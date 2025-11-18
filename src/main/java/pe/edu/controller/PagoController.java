package pe.edu.controller;

import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.logging.Level;
import java.util.logging.Logger;

import pe.edu.entity.Pago;
import pe.edu.dao.PagoDao;

@WebServlet(name = "PagoController", urlPatterns = {"/PagoController"})
public class PagoController extends HttpServlet {
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String pagina = request.getParameter("pagina");
        String idPago = request.getParameter("id");

        if (pagina != null) {
            if (pagina.equals("nuevo")) {
                response.sendRedirect("pago/" + pagina + ".jsp");
            } else {
                response.sendRedirect("pago/" + pagina + ".jsp?id=" + idPago);
            }
        } else {
            // Por defecto ir al listado
            response.sendRedirect("pago/listado.jsp");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        Pago pago = new Pago();
        PagoDao pagoDao = new PagoDao();
        String accion = request.getParameter("accion");

        String idPago = request.getParameter("idPago");
        String idAlumno = request.getParameter("idAlumno");
        String fechaPago = request.getParameter("fechaPago");
        String concepto = request.getParameter("concepto");
        String monto = request.getParameter("monto");
        String metodoPago = request.getParameter("metodoPago");
        String referencia = request.getParameter("referencia");

        try {          
            // Validar formato de fecha            

            if (idPago != null && !idPago.trim().isEmpty()) {
                pago.setIdPago(idPago);
            }

            pago.setIdAlumno(idAlumno);
            pago.setFechaPago(fechaPago);
            pago.setConcepto(concepto);
            pago.setMonto(monto);
            pago.setMetodoPago(metodoPago);
            pago.setReferencia(referencia);

            switch (accion) {
                case "nuevo":
                    pagoDao.insertar(pago);
                    break;
                case "leer":
                    // El método leer en CarreraDao devuelve una Carrera por ID, 
                    // aquí no se necesita una acción directa ya que se maneja en doGet
                    break; 
                case "editar":
                    pagoDao.editar(pago);
                    break;
                case "eliminar":
                    pagoDao.eliminar(idPago);
                    break;
                default:
                    // No hacer nada o manejar error
                    break;
            }

            request.getSession().setAttribute("mensaje", "Operación realizada exitosamente");

        } catch (NumberFormatException | DateTimeParseException e) {
            Logger.getLogger(PagoController.class.getName()).log(Level.SEVERE, null, e);
            request.getSession().setAttribute("error", "Error en los datos ingresados: " + e.getMessage());
        } catch (Exception ex) {
            Logger.getLogger(PagoController.class.getName()).log(Level.SEVERE, null, ex);
            request.getSession().setAttribute("error", "Error al realizar la operación: " + ex.getMessage());
        }

        response.sendRedirect("pago/listado.jsp");
    }
}
