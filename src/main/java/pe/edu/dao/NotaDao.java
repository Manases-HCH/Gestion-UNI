package pe.edu.dao;

import java.sql.CallableStatement; // Importar CallableStatement
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.LinkedList;
import java.util.logging.Level;
import java.util.logging.Logger;
import pe.edu.entity.Nota; // Importar la entidad Nota
import pe.universidad.util.Conexion; // Asegúrate de que esta ruta sea correcta

public class NotaDao implements DaoCrud<Nota> {

    @Override
    public LinkedList<Nota> listar() {
        LinkedList<Nota> lista = new LinkedList<>();
        Connection cnx = null;
        CallableStatement cs = null; // Cambiado de Statement a CallableStatement
        ResultSet resultado = null;
        try {
            Conexion c = new Conexion();
            cnx = c.conecta();

            // Llama al procedimiento almacenado para listar notas
            cs = cnx.prepareCall("{call sp_listar_notas()}"); //
            resultado = cs.executeQuery();

            while (resultado.next()) {
                Nota nota = new Nota();
                // Obtener los valores reales del ResultSet por el nombre de la columna
                nota.setIdNota(resultado.getString("id_nota")); //
                nota.setIdInscripcion(resultado.getString("id_inscripcion")); //
                nota.setNota1(resultado.getString("nota1")); //
                nota.setNota2(resultado.getString("nota2")); //
                nota.setNotaFinal(resultado.getString("nota_final")); //
                nota.setEstado(resultado.getString("estado")); //
                lista.add(nota);
            }
            return lista;
        } catch (SQLException e) {
            System.out.println("Error SQL al listar notas: " + e.getMessage());
            Logger.getLogger(NotaDao.class.getName()).log(Level.SEVERE, null, e);
        } catch (ClassNotFoundException ex) {
            System.out.println("Error de clase no encontrada al listar notas: " + ex.getMessage());
            Logger.getLogger(NotaDao.class.getName()).log(Level.SEVERE, null, ex);
        } finally {
            try {
                if (resultado != null) resultado.close();
                if (cs != null) cs.close(); // Cerrar CallableStatement
                if (cnx != null) cnx.close();
            } catch (SQLException ex) {
                Logger.getLogger(NotaDao.class.getName()).log(Level.SEVERE, null, ex);
            }
        }
        return null; // Retornar null si hay un error
    }

    @Override
    public void insertar(Nota obj) {
        Connection cnx = null;
        CallableStatement cs = null; // Cambiado de PreparedStatement a CallableStatement
        try {
            Conexion c = new Conexion();
            cnx = c.conecta();

            // Llama al procedimiento almacenado para insertar nota
            // sp_insertar_nota(p_id_inscripcion, p_nota1, p_nota2, p_nota_final, p_estado)
            cs = cnx.prepareCall("{call sp_insertar_nota(?,?,?,?,?)}"); //

            cs.setInt(1, Integer.parseInt(obj.getIdInscripcion())); //
            cs.setDouble(2, Double.parseDouble(obj.getNota1())); //
            cs.setDouble(3, Double.parseDouble(obj.getNota2())); //
            cs.setDouble(4, Double.parseDouble(obj.getNotaFinal())); //
            cs.setString(5, obj.getEstado()); //

            cs.executeUpdate();
            System.out.println("Nota insertada correctamente");

        } catch (SQLException e) {
            System.out.println("Error SQL al insertar nota: " + e.getMessage());
            Logger.getLogger(NotaDao.class.getName()).log(Level.SEVERE, null, e);
        } catch (ClassNotFoundException ex) {
            System.out.println("Error de clase no encontrada al insertar nota: " + ex.getMessage());
            Logger.getLogger(NotaDao.class.getName()).log(Level.SEVERE, null, ex);
        } catch (NumberFormatException e) {
            System.out.println("Error de formato de número al insertar nota: " + e.getMessage());
            Logger.getLogger(NotaDao.class.getName()).log(Level.SEVERE, null, e);
        } finally {
            try {
                if (cs != null) cs.close(); // Cerrar CallableStatement
                if (cnx != null) cnx.close();
            } catch (SQLException ex) {
                Logger.getLogger(NotaDao.class.getName()).log(Level.SEVERE, null, ex);
            }
        }
    }

