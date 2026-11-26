package cemestre.modelo;

/** Intervalo de clase en un día. Inmutable. Las horas se guardan en minutos desde medianoche. */
public final class BloqueHorario implements Comparable<BloqueHorario> {
    private final DiaSemana dia;
    private final int inicioMinutos;
    private final int finMinutos;

    public BloqueHorario(DiaSemana dia, int inicioMinutos, int finMinutos) {
        if (dia == null) {
            throw new IllegalArgumentException("El día no puede ser nulo");
        }
        if (inicioMinutos < 0 || finMinutos > 24 * 60 || inicioMinutos >= finMinutos) {
            throw new IllegalArgumentException("Intervalo inválido: " + inicioMinutos + "-" + finMinutos);
        }
        this.dia = dia;
        this.inicioMinutos = inicioMinutos;
        this.finMinutos = finMinutos;
    }

    public DiaSemana getDia() { return dia; }
    public int getInicioMinutos() { return inicioMinutos; }
    public int getFinMinutos() { return finMinutos; }
    public int getDuracionMinutos() { return finMinutos - inicioMinutos; }

    public String getInicioTexto() { return formato(inicioMinutos); }
    public String getFinTexto() { return formato(finMinutos); }

    private static String formato(int minutos) {
        return String.format("%02d:%02d", minutos / 60, minutos % 60);
    }

    @Override
    public int compareTo(BloqueHorario otro) {
        int c = dia.compareTo(otro.dia);
        return c != 0 ? c : Integer.compare(inicioMinutos, otro.inicioMinutos);
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof BloqueHorario)) return false;
        BloqueHorario b = (BloqueHorario) o;
        return dia == b.dia && inicioMinutos == b.inicioMinutos && finMinutos == b.finMinutos;
    }

    @Override
    public int hashCode() {
        return 31 * (31 * dia.hashCode() + inicioMinutos) + finMinutos;
    }

    @Override
    public String toString() {
        return dia + " " + getInicioTexto() + "-" + getFinTexto();
    }
}
