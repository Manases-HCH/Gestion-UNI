<%@ page import="java.sql.*, java.util.*, pe.universidad.util.Conection" %>
<%@ page import="java.time.LocalDate, java.time.format.TextStyle, java.util.Locale" %>
<%@ page import="java.util.List, java.util.ArrayList, java.util.HashMap, java.util.Map" %>
<%@ page session="true" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<%! // Métodos auxiliares reutilizables
    private void closeDbResources(ResultSet rs, PreparedStatement pstmt) {
        try { if (rs != null) rs.close(); } catch (SQLException e) { /* Ignored */ }
        try { if (pstmt != null) pstmt.close(); } catch (SQLException e) { /* Ignored */ }
    }
%>

<%
    // --- Variables para la información del profesor logueado ---
    Object idObj = session.getAttribute("id_profesor");
    String emailSesion = (String) session.getAttribute("email");
    String rolUsuario = (String) session.getAttribute("rol");
    int idProfesor = -1;
    String nombreProfesor = "";
    String emailProfesor = "";
    String facultadProfesor = "No asignada";
    String pageLoadErrorMessage = null;

    if (idObj != null && emailSesion != null && "profesor".equalsIgnoreCase(rolUsuario)) {
        idProfesor = (idObj instanceof Integer) ? (Integer) idObj : Integer.parseInt(idObj.toString());
        emailProfesor = emailSesion;
    } else {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    // --- Variables para la lógica de asistencia ---
    String idClaseParam = request.getParameter("id_clase");
    String nombreClase = "Clase No Seleccionada";
    String codigoClase = "";
    String aulaClase = "";
    String semestreClase = "";
    String anioAcademicoClase = "";
    String fechaActualDisplay = LocalDate.now().format(java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy"));
    String fechaActualDB = LocalDate.now().format(java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd"));

    List<Map<String, String>> clasesDelProfesor = new ArrayList<>();
    List<Map<String, String>> estudiantesDeClase = new ArrayList<>();
    String mensajeFeedback = "";
    String tipoMensajeFeedback = "";

    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    try {
        Conection conexionUtil = new Conection();
        conn = conexionUtil.conecta();

        // 1. Obtener información básica del profesor
        String sqlProfesor = "SELECT p.nombre, p.apellido_paterno, p.apellido_materno, p.email, f.nombre_facultad as facultad " +
                             "FROM profesores p LEFT JOIN facultades f ON p.id_facultad = f.id_facultad WHERE p.id_profesor = ?";
        pstmt = conn.prepareStatement(sqlProfesor);
        pstmt.setInt(1, idProfesor);
        rs = pstmt.executeQuery();
        if (rs.next()) {
            nombreProfesor = rs.getString("nombre") + " " + rs.getString("apellido_paterno") +
                             (rs.getString("apellido_materno") != null ? " " + rs.getString("apellido_materno") : "");
            facultadProfesor = rs.getString("facultad") != null ? rs.getString("facultad") : "No asignada";
        }
        closeDbResources(rs, pstmt);

        // Guardar asistencia (POST)
        if ("POST".equalsIgnoreCase(request.getMethod()) && idClaseParam != null && !idClaseParam.isEmpty()) {
            int idClaseGuardar = Integer.parseInt(idClaseParam);

            String sqlCheckClass = "SELECT COUNT(*) FROM clases WHERE id_clase = ? AND id_profesor = ?";
            pstmt = conn.prepareStatement(sqlCheckClass);
            pstmt.setInt(1, idClaseGuardar);
            pstmt.setInt(2, idProfesor);
            rs = pstmt.executeQuery();
            if (rs.next() && rs.getInt(1) == 0) {
                mensajeFeedback = "Error: La clase seleccionada no es válida o no le pertenece.";
                tipoMensajeFeedback = "danger";
                response.sendRedirect(request.getContextPath() + "/INTERFAZ_PROFESOR/asistencia.jsp?mensaje=" + java.net.URLEncoder.encode(mensajeFeedback, "UTF-8") + "&tipo=" + tipoMensajeFeedback);
                return;
            }
            closeDbResources(rs, pstmt);

            int registrosAfectados = 0;
            String sqlInscripcionesClase = "SELECT id_inscripcion FROM inscripciones WHERE id_clase = ? AND estado = 'inscrito'";
            pstmt = conn.prepareStatement(sqlInscripcionesClase);
            pstmt.setInt(1, idClaseGuardar);
            rs = pstmt.executeQuery();
            List<String> idsInscripcionEnForm = new ArrayList<>();
            while(rs.next()) {
                idsInscripcionEnForm.add(String.valueOf(rs.getInt("id_inscripcion")));
            }
            closeDbResources(rs, pstmt);

            String sqlInsert = "INSERT INTO asistencia (id_inscripcion, fecha, estado, observaciones) VALUES (?, ?, ?, ?)";
            String sqlUpdate = "UPDATE asistencia SET estado = ?, observaciones = ? WHERE id_inscripcion = ? AND fecha = ?";

            for (String idInscripcion : idsInscripcionEnForm) {
                String estado = request.getParameter("estado_" + idInscripcion);
                String observaciones = request.getParameter("observaciones_" + idInscripcion);
                if (estado == null) estado = "ausente"; // Default to ausente if not explicitly set
                if (observaciones == null) observaciones = "";

                try {
                    pstmt = conn.prepareStatement(sqlInsert);
                    pstmt.setString(1, idInscripcion);
                    pstmt.setString(2, fechaActualDB);
                    pstmt.setString(3, estado);
                    pstmt.setString(4, observaciones.isEmpty() ? null : observaciones);
                    pstmt.executeUpdate();
                    registrosAfectados++;
                } catch (SQLException e) {
                    if (e.getSQLState() != null && e.getSQLState().startsWith("23")) { // Check for unique constraint violation
                        pstmt = conn.prepareStatement(sqlUpdate);
                        pstmt.setString(1, estado);
                        pstmt.setString(2, observaciones.isEmpty() ? null : observaciones);
                        pstmt.setString(3, idInscripcion);
                        pstmt.setString(4, fechaActualDB);
                        int updatedRows = pstmt.executeUpdate();
                        if (updatedRows > 0) registrosAfectados++;
                    } else {
                        throw e; // Re-throw other SQL exceptions
                    }
                } finally {
                    if (pstmt != null) try { pstmt.close(); } catch (SQLException ignore) {}
                }
            }
            mensajeFeedback = "Asistencia guardada exitosamente para " + registrosAfectados + " alumnos.";
            tipoMensajeFeedback = "success";
            // Important: Redirect to clear POST data and show message
            response.sendRedirect(request.getContextPath() + "/INTERFAZ_PROFESOR/asistencia_profesor.jsp?id_clase=" + idClaseParam + "&mensaje=" + java.net.URLEncoder.encode(mensajeFeedback, "UTF-8") + "&tipo=" + tipoMensajeFeedback);
            return;
        }

        // Mensaje de feedback si viene de redirección previa (GET parameters)
        String mensajeParam = request.getParameter("mensaje");
        String tipoParam = request.getParameter("tipo");
        if (mensajeParam != null && !mensajeParam.isEmpty()) {
            mensajeFeedback = java.net.URLDecoder.decode(mensajeParam, "UTF-8");
            tipoMensajeFeedback = tipoParam != null ? tipoParam : "";
        }

        if (idClaseParam == null || idClaseParam.isEmpty()) {
            // Display list of classes to choose from
            String sqlClasesProfesor = "SELECT cl.id_clase, cu.nombre_curso, cl.seccion, cl.semestre, cl.año_academico, h.aula " +
                                       "FROM clases cl JOIN cursos cu ON cl.id_curso = cu.id_curso " +
                                       "JOIN horarios h ON cl.id_horario = h.id_horario " +
                                       "WHERE cl.id_profesor = ? AND cl.estado = 'activo' " +
                                       "ORDER BY cl.año_academico DESC, cl.semestre DESC, cu.nombre_curso, cl.seccion";
            pstmt = conn.prepareStatement(sqlClasesProfesor);
            pstmt.setInt(1, idProfesor);
            rs = pstmt.executeQuery();
            while (rs.next()) {
                Map<String, String> clase = new HashMap<>();
                clase.put("id_clase", String.valueOf(rs.getInt("id_clase")));
                clase.put("nombre_curso", rs.getString("nombre_curso"));
                clase.put("seccion", rs.getString("seccion"));
                clase.put("semestre", rs.getString("semestre"));
                clase.put("anio_academico", String.valueOf(rs.getInt("año_academico")));
                clase.put("aula", rs.getString("aula"));
                clasesDelProfesor.add(clase);
            }
            closeDbResources(rs, pstmt);
        } else {
            // Display attendance form for selected class
            int idClaseMostar = Integer.parseInt(idClaseParam);
            String sqlDetalleClase = "SELECT cu.nombre_curso, cu.codigo_curso, cl.seccion, h.aula, cl.semestre, cl.año_academico " +
                                     "FROM clases cl JOIN cursos cu ON cl.id_curso = cu.id_curso " +
                                     "JOIN horarios h ON cl.id_horario = h.id_horario " +
                                     "WHERE cl.id_clase = ? AND cl.id_profesor = ?";
            pstmt = conn.prepareStatement(sqlDetalleClase);
            pstmt.setInt(1, idClaseMostar);
            pstmt.setInt(2, idProfesor);
            rs = pstmt.executeQuery();
            if (rs.next()) {
                nombreClase = rs.getString("nombre_curso");
                codigoClase = rs.getString("codigo_curso");
                aulaClase = rs.getString("aula");
                semestreClase = rs.getString("semestre");
                anioAcademicoClase = String.valueOf(rs.getInt("año_academico"));
            } else {
                // Redirect if class is not found or doesn't belong to the professor
                response.sendRedirect(request.getContextPath() + "/INTERFAZ_PROFESOR/asistencia_profesor.jsp");
                return;
            }
            closeDbResources(rs, pstmt);

            // Students of the selected class
            String sqlEstudiantes = "SELECT a.id_alumno, a.dni, a.nombre, a.apellido_paterno, a.apellido_materno, " +
                                    "i.id_inscripcion, sa.estado AS estado_asistencia, sa.observaciones " +
                                    "FROM inscripciones i JOIN alumnos a ON i.id_alumno = a.id_alumno " +
                                    "LEFT JOIN asistencia sa ON i.id_inscripcion = sa.id_inscripcion AND sa.fecha = ? " +
                                    "WHERE i.id_clase = ? AND i.estado = 'inscrito' " +
                                    "ORDER BY a.apellido_paterno, a.apellido_materno, a.nombre";
            pstmt = conn.prepareStatement(sqlEstudiantes);
            pstmt.setString(1, fechaActualDB);
            pstmt.setInt(2, idClaseMostar);
            rs = pstmt.executeQuery();

            while (rs.next()) {
                Map<String, String> estudiante = new HashMap<>();
                estudiante.put("id_inscripcion", String.valueOf(rs.getInt("id_inscripcion")));
                estudiante.put("dni", rs.getString("dni"));
                estudiante.put("nombre_completo", rs.getString("nombre") + " " +
                                                   rs.getString("apellido_paterno") +
                                                   (rs.getString("apellido_materno") != null ? " " + rs.getString("apellido_materno") : ""));
                estudiante.put("estado_asistencia", rs.getString("estado_asistencia") != null ? rs.getString("estado_asistencia") : "");
                estudiante.put("observaciones", rs.getString("observaciones") != null ? rs.getString("observaciones") : "");
                estudiantesDeClase.add(estudiante);
            }
            closeDbResources(rs, pstmt);
        }

    } catch (Exception e) {
        pageLoadErrorMessage = "Ocurrió un error inesperado: " + e.getMessage();
        e.printStackTrace();
    } finally {
        try { if (conn != null) conn.close(); } catch (SQLException ignore) {}
    }
%>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Asistencia - Sistema Universitario</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
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
            overflow-x: hidden; /* Prevent horizontal scroll */
        }
        #app { display: flex; flex: 1; width: 100%; }
        /* Sidebar */
        .sidebar {
            width: 280px; background-color: var(--admin-dark); color: rgba(255,255,255,0.8); padding-top: 1rem; flex-shrink: 0;
            position: sticky; top: 0; left: 0; height: 100vh; overflow-y: auto; box-shadow: 2px 0 5px rgba(0,0,0,0.1); z-index: 1030;
        }
        .sidebar-header { padding: 1rem 1.5rem; margin-bottom: 1.5rem; text-align: center; font-size: 1.5rem; font-weight: 700; color: var(--admin-primary); border-bottom: 1px solid rgba(255,255,255,0.05);}
        .sidebar .nav-link { display: flex; align-items: center; padding: 0.75rem 1.5rem; color: rgba(255,255,255,0.7); text-decoration: none; transition: all 0.2s ease-in-out; font-weight: 500;}
        .sidebar .nav-link i { margin-right: 0.75rem; font-size: 1.1rem;}
        .sidebar .nav-link:hover, .sidebar .nav-link.active { color: white; background-color: rgba(255,255,255,0.08); border-left: 4px solid var(--admin-primary); padding-left: 1.3rem;}
        /* Main Content */
        .main-content { flex: 1; padding: 1.5rem; overflow-y: auto; display: flex; flex-direction: column; }
        .top-navbar {
            background-color: var(--admin-card-bg); padding: 1rem 1.5rem; box-shadow: 0 0.125rem 0.25rem rgba(0,0,0,0.075);
            margin-bottom: 1.5rem; border-radius: 0.5rem; display: flex; justify-content: flex-end; align-items: center; /* Adjusted to push items to the right */
        }
        .top-navbar .user-dropdown .dropdown-toggle {
            display: flex; align-items: center; color: var(--admin-text-dark); text-decoration: none;
        }
        .top-navbar .user-dropdown .dropdown-toggle img { width: 32px; height: 32px; border-radius: 50%; margin-right: 0.5rem; object-fit: cover; border: 2px solid var(--admin-primary);}
        .welcome-section { background-color: var(--admin-card-bg); border-radius: 0.5rem; padding: 1.5rem; margin-bottom: 1.5rem; box-shadow: 0 0.125rem 0.25rem rgba(0,0,0,0.075);}
        .welcome-section h1 { color: var(--admin-text-dark); font-weight: 600; margin-bottom: 0.5rem;}
        .welcome-section p.lead { color: var(--admin-text-muted); font-size: 1rem;}
        .content-section.card { border-radius: 0.5rem; box-shadow: 0 0.125rem 0.25rem rgba(0,0,0,0.075); border-left: 4px solid var(--admin-primary);}
        .section-title { color: var(--admin-primary); margin-bottom: 1rem; font-weight: 600;}

        /* Alert Messages */
        .alert-error-message { background-color: rgba(220,53,69,0.1); border-color: var(--admin-danger); color: var(--admin-danger);}
        .alert-success-message { background-color: rgba(40,167,69,0.1); border-color: var(--admin-success); color: var(--admin-success);}

        /* Professor Info Card */
        .profesor-info .card-body p strong { color: var(--admin-text-dark); }

        /* Class Selection Cards */
        .class-card {
            cursor: pointer;
            transition: all 0.2s ease-in-out;
            border: 1px solid #e0e0e0; /* subtle border */
            border-left: 5px solid var(--admin-info); /* highlight color */
            background-color: var(--admin-card-bg);
            border-radius: 0.5rem;
        }
        .class-card:hover {
            transform: translateY(-3px);
            box-shadow: 0 0.25rem 0.5rem rgba(0,0,0,0.1);
            border-color: var(--admin-primary); /* stronger highlight on hover */
        }
        .class-card .card-title {
            font-weight: 600;
            color: var(--admin-primary);
        }
        .class-card .card-text {
            font-size: 0.9rem;
            color: var(--admin-text-muted);
        }
        .class-card .action-icon {
            font-size: 1.5rem;
            color: var(--admin-primary);
        }

        /* Attendance Table */
        .table-asistencia {
            margin-bottom: 1.5rem; /* Space below table before buttons */
        }
        .table-asistencia thead th {
            background-color: var(--admin-primary);
            color: white;
            font-weight: 600;
            vertical-align: middle;
            position: sticky; /* Make header sticky */
            top: 0; /* Stick to the top of its scrolling container */
            z-index: 1; /* Ensure it stays above table body */
        }
        .table-asistencia tbody td, .table-asistencia tbody th {
            vertical-align: middle;
        }
        .table-asistencia tbody tr:hover {
            background-color: rgba(0, 123, 255, 0.05); /* Light blue on hover */
        }

        /* Attendance Radio Buttons (Custom Style) */
        .btn-group-asistencia .btn-check + .btn {
            padding: 0.5rem 0.75rem; /* Larger padding for better touch targets */
            font-weight: 500;
            border-radius: 0.375rem; /* Bootstrap default border-radius */
        }
        .btn-group-asistencia .btn-check:checked + .btn-outline-success {
            background-color: var(--admin-success);
            color: white;
        }
        .btn-group-asistencia .btn-check:checked + .btn-outline-danger {
            background-color: var(--admin-danger);
            color: white;
        }
        .btn-group-asistencia .btn-check:checked + .btn-outline-warning {
            background-color: var(--admin-warning);
            color: white;
        }
        .btn-group-asistencia .btn-check:checked + .btn-outline-info {
            background-color: var(--admin-info);
            color: white;
        }

        /* Floating Label for Observations */
        .form-floating > .form-control-sm {
            height: calc(2.5rem + 2px); /* Adjusted height for sm input with floating label */
            padding-top: 1rem;
            padding-bottom: 0.5rem;
        }
        .form-floating > label {
            padding-top: 0.75rem; /* Adjusted label padding */
        }

        /* Empty State */
        .empty-state {
            text-align: center;
            padding: 3rem 1rem;
            color: var(--admin-text-muted);
        }
        .empty-state i {
            font-size: 3rem;
            margin-bottom: 1rem;
            color: var(--admin-secondary-color);
        }
        .empty-state h4 {
            color: var(--admin-text-dark);
            font-weight: 500;
            margin-bottom: 1rem;
        }

        /* Responsive Adjustments */
        @media (max-width: 992px) { /* Laptops and larger tablets */
            .sidebar { width: 220px; }
            .main-content { padding: 1rem; }
        }
        @media (max-width: 768px) { /* Tablets and mobiles */
            #app { flex-direction: column; }
            .sidebar {
                width: 100%; height: auto; position: relative;
                box-shadow: 0 2px 5px rgba(0,0,0,0.1); padding-bottom: 0.5rem;
            }
            .sidebar .nav-link { justify-content: center; padding: 0.6rem 1rem;}
            .sidebar .nav-link i { margin-right: 0.5rem;}
            .top-navbar { flex-direction: column; align-items: flex-start;}
            .top-navbar .user-dropdown { width: 100%; text-align: center;}
            .top-navbar .user-dropdown .dropdown-toggle { justify-content: center;}
            .btn-group-asistencia { flex-wrap: wrap; justify-content: center; } /* Wrap buttons on small screens */
            .btn-group-asistencia .btn { flex-grow: 1; margin: 2px; } /* Give buttons some space */
        }
        @media (max-width: 576px) { /* Small mobiles */
            .main-content { padding: 0.75rem; }
            .welcome-section, .card { padding: 1rem; }
            .btn-group-asistencia .btn { min-width: unset; padding: 0.4rem 0.6rem; } /* Even smaller buttons */
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
            <li class="nav-item"><a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/home_profesor.jsp"><i class="fas fa-chart-line"></i> Dashboard</a></li>
            <li class="nav-item"><a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/facultad_profesor.jsp"><i class="fas fa-building"></i> Facultades</a></li>
            <li class="nav-item"><a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/carreras_profesor.jsp"><i class="fas fa-graduation-cap"></i> Carreras</a></li>
            <li class="nav-item"><a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/cursos_profesor.jsp"><i class="fas fa-book"></i> Cursos</a></li>
            <li class="nav-item"><a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/salones_profesor.jsp"><i class="fas fa-chalkboard"></i> Clases</a></li>
            <li class="nav-item"><a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/horarios_profesor.jsp"><i class="fas fa-calendar-alt"></i> Horarios</a></li>
            <li class="nav-item"><a class="nav-link active" href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/asistencia_profesor.jsp"><i class="fas fa-clipboard-check"></i> Asistencia</a></li>
            <li class="nav-item"><a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/mensaje_profesor.jsp"><i class="fas fa-envelope"></i> Mensajería</a></li>
            <li class="nav-item"><a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/nota_profesor.jsp"><i class="fas fa-percent"></i> Notas</a></li>
            <li class="nav-item mt-3">
                <form action="<%= request.getContextPath() %>/logout.jsp" method="post" class="d-grid gap-2">
                    <button type="submit" class="btn btn-outline-light mx-3"><i class="fas fa-sign-out-alt me-2"></i> Cerrar sesión</button>
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
                <h1 class="h3 mb-3"><i class="fas fa-clipboard-check me-2"></i>Registro de Asistencia</h1>
                <p class="lead">Toma y revisa la asistencia de tus alumnos de forma sencilla.</p>
            </div>
            <% if (pageLoadErrorMessage != null) { %>
                <div class="alert alert-danger alert-error-message" role="alert">
                    <i class="fas fa-exclamation-triangle me-2"></i>Error al cargar la página: <%= pageLoadErrorMessage %>
                </div>
            <% } %>
            <% if (!mensajeFeedback.isEmpty()) {
                String alertClass = "success".equals(tipoMensajeFeedback) ? "alert-success-message" : "alert-error-message";
            %>
                <div class="alert alert-<%= tipoMensajeFeedback %> <%= alertClass %> alert-dismissible fade show" role="alert">
                    <%= mensajeFeedback %>
                    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                </div>
            <% } %>

            <div class="row">
                <div class="col-12 mb-4"> <%-- Made professor info always full width for this page --%>
                    <div class="card content-section">
                        <div class="card-body">
                            <h5 class="card-title mb-3 text-primary"><i class="fas fa-user-circle me-2"></i>Información del Profesor</h5>
                            <div class="row">
                                <div class="col-md-6">
                                    <p class="mb-1"><strong>Nombre:</strong> <%= nombreProfesor %></p>
                                    <p class="mb-1"><strong>Email:</strong> <%= emailProfesor %></p>
                                </div>
                                <div class="col-md-6">
                                    <p class="mb-1"><strong>Facultad:</strong> <%= facultadProfesor %></p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div> 
            </div>

            <% if (idClaseParam == null || idClaseParam.isEmpty()) { %>
                <div class="card content-section mb-4">
                    <div class="card-header bg-white border-bottom-0 pt-4">
                        <h5 class="card-title mb-0 section-title"><i class="fas fa-chalkboard me-2"></i>Seleccione una Clase para Registrar Asistencia</h5>
                    </div>
                    <div class="card-body">
                        <% if (clasesDelProfesor.isEmpty()) { %>
                            <div class="empty-state">
                                <i class="fas fa-exclamation-circle"></i>
                                <h4>No tiene clases asignadas actualmente.</h4>
                                <p class="text-muted">Por favor, contacte con administración si cree que esto es un error.</p>
                            </div>
                        <% } else { %>
                            <div class="row row-cols-1 row-cols-md-2 row-cols-lg-3 g-4"> <%-- Grid for class cards --%>
                                <% for (Map<String, String> clase : clasesDelProfesor) { %>
                                    <div class="col">
                                        <a href="asistencia_profesor.jsp?id_clase=<%= clase.get("id_clase") %>" class="text-decoration-none">
                                            <div class="card h-100 class-card">
                                                <div class="card-body d-flex flex-column">
                                                    <h5 class="card-title"><%= clase.get("nombre_curso") %></h5>
                                                    <p class="card-text mb-1"><strong>Sección:</strong> <%= clase.get("seccion") %></p>
                                                    <p class="card-text mb-1"><strong>Semestre:</strong> <%= clase.get("semestre") %> (<%= clase.get("anio_academico") %>)</p>
                                                    <p class="card-text mb-2"><strong>Aula:</strong> <%= clase.get("aula") %></p>
                                                    <div class="mt-auto text-end">
                                                        <i class="fas fa-arrow-circle-right action-icon"></i>
                                                    </div>
                                                </div>
                                            </div>
                                        </a>
                                    </div>
                                <% } %>
                            </div>
                        <% } %>
                    </div>
                </div>
            <% } else { %>
                <div class="card content-section mb-4">
                    <div class="card-header d-flex flex-wrap justify-content-between align-items-center bg-white border-bottom-0 pt-4">
                        <h5 class="card-title mb-2 section-title"><i class="fas fa-chalkboard-teacher me-2"></i>Asistencia de <%= nombreClase %></h5>
                        <span class="text-muted fs-6"><i class="fas fa-calendar-alt me-1"></i> Fecha: <%= fechaActualDisplay %></span>
                        <div class="w-100 text-muted mt-1">
                            <small>Código: <%= codigoClase %> | Aula: <%= aulaClase %> | Semestre: <%= semestreClase %> (<%= anioAcademicoClase %>)</small>
                        </div>
                    </div>
                    <div class="card-body">
                        <% if (estudiantesDeClase.isEmpty()) { %>
                            <div class="empty-state">
                                <i class="fas fa-user-times"></i>
                                <h4>No hay alumnos inscritos en esta clase para registrar asistencia hoy.</h4>
                                <p class="text-muted">Verifique las inscripciones o regrese más tarde.</p>
                                <div class="mt-4">
                                    <a href="asistencia_profesor.jsp" class="btn btn-secondary btn-lg"><i class="fas fa-arrow-left me-2"></i> Volver a Clases</a>
                                </div>
                            </div>
                        <% } else { %>
                            <form method="post" action="asistencia_profesor.jsp?id_clase=<%= idClaseParam %>">
                                <input type="hidden" name="fecha_asistencia_db" value="<%= fechaActualDB %>">
                                <div class="table-responsive" style="max-height: 500px; overflow-y: auto;"> <%-- Added scroll for table --%>
                                    <table class="table table-hover table-asistencia caption-top">
                                        <caption>Lista de Alumnos</caption>
                                        <thead>
                                            <tr>
                                                <th>#</th>
                                                <th>DNI</th>
                                                <th>Nombre Completo</th>
                                                <th class="text-center" style="min-width: 150px;">Estado</th>
                                                <th style="min-width: 200px;">Observaciones</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <% int contador = 1; %>
                                            <% for (Map<String, String> estudiante : estudiantesDeClase) { %>
                                                <tr>
                                                    <td><%= contador++ %></td>
                                                    <td><%= estudiante.get("dni") %></td>
                                                    <td><%= estudiante.get("nombre_completo") %></td>
                                                    <td>
                                                        <div class="btn-group btn-group-sm btn-group-asistencia w-100" role="group">
                                                            <input type="radio" class="btn-check" id="presente_<%= estudiante.get("id_inscripcion") %>"
                                                                name="estado_<%= estudiante.get("id_inscripcion") %>" value="presente" autocomplete="off"
                                                                <%= "presente".equals(estudiante.get("estado_asistencia")) ? "checked" : "" %>>
                                                            <label class="btn btn-outline-success" for="presente_<%= estudiante.get("id_inscripcion") %>">P</label>

                                                            <input type="radio" class="btn-check" id="ausente_<%= estudiante.get("id_inscripcion") %>"
                                                                name="estado_<%= estudiante.get("id_inscripcion") %>" value="ausente" autocomplete="off"
                                                                <%= "ausente".equals(estudiante.get("estado_asistencia")) || estudiante.get("estado_asistencia").isEmpty() ? "checked" : "" %>> <%-- Default to Ausente --%>
                                                            <label class="btn btn-outline-danger" for="ausente_<%= estudiante.get("id_inscripcion") %>">F</label>

                                                            <input type="radio" class="btn-check" id="tardanza_<%= estudiante.get("id_inscripcion") %>"
                                                                name="estado_<%= estudiante.get("id_inscripcion") %>" value="tardanza" autocomplete="off"
                                                                <%= "tardanza".equals(estudiante.get("estado_asistencia")) ? "checked" : "" %>>
                                                            <label class="btn btn-outline-warning" for="tardanza_<%= estudiante.get("id_inscripcion") %>">T</label>

                                                            <input type="radio" class="btn-check" id="justificado_<%= estudiante.get("id_inscripcion") %>"
                                                                name="estado_<%= estudiante.get("id_inscripcion") %>" value="justificado" autocomplete="off"
                                                                <%= "justificado".equals(estudiante.get("estado_asistencia")) ? "checked" : "" %>>
                                                            <label class="btn btn-outline-info" for="justificado_<%= estudiante.get("id_inscripcion") %>">J</label>
                                                        </div>
                                                    </td>
                                                    <td>
                                                        <div class="form-floating">
                                                            <input type="text" class="form-control form-control-sm" id="observaciones_<%= estudiante.get("id_inscripcion") %>"
                                                                name="observaciones_<%= estudiante.get("id_inscripcion") %>" placeholder="Observaciones"
                                                                value="<%= estudiante.get("observaciones") != null ? estudiante.get("observaciones") : "" %>">
                                                            <label for="observaciones_<%= estudiante.get("id_inscripcion") %>">Observaciones</label>
                                                        </div>
                                                    </td>
                                                </tr>
                                            <% } %>
                                        </tbody>
                                    </table>
                                </div>
                                <div class="mt-4 d-flex flex-wrap gap-3 justify-content-center">
                                    <button type="submit" class="btn btn-primary btn-lg px-4"><i class="fas fa-save me-2"></i> Guardar Asistencia</button>
                                    <a href="asistencia_profesor.jsp" class="btn btn-secondary btn-lg px-4"><i class="fas fa-arrow-left me-2"></i> Volver a Clases</a>
                                </div>
                            </form>
                        <% } %>
                    </div>
                </div>
            <% } %>
        </div>
    </div>
</div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>