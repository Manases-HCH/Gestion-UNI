<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, pe.universidad.util.Conection, java.util.*, java.net.URLEncoder, java.nio.charset.StandardCharsets" %>
<%@ page session="true" %>

<%
    // --- LÓGICA DE SESIÓN Y ACCIONES ---
    String emailSesion = (String) session.getAttribute("email");
    String rolUsuario = (String) session.getAttribute("rol");
    Object idAlumnoObj = session.getAttribute("id_alumno");

    if (emailSesion == null || !"alumno".equalsIgnoreCase(rolUsuario) || idAlumnoObj == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    int idAlumno = (Integer) idAlumnoObj;
    String nombreAlumno = (String) session.getAttribute("nombre_alumno");

    String action = request.getParameter("action");
    String cursoIdParam = request.getParameter("id_curso");
    String message = null;
    String messageType = null;

    if (action != null && cursoIdParam != null) {
        Connection connAction = null;
        PreparedStatement pstmtAction = null;
        try {
            int idCurso = Integer.parseInt(cursoIdParam);
            String tipoSolicitud = "UNIRSE".equals(action) ? "UNIRSE" : "SALIR";
            Conection c = new Conection();
            connAction = c.conecta();
            String sqlInsert = "INSERT INTO solicitudes_cursos_alumnos (id_alumno, id_curso, tipo_solicitud, estado, fecha_solicitud) VALUES (?, ?, ?, 'PENDIENTE', NOW())";
            pstmtAction = connAction.prepareStatement(sqlInsert);
            pstmtAction.setInt(1, idAlumno);
            pstmtAction.setInt(2, idCurso);
            pstmtAction.setString(3, tipoSolicitud);
            pstmtAction.executeUpdate();
            message = "Solicitud para " + tipoSolicitud.toLowerCase() + " enviada correctamente.";
            messageType = "success";
        } catch (Exception e) {
            message = "Error al procesar la solicitud.";
            messageType = "danger";
        } finally {
            if (pstmtAction != null) try { pstmtAction.close(); } catch (SQLException e) {}
            if (connAction != null) try { connAction.close(); } catch (SQLException e) {}
        }
        response.sendRedirect(request.getRequestURI() + "?message=" + URLEncoder.encode(message, StandardCharsets.UTF_8.toString()) + "&type=" + messageType);
        return;
    }
    message = request.getParameter("message");
    messageType = request.getParameter("type");
%>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Catálogo de Cursos | Portal Alumno</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        body { 
            background-color: #eef2f5; 
            font-family: 'Segoe UI', system-ui, -apple-system, BlinkMacSystemFont, sans-serif;
        }
        .section-title {
            font-weight: 600;
            color: #343a40;
            margin-bottom: 1.5rem;
            display: flex;
            align-items: center;
        }
        .section-title i {
            font-size: 1.5rem;
            margin-right: 0.75rem;
            color: #0d6efd;
        }
        .course-card {
            transition: transform 0.2s ease-in-out, box-shadow 0.2s ease-in-out;
            border: none;
            border-radius: 0.75rem;
            box-shadow: 0 4px 6px rgba(0,0,0,0.05);
            display: flex;
            flex-direction: column;
            height: 100%;
        }
        .course-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 12px 20px rgba(0,0,0,0.08);
        }
        .course-card .card-img-top-placeholder {
            background-color: #4a69bd;
            color: white;
            height: 140px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 3rem;
            border-top-left-radius: 0.75rem;
            border-top-right-radius: 0.75rem;
        }
        .course-card .card-body {
            flex-grow: 1;
            display: flex;
            flex-direction: column;
        }
        .course-card .card-title {
            font-weight: 600;
            color: #212529;
        }
        .course-card .card-footer {
            background-color: #ffffff;
            border-top: 1px solid #f1f1f1;
        }
        .nav-scroller {
            position: sticky;
            top: 0;
            z-index: 1020;
        }
    </style>
</head>
<body>

