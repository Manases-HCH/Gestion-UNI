<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, pe.universidad.util.Conection" %>
<%@ page import="java.net.URLEncoder" %>
<%@ page import="java.nio.charset.StandardCharsets" %>
<%@ page session="true" %>

<%
    // --- VALIDACIÓN DE SESIÓN ---
    String emailSesion = (String) session.getAttribute("email");
    String rolUsuario = (String) session.getAttribute("rol");
    Object idProfesorObj = session.getAttribute("id_profesor");

    if (emailSesion == null || !"profesor".equalsIgnoreCase(rolUsuario) || idProfesorObj == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    int idProfesor = -1;
    try {
        idProfesor = Integer.parseInt(String.valueOf(idProfesorObj));
    } catch (NumberFormatException e) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?error=" + URLEncoder.encode("ID de profesor inválido en sesión.", StandardCharsets.UTF_8.toString()));
        return;
    }

    int idMensaje = -1;
    try {
        idMensaje = Integer.parseInt(request.getParameter("id_mensaje"));
    } catch (NumberFormatException e) {
        response.sendRedirect(request.getContextPath() + "/INTERFAZ_PROFESOR/mensaje_profesor.jsp?error=" + URLEncoder.encode("ID de mensaje inválido.", StandardCharsets.UTF_8.toString()));
        return;
    }

    Conection conUtil = null;
    Connection conn = null;
    PreparedStatement pstmt = null;

    try {
        conUtil = new Conection();
        conn = conUtil.conecta();

        if (conn == null || conn.isClosed()) {
            throw new SQLException("No se pudo establecer conexión a la base de datos.");
        }

        // Marcar el mensaje como leído si el destinatario es el apoderado logueado
        // Y el tipo de destinatario es 'apoderado'
        String sql = "UPDATE mensajes SET leido = 1 WHERE id_mensaje = ? AND id_destinatario = ? AND tipo_destinatario = 'profesor'";
        pstmt = conn.prepareStatement(sql);
        pstmt.setInt(1, idMensaje);
        pstmt.setInt(2, idProfesor);

        int rowsAffected = pstmt.executeUpdate();

        if (rowsAffected > 0) {
            response.sendRedirect(request.getContextPath() + "/INTERFAZ_PROFESOR/mensaje_profesor.jsp?error=" + URLEncoder.encode("Mensaje marcado como leído.", StandardCharsets.UTF_8.toString()) + "&type=" + URLEncoder.encode("success", StandardCharsets.UTF_8.toString()));
        } else {
            response.sendRedirect(request.getContextPath() + "/INTERFAZ_PROFESOR/mensaje_profesor.jsp?error=" + URLEncoder.encode("No se pudo marcar el mensaje como leído o no tienes permiso.", StandardCharsets.UTF_8.toString()) + "&type=" + URLEncoder.encode("danger", StandardCharsets.UTF_8.toString()));
        }

    } catch (SQLException e) {
        response.sendRedirect(request.getContextPath() + "/INTERFAZ_PROFESOR/mensaje_profesor.jsp?error=" + URLEncoder.encode("Error de base de datos al marcar mensaje: " + e.getMessage(), StandardCharsets.UTF_8.toString()) + "&type=" + URLEncoder.encode("danger", StandardCharsets.UTF_8.toString()));
        e.printStackTrace();
    } catch (ClassNotFoundException e) {
        response.sendRedirect(request.getContextPath() + "/INTERFAZ_PROFESOR/mensaje_profesor.jsp?error=" + URLEncoder.encode("Error: Driver JDBC no encontrado.", StandardCharsets.UTF_8.toString()) + "&type=" + URLEncoder.encode("danger", StandardCharsets.UTF_8.toString()));
        e.printStackTrace();
    } finally {
        if (pstmt != null) { try { pstmt.close(); } catch (SQLException ignore) {} }
        if (conn != null) { try { conn.close(); } catch (SQLException ignore) {} }
    }
%>