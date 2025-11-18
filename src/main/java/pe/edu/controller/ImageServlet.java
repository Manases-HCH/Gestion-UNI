package pe.edu.controller; // Asegúrate de que este sea el paquete correcto donde lo quieres colocar

import java.io.IOException;
import java.io.OutputStream; // Necesario para escribir los bytes de la imagen en la respuesta
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet; // Para mapear el servlet a una URL
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import pe.edu.dao.CursoDao; // Importa tu DAO de Curso
import pe.edu.entity.Curso; // Importa tu clase de entidad Curso

@WebServlet("/ImageServlet") // Esta anotación mapea este servlet a la URL "/ImageServlet"
public class ImageServlet extends HttpServlet {

    // Instancia de tu CursoDao. Es buena práctica tenerla como miembro de la clase
    // para que se inicialice una vez y no en cada solicitud.
    private CursoDao cursoDao = new CursoDao();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        // 1. Obtener el ID del curso desde los parámetros de la solicitud
        // La JSP enviará el ID como: <img src="ImageServlet?id=ABC">
        String idCurso = request.getParameter("id");

        // 2. Validar que el ID no sea nulo o vacío
        if (idCurso == null || idCurso.isEmpty()) {
            // Si no hay ID, no podemos saber qué imagen servir.
            // Enviamos un error 400 (Bad Request)
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "ID de curso no especificado para la imagen.");
            return; // Termina la ejecución del método
        }

        try {
            // 3. Usar el DAO para leer el objeto Curso completo desde la base de datos
            // Esto asume que tu CursoDao tiene un método 'leer' que puede devolver un Curso por su ID
            Curso curso = cursoDao.leer(idCurso); // Asume que cursoDao.leer(String id) existe y funciona

            // 4. Verificar si el curso fue encontrado y si tiene una imagen
            if (curso != null && curso.getImagen() != null && curso.getImagen().length > 0) {
                // 5. Establecer los encabezados de la respuesta HTTP para la imagen
                // Esto le dice al navegador qué tipo de contenido está recibiendo y su tamaño.
                response.setContentType(curso.getTipoImagen()); // ej: "image/jpeg", "image/png"
                response.setContentLength(curso.getImagen().length); // El tamaño en bytes de la imagen

                // 6. Obtener el OutputStream de la respuesta para escribir los bytes de la imagen
                try (OutputStream out = response.getOutputStream()) {
                    // 7. Escribir los bytes de la imagen directamente en el flujo de salida de la respuesta
                    out.write(curso.getImagen());
                    out.flush(); // Asegurarse de que todos los bytes se envíen
                }
            } else {
                // 8. Si el curso no existe o no tiene imagen, enviar un error 404 (Not Found)
                // Opcional: podrías servir una imagen de placeholder (ej. una imagen "no-disponible.png")
                // Para servir una imagen de placeholder:
                // InputStream placeholder = getServletContext().getResourceAsStream("/resources/img/no-image.png");
                // if (placeholder != null) { ... copiar bytes de placeholder a response ... }
                // else { response.sendError(...) }
                response.sendError(HttpServletResponse.SC_NOT_FOUND, "Imagen no encontrada para el curso con ID: " + idCurso);
            }
        } catch (Exception e) {
            // 9. Manejar cualquier excepción durante el proceso (ej. error de base de datos)
            // Es crucial loguear el error para depuración en el servidor.
            System.err.println("Error en ImageServlet al recuperar imagen para ID: " + idCurso + " - " + e.getMessage());
            e.printStackTrace(); // Imprime la traza completa del error en la consola del servidor
            // Envía un error 500 (Internal Server Error) al cliente
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Error interno al recuperar la imagen.");
        }
    }
}