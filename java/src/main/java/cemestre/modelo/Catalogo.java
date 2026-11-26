package cemestre.modelo;

import java.util.Collection;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Optional;

/** Catálogo de cursos generado por la etapa de C. */
public final class Catalogo {
    private final String carrera;
    private final Map<String, Curso> cursos = new LinkedHashMap<>();

    public Catalogo(String carrera) {
        this.carrera = carrera;
    }

    public void agregarCurso(Curso curso) {
        cursos.put(curso.getCodigo(), curso);
    }

    public Optional<Curso> buscarCurso(String codigo) {
        return Optional.ofNullable(cursos.get(codigo));
    }

    public String getCarrera() { return carrera; }
    public Collection<Curso> getCursos() { return Collections.unmodifiableCollection(cursos.values()); }
    public int size() { return cursos.size(); }
}
