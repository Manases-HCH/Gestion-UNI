<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.*"%>
<%
    String loginError = (String) session.getAttribute("loginError");
    if (loginError != null) {
        session.removeAttribute("loginError");
    }
%>
<!DOCTYPE html>
<html>
    <head>
        <meta charset="UTF-8">
        <title>UGIC PORTAL</title>
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous">
        <link href="https://fonts.googleapis.com/css2?family=Montserrat:wght@400;700;900&family=Open+Sans:wght@400;600&display=swap" rel="stylesheet">
        <link rel="stylesheet" href="https://pro.fontawesome.com/releases/v5.10.0/css/all.css" />
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.5/dist/css/bootstrap.min.css" rel="stylesheet">
        <style>
            .navbar-brand img {
                max-height: 2.5rem;
                margin-right: 10px;
            }
        </style>
        <style>
    /* Base Fade-in animation - good as is */
    .fade-in {
        opacity: 0;
        animation: fadeInAnimation 1.5s ease-in forwards;
    }

    @keyframes fadeInAnimation {
        to {
            opacity: 1;
        }
    }

    /* Variables CSS con tonos plomo elegantes - Added a subtle hover color */
    :root {
        --primary-color: #708090; /* Plomo slate gray */
        --secondary-color: #2F4F4F; /* Plomo oscuro dark slate gray */
        --accent-color: #20B2AA; /* Verde agua para acentos */
        --light-gray: #B0C4DE; /* Plomo claro light steel blue */
        --text-color: #ffffff; /* Texto blanco principal */
        --text-dark: #2F4F4F; /* Texto oscuro para contraste */
        --gradient-bg: linear-gradient(135deg, #708090 0%, #2F4F4F 50%, #36454F 100%); /* Gradiente plomo */
        --card-bg: rgba(255, 255, 255, 0.15); /* Fondo semi-transparente para tarjetas */
        --hover-shadow: 0 20px 40px rgba(112, 128, 144, 0.4); /* Sombra plomo suave */
        --hover-color: #36454F; /* New: Slightly darker shade for interactive elements on hover */
    }

    /* General Body Styling - Enhanced scroll behavior */
    body {
        font-family: 'Open Sans', sans-serif;
        color: var(--text-color);
        line-height: 1.6;
        background: var(--gradient-bg);
        margin: 0;
        padding: 0;
        overflow-x: hidden;
        min-height: 100vh;
        /* Added smooth scrolling for better user experience when navigating sections */
        scroll-behavior: smooth;
    }

    /* Headings - Consistent, professional font choices */
    h1, h2, h3, h4, h5, h6 {
        font-family: 'Montserrat', sans-serif;
        font-weight: 700;
        color: var(--text-color);
    }
    
    /* Section Titles - Refined shadow and subtle text glow */
    .section-title {
        background: linear-gradient(135deg, var(--primary-color) 0%, var(--secondary-color) 100%);
        color: var(--text-color);
        font-family: 'Montserrat', sans-serif;
        font-weight: 900;
        font-size: clamp(2.5rem, 5vw, 4.5rem);
        padding: 40px 60px;
        margin-bottom: 0;
        text-align: left;
        /* Enhanced shadow for more depth */
        box-shadow: 0 10px 30px rgba(0, 0, 0, 0.3);
        position: relative;
        overflow: hidden;
        /* Added a slight border-radius to the top corners for a softer look */
        border-top-left-radius: 10px;
        border-top-right-radius: 10px;
    }

    /* Shimmer effect for titles - good as is */
    .section-title::before {
        content: '';
        position: absolute;
        top: 0;
        left: -100%;
        width: 100%;
        height: 100%;
        background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.1), transparent);
        animation: shimmer 3s infinite;
    }

    @keyframes shimmer {
        0% { left: -100%; }
        50% { left: 100%; }
        100% { left: 100%; }
    }

    /* Title paragraph - Subtle text glow */
    .section-title p {
        margin: 0;
        margin-left: 50px;
        /* Increased text shadow for better legibility and a slight glow effect */
        text-shadow: 0 0 10px rgba(255, 255, 255, 0.7), 0 0 20px rgba(255, 255, 255, 0.5);
    }

    /* Section Container - Adjusted margin for better spacing */
    .section-container {
        max-width: 1200px;
        /* Slightly more generous top margin for separation */
        margin: 100px auto; 
        padding: 0 30px;
    }

    /* Hero Overlay Text - Enhanced blur and border */
    .hero-overlay-text {
        z-index: 10;
        background: rgba(112, 128, 144, 0.95); /* Slightly less transparent */
        backdrop-filter: blur(12px); /* Increased blur for a softer effect */
        -webkit-backdrop-filter: blur(12px);
        padding: 3rem 4rem;
        border-radius: 20px;
        animation: fadeInScale 2s ease-out forwards;
        text-shadow: 2px 2px 8px rgba(0, 0, 0, 0.4);
        border: 2px solid rgba(255, 255, 255, 0.3); /* Slightly more prominent border */
    }

    /* Fade-in Scale for hero - good as is */
    @keyframes fadeInScale {
        from {
            opacity: 0;
            transform: translate(-50%, -50%) scale(0.8);
        }
        to {
            opacity: 1;
            transform: translate(-50%, -50%) scale(1);
        }
    }

    /* Carousel Images - Enhanced visual depth and interaction */
    .carousel-item img {
        height: 700px;
        object-fit: cover;
        /* More dynamic filter effect on hover */
        filter: brightness(0.7) saturate(1.1);
        transition: filter 0.6s ease-in-out, transform 0.6s ease-in-out; /* Added transform for hover */
    }

    .carousel-item img:hover {
        filter: brightness(0.9) saturate(1.3); /* Brighter and more saturated on hover */
        transform: scale(1.02); /* Slight zoom on hover */
    }

    /* Carousel Indicators - Refined appearance */
    .carousel-indicators [data-bs-target] {
        background-color: var(--light-gray);
        opacity: 0.7;
        width: 15px;
        height: 15px;
        border-radius: 50%;
        transition: all 0.4s ease; /* Slightly longer transition */
        /* Added a subtle border to indicators */
        border: 1px solid rgba(255, 255, 255, 0.5);
    }

    .carousel-indicators .active {
        opacity: 1;
        background-color: var(--accent-color);
        transform: scale(1.2);
        /* Added a glow effect to active indicator */
        box-shadow: 0 0 15px var(--accent-color);
    }

    /* About Section - Enhanced background and border */
    .about-section {
        display: flex;
        flex-wrap: wrap;
        justify-content: center;
        align-items: flex-start;
        gap: 60px;
        background: var(--card-bg);
        backdrop-filter: blur(10px);
        border-radius: 25px;
        padding: 40px;
        /* More prominent border for better definition */
        border: 1px solid rgba(255, 255, 255, 0.4);
        /* Added a subtle internal shadow for depth */
        box-shadow: inset 0 0 20px rgba(0, 0, 0, 0.1);
    }

    .about-section .text-content {
        flex: 1 1 480px;
        font-size: 1.2rem;
        padding-top: 30px;
        color: var(--text-color);
        /* Added a subtle text shadow for better readability on varied backgrounds */
        text-shadow: 1px 1px 3px rgba(0, 0, 0, 0.2);
    }

    .about-section .image-content {
        flex: 1 1 480px;
        text-align: center;
    }

    .about-section img {
        max-width: 100%;
        height: auto;
        border-radius: 25px;
        /* Slightly more pronounced shadow */
        box-shadow: 0 20px 45px rgba(112, 128, 144, 0.3);
        transition: transform 0.5s ease, box-shadow 0.5s ease, border 0.5s ease; /* Longer transition */
        border: 3px solid rgba(255, 255, 255, 0.4); /* Slightly stronger border */
    }

    .about-section img:hover {
        transform: scale(1.06) rotate(1deg); /* Slightly more pronounced scale */
        box-shadow: 0 25px 50px rgba(112, 128, 144, 0.5); /* More intense shadow on hover */
        border-color: var(--accent-color); /* Highlight border on hover */
    }

    /* Mission & Vision Cards - Enhanced hover effects and subtle glow */
    .mv-container {
        display: flex;
        flex-wrap: wrap;
        justify-content: center;
        gap: 50px;
        margin: 80px auto;
        padding: 0 30px;
    }

    .mv-card {
        flex: 1 1 45%;
        min-width: 320px;
        background: var(--card-bg);
        backdrop-filter: blur(15px);
        border: 2px solid rgba(255, 255, 255, 0.3);
        border-radius: 25px;
        padding: 40px;
        box-shadow: var(--hover-shadow);
        transition: all 0.5s ease; /* Longer transition */
        position: relative;
        overflow: hidden;
        /* Added a subtle glow on the card itself */
        box-shadow: 0 0 15px rgba(112, 128, 144, 0.3);
    }

    /* Top border gradient - good as is */
    .mv-card::before {
        content: '';
        position: absolute;
        top: 0;
        left: 0;
        right: 0;
        height: 5px;
        background: linear-gradient(90deg, var(--primary-color), var(--accent-color));
    }

    .mv-card:hover {
        transform: translateY(-20px) scale(1.03); /* More pronounced lift and scale */
        box-shadow: 0 30px 60px rgba(112, 128, 144, 0.5); /* More intense shadow on hover */
        border-color: var(--accent-color); /* Border highlights with accent color */
    }

    .mv-card h2 {
        font-size: 2.2rem;
        color: var(--text-color);
        margin-bottom: 20px;
        text-align: center;
        /* Enhanced text shadow for a clearer heading */
        text-shadow: 0 0 8px rgba(255, 255, 255, 0.6), 0 0 15px rgba(255, 255, 255, 0.4);
    }

    .mv-card p {
        font-size: 1.1rem;
        line-height: 1.8;
        color: var(--text-color);
        /* Subtle text shadow for paragraph */
        text-shadow: 1px 1px 2px rgba(0, 0, 0, 0.1);
    }

    /* Values Grid - Refined layout and interaction */
    .values-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
        gap: 40px;
        margin-top: 60px;
    }

    .value-card {
        background: var(--card-bg);
        backdrop-filter: blur(15px);
        border: 2px solid rgba(255, 255, 255, 0.3);
        border-radius: 20px;
        padding: 30px;
        box-shadow: 0 10px 25px rgba(112, 128, 144, 0.2);
        transition: all 0.4s ease;
        text-align: center;
        position: relative;
        overflow: hidden;
    }

    /* Shimmer on hover for value cards - good as is */
    .value-card::after {
        content: '';
        position: absolute;
        top: -50%;
        left: -50%;
        width: 200%;
        height: 200%;
        background: linear-gradient(45deg, transparent, rgba(255, 255, 255, 0.1), transparent);
        transform: rotate(45deg);
        opacity: 0;
        transition: opacity 0.3s ease;
    }

    .value-card:hover::after {
        opacity: 1;
        animation: rotate 1.5s ease-in-out;
    }

    @keyframes rotate {
        0% { transform: rotate(45deg) translate(-100%, -100%); }
        100% { transform: rotate(45deg) translate(100%, 100%); }
    }

    .value-card:hover {
        transform: translateY(-15px); /* Slightly more lift */
        box-shadow: var(--hover-shadow);
        border-color: var(--accent-color); /* Highlight border on hover */
    }

    .value-card h3 {
        color: var(--text-color);
        margin-bottom: 15px;
        font-size: 1.8rem;
        /* Stronger text shadow for headings */
        text-shadow: 0 0 5px rgba(255, 255, 255, 0.5), 0 0 10px rgba(255, 255, 255, 0.3);
    }

    .value-card p {
        font-size: 1.05rem;
        color: var(--text-color);
    }

    /* Icons in cards - More vibrant on hover */
    .value-card i {
        font-size: 3.8rem; /* Slightly larger icons */
        color: var(--light-gray);
        display: block;
        margin-bottom: 20px;
        transition: all 0.4s ease; /* Longer transition */
        text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.3);
    }

    .value-card:hover i {
        transform: scale(1.25) rotate(10deg); /* More pronounced icon animation */
        color: var(--accent-color);
        /* Added a subtle glow to the icon on hover */
        text-shadow: 0 0 15px var(--accent-color), 0 0 25px var(--accent-color);
    }

    /* History Section - Enhanced imagery and layout */
    .history-section {
        display: flex;
        flex-wrap: wrap;
        justify-content: center;
        align-items: flex-start;
        gap: 60px;
        background: var(--card-bg);
        backdrop-filter: blur(10px);
        border-radius: 25px;
        padding: 40px;
        border: 1px solid rgba(255, 255, 255, 0.2);
        /* Added a subtle border to the section for definition */
        box-shadow: inset 0 0 20px rgba(0, 0, 0, 0.1);
    }

    .history-section .text-content {
        flex: 1 1 480px;
        font-size: 1.18rem;
        color: var(--text-color);
        text-shadow: 1px 1px 2px rgba(0, 0, 0, 0.1); /* Consistent text shadow */
    }

    .history-collage {
        flex: 1 1 480px;
        display: grid;
        grid-template-columns: repeat(2, 1fr);
        gap: 20px;
    }

    .history-collage img {
        width: 100%;
        height: 250px;
        object-fit: cover;
        border-radius: 20px;
        box-shadow: 0 10px 25px rgba(112, 128, 144, 0.3);
        transition: all 0.5s ease; /* Longer transition */
        border: 2px solid rgba(255, 255, 255, 0.3);
    }

    .history-collage img:hover {
        transform: scale(1.07) rotate(-2deg); /* More pronounced scale */
        box-shadow: 0 20px 40px rgba(112, 128, 144, 0.5); /* More intense shadow */
        border-color: var(--accent-color); /* Highlight border on hover */
    }

    .history-collage img:nth-child(3) {
        grid-column: span 2;
        height: 300px;
    }

    /* Premium Authority Cards - Enhanced hover and information presentation */
    .authorities-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
        gap: 50px;
        margin-top: 60px;
    }

    .authority-card {
        background: var(--card-bg);
        backdrop-filter: blur(15px);
        border: 2px solid rgba(255, 255, 255, 0.3);
        border-radius: 25px;
        box-shadow: 0 15px 35px rgba(112, 128, 144, 0.2);
        overflow: hidden;
        text-align: center;
        transition: all 0.5s ease; /* Longer transition */
        position: relative;
        /* Added a subtle initial glow */
        box-shadow: 0 0 10px rgba(112, 128, 144, 0.2);
    }

    /* Top border gradient - good as is */
    .authority-card::before {
        content: '';
        position: absolute;
        top: 0;
        left: 0;
        right: 0;
        height: 5px;
        background: linear-gradient(90deg, var(--primary-color), var(--accent-color));
    }

    .authority-card:hover {
        transform: translateY(-25px); /* More significant lift */
        box-shadow: 0 30px 60px rgba(112, 128, 144, 0.5); /* Stronger shadow on hover */
        border-color: var(--accent-color); /* Highlight border with accent color */
    }

    .authority-card img {
        width: 100%;
        height: 300px;
        object-fit: cover;
        object-position: top center;
        transition: transform 0.5s ease, filter 0.5s ease; /* Longer transition for image */
        filter: brightness(1) saturate(1); /* Reset filter on image for a more natural look, apply only on hover */
    }

    .authority-card:hover img {
        transform: scale(1.12); /* More pronounced zoom */
        filter: brightness(1.2) saturate(1.3); /* Brighter and more saturated on hover */
    }

    .authority-info {
        padding: 25px;
        background: rgba(255, 255, 255, 0.15); /* Slightly less transparent background */
        /* Added a subtle top border to info section */
        border-top: 1px solid rgba(255, 255, 255, 0.1);
    }

    .authority-info h3 {
        font-size: 1.6rem;
        color: var(--text-color);
        margin-bottom: 5px;
        /* Enhanced text shadow for name */
        text-shadow: 0 0 8px rgba(255, 255, 255, 0.6);
    }

    .authority-info p {
        font-size: 1.15rem;
        color: rgba(255, 255, 255, 0.95); /* Slightly more opaque text */
        font-weight: 600;
        /* Added a subtle text shadow for title */
        text-shadow: 1px 1px 2px rgba(0, 0, 0, 0.2);
    }

    /* Responsive Design - Your existing media queries are robust */
    @media (max-width: 992px) {
        .section-title {
            font-size: clamp(2rem, 6vw, 4rem);
            padding: 30px 40px;
        }
        
        .about-section, .history-section {
            padding: 30px;
        }
        
        .carousel-item img {
            height: 550px;
        }
    }

    @media (max-width: 768px) {
        .carousel-item img {
            height: 450px;
        }
        
        .hero-overlay-text {
            padding: 2rem 2rem;
            border-radius: 15px;
        }
        
        .section-title {
            font-size: clamp(1.8rem, 7vw, 3.5rem);
            padding: 20px 25px;
        }
        
        .about-section, .history-section {
            padding: 25px;
            border-radius: 20px;
        }
    }

    @media (max-width: 576px) {
        .hero-overlay-text {
            padding: 1.5rem 1.5rem;
        }
        
        .carousel-item img {
            height: 350px;
        }
        
        .section-title {
            padding: 15px 20px;
        }
        
        .mv-card, .value-card, .authority-card {
            border-radius: 18px;
        }
    }
