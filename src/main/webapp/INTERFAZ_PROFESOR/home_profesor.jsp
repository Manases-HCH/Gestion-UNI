<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, pe.universidad.util.Conection" %>
<%@ page import="java.time.LocalDateTime, java.time.format.DateTimeFormatter" %>
<%@ page import="java.util.ArrayList, java.util.HashMap, java.util.List, java.util.Map" %>
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
    if (email == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    // --- Variables para los datos del profesor ---
    String nombreCompleto = "Usuario";
    String dni = "No disponible";
    String facultad = "Facultad no especificada";
    String telefono = "No registrado";
    String ultimoAcceso = "Ahora";

    int totalCursos = 0;
    int cursosActivos = 0;
    int totalAlumnos = 0;

    // --- Listas para las tablas ---
    List<Map<String, String>> cursosList = new ArrayList<>();
    List<Map<String, String>> alumnosList = new ArrayList<>();

    // --- Datos para gráficos ---
    List<String> nombresCursosNotas = new ArrayList<>();
    List<Double> promediosNotas = new ArrayList<>();
    int totalPresentes = 0;
    int totalAusentes = 0;
    int totalTardanzas = 0;

    Connection conn = null;

    try {
        Conection c = new Conection();
        conn = c.conecta();

        // --- 1. Obtener Datos Principales del Profesor ---
        PreparedStatement pstmtProfesor = null;
        ResultSet rsProfesor = null;
        int idProfesor = 0;
        try {
            String sqlProfesor = "SELECT p.id_profesor, p.dni, p.nombre, p.apellido_paterno, "
                    + "p.apellido_materno, p.telefono, f.nombre_facultad "
                    + "FROM profesores p "
                    + "JOIN facultades f ON p.id_facultad = f.id_facultad "
                    + "WHERE p.email = ?";
            pstmtProfesor = conn.prepareStatement(sqlProfesor);
            pstmtProfesor.setString(1, email.trim());
            rsProfesor = pstmtProfesor.executeQuery();

            if (rsProfesor.next()) {
                idProfesor = rsProfesor.getInt("id_profesor");
                String nombre = rsProfesor.getString("nombre") != null ? rsProfesor.getString("nombre") : "";
                String apPaterno = rsProfesor.getString("apellido_paterno") != null ? rsProfesor.getString("apellido_paterno") : "";
                String apMaterno = rsProfesor.getString("apellido_materno") != null ? rsProfesor.getString("apellido_materno") : "";

                nombreCompleto = nombre + " " + apPaterno;
                if (!apMaterno.isEmpty()) {
                    nombreCompleto += " " + apMaterno;
                }

                dni = rsProfesor.getString("dni") != null ? rsProfesor.getString("dni") : "No disponible";
                telefono = rsProfesor.getString("telefono") != null ? rsProfesor.getString("telefono") : "No registrado";
                facultad = rsProfesor.getString("nombre_facultad") != null ? rsProfesor.getString("nombre_facultad") : "Facultad no especificada";

            } else {
                response.sendRedirect("login.jsp?error=profesor_no_encontrado");
                return;
            }
        } finally {
            cerrarRecursos(rsProfesor, pstmtProfesor);
        }

        // --- 2. Obtener Estadísticas y Listas (Solo si el profesor se encontró) ---
        if (idProfesor > 0) {
            // Total Cursos Asignados
            PreparedStatement pstmtTotalCursos = null;
            ResultSet rsTotalCursos = null;
            try {
                String sqlCountCursos = "SELECT COUNT(*) AS total FROM profesor_curso WHERE id_profesor = ?";
                pstmtTotalCursos = conn.prepareStatement(sqlCountCursos);
                pstmtTotalCursos.setInt(1, idProfesor);
                rsTotalCursos = pstmtTotalCursos.executeQuery();
                if (rsTotalCursos.next()) {
                    totalCursos = rsTotalCursos.getInt("total");
                }
            } finally {
                cerrarRecursos(rsTotalCursos, pstmtTotalCursos);
            }

            // Cursos Activos
            PreparedStatement pstmtCursosActivos = null;
            ResultSet rsCursosActivos = null;
            try {
                String sqlCursosActivos = "SELECT COUNT(*) AS total FROM profesor_curso WHERE id_profesor = ? AND estado = 'activo'";
                pstmtCursosActivos = conn.prepareStatement(sqlCursosActivos);
                pstmtCursosActivos.setInt(1, idProfesor);
                rsCursosActivos = pstmtCursosActivos.executeQuery();
                if (rsCursosActivos.next()) {
                    cursosActivos = rsCursosActivos.getInt("total");
                }
            } finally {
                cerrarRecursos(rsCursosActivos, pstmtCursosActivos);
            }

            // Total Alumnos
            PreparedStatement pstmtTotalAlumnos = null;
            ResultSet rsTotalAlumnos = null;
            try {
                String sqlTotalAlumnos = "SELECT COUNT(DISTINCT i.id_alumno) AS total "
                        + "FROM inscripciones i "
                        + "JOIN clases cl ON i.id_clase = cl.id_clase "
                        + "JOIN cursos cu ON cl.id_curso = cu.id_curso "
                        + "WHERE cl.id_profesor = ? AND i.estado = 'inscrito'";
                pstmtTotalAlumnos = conn.prepareStatement(sqlTotalAlumnos);
                pstmtTotalAlumnos.setInt(1, idProfesor);
                rsTotalAlumnos = pstmtTotalAlumnos.executeQuery();
                if (rsTotalAlumnos.next()) {
                    totalAlumnos = rsTotalAlumnos.getInt("total");
                }
            } finally {
                cerrarRecursos(rsTotalAlumnos, pstmtTotalAlumnos);
            }

            // Lista de Mis Cursos (excluding the 'alumnos' count as it's removed from display)
            PreparedStatement pstmtCursosList = null;
            ResultSet rsCursosList = null;
            try {
                String sqlCursosList = "SELECT c.id_curso, c.nombre_curso, c.codigo_curso, c.creditos "
                        + "FROM cursos c "
                        + "JOIN profesor_curso pc ON c.id_curso = pc.id_curso "
                        + "WHERE pc.id_profesor = ? ORDER BY c.nombre_curso";
                pstmtCursosList = conn.prepareStatement(sqlCursosList);
                pstmtCursosList.setInt(1, idProfesor);
                rsCursosList = pstmtCursosList.executeQuery();
                while (rsCursosList.next()) {
                    Map<String, String> curso = new HashMap<>();
                    curso.put("id_curso", String.valueOf(rsCursosList.getInt("id_curso")));
                    curso.put("codigo_curso", rsCursosList.getString("codigo_curso") != null ? rsCursosList.getString("codigo_curso") : "");
                    curso.put("nombre_curso", rsCursosList.getString("nombre_curso") != null ? rsCursosList.getString("nombre_curso") : "");
                    curso.put("creditos", String.valueOf(rsCursosList.getInt("creditos")));
                    // Removed fetching of 'alumnos' as it's no longer displayed.
                    cursosList.add(curso);
                }
            } finally {
                cerrarRecursos(rsCursosList, pstmtCursosList);
            }

            // Lista de Alumnos Recientes
            PreparedStatement pstmtAlumnosList = null;
            ResultSet rsAlumnosList = null;
            try {
                String sqlAlumnosList = "SELECT a.id_alumno, a.nombre, a.apellido_paterno, a.apellido_materno, cu.nombre_curso "
                        + "FROM alumnos a "
                        + "JOIN inscripciones i ON a.id_alumno = i.id_alumno "
                        + "JOIN clases cl ON i.id_clase = cl.id_clase "
                        + "JOIN cursos cu ON cl.id_curso = cu.id_curso "
                        + "WHERE cl.id_profesor = ? AND i.estado = 'inscrito' "
                        + "ORDER BY i.fecha_inscripcion DESC LIMIT 5";
                pstmtAlumnosList = conn.prepareStatement(sqlAlumnosList);
                pstmtAlumnosList.setInt(1, idProfesor);
                rsAlumnosList = pstmtAlumnosList.executeQuery();
                while (rsAlumnosList.next()) {
                    Map<String, String> alumno = new HashMap<>();
                    alumno.put("id_alumno", String.valueOf(rsAlumnosList.getInt("id_alumno")));
                    String alNombre = rsAlumnosList.getString("nombre") != null ? rsAlumnosList.getString("nombre") : "";
                    String alApPaterno = rsAlumnosList.getString("apellido_paterno") != null ? rsAlumnosList.getString("apellido_paterno") : "";
                    String alApMaterno = rsAlumnosList.getString("apellido_materno") != null ? rsAlumnosList.getString("apellido_materno") : "";
                    String alNombreCompleto = alNombre + " " + alApPaterno;
                    if (!alApMaterno.isEmpty()) {
                        alNombreCompleto += " " + alApMaterno;
                    }
                    alumno.put("nombre_completo", alNombreCompleto);
                    alumno.put("nombre_curso", rsAlumnosList.getString("nombre_curso") != null ? rsAlumnosList.getString("nombre_curso") : "");
                    alumnosList.add(alumno);
                }
            } finally {
                cerrarRecursos(rsAlumnosList, pstmtAlumnosList);
            }

            // --- Lógica para datos de gráficos ---
            // Para Notas: Obtener promedios de notas por curso
            PreparedStatement pstmtPromediosNotas = null;
            ResultSet rsPromediosNotas = null;
            try {
                String sqlPromediosNotas = "SELECT cu.nombre_curso, AVG(n.nota_final) as promedio "
                        + "FROM notas n "
                        + "JOIN inscripciones i ON n.id_inscripcion = i.id_inscripcion "
                        + "JOIN clases cl ON i.id_clase = cl.id_clase "
                        + "JOIN cursos cu ON cl.id_curso = cu.id_curso "
                        + "WHERE cl.id_profesor = ? AND n.nota_final IS NOT NULL "
                        + "GROUP BY cu.nombre_curso LIMIT 5"; // Limiting to 5 for better chart readability
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

            // Para Asistencia: Contar presentes, ausentes, tardanzas
            PreparedStatement pstmtAsistencia = null;
            ResultSet rsAsistencia = null;
            try {
                String sqlAsistencia = "SELECT a.estado, COUNT(*) as count FROM asistencia a "
                        + "JOIN inscripciones i ON a.id_inscripcion = i.id_inscripcion "
                        + "JOIN clases cl ON i.id_clase = cl.id_clase "
                        + "WHERE cl.id_profesor = ? "
                        + "GROUP BY a.estado";
                pstmtAsistencia = conn.prepareStatement(sqlAsistencia);
                pstmtAsistencia.setInt(1, idProfesor);
                rsAsistencia = pstmtAsistencia.executeQuery();
                while (rsAsistencia.next()) {
                    String estadoAsistencia = rsAsistencia.getString("estado");
                    int count = rsAsistencia.getInt("count");
                    if ("presente".equalsIgnoreCase(estadoAsistencia)) {
                        totalPresentes = count;
                    } else if ("ausente".equalsIgnoreCase(estadoAsistencia)) {
                        totalAusentes = count;
                    } else if ("tardanza".equalsIgnoreCase(estadoAsistencia)) {
                        totalTardanzas = count;
                    }
                }
            } finally {
                cerrarRecursos(rsAsistencia, pstmtAsistencia);
            }
        }

        // --- Obtener la fecha actual para "Último acceso" ---
        ultimoAcceso = LocalDateTime.now().format(DateTimeFormatter.ofPattern("EEEE, d 'de' MMMM 'de' yyyy"));

    } catch (SQLException | ClassNotFoundException e) {
        e.printStackTrace();
        response.sendRedirect("error.jsp?message=Error_interno_del_servidor");
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
        <title>Dashboard Profesor | Sistema Universitario</title>
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous">
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">

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
                font-family: 'Inter', sans-serif; /* Usamos Inter si está disponible */
                background-color: var(--admin-light-bg);
                color: var(--admin-text-dark);
                min-height: 100vh;
                display: flex;
                flex-direction: column;
                overflow-x: hidden; /* Evita el scroll horizontal en caso de desbordamiento */
            }

            /* Contenedor principal de la aplicación */
            #app {
                display: flex;
                flex: 1;
                width: 100%;
            }

            /* Sidebar */
            .sidebar {
                width: 280px; /* Ancho fijo para el sidebar */
                background-color: var(--admin-dark);
                color: rgba(255, 255, 255, 0.8);
                padding-top: 1rem;
                flex-shrink: 0;
                position: sticky; /* Sticky sidebar */
                top: 0;
                left: 0;
                height: 100vh; /* Ocupa toda la altura de la ventana */
                overflow-y: auto; /* Permite desplazamiento si hay muchos elementos */
                box-shadow: 2px 0 5px rgba(0,0,0,0.1);
                z-index: 1030; /* Por debajo de la navbar principal de Bootstrap */
            }

            .sidebar-header {
                padding: 1rem 1.5rem;
                margin-bottom: 1.5rem;
                text-align: center;
                font-size: 1.5rem;
                font-weight: 700;
                color: var(--admin-primary); /* Similar al logo de AdminKit */
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

            .sidebar .nav-link:hover,
            .sidebar .nav-link.active {
                color: white;
                background-color: rgba(255, 255, 255, 0.08);
                border-left: 4px solid var(--admin-primary); /* Indicador de activo */
                padding-left: 1.3rem; /* Ajuste para compensar el borde */
            }

            .sidebar .nav-link i {
                margin-right: 0.75rem;
                font-size: 1.1rem;
            }

            /* Contenido principal */
            .main-content {
                flex: 1;
                padding: 1.5rem; /* Menos padding general para un look más compacto */
                overflow-y: auto;
                display: flex;
                flex-direction: column;
            }

            /* Navbar superior */
            .top-navbar {
                background-color: var(--admin-card-bg); /* Fondo blanco */
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

            /* Sección de Bienvenida */
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

            /* Stats Cards - Reuso de la clase card de Bootstrap */
            .stat-card .card-body {
                padding: 1.25rem;
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
                color: var(--admin-text-dark); /* Color oscuro principal */
                margin-bottom: 0.25rem;
            }
            .stat-card .description {
                font-size: 0.85rem;
                color: var(--admin-text-muted);
            }
            .stat-card .icon-wrapper {
                background-color: var(--admin-primary);
                color: white;
                padding: 0.75rem;
                border-radius: 0.5rem;
                font-size: 1.5rem;
                display: inline-flex;
                align-items: center;
                justify-content: center;
                margin-bottom: 1rem;
                width: 50px;
                height: 50px;
            }
            /* Colores específicos para stats cards (similar a AdminKit) */
            .stat-card.sales .icon-wrapper {
                background-color: var(--admin-info);
            }
            .stat-card.earnings .icon-wrapper {
                background-color: var(--admin-success);
            }
            .stat-card.students .icon-wrapper {
                background-color: var(--admin-warning);
            }


            /* Información del Profesor */
            .profesor-info.card {
                border-left: 4px solid var(--admin-primary);
                /* Modificación: Hacer que la tarjeta de información ocupe todo el ancho disponible */
                width: 100%; /* Asegura que ocupe todo el ancho del contenedor */
            }
            .profesor-info .section-title {
                color: var(--admin-primary);
            }
            .profesor-info p strong {
                color: var(--admin-text-dark);
            }

            /* Secciones de Contenido General (tablas, gráficos) */
            .content-section.card {
                border-left: 4px solid var(--admin-primary); /* Bordes de color para secciones principales */
                box-shadow: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.075);
            }
            .content-section .section-title {
                color: var(--admin-primary);
                margin-bottom: 1rem;
                font-weight: 600;
            }

            /* Tablas */
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
                background-color: rgba(0, 123, 255, 0.05); /* Ligeramente azul al pasar el mouse */
            }

            /* Gráficos */
            .chart-container {
                height: 330px; /* Ajuste de altura */
                padding: 1rem;
            }

            /* Acciones Rápidas */
            .quick-actions {
                display: grid;
                /* Modificación: Aumentar el tamaño de las tarjetas de acción y distribuir mejor */
                grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); /* Ajuste el minmax para que sean más grandes */
                gap: 1.5rem;
                margin-top: 1.5rem;
            }

            .action-card {
                background-color: var(--admin-card-bg);
                border-radius: 0.5rem;
                padding: 1.5rem;
                text-align: center;
                box-shadow: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.075);
                transition: transform 0.2s ease, box-shadow 0.2s ease;
                border-bottom: 4px solid var(--admin-accent); /* Un color secundario para las acciones */
            }

            .action-card:hover {
                transform: translateY(-3px);
                box-shadow: 0 0.25rem 0.5rem rgba(0,0,0,0.1);
            }

            .action-card i {
                /* Modificación: Aumentar el tamaño del ícono */
                font-size: 3.5rem; /* Ajuste del tamaño del ícono */
                color: var(--admin-primary);
                margin-bottom: 1rem;
            }

            .action-card h4 {
                color: var(--admin-primary);
                margin-bottom: 0.5rem;
                font-weight: 600;
            }

            .action-card p {
                font-size: 0.9rem;
                color: var(--admin-text-muted);
                margin-bottom: 1.5rem;
            }

            .action-btn {
                display: inline-block;
                background-color: var(--admin-primary);
                color: white;
                padding: 0.6rem 1.2rem;
                border-radius: 0.3rem; /* Menos redondeado */
                text-decoration: none;
                font-weight: 500;
                transition: background-color 0.2s ease;
            }

            .action-btn:hover {
                background-color: #0056b3; /* Un tono más oscuro del azul primario */
                color: white;
            }

            /* Styles for the new Calendar Widget */
            .calendar-widget {
                padding: 1rem;
                font-size: 0.9rem;
                max-width: 400px; /* Limit calendar width for better appearance */
                margin: auto; /* Center the calendar within its card */
            }
            .calendar-grid {
                display: grid;
                grid-template-columns: repeat(7, 1fr);
                gap: 5px;
            }
            .calendar-grid .day-name {
                font-weight: bold;
                color: var(--admin-primary);
                padding-bottom: 5px;
            }
            .calendar-grid .day {
                padding: 8px;
                border-radius: 5px;
                background-color: #f8f9fa;
                border: 1px solid #e9ecef;
                cursor: pointer;
                transition: background-color 0.2s ease;
            }
            .calendar-grid .day:hover {
                background-color: var(--admin-light-bg);
            }
            .calendar-grid .day.current {
                background-color: var(--admin-primary);
                color: white;
                font-weight: bold;
            }
            .calendar-grid .day.old {
                color: var(--admin-text-muted);
                background-color: #e9ecef;
            }

            /* Media Queries para responsividad */
            @media (max-width: 992px) { /* Laptops y tablets */
                .sidebar {
                    width: 220px;
                }
                .main-content {
                    padding: 1rem;
                }
                /* Mi Información ya es col-12, no necesita cambio aquí */
            }

            @media (max-width: 768px) { /* Tablets y móviles */
                #app {
                    flex-direction: column;
                }
                .sidebar {
                    width: 100%;
                    height: auto; /* Altura automática en móvil */
                    position: relative; /* Deja de ser sticky */
                    box-shadow: 0 2px 5px rgba(0,0,0,0.1);
                    padding-bottom: 0.5rem;
                }
                .sidebar .nav-link {
                    justify-content: center; /* Centra los elementos del menú en móvil */
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
            }

            @media (max-width: 576px) { /* Móviles pequeños */
                .main-content {
                    padding: 0.75rem;
                }
                .welcome-section, .card {
                    padding: 1rem;
                }
                .stat-card .value {
                    font-size: 1.8rem;
                }
                .action-card i {
                    font-size: 2.5rem;
                }
                .action-btn {
                    padding: 0.5rem 1rem;
                }
                /* Ajuste de columnas para acciones rápidas en pantallas muy pequeñas */
                .quick-actions {
                    grid-template-columns: 1fr; /* Una columna en pantallas muy pequeñas */
                }
                .calendar-widget {
                    padding: 0.5rem;
                    font-size: 0.8rem;
                }
                .calendar-grid .day {
                    padding: 6px;
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
                        <a class="nav-link active" href="home_profesor.jsp"><i class="fas fa-chart-line"></i><span> Dashboard</span></a>
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
                                <img src="https://via.placeholder.com/32" alt="Avatar"> <span class="d-none d-md-inline-block"><%= nombreCompleto%></span>
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
                        <h1 class="h3 mb-3">Dashboard del Profesor</h1>
                        <p class="lead">Bienvenido, <%= nombreCompleto%>. Este es su panel de control para gestionar sus actividades académicas.</p>
                    </div>

                    <div class="row">
                        <div class="col-md-4 col-sm-6 mb-4">
                            <div class="card stat-card sales">
                                <div class="card-body">
                                    <div class="row align-items-center">
                                        <div class="col-auto">
                                            <div class="icon-wrapper bg-info text-white">
                                                <i class="fas fa-book"></i>
                                            </div>
                                        </div>
                                        <div class="col">
                                            <h3 class="card-title">Cursos Asignados</h3>
                                            <div class="value"><%= totalCursos%></div>
                                            <p class="card-text description text-muted">Total de cursos a su cargo</p>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="col-md-4 col-sm-6 mb-4">
                            <div class="card stat-card earnings">
                                <div class="card-body">
                                    <div class="row align-items-center">
                                        <div class="col-auto">
                                            <div class="icon-wrapper bg-success text-white">
                                                <i class="fas fa-check-circle"></i>
                                            </div>
                                        </div>
                                        <div class="col">
                                            <h3 class="card-title">Cursos Activos</h3>
                                            <div class="value"><%= cursosActivos%></div>
                                            <p class="card-text description text-muted">Cursos en periodo lectivo</p>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="col-md-4 col-sm-6 mb-4">
                            <div class="card stat-card students">
                                <div class="card-body">
                                    <div class="row align-items-center">
                                        <div class="col-auto">
                                            <div class="icon-wrapper bg-warning text-white">
                                                <i class="fas fa-users"></i>
                                            </div>
                                        </div>
                                        <div class="col">
                                            <h3 class="card-title">Estudiantes</h3>
                                            <div class="value"><%= totalAlumnos%></div>
                                            <p class="card-text description text-muted">Alumnos matriculados</p>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="row">
                        <div class="col-12 mb-4">
                            <div class="card profesor-info">
                                <div class="card-body">
                                    <h3 class="section-title card-title mb-3">Mi Información</h3>
                                    <div class="row">
                                        <div class="col-lg-6">
                                            <p class="mb-1"><small class="text-muted">Nombre completo:</small><br> <strong><%= nombreCompleto%></strong></p>
                                            <p class="mb-1"><small class="text-muted">DNI:</small><br> <strong><%= dni%></strong></p>
                                            <p class="mb-1"><small class="text-muted">Facultad:</small><br> <strong><%= facultad%></strong></p>
                                        </div>
                                        <div class="col-lg-6">
                                            <p class="mb-1"><small class="text-muted">Correo electrónico:</small><br> <strong><%= email%></strong></p>
                                            <p class="mb-1"><small class="text-muted">Teléfono:</small><br> <strong><%= telefono%></strong></p>
                                            <p class="mb-1"><small class="text-muted">Último acceso:</small><br> <strong><%= ultimoAcceso%></strong></p>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="row">
                        <div class="col-xl-6 col-lg-12 mb-4">
                            <div class="card content-section">
                                <div class="card-body">
                                    <h3 class="section-title card-title">Estadísticas de Asistencia</h3>
                                    <div class="chart-container">
                                        <canvas id="asistenciaChart"></canvas>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="col-xl-6 col-lg-12 mb-4">
                            <div class="card content-section">
                                <div class="card-body">
                                    <h3 class="section-title card-title">Calendario</h3>
                                    <div class="calendar-widget">
                                        <div class="calendar-header d-flex justify-content-between align-items-center mb-3">
                                            <button class="btn btn-sm btn-outline-primary"><i class="fas fa-chevron-left"></i></button>
                                            <h5>Junio 2025</h5>
                                            <button class="btn btn-sm btn-outline-primary"><i class="fas fa-chevron-right"></i></button>
                                        </div>
                                        <div class="calendar-grid text-center">
                                            <div class="day-name">Dom</div>
                                            <div class="day-name">Lun</div>
                                            <div class="day-name">Mar</div>
                                            <div class="day-name">Mié</div>
                                            <div class="day-name">Jue</div>
                                            <div class="day-name">Vie</div>
                                            <div class="day-name">Sáb</div>
                                            <div class="day">1</div><div class="day">2</div><div class="day">3</div><div class="day">4</div><div class="day">5</div><div class="day">6</div><div class="day">7</div>
                                            <div class="day">8</div><div class="day">9</div><div class="day">10</div><div class="day">11</div><div class="day">12</div><div class="day">13</div><div class="day">14</div>
                                            <div class="day">15</div><div class="day current">16</div><div class="day">17</div><div class="day">18</div><div class="day">19</div><div class="day">20</div><div class="day">21</div>
                                            <div class="day">22</div><div class="day">23</div><div class="day">24</div><div class="day">25</div><div class="day">26</div><div class="day">27</div><div class="day">28</div>
                                            <div class="day">29</div><div class="day">30</div>
                                            <div class="day old">1</div><div class="day old">2</div><div class="day old">3</div><div class="day old">4</div><div class="day old">5</div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>


                    <div class="row">
                        <div class="col-12 mb-4">
                            <div class="card content-section">
                                <div class="card-body">
                                    <h3 class="section-title card-title">Notas Promedio por Curso</h3>
                                    <div class="chart-container">
                                        <canvas id="notasChart"></canvas>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="row">
                        <div class="col-lg-7 mb-4">
                            <div class="card content-section">
                                <div class="card-body">
                                    <h3 class="section-title card-title">Mis Cursos</h3>
                                    <div class="table-responsive">
                                        <% if (!cursosList.isEmpty()) { %>
                                        <table class="table table-hover table-sm">
                                            <thead>
                                                <tr>
                                                    <th scope="col">Código</th>
                                                    <th scope="col">Nombre del Curso</th>
                                                    <th scope="col">Créditos</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                <% for (Map<String, String> curso : cursosList) {%>
                                                <tr>
                                                    <td><%= curso.get("codigo_curso")%></td>
                                                    <td><%= curso.get("nombre_curso")%></td>
                                                    <td><%= curso.get("creditos")%></td>
                                                </tr>
                                                <% } %>
                                            </tbody>
                                        </table>
                                        <% } else { %>
                                        <p class="text-muted">No hay cursos asignados actualmente.</p>
                                        <% } %>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="col-lg-5 mb-4">
                            <div class="card content-section">
                                <div class="card-body">
                                    <h3 class="section-title card-title">Alumnos Recientes</h3>
                                    <div class="table-responsive">
                                        <% if (!alumnosList.isEmpty()) { %>
                                        <table class="table table-hover table-sm">
                                            <thead>
                                                <tr>
                                                    <th scope="col">ID</th>
                                                    <th scope="col">Nombre</th>
                                                    <th scope="col">Curso</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                <% for (Map<String, String> alumno : alumnosList) {%>
                                                <tr>
                                                    <td><%= alumno.get("id_alumno")%></td>
                                                    <td><%= alumno.get("nombre_completo")%></td>
                                                    <td><%= alumno.get("nombre_curso")%></td>
                                                </tr>
                                                <% } %>
                                            </tbody>
                                        </table>
                                        <% } else { %>
                                        <p class="text-muted">No hay alumnos registrados recientemente.</p>
                                        <% } %>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="row">
                        <div class="col-12 mb-4">
                            <div class="card content-section">
                                <div class="card-body">
                                    <h3 class="section-title card-title">Acciones Rápidas</h3>
                                    <div class="quick-actions">
                                        <div class="action-card">
                                            <i class="fas fa-clipboard-check"></i>
                                            <h4>Registrar Asistencia</h4>
                                            <p>Registre la asistencia de sus estudiantes para la sesión de hoy</p>
                                            <a href="asistencia_profesor.jsp" class="action-btn">Ir ahora</a>
                                        </div>

                                        <div class="action-card">
                                            <i class="fas fa-edit"></i>
                                            <h4>Ingresar Notas</h4>
                                            <p>Ingrese las calificaciones de la última evaluación</p>
                                            <a href="nota_profesor.jsp" class="action-btn">Ir ahora</a>
                                        </div>

                                        <div class="action-card">
                                            <i class="fas fa-calendar-alt"></i>
                                            <h4>Ver Horario</h4>
                                            <p>Consulte su horario de clases para esta semana</p>
                                            <a href="horarios_profesor.jsp" class="action-btn">Ver horario</a>
                                        </div>

                                        <div class="action-card">
                                            <i class="fas fa-envelope"></i>
                                            <h4>Mensajes</h4>
                                            <p>Revise sus mensajes y comunicados importantes</p>
                                            <a href="mensaje_profesor.jsp" class="action-btn">Ver mensajes</a>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js" integrity="sha384-YvpcrYf0tY3lHB60NNkmXc5s9fDVZLESaAA55NDzOxhy9GkcIdslK1eN7N6jIeHz" crossorigin="anonymous"></script>
        <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
        <script>
            // --- Gráfico de Notas ---
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

            // Colores variados para las barras
            const barColors = [
                'rgba(255, 99, 132, 0.8)', // Rojo suave
                'rgba(54, 162, 235, 0.8)', // Azul suave
                'rgba(255, 206, 86, 0.8)', // Amarillo suave
                'rgba(75, 192, 192, 0.8)', // Verde agua suave
                'rgba(153, 102, 255, 0.8)', // Púrpura suave
                'rgba(255, 159, 64, 0.8)', // Naranja suave
                'rgba(199, 199, 199, 0.8)'  // Gris suave
            ];


            const ctxNotas = document.getElementById('notasChart');
            if (ctxNotas) {
                new Chart(ctxNotas.getContext('2d'), {
                    type: 'bar', // Sigue siendo 'bar' pero con indexAxis: 'y' para ser horizontal
                    data: {
                        labels: nombresCursosNotas,
                        datasets: [{
                                label: 'Promedio de Notas',
                                data: promediosNotas,
                                // MODIFICACIÓN: Usar colores variados para las barras
                                backgroundColor: barColors,
                                borderColor: barColors.map(color => color.replace('0.8', '1')), // Versión sólida del color para el borde
                                borderWidth: 1,
                                borderRadius: 5,
                            }]
                    },
                    options: {
                        indexAxis: 'y', // Esto hace que el gráfico de barras sea horizontal
                        responsive: true,
                        maintainAspectRatio: false,
                        plugins: {
                            title: {
                                display: true,
                                text: 'Promedio de Notas por Curso Asignado',
                                font: {size: 16, weight: 'bold'},
                                color: '#333'
                            },
                            legend: {
                                display: false
                            },
                            tooltip: {
                                backgroundColor: 'rgba(0,0,0,0.8)',
                                titleFont: {weight: 'bold'},
                                bodyFont: {weight: 'normal'},
                                padding: 10,
                                cornerRadius: 5
                            }
                        },
                        scales: {
                            x: {// Eje X para gráfico de barras horizontal (representa valores)
                                beginAtZero: true,
                                max: 20, // La nota máxima es 20
                                grid: {
                                    color: '#e9ecef'
                                },
                                ticks: {
                                    color: '#666'
                                },
                                title: {
                                    display: true,
                                    text: 'Nota Promedio',
                                    color: '#333',
                                    font: {weight: 'bold'}
                                }
                            },
                            y: {// Eje Y para gráfico de barras horizontal (representa categorías)
                                grid: {
                                    display: false
                                },
                                ticks: {
                                    color: '#666'
                                },
                                title: {
                                    display: true,
                                    text: 'Curso',
                                    color: '#333',
                                    font: {weight: 'bold'}
                                }
                            }
                        }
                    }
                });
            }

            // --- Gráfico de Asistencia ---
            const dataAsistencia = {
                labels: ['Presentes', 'Ausentes', 'Tardanzas'],
                datasets: [{
                        data: [<%= totalPresentes%>, <%= totalAusentes%>, <%= totalTardanzas%>],
                        backgroundColor: [
                            'rgba(23, 162, 184, 0.8)', /* admin-info (cyan) */
                            'rgba(220, 53, 69, 0.8)', /* admin-danger (red) */
                            'rgba(255, 193, 7, 0.8)'   /* admin-warning (yellow) */
                        ],
                        borderColor: [
                            'rgba(23, 162, 184, 1)',
                            'rgba(220, 53, 69, 1)',
                            'rgba(255, 193, 7, 1)'
                        ],
                        borderWidth: 1
                    }]
            };

            const ctxAsistencia = document.getElementById('asistenciaChart');
            if (ctxAsistencia) {
                new Chart(ctxAsistencia.getContext('2d'), {
                    type: 'doughnut',
                    data: dataAsistencia,
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        plugins: {
                            title: {
                                display: true,
                                text: 'Distribución de Asistencia',
                                font: {size: 16, weight: 'bold'},
                                color: '#333'
                            },
                            legend: {
                                position: 'bottom',
                                labels: {
                                    font: {size: 12},
                                    color: '#333'
                                }
                            },
                            tooltip: {
                                backgroundColor: 'rgba(0,0,0,0.8)',
                                titleFont: {weight: 'bold'},
                                bodyFont: {weight: 'normal'},
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