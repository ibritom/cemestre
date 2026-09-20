# cemestre
Programa para apoyar a un estudiante para la creación de sus horarios para un semestre.

# Dependencias
Este programa depende de la biblioteca de C jansson, que se usa para parsear los archivos .json del plan de estudio y del historial del estudiante; tambien se usa para crear el archivo de salida.

# Porque .json?
Se decidió usar el formato .json debido a que este es un formato universal que es soportado por todos los lenguajes que se van a usar durante el projecto. También, debido a que el formato json es jerárquico, ayuda a poner todos los grupos de un curso en un solo lugar, sin tener que repetirlo constantemente.

# Uso
Se deben proporcionar los archivos .json del plan de estudios y del historial del estudiante, en ese orden, como argumentos al correr el archivo en una terminal.

# Arquitectura
El proyecto está modularizado para hacer el manejo del código más práctico. Estos modulos separan la lógica para parsear los archivos, verificar los choques de horarios y los ciclos que esto puede generar, validar si un curso se puede matricular, y escribir el archivo de salida.

# Decisiones de diseño
Se decidió representar los horarios de inicio a fin del el dataset como un entero de 5 dígitos, con el digito más significativo representando el día de la semana, de tal manera de que el lunes-sabado sean representados por 0-6.
El grupo 4 de EL2113, que los miercoles tiene clases de 7:30AM a las 9:20AM, su hora de inicio los miercoles se ve representada por el entero 20730, y su hora de salida se ve representada por 20920. Esto es así para facilitar la verificación de choques de horarios, solo necesitando comparar los horarios de un grupo con los del otro, si uno de los enteros de un grupo de un curso A se encuentra entre los enteros de un grupo de un curso B, se presenta un choque.

En el archivo del plan de estudios, se decidió solo usar el código del curso, y poner si está aprobado como un booleano, esto para hacer el archivo más sencillo de modificar manualmente.

Llenar la parte 2.2.2

# Estructuras de datos
El plan de estudios esta estructurado de tal manera de que tenga el nombre de la carrera y que tipo de archivo es el el tope de la jerarquía, y que los cursos estén el la sección cursos. Cada uno de los cursos contiene su nombre, código, cantidad de créditos, y sus requisitos y correquisitos como un arreglo. Dentro de cada uno de los cursos, hay una categoría que contiene los grupos, con el número del grupo, el nombre del profesor que lo está llevando, y una última sección dentro de cada uno de los grupos que contiene los horarios, guardados con el entero mencionado previamente.
El historial del estudiante tiene el nombre de la carrera y que tipo de archivo es al inicio del archivo. Luego, tiene todos los cursos con solo su código, y un booleano que indica si está aprobado o no.
El archivo de salida tiene que tipo de archivo es, el nombre de la carrera, los semestres considerados, y los ciclos encontrados en el tope de la jerarquía. Para los cursos individuales, tiene lo mismo que el plan de estudios, solo que con la adición de si está aprobado, si tiene los requisitos completos, los correquisitos pendientes, si es matriculable, y si presenta un choque con otro grupo, y muestra todos los grupos de un curso con los que tiene choque de horario, junto con su número de grupo y código de curso.
