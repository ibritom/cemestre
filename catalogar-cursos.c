#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <jansson.h>

#define COD_LEN 7 // Longitud del código del curso
#define NOMBRE_LEN 128 // Longitud del nombre del curso
#define PROFESOR_LEN 64 // Longitdud del nombre del profesor

// struct para el horario de cada grupo
typedef struct {
	int inicio;
	int fin;
} Horario;

// struct para la verificación de requisitos y correquisitos
typedef struct {
    int requisitos_cumplidos;
    char **correquisitos_pendientes;
    size_t num_correquisitos_pendientes;
} VerificacionRequisitos;

// struct para los grupos
typedef struct {
	// Datos del curso
	char codigo[COD_LEN];
	char nombre[NOMBRE_LEN];
	int creditos;

	char **requisitos;
	size_t num_requisitos;

	char **correquisitos;
	size_t num_correquisitos;

	// Datos del grupo en especifico
	int grupo;
	char profesor[PROFESOR_LEN];

	Horario *horarios;
	size_t num_horarios;
} GrupoCurso;

// Copiar un array JSON a un char, necesario para manejar los requisitos y correquisitos
static char **copiar_array_strings(json_t *arr, size_t *out_count) {
	if (!arr || !json_is_array(arr)) {
		*out_count = 0;
		return NULL;
	}

	size_t n = json_array_size(arr);
	char **result = malloc(n * sizeof(char *));
	if (!result) {
		*out_count = 0;
		return NULL;
	}

	for (size_t i = 0; i < n; i++) {
		json_t *item = json_array_get(arr, i);
		const char *s = json_is_string(item) ? json_string_value(item) : "";
		result[i] = strdup(s);
	}

	*out_count = n;
	return result;
}

// Libera la memoria creada por copiar_array_strings
static void liberar_array_strings(char **arr, size_t count) {
	if (!arr) return;
	for (size_t i = 0; i < count; i++) {
		free(arr[i]);
	}
	free(arr);
}

// Parsea el .json del plan de estudios
static GrupoCurso *parsear_plan(json_t *root, size_t *out_count) {
    json_t *cursos = json_object_get(root, "cursos");
    if (!cursos || !json_is_array(cursos)) {
        fprintf(stderr, "El JSON no tiene un array 'cursos' válido\n");
        *out_count = 0;
        return NULL;
    }

    // Contar cuantos grupos hay en total para reservar la memoria
    size_t total_grupos = 0;
    size_t num_cursos = json_array_size(cursos);
    for (size_t i = 0; i < num_cursos; i++) {
        json_t *curso = json_array_get(cursos, i);
        json_t *grupos = json_object_get(curso, "grupos");
        if (grupos && json_is_array(grupos)) {
            total_grupos += json_array_size(grupos);
        }
    }

    GrupoCurso *result = malloc(total_grupos * sizeof(GrupoCurso));
    if (!result) {
        *out_count = 0;
        return NULL;
    }

    size_t idx = 0;
    for (size_t i = 0; i < num_cursos; i++) {
        json_t *curso = json_array_get(cursos, i);

        json_t *j_codigo = json_object_get(curso, "codigo");
        json_t *j_nombre = json_object_get(curso, "nombre");
        json_t *j_creditos = json_object_get(curso, "creditos");
        json_t *j_requisitos = json_object_get(curso, "requisitos");
        json_t *j_correquisitos = json_object_get(curso, "correquisitos");
        json_t *j_grupos = json_object_get(curso, "grupos");

        if (!j_grupos || !json_is_array(j_grupos)) {
            continue;
        }

        size_t num_grupos = json_array_size(j_grupos);
        for (size_t g = 0; g < num_grupos; g++) {
            json_t *grupo = json_array_get(j_grupos, g);
            GrupoCurso *gc = &result[idx];

            // Datos del curso
            snprintf(gc->codigo, COD_LEN, "%s",
                      j_codigo && json_is_string(j_codigo) ? json_string_value(j_codigo) : "");
            snprintf(gc->nombre, NOMBRE_LEN, "%s",
                      j_nombre && json_is_string(j_nombre) ? json_string_value(j_nombre) : "");
            gc->creditos = j_creditos && json_is_integer(j_creditos)
                               ? (int)json_integer_value(j_creditos)
                               : 0;

            gc->requisitos = copiar_array_strings(j_requisitos, &gc->num_requisitos);
            gc->correquisitos = copiar_array_strings(j_correquisitos, &gc->num_correquisitos);

            // Datos del grupo
            json_t *j_numgrupo = json_object_get(grupo, "grupo");
            gc->grupo = j_numgrupo && json_is_integer(j_numgrupo)
                            ? (int)json_integer_value(j_numgrupo)
                            : 0;

            json_t *j_profesores = json_object_get(grupo, "profesores");
            const char *primer_profesor = "";
            if (j_profesores && json_is_array(j_profesores) && json_array_size(j_profesores) > 0) {
                json_t *p0 = json_array_get(j_profesores, 0);
                if (json_is_string(p0)) {
                    primer_profesor = json_string_value(p0);
                }
            }
            snprintf(gc->profesor, PROFESOR_LEN, "%s", primer_profesor);

            // Horarios del grupo
            json_t *j_horario = json_object_get(grupo, "horario");
            size_t num_h = (j_horario && json_is_array(j_horario)) ? json_array_size(j_horario) : 0;
            gc->horarios = num_h > 0 ? malloc(num_h * sizeof(Horario)) : NULL;
            gc->num_horarios = num_h;

            for (size_t h = 0; h < num_h; h++) {
                json_t *bloque = json_array_get(j_horario, h);
                json_t *j_inicio = json_object_get(bloque, "inicio");
                json_t *j_fin = json_object_get(bloque, "fin");

                gc->horarios[h].inicio = (j_inicio && json_is_string(j_inicio))
                                              ? atoi(json_string_value(j_inicio))
                                              : 0;
                gc->horarios[h].fin = (j_fin && json_is_string(j_fin))
                                           ? atoi(json_string_value(j_fin))
                                           : 0;
            }

            idx++;
        }
    }

    *out_count = idx;
    return result;
}

