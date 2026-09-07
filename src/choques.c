#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "choques.h"

static int obtener_dia(int horario) {
    return horario / HORARIO_DIVISOR;
}

static int obtener_hora(int horario) {
    return horario % HORARIO_DIVISOR;
}

static int horarios_chocan(Horario a, Horario b) {
    int dia_a = obtener_dia(a.inicio);
    int dia_b = obtener_dia(b.inicio);

    if (dia_a != dia_b) {
        return 0;
    }

    int inicio_a = obtener_hora(a.inicio);
    int fin_a = obtener_hora(a.fin);
    int inicio_b = obtener_hora(b.inicio);
    int fin_b = obtener_hora(b.fin);

    return inicio_a < fin_b && inicio_b < fin_a;
}

static int grupos_chocan(const GrupoCurso *a, const GrupoCurso *b) {
    for (size_t i = 0; i < a->num_horarios; i++) {
        for (size_t j = 0; j < b->num_horarios; j++) {
            if (horarios_chocan(a->horarios[i], b->horarios[j])) {
                return 1;
            }
        }
    }

    return 0;
}

static int agregar_conflicto(GrupoCurso *gc,
                             const char *codigo,
                             int grupo) {
    for (size_t i = 0; i < gc->num_choques; i++) {
        if (strcmp(gc->choques[i].codigo, codigo) == 0 &&
            gc->choques[i].grupo == grupo) {
            return 1;
        }
    }

    Conflicto *nuevo = realloc(gc->choques,
                               (gc->num_choques + 1) * sizeof(Conflicto));

    if (!nuevo) {
        return 0;
    }

    gc->choques = nuevo;
    snprintf(gc->choques[gc->num_choques].codigo, COD_LEN, "%s", codigo);
    gc->choques[gc->num_choques].grupo = grupo;
    gc->num_choques++;

    return 1;
}

void detectar_choques(GrupoCurso *plan, size_t num_grupos) {
    for (size_t i = 0; i < num_grupos; i++) {
        for (size_t j = i + 1; j < num_grupos; j++) {
            if (strcmp(plan[i].codigo, plan[j].codigo) == 0) {
                continue;
            }

            if (grupos_chocan(&plan[i], &plan[j])) {
                if (!agregar_conflicto(&plan[i], plan[j].codigo, plan[j].grupo) ||
                    !agregar_conflicto(&plan[j], plan[i].codigo, plan[i].grupo)) {
                    fprintf(stderr,
                            "Advertencia: no se pudo guardar completamente un choque de horario.\n");
                }
            }
        }
    }
}