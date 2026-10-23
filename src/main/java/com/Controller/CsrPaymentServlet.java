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
 * KSS CSR Amount Spending - Payments to vendors (Global role only).
 * Opened only from the Management Approval page (CsrLetterServlet?action=view&id=N#pay); after saving it returns there.
 *
 *  GET  CsrPaymentServlet?action=voucherForm&invoiceId=N | &id=N      -> payment voucher for a tax invoice
 *  GET  CsrPaymentServlet?action=advanceForm&woId=N | &letterId=N | &id=N -> advance paid to a vendor against a work order
 *  GET  CsrPaymentServlet?action=file&kind=voucher|advance&id=N        -> open the payment proof
 *  POST action=saveVoucher | deleteVoucher | saveAdvance | deleteAdvance (AJAX, multipart for save)
 *
 *  A tax invoice can be paid in parts: one or more vouchers. Each voucher settles
 *     net paid + debit note + TDS + retention + advance adjusted
 *  of the bill; the vouchers of one bill together can never settle more than the bill amount.
 *  Advance adjusted on a work order can never exceed the advances paid on that work order.
 */
@WebServlet("/CsrPaymentServlet")
@MultipartConfig(maxFileSize = 10 * 1024 * 1024, maxRequestSize = 12 * 1024 * 1024)
public class CsrPaymentServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private static final int MAX_FILE_BYTES = 10 * 1024 * 1024;
    private static final char NBSP = (char) 160;
    private static final BigDecimal HUNDRED = new BigDecimal("100");
    private static final BigDecimal MAX_AMOUNT = new BigDecimal("999999999999");

    public static final List<String> MODES = Arrays.asList("NEFT", "RTGS", "IMPS", "UPI", "Cheque", "DD", "Cash", "Other");
    /** TDS sections offered on the voucher: {code, label}. */
    public static final String[][] TDS_SECTIONS = {
        { "194C", "194C - Contractor" },
        { "194J", "194J - Professional / Technical" }
      
    };

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
        } else if ("voucherForm".equals(action)) {
            showVoucherForm(request, response);
        } else if ("advanceForm".equals(action)) {
            showAdvanceForm(request, response);
        } else {
            // everything is reached from the Management Approval page
            response.sendRedirect("CsrLetterServlet");
        }
    }

    private void showVoucherForm(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        int id = intParam(request.getParameter("id"));
        int invoiceId = intParam(request.getParameter("invoiceId"));
        Map<String, String> voucher = null, bill = null;
        try (Connection con = DBUtil.getConnection()) {
            if (id > 0) {
                voucher = one(con, "SELECT p.id, p.invoice_id, p.voucher_no, DATE_FORMAT(p.payment_date, '%Y-%m-%d') AS payment_date, "
                        + "p.bill_amount, p.debit_note_amount, p.debit_note_remarks, p.tds_section, p.tds_percent, p.tds_amount, "
                        + "p.retention_percent, p.retention_amount, p.advance_adjusted, p.net_paid, p.payment_mode, p.reference_no, "
                        + "p.bank_name, p.remarks, p.attachment_name, p.attachment_size, p.created_by, "
                        + "DATE_FORMAT(p.created_at, '%d-%m-%Y') AS created_txt "
                        + "FROM kss_csr_vendor_payment p WHERE p.id = ?", id);
                if (voucher == null) { response.sendRedirect("CsrLetterServlet"); return; }
                invoiceId = Integer.parseInt(voucher.get("invoice_id"));
            }
            bill = loadBill(con, invoiceId, id);
            if (bill == null) { response.sendRedirect("CsrLetterServlet"); return; }
            if (!"Tax Invoice".equals(bill.get("invoice_type"))) {
                response.sendRedirect("CsrLetterServlet?action=view&id=" + bill.get("letter_id") + "#pay");
                return;
            }
            // other vouchers of the same bill (part payments)
            request.setAttribute("others", rows(con,
                    "SELECT p.id, p.voucher_no, DATE_FORMAT(p.payment_date, '%d-%m-%Y') AS payment_date, p.net_paid, "
                  + "p.debit_note_amount, p.tds_amount, p.retention_amount, p.advance_adjusted, " + SETTLED + " AS settled "
                  + "FROM kss_csr_vendor_payment p WHERE p.invoice_id = ? AND p.id <> " + id + " ORDER BY p.payment_date, p.id", invoiceId));
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Database error: " + e.getMessage()
                    + " (Has KSS_csr_vendor_payment.sql been run?)");
        }
        request.setAttribute("voucher", voucher);
        request.setAttribute("bill", bill == null ? new LinkedHashMap<String, String>() : bill);
        request.setAttribute("modes", MODES);
        request.setAttribute("tdsSections", TDS_SECTIONS);
        request.getRequestDispatcher("/csrPaymentVoucherForm.jsp").forward(request, response);
    }

    /** Tax invoice with its work order, letter, particulars and the advance still available on the work order. */
    /** Part of the bill one voucher settles. */
    static final String SETTLED = "(p.net_paid + p.debit_note_amount + p.tds_amount + p.retention_amount + p.advance_adjusted)";

    private static Map<String, String> loadBill(Connection con, int invoiceId, int voucherId) throws Exception {
        Map<String, String> bill = one(con,
                "SELECT i.id, i.invoice_type, i.invoice_number, DATE_FORMAT(i.invoice_date, '%Y-%m-%d') AS invoice_date_iso, "
              + "DATE_FORMAT(i.invoice_date, '%d-%m-%Y') AS invoice_date, i.particulars, i.price, i.gst_percent, i.gst_amount, i.amount, "
              + "i.attachment_size, w.id AS wo_id, w.wo_number, w.vendor_name, w.vendor_gstin, w.total_amount AS wo_total, "
              + "l.id AS letter_id, l.letter_number, l.letter_name, "
              + "(SELECT GROUP_CONCAT(it.particulars ORDER BY it.line_no SEPARATOR '; ') FROM kss_csr_work_order_item it "
              + " WHERE it.work_order_id = w.id) AS wo_particulars, "
              + "(SELECT COALESCE(SUM(a.amount), 0) FROM kss_csr_vendor_advance a WHERE a.work_order_id = w.id) AS adv_paid, "
              + "(SELECT COALESCE(SUM(p.advance_adjusted), 0) FROM kss_csr_vendor_payment p JOIN kss_csr_invoice x ON x.id = p.invoice_id "
              + " WHERE x.work_order_id = w.id AND p.id <> " + voucherId + ") AS adv_adjusted_others, "
              // what the other vouchers of this bill have already settled
              + "(SELECT COALESCE(SUM(" + SETTLED + "), 0) FROM kss_csr_vendor_payment p WHERE p.invoice_id = i.id AND p.id <> " + voucherId + ") AS settled_others, "
              + "(SELECT COALESCE(SUM(p.tds_amount), 0) FROM kss_csr_vendor_payment p WHERE p.invoice_id = i.id AND p.id <> " + voucherId + ") AS tds_others, "
              + "(SELECT COALESCE(SUM(p.retention_amount), 0) FROM kss_csr_vendor_payment p WHERE p.invoice_id = i.id AND p.id <> " + voucherId + ") AS ret_others, "
              + "(SELECT COALESCE(SUM(p.debit_note_amount), 0) FROM kss_csr_vendor_payment p WHERE p.invoice_id = i.id AND p.id <> " + voucherId + ") AS dn_others "
              + "FROM kss_csr_invoice i JOIN kss_csr_work_order w ON w.id = i.work_order_id "
              + "JOIN kss_csr_approval_letter l ON l.id = w.letter_id WHERE i.id = ?", invoiceId);
        return bill;
    }

    private void showAdvanceForm(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        int id = intParam(request.getParameter("id"));
        int woId = intParam(request.getParameter("woId"));
        int letterId = intParam(request.getParameter("letterId"));
        Map<String, String> adv = null;
        List<Map<String, String>> workOrders = new ArrayList<>();
        try (Connection con = DBUtil.getConnection()) {
            if (id > 0) {
                adv = one(con, "SELECT a.id, a.work_order_id, DATE_FORMAT(a.advance_date, '%Y-%m-%d') AS advance_date, a.amount, "
                        + "a.payment_mode, a.reference_no, a.bank_name, a.remarks, a.attachment_name, a.attachment_size "
                        + "FROM kss_csr_vendor_advance a WHERE a.id = ?", id);
                if (adv == null) { response.sendRedirect("CsrLetterServlet"); return; }
                woId = Integer.parseInt(adv.get("work_order_id"));
            }
            if (woId > 0) {
                Map<String, String> w = one(con, "SELECT letter_id FROM kss_csr_work_order WHERE id = ?", woId);
                if (w == null) { response.sendRedirect("CsrLetterServlet"); return; }
                letterId = Integer.parseInt(w.get("letter_id"));
            }
            if (letterId <= 0) { response.sendRedirect("CsrLetterServlet"); return; }
            Map<String, String> letter = one(con, "SELECT id, letter_number, letter_name FROM kss_csr_approval_letter WHERE id = ?", letterId);
            if (letter == null) { response.sendRedirect("CsrLetterServlet"); return; }
            request.setAttribute("letter", letter);
            workOrders = rows(con,
                    "SELECT w.id, w.wo_number, w.vendor_name, w.total_amount, "
                  + "(SELECT COALESCE(SUM(a.amount), 0) FROM kss_csr_vendor_advance a WHERE a.work_order_id = w.id) AS adv_paid, "
                  + "(SELECT COALESCE(SUM(p.advance_adjusted), 0) FROM kss_csr_vendor_payment p JOIN kss_csr_invoice x ON x.id = p.invoice_id "
                  + " WHERE x.work_order_id = w.id) AS adv_adjusted "
                  + "FROM kss_csr_work_order w WHERE w.letter_id = ? ORDER BY w.wo_date, w.id", letterId);
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Database error: " + e.getMessage()
                    + " (Has KSS_csr_vendor_payment.sql been run?)");
        }
        if (request.getAttribute("letter") == null) request.setAttribute("letter", new LinkedHashMap<String, String>());
        request.setAttribute("adv", adv);
        request.setAttribute("workOrders", workOrders);
        request.setAttribute("presetWoId", woId > 0 ? String.valueOf(woId) : "");
        request.setAttribute("modes", MODES);
        request.getRequestDispatcher("/csrVendorAdvanceForm.jsp").forward(request, response);
    }

    private void streamFile(HttpServletRequest request, HttpServletResponse response) throws IOException {
        int id = intParam(request.getParameter("id"));
        String kind = request.getParameter("kind");
        String table = "advance".equals(kind) ? "kss_csr_vendor_advance" : "voucher".equals(kind) ? "kss_csr_vendor_payment" : null;
        if (id <= 0 || table == null) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid file.");
            return;
        }
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(
                     "SELECT attachment, attachment_name, attachment_type FROM " + table + " WHERE id = ?")) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                byte[] data = rs.next() ? rs.getBytes("attachment") : null;
                if (data == null) {
                    response.sendError(HttpServletResponse.SC_NOT_FOUND, "File not found.");
                    return;
                }
                String type = rs.getString("attachment_type");
                String name = rs.getString("attachment_name");
                if (name == null || name.trim().isEmpty()) name = "Payment_" + id;
                name = name.replaceAll("[^A-Za-z0-9._-]", "_");
                response.setContentType(type == null ? "application/octet-stream" : type);
                response.setContentLength(data.length);
                response.setHeader("Content-Disposition", "inline; filename=\"" + name + "\"");
                response.getOutputStream().write(data);
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Could not open the file.");
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
            sendJson(response, 403, fail("Only Global users can manage vendor payments."));
            return;
        }
        String user = (String) sess.getAttribute("username");

        try (Connection con = DBUtil.getConnection()) {
            String action = request.getParameter("action");
            con.setAutoCommit(false);
            try {
                boolean ok;
                if ("saveVoucher".equals(action))        ok = saveVoucher(request, response, con, user);
                else if ("deleteVoucher".equals(action)) ok = deleteVoucher(request, response, con);
                else if ("saveAdvance".equals(action))   ok = saveAdvance(request, response, con, user);
                else if ("deleteAdvance".equals(action)) ok = deleteAdvance(request, response, con);
                else { sendJson(response, 400, fail("Unknown action.")); ok = false; }
                if (ok) con.commit(); else con.rollback();
            } catch (Exception e) {
                con.rollback();
                throw e;
            } finally {
                con.setAutoCommit(true);
            }
        } catch (IllegalStateException tooBig) {
            sendJson(response, 400, fail("The file is too large (maximum 10 MB)."));
        } catch (Exception e) {
            e.printStackTrace();
            sendJson(response, 500, fail("Database error: " + e.getMessage()));
        }
    }

    // ---------------------------------------------------------------- payment voucher
    private boolean saveVoucher(HttpServletRequest request, HttpServletResponse response, Connection con, String user) throws Exception {
        int id = 0;
        String idParam = trim(request.getParameter("id"));
        if (!idParam.isEmpty()) {
            id = intParam(idParam);
            if (id <= 0) { sendJson(response, 400, fail("Invalid payment voucher.")); return false; }
        }
        int invoiceId = intParam(request.getParameter("invoiceId"));
        if (id > 0) {
            // the bill of a saved voucher never changes
            Map<String, String> old = one(con, "SELECT invoice_id FROM kss_csr_vendor_payment WHERE id = ? FOR UPDATE", id);
            if (old == null) { sendJson(response, 404, fail("Payment voucher not found. Please reload the page.")); return false; }
            invoiceId = Integer.parseInt(old.get("invoice_id"));
        }
        if (invoiceId <= 0) { sendJson(response, 400, fail("Please open the voucher from a tax invoice.")); return false; }

        // lock the work order so two vouchers cannot use the same advance at the same time
        Map<String, String> wo = one(con, "SELECT w.id FROM kss_csr_work_order w JOIN kss_csr_invoice i ON i.work_order_id = w.id "
                + "WHERE i.id = ? FOR UPDATE", invoiceId);
        if (wo == null) { sendJson(response, 404, fail("Tax invoice not found. Please reload the page.")); return false; }
        Map<String, String> bill = loadBill(con, invoiceId, id);
        if (bill == null) { sendJson(response, 404, fail("Tax invoice not found. Please reload the page.")); return false; }
        if (!"Tax Invoice".equals(bill.get("invoice_type"))) {
            sendJson(response, 400, fail("A payment voucher can be made only for a tax invoice, not for a proforma invoice."));
            return false;
        }

        String voucherNo = trim(request.getParameter("voucherNo"));
        String dateS = trim(request.getParameter("paymentDate"));
        String dnRemarks = trim(request.getParameter("debitNoteRemarks"));
        String tdsSection = trim(request.getParameter("tdsSection"));
        String mode = trim(request.getParameter("paymentMode"));
        String refNo = trim(request.getParameter("referenceNo"));
        String bank = trim(request.getParameter("bankName"));
        String remarks = trim(request.getParameter("remarks"));

        if (voucherNo.isEmpty())      { sendJson(response, 400, fail("Please enter the Voucher No.")); return false; }
        if (voucherNo.length() > 100) { sendJson(response, 400, fail("Voucher No is too long.")); return false; }
        LocalDate date;
        try { date = LocalDate.parse(dateS); } catch (Exception e) { sendJson(response, 400, fail("Please enter a valid Payment Date.")); return false; }
        LocalDate billDate = LocalDate.parse(bill.get("invoice_date_iso"));
        if (date.isBefore(billDate)) {
            sendJson(response, 400, fail("Payment Date cannot be before the bill date " + bill.get("invoice_date") + "."));
            return false;
        }
        if (!MODES.contains(mode))    { sendJson(response, 400, fail("Please select the Payment Mode.")); return false; }
        if (refNo.length() > 100 || bank.length() > 150 || remarks.length() > 500 || dnRemarks.length() > 500) {
            sendJson(response, 400, fail("One of the fields is too long."));
            return false;
        }

        BigDecimal billAmount = new BigDecimal(bill.get("amount"));
        BigDecimal price = new BigDecimal(bill.get("price"));
        BigDecimal dn = money(request.getParameter("debitNoteAmount"));
        BigDecimal tdsPct = money(request.getParameter("tdsPercent"));
        BigDecimal tds = money(request.getParameter("tdsAmount"));
        BigDecimal retPct = money(request.getParameter("retentionPercent"));
        BigDecimal ret = money(request.getParameter("retentionAmount"));
        BigDecimal adv = money(request.getParameter("advanceAdjusted"));
        BigDecimal net = money(request.getParameter("netPaid"));
        if (dn == null || tdsPct == null || tds == null || retPct == null || ret == null || adv == null || net == null) {
            sendJson(response, 400, fail("Please enter the amounts in numbers only."));
            return false;
        }
        if (dn.signum() < 0 || tds.signum() < 0 || ret.signum() < 0 || adv.signum() < 0 || tdsPct.signum() < 0 || retPct.signum() < 0
                || net.signum() < 0) {
            sendJson(response, 400, fail("Amount paid and deductions cannot be negative."));
            return false;
        }
        if (dn.signum() > 0 && dnRemarks.isEmpty()) {
            sendJson(response, 400, fail("Please enter the reason for the Debit Note."));
            return false;
        }
        BigDecimal settledOthers = new BigDecimal(bill.get("settled_others"));
        BigDecimal tdsOthers = new BigDecimal(bill.get("tds_others"));
        BigDecimal retOthers = new BigDecimal(bill.get("ret_others"));
        BigDecimal due = billAmount.subtract(settledOthers);   // still to settle on this bill before this voucher
        if (tdsSection.isEmpty()) {
            if (tds.signum() > 0 || tdsPct.signum() > 0) { sendJson(response, 400, fail("Please select the TDS Section.")); return false; }
        } else {
            boolean known = false;
            for (String[] s : TDS_SECTIONS) if (s[0].equals(tdsSection)) known = true;
            if (!known) { sendJson(response, 400, fail("Please select a valid TDS Section.")); return false; }
            if (tds.signum() <= 0) { sendJson(response, 400, fail("Please enter the TDS Amount, or set TDS Section to Not deducted.")); return false; }
        }
        if (tdsPct.compareTo(HUNDRED) > 0 || retPct.compareTo(HUNDRED) > 0) {
            sendJson(response, 400, fail("TDS % and Retention % must be between 0 and 100."));
            return false;
        }
        if (tds.add(tdsOthers).compareTo(price) > 0) {
            sendJson(response, 400, fail("Total TDS on this bill " + inr(tds.add(tdsOthers)) + " cannot be more than the taxable value "
                    + inr(price) + (tdsOthers.signum() > 0 ? " (" + inr(tdsOthers) + " already deducted in earlier vouchers)." : ".")));
            return false;
        }
        if (ret.add(retOthers).compareTo(billAmount) > 0) {
            sendJson(response, 400, fail("Total retention on this bill " + inr(ret.add(retOthers)) + " cannot be more than the bill amount "
                    + inr(billAmount) + "."));
            return false;
        }
        BigDecimal advAvailable = new BigDecimal(bill.get("adv_paid")).subtract(new BigDecimal(bill.get("adv_adjusted_others")));
        if (adv.compareTo(advAvailable) > 0) {
            sendJson(response, 400, fail("Advance adjusted " + inr(adv) + " is more than the advance available "
                    + inr(advAvailable) + " on work order " + bill.get("wo_number") + "."));
            return false;
        }
        BigDecimal settles = net.add(dn).add(tds).add(ret).add(adv);
        if (settles.signum() <= 0) {
            sendJson(response, 400, fail("Please enter the Amount Paid Now or a deduction."));
            return false;
        }
        if (settles.compareTo(due) > 0) {
            sendJson(response, 400, fail("This voucher settles " + inr(settles) + " but only " + inr(due) + " is due on bill "
                    + bill.get("invoice_number") + (settledOthers.signum() > 0 ? " (" + inr(settledOthers) + " settled by earlier vouchers)." : ".")));
            return false;
        }
        BigDecimal dueAfter = due.subtract(settles);
        if (tdsSection.isEmpty()) tdsPct = BigDecimal.ZERO.setScale(2);

        // ---- payment proof (optional)
        byte[] file = null;
        String fileName = null, fileType = null;
        Part part = request.getPart("attachment");
        if (part != null && part.getSize() > 0) {
            if (part.getSize() > MAX_FILE_BYTES) { sendJson(response, 400, fail("The file is too large (maximum 10 MB).")); return false; }
            file = readAll(part.getInputStream());
            fileType = detectType(file);
            if (fileType == null) { sendJson(response, 400, fail("Payment proof must be a PDF, JPG or PNG file.")); return false; }
            fileName = cleanName(part.getSubmittedFileName());
        }

        boolean isNew = id == 0;
        try {
            if (isNew) {
                try (PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO kss_csr_vendor_payment (invoice_id, voucher_no, payment_date, bill_amount, debit_note_amount, debit_note_remarks, "
                      + "tds_section, tds_percent, tds_amount, retention_percent, retention_amount, advance_adjusted, net_paid, payment_mode, "
                      + "reference_no, bank_name, remarks, attachment, attachment_name, attachment_type, attachment_size, created_by, updated_by) "
                      + "VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)", Statement.RETURN_GENERATED_KEYS)) {
                    int i = 1;
                    ps.setInt(i++, invoiceId);
                    i = setVoucherFields(ps, i, voucherNo, date, billAmount, dn, dnRemarks, tdsSection, tdsPct, tds, retPct, ret, adv, net,
                            mode, refNo, bank, remarks);
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
                String sql = "UPDATE kss_csr_vendor_payment SET voucher_no=?, payment_date=?, bill_amount=?, debit_note_amount=?, debit_note_remarks=?, "
                           + "tds_section=?, tds_percent=?, tds_amount=?, retention_percent=?, retention_amount=?, advance_adjusted=?, net_paid=?, "
                           + "payment_mode=?, reference_no=?, bank_name=?, remarks=?, updated_by=?"
                           + (file != null ? ", attachment=?, attachment_name=?, attachment_type=?, attachment_size=?" : "")
                           + " WHERE id=?";
                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    int i = setVoucherFields(ps, 1, voucherNo, date, billAmount, dn, dnRemarks, tdsSection, tdsPct, tds, retPct, ret, adv, net,
                            mode, refNo, bank, remarks);
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
        } catch (SQLIntegrityConstraintViolationException dup) {
            String m = dup.getMessage() == null ? "" : dup.getMessage();
            sendJson(response, 409, fail(m.contains("uq_csr_pay_voucher") || m.toLowerCase().contains("duplicate")
                    ? "Voucher No \"" + voucherNo + "\" already exists." : "Could not save the voucher: " + m));
            return false;
        }

        JsonObject json = new JsonObject();
        json.addProperty("ok", true);
        json.addProperty("id", id);
        json.addProperty("letterId", bill.get("letter_id"));
        json.addProperty("message", (isNew ? "Payment voucher saved: " : "Payment voucher updated: ") + voucherNo
                + " (paid " + inr(net) + "; " + (dueAfter.signum() == 0 ? "bill " + bill.get("invoice_number") + " fully paid"
                        : "balance due on bill " + bill.get("invoice_number") + " " + inr(dueAfter)) + ")");
        sendJson(response, 200, json);
        return true;
    }

    private static int setVoucherFields(PreparedStatement ps, int i, String voucherNo, LocalDate date, BigDecimal billAmount,
            BigDecimal dn, String dnRemarks, String tdsSection, BigDecimal tdsPct, BigDecimal tds, BigDecimal retPct, BigDecimal ret,
            BigDecimal adv, BigDecimal net, String mode, String refNo, String bank, String remarks) throws Exception {
        ps.setString(i++, voucherNo);
        ps.setDate(i++, Date.valueOf(date));
        ps.setBigDecimal(i++, billAmount);
        ps.setBigDecimal(i++, dn);
        ps.setString(i++, dn.signum() > 0 ? dnRemarks : null);
        ps.setString(i++, tdsSection.isEmpty() ? null : tdsSection);
        ps.setBigDecimal(i++, tdsPct);
        ps.setBigDecimal(i++, tds);
        ps.setBigDecimal(i++, retPct);
        ps.setBigDecimal(i++, ret);
        ps.setBigDecimal(i++, adv);
        ps.setBigDecimal(i++, net);
        ps.setString(i++, mode);
        ps.setString(i++, refNo.isEmpty() ? null : refNo);
        ps.setString(i++, bank.isEmpty() ? null : bank);
        ps.setString(i++, remarks.isEmpty() ? null : remarks);
        return i;
    }

    private boolean deleteVoucher(HttpServletRequest request, HttpServletResponse response, Connection con) throws Exception {
        int id = intParam(request.getParameter("id"));
        if (id <= 0) { sendJson(response, 400, fail("Invalid payment voucher.")); return false; }
        Map<String, String> v = one(con, "SELECT voucher_no FROM kss_csr_vendor_payment WHERE id = ? FOR UPDATE", id);
        if (v == null) { sendJson(response, 404, fail("Payment voucher not found. Please reload the page.")); return false; }
        try (PreparedStatement ps = con.prepareStatement("DELETE FROM kss_csr_vendor_payment WHERE id = ?")) {
            ps.setInt(1, id);
            ps.executeUpdate();
        }
        JsonObject json = new JsonObject();
        json.addProperty("ok", true);
        json.addProperty("id", id);
        json.addProperty("message", "Payment voucher deleted: " + v.get("voucher_no"));
        sendJson(response, 200, json);
        return true;
    }

    // ---------------------------------------------------------------- advance to vendor
    private boolean saveAdvance(HttpServletRequest request, HttpServletResponse response, Connection con, String user) throws Exception {
        int id = 0;
        String idParam = trim(request.getParameter("id"));
        if (!idParam.isEmpty()) {
            id = intParam(idParam);
            if (id <= 0) { sendJson(response, 400, fail("Invalid advance.")); return false; }
        }
        int woId = intParam(request.getParameter("woId"));
        String dateS = trim(request.getParameter("advanceDate"));
        String mode = trim(request.getParameter("paymentMode"));
        String refNo = trim(request.getParameter("referenceNo"));
        String bank = trim(request.getParameter("bankName"));
        String remarks = trim(request.getParameter("remarks"));
        BigDecimal amount = money(request.getParameter("amount"));

        if (woId <= 0) { sendJson(response, 400, fail("Please select the Work Order.")); return false; }
        LocalDate date;
        try { date = LocalDate.parse(dateS); } catch (Exception e) { sendJson(response, 400, fail("Please enter a valid Advance Date.")); return false; }
        if (amount == null || amount.signum() <= 0 || amount.compareTo(MAX_AMOUNT) > 0) {
            sendJson(response, 400, fail("Please enter a valid Advance Amount."));
            return false;
        }
        if (!MODES.contains(mode)) { sendJson(response, 400, fail("Please select the Payment Mode.")); return false; }
        if (refNo.length() > 100 || bank.length() > 150 || remarks.length() > 500) {
            sendJson(response, 400, fail("One of the fields is too long."));
            return false;
        }

        int oldWo = 0;
        BigDecimal oldAmount = BigDecimal.ZERO;
        if (id > 0) {
            Map<String, String> old = one(con, "SELECT work_order_id, amount FROM kss_csr_vendor_advance WHERE id = ? FOR UPDATE", id);
            if (old == null) { sendJson(response, 404, fail("Advance not found. Please reload the page.")); return false; }
            oldWo = Integer.parseInt(old.get("work_order_id"));
            oldAmount = new BigDecimal(old.get("amount"));
        }
        Map<String, String> w = lockWorkOrder(con, woId);
        if (w == null) { sendJson(response, 400, fail("Work order not found. Please reload the page.")); return false; }
        if (oldWo > 0 && oldWo != woId) {
            Map<String, String> ow = lockWorkOrder(con, oldWo);
            if (ow != null && new BigDecimal(ow.get("adv_paid")).subtract(oldAmount).compareTo(new BigDecimal(ow.get("adv_adjusted"))) < 0) {
                sendJson(response, 400, fail("This advance is already adjusted against bills of work order " + ow.get("wo_number")
                        + ", so it cannot be moved to another work order."));
                return false;
            }
        }
        BigDecimal othersPaid = new BigDecimal(w.get("adv_paid")).subtract(oldWo == woId ? oldAmount : BigDecimal.ZERO);
        BigDecimal adjusted = new BigDecimal(w.get("adv_adjusted"));
        BigDecimal woTotal = new BigDecimal(w.get("total_amount"));
        if (othersPaid.add(amount).compareTo(woTotal) > 0) {
            sendJson(response, 400, fail("Total advance " + inr(othersPaid.add(amount)) + " would be more than the value "
                    + inr(woTotal) + " of work order " + w.get("wo_number") + "."));
            return false;
        }
        if (othersPaid.add(amount).compareTo(adjusted) < 0) {
            sendJson(response, 400, fail(inr(adjusted) + " of advance is already adjusted against bills of work order "
                    + w.get("wo_number") + ". The total advance cannot be less than that."));
            return false;
        }

        byte[] file = null;
        String fileName = null, fileType = null;
        Part part = request.getPart("attachment");
        if (part != null && part.getSize() > 0) {
            if (part.getSize() > MAX_FILE_BYTES) { sendJson(response, 400, fail("The file is too large (maximum 10 MB).")); return false; }
            file = readAll(part.getInputStream());
            fileType = detectType(file);
            if (fileType == null) { sendJson(response, 400, fail("Payment proof must be a PDF, JPG or PNG file.")); return false; }
            fileName = cleanName(part.getSubmittedFileName());
        }

        boolean isNew = id == 0;
        if (isNew) {
            try (PreparedStatement ps = con.prepareStatement(
                    "INSERT INTO kss_csr_vendor_advance (work_order_id, advance_date, amount, payment_mode, reference_no, bank_name, remarks, "
                  + "attachment, attachment_name, attachment_type, attachment_size, created_by, updated_by) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)",
                    Statement.RETURN_GENERATED_KEYS)) {
                int i = 1;
                ps.setInt(i++, woId);
                ps.setDate(i++, Date.valueOf(date));
                ps.setBigDecimal(i++, amount);
                ps.setString(i++, mode);
                ps.setString(i++, refNo.isEmpty() ? null : refNo);
                ps.setString(i++, bank.isEmpty() ? null : bank);
                ps.setString(i++, remarks.isEmpty() ? null : remarks);
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
            String sql = "UPDATE kss_csr_vendor_advance SET work_order_id=?, advance_date=?, amount=?, payment_mode=?, reference_no=?, "
                       + "bank_name=?, remarks=?, updated_by=?"
                       + (file != null ? ", attachment=?, attachment_name=?, attachment_type=?, attachment_size=?" : "")
                       + " WHERE id=?";
            try (PreparedStatement ps = con.prepareStatement(sql)) {
                int i = 1;
                ps.setInt(i++, woId);
                ps.setDate(i++, Date.valueOf(date));
                ps.setBigDecimal(i++, amount);
                ps.setString(i++, mode);
                ps.setString(i++, refNo.isEmpty() ? null : refNo);
                ps.setString(i++, bank.isEmpty() ? null : bank);
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
        JsonObject json = new JsonObject();
        json.addProperty("ok", true);
        json.addProperty("id", id);
        json.addProperty("letterId", w.get("letter_id"));
        json.addProperty("message", (isNew ? "Advance saved: " : "Advance updated: ") + inr(amount)
                + " to " + w.get("vendor_name") + " (" + w.get("wo_number") + ")");
        sendJson(response, 200, json);
        return true;
    }

    private boolean deleteAdvance(HttpServletRequest request, HttpServletResponse response, Connection con) throws Exception {
        int id = intParam(request.getParameter("id"));
        if (id <= 0) { sendJson(response, 400, fail("Invalid advance.")); return false; }
        Map<String, String> a = one(con, "SELECT work_order_id, amount FROM kss_csr_vendor_advance WHERE id = ? FOR UPDATE", id);
        if (a == null) { sendJson(response, 404, fail("Advance not found. Please reload the page.")); return false; }
        Map<String, String> w = lockWorkOrder(con, Integer.parseInt(a.get("work_order_id")));
        BigDecimal remaining = new BigDecimal(w.get("adv_paid")).subtract(new BigDecimal(a.get("amount")));
        if (remaining.compareTo(new BigDecimal(w.get("adv_adjusted"))) < 0) {
            sendJson(response, 409, fail("Cannot delete: " + inr(new BigDecimal(w.get("adv_adjusted"))) + " of advance is already adjusted against bills of work order "
                    + w.get("wo_number") + ". Reduce the advance adjusted in those payment vouchers first."));
            return false;
        }
        try (PreparedStatement ps = con.prepareStatement("DELETE FROM kss_csr_vendor_advance WHERE id = ?")) {
            ps.setInt(1, id);
            ps.executeUpdate();
        }
        JsonObject json = new JsonObject();
        json.addProperty("ok", true);
        json.addProperty("id", id);
        json.addProperty("message", "Advance deleted: " + inr(new BigDecimal(a.get("amount"))) + " (" + w.get("wo_number") + ")");
        sendJson(response, 200, json);
        return true;
    }

    /** Locks the work order row and returns its advance figures. */
    private static Map<String, String> lockWorkOrder(Connection con, int woId) throws Exception {
        if (one(con, "SELECT id FROM kss_csr_work_order WHERE id = ? FOR UPDATE", woId) == null) return null;
        return one(con, "SELECT w.id, w.letter_id, w.wo_number, w.vendor_name, w.total_amount, "
                + "(SELECT COALESCE(SUM(a.amount), 0) FROM kss_csr_vendor_advance a WHERE a.work_order_id = w.id) AS adv_paid, "
                + "(SELECT COALESCE(SUM(p.advance_adjusted), 0) FROM kss_csr_vendor_payment p JOIN kss_csr_invoice x ON x.id = p.invoice_id "
                + " WHERE x.work_order_id = w.id) AS adv_adjusted "
                + "FROM kss_csr_work_order w WHERE w.id = ?", woId);
    }

    // ================================================================== helpers
    /** Runs a query with one int parameter; every column becomes a string (money with 2 decimals). */
    static List<Map<String, String>> rows(Connection con, String sql, int param) throws Exception {
        List<Map<String, String>> list = new ArrayList<>();
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, param);
            try (ResultSet rs = ps.executeQuery()) {
                java.sql.ResultSetMetaData md = rs.getMetaData();
                while (rs.next()) {
                    Map<String, String> m = new LinkedHashMap<>();
                    for (int c = 1; c <= md.getColumnCount(); c++) {
                        Object v = rs.getObject(c);
                        String val;
                        if (v == null) val = null;
                        else if (v instanceof BigDecimal) val = ((BigDecimal) v).setScale(2, RoundingMode.HALF_UP).toPlainString();
                        else if (v instanceof byte[]) val = new String((byte[]) v, java.nio.charset.StandardCharsets.UTF_8);
                        else val = String.valueOf(v);
                        m.put(md.getColumnLabel(c), val);
                    }
                    list.add(m);
                }
            }
        }
        return list;
    }

    private static Map<String, String> one(Connection con, String sql, int param) throws Exception {
        List<Map<String, String>> list = rows(con, sql, param);
        return list.isEmpty() ? null : list.get(0);
    }

    /** Indian format: 1,23,456.78 with the rupee sign. */
    static String inr(BigDecimal v) {
        if (v == null) v = BigDecimal.ZERO;
        v = v.setScale(2, RoundingMode.HALF_UP);
        String plain = v.abs().toPlainString();
        String whole = plain.substring(0, plain.indexOf('.')), dec = plain.substring(plain.indexOf('.'));
        StringBuilder out = new StringBuilder();
        int len = whole.length();
        for (int i = 0; i < len; i++) {
            out.append(whole.charAt(i));
            int left = len - 1 - i;
            if (left > 0 && (left == 3 || (left > 3 && (left - 3) % 2 == 0))) out.append(',');
        }
        return (v.signum() < 0 ? "-" : "") + "\u20B9 " + out + dec;
    }

    private static int intParam(String s) {
        s = trim(s);
        if (!s.matches("\\d{1,9}")) return 0;
        return Integer.parseInt(s);
    }

    /** Empty means 0; returns null when it is not a number. Always 2 decimals. */
    private static BigDecimal money(String s) {
        s = trim(s).replace(",", "");
        if (s.isEmpty()) return BigDecimal.ZERO.setScale(2);
        try {
            BigDecimal v = new BigDecimal(s);
            if (v.abs().compareTo(MAX_AMOUNT) > 0) return null;
            return v.setScale(2, RoundingMode.HALF_UP);
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private static String cleanName(String name) {
        if (name == null) return null;
        name = name.replaceAll("^.*[\\\\/]", "");
        return name.length() > 255 ? name.substring(name.length() - 255) : name;
    }

    private static String detectType(byte[] d) {
        if (d.length > 4 && d[0] == '%' && d[1] == 'P' && d[2] == 'D' && d[3] == 'F') return "application/pdf";
        if (d.length > 3 && (d[0] & 0xFF) == 0xFF && (d[1] & 0xFF) == 0xD8 && (d[2] & 0xFF) == 0xFF) return "image/jpeg";
        if (d.length > 8 && (d[0] & 0xFF) == 0x89 && d[1] == 'P' && d[2] == 'N' && d[3] == 'G') return "image/png";
        return null;
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
