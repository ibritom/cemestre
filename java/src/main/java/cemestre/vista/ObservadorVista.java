package cemestre.vista;

import cemestre.modelo.Combinacion;

/**
 * TEMPORAL: contrato mínimo para que las vistas reaccionen a la combinación seleccionada.
 * Reemplazar por la interfaz Observer que defina la Persona D (paquete observador).
 */
public interface ObservadorVista {
    /** @param combinacion la combinación seleccionada, o null si no hay ninguna. */
    void actualizar(Combinacion combinacion);
}
