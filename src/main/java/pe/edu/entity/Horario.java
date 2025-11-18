package pe.edu.entity;

import java.sql.Time; // Puedes usar java.sql.Time si lo necesitas, pero por simplicidad usaré String para las horas en JSP

public class Horario {
    private String idHorario = ""; // id_horario en la base de datos
    private String diaSemana = ""; // dia_semana en la base de datos
    private String horaInicio = ""; // hora_inicio en la base de datos, lo manejo como String
    private String horaFin = "" ;    // hora_fin en la base de datos, lo manejo como String
    private String aula = "";       // aula en la base de datos

    // Constructor vacío
    public Horario() {
    }

    // Getters y Setters
    public String getIdHorario() {
        return idHorario;
    }

    public void setIdHorario(String idHorario) {
        this.idHorario = idHorario;
    }

    public String getDiaSemana() {
        return diaSemana;
    }

    public void setDiaSemana(String diaSemana) {
        this.diaSemana = diaSemana;
    }

    public String getHoraInicio() {
        return horaInicio;
    }

    public void setHoraInicio(String horaInicio) {
        this.horaInicio = horaInicio;
    }

    public String getHoraFin() {
        return horaFin;
    }

    public void setHoraFin(String horaFin) {
        this.horaFin = horaFin;
    }

    public String getAula() {
        return aula;
    }

    public void setAula(String aula) {
        this.aula = aula;
    }
}