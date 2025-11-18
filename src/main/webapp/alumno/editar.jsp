<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="pe.edu.entity.Alumno, pe.edu.dao.AlumnoDao" %>
<!DOCTYPE html>
<html>
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <%@include file="../util/referencias.jsp" %>
    <title>Editar Alumno</title>
</head>

<jsp:useBean id="alumnoDao" class="pe.edu.dao.AlumnoDao" scope="request" />
<jsp:useBean id="alumno" class="pe.edu.entity.Alumno" scope="request" />

<body>
    <div class="container-fluid">
        <div class="row flex-nowrap">
            <%@include file="../menu.jsp" %>
            <div class="col py-3">

                <% 
                    String id = request.getParameter("idAlumno");
                    if (id != null && !id.isEmpty()) {
                        Alumno alumnoExistente = alumnoDao.leer(id);
                        if (alumnoExistente != null) {
                            alumno = alumnoExistente;
                        }
                    }
                %>

                <center>
                    <div class="card shadow-lg col-12 col-md-8 col-lg-6">
                        <div class="card-header bg-primary text-white text-center">
                            <h2 class="mb-0">
                                <i class="fas fa-user-edit me-2"></i>Editar Alumno
                            </h2>
                        </div>

                        <div class="card-body p-4">
                            <form action="../AlumnoController" method="post">
                                <input type="hidden" name="accion" value="editar">

                                <div class="mb-3">
                                    <label class="form-label fw-bold">ID Alumno</label>
                                    <input type="text" name="idAlumno" class="form-control" readonly
                                           value="<%= alumno.getIdAlumno() %>">
                                </div>

                                <div class="row">
                                    <div class="col-md-6 mb-3">
                                        <label class="form-label fw-bold">DNI</label>
                                        <input type="text" name="dni" class="form-control"
                                               value="<%= alumno.getDni() %>">
                                    </div>
                                    <div class="col-md-6 mb-3">
                                        <label class="form-label fw-bold">Nombre</label>
                                        <input type="text" name="nombre" class="form-control"
                                               value="<%= alumno.getNombre() %>">
                                    </div>
                                </div>

                                <div class="row">
                                    <div class="col-md-6 mb-3">
                                        <label class="form-label fw-bold">Apellido Paterno</label>
                                        <input type="text" name="apellidoPaterno" class="form-control"
                                               value="<%= alumno.getApellidoPaterno() %>">
                                    </div>
                                    <div class="col-md-6 mb-3">
                                        <label class="form-label fw-bold">Apellido Materno</label>
                                        <input type="text" name="apellidoMaterno" class="form-control"
                                               value="<%= alumno.getApellidoMaterno() %>">
                                    </div>
                                </div>

                                <div class="mb-3">
                                    <label class="form-label fw-bold">Dirección</label>
                                    <input type="text" name="direccion" class="form-control"
                                           value="<%= alumno.getDireccion() %>">
                                </div>

                                <div class="row">
                                    <div class="col-md-6 mb-3">
                                        <label class="form-label fw-bold">Teléfono</label>
                                        <input type="text" name="telefono" class="form-control"
                                               value="<%= alumno.getTelefono() %>">
                                    </div>
                                    <div class="col-md-6 mb-3">
                                        <label class="form-label fw-bold">Fecha de Nacimiento</label>
                                        <input type="date" name="fechaNacimiento" class="form-control"
                                               value="<%= alumno.getFechaNacimiento() %>">
                                    </div>
                                </div>

                                <div class="mb-3">
                                    <label class="form-label fw-bold">Email</label>
                                    <input type="email" name="email" class="form-control"
                                           value="<%= alumno.getEmail() %>">
                                </div>

                                <div class="row">
                                    <div class="col-md-6 mb-3">
                                        <label class="form-label fw-bold">ID Carrera</label>
                                        <input type="text" name="idCarrera" class="form-control"
                                               value="<%= alumno.getIdCarrera() %>">
                                    </div>
                                    <div class="col-md-6 mb-3">
                                        <label class="form-label fw-bold">Rol</label>
                                        <input type="text" name="rol" class="form-control"
                                               value="<%= alumno.getRol() %>">
                                    </div>
                                </div>

                                <div class="mb-3">
                                    <label class="form-label fw-bold">Password</label>
                                    <input type="text" name="password" class="form-control"
                                           value="<%= alumno.getPassword() %>">
                                </div>

                                <div class="d-flex justify-content-center mt-4">
                                    <a href="listado.jsp" class="btn btn-secondary me-3">
                                        <i class="fas fa-arrow-left me-1"></i>Cancelar
                                    </a>
                                    <button type="submit" class="btn btn-success">
                                        <i class="fas fa-save me-1"></i>Guardar Cambios
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

<script src="https://code.jquery.com/jquery-3.7.1.js"></script>
<script src="https://cdn.datatables.net/2.3.1/js/dataTables.js"></script>
<script type="text/javascript">
let table = new DataTable('#myTable');
</script>
