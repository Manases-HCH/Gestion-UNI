<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, pe.universidad.util.Conection" %>
<%@ page import="java.time.LocalDate, java.time.format.DateTimeFormatter, java.time.DayOfWeek, java.time.temporal.TemporalAdjusters" %>
<%@ page import="java.time.format.TextStyle" %> <%-- Importación de TextStyle --%>
<%@ page import="java.util.Locale" %>
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
            System.err.println("Error cerrando ResultSet: " + e.getMessage()); // Loguear error al cerrar
        }
        try {
            if (pstmt != null) {
                pstmt.close();
            }
        } catch (SQLException e) {
            System.err.println("Error cerrando PreparedStatement: " + e.getMessage()); // Loguear error al cerrar
        }
    }
%>

<%
    // ====================================================================
    // 🧪 FORZAR SESIÓN TEMPORALMENTE PARA APODERADO (SOLO PARA TEST)
    // REMOVER ESTE BLOQUE EN PRODUCCIÓN O CUANDO EL LOGIN REAL FUNCIONE
    if (session.getAttribute("id_apoderado") == null) {
        session.setAttribute("email", "roberto.sanchez@gmail.com"); // Email de un apoderado que exista en tu BD (ID 1 en bd_sw.sql)
        session.setAttribute("rol", "apoderado");
        session.setAttribute("id_apoderado", 1);    // ID del apoderado en tu BD (ej: Roberto Carlos Sánchez Díaz)
    }
    // ====================================================================

    // --- Obtener información de la sesión ---
    String emailSesion = (String) session.getAttribute("email");
    String rolUsuario = (String) session.getAttribute("rol");
    Object idApoderadoObj = session.getAttribute("id_apoderado");
    
    // --- Variables para los datos del apoderado y su hijo ---
    int idApoderado = -1;    
    String nombreApoderado = "Apoderado Desconocido";
    String emailApoderado = (emailSesion != null ? emailSesion : "N/A");
    String telefonoApoderado = "No registrado";    

    int idHijo = -1;
    String nombreHijo = "Hijo No Asignado";
    String dniHijo = "N/A";
    String carreraHijo = "Carrera Desconocida";
    String estadoHijo = "N/A";    

    List<Map<String, String>> cursosHijoDetalleList = new ArrayList<>();
    List<String> nombresCursosPromedio = new ArrayList<>();
    List<Double> promediosCursos = new ArrayList<>();

    // --- Datos para el calendario de clases ---
    List<Map<String, String>> clasesParaCalendario = new ArrayList<>();
    LocalDate hoy = LocalDate.now();
    int anioActual = hoy.getYear();
    int mesActual = hoy.getMonthValue();
    LocalDate primerDiaMes = LocalDate.of(anioActual, mesActual, 1);
    LocalDate ultimoDiaMes = primerDiaMes.with(TemporalAdjusters.lastDayOfMonth());
    String nombreMesActual = primerDiaMes.getMonth().getDisplayName(TextStyle.FULL, new Locale("es", "ES"));

    // --- Datos para el gráfico lineal de asistencia mensual ---
    List<String> fechasAsistenciaMes = new ArrayList<>();
    List<Integer> presentesPorDia = new ArrayList<>();
    List<Integer> ausentesPorDia = new ArrayList<>();
    List<Integer> tardanzasPorDia = new ArrayList<>();


    Connection conn = null;        
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    String globalErrorMessage = null;        

    try {
        // --- 1. Validar y obtener ID del Apoderado de Sesión ---
        if (emailSesion == null || !"apoderado".equalsIgnoreCase(rolUsuario) || idApoderadoObj == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");    
            return;
        }
        try {
            idApoderado = Integer.parseInt(String.valueOf(idApoderadoObj));
        } catch (NumberFormatException e) {
            System.err.println("ERROR (cursos_apoderado): ID de apoderado en sesión no es un número válido. " + e.getMessage());
            globalErrorMessage = "Error de sesión: ID de apoderado inválido.";
        }

        // Si idApoderado es válido, intentar conectar y cargar datos
        if (idApoderado != -1 && globalErrorMessage == null) {
            // --- 2. Conectar a la Base de Datos ---
            Conection c = new Conection();
            conn = c.conecta();    
            if (conn == null || conn.isClosed()) {
                throw new SQLException("No se pudo establecer conexión a la base de datos.");
            }

            // --- 3. Obtener Nombre y Datos del Apoderado ---
            try {
                String sqlApoderado = "SELECT nombre, apellido_paterno, apellido_materno, email, telefono FROM apoderados WHERE id_apoderado = ?";
                pstmt = conn.prepareStatement(sqlApoderado);
                pstmt.setInt(1, idApoderado);
                rs = pstmt.executeQuery();
                if (rs.next()) {
                    String nombre = rs.getString("nombre") != null ? rs.getString("nombre") : "";
                    String apPaterno = rs.getString("apellido_paterno") != null ? rs.getString("apellido_paterno") : "";
                    String apMaterno = rs.getString("apellido_materno") != null ? rs.getString("apellido_materno") : "";
                    nombreApoderado = nombre + " " + apPaterno;
                    if (!apMaterno.isEmpty()) { nombreApoderado += " " + apMaterno; }
                    emailApoderado = rs.getString("email");
                    telefonoApoderado = rs.getString("telefono") != null ? rs.getString("telefono") : "No registrado";
                    session.setAttribute("nombre_apoderado", nombreApoderado);    
                } else {
                    globalErrorMessage = "Apoderado no encontrado en la base de datos. Por favor, contacte a soporte.";
                    System.err.println("ERROR (cursos_apoderado): Apoderado con ID " + idApoderado + " no encontrado en BD.");
                }
            } finally { cerrarRecursos(rs, pstmt); }

            // --- 4. Obtener ID y Nombre del Hijo ---
            if (globalErrorMessage == null) {    
                try {
                    String sqlHijo = "SELECT a.id_alumno, a.dni, a.nombre, a.apellido_paterno, a.apellido_materno, c.nombre_carrera, a.estado "
                                           + "FROM alumnos a "
                                           + "JOIN alumno_apoderado aa ON a.id_alumno = aa.id_alumno "
                                           + "JOIN carreras c ON a.id_carrera = c.id_carrera "
                                           + "WHERE aa.id_apoderado = ? LIMIT 1";    
                    pstmt = conn.prepareStatement(sqlHijo);
                    pstmt.setInt(1, idApoderado);
                    rs = pstmt.executeQuery();
                    if (rs.next()) {
                        idHijo = rs.getInt("id_alumno");
                        String nombre = rs.getString("nombre") != null ? rs.getString("nombre") : "";
                        String apPaterno = rs.getString("apellido_paterno") != null ? rs.getString("apellido_paterno") : "";
                        String apMaterno = rs.getString("apellido_materno") != null ? rs.getString("apellido_materno") : "";
                        nombreHijo = nombre + " " + apPaterno;
                        if (!apMaterno.isEmpty()) { nombreHijo += " " + apMaterno; }
                        dniHijo = rs.getString("dni") != null ? rs.getString("dni") : "N/A";
                        carreraHijo = rs.getString("nombre_carrera") != null ? rs.getString("nombre_carrera") : "Desconocida";
                        estadoHijo = rs.getString("estado") != null ? rs.getString("estado") : "N/A";
                        session.setAttribute("id_hijo", idHijo);    
                        session.setAttribute("nombre_hijo", nombreHijo);    
                    } else {
                        globalErrorMessage = "No se encontró un hijo asociado a este apoderado. Contacte a la administración para asignar a su hijo/a.";
                        System.err.println("ERROR (cursos_apoderado): No se encontró hijo para apoderado ID: " + idApoderado);
                        idHijo = -1; // Asegurar que idHijo sea inválido si no se encuentra
                    }
                } finally { cerrarRecursos(rs, pstmt); }
            }

            // --- 5. Obtener Cursos Detallados, Promedios y Datos de Asistencia/Calendario del Hijo ---
            if (idHijo != -1 && globalErrorMessage == null) {
                // a) Cursos Detallados del Hijo (para la tabla)
                String sqlCursosDetalle = "SELECT cu.nombre_curso, cu.codigo_curso, cu.creditos, "
                                             + "cl.seccion, cl.ciclo, cl.semestre, cl.año_academico, "
                                             + "p.nombre AS nombre_profesor, p.apellido_paterno AS apPaterno_profesor, "
                                             + "h.dia_semana, h.hora_inicio, h.hora_fin, h.aula, "
                                             + "n.nota_final, n.estado AS estado_nota "
                                             + "FROM inscripciones i "
                                             + "JOIN clases cl ON i.id_clase = cl.id_clase "
                                             + "JOIN cursos cu ON cl.id_curso = cu.id_curso "
                                             + "JOIN profesores p ON cl.id_profesor = p.id_profesor "
                                             + "JOIN horarios h ON cl.id_horario = h.id_horario "
                                             + "LEFT JOIN notas n ON i.id_inscripcion = n.id_inscripcion "    
                                             + "WHERE i.id_alumno = ? AND i.estado = 'inscrito' "
                                             + "ORDER BY cl.año_academico DESC, cl.semestre DESC, cu.nombre_curso";

                pstmt = conn.prepareStatement(sqlCursosDetalle);
                pstmt.setInt(1, idHijo);
                rs = pstmt.executeQuery();

                while(rs.next()) {
                    Map<String, String> cursoDetalle = new HashMap<>();
                    cursoDetalle.put("nombre_curso", rs.getString("nombre_curso"));
                    cursoDetalle.put("codigo_curso", rs.getString("codigo_curso"));
                    cursoDetalle.put("creditos", String.valueOf(rs.getInt("creditos")));
                    cursoDetalle.put("seccion", rs.getString("seccion"));
                    cursoDetalle.put("ciclo", rs.getString("ciclo"));
                    cursoDetalle.put("semestre", rs.getString("semestre"));
                    cursoDetalle.put("anio_academico", String.valueOf(rs.getInt("año_academico")));

                    String profNombre = rs.getString("nombre_profesor") != null ? rs.getString("nombre_profesor") : "";
                    String profApPaterno = rs.getString("apPaterno_profesor") != null ? rs.getString("apPaterno_profesor") : "";
                    String nombreProfesorCompleto = profNombre + " " + profApPaterno;
                    cursoDetalle.put("profesor", nombreProfesorCompleto);

                    cursoDetalle.put("dia_semana", rs.getString("dia_semana"));
                    cursoDetalle.put("hora_inicio", rs.getString("hora_inicio").substring(0, 5));
                    cursoDetalle.put("hora_fin", rs.getString("hora_fin").substring(0, 5));
                    cursoDetalle.put("aula", rs.getString("aula"));

                    double notaFinal = rs.getDouble("nota_final");
                    if (rs.wasNull()) {
                        cursoDetalle.put("nota_final", "N/A");
                        cursoDetalle.put("estado_nota", "PENDIENTE");
                    } else {
                        cursoDetalle.put("nota_final", String.format(Locale.US, "%.2f", notaFinal));
                        cursoDetalle.put("estado_nota", rs.getString("estado_nota").toUpperCase());
                    }
                    cursosHijoDetalleList.add(cursoDetalle);
                }
            }
            // b) Promedios de Notas por Curso para el Gráfico
            if (globalErrorMessage == null) {
                try {
                    String sqlPromediosGrafico = "SELECT cu.nombre_curso, AVG(n.nota_final) AS promedio_nota "
                                                 + "FROM inscripciones i "
                                                 + "JOIN clases cl ON i.id_clase = cl.id_clase "
                                                 + "JOIN cursos cu ON cl.id_curso = cu.id_curso "
                                                 + "JOIN notas n ON i.id_inscripcion = n.id_inscripcion "
                                                 + "WHERE i.id_alumno = ? AND n.nota_final IS NOT NULL "
                                                 + "GROUP BY cu.nombre_curso ORDER BY promedio_nota DESC LIMIT 5";    
                    pstmt = conn.prepareStatement(sqlPromediosGrafico);
                    pstmt.setInt(1, idHijo);
                    rs = pstmt.executeQuery();
                    while (rs.next()) {
                        nombresCursosPromedio.add(rs.getString("nombre_curso"));
                        promediosCursos.add(rs.getDouble("promedio_nota"));
                    }
                } finally { cerrarRecursos(rs, pstmt); }
            }

            // c) Clases del Hijo para el Calendario (para el mes actual)
            if (globalErrorMessage == null) {
                try {
                    String sqlClasesCalendario = "SELECT cl.id_clase, cu.nombre_curso, cl.seccion, "
                                                 + "h.dia_semana, h.hora_inicio, h.hora_fin, h.aula "
                                                 + "FROM inscripciones i "
                                                 + "JOIN clases cl ON i.id_clase = cl.id_clase "
                                                 + "JOIN cursos cu ON cl.id_curso = cu.id_curso "
                                                 + "JOIN horarios h ON cl.id_horario = h.id_horario "
                                                 + "WHERE i.id_alumno = ? AND i.estado = 'inscrito' AND cl.estado = 'activo' "
                                                 + "ORDER BY h.dia_semana, h.hora_inicio";
                    pstmt = conn.prepareStatement(sqlClasesCalendario);
                    pstmt.setInt(1, idHijo);
                    rs = pstmt.executeQuery();
                    while (rs.next()) {
                        Map<String, String> clase = new HashMap<>();
                        clase.put("id_clase", String.valueOf(rs.getInt("id_clase")));
                        clase.put("nombre_curso", rs.getString("nombre_curso"));
                        clase.put("seccion", rs.getString("seccion"));
                        clase.put("dia_semana", rs.getString("dia_semana"));
                        clase.put("hora_inicio", rs.getString("hora_inicio").substring(0, 5));
                        clase.put("hora_fin", rs.getString("hora_fin").substring(0, 5));
                        clase.put("aula", rs.getString("aula"));
                        clasesParaCalendario.add(clase);
                    }
                } finally { cerrarRecursos(rs, pstmt); }
            }

            // d) Datos para Gráfico Lineal de Asistencia del Mes
            if (globalErrorMessage == null) {
                try {
                    String sqlAsistenciaMensual = "SELECT DATE_FORMAT(a.fecha, '%Y-%m-%d') AS dia, "
                                                 + "SUM(CASE WHEN a.estado = 'presente' THEN 1 ELSE 0 END) AS presentes, "
                                                 + "SUM(CASE WHEN a.estado = 'ausente' THEN 1 ELSE 0 END) AS ausentes, "
                                                 + "SUM(CASE WHEN a.estado = 'tardanza' THEN 1 ELSE 0 END) AS tardanzas "
                                                 + "FROM asistencia a "
                                                 + "JOIN inscripciones i ON a.id_inscripcion = i.id_inscripcion "
                                                 + "WHERE i.id_alumno = ? AND a.fecha BETWEEN ? AND ? "
                                                 + "GROUP BY a.fecha ORDER BY a.fecha ASC";
                    
                    pstmt = conn.prepareStatement(sqlAsistenciaMensual);
                    pstmt.setInt(1, idHijo);
                    pstmt.setString(2, primerDiaMes.format(DateTimeFormatter.ISO_LOCAL_DATE)); // 'YYYY-MM-DD'
                    pstmt.setString(3, ultimoDiaMes.format(DateTimeFormatter.ISO_LOCAL_DATE)); // 'YYYY-MM-DD'
                    rs = pstmt.executeQuery();

                    while (rs.next()) {
                        fechasAsistenciaMes.add(rs.getString("dia"));
                        presentesPorDia.add(rs.getInt("presentes"));
                        ausentesPorDia.add(rs.getInt("ausentes"));
                        tardanzasPorDia.add(rs.getInt("tardanzas"));
                    }
                } finally { cerrarRecursos(rs, pstmt); }
            }

        } // Fin if (idApoderado != -1) para operaciones de BD
        
    } catch (SQLException e) {
        globalErrorMessage = "Error de base de datos al cargar la información: " + e.getMessage();
        System.err.println("ERROR (cursos_apoderado) SQL Principal: " + globalErrorMessage);
        e.printStackTrace();
    } catch (ClassNotFoundException e) {
        globalErrorMessage = "Error de configuración: Driver JDBC no encontrado. Asegúrate de que el conector esté en WEB-INF/lib.";
        System.err.println("ERROR (cursos_apoderado) DRIVER Principal: " + globalErrorMessage);
        e.printStackTrace();
    } finally {
        // Cierre final de la conexión
        try {
            if (conn != null) {
                conn.close();
            }
        } catch (SQLException e) {
            System.err.println("Error al cerrar conexión final: " + e.getMessage());
        }
    }
    // El 'Locale' es importante para el formato de nombres de días y meses en español.
    String ultimoAcceso = LocalDateTime.now().format(DateTimeFormatter.ofPattern("EEEE, d 'de' MMMM 'de' yyyy, HH:mm", new Locale("es", "ES")));
