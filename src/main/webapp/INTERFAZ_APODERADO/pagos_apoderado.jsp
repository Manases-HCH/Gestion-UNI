<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, pe.universidad.util.Conection" %>
<%@ page import="java.time.LocalDateTime, java.time.format.DateTimeFormatter" %>
<%@ page import="java.util.Locale" %> <%-- Para formato de números y fechas --%>
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
    // ====================================================================
    // 🧪 FORZAR SESIÓN TEMPORALMENTE PARA APODERADO (SOLO PARA TEST)
    // REMOVER ESTE BLOQUE EN PRODUCCIÓN O CUANDO EL LOGIN REAL FUNCIONE
    // --- Obtener información de la sesión ---
    String emailSesion = (String) session.getAttribute("email");
    String rolUsuario = (String) session.getAttribute("rol");
    Object idApoderadoObj = session.getAttribute("id_apoderado");
    
    // --- Variables para los datos del apoderado y su hijo ---
    int idApoderado = -1;    
    String nombreApoderado = "Apoderado Desconocido";
    String emailApoderado = (emailSesion != null ? emailSesion : "N/A");
    String telefonoApoderado = "No registrado";
    // String ultimoAcceso = ""; // Will be updated later at the end of the scriptlet

    int idHijo = -1;
    String nombreHijo = "Hijo No Asignado";
    String dniHijo = "N/A";
    String carreraHijo = "Carrera Desconocida";
    String estadoHijo = "N/A";

    List<Map<String, String>> pagosHijoList = new ArrayList<>();

    // --- Variables para las estadísticas de pagos ---
    int totalPagosPendientes = 0;
    int totalPagosVencidos = 0;
    double montoTotalPendiente = 0.0;
    String fechaUltimoPago = "N/A";

    // --- Datos para el gráfico de torta (distribución de estados de pago) ---
    int countPagado = 0;
    int countPendiente = 0;
    int countVencido = 0;

    Connection conn = null;        
    PreparedStatement pstmt = null; // Declare here for broader scope
    ResultSet rs = null; // Declare here for broader scope
    String globalErrorMessage = null; // Initialize here

    try {
        // --- 1. Validar y obtener ID del Apoderado de Sesión ---
        if (emailSesion == null || !"apoderado".equalsIgnoreCase(rolUsuario) || idApoderadoObj == null) {
            System.out.println("DEBUG (pagos_apoderado): Sesión inválida o rol incorrecto. Redirigiendo a login.");
            response.sendRedirect(request.getContextPath() + "/login.jsp"); // Corrected path
            return;
        }
        try {
            idApoderado = Integer.parseInt(String.valueOf(idApoderadoObj));
            System.out.println("DEBUG (pagos_apoderado): ID Apoderado de sesión: " + idApoderado);
        } catch (NumberFormatException e) {
            System.err.println("ERROR (pagos_apoderado): ID de apoderado en sesión no es un número válido. " + e.getMessage());
            globalErrorMessage = "Error de sesión: ID de apoderado inválido.";
            // No return here, allow the page to render with the error message
        }

        // Si idApoderado es válido, intentar conectar y cargar datos
        if (idApoderado != -1 && globalErrorMessage == null) {
            // --- 2. Conectar a la Base de Datos ---
            Conection c = new Conection();
            conn = c.conecta();    
            if (conn == null || conn.isClosed()) {
                throw new SQLException("No se pudo establecer conexión a la base de datos.");
            }
            System.out.println("DEBUG (pagos_apoderado): Conexión a BD establecida.");

            // --- 3. Obtener Nombre y Datos del Apoderado ---
            // Use local pstmt/rs for this specific query to avoid conflict with main pstmt/rs
            PreparedStatement currentPstmt = null;
            ResultSet currentRs = null;
            try {
                String sqlApoderado = "SELECT nombre, apellido_paterno, apellido_materno, email, telefono FROM apoderados WHERE id_apoderado = ?";
                currentPstmt = conn.prepareStatement(sqlApoderado);
                currentPstmt.setInt(1, idApoderado);
                currentRs = currentPstmt.executeQuery();
                if (currentRs.next()) {
                    String nombre = currentRs.getString("nombre") != null ? currentRs.getString("nombre") : "";
                    String apPaterno = currentRs.getString("apellido_paterno") != null ? currentRs.getString("apellido_paterno") : "";
                    String apMaterno = currentRs.getString("apellido_materno") != null ? currentRs.getString("apellido_materno") : "";
                    nombreApoderado = nombre + " " + apPaterno;
                    if (!apMaterno.isEmpty()) { nombreApoderado += " " + apMaterno; }
                    emailApoderado = currentRs.getString("email");
                    telefonoApoderado = currentRs.getString("telefono") != null ? currentRs.getString("telefono") : "No registrado";
                    session.setAttribute("nombre_apoderado", nombreApoderado);    
                    System.out.println("DEBUG (pagos_apoderado): Datos de apoderado cargados: " + nombreApoderado);
                } else {
                    globalErrorMessage = "Apoderado no encontrado en la base de datos. Por favor, contacte a soporte.";
                    System.err.println("ERROR (pagos_apoderado): Apoderado con ID " + idApoderado + " no encontrado en BD.");
                }
            } finally { cerrarRecursos(currentRs, currentPstmt); }

            // --- 4. Obtener ID y Nombre del Hijo e información general del hijo ---
            if (globalErrorMessage == null) { // Only proceed if apoderado data was successfully retrieved
                try {
                    String sqlHijo = "SELECT a.id_alumno, a.dni, a.nombre, a.apellido_paterno, a.apellido_materno, c.nombre_carrera, a.estado "
                                            + "FROM alumnos a "
                                            + "JOIN alumno_apoderado aa ON a.id_alumno = aa.id_alumno "
                                            + "JOIN carreras c ON a.id_carrera = c.id_carrera "
                                            + "WHERE aa.id_apoderado = ? LIMIT 1";    
                    currentPstmt = conn.prepareStatement(sqlHijo);
                    currentPstmt.setInt(1, idApoderado);
                    currentRs = currentPstmt.executeQuery();
                    if (currentRs.next()) {
                        idHijo = currentRs.getInt("id_alumno");
                        String nombre = currentRs.getString("nombre") != null ? currentRs.getString("nombre") : "";
                        String apPaterno = currentRs.getString("apellido_paterno") != null ? currentRs.getString("apellido_paterno") : "";
                        String apMaterno = currentRs.getString("apellido_materno") != null ? currentRs.getString("apellido_materno") : "";
                        nombreHijo = nombre + " " + apPaterno;
                        if (!apMaterno.isEmpty()) { nombreHijo += " " + apMaterno; }
                        dniHijo = currentRs.getString("dni") != null ? currentRs.getString("dni") : "N/A"; // Get DNI
                        carreraHijo = currentRs.getString("nombre_carrera") != null ? currentRs.getString("nombre_carrera") : "Desconocida";
                        estadoHijo = currentRs.getString("estado") != null ? currentRs.getString("estado") : "N/A";
                        session.setAttribute("id_hijo", idHijo);    
                        session.setAttribute("nombre_hijo", nombreHijo);    
                    } else {
                        globalErrorMessage = "No se encontró un hijo asociado a este apoderado. Contacte a la administración para asignar a su hijo/a.";
                        System.err.println("ERROR (pagos_apoderado): No se encontró hijo para apoderado ID: " + idApoderado);
                        idHijo = -1; // Ensure idHijo is invalid if not found
                    }
                } finally { cerrarRecursos(currentRs, currentPstmt); }
            }

            // --- 5. Obtener Historial de Pagos del Hijo (if child is assigned and no previous errors) ---
            if (idHijo != -1 && globalErrorMessage == null) {
                try {
                    String sqlPagos = "SELECT id_pago, fecha_pago, fecha_vencimiento, concepto, monto, metodo_pago, referencia, estado "
                                           + "FROM pagos "
                                           + "WHERE id_alumno = ? "
                                           + "ORDER BY fecha_vencimiento DESC, fecha_pago DESC";
                    
                    currentPstmt = conn.prepareStatement(sqlPagos);
                    currentPstmt.setInt(1, idHijo);
                    currentRs = currentPstmt.executeQuery();

                    while(currentRs.next()) {
                        Map<String, String> pagoRecord = new HashMap<>();
                        pagoRecord.put("id_pago", String.valueOf(currentRs.getInt("id_pago")));
                        
                        java.sql.Date fechaPagoSql = currentRs.getDate("fecha_pago");
                        pagoRecord.put("fecha_pago", fechaPagoSql != null ? fechaPagoSql.toLocalDate().format(DateTimeFormatter.ofPattern("dd/MM/yyyy")) : "N/A"); // Format date
                        
                        java.sql.Date fechaVencimientoSql = currentRs.getDate("fecha_vencimiento");
                        pagoRecord.put("fecha_vencimiento", fechaVencimientoSql != null ? fechaVencimientoSql.toLocalDate().format(DateTimeFormatter.ofPattern("dd/MM/yyyy")) : "N/A"); // Format date
                        
                        pagoRecord.put("concepto", currentRs.getString("concepto"));
                        pagoRecord.put("monto", String.format(Locale.US, "%.2f", currentRs.getDouble("monto")));
                        
                        String metodoPago = currentRs.getString("metodo_pago");
                        pagoRecord.put("metodo_pago", metodoPago != null && !metodoPago.isEmpty() ? metodoPago : "N/A");
                        
                        String referencia = currentRs.getString("referencia");
                        pagoRecord.put("referencia", referencia != null && !referencia.isEmpty() ? referencia : "N/A");
                        
                        String estadoPago = currentRs.getString("estado").toUpperCase();
                        pagoRecord.put("estado", estadoPago);
                        
                        pagosHijoList.add(pagoRecord);
                    }
                    System.out.println("DEBUG (pagos_apoderado): Registros de pagos de hijo listados: " + pagosHijoList.size());
                } finally { cerrarRecursos(currentRs, currentPstmt); }
            }

            // --- 6. Obtener Datos para Estadísticas y Gráfico de Torta ---
            if (idHijo != -1 && globalErrorMessage == null) {
                try {
                    String sqlStats = "SELECT estado, COUNT(*) as count, SUM(monto) as total_monto FROM pagos WHERE id_alumno = ? GROUP BY estado";
                    currentPstmt = conn.prepareStatement(sqlStats);
                    currentPstmt.setInt(1, idHijo);
                    currentRs = currentPstmt.executeQuery();
                    while(currentRs.next()) {
                        String estado = currentRs.getString("estado").toUpperCase();
                        int count = currentRs.getInt("count");
                        double totalMonto = currentRs.getDouble("total_monto");
                        
                        if ("PAGADO".equals(estado)) {
                            countPagado = count;
                        } else if ("PENDIENTE".equals(estado)) {
                            countPendiente = count;
                            montoTotalPendiente += totalMonto; // Add pending amounts
                            totalPagosPendientes = count;
                        } else if ("VENCIDO".equals(estado)) {
                            countVencido = count;
                            montoTotalPendiente += totalMonto; // Add overdue amounts to total pending as well
                            totalPagosVencidos = count;
                        }
                    }
                } finally { cerrarRecursos(currentRs, currentPstmt); }

                // Obtener última fecha de pago (si existe)
                try {
                    String sqlLastPayment = "SELECT MAX(fecha_pago) as last_date FROM pagos WHERE id_alumno = ? AND estado = 'pagado'";
                    currentPstmt = conn.prepareStatement(sqlLastPayment);
                    currentPstmt.setInt(1, idHijo);
                    currentRs = currentPstmt.executeQuery();
                    if(currentRs.next() && currentRs.getDate("last_date") != null) {
                        fechaUltimoPago = currentRs.getDate("last_date").toLocalDate().format(DateTimeFormatter.ofPattern("dd/MM/yyyy")); // Format date
                    }
                } finally { cerrarRecursos(currentRs, currentPstmt); }
            }

        } // Fin if (idApoderado != -1 && globalErrorMessage == null) para operaciones de BD

    } catch (SQLException e) {
        globalErrorMessage = "Error de base de datos al cargar la información: " + e.getMessage();
        System.err.println("ERROR (pagos_apoderado) SQL Principal: " + globalErrorMessage);
        e.printStackTrace();
    } catch (ClassNotFoundException e) {
        globalErrorMessage = "Error de configuración: Driver JDBC no encontrado. Asegúrate de que el conector esté en WEB-INF/lib.";
        System.err.println("ERROR (pagos_apoderado) DRIVER Principal: " + globalErrorMessage);
        e.printStackTrace();
    } finally {
        // Ensure the main connection is closed. All pstmt and rs should be closed in their respective finally blocks.
        try {
            if (conn != null) {
                conn.close();
            }
        } catch (SQLException e) {
            System.err.println("Error al cerrar conexión final: " + e.getMessage());
        }
    }
    // Formato para la fecha de "Último acceso" (this is fine outside the main try-catch of DB operations)
    String ultimoAcceso = LocalDateTime.now().format(DateTimeFormatter.ofPattern("EEEE, d 'de' MMMM 'de'yyyy, HH:mm", new Locale("es", "ES")));
