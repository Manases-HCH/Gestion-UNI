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
                String url = "jdbc:mysql://localhost:3306/bd-uni";
                cnx = DriverManager.getConnection(url, usr, psw);
                return cnx;
            } catch (SQLException e) {
                System.out.println(e.getMessage());
            }
            return null;
        }
        /*
        public Connection conecta() throws ClassNotFoundException {
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");

                String host = "interchange.proxy.rlwy.net";
                String port = "15497";
                String database = "railway";
                String user = "root"; 
                String password = "uwWbcOhGyyQnzLMJEAOFqAxlqbllNgzE";

                String url = "jdbc:mysql://" + host + ":" + port + "/" + database
                    + "?sslMode=DISABLED"
                    + "&connectTimeout=15000"
                    + "&socketTimeout=15000"
                    + "&allowPublicKeyRetrieval=true";
                
                Connection cnx = DriverManager.getConnection(url, user, password);
                System.out.println("✔ Conexión exitosa a Railway");
                return cnx;

            } catch (SQLException e) {
                System.out.println("❌ Falló la conexión JDBC");
                System.out.println("Mensaje: " + e.getMessage());
                return null;
            }
        }
*/
        
        public Connection conecta() throws ClassNotFoundException {
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");

                // 🔹 Leer variables desde Render Environment
                String host = System.getenv("DB_HOST");
                String port = System.getenv("DB_PORT");
                String database = System.getenv("DB_NAME");
                String user = System.getenv("DB_USER");
                String password = System.getenv("DB_PASS");

                // 🔎 Validación si Render no envió alguna variable
                if (host == null) {
                    System.out.println("❌ ERROR: Variables de entorno no detectadas en Render.");
                    System.out.println("Asegúrate de haber creado:");
                    System.out.println("DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASS");
                    return null;
                }

                // 🔹 URL JDBC optimizada para Railway + Render
                String url = "jdbc:mysql://" + host + ":" + port + "/" + database
                        + "?useSSL=false"
                        + "&allowPublicKeyRetrieval=true"
                        + "&autoReconnect=true"
                        + "&serverTimezone=UTC";

                cnx = DriverManager.getConnection(url, user, password);
                System.out.println("✔ Conexión exitosa a MySQL Render/Railway");
                return cnx;

            } catch (SQLException e) {
                System.out.println("❌ Falló la conexión JDBC");
                System.out.println("Mensaje: " + e.getMessage());
                return null;
            }
        }
        
        public int pruebaConexion() throws ClassNotFoundException {
            Connection c = conecta();
            return (c != null) ? 1 : 0;
        }
    }


