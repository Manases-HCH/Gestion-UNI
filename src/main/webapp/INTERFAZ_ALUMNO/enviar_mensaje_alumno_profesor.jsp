<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, pe.universidad.util.Conection" %>
<%@ page import="java.net.URLEncoder" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.nio.charset.StandardCharsets" %>
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
                default:
                    if (ch < 32 || ch > 126) { // Characters outside printable ASCII range
                        String hex = Integer.toHexString(ch);
                        sb.append("\\u");
                        for (int k = 0; k < 4 - hex.length(); k++) {
                            sb.append('0');
                        }
                        sb.append(hex.toUpperCase());
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
    Object idAlumnoObj = session.getAttribute("id_alumno"); // Changed from idApoderadoObj

    int idAlumno = -1; // Changed from idApoderado
    try {
        if (idAlumnoObj != null) {
            idAlumno = Integer.parseInt(String.valueOf(idAlumnoObj));
        }
    } catch (NumberFormatException e) {
        System.err.println("ERROR: ID de alumno en sesión no es un número válido. Redirigiendo a login. " + e.getMessage()); // Changed log
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    if (emailSesion == null || !"alumno".equalsIgnoreCase(rolUsuario) || idAlumno == -1) { // Changed rol check and ID
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    String nombreAlumno = (String) session.getAttribute("nombre_alumno"); // Changed from nombreApoderado
    if (nombreAlumno == null || nombreAlumno.isEmpty()) {
        // Fetch alumno name if not in session
        Connection connTemp = null;
        PreparedStatement pstmtTemp = null;
        ResultSet rsTemp = null;
        try {
            connTemp = new Conection().conecta();
            String sqlGetNombre = "SELECT CONCAT(nombre, ' ', apellido_paterno, ' ', IFNULL(apellido_materno, '')) AS nombre_completo FROM alumnos WHERE id_alumno = ?"; // Changed table
            pstmtTemp = connTemp.prepareStatement(sqlGetNombre);
            pstmtTemp.setInt(1, idAlumno);
            rsTemp = pstmtTemp.executeQuery();
            if (rsTemp.next()) {
                nombreAlumno = rsTemp.getString("nombre_completo");
                session.setAttribute("nombre_alumno", nombreAlumno); // Save to session
            }
        } catch (SQLException | ClassNotFoundException ex) {
            System.err.println("ERROR: Al obtener nombre del alumno en enviar_mensaje_alumno_profesor.jsp: " + ex.getMessage()); // Changed log
        } finally {
            closeDbResources(rsTemp, pstmtTemp);
            if (connTemp != null) { try { connTemp.close(); } catch (SQLException ignore) {} }
        }
    }

    // --- AJAX Request Handling ---
    String searchTerm = request.getParameter("term");
    String requestType = request.getParameter("requestType");

    if (searchTerm != null || "getAllTeachersOfMyCourses".equals(requestType)) { // Changed requestType name
        response.setContentType("application/json;charset=UTF-8");
        StringBuilder jsonResponse = new StringBuilder();
        Connection connAjax = null;
        PreparedStatement pstmtAjax = null;
        ResultSet rsAjax = null;

        try {
            connAjax = new Conection().conecta();
            if (connAjax == null || connAjax.isClosed()) {
                throw new SQLException("No se pudo establecer conexión a la base de datos para AJAX.");
            }

            String sql;
            if ("getAllTeachersOfMyCourses".equals(requestType)) { // Changed requestType name
                sql = "SELECT DISTINCT p.id_profesor, p.dni, p.nombre, p.apellido_paterno, p.apellido_materno, p.email " +
                      "FROM profesores p " +
                      "INNER JOIN clases cl ON p.id_profesor = cl.id_profesor " +
                      "INNER JOIN inscripciones i ON cl.id_clase = i.id_clase " +
                      "WHERE i.id_alumno = ? AND cl.estado = 'activo' AND i.estado = 'inscrito' AND p.estado = 'activo' " +
                      "ORDER BY p.apellido_paterno, p.nombre";
                pstmtAjax = connAjax.prepareStatement(sql);
                pstmtAjax.setInt(1, idAlumno); // Filter by id_alumno
            } else { // It's a normal search by 'term'
                if (searchTerm == null || searchTerm.trim().isEmpty() || searchTerm.trim().length() < 3) {
                    jsonResponse.append("[]");
                    out.print(jsonResponse.toString());
                    return;
                }

                sql = "SELECT DISTINCT p.id_profesor, p.dni, p.nombre, p.apellido_paterno, p.apellido_materno, p.email " +
                      "FROM profesores p " +
                      "INNER JOIN clases cl ON p.id_profesor = cl.id_profesor " +
                      "INNER JOIN inscripciones i ON cl.id_clase = i.id_clase " +
                      "WHERE i.id_alumno = ? AND cl.estado = 'activo' AND i.estado = 'inscrito' AND p.estado = 'activo' AND ( " +
                      "    LOWER(CONCAT(p.nombre, ' ', p.apellido_paterno, ' ', IFNULL(p.apellido_materno, ''))) LIKE LOWER(?) OR " +
                      "    p.dni LIKE ? OR " +
                      "    LOWER(p.email) LIKE LOWER(?) " +
                      ") LIMIT 10";

                pstmtAjax = connAjax.prepareStatement(sql);
                String searchPattern = "%" + searchTerm.trim() + "%";
                pstmtAjax.setInt(1, idAlumno); // Filter by id_alumno
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

                int idProfesorResult = rsAjax.getInt("id_profesor");
                String dni = rsAjax.getString("dni");
                String nombre = rsAjax.getString("nombre");
                String apellidoPaterno = rsAjax.getString("apellido_paterno");
                String apellidoMaterno = rsAjax.getString("apellido_materno");
                String email = rsAjax.getString("email");

                String nombreCompleto = nombre + " " + apellidoPaterno;
                if (apellidoMaterno != null && !apellidoMaterno.trim().isEmpty()) {
                    nombreCompleto += " " + apellidoMaterno;
                }

                jsonResponse.append("\"id_profesor\":").append(idProfesorResult).append(",");
                jsonResponse.append("\"dni\":\"").append(escapeJson(dni)).append("\",");
                jsonResponse.append("\"nombre_completo\":\"").append(escapeJson(nombreCompleto)).append("\",");
                jsonResponse.append("\"email\":\"").append(escapeJson(email)).append("\"");

                jsonResponse.append("}");
                first = false;
            }
            jsonResponse.append("]");

        } catch (SQLException e) {
            System.err.println("ERROR SQL al obtener profesores (AJAX): " + e.getMessage());
            jsonResponse.setLength(0);
            jsonResponse.append("[]");
        } catch (ClassNotFoundException e) {
            System.err.println("ERROR ClassNotFound al obtener profesores (AJAX): " + e.getMessage());
            jsonResponse.setLength(0);
            jsonResponse.append("[]");
        } finally {
            closeDbResources(rsAjax, pstmtAjax);
            if (connAjax != null) { try { connAjax.close(); } catch (SQLException ignore) {} }
        }
        out.print(jsonResponse.toString());
        out.flush();
        return; // IMPORTANT: Terminate execution for AJAX requests here
    }

    // --- If not an AJAX request, proceed with HTML form rendering (POST or initial GET) ---
    String mensajeDisplay = request.getParameter("message");
    String messageType = request.getParameter("type");

    String preselectedProfesorId = request.getParameter("id_profesor");
    String preselectedProfesorNombre = request.getParameter("nombre_profesor");
    String preselectedProfesorEmail = request.getParameter("email_profesor");

    // --- Logic for sending the message (when form is submitted with POST) ---
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String asunto = request.getParameter("asunto");
        String contenido = request.getParameter("contenido");
        String destinatariosIds = request.getParameter("destinatarios_ids");

        System.out.println("DEBUG (POST Request Received):");
        System.out.println("  Asunto: " + asunto);
        System.out.println("  Contenido: " + contenido);
        System.out.println("  Destinatarios IDs (raw from hidden input): '" + destinatariosIds + "'");

        String[] idsArray = destinatariosIds != null && !destinatariosIds.trim().isEmpty() ? destinatariosIds.split(",") : new String[0];
        List<Integer> profesoresAEnviar = new ArrayList<>();

        for (String idStr : idsArray) {
            try {
                if (!idStr.trim().isEmpty()) {
                    profesoresAEnviar.add(Integer.parseInt(idStr.trim()));
                }
            } catch (NumberFormatException nfe) {
                System.err.println("Advertencia: ID de profesor inválido encontrado y omitido: '" + idStr + "'");
            }
        }
        System.out.println("DEBUG (POST): IDs de profesores a enviar (procesados): " + profesoresAEnviar);

        String redirectURL = request.getContextPath() + "/INTERFAZ_ALUMNO/mensajes_alumno.jsp"; // Changed redirect path

        // Server-side validation
        if (profesoresAEnviar.isEmpty()) {
            response.sendRedirect(redirectURL + "?message=" + URLEncoder.encode("Debes seleccionar al menos un profesor destinatario válido.", StandardCharsets.UTF_8.toString()) + "&type=danger");
            return;
        }
        if (asunto == null || asunto.trim().isEmpty()) {
            response.sendRedirect(redirectURL + "?message=" + URLEncoder.encode("El asunto del mensaje no puede estar vacío.", StandardCharsets.UTF_8.toString()) + "&type=danger");
            return;
        }
        if (contenido == null || contenido.trim().isEmpty()) {
            response.sendRedirect(redirectURL + "?message=" + URLEncoder.encode("El contenido del mensaje no puede estar vacío.", StandardCharsets.UTF_8.toString()) + "&type=danger");
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

            // INSERT message from alumno to professor
            String sqlInsertMensaje = "INSERT INTO mensajes (id_remitente, tipo_remitente, id_destinatario, tipo_destinatario, asunto, contenido, fecha_envio, leido) VALUES (?, 'alumno', ?, 'profesor', ?, ?, NOW(), 0)"; // Changed tipo_remitente
            pstmtMensaje = connPost.prepareStatement(sqlInsertMensaje);

            int messagesQueued = 0;
            for (Integer idProfesorDest : profesoresAEnviar) {
                pstmtMensaje.setInt(1, idAlumno); // Remitente es el alumno
                pstmtMensaje.setInt(2, idProfesorDest); // Destinatario es el profesor
                pstmtMensaje.setString(3, asunto);
                pstmtMensaje.setString(4, contenido);
                pstmtMensaje.addBatch();
                messagesQueued++;
            }

            System.out.println("DEBUG (POST): Intentando insertar " + messagesQueued + " mensajes en la base de datos.");
            int[] results = pstmtMensaje.executeBatch();
            System.out.println("DEBUG (POST): Resultados de executeBatch(): " + Arrays.toString(results));
            connPost.commit();

            int mensajesEnviadosCount = 0;
            for (int res : results) {
                if (res > 0) {
                    mensajesEnviadosCount++;
                }
            }

            if (mensajesEnviadosCount == profesoresAEnviar.size()) {
                response.sendRedirect(redirectURL + "?message=" + URLEncoder.encode("Mensajes enviados correctamente a " + mensajesEnviadosCount + " profesor(es).", StandardCharsets.UTF_8.toString()) + "&type=success");
            } else if (mensajesEnviadosCount > 0) {
                response.sendRedirect(redirectURL + "?message=" + URLEncoder.encode("Se enviaron algunos mensajes, pero no a todos los profesores (" + mensajesEnviadosCount + "/" + profesoresAEnviar.size() + ").", StandardCharsets.UTF_8.toString()) + "&type=danger");
            } else {
                response.sendRedirect(redirectURL + "?message=" + URLEncoder.encode("No se pudo enviar mensajes a ningún profesor. Verifique el log del servidor para más detalles.", StandardCharsets.UTF_8.toString()) + "&type=danger");
            }
            return;

        } catch (SQLException e) {
            if (connPost != null) {
                try {
                    connPost.rollback();
                    System.err.println("DEBUG (POST): Transacción rollback debido a error: " + e.getMessage());
                } catch (SQLException rollbackEx) {
                    System.err.println("ERROR (POST): Error al hacer rollback: " + rollbackEx.getMessage());
                }
            }
            System.err.println("ERROR (POST): Error de base de datos al enviar mensaje: " + e.getMessage());
            e.printStackTrace();
            response.sendRedirect(redirectURL + "?message=" + URLEncoder.encode("Error de base de datos al enviar mensaje: " + e.getMessage(), StandardCharsets.UTF_8.toString()) + "&type=danger");
            return;
        } catch (ClassNotFoundException e) {
            System.err.println("ERROR (POST): No se encontró el driver JDBC de MySQL: " + e.getMessage());
            e.printStackTrace();
            response.sendRedirect(redirectURL + "?message=" + URLEncoder.encode("Error: No se encontró el driver JDBC de MySQL.", StandardCharsets.UTF_8.toString()) + "&type=danger");
            return;
        } finally {
            closeDbResources(null, pstmtMensaje);
            if (connPost != null) {
                try { connPost.setAutoCommit(true); connPost.close(); } catch (SQLException ignore) {}
            }
        }
    }
%>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Componer Mensaje a Profesor | Sistema Universitario</title>
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
        .section-title { color: var(--admin-primary); margin-bottom: 1.5rem; font-weight: 600;}

        /* Info Box */
        .info-box {
            background-color: var(--admin-info);
            color: white;
            padding: 1.5rem;
            margin-bottom: 1.5rem;
            border-radius: 0.5rem;
            display: flex;
            align-items: center;
            gap: 1rem;
            box-shadow: 0 0.125rem 0.25rem rgba(0,0,0,0.075);
        }
        .info-box i {
            font-size: 2rem;
        }
        .info-box h4 {
            color: white;
            margin-bottom: 0.5rem;
            font-weight: 600;
        }
        .info-box p {
            font-size: 0.95rem;
            margin-bottom: 0;
        }

        /* Alerts (Bootstrap standard) */
        .alert {
            padding: 1rem 1.5rem;
            margin-bottom: 1.5rem;
            border-radius: 0.375rem;
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
            background-color: var(--admin-light-bg);
        }
        .search-results-list li:last-child { border-bottom: none; }
        .search-results-list li .text-muted { font-size: 0.85rem; }

        /* Selected recipients list */
        .selected-recipients {
            list-style-type: none;
            padding: 0.75rem;
            margin-top: 0.5rem;
            border: 1px solid var(--admin-info);
            background-color: rgba(23, 162, 184, 0.1);
            border-radius: 0.5rem;
            max-height: 180px;
            overflow-y: auto;
        }
        .selected-recipients li {
            background-color: var(--admin-info);
            color: white;
            padding: 0.5rem 0.75rem;
            margin-bottom: 0.5rem;
            border-radius: 0.3rem;
            display: flex;
            justify-content: space-between;
            align-items: center;
            font-size: 0.9em;
            word-break: break-word;
        }
        .selected-recipients li:last-child { margin-bottom: 0; }
        .selected-recipients li .remove-recipient {
            background: none;
            border: none;
            color: white;
            cursor: pointer;
            font-size: 1.2em;
            margin-left: 10px;
            transition: color 0.2s;
            opacity: 0.8;
        }
        .selected-recipients li .remove-recipient:hover {
            color: var(--admin-warning);
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
            margin-bottom: 1.5rem;
            display: flex;
            gap: 1rem;
            flex-wrap: wrap;
        }
        .select-all-buttons .btn {
            background-color: var(--admin-info);
            color: white;
            padding: 0.6rem 1.2rem;
            border: none;
            border-radius: 0.3rem;
            cursor: pointer;
            font-size: 0.95rem;
            transition: background-color 0.3s ease, transform 0.2s ease;
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
        }
        .select-all-buttons .btn:hover {
            background-color: #138496;
            transform: translateY(-2px);
        }
        .select-all-buttons #clearRecipientsBtn {
            background-color: var(--admin-danger);
        }
        .select-all-buttons #clearRecipientsBtn:hover {
            background-color: #c82333;
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
            display: inline-flex;
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
            color: white;
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

            .content-section { padding: 1.5rem 1rem; }
            .info-box { flex-direction: column; text-align: center; gap: 0.5rem; }
            .info-box i { margin-bottom: 0.5rem; }
        }

        @media (max-width: 576px) {
            .main-content { padding: 0.75rem; }
            .welcome-section, .content-section, .info-box { padding: 1rem;}
            .form-control, .form-select { padding: 0.6rem 0.8rem; font-size: 0.9rem; }
            .select-all-buttons .btn { flex-grow: 1; text-align: center; }
        }
    </style>
