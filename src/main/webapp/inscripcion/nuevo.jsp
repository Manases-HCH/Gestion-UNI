<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.time.LocalDateTime, java.time.format.DateTimeFormatter" %>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <%@include file="../util/referencias.jsp" %>
        <title>Nueva Inscripción</title>        
    </head>
    <body>            
        <div class="container-fluid">
            <div class="row flex-nowrap">
                <%@include file="../menu.jsp" %>
                    
                <div class="col py-3">            
                    <center>
                        <div class="card card_login shadow">
                            <div class="card-header card_titulo bg-success text-white">
                                <h2 class="mb-0">
                                    <i class="fas fa-plus-circle me-2"></i>Registrar Nueva Inscripción
                                </h2>
                            </div>
                            <div class="card-body">
                                <%-- El action del formulario apunta a InscripcionController --%>
                                <form action="../InscripcionController" method="post">        
                                    <input type="hidden" name="accion" value="nuevo">
                                    
                                    <%-- Campo ID Alumno --%>
                                    <div class="mb-3 text-start">
                                        <label for="idAlumno" class="form-label"><i class="fas fa-user-graduate me-1"></i>ID Alumno:</label>
                                        <input type="number" id="idAlumno" name="idAlumno" class="form-control" required="true" placeholder="Ej: 1">
                                    </div>

                                    <%-- Campo ID Clase --%>
                                    <div class="mb-3 text-start">
                                        <label for="idClase" class="form-label"><i class="fas fa-chalkboard me-1"></i>ID Clase:</label>
                                        <input type="number" id="idClase" name="idClase" class="form-control" required="true" placeholder="Ej: 101">
                                    </div>

                                    <%-- Campo Fecha de Inscripción (autogenerada o editable) --%>
                                    <div class="mb-3 text-start">
                                        <label for="fechaInscripcion" class="form-label"><i class="fas fa-calendar-alt me-1"></i>Fecha de Inscripción:</label>
                                        <% 
                                            // Obtener la fecha y hora actual en el formato de la base de datos 'YYYY-MM-DD HH:MM:SS'
                                            LocalDateTime now = LocalDateTime.now();
                                            DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
                                            String formattedDateTime = now.format(formatter);
                                        %>
                                        <input type="text" id="fechaInscripcion" name="fechaInscripcion" class="form-control" readonly="true" 
                                               value="<%= formattedDateTime %>">
                                        <small class="form-text text-muted">La fecha se genera automáticamente.</small>
                                    </div>

                                    <%-- Campo Estado --%>
                                    <div class="mb-3 text-start">
                                        <label for="estado" class="form-label"><i class="fas fa-check-circle me-1"></i>Estado:</label>
                                        <select id="estado" name="estado" class="form-select" required="true">
                                            <option value="Activo">Activo</option>
                                            <option value="Inactivo">Inactivo</option>
                                            <option value="Pendiente">Pendiente</option>
                                        </select>
                                    </div>
                                                                            
                                    <div class="d-grid gap-2 d-md-flex justify-content-md-end mt-4">
                                        <a href="listado.jsp" class="btn btn-danger d-flex align-items-center me-md-2">
                                            <i class="fas fa-times-circle me-2"></i>Cancelar
                                        </a>
                                        <button type="submit" class="btn btn-success d-flex align-items-center">
                                            <i class="fas fa-save me-2"></i>Guardar Inscripción
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