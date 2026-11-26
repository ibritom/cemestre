package cemestre.modelo;

/** Combinación que cumple: no hay razón de rechazo. */
public final class SinRazon extends RazonRechazo {
    public SinRazon() { super("ninguna"); }

    @Override
    public String describir() { return "Cumple todas las políticas"; }

    @Override
    public boolean existe() { return false; }
}
