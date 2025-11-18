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
public class alumno {
    private String id = "";
    private String dni = "";
    private String nombre = "";
    private String apellido = "";
    private String direccion = "";
    private String telefono = "";
    private String fechaNacimiento = ""; // Changed to String for simplicity, can be java.sql.Date
    private String email = "";
    private String idCarrera = ""; // Changed to String for simplicity, can be int
    private String rol = ""; // Assuming rol is stored for consistency with the image
    private String password = "";
    private String imagen = ""; // Path or reference to image

    public alumno() {
    }

    // --- Getters ---
    public String getId() {
        return id;
    }

    public String getDni() {
        return dni;
    }

    public String getNombre() {
        return nombre;
    }

    public String getApellido() {
        return apellido;
    }

    public String getDireccion() {
        return direccion;
    }

    public String getTelefono() {
        return telefono;
    }

    public String getFechaNacimiento() {
        return fechaNacimiento;
    }

    public String getEmail() {
        return email;
    }

    public String getIdCarrera() {
        return idCarrera;
    }

    public String getRol() {
        return rol;
    }

    public String getPassword() {
        return password;
    }

    public String getImagen() {
        return imagen;
    }

    // --- Setters ---
    public void setId(String id) {
        this.id = id;
    }

    public void setDni(String dni) {
        this.dni = dni;
    }

    public void setNombre(String nombre) {
        this.nombre = nombre;
    }

    public void setApellido(String apellido) {
        this.apellido = apellido;
    }

    public void setDireccion(String direccion) {
        this.direccion = direccion;
    }

    public void setTelefono(String telefono) {
        this.telefono = telefono;
    }

