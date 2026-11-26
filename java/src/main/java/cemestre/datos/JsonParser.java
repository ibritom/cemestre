package cemestre.datos;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Parser JSON mínimo (RFC 8259) para no depender de librerías externas y poder
 * ejecutar con java -jar. Devuelve Map, List, String, Long, Double, Boolean o null.
 */
public final class JsonParser {
    private final String texto;
    private int pos;

    private JsonParser(String texto) {
        this.texto = texto;
    }

    public static Object parsear(String texto) throws DatosInvalidosException {
        if (texto != null && texto.startsWith("\uFEFF")) {
            texto = texto.substring(1);
        }
        JsonParser p = new JsonParser(texto == null ? "" : texto);
        p.saltarEspacios();
        Object valor = p.leerValor();
        p.saltarEspacios();
        if (p.pos != p.texto.length()) {
            throw p.error("Contenido inesperado después del JSON");
        }
        return valor;
    }

    private Object leerValor() throws DatosInvalidosException {
        if (pos >= texto.length()) throw error("Fin inesperado del JSON");
        char c = texto.charAt(pos);
        switch (c) {
            case '{': return leerObjeto();
            case '[': return leerArreglo();
            case '"': return leerCadena();
            case 't': consumir("true"); return Boolean.TRUE;
            case 'f': consumir("false"); return Boolean.FALSE;
            case 'n': consumir("null"); return null;
            default:
                if (c == '-' || Character.isDigit(c)) return leerNumero();
                throw error("Carácter inesperado '" + c + "'");
        }
    }

    private Map<String, Object> leerObjeto() throws DatosInvalidosException {
        Map<String, Object> mapa = new LinkedHashMap<>();
        pos++; // {
        saltarEspacios();
        if (peek() == '}') { pos++; return mapa; }
        while (true) {
            saltarEspacios();
            if (peek() != '"') throw error("Se esperaba una clave de texto");
            String clave = leerCadena();
            saltarEspacios();
            if (peek() != ':') throw error("Se esperaba ':'");
            pos++;
            saltarEspacios();
            mapa.put(clave, leerValor());
            saltarEspacios();
            char c = peek();
            pos++;
            if (c == '}') return mapa;
            if (c != ',') throw error("Se esperaba ',' o '}'");
        }
    }

    private List<Object> leerArreglo() throws DatosInvalidosException {
        List<Object> lista = new ArrayList<>();
        pos++; // [
        saltarEspacios();
        if (peek() == ']') { pos++; return lista; }
        while (true) {
            saltarEspacios();
            lista.add(leerValor());
            saltarEspacios();
            char c = peek();
            pos++;
            if (c == ']') return lista;
            if (c != ',') throw error("Se esperaba ',' o ']'");
        }
    }

    private String leerCadena() throws DatosInvalidosException {
        StringBuilder sb = new StringBuilder();
        pos++; // comilla inicial
        while (true) {
            if (pos >= texto.length()) throw error("Cadena sin cerrar");
            char c = texto.charAt(pos++);
            if (c == '"') return sb.toString();
            if (c != '\\') { sb.append(c); continue; }
            if (pos >= texto.length()) throw error("Escape incompleto");
            char e = texto.charAt(pos++);
            switch (e) {
                case '"': sb.append('"'); break;
                case '\\': sb.append('\\'); break;
                case '/': sb.append('/'); break;
                case 'b': sb.append('\b'); break;
                case 'f': sb.append('\f'); break;
                case 'n': sb.append('\n'); break;
                case 'r': sb.append('\r'); break;
                case 't': sb.append('\t'); break;
                case 'u':
                    if (pos + 4 > texto.length()) throw error("Escape \\u incompleto");
                    try {
                        sb.append((char) Integer.parseInt(texto.substring(pos, pos + 4), 16));
                    } catch (NumberFormatException ex) {
                        throw error("Escape \\u inválido");
                    }
                    pos += 4;
                    break;
                default: throw error("Escape inválido \\" + e);
            }
        }
    }

    private Object leerNumero() throws DatosInvalidosException {
        int inicio = pos;
        if (peek() == '-') pos++;
        while (pos < texto.length() && "0123456789.eE+-".indexOf(texto.charAt(pos)) >= 0) pos++;
        String t = texto.substring(inicio, pos);
        try {
            if (t.contains(".") || t.contains("e") || t.contains("E")) return Double.valueOf(t);
            return Long.valueOf(t);
        } catch (NumberFormatException ex) {
            pos = inicio;
            throw error("Número inválido '" + t + "'");
        }
    }

    private void consumir(String literal) throws DatosInvalidosException {
        if (!texto.startsWith(literal, pos)) throw error("Se esperaba '" + literal + "'");
        pos += literal.length();
    }

    private char peek() throws DatosInvalidosException {
        if (pos >= texto.length()) throw error("Fin inesperado del JSON");
        return texto.charAt(pos);
    }

    private void saltarEspacios() {
        while (pos < texto.length() && Character.isWhitespace(texto.charAt(pos))) pos++;
    }

    private DatosInvalidosException error(String mensaje) {
        int linea = 1;
        for (int i = 0; i < Math.min(pos, texto.length()); i++) {
            if (texto.charAt(i) == '\n') linea++;
        }
        return new DatosInvalidosException("JSON inválido (línea " + linea + ", posición " + pos + "): " + mensaje);
    }
}
