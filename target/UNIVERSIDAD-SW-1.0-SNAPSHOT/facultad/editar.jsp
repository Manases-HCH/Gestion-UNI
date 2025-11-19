<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="pe.edu.entity.Facultad, pe.edu.dao.FacultadDao" %>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <%@include file="../util/referencias.jsp" %>
        <title>Editar Facultad</title>        
    </head>
    
    <%-- Instancia de FacultadDao para interactuar con la base de datos --%>
    <jsp:useBean id="facultadDao" class="pe.edu.dao.FacultadDao" scope="session"></jsp:useBean>
    
    <body>            
        <div class="container-fluid">
            <div class="row flex-nowrap">
                <%@include file="../menu.jsp" %>
                    
                <div class="col py-3">            
                    <%-- Instancia de Facultad para almacenar los datos de la facultad a editar --%>
                    <jsp:useBean id="facultad" class="pe.edu.entity.Facultad" scope="request"></jsp:useBean>
                    <%
                        String id = request.getParameter("id");
                        if (id != null && !id.isEmpty()) {
                            Facultad facultadExistente = facultadDao.leer(id);
                            if (facultadExistente != null) {
                                // Establecer las propiedades del bean 'facultad' con los datos existentes
                                facultad.setIdFacultad(facultadExistente.getIdFacultad());
                                facultad.setNombreFacultad(facultadExistente.getNombreFacultad());
                            } else {
                                // Redirigir o mostrar mensaje de error si la facultad no se encuentra
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
                                    <i class="fas fa-edit me-2"></i>Editar Facultad
                                </h2>
                            </div>
                            <div class="card-body">
                                <%-- El action del formulario apunta a FacultadController --%>
                                <form action="../FacultadController" method="post">        
                                    <input type="hidden" name="accion" value="editar">
                                    
                                    <%-- Campo ID Facultad (oculto para enviar el ID al controlador) --%>
                                    <input type="hidden" name="idFacultad" 
                                           value="<jsp:getProperty name="facultad" property="idFacultad"></jsp:getProperty>">
                                                                            
                                    <%-- Campo ID Facultad (solo lectura para visualización) --%>
                                    <div class="mb-3 text-start">
                                        <label for="displayIdFacultad" class="form-label"><i class="fas fa-fingerprint me-1"></i>ID Facultad:</label>
                                        <input type="text" id="displayIdFacultad" class="form-control" readonly="true" 
                                               value="<jsp:getProperty name="facultad" property="idFacultad"></jsp:getProperty>">
                                    </div>

                                    <%-- Campo Nombre de la Facultad --%>
                                    <div class="mb-3 text-start">
                                        <label for="nombreFacultad" class="form-label"><i class="fas fa-tag me-1"></i>Nombre de la Facultad:</label>
                                        <input type="text" id="nombreFacultad" name="nombreFacultad" class="form-control" required="true" 
                                               value="<jsp:getProperty name="facultad" property="nombreFacultad"></jsp:getProperty>"
                                               placeholder="Ej: Facultad de Ingeniería">
                                    </div>
                                                                            
                                    <div class="d-grid gap-2 d-md-flex justify-content-md-end mt-4">
                                        <a href="listado.jsp" class="btn btn-danger d-flex align-items-center me-md-2">
                                            <i class="fas fa-times-circle me-2"></i>Cancelar
                                        </a>
                                        <button type="submit" class="btn btn-warning d-flex align-items-center">
                                            <i class="fas fa-save me-2"></i>Actualizar Facultad
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