    public void setFechaNacimiento(String fechaNacimiento) {
        this.fechaNacimiento = fechaNacimiento;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public void setIdCarrera(String idCarrera) {
        this.idCarrera = idCarrera;
    }

    public void setRol(String rol) {
        this.rol = rol;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public void setImagen(String imagen) {
        this.imagen = imagen;
    }

    // --- CRUD-like operations (Adapted from Usuario class) ---

    // Simulates a "create" operation by setting current object's fields
    public void crear(String id, String dni, String nombre, String apellido, String direccion, String telefono,
                      String fechaNacimiento, String email, String idCarrera, String rol, String psw, String imagen) {
        this.id = id;
        this.dni = dni;
        this.nombre = nombre;
        this.apellido = apellido;
        this.direccion = direccion;
        this.telefono = telefono;
        this.fechaNacimiento = fechaNacimiento;
        this.email = email;
        this.idCarrera = idCarrera;
        this.rol = rol;
        this.password = psw;
        this.imagen = imagen;
    }

    // Simulates a "read" operation by returning the current object
    public alumno leer() {
        return this;
    }

    // Simulates an "update" operation by updating current object's fields (partial update)
    public void actualiza(String psw, String nombre, String apellido, String direccion, String telefono,
                          String fechaNacimiento, String email, String idCarrera, String imagen) {
        this.password = psw;
        this.nombre = nombre;
        this.apellido = apellido;
        this.direccion = direccion;
        this.telefono = telefono;
        this.fechaNacimiento = fechaNacimiento;
        this.email = email;
        this.idCarrera = idCarrera;
        this.imagen = imagen;
    }

    // Simulates a "delete" operation by clearing current object's fields
    public void elimina() {
        this.id = "";
        this.dni = "";
        this.nombre = "";
        this.apellido = "";
        this.direccion = "";
        this.telefono = "";
        this.fechaNacimiento = "";
        this.email = "";
        this.idCarrera = "";
        this.rol = "";
        this.password = "";
        this.imagen = "";
    }

    // Checks if the current Alumno (based on id and password) can log in
    public int getLogueado() throws ClassNotFoundException {
        try {
            int contador = 0;
            Conexion c = new Conexion();
            Connection cnx = c.conecta();
            String query = "SELECT * FROM alumno "; // Assuming table name is 'alumno'
            query += " WHERE id='" + this.id + "' AND ";
            query += " password='" + this.password + "';";
            Statement sentencia = cnx.createStatement();
            ResultSet resultado = sentencia.executeQuery(query);

            while (resultado.next()) {
                contador++;
            }
            if (contador != 0) {
                return 1; // Logged in
            } else {
                return 0; // Not logged in
            }
        } catch (SQLException e) {
            System.out.println(e.getMessage());
        }
        return 0;
    }

    // Retrieves all alumni from the database
    public LinkedList<alumno> muestraAlumnos() throws ClassNotFoundException {
        try {
            Conexion c = new Conexion();
            Connection cnx = c.conecta();
            LinkedList<alumno> lista = new LinkedList<>();
            String query = "SELECT * FROM alumno;"; // Assuming table name is 'alumno'
            Statement sentencia = cnx.createStatement();
            ResultSet resultado = sentencia.executeQuery(query);

            while (resultado.next()) {
                alumno a = new alumno();
                a.id = resultado.getString("id");
                a.dni = resultado.getString("dni");
                a.nombre = resultado.getString("nombre");
                a.apellido = resultado.getString("apellido");
                a.direccion = resultado.getString("direccion");
                a.telefono = resultado.getString("telefono");
                a.fechaNacimiento = resultado.getString("fecha_nacimiento");
                a.email = resultado.getString("email");
                a.idCarrera = resultado.getString("id_carrera");
                a.rol = resultado.getString("rol");
                a.password = resultado.getString("password");
                a.imagen = resultado.getString("imagen");
                lista.add(a);
            }
            return lista;
        } catch (SQLException e) {
            System.out.println(e.getMessage());
        }
        return null;
    }

    // Populates the current Alumno object with data from the database based on its ID
    public void ver() throws ClassNotFoundException {
        try {
            Conexion c = new Conexion();
            Connection cnx = c.conecta();
            String query = "SELECT * FROM alumno "; // Assuming table name is 'alumno'
            query += " WHERE id='" + this.id + "'";
            Statement sentencia = cnx.createStatement();
            ResultSet resultado = sentencia.executeQuery(query);

            if (resultado.next()) { // Use if instead of while since we expect at most one row
                this.id = resultado.getString("id");
                this.dni = resultado.getString("dni");
                this.nombre = resultado.getString("nombre");
                this.apellido = resultado.getString("apellido");
                this.direccion = resultado.getString("direccion");
                this.telefono = resultado.getString("telefono");
                this.fechaNacimiento = resultado.getString("fecha_nacimiento");
                this.email = resultado.getString("email");
                this.idCarrera = resultado.getString("id_carrera");
                this.rol = resultado.getString("rol");
                this.password = resultado.getString("password");
                this.imagen = resultado.getString("imagen");
            }
            // Close resources
            resultado.close();
            sentencia.close();
            cnx.close();
        } catch (SQLException e) {
            System.out.println(e.getMessage());
        }
    }

    // Adds a new alumno record to the database
    public void agregar(String id, String dni, String nombre, String apellido, String direccion, String telefono,
                        String fechaNacimiento, String email, String idCarrera, String rol, String psw, String imagen) throws ClassNotFoundException {
        try {
            Conexion c = new Conexion();
            Connection cnx = c.conecta();
            String query = "INSERT INTO alumno VALUES(?,?,?,?,?,?,?,?,?,?,?,?)"; // 12 columns
            PreparedStatement sentencia = cnx.prepareStatement(query);
            sentencia.setString(1, id);
            sentencia.setString(2, dni);
            sentencia.setString(3, nombre);
            sentencia.setString(4, apellido);
            sentencia.setString(5, direccion);
            sentencia.setString(6, telefono);
            sentencia.setString(7, fechaNacimiento);
            sentencia.setString(8, email);
            sentencia.setString(9, idCarrera);
            sentencia.setString(10, rol);
            sentencia.setString(11, psw);
            sentencia.setString(12, imagen);
            sentencia.executeUpdate();
            sentencia.close();
            cnx.close();
        } catch (SQLException e) {
            System.out.println(e.getMessage());
        }
    }

    // Updates an existing alumno record in the database
    public void actualizar(String id, String dni, String nombre, String apellido, String direccion, String telefono,
                           String fechaNacimiento, String email, String idCarrera, String rol, String psw, String imagen) throws ClassNotFoundException {
        try {
            Conexion c = new Conexion();
            Connection cnx = c.conecta();
            String query = "UPDATE alumno SET dni=?, nombre=?, apellido=?, direccion=?, telefono=?, fecha_nacimiento=?, email=?, id_carrera=?, rol=?, password=?, imagen=? WHERE id=?";
            PreparedStatement sentencia = cnx.prepareStatement(query);
            sentencia.setString(1, dni);
            sentencia.setString(2, nombre);
            sentencia.setString(3, apellido);
            sentencia.setString(4, direccion);
            sentencia.setString(5, telefono);
            sentencia.setString(6, fechaNacimiento);
            sentencia.setString(7, email);
            sentencia.setString(8, idCarrera);
            sentencia.setString(9, rol);
            sentencia.setString(10, psw);
            sentencia.setString(11, imagen);
            sentencia.setString(12, id); // Where clause condition
            sentencia.executeUpdate();
            sentencia.close();
            cnx.close();
        } catch (SQLException e) {
            System.out.println(e.getMessage());
        }
    }

    // Deletes an alumno record from the database
    public void eliminar(String id) throws ClassNotFoundException {
        try {
            Conexion c = new Conexion();
            Connection cnx = c.conecta();
            String query = "DELETE FROM alumno WHERE id=?";
            PreparedStatement sentencia = cnx.prepareStatement(query);
            sentencia.setString(1, id);
            sentencia.executeUpdate();
            sentencia.close();
            cnx.close();
        } catch (SQLException e) {
            System.out.println(e.getMessage());
        }
    }
}
