package com.Controller;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.Bean.AppConfig;

/**
 * Choose / switch the institution (Global users only).
 *  GET InstitutionServlet?code=KSS|SSS  -> remembers it in the session and opens its first page.
 */
@WebServlet("/InstitutionServlet")
public class InstitutionServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return;
        }
        String role = (String) sess.getAttribute("role");
        if (role == null || !"Global".equalsIgnoreCase(role.replace(' ', ' ').trim())) {
            response.sendRedirect("Dashboard.jsp");   // other users always work in KSS
            return;
        }
        AppConfig.Inst inst = AppConfig.byCode(request.getParameter("code"));
        if (inst == null) {
            response.sendRedirect("selectInstitution.jsp");
            return;
        }
        sess.setAttribute(AppConfig.SESSION_KEY, inst.code);
        response.sendRedirect(inst.csrOnly ? "CsrDashboardServlet" : "Dashboard.jsp");
    }
}
