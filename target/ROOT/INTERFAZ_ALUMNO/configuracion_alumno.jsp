<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, pe.universidad.util.Conection" %>
<%@ page import="java.net.URLEncoder" %>
<%@ page import="java.nio.charset.StandardCharsets" %>
<%@ page import="java.time.LocalDateTime" %>
<%@ page import="java.time.format.DateTimeFormatter" %>
<%@ page import="java.time.LocalDate" %>
<%@ page import="java.util.Locale" %>
<%@ page session="true" %>

<%!
    // Método para cerrar recursos de BD
    private static void cerrarRecursos(ResultSet rs, PreparedStatement pstmt) {
        try { if (rs != null) { rs.close(); } } catch (SQLException e) { /* Ignorar */ }
        try { if (pstmt != null) { pstmt.close(); } } catch (SQLException e) { /* Ignorar */ }
    }
%>

<%
    // --- Obtener información de la sesión ---
    String emailSesion = (String) session.getAttribute("email");
    String rolUsuario = (String) session.getAttribute("rol");
    Object idAlumnoObj = session.getAttribute("id_alumno"); // Changed from idApoderadoObj

    if (emailSesion == null || !"alumno".equalsIgnoreCase(rolUsuario) || idAlumnoObj == null) { // Changed rol check
        response.sendRedirect(request.getContextPath() + "/login.jsp"); // Redirect if not authenticated as alumno
        return;
    }

    int idAlumno = -1; // Changed from idApoderado
    try {
        idAlumno = Integer.parseInt(String.valueOf(idAlumnoObj));
    } catch (NumberFormatException e) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?error=" + URLEncoder.encode("ID de alumno inválido en sesión.", StandardCharsets.UTF_8.toString())); // Changed message
        return;
    }

    // --- Variables para los datos del alumno (se usarán para pre-rellenar el formulario y en la barra superior) ---
    String nombre = "";
    String apellidoPaterno = "";
    String apellidoMaterno = "";
    String dni = ""; // Read-only
    String telefono = "";
    String currentEmail = emailSesion;
    String fechaNacimiento = ""; // Added
    String direccion = ""; // Added

    String nombreAlumno = (String) session.getAttribute("nombre_alumno"); // Changed from nombre_apoderado
    if (nombreAlumno == null || nombreAlumno.isEmpty()) {
        nombreAlumno = "Alumno"; // Default value if not in session or load fails
    }

    // --- Feedback messages (after POST or if there are GET load errors) ---
    String message = request.getParameter("message");
    String messageType = request.getParameter("type"); // success or danger

    Connection conn = null; // Main connection declaration
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    try {
        Conection c = new Conection();
        conn = c.conecta(); // Attempt to connect to DB

        if (conn == null || conn.isClosed()) {
            throw new SQLException("No se pudo establecer conexión a la base de datos."); // Force an error if connection fails
        }

        // --- Logic for HANDLING POST REQUEST (Form Submission for Update) ---
        if ("POST".equalsIgnoreCase(request.getMethod())) {
            String formType = request.getParameter("form_type"); // 'profile_update' or 'password_change'

            if ("profile_update".equals(formType)) {
                String newNombre = request.getParameter("nombre");
                String newApellidoPaterno = request.getParameter("apellido_paterno");
                String newApellidoMaterno = request.getParameter("apellido_materno");
                String newTelefono = request.getParameter("telefono");
                String newFechaNacimientoStr = request.getParameter("fecha_nacimiento"); // Added
                String newDireccion = request.getParameter("direccion"); // Added

                // Validate required fields (can be more robust with regex, etc.)
                if (newNombre == null || newNombre.trim().isEmpty() ||
                    newApellidoPaterno == null || newApellidoPaterno.trim().isEmpty() ||
                    newTelefono == null || newTelefono.trim().isEmpty() ||
                    newFechaNacimientoStr == null || newFechaNacimientoStr.trim().isEmpty() || // Validate date
                    newDireccion == null || newDireccion.trim().isEmpty()) {
                    
                    message = "Todos los campos obligatorios (Nombre, Apellido Paterno, Teléfono, Fecha de Nacimiento, Dirección) deben ser llenados.";
                    messageType = "danger";
                } else {
                    java.sql.Date sqlFechaNacimiento = null;
                    try {
                        sqlFechaNacimiento = java.sql.Date.valueOf(newFechaNacimientoStr);
                    } catch (IllegalArgumentException e) {
                        message = "Formato de Fecha de Nacimiento inválido. Usa YYYY-MM-DD.";
                        messageType = "danger";
                    }

                    if (messageType == null || !messageType.equals("danger")) { // Only proceed if no date format error
                        String updateSql = "UPDATE alumnos SET nombre = ?, apellido_paterno = ?, apellido_materno = ?, telefono = ?, fecha_nacimiento = ?, direccion = ? WHERE id_alumno = ?"; // Updated table and fields
                        pstmt = conn.prepareStatement(updateSql);
                        pstmt.setString(1, newNombre);
                        pstmt.setString(2, newApellidoPaterno);
                        pstmt.setString(3, newApellidoMaterno);
                        pstmt.setString(4, newTelefono);
                        pstmt.setDate(5, sqlFechaNacimiento); // Set date
                        pstmt.setString(6, newDireccion); // Set direccion
                        pstmt.setInt(7, idAlumno); // Filter by idAlumno

                        int rowsAffected = pstmt.executeUpdate();
                        if (rowsAffected > 0) {
                            message = "¡Perfil actualizado exitosamente!";
                            messageType = "success";
                            // Update session attribute for display in top navbar immediately
                            session.setAttribute("nombre_alumno", newNombre + " " + newApellidoPaterno + (newApellidoMaterno != null && !newApellidoMaterno.isEmpty() ? " " + newApellidoMaterno : ""));
                        } else {
                            message = "No se pudo actualizar el perfil. No se realizaron cambios.";
                            messageType = "danger";
                        }
                    }
                }
                cerrarRecursos(null, pstmt); // Close pstmt after use

            } else if ("password_change".equals(formType)) {
                String currentPassword = request.getParameter("current_password");
                String newPassword = request.getParameter("new_password");
                String confirmNewPassword = request.getParameter("confirm_new_password");

                if (!newPassword.equals(confirmNewPassword)) {
                    message = "Las nuevas contraseñas no coinciden.";
                    messageType = "danger";
                } else if (newPassword.length() < 6) {
                    message = "La nueva contraseña debe tener al menos 6 caracteres.";
                    messageType = "danger";
                }
                else {
                    // --- IMPORTANT: Hash and verify passwords ---
                    // This is a placeholder. In a real application, NEVER store passwords in plaintext.
                    // Use a strong hashing algorithm (e.g., bcrypt) when saving and verifying passwords.
                    String checkPassSql = "SELECT password FROM alumnos WHERE id_alumno = ?"; // Changed table
                    pstmt = conn.prepareStatement(checkPassSql);
                    pstmt.setInt(1, idAlumno);
                    rs = pstmt.executeQuery();
                    if (rs.next() && rs.getString("password").equals(currentPassword)) { // Plaintext comparison (BAD for real app)
                        String updatePassSql = "UPDATE alumnos SET password = ? WHERE id_alumno = ?"; // Changed table
                        cerrarRecursos(rs, pstmt); // Close previous resources before new pstmt
                        pstmt = conn.prepareStatement(updatePassSql);
                        pstmt.setString(1, newPassword); // Should be hashed newPassword
                        pstmt.setInt(2, idAlumno);
                        int rowsAffected = pstmt.executeUpdate();
                        if (rowsAffected > 0) {
                            message = "¡Contraseña actualizada exitosamente!";
                            messageType = "success";
                        } else {
                            message = "No se pudo actualizar la contraseña. Intenta de nuevo.";
                            messageType = "danger";
                        }
                    } else {
                        message = "La contraseña actual es incorrecta.";
                        messageType = "danger";
                    }
                    cerrarRecursos(rs, pstmt);
                }
            }
            // After POST processing, redirect to avoid form resubmission
            response.sendRedirect(request.getContextPath() + "/INTERFAZ_ALUMNO/configuracion_alumno.jsp?message=" + URLEncoder.encode(message, StandardCharsets.UTF_8.toString()) + "&type=" + URLEncoder.encode(messageType, StandardCharsets.UTF_8.toString())); // Changed path
            return; // Important! Terminate JSP execution here for POST request
        }

        // --- Logic for LOADING DATA (Initial GET request or after POST redirect) ---
        // Load data to pre-fill the form
        String sqlAlumnoDatos = "SELECT dni, nombre, apellido_paterno, apellido_materno, telefono, email, fecha_nacimiento, direccion " + // Added
                               "FROM alumnos WHERE id_alumno = ?"; // Changed table
        pstmt = conn.prepareStatement(sqlAlumnoDatos);
        pstmt.setInt(1, idAlumno);
        rs = pstmt.executeQuery();

        if (rs.next()) {
            nombre = rs.getString("nombre") != null ? rs.getString("nombre") : "";
            apellidoPaterno = rs.getString("apellido_paterno") != null ? rs.getString("apellido_paterno") : "";
            apellidoMaterno = rs.getString("apellido_materno") != null ? rs.getString("apellido_materno") : "";
            dni = rs.getString("dni") != null ? rs.getString("dni") : ""; // DNI usually not editable
            telefono = rs.getString("telefono") != null ? rs.getString("telefono") : "";
            currentEmail = rs.getString("email") != null ? rs.getString("email") : emailSesion;
            
            java.sql.Date fechaNacimientoSql = rs.getDate("fecha_nacimiento"); // Added
            if (fechaNacimientoSql != null) {
                fechaNacimiento = fechaNacimientoSql.toString(); // Format to YYYY-MM-DD for input type="date"
            } else {
                fechaNacimiento = ""; // Empty string for no date
            }
            direccion = rs.getString("direccion") != null ? rs.getString("direccion") : ""; // Added
            
        } else {
            message = "No se encontraron datos para configurar el perfil.";
            messageType = "danger";
        }
        cerrarRecursos(rs, pstmt);

    } catch (SQLException e) {
        message = "Error de base de datos al cargar/guardar la configuración: " + e.getMessage();
        messageType = "danger";
        System.err.println("SQLException en configuracion_alumno.jsp: " + e.getMessage()); // Changed log
        e.printStackTrace();
    } catch (ClassNotFoundException e) {
        message = "Error de conexión: No se encontró el driver JDBC de MySQL. Asegúrate de que el conector esté en WEB-INF/lib.";
        messageType = "danger";
        System.err.println("ClassNotFoundException en configuracion_alumno.jsp: " + e.getMessage()); // Changed log
        e.printStackTrace();
    } finally {
        try {
            if (conn != null) {
                conn.close();
            }
        } catch (SQLException e) {
            System.err.println("Error al cerrar la conexión en finally: " + e.getMessage());
            e.printStackTrace();
        }
    }