%>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Cursos de mi Hijo | Dashboard Apoderado | Sistema Universitario</title>
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
            border-left: 4px solid var(--admin-primary); /* Default border color */
            margin-bottom: 1.5rem;
        }
        .content-section.card .card-header {
             background-color: var(--admin-card-bg); /* Keep header white */
             border-bottom: 1px solid #dee2e6; /* Light separator */
             padding-bottom: 1rem;
        }
        .content-section .section-title {
            color: var(--admin-primary);
            font-weight: 600;
            margin-bottom: 0; /* Adjusted for card-header title */
        }
        .content-section.card .card-body p.text-muted {
            font-size: 0.95rem; /* Slightly larger text for general info */
        }


        /* Tablas */
        .table-responsive {
            max-height: 500px; /* Max height for scrollable tables */
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
            position: sticky; /* Make header sticky */
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
        .badge.bg-warning { background-color: var(--admin-warning) !important; color: var(--admin-text-dark) !important;} /* Warning badge text is dark */
        .badge.bg-secondary { background-color: var(--admin-secondary-color) !important; }

        /* Chart Container */
        .chart-container {
            height: 300px; /* Tamaño más pequeño para los gráficos */
            width: 100%;
            margin: auto;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 1rem; /* Padding inside chart container */
        }
        .chart-container canvas {
            max-width: 100%;
            max-height: 100%;
        }

        /* Calendar de Clases */
        .calendar-display {
            border: 1px solid #dee2e6;
            border-radius: 0.5rem;
            overflow: hidden; /* Para que los bordes redondeados se apliquen bien */
            background-color: var(--admin-card-bg);
            box-shadow: 0 0.125rem 0.25rem rgba(0,0,0,0.075);
            padding: 1rem;
        }
        .calendar-days-header {
            display: grid;
            grid-template-columns: repeat(7, 1fr);
            text-align: center;
            background-color: var(--admin-light-bg);
            padding: 0.5rem 0;
            border-bottom: 1px solid #dee2e6;
            font-size: 0.9rem;
        }
        .calendar-days-header > div {
            padding: 0.25rem;
            color: var(--admin-primary);
        }
        .calendar-grid-dynamic {
            display: grid;
            grid-template-columns: repeat(7, 1fr);
            gap: 2px; /* Espacio más pequeño entre días */
            text-align: center;
            padding-top: 0.5rem;
        }
        .calendar-grid-dynamic .day-cell {
            padding: 8px;
            min-height: 80px; /* Altura mínima para cada día */
            border: 1px solid #f0f0f0;
            background-color: var(--admin-card-bg);
            font-size: 0.9rem;
            display: flex;
            flex-direction: column;
            align-items: center;
            position: relative;
            cursor: default; /* Por defecto no es clicable, los eventos son en el tooltip */
        }
        .calendar-grid-dynamic .day-cell.other-month {
            background-color: var(--admin-light-bg);
            color: var(--admin-text-muted);
        }
        .calendar-grid-dynamic .day-number {
            font-weight: bold;
            font-size: 1.1em;
            margin-bottom: 5px;
            color: var(--admin-text-dark);
        }
        .calendar-grid-dynamic .day-cell.current-day {
            border: 2px solid var(--admin-primary);
            background-color: rgba(0, 123, 255, 0.1);
            box-shadow: 0 0 5px rgba(0, 123, 255, 0.3);
        }
        .calendar-grid-dynamic .day-cell .class-indicator {
            background-color: var(--admin-info);
            color: white;
            font-size: 0.7rem;
            padding: 2px 4px;
            border-radius: 3px;
            margin-top: 2px;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
            width: 90%;
        }
        .calendar-grid-dynamic .day-cell.has-classes {
            cursor: pointer;
        }
        /* Estilo para el tooltip de las clases */
        .tooltip-inner {
            background-color: var(--admin-dark);
            color: white;
            max-width: 300px;
            padding: 0.75rem;
            font-size: 0.875rem;
            text-align: left;
        }
        .tooltip.bs-tooltip-auto[data-popper-placement^=top] .tooltip-arrow::before { border-top-color: var(--admin-dark); }
        .tooltip.bs-tooltip-auto[data-popper-placement^=bottom] .tooltip-arrow::before { border-bottom-color: var(--admin-dark); }
        .tooltip.bs-tooltip-auto[data-popper-placement^=left] .tooltip-arrow::before { border-left-color: var(--admin-dark); }
        .tooltip.bs-tooltip-auto[data-popper-placement^=right] .tooltip-arrow::before { border-right-color: var(--admin-dark); }


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
            .chart-container { height: 250px; } /* Ajuste de altura para gráficos en móvil */
        }
        @media (max-width: 576px) {
            .main-content { padding: 0.75rem; }
            .welcome-section, .card { padding: 0.75rem;}
            .calendar-grid-dynamic .day-cell { min-height: 60px; padding: 5px; font-size: 0.8rem; }
            .calendar-grid-dynamic .day-number { font-size: 1em; }
        }
    </style>
