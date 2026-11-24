# CEmestre - Constructor de horarios

## Etapa 3: Paradigma lógico (Prolog)

**Instituto Tecnológico de Costa Rica**  
**Escuela de Ingeniería en Computadores**  
**CE1106 - Paradigmas de Programación**  
**II Semestre, 2026**



---

## 1. Descripción del proyecto

CEmestre es un sistema que permite construir posibles horarios de
matrícula para estudiantes universitarios, considerando los cursos
disponibles, requisitos, correquisitos, choques de horario y reglas
de política académica.

El proyecto se desarrolla de manera incremental mediante cuatro
paradigmas de programación. Cada etapa recibe los datos producidos
por la anterior, realiza un procesamiento específico y genera un
archivo de salida para la siguiente etapa.

En esta tercera etapa se utiliza el paradigma lógico mediante
Prolog para evaluar las combinaciones de horarios generadas por
Racket.

El programa determina si cada combinación cumple las reglas de
política académica y, en caso contrario, identifica la primera
regla incumplida.

Adicionalmente, al tratarse de un grupo de cuatro integrantes,
se implementó una funcionalidad que permite sugerir el retiro
de un curso cuando esta acción hace que la combinación cumpla
todas las reglas de política.

## 2. Objetivos de la etapa

- Cargar las combinaciones generadas por Racket.
- Representar los cursos mediante términos compuestos y listas.
- Implementar las tres reglas de política académica mediante
  hechos y predicados.
- Identificar la primera causa de rechazo utilizando corte y
  negación por falla.
- Recorrer las combinaciones mediante backtracking.
- Implementar predicados que puedan utilizarse en diferentes
  modos de consulta.
- Sugerir el retiro de un curso cuando permita obtener una
  combinación válida.
- Exportar los resultados en un formato compatible con la
  siguiente etapa del proyecto.

---

## 3. Arquitectura del proyecto

El sistema se encuentra dividido en cuatro etapas independientes.

| Etapa | Lenguaje | Paradigma | Responsabilidad |
|---|---|---|---|
| 1 | C | Imperativo | Construcción del catálogo y validación de requisitos, correquisitos y choques de horario. |
| 2 | Racket | Funcional | Generación y filtrado de combinaciones de horarios. |
| 3 | Prolog | Lógico | Evaluación de las reglas de política académica. |
| 4 | Java | Orientado a objetos | Integración y presentación de resultados al usuario. |

### 3.1. Flujo general de información

```text
          Planes de estudio
                 |
                 v
                 C
       Validación del catálogo
                 |
                 v
              Racket
      Generación de combinaciones
                 |
                 v
          resultado.json
                 |
                 v
              Prolog
       Evaluación de políticas
                 |
                 v
       JSON con los resultados
                 |
                 v
                Java
       Presentación al usuario
```

Cada módulo funciona de manera independiente y se comunica con
los demás mediante archivos.

Prolog no ejecuta directamente el código de Racket. En su lugar,
recibe el archivo JSON generado por dicho módulo.

El componente lógico tampoco genera nuevas combinaciones ni
vuelve a realizar las validaciones correspondientes a las
etapas anteriores.

### 3.2. Flujo interno del módulo de Prolog

```text
             main.pl
                |
                v
            cargar.pl
      Lectura del archivo JSON
                |
                v
          evaluacion.pl
       Recorrido de combinaciones
                |
                v
           politica.pl <------ politica_datos.pl
        Validación lógica       Hechos de política
                |
                v
          evaluacion.pl
       Sugerencia de retiro
                |
                v
           exportar.pl
                |
                v
        Archivo JSON de salida
```

El archivo main.pl coordina la ejecución de los demás módulos.

---

## 4. Estructura del módulo

```text
Prolog/
├── cargar.pl
├── evaluacion.pl
├── exportar.pl
├── main.pl
├── politica.pl
├── politica_datos.pl
├── pruebas.pl
├── README.md
└── pruebas/
    ├── entrada.json
    ├── salida_esperada.json
    ├── salida_obtenida.json
    └── salida_real.json
```

### 4.1. Responsabilidad de cada archivo

| Archivo | Descripción |
|---|---|
| cargar.pl | Lee el archivo JSON de entrada y transforma los datos en términos de Prolog. |
| evaluacion.pl | Recorre las combinaciones, obtiene sus veredictos y genera sugerencias de retiro. |
| exportar.pl | Convierte los resultados internos de Prolog al formato JSON. |
| main.pl | Coordina la carga, evaluación y exportación de las combinaciones. |
| politica.pl | Contiene las tres reglas de política académica y el predicado principal de validación. |
| politica_datos.pl | Define los parámetros, límites y pares de cursos incompatibles. |
| pruebas.pl | Contiene las pruebas automatizadas implementadas mediante PlUnit. |
| pruebas/entrada.json | Contiene siete combinaciones controladas para comprobar el funcionamiento. |
| pruebas/salida_esperada.json | Contiene los resultados esperados de las siete combinaciones. |
| pruebas/salida_obtenida.json | Contiene los resultados generados durante la ejecución de las pruebas. |
| pruebas/salida_real.json | Contiene los resultados obtenidos utilizando el JSON real de Racket. |
| README.md | Documentación técnica y guía de ejecución del módulo. |

---

## 5. Representación de los datos

### 5.1. Representación de un curso

Cada curso se representa mediante un término compuesto de cinco
argumentos:

```prolog
curso(Codigo, Grupo, Creditos, Carrera, Area).
```

| Argumento | Tipo esperado | Descripción |
|---|---|---|
| Codigo | Átomo | Código que identifica el curso. |
| Grupo | Entero | Número del grupo seleccionado. |
| Creditos | Entero | Cantidad de créditos del curso. |
| Carrera | Átomo | Carrera a la que pertenece el curso. |
| Area | Átomo | Área académica asignada al curso. |

Ejemplo con datos controlados:

```prolog
curso(
    'TESTCE01',
    1,
    3,
    'ingenieria-computadores',
    programacion
).
```

El término anterior representa un curso de Ingeniería en
Computadores, perteneciente al área de programación, con tres
créditos y grupo número uno.

La representación mediante términos compuestos permite acceder
a los atributos necesarios utilizando unificación.

Por ejemplo, para obtener únicamente los créditos de un curso:

```prolog
curso(_, _, Creditos, _, _)
```

El carácter de subrayado representa una variable anónima cuyo
valor no interesa para esa operación.

### 5.2. Representación de una combinación

Una combinación se representa mediante una lista de términos
curso/5.

```prolog
[
    curso(
        'TESTCE01',
        1,
        3,
        'ingenieria-computadores',
        programacion
    ),
    curso(
        'TESTCO01',
        1,
        2,
        'ingenieria-construccion',
        estructuras
    )
]
```

Cada elemento de la lista representa un curso y su grupo
seleccionado.

Esta representación facilita el recorrido mediante recursividad,
unificación, backtracking y predicados propios del manejo de listas.

### 5.3. Representación de los resultados

Después de evaluar una combinación se genera un término con
la siguiente estructura:

```prolog
resultado(Id, Pares, Cumple, Razon, Sugerencia).
```

