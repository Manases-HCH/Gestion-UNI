package pe.edu.controller;

import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.util.logging.Level; // Importar para Logger
import java.util.logging.Logger; // Importar para Logger
import pe.edu.dao.NotaDao; // Asegúrate de que esta ruta sea correcta
import pe.edu.entity.Nota; // Asegúrate de que esta ruta sea correcta

@WebServlet(name = "NotaController", urlPatterns = {"/NotaController"})
public class NotaController extends HttpServlet {

    // Instancia del DAO: se crea una sola vez para ser reutilizada
   
    // Logger para registrar eventos y errores (como en AlumnoController)
    private static final Logger LOGGER = Logger.getLogger(NotaController.class.getName());

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String pagina = request.getParameter("pagina");
        String idNota = request.getParameter("id"); // Usar "id" para consistencia con AlumnoController

        if (pagina != null) {
            if (pagina.equals("nuevo")) {
                // Redirige al JSP para crear una nueva nota.
                // Nota: El AlumnoController usa response.sendRedirect aquí, así que lo replicamos.
                String path = "nota/" + pagina + ".jsp";
                response.sendRedirect(path);
            } else {
                // Para editar, ver o eliminar una nota existente, se pasa el ID.
                // Replica el comportamiento de AlumnoController con response.sendRedirect.
                String path = "nota/" + pagina + ".jsp?id=" + idNota;
                response.sendRedirect(path);
            }
        }
        // Si 'pagina' es null, no hay acción explícita, el controlador no hace nada
        // y se esperaría que el cliente ya esté en una página adecuada o se le redirija desde otro lado.
        // Si se desea un comportamiento por defecto, se podría añadir un else aquí.
        // Por ejemplo, para ir a un listado:
        // else {
        //    response.sendRedirect("nota/listado.jsp");
        // }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Se crea una nueva instancia de Nota y AlumnoDao en cada doPost (como en AlumnoController original)
        Nota nota = new Nota();
        NotaDao notaDao = new NotaDao();
        // NotaDao notaDao = new NotaDao(); // <-- Ya está como atributo de la clase, no re-instanciar aquí
        String accion = request.getParameter("accion");

        // Obtener todos los parámetros necesarios del formulario para un objeto Nota
        String id = request.getParameter("id"); // Asumiendo que el ID de la nota se pasa como 'id' (consistencia con AlumnoController)
        String idInscripcion = request.getParameter("idInscripcion");
        String nota1Str = request.getParameter("nota1");
        String nota2Str = request.getParameter("nota2");
        // Variables temporales para el cálculo
        // Variables temporales para el cálculo (inicializadas, pero sus valores son temporales antes del cálculo)
    double nota1Double = 0.0;
    double nota2Double = 0.0;
    double notaFinalDouble = 0.0; // Cambiado de 'notaFinal' para evitar conflicto y ser más claro
    String estadoCalculado = ""; // Cambiado de 'estado' para ser más claro

    // Establecer idNota e idInscripcion en el objeto Nota ANTES del bloque try-catch,
    // ya que no dependen de conversiones numéricas y son necesarios para validaciones.
    if (id != null && !id.trim().isEmpty()) {
        nota.setIdNota(id); 
    }
    // ESTA LÍNEA YA ESTABA AQUÍ, y es la correcta para asignar idInscripcion temprano.
    nota.setIdInscripcion(idInscripcion); 

