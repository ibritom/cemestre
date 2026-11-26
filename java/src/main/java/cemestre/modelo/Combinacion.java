package cemestre.modelo;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/** Combinación de horario evaluada por Prolog. Solo guarda datos; no valida ni genera nada. */
public final class Combinacion {
    private final int id;
    private final List<CursoGrupo> cursos;
    private final boolean cumple;
    private final RazonRechazo razon;
    private final Sugerencia sugerencia;

    public Combinacion(int id, List<CursoGrupo> cursos, boolean cumple, RazonRechazo razon, Sugerencia sugerencia) {
        this.id = id;
        this.cursos = Collections.unmodifiableList(new ArrayList<>(cursos));
        this.cumple = cumple;
        this.razon = razon == null ? new SinRazon() : razon;
        this.sugerencia = sugerencia == null ? Sugerencia.ninguna() : sugerencia;
    }

    public int getId() { return id; }
    public List<CursoGrupo> getCursos() { return cursos; }
    public boolean isCumple() { return cumple; }
    public RazonRechazo getRazon() { return razon; }
    public Sugerencia getSugerencia() { return sugerencia; }

    public int getCreditosTotales() {
        int total = 0;
        for (CursoGrupo cg : cursos) {
            total += cg.getCreditos();
        }
        return total;
    }

    /** Todos los bloques de todos los cursos, ordenados por día y hora (útil para los criterios y la vista). */
    public List<BloqueHorario> getBloques() {
        List<BloqueHorario> todos = new ArrayList<>();
        for (CursoGrupo cg : cursos) {
            todos.addAll(cg.getBloques());
        }
        Collections.sort(todos);
        return todos;
    }

    @Override
    public String toString() {
        return "Combinación #" + id + " " + cursos + (cumple ? " [válida]" : " [rechazada]");
    }
}
