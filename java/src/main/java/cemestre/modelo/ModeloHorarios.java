package cemestre.modelo;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

/** Datos ya unificados (catálogo + resultado de Prolog) que usan las demás capas. */
public final class ModeloHorarios {
    private final Catalogo catalogo;
    private final List<Combinacion> combinaciones;

    public ModeloHorarios(Catalogo catalogo, List<Combinacion> combinaciones) {
        this.catalogo = catalogo;
        this.combinaciones = Collections.unmodifiableList(new ArrayList<>(combinaciones));
    }

    public Catalogo getCatalogo() { return catalogo; }
    public List<Combinacion> getCombinaciones() { return combinaciones; }

    public List<Combinacion> getValidas() { return filtrar(true); }
    public List<Combinacion> getRechazadas() { return filtrar(false); }

    public Optional<Combinacion> buscarPorId(int id) {
        for (Combinacion c : combinaciones) {
            if (c.getId() == id) return Optional.of(c);
        }
        return Optional.empty();
    }

    private List<Combinacion> filtrar(boolean cumple) {
        List<Combinacion> r = new ArrayList<>();
        for (Combinacion c : combinaciones) {
            if (c.isCumple() == cumple) r.add(c);
        }
        return Collections.unmodifiableList(r);
    }
}
