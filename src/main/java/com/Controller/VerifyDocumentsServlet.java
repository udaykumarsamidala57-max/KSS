package com.Controller;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.time.ZoneId;
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
import com.DAO.scholarshipListDAO;
import com.google.gson.JsonObject;

/**
 * Step 2 : Verify Documents (Global role only).
 * Lists submitted applications that already have a KSS course (Step 1 done) and lets
 * the user verify / reject each document. Every click is saved with AJAX into
 * kss_scholarship_approval (one row per application).
 */
@WebServlet("/VerifyDocumentsServlet")
public class VerifyDocumentsServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    /**
     * Documents to verify:
     * { key (= column prefix in kss_scholarship_approval), label, BLOB column in kss_student_scholarship,
     *   field name used by ScholarshipDocumentDownloadServlet }
     */
    public static final List<String[]> DOCS = Arrays.asList(
        new String[]{"marks_card",       "Previous AY Marks Card",    "previous_ay_marks_card",   "previousAyMarksCard"},
        new String[]{"kss_application",  "KSS Application",           "kss_application",          "kssApplication"},
        new String[]{"fee_structure",    "Fee Structure",             "fee_structure",            "feeStructure"},
        new String[]{"fee_receipts",     "Fee Receipts",              "fee_receipts",             "feeReceipts"},
        new String[]{"parent_aadhar",    "Parent Identity Document",  "parent_aadhar_copy",       "parentAadharCopy"},
        new String[]{"student_aadhar",   "Student Identity Document", "student_aadhar_copy",      "studentAadharCopy"},
        new String[]{"bank_passbook",    "Bank Passbook First Page",  "bank_passbook_first_page", "bankPassbookFirstPage"},
        new String[]{"parent_id_proof",  "Parent Identity Proof",     "parent_aadhar",            "parentAadhar"},
        new String[]{"student_id_proof", "Student Identity Proof",    "student_aadhar",           "studentAadhar"}
    );

    private static volatile boolean columnsChecked = false;

    /**
     * Makes sure kss_scholarship_approval has a _status / _remarks column for every
     * document in DOCS (for example after new documents were added to the list).
     * Only ADDS missing columns, never drops or changes data. Runs once per app start.
     */
    public static void ensureDocColumns(Connection con) throws java.sql.SQLException {
        if (columnsChecked) return;
        synchronized (VerifyDocumentsServlet.class) {
            if (columnsChecked) return;
            java.util.Set<String> existing = new java.util.HashSet<>();
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT COLUMN_NAME FROM information_schema.COLUMNS "
                  + "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'kss_scholarship_approval'");
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) existing.add(rs.getString(1).toLowerCase());
            }
            if (existing.isEmpty()) {
                return;   // table not created yet; the page shows the database error
            }
            String after = null;
            for (String[] d : DOCS) {
                String st = d[0] + "_status", rm = d[0] + "_remarks";
                if (!existing.contains(st)) {
                    try (PreparedStatement ps = con.prepareStatement(
                            "ALTER TABLE kss_scholarship_approval "
                          + "ADD COLUMN " + st + " ENUM('Pending','Verified','Rejected') NOT NULL DEFAULT 'Pending'"
                          + (after != null ? " AFTER " + after : "") + ", "
                          + "ADD COLUMN " + rm + " VARCHAR(300) DEFAULT NULL AFTER " + st)) {
                        ps.executeUpdate();
                    }
                    existing.add(st);
                    existing.add(rm);
                }
                after = existing.contains(rm) ? rm : st;
            }
            columnsChecked = true;
        }
    }

    private static String[] findDoc(String key) {
        for (String[] d : DOCS) {
            if (d[0].equals(key)) return d;
        }
        return null;
    }

    private boolean isGlobal(HttpSession sess) {
        String role = (String) sess.getAttribute("role");
        return role != null && "Global".equalsIgnoreCase(role.replace('\u00A0', ' ').strip());
    }

    // ------------------------------------------------------------------ GET : load page
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
        int waitingForKssCourse = 0;

        StringBuilder sql = new StringBuilder();
        sql.append("SELECT s.id, s.App_no, s.org_name, s.emp_no, s.emp_name, s.children_name, ")
           .append("s.college_name, s.course, s.present_year, s.KSS_courses, a.final_status, ");
        for (String[] d : DOCS) {
            // Only the size of each file, never the file itself
            sql.append("(OCTET_LENGTH(s.").append(d[2]).append(") > 0) AS has_").append(d[0]).append(", ")
               .append("a.").append(d[0]).append("_status AS st_").append(d[0]).append(", ")
               .append("a.").append(d[0]).append("_remarks AS rm_").append(d[0]).append(", ");
        }
        sql.append("a.docs_verified_by, a.docs_verified_at ")
           .append("FROM kss_student_scholarship s ")
           .append("LEFT JOIN kss_scholarship_approval a ON a.scholarship_id = s.id ")
           .append("WHERE TRIM(s.submiited) = 'Submitted' ")
           .append("AND s.KSS_courses IS NOT NULL AND TRIM(s.KSS_courses) <> '' ")
           .append("ORDER BY TRIM(s.org_name), s.id DESC");

        try (Connection con = DBUtil.getConnection()) {
            ensureDocColumns(con);

            try (PreparedStatement ps = con.prepareStatement(sql.toString());
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
                    r.put("finalStatus", rs.getString("final_status"));
                    r.put("verifiedBy", rs.getString("docs_verified_by"));
                    r.put("verifiedAt", rs.getString("docs_verified_at"));
                    for (String[] d : DOCS) {
                        r.put("has_" + d[0], rs.getInt("has_" + d[0]) == 1 ? "1" : "0");
                        String st = rs.getString("st_" + d[0]);
                        r.put("st_" + d[0], st == null ? "Pending" : st);
                        r.put("rm_" + d[0], rs.getString("rm_" + d[0]));
                    }
                    rows.add(r);
                }
            }

            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT COUNT(*) FROM kss_student_scholarship WHERE TRIM(submiited) = 'Submitted' "
                  + "AND (KSS_courses IS NULL OR TRIM(KSS_courses) = '')");
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) waitingForKssCourse = rs.getInt(1);
            }

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Database error: " + e.getMessage()
                    + " (Has the kss_scholarship_approval table been created?)");
        }

        request.setAttribute("rows", rows);
        request.setAttribute("docs", DOCS);
        request.setAttribute("waitingForKssCourse", waitingForKssCourse);
        request.getRequestDispatcher("/verifyDocuments.jsp").forward(request, response);
    }

    // ------------------------------------------------------------------ POST : verify / reject one document (AJAX)
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            sendJson(response, HttpServletResponse.SC_UNAUTHORIZED, fail("Your session has expired. Please log in again."));
            return;
        }
        if (!isGlobal(sess)) {
            sendJson(response, HttpServletResponse.SC_FORBIDDEN, fail("Only Global users can verify documents."));
            return;
        }

        String user = (String) sess.getAttribute("username");
        String idParam = request.getParameter("id");
        String docKey = request.getParameter("doc");
        String status = request.getParameter("status");
        String remarks = request.getParameter("remarks");
        remarks = remarks == null ? "" : remarks.trim();

        String[] doc = findDoc(docKey);
        if (idParam == null || !idParam.trim().matches("\\d+") || doc == null) {
            sendJson(response, HttpServletResponse.SC_BAD_REQUEST, fail("Invalid request."));
            return;
        }
        if (!"Verified".equals(status) && !"Rejected".equals(status) && !"Pending".equals(status)) {
            sendJson(response, HttpServletResponse.SC_BAD_REQUEST, fail("Invalid status."));
            return;
        }
        if ("Rejected".equals(status) && remarks.isEmpty()) {
            sendJson(response, HttpServletResponse.SC_BAD_REQUEST, fail("Please enter a reason for rejecting."));
            return;
        }
        if (remarks.length() > 300) remarks = remarks.substring(0, 300);
        if (!"Rejected".equals(status)) remarks = "";   // remarks only kept for rejections

        int id = Integer.parseInt(idParam.trim());
        String col = doc[0];   // whitelisted column prefix

        try (Connection con = DBUtil.getConnection()) {
            ensureDocColumns(con);

            // Application must be submitted, have a KSS course, and not be finally decided yet
            String appNo = null, empNo = null, empName = null, finalStatus = null;
            boolean hasFile = false, found = false;
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT s.App_no, s.emp_no, s.emp_name, (OCTET_LENGTH(s." + doc[2] + ") > 0) AS has_file, "
                  + "a.final_status FROM kss_student_scholarship s "
                  + "LEFT JOIN kss_scholarship_approval a ON a.scholarship_id = s.id "
                  + "WHERE s.id = ? AND TRIM(s.submiited) = 'Submitted' "
                  + "AND s.KSS_courses IS NOT NULL AND TRIM(s.KSS_courses) <> ''")) {
                ps.setInt(1, id);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        found = true;
                        appNo = rs.getString("App_no");
                        empNo = rs.getString("emp_no");
                        empName = rs.getString("emp_name");
                        hasFile = rs.getInt("has_file") == 1;
                        finalStatus = rs.getString("final_status");
                    }
                }
            }

            if (!found) {
                sendJson(response, HttpServletResponse.SC_BAD_REQUEST,
                        fail("Application not found, not submitted, or KSS course not applied (Step 1)."));
                return;
            }
            if (finalStatus != null && !"Pending".equalsIgnoreCase(finalStatus)) {
                sendJson(response, HttpServletResponse.SC_CONFLICT,
                        fail("This application is already " + finalStatus + ". Documents are locked."));
                return;
            }
            if ("Verified".equals(status) && !hasFile) {
                sendJson(response, HttpServletResponse.SC_BAD_REQUEST,
                        fail("This document was not uploaded, so it cannot be verified."));
                return;
            }

            // Insert the approval row if it does not exist yet, otherwise update this document only
            String upsert = "INSERT INTO kss_scholarship_approval "
                    + "(scholarship_id, app_no, " + col + "_status, " + col + "_remarks, docs_verified_by, docs_verified_at) "
                    + "VALUES (?, ?, ?, ?, ?, ?) "
                    + "ON DUPLICATE KEY UPDATE "
                    + col + "_status = VALUES(" + col + "_status), "
                    + col + "_remarks = VALUES(" + col + "_remarks), "
                    + "docs_verified_by = VALUES(docs_verified_by), "
                    + "docs_verified_at = VALUES(docs_verified_at)";
            try (PreparedStatement ps = con.prepareStatement(upsert)) {
                ps.setInt(1, id);
                ps.setString(2, appNo);
                ps.setString(3, status);
                ps.setString(4, remarks.isEmpty() ? null : remarks);
                ps.setString(5, user);
                ps.setTimestamp(6, Timestamp.valueOf(LocalDateTime.now(ZoneId.of("Asia/Kolkata"))));  // IST, like the audit table
                ps.executeUpdate();
            }

            new scholarshipListDAO().logAudit(con, id, "DOC_VERIFY", appNo, empNo, empName, user,
                    doc[1] + ": " + status + (remarks.isEmpty() ? "" : " (" + remarks + ")"));

            // Return the new summary for this application
            int verified = 0, rejected = 0, pending = 0;
            StringBuilder q = new StringBuilder("SELECT ");
            for (int i = 0; i < DOCS.size(); i++) {
                q.append(i == 0 ? "" : ", ").append(DOCS.get(i)[0]).append("_status");
            }
            q.append(", DATE_FORMAT(docs_verified_at, '%d-%m-%Y %H:%i') AS at_txt FROM kss_scholarship_approval WHERE scholarship_id = ?");
            String atTxt = null;
            try (PreparedStatement ps = con.prepareStatement(q.toString())) {
                ps.setInt(1, id);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        for (String[] d : DOCS) {
                            String st = rs.getString(d[0] + "_status");
                            if ("Verified".equals(st)) verified++;
                            else if ("Rejected".equals(st)) rejected++;
                            else pending++;
                        }
                        atTxt = rs.getString("at_txt");
                    }
                }
            }

            JsonObject json = new JsonObject();
            json.addProperty("ok", true);
            json.addProperty("message", doc[1] + " marked " + status + " for " + (appNo != null ? appNo : "ID " + id) + ".");
            json.addProperty("doc", col);
            json.addProperty("status", status);
            json.addProperty("remarks", remarks);
            json.addProperty("verified", verified);
            json.addProperty("rejected", rejected);
            json.addProperty("pending", pending);
            json.addProperty("total", DOCS.size());
            json.addProperty("docsStatus", rejected > 0 ? "Has Rejected" : (verified == DOCS.size() ? "All Verified" : "Pending"));
            json.addProperty("verifiedBy", user);
            json.addProperty("verifiedAt", atTxt);
            sendJson(response, HttpServletResponse.SC_OK, json);

        } catch (Exception e) {
            e.printStackTrace();
            sendJson(response, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, fail("Database error: " + e.getMessage()));
        }
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
