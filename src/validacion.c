#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "validacion.h"
#include "utilidades.h"

int verificar_tipo(json_t *root,
                          const char *tipo_esperado,
                          const char *filename) {
    json_t *tipo = json_object_get(root, "tipo");

    if (!tipo || !json_is_string(tipo)) {
        fprintf(stderr, "'%s' no tiene un campo 'tipo' valido.\n", filename);
        return 0;
    }

    const char *tipo_str = json_string_value(tipo);

    if (strcmp(tipo_str, tipo_esperado) != 0) {
        fprintf(stderr,
                "'%s' es de tipo '%s', se esperaba '%s'. ¿Invertiste los archivos?\n",
                filename, tipo_str, tipo_esperado);
        return 0;
    }

    return 1;
}

int verificar_carrera(json_t *plan_root, json_t *historial_root) {
    json_t *j_plan = json_object_get(plan_root, "carrera");
    json_t *j_historial = json_object_get(historial_root, "carrera");

    if (!j_plan || !json_is_string(j_plan) ||
        !j_historial || !json_is_string(j_historial)) {
        fprintf(stderr,
                "Error: alguno de los archivos no tiene un campo 'carrera' valido.\n");
        return 0;
    }

    const char *carrera_plan = json_string_value(j_plan);
    const char *carrera_historial = json_string_value(j_historial);

    if (strcmp(carrera_plan, carrera_historial) != 0) {
        fprintf(stderr,
                "Error: el plan pertenece a '%s' y el historial a '%s'.\n",
                carrera_plan, carrera_historial);
        return 0;
    }

    return 1;
}

int esta_aprobado(json_t *historial_root, const char *codigo) {
    const char *clave;
    json_t *bloque;

    json_object_foreach(historial_root, clave, bloque) {
        if (strcmp(clave, "tipo") == 0 || strcmp(clave, "carrera") == 0) {
            continue;
        }

        if (!json_is_array(bloque)) {
            continue;
        }

        size_t n = json_array_size(bloque);

        for (size_t i = 0; i < n; i++) {
            json_t *curso = json_array_get(bloque, i);
            json_t *j_codigo = json_object_get(curso, "codigo");

            if (j_codigo && json_is_string(j_codigo) &&
                strcmp(json_string_value(j_codigo), codigo) == 0) {

                json_t *j_aprobado = json_object_get(curso, "aprobado");

                if (j_aprobado && json_is_boolean(j_aprobado)) {
                    return json_is_true(j_aprobado) ? 1 : 0;
                }

                return 0;
            }
        }
    }

    return -1;
}

VerificacionRequisitos verificar_requisitos(json_t *historial_root,
                                                    const GrupoCurso *gc) {
    VerificacionRequisitos res;
    res.requisitos_cumplidos = 1;
    res.correquisitos_pendientes = NULL;
    res.num_correquisitos_pendientes = 0;

    for (size_t i = 0; i < gc->num_requisitos; i++) {
        if (esta_aprobado(historial_root, gc->requisitos[i]) != 1) {
            res.requisitos_cumplidos = 0;
        }
    }

    if (gc->num_correquisitos > 0) {
        res.correquisitos_pendientes =
            malloc(gc->num_correquisitos * sizeof(char *));

        if (!res.correquisitos_pendientes) {
            res.num_correquisitos_pendientes = 0;
            return res;
        }

        for (size_t i = 0; i < gc->num_correquisitos; i++) {
            if (esta_aprobado(historial_root, gc->correquisitos[i]) != 1) {
                res.correquisitos_pendientes[res.num_correquisitos_pendientes] =
                    strdup(gc->correquisitos[i]);

                if (res.correquisitos_pendientes[res.num_correquisitos_pendientes]) {
                    res.num_correquisitos_pendientes++;
                }
            }
        }
    }

    return res;
}

