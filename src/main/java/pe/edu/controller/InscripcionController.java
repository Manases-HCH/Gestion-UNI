package pe.edu.controller;

import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.util.logging.Level;
import java.util.logging.Logger;

import pe.edu.entity.Inscripcion;
import pe.edu.dao.InscripcionDao;

@WebServlet(name = "InscripcionController", urlPatterns = {"/InscripcionController"})
public class InscripcionController extends HttpServlet {

    private static final Logger LOGGER = Logger.getLogger(InscripcionController.class.getName());

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String pagina = request.getParameter("pagina");
        String idInscripcion = request.getParameter("id");

        if (pagina != null) {
            if (pagina.equals("nuevo")) {
                request.getRequestDispatcher("inscripcion/nuevo.jsp").forward(request, response);
            } else {
                request.setAttribute("id", idInscripcion);
                request.getRequestDispatcher("inscripcion/" + pagina + ".jsp").forward(request, response);
            }
        } else {
            response.sendRedirect("inscripcion/listado.jsp");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        Inscripcion inscripcion = new Inscripcion();
        InscripcionDao inscripcionDao = new InscripcionDao();
        String accion = request.getParameter("accion");

        String idInscripcionStr = request.getParameter("idInscripcion");
        String idAlumnoStr = request.getParameter("idAlumno");
        String idClaseStr = request.getParameter("idClase");
        String fechaInscripcion = request.getParameter("fechaInscripcion");
        String estado = request.getParameter("estado");

        if (idInscripcionStr != null && !idInscripcionStr.trim().isEmpty()) {
            inscripcion.setIdInscripcion(idInscripcionStr);
        }
        
        inscripcion.setIdAlumno(idAlumnoStr);
        inscripcion.setIdClase(idClaseStr);
        inscripcion.setFechaInscripcion(fechaInscripcion);
        inscripcion.setEstado(estado);

        try {
            switch (accion) {
                case "nuevo":                   
                        inscripcionDao.insertar(inscripcion);                        
                    break;

                case "leer":
                    break;

                case "editar":                  
                        inscripcionDao.editar(inscripcion);
                        request.getSession().setAttribute("mensaje", "Inscripción editada correctamente");                    
                    break;

                case "eliminar":                   
                        inscripcionDao.eliminar(idInscripcionStr);                      
                    break;

                default:
                    request.getSession().setAttribute("error", "Acción no reconocida.");
                    break;
            }

        } catch (Exception ex) {
            LOGGER.log(Level.SEVERE, "Error en InscripcionController: " + accion, ex);
            request.getSession().setAttribute("error", "Error al realizar la operación: " + ex.getMessage());
        }

        response.sendRedirect("inscripcion/listado.jsp");
    }

    private boolean datosCompletos(String idAlumno, String idClase, String fecha, String estado) {
        return idAlumno != null && !idAlumno.isEmpty() &&
               idClase != null && !idClase.isEmpty() &&
               fecha != null && !fecha.isEmpty() &&
               estado != null && !estado.isEmpty();
    }

    @Override
    public String getServletInfo() {
        return "Controlador para la gestión de Inscripciones";
    }
}