<%@page contentType="text/html" pageEncoding="UTF-8"%> 
<%@page import="java.util.LinkedList, pe.edu.entity.Alumno, pe.edu.dao.AlumnoDao" %> 
<!DOCTYPE html> 
<html> 
    <head> 
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"> 
        <%@include file="../util/referencias.jsp" %> 
        <title>Eliminar Alumno</title> 
    </head> 
    <%-- Instancia de AlumnoDao para interactuar con la base de datos --%> 
    <jsp:useBean id="alumnoDao" class="pe.edu.dao.AlumnoDao" scope="session"></jsp:useBean> 
    <body> 
        <div class="container-fluid"> 
            <div class="row flex-nowrap"> 
                <%@include file="../menu.jsp" %> 
                <div class="col py-3"> 
                    <%-- Instancia de Alumno para almacenar los datos del alumno a eliminar --%> 
                    <jsp:useBean id="alumno" class="pe.edu.entity.Alumno" scope="session"></jsp:useBean> 
                    <% 
                    // Obtener el ID del alumno desde la URL 
                    String id = request.getParameter("idAlumno"); 
                        // Si el ID no es nulo, cargar los datos del alumno de la base de datos 
                    if (id != null && !id.isEmpty()) { 
                        Alumno alumnoExistente = alumnoDao.leer(id); 
                        if (alumnoExistente != null) { 
                            alumno.setIdAlumno(alumnoExistente.getIdAlumno()); 
                            alumno.setDni(alumnoExistente.getDni()); 
                            alumno.setNombre(alumnoExistente.getNombre()); 
                            alumno.setApellidoPaterno(alumnoExistente.getApellidoPaterno()); 
                            alumno.setApellidoMaterno(alumnoExistente.getApellidoMaterno()); 
                            alumno.setDireccion(alumnoExistente.getDireccion()); 
                            alumno.setTelefono(alumnoExistente.getTelefono()); 
                            alumno.setFechaNacimiento(alumnoExistente.getFechaNacimiento()); 
                            alumno.setEmail(alumnoExistente.getEmail()); 
                            alumno.setIdCarrera(alumnoExistente.getIdCarrera()); 
                            alumno.setRol(alumnoExistente.getRol()); 
                            alumno.setPassword(alumnoExistente.getPassword()); 
                        }
 
                    } 
                    %> 
                    <center> 
                        <div class="card shadow-lg col-12 col-md-8 col-lg-6">
                            <div class="card-header bg-danger text-white text-center">
                                <h2 class="mb-0">
                                    <i class="fas fa-user-times me-2"></i>Confirmar Eliminación
                                </h2>
                            </div> 
                            <br> 
                            <div class="card-body p-4">
                                <p class="text-center text-muted mb-4">
                                    ¿Estás seguro de que deseas eliminar el siguiente registro de alumno? Esta acción no se puede deshacer.
                                </p>

                                <form action="../AlumnoController" method="post">
    <input type="hidden" name="accion" value="eliminar">
    <input type="hidden" name="idAlumno" value="<jsp:getProperty name='alumno' property='idAlumno'/>">

    <div class="table-responsive mt-3">
        <table class="table table-bordered table-striped align-middle text-center">
            <tbody>
                <tr><th>ID Alumno</th><td><jsp:getProperty name="alumno" property="idAlumno" /></td></tr>
                                            <tr><th>DNI</th><td><jsp:getProperty name="alumno" property="dni" /></td></tr>
                                            <tr><th>Nombre</th><td><jsp:getProperty name="alumno" property="nombre" /></td></tr>
                                            <tr><th>Apellido Paterno</th><td><jsp:getProperty name="alumno" property="apellidoPaterno" /></td></tr>
                                            <tr><th>Apellido Materno</th><td><jsp:getProperty name="alumno" property="apellidoMaterno" /></td></tr>
                                            <tr><th>Dirección</th><td><jsp:getProperty name="alumno" property="direccion" /></td></tr>
                                            <tr><th>Teléfono</th><td><jsp:getProperty name="alumno" property="telefono" /></td></tr>
                                            <tr><th>Fecha Nacimiento</th><td><jsp:getProperty name="alumno" property="fechaNacimiento" /></td></tr>
                                            <tr><th>Email</th><td><jsp:getProperty name="alumno" property="email" /></td></tr>
                                            <tr><th>ID Carrera</th><td><jsp:getProperty name="alumno" property="idCarrera" /></td></tr>
                                            <tr><th>Rol</th><td><jsp:getProperty name="alumno" property="rol" /></td></tr>
                                        </tbody>
            </tbody>
        </table>
    </div>

    <div class="d-flex justify-content-center mt-4">
        <a href="listado.jsp" class="btn btn-secondary me-3">
            <i class="fas fa-arrow-left me-1"></i>Cancelar
        </a>
        <button type="submit" class="btn btn-danger">
            <i class="fas fa-trash-alt me-1"></i>Eliminar Definitivamente
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