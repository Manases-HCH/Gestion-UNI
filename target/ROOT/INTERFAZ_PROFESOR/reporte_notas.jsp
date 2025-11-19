<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, pe.universidad.util.Conection" %>
<%@ page import="java.time.LocalDateTime, java.time.format.DateTimeFormatter" %>
<%@ page import="java.util.ArrayList, java.util.HashMap, java.util.List, java.util.Map" %>
<%@ page import="java.util.Locale" %> <%-- Import Locale for String.format --%>
<%@ page session="true" %>

<%!
    // Método para cerrar recursos de BD
    private static void cerrarRecursos(ResultSet rs, PreparedStatement pstmt) {
        try {
            if (rs != null) {
                rs.close();
            }
        } catch (SQLException e) {
            /* Ignorar */ }
        try {
            if (pstmt != null) {
                pstmt.close();
            }
        } catch (SQLException e) {
            /* Ignorar */ }
    }
%>

<%
    // --- Obtener información de la sesión ---
    String email = (String) session.getAttribute("email");
    String rolUsuario = (String) session.getAttribute("rol");
    Object idProfesorObj = session.getAttribute("id_profesor");

    if (email == null || !"profesor".equalsIgnoreCase(rolUsuario) || idProfesorObj == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp"); // Adjust to your login page
        return;
    }

    int idProfesor = (Integer) idProfesorObj;

    // --- Variables para los datos del profesor (para mostrar en la cabecera/sidebar) ---
    String nombreProfesor = (String) session.getAttribute("nombre_profesor");
    if (nombreProfesor == null || nombreProfesor.isEmpty()) {
        // Re-fetch professor's name if not in session or empty
        Connection connTemp = null;
        PreparedStatement pstmtTemp = null;
        ResultSet rsTemp = null;
        try {
            connTemp = new Conection().conecta();
            String sqlGetNombre = "SELECT CONCAT(p.nombre, ' ', p.apellido_paterno, ' ', IFNULL(p.apellido_materno, '')) AS nombre_completo FROM profesores WHERE id_profesor = ?";
            pstmtTemp = connTemp.prepareStatement(sqlGetNombre);
            pstmtTemp.setInt(1, idProfesor);
            rsTemp = pstmtTemp.executeQuery();
            if (rsTemp.next()) {
                nombreProfesor = rsTemp.getString("nombre_completo");
                session.setAttribute("nombre_profesor", nombreProfesor); // Store for future use
            }
        } catch (SQLException | ClassNotFoundException ex) {
            System.err.println("Error al obtener nombre del profesor: " + ex.getMessage());
        } finally {
            cerrarRecursos(rsTemp, pstmtTemp);
            if (connTemp != null) { try { connTemp.close(); } catch (SQLException ignore) {} }
        }
    }

    String emailProfesor = email; // Email is already from session
    String facultadProfesor = "No asignada"; // Default, try to fetch it if not in session

    // Fetch facultadProfesor (if not already fetched for name)
    Connection connFacultad = null;
    PreparedStatement pstmtFacultad = null;
    ResultSet rsFacultad = null;
    try {
        connFacultad = new Conection().conecta();
        String sqlFacultad = "SELECT f.nombre_facultad as facultad FROM profesores p LEFT JOIN facultades f ON p.id_facultad = f.id_facultad WHERE p.id_profesor = ?";
        pstmtFacultad = connFacultad.prepareStatement(sqlFacultad);
        pstmtFacultad.setInt(1, idProfesor);
        rsFacultad = pstmtFacultad.executeQuery();
        if (rsFacultad.next()) {
            facultadProfesor = rsFacultad.getString("facultad") != null ? rsFacultad.getString("facultad") : "No asignada";
        }
    } catch (SQLException | ClassNotFoundException ex) {
        System.err.println("Error al obtener facultad del profesor: " + ex.getMessage());
    } finally {
        cerrarRecursos(rsFacultad, pstmtFacultad);
        if (connFacultad != null) { try { connFacultad.close(); } catch (SQLException ignore) {} }
    }


    // --- Variables para las tarjetas informativas ---
    double promedioGeneral = 0.0;
    double porcentajeAprobados = 0.0;
    double notaMaxima = 0.0;
    int estudiantesPendientes = 0;

    // --- Variables para los gráficos ---
    List<String> nombresCursosNotas = new ArrayList<>();
    List<Double> promediosNotas = new ArrayList<>();
    int totalAprobadosChart = 0;
    int totalDesaprobadosChart = 0;
    int totalPendientesChart = 0;

    // --- Lista para la tabla de detalle de calificaciones ---
    List<Map<String, String>> notasDetalleList = new ArrayList<>();

    Connection conn = null;

    try {
        Conection c = new Conection();
        conn = c.conecta();

        // --- 2. Obtener Datos para Tarjetas Informativas ---

        // Promedio General
        PreparedStatement pstmtPromedioGeneral = null;
        ResultSet rsPromedioGeneral = null;
        try {
            String sqlPromedioGeneral = "SELECT AVG(n.nota_final) AS promedio_general "
                                      + "FROM notas n "
                                      + "JOIN inscripciones i ON n.id_inscripcion = i.id_inscripcion "
                                      + "JOIN clases cl ON i.id_clase = cl.id_clase "
                                      + "WHERE cl.id_profesor = ? AND n.nota_final IS NOT NULL";
            pstmtPromedioGeneral = conn.prepareStatement(sqlPromedioGeneral);
            pstmtPromedioGeneral.setInt(1, idProfesor);
            rsPromedioGeneral = pstmtPromedioGeneral.executeQuery();
            if (rsPromedioGeneral.next()) {
                promedioGeneral = rsPromedioGeneral.getDouble("promedio_general");
                if (rsPromedioGeneral.wasNull()) promedioGeneral = 0.0; // Handle NULL case
            }
        } finally {
            cerrarRecursos(rsPromedioGeneral, pstmtPromedioGeneral);
        }

        // Porcentaje de Aprobados
        PreparedStatement pstmtPorcentajeAprobados = null;
        ResultSet rsPorcentajeAprobados = null;
        try {
            String sqlPorcentajeAprobados = "SELECT "
                                          + "(SUM(CASE WHEN n.estado = 'aprobado' THEN 1 ELSE 0 END) * 100.0 / COUNT(n.id_nota)) AS porcentaje_aprobados "
                                          + "FROM notas n "
                                          + "JOIN inscripciones i ON n.id_inscripcion = i.id_inscripcion "
                                          + "JOIN clases cl ON i.id_clase = cl.id_clase "
                                          + "WHERE cl.id_profesor = ? AND n.nota_final IS NOT NULL";
            pstmtPorcentajeAprobados = conn.prepareStatement(sqlPorcentajeAprobados);
            pstmtPorcentajeAprobados.setInt(1, idProfesor);
            rsPorcentajeAprobados = pstmtPorcentajeAprobados.executeQuery();
            if (rsPorcentajeAprobados.next()) {
                porcentajeAprobados = rsPorcentajeAprobados.getDouble("porcentaje_aprobados");
                if (rsPorcentajeAprobados.wasNull()) porcentajeAprobados = 0.0;
            }
        } finally {
            cerrarRecursos(rsPorcentajeAprobados, pstmtPorcentajeAprobados);
        }

        // Nota Más Alta
        PreparedStatement pstmtNotaMaxima = null;
        ResultSet rsNotaMaxima = null;
        try {
            String sqlNotaMaxima = "SELECT MAX(n.nota_final) AS nota_maxima "
                                 + "FROM notas n "
                                 + "JOIN inscripciones i ON n.id_inscripcion = i.id_inscripcion "
                                 + "JOIN clases cl ON i.id_clase = cl.id_clase "
                                 + "WHERE cl.id_profesor = ? AND n.nota_final IS NOT NULL";
            pstmtNotaMaxima = conn.prepareStatement(sqlNotaMaxima);
            pstmtNotaMaxima.setInt(1, idProfesor);
            rsNotaMaxima = pstmtNotaMaxima.executeQuery();
            if (rsNotaMaxima.next()) {
                notaMaxima = rsNotaMaxima.getDouble("nota_maxima");
                if (rsNotaMaxima.wasNull()) notaMaxima = 0.0;
            }
        } finally {
            cerrarRecursos(rsNotaMaxima, pstmtNotaMaxima);
        }

        // Estudiantes con Notas Pendientes (count of notes in 'pendiente' state)
        PreparedStatement pstmtEstudiantesPendientes = null;
        ResultSet rsEstudiantesPendientes = null;
        try {
            String sqlEstudiantesPendientes = "SELECT COUNT(*) AS notas_pendientes " // Count individual pending notes
                                            + "FROM notas n "
                                            + "JOIN inscripciones i ON n.id_inscripcion = i.id_inscripcion "
                                            + "JOIN clases cl ON i.id_clase = cl.id_clase "
                                            + "WHERE cl.id_profesor = ? AND n.estado = 'pendiente'";
            pstmtEstudiantesPendientes = conn.prepareStatement(sqlEstudiantesPendientes);
            pstmtEstudiantesPendientes.setInt(1, idProfesor);
            rsEstudiantesPendientes = pstmtEstudiantesPendientes.executeQuery();
            if (rsEstudiantesPendientes.next()) {
                estudiantesPendientes = rsEstudiantesPendientes.getInt("notas_pendientes");
            }
        } finally {
            cerrarRecursos(rsEstudiantesPendientes, pstmtEstudiantesPendientes);
        }

        // --- 3. Datos para Gráfico de Promedios por Curso ---
        PreparedStatement pstmtPromediosNotas = null;
        ResultSet rsPromediosNotas = null;
        try {
            String sqlPromediosNotas = "SELECT cu.nombre_curso, AVG(n.nota_final) as promedio "
                                      + "FROM notas n "
                                      + "JOIN inscripciones i ON n.id_inscripcion = i.id_inscripcion "
                                      + "JOIN clases cl ON i.id_clase = cl.id_clase "
                                      + "JOIN cursos cu ON cl.id_curso = cu.id_curso "
                                      + "WHERE cl.id_profesor = ? AND n.nota_final IS NOT NULL "
                                      + "GROUP BY cu.nombre_curso LIMIT 5"; // Limit for a readable chart
            pstmtPromediosNotas = conn.prepareStatement(sqlPromediosNotas);
            pstmtPromediosNotas.setInt(1, idProfesor);
            rsPromediosNotas = pstmtPromediosNotas.executeQuery();
            while (rsPromediosNotas.next()) {
                nombresCursosNotas.add(rsPromediosNotas.getString("nombre_curso") != null ? rsPromediosNotas.getString("nombre_curso") : "N/A");
                promediosNotas.add(rsPromediosNotas.getDouble("promedio"));
            }
        } finally {
            cerrarRecursos(rsPromediosNotas, pstmtPromediosNotas);
        }

        // --- 4. Datos para Gráfico de Estado de Estudiantes (Aprobados/Desaprobados/Pendientes) ---
        PreparedStatement pstmtEstadoEstudiantes = null;
        ResultSet rsEstadoEstudiantes = null;
        try {
            // Count all students who have a final grade, categorized by status
            String sqlEstadoEstudiantes = "SELECT n.estado, COUNT(*) as count FROM notas n "
                                        + "JOIN inscripciones i ON n.id_inscripcion = i.id_inscripcion "
                                        + "JOIN clases cl ON i.id_clase = cl.id_clase "
                                        + "WHERE cl.id_profesor = ? AND n.nota_final IS NOT NULL " // Only consider finalized notes for status
                                        + "GROUP BY n.estado";
            pstmtEstadoEstudiantes = conn.prepareStatement(sqlEstadoEstudiantes);
            pstmtEstadoEstudiantes.setInt(1, idProfesor);
            rsEstadoEstudiantes = pstmtEstadoEstudiantes.executeQuery();
            while (rsEstadoEstudiantes.next()) {
                String estado = rsEstadoEstudiantes.getString("estado");
                int count = rsEstadoEstudiantes.getInt("count");
                if ("aprobado".equalsIgnoreCase(estado)) {
                    totalAprobadosChart = count;
                } else if ("desaprobado".equalsIgnoreCase(estado)) {
                    totalDesaprobadosChart = count;
                } else if ("pendiente".equalsIgnoreCase(estado)) {
                    totalPendientesChart = count;
                }
            }
        } finally {
            cerrarRecursos(rsEstadoEstudiantes, pstmtEstadoEstudiantes);
        }

        // --- 5. Obtener Datos para la Tabla de Detalle de Calificaciones ---
        PreparedStatement pstmtNotasDetalle = null;
        ResultSet rsNotasDetalle = null;
        try {
            String sqlNotasDetalle = "SELECT a.dni, CONCAT(a.nombre, ' ', a.apellido_paterno, ' ', IFNULL(a.apellido_materno, '')) AS nombre_completo, "
                                   + "cu.nombre_curso, n.nota1, n.nota2, n.nota3, n.examen_parcial, n.examen_final, n.nota_final, n.estado "
                                   + "FROM notas n "
                                   + "JOIN inscripciones i ON n.id_inscripcion = i.id_inscripcion "
                                   + "JOIN alumnos a ON i.id_alumno = a.id_alumno "
                                   + "JOIN clases cl ON i.id_clase = cl.id_clase "
                                   + "JOIN cursos cu ON cl.id_curso = cu.id_curso "
                                   + "WHERE cl.id_profesor = ? "
                                   + "ORDER BY cu.nombre_curso, a.apellido_paterno, a.nombre";
            pstmtNotasDetalle = conn.prepareStatement(sqlNotasDetalle);
            pstmtNotasDetalle.setInt(1, idProfesor);
            rsNotasDetalle = pstmtNotasDetalle.executeQuery();
            while (rsNotasDetalle.next()) {
                Map<String, String> nota = new HashMap<>();
                nota.put("dni", rsNotasDetalle.getString("dni") != null ? rsNotasDetalle.getString("dni") : "N/A");
                nota.put("nombre_completo", rsNotasDetalle.getString("nombre_completo") != null ? rsNotasDetalle.getString("nombre_completo") : "N/A");
                nota.put("nombre_curso", rsNotasDetalle.getString("nombre_curso") != null ? rsNotasDetalle.getString("nombre_curso") : "N/A");
                // Format grades to two decimal places and handle NULLs
                nota.put("nota1", rsNotasDetalle.getBigDecimal("nota1") != null ? String.format(Locale.US, "%.2f", rsNotasDetalle.getBigDecimal("nota1")) : "N/A");
                nota.put("nota2", rsNotasDetalle.getBigDecimal("nota2") != null ? String.format(Locale.US, "%.2f", rsNotasDetalle.getBigDecimal("nota2")) : "N/A");
                nota.put("nota3", rsNotasDetalle.getBigDecimal("nota3") != null ? String.format(Locale.US, "%.2f", rsNotasDetalle.getBigDecimal("nota3")) : "N/A");
                nota.put("examen_parcial", rsNotasDetalle.getBigDecimal("examen_parcial") != null ? String.format(Locale.US, "%.2f", rsNotasDetalle.getBigDecimal("examen_parcial")) : "N/A");
                nota.put("examen_final", rsNotasDetalle.getBigDecimal("examen_final") != null ? String.format(Locale.US, "%.2f", rsNotasDetalle.getBigDecimal("examen_final")) : "N/A");
                nota.put("nota_final", rsNotasDetalle.getBigDecimal("nota_final") != null ? String.format(Locale.US, "%.2f", rsNotasDetalle.getBigDecimal("nota_final")) : "N/A");
                nota.put("estado", rsNotasDetalle.getString("estado") != null ? rsNotasDetalle.getString("estado") : "Pendiente"); // Default to "Pendiente"
                notasDetalleList.add(nota);
            }
        } finally {
            cerrarRecursos(rsNotasDetalle, pstmtNotasDetalle);
        }

    } catch (SQLException | ClassNotFoundException e) {
        e.printStackTrace();
        // Redirect to a generic error page, encoding the message
        response.sendRedirect(request.getContextPath() + "/error.jsp?message=" + java.net.URLEncoder.encode("Error interno del servidor al cargar el reporte de notas: " + e.getMessage(), "UTF-8"));
        return;
    } finally {
        try {
            if (conn != null) {
                conn.close();
            }
        } catch (SQLException e) {
            /* Ignorar */ }
    }
