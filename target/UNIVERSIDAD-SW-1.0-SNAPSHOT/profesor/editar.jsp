<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.LinkedList,pe.edu.entity.Profesor, pe.edu.dao.ProfesorDao" %>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <%@include file="../util/referencias.jsp" %>
        <title>Editar Profesor</title>        
    </head>
    
    <%-- Instancia de ProfesorDao para interactuar con la base de datos --%>
    <jsp:useBean id="profesorDao" class="pe.edu.dao.ProfesorDao" scope="session"></jsp:useBean>
    
    <body>            
        <div class="container-fluid">
            <div class="row flex-nowrap">
                <%@include file="../menu.jsp" %>
                        
                <div class="col py-3">            
                    <%-- Instancia de Profesor para almacenar los datos del profesor a editar --%>
                    <%-- Usamos scope="session" para que el bean persista en la sesión, si es el comportamiento deseado --%>
                    <jsp:useBean id="profesor" class="pe.edu.entity.Profesor" scope="session"></jsp:useBean>
                    <%
                        // Obtener el ID del profesor desde la URL
                        String id = request.getParameter("id");
                        
                        // Si el ID no es nulo, cargar los datos del profesor de la base de datos
                        if (id != null && !id.isEmpty()) {
                            Profesor profesorExistente = profesorDao.leer(id);
                            if (profesorExistente != null) {
                                profesor.setIdProfesor(profesorExistente.getIdProfesor());
                                profesor.setNombre(profesorExistente.getNombre());
                                profesor.setApellidoPaterno(profesorExistente.getApellidoPaterno());
                                profesor.setApellidoMaterno(profesorExistente.getApellidoMaterno());
                                profesor.setEmail(profesorExistente.getEmail());
                                profesor.setIdFacultad(profesorExistente.getIdFacultad());
                                profesor.setRol(profesorExistente.getRol());
                                // Importante: No cargar la contraseña directamente en el campo de texto si es un campo de tipo password
                                // O si decides cargarlo, que sea un campo de tipo texto para debug, pero nunca en producción.
                                // Para este ejemplo, la cargamos para emular el comportamiento de Alumno.
                                profesor.setPassword(profesorExistente.getPassword());
                            }
                        }
                    %>
                    <center>
                        <div class="card card_login shadow">
                            <div class="card-header card_titulo bg-warning text-white">
                                <h2 class="mb-0">
                                    <i class="fas fa-edit me-2"></i>Editar Profesor
                                </h2>
                            </div>
                            <div class="card-body">
                                <%-- El action del formulario apunta a ProfesorController --%>
                                <form action="../ProfesorController" method="post">            
                                    <input type="hidden" name="accion" value="editar">
                                    
                                    <%-- Campo ID Profesor (solo lectura para visualización) --%>
                                    ID Profesor <br>
                                    <input type="text" name="id" class="form-control" readonly="true" 
                                           value="<jsp:getProperty name="profesor" property="idProfesor"/>">

                                    <%-- Campo Nombre --%>
                                    Nombre <br>
                                    <input type="text" name="nombre" class="form-control" required="true"
                                           value="<jsp:getProperty name="profesor" property="nombre"/>"><br>

                                    <%-- Campo Apellido Paterno --%>
                                    Apellido Paterno <br>
                                    <input type="text" name="apellidoPaterno" class="form-control" required="true"
                                           value="<jsp:getProperty name="profesor" property="apellidoPaterno"/>"><br>

                                    <%-- Campo Apellido Materno --%>
                                    Apellido Materno <br>
                                    <input type="text" name="apellidoMaterno" class="form-control"
                                           value="<jsp:getProperty name="profesor" property="apellidoMaterno"/>"><br>

                                    <%-- Campo Email --%>
                                    Email <br>
                                    <input type="email" name="email" class="form-control" required="true"
                                           value="<jsp:getProperty name="profesor" property="email"/>"><br>

                                    <%-- Campo ID Facultad --%>
                                    ID Facultad <br>
                                    <input type="text" name="idFacultad" class="form-control" required="true"
                                           value="<jsp:getProperty name="profesor" property="idFacultad"/>"><br>

                                    <%-- Campo Rol --%>
                                    Rol <br>
                                    <select name="rol" class="form-select" required="true">
                                        <option value="profesor" <%= profesor.getRol() != null && profesor.getRol().equals("profesor") ? "selected" : "" %>>profesor</option>
                                        <option value="jefe_departamento" <%= profesor.getRol() != null && profesor.getRol().equals("jefe_departamento") ? "selected" : "" %>>jefe_departamento</option>
                                        <option value="admin" <%= profesor.getRol() != null && profesor.getRol().equals("admin") ? "selected" : "" %>>admin</option>
                                    </select><br>

                                    <%-- Campo Password --%>
                                    Password <br>
                                    <input type="text" name="password" class="form-control"
                                           value="<jsp:getProperty name="profesor" property="password"/>"><br>
                                                                                    
                                    <div class="d-grid gap-2 d-md-flex justify-content-md-end mt-4">
                                        <a href="listado.jsp" class="btn btn-danger d-flex align-items-center me-md-2">
                                            <i class="fas fa-times-circle me-2"></i>Cancelar
                                        </a>
                                        <button type="submit" class="btn btn-warning d-flex align-items-center">
                                            <i class="fas fa-save me-2"></i>Actualizar Profesor
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

<%-- Scripts --%>
<script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/js/all.min.js"></script>
<script type="text/javascript">
    // Asegúrate de que #myTable exista en esta página si necesitas DataTables
    // let table = new DataTable('#myTable'); 
</script>