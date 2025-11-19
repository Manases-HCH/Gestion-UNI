<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, pe.universidad.util.Conection" %>
<%@ page import="java.net.URLEncoder" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.ArrayList" %>
<%@ page session="true" %>

<%!
    // Método auxiliar para cerrar ResultSet y PreparedStatement
    private void closeDbResources(ResultSet rs, PreparedStatement pstmt) {
        try {
            if (rs != null) {
                rs.close();
            }
        } catch (SQLException e) { /* Ignorar al cerrar */ }
        try {
            if (pstmt != null) {
                pstmt.close();
            }
        } catch (SQLException e) { /* Ignorar al cerrar */ }
    }

    // Helper method for manual JSON string escaping
    private String escapeJson(String text) {
        if (text == null) {
            return "null";
        }
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < text.length(); i++) {
            char ch = text.charAt(i);
            switch (ch) {
                case '"':
                    sb.append("\\\"");
                    break;
                case '\\':
                    sb.append("\\\\");
                    break;
                case '\b':
                    sb.append("\\b");
                    break;
                case '\f':
                    sb.append("\\f");
                    break;
                case '\n':
                    sb.append("\\n");
                    break;
                case '\r':
                    sb.append("\\r");
                    break;
                case '\t':
                    sb.append("\\t");
                    break;
                // Add more escaping if needed for other control characters or HTML entities
                default:
                    if (ch < ' ' || (ch >= '\u0080' && ch < '\u00a0') || (ch >= '\u2000' && ch < '\u2100')) {
                        sb.append(String.format("\\u%04x", (int) ch));
                    } else {
                        sb.append(ch);
                    }
            }
        }
        return sb.toString();
    }
%>

