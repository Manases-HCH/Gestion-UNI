<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, pe.universidad.util.Conection" %>
<%@ page import="java.util.Base64" %>
<%@ page import="java.util.ArrayList, java.util.HashMap, java.util.List, java.util.Map" %>
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
%>

<%
    // Obtener información de la sesión
    String email = (String) session.getAttribute("email");
    String rolUsuario = (String) session.getAttribute("rol");

    if (email == null || !"profesor".equalsIgnoreCase(rolUsuario)) {
        response.sendRedirect("login.jsp");
        return;
    }

    String mensaje = "";
    String tipoMensaje = "info"; // Para mostrar alertas

    int idProfesor = 0;
    String nombreProfesor = "";
    String facultadProfesor = "Sin asignar";
    int idFacultadProfesor = 0;

    int totalCursosAsignados = 0;
    int totalPendingJoinRequests = 0; // Nuevo contador
    int totalPendingLeaveRequests = 0; // Nuevo contador

    Connection conn = null; // La conexión se inicializa y se cierra una vez por petición
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    try {
        Conection c = new Conection();
        conn = c.conecta(); // Obtener la conexión al inicio de la petición

        // --- 1. Obtener Datos Principales del Profesor ---
        PreparedStatement pstmtProfesor = null;
        ResultSet rsProfesor = null;
        try {
            String sqlProfesor = "SELECT p.id_profesor, p.nombre, p.apellido_paterno, p.apellido_materno, p.id_facultad, f.nombre_facultad "
                                + "FROM profesores p LEFT JOIN facultades f ON p.id_facultad = f.id_facultad "
                                + "WHERE p.email = ?";
            pstmtProfesor = conn.prepareStatement(sqlProfesor);
            pstmtProfesor.setString(1, email);
            rsProfesor = pstmtProfesor.executeQuery();

            if (rsProfesor.next()) {
                idProfesor = rsProfesor.getInt("id_profesor");
                String nom = rsProfesor.getString("nombre") != null ? rsProfesor.getString("nombre") : "";
                String apP = rsProfesor.getString("apellido_paterno") != null ? rsProfesor.getString("apellido_paterno") : "";
                String apM = rsProfesor.getString("apellido_materno") != null ? rsProfesor.getString("apellido_materno") : "";
                nombreProfesor = (nom + " " + apP + " " + apM).trim().replaceAll("\\s+", " ");
                idFacultadProfesor = rsProfesor.getInt("id_facultad");
                facultadProfesor = rsProfesor.getString("nombre_facultad") != null ? rsProfesor.getString("nombre_facultad") : "Sin asignar";
            } else {
                response.sendRedirect("login.jsp?error=profesor_no_encontrado");
                return;
            }
        } finally {
            closeDbResources(rsProfesor, pstmtProfesor);
        }

        // --- 2. Procesar acciones del formulario (Unirse/Salir) ---
        String action = request.getParameter("action");
        String idCursoParam = request.getParameter("id_curso");

        if (idCursoParam != null && idProfesor > 0) {
            int idCurso = Integer.parseInt(idCursoParam);

            if ("unirse".equals(action)) {
                // Verificar si ya está inscrito
                PreparedStatement pstmtCheckInscrito = null;
                ResultSet rsCheckInscrito = null;
                boolean yaInscrito = false;
                try {
                    String sqlCheckInscrito = "SELECT COUNT(*) FROM profesor_curso WHERE id_profesor = ? AND id_curso = ?";
                    pstmtCheckInscrito = conn.prepareStatement(sqlCheckInscrito);
                    pstmtCheckInscrito.setInt(1, idProfesor);
                    pstmtCheckInscrito.setInt(2, idCurso);
                    rsCheckInscrito = pstmtCheckInscrito.executeQuery();
                    if (rsCheckInscrito.next() && rsCheckInscrito.getInt(1) > 0) {
                        yaInscrito = true;
                    }
                } finally { closeDbResources(rsCheckInscrito, pstmtCheckInscrito); }

                // Verificar si ya hay una solicitud PENDIENTE para UNIRSE
                PreparedStatement pstmtCheckPendingJoin = null;
                ResultSet rsCheckPendingJoin = null;
                boolean solicitudUnirsePendiente = false;
                try {
                    String sqlCheckPending = "SELECT COUNT(*) FROM solicitudes_cursos WHERE id_profesor = ? AND id_curso = ? AND tipo_solicitud = 'UNIRSE' AND estado = 'PENDIENTE'";
                    pstmtCheckPendingJoin = conn.prepareStatement(sqlCheckPending);
                    pstmtCheckPendingJoin.setInt(1, idProfesor);
                    pstmtCheckPendingJoin.setInt(2, idCurso);
                    rsCheckPendingJoin = pstmtCheckPendingJoin.executeQuery();
                    if (rsCheckPendingJoin.next() && rsCheckPendingJoin.getInt(1) > 0) {
                        solicitudUnirsePendiente = true;
                    }
                } finally { closeDbResources(rsCheckPendingJoin, pstmtCheckPendingJoin); }

                if (yaInscrito) {
                    mensaje = "Ya estás asignado a este curso.";
                    tipoMensaje = "warning";
                } else if (solicitudUnirsePendiente) {
                    mensaje = "Ya existe una solicitud pendiente para unirte a este curso.";
                    tipoMensaje = "info";
                } else {
                    PreparedStatement pstmtInsertRequest = null;
                    try {
                        String sqlInsertRequest = "INSERT INTO solicitudes_cursos (id_profesor, id_curso, tipo_solicitud, estado) VALUES (?, ?, 'UNIRSE', 'PENDIENTE')";
                        pstmtInsertRequest = conn.prepareStatement(sqlInsertRequest);
                        pstmtInsertRequest.setInt(1, idProfesor);
                        pstmtInsertRequest.setInt(2, idCurso);
                        int result = pstmtInsertRequest.executeUpdate();
                        if (result > 0) {
                            mensaje = "Tu solicitud para unirte al curso ha sido enviada para aprobación.";
                            tipoMensaje = "success";
                        } else {
                            mensaje = "Error al enviar la solicitud para unirte al curso.";
                            tipoMensaje = "danger";
                        }
                    } finally { closeDbResources(null, pstmtInsertRequest); }
                }
            } else if ("salir".equals(action)) {
                // Verificar si ya hay una solicitud PENDIENTE para SALIR
                PreparedStatement pstmtCheckPendingLeave = null;
                ResultSet rsCheckPendingLeave = null;
                boolean solicitudSalirPendiente = false;
                try {
                    String sqlCheckPending = "SELECT COUNT(*) FROM solicitudes_cursos WHERE id_profesor = ? AND id_curso = ? AND tipo_solicitud = 'SALIR' AND estado = 'PENDIENTE'";
                    pstmtCheckPendingLeave = conn.prepareStatement(sqlCheckPending);
                    pstmtCheckPendingLeave.setInt(1, idProfesor);
                    pstmtCheckPendingLeave.setInt(2, idCurso);
                    rsCheckPendingLeave = pstmtCheckPendingLeave.executeQuery();
                    if (rsCheckPendingLeave.next() && rsCheckPendingLeave.getInt(1) > 0) {
                        solicitudSalirPendiente = true;
                    }
                } finally { closeDbResources(rsCheckPendingLeave, pstmtCheckPendingLeave); }

                if (solicitudSalirPendiente) {
                    mensaje = "Ya existe una solicitud pendiente para salir de este curso.";
                    tipoMensaje = "info";
                } else {
                    PreparedStatement pstmtInsertRequest = null;
                    try {
                        String sqlInsertRequest = "INSERT INTO solicitudes_cursos (id_profesor, id_curso, tipo_solicitud, estado) VALUES (?, ?, 'SALIR', 'PENDIENTE')";
                        pstmtInsertRequest = conn.prepareStatement(sqlInsertRequest);
                        pstmtInsertRequest.setInt(1, idProfesor);
                        pstmtInsertRequest.setInt(2, idCurso);
                        int result = pstmtInsertRequest.executeUpdate();
                        if (result > 0) {
                            mensaje = "Tu solicitud para salir del curso ha sido enviada para aprobación.";
                            tipoMensaje = "success";
                        } else {
                            mensaje = "Error al enviar la solicitud para salir del curso.";
                            tipoMensaje = "danger";
                        }
                    } finally { closeDbResources(null, pstmtInsertRequest); }
                }
            }
        }

        // --- 3. Obtener Total de Cursos Asignados ---
        PreparedStatement pstmtTotalAsignados = null;
        ResultSet rsTotalAsignados = null;
        try {
            String sqlCount = "SELECT COUNT(*) FROM profesor_curso WHERE id_profesor = ?";
            pstmtTotalAsignados = conn.prepareStatement(sqlCount);
            pstmtTotalAsignados.setInt(1, idProfesor);
            rsTotalAsignados = pstmtTotalAsignados.executeQuery();
            if (rsTotalAsignados.next()) {
                totalCursosAsignados = rsTotalAsignados.getInt(1);
            }
        } finally {
            closeDbResources(rsTotalAsignados, pstmtTotalAsignados);
        }

        // --- 4. Obtener Conteo de Solicitudes Pendientes (UNIRSE) ---
        PreparedStatement pstmtPendingJoin = null;
        ResultSet rsPendingJoin = null;
        try {
            String sqlPendingJoin = "SELECT COUNT(*) FROM solicitudes_cursos WHERE id_profesor = ? AND tipo_solicitud = 'UNIRSE' AND estado = 'PENDIENTE'";
            pstmtPendingJoin = conn.prepareStatement(sqlPendingJoin);
            pstmtPendingJoin.setInt(1, idProfesor);
            rsPendingJoin = pstmtPendingJoin.executeQuery();
            if (rsPendingJoin.next()) {
                totalPendingJoinRequests = rsPendingJoin.getInt(1);
            }
        } finally {
            closeDbResources(rsPendingJoin, pstmtPendingJoin);
        }

        // --- 5. Obtener Conteo de Solicitudes Pendientes (SALIR) ---
        PreparedStatement pstmtPendingLeave = null;
        ResultSet rsPendingLeave = null;
        try {
            String sqlPendingLeave = "SELECT COUNT(*) FROM solicitudes_cursos WHERE id_profesor = ? AND tipo_solicitud = 'SALIR' AND estado = 'PENDIENTE'";
            pstmtPendingLeave = conn.prepareStatement(sqlPendingLeave);
            pstmtPendingLeave.setInt(1, idProfesor);
            rsPendingLeave = pstmtPendingLeave.executeQuery();
            if (rsPendingLeave.next()) {
                totalPendingLeaveRequests = rsPendingLeave.getInt(1);
            }
        } finally {
            closeDbResources(rsPendingLeave, pstmtPendingLeave);
        }

    } catch (Exception e) { // Captura cualquier excepción que pueda ocurrir
        mensaje = "Error inesperado: " + e.getMessage();
        tipoMensaje = "danger";
        e.printStackTrace();
    } finally {
        // La conexión principal se cierra una única vez al final de la petición
        try {
            if (conn != null) {
                conn.close();
            }
        } catch (SQLException e) { /* Ignorar al cerrar la conexión final */ }
    }
