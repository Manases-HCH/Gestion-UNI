package pe.edu.controller;

import org.mindrot.jbcrypt.BCrypt;
import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.util.logging.Level;
import java.util.logging.Logger;
import pe.edu.entity.Alumno;
import pe.edu.dao.AlumnoDao;

@WebServlet(name = "AlumnoController", urlPatterns = {"/AlumnoController"})
public class AlumnoController extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String pagina = request.getParameter("pagina");        
        String idAlumno = request.getParameter("idAlumno"); // ID del alumno
        
        if (pagina != null) {            
            if (pagina.equals("nuevo")) {
                pagina = "alumno/" + pagina + ".jsp"; // Redirige a la página para crear un nuevo alumno
                response.sendRedirect(pagina);
            } else {
                // Para editar o leer un alumno existente, se pasa el ID
                pagina = "alumno/" + pagina + ".jsp?idAlumno=" + idAlumno;
                response.sendRedirect(pagina);
            }            
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        Alumno alumno = new Alumno();
        AlumnoDao alumnoDao = new AlumnoDao();
        String accion = request.getParameter("accion");
        
        // --- Capturar parámetros del formulario ---
        String idAlumno = request.getParameter("idAlumno");
        String dni = request.getParameter("dni");
        String nombre = request.getParameter("nombre");
        String apellidoPaterno = request.getParameter("apellidoPaterno");
        String apellidoMaterno = request.getParameter("apellidoMaterno");
        String direccion = request.getParameter("direccion");
        String telefono = request.getParameter("telefono");
        String fechaNacimiento = request.getParameter("fechaNacimiento");
        String email = request.getParameter("email");
        String idCarrera = request.getParameter("idCarrera");
        String rol = request.getParameter("rol");
        String password = request.getParameter("password");

        // --- Asignar valores al objeto ---
        alumno.setIdAlumno(idAlumno);
        alumno.setDni(dni);
        alumno.setNombre(nombre);
        alumno.setApellidoPaterno(apellidoPaterno);
        alumno.setApellidoMaterno(apellidoMaterno);
        alumno.setDireccion(direccion);
        alumno.setTelefono(telefono);
        alumno.setFechaNacimiento(fechaNacimiento);
        alumno.setEmail(email);
        alumno.setIdCarrera(idCarrera);
        alumno.setRol(rol);

        try {
            switch (accion) {
                case "nuevo":
                    // Hashear la contraseña antes de guardar
                    if (password != null && !password.trim().isEmpty()) {
                        String hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt(12));
                        alumno.setPassword(hashedPassword);
                    }
                    alumnoDao.insertar(alumno);
                    break;

                case "editar":
                    // Solo hashear si se cambió la contraseña
                    if (password != null && !password.trim().isEmpty()) {
                        String hashedNewPassword = BCrypt.hashpw(password, BCrypt.gensalt(12));
                        alumno.setPassword(hashedNewPassword);
                    }
                    alumnoDao.editar(alumno);
                    break;

                case "leer":
                    // No realiza cambios, solo delega a doGet
                    break;

                case "eliminar":
                    alumnoDao.eliminar(idAlumno);
                    break;

                default:
                    System.out.println("⚠️ Acción no reconocida en AlumnoController: " + accion);
                    break;
            }

            request.getSession().setAttribute("mensaje", "Operación realizada exitosamente");

        } catch (Exception ex) {
            Logger.getLogger(AlumnoController.class.getName()).log(Level.SEVERE, null, ex);
            request.getSession().setAttribute("error", "Error al realizar la operación: " + ex.getMessage());
        }

        // Redirige siempre al listado
        response.sendRedirect("alumno/listado.jsp");
    }
}
