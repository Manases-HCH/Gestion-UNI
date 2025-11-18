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
import pe.edu.entity.Pago; // Importar la entidad Pago
import pe.universidad.util.Conexion; // Asegúrate de que esta ruta sea correcta

public class PagoDao implements DaoCrud<Pago> {

    @Override
    public LinkedList<Pago> listar() {
        LinkedList<Pago> lista = new LinkedList<>();       
        try {
            Conexion c = new Conexion();
            Connection cnx = c.conecta();

            CallableStatement cs = cnx.prepareCall("{call sp_listar_pagos()}");
            ResultSet resultado = cs.executeQuery();


            while (resultado.next()) {
                Pago pago = new Pago();
                pago.setIdPago(resultado.getString("id_pago"));
                pago.setNombreAlumno(resultado.getString("nombre_alumno"));
                pago.setApellidoAlumno(resultado.getString("apellido_alumno"));
                pago.setFechaPago(resultado.getString("fecha_pago")); // Lo obtenemos como String
                pago.setConcepto(resultado.getString("concepto"));
                pago.setMonto(resultado.getString("monto"));
                pago.setMetodoPago(resultado.getString("metodo_pago"));
                pago.setReferencia(resultado.getString("referencia"));
                lista.add(pago);
            }
            resultado.close();
            cs.close();
            cnx.close();
            return lista;
        } catch (SQLException e) {
            System.out.println("Error SQL al listar pagos: " + e.getMessage());
            Logger.getLogger(PagoDao.class.getName()).log(Level.SEVERE, null, e);
        } catch (ClassNotFoundException ex) {
            System.out.println("Error de clase no encontrada al listar pagos: " + ex.getMessage());
            Logger.getLogger(PagoDao.class.getName()).log(Level.SEVERE, null, ex);
        } 
        return null;
    }

    @Override
    public void insertar(Pago obj) {
        try {
            Conexion c = new Conexion();
            Connection cnx = c.conecta();

        // Excluimos 'id' porque es AUTO_INCREMENT
        // Corrected: 10 columns and 10 placeholders
            CallableStatement sentencia = cnx.prepareCall("{call sp_insertar_pago(?,?,?,?,?,?)}");

            sentencia.setInt(1, Integer.parseInt(obj.getIdAlumno())); 
            sentencia.setString(2, obj.getFechaPago()); // Formato 'YYYY-MM-DD'
            sentencia.setString(3, obj.getConcepto());
            sentencia.setDouble(4, Integer.parseInt(obj.getMonto())); 
            sentencia.setString(5, obj.getMetodoPago());
            sentencia.setString(6, obj.getReferencia());

            sentencia.executeUpdate();
            sentencia.close();
            cnx.close();
            System.out.println("Pago insertado correctamente");

        } catch (SQLException e) {
            System.out.println("Error SQL al insertar pago: " + e.getMessage());
            Logger.getLogger(PagoDao.class.getName()).log(Level.SEVERE, null, e);
        } catch (ClassNotFoundException ex) {
            System.out.println("Error de clase no encontrada al insertar pago: " + ex.getMessage());
            Logger.getLogger(PagoDao.class.getName()).log(Level.SEVERE, null, ex);
        } 
    }

    @Override
    public Pago leer(String id) { // El ID del pago se pasa como String desde la URL
        Pago pago = null;      
        try {
            Conexion c = new Conexion();
            Connection cnx = c.conecta();

            CallableStatement cs = cnx.prepareCall("{call sp_obtener_pago(?)}");
            cs.setInt(1, Integer.parseInt(id));
            ResultSet resultado = cs.executeQuery();

            if (resultado.next()) {
                pago = new Pago();
                pago.setIdPago(resultado.getString("id_pago"));
                pago.setIdAlumno(resultado.getString("id_alumno"));
                pago.setFechaPago(resultado.getString("fecha_pago"));
                pago.setConcepto(resultado.getString("concepto"));
                pago.setMonto(resultado.getString("monto"));
                pago.setMetodoPago(resultado.getString("metodo_pago"));
                pago.setReferencia(resultado.getString("referencia"));
            }
            resultado.close();
            cs.close();
            cnx.close();
            return pago;
        } catch (SQLException e) {
            System.out.println("Error SQL al leer pago: " + e.getMessage());
            Logger.getLogger(PagoDao.class.getName()).log(Level.SEVERE, null, e);
        } catch (ClassNotFoundException ex) {
            System.out.println("Error de clase no encontrada al leer pago: " + ex.getMessage());
            Logger.getLogger(PagoDao.class.getName()).log(Level.SEVERE, null, ex);
        } catch (NumberFormatException e) {
            System.out.println("Error de formato de número al leer pago (ID no es un entero): " + e.getMessage());
            Logger.getLogger(PagoDao.class.getName()).log(Level.SEVERE, null, e);
        } 
        return null;
    }

    @Override
    public void editar(Pago obj) {   
        try {
            Conexion c = new Conexion();
            Connection cnx = c.conecta();
            System.out.println("=== DEBUG EDITAR Pago ===");
            System.out.println("ID a editar: " + obj.getIdAlumno());
            System.out.println("Nombre: " + obj.getFechaPago());
            System.out.println("Email: " + obj.getConcepto());
            System.out.println("============================");
            CallableStatement sentencia = cnx.prepareCall("{call sp_editar_pago(?,?,?,?,?,?,?)}");
            sentencia.setInt(1, Integer.parseInt(obj.getIdPago())); // El ID para la condición WHERE
            sentencia.setInt(2, Integer.parseInt(obj.getIdAlumno()));
            sentencia.setString(3, obj.getFechaPago());
            sentencia.setString(4, obj.getConcepto());
            sentencia.setDouble(5, Double.parseDouble(obj.getMonto())); 
            sentencia.setString(6, obj.getMetodoPago());
            sentencia.setString(7, obj.getReferencia());
            
            
            sentencia.executeUpdate();
            sentencia.close();
            cnx.close();
            System.out.println("Pago editado correctamente");
            
        } catch (SQLException e) {
            System.out.println("Error SQL al editar pago: " + e.getMessage());
            Logger.getLogger(PagoDao.class.getName()).log(Level.SEVERE, null, e);
        } catch (ClassNotFoundException ex) {
            System.out.println("Error de clase no encontrada al editar pago: " + ex.getMessage());
            Logger.getLogger(PagoDao.class.getName()).log(Level.SEVERE, null, ex);
        } 
    }

    @Override
    public void eliminar(String id) { // El ID del pago se pasa como String desde la URL
       
        try {
            Conexion c = new Conexion();
            Connection cnx = c.conecta();
            CallableStatement cs = cnx.prepareCall("{call sp_eliminar_pago(?)}");
            cs.setInt(1, Integer.parseInt(id));
            cs.executeUpdate();

            cs.close();
            cnx.close();
            System.out.println("Pago eliminado correctamente");
            
        } catch (SQLException e) {
            System.out.println("Error SQL al eliminar pago: " + e.getMessage());
            Logger.getLogger(PagoDao.class.getName()).log(Level.SEVERE, null, e);
        } catch (ClassNotFoundException ex) {
            System.out.println("Error de clase no encontrada al eliminar pago: " + ex.getMessage());
            Logger.getLogger(PagoDao.class.getName()).log(Level.SEVERE, null, ex);
        } catch (NumberFormatException e) {
            System.out.println("Error de formato de número al eliminar pago (ID no es un entero): " + e.getMessage());
            Logger.getLogger(PagoDao.class.getName()).log(Level.SEVERE, null, e);
        } 
    }
}