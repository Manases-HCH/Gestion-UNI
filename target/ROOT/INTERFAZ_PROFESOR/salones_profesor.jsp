<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, pe.universidad.util.Conection" %>
<%@ page import="java.util.Base64" %>
<%@ page session="true" %>

<%!
    // Método auxiliar para cerrar ResultSet y PreparedStatement de forma segura.
    private void closeDbResources(ResultSet rs, PreparedStatement pstmt) {
        try {
            if (rs != null) {
                rs.close();
            }
        } catch (SQLException e) {
            System.err.println("Error al cerrar ResultSet: " + e.getMessage());
        }
        try {
            if (pstmt != null) {
                pstmt.close();
            }
        } catch (SQLException e) {
            System.err.println("Error al cerrar PreparedStatement: " + e.getMessage());
        }
    }

    // Declaración de variable a nivel de clase (generada en el servlet)
    String globalDbErrorMessage = null;
%>

<%
    // --- VALIDACIÓN DE SESIÓN INICIAL ---
    String emailSesion = (String) session.getAttribute("email");
    String rolUsuario = (String) session.getAttribute("rol");
    Object idProfesorObj = session.getAttribute("id_profesor");

    // Redirigir si el usuario no está logueado, no es profesor o no tiene un ID de profesor en sesión
    if (emailSesion == null || !"profesor".equalsIgnoreCase(rolUsuario) || idProfesorObj == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    // Datos del profesor logueado, obtenidos de la sesión
    int idProfesor = -1;
    if (idProfesorObj instanceof Integer) {
        idProfesor = (Integer) idProfesorObj;
    } else {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    String nombreProfesor = "";
    String emailProfesor = emailSesion;
    String facultadProfesor = "No Asignada";

    // Variables para estadísticas
    int totalClases = 0;
    int totalAlumnos = 0;
    int totalCapacidadClasesActivas = 0;
    int totalAlumnosEnClasesActivas = 0;

    // Variables para contadores de solicitudes (aunque no se usan en este JSP visualmente)
    int totalPendingJoinRequests = 0;
    int totalPendingLeaveRequests = 0;

    String mensaje = "";
    String tipoMensaje = "info";

    Connection conn = null;

    try {
        Conection conUtil = new Conection();
        conn = conUtil.conecta();

        if (conn == null || conn.isClosed()) {
            throw new SQLException("No se pudo establecer conexión a la base de datos.");
        }

        // --- 1. Obtener información detallada del profesor ---
        PreparedStatement pstmtProfesorInfo = null;
        ResultSet rsProfesorInfo = null;
        try {
            String sqlProfesorInfo = "SELECT CONCAT(p.nombre, ' ', p.apellido_paterno, ' ', IFNULL(p.apellido_materno, '')) AS nombre_completo, f.nombre_facultad as facultad "
                                   + "FROM profesores p "
                                   + "LEFT JOIN facultades f ON p.id_facultad = f.id_facultad "
                                   + "WHERE p.id_profesor = ?";
            pstmtProfesorInfo = conn.prepareStatement(sqlProfesorInfo);
            pstmtProfesorInfo.setInt(1, idProfesor);
            rsProfesorInfo = pstmtProfesorInfo.executeQuery();

            if (rsProfesorInfo.next()) {
                nombreProfesor = rsProfesorInfo.getString("nombre_completo");
                facultadProfesor = rsProfesorInfo.getString("facultad") != null ? rsProfesorInfo.getString("facultad") : "No asignada";
            } else {
                globalDbErrorMessage = "No se encontró información detallada para el profesor con ID " + idProfesor + ".";
            }
        } finally {
            closeDbResources(rsProfesorInfo, pstmtProfesorInfo);
        }

        // --- 3. Obtener estadísticas de clases para el profesor ---
        PreparedStatement pstmtStats = null;
        ResultSet rsStats = null;
        try {
            String sqlStats = "SELECT "
                              + "COUNT(DISTINCT cl.id_clase) as total_clases, "
                              + "COUNT(DISTINCT i.id_alumno) as total_alumnos_unicos, "
                              + "SUM(CASE WHEN cl.estado = 'activo' THEN cl.capacidad_maxima ELSE 0 END) as total_capacidad_clases_activas, "
                              + "SUM(CASE WHEN cl.estado = 'activo' THEN "
                              + "    (SELECT COUNT(*) FROM inscripciones sub_i WHERE sub_i.id_clase = cl.id_clase AND sub_i.estado = 'inscrito') "
                              + "    ELSE 0 END) as total_alumnos_en_clases_activas "
                              + "FROM clases cl "
                              + "LEFT JOIN inscripciones i ON cl.id_clase = i.id_clase "
                              + "WHERE cl.id_profesor = ?";
            pstmtStats = conn.prepareStatement(sqlStats);
            pstmtStats.setInt(1, idProfesor);
            rsStats = pstmtStats.executeQuery();

            if (rsStats.next()) {
                totalClases = rsStats.getInt("total_clases");
                totalAlumnos = rsStats.getInt("total_alumnos_unicos");
                totalCapacidadClasesActivas = rsStats.getInt("total_capacidad_clases_activas");
                totalAlumnosEnClasesActivas = rsStats.getInt("total_alumnos_en_clases_activas");
            }
        } finally {
            closeDbResources(rsStats, pstmtStats);
        }

        // --- 4. Obtener Conteo de Solicitudes Pendientes ---
        PreparedStatement pstmtPending = null;
        ResultSet rsPending = null;
        try {
            String sqlPendingJoin = "SELECT COUNT(*) FROM solicitudes_cursos WHERE id_profesor = ? AND tipo_solicitud = 'UNIRSE' AND estado = 'PENDIENTE'";
            pstmtPending = conn.prepareStatement(sqlPendingJoin);
            pstmtPending.setInt(1, idProfesor);
            rsPending = pstmtPending.executeQuery();
            if (rsPending.next()) {
                totalPendingJoinRequests = rsPending.getInt(1);
            }
            closeDbResources(rsPending, pstmtPending);

            String sqlPendingLeave = "SELECT COUNT(*) FROM solicitudes_cursos WHERE id_profesor = ? AND tipo_solicitud = 'SALIR' AND estado = 'PENDIENTE'";
            pstmtPending = conn.prepareStatement(sqlPendingLeave);
            pstmtPending.setInt(1, idProfesor);
            rsPending = pstmtPending.executeQuery();
            if (rsPending.next()) {
                totalPendingLeaveRequests = rsPending.getInt(1);
            }
        } finally {
            closeDbResources(rsPending, pstmtPending);
        }

    } catch (SQLException e) {
        globalDbErrorMessage = "Error de base de datos en la carga principal: " + e.getMessage();
        e.printStackTrace();
    }
    // Removed the ClassNotFoundException catch block here
    finally {
        // Connection 'conn' is closed at the very end of the JSP
    }
%>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Clases del Profesor - Sistema Universitario</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.0/font/bootstrap-icons.css">
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.6.0/jquery.min.js"></script>
    <style>
        /* Your CSS styles (omitted for brevity, assume they are the same as before) */
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

        /* Stats Grid for this page */
        .stats-grid-clases {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); /* Adjusted for more stats */
            gap: 1.5rem;
            margin-bottom: 1.5rem;
        }
        .stats-card-clases {
            border-radius: 0.5rem;
            box-shadow: 0 0.125rem 0.25rem rgba(0,0,0,0.075);
            transition: transform 0.2s ease, box-shadow 0.2s ease;
            height: 100%;
        }
        .stats-card-clases:hover {
            transform: translateY(-3px);
            box-shadow: 0 0.25rem 0.5rem rgba(0,0,0,0.1);
        }
        .stats-card-clases .card-body {
            padding: 1.25rem;
            display: flex;
            flex-direction: column; /* Stack content vertically */
            align-items: center;
            text-align: center;
        }
        .stats-card-clases .stat-icon {
            font-size: 2rem;
            color: var(--admin-primary);
            margin-bottom: 0.5rem;
        }
        .stats-card-clases .value {
            font-size: 2.2rem;
            font-weight: 700;
            color: var(--admin-text-dark);
            line-height: 1;
            margin-bottom: 0.5rem;
        }
        .stats-card-clases .label {
            font-size: 0.9rem;
            color: var(--admin-text-muted);
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
        .badge-success-custom { background-color: rgba(40, 167, 69, 0.1); color: var(--admin-success); border: 1px solid var(--admin-success); }
        .badge-primary-custom { background-color: rgba(0, 123, 255, 0.1); color: var(--admin-primary); border: 1px solid var(--admin-primary); }
        .badge-secondary-custom { background-color: rgba(108, 117, 125, 0.1); color: var(--admin-secondary-color); border: 1px solid var(--admin-secondary-color); }

        /* Empty states / Error messages */
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
        .alert-error-message {
            background-color: rgba(220, 53, 69, 0.1);
            border-color: var(--admin-danger);
            color: var(--admin-danger);
        }

        /* Modal specific styles */
        #viewStudentsModal .modal-header {
            background-color: var(--admin-primary);
            color: white;
            border-bottom: none;
        }
        #viewStudentsModal .modal-title {
            color: white;
        }
        #viewStudentsModal .modal-footer {
            border-top: none;
        }
        #viewStudentsModal .table th {
            background-color: var(--admin-light-bg);
            color: var(--admin-primary);
        }

        /* Custom button for 'Solicitar agregar clase' */
        .btn-add-class {
            background-color: var(--admin-primary);
            color: white;
            padding: 0.75rem 1.5rem;
            border: none;
            border-radius: 0.5rem;
            font-size: 1.1rem;
            box-shadow: 0 4px 8px rgba(0,0,0,0.1);
            transition: all 0.3s ease;
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            text-decoration: none;
        }
        .btn-add-class:hover {
            background-color: #0056b3;
            transform: translateY(-2px);
            box-shadow: 0 6px 12px rgba(0,0,0,0.15);
            color: white;
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
            .stats-grid-clases {
                grid-template-columns: 1fr;
            }
        }

        @media (max-width: 576px) {
            .main-content {
                padding: 0.75rem;
            }
            .welcome-section, .card {
                padding: 1rem;
            }
            .stats-card-clases .value {
                font-size: 1.8rem;
            }
            .btn-add-class {
                font-size: 1rem;
                padding: 0.6rem 1rem;
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
                    <a class="nav-link active" href="salones_profesor.jsp"><i class="fas fa-chalkboard"></i><span> Clases</span></a>
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
                    <h1 class="h3 mb-3">Gestión de Clases</h1>
                    <p class="lead">Bienvenido al módulo de clases. Aquí puedes ver tus clases asignadas y gestionar a los estudiantes.</p>
                </div>

                <% // Mostrar mensaje de error global de la base de datos si existe
                    if (globalDbErrorMessage != null) { %>
                <div class="alert alert-danger alert-error-message" role="alert">
                    <i class="fas fa-exclamation-triangle me-2"></i>Error al cargar la página: <%= globalDbErrorMessage %>
                </div>
                <% } %>

                <div class="row stats-grid-clases">
                    <div class="col">
                        <div class="card stats-card-clases" style="border-left: 4px solid var(--admin-primary);">
                            <div class="card-body">
                                <div class="stat-icon"><i class="fas fa-chalkboard"></i></div>
                                <div class="value"><%= totalClases %></div>
                                <div class="label">Total Clases Asignadas</div>
                            </div>
                        </div>
                    </div>
                    <div class="col">
                        <div class="card stats-card-clases" style="border-left: 4px solid var(--admin-success);">
                            <div class="card-body">
                                <div class="stat-icon"><i class="fas fa-user-graduate"></i></div>
                                <div class="value"><%= totalAlumnos %></div>
                                <div class="label">Alumnos Únicos Inscritos</div>
                            </div>
                        </div>
                    </div>
                    <div class="col">
                        <div class="card stats-card-clases" style="border-left: 4px solid var(--admin-info);">
                            <div class="card-body">
                                <div class="stat-icon"><i class="fas fa-chart-pie"></i></div>
                                <%
                                    double porcentajeOcupacionGeneral = 0.0;
                                    if (totalCapacidadClasesActivas > 0) {
                                        porcentajeOcupacionGeneral = ((double)totalAlumnosEnClasesActivas / totalCapacidadClasesActivas) * 100;
                                    }
                                %>
                                <div class="value"><%= String.format("%.0f%%", porcentajeOcupacionGeneral) %></div>
                                <div class="label">Ocupación Clases Activas</div>
                            </div>
                        </div>
                    </div>
                    <div class="col">
                        <div class="card stats-card-clases" style="border-left: 4px solid var(--admin-warning);">
                            <div class="card-body">
                                <div class="stat-icon"><i class="fas fa-users-slash"></i></div>
                                <div class="value">N/A</div> <%-- Placeholder for another relevant metric --%>
                                <div class="label">Clases Llenas</div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="row">
                    <div class="col-12 mb-4">
                        <div class="card content-section">
                            <div class="card-body">
                                <h3 class="section-title card-title"><i class="fas fa-list-ul me-2"></i>Detalle de Mis Clases</h3>
                                <div class="table-responsive">
                                    <table class="table table-hover table-sm">
                                        <thead>
                                            <tr>
                                                <th scope="col">Clase</th>
                                                <th scope="col">Curso</th>
                                                <th scope="col">Horario</th>
                                                <th scope="col">Aula</th>
                                                <th scope="col">Alumnos / Cap.</th>
                                                <th scope="col">Estado</th>
                                                <th scope="col">Acciones</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <%
                                                PreparedStatement localPstmtClases = null;
                                                ResultSet localRsClases = null;
                                                boolean hayClases = false;
                                                try {
                                                    if (conn != null && !conn.isClosed() && idProfesor != -1) {
                                                        String sqlClases = "SELECT cl.id_clase, cl.seccion, cl.ciclo, cl.semestre, cl.año_academico, cl.estado AS clase_estado, cl.capacidad_maxima, "
                                                                         + "cu.nombre_curso, cu.codigo_curso, "
                                                                         + "h.dia_semana, h.hora_inicio, h.hora_fin, h.aula, "
                                                                         + "(SELECT COUNT(*) FROM inscripciones i WHERE i.id_clase = cl.id_clase AND i.estado = 'inscrito') as alumnos_inscritos "
                                                                         + "FROM clases cl "
                                                                         + "INNER JOIN cursos cu ON cl.id_curso = cu.id_curso "
                                                                         + "INNER JOIN horarios h ON cl.id_horario = h.id_horario "
                                                                         + "WHERE cl.id_profesor = ? "
                                                                         + "ORDER BY cl.año_academico DESC, cl.semestre DESC, cu.nombre_curso, cl.seccion";

                                                        localPstmtClases = conn.prepareStatement(sqlClases);
                                                        localPstmtClases.setInt(1, idProfesor);
                                                        localRsClases = localPstmtClases.executeQuery();

                                                        while (localRsClases.next()) {
                                                            hayClases = true;
                                                            int idClase = localRsClases.getInt("id_clase");
                                                            String estadoClase = localRsClases.getString("clase_estado");
                                                            String badgeClass = "";
                                                            if ("activo".equals(estadoClase)) {
                                                                badgeClass = "badge-success-custom";
                                                            } else if ("finalizado".equals(estadoClase)) {
                                                                badgeClass = "badge-primary-custom";
                                                            } else { // inactivo
                                                                badgeClass = "badge-secondary-custom";
                                                            }

                                                            int alumnosInscritos = localRsClases.getInt("alumnos_inscritos");
                                                            int capacidadMaxima = localRsClases.getInt("capacidad_maxima");
                                                %>
                                            <tr>
                                                <td>
                                                    <strong><%= localRsClases.getString("seccion")%> - <%= localRsClases.getString("ciclo")%></strong>
                                                    <br><small class="text-muted"><%= localRsClases.getString("semestre")%> / <%= localRsClases.getInt("año_academico")%></small>
                                                </td>
                                                <td>
                                                    <%= localRsClases.getString("nombre_curso")%>
                                                    <br><small class="text-muted">Código: <%= localRsClases.getString("codigo_curso")%></small>
                                                </td>
                                                <td>
                                                    <%= localRsClases.getString("dia_semana")%><br>
                                                    <%= localRsClases.getTime("hora_inicio")%> - <%= localRsClases.getTime("hora_fin")%>
                                                </td>
                                                <td><%= localRsClases.getString("aula") %></td>
                                                <td><%= alumnosInscritos%> / <%= capacidadMaxima%></td>
                                                <td><span class="badge <%= badgeClass%>"><%= estadoClase.toUpperCase()%></span></td>
                                                <td>
                                                    <a href="ver_estudiantes.jsp?id_clase=<%= idClase %>" class="btn btn-sm btn-primary">
                                                        <i class="fas fa-eye me-1"></i> Ver Estudiantes
                                                    </a>
                                                </td>
                                            </tr>
                                                <%
                                                        } // Cierre de while

                                                        if (!hayClases) {
                                                %>
                                            <tr>
                                                <td colspan="7" class="empty-state">
                                                    <i class="fas fa-exclamation-circle"></i>
                                                    <h4>No tienes clases asignadas.</h4>
                                                    <p>Contacta al administrador para la asignación de clases.</p>
                                                </td>
                                            </tr>
                                                <%
                                                        }
                                                    }
                                                    else if (idProfesor == -1) {
                                                %>
                                                <tr>
                                                    <td colspan="7" class="alert alert-warning text-center" role="alert">
                                                        <i class="fas fa-exclamation-triangle me-2"></i>No se pudo obtener el ID del profesor. Por favor, re-inicia sesión.
                                                    </td>
                                                </tr>
                                                <%
                                                    }
                                                } catch (SQLException e) {
                                                    globalDbErrorMessage = "Error de SQL al cargar las clases: " + e.getMessage();
                                                    e.printStackTrace();
                                                %>
                                                <tr>
                                                    <td colspan="7" class="alert alert-danger text-center" role="alert">
                                                        <i class="fas fa-exclamation-triangle me-2"></i>Error de SQL al cargar las clases: <%= e.getMessage() %>
                                                    </td>
                                                </tr>
                                                <%
                                                }
                                                // The problematic ClassNotFoundException catch block is removed from here
                                                finally {
                                                    closeDbResources(localRsClases, localPstmtClases);
                                                }
                                                %>
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="text-end mt-4 mb-4">
                    <a href="solicitar_clase.jsp" class="btn-add-class">
                        <i class="fas fa-plus-circle me-2"></i>Solicitar Nueva Clase
                    </a>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js" integrity="sha384-YvpcrYf0tY3lHB60NNkmXc5s9fDVZLESaAA55NDzOxhy9GkcIdslK1eN7N6jIeHz" crossorigin="anonymous"></script>
</body>
</html>
<%
    if (conn != null) {
        try {
            conn.close();
        } catch (SQLException ignore) {
            System.err.println("Error al cerrar la conexión principal: " + ignore.getMessage());
        }
    }
%>