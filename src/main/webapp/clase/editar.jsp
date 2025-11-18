<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.LinkedList, pe.edu.entity.Clase, pe.edu.dao.ClaseDao, pe.edu.entity.Curso, pe.edu.dao.CursoDao, pe.edu.entity.Profesor, pe.edu.dao.ProfesorDao, pe.edu.entity.Horario, pe.edu.dao.HorarioDao" %>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <%@include file="../util/referencias.jsp" %>
        <title>Editar Clase</title>        
    </head>
    
    <%-- Instancias DAO para interactuar con la base de datos --%>
    <jsp:useBean id="claseDao" class="pe.edu.dao.ClaseDao" scope="session"></jsp:useBean>
    <jsp:useBean id="cursoDao" class="pe.edu.dao.CursoDao" scope="session"></jsp:useBean>
    <jsp:useBean id="profesorDao" class="pe.edu.dao.ProfesorDao" scope="session"></jsp:useBean>
    <jsp:useBean id="horarioDao" class="pe.edu.dao.HorarioDao" scope="session"></jsp:useBean>
    
    <body>            
        <div class="container-fluid">
            <div class="row flex-nowrap">
                <%@include file="../menu.jsp" %>
                <div class="col py-3">    
                    <%-- Instancia de Clase para almacenar los datos --%>
                    <jsp:useBean id="clase" class="pe.edu.entity.Clase" scope="session"></jsp:useBean>
                    
                    <%
                        // Variables para manejo de errores y datos
                        String mensaje = "";
                        String tipoMensaje = "";
                        LinkedList<Curso> listaCursos = null;
                        LinkedList<Profesor> listaProfesores = null;
                        LinkedList<Horario> listaHorarios = null;
                        
                        try {
                            // Obtener listas para los dropdowns
                            listaCursos = cursoDao.listar();
                            listaProfesores = profesorDao.listar();
                            listaHorarios = horarioDao.listar();
                            
                            // Obtener el ID de la clase desde la URL
                            String id = request.getParameter("id");
                            
                            // Si el ID no es nulo, cargar los datos de la clase
                            if (id != null && !id.isEmpty()) {
                                Clase claseExistente = claseDao.leer(id);
                                if (claseExistente != null) {
                                    clase.setIdClase(claseExistente.getIdClase());
                                    clase.setIdCurso(claseExistente.getIdCurso());
                                    clase.setIdProfesor(claseExistente.getIdProfesor());
                                    clase.setIdHorario(claseExistente.getIdHorario());
                                    clase.setCiclo(claseExistente.getCiclo());
                                } else {
                                    mensaje = "No se encontró la clase con ID: " + id;
                                    tipoMensaje = "danger";
                                }
                            } else {
                                mensaje = "ID de clase no proporcionado";
                                tipoMensaje = "warning";
                            }
                        } catch (Exception e) {
                            mensaje = "Error al cargar los datos: " + e.getMessage();
                            tipoMensaje = "danger";
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
                                            <i class="fas fa-chalkboard-teacher me-2"></i>Editar Clase
                                        </h4>
                                    </div>
                                    <div class="card-body">
                                        <form action="../ClaseController" method="post" id="formEditarClase" class="needs-validation" novalidate>
                                            <input type="hidden" name="accion" value="editar">
                                            
                                            <%-- Campo ID Clase (solo lectura) --%>
                                            <div class="mb-3">
                                                <label for="idClase" class="form-label">
                                                    <i class="fas fa-id-card me-1"></i>ID Clase
                                                </label>
                                                <input type="text" 
                                                       id="idClase"
                                                       name="idClase" 
                                                       class="form-control" 
                                                       readonly
                                                       value="<jsp:getProperty name="clase" property="idClase"></jsp:getProperty>">
                                            </div>
                                            
                                            <%-- Campo Curso --%>
                                            <div class="mb-3">
                                                <label for="idCurso" class="form-label">
                                                    <i class="fas fa-book me-1"></i>Curso *
                                                </label>
                                                <select id="idCurso" 
                                                        name="idCurso" 
                                                        class="form-select" 
                                                        required>
                                                    <option value="">Seleccione un curso</option>
                                                    <% 
                                                    if (listaCursos != null) {
                                                        for (Curso curso : listaCursos) { 
                                                            String selected = "";
                                                            if (clase.getIdCurso() != null && 
                                                                clase.getIdCurso().equals(curso.getIdCurso())) {
                                                                selected = "selected";
                                                            }
                                                    %>
                                                        <option value="<%= curso.getIdCurso() %>" <%= selected %>>
                                                            <%= curso.getNombreCurso() %> - <%= curso.getCreditos() %> créditos
                                                        </option>
                                                    <% 
                                                        }
                                                    }
                                                    %>
                                                </select>
                                                <div class="invalid-feedback">
                                                    Por favor, seleccione un curso.
                                                </div>
                                            </div>

                                            <%-- Campo Profesor --%>
                                            <div class="mb-3">
                                                <label for="idProfesor" class="form-label">
                                                    <i class="fas fa-user-tie me-1"></i>Profesor *
                                                </label>
                                                <select id="idProfesor" 
                                                        name="idProfesor" 
                                                        class="form-select" 
                                                        required>
                                                    <option value="">Seleccione un profesor</option>
                                                    <% 
                                                    if (listaProfesores != null) {
                                                        for (Profesor profesor : listaProfesores) { 
                                                            String selected = "";
                                                            if (clase.getIdProfesor() != null && 
                                                                clase.getIdProfesor().equals(profesor.getIdProfesor())) {
                                                                selected = "selected";
                                                            }
                                                    %>
                                                        <option value="<%= profesor.getIdProfesor() %>" <%= selected %>>
                                                            <%= profesor.getNombre() %> <%= profesor.getApellidoPaterno() %>
                                                        </option>
                                                    <% 
                                                        }
                                                    }
                                                    %>
                                                </select>
                                                <div class="invalid-feedback">
                                                    Por favor, seleccione un profesor.
                                                </div>
                                            </div>

                                            <%-- Campo Horario --%>
                                            <div class="mb-3">
                                                <label for="idHorario" class="form-label">
                                                    <i class="fas fa-clock me-1"></i>Horario *
                                                </label>
                                                <select id="idHorario" 
                                                        name="idHorario" 
                                                        class="form-select" 
                                                        required>
                                                    <option value="">Seleccione un horario</option>
                                                    <% 
                                                    if (listaHorarios != null) {
                                                        for (Horario horario : listaHorarios) { 
                                                            String selected = "";
                                                            if (clase.getIdHorario() != null && 
                                                                clase.getIdHorario().equals(horario.getIdHorario())) {
                                                                selected = "selected";
                                                            }
                                                    %>
                                                        <option value="<%= horario.getIdHorario() %>" <%= selected %>>
                                                            <%= horario.getDiaSemana() %> - <%= horario.getHoraInicio() %> a <%= horario.getHoraFin() %>
                                                        </option>
                                                    <% 
                                                        }
                                                    }
                                                    %>
                                                </select>
                                                <div class="invalid-feedback">
                                                    Por favor, seleccione un horario.
                                                </div>
                                            </div>

                                            <%-- Campo Ciclo --%>
                                            <div class="mb-3">
                                                <label for="ciclo" class="form-label">
                                                    <i class="fas fa-calendar-alt me-1"></i>Ciclo *
                                                </label>
                                                <select id="ciclo" 
                                                        name="ciclo" 
                                                        class="form-select" 
                                                        required>
                                                    <option value="">Seleccione un ciclo</option>
                                                    <% 
                                                        String[] ciclos = {"2024-I", "2024-II", "2024-III", "2025-I", "2025-II", "2025-III"};
                                                        for (String cicloOption : ciclos) { 
                                                            String selected = "";
                                                            if (clase.getCiclo() != null && 
                                                                clase.getCiclo().equals(cicloOption)) {
                                                                selected = "selected";
                                                            }
                                                    %>
                                                        <option value="<%= cicloOption %>" <%= selected %>>
                                                            <%= cicloOption %>
                                                        </option>
                                                    <% } %>
                                                </select>
                                                <div class="invalid-feedback">
                                                    Por favor, seleccione un ciclo.
                                                </div>
                                            </div>
                                            
                                            <%-- Información adicional --%>
                                            <div class="alert alert-info">
                                                <i class="fas fa-info-circle me-2"></i>
                                                <strong>Información:</strong> Asegúrese de que no existan conflictos de horario para el profesor seleccionado.
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
            document.getElementById('formEditarClase').addEventListener('submit', function(e) {
                if (!confirm('¿Está seguro de que desea guardar los cambios en esta clase?')) {
                    e.preventDefault();
                }
            });

            // Validación de conflictos de horario (opcional)
            document.getElementById('idProfesor').addEventListener('change', function() {
                var profesorId = this.value;
                var horarioId = document.getElementById('idHorario').value;
                var ciclo = document.getElementById('ciclo').value;
                
                if (profesorId && horarioId && ciclo) {
                    // Aquí podrías hacer una llamada AJAX para verificar conflictos
                    console.log('Verificando conflictos para profesor:', profesorId, 'horario:', horarioId, 'ciclo:', ciclo);
                }
            });

            document.getElementById('idHorario').addEventListener('change', function() {
                var horarioId = this.value;
                var profesorId = document.getElementById('idProfesor').value;
                var ciclo = document.getElementById('ciclo').value;
                
                if (profesorId && horarioId && ciclo) {
                    // Aquí podrías hacer una llamada AJAX para verificar conflictos
                    console.log('Verificando conflictos para horario:', horarioId, 'profesor:', profesorId, 'ciclo:', ciclo);
                }
            });
        </script>
    </body>
</html>