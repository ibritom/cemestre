package cemestre.vista;

import cemestre.modelo.BloqueHorario;
import cemestre.modelo.Combinacion;
import cemestre.modelo.CursoGrupo;
import cemestre.modelo.DiaSemana;

import javax.swing.JPanel;
import java.awt.BasicStroke;
import java.awt.Color;
import java.awt.Dimension;
import java.awt.Font;
import java.awt.FontMetrics;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.Shape;
import java.util.ArrayList;
import java.util.List;

/** Vista semanal del horario (cuadrícula días x horas). Solo dibuja lo que recibe; no valida nada. */
public class PanelHorario extends JPanel implements ObservadorVista {
    private static final int HORA_MIN = 7;
    private static final int HORA_MAX = 21;
    private static final int ANCHO_HORAS = 60;
    private static final int ALTO_ENCABEZADO = 30;
    private static final int ALTO_HORA = 48;
    private static final int ANCHO_DIA_PREF = 130;

    private final DiaSemana[] dias = DiaSemana.values();
    private Combinacion combinacion;
    private int horaInicio = HORA_MIN;
    private int horaFin = HORA_MAX;

    public PanelHorario() {
        setBackground(Color.WHITE);
        recalcularTamano();
    }

    @Override
    public void actualizar(Combinacion c) {
        this.combinacion = c;
        horaInicio = HORA_MIN;
        horaFin = HORA_MAX;
        if (c != null) {
            for (BloqueHorario b : c.getBloques()) {
                horaInicio = Math.min(horaInicio, b.getInicioMinutos() / 60);
                horaFin = Math.max(horaFin, (b.getFinMinutos() + 59) / 60);
            }
        }
        recalcularTamano();
        revalidate();
        repaint();
    }

    private void recalcularTamano() {
        setPreferredSize(new Dimension(ANCHO_HORAS + dias.length * ANCHO_DIA_PREF,
                ALTO_ENCABEZADO + (horaFin - horaInicio) * ALTO_HORA + 18));
    }

    @Override
    protected void paintComponent(Graphics g0) {
        super.paintComponent(g0);
        Graphics2D g = (Graphics2D) g0.create();
        g.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
        g.setRenderingHint(RenderingHints.KEY_TEXT_ANTIALIASING, RenderingHints.VALUE_TEXT_ANTIALIAS_ON);

        int anchoDia = Math.max(60, (getWidth() - ANCHO_HORAS) / dias.length);
        dibujarCuadricula(g, anchoDia);
        if (combinacion != null) {
            dibujarBloques(g, anchoDia);
        }
        g.dispose();
    }

    /** Dibuja todos los bloques; los que se solapan en un mismo día se reparten el ancho de la columna. */
    private void dibujarBloques(Graphics2D g, int anchoDia) {
        List<CursoGrupo> dueños = new ArrayList<>();
        List<BloqueHorario> bloques = new ArrayList<>();
        for (CursoGrupo cg : combinacion.getCursos()) {
            for (BloqueHorario b : cg.getBloques()) {
                dueños.add(cg);
                bloques.add(b);
            }
        }
        int n = bloques.size();
        int[] columna = new int[n];
        int[] total = new int[n];
        for (int i = 0; i < n; i++) {
            boolean[] usada = new boolean[n + 1];
            for (int j = 0; j < i; j++) {
                if (seSolapan(bloques.get(i), bloques.get(j))) usada[columna[j]] = true;
            }
            int c = 0;
            while (usada[c]) c++;
            columna[i] = c;
        }
        for (int i = 0; i < n; i++) {
            total[i] = columna[i] + 1;
            for (int j = 0; j < n; j++) {
                if (i != j && seSolapan(bloques.get(i), bloques.get(j))) {
                    total[i] = Math.max(total[i], columna[j] + 1);
                }
            }
        }
        for (int i = 0; i < n; i++) {
            CursoGrupo cg = dueños.get(i);
            dibujarBloque(g, cg, bloques.get(i), anchoDia, colorPara(cg.getCodigo()), columna[i], total[i]);
        }
    }

