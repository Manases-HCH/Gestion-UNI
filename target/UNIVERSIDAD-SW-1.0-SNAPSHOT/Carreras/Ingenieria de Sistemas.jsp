<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.*"%>
<%
    String loginError = (String) session.getAttribute("loginError");
    if (loginError != null) {
        session.removeAttribute("loginError");
    }
%>
<!DOCTYPE html>
<html lang="es">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>UGIC PORTAL - Ingeniería de Sistemas</title>
        <link rel="icon" href="../img/favicon.ico" type="image/x-icon">
        <link rel="stylesheet" href="https://pro.fontawesome.com/releases/v5.10.0/css/all.css" />
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
        <link href="https://fonts.googleapis.com/css2?family=Montserrat:wght@400;600;700&family=Roboto:wght@300;400;700&display=swap" rel="stylesheet">
        <style>
            body {
                font-family: 'Roboto', sans-serif;
                background-color: #f8f9fa;
                color: #333;
            }
            .navbar {
                box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            }
            .navbar-brand img {
                max-height: 2.8rem; /* Aumentado ligeramente para mejor visibilidad */
                margin-right: 10px;
                transition: transform 0.3s ease;
            }
            .navbar-brand img:hover {
                transform: scale(1.05);
            }
            .navbar-nav .nav-link {
                font-weight: 500;
                color: rgba(255, 255, 255, 0.85);
                transition: color 0.3s ease, transform 0.3s ease;
            }
            .navbar-nav .nav-link:hover {
                color: white;
                transform: translateY(-2px);
            }
            .dropdown-menu {
                border-radius: 0.5rem;
                box-shadow: 0 5px 15px rgba(0,0,0,0.1);
                animation: fadeInDropdown 0.3s ease-out forwards;
            }
            @keyframes fadeInDropdown {
                from { opacity: 0; transform: translateY(-10px); }
                to { opacity: 1; transform: translateY(0); }
            }
            .dropdown-item {
                transition: background-color 0.2s ease, color 0.2s ease;
            }
            .dropdown-item:hover {
                background-color: #e9ecef;
                color: #007bff;
            }

            /* Estilos para el texto superpuesto en el carrusel */
            .hero-text-overlay {
                z-index: 10;
                background-color: rgba(0, 0, 0, 0.6); /* Un poco más oscuro para mejor contraste */
                backdrop-filter: blur(3px); /* Efecto de desenfoque sutil */
                border-radius: 1rem; /* Bordes más redondeados */
                padding: 1.5rem 2.5rem; /* Más padding */
                box-shadow: 0 5px 20px rgba(0, 0, 0, 0.3);
                animation: fadeInScale 1.5s ease-out forwards; /* Animación de fade-in y escala */
            }

            @keyframes fadeInScale {
                from { opacity: 0; transform: translate(-50%, -50%) scale(0.9); }
                to { opacity: 1; transform: translate(-50%, -50%) scale(1); }
            }

            .hero-text-overlay h1 {
                font-family: 'Montserrat', sans-serif;
                font-size: 3.5rem; /* Tamaño de fuente más grande */
                font-weight: 700;
                text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.5); /* Sombra de texto */
            }

            /* Carrusel */
            .carousel-item img {
                filter: brightness(0.7); /* Oscurecer un poco las imágenes para que el texto resalte */
            }
            .carousel-control-prev-icon, .carousel-control-next-icon {
                background-color: rgba(0, 0, 0, 0.4);
                border-radius: 50%;
                padding: 1.5rem;
            }

            /* Título de la carrera principal */
            .career-title-banner {
                background: linear-gradient(to right, #8b0000, #b22222); /* Degradado de rojo oscuro */
                color: white;
                font-size: 3.5rem; /* Tamaño de fuente más grande */
                font-family: 'Montserrat', sans-serif;
                padding: 2.5rem 0;
                text-align: center;
                letter-spacing: 2px; /* Espaciado entre letras */
                text-shadow: 3px 3px 6px rgba(0, 0, 0, 0.4); /* Sombra más pronunciada */
                margin-bottom: 2rem;
            }
            .career-title-banner p {
                margin: 0; /* Eliminar margen predeterminado del párrafo */
            }

            /* Información general de la carrera */
            .info-section {
                max-width: 1000px;
                margin: 40px auto;
                padding: 0 20px; /* Ajuste el padding para pantallas más pequeñas */
                font-size: 1.15rem; /* Aumentar tamaño de fuente */
                line-height: 1.8;
                color: #555;
            }
            .info-section strong {
                color: #8b0000;
            }
            .info-section ul {
                list-style-type: none; /* Eliminar viñetas predeterminadas */
                padding: 0;
            }
            .info-section ul li {
                position: relative;
                padding-left: 30px;
                margin-bottom: 10px;
            }
            .info-section ul li::before {
                content: "\f058"; /* Icono de check-circle de Font Awesome */
                font-family: "Font Awesome 5 Pro";
                font-weight: 900;
                color: #28a745; /* Color verde para el check */
                position: absolute;
                left: 0;
                top: 0;
            }

            /* Malla Curricular */
            .curriculum-section {
                max-width: 1200px; /* Aumentar ancho máximo para la malla */
                margin: 60px auto;
                padding: 0 20px;
            }
            .curriculum-section h2 {
                font-size: 2.5rem;
                color: #8b0000;
                margin-bottom: 2.5rem;
                text-align: center;
                font-family: 'Montserrat', sans-serif;
                position: relative;
                padding-bottom: 10px;
            }
            .curriculum-section h2::after {
                content: '';
                position: absolute;
                left: 50%;
                bottom: 0;
                transform: translateX(-50%);
                width: 80px;
                height: 4px;
                background-color: #8b0000;
                border-radius: 2px;
            }

            .cycles-grid {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); /* Columnas responsivas */
                gap: 30px;
            }
            .cycle-card {
                border: 2px solid #8b0000;
                border-radius: 15px; /* Más redondeado */
                padding: 25px;
                background-color: white;
                box-shadow: 0 8px 25px rgba(0,0,0,0.1); /* Sombra más suave y extendida */
                transition: transform 0.3s ease, box-shadow 0.3s ease;
            }
            .cycle-card:hover {
                transform: translateY(-8px); /* Efecto hover de levantamiento */
                box-shadow: 0 12px 30px rgba(0,0,0,0.15);
            }
            .cycle-card h3 {
                color: #8b0000;
                margin-bottom: 15px;
                font-family: 'Montserrat', sans-serif;
                font-size: 1.8rem;
                border-bottom: 2px solid #f0f0f0; /* Separador sutil */
                padding-bottom: 10px;
            }
            .cycle-card ul {
                list-style-type: none;
                padding: 0;
            }
            .cycle-card ul li {
                margin-bottom: 8px;
                font-size: 1rem;
                color: #444;
                position: relative;
                padding-left: 25px;
            }
            .cycle-card ul li::before {
                content: "\f101"; /* Icono de ángulo derecho de Font Awesome */
                font-family: "Font Awesome 5 Pro";
                font-weight: 900;
                color: #007bff; /* Color azul para los ítems */
                position: absolute;
                left: 0;
                top: 2px;
            }

            /* Modales de Login */
            .modal-header-primary { background-color: #007bff !important; }
            .modal-header-info { background-color: #17a2b8 !important; }
            .modal-header-success { background-color: #28a745 !important; }
            .modal-content { border-radius: 1rem; overflow: hidden; }
            .modal-body { padding: 2rem; }
            .modal-footer { border-top: none; padding: 1rem 2rem; }
            .form-label { font-weight: 600; color: #555; }
            .form-control { border-radius: 0.5rem; padding: 0.75rem 1rem; }
            .btn { border-radius: 0.5rem; padding: 0.75rem 1.25rem; font-weight: 600; }
            .btn-primary { background-color: #007bff; border-color: #007bff; transition: all 0.3s ease; }
            .btn-primary:hover { background-color: #0056b3; border-color: #0056b3; transform: translateY(-2px); box-shadow: 0 4px 8px rgba(0,123,255,0.2); }
            .btn-info { background-color: #17a2b8; border-color: #17a2b8; transition: all 0.3s ease; }
            .btn-info:hover { background-color: #138496; border-color: #138496; transform: translateY(-2px); box-shadow: 0 4px 8px rgba(23,162,184,0.2); }
            .btn-success { background-color: #28a745; border-color: #28a745; transition: all 0.3s ease; }
            .btn-success:hover { background-color: #1e7e34; border-color: #1e7e34; transform: translateY(-2px); box-shadow: 0 4px 8px rgba(40,167,69,0.2); }
            .modal-footer .btn-secondary { background-color: #6c757d; border-color: #6c757d; transition: all 0.3s ease; }
            .modal-footer .btn-secondary:hover { background-color: #5a6268; border-color: #545b62; }

            /* Footer */
            footer {
                background-color: #222;
                color: #e0e0e0;
                padding: 40px 20px;
                font-size: 0.95rem;
                margin-top: 80px;
                border-top: 5px solid #8b0000; /* Línea de color de la marca */
            }
            footer p {
                margin-bottom: 8px;
            }
            footer a {
                color: #007bff; /* Enlaces en el footer en azul */
                text-decoration: none;
                transition: color 0.3s ease;
            }
            footer a:hover {
                color: #e0e0e0; /* Cambiar a blanco en hover */
                text-decoration: underline;
            }
            .social-icons {
                margin-top: 15px;
            }
            .social-icons a {
                color: white;
                font-size: 1.5rem;
                margin: 0 10px;
                transition: transform 0.3s ease, color 0.3s ease;
            }
            .social-icons a:hover {
                transform: translateY(-3px) scale(1.1);
                color: #007bff;
            }

            /* Responsive Adjustments */
            @media (max-width: 768px) {
                .hero-text-overlay h1 {
                    font-size: 2.5rem;
                }
                .career-title-banner {
                    font-size: 2.5rem;
                    padding: 1.5rem 0;
                }
                .info-section {
                    font-size: 1rem;
                }
                .curriculum-section h2 {
                    font-size: 2rem;
                }
                .cycle-card {
                    padding: 20px;
                }
                .cycle-card h3 {
                    font-size: 1.5rem;
                }
            }
            @media (max-width: 576px) {
                .hero-text-overlay {
                    padding: 1rem 1.5rem;
                }
                .hero-text-overlay h1 {
                    font-size: 2rem;
                }
                .career-title-banner {
                    font-size: 1.8rem;
                    padding: 1rem 0;
                }
                .info-section {
                    margin: 20px auto;
                }
                .curriculum-section {
                    margin: 30px auto;
                }
                .cycles-grid {
                    grid-template-columns: 1fr; /* Una columna en móviles */
                }
            }
        </style>
    </head>
    <body>
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
                }
            });
        </script>

        <nav class="navbar navbar-expand-lg navbar-dark bg-dark sticky-top">
            <div class="container-fluid px-4">
                <a class="navbar-brand" href="../Plataforma.jsp">
                    <img src="../img/logo_ugic.png" alt="Logo UGIC"> UGIC Portal
                </a>
                <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarSupportedContent"
                        aria-controls="navbarSupportedContent" aria-expanded="false" aria-label="Toggle navigation">
                    <span class="navbar-toggler-icon"></span>
                </button>
                <div class="collapse navbar-collapse" id="navbarSupportedContent">
                    <ul class="navbar-nav me-auto mb-2 mb-lg-0">
                        <li class="nav-item dropdown">
                            <a class="nav-link dropdown-toggle" href="#" id="carrerasPregradoDropdown" role="button"
                               data-bs-toggle="dropdown" aria-expanded="false">
                                <i class="fas fa-graduation-cap me-2"></i> Carreras Pregrado
                            </a>
                            <ul class="dropdown-menu" aria-labelledby="carrerasPregradoDropdown">
                                <li><a class="dropdown-item" href="Ingenieria de Sistemas.jsp">Ingeniería de Sistemas</a></li>
                                <li><hr class="dropdown-divider"></li>
                                <li><a class="dropdown-item" href="Administración de Empresas.jsp">Administración de Empresas</a></li>
                                <li><a class="dropdown-item" href="Derecho.jsp">Derecho</a></li>
                                <li><a class="dropdown-item" href="Contabilidad.jsp">Contabilidad</a></li>
                                <li><a class="dropdown-item" href="Ingeniería Industrial.jsp">Ingeniería Industrial</a></li>
                                <li><a class="dropdown-item" href="Ingeniería Civil.jsp">Ingeniería Civil</a></li>
                                <li><a class="dropdown-item" href="Psicología.jsp">Psicología</a></li>
                                <li><a class="dropdown-item" href="Educación Inicial.jsp">Educación Inicial</a></li>
                                <li><a class="dropdown-item" href="Ciencias de la Comunicación.jsp">Ciencias de la Comunicación</a></li>
                                <li><a class="dropdown-item" href="Arquitectura.jsp">Arquitectura</a></li>
                            </ul>
                        </li>
                        <li class="nav-item dropdown">
                            <a class="nav-link dropdown-toggle" href="#" id="carrerasDistanciaDropdown" role="button"
                               data-bs-toggle="dropdown" aria-expanded="false">
                                <i class="fas fa-globe me-2"></i> Carreras a Distancia
                            </a>
                            <ul class="dropdown-menu" aria-labelledby="carrerasDistanciaDropdown">
                                <li><a class="dropdown-item" href="#">Administración de Empresas (Virtual)</a></li>
                                <li><a class="dropdown-item" href="#">Marketing Digital (Virtual)</a></li>
                            </ul>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="#"><i class="fas fa-book-open me-2"></i> Posgrado</a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="#"><i class="fas fa-users me-2"></i> Nosotros</a>
                        </li>
                    </ul>
                    <form class="d-flex me-3">
                        <input class="form-control me-2" type="search" placeholder="Buscar..." aria-label="Buscar">
                        <button class="btn btn-outline-light" type="submit"><i class="fas fa-search"></i></button>
                    </form>
                    <ul class="navbar-nav">
                        <li class="nav-item">
                            <a class="nav-link btn btn-primary px-3 py-2 me-2" href="#" style="background-color: #8b0000; border-color: #8b0000; color: white;"><i class="fas fa-hand-point-right me-2"></i> Postular a UGIC</a>
                        </li>
                        <li class="nav-item dropdown">
                            <a class="nav-link dropdown-toggle" href="#" id="usuarioDropdown" role="button"
                               data-bs-toggle="dropdown" aria-expanded="false">
                                <i class="fas fa-user-circle me-2"></i> Iniciar Sesión
                            </a>
                            <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="usuarioDropdown">
                                <li><a class="dropdown-item" href="#" data-bs-toggle="modal" data-bs-target="#alumnoModal"><i class="fas fa-user me-2"></i> Alumno</a></li>
                                <li><a class="dropdown-item" href="#" data-bs-toggle="modal" data-bs-target="#profesorModal"><i class="fas fa-chalkboard-teacher me-2"></i> Profesor</a></li>
                                <li><hr class="dropdown-divider"></li>
                                <li><a class="dropdown-item" href="#" data-bs-toggle="modal" data-bs-target="#adminModal"><i class="fas fa-user-shield me-2"></i> Administrador</a></li>
                                <li><hr class="dropdown-divider"></li>
                                <li><a class="dropdown-item text-primary" href="#"><i class="fas fa-user-plus me-2"></i> ¿No tienes cuenta? Regístrate</a></li>
                            </ul>
                        </li>
                    </ul>
                </div>
            </div>
        </nav>

        <div class="position-relative">
            <div class="position-absolute top-50 start-50 translate-middle text-center text-white hero-text-overlay">
                <h1 class="display-4 fw-bold">Ingeniería de Sistemas</h1>
                <p class="lead mt-3">¡Construye el futuro con tecnología e innovación!</p>
            </div>
            <div id="miCarrusel" class="carousel slide carousel-fade" data-bs-ride="carousel" data-bs-interval="5000"> <div class="carousel-inner">
                    <div class="carousel-item active">
                        <img src="imgUni/IG1.jpg" class="d-block w-100" alt="Campus Universitario Moderno" style="height: 550px; object-fit: cover;">
                    </div>
                    <div class="carousel-item">
                        <img src="imgUni/IG2.jpg" class="d-block w-100" alt="Estudiantes Colaborando en Laboratorio" style="height: 550px; object-fit: cover;">
                    </div>
                    <div class="carousel-item">
                        <img src="https://via.placeholder.com/1920x550/4682B4/FFFFFF?text=Innovación+Tecnológica" class="d-block w-100" alt="Innovación Tecnológica" style="height: 550px; object-fit: cover;">
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
            </div>
        </div>

        <div class="career-title-banner">
            <p>INGENIERÍA DE SISTEMAS</p>
        </div>

        <div class="container info-section">
            <p class="text-center mb-5">
                La carrera de <strong>Ingeniería de Sistemas</strong> de UGIC forma profesionales capaces de diseñar, desarrollar e implementar soluciones tecnológicas que optimicen los procesos en organizaciones públicas y privadas. Se combina una sólida formación técnica con conocimientos en gestión, innovación y ética profesional.
            </p>

            <h3 class="text-center mb-4 text-primary fw-bold">Información Clave de la Carrera</h3>
            <ul class="list-unstyled d-flex flex-wrap justify-content-center">
                <li class="mx-4 my-2"><i class="fas fa-award me-2 text-success"></i><strong>Grado Académico:</strong> Bachiller en Ingeniería de Sistemas</li>
                <li class="mx-4 my-2"><i class="fas fa-user-tie me-2 text-info"></i><strong>Título Profesional:</strong> Ingeniero(a) de Sistemas</li>
                <li class="mx-4 my-2"><i class="fas fa-clock me-2 text-warning"></i><strong>Duración:</strong> 10 ciclos académicos (5 años)</li>
            </ul>
        </div>

        <div class="curriculum-section">
            <h2>Malla Curricular</h2>
            <div class="cycles-grid">
                <div class="cycle-card">
                    <h3><i class="fas fa-list-ol me-2"></i> Ciclo I</h3>
                    <ul>
                        <li>Desarrollo del talento</li>
                        <li>Complemento matemático aplicado</li>
                        <li>Introducción a la ingeniería de sistemas computacionales</li>
                        <li>Ciudadanía global</li>
                        <li>Comunicación 1</li>
                    </ul>
                </div>

                <div class="cycle-card">
                    <h3><i class="fas fa-list-ol me-2"></i> Ciclo II</h3>
                    <ul>
                        <li>Matemática básica aplicada</li>
                        <li>Fundamentos de algoritmos</li>
                        <li>Metodología universitaria</li>
                        <li>Pre beginner 1</li>
                        <li>Comunicación 2</li>
                    </ul>
                </div>

                <div class="cycle-card">
                    <h3><i class="fas fa-list-ol me-2"></i> Ciclo III</h3>
                    <ul>
                        <li>Cálculo 1</li>
                        <li>Fundamentos de programación</li>
                        <li>Matemática discreta</li>
                        <li>Mecánica, oscilación y ondas</li>
                        <li>Pre beginner 2</li>
                        <li>Comunicación 3</li>
                    </ul>
                </div>

                <div class="cycle-card">
                    <h3><i class="fas fa-list-ol me-2"></i> Ciclo IV</h3>
                    <ul>
                        <li>Estructura de datos</li>
                        <li>Cálculo 2</li>
                        <li>Probabilidad y estadística</li>
                        <li>Herramientas informáticas</li>
                        <li>Electricidad, magnetismo y óptica</li>
                    </ul>
                </div>

                <div class="cycle-card">
                    <h3><i class="fas fa-list-ol me-2"></i> Ciclo V</h3>
                    <ul>
                        <li>Técnicas de programación orientada a objetos</li>
                        <li>Base de datos</li>
                        <li>Electrónica digital</li>
                        <li>Análisis de algoritmos y estrategias de programación</li>
                        <li>Optimización y simulación</li>
                        <li>Responsabilidad social</li>
                    </ul>
                </div>

                <div class="cycle-card">
                    <h3><i class="fas fa-list-ol me-2"></i> Ciclo VI</h3>
                    <ul>
                        <li>Base de datos avanzadas y big data</li>
                        <li>Empleabilidad</li>
                        <li>Modelamiento y análisis de software</li>
                        <li>Computación gráfica y visual</li>
                        <li>Arquitectura del computador</li>
                    </ul>
                </div>

                <div class="cycle-card">
                    <h3><i class="fas fa-list-ol me-2"></i> Ciclo VII</h3>
                    <ul>
                        <li>Sistemas operativos</li>
                        <li>Interacción humano computador</li>
                        <li>Redes 1</li>
                        <li>Diseño y arquitectura de software</li>
                        <li>Metodología de la investigación</li>
                        <li>Proyecto social</li>
                    </ul>
                </div>

                <div class="cycle-card">
                    <h3><i class="fas fa-list-ol me-2"></i> Ciclo VIII</h3>
                    <ul>
                        <li>Soluciones web y aplicaciones distribuidas</li>
                        <li>Redes 2</li>
                        <li>Calidad y pruebas de software</li>
                        <li>Prácticas preprofesionales</li>
                        <li>Taller de robótica</li>
                    </ul>
                </div>
                <div class="cycle-card">
                    <h3><i class="fas fa-list-ol me-2"></i> Ciclo IX</h3>
                    <ul>
                        <li>Videojuegos y aplicaciones móviles</li>
                        <li>Tesis</li>
                        <li>Sistemas inteligentes y machine learning</li>
                        <li>Administración de proyectos de software</li>
                        <li>Electivo 1</li>
                    </ul>
                </div>
                <div class="cycle-card">
                    <h3><i class="fas fa-list-ol me-2"></i> Ciclo X</h3>
                    <ul>
                        <li>Capstone Project Sistemas</li>
                        <li>Trabajo de Investigación</li>
                        <li>Seguridad informática</li>
                        <li>Electiva II</li>
                    </ul>
                </div>
            </div>
        </div>

        <div class="modal fade" id="alumnoModal" tabindex="-1" aria-labelledby="alumnoModalLabel" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered">
                <div class="modal-content">
                    <div class="modal-header modal-header-primary bg-primary text-white">
                        <h5 class="modal-title" id="alumnoModalLabel"><i class="fas fa-graduation-cap me-2"></i> Iniciar Sesión Alumno</h5>
                        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>
                    <div class="modal-body">
                        <form action="loginServlet" method="post">
                            <input type="hidden" name="userType" value="alumno">
                            <div class="mb-3">
                                <label for="alumnoUsernameInput" class="form-label"><i class="fas fa-user me-2"></i> Usuario</label>
                                <input type="text" class="form-control" id="alumnoUsernameInput" name="username" placeholder="Ingrese su usuario" required>
                            </div>
                            <div class="mb-3">
                                <label for="alumnoPasswordInput" class="form-label"><i class="fas fa-lock me-2"></i> Contraseña</label>
                                <input type="password" class="form-control" id="alumnoPasswordInput" name="password" placeholder="Ingrese su contraseña" required>
                            </div>
                            <div class="form-check mb-3">
                                <input type="checkbox" class="form-check-input" id="rememberAlumno">
                                <label class="form-check-label" for="rememberAlumno">Recordarme</label>
                            </div>
                            <div class="d-grid">
                                <button type="submit" class="btn btn-primary"><i class="fas fa-sign-in-alt me-2"></i> Iniciar Sesión</button>
                            </div>
                            <div class="mt-3 text-center">
                                <a href="#" class="text-decoration-none">¿Olvidó su contraseña?</a> | <a href="#" class="text-decoration-none">Registrarse</a>
                            </div>
                        </form>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary btn-sm" data-bs-dismiss="modal"><i class="fas fa-times me-2"></i> Cerrar</button>
                    </div>
                </div>
            </div>
        </div>

        <div class="modal fade" id="profesorModal" tabindex="-1" aria-labelledby="profesorModalLabel" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered">
                <div class="modal-content">
                    <div class="modal-header bg-info text-white">
                        <h5 class="modal-title" id="profesorModalLabel"><i class="fas fa-chalkboard-teacher me-2"></i> Iniciar Sesión Profesor</h5>
                        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>
                    <div class="modal-body">
                        <form action="loginServlet" method="post">
                            <input type="hidden" name="userType" value="profesor">
                            <div class="mb-3">
                                <label for="profesorUsernameInput" class="form-label"><i class="fas fa-user me-2"></i> Usuario Profesor</label>
                                <input type="text" class="form-control" id="profesorUsernameInput" name="username" placeholder="Ingrese su usuario de profesor" required>
                            </div>
                            <div class="mb-3">
                                <label for="profesorPasswordInput" class="form-label"><i class="fas fa-lock me-2"></i> Contraseña Profesor</label>
                                <input type="password" class="form-control" id="profesorPasswordInput" name="password" placeholder="Ingrese su contraseña" required>
                            </div>
                            <div class="form-check mb-3">
                                <input type="checkbox" class="form-check-input" id="rememberProfesor">
                                <label class="form-check-label" for="rememberProfesor">Recordarme</label>
                            </div>
                            <div class="d-grid">
                                <button type="submit" class="btn btn-info"><i class="fas fa-sign-in-alt me-2"></i> Iniciar Sesión</button>
                            </div>
                            <div class="mt-3 text-center">
                                <a href="#" class="text-decoration-none">¿Olvidó su contraseña?</a> | <a href="#" class="text-decoration-none">Registrarse</a>
                            </div>
                        </form>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary btn-sm" data-bs-dismiss="modal"><i class="fas fa-times me-2"></i> Cerrar</button>
                    </div>
                </div>
            </div>
        </div>

        <div class="modal fade" id="adminModal" tabindex="-1" aria-labelledby="adminModalLabel" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered">
                <div class="modal-content">
                    <div class="modal-header bg-success text-white">
                        <h5 class="modal-title" id="adminModalLabel"><i class="fas fa-user-shield me-2"></i> Iniciar Sesión Administrador</h5>
                        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>
                    <div class="modal-body">
                        <form action="loginServlet" method="post">
                            <input type="hidden" name="userType" value="admin">
                            <div class="mb-3">
                                <label for="adminUsernameInput" class="form-label"><i class="fas fa-user me-2"></i> Usuario Admin</label>
                                <input type="text" class="form-control" id="adminUsernameInput" name="username" placeholder="Ingrese su usuario de administrador" required>
                            </div>
                            <div class="mb-3">
                                <label for="adminPasswordInput" class="form-label"><i class="fas fa-lock me-2"></i> Contraseña Admin</label>
                                <input type="password" class="form-control" id="adminPasswordInput" name="password" placeholder="Ingrese su contraseña" required>
                            </div>
                            <div class="form-check mb-3">
                                <input type="checkbox" class="form-check-input" id="rememberAdmin">
                                <label class="form-check-label" for="rememberAdmin">Recordarme</label>
                            </div>
                            <div class="d-grid">
                                <button type="submit" class="btn btn-success"><i class="fas fa-sign-in-alt me-2"></i> Iniciar Sesión</button>
                            </div>
                            <div class="mt-3 text-center">
                                <a href="#" class="text-decoration-none">¿Olvidó su contraseña?</a> | <a href="#" class="text-decoration-none">Registrarse</a>
                            </div>
                        </form>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary btn-sm" data-bs-dismiss="modal"><i class="fas fa-times me-2"></i> Cerrar</button>
                    </div>
                </div>
            </div>
        </div>

        <footer class="text-center">
            <div class="container">
                <p>&copy; 2025 Universidad Global de Innovación y Conocimiento (UGIC). Todos los derechos reservados.</p>
                <p>Contacto: <a href="mailto:info@ugic.edu">info@ugic.edu</a> | Tel: <a href="tel:+1234567890">+123 456 7890</a></p>
                <div class="social-icons mb-3">
                    <a href="#" aria-label="Facebook"><i class="fab fa-facebook-f"></i></a>
                    <a href="#" aria-label="Twitter"><i class="fab fa-twitter"></i></a>
                    <a href="#" aria-label="Instagram"><i class="fab fa-instagram"></i></a>
                    <a href="#" aria-label="LinkedIn"><i class="fab fa-linkedin-in"></i></a>
                </div>
                <div>
                    <a href="#">Aviso legal</a>
                    <span class="mx-2">|</span>
                    <a href="#">Política de privacidad</a>
                    <span class="mx-2">|</span>
                    <a href="#">Términos de uso</a>
                </div>
            </div>
        </footer>
        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    </body>
</html>