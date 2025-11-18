package pe.edu.entity;

public class Nota {
    private String idNota=""; // id_nota en la base de datos
    private String idInscripcion=""; // id_inscripcion en la base de datos
    private String nota1="";    // nota1 en la base de datos
    private String nota2="";    // nota2 en la base de datos
    private String notaFinal=""; // nota_final en la base de datos
    private String estado="";   // estado en la base de datos

    // Constructor vacío
    public Nota() {
    }

    // Getters y Setters
    public String getIdNota() {
        return idNota;
    }

    public void setIdNota(String idNota) {
        this.idNota = idNota;
    }

    public String getIdInscripcion() {
        return idInscripcion;
    }

    public void setIdInscripcion(String idInscripcion) {
        this.idInscripcion = idInscripcion;
    }

    public String getNota1() {
        return nota1;
    }

    public void setNota1(String nota1) {
        this.nota1 = nota1;
    }

    public String getNota2() {
        return nota2;
    }

    public void setNota2(String nota2) {
        this.nota2 = nota2;
    }

    public String getNotaFinal() {
        return notaFinal;
    }

    public void setNotaFinal(String notaFinal) {
        this.notaFinal = notaFinal;
    }

    public String getEstado() {
        return estado;
    }

    public void setEstado(String estado) {
        this.estado = estado;
    }
}