| Argumento | Descripción |
|---|---|
| Id | Identificador consecutivo de la combinación. |
| Pares | Lista de pares código-grupo. |
| Cumple | Veredicto representado mediante true o false. |
| Razon | Primera regla incumplida o el átomo ninguna. |
| Sugerencia | Curso que puede retirarse o el átomo ninguna. |

Ejemplo de una combinación válida:

```prolog
resultado(
    1,
    ['TESTCE01'-1, 'TESTCO01'-1],
    true,
    ninguna,
    ninguna
).
```

Ejemplo de una combinación rechazada:

```prolog
resultado(
    2,
    ['PI5516'-1, 'AE5121'-1],
    false,
    balance_carreras(
        'ingenieria-construccion',
        3,
        6,
        40
    ),
    retirar('AE5121'-1)
).
```

Los pares código-grupo permiten identificar los cursos originales
sin exportar nuevamente todos los atributos del catálogo.

---

## 6. Datos de política académica

Los parámetros de las reglas se encuentran separados de la
implementación lógica en el archivo politica_datos.pl.

### 6.1. Porcentaje máximo por carrera

```prolog
max_porcentaje('ingenieria-computadores', 100).
max_porcentaje('ingenieria-construccion', 40).
```

| Carrera | Porcentaje máximo de créditos |
|---|---:|
| Ingeniería en Computadores | 100% |
| Ingeniería en Construcción | 40% |

Se permite que una combinación esté formada únicamente por
cursos de Ingeniería en Computadores.

En cambio, los créditos de Ingeniería en Construcción no pueden
superar el 40% de los créditos totales de la combinación.

Estos porcentajes corresponden a parámetros definidos por el
equipo para el funcionamiento del proyecto y pueden modificarse
durante la defensa.

No representan necesariamente restricciones oficiales de
matrícula del Tecnológico de Costa Rica.

### 6.2. Límite de cursos por área

```prolog
max_cursos_area(4).
```

Se permite incluir como máximo cuatro cursos pertenecientes
a una misma área académica.

### 6.3. Cursos incompatibles

```prolog
incompatible('PI5516', 'AE5121').
incompatible('CO4108', 'CO4106').
incompatible('CE1114', 'CE1116').
```

Los pares incompatibles definidos por el equipo son:

| Curso A | Curso B | Justificación |
|---|---|---|
| PI5516 | AE5121 | Ambos corresponden a Ingeniería Económica y tienen tres créditos. Se busca evitar la duplicación de contenidos. |
| CO4108 | CO4106 | Corresponden a Taller I y Taller II del plan de Construcción. Se busca evitar que ambos talleres consecutivos se lleven simultáneamente. |
| CE1114 | CE1116 | Ambos requieren proyectos de diseño durante el semestre, por lo que sus cargas de trabajo podrían competir. |

Las justificaciones también se encuentran representadas mediante
hechos justificacion/3 dentro de politica_datos.pl.

Estos hechos se utilizan como documentación de las decisiones
del equipo y no intervienen directamente en la evaluación lógica.

Separar los parámetros de las reglas permite modificar la política
sin cambiar los algoritmos de validación.

---

## 7. Reglas de política académica

### 7.1. Regla 1: Balance entre carreras

La primera regla comprueba que ninguna carrera supere el
porcentaje máximo de créditos establecido.

El porcentaje de una carrera se obtiene mediante:

```text
                        Créditos de la carrera
Porcentaje = ---------------------------------------- × 100
              Créditos totales de la combinación
```

La implementación utiliza el predicado viola_balance/2:

```prolog
viola_balance(
    Combinacion,
    balance_carreras(Carrera, Cred, Total, Max)
) :-
    creditos_totales(Combinacion, Total),
    carrera_en(Combinacion, Carrera),
    max_porcentaje(Carrera, Max),
    creditos_carrera(Combinacion, Carrera, Cred),
    Cred * 100 > Max * Total.
```

En lugar de realizar una división, se utiliza la comparación:

```prolog
Cred * 100 > Max * Total.
```

Esta decisión evita posibles problemas de precisión asociados
con operaciones de punto flotante.

También permite comprobar correctamente los casos donde el
porcentaje obtenido coincide exactamente con el máximo permitido.

#### Ejemplo

Una combinación contiene:

| Carrera | Créditos |
|---|---:|
| Ingeniería en Computadores | 3 |
| Ingeniería en Construcción | 3 |
| Total | 6 |

El porcentaje de Construcción es:

```text
(3 / 6) × 100 = 50%
```

Como el máximo permitido es 40%, la combinación incumple
la regla.

La razón generada es:

```prolog
balance_carreras(
    'ingenieria-construccion',
    3,
    6,
    40
).
```

### 7.2. Regla 2: Límite por área

La segunda regla comprueba que la cantidad de cursos
pertenecientes a una misma área no supere el límite definido.

```prolog
viola_area(
    Combinacion,
    limite_area(Area, Cantidad, Max)
) :-
    max_cursos_area(Max),
    area_en(Combinacion, Area),
    cursos_por_area(Combinacion, Area, Cantidad),
    Cantidad > Max.
```

Para obtener la cantidad de cursos de un área se utiliza:

```prolog
cursos_por_area(Combinacion, Area, Cantidad) :-
    findall(
        Cod,
        member(curso(Cod, _, _, _, Area), Combinacion),
        Cods
    ),
    length(Cods, Cantidad).
```

Se utiliza findall/3 para reunir los códigos de todos los cursos
pertenecientes al área consultada.

Posteriormente, length/2 determina la cantidad de elementos de
la lista resultante.

#### Ejemplo

| Curso | Área |
|---|---|
| TESTCE01 | programacion |
| TESTCE02 | programacion |
| TESTCE03 | programacion |
| TESTCE04 | programacion |
| TESTCE05 | programacion |

Cantidad de cursos: 5.

Máximo permitido: 4.

La razón generada es:

```prolog
limite_area(programacion, 5, 4).
```

La regla utiliza la cantidad de cursos y no la cantidad
de créditos.

### 7.3. Regla 3: Incompatibilidad entre cursos

La tercera regla determina si una combinación contiene ambos
cursos de un par declarado incompatible.

```prolog
viola_incompatibilidad(
    Combinacion,
    incompatibilidad(A, B)
) :-
    incompatibles(A, B),
    member(curso(A, _, _, _, _), Combinacion),
    member(curso(B, _, _, _, _), Combinacion).
```

El predicado member/2 permite comprobar si un curso se encuentra
dentro de la lista que representa la combinación.

La incompatibilidad se implementa de forma simétrica:

```prolog
incompatibles(A, B) :-
    incompatible(A, B).

incompatibles(A, B) :-
    incompatible(B, A).
```

De esta manera, no es necesario declarar cada par dos veces
en el archivo de política.

Por ejemplo:

```prolog
?- incompatibles('CE1114', 'CE1116').
true.

?- incompatibles('CE1116', 'CE1114').
true.
```

La incompatibilidad se detecta independientemente del orden en
que aparezcan los cursos dentro de la combinación.

---

## 8. Decisiones de diseño

### 8.1. Asignación del área académica

