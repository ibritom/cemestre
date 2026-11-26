package cemestre.datos;

/**
 * Patrón Adapter (interfaz objetivo): convierte la representación cruda de un archivo
 * externo (JSON ya parseado, formato propio de C o de Prolog) en objetos del modelo.
 *
 * @param <O> tipo de origen (estructura JSON del módulo anterior)
 * @param <D> tipo de destino (clase del modelo)
 */
public interface Adaptador<O, D> {
    D adaptar(O origen) throws DatosInvalidosException;
}
