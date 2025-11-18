package pe.edu.controller;

import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.Part;
import java.io.InputStream;
import java.util.logging.Level;
import java.util.logging.Logger;
// Importa las clases de Curso y CursoDao
import pe.edu.entity.Curso; // Asegúrate de que esta ruta sea correcta
import pe.edu.dao.CursoDao; // Asegúrate de que esta ruta sea correcta
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024 * 1, // 1 MB
    maxFileSize = 1024 * 1024 * 10,      // 10 MB
    maxRequestSize = 1024 * 1024 * 50    // 50 MB
)
@WebServlet(name = "CursoController", urlPatterns = {"/CursoController"})
public class CursoController extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String pagina = request.getParameter("pagina");
        String idCurso = request.getParameter("id"); // ID del curso

        if (pagina != null) {
            if (pagina.equals("nuevo")) {
                pagina = "curso/" + pagina + ".jsp"; // Redirige a la página para crear un nuevo curso
                response.sendRedirect(pagina);
            } else {
                // Para editar o ver un curso existente, se pasa el ID
                pagina = "curso/" + pagina + ".jsp?id=" + idCurso;
                response.sendRedirect(pagina);
            }
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        Curso curso = new Curso();
        CursoDao cursoDao = new CursoDao();
        String accion = request.getParameter("accion");

        // Obtener todos los parámetros necesarios del formulario para un objeto Curso
        String idCurso = request.getParameter("idCurso"); // ID del curso
        String nombreCurso = request.getParameter("nombreCurso");
        String codigoCurso = request.getParameter("codigoCurso");
        String creditos = request.getParameter("creditos"); // Convertir a int
        String idCarrera = request.getParameter("idCarrera"); // Convertir a int

        // Establecer los atributos del objeto Curso
        curso.setIdCurso(idCurso); // Si idCurso es auto-generado por la BD, no lo establecerías al insertar
        curso.setNombreCurso(nombreCurso);
        curso.setCodigoCurso(codigoCurso);
        curso.setCreditos(creditos);
        curso.setIdCarrera(idCarrera);

        // --- INICIO DE INTEGRACIÓN DE IMAGEN ---
        byte[] imagenBytes = null;
        String tipoImagen = null;
        Part imagenPart = null;

        try {
            // El nombre "imagenFile" debe coincidir con el 'name' del <input type="file"> en tu JSP
            imagenPart = request.getPart("imagenFile"); 
        } catch (ServletException e) {
            // Esto captura errores si la solicitud no es multipart o si la parte no se encuentra.
            // Para la integración sin cambios, simplemente logueamos y continuamos,
            // pero el formulario DEBE tener enctype="multipart/form-data".
            Logger.getLogger(CursoController.class.getName()).log(Level.WARNING, "No se pudo obtener la parte de la imagen. Esto es esperado si no se sube un archivo o si el formulario no es multipart/form-data.", e);
        }

        if (imagenPart != null && imagenPart.getSize() > 0) { // Verifica si se subió un archivo
            try (InputStream is = imagenPart.getInputStream()) {
                imagenBytes = is.readAllBytes(); // Lee todos los bytes del archivo
                tipoImagen = imagenPart.getContentType(); // Obtiene el tipo MIME (ej. "image/jpeg")
            } catch (IOException e) {
                Logger.getLogger(CursoController.class.getName()).log(Level.SEVERE, "Error al leer los bytes de la imagen subida.", e);
                // Aquí podrías decidir cómo manejar este error (ej. redirigir con un mensaje de error)
            }
        }

        // Asigna los bytes y el tipo de imagen al objeto Curso
        curso.setImagen(imagenBytes);
        curso.setTipoImagen(tipoImagen);
        // --- FIN DE INTEGRACIÓN DE IMAGEN ---

        try {
            switch (accion) {
                case "nuevo":
                    cursoDao.agregar(curso);
                    break;
                case "leer":
                    // El método leer en CursoDao devuelve un Curso por ID,
                    // aquí no se necesita una acción directa ya que se maneja en doGet
                    break;
                case "editar":
                    // Para 'editar', tu método cursoDao.actualizar() necesitará
                    // aceptar y guardar la imagen y el tipo de imagen también.
                    // Si el usuario no sube una nueva imagen, 'imagenBytes' e 'tipoImagen' serán null.
                    // Tu DAO debería manejar esto adecuadamente (ej. no actualizar la imagen si es null).
                    cursoDao.actualizar(curso);
                    break;
                case "eliminar":
                    cursoDao.eliminar(idCurso); // Eliminar por ID
                    break;
                default:
                    break;
            }
        } catch (Exception ex) { // Captura cualquier excepción para loguear
            Logger.getLogger(CursoController.class.getName()).log(Level.SEVERE, null, ex);
        }

        // Redirige siempre al listado de cursos después de una operación POST
        response.sendRedirect("curso/listado.jsp");
    }
}