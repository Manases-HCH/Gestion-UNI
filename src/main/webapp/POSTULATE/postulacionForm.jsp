<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="pe.edu.entity.Carrera" %>
<%@ page import="java.util.List" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Formulario de Postulación</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body {
            background-color: #f8f9fa;
        }
        .form-container {
            margin-top: 50px;
            margin-bottom: 50px;
        }
    </style>
</head>
<body>
    <div class="container form-container">
        <div class="card shadow-sm">
            <div class="card-header bg-primary text-white">
                <h2 class="mb-0 text-center">Formulario de Postulación</h2>
            </div>
            <div class="card-body">
                <% if (request.getAttribute("success") != null && !(Boolean) request.getAttribute("success")) { %>
                    <div class="alert alert-danger" role="alert">
                        <%= request.getAttribute("message") %>
                    </div>
                <% } %>

                <form action="${pageContext.request.contextPath}/postulacion" method="post">
                    <div class="mb-3">
                        <label for="nombreCompleto" class="form-label">Nombre Completo:</label>
                        <input type="text" class="form-control" id="nombreCompleto" name="nombreCompleto" value="${param.nombreCompleto}" required>
                    </div>
                    <div class="mb-3">
                        <label for="dni" class="form-label">DNI:</label>
                        <input type="text" class="form-control" id="dni" name="dni" pattern="[0-9]{8}" title="El DNI debe contener 8 dígitos numéricos" value="${param.dni}" required>
                    </div>
                    <div class="mb-3">
                        <label for="fechaNacimiento" class="form-label">Fecha de Nacimiento:</label>
                        <input type="date" class="form-control" id="fechaNacimiento" name="fechaNacimiento" value="${param.fechaNacimiento}" required>
                    </div>
                    <div class="mb-3">
                        <label for="email" class="form-label">Email:</label>
                        <input type="email" class="form-control" id="email" name="email" value="${param.email}" required>
                    </div>
                    <div class="mb-3">
                        <label for="telefono" class="form-label">Teléfono:</label>
                        <input type="text" class="form-control" id="telefono" name="telefono" pattern="[0-9]{9}" title="El teléfono debe contener 9 dígitos numéricos" value="${param.telefono}" required>
                    </div>
                    <div class="mb-3">
                        <label for="direccion" class="form-label">Dirección:</label>
                        <input type="text" class="form-control" id="direccion" name="direccion" value="${param.direccion}" required>
                    </div>
                    <div class="mb-3">
                        <label for="carreraInteresId" class="form-label">Carrera de Interés:</label>
                        <select class="form-select" id="carreraInteresId" name="carreraInteresId" required>
                            <option value="">Seleccione una carrera</option>
                            <%
                                List<Carrera> carreras = (List<Carrera>) request.getAttribute("carreras");
                                if (carreras != null) {
                                    for (Carrera carrera : carreras) {
                                        String selected = carrera.getIdCarrera() == (request.getParameter("carreraInteresId") != null ? Integer.parseInt(request.getParameter("carreraInteresId")) : 0) ? "selected" : "";
                                        out.println("<option value=\"" + carrera.getIdCarrera() + "\" " + selected + ">" + carrera.getNombreCarrera() + "</option>");
                                    }
                                } else {
                                    out.println("<option value=\"\">No hay carreras disponibles</option>");
                                }
                            %>
                        </select>
                    </div>
                    <div class="mb-3">
                        <label for="documentosAdjuntosUrl" class="form-label">URL Documentos Adjuntos (opcional):</label>
                        <input type="url" class="form-control" id="documentosAdjuntosUrl" name="documentosAdjuntosUrl" value="${param.documentosAdjuntosUrl}" placeholder="Ej: http://mi-portafolio.com/documentos">
                    </div>
                    <div class="d-grid gap-2">
                        <button type="submit" class="btn btn-success btn-lg">Enviar Postulación</button>
                    </div>
                </form>

                <div class="text-center mt-3">
                    <p>¿Ya te registraste?</p>
                    <a href="${pageContext.request.contextPath}/POSTULATE/seguimientoPostulacion.jsp" class="btn btn-outline-primary">Ir al Seguimiento</a>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        document.querySelector('form').addEventListener('submit', function(event) {
            const dni = document.getElementById('dni').value;
            const telefono = document.getElementById('telefono').value;
            if (dni.length !== 8 || isNaN(dni)) {
                event.preventDefault();
                alert('El DNI debe contener exactamente 8 dígitos numéricos.');
            }
            if (telefono && (telefono.length !== 9 || isNaN(telefono))) {
                event.preventDefault();
                alert('El teléfono debe contener exactamente 9 dígitos numéricos.');
            }
        });
    </script>
</body>
</html>