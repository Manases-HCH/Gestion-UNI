<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, pe.universidad.util.Conection" %>
<%@ page import="java.time.LocalDateTime, java.time.format.DateTimeFormatter" %>
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
    Object idApoderadoObj = session.getAttribute("id_apoderado");

    // --- Variables para los datos del apoderado y su hijo ---
    int idApoderado = -1;
    String nombreApoderado = "Apoderado Desconocido";
    String emailApoderado = (emailSesion != null ? emailSesion : "N/A");
    String telefonoApoderado = "No registrado";
    String ultimoAcceso = "Ahora"; // Se actualizará con la hora actual del servidor

    int idHijo = -1;
    String nombreHijo = "Hijo No Asignado";
    String dniHijo = "N/A";
    String carreraHijo = "Carrera Desconocida";
    String estadoHijo = "N/A"; // Estado académico del hijo (activo, inactivo, egresado)

    int totalCursosHijo = 0;
    int cursosActivosHijo = 0;
    int totalClasesHijo = 0;
    int totalPagosPendientes = 0; // Número de pagos pendientes

    // Listas para tablas
    List<Map<String, String>> cursosHijoList = new ArrayList<>();
    List<Map<String, String>> pagosPendientesList = new ArrayList<>();

    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    String globalErrorMessage = null; // Mensaje de error general para mostrar en la UI

    try {
        // --- 1. Validar y obtener ID del Apoderado de Sesión ---
        if (emailSesion == null || !"apoderado".equalsIgnoreCase(rolUsuario) || idApoderadoObj == null) {
            System.out.println("DEBUG (home_apoderado): Sesión inválida o rol incorrecto. Redirigiendo a login.");
            response.sendRedirect(request.getContextPath() + "/login.jsp"); // Redirigir al login
            return;
        }
        try {
            idApoderado = Integer.parseInt(String.valueOf(idApoderadoObj));
            System.out.println("DEBUG (home_apoderado): ID Apoderado de sesión: " + idApoderado);
        } catch (NumberFormatException e) {
            System.err.println("ERROR (home_apoderado): ID de apoderado en sesión no es un número válido. " + e.getMessage());
            globalErrorMessage = "Error de sesión: ID de apoderado inválido.";
            // No redirigir aquí, dejar que el código siga para mostrar el error en la página
        }

        // Si el idApoderado es -1 debido a un error de formato, o por cualquier otra razón, no intentar conectar a la BD
        if (idApoderado != -1) {
            // --- 2. Conectar a la Base de Datos ---
            Conection c = new Conection();
            conn = c.conecta();
            if (conn == null || conn.isClosed()) {
                throw new SQLException("No se pudo establecer conexión a la base de datos.");
            }
            System.out.println("DEBUG (home_apoderado): Conexión a BD establecida.");

            // --- 3. Obtener Datos Principales del Apoderado ---
            try {
                String sqlApoderado = "SELECT nombre, apellido_paterno, apellido_materno, email, telefono "
                        + "FROM apoderados WHERE id_apoderado = ?";
                pstmt = conn.prepareStatement(sqlApoderado);
                pstmt.setInt(1, idApoderado);
                rs = pstmt.executeQuery();

                if (rs.next()) {
                    String nombre = rs.getString("nombre") != null ? rs.getString("nombre") : "";
                    String apPaterno = rs.getString("apellido_paterno") != null ? rs.getString("apellido_paterno") : "";
                    String apMaterno = rs.getString("apellido_materno") != null ? rs.getString("apellido_materno") : "";
                    nombreApoderado = nombre + " " + apPaterno;
                    if (!apMaterno.isEmpty()) {
                        nombreApoderado += " " + apMaterno;
                    }
                    emailApoderado = rs.getString("email");
                    telefonoApoderado = rs.getString("telefono") != null ? rs.getString("telefono") : "No registrado";
                    session.setAttribute("nombre_apoderado", nombreApoderado); // Guardar en sesión para otras páginas
                    System.out.println("DEBUG (home_apoderado): Datos de apoderado cargados: " + nombreApoderado);
                } else {
                    globalErrorMessage = "Apoderado no encontrado en la base de datos.";
                    System.err.println("ERROR (home_apoderado): Apoderado con ID " + idApoderado + " no encontrado en BD.");
                    // Si el apoderado no existe en BD a pesar de tener ID de sesión, redirigir
                    response.sendRedirect(request.getContextPath() + "/login.jsp?error=" + java.net.URLEncoder.encode(globalErrorMessage, "UTF-8"));
                    return;
                }
            } finally {
                cerrarRecursos(rs, pstmt);
            }

            // --- 4. Obtener Datos del Hijo (Primer hijo asociado al apoderado) ---
            try {
                String sqlHijo = "SELECT a.id_alumno, a.dni, a.nombre, a.apellido_paterno, a.apellido_materno, c.nombre_carrera, a.estado "
                        + "FROM alumnos a "
                        + "JOIN alumno_apoderado aa ON a.id_alumno = aa.id_alumno "
                        + "JOIN carreras c ON a.id_carrera = c.id_carrera "
                        + "WHERE aa.id_apoderado = ? LIMIT 1"; // Asumimos un hijo por ahora
                pstmt = conn.prepareStatement(sqlHijo);
                pstmt.setInt(1, idApoderado);
                rs = pstmt.executeQuery();

                if (rs.next()) {
                    idHijo = rs.getInt("id_alumno");
                    String nombre = rs.getString("nombre") != null ? rs.getString("nombre") : "";
                    String apPaterno = rs.getString("apellido_paterno") != null ? rs.getString("apellido_paterno") : "";
                    String apMaterno = rs.getString("apellido_materno") != null ? rs.getString("apellido_materno") : "";
                    nombreHijo = nombre + " " + apPaterno;
                    if (!apMaterno.isEmpty()) {
                        nombreHijo += " " + apMaterno;
                    }
                    dniHijo = rs.getString("dni") != null ? rs.getString("dni") : "N/A";
                    carreraHijo = rs.getString("nombre_carrera") != null ? rs.getString("nombre_carrera") : "Desconocida";
                    estadoHijo = rs.getString("estado") != null ? rs.getString("estado") : "N/A";
                    session.setAttribute("id_hijo", idHijo); // Guardar ID de hijo en sesión
                    session.setAttribute("nombre_hijo", nombreHijo); // Guardar nombre de hijo en sesión
                    System.out.println("DEBUG (home_apoderado): Datos del hijo cargados: " + nombreHijo);
                } else {
                    globalErrorMessage = "No se encontró un hijo asociado a este apoderado. Contacte a la administración.";
                    System.err.println("ERROR (home_apoderado): No se encontró hijo para apoderado ID: " + idApoderado);
                }
            } finally {
                cerrarRecursos(rs, pstmt);
            }

            // --- 5. Obtener Estadísticas y Listas del Hijo (si hay un hijo asignado) ---
            if (idHijo != -1) {
                // Total Cursos del Hijo
                try {
                    String sqlCountCursosHijo = "SELECT COUNT(DISTINCT cl.id_curso) AS total "
                            + "FROM inscripciones i "
                            + "JOIN clases cl ON i.id_clase = cl.id_clase "
                            + "WHERE i.id_alumno = ? AND i.estado = 'inscrito'";
                    pstmt = conn.prepareStatement(sqlCountCursosHijo);
                    pstmt.setInt(1, idHijo);
                    rs = pstmt.executeQuery();
                    if (rs.next()) {
                        totalCursosHijo = rs.getInt("total");
                    }
                    System.out.println("DEBUG (home_apoderado): Total Cursos Hijo: " + totalCursosHijo);
                } finally {
                    cerrarRecursos(rs, pstmt);
                }

                // Cursos Activos del Hijo
                try {
                    String sqlCursosActivosHijo = "SELECT COUNT(DISTINCT cl.id_curso) AS total "
                            + "FROM inscripciones i "
                            + "JOIN clases cl ON i.id_clase = cl.id_clase "
                            + "WHERE i.id_alumno = ? AND i.estado = 'inscrito' AND cl.estado = 'activo'"; // Clases activas
                    pstmt = conn.prepareStatement(sqlCursosActivosHijo);
                    pstmt.setInt(1, idHijo);
                    rs = pstmt.executeQuery();
                    if (rs.next()) {
                        cursosActivosHijo = rs.getInt("total");
                    }
                    System.out.println("DEBUG (home_apoderado): Cursos Activos Hijo: " + cursosActivosHijo);
                } finally {
                    cerrarRecursos(rs, pstmt);
                }

                // Total Clases Matriculadas por el Hijo (cuenta clases, no cursos)
                try {
                    String sqlTotalClasesHijo = "SELECT COUNT(*) AS total FROM inscripciones WHERE id_alumno = ? AND estado = 'inscrito'";
                    pstmt = conn.prepareStatement(sqlTotalClasesHijo);
                    pstmt.setInt(1, idHijo);
                    rs = pstmt.executeQuery();
                    if (rs.next()) {
                        totalClasesHijo = rs.getInt("total");
                    }
                    System.out.println("DEBUG (home_apoderado): Total Clases Hijo (inscripciones): " + totalClasesHijo);
                } finally {
                    cerrarRecursos(rs, pstmt);
                }

                // Pagos Pendientes del Hijo
                try {
                    String sqlPagos = "SELECT id_pago, concepto, monto, fecha_vencimiento, estado "
                            + "FROM pagos WHERE id_alumno = ? AND estado = 'pendiente'";
                    pstmt = conn.prepareStatement(sqlPagos);
                    pstmt.setInt(1, idHijo);
                    rs = pstmt.executeQuery();
                    while (rs.next()) {
                        Map<String, String> pago = new HashMap<>();
                        pago.put("id_pago", String.valueOf(rs.getInt("id_pago")));
                        pago.put("concepto", rs.getString("concepto"));
                        pago.put("monto", String.format(Locale.US, "%.2f", rs.getDouble("monto"))); // Formato con 2 decimales
                        pago.put("fecha_vencimiento", rs.getDate("fecha_vencimiento").toString());
                        pago.put("estado", rs.getString("estado"));
                        pagosPendientesList.add(pago);
                    }
                    totalPagosPendientes = pagosPendientesList.size();
                    System.out.println("DEBUG (home_apoderado): Pagos pendientes: " + totalPagosPendientes);
                } finally {
                    cerrarRecursos(rs, pstmt);
                }

                // Lista de Cursos del Hijo para tabla
                try {
                    String sqlCursosHijoList = "SELECT cu.nombre_curso, cl.seccion, cl.semestre, cl.año_academico, cu.creditos "
                            + "FROM inscripciones i "
                            + "JOIN clases cl ON i.id_clase = cl.id_clase "
                            + "JOIN cursos cu ON cl.id_curso = cu.id_curso "
                            + "WHERE i.id_alumno = ? AND i.estado = 'inscrito' "
                            + "ORDER BY cl.año_academico DESC, cl.semestre DESC, cu.nombre_curso";
                    pstmt = conn.prepareStatement(sqlCursosHijoList);
                    pstmt.setInt(1, idHijo);
                    rs = pstmt.executeQuery();
                    while (rs.next()) {
                        Map<String, String> curso = new HashMap<>();
                        curso.put("nombre_curso", rs.getString("nombre_curso"));
                        curso.put("seccion", rs.getString("seccion"));
                        curso.put("semestre", rs.getString("semestre"));
                        curso.put("anio", String.valueOf(rs.getInt("año_academico")));
                        curso.put("creditos", String.valueOf(rs.getInt("creditos"))); // Añadido
                        cursosHijoList.add(curso);
                    }
                    System.out.println("DEBUG (home_apoderado): Cursos de hijo listados: " + cursosHijoList.size());
                } finally {
                    cerrarRecursos(rs, pstmt);
                }

            } // Fin de if (idHijo != -1)
        } // Fin de if (idApoderado != -1) para operaciones de BD

        // --- Obtener la fecha y hora actual para "Último acceso" ---
        ultimoAcceso = LocalDateTime.now().format(DateTimeFormatter.ofPattern("EEEE, d 'de' MMMM 'de'yyyy, HH:mm", new Locale("es", "ES"))); // Formato en español

    } catch (SQLException e) {
        globalErrorMessage = "Error de base de datos al cargar la información: " + e.getMessage();
        System.err.println("ERROR (home_apoderado) SQL Principal: " + globalErrorMessage);
        e.printStackTrace();
    } catch (ClassNotFoundException e) {
        globalErrorMessage = "Error de configuración: Driver JDBC no encontrado.";
        System.err.println("ERROR (home_apoderado) DRIVER Principal: " + globalErrorMessage);
        e.printStackTrace();
    } finally {
        try {
            if (conn != null) {
                conn.close();
            }
        } catch (SQLException e) {
            System.err.println("Error al cerrar conexión final: " + e.getMessage());
        }
    }
