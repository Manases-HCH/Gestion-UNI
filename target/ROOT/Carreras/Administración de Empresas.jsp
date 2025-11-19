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
        <title>UGIC PORTAL</title>
        <link rel="stylesheet" href="https://pro.fontawesome.com/releases/v5.10.0/css/all.css" />
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.5/dist/css/bootstrap.min.css" rel="stylesheet">
        <style>
            .navbar-brand img {
                max-height: 2.5rem;
                margin-right: 10px;
            }
        </style>
        <style>
            .fade-in {
                opacity: 0;
                animation: fadeInAnimation 1.5s ease-in forwards;
            }

            @keyframes fadeInAnimation {
                to {
                    opacity: 1;
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
        <nav class="navbar navbar-expand-lg navbar-dark bg-dark">
            <div class="container-fluid">
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
                                Carreras Pregrado
                            </a>
                            <ul class="dropdown-menu" aria-labelledby="carrerasPregradoDropdown">
                                <li><a class="dropdown-item" href="Ingenieria de Sistemas.jsp">Ingeniería de Sistemas</a></li>
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
                                Carreras a Distancia
                            </a>
                            <ul class="dropdown-menu" aria-labelledby="carrerasDistanciaDropdown">
                                <li><a class="dropdown-item" href="#">Administración de Empresas (Virtual)</a></li>
                                <li><a class="dropdown-item" href="#">Marketing Digital (Virtual)</a></li>
                            </ul>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="#">Posgrado</a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="#">Nosotros</a>
                        </li>
                    </ul>
                    <form class="d-flex">
                        <input class="form-control me-2" type="search" placeholder="Buscar" aria-label="Buscar">
                        <button class="btn btn-outline-success" type="submit">Buscar</button>
                    </form>
                    <ul class="navbar-nav">
                        <li class="nav-item">
                            <a class="nav-link" href="#">Postular a UGIC</a>
                        </li>
                        <li class="nav-item dropdown">
                            <a class="nav-link dropdown-toggle" href="#" id="usuarioDropdown" role="button"
                               data-bs-toggle="dropdown" aria-expanded="false">
                                <i class="fas fa-user"></i> Iniciar Sesión
                            </a>
                            <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="usuarioDropdown">
                                <li><a class="dropdown-item" href="#" data-bs-toggle="modal" data-bs-target="#alumnoModal">Alumno</a></li>
                                <li><a class="dropdown-item" href="#" data-bs-toggle="modal" data-bs-target="#profesorModal">Profesor</a></li>
                                 <li><a class="dropdown-item" href="#" data-bs-toggle="modal" data-bs-target="#apoderadoModal">Apoderado</a></li>
                                <li><hr class="dropdown-divider"></li>
                                <li><a class="dropdown-item" href="#" data-bs-toggle="modal" data-bs-target="#adminModal">Administrador</a></li>
                                <li><hr class="dropdown-divider"></li>                     
                            </ul>
                        </li>
                    </ul>
                </div>
            </div>
        </nav>
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
                                <label for="alumnoUsernameModal" class="form-label"><i class="fas fa-user me-2"></i> Usuario</label>
                                <input type="text" class="form-control" id="alumnoUsernameInput" name="username" placeholder="Ingrese su usuario" required>
                            </div>
                            <div class="mb-3">
                                <label for="alumnoPasswordModal" class="form-label"><i class="fas fa-lock me-2"></i> Contraseña</label>
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
                                <a href="#">¿Olvidó su contraseña?</a> 
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
                                <label for="profesorUsernameModal" class="form-label"><i class="fas fa-user me-2"></i> Usuario </label>
                                <input type="text" class="form-control" id="profesorUsernameInput" name="username" placeholder="Ingrese su usuario de profesor" required>
                            </div>
                            <div class="mb-3">
                                <label for="profesorPasswordModal" class="form-label"><i class="fas fa-lock me-2"></i> Contraseña </label>
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
                                <a href="#">¿Olvidó su contraseña?</a> 
                            </div>
                        </form>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary btn-sm" data-bs-dismiss="modal"><i class="fas fa-times me-2"></i> Cerrar</button>
                    </div>
                </div>
            </div>
        </div>

        <div class="modal fade" id="apoderadoModal" tabindex="-1" aria-labelledby="apoderadoModalLabel" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered">
                <div class="modal-content">
                    <div class="modal-header bg-warning text-dark">
                        <h5 class="modal-title" id="apoderadoModalLabel"><i class="fas fa-user-friends me-2"></i> Iniciar Sesión Apoderado</h5>
                        <button type="button" class="btn-close btn-close-dark" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>
                    <div class="modal-body">
                        <form action="loginServlet" method="post">
                            <input type="hidden" name="userType" value="apoderado">
                            <div class="mb-3">
                                <label for="apoderadoUsernameModal" class="form-label"><i class="fas fa-user me-2"></i> Usuario</label>
                                <input type="text" class="form-control" id="apoderadoUsernameInput" name="username" placeholder="Ingrese su usuario de apoderado" required>
                            </div>
                            <div class="mb-3">
                                <label for="apoderadoPasswordModal" class="form-label"><i class="fas fa-lock me-2"></i> Contraseña</label>
                                <input type="password" class="form-control" id="apoderadoPasswordInput" name="password" placeholder="Ingrese su contraseña" required>
                            </div>
                            <div class="form-check mb-3">
                                <input type="checkbox" class="form-check-input" id="rememberApoderado">
                                <label class="form-check-label" for="rememberApoderado">Recordarme</label>
                            </div>
                            <div class="d-grid">
                                <button type="submit" class="btn btn-warning text-dark"><i class="fas fa-sign-in-alt me-2"></i> Iniciar Sesión</button>
                            </div>
                            <div class="mt-3 text-center">
                                <a href="#">¿Olvidó su contraseña?</a> 
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
                                <label for="adminUsernameModal" class="form-label"><i class="fas fa-user me-2"></i> Usuario </label>
                                <input type="text" class="form-control" id="adminUsernameInput" name="username" placeholder="Ingrese su usuario de administrador" required>
                            </div>
                            <div class="mb-3">
                                <label for="adminPasswordModal" class="form-label"><i class="fas fa-lock me-2"></i> Contraseña </label>
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
                                <a href="#">¿Olvidó su contraseña?</a> 
                            </div>
                        </form>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary btn-sm" data-bs-dismiss="modal"><i class="fas fa-times me-2"></i> Cerrar</button>
                    </div>
                </div>
            </div>
        </div>
        <div class="position-relative">
            <!-- Texto superpuesto fijo -->
            <div class="position-absolute top-50 start-50 translate-middle text-center text-white px-4 py-3 rounded fade-in"
                 style="z-index: 10; background-color: rgba(0, 0, 0, 0.5);">
                <h1 class="display-4 fw-bold">Administración de Empresas</h1>
            </div>
            <!-- Carrusel de fondo -->
            <div id="miCarrusel" class="carousel slide" data-bs-ride="carousel">
                <div class="carousel-inner">
                    <div class="carousel-item active">
                        <img src="imgUni/AP1.jpg" class="d-block w-100" alt="Campus 1" style="height: 500px; object-fit: cover;">
                    </div>
                    <div class="carousel-item">
                        <img src="imgUni/AP2.jpg" class="d-block w-100" alt="Campus 2" style="height: 500px; object-fit: cover;">
                    </div>
                </div>
                <button class="carousel-control-prev" type="button" data-bs-target="#miCarrusel" data-bs-slide="prev">
                    <span class="carousel-control-prev-icon"></span>
                </button>
                <button class="carousel-control-next" type="button" data-bs-target="#miCarrusel" data-bs-slide="next">
                    <span class="carousel-control-next-icon"></span>
                </button>
            </div>
        </div>
        <!-- Título de la carrera -->
        <div style="background-color: darkred; color: white; font-size: 50px; font-family: 'Arial Black', sans-serif; padding: 30px;">
            <p style="margin-left: 50px;">Administración de Empresas</p>
        </div>

        <!-- Información general de la carrera -->
        <div style="max-width: 1000px; margin: 40px auto; padding: 0 60px; font-size: 18px; line-height: 1.7;">
            <p>
                La carrera de Administración de Empresas en UGIC forma líderes capaces de gestionar eficientemente organizaciones en entornos dinámicos y globales. El enfoque del programa combina teoría y práctica en áreas clave como finanzas, marketing, recursos humanos, estrategia y emprendimiento. El objetivo es preparar profesionales con pensamiento estratégico, visión innovadora y sólidos valores éticos.
            </p>

            <ul style="margin-top: 30px;">
                <li><strong>Grado Académico:</strong> Bachiller en Ciencias Administrativas</li>
                <li><strong>Título Profesional:</strong> Administrador(a) de Empresas</li>
                <li><strong>Duración:</strong> 10 ciclos académicos (5 años)</li>
            </ul>
        </div>

        <!-- Malla Curricular -->
        <div style="max-width: 1000px; margin: 60px auto; padding: 0 60px;">
            <h2 style="font-size: 32px; color: darkred; margin-bottom: 20px;">Malla Curricular</h2>

            <!-- Ciclos -->
            <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 30px;">

                <!-- Ciclo 1 -->
                <div style="border: 2px solid darkred; border-radius: 10px; padding: 20px;">
                    <h3 style="color: darkred;">Ciclo I</h3>
                    <ul>
                        <li>Introducción a la Administración</li>
                        <li>Matemática Básica</li>
                        <li>Contabilidad General</li>
                        <li>Comunicación Oral y Escrita</li>
                        <li>Fundamentos de Economía</li>
                        <li>Realidad Nacional</li>
                    </ul>
                </div>

                <!-- Ciclo 2 -->
                <div style="border: 2px solid darkred; border-radius: 10px; padding: 20px;">
                    <h3 style="color: darkred;">Ciclo II</h3>
                    <ul>
                        <li>Comportamiento Organizacional</li>
                        <li>Estadística I</li>
                        <li>Contabilidad de Costos</li>
                        <li>Derecho Empresarial</li>
                        <li>Matemática Financiera</li>
                        <li>Fundamentos de Marketing</li>
                    </ul>
                </div>

                <!-- Ciclo 3 -->
                <div style="border: 2px solid darkred; border-radius: 10px; padding: 20px;">
                    <h3 style="color: darkred;">Ciclo III</h3>
                    <ul>
                        <li>Administración Financiera I</li>
                        <li>Microeconomía</li>
                        <li>Estadística II</li>
                        <li>Gestión del Talento Humano</li>
                        <li>Tecnología de la Información</li>
                        <li>Inglés Técnico I</li>
                    </ul>
                </div>

                <!-- Ciclo 4 -->
                <div style="border: 2px solid darkred; border-radius: 10px; padding: 20px;">
                    <h3 style="color: darkred;">Ciclo IV</h3>
                    <ul>
                        <li>Administración de Operaciones</li>
                        <li>Macroeconomía</li>
                        <li>Análisis Financiero</li>
                        <li>Comunicación Corporativa</li>
                        <li>Ética Profesional</li>
                        <li>Inglés Técnico II</li>
                    </ul>
                </div>

                <!-- Ciclo 5 -->
                <div style="border: 2px solid darkred; border-radius: 10px; padding: 20px;">
                    <h3 style="color: darkred;">Ciclo V</h3>
                    <ul>
                        <li>Planeamiento Estratégico</li>
                        <li>Investigación de Mercados</li>
                        <li>Gestión Logística</li>
                        <li>Fundamentos de Emprendimiento</li>
                        <li>Responsabilidad Social Empresarial</li>
                        <li>Electivo I</li>
                    </ul>
                </div>

                <!-- Ciclo 6 -->
                <div style="border: 2px solid darkred; border-radius: 10px; padding: 20px;">
                    <h3 style="color: darkred;">Ciclo VI</h3>
                    <ul>
                        <li>Dirección Comercial</li>
                        <li>Gestión de Proyectos</li>
                        <li>Negociación y Manejo de Conflictos</li>
                        <li>Gestión de Calidad</li>
                        <li>Desarrollo Organizacional</li>
                        <li>Electivo II</li>
                    </ul>
                </div>

                <!-- Ciclo 7 -->
                <div style="border: 2px solid darkred; border-radius: 10px; padding: 20px;">
                    <h3 style="color: darkred;">Ciclo VII</h3>
                    <ul>
                        <li>Evaluación de Proyectos de Inversión</li>
                        <li>Comercio Internacional</li>
                        <li>Derecho Laboral Empresarial</li>
                        <li>Creatividad e Innovación Empresarial</li>
                        <li>Finanzas Corporativas</li>
                        <li>Electivo III</li>
                    </ul>
                </div>

                <!-- Ciclo 8 -->
                <div style="border: 2px solid darkred; border-radius: 10px; padding: 20px;">
                    <h3 style="color: darkred;">Ciclo VIII</h3>
                    <ul>
                        <li>Simulación de Negocios</li>
                        <li>Finanzas Internacionales</li>
                        <li>Marketing Digital</li>
                        <li>Gestión del Cambio</li>
                        <li>Desarrollo Sostenible</li>
                        <li>Taller de Investigación I</li>
                    </ul>
                </div>
                <!-- Ciclo 9 -->
                <div style="border: 2px solid darkred; border-radius: 10px; padding: 20px;">
                    <h3 style="color: darkred;">Ciclo IX</h3>
                    <ul>
                        <li>Auditoría Administrativa</li>
                        <li>Formulación de Plan de Negocios</li>
                        <li>Inteligencia de Negocios</li>
                        <li>Cultura Organizacional</li>
                        <li>Taller de Investigación II</li>
                        <li>Electivo IV</li>
                    </ul>
                </div>
                <!-- Ciclo 10 -->
                <div style="border: 2px solid darkred; border-radius: 10px; padding: 20px;">
                    <h3 style="color: darkred;">Ciclo X</h3>
                    <ul>
                        <li>Seminario de Tesis</li>
                        <li>Prácticas Preprofesionales</li>
                        <li>Taller de Liderazgo Empresarial</li>
                        <li>Ética y Responsabilidad Profesional</li>
                        <li>Proyecto de Innovación Empresarial</li>
                    </ul>
                </div>
            </div>
        </div>
        <div class="container mt-2">
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
                                <label for="alumnoUsernameModal" class="form-label"><i class="fas fa-user me-2"></i> Usuario</label>
                                <input type="text" class="form-control" id="alumnoUsernameInput" name="username" placeholder="Ingrese su usuario" required>
                            </div>
                            <div class="mb-3">
                                <label for="alumnoPasswordModal" class="form-label"><i class="fas fa-lock me-2"></i> Contraseña</label>
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
                                <a href="#">¿Olvidó su contraseña?</a> | <a href="#">Registrarse</a>
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
                                <label for="profesorUsernameModal" class="form-label"><i class="fas fa-user me-2"></i> Usuario Profesor</label>
                                <input type="text" class="form-control" id="profesorUsernameInput" name="username" placeholder="Ingrese su usuario de profesor" required>
                            </div>
                            <div class="mb-3">
                                <label for="profesorPasswordModal" class="form-label"><i class="fas fa-lock me-2"></i> Contraseña Profesor</label>
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
                                <a href="#">¿Olvidó su contraseña?</a> | <a href="#">Registrarse</a>
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
                                <label for="adminUsernameModal" class="form-label"><i class="fas fa-user me-2"></i> Usuario Admin</label>
                                <input type="text" class="form-control" id="adminUsernameInput" name="username" placeholder="Ingrese su usuario de administrador" required>
                            </div>
                            <div class="mb-3">
                                <label for="adminPasswordModal" class="form-label"><i class="fas fa-lock me-2"></i> Contraseña Admin</label>
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
                                <a href="#">¿Olvidó su contraseña?</a> | <a href="#">Registrarse</a>
                            </div>
                        </form>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary btn-sm" data-bs-dismiss="modal"><i class="fas fa-times me-2"></i> Cerrar</button>
                    </div>
                </div>
            </div>
        </div>
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
        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    </body>
</html>