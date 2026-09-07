#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "salida.h"
#include "constantes.h"
#include "utilidades.h"
#include "validacion.h"

static json_t *array_strings_a_json(char **arr, size_t count) {
    json_t *resultado = json_array();

    for (size_t i = 0; i < count; i++) {
        json_array_append_new(resultado, json_string(arr[i]));
    }

    return resultado;
}

static int curso_tiene_choque(const GrupoCurso *plan,
                              size_t num_grupos,
                              const char *codigo) {
    for (size_t i = 0; i < num_grupos; i++) {
        if (strcmp(plan[i].codigo, codigo) == 0 &&
            plan[i].num_choques > 0) {
            return 1;
        }
    }

    return 0;
}

int exportar_catalogo_json(const char *filename,
                                  json_t *plan_root,
                                  json_t *historial_root,
                                  const GrupoCurso *plan,
                                  size_t num_grupos,
                                  char **ciclos,
                                  size_t num_ciclos) {
    json_t *root = json_object();
    json_t *cursos_json = json_array();
    json_t *ciclos_json = json_array();

    if (!root || !cursos_json || !ciclos_json) {
        json_decref(root);
        json_decref(cursos_json);
        json_decref(ciclos_json);
        return 0;
    }

    json_t *j_carrera = json_object_get(plan_root, "carrera");
    const char *carrera =
        (j_carrera && json_is_string(j_carrera))
            ? json_string_value(j_carrera)
            : "";

    json_object_set_new(root, "tipo", json_string(TIPO_SALIDA));
    json_object_set_new(root, "carrera", json_string(carrera));
    json_object_set_new(root, "semestres_considerados",
                        json_integer(NUM_SEMESTRES));

    for (size_t i = 0; i < num_ciclos; i++) {
        json_array_append_new(ciclos_json, json_string(ciclos[i]));
    }
    json_object_set_new(root, "ciclos_requisitos", ciclos_json);

    size_t num_unicos = 0;
    size_t *indices = obtener_indices_cursos_unicos(plan,
                                                    num_grupos,
                                                    &num_unicos);

    if (num_unicos > 0 && !indices) {
        json_decref(root);
        json_decref(cursos_json);
        return 0;
    }

    for (size_t u = 0; u < num_unicos; u++) {
        const GrupoCurso *base = &plan[indices[u]];

        json_t *curso_json = json_object();
        json_t *grupos_json = json_array();

        if (!curso_json || !grupos_json) {
            json_decref(curso_json);
            json_decref(grupos_json);
            free(indices);
            json_decref(root);
            json_decref(cursos_json);
            return 0;
        }

        int aprobado = esta_aprobado(historial_root, base->codigo) == 1;
        int puede_matricular = puede_matricular_curso(historial_root,
                                                      plan,
                                                      num_grupos,
                                                      base->codigo);

        VerificacionRequisitos verificacion =
            verificar_requisitos(historial_root, base);

        json_object_set_new(curso_json, "codigo", json_string(base->codigo));
        json_object_set_new(curso_json, "nombre", json_string(base->nombre));
        json_object_set_new(curso_json, "creditos", json_integer(base->creditos));
        json_object_set_new(curso_json, "aprobado", json_boolean(aprobado));

        json_object_set_new(curso_json,
                            "requisitos",
                            array_strings_a_json(base->requisitos,
                                                 base->num_requisitos));

        json_object_set_new(curso_json,
                            "correquisitos",
                            array_strings_a_json(base->correquisitos,
                                                 base->num_correquisitos));

        json_object_set_new(curso_json,
                            "requisitos_cumplidos",
                            json_boolean(verificacion.requisitos_cumplidos));

        json_object_set_new(curso_json,
                            "correquisitos_pendientes",
                            array_strings_a_json(
                                verificacion.correquisitos_pendientes,
                                verificacion.num_correquisitos_pendientes));

        json_object_set_new(curso_json,
                            "puede_matricular",
                            json_boolean(puede_matricular));

        json_object_set_new(curso_json,
                            "tiene_choque",
                            json_boolean(curso_tiene_choque(plan,
                                                           num_grupos,
                                                           base->codigo)));

        for (size_t i = 0; i < num_grupos; i++) {
            if (strcmp(plan[i].codigo, base->codigo) != 0) {
                continue;
            }

            const GrupoCurso *gc = &plan[i];
            json_t *grupo_json = json_object();
            json_t *profesores_json = json_array();
            json_t *horarios_json = json_array();
            json_t *choques_json = json_array();

            json_object_set_new(grupo_json,
                                "grupo",
                                json_integer(gc->grupo));

            for (size_t p = 0; p < gc->num_profesores; p++) {
                json_array_append_new(profesores_json,
                                      json_string(gc->profesores[p]));
            }
            json_object_set_new(grupo_json,
                                "profesores",
                                profesores_json);

            for (size_t h = 0; h < gc->num_horarios; h++) {
                json_t *horario_json = json_object();
                char inicio[HORARIO_STR_LEN];
                char fin[HORARIO_STR_LEN];

                snprintf(inicio, sizeof(inicio), "%05d", gc->horarios[h].inicio);
                snprintf(fin, sizeof(fin), "%05d", gc->horarios[h].fin);

                json_object_set_new(horario_json,
                                    "inicio",
                                    json_string(inicio));
                json_object_set_new(horario_json,
                                    "fin",
                                    json_string(fin));

                json_array_append_new(horarios_json, horario_json);
            }
            json_object_set_new(grupo_json, "horario", horarios_json);

            json_object_set_new(grupo_json,
                                "tiene_choque",
                                json_boolean(gc->num_choques > 0));

            for (size_t c = 0; c < gc->num_choques; c++) {
                json_t *choque_json = json_object();

                json_object_set_new(choque_json,
                                    "codigo",
                                    json_string(gc->choques[c].codigo));
                json_object_set_new(choque_json,
                                    "grupo",
                                    json_integer(gc->choques[c].grupo));

                json_array_append_new(choques_json, choque_json);
            }

            json_object_set_new(grupo_json, "choques", choques_json);
            json_array_append_new(grupos_json, grupo_json);
        }

        json_object_set_new(curso_json, "grupos", grupos_json);
        json_array_append_new(cursos_json, curso_json);

        liberar_verificacion(&verificacion);
    }

    free(indices);
    json_object_set_new(root, "cursos", cursos_json);

    int resultado =
        json_dump_file(root, filename, JSON_INDENT(2) | JSON_PRESERVE_ORDER);

    json_decref(root);

    return resultado == 0;
}