<%
    // --- VALIDACIÓN DE SESIÓN ---
    String emailSesion = (String) session.getAttribute("email");
    String rolUsuario = (String) session.getAttribute("rol");
    Object idProfesorObj = session.getAttribute("id_profesor");

    if (emailSesion == null || !"profesor".equalsIgnoreCase(rolUsuario) || idProfesorObj == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp"); // Redirect to base login
        return;
    }

    int idProfesor = -1;
    if (idProfesorObj instanceof Integer) {
        idProfesor = (Integer) idProfesorObj;
    } else {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    String nombreProfesor = (String) session.getAttribute("nombre_profesor");
    if (nombreProfesor == null || nombreProfesor.isEmpty()) {
        Connection connTemp = null;
        PreparedStatement pstmtTemp = null;
        ResultSet rsTemp = null;
        try {
            connTemp = new Conection().conecta();
            String sqlGetNombre = "SELECT CONCAT(p.nombre, ' ', p.apellido_paterno, ' ', IFNULL(p.apellido_materno, '')) AS nombre_completo FROM profesores WHERE id_profesor = ?";
            pstmtTemp = connTemp.prepareStatement(sqlGetNombre);
            pstmtTemp.setInt(1, idProfesor);
            rsTemp = pstmtTemp.executeQuery();
            if (rsTemp.next()) {
                nombreProfesor = rsTemp.getString("nombre_completo");
                session.setAttribute("nombre_profesor", nombreProfesor);
            }
        } catch (SQLException | ClassNotFoundException ex) {
            System.err.println("Error al obtener nombre del profesor en enviar_mensaje_seccion.jsp: " + ex.getMessage());
            // No redirect, just log.
        } finally {
            closeDbResources(rsTemp, pstmtTemp);
            if (connTemp != null) { try { connTemp.close(); } catch (SQLException ignore) {} }
        }
    }

    // --- Detectar si es una solicitud AJAX para buscar alumnos o seleccionar todos ---
    String searchTerm = request.getParameter("term");
    String requestType = request.getParameter("requestType"); // "getAllStudentsByProfessor" or "getAllStudentsByClass"
    String idClaseForAjax = request.getParameter("id_clase"); // Used when requestType is "getAllStudentsByClass"

    // This block executes ONLY if it's an AJAX call.
    if (searchTerm != null || "getAllStudentsByProfessor".equals(requestType) || "getAllStudentsByClass".equals(requestType)) {
        response.setContentType("application/json;charset=UTF-8");
        StringBuilder jsonResponse = new StringBuilder(); // Manual JSON building
        Connection connAjax = null;
        PreparedStatement pstmtAjax = null;
        ResultSet rsAjax = null;

        try {
            connAjax = new Conection().conecta();
            if (connAjax == null || connAjax.isClosed()) {
                throw new SQLException("No se pudo establecer conexión a la base de datos para AJAX.");
            }

            String sql;
            if ("getAllStudentsByProfessor".equals(requestType)) {
                sql = "SELECT DISTINCT a.id_alumno, a.dni, a.nombre, a.apellido_paterno, a.apellido_materno, a.email "
                    + "FROM alumnos a "
                    + "INNER JOIN inscripciones i ON a.id_alumno = i.id_alumno "
                    + "INNER JOIN clases cl ON i.id_clase = cl.id_clase "
                    + "WHERE cl.id_profesor = ? AND cl.estado = 'activo' AND i.estado = 'inscrito' "
                    + "ORDER BY a.apellido_paterno, a.nombre";
                pstmtAjax = connAjax.prepareStatement(sql);
                pstmtAjax.setInt(1, idProfesor);

            } else if ("getAllStudentsByClass".equals(requestType) && idClaseForAjax != null && !idClaseForAjax.isEmpty()) {
                int classId = Integer.parseInt(idClaseForAjax);
                sql = "SELECT a.id_alumno, a.dni, a.nombre, a.apellido_paterno, a.apellido_materno, a.email "
                    + "FROM alumnos a "
                    + "INNER JOIN inscripciones i ON a.id_alumno = i.id_alumno "
                    + "INNER JOIN clases cl ON i.id_clase = cl.id_clase "
                    + "WHERE cl.id_clase = ? AND cl.id_profesor = ? AND cl.estado = 'activo' AND i.estado = 'inscrito' "
                    + "ORDER BY a.apellido_paterno, a.nombre";
                pstmtAjax = connAjax.prepareStatement(sql);
                pstmtAjax.setInt(1, classId);
                pstmtAjax.setInt(2, idProfesor); // Ensure professor owns this class

            } else { // It's a normal search by 'term'
                if (searchTerm == null || searchTerm.trim().isEmpty() || searchTerm.trim().length() < 3) {
                    jsonResponse.append("[]"); // Return empty JSON for empty/short search term
                    out.print(jsonResponse.toString());
                    return; // Terminate execution here for empty/short search
                }

                sql = "SELECT DISTINCT a.id_alumno, a.dni, a.nombre, a.apellido_paterno, a.apellido_materno, a.email "
                    + "FROM alumnos a "
                    + "INNER JOIN inscripciones i ON a.id_alumno = i.id_alumno "
                    + "INNER JOIN clases cl ON i.id_clase = cl.id_clase "
                    + "WHERE cl.id_profesor = ? AND cl.estado = 'activo' AND i.estado = 'inscrito' AND ( " // Only search within this professor's active students
                    + "    LOWER(CONCAT(a.nombre, ' ', a.apellido_paterno, ' ', IFNULL(a.apellido_materno, ''))) LIKE LOWER(?) OR "
                    + "    a.dni LIKE ? OR "
                    + "    LOWER(a.email) LIKE LOWER(?) "
                    + ") LIMIT 10"; // Limit results for performance

                pstmtAjax = connAjax.prepareStatement(sql);
                String searchPattern = "%" + searchTerm.trim() + "%";
                pstmtAjax.setInt(1, idProfesor); // Bind professor ID
                pstmtAjax.setString(2, searchPattern);
                pstmtAjax.setString(3, searchPattern);
                pstmtAjax.setString(4, searchPattern);
            }

            rsAjax = pstmtAjax.executeQuery();

            jsonResponse.append("[");
            boolean first = true;
            while (rsAjax.next()) {
                if (!first) {
                    jsonResponse.append(",");
                }
                jsonResponse.append("{");

                int idAlumno = rsAjax.getInt("id_alumno");
                String dni = rsAjax.getString("dni");
                String nombre = rsAjax.getString("nombre");
                String apellidoPaterno = rsAjax.getString("apellido_paterno");
                String apellidoMaterno = rsAjax.getString("apellido_materno");
                String email = rsAjax.getString("email");

                String nombreCompleto = nombre + " " + apellidoPaterno;
                if (apellidoMaterno != null && !apellidoMaterno.trim().isEmpty()) {
                    nombreCompleto += " " + apellidoMaterno;
                }

                jsonResponse.append("\"id_alumno\":").append(idAlumno).append(",");
                jsonResponse.append("\"dni\":\"").append(escapeJson(dni)).append("\",");
                jsonResponse.append("\"nombre_completo\":\"").append(escapeJson(nombreCompleto)).append("\",");
                jsonResponse.append("\"email\":\"").append(escapeJson(email)).append("\"");

                jsonResponse.append("}");
                first = false;
            }
            jsonResponse.append("]");

        } catch (SQLException e) {
            System.err.println("Error SQL al obtener alumnos (AJAX): " + e.getMessage());
            jsonResponse.setLength(0); // Clear any partial JSON
            jsonResponse.append("[]"); // Return empty array on error
        } catch (ClassNotFoundException e) {
            System.err.println("Error ClassNotFound al obtener alumnos (AJAX): " + e.getMessage());
            jsonResponse.setLength(0); // Clear any partial JSON
            jsonResponse.append("[]"); // Return empty array on error
        } finally {
            closeDbResources(rsAjax, pstmtAjax);
            if (connAjax != null) { try { connAjax.close(); } catch (SQLException ignore) {} }
        }
        out.print(jsonResponse.toString()); // Output the JSON string
        out.flush();
        return; // IMPORTANT: Terminate execution for AJAX requests here
    }

    // --- If not an AJAX request, proceed with HTML form rendering (POST or initial GET) ---
    String mensajeExito = request.getParameter("exito");
    String mensajeError = request.getParameter("error");

    // --- Logic for sending the message (when form is submitted with POST) ---
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String asunto = request.getParameter("asunto");
        String contenido = request.getParameter("contenido");
        String destinatariosIds = request.getParameter("destinatarios_ids");

        String[] idsArray = destinatariosIds.split(",");
        List<Integer> alumnosAEnviar = new ArrayList<>();

        for (String idStr : idsArray) {
            try {
                if (!idStr.trim().isEmpty()) {
                    alumnosAEnviar.add(Integer.parseInt(idStr.trim()));
                }
            } catch (NumberFormatException nfe) {
                System.err.println("Advertencia: ID de alumno inválido encontrado y omitido: " + idStr);
            }
        }

        // Construct redirect URL, preserving current class context if available
        String redirectURL = request.getContextPath() + "/INTERFAZ_PROFESOR/enviar_mensaje_seccion.jsp?";
        String currentClaseIdParam = request.getParameter("id_clase");
        if (currentClaseIdParam != null && !currentClaseIdParam.isEmpty()) {
             redirectURL += "id_clase=" + URLEncoder.encode(currentClaseIdParam, "UTF-8") + "&";
        }
        String nombreCursoParam = request.getParameter("nombre_curso");
        if (nombreCursoParam != null && !nombreCursoParam.isEmpty()) {
             redirectURL += "nombre_curso=" + URLEncoder.encode(nombreCursoParam, "UTF-8") + "&";
        }
        String seccionParam = request.getParameter("seccion");
        if (seccionParam != null && !seccionParam.isEmpty()) {
             redirectURL += "seccion=" + URLEncoder.encode(seccionParam, "UTF-8") + "&";
        }

        if (alumnosAEnviar.isEmpty()) {
            response.sendRedirect(redirectURL + "error=" + URLEncoder.encode("Debes seleccionar al menos un destinatario válido.", "UTF-8"));
            return;
        }

        Connection connPost = null;
        PreparedStatement pstmtMensaje = null;

        try {
            connPost = new Conection().conecta();
            if (connPost == null || connPost.isClosed()) {
                throw new SQLException("No se pudo establecer conexión a la base de datos.");
            }

            connPost.setAutoCommit(false); // Start transaction

            String sqlInsertMensaje = "INSERT INTO mensajes (id_remitente, tipo_remitente, id_destinatario, tipo_destinatario, asunto, contenido, fecha_envio) VALUES (?, 'profesor', ?, 'alumno', ?, ?, NOW())";
            pstmtMensaje = connPost.prepareStatement(sqlInsertMensaje);

            for (Integer idAlumno : alumnosAEnviar) {
                pstmtMensaje.setInt(1, idProfesor);
                pstmtMensaje.setInt(2, idAlumno);
                pstmtMensaje.setString(3, asunto);
                pstmtMensaje.setString(4, contenido);
                pstmtMensaje.addBatch(); // Add to batch for efficient inserts
            }

            int[] results = pstmtMensaje.executeBatch(); // Execute all inserts
            connPost.commit(); // Commit transaction

            int mensajesEnviadosCount = 0;
            for (int res : results) {
                if (res > 0) { // Check if insert was successful
                    mensajesEnviadosCount++;
                }
            }

            if (mensajesEnviadosCount == alumnosAEnviar.size()) {
                response.sendRedirect(redirectURL + "exito=" + URLEncoder.encode("Mensajes enviados correctamente a " + mensajesEnviadosCount + " destinatario(s).", "UTF-8"));
            } else if (mensajesEnviadosCount > 0) {
                response.sendRedirect(redirectURL + "error=" + URLEncoder.encode("Se enviaron algunos mensajes, pero no a todos los destinatarios (" + mensajesEnviadosCount + "/" + alumnosAEnviar.size() + ").", "UTF-8"));
            } else {
                response.sendRedirect(redirectURL + "error=" + URLEncoder.encode("No se pudo enviar mensajes a ningún destinatario.", "UTF-8"));
            }
            return;

        } catch (SQLException e) {
            if (connPost != null) {
                try {
                    connPost.rollback(); // Rollback on SQL error
                } catch (SQLException rollbackEx) {
                    System.err.println("Error al hacer rollback: " + rollbackEx.getMessage());
                }
            }
            System.err.println("Error de base de datos al enviar mensaje (POST): " + e.getMessage());
            e.printStackTrace();
            response.sendRedirect(redirectURL + "error=" + URLEncoder.encode("Error de base de datos al enviar mensaje: " + e.getMessage(), "UTF-8"));
            return;
        } catch (ClassNotFoundException e) {
            System.err.println("Error: No se encontró el driver JDBC de MySQL (POST): " + e.getMessage());
            e.printStackTrace();
            response.sendRedirect(redirectURL + "error=" + URLEncoder.encode("Error: No se encontró el driver JDBC de MySQL.", "UTF-8"));
            return;
        } finally {
            if (pstmtMensaje != null) { try { pstmtMensaje.close(); } catch (SQLException ignore) {} }
            if (connPost != null) {
                try { connPost.setAutoCommit(true); connPost.close(); } catch (SQLException ignore) {}
            }
        }
    }

    // Parameters for current class if coming from 'mensaje_profesor.jsp'
    String currentClaseId = request.getParameter("id_clase");
    String currentClaseNombre = request.getParameter("nombre_curso");
    String currentClaseSeccion = request.getParameter("seccion");