%>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Cursos - Sistema Universitario</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.0/font/bootstrap-icons.css">
    <style>
        :root {
            --admin-dark: #222B40; /* Color oscuro para sidebar y navbar */
            --admin-light-bg: #F0F2F5; /* Fondo claro para el main content */
            --admin-card-bg: #FFFFFF; /* Fondo de las tarjetas */
            --admin-text-dark: #333333; /* Texto principal */
            --admin-text-muted: #6C757D; /* Texto secundario/gris */
            --admin-primary: #007BFF; /* Azul principal de AdminKit */
            --admin-success: #28A745; /* Verde para crecimiento */
            --admin-danger: #DC3545; /* Rojo para descenso */
            --admin-warning: #FFC107; /* Amarillo para advertencias/tardanzas */
            --admin-info: #17A2B8; /* Cian para información/presentes */
            --admin-secondary-color: #6C757D; /* Un gris más oscuro para algunos detalles */
        }

        body {
            font-family: 'Inter', sans-serif;
            background-color: var(--admin-light-bg);
            color: var(--admin-text-dark);
            min-height: 100vh;
            display: flex;
            flex-direction: column; /* Changed to column for global app structure */
            overflow-x: hidden;
        }

        /* Contenedor principal de la aplicación */
        #app {
            display: flex;
            flex: 1; /* Make it take available height */
            width: 100%;
        }

        /* Sidebar */
        .sidebar {
            width: 280px;
            background-color: var(--admin-dark);
            color: rgba(255, 255, 255, 0.8);
            padding-top: 1rem;
            flex-shrink: 0;
            position: sticky; /* Make it sticky */
            top: 0;
            left: 0;
            height: 100vh; /* Full viewport height */
            overflow-y: auto;
            box-shadow: 2px 0 5px rgba(0,0,0,0.1);
            z-index: 1030;
        }

        .sidebar-header {
            padding: 1rem 1.5rem;
            margin-bottom: 1.5rem;
            text-align: center;
            font-size: 1.5rem;
            font-weight: 700;
            color: var(--admin-primary);
            border-bottom: 1px solid rgba(255, 255, 255, 0.05);
        }

        .sidebar .nav-link {
            display: flex;
            align-items: center;
            padding: 0.75rem 1.5rem;
            color: rgba(255, 255, 255, 0.7);
            text-decoration: none;
            transition: all 0.2s ease-in-out;
            font-weight: 500;
        }

        .sidebar .nav-link i {
            margin-right: 0.75rem;
            font-size: 1.1rem;
        }

        .sidebar .nav-link:hover,
        .sidebar .nav-link.active {
            color: white;
            background-color: rgba(255, 255, 255, 0.08);
            border-left: 4px solid var(--admin-primary);
            padding-left: 1.3rem;
        }

        /* Main Content */
        .main-content {
            flex: 1;
            padding: 1.5rem;
            overflow-y: auto;
            display: flex;
            flex-direction: column;
        }

        /* Top Navbar */
        .top-navbar {
            background-color: var(--admin-card-bg);
            padding: 1rem 1.5rem;
            box-shadow: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.075);
            margin-bottom: 1.5rem;
            border-radius: 0.5rem;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .top-navbar .search-bar .form-control {
            border: 1px solid #e0e0e0;
            border-radius: 0.3rem;
            padding: 0.5rem 1rem;
        }

        .top-navbar .user-dropdown .dropdown-toggle {
            display: flex;
            align-items: center;
            color: var(--admin-text-dark);
            text-decoration: none;
        }
        .top-navbar .user-dropdown .dropdown-toggle img {
            width: 32px;
            height: 32px;
            border-radius: 50%;
            margin-right: 0.5rem;
            object-fit: cover;
            border: 2px solid var(--admin-primary);
        }

        /* Welcome Section */
        .welcome-section {
            background-color: var(--admin-card-bg);
            border-radius: 0.5rem;
            padding: 1.5rem;
            margin-bottom: 1.5rem;
            box-shadow: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.075);
        }
        .welcome-section h1 {
            color: var(--admin-text-dark);
            font-weight: 600;
            margin-bottom: 0.5rem;
        }
        .welcome-section p.lead {
            color: var(--admin-text-muted);
            font-size: 1rem;
        }

        /* General Content Card Styling */
        .content-section.card {
            border-radius: 0.5rem;
            box-shadow: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.075);
            border-left: 4px solid var(--admin-primary); /* Consistent border */
        }
        .section-title {
            color: var(--admin-primary);
            margin-bottom: 1rem;
            font-weight: 600;
        }

        /* Profesor Info Card (re-styled for dashboard consistency) */
        .profesor-info.card {
            border-left: 4px solid var(--admin-info); /* Different color for professor info */
            box-shadow: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.075);
            border-radius: 0.5rem;
            padding: 1.5rem;
            margin-bottom: 1.5rem;
        }
        .profesor-info h4 {
            color: var(--admin-text-dark);
            font-weight: 600;
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }
        .profesor-info p {
            margin-bottom: 0.2rem;
            color: var(--admin-text-muted);
        }
        .profesor-info p strong {
            color: var(--admin-text-dark);
        }
        .profesor-info .total-cursos-display {
            font-size: 2.2rem;
            font-weight: 700;
            color: var(--admin-primary);
            line-height: 1;
        }
        .profesor-info .total-cursos-label {
            font-size: 0.85rem;
            color: var(--admin-text-muted);
        }

        /* Solicitudes Pendientes Section */
        .pending-requests-card {
            border-left: 4px solid var(--admin-warning); /* Warning color for pending status */
            box-shadow: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.075);
            border-radius: 0.5rem;
            padding: 1.5rem;
            margin-bottom: 1.5rem;
        }
        .pending-requests-card .card-body {
            display: flex;
            flex-direction: column;
        }
        .pending-requests-card .request-summary {
            display: flex;
            justify-content: space-around;
            align-items: center;
            margin-top: 1rem;
            margin-bottom: 1.5rem;
        }
        .pending-requests-card .request-item {
            text-align: center;
        }
        .pending-requests-card .request-item .count {
            font-size: 2.5rem;
            font-weight: 700;
            color: var(--admin-warning);
            line-height: 1;
        }
        .pending-requests-card .request-item .label {
            font-size: 0.9rem;
            color: var(--admin-text-muted);
            margin-top: 0.25rem;
        }
        .pending-requests-card .action-button {
            text-align: center;
            margin-top: auto; /* Pushes button to bottom if content is dynamic */
        }


        /* Tab Styling */
        .nav-tabs {
            border-bottom: 2px solid var(--admin-primary);
            margin-bottom: 1.5rem;
        }
        .nav-tabs .nav-link {
            color: var(--admin-text-dark);
            border: none;
            border-top-left-radius: 0.3rem;
            border-top-right-radius: 0.3rem;
            padding: 0.75rem 1.25rem;
            font-weight: 500;
        }
        .nav-tabs .nav-link.active {
            color: white;
            background-color: var(--admin-primary);
            border-color: var(--admin-primary);
            border-bottom-color: var(--admin-primary); /* Ensure consistent active tab color */
        }
        .nav-tabs .nav-link:hover:not(.active) {
            color: var(--admin-primary);
            background-color: rgba(0, 123, 255, 0.1);
        }
        .tab-content {
            background-color: var(--admin-card-bg);
            border-radius: 0.5rem;
            box-shadow: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.075);
            padding: 1.5rem;
        }


        /* Curso Card Grid */
        .cursos-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
            gap: 1.5rem;
            margin-top: 1rem; /* Adjust if needed after tab-content padding */
        }

        .curso-card {
            transition: transform 0.2s, box-shadow 0.2s;
            border: 1px solid #e0e0e0;
            border-radius: 0.5rem;
            overflow: hidden;
            box-shadow: 0 0.125rem 0.25rem rgba(0,0,0,0.075);
            background-color: var(--admin-card-bg);
        }
        .curso-card:hover {
            transform: translateY(-3px);
            box-shadow: 0 0.25rem 0.5rem rgba(0,0,0,0.1);
            border-color: var(--admin-primary);
        }

        .curso-imagen {
            height: 180px;
            width: 100%;
            object-fit: cover;
            background-color: #f0f0f0;
        }
        .curso-imagen-placeholder {
            height: 180px;
            display: flex;
            align-items: center;
            justify-content: center;
            background-color: #f0f0f0;
            color: var(--admin-primary);
            font-size: 3rem;
        }

        .curso-card .card-body {
            padding: 1rem;
        }
        .curso-card .card-title {
            color: var(--admin-primary);
            margin-bottom: 0.5rem;
            font-weight: 600;
        }
        .curso-card .text-muted i {
            margin-right: 0.25rem;
            color: var(--admin-text-muted);
        }
        .curso-card .badge {
            font-weight: 500;
            margin-right: 0.5rem;
            border-radius: 0.25rem; /* Less rounded than pill */
        }
        .curso-card .badge-primary {
            background-color: rgba(0, 123, 255, 0.1);
            color: var(--admin-primary);
            border: 1px solid var(--admin-primary);
        }
        .curso-card .badge-creditos {
            background-color: rgba(108, 117, 125, 0.1);
            color: var(--admin-secondary-color);
            border: 1px solid var(--admin-secondary-color);
        }

        .curso-card .btn {
            width: 100%;
            padding: 0.6rem 1rem;
            font-weight: 500;
            border-radius: 0.3rem;
        }
        .curso-card .btn-primary {
            background-color: var(--admin-primary);
            border-color: var(--admin-primary);
            color: white;
        }
        .curso-card .btn-primary:hover {
            background-color: #0056b3;
            border-color: #0056b3;
        }
        .curso-card .btn-outline-danger {
            color: var(--admin-danger);
            border-color: var(--admin-danger);
        }
        .curso-card .btn-outline-danger:hover {
            background-color: var(--admin-danger);
            color: white;
        }

        /* No data / Empty states */
        .empty-state {
            text-align: center;
            padding: 3rem;
            color: var(--admin-text-muted);
        }
        .empty-state i {
            font-size: 3rem;
            margin-bottom: 1rem;
        }
        .empty-state h4 {
            color: var(--admin-text-dark);
            margin-top: 1rem;
        }

        /* Alert styling consistent with AdminKit */
        .alert {
            border-radius: 0.5rem;
            padding: 1rem 1.5rem;
            margin-bottom: 1.5rem;
            font-weight: 500;
        }
        .alert-success { background-color: rgba(40, 167, 69, 0.1); border-color: var(--admin-success); color: var(--admin-success); }
        .alert-danger { background-color: rgba(220, 53, 69, 0.1); border-color: var(--admin-danger); color: var(--admin-danger); }
        .alert-warning { background-color: rgba(255, 193, 7, 0.1); border-color: var(--admin-warning); color: var(--admin-warning); }
        .alert-info { background-color: rgba(23, 162, 184, 0.1); border-color: var(--admin-info); color: var(--admin-info); }


        /* Responsive adjustments */
        @media (max-width: 992px) {
            .sidebar {
                width: 220px;
            }
            .main-content {
                padding: 1rem;
            }
        }

        @media (max-width: 768px) {
            #app {
                flex-direction: column;
            }
            .sidebar {
                width: 100%;
                height: auto;
                position: relative;
                box-shadow: 0 2px 5px rgba(0,0,0,0.1);
                padding-bottom: 0.5rem;
            }
            .sidebar .nav-link {
                justify-content: center;
                padding: 0.6rem 1rem;
            }
            .sidebar .nav-link i {
                margin-right: 0.5rem;
            }
            .top-navbar {
                flex-direction: column;
                align-items: flex-start;
            }
            .top-navbar .search-bar {
                width: 100%;
                margin-bottom: 1rem;
            }
            .top-navbar .user-dropdown {
                width: 100%;
                text-align: center;
            }
            .top-navbar .user-dropdown .dropdown-toggle {
                justify-content: center;
            }
            .profesor-info.card .row > div { /* For the two columns inside profesor-info */
                flex-basis: 100% !important;
            }
            .profesor-info .total-cursos-display-wrapper {
                text-align: left !important; /* Adjust align on small screens */
                margin-top: 1rem;
            }
            .pending-requests-card .request-summary {
                flex-direction: column;
                gap: 1rem;
            }
        }

        @media (max-width: 576px) {
            .main-content {
                padding: 0.75rem;
            }
            .welcome-section, .card {
                padding: 1rem;
            }
            .curso-card .btn {
                font-size: 0.9rem;
                padding: 0.5rem 0.8rem;
            }
        }
    </style>
