package cemestre.modelo;

import java.util.Collection;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Optional;

/** Curso del catálogo con sus grupos. */
public final class Curso {
    private final String codigo;
    private final String nombre;
    private final int creditos;
    private final Map<Integer, Grupo> grupos = new LinkedHashMap<>();

    public Curso(String codigo, String nombre, int creditos) {
        if (codigo == null || codigo.isEmpty()) {
            throw new IllegalArgumentException("El código del curso es obligatorio");
        }
        this.codigo = codigo;
        this.nombre = nombre == null ? codigo : nombre;
        this.creditos = creditos;
    }

    public void agregarGrupo(Grupo grupo) {
        grupos.put(grupo.getNumero(), grupo);
    }

    public Optional<Grupo> buscarGrupo(int numero) {
        return Optional.ofNullable(grupos.get(numero));
    }

    public String getCodigo() { return codigo; }
    public String getNombre() { return nombre; }
    public int getCreditos() { return creditos; }
    public Collection<Grupo> getGrupos() { return Collections.unmodifiableCollection(grupos.values()); }

    @Override
    public String toString() {
        return codigo + " " + nombre;
    }
}
