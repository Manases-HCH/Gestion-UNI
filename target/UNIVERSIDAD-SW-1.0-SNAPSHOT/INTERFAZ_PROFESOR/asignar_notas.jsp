<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, pe.universidad.util.Conection" %>
<%@ page session="true" %>

<%!
    // Método auxiliar para cerrar ResultSet y PreparedStatement de forma segura.
    private void closeDbResources(ResultSet rs, PreparedStatement pstmt) {
        try { if (rs != null) rs.close(); } catch (SQLException e) { /* Ignorar */ }
        try { if (pstmt != null) pstmt.close(); } catch (SQLException e) { /* Ignorar */ }
    }

    // Mover localErrorMessage y successMessage aquí para que sean campos de la clase generada.
    // Esto garantiza su visibilidad en todos los bloques try-catch dentro del JSP.
    String localErrorMessage = null;
    String successMessage = null;
%>

<%
    // NO declarar localErrorMessage o successMessage aquí de nuevo
    // String localErrorMessage = null; // REMOVER ESTA LÍNEA
    // String successMessage = null; // REMOVER ESTA LÍNEA

    // --- VALIDACIÓN DE SESIÓN ---
    String emailSesion = (String) session.getAttribute("email");
    String rolUsuario = (String) session.getAttribute("rol");
    Object idProfesorObj = session.getAttribute("id_profesor");

    if (emailSesion == null || !"profesor".equalsIgnoreCase(rolUsuario) || idProfesorObj == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    int idProfesor = (Integer) idProfesorObj;

    // Datos del profesor para la navbar
    String nombreProfesor = "Profesor";
    String facultadProfesor = "Sin asignar";

    // --- Obtener id_clase y id_alumno de la URL ---
    int idClase = -1;
    int idAlumno = -1;
    String idClaseParam = request.getParameter("id_clase");
    String idAlumnoParam = request.getParameter("id_alumno");

    // Reinicializar los mensajes al inicio de cada petición
    localErrorMessage = null; // Es importante reinicializarlos si son campos de clase
    successMessage = null;   // para evitar arrastrar mensajes de peticiones anteriores.

    try {
        if (idClaseParam != null && !idClaseParam.isEmpty()) {
            idClase = Integer.parseInt(idClaseParam);
        } else {
            localErrorMessage = "No se proporcionó un ID de clase.";
        }
        if (idAlumnoParam != null && !idAlumnoParam.isEmpty()) {
            idAlumno = Integer.parseInt(idAlumnoParam);
        } else {
            localErrorMessage = (localErrorMessage == null ? "" : localErrorMessage + " ") + "No se proporcionó un ID de alumno.";
        }
    } catch (NumberFormatException e) {
        localErrorMessage = "IDs (clase/alumno) inválidos.";
    }

    // Variables para información de contexto
    String nombreCurso = "Curso Desconocido";
    String seccionClase = "";
    String nombreCompletoAlumno = "Alumno Desconocido";
    int idInscripcion = -1;

    // Mapa para almacenar las notas
    Map<String, String> notasAlumno = new HashMap<>();
    notasAlumno.put("nota1", "");
    notasAlumno.put("nota2", "");
    notasAlumno.put("nota3", "");
    notasAlumno.put("examen_parcial", "");
    notasAlumno.put("examen_final", "");
    notasAlumno.put("nota_final", "Pendiente");
    notasAlumno.put("estado_nota", "Pendiente");

    Connection conn = null;

    try {
        Conection conUtil = new Conection();
        conn = conUtil.conecta();

        if (conn == null || conn.isClosed()) {
            throw new SQLException("No se pudo establecer conexión a la base de datos.");
        }

        // --- Cargar datos del profesor para la navbar (omito para brevedad) ---

        // --- Procesar envío de formulario de notas (si es POST) ---
        if ("POST".equalsIgnoreCase(request.getMethod())) {
            if (idClase != -1 && idAlumno != -1) {
                PreparedStatement pstmtGetInsc = null;
                ResultSet rsGetInsc = null;
                try {
                    String sqlGetInsc = "SELECT id_inscripcion FROM inscripciones WHERE id_clase = ? AND id_alumno = ?";
                    pstmtGetInsc = conn.prepareStatement(sqlGetInsc);
                    pstmtGetInsc.setInt(1, idClase);
                    pstmtGetInsc.setInt(2, idAlumno);
                    rsGetInsc = pstmtGetInsc.executeQuery();
                    if (rsGetInsc.next()) {
                        idInscripcion = rsGetInsc.getInt("id_inscripcion");
                    } else {
                        localErrorMessage = "Inscripción no encontrada para la clase y alumno especificados.";
                    }
                } finally {
                    closeDbResources(rsGetInsc, pstmtGetInsc);
                }

                if (idInscripcion != -1 && localErrorMessage == null) {
                    String nota1Str = request.getParameter("nota1");
                    String nota2Str = request.getParameter("nota2");
                    String nota3Str = request.getParameter("nota3");
                    String examenParcialStr = request.getParameter("examen_parcial");
                    String examenFinalStr = request.getParameter("examen_final");

                    Double nota1 = (nota1Str != null && !nota1Str.isEmpty()) ? Double.parseDouble(nota1Str) : null;
                    Double nota2 = (nota2Str != null && !nota2Str.isEmpty()) ? Double.parseDouble(nota2Str) : null;
                    Double nota3 = (nota3Str != null && !nota3Str.isEmpty()) ? Double.parseDouble(nota3Str) : null;
                    Double examenParcial = (examenParcialStr != null && !examenParcialStr.isEmpty()) ? Double.parseDouble(examenParcialStr) : null;
                    Double examenFinal = (examenFinalStr != null && !examenFinalStr.isEmpty()) ? Double.parseDouble(examenFinalStr) : null;

                    PreparedStatement pstmtUpdateNotas = null;
                    try {
                        String sqlCheckNotas = "SELECT id_nota FROM notas WHERE id_inscripcion = ?";
                        pstmtUpdateNotas = conn.prepareStatement(sqlCheckNotas);
                        pstmtUpdateNotas.setInt(1, idInscripcion);
                        ResultSet rsCheckNotas = pstmtUpdateNotas.executeQuery();

                        if (rsCheckNotas.next()) {
                            String sqlUpdate = "UPDATE notas SET nota1=?, nota2=?, nota3=?, examen_parcial=?, examen_final=? WHERE id_inscripcion = ?";
                            pstmtUpdateNotas = conn.prepareStatement(sqlUpdate);
                            if (nota1 != null) pstmtUpdateNotas.setDouble(1, nota1); else pstmtUpdateNotas.setNull(1, Types.DECIMAL);
                            if (nota2 != null) pstmtUpdateNotas.setDouble(2, nota2); else pstmtUpdateNotas.setNull(2, Types.DECIMAL);
                            if (nota3 != null) pstmtUpdateNotas.setDouble(3, nota3); else pstmtUpdateNotas.setNull(3, Types.DECIMAL);
                            if (examenParcial != null) pstmtUpdateNotas.setDouble(4, examenParcial); else pstmtUpdateNotas.setNull(4, Types.DECIMAL);
                            if (examenFinal != null) pstmtUpdateNotas.setDouble(5, examenFinal); else pstmtUpdateNotas.setNull(5, Types.DECIMAL);
                            pstmtUpdateNotas.setInt(6, idInscripcion);
                        } else {
                            String sqlInsert = "INSERT INTO notas (id_inscripcion, nota1, nota2, nota3, examen_parcial, examen_final) VALUES (?, ?, ?, ?, ?, ?)";
                            pstmtUpdateNotas = conn.prepareStatement(sqlInsert);
                            pstmtUpdateNotas.setInt(1, idInscripcion);
                            if (nota1 != null) pstmtUpdateNotas.setDouble(2, nota1); else pstmtUpdateNotas.setNull(2, Types.DECIMAL);
                            if (nota2 != null) pstmtUpdateNotas.setDouble(3, nota2); else pstmtUpdateNotas.setNull(3, Types.DECIMAL);
                            if (nota3 != null) pstmtUpdateNotas.setDouble(4, nota3); else pstmtUpdateNotas.setNull(4, Types.DECIMAL);
                            if (examenParcial != null) pstmtUpdateNotas.setDouble(5, examenParcial); else pstmtUpdateNotas.setNull(5, Types.DECIMAL);
                            if (examenFinal != null) pstmtUpdateNotas.setDouble(6, examenFinal); else pstmtUpdateNotas.setNull(6, Types.DECIMAL);
                        }
                        
                        int rowsAffected = pstmtUpdateNotas.executeUpdate();
                        if (rowsAffected > 0) {
                            successMessage = "Notas guardadas/actualizadas correctamente.";
                        } else {
                            localErrorMessage = "No se pudo guardar/actualizar las notas.";
                        }
                    } catch (NumberFormatException nfe) {
                        localErrorMessage = "Una o más notas no son números válidos."; // Error here
                    } finally {
                        closeDbResources(null, pstmtUpdateNotas); // rsCheckNotas ya se cerró con el closeDbResources del if
                    }
                }
            } else {
                localErrorMessage = "Faltan ID de clase o ID de alumno para guardar notas.";
            }
        } // Fin del if POST

        // --- Cargar información de la clase y el alumno para el contexto ---
        if (idClase != -1 && idAlumno != -1 && localErrorMessage == null) {
            PreparedStatement pstmtInfo = null;
            ResultSet rsInfo = null;
            try {
                String sqlInfo = "SELECT cl.seccion, cu.nombre_curso, "
                               + "CONCAT(a.nombre, ' ', a.apellido_paterno, ' ', IFNULL(a.apellido_materno, '')) AS nombre_alumno_completo, "
                               + "i.id_inscripcion "
                               + "FROM clases cl "
                               + "JOIN cursos cu ON cl.id_curso = cu.id_curso "
                               + "JOIN inscripciones i ON cl.id_clase = i.id_clase "
                               + "JOIN alumnos a ON i.id_alumno = a.id_alumno "
                               + "WHERE cl.id_clase = ? AND a.id_alumno = ? AND cl.id_profesor = ?";
                pstmtInfo = conn.prepareStatement(sqlInfo);
                pstmtInfo.setInt(1, idClase);
                pstmtInfo.setInt(2, idAlumno);
                pstmtInfo.setInt(3, idProfesor);
                rsInfo = pstmtInfo.executeQuery();
                if (rsInfo.next()) {
                    nombreCurso = rsInfo.getString("nombre_curso");
                    seccionClase = rsInfo.getString("seccion");
                    nombreCompletoAlumno = rsInfo.getString("nombre_alumno_completo");
                    idInscripcion = rsInfo.getInt("id_inscripcion");
                } else {
                    localErrorMessage = "Clase o alumno no encontrado para este profesor.";
                }
            } finally {
                closeDbResources(rsInfo, pstmtInfo);
            }

            // --- Cargar notas existentes del alumno para mostrarlas en el formulario ---
            if (idInscripcion != -1 && localErrorMessage == null) {
                PreparedStatement pstmtNotas = null;
                ResultSet rsNotas = null;
                try {
                    String sqlNotas = "SELECT nota1, nota2, nota3, examen_parcial, examen_final, nota_final, estado FROM notas WHERE id_inscripcion = ?";
                    pstmtNotas = conn.prepareStatement(sqlNotas);
                    pstmtNotas.setInt(1, idInscripcion);
                    rsNotas = pstmtNotas.executeQuery();
                    if (rsNotas.next()) {
                        notasAlumno.put("nota1", rsNotas.getString("nota1") != null ? rsNotas.getString("nota1") : "");
                        notasAlumno.put("nota2", rsNotas.getString("nota2") != null ? rsNotas.getString("nota2") : "");
                        notasAlumno.put("nota3", rsNotas.getString("nota3") != null ? rsNotas.getString("nota3") : "");
                        notasAlumno.put("examen_parcial", rsNotas.getString("examen_parcial") != null ? rsNotas.getString("examen_parcial") : "");
                        notasAlumno.put("examen_final", rsNotas.getString("examen_final") != null ? rsNotas.getString("examen_final") : "");
                        notasAlumno.put("nota_final", rsNotas.getString("nota_final") != null ? rsNotas.getString("nota_final") : "Pendiente");
                        notasAlumno.put("estado_nota", rsNotas.getString("estado") != null ? rsNotas.getString("estado") : "Pendiente");
                    }
                } finally {
                    closeDbResources(rsNotas, pstmtNotas);
                }
            }
        }

    } catch (SQLException e) {
        localErrorMessage = "Error de base de datos: " + e.getMessage();
        e.printStackTrace();
    } catch (ClassNotFoundException e) {
        localErrorMessage = "Error: No se encontró el driver JDBC de MySQL. Asegúrate de que mysql-connector-java.jar esté en WEB-INF/lib.";
        e.printStackTrace();
    } finally {
        try { if (conn != null) conn.close(); } catch (SQLException ignore) { /* Ignorar */ }
    }
%>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Asignar Notas - Sistema Universitario</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        /* Reutiliza tus estilos CSS existentes */
        :root {
            --admin-dark: #222B40; --admin-light-bg: #F0F2F5; --admin-card-bg: #FFFFFF;
            --admin-text-dark: #333333; --admin-text-muted: #6C757D;
            --admin-primary: #007BFF; --admin-success: #28A745; --admin-danger: #DC3545;
            --admin-warning: #FFC107; --admin-info: #17A2B8; --admin-secondary-color: #6C757D;
        }
        body { font-family: 'Inter', sans-serif; background-color: var(--admin-light-bg); color: var(--admin-text-dark); min-height: 100vh; display: flex; flex-direction: column; overflow-x: hidden; }
        #app { display: flex; flex: 1; width: 100%; }
        .sidebar { width: 280px; background-color: var(--admin-dark); color: rgba(255, 255, 255, 0.8); padding-top: 1rem; flex-shrink: 0; position: sticky; top: 0; left: 0; height: 100vh; overflow-y: auto; box-shadow: 2px 0 5px rgba(0,0,0,0.1); z-index: 1030; }
        .sidebar-header { padding: 1rem 1.5rem; margin-bottom: 1.5rem; text-align: center; font-size: 1.5rem; font-weight: 700; color: var(--admin-primary); border-bottom: 1px solid rgba(255, 255, 255, 0.05); }
        .sidebar .nav-link { display: flex; align-items: center; padding: 0.75rem 1.5rem; color: rgba(255, 255, 255, 0.7); text-decoration: none; transition: all 0.2s ease-in-out; font-weight: 500; }
        .sidebar .nav-link i { margin-right: 0.75rem; font-size: 1.1rem; }
        .sidebar .nav-link:hover, .sidebar .nav-link.active { color: white; background-color: rgba(255, 255, 255, 0.08); border-left: 4px solid var(--admin-primary); padding-left: 1.3rem; }
        .main-content { flex: 1; padding: 1.5rem; overflow-y: auto; display: flex; flex-direction: column; }
        .top-navbar { background-color: var(--admin-card-bg); padding: 1rem 1.5rem; box-shadow: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.075); margin-bottom: 1.5rem; border-radius: 0.5rem; display: flex; justify-content: space-between; align-items: center; }
        .top-navbar .search-bar .form-control { border: 1px solid #e0e0e0; border-radius: 0.3rem; padding: 0.5rem 1rem; }
        .top-navbar .user-dropdown .dropdown-toggle { display: flex; align-items: center; color: var(--admin-text-dark); text-decoration: none; }
        .top-navbar .user-dropdown .dropdown-toggle img { width: 32px; height: 32px; border-radius: 50%; margin-right: 0.5rem; object-fit: cover; border: 2px solid var(--admin-primary); }
        .welcome-section { background-color: var(--admin-card-bg); border-radius: 0.5rem; padding: 1.5rem; margin-bottom: 1.5rem; box-shadow: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.075); }
        .welcome-section h1 { color: var(--admin-text-dark); font-weight: 600; margin-bottom: 0.5rem; }
        .welcome-section p.lead { color: var(--admin-text-muted); font-size: 1rem; }
        .content-section.card { border-radius: 0.5rem; box-shadow: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.075); border-left: 4px solid var(--admin-primary); }
        .section-title { color: var(--admin-primary); margin-bottom: 1rem; font-weight: 600; }
        .form-label { font-weight: 500; }
        .btn-action { margin-top: 1rem; }
        .btn-back {
            background-color: var(--admin-secondary-color);
            color: white;
            padding: 0.75rem 1.5rem;
            border-radius: 0.5rem;
            text-decoration: none;
            transition: background-color 0.2s ease;
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
        }
        .btn-back:hover {
            background-color: #5a6268;
            color: white;
        }
        /* Responsive adjustments */
        @media (max-width: 992px) { .sidebar { width: 220px; } .main-content { padding: 1rem; } }
        @media (max-width: 768px) {
            #app { flex-direction: column; } .sidebar { width: 100%; height: auto; position: relative; box-shadow: 0 2px 5px rgba(0,0,0,0.1); padding-bottom: 0.5rem; }
            .sidebar .nav-link { justify-content: center; padding: 0.6rem 1rem; } .sidebar .nav-link i { margin-right: 0.5rem; }
            .top-navbar { flex-direction: column; align-items: flex-start; } .top-navbar .search-bar { width: 100%; margin-bottom: 1rem; }
            .top-navbar .user-dropdown { width: 100%; text-align: center; } .top-navbar .user-dropdown .dropdown-toggle { justify-content: center; }
        }
        @media (max-width: 576px) { .main-content { padding: 0.75rem; } .welcome-section, .card { padding: 1rem; } }
    </style>