</head>
<body>
    <div id="app">
        <nav class="sidebar">
            <div class="sidebar-header">
                <a href="<%= request.getContextPath() %>/INTERFAZ_ALUMNO/home_alumno.jsp" class="text-white text-decoration-none">UGIC Portal</a>
            </div>
            <ul class="navbar-nav">
                <li class="nav-item">
                    <a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_ALUMNO/home_alumno.jsp"><i class="fas fa-home"></i><span> Inicio</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_ALUMNO/cursos_alumno.jsp"><i class="fas fa-book"></i><span> Mis Cursos</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_ALUMNO/asistencia_alumno.jsp"><i class="fas fa-clipboard-check"></i><span> Mi Asistencia</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_ALUMNO/notas_alumno.jsp"><i class="fas fa-percent"></i><span> Mis Notas</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_ALUMNO/pagos_alumno.jsp"><i class="fas fa-money-bill-wave"></i><span> Mis Pagos</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link active" href="<%= request.getContextPath() %>/INTERFAZ_ALUMNO/mensajes_alumno.jsp"><i class="fas fa-envelope"></i><span> Mensajes</span></a>
                </li>
            </ul>
            <li class="nav-item mt-3">
                <form action="<%= request.getContextPath() %>/logout.jsp" method="post" class="d-grid gap-2">
                    <button type="submit" class="btn btn-outline-light mx-3"><i class="fas fa-sign-out-alt me-2"></i>Cerrar sesión</button>
                </form>
            </li>
        </nav>

        <div class="main-content">
            <nav class="top-navbar">
                <div class="search-bar">
                    <form class="d-flex">
                        <%-- Search bar can remain here, but not functional for this page's context --%>
                    </form>
                </div>
                <div class="d-flex align-items-center">
                    <div class="me-3 dropdown">
                        <%-- Notifications for alumno can be added here, e.g., unread messages --%>
                    </div>
                    <div class="me-3 dropdown">
                        <a class="text-dark" href="#" role="button" id="messagesDropdown" data-bs-toggle="dropdown" aria-expanded="false">
                            <i class="fas fa-envelope fa-lg"></i>
                            <span class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger">
                                <%-- Number of unread messages for alumno --%>
                            </span>
                        </a>
                        <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="messagesDropdown">
                            <li><a class="dropdown-item" href="<%= request.getContextPath()%>/INTERFAZ_ALUMNO/mensajes_alumno.jsp">Ver todos</a></li>
                        </ul>
                    </div>

                    <div class="dropdown user-dropdown">
                        <a class="dropdown-toggle" href="#" role="button" id="userDropdown" data-bs-toggle="dropdown" aria-expanded="false">
                            <img src="https://via.placeholder.com/32" alt="Avatar"> <span class="d-none d-md-inline-block"><%= nombreAlumno != null ? nombreAlumno : "Alumno"%></span>
                        </a>
                        <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="userDropdown">
                            <li><a class="dropdown-item" href="perfil_alumno.jsp"><i class="fas fa-user me-2"></i>Perfil</a></li>
                            <li><a class="dropdown-item" href="configuracion_alumno.jsp"><i class="fas fa-cog me-2"></i>Configuración</a></li>
                            <li><hr class="dropdown-divider"></li>
                            <li><a class="dropdown-item" href="<%= request.getContextPath() %>/logout.jsp"><i class="fas fa-sign-out-alt me-2"></i>Cerrar sesión</a></li>
                        </ul>
                    </div>
                </div>
            </nav>

            <div class="container-fluid">
                <div class="welcome-section">
                    <h1 class="h3 mb-3"><i class="fas fa-paper-plane me-2"></i>Componer Mensaje a Profesor</h1>
                    <p class="lead">Envía comunicaciones importantes a tus profesores.</p>
                </div>

                <% if (mensajeDisplay != null && "success".equals(messageType)) { %>
                    <div class="alert alert-success alert-dismissible fade show" role="alert">
                        <i class="fas fa-check-circle me-2"></i><%= mensajeDisplay %>
                        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                    </div>
                <% } %>
                <% if (mensajeDisplay != null && "danger".equals(messageType)) { %>
                    <div class="alert alert-danger alert-dismissible fade show" role="alert">
                        <i class="fas fa-exclamation-triangle me-2"></i><%= mensajeDisplay %>
                        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                    </div>
                <% } %>

                <div class="info-box">
                    <i class="fas fa-info-circle"></i>
                    <div>
                        <h4>Información para el Envío</h4>
                        <p class="mb-0">
                            <% if (preselectedProfesorId != null && !preselectedProfesorId.isEmpty()) { %>
                                Estás enviando un mensaje al profesor: **<%= preselectedProfesorNombre != null ? URLEncoder.encode(preselectedProfesorNombre, StandardCharsets.UTF_8.toString()) : "N/A" %> (<%= preselectedProfesorEmail != null ? URLEncoder.encode(preselectedProfesorEmail, StandardCharsets.UTF_8.toString()) : "N/A" %>)**.
                                Puedes añadir otros profesores si lo necesitas, o usar el botón "Seleccionar Profesores de Mis Cursos" para incluir a todos tus docentes.
                            <% } else { %>
                                No has seleccionado un profesor específico. Puedes buscar profesores individualmente o usar "Seleccionar Profesores de Mis Cursos" para incluir a todos tus docentes.
                            <% } %>
                        </p>
                    </div>
                </div>

                <div class="content-section">
                    <h2 class="section-title"><i class="fas fa-edit me-2"></i>Componer Nuevo Mensaje</h2>

                    <form id="mensajeForm" action="<%= request.getContextPath() %>/INTERFAZ_ALUMNO/enviar_mensaje_alumno_profesor.jsp" method="post">
                        <div class="mb-3">
                            <label for="teacherSearchInput" class="form-label">Buscar Profesor (Nombre, DNI o Correo):</label>
                            <div class="input-group search-input-container">
                                <span class="input-group-text"><i class="fas fa-search"></i></span>
                                <input type="text" class="form-control" id="teacherSearchInput" placeholder="Escribe al menos 3 letras para buscar...">
                            </div>
                            <ul id="teacherSearchResults" class="search-results-list" style="display:none;"></ul>
                        </div>

                        <div class="select-all-buttons">
                            <button type="button" class="btn btn-info" id="selectAllTeachersOfMyCoursesBtn">
                                <i class="fas fa-chalkboard-teacher"></i> Seleccionar Profesores de Mis Cursos
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
                            <input type="text" class="form-control" id="asunto" name="asunto" required maxlength="200" placeholder="Ej: Consulta sobre rendimiento, Solicitud de reunión">
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

                <a href="<%= request.getContextPath() %>/INTERFAZ_ALUMNO/mensajes_alumno.jsp" class="back-button">
                    <i class="fas fa-arrow-left"></i> Volver al Panel Principal de Mensajería
                </a>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous"></script>
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            const teacherSearchInput = document.getElementById('teacherSearchInput');
            const teacherSearchResults = document.getElementById('teacherSearchResults');
            const selectedRecipientsList = document.getElementById('selectedRecipientsList');
            const destinatariosIdsHidden = document.getElementById('destinatariosIds');
            const recipientCountSpan = document.getElementById('recipientCount');
            const selectAllTeachersOfMyCoursesBtn = document.getElementById('selectAllTeachersOfMyCoursesBtn'); // Changed ID
            const clearRecipientsBtn = document.getElementById('clearRecipientsBtn');
            const mensajeForm = document.getElementById('mensajeForm');
            const asuntoInput = document.getElementById('asunto');
            const contenidoInput = document.getElementById('contenido');

            const preselectedProfesorId = '<%= request.getParameter("id_profesor") != null ? request.getParameter("id_profesor") : "" %>';
            const preselectedProfesorNombre = '<%= request.getParameter("nombre_profesor") != null ? request.getParameter("nombre_profesor") : "" %>';
            const preselectedProfesorEmail = '<%= request.getParameter("email_profesor") != null ? request.getParameter("email_profesor") : "" %>';

            let selectedProfesores = new Map();

            function updateRecipientCount() {
                recipientCountSpan.textContent = `${selectedProfesores.size} destinatario(s)`;
                destinatariosIdsHidden.value = Array.from(selectedProfesores.keys()).join(',');
            }

            function addRecipient(profesor) {
                if (!selectedProfesores.has(profesor.id_profesor)) {
                    selectedProfesores.set(profesor.id_profesor, profesor);

                    const listItem = document.createElement('li');
                    listItem.dataset.id = profesor.id_profesor;
                    
                    const displayDni = (profesor.dni && String(profesor.dni).trim() !== '') ? profesor.dni : 'N/A';
                    const displayEmail = (profesor.email && String(profesor.email).trim() !== '') ? profesor.email : 'N/A';
                    const displayNombreCompleto = (profesor.nombre_completo && String(profesor.nombre_completo).trim() !== '') ? profesor.nombre_completo : 'N/A';

                    listItem.innerHTML = `
                        <span><i class="fas fa-chalkboard-teacher me-2"></i> ${displayNombreCompleto} (DNI: ${displayDni}, Email: ${displayEmail})</span>
                        <button type="button" class="remove-recipient" data-id="${profesor.id_profesor}">&times;</button>
                    `;
                    selectedRecipientsList.appendChild(listItem);

                    listItem.querySelector('.remove-recipient').addEventListener('click', function() {
                        removeRecipient(parseInt(this.dataset.id));
                    });

                    updateRecipientCount();
                }
                teacherSearchInput.value = '';
                teacherSearchResults.innerHTML = '';
                teacherSearchResults.style.display = 'none';
            }

            function removeRecipient(idProfesor) {
                selectedProfesores.delete(idProfesor);
                const listItem = selectedRecipientsList.querySelector(`li[data-id="${idProfesor}"]`);
                if (listItem) {
                    listItem.remove();
                }
                updateRecipientCount();
            }

            // --- Teacher Search Logic (AJAX to this JSP) ---
            let currentSearchTimeout = null;
            teacherSearchInput.addEventListener('keyup', function() {
                clearTimeout(currentSearchTimeout);
                const searchTerm = this.value.trim();

                if (searchTerm.length < 3) {
                    teacherSearchResults.innerHTML = '';
                    teacherSearchResults.style.display = 'none';
                    return;
                }

                currentSearchTimeout = setTimeout(function() {
                    // AJAX request to this JSP, with 'term' parameter and requestType
                    fetch('<%= request.getContextPath() %>/INTERFAZ_ALUMNO/enviar_mensaje_alumno_profesor.jsp?requestType=searchTeachers&term=' + encodeURIComponent(searchTerm)) // Changed path
                        .then(response => {
                            if (!response.ok) {
                                throw new Error('Error de red o servidor: ' + response.status + ' ' + response.statusText);
                            }
                            return response.json();
                        })
                        .then(data => {
                            teacherSearchResults.innerHTML = '';
                            if (data.length > 0) {
                                data.forEach(profesor => {
                                    const listItem = document.createElement('li');
                                    const displayDni = (profesor.dni && String(profesor.dni).trim() !== '') ? profesor.dni : 'N/A';
                                    const displayEmail = (profesor.email && String(profesor.email).trim() !== '') ? profesor.email : 'N/A';
                                    const displayNombreCompleto = (profesor.nombre_completo && String(profesor.nombre_completo).trim() !== '') ? profesor.nombre_completo : 'N/A';

                                    listItem.innerHTML = `<i class="fas fa-chalkboard-teacher"></i> ${displayNombreCompleto} <span class="text-muted">(DNI: ${displayDni})</span>`;
                                    listItem.dataset.id_profesor = profesor.id_profesor;
                                    listItem.dataset.nombre_completo = profesor.nombre_completo;
                                    listItem.dataset.dni = profesor.dni;
                                    listItem.dataset.email = profesor.email;
                                    
                                    listItem.addEventListener('click', function() {
                                        addRecipient({
                                            id_profesor: parseInt(this.dataset.id_profesor),
                                            nombre_completo: this.dataset.nombre_completo,
                                            dni: this.dataset.dni,
                                            email: this.dataset.email
                                        });
                                    });
                                    teacherSearchResults.appendChild(listItem);
                                });
                                teacherSearchResults.style.display = 'block';
                            } else {
                                const listItem = document.createElement('li');
                                listItem.textContent = 'No se encontraron profesores.';
                                listItem.style.fontStyle = 'italic';
                                listItem.style.color = 'var(--admin-text-muted)';
                                teacherSearchResults.appendChild(listItem);
                                teacherSearchResults.style.display = 'block';
                            }
                        })
                        .catch(error => {
                            console.error('ERROR: Al obtener datos de profesores para el buscador (AJAX):', error);
                            teacherSearchResults.innerHTML = '<li><i class="fas fa-exclamation-triangle text-danger me-2"></i>Error al cargar resultados. Por favor, intente de nuevo.</li>';
                            teacherSearchResults.style.display = 'block';
                        });
                }, 300);
            });

            // Hide search results when clicking outside
            document.addEventListener('click', function(event) {
                if (!teacherSearchInput.contains(event.target) && !teacherSearchResults.contains(event.target)) {
                    teacherSearchResults.style.display = 'none';
                }
            });

            // --- Button to select all teachers from my courses ---
            selectAllTeachersOfMyCoursesBtn.addEventListener('click', function() { // Changed ID
                if (confirm('¿Estás seguro de que quieres seleccionar a TODOS los profesores de tus cursos activos? Esto sobrescribirá la lista actual de destinatarios.')) {
                    selectedProfesores.clear();
                    selectedRecipientsList.innerHTML = '';

                    fetch('<%= request.getContextPath() %>/INTERFAZ_ALUMNO/enviar_mensaje_alumno_profesor.jsp?requestType=getAllTeachersOfMyCourses') // Changed path and requestType
                        .then(response => {
                            if (!response.ok) {
                                throw new Error('Network response was not ok ' + response.statusText);
                            }
                            return response.json();
                        })
                        .then(data => {
                            if (data.length > 0) {
                                data.forEach(profesor => {
                                    addRecipient(profesor);
                                });
                                alert(`Se han añadido ${data.length} profesores de tus cursos.`); // Changed message
                            } else {
                                alert('No se encontraron profesores para tus cursos activos.'); // Changed message
                            }
                        })
                        .catch(error => {
                            console.error('ERROR: Al seleccionar todos los profesores del alumno (AJAX):', error); // Changed log
                            alert('Hubo un error al intentar seleccionar todos los profesores. Verifique la consola para más detalles.');
                        });
                }
            });

            // Button to clear all recipients
            clearRecipientsBtn.addEventListener('click', function() {
                if (confirm('¿Estás seguro de que quieres limpiar todos los destinatarios seleccionados?')) {
                    selectedProfesores.clear();
                    selectedRecipientsList.innerHTML = '';
                    updateRecipientCount();
                }
            });

            // Form validation on submit
            mensajeForm.addEventListener('submit', function(event) {
                if (selectedProfesores.size === 0) {
                    alert("Debes seleccionar al menos un destinatario para enviar el mensaje.");
                    event.preventDefault();
                    return;
                }
                if (asuntoInput.value.trim() === '') {
                    alert("El asunto del mensaje no puede estar vacío.");
                    asuntoInput.focus();
                    event.preventDefault();
                    return;
                }
                if (contenidoInput.value.trim() === '') {
                    alert("El contenido del mensaje no puede estar vacío.");
                    contenidoInput.focus();
                    event.preventDefault();
                    return;
                }
            });

            // Initial recipient count on page load
            updateRecipientCount();

            // Auto-populate pre-selected teacher if ID, Nombre, and Email are present in the URL
            if (preselectedProfesorId && preselectedProfesorId !== "null" && preselectedProfesorId !== "") {
                addRecipient({
                    id_profesor: parseInt(preselectedProfesorId),
                    nombre_completo: decodeURIComponent(preselectedProfesorNombre),
                    email: decodeURIComponent(preselectedProfesorEmail),
                    dni: 'N/A' // DNI might not be passed in URL, or fetch it if needed.
                });
            }
        });
    </script>
</body>
</html>