</style>

    </head>
    <body>
        <!-- Modal de error -->
        <div class="modal fade" id="loginErrorModal" tabindex="-1" aria-labelledby="loginErrorModalLabel" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered">
                <div class="modal-content">
                    <div class="modal-header bg-danger text-white">
                        <h5 class="modal-title" id="loginErrorModalLabel"><i class="fas fa-exclamation-triangle me-2"></i> Error de Inicio de Sesión</h5>
                        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>
                    <div class="modal-body">
                        <p id="loginErrorMessage"></p>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary btn-sm" data-bs-dismiss="modal">Cerrar</button>
                    </div>
                </div>
            </div>
        </div>

        <script>
            document.addEventListener('DOMContentLoaded', function () {
                const error = "<%= loginError != null ? loginError.replaceAll("\"", "\\\\\"") : "" %>";
                if (error && error.trim() !== "") {
                    const loginErrorMessage = document.getElementById('loginErrorMessage');
                    const loginErrorModal = new bootstrap.Modal(document.getElementById('loginErrorModal'));
                    loginErrorMessage.textContent = error;
                    loginErrorModal.show();
                    // Limpiar el atributo de la petición para que no se muestre en futuras cargas
                    // (Esto solo funciona si no hay redirecciones intermedias que conserven la petición)
                    // Una mejor manera es limpiar la sesión en la carga inicial (ver otra opción).
                    // <% request.removeAttribute("error"); %>
                }
            });
        </script>
        <%@include file="modulo.jsp" %>
        <div class="position-relative">
            <div class="position-absolute top-50 start-50 translate-middle text-center text-white hero-overlay-text">
                <h1 class="display-4 fw-bold">Bienvenido al Portal Oficial de la Universidad UGIC</h1>
                <p class="lead d-none d-md-block">Innovación, Excelencia y Compromiso con tu Futuro.</p>
            </div>

            <div id="miCarrusel" class="carousel slide carousel-fade" data-bs-ride="carousel" data-bs-interval="5000"> <div class="carousel-inner">
                    <div class="carousel-item active">
                        <img src="img/imagen1.png" class="d-block w-100" alt="Campus Universitario Moderno">
                    </div>
                    <div class="carousel-item">
                        <img src="img/imagen2.png" class="d-block w-100" alt="Estudiantes Colaborando en Laboratorio">
                    </div>
                    <div class="carousel-item">
                        <img src="img/imagen3.png" class="d-block w-100" alt="Aula con Tecnología Avanzada">
                    </div>
                    <div class="carousel-item">
                        <img src="img/imagen4.png" class="d-block w-100" alt="Áreas Verdes del Campus">
                    </div>
                    <div class="carousel-item">
                        <img src="img/imagen5.png" class="d-block w-100" alt="Actividad Cultural Universitaria">
                    </div>
                </div>
                <button class="carousel-control-prev" type="button" data-bs-target="#miCarrusel" data-bs-slide="prev">
                    <span class="carousel-control-prev-icon" aria-hidden="true"></span>
                    <span class="visually-hidden">Anterior</span>
                </button>
                <button class="carousel-control-next" type="button" data-bs-target="#miCarrusel" data-bs-slide="next">
                    <span class="carousel-control-next-icon" aria-hidden="true"></span>
                    <span class="visually-hidden">Siguiente</span>
                </button>
                <div class="carousel-indicators">
                    <button type="button" data-bs-target="#miCarrusel" data-bs-slide-to="0" class="active" aria-current="true" aria-label="Slide 1"></button>
                    <button type="button" data-bs-target="#miCarrusel" data-bs-slide-to="1" aria-label="Slide 2"></button>
                    <button type="button" data-bs-target="#miCarrusel" data-bs-slide-to="2" aria-label="Slide 3"></button>
                    <button type="button" data-bs-target="#miCarrusel" data-bs-slide-to="3" aria-label="Slide 4"></button>
                    <button type="button" data-bs-target="#miCarrusel" data-bs-slide-to="4" aria-label="Slide 5"></button>
                </div>
            </div>
        </div>

        <section class="section-title">
            <p>SOBRE NOSOTROS</p>
        </section>

        <section class="section-container about-section">
            <div class="text-content">
                <p>La Universidad de Gestión e Innovación del Conocimiento (UGIC) es una institución educativa de nivel superior comprometida con la formación de profesionales íntegros, críticos y creativos. Nuestra propuesta académica se fundamenta en la excelencia, la innovación y el compromiso con la sociedad. En UGIC, promovemos un entorno inclusivo, colaborativo y orientado al desarrollo sostenible y tecnológico.</p>
                <p>Desde nuestra fundación en 2010, nos hemos dedicado a fomentar un ambiente donde el aprendizaje trasciende el aula. Impulsamos la investigación aplicada, el emprendimiento y la conexión con el sector productivo para que nuestros estudiantes desarrollen habilidades relevantes y resuelvan desafíos del mundo real, preparándolos para ser líderes en sus campos.</p>
            </div>
            <div class="image-content">
                <img src="img/imagen7.png" alt="Fachada principal de la Universidad UGIC">
            </div>
        </section>

        <section class="section-title" style="background-color: var(--primary-color);">
            <p>NUESTRA VISIÓN Y MISIÓN</p>
        </section>

        <section class="mv-container">
            <div class="mv-card">
                <h2>Misión</h2>
                <p>Formar profesionales con sólida preparación académica, ética y humanística, capaces de liderar procesos de cambio e innovación en sus comunidades. Fomentamos la investigación, el pensamiento crítico y el compromiso social como pilares fundamentales para contribuir al desarrollo regional, nacional e internacional, impulsando el progreso y la transformación.</p>
            </div>

            <div class="mv-card">
                <h2>Visión</h2>
                <p>Ser reconocida como una universidad líder en educación superior por su excelencia académica, su capacidad innovadora y su impacto positivo en la sociedad, a través de la formación de líderes transformadores y comprometidos con el conocimiento, la equidad y el progreso, forjando el futuro de nuestra región y el mundo.</p>
            </div>
        </section>

        <section class="section-container">
            <h2 class="section-title" style="background-color: transparent; color: var(--secondary-color); text-align: center; box-shadow: none; margin-left: 0;">NUESTROS VALORES</h2>
            <div class="values-grid">
                <div class="value-card" data-icon="&#xf005;">
                    <h3>Excelencia Académica</h3>
                    <p>Nos esforzamos por alcanzar y mantener los más altos estándares en enseñanza, investigación y gestión institucional, buscando la mejora continua en cada aspecto de nuestra labor.</p>
                </div>
                <div class="value-card" data-icon="&#xf0eb;">
                    <h3>Innovación</h3>
                    <p>Promovemos la creatividad, el emprendimiento y la incorporación constante de nuevas ideas y tecnologías que impulsan la transformación social y el avance del conocimiento.</p>
                </div>
                <div class="value-card" data-icon="&#xf530;">
                    <h3>Ética</h3>
                    <p>Actuamos con integridad, transparencia y responsabilidad en todos nuestros procesos y relaciones, fomentando un ambiente de honestidad y respeto mutuo en toda la comunidad universitaria.</p>
                </div>
                <div class="value-card" data-icon="&#xf0c0;">
                    <h3>Compromiso Social</h3>
                    <p>Trabajamos activamente con y para nuestras comunidades, generando un impacto real y sostenible a través de proyectos de extensión, investigación aplicada y voluntariado.</p>
                </div>
                <div class="value-card" data-icon="&#xf52d;">
                    <h3>Diversidad e Inclusión</h3>
                    <p>Valoramos las diferencias individuales y promovemos un entorno respetuoso y equitativo donde todos los miembros de la comunidad universitaria se sientan valorados y puedan desarrollarse plenamente.</p>
                </div>
                <div class="value-card" data-icon="&#xf1ad;">
                    <h3>Liderazgo</h3>
                    <p>Inspiramos y formamos líderes transformadores, capaces de generar un cambio positivo en sus entornos, con una visión clara, determinación y un fuerte sentido de propósito.</p>
                </div>
            </div>
        </section>

        <section class="section-title" style="background-color: var(--primary-color);">
            <p>NUESTRA HISTORIA</p>
        </section>

        <section class="section-container history-section">
            <div class="text-content">
                <p>
                    La Universidad de Gestión e Innovación del Conocimiento (UGIC) fue fundada en el año 2010 como una iniciativa académica audaz, destinada a cubrir las nuevas demandas del mercado laboral en sectores emergentes y de alta tecnología. Desde sus inicios, UGIC se propuso ser un faro de conocimiento y un motor de desarrollo para la región.
                </p>
                <p>
                    Con un enfoque vanguardista, la universidad ha crecido sostenidamente, expandiendo su oferta educativa con programas innovadores, modernizando su infraestructura con tecnología de punta y fortaleciendo alianzas estratégicas con instituciones académicas y empresariales tanto nacionales como internacionales. Cada paso en nuestra historia ha sido impulsado por la visión de formar profesionales con una sólida base teórica y práctica.
                </p>
                <p>
                    Hoy, UGIC es un referente en educación superior, reconocida por su excelencia académica, su activa investigación y su profundo impacto social, preparando a las nuevas generaciones para los desafíos del mañana y contribuyendo al progreso sostenible de la sociedad.
                </p>
            </div>

            <div class="history-collage">
                <img src="img/imagen10.png" alt="Antiguo edificio de la universidad">
                <img src="img/imagen11.png" alt="Primera generación de graduados">
                <img src="img/imagen12.png" alt="Construcción de nuevas instalaciones">
                <img src="img/imagen13.png" alt="Evento importante en la historia de UGIC">
                <img src="img/imagen14.png" alt="Logro académico destacado">
            </div>
        </section>

        <section class="section-title">
            <p>AUTORIDADES</p>
        </section>

        <section class="section-container authorities-grid">
            <div class="authority-card">
                <img src="img/imagen20.png" alt="Foto del Dr. Mario Fernández Torres">
                <div class="authority-info">
                    <h3>Dr. Mario Fernández Torres</h3>
                    <p>Rector General</p>
                </div>
            </div>
            <div class="authority-card">
                <img src="img/imagen21.png" alt="Foto de la Dra. Lucía Ramírez Delgado">
                <div class="authority-info">
                    <h3>Dra. Lucía Ramírez Delgado</h3>
                    <p>Vicerrectora Académica</p>
                </div>
            </div>
            <div class="authority-card">
                <img src="img/imagen22.png" alt="Foto del Dr. Felipe Montes Quispe">
                <div class="authority-info">
                    <h3>Dr. Felipe Montes Quispe</h3>
                    <p>Vicerrector de Investigación</p>
                </div>
            </div>
            <div class="authority-card">
                <img src="img/imagen23.png" alt="Foto de la Lic. Ana Gabriela Suárez">
                <div class="authority-info">
                    <h3>Lic. Ana Gabriela Suárez</h3>
                    <p>Directora de Bienestar Universitario</p>
                </div>
            </div>
            <div class="authority-card">
                <img src="img/imagen24.png" alt="Foto del Ing. Carlos Méndez Rosales">
                <div class="authority-info">
                    <h3>Ing. Carlos Méndez Rosales</h3>
                    <p>Decano de la Facultad de Ingeniería</p>
                </div>
            </div>
            <div class="authority-card">
                <img src="img/imagen25.png" alt="Foto de la Dra. Rosa Elena Támara">
                <div class="authority-info">
                    <h3>Dra. Rosa Elena Támara</h3>
                    <p>Decana de la Facultad de Ciencias Sociales</p>
                </div>
            </div>
            <div class="authority-card">
                <img src="img/imagen26.png" alt="Foto del Mgr. Javier López Herrera">
                <div class="authority-info">
                    <h3>Mgr. Javier López Herrera</h3>
                    <p>Secretario General</p>
                </div>
            </div>
            </section>
        <!-- Footer / Pie de página -->
        <footer style="background-color: #222; color: white; text-align: center; padding: 30px 20px; font-size: 16px; margin-top: 60px;">
            <p>&copy; 2025 Universidad Global de Innovación y Conocimiento (UGIC). Todos los derechos reservados.</p>
            <p>Contacto: info@ugic.edu | Tel: +123 456 7890</p>
            <div style="margin-top: 10px;">
                <a href="#" style="color: #ccc; margin: 0 10px; text-decoration: none;">Aviso legal</a>
                |
                <a href="#" style="color: #ccc; margin: 0 10px; text-decoration: none;">Política de privacidad</a>
                |
                <a href="#" style="color: #ccc; margin: 0 10px; text-decoration: none;">Términos de uso</a>
            </div>
        </footer>
        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.5/dist/js/bootstrap.bundle.min.js"></script>
    </body>
</html>