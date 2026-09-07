#ifndef UTILIDADES_H
#define UTILIDADES_H

#include <stddef.h>
#include <jansson.h>
#include "estructuras.h"

char **copiar_array_strings(json_t *arr, size_t *out_count);
void liberar_array_strings(char **arr, size_t count);
size_t *obtener_indices_cursos_unicos(const GrupoCurso *plan,
                                      size_t num_grupos,
                                      size_t *out_count);
int buscar_indice_unico(const GrupoCurso *plan,
                        const size_t *indices,
                        size_t num_unicos,
                        const char *codigo);

#endif