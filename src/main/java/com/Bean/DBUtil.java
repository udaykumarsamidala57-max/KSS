package com.Bean;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DBUtil {


	
	//private static final String URL = System.getenv("MYSQLHOST");
   //private static final String USER = "root";

	
	private static final String URL = "jdbc:mysql://shuttle.proxy.rlwy.net:26985/KSS?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC&tcpKeepAlive=true";
	   private static final String USER = "root";
	  
	   private static final String PASSWORD = "JKaqOrLeYxQdfhgbJoQdmvJOlbYvQyhi";
	
	
	
    static {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
        	
            e.printStackTrace();
        }
    }

    /**
     * Connection to the schema of the institution of the current request (AppConfig / ModuleFilter):
     * KSS uses the schema in URL above, SSS uses SSS_CSR on the same MySQL server.
     */
    public static Connection getConnection() throws SQLException {
        Connection con = DriverManager.getConnection(URL, USER, PASSWORD);
        String schema = AppConfig.schema();
        if (schema != null) {
            try {
                con.setCatalog(schema);
            } catch (SQLException e) {
                con.close();
                throw e;
            }
        }
        return con;
    }
}