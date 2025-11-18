package pe.edu.controller;

import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.util.logging.Level;
import java.util.logging.Logger;
// Importa las clases de Clase y ClaseDao
import pe.edu.entity.Clase; // Asegúrate de que esta ruta sea correcta
import pe.edu.dao.ClaseDao; // Asegúrate de que esta ruta sea correcta

@WebServlet(name = "ClaseController", urlPatterns = {"/ClaseController"})
public class ClaseController extends HttpServlet {
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String pagina = request.getParameter("pagina");        
        String idClase = request.getParameter("id"); // ID de la clase
        
        if (pagina != null) {            
            if (pagina.equals("nuevo")) {
                pagina = "clase/" + pagina + ".jsp"; // Redirige a la página para crear una nueva clase
                response.sendRedirect(pagina);
            } else {
                // Para editar o ver una clase existente, se pasa el ID
                pagina = "clase/" + pagina + ".jsp?id=" + idClase;
                response.sendRedirect(pagina);
            }            
        }
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        Clase clase = new Clase();
        ClaseDao claseDao = new ClaseDao();
        String accion = request.getParameter("accion");
        
        // Obtener todos los parámetros necesarios del formulario para un objeto Clase
        String idClase = request.getParameter("idClase"); // ID de la clase
        String idCurso = request.getParameter("idCurso");
        String idProfesor = request.getParameter("idProfesor");
        String idHorario = request.getParameter("idHorario");
        String ciclo = request.getParameter("ciclo");
        
        // Establecer los atributos del objeto Clase
        clase.setIdClase(idClase);
        clase.setIdCurso(idCurso);
        clase.setIdProfesor(idProfesor);
        clase.setIdHorario(idHorario);
        clase.setCiclo(ciclo);
        
        try {
            switch (accion) {
                case "nuevo":
                    claseDao.insertar(clase);
                    break;
                case "leer":
                    // El método leer en ClaseDao devuelve una Clase por ID, 
                    // aquí no se necesita una acción directa ya que se maneja en doGet
                    break; 
                case "editar":
                    claseDao.editar(clase);
                    break;
                case "eliminar":
                    claseDao.eliminar(idClase); // Eliminar por ID
                    break;
                default:
                    break;
            }
        } catch (Exception ex) { // Captura cualquier excepción para loguear
            Logger.getLogger(ClaseController.class.getName()).log(Level.SEVERE, null, ex);
        }
        
        // Redirige siempre al listado de clases después de una operación POST
        response.sendRedirect("clase/listado.jsp");
    }
}