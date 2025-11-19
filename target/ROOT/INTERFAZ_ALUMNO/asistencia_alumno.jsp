<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, pe.universidad.util.Conection" %>
<%@ page import="java.time.LocalDate, java.time.format.DateTimeFormatter, java.time.format.TextStyle, java.time.temporal.TemporalAdjusters" %>
<%@ page import="java.util.Locale" %> <%-- Para formato de números y fechas --%>
<%@ page import="java.time.LocalDateTime" %> <%-- ADDED THIS IMPORT --%>
<%@ page session="true" %>

<%!
    // Método para cerrar recursos de BD
    private static void cerrarRecursos(ResultSet rs, PreparedStatement pstmt) {
        try {
            if (rs != null) {
                rs.close();
            }
        } catch (SQLException e) {
            System.err.println("Error cerrando ResultSet: " + e.getMessage());
        }
        try {
            if (pstmt != null) {
                pstmt.close();
            }
        } catch (SQLException e) {
            System.err.println("Error cerrando PreparedStatement: " + e.getMessage());
        }
    }
%>

<%
    // --- Obtener información de la sesión ---
    String emailSesion = (String) session.getAttribute("email");
    String rolUsuario = (String) session.getAttribute("rol");
    Object idAlumnoObj = session.getAttribute("id_alumno"); // Changed from idApoderadoObj

    // --- Variables para los datos del alumno ---
    int idAlumno = -1;    // Changed from idApoderado
    String nombreAlumno = "Alumno Desconocido"; // Changed from nombreApoderado
    String dniAlumno = "N/A"; // Added for alumno info
    String emailAlumno = (emailSesion != null ? emailSesion : "N/A"); // Changed from emailApoderado
    String telefonoAlumno = "No registrado"; // Not explicitly used for display on this page, but kept
    String carreraAlumno = "Carrera Desconocida"; // Added for alumno info
    String estadoAlumno = "N/A"; // Estado académico del alumno (activo, inactivo, egresado)
    String ultimoAcceso = ""; // Will be updated with current server time

    List<Map<String, String>> asistenciaAlumnoList = new ArrayList<>(); // Changed from asistenciaHijoList

    // --- Datos para el gráfico lineal de asistencia mensual ---
    LocalDate hoy = LocalDate.now();
    int anioActual = hoy.getYear();
    int mesActual = hoy.getMonthValue();
    LocalDate primerDiaMes = LocalDate.of(anioActual, mesActual, 1);
    LocalDate ultimoDiaMes = primerDiaMes.with(TemporalAdjusters.lastDayOfMonth());
    String nombreMesActual = primerDiaMes.getMonth().getDisplayName(TextStyle.FULL, new Locale("es", "ES"));

    List<String> fechasAsistenciaMes = new ArrayList<>();
    List<Integer> presentesPorDia = new ArrayList<>();
    List<Integer> ausentesPorDia = new ArrayList<>();
    List<Integer> tardanzasPorDia = new ArrayList<>();
    List<Integer> justificadosPorDia = new ArrayList<>();

    Connection conn = null;    
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    String globalErrorMessage = null; // General error message for UI

    try {
        // --- 1. Validar y obtener ID del Alumno de Sesión ---
        if (emailSesion == null || !"alumno".equalsIgnoreCase(rolUsuario) || idAlumnoObj == null) {
            System.out.println("DEBUG (asistencia_alumno): Sesión inválida o rol incorrecto. Redirigiendo a login.");
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }
        try {
            idAlumno = Integer.parseInt(String.valueOf(idAlumnoObj)); // Changed from idApoderado
            System.out.println("DEBUG (asistencia_alumno): ID Alumno de sesión: " + idAlumno); // Changed log
        } catch (NumberFormatException e) {
            System.err.println("ERROR (asistencia_alumno): ID de alumno en sesión no es un número válido. " + e.getMessage()); // Changed log
            globalErrorMessage = "Error de sesión: ID de alumno inválido."; // Changed message
        }

        // If idAlumno is valid, try to connect and load data
        if (idAlumno != -1 && globalErrorMessage == null) {
            // --- 2. Conectar a la Base de Datos ---
            Conection c = new Conection();
            conn = c.conecta();
            if (conn == null || conn.isClosed()) {
                throw new SQLException("No se pudo establecer conexión a la base de datos.");
            }
            System.out.println("DEBUG (asistencia_alumno): Conexión a BD establecida."); // Changed log

            // --- 3. Obtener Nombre y Datos del Alumno para el encabezado y tablas (using vista_alumnos_completa) ---
            try {
                // Assuming vista_alumnos_completa includes all necessary fields like dni, nombre_completo, carrera, estado
                String sqlAlumnoInfo = "SELECT dni, nombre_completo, email, telefono, nombre_carrera, estado FROM vista_alumnos_completa WHERE id_alumno = ?";
                pstmt = conn.prepareStatement(sqlAlumnoInfo);
                pstmt.setInt(1, idAlumno);
                rs = pstmt.executeQuery();
                if (rs.next()) {
                    nombreAlumno = rs.getString("nombre_completo");
                    dniAlumno = rs.getString("dni") != null ? rs.getString("dni") : "N/A";
                    emailAlumno = rs.getString("email");
                    telefonoAlumno = rs.getString("telefono") != null ? rs.getString("telefono") : "No registrado";
                    carreraAlumno = rs.getString("nombre_carrera") != null ? rs.getString("nombre_carrera") : "Desconocida";
                    estadoAlumno = rs.getString("estado") != null ? rs.getString("estado") : "N/A";
                    session.setAttribute("nombre_alumno", nombreAlumno); // Save to session for other pages
                    System.out.println("DEBUG (asistencia_alumno): Datos de alumno cargados: " + nombreAlumno); // Changed log
                } else {
                    globalErrorMessage = "Tu información de alumno no se encontró en la base de datos. Por favor, contacta a soporte."; // Changed message
                    System.err.println("ERROR (asistencia_alumno): Alumno con ID " + idAlumno + " no encontrado en BD."); // Changed log
                }
            } finally { cerrarRecursos(rs, pstmt); }

            // --- 4. Obtener Registros de Asistencia del Alumno (if alumno assigned and no prior errors) ---
            if (globalErrorMessage == null) {
                // a) Historial de Asistencia Detallado (para la tabla)
                String sqlAsistencia = "SELECT a.fecha, a.estado, a.observaciones, "
                                       + "cu.nombre_curso, cl.seccion, cl.semestre, cl.año_academico "
                                       + "FROM asistencia a "
                                       + "JOIN inscripciones i ON a.id_inscripcion = i.id_inscripcion "
                                       + "JOIN clases cl ON i.id_clase = cl.id_clase "
                                       + "JOIN cursos cu ON cl.id_curso = cu.id_curso "
                                       + "WHERE i.id_alumno = ? " // Filter by id_alumno
                                       + "ORDER BY a.fecha DESC, cu.nombre_curso ASC";
                
                pstmt = conn.prepareStatement(sqlAsistencia);
                pstmt.setInt(1, idAlumno); // Use idAlumno
                rs = pstmt.executeQuery();

                while(rs.next()) {
                    Map<String, String> asistenciaRecord = new HashMap<>();
                    asistenciaRecord.put("fecha", rs.getDate("fecha").toString());
                    asistenciaRecord.put("estado", rs.getString("estado").toUpperCase());
                    String observaciones = rs.getString("observaciones");
                    asistenciaRecord.put("observaciones", observaciones != null && !observaciones.isEmpty() ? observaciones : "N/A");
                    asistenciaRecord.put("nombre_curso", rs.getString("nombre_curso"));
                    asistenciaRecord.put("seccion", rs.getString("seccion"));
                    asistenciaRecord.put("semestre", rs.getString("semestre"));
                    asistenciaRecord.put("anio_academico", String.valueOf(rs.getInt("año_academico")));
                    
                    asistenciaAlumnoList.add(asistenciaRecord); // Changed to asistenciaAlumnoList
                }
                System.out.println("DEBUG (asistencia_alumno): Registros de asistencia de alumno listados: " + asistenciaAlumnoList.size()); // Changed log
            }

            // b) Datos para Gráfico Lineal de Asistencia Mensual
            if (globalErrorMessage == null) {
                try {
                    String sqlAsistenciaMensual = "SELECT DATE_FORMAT(a.fecha, '%Y-%m-%d') AS dia, "
                                                + "SUM(CASE WHEN a.estado = 'presente' THEN 1 ELSE 0 END) AS presentes, "
                                                + "SUM(CASE WHEN a.estado = 'ausente' THEN 1 ELSE 0 END) AS ausentes, "
                                                + "SUM(CASE WHEN a.estado = 'tardanza' THEN 1 ELSE 0 END) AS tardanzas, "
                                                + "SUM(CASE WHEN a.estado = 'justificado' THEN 1 ELSE 0 END) AS justificados "
                                                + "FROM asistencia a "
                                                + "JOIN inscripciones i ON a.id_inscripcion = i.id_inscripcion "
                                                + "WHERE i.id_alumno = ? AND a.fecha BETWEEN ? AND ? " // Filter by id_alumno
                                                + "GROUP BY a.fecha ORDER BY a.fecha ASC";
                    
                    pstmt = conn.prepareStatement(sqlAsistenciaMensual);
                    pstmt.setInt(1, idAlumno); // Use idAlumno
                    pstmt.setString(2, primerDiaMes.format(DateTimeFormatter.ISO_LOCAL_DATE));
                    pstmt.setString(3, ultimoDiaMes.format(DateTimeFormatter.ISO_LOCAL_DATE));
                    rs = pstmt.executeQuery();

                    while (rs.next()) {
                        fechasAsistenciaMes.add(rs.getString("dia"));
                        presentesPorDia.add(rs.getInt("presentes"));
                        ausentesPorDia.add(rs.getInt("ausentes"));
                        tardanzasPorDia.add(rs.getInt("tardanzas"));
                        justificadosPorDia.add(rs.getInt("justificados"));
                    }
                } finally { cerrarRecursos(rs, pstmt); }
            }

        } // End if (idAlumno != -1) for database operations
            
    } catch (SQLException e) {
        globalErrorMessage = "Error de base de datos al cargar la información: " + e.getMessage();
        System.err.println("ERROR (asistencia_alumno) SQL Principal: " + globalErrorMessage);
        e.printStackTrace();
    } catch (ClassNotFoundException e) {
        globalErrorMessage = "Error de configuración: Driver JDBC no encontrado. Asegúrate de que el conector esté en WEB-INF/lib.";
        System.err.println("ERROR (asistencia_alumno) DRIVER Principal: " + globalErrorMessage);
        e.printStackTrace();
    } finally {
        // Final connection closing
        try {
            if (conn != null) {
                conn.close();
            }
        } catch (SQLException e) {
            System.err.println("Error al cerrar conexión final: " + e.getMessage());
        }
    }
    // Formato para "Último acceso" (not used in this specific page, but for consistency)
    // You might want to remove this line if it's not displayed on the page
    // ultimoAcceso = LocalDateTime.now().format(DateTimeFormatter.ofPattern("EEEE, d 'de' MMMM 'de'yyyy, HH:mm", new Locale("es", "ES")));
