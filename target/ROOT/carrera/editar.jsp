<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.LinkedList, pe.edu.entity.Carrera, pe.edu.dao.CarreraDao" %>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <%@include file="../util/referencias.jsp" %>

        <title>Editar Carrera</title>        

    </head>
    <%-- Instancia de CarreraDao para interactuar con la base de datos --%>
    <jsp:useBean id="carreraDao" class="pe.edu.dao.CarreraDao" scope="session"></jsp:useBean>
    <body>            
        <div class="container-fluid">
            <div class="row flex-nowrap">
                <%@include file="../menu.jsp" %>
                <div class="col py-3">    
                    <%-- Instancia de Carrera para almacenar los datos de la carrera a editar --%>
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
                            <div class="card-body">
                                <%-- El action del formulario apunta a CarreraController --%>
                                <form action="../CarreraController" method="post">
                                    <h3>EDITAR CARRERA</h3>
                                    <input type="hidden" name="accion" value="editar">
                                    
                                    <%-- Campo ID Carrera (solo lectura) --%>
                                    ID Carrera <br>
                                    <input type="text" name="idCarrera" class="form-control" readonly="true"
                                           value="<jsp:getProperty name="carrera" property="idCarrera"></jsp:getProperty>"><br>
                                    
                                    <%-- Campo Nombre de Carrera --%>
                                    Nombre de Carrera <br>
                                    <input type="text" name="nombreCarrera" class="form-control" required
                                           value="<jsp:getProperty name="carrera" property="nombreCarrera"></jsp:getProperty>"><br>

                                    <%-- Campo ID Facultad --%>
                                    ID Facultad <br>
                                    <input type="text" name="idFacultad" class="form-control" required
                                           value="<jsp:getProperty name="carrera" property="idFacultad"></jsp:getProperty>"><br>
                                    
                                    <a href="listado.jsp" class="btn btn-danger">Cancelar</a>
                                    <input type="submit" class="btn btn-success" value="Aceptar">
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