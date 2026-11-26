package cemestre.modelo;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/** Grupo de un curso: número, profesores y bloques de horario (ordenados). */
public final class Grupo {
    private final int numero;
    private final List<String> profesores;
    private final List<BloqueHorario> bloques;

    public Grupo(int numero, List<String> profesores, List<BloqueHorario> bloques) {
        this.numero = numero;
        this.profesores = Collections.unmodifiableList(new ArrayList<>(profesores));
        List<BloqueHorario> ordenados = new ArrayList<>(bloques);
        Collections.sort(ordenados);
        this.bloques = Collections.unmodifiableList(ordenados);
    }

    public int getNumero() { return numero; }
    public List<String> getProfesores() { return profesores; }
    public List<BloqueHorario> getBloques() { return bloques; }

    @Override
    public String toString() {
        return "Grupo " + numero;
    }
}
