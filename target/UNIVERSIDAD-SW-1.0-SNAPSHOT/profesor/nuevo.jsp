<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="pe.edu.dao.FacultadDao, pe.edu.entity.Facultad" %>
<%@page import="java.util.LinkedList" %>

<%
    FacultadDao facultadDao = new FacultadDao();
    LinkedList<Facultad> listaFacultades = facultadDao.listar();
    if (listaFacultades == null) {
        listaFacultades = new LinkedList<>();
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <%@include file="../util/referencias.jsp" %>
    <title>Nuevo Profesor</title>        
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
                                <i class="fas fa-plus-circle me-2"></i>Registrar Nuevo Profesor
                            </h2>
                        </div>
                        <div class="card-body">
                            <form action="../ProfesorController" method="post">        
                                <input type="hidden" name="accion" value="nuevo">
                                
                                <%-- Campo Nombre --%>
                                <div class="mb-3 text-start">
                                    <label for="nombre" class="form-label"><i class="fas fa-user me-1"></i>Nombre:</label>
                                    <input type="text" id="nombre" name="nombre" class="form-control" required placeholder="Ej: Carlos">
                                </div>

                                <%-- Campo Apellido Paterno --%>
                                <div class="mb-3 text-start">
                                    <label for="apellidoPaterno" class="form-label"><i class="fas fa-user-tag me-1"></i>Apellido Paterno:</label>
                                    <input type="text" id="apellidoPaterno" name="apellidoPaterno" class="form-control" required placeholder="Ej: López">
                                </div>

                                <%-- Campo Apellido Materno --%>
                                <div class="mb-3 text-start">
                                    <label for="apellidoMaterno" class="form-label"><i class="fas fa-user-tag me-1"></i>Apellido Materno:</label>
                                    <input type="text" id="apellidoMaterno" name="apellidoMaterno" class="form-control" placeholder="Ej: Peralta">
                                </div>

                                <%-- Campo Email --%>
                                <div class="mb-3 text-start">
                                    <label for="email" class="form-label"><i class="fas fa-envelope me-1"></i>Email:</label>
                                    <input type="email" id="email" name="email" class="form-control" required placeholder="Ej: profesor@uni.edu.pe">
                                </div>
                                
                                <%-- Campo Facultad (por nombre, se guarda id) --%>
                                <div class="mb-3 text-start">
                                    <label for="idFacultad" class="form-label"><i class="fas fa-building me-1"></i>Facultad:</label>
                                    <select id="idFacultad" name="idFacultad" class="form-select" required>
                                        <option value="">Seleccione una facultad</option>
                                        <% for (Facultad f : listaFacultades) { %>
                                            <option value="<%= f.getIdFacultad() %>"><%= f.getNombreFacultad() %></option>
                                        <% } %>
                                    </select>
                                </div>

                                <%-- Campo Rol --%>
                                <div class="mb-3 text-start">
                                    <label for="rol" class="form-label"><i class="fas fa-user-shield me-1"></i>Rol:</label>
                                    <select id="rol" name="rol" class="form-select" required>
                                        <option value="">Seleccione un rol</option>
                                        <option value="profesor">profesor</option>
                                        <option value="jefe_departamento">jefe_departamento</option>
                                        <option value="admin">admin</option>
                                    </select>
                                </div>

                                <%-- Campo Contraseña --%>
                                <div class="mb-3 text-start">
                                    <label for="password" class="form-label"><i class="fas fa-key me-1"></i>Contraseña:</label>
                                    <input type="password" id="password" name="password" class="form-control" required placeholder="Ingrese una contraseña">
                                </div>
                                                                        
                                <div class="d-grid gap-2 d-md-flex justify-content-md-end mt-4">
                                    <a href="listado.jsp" class="btn btn-danger d-flex align-items-center me-md-2">
                                        <i class="fas fa-times-circle me-2"></i>Cancelar
                                    </a>
                                    <button type="submit" class="btn btn-success d-flex align-items-center">
                                        <i class="fas fa-save me-2"></i>Guardar Profesor
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
