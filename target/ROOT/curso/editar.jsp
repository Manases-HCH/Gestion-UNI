<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.LinkedList, pe.edu.entity.Curso, pe.edu.dao.CursoDao, pe.edu.entity.Carrera, pe.edu.dao.CarreraDao" %>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <%@include file="../util/referencias.jsp" %>
        <title>Editar Curso</title>        
    </head>
    
    <%-- Instancias DAO para interactuar con la base de datos --%>
    <jsp:useBean id="cursoDao" class="pe.edu.dao.CursoDao" scope="session"></jsp:useBean>
    <jsp:useBean id="carreraDao" class="pe.edu.dao.CarreraDao" scope="session"></jsp:useBean>
    
    <body>            
        <div class="container-fluid">
            <div class="row flex-nowrap">
                <%@include file="../menu.jsp" %>
                <div class="col py-3">    
                    <%-- Instancia de Curso para almacenar los datos --%>
                    <jsp:useBean id="curso" class="pe.edu.entity.Curso" scope="session"></jsp:useBean>
                    
                    <%
                        // Variables para manejo de errores y datos
                        String mensaje = "";
                        String tipoMensaje = "";
                        LinkedList<Carrera> listaCarreras = null;
                        
                        try {
                            // Obtener lista de carreras para el dropdown
                            listaCarreras = carreraDao.listar(); // Asume que CarreraDao tiene un método listar()
                            
                            // Obtener el ID del curso desde la URL
                            String id = request.getParameter("id");
                            
                            // Si el ID no es nulo, cargar los datos del curso
                            if (id != null && !id.isEmpty()) {
                                Curso cursoExistente = cursoDao.leer(id); // Asume que CursoDao tiene un método leer(String id)
                                if (cursoExistente != null) {
                                    // Establecer las propiedades del bean 'curso' con los datos existentes
                                    curso.setIdCurso(cursoExistente.getIdCurso());
                                    curso.setNombreCurso(cursoExistente.getNombreCurso());
                                    curso.setCodigoCurso(cursoExistente.getCodigoCurso());
                                    curso.setCreditos(cursoExistente.getCreditos());
                                    curso.setIdCarrera(cursoExistente.getIdCarrera());
                                } else {
                                    mensaje = "No se encontró el curso con ID: " + id;
                                    tipoMensaje = "danger";
                                }
                            } else {
                                mensaje = "ID de curso no proporcionado";
                                tipoMensaje = "warning";
                            }
                        } catch (Exception e) {
                            mensaje = "Error al cargar los datos: " + e.getMessage();
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
                                        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                                    </div>
                                <% } %>
                                
                                <div class="card shadow">
                                    <div class="card-header bg-primary text-white">
                                        <h4 class="mb-0">
                                            <i class="fas fa-book me-2"></i>Editar Curso
                                        </h4>
                                    </div>
                                    <div class="card-body">
                                        <form action="../CursoController" method="post" id="formEditarCurso" class="needs-validation" novalidate>
                                            <input type="hidden" name="accion" value="editar">
                                            
                                            <%-- Campo ID Curso (solo lectura) --%>
                                            <div class="mb-3">
                                                <label for="idCurso" class="form-label">
                                                    <i class="fas fa-id-card me-1"></i>ID Curso
                                                </label>
                                                <input type="text" 
                                                       id="idCurso"
                                                       name="idCurso" 
                                                       class="form-control" 
                                                       readonly
                                                       value="<jsp:getProperty name="curso" property="idCurso"></jsp:getProperty>">
                                            </div>
                                            
                                            <%-- Campo Nombre del Curso --%>
                                            <div class="mb-3">
                                                <label for="nombreCurso" class="form-label">
                                                    <i class="fas fa-heading me-1"></i>Nombre del Curso *
                                                </label>
                                                <input type="text" 
                                                       id="nombreCurso"
                                                       name="nombreCurso" 
                                                       class="form-control" 
                                                       required
                                                       value="<jsp:getProperty name="curso" property="nombreCurso"></jsp:getProperty>">
                                                <div class="invalid-feedback">
                                                    Por favor, ingrese el nombre del curso.
                                                </div>
                                            </div>

                                            <%-- Campo Código del Curso --%>
                                            <div class="mb-3">
                                                <label for="codigoCurso" class="form-label">
                                                    <i class="fas fa-tag me-1"></i>Código del Curso *
                                                </label>
                                                <input type="text" 
                                                       id="codigoCurso"
                                                       name="codigoCurso" 
                                                       class="form-control" 
                                                       required
                                                       value="<jsp:getProperty name="curso" property="codigoCurso"></jsp:getProperty>">
                                                <div class="invalid-feedback">
                                                    Por favor, ingrese el código del curso.
                                                </div>
                                            </div>

                                            <%-- Campo Créditos --%>
                                            <div class="mb-3">
                                                <label for="creditos" class="form-label">
                                                    <i class="fas fa-star me-1"></i>Créditos *
                                                </label>
                                                <input type="number" 
                                                       id="creditos"
                                                       name="creditos" 
                                                       class="form-control" 
                                                       required min="1" max="10"
                                                       value="<jsp:getProperty name="curso" property="creditos"></jsp:getProperty>">
                                                <div class="invalid-feedback">
                                                    Por favor, ingrese los créditos del curso (entre 1 y 10).
                                                </div>
                                            </div>

                                            <%-- Campo Carrera --%>
                                            <div class="mb-3">
                                                <label for="idCarrera" class="form-label">
                                                    <i class="fas fa-university me-1"></i>Carrera *
                                                </label>
                                                <select id="idCarrera" 
                                                        name="idCarrera" 
                                                        class="form-select" 
                                                        required>
                                                    <option value="">Seleccione una carrera</option>
                                                    <% 
                                                        if (listaCarreras != null) {
                                                            for (Carrera carrera : listaCarreras) { 
                                                                String selected = "";
                                                                // Nota: idCarrera es int, getIdCarrera() devuelve int
                                                                if (curso.getIdCarrera() == carrera.getIdCarrera()) {
                                                                    selected = "selected";
                                                                }
                                                    %>
                                                            <option value="<%= carrera.getIdCarrera() %>" <%= selected %>>
                                                                <%= carrera.getNombreCarrera() %>
                                                            </option>
                                                    <%  
                                                            }
                                                        }
                                                    %>
                                                </select>
                                                <div class="invalid-feedback">
                                                    Por favor, seleccione una carrera.
                                                </div>
                                            </div>
                                            
                                            <%-- Información adicional --%>
                                            <div class="alert alert-info">
                                                <i class="fas fa-info-circle me-2"></i>
                                                <strong>Campos obligatorios:</strong> Los campos marcados con (*) son obligatorios.
                                            </div>
                                            
                                            <%-- Botones de acción --%>
                                            <div class="d-grid gap-2 d-md-flex justify-content-md-end">
                                                <a href="listado.jsp" class="btn btn-outline-secondary me-md-2">
                                                    <i class="fas fa-times me-1"></i>Cancelar
                                                </a>
                                                <button type="submit" class="btn btn-success">
                                                    <i class="fas fa-check me-1"></i>Guardar Cambios
                                                </button>
                                            </div>
                                        </form>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <%-- Scripts --%>
        <script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/js/all.min.js"></script>
        <script type="text/javascript">
    let table = new DataTable('#myTable');
</script>
        <script>
            // Validación del formulario Bootstrap
            (function() {
                'use strict';
                window.addEventListener('load', function() {
                    var forms = document.getElementsByClassName('needs-validation');
                    var validation = Array.prototype.filter.call(forms, function(form) {
                        form.addEventListener('submit', function(event) {
                            if (form.checkValidity() === false) {
                                event.preventDefault();
                                event.stopPropagation();
                            }
                            form.classList.add('was-validated');
                        }, false);
                    });
                }, false);
            })();

            // Confirmación antes de guardar
            document.getElementById('formEditarCurso').addEventListener('submit', function(e) {
                if (!confirm('¿Está seguro de que desea guardar los cambios en este curso?')) {
                    e.preventDefault();
                }
            });
        </script>
    </body>
</html>