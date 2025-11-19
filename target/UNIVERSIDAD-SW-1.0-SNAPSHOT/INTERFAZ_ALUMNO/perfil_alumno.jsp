<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, pe.universidad.util.Conection" %>
<%@ page import="java.time.LocalDateTime, java.time.format.DateTimeFormatter" %>
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
        response.sendRedirect(request.getContextPath() + "/login.jsp"); // Redirect to login if not authenticated as alumno
        return;
    }

    int idAlumno = -1; // Changed from idApoderado
    try {
        idAlumno = Integer.parseInt(String.valueOf(idAlumnoObj));
    } catch (NumberFormatException e) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?error=" + java.net.URLEncoder.encode("ID de alumno inválido en sesión.", "UTF-8")); // Changed message
        return;
    }

    // --- Variables para los datos del alumno ---
    String nombreAlumno = "Alumno Desconocido"; // Changed from nombreApoderado
    String dniAlumno = "N/A";
    String emailAlumno = emailSesion;
    String telefonoAlumno = "N/A";
    String fechaNacimientoAlumno = "N/A";
    String direccionAlumno = "N/A";
    String carreraAlumno = "N/A";
    String facultadAlumno = "N/A";
    String estadoAlumno = "N/A";
    String fechaRegistroAlumno = "N/A";
    String ultimoAcceso = "Ahora";
    String profileLoadError = null;

    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    try {
        Conection c = new Conection();
        conn = c.conecta();

        if (conn == null || conn.isClosed()) {
            throw new SQLException("No se pudo establecer conexión a la base de datos.");
        }

        // --- 1. Obtener Datos del Alumno (combinando datos personales y académicos) ---
        String sqlAlumno = "SELECT al.dni, al.nombre, al.apellido_paterno, al.apellido_materno, al.telefono, al.email, al.fecha_registro, " +
                          "al.fecha_nacimiento, al.direccion, ca.nombre_carrera, fa.nombre_facultad, al.estado " +
                          "FROM alumnos al " +
                          "JOIN carreras ca ON al.id_carrera = ca.id_carrera " +
                          "JOIN facultades fa ON ca.id_facultad = fa.id_facultad " +
                          "WHERE al.id_alumno = ?";
        pstmt = conn.prepareStatement(sqlAlumno);
        pstmt.setInt(1, idAlumno); // Use idAlumno
        rs = pstmt.executeQuery();

        if (rs.next()) {
            String nombre = rs.getString("nombre") != null ? rs.getString("nombre") : "";
            String apPaterno = rs.getString("apellido_paterno") != null ? rs.getString("apellido_paterno") : "";
            String apMaterno = rs.getString("apellido_materno") != null ? rs.getString("apellido_materno") : "";

            nombreAlumno = nombre + " " + apPaterno;
            if (!apMaterno.isEmpty()) {
                nombreAlumno += " " + apMaterno;
            }

            dniAlumno = rs.getString("dni") != null ? rs.getString("dni") : "N/A";
            telefonoAlumno = rs.getString("telefono") != null ? rs.getString("telefono") : "N/A";
            emailAlumno = rs.getString("email") != null ? rs.getString("email") : emailSesion;
            
            Timestamp registroTimestamp = rs.getTimestamp("fecha_registro");
            if (registroTimestamp != null) {
                fechaRegistroAlumno = new java.text.SimpleDateFormat("dd/MM/yyyy HH:mm").format(registroTimestamp);
            } else {
                fechaRegistroAlumno = "N/A";
            }

            java.sql.Date fechaNacimientoSql = rs.getDate("fecha_nacimiento");
            if (fechaNacimientoSql != null) {
                fechaNacimientoAlumno = new java.text.SimpleDateFormat("dd/MM/yyyy").format(fechaNacimientoSql);
            } else {
                fechaNacimientoAlumno = "N/A";
            }

            direccionAlumno = rs.getString("direccion") != null ? rs.getString("direccion") : "N/A";
            carreraAlumno = rs.getString("nombre_carrera") != null ? rs.getString("nombre_carrera") : "N/A";
            facultadAlumno = rs.getString("nombre_facultad") != null ? rs.getString("nombre_facultad") : "N/A";
            estadoAlumno = rs.getString("estado") != null ? rs.getString("estado") : "N/A";

        } else {
            profileLoadError = "No se encontraron tus datos de alumno."; // Changed message
            // If alumno does not exist, redirect
            response.sendRedirect(request.getContextPath() + "/login.jsp?error=" + java.net.URLEncoder.encode(profileLoadError, "UTF-8"));
            return;
        }
        cerrarRecursos(rs, pstmt);

        // Obtener la fecha actual para "Último acceso"
        ultimoAcceso = LocalDateTime.now().format(DateTimeFormatter.ofPattern("EEEE, d 'de' MMMM 'de'yyyy, HH:mm", new Locale("es", "ES")));

    } catch (SQLException | ClassNotFoundException e) {
        profileLoadError = "Error al cargar los datos de tu perfil: " + e.getMessage(); // Changed message
        e.printStackTrace();
    } finally {
        cerrarRecursos(rs, pstmt);
        try { if (conn != null) conn.close(); } catch (SQLException e) { /* Ignorar */ }
    }
