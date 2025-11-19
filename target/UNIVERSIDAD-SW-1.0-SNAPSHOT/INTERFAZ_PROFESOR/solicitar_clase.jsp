<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, pe.universidad.util.Conection" %>
<%@ page session="true" %>

<%!
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
%>

<%
    // Validar sesión
    String emailProfesorSesion = (String) session.getAttribute("email");
    String rolUsuario = (String) session.getAttribute("rol");
    Object idProfesorObj = session.getAttribute("id_profesor");
    int idProfesor = (idProfesorObj instanceof Integer) ? (Integer) idProfesorObj : -1;

    // Redirigir si el usuario no es profesor o el ID no es válido
    if (!"profesor".equals(rolUsuario) || idProfesor == -1) {
        response.sendRedirect(request.getContextPath() + "/login.jsp"); // Ajusta esta ruta si es diferente
        return;
    }

    String nombreProfesor = "";
    String facultadProfesor = ""; // Para mostrar en la navbar/sidebar

    String successMsg = null; // Mensaje de éxito o error de la solicitud POST

    // --- LÓGICA PARA PROCESAR ENVÍO POST DE LA SOLICITUD ---
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        Connection connPost = null; // Conexión separada para el POST
        PreparedStatement pstmtPost = null;
        try {
            // Obtener parámetros del formulario
            String curso = request.getParameter("curso");
            String seccion = request.getParameter("seccion");
            String ciclo = request.getParameter("ciclo");
            String semestre = request.getParameter("semestre");
            int anio = Integer.parseInt(request.getParameter("anio"));
            String dia = request.getParameter("dia");
            String horaInicio = request.getParameter("hora_inicio");
            String horaFin = request.getParameter("hora_fin");
            String aula = request.getParameter("aula");
            int capacidad = Integer.parseInt(request.getParameter("capacidad"));

            // Validaciones básicas de campos (más robustas con Bootstrap)
            if (curso == null || curso.trim().isEmpty() || seccion == null || seccion.trim().isEmpty() ||
                ciclo == null || ciclo.trim().isEmpty() || semestre == null || semestre.trim().isEmpty() ||
                dia == null || dia.trim().isEmpty() || horaInicio == null || horaInicio.trim().isEmpty() ||
                horaFin == null || horaFin.trim().isEmpty() || aula == null || aula.trim().isEmpty()) {
                successMsg = "❌ Error: Por favor, completa todos los campos obligatorios.";
            } else if (anio < 1900 || anio > 2100) { // Validación de rango de año
                successMsg = "❌ Error: Año académico inválido.";
            } else if (capacidad <= 0) {
                successMsg = "❌ Error: La capacidad debe ser un número positivo.";
            } else {
                connPost = new Conection().conecta();
                if (connPost == null || connPost.isClosed()) {
                    throw new SQLException("Fallo al conectar con la base de datos.");
                }

                // Inserción en la tabla solicitudes_clases
                String sqlInsert = "INSERT INTO solicitudes_clases ("
                                 + "id_profesor, curso, seccion, ciclo, semestre, anio_academico, "
                                 + "dia_semana, hora_inicio, hora_fin, aula, capacidad, estado_solicitud, fecha_solicitud) " // Agregado fecha_solicitud
                                 + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())"; // NOW() para la fecha actual

                pstmtPost = connPost.prepareStatement(sqlInsert);
                pstmtPost.setInt(1, idProfesor);
                pstmtPost.setString(2, curso);
                pstmtPost.setString(3, seccion);
                pstmtPost.setString(4, ciclo);
                pstmtPost.setString(5, semestre);
                pstmtPost.setInt(6, anio);
                pstmtPost.setString(7, dia);
                pstmtPost.setString(8, horaInicio);
                pstmtPost.setString(9, horaFin);
                pstmtPost.setString(10, aula);
                pstmtPost.setInt(11, capacidad);
                pstmtPost.setString(12, "pendiente"); // Estado inicial (en minúsculas según tu ENUM)

                int rowsAffected = pstmtPost.executeUpdate();
                if (rowsAffected > 0) {
                    successMsg = "✅ Solicitud enviada correctamente. Espera la aprobación del administrador.";
                } else {
                    successMsg = "❌ No se pudo registrar la solicitud. Intenta de nuevo.";
                }
            }
        } catch (NumberFormatException e) {
            successMsg = "❌ Error en el formato de año o capacidad. Asegúrate de que sean números válidos.";
            e.printStackTrace();
        } catch (SQLException e) {
            successMsg = "❌ Error de base de datos al enviar la solicitud: " + e.getMessage();
            e.printStackTrace();
        } catch (ClassNotFoundException e) {
            successMsg = "❌ Error de configuración: Driver JDBC no encontrado.";
            e.printStackTrace();
        } finally {
            closeDbResources(null, pstmtPost);
            if (connPost != null) { try { connPost.close(); } catch (SQLException ignore) {} }
        }
    }

    // --- LÓGICA PARA OBTENER DATOS DEL PROFESOR (para la interfaz) ---
    Connection connMain = null; // Conexión para obtener datos de interfaz
    PreparedStatement pstmtMain = null;
    ResultSet rsMain = null;

    try {
        connMain = new Conection().conecta();
        if (connMain == null || connMain.isClosed()) {
            throw new SQLException("No se pudo establecer conexión a la base de datos para la interfaz.");
        }

        String sqlProfesorInfo = "SELECT p.nombre, p.apellido_paterno, p.apellido_materno, p.email, f.nombre_facultad "
                               + "FROM profesores p LEFT JOIN facultades f ON p.id_facultad = f.id_facultad "
                               + "WHERE p.id_profesor = ?";
        pstmtMain = connMain.prepareStatement(sqlProfesorInfo);
        pstmtMain.setInt(1, idProfesor);
        rsMain = pstmtMain.executeQuery();

        if (rsMain.next()) {
            String nom = rsMain.getString("nombre");
            String apP = rsMain.getString("apellido_paterno");
            String apM = rsMain.getString("apellido_materno");
            nombreProfesor = (nom + " " + apP + (apM != null ? " " + apM : "")).trim();
            facultadProfesor = rsMain.getString("nombre_facultad") != null ? rsMain.getString("nombre_facultad") : "Sin asignar";
            // emailProfesorSesion ya está asignado desde la sesión
        }
    } catch (SQLException e) {
        successMsg = (successMsg == null ? "" : successMsg + " | ") + "Error al cargar datos del profesor: " + e.getMessage();
        e.printStackTrace();
    } catch (ClassNotFoundException e) {
        successMsg = (successMsg == null ? "" : successMsg + " | ") + "Error de driver al cargar datos del profesor.";
        e.printStackTrace();
    } finally {
        closeDbResources(rsMain, pstmtMain);
        if (connMain != null) { try { connMain.close(); } catch (SQLException ignore) {} }
    }
