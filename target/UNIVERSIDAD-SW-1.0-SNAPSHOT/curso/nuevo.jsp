<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.LinkedList, pe.edu.entity.Curso, pe.edu.entity.Carrera, pe.edu.dao.CarreraDao" %>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <%@include file="../util/referencias.jsp" %>
        <title>Nuevo Curso</title>        
    </head>
    
    <%-- Instancia de CarreraDao para obtener la lista de carreras --%>
    <jsp:useBean id="carreraDao" class="pe.edu.dao.CarreraDao" scope="session"></jsp:useBean>
    
    <body>            
        <div class="container-fluid">
            <div class="row flex-nowrap">
                <%@include file="../menu.jsp" %>
                        
                <div class="col py-3">            
                    <center>
                        <div class="card card_login shadow">
                            <div class="card-header card_titulo bg-success text-white">
                                <h2 class="mb-0">
                                    <i class="fas fa-plus-circle me-2"></i>Registrar Nuevo Curso
                                </h2>
                            </div>
                            <div class="card-body">
                                <%-- MODIFICACIÓN CLAVE AQUÍ: AÑADIR enctype="multipart/form-data" --%>
                                <form action="../CursoController" method="post" enctype="multipart/form-data">        
                                    <input type="hidden" name="accion" value="nuevo">
                                                                    
                                    <%-- Campo Nombre del Curso --%>
                                    <div class="mb-3 text-start">
                                        <label for="nombreCurso" class="form-label"><i class="fas fa-heading me-1"></i>Nombre del Curso:</label>
                                        <input type="text" id="nombreCurso" name="nombreCurso" class="form-control" required="true" placeholder="Ej: Introducción a la Programación">
                                    </div>

                                    <%-- Campo Código del Curso --%>
                                    <div class="mb-3 text-start">
                                        <label for="codigoCurso" class="form-label"><i class="fas fa-tag me-1"></i>Código del Curso:</label>
                                        <input type="text" id="codigoCurso" name="codigoCurso" class="form-control" required="true" placeholder="Ej: CS101">
                                    </div>

                                    <%-- Campo Créditos --%>
                                    <div class="mb-3 text-start">
                                        <label for="creditos" class="form-label"><i class="fas fa-star me-1"></i>Créditos:</label>
                                        <input type="number" id="creditos" name="creditos" class="form-control" required="true" min="1" max="10" placeholder="Ej: 3">
                                    </div>
                                    
                                    <%-- Campo ID Carrera (selector de carrera) --%>
                                    <div class="mb-3 text-start">
                                        <label for="idCarrera" class="form-label"><i class="fas fa-university me-1"></i>Carrera:</label>
                                        <select id="idCarrera" name="idCarrera" class="form-select" required="true">
                                            <option value="">-- Seleccione una Carrera --</option>
                                            <%
                                                LinkedList<Carrera> listaCarreras = carreraDao.listar(); // Asume que CarreraDao tiene un método listar()
                                                if (listaCarreras != null) {
                                                    for (Carrera car : listaCarreras) {
                                            %>
                                                        <option value="<%= car.getIdCarrera() %>"><%= car.getNombreCarrera() %></option>
                                            <%
                                                    }
                                                } else {
                                            %>
                                                        <option value="" disabled>No hay carreras disponibles</option>
                                            <%
                                                }
                                            %>
                                        </select>
                                    </div>
                                    
                                    <%-- NUEVO CAMPO: INPUT PARA LA IMAGEN --%>
                                    <div class="mb-3 text-start">
                                        <label for="imagenFile" class="form-label"><i class="fas fa-image me-1"></i>Seleccionar Imagen:</label>
                                        <input type="file" id="imagenFile" name="imagenFile" class="form-control" accept="image/*">
                                        <small class="form-text text-muted">Archivos permitidos: JPG, PNG, GIF. Tamaño máximo: 10MB.</small>
                                    </div>
                                    <%-- FIN DEL NUEVO CAMPO --%>
                                                                    
                                    <div class="d-grid gap-2 d-md-flex justify-content-md-end mt-4">
                                        <a href="listado.jsp" class="btn btn-danger d-flex align-items-center me-md-2">
                                            <i class="fas fa-times-circle me-2"></i>Cancelar
                                        </a>
                                        <button type="submit" class="btn btn-success d-flex align-items-center">
                                            <i class="fas fa-save me-2"></i>Guardar Curso
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

<%-- Scripts (puedes mantenerlos si son parte de tu referencias.jsp o moverlos aquí) --%>
<script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/js/all.min.js"></script>
<script type="text/javascript">
    let table = new DataTable('#myTable');
</script>