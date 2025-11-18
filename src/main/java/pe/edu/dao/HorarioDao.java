package pe.edu.dao;

import java.sql.CallableStatement; // Importar CallableStatement
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.LinkedList;
import java.util.logging.Level;
import java.util.logging.Logger;
import pe.edu.entity.Horario; // Importar la entidad Horario
import pe.universidad.util.Conexion; // Asegúrate de que esta ruta sea correcta

public class HorarioDao implements DaoCrud<Horario> {

    @Override
    public LinkedList<Horario> listar() {
        LinkedList<Horario> lista = new LinkedList<>();
        Connection cnx = null;
        CallableStatement cs = null; // Usar CallableStatement
        ResultSet resultado = null;
        try {
            Conexion c = new Conexion();
            cnx = c.conecta();

            // Llamada al procedimiento almacenado para listar horarios
            cs = cnx.prepareCall("{call sp_listar_horarios()}");
            resultado = cs.executeQuery();

            while (resultado.next()) {
                Horario horario = new Horario();
                horario.setIdHorario(resultado.getString("id_horario")); // Correcto: Obtener el valor del ResultSet
                horario.setDiaSemana(resultado.getString("dia_semana"));
                horario.setHoraInicio(resultado.getString("hora_inicio")); // Asumiendo que el entity lo maneja como String "HH:MM:SS"
                horario.setHoraFin(resultado.getString("hora_fin"));     // Asumiendo que el entity lo maneja como String "HH:MM:SS"
                horario.setAula(resultado.getString("aula"));
                lista.add(horario);
            }
        } catch (SQLException e) {
            System.out.println("Error SQL al listar horarios: " + e.getMessage());
            Logger.getLogger(HorarioDao.class.getName()).log(Level.SEVERE, "Error SQL al listar horarios", e);
        } catch (ClassNotFoundException ex) {
            System.out.println("Error de clase no encontrada al listar horarios: " + ex.getMessage());
            Logger.getLogger(HorarioDao.class.getName()).log(Level.SEVERE, "Error de clase no encontrada al listar horarios", ex);
        } finally {
            try {
                if (resultado != null) resultado.close();
                if (cs != null) cs.close(); // Cerrar CallableStatement
                if (cnx != null) cnx.close();
            } catch (SQLException ex) {
                Logger.getLogger(HorarioDao.class.getName()).log(Level.SEVERE, "Error al cerrar recursos en listar", ex);
            }
        }
        return lista; // Si no hay resultados o hay error, devuelve lista vacía o null si prefieres.
    }

    @Override
    public void insertar(Horario obj) {
        Connection cnx = null;
        CallableStatement cs = null; // Usar CallableStatement
        try {
            Conexion c = new Conexion();
            cnx = c.conecta();

            // Llamada al procedimiento almacenado para insertar horario
            cs = cnx.prepareCall("{call sp_insertar_horario(?,?,?,?)}");

            cs.setString(1, obj.getDiaSemana());
            cs.setString(2, obj.getHoraInicio()); // Asumiendo que el entity lo maneja como String "HH:MM:SS"
            cs.setString(3, obj.getHoraFin());     // Asumiendo que el entity lo maneja como String "HH:MM:SS"
            cs.setString(4, obj.getAula()); // Si obj.getAula() es null, JDBC lo mapea a SQL NULL

            cs.executeUpdate();
            System.out.println("Horario insertado correctamente");

        } catch (SQLException e) {
            System.out.println("Error SQL al insertar horario: " + e.getMessage());
            Logger.getLogger(HorarioDao.class.getName()).log(Level.SEVERE, "Error SQL al insertar horario", e);
        } catch (ClassNotFoundException ex) {
            System.out.println("Error de clase no encontrada al insertar horario: " + ex.getMessage());
            Logger.getLogger(HorarioDao.class.getName()).log(Level.SEVERE, "Error de clase no encontrada al insertar horario", ex);
        } finally {
            try {
                if (cs != null) cs.close(); // Cerrar CallableStatement
                if (cnx != null) cnx.close();
            } catch (SQLException ex) {
                Logger.getLogger(HorarioDao.class.getName()).log(Level.SEVERE, "Error al cerrar recursos en insertar", ex);
            }
        }
    }