%>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Configuración de Alumno | Sistema Universitario</title> <link rel="icon" type="image/x-icon" href="<%= request.getContextPath() %>/img/favicon.ico">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        /* Shared CSS Variables */
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

        /* Content Card Styling */
        .content-card.card {
            border-radius: 0.5rem;
            box-shadow: 0 0.125rem 0.25rem rgba(0,0,0,0.075);
            border-left: 4px solid var(--admin-primary);
            margin-bottom: 1.5rem;
        }
        .content-card.card .card-title {
            color: var(--admin-primary);
            font-weight: 600;
            margin-bottom: 1rem;
        }

        /* Form styling */
        .form-label {
            font-weight: 600;
            color: var(--admin-text-dark);
        }
        .form-control {
            border-radius: 0.3rem;
            border-color: #dee2e6;
            padding: 0.75rem 1rem;
        }
        .form-control:focus {
            border-color: var(--admin-primary);
            box-shadow: 0 0 0 0.25rem rgba(0, 123, 255, 0.25);
        }

        /* Buttons */
        .btn-primary-custom {
            background-color: var(--admin-primary);
            color: white;
            padding: 0.75rem 1.5rem;
            border-radius: 0.3rem;
            transition: background-color 0.2s ease, transform 0.2s ease;
        }
        .btn-primary-custom:hover {
            background-color: #0056b3;
            transform: translateY(-2px);
            color: white;
        }
        .btn-secondary-custom {
            background-color: var(--admin-secondary-color);
            color: white;
            padding: 0.75rem 1.5rem;
            border-radius: 0.3rem;
            transition: background-color 0.2s ease, transform 0.2s ease;
        }
        .btn-secondary-custom:hover {
            background-color: #5a6268;
            transform: translateY(-2px);
            color: white;
        }

        /* Alert messages */
        .alert-custom {
            padding: 1rem 1.5rem;
            margin-bottom: 1.5rem;
            border-radius: 0.375rem;
        }
        .alert-success-custom {
            background-color: rgba(40, 167, 69, 0.1);
            border-color: var(--admin-success);
            color: var(--admin-success);
        }
        .alert-danger-custom {
            background-color: rgba(220, 53, 69, 0.1);
            border-color: var(--admin-danger);
            color: var(--admin-danger);
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
            .content-card.card { padding: 1.5rem 1rem; }
        }
        @media (max-width: 576px) {
            .main-content { padding: 0.75rem; }
            .welcome-section, .content-card.card { padding: 1rem;}
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
                    <a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_ALUMNO/notas_alumno.jsp"><i class="fas fa-percent"></i><span> Mis Notas</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_ALUMNO/pagos_alumno.jsp"><i class="fas fa-money-bill-wave"></i><span> Mis Pagos</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_ALUMNO/mensajes_alumno.jsp"><i class="fas fa-envelope"></i><span> Mensajes</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link active" href="<%= request.getContextPath() %>/INTERFAZ_ALUMNO/perfil_alumno.jsp"><i class="fas fa-user"></i><span> Mi Perfil</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_ALUMNO/configuracion_alumno.jsp"><i class="fas fa-cog"></i><span> Configuración</span></a>
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
                           <input class="form-control me-2" type="search" placeholder="Buscar..." aria-label="Search">
                           <button class="btn btn-outline-secondary" type="submit"><i class="fas fa-search"></i></button>
                    </form>
                </div>
                <div class="d-flex align-items-center">
                    <div class="me-3 dropdown">
                            <a class="text-dark" href="#" role="button" id="notificationsDropdown" data-bs-toggle="dropdown" aria-expanded="false">
                                <i class="fas fa-bell fa-lg"></i>
                                <%-- If you want to show a badge count, ensure it's dynamically populated --%>
                                <%-- <span class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger">3</span> --%>
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
                                <%-- If you want to show a badge count, ensure it's dynamically populated --%>
                                <%-- <span class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger">2</span> --%>
                            </a>
                            <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="messagesDropdown">
                                <li><a class="dropdown-item" href="mensajes_alumno.jsp">Mensaje de Profesor X</a></li>
                                <li><a class="dropdown-item" href="mensajes_alumno.jsp">Mensaje de Administración</a></li>
                                <li><hr class="dropdown-divider"></li>
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
                            <li><a class="dropdown-item" href="logout.jsp"><i class="fas fa-sign-out-alt me-2"></i>Cerrar sesión</a></li>
                        </ul>
                    </div>
                </div>
            </nav>

            <div class="container-fluid">
                <div class="welcome-section">
                    <h1 class="h3 mb-3"><i class="fas fa-cog me-2"></i>Configuración de Mi Cuenta</h1> <p class="lead">Gestiona tu información personal y contraseña.</p>
                </div>

                <% if (message != null) { %>
                    <div class="alert <%= "success".equals(messageType) ? "alert-success-custom" : "alert-danger-custom" %> alert-dismissible fade show alert-custom" role="alert">
                        <i class="fas <%= "success".equals(messageType) ? "fa-check-circle" : "fa-exclamation-triangle" %> me-2"></i>
                        <%= message %>
                        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                    </div>
                <% } %>

                <div class="card content-card mb-4">
                    <div class="card-body">
                        <h5 class="card-title mb-4"><i class="fas fa-user-edit me-2"></i>Actualizar Información de Perfil</h5>
                        <form action="<%= request.getContextPath() %>/INTERFAZ_ALUMNO/configuracion_alumno.jsp" method="post"> <input type="hidden" name="form_type" value="profile_update">
                            <div class="row g-3">
                                <div class="col-md-4">
                                    <label for="nombre" class="form-label">Nombre(s):</label>
                                    <input type="text" class="form-control" id="nombre" name="nombre" value="<%= nombre %>" required>
                                </div>
                                <div class="col-md-4">
                                    <label for="apellido_paterno" class="form-label">Apellido Paterno:</label>
                                    <input type="text" class="form-control" id="apellido_paterno" name="apellido_paterno" value="<%= apellidoPaterno %>" required>
                                </div>
                                <div class="col-md-4">
                                    <label for="apellido_materno" class="form-label">Apellido Materno:</label>
                                    <input type="text" class="form-control" id="apellido_materno" name="apellido_materno" value="<%= apellidoMaterno %>">
                                </div>
                                <div class="col-md-6">
                                    <label for="dni" class="form-label">DNI:</label>
                                    <input type="text" class="form-control" id="dni" name="dni" value="<%= dni %>" readonly disabled>
                                    <div class="form-text">El DNI no se puede modificar directamente.</div>
                                </div>
                                <div class="col-md-6">
                                    <label for="email" class="form-label">Correo Electrónico:</label>
                                    <input type="email" class="form-control" id="email" name="email" value="<%= currentEmail %>" readonly disabled>
                                    <div class="form-text">El correo es tu usuario y no se puede modificar aquí.</div>
                                </div>
                                <div class="col-md-6">
                                    <label for="telefono" class="form-label">Teléfono:</label>
                                    <input type="text" class="form-control" id="telefono" name="telefono" value="<%= telefono %>">
                                </div>
                                <div class="col-md-6">
                                    <label for="fecha_nacimiento" class="form-label">Fecha de Nacimiento:</label>
                                    <input type="date" class="form-control" id="fecha_nacimiento" name="fecha_nacimiento" value="<%= fechaNacimiento %>" required>
                                </div>
                                <div class="col-md-12">
                                    <label for="direccion" class="form-label">Dirección:</label>
                                    <input type="text" class="form-control" id="direccion" name="direccion" value="<%= direccion %>" required>
                                </div>
                                <div class="col-12 text-end mt-4">
                                    <button type="submit" class="btn btn-primary-custom"><i class="fas fa-save me-2"></i>Guardar Cambios</button>
                                </div>
                            </div>
                        </form>
                    </div>
                </div>

                <div class="card content-card">
                    <div class="card-body">
                        <h5 class="card-title mb-4"><i class="fas fa-key me-2"></i>Cambiar Contraseña</h5>
                        <form action="<%= request.getContextPath() %>/INTERFAZ_ALUMNO/configuracion_alumno.jsp" method="post"> <input type="hidden" name="form_type" value="password_change">
                            <div class="mb-3">
                                <label for="current_password" class="form-label">Contraseña Actual:</label>
                                <input type="password" class="form-control" id="current_password" name="current_password" required>
                            </div>
                            <div class="mb-3">
                                <label for="new_password" class="form-label">Nueva Contraseña:</label>
                                <input type="password" class="form-control" id="new_password" name="new_password" required minlength="6">
                            </div>
                            <div class="mb-3">
                                <label for="confirm_new_password" class="form-label">Confirmar Nueva Contraseña:</label>
                                <input type="password" class="form-control" id="confirm_new_password" name="confirm_new_password" required minlength="6">
                            </div>
                            <div class="text-end mt-4">
                                <button type="submit" class="btn btn-primary-custom"><i class="fas fa-unlock-alt me-2"></i>Cambiar Contraseña</button>
                            </div>
                        </form>
                    </div>
                </div>

            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js" integrity="sha384-YvpcrYf0tY3lHB60NNkmXc5s9fDVZLESaAA55NDzOxhy9GkcIdslK1eN7N6jIeHz" crossorigin="anonymous"></script>
</body>
</html>