</head>
<body>
    <div id="app">
        <nav class="sidebar">
            <div class="sidebar-header">
                <a href="home_profesor.jsp" class="text-white text-decoration-none">UGIC Portal</a>
            </div>

            <ul class="navbar-nav">
                <li class="nav-item"><a class="nav-link" href="home_profesor.jsp"><i class="fas fa-chart-line"></i><span> Dashboard</span></a></li>
                <li class="nav-item"><a class="nav-link" href="facultad_profesor.jsp"><i class="fas fa-building"></i><span> Facultades</span></a></li>
                <li class="nav-item"><a class="nav-link" href="carreras_profesor.jsp"><i class="fas fa-graduation-cap"></i><span> Carreras</span></a></li>
                <li class="nav-item"><a class="nav-link" href="cursos_profesor.jsp"><i class="fas fa-book"></i><span> Cursos</span></a></li>
                <li class="nav-item"><a class="nav-link active" href="salones_profesor.jsp"><i class="fas fa-chalkboard"></i><span> Clases</span></a></li>
                <li class="nav-item"><a class="nav-link" href="horarios_profesor.jsp"><i class="fas fa-calendar-alt"></i><span> Horarios</span></a></li>
                <li class="nav-item"><a class="nav-link" href="asistencia_profesor.jsp"><i class="fas fa-clipboard-check"></i><span> Asistencia</span></a></li>
                <li class="nav-item"><a class="nav-link" href="mensaje_profesor.jsp"><i class="fas fa-envelope"></i><span> Mensajería</span></a></li>
                <li class="nav-item"><a class="nav-link" href="nota_profesor.jsp"><i class="fas fa-percent"></i><span> Notas</span></a></li>
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
                        <input class="form-control me-2" type="search" placeholder="Buscar..." aria-label="Search">
                        <button class="btn btn-outline-secondary" type="submit"><i class="fas fa-search"></i></button>
                    </form>
                </div>
                <div class="d-flex align-items-center">
                    <div class="me-3 dropdown">
                        <a class="text-dark" href="#" role="button" id="notificationsDropdown" data-bs-toggle="dropdown" aria-expanded="false">
                            <i class="fas fa-bell fa-lg"></i>
                            <span class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger">3</span>
                        </a>
                        <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="notificationsDropdown">
                            <li><a class="dropdown-item" href="#">Nueva notificación</a></li>
                            <li><a class="dropdown-item" href="#">Recordatorio</a></li>
                            <li><hr class="dropdown-divider"></li>
                            <li><a class="dropdown-item" href="#">Ver todas</a></li>
                        </ul>
                    </div>
                    <div class="me-3 dropdown">
                        <a class="text-dark" href="#" role="button" id="messagesDropdown" data-bs-toggle="dropdown" aria-expanded="false">
                            <i class="fas fa-envelope fa-lg"></i>
                            <span class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger">2</span>
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
                            <img src="https://via.placeholder.com/32" alt="Avatar"> <span class="d-none d-md-inline-block"><%= nombreProfesor%></span>
                        </a>
                        <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="userDropdown">
                            <li><a class="dropdown-item" href="#"><i class="fas fa-user me-2"></i>Perfil</a></li>
                            <li><a class="dropdown-item" href="#"><i class="fas fa-cog me-2"></i>Configuración</a></li>
                            <li><hr class="dropdown-divider"></li>
                            <li><a class="dropdown-item" href="logout.jsp"><i class="fas fa-sign-out-alt me-2"></i>Cerrar sesión</a></li>
                        </ul>
                    </div>
                </div>
            </nav>

            <div class="container-fluid">
                <div class="welcome-section">
                    <h1 class="h3 mb-3">Asignar Notas</h1>
                    <p class="lead">Gestiona las notas para <strong><%= nombreCompletoAlumno %></strong> en el curso <strong><%= nombreCurso %></strong> (Sección: <%= seccionClase %>).</p>
                </div>

                <% if (localErrorMessage != null) { %>
                    <div class="alert alert-danger alert-error-message" role="alert">
                        <i class="fas fa-exclamation-triangle me-2"></i>Error: <%= localErrorMessage %>
                    </div>
                <% } else if (successMessage != null) { %>
                    <div class="alert alert-success" role="alert">
                        <i class="fas fa-check-circle me-2"></i><%= successMessage %>
                    </div>
                <% } %>

                <div class="card content-section">
                    <div class="card-body">
                        <h3 class="section-title card-title"><i class="fas fa-edit me-2"></i>Formulario de Notas</h3>
                        <form method="post" action="asignar_notas.jsp?id_clase=<%= idClase %>&id_alumno=<%= idAlumno %>">
                            <div class="row">
                                <div class="col-md-4 mb-3">
                                    <label for="nota1" class="form-label">Nota 1:</label>
                                    <input type="number" step="0.01" min="0" max="20" class="form-control" id="nota1" name="nota1" value="<%= notasAlumno.get("nota1") %>" placeholder="Nota 1">
                                </div>
                                <div class="col-md-4 mb-3">
                                    <label for="nota2" class="form-label">Nota 2:</label>
                                    <input type="number" step="0.01" min="0" max="20" class="form-control" id="nota2" name="nota2" value="<%= notasAlumno.get("nota2") %>" placeholder="Nota 2">
                                </div>
                                <div class="col-md-4 mb-3">
                                    <label for="nota3" class="form-label">Nota 3:</label>
                                    <input type="number" step="0.01" min="0" max="20" class="form-control" id="nota3" name="nota3" value="<%= notasAlumno.get("nota3") %>" placeholder="Nota 3">
                                </div>
                            </div>
                            <div class="row">
                                <div class="col-md-6 mb-3">
                                    <label for="examen_parcial" class="form-label">Examen Parcial:</label>
                                    <input type="number" step="0.01" min="0" max="20" class="form-control" id="examen_parcial" name="examen_parcial" value="<%= notasAlumno.get("examen_parcial") %>" placeholder="Examen Parcial">
                                </div>
                                <div class="col-md-6 mb-3">
                                    <label for="examen_final" class="form-label">Examen Final:</label>
                                    <input type="number" step="0.01" min="0" max="20" class="form-control" id="examen_final" name="examen_final" value="<%= notasAlumno.get("examen_final") %>" placeholder="Examen Final">
                                </div>
                            </div>
                            <div class="row mb-3">
                                <div class="col-md-6">
                                    <p class="form-label"><strong>Nota Final:</strong> <span class="badge bg-primary fs-6"><%= notasAlumno.get("nota_final") %></span></p>
                                </div>
                                <div class="col-md-6">
                                    <p class="form-label"><strong>Estado:</strong> <span class="badge bg-info fs-6"><%= notasAlumno.get("estado_nota").toUpperCase() %></span></p>
                                </div>
                            </div>
                            
                            <button type="submit" class="btn btn-primary btn-action"><i class="fas fa-save me-2"></i>Guardar Notas</button>
                        </form>
                    </div>
                </div>

                <div class="text-start mt-4 mb-4">
                    <a href="ver_estudiantes.jsp?id_clase=<%= idClase %>" class="btn btn-back">
                        <i class="fas fa-arrow-left me-2"></i>Volver a Estudiantes de la Clase
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