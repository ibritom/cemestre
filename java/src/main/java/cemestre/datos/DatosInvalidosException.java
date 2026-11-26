package cemestre.datos;

/** Error al leer, parsear o unificar los archivos de entrada. */
public class DatosInvalidosException extends Exception {
    private static final long serialVersionUID = 1L;

    public DatosInvalidosException(String mensaje) {
        super(mensaje);
    }

    public DatosInvalidosException(String mensaje, Throwable causa) {
        super(mensaje, causa);
    }
}
