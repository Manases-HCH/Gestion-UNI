/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package pe.edu.model;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.LinkedList;
import pe.universidad.util.Conexion;

/**
 *
 * @author LENOVO
 */
public class carrera {
    private String idCarrera = "";
    private String nombreCarrera = "";
    private String idFacultad = "";

    public carrera() {
    }

    // --- Getters ---
    public String getIdCarrera() {
        return idCarrera;
    }

    public String getNombreCarrera() {
        return nombreCarrera;
    }

    public String getIdFacultad() {
        return idFacultad;
    }

    // --- Setters ---
    public void setIdCarrera(String idCarrera) {
        this.idCarrera = idCarrera;
    }

    public void setNombreCarrera(String nombreCarrera) {
        this.nombreCarrera = nombreCarrera;
    }

    public void setIdFacultad(String idFacultad) {
        this.idFacultad = idFacultad;
    }

    // --- CRUD-like operations ---

    // Simulates a "create" operation by setting current object's fields
    public void crear(String idCarrera, String nombreCarrera, String idFacultad) {
        this.idCarrera = idCarrera;
        this.nombreCarrera = nombreCarrera;
        this.idFacultad = idFacultad;
    }

    // Simulates a "read" operation by returning the current object
    public carrera leer() {
        return this;
    }

    // Simulates an "update" operation by updating current object's fields
    public void actualiza(String nombreCarrera, String idFacultad) {
        this.nombreCarrera = nombreCarrera;
        this.idFacultad = idFacultad;
    }

    // Simulates a "delete" operation by clearing current object's fields
    public void elimina() {
        this.idCarrera = "";
        this.nombreCarrera = "";
        this.idFacultad = "";
    }

    // Retrieves all carreras from the database
    public LinkedList<carrera> muestraCarreras() throws ClassNotFoundException {
        try {
            Conexion c = new Conexion();
            Connection cnx = c.conecta();
            LinkedList<carrera> lista = new LinkedList<>();
            String query = "SELECT * FROM carreras ORDER BY nombre_carrera;";
            Statement sentencia = cnx.createStatement();
            ResultSet resultado = sentencia.executeQuery(query);

            while (resultado.next()) {
                carrera car = new carrera();
                car.idCarrera = resultado.getString("id_carrera");
                car.nombreCarrera = resultado.getString("nombre_carrera");
                car.idFacultad = resultado.getString("id_facultad");
                lista.add(car);
            }
            
            // Close resources
            resultado.close();
            sentencia.close();
            cnx.close();
            
            return lista;
        } catch (SQLException e) {
            System.out.println(e.getMessage());
        }
        return null;
    }

    // Populates the current Carrera object with data from the database based on its ID
    public void ver() throws ClassNotFoundException {
        try {
            Conexion c = new Conexion();
            Connection cnx = c.conecta();
            String query = "SELECT * FROM carreras WHERE id_carrera='" + this.idCarrera + "'";
            Statement sentencia = cnx.createStatement();
            ResultSet resultado = sentencia.executeQuery(query);

            if (resultado.next()) {
                this.idCarrera = resultado.getString("id_carrera");
                this.nombreCarrera = resultado.getString("nombre_carrera");
                this.idFacultad = resultado.getString("id_facultad");
            }
            
            // Close resources
            resultado.close();
            sentencia.close();
            cnx.close();
        } catch (SQLException e) {
            System.out.println(e.getMessage());
        }
    }

    // Adds a new carrera record to the database
    public void agregar(String idCarrera, String nombreCarrera, String idFacultad) throws ClassNotFoundException {
        try {
            Conexion c = new Conexion();
            Connection cnx = c.conecta();
            String query = "INSERT INTO carreras VALUES(?,?,?)"; // 3 columns
            PreparedStatement sentencia = cnx.prepareStatement(query);
            sentencia.setString(1, idCarrera);
            sentencia.setString(2, nombreCarrera);
            sentencia.setString(3, idFacultad);
            sentencia.executeUpdate();
            sentencia.close();
            cnx.close();
        } catch (SQLException e) {
            System.out.println(e.getMessage());
        }
    }

