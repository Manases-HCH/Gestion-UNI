package pe.edu.controller;

import java.io.IOException;
import java.util.logging.Level;
import java.util.logging.Logger;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import pe.edu.entity.Facultad;
import pe.edu.dao.FacultadDao;

@WebServlet(name = "FacultadController", urlPatterns = {"/FacultadController"})
public class FacultadController extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String pagina = request.getParameter("pagina");
        String idFacultad = request.getParameter("id");

        if (pagina != null) {
            if (pagina.equals("nuevo")) {
                response.sendRedirect("facultad/nuevo.jsp");
            } else {
                // Para editar o ver una facultad existente, se pasa el ID
                response.sendRedirect("facultad/" + pagina + ".jsp?id=" + idFacultad);
            }
        } else {
            response.sendRedirect("facultad/listado.jsp");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

       Facultad facultad = new Facultad();
        FacultadDao facultadDao = new FacultadDao();
        String accion = request.getParameter("accion");

        String id = request.getParameter("idFacultad"); // Este ID puede venir vacío si es nuevo
        String nombreFacultad = request.getParameter("nombreFacultad");

        if (id != null && !id.trim().isEmpty()) {
            facultad.setIdFacultad(id);
        }
        facultad.setNombreFacultad(nombreFacultad);

        try {
            switch (accion) {
                case "nuevo":
                    facultad.setIdFacultad(null); // Para asegurar inserción sin ID
                    facultadDao.insertar(facultad);
                    break;
                case "editar":
                    facultadDao.editar(facultad);
                    break;
                case "eliminar":
                    facultadDao.eliminar(id);
                    break;
                default:
                    break;
            }

            request.getSession().setAttribute("mensaje", "Operación realizada exitosamente");

        } catch (Exception ex) {
            Logger.getLogger(FacultadController.class.getName()).log(Level.SEVERE, null, ex);
            request.getSession().setAttribute("error", "Error al realizar la operación: " + ex.getMessage());
        }

        response.sendRedirect("facultad/listado.jsp");
    }

    @Override
    public String getServletInfo() {
        return "Controlador para la gestión de Facultades";
    }
}