// Liberar la memoria usada por parsear_plan
static void liberar_plan(GrupoCurso *plan, size_t count) {
    if (!plan) return;
    for (size_t i = 0; i < count; i++) {
        liberar_array_strings(plan[i].requisitos, plan[i].num_requisitos);
        liberar_array_strings(plan[i].correquisitos, plan[i].num_correquisitos);
        free(plan[i].horarios);
    }
    free(plan);
}

// Imprimir un GrupoCurso, usado para debugging
static void imprimir_grupo(const GrupoCurso *gc) {
    printf("%s - %s (grupo %d, %d créditos)\n",
           gc->codigo, gc->nombre, gc->grupo, gc->creditos);
    printf("  Profesor: %s\n", gc->profesor);

    printf("  Requisitos: ");
    if (gc->num_requisitos == 0) printf("(ninguno)");
    for (size_t i = 0; i < gc->num_requisitos; i++) {
        printf("%s%s", gc->requisitos[i], (i + 1 < gc->num_requisitos) ? ", " : "");
    }
    printf("\n");

    printf("  Correquisitos: ");
    if (gc->num_correquisitos == 0) printf("(ninguno)");
    for (size_t i = 0; i < gc->num_correquisitos; i++) {
        printf("%s%s", gc->correquisitos[i], (i + 1 < gc->num_correquisitos) ? ", " : "");
    }
    printf("\n");

    printf("  Horario: ");
    if (gc->num_horarios == 0) printf("(sin horario)");
    for (size_t i = 0; i < gc->num_horarios; i++) {
        printf("[%05d-%05d]%s", gc->horarios[i].inicio, gc->horarios[i].fin,
               (i + 1 < gc->num_horarios) ? " " : "");
    }
    printf("\n\n");
}

// Funcion que verifique que el tipo de cada .json sea el correcto
static int verificar_tipo(json_t *root, const char *tipo_esperado, const char *filename) {
	json_t *tipo = json_object_get(root, "tipo");
	if (!tipo || !json_is_string(tipo)) {
		fprintf(stderr, "'%s' no tiene un campo 'tipo' válido\n", filename);
		return 0;
	}
	const char *tipo_str = json_string_value(tipo);
	if (strcmp(tipo_str, tipo_esperado) != 0) {
		fprintf(stderr, "'%s' es de tipo '%s', se esperaba '%s'. ¿Invertiste los archivos?\n", filename, tipo_str, tipo_esperado);
		return 0;
	}
	return 1;
}

// Funcion que revise si el estudiante ya aporobó un curso
// Retorna 1 si está aprobado, 0 si no, y -1 si el curso no esta en el historial
static int esta_aprobado(json_t *historial_root, const char *codigo) {
    const char *clave;
    json_t *bloque;

    json_object_foreach(historial_root, clave, bloque) {
        // Saltar los campos que no son bloques de cursos
        if (strcmp(clave, "tipo") == 0 || strcmp(clave, "carrera") == 0) {
            continue;
        }

        if (!json_is_array(bloque)) {
            continue;
        }

        size_t n = json_array_size(bloque);
        for (size_t i = 0; i < n; i++) {
            json_t *curso = json_array_get(bloque, i);
            json_t *j_codigo = json_object_get(curso, "codigo");

            if (j_codigo && json_is_string(j_codigo) &&
                strcmp(json_string_value(j_codigo), codigo) == 0) {

                json_t *j_aprobado = json_object_get(curso, "aprobado");
                if (j_aprobado && json_is_boolean(j_aprobado)) {
		    int aprobado = json_is_true(j_aprobado);
		    // printf("%s: %s\n", codigo, aprobado ? "aprobado" : "no aprobado"); print para debugging
                    return aprobado ? 1 : 0;
                }
		// printf("%s: encontrado pero sin campo 'aprobado' válido\n", codigo); print para debugging
                return 0; // encontrado pero sin campo 'aprobado' válido
            }
        }
    }
    // printf("%s: no aparece en el historial\n", codigo); print para debugging
    return -1; // no encontrado en ningún bloque
}

