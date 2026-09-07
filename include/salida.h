#ifndef SALIDA_H
#define SALIDA_H

#include <stddef.h>
#include <jansson.h>
#include "estructuras.h"

int exportar_catalogo_json(const char *filename,
                           json_t *plan_root,
                           json_t *historial_root,
                           const GrupoCurso *plan,
                           size_t num_grupos,
                           char **ciclos,
                           size_t num_ciclos);

#endif