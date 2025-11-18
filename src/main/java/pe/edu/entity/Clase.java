/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package pe.edu.entity;

/**
 *
 * @author LENOVO
 */
public class Clase { // Asumiendo que estas variables pertenecen a una clase llamada "Clase"

    private String idClase = "";
    private String idCurso = "";
    private String idProfesor = "";
    private String idHorario = "";
    private String ciclo = "";
    private String nombreCurso = "";
    private String nombreProfesor = "";

    // Constructor vacío (opcional pero recomendado para JavaBeans)
    public Clase() {
    }

    // Getters y Setters para idClase
    public String getIdClase() {
        return idClase;
    }

    public void setIdClase(String idClase) {
        this.idClase = idClase;
    }

    // Getters y Setters para idCurso
    public String getIdCurso() {
        return idCurso;
    }

    public void setIdCurso(String idCurso) {
        this.idCurso = idCurso;
    }

    // Getters y Setters para idProfesor
    public String getIdProfesor() {
        return idProfesor;
    }

    public void setIdProfesor(String idProfesor) {
        this.idProfesor = idProfesor;
    }

    // Getters y Setters para idHorario
    public String getIdHorario() {
        return idHorario;
    }

    public void setIdHorario(String idHorario) {
        this.idHorario = idHorario;
    }

    // Getters y Setters para ciclo
    public String getCiclo() {
        return ciclo;
    }

    public void setCiclo(String ciclo) {
        this.ciclo = ciclo;
    }

    // Getters y Setters para nombreCurso
    public String getNombreCurso() {
        return nombreCurso;
    }

    public void setNombreCurso(String nombreCurso) {
        this.nombreCurso = nombreCurso;
    }

    // Getters y Setters para nombreProfesor
    public String getNombreProfesor() {
        return nombreProfesor;
    }

    public void setNombreProfesor(String nombreProfesor) {
        this.nombreProfesor = nombreProfesor;
    }
}