package pe.edu.entity;

/**
 *
 * @author LENOVO
 */
public class Carrera {
    private String idCarrera = "";
    private String nombreCarrera = "";
    private String idFacultad = "";
    
    public Carrera() {
    }
    
    // Constructor con parámetros
    public Carrera(String idCarrera, String nombreCarrera, String idFacultad) {
        this.idCarrera = idCarrera;
        this.nombreCarrera = nombreCarrera;
        this.idFacultad = idFacultad;
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
    
    @Override
    public String toString() {
        return "Carrera{" + 
               "idCarrera=" + idCarrera + 
               ", nombreCarrera=" + nombreCarrera + 
               ", idFacultad=" + idFacultad + 
               '}';
    }
}