%>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Pagos y Mensualidades | Dashboard Apoderado | Sistema Universitario</title>
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

        /* Stat Cards for Payments */
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
        .stat-card.pending-count .value, .stat-card.pending-count .icon-wrapper { color: var(--admin-warning); }
        .stat-card.overdue-count .value, .stat-card.overdue-count .icon-wrapper { color: var(--admin-danger); }
        .stat-card.total-amount-due .value, .stat-card.total-amount-due .icon-wrapper { color: var(--admin-primary); }
        .stat-card.last-payment-date .value, .stat-card.last-payment-date .icon-wrapper { color: var(--admin-info); }


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
        .badge.bg-success { background-color: var(--admin-success) !important; } /* Pagado */
        .badge.bg-warning { background-color: var(--admin-warning) !important; color: var(--admin-text-dark) !important;} /* Pendiente */
        .badge.bg-danger { background-color: var(--admin-danger) !important; } /* Vencido */


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
            height: 300px; /* Tamaño del gráfico */
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
            .stat-card { min-height: 120px; padding: 1rem; } /* Reduce height for mobile stats */
            .stat-card .value { font-size: 1.8rem; }
            .stat-card .icon-wrapper { font-size: 1.5rem; margin-bottom: 0.5rem; }
            .chart-container { height: 250px; } /* Ajuste de altura para gráficos en móvil */
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
                <a href="<%= request.getContextPath() %>/INTERFAZ_APODERADO/home_apoderado.jsp" class="text-white text-decoration-none">UGIC Portal</a>
            </div>
            <ul class="navbar-nav">
                <li class="nav-item">
                    <a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_APODERADO/home_apoderado.jsp"><i class="fas fa-home"></i><span> Inicio</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_APODERADO/cursos_apoderado.jsp"><i class="fas fa-book"></i><span> Cursos de mi hijo</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_APODERADO/asistencia_apoderado.jsp"><i class="fas fa-clipboard-check"></i><span> Asistencia de mi hijo</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_APODERADO/notas_apoderado.jsp"><i class="fas fa-percent"></i><span> Notas de mi hijo</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link active" href="<%= request.getContextPath() %>/INTERFAZ_APODERADO/pagos_apoderado.jsp"><i class="fas fa-money-bill-wave"></i><span> Pagos y Mensualidades</span></a>
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
                            <li><a class="dropdown-item" href="<%= request.getContextPath() %>/logout.jsp"><i class="fas fa-sign-out-alt me-2"></i>Cerrar sesión</a></li>
                        </ul>
                    </div>
                </div>
            </nav>
            <div class="container-fluid">
                <div class="welcome-section">
                    <h1 class="h3 mb-3"><i class="fas fa-money-bill-wave me-2"></i>Pagos y Mensualidades de <%= nombreHijo %></h1>
                    <p class="lead">Aquí puede ver el historial de todos los pagos de su hijo/a, así como las mensualidades pendientes o vencidas.</p>
                </div>

                <% if (globalErrorMessage != null) { %>
                    <div class="alert alert-danger alert-dismissible fade show" role="alert">
                        <i class="fas fa-exclamation-triangle me-2"></i> <%= globalErrorMessage %>
                        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                    </div>
                <% } %>
                
                <%-- Add this section to display messages from redirects --%>
                <% String messageFromUrl = request.getParameter("message");
                   String typeFromUrl = request.getParameter("type");
                   if (messageFromUrl != null && !messageFromUrl.isEmpty()) { %>
                    <div class="alert alert-<%= typeFromUrl %> alert-dismissible fade show mt-3" role="alert">
                        <i class="fas <%= "success".equals(typeFromUrl) ? "fa-check-circle" : ("danger".equals(typeFromUrl) ? "fa-exclamation-triangle" : "fa-info-circle") %> me-2"></i> <%= messageFromUrl %>
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
                                <p class="mb-1"><strong>Total Registros de Pagos:</strong> <%= pagosHijoList.size() %></p>
                            </div>
                        </div>
                        <% } else { %>
                        <p class="text-muted text-center py-3 mb-0">No se encontró información detallada del hijo/a.</p>
                        <% } %>
                    </div>
                </div>

                <div class="row row-cols-1 row-cols-md-2 row-cols-lg-4 g-4 mb-4">
                    <div class="col">
                        <div class="card h-100 shadow-sm stat-card pending-count">
                            <div class="card-body">
                                <div class="icon-wrapper"><i class="fas fa-hourglass-half"></i></div>
                                <h3 class="card-title">Pagos Pendientes</h3>
                                <div class="value"><%= totalPagosPendientes %></div>
                                <div class="description">Número de cuotas pendientes</div>
                            </div>
                        </div>
                    </div>
                    <div class="col">
                        <div class="card h-100 shadow-sm stat-card overdue-count">
                            <div class="card-body">
                                <div class="icon-wrapper"><i class="fas fa-calendar-times"></i></div>
                                <h3 class="card-title">Pagos Vencidos</h3>
                                <div class="value"><%= totalPagosVencidos %></div>
                                <div class="description">Número de cuotas vencidas</div>
                            </div>
                        </div>
                    </div>
                    <div class="col">
                        <div class="card h-100 shadow-sm stat-card total-amount-due">
                            <div class="card-body">
                                <div class="icon-wrapper"><i class="fas fa-money-check-alt"></i></div>
                                <h3 class="card-title">Monto Total Pendiente</h3>
                                <div class="value">S/. <%= String.format(Locale.US, "%.2f", montoTotalPendiente) %></div>
                                <div class="description">Sumatoria de montos pendientes y vencidos</div>
                            </div>
                        </div>
                    </div>
                    <div class="col">
                        <div class="card h-100 shadow-sm stat-card last-payment-date">
                            <div class="card-body">
                                <div class="icon-wrapper"><i class="fas fa-calendar-check"></i></div>
                                <h3 class="card-title">Último Pago</h3>
                                <div class="value"><%= fechaUltimoPago %></div>
                                <div class="description">Fecha de la última mensualidad pagada</div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="card content-section mb-4">
                    <div class="card-header">
                        <h3 class="section-title mb-0"><i class="fas fa-chart-pie me-2"></i>Distribución de Estados de Pago</h3>
                    </div>
                    <div class="card-body">
                        <% if (countPagado > 0 || countPendiente > 0 || countVencido > 0) { %>
                            <div class="chart-container">
                                <canvas id="paymentStatusChart"></canvas>
                            </div>
                        <% } else { %>
                            <p class="text-muted text-center py-3">No hay datos de pagos para mostrar el gráfico de distribución.</p>
                            <p class="text-muted text-center"><small>Los pagos deben estar registrados para ver este gráfico.</small></p>
                        <% } %>
                    </div>
                </div>


                <div class="card content-section mb-4">
                    <div class="card-header">
                        <h3 class="section-title mb-0"><i class="fas fa-file-invoice-dollar me-2"></i>Historial Detallado de Pagos</h3>
                    </div>
                    <div class="card-body">
                        <div class="table-responsive">
                            <% if (!pagosHijoList.isEmpty()) { %>
                            <table class="table table-hover table-striped">
                                <thead>
                                    <tr>
                                        <th>Concepto</th>
                                        <th>Monto</th>
                                        <th>F. Vencimiento</th>
                                        <th>F. Pago</th>
                                        <th>Método</th>
                                        <th>Referencia</th>
                                        <th>Estado</th>
                                        <th>Acción</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <% for (Map<String, String> pago : pagosHijoList) {%>
                                    <tr>
                                        <td><%= pago.get("concepto") %></td>
                                        <td>S/. <%= pago.get("monto") %></td>
                                        <td><%= pago.get("fecha_vencimiento") %></td>
                                        <td><%= pago.get("fecha_pago") %></td>
                                        <td><%= pago.get("metodo_pago") %></td>
                                        <td><%= pago.get("referencia") %></td>
                                        <td>
                                            <%    String estadoPago = pago.get("estado");
                                                    String badgeClass = "";
                                                    if ("PAGADO".equalsIgnoreCase(estadoPago)) { badgeClass = "bg-success"; }
                                                    else if ("PENDIENTE".equalsIgnoreCase(estadoPago)) { badgeClass = "bg-warning text-dark"; }
                                                    else if ("VENCIDO".equalsIgnoreCase(estadoPago)) { badgeClass = "bg-danger"; }
                                            %>
                                            <span class="badge badge-pago <%= badgeClass %>"><%= estadoPago %></span>
                                        </td>
                                        <td>
                                            <% if ("PENDIENTE".equalsIgnoreCase(pago.get("estado")) || "VENCIDO".equalsIgnoreCase(pago.get("estado"))) { %>
                                                <a href="<%= request.getContextPath() %>/INTERFAZ_APODERADO/realizar_pago.jsp?idPago=<%= pago.get("id_pago") %>" class="btn btn-primary btn-sm">
                                                    <i class="fas fa-money-check-alt me-1"></i> Pagar
                                                </a>
                                            <% } else { %>
                                                <button class="btn btn-primary btn-sm" disabled>
                                                    <i class="fas fa-check-circle me-1"></i> Pagado
                                                </button>
                                            <% } %>
                                        </td>
                                    </tr>
                                    <% } %>
                                </tbody>
                            </table>
                            <% } else { %>
                            <p class="text-muted text-center py-3">No hay registros de pagos disponibles para su hijo/a actualmente.</p>
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
            // --- Gráfico de Distribución de Estados de Pago (Gráfico de Torta) ---
            const countPagado = <%= countPagado %>;
            const countPendiente = <%= countPendiente %>;
            const countVencido = <%= countVencido %>;

            const ctxPaymentStatus = document.getElementById('paymentStatusChart');
            if (ctxPaymentStatus) {
                new Chart(ctxPaymentStatus.getContext('2d'), {
                    type: 'pie',
                    data: {
                        labels: ['Pagado', 'Pendiente', 'Vencido'],
                        datasets: [{
                            data: [countPagado, countPendiente, countVencido],
                            backgroundColor: [
                                '#2E8B57',    // Sea Green for Pagado (a distinct green)
                                '#F0AD4E',    // Goldenrod for Pendiente (a distinct yellow-orange)
                                '#D9534F'     // Tomato for Vencido (a distinct red)
                            ],
                            borderColor: 'var(--admin-card-bg)', // Color de borde de las secciones del gráfico
                            borderWidth: 2
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        plugins: {
                            title: {
                                display: false, // Título ya en HTML (h3)
                            },
                            legend: {
                                position: 'top', // Leyenda en la parte superior
                                labels: {
                                    font: { size: 12 },
                                    color: 'var(--admin-text-dark)'
                                }
                            },
                            tooltip: { // Estilo del tooltip
                                backgroundColor: 'rgba(0,0,0,0.8)',
                                titleFont: { weight: 'bold' },
                                bodyFont: { weight: 'normal' },
                                padding: 10,
                                cornerRadius: 5,
                                callbacks: {
                                    label: function(context) {
                                        let label = context.label || '';
                                        if (label) {
                                            label += ': ';
                                        }
                                        if (context.parsed !== null) {
                                            const total = context.dataset.data.reduce((sum, val) => sum + val, 0);
                                            const percentage = (context.parsed / total * 100).toFixed(1);
                                            label += context.parsed + ' (' + percentage + '%)';
                                        }
                                        return label;
                                    }
                                }
                            }
                        }
                    }
                });
            }
        });
    </script>
</body>
</html>