    // Adds a new carrera record without specifying ID (for AUTO_INCREMENT)
    public void agregarSinId(String nombreCarrera, String idFacultad) throws ClassNotFoundException {
        try {
            Conexion c = new Conexion();
            Connection cnx = c.conecta();
            String query = "INSERT INTO carreras (nombre_carrera, id_facultad) VALUES(?,?)";
            PreparedStatement sentencia = cnx.prepareStatement(query);
            sentencia.setString(1, nombreCarrera);
            sentencia.setString(2, idFacultad);
            sentencia.executeUpdate();
            sentencia.close();
            cnx.close();
        } catch (SQLException e) {
            System.out.println(e.getMessage());
        }
    }

    // Updates an existing carrera record in the database
    public void actualizar(String idCarrera, String nombreCarrera, String idFacultad) throws ClassNotFoundException {
        try {
            Conexion c = new Conexion();
            Connection cnx = c.conecta();
            String query = "UPDATE carreras SET nombre_carrera=?, id_facultad=? WHERE id_carrera=?";
            PreparedStatement sentencia = cnx.prepareStatement(query);
            sentencia.setString(1, nombreCarrera);
            sentencia.setString(2, idFacultad);
            sentencia.setString(3, idCarrera);
            sentencia.executeUpdate();
            sentencia.close();
            cnx.close();
        } catch (SQLException e) {
            System.out.println(e.getMessage());
        }
    }

    // Deletes a carrera record from the database
    public void eliminar(String idCarrera) throws ClassNotFoundException {
        try {
            Conexion c = new Conexion();
            Connection cnx = c.conecta();
            String query = "DELETE FROM carreras WHERE id_carrera=?";
            PreparedStatement sentencia = cnx.prepareStatement(query);
            sentencia.setString(1, idCarrera);
            sentencia.executeUpdate();
            sentencia.close();
            cnx.close();
        } catch (SQLException e) {
            System.out.println(e.getMessage());
        }
    }

    // Get carreras by faculty ID
    public LinkedList<carrera> muestraCarrerasPorFacultad(String idFacultad) throws ClassNotFoundException {
        try {
            Conexion c = new Conexion();
            Connection cnx = c.conecta();
            LinkedList<carrera> lista = new LinkedList<>();
            String query = "SELECT * FROM carreras WHERE id_facultad='" + idFacultad + "' ORDER BY nombre_carrera;";
            Statement sentencia = cnx.createStatement();
            ResultSet resultado = sentencia.executeQuery(query);

            while (resultado.next()) {
                carrera car = new carrera();
                car.idCarrera = resultado.getString("id_carrera");
                car.nombreCarrera = resultado.getString("nombre_carrera");
                car.idFacultad = resultado.getString("id_facultad");
                lista.add(car);
            }
            
            // Close resources
            resultado.close();
            sentencia.close();
            cnx.close();
            
            return lista;
        } catch (SQLException e) {
            System.out.println(e.getMessage());
        }
        return null;
    }

    // Check if carrera exists
    public boolean existe(String idCarrera) throws ClassNotFoundException {
        try {
            int contador = 0;
            Conexion c = new Conexion();
            Connection cnx = c.conecta();
            String query = "SELECT * FROM carreras WHERE id_carrera='" + idCarrera + "'";
            Statement sentencia = cnx.createStatement();
            ResultSet resultado = sentencia.executeQuery(query);

            while (resultado.next()) {
                contador++;
            }
            
            // Close resources
            resultado.close();
            sentencia.close();
            cnx.close();
            
            return contador > 0;
        } catch (SQLException e) {
            System.out.println(e.getMessage());
        }
        return false;
    }
}