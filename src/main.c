#include <stdio.h>
#include <jansson.h>

#include "constantes.h"
#include "estructuras.h"
#include "utilidades.h"
#include "parser.h"
#include "validacion.h"
#include "choques.h"
#include "ciclos.h"
#include "salida.h"

int main(int argc, char *argv[]) {
    if (argc != 3 && argc != 4) {
        fprintf(stderr,
                "Uso: %s <plandeestudios.json> <historial.json> [salida.json]\n",
                argv[0]);
        return 1;
    }

    const char *plan_filename = argv[1];
    const char *historial_filename = argv[2];
    const char *salida_filename =
        argc == 4 ? argv[3] : SALIDA_DEFAULT;

    json_error_t error;

    json_t *plan_root = json_load_file(plan_filename, 0, &error);
    if (!plan_root) {
        fprintf(stderr,
                "Error al parsear '%s' (linea %d): %s\n",
                plan_filename,
                error.line,
                error.text);
        return 1;
    }

    json_t *historial_root = json_load_file(historial_filename, 0, &error);
    if (!historial_root) {
        fprintf(stderr,
                "Error al parsear '%s' (linea %d): %s\n",
                historial_filename,
                error.line,
                error.text);
        json_decref(plan_root);
        return 1;
    }

    if (!verificar_tipo(plan_root, TIPO_PLAN, plan_filename) ||
        !verificar_tipo(historial_root, TIPO_HISTORIAL, historial_filename) ||
        !verificar_carrera(plan_root, historial_root)) {

        json_decref(plan_root);
        json_decref(historial_root);
        return 1;
    }

    size_t num_grupos = 0;
    GrupoCurso *plan = parsear_plan(plan_root,
                                    historial_root,
                                    &num_grupos);

    if (!plan || num_grupos == 0) {
        fprintf(stderr,
                "Error: no se cargaron grupos de los primeros %d semestres.\n",
                NUM_SEMESTRES);
        liberar_plan(plan, num_grupos);
        json_decref(plan_root);
        json_decref(historial_root);
        return 1;
    }

    printf("Total de grupos cargados de los primeros %d semestres: %zu\n\n",
           NUM_SEMESTRES,
           num_grupos);

    detectar_choques(plan, num_grupos);

    size_t num_ciclos = 0;
    char **ciclos = detectar_ciclos_requisitos(plan,
                                               num_grupos,
                                               &num_ciclos);

    if (num_ciclos == 0) {
        printf("CICLOS_REQUISITOS:0\n");
    } else {
        printf("CICLOS_REQUISITOS:%zu\n", num_ciclos);
        for (size_t i = 0; i < num_ciclos; i++) {
            printf("%s\n", ciclos[i]);
        }
    }

    printf("\n");

    size_t num_matriculables = 0;
    char **matriculables =
        listar_cursos_matriculables(historial_root,
                                    plan,
                                    num_grupos,
                                    &num_matriculables);

    imprimir_cursos_matriculables(matriculables,
                                  num_matriculables);

    if (!exportar_catalogo_json(salida_filename,
                                plan_root,
                                historial_root,
                                plan,
                                num_grupos,
                                ciclos,
                                num_ciclos)) {
        fprintf(stderr,
                "Error: no se pudo generar el archivo '%s'.\n",
                salida_filename);

        liberar_array_strings(matriculables, num_matriculables);
        liberar_array_strings(ciclos, num_ciclos);
        liberar_plan(plan, num_grupos);
        json_decref(plan_root);
        json_decref(historial_root);
        return 1;
    }

    printf("\nArchivo generado correctamente: %s\n",
           salida_filename);

    liberar_array_strings(matriculables, num_matriculables);
    liberar_array_strings(ciclos, num_ciclos);
    liberar_plan(plan, num_grupos);
    json_decref(plan_root);
    json_decref(historial_root);

    return 0;
}