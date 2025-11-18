<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="pe.edu.entity.Nota, pe.edu.dao.NotaDao" %>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <%@include file="../util/referencias.jsp" %>
        <title>Ver Nota</title>        
    </head>
    
    <%-- Instancia de NotaDao para interactuar con la base de datos --%>
    <jsp:useBean id="notaDao" class="pe.edu.dao.NotaDao" scope="session"></jsp:useBean>
    
    <body>            
        <div class="container-fluid">
            <div class="row flex-nowrap">
                <%@include file="../menu.jsp" %>
                <div class="col py-3">    
                    <%-- Instancia de Nota para almacenar los datos de la nota a ver --%>
                    <jsp:useBean id="nota" class="pe.edu.entity.Nota" scope="request"></jsp:useBean>
                    <%
                        String mensaje = "";
                        String tipoMensaje = "";

                        try {
                            // Obtener el ID de la nota desde la URL
                            String id = request.getParameter("id");
                            
                            // Si el ID no es nulo, cargar los datos de la nota de la base de datos
                            if (id != null && !id.isEmpty()) {
                                Nota notaExistente = notaDao.leer(id);
                                if (notaExistente != null) {
                                    // Establecer las propiedades del bean 'nota' con los datos existentes
                                    nota.setIdNota(notaExistente.getIdNota());
                                    nota.setIdInscripcion(notaExistente.getIdInscripcion());
                                    nota.setNota1(notaExistente.getNota1());
                                    nota.setNota2(notaExistente.getNota2());
                                    nota.setNotaFinal(notaExistente.getNotaFinal());
                                    nota.setEstado(notaExistente.getEstado());
                                } else {
                                    mensaje = "No se encontró la nota con ID: " + id + ".";
                                    tipoMensaje = "danger";
                                }
                            } else {
                                mensaje = "ID de nota no proporcionado para ver detalles.";
                                tipoMensaje = "warning";
                            }
                        } catch (Exception e) {
                            mensaje = "Error al cargar los datos de la nota: " + e.getMessage();
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

                                <% if (nota.getIdNota() != "") { // Si el ID es 0, asumimos que no se encontró %>
                                    <div class="card shadow">
                                        <div class="card-header bg-info text-white">
                                            <h4 class="mb-0">
                                                <i class="fas fa-eye me-2"></i>Detalles de la Nota
                                            </h4>
                                        </div>
                                        <div class="card-body">
                                            <%-- En el caso de "ver", no hay formulario POST. Se muestra solo información. --%>
                                            <div class="mb-3">
                                                <label class="form-label fw-bold"><i class="fas fa-fingerprint me-1"></i>ID Nota:</label>
                                                <p class="form-control-plaintext"><%= nota.getIdNota() %></p>
                                            </div>
                                            
                                            <div class="mb-3">
                                                <label class="form-label fw-bold"><i class="fas fa-id-badge me-1"></i>ID Inscripción:</label>
                                                <p class="form-control-plaintext"><%= nota.getIdInscripcion() %></p>
                                            </div>
                                            
                                            <div class="mb-3">
                                                <label class="form-label fw-bold"><i class="fas fa-calculator me-1"></i>Nota 1:</label>
                                                <p class="form-control-plaintext"><%= nota.getNota1() %></p>
                                            </div>

                                            <div class="mb-3">
                                                <label class="form-label fw-bold"><i class="fas fa-calculator me-1"></i>Nota 2:</label>
                                                <p class="form-control-plaintext"><%= nota.getNota2() %></p>
                                            </div>

                                            <div class="mb-3">
                                                <label class="form-label fw-bold"><i class="fas fa-trophy me-1"></i>Nota Final:</label>
                                                <p class="form-control-plaintext"><%= nota.getNotaFinal() %></p>
                                            </div>
                                            
                                            <div class="mb-3">
                                                <label class="form-label fw-bold"><i class="fas fa-check-circle me-1"></i>Estado:</label>
                                                <p class="form-control-plaintext"><%= nota.getEstado() %></p>
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
                                        No hay datos de nota para mostrar. Por favor, asegúrese de que el ID sea válido.
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