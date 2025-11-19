<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.LinkedList, pe.edu.entity.Curso, pe.edu.dao.CursoDao, pe.edu.entity.Carrera, pe.edu.dao.CarreraDao" %>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <%@include file="../util/referencias.jsp" %>
        <title>Eliminar Curso</title>        
    </head>
    
    <%-- Instancia de CursoDao para interactuar con la base de datos --%>
    <jsp:useBean id="cursoDao" class="pe.edu.dao.CursoDao" scope="session"></jsp:useBean>
    <jsp:useBean id="carreraDao" class="pe.edu.dao.CarreraDao" scope="session"></jsp:useBean>
    
    <body>            
        <div class="container-fluid">
            <div class="row flex-nowrap">
                <%@include file="../menu.jsp" %>
                <div class="col py-3">    
                    <%-- Instancia de Curso para almacenar los datos del curso a eliminar --%>
                    <jsp:useBean id="curso" class="pe.edu.entity.Curso" scope="session"></jsp:useBean>
                    <%
                        // Variables para manejo de errores y datos
                        String mensaje = "";
                        String tipoMensaje = "";
                        Carrera carreraAsociada = null; // Para mostrar el nombre de la carrera

                        try {
                            // Obtener el ID del curso desde la URL
                            String id = request.getParameter("id");
                            
                            // Si el ID no es nulo, cargar los datos del curso de la base de datos
                            if (id != null && !id.isEmpty()) {
                                Curso cursoExistente = cursoDao.leer(id); // Asume que CursoDao tiene un método leer(String id)
                                if (cursoExistente != null) {
                                    // Establecer las propiedades del bean 'curso' con los datos existentes
                                    curso.setIdCurso(cursoExistente.getIdCurso());
                                    curso.setNombreCurso(cursoExistente.getNombreCurso());
                                    curso.setCodigoCurso(cursoExistente.getCodigoCurso());
                                    curso.setCreditos(cursoExistente.getCreditos());
                                    curso.setIdCarrera(cursoExistente.getIdCarrera());

                                    // Obtener el nombre de la carrera asociada
                                    carreraAsociada = carreraDao.leer(cursoExistente.getIdCarrera()); // Asume que CarreraDao tiene un método leer(int id)
                                } else {
                                    mensaje = "No se encontró el curso con ID: " + id + ".";
                                    tipoMensaje = "danger";
                                }
                            } else {
                                mensaje = "ID de curso no proporcionado para eliminar.";
                                tipoMensaje = "warning";
                            }
                        } catch (Exception e) {
                            mensaje = "Error al cargar los datos del curso: " + e.getMessage();
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

                                <% if (curso.getIdCurso() != null && !curso.getIdCurso().isEmpty()) { %>
                                    <div class="card shadow">
                                        <div class="card-header bg-danger text-white">
                                            <h4 class="mb-0">
                                                <i class="fas fa-trash-alt me-2"></i>Confirmar Eliminación de Curso
                                            </h4>
                                        </div>
                                        <div class="card-body">
                                            <p class="lead text-center">
                                                ¿Está seguro que desea eliminar el siguiente curso?
                                            </p>
                                            
                                            <form action="../CursoController" method="post">
                                                <input type="hidden" name="accion" value="eliminar">
                                                <input type="hidden" name="idCurso" value="<jsp:getProperty name="curso" property="idCurso"></jsp:getProperty>">
                                                
                                                <div class="mb-3">
                                                    <label class="form-label fw-bold"><i class="fas fa-id-card me-1"></i>ID Curso:</label>
                                                    <p class="form-control-plaintext"><jsp:getProperty name="curso" property="idCurso"></jsp:getProperty></p>
                                                </div>
                                                
                                                <div class="mb-3">
                                                    <label class="form-label fw-bold"><i class="fas fa-heading me-1"></i>Nombre del Curso:</label>
                                                    <p class="form-control-plaintext"><jsp:getProperty name="curso" property="nombreCurso"></jsp:getProperty></p>
                                                </div>

                                                <div class="mb-3">
                                                    <label class="form-label fw-bold"><i class="fas fa-tag me-1"></i>Código del Curso:</label>
                                                    <p class="form-control-plaintext"><jsp:getProperty name="curso" property="codigoCurso"></jsp:getProperty></p>
                                                </div>

                                                <div class="mb-3">
                                                    <label class="form-label fw-bold"><i class="fas fa-star me-1"></i>Créditos:</label>
                                                    <p class="form-control-plaintext"><jsp:getProperty name="curso" property="creditos"></jsp:getProperty></p>
                                                </div>

                                                <div class="mb-3">
                                                    <label class="form-label fw-bold"><i class="fas fa-university me-1"></i>Carrera:</label>
                                                    <p class="form-control-plaintext">
                                                        <% if (carreraAsociada != null) { %>
                                                            <%= carreraAsociada.getNombreCarrera() %>
                                                        <% } else { %>
                                                            Desconocida
                                                        <% } %>
                                                    </p>
                                                </div>
                                                
                                                <div class="alert alert-danger" role="alert">
                                                    <strong>¡Advertencia!</strong> Esta acción es irreversible. Una vez eliminado, los datos del curso no podrán recuperarse.
                                                </div>
                                                
                                                <div class="d-grid gap-2 d-md-flex justify-content-md-end">
                                                    <a href="listado.jsp" class="btn btn-outline-secondary me-md-2">
                                                        <i class="fas fa-times me-1"></i>Cancelar
                                                    </a>
                                                    <button type="submit" class="btn btn-danger" 
                                                            onclick="return confirm('¿Está ABSOLUTAMENTE seguro de que desea eliminar este curso? Esta acción es irreversible.')">
                                                        <i class="fas fa-trash-alt me-1"></i>Eliminar Curso
                                                    </button>
                                                </div>
                                            </form>
                                        </div>
                                    </div>
                                <% } else { %>
                                    <div class="alert alert-info mt-3" role="alert">
                                        No hay datos de curso para mostrar. Por favor, asegúrese de que el ID sea válido.
                                    </div>
                                <% } %>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        
        <%-- Scripts (puedes mantenerlos si son parte de tu referencias.jsp o moverlos aquí) --%>
        <script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/js/all.min.js"></script>
        <%-- Estos scripts son para DataTables y probablemente no son necesarios en una página de eliminación simple --%>
        <%-- <script src="https://cdn.datatables.net/2.3.1/js/dataTables.js"></script> --%>
        <%-- <script type="text/javascript">
            let table = new DataTable('#myTable');
        </script> --%>
    </body>
</html>
<script type="text/javascript">
    let table = new DataTable('#myTable');
</script>