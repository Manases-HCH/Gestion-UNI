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
public class clase {
    private String idClase = "";
    private String idCurso = "";
    private String idProfesor = "";
    private String idHorario = "";
    private String ciclo = "";

    public clase() {
    }

    // --- Getters ---
    public String getIdClase() {
        return idClase;
    }

    public String getIdCurso() {
        return idCurso;
    }

    public String getIdProfesor() {
        return idProfesor;
    }

    public String getIdHorario() {
        return idHorario;
    }

    public String getCiclo() {
        return ciclo;
    }

    // --- Setters ---
    public void setIdClase(String idClase) {
        this.idClase = idClase;
    }

    public void setIdCurso(String idCurso) {
        this.idCurso = idCurso;
    }

    public void setIdProfesor(String idProfesor) {
        this.idProfesor = idProfesor;
    }

    public void setIdHorario(String idHorario) {
        this.idHorario = idHorario;
    }

    public void setCiclo(String ciclo) {
        this.ciclo = ciclo;
    }

    // --- CRUD-like operations ---

    // Simulates a "create" operation by setting current object's fields
    public void crear(String idClase, String idCurso, String idProfesor, String idHorario, String ciclo) {
        this.idClase = idClase;
        this.idCurso = idCurso;
        this.idProfesor = idProfesor;
        this.idHorario = idHorario;
        this.ciclo = ciclo;
    }

    // Simulates a "read" operation by returning the current object
    public clase leer() {
        return this;
    }

    // Simulates an "update" operation by updating current object's fields
    public void actualiza(String idCurso, String idProfesor, String idHorario, String ciclo) {
        this.idCurso = idCurso;
        this.idProfesor = idProfesor;
        this.idHorario = idHorario;
        this.ciclo = ciclo;
    }

    // Simulates a "delete" operation by clearing current object's fields
    public void elimina() {
        this.idClase = "";
        this.idCurso = "";
        this.idProfesor = "";
        this.idHorario = "";
        this.ciclo = "";
    }

