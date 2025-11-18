package pe.edu.controller;

import java.io.IOException;
import java.util.logging.Level;
import java.util.logging.Logger;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import pe.edu.dao.HorarioDao;
import pe.edu.entity.Horario;

@WebServlet(name = "HorarioController", urlPatterns = {"/HorarioController"})
public class HorarioController extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String pagina = request.getParameter("pagina");
        String idHorario = request.getParameter("id");

        if (pagina != null) {
            if (pagina.equals("nuevo")) {
                response.sendRedirect("horario/nuevo.jsp");
            } else {
                response.sendRedirect("horario/" + pagina + ".jsp?id=" + idHorario);
            }
        } else {
            response.sendRedirect("horario/listado.jsp");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        
        Horario horario = new Horario();
        HorarioDao horarioDao = new HorarioDao();
        String accion = request.getParameter("accion");

        String id = request.getParameter("idHorario");
        String diaSemana = request.getParameter("diaSemana");
        String horaInicio = request.getParameter("horaInicio");
        String horaFin = request.getParameter("horaFin");
        String aula = request.getParameter("aula");

        if (id != null && !id.trim().isEmpty()) {
            horario.setIdHorario(id);
        }
        horario.setDiaSemana(diaSemana);
        horario.setHoraInicio(horaInicio);
        horario.setHoraFin(horaFin);
        horario.setAula(aula);

        try {
            switch (accion) {
                case "nuevo":
                    horario.setIdHorario(null); // Omitir ID si se genera automáticamente
                    horarioDao.insertar(horario);
                    break;
                case "editar":
                    horarioDao.editar(horario);
                    break;
                case "eliminar":
                    horarioDao.eliminar(id);
                    break;
                default:
                    request.getSession().setAttribute("error", "Acción no reconocida");
                    break;
            }
            request.getSession().setAttribute("mensaje", "Operación realizada exitosamente");

        } catch (Exception ex) {
            Logger.getLogger(HorarioController.class.getName()).log(Level.SEVERE, null, ex);
            request.getSession().setAttribute("error", "Error al realizar la operación: " + ex.getMessage());
        }

        response.sendRedirect("horario/listado.jsp");
    }

    @Override
    public String getServletInfo() {
        return "Controlador para la gestión de Horarios";
    }
}