El campo area se incorpora al catálogo de cursos en la etapa
de C y se propaga mediante Racket hasta el módulo de Prolog.

Su finalidad es clasificar los cursos de acuerdo con su contenido
académico y aplicar restricciones sobre la concentración de
asignaturas de una misma área.

Como ejemplos del criterio de clasificación se consideran:

| Curso o tipo de curso | Área de referencia | Justificación |
|---|---|---|
| Paradigmas de Programación | programacion | Estudia técnicas y paradigmas de programación. |
| Ingeniería Económica | economia | Se relaciona con la evaluación económica de alternativas. |
| Cursos de Matemática | matematica | Desarrollan herramientas matemáticas utilizadas en ingeniería. |
| Talleres de Construcción | construccion | Desarrollan conocimientos propios del área constructiva. |
| Cursos de estructuras | estructuras | Analizan el comportamiento de elementos estructurales. |

Las etiquetas definitivas de cada curso corresponden a las
establecidas en los catálogos de ambos planes de estudio.

Prolog utiliza directamente el área recibida desde Racket y no
realiza una nueva clasificación de los cursos.

### 8.2. Extensión de los planes de estudio

Para esta etapa se extendieron los planes de estudio de Ingeniería
en Computadores e Ingeniería en Construcción hasta el octavo
semestre.

La ampliación se realiza en los datos utilizados por el módulo
de C, manteniendo la separación de responsabilidades entre
los diferentes paradigmas.

También se incorpora el campo area al catálogo para que la
información necesaria pueda llegar hasta Prolog.

### 8.3. Orden de evaluación de las reglas

El orden establecido por el equipo es:

1. Balance entre carreras.
2. Límite de cursos por área.
3. Incompatibilidad entre cursos.

Se decidió evaluar primero las condiciones generales de la
combinación, posteriormente las agrupaciones por área y finalmente
las relaciones específicas entre pares de cursos.

La implementación es:

```prolog
violacion(Combinacion, Razon) :-
    viola_balance(Combinacion, Razon), !.

violacion(Combinacion, Razon) :-
    viola_area(Combinacion, Razon), !.

violacion(Combinacion, Razon) :-
    viola_incompatibilidad(Combinacion, Razon), !.
```

La prioridad depende del orden de las cláusulas.

Cuando se encuentra una violación, el corte impide continuar
buscando otras razones de rechazo en esa evaluación.

### 8.4. Caso donde el orden cambia la razón reportada

Considérese la siguiente combinación:

```prolog
[
    curso(
        'PI5516',
        1,
        3,
        'ingenieria-computadores',
        economia
    ),
    curso(
        'AE5121',
        1,
        3,
        'ingenieria-construccion',
        economia
    )
]
```

Esta combinación incumple dos reglas:

- Ingeniería en Construcción representa el 50% de los créditos,
  superando el máximo permitido de 40%.
- Los cursos PI5516 y AE5121 forman un par incompatible.

| Regla | Resultado |
|---|---|
| Balance entre carreras | Incumple |
| Límite por área | Cumple |
| Incompatibilidad | Incumple |

Con el orden actual se obtiene:

```prolog
balance_carreras(
    'ingenieria-construccion',
    3,
    6,
    40
).
```

Si se modificara el orden de las cláusulas para evaluar primero
la incompatibilidad, se obtendría:

```prolog
incompatibilidad('PI5516', 'AE5121').
```

En ambos casos la combinación sería rechazada, pero cambiaría
la explicación proporcionada al usuario.

Este comportamiento se comprueba mediante la prueba automatizada
primera_razon_de_rechazo.

### 8.5. Uso del corte

El corte, representado mediante el operador !, se utiliza
para evitar que Prolog continúe buscando alternativas después
de encontrar la primera violación.

```prolog
evaluar(Combinacion, false, Razon) :-
    violacion(Combinacion, Razon),
    !.
```

Su utilización permite que el programa reporte una sola razón
por combinación durante el flujo normal de evaluación.

También se utiliza para conservar la primera sugerencia de
retiro que produce una combinación válida.

El corte no impide que el programa continúe evaluando las demás
combinaciones del archivo de entrada.

### 8.6. Negación por falla

La negación por falla se representa mediante el operador \+.

```prolog
evaluar(Combinacion, true, ninguna) :-
    \+ violacion(Combinacion, _).
```

Una combinación se considera válida cuando no puede demostrarse
ninguna violación de las reglas definidas.

La negación por falla también se utiliza para determinar que
no existe una sugerencia válida de retiro:

```prolog
sugerir_retiro(Combinacion, ninguna) :-
    \+ retiro_valido(Combinacion, _).
```

### 8.7. Backtracking

El recorrido de las combinaciones se realiza mediante el
predicado combinacion_id/4.

```prolog
combinacion_id([Combinacion | _], N, N, Combinacion).

combinacion_id([_ | Resto], N0, Id, Combinacion) :-
    N1 is N0 + 1,
    combinacion_id(Resto, N1, Id, Combinacion).
```

La primera cláusula devuelve la combinación actual.

La segunda cláusula permite continuar recorriendo el resto
de la lista e incrementar el identificador.

Cuando se solicitan nuevas soluciones, Prolog utiliza
backtracking para obtener las demás combinaciones.

Posteriormente, findall/3 reúne los resultados en una lista
para realizar su exportación.

```prolog
evaluar_todas(Combinaciones, Resultados) :-
    findall(
        resultado(Id, Pares, Cumple, Razon, Sugerencia),
        (
            veredicto(
                Combinaciones,
                Id,
                Combinacion,
                Cumple,
                Razon
            ),
            pares_curso_grupo(Combinacion, Pares),
            sugerencia(Cumple, Combinacion, Sugerencia)
        ),
        Resultados
    ).
```

Los resultados intermedios se manejan mediante argumentos,
unificación y listas.

No se utilizan assert/retract ni variables globales para
almacenar los resultados de la evaluación.

### 8.8. Selección del formato JSON

Se decidió utilizar JSON como formato de intercambio entre
Racket, Prolog y Java debido a las siguientes características:

- Permite representar listas y objetos.
- Admite estructuras anidadas.
- Permite representar valores booleanos y valores nulos.
- Es independiente del lenguaje de programación.
- Facilita la lectura de los archivos durante las pruebas.
- Permite representar diferentes tipos de razones de rechazo
  sin utilizar una estructura tabular rígida.

A diferencia de un archivo CSV, JSON permite representar una
combinación con una cantidad variable de cursos y agregar
información específica sobre cada regla incumplida.

La salida JSON constituye el contrato de intercambio con el
módulo de Java.

---

## 9. Sugerencia de retiro de cursos

Como requisito adicional para los grupos de cuatro integrantes,
el programa debe determinar si retirar un curso de una combinación
rechazada permite cumplir todas las reglas.

Para ello se utiliza el predicado select/3:

```prolog
retiro_valido(Combinacion, Cod-Gr) :-
    select(
        curso(Cod, Gr, _, _, _),
        Combinacion,
        Resto
    ),
    Resto \== [],
    evaluar(Resto, true, _).
```

El procedimiento consiste en:

