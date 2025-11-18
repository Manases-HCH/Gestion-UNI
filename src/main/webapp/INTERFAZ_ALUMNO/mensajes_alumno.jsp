<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, pe.universidad.util.Conection" %>
<%@ page import="java.time.LocalDate, java.time.format.TextStyle, java.util.Locale" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.net.URLEncoder" %>
<%@ page session="true" %>
<%@ page import="java.nio.charset.StandardCharsets" %>
<%@ page import="java.time.LocalDateTime" %>

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
            return ""; // Return empty string for null to prevent "null" literal in JS
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
                    if (ch < 32 || ch > 126) {
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
    Object idAlumnoObj = session.getAttribute("id_alumno");

    int idAlumno = -1;
    try {
        if (idAlumnoObj != null) {
            idAlumno = Integer.parseInt(String.valueOf(idAlumnoObj));
        }
    } catch (NumberFormatException e) {
        System.err.println("ERROR: ID de alumno en sesión no es un número válido. Redirigiendo a login. " + e.getMessage());
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    if (emailSesion == null || !"alumno".equalsIgnoreCase(rolUsuario) || idAlumno == -1) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    String nombreAlumno = (String) session.getAttribute("nombre_alumno");
    if (nombreAlumno == null || nombreAlumno.isEmpty()) {
        Connection connTemp = null;
        PreparedStatement pstmtTemp = null;
        ResultSet rsTemp = null;
        try {
            connTemp = new Conection    ().conecta();
            String sqlGetNombre = "SELECT CONCAT(nombre, ' ', apellido_paterno, ' ', IFNULL(apellido_materno, '')) AS nombre_completo FROM alumnos WHERE id_alumno = ?";
            pstmtTemp = connTemp.prepareStatement(sqlGetNombre);
            pstmtTemp.setInt(1, idAlumno);
            rsTemp = pstmtTemp.executeQuery();
            if (rsTemp.next()) {
                nombreAlumno = rsTemp.getString("nombre_completo");
                session.setAttribute("nombre_alumno", nombreAlumno);
            }
        } catch (SQLException | ClassNotFoundException ex) {
            System.err.println("ERROR: Al obtener nombre del alumno en mensajes_alumno.jsp: " + ex.getMessage());
        } finally {
            closeDbResources(rsTemp, pstmtTemp);
            if (connTemp != null) { try { connTemp.close(); } catch (SQLException ignore) {} }
        }
    }

    // Variables para contadores de notificaciones
    int totalUnreadMessages = 0;
    int totalSentMessages = 0;
    int totalReceivedMessages = 0;

    Connection conn = null;

    try {
        conn = new Conection().conecta();

        if (conn == null || conn.isClosed()) {
            throw new SQLException("No se pudo establecer conexión a la base de datos.");
        }

        PreparedStatement pstmt = null;
        ResultSet rs = null;
        try {
            String sqlUnreadMessagesCount = "SELECT COUNT(*) FROM mensajes WHERE id_destinatario = ? AND tipo_destinatario = 'alumno' AND leido = FALSE";
            pstmt = conn.prepareStatement(sqlUnreadMessagesCount);
            pstmt.setInt(1, idAlumno);
            rs = pstmt.executeQuery();
            if (rs.next()) {
                totalUnreadMessages = rs.getInt(1);
            }
            closeDbResources(rs, pstmt);

            String sqlTotalSent = "SELECT COUNT(*) FROM mensajes WHERE id_remitente = ? AND tipo_remitente = 'alumno'";
            pstmt = conn.prepareStatement(sqlTotalSent);
            pstmt.setInt(1, idAlumno);
            rs = pstmt.executeQuery();
            if (rs.next()) {
                totalSentMessages = rs.getInt(1);
            }
            closeDbResources(rs, pstmt);

            String sqlTotalReceived = "SELECT COUNT(*) FROM mensajes WHERE id_destinatario = ? AND tipo_destinatario = 'alumno'";
            pstmt = conn.prepareStatement(sqlTotalReceived);
            pstmt.setInt(1, idAlumno);
            rs = pstmt.executeQuery();
            if (rs.next()) {
                totalReceivedMessages = rs.getInt(1);
            }
            closeDbResources(rs, pstmt);

        } finally {
            // Resources already closed in inner blocks
        }

    } catch (Exception e) {
        System.err.println("ERROR general en mensajes_alumno.jsp: " + e.getMessage());
        e.printStackTrace();
        response.sendRedirect(request.getContextPath() + "/error.jsp?message=" + URLEncoder.encode("Error inesperado al cargar la página de mensajería: " + e.getMessage(), "UTF-8"));
        return;
    } finally {
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
        <title>Mi Mensajería - Sistema Universitario</title>
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
                border-left: 4px solid var(--admin-primary);
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
                text-wrap: pretty;
            }
            .stat-card .icon-wrapper {
                background-color: var(--admin-primary);
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
            }
            .stat-card.messages-received .icon-wrapper {
                background-color: var(--admin-info);
            }
            .stat-card.unread-messages .icon-wrapper {
                background-color: var(--admin-warning);
            }


            /* Message Sections */
            .message-section.card {
                border-radius: 0.5rem;
                box-shadow: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.075);
                margin-bottom: 1.5rem;
            }
            .message-section.compose {
                border-left: 4px solid var(--admin-primary);
            }
            .message-section.received {
                border-left: 4px solid var(--admin-info);
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
                position: sticky;
                top: 0;
                z-index: 1;
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
                filter: invert(1) grayscale(100%) brightness(200%);
            }
            #modalMessageContenido {
                background-color: var(--admin-light-bg);
                border-color: var(--admin-info);
                padding: 1rem;
                border-radius: 0.3rem;
                font-size: 0.95rem;
                white-space: pre-wrap;
                word-break: break-word;
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
                }
            }

            @media (max-width: 576px) {
                .main-content {
                    padding: 0.75rem;
                }
                .welcome-section, .card {
                    padding: 1rem;
                }
                .row-cols-md-2 > .col {
                    flex: 0 0 100%;
                    max-width: 100%;
                }
            }
        </style>
    </head>
    <body>
        <div id="app">
            <nav class="sidebar">
                <div class="sidebar-header">
                    <a href="<%= request.getContextPath()%>/INTERFAZ_ALUMNO/home_alumno.jsp" class="text-white text-decoration-none">UGIC Portal</a>
                </div>

                <ul class="navbar-nav">
                    <li class="nav-item">
                        <a class="nav-link" href="<%= request.getContextPath()%>/INTERFAZ_ALUMNO/home_alumno.jsp"><i class="fas fa-home"></i><span> Inicio</span></a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="<%= request.getContextPath()%>/INTERFAZ_ALUMNO/cursos_alumno.jsp"><i class="fas fa-book"></i><span> Mis Cursos</span></a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="<%= request.getContextPath()%>/INTERFAZ_ALUMNO/asistencia_alumno.jsp"><i class="fas fa-clipboard-check"></i><span> Mi Asistencia</span></a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="<%= request.getContextPath()%>/INTERFAZ_ALUMNO/notas_alumno.jsp"><i class="fas fa-percent"></i><span> Mis Notas</span></a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="<%= request.getContextPath()%>/INTERFAZ_ALUMNO/pagos_alumno.jsp"><i class="fas fa-money-bill-wave"></i><span> Mis Pagos</span></a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link active" href="<%= request.getContextPath()%>/INTERFAZ_ALUMNO/mensajes_alumno.jsp"><i class="fas fa-envelope"></i><span> Mensajes</span></a>
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
                                    <%= totalUnreadMessages > 0 ? totalUnreadMessages : ""%>
                                </span>
                            </a>
                            <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="notificationsDropdown">
                                <li><a class="dropdown-item" href="<%= request.getContextPath()%>/INTERFAZ_ALUMNO/mensajes_alumno.jsp#message-table-section">Tienes <%= totalUnreadMessages%> mensajes no leídos</a></li>
                                <li><hr class="dropdown-divider"></li>
                                <li><a class="dropdown-item" href="<%= request.getContextPath()%>/INTERFAZ_ALUMNO/mensajes_alumno.jsp">Ver todos los mensajes</a></li>
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
                                <li><a class="dropdown-item" href="<%= request.getContextPath()%>/INTERFAZ_ALUMNO/mensajes_alumno.jsp#message-table-section">Tienes <%= totalUnreadMessages%> mensajes no leídos</a></li>
                                <li><hr class="dropdown-divider"></li>
                                <li><a class="dropdown-item" href="<%= request.getContextPath()%>/INTERFAZ_ALUMNO/mensajes_alumno.jsp">Ver todos los mensajes</a></li>
                            </ul>
                        </div>

                        <div class="dropdown user-dropdown">
                            <a class="dropdown-toggle" href="#" role="button" id="userDropdown" data-bs-toggle="dropdown" aria-expanded="false">
                                <img src="https://via.placeholder.com/32" alt="Avatar"> <span class="d-none d-md-inline-block"><%= nombreAlumno%></span>
                            </a>
                            <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="userDropdown">
                                <li><a class="dropdown-item" href="perfil_alumno.jsp"><i class="fas fa-user me-2"></i>Perfil</a></li>
                                <li><a class="dropdown-item" href="configuracion_alumno.jsp"><i class="fas fa-cog me-2"></i>Configuración</a></li>
                                <li><hr class="dropdown-divider"></li>
                                <li><a class="dropdown-item" href="<%= request.getContextPath()%>/logout.jsp"><i class="fas fa-sign-out-alt me-2"></i>Cerrar sesión</a></li>
                            </ul>
                        </div>
                    </div>
                </nav>

                <div class="container-fluid">
                    <div class="welcome-section">
                        <h1 class="h3 mb-3"><i class="fas fa-comments me-2"></i>Mi Panel de Mensajería</h1>
                        <p class="lead">Envía y revisa mensajes con tus profesores y la administración.</p>
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
                            <div class="card stat-card unread-messages">
                                <div class="card-body">
                                    <div class="row align-items-center">
                                        <div class="col-auto">
                                            <div class="icon-wrapper bg-warning text-white">
                                                <i class="fas fa-envelope-open-text"></i>
                                            </div>
                                        </div>
                                        <div class="col">
                                            <h3 class="card-title">Mensajes No Leídos</h3>
                                            <div class="value" id="stat-unread-messages">0</div>
                                            <p class="card-text description text-muted">Mensajes nuevos que requieren tu atención.</p>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="row">
                        <div class="col-12 mb-4">
                            <div class="card message-section compose">
                                <div class="card-body">
                                    <h2 class="section-title"><i class="fas fa-paper-plane me-2"></i>Enviar Nuevo Mensaje</h2>
                                    <p class="text-muted mb-4">Envía un mensaje a tus profesores o a la administración.</p>
                                    <a href="<%= request.getContextPath()%>/INTERFAZ_ALUMNO/enviar_mensaje_alumno_profesor.jsp" class="btn btn-primary">
                                        <i class="fas fa-plus-circle me-2"></i>Enviar Mensaje
                                    </a>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="row">
                        <div class="col-12 mb-4">
                            <div class="card message-section received">
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
                                                            conn = new Conection().conecta();
                                                        }

                                                        if (conn != null && !conn.isClosed() && idAlumno != -1) {
                                                            String sqlMensajesRecibidos = "SELECT m.id_mensaje, m.asunto, m.contenido, m.fecha_envio, m.leido, "
                                                                                        + "CASE m.tipo_remitente "
                                                                                        + "    WHEN 'profesor' THEN CONCAT(p.nombre, ' ', p.apellido_paterno) "
                                                                                        + "    WHEN 'admin' THEN a.nombre "
                                                                                        + "    WHEN 'alumno' THEN CONCAT(al.nombre, ' ', al.apellido_paterno) "
                                                                                        + "    ELSE 'Desconocido' "
                                                                                        + "END AS remitente_nombre, "
                                                                                        + "m.tipo_remitente "
                                                                                        + "FROM mensajes m "
                                                                                        + "LEFT JOIN profesores p ON m.id_remitente = p.id_profesor AND m.tipo_remitente = 'profesor' "
                                                                                        + "LEFT JOIN admin a ON m.id_remitente = a.id_admin AND m.tipo_remitente = 'admin' "
                                                                                        + "LEFT JOIN alumnos al ON m.id_remitente = al.id_alumno AND m.tipo_remitente = 'alumno' "
                                                                                        + "WHERE m.id_destinatario = ? AND m.tipo_destinatario = 'alumno' "
                                                                                        + "ORDER BY m.fecha_envio DESC";

                                                            pstmtMensajesRecibidos = conn.prepareStatement(sqlMensajesRecibidos);
                                                            pstmtMensajesRecibidos.setInt(1, idAlumno);
                                                            rsMensajesRecibidos = pstmtMensajesRecibidos.executeQuery();

                                                            while (rsMensajesRecibidos.next()) {
                                                                hayMensajesRecibidos = true;
                                                                int idMensaje = rsMensajesRecibidos.getInt("id_mensaje");
                                                                String remitenteNombreFull = rsMensajesRecibidos.getString("remitente_nombre");
                                                                String asuntoMensaje = rsMensajesRecibidos.getString("asunto");
                                                                String contenidoMensaje = rsMensajesRecibidos.getString("contenido");
                                                                java.sql.Timestamp fechaEnvio = rsMensajesRecibidos.getTimestamp("fecha_envio");
                                                                boolean leido = rsMensajesRecibidos.getBoolean("leido");
                                                                String tipoRemitente = rsMensajesRecibidos.getString("tipo_remitente");

                                                                String badgeStatusClass = leido ? "badge-read-custom" : "badge-unread-custom";
                                                                String statusText = leido ? "Leído" : "No Leído";
                                                                String displayContent = contenidoMensaje != null && contenidoMensaje.length() > 70 ? contenidoMensaje.substring(0, 70) + "..." : (contenidoMensaje != null ? contenidoMensaje : "");
                                                                String fullRemitente = (remitenteNombreFull != null ? remitenteNombreFull : "N/A") + " (" + tipoRemitente + ")";
                                                %>
                                                <tr class="<%= !leido ? "table-primary-subtle" : ""%>">
                                                    <td>
                                                        <strong><%= remitenteNombreFull != null ? remitenteNombreFull : "N/A"%></strong><br><small class="text-muted">(<%= tipoRemitente%>)</small>
                                                    </td>
                                                    <td><%= asuntoMensaje != null ? asuntoMensaje : "Sin Asunto"%></td>
                                                    <td><%= displayContent%></td>
                                                    <td><%= new SimpleDateFormat("dd/MM/yyyy HH:mm").format(fechaEnvio)%></td>
                                                    <td class="text-center"><span class="badge <%= badgeStatusClass%>"><%= statusText%></span></td>
                                                    <td class="text-center">
                                                        <% if (!leido) {%>
                                                        <form action="<%= request.getContextPath()%>/INTERFAZ_ALUMNO/marcar_leido_alumno.jsp" method="post" class="d-inline-block me-1">
                                                            <input type="hidden" name="id_mensaje" value="<%= idMensaje%>">
                                                            <button type="submit" class="btn btn-primary btn-sm" title="Marcar como leído"><i class="fas fa-check"></i></button>
                                                        </form>
                                                        <% }%>
                                                        <button type="button" class="btn btn-info btn-sm" data-bs-toggle="modal" data-bs-target="#viewMessageModal"
                                                                data-asunto="<%= escapeJson(asuntoMensaje) %>"
                                                                data-contenido="<%= escapeJson(contenidoMensaje) %>"
                                                                data-remitente="<%= escapeJson(fullRemitente) %>"
                                                                data-fecha="<%= new SimpleDateFormat("dd/MM/yyyy HH:mm").format(fechaEnvio)%>"
                                                                data-id-mensaje="<%= idMensaje%>"
                                                                data-leido="<%= leido%>">
                                                            <i class="fas fa-eye"></i>
                                                        </button>
                                                    </td>
                                                </tr>
                                                <%
                                                            }
                                                        }

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
                        step();
                }

                // Pass the counts from JSP to JavaScript directly
                const totalSentMessages = <%= totalSentMessages%>;
                const totalReceivedMessages = <%= totalReceivedMessages%>;
                const totalUnreadMessages = <%= totalUnreadMessages%>;

                animateValue("stat-msg-enviados", 0, totalSentMessages, 1000);
                animateValue("stat-msg-recibidos", 0, totalReceivedMessages, 1000);
                animateValue("stat-unread-messages", 0, totalUnreadMessages, 1000);

                // Handler for the "View" message button (opens the modal)
                $('#viewMessageModal').on('show.bs.modal', function (event) {
                    const button = $(event.relatedTarget);
                    const asunto = button.data('asunto');
                    const contenido = button.data('contenido');
                    const remitente = button.data('remitente');
                    const fecha = button.data('fecha');
                    const idMensaje = button.data('id-mensaje');
                    const leido = button.data('leido');

                    const modal = $(this);
                    modal.find('#modalMessageRemitente').text(remitente);
                    modal.find('#modalMessageAsunto').text(asunto);
                    modal.find('#modalMessageFecha').text(fecha);
                    modal.find('#modalMessageContenido').text(contenido);

                    // If message is unread, mark it as read via AJAX
                    if (!leido) {
                        $.ajax({
                            url: '<%= request.getContextPath()%>/INTERFAZ_ALUMNO/marcar_leido_alumno.jsp',
                            type: 'POST', // Changed to POST to match the form
                            data: { id_mensaje: idMensaje, ajax: true },
                            success: function(response) {
                                console.log("Mensaje marcado como leído (AJAX):", idMensaje);
                                const $row = $(button).closest('tr');
                                $row.removeClass('table-primary-subtle');
                                $row.find('.badge-unread-custom').removeClass('badge-unread-custom').addClass('badge-read-custom').text('Leído');
                                
                                // Find the specific button and remove the form around it, replace with "read" button
                                const $markReadForm = $(button).closest('td').find('form');
                                if ($markReadForm.length) { // Check if form exists
                                    $markReadForm.remove();
                                }
                                
                                // Decrement unread message count in navbar and stat card if visible
                                let currentUnreadCount = parseInt($('#stat-unread-messages').text()) || 0;
                                if (currentUnreadCount > 0) {
                                    $('#stat-unread-messages').text(currentUnreadCount - 1);
                                    $('.top-navbar .badge.rounded-pill.bg-danger').text(currentUnreadCount - 1 > 0 ? currentUnreadCount - 1 : '');
                                }
                            },
                            error: function(xhr, status, error) {
                                console.error("Error al marcar mensaje como leído (AJAX):", error);
                            }
                        });
                    }
                });
            });
        </script>
    </body>
</html>