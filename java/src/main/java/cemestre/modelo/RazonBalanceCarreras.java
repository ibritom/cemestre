package cemestre.modelo;

/** Una carrera supera el porcentaje máximo de créditos permitido. */
public final class RazonBalanceCarreras extends RazonRechazo {
    private final String carrera;
    private final int creditos;
    private final int total;
    private final int maxPorcentaje;

    public RazonBalanceCarreras(String carrera, int creditos, int total, int maxPorcentaje) {
        super("balance_carreras");
        this.carrera = carrera;
        this.creditos = creditos;
        this.total = total;
        this.maxPorcentaje = maxPorcentaje;
    }

    public String getCarrera() { return carrera; }
    public int getCreditos() { return creditos; }
    public int getTotal() { return total; }
    public int getMaxPorcentaje() { return maxPorcentaje; }

    @Override
    public String describir() {
        return "Balance entre carreras: " + carrera + " tiene " + creditos + " de " + total
                + " créditos y el máximo permitido es " + maxPorcentaje + "%";
    }
}
