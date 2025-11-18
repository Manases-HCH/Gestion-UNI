package pe.edu.dao; // Changed from pe.edu.model to pe.edu.dao based on your JSP usage

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.LinkedList;
import pe.edu.entity.Curso; // Import the Curso entity
import pe.universidad.util.Conexion;

/**
 *
 * @author LENOVO
 */
public class CursoDao { // Renamed from 'clase' to 'CursoDao'

    // This DAO should not hold state for a single Curso, as it's meant for operations.
    // The previous 'clase' class had properties like idClase, idCurso, etc., making it
    // an entity/model class acting as a DAO. We separate that here.

    // Retrieves all cursos from the database
    public LinkedList<Curso> listar() {
        LinkedList<Curso> lista = new LinkedList<>();              
        try {
            Conexion c = new Conexion();
            Connection cnx = c.conecta();
            CallableStatement cs = cnx.prepareCall("{call sp_listar_cursos()}");
            ResultSet resultado = cs.executeQuery();

            while (resultado.next()) {
                Curso cur = new Curso();
                cur.setIdCurso(resultado.getString("id_curso"));
                cur.setNombreCurso(resultado.getString("nombre_curso"));
                cur.setCodigoCurso(resultado.getString("codigo_curso"));
                cur.setCreditos(resultado.getString("creditos"));
                cur.setIdCarrera(resultado.getString("id_carrera"));
                lista.add(cur);
            }
            resultado.close();
        cs.close();
        cnx.close();
        } catch (ClassNotFoundException | SQLException e) {
            System.out.println("Error al listar cursos: " + e.getMessage());        
        }
        return lista;
    }

    // Reads a single Curso object from the database based on its ID
    public Curso leer(String idCurso) {
        Curso cur = null;
        
        try {
            Conexion c = new Conexion();
            Connection cnx = c.conecta();

            CallableStatement cs = cnx.prepareCall("{call sp_obtener_curso(?)}");
            cs.setInt(1, Integer.parseInt(idCurso));
            ResultSet resultado = cs.executeQuery();

            if (resultado.next()) {
                cur = new Curso();
                cur.setIdCurso(resultado.getString("id_curso"));
                cur.setNombreCurso(resultado.getString("nombre_curso"));
                cur.setCodigoCurso(resultado.getString("codigo_curso"));
                cur.setCreditos(resultado.getString("creditos"));
                cur.setIdCarrera(resultado.getString("id_carrera"));
            }
            resultado.close();
            cs.close();
            cnx.close();
        } catch (ClassNotFoundException | SQLException e) {
            System.out.println("Error al leer curso: " + e.getMessage());
        }
        return cur;
    }

    // Adds a new curso record to the database
public void agregar(Curso curso) {
    Connection cnx = null; // Inicializar a null para asegurar que se cierre en finally
    CallableStatement sentencia = null; // Inicializar a null

    try {
        Conexion c = new Conexion();
        cnx = c.conecta(); // Obtener la conexión

        // 1. Modificar la llamada al procedimiento almacenado para 6 parámetros
        //    (nombre_curso, codigo_curso, creditos, id_carrera, imagen, tipo_imagen)
        sentencia = cnx.prepareCall("{call sp_insertar_curso(?, ?, ?, ?, ?, ?)}");

        // 2. Setear los parámetros existentes
        sentencia.setString(1, curso.getNombreCurso());
        sentencia.setString(2, curso.getCodigoCurso());

        // Asegúrate de que getCreditos() y getIdCarrera() devuelvan String o int
        // Si devuelven String, la conversión a int ya la haces aquí.
        // Si ya son int, remueve Integer.parseInt().
        sentencia.setInt(3, Integer.parseInt(curso.getCreditos()));
        sentencia.setInt(4, Integer.parseInt(curso.getIdCarrera()));

        // 3. Setear los nuevos parámetros para la imagen y el tipo de imagen
        if (curso.getImagen() != null && curso.getImagen().length > 0) {
            sentencia.setBytes(5, curso.getImagen()); // Para el BLOB
            sentencia.setString(6, curso.getTipoImagen()); // Para el tipo de imagen
        } else {
            // Si no hay imagen, insertar NULL en las columnas de imagen
            sentencia.setNull(5, java.sql.Types.LONGVARBINARY); // O el tipo SQL apropiado para BLOB
            sentencia.setNull(6, java.sql.Types.VARCHAR); // O el tipo SQL apropiado para VARCHAR
        }

        // 4. Ejecutar la sentencia
        sentencia.executeUpdate();

    } catch (ClassNotFoundException | SQLException e) {
        System.out.println("Error al agregar curso: " + e.getMessage());
        e.printStackTrace(); // Imprime la traza completa para depuración
    } finally {
        // 5. Asegurarse de cerrar los recursos en el bloque finally
        try {
            if (sentencia != null) {
                sentencia.close();
            }
            if (cnx != null) {
                cnx.close();
            }
        } catch (SQLException e) {
            System.out.println("Error al cerrar recursos en agregar curso: " + e.getMessage());
        }
    }
}
    // Updates an existing curso record in the database
    public void actualizar(Curso curso) {
        Connection cnx = null;
        try {
            Conexion c = new Conexion();
            cnx = c.conecta();
            CallableStatement sentencia = cnx.prepareCall("{call sp_editar_curso(?,?,?,?,?)}");
            
            sentencia.setString(1, curso.getIdCurso());
            sentencia.setString(2, curso.getNombreCurso());
            sentencia.setString(3, curso.getCodigoCurso());
            sentencia.setInt(4, Integer.parseInt(curso.getCreditos()));
            sentencia.setInt(5, Integer.parseInt(curso.getIdCarrera()));
            
            
            sentencia.executeUpdate();
            sentencia.close();
            cnx.close();

            int filasAfectadas = sentencia.executeUpdate();
         
        } catch (ClassNotFoundException | SQLException e) {
            System.out.println("Error al actualizar curso: " + e.getMessage());
            
        } 
    }