1. Seleccionar un curso de la combinación.
2. Obtener una lista sin el curso seleccionado.
3. Comprobar que la lista restante no esté vacía.
4. Volver a evaluar la combinación mediante evaluar/3.
5. Si cumple todas las reglas, conservar la sugerencia.
6. Si no cumple, continuar probando los demás cursos.
7. Si ningún retiro funciona, indicar que no existe sugerencia.

Se utiliza el mismo predicado evaluar/3 para evitar duplicar
la lógica de las reglas de política.

### 9.1. Selección de la primera sugerencia válida

```prolog
sugerir_retiro(Combinacion, retirar(Par)) :-
    retiro_valido(Combinacion, Par), !.

sugerir_retiro(Combinacion, ninguna) :-
    \+ retiro_valido(Combinacion, _).
```

Si existen varias alternativas válidas, se conserva la primera
encontrada según el orden de los cursos de la combinación.

### 9.2. Ejemplo de sugerencia

Combinación original:

| Curso | Créditos | Carrera |
|---|---:|---|
| PI5516 | 3 | Computadores |
| AE5121 | 3 | Construcción |

La combinación incumple el balance entre carreras y contiene
un par incompatible.

Se prueban los siguientes retiros:

| Curso retirado | Combinación restante | Resultado |
|---|---|---|
| PI5516 | AE5121 | No cumple: Construcción representa el 100%. |
| AE5121 | PI5516 | Cumple todas las reglas. |

Por lo tanto, la sugerencia es:

```prolog
retirar('AE5121'-1).
```

El retiro sugerido no modifica la combinación original.

La sugerencia garantiza únicamente el cumplimiento de las
reglas de política evaluadas en Prolog. No implica que se
hayan comprobado nuevamente los correquisitos o los límites
de créditos correspondientes a las etapas anteriores.

---

## 10. Predicados principales

| Predicado | Función |
|---|---|
| main/1 | Coordina la ejecución general del programa. |
| cargar_combinaciones/2 | Carga las combinaciones desde un archivo JSON. |
| json_a_combinacion/2 | Convierte un objeto JSON en una lista de cursos. |
| json_a_curso/2 | Convierte un objeto JSON en un término curso/5. |
| evaluar/3 | Determina si una combinación cumple las reglas. |
| violacion/2 | Obtiene una violación según la prioridad establecida. |
| viola_balance/2 | Comprueba el porcentaje de créditos por carrera. |
| carrera_en/2 | Identifica las carreras presentes en la combinación. |
| creditos_totales/2 | Obtiene la cantidad total de créditos. |
| creditos_carrera/3 | Obtiene los créditos correspondientes a una carrera. |
| sumar_creditos/2 | Suma los créditos mediante recursividad. |
| porcentaje_carrera/3 | Calcula el porcentaje de créditos de una carrera. |
| viola_area/2 | Comprueba el límite de cursos por área. |
| area_en/2 | Identifica las áreas presentes. |
| cursos_por_area/3 | Cuenta los cursos pertenecientes a un área. |
| viola_incompatibilidad/2 | Detecta pares de cursos incompatibles. |
| incompatibles/2 | Representa la incompatibilidad simétrica. |
| curso_en_combinacion/3 | Verifica o enumera cursos de una combinación. |
| veredicto/5 | Obtiene una combinación junto con su evaluación. |
| combinacion_id/4 | Recorre las combinaciones mediante backtracking. |
| evaluar_todas/2 | Reúne todos los resultados de la evaluación. |
| sugerencia/3 | Determina si corresponde generar una sugerencia. |
| sugerir_retiro/2 | Obtiene la primera sugerencia válida. |
| retiro_valido/2 | Comprueba si retirar un curso resuelve las violaciones. |
| pares_curso_grupo/2 | Extrae los pares de códigos y grupos. |
| exportar_resultados/2 | Genera el archivo JSON de salida. |
| resultado_json/2 | Transforma un resultado en un objeto JSON. |
| razon_json/2 | Convierte una razón de rechazo al formato JSON. |
| sugerencia_json/3 | Convierte una sugerencia al formato JSON. |

---

## 11. Predicado con múltiples modos de consulta

El predicado curso_en_combinacion/3 permite realizar consultas
utilizando diferentes combinaciones de argumentos instanciados
y variables libres.

```prolog
curso_en_combinacion(Codigo, Grupo, Combinacion) :-
    member(
        curso(Codigo, Grupo, _, _, _),
        Combinacion
    ).
```

### 11.1. Modo de verificación

```prolog
curso_en_combinacion(+Codigo, +Grupo, +Combinacion)
```

El código, grupo y combinación se encuentran instanciados.

Permite verificar si un curso y grupo específicos pertenecen
a la combinación.

Ejemplo:

```prolog
?- curso_en_combinacion(
    'TESTCE01',
    1,
    [
        curso(
            'TESTCE01',
            1,
            3,
            'ingenieria-computadores',
            programacion
        )
    ]
).
```

Resultado esperado:

```prolog
true.
```

Si se consulta un grupo inexistente:

```prolog
?- curso_en_combinacion(
    'TESTCE01',
    2,
    [
        curso(
            'TESTCE01',
            1,
            3,
            'ingenieria-computadores',
            programacion
        )
    ]
).
```

Resultado esperado:

```prolog
false.
```

### 11.2. Modo de enumeración

```prolog
curso_en_combinacion(-Codigo, -Grupo, +Combinacion)
```

La combinación se encuentra instanciada, mientras que Codigo
y Grupo son variables libres.

```prolog
?- curso_en_combinacion(
    Codigo,
    Grupo,
    [
        curso(
            'TESTCE01',
            1,
            3,
            'ingenieria-computadores',
            programacion
        ),
        curso(
            'TESTCO01',
            1,
            2,
            'ingenieria-construccion',
            estructuras
        )
    ]
).
```

Resultados esperados:

```prolog
Codigo = 'TESTCE01',
Grupo = 1 ;

Codigo = 'TESTCO01',
Grupo = 1.
```

El punto y coma permite solicitar la siguiente solución mediante
backtracking.

### 11.3. Modo parcialmente instanciado

```prolog
curso_en_combinacion(+Codigo, -Grupo, +Combinacion)
```

Permite consultar el grupo correspondiente a un código
conocido.

```prolog
?- curso_en_combinacion(
    'TESTCE01',
    Grupo,
    [
        curso(
            'TESTCE01',
            1,
            3,
            'ingenieria-computadores',
            programacion
        )
    ]
).
```

Resultado esperado:

```prolog
Grupo = 1.
```

Los tres modos utilizan exactamente la misma implementación.

Esto demuestra una característica del paradigma lógico:
un mismo predicado puede utilizarse para comprobar una
relación o para encontrar valores que satisfagan dicha relación.

---

## 12. Formato de entrada

El módulo recibe un archivo JSON generado por Racket.

El archivo debe contener una propiedad combinaciones, cuyo valor
es una lista de objetos.

Cada combinación contiene una propiedad cursos, que almacena
los cursos seleccionados.

Ejemplo de entrada:

```json
{
  "combinaciones": [
    {
      "cursos": [
        {
          "codigo": "TESTCE01",
          "grupo": 1,
          "creditos": 3,
          "carrera": "ingenieria-computadores",
          "area": "programacion"
        },
        {
          "codigo": "TESTCO01",
          "grupo": 1,
          "creditos": 2,
          "carrera": "ingenieria-construccion",
          "area": "estructuras"
        }
      ]
    }
  ]
}
```

### 12.1. Campos obligatorios por curso

| Campo | Tipo JSON | Descripción |
|---|---|---|
| codigo | String | Código del curso. |
| grupo | Número entero | Grupo seleccionado. |
| creditos | Número entero | Créditos correspondientes al curso. |
| carrera | String | Identificador de la carrera. |
| area | String | Identificador del área académica. |

Los nombres de los campos deben mantenerse para garantizar
la compatibilidad entre Racket y Prolog.

### 12.2. Transformación de JSON a Prolog

El predicado json_a_curso/2 realiza la transformación de los
datos recibidos:

```prolog
json_a_curso(
    Objeto,
    curso(Codigo, Grupo, Creditos, Carrera, Area)
) :-
    Codigo   = Objeto.codigo,
    Grupo    = Objeto.grupo,
    Creditos = Objeto.creditos,
    Carrera  = Objeto.carrera,
    Area     = Objeto.area.
```

La biblioteca library(http/json) permite interpretar el archivo.

Se utiliza la opción value_string_as(atom) para representar
las cadenas recibidas como átomos de Prolog.

---

## 13. Formato de salida

La salida contiene los resultados de todas las combinaciones
evaluadas.

### 13.1. Combinación válida

```json
{
  "combinaciones": [
    {
      "id": 1,
      "cursos": [
        {
          "codigo": "TESTCE01",
          "grupo": 1
        },
        {
          "codigo": "TESTCO01",
          "grupo": 1
        }
      ],
      "cumple": true,
      "razon": null,
      "sugerencia": null
    }
  ]
}
```

### 13.2. Combinación rechazada con sugerencia

```json
{
  "combinaciones": [
    {
      "id": 2,
      "cursos": [
        {
          "codigo": "PI5516",
          "grupo": 1
        },
        {
          "codigo": "AE5121",
          "grupo": 1
        }
      ],
      "cumple": false,
      "razon": {
        "regla": "balance_carreras",
        "carrera": "ingenieria-construccion",
        "creditos": 3,
        "total": 6,
        "max_porcentaje": 40
      },
      "sugerencia": {
        "existe": true,
        "retirar": {
          "codigo": "AE5121",
          "grupo": 1
        }
      }
    }
  ]
}
```

### 13.3. Combinación sin sugerencia válida

Cuando la combinación es rechazada y ningún retiro individual
permite cumplir todas las reglas, la sugerencia contiene:

```json
{
  "existe": false,
  "retirar": null
}
```

### 13.4. Descripción de los campos de salida

| Campo | Tipo JSON | Descripción |
|---|---|---|
| combinaciones | Array | Lista de resultados. |
| id | Integer | Identificador consecutivo. |
| cursos | Array | Lista de pares código-grupo. |
| cumple | Boolean | Indica si la combinación cumple las reglas. |
| razon | Object o null | Primera regla incumplida. |
| sugerencia | Object o null | Información sobre el posible retiro. |

### 13.5. Estructura de las razones

Balance entre carreras:

```json
{
  "regla": "balance_carreras",
  "carrera": "ingenieria-construccion",
  "creditos": 3,
  "total": 6,
  "max_porcentaje": 40
}
```

Límite por área:

```json
{
  "regla": "limite_area",
  "area": "programacion",
  "cantidad": 5,
  "maximo": 4
}
```

Incompatibilidad:

```json
{
  "regla": "incompatibilidad",
  "curso_a": "CE1114",
  "curso_b": "CE1116"
}
```

Esta estructura permite que Java identifique la regla incumplida
y utilice sus parámetros para construir un mensaje descriptivo.

---

## 14. Instalación y ejecución

### 14.1. Requisitos

- SWI-Prolog.
- Git.
- Archivo JSON con las combinaciones generadas por Racket.
- Editor de código, como Visual Studio Code.

El módulo fue probado utilizando SWI-Prolog 11.0.1 de 64 bits
en Windows mediante Git Bash.

### 14.2. Instalación de SWI-Prolog

SWI-Prolog puede descargarse desde su página oficial:

https://www.swi-prolog.org/download/stable

Para comprobar que se encuentra instalado:

```bash
swipl --version
```

### 14.3. Ubicación dentro del repositorio

Desde la raíz del proyecto:

```bash
cd Prolog
```

Los comandos siguientes deben ejecutarse desde este directorio.

### 14.4. Ejecución general

La estructura del comando es:

```bash
swipl -q -s main.pl -- entrada.json salida.json
```

Donde:

- -q reduce los mensajes informativos del intérprete.
- -s indica el archivo fuente que debe cargarse.
- main.pl es el archivo principal del módulo.
- -- separa las opciones de SWI-Prolog de los argumentos del programa.
- entrada.json corresponde al archivo de combinaciones.
- salida.json corresponde al archivo que contendrá los resultados.

### 14.5. Ejecutar las combinaciones de prueba

```bash
swipl -q -s main.pl -- pruebas/entrada.json pruebas/salida_obtenida.json
```

Resultado obtenido:

```text
Evaluadas 7 combinaciones. Resultado en pruebas/salida_obtenida.json
```

### 14.6. Ejecutar con el archivo real de Racket

```bash
swipl -q -s main.pl -- ../racket/resultado.json pruebas/salida_real.json
```

Resultado obtenido:

```text
Evaluadas 2 combinaciones. Resultado en pruebas/salida_real.json
```

La cantidad de combinaciones evaluadas puede cambiar dependiendo
del archivo generado por Racket.

### 14.7. Ejecutar las pruebas automatizadas

```bash
swipl -q -s pruebas.pl -g run_tests -t halt
```

Donde:

- run_tests ejecuta las pruebas definidas mediante PlUnit.
- halt finaliza el intérprete después de ejecutar las pruebas.

### 14.8. Comparar los resultados

Para abrir los archivos en modo comparación utilizando
Visual Studio Code:

```bash
code --diff pruebas/salida_esperada.json pruebas/salida_obtenida.json
```

Pueden existir diferencias de formato, indentación u orden de
las propiedades JSON sin que exista una diferencia en los datos.

Por esta razón, la prueba automatizada de exportación compara
las estructuras interpretadas y no únicamente el texto de
los archivos.

---

## 15. Consultas interactivas en Prolog

Desde la carpeta Prolog, ejecutar:

```bash
swipl
```

Posteriormente, cargar los archivos necesarios:

```prolog
?- [cargar, evaluacion, politica_datos, exportar].
```

### 15.1. Consultar los porcentajes máximos

```prolog
?- max_porcentaje(Carrera, Maximo).
```

Resultados esperados:

```prolog
Carrera = 'ingenieria-computadores',
Maximo = 100 ;

Carrera = 'ingenieria-construccion',
Maximo = 40.
```

