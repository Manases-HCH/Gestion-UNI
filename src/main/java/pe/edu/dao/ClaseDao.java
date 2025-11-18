package pe.edu.dao;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.LinkedList;
import java.util.logging.Level;
import java.util.logging.Logger;
import pe.edu.dao.DaoCrud;
import pe.edu.entity.Clase;
import pe.universidad.util.Conexion;

public class ClaseDao implements DaoCrud<Clase> {

    @Override
    public LinkedList<Clase> listar() {
        LinkedList<Clase> lista = new LinkedList<>();
        try {
            Conexion c = new Conexion();
            Connection cnx = c.conecta();
            CallableStatement sentencia = cnx.prepareCall("{call sp_listar_clases()}");
            ResultSet resultado = sentencia.executeQuery();

            while (resultado.next()) {
                Clase clase = new Clase();
                clase.setIdClase(resultado.getString("id_clase"));
                clase.setIdCurso(resultado.getString("nombre_curso"));
                clase.setIdProfesor(resultado.getString("nombre"));
                clase.setIdHorario(resultado.getString("dia_semana"));
                clase.setCiclo(resultado.getString("ciclo"));
                lista.add(clase);
            }
            // Cerrar recursos
            resultado.close();
            sentencia.close();
            cnx.close();
            return lista;
        } catch (SQLException e) {
            System.out.println("Error SQL al listar clases: " + e.getMessage());
            Logger.getLogger(ClaseDao.class.getName()).log(Level.SEVERE, null, e);
        } catch (ClassNotFoundException ex) {
            System.out.println("Error de clase no encontrada al listar clases: " + ex.getMessage());
            Logger.getLogger(ClaseDao.class.getName()).log(Level.SEVERE, null, ex);
        }
        return null;
    }

    @Override
    public void insertar(Clase obj) {
        try {
            Conexion c = new Conexion();
            Connection cnx = c.conecta();

            // Excluimos 'id_clase' porque es AUTO_INCREMENT
            String query = "INSERT INTO clases (id_curso, id_profesor, id_horario, ciclo) VALUES(?,?,?,?)";

            PreparedStatement sentencia = cnx.prepareStatement(query);

            sentencia.setString(1, obj.getIdCurso());
            sentencia.setString(2, obj.getIdProfesor());
            sentencia.setString(3, obj.getIdHorario());
            sentencia.setString(4, obj.getCiclo());

            sentencia.executeUpdate();
            sentencia.close();
            cnx.close();

            System.out.println("Clase insertada correctamente");

        } catch (SQLException e) {
            System.out.println("Error SQL al insertar clase: " + e.getMessage());
            Logger.getLogger(ClaseDao.class.getName()).log(Level.SEVERE, null, e);
        } catch (ClassNotFoundException ex) {
            System.out.println("Error de clase no encontrada al insertar clase: " + ex.getMessage());
            Logger.getLogger(ClaseDao.class.getName()).log(Level.SEVERE, null, ex);
        }
    }

    @Override
    public Clase leer(String id) {
        Clase clase = null;
        try {
            Conexion c = new Conexion();
            Connection cnx = c.conecta();
            String query = "SELECT * FROM clases WHERE id_clase=?";
            PreparedStatement sentencia = cnx.prepareStatement(query);
            sentencia.setString(1, id);
            ResultSet resultado = sentencia.executeQuery();

            if (resultado.next()) {
                clase = new Clase();
                clase.setIdClase(resultado.getString("id_clase"));
                clase.setIdCurso(resultado.getString("id_curso"));
                clase.setIdProfesor(resultado.getString("id_profesor"));
                clase.setIdHorario(resultado.getString("id_horario"));
                clase.setCiclo(resultado.getString("ciclo"));
            }
            // Cerrar recursos
            resultado.close();
            sentencia.close();
            cnx.close();
            return clase;
        } catch (SQLException e) {
            System.out.println("Error SQL al leer clase: " + e.getMessage());
            Logger.getLogger(ClaseDao.class.getName()).log(Level.SEVERE, null, e);
        } catch (ClassNotFoundException ex) {
            System.out.println("Error de clase no encontrada al leer clase: " + ex.getMessage());
            Logger.getLogger(ClaseDao.class.getName()).log(Level.SEVERE, null, ex);
        }
        return null;
    }

