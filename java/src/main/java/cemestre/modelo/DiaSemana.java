package cemestre.modelo;

/** Día de la semana. El código coincide con el dígito más significativo del formato de C (lunes = 0). */
public enum DiaSemana {
    LUNES("Lunes"), MARTES("Martes"), MIERCOLES("Miércoles"),
    JUEVES("Jueves"), VIERNES("Viernes"), SABADO("Sábado");

    private final String nombre;

    DiaSemana(String nombre) {
        this.nombre = nombre;
    }

    public String getNombre() {
        return nombre;
    }

    public static DiaSemana desdeCodigo(int codigo) {
        DiaSemana[] valores = values();
        if (codigo < 0 || codigo >= valores.length) {
            throw new IllegalArgumentException("Código de día inválido: " + codigo);
        }
        return valores[codigo];
    }

    @Override
    public String toString() {
        return nombre;
    }
}