### 15.2. Consultar el máximo de cursos por área

```prolog
?- max_cursos_area(Maximo).
```

Resultado:

```prolog
Maximo = 4.
```

### 15.3. Consultar los pares incompatibles

```prolog
?- incompatible(A, B).
```

Resultados esperados:

```prolog
A = 'PI5516',
B = 'AE5121' ;

A = 'CO4108',
B = 'CO4106' ;

A = 'CE1114',
B = 'CE1116'.
```

### 15.4. Evaluar directamente una combinación válida

```prolog
?- evaluar(
    [
        curso(
            'TESTCE01',
            1,
            3,
            'ingenieria-computadores',
            programacion
        ),
        curso(
            'TESTCO01',
            1,
            2,
            'ingenieria-construccion',
            estructuras
        )
    ],
    Cumple,
    Razon
).
```

Resultado esperado:

```prolog
Cumple = true,
Razon = ninguna.
```

### 15.5. Evaluar una combinación rechazada

```prolog
?- evaluar(
    [
        curso(
            'PI5516',
            1,
            3,
            'ingenieria-computadores',
            economia
        ),
        curso(
            'AE5121',
            1,
            3,
            'ingenieria-construccion',
            economia
        )
    ],
    Cumple,
    Razon
).
```

Resultado esperado:

```prolog
Cumple = false,
Razon = balance_carreras(
    'ingenieria-construccion',
    3,
    6,
    40
).
```

### 15.6. Salir del intérprete

```prolog
?- halt.
```

---

## 16. Estrategia de pruebas

Para comprobar el funcionamiento del módulo se utilizaron
tres tipos de pruebas.

| Tipo de prueba | Objetivo |
|---|---|
| Unitarias | Comprobar el funcionamiento de predicados específicos. |
| Funcionales | Evaluar combinaciones con resultados conocidos previamente. |
| Integración | Verificar la compatibilidad entre la salida real de Racket y Prolog. |

Se utilizaron tanto combinaciones controladas como combinaciones
reales generadas por Racket.

Las combinaciones controladas permiten comprobar situaciones
específicas que no necesariamente se presentan en un archivo
real de matrícula.

Los códigos que comienzan con TEST corresponden a cursos
sintéticos utilizados exclusivamente para las pruebas.

Estos datos no modifican los planes de estudio originales.

### 16.1. Casos funcionales

| Caso | Descripción | Resultado esperado | Resultado obtenido |
|---|---|---|---|
| 1 | Construcción representa exactamente el 40% de los créditos. | Válido | Válido |
| 2 | Incumple balance e incompatibilidad. | Rechazo por balance | Rechazo por balance |
| 3 | Contiene cinco cursos de programación. | Rechazo por área | Rechazo por área |
| 4 | Contiene un par incompatible en orden inverso. | Rechazo por incompatibilidad | Rechazo por incompatibilidad |
| 5 | Contiene dos incompatibilidades independientes. | Rechazo sin retiro válido | Rechazo sin retiro válido |
| 6 | Contiene únicamente un curso de Construcción. | Rechazo sin retiro válido | Rechazo sin retiro válido |
| 7 | Contiene exactamente cuatro cursos de programación. | Válido | Válido |

### 16.2. Sugerencias esperadas y obtenidas

| Caso | Sugerencia esperada | Sugerencia obtenida |
|---|---|---|
| 1 | Ninguna | Ninguna |
| 2 | Retirar AE5121, grupo 1 | Retirar AE5121, grupo 1 |
| 3 | Retirar TESTCE01, grupo 1 | Retirar TESTCE01, grupo 1 |
| 4 | Retirar CE1116, grupo 1 | Retirar CE1116, grupo 1 |
| 5 | No existe retiro válido | No existe retiro válido |
| 6 | No existe retiro válido | No existe retiro válido |
| 7 | Ninguna | Ninguna |

De las siete combinaciones evaluadas:

- Dos fueron aceptadas.
- Cinco fueron rechazadas.
- Tres combinaciones rechazadas recibieron una sugerencia válida.
- Dos combinaciones rechazadas no pudieron resolverse mediante
  el retiro de un único curso.

Los resultados obtenidos coincidieron con los resultados
esperados.

---

## 17. Casos límite

### 17.1. Porcentaje exactamente igual al máximo

La primera combinación de prueba contiene tres créditos de
Ingeniería en Computadores y dos créditos de Ingeniería
en Construcción.

```text
Créditos totales = 5
Créditos de Construcción = 2
Porcentaje máximo = 40%

(2 / 5) × 100 = 40%
```

La comparación realizada por el programa es:

```text
2 × 100 > 40 × 5

200 > 200
```

La condición es falsa, por lo que no existe una violación.

Se decidió utilizar el operador mayor estricto porque alcanzar
el máximo permitido no representa un incumplimiento.

Resultado obtenido: combinación válida.

### 17.2. Cantidad de cursos igual al límite

Una combinación contiene exactamente cuatro cursos de
programación.

```text
Cantidad = 4
Máximo = 4

4 > 4
```

La condición es falsa.

Resultado obtenido: combinación válida.

Al incorporar un quinto curso de la misma área, la combinación
es rechazada.

### 17.3. Retiro del único curso de una combinación

Se evaluó una combinación formada únicamente por un curso de
Ingeniería en Construcción.

Como dicha carrera representa el 100% de los créditos,
la combinación incumple la regla de balance.

Retirar el único curso produciría una lista vacía.

Aunque una lista vacía no contiene violaciones de política,
no constituye una sugerencia útil para construir un horario.

Para evitar este resultado se utiliza:

```prolog
Resto \== []
```

Resultado obtenido: combinación rechazada sin sugerencia
de retiro.

### 17.4. Dos incompatibilidades independientes

Se evaluó una combinación con los siguientes cursos:

```text
CE1114 <--> CE1116

PI5516 <--> AE5121
```

La combinación presenta dos pares incompatibles independientes.

Retirar un curso puede resolver uno de los conflictos, pero el
otro permanece.

El programa vuelve a evaluar todas las reglas después de
cada posible retiro.

Resultado obtenido: no existe una sugerencia individual válida.

Este caso comprueba que la sugerencia no se limita a resolver
la primera causa de rechazo, sino que debe producir una
combinación que cumpla todas las reglas.

---

## 18. Pruebas automatizadas

Las pruebas automatizadas se encuentran en el archivo pruebas.pl.

Se utilizó PlUnit, una biblioteca de SWI-Prolog que permite
definir y ejecutar pruebas sobre los predicados del programa.

### 18.1. Pruebas implementadas

