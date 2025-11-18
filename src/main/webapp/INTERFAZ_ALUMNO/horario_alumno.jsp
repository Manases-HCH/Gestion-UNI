<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*, java.util.*, java.time.*, java.time.format.*"%>
<%@ page import="java.sql.*, java.util.*, pe.universidad.util.Conection" %>
<%
    HttpSession sesion = request.getSession(false);
    if (sesion == null || sesion.getAttribute("id_alumno") == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    int idAlumno = (int) sesion.getAttribute("id_alumno");
    String nombreAlumno = (String) sesion.getAttribute("nombre_alumno");
    LocalDate hoy = LocalDate.now();
    int anioActual = hoy.getYear();
    int mesActual = hoy.getMonthValue();
    String nombreMesActual = hoy.getMonth().getDisplayName(TextStyle.FULL, new Locale("es", "ES"));

    List<Map<String, String>> clasesParaCalendario = new ArrayList<>();

    try {
        Conection c = new Conection();
        Connection conn = c.conecta();

        String sql = "SELECT cl.id_clase, cu.nombre_curso, cl.seccion, h.dia_semana, h.hora_inicio, h.hora_fin, h.aula "
                   + "FROM inscripciones i "
                   + "JOIN clases cl ON i.id_clase = cl.id_clase "
                   + "JOIN cursos cu ON cl.id_curso = cu.id_curso "
                   + "JOIN horarios h ON cl.id_horario = h.id_horario "
                   + "WHERE i.id_alumno = ? AND i.estado = 'inscrito' AND cl.estado = 'activo' "
                   + "ORDER BY h.dia_semana, h.hora_inicio";

        PreparedStatement pstmt = conn.prepareStatement(sql);
        pstmt.setInt(1, idAlumno);
        ResultSet rs = pstmt.executeQuery();

        while (rs.next()) {
            Map<String, String> clase = new HashMap<>();
            clase.put("nombre_curso", rs.getString("nombre_curso"));
            clase.put("seccion", rs.getString("seccion"));
            clase.put("dia_semana", rs.getString("dia_semana").toLowerCase());
            clase.put("hora_inicio", rs.getString("hora_inicio").substring(0, 5));
            clase.put("hora_fin", rs.getString("hora_fin").substring(0, 5));
            clase.put("aula", rs.getString("aula"));
            clasesParaCalendario.add(clase);
        }
        rs.close(); pstmt.close(); conn.close();
    } catch (Exception e) {
        e.printStackTrace();
    }
%>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Horario de Clases</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css">
    <script src="https://kit.fontawesome.com/a076d05399.js" crossorigin="anonymous"></script>
    <style>
        .calendar-display {
            border: 1px solid #ddd;
            border-radius: 10px;
            padding: 20px;
            background: white;
        }

        .calendar-days-header {
            font-weight: bold;
        }

        .calendar-grid-dynamic {
            display: grid;
            grid-template-columns: repeat(7, 1fr);
            gap: 10px;
        }

        .day-cell {
            background-color: #f9f9f9;
            border: 1px solid #ccc;
            border-radius: 6px;
            padding: 10px;
            min-height: 100px;
            position: relative;
        }

        .day-number {
            font-weight: bold;
        }

        .class-indicator {
            display: block;
            font-size: 0.8rem;
            background: #007bff;
            color: white;
            padding: 2px 4px;
            border-radius: 4px;
            margin-top: 5px;
        }

        .has-classes {
            background: #e0f7fa;
        }

        .current-day {
            border: 2px solid #007bff;
        }
    </style>
    <style>
    .sidebar {
        position: fixed;
        top: 0;
        left: 0;
        width: 260px;
        height: 100vh;
        background: linear-gradient(to bottom, #2F4F4F, #36454F);
        padding: 20px;
        box-shadow: 2px 0 10px rgba(0, 0, 0, 0.2);
        z-index: 1000;
        overflow-y: auto;
    }

    .sidebar-header {
        font-size: 1.6rem;
        font-weight: 700;
        color: #fff;
        text-align: center;
        margin-bottom: 30px;
        font-family: 'Montserrat', sans-serif;
        border-bottom: 2px solid rgba(255, 255, 255, 0.2);
        padding-bottom: 10px;
    }

    .nav-link {
        color: #dfe6e9;
        font-weight: 500;
        display: flex;
        align-items: center;
        padding: 12px 16px;
        border-radius: 8px;
        transition: background 0.3s ease, color 0.3s ease;
    }

    .nav-link i {
        margin-right: 10px;
        font-size: 1.1rem;
    }

    .nav-link:hover {
        background: rgba(255, 255, 255, 0.1);
        color: #fff;
    }

    .nav-link.active {
        background: #20B2AA;
        color: #fff !important;
        box-shadow: 0 0 10px rgba(32, 178, 170, 0.5);
    }

    .nav-item + .nav-item {
        margin-top: 10px;
    }

    .mt-auto {
        margin-top: auto;
    }

    body {
        margin-left: 260px; /* Para evitar que el contenido se solape con el sidebar */
    }
</style>
</head>
<body>
    <nav class="sidebar">
            <div class="sidebar-header">Portal UGIC</div>
            <ul class="nav flex-column mt-3">
                <li class="nav-item"><a class="nav-link active" href="home_alumno.jsp"><i class="fas fa-home fa-fw me-2"></i>Inicio</a></li>
                <li class="nav-item"><a class="nav-link" href="cursos_alumno.jsp"><i class="fas fa-book fa-fw me-2"></i>Mis Cursos</a></li>
                <li class="nav-item"><a class="nav-link" href="asistencia_alumno.jsp"><i class="fas fa-clipboard-check fa-fw me-2"></i>Mi Asistencia</a></li>
                <li class="nav-item"><a class="nav-link" href="notas_alumno.jsp"><i class="fas fa-percent fa-fw me-2"></i>Mis Notas</a></li>
                <li class="nav-item"><a class="nav-link" href="pagos_alumno.jsp"><i class="fas fa-money-bill-wave fa-fw me-2"></i>Mis Pagos</a></li>
                <li class="nav-item"><a class="nav-link" href="mensajes_alumno.jsp"><i class="fas fa-envelope fa-fw me-2"></i>Mensajes</a></li>
                <li class="nav-item"><a class="nav-link" href="perfil_alumno.jsp"><i class="fas fa-user-circle fa-fw me-2"></i>Mi Perfil</a></li>
                <li class="nav-item"><a class="nav-link" href="configuracion_alumno.jsp"><i class="fas fa-cog fa-fw me-2"></i>Configuración</a></li>
                <li class="nav-item mt-auto"><a class="nav-link" href="logout.jsp"><i class="fas fa-sign-out-alt fa-fw me-2"></i>Cerrar Sesión</a></li>
            </ul>
        </nav>
    <div class="container mt-4">
        <div class="card">
            <div class="card-header">
                <h3><i class="fas fa-calendar-check me-2"></i>Mi Horario de Clases</h3>
                <p class="text-muted mb-0"><small>Clases para <%= nombreMesActual %> de <%= anioActual %>.</small></p>
            </div>
            <div class="card-body">
                <div class="calendar-display">
                    <div class="calendar-days-header d-flex text-center mb-2">
                        <div class="flex-fill">Dom</div>
                        <div class="flex-fill">Lun</div>
                        <div class="flex-fill">Mar</div>
                        <div class="flex-fill">Mié</div>
                        <div class="flex-fill">Jue</div>
                        <div class="flex-fill">Vie</div>
                        <div class="flex-fill">Sáb</div>
                    </div>
                    <div class="calendar-grid-dynamic" id="calendarGridDynamic"></div>
                </div>
            </div>
        </div>
    </div>

    <script>
        const clasesParaCalendario = [
<%
    for (int i = 0; i < clasesParaCalendario.size(); i++) {
        Map<String, String> clase = clasesParaCalendario.get(i);
        out.print("{");
        out.print("nombre_curso: '" + clase.get("nombre_curso").replace("'", "\\'") + "', ");
        out.print("seccion: '" + clase.get("seccion") + "', ");
        out.print("dia_semana: '" + clase.get("dia_semana") + "', ");
        out.print("hora_inicio: '" + clase.get("hora_inicio") + "', ");
        out.print("hora_fin: '" + clase.get("hora_fin") + "', ");
        out.print("aula: '" + clase.get("aula") + "'");
        out.print("}");
        if (i < clasesParaCalendario.size() - 1) {
            out.print(", ");
        }
    }
%>
];

        const diasSemanaMap = {
            'domingo': 0, 'lunes': 1, 'martes': 2,
            'miercoles': 3, 'jueves': 4, 'viernes': 5, 'sabado': 6
        };

        const calendarGridDynamic = document.getElementById('calendarGridDynamic');
        const today = new Date();
        const year = today.getFullYear();
        const month = today.getMonth();
        const todayDay = today.getDate();

        function getDaysInMonth(year, month) {
            return new Date(year, month + 1, 0).getDate();
        }

        function getFirstDayIndex(year, month) {
            return new Date(year, month, 1).getDay();
        }

        const numDays = getDaysInMonth(year, month);
        const firstDayIndex = getFirstDayIndex(year, month);

        for (let i = 0; i < firstDayIndex; i++) {
            const empty = document.createElement('div');
            empty.classList.add('day-cell', 'other-month');
            calendarGridDynamic.appendChild(empty);
        }

        for (let day = 1; day <= numDays; day++) {
            const date = new Date(year, month, day);
            const dayOfWeek = date.getDay();
            const dayDiv = document.createElement('div');
            dayDiv.classList.add('day-cell');
            if (day === todayDay) dayDiv.classList.add('current-day');

            const dayNumber = document.createElement('span');
            dayNumber.classList.add('day-number');
            dayNumber.textContent = day;
            dayDiv.appendChild(dayNumber);

            const clasesHoy = clasesParaCalendario.filter(c => diasSemanaMap[c.dia_semana] === dayOfWeek);
            if (clasesHoy.length > 0) {
                dayDiv.classList.add('has-classes');
                clasesHoy.slice(0, 2).forEach(clase => {
                    const short = document.createElement('span');
                    short.classList.add('class-indicator');
                    short.textContent = `${clase.nombre_curso.split(' ')[0]} (${clase.hora_inicio})`;
                    dayDiv.appendChild(short);
                });
            }

            calendarGridDynamic.appendChild(dayDiv);
        }
    </script>
</body>
</html>
    