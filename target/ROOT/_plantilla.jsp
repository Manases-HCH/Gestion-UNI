<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html>
<head>
  <title>Plataforma</title>
  <link href="estilos/bootstrap.min.css" rel="stylesheet"/>
  <link href="estilos/datatables.min.css" rel="stylesheet"/>
  <script src="estilos/jquery-3.7.1.min.js"></script>
  <script src="estilos/datatables.min.js"></script>
</head>
<body>
  <div class="container-fluid">
    <div class="row">
      <!-- Sidebar -->
      <jsp:include page="menu.jsp" />

      <!-- Contenido dinámico -->
      <div class="col-md-10 mt-3">
        <jsp:include page="<%= request.getAttribute(\"contenido\") %>" />
      </div>
    </div>
  </div>
</body>
</html>
