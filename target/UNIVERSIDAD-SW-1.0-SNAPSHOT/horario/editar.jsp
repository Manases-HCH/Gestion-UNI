<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="pe.edu.entity.Horario, pe.edu.dao.HorarioDao" %>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <%@include file="../util/referencias.jsp" %>
        <title>Editar Horario</title>        
    </head>
    
    <%-- Instancia de HorarioDao para interactuar con la base de datos --%>
    <jsp:useBean id="horarioDao" class="pe.edu.dao.HorarioDao" scope="session"></jsp:useBean>
    
    <body>            
        <div class="container-fluid">
            <div class="row flex-nowrap">
                <%@include file="../menu.jsp" %>
                    
                <div class="col py-3">            
                    <%-- Instancia de Horario para almacenar los datos del horario a editar --%>
                    <jsp:useBean id="horario" class="pe.edu.entity.Horario" scope="request"></jsp:useBean>
                    <%
                        String id = request.getParameter("id");
                        if (id != null && !id.isEmpty()) {
                            Horario horarioExistente = horarioDao.leer(id); // Pasar el ID como String
                            if (horarioExistente != null) {
                                // Establecer las propiedades del bean 'horario' con los datos existentes
                                horario.setIdHorario(horarioExistente.getIdHorario());
                                horario.setDiaSemana(horarioExistente.getDiaSemana());
                                horario.setHoraInicio(horarioExistente.getHoraInicio());
                                horario.setHoraFin(horarioExistente.getHoraFin());
                                horario.setAula(horarioExistente.getAula());
                            } else {
                                // Redirigir o mostrar mensaje de error si el horario no se encuentra
                                response.sendRedirect("listado.jsp?msg=notfound"); // Ejemplo de redirección
                                return; // Importante para detener la ejecución
                            }
                        } else {
                            // Redirigir o mostrar mensaje de error si no se proporciona ID
                            response.sendRedirect("listado.jsp?msg=noid"); // Ejemplo de redirección
                            return; // Importante para detener la ejecución
                        }
                    %>
                    <center>
                        <div class="card card_login shadow">
                            <div class="card-header card_titulo bg-warning text-white">
                                <h2 class="mb-0">
                                    <i class="fas fa-edit me-2"></i>Editar Horario
                                </h2>
                            </div>
                            <div class="card-body">
                                <%-- El action del formulario apunta a HorarioController --%>
                                <form action="../HorarioController" method="post">        
                                    <input type="hidden" name="accion" value="editar">
                                    
                                    <%-- Campo ID Horario (oculto para enviar el ID al controlador) --%>
                                    <input type="hidden" name="idHorario" 
                                           value="<jsp:getProperty name="horario" property="idHorario"></jsp:getProperty>">
                                                                            
                                    <%-- Campo ID Horario (solo lectura para visualización) --%>
                                    <div class="mb-3 text-start">
                                        <label for="displayIdHorario" class="form-label"><i class="fas fa-fingerprint me-1"></i>ID Horario:</label>
                                        <input type="text" id="displayIdHorario" class="form-control" readonly="true" 
                                               value="<jsp:getProperty name="horario" property="idHorario"></jsp:getProperty>">
                                    </div>

                                    <%-- Campo Día de la Semana --%>
                                    <div class="mb-3 text-start">
                                        <label for="diaSemana" class="form-label"><i class="fas fa-calendar-day me-1"></i>Día de la Semana:</label>
                                        <select id="diaSemana" name="diaSemana" class="form-select" required="true">
                                            <option value="">Seleccione un día</option>
                                            <option value="Lunes" <%= horario.getDiaSemana().equals("Lunes") ? "selected" : "" %>>Lunes</option>
                                            <option value="Martes" <%= horario.getDiaSemana().equals("Martes") ? "selected" : "" %>>Martes</option>
                                            <option value="Miércoles" <%= horario.getDiaSemana().equals("Miércoles") ? "selected" : "" %>>Miércoles</option>
                                            <option value="Jueves" <%= horario.getDiaSemana().equals("Jueves") ? "selected" : "" %>>Jueves</option>
                                            <option value="Viernes" <%= horario.getDiaSemana().equals("Viernes") ? "selected" : "" %>>Viernes</option>
                                            <option value="Sábado" <%= horario.getDiaSemana().equals("Sábado") ? "selected" : "" %>>Sábado</option>
                                            <option value="Domingo" <%= horario.getDiaSemana().equals("Domingo") ? "selected" : "" %>>Domingo</option>
                                        </select>
                                    </div>

                                    <%-- Campo Hora Inicio --%>
                                    <div class="mb-3 text-start">
                                        <label for="horaInicio" class="form-label"><i class="fas fa-clock me-1"></i>Hora de Inicio:</label>
                                        <input type="time" id="horaInicio" name="horaInicio" class="form-control" required="true"
                                               value="<jsp:getProperty name="horario" property="horaInicio"></jsp:getProperty>">
                                    </div>

                                    <%-- Campo Hora Fin --%>
                                    <div class="mb-3 text-start">
                                        <label for="horaFin" class="form-label"><i class="fas fa-clock me-1"></i>Hora de Fin:</label>
                                        <input type="time" id="horaFin" name="horaFin" class="form-control" required="true"
                                               value="<jsp:getProperty name="horario" property="horaFin"></jsp:getProperty>">
                                    </div>

                                    <%-- Campo Aula --%>
                                    <div class="mb-3 text-start">
                                        <label for="aula" class="form-label"><i class="fas fa-school me-1"></i>Aula:</label>
                                        <input type="text" id="aula" name="aula" class="form-control" required="true" 
                                               value="<jsp:getProperty name="horario" property="aula"></jsp:getProperty>"
                                               placeholder="Ej: A-101">
                                    </div>
                                                                            
                                    <div class="d-grid gap-2 d-md-flex justify-content-md-end mt-4">
                                        <a href="listado.jsp" class="btn btn-danger d-flex align-items-center me-md-2">
                                            <i class="fas fa-times-circle me-2"></i>Cancelar
                                        </a>
                                        <button type="submit" class="btn btn-warning d-flex align-items-center">
                                            <i class="fas fa-save me-2"></i>Actualizar Horario
                                        </button>
                                    </div>
                                </form>
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