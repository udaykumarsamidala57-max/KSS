package com.Controller;

import java.io.IOException;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLIntegrityConstraintViolationException;
import java.sql.Statement;
import java.util.ArrayList;
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

/**
 * KSS Course Master (Global role only): add / edit / activate-deactivate / delete
 * rows of kss_course_master. All changes are done with AJAX (JSON responses).
 */
@WebServlet("/KssCourseMasterServlet")
public class KssCourseMasterServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    private boolean isGlobal(HttpSession sess) {
        String role = (String) sess.getAttribute("role");
        return role != null && "Global".equalsIgnoreCase(role.replace('\u00A0', ' ').strip());
    }

    // ------------------------------------------------------------------ GET : list page
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
        String sql = "SELECT c.id, c.course_name, c.sanctioned_amount, c.is_active, c.sort_order, "
                   + "(SELECT COUNT(*) FROM kss_student_scholarship s WHERE TRIM(s.KSS_courses) = c.course_name) AS used_count "
                   + "FROM kss_course_master c ORDER BY c.sort_order, c.course_name";

        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, String> r = new LinkedHashMap<>();
                r.put("id", String.valueOf(rs.getInt("id")));
                r.put("name", rs.getString("course_name"));
                BigDecimal amt = rs.getBigDecimal("sanctioned_amount");
                r.put("amount", amt == null ? "0.00" : amt.setScale(2, RoundingMode.HALF_UP).toPlainString());
                r.put("active", rs.getInt("is_active") == 1 ? "1" : "0");
                r.put("sort", String.valueOf(rs.getInt("sort_order")));
                r.put("used", String.valueOf(rs.getInt("used_count")));
                rows.add(r);
            }
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Database error: " + e.getMessage()
                    + " (Has the kss_course_master table been created?)");
        }

        request.setAttribute("rows", rows);
        request.getRequestDispatcher("/kssCourseMaster.jsp").forward(request, response);
    }

    // ------------------------------------------------------------------ POST : AJAX actions
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            sendJson(response, HttpServletResponse.SC_UNAUTHORIZED, fail("Your session has expired. Please log in again."));
            return;
        }
        if (!isGlobal(sess)) {
            sendJson(response, HttpServletResponse.SC_FORBIDDEN, fail("Only Global users can manage KSS courses."));
            return;
        }

        String action = request.getParameter("action");
        try (Connection con = DBUtil.getConnection()) {
            if ("save".equals(action)) {
                save(request, response, con);
            } else if ("toggle".equals(action)) {
                toggle(request, response, con);
            } else if ("delete".equals(action)) {
                delete(request, response, con);
            } else {
                sendJson(response, HttpServletResponse.SC_BAD_REQUEST, fail("Unknown action."));
            }
        } catch (Exception e) {
            e.printStackTrace();
            sendJson(response, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, fail("Database error: " + e.getMessage()));
        }
    }

    /** Add (no id) or update (with id). Renaming also updates applications using the old name. */
    private void save(HttpServletRequest request, HttpServletResponse response, Connection con) throws Exception {
        String idParam = request.getParameter("id");
        String name = request.getParameter("name");
        name = name == null ? "" : name.replace('\u00A0', ' ').trim().replaceAll("\\s+", " ");
        String amountParam = request.getParameter("amount");
        String sortParam = request.getParameter("sort");

        if (name.isEmpty()) {
            sendJson(response, HttpServletResponse.SC_BAD_REQUEST, fail("Please enter the course name."));
            return;
        }
        if (name.length() > 150) {
            sendJson(response, HttpServletResponse.SC_BAD_REQUEST, fail("Course name is too long (max 150 characters)."));
            return;
        }

        BigDecimal amount;
        try {
            amount = new BigDecimal(amountParam == null ? "" : amountParam.trim().replace(",", ""));
        } catch (NumberFormatException e) {
            amount = null;
        }
        if (amount == null || amount.signum() < 0 || amount.compareTo(new BigDecimal("9999999999")) > 0) {
            sendJson(response, HttpServletResponse.SC_BAD_REQUEST, fail("Please enter a valid sanctioned amount (0 or more)."));
            return;
        }
        amount = amount.setScale(2, RoundingMode.HALF_UP);

        int sort = 0;
        if (sortParam != null && sortParam.trim().matches("-?\\d{1,6}")) sort = Integer.parseInt(sortParam.trim());

        boolean isNew = idParam == null || idParam.trim().isEmpty();
        int renamedApps = 0;
        int id;

        try {
            if (isNew) {
                if (sortParam == null || sortParam.trim().isEmpty()) {
                    try (PreparedStatement ps = con.prepareStatement("SELECT COALESCE(MAX(sort_order), 0) + 1 FROM kss_course_master");
                         ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) sort = rs.getInt(1);
                    }
                }
                try (PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO kss_course_master (course_name, sanctioned_amount, sort_order) VALUES (?, ?, ?)",
                        Statement.RETURN_GENERATED_KEYS)) {
                    ps.setString(1, name);
                    ps.setBigDecimal(2, amount);
                    ps.setInt(3, sort);
                    ps.executeUpdate();
                    try (ResultSet keys = ps.getGeneratedKeys()) {
                        keys.next();
                        id = keys.getInt(1);
                    }
                }
            } else {
                if (!idParam.trim().matches("\\d+")) {
                    sendJson(response, HttpServletResponse.SC_BAD_REQUEST, fail("Invalid course."));
                    return;
                }
                id = Integer.parseInt(idParam.trim());

                String oldName = null;
                try (PreparedStatement ps = con.prepareStatement("SELECT course_name FROM kss_course_master WHERE id = ?")) {
                    ps.setInt(1, id);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) oldName = rs.getString(1);
                    }
                }
                if (oldName == null) {
                    sendJson(response, HttpServletResponse.SC_NOT_FOUND, fail("Course not found. Please reload the page."));
                    return;
                }

                con.setAutoCommit(false);
                try {
                    try (PreparedStatement ps = con.prepareStatement(
                            "UPDATE kss_course_master SET course_name = ?, sanctioned_amount = ?, sort_order = ? WHERE id = ?")) {
                        ps.setString(1, name);
                        ps.setBigDecimal(2, amount);
                        ps.setInt(3, sort);
                        ps.setInt(4, id);
                        ps.executeUpdate();
                    }
                    // Keep applications pointing at the course when it is renamed
                    if (!oldName.equals(name)) {
                        try (PreparedStatement ps = con.prepareStatement(
                                "UPDATE kss_student_scholarship SET KSS_courses = ? WHERE TRIM(KSS_courses) = ?")) {
                            ps.setString(1, name);
                            ps.setString(2, oldName);
                            renamedApps = ps.executeUpdate();
                        }
                    }
                    con.commit();
                } catch (Exception e) {
                    con.rollback();
                    throw e;
                } finally {
                    con.setAutoCommit(true);
                }
            }
        } catch (SQLIntegrityConstraintViolationException dup) {
            sendJson(response, HttpServletResponse.SC_CONFLICT, fail("A course named \"" + name + "\" already exists."));
            return;
        }

        JsonObject json = rowJson(con, id);
        json.addProperty("ok", true);
        json.addProperty("isNew", isNew);
        json.addProperty("message", (isNew ? "Course added: " : "Course updated: ") + name
                + (renamedApps > 0 ? " (" + renamedApps + " application" + (renamedApps == 1 ? "" : "s") + " updated to the new name)" : ""));
        sendJson(response, HttpServletResponse.SC_OK, json);
    }

    /** Activate / deactivate (inactive courses are hidden from the KSS Course dropdown). */
    private void toggle(HttpServletRequest request, HttpServletResponse response, Connection con) throws Exception {
        String idParam = request.getParameter("id");
        if (idParam == null || !idParam.trim().matches("\\d+")) {
            sendJson(response, HttpServletResponse.SC_BAD_REQUEST, fail("Invalid course."));
            return;
        }
        int id = Integer.parseInt(idParam.trim());
        int n;
        try (PreparedStatement ps = con.prepareStatement(
                "UPDATE kss_course_master SET is_active = 1 - is_active WHERE id = ?")) {
            ps.setInt(1, id);
            n = ps.executeUpdate();
        }
        if (n == 0) {
            sendJson(response, HttpServletResponse.SC_NOT_FOUND, fail("Course not found. Please reload the page."));
            return;
        }
        JsonObject json = rowJson(con, id);
        json.addProperty("ok", true);
        json.addProperty("message", "Course " + ("1".equals(json.get("active").getAsString()) ? "activated" : "deactivated")
                + ": " + json.get("name").getAsString());
        sendJson(response, HttpServletResponse.SC_OK, json);
    }

    /** Delete only when no application uses the course. */
    private void delete(HttpServletRequest request, HttpServletResponse response, Connection con) throws Exception {
        String idParam = request.getParameter("id");
        if (idParam == null || !idParam.trim().matches("\\d+")) {
            sendJson(response, HttpServletResponse.SC_BAD_REQUEST, fail("Invalid course."));
            return;
        }
        int id = Integer.parseInt(idParam.trim());
        JsonObject row = rowJson(con, id);
        if (!row.has("name")) {
            sendJson(response, HttpServletResponse.SC_NOT_FOUND, fail("Course not found. Please reload the page."));
            return;
        }
        int used = row.get("used").getAsInt();
        if (used > 0) {
            sendJson(response, HttpServletResponse.SC_CONFLICT, fail("Cannot delete \"" + row.get("name").getAsString()
                    + "\": it is used by " + used + " application" + (used == 1 ? "" : "s") + ". Deactivate it instead."));
            return;
        }
        try (PreparedStatement ps = con.prepareStatement("DELETE FROM kss_course_master WHERE id = ?")) {
            ps.setInt(1, id);
            ps.executeUpdate();
        }
        JsonObject json = new JsonObject();
        json.addProperty("ok", true);
        json.addProperty("id", id);
        json.addProperty("message", "Course deleted: " + row.get("name").getAsString());
        sendJson(response, HttpServletResponse.SC_OK, json);
    }

    private JsonObject rowJson(Connection con, int id) throws Exception {
        JsonObject json = new JsonObject();
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT c.id, c.course_name, c.sanctioned_amount, c.is_active, c.sort_order, "
              + "(SELECT COUNT(*) FROM kss_student_scholarship s WHERE TRIM(s.KSS_courses) = c.course_name) AS used_count "
              + "FROM kss_course_master c WHERE c.id = ?")) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    json.addProperty("id", rs.getInt("id"));
                    json.addProperty("name", rs.getString("course_name"));
                    BigDecimal amt = rs.getBigDecimal("sanctioned_amount");
                    json.addProperty("amount", amt == null ? "0.00" : amt.setScale(2, RoundingMode.HALF_UP).toPlainString());
                    json.addProperty("active", rs.getInt("is_active") == 1 ? "1" : "0");
                    json.addProperty("sort", rs.getInt("sort_order"));
                    json.addProperty("used", rs.getInt("used_count"));
                }
            }
        }
        return json;
    }

    private static JsonObject fail(String message) {
        JsonObject json = new JsonObject();
        json.addProperty("ok", false);
        json.addProperty("message", message);
        return json;
    }

    private void sendJson(HttpServletResponse response, int status, JsonObject json) throws IOException {
        response.setStatus(status);
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write(json.toString());
    }
}
