package cemestre.modelo;

/** Dos cursos de la combinación son incompatibles entre sí. */
public final class RazonIncompatibilidad extends RazonRechazo {
    private final String cursoA;
    private final String cursoB;

    public RazonIncompatibilidad(String cursoA, String cursoB) {
        super("incompatibilidad");
        this.cursoA = cursoA;
        this.cursoB = cursoB;
    }

    public String getCursoA() { return cursoA; }
    public String getCursoB() { return cursoB; }

    @Override
    public String describir() {
        return "Incompatibilidad: " + cursoA + " no se puede llevar junto con " + cursoB;
    }
}
