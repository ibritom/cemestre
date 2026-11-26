package cemestre.datos;

import cemestre.modelo.Catalogo;
import cemestre.modelo.Combinacion;
import cemestre.modelo.Curso;
import cemestre.modelo.CursoGrupo;
import cemestre.modelo.Grupo;
import cemestre.modelo.RazonBalanceCarreras;
import cemestre.modelo.RazonIncompatibilidad;
import cemestre.modelo.RazonLimiteArea;
import cemestre.modelo.RazonRechazo;
import cemestre.modelo.SinRazon;
import cemestre.modelo.Sugerencia;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * Adapter de la salida de Prolog ({combinaciones: [{id, cursos:[{codigo, grupo}], cumple, razon, sugerencia}]}).
 * Prolog solo entrega pares código/grupo, así que aquí se unifica con el catálogo de C para
 * obtener nombre, créditos y horario. Conserva las razones de rechazo y las sugerencias tal cual.
 */
public final class AdaptadorResultadoProlog implements Adaptador<Map<String, Object>, List<Combinacion>> {
    private final Catalogo catalogo;

    public AdaptadorResultadoProlog(Catalogo catalogo) {
        this.catalogo = catalogo;
    }

    @Override
    public List<Combinacion> adaptar(Map<String, Object> raiz) throws DatosInvalidosException {
        List<Combinacion> resultado = new ArrayList<>();
        for (Object c : Json.lista(Json.campo(raiz, "combinaciones", "salida de Prolog"), "combinaciones")) {
            resultado.add(adaptarCombinacion(Json.objeto(c, "combinación")));
        }
        return resultado;
    }

    private Combinacion adaptarCombinacion(Map<String, Object> o) throws DatosInvalidosException {
        int id = Json.entero(o, "id", "combinación");
        String ctx = "combinación " + id;
        List<CursoGrupo> cursos = new ArrayList<>();
        for (Object c : Json.lista(Json.campo(o, "cursos", ctx), ctx + ".cursos")) {
            cursos.add(resolver(Json.objeto(c, ctx + " curso"), ctx));
        }
        boolean cumple = Json.booleano(o, "cumple", ctx);
        RazonRechazo razon = crearRazon(o.get("razon"), ctx);
        if (!cumple && !razon.existe()) {
            throw new DatosInvalidosException(ctx + ": está rechazada pero no trae razón");
        }
        return new Combinacion(id, cursos, cumple, razon, crearSugerencia(o.get("sugerencia"), ctx));
    }

    private CursoGrupo resolver(Map<String, Object> o, String ctx) throws DatosInvalidosException {
        String codigo = Json.texto(o, "codigo", ctx);
        int numero = Json.entero(o, "grupo", ctx);
        Curso curso = catalogo.buscarCurso(codigo).orElseThrow(
                () -> new DatosInvalidosException(ctx + ": el curso " + codigo + " no está en el catálogo de C"));
        Grupo grupo = curso.buscarGrupo(numero).orElseThrow(
                () -> new DatosInvalidosException(ctx + ": el grupo " + numero + " de " + codigo + " no está en el catálogo de C"));
        return new CursoGrupo(curso, grupo);
    }

    /** Fábrica de razones: elige la subclase según el campo "regla" que exporta Prolog. */
    private RazonRechazo crearRazon(Object valor, String ctx) throws DatosInvalidosException {
        if (valor == null) return new SinRazon();
        Map<String, Object> o = Json.objeto(valor, ctx + ".razon");
        String regla = Json.texto(o, "regla", ctx + ".razon");
        switch (regla) {
            case "balance_carreras":
                return new RazonBalanceCarreras(Json.texto(o, "carrera", ctx), Json.entero(o, "creditos", ctx),
                        Json.entero(o, "total", ctx), Json.entero(o, "max_porcentaje", ctx));
            case "limite_area":
                return new RazonLimiteArea(Json.texto(o, "area", ctx), Json.entero(o, "cantidad", ctx),
                        Json.entero(o, "maximo", ctx));
            case "incompatibilidad":
                return new RazonIncompatibilidad(Json.texto(o, "curso_a", ctx), Json.texto(o, "curso_b", ctx));
            default:
                throw new DatosInvalidosException(ctx + ": regla de rechazo desconocida '" + regla + "'");
        }
    }

    private Sugerencia crearSugerencia(Object valor, String ctx) throws DatosInvalidosException {
        if (valor == null) return Sugerencia.ninguna();
        Map<String, Object> o = Json.objeto(valor, ctx + ".sugerencia");
        if (!Json.booleano(o, "existe", ctx + ".sugerencia") || o.get("retirar") == null) {
            return Sugerencia.ninguna();
        }
        return Sugerencia.retirar(resolver(Json.objeto(o.get("retirar"), ctx + ".sugerencia.retirar"), ctx));
    }
}
