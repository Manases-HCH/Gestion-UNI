<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, pe.universidad.util.Conection, java.util.*, java.time.*, java.time.format.*, java.text.DecimalFormat, java.util.Locale" %>
<%@ page session="true" %>

<%!
    // Método para cerrar recursos de BD
    private void cerrarRecursos(ResultSet rs, PreparedStatement pstmt) {
        try { if (rs != null) rs.close(); } catch (SQLException e) {}
        try { if (pstmt != null) pstmt.close(); } catch (SQLException e) {}
    }
%>

<%
    // --- 1. LÓGICA DE SESIÓN Y DATOS (SIN CAMBIOS) ---
    String email = (String) session.getAttribute("email");
    Object idAlumnoObj = session.getAttribute("id_alumno");

    if (email == null || idAlumnoObj == null || !"alumno".equalsIgnoreCase((String)session.getAttribute("rol"))) {
        response.sendRedirect("login.jsp");
        return;
    }
    int idAlumno = (Integer) idAlumnoObj;

    String nombreCompleto = "Alumno";
    String carrera = "No especificada";
    String estadoAcademico = "No disponible";
    String ultimoAcceso = LocalDateTime.now().format(DateTimeFormatter.ofPattern("d 'de' MMMM, HH:mm", new Locale("es", "ES")));

    int cursosInscritos = 0;
    int creditosAprobados = 0;
    double promedioPonderado = 0.0;
    int pagosPendientes = 0;

    List<Map<String, String>> anuncios = new ArrayList<>();
    
    List<String> nombresCursosNotas = new ArrayList<>();
    List<Double> misNotas = new ArrayList<>();
    int totalPresente = 0;
    int totalAusente = 0;
    int totalTardanza = 0;

    Connection conn = null;

    try {
        conn = new Conection().conecta();
        PreparedStatement pstmtAlumno = conn.prepareStatement("SELECT nombre_completo, nombre_carrera, estado FROM vista_alumnos_completa WHERE id_alumno = ?");
        pstmtAlumno.setInt(1, idAlumno);
        ResultSet rsAlumno = pstmtAlumno.executeQuery();
        if (rsAlumno.next()) {
            nombreCompleto = rsAlumno.getString("nombre_completo");
            carrera = rsAlumno.getString("nombre_carrera");
            estadoAcademico = rsAlumno.getString("estado");
        }
        cerrarRecursos(rsAlumno, pstmtAlumno);

        PreparedStatement pstmtCursosCount = conn.prepareStatement("SELECT COUNT(*) FROM inscripciones WHERE id_alumno = ? AND estado = 'inscrito'");
        pstmtCursosCount.setInt(1, idAlumno);
        ResultSet rsCursosCount = pstmtCursosCount.executeQuery();
        if (rsCursosCount.next()) cursosInscritos = rsCursosCount.getInt(1);
        cerrarRecursos(rsCursosCount, pstmtCursosCount);

        PreparedStatement pstmtNotasStats = conn.prepareStatement(
            "SELECT SUM(c.creditos) AS creditos_aprobados FROM notas n " +
            "JOIN inscripciones i ON n.id_inscripcion = i.id_inscripcion " +
            "JOIN clases cl ON i.id_clase = cl.id_clase " +
            "JOIN cursos c ON cl.id_curso = c.id_curso " +
            "WHERE i.id_alumno = ? AND n.nota_final >= 11"
        );
        pstmtNotasStats.setInt(1, idAlumno);
        ResultSet rsNotasStats = pstmtNotasStats.executeQuery();
        if (rsNotasStats.next()) creditosAprobados = rsNotasStats.getInt("creditos_aprobados");
        cerrarRecursos(rsNotasStats, pstmtNotasStats);

        PreparedStatement pstmtPromedio = conn.prepareStatement("SELECT AVG(n.nota_final) as promedio FROM notas n JOIN inscripciones i ON n.id_inscripcion = i.id_inscripcion WHERE i.id_alumno = ?");
        pstmtPromedio.setInt(1, idAlumno);
        ResultSet rsPromedio = pstmtPromedio.executeQuery();
        if(rsPromedio.next()) promedioPonderado = rsPromedio.getDouble("promedio");
        cerrarRecursos(rsPromedio, pstmtPromedio);

        PreparedStatement pstmtPagos = conn.prepareStatement("SELECT COUNT(*) FROM pagos WHERE id_alumno = ? AND estado = 'pendiente'");
        pstmtPagos.setInt(1, idAlumno);
        ResultSet rsPagos = pstmtPagos.executeQuery();
        if (rsPagos.next()) pagosPendientes = rsPagos.getInt(1);
        cerrarRecursos(rsPagos, pstmtPagos);
        
        PreparedStatement pstmtNotasChart = conn.prepareStatement("SELECT c.nombre_curso, n.nota_final FROM notas n JOIN inscripciones i ON n.id_inscripcion = i.id_inscripcion JOIN clases cl ON i.id_clase = cl.id_clase JOIN cursos c ON cl.id_curso = c.id_curso WHERE i.id_alumno = ? AND n.nota_final IS NOT NULL");
        pstmtNotasChart.setInt(1, idAlumno);
        ResultSet rsNotasChart = pstmtNotasChart.executeQuery();
        while(rsNotasChart.next()){
            nombresCursosNotas.add(rsNotasChart.getString("nombre_curso"));
            misNotas.add(rsNotasChart.getDouble("nota_final"));
        }
        cerrarRecursos(rsNotasChart, pstmtNotasChart);

        PreparedStatement pstmtAsistencia = conn.prepareStatement("SELECT estado, COUNT(*) as count FROM asistencia a JOIN inscripciones i ON a.id_inscripcion = i.id_inscripcion WHERE i.id_alumno = ? GROUP BY estado");
        pstmtAsistencia.setInt(1, idAlumno);
        ResultSet rsAsistencia = pstmtAsistencia.executeQuery();
        while(rsAsistencia.next()){
            String estado = rsAsistencia.getString("estado");
            if("presente".equalsIgnoreCase(estado)) totalPresente = rsAsistencia.getInt("count");
            else if("ausente".equalsIgnoreCase(estado)) totalAusente = rsAsistencia.getInt("count");
            else if("tardanza".equalsIgnoreCase(estado)) totalTardanza = rsAsistencia.getInt("count");
        }
        cerrarRecursos(rsAsistencia, pstmtAsistencia);
        
        PreparedStatement pstmtAnuncios = conn.prepareStatement("SELECT titulo, contenido, fecha_publicacion FROM anuncios ORDER BY fecha_publicacion DESC LIMIT 3");
        ResultSet rsAnuncios = pstmtAnuncios.executeQuery();
        while(rsAnuncios.next()){
            Map<String, String> anuncio = new HashMap<>();
            anuncio.put("titulo", rsAnuncios.getString("titulo"));
            anuncio.put("contenido", rsAnuncios.getString("contenido"));
            anuncio.put("fecha", rsAnuncios.getTimestamp("fecha_publicacion").toLocalDateTime().format(DateTimeFormatter.ofPattern("dd MMM Yelp", new Locale("es", "ES"))));
            anuncios.add(anuncio);
        }
        cerrarRecursos(rsAnuncios, pstmtAnuncios);
        
    } catch (Exception e) {
        e.printStackTrace();
    } finally {
        if (conn != null) try { conn.close(); } catch (SQLException e) {}
    }
    
    DecimalFormat df = new DecimalFormat("#.00");