%>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reporte de Notas | Sistema Universitario</title>
    <link rel="icon" type="image/x-icon" href="<%= request.getContextPath() %>/img/favicon.ico"> <%-- Assuming favicon.ico exists --%>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        /* Consistent AdminKit-like CSS variables */
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

        /* Sidebar styles */
        .sidebar {
            width: 280px; background-color: var(--admin-dark); color: rgba(255,255,255,0.8); padding-top: 1rem; flex-shrink: 0;
            position: sticky; top: 0; left: 0; height: 100vh; overflow-y: auto; box-shadow: 2px 0 5px rgba(0,0,0,0.1); z-index: 1030;
        }
        .sidebar-header { padding: 1rem 1.5rem; margin-bottom: 1.5rem; text-align: center; font-size: 1.5rem; font-weight: 700; color: var(--admin-primary); border-bottom: 1px solid rgba(255,255,255,0.05);}
        .sidebar .nav-link { display: flex; align-items: center; padding: 0.75rem 1.5rem; color: rgba(255,255,255,0.7); text-decoration: none; transition: all 0.2s ease-in-out; font-weight: 500;}
        .sidebar .nav-link i { margin-right: 0.75rem; font-size: 1.1rem;}
        .sidebar .nav-link:hover, .sidebar .nav-link.active { color: white; background-color: rgba(255,255,255,0.08); border-left: 4px solid var(--admin-primary); padding-left: 1.3rem;}

        /* Main Content area */
        .main-content {
            flex: 1;
            padding: 1.5rem;
            overflow-y: auto;
            display: flex;
            flex-direction: column;
        }

        /* Top Navbar styles */
        .top-navbar {
            background-color: var(--admin-card-bg); padding: 1rem 1.5rem; box-shadow: 0 0.125rem 0.25rem rgba(0,0,0,0.075);
            margin-bottom: 1.5rem; border-radius: 0.5rem; display: flex; justify-content: space-between; align-items: center;
        }
        .top-navbar .search-bar .form-control { border: 1px solid #e0e0e0; border-radius: 0.3rem; padding: 0.5rem 1rem; }
        .top-navbar .user-dropdown .dropdown-toggle { display: flex; align-items: center; color: var(--admin-text-dark); text-decoration: none; }
        .top-navbar .user-dropdown .dropdown-toggle img { width: 32px; height: 32px; border-radius: 50%; margin-right: 0.5rem; object-fit: cover; border: 2px solid var(--admin-primary); }

        /* Welcome section */
        .welcome-section {
            background-color: var(--admin-card-bg); border-radius: 0.5rem; padding: 1.5rem; margin-bottom: 1.5rem; box-shadow: 0 0.125rem 0.25rem rgba(0,0,0,0.075);
        }
        .welcome-section h1 { color: var(--admin-text-dark); font-weight: 600; margin-bottom: 0.5rem;}
        .welcome-section p.lead { color: var(--admin-text-muted); font-size: 1rem;}

        /* General Content Card Styling */
        .content-section.card {
            border-radius: 0.5rem;
            box-shadow: 0 0.125rem 0.25rem rgba(0,0,0,0.075);
            border-left: 4px solid var(--admin-primary); /* Default border color */
            margin-bottom: 1.5rem; /* Space between cards */
        }
        .content-section.card .card-header {
             background-color: var(--admin-card-bg); /* Keep header white */
             border-bottom: 1px solid #dee2e6; /* Light separator */
             padding-bottom: 1rem;
        }

        .section-title {
            color: var(--admin-primary);
            margin-bottom: 1rem;
            font-weight: 600;
        }

        /* Stats Cards - Specific Styles */
        .stat-card {
            background-color: var(--admin-card-bg);
            border-radius: 0.5rem;
            padding: 1.5rem;
            text-align: center;
            box-shadow: 0 0.125rem 0.25rem rgba(0,0,0,0.075);
            border-bottom: 4px solid var(--admin-primary); /* Primary border color */
            transition: transform 0.3s ease-in-out;
            min-height: 150px; /* Ensure cards have similar height */
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            border-top: none; /* Remove top border if present */
            border-left: none; /* Remove left border if present */
            border-right: none; /* Remove right border if present */
        }

        .stat-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 0.5rem 1rem rgba(0,0,0,0.15); /* More pronounced shadow on hover */
        }

        .stat-card h3 {
            color: var(--admin-text-muted); /* Muted title */
            font-size: 1rem; /* Smaller title */
            margin-bottom: 0.5rem;
            font-weight: 500;
        }

        .stat-card .value {
            font-size: 2.5rem;
            font-weight: bold;
            color: var(--admin-primary); /* Primary color for value */
            margin-bottom: 0.5rem;
        }

        .stat-card .description {
            font-size: 0.85rem;
            color: var(--admin-text-muted);
        }

        .stat-card .icon-wrapper {
            font-size: 2rem; /* Larger icon */
            color: var(--admin-primary); /* Primary color for icon */
            margin-bottom: 0.75rem;
        }
        /* Specific colors for stat cards */
        .stat-card.avg-grade .value { color: var(--admin-info); }
        .stat-card.avg-grade .icon-wrapper { color: var(--admin-info); }

        .stat-card.passed-percentage .value { color: var(--admin-success); }
        .stat-card.passed-percentage .icon-wrapper { color: var(--admin-success); }

        .stat-card.max-grade .value { color: var(--admin-warning); }
        .stat-card.max-grade .icon-wrapper { color: var(--admin-warning); }

        .stat-card.pending-students .value { color: var(--admin-danger); }
        .stat-card.pending-students .icon-wrapper { color: var(--admin-danger); }


        /* Charts - Ajustes para visualización */
        .chart-container {
            position: relative;
            height: 350px; /* Fixed height for consistency */
            width: 100%;
            margin: auto;
            display: flex;
            justify-content: center;
            align-items: center;
        }
        .chart-container canvas {
            max-width: 100%;
            max-height: 100%;
        }

        /* Tables */
        .table-responsive {
            margin-top: 1rem;
            max-height: 600px; /* Max height for scrollable table */
            overflow-y: auto; /* Enable vertical scrolling */
        }

        .table-detail {
            width: 100%;
            margin-bottom: 0; /* Remove default table margin-bottom */
            color: var(--admin-text-dark);
            border-collapse: collapse; /* Ensure standard collapse */
        }

        .table-detail th, .table-detail td {
            padding: 0.75rem;
            vertical-align: middle;
            border-top: 1px solid #dee2e6;
        }

        .table-detail thead th {
            vertical-align: bottom;
            border-bottom: 2px solid var(--admin-primary);
            color: var(--admin-primary);
            font-weight: 600;
            background-color: var(--admin-light-bg); /* Light background for header */
            position: sticky; /* Make header sticky */
            top: 0; /* Stick to the top of its scrolling container */
            z-index: 1; /* Ensure it stays above table body */
        }

        .table-detail tbody tr:hover {
            background-color: rgba(0, 123, 255, 0.05); /* Light blue hover */
        }
        .table-detail tbody tr:nth-of-type(even) { /* Stripe effect */
            background-color: rgba(0,0,0,.02);
        }

        /* Badge for status in table */
        .badge.bg-success { background-color: var(--admin-success) !important; }
        .badge.bg-danger { background-color: var(--admin-danger) !important; }
        .badge.bg-secondary { background-color: var(--admin-secondary-color) !important; }

        /* No data message for tables/lists */
        .no-data-message {
            text-align: center;
            padding: 2rem;
            color: var(--admin-text-muted);
            font-style: italic;
            font-size: 1.1rem;
        }
        .no-data-message i {
            font-size: 2.5rem;
            margin-bottom: 1rem;
            display: block;
            color: var(--admin-secondary-color);
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

            .welcome-section, .content-section.card { padding: 1.5rem 1rem; }
            .stat-card { min-height: 120px; padding: 1rem; }
            .stat-card h3 { font-size: 0.9rem; }
            .stat-card .value { font-size: 2rem; }
            .stat-card .icon-wrapper { font-size: 1.5rem; margin-bottom: 0.5rem; }

            .chart-container { height: 300px; } /* Adjust height for smaller screens */

            .table-detail { font-size: 0.85rem; }
            .table-detail th, .table-detail td { padding: 0.6rem; }
        }
        @media (max-width: 576px) {
            .main-content { padding: 0.75rem; }
            .welcome-section, .content-section.card { padding: 1rem;}
        }
    </style>
