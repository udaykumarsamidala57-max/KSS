package com.Controller;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.Bean.ScholarshipBean;
import com.DAO.scholarshipViewDAO;

@WebServlet("/ScholarshipViewServlet")
public class ScholarshipViewServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    public ScholarshipViewServlet() {
        super();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        try {
            String idStr = request.getParameter("id");

            // Safeguard against missing or malformed IDs
            if (idStr == null || idStr.trim().isEmpty()) {
                response.sendRedirect("ScholarshipListServelt"); // Note: Matches your exact typo spelling
                return;
            }

            int id = Integer.parseInt(idStr);
            scholarshipViewDAO dao = new scholarshipViewDAO();
            ScholarshipBean bean = dao.getScholarshipById(id);

            // Always forward to the view JSP; the JSP's (bean == null) checks handle the UI logic natively
            request.setAttribute("bean", bean);
            request.getRequestDispatcher("scholarshipView.jsp").forward(request, response);

        } catch (NumberFormatException e) {
            // Gracefully fall back if the ID is not an integer string
            response.sendRedirect("ScholarshipListServelt");
        } catch (Exception e) {
            e.printStackTrace();
            throw new ServletException("Error retrieving scholarship details", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        doGet(request, response);
    }
}