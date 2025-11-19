<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <%@include file="../util/referencias.jsp" %>
        <title>Nueva Nota</title>        
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
                                    <i class="fas fa-plus-circle me-2"></i>Registrar Nueva Nota
                                </h2>
                            </div>
                            <div class="card-body">
                                <form action="../NotaController" method="post">      
                                    <input type="hidden" name="accion" value="nuevo">
                                                                                
                                    <%-- Campo ID Inscripción --%>
                                    <div class="mb-3 text-start">
                                        <label for="idInscripcion" class="form-label"><i class="fas fa-id-badge me-1"></i>ID Inscripción:</label>
                                        <input type="text" id="idInscripcion" name="idInscripcion" class="form-control" required="true" placeholder="Ej: INS001">
                                    </div>

                                    <%-- Campo Nota 1 --%>
                                    <div class="mb-3 text-start">
                                        <label for="nota1" class="form-label"><i class="fas fa-calculator me-1"></i>Nota 1:</label>
                                        <input type="number" step="0.01" id="nota1" name="nota1" class="form-control" required="true" placeholder="Ej: 15.50" min="0" max="20">
                                    </div>

                                    <%-- Campo Nota 2 --%>
                                    <div class="mb-3 text-start">
                                        <label for="nota2" class="form-label"><i class="fas fa-calculator me-1"></i>Nota 2:</label>
                                        <input type="number" step="0.01" id="nota2" name="nota2" class="form-control" required="true" placeholder="Ej: 17.00" min="0" max="20">
                                    </div>     
                                    
                                    <%-- Nota Final y Estado se calculan en el controlador y NO se muestran como campos de entrada --%>
                                                                                
                                    <div class="d-grid gap-2 d-md-flex justify-content-md-end mt-4">
                                        <a href="listado.jsp" class="btn btn-danger d-flex align-items-center me-md-2">
                                            <i class="fas fa-times-circle me-2"></i>Cancelar
                                        </a>
                                        <button type="submit" class="btn btn-success d-flex align-items-center">
                                            <i class="fas fa-save me-2"></i>Guardar Nota
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

<%-- Scripts (Pueden ser omitidos o manejados en referencias.jsp si ya se incluyen globalmente) --%>
<script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/js/all.min.js"></script>
<script type="text/javascript">
    // Si 'myTable' es para una tabla de listado, este script no es necesario en 'nuevo.jsp'
    // let table = new DataTable('#myTable'); 
</script>