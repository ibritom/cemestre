package cemestre.modelo;

/**
 * Razón por la que Prolog rechazó una combinación. Jerarquía polimórfica:
 * cada subclase sabe describirse. {@link SinRazon} representa "cumple" (objeto nulo).
 */
public abstract class RazonRechazo {
    private final String regla;

    protected RazonRechazo(String regla) {
        this.regla = regla;
    }

    /** Nombre de la regla tal como la exporta Prolog (p. ej. "limite_area"). */
    public String getRegla() { return regla; }

    /** Texto legible para la interfaz. */
    public abstract String describir();

    public boolean existe() { return true; }

    @Override
    public String toString() {
        return describir();
    }
}
