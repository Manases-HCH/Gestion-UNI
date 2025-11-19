<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, pe.universidad.util.Conection" %>
<%@ page import="java.time.LocalDate, java.time.format.TextStyle, java.util.Locale" %>
<%@ page import="java.util.List, java.util.ArrayList, java.util.HashMap, java.util.Map" %>
<%@ page session="true" %>

<%!
    // Helper method to parse a string to Double, returning null if empty or invalid
    private Double parseGrade(String gradeStr) {
        if (gradeStr == null || gradeStr.trim().isEmpty()) {
            return null;
        }
        try {
            double grade = Double.parseDouble(gradeStr.trim());
            // Optional: enforce range 0-20 if not already done by DB checks
            return Math.max(0.00, Math.min(20.00, grade));
        } catch (NumberFormatException e) {
            return null; // Or throw an exception for clearer error handling
        }
    }

    // Helper method to close database resources
    private void closeDbResources(ResultSet rs, PreparedStatement pstmt) {
        try {
            if (rs != null) {
                rs.close();
            }
        } catch (SQLException e) { /* Ignore */ }
        try {
            if (pstmt != null) {
                pstmt.close();
            }
        } catch (SQLException e) { /* Ignore */ }
    }
%>

<%
    // --- Session Validation ---
    Object idObj = session.getAttribute("id_profesor");
    String rolUsuario = (String) session.getAttribute("rol"); // Ensure rol is checked
    int idProfesor = -1;

    if (idObj == null || !"profesor".equalsIgnoreCase(rolUsuario)) {
        response.sendRedirect(request.getContextPath() + "/login.jsp"); // Adjust to your login page
        return;
    }

    idProfesor = Integer.parseInt(idObj.toString());

    String nombreProfesor = (String) session.getAttribute("nombre_profesor");
    if (nombreProfesor == null || nombreProfesor.isEmpty()) {
        // Fetch professor's name if not in session (e.g., direct access or session refresh)
        Connection connTemp = null;
        PreparedStatement pstmtTemp = null;
        ResultSet rsTemp = null;
        try {
            connTemp = new Conection().conecta();
            String sqlGetNombre = "SELECT CONCAT(p.nombre, ' ', p.apellido_paterno, ' ', IFNULL(p.apellido_materno, '')) AS nombre_completo FROM profesores WHERE id_profesor = ?";
            pstmtTemp = connTemp.prepareStatement(sqlGetNombre);
            pstmtTemp.setInt(1, idProfesor);
            rsTemp = pstmtTemp.executeQuery();
            if (rsTemp.next()) {
                nombreProfesor = rsTemp.getString("nombre_completo");
                session.setAttribute("nombre_profesor", nombreProfesor); // Store for future use
            }
        } catch (SQLException | ClassNotFoundException ex) {
            System.err.println("Error al obtener nombre del profesor: " + ex.getMessage());
        } finally {
            closeDbResources(rsTemp, pstmtTemp);
            if (connTemp != null) { try { connTemp.close(); } catch (SQLException ignore) {} }
        }
    }

    String emailProfesor = (String) session.getAttribute("email"); // Get email from session
    String facultadProfesor = "No asignada"; // Default value

    // --- Variables for grade logic ---
    String idClaseParam = request.getParameter("id_clase");
    String nombreClase = "Clase No Seleccionada";
    String codigoClase = "";
    String aulaClase = "";
    String semestreClase = "";
    String anioAcademicoClase = "";
    
    // Lists to store data
    List<Map<String, String>> clasesDelProfesor = new ArrayList<>();
    List<Map<String, String>> estudiantesDeClase = new ArrayList<>();
    
    // Feedback messages after saving
    String mensajeFeedback = "";
    String tipoMensajeFeedback = ""; // 'success' or 'danger'

    // --- Database Connection and Resources ---
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    try {
        Conection conexionUtil = new Conection();
        conn = conexionUtil.conecta();

        // 1. Get basic professor information (needed for sidebar/header, already fetched at top, but ensure it's here)
        // Re-fetching facultades because it might not be in session
        String sqlProfesorInfo = "SELECT p.email, f.nombre_facultad as facultad FROM profesores p LEFT JOIN facultades f ON p.id_facultad = f.id_facultad WHERE p.id_profesor = ?";
        pstmt = conn.prepareStatement(sqlProfesorInfo);
        pstmt.setInt(1, idProfesor);
        rs = pstmt.executeQuery();
        if (rs.next()) {
            emailProfesor = rs.getString("email");
            facultadProfesor = rs.getString("facultad") != null ? rs.getString("facultad") : "No asignada";
        }
        closeDbResources(rs, pstmt);

        // --- START POST Processing Logic (Save Grades) ---
        if ("POST".equalsIgnoreCase(request.getMethod()) && idClaseParam != null && !idClaseParam.isEmpty()) {
            int idClaseGuardar = Integer.parseInt(idClaseParam);
            
            // Re-verify that this class belongs to the logged-in professor before saving
            String sqlCheckClass = "SELECT COUNT(*) FROM clases WHERE id_clase = ? AND id_profesor = ?";
            pstmt = conn.prepareStatement(sqlCheckClass);
            pstmt.setInt(1, idClaseGuardar);
            pstmt.setInt(2, idProfesor);
            rs = pstmt.executeQuery();
            if (rs.next() && rs.getInt(1) == 0) {
                mensajeFeedback = "Error: La clase seleccionada no es válida o no le pertenece.";
                tipoMensajeFeedback = "danger";
                response.sendRedirect(request.getContextPath() + "/INTERFAZ_PROFESOR/nota_profesor.jsp?mensaje=" + java.net.URLEncoder.encode(mensajeFeedback, "UTF-8") + "&tipo=" + tipoMensajeFeedback);
                return;
            }
            closeDbResources(rs, pstmt);

            // Get all id_inscripcion for students in this class
            String sqlInscripcionesClase = "SELECT id_inscripcion FROM inscripciones WHERE id_clase = ? AND estado = 'inscrito'";
            pstmt = conn.prepareStatement(sqlInscripcionesClase);
            pstmt.setInt(1, idClaseGuardar);
            rs = pstmt.executeQuery();
            
            List<Integer> idsInscripcionEnClase = new ArrayList<>();
            while(rs.next()) {
                idsInscripcionEnClase.add(rs.getInt("id_inscripcion"));
            }
            closeDbResources(rs, pstmt);

            int notasAfectadas = 0;
            conn.setAutoCommit(false); // Start transaction

            String sqlCheckNotaExists = "SELECT id_nota FROM notas WHERE id_inscripcion = ?";
            String sqlInsertNota = "INSERT INTO notas (id_inscripcion, nota1, nota2, nota3, examen_parcial, examen_final) VALUES (?, ?, ?, ?, ?, ?)";
            String sqlUpdateNota = "UPDATE notas SET nota1 = ?, nota2 = ?, nota3 = ?, examen_parcial = ?, examen_final = ? WHERE id_inscripcion = ?";

            for (Integer idInscripcion : idsInscripcionEnClase) {
                String nota1Str = request.getParameter("nota1_" + idInscripcion);
                String nota2Str = request.getParameter("nota2_" + idInscripcion);
                String nota3Str = request.getParameter("nota3_" + idInscripcion);
                String examenParcialStr = request.getParameter("examen_parcial_" + idInscripcion);
                String examenFinalStr = request.getParameter("examen_final_" + idInscripcion);

                Double nota1 = parseGrade(nota1Str);
                Double nota2 = parseGrade(nota2Str);
                Double nota3 = parseGrade(nota3Str);
                Double examenParcial = parseGrade(examenParcialStr);
                Double examenFinal = parseGrade(examenFinalStr);
                
                // Check if a note record exists for this inscription
                boolean noteExists = false;
                pstmt = conn.prepareStatement(sqlCheckNotaExists);
                pstmt.setInt(1, idInscripcion);
                rs = pstmt.executeQuery();
                if (rs.next()) {
                    noteExists = true;
                }
                closeDbResources(rs, pstmt);

                if (noteExists) {
                    // Update existing record
                    pstmt = conn.prepareStatement(sqlUpdateNota);
                    if (nota1 != null) pstmt.setDouble(1, nota1); else pstmt.setNull(1, Types.DECIMAL);
                    if (nota2 != null) pstmt.setDouble(2, nota2); else pstmt.setNull(2, Types.DECIMAL);
                    if (nota3 != null) pstmt.setDouble(3, nota3); else pstmt.setNull(3, Types.DECIMAL);
                    if (examenParcial != null) pstmt.setDouble(4, examenParcial); else pstmt.setNull(4, Types.DECIMAL);
                    if (examenFinal != null) pstmt.setDouble(5, examenFinal); else pstmt.setNull(5, Types.DECIMAL);
                    pstmt.setInt(6, idInscripcion);
                    pstmt.executeUpdate();
                    notasAfectadas++;
                } else {
                    // Insert new record only if at least one grade is provided
                    if (nota1 != null || nota2 != null || nota3 != null || examenParcial != null || examenFinal != null) {
                        pstmt = conn.prepareStatement(sqlInsertNota);
                        pstmt.setInt(1, idInscripcion);
                        if (nota1 != null) pstmt.setDouble(2, nota1); else pstmt.setNull(2, Types.DECIMAL);
                        if (nota2 != null) pstmt.setDouble(3, nota2); else pstmt.setNull(3, Types.DECIMAL);
                        if (nota3 != null) pstmt.setDouble(4, nota3); else pstmt.setNull(4, Types.DECIMAL);
                        if (examenParcial != null) pstmt.setDouble(5, examenParcial); else pstmt.setNull(5, Types.DECIMAL);
                        if (examenFinal != null) pstmt.setDouble(6, examenFinal); else pstmt.setNull(6, Types.DECIMAL);
                        pstmt.executeUpdate();
                        notasAfectadas++;
                    }
                }
                if (pstmt != null) { try { pstmt.close(); } catch (SQLException ignore) {} } // Close after each use
            }
            conn.commit(); // Commit transaction
            mensajeFeedback = "Notas guardadas exitosamente para " + notasAfectadas + " alumnos.";
            tipoMensajeFeedback = "success";

            // Redirect to clear POST data and show message
            response.sendRedirect(request.getContextPath() + "/INTERFAZ_PROFESOR/nota_profesor.jsp?id_clase=" + idClaseParam + "&mensaje=" + java.net.URLEncoder.encode(mensajeFeedback, "UTF-8") + "&tipo=" + tipoMensajeFeedback);
            return;

        } // End of POST processing block

        // Retrieve feedback message if coming from a previous redirection
        String mensajeParam = request.getParameter("mensaje");
        String tipoParam = request.getParameter("tipo");
        if (mensajeParam != null && !mensajeParam.isEmpty()) {
            mensajeFeedback = java.net.URLDecoder.decode(mensajeParam, "UTF-8");
            tipoMensajeFeedback = tipoParam != null ? tipoParam : "";
        }

        // --- START Display Logic (GET or after POST) ---
        if (idClaseParam == null || idClaseParam.isEmpty()) {
            // If no class selected, list all classes for the professor
            String sqlClasesProfesor = "SELECT cl.id_clase, cu.nombre_curso, cl.seccion, cl.semestre, cl.año_academico, h.aula " +
                                       "FROM clases cl " +
                                       "JOIN cursos cu ON cl.id_curso = cu.id_curso " +
                                       "JOIN horarios h ON cl.id_horario = h.id_horario " +
                                       "WHERE cl.id_profesor = ? AND cl.estado = 'activo' " +
                                       "ORDER BY cl.año_academico DESC, cl.semestre DESC, cu.nombre_curso, cl.seccion";
            pstmt = conn.prepareStatement(sqlClasesProfesor);
            pstmt.setInt(1, idProfesor);
            rs = pstmt.executeQuery();
            while (rs.next()) {
                Map<String, String> clase = new HashMap<>();
                clase.put("id_clase", String.valueOf(rs.getInt("id_clase")));
                clase.put("nombre_curso", rs.getString("nombre_curso"));
                clase.put("seccion", rs.getString("seccion"));
                clase.put("semestre", rs.getString("semestre"));
                clase.put("anio_academico", String.valueOf(rs.getInt("año_academico")));
                clase.put("aula", rs.getString("aula"));
                clasesDelProfesor.add(clase);
            }
            closeDbResources(rs, pstmt);

        } else {
            // If a class is selected, show its students and grades
            int idClaseMostar = Integer.parseInt(idClaseParam);
            // Get selected class details
            String sqlDetalleClase = "SELECT cu.nombre_curso, cu.codigo_curso, cl.seccion, h.aula, cl.semestre, cl.año_academico " +
                                     "FROM clases cl " +
                                     "JOIN cursos cu ON cl.id_curso = cu.id_curso " +
                                     "JOIN horarios h ON cl.id_horario = h.id_horario " +
                                     "WHERE cl.id_clase = ? AND cl.id_profesor = ?";
            pstmt = conn.prepareStatement(sqlDetalleClase);
            pstmt.setInt(1, idClaseMostar);
            pstmt.setInt(2, idProfesor);
            rs = pstmt.executeQuery();
            if (rs.next()) {
                nombreClase = rs.getString("nombre_curso");
                codigoClase = rs.getString("codigo_curso");
                aulaClase = rs.getString("aula");
                semestreClase = rs.getString("semestre");
                anioAcademicoClase = String.valueOf(rs.getInt("año_academico"));
            } else {
                // If the class doesn't belong to this professor or doesn't exist, redirect
                response.sendRedirect(request.getContextPath() + "/INTERFAZ_PROFESOR/nota_profesor.jsp");
                return;
            }
            closeDbResources(rs, pstmt);

            // Get list of students enrolled in the selected class and their grades
            String sqlEstudiantes = "SELECT a.id_alumno, a.dni, a.nombre, a.apellido_paterno, a.apellido_materno, " +
                                    "i.id_inscripcion, n.nota1, n.nota2, n.nota3, n.examen_parcial, n.examen_final, n.nota_final, n.estado " +
                                    "FROM inscripciones i " +
                                    "JOIN alumnos a ON i.id_alumno = a.id_alumno " +
                                    "LEFT JOIN notas n ON i.id_inscripcion = n.id_inscripcion " +
                                    "WHERE i.id_clase = ? AND i.estado = 'inscrito' " +
                                    "ORDER BY a.apellido_paterno, a.apellido_materno, a.nombre";
            pstmt = conn.prepareStatement(sqlEstudiantes);
            pstmt.setInt(1, idClaseMostar);
            rs = pstmt.executeQuery();
            
            while (rs.next()) {
                Map<String, String> estudiante = new HashMap<>();
                estudiante.put("id_inscripcion", String.valueOf(rs.getInt("id_inscripcion")));
                estudiante.put("dni", rs.getString("dni") != null ? rs.getString("dni") : "");
                String studentName = rs.getString("nombre") + " " + rs.getString("apellido_paterno");
                if (rs.getString("apellido_materno") != null) {
                    studentName += " " + rs.getString("apellido_materno");
                }
                estudiante.put("nombre_completo", studentName);
                estudiante.put("nota1", rs.getString("nota1") != null ? rs.getString("nota1") : "");
                estudiante.put("nota2", rs.getString("nota2") != null ? rs.getString("nota2") : "");
                estudiante.put("nota3", rs.getString("nota3") != null ? rs.getString("nota3") : "");
                estudiante.put("examen_parcial", rs.getString("examen_parcial") != null ? rs.getString("examen_parcial") : "");
                estudiante.put("examen_final", rs.getString("examen_final") != null ? rs.getString("examen_final") : "");
                
                double notaFinalVal = rs.getDouble("nota_final");
                // Check for SQL NULL vs. actual 0.0 value or if it was not calculated
                if (rs.wasNull()) {
                    estudiante.put("nota_final", "N/A"); // No final grade calculated yet or is null
                } else {
                    estudiante.put("nota_final", String.format(Locale.US, "%.2f", notaFinalVal)); // Format to 2 decimal places
                }

                String estadoNota = rs.getString("estado"); // 'aprobado', 'desaprobado', or null/empty
                estudiante.put("estado_nota", estadoNota != null ? estadoNota : "Pendiente"); // Default to "Pendiente"
                estudiantesDeClase.add(estudiante);
            }
            closeDbResources(rs, pstmt);
        }

    } catch (Exception e) { // Catch any exception that occurs
        System.err.println("ERROR general en nota_profesor.jsp: " + e.getMessage());
        e.printStackTrace();
        mensajeFeedback = "Ocurrió un error inesperado al cargar o guardar notas: " + e.getMessage();
        tipoMensajeFeedback = "danger";
        try { if (conn != null) conn.rollback(); } catch (SQLException rbex) { System.err.println("Error al hacer rollback: " + rbex.getMessage()); }
    } finally {
        // Ensure resources are closed
        try { if (rs != null) rs.close(); } catch (SQLException e) { e.printStackTrace(); }
        try { if (pstmt != null) pstmt.close(); } catch (SQLException e) { e.printStackTrace(); }
        try { if (conn != null) { conn.setAutoCommit(true); conn.close(); } } catch (SQLException e) { e.printStackTrace(); } // Reset auto-commit and close
    }
