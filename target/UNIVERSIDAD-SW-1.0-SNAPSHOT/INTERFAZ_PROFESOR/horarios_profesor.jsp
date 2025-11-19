<%@ page import="java.sql.*, pe.universidad.util.Conection" %>
<%@ page import="java.time.LocalDate, java.time.format.TextStyle, java.time.format.DateTimeFormatter, java.util.Locale" %>
<%@ page import="java.util.List, java.util.ArrayList, java.util.Map, java.util.HashMap" %>
<%@ page session="true" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<%! // BLOQUE DE DECLARACIÓN JSP PARA MÉTODOS Y VARIABLES A NIVEL DE CLASE
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

    // Convertir día de la semana de nombre a número para FullCalendar (0=Domingo, 1=Lunes, etc.)
    int convertirDiaSemanaANumero(String dia) {
        switch (dia.toLowerCase(Locale.ROOT)) { // Usar Locale.ROOT para consistencia
            case "domingo": return 0;
            case "lunes": return 1;
            case "martes": return 2;
            case "miércoles": case "miercoles": return 3; // Aceptar con y sin tilde
            case "jueves": return 4;
            case "viernes": return 5;
            case "sábado": case "sabado": return 6; // Aceptar con y sin tilde
            default: return -1; // Valor por defecto o para manejar error
        }
    }
    // globalDbErrorMessage declaration removed from here - it will no longer be used.
%>