    @Override
    public void editar(Clase obj) {
        try {
            Conexion c = new Conexion();
            Connection cnx = c.conecta();
            String query = "UPDATE clases SET id_curso=?, id_profesor=?, id_horario=?, ciclo=? WHERE id_clase=?";
            PreparedStatement sentencia = cnx.prepareStatement(query);
            
            sentencia.setString(1, obj.getIdCurso());
            sentencia.setString(2, obj.getIdProfesor());
            sentencia.setString(3, obj.getIdHorario());
            sentencia.setString(4, obj.getCiclo());
            sentencia.setString(5, obj.getIdClase());
            
            sentencia.executeUpdate();
            sentencia.close();
            cnx.close();
            
            System.out.println("Clase editada correctamente");
            
        } catch (SQLException e) {
            System.out.println("Error SQL al editar clase: " + e.getMessage());
            Logger.getLogger(ClaseDao.class.getName()).log(Level.SEVERE, null, e);
        } catch (ClassNotFoundException ex) {
            System.out.println("Error de clase no encontrada al editar clase: " + ex.getMessage());
            Logger.getLogger(ClaseDao.class.getName()).log(Level.SEVERE, null, ex);
        }
    }

    @Override
    public void eliminar(String id) {
        try {
            Conexion c = new Conexion();
            Connection cnx = c.conecta();
            String query = "DELETE FROM clases WHERE id_clase=?";
            PreparedStatement sentencia = cnx.prepareStatement(query);
            sentencia.setString(1, id);
            sentencia.executeUpdate();
            sentencia.close();
            cnx.close();
            
            System.out.println("Clase eliminada correctamente");
            
        } catch (SQLException e) {
            System.out.println("Error SQL al eliminar clase: " + e.getMessage());
            Logger.getLogger(ClaseDao.class.getName()).log(Level.SEVERE, null, e);
        } catch (ClassNotFoundException ex) {
            System.out.println("Error de clase no encontrada al eliminar clase: " + ex.getMessage());
            Logger.getLogger(ClaseDao.class.getName()).log(Level.SEVERE, null, ex);
        }    
    }

    // Métodos adicionales específicos para clases
    
    /**
     * Lista todas las clases de un curso específico
     * @param idCurso ID del curso
     * @return Lista de clases del curso
     */
    public LinkedList<Clase> listarPorCurso(String idCurso) {
        LinkedList<Clase> lista = new LinkedList<>();
        try {
            Conexion c = new Conexion();
            Connection cnx = c.conecta();
            String query = "SELECT * FROM clases WHERE id_curso=? ORDER BY id_clase;";
            PreparedStatement sentencia = cnx.prepareStatement(query);
            sentencia.setString(1, idCurso);
            ResultSet resultado = sentencia.executeQuery();

            while (resultado.next()) {
                Clase clase = new Clase();
                clase.setIdClase(resultado.getString("id_clase"));
                clase.setIdCurso(resultado.getString("id_curso"));
                clase.setIdProfesor(resultado.getString("id_profesor"));
                clase.setIdHorario(resultado.getString("id_horario"));
                clase.setCiclo(resultado.getString("ciclo"));
                lista.add(clase);
            }
            // Cerrar recursos
            resultado.close();
            sentencia.close();
            cnx.close();
            return lista;
        } catch (SQLException e) {
            System.out.println("Error SQL al listar clases por curso: " + e.getMessage());
            Logger.getLogger(ClaseDao.class.getName()).log(Level.SEVERE, null, e);
        } catch (ClassNotFoundException ex) {
            System.out.println("Error de clase no encontrada al listar clases por curso: " + ex.getMessage());
            Logger.getLogger(ClaseDao.class.getName()).log(Level.SEVERE, null, ex);
        }
        return null;
    }

