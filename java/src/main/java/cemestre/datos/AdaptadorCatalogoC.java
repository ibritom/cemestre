package cemestre.datos;

import cemestre.modelo.BloqueHorario;
import cemestre.modelo.Catalogo;
import cemestre.modelo.Curso;
import cemestre.modelo.DiaSemana;
import cemestre.modelo.Grupo;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * Adapter del catálogo validado de C (catalogo_validado.json) al modelo.
 * Solo toma lo que la etapa 4 muestra: código, nombre, créditos, grupos, profesores y horarios.
 * Los campos de choques y requisitos de C se ignoran: Java no recalcula nada de eso.
 */
public final class AdaptadorCatalogoC implements Adaptador<Map<String, Object>, Catalogo> {

    @Override
    public Catalogo adaptar(Map<String, Object> raiz) throws DatosInvalidosException {
        Catalogo catalogo = new Catalogo(Json.texto(raiz, "carrera", "catálogo"));
        for (Object c : Json.lista(Json.campo(raiz, "cursos", "catálogo"), "catálogo.cursos")) {
            catalogo.agregarCurso(adaptarCurso(Json.objeto(c, "curso")));
        }
        return catalogo;
    }

    private Curso adaptarCurso(Map<String, Object> o) throws DatosInvalidosException {
        String codigo = Json.texto(o, "codigo", "curso");
        String ctx = "curso " + codigo;
        Curso curso = new Curso(codigo, Json.texto(o, "nombre", ctx), Json.entero(o, "creditos", ctx));
        for (Object g : Json.lista(Json.campo(o, "grupos", ctx), ctx + ".grupos")) {
            curso.agregarGrupo(adaptarGrupo(Json.objeto(g, ctx + " grupo"), ctx));
        }
        return curso;
    }

    private Grupo adaptarGrupo(Map<String, Object> o, String ctxCurso) throws DatosInvalidosException {
        int numero = Json.entero(o, "grupo", ctxCurso);
        String ctx = ctxCurso + " grupo " + numero;
        List<String> profesores = new ArrayList<>();
        for (Object p : Json.lista(Json.campo(o, "profesores", ctx), ctx + ".profesores")) {
            profesores.add(String.valueOf(p));
        }
        List<BloqueHorario> bloques = new ArrayList<>();
        for (Object b : Json.lista(Json.campo(o, "horario", ctx), ctx + ".horario")) {
            Map<String, Object> bo = Json.objeto(b, ctx + " horario");
            bloques.add(decodificar(Json.campo(bo, "inicio", ctx), Json.campo(bo, "fin", ctx), ctx));
        }
        return new Grupo(numero, profesores, bloques);
    }

    /**
     * Decodifica el entero de 5 dígitos de C: D HHMM, con D = día (lunes 0 ... sábado 5)
     * y HHMM la hora. Ej.: 20930 = miércoles 09:30.
     */
    static BloqueHorario decodificar(Object inicio, Object fin, String ctx) throws DatosInvalidosException {
        int i = Json.aEntero(inicio, ctx + ".inicio");
        int f = Json.aEntero(fin, ctx + ".fin");
        if (i / 10000 != f / 10000) {
            throw new DatosInvalidosException(ctx + ": el bloque " + i + "-" + f + " cruza de día");
        }
        try {
            return new BloqueHorario(DiaSemana.desdeCodigo(i / 10000), minutos(i), minutos(f));
        } catch (IllegalArgumentException e) {
            throw new DatosInvalidosException(ctx + ": horario inválido " + i + "-" + f + " (" + e.getMessage() + ")", e);
        }
    }

    private static int minutos(int codigo) {
        int hhmm = codigo % 10000;
        return (hhmm / 100) * 60 + hhmm % 100;
    }
}