    private static boolean seSolapan(BloqueHorario a, BloqueHorario b) {
        return a.getDia() == b.getDia()
                && a.getInicioMinutos() < b.getFinMinutos()
                && b.getInicioMinutos() < a.getFinMinutos();
    }

    private void dibujarCuadricula(Graphics2D g, int anchoDia) {
        Font base = getFont();
        g.setFont(base.deriveFont(Font.BOLD, 12f));
        FontMetrics fm = g.getFontMetrics();
        for (int d = 0; d < dias.length; d++) {
            int x = ANCHO_HORAS + d * anchoDia;
            g.setColor(new Color(0xE8EEF5));
            g.fillRect(x, 0, anchoDia, ALTO_ENCABEZADO);
            g.setColor(Color.DARK_GRAY);
            String nombre = dias[d].getNombre();
            g.drawString(nombre, x + (anchoDia - fm.stringWidth(nombre)) / 2, 20);
        }
        int alto = ALTO_ENCABEZADO + (horaFin - horaInicio) * ALTO_HORA;
        g.setFont(base.deriveFont(11f));
        for (int h = horaInicio; h <= horaFin; h++) {
            int y = ALTO_ENCABEZADO + (h - horaInicio) * ALTO_HORA;
            g.setColor(new Color(0xD0D0D0));
            g.drawLine(ANCHO_HORAS, y, ANCHO_HORAS + dias.length * anchoDia, y);
            g.setColor(Color.GRAY);
            g.drawString(String.format("%02d:00", h), 8, y + 12);
        }
        g.setColor(new Color(0xD0D0D0));
        for (int d = 0; d <= dias.length; d++) {
            int x = ANCHO_HORAS + d * anchoDia;
            g.drawLine(x, 0, x, alto);
        }
    }

    private void dibujarBloque(Graphics2D g, CursoGrupo cg, BloqueHorario b, int anchoDia, Color color,
                               int columna, int totalColumnas) {
        double yIni = ALTO_ENCABEZADO + (b.getInicioMinutos() - horaInicio * 60) * ALTO_HORA / 60.0;
        double yFin = ALTO_ENCABEZADO + (b.getFinMinutos() - horaInicio * 60) * ALTO_HORA / 60.0;
        int anchoCol = (anchoDia - 4) / totalColumnas;
        int x = ANCHO_HORAS + b.getDia().ordinal() * anchoDia + 2 + columna * anchoCol;
        int y = (int) yIni + 1;
        int w = anchoCol - (totalColumnas > 1 ? 1 : 0);
        int h = (int) (yFin - yIni) - 2;

        g.setColor(color);
        g.fillRoundRect(x, y, w, h, 8, 8);
        g.setColor(color.darker());
        g.setStroke(new BasicStroke(1.2f));
        g.drawRoundRect(x, y, w, h, 8, 8);

        Shape clipAnterior = g.getClip();
        g.setClip(x + 3, y + 2, w - 6, h - 4);
        g.setColor(Color.WHITE);
        Font base = getFont();
        g.setFont(base.deriveFont(Font.BOLD, 12f));
        int ty = y + 16;
        g.drawString(cg.getCodigo(), x + 6, ty);
        g.setFont(base.deriveFont(11f));
        FontMetrics fm = g.getFontMetrics();
        ty += fm.getHeight();
        g.drawString(recortar(cg.getNombre(), fm, w - 12), x + 6, ty);
        ty += fm.getHeight();
        g.drawString("Grupo " + cg.getNumeroGrupo(), x + 6, ty);
        ty += fm.getHeight();
        g.drawString(b.getInicioTexto() + "-" + b.getFinTexto(), x + 6, ty);
        g.setClip(clipAnterior);
    }

    private static String recortar(String s, FontMetrics fm, int max) {
        if (fm.stringWidth(s) <= max) return s;
        while (s.length() > 1 && fm.stringWidth(s + "…") > max) {
            s = s.substring(0, s.length() - 1);
        }
        return s + "…";
    }

    /** Mismo código de curso = mismo color. */
    private static Color colorPara(String codigo) {
        float hue = (Math.abs(codigo.hashCode()) % 360) / 360f;
        return Color.getHSBColor(hue, 0.55f, 0.65f);
    }
}