    /**
     * Lista todas las clases de un profesor específico
     * @param idProfesor ID del profesor
     * @return Lista de clases del profesor
     */
    public LinkedList<Clase> listarPorProfesor(String idProfesor) {
        LinkedList<Clase> lista = new LinkedList<>();
        try {
            Conexion c = new Conexion();
            Connection cnx = c.conecta();
            String query = "SELECT * FROM clases WHERE id_profesor=? ORDER BY id_clase;";
            PreparedStatement sentencia = cnx.prepareStatement(query);
            sentencia.setString(1, idProfesor);
            ResultSet resultado = sentencia.executeQuery();

            while (resultado.next()) {
                Clase clase = new Clase();
                clase.setIdClase(resultado.getString("id_clase"));
                clase.setIdCurso(resultado.getString("id_curso"));
                clase.setIdProfesor(resultado.getString("id_profesor"));
                clase.setIdHorario(resultado.getString("id_horario"));
                clase.setCiclo(resultado.getString("ciclo"));
                lista.add(clase);
            }
            // Cerrar recursos
            resultado.close();
            sentencia.close();
            cnx.close();
            return lista;
        } catch (SQLException e) {
            System.out.println("Error SQL al listar clases por profesor: " + e.getMessage());
            Logger.getLogger(ClaseDao.class.getName()).log(Level.SEVERE, null, e);
        } catch (ClassNotFoundException ex) {
            System.out.println("Error de clase no encontrada al listar clases por profesor: " + ex.getMessage());
            Logger.getLogger(ClaseDao.class.getName()).log(Level.SEVERE, null, ex);
        }
        return null;
    }

    /**
     * Lista todas las clases de un ciclo específico
     * @param ciclo Ciclo académico
     * @return Lista de clases del ciclo
     */
    public LinkedList<Clase> listarPorCiclo(String ciclo) {
        LinkedList<Clase> lista = new LinkedList<>();
        try {
            Conexion c = new Conexion();
            Connection cnx = c.conecta();
            String query = "SELECT * FROM clases WHERE ciclo=? ORDER BY id_clase;";
            PreparedStatement sentencia = cnx.prepareStatement(query);
            sentencia.setString(1, ciclo);
            ResultSet resultado = sentencia.executeQuery();

            while (resultado.next()) {
                Clase clase = new Clase();
                clase.setIdClase(resultado.getString("id_clase"));
                clase.setIdCurso(resultado.getString("id_curso"));
                clase.setIdProfesor(resultado.getString("id_profesor"));
                clase.setIdHorario(resultado.getString("id_horario"));
                clase.setCiclo(resultado.getString("ciclo"));
                lista.add(clase);
            }
            // Cerrar recursos
            resultado.close();
            sentencia.close();
            cnx.close();
            return lista;
        } catch (SQLException e) {
            System.out.println("Error SQL al listar clases por ciclo: " + e.getMessage());
            Logger.getLogger(ClaseDao.class.getName()).log(Level.SEVERE, null, e);
        } catch (ClassNotFoundException ex) {
            System.out.println("Error de clase no encontrada al listar clases por ciclo: " + ex.getMessage());
            Logger.getLogger(ClaseDao.class.getName()).log(Level.SEVERE, null, ex);
        }
        return null;
    }

    /**
     * Verifica si existe una clase con el ID especificado
     * @param idClase ID de la clase
     * @return true si existe, false si no existe
     */
    public boolean existe(String idClase) {
        try {
            Conexion c = new Conexion();
            Connection cnx = c.conecta();
            String query = "SELECT COUNT(*) as total FROM clases WHERE id_clase=?";
            PreparedStatement sentencia = cnx.prepareStatement(query);
            sentencia.setString(1, idClase);
            ResultSet resultado = sentencia.executeQuery();

            if (resultado.next()) {
                int total = resultado.getInt("total");
                // Cerrar recursos
                resultado.close();
                sentencia.close();
                cnx.close();
                return total > 0;
            }
            
            // Cerrar recursos
            resultado.close();
            sentencia.close();
            cnx.close();
            
        } catch (SQLException e) {
            System.out.println("Error SQL al verificar existencia de clase: " + e.getMessage());
            Logger.getLogger(ClaseDao.class.getName()).log(Level.SEVERE, null, e);
        } catch (ClassNotFoundException ex) {
            System.out.println("Error de clase no encontrada al verificar existencia de clase: " + ex.getMessage());
            Logger.getLogger(ClaseDao.class.getName()).log(Level.SEVERE, null, ex);
        }
        return false;
    }
}