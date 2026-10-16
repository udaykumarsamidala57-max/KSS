package com.Controller;

import java.io.IOException;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.sql.Types;
import java.time.LocalDateTime;
import java.time.ZoneId;
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
import com.DAO.scholarshipListDAO;
import com.google.gson.JsonObject;

/**
 * Step 3 : Approve Scholarship (Global role only).
 * Shows only applications whose 9 documents are ALL Verified (Step 2 done) and lets the
 * user Approve (with amount) / Reject (with reason) / Revert, saved with AJAX into
 * kss_scholarship_approval.
 */
@WebServlet("/ApproveScholarshipServlet")
public class ApproveScholarshipServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    /** SQL condition: all documents verified (alias a = kss_scholarship_approval). */
    private static String allVerifiedCondition() {
        StringBuilder sb = new StringBuilder("(");
        for (int i = 0; i < VerifyDocumentsServlet.DOCS.size(); i++) {
            if (i > 0) sb.append(" AND ");
            sb.append("a.").append(VerifyDocumentsServlet.DOCS.get(i)[0]).append("_status = 'Verified'");
        }
        return sb.append(")").toString();
    }

    private boolean isGlobal(HttpSession sess) {
        String role = (String) sess.getAttribute("role");
        return role != null && "Global".equalsIgnoreCase(role.replace(' ', ' ').strip());
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
        int waitingForVerification = 0;

        String sql = "SELECT s.id, s.App_no, s.org_name, s.emp_no, s.emp_name, s.children_name, "
                   + "s.college_name, s.course, s.present_year, s.KSS_courses, "
                   + "s.previous_ay_percentage, s.fee_amount_current_ay, s.actual_fee_paid, "
                   + "a.final_status, a.approved_amount, a.final_remarks, a.approved_by, "
                   + "DATE_FORMAT(a.approved_at, '%d-%m-%Y %H:%i') AS approved_at_txt, a.reimbursement_status "
                   + "FROM kss_student_scholarship s "
                   + "JOIN kss_scholarship_approval a ON a.scholarship_id = s.id "
                   + "WHERE TRIM(s.submiited) = 'Submitted' "
                   + "AND s.KSS_courses IS NOT NULL AND TRIM(s.KSS_courses) <> '' "
                   + "AND " + allVerifiedCondition() + " "
                   + "ORDER BY (a.final_status = 'Pending') DESC, TRIM(s.org_name), s.id DESC";

        try (Connection con = DBUtil.getConnection()) {
            VerifyDocumentsServlet.ensureDocColumns(con);

            try (PreparedStatement ps = con.prepareStatement(sql);
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
                    r.put("percentage", rs.getString("previous_ay_percentage"));
                    r.put("feeAmount", rs.getString("fee_amount_current_ay"));
                    r.put("actualFeePaid", rs.getString("actual_fee_paid"));
                    r.put("finalStatus", rs.getString("final_status"));
                    r.put("approvedAmount", rs.getString("approved_amount"));
                    r.put("finalRemarks", rs.getString("final_remarks"));
                    r.put("approvedBy", rs.getString("approved_by"));
                    r.put("approvedAt", rs.getString("approved_at_txt"));
                    r.put("reimbursementStatus", rs.getString("reimbursement_status"));
                    rows.add(r);
                }
            }

            // Applications that finished Step 1 but not all documents verified yet
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT COUNT(*) FROM kss_student_scholarship s "
                  + "LEFT JOIN kss_scholarship_approval a ON a.scholarship_id = s.id "
                  + "WHERE TRIM(s.submiited) = 'Submitted' AND s.KSS_courses IS NOT NULL AND TRIM(s.KSS_courses) <> '' "
                  + "AND (a.scholarship_id IS NULL OR NOT " + allVerifiedCondition() + ")");
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) waitingForVerification = rs.getInt(1);
            }

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Database error: " + e.getMessage()
                    + " (Has the kss_scholarship_approval table been created?)");
        }

        request.setAttribute("rows", rows);
        request.setAttribute("waitingForVerification", waitingForVerification);
        request.getRequestDispatcher("/approveScholarship.jsp").forward(request, response);
    }

    // ------------------------------------------------------------------ POST : approve / reject / revert (AJAX)
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            sendJson(response, HttpServletResponse.SC_UNAUTHORIZED, fail("Your session has expired. Please log in again."));
            return;
        }
        if (!isGlobal(sess)) {
            sendJson(response, HttpServletResponse.SC_FORBIDDEN, fail("Only Global users can approve scholarships."));
            return;
        }

        String user = (String) sess.getAttribute("username");
        String idParam = request.getParameter("id");
        String decision = request.getParameter("decision");     // Approved / Rejected / Pending (revert)
        String amountParam = request.getParameter("amount");
        String remarks = request.getParameter("remarks");
        remarks = remarks == null ? "" : remarks.trim();
        if (remarks.length() > 500) remarks = remarks.substring(0, 500);

        if (idParam == null || !idParam.trim().matches("\\d+")) {
            sendJson(response, HttpServletResponse.SC_BAD_REQUEST, fail("Invalid application."));
            return;
        }
        if (!"Approved".equals(decision) && !"Rejected".equals(decision) && !"Pending".equals(decision)) {
            sendJson(response, HttpServletResponse.SC_BAD_REQUEST, fail("Invalid decision."));
            return;
        }

        BigDecimal amount = null;
        if ("Approved".equals(decision)) {
            try {
                amount = new BigDecimal(amountParam == null ? "" : amountParam.trim().replace(",", ""));
            } catch (NumberFormatException e) {
                amount = null;
            }
            if (amount == null || amount.signum() <= 0 || amount.compareTo(new BigDecimal("9999999999")) > 0) {
                sendJson(response, HttpServletResponse.SC_BAD_REQUEST, fail("Please enter a valid approved amount."));
                return;
            }
            amount = amount.setScale(2, java.math.RoundingMode.HALF_UP);
        }
        if ("Rejected".equals(decision) && remarks.isEmpty()) {
            sendJson(response, HttpServletResponse.SC_BAD_REQUEST, fail("Please enter a reason for rejecting."));
            return;
        }

        int id = Integer.parseInt(idParam.trim());

        try (Connection con = DBUtil.getConnection()) {
            VerifyDocumentsServlet.ensureDocColumns(con);

            // Must be submitted, KSS course applied, all documents verified
            String appNo = null, empNo = null, empName = null, oldStatus = null, reimb = null;
            boolean found = false;
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT s.App_no, s.emp_no, s.emp_name, a.final_status, a.reimbursement_status "
                  + "FROM kss_student_scholarship s JOIN kss_scholarship_approval a ON a.scholarship_id = s.id "
                  + "WHERE s.id = ? AND TRIM(s.submiited) = 'Submitted' "
                  + "AND s.KSS_courses IS NOT NULL AND TRIM(s.KSS_courses) <> '' AND " + allVerifiedCondition())) {
                ps.setInt(1, id);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        found = true;
                        appNo = rs.getString("App_no");
                        empNo = rs.getString("emp_no");
                        empName = rs.getString("emp_name");
                        oldStatus = rs.getString("final_status");
                        reimb = rs.getString("reimbursement_status");
                    }
                }
            }

            if (!found) {
                sendJson(response, HttpServletResponse.SC_BAD_REQUEST,
                        fail("Application not found or not all documents are verified (Step 2)."));
                return;
            }
            if ("Reimbursed".equalsIgnoreCase(reimb)) {
                sendJson(response, HttpServletResponse.SC_CONFLICT,
                        fail("This scholarship is already reimbursed and cannot be changed."));
                return;
            }
            if (!"Pending".equals(decision) && !"Pending".equalsIgnoreCase(oldStatus)) {
                sendJson(response, HttpServletResponse.SC_CONFLICT,
                        fail("This application is already " + oldStatus + ". Revert it first to change the decision."));
                return;
            }

            Timestamp nowIst = Timestamp.valueOf(LocalDateTime.now(ZoneId.of("Asia/Kolkata")));
            String sql = "UPDATE kss_scholarship_approval SET final_status = ?, approved_amount = ?, final_remarks = ?, "
                       + "approved_by = ?, approved_at = ?, reimbursement_status = ? WHERE scholarship_id = ?";
            try (PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setString(1, decision);
                if (amount != null) ps.setBigDecimal(2, amount); else ps.setNull(2, Types.DECIMAL);
                ps.setString(3, remarks.isEmpty() ? null : remarks);
                if ("Pending".equals(decision)) {
                    ps.setNull(4, Types.VARCHAR);
                    ps.setNull(5, Types.TIMESTAMP);
                } else {
                    ps.setString(4, user);
                    ps.setTimestamp(5, nowIst);
                }
                ps.setString(6, "Approved".equals(decision) ? "Pending" : "Not Started");
                ps.setInt(7, id);
                ps.executeUpdate();
            }

            String detail = "Pending".equals(decision)
                    ? "Decision reverted from " + oldStatus + " to Pending" + (remarks.isEmpty() ? "" : " (" + remarks + ")")
                    : "Scholarship " + decision
                      + (amount != null ? ", amount " + amount.toPlainString() : "")
                      + (remarks.isEmpty() ? "" : " (" + remarks + ")");
            new scholarshipListDAO().logAudit(con, id, "APPROVAL", appNo, empNo, empName, user, detail);

            JsonObject json = new JsonObject();
            json.addProperty("ok", true);
            json.addProperty("message", "Pending".equals(decision)
                    ? "Decision reverted for " + appNo + "."
                    : "Scholarship " + decision.toLowerCase() + " for " + appNo + ".");
            json.addProperty("finalStatus", decision);
            json.addProperty("amount", amount == null ? null : amount.toPlainString());
            json.addProperty("remarks", remarks);
            json.addProperty("by", "Pending".equals(decision) ? null : user);
            json.addProperty("at", "Pending".equals(decision) ? null
                    : LocalDateTime.now(ZoneId.of("Asia/Kolkata")).format(java.time.format.DateTimeFormatter.ofPattern("dd-MM-yyyy HH:mm")));
            json.addProperty("reimbursementStatus", "Approved".equals(decision) ? "Pending" : "Not Started");
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
