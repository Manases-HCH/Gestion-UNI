<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sidebar Académico</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css" rel="stylesheet">
    <style>
        body {
            background-color: #f0f2f5; /* Un fondo claro para contrastar con el sidebar oscuro */
        }
        /* Asegúrate de que la barra lateral ocupe el 100% de la altura de la ventana */
        .min-vh-100 {
            min-height: 100vh;
        }

        /* Estilos generales para el sidebar oscuro */
        .col-auto.bg-dark {
            background-color: #212529 !important; /* Asegura un color oscuro consistente */
        }

        /* Logo y título del sidebar */
        .sidebar-logo {
            padding: 20px 15px 15px 15px; /* Más padding arriba */
            border-bottom: 1px solid rgba(255, 255, 255, 0.1);
            margin-bottom: 15px;
            text-align: center;
        }
        .sidebar-logo img {
            width: 70px; /* Aumentar tamaño del logo */
            height: 70px;
            object-fit: cover;
            border-radius: 50%;
            border: 2px solid rgba(255, 255, 255, 0.3); /* Borde alrededor del logo */
            margin-bottom: 10px;
        }
        .sidebar-logo .sidebar-title {
            font-size: 1.4rem; /* Tamaño de fuente para "ACADÉMICO UGIC" */
            font-weight: 700;
            line-height: 1.2;
            color: #ffffff;
        }
        .sidebar-logo .sidebar-subtitle {
            font-size: 0.8rem; /* Tamaño de fuente para "SYSTAG" */
            color: #adb5bd; /* Gris claro para el subtítulo */
            letter-spacing: 0.5px;
        }

        /* Estilos para los elementos del menú de navegación */
        .nav-pills .nav-link {
            color: #adb5bd; /* Color por defecto de los enlaces */
            padding: 10px 15px; /* Espaciado interno */
            transition: background-color 0.2s, color 0.2s; /* Transición suave */
            border-radius: 5px; /* Bordes ligeramente redondeados */
        }

        .nav-pills .nav-link:hover,
        .nav-pills .nav-link:focus {
            background-color: rgba(255, 255, 255, 0.1); /* Fondo más claro al pasar el ratón */
            color: #ffffff; /* Texto blanco al pasar el ratón */
        }

        .nav-pills .nav-link.active {
            background-color: #0d6efd; /* Color azul de Bootstrap para activo, o puedes cambiarlo */
            color: #ffffff;
        }

        /* Estilos para los iconos en el menú */
        .nav-link i {
            margin-right: 10px; /* Espacio entre el icono y el texto */
            font-size: 1.2rem; /* Tamaño del icono */
        }

        /* Estilos para los submenús */
        #submenu1 {
            background-color: #2c3034; /* Un tono ligeramente más claro para el submenú */
            border-radius: 5px;
            margin-top: 5px;
            padding-left: 0; /* Asegura que no haya padding inicial en la lista */
        }

        #submenu1 .nav-link {
            padding-left: 30px; /* Indentación para los elementos del submenú */
            font-size: 0.9rem; /* Un poco más pequeño para los subelementos */
        }

        /* Estilos para el dropdown de usuario */
        .dropdown-pb-4 {
            padding-bottom: 1.5rem !important; /* Ajusta el padding si es necesario */
            padding-top: 1rem; /* Espacio entre el menú y el dropdown */
            border-top: 1px solid rgba(255, 255, 255, 0.1); /* Separador para el usuario */
            width: 100%; /* Asegura que ocupe todo el ancho */
        }

        .dropdown-toggle {
            color: #adb5bd; /* Color del texto del usuario */
            display: flex;
            align-items: center;
        }
        .dropdown-toggle:hover {
            color: #ffffff; /* Color al pasar el ratón */
        }

        .dropdown-toggle img {
            margin-right: 10px; /* Espacio entre la imagen del usuario y el texto */
        }

        .dropdown-menu.dropdown-menu-dark {
            background-color: #343a40; /* Fondo oscuro para el dropdown */
            border: none;
        }

        .dropdown-menu.dropdown-menu-dark .dropdown-item {
            color: #adb5bd;
        }

        .dropdown-menu.dropdown-menu-dark .dropdown-item:hover {
            background-color: #0d6efd; /* Color de hover para los items */
            color: #ffffff;
        }
        .dropdown-menu.dropdown-menu-dark .dropdown-divider {
            border-color: rgba(255, 255, 255, 0.1);
        }

        /* Ajustes para el texto "COMPONENTES ACADEMICOS" */
        .nav-link.px-0.align-middle span {
            font-weight: bold; /* Hacer el texto más audaz si es necesario */
            color: #ffffff; /* Asegurar que el título del menú sea blanco */
        }

    </style>
