<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, pe.universidad.util.Conection" %>
<%@ page import="java.time.LocalDateTime, java.time.format.DateTimeFormatter, java.time.LocalDate" %>
<%@ page import="java.util.Locale" %>
<%@ page import="java.net.URLEncoder" %>
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
    Object idAlumnoObj = session.getAttribute("id_alumno"); // Changed from idApoderadoObj
    
    // --- Variables para los datos del alumno ---
    int idAlumno = -1;    // Changed from idApoderado and idHijo
    String nombreAlumno = "Alumno Desconocido"; // Changed from nombreApoderado and nombreHijo
    String dniAlumno = "N/A"; // Added for alumno info
    String carreraAlumno = "Carrera Desconocida"; // Added for alumno info
    String estadoAlumno = "N/A"; // Added for alumno info

    Map<String, String> pagoDetalleActual = null; // To store details of the payment to be 'processed'

    String globalErrorMessage = null;
    String globalSuccessMessage = null;

    // --- Obtener el ID de Pago de la URL ---
    String idPagoParam = request.getParameter("idPago");
    int idPagoSeleccionado = -1;

    if (idPagoParam != null && !idPagoParam.isEmpty()) {
        try {
            idPagoSeleccionado = Integer.parseInt(idPagoParam);
            System.out.println("DEBUG (realizar_pago_alumno): ID de Pago recibido: " + idPagoSeleccionado); // Changed log
        } catch (NumberFormatException e) {
            globalErrorMessage = "El ID de pago proporcionado es inválido.";
            System.err.println("ERROR (realizar_pago_alumno): " + globalErrorMessage + " " + e.getMessage()); // Changed log
        }
    } else {
        if (!"POST".equalsIgnoreCase(request.getMethod())) {
            globalErrorMessage = "No se ha especificado un ID de pago para esta operación.";
        }
    }

    Connection conn = null;        
    PreparedStatement pstmt = null;    
    ResultSet rs = null;        

    try {
        // --- 1. Validar y obtener ID del Alumno de Sesión ---
        if (emailSesion == null || !"alumno".equalsIgnoreCase(rolUsuario) || idAlumnoObj == null) { // Changed rol check
            System.out.println("DEBUG (realizar_pago_alumno): Sesión inválida o rol incorrecto. Redirigiendo a login."); // Changed log
            response.sendRedirect(request.getContextPath() + "/login.jsp?message=" + URLEncoder.encode("Tu sesión ha expirado o no tienes permisos para acceder a esta página.", "UTF-8") + "&type=danger");
            return;
        }
        try {
            idAlumno = Integer.parseInt(String.valueOf(idAlumnoObj)); // Use idAlumnoObj
            System.out.println("DEBUG (realizar_pago_alumno): ID Alumno de sesión: " + idAlumno); // Changed log
        } catch (NumberFormatException e) {
            System.err.println("ERROR (realizar_pago_alumno): ID de alumno en sesión no es un número válido. " + e.getMessage()); // Changed log
            globalErrorMessage = "Error de sesión: ID de alumno inválido.";
        }

        // If idAlumno is valid, attempt to connect and load data
        if (idAlumno != -1 && globalErrorMessage == null) {
            // --- 2. Conectar a la Base de Datos ---
            Conection c = new Conection();
            conn = c.conecta();    
            if (conn == null || conn.isClosed()) {
                throw new SQLException("No se pudo establecer conexión a la base de datos.");
            }
            System.out.println("DEBUG (realizar_pago_alumno): Conexión a BD establecida."); // Changed log

            // --- 3. Obtener Información General del Alumno (using vista_alumnos_completa) ---
            // Using a separate pstmt/rs for this general info block
            PreparedStatement currentPstmt = null; 
            ResultSet currentRs = null;          
            try {
                // Assuming vista_alumnos_completa has dni, nombre_completo, nombre_carrera, estado
                String sqlAlumnoInfo = "SELECT dni, nombre_completo, nombre_carrera, estado FROM vista_alumnos_completa WHERE id_alumno = ?";
                currentPstmt = conn.prepareStatement(sqlAlumnoInfo);
                currentPstmt.setInt(1, idAlumno); // Use idAlumno
                currentRs = currentPstmt.executeQuery();
                if (currentRs.next()) {
                    nombreAlumno = currentRs.getString("nombre_completo");
                    dniAlumno = currentRs.getString("dni") != null ? currentRs.getString("dni") : "N/A";
                    carreraAlumno = currentRs.getString("nombre_carrera") != null ? currentRs.getString("nombre_carrera") : "Desconocida";
                    estadoAlumno = currentRs.getString("estado") != null ? currentRs.getString("estado") : "N/A";
                    session.setAttribute("nombre_alumno", nombreAlumno); // Save to session
                    System.out.println("DEBUG (realizar_pago_alumno): Datos de alumno cargados: " + nombreAlumno); // Changed log
                } else {
                    globalErrorMessage = "Tu información de alumno no se encontró en la base de datos. Por favor, contacta a soporte."; // Changed message
                    System.err.println("ERROR (realizar_pago_alumno): Alumno con ID " + idAlumno + " no encontrado en BD."); // Changed log
                    // If student not found, invalidate session and redirect
                    session.invalidate();
                    response.sendRedirect(request.getContextPath() + "/login.jsp?error=" + URLEncoder.encode(globalErrorMessage, "UTF-8") + "&type=danger");
                    return; // Stop further processing
                }
            } finally { cerrarRecursos(currentRs, currentPstmt); }
            
            // --- Procesar el formulario de pago si es un POST request ---
            if ("POST".equalsIgnoreCase(request.getMethod()) && idPagoSeleccionado != -1 && globalErrorMessage == null) { // idHijo replaced with idAlumno
                String metodoPago = request.getParameter("metodoPago");
                String referencia = request.getParameter("referencia");

                if (metodoPago == null || metodoPago.isEmpty()) {
                    globalErrorMessage = "Debe seleccionar un método de pago.";
                } else {
                    try {
                        String sqlUpdatePago = "UPDATE pagos SET fecha_pago = ?, metodo_pago = ?, referencia = ?, estado = 'Pagado' WHERE id_pago = ? AND id_alumno = ?";
                        pstmt = conn.prepareStatement(sqlUpdatePago); // Using main pstmt
                        pstmt.setDate(1, java.sql.Date.valueOf(LocalDate.now())); // Current date
                        pstmt.setString(2, metodoPago);
                        pstmt.setString(3, referencia);
                        pstmt.setInt(4, idPagoSeleccionado);
                        pstmt.setInt(5, idAlumno); // Ensure payment belongs to this student
                        
                        int rowsAffected = pstmt.executeUpdate();
                        if (rowsAffected > 0) {
                            globalSuccessMessage = "¡Pago realizado con éxito! La página de historial de pagos se actualizará.";
                            System.out.println("DEBUG (realizar_pago_alumno): Pago ID " + idPagoSeleccionado + " actualizado a 'Pagado'."); // Changed log
                            // Redirect to pagos_alumno.jsp with a success message
                            response.sendRedirect(request.getContextPath() + "/INTERFAZ_ALUMNO/pagos_alumno.jsp?message=" + URLEncoder.encode(globalSuccessMessage, "UTF-8") + "&type=success"); // Changed path
                            return; // Stop further execution of this JSP
                        } else {
                            globalErrorMessage = "No se pudo actualizar el pago. Verifique si el pago ya fue realizado o los datos son correctos.";
                            System.err.println("ERROR (realizar_pago_alumno): No se afectaron filas al actualizar el pago ID: " + idPagoSeleccionado); // Changed log
                        }
                    } finally {
                        cerrarRecursos(null, pstmt); // No ResultSet for UPDATE
                    }
                }
            }


            // --- Obtener los detalles del pago seleccionado para mostrar en el formulario (if not redirected yet) ---
            if (idPagoSeleccionado != -1 && idAlumno != -1 && globalErrorMessage == null) { // idHijo replaced with idAlumno
                try {
                    String sqlPagoActual = "SELECT id_pago, fecha_vencimiento, concepto, monto, estado " +
                                           "FROM pagos WHERE id_pago = ? AND id_alumno = ?"; // Filter by id_alumno
                    pstmt = conn.prepareStatement(sqlPagoActual); // Using main pstmt
                    pstmt.setInt(1, idPagoSeleccionado);
                    pstmt.setInt(2, idAlumno); // Ensure payment belongs to this student
                    rs = pstmt.executeQuery(); // Using main rs

                    if (rs.next()) {
                        pagoDetalleActual = new HashMap<>();
                        pagoDetalleActual.put("id_pago", String.valueOf(rs.getInt("id_pago")));
                        pagoDetalleActual.put("concepto", rs.getString("concepto"));
                        pagoDetalleActual.put("monto", String.format(Locale.US, "%.2f", rs.getDouble("monto")));
                        java.sql.Date fechaVencimientoSql = rs.getDate("fecha_vencimiento");
                        pagoDetalleActual.put("fecha_vencimiento", fechaVencimientoSql != null ? fechaVencimientoSql.toLocalDate().format(DateTimeFormatter.ofPattern("dd/MM/yyyy")) : "N/A");
                        pagoDetalleActual.put("estado", rs.getString("estado").toUpperCase());
                    } else {
                        globalErrorMessage = "El pago especificado no se encontró o no te pertenece."; // Changed message
                    }
                } finally { cerrarRecursos(rs, pstmt); } // Close main rs and pstmt here
            }

        } // End if (idAlumno != -1 && globalErrorMessage == null) for database operations

    } catch (SQLException e) {
        globalErrorMessage = "Error de base de datos al cargar la información: " + e.getMessage();
        System.err.println("ERROR (realizar_pago_alumno) SQL Principal: " + globalErrorMessage); // Changed log
        e.printStackTrace();
    } catch (ClassNotFoundException e) {
        globalErrorMessage = "Error de configuración: Driver JDBC no encontrado. Asegúrate de que el conector esté en WEB-INF/lib.";
        System.err.println("ERROR (realizar_pago_alumno) DRIVER Principal: " + globalErrorMessage); // Changed log
        e.printStackTrace();
    } finally {
        // Ensure the main connection is closed.
        try {
            if (conn != null) {
                conn.close();
            }
        } catch (SQLException e) {
            System.err.println("Error al cerrar conexión final: " + e.getMessage());
        }
    }
    // Format for "Último acceso" (this is fine outside the main try-catch of DB operations)
    String ultimoAcceso = LocalDateTime.now().format(DateTimeFormatter.ofPattern("EEEE, d 'de' MMMM 'de'yyyy, HH:mm", new Locale("es", "ES")));
