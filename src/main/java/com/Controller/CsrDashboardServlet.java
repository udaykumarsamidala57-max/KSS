package com.Controller;

import java.io.IOException;
import java.io.OutputStream;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.text.NumberFormat;
import java.text.SimpleDateFormat;
import java.util.LinkedHashMap;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellStyle;
import org.apache.poi.ss.usermodel.Font;
import org.apache.poi.ss.usermodel.HorizontalAlignment;
import org.apache.poi.ss.usermodel.VerticalAlignment;
import org.apache.poi.ss.usermodel.BorderStyle;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

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
    /** 1 April of the current financial year (April to March), worked out by MySQL. */
    private static final String FY_START_SQL = "(MAKEDATE(YEAR(CURDATE()) - (MONTH(CURDATE()) < 4), 1) + INTERVAL 3 MONTH)";

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
          + " FROM kss_csr_work_order w WHERE w.letter_id = l.id) AS unpaid, "
          + "(SELECT COALESCE(SUM(f.amount), 0) FROM kss_csr_fund_receipt f WHERE f.letter_id = l.id AND f.receipt_date < " + FY_START_SQL + ") AS received_opening, "
          + "(SELECT COUNT(*) FROM kss_csr_work_order w WHERE w.letter_id = l.id) AS wo_count, "
          + "(SELECT COALESCE(SUM(w.total_amount), 0) FROM kss_csr_work_order w WHERE w.letter_id = l.id) AS wo_total, "
          + "(SELECT COALESCE(SUM(i.amount), 0) FROM kss_csr_invoice i JOIN kss_csr_work_order w ON w.id = i.work_order_id "
          + " WHERE w.letter_id = l.id AND i.invoice_type = 'Tax Invoice') AS billed "
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
        if ("detailExcel".equals(request.getParameter("action"))) {
            exportDetailToExcel(request, response);
            return;
        }
        if ("exportExcel".equals(request.getParameter("action"))) {
            exportDashboardToExcel(request, response);
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
            request.setAttribute("projectPosition", loadProjectPosition(con));
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
            "projects", "approved", "received", "yetToReceive", "utilised", "unspent", "retention", "unpaid", "free", "utilisation",
            "receivedOpening", "receivedCurrent", "woAmount", "invoiced", "invoicePaid", "toBill"));
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
            buildDetail(con, request, out);
            out.remove("ids");
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

    /** Validates view / key / col [/ fy] and fills the pop-up table (shared by the JSON pop-up and its Excel download). */
    private void buildDetail(java.sql.Connection con, HttpServletRequest request, Map<String, Object> out) throws Exception {
        String view = request.getParameter("view"), key = request.getParameter("key"), col = request.getParameter("col");
        if (key == null || key.length() > 200) throw new IllegalArgumentException("Invalid selection.");
        if ("month".equals(view)) {
            if (!MONTH_COLS.contains(col)) throw new IllegalArgumentException("Invalid column.");
            String fyParam = request.getParameter("fy");
            if (fyParam == null || !fyParam.matches("\\d{4}")) throw new IllegalArgumentException("Invalid financial year.");
            monthDetail(con, Integer.parseInt(fyParam), key, col, out);
        } else if ("co".equals(view) || "unit".equals(view) || "proj".equals(view)) {
            if (!POS_COLS.contains(col)) throw new IllegalArgumentException("Invalid column.");
            positionDetail(con, view, key, col, out);
        } else {
            throw new IllegalArgumentException("Invalid view.");
        }
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
                else if ("proj".equals(view)) take = String.valueOf(rs.getInt("id")).equals(want);
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
        String group = "all".equals(key) ? "All" : ("co".equals(view) ? companyLabel(con, key)
                     : "proj".equals(view) ? projectLabel(con, key) : key);
        java.sql.Date from = java.sql.Date.valueOf("1900-01-01"), to = java.sql.Date.valueOf("9999-12-31");
        java.time.LocalDate today = java.time.LocalDate.now(java.time.ZoneId.of("Asia/Kolkata"));
        java.sql.Date fyStart = java.sql.Date.valueOf(java.time.LocalDate.of(today.getMonthValue() >= 4 ? today.getYear() : today.getYear() - 1, 4, 1));
        if ("received".equals(col)) receiptsTable(con, ids, from, to, "Received: " + group, out);
        else if ("receivedOpening".equals(col)) receiptsTable(con, ids, from, fyStart, "Received before " + fyStart.toLocalDate().format(java.time.format.DateTimeFormatter.ofPattern("dd-MM-yyyy")) + ": " + group, out);
        else if ("receivedCurrent".equals(col)) receiptsTable(con, ids, fyStart, to, "Received this financial year: " + group, out);
        else if ("utilised".equals(col)) outflowTable(con, ids, from, to, "Utilised: " + group, false, out);
        else if ("retention".equals(col)) retentionTable(con, ids, "Retention Held: " + group, out);
        else if ("unpaid".equals(col)) unpaidTable(con, ids, "Bills Unpaid: " + group, out);
        else {
            approvalsTable(con, ids, group, out);
            if ("woAmount".equals(col)) out.put("title", "2. Work Orders: " + group);
            else if ("invoicePaid".equals(col)) out.put("title", "3. Payment: " + group);
        }
    }

    private static String projectLabel(java.sql.Connection con, String key) throws Exception {
        if (!key.matches("\\d+")) return "Project";
        try (java.sql.PreparedStatement ps = con.prepareStatement("SELECT letter_number FROM kss_csr_approval_letter WHERE id = ?")) {
            ps.setInt(1, Integer.parseInt(key));
            try (java.sql.ResultSet rs = ps.executeQuery()) { return rs.next() ? rs.getString(1) : "Project"; }
        }
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
                rows.add(positionCells(rs.getString("letter_number") + " - " + rs.getString("letter_name"), rs.getString("descr"), r));
            }
        }
        Map<String, String> t = positionRow("", "", total);
        // same layout as the Company-wise / Unit-wise Position tables (owner request 2026-11-04)
        java.time.LocalDate today = java.time.LocalDate.now(java.time.ZoneId.of("Asia/Kolkata"));
        int fyYear = today.getMonthValue() >= 4 ? today.getYear() : today.getYear() - 1;
        String fyLabel = fyYear + "-" + String.valueOf(fyYear + 1).substring(2);
        put(out, "Management Approvals: " + group + " (" + total[0].toPlainString() + ")",
            new String[] { "Management Approval", "Description",
                "Approved", "Received – Opening", "Received – Current", "Received", "Yet to Receive", "% to Receive",
                "Work Order Amount", "Invoice Raised", "Balance to be Billed",
                "Invoice Received", "Amount Paid", "Balance to Pay",
                "Total Received", "Paid to Vendors", "Balance" },
            new boolean[] { false, false, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true }, rows,
            positionCells("Total", "", t));
        out.put("sub", new String[] { "", "", "", "till 31-03-" + fyYear, "FY " + fyLabel, "Total", "", "", "", "", "", "", "", "", "", "", "" });
        // g = first column of a group (left rule), k = key column of a group (bold)
        out.put("cls", new String[] { "", "", "g", "", "", "k", "", "", "g", "", "k", "g", "", "k", "g", "", "k" });
        out.put("ids", ids);   // for the Excel download only (removed from the JSON reply)
        out.put("groups", new Object[][] { { "", 1 }, { "1. Budget", 6 }, { "2. Work Orders", 3 }, { "3. Payment", 3 }, { "4. Received from Sponsor", 3 } });
    }

    /** One row of the approvals pop-up, in the column order of the position tables. */
    private static String[] positionCells(String name, String descr, Map<String, String> r) {
        return new String[] { name, descr,
            r.get("approved"), r.get("receivedOpening"), r.get("receivedCurrent"), r.get("received"), r.get("yetToReceive"), r.get("yetToReceivePct"),
            r.get("woAmount"), r.get("invoiced"), r.get("toBill"),
            r.get("invoiced"), r.get("invoicePaid"), r.get("unpaid"),
            r.get("received"), r.get("utilised"), r.get("unspent") };
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

    /**
     * Project-wise Position: one row per Management Approval (entry order), plus TOTAL.
     * Status: no work orders = Not started; work orders fully billed and nothing unpaid = Completed; else Work in progress.
     * Alert (first that applies): utilised above approved; own funds advanced (unspent < 0);
     * commitments above funds (free balance < 0); completed with free balance = surplus.
     */
    private List<Map<String, String>> loadProjectPosition(java.sql.Connection con) throws Exception {
        List<Map<String, String>> out = new ArrayList<Map<String, String>>();
        BigDecimal[] total = zeros();
        try (java.sql.PreparedStatement ps = con.prepareStatement(POSITION_SQL + " ORDER BY l.id");
             java.sql.ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                BigDecimal[] t = zeros();
                add(t, rs);
                for (int k = 0; k < total.length; k++) total[k] = total[k].add(t[k]);
                Map<String, String> r = positionRow(rs.getString("letter_name"), "", t);
                r.put("key", String.valueOf(rs.getInt("id")));
                r.put("projectId", rs.getString("letter_number"));
                r.put("unit", rs.getString("activity_kind"));
                r.put("descr", rs.getString("descr"));
                BigDecimal woTotal = zeroIfNull(rs.getBigDecimal("wo_total")), billed = zeroIfNull(rs.getBigDecimal("billed"));
                String status;
                if (rs.getInt("wo_count") == 0) status = "Not started";
                else if (billed.compareTo(woTotal) >= 0 && t[5].signum() == 0) status = "Completed";
                else status = "Work in progress";
                r.put("status", status);
                BigDecimal approved = t[1], unspent = t[2].subtract(t[3]), free = unspent.subtract(t[4]).subtract(t[5]);
                String alert = "";
                if (t[3].compareTo(approved) > 0) alert = "Spent more than approved";
                else if (unspent.signum() < 0) alert = "Own funds advanced \u2013 claim from company";
                else if (free.signum() < 0) alert = "Commitments exceed funds \u2013 request funds";
                else if ("Completed".equals(status) && free.signum() > 0) alert = "Surplus \u2013 refund / adjust with company";
                r.put("alert", alert);
                r.put("alertBad", alert.startsWith("Surplus") ? "" : (alert.isEmpty() ? "" : "1"));
                out.add(r);
            }
        }
        Map<String, String> t = positionRow("TOTAL", "", total);
        t.put("total", "1");
        t.put("key", "all");
        out.add(t);
        return out;
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
        t[6] = t[6].add(zeroIfNull(rs.getBigDecimal("received_opening")));
        t[7] = t[7].add(zeroIfNull(rs.getBigDecimal("wo_total")));
        t[8] = t[8].add(zeroIfNull(rs.getBigDecimal("billed")));
    }

    private static BigDecimal[] zeros() {
        // projects, approved, received, utilised, retention, unpaid, received before this FY, work order value, tax invoices
        BigDecimal[] z = new BigDecimal[9];
        java.util.Arrays.fill(z, BigDecimal.ZERO);
        return z;
    }

    private static Map<String, String> positionRow(String name, String id, BigDecimal[] t) {
        BigDecimal approved = t[1], received = t[2], utilised = t[3], retention = t[4], unpaid = t[5];
        BigDecimal unspent = received.subtract(utilised);
        BigDecimal free = unspent.subtract(retention).subtract(unpaid);
        BigDecimal yetToReceive = approved.subtract(received);
        Map<String, String> r = new LinkedHashMap<String, String>();
        r.put("name", name);
        r.put("companyId", id);
        r.put("projects", t[0].toPlainString());
        r.put("approved", acct(approved));
        r.put("received", acct(received));
        r.put("receivedPct", approved.signum() == 0 ? "-"
                : received.multiply(BigDecimal.valueOf(100)).divide(approved, 1, java.math.RoundingMode.HALF_UP).toPlainString() + "%");
        r.put("yetToReceive", acct(yetToReceive));
        r.put("yetToReceivePct", approved.signum() == 0 ? "-"
                : yetToReceive.multiply(BigDecimal.valueOf(100)).divide(approved, 1, java.math.RoundingMode.HALF_UP).toPlainString() + "%");
        r.put("utilised", acct(utilised));
        r.put("unspent", acct(unspent));
        r.put("retention", acct(retention));
        r.put("unpaid", acct(unpaid));
        r.put("free", acct(free));
        r.put("unspentNeg", unspent.signum() < 0 ? "1" : "");
        r.put("freeNeg", free.signum() < 0 ? "1" : "");
        // owner layout (2026-11-03): Budget / Invoicing / Received from Sponsor
        r.put("receivedOpening", acct(t[6]));
        r.put("receivedCurrent", acct(received.subtract(t[6])));
        r.put("woAmount", acct(t[7]));
        r.put("invoiced", acct(t[8]));
        r.put("invoicePaid", acct(t[8].subtract(unpaid)));   // balance to pay = Bills Unpaid
        BigDecimal toBill = t[7].subtract(t[8]);              // work order value not yet billed in tax invoices
        r.put("toBill", acct(toBill));
        r.put("toBillNeg", toBill.signum() < 0 ? "1" : "");
        r.put("utilisation", approved.signum() == 0 ? "-"
                : utilised.multiply(BigDecimal.valueOf(100)).divide(approved, 1, java.math.RoundingMode.HALF_UP).toPlainString() + "%");
        return r;
    }

    /** Accounts style: Indian grouping, 2 decimals, negative in brackets, zero as "-". */
    private static String acct(BigDecimal v) {
        if (v == null || v.setScale(0, java.math.RoundingMode.HALF_UP).signum() == 0) return "-";   // e.g. 0.46 shows as nil
        String s = indian(v.abs());
        return v.signum() < 0 ? "(" + s + ")" : s;
    }

    /**
     * 1234567.5 -> 12,34,568 (lakh / crore grouping; Java's en-IN DecimalFormat groups by 3 only).
     * Owner rule (2026-11-03): the dashboard shows whole rupees, rounded half up; stored amounts keep their paise.
     */
    static String indian(BigDecimal v) {
        String whole = v.setScale(0, java.math.RoundingMode.HALF_UP).abs().toPlainString(), dec = "";
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

    // =====================================================================================
    // Excel downloads (owner request 2026-11-04): dashboard and every pop-up, with live Excel formulas.
    // Raw amounts per Management Approval sit on the "Approvals" sheet; the Company-wise and Unit-wise
    // tables add them up with SUMIFS, and every derived column (Received Total, Yet to Receive,
    // % to Receive, Balance to be Billed, Balance to Pay, Balance) is a formula, as on the dashboard.
    // =====================================================================================

    /** One Management Approval with the raw totals of POSITION_SQL (see zeros() for the index order). */
    private static final class ApprovalRaw {
        String name, descr, company, unit;
        BigDecimal[] t;
    }

    /** Approvals with company / unit names grouped exactly as loadCompanyPosition / loadUnitPosition. */
    private static List<ApprovalRaw> loadApprovalsRaw(java.sql.Connection con, String ids) throws Exception {
        Map<Integer, String> companies = new LinkedHashMap<Integer, String>();
        try (java.sql.PreparedStatement ps = con.prepareStatement(
                "SELECT id, COALESCE(NULLIF(short_name, ''), company_name) AS name FROM kss_csr_company ORDER BY company_name");
             java.sql.ResultSet rs = ps.executeQuery()) {
            while (rs.next()) companies.put(rs.getInt("id"), rs.getString("name"));
        }
        Map<String, String> unitNames = new LinkedHashMap<String, String>();            // key (lower case) -> name as first entered
        List<ApprovalRaw> list = new ArrayList<ApprovalRaw>();
        String sql = POSITION_SQL + (ids == null ? "" : " WHERE l.id IN (" + ids + ")") + " ORDER BY l.id";   // ids: integers only (letterIds)
        try (java.sql.PreparedStatement ps = con.prepareStatement(sql); java.sql.ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                ApprovalRaw a = new ApprovalRaw();
                a.name = rs.getString("letter_number") + " - " + rs.getString("letter_name");
                a.descr = rs.getString("descr");
                int co = rs.getInt("company_id");
                a.company = rs.wasNull() || !companies.containsKey(co) ? "Company not set" : companies.get(co);
                String place = rs.getString("activity_kind");
                place = place == null ? "" : place.replace(NBSP, ' ').trim().replaceAll("\\s+", " ");
                if (place.isEmpty()) place = "Not given";
                String k = place.toLowerCase(Locale.ROOT);
                if (!unitNames.containsKey(k)) unitNames.put(k, place);
                a.unit = unitNames.get(k);
                a.t = zeros();
                add(a.t, rs);
                list.add(a);
            }
        }
        list.sort((x, y) -> String.valueOf(x.name).compareToIgnoreCase(String.valueOf(y.name)));
        return list;
    }

    /** Cell styles shared by the downloads. */
    private static final class XStyles {
        CellStyle title, sub, group, head, text, textWrap, amt, amtNeg, amtZero, pct, totText, totAmt, totAmtNeg, totAmtZero, totPct, count, totCount;
        XStyles(Workbook wb) {
            org.apache.poi.ss.usermodel.DataFormat df = wb.createDataFormat();
            // Indian grouping (12,34,56,789.00) whatever the PC's regional setting; negatives in brackets; nil as "-"
            short pos = df.getFormat("[>=10000000]##\\,##\\,##\\,##0.00;[>=100000]##\\,##\\,##0.00;##,##0.00");
            short neg = df.getFormat("[<=-10000000](##\\,##\\,##\\,##0.00);[<=-100000](##\\,##\\,##0.00);(##,##0.00)");
            short nil = df.getFormat("\"-\"");
            short pc = df.getFormat("0.0%;(0.0%);\"-\"");
            Font bold = wb.createFont(); bold.setBold(true);
            Font big = wb.createFont(); big.setBold(true); big.setFontHeightInPoints((short) 13);
            Font muted = wb.createFont(); muted.setItalic(true); muted.setColor(org.apache.poi.ss.usermodel.IndexedColors.GREY_50_PERCENT.getIndex());
            Font red = wb.createFont(); red.setColor(org.apache.poi.ss.usermodel.IndexedColors.RED.getIndex());
            Font redBold = wb.createFont(); redBold.setBold(true); redBold.setColor(org.apache.poi.ss.usermodel.IndexedColors.RED.getIndex());
            title = wb.createCellStyle(); title.setFont(big);
            sub = wb.createCellStyle(); sub.setFont(muted);
            group = box(wb, bold, HorizontalAlignment.CENTER, true); group.setBorderBottom(BorderStyle.MEDIUM);
            head = box(wb, bold, HorizontalAlignment.CENTER, true); head.setWrapText(true);
            text = box(wb, null, HorizontalAlignment.LEFT, false);
            textWrap = box(wb, null, HorizontalAlignment.LEFT, false); textWrap.setWrapText(true);
            amt = box(wb, null, HorizontalAlignment.RIGHT, false); amt.setDataFormat(pos);
            amtNeg = box(wb, red, HorizontalAlignment.RIGHT, false); amtNeg.setDataFormat(neg);
            amtZero = box(wb, null, HorizontalAlignment.RIGHT, false); amtZero.setDataFormat(nil);
            pct = box(wb, null, HorizontalAlignment.RIGHT, false); pct.setDataFormat(pc);
            count = box(wb, null, HorizontalAlignment.RIGHT, false);
            totText = total(wb, bold, HorizontalAlignment.LEFT);
            totAmt = total(wb, bold, HorizontalAlignment.RIGHT); totAmt.setDataFormat(pos);
            totAmtNeg = total(wb, redBold, HorizontalAlignment.RIGHT); totAmtNeg.setDataFormat(neg);
            totAmtZero = total(wb, bold, HorizontalAlignment.RIGHT); totAmtZero.setDataFormat(nil);
            totPct = total(wb, bold, HorizontalAlignment.RIGHT); totPct.setDataFormat(pc);
            totCount = total(wb, bold, HorizontalAlignment.RIGHT);
        }
        private static CellStyle box(Workbook wb, Font f, HorizontalAlignment h, boolean shade) {
            CellStyle s = wb.createCellStyle();
            if (f != null) s.setFont(f);
            s.setAlignment(h);
            s.setVerticalAlignment(VerticalAlignment.TOP);
            s.setBorderTop(BorderStyle.THIN); s.setBorderBottom(BorderStyle.THIN); s.setBorderLeft(BorderStyle.THIN); s.setBorderRight(BorderStyle.THIN);
            if (shade) {
                s.setFillForegroundColor(org.apache.poi.ss.usermodel.IndexedColors.GREY_25_PERCENT.getIndex());
                s.setFillPattern(org.apache.poi.ss.usermodel.FillPatternType.SOLID_FOREGROUND);
                s.setVerticalAlignment(VerticalAlignment.CENTER);
            }
            return s;
        }
        private static CellStyle total(Workbook wb, Font f, HorizontalAlignment h) {
            CellStyle s = box(wb, f, h, false);
            s.setBorderTop(BorderStyle.THIN); s.setBorderBottom(BorderStyle.DOUBLE);
            return s;
        }
        /** Amount style chosen from the value Excel will show (whole rupees, as on the dashboard). */
        CellStyle amount(BigDecimal v, boolean tot) {
            int sg = v == null ? 0 : v.setScale(0, java.math.RoundingMode.HALF_UP).signum();
            return sg == 0 ? (tot ? totAmtZero : amtZero) : sg < 0 ? (tot ? totAmtNeg : amtNeg) : (tot ? totAmt : amt);
        }
    }

    private static String colName(int c) { return org.apache.poi.ss.util.CellReference.convertNumToColString(c); }

    private static Row row(Sheet s, int r) { Row x = s.getRow(r); return x == null ? s.createRow(r) : x; }

    private static void text(Sheet s, int r, int c, String v, CellStyle st) {
        Cell cell = row(s, r).createCell(c);
        cell.setCellValue(v == null ? "" : v);
        if (st != null) cell.setCellStyle(st);
    }

    private static void num(Sheet s, int r, int c, BigDecimal v, CellStyle st) {
        Cell cell = row(s, r).createCell(c);
        cell.setCellValue((v == null ? BigDecimal.ZERO : v).doubleValue());
        cell.setCellStyle(st);
    }

    private static void formula(Sheet s, int r, int c, String f, CellStyle st) {
        Cell cell = row(s, r).createCell(c);
        cell.setCellFormula(f);
        cell.setCellStyle(st);
    }

    /** Two header rows: 1. Budget | 2. Work Orders | 3. Payment | 4. Received from Sponsor, starting at column c0. */
    private static void positionHeader(Sheet s, int r, int c0, String[] lead, String fyOpening, String fyCurrent, XStyles x) {
        for (int i = 0; i < lead.length; i++) {
            text(s, r, i, lead[i], x.head); text(s, r + 1, i, "", x.head);
            s.addMergedRegion(new org.apache.poi.ss.util.CellRangeAddress(r, r + 1, i, i));
        }
        String[][] groups = { { "1. Budget", "6" }, { "2. Work Orders", "3" }, { "3. Payment", "3" }, { "4. Received from Sponsor", "3" } };
        int c = c0;
        for (String[] g : groups) {
            int n = Integer.parseInt(g[1]);
            for (int i = 0; i < n; i++) text(s, r, c + i, i == 0 ? g[0] : "", x.group);
            s.addMergedRegion(new org.apache.poi.ss.util.CellRangeAddress(r, r, c, c + n - 1));
            c += n;
        }
        String[] cols = { "Approved", "Received – Opening\n" + fyOpening, "Received – Current\n" + fyCurrent, "Received\nTotal", "Yet to Receive", "% to Receive",
            "Work Order Amount", "Invoice Raised", "Balance to be Billed", "Invoice Received", "Amount Paid", "Balance to Pay",
            "Total Received", "Paid to Vendors", "Balance" };
        for (int i = 0; i < cols.length; i++) text(s, r + 1, c0 + i, cols[i], x.head);
        row(s, r + 1).setHeightInPoints(42);
    }

    /**
     * The 15 position columns from c0 on row r. The 7 inputs (Approved, Received-Opening, Received-Current,
     * Work Order Amount, Invoice Raised, Amount Paid, Paid to Vendors) are values, or formulas when inF != null.
     */
    private static void positionCells(Sheet s, int r, int c0, BigDecimal[] t, String[] inF, boolean tot, XStyles x) {
        int R = r + 1;
        String C = colName(c0), D = colName(c0 + 1), E = colName(c0 + 2), F = colName(c0 + 3), G = colName(c0 + 4),
               I = colName(c0 + 6), J = colName(c0 + 7), L = colName(c0 + 9), M = colName(c0 + 10), O = colName(c0 + 12), P = colName(c0 + 13);
        BigDecimal approved = t[1], received = t[2], utilised = t[3], unpaid = t[5], opening = t[6], wo = t[7], billed = t[8];
        BigDecimal current = received.subtract(opening), paid = billed.subtract(unpaid);
        BigDecimal[] inV = { approved, opening, current, wo, billed, paid, utilised };
        int[] inCol = { 0, 1, 2, 6, 7, 10, 13 };
        for (int i = 0; i < inCol.length; i++) {
            if (inF != null) formula(s, r, c0 + inCol[i], inF[i], x.amount(inV[i], tot));
            else num(s, r, c0 + inCol[i], inV[i], x.amount(inV[i], tot));
        }
        formula(s, r, c0 + 3, D + R + "+" + E + R, x.amount(received, tot));                                  // Received Total
        formula(s, r, c0 + 4, C + R + "-" + F + R, x.amount(approved.subtract(received), tot));                // Yet to Receive
        formula(s, r, c0 + 5, "IF(" + C + R + "=0,0," + G + R + "/" + C + R + ")", tot ? x.totPct : x.pct);  // % to Receive
        formula(s, r, c0 + 8, I + R + "-" + J + R, x.amount(wo.subtract(billed), tot));                        // Balance to be Billed
        formula(s, r, c0 + 9, J + R, x.amount(billed, tot));                                                   // Invoice Received
        formula(s, r, c0 + 11, L + R + "-" + M + R, x.amount(unpaid, tot));                                    // Balance to Pay
        formula(s, r, c0 + 12, F + R, x.amount(received, tot));                                                // Total Received
        formula(s, r, c0 + 14, O + R + "-" + P + R, x.amount(received.subtract(utilised), tot));              // Balance
    }

    /** Total row: SUM of the rows above for the inputs; derived columns keep their formulas. */
    private static void positionTotal(Sheet s, int r, int c0, int first, int last, BigDecimal[] t, XStyles x) {
        String[] inF = new String[7];
        int[] inCol = { 0, 1, 2, 6, 7, 10, 13 };
        for (int i = 0; i < inCol.length; i++) {
            String c = colName(c0 + inCol[i]);
            inF[i] = last < first ? "0" : "SUM(" + c + (first + 1) + ":" + c + (last + 1) + ")";
        }
        positionCells(s, r, c0, t, inF, true, x);
    }

    private static String[] fyLabels() {
        java.time.LocalDate today = java.time.LocalDate.now(java.time.ZoneId.of("Asia/Kolkata"));
        int fy = today.getMonthValue() >= 4 ? today.getYear() : today.getYear() - 1;
        return new String[] { "till 31-03-" + fy, "FY " + fy + "-" + String.valueOf(fy + 1).substring(2),
            today.format(java.time.format.DateTimeFormatter.ofPattern("dd-MM-yyyy")) };
    }

    /**
     * "Approvals" sheet: one row per Management Approval; inputs are values, derived columns are formulas.
     * Columns: A Sl, B Management Approval, C Description, D Company, E Unit, F..T the 15 position columns.
     * Returns {first data row, last data row} (0-based).
     */
    private static int[] writeApprovalsSheet(Sheet s, String title, List<ApprovalRaw> list, XStyles x) {
        String[] fy = fyLabels();
        text(s, 0, 0, title, x.title);
        text(s, 1, 0, "Amounts in ₹ · generated " + fy[2] + " · inputs are values; totals and balances are Excel formulas", x.sub);
        positionHeader(s, 3, 5, new String[] { "Sl.", "Management Approval", "Description", "Company", "Unit" }, fy[0], fy[1], x);
        int r = 5, first = 5;
        BigDecimal[] total = zeros();
        for (ApprovalRaw a : list) {
            Cell sl = row(s, r).createCell(0); sl.setCellValue(r - first + 1); sl.setCellStyle(x.count);
            text(s, r, 1, a.name, x.textWrap);
            text(s, r, 2, a.descr, x.textWrap);
            text(s, r, 3, a.company, x.text);
            text(s, r, 4, a.unit, x.text);
            positionCells(s, r, 5, a.t, null, false, x);
            for (int k = 0; k < total.length; k++) total[k] = total[k].add(a.t[k]);
            r++;
        }
        int last = r - 1;
        for (int c = 0; c < 5; c++) text(s, r, c, c == 1 ? "Total" : "", x.totText);
        positionTotal(s, r, 5, first, last, total, x);
        s.setColumnWidth(0, 5 * 256); s.setColumnWidth(1, 48 * 256); s.setColumnWidth(2, 30 * 256);
        s.setColumnWidth(3, 16 * 256); s.setColumnWidth(4, 18 * 256);
        for (int c = 5; c < 20; c++) s.setColumnWidth(c, 17 * 256);
        s.createFreezePane(2, 5);
        return new int[] { first, last };
    }

    /** Company-wise / Unit-wise table on the Dashboard sheet, summed from the Approvals sheet with SUMIFS / COUNTIFS (exact name match). */
    private static int writeGroupTable(Sheet s, int r, String heading, String lead, List<String> names, List<ApprovalRaw> list,
                                       boolean byCompany, int[] span, XStyles x) {
        String[] fy = fyLabels();
        text(s, r, 0, heading + " (₹)", x.title);
        r += 1;
        positionHeader(s, r, 2, new String[] { lead, "Projects" }, fy[0], fy[1], x);
        r += 2;
        int a1 = span[0] + 1, a2 = Math.max(span[1], span[0]) + 1;                    // Approvals rows, 1-based (one blank row if none)
        String key = byCompany ? "D" : "E";
        String[] src = { "F", "G", "H", "L", "M", "P", "S" };                           // Approvals columns of the 7 inputs
        int first = r;
        BigDecimal[] total = zeros();
        for (String n : names) {
            BigDecimal[] t = zeros();
            for (ApprovalRaw a : list) if (n.equalsIgnoreCase(byCompany ? a.company : a.unit)) for (int k = 0; k < t.length; k++) t[k] = t[k].add(a.t[k]);
            for (int k = 0; k < total.length; k++) total[k] = total[k].add(t[k]);
            // exact, case-insensitive match: "=" prefix, and ~ * ? escaped so a name is never read as a wildcard
            String crit = "\"=" + n.replace("~", "~~").replace("*", "~*").replace("?", "~?").replace("\"", "\"\"") + "\"";
            String keyRange = "Approvals!$" + key + "$" + a1 + ":$" + key + "$" + a2;
            text(s, r, 0, n, x.text);
            formula(s, r, 1, "COUNTIFS(" + keyRange + "," + crit + ")", x.count);
            String[] inF = new String[7];
            for (int i = 0; i < 7; i++) inF[i] = "SUMIFS(Approvals!$" + src[i] + "$" + a1 + ":$" + src[i] + "$" + a2 + "," + keyRange + "," + crit + ")";
            positionCells(s, r, 2, t, inF, false, x);
            r++;
        }
        int last = r - 1;
        text(s, r, 0, "TOTAL", x.totText);
        formula(s, r, 1, last < first ? "0" : "SUM(B" + (first + 1) + ":B" + (last + 1) + ")", x.totCount);
        positionTotal(s, r, 2, first, last, total, x);
        return r + 3;
    }

    private static void sendWorkbook(HttpServletResponse response, Workbook wb, String fileName) throws IOException {
        try {
            wb.getCreationHelper().createFormulaEvaluator().evaluateAll();   // cached results, so viewers that do not recalculate still show figures
        } catch (RuntimeException ignored) {
            // Excel recalculates on open anyway
        }
        wb.setForceFormulaRecalculation(true);
        java.io.ByteArrayOutputStream buf = new java.io.ByteArrayOutputStream();
        wb.write(buf);
        response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
        response.setHeader("Content-Disposition", "attachment; filename=\"" + fileName.replaceAll("[^A-Za-z0-9._-]", "_") + "\"");
        response.setHeader("Cache-Control", "no-store");
        response.setContentLength(buf.size());
        try (OutputStream out = response.getOutputStream()) { buf.writeTo(out); }
    }

    private static String stamp() {
        return java.time.LocalDate.now(java.time.ZoneId.of("Asia/Kolkata")).format(java.time.format.DateTimeFormatter.ofPattern("dd-MM-yyyy"));
    }

    private void exportDashboardToExcel(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try (java.sql.Connection con = DBUtil.getConnection(); Workbook wb = new XSSFWorkbook()) {
            XStyles x = new XStyles(wb);
            List<ApprovalRaw> list = loadApprovalsRaw(con, null);
            Sheet dash = wb.createSheet("Dashboard");
            Sheet appr = wb.createSheet("Approvals");
            int[] span = writeApprovalsSheet(appr, com.Bean.AppConfig.code() + " CSR – Management Approval-wise Position", list, x);

            // row names exactly as on the dashboard (companies incl. Active ones without approvals; units)
            List<String> coNames = new ArrayList<String>(), unitNames = new ArrayList<String>();
            for (Map<String, String> m : loadCompanyPosition(con)) if (!"1".equals(m.get("total"))) coNames.add(m.get("name"));
            for (Map<String, String> m : loadUnitPosition(con)) if (!"1".equals(m.get("total"))) unitNames.add(m.get("name"));

            text(dash, 0, 0, com.Bean.AppConfig.code() + " CSR Amount Spending Dashboard", x.title);
            text(dash, 1, 0, "Amounts in ₹ · generated " + stamp() + " · figures are formulas on the Approvals sheet", x.sub);
            int r = writeGroupTable(dash, 3, "Company-wise Position", "Company", coNames, list, true, span, x);
            writeGroupTable(dash, r, "Unit / Institution-wise Position", "Unit", unitNames, list, false, span, x);
            dash.setColumnWidth(0, 30 * 256); dash.setColumnWidth(1, 9 * 256);
            for (int c = 2; c < 17; c++) dash.setColumnWidth(c, 17 * 256);
            dash.createFreezePane(1, 0);
            sendWorkbook(response, wb, "CSR-Dashboard-" + stamp() + ".xlsx");
        } catch (Exception e) {
            getServletContext().log("Error exporting dashboard to Excel", e);
            if (!response.isCommitted()) response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Failed to export dashboard");
        }
    }

    /** Excel of one dashboard pop-up (same view / key / col [/ fy] and the same checks as the pop-up itself). */
    private void exportDetailToExcel(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        try (java.sql.Connection con = DBUtil.getConnection(); Workbook wb = new XSSFWorkbook()) {
            Map<String, Object> out = new LinkedHashMap<String, Object>();
            buildDetail(con, request, out);
            XStyles x = new XStyles(wb);
            String title = String.valueOf(out.get("title"));
            if (out.get("groups") != null && out.get("ids") != null) {
                // Management Approvals pop-up: raw inputs + formulas, same layout as the dashboard
                writeApprovalsSheet(wb.createSheet("Approvals"), title, loadApprovalsRaw(con, (String) out.get("ids")), x);
            } else {
                writeDetailSheet(wb.createSheet("Details"), title, out, x);
            }
            sendWorkbook(response, wb, title.replaceAll("[^A-Za-z0-9]+", "-").replaceAll("^-|-$", "") + "-" + stamp() + ".xlsx");
        } catch (IllegalArgumentException bad) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, bad.getMessage());
        } catch (Exception e) {
            getServletContext().log("Error exporting dashboard detail to Excel", e);
            if (!response.isCommitted()) response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Failed to export details");
        }
    }

    /** Ledger-style pop-ups (receipts, payments, retention, bills unpaid, month-wise): amounts as numbers, totals as SUM where they add up. */
    private static void writeDetailSheet(Sheet s, String title, Map<String, Object> out, XStyles x) {
        String[] cols = (String[]) out.get("cols");
        boolean[] numCol = (boolean[]) out.get("num");
        @SuppressWarnings("unchecked")
        List<String[]> rows = (List<String[]>) out.get("rows");
        String[] foot = (String[]) out.get("foot");
        text(s, 0, 0, title, x.title);
        text(s, 1, 0, "Amounts in ₹ (whole rupees, as shown on the dashboard) · generated " + stamp(), x.sub);
        for (int c = 0; c < cols.length; c++) {
            text(s, 3, c, cols[c], x.head);
            s.setColumnWidth(c, (numCol[c] ? 17 : ("Description".equals(cols[c]) || "Management Approval".equals(cols[c]) ? 40 : 18)) * 256);
        }
        int r = 4, first = 4;
        BigDecimal[] sums = new BigDecimal[cols.length];
        boolean[] summable = new boolean[cols.length];
        for (int c = 0; c < cols.length; c++) { sums[c] = BigDecimal.ZERO; summable[c] = numCol[c]; }
        if (rows != null) for (String[] v : rows) {
            for (int c = 0; c < cols.length; c++) {
                String cell = c < v.length ? v[c] : "";
                if (numCol[c]) {
                    BigDecimal n = parseShown(cell);
                    if (n == null) { text(s, r, c, cell, x.text); summable[c] = false; continue; }
                    if (cell.trim().endsWith("%")) { num(s, r, c, n, x.pct); summable[c] = false; }
                    else { num(s, r, c, n, x.amount(n, false)); sums[c] = sums[c].add(n); }
                } else text(s, r, c, cell, c < 2 || cell == null || cell.length() <= 30 ? x.text : x.textWrap);
            }
            r++;
        }
        int last = r - 1;
        if (foot != null) {
            for (int c = 0; c < cols.length; c++) {
                String f = c < foot.length ? foot[c] : "";
                if (!numCol[c] || f == null || f.isEmpty()) { text(s, r, c, f, x.totText); continue; }
                BigDecimal n = parseShown(f);
                if (n == null) { text(s, r, c, f, x.totText); continue; }
                if (f.trim().endsWith("%")) { num(s, r, c, n, x.totPct); continue; }
                // a running figure (e.g. Cumulative Unspent) is not the sum of its column: keep the value then
                if (summable[c] && last >= first && sums[c].compareTo(n) == 0)
                    formula(s, r, c, "SUM(" + colName(c) + (first + 1) + ":" + colName(c) + (last + 1) + ")", x.amount(n, true));
                else num(s, r, c, n, x.amount(n, true));
            }
        }
        s.createFreezePane(0, 4);
    }

    /** "12,34,567" -> 1234567; "(7,94,502)" -> -794502; "-" / "" -> 0; "42.9%" -> 0.429; anything else -> null. */
    private static BigDecimal parseShown(String v) {
        if (v == null) return BigDecimal.ZERO;
        String s = v.trim();
        if (s.isEmpty() || "-".equals(s)) return BigDecimal.ZERO;
        boolean neg = s.startsWith("(") && s.endsWith(")");
        if (neg) s = s.substring(1, s.length() - 1);
        boolean pct = s.endsWith("%");
        if (pct) s = s.substring(0, s.length() - 1);
        s = s.replace(",", "").replace("₹", "").trim();
        if (!s.matches("-?\\d+(\\.\\d+)?")) return null;
        BigDecimal n = new BigDecimal(s);
        if (pct) n = n.movePointLeft(2);
        return neg ? n.negate() : n;
    }

}
