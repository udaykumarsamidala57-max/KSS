package com.Controller;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.servlet.http.Part;

import com.Bean.DBUtil;
import com.google.gson.JsonObject;

/**
 * KSS CSR Amount Spending : Fund Receipts against Funds Request Letters (Global role only).
 * Approval Letter -> FRLs -> Fund Receipts. An FRL can receive funds many times;
 * the total received against an FRL may not exceed the amount requested in it.
 *
 *  GET  CsrFundServlet[?letterId=N]                    -> list page (csrFunds.jsp)
 *  GET  CsrFundServlet?action=form[&id=N|&frlId=N]     -> add / edit form (csrFundForm.jsp)
 *  GET  CsrFundServlet?action=file&id=N                -> open the attachment
 *  POST action=save   (multipart, AJAX)                -> add / update
 *  POST action=delete (AJAX)                           -> delete
 */
@WebServlet("/CsrFundServlet")
@MultipartConfig(maxFileSize = 10 * 1024 * 1024, maxRequestSize = 12 * 1024 * 1024)
public class CsrFundServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private static final int MAX_FILE_BYTES = 10 * 1024 * 1024;
    private static final char NBSP = (char) 160;
    public static final List<String> MODES = Arrays.asList("NEFT", "RTGS", "IMPS", "UPI", "Cheque", "DD", "Cash", "Other");

    private static final String FUND_COLUMNS =
            "f.id, f.letter_id, f.frl_id, r.frl_number, DATE_FORMAT(f.receipt_date, '%Y-%m-%d') AS rdate_iso, "
          + "DATE_FORMAT(f.receipt_date, '%d-%m-%Y') AS rdate_txt, f.amount, f.payment_mode, f.reference_no, f.bank_name, "
          + "f.remarks, f.attachment_name, f.attachment_size, f.created_by, DATE_FORMAT(f.created_at, '%d-%m-%Y') AS created_txt, "
          + "l.letter_number, l.letter_name, l.activity_kind, l.amount AS letter_amount, l.company_id, "
          + CsrCompanyServlet.nameOf("l") + " AS company_name";

    private static final String FUND_FROM =
            " FROM kss_csr_fund_receipt f JOIN kss_csr_approval_letter l ON l.id = f.letter_id"
          + " LEFT JOIN kss_csr_fund_request r ON r.id = f.frl_id";

    private boolean isGlobal(HttpSession sess) {
        String role = (String) sess.getAttribute("role");
        return role != null && "Global".equalsIgnoreCase(role.replace(NBSP, ' ').trim());
    }

    // ================================================================== GET
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

        String action = request.getParameter("action");
        if ("file".equals(action)) {
            streamFile(request, response);
            return;
        }

        String letterParam = request.getParameter("letterId");
        String presetLetter = letterParam != null && letterParam.matches("\\d+") ? letterParam : "";
        List<Map<String, String>> letters = new ArrayList<>();

        if ("form".equals(action)) {
            String idParam = request.getParameter("id");
            String frlParam = request.getParameter("frlId");
            List<Map<String, String>> frls = new ArrayList<>();
            Map<String, String> fund = null;
            try (Connection con = DBUtil.getConnection()) {
                if (idParam != null && idParam.matches("\\d+")) {
                    try (PreparedStatement ps = con.prepareStatement("SELECT " + FUND_COLUMNS + FUND_FROM + " WHERE f.id = ?")) {
                        ps.setInt(1, Integer.parseInt(idParam));
                        try (ResultSet rs = ps.executeQuery()) { if (rs.next()) fund = fundMap(rs); }
                    }
                    if (fund == null) {
                        response.sendRedirect("CsrFundServlet");
                        return;
                    }
                }
                frls = CsrFrlServlet.loadFrls(con);
            } catch (Exception e) {
                e.printStackTrace();
                request.setAttribute("error", "Database error: " + e.getMessage()
                        + " (Have the kss_csr_fund_receipt and kss_csr_fund_request tables been created?)");
            }
            request.setAttribute("fund", fund);
            request.setAttribute("frls", frls);
            request.setAttribute("presetFrlId", frlParam != null && frlParam.matches("\\d+") ? frlParam : "");
            request.setAttribute("modes", MODES);
            request.setAttribute("presetLetterId", presetLetter);
            request.getRequestDispatcher("/csrFundForm.jsp").forward(request, response);
            return;
        }

        // ---- list
        List<Map<String, String>> rows = new ArrayList<>();
        try (Connection con = DBUtil.getConnection()) {
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT " + FUND_COLUMNS + FUND_FROM + " ORDER BY f.receipt_date DESC, f.id DESC");
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) rows.add(fundMap(rs));
            }
            letters = loadLetters(con);
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Database error: " + e.getMessage()
                    + " (Has the kss_csr_fund_receipt table been created?)");
        }
        request.setAttribute("rows", rows);
        request.setAttribute("letters", letters);
        request.setAttribute("letterFilter", presetLetter);
        request.getRequestDispatcher("/csrFunds.jsp").forward(request, response);
    }

    private void streamFile(HttpServletRequest request, HttpServletResponse response) throws IOException {
        String idParam = request.getParameter("id");
        if (idParam == null || !idParam.matches("\\d+")) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid receipt.");
            return;
        }
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(
                     "SELECT id, attachment, attachment_name, attachment_type FROM kss_csr_fund_receipt WHERE id = ?")) {
            ps.setInt(1, Integer.parseInt(idParam));
            try (ResultSet rs = ps.executeQuery()) {
                byte[] data = rs.next() ? rs.getBytes("attachment") : null;
                if (data == null) {
                    response.sendError(HttpServletResponse.SC_NOT_FOUND, "Attachment not found.");
                    return;
                }
                String type = rs.getString("attachment_type");
                String name = rs.getString("attachment_name");
                if (name == null || name.trim().isEmpty()) name = "FundReceipt_" + rs.getInt("id");
                name = name.replaceAll("[^A-Za-z0-9._-]", "_");
                response.setContentType(type == null ? "application/octet-stream" : type);
                response.setContentLength(data.length);
                response.setHeader("Content-Disposition", "inline; filename=\"" + name + "\"");
                response.getOutputStream().write(data);
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Could not open the attachment.");
        }
    }

    // ================================================================== POST (AJAX)
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            sendJson(response, 401, fail("Your session has expired. Please log in again."));
            return;
        }
        if (!isGlobal(sess)) {
            sendJson(response, 403, fail("Only Global users can manage fund receipts."));
            return;
        }
        String user = (String) sess.getAttribute("username");

        try (Connection con = DBUtil.getConnection()) {
            String action = request.getParameter("action");
            if ("save".equals(action)) {
                save(request, response, con, user);
            } else if ("delete".equals(action)) {
                delete(request, response, con);
            } else {
                sendJson(response, 400, fail("Unknown action."));
            }
        } catch (IllegalStateException tooBig) {
            sendJson(response, 400, fail("The attachment is too large (maximum 10 MB)."));
        } catch (Exception e) {
            e.printStackTrace();
            sendJson(response, 500, fail("Database error: " + e.getMessage()));
        }
    }

    private void save(HttpServletRequest request, HttpServletResponse response, Connection con, String user) throws Exception {
        String idParam = trim(request.getParameter("id"));
        String frlParam = trim(request.getParameter("frlId"));
        String rDate = trim(request.getParameter("receiptDate"));
        String amountS = trim(request.getParameter("amount"));
        String mode = trim(request.getParameter("paymentMode"));
        String refNo = trim(request.getParameter("referenceNo"));
        String bank = trim(request.getParameter("bankName"));
        String remarks = trim(request.getParameter("remarks"));

        if (!frlParam.matches("\\d+")) { sendJson(response, 400, fail("Please select the Funds Request Letter.")); return; }
        LocalDate date;
        try {
            date = LocalDate.parse(rDate);
        } catch (Exception e) {
            sendJson(response, 400, fail("Please enter a valid Receipt Date."));
            return;
        }
        BigDecimal amount;
        try {
            amount = new BigDecimal(amountS.replace(",", ""));
        } catch (NumberFormatException e) {
            amount = null;
        }
        if (amount == null || amount.signum() <= 0 || amount.compareTo(new BigDecimal("999999999999")) > 0) {
            sendJson(response, 400, fail("Please enter a valid Amount."));
            return;
        }
        amount = amount.setScale(2, RoundingMode.HALF_UP);
        if (!MODES.contains(mode)) { sendJson(response, 400, fail("Please select the Payment Mode.")); return; }
        if (refNo.length() > 100 || bank.length() > 150 || remarks.length() > 500) {
            sendJson(response, 400, fail("One of the fields is too long."));
            return;
        }

        // ---- attachment (optional)
        byte[] file = null;
        String fileName = null, fileType = null;
        Part part = request.getPart("attachment");
        if (part != null && part.getSize() > 0) {
            if (part.getSize() > MAX_FILE_BYTES) { sendJson(response, 400, fail("The attachment is too large (maximum 10 MB).")); return; }
            file = readAll(part.getInputStream());
            fileType = detectType(file);
            if (fileType == null) { sendJson(response, 400, fail("Attachment must be a PDF, JPG or PNG file.")); return; }
            fileName = part.getSubmittedFileName();
            if (fileName != null) fileName = fileName.replaceAll("^.*[\\\\/]", "");
            if (fileName != null && fileName.length() > 255) fileName = fileName.substring(fileName.length() - 255);
        }

        boolean isNew = idParam.isEmpty();
        if (!isNew && !idParam.matches("\\d+")) { sendJson(response, 400, fail("Invalid receipt.")); return; }
        int frlId = Integer.parseInt(frlParam);
        int id = isNew ? 0 : Integer.parseInt(idParam);

        // ---- total received against an FRL must not exceed the amount requested in it
        BigDecimal requested = null;
        int letterId = 0;
        String frlNumber = null;
        try (PreparedStatement ps = con.prepareStatement("SELECT amount, letter_id, frl_number FROM kss_csr_fund_request WHERE id = ?")) {
            ps.setInt(1, frlId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) { requested = rs.getBigDecimal(1); letterId = rs.getInt(2); frlNumber = rs.getString(3); }
            }
        }
        if (requested == null) { sendJson(response, 400, fail("Funds request letter not found. Please reload the page.")); return; }
        BigDecimal others;
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT COALESCE(SUM(amount), 0) FROM kss_csr_fund_receipt WHERE frl_id = ? AND id <> ?")) {
            ps.setInt(1, frlId);
            ps.setInt(2, id);
            try (ResultSet rs = ps.executeQuery()) { rs.next(); others = rs.getBigDecimal(1); }
        }
        BigDecimal pending = requested.subtract(others);
        if (amount.compareTo(pending) > 0) {
            sendJson(response, 400, fail("Amount Rs " + amount.toPlainString() + " is more than the Rs "
                    + pending.setScale(2, RoundingMode.HALF_UP).toPlainString() + " yet to be received against FRL " + frlNumber + "."));
            return;
        }

        if (isNew) {
            try (PreparedStatement ps = con.prepareStatement(
                    "INSERT INTO kss_csr_fund_receipt (letter_id, frl_id, receipt_date, amount, payment_mode, reference_no, bank_name, remarks, "
                  + "attachment, attachment_name, attachment_type, attachment_size, created_by, updated_by) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
                    Statement.RETURN_GENERATED_KEYS)) {
                int i = 1;
                ps.setInt(i++, letterId);
                ps.setInt(i++, frlId);
                ps.setDate(i++, Date.valueOf(date));
                ps.setBigDecimal(i++, amount);
                ps.setString(i++, mode);
                ps.setString(i++, emptyToNull(refNo));
                ps.setString(i++, emptyToNull(bank));
                ps.setString(i++, emptyToNull(remarks));
                ps.setBytes(i++, file);
                ps.setString(i++, fileName);
                ps.setString(i++, fileType);
                if (file == null) ps.setNull(i++, java.sql.Types.INTEGER); else ps.setInt(i++, file.length);
                ps.setString(i++, user);
                ps.setString(i, user);
                ps.executeUpdate();
                try (ResultSet keys = ps.getGeneratedKeys()) { keys.next(); id = keys.getInt(1); }
            }
        } else {
            String sql = "UPDATE kss_csr_fund_receipt SET letter_id=?, frl_id=?, receipt_date=?, amount=?, payment_mode=?, reference_no=?, "
                       + "bank_name=?, remarks=?, updated_by=?"
                       + (file != null ? ", attachment=?, attachment_name=?, attachment_type=?, attachment_size=?" : "")
                       + " WHERE id=?";
            try (PreparedStatement ps = con.prepareStatement(sql)) {
                int i = 1;
                ps.setInt(i++, letterId);
                ps.setInt(i++, frlId);
                ps.setDate(i++, Date.valueOf(date));
                ps.setBigDecimal(i++, amount);
                ps.setString(i++, mode);
                ps.setString(i++, emptyToNull(refNo));
                ps.setString(i++, emptyToNull(bank));
                ps.setString(i++, emptyToNull(remarks));
                ps.setString(i++, user);
                if (file != null) {
                    ps.setBytes(i++, file);
                    ps.setString(i++, fileName);
                    ps.setString(i++, fileType);
                    ps.setInt(i++, file.length);
                }
                ps.setInt(i, id);
                if (ps.executeUpdate() == 0) {
                    sendJson(response, 404, fail("Receipt not found. Please reload the page."));
                    return;
                }
            }
        }

        JsonObject json = new JsonObject();
        json.addProperty("ok", true);
        json.addProperty("id", id);
        json.addProperty("message", (isNew ? "Fund receipt added: Rs " : "Fund receipt updated: Rs ") + amount.toPlainString()
                + " against FRL " + frlNumber);
        sendJson(response, 200, json);
    }

    private void delete(HttpServletRequest request, HttpServletResponse response, Connection con) throws Exception {
        String idParam = trim(request.getParameter("id"));
        if (!idParam.matches("\\d+")) { sendJson(response, 400, fail("Invalid receipt.")); return; }
        int id = Integer.parseInt(idParam);
        String info = null;
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT CONCAT('Rs ', f.amount, ' for ', l.letter_number) FROM kss_csr_fund_receipt f "
              + "JOIN kss_csr_approval_letter l ON l.id = f.letter_id WHERE f.id = ?")) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) { if (rs.next()) info = rs.getString(1); }
        }
        if (info == null) { sendJson(response, 404, fail("Receipt not found. Please reload the page.")); return; }
        try (PreparedStatement ps = con.prepareStatement("DELETE FROM kss_csr_fund_receipt WHERE id = ?")) {
            ps.setInt(1, id);
            ps.executeUpdate();
        }
        JsonObject json = new JsonObject();
        json.addProperty("ok", true);
        json.addProperty("id", id);
        json.addProperty("message", "Fund receipt deleted: " + info);
        sendJson(response, 200, json);
    }

    // ================================================================== helpers
    /** Approval letters with total received and number of receipts. */
    static List<Map<String, String>> loadLetters(Connection con) throws Exception {
        List<Map<String, String>> list = new ArrayList<>();
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT l.id, l.letter_number, l.letter_name, l.activity_kind, l.amount, l.company_id, "
              + CsrCompanyServlet.nameOf("l") + " AS company_name, "
              + "COALESCE(SUM(f.amount), 0) AS received, COUNT(f.id) AS rcpt_count "
              + "FROM kss_csr_approval_letter l LEFT JOIN kss_csr_fund_receipt f ON f.letter_id = l.id "
              + "GROUP BY l.id, l.letter_number, l.letter_name, l.activity_kind, l.amount, l.company_id ORDER BY l.id DESC");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, String> m = new LinkedHashMap<>();
                m.put("id", String.valueOf(rs.getInt("id")));
                m.put("letterNumber", rs.getString("letter_number"));
                m.put("letterName", rs.getString("letter_name"));
                m.put("companyId", rs.getInt("company_id") == 0 ? "" : String.valueOf(rs.getInt("company_id")));
                m.put("companyName", rs.getString("company_name"));
                m.put("activityKind", rs.getString("activity_kind"));
                m.put("amount", money2(rs.getBigDecimal("amount")));
                m.put("received", money2(rs.getBigDecimal("received")));
                m.put("rcptCount", String.valueOf(rs.getInt("rcpt_count")));
                list.add(m);
            }
        }
        return list;
    }

    private static Map<String, String> fundMap(ResultSet rs) throws Exception {
        Map<String, String> r = new LinkedHashMap<>();
        r.put("id", String.valueOf(rs.getInt("id")));
        r.put("letterId", String.valueOf(rs.getInt("letter_id")));
        int frl = rs.getInt("frl_id");
        r.put("frlId", rs.wasNull() ? "" : String.valueOf(frl));
        r.put("frlNumber", rs.getString("frl_number"));
        r.put("receiptDate", rs.getString("rdate_iso"));
        r.put("receiptDateTxt", rs.getString("rdate_txt"));
        r.put("amount", money2(rs.getBigDecimal("amount")));
        r.put("paymentMode", rs.getString("payment_mode"));
        r.put("referenceNo", rs.getString("reference_no"));
        r.put("bankName", rs.getString("bank_name"));
        r.put("remarks", rs.getString("remarks"));
        r.put("attachmentName", rs.getString("attachment_name"));
        r.put("attachmentSize", rs.getString("attachment_size"));
        r.put("createdBy", rs.getString("created_by"));
        r.put("createdAt", rs.getString("created_txt"));
        r.put("letterNumber", rs.getString("letter_number"));
        r.put("letterName", rs.getString("letter_name"));
        r.put("companyId", rs.getInt("company_id") == 0 ? "" : String.valueOf(rs.getInt("company_id")));
        r.put("companyName", rs.getString("company_name"));
        r.put("activityKind", rs.getString("activity_kind"));
        r.put("letterAmount", money2(rs.getBigDecimal("letter_amount")));
        return r;
    }

    private static String detectType(byte[] d) {
        if (d.length > 4 && d[0] == '%' && d[1] == 'P' && d[2] == 'D' && d[3] == 'F') return "application/pdf";
        if (d.length > 3 && (d[0] & 0xFF) == 0xFF && (d[1] & 0xFF) == 0xD8 && (d[2] & 0xFF) == 0xFF) return "image/jpeg";
        if (d.length > 8 && (d[0] & 0xFF) == 0x89 && d[1] == 'P' && d[2] == 'N' && d[3] == 'G') return "image/png";
        return null;
    }

    private static String money2(BigDecimal v) {
        return v == null ? "0.00" : v.setScale(2, RoundingMode.HALF_UP).toPlainString();
    }

    private static byte[] readAll(InputStream in) throws IOException {
        try (InputStream is = in; ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            byte[] buf = new byte[8192];
            int n;
            while ((n = is.read(buf)) != -1) out.write(buf, 0, n);
            return out.toByteArray();
        }
    }

    private static String trim(String s) {
        return s == null ? "" : s.replace(NBSP, ' ').trim();
    }

    private static String emptyToNull(String s) {
        return s == null || s.isEmpty() ? null : s;
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
