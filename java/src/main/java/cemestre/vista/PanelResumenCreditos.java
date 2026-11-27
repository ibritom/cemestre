package cemestre.vista;

import cemestre.modelo.BloqueHorario;
import cemestre.modelo.Combinacion;
import cemestre.modelo.CursoGrupo;

import javax.swing.BorderFactory;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JTable;
import javax.swing.table.DefaultTableModel;
import java.awt.BorderLayout;
import java.awt.Dimension;
import java.awt.Font;
import java.util.HashSet;
import java.util.Set;

/** Segunda vista sincronizada: créditos por curso y total. */
public class PanelResumenCreditos extends JPanel implements ObservadorVista {
    private final DefaultTableModel modelo =
            new DefaultTableModel(new String[]{"Código", "Nombre", "Grupo", "Créd."}, 0) {
                @Override
                public boolean isCellEditable(int fila, int columna) {
                    return false;
                }
            };
    private final JLabel lblTotal = new JLabel("Total: 0 créditos");
    private final JLabel lblDias = new JLabel("Días en el TEC: 0");

    public PanelResumenCreditos() {
        super(new BorderLayout(0, 6));
        setBorder(BorderFactory.createTitledBorder("Resumen de créditos"));
        setPreferredSize(new Dimension(320, 200));

        JTable tabla = new JTable(modelo);
        tabla.getColumnModel().getColumn(0).setPreferredWidth(60);
        tabla.getColumnModel().getColumn(1).setPreferredWidth(160);
        tabla.getColumnModel().getColumn(2).setPreferredWidth(45);
        tabla.getColumnModel().getColumn(3).setPreferredWidth(40);
        lblTotal.setFont(lblTotal.getFont().deriveFont(Font.BOLD, 14f));

        JPanel pie = new JPanel(new BorderLayout());
        pie.add(lblTotal, BorderLayout.NORTH);
        pie.add(lblDias, BorderLayout.SOUTH);

        add(new JScrollPane(tabla), BorderLayout.CENTER);
        add(pie, BorderLayout.SOUTH);
    }

    @Override
    public void actualizar(Combinacion c) {
        modelo.setRowCount(0);
        if (c == null) {
            lblTotal.setText("Total: 0 créditos");
            lblDias.setText("Días en el TEC: 0");
            return;
        }
        for (CursoGrupo cg : c.getCursos()) {
            modelo.addRow(new Object[]{cg.getCodigo(), cg.getNombre(), cg.getNumeroGrupo(), cg.getCreditos()});
        }
        Set<Object> dias = new HashSet<>();
        for (BloqueHorario b : c.getBloques()) {
            dias.add(b.getDia());
        }
        lblTotal.setText("Total: " + c.getCreditosTotales() + " créditos");
        lblDias.setText("Días en el TEC: " + dias.size());
    }
}
