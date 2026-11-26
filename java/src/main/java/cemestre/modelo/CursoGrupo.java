package cemestre.modelo;

import java.util.List;

/** Un curso con el grupo concreto elegido dentro de una combinación. */
public final class CursoGrupo {
    private final Curso curso;
    private final Grupo grupo;

    public CursoGrupo(Curso curso, Grupo grupo) {
        this.curso = curso;
        this.grupo = grupo;
    }

    public Curso getCurso() { return curso; }
    public Grupo getGrupo() { return grupo; }
    public String getCodigo() { return curso.getCodigo(); }
    public String getNombre() { return curso.getNombre(); }
    public int getNumeroGrupo() { return grupo.getNumero(); }
    public int getCreditos() { return curso.getCreditos(); }
    public List<BloqueHorario> getBloques() { return grupo.getBloques(); }

    @Override
    public String toString() {
        return curso.getCodigo() + "-G" + grupo.getNumero();
    }
}
