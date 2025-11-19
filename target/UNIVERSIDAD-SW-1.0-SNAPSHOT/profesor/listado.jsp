<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.LinkedList, pe.edu.entity.Profesor, pe.edu.dao.ProfesorDao" %>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <%@include file="../util/referencias.jsp" %>
        <title>Listado de Profesores</title>        

        <link rel="stylesheet" type="text/css" href="https://cdn.datatables.net/buttons/2.3.6/css/buttons.bootstrap5.min.css"/>
        
        <style>
            /* Ajustes para la alineación del buscador y botones de DataTables */
            .dataTables_filter {
                display: flex;
                align-items: center;
                gap: 10px;
                flex-wrap: wrap;
            }
            .dataTables_filter label {
                margin-bottom: 0;
                white-space: nowrap;
                font-weight: 600;
                color: #495057;
            }
            .dataTables_filter input {
                min-width: 200px;
                flex-grow: 1;
                border-radius: 8px;
                border: 2px solid #e9ecef;
                padding: 8px 12px;
                transition: all 0.3s ease;
            }
            .dataTables_filter input:focus {
                border-color: #0d6efd;
                box-shadow: 0 0 0 0.2rem rgba(13, 110, 253, 0.25);
            }

            /* Mejoras para los botones de DataTables */
            .dt-buttons {
                display: flex;
                align-items: center;
                flex-wrap: wrap;
                gap: 8px;
            }
            
            .dt-button {
                border-radius: 8px !important;
                padding: 8px 16px !important;
                font-weight: 600 !important;
                transition: all 0.3s ease !important;
                box-shadow: 0 2px 4px rgba(0,0,0,0.1) !important;
                border: none !important;
                position: relative;
                overflow: hidden;
            }
            
            .dt-button:hover {
                transform: translateY(-2px) !important;
                box-shadow: 0 4px 8px rgba(0,0,0,0.15) !important;
            }
            
            .dt-button:active {
                transform: translateY(0) !important;
            }
            
            /* Efectos específicos para cada botón */
            .dt-button.btn-success {
                background: linear-gradient(45deg, #198754, #20c997) !important;
            }
            .dt-button.btn-success:hover {
                background: linear-gradient(45deg, #157347, #1aa085) !important;
            }
            
            .dt-button.btn-danger {
                background: linear-gradient(45deg, #dc3545, #e74c3c) !important;
            }
            .dt-button.btn-danger:hover {
                background: linear-gradient(45deg, #b02a37, #c0392b) !important;
            }
            
            .dt-button.btn-secondary {
                background: linear-gradient(45deg, #6c757d, #495057) !important;
            }
            .dt-button.btn-secondary:hover {
                background: linear-gradient(45deg, #5a6268, #3d4043) !important;
            }

            /* Mejoras para el botón "Nuevo Profesor" */
            .btn-nuevo-profesor {
                background: linear-gradient(45deg, #198754, #20c997);
                border: none;
                border-radius: 10px;
                padding: 12px 24px;
                font-weight: 600;
                color: white;
                transition: all 0.3s ease;
                box-shadow: 0 4px 8px rgba(25, 135, 84, 0.3);
                text-decoration: none;
                display: inline-flex;
                align-items: center;
                gap: 8px;
            }
            
            .btn-nuevo-profesor:hover {
                background: linear-gradient(45deg, #157347, #1aa085);
                transform: translateY(-2px);
                box-shadow: 0 6px 12px rgba(25, 135, 84, 0.4);
                color: white;
            }
            
            .btn-nuevo-profesor:active {
                transform: translateY(0);
            }

            /* Mejoras para los botones de acciones */
            .action-buttons {
                display: flex;
                gap: 6px;
                justify-content: center;
                align-items: center;
            }
            
            .btn-action {
                width: 36px;
                height: 36px;
                border-radius: 8px;
                border: none;
                display: flex;
                align-items: center;
                justify-content: center;
                transition: all 0.3s ease;
                text-decoration: none;
                font-size: 14px;
                position: relative;
                overflow: hidden;
            }
            
            .btn-action:hover {
                transform: translateY(-2px);
                box-shadow: 0 4px 8px rgba(0,0,0,0.2);
            }
            
            .btn-action:active {
                transform: translateY(0);
            }
            
            .btn-action.btn-info {
                background: linear-gradient(45deg, #0dcaf0, #17a2b8);
                color: white;
            }
            .btn-action.btn-info:hover {
                background: linear-gradient(45deg, #0aa2c0, #138496);
                color: white;
            }
            
            .btn-action.btn-warning {
                background: linear-gradient(45deg, #ffc107, #ffca2c);
                color: #212529;
            }
            .btn-action.btn-warning:hover {
                background: linear-gradient(45deg, #e0a800, #ffb700);
                color: #212529;
            }
            
            .btn-action.btn-danger {
                background: linear-gradient(45deg, #dc3545, #e74c3c);
                color: white;
            }
            .btn-action.btn-danger:hover {
                background: linear-gradient(45deg, #b02a37, #c0392b);
                color: white;
            }
            
            /* Tooltip personalizado */
            .btn-action::before {
                content: attr(data-tooltip);
                position: absolute;
                bottom: 100%;
                left: 50%;
                transform: translateX(-50%);
                background: rgba(0, 0, 0, 0.8);
                color: white;
                padding: 4px 8px;
                border-radius: 4px;
                font-size: 12px;
                white-space: nowrap;
                opacity: 0;
                visibility: hidden;
                transition: all 0.3s ease;
                z-index: 1000;
            }
            
            .btn-action:hover::before {
                opacity: 1;
                visibility: visible;
                bottom: calc(100% + 5px);
            }

            /* Mejoras generales de la tabla */
            #myTable tbody td {
                text-align: center;
                vertical-align: middle;
                padding: 12px 8px;
            }
            #myTable thead th {
                text-align: center;
                background: linear-gradient(45deg, #0d6efd, #6610f2);
                color: white;
                font-weight: 600;
                padding: 15px 8px;
                border: none;
            }
            
            .card {
                border: none;
                border-radius: 15px;
                box-shadow: 0 8px 24px rgba(0,0,0,0.1);
                overflow: hidden;
            }
            
            .card-header {
                background: linear-gradient(45deg, #0d6efd, #6610f2);
                border: none;
                padding: 20px;
            }
            
            .table-responsive {
                border-radius: 10px;
                overflow: hidden;
            }
            
            .table {
                margin-bottom: 0;
            }
            
            .table tbody tr {
                transition: all 0.3s ease;
            }
            
            .table tbody tr:hover {
                background-color: #f8f9fa;
                transform: scale(1.01);
            }
            
            /* Animación de carga */
            @keyframes fadeIn {
                from {
                    opacity: 0;
                    transform: translateY(20px);
                }
                to {
                    opacity: 1;
                    transform: translateY(0);
                }
            }
            
            .card {
                animation: fadeIn 0.6s ease-out;
            }
            
            /* Responsive */
            @media (max-width: 768px) {
                .action-buttons {
                    flex-direction: column;
                    gap: 4px;
                }
                
                .btn-action {
                    width: 32px;
                    height: 32px;
                    font-size: 12px;
                }
                
                .dataTables_filter input {
                    min-width: 150px;
                }
            }
        </style>
    </head>

    <%-- Instancia de ProfesorDao para interactuar con la base de datos --%>
    <jsp:useBean id="profesorDao" class="pe.edu.dao.ProfesorDao" scope="session"></jsp:useBean>
    
    <body>            
    <div class="container-fluid">
        <div class="row flex-nowrap">
            <%@include file="../menu.jsp" %>
            <div class="col py-3">            
                <center>
                    <div class="card card_tabla shadow-sm">
                        <div class="card-header card_titulo bg-primary text-white">
                            <h2 class="mb-0">
                                <i class="fas fa-chalkboard-teacher me-2"></i>Gestión de Profesores
                            </h2>
                        </div>
                        <div class="card-body">
                            <div class="row mb-4 align-items-center">
                                <div class="col-sm-auto">
                                    <a href="../ProfesorController?pagina=nuevo" class="btn-nuevo-profesor">
                                        <i class="fas fa-plus-circle"></i>
                                        Nuevo Profesor
                                    </a>
                                </div>
                            </div>

                            <div class="table-responsive">
                                <table id="myTable" class="display table table-light table-striped table-hover card_contenido align-middle">
                                    <thead>
                                        <tr>
                                            <th>DNI</th>
                                            <th>Nombre</th>
                                            <th>Apellido Paterno</th>
                                            <th>Apellido Materno</th>
                                            <th>Email</th>
                                            <th>Teléfono</th>
                                            <th>Facultad</th>
                                            <th>Estado</th>
                                            <th>Fecha Registro</th>
                                            <th>Acciones</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <%
                                            LinkedList<Profesor> listaProfesores = profesorDao.listar();
                                            if (listaProfesores == null) {
                                                listaProfesores = new LinkedList<Profesor>();
                                            }
                                            for (Profesor p : listaProfesores) {
                                        %>            
                                        <tr>
                                            <td><%= p.getDni() %></td>
                                            <td><%= p.getNombre() %></td>
                                            <td><%= p.getApellidoPaterno() %></td>
                                            <td><%= p.getApellidoMaterno() %></td>
                                            <td><%= p.getEmail() %></td>
                                            <td><%= p.getTelefono() %></td>
                                            <td><%= p.getNombreFacultad() != null ? p.getNombreFacultad() : p.getIdFacultad() %></td>
                                            <td><%= p.getEstado() %></td>
                                            <td><%= p.getFechaRegistro() %></td>
                                            <td class="text-center">
                                                <div class="action-buttons">
                                                    <a href="../ProfesorController?pagina=ver&id=<%= p.getIdProfesor() %>" 
                                                       class="btn-action btn-info" 
                                                       data-tooltip="Ver detalles">
                                                        <i class="fas fa-eye"></i>
                                                    </a>
                                                    <a href="../ProfesorController?pagina=editar&id=<%= p.getIdProfesor() %>" 
                                                       class="btn-action btn-warning" 
                                                       data-tooltip="Editar">
                                                        <i class="fas fa-edit"></i>
                                                    </a>
                                                    <a href="../ProfesorController?pagina=eliminar&id=<%= p.getIdProfesor() %>" 
                                                       class="btn-action btn-danger" 
                                                       data-tooltip="Eliminar"
                                                       onclick="return confirm('¿Está seguro que desea eliminar este profesor? Esta acción no se puede deshacer.')">
                                                        <i class="fas fa-trash-alt"></i>
                                                    </a>
                                                </div>
                                            </td>
                                        </tr>
                                        <%
                                            }
                                        %>            
                                    </tbody>
                                </table> 
                            </div>
                        </div>
                    </div>
                </center>
            </div>
        </div>
    </div>
</body>
</html>

<!-- JS y scripts -->
<script src="https://code.jquery.com/jquery-3.7.1.js"></script>
<script src="https://cdn.datatables.net/2.3.1/js/dataTables.js"></script>
<script src="https://cdn.datatables.net/2.3.1/js/dataTables.bootstrap5.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/js/all.min.js"></script>
<script src="https://cdn.datatables.net/buttons/2.3.6/js/dataTables.buttons.min.js"></script>
<script src="https://cdn.datatables.net/buttons/2.3.6/js/buttons.bootstrap5.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/jszip/3.1.3/jszip.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/pdfmake/0.1.53/pdfmake.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/pdfmake/0.1.53/vfs_fonts.js"></script>
<script src="https://cdn.datatables.net/buttons/2.3.6/js/buttons.html5.min.js"></script>
<script src="https://cdn.datatables.net/buttons/2.3.6/js/buttons.print.min.js"></script>

<script type="text/javascript">
    $(document).ready(function() {
        $('#myTable').DataTable({
            dom: "<'row mb-3'<'col-auto'l><'col d-flex justify-content-center align-items-center'B><'col-auto'f>>" +
                 "<'row'<'col-sm-12'tr>>" +
                 "<'row mt-3'<'col-sm-5'i><'col-sm-7'p>>",
            buttons: [
                {
                    extend: 'excelHtml5',
                    text: '<i class="fas fa-file-excel me-2"></i>Excel', 
                    titleAttr: 'Exportar a Excel', 
                    className: 'btn btn-success me-2', 
                    exportOptions: {
                        columns: [0,1,2,3,4,5,6,7,8,9,10] // sin acciones
                    }
                },
                {
                    extend: 'pdfHtml5',
                    text: '<i class="fas fa-file-pdf me-2"></i>PDF', 
                    titleAttr: 'Exportar a PDF', 
                    className: 'btn btn-danger me-2',
                    orientation: 'landscape',
                    pageSize: 'A4',
                    exportOptions: {
                        columns: [0,1,2,3,4,5,6,7,8,9,10]
                    },
                    customize: function (doc) {
                        var colCount = doc.content[1].table.body[0].length;
                        var widths = Array(colCount).fill('*');
                        doc.content[1].table.widths = widths;
                        
                        doc.defaultStyle.fontSize = 8;
                        doc.pageMargins = [20, 20, 20, 20];
                        doc.content.splice(0, 0, {
                            text: 'Listado de Profesores',
                            fontSize: 16,
                            bold: true,
                            alignment: 'center',
                            margin: [0, 0, 0, 15],
                            color: '#0d6efd'
                        });
                        doc.footer = function(page, pages) {
                            return {
                                columns: [
                                    { text: 'Exportado el ' + new Date().toLocaleDateString(), alignment: 'left', margin: [20, 0, 0, 0] },
                                    { text: 'Página ' + page.toString() + ' de ' + pages.toString(), alignment: 'right', margin: [0, 0, 20, 0] }
                                ],
                                fontSize: 8
                            };
                        };
                    }
                },
                {
                    extend: 'print',
                    text: '<i class="fas fa-print me-2"></i>Imprimir',
                    titleAttr: 'Imprimir Tabla',
                    className: 'btn btn-secondary',
                    exportOptions: {
                        columns: [0,1,2,3,4,5,6,7,8,9,10]
                    }
                }
            ],
            language: {
                url: 'https://cdn.datatables.net/plug-ins/1.13.5/i18n/es-ES.json' 
            },
            pageLength: 10,
            lengthMenu: [[10, 25, 50, 100], [10, 25, 50, 100]],
            responsive: true,
            columnDefs: [
                { targets: 9, orderable: false } // desactivar acciones
            ]
        });
    });
</script>