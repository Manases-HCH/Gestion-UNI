package pe.edu.dao;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.LinkedList;
import java.util.logging.Level;
import java.util.logging.Logger;
import pe.edu.entity.Profesor;
import pe.universidad.util.Conection;

public class ProfesorDao implements DaoCrud<Profesor> {

    private static final Logger LOGGER = Logger.getLogger(ProfesorDao.class.getName());

    @Override
    public LinkedList<Profesor> listar() {
        LinkedList<Profesor> lista = new LinkedList<>();
        try (Connection cnx = new Conection().conecta();
             CallableStatement cs = cnx.prepareCall("{CALL sp_listar_profesores()}");
             ResultSet rs = cs.executeQuery()) {

            while (rs.next()) {
                Profesor p = new Profesor();
                p.setIdProfesor(rs.getString("id_profesor"));
                p.setDni(rs.getString("dni"));
                p.setNombre(rs.getString("nombre"));
                p.setApellidoPaterno(rs.getString("apellido_paterno"));
                p.setApellidoMaterno(rs.getString("apellido_materno"));
                p.setEmail(rs.getString("email"));
                p.setTelefono(rs.getString("telefono"));
                p.setIdFacultad(rs.getString("id_facultad"));
                p.setRol(rs.getString("rol"));
                p.setPassword(rs.getString("password"));
                p.setIntentos(rs.getInt("intentos"));
                p.setEstado(rs.getString("estado"));
                p.setFechaRegistro(rs.getString("fecha_registro"));

                // Si el SP hace JOIN con facultad
                try {
                    p.setNombreFacultad(rs.getString("nombre_facultad"));
                } catch (SQLException ignore) {}

                lista.add(p);
            }
        } catch (SQLException | ClassNotFoundException e) {
            LOGGER.log(Level.SEVERE, "Error al listar profesores", e);
        }
        return lista;
    }

    @Override
    public void insertar(Profesor obj) {
        try (Connection cnx = new Conection().conecta();
             CallableStatement cs = cnx.prepareCall("{CALL sp_insertar_profesor(?, ?, ?, ?, ?, ?, ?, ?, ?)}")) {

            cs.setString(1, obj.getDni());
            cs.setString(2, obj.getNombre());
            cs.setString(3, obj.getApellidoPaterno());
            cs.setString(4, obj.getApellidoMaterno());
            cs.setString(5, obj.getEmail());
            cs.setString(6, obj.getTelefono());
            cs.setInt(7, Integer.parseInt(obj.getIdFacultad()));
            cs.setString(8, obj.getRol());
            cs.setString(9, obj.getPassword());

            cs.executeUpdate();
            System.out.println("✅ Profesor insertado correctamente.");

        } catch (SQLException | ClassNotFoundException e) {
            LOGGER.log(Level.SEVERE, "❌ Error al insertar profesor", e);
        }
    }

    @Override
    public Profesor leer(String id) {
        Profesor profesor = null;
        try (Connection cnx = new Conection().conecta();
             CallableStatement cs = cnx.prepareCall("{CALL sp_obtener_profesor(?)}")) {

            cs.setString(1, id);
            try (ResultSet rs = cs.executeQuery()) {
                if (rs.next()) {
                    profesor = new Profesor();
                    profesor.setIdProfesor(rs.getString("id_profesor"));
                    profesor.setDni(rs.getString("dni"));
                    profesor.setNombre(rs.getString("nombre"));
                    profesor.setApellidoPaterno(rs.getString("apellido_paterno"));
                    profesor.setApellidoMaterno(rs.getString("apellido_materno"));
                    profesor.setEmail(rs.getString("email"));
                    profesor.setTelefono(rs.getString("telefono"));
                    profesor.setIdFacultad(rs.getString("id_facultad"));
                    profesor.setRol(rs.getString("rol"));
                    profesor.setPassword(rs.getString("password"));
                    profesor.setIntentos(rs.getInt("intentos"));
                    profesor.setEstado(rs.getString("estado"));
                    profesor.setFechaRegistro(rs.getString("fecha_registro"));
                }
            }
        } catch (SQLException | ClassNotFoundException e) {
            LOGGER.log(Level.SEVERE, "❌ Error al leer profesor", e);
        }
        return profesor;
    }

    @Override
    public void editar(Profesor obj) {
        try (Connection cnx = new Conection().conecta();
             CallableStatement cs = cnx.prepareCall("{CALL sp_editar_profesor(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)}")) {

            cs.setInt(1, Integer.parseInt(obj.getIdProfesor()));
            cs.setString(2, obj.getDni());
            cs.setString(3, obj.getNombre());
            cs.setString(4, obj.getApellidoPaterno());
            cs.setString(5, obj.getApellidoMaterno());
            cs.setString(6, obj.getEmail());
            cs.setString(7, obj.getTelefono());
            cs.setInt(8, Integer.parseInt(obj.getIdFacultad()));
            cs.setString(9, obj.getRol());
            cs.setString(10, obj.getPassword());

            cs.executeUpdate();
            System.out.println("✅ Profesor editado correctamente.");

        } catch (SQLException | ClassNotFoundException e) {
            LOGGER.log(Level.SEVERE, "❌ Error al editar profesor", e);
        }
    }

    @Override
    public void eliminar(String id) {
        try (Connection cnx = new Conection().conecta();
             CallableStatement cs = cnx.prepareCall("{CALL sp_eliminar_profesor(?)}")) {

            cs.setInt(1, Integer.parseInt(id));
            int filas = cs.executeUpdate();

            if (filas > 0)
                System.out.println("🗑️ Profesor eliminado correctamente.");
            else
                System.out.println("⚠️ No se encontró el profesor con ID " + id);

        } catch (SQLException | ClassNotFoundException e) {
            LOGGER.log(Level.SEVERE, "❌ Error al eliminar profesor", e);
        }
    }
}
