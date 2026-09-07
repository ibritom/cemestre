#include <stdlib.h>
#include <string.h>

#include "ciclos.h"
#include "utilidades.h"

static void dfs_ciclos(const GrupoCurso *plan,
                       const size_t *indices,
                       size_t num_unicos,
                       size_t actual,
                       int *estado,
                       size_t *pila,
                       size_t *tam_pila,
                       int *en_ciclo) {
    estado[actual] = 1;
    pila[*tam_pila] = actual;
    (*tam_pila)++;

    const GrupoCurso *gc = &plan[indices[actual]];

    for (size_t r = 0; r < gc->num_requisitos; r++) {
        int vecino = buscar_indice_unico(plan,
                                         indices,
                                         num_unicos,
                                         gc->requisitos[r]);

        if (vecino < 0) {
            continue;
        }

        if (estado[vecino] == 0) {
            dfs_ciclos(plan,
                       indices,
                       num_unicos,
                       (size_t)vecino,
                       estado,
                       pila,
                       tam_pila,
                       en_ciclo);
        } else if (estado[vecino] == 1) {
            size_t inicio_ciclo = 0;

            while (inicio_ciclo < *tam_pila &&
                   pila[inicio_ciclo] != (size_t)vecino) {
                inicio_ciclo++;
            }

            for (size_t k = inicio_ciclo; k < *tam_pila; k++) {
                en_ciclo[pila[k]] = 1;
            }
        }
    }

    (*tam_pila)--;
    estado[actual] = 2;
}

char **detectar_ciclos_requisitos(const GrupoCurso *plan,
                                          size_t num_grupos,
                                          size_t *out_count) {
    size_t num_unicos = 0;
    size_t *indices = obtener_indices_cursos_unicos(plan,
                                                    num_grupos,
                                                    &num_unicos);

    if (!indices || num_unicos == 0) {
        free(indices);
        *out_count = 0;
        return NULL;
    }

    int *estado = calloc(num_unicos, sizeof(int));
    int *en_ciclo = calloc(num_unicos, sizeof(int));
    size_t *pila = malloc(num_unicos * sizeof(size_t));

    if (!estado || !en_ciclo || !pila) {
        free(indices);
        free(estado);
        free(en_ciclo);
        free(pila);
        *out_count = 0;
        return NULL;
    }

    size_t tam_pila = 0;

    for (size_t i = 0; i < num_unicos; i++) {
        if (estado[i] == 0) {
            dfs_ciclos(plan,
                       indices,
                       num_unicos,
                       i,
                       estado,
                       pila,
                       &tam_pila,
                       en_ciclo);
        }
    }

    size_t cantidad = 0;
    for (size_t i = 0; i < num_unicos; i++) {
        if (en_ciclo[i]) {
            cantidad++;
        }
    }

    char **resultado = cantidad > 0
                           ? malloc(cantidad * sizeof(char *))
                           : NULL;

    if (cantidad > 0 && !resultado) {
        free(indices);
        free(estado);
        free(en_ciclo);
        free(pila);
        *out_count = 0;
        return NULL;
    }

    size_t pos = 0;
    for (size_t i = 0; i < num_unicos; i++) {
        if (en_ciclo[i]) {
            resultado[pos] = strdup(plan[indices[i]].codigo);
            if (resultado[pos]) {
                pos++;
            }
        }
    }

    free(indices);
    free(estado);
    free(en_ciclo);
    free(pila);

    *out_count = pos;
    return resultado;
}