</head>
<body>
    <div id="app">
        <nav class="sidebar">
            <div class="sidebar-header">
                <a href="home_profesor.jsp" class="text-white text-decoration-none">UGIC Portal</a>
            </div>

            <ul class="navbar-nav">
                <li class="nav-item">
                    <a class="nav-link" href="home_profesor.jsp"><i class="fas fa-chart-line"></i><span> Dashboard</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="facultad_profesor.jsp"><i class="fas fa-building"></i><span> Facultades</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="carreras_profesor.jsp"><i class="fas fa-graduation-cap"></i><span> Carreras</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link active" href="cursos_profesor.jsp"><i class="fas fa-book"></i><span> Cursos</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="salones_profesor.jsp"><i class="fas fa-chalkboard"></i><span> Clases</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="horarios_profesor.jsp"><i class="fas fa-calendar-alt"></i><span> Horarios</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="asistencia_profesor.jsp"><i class="fas fa-clipboard-check"></i><span> Asistencia</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="mensaje_profesor.jsp"><i class="fas fa-envelope"></i><span> Mensajería</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="nota_profesor.jsp"><i class="fas fa-percent"></i><span> Notas</span></a>
                </li>
                <li class="nav-item mt-3">
                    <form action="logout.jsp" method="post" class="d-grid gap-2">
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
                    <h1 class="h3 mb-3">Gestión de Cursos</h1>
                    <p class="lead">Bienvenido al módulo de cursos. Aquí puede ver los cursos asignados y unirse a nuevos cursos disponibles.</p>
                </div>

                <% if (!mensaje.isEmpty()) {%>
                <div class="alert alert-<%= tipoMensaje%> alert-dismissible fade show" role="alert">
                    <%= mensaje%>
                    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                </div>
                <% }%>

                <div class="row">
                    <div class="col-xl-6 col-lg-12 mb-4">
                        <div class="profesor-info card">
                            <div class="card-body">
                                <div class="row align-items-center">
                                    <div class="col-md-8">
                                        <h4><i class="fas fa-user-tie me-2"></i><%= nombreProfesor%></h4>
                                        <p class="mb-0"><i class="fas fa-envelope me-2"></i><%= email%></p>
                                        <p class="mb-0"><i class="fas fa-building me-2"></i>Facultad: <strong><%= facultadProfesor%></strong></p>
                                    </div>
                                    <div class="col-md-4 text-end total-cursos-display-wrapper">
                                        <div class="total-cursos-display"><%= totalCursosAsignados%></div>
                                        <div class="total-cursos-label">Cursos Asignados</div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="col-xl-6 col-lg-12 mb-4">
                        <div class="pending-requests-card card">
                            <div class="card-body">
                                <h3 class="section-title card-title"><i class="fas fa-hourglass-half me-2"></i>Resumen de Solicitudes Pendientes</h3>
                                <div class="request-summary">
                                    <div class="request-item">
                                        <div class="count text-info"><%= totalPendingJoinRequests%></div>
                                        <div class="label">Solicitudes para Unirse</div>
                                    </div>
                                    <div class="request-item">
                                        <div class="count text-warning"><%= totalPendingLeaveRequests%></div>
                                        <div class="label">Solicitudes para Salir</div>
                                    </div>
                                </div>
                                <div class="action-button">
                                    <a href="solicitudes_profesor.jsp" class="btn btn-outline-primary"><i class="fas fa-file-alt me-2"></i>Gestionar Mis Solicitudes</a>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="tab-section">
                    <ul class="nav nav-tabs" id="cursosTabs" role="tablist">
                        <li class="nav-item" role="presentation">
                            <button class="nav-link active" id="mis-cursos-tab" data-bs-toggle="tab"
                                    data-bs-target="#mis-cursos" type="button" role="tab" aria-controls="mis-cursos" aria-selected="true">
                                <i class="fas fa-chalkboard-teacher me-2"></i>Mis Cursos Asignados
                            </button>
                        </li>
                        <li class="nav-item" role="presentation">
                            <button class="nav-link" id="disponibles-tab" data-bs-toggle="tab"
                                    data-bs-target="#disponibles" type="button" role="tab" aria-controls="disponibles" aria-selected="false">
                                <i class="fas fa-search me-2"></i>Cursos Disponibles para Unirse
                            </button>
                        </li>
                    </ul>

                    <div class="tab-content" id="cursosTabsContent">
                        <div class="tab-pane fade show active" id="mis-cursos" role="tabpanel" aria-labelledby="mis-cursos-tab">
                            <div class="cursos-grid">
                                <%
                                    // RE-OBTENER LA CONEXIÓN PARA ESTE BLOQUE DE CÓDIGO
                                    // Esto es para asegurar que la conexión esté abierta si ha habido alguna excepción previa
                                    // Idealmente, la conexión se maneja una vez al principio de la página.
                                    // Si hay errores de "conexión cerrada", este es el punto a revisar a fondo.
                                    Connection localConnMisCursos = null;
                                    PreparedStatement localPstmtMisCursos = null;
                                    ResultSet localRsMisCursos = null;
                                    try {
                                        if (conn == null || conn.isClosed()) { // Reabrir si se cerró por error
                                            Conection c = new Conection();
                                            localConnMisCursos = c.conecta();
                                        } else {
                                            localConnMisCursos = conn; // Usar la conexión existente
                                        }

                                        String sqlMisCursos = "SELECT c.id_curso, c.nombre_curso, c.codigo_curso, c.creditos, "
                                                            + "c.imagen, c.tipo_imagen, "
                                                            + "(SELECT estado FROM solicitudes_cursos sc WHERE sc.id_profesor = ? AND sc.id_curso = c.id_curso AND sc.tipo_solicitud = 'SALIR' ORDER BY sc.fecha_solicitud DESC LIMIT 1) as pending_leave_status "
                                                            + "FROM cursos c "
                                                            + "JOIN profesor_curso pc ON c.id_curso = pc.id_curso "
                                                            + "WHERE pc.id_profesor = ? "
                                                            + "ORDER BY c.nombre_curso";
                                        localPstmtMisCursos = localConnMisCursos.prepareStatement(sqlMisCursos);
                                        localPstmtMisCursos.setInt(1, idProfesor);
                                        localPstmtMisCursos.setInt(2, idProfesor);
                                        localRsMisCursos = localPstmtMisCursos.executeQuery();

                                        boolean tieneCursos = false;
                                        while (localRsMisCursos.next()) {
                                            tieneCursos = true;
                                            int idCurso = localRsMisCursos.getInt("id_curso");
                                            String nombreCurso = localRsMisCursos.getString("nombre_curso");
                                            String codigoCurso = localRsMisCursos.getString("codigo_curso");
                                            int creditos = localRsMisCursos.getInt("creditos");
                                            byte[] imagen = localRsMisCursos.getBytes("imagen");
                                            String tipoImagen = localRsMisCursos.getString("tipo_imagen");
                                            String pendingLeaveStatus = localRsMisCursos.getString("pending_leave_status");

                                            String imagenBase64 = "";
                                            if (imagen != null && imagen.length > 0) {
                                                imagenBase64 = "data:" + tipoImagen + ";base64," + Base64.getEncoder().encodeToString(imagen);
                                            }
                                %>
                                <div class="curso-card">
                                    <% if (!imagenBase64.isEmpty()) {%>
                                    <img src="<%= imagenBase64%>" class="curso-imagen" alt="<%= nombreCurso%>">
                                    <% } else { %>
                                    <div class="curso-imagen-placeholder">
                                        <i class="fas fa-book"></i>
                                    </div>
                                    <% }%>
                                    <div class="card-body">
                                        <h5 class="card-title"><%= nombreCurso%></h5>
                                        <p>
                                            <span class="badge badge-primary"><%= codigoCurso%></span>
                                            <span class="badge badge-creditos"><%= creditos%> créditos</span>
                                        </p>
                                        <div style="margin-top: 1rem;">
                                            <% if ("PENDIENTE".equals(pendingLeaveStatus)) { %>
                                            <button class="btn btn-outline-danger" disabled>
                                                <i class="fas fa-clock me-2"></i>Solicitud de salida pendiente
                                            </button>
                                            <% } else {%>
                                            <a href="?action=salir&id_curso=<%= idCurso%>"
                                               class="btn btn-outline-danger"
                                               onclick="return confirm('¿Seguro que deseas solicitar salir de <%= nombreCurso%>? Esto requerirá aprobación.')">
                                                <i class="fas fa-sign-out-alt me-2"></i>Solicitar Salir
                                            </a>
                                            <% } %>
                                        </div>
                                    </div>
                                </div>
                                <%
                                        }

                                        if (!tieneCursos) {
                                %>
                                <div class="empty-state">
                                    <i class="fas fa-clipboard-list"></i>
                                    <h4>No tienes cursos asignados actualmente.</h4>
                                    <p>Explora la pestaña "Cursos Disponibles" para unirte a nuevos.</p>
                                </div>
                                <%
                                        }
                                    } catch (SQLException e) {
                                %>
                                <div class="alert alert-danger" role="alert">
                                    <i class="fas fa-exclamation-triangle me-2"></i>Error al cargar tus cursos: <%= e.getMessage()%>
                                </div>
                                <%
                                    } finally {
                                        // Asegurarse de no cerrar 'conn' si se usó la conexión principal
                                        if (localConnMisCursos != conn) {
                                            closeDbResources(localRsMisCursos, localPstmtMisCursos);
                                            try { if (localConnMisCursos != null) localConnMisCursos.close(); } catch (SQLException e) {}
                                        } else {
                                            closeDbResources(localRsMisCursos, localPstmtMisCursos);
                                        }
                                    }
                                %>
                            </div>
                        </div>

                        <div class="tab-pane fade" id="disponibles" role="tabpanel" aria-labelledby="disponibles-tab">
                            <div class="cursos-grid">
                                <%
                                    // RE-OBTENER LA CONEXIÓN PARA ESTE BLOQUE DE CÓDIGO
                                    Connection localConnDisponibles = null;
                                    PreparedStatement localPstmtDisponibles = null;
                                    ResultSet localRsDisponibles = null;
                                    try {
                                        if (conn == null || conn.isClosed()) { // Reabrir si se cerró por error
                                            Conection c = new Conection();
                                            localConnDisponibles = c.conecta();
                                        } else {
                                            localConnDisponibles = conn; // Usar la conexión existente
                                        }

                                        String sqlDisponibles = "SELECT c.id_curso, c.nombre_curso, c.codigo_curso, c.creditos, "
                                                                + "c.imagen, c.tipo_imagen, car.nombre_carrera, "
                                                                + "(SELECT estado FROM solicitudes_cursos sc WHERE sc.id_profesor = ? AND sc.id_curso = c.id_curso AND sc.tipo_solicitud = 'UNIRSE' ORDER BY sc.fecha_solicitud DESC LIMIT 1) as pending_join_status "
                                                                + "FROM cursos c "
                                                                + "INNER JOIN carreras car ON c.id_carrera = car.id_carrera "
                                                                + "INNER JOIN facultades f ON car.id_facultad = f.id_facultad "
                                                                + "INNER JOIN profesores p ON p.id_facultad = f.id_facultad "
                                                                + "WHERE p.id_profesor = ? "
                                                                + "AND c.id_curso NOT IN (SELECT pc.id_curso FROM profesor_curso pc WHERE pc.id_profesor = ?) "
                                                                + "ORDER BY c.nombre_curso";
                                        localPstmtDisponibles = localConnDisponibles.prepareStatement(sqlDisponibles);
                                        localPstmtDisponibles.setInt(1, idProfesor);
                                        localPstmtDisponibles.setInt(2, idProfesor);
                                        localPstmtDisponibles.setInt(3, idProfesor);
                                        localRsDisponibles = localPstmtDisponibles.executeQuery();

                                        boolean hayDisponibles = false;
                                        while (localRsDisponibles.next()) {
                                            hayDisponibles = true;
                                            int idCurso = localRsDisponibles.getInt("id_curso");
                                            String nombreCurso = localRsDisponibles.getString("nombre_curso");
                                            String codigoCurso = localRsDisponibles.getString("codigo_curso");
                                            int creditos = localRsDisponibles.getInt("creditos");
                                            String nombreCarrera = localRsDisponibles.getString("nombre_carrera");
                                            byte[] imagen = localRsDisponibles.getBytes("imagen");
                                            String tipoImagen = localRsDisponibles.getString("tipo_imagen");
                                            String pendingJoinStatus = localRsDisponibles.getString("pending_join_status");

                                            String imagenBase64 = "";
                                            if (imagen != null && imagen.length > 0) {
                                                imagenBase64 = "data:" + tipoImagen + ";base64," + Base64.getEncoder().encodeToString(imagen);
                                            }
                                %>
                                <div class="curso-card">
                                    <% if (!imagenBase64.isEmpty()) {%>
                                    <img src="<%= imagenBase64%>" class="curso-imagen" alt="<%= nombreCurso%>">
                                    <% } else { %>
                                    <div class="curso-imagen-placeholder">
                                        <i class="fas fa-book"></i>
                                    </div>
                                    <% }%>
                                    <div class="card-body">
                                        <h5 class="card-title"><%= nombreCurso%></h5>
                                        <p class="text-muted" style="font-size: 0.9em; margin-bottom: 0.5rem;">
                                            <i class="fas fa-building"></i> <%= nombreCarrera%>
                                        </p>
                                        <p>
                                            <span class="badge badge-primary"><%= codigoCurso%></span>
                                            <span class="badge badge-creditos"><%= creditos%> créditos</span>
                                        </p>
                                        <div style="margin-top: 1rem;">
                                            <% if ("PENDIENTE".equals(pendingJoinStatus)) { %>
                                            <button class="btn btn-primary" disabled>
                                                <i class="fas fa-clock me-2"></i>Solicitud de unión pendiente
                                            </button>
                                            <% } else {%>
                                            <a href="?action=unirse&id_curso=<%= idCurso%>"
                                               class="btn btn-primary"
                                               onclick="return confirm('¿Seguro que deseas solicitar unirte a <%= nombreCurso%>? Esto requerirá aprobación.')">
                                                <i class="fas fa-user-plus me-2"></i>Solicitar Unirse
                                            </a>
                                            <% } %>
                                        </div>
                                    </div>
                                </div>
                                <%
                                        }

                                        if (!hayDisponibles) {
                                %>
                                <div class="empty-state">
                                    <i class="fas fa-check-circle" style="color: var(--admin-success);"></i>
                                    <h4>¡Estás asignado a todos los cursos disponibles!</h4>
                                    <p>No hay más cursos de tu facultad disponibles para unirte.</p>
                                </div>
                                <%
                                        }
                                    } catch (SQLException e) {
                                %>
                                <div class="alert alert-danger" role="alert">
                                    <i class="fas fa-exclamation-triangle me-2"></i>Error al cargar cursos disponibles: <%= e.getMessage()%>
                                </div>
                                <%
                                    } finally {
                                        // Asegurarse de no cerrar 'conn' si se usó la conexión principal
                                        if (localConnDisponibles != conn) {
                                            closeDbResources(localRsDisponibles, localPstmtDisponibles);
                                            try { if (localConnDisponibles != null) localConnDisponibles.close(); } catch (SQLException e) {}
                                        } else {
                                            closeDbResources(localRsDisponibles, localPstmtDisponibles);
                                        }
                                    }
                                %>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js" integrity="sha384-YvpcrYf0tY3lHB60NNkmXc5s9fDVZLESaAA55NDzOxhy9GkcIdslK1eN7N6jIeHz" crossorigin="anonymous"></script>
</body>
</html>