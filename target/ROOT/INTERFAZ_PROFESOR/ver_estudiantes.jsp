<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, pe.universidad.util.Conection" %>
<%@ page session="true" %>

<%!
    // Método auxiliar para cerrar ResultSet y PreparedStatement de forma segura.
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

    // El método escapeJsonForJs ya no es estrictamente necesario si no se genera JSON para JS,
    // pero lo dejamos si hay otras partes del código que lo puedan usar o para futuras expansiones.
    private String escapeJsonForJs(String text) {
        if (text == null) {
            return ""; 
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
                case '\'':
                    sb.append("\\'");
                    break;
                default:
                    if (ch >= 0x00 && ch <= 0x1F) {
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
    // --- VALIDACIÓN DE SESIÓN INICIAL ---
    String emailSesion = (String) session.getAttribute("email");
    String rolUsuario = (String) session.getAttribute("rol");
    Object idProfesorObj = session.getAttribute("id_profesor");

    if (emailSesion == null || !"profesor".equalsIgnoreCase(rolUsuario) || idProfesorObj == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    int idProfesor = (Integer) idProfesorObj;
    String nombreProfesor = "";
    String facultadProfesor = "Sin asignar";

    String idClaseParam = request.getParameter("id_clase");
    int idClase = -1;
    String nombreClase = "Clase Desconocida";
    String codigoCursoClase = "";
    String seccionClase = "";
    String cicloClase = "";
    // estudiantesList ya no necesita todos los campos del perfil si no se muestran en el modal.
    // Solo los necesarios para la tabla.
    List<Map<String, String>> estudiantesList = new ArrayList<>();

    int totalPendingJoinRequests = 0;
    int totalPendingLeaveRequests = 0;

    Connection conn = null;
    String localErrorMessage = null;

    try {
        pe.universidad.util.Conection conUtil = new pe.universidad.util.Conection();
        conn = conUtil.conecta();

        if (conn == null || conn.isClosed()) {
            throw new SQLException("No se pudo establecer conexión a la base de datos.");
        }

        PreparedStatement pstmtProfesorInfo = null;
        ResultSet rsProfesorInfo = null;
        try {
            String sqlProfesorInfo = "SELECT p.nombre, p.apellido_paterno, p.apellido_materno, f.nombre_facultad "
                                   + "FROM profesores p LEFT JOIN facultades f ON p.id_facultad = f.id_facultad "
                                   + "WHERE p.id_profesor = ?";
            pstmtProfesorInfo = conn.prepareStatement(sqlProfesorInfo);
            pstmtProfesorInfo.setInt(1, idProfesor);
            rsProfesorInfo = pstmtProfesorInfo.executeQuery();

            if (rsProfesorInfo.next()) {
                String nom = rsProfesorInfo.getString("nombre") != null ? rsProfesorInfo.getString("nombre") : "";
                String apP = rsProfesorInfo.getString("apellido_paterno") != null ? rsProfesorInfo.getString("apellido_paterno") : "";
                String apM = rsProfesorInfo.getString("apellido_materno") != null ? rsProfesorInfo.getString("apellido_materno") : "";
                nombreProfesor = (nom + " " + apP + " " + apM).trim().replaceAll("\\s+", " ");
                facultadProfesor = rsProfesorInfo.getString("nombre_facultad") != null ? rsProfesorInfo.getString("nombre_facultad") : "Sin asignar";
            } else {
                localErrorMessage = "No se encontró información detallada para el profesor con ID " + idProfesor + ".";
            }
        } finally {
            closeDbResources(rsProfesorInfo, pstmtProfesorInfo);
        }

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

            pstmtPending = conn.prepareStatement("SELECT COUNT(*) FROM solicitudes_cursos WHERE id_profesor = ? AND tipo_solicitud = 'SALIR' AND estado = 'PENDIENTE'");
            pstmtPending.setInt(1, idProfesor);
            rsPending = pstmtPending.executeQuery();
            if (rsPending.next()) {
                totalPendingLeaveRequests = rsPending.getInt(1);
            }
        } finally {
            closeDbResources(rsPending, pstmtPending);
        }

        if (idClaseParam != null && !idClaseParam.isEmpty()) {
            try {
                idClase = Integer.parseInt(idClaseParam);
            } catch (NumberFormatException e) {
                localErrorMessage = "ID de clase inválido en la URL.";
            }

            if (idClase != -1) {
                PreparedStatement pstmtClaseInfo = null;
                ResultSet rsClaseInfo = null;
                try {
                    String sqlClaseInfo = "SELECT cl.seccion, cl.ciclo, cu.nombre_curso, cu.codigo_curso "
                                        + "FROM clases cl JOIN cursos cu ON cl.id_curso = cu.id_curso "
                                        + "WHERE cl.id_clase = ? AND cl.id_profesor = ?";
                    pstmtClaseInfo = conn.prepareStatement(sqlClaseInfo);
                    pstmtClaseInfo.setInt(1, idClase);
                    pstmtClaseInfo.setInt(2, idProfesor);
                    rsClaseInfo = pstmtClaseInfo.executeQuery();
                    if (rsClaseInfo.next()) {
                        nombreClase = rsClaseInfo.getString("nombre_curso") + " - " + rsClaseInfo.getString("seccion");
                        codigoCursoClase = rsClaseInfo.getString("codigo_curso");
                        seccionClase = rsClaseInfo.getString("seccion");
                        cicloClase = rsClaseInfo.getString("ciclo");
                    } else {
                        localErrorMessage = "Clase no encontrada o no asignada a este profesor.";
                    }
                } finally {
                    closeDbResources(rsClaseInfo, pstmtClaseInfo);
                }

                if (localErrorMessage == null) {
                    PreparedStatement pstmtEstudiantes = null;
                    ResultSet rsEstudiantes = null;
                    try {
                        // SQL ahora solo trae lo necesario para la tabla
                        String sqlEstudiantes = "SELECT a.id_alumno, a.nombre, a.apellido_paterno, a.apellido_materno, a.email, "
                                              + "i.estado AS estado_inscripcion "
                                              + "FROM alumnos a "
                                              + "JOIN inscripciones i ON a.id_alumno = i.id_alumno "
                                              + "WHERE i.id_clase = ? ORDER BY a.apellido_paterno, a.nombre";
                        pstmtEstudiantes = conn.prepareStatement(sqlEstudiantes);
                        pstmtEstudiantes.setInt(1, idClase);
                        rsEstudiantes = pstmtEstudiantes.executeQuery();
                        while (rsEstudiantes.next()) {
                            Map<String, String> estudiante = new HashMap<>();
                            estudiante.put("id_alumno", String.valueOf(rsEstudiantes.getInt("id_alumno")));
                            String nom = rsEstudiantes.getString("nombre") != null ? rsEstudiantes.getString("nombre") : "";
                            String apP = rsEstudiantes.getString("apellido_paterno") != null ? rsEstudiantes.getString("apellido_paterno") : "";
                            String apM = rsEstudiantes.getString("apellido_materno") != null ? rsEstudiantes.getString("apellido_materno") : "";
                            estudiante.put("nombre_completo", (nom + " " + apP + " " + apM).trim().replaceAll("\\s+", " "));
                            estudiante.put("email", rsEstudiantes.getString("email"));
                            estudiante.put("estado_inscripcion", rsEstudiantes.getString("estado_inscripcion"));
                            
                            // Ya no necesitamos poner todos los campos de perfil en el Map
                            // si el modal no los va a usar o no existe.

                            estudiantesList.add(estudiante);
                        }
                    } finally {
                        closeDbResources(rsEstudiantes, pstmtEstudiantes);
                    }
                }
            }
        } else {
            localErrorMessage = "No se proporcionó un ID de clase para ver los estudiantes.";
        }

    } catch (SQLException e) {
        localErrorMessage = "Error de base de datos: " + e.getMessage();
        e.printStackTrace();
    } catch (ClassNotFoundException e) {
        localErrorMessage = "Error: No se encontró el driver JDBC de MySQL. Asegúrate de que mysql-connector-java.jar esté en WEB-INF/lib.";
        e.printStackTrace();
    } finally {
        try {
            if (conn != null) {
                conn.close();
            }
        } catch (SQLException e) { /* Ignorar */ }
    }
%>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Estudiantes de Clase - Sistema Universitario</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.6.0/jquery.min.js"></script>
    <style>
        /* Tu CSS existente */
        :root {
            --admin-dark: #222B40; --admin-light-bg: #F0F2F5; --admin-card-bg: #FFFFFF;
            --admin-text-dark: #333333; --admin-text-muted: #6C757D;
            --admin-primary: #007BFF; --admin-success: #28A745; --admin-danger: #DC3545;
            --admin-warning: #FFC107; --admin-info: #17A2B8; --admin-secondary-color: #6C757D;
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

        /* Class Info Card */
        .class-info-card {
            border-left: 4px solid var(--admin-info);
            box-shadow: 0 0.125rem 0.25rem rgba(0,0,0,0.075);
            border-radius: 0.5rem;
            padding: 1.5rem;
            margin-bottom: 1.5rem;
        }
        .class-info-card h3 {
            color: var(--admin-text-dark);
            font-weight: 600;
            margin-bottom: 0.5rem;
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }
        .class-info-card p {
            margin-bottom: 0.2rem;
            color: var(--admin-text-muted);
        }
        .class-info-card p strong {
            color: var(--admin-text-dark);
        }

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
        .btn-back-to-clases {
            background-color: var(--admin-secondary-color);
            color: white;
            padding: 0.75rem 1.5rem;
            border-radius: 0.5rem;
            text-decoration: none;
            transition: background-color 0.2s ease;
        }
        .btn-back-to-clases:hover {
            background-color: #5a6268;
            color: white;
        }

        /* Estilos específicos para el modal de perfil */
        #studentProfileContent p {
            margin-bottom: 0.5rem;
            padding: 0.2rem 0;
            border-bottom: 1px dashed var(--admin-light-bg);
        }
        #studentProfileContent p:last-child {
            border-bottom: none;
        }
        #studentProfileContent p strong {
            display: inline-block;
            width: 160px; /* Ancho fijo para alinear las etiquetas */
            color: var(--admin-primary); /* Color para las etiquetas */
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
            .top-navbar .user-dropdown .dropdown-toggle {
                justify-content: center;
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
                    <h1 class="h3 mb-3">Estudiantes de Clase</h1>
                    <p class="lead">Listado de estudiantes inscritos en la clase: <strong><%= nombreClase %></strong> (Código: <%= codigoCursoClase %> / Sección: <%= seccionClase %> / Ciclo: <%= cicloClase %>)</p>
                </div>

                <% if (localErrorMessage != null) { %>
                <div class="alert alert-danger alert-error-message" role="alert">
                    <i class="fas fa-exclamation-triangle me-2"></i>Error al cargar la página: <%= localErrorMessage %>
                </div>
                <% } %>

                <div class="row">
                    <div class="col-12 mb-4">
                        <div class="card content-section">
                            <div class="card-body">
                                <h3 class="section-title card-title"><i class="fas fa-users me-2"></i>Lista de Estudiantes</h3>
                                <div class="table-responsive">
                                    <table class="table table-hover table-sm">
                                        <thead>
                                            <tr>
                                                <th scope="col">ID Alumno</th>
                                                <th scope="col">Nombre Completo</th>
                                                <th scope="col">Email</th>
                                                <th scope="col">Estado Inscripción</th>
                                                <th scope="col">Acciones</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <% if (estudiantesList.isEmpty()) { %>
                                            <tr>
                                                <td colspan="5" class="empty-state">
                                                    <i class="fas fa-user-times"></i>
                                                    <h4>No hay estudiantes inscritos en esta clase.</h4>
                                                    <p>La lista de estudiantes está vacía o hubo un problema al cargarla.</p>
                                                </td>
                                            </tr>
                                            <% } else {
                                                for (Map<String, String> estudiante : estudiantesList) {
                                                    String estadoInscripcion = estudiante.get("estado_inscripcion");
                                                    String badgeClass = "";
                                                    if ("inscrito".equals(estadoInscripcion)) {
                                                        badgeClass = "badge-success-custom";
                                                    } else if ("pendiente".equals(estadoInscripcion)) {
                                                        badgeClass = "badge-warning";
                                                    } else {
                                                        badgeClass = "badge-secondary-custom";
                                                    }
                                            %>
                                            <tr>
                                                <td><%= estudiante.get("id_alumno") %></td>
                                                <td><%= estudiante.get("nombre_completo") %></td>
                                                <td><%= estudiante.get("email") %></td>
                                                <td><span class="badge <%= badgeClass%>"><%= estadoInscripcion.toUpperCase()%></span></td>
                                                <td>
                                                    <a href="asignar_notas.jsp?id_clase=<%= idClase %>&id_alumno=<%= estudiante.get("id_alumno") %>" class="btn btn-sm btn-success" title="Asignar Notas">
                                                        <i class="fas fa-percent"></i> Asignar Notas
                                                    </a>
                                                </td>
                                            </tr>
                                            <%
                                                }
                                            }
                                            %>
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="text-start mt-4 mb-4">
                    <a href="salones_profesor.jsp" class="btn btn-back-to-clases">
                        <i class="fas fa-arrow-left me-2"></i>Volver a Mis Clases
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
        }
    }
%>