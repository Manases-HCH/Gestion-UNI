<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.LinkedList, pe.edu.entity.Profesor, pe.edu.dao.ProfesorDao" %>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <%@include file="../util/referencias.jsp" %>
        <title>Ver Profesor</title>        
    </head>
    
    <%-- Instancia de ProfesorDao para interactuar con la base de datos --%>
    <jsp:useBean id="profesorDao" class="pe.edu.dao.ProfesorDao" scope="session"></jsp:useBean>
    
    <body>            
        <div class="container-fluid">
            <div class="row flex-nowrap">
                <%@include file="../menu.jsp" %>
                <div class="col py-3">    
                    <%-- Instancia de Profesor para almacenar los datos del profesor a ver --%>
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
                            }
                        }
                    %>
                    <center>
                        <div class="card card_login">
                            <div class="card-header card_titulo">
                                <h2>Ver Profesor</h2>
                            </div>
                            <br>
                            <div class="card-body">
                                <%-- El action del formulario apunta a ProfesorController, aunque para "ver" no se envía nada --%>
                                <form action="../ProfesorController" method="post">
                                    <input type="hidden" name="accion" value="ver">
                                    
                                    <%-- Campo ID Profesor (solo lectura) --%>
                                    ID Profesor <br>
                                    <input type="text" name="idProfesor" class="form-control" readonly="true"
                                           value="<jsp:getProperty name="profesor" property="idProfesor"></jsp:getProperty>"><br>
                                    
                                    <%-- Campo Nombre (solo lectura) --%>
                                    Nombre <br>
                                    <input type="text" name="nombre" class="form-control" readonly="true"
                                           value="<jsp:getProperty name="profesor" property="nombre"></jsp:getProperty>"><br>
                                    
                                    <%-- Campo Apellido Paterno (solo lectura) --%>
                                    Apellido Paterno <br>
                                    <input type="text" name="apellidoPaterno" class="form-control" readonly="true"
                                           value="<jsp:getProperty name="profesor" property="apellidoPaterno"></jsp:getProperty>"><br>
                                    
                                    <%-- Campo Apellido Materno (solo lectura) --%>
                                    Apellido Materno <br>
                                    <input type="text" name="apellidoMaterno" class="form-control" readonly="true"
                                           value="<jsp:getProperty name="profesor" property="apellidoMaterno"></jsp:getProperty>"><br>
                                    
                                    <%-- Campo Email (solo lectura) --%>
                                    Email <br>
                                    <input type="text" name="email" class="form-control" readonly="true"
                                           value="<jsp:getProperty name="profesor" property="email"></jsp:getProperty>"><br>
                                    
                                    <%-- Campo ID Facultad (solo lectura) --%>
                                    ID Facultad <br>
                                    <input type="text" name="idFacultad" class="form-control" readonly="true"
                                           value="<jsp:getProperty name="profesor" property="idFacultad"></jsp:getProperty>"><br>
                                    
                                    <%-- Campo Rol (solo lectura) --%>
                                    Rol <br>
                                    <input type="text" name="rol" class="form-control" readonly="true"
                                           value="<jsp:getProperty name="profesor" property="rol"></jsp:getProperty>"><br>

                                    <a href="listado.jsp" class="btn btn-danger">Volver al Listado</a>
                                    <%-- El botón "Aceptar" no tiene una función aquí, ya que es solo para ver. 
                                         Se podría quitar o cambiar a un botón de "Cerrar" --%>
                                    <%-- <input type="submit" class="btn btn-success" value="Aceptar"> --%>
                                </form>
                            </div>
                        </div>
                    </center>
                </div>
            </div>
        </div>
    </body>
</html>

<script src="https://code.jquery.com/jquery-3.7.1.js"></script>
<script src="https://cdn.datatables.net/2.3.1/js/dataTables.js"></script>

<script type="text/javascript">
    let table = new DataTable('#myTable');
</script>