%>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard Alumno | Sistema Universitario</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --bs-primary-rgb: 13, 110, 253;
            --sidebar-bg: #222B40;
            --light-bg: #F0F2F5;
        }
        body { background-color: var(--light-bg); font-family: 'Inter', sans-serif; }
        .sidebar { width: 260px; background-color: var(--sidebar-bg); position: fixed; height: 100%; z-index: 1030;}
        .sidebar-header { padding: 1.25rem; text-align: center; font-size: 1.5rem; font-weight: bold; color: #fff; border-bottom: 1px solid rgba(255, 255, 255, 0.1); }
        .sidebar .nav-link { color: rgba(255, 255, 255, 0.7); padding: 0.75rem 1.5rem; }
        .sidebar .nav-link:hover, .sidebar .nav-link.active { color: #fff; background-color: rgba(255, 255, 255, 0.08); }
        
        .main-content { 
            margin-left: 260px; 
            padding: 2rem; 
            flex: 1; /* <-- ESTA ES LA LÍNEA CORREGIDA */
        }

        .stat-card { border: none; border-left: 5px solid var(--bs-primary); box-shadow: 0 4px 12px rgba(0,0,0,0.05); }
        .stat-card .icon { font-size: 2rem; opacity: 0.3; }
        .action-card { text-align: center; padding: 1.5rem; border-radius: 0.75rem; background-color: #fff; box-shadow: 0 4px 12px rgba(0,0,0,0.05); transition: transform 0.2s, box-shadow 0.2s; }
        .action-card:hover { transform: translateY(-5px); box-shadow: 0 8px 16px rgba(0,0,0,0.1); }
        .action-card i { font-size: 2.5rem; margin-bottom: 1rem; color: var(--bs-primary); }
        .action-card a { text-decoration: none; color: inherit; }
        .chart-container { height: 350px; }
    </style>
</head>
<body>
    <div class="d-flex">
        <nav class="sidebar">
            <div class="sidebar-header">Portal UGIC</div>
            <ul class="nav flex-column mt-3">
                <li class="nav-item"><a class="nav-link active" href="home_alumno.jsp"><i class="fas fa-home fa-fw me-2"></i>Inicio</a></li>
                <li class="nav-item"><a class="nav-link" href="cursos_alumno.jsp"><i class="fas fa-book fa-fw me-2"></i>Mis Cursos</a></li>
                <li class="nav-item"><a class="nav-link" href="asistencia_alumno.jsp"><i class="fas fa-clipboard-check fa-fw me-2"></i>Mi Asistencia</a></li>
                <li class="nav-item"><a class="nav-link" href="notas_alumno.jsp"><i class="fas fa-percent fa-fw me-2"></i>Mis Notas</a></li>
                <li class="nav-item"><a class="nav-link" href="pagos_alumno.jsp"><i class="fas fa-money-bill-wave fa-fw me-2"></i>Mis Pagos</a></li>
                <li class="nav-item"><a class="nav-link" href="mensajes_alumno.jsp"><i class="fas fa-envelope fa-fw me-2"></i>Mensajes</a></li>
                <li class="nav-item"><a class="nav-link" href="perfil_alumno.jsp"><i class="fas fa-user-circle fa-fw me-2"></i>Mi Perfil</a></li>
                <li class="nav-item"><a class="nav-link" href="configuracion_alumno.jsp"><i class="fas fa-cog fa-fw me-2"></i>Configuración</a></li>
                <li class="nav-item mt-auto"><a class="nav-link" href="logout.jsp"><i class="fas fa-sign-out-alt fa-fw me-2"></i>Cerrar Sesión</a></li>
            </ul>
        </nav>

        <main class="main-content">
            <div class="container-fluid">
                <div class="p-4 mb-4 bg-white rounded shadow-sm">
                    <h1 class="h3">¡Bienvenido de nuevo, <%= nombreCompleto.split(" ")[0] %>!</h1>
                    <p class="text-muted mb-0">Último acceso: <%= ultimoAcceso %></p>
                </div>
                
                <div class="card mb-4 shadow-sm">
                    <div class="card-body">
                        <div class="row align-items-center">
                            <div class="col-md-2 text-center mb-3 mb-md-0">
                                <i class="fas fa-user-circle fa-5x text-secondary"></i>
                            </div>
                            <div class="col-md-10">
                                <h4 class="card-title mb-1"><%= nombreCompleto %></h4>
                                <p class="text-muted mb-2">Estudiante de <strong><%= carrera %></strong></p>
                                <span class="badge bg-success-subtle text-success-emphasis rounded-pill fs-6">
                                    <i class="fas fa-check-circle me-1"></i> Estado: <%= estadoAcademico %>
                                </span>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="row mb-4">
                    <div class="col-lg-3 col-md-6 mb-3">
                        <div class="card stat-card border-primary h-100">
                            <div class="card-body d-flex justify-content-between align-items-center">
                                <div>
                                    <h6 class="card-title text-muted">Cursos Inscritos</h6>
                                    <h2 class="card-text fw-bold"><%= cursosInscritos %></h2>
                                </div>
                                <i class="fas fa-book-open icon text-primary"></i>
                            </div>
                        </div>
                    </div>
                    <div class="col-lg-3 col-md-6 mb-3">
                        <div class="card stat-card border-success h-100">
                            <div class="card-body d-flex justify-content-between align-items-center">
                                <div>
                                    <h6 class="card-title text-muted">Créditos Aprobados</h6>
                                    <h2 class="card-text fw-bold"><%= creditosAprobados %></h2>
                                </div>
                                <i class="fas fa-check-double icon text-success"></i>
                            </div>
                        </div>
                    </div>
                    <div class="col-lg-3 col-md-6 mb-3">
                        <div class="card stat-card border-info h-100">
                            <div class="card-body d-flex justify-content-between align-items-center">
                                <div>
                                    <h6 class="card-title text-muted">Promedio Ponderado</h6>
                                    <h2 class="card-text fw-bold"><%= df.format(promedioPonderado) %></h2>
                                </div>
                                 <i class="fas fa-star-half-alt icon text-info"></i>
                            </div>
                        </div>
                    </div>
                    <div class="col-lg-3 col-md-6 mb-3">
                         <div class="card stat-card border-danger h-100">
                            <div class="card-body d-flex justify-content-between align-items-center">
                                <div>
                                    <h6 class="card-title text-muted">Pagos Pendientes</h6>
                                    <h2 class="card-text fw-bold"><%= pagosPendientes %></h2>
                                </div>
                                 <i class="fas fa-file-invoice-dollar icon text-danger"></i>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="row mb-4">
                    <div class="col-lg-7 mb-3">
                        <div class="card h-100">
                            <div class="card-body">
                                <h5 class="card-title">Mis Notas por Curso</h5>
                                <div class="chart-container">
                                    <canvas id="notasChart"></canvas>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="col-lg-5 mb-3">
                         <div class="card h-100">
                            <div class="card-body">
                                <h5 class="card-title">Mi Récord de Asistencia</h5>
                                 <div class="chart-container">
                                    <canvas id="asistenciaChart"></canvas>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                
                 <div class="row">
                    <div class="col-lg-7 mb-3">
                        <div class="card h-100">
                            <div class="card-body">
                                <h5 class="card-title mb-3">Acceso Rápido</h5>
                                <div class="row g-3">
                                    <div class="col-md-6"><div class="action-card"><a href="horario_alumno.jsp"><i class="fas fa-calendar-week"></i><h6>Ver Horario</h6></a></div></div>
                                    <div class="col-md-6"><div class="action-card"><a href="pagos_alumno.jsp"><i class="fas fa-dollar-sign"></i><h6>Realizar Pagos</h6></a></div></div>
                                    <div class="col-md-6"><div class="action-card"><a href="notas_alumno.jsp"><i class="fas fa-poll"></i><h6>Mis Calificaciones</h6></a></div></div>
                                    <div class="col-md-6"><div class="action-card"><a href="solicitud_curso_alumno.jsp"><i class="fas fa-plus"></i><h6>Inscripción a Cursos</h6></a></div></div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="col-lg-5 mb-3">
                        <div class="card h-100">
                            <div class="card-body">
                                <h5 class="card-title mb-3">Anuncios Recientes</h5>
                                <% if (anuncios.isEmpty()) { %>
                                    <p class="text-muted">No hay anuncios nuevos.</p>
                                <% } else { %>
                                    <div class="list-group list-group-flush">
                                    <% for(Map<String, String> anuncio : anuncios) { %>
                                        <a href="#" class="list-group-item list-group-item-action">
                                            <div class="d-flex w-100 justify-content-between">
                                                <h6 class="mb-1"><%= anuncio.get("titulo") %></h6>
                                                <small class="text-muted"><%= anuncio.get("fecha") %></small>
                                            </div>
                                            <p class="mb-1 text-muted small"><%= anuncio.get("contenido").length() > 80 ? anuncio.get("contenido").substring(0, 80) + "..." : anuncio.get("contenido") %></p>
                                        </a>
                                    <% } %>
                                    </div>
                                <% } %>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </main>
    </div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
<script>
document.addEventListener('DOMContentLoaded', function () {
    // --- Gráfico de Notas ---
    const ctxNotas = document.getElementById('notasChart');
    if (ctxNotas && <%= misNotas.size() %> > 0) {
        new Chart(ctxNotas, {
            type: 'bar',
            data: {
                labels: [<% for(int i=0; i<nombresCursosNotas.size(); i++) out.print("'" + nombresCursosNotas.get(i).replace("'", "\\'") + (i < nombresCursosNotas.size()-1 ? "'," : "'")); %>],
                datasets: [{
                    label: 'Mi Nota Final',
                    data: [<% for(int i=0; i<misNotas.size(); i++) out.print(misNotas.get(i) + (i < misNotas.size()-1 ? "," : "")); %>],
                    backgroundColor: 'rgba(13, 110, 253, 0.6)',
                    borderColor: 'rgba(13, 110, 253, 1)',
                    borderWidth: 1,
                    borderRadius: 5
                }]
            },
            options: { responsive: true, maintainAspectRatio: false, scales: { y: { beginAtZero: true, max: 20 } }, plugins: { legend: { display: false } } }
        });
    }

    // --- Gráfico de Asistencia ---
    const ctxAsistencia = document.getElementById('asistenciaChart');
    if (ctxAsistencia && (<%= totalPresente + totalAusente + totalTardanza %>) > 0) {
        new Chart(ctxAsistencia, {
            type: 'doughnut',
            data: {
                labels: ['Presente', 'Ausente', 'Tardanza'],
                datasets: [{
                    data: [<%= totalPresente %>, <%= totalAusente %>, <%= totalTardanza %>],
                    backgroundColor: ['rgba(25, 135, 84, 0.8)', 'rgba(220, 53, 69, 0.8)', 'rgba(255, 193, 7, 0.8)'],
                    borderColor: ['#fff'],
                    borderWidth: 3
                }]
            },
            options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { position: 'bottom' } } }
        });
    }
});
</script>
</body>
</html>