%>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mi Perfil | Sistema Universitario</title> <link rel="icon" type="image/x-icon" href="<%= request.getContextPath() %>/img/favicon.ico">
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
        .content-card.card .card-header {
             background-color: var(--admin-card-bg);
             border-bottom: 1px solid #dee2e6;
             padding-bottom: 1rem;
        }
        .content-card.card .card-title {
            color: var(--admin-primary);
            font-weight: 600;
            margin-bottom: 1rem;
        }

        /* Profile details styling */
        .profile-detail-row {
            padding: 0.5rem 0;
            border-bottom: 1px dashed #e0e0e0;
        }
        .profile-detail-row:last-child {
            border-bottom: none;
        }
        .profile-detail-row strong {
            color: var(--admin-text-dark);
            font-weight: 600;
        }
        .profile-detail-row span {
            color: var(--admin-text-muted);
        }

        /* Edit Profile Button */
        .btn-edit-profile {
            background-color: var(--admin-info);
            color: white;
            padding: 0.75rem 1.5rem;
            border-radius: 0.3rem;
            transition: background-color 0.2s ease, transform 0.2s ease;
        }
        .btn-edit-profile:hover {
            background-color: #138496;
            transform: translateY(-2px);
        }

        /* Error message styling */
        .alert-error-message {
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
            .profile-detail-row { flex-direction: column; align-items: flex-start; }
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
                <li class="nav-item active">
                    <a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_ALUMNO/perfil_alumno.jsp"><i class="fas fa-user"></i><span> Mi Perfil</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_ALUMNO/configuracion_alumno.jsp"><i class="fas fa-cog"></i><span> Configuración</span></a>
                </li>
                <li class="nav-item mt-3">
                    <form action="<%= request.getContextPath() %>/logout.jsp" method="post" class="d-grid gap-2">
                        <button type="submit" class="btn btn-outline-light mx-3"><i class="fas fa-sign-out-alt me-2"></i>Cerrar sesión</button>
                    </form>
                </li>
            </ul>
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
                            
                            <li><a class="dropdown-item" href="<%= request.getContextPath() %>/INTERFAZ_ALUMNO/mensajes_alumno.jsp">Ver todos</a></li>
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
                    <h1 class="h3 mb-3"><i class="fas fa-user-circle me-2"></i>Mi Perfil</h1>
                    <p class="lead">Aquí puedes ver tus datos personales y académicos.</p>
                </div>

                <% if (profileLoadError != null) { %>
                    <div class="alert alert-danger alert-error-message fade show" role="alert">
                        <i class="fas fa-exclamation-triangle me-2"></i><%= profileLoadError %>
                    </div>
                <% } %>

                <div class="card content-card">
                    <div class="card-body">
                        <div class="row">
                            <div class="col-md-4 text-center mb-4 mb-md-0">
                                <img src="https://via.placeholder.com/150" alt="Avatar de <%= nombreAlumno %>" class="img-fluid rounded-circle border border-primary p-1 shadow-sm mb-3">
                                <h4 class="mb-1 text-primary"><%= nombreAlumno %></h4>
                                <p class="text-muted">Alumno</p>
                                <a href="<%= request.getContextPath() %>/INTERFAZ_ALUMNO/configuracion_alumno.jsp" class="btn btn-edit-profile"><i class="fas fa-edit me-2"></i>Editar Perfil</a>
                            </div>
                            <div class="col-md-8">
                                <h5 class="card-title mb-4">Información Personal y de Contacto</h5>
                                <div class="row profile-detail-row">
                                    <div class="col-sm-6"><strong>DNI:</strong></div>
                                    <div class="col-sm-6"><span><%= dniAlumno %></span></div>
                                </div>
                                <div class="row profile-detail-row">
                                    <div class="col-sm-6"><strong>Correo Electrónico:</strong></div>
                                    <div class="col-sm-6"><span><%= emailAlumno %></span></div>
                                </div>
                                <div class="row profile-detail-row">
                                    <div class="col-sm-6"><strong>Teléfono:</strong></div>
                                    <div class="col-sm-6"><span><%= telefonoAlumno %></span></div>
                                </div>
                                <div class="row profile-detail-row">
                                    <div class="col-sm-6"><strong>Fecha de Nacimiento:</strong></div>
                                    <div class="col-sm-6"><span><%= fechaNacimientoAlumno %></span></div>
                                </div>
                                <div class="row profile-detail-row">
                                    <div class="col-sm-6"><strong>Dirección:</strong></div>
                                    <div class="col-sm-6"><span><%= direccionAlumno %></span></div>
                                </div>
                                <div class="row profile-detail-row">
                                    <div class="col-sm-6"><strong>Fecha de Registro:</strong></div>
                                    <div class="col-sm-6"><span><%= fechaRegistroAlumno %></span></div>
                                </div>
                                <div class="row profile-detail-row">
                                    <div class="col-sm-6"><strong>Último Acceso:</strong></div>
                                    <div class="col-sm-6"><span><%= ultimoAcceso %></span></div>
                                </div>

                                <h5 class="card-title mt-4 mb-4">Información Académica</h5>
                                <div class="row profile-detail-row">
                                    <div class="col-sm-6"><strong>Carrera:</strong></div>
                                    <div class="col-sm-6"><span><%= carreraAlumno %></span></div>
                                </div>
                                <div class="row profile-detail-row">
                                    <div class="col-sm-6"><strong>Facultad:</strong></div>
                                    <div class="col-sm-6"><span><%= facultadAlumno %></span></div>
                                </div>
                                <div class="row profile-detail-row">
                                    <div class="col-sm-6"><strong>Estado Académico:</strong></div>
                                    <div class="col-sm-6"><span><%= estadoAlumno.toUpperCase() %></span></div>
                                </div>
                                <hr class="my-3">
                                <p class="text-muted">Accede al detalle de tus notas, asistencia y pagos.</p>
                                <a href="<%= request.getContextPath() %>/INTERFAZ_ALUMNO/notas_alumno.jsp" class="btn btn-outline-primary me-2"><i class="fas fa-percent me-2"></i>Ver Mis Notas</a>
                                <a href="<%= request.getContextPath() %>/INTERFAZ_ALUMNO/asistencia_alumno.jsp" class="btn btn-outline-info me-2"><i class="fas fa-clipboard-check me-2"></i>Ver Mi Asistencia</a>
                                <a href="<%= request.getContextPath() %>/INTERFAZ_ALUMNO/pagos_alumno.jsp" class="btn btn-outline-warning"><i class="fas fa-money-bill-wave me-2"></i>Ver Mis Pagos</a>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js" integrity="sha384-YvpcrYf0tY3lHB60NNkmXc5s9fDVZLESaAA55NDzOxhy9GkcIdslK1eN7N6jIeHz" crossorigin="anonymous"></script>
</body>
</html>