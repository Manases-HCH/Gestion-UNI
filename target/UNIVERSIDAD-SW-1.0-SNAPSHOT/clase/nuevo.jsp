<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.LinkedList, pe.edu.entity.Clase, pe.edu.dao.ClaseDao" %>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <%@include file="../util/referencias.jsp" %>

        <title>Nueva Clase</title>        

    </head>
    <body>            
        <div class="container-fluid">
            <div class="row flex-nowrap">
                
                <%@include file="../menu.jsp" %>
                    
                <div class="col py-3">            
                        
                    <center>
                        <div class="card card_login">
                            <div class="card-header card_titulo">
                                <h2>Nueva Clase</h2>
                            </div>
                            <br>
                            <div class="card-body">
                                <%-- El action del formulario apunta a ClaseController --%>
                                <form action="../ClaseController" method="post">        
                                    <input type="hidden" name="accion" value="nuevo">
                                                                                                    
                                    <%-- Campo ID Curso --%>
                                    ID Curso <br>
                                    <input type="text" name="idCurso" class="form-control" required="true" placeholder="Ej: 101"><br>

                                    <%-- Campo ID Profesor --%>
                                    ID Profesor <br>
                                    <input type="text" name="idProfesor" class="form-control" required="true" placeholder="Ej: 5"><br>

                                    <%-- Campo ID Horario --%>
                                    ID Horario <br>
                                    <input type="text" name="idHorario" class="form-control" required="true" placeholder="Ej: 2"><br>
                                    
                                    <%-- Campo Ciclo --%>
                                    Ciclo <br>
                                    <input type="text" name="ciclo" class="form-control" required="true" placeholder="Ej: 2024-II"><br>
                                                                        
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