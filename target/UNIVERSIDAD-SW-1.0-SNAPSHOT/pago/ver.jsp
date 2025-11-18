<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="pe.edu.entity.Pago, pe.edu.dao.PagoDao" %>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <%@include file="../util/referencias.jsp" %>
        <title>Ver Pago</title>        
    </head>
    
    <%-- Instancia de PagoDao para interactuar con la base de datos --%>
    <jsp:useBean id="pagoDao" class="pe.edu.dao.PagoDao" scope="session"></jsp:useBean>
    
    <body>            
        <div class="container-fluid">
            <div class="row flex-nowrap">
                <%@include file="../menu.jsp" %>
                <div class="col py-3">    
                    <%-- Instancia de Pago para almacenar los datos del pago a ver --%>
                    <jsp:useBean id="pago" class="pe.edu.entity.Pago" scope="request"></jsp:useBean>
                    <%
                        String mensaje = "";
                        String tipoMensaje = "";

                        try {
                            // Obtener el ID del pago desde la URL
                            String id = request.getParameter("id");
                            
                            // Si el ID no es nulo, cargar los datos del pago de la base de datos
                            if (id != null && !id.isEmpty()) {
                                Pago pagoExistente = pagoDao.leer(id);
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
                                    mensaje = "No se encontró el pago con ID: " + id + ".";
                                    tipoMensaje = "danger";
                                }
                            } else {
                                mensaje = "ID de pago no proporcionado para ver detalles.";
                                tipoMensaje = "warning";
                            }
                        } catch (Exception e) {
                            mensaje = "Error al cargar los datos del pago: " + e.getMessage();
                            tipoMensaje = "danger";
                            e.printStackTrace(); // Para depuración
                        }
                    %>
                    
                    <div class="container">
                        <div class="row justify-content-center">
                            <div class="col-md-8 col-lg-6">
                                <%-- Mostrar mensajes de error o información --%>
                                <% if (!mensaje.isEmpty()) { %>
                                    <div class="alert alert-<%= tipoMensaje %> alert-dismissible fade show" role="alert">
                                        <%= mensaje %>
                                        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                                    </div>
                                <% } %>

                                <% if (pago.getIdPago() != "") { // Si el ID es 0, asumimos que no se encontró %>
                                    <div class="card shadow">
                                        <div class="card-header bg-info text-white">
                                            <h4 class="mb-0">
                                                <i class="fas fa-eye me-2"></i>Detalles del Pago
                                            </h4>
                                        </div>
                                        <div class="card-body">
                                            <%-- En el caso de "ver", no hay formulario POST. Se muestra solo información. --%>
                                            <div class="mb-3">
                                                <label class="form-label fw-bold"><i class="fas fa-fingerprint me-1"></i>ID Pago:</label>
                                                <p class="form-control-plaintext"><%= pago.getIdPago() %></p>
                                            </div>
                                            
                                            <div class="mb-3">
                                                <label class="form-label fw-bold"><i class="fas fa-user-graduate me-1"></i>ID Alumno:</label>
                                                <p class="form-control-plaintext"><%= pago.getIdAlumno() %></p>
                                            </div>
                                            
                                            <div class="mb-3">
                                                <label class="form-label fw-bold"><i class="fas fa-calendar-alt me-1"></i>Fecha de Pago:</label>
                                                <p class="form-control-plaintext"><%= pago.getFechaPago() %></p>
                                            </div>

                                            <div class="mb-3">
                                                <label class="form-label fw-bold"><i class="fas fa-file-invoice-dollar me-1"></i>Concepto:</label>
                                                <p class="form-control-plaintext"><%= pago.getConcepto() %></p>
                                            </div>

                                            <div class="mb-3">
                                                <label class="form-label fw-bold"><i class="fas fa-dollar-sign me-1"></i>Monto:</label>
                                                <p class="form-control-plaintext"><%= pago.getMonto() %></p>
                                            </div>
                                            
                                            <div class="mb-3">
                                                <label class="form-label fw-bold"><i class="fas fa-wallet me-1"></i>Método de Pago:</label>
                                                <p class="form-control-plaintext"><%= pago.getMetodoPago() %></p>
                                            </div>

                                            <div class="mb-3">
                                                <label class="form-label fw-bold"><i class="fas fa-receipt me-1"></i>Referencia:</label>
                                                <p class="form-control-plaintext"><%= pago.getReferencia() %></p>
                                            </div>
                                            
                                            <div class="d-grid gap-2">
                                                <a href="listado.jsp" class="btn btn-primary d-flex align-items-center justify-content-center">
                                                    <i class="fas fa-arrow-alt-circle-left me-2"></i>Volver al Listado
                                                </a>
                                            </div>
                                        </div>
                                    </div>
                                <% } else { %>
                                    <div class="alert alert-info mt-3" role="alert">
                                        No hay datos de pago para mostrar. Por favor, asegúrese de que el ID sea válido.
                                    </div>
                                <% } %>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </body>
</html>

<%-- Scripts (no necesarios en esta página, ya incluidos en referencias.jsp) --%>
<script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/js/all.min.js"></script>