%>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Enviar Mensajes | Sistema Universitario</title>
    <link rel="icon" type="image/x-icon" href="<%= request.getContextPath() %>/img/favicon.ico">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        /* Your consistent AdminKit-like CSS variables */
        :root {
            --admin-dark: #222B40;
            --admin-light-bg: #F0F2F5;
            --admin-card-bg: #FFFFFF;
            --admin-text-dark: #333333;
            --admin-text-muted: #6C757D;
            --admin-primary: #007BFF;
            --admin-success: #28A745;
            --admin-danger: #DC3545;
            --admin-warning: #FFC107;
            --admin-info: #17A2B8;
            --admin-secondary-color: #6C757D;
        }

        body {
            font-family: 'Inter', sans-serif;
            background-color: var(--admin-light-bg);
            color: var(--admin-text-dark);
            min-height: 100vh;
            margin: 0;
            padding: 0;
            display: flex;
            flex-direction: column;
            overflow-x: hidden;
        }

        #app {
            display: flex;
            flex: 1;
            width: 100%;
        }

        /* Sidebar styles */
        .sidebar {
            width: 280px; background-color: var(--admin-dark); color: rgba(255,255,255,0.8); padding-top: 1rem; flex-shrink: 0;
            position: sticky; top: 0; left: 0; height: 100vh; overflow-y: auto; box-shadow: 2px 0 5px rgba(0,0,0,0.1); z-index: 1030;
        }
        .sidebar-header { padding: 1rem 1.5rem; margin-bottom: 1.5rem; text-align: center; font-size: 1.5rem; font-weight: 700; color: var(--admin-primary); border-bottom: 1px solid rgba(255,255,255,0.05);}
        .sidebar .nav-link { display: flex; align-items: center; padding: 0.75rem 1.5rem; color: rgba(255,255,255,0.7); text-decoration: none; transition: all 0.2s ease-in-out; font-weight: 500;}
        .sidebar .nav-link i { margin-right: 0.75rem; font-size: 1.1rem;}
        .sidebar .nav-link:hover, .sidebar .nav-link.active { color: white; background-color: rgba(255,255,255,0.08); border-left: 4px solid var(--admin-primary); padding-left: 1.3rem;}

        /* Main Content area */
        .main-content {
            flex: 1;
            padding: 1.5rem;
            overflow-y: auto;
            display: flex;
            flex-direction: column;
        }

        /* Top Navbar styles */
        .top-navbar {
            background-color: var(--admin-card-bg); padding: 1rem 1.5rem; box-shadow: 0 0.125rem 0.25rem rgba(0,0,0,0.075);
            margin-bottom: 1.5rem; border-radius: 0.5rem; display: flex; justify-content: space-between; align-items: center;
        }
        .top-navbar .search-bar .form-control { border: 1px solid #e0e0e0; border-radius: 0.3rem; padding: 0.5rem 1rem; }
        .top-navbar .user-dropdown .dropdown-toggle { display: flex; align-items: center; color: var(--admin-text-dark); text-decoration: none; }
        .top-navbar .user-dropdown .dropdown-toggle img { width: 32px; height: 32px; border-radius: 50%; margin-right: 0.5rem; object-fit: cover; border: 2px solid var(--admin-primary); }

        /* Welcome section */
        .welcome-section {
            background-color: var(--admin-card-bg); border-radius: 0.5rem; padding: 1.5rem; margin-bottom: 1.5rem; box-shadow: 0 0.125rem 0.25rem rgba(0,0,0,0.075);
        }
        .welcome-section h1 { color: var(--admin-text-dark); font-weight: 600; margin-bottom: 0.5rem;}
        .welcome-section p.lead { color: var(--admin-text-muted); font-size: 1rem;}

        /* Content section for the form */
        .content-section {
            background-color: var(--admin-card-bg); border-radius: 0.5rem; box-shadow: 0 0.125rem 0.25rem rgba(0,0,0,0.075);
            border-left: 4px solid var(--admin-primary); padding: 2rem 1.5rem; margin-bottom: 2rem;
        }
        .section-title { color: var(--admin-primary); margin-bottom: 1.5rem; font-weight: 600;} /* Increased margin-bottom */

        /* Info Box */
        .info-box {
            background-color: var(--admin-info); /* Use a more prominent info color */
            color: white; /* White text for contrast */
            padding: 1.5rem; /* Increased padding */
            margin-bottom: 1.5rem;
            border-radius: 0.5rem; /* Rounded corners */
            display: flex;
            align-items: center;
            gap: 1rem;
            box-shadow: 0 0.125rem 0.25rem rgba(0,0,0,0.075);
        }
        .info-box i {
            font-size: 2rem; /* Larger icon */
        }
        .info-box h4 {
            color: white; /* White text */
            margin-bottom: 0.5rem;
            font-weight: 600;
        }
        .info-box p {
            font-size: 0.95rem;
            margin-bottom: 0;
        }

        /* Alerts (Bootstrap standard) */
        .alert {
            padding: 1rem 1.5rem; /* Standard Bootstrap padding */
            margin-bottom: 1.5rem;
            border-radius: 0.375rem; /* Standard Bootstrap border-radius */
        }
        .alert-success { background-color: var(--admin-success); color: white; border-color: var(--admin-success); }
        .alert-danger { background-color: var(--admin-danger); color: white; border-color: var(--admin-danger); }

        /* Form Group and Controls */
        .form-label {
            font-weight: 600;
            color: var(--admin-text-dark);
            margin-bottom: 0.5rem;
        }
        .form-control, .form-select {
            border-radius: 0.3rem;
            border-color: #dee2e6;
            padding: 0.75rem 1rem;
        }
        .form-control:focus, .form-select:focus {
            border-color: var(--admin-primary);
            box-shadow: 0 0 0 0.25rem rgba(0, 123, 255, 0.25);
        }
        textarea.form-control {
            min-height: 150px;
            resize: vertical;
        }

        /* Search input and results list */
        .search-input-container {
            position: relative;
            margin-bottom: 1rem;
        }
        .search-results-list {
            list-style-type: none;
            padding: 0;
            margin: 0;
            border: 1px solid #ddd;
            border-top: none;
            max-height: 200px;
            overflow-y: auto;
            background-color: var(--admin-card-bg);
            position: absolute;
            width: 100%;
            z-index: 1000;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
            border-radius: 0 0 0.3rem 0.3rem;
        }
        .search-results-list li {
            padding: 0.8rem;
            border-bottom: 1px solid #eee;
            cursor: pointer;
            display: flex;
            align-items: center;
            gap: 0.5rem;
            color: var(--admin-text-dark);
        }
        .search-results-list li:hover {
            background-color: var(--admin-light-bg); /* Lighter hover color */
        }
        .search-results-list li:last-child { border-bottom: none; }
        .search-results-list li .text-muted { font-size: 0.85rem; }

        /* Selected recipients list */
        .selected-recipients {
            list-style-type: none;
            padding: 0.75rem; /* Padding inside the box */
            margin-top: 0.5rem;
            border: 1px solid var(--admin-info); /* Blue border */
            background-color: rgba(23, 162, 184, 0.1); /* Light blue background */
            border-radius: 0.5rem;
            max-height: 180px;
            overflow-y: auto;
        }
        .selected-recipients li {
            background-color: var(--admin-info); /* Solid blue for tags */
            color: white;
            padding: 0.5rem 0.75rem;
            margin-bottom: 0.5rem;
            border-radius: 0.3rem;
            display: flex;
            justify-content: space-between;
            align-items: center;
            font-size: 0.9em;
            word-break: break-word; /* Prevent overflow on long names */
        }
        .selected-recipients li:last-child { margin-bottom: 0; }
        .selected-recipients li .remove-recipient {
            background: none;
            border: none;
            color: white; /* White 'x' */
            cursor: pointer;
            font-size: 1.2em;
            margin-left: 10px;
            transition: color 0.2s;
            opacity: 0.8;
        }
        .selected-recipients li .remove-recipient:hover {
            color: var(--admin-warning); /* Yellow on hover */
            opacity: 1;
        }
        .recipient-count {
            font-size: 0.9em;
            color: var(--admin-text-muted);
            text-align: right;
            margin-top: 0.5rem;
        }
        
        /* Select All / Clear Buttons */
        .select-all-buttons {
            margin-top: 1.5rem;
            margin-bottom: 1.5rem; /* Added margin-bottom */
            display: flex;
            gap: 1rem; /* Spacing between buttons */
            flex-wrap: wrap;
        }
        .select-all-buttons .btn {
            background-color: var(--admin-info); /* Info blue */
            color: white;
            padding: 0.6rem 1.2rem; /* Adjusted padding */
            border: none;
            border-radius: 0.3rem; /* Standard Bootstrap radius */
            cursor: pointer;
            font-size: 0.95rem; /* Slightly larger text */
            transition: background-color 0.3s ease, transform 0.2s ease;
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
        }
        .select-all-buttons .btn:hover {
            background-color: #138496; /* Darker info blue */
            transform: translateY(-2px);
        }
        .select-all-buttons #clearRecipientsBtn {
            background-color: var(--admin-danger); /* Red for clear */
        }
        .select-all-buttons #clearRecipientsBtn:hover {
            background-color: #c82333; /* Darker red */
        }

        /* Form Actions */
        .form-actions {
            text-align: right;
            margin-top: 2rem;
        }
        .form-actions .btn-primary {
            background-color: var(--admin-primary);
            color: white;
            padding: 0.8rem 2rem;
            border: none;
            border-radius: 0.3rem;
            cursor: pointer;
            font-size: 1.1rem;
            font-weight: 600;
            transition: background-color 0.3s ease, transform 0.2s ease;
        }
        .form-actions .btn-primary:hover {
            background-color: #0056b3;
            transform: translateY(-2px);
        }

        /* Back Button */
        .back-button {
            display: inline-flex; /* Use flexbox for icon and text */
            align-items: center;
            background-color: var(--admin-secondary-color);
            color: white;
            padding: 0.75rem 1.5rem;
            border: none;
            border-radius: 0.3rem;
            text-decoration: none;
            font-size: 1rem;
            margin-top: 2rem;
            transition: background-color 0.3s ease, transform 0.2s ease;
        }
        .back-button:hover {
            background-color: #5a6268;
            color: white; /* Ensure text remains white on hover */
            transform: translateY(-2px);
        }
        .back-button i {
            margin-right: 0.5rem;
        }

        /* Responsive adjustments */
        @media (max-width: 992px) {
            .sidebar { width: 220px; }
            .main-content { padding: 1rem; }
        }

        @media (max-width: 768px) {
            #app { flex-direction: column; }
            .sidebar {
                width: 100%; height: auto; position: relative;
                box-shadow: 0 2px 5px rgba(0,0,0,0.1); padding-bottom: 0.5rem;
            }
            .sidebar .nav-link { justify-content: center; padding: 0.6rem 1rem;}
            .sidebar .nav-link i { margin-right: 0.5rem;}
            .top-navbar { flex-direction: column; align-items: flex-start;}
            .top-navbar .search-bar { width: 100%; margin-bottom: 1rem;}
            .top-navbar .user-dropdown { width: 100%; text-align: center;}
            .top-navbar .user-dropdown .dropdown-toggle { justify-content: center;}

            .content-section { padding: 1.5rem 1rem; } /* Adjust content padding */
            .info-box { flex-direction: column; text-align: center; gap: 0.5rem; }
            .info-box i { margin-bottom: 0.5rem; }
        }

        @media (max-width: 576px) {
            .main-content { padding: 0.75rem; }
            .welcome-section, .content-section, .info-box { padding: 1rem;}
            /* Adjust input and textarea padding if necessary for very small screens */
            .form-control, .form-select { padding: 0.6rem 0.8rem; font-size: 0.9rem; }
            .select-all-buttons .btn { flex-grow: 1; text-align: center; } /* Make buttons stretch on very small screens */
        }
    </style>
