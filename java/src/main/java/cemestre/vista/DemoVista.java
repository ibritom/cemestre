package cemestre.vista;

import cemestre.datos.CargadorDatos;
import cemestre.datos.DatosInvalidosException;
import cemestre.modelo.BloqueHorario;
import cemestre.modelo.Combinacion;
import cemestre.modelo.ModeloHorarios;

import javax.swing.JOptionPane;
import javax.swing.SwingUtilities;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * TEMPORAL: prueba la vista con datos reales sin B ni D.
 * Uso: java -cp out cemestre.vista.DemoVista [catalogo.json] [salida_prolog.json]
 * Se borra al integrar (el controlador de D hará este trabajo).
 */
public class DemoVista {
    public static void main(String[] args) {
        String catalogo = args.length > 0 ? args[0] : "datos/catalogo_validado.json";
        String prolog = args.length > 1 ? args[1] : "datos/salida_prolog_ejemplo.json";

        SwingUtilities.invokeLater(() -> {
            ModeloHorarios modelo;
            try {
                modelo = new CargadorDatos().cargar(Paths.get(catalogo), Paths.get(prolog));
            } catch (DatosInvalidosException e) {
                JOptionPane.showMessageDialog(null, e.getMessage(), "Error al cargar datos", JOptionPane.ERROR_MESSAGE);
                return;
            }

            PanelHorario horario = new PanelHorario();
            PanelResumenCreditos resumen = new PanelResumenCreditos();
            List<ObservadorVista> observadores = Arrays.asList(horario, resumen); // D lo reemplazará con Observer

            VentanaPrincipal v = new VentanaPrincipal(
                    Arrays.asList("Menos días en el TEC", "Menos huecos", "Hora promedio de inicio", "Más créditos"),
                    horario, resumen);

            List<Combinacion> datos = new ArrayList<>(modelo.getCombinaciones());
            v.setCombinaciones(datos);
            v.setAlSeleccionarCombinacion(c -> observadores.forEach(o -> o.actualizar(c)));
            v.setAlCambiarCriterio(nombre -> { // orden de ejemplo; el real es el Strategy de B
                Comparator<Combinacion> cmp = nombre.startsWith("Más créditos")
                        ? Comparator.comparingInt(Combinacion::getCreditosTotales).reversed()
                        : Comparator.comparingInt(DemoVista::dias);
                datos.sort(cmp);
                v.setCombinaciones(datos);
            });
            v.setVisible(true);
        });
    }

    private static int dias(Combinacion c) {
        Set<Object> s = new HashSet<>();
        for (BloqueHorario b : c.getBloques()) s.add(b.getDia());
        return s.size();
    }
}
