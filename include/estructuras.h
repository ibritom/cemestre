#ifndef ESTRUCTURAS_H
#define ESTRUCTURAS_H

#include <stddef.h>
#include "constantes.h"

typedef struct {
    int inicio;
    int fin;
} Horario;

typedef struct {
    char codigo[COD_LEN];
    int grupo;
} Conflicto;

typedef struct {
    int requisitos_cumplidos;

    char **correquisitos_pendientes;
    size_t num_correquisitos_pendientes;

} VerificacionRequisitos;

typedef struct {

    char codigo[COD_LEN];
    char nombre[NOMBRE_LEN];

    int creditos;

    char **requisitos;
    size_t num_requisitos;

    char **correquisitos;
    size_t num_correquisitos;

    int grupo;

    char **profesores;
    size_t num_profesores;

    Horario *horarios;
    size_t num_horarios;

    Conflicto *choques;
    size_t num_choques;

} GrupoCurso;

#endif