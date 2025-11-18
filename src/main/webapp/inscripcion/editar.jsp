<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="pe.edu.entity.Inscripcion, pe.edu.dao.InscripcionDao" %>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <%@include file="../util/referencias.jsp" %>
        <title>Editar Inscripción</title>        
    </head>
    
    <%-- Instancia de InscripcionDao para interactuar con la base de datos --%>
    <jsp:useBean id="inscripcionDao" class="pe.edu.dao.InscripcionDao" scope="session"></jsp:useBean>
    
    <body>            
        <div class="container-fluid">
            <div class="row flex-nowrap">
                <%@include file="../menu.jsp" %>
                    
                <div class="col py-3">            
                    <%-- Instancia de Inscripcion para almacenar los datos de la inscripción a editar --%>
                    <jsp:useBean id="inscripcion" class="pe.edu.entity.Inscripcion" scope="request"></jsp:useBean>
                    <%
                        String id = request.getParameter("id");
                        if (id != null && !id.isEmpty()) {
                            Inscripcion inscripcionExistente = inscripcionDao.leer(id); // Pasar el ID como String
                            if (inscripcionExistente != null) {
                                // Establecer las propiedades del bean 'inscripcion' con los datos existentes
                                inscripcion.setIdInscripcion(inscripcionExistente.getIdInscripcion());
                                inscripcion.setIdAlumno(inscripcionExistente.getIdAlumno());
                                inscripcion.setIdClase(inscripcionExistente.getIdClase());
                                inscripcion.setFechaInscripcion(inscripcionExistente.getFechaInscripcion());
                                inscripcion.setEstado(inscripcionExistente.getEstado());
                            } else {
                                // Redirigir o mostrar mensaje de error si la inscripción no se encuentra
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
                                    <i class="fas fa-edit me-2"></i>Editar Inscripción
                                </h2>
                            </div>
                            <div class="card-body">
                                <%-- El action del formulario apunta a InscripcionController --%>
                                <form action="../InscripcionController" method="post">        
                                    <input type="hidden" name="accion" value="editar">
                                    
                                    <%-- Campo ID Inscripción (oculto para enviar el ID al controlador) --%>
                                    <input type="hidden" name="idInscripcion" 
                                           value="<jsp:getProperty name="inscripcion" property="idInscripcion"></jsp:getProperty>">
                                                                            
                                    <%-- Campo ID Inscripción (solo lectura para visualización) --%>
                                    <div class="mb-3 text-start">
                                        <label for="displayIdInscripcion" class="form-label"><i class="fas fa-fingerprint me-1"></i>ID Inscripción:</label>
                                        <input type="text" id="displayIdInscripcion" class="form-control" readonly="true" 
                                               value="<jsp:getProperty name="inscripcion" property="idInscripcion"></jsp:getProperty>">
                                    </div>

                                    <%-- Campo ID Alumno --%>
                                    <div class="mb-3 text-start">
                                        <label for="idAlumno" class="form-label"><i class="fas fa-user-graduate me-1"></i>ID Alumno:</label>
                                        <input type="number" id="idAlumno" name="idAlumno" class="form-control" required="true" 
                                               value="<jsp:getProperty name="inscripcion" property="idAlumno"></jsp:getProperty>">
                                    </div>

                                    <%-- Campo ID Clase --%>
                                    <div class="mb-3 text-start">
                                        <label for="idClase" class="form-label"><i class="fas fa-chalkboard me-1"></i>ID Clase:</label>
                                        <input type="number" id="idClase" name="idClase" class="form-control" required="true" 
                                               value="<jsp:getProperty name="inscripcion" property="idClase"></jsp:getProperty>">
                                    </div>

                                    <%-- Campo Fecha de Inscripción --%>
                                    <div class="mb-3 text-start">
                                        <label for="fechaInscripcion" class="form-label"><i class="fas fa-calendar-alt me-1"></i>Fecha de Inscripción:</label>
                                        <input type="text" id="fechaInscripcion" name="fechaInscripcion" class="form-control" required="true"
                                               value="<jsp:getProperty name="inscripcion" property="fechaInscripcion"></jsp:getProperty>"
                                               placeholder="YYYY-MM-DD HH:MM:SS">
                                        <small class="form-text text-muted">Formato: YYYY-MM-DD HH:MM:SS</small>
                                    </div>

                                    <%-- Campo Estado --%>
                                    <div class="mb-3 text-start">
                                        <label for="estado" class="form-label"><i class="fas fa-check-circle me-1"></i>Estado:</label>
                                        <select id="estado" name="estado" class="form-select" required="true">
                                            <option value="Activo" <%= inscripcion.getEstado().equals("Activo") ? "selected" : "" %>>Activo</option>
                                            <option value="Inactivo" <%= inscripcion.getEstado().equals("Inactivo") ? "selected" : "" %>>Inactivo</option>
                                            <option value="Pendiente" <%= inscripcion.getEstado().equals("Pendiente") ? "selected" : "" %>>Pendiente</option>
                                        </select>
                                    </div>
                                                                            
                                    <div class="d-grid gap-2 d-md-flex justify-content-md-end mt-4">
                                        <a href="listado.jsp" class="btn btn-danger d-flex align-items-center me-md-2">
                                            <i class="fas fa-times-circle me-2"></i>Cancelar
                                        </a>
                                        <button type="submit" class="btn btn-warning d-flex align-items-center">
                                            <i class="fas fa-save me-2"></i>Actualizar Inscripción
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