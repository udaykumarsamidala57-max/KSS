package com.Controller;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
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
 * KSS CSR Amount Spending - Approval Letters (Global role only).
 *
 *  GET  CsrLetterServlet                    -> list page (csrLetters.jsp)
 *  GET  CsrLetterServlet?action=form[&id=N] -> add / edit form (csrLetterForm.jsp)
 *  GET  CsrLetterServlet?action=pdf&id=N    -> open the PDF
 *  POST action=save   (multipart, AJAX)     -> add / update (PDF required when adding)
 *  POST action=delete (AJAX)                -> delete
 */
@WebServlet("/CsrLetterServlet")
@MultipartConfig(maxFileSize = 10 * 1024 * 1024, maxRequestSize = 12 * 1024 * 1024)
public class CsrLetterServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private static final int MAX_PDF_BYTES = 10 * 1024 * 1024;   // 10 MB

    private static final String LIST_COLUMNS =
            "id, letter_name, letter_number, activity_kind, place, particulars, amount, pdf_name, pdf_size, "
          + "created_by, DATE_FORMAT(created_at, '%d-%m-%Y') AS created_txt, "
          + "updated_by, DATE_FORMAT(updated_at, '%d-%m-%Y %H:%i') AS updated_txt, "
          + "(SELECT COUNT(*) FROM kss_csr_work_order w WHERE w.letter_id = kss_csr_approval_letter.id) AS wo_count, "
          + "(SELECT COALESCE(SUM(w.total_amount), 0) FROM kss_csr_work_order w WHERE w.letter_id = kss_csr_approval_letter.id) AS wo_total, "
          + "(SELECT COUNT(*) FROM kss_csr_fund_receipt f WHERE f.letter_id = kss_csr_approval_letter.id) AS fund_count, "
          + "(SELECT COALESCE(SUM(f.amount), 0) FROM kss_csr_fund_receipt f WHERE f.letter_id = kss_csr_approval_letter.id) AS fund_total";

    private boolean isGlobal(HttpSession sess) {
        String role = (String) sess.getAttribute("role");
        return role != null && "Global".equalsIgnoreCase(role.replace('\u00A0', ' ').trim());
    }

    // ------------------------------------------------------------------ GET
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

        if ("pdf".equals(request.getParameter("action"))) {
            streamPdf(request, response);
            return;
        }
        if ("form".equals(request.getParameter("action"))) {
            showForm(request, response);
            return;
        }

        List<Map<String, String>> rows = new ArrayList<>();
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(
                     "SELECT " + LIST_COLUMNS + " FROM kss_csr_approval_letter ORDER BY id DESC");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) rows.add(toMap(rs));
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Database error: " + e.getMessage()
                    + " (Has the kss_csr_approval_letter table been created?)");
        }

        request.setAttribute("rows", rows);
        request.getRequestDispatcher("/csrLetters.jsp").forward(request, response);
    }

    /** Add (no id) or edit (with id) form page. */
    private void showForm(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String idParam = request.getParameter("id");
        Map<String, String> row = null;
        List<String> kinds = new ArrayList<>();
        try (Connection con = DBUtil.getConnection()) {
            if (idParam != null && idParam.matches("\\d+")) {
                try (PreparedStatement ps = con.prepareStatement(
                        "SELECT " + LIST_COLUMNS + " FROM kss_csr_approval_letter WHERE id = ?")) {
                    ps.setInt(1, Integer.parseInt(idParam));
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) row = toMap(rs);
                    }
                }
                if (row == null) {
                    response.sendRedirect("CsrLetterServlet");
                    return;
                }
            }
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT DISTINCT activity_kind FROM kss_csr_approval_letter ORDER BY activity_kind");
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) kinds.add(rs.getString(1));
            }
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Database error: " + e.getMessage()
                    + " (Has the kss_csr_approval_letter table been created?)");
        }
        request.setAttribute("row", row);
        request.setAttribute("kinds", kinds);
        request.getRequestDispatcher("/csrLetterForm.jsp").forward(request, response);
    }

    private void streamPdf(HttpServletRequest request, HttpServletResponse response) throws IOException {
        String idParam = request.getParameter("id");
        if (idParam == null || !idParam.matches("\\d+")) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid letter.");
            return;
        }
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(
                     "SELECT letter_number, pdf_name, pdf_file FROM kss_csr_approval_letter WHERE id = ?")) {
            ps.setInt(1, Integer.parseInt(idParam));
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next() || rs.getBytes("pdf_file") == null) {
                    response.sendError(HttpServletResponse.SC_NOT_FOUND, "PDF not found.");
                    return;
                }
                byte[] data = rs.getBytes("pdf_file");
                String name = rs.getString("pdf_name");
                if (name == null || name.trim().isEmpty()) name = "CSR_Letter_" + rs.getString("letter_number") + ".pdf";
                name = name.replaceAll("[^A-Za-z0-9._-]", "_");
                response.setContentType("application/pdf");
                response.setContentLength(data.length);
                response.setHeader("Content-Disposition", "inline; filename=\"" + name + "\"");
                response.getOutputStream().write(data);
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Could not open the PDF.");
        }
    }

    // ------------------------------------------------------------------ POST (AJAX)
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            sendJson(response, HttpServletResponse.SC_UNAUTHORIZED, fail("Your session has expired. Please log in again."));
            return;
        }
        if (!isGlobal(sess)) {
            sendJson(response, HttpServletResponse.SC_FORBIDDEN, fail("Only Global users can manage CSR approval letters."));
            return;
        }
        String user = (String) sess.getAttribute("username");

        String action;
        try {
            action = request.getParameter("action");
        } catch (IllegalStateException tooBig) {
            sendJson(response, HttpServletResponse.SC_BAD_REQUEST, fail("The PDF is too large (maximum 10 MB)."));
            return;
        }

        try (Connection con = DBUtil.getConnection()) {
            if ("save".equals(action)) {
                save(request, response, con, user);
            } else if ("delete".equals(action)) {
                delete(request, response, con);
            } else {
                sendJson(response, HttpServletResponse.SC_BAD_REQUEST, fail("Unknown action."));
            }
        } catch (IllegalStateException tooBig) {
            sendJson(response, HttpServletResponse.SC_BAD_REQUEST, fail("The PDF is too large (maximum 10 MB)."));
        } catch (Exception e) {
            e.printStackTrace();
            sendJson(response, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, fail("Database error: " + e.getMessage()));
        }
    }

    private void save(HttpServletRequest request, HttpServletResponse response, Connection con, String user)
            throws Exception {

        String idParam = trim(request.getParameter("id"));
        String letterName = trim(request.getParameter("letterName"));
        String letterNumber = trim(request.getParameter("letterNumber"));
        String activity = trim(request.getParameter("activityKind"));
        String place = trim(request.getParameter("place"));
        String particulars = trim(request.getParameter("particulars"));
        String amountParam = trim(request.getParameter("amount"));

        // ---- validation
        if (letterName.isEmpty())   { sendJson(response, 400, fail("Please enter the Letter Name.")); return; }
        if (letterNumber.isEmpty()) { sendJson(response, 400, fail("Please enter the Letter Number.")); return; }
        if (activity.isEmpty())     { sendJson(response, 400, fail("Please enter the Kind of CSR activity.")); return; }
        if (place.isEmpty())        { sendJson(response, 400, fail("Please enter the Place.")); return; }
        if (letterName.length() > 200 || letterNumber.length() > 100 || activity.length() > 150 || place.length() > 200) {
            sendJson(response, 400, fail("One of the fields is too long."));
            return;
        }
        BigDecimal amount;
        try {
            amount = new BigDecimal(amountParam.replace(",", ""));
        } catch (NumberFormatException e) {
            amount = null;
        }
        if (amount == null || amount.signum() <= 0 || amount.compareTo(new BigDecimal("999999999999")) > 0) {
            sendJson(response, 400, fail("Please enter a valid Amount."));
            return;
        }
        amount = amount.setScale(2, RoundingMode.HALF_UP);

        // ---- PDF (required when adding, optional when editing)
        byte[] pdf = null;
        String pdfName = null;
        Part part = request.getPart("pdfFile");
        if (part != null && part.getSize() > 0) {
            if (part.getSize() > MAX_PDF_BYTES) {
                sendJson(response, 400, fail("The PDF is too large (maximum 10 MB)."));
                return;
            }
            pdf = readAll(part.getInputStream());
            if (pdf.length < 5 || pdf[0] != '%' || pdf[1] != 'P' || pdf[2] != 'D' || pdf[3] != 'F') {
                sendJson(response, 400, fail("Please attach a PDF file."));
                return;
            }
            pdfName = part.getSubmittedFileName();
            if (pdfName != null) pdfName = pdfName.replaceAll("^.*[\\\\/]", "");   // strip any path
            if (pdfName != null && pdfName.length() > 255) pdfName = pdfName.substring(pdfName.length() - 255);
        }

        boolean isNew = idParam.isEmpty();
        int id;
        try {
            if (isNew) {
                if (pdf == null) {
                    sendJson(response, 400, fail("Please attach the approval letter PDF."));
                    return;
                }
                try (PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO kss_csr_approval_letter (letter_name, letter_number, activity_kind, place, particulars, "
                      + "amount, pdf_file, pdf_name, pdf_size, created_by, updated_by) VALUES (?,?,?,?,?,?,?,?,?,?,?)",
                        Statement.RETURN_GENERATED_KEYS)) {
                    ps.setString(1, letterName);
                    ps.setString(2, letterNumber);
                    ps.setString(3, activity);
                    ps.setString(4, place);
                    ps.setString(5, particulars.isEmpty() ? null : particulars);
                    ps.setBigDecimal(6, amount);
                    ps.setBytes(7, pdf);
                    ps.setString(8, pdfName);
                    ps.setInt(9, pdf.length);
                    ps.setString(10, user);
                    ps.setString(11, user);
                    ps.executeUpdate();
                    try (ResultSet keys = ps.getGeneratedKeys()) {
                        keys.next();
                        id = keys.getInt(1);
                    }
                }
            } else {
                if (!idParam.matches("\\d+")) {
                    sendJson(response, 400, fail("Invalid letter."));
                    return;
                }
                id = Integer.parseInt(idParam);
                // the approved amount cannot go below what is already committed (work orders) or received (funds)
                BigDecimal committed = BigDecimal.ZERO, received = BigDecimal.ZERO;
                try (PreparedStatement ps = con.prepareStatement(
                        "SELECT (SELECT COALESCE(SUM(total_amount), 0) FROM kss_csr_work_order WHERE letter_id = ?), "
                      + "(SELECT COALESCE(SUM(amount), 0) FROM kss_csr_fund_receipt WHERE letter_id = ?)")) {
                    ps.setInt(1, id);
                    ps.setInt(2, id);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) { committed = rs.getBigDecimal(1); received = rs.getBigDecimal(2); }
                    }
                }
                if (amount.compareTo(committed) < 0) {
                    sendJson(response, 400, fail("Amount cannot be less than the work orders already raised ("
                            + committed.setScale(2, RoundingMode.HALF_UP).toPlainString() + ")."));
                    return;
                }
                if (amount.compareTo(received) < 0) {
                    sendJson(response, 400, fail("Amount cannot be less than the funds already received ("
                            + received.setScale(2, RoundingMode.HALF_UP).toPlainString() + ")."));
                    return;
                }
                String sql = "UPDATE kss_csr_approval_letter SET letter_name=?, letter_number=?, activity_kind=?, place=?, "
                           + "particulars=?, amount=?, updated_by=?"
                           + (pdf != null ? ", pdf_file=?, pdf_name=?, pdf_size=?" : "")
                           + " WHERE id=?";
                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    int i = 1;
                    ps.setString(i++, letterName);
                    ps.setString(i++, letterNumber);
                    ps.setString(i++, activity);
                    ps.setString(i++, place);
                    ps.setString(i++, particulars.isEmpty() ? null : particulars);
                    ps.setBigDecimal(i++, amount);
                    ps.setString(i++, user);
                    if (pdf != null) {
                        ps.setBytes(i++, pdf);
                        ps.setString(i++, pdfName);
                        ps.setInt(i++, pdf.length);
                    }
                    ps.setInt(i, id);
                    if (ps.executeUpdate() == 0) {
                        sendJson(response, 404, fail("Letter not found. Please reload the page."));
                        return;
                    }
                }
            }
        } catch (SQLIntegrityConstraintViolationException dup) {
            sendJson(response, 409, fail("Letter Number \"" + letterNumber + "\" already exists."));
            return;
        }

        JsonObject json = rowJson(con, id);
        json.addProperty("ok", true);
        json.addProperty("isNew", isNew);
        json.addProperty("message", (isNew ? "Approval letter added: " : "Approval letter updated: ") + letterNumber);
        sendJson(response, 200, json);
    }

    private void delete(HttpServletRequest request, HttpServletResponse response, Connection con) throws Exception {
        String idParam = trim(request.getParameter("id"));
        if (!idParam.matches("\\d+")) {
            sendJson(response, 400, fail("Invalid letter."));
            return;
        }
        int id = Integer.parseInt(idParam);
        String number = null;
        try (PreparedStatement ps = con.prepareStatement("SELECT letter_number FROM kss_csr_approval_letter WHERE id = ?")) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) number = rs.getString(1);
            }
        }
        if (number == null) {
            sendJson(response, 404, fail("Letter not found. Please reload the page."));
            return;
        }
        int woCount = 0;
        try (PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM kss_csr_work_order WHERE letter_id = ?")) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) { if (rs.next()) woCount = rs.getInt(1); }
        }
        if (woCount > 0) {
            sendJson(response, 409, fail("Cannot delete " + number + ": it has " + woCount + " work order"
                    + (woCount == 1 ? "" : "s") + ". Delete the work orders first."));
            return;
        }
        int fundCount = 0;
        try (PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM kss_csr_fund_receipt WHERE letter_id = ?")) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) { if (rs.next()) fundCount = rs.getInt(1); }
        }
        if (fundCount > 0) {
            sendJson(response, 409, fail("Cannot delete " + number + ": it has " + fundCount + " fund receipt"
                    + (fundCount == 1 ? "" : "s") + ". Delete the fund receipts first."));
            return;
        }
        try (PreparedStatement ps = con.prepareStatement("DELETE FROM kss_csr_approval_letter WHERE id = ?")) {
            ps.setInt(1, id);
            ps.executeUpdate();
        }
        JsonObject json = new JsonObject();
        json.addProperty("ok", true);
        json.addProperty("id", id);
        json.addProperty("message", "Approval letter deleted: " + number);
        sendJson(response, 200, json);
    }

    // ------------------------------------------------------------------ helpers
    private static Map<String, String> toMap(ResultSet rs) throws Exception {
        Map<String, String> r = new LinkedHashMap<>();
        r.put("id", String.valueOf(rs.getInt("id")));
        r.put("letterName", rs.getString("letter_name"));
        r.put("letterNumber", rs.getString("letter_number"));
        r.put("activityKind", rs.getString("activity_kind"));
        r.put("place", rs.getString("place"));
        r.put("particulars", rs.getString("particulars"));
        BigDecimal amt = rs.getBigDecimal("amount");
        r.put("amount", amt == null ? "0.00" : amt.setScale(2, RoundingMode.HALF_UP).toPlainString());
        r.put("pdfName", rs.getString("pdf_name"));
        r.put("pdfSize", rs.getString("pdf_size"));
        r.put("createdBy", rs.getString("created_by"));
        r.put("createdAt", rs.getString("created_txt"));
        r.put("updatedBy", rs.getString("updated_by"));
        r.put("updatedAt", rs.getString("updated_txt"));
        r.put("woCount", String.valueOf(rs.getInt("wo_count")));
        BigDecimal woTotal = rs.getBigDecimal("wo_total");
        r.put("woTotal", woTotal == null ? "0.00" : woTotal.setScale(2, RoundingMode.HALF_UP).toPlainString());
        r.put("fundCount", String.valueOf(rs.getInt("fund_count")));
        BigDecimal fundTotal = rs.getBigDecimal("fund_total");
        r.put("fundTotal", fundTotal == null ? "0.00" : fundTotal.setScale(2, RoundingMode.HALF_UP).toPlainString());
        return r;
    }

    private JsonObject rowJson(Connection con, int id) throws Exception {
        JsonObject json = new JsonObject();
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT " + LIST_COLUMNS + " FROM kss_csr_approval_letter WHERE id = ?")) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    for (Map.Entry<String, String> e : toMap(rs).entrySet()) json.addProperty(e.getKey(), e.getValue());
                }
            }
        }
        return json;
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
        return s == null ? "" : s.replace('\u00A0', ' ').trim();
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