<div class="container my-5">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h1 class="h3">Catálogo de Cursos</h1>
        <a href="home_alumno.jsp" class="btn btn-outline-secondary"><i class="fas fa-arrow-left me-2"></i>Volver al Inicio</a>
    </div>

    <div class="nav-scroller bg-body shadow-sm p-2 mb-4 rounded">
        <nav class="nav nav-pills">
            <a class="nav-link" href="#cursos-disponibles">
                <i class="fas fa-chalkboard-teacher me-2"></i>Ver Cursos Disponibles
            </a>
            <a class="nav-link" href="#mis-cursos">
                <i class="fas fa-user-graduate me-2"></i>Ir a Mis Cursos (Para Retiro)
            </a>
        </nav>
    </div>
    <% if (message != null) { %>
        <div class="alert alert-<%= "success".equals(messageType) ? "success" : "danger" %> alert-dismissible fade show" role="alert">
            <i class="fas fa-<%= "success".equals(messageType) ? "check-circle" : "exclamation-triangle" %> me-2"></i>
            <%= message %>
            <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
        </div>
    <% } %>

    <div class="mb-5">
        <h2 id="cursos-disponibles" class="section-title"><i class="fas fa-chalkboard-teacher"></i>Cursos Disponibles</h2>
        <div class="row row-cols-1 row-cols-md-2 row-cols-lg-3 g-4">
            <%
            Connection conn1 = null; PreparedStatement pstmt1 = null; ResultSet rs1 = null;
            try {
                conn1 = new Conection().conecta();
                String sql1 = "SELECT c.id_curso, c.nombre_curso, c.creditos, ca.nombre_carrera, " +
                              "(SELECT estado FROM solicitudes_cursos_alumnos sca WHERE sca.id_curso = c.id_curso AND sca.id_alumno = ? AND sca.tipo_solicitud = 'UNIRSE' AND sca.estado = 'PENDIENTE') AS solicitud_estado " +
                              "FROM cursos c JOIN carreras ca ON c.id_carrera = ca.id_carrera " +
                              "WHERE c.estado = 'activo' AND c.id_curso NOT IN (SELECT cl.id_curso FROM inscripciones i JOIN clases cl ON i.id_clase = cl.id_clase WHERE i.id_alumno = ?)";
                pstmt1 = conn1.prepareStatement(sql1);
                pstmt1.setInt(1, idAlumno);
                pstmt1.setInt(2, idAlumno);
                rs1 = pstmt1.executeQuery();
                boolean found1 = false;
                while(rs1.next()) {
                    found1 = true;
            %>
                    <div class="col">
                        <div class="card course-card">
                            <div class="card-img-top-placeholder"><i class="fas fa-book-open"></i></div>
                            <div class="card-body">
                                <h5 class="card-title"><%= rs1.getString("nombre_curso") %></h5>
                                <p class="card-text text-muted"><%= rs1.getString("nombre_carrera") %></p>
                                <div class="mt-auto">
                                    <span class="badge bg-primary-subtle text-primary-emphasis rounded-pill"><%= rs1.getInt("creditos") %> Créditos</span>
                                </div>
                            </div>
                            <div class="card-footer text-center">
                                <% if (rs1.getString("solicitud_estado") != null) { %>
                                    <button class="btn btn-secondary w-100" disabled><i class="fas fa-hourglass-half me-2"></i> Solicitud Pendiente</button>
                                <% } else { %>
                                    <form action="<%= request.getRequestURI() %>" method="POST">
                                        <input type="hidden" name="action" value="UNIRSE">
                                        <input type="hidden" name="id_curso" value="<%= rs1.getInt("id_curso") %>">
                                        <button type="submit" class="btn btn-primary w-100"><i class="fas fa-plus me-2"></i> Solicitar Inscripción</button>
                                    </form>
                                <% } %>
                            </div>
                        </div>
                    </div>
            <%  }
                if (!found1) { %>
                    <div class="col-12">
                        <div class="text-center p-5 bg-light rounded">
                            <i class="fas fa-check-circle fa-3x text-success mb-3"></i>
                            <h4>¡Excelente!</h4>
                            <p class="text-muted">No hay nuevos cursos disponibles para ti en este momento.</p>
                        </div>
                    </div>
                <% }
            } finally {
                if (rs1 != null) rs1.close(); if (pstmt1 != null) pstmt1.close(); if (conn1 != null) conn1.close();
            }
            %>
        </div>
    </div>

    <div>
        <h2 id="mis-cursos" class="section-title"><i class="fas fa-user-graduate"></i>Mis Cursos Inscritos</h2>
        <div class="row row-cols-1 row-cols-md-2 row-cols-lg-3 g-4">
             <%
            Connection conn2 = null; PreparedStatement pstmt2 = null; ResultSet rs2 = null;
            try {
                conn2 = new Conection().conecta();
                String sql2 = "SELECT c.id_curso, c.nombre_curso, cl.seccion, " +
                              " (SELECT estado FROM solicitudes_cursos_alumnos sca WHERE sca.id_curso = c.id_curso AND sca.id_alumno = ? AND sca.tipo_solicitud = 'SALIR' AND sca.estado = 'PENDIENTE') AS solicitud_estado " +
                              "FROM inscripciones i JOIN clases cl ON i.id_clase = cl.id_clase JOIN cursos c ON cl.id_curso = c.id_curso " +
                              "WHERE i.id_alumno = ? AND i.estado = 'inscrito'";
                pstmt2 = conn2.prepareStatement(sql2);
                pstmt2.setInt(1, idAlumno);
                pstmt2.setInt(2, idAlumno);
                rs2 = pstmt2.executeQuery();
                boolean found2 = false;
                while(rs2.next()) {
                    found2 = true;
            %>
                    <div class="col">
                        <div class="card course-card">
                             <div class="card-img-top-placeholder bg-success"><i class="fas fa-check"></i></div>
                             <div class="card-body">
                                <h5 class="card-title"><%= rs2.getString("nombre_curso") %></h5>
                                <p class="card-text text-muted">Sección: <%= rs2.getString("seccion") %></p>
                             </div>
                             <div class="card-footer text-center">
                                <% if (rs2.getString("solicitud_estado") != null) { %>
                                    <button class="btn btn-secondary w-100" disabled><i class="fas fa-hourglass-half me-2"></i> Solicitud Pendiente</button>
                                <% } else { %>
                                    <form action="<%= request.getRequestURI() %>" method="POST">
                                        <input type="hidden" name="action" value="SALIR">
                                        <input type="hidden" name="id_curso" value="<%= rs2.getInt("id_curso") %>">
                                        <button type="submit" class="btn btn-outline-danger w-100"><i class="fas fa-minus me-2"></i> Solicitar Retiro</button>
                                    </form>
                                <% } %>
                             </div>
                        </div>
                    </div>
            <%  }
                if (!found2) { %>
                    <div class="col-12">
                        <div class="text-center p-5 bg-light rounded">
                            <i class="fas fa-folder-open fa-3x text-muted mb-3"></i>
                            <h4>Aún no estás inscrito en cursos</h4>
                             <p class="text-muted">Puedes solicitar tu inscripción desde la sección de cursos disponibles.</p>
                        </div>
                    </div>
                <% }
            } finally {
                if (rs2 != null) rs2.close(); if (pstmt2 != null) pstmt2.close(); if (conn2 != null) conn2.close();
            }
            %>
        </div>
    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>

<script>
    document.addEventListener('DOMContentLoaded', function() {
        document.querySelectorAll('.nav-scroller .nav-link').forEach(anchor => {
            anchor.addEventListener('click', function (e) {
                e.preventDefault();
                const targetId = this.getAttribute('href');
                const targetElement = document.querySelector(targetId);
                if (targetElement) {
                    // Calculamos la posición del elemento y un pequeño margen superior.
                    const offsetTop = targetElement.getBoundingClientRect().top + window.pageYOffset - 80; // 80px de margen
                    window.scrollTo({
                        top: offsetTop,
                        behavior: 'smooth'
                    });
                }
            });
        });
    });
</script>
</body>
</html>