<% // Scriptlet principal que ejecuta la lógica de la página
    String nombreProfesor = "";
    String emailProfesor = ""; // Se inicializará con el valor de sesión
    String facultadProfesor = "";

    // Datos para la Top Navbar (conteo de notificaciones/mensajes)
    int totalPendingJoinRequests = 0;
    int totalPendingLeaveRequests = 0;

    // Variables para estadísticas y FullCalendar
    String diaHoy = LocalDate.now().getDayOfWeek().getDisplayName(TextStyle.FULL, new Locale("es")).toLowerCase();
    List<String> salonesHoy = new ArrayList<>(); // Para salones únicos de hoy
    List<Map<String, String>> clasesHoyList = new ArrayList<>(); // Para la sorpresa: clases detalladas de hoy

    int totalClasesAsignadas = 0; // Total de clases para la estadística
    StringBuilder eventosFullCalendar = new StringBuilder("["); // Para los eventos del calendario

    // Variable para almacenar un mensaje de error específico si ocurre en el try/catch principal
    String pageLoadErrorMessage = null; 

    Connection conn = null; // Declarar conn aquí (null inicial)

    try {
        // --- VALIDACIÓN DE SESIÓN Y OBTENCIÓN DE EMAIL ---
        String emailSesion = (String) session.getAttribute("email");
        String rolUsuario = (String) session.getAttribute("rol");
        Object idProfesorObj = session.getAttribute("id_profesor");

        if (emailSesion == null || !"profesor".equalsIgnoreCase(rolUsuario) || idProfesorObj == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        // Asignar emailSesion al emailProfesor
        emailProfesor = emailSesion;

        // Obtener ID del profesor
        int idProfesor = -1;
        if (idProfesorObj instanceof Integer) {
            idProfesor = (Integer) idProfesorObj;
        } else {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        // OBTENER LA CONEXIÓN UNA SOLA VEZ AL INICIO DEL BLOQUE TRY PRINCIPAL
        Conection conUtil = new Conection();
        conn = conUtil.conecta();

        if (conn == null || conn.isClosed()) {
            throw new SQLException("No se pudo establecer conexión a la base de datos.");
        }

        // --- 1. Obtener información básica del profesor (para navbar y bienvenida) ---
        PreparedStatement pstmtProfesor = null;
        ResultSet rsProfesor = null;
        try {
            String sqlProfesor = "SELECT p.nombre, p.apellido_paterno, p.apellido_materno, p.email, f.nombre_facultad as facultad " +
                                 "FROM profesores p " +
                                 "LEFT JOIN facultades f ON p.id_facultad = f.id_facultad " +
                                 "WHERE p.id_profesor = ?";
            pstmtProfesor = conn.prepareStatement(sqlProfesor);
            pstmtProfesor.setInt(1, idProfesor);
            rsProfesor = pstmtProfesor.executeQuery();

            if (rsProfesor.next()) {
                String nombre = rsProfesor.getString("nombre");
                String apellidoPaterno = rsProfesor.getString("apellido_paterno");
                String apellidoMaterno = rsProfesor.getString("apellido_materno");
                
                nombreProfesor = nombre + " " + apellidoPaterno + (apellidoMaterno != null ? " " + apellidoMaterno : "");
                facultadProfesor = rsProfesor.getString("facultad");
            } else {
                // Si hay un error aquí, la página se redirigirá al login
                response.sendRedirect(request.getContextPath() + "/login.jsp?error=profesor_info_not_found");
                return;
            }
        } finally {
            closeDbResources(rsProfesor, pstmtProfesor);
        }

        // --- 2. Obtener horarios de las clases asignadas al profesor para FullCalendar y estadísticas ---
        PreparedStatement pstmtHorarios = null;
        ResultSet rsHorarios = null;
        try {
            String sqlHorarios = "SELECT cl.id_clase, cu.nombre_curso AS curso, cu.codigo_curso AS codigo, " +
                                 "h.dia_semana, h.hora_inicio, h.hora_fin, h.aula AS salon_aula, " +
                                 "cl.seccion, cl.capacidad_maxima AS capacidad " +
                                 "FROM clases cl " +
                                 "JOIN cursos cu ON cl.id_curso = cu.id_curso " +
                                 "JOIN horarios h ON cl.id_horario = h.id_horario " +
                                 "WHERE cl.id_profesor = ? AND cl.estado = 'activo' " +
                                 "ORDER BY FIELD(h.dia_semana, 'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'), h.hora_inicio";

            pstmtHorarios = conn.prepareStatement(sqlHorarios);
            pstmtHorarios.setInt(1, idProfesor);
            rsHorarios = pstmtHorarios.executeQuery();

            boolean hasEvents = false;
            while (rsHorarios.next()) {
                if (hasEvents) eventosFullCalendar.append(",");

                // Lógica para la "sorpresa": Clases de Hoy y salones únicos
                String diaBD = rsHorarios.getString("dia_semana").toLowerCase(Locale.ROOT);
                if (diaBD.equals(diaHoy)) {
                    Map<String, String> claseHoy = new HashMap<>();
                    claseHoy.put("curso", rsHorarios.getString("curso"));
                    claseHoy.put("seccion", rsHorarios.getString("seccion"));
                    claseHoy.put("hora_inicio", rsHorarios.getString("hora_inicio"));
                    claseHoy.put("hora_fin", rsHorarios.getString("hora_fin"));
                    claseHoy.put("aula", rsHorarios.getString("salon_aula"));
                    clasesHoyList.add(claseHoy);

                    String salon = rsHorarios.getString("salon_aula");
                    if (salon != null && !salon.trim().isEmpty() && !salonesHoy.contains(salon)) {
                        salonesHoy.add(salon);
                    }
                }

                String idClase = String.valueOf(rsHorarios.getInt("id_clase"));
                String curso = rsHorarios.getString("curso");
                String codigo = rsHorarios.getString("codigo");
                String diaSemana = rsHorarios.getString("dia_semana");
                String horaInicio = rsHorarios.getString("hora_inicio");
                String horaFin = rsHorarios.getString("hora_fin");
                String salon = rsHorarios.getString("salon_aula");
                int capacidad = rsHorarios.getInt("capacidad");
                String seccion = rsHorarios.getString("seccion");

                eventosFullCalendar.append("{")
                            .append("id:'").append(idClase).append("',")
                            .append("title:'").append(curso).append(" (").append(codigo).append(" - ").append(seccion).append(")',")
                            .append("daysOfWeek:[").append(convertirDiaSemanaANumero(diaSemana)).append("],")
                            .append("startTime:'").append(horaInicio).append("',")
                            .append("endTime:'").append(horaFin).append("',")
                            .append("backgroundColor:'var(--admin-primary)',")
                            .append("borderColor:'var(--admin-warning)',")
                            .append("extendedProps:{")
                            .append("salon:'").append(salon != null ? salon : "No asignado").append("',")
                            .append("capacidad:").append(capacidad).append(",")
                            .append("codigo:'").append(codigo).append("'")
                            .append("}")
                            .append("}");
                hasEvents = true;
                totalClasesAsignadas++;
            }
        } finally {
            closeDbResources(rsHorarios, pstmtHorarios);
        }

        eventosFullCalendar.append("]");

        // --- 3. Obtener Conteo de Solicitudes Pendientes (para la navbar) ---
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

            // Re-use pstmtPending and rsPending variables for the next query
            pstmtPending = null;
            rsPending = null;

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
        // Asignar el mensaje de error para mostrar en la página si no hay una redirección
        pageLoadErrorMessage = "Error de base de datos en la carga principal: " + e.getMessage();
        e.printStackTrace();
    } catch (ClassNotFoundException e) {
        pageLoadErrorMessage = "Error: No se encontró el driver JDBC de MySQL. Asegúrate de que mysql-connector-java.jar esté en WEB-INF/lib.";
        e.printStackTrace();
    } catch (Exception e) { // Captura cualquier otra excepción inesperada
        pageLoadErrorMessage = "Ocurrió un error inesperado: " + e.getMessage();
        e.printStackTrace();
    } finally {
        // Cierre final de la conexión 'conn' que se abrió al inicio del scriptlet.
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
    <title>Horarios - Sistema Universitario</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/fullcalendar@6.1.8/index.global.min.css" />
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

        /* Stats Grid for this page */
        .stats-grid-horarios {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
            gap: 1.5rem;
            margin-bottom: 1.5rem;
        }
        .stats-card-horarios {
            border-radius: 0.5rem;
            box-shadow: 0 0.125rem 0.25rem rgba(0,0,0,0.075);
            transition: transform 0.2s ease, box-shadow 0.2s ease;
            height: 100%;
        }
        .stats-card-horarios:hover {
            transform: translateY(-3px);
            box-shadow: 0 0.25rem 0.5rem rgba(0,0,0,0.1);
        }
        .stats-card-horarios .card-body {
            padding: 1.25rem;
            display: flex;
            flex-direction: column;
            align-items: center;
            text-align: center;
        }
        .stats-card-horarios .stat-icon {
            font-size: 2rem;
            color: var(--admin-primary);
            margin-bottom: 0.5rem;
        }
        .stats-card-horarios .value {
            font-size: 2.2rem;
            font-weight: 700;
            color: var(--admin-text-dark);
            line-height: 1;
            margin-bottom: 0.5rem;
        }
        .stats-card-horarios .label {
            font-size: 0.9rem;
            color: var(--admin-text-muted);
        }

        /* FullCalendar Customizations */
        #calendar {
            background-color: var(--admin-card-bg);
            border-radius: 0.5rem;
            padding: 1rem;
            box-shadow: 0 0.125rem 0.25rem rgba(0,0,0,0.075);
            margin-bottom: 1.5rem;
            border-left: 4px solid var(--admin-primary);
        }
        .fc .fc-toolbar-title {
            color: var(--admin-text-dark);
            font-weight: 700;
            font-size: 1.5rem;
        }
        .fc .fc-button-primary {
            background-color: var(--admin-primary) !important;
            border-color: var(--admin-primary) !important;
            color: white !important;
            box-shadow: none !important;
        }
        .fc .fc-button-primary:hover {
            background-color: #0056b3 !important;
            border-color: #0056b3 !important;
        }
        .fc .fc-button-group > .fc-button {
            border-radius: 0.25rem;
        }
        .fc-event {
            border-radius: 0.25rem !important;
            font-size: 0.85rem;
        }
        .fc-event-title {
            white-space: normal;
        }
        .fc .fc-timegrid-slot-label {
            vertical-align: middle;
        }

        /* Custom Modal for Event Details (if reintroduced) */
        #eventModal .modal-header {
            background-color: var(--admin-primary);
            color: white;
            border-bottom: none;
        }
        #eventModal .modal-title {
            color: white;
            font-weight: 600;
        }
        #eventModal .modal-body p {
            margin-bottom: 0.5rem;
            color: var(--admin-text-dark);
        }
        #eventModal .modal-body p strong {
            color: var(--admin-primary);
        }
        .modal-footer {
            border-top: 1px solid var(--admin-light-bg);
        }

        /* Clases del Día (The Surprise) */
        .clases-del-dia-card {
            border-left: 4px solid var(--admin-warning);
            box-shadow: 0 0.125rem 0.25rem rgba(0,0,0,0.075);
            border-radius: 0.5rem;
            padding: 1.5rem;
            margin-bottom: 1.5rem;
        }
        .clases-del-dia-card .list-group-item {
            border: none;
            border-bottom: 1px solid var(--admin-light-bg);
            padding: 0.75rem 0;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .clases-del-dia-card .list-group-item:last-child {
            border-bottom: none;
        }
        .clases-del-dia-card .clase-info {
            flex-grow: 1;
        }
        .clases-del-dia-card .clase-info h6 {
            color: var(--admin-primary);
            margin-bottom: 0.25rem;
            font-weight: 600;
        }
        .clases-del-dia-card .clase-info small {
            color: var(--admin-text-muted);
        }
        .clases-del-dia-card .clase-time-aula {
            text-align: right;
            font-weight: 500;
        }
        .clases-del-dia-card .clase-time-aula .time {
            color: var(--admin-info);
        }
        .clases-del-dia-card .clase-time-aula .aula {
            display: block;
            font-size: 0.85em;
            color: var(--admin-text-muted);
        }


        /* Global error/empty state styling */
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


        /* Responsive adjustments */
        @media (max-width: 992px) {
            .sidebar {
                width: 220px;
            }
            .main-content {
                padding: 1rem;
            }
            .stats-grid-horarios {
                grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
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
            .stats-grid-horarios {
                grid-template-columns: 1fr;
            }
            #calendar {
                padding: 0.5rem;
            }
            .fc .fc-toolbar-title {
                font-size: 1.25rem;
            }
        }

        @media (max-width: 576px) {
            .main-content {
                padding: 0.75rem;
            }
            .welcome-section, .card {
                padding: 1rem;
            }
            .stats-card-horarios .value {
                font-size: 1.8rem;
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
                    <a class="nav-link active" href="horarios_profesor.jsp"><i class="fas fa-calendar-alt"></i><span> Horarios</span></a>
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
                    <h1 class="h3 mb-3">Horarios del Profesor</h1>
                    <p class="lead">Visualiza tu horario de clases y gestiona tu disponibilidad.</p>
                </div>

                <% if (pageLoadErrorMessage != null) { %>
                <div class="alert alert-danger alert-error-message" role="alert">
                    <i class="fas fa-exclamation-triangle me-2"></i>Error al cargar la página: <%= pageLoadErrorMessage %>
                </div>
                <% } %>
                
                <div class="row stats-grid-horarios">
                    <div class="col">
                        <div class="card stats-card-horarios" style="border-left: 4px solid var(--admin-primary);">
                            <div class="card-body">
                                <div class="stat-icon"><i class="fas fa-calendar-alt"></i></div>
                                <div class="value"><%= totalClasesAsignadas %></div>
                                <div class="label">Clases Programadas</div>
                            </div>
                        </div>
                    </div>
                    <div class="col">
                        <div class="card stats-card-horarios" style="border-left: 4px solid var(--admin-info);">
                            <div class="card-body">
                                <div class="stat-icon"><i class="fas fa-map-marker-alt"></i></div>
                                <div class="value">
                                    <% if (salonesHoy.isEmpty()) { %>
                                        0
                                    <% } else { %>
                                        <%= salonesHoy.size() %>
                                    <% } %>
                                </div>
                                <div class="label">Salones Diferentes Hoy</div>
                            </div>
                        </div>
                    </div>
                    <div class="col">
                        <div class="card stats-card-horarios" style="border-left: 4px solid var(--admin-success);">
                            <div class="card-body">
                                <div class="stat-icon"><i class="fas fa-check-circle"></i></div>
                                <div class="value">95%</div> <%-- Métrica de ejemplo --%>
                                <div class="label">Asistencia Promedio</div>
                            </div>
                        </div>
                    </div>
                    <div class="col">
                        <div class="card stats-card-horarios" style="border-left: 4px solid var(--admin-warning);">
                            <div class="card-body">
                                <div class="stat-icon"><i class="fas fa-users-slash"></i></div>
                                <div class="value">0</div> <%-- Métrica de ejemplo --%>
                                <div class="label">Faltas Reportadas</div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="row">
                    <div class="col-12 mb-4">
                        <div class="card clases-del-dia-card">
                            <div class="card-body">
                                <h3 class="section-title card-title"><i class="fas fa-sun me-2"></i>Clases de Hoy (<%= LocalDate.now().getDayOfWeek().getDisplayName(TextStyle.FULL, new Locale("es")).substring(0, 1).toUpperCase() + LocalDate.now().getDayOfWeek().getDisplayName(TextStyle.FULL, new Locale("es")).substring(1) %>)</h3>
                                <% if (!clasesHoyList.isEmpty()) { %>
                                <ul class="list-group list-group-flush">
                                    <% for (Map<String, String> clase : clasesHoyList) { %>
                                        <li class="list-group-item">
                                            <div class="clase-info">
                                                <h6><%= clase.get("curso") %> (<%= clase.get("seccion") %>)</h6>
                                                <small><i class="fas fa-map-marker-alt me-1"></i><%= clase.get("aula") %></small>
                                            </div>
                                            <div class="clase-time-aula">
                                                <span class="time"><%= clase.get("hora_inicio") %> - <%= clase.get("hora_fin") %></span>
                                            </div>
                                        </li>
                                    <% } %>
                                </ul>
                                <% } else { %>
                                <div class="empty-state py-3">
                                    <i class="fas fa-sad-tear"></i>
                                    <h4>¡Día libre! No tienes clases programadas hoy.</h4>
                                    <p>Disfruta tu tiempo o prepárate para mañana.</p>
                                </div>
                                <% } %>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="row">
                    <div class="col-12 mb-4">
                        <div class="card content-section" id="calendar">
                            </div>
                    </div>
                </div>

            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js" integrity="sha384-YvpcrYf0tY3lHB60NNkmXc5s9fDVZLESaAA55NDzOxhy9GkcIdslK1eN7N6jIeHz" crossorigin="anonymous"></script>
    <script src="https://cdn.jsdelivr.net/npm/fullcalendar@6.1.8/index.global.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/fullcalendar@6.1.8/locales-all.global.min.js"></script>
    <script>
        document.addEventListener('DOMContentLoaded', function () {
            const calendarEl = document.getElementById('calendar');
            
            if (calendarEl) {
                const calendar = new FullCalendar.Calendar(calendarEl, {
                    locale: 'es',
                    initialView: 'timeGridWeek',
                    headerToolbar: {
                        left: 'prev,next today',
                        center: 'title',
                        right: 'dayGridMonth,timeGridWeek,timeGridDay'
                    },
                    slotMinTime: "07:00:00",
                    slotMaxTime: "22:00:00",
                    height: 'auto',
                    expandRows: true,
                    events: <%= eventosFullCalendar.toString() %>,

                    eventClick: function(info) {
                        const event = info.event;
                        const props = event.extendedProps;
                        
                        // Redirigir a ver_estudiantes.jsp con el ID de la clase
                        // Asegúrate de que request.getContextPath() esté disponible si la app no está en la raíz
                        window.location.href = '<%= request.getContextPath() %>/INTERFAZ_PROFESOR/ver_estudiantes.jsp?id_clase=' + event.id;
                    },

                    eventDidMount: function(info) {
                        info.el.setAttribute('title',
                            `${info.event.title}\nSalón: ${info.event.extendedProps.salon}\nHorario: ${info.event.start ? info.event.start.toLocaleTimeString('es-ES', {hour: '2-digit', minute:'2-digit'}) : 'N/A'} - ${info.event.end ? info.event.end.toLocaleTimeString('es-ES', {hour: '2-digit', 'minute':'2-digit'}) : 'N/A'}`
                        );
                    },

                    businessHours: {
                        daysOfWeek: [1, 2, 3, 4, 5, 6],
                        startTime: '07:00',
                        endTime: '22:00'
                    },

                    slotLabelFormat: {
                        hour: '2-digit',
                        minute: '2-digit',
                        hour12: false
                    },

                    eventTimeFormat: {
                        hour: '2-digit',
                        minute: '2-digit',
                        hour12: false
                    }
                });

                calendar.render();
            } else {
                console.error("El elemento con ID 'calendar' no se encontró en el DOM.");
            }
        });
    </script>
</body>
</html>
<%
    // Cierre final de la conexión 'conn' que se abrió al inicio del scriptlet.
    if (conn != null) {
        try {
            conn.close();
        } catch (SQLException ignore) {
        }
    }
%>