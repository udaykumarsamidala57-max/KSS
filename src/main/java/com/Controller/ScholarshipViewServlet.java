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

            // Safeguard against missing, empty, or malformed ID query parameters
            if (idStr == null || idStr.trim().isEmpty()) {
                response.sendRedirect("ScholarshipListServelt");
                return;
            }

            int id = Integer.parseInt(idStr);
            scholarshipViewDAO dao = new scholarshipViewDAO();
            
            // Fetches the bean natively containing the text, numeric, and binary file byte arrays
            ScholarshipBean bean = dao.getScholarshipById(id);

            // Bind the bean payload to the request scope attributes
            request.setAttribute("bean", bean);
            
            // Forward execution down to the presentation layer view
            request.getRequestDispatcher("scholarshipView.jsp").forward(request, response);

        } catch (NumberFormatException e) {
            // Gracefully handle situations where non-numeric parameters are injected into the URI
            response.sendRedirect("ScholarshipListServelt");
        } catch (Exception e) {
            // Standardize deep stack tracing to local servlet container tracking logs
            getServletContext().log("Exception encountered inside ScholarshipViewServlet processing request parameters", e);
            throw new ServletException("Core application error processing scholarship file system retrieval pipeline.", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        doGet(request, response);
    }
}