    @Override
    public Nota leer(String id) { // El ID de la nota se pasa como String desde la URL
        Nota nota = null;
        Connection cnx = null;
        CallableStatement cs = null; // Cambiado de PreparedStatement a CallableStatement
        ResultSet resultado = null;
        try {
            Conexion c = new Conexion();
            cnx = c.conecta();
            
            // Llama al procedimiento almacenado para obtener nota por ID
            cs = cnx.prepareCall("{call sp_obtener_nota(?)}"); //
            cs.setInt(1, Integer.parseInt(id)); //
            resultado = cs.executeQuery();

            if (resultado.next()) {
                nota = new Nota();
                // Obtener los valores reales del ResultSet por el nombre de la columna
                nota.setIdNota(resultado.getString("id_nota")); //
                nota.setIdInscripcion(resultado.getString("id_inscripcion")); //
                nota.setNota1(resultado.getString("nota1")); //
                nota.setNota2(resultado.getString("nota2")); //
                nota.setNotaFinal(resultado.getString("nota_final")); //
                nota.setEstado(resultado.getString("estado")); //
            }
            return nota;
        } catch (SQLException e) {
            System.out.println("Error SQL al leer nota: " + e.getMessage());
            Logger.getLogger(NotaDao.class.getName()).log(Level.SEVERE, null, e);
        } catch (ClassNotFoundException ex) {
            System.out.println("Error de clase no encontrada al leer nota: " + ex.getMessage());
            Logger.getLogger(NotaDao.class.getName()).log(Level.SEVERE, null, ex);
        } catch (NumberFormatException e) {
            System.out.println("Error de formato de número al leer nota (ID no es un entero): " + e.getMessage());
            Logger.getLogger(NotaDao.class.getName()).log(Level.SEVERE, null, e);
        } finally {
            try {
                if (resultado != null) resultado.close();
                if (cs != null) cs.close(); // Cerrar CallableStatement
                if (cnx != null) cnx.close();
            } catch (SQLException ex) {
                Logger.getLogger(NotaDao.class.getName()).log(Level.SEVERE, null, ex);
            }
        }
        return null;
    }

    @Override
    public void editar(Nota obj) {
        Connection cnx = null;
        CallableStatement cs = null; // Cambiado de PreparedStatement a CallableStatement
        try {
            Conexion c = new Conexion();
            cnx = c.conecta();
            
            // Llama al procedimiento almacenado para editar nota
            // sp_editar_nota(p_id_nota, p_id_inscripcion, p_nota1, p_nota2, p_nota_final, p_estado)
            cs = cnx.prepareCall("{call sp_editar_nota(?,?,?,?,?,?)}"); //
            
            cs.setInt(1, Integer.parseInt(obj.getIdNota())); //
            cs.setInt(2, Integer.parseInt(obj.getIdInscripcion())); //
            cs.setDouble(3, Double.parseDouble(obj.getNota1())); //
            cs.setDouble(4, Double.parseDouble(obj.getNota2())); //
            cs.setDouble(5, Double.parseDouble(obj.getNotaFinal())); //
            cs.setString(6, obj.getEstado()); //
            
            cs.executeUpdate();
            System.out.println("Nota editada correctamente");
            
        } catch (SQLException e) {
            System.out.println("Error SQL al editar nota: " + e.getMessage());
            Logger.getLogger(NotaDao.class.getName()).log(Level.SEVERE, null, e);
        } catch (ClassNotFoundException ex) {
            System.out.println("Error de clase no encontrada al editar nota: " + ex.getMessage());
            Logger.getLogger(NotaDao.class.getName()).log(Level.SEVERE, null, ex);
        } catch (NumberFormatException e) {
            System.out.println("Error de formato de número al editar nota: " + e.getMessage());
            Logger.getLogger(NotaDao.class.getName()).log(Level.SEVERE, null, e);
        } finally {
            try {
                if (cs != null) cs.close(); // Cerrar CallableStatement
                if (cnx != null) cnx.close();
            } catch (SQLException ex) {
                Logger.getLogger(NotaDao.class.getName()).log(Level.SEVERE, null, ex);
            }
        }
    }

    @Override
    public void eliminar(String id) { // El ID de la nota se pasa como String desde la URL
        Connection cnx = null;
        CallableStatement cs = null; // Cambiado de PreparedStatement a CallableStatement
        try {
            Conexion c = new Conexion();
            cnx = c.conecta();
            
            // Llama al procedimiento almacenado para eliminar nota
            // sp_eliminar_nota(p_id_nota)
            cs = cnx.prepareCall("{call sp_eliminar_nota(?)}"); //
            cs.setInt(1, Integer.parseInt(id)); //
            cs.executeUpdate();
            
            System.out.println("Nota eliminada correctamente");
            
        } catch (SQLException e) {
            System.out.println("Error SQL al eliminar nota: " + e.getMessage());
            Logger.getLogger(NotaDao.class.getName()).log(Level.SEVERE, null, e);
        } catch (ClassNotFoundException ex) {
            System.out.println("Error de clase no encontrada al eliminar nota: " + ex.getMessage());
            Logger.getLogger(NotaDao.class.getName()).log(Level.SEVERE, null, ex);
        } catch (NumberFormatException e) {
            System.out.println("Error de formato de número al eliminar nota (ID no es un entero): " + e.getMessage());
            Logger.getLogger(NotaDao.class.getName()).log(Level.SEVERE, null, e);
        } finally {
            try {
                if (cs != null) cs.close(); // Cerrar CallableStatement
                if (cnx != null) cnx.close();
            } catch (SQLException ex) {
                Logger.getLogger(NotaDao.class.getName()).log(Level.SEVERE, null, ex);
            }
        }       
    }
}