<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="pe.edu.entity.Horario, pe.edu.dao.HorarioDao" %>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <%@include file="../util/referencias.jsp" %>
        <title>Confirmar Eliminación de Horario</title>        
    </head>
    
    <%-- Instancia de HorarioDao para interactuar con la base de datos --%>
    <jsp:useBean id="horarioDao" class="pe.edu.dao.HorarioDao" scope="session"></jsp:useBean>
    
    <body>            
        <div class="container-fluid">
            <div class="row flex-nowrap">
                <%@include file="../menu.jsp" %>
                    
                <div class="col py-3">            
                    <%-- Instancia de Horario para almacenar los datos del horario a eliminar --%>
                    <jsp:useBean id="horario" class="pe.edu.entity.Horario" scope="request"></jsp:useBean>
                    <%
                        String mensaje = "";
                        String tipoMensaje = "";
                        boolean horarioEncontrado = false;

                        try {
                            // Obtener el ID del horario desde la URL
                            String id = request.getParameter("id");
                            
                            // Si el ID no es nulo, cargar los datos del horario de la base de datos
                            if (id != null && !id.isEmpty()) {
                                Horario horarioExistente = horarioDao.leer(id);
                                if (horarioExistente != null) {
                                    // Establecer las propiedades del bean 'horario' con los datos existentes
                                    horario.setIdHorario(horarioExistente.getIdHorario());
                                    horario.setDiaSemana(horarioExistente.getDiaSemana());
                                    horario.setHoraInicio(horarioExistente.getHoraInicio());
                                    horario.setHoraFin(horarioExistente.getHoraFin());
                                    horario.setAula(horarioExistente.getAula());
                                    horarioEncontrado = true;
                                } else {
                                    mensaje = "No se encontró el horario con ID: " + id + ".";
                                    tipoMensaje = "danger";
                                }
                            } else {
                                mensaje = "ID de horario no proporcionado para confirmar eliminación.";
                                tipoMensaje = "warning";
                            }
                        } catch (Exception e) {
                            mensaje = "Error al cargar los datos del horario: " + e.getMessage();
                            tipoMensaje = "danger";
                            e.printStackTrace(); // Para depuración
                        }
                    %>
                    <center>
                        <div class="card card_login shadow">
                            <div class="card-header card_titulo bg-danger text-white">
                                <h2 class="mb-0">
                                    <i class="fas fa-exclamation-triangle me-2"></i>Confirmar Eliminación
                                </h2>
                            </div>
                            <div class="card-body">
                                <%-- Mostrar mensajes de error o información --%>
                                <% if (!mensaje.isEmpty()) { %>
                                    <div class="alert alert-<%= tipoMensaje %> alert-dismissible fade show" role="alert">
                                        <%= mensaje %>
                                        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                                    </div>
                                    <div class="d-grid gap-2">
                                        <a href="listado.jsp" class="btn btn-primary d-flex align-items-center justify-content-center mt-3">
                                            <i class="fas fa-arrow-alt-circle-left me-2"></i>Volver al Listado
                                        </a>
                                    </div>
                                <% } %>

                                <% if (horarioEncontrado) { %>
                                    <p class="text-danger lead mb-4">
                                        ¿Está seguro que desea eliminar el siguiente horario?
                                        Esta acción no se puede deshacer.
                                    </p>
                                    
                                    <div class="text-start mb-4">
                                        <div class="mb-2">
                                            <label class="form-label fw-bold"><i class="fas fa-fingerprint me-1"></i>ID Horario:</label>
                                            <p class="form-control-plaintext"><%= horario.getIdHorario() %></p>
                                        </div>
                                        <div class="mb-2">
                                            <label class="form-label fw-bold"><i class="fas fa-calendar-day me-1"></i>Día de la Semana:</label>
                                            <p class="form-control-plaintext"><%= horario.getDiaSemana() %></p>
                                        </div>
                                        <div class="mb-2">
                                            <label class="form-label fw-bold"><i class="fas fa-clock me-1"></i>Hora de Inicio:</label>
                                            <p class="form-control-plaintext"><%= horario.getHoraInicio() %></p>
                                        </div>
                                        <div class="mb-2">
                                            <label class="form-label fw-bold"><i class="fas fa-clock me-1"></i>Hora de Fin:</label>
                                            <p class="form-control-plaintext"><%= horario.getHoraFin() %></p>
                                        </div>
                                        <div class="mb-2">
                                            <label class="form-label fw-bold"><i class="fas fa-school me-1"></i>Aula:</label>
                                            <p class="form-control-plaintext"><%= horario.getAula() %></p>
                                        </div>
                                    </div>

                                    <%-- Formulario para confirmar la eliminación --%>
                                    <form action="../HorarioController" method="post">        
                                        <input type="hidden" name="accion" value="eliminar">
                                        <input type="hidden" name="idHorario" value="<jsp:getProperty name="horario" property="idHorario"></jsp:getProperty>">
                                                                                
                                        <div class="d-grid gap-2 d-md-flex justify-content-md-end mt-4">
                                            <a href="listado.jsp" class="btn btn-secondary d-flex align-items-center me-md-2">
                                                <i class="fas fa-times-circle me-2"></i>Cancelar
                                            </a>
                                            <button type="submit" class="btn btn-danger d-flex align-items-center">
                                                <i class="fas fa-trash-alt me-2"></i>Confirmar Eliminación
                                            </button>
                                        </div>
                                    </form>
                                <% } %>
                            </div>
                        </div>
                    </center>
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