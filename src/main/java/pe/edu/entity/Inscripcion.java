package pe.edu.entity;

// Importar Date o Timestamp si vas a manejar fechas/horas como objetos Java.
// Por simplicidad en JSP, usaremos String para fecha_inscripcion.
// import java.sql.Timestamp;
// import java.util.Date;

public class Inscripcion {
    private String idInscripcion=""; // id_inscripcion en la base de datos
    private String idAlumno="";     // id_alumno en la base de datos
    private String idClase="";       // id_clase en la base de datos
    private String fechaInscripcion=""; // fecha_inscripcion en la base de datos (lo manejo como String)
    private String estado="";       // estado en la base de datos
    private String nombreAlumno;
    private String apellidoAlumno;
    private String nombreCurso;

    public String getNombreCurso() {
        return nombreCurso;
    }

    public void setNombreCurso(String nombreCurso) {
        this.nombreCurso = nombreCurso;
    }
    public String getNombreAlumno() {
        return nombreAlumno;
    }

    public void setNombreAlumno(String nombreAlumno) {
        this.nombreAlumno = nombreAlumno;
    }

    public String getApellidoAlumno() {
        return apellidoAlumno;
    }

    public void setApellidoAlumno(String apellidoAlumno) {
        this.apellidoAlumno = apellidoAlumno;
    }
    
    // Constructor vacío
    public Inscripcion() {
    }

    // Getters y Setters
    public String getIdInscripcion() {
        return idInscripcion;
    }

    public void setIdInscripcion(String idInscripcion) {
        this.idInscripcion = idInscripcion;
    }

    public String getIdAlumno() {
        return idAlumno;
    }

    public void setIdAlumno(String idAlumno) {
        this.idAlumno = idAlumno;
    }

    public String getIdClase() {
        return idClase;
    }

    public void setIdClase(String idClase) {
        this.idClase = idClase;
    }

    public String getFechaInscripcion() {
        return fechaInscripcion;
    }

    public void setFechaInscripcion(String fechaInscripcion) {
        this.fechaInscripcion = fechaInscripcion;
    }

    public String getEstado() {
        return estado;
    }

    public void setEstado(String estado) {
        this.estado = estado;
    }
}