package cemestre.datos;

import java.util.List;
import java.util.Map;

/** Accesores tipados sobre el resultado de {@link JsonParser}, con mensajes de error claros. */
final class Json {
    private Json() { }

    @SuppressWarnings("unchecked")
    static Map<String, Object> objeto(Object valor, String contexto) throws DatosInvalidosException {
        if (!(valor instanceof Map)) throw new DatosInvalidosException(contexto + ": se esperaba un objeto JSON");
        return (Map<String, Object>) valor;
    }

    @SuppressWarnings("unchecked")
    static List<Object> lista(Object valor, String contexto) throws DatosInvalidosException {
        if (!(valor instanceof List)) throw new DatosInvalidosException(contexto + ": se esperaba un arreglo JSON");
        return (List<Object>) valor;
    }

    static Object campo(Map<String, Object> o, String clave, String contexto) throws DatosInvalidosException {
        if (!o.containsKey(clave)) throw new DatosInvalidosException(contexto + ": falta el campo '" + clave + "'");
        return o.get(clave);
    }

    static String texto(Map<String, Object> o, String clave, String contexto) throws DatosInvalidosException {
        Object v = campo(o, clave, contexto);
        if (v instanceof String) return (String) v;
        if (v instanceof Number) return String.valueOf(v);
        throw new DatosInvalidosException(contexto + ": '" + clave + "' debe ser texto");
    }

    static int entero(Map<String, Object> o, String clave, String contexto) throws DatosInvalidosException {
        return aEntero(campo(o, clave, contexto), contexto + "." + clave);
    }

    static boolean booleano(Map<String, Object> o, String clave, String contexto) throws DatosInvalidosException {
        Object v = campo(o, clave, contexto);
        if (v instanceof Boolean) return (Boolean) v;
        throw new DatosInvalidosException(contexto + ": '" + clave + "' debe ser true o false");
    }

    /** Acepta números JSON o textos numéricos (C exporta las horas como texto: "20930"). */
    static int aEntero(Object v, String contexto) throws DatosInvalidosException {
        if (v instanceof Number) return ((Number) v).intValue();
        if (v instanceof String) {
            try {
                return Integer.parseInt(((String) v).trim());
            } catch (NumberFormatException e) {
                // cae al error de abajo
            }
        }
        throw new DatosInvalidosException(contexto + ": se esperaba un entero, se encontró " + v);
    }
}
