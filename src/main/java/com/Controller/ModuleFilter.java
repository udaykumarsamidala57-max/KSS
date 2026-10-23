package com.Controller;

import java.io.IOException;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.annotation.WebFilter;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.Bean.AppConfig;

/**
 * Sets the institution (KSS / SSS) of every request from the session, so pages and DBUtil use the right one.
 *  - Global user: the institution chosen after login (InstitutionServlet); not chosen yet -> choose page.
 *  - Any other user: always KSS.
 *  - In a CSR-only institution (SSS) the scholarship pages and the site root go to the CSR dashboard.
 */
@WebFilter("/*")
public class ModuleFilter implements Filter {

    private static final Set<String> SCHOLARSHIP = new HashSet<>(Arrays.asList(
            "/", "/Dashboard.jsp",
            "/ScholarshipListServelt", "/ScholarshipServlet", "/ScholarshipViewServlet", "/ScholarshipDocumentUploadServlet",
            "/ScholarshipDocumentDownloadServlet", "/UpdateStatusServlet", "/KssCourseServlet", "/VerifyDocumentsServlet",
            "/ApproveScholarshipServlet", "/KssCourseMasterServlet",
            "/ScholarshipApplication.jsp", "/scholarshipList.jsp", "/scholarshipView.jsp", "/scholarshipDocumentStatus.jsp",
            "/submitted_list.jsp", "/updateStatus.jsp", "/printScholarshipApplication.jsp", "/kssCourse.jsp",
            "/verifyDocuments.jsp", "/approveScholarship.jsp", "/kssCourseMaster.jsp", "/organization.jsp"));

    /** Pages that work before an institution is chosen. */
    private static final Set<String> NO_CHOICE_NEEDED = new HashSet<>(Arrays.asList(
            "/login.jsp", "/LoginServlet", "/Logout.jsp", "/InstitutionServlet", "/selectInstitution.jsp"));

    @Override
    public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain) throws IOException, ServletException {
        HttpServletRequest request = (HttpServletRequest) req;
        HttpServletResponse response = (HttpServletResponse) res;
        String path = request.getRequestURI().substring(request.getContextPath().length());
        if (path.isEmpty()) path = "/";

        HttpSession sess = request.getSession(false);
        boolean loggedIn = sess != null && sess.getAttribute("username") != null;
        String role = loggedIn ? (String) sess.getAttribute("role") : null;
        boolean global = role != null && "Global".equalsIgnoreCase(role.replace(' ', ' ').trim());
        AppConfig.Inst inst = global ? AppConfig.byCode((String) sess.getAttribute(AppConfig.SESSION_KEY)) : AppConfig.KSS;

        AppConfig.setCurrent(inst == null ? AppConfig.KSS : inst);
        try {
            if (global && inst == null && !NO_CHOICE_NEEDED.contains(path)) {
                response.sendRedirect(request.getContextPath() + "/selectInstitution.jsp");   // choose KSS or SSS first
                return;
            }
            if (loggedIn && AppConfig.csrOnly() && SCHOLARSHIP.contains(path)) {
                response.sendRedirect(request.getContextPath() + "/" + AppConfig.homePage());
                return;
            }
            chain.doFilter(req, res);
        } finally {
            AppConfig.clearCurrent();
        }
    }

    @Override
    public void init(FilterConfig filterConfig) { }

    @Override
    public void destroy() { }
}
