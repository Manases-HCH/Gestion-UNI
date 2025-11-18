<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Examen de Admisión</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
    <style>
        body {
            background-color: #f8f9fa;
        }
        .question-card {
            margin-bottom: 20px;
        }
        .timer {
            font-size: 1.2rem;
            font-weight: bold;
        }
    </style>
</head>
<body>
<div class="container py-5">
    <div class="row mb-4">
        <div class="col text-center">
            <h1 class="text-primary">Examen de Admisión</h1>
            <p class="text-muted">Responde cuidadosamente todas las preguntas</p>
            <p class="timer text-danger" id="timer">Tiempo restante: 30:00</p>
        </div>
    </div>

    <form action="${pageContext.request.contextPath}/guardarRespuestas" method="post">

        <c:if test="${empty param.id}">
            <div class="alert alert-danger text-center">
                ⚠️ ID del examen no recibido. Asegúrate de ingresar desde el botón correcto.
            </div>
        </c:if>

        <input type="hidden" name="idExamenAdmision" value="${param.id}"/>

        <!-- Pregunta 1 -->
        <div class="card question-card">
            <div class="card-header">1. ¿Cuál es la capital de Perú?</div>
            <div class="card-body">
                <div class="form-check">
                    <input class="form-check-input" type="radio" name="pregunta1" id="p1_1" value="Lima" required>
                    <label class="form-check-label" for="p1_1">Lima</label>
                </div>
                <div class="form-check">
                    <input class="form-check-input" type="radio" name="pregunta1" id="p1_2" value="Cusco">
                    <label class="form-check-label" for="p1_2">Cusco</label>
                </div>
                <div class="form-check">
                    <input class="form-check-input" type="radio" name="pregunta1" id="p1_3" value="Arequipa">
                    <label class="form-check-label" for="p1_3">Arequipa</label>
                </div>
                <div class="form-check">
                    <input class="form-check-input" type="radio" name="pregunta1" id="p1_4" value="Trujillo">
                    <label class="form-check-label" for="p1_4">Trujillo</label>
                </div>
            </div>
        </div>

        <!-- Pregunta 2 -->
        <div class="card question-card">
            <div class="card-header">2. ¿Cuántos lados tiene un triángulo?</div>
            <div class="card-body">
                <div class="form-check">
                    <input class="form-check-input" type="radio" name="pregunta2" id="p2_1" value="3" required>
                    <label class="form-check-label" for="p2_1">3</label>
                </div>
                <div class="form-check">
                    <input class="form-check-input" type="radio" name="pregunta2" id="p2_2" value="4">
                    <label class="form-check-label" for="p2_2">4</label>
                </div>
                <div class="form-check">
                    <input class="form-check-input" type="radio" name="pregunta2" id="p2_3" value="5">
                    <label class="form-check-label" for="p2_3">5</label>
                </div>
                <div class="form-check">
                    <input class="form-check-input" type="radio" name="pregunta2" id="p2_4" value="6">
                    <label class="form-check-label" for="p2_4">6</label>
                </div>
            </div>
        </div>

        <!-- Pregunta 3 -->
        <div class="card question-card">
            <div class="card-header">3. ¿Cuál es el elemento químico más abundante en la atmósfera terrestre?</div>
            <div class="card-body">
                <div class="form-check">
                    <input class="form-check-input" type="radio" name="pregunta3" id="p3_1" value="Nitrógeno" required>
                    <label class="form-check-label" for="p3_1">Nitrógeno</label>
                </div>
                <div class="form-check">
                    <input class="form-check-input" type="radio" name="pregunta3" id="p3_2" value="Oxígeno">
                    <label class="form-check-label" for="p3_2">Oxígeno</label>
                </div>
                <div class="form-check">
                    <input class="form-check-input" type="radio" name="pregunta3" id="p3_3" value="Argón">
                    <label class="form-check-label" for="p3_3">Argón</label>
                </div>
                <div class="form-check">
                    <input class="form-check-input" type="radio" name="pregunta3" id="p3_4" value="Dióxido de carbono">
                    <label class="form-check-label" for="p3_4">Dióxido de carbono</label>
                </div>
            </div>
        </div>

        <!-- Pregunta 4 -->
        <div class="card question-card">
            <div class="card-header">4. ¿Quién escribió "Don Quijote de la Mancha"?</div>
            <div class="card-body">
                <div class="form-check">
                    <input class="form-check-input" type="radio" name="pregunta4" id="p4_1" value="Miguel de Cervantes" required>
                    <label class="form-check-label" for="p4_1">Miguel de Cervantes</label>
                </div>
                <div class="form-check">
                    <input class="form-check-input" type="radio" name="pregunta4" id="p4_2" value="Gabriel García Márquez">
                    <label class="form-check-label" for="p4_2">Gabriel García Márquez</label>
                </div>
                <div class="form-check">
                    <input class="form-check-input" type="radio" name="pregunta4" id="p4_3" value="Jorge Luis Borges">
                    <label class="form-check-label" for="p4_3">Jorge Luis Borges</label>
                </div>
                <div class="form-check">
                    <input class="form-check-input" type="radio" name="pregunta4" id="p4_4" value="Mario Vargas Llosa">
                    <label class="form-check-label" for="p4_4">Mario Vargas Llosa</label>
                </div>
            </div>
        </div>

        <!-- Pregunta 5 -->
        <div class="card question-card">
            <div class="card-header">5. ¿Qué planeta es conocido como el "Planeta Rojo"?</div>
            <div class="card-body">
                <div class="form-check">
                    <input class="form-check-input" type="radio" name="pregunta5" id="p5_1" value="Marte" required>
                    <label class="form-check-label" for="p5_1">Marte</label>
                </div>
                <div class="form-check">
                    <input class="form-check-input" type="radio" name="pregunta5" id="p5_2" value="Júpiter">
                    <label class="form-check-label" for="p5_2">Júpiter</label>
                </div>
                <div class="form-check">
                    <input class="form-check-input" type="radio" name="pregunta5" id="p5_3" value="Venus">
                    <label class="form-check-label" for="p5_3">Venus</label>
                </div>
                <div class="form-check">
                    <input class="form-check-input" type="radio" name="pregunta5" id="p5_4" value="Mercurio">
                    <label class="form-check-label" for="p5_4">Mercurio</label>
                </div>
            </div>
        </div>

        <!-- Pregunta 6 -->
        <div class="card question-card">
            <div class="card-header">6. ¿Cuál es el resultado de 5 + 3 * 2?</div>
            <div class="card-body">
                <div class="form-check">
                    <input class="form-check-input" type="radio" name="pregunta6" id="p6_1" value="11" required>
                    <label class="form-check-label" for="p6_1">11</label>
                </div>
                <div class="form-check">
                    <input class="form-check-input" type="radio" name="pregunta6" id="p6_2" value="16">
                    <label class="form-check-label" for="p6_2">16</label>
                </div>
                <div class="form-check">
                    <input class="form-check-input" type="radio" name="pregunta6" id="p6_3" value="13">
                    <label class="form-check-label" for="p6_3">13</label>
                </div>
                <div class="form-check">
                    <input class="form-check-input" type="radio" name="pregunta6" id="p6_4" value="8">
                    <label class="form-check-label" for="p6_4">8</label>
                </div>
            </div>
        </div>

        <!-- Pregunta 7 -->
        <div class="card question-card">
            <div class="card-header">7. ¿En qué continente se encuentra el desierto del Sahara?</div>
            <div class="card-body">
                <div class="form-check">
                    <input class="form-check-input" type="radio" name="pregunta7" id="p7_1" value="África" required>
                    <label class="form-check-label" for="p7_1">África</label>
                </div>
                <div class="form-check">
                    <input class="form-check-input" type="radio" name="pregunta7" id="p7_2" value="Asia">
                    <label class="form-check-label" for="p7_2">Asia</label>
                </div>
                <div class="form-check">
                    <input class="form-check-input" type="radio" name="pregunta7" id="p7_3" value="Australia">
                    <label class="form-check-label" for="p7_3">Australia</label>
                </div>
                <div class="form-check">
                    <input class="form-check-input" type="radio" name="pregunta7" id="p7_4" value="América">
                    <label class="form-check-label" for="p7_4">América</label>
                </div>
            </div>
        </div>

        <!-- Pregunta 8 -->
        <div class="card question-card">
            <div class="card-header">8. ¿Cuál es el hueso más largo del cuerpo humano?</div>
            <div class="card-body">
                <div class="form-check">
                    <input class="form-check-input" type="radio" name="pregunta8" id="p8_1" value="Fémur" required>
                    <label class="form-check-label" for="p8_1">Fémur</label>
                </div>
                <div class="form-check">
                    <input class="form-check-input" type="radio" name="pregunta8" id="p8_2" value="Húmero">
                    <label class="form-check-label" for="p8_2">Húmero</label>
                </div>
                <div class="form-check">
                    <input class="form-check-input" type="radio" name="pregunta8" id="p8_3" value="Tibia">
                    <label class="form-check-label" for="p8_3">Tibia</label>
                </div>
                <div class="form-check">
                    <input class="form-check-input" type="radio" name="pregunta8" id="p8_4" value="Radio">
                    <label class="form-check-label" for="p8_4">Radio</label>
                </div>
            </div>
        </div>

        <!-- Pregunta 9 -->
        <div class="card question-card">
            <div class="card-header">9. Si todos los gatos son animales y Félix es un gato, ¿Félix es un animal?</div>
            <div class="card-body">
                <div class="form-check">
                    <input class="form-check-input" type="radio" name="pregunta9" id="p9_1" value="Sí" required>
                    <label class="form-check-label" for="p9_1">Sí</label>
                </div>
                <div class="form-check">
                    <input class="form-check-input" type="radio" name="pregunta9" id="p9_2" value="No">
                    <label class="form-check-label" for="p9_2">No</label>
                </div>
                <div class="form-check">
                    <input class="form-check-input" type="radio" name="pregunta9" id="p9_3" value="Tal vez">
                    <label class="form-check-label" for="p9_3">Tal vez</label>
                </div>
                <div class="form-check">
                    <input class="form-check-input" type="radio" name="pregunta9" id="p9_4" value="No aplica">
                    <label class="form-check-label" for="p9_4">No aplica</label>
                </div>
            </div>
        </div>

        <!-- Pregunta 10 -->
        <div class="card question-card">
            <div class="card-header">10. ¿Qué significan las siglas "ONU"?</div>
            <div class="card-body">
                <div class="form-check">
                    <input class="form-check-input" type="radio" name="pregunta10" id="p10_1" value="Organización de las Naciones Unidas" required>
                    <label class="form-check-label" for="p10_1">Organización de las Naciones Unidas</label>
                </div>
                <div class="form-check">
                    <input class="form-check-input" type="radio" name="pregunta10" id="p10_2" value="Organización Nacional de Unidades">
                    <label class="form-check-label" for="p10_2">Organización Nacional de Unidades</label>
                </div>
                <div class="form-check">
                    <input class="form-check-input" type="radio" name="pregunta10" id="p10_3" value="Oficina de Negocios Unidos">
                    <label class="form-check-label" for="p10_3">Oficina de Negocios Unidos</label>
                </div>
                <div class="form-check">
                    <input class="form-check-input" type="radio" name="pregunta10" id="p10_4" value="Organización de Naciones Urbanas">
                    <label class="form-check-label" for="p10_4">Organización de Naciones Urbanas</label>
                </div>
            </div>
        </div>

        <div class="text-center mt-4">
            <button type="submit" class="btn btn-success btn-lg">Enviar Examen</button>
        </div>
    </form>
</div>

<script>
    // Temporizador simple 30 minutos
    let timer = 30 * 60;
    const timerElement = document.getElementById("timer");

    const interval = setInterval(() => {
        const minutes = Math.floor(timer / 60);
        const seconds = timer % 60;
        timerElement.textContent = `Tiempo restante: ${minutes}:${seconds < 10 ? '0' + seconds : seconds}`;

        if (timer <= 0) {
            clearInterval(interval);
            document.querySelector("form").submit();
        }
        timer--;
    }, 1000);
</script>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>