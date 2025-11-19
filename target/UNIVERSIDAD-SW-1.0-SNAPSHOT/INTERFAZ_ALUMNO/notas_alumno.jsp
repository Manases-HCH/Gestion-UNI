<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, pe.universidad.util.Conection" %>
<%@ page import="java.time.LocalDateTime, java.time.format.DateTimeFormatter" %>
<%@ page import="java.util.Locale" %> <%-- Para formato de números --%>
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
    String dniAlumno = "N/A";    // Added for alumno info
    String carreraAlumno = "Carrera Desconocida";    // Added for alumno info
    String estadoAlumno = "N/A";    // Added for alumno info
    int totalCursosConNotas = 0;

    List<Map<String, String>> notasAlumnoList = new ArrayList<>(); // Changed from notasHijoList

    // --- Datos para gráficos ---
    List<String> nombresCursosPromedio = new ArrayList<>();
    List<Double> promediosCursos = new ArrayList<>();
    int totalAprobados = 0;
    int totalDesaprobados = 0;
    int totalPendientes = 0;
    int totalCalificacionesRegistradas = 0;

    Connection conn = null;    
    PreparedStatement currentPstmt = null; // Declare here to ensure it's always accessible in finally
    ResultSet currentRs = null; // Declare here to ensure it's always accessible in finally
    String globalErrorMessage = null; 

    try {
        // --- 1. Validar y obtener ID del Alumno de Sesión ---
        if (emailSesion == null || !"alumno".equalsIgnoreCase(rolUsuario) || idAlumnoObj == null) { // Changed rol check
            System.out.println("DEBUG (notas_alumno): Sesión inválida o rol incorrecto. Redirigiendo a login.");
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }
        try {
            idAlumno = Integer.parseInt(String.valueOf(idAlumnoObj)); // Use idAlumnoObj
            System.out.println("DEBUG (notas_alumno): ID Alumno de sesión: " + idAlumno); // Changed log
        } catch (NumberFormatException e) {
            System.err.println("ERROR (notas_alumno): ID de alumno en sesión no es un número válido. " + e.getMessage()); // Changed log
            globalErrorMessage = "Error de sesión: ID de alumno inválido.";
        }

        // If idAlumno is valid, attempt to connect and load data
        if (idAlumno != -1 && globalErrorMessage == null) {
            // --- 2. Conectar a la Base de Datos ---
            Conection c = new Conection();
            conn = c.conecta();    
            if (conn == null || conn.isClosed()) {
                throw new SQLException("No se pudo establecer conexión a la base de datos.");
            }
            System.out.println("DEBUG (notas_alumno): Conexión a BD establecida."); // Changed log

            // --- 3. Obtener Información General del Alumno (using vista_alumnos_completa) ---
            try {
                // Assuming vista_alumnos_completa has dni, nombre_completo, nombre_carrera, estado
                String sqlAlumnoInfo = "SELECT dni, nombre_completo, nombre_carrera, estado FROM vista_alumnos_completa WHERE id_alumno = ?";
                currentPstmt = conn.prepareStatement(sqlAlumnoInfo);
                currentPstmt.setInt(1, idAlumno); // Use idAlumno
                currentRs = currentPstmt.executeQuery();
                if (currentRs.next()) {
                    nombreAlumno = currentRs.getString("nombre_completo");
                    dniAlumno = currentRs.getString("dni") != null ? currentRs.getString("dni") : "N/A";
                    carreraAlumno = currentRs.getString("nombre_carrera") != null ? currentRs.getString("nombre_carrera") : "Desconocida";
                    estadoAlumno = currentRs.getString("estado") != null ? currentRs.getString("estado") : "N/A";
                    session.setAttribute("nombre_alumno", nombreAlumno); // Save to session
                    System.out.println("DEBUG (notas_alumno): Datos de alumno cargados: " + nombreAlumno); // Changed log
                } else {
                    globalErrorMessage = "Tu información de alumno no se encontró en la base de datos. Por favor, contacta a soporte."; // Changed message
                    System.err.println("ERROR (notas_alumno): Alumno con ID " + idAlumno + " no encontrado en BD."); // Changed log
                    // If student not found, invalidate session and redirect
                    session.invalidate();
                    response.sendRedirect(request.getContextPath() + "/login.jsp?error=" + java.net.URLEncoder.encode(globalErrorMessage, "UTF-8"));
                    return; // Stop further processing
                }
            } finally { cerrarRecursos(currentRs, currentPstmt); }

            // --- 4. Obtener Notas del Alumno (if alumno info successfully retrieved) ---
            if (globalErrorMessage == null) {
                // a) Detalle de Notas (para la tabla)
                try {
                    String sqlNotas = "SELECT cu.nombre_curso, cl.seccion, cl.semestre, cl.año_academico, "
                                    + "n.nota1, n.nota2, n.nota3, n.examen_parcial, n.examen_final, n.nota_final, n.estado AS estado_nota "
                                    + "FROM notas n "
                                    + "JOIN inscripciones i ON n.id_inscripcion = i.id_inscripcion "
                                    + "JOIN clases cl ON i.id_clase = cl.id_clase "
                                    + "JOIN cursos cu ON cl.id_curso = cu.id_curso "
                                    + "WHERE i.id_alumno = ? " // Filter by id_alumno
                                    + "ORDER BY cl.año_academico DESC, cl.semestre DESC, cu.nombre_curso ASC";
                    
                    currentPstmt = conn.prepareStatement(sqlNotas);
                    currentPstmt.setInt(1, idAlumno); // Use idAlumno
                    currentRs = currentPstmt.executeQuery();

                    while(currentRs.next()) {
                        Map<String, String> notaRecord = new HashMap<>();
                        notaRecord.put("nombre_curso", currentRs.getString("nombre_curso"));
                        notaRecord.put("seccion", currentRs.getString("seccion"));
                        notaRecord.put("semestre", currentRs.getString("semestre"));
                        notaRecord.put("anio_academico", String.valueOf(currentRs.getInt("año_academico")));
                        
                        // Retrieve and format notes, handling NULLs
                        notaRecord.put("nota1", currentRs.getObject("nota1") != null ? String.format(Locale.US, "%.2f", currentRs.getDouble("nota1")) : "N/A");
                        notaRecord.put("nota2", currentRs.getObject("nota2") != null ? String.format(Locale.US, "%.2f", currentRs.getDouble("nota2")) : "N/A");
                        notaRecord.put("nota3", currentRs.getObject("nota3") != null ? String.format(Locale.US, "%.2f", currentRs.getDouble("nota3")) : "N/A");
                        notaRecord.put("examen_parcial", currentRs.getObject("examen_parcial") != null ? String.format(Locale.US, "%.2f", currentRs.getDouble("examen_parcial")) : "N/A");
                        notaRecord.put("examen_final", currentRs.getObject("examen_final") != null ? String.format(Locale.US, "%.2f", currentRs.getDouble("examen_final")) : "N/A");
                        notaRecord.put("nota_final", currentRs.getObject("nota_final") != null ? String.format(Locale.US, "%.2f", currentRs.getDouble("nota_final")) : "PENDIENTE");
                        
                        String estadoNota = currentRs.getString("estado_nota");
                        notaRecord.put("estado_nota", estadoNota != null ? estadoNota.toUpperCase() : "PENDIENTE");
                        
                        notasAlumnoList.add(notaRecord); // Changed to notasAlumnoList
                    }
                    totalCursosConNotas = notasAlumnoList.size(); // Update total for general info
                    System.out.println("DEBUG (notas_alumno): Registros de notas de alumno listados: " + notasAlumnoList.size()); // Changed log
                } finally { cerrarRecursos(currentRs, currentPstmt); }
            }

            // b) Datos para Gráfico de Torta (Distribución General de Notas)
            if (globalErrorMessage == null) {
                try {
                    String sqlDistribucionNotas = "SELECT COALESCE(n.estado, 'PENDIENTE') AS estado, COUNT(*) as count FROM notas n "
                                                + "JOIN inscripciones i ON n.id_inscripcion = i.id_inscripcion "
                                                + "WHERE i.id_alumno = ? " // Filter by id_alumno
                                                + "GROUP BY COALESCE(n.estado, 'PENDIENTE')";
                    currentPstmt = conn.prepareStatement(sqlDistribucionNotas);
                    currentPstmt.setInt(1, idAlumno); // Use idAlumno
                    currentRs = currentPstmt.executeQuery();
                    while(currentRs.next()) {
                        String estado = currentRs.getString("estado");
                        int count = currentRs.getInt("count");
                        if ("APROBADO".equalsIgnoreCase(estado)) { totalAprobados = count; }
                        else if ("DESAPROBADO".equalsIgnoreCase(estado)) { totalDesaprobados = count; }
                        else if ("PENDIENTE".equalsIgnoreCase(estado)) { totalPendientes = count; }
                    }
                    totalCalificacionesRegistradas = totalAprobados + totalDesaprobados + totalPendientes;
                } finally { cerrarRecursos(currentRs, currentPstmt); }
            }

            // c) Datos para Gráfico de Barras (Promedio de Nota Final por Curso)
            if (globalErrorMessage == null) {
                try {
                    String sqlPromediosPorCurso = "SELECT cu.nombre_curso, AVG(n.nota_final) AS promedio_curso_nota "
                                                + "FROM notas n "
                                                + "JOIN inscripciones i ON n.id_inscripcion = i.id_inscripcion "
                                                + "JOIN clases cl ON i.id_clase = cl.id_clase "
                                                + "JOIN cursos cu ON cl.id_curso = cu.id_curso "
                                                + "WHERE i.id_alumno = ? AND n.nota_final IS NOT NULL " // Filter by id_alumno
                                                + "GROUP BY cu.nombre_curso ORDER BY promedio_curso_nota DESC LIMIT 5";
                    currentPstmt = conn.prepareStatement(sqlPromediosPorCurso);
                    currentPstmt.setInt(1, idAlumno); // Use idAlumno
                    currentRs = currentPstmt.executeQuery();
                    while (currentRs.next()) {
                        nombresCursosPromedio.add(currentRs.getString("nombre_curso"));
                        promediosCursos.add(currentRs.getDouble("promedio_curso_nota"));
                    }
                } finally { cerrarRecursos(currentRs, currentPstmt); }
            }

        } // End if (idAlumno != -1 && globalErrorMessage == null) for database operations

    } catch (SQLException e) {
        globalErrorMessage = "Error de base de datos al cargar la información: " + e.getMessage();
        System.err.println("ERROR (notas_alumno) SQL Principal: " + globalErrorMessage); // Changed log
        e.printStackTrace();
    } catch (ClassNotFoundException e) {
        globalErrorMessage = "Error de configuración: Driver JDBC no encontrado. Asegúrate de que el conector esté en WEB-INF/lib.";
        System.err.println("ERROR (notas_alumno) DRIVER Principal: " + globalErrorMessage); // Changed log
        e.printStackTrace();
    } finally {
        // Ensure the main connection is closed.
        try {
            if (conn != null) {
                conn.close();
            }
        } catch (SQLException e) {
            System.err.println("Error al cerrar conexión final: " + e.getMessage());
        }
    }
    // Format for "Último acceso"
    String ultimoAcceso = LocalDateTime.now().format(DateTimeFormatter.ofPattern("EEEE, d 'de' MMMM 'de'yyyy, HH:mm", new Locale("es", "ES")));
