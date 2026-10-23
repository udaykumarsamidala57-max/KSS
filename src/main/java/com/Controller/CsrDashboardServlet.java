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

    /**
     * Company-wise position (owner rules, 2026-10-23), one row per approval, added up per company in Java:
     *   Utilised      = net paid to vendors (advances + amount paid on vouchers) + TDS deducted
     *   Unspent       = received from the company - utilised (negative = paid from own funds, to be claimed)
     *   Bills unpaid  = per work order: balance due on tax invoices less advances not yet adjusted (never below 0)
     *   Free balance  = unspent - retention held - bills unpaid
     */
    private static final String POSITION_SQL =
            "SELECT l.id, l.company_id, l.activity_kind, l.letter_number, l.letter_name, COALESCE(l.particulars, '') AS descr, l.amount AS approved, "
          + "(SELECT COALESCE(SUM(f.amount), 0) FROM kss_csr_fund_receipt f WHERE f.letter_id = l.id) AS received, "
          + "(SELECT COALESCE(SUM(a.amount), 0) FROM kss_csr_vendor_advance a JOIN kss_csr_work_order w ON w.id = a.work_order_id "
          + " WHERE w.letter_id = l.id) AS advances, "
          + "(SELECT COALESCE(SUM(p.net_paid), 0) FROM kss_csr_vendor_payment p JOIN kss_csr_invoice i ON i.id = p.invoice_id "
          + " JOIN kss_csr_work_order w ON w.id = i.work_order_id WHERE w.letter_id = l.id) AS paid, "
          + "(SELECT COALESCE(SUM(p.tds_amount), 0) FROM kss_csr_vendor_payment p JOIN kss_csr_invoice i ON i.id = p.invoice_id "
          + " JOIN kss_csr_work_order w ON w.id = i.work_order_id WHERE w.letter_id = l.id) AS tds, "
          + "(SELECT COALESCE(SUM(p.retention_amount), 0) FROM kss_csr_vendor_payment p JOIN kss_csr_invoice i ON i.id = p.invoice_id "
          + " JOIN kss_csr_work_order w ON w.id = i.work_order_id WHERE w.letter_id = l.id) AS retention, "
          + "(SELECT COALESCE(SUM(GREATEST(0, "
          + "    (SELECT COALESCE(SUM(GREATEST(i.amount - COALESCE((SELECT SUM(" + CsrPaymentServlet.SETTLED + ") "
          + "       FROM kss_csr_vendor_payment p WHERE p.invoice_id = i.id), 0), 0)), 0) "
          + "     FROM kss_csr_invoice i WHERE i.work_order_id = w.id AND i.invoice_type = 'Tax Invoice') "
          + "  - GREATEST(0, (SELECT COALESCE(SUM(a.amount), 0) FROM kss_csr_vendor_advance a WHERE a.work_order_id = w.id) "
          + "     - (SELECT COALESCE(SUM(p.advance_adjusted), 0) FROM kss_csr_vendor_payment p JOIN kss_csr_invoice i ON i.id = p.invoice_id "
          + "        WHERE i.work_order_id = w.id)))), 0) "
          + " FROM kss_csr_work_order w WHERE w.letter_id = l.id) AS unpaid "
          + "FROM kss_csr_approval_letter l";

    /** Money in / out by month: receipts from companies, net paid to vendors (advances + voucher payments), TDS on vouchers. */
    private static final String MONTHLY_SQL =
            "SELECT YEAR(d) AS y, MONTH(d) AS m, SUM(rec) AS rec, SUM(paid) AS paid, SUM(tds) AS tds FROM ("
          + " SELECT receipt_date AS d, amount AS rec, 0 AS paid, 0 AS tds FROM kss_csr_fund_receipt"
          + " UNION ALL SELECT advance_date, 0, amount, 0 FROM kss_csr_vendor_advance"
          + " UNION ALL SELECT payment_date, 0, net_paid, tds_amount FROM kss_csr_vendor_payment"
          + ") x WHERE d IS NOT NULL GROUP BY YEAR(d), MONTH(d) ORDER BY y, m";

    private static final String[] MONTHS = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" };

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

        if ("detail".equals(request.getParameter("action"))) {
            sendDetail(request, response);
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

        try (java.sql.Connection con = DBUtil.getConnection()) {
            request.setAttribute("companyPosition", loadCompanyPosition(con));
            request.setAttribute("unitPosition", loadUnitPosition(con));
            loadMonthly(con, request);
        } catch (Exception e) {
            getServletContext().log("Unable to load company-wise position", e);
            request.setAttribute("companyError", "Company-wise position could not be loaded: " + e.getMessage()
                    + " (Has Dump20261016\\KSS_csr_company.sql been run?)");
        }

        request.setAttribute("stats", stats);
        request.setAttribute("approvalLetters", approvalLetters);
        request.setAttribute("letterStats", letterStats);
        request.setAttribute("selectedLetterId", selectedLetterId);
        request.getRequestDispatcher("/csrDashboard.jsp").forward(request, response);
    }

    /** Rows of the Company-wise Position table, formatted; the last row is the TOTAL. */
    private List<Map<String, String>> loadCompanyPosition(java.sql.Connection con) throws Exception {
        // companies: Active ones and any that fund an approval; key 0 = approvals without a company
        Map<Integer, String> names = new LinkedHashMap<Integer, String>();
        Map<Integer, BigDecimal[]> sums = new LinkedHashMap<Integer, BigDecimal[]>();   // projects, approved, received, utilised, retention, unpaid
        try (java.sql.PreparedStatement ps = con.prepareStatement(
                "SELECT id, COALESCE(NULLIF(short_name, ''), company_name) AS name, status FROM kss_csr_company ORDER BY company_name");
             java.sql.ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                names.put(rs.getInt("id"), rs.getString("name"));
                if ("Active".equals(rs.getString("status"))) sums.put(rs.getInt("id"), zeros());
            }
        }
        try (java.sql.PreparedStatement ps = con.prepareStatement(POSITION_SQL);
             java.sql.ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                int co = rs.getInt("company_id");
                if (rs.wasNull() || !names.containsKey(co)) co = 0;
                BigDecimal[] t = sums.get(co);
                if (t == null) { t = zeros(); sums.put(co, t); }
                add(t, rs);
            }
        }
        List<Map<String, String>> out = new ArrayList<Map<String, String>>();
        BigDecimal[] total = zeros();
        for (Map.Entry<Integer, BigDecimal[]> e : sums.entrySet()) {
            int co = e.getKey();
            out.add(positionRow(co == 0 ? "Company not set" : names.get(co), co == 0 ? "" : String.valueOf(co), e.getValue()));
            for (int k = 0; k < total.length; k++) total[k] = total[k].add(e.getValue()[k]);
        }
        Map<String, String> t = positionRow("TOTAL", "", total);
        t.put("total", "1");
        out.add(t);
        return out;
    }

    /** Rows of the Unit-wise Position table (unit = Kind of CSR Activity of the approval), formatted; the last row is the TOTAL. */
    private List<Map<String, String>> loadUnitPosition(java.sql.Connection con) throws Exception {
        Map<String, String> names = new java.util.TreeMap<String, String>();          // key (lower case) -> name as first entered
        Map<String, BigDecimal[]> sums = new LinkedHashMap<String, BigDecimal[]>();
        try (java.sql.PreparedStatement ps = con.prepareStatement(POSITION_SQL);
             java.sql.ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                String place = rs.getString("activity_kind");
                place = place == null ? "" : place.replace(NBSP, ' ').trim().replaceAll("\\s+", " ");
                if (place.isEmpty()) place = "Not given";
                String key = place.toLowerCase(Locale.ROOT);
                if (!names.containsKey(key)) names.put(key, place);
                BigDecimal[] t = sums.get(key);
                if (t == null) { t = zeros(); sums.put(key, t); }
                add(t, rs);
            }
        }
        List<Map<String, String>> out = new ArrayList<Map<String, String>>();
        BigDecimal[] total = zeros();
        for (Map.Entry<String, String> e : names.entrySet()) {
            BigDecimal[] t = sums.get(e.getKey());
            Map<String, String> r = positionRow(e.getValue(), "", t);
            r.put("unit", e.getValue());
            out.add(r);
            for (int k = 0; k < total.length; k++) total[k] = total[k].add(t[k]);
        }
        Map<String, String> t = positionRow("TOTAL", "", total);
        t.put("total", "1");
        out.add(t);
        return out;
    }

    /**
     * Month-wise Receipts vs Utilisation for one financial year (April to March, ?fy=2026 = 01-Apr-2026 to 31-Mar-2027).
     * Net flow = received - (net paid + TDS); cumulative unspent starts from the unspent before the year.
     */
    private void loadMonthly(java.sql.Connection con, HttpServletRequest request) throws Exception {
        java.time.LocalDate today = java.time.LocalDate.now(java.time.ZoneId.of("Asia/Kolkata"));
        int currentFy = today.getMonthValue() >= 4 ? today.getYear() : today.getYear() - 1;
        int fy = currentFy;
        String fyParam = request.getParameter("fy");
        if (fyParam != null && fyParam.matches("\\d{4}")) fy = Integer.parseInt(fyParam);

        BigDecimal[][] m = new BigDecimal[12][3];                       // index 0 = April; received, net paid, TDS
        for (BigDecimal[] r : m) { r[0] = BigDecimal.ZERO; r[1] = BigDecimal.ZERO; r[2] = BigDecimal.ZERO; }
        BigDecimal opening = BigDecimal.ZERO;
        int firstFy = currentFy;
        try (java.sql.PreparedStatement ps = con.prepareStatement(MONTHLY_SQL);
             java.sql.ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                int y = rs.getInt("y"), mo = rs.getInt("m");
                int rowFy = mo >= 4 ? y : y - 1;
                firstFy = Math.min(firstFy, rowFy);
                BigDecimal rec = zeroIfNull(rs.getBigDecimal("rec")), paid = zeroIfNull(rs.getBigDecimal("paid")),
                           tds = zeroIfNull(rs.getBigDecimal("tds"));
                if (rowFy < fy) opening = opening.add(rec).subtract(paid).subtract(tds);
                else if (rowFy == fy) {
                    int k = (mo + 8) % 12;                                   // Apr -> 0 ... Mar -> 11
                    m[k][0] = m[k][0].add(rec); m[k][1] = m[k][1].add(paid); m[k][2] = m[k][2].add(tds);
                }
            }
        }
        List<Map<String, String>> rows = new ArrayList<Map<String, String>>();
        BigDecimal cum = opening, tr = BigDecimal.ZERO, tp = BigDecimal.ZERO, tt = BigDecimal.ZERO;
        for (int k = 0; k < 12; k++) {
            int month = (k + 3) % 12;                                        // 0-based calendar month
            int year = k < 9 ? fy : fy + 1;
            BigDecimal util = m[k][1].add(m[k][2]), flow = m[k][0].subtract(util);
            cum = cum.add(flow);
            tr = tr.add(m[k][0]); tp = tp.add(m[k][1]); tt = tt.add(m[k][2]);
            Map<String, String> mr = monthRow(MONTHS[month] + "-" + String.valueOf(year).substring(2), m[k][0], m[k][1], m[k][2], cum);
            mr.put("key", year + "-" + (month + 1 < 10 ? "0" : "") + (month + 1));
            rows.add(mr);
        }
        Map<String, String> total = monthRow("FY TOTAL", tr, tp, tt, cum);
        total.put("total", "1");
        total.put("key", "all");
        rows.add(total);

        List<String[]> years = new ArrayList<String[]>();                    // { value, label }
        for (int y = Math.max(currentFy, fy); y >= Math.min(firstFy, fy); y--) {
            years.add(new String[] { String.valueOf(y), y + "-" + String.valueOf(y + 1).substring(2) });
        }
        request.setAttribute("monthly", rows);
        request.setAttribute("monthlyFy", String.valueOf(fy));
        request.setAttribute("monthlyFyStart", "01-Apr-" + fy);
        request.setAttribute("monthlyYears", years);
        request.setAttribute("monthlyOpening", opening.signum() == 0 ? "" : acct(opening));
    }

    private static Map<String, String> monthRow(String label, BigDecimal rec, BigDecimal paid, BigDecimal tds, BigDecimal cum) {
        BigDecimal util = paid.add(tds), flow = rec.subtract(util);
        Map<String, String> r = new LinkedHashMap<String, String>();
        r.put("month", label);
        r.put("received", acct(rec));
        r.put("paid", acct(paid));
        r.put("tds", acct(tds));
        r.put("utilised", acct(util));
        r.put("flow", acct(flow));
        r.put("cumulative", acct(cum));
        r.put("flowNeg", flow.signum() < 0 ? "1" : "");
        r.put("cumNeg", cum.signum() < 0 ? "1" : "");
        return r;
    }

    // ================================================================== popup details (?action=detail)
    /*
     * view = co (key = company id, 0 = not set) | unit (key = Kind of CSR Activity) | month (key = yyyy-mm, fy = year)
     * key = all for the TOTAL row. col = the clicked column. Answer: { ok, title, cols, num, rows, foot } with formatted cells.
     */
    private static final java.util.Set<String> POS_COLS = new java.util.HashSet<String>(java.util.Arrays.asList(
            "projects", "approved", "received", "yetToReceive", "utilised", "unspent", "retention", "unpaid", "free", "utilisation"));
    private static final java.util.Set<String> MONTH_COLS = new java.util.HashSet<String>(java.util.Arrays.asList(
            "received", "paid", "tds", "utilised", "flow", "cumulative"));

    private static final String RECEIPTS_SQL =
            "SELECT * FROM (SELECT f.receipt_date AS d, DATE_FORMAT(f.receipt_date, '%d-%m-%Y') AS dt, CONCAT(l.letter_number, IF(l.letter_name IS NULL OR l.letter_name = '', '', CONCAT(' - ', l.letter_name))) AS letter_number, COALESCE(l.particulars, '') AS descr, "
          + " COALESCE(r.frl_number, '') AS frl, CONCAT(f.payment_mode, IF(f.reference_no IS NULL OR f.reference_no = '', '', CONCAT(' ', f.reference_no))) AS mode, "
          + " f.amount FROM kss_csr_fund_receipt f JOIN kss_csr_approval_letter l ON l.id = f.letter_id "
          + " LEFT JOIN kss_csr_fund_request r ON r.id = f.frl_id WHERE l.id IN (%IDS%)) x WHERE x.d >= ? AND x.d < ? ORDER BY x.d, x.letter_number";

    private static final String OUTFLOW_SQL =
            "SELECT * FROM ("
          + " SELECT a.advance_date AS d, DATE_FORMAT(a.advance_date, '%d-%m-%Y') AS dt, 'Advance' AS kind, "
          + "  COALESCE(a.reference_no, '') AS ref, '' AS bill, w.wo_number, w.vendor_name, CONCAT(l.letter_number, IF(l.letter_name IS NULL OR l.letter_name = '', '', CONCAT(' - ', l.letter_name))) AS letter_number, COALESCE(l.particulars, '') AS descr, a.amount AS net, 0 AS tds "
          + "  FROM kss_csr_vendor_advance a JOIN kss_csr_work_order w ON w.id = a.work_order_id "
          + "  JOIN kss_csr_approval_letter l ON l.id = w.letter_id WHERE l.id IN (%IDS%) "
          + " UNION ALL SELECT p.payment_date, DATE_FORMAT(p.payment_date, '%d-%m-%Y'), 'Payment', p.voucher_no, i.invoice_number, "
          + "  w.wo_number, w.vendor_name, CONCAT(l.letter_number, IF(l.letter_name IS NULL OR l.letter_name = '', '', CONCAT(' - ', l.letter_name))), COALESCE(l.particulars, ''), p.net_paid, p.tds_amount "
          + "  FROM kss_csr_vendor_payment p JOIN kss_csr_invoice i ON i.id = p.invoice_id JOIN kss_csr_work_order w ON w.id = i.work_order_id "
          + "  JOIN kss_csr_approval_letter l ON l.id = w.letter_id WHERE l.id IN (%IDS%)"
          + ") x WHERE x.d >= ? AND x.d < ? ORDER BY x.d, x.ref";

    private static final String RETENTION_SQL =
            "SELECT DATE_FORMAT(p.payment_date, '%d-%m-%Y') AS dt, p.voucher_no, i.invoice_number, w.vendor_name, CONCAT(l.letter_number, IF(l.letter_name IS NULL OR l.letter_name = '', '', CONCAT(' - ', l.letter_name))) AS letter_number, COALESCE(l.particulars, '') AS descr, "
          + " p.retention_percent, p.retention_amount FROM kss_csr_vendor_payment p JOIN kss_csr_invoice i ON i.id = p.invoice_id "
          + " JOIN kss_csr_work_order w ON w.id = i.work_order_id JOIN kss_csr_approval_letter l ON l.id = w.letter_id "
          + " WHERE p.retention_amount <> 0 AND l.id IN (%IDS%) ORDER BY p.payment_date, p.voucher_no";

    private static final String BILLS_DUE_SQL =
            "SELECT i.work_order_id, i.invoice_number, DATE_FORMAT(i.invoice_date, '%d-%m-%Y') AS dt, w.wo_number, w.vendor_name, "
          + " CONCAT(l.letter_number, IF(l.letter_name IS NULL OR l.letter_name = '', '', CONCAT(' - ', l.letter_name))) AS letter_number, COALESCE(l.particulars, '') AS descr, i.amount, COALESCE((SELECT SUM(" + CsrPaymentServlet.SETTLED + ") FROM kss_csr_vendor_payment p "
          + " WHERE p.invoice_id = i.id), 0) AS settled FROM kss_csr_invoice i JOIN kss_csr_work_order w ON w.id = i.work_order_id "
          + " JOIN kss_csr_approval_letter l ON l.id = w.letter_id WHERE i.invoice_type = 'Tax Invoice' AND l.id IN (%IDS%) "
          + " ORDER BY w.wo_number, i.invoice_date, i.id";

    private static final String WO_ADVANCE_SQL =
            "SELECT w.id, w.wo_number, w.vendor_name, "
          + " (SELECT COALESCE(SUM(a.amount), 0) FROM kss_csr_vendor_advance a WHERE a.work_order_id = w.id) "
          + " - (SELECT COALESCE(SUM(p.advance_adjusted), 0) FROM kss_csr_vendor_payment p JOIN kss_csr_invoice i ON i.id = p.invoice_id "
          + "    WHERE i.work_order_id = w.id) AS open_adv FROM kss_csr_work_order w WHERE w.letter_id IN (%IDS%)";

    private void sendDetail(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.setContentType("application/json;charset=UTF-8");
        String view = request.getParameter("view"), key = request.getParameter("key"), col = request.getParameter("col");
        Map<String, Object> out = new LinkedHashMap<String, Object>();
        try (java.sql.Connection con = DBUtil.getConnection()) {
            if (key == null || key.length() > 200) throw new IllegalArgumentException("Invalid selection.");
            if ("month".equals(view)) {
                if (!MONTH_COLS.contains(col)) throw new IllegalArgumentException("Invalid column.");
                String fyParam = request.getParameter("fy");
                if (fyParam == null || !fyParam.matches("\\d{4}")) throw new IllegalArgumentException("Invalid financial year.");
                monthDetail(con, Integer.parseInt(fyParam), key, col, out);
            } else if ("co".equals(view) || "unit".equals(view)) {
                if (!POS_COLS.contains(col)) throw new IllegalArgumentException("Invalid column.");
                positionDetail(con, view, key, col, out);
            } else {
                throw new IllegalArgumentException("Invalid view.");
            }
            out.put("ok", true);
        } catch (IllegalArgumentException bad) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            out.clear(); out.put("ok", false); out.put("message", bad.getMessage());
        } catch (Exception e) {
            getServletContext().log("Unable to load dashboard detail", e);
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            out.clear(); out.put("ok", false); out.put("message", "Details could not be loaded. Please try again.");
        }
        response.getWriter().write(new Gson().toJson(out));
    }

    /** Approval ids of one company / unit (key "all" = every approval). */
    private static String letterIds(java.sql.Connection con, String view, String key) throws Exception {
        java.util.Set<Integer> companies = new java.util.HashSet<Integer>();
        try (java.sql.PreparedStatement ps = con.prepareStatement("SELECT id FROM kss_csr_company");
             java.sql.ResultSet rs = ps.executeQuery()) { while (rs.next()) companies.add(rs.getInt(1)); }
        StringBuilder ids = new StringBuilder();
        String want = "unit".equals(view) ? unitKey(key) : key;
        try (java.sql.PreparedStatement ps = con.prepareStatement("SELECT id, company_id, activity_kind FROM kss_csr_approval_letter");
             java.sql.ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                boolean take;
                if ("all".equals(key)) take = true;
                else if ("co".equals(view)) {
                    int co = rs.getInt("company_id");
                    if (rs.wasNull() || !companies.contains(co)) co = 0;
                    take = String.valueOf(co).equals(want);
                } else take = unitKey(rs.getString("activity_kind")).equals(want);
                if (take) ids.append(ids.length() == 0 ? "" : ",").append(rs.getInt("id"));   // integers only
            }
        }
        return ids.length() == 0 ? "-1" : ids.toString();
    }

    /** Same grouping as loadUnitPosition: case and extra spaces ignored. */
    private static String unitKey(String activity) {
        String a = activity == null ? "" : activity.replace(NBSP, ' ').trim().replaceAll("\\s+", " ");
        return (a.isEmpty() ? "Not given" : a).toLowerCase(Locale.ROOT);
    }

    private void positionDetail(java.sql.Connection con, String view, String key, String col, Map<String, Object> out) throws Exception {
        String ids = letterIds(con, view, key);
        String group = "all".equals(key) ? "All" : ("co".equals(view) ? companyLabel(con, key) : key);
        java.sql.Date from = java.sql.Date.valueOf("1900-01-01"), to = java.sql.Date.valueOf("9999-12-31");
        if ("received".equals(col)) receiptsTable(con, ids, from, to, "Received: " + group, out);
        else if ("utilised".equals(col)) outflowTable(con, ids, from, to, "Utilised: " + group, false, out);
        else if ("retention".equals(col)) retentionTable(con, ids, "Retention Held: " + group, out);
        else if ("unpaid".equals(col)) unpaidTable(con, ids, "Bills Unpaid: " + group, out);
        else approvalsTable(con, ids, group, out);
    }

    private static String companyLabel(java.sql.Connection con, String key) throws Exception {
        if (!key.matches("\\d+") || "0".equals(key)) return "Company not set";
        try (java.sql.PreparedStatement ps = con.prepareStatement(
                "SELECT COALESCE(NULLIF(short_name, ''), company_name) FROM kss_csr_company WHERE id = ?")) {
            ps.setInt(1, Integer.parseInt(key));
            try (java.sql.ResultSet rs = ps.executeQuery()) { return rs.next() ? rs.getString(1) : "Company"; }
        }
    }

    private void monthDetail(java.sql.Connection con, int fy, String key, String col, Map<String, Object> out) throws Exception {
        java.time.LocalDate from, to;
        String label;
        if ("all".equals(key)) {
            from = java.time.LocalDate.of(fy, 4, 1); to = from.plusYears(1);
            label = "FY " + fy + "-" + String.valueOf(fy + 1).substring(2);
        } else if (key.matches("\\d{4}-\\d{2}")) {
            from = java.time.LocalDate.parse(key + "-01"); to = from.plusMonths(1);
            label = MONTHS[from.getMonthValue() - 1] + "-" + String.valueOf(from.getYear()).substring(2);
        } else throw new IllegalArgumentException("Invalid month.");
        String ids = letterIds(con, "co", "all");
        java.sql.Date f = java.sql.Date.valueOf(from), t = java.sql.Date.valueOf(to);
        if ("received".equals(col)) receiptsTable(con, ids, f, t, "Received from Company: " + label, out);
        else if ("paid".equals(col)) outflowTable(con, ids, f, t, "Net Paid to Vendors: " + label, false, out);
        else if ("tds".equals(col)) outflowTable(con, ids, f, t, "TDS Deducted: " + label, true, out);
        else if ("utilised".equals(col)) outflowTable(con, ids, f, t, "Total Utilised: " + label, false, out);
        else if ("flow".equals(col)) flowTable(con, ids, f, t, "Net Flow: " + label, out);
        else cumulativeTable(con, fy, to, "Cumulative Unspent: up to " + label, out);
    }

    // ---- detail tables
    private static void put(Map<String, Object> out, String title, String[] cols, boolean[] num, List<String[]> rows, String[] foot) {
        out.put("title", title);
        out.put("cols", cols);
        out.put("num", num);
        out.put("rows", rows);
        out.put("foot", foot);
    }

    private static java.sql.PreparedStatement prep(java.sql.Connection con, String sql, String ids) throws Exception {
        return con.prepareStatement(sql.replace("%IDS%", ids));
    }

    private static void receiptsTable(java.sql.Connection con, String ids, java.sql.Date from, java.sql.Date to, String title,
                                      Map<String, Object> out) throws Exception {
        List<String[]> rows = new ArrayList<String[]>();
        BigDecimal total = BigDecimal.ZERO;
        try (java.sql.PreparedStatement ps = prep(con, RECEIPTS_SQL, ids)) {
            ps.setDate(1, from); ps.setDate(2, to);
            try (java.sql.ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    BigDecimal a = zeroIfNull(rs.getBigDecimal("amount"));
                    total = total.add(a);
                    rows.add(new String[] { rs.getString("dt"), rs.getString("letter_number"), rs.getString("descr"), rs.getString("frl"), rs.getString("mode"), acct(a) });
                }
            }
        }
        put(out, title, new String[] { "Date", "Management Approval", "Description", "FRL", "Mode / Reference", "Amount" },
            new boolean[] { false, false, false, false, false, true }, rows, new String[] { "Total", "", "", "", "", acct(total) });
    }

    private static void outflowTable(java.sql.Connection con, String ids, java.sql.Date from, java.sql.Date to, String title,
                                     boolean tdsOnly, Map<String, Object> out) throws Exception {
        List<String[]> rows = new ArrayList<String[]>();
        BigDecimal tn = BigDecimal.ZERO, tt = BigDecimal.ZERO;
        try (java.sql.PreparedStatement ps = prep(con, OUTFLOW_SQL, ids)) {
            ps.setDate(1, from); ps.setDate(2, to);
            try (java.sql.ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    BigDecimal n = zeroIfNull(rs.getBigDecimal("net")), t = zeroIfNull(rs.getBigDecimal("tds"));
                    if (tdsOnly && t.signum() == 0) continue;
                    tn = tn.add(n); tt = tt.add(t);
                    String bill = rs.getString("bill");
                    rows.add(new String[] { rs.getString("dt"), rs.getString("kind"), rs.getString("ref"),
                        (bill == null || bill.isEmpty() ? "" : bill + " / ") + rs.getString("wo_number"), rs.getString("vendor_name"),
                        rs.getString("letter_number"), rs.getString("descr"), acct(n), acct(t), acct(n.add(t)) });
                }
            }
        }
        put(out, title, new String[] { "Date", "Type", "Voucher / Ref", "Bill / WO", "Vendor", "Management Approval", "Description", "Net Paid", "TDS", "Utilised" },
            new boolean[] { false, false, false, false, false, false, false, true, true, true }, rows,
            new String[] { "Total", "", "", "", "", "", "", acct(tn), acct(tt), acct(tn.add(tt)) });
    }

    private static void retentionTable(java.sql.Connection con, String ids, String title, Map<String, Object> out) throws Exception {
        List<String[]> rows = new ArrayList<String[]>();
        BigDecimal total = BigDecimal.ZERO;
        try (java.sql.PreparedStatement ps = prep(con, RETENTION_SQL, ids); java.sql.ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                BigDecimal a = zeroIfNull(rs.getBigDecimal("retention_amount"));
                total = total.add(a);
                BigDecimal pc = rs.getBigDecimal("retention_percent");
                rows.add(new String[] { rs.getString("dt"), rs.getString("voucher_no"), rs.getString("invoice_number"), rs.getString("vendor_name"),
                    rs.getString("letter_number"), rs.getString("descr"), pc == null || pc.signum() == 0 ? "" : pc.stripTrailingZeros().toPlainString() + "%", acct(a) });
            }
        }
        put(out, title, new String[] { "Date", "Voucher", "Bill", "Vendor", "Management Approval", "Description", "Rate", "Retention" },
            new boolean[] { false, false, false, false, false, false, true, true }, rows, new String[] { "Total", "", "", "", "", "", "", acct(total) });
    }

    /** Balance due per bill, less advances not yet adjusted on the same work order (as in the position tables). */
    private static void unpaidTable(java.sql.Connection con, String ids, String title, Map<String, Object> out) throws Exception {
        Map<Integer, String[]> wo = new LinkedHashMap<Integer, String[]>();
        Map<Integer, BigDecimal> openAdv = new LinkedHashMap<Integer, BigDecimal>();
        try (java.sql.PreparedStatement ps = prep(con, WO_ADVANCE_SQL, ids); java.sql.ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                wo.put(rs.getInt("id"), new String[] { rs.getString("wo_number"), rs.getString("vendor_name") });
                openAdv.put(rs.getInt("id"), zeroIfNull(rs.getBigDecimal("open_adv")).max(BigDecimal.ZERO));
            }
        }
        Map<Integer, List<String[]>> billRows = new LinkedHashMap<Integer, List<String[]>>();
        Map<Integer, BigDecimal> dueByWo = new LinkedHashMap<Integer, BigDecimal>();
        try (java.sql.PreparedStatement ps = prep(con, BILLS_DUE_SQL, ids); java.sql.ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                BigDecimal amt = zeroIfNull(rs.getBigDecimal("amount")), settled = zeroIfNull(rs.getBigDecimal("settled"));
                BigDecimal due = amt.subtract(settled).max(BigDecimal.ZERO);
                if (due.signum() == 0) continue;
                int w = rs.getInt("work_order_id");
                dueByWo.put(w, (dueByWo.containsKey(w) ? dueByWo.get(w) : BigDecimal.ZERO).add(due));
                if (!billRows.containsKey(w)) billRows.put(w, new ArrayList<String[]>());
                billRows.get(w).add(new String[] { rs.getString("invoice_number"), rs.getString("dt"), rs.getString("wo_number") + " / " + rs.getString("vendor_name"),
                    rs.getString("letter_number"), rs.getString("descr"), acct(amt), acct(settled), acct(due) });
            }
        }
        List<String[]> rows = new ArrayList<String[]>();
        BigDecimal total = BigDecimal.ZERO;
        for (Map.Entry<Integer, List<String[]>> e : billRows.entrySet()) {
            rows.addAll(e.getValue());
            BigDecimal due = dueByWo.get(e.getKey());
            BigDecimal less = openAdv.containsKey(e.getKey()) ? openAdv.get(e.getKey()).min(due) : BigDecimal.ZERO;
            if (less.signum() > 0) {
                String[] w = wo.get(e.getKey());
                rows.add(new String[] { "Less: advance not yet adjusted", "", w[0] + " / " + w[1], "", "", "", "", acct(less.negate()) });
            }
            total = total.add(due.subtract(less));
        }
        put(out, title, new String[] { "Bill", "Date", "Work Order / Vendor", "Management Approval", "Description", "Bill Amount", "Settled", "Unpaid" },
            new boolean[] { false, false, false, false, false, true, true, true }, rows, new String[] { "Total", "", "", "", "", "", "", acct(total) });
    }

    /** Approval-wise breakdown of one company / unit, same columns as the position table. */
    private static void approvalsTable(java.sql.Connection con, String ids, String group, Map<String, Object> out) throws Exception {
        List<String[]> rows = new ArrayList<String[]>();
        BigDecimal[] total = zeros();
        try (java.sql.PreparedStatement ps = con.prepareStatement(POSITION_SQL + " WHERE l.id IN (" + ids + ") ORDER BY l.letter_number");
             java.sql.ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                BigDecimal[] t = zeros();
                add(t, rs);
                for (int k = 0; k < total.length; k++) total[k] = total[k].add(t[k]);
                Map<String, String> r = positionRow("", "", t);
                rows.add(new String[] { rs.getString("letter_number") + " - " + rs.getString("letter_name"), rs.getString("descr"), r.get("approved"), r.get("received"),
                    r.get("yetToReceive"), r.get("utilised"), r.get("unspent"), r.get("retention"), r.get("unpaid"), r.get("free"), r.get("utilisation") });
            }
        }
        Map<String, String> t = positionRow("", "", total);
        put(out, "Management Approvals: " + group + " (" + total[0].toPlainString() + ")",
            new String[] { "Management Approval", "Description", "Approved", "Received", "Yet to Receive", "Utilised", "Unspent", "Retention", "Bills Unpaid", "Free Balance", "Utilisation %" },
            new boolean[] { false, false, true, true, true, true, true, true, true, true, true }, rows,
            new String[] { "Total", "", t.get("approved"), t.get("received"), t.get("yetToReceive"), t.get("utilised"), t.get("unspent"),
                t.get("retention"), t.get("unpaid"), t.get("free"), t.get("utilisation") });
    }

    /** Money in and out in the period, one line per entry. */
    private static void flowTable(java.sql.Connection con, String ids, java.sql.Date from, java.sql.Date to, String title,
                                  Map<String, Object> out) throws Exception {
        List<Object[]> lines = new ArrayList<Object[]>();                 // date (sortable), cells
        try (java.sql.PreparedStatement ps = prep(con, RECEIPTS_SQL, ids)) {
            ps.setDate(1, from); ps.setDate(2, to);
            try (java.sql.ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    BigDecimal a = zeroIfNull(rs.getBigDecimal("amount"));
                    lines.add(new Object[] { rs.getDate("d"), a, BigDecimal.ZERO, new String[] { rs.getString("dt"),
                        "Received" + (rs.getString("frl").isEmpty() ? "" : " against " + rs.getString("frl")), rs.getString("letter_number"), rs.getString("descr") } });
                }
            }
        }
        try (java.sql.PreparedStatement ps = prep(con, OUTFLOW_SQL, ids)) {
            ps.setDate(1, from); ps.setDate(2, to);
            try (java.sql.ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    BigDecimal u = zeroIfNull(rs.getBigDecimal("net")).add(zeroIfNull(rs.getBigDecimal("tds")));
                    lines.add(new Object[] { rs.getDate("d"), BigDecimal.ZERO, u, new String[] { rs.getString("dt"),
                        rs.getString("kind") + " " + rs.getString("ref") + " - " + rs.getString("vendor_name"), rs.getString("letter_number"), rs.getString("descr") } });
                }
            }
        }
        lines.sort((x, y) -> ((java.sql.Date) x[0]).compareTo((java.sql.Date) y[0]));
        List<String[]> rows = new ArrayList<String[]>();
        BigDecimal ti = BigDecimal.ZERO, to2 = BigDecimal.ZERO;
        for (Object[] l : lines) {
            String[] c = (String[]) l[3];
            BigDecimal in = (BigDecimal) l[1], o = (BigDecimal) l[2];
            ti = ti.add(in); to2 = to2.add(o);
            rows.add(new String[] { c[0], c[1], c[2], c[3], acct(in), acct(o) });
        }
        put(out, title, new String[] { "Date", "Particulars", "Management Approval", "Description", "Received", "Utilised (net + TDS)" },
            new boolean[] { false, false, false, false, true, true }, rows,
            new String[] { "Total", "Net Flow (Received - Utilised): " + acct(ti.subtract(to2)), "", "", acct(ti), acct(to2) });
    }

    /** Opening unspent and each month of the year up to the chosen month. */
    private static void cumulativeTable(java.sql.Connection con, int fy, java.time.LocalDate upTo, String title,
                                        Map<String, Object> out) throws Exception {
        java.time.LocalDate start = java.time.LocalDate.of(fy, 4, 1);
        BigDecimal opening = BigDecimal.ZERO;
        Map<String, BigDecimal[]> months = new LinkedHashMap<String, BigDecimal[]>();
        for (java.time.LocalDate d = start; d.isBefore(upTo); d = d.plusMonths(1)) {
            months.put(d.getYear() + "-" + d.getMonthValue(), new BigDecimal[] { BigDecimal.ZERO, BigDecimal.ZERO });
        }
        try (java.sql.PreparedStatement ps = con.prepareStatement(MONTHLY_SQL); java.sql.ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                java.time.LocalDate d = java.time.LocalDate.of(rs.getInt("y"), rs.getInt("m"), 1);
                BigDecimal rec = zeroIfNull(rs.getBigDecimal("rec")),
                           util = zeroIfNull(rs.getBigDecimal("paid")).add(zeroIfNull(rs.getBigDecimal("tds")));
                if (d.isBefore(start)) opening = opening.add(rec).subtract(util);
                else if (d.isBefore(upTo)) {
                    BigDecimal[] m = months.get(d.getYear() + "-" + d.getMonthValue());
                    m[0] = m[0].add(rec); m[1] = m[1].add(util);
                }
            }
        }
        List<String[]> rows = new ArrayList<String[]>();
        rows.add(new String[] { "Opening unspent (before " + "01-04-" + fy + ")", "", "", "", acct(opening) });
        BigDecimal cum = opening;
        for (Map.Entry<String, BigDecimal[]> e : months.entrySet()) {
            String[] ym = e.getKey().split("-");
            BigDecimal flow = e.getValue()[0].subtract(e.getValue()[1]);
            cum = cum.add(flow);
            rows.add(new String[] { MONTHS[Integer.parseInt(ym[1]) - 1] + "-" + ym[0].substring(2), acct(e.getValue()[0]),
                acct(e.getValue()[1]), acct(flow), acct(cum) });
        }
        put(out, title, new String[] { "Month", "Received", "Utilised", "Net Flow", "Cumulative Unspent" },
            new boolean[] { false, true, true, true, true }, rows, new String[] { "Closing", "", "", "", acct(cum) });
    }

    /** Adds one approval row of POSITION_SQL to the totals. */
    private static void add(BigDecimal[] t, java.sql.ResultSet rs) throws Exception {
        t[0] = t[0].add(BigDecimal.ONE);
        t[1] = t[1].add(zeroIfNull(rs.getBigDecimal("approved")));
        t[2] = t[2].add(zeroIfNull(rs.getBigDecimal("received")));
        t[3] = t[3].add(zeroIfNull(rs.getBigDecimal("advances"))).add(zeroIfNull(rs.getBigDecimal("paid")))
                   .add(zeroIfNull(rs.getBigDecimal("tds")));
        t[4] = t[4].add(zeroIfNull(rs.getBigDecimal("retention")));
        t[5] = t[5].add(zeroIfNull(rs.getBigDecimal("unpaid")));
    }

    private static BigDecimal[] zeros() {
        return new BigDecimal[] { BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO };
    }

    private static Map<String, String> positionRow(String name, String id, BigDecimal[] t) {
        BigDecimal approved = t[1], received = t[2], utilised = t[3], retention = t[4], unpaid = t[5];
        BigDecimal unspent = received.subtract(utilised);
        BigDecimal free = unspent.subtract(retention).subtract(unpaid);
        Map<String, String> r = new LinkedHashMap<String, String>();
        r.put("name", name);
        r.put("companyId", id);
        r.put("projects", t[0].toPlainString());
        r.put("approved", acct(approved));
        r.put("received", acct(received));
        r.put("yetToReceive", acct(approved.subtract(received)));
        r.put("utilised", acct(utilised));
        r.put("unspent", acct(unspent));
        r.put("retention", acct(retention));
        r.put("unpaid", acct(unpaid));
        r.put("free", acct(free));
        r.put("unspentNeg", unspent.signum() < 0 ? "1" : "");
        r.put("freeNeg", free.signum() < 0 ? "1" : "");
        r.put("utilisation", approved.signum() == 0 ? "-"
                : utilised.multiply(BigDecimal.valueOf(100)).divide(approved, 1, java.math.RoundingMode.HALF_UP).toPlainString() + "%");
        return r;
    }

    /** Accounts style: Indian grouping, 2 decimals, negative in brackets, zero as "-". */
    private static String acct(BigDecimal v) {
        if (v == null || v.signum() == 0) return "-";
        String s = indian(v.abs());
        return v.signum() < 0 ? "(" + s + ")" : s;
    }

    /** 1234567.5 -> 12,34,567.50 (lakh / crore grouping; Java's en-IN DecimalFormat groups by 3 only). */
    static String indian(BigDecimal v) {
        String plain = v.setScale(2, java.math.RoundingMode.HALF_UP).abs().toPlainString();
        int dot = plain.indexOf('.');
        String whole = plain.substring(0, dot), dec = plain.substring(dot);
        StringBuilder b = new StringBuilder();
        int n = whole.length();
        if (n <= 3) b.append(whole);
        else {
            String head = whole.substring(0, n - 3);
            int first = head.length() % 2 == 0 ? 2 : 1;
            b.append(head, 0, first);
            for (int i = first; i < head.length(); i += 2) b.append(',').append(head, i, i + 2);
            b.append(',').append(whole.substring(n - 3));
        }
        return (v.signum() < 0 ? "-" : "") + b + dec;
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
        BigDecimal v = amount == null ? BigDecimal.ZERO : amount;
        return (v.signum() < 0 ? "-" : "") + "\u20B9" + indian(v.abs());
    }

}
