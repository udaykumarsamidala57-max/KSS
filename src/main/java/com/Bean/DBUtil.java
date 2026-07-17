package com.Bean;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DBUtil {


	
	//private static final String URL = System.getenv("MYSQLHOST");
   //private static final String USER = "root";
//private static final String PASSWORD = System.getenv("MYSQLPASSWORD");
	
	private static final String URL = "jdbc:mysql://shuttle.proxy.rlwy.net:26985/KSS?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC&tcpKeepAlive=true";
	   private static final String USER = "root";
	   private static final String PASSWORD = "vSZVibKCzvcovcGjaLlxrTddrjiNPVQn";
	
	
	
	
    static {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
        	
            e.printStackTrace();
        }
    }

    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(URL, USER, PASSWORD);
    }
}