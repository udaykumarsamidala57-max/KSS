package com.Controller;

import java.io.IOException;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLIntegrityConstraintViolationException;
import java.sql.SQLSyntaxErrorException;
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
 * Masters > CSR Activities & Places (Global only): the lists offered on the Management Approval form
 * for "Kind of CSR Activity" and "Place". Table kss_csr_activity_place (kind = Activity / Place).
 * The approval keeps the name as text (activity_kind / place); renaming an entry here also renames it
 * on the approvals that use it, so the dashboard Unit grouping stays correct.
 *
 *   GET                         list (csrActivityPlaces.jsp)
 *   GET ?action=form[&id=N|&kind=Activity|Place]   add / edit form (csrActivityPlaceForm.jsp)
 *   POST action=save            add / edit (AJAX, JSON)
 *   POST action=delete          delete (AJAX, JSON) - not allowed while an approval uses it
 */
@WebServlet("/CsrActivityPlaceServlet")
public class CsrActivityPlaceServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    static final String ACTIVITY = "Activity";
    static final String PLACE = "Place";
    static final String SETUP_HINT = "Run Dump20261016\\KSS_csr_activity_place.sql in this institution's database.";

    /** Approval-letter column that holds the name of each kind. Fixed strings only, never user input. */
    private static String letterColumn(String kind) { return ACTIVITY.equals(kind) ? "activity_kind" : "place"; }

    private static int maxLength(String kind) { return ACTIVITY.equals(kind) ? 150 : 200; }

    static String label(String kind) { return ACTIVITY.equals(kind) ? "Kind of CSR Activity" : "Place"; }

    private static final String COLUMNS =
            "m.id, m.kind, m.name, m.status, "
          + "m.created_by, DATE_FORMAT(m.created_at, '%d-%m-%Y') AS created_txt, "
          + "m.updated_by, DATE_FORMAT(m.updated_at, '%d-%m-%Y %H:%i') AS updated_txt, "
          + "(SELECT COUNT(*) FROM kss_csr_approval_letter l "
          + "  WHERE (m.kind = 'Activity' AND TRIM(l.activity_kind) = m.name) OR (m.kind = 'Place' AND TRIM(l.place) = m.name)) AS letter_count, "
          + "(SELECT COALESCE(SUM(l.amount), 0) FROM kss_csr_approval_letter l "
          + "  WHERE (m.kind = 'Activity' AND TRIM(l.activity_kind) = m.name) OR (m.kind = 'Place' AND TRIM(l.place) = m.name)) AS sanctioned";

    // ------------------------------------------------------------------ GET
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) { response.sendRedirect("login.jsp"); return; }
        if (!CsrCompanyServlet.isGlobal(sess)) { response.sendRedirect("Dashboard.jsp"); return; }

        boolean form = "form".equals(request.getParameter("action"));
        String idParam = request.getParameter("id");
        String kindParam = request.getParameter("kind");
        List<Map<String, String>> rows = new ArrayList<>();
        Map<String, String> row = null;
        try (Connection con = DBUtil.getConnection()) {
            if (form) {
                if (idParam != null && idParam.matches("\\d+")) {
                    row = one(con, Integer.parseInt(idParam));
                    if (row == null) { response.sendRedirect("CsrActivityPlaceServlet"); return; }
                }
            } else {
                try (PreparedStatement ps = con.prepareStatement(
                        "SELECT " + COLUMNS + " FROM kss_csr_activity_place m ORDER BY m.kind, m.status, m.name");
                     ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) rows.add(toMap(rs));
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Database error: " + e.getMessage() + " (" + SETUP_HINT + ")");
        }
        if (form) {
            request.setAttribute("row", row);
            request.setAttribute("presetKind", PLACE.equals(kindParam) ? PLACE : ACTIVITY);
            request.setAttribute("formReady", Boolean.TRUE);
            request.getRequestDispatcher("/csrActivityPlaceForm.jsp").forward(request, response);
        } else {
            request.setAttribute("rows", rows);
            request.getRequestDispatcher("/csrActivityPlaces.jsp").forward(request, response);
        }
    }

    // ------------------------------------------------------------------ POST (AJAX)
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            sendJson(response, 401, fail("Your session has expired. Please log in again."));
            return;
        }
        if (!CsrCompanyServlet.isGlobal(sess)) {
            sendJson(response, 403, fail("Only Global users can manage CSR activities and places."));
            return;
        }
        String user = (String) sess.getAttribute("username");
        String action = request.getParameter("action");
        try (Connection con = DBUtil.getConnection()) {
            if ("save".equals(action)) save(request, response, con, user);
            else if ("delete".equals(action)) delete(request, response, con);
            else sendJson(response, 400, fail("Unknown action."));
        } catch (Exception e) {
            e.printStackTrace();
            sendJson(response, 500, fail("Database error: " + e.getMessage()));
        }
    }

    private void save(HttpServletRequest request, HttpServletResponse response, Connection con, String user)
            throws Exception {
        String idParam = trim(request.getParameter("id"));
        String kind = trim(request.getParameter("kind"));
        String name = trim(request.getParameter("name")).replaceAll("\\s+", " ");
        String status = trim(request.getParameter("status"));

        boolean isNew = idParam.isEmpty();
        Map<String, String> old = null;
        if (!isNew) {
            if (!idParam.matches("\\d+")) { sendJson(response, 400, fail("Invalid entry.")); return; }
            old = one(con, Integer.parseInt(idParam));
            if (old == null) { sendJson(response, 404, fail("Entry not found. Please reload the page.")); return; }
            kind = old.get("kind");   // the type of an existing entry never changes
        }
        if (!ACTIVITY.equals(kind) && !PLACE.equals(kind)) { sendJson(response, 400, fail("Please choose the Type.")); return; }
        if (name.isEmpty()) { sendJson(response, 400, fail("Please enter the " + label(kind) + ".")); return; }
        if (name.length() > maxLength(kind)) {
            sendJson(response, 400, fail(label(kind) + " is too long (maximum " + maxLength(kind) + " characters)."));
            return;
        }
        if (!"Active".equals(status) && !"Inactive".equals(status)) { sendJson(response, 400, fail("Please choose the Status.")); return; }

        int id;
        int renamed = 0;
        try {
            if (isNew) {
                try (PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO kss_csr_activity_place (kind, name, status, created_by, updated_by) VALUES (?,?,?,?,?)",
                        Statement.RETURN_GENERATED_KEYS)) {
                    ps.setString(1, kind);
                    ps.setString(2, name);
                    ps.setString(3, status);
                    ps.setString(4, user);
                    ps.setString(5, user);
                    ps.executeUpdate();
                    try (ResultSet keys = ps.getGeneratedKeys()) { keys.next(); id = keys.getInt(1); }
                }
            } else {
                id = Integer.parseInt(idParam);
                String oldName = old.get("name");
                boolean nameChanged = !oldName.equals(name);
                con.setAutoCommit(false);
                try {
                    try (PreparedStatement ps = con.prepareStatement(
                            "UPDATE kss_csr_activity_place SET name=?, status=?, updated_by=? WHERE id=?")) {
                        ps.setString(1, name);
                        ps.setString(2, status);
                        ps.setString(3, user);
                        ps.setInt(4, id);
                        ps.executeUpdate();
                    }
                    // keep approvals in step with the new name (same transaction)
                    if (nameChanged) {
                        String col = letterColumn(kind);
                        try (PreparedStatement ps = con.prepareStatement(
                                "UPDATE kss_csr_approval_letter SET " + col + " = ?, updated_by = ? WHERE TRIM(" + col + ") = ?")) {
                            ps.setString(1, name);
                            ps.setString(2, user);
                            ps.setString(3, oldName);
                            renamed = ps.executeUpdate();
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
            sendJson(response, 409, fail(label(kind) + " \"" + name + "\" already exists."));
            return;
        }
        JsonObject json = new JsonObject();
        json.addProperty("ok", true);
        json.addProperty("id", id);
        json.addProperty("message", (isNew ? label(kind) + " added: " : label(kind) + " updated: ") + name
                + (renamed > 0 ? " (" + renamed + " Management Approval" + (renamed == 1 ? "" : "s") + " updated)" : ""));
        sendJson(response, 200, json);
    }

    private void delete(HttpServletRequest request, HttpServletResponse response, Connection con) throws Exception {
        String idParam = trim(request.getParameter("id"));
        if (!idParam.matches("\\d+")) { sendJson(response, 400, fail("Invalid entry.")); return; }
        Map<String, String> m = one(con, Integer.parseInt(idParam));
        if (m == null) { sendJson(response, 404, fail("Entry not found. Please reload the page.")); return; }
        int used = Integer.parseInt(m.get("letterCount"));
        if (used > 0) {
            sendJson(response, 409, fail("Cannot delete " + m.get("name") + ": " + used + " Management Approval"
                    + (used == 1 ? " uses" : "s use") + " it. Set it Inactive instead."));
            return;
        }
        try (PreparedStatement ps = con.prepareStatement("DELETE FROM kss_csr_activity_place WHERE id = ?")) {
            ps.setInt(1, Integer.parseInt(idParam));
            ps.executeUpdate();
        }
        JsonObject json = new JsonObject();
        json.addProperty("ok", true);
        json.addProperty("message", label(m.get("kind")) + " deleted: " + m.get("name"));
        sendJson(response, 200, json);
    }

    // ------------------------------------------------------------------ shared (Management Approval form)
    /**
     * Names for the approval form: Active entries of this kind, plus the value already on the approval
     * (even if Inactive or typed before this master existed), so an old approval can still be edited.
     */
    static List<String> loadChoices(Connection con, String kind, String keep) throws Exception {
        List<String> list = new ArrayList<>();
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT name FROM kss_csr_activity_place WHERE kind = ? AND (status = 'Active' OR name = ?) ORDER BY name")) {
            ps.setString(1, kind);
            ps.setString(2, keep == null ? "" : keep);
            try (ResultSet rs = ps.executeQuery()) { while (rs.next()) list.add(rs.getString(1)); }
        }
        if (keep != null && !keep.isEmpty()) {
            boolean found = false;
            for (String s : list) if (s.equals(keep)) { found = true; break; }   // exact, so the form can select it
            if (!found) list.add(0, keep);
        }
        return list;
    }

    /**
     * Checks a value chosen on the approval form. Returns null when it is allowed, else the message to show.
     * Allowed: an Active entry of this kind, or the value the approval already had (unchanged).
     */
    static String checkChoice(Connection con, String kind, String value, String oldValue) throws Exception {
        if (oldValue != null && trim(oldValue).equals(value)) return null;   // unchanged (old rows may have extra spaces)
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT status FROM kss_csr_activity_place WHERE kind = ? AND name = ?")) {
            ps.setString(1, kind);
            ps.setString(2, value);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return label(kind) + " \"" + value + "\" is not in Masters > CSR Activities & Places. Add it there first.";
                if (!"Active".equals(rs.getString(1))) return label(kind) + " \"" + value + "\" is Inactive. Choose another or make it Active in Masters.";
            }
        } catch (SQLSyntaxErrorException missing) {
            return "CSR Activities & Places master is not set up. " + SETUP_HINT;
        }
        return null;
    }

    private static Map<String, String> one(Connection con, int id) throws Exception {
        try (PreparedStatement ps = con.prepareStatement("SELECT " + COLUMNS + " FROM kss_csr_activity_place m WHERE m.id = ?")) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) { return rs.next() ? toMap(rs) : null; }
        }
    }

    private static Map<String, String> toMap(ResultSet rs) throws Exception {
        Map<String, String> r = new LinkedHashMap<>();
        r.put("id", String.valueOf(rs.getInt("id")));
        r.put("kind", rs.getString("kind"));
        r.put("name", rs.getString("name"));
        r.put("status", rs.getString("status"));
        r.put("createdBy", rs.getString("created_by"));
        r.put("createdAt", rs.getString("created_txt"));
        r.put("updatedBy", rs.getString("updated_by"));
        r.put("updatedAt", rs.getString("updated_txt"));
        r.put("letterCount", String.valueOf(rs.getInt("letter_count")));
        BigDecimal s = rs.getBigDecimal("sanctioned");
        r.put("sanctioned", s == null ? "0.00" : s.setScale(2, RoundingMode.HALF_UP).toPlainString());
        return r;
    }

    private static String trim(String s) { return s == null ? "" : s.replace('\u00A0', ' ').trim(); }

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
