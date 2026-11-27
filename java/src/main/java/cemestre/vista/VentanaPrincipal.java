package cemestre.vista;

import cemestre.modelo.Combinacion;
import cemestre.modelo.CursoGrupo;

import javax.swing.BorderFactory;
import javax.swing.DefaultListCellRenderer;
import javax.swing.DefaultListModel;
import javax.swing.JComboBox;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JList;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JSplitPane;
import javax.swing.JTextArea;
import javax.swing.ListSelectionModel;
import java.awt.BorderLayout;
import java.awt.Color;
import java.awt.Component;
import java.awt.Dimension;
import java.awt.FlowLayout;
import java.util.ArrayList;
import java.util.List;
import java.util.function.Consumer;

/**
 * Ventana principal. No genera, valida ni ordena: avisa por callbacks (que el controlador
 * conectará) cuando el usuario elige una combinación, un criterio o un filtro.
 */
public class VentanaPrincipal extends JFrame {
    private final DefaultListModel<Combinacion> modeloLista = new DefaultListModel<>();
    private final JList<Combinacion> lista = new JList<>(modeloLista);
    private final JComboBox<String> selCriterio;
    private final JComboBox<String> filtro = new JComboBox<>(new String[]{"Todas", "Válidas", "Rechazadas"});
    private final JTextArea txtDetalle = new JTextArea(4, 40);

    private List<Combinacion> todas = new ArrayList<>();
    private Consumer<Combinacion> alSeleccionarCombinacion = c -> { };
    private Consumer<String> alCambiarCriterio = s -> { };

    public VentanaPrincipal(List<String> criterios, PanelHorario horario, PanelResumenCreditos resumen) {
        super("CEmestre – Constructor de horarios");
        setDefaultCloseOperation(EXIT_ON_CLOSE);
        selCriterio = new JComboBox<>(criterios.toArray(new String[0]));

        add(construirBarraSuperior(), BorderLayout.NORTH);

        JScrollPane scrollLista = new JScrollPane(lista);
        scrollLista.setBorder(BorderFactory.createTitledBorder("Combinaciones"));
        scrollLista.setPreferredSize(new Dimension(280, 400));

        JPanel derecha = new JPanel(new BorderLayout(8, 0));
        JScrollPane scrollHorario = new JScrollPane(horario);
        scrollHorario.setBorder(BorderFactory.createTitledBorder("Horario semanal"));
        derecha.add(scrollHorario, BorderLayout.CENTER);
        derecha.add(resumen, BorderLayout.EAST);

        JSplitPane split = new JSplitPane(JSplitPane.HORIZONTAL_SPLIT, scrollLista, derecha);
        add(split, BorderLayout.CENTER);

        txtDetalle.setEditable(false);
        txtDetalle.setLineWrap(true);
        txtDetalle.setWrapStyleWord(true);
        JScrollPane scrollDetalle = new JScrollPane(txtDetalle);
        scrollDetalle.setBorder(BorderFactory.createTitledBorder("Razón de rechazo / sugerencias"));
        add(scrollDetalle, BorderLayout.SOUTH);

        configurarLista();
        setSize(1250, 780);
        setLocationRelativeTo(null);
    }

    private JPanel construirBarraSuperior() {
        JPanel barra = new JPanel(new FlowLayout(FlowLayout.LEFT, 10, 8));
        barra.add(new JLabel("Ordenar por:"));
        barra.add(selCriterio);
        barra.add(new JLabel("Mostrar:"));
        barra.add(filtro);
        selCriterio.addActionListener(e -> alCambiarCriterio.accept((String) selCriterio.getSelectedItem()));
        filtro.addActionListener(e -> aplicarFiltro());
        return barra;
    }

    private void configurarLista() {
        lista.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        lista.setCellRenderer(new DefaultListCellRenderer() {
            @Override
            public Component getListCellRendererComponent(JList<?> l, Object valor, int i,
                                                          boolean seleccionado, boolean foco) {
                Component c = super.getListCellRendererComponent(l, valor, i, seleccionado, foco);
                if (valor instanceof Combinacion) {
                    Combinacion comb = (Combinacion) valor;
                    setText(textoDe(comb));
                    if (!seleccionado) {
                        c.setForeground(comb.isCumple() ? new Color(0x1B7F3B) : new Color(0xB3261E));
                    }
                }
                return c;
            }
        });
        lista.addListSelectionListener(e -> {
            if (e.getValueIsAdjusting()) return;
            Combinacion sel = lista.getSelectedValue();
            mostrarDetalle(sel);
            if (sel != null) alSeleccionarCombinacion.accept(sel);
        });
    }

    private static String textoDe(Combinacion c) {
        StringBuilder sb = new StringBuilder(c.isCumple() ? "✔ " : "✘ ");
        sb.append('#').append(c.getId()).append("  ");
        boolean primero = true;
        for (CursoGrupo cg : c.getCursos()) {
            if (!primero) sb.append(", ");
            sb.append(cg);
            primero = false;
        }
        return sb.toString();
    }

    private void mostrarDetalle(Combinacion c) {
        if (c == null) {
            txtDetalle.setText("");
        } else if (c.isCumple()) {
            txtDetalle.setText(c.getRazon().describir() + " (" + c.getCreditosTotales() + " créditos)");
        } else {
            txtDetalle.setText("RECHAZADA: " + c.getRazon().describir() + "\n" + c.getSugerencia().describir());
        }
        txtDetalle.setCaretPosition(0);
    }

    private void aplicarFiltro() {
        int op = filtro.getSelectedIndex();
        modeloLista.clear();
        for (Combinacion c : todas) {
            if (op == 0 || (op == 1 && c.isCumple()) || (op == 2 && !c.isCumple())) {
                modeloLista.addElement(c);
            }
        }
        if (!modeloLista.isEmpty()) {
            lista.setSelectedIndex(0);
        } else {
            mostrarDetalle(null);
        }
    }

    // ---- API para el controlador ----
    public void setCombinaciones(List<Combinacion> combinaciones) {
        this.todas = new ArrayList<>(combinaciones);
        aplicarFiltro();
    }

    public void setAlSeleccionarCombinacion(Consumer<Combinacion> accion) { this.alSeleccionarCombinacion = accion; }

    public void setAlCambiarCriterio(Consumer<String> accion) { this.alCambiarCriterio = accion; }
}
