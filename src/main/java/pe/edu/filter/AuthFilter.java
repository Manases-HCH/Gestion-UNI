package pe.edu.filter;

import jakarta.servlet.*;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.util.*;

@WebFilter("/*")
public class AuthFilter implements Filter {

    // Rutas públicas
    private static final Set<String> PUBLIC_PATHS = Set.of(
            "/Plataforma.jsp", "/login.jsp", "/loginServlet","/error403.jsp",
            "/css/", "/js/", "/img/", "/favicon.ico"
    );

    // Permisos por rol (solo se restringen los no-admin)
    private static final Map<String, List<String>> ROLE_PATHS = Map.of(
            "alumno", List.of("/INTERFAZ_ALUMNO/"),
            "profesor", List.of("/INTERFAZ_PROFESOR/"),
            "apoderado", List.of("/INTERFAZ_APODERADO/")
    );

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest req = (HttpServletRequest) request;
        HttpServletResponse res = (HttpServletResponse) response;
        HttpSession session = req.getSession(false);

        String path = req.getRequestURI().substring(req.getContextPath().length());

        // 🟢 Permitir acceso a rutas públicas
        if (isPublic(path)) {
            chain.doFilter(request, response);
            return;
        }

        // 🔒 Si no hay sesión o no hay rol -> redirigir al login
        if (session == null || session.getAttribute("rol") == null) {
            res.sendRedirect(req.getContextPath() + "/Plataforma.jsp");
            return;
        }

        String rol = (String) session.getAttribute("rol");

        // ⏱ Control de sesión inactiva (15 min)
        if (isSessionExpired(session, 15)) {
            session.invalidate();
            res.sendRedirect(req.getContextPath() + "/Plataforma.jsp?expired=true");
            return;
        }

        // 👑 Si es admin → acceso total
        if ("admin".equalsIgnoreCase(rol)) {
            chain.doFilter(request, response);
            return;
        }

        // 🚫 Validar rutas según el rol
        if (!isAuthorized(path, rol)) {
            System.out.println("[SECURITY] Acceso denegado: rol=" + rol + " intentó acceder a " + path);

            // ✅ Recuperar última página segura
            String ultimaRuta = (String) session.getAttribute("ultimaRutaSegura");

            // ✅ Guardar para usar en el JSP
            req.setAttribute("ultimaRutaSegura", ultimaRuta);

            // ✅ Redirigir a tu JSP personalizado
            res.sendRedirect(req.getContextPath() + "/error403.jsp");
            return;
        }

        // ✅ Actualizar timestamp de actividad y continuar
        session.setAttribute("lastActivity", System.currentTimeMillis());
        // ✅ Guardar última ruta segura (solo si es autorizado)
        session.setAttribute("ultimaRutaSegura", path);

        session.setAttribute("lastActivity", System.currentTimeMillis());
        chain.doFilter(request, response);
    }

    // 🔍 Verifica si es ruta pública
    private boolean isPublic(String path) {
        return PUBLIC_PATHS.stream().anyMatch(path::startsWith);
    }

    // 🔍 Verifica si el rol tiene permiso a la ruta
    private boolean isAuthorized(String path, String rol) {
        List<String> allowedPaths = ROLE_PATHS.get(rol);
        if (allowedPaths == null) {
            return false;
        }
        return allowedPaths.stream().anyMatch(path::startsWith);
    }

    // ⏱ Verifica expiración de sesión
    private boolean isSessionExpired(HttpSession session, int minutes) {
        Object last = session.getAttribute("lastActivity");
        if (last == null) {
            return false;
        }
        long elapsed = System.currentTimeMillis() - (long) last;
        return elapsed > (minutes * 60 * 1000);
    }
}