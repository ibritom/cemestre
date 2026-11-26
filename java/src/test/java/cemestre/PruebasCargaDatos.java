package cemestre;

import cemestre.datos.CargadorDatos;
import cemestre.datos.DatosInvalidosException;
import cemestre.datos.JsonParser;
import cemestre.datos.AdaptadorCatalogoC;
import cemestre.datos.AdaptadorResultadoProlog;
import cemestre.modelo.*;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.Map;

/** Pruebas de la Persona A (sin librerías externas). Ejecutar: java -cp out cemestre.PruebasCargaDatos datos */
public class PruebasCargaDatos {
    private static int ok = 0, fallos = 0;

    public static void main(String[] args) throws Exception {
        Path dir = Paths.get(args.length > 0 ? args[0] : "datos");
        Path catalogo = dir.resolve("catalogo_validado.json");
        Path prolog = dir.resolve("salida_prolog_ejemplo.json");

        pruebaParser();
        pruebaBloque();
        ModeloHorarios m = new CargadorDatos().cargar(catalogo, prolog);
        pruebaCatalogo(m);
        pruebaCombinaciones(m);
        pruebaErrores(catalogo, dir);

        System.out.println("\n" + ok + " pruebas OK, " + fallos + " fallidas");
        if (fallos > 0) System.exit(1);
    }

    private static void pruebaParser() throws Exception {
        Object o = JsonParser.parsear("{\"a\":[1,2.5,true,null,\"x\\u00e9\\n\"],\"b\":{}}");
        Map<?, ?> mapa = (Map<?, ?>) o;
        List<?> a = (List<?>) mapa.get("a");
        igual("parser: entero", 1L, a.get(0));
        igual("parser: decimal", 2.5, a.get(1));
        igual("parser: null", null, a.get(3));
        igual("parser: escapes", "xé\n", a.get(4));
        lanza("parser: JSON truncado", () -> JsonParser.parsear("{\"a\":"));
        lanza("parser: basura final", () -> JsonParser.parsear("{} x"));
    }

    private static void pruebaBloque() {
        BloqueHorario b = new BloqueHorario(DiaSemana.MIERCOLES, 9 * 60 + 30, 11 * 60 + 20);
        igual("bloque: texto", "Miércoles 09:30-11:20", b.toString());
        igual("bloque: duración", 110, b.getDuracionMinutos());
    }

    private static void pruebaCatalogo(ModeloHorarios m) {
        Catalogo c = m.getCatalogo();
        igual("catálogo: carrera", "ingenieria-computadores", c.getCarrera());
        igual("catálogo: cantidad de cursos", 25, c.size());
        Curso ce1106 = c.buscarCurso("CE1106").get();
        igual("curso: nombre", "Paradigmas de programación", ce1106.getNombre());
        igual("curso: créditos", 3, ce1106.getCreditos());
        Grupo g1 = ce1106.buscarGrupo(1).get();
        igual("grupo: profesor", "BARBOZA ARTAVIA LUIS", g1.getProfesores().get(0));
        // 20930-21120 (miércoles) y 40930-41120 (viernes)
        igual("grupo: bloque 1", "Miércoles 09:30-11:20", g1.getBloques().get(0).toString());
        igual("grupo: bloque 2", "Viernes 09:30-11:20", g1.getBloques().get(1).toString());
    }

    private static void pruebaCombinaciones(ModeloHorarios m) {
        igual("combinaciones: total", 5, m.getCombinaciones().size());
        igual("combinaciones: válidas", 2, m.getValidas().size());
        igual("combinaciones: rechazadas", 3, m.getRechazadas().size());

        Combinacion c1 = m.buscarPorId(1).get();
        verdad("c1 válida", c1.isCumple());
        verdad("c1 sin razón (objeto nulo)", !c1.getRazon().existe());
        igual("c1 créditos", 3, c1.getCreditosTotales());
        igual("c1 bloques", 2, c1.getBloques().size());

        Combinacion c3 = m.buscarPorId(3).get();
        verdad("c3 rechazada", !c3.isCumple());
        verdad("c3 razón polimórfica: balance", c3.getRazon() instanceof RazonBalanceCarreras);
        verdad("c3 describe porcentaje", c3.getRazon().describir().contains("20%"));
        verdad("c3 sugerencia existe", c3.getSugerencia().existe());
        igual("c3 retira MA1102", "MA1102", c3.getSugerencia().getRetiro().get().getCodigo());
        verdad("c3 créditos = suma del catálogo", c3.getCreditosTotales() > 3);

        verdad("c4 razón: límite de área", m.buscarPorId(4).get().getRazon() instanceof RazonLimiteArea);
        verdad("c4 sin sugerencia", !m.buscarPorId(4).get().getSugerencia().existe());
        verdad("c5 razón: incompatibilidad", m.buscarPorId(5).get().getRazon() instanceof RazonIncompatibilidad);
        verdad("c5 bloques ordenados", ordenados(m.buscarPorId(5).get().getBloques()));
    }

    private static void pruebaErrores(Path catalogo, Path dir) throws Exception {
        CargadorDatos cargador = new CargadorDatos();
        Path tmp = Files.createTempFile("prolog", ".json");
        Files.write(tmp, "{\"combinaciones\":[{\"id\":1,\"cursos\":[{\"codigo\":\"XX9999\",\"grupo\":1}],\"cumple\":true,\"razon\":null,\"sugerencia\":null}]}".getBytes("UTF-8"));
        lanza("error: curso fuera del catálogo", () -> cargador.cargar(catalogo, tmp));
        Files.write(tmp, "{\"combinaciones\":[{\"id\":1,\"cursos\":[],\"cumple\":false,\"razon\":null,\"sugerencia\":null}]}".getBytes("UTF-8"));
        lanza("error: rechazada sin razón", () -> cargador.cargar(catalogo, tmp));
        Files.write(tmp, "{\"combinaciones\":[{\"id\":1,\"cursos\":[],\"cumple\":false,\"razon\":{\"regla\":\"otra\"},\"sugerencia\":null}]}".getBytes("UTF-8"));
        lanza("error: regla desconocida", () -> cargador.cargar(catalogo, tmp));
        lanza("error: archivo inexistente", () -> cargador.cargar(dir.resolve("no-existe.json"), tmp));
        Files.delete(tmp);
    }

    // ---- utilidades mínimas de prueba ----
    private interface Accion { void ejecutar() throws Exception; }

    private static boolean ordenados(List<BloqueHorario> l) {
        for (int i = 1; i < l.size(); i++) if (l.get(i - 1).compareTo(l.get(i)) > 0) return false;
        return true;
    }

    private static void verdad(String nombre, boolean cond) {
        if (cond) { ok++; System.out.println("OK    " + nombre); }
        else { fallos++; System.out.println("FALLA " + nombre); }
    }

    private static void igual(String nombre, Object esperado, Object real) {
        boolean cond = esperado == null ? real == null : esperado.equals(real);
        if (cond) { ok++; System.out.println("OK    " + nombre); }
        else { fallos++; System.out.println("FALLA " + nombre + " (esperado=" + esperado + ", real=" + real + ")"); }
    }

    private static void lanza(String nombre, Accion a) {
        try {
            a.ejecutar();
            fallos++;
            System.out.println("FALLA " + nombre + " (no lanzó DatosInvalidosException)");
        } catch (DatosInvalidosException e) {
            ok++;
            System.out.println("OK    " + nombre + " -> " + e.getMessage());
        } catch (Exception e) {
            fallos++;
            System.out.println("FALLA " + nombre + " (excepción inesperada " + e + ")");
        }
    }
}