</head>
<body>
    <div id="app">
        <nav class="sidebar">
            <div class="sidebar-header">
                <a href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/home_profesor.jsp" class="text-white text-decoration-none">UGIC Portal</a>
            </div>
            <ul class="navbar-nav">
                <li class="nav-item"><a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/home_profesor.jsp"><i class="fas fa-chart-line"></i><span> Dashboard</span></a></li>
                <li class="nav-item"><a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/facultad_profesor.jsp"><i class="fas fa-building"></i><span> Facultades</span></a></li>
                <li class="nav-item"><a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/carreras_profesor.jsp"><i class="fas fa-graduation-cap"></i><span> Carreras</span></a></li>
                <li class="nav-item"><a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/cursos_profesor.jsp"><i class="fas fa-book"></i><span> Cursos</span></a></li>
                <li class="nav-item"><a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/salones_profesor.jsp"><i class="fas fa-chalkboard"></i><span> Clases</span></a></li>
                <li class="nav-item"><a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/horarios_profesor.jsp"><i class="fas fa-calendar-alt"></i><span> Horarios</span></a></li>
                <li class="nav-item"><a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/asistencia_profesor.jsp"><i class="fas fa-clipboard-check"></i><span> Asistencia</span></a></li>
                <li class="nav-item"><a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/mensaje_profesor.jsp"><i class="fas fa-envelope"></i><span> Mensajería</span></a></li>
                <li class="nav-item"><a class="nav-link active" href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/reporte_notas.jsp"><i class="fas fa-clipboard-check"></i><span> Reporte de Notas</span></a></li> <%-- ENLACE A ESTA PÁGINA --%>
            </ul>
            <li class="nav-item mt-3">
                <form action="<%= request.getContextPath() %>/logout.jsp" method="post" class="d-grid gap-2">
                    <button type="submit" class="btn btn-outline-light mx-3"><i class="fas fa-sign-out-alt me-2"></i>Cerrar sesión</button>
                </form>
            </li>
        </nav>

        <div class="main-content">
            <nav class="top-navbar">
                <div class="search-bar">
                    <form class="d-flex">
                        <input class="form-control me-2" type="search" placeholder="Buscar..." aria-label="Search">
                        <button class="btn btn-outline-secondary" type="submit"><i class="fas fa-search"></i></button>
                    </form>
                </div>
                <div class="d-flex align-items-center">
                    <div class="me-3 dropdown">
                        <a class="text-dark" href="#" role="button" id="notificationsDropdown" data-bs-toggle="dropdown" aria-expanded="false">
                            <i class="fas fa-bell fa-lg"></i>
                            <span class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger">
                                3
                            </span>
                        </a>
                        <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="notificationsDropdown">
                            <li><a class="dropdown-item" href="#">Nueva nota pendiente</a></li>
                            <li><a class="dropdown-item" href="#">Recordatorio de clase</a></li>
                            <li><hr class="dropdown-divider"></li>
                            <li><a class="dropdown-item" href="#">Ver todas</a></li>
                        </ul>
                    </div>
                    <div class="me-3 dropdown">
                        <a class="text-dark" href="#" role="button" id="messagesDropdown" data-bs-toggle="dropdown" aria-expanded="false">
                            <i class="fas fa-envelope fa-lg"></i>
                            <span class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger">
                                2
                            </span>
                        </a>
                        <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="messagesDropdown">
                            <li><a class="dropdown-item" href="#">Mensaje de Alumno X</a></li>
                            <li><a class="dropdown-item" href="#">Mensaje de Coordinación</a></li>
                            <li><hr class="dropdown-divider"></li>
                            <li><a class="dropdown-item" href="#">Ver todos</a></li>
                        </ul>
                    </div>

                    <div class="dropdown user-dropdown">
                        <a class="dropdown-toggle" href="#" role="button" id="userDropdown" data-bs-toggle="dropdown" aria-expanded="false">
                            <img src="https://via.placeholder.com/32" alt="Avatar"> <span class="d-none d-md-inline-block"><%= nombreProfesor != null ? nombreProfesor : "Profesor" %></span>
                        </a>
                        <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="userDropdown">
                            <li><a class="dropdown-item" href="#"><i class="fas fa-user me-2"></i>Perfil</a></li>
                            <li><a class="dropdown-item" href="#"><i class="fas fa-cog me-2"></i>Configuración</a></li>
                            <li><hr class="dropdown-divider"></li>
                            <li><a class="dropdown-item" href="<%= request.getContextPath() %>/logout.jsp"><i class="fas fa-sign-out-alt me-2"></i>Cerrar sesión</a></li>
                        </ul>
                    </div>
                </div>
            </nav>

            <div class="container-fluid">
                <div class="welcome-section">
                    <h1 class="h3 mb-3"><i class="fas fa-chart-line me-2"></i>Reporte de Notas</h1>
                    <p class="lead">Gestione y visualice las calificaciones y el rendimiento académico de sus estudiantes.</p>
                </div>

                <%-- Top Stat Cards --%>
                <div class="row mb-4">
                    <div class="col-md-3 col-sm-6 mb-3">
                        <div class="stat-card avg-grade">
                            <div class="icon-wrapper"><i class="fas fa-calculator"></i></div>
                            <h3>Promedio General</h3>
                            <div class="value"><%= String.format(Locale.US, "%.2f", promedioGeneral) %></div>
                            <div class="description">Nota promedio de todos sus cursos</div>
                        </div>
                    </div>
                    <div class="col-md-3 col-sm-6 mb-3">
                        <div class="stat-card passed-percentage">
                            <div class="icon-wrapper"><i class="fas fa-percent"></i></div>
                            <h3>% Aprobados</h3>
                            <div class="value"><%= String.format(Locale.US, "%.0f%%", porcentajeAprobados) %></div>
                            <div class="description">Estudiantes con calificación aprobatoria</div>
                        </div>
                    </div>
                    <div class="col-md-3 col-sm-6 mb-3">
                        <div class="stat-card max-grade">
                            <div class="icon-wrapper"><i class="fas fa-star"></i></div>
                            <h3>Nota Más Alta</h3>
                            <div class="value"><%= String.format(Locale.US, "%.2f", notaMaxima) %></div>
                            <div class="description">La calificación individual más alta registrada</div>
                        </div>
                    </div>
                    <div class="col-md-3 col-sm-6 mb-3">
                        <div class="stat-card pending-students">
                            <div class="icon-wrapper"><i class="fas fa-exclamation-triangle"></i></div>
                            <h3>Notas Pendientes</h3>
                            <div class="value"><%= estudiantesPendientes %></div>
                            <div class="description">Calificaciones aún por registrar</div>
                        </div>
                    </div>
                </div>

                <%-- Charts Section --%>
                <div class="row mb-4">
                    <div class="col-md-6 mb-3">
                        <div class="card content-section">
                            <div class="card-body">
                                <h3 class="section-title"><i class="fas fa-chart-bar me-2"></i>Promedio de Notas por Curso</h3>
                                <div class="chart-container">
                                    <canvas id="notasChart"></canvas>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-6 mb-3">
                        <div class="card content-section">
                            <div class="card-body">
                                <h3 class="section-title"><i class="fas fa-chart-pie me-2"></i>Estado de Estudiantes por Notas</h3>
                                <div class="chart-container">
                                    <canvas id="estadoEstudiantesChart"></canvas>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <%-- Detail Grades Table --%>
                <div class="card content-section mb-4">
                    <div class="card-body">
                        <h3 class="section-title"><i class="fas fa-table me-2"></i>Detalle de Calificaciones</h3>
                        <div class="table-responsive">
                            <% if (!notasDetalleList.isEmpty()) { %>
                            <table class="table table-hover table-striped table-detail caption-top">
                                <caption>Lista detallada de todas las calificaciones de sus alumnos.</caption>
                                <thead>
                                    <tr>
                                        <th>DNI</th>
                                        <th>Estudiante</th>
                                        <th>Curso</th>
                                        <th>Nota 1</th>
                                        <th>Nota 2</th>
                                        <th>Nota 3</th>
                                        <th>Examen Parcial</th>
                                        <th>Examen Final</th>
                                        <th>Nota Final</th>
                                        <th>Estado</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <% for (Map<String, String> nota : notasDetalleList) { %>
                                    <tr>
                                        <td><%= nota.get("dni") %></td>
                                        <td><%= nota.get("nombre_completo") %></td>
                                        <td><%= nota.get("nombre_curso") %></td>
                                        <td><%= nota.get("nota1") %></td>
                                        <td><%= nota.get("nota2") %></td>
                                        <td><%= nota.get("nota3") %></td>
                                        <td><%= nota.get("examen_parcial") %></td>
                                        <td><%= nota.get("examen_final") %></td>
                                        <td><%= nota.get("nota_final") %></td>
                                        <td>
                                            <span class="badge
                                                <% if ("aprobado".equals(nota.get("estado"))) { %> bg-success
                                                <% } else if ("desaprobado".equals(nota.get("estado"))) { %> bg-danger
                                                <% } else { %> bg-secondary <% } %>">
                                                <%= nota.get("estado") %>
                                            </span>
                                        </td>
                                    </tr>
                                    <% } %>
                                </tbody>
                            </table>
                            <% } else { %>
                            <p class="no-data-message">
                                <i class="fas fa-info-circle"></i>
                                No hay calificaciones detalladas disponibles para sus cursos.
                            </p>
                            <% } %>
                        </div>
                    </div>
                </div>

            </div> <%-- End of container-fluid --%>
        </div> <%-- End of main-content --%>
    </div> <%-- End of app --%>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js" integrity="sha384-YvpcrYf0tY3lHB60NNkmXc5s9fDVZLESaAA55NDzOxhy9GkcIdslK1eN7N6jIeHz" crossorigin="anonymous"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script>
        // --- Gráfico de Notas Promedio por Curso ---
        const nombresCursosNotas = [
        <%
            for (int i = 0; i < nombresCursosNotas.size(); i++) {
                out.print("'" + nombresCursosNotas.get(i).replace("'", "\\'") + "'"); // Escape single quotes
                if (i < nombresCursosNotas.size() - 1) {
                    out.print(", ");
                }
            }
        %>
        ];
        const promediosNotas = [
        <%
            for (int i = 0; i < promediosNotas.size(); i++) {
                out.print(promediosNotas.get(i));
                if (i < promediosNotas.size() - 1) {
                    out.print(", ");
                }
            }
        %>
        ];

        const ctxNotas = document.getElementById('notasChart');
        if (ctxNotas) {
            new Chart(ctxNotas.getContext('2d'), {
                type: 'bar',
                data: {
                    labels: nombresCursosNotas,
                    datasets: [{
                        label: 'Promedio de Notas',
                        data: promediosNotas,
                        backgroundColor: 'rgba(0, 123, 255, 0.7)', /* admin-primary with opacity */
                        borderColor: 'rgba(0, 123, 255, 1)', /* solid admin-primary */
                        borderWidth: 1,
                        borderRadius: 5, /* Rounded bars for modern look */
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    scales: {
                        y: {
                            beginAtZero: true,
                            max: 20, /* Max grade is 20 */
                            title: {
                                display: true,
                                text: 'Nota Promedio',
                                color: 'var(--admin-text-dark)',
                                font: { weight: 'bold' }
                            },
                            grid: { color: '#e9ecef' }, /* Lighter grid lines */
                            ticks: { color: 'var(--admin-text-muted)' }
                        },
                        x: {
                            title: {
                                display: true,
                                text: 'Curso',
                                color: 'var(--admin-text-dark)',
                                font: { weight: 'bold' }
                            },
                            grid: { display: false }, /* No vertical grid lines */
                            ticks: { color: 'var(--admin-text-muted)' }
                        }
                    },
                    plugins: {
                        title: {
                            display: false, /* Title is in h3 above chart */
                        },
                        legend: {
                            display: false, /* Hide dataset label */
                        },
                        tooltip: { /* Custom tooltip style */
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

        // --- Gráfico de Estado de Estudiantes (Aprobados/Desaprobados/Pendientes) ---
        const totalAprobadosChart = <%= totalAprobadosChart %>;
        const totalDesaprobadosChart = <%= totalDesaprobadosChart %>;
        const totalPendientesChart = <%= totalPendientesChart %>;

        const ctxEstadoEstudiantes = document.getElementById('estadoEstudiantesChart');
        if (ctxEstadoEstudiantes) {
            new Chart(ctxEstadoEstudiantes.getContext('2d'), {
                type: 'pie', /* Pie chart is better for showing parts of a whole */
                data: {
                    labels: ['Aprobados', 'Desaprobados', 'Pendientes'],
                    datasets: [{
                        data: [totalAprobadosChart, totalDesaprobadosChart, totalPendientesChart],
                        backgroundColor: [
                            'rgba(40, 167, 69, 0.7)',  /* admin-success */
                            'rgba(220, 53, 69, 0.7)',  /* admin-danger */
                            'rgba(255, 193, 7, 0.7)'   /* admin-warning */
                        ],
                        borderColor: [
                            'rgba(40, 167, 69, 1)',
                            'rgba(220, 53, 69, 1)',
                            'rgba(255, 193, 7, 1)'
                        ],
                        borderWidth: 1
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        title: {
                            display: false, /* Title is in h3 above chart */
                        },
                        legend: {
                            position: 'bottom', /* Legend below the chart */
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
                            cornerRadius: 5
                        }
                    }
                }
            });
        }
    </script>
</body>
</html>