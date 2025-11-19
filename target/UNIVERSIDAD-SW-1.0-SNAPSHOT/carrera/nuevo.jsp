<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.LinkedList, pe.edu.entity.Carrera, pe.edu.dao.CarreraDao" %>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <%@include file="../util/referencias.jsp" %>

        <title>Nueva Carrera</title>        

    </head>
    <body>            
        <div class="container-fluid">
            <div class="row flex-nowrap">
                
                <%@include file="../menu.jsp" %>
                    
                <div class="col py-3">            
                        
                    <center>
                        <div class="card card_login">
                            <div class="card-header card_titulo">
                                <h2>Nueva Carrera</h2>
                            </div>
                            <br>
                            <div class="card-body">
                                <%-- El action del formulario apunta a CarreraController --%>
                                <form action="../CarreraController" method="post">        
                                    <input type="hidden" name="accion" value="nuevo">
                                                                                                        
                                    <%-- Campo Nombre Carrera --%>
                                    Nombre de la Carrera <br>
                                    <input type="text" name="nombreCarrera" class="form-control" required="true" placeholder="Ej: Ingeniería de Sistemas"><br>

                                    <%-- Campo ID Facultad --%>
                                    ID Facultad <br>
                                    <select name="idFacultad" class="form-control" required="true">
                                        <option value="">Seleccione una facultad</option>
                                        <option value="1">1 - Facultad de Ingeniería</option>
                                        <option value="2">2 - Facultad de Medicina</option>
                                        <option value="3">3 - Facultad de Ciencias Económicas</option>
                                        <option value="4">4 - Facultad de Educación</option>
                                    </select><br>
                                                                        
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