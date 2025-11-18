<%@ page contentType="text/html;charset=UTF-8" language="java" session="true" %>
<%
    String ultimaRutaSegura = (String) session.getAttribute("ultimaRutaSegura");

    if (ultimaRutaSegura == null || ultimaRutaSegura.isBlank()) {
        ultimaRutaSegura = request.getContextPath() + "/Plataforma.jsp";
    } else {
        ultimaRutaSegura = request.getContextPath() + ultimaRutaSegura;
    }
%>
<html>
<head>
    <title>Acceso Denegado</title>
</head>
<body style="text-align:center; margin-top:100px;">
    <h2>⚠ Acceso Denegado</h2>
    <p>No tienes permiso para acceder a esta sección.</p>

    <!-- ✅ Botón que regresa a la última página válida -->
    <button onclick="window.location.href='<%= ultimaRutaSegura %>'">
        ⬅ Regresar
    </button>
</body>
</html>