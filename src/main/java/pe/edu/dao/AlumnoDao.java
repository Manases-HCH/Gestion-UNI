package pe.edu.dao;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.ResultSet;
import java.util.LinkedList;
import java.util.logging.Level;
import java.util.logging.Logger;
import pe.edu.entity.Alumno;
import pe.universidad.util.Conection;

public class AlumnoDao implements DaoCrud<Alumno> {

    @Override
    public LinkedList<Alumno> listar() {
        LinkedList<Alumno> lista = new LinkedList<>();
        try {
            Conection c = new Conection();
            Connection cnx = c.conecta();

            CallableStatement cs = cnx.prepareCall("{call sp_listar_alumnos()}");
            ResultSet rs = cs.executeQuery();

            while (rs.next()) {
                Alumno a = new Alumno();
                a.setIdAlumno(rs.getString("id_alumno"));
                a.setDni(rs.getString("dni"));
                a.setNombre(rs.getString("nombre"));
                a.setApellidoPaterno(rs.getString("apellido_paterno"));
                a.setApellidoMaterno(rs.getString("apellido_materno"));
                a.setDireccion(rs.getString("direccion"));
                a.setTelefono(rs.getString("telefono"));
                a.setFechaNacimiento(rs.getString("fecha_nacimiento"));
                a.setEmail(rs.getString("email"));
                a.setIdCarrera(rs.getString("id_carrera"));
                a.setRol(rs.getString("rol"));
                a.setPassword(rs.getString("password"));
                a.setIntentos(rs.getString("intentos"));
                a.setEstado(rs.getString("estado"));
                a.setFechaRegistro(rs.getString("fecha_registro"));
                a.setNombreCarrera(rs.getString("nombre_carrera"));
                lista.add(a);
            }

            rs.close();
            cs.close();
            cnx.close();
        } catch (Exception e) {
            Logger.getLogger(AlumnoDao.class.getName()).log(Level.SEVERE, null, e);
        }
        return lista;
    }

    @Override
    public void insertar(Alumno obj) {
        try {
            Conection c = new Conection();
            Connection cnx = c.conecta();

            CallableStatement cs = cnx.prepareCall("{call sp_insertar_alumno(?,?,?,?,?,?,?,?,?,?,?)}");

            cs.setString(1, obj.getDni());
            cs.setString(2, obj.getNombre());
            cs.setString(3, obj.getApellidoPaterno());
            cs.setString(4, obj.getApellidoMaterno());
            cs.setString(5, obj.getDireccion());
            cs.setString(6, obj.getTelefono());
            cs.setDate(7, java.sql.Date.valueOf(obj.getFechaNacimiento())); // ✅ mejor práctica
            cs.setString(8, obj.getEmail());
            cs.setString(9, obj.getIdCarrera());
            cs.setString(10, obj.getRol());
            cs.setString(11, obj.getPassword());

            cs.executeUpdate();
            cs.close();
            cnx.close();

            System.out.println("✅ Alumno insertado correctamente");

        } catch (Exception e) {
            System.out.println("❌ Error al insertar alumno: " + e.getMessage());
            Logger.getLogger(AlumnoDao.class.getName()).log(Level.SEVERE, null, e);
        }
    }

    @Override
    public Alumno leer(String id) {
        Alumno a = null;
        try {
            Conection c = new Conection();
            Connection cnx = c.conecta();

            CallableStatement cs = cnx.prepareCall("{call sp_obtener_alumno(?)}");
            cs.setString(1, id);
            ResultSet rs = cs.executeQuery();

            if (rs.next()) {
                a = new Alumno();
                a.setIdAlumno(rs.getString("id_alumno"));
                a.setDni(rs.getString("dni"));
                a.setNombre(rs.getString("nombre"));
                a.setApellidoPaterno(rs.getString("apellido_paterno"));
                a.setApellidoMaterno(rs.getString("apellido_materno"));
                a.setDireccion(rs.getString("direccion"));
                a.setTelefono(rs.getString("telefono"));
                a.setFechaNacimiento(rs.getString("fecha_nacimiento"));
                a.setEmail(rs.getString("email"));
                a.setIdCarrera(rs.getString("id_carrera"));
                a.setRol(rs.getString("rol"));
                a.setPassword(rs.getString("password"));
                a.setIntentos(rs.getString("intentos"));
                a.setEstado(rs.getString("estado"));
                a.setFechaRegistro(rs.getString("fecha_registro"));
            }

            rs.close();
            cs.close();
            cnx.close();
        } catch (Exception e) {
            Logger.getLogger(AlumnoDao.class.getName()).log(Level.SEVERE, null, e);
        }
        return a;
    }

    @Override
    public void editar(Alumno obj) {
        try {
            Conection c = new Conection();
            Connection cnx = c.conecta();

            CallableStatement cs = cnx.prepareCall("{call sp_editar_alumno(?,?,?,?,?,?,?,?,?,?,?,?)}");

            cs.setString(1, obj.getIdAlumno());
            cs.setString(2, obj.getDni());
            cs.setString(3, obj.getNombre());
            cs.setString(4, obj.getApellidoPaterno());
            cs.setString(5, obj.getApellidoMaterno());
            cs.setString(6, obj.getDireccion());
            cs.setString(7, obj.getTelefono());
            cs.setDate(8, java.sql.Date.valueOf(obj.getFechaNacimiento())); // ✅ igual que insertar
            cs.setString(9, obj.getEmail());
            cs.setString(10, obj.getIdCarrera());
            cs.setString(11, obj.getRol());
            cs.setString(12, obj.getPassword());

            cs.executeUpdate();
            cs.close();
            cnx.close();

            System.out.println("✅ Alumno editado correctamente");

        } catch (Exception e) {
            System.out.println("❌ Error al editar alumno: " + e.getMessage());
            Logger.getLogger(AlumnoDao.class.getName()).log(Level.SEVERE, null, e);
        }
    }

    @Override
    public void eliminar(String idAlumno) {
        try {
            Conection c = new Conection();
            Connection cnx = c.conecta();

            CallableStatement cs = cnx.prepareCall("{CALL sp_eliminar_alumno(?)}");
            cs.setString(1, idAlumno);
            cs.executeUpdate();

            cs.close();
            cnx.close();
            System.out.println("🗑️ Alumno eliminado correctamente");

        } catch (Exception e) {
            System.out.println("❌ Error al eliminar alumno: " + e.getMessage());
            Logger.getLogger(AlumnoDao.class.getName()).log(Level.SEVERE, null, e);
        }
    }
}
