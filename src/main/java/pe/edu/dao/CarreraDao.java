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
import pe.edu.entity.Carrera;
import pe.universidad.util.Conexion;

public class CarreraDao implements DaoCrud<Carrera> {

    @Override
    public LinkedList<Carrera> listar() {
        LinkedList<Carrera> lista = new LinkedList<>();
        try {
            Conexion c = new Conexion();
            Connection cnx = c.conecta();
            CallableStatement cs = cnx.prepareCall("{call sp_listar_carreras()}");
            ResultSet resultado = cs.executeQuery();            

            while (resultado.next()) {
                Carrera carrera = new Carrera();
                carrera.setIdCarrera(resultado.getString("id_carrera"));
                carrera.setNombreCarrera(resultado.getString("nombre_carrera"));
                carrera.setIdFacultad(resultado.getString("id_facultad"));
                lista.add(carrera);
            }
            // Cerrar recursos
            resultado.close();
            cs.close();
            cnx.close();
            return lista;
        } catch (SQLException e) {
            System.out.println("Error SQL al listar carreras: " + e.getMessage());
            Logger.getLogger(CarreraDao.class.getName()).log(Level.SEVERE, null, e);
        } catch (ClassNotFoundException ex) {
            System.out.println("Error de clase no encontrada al listar carreras: " + ex.getMessage());
            Logger.getLogger(CarreraDao.class.getName()).log(Level.SEVERE, null, ex);
        }
        return null;
    }

    @Override
    public void insertar(Carrera obj) {
        try {
            Conexion c = new Conexion();
            Connection cnx = c.conecta();

             CallableStatement sentencia = cnx.prepareCall("{call sp_insertar_carrera(?,?)}");
           
            sentencia.setString(1, obj.getNombreCarrera());
            sentencia.setString(2, obj.getIdFacultad());

            sentencia.executeUpdate();
            sentencia.close();
            cnx.close();

            System.out.println("Carrera insertada correctamente");

        } catch (SQLException e) {
            System.out.println("Error SQL al insertar carrera: " + e.getMessage());
            Logger.getLogger(CarreraDao.class.getName()).log(Level.SEVERE, null, e);
        } catch (ClassNotFoundException ex) {
            System.out.println("Error de clase no encontrada al insertar carrera: " + ex.getMessage());
            Logger.getLogger(CarreraDao.class.getName()).log(Level.SEVERE, null, ex);
        }
    }

    @Override
    public Carrera leer(String id) {
        Carrera carrera = null;
        try {
            Conexion c = new Conexion();
            Connection cnx = c.conecta();
            CallableStatement sentencia = cnx.prepareCall("{call sp_obtener_carrera(?)}");
            sentencia.setString(1, id);
            ResultSet resultado = sentencia.executeQuery();

            if (resultado.next()) {
                carrera = new Carrera();
                carrera.setIdCarrera(resultado.getString("id_carrera"));
                carrera.setNombreCarrera(resultado.getString("nombre_carrera"));
                carrera.setIdFacultad(resultado.getString("id_facultad"));
            }
            // Cerrar recursos
            resultado.close();
            sentencia.close();
            cnx.close();
            return carrera;
        } catch (SQLException e) {
            System.out.println("Error SQL al leer carrera: " + e.getMessage());
            Logger.getLogger(CarreraDao.class.getName()).log(Level.SEVERE, null, e);
        } catch (ClassNotFoundException ex) {
            System.out.println("Error de clase no encontrada al leer carrera: " + ex.getMessage());
            Logger.getLogger(CarreraDao.class.getName()).log(Level.SEVERE, null, ex);
        }
        return null;
    }

    @Override
    public void editar(Carrera obj) {
        try {
            Conexion c = new Conexion();
            Connection cnx = c.conecta();
             CallableStatement sentencia = cnx.prepareCall("{call sp_editar_carrera(?,?,?)}");
             
            sentencia.setString(1, obj.getIdCarrera());
            sentencia.setString(2, obj.getNombreCarrera());
            sentencia.setString(3, obj.getIdFacultad());
                     
            sentencia.executeUpdate();
            sentencia.close();
            cnx.close();
            
            System.out.println("Carrera editada correctamente");
            
        } catch (SQLException e) {
            System.out.println("Error SQL al editar carrera: " + e.getMessage());
            Logger.getLogger(CarreraDao.class.getName()).log(Level.SEVERE, null, e);
        } catch (ClassNotFoundException ex) {
            System.out.println("Error de clase no encontrada al editar carrera: " + ex.getMessage());
            Logger.getLogger(CarreraDao.class.getName()).log(Level.SEVERE, null, ex);
        }
    }

    @Override
    public void eliminar(String id) {
        try {
            Conexion c = new Conexion();
            Connection cnx = c.conecta();
            CallableStatement sentencia = cnx.prepareCall("{call sp_eliminar_carrera(?)}");
            sentencia.setString(1, id);
            sentencia.executeUpdate();
            sentencia.close();
            cnx.close();
            
            System.out.println("Carrera eliminada correctamente");
            
        } catch (SQLException e) {
            System.out.println("Error SQL al eliminar carrera: " + e.getMessage());
            Logger.getLogger(CarreraDao.class.getName()).log(Level.SEVERE, null, e);
        } catch (ClassNotFoundException ex) {
            System.out.println("Error de clase no encontrada al eliminar carrera: " + ex.getMessage());
            Logger.getLogger(CarreraDao.class.getName()).log(Level.SEVERE, null, ex);
        }    
    }
}