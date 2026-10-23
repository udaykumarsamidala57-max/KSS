package com.Controller;

import java.io.IOException;
import java.math.BigDecimal;
import java.text.NumberFormat;
import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.Bean.DBUtil;

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
          + "(SELECT COUNT(*) FROM kss_csr_invoice) AS invoice_count, "
          + "(SELECT COALESCE(SUM(CASE WHEN invoice_type = 'Tax Invoice' THEN amount ELSE 0 END), 0) FROM kss_csr_invoice) AS tax_invoice_amount, "
          + "(SELECT COALESCE(SUM(CASE WHEN invoice_type = 'Proforma' THEN amount ELSE 0 END), 0) FROM kss_csr_invoice) AS proforma_amount, "
          + "(SELECT COUNT(*) FROM kss_csr_fund_request) AS frl_count, "
          + "(SELECT COALESCE(SUM(amount), 0) FROM kss_csr_fund_request) AS frl_amount, "
          + "(SELECT COUNT(*) FROM kss_csr_frl_invoice) AS claim_count, "
          + "(SELECT COALESCE(SUM(claim_amount), 0) FROM kss_csr_frl_invoice) AS claim_amount, "
          + "(SELECT COUNT(*) FROM kss_csr_fund_receipt) AS receipt_count, "
          + "(SELECT COALESCE(SUM(amount), 0) FROM kss_csr_fund_receipt) AS received_amount";

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

        Map<String, String> stats = new LinkedHashMap<String, String>();
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
                receivedAmount = zeroIfNull(rs.getBigDecimal("received_amount"));
                stats.put("receivedAmount", formatCurrency(receivedAmount));
            }
        } catch (Exception e) {
            getServletContext().log("Unable to load KSS CSR dashboard totals", e);
            request.setAttribute("loadError", "Dashboard totals could not be loaded. Please try again.");
        }

        request.setAttribute("stats", stats);
        request.getRequestDispatcher("/csrDashboard.jsp").forward(request, response);
    }

    private static BigDecimal zeroIfNull(BigDecimal amount) {
        return amount == null ? BigDecimal.ZERO : amount;
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