// Función que revisa si un curso es matriculable por sus requisitos y correquisitos
static VerificacionRequisitos verificar_requisitos(json_t *historial_root, const GrupoCurso *gc) {
    VerificacionRequisitos res;
    res.requisitos_cumplidos = 1;
    res.correquisitos_pendientes = NULL;
    res.num_correquisitos_pendientes = 0;

    // Todos los requisitos deben estar aprobados
    for (size_t i = 0; i < gc->num_requisitos; i++) {
        if (esta_aprobado(historial_root, gc->requisitos[i]) != 1) {
            res.requisitos_cumplidos = 0;
        }
    }

    // Guardar los correquisitos como pendientes, se deben matricular juntos
    if (gc->num_correquisitos > 0) {
        res.correquisitos_pendientes = malloc(gc->num_correquisitos * sizeof(char *));
        for (size_t i = 0; i < gc->num_correquisitos; i++) {
            if (esta_aprobado(historial_root, gc->correquisitos[i]) != 1) {
                res.correquisitos_pendientes[res.num_correquisitos_pendientes] =
                    strdup(gc->correquisitos[i]);
                res.num_correquisitos_pendientes++;
            }
        }
    }

    return res;
}

// Funcion para liberar la memoria usada por verificar_requisitos()
static void liberar_verificacion(VerificacionRequisitos *v) {
    liberar_array_strings(v->correquisitos_pendientes, v->num_correquisitos_pendientes);
    v->correquisitos_pendientes = NULL;
    v->num_correquisitos_pendientes = 0;
}

// Funciones para imprimir todos los cursos matriculables
static char **listar_cursos_matriculables(json_t *historial_root,
                                           const GrupoCurso *plan, size_t num_grupos,
                                           size_t *out_count) {
    char **result = malloc(num_grupos * sizeof(char *)); // cota superior
    size_t count = 0;

    for (size_t i = 0; i < num_grupos; i++) {
        const char *codigo = plan[i].codigo;

        // Saltar si ya agregamos este código (varios grupos comparten curso)
        int ya_incluido = 0;
        for (size_t j = 0; j < count; j++) {
            if (strcmp(result[j], codigo) == 0) {
                ya_incluido = 1;
                break;
            }
        }
        if (ya_incluido) continue;

        // Saltar cursos que ya están aprobados
        if (esta_aprobado(historial_root, codigo) == 1) continue;

        // Un curso es matriculable si todos sus requisitos están cumplidos.
        // (Los correquisitos no bloquean, así que no se revisan acá.)
        VerificacionRequisitos v = verificar_requisitos(historial_root, &plan[i]);
        if (v.requisitos_cumplidos) {
            result[count] = strdup(codigo);
            count++;
        }
        liberar_verificacion(&v);
    }

    *out_count = count;
    return result;
}

static void imprimir_cursos_matriculables(char **codigos, size_t count) {
    printf("CURSOS_MATRICULABLES:%zu\n", count);
    for (size_t i = 0; i < count; i++) {
        printf("%s\n", codigos[i]);
    }
}

int main(int argc, char *argv[]) {
	// Output si se dan menos de dos argumentos
	if (argc != 3) {
		fprintf(stderr, "Uso: %s <plandeestudios.json> <historial.json>\n", argv[0]);
		return 1;
	}

	const char *plan_filename = argv[1]; // Definir el archivo de plan de estudios como el primer argumento
	const char *historial_filename = argv[2]; // Definir el archivo del historial como el segundo argumento

	json_error_t error;

	// Cargar el plan de estudios
	json_t *plan_root = json_load_file(plan_filename, 0, &error);
	if (!plan_root) {
		fprintf(stderr, "Error al parsear '%s' (linea %d): %s\n", plan_filename, error.line, error.text);
		return 1;
	}

	// Cargar el historial
	json_t *historial_root = json_load_file(historial_filename, 0, &error);
	if (!historial_root) {
		fprintf(stderr, "Error al parsear '%s' (linea %d): %s\n", historial_filename, error.line, error.text);
		json_decref(historial_root);
		return 1;
	}

	// Verificar si los argumentos fueron puestos en el orden correcto
	if (!verificar_tipo(plan_root, "plan", plan_filename) || !verificar_tipo(historial_root, "historial", historial_filename)) {
		json_decref(plan_root);
		json_decref(historial_root);
		return 1;
	}

	// Parsear todo el plan de estudios a un arreglo de GrupoCurso
	size_t num_grupos = 0;
	GrupoCurso *plan = parsear_plan(plan_root, &num_grupos);

	printf("Total de grupos cargados: %zu\n\n", num_grupos);

	// Imprimir los cursos matriculables
	size_t num_matriculables = 0;
	char **matriculables = listar_cursos_matriculables(historial_root, plan, num_grupos, &num_matriculables);
	imprimir_cursos_matriculables(matriculables, num_matriculables);

	// TODO: Implementar la lógica para verificar el choque de horarios, y imprimir todo al archivo de salida
	liberar_array_strings(matriculables, num_matriculables);
	liberar_plan(plan, num_grupos);
	json_decref(plan_root);
	json_decref(historial_root);
	return 0;
}

