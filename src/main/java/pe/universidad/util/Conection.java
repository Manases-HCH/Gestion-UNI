package pe.universidad.util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
public class Conection {
    private Connection cnx;
    /*
    public Connection conecta() throws ClassNotFoundException {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            String usr = "root";
            String psw = "";
            String url = "jdbc:mysql://localhost:3306/bduni";
            cnx = DriverManager.getConnection(url, usr, psw);
            return cnx;
        } catch (SQLException e) {
            System.out.println(e.getMessage());
        }
        return null;
    }
*/
    public Connection conecta() throws ClassNotFoundException {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");

            String host = "nozomi.proxy.rlwy.net";
            String port = "58948";
            String database = "railway";
            String user = "root";
            String password = "WqtWQlNBfsYwEputBlISihwPziyRWCfI";
            
            String url = "jdbc:mysql://" + host + ":" + port + "/" + database
                + "?useSSL=true"
                + "&requireSSL=true"
                + "&allowPublicKeyRetrieval=true"
                + "&serverTimezone=UTC";

             /*     
            String url = "jdbc:mysql://" + host + ":" + port + "/" + database
                    + "?allowPublicKeyRetrieval=true"
                    + "&useSSL=false"
                    + "&requireSSL=false"
                    + "&serverTimezone=UTC";
*/
            cnx = DriverManager.getConnection(url, user, password);
            System.out.println("✔ Conexión Exitosa");
            return cnx;

        } catch (SQLException e) {
            System.out.println("❌ ERROR CONEXIÓN: " + e.getMessage());
            e.printStackTrace();
        }
        return null;
    }

    public int pruebaConexion() throws ClassNotFoundException {
        Connection c = conecta();
        return (c != null) ? 1 : 0;
    }
}


