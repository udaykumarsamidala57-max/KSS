<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@page import="java.util.Map"%>
<%
    @SuppressWarnings("unchecked")
    Map<String, String> stats = (Map<String, String>) request.getAttribute("stats");
    if (stats == null) {
        response.sendRedirect("CsrDashboardServlet");
        return;
    }
    String loadError = (String) request.getAttribute("loadError");
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>KSS CSR Dashboard</title>

<%@ include file="header.jsp" %>

<style>
<%@ include file="css/csrLetter.css" %>
</style>
<style>
<%@ include file="css/finance.css" %>
.csr-dashboard-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(220px, 1fr));
  gap: 12px;
  margin-top: 14px;
}
.csr-dashboard-card {
  min-height: 138px;
  padding: 16px 18px;
  background: #fff;
  border: 1px solid var(--fin-line);
  border-radius: 7px;
  box-shadow: 0 1px 2px rgba(15, 23, 42, .05);
}
.csr-dashboard-label {
  margin-bottom: 9px;
  color: var(--fin-muted);
  font-size: 11px;
  font-weight: 600;
  letter-spacing: .5px;
  text-transform: uppercase;
}
.csr-dashboard-value {
  color: var(--fin-ink);
  font-size: clamp(21px, 2vw, 28px);
  font-weight: 700;
  line-height: 1.2;
  overflow-wrap: anywhere;
}
.csr-dashboard-detail {
  margin-top: 9px;
  color: var(--fin-ink-2);
  font-size: 12px;
  line-height: 1.5;
}
.csr-dashboard-note {
  margin-top: 12px;
  color: var(--fin-muted);
  font-size: 11px;
}
@media (max-width: 900px) {
  .csr-dashboard-grid { grid-template-columns: repeat(2, minmax(200px, 1fr)); }
}
@media (max-width: 560px) {
  .csr-dashboard-grid { grid-template-columns: 1fr; }
}
</style>
</head>
<body>
<div class="csr-page">
  <div class="csr-header">
    <div>
      <div class="csr-subtitle">KSS CSR Amount Spending</div>
      <h1 class="csr-title">Dashboard</h1>
    </div>
    <a href="CsrLetterServlet" class="csr-btn csr-btn-outline csr-link-btn">&#8592; Back to Management Approvals</a>
  </div>

  <% if (loadError != null) { %>
  <div class="csr-alert csr-alert-err" role="alert"><%= loadError %></div>
  <% } %>

  <div class="csr-dashboard-grid">
    <section class="csr-dashboard-card">
      <div class="csr-dashboard-label">Total Approved</div>
      <div class="csr-dashboard-value"><%= stats.getOrDefault("approvedAmount", "₹0.00") %></div>
      <div class="csr-dashboard-detail"><%= stats.getOrDefault("approvalCount", "0") %> Management Approvals</div>
    </section>
    <section class="csr-dashboard-card">
      <div class="csr-dashboard-label">Work Orders Raised</div>
      <div class="csr-dashboard-value"><%= stats.getOrDefault("workOrderCount", "0") %></div>
      <div class="csr-dashboard-detail">Committed total: <%= stats.getOrDefault("workOrderAmount", "₹0.00") %></div>
    </section>
    <section class="csr-dashboard-card">
      <div class="csr-dashboard-label">Invoices</div>
      <div class="csr-dashboard-value"><%= stats.getOrDefault("invoiceCount", "0") %></div>
      <div class="csr-dashboard-detail">Tax invoices: <%= stats.getOrDefault("taxInvoiceAmount", "₹0.00") %><br>Proforma invoices: <%= stats.getOrDefault("proformaAmount", "₹0.00") %></div>
    </section>
    <section class="csr-dashboard-card">
      <div class="csr-dashboard-label">FRLs Raised</div>
      <div class="csr-dashboard-value"><%= stats.getOrDefault("frlCount", "0") %></div>
      <div class="csr-dashboard-detail">Requested total: <%= stats.getOrDefault("frlAmount", "₹0.00") %></div>
    </section>
    <section class="csr-dashboard-card">
      <div class="csr-dashboard-label">FRL Claims</div>
      <div class="csr-dashboard-value"><%= stats.getOrDefault("claimCount", "0") %></div>
      <div class="csr-dashboard-detail">Claimed total: <%= stats.getOrDefault("claimAmount", "₹0.00") %></div>
    </section>
    <section class="csr-dashboard-card">
      <div class="csr-dashboard-label">Funds Received</div>
      <div class="csr-dashboard-value"><%= stats.getOrDefault("receivedAmount", "₹0.00") %></div>
      <div class="csr-dashboard-detail"><%= stats.getOrDefault("receiptCount", "0") %> receipts</div>
    </section>
  </div>
  <p class="csr-dashboard-note">All-time totals from recorded CSR data. Invoice count includes proforma invoices and tax invoices; their values are shown separately.</p>
</div>
</body>
</html>
