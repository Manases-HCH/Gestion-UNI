<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, pe.universidad.util.Conection" %>
<%@ page import="java.time.LocalDateTime, java.time.format.DateTimeFormatter" %>
<%@ page import="java.util.ArrayList, java.util.HashMap, java.util.List, java.util.Map" %>
<%@ page import="java.text.SimpleDateFormat" %> <%-- Importar SimpleDateFormat --%>
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

    // Variables para los datos del profesor (para la navbar y sidebar)
    String nombreProfesor = "Usuario";
    String facultadProfesor = "Sin asignar";
    int idProfesor = 0;

    // Variables para las estadísticas de solicitudes
    int totalSolicitudesPendientes = 0;
    int totalSolicitudesAprobadas = 0;
    int totalSolicitudesRechazadas = 0;
    List<Map<String, String>> misSolicitudesList = new ArrayList<>(); // Para la tabla de solicitudes

    Connection conn = null; // La conexión se inicializa y se cierra una vez por petición

    try {
        Conection c = new Conection();
        conn = c.conecta(); // Obtener la conexión al inicio de la petición

        // --- 1. Obtener Datos del Profesor para la Navbar/Sidebar y su ID ---
        PreparedStatement pstmtProfesor = null;
        ResultSet rsProfesor = null;
        try {
            String sqlProfesor = "SELECT p.id_profesor, p.nombre, p.apellido_paterno, p.apellido_materno, f.nombre_facultad "
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
                facultadProfesor = rsProfesor.getString("nombre_facultad") != null ? rsProfesor.getString("nombre_facultad") : "Sin asignar";
            } else {
                response.sendRedirect("login.jsp?error=profesor_no_encontrado");
                return;
            }
        } finally {
            closeDbResources(rsProfesor, pstmtProfesor);
        }

        // --- 2. Lógica para cargar las estadísticas y la lista de solicitudes ---
        if (idProfesor > 0) {
            // Contar solicitudes por estado
            PreparedStatement pstmtCountRequests = null;
            ResultSet rsCountRequests = null;
            try {
                String sqlCountRequests = "SELECT estado, COUNT(*) as total FROM solicitudes_cursos WHERE id_profesor = ? GROUP BY estado";
                pstmtCountRequests = conn.prepareStatement(sqlCountRequests);
                pstmtCountRequests.setInt(1, idProfesor);
                rsCountRequests = pstmtCountRequests.executeQuery();
                while (rsCountRequests.next()) {
                    String estado = rsCountRequests.getString("estado");
                    int total = rsCountRequests.getInt("total");
                    if ("PENDIENTE".equalsIgnoreCase(estado)) {
                        totalSolicitudesPendientes = total;
                    } else if ("APROBADA".equalsIgnoreCase(estado)) {
                        totalSolicitudesAprobadas = total;
                    } else if ("RECHAZADA".equalsIgnoreCase(estado)) {
                        totalSolicitudesRechazadas = total;
                    }
                }
            } finally {
                closeDbResources(rsCountRequests, pstmtCountRequests);
            }

            // Cargar la lista completa de solicitudes para la tabla
            PreparedStatement pstmtSolicitudesList = null;
            ResultSet rsSolicitudesList = null;
            try {
                String sqlSolicitudesList = "SELECT sc.id_solicitud, sc.tipo_solicitud, sc.estado, sc.fecha_solicitud, c.nombre_curso "
                                            + "FROM solicitudes_cursos sc JOIN cursos c ON sc.id_curso = c.id_curso "
                                            + "WHERE sc.id_profesor = ? ORDER BY sc.fecha_solicitud DESC";
                pstmtSolicitudesList = conn.prepareStatement(sqlSolicitudesList);
                pstmtSolicitudesList.setInt(1, idProfesor);
                rsSolicitudesList = pstmtSolicitudesList.executeQuery();
                while (rsSolicitudesList.next()) {
                    Map<String, String> solicitud = new HashMap<>();
                    solicitud.put("id_solicitud", String.valueOf(rsSolicitudesList.getInt("id_solicitud")));
                    solicitud.put("nombre_curso", rsSolicitudesList.getString("nombre_curso"));
                    solicitud.put("tipo_solicitud", rsSolicitudesList.getString("tipo_solicitud"));
                    solicitud.put("estado", rsSolicitudesList.getString("estado"));
                    Timestamp fecha = rsSolicitudesList.getTimestamp("fecha_solicitud");
                    solicitud.put("fecha_solicitud", fecha != null ? new SimpleDateFormat("dd/MM/yyyy HH:mm").format(fecha) : "N/A");
                    misSolicitudesList.add(solicitud);
                }
            } finally {
                closeDbResources(rsSolicitudesList, pstmtSolicitudesList);
            }

        } // Fin if (idProfesor > 0)

    } catch (SQLException | ClassNotFoundException e) {
        e.printStackTrace();
        response.sendRedirect("error.jsp?message=Error_interno_del_servidor_al_cargar_solicitudes");
        return;
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
    <title>Mis Solicitudes - Sistema Universitario</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
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

        /* Statistics Cards */
        .stats-card-solicitudes {
            border-radius: 0.5rem;
            box-shadow: 0 0.125rem 0.25rem rgba(0,0,0,0.075);
            transition: transform 0.2s ease, box-shadow 0.2s ease;
            height: 100%;
        }
        .stats-card-solicitudes:hover {
            transform: translateY(-3px);
            box-shadow: 0 0.25rem 0.5rem rgba(0,0,0,0.1);
        }
        .stats-card-solicitudes .card-body {
            padding: 1.25rem;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }
        .stats-card-solicitudes .content-left {
            flex-grow: 1;
        }
        .stats-card-solicitudes .card-title {
            color: var(--admin-text-muted);
            font-size: 0.9rem;
            margin-bottom: 0.25rem;
            font-weight: 500;
        }
        .stats-card-solicitudes .value {
            font-size: 1.8rem;
            font-weight: 700;
            color: var(--admin-text-dark);
            margin-bottom: 0.25rem;
            line-height: 1;
        }
        .stats-card-solicitudes .icon-right {
            background-color: var(--admin-primary);
            color: white;
            padding: 0.75rem;
            border-radius: 0.5rem;
            font-size: 1.5rem;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            width: 50px;
            height: 50px;
            flex-shrink: 0;
            margin-left: 1rem;
        }
        .stats-card-solicitudes.pending .icon-right { background-color: var(--admin-warning); }
        .stats-card-solicitudes.approved .icon-right { background-color: var(--admin-success); }
        .stats-card-solicitudes.rejected .icon-right { background-color: var(--admin-danger); }


        /* Tables */
        .table {
            color: var(--admin-text-dark);
        }
        .table thead th {
            border-bottom: 2px solid var(--admin-primary);
            color: var(--admin-primary);
            font-weight: 600;
            background-color: var(--admin-light-bg);
        }
        .table tbody tr:hover {
            background-color: rgba(0, 123, 255, 0.05);
        }
        .table-sm th, .table-sm td {
            padding: 0.5rem;
        }

        /* Status Badges in table */
        .badge-status-pending { background-color: rgba(255, 193, 7, 0.1); color: var(--admin-warning); border: 1px solid var(--admin-warning); }
        .badge-status-approved { background-color: rgba(40, 167, 69, 0.1); color: var(--admin-success); border: 1px solid var(--admin-success); }
        .badge-status-rejected { background-color: rgba(220, 53, 69, 0.1); color: var(--admin-danger); border: 1px solid var(--admin-danger); }

        /* Empty states */
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
            .stats-card-solicitudes .card-body {
                flex-direction: column;
                align-items: flex-start;
            }
            .stats-card-solicitudes .icon-right {
                margin-bottom: 1rem;
                margin-left: 0;
            }
        }

        @media (max-width: 576px) {
            .main-content {
                padding: 0.75rem;
            }
            .welcome-section, .card {
                padding: 1rem;
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
                    <a class="nav-link" href="cursos_profesor.jsp"><i class="fas fa-book"></i><span> Cursos</span></a>
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
                            <li><a class="dropdown-item" href="mensaje_profesor.jsp">Ver todos</a></li>
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
                    <h1 class="h3 mb-3">Gestión de Solicitudes de Cursos</h1>
                    <p class="lead">Aquí puedes revisar el estado de tus solicitudes para unirte o salir de cursos.</p>
                </div>

                <div class="row">
                    <div class="col-md-4 mb-4">
                        <div class="card stats-card-solicitudes pending">
                            <div class="card-body">
                                <div class="content-left">
                                    <h3 class="card-title">Pendientes</h3>
                                    <div class="value"><%= totalSolicitudesPendientes %></div>
                                </div>
                                <div class="icon-right bg-warning">
                                    <i class="fas fa-hourglass-half"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-4 mb-4">
                        <div class="card stats-card-solicitudes approved">
                            <div class="card-body">
                                <div class="content-left">
                                    <h3 class="card-title">Aprobadas</h3>
                                    <div class="value"><%= totalSolicitudesAprobadas %></div>
                                </div>
                                <div class="icon-right bg-success">
                                    <i class="fas fa-check-circle"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-4 mb-4">
                        <div class="card stats-card-solicitudes rejected">
                            <div class="card-body">
                                <div class="content-left">
                                    <h3 class="card-title">Rechazadas</h3>
                                    <div class="value"><%= totalSolicitudesRechazadas %></div>
                                </div>
                                <div class="icon-right bg-danger">
                                    <i class="fas fa-times-circle"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="row">
                    <div class="col-12 mb-4">
                        <div class="card content-section">
                            <div class="card-body">
                                <h3 class="section-title card-title"><i class="fas fa-clipboard-list me-2"></i>Historial de Solicitudes</h3>
                                <div class="table-responsive">
                                    <table class="table table-hover table-sm">
                                        <thead>
                                            <tr>
                                                <th scope="col">ID Solicitud</th>
                                                <th scope="col">Curso</th>
                                                <th scope="col">Tipo</th>
                                                <th scope="col">Estado</th>
                                                <th scope="col">Fecha Solicitud</th>
                                                </tr>
                                        </thead>
                                        <tbody>
                                            <% if (!misSolicitudesList.isEmpty()) {
                                                for (Map<String, String> solicitud : misSolicitudesList) {
                                                    String estadoClass = "";
                                                    switch (solicitud.get("estado")) {
                                                        case "PENDIENTE": estadoClass = "badge-status-pending"; break;
                                                        case "APROBADA":  estadoClass = "badge-status-approved"; break;
                                                        case "RECHAZADA": estadoClass = "badge-status-rejected"; break;
                                                        default: estadoClass = "badge bg-secondary"; break; // Fallback
                                                    }
                                            %>
                                            <tr>
                                                <td><%= solicitud.get("id_solicitud") %></td>
                                                <td><%= solicitud.get("nombre_curso") %></td>
                                                <td><%= solicitud.get("tipo_solicitud") %></td>
                                                <td><span class="badge <%= estadoClass %>"><%= solicitud.get("estado") %></span></td>
                                                <td><%= solicitud.get("fecha_solicitud") %></td>
                                            </tr>
                                            <% }
                                            } else { %>
                                            <tr>
                                                <td colspan="5" class="text-center text-muted py-3">
                                                    <i class="fas fa-info-circle me-2"></i>No tienes solicitudes de cursos registradas.
                                                </td>
                                            </tr>
                                            <% } %>
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

            </div>
        </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js" integrity="sha384-YvpcrYf0tY3lHB60NNkmXc5s9fDVZLESaAA55NDzOxhy9GkcIdslK1eN7N6jIeHz" crossorigin="anonymous"></script>
</body>
</html>