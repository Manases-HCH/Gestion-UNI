<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, pe.universidad.util.Conection" %>
<%@ page import="java.net.URLEncoder" %>
<%@ page session="true" %>

<%!
    // Método auxiliar para cerrar ResultSet y PreparedStatement
    private void closeDbResources(ResultSet rs, PreparedStatement pstmt) {
        try {
            if (rs != null) {
                rs.close();
            }
        } catch (SQLException e) { /* Ignorar al cerrar */ }
        try {
            if (pstmt != null) {
                pstmt.close();
            }
        } catch (SQLException e) { /* Ignorar al cerrar */ }
    }
%>

<%
    // ====================================================================
    // 🧪 FORZAR SESIÓN TEMPORALMENTE PARA APODERADO (SOLO PARA TEST)
    // REMOVER ESTE BLOQUE EN PRODUCCIÓN O CUANDO EL LOGIN REAL FUNCIONE
    if (session.getAttribute("id_apoderado") == null) {
        session.setAttribute("email", "roberto.sanchez@gmail.com"); // Email de un apoderado que exista en tu BD (ID 1 en bd-uni.sql)
        session.setAttribute("rol", "apoderado");
        session.setAttribute("id_apoderado", 1);    // ID del apoderado en tu BD (ej: Roberto Carlos Sánchez Díaz)
        System.out.println("DEBUG (lista_profesores_apoderado): Sesión forzada para prueba.");
    }
    // ====================================================================

    // --- VALIDACIÓN DE SESIÓN ---
    String emailSesion = (String) session.getAttribute("email");
    String rolUsuario = (String) session.getAttribute("rol");
    Object idApoderadoObj = session.getAttribute("id_apoderado");

    if (emailSesion == null || !"apoderado".equalsIgnoreCase(rolUsuario) || idApoderadoObj == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp"); // Redirigir al login si no está autenticado
        return;
    }

    int idApoderado = -1;
    try {
        idApoderado = Integer.parseInt(String.valueOf(idApoderadoObj));
    } catch (NumberFormatException e) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?error=" + URLEncoder.encode("ID de apoderado inválido en sesión.", "UTF-8"));
        return;
    }

    String nombreApoderado = (String) session.getAttribute("nombre_apoderado");
    if (nombreApoderado == null || nombreApoderado.isEmpty()) {
        // Obtener el nombre del apoderado si no está en sesión
        Connection connTemp = null;
        PreparedStatement pstmtTemp = null;
        ResultSet rsTemp = null;
        try {
            connTemp = new Conection().conecta();
            String sqlGetNombre = "SELECT CONCAT(a.nombre, ' ', a.apellido_paterno, ' ', IFNULL(a.apellido_materno, '')) AS nombre_completo FROM apoderados a WHERE id_apoderado = ?";
            pstmtTemp = connTemp.prepareStatement(sqlGetNombre);
            pstmtTemp.setInt(1, idApoderado);
            rsTemp = pstmtTemp.executeQuery();
            if (rsTemp.next()) {
                nombreApoderado = rsTemp.getString("nombre_completo");
                session.setAttribute("nombre_apoderado", nombreApoderado);
            }
        } catch (SQLException | ClassNotFoundException ex) {
            System.err.println("Error al obtener nombre del apoderado en lista_profesores_apoderado.jsp: " + ex.getMessage());
        } finally {
            closeDbResources(rsTemp, pstmtTemp);
            if (connTemp != null) { try { connTemp.close(); } catch (SQLException ignore) {} }
        }
    }

    // --- Obtener ID del hijo asociado al apoderado ---
    int idHijoAsociado = -1;
    Connection connHijo = null;
    PreparedStatement pstmtHijo = null;
    ResultSet rsHijo = null;
    try {
        connHijo = new Conection().conecta();
        String sqlGetHijo = "SELECT id_alumno FROM alumno_apoderado WHERE id_apoderado = ? LIMIT 1";
        pstmtHijo = connHijo.prepareStatement(sqlGetHijo);
        pstmtHijo.setInt(1, idApoderado);
        rsHijo = pstmtHijo.executeQuery();
        if (rsHijo.next()) {
            idHijoAsociado = rsHijo.getInt("id_alumno");
        }
    } catch (SQLException | ClassNotFoundException ex) {
        System.err.println("Error al obtener ID del hijo en lista_profesores_apoderado.jsp: " + ex.getMessage());
    } finally {
        closeDbResources(rsHijo, pstmtHijo);
        if (connHijo != null) { try { connHijo.close(); } catch (SQLException ignore) {} }
    }
