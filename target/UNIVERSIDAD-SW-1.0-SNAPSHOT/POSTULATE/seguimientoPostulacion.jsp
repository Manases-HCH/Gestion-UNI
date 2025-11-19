<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="es">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Seguimiento de Postulación</title>
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
    </head>
    <body class="bg-light">
        <div class="container mt-5">
            <div class="card shadow">
                <div class="card-header bg-primary text-white text-center">
                    <h2 class="mb-0">Seguimiento de Postulación</h2>
                </div>
                <div class="card-body">
                    <form action="${pageContext.request.contextPath}/seguimientoPostulacion" method="get" class="mb-4">
                        <div class="input-group">
                            <input type="text" class="form-control form-control-lg" placeholder="Ingresa tu DNI" name="dni" value="${param.dni}" required>
                            <button class="btn btn-primary btn-lg" type="submit">Consultar</button>
                        </div>
                    </form>

                    <c:if test="${not empty error}">
                        <div class="alert alert-danger text-center">${error}</div>
                    </c:if>

                    <c:if test="${not empty postulacion}">
                        <div class="alert alert-info">
                            <h4 class="text-center">Estado de tu Postulación</h4>
                            <p><strong>DNI:</strong> ${postulacion.dni}</p>
                            <p><strong>Nombre:</strong> ${postulacion.nombreCompleto}</p>
                            <p><strong>Carrera:</strong> ${postulacion.carreraInteres.nombreCarrera}</p>
                            <p><strong>Estado:</strong>
                                <span class="badge 
                                      <c:choose>
                                          <c:when test="${postulacion.estadoPostulacion == 'aprobada'}">bg-success</c:when>
                                          <c:when test="${postulacion.estadoPostulacion == 'rechazada'}">bg-danger</c:when>
                                          <c:otherwise>bg-warning text-dark</c:otherwise>
                                      </c:choose>">
                                    ${postulacion.estadoPostulacion}
                                </span>
                            </p>

                            <c:if test="${not empty postulacion.observaciones}">
                                <p><strong>Observaciones:</strong> ${postulacion.observaciones}</p>
                            </c:if>
                            <p class="text-muted text-center">
                                Estado: ${postulacion.estadoPostulacion} | examenId: ${examenId}
                            </p>

                            <!-- Botón solo si la postulación fue aprobada -->
                            <c:if test="${postulacion.estadoPostulacion == 'aprobada' && not empty examenId}">
                                <div class="mt-4 text-center">
                                    <a href="${pageContext.request.contextPath}/POSTULATE/examen.jsp?id=${examenId}" 
                                       class="btn btn-success btn-lg">
                                        Ir al Examen de Admisión
                                    </a>
                                </div>
                            </c:if>


                        </div>
                    </c:if>
                </div>
            </div>
        </div>
    </body>
</html>