%>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Notas de Alumnos | Sistema Universitario</title>
    <link rel="icon" type="image/x-icon" href="<%= request.getContextPath() %>/img/favicon.ico"> <%-- Assuming favicon.ico exists in your img folder --%>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        /* Consistent AdminKit-like CSS variables */
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

        #app {
            display: flex;
            flex: 1;
            width: 100%;
        }

        /* Sidebar styles */
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

        /* Content section cards */
        .content-section.card {
            border-radius: 0.5rem;
            box-shadow: 0 0.125rem 0.25rem rgba(0,0,0,0.075);
            margin-bottom: 1.5rem;
        }
        .content-section.card.prof-info { border-left: 4px solid var(--admin-primary); }
        .content-section.card.class-selection { border-left: 4px solid var(--admin-info); } /* Cyan for class selection */
        .content-section.card.grades-form { border-left: 4px solid var(--admin-success); } /* Green for grades form */
        .content-section.card.report-section { border-left: 4px solid var(--admin-warning); } /* Yellow for reports */


        .section-title {
            color: var(--admin-primary);
            margin-bottom: 1rem;
            font-weight: 600;
        }

        /* Professor Info Card */
        .profesor-info-card .card-title { color: var(--admin-text-dark); }
        .profesor-info-card .card-body p strong { color: var(--admin-text-dark); }


        /* Class Selection Cards (for class list) */
        .class-select-card {
            cursor: pointer;
            transition: all 0.2s ease-in-out;
            border: 1px solid #e0e0e0;
            border-left: 5px solid var(--admin-primary);
            background-color: var(--admin-card-bg);
            border-radius: 0.5rem;
        }
        .class-select-card:hover {
            transform: translateY(-3px);
            box-shadow: 0 0.25rem 0.5rem rgba(0,0,0,0.1);
            border-color: var(--admin-info); /* Highlight on hover */
        }
        .class-select-card .card-title {
            font-weight: 600;
            color: var(--admin-primary);
        }
        .class-select-card .card-text {
            font-size: 0.9rem;
            color: var(--admin-text-muted);
        }
        .class-select-card .action-icon {
            font-size: 1.5rem;
            color: var(--admin-primary);
        }

        /* Grades Table */
        .table-grades thead th {
            background-color: var(--admin-primary);
            color: white;
            font-weight: 600;
            vertical-align: middle;
            position: sticky; /* Sticky header */
            top: 0;
            z-index: 1;
        }
        .table-grades tbody td, .table-grades tbody th {
            vertical-align: middle;
        }
        .table-grades tbody tr:hover { background-color: rgba(0, 123, 255, 0.05); }

        .form-control-grade { /* Specific style for grade input fields */
            width: 75px; /* Narrower width */
            padding: 0.375rem 0.75rem; /* Smaller padding */
            font-size: 0.875rem; /* Smaller font size */
            text-align: center;
            border: 1px solid #ced4da;
            border-radius: 0.25rem;
        }
        .form-control-grade:focus {
            border-color: var(--admin-primary);
            box-shadow: 0 0 0 0.25rem rgba(0, 123, 255, 0.25);
        }

        /* Buttons */
        .btn-action-custom { /* Used for "Administrar Notas", "Volver a Clases", "Ir a Reportes" */
            background-color: var(--admin-primary);
            color: white;
            border: none;
            padding: 0.6rem 1.2rem;
            border-radius: 0.3rem;
            cursor: pointer;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 0.5rem;
            transition: background-color 0.3s ease, transform 0.2s ease;
        }
        .btn-action-custom:hover {
            background-color: #0056b3;
            color: white;
            transform: translateY(-2px);
        }
        .btn-action-custom.btn-secondary { /* For secondary actions */
             background-color: var(--admin-secondary-color);
        }
        .btn-action-custom.btn-secondary:hover {
            background-color: #5a6268;
        }
        .btn-action-custom.btn-primary { /* Explicit primary for form submit */
            background-color: var(--admin-primary);
        }
        .btn-action-custom.btn-primary:hover {
            background-color: #0056b3;
        }
        .btn-action-custom.btn-warning-report { /* Specific for report button */
            background-color: var(--admin-warning);
            color: var(--admin-text-dark); /* Darker text for warning */
        }
        .btn-action-custom.btn-warning-report:hover {
            background-color: #e0a800; /* Darker yellow */
        }


        /* Feedback messages (Bootstrap alerts) */
        .alert-custom {
            padding: 1rem 1.5rem;
            margin-bottom: 1.5rem;
            border-radius: 0.375rem;
        }
        .alert-success-custom {
            color: var(--admin-success);
            background-color: rgba(40, 167, 69, 0.1);
            border-color: var(--admin-success);
        }
        .alert-danger-custom {
            color: var(--admin-danger);
            background-color: rgba(220, 53, 69, 0.1);
            border-color: var(--admin-danger);
        }

        /* Badge for notes status */
        .badge {
            display: inline-block;
            padding: .35em .65em;
            font-size: .75em;
            font-weight: 700;
            line-height: 1;
            color: #fff;
            text-align: center;
            white-space: nowrap;
            vertical-align: baseline;
            border-radius: .25rem;
        }
        .badge.bg-success { background-color: var(--admin-success) !important; }
        .badge.bg-danger { background-color: var(--admin-danger) !important; }
        .badge.bg-secondary { background-color: var(--admin-secondary-color) !important; }

        /* No data message */
        .no-data-message {
            text-align: center;
            padding: 2rem;
            color: var(--admin-text-muted);
            font-style: italic;
            font-size: 1.1rem;
        }
        .no-data-message i {
            font-size: 2.5rem;
            margin-bottom: 1rem;
            display: block;
            color: var(--admin-secondary-color);
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
            .sidebar .nav-link { justify-content: center; padding: 0.6rem 1rem;}
            .sidebar .nav-link i { margin-right: 0.5rem;}
            .top-navbar { flex-direction: column; align-items: flex-start;}
            .top-navbar .search-bar { width: 100%; margin-bottom: 1rem;}
            .top-navbar .user-dropdown { width: 100%; text-align: center;}
            .top-navbar .user-dropdown .dropdown-toggle { justify-content: center;}

            .content-section.card { padding: 1.5rem 1rem; }
            .table-grades { font-size: 0.85rem; }
            .table-grades th, .table-grades td { padding: 0.75rem 0.5rem; }
            .form-control-grade { width: 60px; padding: 0.25rem 0.5rem; font-size: 0.8rem; }
            .btn-action-custom { padding: 0.5rem 1rem; font-size: 0.9rem; }
        }
        @media (max-width: 576px) {
            .main-content { padding: 0.75rem; }
            .welcome-section, .content-section.card { padding: 1rem;}
        }
    </style>
