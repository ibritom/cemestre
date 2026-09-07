#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "utilidades.h"

char **copiar_array_strings(json_t *arr, size_t *out_count) {
    if (!arr || !json_is_array(arr)) {
        *out_count = 0;
        return NULL;
    }

    size_t n = json_array_size(arr);
    if (n == 0) {
        *out_count = 0;
        return NULL;
    }

    char **result = malloc(n * sizeof(char *));
    if (!result) {
        fprintf(stderr, "Error: no se pudo reservar memoria.\n");
        *out_count = 0;
        return NULL;
    }

    for (size_t i = 0; i < n; i++) {
        json_t *item = json_array_get(arr, i);
        const char *s = json_is_string(item) ? json_string_value(item) : "";
        result[i] = strdup(s);

        if (!result[i]) {
            for (size_t j = 0; j < i; j++) {
                free(result[j]);
            }
            free(result);
            *out_count = 0;
            return NULL;
        }
    }

    *out_count = n;
    return result;
}

void liberar_array_strings(char **arr, size_t count) {
    if (!arr) return;

    for (size_t i = 0; i < count; i++) {
        free(arr[i]);
    }

    free(arr);
}


size_t *obtener_indices_cursos_unicos(const GrupoCurso *plan,
                                              size_t num_grupos,
                                              size_t *out_count) {
    size_t *indices = malloc(num_grupos * sizeof(size_t));
    if (!indices) {
        *out_count = 0;
        return NULL;
    }

    size_t count = 0;

    for (size_t i = 0; i < num_grupos; i++) {
        int ya_incluido = 0;

        for (size_t j = 0; j < count; j++) {
            if (strcmp(plan[indices[j]].codigo, plan[i].codigo) == 0) {
                ya_incluido = 1;
                break;
            }
        }

        if (!ya_incluido) {
            indices[count++] = i;
        }
    }

    *out_count = count;
    return indices;
}

int buscar_indice_unico(const GrupoCurso *plan,
                               const size_t *indices,
                               size_t num_unicos,
                               const char *codigo) {
    for (size_t i = 0; i < num_unicos; i++) {
        if (strcmp(plan[indices[i]].codigo, codigo) == 0) {
            return (int)i;
        }
    }

    return -1;
}