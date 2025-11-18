<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="pe.edu.entity.Inscripcion, pe.edu.dao.InscripcionDao" %>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <%@include file="../util/referencias.jsp" %>
        <title>Ver Inscripción</title>        
    </head>
    
    <%-- Instancia de InscripcionDao para interactuar con la base de datos --%>
    <jsp:useBean id="inscripcionDao" class="pe.edu.dao.InscripcionDao" scope="session"></jsp:useBean>
    
    <body>            
        <div class="container-fluid">
            <div class="row flex-nowrap">
                <%@include file="../menu.jsp" %>
                <div class="col py-3">    
                    <%-- Instancia de Inscripcion para almacenar los datos de la inscripción a ver --%>
                    <jsp:useBean id="inscripcion" class="pe.edu.entity.Inscripcion" scope="request"></jsp:useBean>
                    <%
                        String mensaje = "";
                        String tipoMensaje = "";

                        try {
                            // Obtener el ID de la inscripción desde la URL
                            String id = request.getParameter("id");
                            
                            // Si el ID no es nulo, cargar los datos de la inscripción de la base de datos
                            if (id != null && !id.isEmpty()) {
                                Inscripcion inscripcionExistente = inscripcionDao.leer(id);
                                if (inscripcionExistente != null) {
                                    // Establecer las propiedades del bean 'inscripcion' con los datos existentes
                                    inscripcion.setIdInscripcion(inscripcionExistente.getIdInscripcion());
                                    inscripcion.setIdAlumno(inscripcionExistente.getIdAlumno());
                                    inscripcion.setIdClase(inscripcionExistente.getIdClase());
                                    inscripcion.setFechaInscripcion(inscripcionExistente.getFechaInscripcion());
                                    inscripcion.setEstado(inscripcionExistente.getEstado());
                                } else {
                                    mensaje = "No se encontró la inscripción con ID: " + id + ".";
                                    tipoMensaje = "danger";
                                }
                            } else {
                                mensaje = "ID de inscripción no proporcionado para ver detalles.";
                                tipoMensaje = "warning";
                            }
                        } catch (Exception e) {
                            mensaje = "Error al cargar los datos de la inscripción: " + e.getMessage();
                            tipoMensaje = "danger";
                            e.printStackTrace(); // Para depuración
                        }
                    %>
                    
                    <div class="container">
                        <div class="row justify-content-center">
                            <div class="col-md-8 col-lg-6">
                                <%-- Mostrar mensajes de error o información --%>
                                <% if (!mensaje.isEmpty()) { %>
                                    <div class="alert alert-<%= tipoMensaje %> alert-dismissible fade show" role="alert">
                                        <%= mensaje %>
                                        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                                    </div>
                                <% } %>

                                <% if (inscripcion.getIdInscripcion() != "") { // Si el ID es 0, asumimos que no se encontró %>
                                    <div class="card shadow">
                                        <div class="card-header bg-info text-white">
                                            <h4 class="mb-0">
                                                <i class="fas fa-eye me-2"></i>Detalles de la Inscripción
                                            </h4>
                                        </div>
                                        <div class="card-body">
                                            <%-- En el caso de "ver", no hay formulario POST. Se muestra solo información. --%>
                                            <div class="mb-3">
                                                <label class="form-label fw-bold"><i class="fas fa-fingerprint me-1"></i>ID Inscripción:</label>
                                                <p class="form-control-plaintext"><%= inscripcion.getIdInscripcion() %></p>
                                            </div>
                                            
                                            <div class="mb-3">
                                                <label class="form-label fw-bold"><i class="fas fa-user-graduate me-1"></i>ID Alumno:</label>
                                                <p class="form-control-plaintext"><%= inscripcion.getIdAlumno() %></p>
                                            </div>
                                            
                                            <div class="mb-3">
                                                <label class="form-label fw-bold"><i class="fas fa-chalkboard me-1"></i>ID Clase:</label>
                                                <p class="form-control-plaintext"><%= inscripcion.getIdClase() %></p>
                                            </div>

                                            <div class="mb-3">
                                                <label class="form-label fw-bold"><i class="fas fa-calendar-alt me-1"></i>Fecha de Inscripción:</label>
                                                <p class="form-control-plaintext"><%= inscripcion.getFechaInscripcion() %></p>
                                            </div>

                                            <div class="mb-3">
                                                <label class="form-label fw-bold"><i class="fas fa-check-circle me-1"></i>Estado:</label>
                                                <p class="form-control-plaintext"><%= inscripcion.getEstado() %></p>
                                            </div>
                                            
                                            <div class="d-grid gap-2">
                                                <a href="listado.jsp" class="btn btn-primary d-flex align-items-center justify-content-center">
                                                    <i class="fas fa-arrow-alt-circle-left me-2"></i>Volver al Listado
                                                </a>
                                            </div>
                                        </div>
                                    </div>
                                <% } else { %>
                                    <div class="alert alert-info mt-3" role="alert">
                                        No hay datos de inscripción para mostrar. Por favor, asegúrese de que el ID sea válido.
                                    </div>
                                <% } %>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </body>
</html>

<%-- Scripts (no necesarios en esta página, ya incluidos en referencias.jsp) --%>
<script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/js/all.min.js"></script>
<script type="text/javascript">
    let table = new DataTable('#myTable');
</script>   