# CEmestre – Etapa 4 (Java) – Persona A: modelo y datos

Paquetes `cemestre.modelo` y `cemestre.datos`. Sin dependencias externas (parser JSON propio), Java 11+.

## Uso desde el resto del proyecto
```java
ModeloHorarios m = new CargadorDatos().cargar(Paths.get("catalogo_validado.json"),
                                              Paths.get("salida_prolog.json"));
m.getValidas();      // List<Combinacion>
m.getRechazadas();   // con getRazon().describir() y getSugerencia().describir()
```
`CargadorDatos.cargar` lanza `DatosInvalidosException` (mensaje legible para mostrar en la GUI) si falta un
campo, el JSON está mal formado o Prolog menciona un curso/grupo que no está en el catálogo de C.

## Contrato para B, C y D
| Clase | Qué da |
|---|---|
| `Combinacion` | `getId()`, `isCumple()`, `getCursos()` (`List<CursoGrupo>`), `getCreditosTotales()`, `getBloques()` (ordenados por día/hora), `getRazon()`, `getSugerencia()` |
| `CursoGrupo` | `getCodigo()`, `getNombre()`, `getNumeroGrupo()`, `getCreditos()`, `getBloques()` |
| `BloqueHorario` | `getDia()` (`DiaSemana`), `getInicioMinutos()`, `getFinMinutos()`, `getInicioTexto()`, `getFinTexto()` |
| `RazonRechazo` | jerarquía: `RazonBalanceCarreras`, `RazonLimiteArea`, `RazonIncompatibilidad`, `SinRazon`; `describir()` |
| `Sugerencia` | `existe()`, `getRetiro()`, `describir()` |

Las horas están en minutos desde medianoche (B: hora promedio = promedio de `getInicioMinutos()`; huecos = diferencia
entre bloques consecutivos del mismo día). Todas las clases son inmutables.

## Patrón Adapter
`Adaptador<O, D>` (interfaz objetivo) con dos adaptadores: `AdaptadorCatalogoC` (JSON de C → `Catalogo`, decodifica
el entero `DHHMM`, p. ej. 20930 = miércoles 09:30) y `AdaptadorResultadoProlog` (JSON de Prolog → `Combinacion`,
unificando códigos/grupos con el catálogo). `CargadorDatos` es la fachada.

## Pruebas
```bash
javac -encoding UTF-8 -d out $(find src -name '*.java')
java -cp out cemestre.PruebasCargaDatos datos      # 36 pruebas
```
`datos/salida_prolog_ejemplo.json` sigue el formato de `Prolog/exportar.pl` (2 válidas + 3 rechazadas, una por regla).

## Decisiones
- Java no recalcula choques ni políticas: solo se guardan los datos de C y de Prolog.
- El catálogo de C es obligatorio en la práctica: Prolog solo exporta pares código/grupo.
- `SinRazon` y `Sugerencia.ninguna()` (objeto nulo) evitan `null` en la GUI.
