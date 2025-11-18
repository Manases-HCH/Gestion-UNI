<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, pe.universidad.util.Conection" %>
<%@ page import="java.net.URLEncoder" %>
<%@ page import="java.nio.charset.StandardCharsets" %>
<%@ page session="true" %>

<%
    // --- VALIDACIÓN DE SESIÓN ---
    String emailSesion = (String) session.getAttribute("email");
    String rolUsuario = (String) session.getAttribute("rol");
    Object idAlumnoObj = session.getAttribute("id_alumno"); // Changed from idApoderadoObj

    // Check if the user is logged in as an alumno and has a valid ID
    if (emailSesion == null || !"alumno".equalsIgnoreCase(rolUsuario) || idAlumnoObj == null) { // Changed rol check
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    int idAlumno = -1; // Changed from idApoderado
    try {
        idAlumno = Integer.parseInt(String.valueOf(idAlumnoObj));
    } catch (NumberFormatException e) {
        // If ID is invalid, redirect to login with an error message
        response.sendRedirect(request.getContextPath() + "/login.jsp?error=" + URLEncoder.encode("ID de alumno inválido en sesión.", StandardCharsets.UTF_8.toString())); // Changed error message
        return;
    }

    int idMensaje = -1;
    // This JSP can be called via GET (from table button) or POST (from modal AJAX)
    String idMensajeParam = request.getParameter("id_mensaje");
    if (idMensajeParam == null || idMensajeParam.isEmpty()) {
        idMensajeParam = request.getParameter("id_mensaje_modal"); // Assuming you might send it differently from modal
    }

    try {
        idMensaje = Integer.parseInt(idMensajeParam);
    } catch (NumberFormatException e) {
        // Redirect back to messages page with an error if message ID is invalid
        response.sendRedirect(request.getContextPath() + "/INTERFAZ_ALUMNO/mensajes_alumno.jsp?message=" + URLEncoder.encode("ID de mensaje inválido.", StandardCharsets.UTF_8.toString()) + "&type=" + URLEncoder.encode("danger", StandardCharsets.UTF_8.toString())); // Changed redirect path
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

        // Mark the message as read if the recipient is the logged-in alumno
        // And the recipient type is 'alumno'
        String sql = "UPDATE mensajes SET leido = TRUE WHERE id_mensaje = ? AND id_destinatario = ? AND tipo_destinatario = 'alumno'"; // Changed to TRUE, and tipo_destinatario
        pstmt = conn.prepareStatement(sql);
        pstmt.setInt(1, idMensaje);
        pstmt.setInt(2, idAlumno); // Use idAlumno

        int rowsAffected = pstmt.executeUpdate();

        // Check if this is an AJAX request from the modal
        boolean isAjax = "true".equalsIgnoreCase(request.getParameter("ajax"));

        if (rowsAffected > 0) {
            if (isAjax) {
                // For AJAX calls, just respond with a success status (e.g., 200 OK)
                response.setStatus(HttpServletResponse.SC_OK);
                response.getWriter().write("success"); // Simple text response for success
            } else {
                // For regular form submissions, redirect with a message
                response.sendRedirect(request.getContextPath() + "/INTERFAZ_ALUMNO/mensajes_alumno.jsp?message=" + URLEncoder.encode("Mensaje marcado como leído.", StandardCharsets.UTF_8.toString()) + "&type=" + URLEncoder.encode("success", StandardCharsets.UTF_8.toString())); // Changed redirect path
            }
        } else {
            if (isAjax) {
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST); // Or 404/403
                response.getWriter().write("fail");
            } else {
                response.sendRedirect(request.getContextPath() + "/INTERFAZ_ALUMNO/mensajes_alumno.jsp?message=" + URLEncoder.encode("No se pudo marcar el mensaje como leído o no tienes permiso.", StandardCharsets.UTF_8.toString()) + "&type=" + URLEncoder.encode("danger", StandardCharsets.UTF_8.toString())); // Changed redirect path
            }
        }

    } catch (SQLException e) {
        if ("true".equalsIgnoreCase(request.getParameter("ajax"))) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            response.getWriter().write("error: " + e.getMessage());
        } else {
            response.sendRedirect(request.getContextPath() + "/INTERFAZ_ALUMNO/mensajes_alumno.jsp?message=" + URLEncoder.encode("Error de base de datos al marcar mensaje: " + e.getMessage(), StandardCharsets.UTF_8.toString()) + "&type=" + URLEncoder.encode("danger", StandardCharsets.UTF_8.toString())); // Changed redirect path
        }
        e.printStackTrace();
    } catch (ClassNotFoundException e) {
        if ("true".equalsIgnoreCase(request.getParameter("ajax"))) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            response.getWriter().write("error: Driver JDBC no encontrado.");
        } else {
            response.sendRedirect(request.getContextPath() + "/INTERFAZ_ALUMNO/mensajes_alumno.jsp?message=" + URLEncoder.encode("Error: Driver JDBC no encontrado.", StandardCharsets.UTF_8.toString()) + "&type=" + URLEncoder.encode("danger", StandardCharsets.UTF_8.toString())); // Changed redirect path
        }
        e.printStackTrace();
    } finally {
        if (pstmt != null) { try { pstmt.close(); } catch (SQLException ignore) {} }
        if (conn != null) { try { conn.close(); } catch (SQLException ignore) {} }
    }
%>