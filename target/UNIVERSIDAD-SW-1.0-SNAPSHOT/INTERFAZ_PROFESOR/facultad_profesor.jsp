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
    int idFacultad = 0; // Inicializar idFacultad

    int totalProfesoresFacultad = 0;
    int totalCursosFacultad = 0;
    List<Map<String, String>> profesoresFacultadList = new ArrayList<>(); // Para la tabla de profesores
    // List<Map<String, String>> carrerasList = new ArrayList<>(); // Si se necesita una tabla de carreras

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
                idFacultad = rsProfesor.getInt("id_facultad");
            } else {
                response.sendRedirect("login.jsp?error=profesor_no_encontrado");
                return;
            }
        } finally {
            closeDbResources(rsProfesor, pstmtProfesor); // Cerrar recursos específicos de esta consulta
        }

        // --- 2. Obtener Nombre de la Facultad y Estadísticas Asociadas ---
        if (idFacultad > 0) {
            // Obtener el nombre de la facultad
            PreparedStatement pstmtFacultad = null;
            ResultSet rsFacultad = null;
            try {
                String sqlFacultad = "SELECT nombre_facultad FROM facultades WHERE id_facultad = ?";
                pstmtFacultad = conn.prepareStatement(sqlFacultad);
                pstmtFacultad.setInt(1, idFacultad);
                rsFacultad = pstmtFacultad.executeQuery();
                if (rsFacultad.next()) {
                    facultadProfesor = rsFacultad.getString("nombre_facultad");
                }
            } finally {
                closeDbResources(rsFacultad, pstmtFacultad);
            }

            // Contar profesores de la facultad
            PreparedStatement pstmtProfCount = null;
            ResultSet rsProfCount = null;
            try {
                String sqlProfCount = "SELECT COUNT(*) AS total FROM profesores WHERE id_facultad = ?";
                pstmtProfCount = conn.prepareStatement(sqlProfCount);
                pstmtProfCount.setInt(1, idFacultad);
                rsProfCount = pstmtProfCount.executeQuery();
                if (rsProfCount.next()) {
                    totalProfesoresFacultad = rsProfCount.getInt("total");
                }
            } finally {
                closeDbResources(rsProfCount, pstmtProfCount);
            }

            // Contar todos los cursos de la facultad
            PreparedStatement pstmtCursosCount = null;
            ResultSet rsCursosCount = null;
            try {
                String sqlCursosCount = "SELECT COUNT(*) as total FROM cursos c "
                                        + "INNER JOIN carreras car ON c.id_carrera = car.id_carrera "
                                        + "INNER JOIN facultades f ON car.id_facultad = f.id_facultad "
                                        + "WHERE f.id_facultad = ?";
                pstmtCursosCount = conn.prepareStatement(sqlCursosCount);
                pstmtCursosCount.setInt(1, idFacultad);
                rsCursosCount = pstmtCursosCount.executeQuery();
                if (rsCursosCount.next()) {
                    totalCursosFacultad = rsCursosCount.getInt("total");
                }
            } finally {
                closeDbResources(rsCursosCount, pstmtCursosCount);
            }

            // --- 3. Obtener Lista de Profesores de la Misma Facultad para la Tabla ---
            PreparedStatement pstmtProfesoresList = null;
            ResultSet rsProfesoresList = null;
            try {
                String sqlProfesoresList = "SELECT nombre, apellido_paterno, apellido_materno, email "
                                        + "FROM profesores WHERE id_facultad = ? ORDER BY apellido_paterno, nombre";
                pstmtProfesoresList = conn.prepareStatement(sqlProfesoresList);
                pstmtProfesoresList.setInt(1, idFacultad);
                rsProfesoresList = pstmtProfesoresList.executeQuery();
                while (rsProfesoresList.next()) {
                    Map<String, String> profesor = new HashMap<>();
                    String nom = rsProfesoresList.getString("nombre") != null ? rsProfesoresList.getString("nombre") : "";
                    String apP = rsProfesoresList.getString("apellido_paterno") != null ? rsProfesoresList.getString("apellido_paterno") : "";
                    String apM = rsProfesoresList.getString("apellido_materno") != null ? rsProfesoresList.getString("apellido_materno") : "";
                    profesor.put("nombre_completo", (nom + " " + apP + " " + apM).trim().replaceAll("\\s+", " "));
                    profesor.put("email", rsProfesoresList.getString("email"));
                    profesoresFacultadList.add(profesor);
                }
            } finally {
                closeDbResources(rsProfesoresList, pstmtProfesoresList);
            }

        } // Fin if (idFacultad > 0)

    } catch (SQLException | ClassNotFoundException e) {
        e.printStackTrace();
        response.sendRedirect("error.jsp?message=Error_interno_del_servidor_al_cargar_datos_de_facultad");
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
    <title>Mi Facultad - Sistema Universitario</title>
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

        /* General Card Styling */
        .content-section.card, .facultad-card.card {
            border-radius: 0.5rem;
            box-shadow: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.075);
            border-left: 4px solid var(--admin-primary); /* Consistent border */
        }
        .section-title {
            color: var(--admin-primary);
            margin-bottom: 1rem;
            font-weight: 600;
        }

        /* Specific card for "Mi Facultad Asignada" */
        .facultad-card.card {
            text-align: center;
            padding: 1.5rem;
        }
        .facultad-card h2 {
            color: var(--admin-text-dark);
            font-weight: 600;
        }
        .facultad-card h3 {
            color: var(--admin-primary);
            font-size: 2rem;
            font-weight: 700;
            margin-top: 1rem;
            margin-bottom: 0.5rem;
        }
        .facultad-card .badge {
            font-size: 0.9em;
        }

        /* Statistics Cards (similar to dashboard's stat-cards) */
        .stat-card-faculty {
            border-radius: 0.5rem;
            box-shadow: 0 0.125rem 0.25rem rgba(0,0,0,0.075);
            transition: transform 0.2s ease, box-shadow 0.2s ease;
            height: 100%;
        }
        .stat-card-faculty:hover {
            transform: translateY(-3px);
            box-shadow: 0 0.25rem 0.5rem rgba(0,0,0,0.1);
        }
        .stat-card-faculty .card-body {
            padding: 1.25rem;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }
        .stat-card-faculty .content-left {
            flex-grow: 1;
        }
        .stat-card-faculty .card-title {
            color: var(--admin-text-muted);
            font-size: 0.9rem;
            margin-bottom: 0.25rem;
            font-weight: 500;
        }
        .stat-card-faculty .value {
            font-size: 1.8rem;
            font-weight: 700;
            color: var(--admin-text-dark);
            margin-bottom: 0.25rem;
            line-height: 1;
        }
        .stat-card-faculty .icon-right {
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
        .stat-card-faculty.professors .icon-right { background-color: var(--admin-info); }
        .stat-card-faculty.courses .icon-right { background-color: var(--admin-success); }


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
        .table-info { /* Bootstrap's table-info for highlighting */
            --bs-table-bg: #e7f3ff; /* Light blue background for selected row */
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
            .stat-card-faculty .card-body {
                flex-direction: column;
                align-items: flex-start;
            }
            .stat-card-faculty .icon-right {
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
            .facultad-card h3 {
                font-size: 1.5rem;
            }
            .stat-card-faculty .value {
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
                    <a class="nav-link active" href="facultad_profesor.jsp"><i class="fas fa-building"></i><span> Facultades</span></a>
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
                    <h1 class="h3 mb-3">Facultades</h1>
                    <p class="lead">Información detallada de su facultad asignada.</p>
                </div>

                <div class="row">
                    <div class="col-12 mb-4">
                        <div class="card content-section">
                            <div class="card-body">
                                <h3 class="section-title card-title"><i class="fas fa-university me-2"></i>Mi Facultad Asignada</h3>
                                <% if (!"No asignado".equals(facultadProfesor)) {%>
                                <h3 class="text-center text-primary mt-3 mb-2"><%= facultadProfesor%></h3>
                                <p class="text-center text-muted">Aquí encontrará las estadísticas y profesores asociados a esta facultad.</p>
                                <div class="text-center"><span class="badge bg-success"><i class="fas fa-check-circle me-1"></i> Activa</span></div>
                                <% } else { %>
                                <h3 class="text-center text-danger mt-3 mb-2">No Asignado</h3>
                                <p class="text-center text-muted">Su facultad aún no ha sido asignada. Por favor, contacte al administrador.</p>
                                <div class="text-center"><span class="badge bg-warning text-dark"><i class="fas fa-exclamation-triangle me-1"></i> Sin Asignación</span></div>
                                <% } %>
                            </div>
                        </div>
                    </div>
                </div>

                <% if (!"No asignado".equals(facultadProfesor)) { %>
                <div class="row">
                    <div class="col-md-6 mb-4">
                        <div class="card stat-card-faculty professors">
                            <div class="card-body">
                                <div class="content-left">
                                    <h3 class="card-title">Total de Profesores</h3>
                                    <div class="value"><%= totalProfesoresFacultad%></div>
                                </div>
                                <div class="icon-right bg-info">
                                    <i class="fas fa-users"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-6 mb-4">
                        <div class="card stat-card-faculty courses">
                            <div class="card-body">
                                <div class="content-left">
                                    <h3 class="card-title">Total de Cursos</h3>
                                    <div class="value"><%= totalCursosFacultad%></div>
                                </div>
                                <div class="icon-right bg-success">
                                    <i class="fas fa-book"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="row">
                    <div class="col-12 mb-4">
                        <div class="card content-section">
                            <div class="card-body">
                                <h3 class="section-title card-title"><i class="fas fa-chart-pie me-2"></i>Estadísticas de Facultad</h3>
                                <div class="chart-container">
                                    <canvas id="facultyStatsChart"></canvas>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="row">
                    <div class="col-12 mb-4">
                        <div class="card content-section">
                            <div class="card-body">
                                <h3 class="section-title card-title"><i class="fas fa-chalkboard-user me-2"></i>Profesores de <%= facultadProfesor%></h3>
                                <div class="table-responsive">
                                    <table class="table table-hover table-sm">
                                        <thead>
                                            <tr>
                                                <th scope="col">Nombre Completo</th>
                                                <th scope="col">Email</th>
                                                <th scope="col">Estado</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <% if (!profesoresFacultadList.isEmpty()) {
                                                for (Map<String, String> profesor : profesoresFacultadList) {
                                                    String nombreCompletoProf = profesor.get("nombre_completo");
                                                    String emailProfesor = profesor.get("email");
                                                    boolean esUsuarioActual = email.equals(emailProfesor);
                                            %>
                                            <tr <%= esUsuarioActual ? "class='table-info'" : "" %>>
                                                <td>
                                                    <%= nombreCompletoProf %>
                                                    <% if (esUsuarioActual) { %> <span class="badge bg-primary ms-2"><i class="fas fa-user-tie"></i> Tú</span> <% } %>
                                                </td>
                                                <td><%= emailProfesor %></td>
                                                <td><span class="badge bg-success"><i class="fas fa-circle me-1" style="font-size: 0.7em;"></i> Activo</span></td>
                                            </tr>
                                            <%
                                                }
                                            } else {
                                            %>
                                            <tr>
                                                <td colspan="3" class="text-center text-muted py-3">
                                                    <i class="fas fa-info-circle me-2"></i>No hay otros profesores registrados en esta facultad.
                                                </td>
                                            </tr>
                                            <%
                                            }
                                            %>
                                        </tbody>
                                    </table>
                                </div>
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
            // Chart.js Example using data from JSP scriptlets
            const facultyStatsChart = document.getElementById('facultyStatsChart');
            if (facultyStatsChart) {
                new Chart(facultyStatsChart, {
                    type: 'pie', // Changed to pie chart for variety
                    data: {
                        labels: ['Profesores', 'Cursos'],
                        datasets: [{
                            label: 'Total',
                            data: [<%= totalProfesoresFacultad %>, <%= totalCursosFacultad %>],
                            backgroundColor: [
                                'rgba(0, 123, 255, 0.7)', // AdminKit primary blue
                                'rgba(255, 193, 7, 0.7)'  // AdminKit warning yellow
                            ],
                            borderColor: [
                                'rgba(0, 123, 255, 1)',
                                'rgba(255, 193, 7, 1)'
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
                                text: 'Distribución de Profesores y Cursos en la Facultad'
                            }
                        }
                    }
                });
            }
        });
    </script>
</body>
</html>