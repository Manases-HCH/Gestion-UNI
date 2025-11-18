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
import pe.edu.entity.Facultad; // Importar la entidad Facultad
import pe.universidad.util.Conexion; // Asegúrate de que esta ruta sea correcta

public class FacultadDao implements DaoCrud<Facultad> {

    @Override
    public LinkedList<Facultad> listar() {
        LinkedList<Facultad> lista = new LinkedList<>();        
        try {
            Conexion c = new Conexion();
            Connection cnx = c.conecta();

            CallableStatement cs = cnx.prepareCall("{call sp_listar_facultades()}");
            ResultSet resultado = cs.executeQuery();

            while (resultado.next()) {
                Facultad facultad = new Facultad();
                facultad.setIdFacultad(resultado.getString("id_facultad")); // Asumiendo String para id_facultad
                facultad.setNombreFacultad(resultado.getString("nombre_facultad")); // Columnas de tu tabla
                lista.add(facultad);
            }
            return lista;
        } catch (SQLException e) {
            System.out.println("Error SQL al listar facultades: " + e.getMessage());
            Logger.getLogger(FacultadDao.class.getName()).log(Level.SEVERE, null, e);
        } catch (ClassNotFoundException ex) {
            System.out.println("Error de clase no encontrada al listar facultades: " + ex.getMessage());
            Logger.getLogger(FacultadDao.class.getName()).log(Level.SEVERE, null, ex);
        }
        return null;
    }

    @Override
    public void insertar(Facultad obj) {
        try {
            Conexion c = new Conexion();
        Connection cnx = c.conecta();

        // Excluimos 'id' porque es AUTO_INCREMENT
        // Corrected: 10 columns and 10 placeholders
        CallableStatement sentencia = cnx.prepareCall("{call sp_insertar_facultad(?)}");
            sentencia.setString(1, obj.getNombreFacultad());

            sentencia.executeUpdate();
           
        sentencia.executeUpdate();
        sentencia.close();
        cnx.close(); 
        System.out.println("Facultad insertada correctamente");
        } catch (SQLException e) {
            System.out.println("Error SQL al insertar facultad: " + e.getMessage());
            Logger.getLogger(FacultadDao.class.getName()).log(Level.SEVERE, null, e);
        } catch (ClassNotFoundException ex) {
            System.out.println("Error de clase no encontrada al insertar facultad: " + ex.getMessage());
            Logger.getLogger(FacultadDao.class.getName()).log(Level.SEVERE, null, ex);
        }
    }

    @Override
    public Facultad leer(String id) { // El ID de la facultad se muestra como String en tu tabla
        Facultad facultad = null;       
        try {
            Conexion c = new Conexion();
            Connection cnx = c.conecta();

            CallableStatement cs = cnx.prepareCall("{call sp_obtener_facultad(?)}");
            cs.setString(1, id);
            ResultSet resultado = cs.executeQuery();

            if (resultado.next()) {
                facultad = new Facultad();
                facultad.setIdFacultad(resultado.getString("id_facultad")); // Asumiendo String para id_facultad
                facultad.setNombreFacultad(resultado.getString("nombre_facultad")); // Columnas de tu tabla
            }
            resultado.close();
            cs.close();
            cnx.close();
            return facultad;
        } catch (SQLException e) {
            System.out.println("Error SQL al leer facultad: " + e.getMessage());
            Logger.getLogger(FacultadDao.class.getName()).log(Level.SEVERE, null, e);
        } catch (ClassNotFoundException ex) {
            System.out.println("Error de clase no encontrada al leer facultad: " + ex.getMessage());
            Logger.getLogger(FacultadDao.class.getName()).log(Level.SEVERE, null, ex);
        } 
        
        return null;
    }

    @Override
    public void editar(Facultad obj) {
        Connection cnx = null;
        try {
            Conexion c = new Conexion();
            cnx = c.conecta();
            CallableStatement cs = cnx.prepareCall("{call sp_editar_facultad(?,?)}");
            cs.setString(1, obj.getIdFacultad());
            cs.setString(2, obj.getNombreFacultad());
                       
            cs.executeUpdate();
            cs.close();
            cnx.close();
            System.out.println("Facultad editada correctamente");
            
        } catch (SQLException e) {
            System.out.println("Error SQL al editar facultad: " + e.getMessage());
            Logger.getLogger(FacultadDao.class.getName()).log(Level.SEVERE, null, e);
        } catch (ClassNotFoundException ex) {
            System.out.println("Error de clase no encontrada al editar facultad: " + ex.getMessage());
            Logger.getLogger(FacultadDao.class.getName()).log(Level.SEVERE, null, ex);
        } 
    }

    @Override
    public void eliminar(String id) {
        Connection cnx = null;
        PreparedStatement sentencia = null;
        try {
            Conexion c = new Conexion();
            cnx = c.conecta();
            String query = "DELETE FROM facultades WHERE id_facultad=?"; // Columnas de tu tabla
            sentencia = cnx.prepareStatement(query);
            sentencia.setInt(1, Integer.parseInt(id));
            sentencia.executeUpdate();
            System.out.println("Facultad eliminada correctamente");
            
        } catch (SQLException e) {
            System.out.println("Error SQL al eliminar facultad: " + e.getMessage());
            Logger.getLogger(FacultadDao.class.getName()).log(Level.SEVERE, null, e);
        } catch (ClassNotFoundException ex) {
            System.out.println("Error de clase no encontrada al eliminar facultad: " + ex.getMessage());
            Logger.getLogger(FacultadDao.class.getName()).log(Level.SEVERE, null, ex);
        } finally {
            try {
                if (sentencia != null) sentencia.close();
                if (cnx != null) cnx.close();
            } catch (SQLException ex) {
                Logger.getLogger(FacultadDao.class.getName()).log(Level.SEVERE, null, ex);
            }
        }
    }
}