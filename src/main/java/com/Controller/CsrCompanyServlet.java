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
 * Masters > Companies: the companies that fund CSR projects (Global only).
 * Each Management Approval belongs to one company; its FRLs are requests to that company
 * and its receipts are money received from it.
 *
 *   GET                 list (csrCompanies.jsp)
 *   GET ?action=form    add / edit form (csrCompanyForm.jsp)
 *   POST action=save    add / edit (AJAX, JSON)
 *   POST action=delete  delete (AJAX, JSON) - not allowed while an approval uses the company
 */
@WebServlet("/CsrCompanyServlet")
public class CsrCompanyServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    private static final String COLUMNS =
            "c.id, c.company_name, c.short_name, c.gstin, c.pan, c.contact_person, c.phone, c.email, c.address, c.status, "
          + "c.created_by, DATE_FORMAT(c.created_at, '%d-%m-%Y') AS created_txt, "
          + "c.updated_by, DATE_FORMAT(c.updated_at, '%d-%m-%Y %H:%i') AS updated_txt, "
          + "(SELECT COUNT(*) FROM kss_csr_approval_letter l WHERE l.company_id = c.id) AS letter_count, "
          + "(SELECT COALESCE(SUM(l.amount), 0) FROM kss_csr_approval_letter l WHERE l.company_id = c.id) AS sanctioned, "
          + "(SELECT COALESCE(SUM(r.amount), 0) FROM kss_csr_fund_request r JOIN kss_csr_approval_letter l ON l.id = r.letter_id "
          + " WHERE l.company_id = c.id) AS requested, "
          + "(SELECT COALESCE(SUM(f.amount), 0) FROM kss_csr_fund_receipt f JOIN kss_csr_approval_letter l ON l.id = f.letter_id "
          + " WHERE l.company_id = c.id) AS received";

    private static final String GSTIN_RE = "[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]";
    private static final String PAN_RE = "[A-Z]{5}[0-9]{4}[A-Z]";
    private static final String EMAIL_RE = "[^@\\s]+@[^@\\s]+\\.[^@\\s]+";
    private static final String PHONE_RE = "[0-9+\\- ]{6,20}";

    static boolean isGlobal(HttpSession sess) {
        String role = (String) sess.getAttribute("role");
        return role != null && "Global".equalsIgnoreCase(role.replace(' ', ' ').trim());
    }

    // ------------------------------------------------------------------ GET
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) { response.sendRedirect("login.jsp"); return; }
        if (!isGlobal(sess)) { response.sendRedirect("Dashboard.jsp"); return; }

        boolean form = "form".equals(request.getParameter("action"));
        String idParam = request.getParameter("id");
        List<Map<String, String>> rows = new ArrayList<>();
        Map<String, String> row = null;
        try (Connection con = DBUtil.getConnection()) {
            if (form) {
                if (idParam != null && idParam.matches("\\d+")) {
                    row = one(con, Integer.parseInt(idParam));
                    if (row == null) { response.sendRedirect("CsrCompanyServlet"); return; }
                }
            } else {
                try (PreparedStatement ps = con.prepareStatement(
                        "SELECT " + COLUMNS + " FROM kss_csr_company c ORDER BY c.status, c.company_name");
                     ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) rows.add(toMap(rs));
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Database error: " + e.getMessage()
                    + " (Has Dump20261016\\KSS_csr_company.sql been run?)");
        }
        if (form) {
            request.setAttribute("row", row);
            request.setAttribute("formReady", Boolean.TRUE);
            request.getRequestDispatcher("/csrCompanyForm.jsp").forward(request, response);
        } else {
            request.setAttribute("rows", rows);
            request.getRequestDispatcher("/csrCompanies.jsp").forward(request, response);
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
        if (!isGlobal(sess)) {
            sendJson(response, 403, fail("Only Global users can manage companies."));
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
        String name = trim(request.getParameter("companyName"));
        String shortName = trim(request.getParameter("shortName"));
        String gstin = trim(request.getParameter("gstin")).toUpperCase();
        String pan = trim(request.getParameter("pan")).toUpperCase();
        String contact = trim(request.getParameter("contactPerson"));
        String phone = trim(request.getParameter("phone"));
        String email = trim(request.getParameter("email"));
        String address = trim(request.getParameter("address"));
        String status = trim(request.getParameter("status"));

        if (name.isEmpty()) { sendJson(response, 400, fail("Please enter the Company Name.")); return; }
        if (name.length() > 200 || shortName.length() > 50 || contact.length() > 150 || email.length() > 150
                || address.length() > 500) {
            sendJson(response, 400, fail("One of the fields is too long."));
            return;
        }
        if (!gstin.isEmpty() && !gstin.matches(GSTIN_RE)) { sendJson(response, 400, fail("GSTIN is not valid (15 characters).")); return; }
        if (!pan.isEmpty() && !pan.matches(PAN_RE)) { sendJson(response, 400, fail("PAN is not valid (10 characters).")); return; }
        if (!gstin.isEmpty() && !pan.isEmpty() && !gstin.substring(2, 12).equals(pan)) {
            sendJson(response, 400, fail("PAN does not match the PAN inside the GSTIN."));
            return;
        }
        if (!phone.isEmpty() && !phone.matches(PHONE_RE)) { sendJson(response, 400, fail("Phone number is not valid.")); return; }
        if (!email.isEmpty() && !email.matches(EMAIL_RE)) { sendJson(response, 400, fail("Email is not valid.")); return; }
        if (!"Active".equals(status) && !"Inactive".equals(status)) { sendJson(response, 400, fail("Please choose the Status.")); return; }

        boolean isNew = idParam.isEmpty();
        int id;
        try {
            if (isNew) {
                try (PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO kss_csr_company (company_name, short_name, gstin, pan, contact_person, phone, email, "
                      + "address, status, created_by, updated_by) VALUES (?,?,?,?,?,?,?,?,?,?,?)",
                        Statement.RETURN_GENERATED_KEYS)) {
                    bind(ps, name, shortName, gstin, pan, contact, phone, email, address, status);
                    ps.setString(10, user);
                    ps.setString(11, user);
                    ps.executeUpdate();
                    try (ResultSet keys = ps.getGeneratedKeys()) { keys.next(); id = keys.getInt(1); }
                }
            } else {
                if (!idParam.matches("\\d+")) { sendJson(response, 400, fail("Invalid company.")); return; }
                id = Integer.parseInt(idParam);
                try (PreparedStatement ps = con.prepareStatement(
                        "UPDATE kss_csr_company SET company_name=?, short_name=?, gstin=?, pan=?, contact_person=?, phone=?, "
                      + "email=?, address=?, status=?, updated_by=? WHERE id=?")) {
                    bind(ps, name, shortName, gstin, pan, contact, phone, email, address, status);
                    ps.setString(10, user);
                    ps.setInt(11, id);
                    if (ps.executeUpdate() == 0) { sendJson(response, 404, fail("Company not found. Please reload the page.")); return; }
                }
            }
        } catch (SQLIntegrityConstraintViolationException dup) {
            sendJson(response, 409, fail("Company \"" + name + "\" already exists."));
            return;
        }
        JsonObject json = new JsonObject();
        json.addProperty("ok", true);
        json.addProperty("id", id);
        json.addProperty("message", (isNew ? "Company added: " : "Company updated: ") + name);
        sendJson(response, 200, json);
    }

    private void delete(HttpServletRequest request, HttpServletResponse response, Connection con) throws Exception {
        String idParam = trim(request.getParameter("id"));
        if (!idParam.matches("\\d+")) { sendJson(response, 400, fail("Invalid company.")); return; }
        Map<String, String> c = one(con, Integer.parseInt(idParam));
        if (c == null) { sendJson(response, 404, fail("Company not found. Please reload the page.")); return; }
        int used = Integer.parseInt(c.get("letterCount"));
        if (used > 0) {
            sendJson(response, 409, fail("Cannot delete " + c.get("companyName") + ": " + used + " Management Approval"
                    + (used == 1 ? " is" : "s are") + " funded by it. Set it Inactive instead."));
            return;
        }
        try (PreparedStatement ps = con.prepareStatement("DELETE FROM kss_csr_company WHERE id = ?")) {
            ps.setInt(1, Integer.parseInt(idParam));
            ps.executeUpdate();
        }
        JsonObject json = new JsonObject();
        json.addProperty("ok", true);
        json.addProperty("message", "Company deleted: " + c.get("companyName"));
        sendJson(response, 200, json);
    }

    // ------------------------------------------------------------------ shared
    /** Companies for the Management Approval form: Active ones, plus the one already on the letter (even if Inactive). */
    static List<Map<String, String>> loadChoices(Connection con, String keepId) throws Exception {
        List<Map<String, String>> list = new ArrayList<>();
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT id, company_name, short_name, status FROM kss_csr_company "
              + "WHERE status = 'Active' OR id = ? ORDER BY company_name")) {
            ps.setInt(1, keepId != null && keepId.matches("\\d+") ? Integer.parseInt(keepId) : -1);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, String> m = new LinkedHashMap<>();
                    m.put("id", String.valueOf(rs.getInt("id")));
                    m.put("companyName", rs.getString("company_name"));
                    m.put("shortName", rs.getString("short_name"));
                    m.put("status", rs.getString("status"));
                    list.add(m);
                }
            }
        }
        return list;
    }

    /** SQL for the company name of a letter alias: short name when given, else full name. */
    static String nameOf(String letterAlias) {
        return "(SELECT COALESCE(NULLIF(c.short_name, ''), c.company_name) FROM kss_csr_company c WHERE c.id = "
             + letterAlias + ".company_id)";
    }

    private static Map<String, String> one(Connection con, int id) throws Exception {
        try (PreparedStatement ps = con.prepareStatement("SELECT " + COLUMNS + " FROM kss_csr_company c WHERE c.id = ?")) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) { return rs.next() ? toMap(rs) : null; }
        }
    }

    private static void bind(PreparedStatement ps, String name, String shortName, String gstin, String pan,
                             String contact, String phone, String email, String address, String status) throws Exception {
        ps.setString(1, name);
        ps.setString(2, nul(shortName));
        ps.setString(3, nul(gstin));
        ps.setString(4, nul(pan));
        ps.setString(5, nul(contact));
        ps.setString(6, nul(phone));
        ps.setString(7, nul(email));
        ps.setString(8, nul(address));
        ps.setString(9, status);
    }

    private static Map<String, String> toMap(ResultSet rs) throws Exception {
        Map<String, String> r = new LinkedHashMap<>();
        r.put("id", String.valueOf(rs.getInt("id")));
        r.put("companyName", rs.getString("company_name"));
        r.put("shortName", rs.getString("short_name"));
        r.put("gstin", rs.getString("gstin"));
        r.put("pan", rs.getString("pan"));
        r.put("contactPerson", rs.getString("contact_person"));
        r.put("phone", rs.getString("phone"));
        r.put("email", rs.getString("email"));
        r.put("address", rs.getString("address"));
        r.put("status", rs.getString("status"));
        r.put("createdBy", rs.getString("created_by"));
        r.put("createdAt", rs.getString("created_txt"));
        r.put("updatedBy", rs.getString("updated_by"));
        r.put("updatedAt", rs.getString("updated_txt"));
        r.put("letterCount", String.valueOf(rs.getInt("letter_count")));
        r.put("sanctioned", money2(rs.getBigDecimal("sanctioned")));
        r.put("requested", money2(rs.getBigDecimal("requested")));
        r.put("received", money2(rs.getBigDecimal("received")));
        return r;
    }

    private static String money2(BigDecimal v) {
        return v == null ? "0.00" : v.setScale(2, RoundingMode.HALF_UP).toPlainString();
    }

    private static String nul(String s) { return s == null || s.isEmpty() ? null : s; }

    private static String trim(String s) { return s == null ? "" : s.replace(' ', ' ').trim(); }

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