%>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Solicitar Clase - Sistema Universitario</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.6.0/jquery.min.js"></script>
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

        /* Form Card */
        .form-card.card {
            border-radius: 0.5rem;
            box-shadow: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.075);
            border-left: 4px solid var(--admin-primary);
        }

        .form-title {
            color: var(--admin-primary);
            font-weight: 600;
            margin-bottom: 1.5rem;
            display: flex;
            align-items: center;
            gap: 0.75rem;
            justify-content: center;
        }
        .form-title i {
            font-size: 1.8rem;
        }

        /* Form elements */
        .form-label {
            font-weight: 500;
            color: var(--admin-text-dark);
        }
        .form-control, .form-select {
            border-radius: 0.3rem;
            border-color: #dee2e6;
            padding: 0.75rem 1rem;
        }
        .form-control:focus, .form-select:focus {
            border-color: var(--admin-primary);
            box-shadow: 0 0 0 0.25rem rgba(0, 123, 255, 0.25);
        }

        /* Buttons */
        .btn-submit {
            background-color: var(--admin-primary);
            color: white;
            padding: 0.8rem 2rem;
            border-radius: 0.3rem;
            font-weight: 600;
            transition: background-color 0.2s ease, transform 0.2s ease;
        }
        .btn-submit:hover {
            background-color: #0056b3;
            transform: translateY(-2px);
        }
        .btn-back {
            background-color: var(--admin-secondary-color);
            color: white;
            padding: 0.8rem 2rem;
            border-radius: 0.3rem;
            font-weight: 600;
            transition: background-color 0.2s ease;
        }
        .btn-back:hover {
            background-color: #5a6268;
        }

        /* Message Box */
        .message-box {
            border-radius: 0.5rem;
            padding: 1rem 1.5rem;
            margin-bottom: 1.5rem;
            font-weight: 500;
        }
        .message-box.success { background-color: rgba(40, 167, 69, 0.1); border-color: var(--admin-success); color: var(--admin-success); }
        .message-box.error { background-color: rgba(220, 53, 69, 0.1); border-color: var(--admin-danger); color: var(--admin-danger); }


        /* Horario Checker (The Surprise) */
        .horario-checker-card {
            border-left: 4px solid var(--admin-info);
            box-shadow: 0 0.125rem 0.25rem rgba(0,0,0,0.075);
            border-radius: 0.5rem;
            padding: 1.5rem;
            margin-bottom: 1.5rem;
            text-align: center;
        }
        .horario-checker-card .result-icon {
            font-size: 3rem;
            margin-bottom: 1rem;
        }
        .horario-checker-card .result-message {
            font-size: 1.1rem;
            font-weight: 600;
            color: var(--admin-text-dark);
        }
        .horario-checker-card .result-detail {
            font-size: 0.9rem;
            color: var(--admin-text-muted);
        }


        /* Responsive adjustments */
        @media (max-width: 992px) {
            .sidebar { width: 220px; }
            .main-content { padding: 1rem; }
            .form-card { max-width: 90%; }
        }

        @media (max-width: 768px) {
            #app { flex-direction: column; }
            .sidebar { width: 100%; height: auto; position: relative; box-shadow: 0 2px 5px rgba(0,0,0,0.1); padding-bottom: 0.5rem; }
            .sidebar .nav-link { justify-content: center; padding: 0.6rem 1rem; }
            .sidebar .nav-link i { margin-right: 0.5rem; }
            .top-navbar { flex-direction: column; align-items: flex-start; }
            .top-navbar .search-bar { width: 100%; margin-bottom: 1rem; }
            .top-navbar .user-dropdown { width: 100%; text-align: center; }
            .top-navbar .user-dropdown .dropdown-toggle { justify-content: center; }
            .form-row > .col { flex-basis: 100%; } /* Stack form columns */
        }

        @media (max-width: 576px) {
            .main-content { padding: 0.75rem; }
            .welcome-section, .form-card.card { padding: 1rem; }
            .btn-submit, .btn-back { padding: 0.7rem 1.5rem; font-size: 1rem; }
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
                    <h1 class="h3 mb-3">Solicitar Nueva Clase</h1>
                    <p class="lead">Completa este formulario para enviar una solicitud de creación de nueva clase. Será revisada por el administrador.</p>
                </div>

                <% if (successMsg != null) { %>
                <div class="alert <%= successMsg.startsWith("✅") ? "alert-success" : "alert-danger" %> alert-dismissible fade show" role="alert">
                    <%= successMsg %>
                    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                </div>
                <% } %>

                <div class="card form-card">
                    <div class="card-body">
                        <h2 class="form-title"><i class="fas fa-file-alt"></i> Formulario de Solicitud de Clase</h2>

                        <form method="post" onsubmit="return validarFormulario();">
                            <input type="hidden" name="id_profesor" value="<%= idProfesor %>">

                            <div class="row g-3 mb-3">
                                <div class="col-md-6">
                                    <label for="curso" class="form-label">Curso</label>
                                    <input type="text" name="curso" id="curso" class="form-control" required placeholder="Ej: Programación I">
                                </div>
                                <div class="col-md-6">
                                    <label for="seccion" class="form-label">Sección</label>
                                    <input type="text" name="seccion" id="seccion" class="form-control" required placeholder="Ej: A, B">
                                </div>
                            </div>

                            <div class="row g-3 mb-3">
                                <div class="col-md-4">
                                    <label for="ciclo" class="form-label">Ciclo</label>
                                    <input type="text" name="ciclo" id="ciclo" class="form-control" required placeholder="Ej: I, II">
                                </div>
                                <div class="col-md-4">
                                    <label for="semestre" class="form-label">Semestre</label>
                                    <input type="text" name="semestre" id="semestre" class="form-control" placeholder="Ej: 2025-1" required>
                                </div>
                                <div class="col-md-4">
                                    <label for="anio" class="form-label">Año Académico</label>
                                    <input type="number" name="anio" id="anio" class="form-control" value="<%= java.time.Year.now().getValue() %>" required>
                                </div>
                            </div>

                            <div class="row g-3 mb-3">
                                <div class="col-md-4">
                                    <label for="dia" class="form-label">Día de la semana</label>
                                    <select name="dia" id="dia" class="form-select" required>
                                        <option value="">-- Seleccionar --</option>
                                        <option value="lunes">Lunes</option>
                                        <option value="martes">Martes</option>
                                        <option value="miercoles">Miércoles</option>
                                        <option value="jueves">Jueves</option>
                                        <option value="viernes">Viernes</option>
                                        <option value="sabado">Sábado</option>
                                        <option value="domingo">Domingo</option>
                                    </select>
                                </div>
                                <div class="col-md-4">
                                    <label for="hora_inicio" class="form-label">Hora de inicio</label>
                                    <input type="time" name="hora_inicio" id="hora_inicio" class="form-control" required>
                                </div>
                                <div class="col-md-4">
                                    <label for="hora_fin" class="form-label">Hora de fin</label>
                                    <input type="time" name="hora_fin" id="hora_fin" class="form-control" required>
                                </div>
                            </div>

                            <div class="row g-3 mb-3">
                                <div class="col-md-6">
                                    <label for="aula" class="form-label">Aula</label>
                                    <input type="text" name="aula" id="aula" class="form-control" required placeholder="Ej: A101">
                                </div>
                                <div class="col-md-6">
                                    <label for="capacidad" class="form-label">Capacidad del aula</label>
                                    <input type="number" name="capacidad" id="capacidad" class="form-control" required placeholder="Ej: 30" min="1">
                                </div>
                            </div>

                            <div class="row g-3 mb-3">
                                <div class="col-12 text-center">
                                    <button type="button" class="btn btn-info" id="checkHorarioBtn"><i class="fas fa-check-circle me-2"></i>Verificar Disponibilidad de Horario</button>
                                </div>
                                <div class="col-12 mt-3" id="horarioCheckResult" style="display:none;">
                                    <div class="horario-checker-card">
                                        <div id="checkResultIcon" class="result-icon text-muted"></div>
                                        <div id="checkResultMessage" class="result-message"></div>
                                        <div id="checkResultDetail" class="result-detail"></div>
                                    </div>
                                </div>
                            </div>

                            <div class="button-group text-center mt-4">
                                <button type="submit" class="btn btn-submit"><i class="fas fa-paper-plane me-2"></i>Enviar Solicitud</button>
                                <a href="salones_profesor.jsp" class="btn btn-back ms-3"><i class="fas fa-arrow-left me-2"></i>Volver a Clases</a>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js" integrity="sha384-YvpcrYf0tY3lHB60NNkmXc5s9fDVZLESaAA55NDzOxhy9GkcIdslK1eN7N6jIeHz" crossorigin="anonymous"></script>
    <script>
        $(document).ready(function() {
            // Función para validar el formulario antes de enviar (revisado con Bootstrap clases)
            function validarFormulario() {
                const requiredFields = ['curso', 'seccion', 'ciclo', 'semestre', 'anio', 'dia', 'hora_inicio', 'hora_fin', 'aula', 'capacidad'];
                let isValid = true;

                requiredFields.forEach(function(fieldId) {
                    const field = $('#' + fieldId);
                    if (field.val().trim() === '') {
                        field.addClass('is-invalid');
                        isValid = false;
                    } else {
                        field.removeClass('is-invalid');
                    }
                });

                const anio = $('#anio').val();
                if (!/^\d{4}$/.test(anio)) {
                    $('#anio').addClass('is-invalid');
                    isValid = false;
                } else {
                    $('#anio').removeClass('is-invalid');
                }

                const capacidad = parseInt($('#capacidad').val());
                if (isNaN(capacidad) || capacidad <= 0) {
                    $('#capacidad').addClass('is-invalid');
                    isValid = false;
                } else {
                    $('#capacidad').removeClass('is-invalid');
                }

                if (!isValid) {
                    // Muestra una alerta general si falla la validación
                    $('.message-box.error').remove(); // Elimina mensajes anteriores
                    const msg = '<div class="message-box error alert alert-danger" role="alert"><i class="fas fa-exclamation-circle me-2"></i>Por favor, completa todos los campos correctamente.</div>';
                    $(msg).insertBefore('.form-card');
                    $('html, body').animate({
                        scrollTop: $('.message-box.error').offset().top - 100
                    }, 500); // Scroll a la alerta
                } else {
                    $('.message-box.error').remove(); // Oculta mensajes de error si todo es válido
                }

                return isValid;
            }

            // Evento para el botón de verificar disponibilidad
            $('#checkHorarioBtn').on('click', function() {
                const dia = $('#dia').val();
                const horaInicio = $('#hora_inicio').val();
                const horaFin = $('#hora_fin').val();
                const aula = $('#aula').val();
                const anio = $('#anio').val();
                const semestre = $('#semestre').val();
                const idProfesor = '<%= idProfesor %>'; // Obtener idProfesor del JSP

                const resultContainer = $('#horarioCheckResult');
                const resultIcon = $('#checkResultIcon');
                const resultMessage = $('#checkResultMessage');
                const resultDetail = $('#checkResultDetail');

                // Validar que los campos de horario estén llenos para la verificación
                if (dia === '' || horaInicio === '' || horaFin === '' || aula.trim() === '' || anio.trim() === '' || semestre.trim() === '') {
                    resultIcon.html('<i class="fas fa-exclamation-triangle text-warning"></i>');
                    resultMessage.text('Completa Día, Hora Inicio, Hora Fin, Aula, Año y Semestre para verificar.');
                    resultDetail.text('');
                    resultContainer.show().removeClass('alert-success alert-danger').addClass('alert-warning');
                    return;
                }

                // Mostrar spinner de carga
                resultIcon.html('<div class="spinner-border text-primary" role="status"><span class="visually-hidden">Cargando...</span></div>');
                resultMessage.text('Verificando disponibilidad...');
                resultDetail.text('');
                resultContainer.show().removeClass('alert-success alert-danger alert-warning');


                // Realizar la llamada AJAX al endpoint que vamos a crear
                $.ajax({
                    url: '<%= request.getContextPath() %>/api/verificarHorarioDisponible', // ¡IMPORTANTE! Crea este endpoint
                    type: 'GET',
                    data: {
                        idProfesor: idProfesor,
                        dia: dia,
                        horaInicio: horaInicio,
                        horaFin: horaFin,
                        aula: aula,
                        anio: anio,
                        semestre: semestre
                    },
                    dataType: 'json',
                    success: function(response) {
                        if (response.status === 'libre') {
                            resultIcon.html('<i class="fas fa-check-circle text-success"></i>');
                            resultMessage.text('Horario Disponible');
                            resultDetail.text('No hay clases ni solicitudes pendientes para este horario y aula.');
                            resultContainer.removeClass('alert-danger alert-warning').addClass('alert-success');
                        } else if (response.status === 'ocupado_clase') {
                            resultIcon.html('<i class="fas fa-times-circle text-danger"></i>');
                            resultMessage.text('Horario Ocupado por Clase Asignada');
                            resultDetail.text('Ya tienes la clase "' + response.clase_nombre + '" (' + response.clase_codigo + ') en el aula ' + response.clase_aula + '.');
                            resultContainer.removeClass('alert-success alert-warning').addClass('alert-danger');
                        } else if (response.status === 'ocupado_solicitud') {
                            resultIcon.html('<i class="fas fa-exclamation-circle text-warning"></i>');
                            resultMessage.text('Horario Ocupado por Solicitud Pendiente');
                            resultDetail.text('Ya existe una solicitud pendiente para la clase "' + response.solicitud_nombre + '" (' + response.solicitud_codigo + ') en el aula ' + response.solicitud_aula + '.');
                            resultContainer.removeClass('alert-success alert-danger').addClass('alert-warning');
                        } else {
                            // Fallback para cualquier otro estado inesperado
                            resultIcon.html('<i class="fas fa-question-circle text-secondary"></i>');
                            resultMessage.text('Resultado desconocido.');
                            resultDetail.text(response.message || '');
                            resultContainer.removeClass('alert-success alert-danger').addClass('alert-warning');
                        }
                    },
                    error: function(xhr, status, error) {
                        resultIcon.html('<i class="fas fa-exclamation-triangle text-danger"></i>');
                        resultMessage.text('Error al verificar horario.');
                        resultDetail.text('Intenta de nuevo o contacta a soporte. ' + (xhr.responseJSON && xhr.responseJSON.error ? xhr.responseJSON.error : ''));
                        resultContainer.removeClass('alert-success alert-warning').addClass('alert-danger');
                        console.error("AJAX Error:", status, error, xhr.responseText);
                    }
                });
            });

            // Eliminar clases de validación al escribir en los campos
            $('input, select').on('input change', function() {
                $(this).removeClass('is-invalid');
                $('.message-box.error').remove(); // Ocultar mensaje de error al empezar a escribir
            });
        });
    </script>
</body>
</html>