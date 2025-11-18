<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html>
<head>
    <title>Resultado de Postulación</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 50px; }
        .result-container { max-width: 600px; margin: auto; padding: 20px; border: 1px solid #ccc; border-radius: 5px; }
        .success { color: green; }
        .error { color: red; }
    </style>
</head>
<body>
<div class="result-container">
    <h2>Resultado de la Postulación</h2>
    <p class="${success ? 'success' : 'error'}">${message}</p>
    <a href="postulacion">Volver al formulario</a>
</div>
</body>
</html>
