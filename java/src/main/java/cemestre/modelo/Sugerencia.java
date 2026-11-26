package cemestre.modelo;

import java.util.Optional;

/** Sugerencia de Prolog para una combinación rechazada: qué curso retirar para que cumpla. */
public final class Sugerencia {
    private static final Sugerencia NINGUNA = new Sugerencia(null);

    private final CursoGrupo retiro;

    private Sugerencia(CursoGrupo retiro) {
        this.retiro = retiro;
    }

    /** Sin sugerencia (combinación válida o sin retiro individual que funcione). */
    public static Sugerencia ninguna() { return NINGUNA; }

    public static Sugerencia retirar(CursoGrupo cursoGrupo) { return new Sugerencia(cursoGrupo); }

    public boolean existe() { return retiro != null; }
    public Optional<CursoGrupo> getRetiro() { return Optional.ofNullable(retiro); }

    public String describir() {
        return retiro == null
                ? "Sin sugerencia: ningún retiro individual hace cumplir la combinación"
                : "Retirar " + retiro.getCodigo() + " " + retiro.getNombre() + " (grupo " + retiro.getNumeroGrupo() + ")";
    }

    @Override
    public String toString() {
        return describir();
    }
}