</head>
<body>
    <div id="app">
        <nav class="sidebar">
            <div class="sidebar-header">
                <a href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/home_profesor.jsp" class="text-white text-decoration-none">UGIC Portal</a>
            </div>
            <ul class="navbar-nav">
                <li class="nav-item"><a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/home_profesor.jsp"><i class="fas fa-chart-line"></i><span> Dashboard</span></a></li>
                <li class="nav-item"><a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/facultad_profesor.jsp"><i class="fas fa-building"></i><span> Facultades</span></a></li>
                <li class="nav-item"><a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/carreras_profesor.jsp"><i class="fas fa-graduation-cap"></i><span> Carreras</span></a></li>
                <li class="nav-item"><a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/cursos_profesor.jsp"><i class="fas fa-book"></i><span> Cursos</span></a></li>
                <li class="nav-item"><a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/salones_profesor.jsp"><i class="fas fa-chalkboard"></i><span> Clases</span></a></li>
                <li class="nav-item"><a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/horarios_profesor.jsp"><i class="fas fa-calendar-alt"></i><span> Horarios</span></a></li>
                <li class="nav-item"><a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/asistencia_profesor.jsp"><i class="fas fa-clipboard-check"></i><span> Asistencia</span></a></li>
                <li class="nav-item"><a class="nav-link active" href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/mensaje_profesor.jsp"><i class="fas fa-envelope"></i><span> Mensajería</span></a></li>
                <li class="nav-item"><a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/nota_profesor.jsp"><i class="fas fa-percent"></i><span> Notas</span></a></li>
                <li class="nav-item mt-3">
                    <form action="<%= request.getContextPath() %>/logout.jsp" method="post" class="d-grid gap-2">
                        <button type="submit" class="btn btn-outline-light mx-3"><i class="fas fa-sign-out-alt me-2"></i>Cerrar sesión</button>
                    </form>
                </li>
            </ul>
        </nav>

        <div class="main-content">
            <nav class="top-navbar">
                <div class="search-bar">
                    <form class="d-flex">
                    </form>
                </div>
                <div class="d-flex align-items-center">
                    <div class="me-3 dropdown">
                        
                    </div>
                    <div class="me-3 dropdown">
                        <a class="text-dark" href="#" role="button" id="messagesDropdown" data-bs-toggle="dropdown" aria-expanded="false">
                            <i class="fas fa-envelope fa-lg"></i>
                            <span class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger">
                            </span>
                        </a>
                        <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="messagesDropdown">
                            <li><a class="dropdown-item" href="mensajeria_profesor.jsp">Ver todos</a></li>
                        </ul>
                    </div>

                    <div class="dropdown user-dropdown">
                        <a class="dropdown-toggle" href="#" role="button" id="userDropdown" data-bs-toggle="dropdown" aria-expanded="false">
                            <img src="https://via.placeholder.com/32" alt="Avatar"> <span class="d-none d-md-inline-block"><%= nombreProfesor%></span>
                        </a>
                        <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="userDropdown">
                            <li><a class="dropdown-item" href="perfil_profesor.jsp"><i class="fas fa-user me-2"></i>Perfil</a></li>
                            <li><a class="dropdown-item" href="configuracion_profesor.jsp"><i class="fas fa-cog me-2"></i>Configuración</a></li>
                            <li><hr class="dropdown-divider"></li>
                            <li><a class="dropdown-item" href="logout.jsp"><i class="fas fa-sign-out-alt me-2"></i>Cerrar sesión</a></li>
                        </ul>
                    </div>
                </div>
            </nav>

            <div class="container-fluid">
                <div class="welcome-section">
                    <h1 class="h3 mb-3"><i class="fas fa-paper-plane me-2"></i>Componer Mensaje</h1>
                    <p class="lead">Envía comunicaciones importantes a tus estudiantes.</p>
                </div>

                <% if (mensajeExito != null) { %>
                    <div class="alert alert-success alert-dismissible fade show" role="alert">
                        <i class="fas fa-check-circle me-2"></i><%= mensajeExito %>
                        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                    </div>
                <% } %>
                <% if (mensajeError != null) { %>
                    <div class="alert alert-danger alert-dismissible fade show" role="alert">
                        <i class="fas fa-exclamation-triangle me-2"></i><%= mensajeError %>
                        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                    </div>
                <% } %>

                <div class="info-box">
                    <i class="fas fa-info-circle"></i>
                    <div>
                        <h4>Información de la Clase</h4>
                        <p class="mb-0">
                            <% if (currentClaseNombre != null && !currentClaseNombre.isEmpty()) { %>
                                Estás enviando un mensaje específico para la clase: **<%= currentClaseNombre %> - Sección: <%= currentClaseSeccion %>**.
                                Puedes buscar y añadir otros alumnos si lo necesitas, o usar el botón "Seleccionar Alumnos de MI Clase Actual" para agregar a todos los de esta sección.
                            <% } else { %>
                                No has seleccionado una clase específica. Puedes buscar alumnos individualmente o usar "Seleccionar Alumnos de MIS Clases" para incluir a todos tus alumnos activos.
                            <% } %>
                        </p>
                    </div>
                </div>

                <div class="content-section">
                    <h2 class="section-title"><i class="fas fa-edit me-2"></i>Componer Nuevo Mensaje</h2>

                    <form id="mensajeForm" action="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/enviar_mensaje_seccion.jsp" method="post">
                        <%-- Hidden fields to pass class context if applicable --%>
                        <% if (currentClaseId != null && !currentClaseId.isEmpty()) { %>
                            <input type="hidden" name="id_clase" value="<%= currentClaseId %>">
                            <input type="hidden" name="nombre_curso" value="<%= currentClaseNombre %>">
                            <input type="hidden" name="seccion" value="<%= currentClaseSeccion %>">
                        <% } %>

                        <div class="mb-3">
                            <label for="alumnoSearchInput" class="form-label">Buscar Alumnos (Nombre, DNI o Correo):</label>
                            <div class="input-group search-input-container">
                                <span class="input-group-text"><i class="fas fa-search"></i></span>
                                <input type="text" class="form-control" id="alumnoSearchInput" placeholder="Escribe al menos 3 letras para buscar...">
                            </div>
                            <ul id="alumnoSearchResults" class="search-results-list" style="display:none;"></ul>
                        </div>

                        <div class="select-all-buttons">
                            <% if (currentClaseId != null && !currentClaseId.isEmpty()) { %>
                                <button type="button" class="btn btn-info" id="selectAllStudentsInCurrentClassBtn">
                                    <i class="fas fa-users-class"></i> Seleccionar Alumnos de MI Clase Actual (<%= currentClaseSeccion %>)
                                </button>
                            <% } %>
                            <button type="button" class="btn btn-info" id="selectAllStudentsInMyClassesBtn">
                                <i class="fas fa-users"></i> Seleccionar Alumnos de TODAS MIS Clases
                            </button>
                            <button type="button" class="btn btn-danger" id="clearRecipientsBtn">
                                <i class="fas fa-times-circle"></i> Limpiar Destinatarios
                            </button>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Destinatarios Seleccionados:</label>
                            <ul id="selectedRecipientsList" class="selected-recipients"></ul>
                            <div class="recipient-count" id="recipientCount">0 destinatario(s)</div>
                            <input type="hidden" name="destinatarios_ids" id="destinatariosIds" value="">
                        </div>

                        <div class="mb-3">
                            <label for="asunto" class="form-label">Asunto:</label>
                            <input type="text" class="form-control" id="asunto" name="asunto" required maxlength="200" placeholder="Ej: Recordatorio, Información Importante">
                        </div>

                        <div class="mb-3">
                            <label for="contenido" class="form-label">Contenido del Mensaje:</label>
                            <textarea class="form-control" id="contenido" name="contenido" rows="8" required placeholder="Escribe aquí tu mensaje..."></textarea>
                        </div>

                        <div class="form-actions">
                            <button type="submit" class="btn btn-primary" id="enviarBtn"><i class="fas fa-paper-plane me-2"></i> Enviar Mensaje</button>
                        </div>
                    </form>
                </div>

                <a href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/mensaje_profesor.jsp" class="back-button">
                    <i class="fas fa-arrow-left"></i> Volver al Panel Principal de Mensajería
                </a>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js" integrity="sha384-YvpcrYf0tY3lHB60NNkmXc5s9fDVZLESaAA55NDzOxhy9GkcIdslK1eN7N6jIeHz" crossorigin="anonymous"></script>
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            const alumnoSearchInput = document.getElementById('alumnoSearchInput');
            const alumnoSearchResults = document.getElementById('alumnoSearchResults');
            const selectedRecipientsList = document.getElementById('selectedRecipientsList');
            const destinatariosIdsHidden = document.getElementById('destinatariosIds');
            const recipientCountSpan = document.getElementById('recipientCount');
            const selectAllStudentsInMyClassesBtn = document.getElementById('selectAllStudentsInMyClassesBtn');
            const clearRecipientsBtn = document.getElementById('clearRecipientsBtn');
            const mensajeForm = document.getElementById('mensajeForm');

            const selectAllStudentsInCurrentClassBtn = document.getElementById('selectAllStudentsInCurrentClassBtn');
            const currentClaseId = '<%= currentClaseId %>';

            let selectedAlumnos = new Map(); // Map to store {id_alumno: {nombre, dni, email}}

            function updateRecipientCount() {
                recipientCountSpan.textContent = `${selectedAlumnos.size} destinatario(s)`;
                destinatariosIdsHidden.value = Array.from(selectedAlumnos.keys()).join(',');
            }

            function addRecipient(alumno) {
                if (!selectedAlumnos.has(alumno.id_alumno)) {
                    selectedAlumnos.set(alumno.id_alumno, alumno);

                    const listItem = document.createElement('li');
                    listItem.dataset.id = alumno.id_alumno;
                    
                    const displayDni = (alumno.dni && String(alumno.dni).trim() !== '') ? alumno.dni : 'N/A';
                    const displayEmail = (alumno.email && String(alumno.email).trim() !== '') ? alumno.email : 'N/A';
                    const displayNombreCompleto = (alumno.nombre_completo && String(alumno.nombre_completo).trim() !== '') ? alumno.nombre_completo : 'N/A';

                    listItem.innerHTML = `
                        <span><i class="fas fa-user-graduate me-2"></i> ${displayNombreCompleto} (DNI: ${displayDni}, Email: ${displayEmail})</span>
                        <button type="button" class="remove-recipient" data-id="${alumno.id_alumno}">&times;</button>
                    `;
                    selectedRecipientsList.appendChild(listItem);

                    listItem.querySelector('.remove-recipient').addEventListener('click', function() {
                        removeRecipient(parseInt(this.dataset.id));
                    });

                    updateRecipientCount();
                }
                alumnoSearchInput.value = ''; // Limpiar el input de búsqueda
                alumnoSearchResults.style.display = 'none'; // Ocultar resultados
            }

            function removeRecipient(idAlumno) {
                selectedAlumnos.delete(idAlumno);
                const listItem = selectedRecipientsList.querySelector(`li[data-id="${idAlumno}"]`);
                if (listItem) {
                    listItem.remove();
                }
                updateRecipientCount();
            }

            // --- Student Search Logic (AJAX to same JSP) ---
            let currentSearchTimeout = null;
            alumnoSearchInput.addEventListener('keyup', function() {
                clearTimeout(currentSearchTimeout);
                const searchTerm = this.value.trim();

                if (searchTerm.length < 3) { // Require at least 3 characters for search
                    alumnoSearchResults.innerHTML = '';
                    alumnoSearchResults.style.display = 'none';
                    return;
                }

                currentSearchTimeout = setTimeout(function() {
                    // AJAX request to the same JSP, with 'term' parameter
                    fetch('<%= request.getContextPath() %>/INTERFAZ_PROFESOR/enviar_mensaje_seccion.jsp?term=' + encodeURIComponent(searchTerm))
                        .then(response => {
                            if (!response.ok) {
                                throw new Error('Error de red o servidor: ' + response.status + ' ' + response.statusText);
                            }
                            return response.json(); // Parse the JSON response
                        })
                        .then(data => {
                            alumnoSearchResults.innerHTML = ''; // Clear previous results
                            if (data.length > 0) {
                                data.forEach(alumno => {
                                    const listItem = document.createElement('li');
                                    const displayDni = (alumno.dni && String(alumno.dni).trim() !== '') ? alumno.dni : 'N/A';
                                    const displayEmail = (alumno.email && String(alumno.email).trim() !== '') ? alumno.email : 'N/A';
                                    const displayNombreCompleto = (alumno.nombre_completo && String(alumno.nombre_completo).trim() !== '') ? alumno.nombre_completo : 'N/A';

                                    listItem.innerHTML = `<i class="fas fa-user-graduate"></i> ${displayNombreCompleto} <span class="text-muted">(DNI: ${displayDni})</span>`;
                                    // Store full alumno data in dataset for easy retrieval
                                    listItem.dataset.id = alumno.id_alumno;
                                    listItem.dataset.nombre_completo = alumno.nombre_completo;
                                    listItem.dataset.dni = alumno.dni;
                                    listItem.dataset.email = alumno.email;
                                    
                                    listItem.addEventListener('click', function() {
                                        addRecipient({ // Pass the full object to addRecipient
                                            id_alumno: parseInt(this.dataset.id),
                                            nombre_completo: this.dataset.nombre_completo,
                                            dni: this.dataset.dni,
                                            email: this.dataset.email
                                        });
                                    });
                                    alumnoSearchResults.appendChild(listItem);
                                });
                                alumnoSearchResults.style.display = 'block';
                            } else {
                                const listItem = document.createElement('li');
                                listItem.textContent = 'No se encontraron alumnos.';
                                listItem.style.fontStyle = 'italic';
                                listItem.style.color = 'var(--admin-text-muted)';
                                alumnoSearchResults.appendChild(listItem);
                                alumnoSearchResults.style.display = 'block';
                            }
                        })
                        .catch(error => {
                            console.error('Error al obtener datos de alumnos para el buscador:', error);
                            alumnoSearchResults.innerHTML = '<li><i class="fas fa-exclamation-triangle text-danger me-2"></i>Error al cargar resultados. Por favor, intente de nuevo.</li>';
                            alumnoSearchResults.style.display = 'block';
                        });
                }, 300); // Debounce delay
            });

            // Hide search results when clicking outside
            document.addEventListener('click', function(event) {
                if (!alumnoSearchInput.contains(event.target) && !alumnoSearchResults.contains(event.target)) {
                    alumnoSearchResults.style.display = 'none';
                }
            });

            // --- Button to select all students from professor's active classes ---
            selectAllStudentsInMyClassesBtn.addEventListener('click', function() {
                if (confirm('¿Estás seguro de que quieres seleccionar a TODOS los alumnos de tus clases activas? Esto sobrescribirá la lista actual de destinatarios.')) {
                    selectedAlumnos.clear();
                    selectedRecipientsList.innerHTML = ''; // Clear visible list

                    fetch('<%= request.getContextPath() %>/INTERFAZ_PROFESOR/enviar_mensaje_seccion.jsp?requestType=getAllStudentsByProfessor')
                        .then(response => {
                            if (!response.ok) {
                                throw new Error('Network response was not ok ' + response.statusText);
                            }
                            return response.json();
                        })
                        .then(data => {
                            if (data.length > 0) {
                                data.forEach(alumno => {
                                    addRecipient(alumno); // Reuse addRecipient function
                                });
                                alert(`Se han añadido ${data.length} alumnos de tus clases.`);
                            } else {
                                alert('No se encontraron alumnos en tus clases activas.');
                            }
                        })
                        .catch(error => {
                            console.error('Error al seleccionar todos los alumnos del profesor:', error);
                            alert('Hubo un error al intentar seleccionar todos los alumnos. Verifique la consola para más detalles.');
                        });
                }
            });

            // Optional: Button to select all students from the CURRENT class
            if (selectAllStudentsInCurrentClassBtn) {
                selectAllStudentsInCurrentClassBtn.addEventListener('click', function() {
                    if (confirm('¿Estás seguro de que quieres seleccionar a TODOS los alumnos de esta clase? Esto sobrescribirá la lista actual de destinatarios.')) {
                        selectedAlumnos.clear();
                        selectedRecipientsList.innerHTML = ''; // Clear visible list

                        // Fetch students only for the current class
                        fetch('<%= request.getContextPath() %>/INTERFAZ_PROFESOR/enviar_mensaje_seccion.jsp?requestType=getAllStudentsByClass&id_clase=' + encodeURIComponent(currentClaseId))
                            .then(response => {
                                if (!response.ok) {
                                    throw new Error('Network response was not ok ' + response.statusText);
                                }
                                return response.json();
                            })
                            .then(data => {
                                if (data.length > 0) {
                                    data.forEach(alumno => {
                                        addRecipient(alumno); // Reuse addRecipient function
                                    });
                                    alert(`Se han añadido ${data.length} alumnos de la clase actual.`);
                                } else {
                                    alert('No se encontraron alumnos en la clase actual.');
                                }
                            })
                            .catch(error => {
                                console.error('Error al seleccionar todos los alumnos de la clase actual:', error);
                                alert('Hubo un error al intentar seleccionar todos los alumnos de la clase actual. Verifique la consola para más detalles.');
                            });
                    }
                });
            }

            // Button to clear all recipients
            clearRecipientsBtn.addEventListener('click', function() {
                if (confirm('¿Estás seguro de que quieres limpiar todos los destinatarios seleccionados?')) {
                    selectedAlumnos.clear();
                    selectedRecipientsList.innerHTML = '';
                    updateRecipientCount();
                }
            });

            // Form validation on submit
            mensajeForm.addEventListener('submit', function(event) {
                if (selectedAlumnos.size === 0) {
                    alert("Debes seleccionar al menos un destinatario para enviar el mensaje.");
                    event.preventDefault(); // Prevent form submission
                }
                // If there are recipients, the hidden input 'destinatarios_ids' is already updated by updateRecipientCount()
            });

            // Initial recipient count on page load
            updateRecipientCount();

            // Auto-populate students from the current class if the ID is present in the URL
            // This is triggered only once when the page loads, if the class ID is provided.
            <% if (currentClaseId != null && !currentClaseId.isEmpty()) { %>
                 // Fetch students specifically for the current class on page load
                 fetch('<%= request.getContextPath() %>/INTERFAZ_PROFESOR/enviar_mensaje_seccion.jsp?requestType=getAllStudentsByClass&id_clase=' + encodeURIComponent(currentClaseId))
                    .then(response => {
                        if (!response.ok) {
                            throw new Error('Error al cargar alumnos de la clase actual: ' + response.statusText);
                        }
                        return response.json();
                    })
                    .then(data => {
                        if (data.length > 0) {
                            data.forEach(alumno => addRecipient(alumno));
                            // Optional alert: alert('Alumnos de la clase actual pre-seleccionados.');
                        } else {
                            // Optional alert: alert('No se encontraron alumnos en la clase actual para pre-seleccionar.');
                        }
                    })
                    .catch(error => console.error('Error auto-loading current class students:', error));
            <% } %>
        });
    </script>
</body>
</html>