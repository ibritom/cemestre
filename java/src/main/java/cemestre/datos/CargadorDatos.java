package cemestre.datos;

import cemestre.modelo.Catalogo;
import cemestre.modelo.Combinacion;
import cemestre.modelo.ModeloHorarios;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Map;

/** Fachada de carga: lee los dos archivos, los adapta y entrega un {@link ModeloHorarios} unificado. */
public final class CargadorDatos {

    public ModeloHorarios cargar(Path catalogoC, Path salidaProlog) throws DatosInvalidosException {
        Catalogo catalogo = new AdaptadorCatalogoC().adaptar(leerObjeto(catalogoC));
        List<Combinacion> combinaciones = new AdaptadorResultadoProlog(catalogo).adaptar(leerObjeto(salidaProlog));
        return new ModeloHorarios(catalogo, combinaciones);
    }

    public Catalogo cargarCatalogo(Path catalogoC) throws DatosInvalidosException {
        return new AdaptadorCatalogoC().adaptar(leerObjeto(catalogoC));
    }

    private Map<String, Object> leerObjeto(Path ruta) throws DatosInvalidosException {
        String texto;
        try {
            texto = new String(Files.readAllBytes(ruta), StandardCharsets.UTF_8);
        } catch (IOException e) {
            throw new DatosInvalidosException("No se pudo leer el archivo " + ruta + ": " + e.getMessage(), e);
        }
        try {
            return Json.objeto(JsonParser.parsear(texto), ruta.getFileName().toString());
        } catch (DatosInvalidosException e) {
            throw new DatosInvalidosException(ruta.getFileName() + ": " + e.getMessage(), e);
        }
    }
}