    try {
        // Validaciones iniciales
        // Ya se estableció nota.setIdInscripcion(idInscripcion) fuera del try-catch para evitar duplicidad.
        if (idInscripcion == null || idInscripcion.trim().isEmpty()) {
            request.getSession().setAttribute("error", "El ID de Inscripción es obligatorio.");
            response.sendRedirect("nota/listado.jsp");
            return;
        }

        // 2. Convertir las notas de String a double para poder calcular
        if (nota1Str != null && !nota1Str.trim().isEmpty()) {
            nota1Double = Double.parseDouble(nota1Str);
        } else {
            throw new NumberFormatException("La Nota 1 es obligatoria y debe ser un número.");
        }

        if (nota2Str != null && !nota2Str.trim().isEmpty()) {
            nota2Double = Double.parseDouble(nota2Str);
        } else {
            throw new NumberFormatException("La Nota 2 es obligatoria y debe ser un número.");
        }

        // Validar rango de notas (opcional, pero buena práctica)
        if (nota1Double < 0 || nota1Double > 20 || nota2Double < 0 || nota2Double > 20) {
            request.getSession().setAttribute("error", "Las notas deben estar entre 0 y 20.");
            response.sendRedirect("nota/listado.jsp");
            return;
        }

        // 3. Calcular la Nota Final (promedio)
        // CORREGIDO: Asignación directa a la variable double
        notaFinalDouble = (nota1Double + nota2Double) / 2.0;

        // 4. Determinar el Estado
        if (notaFinalDouble >= 13.0) { // Mayor o igual a 13 (asumiendo "mayor a 12")
            estadoCalculado = "Aprobado";
        } else {
            estadoCalculado = "Desaprobado";
        }
        
        // 5. Asignar las notas y el estado (calculados) al objeto Nota
        // ESTO DEBE IR DESPUÉS DE LOS CÁLCULOS
        nota.setNota1(nota1Str); // Se mantiene el String original del input
        nota.setNota2(nota2Str); // Se mantiene el String original del input
        // Formateamos la nota final a 2 decimales antes de convertirla a String
        nota.setNotaFinal(String.format("%.2f", notaFinalDouble));
        nota.setEstado(estadoCalculado);
        
            switch (accion) {
                case "nuevo":
                    // Para nueva nota, no establecer ID (será auto-generado si la BD lo soporta)
                    // Establece el ID de la nota a null. Esto es una convención común
                    // para indicar que la base de datos debe generar un nuevo ID para esta entrada.
                    nota.setIdNota(null); 
                    
                    // Llama al método insertar del DAO, pasando el objeto 'nota'
                    // que ya contiene todos los datos (idInscripcion, nota1, nota2, notaFinal, estado)
                    notaDao.insertar(nota);
                    
                    // Registro en el log para fines de depuración o auditoría
                    LOGGER.log(Level.INFO, "Nueva nota insertada para Inscripción: {0}, Nota Final: {1}, Estado: {2}", 
                                new Object[]{idInscripcion, nota.getNotaFinal(), nota.getEstado()});
                    
                    // Mensaje de éxito para el usuario (se almacenará en la sesión)
                    request.getSession().setAttribute("mensaje", "Nota registrada correctamente.");
                    break; // Termina el bloque del switch
                case "leer":
                    // Como en AlumnoController, la acción "leer" se maneja en doGet si es para mostrar un formulario.
                    // Si fuera para un API REST, aquí se manejaría la lógica de lectura y retorno de datos.
                    // Por ahora, se deja vacío, ya que el doGet lo maneja con forward.
                    LOGGER.log(Level.INFO, "Acción 'leer' en POST de NotaController no realiza operación directa.");
                    break;
                case "editar":
                    notaDao.editar(nota);
                    LOGGER.log(Level.INFO, "Nota con ID {0} editada.", id);
                    break;
                case "eliminar":
                    notaDao.eliminar(id); // Eliminar por ID
                    LOGGER.log(Level.INFO, "Nota con ID {0} eliminada.", id);
                    break;
                default:
                    LOGGER.log(Level.WARNING, "Acción no válida recibida en NotaController POST: {0}", accion);
                    break;
            }

            // Mensaje de éxito (opcional, como en AlumnoController)
            request.getSession().setAttribute("mensaje", "Operación realizada exitosamente.");

        } catch (Exception ex) {
            // Captura cualquier excepción para loguear (como en AlumnoController)
            LOGGER.log(Level.SEVERE, "Error en NotaController al procesar acción: " + accion, ex);

            // Mensaje de error (opcional, como en AlumnoController)
            request.getSession().setAttribute("error", "Error al realizar la operación: " + ex.getMessage());
        }

        // Redirige siempre al listado de notas después de una operación POST (como en AlumnoController)
        response.sendRedirect("nota/listado.jsp");
    }

    // El método datosCompletos no existe en el AlumnoController proporcionado para POST,
    // por lo que lo eliminamos para mantener la coherencia.
    // Si era intencional en NotaController, podrías considerarlo una mejora.
    /*
    private boolean datosCompletos(String inscripcion, String n1, String n2, String nf, String estado) {
        return inscripcion != null && !inscripcion.isEmpty() &&
               n1 != null && !n1.isEmpty() &&
               n2 != null && !n2.isEmpty() &&
               nf != null && !nf.isEmpty() &&
               estado != null && !estado.isEmpty();
    }
    */

    @Override
    public String getServletInfo() {
        return "Controlador para la gestión de Notas";
    }
}   