%>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Realizar Pago | Sistema Universitario</title>
    <link rel="icon" type="image/x-icon" href="<%= request.getContextPath() %>/img/favicon.ico">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        /* Variables de estilo para consistencia con AdminKit */
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
            border-left: 4px solid var(--admin-primary);
            margin-bottom: 1.5rem;
        }
        .content-section.card .card-header {
             background-color: var(--admin-card-bg);
             border-bottom: 1px solid #dee2e6;
             padding-bottom: 1rem;
        }
        .content-section .section-title {
            color: var(--admin-primary);
            font-weight: 600;
            margin-bottom: 0;
        }
        .content-section.card .card-body p.text-muted {
            font-size: 0.95rem;
        }

        /* Stat Cards for Payments */
        .stat-card {
            background-color: var(--admin-card-bg);
            border-radius: 0.5rem;
            padding: 1.5rem;
            text-align: center;
            box-shadow: 0 0.125rem 0.25rem rgba(0,0,0,0.075);
            border-bottom: 4px solid var(--admin-primary);
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
            color: var(--admin-primary);
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
        .stat-card.pending-count .value, .stat-card.pending-count .icon-wrapper { color: var(--admin-warning); }
        .stat-card.overdue-count .value, .stat-card.overdue-count .icon-wrapper { color: var(--admin-danger); }
        .stat-card.total-amount-due .value, .stat-card.total-amount-due .icon-wrapper { color: var(--admin-primary); }
        .stat-card.last-payment-date .value, .stat-card.last-payment-date .icon-wrapper { color: var(--admin-info); }

        /* Tablas */
        .table-responsive {
            max-height: 500px;
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
            position: sticky;
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
        .badge.bg-warning { background-color: var(--admin-warning) !important; color: var(--admin-text-dark) !important;}
        .badge.bg-danger { background-color: var(--admin-danger) !important; }

        /* Botón de Pagar */
        .btn-pay {
            background-color: var(--admin-primary);
            color: white;
            border: none;
            padding: 0.4rem 0.8rem;
            border-radius: 4px;
            cursor: pointer;
            transition: background-color 0.3s ease, transform 0.2s ease;
            font-size: 0.85rem;
        }
        .btn-pay:hover {
            background-color: #0056b3;
            transform: translateY(-2px);
        }
        .btn-pay:disabled {
            background-color: var(--admin-secondary-color);
            cursor: not-allowed;
            opacity: 0.6;
        }

        /* Chart Container */
        .chart-container {
            height: 300px;
            width: 100%;
            margin: auto;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 1rem;
        }
        .chart-container canvas {
            max-width: 100%;
            max-height: 100%;
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

            .welcome-section, .card { padding: 1rem;}
            .stat-card { min-height: 120px; padding: 1rem; }
            .stat-card .value { font-size: 1.8rem; }
            .stat-card .icon-wrapper { font-size: 1.5rem; margin-bottom: 0.5rem; }
            .chart-container { height: 250px; }
        }
        @media (max-width: 576px) {
            .main-content { padding: 0.75rem; }
            .welcome-section, .card { padding: 0.75rem;}
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
                    <a class="nav-link active" href="<%= request.getContextPath() %>/INTERFAZ_ALUMNO/pagos_alumno.jsp"><i class="fas fa-money-bill-wave"></i><span> Mis Pagos</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_ALUMNO/mensajes_alumno.jsp"><i class="fas fa-envelope"></i><span> Mensajes</span></a>
                </li>
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
                    
                </div>
                <div class="d-flex align-items-center">
                    
                    <div class="me-3 dropdown">
                        <a class="text-dark" href="#" role="button" id="messagesDropdown" data-bs-toggle="dropdown" aria-expanded="false">
                            <i class="fas fa-envelope fa-lg"></i>
                            <span class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger">
                                <%-- Placeholder for message count --%>
                            </span>
                        </a>
                        <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="messagesDropdown">
                            
                            <li><a class="dropdown-item" href="<%= request.getContextPath()%>/INTERFAZ_ALUMNO/mensajes_alumno.jsp">Ver todos</a></li>
                        </ul>
                    </div>

                    <div class="dropdown user-dropdown">
                        <a class="dropdown-toggle" href="#" role="button" id="userDropdown" data-bs-toggle="dropdown" aria-expanded="false">
                            <img src="https://placehold.co/32x32/FFC107/FFFFFF?text=A" alt="Avatar"> <span class="d-none d-md-inline-block"><%= nombreAlumno != null ? nombreAlumno : "Alumno"%></span>
                        </a>
                        <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="userDropdown">
                            <li><a class="dropdown-item" href="perfil_alumno.jsp"><i class="fas fa-user me-2"></i>Perfil</a></li>
                            <li><a class="dropdown-item" href="configuracion_alumno.jsp"><i class="fas fa-cog me-2"></i>Configuración</a></li>
                            <li><hr class="dropdown-divider"></li>
                            <li><a class="dropdown-item" href="<%= request.getContextPath() %>/logout.jsp"><i class="fas fa-sign-out-alt me-2"></i>Cerrar sesión</a></li>
                        </ul>
                    </div>
                </div>
            </nav>
            <div class="container-fluid">
                <div class="welcome-section">
                    <h1 class="h3 mb-3"><i class="fas fa-money-bill-wave me-2"></i>Realizar Pago</h1>
                    <p class="lead">Detalles del pago seleccionado.</p>
                </div>

                <% 
                    // Display server-side messages immediately
                    String messageFromUrl = request.getParameter("message");
                    String typeFromUrl = request.getParameter("type");
                    if (messageFromUrl != null && !messageFromUrl.isEmpty()) { 
                %>
                    <div class="alert alert-<%= typeFromUrl %> alert-dismissible fade show" role="alert">
                        <i class="fas <%= "success".equals(typeFromUrl) ? "fa-check-circle" : ("danger".equals(typeFromUrl) ? "fa-exclamation-triangle" : "fa-info-circle") %> me-2"></i> <%= messageFromUrl %>
                        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                    </div>
                <% } else if (globalErrorMessage != null) { %>
                    <div class="alert alert-danger alert-dismissible fade show" role="alert">
                        <i class="fas fa-exclamation-triangle me-2"></i> <%= globalErrorMessage %>
                        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                    </div>
                <% } else if (globalSuccessMessage != null) { %>
                    <div class="alert alert-success alert-dismissible fade show" role="alert">
                        <i class="fas fa-check-circle me-2"></i> <%= globalSuccessMessage %>
                        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                    </div>
                <% } %>


                <div class="card content-section mb-4">
                    <div class="card-header">
                        <h3 class="section-title mb-0"><i class="fas fa-info-circle me-2"></i>Información del Pago ID: <%= (idPagoSeleccionado != -1) ? idPagoSeleccionado : "N/A" %></h3>
                    </div>
                    <div class="card-body">
                        <% if (pagoDetalleActual != null) { %>
                            <p class="mb-1"><strong>Concepto:</strong> <%= pagoDetalleActual.get("concepto") %></p>
                            <p class="mb-1"><strong>Monto:</strong> S/. <%= pagoDetalleActual.get("monto") %></p>
                            <p class="mb-1"><strong>Fecha de Vencimiento:</strong> <%= pagoDetalleActual.get("fecha_vencimiento") %></p>
                            <p class="mb-1"><strong>Estado:</strong> 
                                <%  String estadoActual = pagoDetalleActual.get("estado");
                                    String badgeClass = "";
                                    if ("PAGADO".equalsIgnoreCase(estadoActual)) { badgeClass = "bg-success"; }
                                    else if ("PENDIENTE".equalsIgnoreCase(estadoActual)) { badgeClass = "bg-warning text-dark"; }
                                    else if ("VENCIDO".equalsIgnoreCase(estadoActual)) { badgeClass = "bg-danger"; }
                                %>
                                <span class="badge <%= badgeClass %>"><%= estadoActual %></span>
                            </p>
                            <p class="mb-3"><strong>Pagando para:</strong> <%= nombreAlumno %></p>

                            <%-- This is the PAYMENT FORM --%>
                            <hr>
                            <h4>Formulario de Pago</h4>
                            <% if ("PAGADO".equalsIgnoreCase(pagoDetalleActual.get("estado"))) { %>
                                <div class="alert alert-info" role="alert">
                                    Este pago ya ha sido marcado como "Pagado". No se requieren acciones adicionales.
                                </div>
                            <% } else { %>
                                <form action="<%= request.getContextPath() %>/INTERFAZ_ALUMNO/realizar_pago_alumno.jsp" method="post">
                                    <input type="hidden" name="idPago" value="<%= idPagoSeleccionado %>">
                                    <div class="mb-3">
                                        <label for="metodoPago" class="form-label">Método de Pago:</label>
                                        <select class="form-select" id="metodoPago" name="metodoPago" required>
                                            <option value="">Seleccione un método</option>
                                            <option value="Tarjeta de Crédito/Débito">Tarjeta</option>
                                            <option value="Transferencia Bancaria">Transferencia</option>
                                            <option value="Yape/Plin">Yape/Plin</option>
                                            <option value="Pago en Efectivo">Efectivo</option>
                                        </select>
                                    </div>
                                    <div class="mb-3">
                                        <label for="referencia" class="form-label">Referencia/Número de Operación (Opcional):</label>
                                        <input type="text" class="form-control" id="referencia" name="referencia" placeholder="Ej. Código de transferencia, 4 últimos dígitos de tarjeta">
                                    </div>
                                    <button type="submit" class="btn btn-success"><i class="fas fa-check-circle me-2"></i>Confirmar Pago</button>
                                </form>
                            <% } %>
                            <%-- END PAYMENT FORM --%>

                        <% } else { %>
                            <p class="text-muted text-center py-3 mb-0">No se encontraron detalles para el pago solicitado.</p>
                        <% } %>
                        <div class="mt-4">
                            <a href="<%= request.getContextPath() %>/INTERFAZ_ALUMNO/pagos_alumno.jsp" class="btn btn-secondary"><i class="fas fa-arrow-left me-2"></i>Volver a Mis Pagos</a>
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
            // No need for a custom alert function here as we are using server-side redirects for messages
            // and the existing Bootstrap alert dismissal for URL parameters.
        });
    </script>
</body>
</html>