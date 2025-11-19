<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.LinkedList, pe.edu.entity.Carrera, pe.edu.dao.CarreraDao" %>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <%@include file="../util/referencias.jsp" %>

        <title>Eliminar Carrera</title>        

    </head>
    <%-- Instancia de CarreraDao para interactuar con la base de datos --%>
    <jsp:useBean id="carreraDao" class="pe.edu.dao.CarreraDao" scope="session"></jsp:useBean>
    <body>            
        <div class="container-fluid">
            <div class="row flex-nowrap">
                <%@include file="../menu.jsp" %>
                <div class="col py-3">    
                    <%-- Instancia de Carrera para almacenar los datos de la carrera a eliminar --%>
                    <jsp:useBean id="carrera" class="pe.edu.entity.Carrera" scope="session"></jsp:useBean>
                    <%
                        // Obtener el ID de la carrera desde la URL
                        String id = request.getParameter("id");
                        
                        // Si el ID no es nulo, cargar los datos de la carrera de la base de datos
                        if (id != null && !id.isEmpty()) {
                            Carrera carreraExistente = carreraDao.leer(id);
                            if (carreraExistente != null) {
                                carrera.setIdCarrera(carreraExistente.getIdCarrera());
                                carrera.setNombreCarrera(carreraExistente.getNombreCarrera());
                                carrera.setIdFacultad(carreraExistente.getIdFacultad());
                            }
                        }
                    %>
                    <center>
                        <div class="card card_login">
                            <div class="card-header card_titulo">
                                <h2>Eliminar Carrera</h2>
                            </div>
                            <br>
                            <div class="card-body">
                                <%-- El action del formulario apunta a CarreraController --%>
                                <form action="../CarreraController" method="post">
                                    <input type="hidden" name="accion" value="eliminar">
                                    
                                    <%-- Campo ID Carrera (solo lectura) --%>
                                    ID Carrera <br>
                                    <input type="text" name="idCarrera" class="form-control" readonly="true"
                                            value="<jsp:getProperty name="carrera" property="idCarrera"></jsp:getProperty>"><br>
                                    
                                    <%-- Campo Nombre de Carrera (solo lectura) --%>
                                    Nombre de Carrera <br>
                                    <input type="text" name="nombreCarrera" class="form-control" readonly="true"
                                            value="<jsp:getProperty name="carrera" property="nombreCarrera"></jsp:getProperty>"><br>

                                    <%-- Campo ID Facultad (solo lectura) --%>
                                    ID Facultad <br>
                                    <input type="text" name="idFacultad" class="form-control" readonly="true"
                                            value="<jsp:getProperty name="carrera" property="idFacultad"></jsp:getProperty>"><br>
                                    
                                    <div class="alert alert-warning" role="alert">
                                        <strong>¡Atención!</strong> Esta acción eliminará permanentemente la carrera de la base de datos. 
                                        Esta operación no se puede deshacer.
                                    </div>
                                    
                                    <a href="listado.jsp" class="btn btn-secondary">Cancelar</a>
                                    <input type="submit" class="btn btn-danger" value="Eliminar" 
                                            onclick="return confirm('¿Está seguro que desea eliminar esta carrera?')">
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