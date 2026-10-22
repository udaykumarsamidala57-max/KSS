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
import java.sql.SQLIntegrityConstraintViolationException;
import java.sql.Statement;
import java.time.LocalDate;
import java.util.ArrayList;
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
 * KSS CSR Amount Spending : Funds Request Letters (FRL) (Global role only).
 * Approval Letter -> Work Orders -> Proforma / Tax Invoices -> FRL (one or more invoices of the
 * same approval letter) -> Fund Receipts. The FRL amount is the total of its invoices.
 *
 *  GET  CsrFrlServlet[?letterId=N]                    -> list page (csrFrls.jsp)
 *  GET  CsrFrlServlet?action=form[&id=N|&letterId=N[&invoiceId=N]] -> add / edit form (csrFrlForm.jsp)
 *  GET  CsrFrlServlet?action=file&id=N                -> open the FRL copy
 *  POST action=save   (multipart, AJAX)               -> add / update
 *  POST action=delete (AJAX)                          -> delete
 */
@WebServlet("/CsrFrlServlet")
@MultipartConfig(maxFileSize = 10 * 1024 * 1024, maxRequestSize = 12 * 1024 * 1024)
public class CsrFrlServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private static final int MAX_FILE_BYTES = 10 * 1024 * 1024;
    private static final char NBSP = (char) 160;

    private static final String FRL_COLUMNS =
            "r.id, r.letter_id, r.frl_number, DATE_FORMAT(r.frl_date, '%Y-%m-%d') AS fdate_iso, "
          + "DATE_FORMAT(r.frl_date, '%d-%m-%Y') AS fdate_txt, r.amount, r.remarks, r.attachment_name, r.attachment_size, "
          + "r.created_by, DATE_FORMAT(r.created_at, '%d-%m-%Y') AS created_txt, "
          + "l.letter_number, l.letter_name, l.activity_kind, l.amount AS letter_amount, "
          + "(SELECT COALESCE(SUM(f.amount), 0) FROM kss_csr_fund_receipt f WHERE f.frl_id = r.id) AS received, "
          + "(SELECT COUNT(*) FROM kss_csr_fund_receipt f WHERE f.frl_id = r.id) AS rcpt_count, "
          + "(SELECT GROUP_CONCAT(CONCAT(IF(i.invoice_type = 'Proforma', 'PI ', ''), i.invoice_number) ORDER BY i.invoice_date, i.id SEPARATOR ', ') "
          + " FROM kss_csr_frl_invoice fi JOIN kss_csr_invoice i ON i.id = fi.invoice_id WHERE fi.frl_id = r.id) AS inv_numbers, "
          + "(SELECT GROUP_CONCAT(fi.invoice_id) FROM kss_csr_frl_invoice fi WHERE fi.frl_id = r.id) AS inv_ids";

    private static final String FRL_FROM =
            " FROM kss_csr_fund_request r JOIN kss_csr_approval_letter l ON l.id = r.letter_id";

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
            String invParam = request.getParameter("invoiceId");
            Map<String, String> frl = null;
            List<Map<String, String>> invoices = new ArrayList<>();
            try (Connection con = DBUtil.getConnection()) {
                if (idParam != null && idParam.matches("\\d+")) {
                    try (PreparedStatement ps = con.prepareStatement("SELECT " + FRL_COLUMNS + FRL_FROM + " WHERE r.id = ?")) {
                        ps.setInt(1, Integer.parseInt(idParam));
                        try (ResultSet rs = ps.executeQuery()) { if (rs.next()) frl = frlMap(rs); }
                    }
                    if (frl == null) {
                        response.sendRedirect("CsrFrlServlet");
                        return;
                    }
                }
                letters = loadLetters(con);
                invoices = CsrInvoiceServlet.loadInvoices(con);
            } catch (Exception e) {
                e.printStackTrace();
                request.setAttribute("error", "Database error: " + e.getMessage()
                        + " (Have the kss_csr_fund_request and kss_csr_frl_invoice tables been created?)");
            }
            request.setAttribute("frl", frl);
            request.setAttribute("invoices", invoices);
            request.setAttribute("presetInvoiceId", invParam != null && invParam.matches("\\d+") ? invParam : "");
            request.setAttribute("letters", letters);
            request.setAttribute("presetLetterId", presetLetter);
            request.getRequestDispatcher("/csrFrlForm.jsp").forward(request, response);
            return;
        }

        // ---- list
        List<Map<String, String>> rows = new ArrayList<>();
        try (Connection con = DBUtil.getConnection()) {
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT " + FRL_COLUMNS + FRL_FROM + " ORDER BY r.frl_date DESC, r.id DESC");
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) rows.add(frlMap(rs));
            }
            letters = loadLetters(con);
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Database error: " + e.getMessage()
                    + " (Has the kss_csr_fund_request table been created?)");
        }
        request.setAttribute("rows", rows);
        request.setAttribute("letters", letters);
        request.setAttribute("letterFilter", presetLetter);
        request.getRequestDispatcher("/csrFrls.jsp").forward(request, response);
    }

    private void streamFile(HttpServletRequest request, HttpServletResponse response) throws IOException {
        String idParam = request.getParameter("id");
        if (idParam == null || !idParam.matches("\\d+")) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid request letter.");
            return;
        }
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(
                     "SELECT frl_number, attachment, attachment_name, attachment_type FROM kss_csr_fund_request WHERE id = ?")) {
            ps.setInt(1, Integer.parseInt(idParam));
            try (ResultSet rs = ps.executeQuery()) {
                byte[] data = rs.next() ? rs.getBytes("attachment") : null;
                if (data == null) {
                    response.sendError(HttpServletResponse.SC_NOT_FOUND, "Attachment not found.");
                    return;
                }
                String type = rs.getString("attachment_type");
                String name = rs.getString("attachment_name");
                if (name == null || name.trim().isEmpty()) name = "FRL_" + rs.getString("frl_number");
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
            sendJson(response, 403, fail("Only Global users can manage funds request letters."));
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
        String letterParam = trim(request.getParameter("letterId"));
        String number = trim(request.getParameter("frlNumber"));
        String dateS = trim(request.getParameter("frlDate"));
        String invoiceIdsS = trim(request.getParameter("invoiceIds"));
        String remarks = trim(request.getParameter("remarks"));

        if (!letterParam.matches("\\d+")) { sendJson(response, 400, fail("Please select the Approval Letter.")); return; }
        if (number.isEmpty()) { sendJson(response, 400, fail("Please enter the FRL Number.")); return; }
        if (number.length() > 100) { sendJson(response, 400, fail("FRL Number is too long (maximum 100 characters).")); return; }
        LocalDate date;
        try {
            date = LocalDate.parse(dateS);
        } catch (Exception e) {
            sendJson(response, 400, fail("Please enter a valid FRL Date."));
            return;
        }
        List<Integer> invoiceIds = new ArrayList<>();
        for (String part : invoiceIdsS.split(",")) {
            String t = part.trim();
            if (t.isEmpty()) continue;
            if (!t.matches("\\d+")) { sendJson(response, 400, fail("Invalid invoice selection.")); return; }
            Integer v = Integer.valueOf(t);
            if (!invoiceIds.contains(v)) invoiceIds.add(v);
        }
        if (invoiceIds.isEmpty()) { sendJson(response, 400, fail("Please tick at least one invoice for this FRL.")); return; }
        if (remarks.length() > 500) { sendJson(response, 400, fail("Remarks are too long (maximum 500 characters).")); return; }

        // ---- attachment (required when adding)
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
        if (!isNew && !idParam.matches("\\d+")) { sendJson(response, 400, fail("Invalid request letter.")); return; }
        if (isNew && file == null) { sendJson(response, 400, fail("Please attach the Funds Request Letter copy.")); return; }
        int letterId = Integer.parseInt(letterParam);
        int id = isNew ? 0 : Integer.parseInt(idParam);

        // ---- the ticked invoices: must exist, belong to this approval letter, and not be in another FRL
        BigDecimal amount = BigDecimal.ZERO;
        for (Integer invId : invoiceIds) {
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT i.invoice_number, i.amount, w.letter_id, "
                  + "(SELECT r.frl_number FROM kss_csr_frl_invoice fi JOIN kss_csr_fund_request r ON r.id = fi.frl_id "
                  + " WHERE fi.invoice_id = i.id AND fi.frl_id <> ?) AS other_frl "
                  + "FROM kss_csr_invoice i JOIN kss_csr_work_order w ON w.id = i.work_order_id WHERE i.id = ?")) {
                ps.setInt(1, id);
                ps.setInt(2, invId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) { sendJson(response, 400, fail("An invoice was not found. Please reload the page.")); return; }
                    if (rs.getInt("letter_id") != letterId) {
                        sendJson(response, 400, fail("Invoice " + rs.getString("invoice_number") + " does not belong to the selected approval letter."));
                        return;
                    }
                    if (rs.getString("other_frl") != null) {
                        sendJson(response, 400, fail("Invoice " + rs.getString("invoice_number") + " is already in FRL " + rs.getString("other_frl") + "."));
                        return;
                    }
                    amount = amount.add(rs.getBigDecimal("amount"));
                }
            }
        }
        amount = amount.setScale(2, RoundingMode.HALF_UP);

        // ---- editing: cannot go below what is already received, cannot move to another letter once funds came
        if (!isNew) {
            Integer oldLetter = null;
            BigDecimal received = BigDecimal.ZERO;
            int rcpts = 0;
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT r.letter_id, (SELECT COALESCE(SUM(f.amount), 0) FROM kss_csr_fund_receipt f WHERE f.frl_id = r.id), "
                  + "(SELECT COUNT(*) FROM kss_csr_fund_receipt f WHERE f.frl_id = r.id) FROM kss_csr_fund_request r WHERE r.id = ?")) {
                ps.setInt(1, id);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) { oldLetter = rs.getInt(1); received = rs.getBigDecimal(2); rcpts = rs.getInt(3); }
                }
            }
            if (oldLetter == null) { sendJson(response, 404, fail("Request letter not found. Please reload the page.")); return; }
            if (rcpts > 0 && oldLetter != letterId) {
                sendJson(response, 400, fail("Funds have already been received against this FRL, so its approval letter cannot be changed."));
                return;
            }
            if (amount.compareTo(received) < 0) {
                sendJson(response, 400, fail("The ticked invoices total Rs " + amount.toPlainString() + ", which is less than the funds already received against this FRL (Rs "
                        + received.setScale(2, RoundingMode.HALF_UP).toPlainString() + ")."));
                return;
            }
        }

        // ---- total requested must not exceed the approved amount
        BigDecimal approved = null;
        String letterNumber = null;
        try (PreparedStatement ps = con.prepareStatement("SELECT amount, letter_number FROM kss_csr_approval_letter WHERE id = ?")) {
            ps.setInt(1, letterId);
            try (ResultSet rs = ps.executeQuery()) { if (rs.next()) { approved = rs.getBigDecimal(1); letterNumber = rs.getString(2); } }
        }
        if (approved == null) { sendJson(response, 400, fail("Approval letter not found. Please reload the page.")); return; }
        BigDecimal others;
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT COALESCE(SUM(amount), 0) FROM kss_csr_fund_request WHERE letter_id = ? AND id <> ?")) {
            ps.setInt(1, letterId);
            ps.setInt(2, id);
            try (ResultSet rs = ps.executeQuery()) { rs.next(); others = rs.getBigDecimal(1); }
        }
        BigDecimal available = approved.subtract(others);
        if (amount.compareTo(available) > 0) {
            sendJson(response, 400, fail("Amount Rs " + amount.toPlainString() + " is more than the Rs "
                    + available.setScale(2, RoundingMode.HALF_UP).toPlainString() + " still available to request on approval letter "
                    + letterNumber + "."));
            return;
        }

        boolean auto = con.getAutoCommit();
        con.setAutoCommit(false);
        try {
            if (isNew) {
                try (PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO kss_csr_fund_request (letter_id, frl_number, frl_date, amount, remarks, attachment, attachment_name, "
                      + "attachment_type, attachment_size, created_by, updated_by) VALUES (?,?,?,?,?,?,?,?,?,?,?)",
                        Statement.RETURN_GENERATED_KEYS)) {
                    int i = 1;
                    ps.setInt(i++, letterId);
                    ps.setString(i++, number);
                    ps.setDate(i++, Date.valueOf(date));
                    ps.setBigDecimal(i++, amount);
                    ps.setString(i++, remarks.isEmpty() ? null : remarks);
                    ps.setBytes(i++, file);
                    ps.setString(i++, fileName);
                    ps.setString(i++, fileType);
                    ps.setInt(i++, file.length);
                    ps.setString(i++, user);
                    ps.setString(i, user);
                    ps.executeUpdate();
                    try (ResultSet keys = ps.getGeneratedKeys()) { keys.next(); id = keys.getInt(1); }
                }
            } else {
                String sql = "UPDATE kss_csr_fund_request SET letter_id=?, frl_number=?, frl_date=?, amount=?, remarks=?, updated_by=?"
                           + (file != null ? ", attachment=?, attachment_name=?, attachment_type=?, attachment_size=?" : "")
                           + " WHERE id=?";
                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    int i = 1;
                    ps.setInt(i++, letterId);
                    ps.setString(i++, number);
                    ps.setDate(i++, Date.valueOf(date));
                    ps.setBigDecimal(i++, amount);
                    ps.setString(i++, remarks.isEmpty() ? null : remarks);
                    ps.setString(i++, user);
                    if (file != null) {
                        ps.setBytes(i++, file);
                        ps.setString(i++, fileName);
                        ps.setString(i++, fileType);
                        ps.setInt(i++, file.length);
                    }
                    ps.setInt(i, id);
                    ps.executeUpdate();
                }
            }
            try (PreparedStatement ps = con.prepareStatement("DELETE FROM kss_csr_frl_invoice WHERE frl_id = ?")) {
                ps.setInt(1, id);
                ps.executeUpdate();
            }
            try (PreparedStatement ps = con.prepareStatement("INSERT INTO kss_csr_frl_invoice (frl_id, invoice_id) VALUES (?, ?)")) {
                for (Integer invId : invoiceIds) {
                    ps.setInt(1, id);
                    ps.setInt(2, invId);
                    ps.addBatch();
                }
                ps.executeBatch();
            }
            con.commit();
        } catch (SQLIntegrityConstraintViolationException dup) {
            con.rollback();
            sendJson(response, 409, fail(dup.getMessage() != null && dup.getMessage().contains("uq_csr_frl_invoice")
                    ? "One of the invoices was just added to another FRL. Please reload the page."
                    : "FRL Number \"" + number + "\" already exists."));
            return;
        } catch (Exception e) {
            con.rollback();
            throw e;
        } finally {
            con.setAutoCommit(auto);
        }

        JsonObject json = new JsonObject();
        json.addProperty("ok", true);
        json.addProperty("id", id);
        json.addProperty("message", (isNew ? "Funds request letter added: " : "Funds request letter updated: ") + number
                + " (Rs " + amount.toPlainString() + ")");
        sendJson(response, 200, json);
    }

    private void delete(HttpServletRequest request, HttpServletResponse response, Connection con) throws Exception {
        String idParam = trim(request.getParameter("id"));
        if (!idParam.matches("\\d+")) { sendJson(response, 400, fail("Invalid request letter.")); return; }
        int id = Integer.parseInt(idParam);
        String number = null;
        int rcpts = 0;
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT frl_number, (SELECT COUNT(*) FROM kss_csr_fund_receipt f WHERE f.frl_id = r.id) FROM kss_csr_fund_request r WHERE r.id = ?")) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) { if (rs.next()) { number = rs.getString(1); rcpts = rs.getInt(2); } }
        }
        if (number == null) { sendJson(response, 404, fail("Request letter not found. Please reload the page.")); return; }
        if (rcpts > 0) {
            sendJson(response, 409, fail("Cannot delete " + number + ": it has " + rcpts + " fund receipt"
                    + (rcpts == 1 ? "" : "s") + ". Delete the fund receipts first."));
            return;
        }
        try (PreparedStatement ps = con.prepareStatement("DELETE FROM kss_csr_fund_request WHERE id = ?")) {
            ps.setInt(1, id);
            ps.executeUpdate();
        }
        JsonObject json = new JsonObject();
        json.addProperty("ok", true);
        json.addProperty("id", id);
        json.addProperty("message", "Funds request letter deleted: " + number);
        sendJson(response, 200, json);
    }

    // ================================================================== helpers
    /** Approval letters with total requested (FRLs) and total received. */
    static List<Map<String, String>> loadLetters(Connection con) throws Exception {
        List<Map<String, String>> list = new ArrayList<>();
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT l.id, l.letter_number, l.letter_name, l.activity_kind, l.amount, "
              + "(SELECT COALESCE(SUM(r.amount), 0) FROM kss_csr_fund_request r WHERE r.letter_id = l.id) AS requested, "
              + "(SELECT COUNT(*) FROM kss_csr_fund_request r WHERE r.letter_id = l.id) AS frl_count, "
              + "(SELECT COALESCE(SUM(f.amount), 0) FROM kss_csr_fund_receipt f WHERE f.letter_id = l.id) AS received "
              + "FROM kss_csr_approval_letter l ORDER BY l.id DESC");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, String> m = new LinkedHashMap<>();
                m.put("id", String.valueOf(rs.getInt("id")));
                m.put("letterNumber", rs.getString("letter_number"));
                m.put("letterName", rs.getString("letter_name"));
                m.put("activityKind", rs.getString("activity_kind"));
                m.put("amount", money2(rs.getBigDecimal("amount")));
                m.put("requested", money2(rs.getBigDecimal("requested")));
                m.put("frlCount", String.valueOf(rs.getInt("frl_count")));
                m.put("received", money2(rs.getBigDecimal("received")));
                list.add(m);
            }
        }
        return list;
    }

    /** All FRLs with received totals (used by the fund receipt form). */
    static List<Map<String, String>> loadFrls(Connection con) throws Exception {
        List<Map<String, String>> list = new ArrayList<>();
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT " + FRL_COLUMNS + FRL_FROM + " ORDER BY r.frl_date DESC, r.id DESC");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(frlMap(rs));
        }
        return list;
    }

    private static Map<String, String> frlMap(ResultSet rs) throws Exception {
        Map<String, String> r = new LinkedHashMap<>();
        r.put("id", String.valueOf(rs.getInt("id")));
        r.put("letterId", String.valueOf(rs.getInt("letter_id")));
        r.put("frlNumber", rs.getString("frl_number"));
        r.put("frlDate", rs.getString("fdate_iso"));
        r.put("frlDateTxt", rs.getString("fdate_txt"));
        r.put("amount", money2(rs.getBigDecimal("amount")));
        r.put("remarks", rs.getString("remarks"));
        r.put("invoiceNumbers", rs.getString("inv_numbers"));
        r.put("invoiceIds", rs.getString("inv_ids"));
        r.put("received", money2(rs.getBigDecimal("received")));
        r.put("rcptCount", String.valueOf(rs.getInt("rcpt_count")));
        r.put("attachmentName", rs.getString("attachment_name"));
        r.put("attachmentSize", rs.getString("attachment_size"));
        r.put("createdBy", rs.getString("created_by"));
        r.put("createdAt", rs.getString("created_txt"));
        r.put("letterNumber", rs.getString("letter_number"));
        r.put("letterName", rs.getString("letter_name"));
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
