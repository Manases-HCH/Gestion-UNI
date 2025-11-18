package pe.universidad.util;

import java.io.IOException;
import jakarta.servlet.http.HttpServletResponse;

public class ErrorHandler {

    public static void handle(Exception e, HttpServletResponse response, String mensajeUsuario) {
        try {
            // Log interno (no visible al usuario)
            System.err.println("[ERROR] " + e.getClass().getSimpleName() + ": " + e.getMessage());

            // Respuesta controlada para el usuario
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            response.setContentType("text/html;charset=UTF-8");
            response.getWriter().write("<script>alert('" + mensajeUsuario + "'); window.location.href='Plataforma.jsp';</script>");
        } catch (IOException ioEx) {
            System.err.println("[ERROR] No se pudo enviar mensaje al cliente: " + ioEx.getMessage());
        }
    }
}
