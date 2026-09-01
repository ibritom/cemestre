#include <stdio.h>
#include <jansson.h>

int main(int argc, char *argv[]) {
	// Output si no se da ningun archivo de input
	if (argc != 3) {
		fprintf(stderr, "Uso: %s <plandeestudios.json> <historial.json>\n", argv[0]);
		return 1;
	}

	const char *plan_filename = argv[1]; // Definir el archivo de plan de estudios como el primer parametro
	const char *historial_filename = argv[2]; // Definir el archivo del historial como el segundo parametro

	json_error_t error;

	// Cargar el plan de estudios
	json_t *plan_root = json_load_file(plan_filename, 0, &error);
	if (!plan_root) {
		fprintf(stderr, "Error al parsear '%s' (linea %d): %s\n", plan_filename, error.line, error.text);
		return 1;
	}

	// Cargar el historial
	json_t *historial_root = json_load_file(historial_filename, 0, &error);
	if (!plan_root) {
		fprintf(stderr, "Error al parsear '%s' (linea %d): %s\n", historial_filename, error.line, error.text);
		json_decref(plan_root);
		return 1;
	}

	// Verificar si el campo "carrera" existe en el historial y si es un string
	// Si ambas condiciones se cumplen, imprimir el string
	json_t *carrera = json_object_get(historial_root, "carrera");
	if (!carrera || !json_is_string(carrera)) {
		fprintf(stderr, "El campo 'carrera' no se encontró como string en '%s'\n", historial_filename);
		json_decref(plan_root);
		json_decref(historial_root);
		return 1;
	}
	printf("Carrera: %s\n", json_string_value(carrera));

	// TODO: Leer el archivo del plan, implementar la lógica para conseguir el catálogo de los cursos
	json_decref(plan_root);
	json_decref(historial_root);
	return 0;
}

