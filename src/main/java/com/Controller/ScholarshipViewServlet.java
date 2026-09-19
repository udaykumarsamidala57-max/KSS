package com.Controller;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

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
        
        // 1. Session Authentication Check
        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        // 2. Referer Header Check: Verify request comes from the List page/servlet
        String referer = request.getHeader("referer");
        
        // If referer is null (direct URL typed into address bar) or doesn't originate from the list page, block it
        if (referer == null || !referer.contains("ScholarshipListServelt")) {
            response.sendRedirect("ScholarshipListServelt");
            return;
        }

        // 3. Process Request
        processViewRequest(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        // Session Authentication Check
        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        // POST requests directly from forms on the list page are treated as valid
        processViewRequest(request, response);
    }

    /**
     * Helper method to handle application lookup and forwarding
     */
    private void processViewRequest(HttpServletRequest request, HttpServletResponse response)
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
            
            // Fetches the bean containing text, numeric, and binary file byte arrays
            ScholarshipBean bean = dao.getScholarshipById(id);

            if (bean == null) {
                response.sendRedirect("ScholarshipListServelt");
                return;
            }

            // Bind the bean payload to the request scope attributes
            request.setAttribute("bean", bean);
            
            // Forward execution to the presentation layer view
            request.getRequestDispatcher("scholarshipView.jsp").forward(request, response);

        } catch (NumberFormatException e) {
            // Handle non-numeric parameter injections
            response.sendRedirect("ScholarshipListServelt");
        } catch (Exception e) {
            getServletContext().log("Exception encountered inside ScholarshipViewServlet processing request parameters", e);
            throw new ServletException("Core application error processing scholarship file system retrieval pipeline.", e);
        }
    }
}