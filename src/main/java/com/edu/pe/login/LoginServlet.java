package com.edu.pe.login;

import java.io.IOException;
import java.sql.*;
import org.mindrot.jbcrypt.BCrypt;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import pe.universidad.util.Conection;
import pe.universidad.util.ErrorHandler;

@WebServlet("/loginServlet")
public class LoginServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String username = request.getParameter("username");
        String passwordIngresada = request.getParameter("secret");
        String userType = request.getParameter("userType");

        Connection conn = null;
        CallableStatement cstmt = null;
        ResultSet rs = null;

        try {
            // Conexión
            Conection conexionUtil = new Conection();
            conn = conexionUtil.conecta();

            // Validar existencia de cuenta
            if (obtenerEstadoCuenta(conn, username, userType) == null) {
                error(request, response, "Credenciales inválidas.");
                return;
            }

            // Validar si está inactivo
            if ("inactivo".equalsIgnoreCase(obtenerEstadoCuenta(conn, username, userType))) {
                error(request, response, "Tu cuenta ha sido bloqueada. Contacta al administrador.");
                return;
            }

            // Validar intentos restantes
            if (!verificarIntentosDisponibles(conn, username, userType)) {
                error(request, response, "Has superado el número de intentos. Tu cuenta ha sido bloqueada.");
                return;
            }

            // === CONSULTAR PASSWORD HASH ===
            String sql = "SELECT password FROM " + getTableName(userType) + " WHERE email = ?";
            PreparedStatement pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, username);
            rs = pstmt.executeQuery();

            String hashBd = null;
            if (rs.next()) {
                hashBd = rs.getString("password");
            }

            boolean isAuthenticated = false;

            if (hashBd != null) {
                // Comparar hash bcrypt
                isAuthenticated = BCrypt.checkpw(passwordIngresada, hashBd);
            }

            // Resultado
            if (isAuthenticated) {
                reiniciarIntentos(conn, username, userType);

                HttpSession session = request.getSession();
                session.setAttribute("email", username);
                session.setAttribute("rol", userType);

                obtenerYGuardarIdUsuario(conn, session, username, userType);

                redirigirSegunRol(response, userType);

            } else {
                int intentos = reducirIntentos(conn, username, userType);
                if (intentos <= 0) {
                    error(request, response, "Cuenta bloqueada. Contacte al administrador.");
                } else {
                    error(request, response, "Credenciales inválidas. Intentos restantes: " + intentos);
                }
            }

        } catch (Exception e) {
            ErrorHandler.handle(e, response, "Error interno del sistema.");
        } finally {
            try { if (rs != null) rs.close(); } catch (Exception ignored) {}
            try { if (cstmt != null) cstmt.close(); } catch (Exception ignored) {}
            try { if (conn != null) conn.close(); } catch (Exception ignored) {}
        }
    }

    // ========================================
    // MÉTODOS AUXILIARES
    // ========================================

    private void error(HttpServletRequest req, HttpServletResponse resp, String msg) throws IOException {
        HttpSession session = req.getSession();
        session.setAttribute("loginError", msg);
        resp.sendRedirect("Plataforma.jsp");
    }

    private String getTableName(String userType) {
        switch (userType) {
            case "alumno": return "alumnos";
            case "profesor": return "profesores";
            case "apoderado": return "apoderados";
            case "admin": return "admin"; // ⇦ CORREGIDO
        }
        return null;
    }

    private String obtenerEstadoCuenta(Connection conn, String email, String userType) throws SQLException {
        String table = getTableName(userType);
        String sql = "SELECT estado FROM " + table + " WHERE email = ?";
        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setString(1, email);
        ResultSet rs = ps.executeQuery();
        if (rs.next()) return rs.getString("estado");
        return null;
    }

    private boolean verificarIntentosDisponibles(Connection conn, String email, String userType) throws SQLException {
        String sql = "SELECT intentos FROM " + getTableName(userType) + " WHERE email = ?";
        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setString(1, email);
        ResultSet rs = ps.executeQuery();
        if (rs.next()) return rs.getInt("intentos") > 0;
        return false;
    }

    private int reducirIntentos(Connection conn, String email, String userType) throws SQLException {
        String sql = "UPDATE " + getTableName(userType) + " SET intentos = intentos - 1 WHERE email = ?";
        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setString(1, email);
        ps.executeUpdate();

        sql = "SELECT intentos FROM " + getTableName(userType) + " WHERE email = ?";
        ps = conn.prepareStatement(sql);
        ps.setString(1, email);
        ResultSet rs = ps.executeQuery();
        if (rs.next()) return rs.getInt("intentos");
        return 0;
    }

    private void reiniciarIntentos(Connection conn, String email, String userType) throws SQLException {
        String sql = "UPDATE " + getTableName(userType) + " SET intentos = 3 WHERE email = ?";
        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setString(1, email);
        ps.executeUpdate();
    }

    private void obtenerYGuardarIdUsuario(Connection conn, HttpSession session, String email, String userType)
            throws SQLException {

        String sql = "";
        String attr = "";

        switch (userType) {
            case "alumno":
                sql = "SELECT id_alumno FROM alumnos WHERE email = ?";
                attr = "id_alumno";
                break;
            case "profesor":
                sql = "SELECT id_profesor FROM profesores WHERE email = ?";
                attr = "id_profesor";
                break;
            case "apoderado":
                sql = "SELECT id_apoderado FROM apoderados WHERE email = ?";
                attr = "id_apoderado";
                break;
            case "admin":
                sql = "SELECT id_admin FROM admin WHERE email = ?";
                attr = "id_admin";
                break;
        }

        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setString(1, email);
        ResultSet rs = ps.executeQuery();

        if (rs.next()) session.setAttribute(attr, rs.getInt(attr));
    }

    private void redirigirSegunRol(HttpServletResponse resp, String userType) throws IOException {
        switch (userType) {
            case "alumno":
                resp.sendRedirect("INTERFAZ_ALUMNO/home_alumno.jsp");
                break;
            case "profesor":
                resp.sendRedirect("INTERFAZ_PROFESOR/home_profesor.jsp");
                break;
            case "apoderado":
                resp.sendRedirect("INTERFAZ_APODERADO/home_apoderado.jsp");
                break;
            case "admin":
                resp.sendRedirect("inicio.jsp");
                break;
        }
    }
}
