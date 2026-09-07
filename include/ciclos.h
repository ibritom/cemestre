#ifndef CICLOS_H
#define CICLOS_H

#include <stddef.h>
#include "estructuras.h"

char **detectar_ciclos_requisitos(
        const GrupoCurso *plan,
        size_t num_grupos,
        size_t *out_count
);

#endif