%>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mi Asistencia | Sistema Universitario</title>
    <link rel="icon" type="image/x-icon" href="<%= request.getContextPath() %>/img/favicon.ico">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        /* Variables de estilo para consistencia con AdminKit */
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
            width: 280px; background-color: var(--admin-dark); color: rgba(255,255,255,0.8); padding-top: 1rem; flex-shrink: 0;
            position: sticky; top: 0; left: 0; height: 100vh; overflow-y: auto; box-shadow: 2px 0 5px rgba(0,0,0,0.1); z-index: 1030;
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

        /* Contenido principal */
        .main-content {
            flex: 1;
            padding: 1.5rem;
            overflow-y: auto;
            display: flex;
            flex-direction: column;
        }

        /* Navbar superior */
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

        /* Content Card Styling */
        .content-section.card {
            border-radius: 0.5rem;
            box-shadow: 0 0.125rem 0.25rem rgba(0,0,0,0.075);
            border-left: 4px solid var(--admin-primary);
            margin-bottom: 1.5rem;
        }
        .content-section.card .card-header {
             background-color: var(--admin-card-bg);
             border-bottom: 1px solid #dee2e6;
             padding-bottom: 1rem;
        }
        .content-section .section-title {
            color: var(--admin-primary);
            font-weight: 600;
            margin-bottom: 0;
        }
        .content-section.card .card-body p.text-muted {
            font-size: 0.95rem;
        }

        /* Tablas */
        .table-responsive {
            max-height: 500px;
            overflow-y: auto;
            margin-top: 1rem;
        }
        .table {
            color: var(--admin-text-dark);
            margin-bottom: 0;
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
        .table .badge {
            font-weight: 500;
            padding: 0.4em 0.7em;
            border-radius: 0.25rem;
        }
        .badge.bg-success { background-color: var(--admin-success) !important; }
        .badge.bg-danger { background-color: var(--admin-danger) !important; }
        .badge.bg-warning { background-color: var(--admin-warning) !important; color: var(--admin-text-dark) !important;}
        .badge.bg-info { background-color: var(--admin-info) !important; color: var(--admin-text-dark) !important;}
        .badge.bg-secondary { background-color: var(--admin-secondary-color) !important; }

        /* Chart Container */
        .chart-container {
            height: 350px;
            width: 100%;
            margin: auto;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 1rem;
        }
        .chart-container canvas {
            max-width: 100%;
            max-height: 100%;
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

            .welcome-section, .card { padding: 1rem;}
            .chart-container { height: 250px; }
        }
        @media (max-width: 576px) {
            .main-content { padding: 0.75rem; }
            .welcome-section, .card { padding: 0.75rem;}
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
                    <a class="nav-link active" href="<%= request.getContextPath() %>/INTERFAZ_ALUMNO/asistencia_alumno.jsp"><i class="fas fa-clipboard-check"></i><span> Mi Asistencia</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_ALUMNO/notas_alumno.jsp"><i class="fas fa-percent"></i><span> Mis Notas</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_ALUMNO/pagos_alumno.jsp"><i class="fas fa-money-bill-wave"></i><span> Mis Pagos</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_ALUMNO/mensajes_alumno.jsp"><i class="fas fa-envelope"></i><span> Mensajes</span></a>
                </li>
            </ul>
            <li class="nav-item mt-3">
                <form action="logout.jsp" method="post" class="d-grid gap-2">
                    <button type="submit" class="btn btn-outline-light mx-3"><i class="fas fa-sign-out-alt me-2"></i>Cerrar sesión</button>
                </form>
            </li>
        </nav>

        <div class="main-content">
            <nav class="top-navbar">
                <div class="search-bar">
                    
                </div>
                <div class="d-flex align-items-center">
                    
                    <div class="me-3 dropdown">
                        <a class="text-dark" href="#" role="button" id="messagesDropdown" data-bs-toggle="dropdown" aria-expanded="false">
                            <i class="fas fa-envelope fa-lg"></i>
                            
                        </a>
                        <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="messagesDropdown">
                            
                            <li><a class="dropdown-item" href="mensajes_alumno.jsp">Ver todos</a></li>
                        </ul>
                    </div>

                    <div class="dropdown user-dropdown">
                        <a class="dropdown-toggle" href="#" role="button" id="userDropdown" data-bs-toggle="dropdown" aria-expanded="false">
                            <img src="https://via.placeholder.com/32" alt="Avatar"> <span class="d-none d-md-inline-block"><%= nombreAlumno %></span>
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
                    <h1 class="h3 mb-3"><i class="fas fa-clipboard-check me-2"></i>Mi Historial de Asistencia</h1>
                    <p class="lead">Aquí puedes ver tu historial de asistencia a las clases inscritas.</p>
                </div>

                <% if (globalErrorMessage != null) { %>
                    <div class="alert alert-danger alert-dismissible fade show" role="alert">
                        <i class="fas fa-exclamation-triangle me-2"></i> <%= globalErrorMessage %>
                        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                    </div>
                <% } %>

                <div class="card content-section mb-4">
                    <div class="card-header">
                        <h3 class="section-title mb-0"><i class="fas fa-user-graduate me-2"></i>Mi Información General</h3>
                    </div>
                    <div class="card-body">
                        <% if (idAlumno != -1) { %>
                        <div class="row">
                            <div class="col-md-6">
                                <p class="mb-1"><strong>DNI:</strong> <%= dniAlumno %></p>
                                <p class="mb-1"><strong>Carrera:</strong> <%= carreraAlumno %></p>
                            </div>
                            <div class="col-md-6">
                                <p class="mb-1"><strong>Estado Académico:</strong> <%= estadoAlumno.toUpperCase() %></p>
                                <p class="mb-1"><strong>Registros de Asistencia:</strong> <%= asistenciaAlumnoList.size() %></p>
                            </div>
                        </div>
                        <% } else { %>
                        <p class="text-muted text-center py-3 mb-0">No se encontró tu información detallada como alumno.</p>
                        <% } %>
                    </div>
                </div>

                <div class="card content-section mb-4">
                    <div class="card-header">
                        <h3 class="section-title mb-0"><i class="fas fa-chart-line me-2"></i>Mi Asistencia Mensual de <%= nombreMesActual %></h3>
                    </div>
                    <div class="card-body">
                        <%  // Check if there is valid data for the chart
                            boolean hasAttendanceData = !fechasAsistenciaMes.isEmpty() || 
                                presentesPorDia.stream().anyMatch(val -> val > 0) || 
                                ausentesPorDia.stream().anyMatch(val -> val > 0) || 
                                tardanzasPorDia.stream().anyMatch(val -> val > 0) ||
                                justificadosPorDia.stream().anyMatch(val -> val > 0);
                        %>
                        <% if (hasAttendanceData) { %>
                            <div class="chart-container" style="height: 350px;">
                                <canvas id="asistenciaMensualChart"></canvas>
                            </div>
                        <% } else { %>
                            <p class="text-muted text-center py-3">No hay datos de asistencia para mostrar el gráfico de este mes.</p>
                            <p class="text-muted text-center"><small>Asegúrate de que se haya registrado asistencia para ti.</small></p>
                        <% } %>
                    </div>
                </div>


                <div class="card content-section mb-4">
                    <div class="card-header">
                        <h3 class="section-title mb-0"><i class="fas fa-table me-2"></i>Detalle de Mi Asistencia</h3>
                    </div>
                    <div class="card-body">
                        <div class="table-responsive">
                            <% if (!asistenciaAlumnoList.isEmpty()) { %>
                            <table class="table table-hover table-striped">
                                <thead>
                                    <tr>
                                        <th>Fecha</th>
                                        <th>Curso (Sección, Semestre, Año)</th>
                                        <th>Estado</th>
                                        <th>Observaciones</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <% for (Map<String, String> record : asistenciaAlumnoList) {%>
                                    <tr>
                                        <td><%= record.get("fecha") %></td>
                                        <td><%= record.get("nombre_curso") %> (<%= record.get("seccion") %>, <%= record.get("semestre") %> <%= record.get("anio_academico") %>)</td>
                                        <td>
                                            <%    String estadoAsistencia = record.get("estado");
                                                String badgeClass = "bg-secondary"; // Default
                                                if ("PRESENTE".equalsIgnoreCase(estadoAsistencia)) { badgeClass = "bg-success"; }
                                                else if ("AUSENTE".equalsIgnoreCase(estadoAsistencia)) { badgeClass = "bg-danger"; }
                                                else if ("TARDANZA".equalsIgnoreCase(estadoAsistencia)) { badgeClass = "bg-warning text-dark"; }
                                                else if ("JUSTIFICADO".equalsIgnoreCase(estadoAsistencia)) { badgeClass = "bg-info text-dark"; }
                                            %>
                                            <span class="badge badge-asistencia <%= badgeClass %>"><%= estadoAsistencia %></span>
                                        </td>
                                        <td><%= record.get("observaciones") %></td>
                                    </tr>
                                    <% } %>
                                </tbody>
                            </table>
                            <% } else { %>
                            <p class="text-muted text-center py-3">No hay registros de asistencia disponibles para ti actualmente.</p>
                            <% } %>
                        </div>
                    </div>
                </div>

            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script>
        document.addEventListener('DOMContentLoaded', (event) => {
            // --- Gráfico Lineal de Asistencia Mensual ---
            const fechasAsistenciaMes = [
                <% for (int i = 0; i < fechasAsistenciaMes.size(); i++) { %>
                    '<%= fechasAsistenciaMes.get(i) %>',
                <% } %>
            ];
            const presentesPorDia = [
                <% for (int i = 0; i < presentesPorDia.size(); i++) { %>
                    <%= presentesPorDia.get(i) %>,
                <% } %>
            ];
            const ausentesPorDia = [
                <% for (int i = 0; i < ausentesPorDia.size(); i++) { %>
                    <%= ausentesPorDia.get(i) %>,
                <% } %>
            ];
            const tardanzasPorDia = [
                <% for (int i = 0; i < tardanzasPorDia.size(); i++) { %>
                    <%= tardanzasPorDia.get(i) %>,
                <% } %>
            ];
            const justificadosPorDia = [
                <% for (int i = 0; i < justificadosPorDia.size(); i++) { %>
                    <%= justificadosPorDia.get(i) %>,
                <% } %>
            ];

            const ctxAsistenciaMensual = document.getElementById('asistenciaMensualChart');
            if (ctxAsistenciaMensual) {
                new Chart(ctxAsistenciaMensual.getContext('2d'), {
                    type: 'line',
                    data: {
                        labels: fechasAsistenciaMes.map(date => new Date(date).toLocaleDateString('es-ES', { day: 'numeric', month: 'short' })),
                        datasets: [
                            {
                                label: 'Presentes',
                                data: presentesPorDia,
                                borderColor: 'var(--admin-success)',
                                backgroundColor: 'rgba(40, 167, 69, 0.2)',
                                fill: true,
                                tension: 0.3,
                                pointBackgroundColor: 'var(--admin-success)',
                                pointBorderColor: '#fff',
                                pointHoverBackgroundColor: '#fff',
                                pointHoverBorderColor: 'var(--admin-success)'
                            },
                            {
                                label: 'Ausentes',
                                data: ausentesPorDia,
                                borderColor: 'var(--admin-danger)',
                                backgroundColor: 'rgba(220, 53, 69, 0.2)',
                                fill: true,
                                tension: 0.3,
                                pointBackgroundColor: 'var(--admin-danger)',
                                pointBorderColor: '#fff',
                                pointHoverBackgroundColor: '#fff',
                                pointHoverBorderColor: 'var(--admin-danger)'
                            },
                            {
                                label: 'Tardanzas',
                                data: tardanzasPorDia,
                                borderColor: 'var(--admin-warning)',
                                backgroundColor: 'rgba(255, 193, 7, 0.2)',
                                fill: true,
                                tension: 0.3,
                                pointBackgroundColor: 'var(--admin-warning)',
                                pointBorderColor: '#fff',
                                pointHoverBackgroundColor: '#fff',
                                pointHoverBorderColor: 'var(--admin-warning)'
                            },
                            {
                                label: 'Justificados',
                                data: justificadosPorDia,
                                borderColor: 'var(--admin-info)',
                                backgroundColor: 'rgba(23, 162, 184, 0.2)',
                                fill: true,
                                tension: 0.3,
                                pointBackgroundColor: 'var(--admin-info)',
                                pointBorderColor: '#fff',
                                pointHoverBackgroundColor: '#fff',
                                pointHoverBorderColor: 'var(--admin-info)'
                            }
                        ]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        scales: {
                            x: {
                                title: {
                                    display: true,
                                    text: 'Día del Mes',
                                    color: 'var(--admin-text-dark)',
                                    font: { weight: 'bold' }
                                },
                                grid: { display: false }
                            },
                            y: {
                                beginAtZero: true,
                                title: {
                                    display: true,
                                    text: 'Cantidad de Registros',
                                    color: 'var(--admin-text-dark)',
                                    font: { weight: 'bold' }
                                },
                                ticks: {
                                    precision: 0
                                }
                            }
                        },
                        plugins: {
                            title: {
                                display: false,
                            },
                            legend: {
                                position: 'top',
                                labels: {
                                    font: { size: 12 },
                                    color: 'var(--admin-text-dark)'
                                }
                            },
                            tooltip: {
                                mode: 'index',
                                intersect: false,
                                backgroundColor: 'rgba(0,0,0,0.8)',
                                titleFont: { weight: 'bold' },
                                bodyFont: { weight: 'normal' },
                                padding: 10,
                                cornerRadius: 5
                            }
                        }
                    }
                });
            }
        });
    </script>
</body>
</html>