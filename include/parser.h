#ifndef PARSER_H
#define PARSER_H

#include <stddef.h>
#include <jansson.h>
#include "estructuras.h"

GrupoCurso *parsear_plan(json_t *plan_root,
                         json_t *historial_root,
                         size_t *out_count);
void liberar_plan(GrupoCurso *plan, size_t count);

#endif