| N.º | Prueba | Descripción | Resultado |
|---:|---|---|---|
| 1 | cantidad_combinaciones | Comprueba la carga de las siete combinaciones. | Superada |
| 2 | estructura_curso | Verifica la representación del término curso/5. | Superada |
| 3 | balance_en_limite | Comprueba la aceptación del 40% exacto. | Superada |
| 4 | balance_excedido | Detecta un porcentaje superior al permitido. | Superada |
| 5 | area_excedida | Detecta cinco cursos de una misma área. | Superada |
| 6 | area_en_limite | Comprueba la aceptación de cuatro cursos de una misma área. | Superada |
| 7 | incompatibilidad_detectada | Detecta un par incompatible. | Superada |
| 8 | incompatibilidad_simetrica | Comprueba ambos sentidos de la relación. | Superada |
| 9 | primera_razon_de_rechazo | Verifica que se conserve la primera violación. | Superada |
| 10 | retiro_por_balance | Comprueba una sugerencia que resuelve el balance. | Superada |
| 11 | retiro_por_area | Comprueba una sugerencia que resuelve el límite por área. | Superada |
| 12 | retiro_por_incompatibilidad | Comprueba una sugerencia que elimina una incompatibilidad. | Superada |
| 13 | sin_retiro_individual_valido | Comprueba una combinación que no puede resolverse con un retiro. | Superada |
| 14 | no_sugerir_horario_vacio | Evita sugerir una combinación vacía. | Superada |
| 15 | verificar_curso | Comprueba el modo de verificación del predicado multimodo. | Superada |
| 16 | enumerar_cursos | Comprueba el modo de enumeración mediante backtracking. | Superada |
| 17 | recorrido_completo | Verifica el recorrido de todas las combinaciones. | Superada |
| 18 | exportacion_json | Compara la estructura JSON obtenida con la esperada. | Superada |

### 18.2. Resumen de resultados

| Funcionalidad | Pruebas realizadas | Pruebas superadas |
|---|---:|---:|
| Carga y representación de datos | 2 | 2 |
| Balance entre carreras | 2 | 2 |
| Límite por área | 2 | 2 |
| Incompatibilidad | 2 | 2 |
| Prioridad de las reglas | 1 | 1 |
| Sugerencias de retiro | 5 | 5 |
| Predicado multimodo | 2 | 2 |
| Recorrido por backtracking | 1 | 1 |
| Exportación JSON | 1 | 1 |
| **Total** | **18** | **18** |

Resultado general:

```text
Pruebas ejecutadas: 18
Pruebas superadas: 18
Pruebas fallidas: 0
Porcentaje de pruebas superadas: 100%
```

El porcentaje corresponde únicamente a las pruebas implementadas
y no representa una medición de cobertura completa del código.

Durante la ejecución inicial se presentó una advertencia
de choicepoint en la prueba exportacion_json.

La advertencia indica que el objetivo finalizó correctamente,
pero dejó un punto de elección disponible para buscar otras
soluciones mediante backtracking.

No se registraron fallos de las pruebas.

### 18.3. Herramientas utilizadas en las pruebas

| Predicado o herramienta | Utilización |
|---|---|
| begin_tests/1 | Define el inicio de un conjunto de pruebas. |
| end_tests/1 | Define el final del conjunto de pruebas. |
| test/1 | Identifica cada caso de prueba. |
| assertion/1 | Comprueba que una condición se cumpla. |
| findall/3 | Reúne las soluciones obtenidas mediante backtracking. |
| nth1/3 | Selecciona una combinación específica según su posición. |
| setup_call_cleanup/3 | Permite gestionar archivos y recursos durante las pruebas. |
| tmp_file_stream/3 | Crea un archivo temporal para comprobar la exportación. |
| =@= | Compara estructuras mediante equivalencia de variantes. |
| delete_file/1 | Elimina los archivos temporales utilizados en las pruebas. |

### 18.4. Prueba de exportación

La prueba exportacion_json verifica el flujo completo del módulo.

El procedimiento realizado es:

1. Cargar las combinaciones del archivo entrada.json.
2. Evaluar todas las combinaciones.
3. Generar las sugerencias correspondientes.
4. Exportar los resultados a un archivo temporal.
5. Leer el archivo generado.
6. Leer el archivo salida_esperada.json.
7. Comparar ambas estructuras.
8. Eliminar el archivo temporal.

Se utiliza la comparación:

```prolog
assertion(Obtenido =@= Esperado).
```

Esto permite verificar la equivalencia de las estructuras
obtenidas después de interpretar ambos archivos JSON.

---

## 19. Prueba de integración con Racket

Además de las pruebas controladas, se utilizó el archivo
resultado.json generado por el módulo de Racket.

El comando ejecutado fue:

```bash
swipl -q -s main.pl -- ../racket/resultado.json pruebas/salida_real.json
```

Resultado obtenido en la terminal:

```text
Evaluadas 2 combinaciones. Resultado en pruebas/salida_real.json
```

El archivo real de Racket contenía dos combinaciones
correspondientes al curso CE1106 (Paradigmas de Programación),
cada una con un grupo diferente.

### 19.1. Resultados obtenidos

| Identificador | Curso | Grupo | Cumple | Razón | Sugerencia |
|---:|---|---:|---|---|---|
| 1 | CE1106 | 1 | true | null | null |
| 2 | CE1106 | 2 | true | null | null |

Ambas combinaciones fueron aceptadas por el módulo de Prolog.

Los resultados no corresponden a combinaciones duplicadas,
debido a que representan grupos diferentes del mismo curso.

### 19.2. Archivo JSON generado

```json
{
  "combinaciones": [
    {
      "cumple": true,
      "cursos": [
        {
          "codigo": "CE1106",
          "grupo": 1
        }
      ],
      "id": 1,
      "razon": null,
      "sugerencia": null
    },
    {
      "cumple": true,
      "cursos": [
        {
          "codigo": "CE1106",
          "grupo": 2
        }
      ],
      "id": 2,
      "razon": null,
      "sugerencia": null
    }
  ]
}
```

El módulo generó un resultado por cada combinación recibida,
conservando los códigos y grupos originales.

Al no detectarse violaciones, los campos razon y sugerencia
contienen el valor null.

### 19.3. Alcance de la integración

La ejecución permitió comprobar que Prolog puede:

- Leer el archivo generado por Racket.
- Interpretar las combinaciones recibidas.
- Evaluar las reglas de política.
- Conservar los códigos y grupos.
- Asignar identificadores consecutivos.
- Generar un archivo JSON con los resultados.

Las combinaciones reales no presentaron rechazos.

Por esta razón, se complementó la prueba de integración con
las siete combinaciones controladas y las 18 pruebas
automatizadas.

La combinación de ambos tipos de pruebas permitió evaluar
tanto la comunicación entre Racket y Prolog como los diferentes
escenarios de aceptación y rechazo.

### 19.4. Comparación de las pruebas controladas y reales

| Funcionalidad | Pruebas controladas | Prueba real |
|---|---|---|
| Carga de combinaciones | Sí | Sí |
| Representación de cursos | Sí | Sí |
| Aceptación de combinaciones | Sí | Sí |
| Rechazo por balance | Sí | No se presentó |
| Rechazo por área | Sí | No se presentó |
| Rechazo por incompatibilidad | Sí | No se presentó |
| Prioridad de las reglas | Sí | No se presentó |
| Sugerencias de retiro | Sí | No se presentó |
| Casos límite | Sí | No se presentó |
| Exportación JSON | Sí | Sí |
| Integración con Racket | No aplica | Sí |

La integración efectiva con Java corresponde a la siguiente
etapa del proyecto y todavía no forma parte de las pruebas
realizadas.

