<%@page import="pe.edu.dao.*"%>
<%@page import="pe.edu.entity.*"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Inicio - UNIVERSIDAD-SW</title>
        <%-- Incluye CSS de Bootstrap, Font Awesome, y tus estilos personalizados --%>
        <%@include file="util/referencias.jsp" %>
        <style>
            /* Estilos para las tarjetas de acceso rápido */
            .quick-access-card {
                text-align: center;
                padding: 25px;
                border-radius: 15px;
                box-shadow: 0 8px 16px rgba(0,0,0,0.1);
                transition: all 0.3s ease;
                margin-bottom: 25px;
                background: linear-gradient(135deg, #ffffff 0%, #f8f9fa 100%);
                border: 1px solid #e9ecef;
                position: relative;
                overflow: hidden;
            }

            .quick-access-card::before {
                content: '';
                position: absolute;
                top: 0;
                left: -100%;
                width: 100%;
                height: 100%;
                background: linear-gradient(90deg, transparent, rgba(255,255,255,0.4), transparent);
                transition: left 0.5s;
            }

            .quick-access-card:hover::before {
                left: 100%;
            }

            .quick-access-card:hover {
                transform: translateY(-10px) scale(1.02);
                box-shadow: 0 12px 24px rgba(0,0,0,0.15);
            }

            .quick-access-card .icon {
                font-size: 4.5rem;
                margin-bottom: 15px;
                color: #28a745;
                transition: all 0.3s ease;
            }

            .quick-access-card:hover .icon {
                color: #218838;
                transform: scale(1.1);
            }

            .quick-access-card h4 {
                font-size: 1.4rem;
                color: #495057;
                margin-bottom: 10px;
                font-weight: 600;
                transition: color 0.3s ease;
            }

            .quick-access-card:hover h4 {
                color: #343a40;
            }

            .quick-access-card .count {
                font-size: 3rem;
                font-weight: bold;
                color: #28a745;
                margin-bottom: 20px;
                text-shadow: 0 2px 4px rgba(0,0,0,0.1);
                transition: all 0.3s ease;
            }

            .quick-access-card:hover .count {
                color: #218838;
            }

            .quick-access-card .btn {
                width: 75%;
                padding: 14px 0;
                border-radius: 25px;
                font-size: 1.1rem;
                font-weight: 600;
                background: linear-gradient(135deg, #28a745 0%, #20c997 100%);
                border: none;
                color: white;
                transition: all 0.3s ease;
                text-transform: uppercase;
                letter-spacing: 0.5px;
                box-shadow: 0 4px 8px rgba(40, 167, 69, 0.3);
            }

            .quick-access-card .btn:hover {
                background: linear-gradient(135deg, #218838 0%, #1aa179 100%);
                transform: translateY(-2px);
                box-shadow: 0 6px 12px rgba(40, 167, 69, 0.4);
            }

            /* Estilos del header principal */
            .main-header {
                background: linear-gradient(135deg, #6c757d 0%, #495057 100%);
                color: white;
                padding: 30px 0;
                margin-bottom: 30px;
                border-radius: 15px;
                text-align: center;
                box-shadow: 0 6px 12px rgba(0,0,0,0.1);
            }

            .main-header h1 {
                font-size: 2.5rem;
                font-weight: 700;
                margin-bottom: 10px;
                text-shadow: 0 2px 4px rgba(0,0,0,0.3);
            }

            .main-header p {
                font-size: 1.2rem;
                opacity: 0.9;
                margin: 0;
            }

            /* Estilos generales mejorados */
            body {
                background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
                min-height: 100vh;
            }

            .col.py-3 {
                padding: 25px;
            }

            /* Animaciones para las tarjetas */
            @keyframes fadeInUp {
                from {
                    opacity: 0;
                    transform: translateY(30px);
                }
                to {
                    opacity: 1;
                    transform: translateY(0);
                }
            }

            .quick-access-card {
                animation: fadeInUp 0.6s ease forwards;
            }

            .quick-access-card:nth-child(1) { animation-delay: 0.1s; }
            .quick-access-card:nth-child(2) { animation-delay: 0.2s; }
            .quick-access-card:nth-child(3) { animation-delay: 0.3s; }
            .quick-access-card:nth-child(4) { animation-delay: 0.4s; }
            .quick-access-card:nth-child(5) { animation-delay: 0.5s; }
            .quick-access-card:nth-child(6) { animation-delay: 0.6s; }
            .quick-access-card:nth-child(7) { animation-delay: 0.7s; }
            .quick-access-card:nth-child(8) { animation-delay: 0.8s; }
            .quick-access-card:nth-child(9) { animation-delay: 0.9s; }
            .quick-access-card:nth-child(10) { animation-delay: 1.0s; }

            /* Responsive adjustments */
            @media (max-width: 768px) {
                .quick-access-card {
                    margin-bottom: 20px;
                }
                
                .main-header h1 {
                    font-size: 2rem;
                }
                
                .quick-access-card .icon {
                    font-size: 3.5rem;
                }
                
                .quick-access-card .count {
                    font-size: 2.5rem;
                }
            }
        </style>
    </head>
    <body>
        <div class="container-fluid">
            <div class="row flex-nowrap">
                <%-- Incluye el menú de la barra lateral --%>
                <%@include file="menu.jsp" %>
                
                <div class="col py-3">
                    <!-- Header Principal -->
                    <div class="main-header">
                        <h1><i class="fas fa-tachometer-alt me-3"></i>Dashboard Académico</h1>
                        <p>Sistema de Gestión Universitaria</p>
                    </div>

                    <!-- Sección de Acceso Rápido -->
                    <div class="row">
                        <%
                            // Instanciamos los DAOs para obtener los conteos
                            ProfesorDao profesorDao = new ProfesorDao();
                            AlumnoDao alumnoDao = new AlumnoDao();
                            CarreraDao carreraDao = new CarreraDao();
                            ClaseDao claseDao = new ClaseDao();
                            CursoDao cursoDao = new CursoDao();
                            FacultadDao facultadDao = new FacultadDao();
                            HorarioDao horarioDao = new HorarioDao();
                            InscripcionDao inscripcionDao = new InscripcionDao();
                            NotaDao notaDao = new NotaDao();
                            PagoDao pagoDao = new PagoDao();

                            // Obtener conteos de cada DAO.
                            int numProfesores = profesorDao.listar() != null ? profesorDao.listar().size() : 0;
                            int numAlumnos = alumnoDao.listar() != null ? alumnoDao.listar().size() : 0;
                            int numCarreras = carreraDao.listar() != null ? carreraDao.listar().size() : 0;
                            int numClases = claseDao.listar() != null ? claseDao.listar().size() : 0;
                            int numCursos = cursoDao.listar() != null ? cursoDao.listar().size() : 0;
                            int numFacultades = facultadDao.listar() != null ? facultadDao.listar().size() : 0;
                            int numHorarios = horarioDao.listar() != null ? horarioDao.listar().size() : 0;
                            int numInscripciones = inscripcionDao.listar() != null ? inscripcionDao.listar().size() : 0;
                            int numNotas = notaDao.listar() != null ? notaDao.listar().size() : 0;
                            int numPagos = pagoDao.listar() != null ? pagoDao.listar().size() : 0;
                        %>

                        <div class="col-lg-4 col-md-6 col-sm-12">
                            <div class="quick-access-card">
                                <div class="icon"><i class="fas fa-chalkboard-teacher"></i></div>
                                <h4>DOCENTES</h4>
                                <div class="count"><%= numProfesores %></div>
                                <a href="<%= request.getContextPath() %>/profesor/listado.jsp" class="btn">Ingresar</a>
                            </div>
                        </div>

                        <div class="col-lg-4 col-md-6 col-sm-12">
                            <div class="quick-access-card">
                                <div class="icon"><i class="fas fa-user-graduate"></i></div>
                                <h4>ESTUDIANTES</h4>
                                <div class="count"><%= numAlumnos %></div>
                                <a href="<%= request.getContextPath() %>/alumno/listado.jsp" class="btn">Ingresar</a>
                            </div>
                        </div>

                        <div class="col-lg-4 col-md-6 col-sm-12">
                            <div class="quick-access-card">
                                <div class="icon"><i class="fas fa-calendar-alt"></i></div>
                                <h4>HORARIOS</h4>
                                <div class="count"><%= numHorarios %></div>
                                <a href="<%= request.getContextPath() %>/horario/listado.jsp" class="btn">Ingresar</a>
                            </div>
                        </div>

                        <div class="col-lg-4 col-md-6 col-sm-12">
                            <div class="quick-access-card">
                                <div class="icon"><i class="fas fa-clipboard-check"></i></div>
                                <h4>NOTAS</h4>
                                <div class="count"><%= numNotas %></div>
                                <a href="<%= request.getContextPath()    %>/nota/listado.jsp" class="btn">Ingresar</a>
                            </div>
                        </div>

                        <div class="col-lg-4 col-md-6 col-sm-12">
                            <div class="quick-access-card">
                                <div class="icon"><i class="fas fa-graduation-cap"></i></div>
                                <h4>CARRERAS</h4>
                                <div class="count"><%= numCarreras %></div>
                                <a href="<%= request.getContextPath() %>/carrera/listado.jsp" class="btn">Ingresar</a>
                            </div>
                        </div>

                        <div class="col-lg-4 col-md-6 col-sm-12">
                            <div class="quick-access-card">
                                <div class="icon"><i class="fas fa-school"></i></div>
                                <h4>CLASES</h4>
                                <div class="count"><%= numClases %></div>
                                <a href="<%= request.getContextPath() %>/clase/listado.jsp" class="btn">Ingresar</a>
                            </div>
                        </div>
                        
                        <div class="col-lg-4 col-md-6 col-sm-12">
                            <div class="quick-access-card">
                                <div class="icon"><i class="fas fa-book"></i></div>
                                <h4>CURSOS</h4>
                                <div class="count"><%= numCursos %></div>
                                <a href="<%= request.getContextPath() %>/curso/listado.jsp" class="btn">Ingresar</a>
                            </div>
                        </div>

                        <div class="col-lg-4 col-md-6 col-sm-12">
                            <div class="quick-access-card">
                                <div class="icon"><i class="fas fa-building"></i></div>
                                <h4>FACULTADES</h4>
                                <div class="count"><%= numFacultades %></div>
                                <a href="<%= request.getContextPath() %>/facultad/listado.jsp" class="btn">Ingresar</a>
                            </div>
                        </div>

                        <div class="col-lg-4 col-md-6 col-sm-12">
                            <div class="quick-access-card">
                                <div class="icon"><i class="fas fa-file-invoice"></i></div>
                                <h4>INSCRIPCIONES</h4>
                                <div class="count"><%= numInscripciones %></div>
                                <a href="<%= request.getContextPath() %>/inscripcion/listado.jsp" class="btn">Ingresar</a>
                            </div>
                        </div>
                        
                        <div class="col-lg-4 col-md-6 col-sm-12">
                            <div class="quick-access-card">
                                <div class="icon"><i class="fas fa-dollar-sign"></i></div>
                                <h4>PAGOS</h4>
                                <div class="count"><%= numPagos %></div>
                                <a href="<%= request.getContextPath() %>/pago/listado.jsp" class="btn">Ingresar</a>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        
        <%-- Scripts necesarios --%>
        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/js/all.min.js"></script>
    </body>
</html> 