</head>
<body>
    <div id="app">
        <nav class="sidebar">
            <div class="sidebar-header">
                <a href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/home_profesor.jsp" class="text-white text-decoration-none">UGIC Portal</a>
            </div>
            <ul class="navbar-nav">
                <li class="nav-item"><a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/home_profesor.jsp"><i class="fas fa-chart-line"></i><span> Dashboard</span></a></li>
                <li class="nav-item"><a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/facultad_profesor.jsp"><i class="fas fa-building"></i><span> Facultades</span></a></li>
                <li class="nav-item"><a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/carreras_profesor.jsp"><i class="fas fa-graduation-cap"></i><span> Carreras</span></a></li>
                <li class="nav-item"><a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/cursos_profesor.jsp"><i class="fas fa-book"></i><span> Cursos</span></a></li>
                <li class="nav-item"><a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/salones_profesor.jsp"><i class="fas fa-chalkboard"></i><span> Clases</span></a></li>
                <li class="nav-item"><a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/horarios_profesor.jsp"><i class="fas fa-calendar-alt"></i><span> Horarios</span></a></li>
                <li class="nav-item"><a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/asistencia_profesor.jsp"><i class="fas fa-clipboard-check"></i><span> Asistencia</span></a></li>
                <li class="nav-item"><a class="nav-link" href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/mensaje_profesor.jsp"><i class="fas fa-envelope"></i><span> Mensajería</span></a></li>
                <li class="nav-item"><a class="nav-link active" href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/nota_profesor.jsp"><i class="fas fa-percent"></i><span> Notas</span></a></li>
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
                    </form>
                </div>
                <div class="d-flex align-items-center">
                    <div class="me-3 dropdown">
                        
                    </div>
                    <div class="me-3 dropdown">
                        <a class="text-dark" href="#" role="button" id="messagesDropdown" data-bs-toggle="dropdown" aria-expanded="false">
                            <i class="fas fa-envelope fa-lg"></i>
                            <span class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger">
                            </span>
                        </a>
                        <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="messagesDropdown">
                            <li><a class="dropdown-item" href="mensajeria_profesor.jsp">Ver todos</a></li>
                        </ul>
                    </div>

                    <div class="dropdown user-dropdown">
                        <a class="dropdown-toggle" href="#" role="button" id="userDropdown" data-bs-toggle="dropdown" aria-expanded="false">
                            <img src="https://via.placeholder.com/32" alt="Avatar"> <span class="d-none d-md-inline-block"><%= nombreProfesor%></span>
                        </a>
                        <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="userDropdown">
                            <li><a class="dropdown-item" href="perfil_profesor.jsp"><i class="fas fa-user me-2"></i>Perfil</a></li>
                            <li><a class="dropdown-item" href="configuracion_profesor.jsp"><i class="fas fa-cog me-2"></i>Configuración</a></li>
                            <li><hr class="dropdown-divider"></li>
                            <li><a class="dropdown-item" href="logout.jsp"><i class="fas fa-sign-out-alt me-2"></i>Cerrar sesión</a></li>
                        </ul>
                    </div>
                </div>
            </nav>

            <div class="container-fluid">
                <div class="welcome-section">
                    <h1 class="h3 mb-3"><i class="fas fa-percent me-2"></i>Gestión de Notas</h1>
                    <p class="lead">Aquí puede ingresar y actualizar las notas de sus alumnos.</p>
                </div>

                <% if (!mensajeFeedback.isEmpty()) { %>
                    <div class="alert alert-<%= tipoMensajeFeedback %> alert-dismissible fade show alert-custom" role="alert">
                        <i class="fas <%= "success".equals(tipoMensajeFeedback) ? "fa-check-circle" : "fa-exclamation-triangle" %> me-2"></i>
                        <%= mensajeFeedback %>
                        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                    </div>
                <% } %>

                <div class="card content-section prof-info">
                    <div class="card-body">
                        <h3 class="card-title text-primary"><i class="fas fa-user-circle me-2"></i>Información del Profesor</h3>
                        <p class="mb-1"><strong>Nombre:</strong> <%= nombreProfesor %></p>
                        <p class="mb-1"><strong>Email:</strong> <%= emailProfesor %></p>
                        <p class="mb-0"><strong>Facultad:</strong> <%= facultadProfesor %></p>
                    </div>
                </div>
                
                <% if (idClaseParam == null || idClaseParam.isEmpty()) { %>
                    <div class="card content-section class-selection">
                        <div class="card-body">
                            <h2 class="card-title text-primary"><i class="fas fa-chalkboard-teacher me-2"></i>Seleccione una Clase para Administrar Notas</h2>
                            <% if (clasesDelProfesor.isEmpty()) { %>
                                <p class="no-data-message">
                                    <i class="fas fa-info-circle"></i>
                                    No tiene clases asignadas actualmente.
                                </p>
                            <% } else { %>
                                <div class="table-responsive" style="max-height: 500px; overflow-y: auto;">
                                    <table class="table table-hover table-striped table-grades caption-top">
                                        <caption>Clases activas asignadas a usted.</caption>
                                        <thead>
                                            <tr>
                                                <th>Curso</th>
                                                <th>Sección</th>
                                                <th>Semestre</th>
                                                <th>Año Académico</th>
                                                <th>Aula</th>
                                                <th>Acción</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <% for (Map<String, String> clase : clasesDelProfesor) { %>
                                                <tr>
                                                    <td><%= clase.get("nombre_curso") %></td>
                                                    <td><%= clase.get("seccion") %></td>
                                                    <td><%= clase.get("semestre") %></td>
                                                    <td><%= clase.get("anio_academico") %></td>
                                                    <td><%= clase.get("aula") %></td>
                                                    <td>
                                                        <a href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/nota_profesor.jsp?id_clase=<%= clase.get("id_clase") %>" class="btn btn-sm btn-action-custom">
                                                            <i class="fas fa-edit"></i> Administrar Notas
                                                        </a>
                                                    </td>
                                                </tr>
                                            <% } %>
                                        </tbody>
                                    </table>
                                </div>
                            <% } %>
                        </div>
                    </div>
                <% } else { %>
                    <div class="card content-section grades-form">
                        <div class="card-body">
                            <div class="d-flex justify-content-between align-items-center mb-3 pb-3 border-bottom">
                                <h2 class="h5 mb-0 text-primary"><i class="fas fa-book-reader me-2"></i>Notas de <%= nombreClase %> (<%= codigoClase %> - <%= aulaClase %>)</h2>
                                <span class="text-muted"><small>Semestre: <%= semestreClase %> - Año: <%= anioAcademicoClase %></small></span>
                            </div>

                            <% if (estudiantesDeClase.isEmpty()) { %>
                                <p class="no-data-message">
                                    <i class="fas fa-exclamation-circle"></i>
                                    No hay alumnos inscritos en esta clase o la clase no fue encontrada para su profesor.
                                </p>
                                <div class="text-center mt-4">
                                    <a href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/nota_profesor.jsp" class="btn btn-action-custom btn-secondary">
                                        <i class="fas fa-arrow-left"></i> Volver a Clases
                                    </a>
                                </div>
                            <% } else { %>
                                <form method="post" action="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/nota_profesor.jsp?id_clase=<%= idClaseParam %>">
                                    <div class="table-responsive" style="max-height: 550px; overflow-y: auto;">
                                        <table class="table table-hover table-striped table-sm table-grades caption-top">
                                            <caption>Ingresa y actualiza las notas de tus alumnos.</caption>
                                            <thead>
                                                <tr>
                                                    <th>#</th>
                                                    <th>DNI</th>
                                                    <th>Nombre Completo</th>
                                                    <th>Nota 1<br>(0-20)</th>
                                                    <th>Nota 2<br>(0-20)</th>
                                                    <th>Nota 3<br>(0-20)</th>
                                                    <th>Ex. Parcial<br>(0-20)</th>
                                                    <th>Ex. Final<br>(0-20)</th>
                                                    <th>Nota Final</th>
                                                    <th>Estado</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                <% int contador = 1; %>
                                                <% for (Map<String, String> estudiante : estudiantesDeClase) { %>
                                                    <tr>
                                                        <td><%= contador++ %></td>
                                                        <td><%= estudiante.get("dni") %></td>
                                                        <td><%= estudiante.get("nombre_completo") %></td>
                                                        <td>
                                                            <input type="number" step="0.01" min="0" max="20" class="form-control form-control-sm form-control-grade"
                                                                name="nota1_<%= estudiante.get("id_inscripcion") %>"
                                                                value="<%= estudiante.get("nota1") %>">
                                                        </td>
                                                        <td>
                                                            <input type="number" step="0.01" min="0" max="20" class="form-control form-control-sm form-control-grade"
                                                                name="nota2_<%= estudiante.get("id_inscripcion") %>"
                                                                value="<%= estudiante.get("nota2") %>">
                                                        </td>
                                                        <td>
                                                            <input type="number" step="0.01" min="0" max="20" class="form-control form-control-sm form-control-grade"
                                                                name="nota3_<%= estudiante.get("id_inscripcion") %>"
                                                                value="<%= estudiante.get("nota3") %>">
                                                        </td>
                                                        <td>
                                                            <input type="number" step="0.01" min="0" max="20" class="form-control form-control-sm form-control-grade"
                                                                name="examen_parcial_<%= estudiante.get("id_inscripcion") %>"
                                                                value="<%= estudiante.get("examen_parcial") %>">
                                                        </td>
                                                        <td>
                                                            <input type="number" step="0.01" min="0" max="20" class="form-control form-control-sm form-control-grade"
                                                                name="examen_final_<%= estudiante.get("id_inscripcion") %>"
                                                                value="<%= estudiante.get("examen_final") %>">
                                                        </td>
                                                        <td>
                                                            <span class="badge
                                                                <% if ("aprobado".equals(estudiante.get("estado_nota"))) { %> bg-success
                                                                <% } else if ("desaprobado".equals(estudiante.get("estado_nota"))) { %> bg-danger
                                                                <% } else { %> bg-secondary <% } %>">
                                                                <%= estudiante.get("nota_final") %>
                                                            </span>
                                                        </td>
                                                        <td>
                                                            <span class="badge
                                                                <% if ("aprobado".equals(estudiante.get("estado_nota"))) { %> bg-success
                                                                <% } else if ("desaprobado".equals(estudiante.get("estado_nota"))) { %> bg-danger
                                                                <% } else { %> bg-secondary <% } %>">
                                                                <%= estudiante.get("estado_nota") %>
                                                            </span>
                                                        </td>
                                                    </tr>
                                                <% } %>
                                            </tbody>
                                        </table>
                                    </div>
                                    
                                    <div class="text-center mt-4 d-flex justify-content-center gap-3">
                                        <button type="submit" class="btn btn-action-custom btn-primary">
                                            <i class="fas fa-save"></i> Guardar Notas
                                        </button>
                                        <a href="<%= request.getContextPath() %>/INTERFAZ_PROFESOR/nota_profesor.jsp" class="btn btn-action-custom btn-secondary">
                                            <i class="fas fa-arrow-left"></i> Volver a Clases
                                        </a>
                                    </div>
                                </form>
                            <% } %>
                        </div>
                    </div>
                <% } %>

                <%-- New: Report Card Section --%>
                <div class="card content-section report-section">
                    <div class="card-body">
                        <h2 class="card-title text-primary"><i class="fas fa-file-alt me-2"></i>Generar Reporte de Notas</h2>
                        <p class="card-text text-muted">Acceda a los reportes detallados de las notas de sus alumnos para análisis o descarga.</p>
                        <a href="reporte_notas.jsp" class="btn btn-action-custom btn-warning-report mt-3">
                            <i class="fas fa-chart-bar"></i> Ir a Reportes de Notas
                        </a>
                    </div>
                </div>

            </div> <%-- End of container-fluid --%>
        </div> <%-- End of main-content --%>
    </div> <%-- End of app --%>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js" integrity="sha384-YvpcrYf0tY3lHB60NNkmXc5s9fDVZLESaAA55NDzOxhy9GkcIdslK1eN7N6jIeHz" crossorigin="anonymous"></script>
</body>
</html>