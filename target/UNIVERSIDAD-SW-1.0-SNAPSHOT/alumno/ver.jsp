<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="pe.edu.entity.Alumno, pe.edu.dao.AlumnoDao" %>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <%@include file="../util/referencias.jsp" %>
        <title>Ver Alumno</title>
    </head>

    <%-- Instancia del DAO y del bean Alumno --%>
    <jsp:useBean id="alumnoDao" class="pe.edu.dao.AlumnoDao" scope="page" />
    <jsp:useBean id="alumno" class="pe.edu.entity.Alumno" scope="page" />

    <body>
        <div class="container-fluid">
            <div class="row flex-nowrap">
                <%@include file="../menu.jsp" %>
                <div class="col py-3">

                    <%
                        // Obtener el ID del alumno desde la URL
                        String idAlumno = request.getParameter("idAlumno");

                        // Si el ID no es nulo, cargar los datos del alumno
                        if (idAlumno != null && !idAlumno.isEmpty()) {
                            Alumno alumnoExistente = alumnoDao.leer(idAlumno);
                            if (alumnoExistente != null) {
                                alumno = alumnoExistente;
                            }
                        }
                    %>

                    <center>
                        <div class="card card_login shadow-sm" style="max-width: 600px;">
                            <div class="card-header card_titulo bg-primary text-white">
                                <h2 class="mb-0">Información del Alumno</h2>
                            </div>
                            <div class="card-body text-start mt-3">

                                <p><strong>ID Alumno:</strong> <%= alumno.getIdAlumno() %></p>
                                <p><strong>DNI:</strong> <%= alumno.getDni() %></p>
                                <p><strong>Nombre:</strong> <%= alumno.getNombre() %></p>
                                <p><strong>Apellido Paterno:</strong> <%= alumno.getApellidoPaterno() %></p>
                                <p><strong>Apellido Materno:</strong> <%= alumno.getApellidoMaterno() %></p>
                                <p><strong>Dirección:</strong> <%= alumno.getDireccion() %></p>
                                <p><strong>Teléfono:</strong> <%= alumno.getTelefono() %></p>
                                <p><strong>Fecha de Nacimiento:</strong> <%= alumno.getFechaNacimiento() %></p>
                                <p><strong>Email:</strong> <%= alumno.getEmail() %></p>
                                <p><strong>Carrera:</strong> <%= alumno.getNombreCarrera() %></p>
                                <p><strong>Rol:</strong> <%= alumno.getRol() %></p>
                                <p><strong>Estado:</strong> <%= alumno.getEstado() %></p>
                                <p><strong>Intentos:</strong> <%= alumno.getIntentos() %></p>
                                <p><strong>Fecha Registro:</strong> <%= alumno.getFechaRegistro() %></p>

                                <div class="text-center mt-4">
                                    <a href="listado.jsp" class="btn btn-secondary">
                                        <i class="fas fa-arrow-left me-2"></i>Volver al Listado
                                    </a>
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

<script type="text/javascript">
    let table = new DataTable('#myTable');
</script>