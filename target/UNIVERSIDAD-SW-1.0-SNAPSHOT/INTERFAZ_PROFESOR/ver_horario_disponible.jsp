<%@ page contentType="application/json;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, pe.universidad.util.Conection" %>
<%@ page import="java.time.LocalTime, java.time.format.DateTimeFormatter, java.time.format.DateTimeParseException" %>
<%-- Ya no se importan librerías JSON externas --%>

<%!
    // Método auxiliar para cerrar recursos de BD
    private void closeDbResources(ResultSet rs, PreparedStatement pstmt) {
        try {
            if (rs != null) {
                rs.close();
            }
        } catch (SQLException e) { /* Ignorar */ }
        try {
            if (pstmt != null) {
                pstmt.close();
            }
        } catch (SQLException e) { /* Ignorar */ }
    }

    // Método para escapar cadenas para JSON manualmente
    private String escapeJson(String text) {
        if (text == null) {
            return "null";
        }
        // Reemplaza comillas dobles y barras invertidas
        String escapedText = text.replace("\\", "\\\\").replace("\"", "\\\"");
        return "\"" + escapedText + "\"";
    }
%>

<%
    response.setContentType("application/json");
    response.setCharacterEncoding("UTF-8");

    StringBuilder jsonResponse = new StringBuilder(); // Usaremos StringBuilder para construir el JSON
    String status = "error";
    String message = "Error desconocido.";

    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    try {
        // 1. Obtener y validar parámetros
        String idProfesorParam = request.getParameter("idProfesor");
        String diaSemana = request.getParameter("dia");
        String horaInicioStr = request.getParameter("horaInicio");
        String horaFinStr = request.getParameter("horaFin");
        String aula = request.getParameter("aula");
        String anioParam = request.getParameter("anio");
        String semestre = request.getParameter("semestre");

        if (idProfesorParam == null || diaSemana == null || horaInicioStr == null || horaFinStr == null || aula == null || anioParam == null || semestre == null ||
            idProfesorParam.isEmpty() || diaSemana.isEmpty() || horaInicioStr.isEmpty() || horaFinStr.isEmpty() || aula.isEmpty() || anioParam.isEmpty() || semestre.isEmpty()) {
            throw new IllegalArgumentException("Todos los parámetros son requeridos.");
        }

        int idProfesor = Integer.parseInt(idProfesorParam);
        int anio = Integer.parseInt(anioParam);
        LocalTime horaInicio = LocalTime.parse(horaInicioStr);
        LocalTime horaFin = LocalTime.parse(horaFinStr);

        if (horaInicio.isAfter(horaFin) || horaInicio.equals(horaFin)) {
            throw new IllegalArgumentException("La hora de inicio debe ser anterior a la hora de fin.");
        }

        // 2. Conectar a la base de datos
        Conection c = new Conection();
        conn = c.conecta();

        if (conn == null || conn.isClosed()) {
            throw new SQLException("No se pudo establecer conexión a la base de datos.");
        }

        // 3. Verificar Solapamiento con Clases ASIGNADAS (estado = 'activo')
        String sqlCheckClasesAsignadas = "SELECT cl.seccion, cu.nombre_curso, cu.codigo_curso, h.aula " +
                                          "FROM clases cl " +
                                          "JOIN cursos cu ON cl.id_curso = cu.id_curso " +
                                          "JOIN horarios h ON cl.id_horario = h.id_horario " +
                                          "WHERE cl.id_profesor = ? " +
                                          "AND cl.estado = 'activo' " +
                                          "AND h.dia_semana = ? " +
                                          "AND h.aula = ? " +
                                          "AND cl.anio_academico = ? " +
                                          "AND cl.semestre = ? " +
                                          "AND ( (h.hora_inicio < ? AND h.hora_fin > ?) OR (h.hora_inicio = ? AND h.hora_fin = ?) )";

        pstmt = conn.prepareStatement(sqlCheckClasesAsignadas);
        pstmt.setInt(1, idProfesor);
        pstmt.setString(2, diaSemana);
        pstmt.setString(3, aula);
        pstmt.setInt(4, anio);
        pstmt.setString(5, semestre);
        pstmt.setString(6, horaFinStr);
        pstmt.setString(7, horaInicioStr);
        pstmt.setString(8, horaInicioStr);
        pstmt.setString(9, horaFinStr);
        rs = pstmt.executeQuery();

        if (rs.next()) {
            status = "ocupado_clase";
            message = "Ya tienes la clase asignada en este horario y aula.";
            
            // Construir el JSON para el caso de ocupado_clase
            jsonResponse.append("{");
            jsonResponse.append("\"status\":").append(escapeJson(status)).append(",");
            jsonResponse.append("\"message\":").append(escapeJson(message)).append(",");
            jsonResponse.append("\"clase_nombre\":").append(escapeJson(rs.getString("nombre_curso") + " " + rs.getString("seccion"))).append(",");
            jsonResponse.append("\"clase_codigo\":").append(escapeJson(rs.getString("codigo_curso"))).append(",");
            jsonResponse.append("\"clase_aula\":").append(escapeJson(rs.getString("aula")));
            jsonResponse.append("}");
            
            closeDbResources(rs, pstmt);
        } else {
            closeDbResources(rs, pstmt); // Cerrar rs y pstmt después de la primera consulta

            // 4. Verificar Solapamiento con Solicitudes PENDIENTES
            String sqlCheckSolicitudesPendientes = "SELECT curso, seccion, aula FROM solicitudes_clases " +
                                                    "WHERE id_profesor = ? " +
                                                    "AND estado_solicitud = 'pendiente' " +
                                                    "AND dia_semana = ? " +
                                                    "AND aula = ? " +
                                                    "AND anio_academico = ? " +
                                                    "AND semestre = ? " +
                                                    "AND ( (hora_inicio < ? AND hora_fin > ?) OR (hora_inicio = ? AND hora_fin = ?) )";

            pstmt = conn.prepareStatement(sqlCheckSolicitudesPendientes);
            pstmt.setInt(1, idProfesor);
            pstmt.setString(2, diaSemana);
            pstmt.setString(3, aula);
            pstmt.setInt(4, anio);
            pstmt.setString(5, semestre);
            pstmt.setString(6, horaFinStr);
            pstmt.setString(7, horaInicioStr);
            pstmt.setString(8, horaInicioStr);
            pstmt.setString(9, horaFinStr);
            rs = pstmt.executeQuery();

            if (rs.next()) {
                status = "ocupado_solicitud";
                message = "Ya existe una solicitud pendiente para este horario y aula.";

                // Construir el JSON para el caso de ocupado_solicitud
                jsonResponse.append("{");
                jsonResponse.append("\"status\":").append(escapeJson(status)).append(",");
                jsonResponse.append("\"message\":").append(escapeJson(message)).append(",");
                jsonResponse.append("\"solicitud_nombre\":").append(escapeJson(rs.getString("curso") + " " + rs.getString("seccion"))).append(",");
                jsonResponse.append("\"solicitud_aula\":").append(escapeJson(rs.getString("aula"))).append(",");
                jsonResponse.append("\"solicitud_codigo\":").append(escapeJson("N/A")); // No tenemos código de curso en solicitudes_clases
                jsonResponse.append("}");
                
                closeDbResources(rs, pstmt);
            } else {
                status = "libre";
                message = "Horario disponible. Puedes enviar la solicitud.";
                
                // Construir el JSON para el caso de libre
                jsonResponse.append("{");
                jsonResponse.append("\"status\":").append(escapeJson(status)).append(",");
                jsonResponse.append("\"message\":").append(escapeJson(message));
                jsonResponse.append("}");
                
                closeDbResources(rs, pstmt); // Cerrar rs y pstmt si no se encontraron solapamientos
            }
        }

    } catch (NumberFormatException e) {
        status = "error";
        message = "Formato de número inválido para ID o Año: " + e.getMessage();
        response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
        // Construir JSON de error
        jsonResponse.append("{\"status\": \"error\", \"error\": ").append(escapeJson(message)).append("}");
    } catch (IllegalArgumentException e) {
        status = "error";
        message = e.getMessage();
        response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
        // Construir JSON de error
        jsonResponse.append("{\"status\": \"error\", \"error\": ").append(escapeJson(message)).append("}");
    } catch (DateTimeParseException e) {
        status = "error";
        message = "Formato de hora inválido. Usa HH:MM.";
        response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
        // Construir JSON de error
        jsonResponse.append("{\"status\": \"error\", \"error\": ").append(escapeJson(message)).append("}");
    } catch (SQLException e) {
        status = "error";
        message = "Error de base de datos: " + e.getMessage();
        response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        e.printStackTrace();
        // Construir JSON de error
        jsonResponse.append("{\"status\": \"error\", \"error\": ").append(escapeJson(message)).append("}");
    } catch (ClassNotFoundException e) {
        status = "error";
        message = "Error de configuración del driver JDBC.";
        response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        e.printStackTrace();
        // Construir JSON de error
        jsonResponse.append("{\"status\": \"error\", \"error\": ").append(escapeJson(message)).append("}");
    } finally {
        closeDbResources(rs, pstmt); // Asegura cierre final si no se hizo en try/catch
        try {
            if (conn != null) {
                conn.close();
            }
        } catch (SQLException e) { /* Ignorar */ }
    }

    // Escribir la respuesta JSON final (ya se construyó dentro de los bloques try/catch)
    out.print(jsonResponse.toString());
%>