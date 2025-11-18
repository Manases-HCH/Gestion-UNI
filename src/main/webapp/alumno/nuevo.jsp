<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.LinkedList, pe.edu.entity.Alumno, pe.edu.dao.AlumnoDao, pe.edu.entity.Carrera, pe.edu.dao.CarreraDao" %>
<!DOCTYPE html>
<html>
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <%@include file="../util/referencias.jsp" %>
    <title>Registrar Alumno</title>
</head>

<body>
    <div class="container-fluid">
        <div class="row flex-nowrap">
            <%@include file="../menu.jsp" %>

            <div class="col py-3">
                <div class="card card_login shadow col-12 col-md-8 col-lg-6 mx-auto">
                    <div class="card-header card_titulo bg-primary text-white text-center">
                        <h2 class="mb-0">
                            <i class="fas fa-user-graduate me-2"></i>Registrar Nuevo Alumno
                        </h2>
                    </div>

                    <div class="card-body">
                        <form action="../AlumnoController" method="post">
                            <input type="hidden" name="accion" value="nuevo">

                            <div class="mb-3">
                                <label for="dni" class="form-label"><i class="fas fa-id-card me-1"></i>DNI:</label>
                                <input type="text" id="dni" name="dni" class="form-control" maxlength="8" required>
                            </div>

                            <div class="mb-3">
                                <label for="nombre" class="form-label"><i class="fas fa-user me-1"></i>Nombre:</label>
                                <input type="text" id="nombre" name="nombre" class="form-control" required>
                            </div>

                            <div class="mb-3">
                                <label for="apellidoPaterno" class="form-label"><i class="fas fa-user-tag me-1"></i>Apellido Paterno:</label>
                                <input type="text" id="apellidoPaterno" name="apellidoPaterno" class="form-control" required>
                            </div>

                            <div class="mb-3">
                                <label for="apellidoMaterno" class="form-label"><i class="fas fa-user-tag me-1"></i>Apellido Materno:</label>
                                <input type="text" id="apellidoMaterno" name="apellidoMaterno" class="form-control" required>
                            </div>

                            <div class="mb-3">
                                <label for="direccion" class="form-label"><i class="fas fa-map-marker-alt me-1"></i>Dirección:</label>
                                <input type="text" id="direccion" name="direccion" class="form-control" required>
                            </div>

                            <div class="mb-3">
                                <label for="telefono" class="form-label"><i class="fas fa-phone me-1"></i>Teléfono:</label>
                                <input type="text" id="telefono" name="telefono" class="form-control" maxlength="9" required>
                            </div>

                            <div class="mb-3">
                                <label for="fechaNacimiento" class="form-label"><i class="fas fa-calendar-alt me-1"></i>Fecha de Nacimiento:</label>
                                <input type="date" id="fechaNacimiento" name="fechaNacimiento" class="form-control" required>
                            </div>

                            <div class="mb-3">
                                <label for="email" class="form-label"><i class="fas fa-envelope me-1"></i>Email:</label>
                                <input type="email" id="email" name="email" class="form-control" required>
                            </div>

                            <div class="mb-3">
                                <label for="idCarrera" class="form-label"><i class="fas fa-graduation-cap me-1"></i>Carrera:</label>
                                <select id="idCarrera" name="idCarrera" class="form-select" required>
                                    <option value="">Seleccione una carrera</option>
                                    <%
                                        CarreraDao carreraDao = new CarreraDao();
                                        LinkedList<Carrera> carreras = carreraDao.listar();
                                        for (Carrera carrera : carreras) {
                                    %>
                                        <option value="<%= carrera.getIdCarrera() %>"><%= carrera.getNombreCarrera() %></option>
                                    <%
                                        }
                                    %>
                                </select>
                            </div>

                            <div class="mb-3">
                                <label for="rol" class="form-label"><i class="fas fa-user-shield me-1"></i>Rol:</label>
                                <input type="text" id="rol" name="rol" class="form-control" value="alumno" readonly>
                            </div>

                            <div class="mb-3">
                                <label for="password" class="form-label"><i class="fas fa-key me-1"></i>Contraseña:</label>
                                <input type="password" id="password" name="password" class="form-control" required>
                            </div>

                            <div class="d-flex justify-content-end mt-4">
                                <a href="listado.jsp" class="btn btn-secondary me-2">
                                    <i class="fas fa-times-circle me-1"></i>Cancelar
                                </a>
                                <button type="submit" class="btn btn-success">
                                    <i class="fas fa-save me-1"></i>Guardar Alumno
                                </button>
                            </div>
                        </form>
                    </div>
                </div>              
            </div>
        </div>
    </div>
</body>
</html>

<script src="https://code.jquery.com/jquery-3.7.1.js"></script>
<script src="https://cdn.datatables.net/2.3.1/js/dataTables.js"></script>
<script type="text/javascript">
    // You might not need DataTable for this specific page, as it's a form.
    // If you plan to add a table later, keep this.
    // let table = new DataTable('#myTable'); 
</script>