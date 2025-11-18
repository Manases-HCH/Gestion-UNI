<%-- 
    Document   : prueba
    Created on : 19 abr. 2025, 5:41:12 p. m.
    Author     : Estudiante
--%>

<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>JSP Page</title>
    </head>
    <body>
        <h1>Prueba de conexion</h1>
        <jsp:useBean id="conexion" class="pe.edu.util.Conexion" scope="session" ></jsp:useBean>
        <jsp:scriptlet>
            int log = 0;
            log = conexion.pruebaConexion();
        </jsp:scriptlet>
        Estado de conexion : <%= log %>
    </body>
</html>
