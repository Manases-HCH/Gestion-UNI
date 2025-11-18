<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Lista de Alumnos | Sistema Universitario</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <style>
        /* Your existing custom CSS from previous examples would go here */
        :root {
            --admin-dark: #222B40;
            --admin-light-bg: #F0F2F5;
            --admin-card-bg: #FFFFFF;
            --admin-text-dark: #333333;
            --admin-text-muted: #6C757D;
            --admin-primary: #007BFF;
            --admin-success: #28A745;
            --admin-danger: #DC3545;
            --admin-warning: #FFC107;
            --admin-info: #17A2B8;
            --admin-secondary-color: #6C757D;
        }

        body {
            font-family: 'Inter', sans-serif;
            background-color: var(--admin-light-bg);
            color: var(--admin-text-dark);
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            overflow-x: hidden;
        }

        #app { display: flex; flex: 1; width: 100%; }
        .sidebar { /* ... your sidebar CSS ... */ }
        .top-navbar { /* ... your top-navbar CSS ... */ }
        .main-content { flex: 1; padding: 1.5rem; overflow-y: auto; }
        .welcome-section { /* ... your welcome-section CSS ... */ }
        .content-section {
            background-color: var(--admin-card-bg);
            border-radius: 0.5rem;
            box-shadow: 0 0.125rem 0.25rem rgba(0,0,0,0.075);
            border-left: 4px solid var(--admin-primary);
            padding: 2rem 1.5rem;
            margin-bottom: 2rem;
        }
        .section-title {
            color: var(--admin-primary);
            margin-bottom: 1rem;
            font-weight: 600;
        }
        .table thead th {
            background-color: var(--admin-primary);
            color: white;
            font-weight: 600;
            vertical-align: middle;
            position: sticky;
            top: 0;
            z-index: 1;
        }
        .table tbody tr:hover { background-color: rgba(0, 123, 255, 0.05); }
        .empty-state {
            text-align: center;
            padding: 3rem 1rem;
            color: var(--admin-text-muted);
        }
        .empty-state i {
            font-size: 3rem;
            margin-bottom: 1rem;
            color: var(--admin-secondary-color);
        }
    </style>
