/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package pe.universidad.util;

import java.io.IOException;
import java.io.InputStream;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.DriverManager; // Import this

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import pe.universidad.util.Conexion;

@WebServlet("/MostrarImagen")
public class MostrarImagenServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
        
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        Connection connection = null;
        PreparedStatement preparedStatement = null;
        ResultSet resultSet = null;
        InputStream imageStream = null;
        
        try {
            // Obtener el ID del curso desde el parámetro de la solicitud
            int cursoId = Integer.parseInt(request.getParameter("id"));
            
            // Obtener conexión a la base de datos
            // FIX: Create an instance of Conexion and call its conecta() method
            Conexion conexionUtil = new Conexion(); 
            connection = conexionUtil.conecta(); // Corrected line
            
            // Preparar la consulta SQL para obtener la imagen
            String sql = "SELECT imagen, tipo_imagen FROM Cursos WHERE id_curso = ?";
            preparedStatement = connection.prepareStatement(sql);
            preparedStatement.setInt(1, cursoId);
            
            // Ejecutar la consulta
            resultSet = preparedStatement.executeQuery();
            
            if (resultSet.next()) {
                // Obtener los datos de la imagen y su tipo
                imageStream = resultSet.getBinaryStream("imagen");
                String contentType = resultSet.getString("tipo_imagen");
                
                if (imageStream != null && contentType != null && !contentType.isEmpty()) {
                    // Establecer el tipo de contenido de la respuesta
                    response.setContentType(contentType);
                    
                    // Escribir los datos de la imagen en la respuesta
                    byte[] buffer = new byte[8192];
                    int bytesRead;
                    while ((bytesRead = imageStream.read(buffer)) != -1) {
                        response.getOutputStream().write(buffer, 0, bytesRead);
                    }
                } else {
                    // Si no hay imagen o tipo de contenido
                    response.sendError(HttpServletResponse.SC_NOT_FOUND);
                }
            } else {
                // Si el curso no existe
                response.sendError(HttpServletResponse.SC_NOT_FOUND);
            }
        } catch (SQLException e) {
            e.printStackTrace();
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        } catch (NumberFormatException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST);
        } catch (ClassNotFoundException e) { // Catch ClassNotFoundException
            e.printStackTrace();
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        } finally {
            // Cerrar todos los recursos
            if (imageStream != null) {
                try { imageStream.close(); } catch (IOException e) { }
            }
            if (resultSet != null) {
                try { resultSet.close(); } catch (SQLException e) { }
            }
            if (preparedStatement != null) {
                try { preparedStatement.close(); } catch (SQLException e) { }
            }
            if (connection != null) {
                try { connection.close(); } catch (SQLException e) { }
            }
        }
    }
}