%>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Lista de Profesores | Dashboard Apoderado | Sistema Universitario</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    
    <link rel="stylesheet" href="https://code.jquery.com/ui/1.13.2/themes/base/jquery-ui.css">

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
        /* Sidebar styles (copied from your previous JSPs) */
        .sidebar {
            width: 280px; background-color: var(--admin-dark); color: rgba(255,255,255,0.8); padding-top: 1rem; flex-shrink: 0;
            position: sticky; top: 0; left: 0; height: 100vh; overflow-y: auto; box-shadow: 2px 0 5px rgba(0,0,0,0.1); z-index: 1030;
        }
        .sidebar-header { padding: 1rem 1.5rem; margin-bottom: 1.5rem; text-align: center; font-size: 1.5rem; font-weight: 700; color: var(--admin-primary); border-bottom: 1px solid rgba(255,255,255,0.05);}
        .sidebar .nav-link { display: flex; align-items: center; padding: 0.75rem 1.5rem; color: rgba(255,255,255,0.7); text-decoration: none; transition: all 0.2s ease-in-out; font-weight: 500;}
        .sidebar .nav-link i { margin-right: 0.75rem; font-size: 1.1rem;}
        .sidebar .nav-link:hover, .sidebar .nav-link.active { color: white; background-color: rgba(255,255,255,0.08); border-left: 4px solid var(--admin-primary); padding-left: 1.3rem;}

        /* Main Content area */
        .main-content {
            flex: 1;
            padding: 1.5rem;
            overflow-y: auto;
            display: flex;
            flex-direction: column;
        }

        /* Top Navbar styles */
        .top-navbar {
            background-color: var(--admin-card-bg); padding: 1rem 1.5rem; box-shadow: 0 0.125rem 0.25rem rgba(0,0,0,0.075);
            margin-bottom: 1.5rem; border-radius: 0.5rem; display: flex; justify-content: space-between; align-items: center;
        }
        .top-navbar .search-bar .form-control { border: 1px solid #e0e0e0; border-radius: 0.3rem; padding: 0.5rem 1rem; }
        .top-navbar .user-dropdown .dropdown-toggle { display: flex; align-items: center; color: var(--admin-text-dark); text-decoration: none; }
        .top-navbar .user-dropdown .dropdown-toggle img { width: 32px; height: 32px; border-radius: 50%; margin-right: 0.5rem; object-fit: cover; border: 2px solid var(--admin-primary); }

        /* Welcome section */
        .welcome-section {
            background-color: var(--admin-card-bg); border-radius: 0.5rem; padding: 1.5rem; margin-bottom: 1.5rem; box-shadow: 0 0.125rem 0.25rem rgba(0,0,0,0.075);
        }
        .welcome-section h1 { color: var(--admin-text-dark); font-weight: 600; margin-bottom: 0.5rem;}
        .welcome-section p.lead { color: var(--admin-text-muted); font-size: 1rem;}

        /* Content cards */
        .content-section {
            background-color: var(--admin-card-bg); border-radius: 0.5rem; box-shadow: 0 0.125rem 0.25rem rgba(0,0,0,0.075);
            border-left: 4px solid var(--admin-primary); padding: 2rem 1.5rem; margin-bottom: 2rem;
        }
        .section-title { color: var(--admin-primary); margin-bottom: 1rem; font-weight: 600;}

        /* Table styles */
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
        .empty-state h4 {
            color: var(--admin-text-dark);
            font-weight: 500;
            margin-bottom: 1rem;
        }

        /* Custom styling for jQuery UI Autocomplete (to match Bootstrap) */
        .ui-autocomplete {
            max-height: 200px;
            overflow-y: auto;
            overflow-x: hidden;
            border: 1px solid #dee2e6;
            background-color: var(--admin-card-bg);
            box-shadow: 0 0.5rem 1rem rgba(0,0,0,.15)!important;
            padding: 0;
            border-radius: 0.3rem;
            list-style: none; /* Remove bullet points */
            z-index: 1050; /* Ensure it's above other elements */
        }
        .ui-menu-item {
            padding: 0.5rem 1rem;
            cursor: pointer;
            color: var(--admin-text-dark);
            font-size: 0.95rem;
            transition: background-color 0.2s ease;
        }
        .ui-menu-item:hover,
        .ui-menu-item.ui-state-active {
            background-color: var(--admin-primary);
            color: white;
            border-radius: 0.2rem;
        }
        .ui-menu-item .ui-menu-item-wrapper {
            display: flex;
            align-items: center;
        }
        .ui-menu-item .ui-menu-item-wrapper i {
            margin-right: 0.5rem;
            color: rgba(255,255,255,0.7); /* Adjust color if needed */
        }
        .ui-menu-item.ui-state-active .ui-menu-item-wrapper i {
             color: white; /* Icon color when active */
        }

        /* Responsive adjustments */
        @media (max-width: 992px) {
            .sidebar { width: 220px; }
            .main-content { padding: 1rem; }
        }
        @media (max-width: 768px) {
            #app { flex-direction: column; }
            .sidebar {
                width: 100%; height: auto; position: relative;
                box-shadow: 0 2px 5px rgba(0,0,0,0.1); padding-bottom: 0.5rem;
            }
            .main-content { padding: 1rem; }
            .top-navbar { flex-direction: column; align-items: flex-start;}
            .top-navbar .search-bar { width: 100%; margin-bottom: 1rem;}
            .top-navbar .user-dropdown { width: 100%; text-align: center;}
            .top-navbar .user-dropdown .dropdown-toggle { justify-content: center;}
        }
        @media (max-width: 576px) {
            .main-content { padding: 0.75rem; }
            .welcome-section, .content-section { padding: 1rem;}
        }
    </style>
</head>
<body>
    <div id="app">
        <nav class="sidebar">
            <div class="sidebar-header">
                <a href="<%= request.getContextPath() %>/INTERFAZ_APODERADO/home_apoderado.jsp" class="text-white text-decoration-none">UGIC Portal</a>
            </div>
            <ul class="navbar-nav">
                <li class="nav-item">
                    <a class="nav-link" href="<%= request.getContextPath()%>/INTERFAZ_APODERADO/home_apoderado.jsp"><i class="fas fa-home"></i><span> Inicio</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="<%= request.getContextPath()%>/INTERFAZ_APODERADO/cursos_apoderado.jsp"><i class="fas fa-book"></i><span> Cursos de mi hijo</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="<%= request.getContextPath()%>/INTERFAZ_APODERADO/asistencia_apoderado.jsp"><i class="fas fa-clipboard-check"></i><span> Asistencia de mi hijo</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="<%= request.getContextPath()%>/INTERFAZ_APODERADO/notas_apoderado.jsp"><i class="fas fa-percent"></i><span> Notas de mi hijo</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="<%= request.getContextPath()%>/INTERFAZ_APODERADO/pagos_apoderado.jsp"><i class="fas fa-money-bill-wave"></i><span> Pagos y Mensualidades</span></a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="<%= request.getContextPath()%>/INTERFAZ_APODERADO/mensajes_apoderado.jsp"><i class="fas fa-envelope"></i><span> Mensajes</span></a>
                </li>
                <li class="nav-item mt-3">
                    <form action="<%= request.getContextPath() %>/logout.jsp" method="post" class="d-grid gap-2">
                        <button type="submit" class="btn btn-outline-light mx-3"><i class="fas fa-sign-out-alt me-2"></i>Cerrar sesión</button>
                    </form>
                </li>
            </ul>
        </nav>
        <div class="main-content">
            <nav class="top-navbar">
                <div class="search-bar">
                    <form class="d-flex">
                        <input class="form-control me-2" type="search" placeholder="Buscar profesores..." aria-label="Search" id="globalSearchInput">
                        <button class="btn btn-outline-secondary" type="button" id="globalSearchButton"><i class="fas fa-search"></i></button>
                    </form>
                </div>
                <div class="d-flex align-items-center">
                    <div class="me-3 dropdown">
                        <a class="text-dark" href="#" role="button" id="notificationsDropdown" data-bs-toggle="dropdown" aria-expanded="false">
                            <i class="fas fa-bell fa-lg"></i>
                            <span class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger">0</span><%-- Dynamic count for apoderado --%>
                        </a>
                        <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="notificationsDropdown">
                            <li><a class="dropdown-item" href="#">No hay notificaciones</a></li><%-- Dynamic notifications --%>
                        </ul>
                    </div>
                    <div class="me-3 dropdown">
                        <a class="text-dark" href="#" role="button" id="messagesDropdown" data-bs-toggle="dropdown" aria-expanded="false">
                            <i class="fas fa-envelope fa-lg"></i>
                            <span class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger">0</span><%-- Dynamic count for apoderado --%>
                        </a>
                        <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="messagesDropdown">
                            <li><a class="dropdown-item" href="<%= request.getContextPath()%>/INTERFAZ_APODERADO/mensajes_apoderado.jsp">Ver todos los mensajes</a></li>
                        </ul>
                    </div>

                    <div class="dropdown user-dropdown">
                        <a class="dropdown-toggle" href="#" role="button" id="userDropdown" data-bs-toggle="dropdown" aria-expanded="false">
                            <img src="https://via.placeholder.com/32" alt="Avatar"> <span class="d-none d-md-inline-block"><%= nombreApoderado != null ? nombreApoderado : "Apoderado"%></span>
                        </a>
                        <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="userDropdown">
                            <li><a class="dropdown-item" href="#"><i class="fas fa-user me-2"></i>Perfil</a></li>
                            <li><a class="dropdown-item" href="#"><i class="fas fa-cog me-2"></i>Configuración</a></li>
                            <li><hr class="dropdown-divider"></li>
                            <li><a class="dropdown-item" href="<%= request.getContextPath() %>/logout.jsp"><i class="fas fa-sign-out-alt me-2"></i>Cerrar sesión</a></li>
                        </ul>
                    </div>
                </div>
            </nav>

            <div class="container-fluid">
                <div class="welcome-section">
                    <h1 class="h3 mb-3"><i class="fas fa-chalkboard-teacher me-2"></i>Lista de Profesores</h1>
                    <p class="lead">Revisa la lista de profesores de los cursos de tu hijo/a.</p>
                </div>

                <% if (idHijoAsociado == -1) { %>
                    <div class="empty-state">
                        <i class="fas fa-child"></i>
                        <h4>No se encontró un hijo asociado a tu cuenta.</h4>
                        <p>Por favor, contacta a administración para asociar a tu hijo/a. No puedes ver profesores sin un hijo asociado.</p>
                    </div>
                <% } else { %>
                    <div class="content-section">
                        <h2 class="section-title"><i class="fas fa-users-class me-2"></i>Profesores de mi Hijo</h2>
                        <div class="table-responsive">
                            <table class="table table-hover table-striped">
                                <thead>
                                    <tr>
                                        <th>ID</th>
                                        <th>DNI</th>
                                        <th>Nombre Completo</th>
                                        <th>Email</th>
                                        <th>Cursos Dictados</th>
                                        <th>Acciones</th>
                                    </tr>
                                </thead>
                                <tbody id="profesoresTableBody">
                                    <tr>
                                        <td colspan="6" class="text-center text-muted">Cargando profesores...</td>
                                    </tr>
                                </tbody>
                            </table>
                            <div id="profesoresEmptyState" class="empty-state d-none">
                                <i class="fas fa-info-circle"></i>
                                <h4>No hay profesores activos para los cursos de tu hijo/a.</h4>
                                <p>Parece que tu hijo/a no está inscrito en ninguna clase activa o no se han asignado profesores.</p>
                            </div>
                        </div>
                    </div>
                <% } %>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.6.0/jquery.min.js"></script>
    <script src="https://code.jquery.com/ui/1.13.2/jquery-ui.min.js"></script>

    <script>
        $(document).ready(function() {
            const globalSearchInput = $('#globalSearchInput');
            const globalSearchButton = $('#globalSearchButton');
            const profesoresTableBody = $('#profesoresTableBody');
            const profesoresEmptyState = $('#profesoresEmptyState');

            const idHijoAsociado = <%= idHijoAsociado %>; // Pass the child ID to JS

            // Function to display teachers in the table
            function displayTeachers(teachers) {
                profesoresTableBody.empty(); // Clear previous results
                profesoresEmptyState.addClass('d-none'); // Hide empty state

                if (teachers.length === 0) {
                    profesoresEmptyState.removeClass('d-none');
                } else {
                    teachers.forEach(profesor => {
                        const coursesText = profesor.cursos.length > 0 ? profesor.cursos.map(c => `${c.nombre_curso} (${c.seccion})`).join(', ') : 'N/A';
                        const row = `
                            <tr>
                                <td>${profesor.id_profesor}</td>
                                <td>${profesor.dni}</td>
                                <td>${profesor.nombre_completo}</td>
                                <td>${profesor.email}</td>
                                <td>${coursesText}</td>
                                <td>
                                    <a href="<%= request.getContextPath()%>/INTERFAZ_APODERADO/enviar_mensaje_apoderado.jsp?id_profesor=${profesor.id_profesor}&nombre_profesor=${encodeURIComponent(profesor.nombre_completo)}&email_profesor=${encodeURIComponent(profesor.email)}" class="btn btn-sm btn-info" title="Enviar Mensaje"><i class="fas fa-envelope"></i></a>
                                </td>
                            </tr>
                        `;
                        profesoresTableBody.append(row);
                    });
                }
            }

            // Function to fetch teachers based on search term or all teachers of child's courses
            function fetchTeachers(term = '') { // Optional term for initial load
                if (idHijoAsociado === -1) {
                    // Already handled by JSP logic, but good to have client-side guard
                    profesoresTableBody.html('<tr><td colspan="6" class="text-center text-muted">No se puede cargar profesores sin un hijo asociado.</td></tr>');
                    return;
                }

                profesoresTableBody.html('<tr><td colspan="6" class="text-center text-muted"><i class="fas fa-spinner fa-spin me-2"></i>Cargando profesores...</td></tr>');
                profesoresEmptyState.addClass('d-none');

                // Endpoint to fetch teachers (the new JSP that serves JSON)
                const endpointUrl = '<%= request.getContextPath() %>/INTERFAZ_APODERADO/obtener_profesores_json.jsp';
                
                // Add id_hijo to data, and 'term' if provided and long enough
                let requestData = { id_hijo: idHijoAsociado };
                if (term && term.length >= 3) {
                    requestData.term = term;
                }

                $.ajax({
                    url: endpointUrl,
                    data: requestData,
                    dataType: 'json',
                    success: function(data) {
                        displayTeachers(data);
                    },
                    error: function(jqXHR, textStatus, errorThrown) {
                        console.error('Error fetching teachers:', textStatus, errorThrown);
                        profesoresTableBody.html(`
                            <tr>
                                <td colspan="6" class="text-center text-danger">
                                    <i class="fas fa-exclamation-triangle me-2"></i>Error al buscar profesores. Intenta de nuevo.
                                </td>
                            </tr>
                        `);
                        profesoresEmptyState.addClass('d-none');
                    }
                });
            }

            // --- Initial load of all teachers for the child's courses ---
            fetchTeachers(); // Call without term to load all relevant teachers initially

            // --- Global Search Button (top right) ---
            globalSearchButton.on('click', function() {
                const globalSearchTerm = globalSearchInput.val().trim();
                fetchTeachers(globalSearchTerm);
            });

            // --- jQuery UI Autocomplete for global search input ---
            globalSearchInput.autocomplete({
                source: function(request, response) {
                    // Only search if term has at least 3 characters
                    if (request.term.length < 3) {
                        response([]);
                        return;
                    }

                    const endpointUrl = '<%= request.getContextPath() %>/INTERFAZ_APODERADO/obtener_profesores_json.jsp';
                    $.ajax({
                        url: endpointUrl,
                        data: { term: request.term, id_hijo: idHijoAsociado },
                        dataType: 'json',
                        success: function(data) {
                            response($.map(data, function(item) {
                                return {
                                    label: `${item.nombre_completo} (DNI: ${item.dni})`,
                                    value: item.nombre_completo, // What gets put into the input field
                                    profesorData: item // Store the full teacher object
                                };
                            }));
                        },
                        error: function() {
                            console.error("Error fetching autocomplete suggestions.");
                            response([]);
                        }
                    });
                },
                minLength: 3, // Start autocomplete after 3 characters
                select: function(event, ui) {
                    // When an item is selected from autocomplete, display it in the main table
                    displayTeachers([ui.item.profesorData]);
                    globalSearchInput.val(ui.item.value); // Keep input synced
                    return false; // Prevent default action (filling input with label)
                },
                // Optional: Customize how the items are rendered in the autocomplete list
                _renderItem: function(ul, item) {
                    return $("<li>")
                        .append(`<div><i class="fas fa-chalkboard-teacher me-2"></i>${item.label}</div>`)
                        .appendTo(ul);
                }
            });
        });
    </script>
</body>
</html>