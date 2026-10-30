#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "parser.h"
#include "utilidades.h"

static int codigo_en_primeros_cuatro_bloques(json_t *historial_root,
                                               const char *codigo) {
    char nombre_bloque[BLOQUE_NOMBRE_LEN];

    for (int semestre = 0; semestre <= NUM_SEMESTRES; semestre++) {
        snprintf(nombre_bloque, sizeof(nombre_bloque), "Bloque %d", semestre);
        json_t *bloque = json_object_get(historial_root, nombre_bloque);

        if (!bloque || !json_is_array(bloque)) {
            continue;
        }

        size_t n = json_array_size(bloque);
        for (size_t i = 0; i < n; i++) {
            json_t *curso = json_array_get(bloque, i);
            json_t *j_codigo = json_object_get(curso, "codigo");

            if (j_codigo && json_is_string(j_codigo) &&
                strcmp(json_string_value(j_codigo), codigo) == 0) {
                return 1;
            }
        }
    }

    return 0;
}

GrupoCurso *parsear_plan(json_t *plan_root,
                                json_t *historial_root,
                                size_t *out_count) {
    json_t *cursos = json_object_get(plan_root, "cursos");

    if (!cursos || !json_is_array(cursos)) {
        fprintf(stderr, "El JSON no tiene un array 'cursos' valido.\n");
        *out_count = 0;
        return NULL;
    }

    size_t total_grupos = 0;
    size_t num_cursos = json_array_size(cursos);

    for (size_t i = 0; i < num_cursos; i++) {
        json_t *curso = json_array_get(cursos, i);
        json_t *j_codigo = json_object_get(curso, "codigo");

        if (!j_codigo || !json_is_string(j_codigo)) {
            continue;
        }

        const char *codigo = json_string_value(j_codigo);
        if (!codigo_en_primeros_cuatro_bloques(historial_root, codigo)) {
            continue;
        }

        json_t *grupos = json_object_get(curso, "grupos");
        if (grupos && json_is_array(grupos)) {
            total_grupos += json_array_size(grupos);
        }
    }

    if (total_grupos == 0) {
        *out_count = 0;
        return NULL;
    }

    GrupoCurso *result = calloc(total_grupos, sizeof(GrupoCurso));
    if (!result) {
        fprintf(stderr, "Error: no se pudo reservar memoria para el plan.\n");
        *out_count = 0;
        return NULL;
    }

    size_t idx = 0;

    for (size_t i = 0; i < num_cursos; i++) {
        json_t *curso = json_array_get(cursos, i);

        json_t *j_codigo = json_object_get(curso, "codigo");
        json_t *j_nombre = json_object_get(curso, "nombre");
        json_t *j_creditos = json_object_get(curso, "creditos");
        json_t *j_requisitos = json_object_get(curso, "requisitos");
        json_t *j_correquisitos = json_object_get(curso, "correquisitos");
        json_t *j_grupos = json_object_get(curso, "grupos");

        if (!j_codigo || !json_is_string(j_codigo)) {
            continue;
        }

        const char *codigo = json_string_value(j_codigo);
        if (!codigo_en_primeros_cuatro_bloques(historial_root, codigo)) {
            continue;
        }

        if (!j_grupos || !json_is_array(j_grupos)) {
            continue;
        }

        size_t num_grupos = json_array_size(j_grupos);

        for (size_t g = 0; g < num_grupos; g++) {
            json_t *grupo = json_array_get(j_grupos, g);
            GrupoCurso *gc = &result[idx];

            snprintf(gc->codigo, COD_LEN, "%s", codigo);
            snprintf(gc->nombre, NOMBRE_LEN, "%s",
                     j_nombre && json_is_string(j_nombre)
                         ? json_string_value(j_nombre)
                         : "");

            gc->creditos = j_creditos && json_is_integer(j_creditos)
                               ? (int)json_integer_value(j_creditos)
                               : 0;

            gc->requisitos = copiar_array_strings(j_requisitos,
                                                   &gc->num_requisitos);
            gc->correquisitos = copiar_array_strings(j_correquisitos,
                                                      &gc->num_correquisitos);

            json_t *j_numgrupo = json_object_get(grupo, "grupo");
            gc->grupo = j_numgrupo && json_is_integer(j_numgrupo)
                            ? (int)json_integer_value(j_numgrupo)
                            : 0;

            json_t *j_profesores = json_object_get(grupo, "profesores");
            gc->profesores = copiar_array_strings(j_profesores,
                                                   &gc->num_profesores);

            json_t *j_horario = json_object_get(grupo, "horario");
            size_t num_h = (j_horario && json_is_array(j_horario))
                               ? json_array_size(j_horario)
                               : 0;

            gc->horarios = num_h > 0
                               ? malloc(num_h * sizeof(Horario))
                               : NULL;
            gc->num_horarios = num_h;

            if (num_h > 0 && !gc->horarios) {
                fprintf(stderr, "Error: no se pudo reservar memoria para horarios.\n");
                gc->num_horarios = 0;
            }

            for (size_t h = 0; h < gc->num_horarios; h++) {
                json_t *bloque = json_array_get(j_horario, h);
                json_t *j_inicio = json_object_get(bloque, "inicio");
                json_t *j_fin = json_object_get(bloque, "fin");

                gc->horarios[h].inicio =
                    (j_inicio && json_is_string(j_inicio))
                        ? atoi(json_string_value(j_inicio))
                        : 0;

                gc->horarios[h].fin =
                    (j_fin && json_is_string(j_fin))
                        ? atoi(json_string_value(j_fin))
                        : 0;
            }

            gc->choques = NULL;
            gc->num_choques = 0;

            idx++;
        }
    }

    *out_count = idx;
    return result;
}

void liberar_plan(GrupoCurso *plan, size_t count) {
    if (!plan) return;

    for (size_t i = 0; i < count; i++) {
        liberar_array_strings(plan[i].requisitos, plan[i].num_requisitos);
        liberar_array_strings(plan[i].correquisitos, plan[i].num_correquisitos);
        liberar_array_strings(plan[i].profesores, plan[i].num_profesores);
        free(plan[i].horarios);
        free(plan[i].choques);
    }

    free(plan);
}