</head>
<body>

    <div class="col-auto col-md-3 col-xl-2 px-sm-2 px-0 bg-dark">
        <div class="d-flex flex-column align-items-center align-items-sm-start px-3 pt-2 text-white min-vh-100">
            <div class="sidebar-logo">
                <img src="img/logo_ugic.png" alt="Logo de la Institución">
                <span class="d-none d-sm-inline sidebar-title">ACADÉMICO UGIC</span>
                <span class="d-none d-sm-inline sidebar-subtitle"></span> </div>
            <hr class="w-100 text-secondary"> <%-- Solución más simple y robusta usando contextPath --%>
            <% String contextPath = request.getContextPath(); %>

            <ul class="nav nav-pills flex-column mb-sm-auto mb-0 align-items-center align-items-sm-start w-100" id="menu">
                <li class="nav-item w-100"> <a href="<%=contextPath%>/inicio.jsp" class="nav-link px-0"> 
                        <i class="fs-4 bi-house"></i> 
                        <span class="ms-1 d-none d-sm-inline">INICIO</span> 
                    </a>
                </li>
                <li class="nav-item w-100">
                    <a href="#submenu1" data-bs-toggle="collapse" class="nav-link px-0 align-middle">
                        <i class="fs-4 bi-speedometer2"></i> 
                        <span class="ms-1 d-none d-sm-inline">COMPONENTES ACADEMICOS</span>
                    </a>
                    <ul class="collapse show nav flex-column ms-1 w-100" id="submenu1" data-bs-parent="#menu">
                        <li class="w-100">
                            <a href="<%=contextPath%>/profesor/listado.jsp" class="nav-link px-0"> 
                                <i class="fs-4 bi-person-badge-fill"></i> 
                                <span class="ms-1 d-none d-sm-inline">Panel de Docentes</span> 
                            </a>
                        </li>
                        <li class="w-100">
                            <a href="<%=contextPath%>/alumno/listado.jsp" class="nav-link px-0"> 
                                <i class="fs-4 bi-person-fill"></i> 
                                <span class="ms-1 d-none d-sm-inline">Panel de Estudiantes</span> 
                            </a>
                        </li>                      
                        <li class="w-100">
                            <a href="<%=contextPath%>/horario/listado.jsp" class="nav-link px-0"> 
                                <i class="fs-4 bi-calendar-week-fill"></i> 
                                <span class="ms-1 d-none d-sm-inline">Panel de Horarios</span> 
                            </a>
                        </li>
                        <li class="w-100">
                            <a href="<%=contextPath%>/nota/listado.jsp" class="nav-link px-0"> 
                                <i class="fs-4 bi-journal-check"></i> 
                                <span class="ms-1 d-none d-sm-inline">Panel de Notas</span> 
                            </a>
                        </li>
                        <li class="w-100">
                            <a href="<%=contextPath%>/carrera/listado.jsp" class="nav-link px-0"> 
                                <i class="fs-4 bi-mortarboard-fill"></i> 
                                <span class="ms-1 d-none d-sm-inline">Panel de Carreras</span> 
                            </a>
                        </li>
                        <li class="w-100">
                            <a href="<%=contextPath%>/clase/listado.jsp" class="nav-link px-0"> 
                                <i class="fs-4 bi-house-fill"></i> 
                                <span class="ms-1 d-none d-sm-inline">Panel de Clases</span> 
                            </a>
                        </li>
                        <li class="w-100">
                            <a href="<%=contextPath%>/curso/listado.jsp" class="nav-link px-0"> 
                                <i class="fs-4 bi-book"></i> 
                                <span class="ms-1 d-none d-sm-inline">Panel de Cursos</span> 
                            </a>
                        </li>
                        <li class="w-100">
                            <a href="<%=contextPath%>/facultad/listado.jsp" class="nav-link px-0"> 
                                <i class="fs-4 bi-building-fill"></i> 
                                <span class="ms-1 d-none d-sm-inline">Panel de Facultades</span> 
                            </a>
                        </li>
                        <li class="w-100">
                            <a href="<%=contextPath%>/inscripcion/listado.jsp" class="nav-link px-0"> 
                                <i class="fs-4 bi-pencil-square"></i> 
                                <span class="ms-1 d-none d-sm-inline">Panel de Inscripciones</span> 
                            </a>
                        </li>
                        <li class="w-100">
                            <a href="<%=contextPath%>/pago/listado.jsp" class="nav-link px-0"> 
                                <i class="fs-4 bi-currency-dollar"></i> 
                                <span class="ms-1 d-none d-sm-inline">Panel de Pagos</span> 
                            </a>
                        </li>                     
                    </ul>
                </li>
            </ul>
            
            <hr class="w-100 text-secondary mt-auto"> <div class="dropdown w-100 dropdown-pb-4">
                <a href="#" class="d-flex align-items-center text-white text-decoration-none dropdown-toggle" 
                   id="dropdownUser1" data-bs-toggle="dropdown" aria-expanded="false">
                    <img src="https://github.com/mdo.png" alt="usuario" width="30" height="30" class="rounded-circle">
                    <span class="d-none d-sm-inline mx-1">Usuario</span>
                </a>
                <ul class="dropdown-menu dropdown-menu-dark text-small shadow" aria-labelledby="dropdownUser1">
                    <li><a class="dropdown-item" href="#">Perfil</a></li>
                    <li><a class="dropdown-item" href="#">Configuración</a></li>
                    <li><a class="dropdown-item" href="#">Mi Cuenta</a></li>
                    <li><hr class="dropdown-divider"></li>
                    <li><a class="dropdown-item" href="../Plataforma.jsp">Cerrar sesión</a></li>
                </ul>
            </div>
            
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        // Forzar inicialización del dropdown cuando la página cargue
        document.addEventListener('DOMContentLoaded', function() {
            // Inicializar todos los dropdowns manualmente
            var dropdownElementList = [].slice.call(document.querySelectorAll('.dropdown-toggle'));
            var dropdownList = dropdownElementList.map(function (dropdownToggleEl) {
                return new bootstrap.Dropdown(dropdownToggleEl);
            });
            
            // Alternativa: manejar el click manualmente si Bootstrap no funciona
            const dropdownToggle = document.getElementById('dropdownUser1');
            const dropdownMenu = document.querySelector('.dropdown-menu');
            
            if (dropdownToggle && dropdownMenu) {
                dropdownToggle.addEventListener('click', function(e) {
                    e.preventDefault();
                    dropdownMenu.classList.toggle('show');
                });
                
                // Cerrar dropdown al hacer click fuera
                document.addEventListener('click', function(e) {
                    if (!dropdownToggle.contains(e.target) && !dropdownMenu.contains(e.target)) {
                        dropdownMenu.classList.remove('show');
                    }
                });
            }
        });
    </script>
</body>
</html>