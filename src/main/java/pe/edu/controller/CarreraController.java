package pe.edu.controller;

import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.util.logging.Level;
import java.util.logging.Logger;
// Importa las clases de Carrera y CarreraDao
import pe.edu.entity.Carrera; // Asegúrate de que esta ruta sea correcta
import pe.edu.dao.CarreraDao; // Asegúrate de que esta ruta sea correcta

@WebServlet(name = "CarreraController", urlPatterns = {"/CarreraController"})
public class CarreraController extends HttpServlet {
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String pagina = request.getParameter("pagina");        
        String idCarrera = request.getParameter("id"); // ID de la carrera
        
        if (pagina != null) {            
            if (pagina.equals("nuevo")) {
                pagina = "carrera/" + pagina + ".jsp"; // Redirige a la página para crear una nueva carrera
                response.sendRedirect(pagina);
            } else {
                // Para editar o ver una carrera existente, se pasa el ID
                pagina = "carrera/" + pagina + ".jsp?id=" + idCarrera;
                response.sendRedirect(pagina);
            }            
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        Carrera carrera = new Carrera();
        CarreraDao carreraDao = new CarreraDao();
        String accion = request.getParameter("accion");
        
        // Obtener todos los parámetros necesarios del formulario para un objeto Carrera
        String idCarrera = request.getParameter("idCarrera"); // ID de la carrera
        String nombreCarrera = request.getParameter("nombreCarrera");
        String idFacultad = request.getParameter("idFacultad");

        // Establecer los atributos del objeto Carrera
        carrera.setIdCarrera(idCarrera);
        carrera.setNombreCarrera(nombreCarrera);
        carrera.setIdFacultad(idFacultad);

        try {
            switch (accion) {
                case "nuevo":
                    carreraDao.insertar(carrera);
                    break;
                case "leer":
                    // El método leer en CarreraDao devuelve una Carrera por ID, 
                    // aquí no se necesita una acción directa ya que se maneja en doGet
                    break; 
                case "editar":
                    carreraDao.editar(carrera);
                    break;
                case "eliminar":
                    carreraDao.eliminar(idCarrera); // Eliminar por ID
                    break;
                default:
                    break;
            }
        } catch (Exception ex) { // Captura cualquier excepción para loguear
            Logger.getLogger(CarreraController.class.getName()).log(Level.SEVERE, null, ex);
        }
        
        // Redirige siempre al listado de carreras después de una operación POST
        response.sendRedirect("carrera/listado.jsp");
    }
}