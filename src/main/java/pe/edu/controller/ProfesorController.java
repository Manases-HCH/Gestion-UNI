package pe.edu.controller;

import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.util.logging.Level;
import java.util.logging.Logger;
import org.mindrot.jbcrypt.BCrypt; // Para cifrar la contraseña
import pe.edu.entity.Profesor;
import pe.edu.dao.ProfesorDao;

@WebServlet(name = "ProfesorController", urlPatterns = {"/ProfesorController"})
public class ProfesorController extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String pagina = request.getParameter("pagina");
        String idProfesor = request.getParameter("id");

        if (pagina != null) {
            if (pagina.equals("nuevo")) {
                pagina = "profesor/" + pagina + ".jsp";
                response.sendRedirect(pagina);
            } else {
                pagina = "profesor/" + pagina + ".jsp?id=" + idProfesor;
                response.sendRedirect(pagina);
            }
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        Profesor profesor = new Profesor();
        ProfesorDao profesorDao = new ProfesorDao();
        String accion = request.getParameter("accion");

        // 🔹 Capturar los parámetros del formulario
        String id = request.getParameter("idProfesor");
        String dni = request.getParameter("dni");
        String nombre = request.getParameter("nombre");
        String apellidoPaterno = request.getParameter("apellidoPaterno");
        String apellidoMaterno = request.getParameter("apellidoMaterno");
        String email = request.getParameter("email");
        String telefono = request.getParameter("telefono");
        String idFacultad = request.getParameter("idFacultad");
        String rol = request.getParameter("rol");
        String password = request.getParameter("password");

        // 🔹 Asignar los valores al objeto Profesor
        if (id != null && !id.trim().isEmpty()) {
            profesor.setIdProfesor(id);
        }
        profesor.setDni(dni);
        profesor.setNombre(nombre);
        profesor.setApellidoPaterno(apellidoPaterno);
        profesor.setApellidoMaterno(apellidoMaterno);
        profesor.setEmail(email);
        profesor.setTelefono(telefono);
        profesor.setIdFacultad(idFacultad);
        profesor.setRol(rol);

        try {
            switch (accion) {
                case "nuevo":
                    // 🔐 Encriptar contraseña antes de insertar
                    if (password != null && !password.trim().isEmpty()) {
                        String hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt(12));
                        profesor.setPassword(hashedPassword);
                    }
                    profesorDao.insertar(profesor);
                    break;

                case "editar":
                    // Solo encripta si se cambió la contraseña
                    if (password != null && !password.trim().isEmpty()) {
                        String hashedNewPassword = BCrypt.hashpw(password, BCrypt.gensalt(12));
                        profesor.setPassword(hashedNewPassword);
                    }
                    profesorDao.editar(profesor);
                    break;

                case "eliminar":
                    profesorDao.eliminar(id);
                    break;

                case "leer":
                    // El método leer se maneja desde doGet en JSP
                    break;

                default:
                    System.out.println("⚠️ Acción no reconocida: " + accion);
                    break;
            }

            request.getSession().setAttribute("mensaje", "Operación realizada exitosamente ✅");

        } catch (Exception ex) {
            Logger.getLogger(ProfesorController.class.getName()).log(Level.SEVERE, null, ex);
            request.getSession().setAttribute("error", "Error al realizar la operación: " + ex.getMessage());
        }

        response.sendRedirect("profesor/listado.jsp");
    }
}
