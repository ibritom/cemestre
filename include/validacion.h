#ifndef VALIDACION_H
#define VALIDACION_H

#include <stddef.h>
#include <jansson.h>
#include "estructuras.h"

int verificar_tipo(json_t *root, const char *tipo_esperado, const char *filename);
int verificar_carrera(json_t *plan_root, json_t *historial_root);
int esta_aprobado(json_t *historial_root, const char *codigo);
VerificacionRequisitos verificar_requisitos(json_t *historial_root,
                                             const GrupoCurso *gc);
void liberar_verificacion(VerificacionRequisitos *v);
int puede_matricular_curso(json_t *historial_root,
                           const GrupoCurso *plan,
                           size_t num_grupos,
                           const char *codigo);
char **listar_cursos_matriculables(json_t *historial_root,
                                   const GrupoCurso *plan,
                                   size_t num_grupos,
                                   size_t *out_count);
void imprimir_cursos_matriculables(char **codigos, size_t count);

#endif