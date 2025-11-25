package com.edu.pe.login;

import java.io.IOException;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.Types;
import org.mindrot.jbcrypt.BCrypt;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import pe.universidad.util.Conection;
import pe.universidad.util.ErrorHandler; // ✅ Importamos nuestro manejador

@WebServlet("/loginServlet")
public class LoginServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String username = request.getParameter("username");
        String password = request.getParameter("password");
        String userType = request.getParameter("userType");

        Connection conn = null;
        CallableStatement cstmt = null;
        ResultSet rs = null;
        PreparedStatement pstmt = null;
        String hashBd = null;


        try {
            Conection conexionUtil = new Conection();
            conn = conexionUtil.conecta();

            // 🔹 1. Verificar estado de cuenta
            String estadoCuenta = obtenerEstadoCuenta(conn, username, userType);

            if (estadoCuenta == null) {
                HttpSession session = request.getSession();
                session.setAttribute("loginError", "Credenciales inválidas. Intente nuevamente.");
                response.sendRedirect("Plataforma.jsp");
                return;
            }

            if ("inactivo".equalsIgnoreCase(estadoCuenta)) {
                HttpSession session = request.getSession();
                session.setAttribute("loginError", "Tu cuenta ha sido bloqueada. Contacta al administrador.");
                response.sendRedirect("Plataforma.jsp");
                return;
            }

            if (!verificarIntentosDisponibles(conn, username, userType)) {
                HttpSession session = request.getSession();
                session.setAttribute("loginError", "Has superado el número máximo de intentos. Tu cuenta ha sido bloqueada temporalmente.");
                response.sendRedirect("Plataforma.jsp");
                return;
            }

            boolean isAuthenticated = false;

            // 🔹 2. Seleccionar el procedimiento según tipo de usuario
            switch (userType) {
                case "alumno":
                    cstmt = conn.prepareCall("{CALL sp_authenticateAlumno(?)}");
                    cstmt.setString(1, username);
                    break;
                case "profesor":
                    cstmt = conn.prepareCall("{CALL sp_authenticateProfesor(?, ?, ?)}");
                    break;
                case "apoderado":
                    cstmt = conn.prepareCall("{CALL sp_authenticateApoderado(?, ?, ?)}");
                    break;
                case "admin":
                    cstmt = conn.prepareCall("{CALL sp_authenticateAdmin(?, ?, ?)}");
                    break;
                default:
                    HttpSession session = request.getSession();
                    session.setAttribute("loginError", "Rol de usuario desconocido.");
                    response.sendRedirect("Plataforma.jsp");
                    return;
            }

                // === AUTENTICACIÓN CON HASH BCRYPT ===
                String sql = "SELECT password FROM " + userType + "s WHERE email = ?";
                pstmt = conn.prepareStatement(sql);
                pstmt.setString(1, username);
                rs = cstmt.executeQuery();
                if (rs.next()) {
                    hashBd = rs.getString("password");
                }

                // Comparar contraseña ingresada con el hash
                if (hashBd != null) {
                    isAuthenticated = BCrypt.checkpw(password, hashBd);
                }


            // 🔹 3. Validar resultado de autenticación
            if (isAuthenticated) {
                reiniciarIntentos(conn, username, userType);
                HttpSession session = request.getSession();
                session.setAttribute("email", username);
                session.setAttribute("rol", userType);
                obtenerYGuardarIdUsuario(conn, session, username, userType);

                switch (userType) {
                    case "alumno":
                        response.sendRedirect("INTERFAZ_ALUMNO/home_alumno.jsp");
                        break;
                    case "profesor":
                        response.sendRedirect("INTERFAZ_PROFESOR/home_profesor.jsp");
                        break;
                    case "apoderado":
                        response.sendRedirect("INTERFAZ_APODERADO/home_apoderado.jsp");
                        break;
                    case "admin":
                        response.sendRedirect("inicio.jsp");
                        break;
                }
            } else {
                int intentosRestantes = reducirIntentos(conn, username, userType);
                HttpSession session = request.getSession();

                if (intentosRestantes <= 0) {
                    session.setAttribute("loginError", "Cuenta bloqueada por demasiados intentos fallidos. Contacte al administrador.");
                } else {
                    session.setAttribute("loginError", "Credenciales inválidas. Te quedan " + intentosRestantes + " intentos.");
                }
                response.sendRedirect("Plataforma.jsp");
            }

        } catch (SQLException e) {
            ErrorHandler.handle(e, response, "Error interno del sistema. Intente nuevamente más tarde.");
        } catch (ClassNotFoundException e) {
            ErrorHandler.handle(e, response, "Error interno al iniciar el servicio. Contacte al administrador.");
        } catch (Exception e) {
            ErrorHandler.handle(e, response, "Ha ocurrido un error inesperado. Intente más tarde.");
        } finally {
            // 🔹 Cierre seguro de recursos
            try { if (rs != null) rs.close(); } catch (SQLException e) { System.err.println("Error al cerrar ResultSet."); }
            try { if (pstmt != null) pstmt.close(); } catch (SQLException e) { System.err.println("Error al cerrar PreparedStatement."); }
            try { if (cstmt != null) cstmt.close(); } catch (SQLException e) { System.err.println("Error al cerrar CallableStatement."); }
            try { if (conn != null) conn.close(); } catch (SQLException e) { System.err.println("Error al cerrar conexión."); }
        }
    }

    // 🔸 MÉTODOS AUXILIARES
    private boolean verificarIntentosDisponibles(Connection conn, String email, String userType) throws SQLException {
        String tableName = getTableName(userType);
        if (tableName == null) return false;

        String sql = "SELECT intentos, estado FROM " + tableName + " WHERE email = ?";
        try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, email);
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    int intentos = rs.getInt("intentos");
                    String estado = rs.getString("estado");
                    return intentos > 0 && "activo".equals(estado);
                }
            }
        }
        return false;
    }

    private String obtenerEstadoCuenta(Connection conn, String email, String userType) throws SQLException {
        String tableName = getTableName(userType);
        if (tableName == null) return null;

        String sql = "SELECT estado FROM " + tableName + " WHERE email = ?";
        try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, email);
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) return rs.getString("estado");
            }
        }
        return null;
    }

    private int reducirIntentos(Connection conn, String email, String userType) throws SQLException {
        String tableName = getTableName(userType);
        if (tableName == null) return 0;

        String updateSql = "UPDATE " + tableName + " SET intentos = intentos - 1 WHERE email = ?";
        try (PreparedStatement pstmt = conn.prepareStatement(updateSql)) {
            pstmt.setString(1, email);
            pstmt.executeUpdate();
        }

        String selectSql = "SELECT intentos FROM " + tableName + " WHERE email = ?";
        try (PreparedStatement pstmt = conn.prepareStatement(selectSql)) {
            pstmt.setString(1, email);
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    int intentosRestantes = rs.getInt("intentos");
                    if (intentosRestantes <= 0) bloquearCuenta(conn, email, userType);
                    return intentosRestantes;
                }
            }
        }
        return 0;
    }

    private void reiniciarIntentos(Connection conn, String email, String userType) throws SQLException {
        String tableName = getTableName(userType);
        if (tableName == null) return;

        String sql = "UPDATE " + tableName + " SET intentos = 3 WHERE email = ?";
        try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, email);
            pstmt.executeUpdate();
        }
    }

    private void bloquearCuenta(Connection conn, String email, String userType) throws SQLException {
        String tableName = getTableName(userType);
        if (tableName == null) return;

        String sql = "UPDATE " + tableName + " SET estado = 'inactivo' WHERE email = ?";
        try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, email);
            pstmt.executeUpdate();
        }
    }

    private String getTableName(String userType) {
        switch (userType) {
            case "alumno": return "alumnos";
            case "profesor": return "profesores";
            case "apoderado": return "apoderados";
            case "admin": return "admin";
            default: return null;
        }
    }

    private void obtenerYGuardarIdUsuario(Connection conn, HttpSession session, String username, String userType)
            throws SQLException {
        String sql = "";
        String idAttribute = "";

        switch (userType) {
            case "alumno":
                sql = "SELECT id_alumno FROM alumnos WHERE email = ?";
                idAttribute = "id_alumno";
                break;
            case "profesor":
                sql = "SELECT id_profesor FROM profesores WHERE email = ?";
                idAttribute = "id_profesor";
                break;
            case "apoderado":
                sql = "SELECT id_apoderado FROM apoderados WHERE email = ?";
                idAttribute = "id_apoderado";
                break;
            case "admin":
                sql = "SELECT id_admin FROM admin WHERE email = ?";
                idAttribute = "id_admin";
                break;
            default:
                return;
        }

        try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, username);
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    session.setAttribute(idAttribute, rs.getInt(idAttribute));
                } else {
                    System.err.println("No se encontró ID para el usuario " + username);
                }
            }
        }
    }
}
    