void liberar_verificacion(VerificacionRequisitos *v) {
    liberar_array_strings(v->correquisitos_pendientes,
                          v->num_correquisitos_pendientes);
    v->correquisitos_pendientes = NULL;
    v->num_correquisitos_pendientes = 0;
}

static int buscar_primer_grupo(const GrupoCurso *plan,
                               size_t num_grupos,
                               const char *codigo) {
    for (size_t i = 0; i < num_grupos; i++) {
        if (strcmp(plan[i].codigo, codigo) == 0) {
            return (int)i;
        }
    }

    return -1;
}

static int codigo_en_pila(const char **pila,
                          size_t tam_pila,
                          const char *codigo) {
    for (size_t i = 0; i < tam_pila; i++) {
        if (strcmp(pila[i], codigo) == 0) {
            return 1;
        }
    }

    return 0;
}

static int curso_habilitado_rec(json_t *historial_root,
                                const GrupoCurso *plan,
                                size_t num_grupos,
                                const char *codigo,
                                const char **pila,
                                size_t tam_pila) {
    if (esta_aprobado(historial_root, codigo) == 1) {
        return 1;
    }

    if (codigo_en_pila(pila, tam_pila, codigo)) {
        return 1;
    }

    int idx = buscar_primer_grupo(plan, num_grupos, codigo);
    if (idx < 0) {
        return 0;
    }

    const GrupoCurso *gc = &plan[idx];

    for (size_t i = 0; i < gc->num_requisitos; i++) {
        if (esta_aprobado(historial_root, gc->requisitos[i]) != 1) {
            return 0;
        }
    }

    const char **nueva_pila = malloc((tam_pila + 1) * sizeof(char *));
    if (!nueva_pila) {
        return 0;
    }

    for (size_t i = 0; i < tam_pila; i++) {
        nueva_pila[i] = pila[i];
    }
    nueva_pila[tam_pila] = gc->codigo;

    for (size_t i = 0; i < gc->num_correquisitos; i++) {
        const char *correq = gc->correquisitos[i];

        if (esta_aprobado(historial_root, correq) == 1) {
            continue;
        }

        if (!curso_habilitado_rec(historial_root,
                                  plan,
                                  num_grupos,
                                  correq,
                                  nueva_pila,
                                  tam_pila + 1)) {
            free(nueva_pila);
            return 0;
        }
    }

    free(nueva_pila);
    return 1;
}

int puede_matricular_curso(json_t *historial_root,
                                  const GrupoCurso *plan,
                                  size_t num_grupos,
                                  const char *codigo) {
    if (esta_aprobado(historial_root, codigo) == 1) {
        return 0;
    }

    return curso_habilitado_rec(historial_root,
                                plan,
                                num_grupos,
                                codigo,
                                NULL,
                                0);
}

char **listar_cursos_matriculables(json_t *historial_root,
                                           const GrupoCurso *plan,
                                           size_t num_grupos,
                                           size_t *out_count) {
    char **result = malloc(num_grupos * sizeof(char *));
    if (!result) {
        *out_count = 0;
        return NULL;
    }

    size_t count = 0;

    for (size_t i = 0; i < num_grupos; i++) {
        const char *codigo = plan[i].codigo;

        int ya_incluido = 0;
        for (size_t j = 0; j < count; j++) {
            if (strcmp(result[j], codigo) == 0) {
                ya_incluido = 1;
                break;
            }
        }

        if (ya_incluido) {
            continue;
        }

        if (puede_matricular_curso(historial_root,
                                   plan,
                                   num_grupos,
                                   codigo)) {
            result[count] = strdup(codigo);
            if (result[count]) {
                count++;
            }
        }
    }

    *out_count = count;
    return result;
}

void imprimir_cursos_matriculables(char **codigos, size_t count) {
    printf("CURSOS_MATRICULABLES:%zu\n", count);

    for (size_t i = 0; i < count; i++) {
        printf("%s\n", codigos[i]);
    }
}