    @Override
    public Horario leer(String id) { // El ID del horario se pasa como String desde la URL
        Horario horario = null;
        Connection cnx = null;
        CallableStatement cs = null; // Usar CallableStatement
        ResultSet resultado = null;
        try {
            Conexion c = new Conexion();
            cnx = c.conecta();

            // Llamada al procedimiento almacenado para obtener horario por ID
            cs = cnx.prepareCall("{call sp_obtener_horario(?)}");
            cs.setInt(1, Integer.parseInt(id)); // Convertir String a int para el ID
            resultado = cs.executeQuery();

            if (resultado.next()) {
                horario = new Horario();
                horario.setIdHorario(resultado.getString("id_horario")); // Correcto
                horario.setDiaSemana(resultado.getString("dia_semana"));
                horario.setHoraInicio(resultado.getString("hora_inicio"));
                horario.setHoraFin(resultado.getString("hora_fin"));
                horario.setAula(resultado.getString("aula"));
            }
        } catch (SQLException e) {
            System.out.println("Error SQL al leer horario: " + e.getMessage());
            Logger.getLogger(HorarioDao.class.getName()).log(Level.SEVERE, "Error SQL al leer horario", e);
        } catch (ClassNotFoundException ex) {
            System.out.println("Error de clase no encontrada al leer horario: " + ex.getMessage());
            Logger.getLogger(HorarioDao.class.getName()).log(Level.SEVERE, "Error de clase no encontrada al leer horario", ex);
        } catch (NumberFormatException e) {
            System.out.println("Error de formato de número al leer horario (ID no es un entero): " + e.getMessage());
            Logger.getLogger(HorarioDao.class.getName()).log(Level.SEVERE, "Error de formato de número al leer horario", e);
        } finally {
            try {
                if (resultado != null) resultado.close();
                if (cs != null) cs.close(); // Cerrar CallableStatement
                if (cnx != null) cnx.close();
            } catch (SQLException ex) {
                Logger.getLogger(HorarioDao.class.getName()).log(Level.SEVERE, "Error al cerrar recursos en leer", ex);
            }
        }
        return horario;
    }

    @Override
    public void editar(Horario obj) {
        Connection cnx = null;
        CallableStatement cs = null; // Usar CallableStatement
        try {
            Conexion c = new Conexion();
            cnx = c.conecta();

            // Llamada al procedimiento almacenado para editar horario
            cs = cnx.prepareCall("{call sp_editar_horario(?,?,?,?,?)}"); // 5 parámetros

            cs.setInt(1, Integer.parseInt(obj.getIdHorario())); // El ID para la condición WHERE
            cs.setString(2, obj.getDiaSemana());
            cs.setString(3, obj.getHoraInicio());
            cs.setString(4, obj.getHoraFin());
            cs.setString(5, obj.getAula());

            cs.executeUpdate();
            System.out.println("Horario editado correctamente");

        } catch (SQLException e) {
            System.out.println("Error SQL al editar horario: " + e.getMessage());
            Logger.getLogger(HorarioDao.class.getName()).log(Level.SEVERE, "Error SQL al editar horario", e);
        } catch (ClassNotFoundException ex) {
            System.out.println("Error de clase no encontrada al editar horario: " + ex.getMessage());
            Logger.getLogger(HorarioDao.class.getName()).log(Level.SEVERE, "Error de clase no encontrada al editar horario", ex);
        } catch (NumberFormatException e) {
            System.out.println("Error de formato de número al editar horario (ID no es un entero): " + e.getMessage());
            Logger.getLogger(HorarioDao.class.getName()).log(Level.SEVERE, "Error de formato de número al editar horario", e);
        } finally {
            try {
                if (cs != null) cs.close(); // Cerrar CallableStatement
                if (cnx != null) cnx.close();
            } catch (SQLException ex) {
                Logger.getLogger(HorarioDao.class.getName()).log(Level.SEVERE, "Error al cerrar recursos en editar", ex);
            }
        }
    }

    @Override
    public void eliminar(String id) { // El ID del horario se pasa como String desde la URL
        Connection cnx = null;
        CallableStatement cs = null; // Usar CallableStatement
        try {
            Conexion c = new Conexion();
            cnx = c.conecta();

            // Llamada al procedimiento almacenado para eliminar horario
            cs = cnx.prepareCall("{call sp_eliminar_horario(?)}");
            cs.setInt(1, Integer.parseInt(id)); // Convertir String a int para el ID
            cs.executeUpdate();

            System.out.println("Horario eliminado correctamente");

        } catch (SQLException e) {
            System.out.println("Error SQL al eliminar horario: " + e.getMessage());
            Logger.getLogger(HorarioDao.class.getName()).log(Level.SEVERE, "Error SQL al eliminar horario", e);
        } catch (ClassNotFoundException ex) {
            System.out.println("Error de clase no encontrada al eliminar horario: " + ex.getMessage());
            Logger.getLogger(HorarioDao.class.getName()).log(Level.SEVERE, "Error de clase no encontrada al eliminar horario", ex);
        } catch (NumberFormatException e) {
            System.out.println("Error de formato de número al eliminar horario (ID no es un entero): " + e.getMessage());
            Logger.getLogger(HorarioDao.class.getName()).log(Level.SEVERE, "Error de formato de número al eliminar horario", e);
        } finally {
            try {
                if (cs != null) cs.close(); // Cerrar CallableStatement
                if (cnx != null) cnx.close();
            } catch (SQLException ex) {
                Logger.getLogger(HorarioDao.class.getName()).log(Level.SEVERE, "Error al cerrar recursos en eliminar", ex);
            }
        }
    }
}