%>

<!DOCTYPE html>
<html lang="es">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Dashboard Apoderado | Sistema Universitario</title>
        <link rel="icon" type="image/x-icon" href="<%= request.getContextPath()%>/img/favicon.ico">
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous">
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
        <style>
            /* Variables de color basadas en tu paleta y renombradas para Bootstrap */
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
                color: rgba(255,255,255,0.8);
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

            /* Welcome section (adapted for Apoderado) */
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

            /* Stats Cards - Adjusted colors for Apoderado dashboard */
            .stat-card {
                background-color: var(--admin-card-bg);
                border-radius: 0.5rem;
                padding: 1.5rem;
                text-align: center;
                box-shadow: 0 0.125rem 0.25rem rgba(0,0,0,0.075);
                border-bottom: 4px solid var(--admin-primary); /* Default for stats */
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
                color: var(--admin-primary); /* Use primary color for values */
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
            /* Specific stat card colors */
            .stat-card.courses .value {
                color: var(--admin-info);
            } /* Info blue */
            .stat-card.courses .icon-wrapper {
                color: var(--admin-info);
            }
            .stat-card.active-classes .value {
                color: var(--admin-success);
            } /* Success green */
            .stat-card.active-classes .icon-wrapper {
                color: var(--admin-success);
            }
            .stat-card.pending-payments .value {
                color: var(--admin-warning);
            } /* Warning yellow */
            .stat-card.pending-payments .icon-wrapper {
                color: var(--admin-warning);
            }
            .stat-card.student-status .value {
                color: var(--admin-text-dark);
            } /* Dark text */
            .stat-card.student-status .icon-wrapper {
                color: var(--admin-text-dark);
            }


            /* Information Cards (Apoderado and Hijo) */
            .info-section-card.card {
                border-left: 4px solid var(--admin-primary);
                box-shadow: 0 0.125rem 0.25rem rgba(0,0,0,0.075);
                margin-bottom: 1.5rem;
            }
            .info-section-card .card-header {
                background-color: var(--admin-card-bg);
                border-bottom: 1px solid #dee2e6;
                padding-bottom: 1rem;
            }
            .info-section-card .section-title {
                color: var(--admin-primary);
                font-weight: 600;
                margin-bottom: 0;
            }
            .info-detail-row {
                padding: 0.2rem 0;
                font-size: 0.95rem;
            }
            .info-detail-row strong {
                color: var(--admin-text-dark);
            }
            .info-detail-row span {
                color: var(--admin-text-muted);
            }

            /* Tables (Courses and Payments) */
            .table-responsive {
                max-height: 400px; /* Limit height for scrollable tables */
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

            /* Calendar Widget */
            .calendar-widget-card .card-body {
                padding: 1rem;
            }
            .calendar-header {
                font-weight: bold;
                color: var(--admin-primary);
                margin-bottom: 0.75rem;
            }
            .calendar-grid {
                display: grid;
                grid-template-columns: repeat(7, 1fr);
                gap: 5px;
                text-align: center;
            }
            .calendar-grid .day-name {
                font-weight: bold;
                color: var(--admin-text-dark);
                font-size: 0.85rem;
                padding-bottom: 5px;
            }
            .calendar-grid .day {
                padding: 8px;
                border-radius: 5px;
                background-color: var(--admin-light-bg);
                border: 1px solid #e9ecef;
                cursor: pointer;
                transition: background-color 0.2s ease;
                font-size: 0.9rem;
            }
            .calendar-grid .day:hover {
                background-color: #e0e0e0;
            }
            .calendar-grid .day.current {
                background-color: var(--admin-primary);
                color: white;
                font-weight: bold;
            }
            .calendar-grid .day.old {
                color: var(--admin-text-muted);
                background-color: #f0f0f0;
            }

            /* Digital Clock */
            .digital-clock-card .card-body {
                display: flex;
                flex-direction: column;
                align-items: center;
                justify-content: center;
                padding: 1.5rem;
                min-height: 150px; /* Ensure similar height to calendar */
            }
            .digital-clock {
                font-family: 'Inter', sans-serif;
                font-size: 3rem;
                font-weight: 700;
                color: var(--admin-primary);
                letter-spacing: 2px;
                margin-bottom: 0.5rem;
            }
            .digital-date {
                font-size: 1rem;
                color: var(--admin-text-muted);
            }


            /* Quick Actions */
            .quick-actions .card-body {
                display: flex;
                flex-direction: column;
                align-items: center;
                justify-content: center;
            }
            .quick-actions .card-title {
                color: var(--admin-primary);
                font-weight: 600;
            }
            .quick-actions .card-text {
                color: var(--admin-text-muted);
            }
            .quick-actions .display-4 {
                font-size: 3rem;
                margin-bottom: 1rem;
            }
            .action-btn-custom {
                display: inline-block;
                background-color: var(--admin-primary);
                color: white;
                padding: 0.6rem 1.2rem;
                border-radius: 0.3rem;
                text-decoration: none;
                font-weight: 500;
                transition: background-color 0.2s ease, transform 0.2s ease;
            }
            .action-btn-custom:hover {
                background-color: #0056b3;
                color: white;
                transform: translateY(-2px);
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

                .welcome-section, .card {
                    padding: 1rem;
                }
                .stat-card, .quick-actions .col {
                    margin-bottom: 1rem;
                } /* Spacing for stacked cards */
                .stat-card .value {
                    font-size: 1.8rem;
                }
                .stat-card .icon-wrapper {
                    font-size: 1.5rem;
                }
                .digital-clock {
                    font-size: 2.5rem;
                }
                .calendar-grid .day {
                    padding: 6px;
                    font-size: 0.8rem;
                }
            }
            @media (max-width: 576px) {
                .main-content {
                    padding: 0.75rem;
                }
                .welcome-section, .card {
                    padding: 0.75rem;
                }
            }
        </style>
    </head>
    <body>
        <div id="app">
            <nav class="sidebar">
                <div class="sidebar-header">
                    <a href="<%= request.getContextPath()%>/INTERFAZ_APODERADO/home_apoderado.jsp" class="text-white text-decoration-none">UGIC Portal</a>
                </div>
                <ul class="navbar-nav">
                    <li class="nav-item">
                        <a class="nav-link active" href="<%= request.getContextPath()%>/INTERFAZ_APODERADO/home_apoderado.jsp"><i class="fas fa-home"></i><span> Inicio</span></a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="<%= request.getContextPath()%>/INTERFAZ_APODERADO/cursos_apoderado.jsp"><i class="fas fa-book"></i><span> Cursos de mi hijo</span></a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="<%= request.getContextPath()%>/INTERFAZ_APODERADO/asistencia_apoderado.jsp"><i class="fas fa-clipboard-check"></i><span> Asistencia de mi hijo</span></a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="<%= request.getContextPath()%>/INTERFAZ_APODERADO/notas_apoderado.jsp"><i class="fas fa-percent"></i><span> Notas de mi hijo</span></a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="<%= request.getContextPath()%>/INTERFAZ_APODERADO/pagos_apoderado.jsp"><i class="fas fa-money-bill-wave"></i><span> Pagos y Mensualidades</span></a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="<%= request.getContextPath()%>/INTERFAZ_APODERADO/mensajes_apoderado.jsp"><i class="fas fa-envelope"></i><span> Mensajes</span></a>
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
                                <img src="https://via.placeholder.com/32" alt="Avatar"> <span class="d-none d-md-inline-block"><%= nombreApoderado%></span>
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
                        <h1 class="h3 mb-3"><i class="fas fa-tachometer-alt me-2"></i>Dashboard del Apoderado</h1>
                        <p class="lead">Bienvenido, <%= nombreApoderado%>. Este es su panel de control para gestionar la información de su hijo/a.</p>
                    </div>

                    <% if (globalErrorMessage != null) {%>
                    <div class="alert alert-danger alert-dismissible fade show" role="alert">
                        <i class="fas fa-exclamation-triangle me-2"></i> <%= globalErrorMessage%>
                        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                    </div>
                    <% }%>

                    <div class="row row-cols-1 row-cols-md-2 row-cols-lg-4 g-4 mb-4 stats-grid">
                        <div class="col">
                            <div class="card h-100 shadow-sm stat-card courses">
                                <div class="card-body">
                                    <div class="icon-wrapper"><i class="fas fa-book"></i></div>
                                    <h3 class="card-title">Cursos Inscritos</h3>
                                    <div class="value"><%= totalCursosHijo%></div>
                                    <div class="description">Total de cursos del hijo/a</div>
                                </div>
                            </div>
                        </div>
                        <div class="col">
                            <div class="card h-100 shadow-sm stat-card active-classes">
                                <div class="card-body">
                                    <div class="icon-wrapper"><i class="fas fa-check-circle"></i></div>
                                    <h3 class="card-title">Clases Activas</h3>
                                    <div class="value"><%= cursosActivosHijo%></div>
                                    <div class="description">Clases en curso</div>
                                </div>
                            </div>
                        </div>
                        <div class="col">
                            <div class="card h-100 shadow-sm stat-card pending-payments">
                                <div class="card-body">
                                    <div class="icon-wrapper"><i class="fas fa-money-bill-wave"></i></div>
                                    <h3 class="card-title">Pagos Pendientes</h3>
                                    <div class="value"><%= totalPagosPendientes%></div>
                                    <div class="description">Mensualidades por pagar</div>
                                </div>
                            </div>
                        </div>
                        <div class="col">
                            <div class="card h-100 shadow-sm stat-card student-status">
                                <div class="card-body">
                                    <div class="icon-wrapper"><i class="fas fa-user-graduate"></i></div>
                                    <h3 class="card-title">Estado del Hijo</h3>
                                    <div class="value"><%= estadoHijo.toUpperCase()%></div>
                                    <div class="description">Estado académico</div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="row">
                        <div class="col-lg-6 mb-4">
                            <div class="card shadow-sm h-100 info-section-card">
                                <div class="card-header">
                                    <h3 class="section-title"><i class="fas fa-user me-2"></i>Mi Información</h3>
                                </div>
                                <div class="card-body">
                                    <p class="mb-1 info-detail-row"><strong>Nombre completo:</strong> <span><%= nombreApoderado%></span></p>
                                    <p class="mb-1 info-detail-row"><strong>Email:</strong> <span><%= emailApoderado%></span></p>
                                    <p class="mb-1 info-detail-row"><strong>Teléfono:</strong> <span><%= telefonoApoderado%></span></p>
                                    <p class="mb-0 info-detail-row"><strong>Último acceso:</strong> <span><%= ultimoAcceso%></span></p>
                                </div>
                            </div>
                        </div>
                        <div class="col-lg-6 mb-4">
                            <div class="card shadow-sm h-100 info-section-card">
                                <div class="card-header">
                                    <h3 class="section-title"><i class="fas fa-child me-2"></i>Información de mi Hijo: <%= nombreHijo%></h3>
                                </div>
                                <div class="card-body">
                                    <% if (idHijo != -1) {%>
                                    <p class="mb-1 info-detail-row"><strong>DNI:</strong> <span><%= dniHijo%></span></p>
                                    <p class="mb-1 info-detail-row"><strong>Carrera:</strong> <span><%= carreraHijo%></span></p>
                                    <p class="mb-1 info-detail-row"><strong>Estado Académico:</strong> <span><%= estadoHijo.toUpperCase()%></span></p>
                                    <p class="mb-0 info-detail-row"><strong>Total Clases:</strong> <span><%= totalClasesHijo%></span></p>
                                    <% } else { %>
                                    <p class="text-muted text-center py-3 mb-0">No se encontró información detallada del hijo/a.</p>
                                    <% }%>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="card shadow-sm mb-4 info-section-card">
                        <div class="card-header">
                            <h3 class="section-title"><i class="fas fa-book-open me-2"></i>Cursos de <%= nombreHijo%></h3>
                        </div>
                        <div class="card-body">
                            <div class="table-responsive">
                                <% if (!cursosHijoList.isEmpty()) { %>
                                <table class="table table-hover table-striped">
                                    <thead>
                                        <tr>
                                            <th>Curso</th>
                                            <th>Sección</th>
                                            <th>Semestre</th>
                                            <th>Año</th>
                                            <th>Créditos</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <% for (Map<String, String> curso : cursosHijoList) {%>
                                        <tr>
                                            <td><%= curso.get("nombre_curso")%></td>
                                            <td><%= curso.get("seccion")%></td>
                                            <td><%= curso.get("semestre")%></td>
                                            <td><%= curso.get("anio")%></td>
                                            <td><%= curso.get("creditos")%></td>
                                        </tr>
                                        <% } %>
                                    </tbody>
                                </table>
                                <% } else { %>
                                <p class="text-muted text-center py-3">No hay cursos inscritos para su hijo/a actualmente.</p>
                                <% }%>
                            </div>
                        </div>
                    </div>

                    <div class="card shadow-sm mb-4 info-section-card">
                        <div class="card-header">
                            <h3 class="section-title"><i class="fas fa-receipt me-2"></i>Pagos Pendientes de <%= nombreHijo%></h3>
                        </div>
                        <div class="card-body">
                            <div class="table-responsive">
                                <% if (!pagosPendientesList.isEmpty()) { %>
                                <table class="table table-hover table-striped">
                                    <thead>
                                        <tr>
                                            <th>Concepto</th>
                                            <th>Monto</th>
                                            <th>Fecha Vencimiento</th>
                                            <th>Estado</th>
                                            <th>Acción</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <% for (Map<String, String> pago : pagosPendientesList) {%>
                                        <tr>
                                            <td><%= pago.get("concepto")%></td>
                                            <td>S/. <%= pago.get("monto")%></td>
                                            <td><%= pago.get("fecha_vencimiento")%></td>
                                            <td><span class="badge bg-warning text-dark"><%= pago.get("estado").toUpperCase()%></span></td>
                                            <td>
                                                <a href="#" onclick="alert('Funcionalidad de pago para <%= pago.get("concepto")%> por desarrollar.')" class="btn btn-primary btn-sm">
                                                    <i class="fas fa-money-check-alt me-1"></i> Pagar
                                                </a>
                                            </td>
                                        </tr>
                                        <% } %>
                                    </tbody>
                                </table>
                                <% } else { %>
                                <p class="text-muted text-center py-3">No hay pagos pendientes para su hijo/a.</p>
                                <% }%>
                            </div>
                        </div>
                    </div>

                    <div class="row g-4 mb-4">
                        <div class="col-md-6">
                            <div class="card shadow-sm h-100 calendar-widget-card">
                                <div class="card-header">
                                    <h3 class="section-title mb-0"><i class="fas fa-calendar-alt me-2"></i>Calendario</h3>
                                </div>
                                <div class="card-body text-center">
                                    <div class="calendar-header d-flex justify-content-between align-items-center mb-3">
                                        <button class="btn btn-sm btn-outline-primary"><i class="fas fa-chevron-left"></i></button>
                                        <h5>Junio 2025</h5> <button class="btn btn-sm btn-outline-primary"><i class="fas fa-chevron-right"></i></button>
                                    </div>
                                    <div class="calendar-grid">
                                        <div class="day-name">Dom</div><div class="day-name">Lun</div><div class="day-name">Mar</div><div class="day-name">Mié</div><div class="day-name">Jue</div><div class="day-name">Vie</div><div class="day-name">Sáb</div>
                                        <div class="day old">26</div><div class="day old">27</div><div class="day old">28</div><div class="day old">29</div><div class="day old">30</div><div class="day">1</div><div class="day">2</div>
                                        <div class="day">3</div><div class="day">4</div><div class="day">5</div><div class="day">6</div><div class="day">7</div><div class="day">8</div><div class="day">9</div>
                                        <div class="day">10</div><div class="day">11</div><div class="day">12</div><div class="day">13</div><div class="day">14</div><div class="day">15</div><div class="day current">16</div>
                                        <div class="day">17</div><div class="day">18</div><div class="day">19</div><div class="day">20</div><div class="day">21</div><div class="day">22</div><div class="day">23</div>
                                        <div class="day">24</div><div class="day">25</div><div class="day">26</div><div class="day">27</div><div class="day">28</div><div class="day">29</div><div class="day">30</div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="card shadow-sm h-100 digital-clock-card">
                                <div class="card-header">
                                    <h3 class="section-title mb-0"><i class="fas fa-clock me-2"></i>Hora Actual</h3>
                                </div>
                                <div class="card-body">
                                    <div id="digitalClock" class="digital-clock"></div>
                                    <div id="digitalDate" class="digital-date"></div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="card shadow-sm mb-4 info-section-card">
                        <div class="card-header">
                            <h3 class="section-title"><i class="fas fa-bolt me-2"></i>Acciones Rápidas</h3>
                        </div>
                        <div class="card-body">
                            <div class="row row-cols-1 row-cols-md-2 row-cols-lg-4 g-4 quick-actions">
                                <div class="col">
                                    <div class="card h-100 text-center shadow-sm card-border-primary">
                                        <div class="card-body">
                                            <i class="fas fa-clipboard-check mb-3 display-4 text-primary"></i>
                                            <h4 class="card-title h5">Ver Asistencia</h4>
                                            <p class="card-text text-muted">Consulte el registro de asistencia de su hijo.</p>
                                            <a href="<%= request.getContextPath()%>/INTERFAZ_APODERADO/asistencia_apoderado.jsp" class="btn btn-primary action-btn-custom">Ir ahora</a>
                                        </div>
                                    </div>
                                </div>

                                <div class="col">
                                    <div class="card h-100 text-center shadow-sm card-border-primary">
                                        <div class="card-body">
                                            <i class="fas fa-graduation-cap mb-3 display-4 text-primary"></i>
                                            <h4 class="card-title h5">Ver Notas</h4>
                                            <p class="card-text text-muted">Revise las calificaciones de su hijo.</p>
                                            <a href="<%= request.getContextPath()%>/INTERFAZ_APODERADO/notas_apoderado.jsp" class="btn btn-primary action-btn-custom">Ir ahora</a>
                                        </div>
                                    </div>
                                </div>

                                <div class="col">
                                    <div class="card h-100 text-center shadow-sm card-border-primary">
                                        <div class="card-body">
                                            <i class="fas fa-money-bill-wave mb-3 display-4 text-primary"></i>
                                            <h4 class="card-title h5">Historial de Pagos</h4>
                                            <p class="card-text text-muted">Consulte los pagos realizados y pendientes.</p>
                                            <a href="<%= request.getContextPath()%>/INTERFAZ_APODERADO/pagos_apoderado.jsp" class="btn btn-primary action-btn-custom">Ver historial</a>
                                        </div>
                                    </div>
                                </div>

                                <div class="col">
                                    <div class="card h-100 text-center shadow-sm card-border-primary">
                                        <div class="card-body">
                                            <i class="fas fa-envelope mb-3 display-4 text-primary"></i>
                                            <h4 class="card-title h5">Mensajes</h4>
                                            <p class="card-text text-muted">Revise los mensajes y comunicados importantes.</p>
                                            <a href="<%= request.getContextPath()%>/INTERFAZ_APODERADO/mensajes_apoderado.jsp" class="btn btn-primary action-btn-custom">Ver mensajes</a>
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
        <script>
                                                    // --- Reloj Digital en Tiempo Real ---
                                                    function updateClock() {
                                                        const now = new Date();
                                                        const hours = String(now.getHours()).padStart(2, '0');
                                                        const minutes = String(now.getMinutes()).padStart(2, '0');
                                                        const seconds = String(now.getSeconds()).padStart(2, '0');
                                                        const timeString = `${hours}:${minutes}:${seconds}`;

                                                                // Usar 'es-PE' para español de Perú, o 'es-ES' para español genérico
                                                                const options = {weekday: 'long', year: 'numeric', month: 'long', day: 'numeric'};
                                                                const dateString = now.toLocaleDateString('es-PE', options); // Changed to es-PE for local context

                                                                const clockElement = document.getElementById('digitalClock');
                                                                const dateElement = document.getElementById('digitalDate');

                                                                // Solo actualiza si los elementos existen
                                                                if (clockElement) {
                                                                    clockElement.textContent = timeString;
                                                                }
                                                                if (dateElement) {
                                                                    dateElement.textContent = dateString;
                                                                }
                                                            }

                                                            // Asegurarse de que el DOM esté cargado antes de iniciar el reloj
                                                            document.addEventListener('DOMContentLoaded', (event) => {
                                                                // Actualiza el reloj cada segundo
                                                                setInterval(updateClock, 1000);
                                                                // Llamada inicial para mostrar el reloj inmediatamente al cargar la página
                                                                updateClock();
                                                            });

                                                            // --- Calendar Widget Placeholder Logic ---
                                                            // El calendario es estático en el HTML. Si necesitas que sea dinámico
                                                            // (ej. cambiar meses), se requeriría JavaScript adicional para renderizarlo
                                                            // dinámicamente o usar una librería de calendario.
        </script>
    </body>
</html>