%>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mis Notas | Sistema Universitario</title>
    <link rel="icon" type="image/x-icon" href="<%= request.getContextPath() %>/img/favicon.ico">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        /* Variables de estilo para consistencia con AdminKit */
        :root {
            --admin-dark: #222B40; /* Color oscuro para sidebar y navbar */
            --admin-light-bg: #F0F2F5; /* Fondo claro para el main content */
            --admin-card-bg: #FFFFFF; /* Fondo de las tarjetas */
            --admin-text-dark: #333333; /* Texto principal */
            --admin-text-muted: #6C757D; /* Texto secundario/gris */
            --admin-primary: #007BFF; /* Azul principal de AdminKit */
            --admin-success: #28A745; /* Verde para aprobación */
            --admin-danger: #DC3545; /* Rojo para desaprobación */
            --admin-warning: #FFC107; /* Amarillo para pendientes */
            --admin-info: #17A2B8; /* Cian para información */
            --admin-secondary-color: #6C757D; /* Un gris más oscuro para detalles */
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

        /* Stat Cards for Payments */
        .stat-card {
            background-color: var(--admin-card-bg);
            border-radius: 0.5rem;
            padding: 1.5rem;
            text-align: center;
            box-shadow: 0 0.125rem 0.25rem rgba(0,0,0,0.075);
            border-bottom: 4px solid var(--admin-primary);
            transition: transform 0.3s ease-in-out;
            min-height: 150px;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
        }
        .stat-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 0.5rem 1rem rgba(0,0,0,0.15);
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
            color: var(--admin-primary);
            margin-bottom: 0.25rem;
        }
        .stat-card .description {
            font-size: 0.85rem;
            color: var(--admin-text-muted);
        }
        .stat-card .icon-wrapper {
            font-size: 2rem;
            color: var(--admin-primary);
            margin-bottom: 0.75rem;
        }
        .stat-card.pending-count .value, .stat-card.pending-count .icon-wrapper { color: var(--admin-warning); }
        .stat-card.overdue-count .value, .stat-card.overdue-count .icon-wrapper { color: var(--admin-danger); }
        .stat-card.total-amount-due .value, .stat-card.total-amount-due .icon-wrapper { color: var(--admin-primary); }
        .stat-card.last-payment-date .value, .stat-card.last-payment-date .icon-wrapper { color: var(--admin-info); }

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
        .badge.bg-warning { background-color: var(--admin-warning) !important; color: var(--admin-text-dark) !important;}
        .badge.bg-danger { background-color: var(--admin-danger) !important; }

        /* Botón de Pagar */
        .btn-pay {
            background-color: var(--admin-primary);
            color: white;
            border: none;
            padding: 0.4rem 0.8rem;
            border-radius: 4px;
            cursor: pointer;
            transition: background-color 0.3s ease, transform 0.2s ease;
            font-size: 0.85rem;
        }
        .btn-pay:hover {
            background-color: #0056b3;
            transform: translateY(-2px);
        }
        .btn-pay:disabled {
            background-color: var(--admin-secondary-color);
            cursor: not-allowed;
            opacity: 0.6;
        }

        /* Chart Container */
        .chart-container {
            height: 300px;
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
            .stat-card { min-height: 120px; padding: 1rem; }
            .stat-card .value { font-size: 1.8rem; }
            .stat-card .icon-wrapper { font-size: 1.5rem; }
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
                    <a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_ALUMNO/asistencia_alumno.jsp"><i class="fas fa-clipboard-check"></i><span> Mi Asistencia</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link active" href="<%= request.getContextPath() %>/INTERFAZ_ALUMNO/notas_alumno.jsp"><i class="fas fa-percent"></i><span> Mis Notas</span></a>
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
                    <h1 class="h3 mb-3"><i class="fas fa-percent me-2"></i>Mis Notas</h1>
                    <p class="lead">Aquí puedes ver el detalle de las calificaciones obtenidas en cada uno de tus cursos.</p>
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
                                <p class="mb-1"><strong>Total Calificaciones:</strong> <%= notasAlumnoList.size() %></p>
                            </div>
                        </div>
                        <% } else { %>
                        <p class="text-muted text-center py-3 mb-0">No se encontró tu información detallada como alumno.</p>
                        <% } %>
                    </div>
                </div>

                <div class="row g-4 mb-4">
                    <div class="col-md-6">
                        <div class="card shadow-sm h-100 content-section">
                            <div class="card-header">
                                <h3 class="section-title mb-0"><i class="fas fa-chart-pie me-2"></i>Distribución de Estados de Notas</h3>
                            </div>
                            <div class="card-body">
                                <% if (totalCalificacionesRegistradas > 0) { %>
                                    <div class="chart-container">
                                        <canvas id="gradeDistributionChart"></canvas>
                                    </div>
                                <% } else { %>
                                    <p class="text-muted text-center py-3">No hay datos de notas finalizadas para mostrar el gráfico.</p>
                                    <p class="text-muted text-center"><small>Las notas finales deben estar registradas para ver este gráfico.</small></p>
                                <% } %>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <div class="card shadow-sm h-100 content-section">
                            <div class="card-header">
                                <h3 class="section-title mb-0"><i class="fas fa-chart-bar me-2"></i>Promedio de Nota Final por Curso</h3>
                            </div>
                            <div class="card-body">
                                <% if (!nombresCursosPromedio.isEmpty()) { %>
                                    <div class="chart-container">
                                        <canvas id="courseAverageChart"></canvas>
                                    </div>
                                <% } else { %>
                                    <p class="text-muted text-center py-3">No hay datos de promedios de cursos para mostrar el gráfico.</p>
                                    <p class="text-muted text-center"><small>Las notas finales por curso deben estar registradas.</small></p>
                                <% } %>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="card content-section mb-4">
                    <div class="card-header">
                        <h3 class="section-title mb-0"><i class="fas fa-table me-2"></i>Mi Historial Detallado de Calificaciones</h3>
                    </div>
                    <div class="card-body">
                        <div class="table-responsive">
                            <% if (!notasAlumnoList.isEmpty()) { %>
                            <table class="table table-hover table-striped">
                                <thead>
                                    <tr>
                                        <th>Curso</th>
                                        <th>Sección</th>
                                        <th>Período</th>
                                        <th>Nota 1</th>
                                        <th>Nota 2</th>
                                        <th>Nota 3</th>
                                        <th>Parcial</th>
                                        <th>Final</th>
                                        <th>Nota Final</th>
                                        <th>Estado</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <% for (Map<String, String> nota : notasAlumnoList) {%>
                                    <tr>
                                        <td><%= nota.get("nombre_curso") %></td>
                                        <td><%= nota.get("seccion") %></td>
                                        <td><%= nota.get("semestre") %> <%= nota.get("anio_academico") %></td>
                                        <td><%= nota.get("nota1") %></td>
                                        <td><%= nota.get("nota2") %></td>
                                        <td><%= nota.get("nota3") %></td>
                                        <td><%= nota.get("examen_parcial") %></td>
                                        <td><%= nota.get("examen_final") %></td>
                                        <td><strong><%= nota.get("nota_final") %></strong></td>
                                        <td>
                                            <%    String estadoNota = nota.get("estado_nota");
                                                String badgeClass = "bg-secondary";
                                                if ("APROBADO".equalsIgnoreCase(estadoNota)) { badgeClass = "bg-success"; }
                                                else if ("DESAPROBADO".equalsIgnoreCase(estadoNota)) { badgeClass = "bg-danger"; }
                                                else if ("PENDIENTE".equalsIgnoreCase(estadoNota)) { badgeClass = "bg-warning text-dark"; }
                                            %>
                                            <span class="badge badge-nota <%= badgeClass %>"><%= estadoNota %></span>
                                        </td>
                                    </tr>
                                    <% } %>
                                </tbody>
                            </table>
                            <% } else { %>
                            <p class="text-muted text-center py-3">No hay registros de notas disponibles para ti actualmente.</p>
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
            // --- Gráfico de Distribución de Estados de Notas (Gráfico de Torta) ---
            const totalAprobados = <%= totalAprobados %>;
            const totalDesaprobados = <%= totalDesaprobados %>;
            const totalPendientes = <%= totalPendientes %>;
            const totalCalificacionesRegistradas = <%= totalCalificacionesRegistradas %>;

            const ctxGradeDistribution = document.getElementById('gradeDistributionChart');
            if (ctxGradeDistribution && totalCalificacionesRegistradas > 0) {
                new Chart(ctxGradeDistribution.getContext('2d'), {
                    type: 'pie',
                    data: {
                        labels: ['Aprobado', 'Desaprobado', 'Pendiente'],
                        datasets: [{
                            data: [totalAprobados, totalDesaprobados, totalPendientes],
                            backgroundColor: [
                                '#1abc9c',
                                '#e74c3c',
                                '#f39c12'
                            ],
                            borderColor: 'var(--admin-card-bg)',
                            borderWidth: 2
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
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
                                backgroundColor: 'rgba(0,0,0,0.8)',
                                titleFont: { weight: 'bold' },
                                bodyFont: { weight: 'normal' },
                                padding: 10,
                                cornerRadius: 5,
                                callbacks: {
                                    label: function(context) {
                                        let label = context.label || '';
                                        if (label) {
                                            label += ': ';
                                        }
                                        if (context.parsed !== null) {
                                            const total = context.dataset.data.reduce((sum, val) => sum + val, 0);
                                            const percentage = (total > 0) ? (context.parsed / total * 100).toFixed(1) : 0;
                                            label += context.parsed + ' (' + percentage + '%)';
                                        }
                                        return label;
                                    }
                                }
                            }
                        }
                    }
                });
            }

            // --- Gráfico de Promedio de Nota Final por Curso (Gráfico de Barras) ---
            const nombresCursosPromedio = [
                <%
                    for (int i = 0; i < nombresCursosPromedio.size(); i++) {
                        out.print("'" + nombresCursosPromedio.get(i).replace("'", "\\'") + "'");
                        if (i < nombresCursosPromedio.size() - 1) {
                            out.print(", ");
                        }
                    }
                %>
            ];
            const promediosCursos = [
                <%
                    for (int i = 0; i < promediosCursos.size(); i++) {
                        out.print(promediosCursos.get(i));
                        if (i < promediosCursos.size() - 1) {
                            out.print(", ");
                        }
                    }
                %>
            ];

            const ctxCourseAverage = document.getElementById('courseAverageChart');
            if (ctxCourseAverage && nombresCursosPromedio.length > 0) {
                new Chart(ctxCourseAverage.getContext('2d'), {
                    type: 'bar',
                    data: {
                        labels: nombresCursosPromedio,
                        datasets: [{
                            label: 'Nota Final Promedio',
                            data: promediosCursos,
                            backgroundColor: [
                                '#3498db',
                                '#2ecc71',
                                '#9b59b6',
                                '#f1c40f',
                                '#e67e22'
                            ],
                            borderColor: 'rgba(0, 123, 255, 1)',
                            borderWidth: 1,
                            borderRadius: 5,
                        }]
                    },
                    options: {
                        indexAxis: 'y',
                        responsive: true,
                        maintainAspectRatio: false,
                        scales: {
                            x: {
                                beginAtZero: true,
                                max: 20,
                                title: {
                                    display: true,
                                    text: 'Promedio de Nota',
                                    color: 'var(--admin-text-dark)',
                                    font: { weight: 'bold' }
                                },
                                grid: { color: '#e9ecef' },
                                ticks: { color: 'var(--admin-text-muted)' }
                            },
                            y: {
                                title: {
                                    display: true,
                                    text: 'Curso',
                                    color: 'var(--admin-text-dark)',
                                    font: { weight: 'bold' }
                                },
                                grid: { display: false },
                                ticks: { color: 'var(--admin-text-dark)' }
                            }
                        },
                        plugins: {
                            title: {
                                display: false,
                            },
                            legend: {
                                display: false,
                            },
                            tooltip: {
                                backgroundColor: 'rgba(0,0,0,0.8)',
                                titleFont: { weight: 'bold' },
                                bodyFont: { weight: 'normal' },
                                padding: 10,
                                cornerRadius: 5,
                                callbacks: {
                                    label: function(context) {
                                        let label = context.dataset.label || '';
                                        if (label) {
                                            label += ': ';
                                        }
                                        if (context.parsed.x !== null) {
                                            label += context.parsed.x.toFixed(2);
                                        }
                                        return label;
                                    }
                                }
                            }
                        }
                    }
                });
            }
        });
    </script>
</body>
</html> 