---

## 20. Evidencia de las pruebas

Los archivos utilizados y generados durante las pruebas se
encuentran en el directorio pruebas.

| Archivo | Contenido |
|---|---|
| entrada.json | Siete combinaciones controladas. |
| salida_esperada.json | Resultados definidos antes de la ejecución. |
| salida_obtenida.json | Resultados generados por Prolog. |
| salida_real.json | Resultados de las dos combinaciones reales de Racket. |

Las pruebas pueden reproducirse mediante los comandos de
ejecución incluidos en este documento.

---

## 21. Modificación de los parámetros durante la defensa

Los parámetros de política se encuentran centralizados en
politica_datos.pl.

### 21.1. Cambiar el porcentaje máximo por carrera

Por ejemplo, para modificar el máximo de Construcción de
40% a 60%:

```prolog
max_porcentaje('ingenieria-computadores', 100).
max_porcentaje('ingenieria-construccion', 60).
```

No es necesario modificar politica.pl, debido a que la regla
consulta directamente el hecho max_porcentaje/2.

### 21.2. Cambiar el máximo de cursos por área

Para permitir solamente tres cursos de una misma área:

```prolog
max_cursos_area(3).
```

La regla viola_area/2 utilizará automáticamente el nuevo valor.

### 21.3. Agregar un par incompatible

Se puede agregar un nuevo hecho:

```prolog
incompatible('CODIGO_A', 'CODIGO_B').
```

La relación seguirá siendo simétrica sin necesidad de agregar
el mismo par en sentido inverso.

### 21.4. Modificar la prioridad de las reglas

La prioridad se encuentra definida mediante el orden de las
cláusulas de violacion/2 en politica.pl.

Para cambiar la regla que se evalúa primero, se debe modificar
el orden de dichas cláusulas.

### 21.5. Consideraciones sobre las pruebas

Las pruebas automatizadas y los archivos de resultados esperados
se diseñaron utilizando los parámetros originales:

```prolog
max_porcentaje('ingenieria-computadores', 100).
max_porcentaje('ingenieria-construccion', 40).
max_cursos_area(4).
```

Si estos valores se modifican durante la defensa, algunos
resultados esperados también cambiarán.

Una diferencia en dichas pruebas después de modificar los
parámetros no implica necesariamente un error de implementación,
sino que puede indicar que los resultados esperados deben
adaptarse a la nueva política.

---

## 22. Limitaciones y consideraciones

- El programa reporta únicamente la primera violación durante
  el flujo normal de evaluación.

- Si varias alternativas de retiro son válidas, se conserva
  únicamente la primera encontrada.

- La sugerencia evalúa el retiro de un único curso. No se
  realizan búsquedas que requieran retirar dos o más cursos.

- No se acepta una combinación vacía como resultado de una
  sugerencia de retiro.

- La evaluación directa de una lista vacía no presenta
  violaciones de política. Se espera que Racket proporcione
  combinaciones apropiadas para el proceso de matrícula.

- El módulo depende de que los datos recibidos desde Racket
  contengan los campos y tipos esperados.

- La carga actual no realiza una validación exhaustiva de
  los tipos y valores de todos los campos JSON.

- Debe existir un porcentaje máximo definido para cada carrera
  utilizada. Una carrera sin un hecho max_porcentaje/2 puede
  quedar sin una restricción de balance efectiva.

- Los identificadores de carrera y área deben coincidir entre
  los módulos de C, Racket y Prolog.

- El predicado evaluar/3 está diseñado principalmente para
  recibir una combinación instanciada y devolver el veredicto
  y la razón. La prioridad no está garantizada del mismo modo
  cuando se proporciona previamente una razón específica
  distinta de la primera violación.

- No se vuelven a comprobar los requisitos, correquisitos,
  choques de horario ni límites de créditos de etapas anteriores.

- Las incompatibilidades y porcentajes representan decisiones
  de política definidas para el proyecto.

- La prueba de integración real se realizó con dos
  combinaciones generadas por Racket. No constituye una
  evaluación exhaustiva de todos los posibles horarios.

- La integración efectiva con Java se realizará en la
  siguiente etapa.

---

## 23. Aportes de los integrantes

| Integrante | Responsabilidad | Aporte |
|---|---|---|
| Henry | Validación en Prolog | Implementación de las tres reglas de política académica, evaluación principal, primera razón de rechazo y predicado multimodo. |
| Ivan | Integración y exportación | Implementación de la carga JSON, recorrido de combinaciones, sugerencia de retiro, integración de módulos y exportación de resultados. |
| Daniel | Datos de los planes y política | Extensión de los planes de estudio hasta el octavo semestre, incorporación del área académica y definición de los hechos de política. |
|  Raymond | Pruebas y documentación | Diseño de siete combinaciones controladas, implementación de 18 pruebas automatizadas, comparación de resultados esperados y obtenidos, prueba de integración con Racket y elaboración del README. |

### 23.1. Distribución de responsabilidades

| Integrante | Carga asignada |
|---|---:|
| Persona A | 40% |
| Persona B | 40% |
| Persona C | 10% |
| Persona D | 10% |

---

## 24. Conclusiones

La tercera etapa de CEmestre permite evaluar las combinaciones
de horarios generadas mediante el paradigma funcional, utilizando
hechos, reglas y mecanismos de control propios del paradigma
lógico.

La separación de los parámetros de política respecto a la
implementación de las reglas facilita su modificación sin
necesidad de cambiar los predicados de validación.

Mediante el uso de corte y negación por falla se obtiene un
veredicto para cada combinación y se identifica la primera
causa de rechazo durante el flujo normal del programa.

La funcionalidad adicional de sugerencia de retiro permite
probar diferentes alternativas reutilizando los predicados
de validación existentes.

Las siete combinaciones controladas y las 18 pruebas
automatizadas permitieron comprobar los escenarios de
aceptación, rechazo, casos límite, incompatibilidad,
prioridad de las reglas, sugerencias y exportación.

Además, la ejecución con dos combinaciones reales provenientes
de Racket permitió verificar la compatibilidad del formato
de entrada y la generación del archivo JSON destinado a
la siguiente etapa del proyecto.

De esta manera, el módulo lógico agrega una evaluación de
política académica a las combinaciones previamente generadas,
manteniendo la arquitectura modular del sistema.

---

## 25. Referencias

- Instituto Tecnológico de Costa Rica. (2026).
  CEmestre: Constructor de horarios. Proyecto, etapa 3:
  Paradigma lógico. CE1106 - Paradigmas de Programación.

- SWI-Prolog. Documentación oficial.
  https://www.swi-prolog.org/pldoc/

- SWI-Prolog. Biblioteca de pruebas PlUnit.
  https://www.swi-prolog.org/pldoc/man?section=plunit

- SWI-Prolog. Predicados para el manejo de JSON.
  https://www.swi-prolog.org/pldoc/man?section=json

- SWI-Prolog. Predicados para el manejo de listas.
  https://www.swi-prolog.org/pldoc/man?section=lists

- Planes de estudio de Ingeniería en Computadores e
  Ingeniería en Construcción utilizados en el proyecto.