</head>
<body>
    <div id="app">
        <nav class="sidebar">
            <div class="sidebar-header">
                <a href="<%= request.getContextPath() %>/INTERFAZ_APODERADO/home_apoderado.jsp" class="text-white text-decoration-none">UGIC Portal</a>
            </div>
            <ul class="navbar-nav">
                <li class="nav-item">
                    <a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_APODERADO/home_apoderado.jsp"><i class="fas fa-home"></i><span> Inicio</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link active" href="<%= request.getContextPath() %>/INTERFAZ_APODERADO/cursos_apoderado.jsp"><i class="fas fa-book"></i><span> Cursos de mi hijo</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_APODERADO/asistencia_apoderado.jsp"><i class="fas fa-clipboard-check"></i><span> Asistencia de mi hijo</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_APODERADO/notas_apoderado.jsp"><i class="fas fa-percent"></i><span> Notas de mi hijo</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_APODERADO/pagos_apoderado.jsp"><i class="fas fa-money-bill-wave"></i><span> Pagos y Mensualidades</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_APODERADO/mensajes_apoderado.jsp"><i class="fas fa-envelope"></i><span> Mensajes</span></a>
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
                            
                            <li><a class="dropdown-item" href="mensaje_apoderado.jsp">Ver todos</a></li>
                        </ul>
                    </div>

                    <div class="dropdown user-dropdown">
                        <a class="dropdown-toggle" href="#" role="button" id="userDropdown" data-bs-toggle="dropdown" aria-expanded="false">
                            <img src="https://via.placeholder.com/32" alt="Avatar"> <span class="d-none d-md-inline-block"><%= nombreApoderado %></span>
                        </a>
                        <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="userDropdown">
                            <li><a class="dropdown-item" href="perfil_apoderado.jsp"><i class="fas fa-user me-2"></i>Perfil</a></li>
                            <li><a class="dropdown-item" href="configuracion_apoderado.jsp"><i class="fas fa-cog me-2"></i>Configuración</a></li>
                            <li><hr class="dropdown-divider"></li>
                            <li><a class="dropdown-item" href="logout.jsp"><i class="fas fa-sign-out-alt me-2"></i>Cerrar sesión</a></li>
                        </ul>
                    </div>
                </div>
            </nav>
            <div class="container-fluid">
                <div class="welcome-section">
                    <h1 class="h3 mb-3"><i class="fas fa-book-open me-2"></i>Cursos Inscritos de <%= nombreHijo %></h1>
                    <p class="lead">Aquí puede ver el detalle de los cursos en los que su hijo/a está matriculado, incluyendo profesor, horario y su última nota final.</p>
                </div>

                <% if (globalErrorMessage != null) { %>
                    <div class="alert alert-danger alert-dismissible fade show" role="alert">
                        <i class="fas fa-exclamation-triangle me-2"></i> <%= globalErrorMessage %>
                        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                    </div>
                <% } %>

                <div class="card content-section mb-4">
                    <div class="card-header">
                        <h3 class="section-title mb-0"><i class="fas fa-child me-2"></i>Información General de <%= nombreHijo %></h3>
                    </div>
                    <div class="card-body">
                        <% if (idHijo != -1) { %>
                        <div class="row">
                            <div class="col-md-6">
                                <p class="mb-1"><strong>DNI:</strong> <%= dniHijo %></p>
                                <p class="mb-1"><strong>Carrera:</strong> <%= carreraHijo %></p>
                            </div>
                            <div class="col-md-6">
                                <p class="mb-1"><strong>Estado Académico:</strong> <%= estadoHijo.toUpperCase() %></p>
                                <p class="mb-1"><strong>Total Clases Inscritas:</strong> <%= cursosHijoDetalleList.size() %></p>
                            </div>
                        </div>
                        <% } else { %>
                        <p class="text-muted text-center py-3 mb-0">No se encontró información detallada del hijo/a.</p>
                        <% } %>
                    </div>
                </div>

               
                <div class="card content-section mb-4">
                    <div class="card-header">
                        <h3 class="section-title mb-0"><i class="fas fa-list-alt me-2"></i>Detalle de Cursos Inscritos</h3>
                    </div>
                    <div class="card-body">
                        <div class="table-responsive">
                            <% if (!cursosHijoDetalleList.isEmpty()) { %>
                            <table class="table table-hover table-striped">
                                <thead>
                                    <tr>
                                        <th>Curso</th>
                                        <th>Sección</th>
                                        <th>Créditos</th>
                                        <th>Período</th>
                                        <th>Profesor</th>
                                        <th>Horario</th>
                                        <th>Aula</th>
                                        <th>Nota Final</th>
                                        <th>Estado Nota</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <% for (Map<String, String> curso : cursosHijoDetalleList) {%>
                                    <tr>
                                        <td><%= curso.get("nombre_curso") %> (<%= curso.get("codigo_curso") %>)</td>
                                        <td><%= curso.get("seccion") %></td>
                                        <td><%= curso.get("creditos") %></td>
                                        <td><%= curso.get("semestre") %> / <%= curso.get("anio_academico") %></td>
                                        <td><%= curso.get("profesor") %></td>
                                        <td><%= curso.get("dia_semana") %> (<%= curso.get("hora_inicio") %> - <%= curso.get("hora_fin") %>)</td>
                                        <td><%= curso.get("aula") %></td>
                                        <td><%= curso.get("nota_final") %></td>
                                        <td>
                                            <%    
                                                String estadoNota = curso.get("estado_nota");
                                                String badgeClass = "bg-secondary"; // Default for N/A or others
                                                if ("APROBADO".equalsIgnoreCase(estadoNota)) { badgeClass = "bg-success"; }
                                                else if ("DESAPROBADO".equalsIgnoreCase(estadoNota)) { badgeClass = "bg-danger"; }
                                                else if ("PENDIENTE".equalsIgnoreCase(estadoNota)) { badgeClass = "bg-warning text-dark"; } // text-dark for warning badge
                                            %>
                                            <span class="badge <%= badgeClass %>"><%= estadoNota %></span>
                                        </td>
                                    </tr>
                                    <% } %>
                                </tbody>
                            </table>
                            <% } else { %>
                            <p class="text-muted text-center py-3">Su hijo/a no tiene cursos inscritos actualmente o no se pudieron cargar.</p>
                            <% } %>
                        </div>
                    </div>
                </div>

                <div class="card content-section mb-4">
                    <div class="card-header">
                        <h3 class="section-title mb-0"><i class="fas fa-calendar-check me-2"></i>Horario de Clases de <%= nombreHijo %></h3>
                        <p class="card-text text-muted mb-0"><small>Clases para <%= nombreMesActual %> de <%= anioActual %>.</small></p>
                    </div>
                    <div class="card-body">
                        <div class="calendar-display">
                            <div class="calendar-days-header d-flex text-center mb-2">
                                <div class="flex-fill fw-bold text-primary">Dom</div>
                                <div class="flex-fill fw-bold text-primary">Lun</div>
                                <div class="flex-fill fw-bold text-primary">Mar</div>
                                <div class="flex-fill fw-bold text-primary">Mié</div>
                                <div class="flex-fill fw-bold text-primary">Jue</div>
                                <div class="flex-fill fw-bold text-primary">Vie</div>
                                <div class="flex-fill fw-bold text-primary">Sáb</div>
                            </div>
                            <div class="calendar-grid-dynamic" id="calendarGridDynamic">
                                </div>
                            <% if (clasesParaCalendario.isEmpty()) { %>
                                <p class="text-muted text-center py-3 mt-3 mb-0">No se encontraron clases para su hijo/a este mes.</p>
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
            // --- Gráfico de Promedio de Notas por Curso ---
            const nombresCursosPromedio = [
                <%
                    for (int i = 0; i < nombresCursosPromedio.size(); i++) {
                        out.print("'" + nombresCursosPromedio.get(i).replace("'", "\\'") + "'"); // Escape single quotes
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

            const ctxPromedioNotas = document.getElementById('promedioNotasChart');
            if (ctxPromedioNotas) {
                new Chart(ctxPromedioNotas.getContext('2d'), {
                    type: 'bar',
                    data: {
                        labels: nombresCursosPromedio,
                        datasets: [{
                            label: 'Promedio de Nota Final',
                            data: promediosCursos,
                            backgroundColor: 'rgba(0, 123, 255, 0.8)', // Color de barra (azul primario)
                            borderColor: 'rgba(0, 123, 255, 1)',
                            borderWidth: 1,
                            borderRadius: 5, // Barras redondeadas
                        }]
                    },
                    options: {
                        indexAxis: 'y', // Hace que el gráfico de barras sea horizontal
                        responsive: true,
                        maintainAspectRatio: false,
                        scales: {
                            x: {
                                beginAtZero: true,
                                max: 20, // Escala de notas de 0 a 20
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
                                display: false, // El título ya está en el HTML (h3)
                            },
                            legend: {
                                display: false, // Ocultar leyenda del dataset
                            },
                            tooltip: { // Estilo del tooltip
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
                                            label += context.parsed.x.toFixed(2); // Formatear a 2 decimales
                                        }
                                        return label;
                                    }
                                }
                            }
                        }
                    }
                });
            }

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
                                tension: 0.3
                            },
                            {
                                label: 'Ausentes',
                                data: ausentesPorDia,
                                borderColor: 'var(--admin-danger)',
                                backgroundColor: 'rgba(220, 53, 69, 0.2)',
                                fill: true,
                                tension: 0.3
                            },
                            {
                                label: 'Tardanzas',
                                data: tardanzasPorDia,
                                borderColor: 'var(--admin-warning)',
                                backgroundColor: 'rgba(255, 193, 7, 0.2)',
                                fill: true,
                                tension: 0.3
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
                                    precision: 0 // No decimales para conteo
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

            // --- Lógica para el Calendario de Clases Dinámico ---
            const clasesParaCalendario = [
                <%    
                    for (Map<String, String> clase : clasesParaCalendario) {
                        out.print("{ ");
                        out.print("id_clase: '" + clase.get("id_clase") + "', ");
                        out.print("nombre_curso: '" + clase.get("nombre_curso").replace("'", "\\'") + "', "); // Escape
                        out.print("seccion: '" + clase.get("seccion") + "', ");
                        out.print("dia_semana: '" + clase.get("dia_semana") + "', ");
                        out.print("hora_inicio: '" + clase.get("hora_inicio") + "', ");
                        out.print("hora_fin: '" + clase.get("hora_fin") + "', ");
                        out.print("aula: '" + clase.get("aula") + "' ");
                        out.print("},");
                    }
                %>
            ];
            
            const calendarGridDynamic = document.getElementById('calendarGridDynamic');
            const hoy = new Date();
            const anioActual = hoy.getFullYear();
            const mesActual = hoy.getMonth(); // 0-11
            const diaHoy = hoy.getDate();

            function getDaysInMonth(year, month) {
                return new Date(year, month + 1, 0).getDate();
            }

            // getDay() devuelve 0 para domingo, 1 para lunes...
            function getFirstDayOfWeekIndex(year, month) {
                const firstDay = new Date(year, month, 1).getDay();
                return firstDay; // Si Domingo es el primer día de la columna (como en tu calendario HTML)
            }

            const diasSemanaMap = { // Mapeo de días de la semana de la DB a índices de JavaScript (0=Dom, 1=Lun...)
                'domingo': 0, 'lunes': 1, 'martes': 2, 'miercoles': 3, 'jueves': 4, 'viernes': 5, 'sabado': 6
            };

            if (calendarGridDynamic) {
                calendarGridDynamic.innerHTML = ''; // Clear previous content

                const numDiasMes = getDaysInMonth(anioActual, mesActual);
                const primerDiaSemanaIndex = getFirstDayOfWeekIndex(anioActual, mesActual); // 0-6 (Dom-Sab)

                // Rellenar días vacíos al inicio del mes (días del mes anterior)
                for (let i = 0; i < primerDiaSemanaIndex; i++) {
                    const emptyDayDiv = document.createElement('div');
                    emptyDayDiv.classList.add('day-cell', 'other-month'); // Clase para días de otro mes
                    emptyDayDiv.textContent = '';    
                    calendarGridDynamic.appendChild(emptyDayDiv);
                }

                // Generar días del mes actual
                for (let dia = 1; dia <= numDiasMes; dia++) {
                    const dayDiv = document.createElement('div');
                    dayDiv.classList.add('day-cell');
                    
                    const dayNumberSpan = document.createElement('span');
                    dayNumberSpan.classList.add('day-number');
                    dayNumberSpan.textContent = dia;
                    dayDiv.appendChild(dayNumberSpan);

                    if (dia === diaHoy && mesActual === hoy.getMonth() && anioActual === hoy.getFullYear()) {
                        dayDiv.classList.add('current-day');
                    }

                    // Añadir clases programadas para este día
                    const fechaClaseActual = new Date(anioActual, mesActual, dia);
                    const diaSemanaClaseIndex = fechaClaseActual.getDay(); // 0-6 (Dom-Sab)
                    const clasesDelDia = clasesParaCalendario.filter(clase => diasSemanaMap[clase.dia_semana] === diaSemanaClaseIndex);

                    if (clasesDelDia.length > 0) {
                        dayDiv.classList.add('has-classes'); // Añadir clase para estilizar días con clases
                        let tooltipContent = `<div class="fw-bold mb-1">${dia} de <%= nombreMesActual %></div>`;
                        clasesDelDia.forEach(clase => {
                            tooltipContent += `<div class="mb-1"><i class="fas fa-dot-circle text-primary me-1"></i>${clase.nombre_curso} (${clase.seccion})<br><small>${clase.hora_inicio}-${clase.hora_fin} / Aula: ${clase.aula}</small></div>`;
                            
                            // Mostrar una o dos clases directamente en la celda si hay espacio
                            if (dayDiv.querySelectorAll('.class-indicator').length < 2) { // Limitar a 2 indicadores
                                const indicator = document.createElement('span');
                                indicator.classList.add('class-indicator');
                                indicator.textContent = `${clase.nombre_curso.split(' ')[0]} (${clase.hora_inicio})`; // Ej: "Prog I (08:00)"
                                dayDiv.appendChild(indicator);
                            }
                        });
                        dayDiv.setAttribute('data-bs-toggle', 'tooltip');
                        dayDiv.setAttribute('data-bs-html', 'true'); // Permite HTML en el tooltip
                        dayDiv.setAttribute('title', tooltipContent);
                    }
                    calendarGridDynamic.appendChild(dayDiv);
                }

                // Rellenar días vacíos al final del mes para completar la última semana
                const totalCells = primerDiaSemanaIndex + numDiasMes;
                const cellsToFill = 7 - (totalCells % 7); // Calcular cuántas celdas faltan para la última semana completa
                if (cellsToFill < 7) { // Solo si no es una semana ya completa
                    for (let i = 0; i < cellsToFill; i++) {
                        const emptyDayDiv = document.createElement('div');
                        emptyDayDiv.classList.add('day-cell', 'other-month');
                        emptyDayDiv.textContent = '';
                        calendarGridDynamic.appendChild(emptyDayDiv);
                    }
                }

                // Inicializar todos los tooltips de Bootstrap
                const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
                const tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
                    return new bootstrap.Tooltip(tooltipTriggerEl)
                });
            }
        });
    </script>
</body>
</html>