    // Retrieves all clases from the database
    public LinkedList<clase> muestraClases() throws ClassNotFoundException {
        try {
            Conexion c = new Conexion();
            Connection cnx = c.conecta();
            LinkedList<clase> lista = new LinkedList<>();
            String query = "SELECT * FROM clases ORDER BY id_clase;";
            Statement sentencia = cnx.createStatement();
            ResultSet resultado = sentencia.executeQuery(query);

            while (resultado.next()) {
                clase cls = new clase();
                cls.idClase = resultado.getString("id_clase");
                cls.idCurso = resultado.getString("id_curso");
                cls.idProfesor = resultado.getString("id_profesor");
                cls.idHorario = resultado.getString("id_horario");
                cls.ciclo = resultado.getString("ciclo");
                lista.add(cls);
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

    // Populates the current Clase object with data from the database based on its ID
    public void ver() throws ClassNotFoundException {
        try {
            Conexion c = new Conexion();
            Connection cnx = c.conecta();
            String query = "SELECT * FROM clases WHERE id_clase='" + this.idClase + "'";
            Statement sentencia = cnx.createStatement();
            ResultSet resultado = sentencia.executeQuery(query);

            if (resultado.next()) {
                this.idClase = resultado.getString("id_clase");
                this.idCurso = resultado.getString("id_curso");
                this.idProfesor = resultado.getString("id_profesor");
                this.idHorario = resultado.getString("id_horario");
                this.ciclo = resultado.getString("ciclo");
            }
            
            // Close resources
            resultado.close();
            sentencia.close();
            cnx.close();
        } catch (SQLException e) {
            System.out.println(e.getMessage());
        }
    }

    // Adds a new clase record to the database
    public void agregar(String idClase, String idCurso, String idProfesor, String idHorario, String ciclo) throws ClassNotFoundException {
        try {
            Conexion c = new Conexion();
            Connection cnx = c.conecta();
            String query = "INSERT INTO clases VALUES(?,?,?,?,?)"; // 5 columns
            PreparedStatement sentencia = cnx.prepareStatement(query);
            sentencia.setString(1, idClase);
            sentencia.setString(2, idCurso);
            sentencia.setString(3, idProfesor);
            sentencia.setString(4, idHorario);
            sentencia.setString(5, ciclo);
            sentencia.executeUpdate();
            sentencia.close();
            cnx.close();
        } catch (SQLException e) {
            System.out.println(e.getMessage());
        }
    }

    // Adds a new clase record without specifying ID (for AUTO_INCREMENT)
    public void agregarSinId(String idCurso, String idProfesor, String idHorario, String ciclo) throws ClassNotFoundException {
        try {
            Conexion c = new Conexion();
            Connection cnx = c.conecta();
            String query = "INSERT INTO clases (id_curso, id_profesor, id_horario, ciclo) VALUES(?,?,?,?)";
            PreparedStatement sentencia = cnx.prepareStatement(query);
            sentencia.setString(1, idCurso);
            sentencia.setString(2, idProfesor);
            sentencia.setString(3, idHorario);
            sentencia.setString(4, ciclo);
            sentencia.executeUpdate();
            sentencia.close();
            cnx.close();
        } catch (SQLException e) {
            System.out.println(e.getMessage());
        }
    }

    // Updates an existing clase record in the database
    public void actualizar(String idClase, String idCurso, String idProfesor, String idHorario, String ciclo) throws ClassNotFoundException {
        try {
            Conexion c = new Conexion();
            Connection cnx = c.conecta();
            String query = "UPDATE clases SET id_curso=?, id_profesor=?, id_horario=?, ciclo=? WHERE id_clase=?";
            PreparedStatement sentencia = cnx.prepareStatement(query);
            sentencia.setString(1, idCurso);
            sentencia.setString(2, idProfesor);
            sentencia.setString(3, idHorario);
            sentencia.setString(4, ciclo);
            sentencia.setString(5, idClase);
            sentencia.executeUpdate();
            sentencia.close();
            cnx.close();
        } catch (SQLException e) {
            System.out.println(e.getMessage());
        }
    }

    // Deletes a clase record from the database
    public void eliminar(String idClase) throws ClassNotFoundException {
        try {
            Conexion c = new Conexion();
            Connection cnx = c.conecta();
            String query = "DELETE FROM clases WHERE id_clase=?";
            PreparedStatement sentencia = cnx.prepareStatement(query);
            sentencia.setString(1, idClase);
            sentencia.executeUpdate();
            sentencia.close();
            cnx.close();
        } catch (SQLException e) {
            System.out.println(e.getMessage());
        }
    }

    // Get clases by curso ID
    public LinkedList<clase> muestraClasesPorCurso(String idCurso) throws ClassNotFoundException {
        try {
            Conexion c = new Conexion();
            Connection cnx = c.conecta();
            LinkedList<clase> lista = new LinkedList<>();
            String query = "SELECT * FROM clases WHERE id_curso='" + idCurso + "' ORDER BY id_clase;";
            Statement sentencia = cnx.createStatement();
            ResultSet resultado = sentencia.executeQuery(query);

            while (resultado.next()) {
                clase cls = new clase();
                cls.idClase = resultado.getString("id_clase");
                cls.idCurso = resultado.getString("id_curso");
                cls.idProfesor = resultado.getString("id_profesor");
                cls.idHorario = resultado.getString("id_horario");
                cls.ciclo = resultado.getString("ciclo");
                lista.add(cls);
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

    // Get clases by profesor ID
    public LinkedList<clase> muestraClasesPorProfesor(String idProfesor) throws ClassNotFoundException {
        try {
            Conexion c = new Conexion();
            Connection cnx = c.conecta();
            LinkedList<clase> lista = new LinkedList<>();
            String query = "SELECT * FROM clases WHERE id_profesor='" + idProfesor + "' ORDER BY id_clase;";
            Statement sentencia = cnx.createStatement();
            ResultSet resultado = sentencia.executeQuery(query);

            while (resultado.next()) {
                clase cls = new clase();
                cls.idClase = resultado.getString("id_clase");
                cls.idCurso = resultado.getString("id_curso");
                cls.idProfesor = resultado.getString("id_profesor");
                cls.idHorario = resultado.getString("id_horario");
                cls.ciclo = resultado.getString("ciclo");
                lista.add(cls);
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

    // Get clases by ciclo
    public LinkedList<clase> muestraClasesPorCiclo(String ciclo) throws ClassNotFoundException {
        try {
            Conexion c = new Conexion();
            Connection cnx = c.conecta();
            LinkedList<clase> lista = new LinkedList<>();
            String query = "SELECT * FROM clases WHERE ciclo='" + ciclo + "' ORDER BY id_clase;";
            Statement sentencia = cnx.createStatement();
            ResultSet resultado = sentencia.executeQuery(query);

            while (resultado.next()) {
                clase cls = new clase();
                cls.idClase = resultado.getString("id_clase");
                cls.idCurso = resultado.getString("id_curso");
                cls.idProfesor = resultado.getString("id_profesor");
                cls.idHorario = resultado.getString("id_horario");
                cls.ciclo = resultado.getString("ciclo");
                lista.add(cls);
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

    // Check if clase exists
    public boolean existe(String idClase) throws ClassNotFoundException {
        try {
            int contador = 0;
            Conexion c = new Conexion();
            Connection cnx = c.conecta();
            String query = "SELECT * FROM clases WHERE id_clase='" + idClase + "'";
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