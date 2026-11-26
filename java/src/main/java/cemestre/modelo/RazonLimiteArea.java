package cemestre.modelo;

/** Se superó la cantidad máxima de cursos de una misma área. */
public final class RazonLimiteArea extends RazonRechazo {
    private final String area;
    private final int cantidad;
    private final int maximo;

    public RazonLimiteArea(String area, int cantidad, int maximo) {
        super("limite_area");
        this.area = area;
        this.cantidad = cantidad;
        this.maximo = maximo;
    }

    public String getArea() { return area; }
    public int getCantidad() { return cantidad; }
    public int getMaximo() { return maximo; }

    @Override
    public String describir() {
        return "Límite por área: " + cantidad + " cursos de " + area + " (máximo " + maximo + ")";
    }
}
