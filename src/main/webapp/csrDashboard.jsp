<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@page import="java.util.Map"%>
<%@page import="java.util.List"%>
<%
    @SuppressWarnings("unchecked")
    Map<String, String> stats = (Map<String, String>) request.getAttribute("stats");
    if (stats == null) {
        response.sendRedirect("CsrDashboardServlet");
        return;
    }
    String loadError = (String) request.getAttribute("loadError");
    @SuppressWarnings("unchecked")
    List<Map<String, String>> approvalLetters = (List<Map<String, String>>) request.getAttribute("approvalLetters");
    @SuppressWarnings("unchecked")
    Map<String, String> letterStats = (Map<String, String>) request.getAttribute("letterStats");
    String selectedLetterId = (String) request.getAttribute("selectedLetterId");
%>
<%!
    private String escapeHtml(String value) {
        if (value == null) return "";
        return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
                .replace("\"", "&quot;").replace("'", "&#39;");
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><%= com.Bean.AppConfig.code() %> CSR Dashboard</title>

<%@ include file="header.jsp" %>

<style>
<%@ include file="css/csrLetter.css" %>
</style>
<style>
<%@ include file="css/finance.css" %>
.csr-dashboard-label {
  margin-bottom: 7px;
  color: var(--fin-muted);
  font-size: 12px;
  font-weight: 600;
  letter-spacing: .5px;
  text-transform: uppercase;
}
.csr-dashboard-value {
  color: var(--fin-ink);
  font-size: clamp(22px, 2vw, 28px);
  font-weight: 700;
  line-height: 1.2;
  overflow-wrap: anywhere;
}
.csr-dashboard-prime { display:grid; grid-template-columns:repeat(3,minmax(0,1fr)); width:100%; box-sizing:border-box; margin-top:10px; background:#fff; border:1px solid var(--fin-line); border-top:2px solid var(--fin-teal); border-radius:7px; box-shadow:0 1px 2px rgba(15,23,42,.05); }
.csr-dashboard-prime-item { min-width:0; padding:16px 20px; }
.csr-dashboard-prime-item + .csr-dashboard-prime-item { border-left:1px solid var(--fin-line); }
.csr-dashboard-prime .csr-dashboard-label { margin:0 0 7px; color:var(--fin-muted); font-size:13px; line-height:1.4; }
.csr-dashboard-prime .csr-dashboard-value { font-size:clamp(23px,2.2vw,30px); line-height:1.25; }
.csr-dashboard-balance { margin-top:7px; color:var(--fin-muted); font-size:13px; line-height:1.4; }
.csr-dashboard-subline { display:flex; justify-content:space-between; gap:10px; margin-top:6px; color:var(--fin-muted); font-size:13px; line-height:1.4; }
.csr-dashboard-subline b { color:var(--fin-ink); font-weight:600; text-align:right; }
.csr-letter-summary { margin-top:14px; padding:14px 16px; background:#fff; border:1px solid var(--fin-line); border-radius:7px; box-shadow:0 1px 2px rgba(15,23,42,.05); }
.csr-letter-summary .csr-dashboard-prime { margin-top:8px; border:0; border-top:1px solid var(--fin-line); border-radius:0; box-shadow:none; }
.csr-letter-filter { display:flex; flex-wrap:wrap; align-items:end; gap:8px; margin-bottom:10px; }
.csr-letter-filter label { display:flex; flex-direction:column; gap:4px; color:var(--fin-muted); font-size:12px; font-weight:600; }
.csr-letter-filter select { min-width:min(420px,75vw); height:34px; padding:0 9px; border:1px solid var(--fin-line); border-radius:4px; color:var(--fin-ink); background:#fff; font:inherit; }
.csr-letter-card-title { margin:0 0 9px; color:var(--fin-ink); font-size:14px; font-weight:600; }
.csr-letter-status { min-height:18px; margin:2px 0 8px; color:var(--fin-muted); font-size:12px; }
.csr-pdf-list { display:flex; flex-wrap:wrap; gap:8px; margin-top:12px; }
.csr-pdf-link { display:flex; flex-direction:column; gap:2px; min-width:160px; max-width:280px; padding:8px 10px; border:1px solid var(--fin-line); border-radius:5px; color:var(--fin-teal); text-decoration:none; background:#fff; }
.csr-pdf-link:hover { background:#f0fdfa; border-color:#99c9c1; }
.csr-pdf-link small { color:var(--fin-muted); font-size:10px; overflow-wrap:anywhere; }
@media (max-width: 900px) {
  .csr-dashboard-prime { grid-template-columns:repeat(2,minmax(0,1fr)); }
  .csr-dashboard-prime-item:nth-child(3) { grid-column:1 / -1; border-left:0; border-top:1px solid var(--fin-line); }
}
@media (max-width: 560px) {
  .csr-dashboard-prime { grid-template-columns:1fr; }
  .csr-dashboard-prime-item + .csr-dashboard-prime-item { border-left:0; border-top:1px solid var(--fin-line); }
  .csr-dashboard-prime-item:nth-child(3) { grid-column:auto; }
}
</style>
</head>
<body>
<div class="csr-page">
  <div class="csr-header">
    <div>
      <div class="csr-subtitle"><%= com.Bean.AppConfig.code() %> CSR Amount Spending</div>
      <h1 class="csr-title">Dashboard</h1>
    </div>
  </div>

  <% if (loadError != null) { %>
  <div class="csr-alert csr-alert-err" role="alert"><%= loadError %></div>
  <% } %>

  <section class="csr-dashboard-prime" aria-label="Key CSR position">
    <div class="csr-dashboard-prime-item">
      <div class="csr-dashboard-label">Approved Budget</div>
      <div class="csr-dashboard-value"><%= stats.getOrDefault("approvedAmount", "₹0.00") %></div>
      <div class="csr-dashboard-balance">Balance: <b><%= stats.getOrDefault("workOrderBalance", "₹0.00") %></b></div>
    </div>
    <div class="csr-dashboard-prime-item">
      <div class="csr-dashboard-label">Work Orders Raised</div>
      <div class="csr-dashboard-subline"><span>Work orders</span><b><%= stats.getOrDefault("workOrderCount", "0") %> nos. · <%= stats.getOrDefault("workOrderAmount", "₹0.00") %></b></div>
      <div class="csr-dashboard-subline"><span>Tax invoices raised</span><b><%= stats.getOrDefault("taxInvoiceCount", "0") %> nos. · <%= stats.getOrDefault("taxInvoiceAmount", "₹0.00") %></b></div>
      <div class="csr-dashboard-subline"><span>Payments done</span><b><%= stats.getOrDefault("paymentCount", "0") %> nos. · <%= stats.getOrDefault("paymentAmount", "₹0.00") %></b></div>
      <div class="csr-dashboard-subline"><span>Balance to pay</span><b><%= stats.getOrDefault("balanceInvoiceCount", "0") %> nos. · <%= stats.getOrDefault("balanceToPay", "₹0.00") %></b></div>
    </div>
    <div class="csr-dashboard-prime-item">
      <div class="csr-dashboard-label">Funds Received</div>
      <div class="csr-dashboard-subline"><span>FRLs Raised</span><b><%= stats.getOrDefault("frlAmount", "₹0.00") %> · <%= stats.getOrDefault("frlCount", "0") %> nos.</b></div>
      <div class="csr-dashboard-subline"><span>FRLs Received</span><b><%= stats.getOrDefault("frlReceivedAmount", "₹0.00") %> · <%= stats.getOrDefault("frlReceivedCount", "0") %> nos.</b></div>
      <div class="csr-dashboard-balance">Balance to receive: <b><%= stats.getOrDefault("fundsBalance", "₹0.00") %></b></div>
    </div>
  </section>
  <section class="csr-letter-summary" aria-labelledby="letter-summary-title">
    <h2 class="csr-letter-card-title" id="letter-summary-title">Approval-wise Summary</h2>
    <div class="csr-letter-filter">
      <label for="letterId">Management Approval
        <select id="letterId" name="letterId">
          <option value="">Select a Management Approval</option>
          <% if (approvalLetters != null) { for (Map<String, String> letter : approvalLetters) {
               String id = letter.get("id");
               String label = (letter.get("number") == null ? "" : letter.get("number"))
                       + (letter.get("name") == null || letter.get("name").isEmpty() ? "" : " — " + letter.get("name")); %>
          <option value="<%= escapeHtml(id) %>" <%= id.equals(selectedLetterId) ? "selected" : "" %>><%= escapeHtml(label) %></option>
          <% } } %>
        </select>
      </label>
    </div>
    <div class="csr-letter-status" id="letterSummaryStatus" aria-live="polite"><%= letterStats == null || letterStats.isEmpty() ? "Choose an approval to load its summary and PDFs." : "" %></div>
    <div id="letterStatsSummary" <%= letterStats == null || letterStats.isEmpty() ? "hidden" : "" %>>
    <div class="csr-dashboard-prime" aria-label="Selected Management Approval summary">
      <div class="csr-dashboard-prime-item">
        <div class="csr-dashboard-label">Approved Budget</div>
        <div class="csr-dashboard-value" id="letterApprovedAmount"><%= letterStats == null ? "₹0.00" : letterStats.getOrDefault("approvedAmount", "₹0.00") %></div>
        <div class="csr-dashboard-balance">Balance: <b id="letterWorkOrderBalance"><%= letterStats == null ? "₹0.00" : letterStats.getOrDefault("workOrderBalance", "₹0.00") %></b></div>
      </div>
      <div class="csr-dashboard-prime-item">
        <div class="csr-dashboard-label">Work Orders Raised</div>
        <div class="csr-dashboard-subline"><span>Work orders</span><b id="letterWorkOrderSummary"><%= letterStats == null ? "0 nos. · ₹0.00" : letterStats.getOrDefault("workOrderCount", "0") + " nos. · " + letterStats.getOrDefault("workOrderAmount", "₹0.00") %></b></div>
        <div class="csr-dashboard-subline"><span>Tax invoices raised</span><b id="letterInvoiceSummary"><%= letterStats == null ? "0 nos. · ₹0.00" : letterStats.getOrDefault("taxInvoiceCount", "0") + " nos. · " + letterStats.getOrDefault("taxInvoiceAmount", "₹0.00") %></b></div>
        <div class="csr-dashboard-subline"><span>Payments done</span><b id="letterPaymentSummary"><%= letterStats == null ? "0 nos. · ₹0.00" : letterStats.getOrDefault("paymentCount", "0") + " nos. · " + letterStats.getOrDefault("paymentAmount", "₹0.00") %></b></div>
        <div class="csr-dashboard-subline"><span>Balance to pay</span><b id="letterBalanceToPaySummary"><%= letterStats == null ? "0 nos. · ₹0.00" : letterStats.getOrDefault("balanceInvoiceCount", "0") + " nos. · " + letterStats.getOrDefault("balanceToPay", "₹0.00") %></b></div>
      </div>
      <div class="csr-dashboard-prime-item">
        <div class="csr-dashboard-label">Funds Received</div>
        <div class="csr-dashboard-subline"><span>FRLs Raised</span><b id="letterFrlRaisedSummary"><%= letterStats == null ? "₹0.00 · 0 nos." : letterStats.getOrDefault("frlAmount", "₹0.00") + " · " + letterStats.getOrDefault("frlCount", "0") + " nos." %></b></div>
        <div class="csr-dashboard-subline"><span>FRLs Received</span><b id="letterFrlReceivedSummary"><%= letterStats == null ? "₹0.00 · 0 nos." : letterStats.getOrDefault("frlReceivedAmount", "₹0.00") + " · " + letterStats.getOrDefault("frlReceivedCount", "0") + " nos." %></b></div>
        <div class="csr-dashboard-balance">Balance to receive: <b id="letterFundsBalance"><%= letterStats == null ? "₹0.00" : letterStats.getOrDefault("fundsBalance", "₹0.00") %></b></div>
      </div>
    </div>
    <div id="letterPdfList" class="csr-pdf-list" aria-label="Approval PDFs"></div>
    </div>
  </section>
</div>
<script>
(function () {
  var select = document.getElementById('letterId');
  var summary = document.getElementById('letterStatsSummary');
  var status = document.getElementById('letterSummaryStatus');
  var pdfList = document.getElementById('letterPdfList');
  function text(id, value) { document.getElementById(id).textContent = value || '0'; }
  function showStats(s) {
    text('letterApprovedAmount', s.approvedAmount);
    text('letterWorkOrderBalance', s.workOrderBalance);
    text('letterWorkOrderSummary', s.workOrderCount + ' nos. · ' + s.workOrderAmount);
    text('letterInvoiceSummary', s.taxInvoiceCount + ' nos. · ' + s.taxInvoiceAmount);
    text('letterPaymentSummary', s.paymentCount + ' nos. · ' + s.paymentAmount);
    text('letterBalanceToPaySummary', s.balanceInvoiceCount + ' nos. · ' + s.balanceToPay);
    text('letterFrlRaisedSummary', s.frlAmount + ' · ' + s.frlCount + ' nos.');
    text('letterFrlReceivedSummary', s.frlReceivedAmount + ' · ' + s.frlReceivedCount + ' nos.');
    text('letterFundsBalance', s.fundsBalance);
  }
  function showPdfs(pdfs) {
    pdfList.replaceChildren();
    if (!pdfs || !pdfs.length) {
      var empty = document.createElement('span');
      empty.className = 'csr-dashboard-balance';
      empty.textContent = 'No PDF files attached to this Management Approval.';
      pdfList.appendChild(empty);
      return;
    }
    pdfs.forEach(function (pdf) {
      var link = document.createElement('a');
      link.className = 'csr-pdf-link';
      link.href = pdf.url;
      link.target = '_blank';
      link.rel = 'noopener';
      link.textContent = pdf.label || 'Open PDF';
      if (pdf.fileName) {
        var name = document.createElement('small');
        name.textContent = pdf.fileName;
        link.appendChild(name);
      }
      pdfList.appendChild(link);
    });
  }
  function loadApproval() {
    var id = select.value;
    pdfList.replaceChildren();
    if (!id) {
      summary.hidden = true;
      status.textContent = 'Choose an approval to load its summary and PDFs.';
      return;
    }
    status.textContent = 'Loading approval details…';
    fetch('CsrDashboardServlet?action=letterData&letterId=' + encodeURIComponent(id), { headers: { 'Accept': 'application/json' } })
      .then(function (response) { return response.json().then(function (data) { if (!response.ok) throw new Error(data.message || 'Could not load approval details.'); return data; }); })
      .then(function (data) {
        if (!data.ok) throw new Error(data.message || 'Could not load approval details.');
        showStats(data.stats);
        showPdfs(data.pdfs);
        summary.hidden = false;
        status.textContent = '';
      })
      .catch(function (error) {
        summary.hidden = true;
        status.textContent = error.message || 'Approval details could not be loaded.';
      });
  }
  select.addEventListener('change', loadApproval);
  if (select.value) loadApproval();
}());
</script>
</body>
</html>
