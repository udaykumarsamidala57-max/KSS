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
    public static final List<String> TYPES = java.util.Arrays.asList("Tax Invoice", "Proforma");

    // ---- shared SQL pieces (a = alias of kss_csr_invoice)
    /** The proforma has been settled by a tax invoice. */
    static String settled(String a) {
        return "EXISTS (SELECT 1 FROM kss_csr_invoice s WHERE s.proforma_id = " + a + ".id)";
    }
    /** Amount that counts as billed against the work order: tax invoices only (a proforma is an advance, not a bill). */
    public static String counted(String a) {
        return "(CASE WHEN " + a + ".invoice_type = 'Proforma' THEN 0 ELSE " + a + ".amount END)";
    }
    /** Advance already claimed in an FRL on the proforma this tax invoice settles. */
    static String advanceClaimed(String a) {
        return "COALESCE((SELECT pf.claim_amount FROM kss_csr_frl_invoice pf WHERE pf.invoice_id = " + a + ".proforma_id), 0)";
    }
    /** What this invoice can claim in an FRL (if it is not in one yet). A tax invoice marked "FRL: No" claims nothing. */
    public static String claimable(String a) {
        return "(CASE WHEN " + a + ".invoice_type = 'Proforma' THEN (CASE WHEN " + settled(a) + " THEN 0 ELSE " + a + ".amount END) "
             + "WHEN " + a + ".frl_required = 0 THEN 0 "
             + "ELSE " + a + ".amount - " + advanceClaimed(a) + " END)";
    }

    private static final String INV_COLUMNS =
            "i.id, i.work_order_id, i.invoice_type, i.invoice_number, DATE_FORMAT(i.invoice_date, '%Y-%m-%d') AS inv_date_iso, "
          + "DATE_FORMAT(i.invoice_date, '%d-%m-%Y') AS inv_date_txt, i.particulars, i.price, i.gst_percent, i.gst_amount, i.amount, "
          + "i.attachment_name, i.attachment_type, i.attachment_size, i.created_by, "
          + "DATE_FORMAT(i.created_at, '%d-%m-%Y') AS created_txt, "
          + "w.wo_number, w.vendor_name, w.total_amount AS wo_total, w.letter_id, l.letter_number, l.letter_name, "
          + "(SELECT fi.frl_id FROM kss_csr_frl_invoice fi WHERE fi.invoice_id = i.id) AS frl_id, "
          + "(SELECT r.frl_number FROM kss_csr_frl_invoice fi JOIN kss_csr_fund_request r ON r.id = fi.frl_id "
          + "WHERE fi.invoice_id = i.id) AS frl_number, "
          + "(SELECT fi.claim_amount FROM kss_csr_frl_invoice fi WHERE fi.invoice_id = i.id) AS claim_amount, "
          + "i.frl_required, i.proforma_id, (SELECT p.invoice_number FROM kss_csr_invoice p WHERE p.id = i.proforma_id) AS proforma_number, "
          + "(SELECT p.amount FROM kss_csr_invoice p WHERE p.id = i.proforma_id) AS proforma_amount, "
          + "(SELECT s.id FROM kss_csr_invoice s WHERE s.proforma_id = i.id) AS settled_by_id, "
          + "(SELECT s.invoice_number FROM kss_csr_invoice s WHERE s.proforma_id = i.id) AS settled_by_number, "
          + "(SELECT GROUP_CONCAT(p.voucher_no ORDER BY p.payment_date, p.id SEPARATOR ', ') FROM kss_csr_vendor_payment p WHERE p.invoice_id = i.id) AS voucher_no, "
          + advanceClaimed("i") + " AS advance_claimed, " + claimable("i") + " AS claimable";

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
                request.setAttribute("invoices", loadInvoices(con));
            } catch (Exception e) {
                e.printStackTrace();
                request.setAttribute("error", "Database error: " + e.getMessage()
                        + " (Has the kss_csr_invoice table been created?)");
            }
            request.setAttribute("inv", inv);
            request.setAttribute("workOrders", workOrders);
            request.setAttribute("presetWoId", presetWo);
            request.setAttribute("types", TYPES);
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
        String type = trim(request.getParameter("invoiceType"));
        String particulars = trim(request.getParameter("particulars"));
        String proformaS = trim(request.getParameter("proformaId"));
        // tax invoice: raise an FRL for it? ("0" = no, the money already came through the proforma advance)
        int frlRequired = "Tax Invoice".equals(type) && "0".equals(trim(request.getParameter("frlRequired"))) ? 0 : 1;

        if (!TYPES.contains(type)) { sendJson(response, 400, fail("Please select the Invoice Type (Proforma / Tax Invoice).")); return; }
        if (!woParam.matches("\\d+"))  { sendJson(response, 400, fail("Please select the Work Order.")); return; }
        if (invNumber.isEmpty())       { sendJson(response, 400, fail("Please enter the Invoice Number.")); return; }
        if (invNumber.length() > 100)  { sendJson(response, 400, fail("Invoice Number is too long.")); return; }
        if (particulars.length() > 500) { sendJson(response, 400, fail("Particulars is too long (maximum 500 characters).")); return; }
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
        int proformaId = 0;
        if ("Tax Invoice".equals(type) && !proformaS.isEmpty()) {
            if (!proformaS.matches("\\d+")) { sendJson(response, 400, fail("Invalid proforma selection.")); return; }
            proformaId = Integer.parseInt(proformaS);
        }

        if (!isNew) {
            String oldType = null, frl = null, settledBy = null, voucher = null;
            int oldWo = 0, oldPf = 0, oldFrlReq = 1;
            BigDecimal oldAmount = null;
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT i.invoice_type, i.work_order_id, i.amount, COALESCE(i.proforma_id, 0), i.frl_required, "
                  + "(SELECT r.frl_number FROM kss_csr_frl_invoice fi JOIN kss_csr_fund_request r ON r.id = fi.frl_id WHERE fi.invoice_id = i.id), "
                  + "(SELECT s.invoice_number FROM kss_csr_invoice s WHERE s.proforma_id = i.id), "
                  + "(SELECT GROUP_CONCAT(p.voucher_no ORDER BY p.payment_date, p.id SEPARATOR ', ') FROM kss_csr_vendor_payment p WHERE p.invoice_id = i.id) "
                  + "FROM kss_csr_invoice i WHERE i.id = ?")) {
                ps.setInt(1, id);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        oldType = rs.getString(1); oldWo = rs.getInt(2); oldAmount = rs.getBigDecimal(3);
                        oldPf = rs.getInt(4); oldFrlReq = rs.getInt(5); frl = rs.getString(6); settledBy = rs.getString(7);
                        voucher = rs.getString(8);
                    }
                }
            }
            if (oldType == null) { sendJson(response, 404, fail("Invoice not found. Please reload the page.")); return; }
            // a proforma settled by a tax invoice is closed
            if (settledBy != null && (!"Proforma".equals(type) || oldWo != woId || oldAmount.compareTo(amount) != 0)) {
                sendJson(response, 400, fail("This proforma is settled by tax invoice " + settledBy
                        + ", so its type, work order and amount cannot be changed."));
                return;
            }
            // a tax invoice already paid through a payment voucher keeps its type, work order and amount
            if (voucher != null && (!oldType.equals(type) || oldWo != woId || oldAmount.compareTo(amount) != 0)) {
                sendJson(response, 400, fail("This invoice is paid through payment voucher(s) " + voucher
                        + ", so its type, work order and amount cannot be changed. Delete the voucher(s) first."));
                return;
            }
            // an invoice already in an FRL keeps its type, work order, amount and proforma link
            if (frl != null && (!oldType.equals(type) || oldWo != woId || oldAmount.compareTo(amount) != 0 || oldPf != proformaId
                    || oldFrlReq != frlRequired)) {
                sendJson(response, 400, fail("This invoice is included in FRL " + frl
                        + ", so its type, work order, amount, proforma and FRL choice cannot be changed. Remove it from the FRL first."));
                return;
            }
        }

        // ---- the proforma this tax invoice settles
        if (proformaId > 0) {
            String pType = null, pNumber = null, pSettledBy = null;
            int pWo = 0, pSettledId = 0;
            BigDecimal pAmount = null;
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT p.invoice_type, p.invoice_number, p.work_order_id, p.amount, "
                  + "(SELECT s.id FROM kss_csr_invoice s WHERE s.proforma_id = p.id), "
                  + "(SELECT s.invoice_number FROM kss_csr_invoice s WHERE s.proforma_id = p.id) "
                  + "FROM kss_csr_invoice p WHERE p.id = ?")) {
                ps.setInt(1, proformaId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        pType = rs.getString(1); pNumber = rs.getString(2); pWo = rs.getInt(3); pAmount = rs.getBigDecimal(4);
                        pSettledId = rs.getInt(5); pSettledBy = rs.getString(6);
                    }
                }
            }
            if (pType == null || !"Proforma".equals(pType) || proformaId == id) {
                sendJson(response, 400, fail("The selected proforma was not found. Please reload the page."));
                return;
            }
            if (pWo != woId) { sendJson(response, 400, fail("Proforma " + pNumber + " belongs to another work order.")); return; }
            if (pSettledBy != null && pSettledId != id) {
                sendJson(response, 400, fail("Proforma " + pNumber + " is already settled by tax invoice " + pSettledBy + "."));
                return;
            }
            if (amount.compareTo(pAmount) < 0) {
                sendJson(response, 400, fail("Tax invoice amount Rs " + amount.toPlainString() + " is less than the proforma advance Rs "
                        + pAmount.setScale(2, RoundingMode.HALF_UP).toPlainString() + " (" + pNumber + ")."));
                return;
            }
        }

        // ---- budget check: invoices of a work order must not exceed the work order total
        BigDecimal woTotal = null;
        String woNumber = null;
        try (PreparedStatement ps = con.prepareStatement("SELECT total_amount, wo_number FROM kss_csr_work_order WHERE id = ?")) {
            ps.setInt(1, woId);
            try (ResultSet rs = ps.executeQuery()) { if (rs.next()) { woTotal = rs.getBigDecimal(1); woNumber = rs.getString(2); } }
        }
        if (woTotal == null) { sendJson(response, 400, fail("Work order not found. Please reload the page.")); return; }
        // already billed on the work order: tax invoices only (a proforma is an advance, not a bill)
        BigDecimal others;
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT COALESCE(SUM(i.amount), 0) FROM kss_csr_invoice i "
              + "WHERE i.work_order_id = ? AND i.id <> ? AND i.invoice_type = 'Tax Invoice'")) {
            ps.setInt(1, woId);
            ps.setInt(2, id);
            try (ResultSet rs = ps.executeQuery()) { rs.next(); others = rs.getBigDecimal(1); }
        }
        BigDecimal balance = woTotal.subtract(others);
        if (amount.compareTo(balance) > 0) {
            sendJson(response, 400, fail(("Proforma".equals(type) ? "Advance" : "Invoice") + " amount Rs " + amount.toPlainString()
                    + " exceeds the balance Rs " + balance.toPlainString() + " (not yet billed) of work order " + woNumber + "."));
            return;
        }

        try {
            if (isNew) {
                try (PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO kss_csr_invoice (work_order_id, invoice_type, proforma_id, frl_required, invoice_number, invoice_date, particulars, price, gst_percent, gst_amount, amount, "
                      + "attachment, attachment_name, attachment_type, attachment_size, created_by, updated_by) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
                        Statement.RETURN_GENERATED_KEYS)) {
                    int i = 1;
                    ps.setInt(i++, woId);
                    ps.setString(i++, type);
                    if (proformaId > 0) ps.setInt(i++, proformaId); else ps.setNull(i++, java.sql.Types.INTEGER);
                    ps.setInt(i++, frlRequired);
                    ps.setString(i++, invNumber);
                    ps.setDate(i++, Date.valueOf(date));
                    ps.setString(i++, particulars.isEmpty() ? null : particulars);
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
                String sql = "UPDATE kss_csr_invoice SET work_order_id=?, invoice_type=?, proforma_id=?, frl_required=?, invoice_number=?, invoice_date=?, particulars=?, price=?, gst_percent=?, "
                           + "gst_amount=?, amount=?, updated_by=?"
                           + (file != null ? ", attachment=?, attachment_name=?, attachment_type=?, attachment_size=?" : "")
                           + " WHERE id=?";
                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    int i = 1;
                    ps.setInt(i++, woId);
                    ps.setString(i++, type);
                    if (proformaId > 0) ps.setInt(i++, proformaId); else ps.setNull(i++, java.sql.Types.INTEGER);
                    ps.setInt(i++, frlRequired);
                    ps.setString(i++, invNumber);
                    ps.setDate(i++, Date.valueOf(date));
                    ps.setString(i++, particulars.isEmpty() ? null : particulars);
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
            if (dup.getMessage() != null && dup.getMessage().contains("uq_csr_inv_proforma")) {
                sendJson(response, 409, fail("That proforma was just settled by another tax invoice. Please reload the page."));
                return;
            }
            sendJson(response, 409, fail("Invoice Number \"" + invNumber + "\" already exists for work order " + woNumber + "."));
            return;
        }

        JsonObject json = new JsonObject();
        json.addProperty("ok", true);
        json.addProperty("id", id);
        json.addProperty("message", (isNew ? type + " added: " : type + " updated: ") + invNumber + " (Rs " + amount.toPlainString() + ")");
        sendJson(response, 200, json);
    }

    private void delete(HttpServletRequest request, HttpServletResponse response, Connection con) throws Exception {
        String idParam = trim(request.getParameter("id"));
        if (!idParam.matches("\\d+")) { sendJson(response, 400, fail("Invalid invoice.")); return; }
        int id = Integer.parseInt(idParam);
        String number = null, frl = null, settledBy = null, voucher = null;
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT i.invoice_number, (SELECT r.frl_number FROM kss_csr_frl_invoice fi JOIN kss_csr_fund_request r ON r.id = fi.frl_id "
              + "WHERE fi.invoice_id = i.id), (SELECT s.invoice_number FROM kss_csr_invoice s WHERE s.proforma_id = i.id), "
              + "(SELECT GROUP_CONCAT(p.voucher_no ORDER BY p.payment_date, p.id SEPARATOR ', ') FROM kss_csr_vendor_payment p WHERE p.invoice_id = i.id) "
              + "FROM kss_csr_invoice i WHERE i.id = ?")) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) { number = rs.getString(1); frl = rs.getString(2); settledBy = rs.getString(3); voucher = rs.getString(4); }
            }
        }
        if (voucher != null) {
            sendJson(response, 409, fail("Cannot delete " + number + ": it is paid through payment voucher(s) " + voucher + ". Delete the voucher(s) first."));
            return;
        }
        if (settledBy != null) {
            sendJson(response, 409, fail("Cannot delete proforma " + number + ": it is settled by tax invoice " + settledBy + "."));
            return;
        }
        if (number == null) { sendJson(response, 404, fail("Invoice not found. Please reload the page.")); return; }
        if (frl != null) {
            sendJson(response, 409, fail("Cannot delete " + number + ": it is included in FRL " + frl + ". Remove it from the FRL first."));
            return;
        }
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
                "SELECT w.id, w.letter_id, w.wo_number, DATE_FORMAT(w.wo_date, '%d-%m-%Y') AS wo_date_txt, w.vendor_name, w.total_amount, "
              + "l.letter_number, COALESCE(SUM(" + counted("i") + "), 0) AS invoiced, COUNT(i.id) AS inv_count "
              + "FROM kss_csr_work_order w JOIN kss_csr_approval_letter l ON l.id = w.letter_id "
              + "LEFT JOIN kss_csr_invoice i ON i.work_order_id = w.id "
              + "GROUP BY w.id, w.letter_id, w.wo_number, w.wo_date, w.vendor_name, w.total_amount, l.letter_number "
              + "ORDER BY w.wo_date DESC, w.id DESC");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, String> m = new LinkedHashMap<>();
                m.put("id", String.valueOf(rs.getInt("id")));
                m.put("letterId", String.valueOf(rs.getInt("letter_id")));
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

    /** All invoices with their letter and FRL link (used by the FRL form). */
    static List<Map<String, String>> loadInvoices(Connection con) throws Exception {
        List<Map<String, String>> list = new ArrayList<>();
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT " + INV_COLUMNS + INV_FROM + " ORDER BY i.invoice_date, i.id");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(invMap(rs));
        }
        return list;
    }

    private static Map<String, String> invMap(ResultSet rs) throws Exception {
        Map<String, String> r = new LinkedHashMap<>();
        r.put("id", String.valueOf(rs.getInt("id")));
        r.put("woId", String.valueOf(rs.getInt("work_order_id")));
        r.put("invoiceType", rs.getString("invoice_type"));
        r.put("letterId", String.valueOf(rs.getInt("letter_id")));
        r.put("letterName", rs.getString("letter_name"));
        int frlId = rs.getInt("frl_id");
        r.put("frlId", rs.wasNull() ? "" : String.valueOf(frlId));
        r.put("frlNumber", rs.getString("frl_number"));
        r.put("frlRequired", String.valueOf(rs.getInt("frl_required")));
        r.put("claimAmount", rs.getBigDecimal("claim_amount") == null ? "" : money2(rs.getBigDecimal("claim_amount")));
        int pf = rs.getInt("proforma_id");
        r.put("proformaId", rs.wasNull() ? "" : String.valueOf(pf));
        r.put("proformaNumber", rs.getString("proforma_number"));
        r.put("proformaAmount", rs.getBigDecimal("proforma_amount") == null ? "" : money2(rs.getBigDecimal("proforma_amount")));
        int sb = rs.getInt("settled_by_id");
        r.put("settledById", rs.wasNull() ? "" : String.valueOf(sb));
        r.put("settledByNumber", rs.getString("settled_by_number"));
        r.put("advanceClaimed", money2(rs.getBigDecimal("advance_claimed")));
        r.put("claimable", money2(rs.getBigDecimal("claimable")));
        r.put("invoiceNumber", rs.getString("invoice_number"));
        r.put("invoiceDate", rs.getString("inv_date_iso"));
        r.put("invoiceDateTxt", rs.getString("inv_date_txt"));
        r.put("particulars", rs.getString("particulars"));
        r.put("voucherNo", rs.getString("voucher_no"));
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
