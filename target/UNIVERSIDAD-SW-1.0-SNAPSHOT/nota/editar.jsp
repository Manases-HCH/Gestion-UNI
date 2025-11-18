<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="pe.edu.entity.Nota, pe.edu.dao.NotaDao" %>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <%@include file="../util/referencias.jsp" %>
        <title>Editar Nota</title>        
    </head>
    
    <%-- Instancia de NotaDao para interactuar con la base de datos --%>
    <jsp:useBean id="notaDao" class="pe.edu.dao.NotaDao" scope="session"></jsp:useBean>
    
    <body>            
        <div class="container-fluid">
            <div class="row flex-nowrap">
                <%@include file="../menu.jsp" %>
                    
                <div class="col py-3">            
                    <%-- Instancia de Nota para almacenar los datos de la nota a editar --%>
                    <jsp:useBean id="nota" class="pe.edu.entity.Nota" scope="request"></jsp:useBean>
                    <%
                        String id = request.getParameter("id");
                        if (id != null && !id.isEmpty()) {
                            Nota notaExistente = notaDao.leer(id); // Pasar el ID como String
                            if (notaExistente != null) {
                                // Establecer las propiedades del bean 'nota' con los datos existentes
                                nota.setIdNota(notaExistente.getIdNota());
                                nota.setIdInscripcion(notaExistente.getIdInscripcion());
                                nota.setNota1(notaExistente.getNota1());
                                nota.setNota2(notaExistente.getNota2());
                                nota.setNotaFinal(notaExistente.getNotaFinal());
                                nota.setEstado(notaExistente.getEstado());
                            } else {
                                // Redirigir o mostrar mensaje de error si la nota no se encuentra
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
                                    <i class="fas fa-edit me-2"></i>Editar Nota
                                </h2>
                            </div>
                            <div class="card-body">
                                <%-- El action del formulario apunta a NotaController --%>
                                <form action="../NotaController" method="post">        
                                    <input type="hidden" name="accion" value="editar">
                                    
                                    <%-- Campo ID Nota (oculto para enviar el ID al controlador) --%>
                                    <input type="hidden" name="id" value="<jsp:getProperty name="nota" property="idNota"></jsp:getProperty>">
                                                                            
                                    <%-- Campo ID Nota (solo lectura para visualización) --%>
                                    <div class="mb-3 text-start">
                                        <label for="displayIdNota" class="form-label"><i class="fas fa-fingerprint me-1"></i>ID Nota:</label>
                                        <input type="text" id="displayIdNota" class="form-control" readonly="true" 
                                               value="<jsp:getProperty name="nota" property="idNota"></jsp:getProperty>">
                                    </div>

                                    <%-- Campo ID Inscripción --%>
                                    <div class="mb-3 text-start">
                                        <label for="idInscripcion" class="form-label"><i class="fas fa-id-badge me-1"></i>ID Inscripción:</label>
                                        <input type="number" id="idInscripcion" name="idInscripcion" class="form-control" required="true" 
                                               value="<jsp:getProperty name="nota" property="idInscripcion"></jsp:getProperty>">
                                    </div>

                                    <%-- Campo Nota 1 --%>
                                    <div class="mb-3 text-start">
                                        <label for="nota1" class="form-label"><i class="fas fa-calculator me-1"></i>Nota 1:</label>
                                        <input type="number" step="0.01" id="nota1" name="nota1" class="form-control" required="true" 
                                               value="<jsp:getProperty name="nota" property="nota1"></jsp:getProperty>">
                                    </div>

                                    <%-- Campo Nota 2 --%>
                                    <div class="mb-3 text-start">
                                        <label for="nota2" class="form-label"><i class="fas fa-calculator me-1"></i>Nota 2:</label>
                                        <input type="number" step="0.01" id="nota2" name="nota2" class="form-control" required="true" 
                                               value="<jsp:getProperty name="nota" property="nota2"></jsp:getProperty>">
                                    </div>

                                    <%-- Campo Nota Final --%>
                                    <div class="mb-3 text-start">
                                        <label for="notaFinal" class="form-label"><i class="fas fa-trophy me-1"></i>Nota Final:</label>
                                        <input type="number" step="0.01" id="notaFinal" name="notaFinal" class="form-control" required="true" 
                                               value="<jsp:getProperty name="nota" property="notaFinal"></jsp:getProperty>">
                                    </div>
                                    
                                    <%-- Campo Estado --%>
                                    <div class="mb-3 text-start">
                                        <label for="estado" class="form-label"><i class="fas fa-check-circle me-1"></i>Estado:</label>
                                        <select id="estado" name="estado" class="form-select" required="true">
                                            <option value="Aprobado" <%= nota.getEstado().equals("Aprobado") ? "selected" : "" %>>Aprobado</option>
                                            <option value="Desaprobado" <%= nota.getEstado().equals("Desaprobado") ? "selected" : "" %>>Desaprobado</option>
                                            <option value="Pendiente" <%= nota.getEstado().equals("Pendiente") ? "selected" : "" %>>Pendiente</option>
                                        </select>
                                    </div>
                                                                            
                                    <div class="d-grid gap-2 d-md-flex justify-content-md-end mt-4">
                                        <a href="listado.jsp" class="btn btn-danger d-flex align-items-center me-md-2">
                                            <i class="fas fa-times-circle me-2"></i>Cancelar
                                        </a>
                                        <button type="submit" class="btn btn-warning d-flex align-items-center">
                                            <i class="fas fa-save me-2"></i>Actualizar Nota
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