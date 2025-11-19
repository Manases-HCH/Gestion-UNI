<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, pe.universidad.util.Conection" %>
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

    String facultadProfesor = "No asignado";
    String nombreProfesor = "";
    int idProfesor = 0;
    int idFacultadProfesor = 0;

    int totalCarreras = 0;
    int cursosDisponibles = 0;
    List<Map<String, String>> carrerasList = new ArrayList<>(); // Para la tabla de carreras

    Connection conn = null; // La conexión se inicializa y se cierra una vez por petición

    try {
        Conection c = new Conection();
        conn = c.conecta(); // Obtener la conexión al inicio de la petición

        // --- 1. Obtener Datos Principales del Profesor ---
        PreparedStatement pstmtProfesor = null;
        ResultSet rsProfesor = null;
        try {
            String sqlProfesor = "SELECT p.id_profesor, p.nombre, p.apellido_paterno, p.apellido_materno, p.id_facultad "
                                + "FROM profesores p WHERE p.email = ?";
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
            } else {
                response.sendRedirect("login.jsp?error=profesor_no_encontrado");
                return;
            }
        } finally {
            closeDbResources(rsProfesor, pstmtProfesor); // Cerrar recursos específicos de esta consulta
        }

        // --- 2. Obtener Nombre de la Facultad y Estadísticas Asociadas ---
        if (idFacultadProfesor > 0) {
            // Obtener el nombre de la facultad
            PreparedStatement pstmtFacultad = null;
            ResultSet rsFacultad = null;
            try {
                String sqlFacultad = "SELECT nombre_facultad FROM facultades WHERE id_facultad = ?";
                pstmtFacultad = conn.prepareStatement(sqlFacultad);
                pstmtFacultad.setInt(1, idFacultadProfesor);
                rsFacultad = pstmtFacultad.executeQuery();
                if (rsFacultad.next()) {
                    facultadProfesor = rsFacultad.getString("nombre_facultad");
                }
            } finally {
                closeDbResources(rsFacultad, pstmtFacultad);
            }

            // Contar carreras de la facultad
            PreparedStatement pstmtTotalCarreras = null;
            ResultSet rsTotalCarreras = null;
            try {
                String sqlCount = "SELECT COUNT(*) as total FROM carreras WHERE id_facultad = ?";
                pstmtTotalCarreras = conn.prepareStatement(sqlCount);
                pstmtTotalCarreras.setInt(1, idFacultadProfesor);
                rsTotalCarreras = pstmtTotalCarreras.executeQuery();
                if (rsTotalCarreras.next()) {
                    totalCarreras = rsTotalCarreras.getInt("total");
                }
            } finally {
                closeDbResources(rsTotalCarreras, pstmtTotalCarreras);
            }

            // Contar cursos disponibles (cursos de la facultad que el profesor NO tiene asignados)
            PreparedStatement pstmtCursosDisponibles = null;
            ResultSet rsCursosDisponibles = null;
            try {
                String sqlCursosDisponibles = "SELECT COUNT(*) as disponibles "
                                            + "FROM cursos c "
                                            + "INNER JOIN carreras car ON c.id_carrera = car.id_carrera "
                                            + "WHERE car.id_facultad = ? "
                                            + "AND c.id_curso NOT IN ("
                                            + "  SELECT pc.id_curso FROM profesor_curso pc WHERE pc.id_profesor = ?"
                                            + ")";
                pstmtCursosDisponibles = conn.prepareStatement(sqlCursosDisponibles);
                pstmtCursosDisponibles.setInt(1, idFacultadProfesor);
                pstmtCursosDisponibles.setInt(2, idProfesor);
                rsCursosDisponibles = pstmtCursosDisponibles.executeQuery();
                if (rsCursosDisponibles.next()) {
                    cursosDisponibles = rsCursosDisponibles.getInt("disponibles");
                }
            } finally {
                closeDbResources(rsCursosDisponibles, pstmtCursosDisponibles);
            }

            // --- 3. Obtener Lista de Carreras para la Tabla ---
            PreparedStatement pstmtCarrerasList = null;
            ResultSet rsCarrerasList = null;
            try {
                String sqlCarreras = "SELECT c.id_carrera, c.nombre_carrera, f.nombre_facultad "
                                    + "FROM carreras c "
                                    + "INNER JOIN facultades f ON c.id_facultad = f.id_facultad "
                                    + "WHERE c.id_facultad = ? "
                                    + "ORDER BY c.nombre_carrera";
                pstmtCarrerasList = conn.prepareStatement(sqlCarreras);
                pstmtCarrerasList.setInt(1, idFacultadProfesor);
                rsCarrerasList = pstmtCarrerasList.executeQuery();

                while (rsCarrerasList.next()) {
                    Map<String, String> carrera = new HashMap<>();
                    carrera.put("id_carrera", String.valueOf(rsCarrerasList.getInt("id_carrera")));
                    carrera.put("nombre_carrera", rsCarrerasList.getString("nombre_carrera"));
                    carrera.put("nombre_facultad", rsCarrerasList.getString("nombre_facultad"));
                    carrerasList.add(carrera);
                }
            } finally {
                closeDbResources(rsCarrerasList, pstmtCarrerasList);
            }

        } // Fin if (idFacultadProfesor > 0)

    } catch (SQLException | ClassNotFoundException e) {
        e.printStackTrace();
        response.sendRedirect("error.jsp?message=Error_interno_del_servidor_al_cargar_carreras");
        return;
    } finally {
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
    <title>Carreras - Sistema Universitario</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
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

        /* Welcome Section (for consistency with dashboard) */
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

        /* Specific card for "Mi Facultad Asignada" (used for context) */
        .faculty-context-card.card {
            text-align: center;
            padding: 1.5rem;
            border-radius: 0.5rem;
            box-shadow: 0 0.125rem 0.25rem rgba(0,0,0,0.075);
            border-left: 4px solid var(--admin-info); /* Different color for context card */
            margin-bottom: 1.5rem;
        }
        .faculty-context-card h3 {
            color: var(--admin-text-dark);
            font-weight: 600;
            margin-bottom: 0.5rem;
        }
        .faculty-context-card p.lead {
            font-size: 1.1rem;
            color: var(--admin-primary);
            font-weight: 500;
        }


        /* Statistics Cards (similar to dashboard's stat-cards) */
        .stat-card-custom {
            border-radius: 0.5rem;
            box-shadow: 0 0.125rem 0.25rem rgba(0,0,0,0.075);
            transition: transform 0.2s ease, box-shadow 0.2s ease;
            height: 100%;
        }
        .stat-card-custom:hover {
            transform: translateY(-3px);
            box-shadow: 0 0.25rem 0.5rem rgba(0,0,0,0.1);
        }
        .stat-card-custom .card-body {
            padding: 1.25rem;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }
        .stat-card-custom .content-left {
            flex-grow: 1;
        }
        .stat-card-custom .card-title {
            color: var(--admin-text-muted);
            font-size: 0.9rem;
            margin-bottom: 0.25rem;
            font-weight: 500;
        }
        .stat-card-custom .value {
            font-size: 1.8rem;
            font-weight: 700;
            color: var(--admin-text-dark);
            margin-bottom: 0.25rem;
            line-height: 1;
        }
        .stat-card-custom .icon-right {
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
        .stat-card-custom.carreras .icon-right { background-color: var(--admin-info); }
        .stat-card-custom.disponibles .icon-right { background-color: var(--admin-success); }


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
            padding: 0.5rem; /* Smaller padding for compact tables */
        }

        /* Chart */
        .chart-container {
            height: 320px;
            padding: 1rem;
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
            .stat-card-custom .card-body {
                flex-direction: column;
                align-items: flex-start;
            }
            .stat-card-custom .icon-right {
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
            .stat-card-custom .value {
                font-size: 1.5rem;
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
                    <a class="nav-link active" href="carreras_profesor.jsp"><i class="fas fa-graduation-cap"></i><span> Carreras</span></a>
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
                    <h1 class="h3 mb-3">Carreras</h1>
                    <p class="lead">Consulta las carreras disponibles en tu facultad asignada.</p>
                </div>

                <div class="row">
                    <div class="col-12 mb-4">
                        <div class="faculty-context-card card">
                            <div class="card-body">
                                <h3 class="card-title">Facultad Actual:</h3>
                                <p class="lead"><%= facultadProfesor %></p>
                                <% if (facultadProfesor.equals("No asignado")) { %>
                                    <span class="badge bg-warning text-dark"><i class="fas fa-exclamation-triangle me-1"></i> Sin Asignación</span>
                                <% } else { %>
                                    <span class="badge bg-primary"><i class="fas fa-check-circle me-1"></i> Asignada</span>
                                <% } %>
                            </div>
                        </div>
                    </div>
                </div>

                <% if (!facultadProfesor.equals("No asignado")) { %>
                <div class="row">
                    <div class="col-md-6 mb-4">
                        <div class="card stat-card-custom carreras">
                            <div class="card-body">
                                <div class="content-left">
                                    <h3 class="card-title">Total de Carreras</h3>
                                    <div class="value"><%= totalCarreras %></div>
                                </div>
                                <div class="icon-right bg-info">
                                    <i class="fas fa-graduation-cap"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-6 mb-4">
                        <div class="card stat-card-custom disponibles">
                            <div class="card-body">
                                <div class="content-left">
                                    <h3 class="card-title">Cursos Disponibles</h3>
                                    <div class="value"><%= cursosDisponibles %></div>
                                </div>
                                <div class="icon-right bg-success">
                                    <i class="fas fa-book-open"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="row">
                    <div class="col-12 mb-4">
                        <div class="card content-section">
                            <div class="card-body">
                                <h3 class="section-title card-title"><i class="fas fa-chart-pie me-2"></i>Distribución de Carreras y Cursos</h3>
                                <div class="chart-container">
                                    <canvas id="carrerasChart"></canvas>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="row">
                    <div class="col-12 mb-4">
                        <div class="card content-section">
                            <div class="card-body">
                                <h3 class="section-title card-title"><i class="fas fa-list-alt me-2"></i>Listado de Carreras - <%= facultadProfesor%></h3>
                                <div class="table-responsive">
                                    <table class="table table-hover table-sm">
                                        <thead>
                                            <tr>
                                                <th scope="col">ID</th>
                                                <th scope="col">Nombre de la Carrera</th>
                                                <th scope="col">Facultad</th>
                                                <th scope="col">Estado</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <% if (!carrerasList.isEmpty()) {
                                                for (Map<String, String> carrera : carrerasList) {%>
                                            <tr>
                                                <td><%= carrera.get("id_carrera")%></td>
                                                <td><%= carrera.get("nombre_carrera")%></td>
                                                <td><%= carrera.get("nombre_facultad")%></td>
                                                <td><span class="badge bg-info"><i class="fas fa-circle me-1" style="font-size: 0.7em;"></i> Activa</span></td>
                                            </tr>
                                            <% }
                                            } else { %>
                                            <tr>
                                                <td colspan="4" class="text-center text-muted py-3">
                                                    <i class="fas fa-info-circle me-2"></i>No hay carreras registradas en esta facultad.
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
                <% } else { %>
                <div class="row">
                    <div class="col-12 mb-4">
                        <div class="card content-section">
                            <div class="card-body text-center py-5">
                                <h3 class="text-warning"><i class="fas fa-exclamation-circle me-2"></i>No tienes una facultad asignada</h3>
                                <p class="text-muted">Contacta al administrador del sistema para que te asigne una facultad y puedas consultar sus carreras.</p>
                                <a href="facultad_profesor.jsp" class="btn btn-primary mt-3"><i class="fas fa-building me-2"></i>Ver mi Facultad</a>
                            </div>
                        </div>
                    </div>
                </div>
                <% } %>
            </div>
        </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js" integrity="sha384-YvpcrYf0tY3lHB60NNkmXc5s9fDVZLESaAA55NDzOxhy9GkcIdslK1eN7N6jIeHz" crossorigin="anonymous"></script>
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            // Chart.js Example for Carreras
            const carrerasChart = document.getElementById('carrerasChart');
            if (carrerasChart) {
                new Chart(carrerasChart, {
                    type: 'doughnut', // Pie or Doughnut for distribution
                    data: {
                        labels: ['Total Carreras', 'Cursos Disponibles'],
                        datasets: [{
                            label: 'Conteo',
                            data: [<%= totalCarreras %>, <%= cursosDisponibles %>],
                            backgroundColor: [
                                'rgba(0, 123, 255, 0.7)', // AdminKit primary blue
                                'rgba(40, 167, 69, 0.7)'  // AdminKit success green
                            ],
                            borderColor: [
                                'rgba(0, 123, 255, 1)',
                                'rgba(40, 167, 69, 1)'
                            ],
                            borderWidth: 1
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        plugins: {
                            legend: {
                                position: 'bottom', // Legend at the bottom
                            },
                            title: {
                                display: true,
                                text: 'Relación Carreras y Cursos Disponibles'
                            }
                        }
                    }
                });
            }
        });
    </script>
</body>
</html>