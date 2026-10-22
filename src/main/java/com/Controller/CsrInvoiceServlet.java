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
 * KSS CSR Amount Spending - Step 3 : Invoices against Work Orders (Global role only).
 *
 *  GET  CsrInvoiceServlet[?woId=N]                       -> list page (csrInvoices.jsp)
 *  GET  CsrInvoiceServlet?action=form[&id=N|&woId=N]     -> add / edit form (csrInvoiceForm.jsp)
 *  GET  CsrInvoiceServlet?action=file&id=N               -> open the invoice copy
 *  POST action=save   (multipart, AJAX)                  -> add / update
 *  POST action=delete (AJAX)                             -> delete
 */
@WebServlet("/CsrInvoiceServlet")
@MultipartConfig(maxFileSize = 10 * 1024 * 1024, maxRequestSize = 12 * 1024 * 1024)
public class CsrInvoiceServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private static final int MAX_FILE_BYTES = 10 * 1024 * 1024;
    private static final char NBSP = (char) 160;
    private static final BigDecimal HUNDRED = new BigDecimal("100");

    private static final String INV_COLUMNS =
            "i.id, i.work_order_id, i.invoice_number, DATE_FORMAT(i.invoice_date, '%Y-%m-%d') AS inv_date_iso, "
          + "DATE_FORMAT(i.invoice_date, '%d-%m-%Y') AS inv_date_txt, i.price, i.gst_percent, i.gst_amount, i.amount, "
          + "i.attachment_name, i.attachment_type, i.attachment_size, i.created_by, "
          + "DATE_FORMAT(i.created_at, '%d-%m-%Y') AS created_txt, "
          + "w.wo_number, w.vendor_name, w.total_amount AS wo_total, l.letter_number";

    private static final String INV_FROM =
            " FROM kss_csr_invoice i JOIN kss_csr_work_order w ON w.id = i.work_order_id "
          + "JOIN kss_csr_approval_letter l ON l.id = w.letter_id";

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

        String woParam = request.getParameter("woId");
        String presetWo = woParam != null && woParam.matches("\\d+") ? woParam : "";
        List<Map<String, String>> workOrders = new ArrayList<>();

        if ("form".equals(action)) {
            String idParam = request.getParameter("id");
            Map<String, String> inv = null;
            try (Connection con = DBUtil.getConnection()) {
                if (idParam != null && idParam.matches("\\d+")) {
                    try (PreparedStatement ps = con.prepareStatement("SELECT " + INV_COLUMNS + INV_FROM + " WHERE i.id = ?")) {
                        ps.setInt(1, Integer.parseInt(idParam));
                        try (ResultSet rs = ps.executeQuery()) { if (rs.next()) inv = invMap(rs); }
                    }
                    if (inv == null) {
                        response.sendRedirect("CsrInvoiceServlet");
                        return;
                    }
                }
                workOrders = loadWorkOrders(con);
            } catch (Exception e) {
                e.printStackTrace();
                request.setAttribute("error", "Database error: " + e.getMessage()
                        + " (Has the kss_csr_invoice table been created?)");
            }
            request.setAttribute("inv", inv);
            request.setAttribute("workOrders", workOrders);
            request.setAttribute("presetWoId", presetWo);
            request.getRequestDispatcher("/csrInvoiceForm.jsp").forward(request, response);
            return;
        }

        // ---- list
        List<Map<String, String>> rows = new ArrayList<>();
        try (Connection con = DBUtil.getConnection()) {
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT " + INV_COLUMNS + INV_FROM + " ORDER BY i.invoice_date DESC, i.id DESC");
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) rows.add(invMap(rs));
            }
            workOrders = loadWorkOrders(con);
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Database error: " + e.getMessage()
                    + " (Has the kss_csr_invoice table been created?)");
        }
        request.setAttribute("rows", rows);
        request.setAttribute("workOrders", workOrders);
        request.setAttribute("woFilter", presetWo);
        request.getRequestDispatcher("/csrInvoices.jsp").forward(request, response);
    }

    private void streamFile(HttpServletRequest request, HttpServletResponse response) throws IOException {
        String idParam = request.getParameter("id");
        if (idParam == null || !idParam.matches("\\d+")) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid invoice.");
            return;
        }
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(
                     "SELECT invoice_number, attachment, attachment_name, attachment_type FROM kss_csr_invoice WHERE id = ?")) {
            ps.setInt(1, Integer.parseInt(idParam));
            try (ResultSet rs = ps.executeQuery()) {
                byte[] data = rs.next() ? rs.getBytes("attachment") : null;
                if (data == null) {
                    response.sendError(HttpServletResponse.SC_NOT_FOUND, "Invoice copy not found.");
                    return;
                }
                String type = rs.getString("attachment_type");
                String name = rs.getString("attachment_name");
                if (name == null || name.trim().isEmpty()) name = "Invoice_" + rs.getString("invoice_number");
                name = name.replaceAll("[^A-Za-z0-9._-]", "_");
                response.setContentType(type == null ? "application/octet-stream" : type);
                response.setContentLength(data.length);
                response.setHeader("Content-Disposition", "inline; filename=\"" + name + "\"");
                response.getOutputStream().write(data);
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Could not open the invoice copy.");
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
            sendJson(response, 403, fail("Only Global users can manage invoices."));
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
            sendJson(response, 400, fail("The invoice copy is too large (maximum 10 MB)."));
        } catch (Exception e) {
            e.printStackTrace();
            sendJson(response, 500, fail("Database error: " + e.getMessage()));
        }
    }

    private void save(HttpServletRequest request, HttpServletResponse response, Connection con, String user) throws Exception {
        String idParam = trim(request.getParameter("id"));
        String woParam = trim(request.getParameter("woId"));
        String invNumber = trim(request.getParameter("invoiceNumber"));
        String invDate = trim(request.getParameter("invoiceDate"));
        String priceS = trim(request.getParameter("price"));
        String gstS = trim(request.getParameter("gst"));

        if (!woParam.matches("\\d+"))  { sendJson(response, 400, fail("Please select the Work Order.")); return; }
        if (invNumber.isEmpty())       { sendJson(response, 400, fail("Please enter the Invoice Number.")); return; }
        if (invNumber.length() > 100)  { sendJson(response, 400, fail("Invoice Number is too long.")); return; }
        LocalDate date;
        try {
            date = LocalDate.parse(invDate);
        } catch (Exception e) {
            sendJson(response, 400, fail("Please enter a valid Invoice Date."));
            return;
        }
        BigDecimal price, gst;
        try {
            price = new BigDecimal(priceS.replace(",", ""));
            gst = new BigDecimal(gstS.isEmpty() ? "0" : gstS);
        } catch (NumberFormatException e) {
            sendJson(response, 400, fail("Please enter a valid Price and GST."));
            return;
        }
        if (price.signum() <= 0 || price.compareTo(new BigDecimal("999999999999")) > 0) {
            sendJson(response, 400, fail("Please enter a valid Price."));
            return;
        }
        if (gst.signum() < 0 || gst.compareTo(HUNDRED) > 0) {
            sendJson(response, 400, fail("GST % must be between 0 and 100."));
            return;
        }
        price = price.setScale(2, RoundingMode.HALF_UP);
        gst = gst.setScale(2, RoundingMode.HALF_UP);
        BigDecimal gstAmt = price.multiply(gst).divide(HUNDRED, 2, RoundingMode.HALF_UP);
        BigDecimal amount = price.add(gstAmt);

        // ---- attachment (optional)
        byte[] file = null;
        String fileName = null, fileType = null;
        Part part = request.getPart("attachment");
        if (part != null && part.getSize() > 0) {
            if (part.getSize() > MAX_FILE_BYTES) { sendJson(response, 400, fail("The invoice copy is too large (maximum 10 MB).")); return; }
            file = readAll(part.getInputStream());
            fileType = detectType(file);
            if (fileType == null) { sendJson(response, 400, fail("Invoice copy must be a PDF, JPG or PNG file.")); return; }
            fileName = part.getSubmittedFileName();
            if (fileName != null) fileName = fileName.replaceAll("^.*[\\\\/]", "");
            if (fileName != null && fileName.length() > 255) fileName = fileName.substring(fileName.length() - 255);
        }

        boolean isNew = idParam.isEmpty();
        if (!isNew && !idParam.matches("\\d+")) { sendJson(response, 400, fail("Invalid invoice.")); return; }
        int woId = Integer.parseInt(woParam);
        int id = isNew ? 0 : Integer.parseInt(idParam);

        // ---- budget check: invoices of a work order must not exceed the work order total
        BigDecimal woTotal = null;
        String woNumber = null;
        try (PreparedStatement ps = con.prepareStatement("SELECT total_amount, wo_number FROM kss_csr_work_order WHERE id = ?")) {
            ps.setInt(1, woId);
            try (ResultSet rs = ps.executeQuery()) { if (rs.next()) { woTotal = rs.getBigDecimal(1); woNumber = rs.getString(2); } }
        }
        if (woTotal == null) { sendJson(response, 400, fail("Work order not found. Please reload the page.")); return; }
        BigDecimal others;
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT COALESCE(SUM(amount), 0) FROM kss_csr_invoice WHERE work_order_id = ? AND id <> ?")) {
            ps.setInt(1, woId);
            ps.setInt(2, id);
            try (ResultSet rs = ps.executeQuery()) { rs.next(); others = rs.getBigDecimal(1); }
        }
        BigDecimal balance = woTotal.subtract(others);
        if (amount.compareTo(balance) > 0) {
            sendJson(response, 400, fail("Invoice amount Rs " + amount.toPlainString() + " exceeds the balance Rs "
                    + balance.toPlainString() + " of work order " + woNumber + "."));
            return;
        }

        try {
            if (isNew) {
                try (PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO kss_csr_invoice (work_order_id, invoice_number, invoice_date, price, gst_percent, gst_amount, amount, "
                      + "attachment, attachment_name, attachment_type, attachment_size, created_by, updated_by) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)",
                        Statement.RETURN_GENERATED_KEYS)) {
                    int i = 1;
                    ps.setInt(i++, woId);
                    ps.setString(i++, invNumber);
                    ps.setDate(i++, Date.valueOf(date));
                    ps.setBigDecimal(i++, price);
                    ps.setBigDecimal(i++, gst);
                    ps.setBigDecimal(i++, gstAmt);
                    ps.setBigDecimal(i++, amount);
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
                String sql = "UPDATE kss_csr_invoice SET work_order_id=?, invoice_number=?, invoice_date=?, price=?, gst_percent=?, "
                           + "gst_amount=?, amount=?, updated_by=?"
                           + (file != null ? ", attachment=?, attachment_name=?, attachment_type=?, attachment_size=?" : "")
                           + " WHERE id=?";
                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    int i = 1;
                    ps.setInt(i++, woId);
                    ps.setString(i++, invNumber);
                    ps.setDate(i++, Date.valueOf(date));
                    ps.setBigDecimal(i++, price);
                    ps.setBigDecimal(i++, gst);
                    ps.setBigDecimal(i++, gstAmt);
                    ps.setBigDecimal(i++, amount);
                    ps.setString(i++, user);
                    if (file != null) {
                        ps.setBytes(i++, file);
                        ps.setString(i++, fileName);
                        ps.setString(i++, fileType);
                        ps.setInt(i++, file.length);
                    }
                    ps.setInt(i, id);
                    if (ps.executeUpdate() == 0) {
                        sendJson(response, 404, fail("Invoice not found. Please reload the page."));
                        return;
                    }
                }
            }
        } catch (SQLIntegrityConstraintViolationException dup) {
            sendJson(response, 409, fail("Invoice Number \"" + invNumber + "\" already exists for work order " + woNumber + "."));
            return;
        }

        JsonObject json = new JsonObject();
        json.addProperty("ok", true);
        json.addProperty("id", id);
        json.addProperty("message", (isNew ? "Invoice added: " : "Invoice updated: ") + invNumber + " (Rs " + amount.toPlainString() + ")");
        sendJson(response, 200, json);
    }

    private void delete(HttpServletRequest request, HttpServletResponse response, Connection con) throws Exception {
        String idParam = trim(request.getParameter("id"));
        if (!idParam.matches("\\d+")) { sendJson(response, 400, fail("Invalid invoice.")); return; }
        int id = Integer.parseInt(idParam);
        String number = null;
        try (PreparedStatement ps = con.prepareStatement("SELECT invoice_number FROM kss_csr_invoice WHERE id = ?")) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) { if (rs.next()) number = rs.getString(1); }
        }
        if (number == null) { sendJson(response, 404, fail("Invoice not found. Please reload the page.")); return; }
        try (PreparedStatement ps = con.prepareStatement("DELETE FROM kss_csr_invoice WHERE id = ?")) {
            ps.setInt(1, id);
            ps.executeUpdate();
        }
        JsonObject json = new JsonObject();
        json.addProperty("ok", true);
        json.addProperty("id", id);
        json.addProperty("message", "Invoice deleted: " + number);
        sendJson(response, 200, json);
    }

    // ================================================================== helpers
    /** Work orders with invoiced amount and invoice count. */
    static List<Map<String, String>> loadWorkOrders(Connection con) throws Exception {
        List<Map<String, String>> list = new ArrayList<>();
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT w.id, w.wo_number, DATE_FORMAT(w.wo_date, '%d-%m-%Y') AS wo_date_txt, w.vendor_name, w.total_amount, "
              + "l.letter_number, COALESCE(SUM(i.amount), 0) AS invoiced, COUNT(i.id) AS inv_count "
              + "FROM kss_csr_work_order w JOIN kss_csr_approval_letter l ON l.id = w.letter_id "
              + "LEFT JOIN kss_csr_invoice i ON i.work_order_id = w.id "
              + "GROUP BY w.id, w.wo_number, w.wo_date, w.vendor_name, w.total_amount, l.letter_number "
              + "ORDER BY w.wo_date DESC, w.id DESC");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, String> m = new LinkedHashMap<>();
                m.put("id", String.valueOf(rs.getInt("id")));
                m.put("woNumber", rs.getString("wo_number"));
                m.put("woDateTxt", rs.getString("wo_date_txt"));
                m.put("vendorName", rs.getString("vendor_name"));
                m.put("total", money2(rs.getBigDecimal("total_amount")));
                m.put("letterNumber", rs.getString("letter_number"));
                m.put("invoiced", money2(rs.getBigDecimal("invoiced")));
                m.put("invCount", String.valueOf(rs.getInt("inv_count")));
                list.add(m);
            }
        }
        return list;
    }

    private static Map<String, String> invMap(ResultSet rs) throws Exception {
        Map<String, String> r = new LinkedHashMap<>();
        r.put("id", String.valueOf(rs.getInt("id")));
        r.put("woId", String.valueOf(rs.getInt("work_order_id")));
        r.put("invoiceNumber", rs.getString("invoice_number"));
        r.put("invoiceDate", rs.getString("inv_date_iso"));
        r.put("invoiceDateTxt", rs.getString("inv_date_txt"));
        r.put("price", money2(rs.getBigDecimal("price")));
        r.put("gst", rs.getBigDecimal("gst_percent").stripTrailingZeros().toPlainString());
        r.put("gstAmount", money2(rs.getBigDecimal("gst_amount")));
        r.put("amount", money2(rs.getBigDecimal("amount")));
        r.put("attachmentName", rs.getString("attachment_name"));
        r.put("attachmentSize", rs.getString("attachment_size"));
        r.put("createdBy", rs.getString("created_by"));
        r.put("createdAt", rs.getString("created_txt"));
        r.put("woNumber", rs.getString("wo_number"));
        r.put("vendorName", rs.getString("vendor_name"));
        r.put("woTotal", money2(rs.getBigDecimal("wo_total")));
        r.put("letterNumber", rs.getString("letter_number"));
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