    // Deletes a curso record from the database
 
    public void eliminar(String idCurso) {    
        try {
            Conexion c = new Conexion();
            Connection cnx = c.conecta();
            CallableStatement sentencia = cnx.prepareCall("{call sp_eliminar_curso(?)}");
            sentencia.setString(1, idCurso);           
            sentencia.executeUpdate();
            sentencia.close();
            cnx.close();
        } catch (ClassNotFoundException | SQLException e) {
            System.out.println("Error al eliminar curso: " + e.getMessage());
        } 
    }

    // Checks if a curso exists by its ID
    public void existe(String idCurso) {
        Connection cnx = null;
        PreparedStatement sentencia = null;
        ResultSet resultado = null;
        try {
            Conexion c = new Conexion();
            cnx = c.conecta();
            String query = "SELECT COUNT(*) FROM cursos WHERE id_curso=?";
            sentencia = cnx.prepareStatement(query);
            sentencia.setString(1, idCurso);
            resultado = sentencia.executeQuery();
            if (resultado.next()) {
   
            }
        } catch (ClassNotFoundException | SQLException e) {
            System.out.println("Error al verificar si curso existe: " + e.getMessage());
        } finally {
            try {
                if (resultado != null) resultado.close();
                if (sentencia != null) sentencia.close();
                if (cnx != null) cnx.close();
            } catch (SQLException e) {
                System.out.println("Error al cerrar recursos: " + e.getMessage());
            }
        }

    }

    // Example of searching by a specific attribute (e.g., nombre_curso)
    public LinkedList<Curso> buscarPorNombre(String nombre) {
        LinkedList<Curso> lista = new LinkedList<>();
        Connection cnx = null;
        PreparedStatement sentencia = null;
        ResultSet resultado = null;
        try {
            Conexion c = new Conexion();
            cnx = c.conecta();
            // Use LIKE for partial matches
            String query = "SELECT id_curso, nombre_curso, codigo_curso, creditos, id_carrera FROM cursos WHERE nombre_curso LIKE ? ORDER BY nombre_curso;";
            sentencia = cnx.prepareStatement(query);
            sentencia.setString(1, "%" + nombre + "%"); // Add wildcards for partial match
            resultado = sentencia.executeQuery();

            while (resultado.next()) {
                Curso cur = new Curso();
                cur.setIdCurso(resultado.getString("id_curso"));
                cur.setNombreCurso(resultado.getString("nombre_curso"));
                cur.setCodigoCurso(resultado.getString("codigo_curso"));
                cur.setCreditos("creditos");
                cur.setIdCarrera("id_carrera");
                lista.add(cur);
            }
        } catch (ClassNotFoundException | SQLException e) {
            System.out.println("Error al buscar cursos por nombre: " + e.getMessage());
        } finally {
            try {
                if (resultado != null) resultado.close();
                if (sentencia != null) sentencia.close();
                if (cnx != null) cnx.close();
            } catch (SQLException e) {
                System.out.println("Error al cerrar recursos: " + e.getMessage());
            }
        }
        return lista;
    }
}