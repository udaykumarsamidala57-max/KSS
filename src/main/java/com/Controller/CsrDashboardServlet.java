package com.Controller;

import java.io.IOException;
import java.math.BigDecimal;
import java.text.NumberFormat;
import java.util.LinkedHashMap;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.Bean.DBUtil;
import com.google.gson.Gson;

@WebServlet("/CsrDashboardServlet")
public class CsrDashboardServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private static final char NBSP = (char) 160;

    private static final String TOTALS_SQL =
            "SELECT "
          + "(SELECT COUNT(*) FROM kss_csr_approval_letter) AS approval_count, "
          + "(SELECT COALESCE(SUM(amount), 0) FROM kss_csr_approval_letter) AS approved_amount, "
          + "(SELECT COUNT(*) FROM kss_csr_work_order) AS work_order_count, "
          + "(SELECT COALESCE(SUM(total_amount), 0) FROM kss_csr_work_order) AS work_order_amount, "
          + "(SELECT COUNT(*) FROM kss_csr_invoice WHERE invoice_type = 'Tax Invoice') AS tax_invoice_count, "
          + "(SELECT COUNT(*) FROM kss_csr_invoice) AS invoice_count, "
          + "(SELECT COALESCE(SUM(CASE WHEN invoice_type = 'Tax Invoice' THEN amount ELSE 0 END), 0) FROM kss_csr_invoice) AS tax_invoice_amount, "
          + "(SELECT COALESCE(SUM(CASE WHEN invoice_type = 'Proforma' THEN amount ELSE 0 END), 0) FROM kss_csr_invoice) AS proforma_amount, "
          + "(SELECT COUNT(*) FROM kss_csr_fund_request) AS frl_count, "
          + "(SELECT COALESCE(SUM(amount), 0) FROM kss_csr_fund_request) AS frl_amount, "
          + "(SELECT COUNT(*) FROM kss_csr_frl_invoice) AS claim_count, "
          + "(SELECT COALESCE(SUM(claim_amount), 0) FROM kss_csr_frl_invoice) AS claim_amount, "
          + "(SELECT COUNT(*) FROM kss_csr_fund_receipt) AS receipt_count, "
          + "(SELECT COALESCE(SUM(amount), 0) FROM kss_csr_fund_receipt) AS received_amount, "
          + "(SELECT COALESCE(SUM(amount), 0) FROM kss_csr_fund_receipt WHERE frl_id IS NOT NULL) AS frl_received_amount, "
          + "(SELECT COUNT(DISTINCT frl_id) FROM kss_csr_fund_receipt WHERE frl_id IS NOT NULL AND amount > 0) AS frl_received_count, "
          + "(SELECT COUNT(*) FROM kss_csr_vendor_payment) AS payment_count, "
          + "(SELECT COALESCE(SUM(net_paid), 0) FROM kss_csr_vendor_payment) AS payment_amount, "
          + "(SELECT COUNT(*) FROM kss_csr_invoice i WHERE i.invoice_type = 'Tax Invoice' AND i.amount > COALESCE((SELECT SUM(p.net_paid + p.debit_note_amount + p.tds_amount + p.retention_amount + p.advance_adjusted) FROM kss_csr_vendor_payment p WHERE p.invoice_id = i.id), 0)) AS balance_invoice_count, "
          + "(SELECT COALESCE(SUM(GREATEST(i.amount - COALESCE((SELECT SUM(p.net_paid + p.debit_note_amount + p.tds_amount + p.retention_amount + p.advance_adjusted) FROM kss_csr_vendor_payment p WHERE p.invoice_id = i.id), 0), 0)), 0) FROM kss_csr_invoice i WHERE i.invoice_type = 'Tax Invoice') AS balance_to_pay";

    private static final String LETTERS_SQL =
            "SELECT id, letter_number, letter_name FROM kss_csr_approval_letter ORDER BY letter_number";

    private static final String LETTER_TOTALS_SQL =
            "SELECT l.amount AS approved_amount, "
          + "(SELECT COUNT(*) FROM kss_csr_work_order w WHERE w.letter_id = l.id) AS work_order_count, "
          + "(SELECT COALESCE(SUM(w.total_amount), 0) FROM kss_csr_work_order w WHERE w.letter_id = l.id) AS work_order_amount, "
          + "(SELECT COUNT(*) FROM kss_csr_invoice i JOIN kss_csr_work_order w ON w.id = i.work_order_id WHERE w.letter_id = l.id AND i.invoice_type = 'Tax Invoice') AS tax_invoice_count, "
          + "(SELECT COALESCE(SUM(i.amount), 0) FROM kss_csr_invoice i JOIN kss_csr_work_order w ON w.id = i.work_order_id WHERE w.letter_id = l.id AND i.invoice_type = 'Tax Invoice') AS tax_invoice_amount, "
          + "(SELECT COUNT(*) FROM kss_csr_vendor_payment p JOIN kss_csr_invoice i ON i.id = p.invoice_id JOIN kss_csr_work_order w ON w.id = i.work_order_id WHERE w.letter_id = l.id) AS payment_count, "
          + "(SELECT COALESCE(SUM(p.net_paid), 0) FROM kss_csr_vendor_payment p JOIN kss_csr_invoice i ON i.id = p.invoice_id JOIN kss_csr_work_order w ON w.id = i.work_order_id WHERE w.letter_id = l.id) AS payment_amount, "
          + "(SELECT COUNT(*) FROM kss_csr_invoice i JOIN kss_csr_work_order w ON w.id = i.work_order_id WHERE w.letter_id = l.id AND i.invoice_type = 'Tax Invoice' AND i.amount > COALESCE((SELECT SUM(p.net_paid + p.debit_note_amount + p.tds_amount + p.retention_amount + p.advance_adjusted) FROM kss_csr_vendor_payment p WHERE p.invoice_id = i.id), 0)) AS balance_invoice_count, "
          + "(SELECT COALESCE(SUM(GREATEST(i.amount - COALESCE((SELECT SUM(p.net_paid + p.debit_note_amount + p.tds_amount + p.retention_amount + p.advance_adjusted) FROM kss_csr_vendor_payment p WHERE p.invoice_id = i.id), 0), 0)), 0) FROM kss_csr_invoice i JOIN kss_csr_work_order w ON w.id = i.work_order_id WHERE w.letter_id = l.id AND i.invoice_type = 'Tax Invoice') AS balance_to_pay, "
          + "(SELECT COUNT(*) FROM kss_csr_fund_request f WHERE f.letter_id = l.id) AS frl_count, "
          + "(SELECT COALESCE(SUM(f.amount), 0) FROM kss_csr_fund_request f WHERE f.letter_id = l.id) AS frl_amount, "
          + "(SELECT COUNT(DISTINCT r.frl_id) FROM kss_csr_fund_receipt r WHERE r.letter_id = l.id AND r.frl_id IS NOT NULL AND r.amount > 0) AS frl_received_count, "
          + "(SELECT COALESCE(SUM(r.amount), 0) FROM kss_csr_fund_receipt r WHERE r.letter_id = l.id AND r.frl_id IS NOT NULL) AS frl_received_amount "
          + "FROM kss_csr_approval_letter l WHERE l.id = ?";

    private static final String LETTER_PDFS_SQL =
            "SELECT 1 AS sort_order, CONCAT('Management Approval ', letter_number) AS label, pdf_name AS file_name, CONCAT('CsrLetterServlet?action=pdf&id=', id) AS url "
          + "FROM kss_csr_approval_letter WHERE id = ? AND pdf_file IS NOT NULL "
          + "UNION ALL SELECT 2, CONCAT('Work Order ', w.wo_number), w.attachment_name, CONCAT('CsrWorkOrderServlet?action=file&id=', w.id) "
          + "FROM kss_csr_work_order w WHERE w.letter_id = ? AND w.attachment IS NOT NULL AND (LOWER(COALESCE(w.attachment_type,'')) = 'application/pdf' OR LOWER(COALESCE(w.attachment_name,'')) LIKE '%.pdf') "
          + "UNION ALL SELECT 3, CONCAT(i.invoice_type, ' ', i.invoice_number), i.attachment_name, CONCAT('CsrInvoiceServlet?action=file&id=', i.id) "
          + "FROM kss_csr_invoice i JOIN kss_csr_work_order w ON w.id = i.work_order_id WHERE w.letter_id = ? AND i.attachment IS NOT NULL AND (LOWER(COALESCE(i.attachment_type,'')) = 'application/pdf' OR LOWER(COALESCE(i.attachment_name,'')) LIKE '%.pdf') "
          + "UNION ALL SELECT 4, CONCAT('Funds Request Letter ', f.frl_number), f.attachment_name, CONCAT('CsrFrlServlet?action=file&id=', f.id) "
          + "FROM kss_csr_fund_request f WHERE f.letter_id = ? AND f.attachment IS NOT NULL AND (LOWER(COALESCE(f.attachment_type,'')) = 'application/pdf' OR LOWER(COALESCE(f.attachment_name,'')) LIKE '%.pdf') "
          + "UNION ALL SELECT 5, CONCAT('Fund Receipt ', r.id), r.attachment_name, CONCAT('CsrFundServlet?action=file&id=', r.id) "
          + "FROM kss_csr_fund_receipt r WHERE r.letter_id = ? AND r.attachment IS NOT NULL AND (LOWER(COALESCE(r.attachment_type,'')) = 'application/pdf' OR LOWER(COALESCE(r.attachment_name,'')) LIKE '%.pdf') "
          + "UNION ALL SELECT 6, CONCAT('Vendor Advance ', w.wo_number), a.attachment_name, CONCAT('CsrPaymentServlet?action=file&kind=advance&id=', a.id) "
          + "FROM kss_csr_vendor_advance a JOIN kss_csr_work_order w ON w.id = a.work_order_id WHERE w.letter_id = ? AND a.attachment IS NOT NULL AND (LOWER(COALESCE(a.attachment_type,'')) = 'application/pdf' OR LOWER(COALESCE(a.attachment_name,'')) LIKE '%.pdf') "
          + "UNION ALL SELECT 7, CONCAT('Payment Voucher ', p.voucher_no), p.attachment_name, CONCAT('CsrPaymentServlet?action=file&kind=voucher&id=', p.id) "
          + "FROM kss_csr_vendor_payment p JOIN kss_csr_invoice i ON i.id = p.invoice_id JOIN kss_csr_work_order w ON w.id = i.work_order_id WHERE w.letter_id = ? AND p.attachment IS NOT NULL AND (LOWER(COALESCE(p.attachment_type,'')) = 'application/pdf' OR LOWER(COALESCE(p.attachment_name,'')) LIKE '%.pdf') ORDER BY sort_order, label";

    private boolean isGlobal(HttpSession session) {
        String role = (String) session.getAttribute("role");
        return role != null && "Global".equalsIgnoreCase(role.replace(NBSP, ' ').trim());
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return;
        }
        if (!isGlobal(session)) {
            response.sendRedirect("Dashboard.jsp");
            return;
        }

        if ("letterData".equals(request.getParameter("action"))) {
            sendLetterData(request, response);
            return;
        }

        Map<String, String> stats = new LinkedHashMap<String, String>();
        List<Map<String, String>> approvalLetters = new ArrayList<Map<String, String>>();
        Map<String, String> letterStats = new LinkedHashMap<String, String>();
        String selectedLetterId = request.getParameter("letterId");
        BigDecimal approvedAmount = BigDecimal.ZERO;
        BigDecimal workOrderAmount = BigDecimal.ZERO;
        BigDecimal taxInvoiceAmount = BigDecimal.ZERO;
        BigDecimal frlAmount = BigDecimal.ZERO;
        BigDecimal claimAmount = BigDecimal.ZERO;
        BigDecimal receivedAmount = BigDecimal.ZERO;
        try (java.sql.Connection con = DBUtil.getConnection();
             java.sql.PreparedStatement ps = con.prepareStatement(TOTALS_SQL);
             java.sql.ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                stats.put("approvalCount", formatCount(rs.getLong("approval_count")));
                approvedAmount = zeroIfNull(rs.getBigDecimal("approved_amount"));
                stats.put("approvedAmount", formatCurrency(approvedAmount));
                stats.put("workOrderCount", formatCount(rs.getLong("work_order_count")));
                workOrderAmount = zeroIfNull(rs.getBigDecimal("work_order_amount"));
                stats.put("workOrderAmount", formatCurrency(workOrderAmount));
                stats.put("workOrderBalance", formatCurrency(nonNegative(approvedAmount.subtract(workOrderAmount))));
                stats.put("taxInvoiceCount", formatCount(rs.getLong("tax_invoice_count")));
                stats.put("paymentCount", formatCount(rs.getLong("payment_count")));
                stats.put("paymentAmount", formatCurrency(rs.getBigDecimal("payment_amount")));
                stats.put("balanceInvoiceCount", formatCount(rs.getLong("balance_invoice_count")));
                stats.put("balanceToPay", formatCurrency(rs.getBigDecimal("balance_to_pay")));
                stats.put("invoiceCount", formatCount(rs.getLong("invoice_count")));
                taxInvoiceAmount = zeroIfNull(rs.getBigDecimal("tax_invoice_amount"));
                stats.put("taxInvoiceAmount", formatCurrency(taxInvoiceAmount));
                stats.put("proformaAmount", formatCurrency(rs.getBigDecimal("proforma_amount")));
                stats.put("frlCount", formatCount(rs.getLong("frl_count")));
                frlAmount = zeroIfNull(rs.getBigDecimal("frl_amount"));
                stats.put("frlAmount", formatCurrency(frlAmount));
                stats.put("claimCount", formatCount(rs.getLong("claim_count")));
                claimAmount = zeroIfNull(rs.getBigDecimal("claim_amount"));
                stats.put("claimAmount", formatCurrency(claimAmount));
                stats.put("receiptCount", formatCount(rs.getLong("receipt_count")));
                stats.put("frlReceivedCount", formatCount(rs.getLong("frl_received_count")));
                receivedAmount = zeroIfNull(rs.getBigDecimal("received_amount"));
                stats.put("receivedAmount", formatCurrency(receivedAmount));
                BigDecimal frlReceivedAmount = zeroIfNull(rs.getBigDecimal("frl_received_amount"));
                stats.put("frlReceivedAmount", formatCurrency(frlReceivedAmount));
                stats.put("fundsBalance", formatCurrency(nonNegative(frlAmount.subtract(frlReceivedAmount))));
            }
        } catch (Exception e) {
            getServletContext().log("Unable to load KSS CSR dashboard totals", e);
            request.setAttribute("loadError", "Dashboard totals could not be loaded. Please try again.");
        }

        try (java.sql.Connection con = DBUtil.getConnection();
             java.sql.PreparedStatement ps = con.prepareStatement(LETTERS_SQL);
             java.sql.ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, String> letter = new LinkedHashMap<String, String>();
                letter.put("id", String.valueOf(rs.getInt("id")));
                letter.put("number", rs.getString("letter_number"));
                letter.put("name", rs.getString("letter_name"));
                approvalLetters.add(letter);
            }
        } catch (Exception e) {
            getServletContext().log("Unable to load CSR approval letters for dashboard filter", e);
        }

        if (selectedLetterId != null && selectedLetterId.matches("\\d+")) {
            try (java.sql.Connection con = DBUtil.getConnection();
                 java.sql.PreparedStatement ps = con.prepareStatement(LETTER_TOTALS_SQL)) {
                ps.setInt(1, Integer.parseInt(selectedLetterId));
                try (java.sql.ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        BigDecimal letterApproved = zeroIfNull(rs.getBigDecimal("approved_amount"));
                        BigDecimal letterWorkOrders = zeroIfNull(rs.getBigDecimal("work_order_amount"));
                        BigDecimal letterFrls = zeroIfNull(rs.getBigDecimal("frl_amount"));
                        BigDecimal letterReceipts = zeroIfNull(rs.getBigDecimal("frl_received_amount"));
                        letterStats.put("approvedAmount", formatCurrency(letterApproved));
                        letterStats.put("workOrderCount", formatCount(rs.getLong("work_order_count")));
                        letterStats.put("workOrderAmount", formatCurrency(letterWorkOrders));
                        letterStats.put("workOrderBalance", formatCurrency(nonNegative(letterApproved.subtract(letterWorkOrders))));
                        letterStats.put("taxInvoiceCount", formatCount(rs.getLong("tax_invoice_count")));
                        letterStats.put("taxInvoiceAmount", formatCurrency(rs.getBigDecimal("tax_invoice_amount")));
                        letterStats.put("paymentCount", formatCount(rs.getLong("payment_count")));
                        letterStats.put("paymentAmount", formatCurrency(rs.getBigDecimal("payment_amount")));
                        letterStats.put("balanceInvoiceCount", formatCount(rs.getLong("balance_invoice_count")));
                        letterStats.put("balanceToPay", formatCurrency(rs.getBigDecimal("balance_to_pay")));
                        letterStats.put("frlCount", formatCount(rs.getLong("frl_count")));
                        letterStats.put("frlAmount", formatCurrency(letterFrls));
                        letterStats.put("frlReceivedCount", formatCount(rs.getLong("frl_received_count")));
                        letterStats.put("frlReceivedAmount", formatCurrency(letterReceipts));
                        letterStats.put("fundsBalance", formatCurrency(nonNegative(letterFrls.subtract(letterReceipts))));
                    }
                }
            } catch (Exception e) {
                getServletContext().log("Unable to load selected CSR approval totals", e);
            }
        }

        request.setAttribute("stats", stats);
        request.setAttribute("approvalLetters", approvalLetters);
        request.setAttribute("letterStats", letterStats);
        request.setAttribute("selectedLetterId", selectedLetterId);
        request.getRequestDispatcher("/csrDashboard.jsp").forward(request, response);
    }

    private static BigDecimal zeroIfNull(BigDecimal amount) {
        return amount == null ? BigDecimal.ZERO : amount;
    }

    private static BigDecimal nonNegative(BigDecimal amount) {
        return amount.signum() < 0 ? BigDecimal.ZERO : amount;
    }

    private void sendLetterData(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.setContentType("application/json;charset=UTF-8");
        String id = request.getParameter("letterId");
        Map<String, Object> payload = new LinkedHashMap<String, Object>();
        if (id == null || !id.matches("\\d+")) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            payload.put("ok", false);
            payload.put("message", "Select a valid Management Approval.");
            response.getWriter().write(new Gson().toJson(payload));
            return;
        }
        try (java.sql.Connection con = DBUtil.getConnection()) {
            int letterId = Integer.parseInt(id);
            Map<String, String> letterStats = loadLetterStats(con, letterId);
            if (letterStats.isEmpty()) {
                response.setStatus(HttpServletResponse.SC_NOT_FOUND);
                payload.put("ok", false);
                payload.put("message", "Management Approval was not found.");
            } else {
                payload.put("ok", true);
                payload.put("stats", letterStats);
                payload.put("pdfs", loadLetterPdfs(con, letterId));
            }
        } catch (Exception e) {
            getServletContext().log("Unable to load selected CSR approval summary", e);
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            payload.put("ok", false);
            payload.put("message", "Approval details could not be loaded. Please try again.");
        }
        response.getWriter().write(new Gson().toJson(payload));
    }

    private Map<String, String> loadLetterStats(java.sql.Connection con, int letterId) throws Exception {
        Map<String, String> letterStats = new LinkedHashMap<String, String>();
        try (java.sql.PreparedStatement ps = con.prepareStatement(LETTER_TOTALS_SQL)) {
            ps.setInt(1, letterId);
            try (java.sql.ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    BigDecimal approved = zeroIfNull(rs.getBigDecimal("approved_amount"));
                    BigDecimal workOrders = zeroIfNull(rs.getBigDecimal("work_order_amount"));
                    BigDecimal frls = zeroIfNull(rs.getBigDecimal("frl_amount"));
                    BigDecimal receipts = zeroIfNull(rs.getBigDecimal("frl_received_amount"));
                    letterStats.put("approvedAmount", formatCurrency(approved));
                    letterStats.put("workOrderCount", formatCount(rs.getLong("work_order_count")));
                    letterStats.put("workOrderAmount", formatCurrency(workOrders));
                    letterStats.put("workOrderBalance", formatCurrency(nonNegative(approved.subtract(workOrders))));
                    letterStats.put("taxInvoiceCount", formatCount(rs.getLong("tax_invoice_count")));
                    letterStats.put("taxInvoiceAmount", formatCurrency(rs.getBigDecimal("tax_invoice_amount")));
                    letterStats.put("paymentCount", formatCount(rs.getLong("payment_count")));
                    letterStats.put("paymentAmount", formatCurrency(rs.getBigDecimal("payment_amount")));
                    letterStats.put("balanceInvoiceCount", formatCount(rs.getLong("balance_invoice_count")));
                    letterStats.put("balanceToPay", formatCurrency(rs.getBigDecimal("balance_to_pay")));
                    letterStats.put("frlCount", formatCount(rs.getLong("frl_count")));
                    letterStats.put("frlAmount", formatCurrency(frls));
                    letterStats.put("frlReceivedCount", formatCount(rs.getLong("frl_received_count")));
                    letterStats.put("frlReceivedAmount", formatCurrency(receipts));
                    letterStats.put("fundsBalance", formatCurrency(nonNegative(frls.subtract(receipts))));
                }
            }
        }
        return letterStats;
    }

    private List<Map<String, String>> loadLetterPdfs(java.sql.Connection con, int letterId) throws Exception {
        List<Map<String, String>> pdfs = new ArrayList<Map<String, String>>();
        try (java.sql.PreparedStatement ps = con.prepareStatement(LETTER_PDFS_SQL)) {
            for (int i = 1; i <= 7; i++) ps.setInt(i, letterId);
            try (java.sql.ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, String> pdf = new LinkedHashMap<String, String>();
                    pdf.put("label", rs.getString("label"));
                    pdf.put("fileName", rs.getString("file_name"));
                    pdf.put("url", rs.getString("url"));
                    pdfs.add(pdf);
                }
            }
        }
        return pdfs;
    }

    private static String formatCount(long count) {
        return NumberFormat.getIntegerInstance(new Locale("en", "IN")).format(count);
    }

    private static String formatCurrency(BigDecimal amount) {
        NumberFormat format = NumberFormat.getCurrencyInstance(new Locale("en", "IN"));
        format.setMinimumFractionDigits(2);
        format.setMaximumFractionDigits(2);
        return format.format(amount == null ? BigDecimal.ZERO : amount);
    }

}
