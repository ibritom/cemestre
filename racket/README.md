# CEmestre – Etapa 2: generador de combinaciones de horario (Racket)

Paradigmas de Programación (CE1106), Instituto Tecnológico de Costa Rica.

Esta etapa toma el catálogo validado que produce el módulo de C (etapa 1) y un archivo de
preferencias del estudiante. Genera combinaciones de horario sin choques (un grupo por
curso), las filtra por el rango de créditos y las exporta a un archivo JSON que leerá la
etapa de Prolog.

El módulo **no** arma un horario final, no optimiza, no aplica preferencias más allá de la
lista de cursos/grupos y el rango de créditos, y no tiene interfaz. El resultado es un archivo.

## Contenido

1. [Requisitos y uso](#requisitos-y-uso)
2. [Arquitectura](#arquitectura)
3. [Decisiones de diseño](#decisiones-de-diseño)
4. [Estructuras de datos](#estructuras-de-datos)
5. [Formato de los archivos](#formato-de-los-archivos)
6. [Pruebas](#pruebas)
7. [Limitaciones conocidas](#limitaciones-conocidas)
8. [Distribución del trabajo](#distribución-del-trabajo)

## Requisitos y uso

Requiere Racket 8.10 o superior (con `typed/racket`, que viene en la distribución completa).
Todos los comandos se corren desde la carpeta `racket/`.

```bash
racket main.rkt ../catalogo_validado.json preferencias.json resultado.json
```

Los tres argumentos son, en orden: el catálogo validado de C, el archivo de preferencias y la
ruta del archivo de salida (se sobrescribe si existe). Si todo sale bien, imprime
`Exportacion completada.`

Para generar el ejecutable que pide el enunciado:

```bash
raco exe -o cemestre main.rkt
./cemestre ../catalogo_validado.json preferencias.json resultado.json
```

El ejecutable produce la misma salida que `racket main.rkt`.

## Arquitectura

Cada módulo tiene una sola responsabilidad; `main.rkt` solo conecta las piezas.

```
catalogo_validado.json ──┐
                         ├─► lectura.rkt ─► main.rkt ─► generador.rkt ─► filtros.rkt ─► exportar.rkt ─► resultado.json
preferencias.json ───────┘                    (une)       (flujo de          (flujo de        (escribe una
                                                          combinaciones)     combinaciones      por una)
                                                                             en el rango)
```

| Archivo | Responsabilidad |
|---|---|
| `tipos.rkt` | Structs tipados: `CursoInfo`, `CursoPreferido`, `Preferencias`, `HorarioInfo`, `GrupoInfo`. |
| `flujos.rkt` | Flujos (streams) perezosos tipados e inmutables y sus operaciones (`flujo-map`, `flujo-filtrar`, `flujo-anexar`, etc.). |
| `lectura.rkt` | Lee el catálogo de C y el archivo de preferencias; valida su estructura. |
| `generador.rkt` | Descarta grupos con choques y genera las combinaciones de forma perezosa, con recursión. |
| `filtros.rkt` | Función polimórfica `filtrar`, usada para créditos (`filtrar-creditos`) y para grupos (`filtrar-grupos`). |
| `exportar.rkt` | Escribe las combinaciones al JSON de salida, una por una. |
| `main.rkt` | Programa principal: lee, selecciona cursos y grupos, genera, filtra y exporta. |
| `generador-test.rkt` | Pruebas del generador y de los flujos. |

Flujo de `main.rkt`:

1. Lee el catálogo y las preferencias.
2. Para cada curso de las preferencias, comprueba que exista y que se pueda matricular, y
   conserva solo los grupos que el estudiante pidió.
3. Pasa esa lista de cursos con sus grupos candidatos a `generar-combinaciones`, que devuelve
   un flujo.
4. Filtra ese flujo con `filtrar-creditos`, que devuelve otro flujo.
5. `exportar-combinaciones` recorre el flujo resultante y escribe cada combinación al archivo
   a medida que se produce.

## Decisiones de diseño

### Decisiones propias de nuestra implementación

**Flujos propios en lugar de `racket/stream`.** Typed Racket (8.10) no tipa `racket/stream`:
no existe el tipo `Stream` ni se puede usar `stream-cons`. Para conservar tipado explícito y
laziness, definimos en `flujos.rkt` un flujo clásico: un nodo con la cabeza ya calculada y la
cola como una promesa (`delay`/`force`). La cola solo se calcula cuando alguien la pide. El
tipo es `(Flujo A)`, definido como `(U Null (Nodo A))`, y es polimórfico en el tipo de los
elementos. No se usa ninguna estructura mutable ni `set!`.

**Descarte de grupos con choque antes de generar.** `generar-combinaciones` primero aplica
`filtrar-cursos`, que:

1. Elimina cada grupo que choca con algún grupo de **otro** curso de la lista (usando el
   campo `choques` que ya calculó el módulo de C, revisado en ambos sentidos).
2. Elimina los cursos que se quedan sin grupos.

Después de este paso, todos los grupos que sobreviven son compatibles entre sí sin importar
cómo se combinen. Así, la detección de choques ocurre una sola vez, antes de generar, y nunca
se construye una combinación completa para descartarla después, que es lo que pide la
optimización para grupos de 4.

**Generación perezosa con recursión.** Con los cursos ya filtrados, `extender` recorre los
cursos uno por uno y acumula la selección parcial como parámetro de la recursión (nunca se
modifica una variable). La función `probar-grupos` mantiene una verificación de choque contra
los grupos ya elegidos que cortaría la rama en cuanto encontrara un choque. Con el
descarte previo esa verificación no llega a descartar nada, y queda como segunda barrera de
seguridad.

**Concatenación perezosa.** `flujo-anexar` recibe el segundo flujo como una función sin
argumentos (thunk) y solo lo construye cuando el primero se agota. Con un `append` normal,
Racket evaluaría el segundo argumento de inmediato y exploraría ramas que quizá nunca se
consuman. Por eso pedir la primera combinación de un espacio de 6^25 posibilidades responde
al instante (hay una prueba de esto).

**La selección parcial se acumula al revés.** Se agrega con `cons` (O(1)) y se invierte con
`reverse` una sola vez, al completar la combinación. Así cada combinación sale en el orden de
los cursos de las preferencias.

**Función polimórfica reutilizable.** `filtrar` tiene el tipo
`(All (A) (-> (-> A Boolean) (Flujo A) (Flujo A)))`. No sabe nada de créditos ni de grupos:
recibe un predicado y un flujo de cualquier tipo. Se usa con dos criterios distintos:

- `filtrar-creditos`: sobre un flujo de combinaciones, con el rango de créditos.
- `filtrar-grupos`: sobre un flujo de candidatos, con los grupos que pidió el estudiante.

**Créditos y datos auxiliares en tablas inmutables.** `main.rkt` arma `creditos` y
`cursos-por-codigo` como `Immutable-HashTable` una sola vez, para consultar créditos en O(1)
dentro del filtro.

**Validaciones al leer.** `lectura.rkt` rechaza archivos con estructura incorrecta con un
mensaje claro: tipo de catálogo equivocado, campos faltantes, créditos mínimos negativos,
máximo menor que el mínimo, curso sin grupos seleccionados, y cursos repetidos en las
preferencias. `main.rkt` además rechaza cursos que no existen o que el estudiante no puede
matricular.

### Un caso límite real que encontramos

`preferencias.json` pide para FI1102 los grupos 2, 3, 5 y 99, pero el grupo 99 no existe en el
catálogo. Si el programa tratara ese grupo como válido, intentaría armar combinaciones con un
grupo sin horario ni choques, y `exportar.rkt` fallaría al no encontrar sus datos
(`Grupo desconocido`). `filtrar-grupos` resuelve esto desde el principio: conserva solo los
grupos pedidos que sí existen en el catálogo, así que el 99 se ignora y se generan las
combinaciones con los grupos 2, 3 y 5. El programa solo se detiene con un error claro cuando
**ningún** grupo pedido para un curso existe (`No hay grupos validos para el curso ...`).

Un segundo caso límite está en el descarte de grupos: si todos los grupos de un curso chocan
con algún grupo de otro curso, ese curso se elimina y no aparece en ninguna combinación. Si
todos los cursos se eliminan, el resultado es un flujo vacío y el archivo de salida queda con
una lista de combinaciones vacía.

## Estructuras de datos

Definidas en `tipos.rkt` (todas inmutables y `#:transparent`):

| Struct | Campos | Uso |
|---|---|---|
| `CursoInfo` | `codigo`, `nombre`, `creditos`, `puede-matricular`, `carrera` | Datos de un curso del catálogo. |
| `GrupoInfo` | `codigo`, `numero`, `profesores`, `horario` | Datos de un grupo, para exportarlos. |
| `HorarioInfo` | `inicio`, `fin` | Un bloque horario (enteros de 5 dígitos como texto; el primer dígito es el día, ver README de la etapa 1). |
| `CursoPreferido` | `codigo`, `grupos` | Un curso que pidió el estudiante, con los grupos que le interesan. |
| `Preferencias` | `cursos`, `min-creditos`, `max-creditos` | Contenido completo del archivo de preferencias. |

Definidas en `generador.rkt`:

| Tipo | Definición | Uso |
|---|---|---|
| `Par` | `(Pairof String Integer)` | Un par curso-grupo, por ejemplo `("EL2207" . 2)`. |
| `Candidato` | struct con `par` y `choques : (Listof Par)` | Un grupo con los pares con los que choca. |
| `CursoCandidatos` | `(Listof Candidato)` | Todos los grupos candidatos de un curso. |

Definidas en `flujos.rkt`:

| Tipo | Definición | Uso |
|---|---|---|
| `Nodo` | struct polimórfica con `cabeza` y `cola : (Promise (Flujo A))` | Un elemento del flujo con la cola pendiente. |
| `Flujo` | `(U Null (Nodo A))` | Flujo perezoso: vacío o un nodo. |

Una combinación es un `(Listof Par)`, y el generador produce un `(Flujo (Listof Par))`. El
generador solo entrega los pares; los créditos y la carrera se obtienen del catálogo al
filtrar y al exportar.

## Formato de los archivos

### Entrada

- **Catálogo**: el `catalogo_validado.json` de la etapa 1. Se usan `tipo` (debe ser
  `catalogo-validado`), `carrera`, y por curso `codigo`, `nombre`, `creditos`,
  `puede_matricular` y `grupos`; de cada grupo, `grupo`, `profesores`, `horario` y `choques`.
  Si un curso trae su propio campo `carrera`, se usa; si no, se toma la carrera de la raíz.
- **Preferencias**:

```json
{
  "cursos": [
    { "codigo": "EL2207", "grupos": [2, 3] },
    { "codigo": "FI1102", "grupos": [2, 3, 5] }
  ],
  "min_creditos": 5,
  "max_creditos": 10
}
```

Cada curso debe pedir al menos un grupo, y la lista de interés admite varios grupos por curso.

### Salida

```json
{
 "combinaciones":[
  {
    "creditos_totales": 7,
    "cursos": [
      {
        "carrera": "ingenieria-computadores",
        "codigo": "EL2207",
        "creditos": 4,
        "grupo": 2,
        "horario": [ { "inicio": "30730", "fin": "30920" } ],
        "nombre": "Elementos activos",
        "profesores": [ "..." ]
      }
    ]
  }
 ]
}
```

Campos mínimos que pide el enunciado: lista de pares curso-grupo (`codigo` y `grupo` de cada
elemento de `cursos`), créditos totales (`creditos_totales`) y carrera de origen de cada curso
(`carrera`).

### Justificación del formato

Elegimos **JSON**, el mismo de la etapa 1, por tres razones:

1. **Lo pueden leer todas las etapas.** Prolog lo lee con la biblioteca JSON de SWI-Prolog y
   Java con cualquier librería JSON estándar, sin escribir un parser propio. Con CSV, una
   combinación sería una fila de largo variable (cada combinación tiene un número distinto de
   cursos), lo que obliga a inventar una convención para separar los grupos.
2. **Cada combinación es un registro autocontenido y jerárquico.** Una combinación es un
   objeto con una lista de cursos adentro, y cada curso lleva su grupo, sus créditos y su
   carrera. Esto refleja directamente la regla del problema (una combinación = varios pares
   curso-grupo) sin repetir columnas.
3. **Permite escribir combinación por combinación.** El archivo es un arreglo
   `"combinaciones": [ ... ]` y cada elemento se escribe, separado por una coma, en cuanto el
   flujo lo produce. `exportar.rkt` formatea cada combinación por separado, así que nunca se
   construye en memoria el JSON completo. Esto encaja con el diseño del generador: lo que se
   genera de forma perezosa también se exporta de forma perezosa.

**Campos adicionales que no pedía el enunciado, y por qué.** Cada curso incluye `nombre`,
`profesores` y `horario`. Los agregamos para que la etapa de Prolog pueda aplicar sus reglas
sin volver a abrir el catálogo de C, y para que la de Java pueda presentar el resultado:
cada combinación contiene todo lo que esas etapas necesitan.

## Pruebas

```bash
racket generador-test.rkt
```

Debe terminar imprimiendo `OK`. Cubre:

- Sin choques: se obtiene el producto cartesiano de los grupos, en el orden esperado.
- Un choque entre dos grupos: ninguna combinación los incluye a ambos.
- Un curso cuyos grupos chocan con otro curso se omite del resultado; si se omiten todos, el
  flujo queda vacío.
- Casos borde: lista de cursos vacía, un curso con lista de grupos vacía y un solo curso con
  un solo grupo.
- Laziness: pedir una combinación de un espacio de 6^25 posibilidades termina de inmediato.
- Operaciones de flujos: `flujo-filtrar`, `flujo-map`, `flujo-tomar` y `flujo-anexar`.

## Limitaciones conocidas

- **El descarte previo es más estricto que "sin choques entre los grupos elegidos".** Un grupo
  que choca con algún grupo de otro curso se elimina aunque pudiera combinarse sin problema
  con otros grupos de ese curso. Por eso, cuando hay muchos cursos y grupos con choques, el
  resultado puede tener menos combinaciones que el total de combinaciones válidas posibles
  (por ejemplo, con los 6 cursos habilitados del catálogo y todos sus grupos se obtiene 1
  combinación). Con pocos cursos, o con grupos que no chocan entre sí, no hay diferencia.
- Los cursos cuyos grupos chocan todos con otro curso no aparecen en el resultado.
- Los flujos memorizan sus nodos (así funcionan las promesas de `delay`). Mientras alguien
  conserve una referencia al inicio del flujo, los nodos ya recorridos permanecen en memoria.
- El catálogo `catalogo_validado.json` incluido considera 4 semestres y una sola carrera
  (`ingenieria-computadores`); el campo `carrera` se toma de la raíz del archivo cuando el
  curso no lo trae.

## Distribución del trabajo

| Parte | Contenido |
|---|---|
| A | `generador.rkt` y `flujos.rkt`: generación perezosa con flujos; pruebas. |
| B | `tipos.rkt`, `lectura.rkt`, `filtros.rkt`, `exportar.rkt`, `main.rkt`. |
| C | Archivos de preferencias de prueba y justificación del formato de salida. |
| D | Cambio en el módulo de C y regeneración del catálogo. |
