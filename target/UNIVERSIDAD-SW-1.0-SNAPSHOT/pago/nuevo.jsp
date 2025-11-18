<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.time.LocalDate, java.time.format.DateTimeFormatter" %>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <%@include file="../util/referencias.jsp" %>
        <title>Nuevo Pago</title>        
    </head>
    <body>            
        <div class="container-fluid">
            <div class="row flex-nowrap">
                <%@include file="../menu.jsp" %>
                    
                <div class="col py-3">            
                    <center>
                        <div class="card card_login shadow">
                            <div class="card-header card_titulo bg-success text-white">
                                <h2 class="mb-0">
                                    <i class="fas fa-plus-circle me-2"></i>Registrar Nuevo Pago
                                </h2>
                            </div>
                            <div class="card-body">
                                <%-- El action del formulario apunta a PagoController --%>
                                <form action="../PagoController" method="post">        
                                    <input type="hidden" name="accion" value="nuevo">
                                    
                                    <%-- Campo ID Alumno --%>
                                    <div class="mb-3 text-start">
                                        <label for="idAlumno" class="form-label"><i class="fas fa-user-graduate me-1"></i>ID Alumno:</label>
                                        <input type="number" id="idAlumno" name="idAlumno" class="form-control" required="true" placeholder="Ej: 1">
                                    </div>

                                    <%-- Campo Fecha de Pago --%>
                                    <div class="mb-3 text-start">
                                        <label for="fechaPago" class="form-label"><i class="fas fa-calendar-alt me-1"></i>Fecha de Pago:</label>
                                        <% 
                                            // Obtener la fecha actual en formato YYYY-MM-DD
                                            LocalDate now = LocalDate.now();
                                            DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd");
                                            String formattedDate = now.format(formatter);
                                        %>
                                        <input type="date" id="fechaPago" name="fechaPago" class="form-control" required="true" 
                                               value="<%= formattedDate %>">
                                    </div>

                                    <%-- Campo Concepto --%>
                                    <div class="mb-3 text-start">
                                        <label for="concepto" class="form-label"><i class="fas fa-file-invoice-dollar me-1"></i>Concepto:</label>
                                        <input type="text" id="concepto" name="concepto" class="form-control" required="true" placeholder="Ej: Matrícula 2024-II">
                                    </div>

                                    <%-- Campo Monto --%>
                                    <div class="mb-3 text-start">
                                        <label for="monto" class="form-label"><i class="fas fa-dollar-sign me-1"></i>Monto:</label>
                                        <input type="number" step="0.01" id="monto" name="monto" class="form-control" required="true" placeholder="Ej: 350.00">
                                    </div>
                                    
                                    <%-- Campo Método de Pago --%>
                                    <div class="mb-3 text-start">
                                        <label for="metodoPago" class="form-label"><i class="fas fa-wallet me-1"></i>Método de Pago:</label>
                                        <select id="metodoPago" name="metodoPago" class="form-select" required="true">
                                            <option value="">Seleccione un método</option>
                                            <option value="Transferencia bancaria">Transferencia bancaria</option>
                                            <option value="Tarjeta de crédito">Tarjeta de crédito</option>
                                            <option value="Tarjeta de débito">Tarjeta de débito</option>
                                            <option value="Efectivo">Efectivo</option>
                                            <option value="Cheque">Cheque</option>
                                        </select>
                                    </div>

                                    <%-- Campo Referencia --%>
                                    <div class="mb-3 text-start">
                                        <label for="referencia" class="form-label"><i class="fas fa-receipt me-1"></i>Referencia:</label>
                                        <input type="text" id="referencia" name="referencia" class="form-control" required="true" placeholder="Ej: TRN-12345">
                                    </div>
                                                                            
                                    <div class="d-grid gap-2 d-md-flex justify-content-md-end mt-4">
                                        <a href="listado.jsp" class="btn btn-danger d-flex align-items-center me-md-2">
                                            <i class="fas fa-times-circle me-2"></i>Cancelar
                                        </a>
                                        <button type="submit" class="btn btn-success d-flex align-items-center">
                                            <i class="fas fa-save me-2"></i>Guardar Pago
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
