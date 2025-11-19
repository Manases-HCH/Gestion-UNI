<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Crear Cuenta de Acceso</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-light">
<div class="container mt-5">
    <div class="row justify-content-center">
        <div class="col-md-6">
            <div class="card shadow-lg">
                <div class="card-header text-center bg-primary text-white">
                    <h3>Crear Cuenta de Acceso</h3>
                </div>
                <div class="card-body">
                    <%
                        String mensaje = "";
                        String error = "";
                        String email = "";
                        String password = "";
                        String confirmPassword = "";

                        // Procesar el formulario si se envía
                        if ("POST".equalsIgnoreCase(request.getMethod())) {
                            email = request.getParameter("email");
                            password = request.getParameter("password");
                            confirmPassword = request.getParameter("confirmPassword");

                            // Validaciones
                            if (email == null || email.trim().isEmpty() ||
                                password == null || password.trim().isEmpty() ||
                                confirmPassword == null || confirmPassword.trim().isEmpty()) {
                                error = "Todos los campos son obligatorios.";
                            } else if (!password.equals(confirmPassword)) {
                                error = "Las contraseñas no coinciden.";
                            } else {
                                // Verificar si el correo existe
                                boolean correoExiste = false;
                                String url = "jdbc:mysql://localhost:3306/bd-uni";
                                String user = "root";
                                String pass = "";
                                try (Connection conn = DriverManager.getConnection(url, user, pass)) {
                                    String sqlCheck = "SELECT COUNT(*) FROM usuarios WHERE correo = ?";
                                    try (PreparedStatement psCheck = conn.prepareStatement(sqlCheck)) {
                                        psCheck.setString(1, email);
                                        try (ResultSet rs = psCheck.executeQuery()) {
                                            if (rs.next() && rs.getInt(1) > 0) {
                                                correoExiste = true;
                                            }
                                        }
                                    }
                                } catch (SQLException e) {
                                    error = "Error al verificar el correo: " + e.getMessage();
                                }

                                if (correoExiste) {
                                    error = "Ya existe una cuenta con ese correo.";
                                } else {
                                    // Insertar nuevo usuario
                                    try (Connection conn = DriverManager.getConnection(url, user, pass)) {
                                        String sqlInsert = "INSERT INTO usuarios (correo, password, rol) VALUES (?, ?, ?)";
                                        try (PreparedStatement psInsert = conn.prepareStatement(sqlInsert)) {
                                            psInsert.setString(1, email);
                                            psInsert.setString(2, password); // En producción, encriptar
                                            psInsert.setString(3, "alumno");
                                            int filasAfectadas = psInsert.executeUpdate();
                                            if (filasAfectadas > 0) {
                                                mensaje = "¡Cuenta creada exitosamente!";
                                            } else {
                                                error = "Error al registrar la cuenta.";
                                            }
                                        }
                                    } catch (SQLException e) {
                                        error = "Error al registrar: " + e.getMessage();
                                    }
                                }
                            }
                        }
                    %>

                    <form action="${pageContext.request.contextPath}/POSTULATE/crearCuenta.jsp" method="post">
                        <div class="mb-3">
                            <label class="form-label">Correo institucional:</label>
                            <div class="input-group">
                                <input type="text" class="form-control" name="correoParte" id="correoParte" value="<%= email != null ? email.split("@")[0] : "" %>" required placeholder="Ingresa tu nombre o identificador" aria-label="Parte inicial del correo">
                                <span class="input-group-text" id="dominio">@edu.pe</span>
                            </div>
                            <small class="form-text text-muted">Ingresa la parte inicial (ejemplo: juan123). El dominio @edu.pe se agregará automáticamente.</small>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Nueva Contraseña:</label>
                            <input type="password" class="form-control" name="password" value="<%= password != null ? password : "" %>" required minlength="6">
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Confirmar Contraseña:</label>
                            <input type="password" class="form-control" name="confirmPassword" value="<%= confirmPassword != null ? confirmPassword : "" %>" required minlength="6">
                        </div>

                        <div class="d-grid">
                            <button type="submit" class="btn btn-success">Registrar Cuenta</button>
                        </div>
                    </form>

                    <% if (!mensaje.isEmpty()) { %>
                        <div class="alert alert-success mt-3 text-center"><%= mensaje %></div>
                        <div class="d-grid mt-3">
                            <a href="${pageContext.request.contextPath}/Plataforma.jsp" class="btn btn-primary">Ir a Plataforma</a>
                        </div>
                    <% } %>
                    <% if (!error.isEmpty()) { %>
                        <div class="alert alert-danger mt-3 text-center"><%= error %></div>
                    <% } %>
                </div>
            </div>
        </div>
    </div>
</div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script>
    document.getElementById('correoParte').addEventListener('input', function(e) {
        this.value = this.value.replace(/[^a-zA-Z0-9\-_]/g, '').toLowerCase();
        if (this.value.length > 20) {
            this.value = this.value.slice(0, 20);
        }
    });

    document.querySelector('form').addEventListener('submit', function(e) {
        const correoParte = document.getElementById('correoParte').value;
        if (correoParte.trim() === '') {
            e.preventDefault();
            alert('Por favor, ingresa la parte inicial del correo.');
            return;
        }
        const correoCompleto = document.createElement('input');
        correoCompleto.type = 'hidden';
        correoCompleto.name = 'email';
        correoCompleto.value = correoParte + '@edu.pe';
        this.appendChild(correoCompleto);
    });
</script>
</body>
</html>