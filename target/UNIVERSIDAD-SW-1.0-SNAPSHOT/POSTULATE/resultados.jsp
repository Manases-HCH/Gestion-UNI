<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %> <!-- ESTA LÍNEA ES CLAVE -->
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Resultado del Examen</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-light">
<div class="container mt-5">
    <div class="row justify-content-center">
        <div class="col-md-8">
            <div class="card shadow-lg">
                <div class="card-body text-center">

                    <c:choose>
                        <c:when test="${param.estado == 'aprobado'}">
                            <h2 class="text-success">🎉 ¡Felicidades!</h2>
                            <p class="fs-5">Has aprobado el examen de admisión.</p>
                            <p>En breve recibirás un correo institucional. Ahora debes crear tu contraseña de acceso.</p>
                            <a href="${pageContext.request.contextPath}/POSTULATE/crearCuenta.jsp" class="btn btn-primary mt-3">
                                Crear mi cuenta de acceso
                            </a>
                        </c:when>

                        <c:when test="${param.estado == 'desaprobado'}">
                            <h2 class="text-danger">😔 Lo sentimos</h2>
                            <p class="fs-5">No alcanzaste el puntaje mínimo para aprobar el examen.</p>
                            <p>Te animamos a prepararte y volver a intentarlo en el próximo proceso de admisión.</p>
                            <a href="${pageContext.request.contextPath}/index.jsp" class="btn btn-secondary mt-3">
                                Volver al inicio
                            </a>
                        </c:when>

                        <c:otherwise>
                            <h4 class="text-warning">⚠️ Resultado no disponible</h4>
                            <p>No se pudo determinar el estado del examen. Por favor, vuelve a intentarlo desde el inicio.</p>
                            <a href="${pageContext.request.contextPath}/index.jsp" class="btn btn-warning mt-3">
                                Ir al inicio
                            </a>
                        </c:otherwise>
                    </c:choose>

                </div>
            </div>
        </div>
    </div>
</div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>

