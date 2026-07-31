package com.Controller;

import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import javax.servlet.RequestDispatcher;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import com.Bean.DBUtil;

@WebServlet("/LoginServlet")
public class LoginServlet extends HttpServlet {

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
	    // Redirect to login page if accessed with GET
	    response.sendRedirect("login.jsp");
	}
    @Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String uname = request.getParameter("username");
        String pass = request.getParameter("password");
        String dept = request.getParameter("department");
       

        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            con = DBUtil.getConnection();

            ps = con.prepareStatement("SELECT role,department FROM users WHERE username=? AND password=?");
            ps.setString(1, uname);
            ps.setString(2, pass);
            rs = ps.executeQuery();

            if (rs.next()) {
                String role = rs.getString("role");
                String department = rs.getString("department");
                HttpSession session = request.getSession();
                session.setAttribute("username", uname);
                session.setAttribute("role", role);
                session.setAttribute("department", department);
              
                
                // Redirect based on role
                if ("Global".equalsIgnoreCase(role)) {
                    response.sendRedirect("ScholarshipListServelt");
                } else if ("incharge".equalsIgnoreCase(role)||"Finance".equalsIgnoreCase(dept)) {
                    response.sendRedirect("ScholarshipListServelt");
                } else if ("HOSTEL".equalsIgnoreCase(department)) {
                    response.sendRedirect("ScholarshipListServelt");
                } else {
                    response.sendRedirect("ScholarshipListServelt");
                }
            } else {
                request.setAttribute("error", "Invalid Username or Password!");
                RequestDispatcher rd = request.getRequestDispatcher("login.jsp");
                rd.forward(request, response);
            }

        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            try { if (rs != null) {
				rs.close();
			} } catch (Exception ignored) {}
            try { if (ps != null) {
				ps.close();
			} } catch (Exception ignored) {}
            try { if (con != null) {
				con.close();
			} } catch (Exception ignored) {}
        }
    }
}
