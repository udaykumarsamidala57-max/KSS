package com.Controller;

import java.io.IOException;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.time.LocalDate;
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
 * Payment Procedure: Deductions for tax invoices (TDS, retention, debit notes, advance payments).
 * Global role only.
 *
 *  GET  CsrPaymentProcedureServlet[?invoiceId=N]           -> list page (csrPaymentProcedures.jsp)
 *  GET  CsrPaymentProcedureServlet?action=form[&id=N|&invoiceId=N] -> add / edit form
 *  POST action=save   (AJAX)                               -> add / update
 *  POST action=delete (AJAX)                               -> delete
 */
@WebServlet("/CsrPaymentProcedureServlet")
public class CsrPaymentProcedureServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private static final char NBSP = (char) 160;

    private boolean isGlobal(HttpSession sess) {
        String role = (String) sess.getAttribute("role");
        return role != null && "Global".equalsIgnoreCase(role.replace(NBSP, ' ').trim());
    }

    // ---- Shared SQL
    private static final String PP_COLUMNS =
            "pp.id, pp.invoice_id, DATE_FORMAT(pp.payment_date, '%Y-%m-%d') AS payment_date_iso, "
          + "DATE_FORMAT(pp.payment_date, '%d-%m-%Y') AS payment_date_txt, "
          + "pp.debit_note_amount, pp.debit_note_description, pp.tds_amount, pp.retention_amount, pp.advance_paid, "
          + "pp.total_deductions, pp.remarks, pp.created_by, DATE_FORMAT(pp.created_at, '%d-%m-%Y') AS created_txt, "
          + "i.invoice_number, i.amount AS invoice_amount, i.work_order_id, w.wo_number, w.letter_id, l.letter_number";

    private static final String PP_FROM =
            " FROM kss_csr_payment_procedure pp "
          + "JOIN kss_csr_invoice i ON i.id = pp.invoice_id "
          + "JOIN kss_csr_work_order w ON w.id = i.work_order_id "
          + "JOIN kss_csr_approval_letter l ON l.id = w.letter_id";

    private Map<String, String> ppMap(ResultSet rs) throws Exception {
        Map<String, String> m = new LinkedHashMap<>();
        m.put("id", rs.getString("id"));
        m.put("invoiceId", rs.getString("invoice_id"));
        m.put("invoiceNumber", rs.getString("invoice_number"));
        m.put("invoiceAmount", rs.getString("invoice_amount"));
        m.put("woNumber", rs.getString("wo_number"));
        m.put("letterId", rs.getString("letter_id"));
        m.put("letterNumber", rs.getString("letter_number"));
        m.put("paymentDateIso", rs.getString("payment_date_iso"));
        m.put("paymentDateTxt", rs.getString("payment_date_txt"));
        m.put("debitNoteAmount", rs.getString("debit_note_amount"));
        m.put("debitNoteDescription", rs.getString("debit_note_description"));
        m.put("tdsAmount", rs.getString("tds_amount"));
        m.put("retentionAmount", rs.getString("retention_amount"));
        m.put("advancePaid", rs.getString("advance_paid"));
        m.put("totalDeductions", rs.getString("total_deductions"));
        m.put("remarks", rs.getString("remarks"));
        m.put("createdBy", rs.getString("created_by"));
        m.put("createdAt", rs.getString("created_txt"));
        return m;
    }

    private List<Map<String, String>> loadPaymentProcedures(Connection con, int invoiceId) throws Exception {
        List<Map<String, String>> list = new ArrayList<>();
        try (PreparedStatement ps = con.prepareStatement("SELECT " + PP_COLUMNS + PP_FROM + " WHERE pp.invoice_id = ? ORDER BY pp.payment_date DESC, pp.id DESC")) {
            ps.setInt(1, invoiceId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(ppMap(rs));
            }
        }
        return list;
    }

    private List<Map<String, String>> loadTaxInvoices(Connection con) throws Exception {
        List<Map<String, String>> list = new ArrayList<>();
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT i.id, i.invoice_number, DATE_FORMAT(i.invoice_date, '%d-%m-%Y') AS inv_date_txt, "
              + "i.amount, w.wo_number, w.vendor_name, w.letter_id, l.letter_number "
              + "FROM kss_csr_invoice i "
              + "JOIN kss_csr_work_order w ON w.id = i.work_order_id "
              + "JOIN kss_csr_approval_letter l ON l.id = w.letter_id "
              + "WHERE i.invoice_type = 'Tax Invoice' ORDER BY i.id DESC")) {
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, String> m = new LinkedHashMap<>();
                    m.put("id", rs.getString("id"));
                    m.put("invoiceNumber", rs.getString("invoice_number"));
                    m.put("invoiceDateTxt", rs.getString("inv_date_txt"));
                    m.put("amount", rs.getString("amount"));
                    m.put("woNumber", rs.getString("wo_number"));
                    m.put("vendorName", rs.getString("vendor_name"));
                    m.put("letterId", rs.getString("letter_id"));
                    m.put("letterNumber", rs.getString("letter_number"));
                    list.add(m);
                }
            }
        }
        return list;
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

        String invoiceParam = request.getParameter("invoiceId");
        int presetInvoiceId = (invoiceParam != null && invoiceParam.matches("\\d+")) ? Integer.parseInt(invoiceParam) : 0;

        String action = request.getParameter("action");

        if ("form".equals(action)) {
            String idParam = request.getParameter("id");
            Map<String, String> pp = null;
            try (Connection con = DBUtil.getConnection()) {
                if (idParam != null && idParam.matches("\\d+")) {
                    try (PreparedStatement ps = con.prepareStatement("SELECT " + PP_COLUMNS + PP_FROM + " WHERE pp.id = ?")) {
                        ps.setInt(1, Integer.parseInt(idParam));
                        try (ResultSet rs = ps.executeQuery()) { if (rs.next()) pp = ppMap(rs); }
                    }
                    if (pp == null) {
                        response.sendRedirect("CsrPaymentProcedureServlet");
                        return;
                    }
                    presetInvoiceId = Integer.parseInt(pp.get("invoiceId"));
                }
                List<Map<String, String>> taxInvoices = loadTaxInvoices(con);
                request.setAttribute("taxInvoices", taxInvoices);
                request.setAttribute("pp", pp);
                request.setAttribute("presetInvoiceId", presetInvoiceId);
            } catch (Exception e) {
                e.printStackTrace();
                request.setAttribute("error", "Database error: " + e.getMessage());
            }
            request.getRequestDispatcher("/csrPaymentProcedureForm.jsp").forward(request, response);
            return;
        }

        // ---- list
        List<Map<String, String>> procedures = new ArrayList<>();
        List<Map<String, String>> taxInvoices = new ArrayList<>();
        try (Connection con = DBUtil.getConnection()) {
            if (presetInvoiceId > 0) {
                procedures = loadPaymentProcedures(con, presetInvoiceId);
            } else {
                try (PreparedStatement ps = con.prepareStatement("SELECT " + PP_COLUMNS + PP_FROM + " ORDER BY pp.payment_date DESC, pp.id DESC LIMIT 100")) {
                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) procedures.add(ppMap(rs));
                    }
                }
            }
            taxInvoices = loadTaxInvoices(con);
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Database error: " + e.getMessage());
        }
        request.setAttribute("procedures", procedures);
        request.setAttribute("taxInvoices", taxInvoices);
        request.setAttribute("invoiceFilter", presetInvoiceId);
        request.getRequestDispatcher("/csrPaymentProcedures.jsp").forward(request, response);
    }

    // ================================================================== POST
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        response.setContentType("application/json; charset=UTF-8");
        JsonObject res = new JsonObject();

        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            res.addProperty("ok", false);
            res.addProperty("message", "Not logged in");
            response.getWriter().print(res);
            return;
        }
        if (!isGlobal(sess)) {
            res.addProperty("ok", false);
            res.addProperty("message", "Global role required");
            response.getWriter().print(res);
            return;
        }

        String action = request.getParameter("action");
        String username = (String) sess.getAttribute("username");

        if ("delete".equals(action)) {
            String idParam = request.getParameter("id");
            if (idParam == null || !idParam.matches("\\d+")) {
                res.addProperty("ok", false);
                res.addProperty("message", "Invalid ID");
                response.getWriter().print(res);
                return;
            }
            int ppId = Integer.parseInt(idParam);
            try (Connection con = DBUtil.getConnection()) {
                try (PreparedStatement ps = con.prepareStatement("DELETE FROM kss_csr_payment_procedure WHERE id = ?")) {
                    ps.setInt(1, ppId);
                    int rows = ps.executeUpdate();
                    if (rows > 0) {
                        res.addProperty("ok", true);
                        res.addProperty("message", "Payment procedure deleted");
                    } else {
                        res.addProperty("ok", false);
                        res.addProperty("message", "Payment procedure not found");
                    }
                }
            } catch (Exception e) {
                e.printStackTrace();
                res.addProperty("ok", false);
                res.addProperty("message", "Database error: " + e.getMessage());
            }
            response.getWriter().print(res);
            return;
        }

        if ("save".equals(action)) {
            String idParam = request.getParameter("id");
            String invoiceIdParam = request.getParameter("invoiceId");
            String paymentDateStr = request.getParameter("paymentDate");
            String debitNoteAmountStr = request.getParameter("debitNoteAmount");
            String debitNoteDesc = request.getParameter("debitNoteDescription");
            String tdsAmountStr = request.getParameter("tdsAmount");
            String retentionAmountStr = request.getParameter("retentionAmount");
            String advancePaidStr = request.getParameter("advancePaid");
            String remarks = request.getParameter("remarks");

            if (invoiceIdParam == null || !invoiceIdParam.matches("\\d+") || paymentDateStr == null || paymentDateStr.isEmpty()) {
                res.addProperty("ok", false);
                res.addProperty("message", "Invoice and payment date are required");
                response.getWriter().print(res);
                return;
            }

            try {
                int invoiceId = Integer.parseInt(invoiceIdParam);
                Date paymentDate = Date.valueOf(paymentDateStr);
                BigDecimal debitNoteAmount = new BigDecimal(debitNoteAmountStr != null ? debitNoteAmountStr : "0").setScale(2, RoundingMode.HALF_UP);
                BigDecimal tdsAmount = new BigDecimal(tdsAmountStr != null ? tdsAmountStr : "0").setScale(2, RoundingMode.HALF_UP);
                BigDecimal retentionAmount = new BigDecimal(retentionAmountStr != null ? retentionAmountStr : "0").setScale(2, RoundingMode.HALF_UP);
                BigDecimal advancePaid = new BigDecimal(advancePaidStr != null ? advancePaidStr : "0").setScale(2, RoundingMode.HALF_UP);
                BigDecimal totalDeductions = debitNoteAmount.add(tdsAmount).add(retentionAmount).add(advancePaid);

                try (Connection con = DBUtil.getConnection()) {
                    if (idParam != null && idParam.matches("\\d+")) {
                        // Update
                        int ppId = Integer.parseInt(idParam);
                        try (PreparedStatement ps = con.prepareStatement(
                                "UPDATE kss_csr_payment_procedure SET invoice_id=?, payment_date=?, "
                              + "debit_note_amount=?, debit_note_description=?, tds_amount=?, retention_amount=?, advance_paid=?, "
                              + "total_deductions=?, remarks=?, updated_by=?, updated_at=CURRENT_TIMESTAMP WHERE id=?")) {
                            ps.setInt(1, invoiceId);
                            ps.setDate(2, paymentDate);
                            ps.setBigDecimal(3, debitNoteAmount);
                            ps.setString(4, debitNoteDesc);
                            ps.setBigDecimal(5, tdsAmount);
                            ps.setBigDecimal(6, retentionAmount);
                            ps.setBigDecimal(7, advancePaid);
                            ps.setBigDecimal(8, totalDeductions);
                            ps.setString(9, remarks);
                            ps.setString(10, username);
                            ps.setInt(11, ppId);
                            ps.executeUpdate();
                        }
                        res.addProperty("ok", true);
                        res.addProperty("message", "Payment procedure updated");
                        res.addProperty("id", ppId);
                    } else {
                        // Insert
                        try (PreparedStatement ps = con.prepareStatement(
                                "INSERT INTO kss_csr_payment_procedure "
                              + "(invoice_id, payment_date, debit_note_amount, debit_note_description, tds_amount, retention_amount, advance_paid, total_deductions, remarks, created_by) "
                              + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", java.sql.Statement.RETURN_GENERATED_KEYS)) {
                            ps.setInt(1, invoiceId);
                            ps.setDate(2, paymentDate);
                            ps.setBigDecimal(3, debitNoteAmount);
                            ps.setString(4, debitNoteDesc);
                            ps.setBigDecimal(5, tdsAmount);
                            ps.setBigDecimal(6, retentionAmount);
                            ps.setBigDecimal(7, advancePaid);
                            ps.setBigDecimal(8, totalDeductions);
                            ps.setString(9, remarks);
                            ps.setString(10, username);
                            ps.executeUpdate();
                            try (ResultSet keys = ps.getGeneratedKeys()) {
                                if (keys.next()) {
                                    int newId = keys.getInt(1);
                                    res.addProperty("ok", true);
                                    res.addProperty("message", "Payment procedure created");
                                    res.addProperty("id", newId);
                                }
                            }
                        }
                    }
                }
            } catch (Exception e) {
                e.printStackTrace();
                res.addProperty("ok", false);
                res.addProperty("message", "Error: " + e.getMessage());
            }
            response.getWriter().print(res);
            return;
        }

        res.addProperty("ok", false);
        res.addProperty("message", "Unknown action");
        response.getWriter().print(res);
    }
}
