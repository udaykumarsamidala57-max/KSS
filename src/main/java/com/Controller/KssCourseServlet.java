package com.Controller;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.Bean.DBUtil;
import com.google.gson.JsonObject;
import com.DAO.scholarshipListDAO;

/**
 * Lists SUBMITTED applications and lets a Global user set the KSS course
 * (column kss_student_scholarship.KSS_courses) from a dropdown.
 */
@WebServlet("/KssCourseServlet")
public class KssCourseServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    // Fallback list, used only if the kss_course_master table is missing or empty.
    // The real list is managed on the KSS Course Master page.
    public static final List<String> KSS_COURSES = Arrays.asList(
        "2 YEAR DIPLOMA/DEGREE IN EDUCATION",
        "2 YEAR PG DEGREE",
        "2 YEAR PG ENGINEERING",
        "3 Year DIPLOMA",
        "3/4 DEGREE",
        "CA/CS/CMA",
        "DIPLOMA",
        "ENGINEERING",
        "ITI/NURSING",
        "MEDICINE",
        "PUC",
        "PUC BANGALORE"
    );

    /** Active courses from kss_course_master (in sort order); falls back to KSS_COURSES. */
    public static List<String> loadCourses() {
        List<String> list = new java.util.ArrayList<>();
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(
                     "SELECT course_name FROM kss_course_master WHERE is_active = 1 ORDER BY sort_order, course_name");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(rs.getString(1));
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list.isEmpty() ? KSS_COURSES : list;
    }

    /** Only Global users may use this page. */
    private boolean isGlobal(HttpSession sess) {
        String role = (String) sess.getAttribute("role");
        return role != null && "Global".equalsIgnoreCase(role.replace('\u00A0', ' ').strip());
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return;
        }
        if (!isGlobal(sess)) {
            response.sendRedirect("Dashboard.jsp");
            return;
        }

        List<Map<String, String>> rows = new ArrayList<>();

        // No BLOB columns here, only what the page shows
        String sql = "SELECT id, App_no, org_name, emp_no, emp_name, children_name, "
                   + "college_name, course, present_year, KSS_courses "
                   + "FROM kss_student_scholarship "
                   + "WHERE TRIM(submiited) = 'Submitted' "
                   + "ORDER BY (KSS_courses IS NULL OR TRIM(KSS_courses) = '') DESC, TRIM(org_name), id DESC";

        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Map<String, String> r = new LinkedHashMap<>();
                r.put("id", String.valueOf(rs.getInt("id")));
                r.put("appNo", rs.getString("App_no"));
                r.put("orgName", rs.getString("org_name"));
                r.put("empNo", rs.getString("emp_no"));
                r.put("empName", rs.getString("emp_name"));
                r.put("childName", rs.getString("children_name"));
                r.put("college", rs.getString("college_name"));
                r.put("course", rs.getString("course"));
                r.put("presentYear", rs.getString("present_year"));
                r.put("kssCourse", rs.getString("KSS_courses"));
                rows.add(r);
            }
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Database error: " + e.getMessage());
        }

        request.setAttribute("rows", rows);
        request.setAttribute("courses", loadCourses());
        request.getRequestDispatcher("/kssCourse.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return;
        }
        boolean ajax = "XMLHttpRequest".equals(request.getHeader("X-Requested-With"));

        if (!isGlobal(sess)) {
            if (ajax) {
                sendJson(response, HttpServletResponse.SC_FORBIDDEN, false, "Only Global users can change the KSS course.", null);
            } else {
                response.sendRedirect("Dashboard.jsp");
            }
            return;
        }

        String user = (String) sess.getAttribute("username");
        String idParam = request.getParameter("id");
        String kssCourse = request.getParameter("kssCourse");
        kssCourse = (kssCourse == null) ? "" : kssCourse.trim();

        String msg;
        boolean ok = false;
        String savedValue = null;

        if (idParam == null || !idParam.trim().matches("\\d+")) {
            msg = "Invalid application.";
        } else if (!kssCourse.isEmpty() && !loadCourses().contains(kssCourse)) {
            msg = "Please choose a course from the list.";
        } else {
            int id = Integer.parseInt(idParam.trim());
            String newValue = kssCourse.isEmpty() ? null : kssCourse;

            try (Connection con = DBUtil.getConnection()) {

                // Read current values (for the audit trail and the message)
                String appNo = null, empNo = null, empName = null, oldValue = null;
                try (PreparedStatement ps = con.prepareStatement(
                        "SELECT App_no, emp_no, emp_name, KSS_courses FROM kss_student_scholarship "
                      + "WHERE id = ? AND TRIM(submiited) = 'Submitted'")) {
                    ps.setInt(1, id);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            appNo = rs.getString("App_no");
                            empNo = rs.getString("emp_no");
                            empName = rs.getString("emp_name");
                            oldValue = rs.getString("KSS_courses");
                        }
                    }
                }

                if (appNo == null && empNo == null) {
                    msg = "Application not found or not submitted.";
                } else {
                    try (PreparedStatement ps = con.prepareStatement(
                            "UPDATE kss_student_scholarship SET KSS_courses = ? WHERE id = ?")) {
                        ps.setString(1, newValue);
                        ps.setInt(2, id);
                        ok = ps.executeUpdate() > 0;
                    }

                    if (ok) {
                        new scholarshipListDAO().logAudit(con, id, "UPDATE", appNo, empNo, empName, user,
                                "KSS_courses: '" + (oldValue == null ? "" : oldValue) + "' -> '"
                                + (newValue == null ? "" : newValue) + "'");
                        msg = "KSS course updated for " + (appNo != null ? appNo : ("ID " + id)) + ".";
                        savedValue = newValue;
                    } else {
                        msg = "Update failed.";
                    }
                }
            } catch (Exception e) {
                e.printStackTrace();
                msg = "Database error: " + e.getMessage();
            }
        }

        if (ajax) {
            // jQuery request: answer with JSON, no page reload
            sendJson(response, HttpServletResponse.SC_OK, ok, msg, savedValue);
            return;
        }

        // Normal form post (fallback): Post/Redirect/Get so refreshing does not resubmit
        response.sendRedirect("KssCourseServlet?" + (ok ? "msg=" : "err=")
                + URLEncoder.encode(msg, StandardCharsets.UTF_8));
    }

    private void sendJson(HttpServletResponse response, int status, boolean ok, String message, String value)
            throws IOException {
        JsonObject json = new JsonObject();
        json.addProperty("ok", ok);
        json.addProperty("message", message);
        json.addProperty("value", value);
        response.setStatus(status);
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write(json.toString());
    }
}
