<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, pe.universidad.util.Conection" %>
<%@ page import="java.time.LocalDate, java.time.format.TextStyle, java.util.Locale" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.net.URLEncoder" %>
<%@ page session="true" %>

<%!
    // Método auxiliar para cerrar ResultSet y PreparedStatement
    private void closeDbResources(ResultSet rs, PreparedStatement pstmt) {
        try {
            if (rs != null) {
                rs.close();
            }
        } catch (SQLException e) {
            /* Ignorar al cerrar */ }
        try {
            if (pstmt != null) {
                pstmt.close();
            }
        } catch (SQLException e) {
            /* Ignorar al cerrar */ }
    }
%>

<%
    // ====================================================================
    // 🧪 FORZAR SESIÓN TEMPORALMENTE PARA APODERADO (SOLO PARA TEST)
    // REMOVER ESTE BLOQUE EN PRODUCCIÓN O CUANDO EL LOGIN REAL FUNCIONE
    if (session.getAttribute("id_apoderado") == null) {
        session.setAttribute("email", "roberto.sanchez@gmail.com"); // Email de un apoderado que exista en tu BD (ID 1 en bd-uni.sql)
        session.setAttribute("rol", "apoderado");
        session.setAttribute("id_apoderado", 1);    // ID del apoderado en tu BD (ej: Roberto Carlos Sánchez Díaz)
        System.out.println("DEBUG (mensajes_apoderado): Sesión forzada para prueba.");
    }
    // ====================================================================

    // --- Bloque de Control Principal y Carga de Datos ---
    String emailSesion = (String) session.getAttribute("email");
    String rolUsuario = (String) session.getAttribute("rol");
    Object idApoderadoObj = session.getAttribute("id_apoderado");

    // Redirigir si el usuario no está logueado, no es apoderado o no tiene un ID de apoderado en sesión
    if (emailSesion == null || !"apoderado".equalsIgnoreCase(rolUsuario) || idApoderadoObj == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp"); // Adjust this path
        return;
    }

    // Datos del apoderado logueado
    int idApoderado = -1;
    try {
        idApoderado = Integer.parseInt(String.valueOf(idApoderadoObj));
    } catch (NumberFormatException e) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?error=" + URLEncoder.encode("ID de apoderado inválido en sesión.", "UTF-8"));
        return;
    }

    String nombreApoderado = "";
    String emailApoderado = emailSesion;
    int idHijoAsociado = -1; // Usaremos este para filtrar los profesores

    // Variables para contadores de notificaciones
    int totalUnreadMessages = 0;
    int totalSentMessages = 0;
    int totalReceivedMessages = 0;
    int totalHijoActiveCourses = 0; // Cambiado de 'Clases Activas' a 'Cursos Activos del Hijo'

    Connection conn = null;

    try {
        // --- Establish Database Connection ---
        conn = new Conection().conecta();

        if (conn == null || conn.isClosed()) {
            throw new SQLException("No se pudo establecer conexión a la base de datos.");
        }

        // --- 1. Get detailed apoderado information and associated child ID ---
        PreparedStatement pstmtApoderadoInfo = null;
        ResultSet rsApoderadoInfo = null;
        try {
            String sqlApoderadoInfo = "SELECT CONCAT(a.nombre, ' ', a.apellido_paterno, ' ', IFNULL(a.apellido_materno, '')) AS nombre_completo "
                                    + "FROM apoderados a WHERE a.id_apoderado = ?";
            pstmtApoderadoInfo = conn.prepareStatement(sqlApoderadoInfo);
            pstmtApoderadoInfo.setInt(1, idApoderado);
            rsApoderadoInfo = pstmtApoderadoInfo.executeQuery();

            if (rsApoderadoInfo.next()) {
                nombreApoderado = rsApoderadoInfo.getString("nombre_completo");
            } else {
                response.sendRedirect(request.getContextPath() + "/login.jsp?error=" + URLEncoder.encode("Apoderado no encontrado.", "UTF-8"));
                return;
            }
        } finally {
            closeDbResources(rsApoderadoInfo, pstmtApoderadoInfo);
        }

        // Get the ID of the associated child (assuming one child per apoderado for this simple example)
        PreparedStatement pstmtHijoId = null;
        ResultSet rsHijoId = null;
        try {
            String sqlGetHijoId = "SELECT id_alumno FROM alumno_apoderado WHERE id_apoderado = ? LIMIT 1";
            pstmtHijoId = conn.prepareStatement(sqlGetHijoId);
            pstmtHijoId.setInt(1, idApoderado);
            rsHijoId = pstmtHijoId.executeQuery();
            if (rsHijoId.next()) {
                idHijoAsociado = rsHijoId.getInt("id_alumno");
            }
        } finally {
            closeDbResources(rsHijoId, pstmtHijoId);
        }

        // --- 2. Load Notification Counters ---
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        try {
            // Count unread messages (for navbar badge and stat card) for APODERADO
            String sqlUnreadMessagesCount = "SELECT COUNT(*) FROM mensajes WHERE id_destinatario = ? AND tipo_destinatario = 'apoderado' AND leido = FALSE";
            pstmt = conn.prepareStatement(sqlUnreadMessagesCount);
            pstmt.setInt(1, idApoderado);
            rs = pstmt.executeQuery();
            if (rs.next()) {
                totalUnreadMessages = rs.getInt(1);
            }
            closeDbResources(rs, pstmt);

            // Count total sent messages by this apoderado
            String sqlTotalSent = "SELECT COUNT(*) FROM mensajes WHERE id_remitente = ? AND tipo_remitente = 'apoderado'";
            pstmt = conn.prepareStatement(sqlTotalSent);
            pstmt.setInt(1, idApoderado);
            rs = pstmt.executeQuery();
            if (rs.next()) {
                totalSentMessages = rs.getInt(1);
            }
            closeDbResources(rs, pstmt);

            // Count total received messages for this apoderado
            String sqlTotalReceived = "SELECT COUNT(*) FROM mensajes WHERE id_destinatario = ? AND tipo_destinatario = 'apoderado'";
            pstmt = conn.prepareStatement(sqlTotalReceived);
            pstmt.setInt(1, idApoderado);
            rs = pstmt.executeQuery();
            if (rs.next()) {
                totalReceivedMessages = rs.getInt(1);
            }
            closeDbResources(rs, pstmt);

            // Count total active courses for the associated child
            if (idHijoAsociado != -1) {
                String sqlTotalHijoCourses = "SELECT COUNT(DISTINCT cl.id_curso) FROM inscripciones i "
                                            + "JOIN clases cl ON i.id_clase = cl.id_clase "
                                            + "WHERE i.id_alumno = ? AND cl.estado = 'activo'";
                pstmt = conn.prepareStatement(sqlTotalHijoCourses);
                pstmt.setInt(1, idHijoAsociado);
                rs = pstmt.executeQuery();
                if (rs.next()) {
                    totalHijoActiveCourses = rs.getInt(1);
                }
            }
            closeDbResources(rs, pstmt);

        } finally {
            // Resources already closed in inner blocks
        }

    } catch (Exception e) {
        System.err.println("ERROR general en mensajes_apoderado.jsp: " + e.getMessage());
        e.printStackTrace();
        response.sendRedirect(request.getContextPath() + "/error.jsp?message=" + URLEncoder.encode("Error inesperado al cargar la página de mensajería: " + e.getMessage(), "UTF-8"));
        return;
    } finally {
        // Final closure of 'conn' connection
        if (conn != null) {
            try {
                conn.close();
            } catch (SQLException ignore) {
            }
        }
    }
