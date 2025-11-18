<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="pe.edu.entity.Pago, pe.edu.dao.PagoDao" %>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <%@include file="../util/referencias.jsp" %>
        <title>Editar Pago</title>        
    </head>
    
    <%-- Instancia de PagoDao para interactuar con la base de datos --%>
    <jsp:useBean id="pagoDao" class="pe.edu.dao.PagoDao" scope="session"></jsp:useBean>
    
    <body>            
        <div class="container-fluid">
            <div class="row flex-nowrap">
                <%@include file="../menu.jsp" %>
                    
                <div class="col py-3">            
                    <%-- Instancia de Pago para almacenar los datos del pago a editar --%>
                    <jsp:useBean id="pago" class="pe.edu.entity.Pago" scope="request"></jsp:useBean>
                    <%
                        String id = request.getParameter("id");
                        if (id != null && !id.isEmpty()) {
                            Pago pagoExistente = pagoDao.leer(id); // Pasar el ID como String
                            if (pagoExistente != null) {
                                // Establecer las propiedades del bean 'pago' con los datos existentes
                                pago.setIdPago(pagoExistente.getIdPago());
                                pago.setIdAlumno(pagoExistente.getIdAlumno());
                                pago.setFechaPago(pagoExistente.getFechaPago());
                                pago.setConcepto(pagoExistente.getConcepto());
                                pago.setMonto(pagoExistente.getMonto());
                                pago.setMetodoPago(pagoExistente.getMetodoPago());
                                pago.setReferencia(pagoExistente.getReferencia());
                            } else {
                                // Redirigir o mostrar mensaje de error si el pago no se encuentra
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
                                    <i class="fas fa-edit me-2"></i>Editar Pago
                                </h2>
                            </div>
                            <div class="card-body">
                                <%-- El action del formulario apunta a PagoController --%>
                                <form action="../PagoController" method="post">        
                                    <input type="hidden" name="accion" value="editar">
                                    
                                    <%-- Campo ID Pago (oculto para enviar el ID al controlador) --%>
                                    <input type="hidden" name="idPago" 
                                           value="<jsp:getProperty name="pago" property="idPago"></jsp:getProperty>">
                                                                            
                                    <%-- Campo ID Pago (solo lectura para visualización) --%>
                                    <div class="mb-3 text-start">
                                        <label for="displayIdPago" class="form-label"><i class="fas fa-fingerprint me-1"></i>ID Pago:</label>
                                        <input type="text" id="displayIdPago" class="form-control" readonly="true" 
                                               value="<jsp:getProperty name="pago" property="idPago"></jsp:getProperty>">
                                    </div>

                                    <%-- Campo ID Alumno --%>
                                    <div class="mb-3 text-start">
                                        <label for="idAlumno" class="form-label"><i class="fas fa-user-graduate me-1"></i>ID Alumno:</label>
                                        <input type="number" id="idAlumno" name="idAlumno" class="form-control" required="true" 
                                               value="<jsp:getProperty name="pago" property="idAlumno"></jsp:getProperty>">
                                    </div>

                                    <%-- Campo Fecha de Pago --%>
                                    <div class="mb-3 text-start">
                                        <label for="fechaPago" class="form-label"><i class="fas fa-calendar-alt me-1"></i>Fecha de Pago:</label>
                                        <input type="date" id="fechaPago" name="fechaPago" class="form-control" required="true"
                                               value="<jsp:getProperty name="pago" property="fechaPago"></jsp:getProperty>">
                                    </div>

                                    <%-- Campo Concepto --%>
                                    <div class="mb-3 text-start">
                                        <label for="concepto" class="form-label"><i class="fas fa-file-invoice-dollar me-1"></i>Concepto:</label>
                                        <input type="text" id="concepto" name="concepto" class="form-control" required="true" 
                                               value="<jsp:getProperty name="pago" property="concepto"></jsp:getProperty>">
                                    </div>

                                    <%-- Campo Monto --%>
                                    <div class="mb-3 text-start">
                                        <label for="monto" class="form-label"><i class="fas fa-dollar-sign me-1"></i>Monto:</label>
                                        <input type="number" step="0.01" id="monto" name="monto" class="form-control" required="true" 
                                               value="<jsp:getProperty name="pago" property="monto"></jsp:getProperty>">
                                    </div>
                                    
                                    <%-- Campo Método de Pago --%>
                                    <div class="mb-3 text-start">
                                        <label for="metodoPago" class="form-label"><i class="fas fa-wallet me-1"></i>Método de Pago:</label>
                                        <select id="metodoPago" name="metodoPago" class="form-select" required="true">
                                            <option value="Transferencia bancaria" <%= pago.getMetodoPago().equals("Transferencia bancaria") ? "selected" : "" %>>Transferencia bancaria</option>
                                            <option value="Tarjeta de crédito" <%= pago.getMetodoPago().equals("Tarjeta de crédito") ? "selected" : "" %>>Tarjeta de crédito</option>
                                            <option value="Tarjeta de débito" <%= pago.getMetodoPago().equals("Tarjeta de débito") ? "selected" : "" %>>Tarjeta de débito</option>
                                            <option value="Efectivo" <%= pago.getMetodoPago().equals("Efectivo") ? "selected" : "" %>>Efectivo</option>
                                            <option value="Cheque" <%= pago.getMetodoPago().equals("Cheque") ? "selected" : "" %>>Cheque</option>
                                        </select>
                                    </div>

                                    <%-- Campo Referencia --%>
                                    <div class="mb-3 text-start">
                                        <label for="referencia" class="form-label"><i class="fas fa-receipt me-1"></i>Referencia:</label>
                                        <input type="text" id="referencia" name="referencia" class="form-control" required="true" 
                                               value="<jsp:getProperty name="pago" property="referencia"></jsp:getProperty>">
                                    </div>
                                                                            
                                    <div class="d-grid gap-2 d-md-flex justify-content-md-end mt-4">
                                        <a href="listado.jsp" class="btn btn-danger d-flex align-items-center me-md-2">
                                            <i class="fas fa-times-circle me-2"></i>Cancelar
                                        </a>
                                        <button type="submit" class="btn btn-warning d-flex align-items-center">
                                            <i class="fas fa-save me-2"></i>Actualizar Pago
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
<script src="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/js/all.min.js"></script>7<script type="text/javascript">
    let table = new DataTable('#myTable');
</script>   