</head>
<body>
    <div id="app">
        <nav class="sidebar">
            <div class="sidebar-header">
                <a href="home_profesor.jsp" class="text-white text-decoration-none">UGIC Portal</a>
            </div>
            <ul class="navbar-nav">
                <li class="nav-item"><a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/home_profesor.jsp"><i class="fas fa-chart-line"></i> Dashboard</a></li>
                <li class="nav-item"><a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/facultad_profesor.jsp"><i class="fas fa-building"></i> Facultades</a></li>
                <li class="nav-item"><a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/carreras_profesor.jsp"><i class="fas fa-graduation-cap"></i> Carreras</a></li>
                <li class="nav-item"><a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/cursos_profesor.jsp"><i class="fas fa-book"></i> Cursos</a></li>
                <li class="nav-item"><a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/salones_profesor.jsp"><i class="fas fa-chalkboard"></i> Clases</a></li>
                <li class="nav-item"><a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/horarios_profesor.jsp"><i class="fas fa-calendar-alt"></i> Horarios</a></li>
                <li class="nav-item"><a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/asistencia_profesor.jsp"><i class="fas fa-clipboard-check"></i> Asistencia</a></li>
                <li class="nav-item"><a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/mensaje_profesor.jsp"><i class="fas fa-envelope"></i> Mensajería</a></li>
                <li class="nav-item"><a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/nota_profesor.jsp"><i class="fas fa-percent"></i> Notas</a></li>
                <li class="nav-item mt-3">
                    <form action="<%= request.getContextPath() %>/logout.jsp" method="post" class="d-grid gap-2">
                        <button type="submit" class="btn btn-outline-light mx-3"><i class="fas fa-sign-out-alt me-2"></i>Cerrar sesión</button>
                    </form>
                </li>
            </ul >
        </nav>
        <div class="main-content">
            <nav class="top-navbar">
                <div class="search-bar">
                    <form class="d-flex">
                        <input class="form-control me-2" type="search" placeholder="Buscar..." aria-label="Search">
                        <button class="btn btn-outline-secondary" type="submit"><i class="fas fa-search"></i></button>
                    </form>
                </div>
                <div class="d-flex align-items-center">
                    <div class="me-3 dropdown">
                        <a class="text-dark" href="#" role="button" id="notificationsDropdown" data-bs-toggle="dropdown" aria-expanded="false">
                            <i class="fas fa-bell fa-lg"></i>
                            <span class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger">
                                3
                            </span>
                        </a>
                        <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="notificationsDropdown">
                            <li><a class="dropdown-item" href="#">Nueva nota pendiente</a></li>
                            <li><a class="dropdown-item" href="#">Recordatorio de clase</a></li>
                            <li><hr class="dropdown-divider"></li>
                            <li><a class="dropdown-item" href="#">Ver todas</a></li>
                        </ul>
                    </div>
                    <div class="me-3 dropdown">
                        <a class="text-dark" href="#" role="button" id="messagesDropdown" data-bs-toggle="dropdown" aria-expanded="false">
                            <i class="fas fa-envelope fa-lg"></i>
                            <span class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger">
                                2
                            </span>
                        </a>
                        <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="messagesDropdown">
                            <li><a class="dropdown-item" href="#">Mensaje de Alumno X</a></li>
                            <li><a class="dropdown-item" href="#">Mensaje de Coordinación</a></li>
                            <li><hr class="dropdown-divider"></li>
                            <li><a class="dropdown-item" href="#">Ver todos</a></li>
                        </ul>
                    </div>

                    <div class="dropdown user-dropdown">
                        <a class="dropdown-toggle" href="#" role="button" id="userDropdown" data-bs-toggle="dropdown" aria-expanded="false">
                            <img src="https://via.placeholder.com/32" alt="Avatar"> <span class="d-none d-md-inline-block">Nombre del Profesor</span>
                        </a>
                        <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="userDropdown">
                            <li><a class="dropdown-item" href="#"><i class="fas fa-user me-2"></i>Perfil</a></li>
                            <li><a class="dropdown-item" href="#"><i class="fas fa-cog me-2"></i>Configuración</a></li>
                            <li><hr class="dropdown-divider"></li>
                            <li><a class="dropdown-item" href="logout.jsp"><i class="fas fa-sign-out-alt me-2"></i>Cerrar sesión</a></li>
                        </ul>
                    </div>
                </div>
            </nav>

            <div class="container-fluid">
                <div class="welcome-section">
                    <h1 class="h3 mb-3"><i class="fas fa-user-graduate me-2"></i>Gestión de Alumnos</h1>
                    <p class="lead">Revisa la lista de alumnos activos en tus clases.</p>
                </div>

                <div class="content-section">
                    <h2 class="section-title"><i class="fas fa-users me-2"></i>Mis Alumnos</h2>
                    <div class="table-responsive">
                        <table class="table table-hover table-striped">
                            <thead>
                                <tr>
                                    <th>ID</th>
                                    <th>DNI</th>
                                    <th>Nombre Completo</th>
                                    <th>Email</th>
                                    <th>Acciones</th>
                                </tr>
                            </thead>
                            <tbody id="alumnosTableBody">
                                <tr>
                                    <td colspan="5" class="text-center text-muted">Cargando alumnos...</td>
                                </tr>
                            </tbody>
                        </table>
                        <div id="alumnosEmptyState" class="empty-state d-none">
                            <i class="fas fa-exclamation-circle"></i>
                            <h4>No hay alumnos activos asignados.</h4>
                            <p>Parece que no tienes alumnos inscritos en ninguna de tus clases activas.</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.6.0/jquery.min.js"></script>
    <script>
        $(document).ready(function() {
            const alumnosTableBody = $('#alumnosTableBody');
            const alumnosEmptyState = $('#alumnosEmptyState');

            // Function to load and display students
            function loadStudents() {
                alumnosTableBody.html('<tr><td colspan="5" class="text-center text-muted"><i class="fas fa-spinner fa-spin me-2"></i>Cargando alumnos...</td></tr>');
                alumnosEmptyState.addClass('d-none');

                fetch('<%= request.getContextPath() %>/obtener_alumnos_por_profesor.jsp')
                    .then(response => {
                        if (!response.ok) {
                            throw new Error('Network response was not ok ' + response.statusText);
                        }
                        return response.json();
                    })
                    .then(data => {
                        alumnosTableBody.empty(); // Clear loading message

                        if (data.length === 0) {
                            alumnosEmptyState.removeClass('d-none');
                        } else {
                            data.forEach(alumno => {
                                const row = `
                                    <tr>
                                        <td>${alumno.id_alumno}</td>
                                        <td>${alumno.dni}</td>
                                        <td>${alumno.nombre_completo}</td>
                                        <td>${alumno.email}</td>
                                        <td>
                                            <a href="#" class="btn btn-sm btn-primary me-2" title="Ver Perfil"><i class="fas fa-user"></i></a>
                                            <a href="#" class="btn btn-sm btn-info" title="Enviar Mensaje"><i class="fas fa-envelope"></i></a>
                                        </td>
                                    </tr>
                                `;
                                alumnosTableBody.append(row);
                            });
                        }
                    })
                    .catch(error => {
                        console.error('Error fetching students:', error);
                        alumnosTableBody.html(`
                            <tr>
                                <td colspan="5" class="text-center text-danger">
                                    <i class="fas fa-exclamation-triangle me-2"></i>Error al cargar alumnos: ${error.message}
                                </td>
                            </tr>
                        `);
                        alumnosEmptyState.addClass('d-none'); // Hide if error occurred
                    });
            }

            // Load students when the page is ready
            loadStudents();
        });
    </script>
</body>
</html>