%>

<!DOCTYPE html>
<html lang="es">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Mensajería del Apoderado - Sistema Universitario</title>
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous">
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
        <style>
            /* CSS de AdminKit Pro para consistencia */
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
                display: flex;
                flex-direction: column;
                overflow-x: hidden;
            }

            #app {
                display: flex;
                flex: 1;
                width: 100%;
            }

            /* Sidebar */
            .sidebar {
                width: 280px;
                background-color: var(--admin-dark);
                color: rgba(255, 255, 255, 0.8);
                padding-top: 1rem;
                flex-shrink: 0;
                position: sticky;
                top: 0;
                left: 0;
                height: 100vh;
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

            /* Stat Cards for Messaging Overview */
            .stat-card .card-body {
                padding: 1.25rem;
            }
            .stat-card .card-title {
                color: var(--admin-text-muted);
                font-size: 1rem;
                margin-bottom: 0.5rem;
                font-weight: 500;
            }
            .stat-card .value {
                font-size: 2.2rem;
                font-weight: 700;
                color: var(--admin-text-dark);
                margin-bottom: 0.25rem;
            }
            .stat-card .description {
                font-size: 0.85rem;
                color: var(--admin-text-muted);
            }
            .stat-card .icon-wrapper {
                background-color: var(--admin-primary); /* Default */
                color: white;
                padding: 0.75rem;
                border-radius: 0.5rem;
                font-size: 1.5rem;
                display: inline-flex;
                align-items: center;
                justify-content: center;
                margin-bottom: 1rem;
                width: 50px;
                height: 50px;
            }
            .stat-card.messages-sent .icon-wrapper {
                background-color: var(--admin-primary);
            } /* Blue */
            .stat-card.messages-received .icon-wrapper {
                background-color: var(--admin-info);
            } /* Cyan */
            .stat-card.active-courses .icon-wrapper { /* Changed class name */
                background-color: var(--admin-success);
            } /* Green */


            /* Message Sections */
            .message-section.card {
                border-radius: 0.5rem;
                box-shadow: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.075);
                margin-bottom: 1.5rem;
            }
            .message-section.enviar {
                border-left: 4px solid var(--admin-primary);
            }
            .message-section.recibidos {
                border-left: 4px solid var(--admin-info); /* Different color for received messages */
            }
            .message-section h2 {
                color: var(--admin-primary);
                font-weight: 600;
                margin-bottom: 1.5rem;
                display: flex;
                align-items: center;
                gap: 0.75rem;
            }

            /* Table Styling */
            .table {
                color: var(--admin-text-dark);
            }
            .table thead th {
                border-bottom: 2px solid var(--admin-primary);
                color: var(--admin-primary);
                font-weight: 600;
                background-color: var(--admin-light-bg);
                position: sticky; /* Make header sticky */
                top: 0; /* Stick to the top of its scrolling container */
                z-index: 1; /* Ensure it stays above table body */
            }
            .table tbody tr:hover {
                background-color: rgba(0, 123, 255, 0.05);
            }
            .table-sm th, .table-sm td {
                padding: 0.5rem;
            }

            /* Badge Styles */
            .badge {
                font-weight: 500;
                border-radius: 0.25rem;
                padding: 0.35em 0.65em;
            }
            /* Custom badges with light backgrounds and colored text/borders */
            .badge-success-custom {
                background-color: rgba(40, 167, 69, 0.1);
                color: var(--admin-success);
                border: 1px solid var(--admin-success);
            }
            .badge-primary-custom {
                background-color: rgba(0, 123, 255, 0.1);
                color: var(--admin-primary);
                border: 1px solid var(--admin-primary);
            }
            .badge-secondary-custom {
                background-color: rgba(108, 117, 125, 0.1);
                color: var(--admin-secondary-color);
                border: 1px solid var(--admin-secondary-color);
            }
            .badge-info-custom {
                background-color: rgba(23, 162, 184, 0.1);
                color: var(--admin-info);
                border: 1px solid var(--admin-info);
            }
            .badge-read-custom {
                background-color: rgba(108, 117, 125, 0.1);
                color: var(--admin-secondary-color);
                border: 1px solid var(--admin-secondary-color);
            }
            .badge-unread-custom {
                background-color: rgba(0, 123, 255, 0.1);
                color: var(--admin-primary);
                border: 1px solid var(--admin-primary);
            }


            /* Teacher Selection Cards (for "Send Messages to Teachers") */
            .teacher-select-card { /* Changed class name */
                cursor: pointer;
                transition: all 0.2s ease-in-out;
                border: 1px solid #e0e0e0; /* subtle border */
                border-left: 5px solid var(--admin-primary); /* highlight color */
                background-color: var(--admin-card-bg);
                border-radius: 0.5rem;
                padding: 1rem;
                display: flex;
                flex-direction: column;
                justify-content: space-between;
            }
            .teacher-select-card:hover { /* Changed class name */
                transform: translateY(-3px);
                box-shadow: 0 0.25rem 0.5rem rgba(0,0,0,0.1);
                border-color: var(--admin-info); /* stronger highlight on hover */
            }
            .teacher-select-card .card-title { /* Changed class name */
                font-weight: 600;
                color: var(--admin-primary);
                margin-bottom: 0.5rem;
            }
            .teacher-select-card .card-text { /* Changed class name */
                font-size: 0.9rem;
                color: var(--admin-text-muted);
                margin-bottom: 0.25rem;
            }
            .teacher-select-card .action-link { /* Changed class name */
                text-align: right;
                margin-top: 1rem;
            }
            .teacher-select-card .action-link .btn { /* Changed class name */
                font-size: 0.9rem;
                padding: 0.5rem 1rem;
            }

            /* Empty State */
            .empty-state {
                text-align: center;
                padding: 3rem 1rem;
                color: var(--admin-text-muted);
            }
            .empty-state i {
                font-size: 3rem;
                margin-bottom: 1rem;
                color: var(--admin-secondary-color);
            }
            .empty-state h4 {
                color: var(--admin-text-dark);
                font-weight: 500;
                margin-bottom: 1rem;
            }


            /* Modal for viewing messages */
            .modal-header.bg-primary {
                background-color: var(--admin-primary) !important;
            }
            .modal-header .btn-close-white {
                filter: invert(1) grayscale(100%) brightness(200%); /* Makes close button white */
            }
            #modalMessageContenido {
                background-color: var(--admin-light-bg);
                border-color: var(--admin-info);
                padding: 1rem;
                border-radius: 0.3rem;
                font-size: 0.95rem;
                white-space: pre-wrap; /* Preserve formatting and wrap text */
                word-break: break-word; /* Break long words */
            }

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
                .stat-card {
                    margin-bottom: 1rem;
                } /* Add margin for stacking on smaller screens */
            }

            @media (max-width: 576px) {
                .main-content {
                    padding: 0.75rem;
                }
                .welcome-section, .card {
                    padding: 1rem;
                }
                /* Adjust grid for stat cards if needed, auto-fit might handle it */
                .row-cols-md-2 > .col {
                    flex: 0 0 100%;
                    max-width: 100%;
                } /* Force single column on smaller phones for cards */
            }
        </style>
    </head>
    <body>
        <div id="app">
            <nav class="sidebar">
                <div class="sidebar-header">
                    <a href="<%= request.getContextPath()%>/INTERFAZ_APODERADO/home_apoderado.jsp" class="text-white text-decoration-none">UGIC Portal</a>
                </div>

                <ul class="navbar-nav">
                    <li class="nav-item">
                        <a class="nav-link" href="<%= request.getContextPath()%>/INTERFAZ_APODERADO/home_apoderado.jsp"><i class="fas fa-home"></i><span> Inicio</span></a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="<%= request.getContextPath()%>/INTERFAZ_APODERADO/cursos_apoderado.jsp"><i class="fas fa-book"></i><span> Cursos de mi hijo</span></a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="<%= request.getContextPath()%>/INTERFAZ_APODERADO/asistencia_apoderado.jsp"><i class="fas fa-clipboard-check"></i><span> Asistencia de mi hijo</span></a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="<%= request.getContextPath()%>/INTERFAZ_APODERADO/notas_apoderado.jsp"><i class="fas fa-percent"></i><span> Notas de mi hijo</span></a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="<%= request.getContextPath()%>/INTERFAZ_APODERADO/pagos_apoderado.jsp"><i class="fas fa-money-bill-wave"></i><span> Pagos y Mensualidades</span></a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link active" href="<%= request.getContextPath()%>/INTERFAZ_APODERADO/mensajes_apoderado.jsp"><i class="fas fa-envelope"></i><span> Mensajes</span></a>
                    </li>
                    <li class="nav-item mt-3">
                        <form action="<%= request.getContextPath()%>/logout.jsp" method="post" class="d-grid gap-2">
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
                            <a class="text-dark" href="#" role="button" id="notificationsDropdown" data-bs-toggle="dropdown" aria-expanded="false">
                                <i class="fas fa-bell fa-lg"></i>
                                <span class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger">
                                    <%= totalUnreadMessages > 0 ? totalUnreadMessages : ""%> <%-- Using unread messages for notification badge --%>
                                </span>
                            </a>
                            <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="notificationsDropdown">
                                <li><a class="dropdown-item" href="<%= request.getContextPath()%>/INTERFAZ_APODERADO/mensajes_apoderado.jsp#message-table-section">Tienes <%= totalUnreadMessages%> mensajes no leídos</a></li>
                                <li><hr class="dropdown-divider"></li>
                                <li><a class="dropdown-item" href="<%= request.getContextPath()%>/INTERFAZ_APODERADO/mensajes_apoderado.jsp">Ver todos los mensajes</a></li>
                            </ul>
                        </div>
                        <div class="me-3 dropdown">
                            <a class="text-dark" href="#" role="button" id="messagesDropdown" data-bs-toggle="dropdown" aria-expanded="false">
                                <i class="fas fa-envelope fa-lg"></i>
                                <span class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger">
                                    <%= totalUnreadMessages > 0 ? totalUnreadMessages : ""%>
                                </span>
                            </a>
                            <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="messagesDropdown">
                                <li><a class="dropdown-item" href="<%= request.getContextPath()%>/INTERFAZ_APODERADO/mensajes_apoderado.jsp#message-table-section">Tienes <%= totalUnreadMessages%> mensajes no leídos</a></li>
                                <li><hr class="dropdown-divider"></li>
                                <li><a class="dropdown-item" href="<%= request.getContextPath()%>/INTERFAZ_APODERADO/mensajes_apoderado.jsp">Ver todos los mensajes</a></li>
                            </ul>
                        </div>

                        <div class="dropdown user-dropdown">
                            <a class="dropdown-toggle" href="#" role="button" id="userDropdown" data-bs-toggle="dropdown" aria-expanded="false">
                                <img src="https://via.placeholder.com/32" alt="Avatar"> <span class="d-none d-md-inline-block"><%= nombreApoderado%></span>
                            </a>
                            <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="userDropdown">
                                <li><a class="dropdown-item" href="perfil_apoderado.jsp"><i class="fas fa-user me-2"></i>Perfil</a></li>
                                <li><a class="dropdown-item" href="configuracion_apoderado.jsp"><i class="fas fa-cog me-2"></i>Configuración</a></li>
                                <li><hr class="dropdown-divider"></li>
                                <li><a class="dropdown-item" href="<%= request.getContextPath()%>/logout.jsp"><i class="fas fa-sign-out-alt me-2"></i>Cerrar sesión</a></li>
                            </ul>
                        </div>
                    </div>
                </nav>

                <div class="container-fluid">
                    <div class="welcome-section">
                        <h1 class="h3 mb-3"><i class="fas fa-comments me-2"></i>Panel de Mensajería</h1>
                        <p class="lead">Envía y revisa mensajes con los profesores de tu hijo/a.</p>
                    </div>

                    <div class="row">
                        <div class="col-md-4 col-sm-6 mb-4">
                            <div class="card stat-card messages-sent">
                                <div class="card-body">
                                    <div class="row align-items-center">
                                        <div class="col-auto">
                                            <div class="icon-wrapper bg-primary text-white">
                                                <i class="fas fa-paper-plane"></i>
                                            </div>
                                        </div>
                                        <div class="col">
                                            <h3 class="card-title">Mensajes Enviados</h3>
                                            <div class="value" id="stat-msg-enviados">0</div>
                                            <p class="card-text description text-muted">Total de mensajes salientes.</p>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="col-md-4 col-sm-6 mb-4">
                            <div class="card stat-card messages-received">
                                <div class="card-body">
                                    <div class="row align-items-center">
                                        <div class="col-auto">
                                            <div class="icon-wrapper bg-info text-white">
                                                <i class="fas fa-inbox"></i>
                                            </div>
                                        </div>
                                        <div class="col">
                                            <h3 class="card-title">Mensajes Recibidos</h3>
                                            <div class="value" id="stat-msg-recibidos">0</div>
                                            <p class="card-text description text-muted">Mensajes en tu bandeja de entrada.</p>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="col-md-4 col-sm-6 mb-4">
                            <div class="card stat-card active-courses"> <%-- Changed class name here --%>
                                <div class="card-body">
                                    <div class="row align-items-center">
                                        <div class="col-auto">
                                            <div class="icon-wrapper bg-success text-white">
                                                <i class="fas fa-book-open"></i> <%-- Changed icon --%>
                                            </div>
                                        </div>
                                        <div class="col">
                                            <h3 class="card-title">Cursos de mi Hijo</h3> <%-- Changed title --%>
                                            <div class="value" id="stat-hijo-cursos-activos">0</div> <%-- Changed ID --%>
                                            <p class="card-text description text-muted">Cursos activos de tu hijo/a.</p>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="row">
                        <div class="col-12 mb-4">
                            <div class="card content-section enviar">
                                <div class="card-body">
                                    <h2 class="section-title"><i class="fas fa-paper-plane me-2"></i>Enviar Mensajes a Profesores</h2>
                                    <p class="text-muted mb-4">Selecciona un profesor de los cursos de tu hijo/a para enviarle un mensaje.</p>

                                    <%
                                        PreparedStatement pstmtProfesores = null;
                                        ResultSet rsProfesores = null;
                                        boolean hayProfesoresParaEnviarMensajes = false;
                                        List<Map<String, String>> profesoresParaMensajes = new ArrayList<>(); // Store teachers for card display
                                        try {
                                            if (conn == null || conn.isClosed()) {
                                                conn = new Conection().conecta();
                                            }

                                            if (conn != null && !conn.isClosed() && idHijoAsociado != -1) {
                                                String sqlProfesores = "SELECT DISTINCT p.id_profesor, CONCAT(p.nombre, ' ', p.apellido_paterno, ' ', IFNULL(p.apellido_materno, '')) AS nombre_completo_profesor, "
                                                                        + "p.email AS email_profesor, cu.nombre_curso, cl.seccion "
                                                                        + "FROM profesores p "
                                                                        + "JOIN clases cl ON p.id_profesor = cl.id_profesor "
                                                                        + "JOIN inscripciones i ON cl.id_clase = i.id_clase "
                                                                        + "JOIN cursos cu ON cl.id_curso = cu.id_curso "
                                                                        + "WHERE i.id_alumno = ? AND cl.estado = 'activo' "
                                                                        + "ORDER BY nombre_completo_profesor, cu.nombre_curso";

                                                pstmtProfesores = conn.prepareStatement(sqlProfesores);
                                                pstmtProfesores.setInt(1, idHijoAsociado); // Filter by child's ID
                                                rsProfesores = pstmtProfesores.executeQuery();

                                                // Group teachers by ID to avoid duplicate cards for teachers teaching multiple courses
                                                Map<Integer, Map<String, String>> uniqueProfesores = new LinkedHashMap<>(); // To maintain order and uniqueness
                                                while (rsProfesores.next()) {
                                                    hayProfesoresParaEnviarMensajes = true;
                                                    int profId = rsProfesores.getInt("id_profesor");
                                                    String profNombre = rsProfesores.getString("nombre_completo_profesor");
                                                    String profEmail = rsProfesores.getString("email_profesor");
                                                    String cursoNombre = rsProfesores.getString("nombre_curso");
                                                    String seccion = rsProfesores.getString("seccion");

                                                    uniqueProfesores.computeIfAbsent(profId, k -> {
                                                        Map<String, String> teacherData = new HashMap<>();
                                                        teacherData.put("id_profesor", String.valueOf(profId));
                                                        teacherData.put("nombre_completo", profNombre);
                                                        teacherData.put("email", profEmail);
                                                        teacherData.put("cursos", ""); // Initialize courses string
                                                        return teacherData;
                                                    });

                                                    Map<String, String> teacherData = uniqueProfesores.get(profId);
                                                    String currentCourses = teacherData.get("cursos");
                                                    if (!currentCourses.isEmpty()) {
                                                        teacherData.put("cursos", currentCourses + ", " + cursoNombre + " (Sección " + seccion + ")");
                                                    } else {
                                                        teacherData.put("cursos", cursoNombre + " (Sección " + seccion + ")");
                                                    }
                                                }
                                                profesoresParaMensajes.addAll(uniqueProfesores.values());
                                            }
                                        } catch (SQLException e) {
                                            out.println("<div class='alert alert-danger-custom' role='alert'><i class='fas fa-exclamation-triangle me-2'></i>Error al cargar profesores para enviar mensajes: " + e.getMessage() + "</div>");
                                        } finally {
                                            closeDbResources(rsProfesores, pstmtProfesores);
                                        }
                                    %>

                                    <% if (idHijoAsociado == -1) { %>
                                        <div class="empty-state">
                                            <i class="fas fa-child"></i>
                                            <h4>No se encontró un hijo asociado a tu cuenta.</h4>
                                            <p>Por favor, contacta a administración para asociar a tu hijo/a.</p>
                                        </div>
                                    <% } else if (!hayProfesoresParaEnviarMensajes) { %>
                                        <div class="empty-state">
                                            <i class="fas fa-chalkboard-teacher"></i>
                                            <h4>Tu hijo/a no tiene profesores asignados a clases activas.</h4>
                                            <p>No hay docentes disponibles para enviar mensajes en este momento.</p>
                                        </div>
                                    <% } else { %>
                                        <div class="row row-cols-1 row-cols-md-2 row-cols-lg-3 g-4">
                                            <% for (Map<String, String> profesor : profesoresParaMensajes) { %>
                                            <div class="col">
                                                <div class="card h-100 teacher-select-card"> <%-- Changed class name --%>
                                                    <div class="card-body">
                                                        <h5 class="card-title"><%= profesor.get("nombre_completo")%></h5>
                                                        <p class="card-text mb-1"><strong>Email:</strong> <%= profesor.get("email")%></p>
                                                        <p class="card-text mb-2"><strong>Cursos:</strong> <%= profesor.get("cursos")%></p>
                                                    </div>
                                                    <div class="card-footer bg-transparent border-0 text-end pt-0">
                                                        <a href="<%= request.getContextPath()%>/INTERFAZ_APODERADO/enviar_mensaje_apoderado_profesor.jsp?id_profesor=<%= profesor.get("id_profesor")%>&nombre_profesor=<%= URLEncoder.encode(profesor.get("nombre_completo"), "UTF-8")%>&email_profesor=<%= URLEncoder.encode(profesor.get("email"), "UTF-8")%>" class="btn btn-primary btn-sm">
                                                            <i class="fas fa-paper-plane me-1"></i> Enviar Mensaje
                                                        </a>
                                                    </div>
                                                </div>
                                            </div>
                                            <% } %>
                                        </div>
                                    <% } %>
                                </div>
                            </div>
                        </div>

                        <div class="col-12 mb-4">
                            <div class="card message-section recibidos">
                                <div class="card-body">
                                    <h2 class="section-title"><i class="fas fa-inbox me-2"></i>Mensajes Recibidos</h2>

                                    <div class="table-responsive" style="max-height: 600px; overflow-y: auto;">
                                        <table class="table table-hover table-sm">
                                            <caption class="caption-top">Lista de todos los mensajes recibidos</caption>
                                            <thead>
                                                <tr>
                                                    <th scope="col">De</th>
                                                    <th scope="col">Asunto</th>
                                                    <th scope="col">Mensaje (Extracto)</th>
                                                    <th scope="col">Fecha</th>
                                                    <th scope="col" class="text-center">Estado</th>
                                                    <th scope="col" class="text-center">Acción</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                <%
                                                    PreparedStatement pstmtMensajesRecibidos = null;
                                                    ResultSet rsMensajesRecibidos = null;
                                                    boolean hayMensajesRecibidos = false;
                                                    try {
                                                        if (conn == null || conn.isClosed()) {
                                                            conn = new Conection().conecta(); // Reopen if closed
                                                        }

                                                        if (conn != null && !conn.isClosed() && idApoderado != -1) {
                                                            String sqlMensajesRecibidos = "SELECT m.id_mensaje, m.asunto, m.contenido, m.fecha_envio, m.leido, "
                                                                                        + "CASE m.tipo_remitente "
                                                                                        + "    WHEN 'profesor' THEN CONCAT(p.nombre, ' ', p.apellido_paterno) "
                                                                                        + "    WHEN 'admin' THEN a.nombre " // Assuming 'admin' sender has a 'nombre' field
                                                                                        + "    ELSE 'Desconocido' "
                                                                                        + "END AS remitente_nombre, "
                                                                                        + "m.tipo_remitente "
                                                                                        + "FROM mensajes m "
                                                                                        + "LEFT JOIN profesores p ON m.id_remitente = p.id_profesor AND m.tipo_remitente = 'profesor' "
                                                                                        + "LEFT JOIN admin a ON m.id_remitente = a.id_admin AND m.tipo_remitente = 'admin' " // Join for admin senders
                                                                                        + "WHERE m.id_destinatario = ? AND m.tipo_destinatario = 'apoderado' "
                                                                                        + "ORDER BY m.fecha_envio DESC";

                                                            pstmtMensajesRecibidos = conn.prepareStatement(sqlMensajesRecibidos);
                                                            pstmtMensajesRecibidos.setInt(1, idApoderado);
                                                            rsMensajesRecibidos = pstmtMensajesRecibidos.executeQuery();

                                                            while (rsMensajesRecibidos.next()) {
                                                                hayMensajesRecibidos = true;
                                                                int idMensaje = rsMensajesRecibidos.getInt("id_mensaje");
                                                                String remitenteNombreFull = rsMensajesRecibidos.getString("remitente_nombre");
                                                                String asuntoMensaje = rsMensajesRecibidos.getString("asunto");
                                                                String contenidoMensaje = rsMensajesRecibidos.getString("contenido");
                                                                Timestamp fechaEnvio = rsMensajesRecibidos.getTimestamp("fecha_envio");
                                                                boolean leido = rsMensajesRecibidos.getBoolean("leido");
                                                                String tipoRemitente = rsMensajesRecibidos.getString("tipo_remitente");

                                                                String badgeStatusClass = leido ? "badge-read-custom" : "badge-unread-custom";
                                                                String statusText = leido ? "Leído" : "No Leído";
                                                                String displayContent = contenidoMensaje.length() > 70 ? contenidoMensaje.substring(0, 70) + "..." : contenidoMensaje;
                                                                String fullRemitente = remitenteNombreFull + " (" + tipoRemitente + ")";
                                                %>
                                                <tr class="<%= !leido ? "table-primary-subtle" : ""%>"> <%-- Highlight unread messages --%>
                                                    <td>
                                                        <strong><%= remitenteNombreFull != null ? remitenteNombreFull : "N/A"%></strong><br><small class="text-muted">(<%= tipoRemitente%>)</small>
                                                    </td>
                                                    <td><%= asuntoMensaje != null ? asuntoMensaje : "Sin Asunto"%></td>
                                                    <td><%= displayContent != null ? displayContent : "Sin Contenido"%></td>
                                                    <td><%= new SimpleDateFormat("dd/MM/yyyy HH:mm").format(fechaEnvio)%></td>
                                                    <td class="text-center"><span class="badge <%= badgeStatusClass%>"><%= statusText%></span></td>
                                                    <td class="text-center">
                                                        <% if (!leido) {%>
                                                        <form action="<%= request.getContextPath()%>/INTERFAZ_APODERADO/marcar_leido_apoderado.jsp" method="get" class="d-inline-block me-1">
                                                            <input type="hidden" name="id_mensaje" value="<%= idMensaje%>">
                                                            <button type="submit" class="btn btn-primary btn-sm" title="Marcar como leído"><i class="fas fa-check"></i></button>
                                                        </form>
                                                        <% }%>
                                                        <button type="button" class="btn btn-info btn-sm" data-bs-toggle="modal" data-bs-target="#viewMessageModal"
                                                                data-asunto="<%= asuntoMensaje != null ? asuntoMensaje.replace("'", "\\'") : ""%>"
                                                                data-contenido="<%= contenidoMensaje != null ? contenidoMensaje.replace("'", "\\'") : ""%>"
                                                                data-remitente="<%= fullRemitente.replace("'", "\\'")%>"
                                                                data-fecha="<%= new SimpleDateFormat("dd/MM/yyyy HH:mm").format(fechaEnvio)%>">
                                                            <i class="fas fa-eye"></i>
                                                        </button>
                                                    </td>
                                                </tr>
                                                <%
                                                            } // End while
                                                        } // End if (conn != null...)

                                                        if (!hayMensajesRecibidos) {
                                                %>
                                                <tr>
                                                    <td colspan="6" class="empty-state">
                                                        <i class="fas fa-inbox"></i>
                                                        <h4>Bandeja de entrada vacía. No hay mensajes recibidos.</h4>
                                                        <p>¡Esperando tus mensajes!</p>
                                                    </td>
                                                </tr>
                                                <%
                                                        }
                                                    } catch (SQLException e) {
                                                        out.println("<tr><td colspan='6' class='alert alert-danger text-center' role='alert'><i class='fas fa-exclamation-triangle me-2'></i>Error al cargar mensajes recibidos: " + e.getMessage() + "</td></tr>");
                                                    } finally {
                                                        closeDbResources(rsMensajesRecibidos, pstmtMensajesRecibidos);
                                                    }
                                                %>
                                            </tbody>
                                        </table>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                </div>
            </div>
        </div>

        <div class="modal fade" id="viewMessageModal" tabindex="-1" aria-labelledby="viewMessageModalLabel" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered modal-lg">
                <div class="modal-content">
                    <div class="modal-header bg-primary text-white">
                        <h5 class="modal-title" id="viewMessageModalLabel"><i class="fas fa-envelope-open-text me-2"></i>Mensaje de: <span id="modalMessageRemitente"></span></h5>
                        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>
                    <div class="modal-body">
                        <p class="mb-1"><strong>Asunto:</strong> <span id="modalMessageAsunto"></span></p>
                        <p class="mb-3"><strong>Fecha:</strong> <span id="modalMessageFecha"></span></p>
                        <hr>
                        <p class="fw-bold">Contenido:</p>
                        <div id="modalMessageContenido" class="alert alert-info"></div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cerrar</button>
                    </div>
                </div>
            </div>
        </div>

        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js" integrity="sha384-YvpcrYf0tY3lHB60NNkmXc5s9fDVZLESaAA55NDzOxhy9GkcIdslK1eN7N6jIeHz" crossorigin="anonymous"></script>
        <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.6.0/jquery.min.js"></script>
        <script>
            $(document).ready(function () {
                // Animación de contadores al cargar la página
                function animateValue(id, start, end, duration) {
                    let range = end - start;
                    let current = start;
                    let increment = end > start ? 1 : -1;
                    let stepTime = Math.abs(Math.floor(duration / range));
                    const obj = document.getElementById(id);
                    if (!obj)
                        return;

                    function step() {
                        current += increment;
                        obj.textContent = current;
                        if (current != end)
                            setTimeout(step, stepTime);
                    }
                    obj.textContent = start;
                    if (start !== end)
                        step(); // Only animate if start and end are different
                }

                // Pass the counts from JSP to JavaScript directly
                const totalSentMessages = <%= totalSentMessages%>;
                const totalReceivedMessages = <%= totalReceivedMessages%>;
                const totalHijoActiveCourses = <%= totalHijoActiveCourses%>; // Changed variable name

                animateValue("stat-msg-enviados", 0, totalSentMessages, 1000);
                animateValue("stat-msg-recibidos", 0, totalReceivedMessages, 1000);
                animateValue("stat-hijo-cursos-activos", 0, totalHijoActiveCourses, 1000); // Changed ID

                // Handler for the "View" message button (opens the modal)
                $('#viewMessageModal').on('show.bs.modal', function (event) {
                    const button = $(event.relatedTarget); // Button that triggered the modal
                    const asunto = button.data('asunto');
                    const contenido = button.data('contenido');
                    const remitente = button.data('remitente');
                    const fecha = button.data('fecha');

                    const modal = $(this);
                    modal.find('#modalMessageRemitente').text(remitente);
                    modal.find('#modalMessageAsunto').text(asunto);
                    modal.find('#modalMessageFecha').text(fecha);
                    modal.find('#modalMessageContenido').text(contenido);
                });
            });
        </script>
    </body>