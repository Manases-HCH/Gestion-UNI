<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.LinkedList, pe.edu.entity.Pago, pe.edu.dao.PagoDao" %>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <%@include file="../util/referencias.jsp" %>
        <title>Listado de Pagos</title>        
    </head>
    
    <%-- Instancia de PagoDao para interactuar con la base de datos --%>
    <jsp:useBean id="pagoDao" class="pe.edu.dao.PagoDao" scope="session"></jsp:useBean>
    
    <body>            
        <div class="container-fluid">
            <div class="row flex-nowrap">
                <%@include file="../menu.jsp" %>
                    
                <div class="col py-3">            
                    <center>
                        <div class="card card_tabla shadow-sm">
                            <div class="card-header card_titulo bg-primary text-white">
                                <h2 class="mb-0">
                                    <i class="fas fa-money-bill-wave me-2"></i>Gestión de Pagos
                                </h2>
                            </div>
                            <div class="card-body">
                                <div class="row mb-3">
                                    <div class="col-sm-auto">
                                        <%-- Enlace para crear un nuevo pago --%>
                                        <a href="../PagoController?pagina=nuevo" class="btn btn-success d-flex align-items-center">
                                            <i class="fas fa-plus-circle me-2"></i>Nuevo Pago
                                        </a>
                                    </div>
                                    <div class="col"></div> <%-- Columna para espacio --%>
                                </div>
                                <br>
                                <div class="table-responsive">
                                    <table id="myTable" class="display table table-light table-striped table-hover card_contenido align-middle">
                                        <thead>
                                            <tr>
                                                <th>Nombre Alumno</th>
                                                <th>Apellido Alumno</th>
                                                <th>Fecha de Pago</th>
                                                <th>Concepto</th>
                                                <th>Monto</th>
                                                <th>Método de Pago</th>
                                                <th>Referencia</th>
                                                <th class="text-center">Acciones</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <%
                                                LinkedList<Pago> listaPagos = pagoDao.listar();
                                                if (listaPagos == null) {
                                                    listaPagos = new LinkedList<Pago>();
                                                }
                                                for (Pago p : listaPagos) {
                                            %>            
                                            <tr>
                                                <td><%= p.getNombreAlumno() %></td>
                                                <td><%= p.getApellidoAlumno() %></td>
                                                <td><%= p.getFechaPago() %></td>
                                                <td><%= p.getConcepto() %></td>
                                                <td><%= p.getMonto() %></td> <%-- Formato de monto --%>
                                                <td><%= p.getMetodoPago() %></td>
                                                <td><%= p.getReferencia() %></td>
                                                <td class="text-center">
                                                    <%-- Enlaces para Ver, Editar y Eliminar --%>
                                                    <a href="../PagoController?pagina=ver&id=<%= p.getIdPago() %>" 
                                                       class="btn btn-info btn-sm me-1" title="Ver detalles">
                                                        <i class="fas fa-eye"></i>
                                                    </a>
                                                    <a href="../PagoController?pagina=editar&id=<%= p.getIdPago() %>" 
                                                       class="btn btn-warning btn-sm me-1" title="Editar">
                                                        <i class="fas fa-edit"></i>
                                                    </a>
                                                    <a href="../PagoController?pagina=eliminar&id=<%= p.getIdPago() %>" 
                                                       class="btn btn-danger btn-sm" title="Eliminar"
                                                       onclick="return confirm('¿Está seguro que desea eliminar este pago? Esta acción no se puede deshacer.')">
                                                        <i class="fas fa-trash-alt"></i>
                                                    </a>
                                                </td>
                                            </tr>
                                            <%
                                                }
                                            %>            
                                        </tbody>
                                    </table> 
                                </div>
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
<script src="https://cdn.datatables.net/2.3.1/js/dataTables.bootstrap5.js"></script> <%-- Para estilos Bootstrap en DataTables --%>
<script src="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/js/all.min.js"></script> <%-- Font Awesome --%>

<script type="text/javascript">
    let table = new DataTable('#myTable');
</script>   