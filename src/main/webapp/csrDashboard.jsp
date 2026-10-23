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
    @SuppressWarnings("unchecked")
    List<Map<String, String>> companyPosition = (List<Map<String, String>>) request.getAttribute("companyPosition");
    @SuppressWarnings("unchecked")
    List<Map<String, String>> unitPosition = (List<Map<String, String>>) request.getAttribute("unitPosition");
    String companyError = (String) request.getAttribute("companyError");
    @SuppressWarnings("unchecked")
    List<Map<String, String>> monthly = (List<Map<String, String>>) request.getAttribute("monthly");
    @SuppressWarnings("unchecked")
    List<String[]> monthlyYears = (List<String[]>) request.getAttribute("monthlyYears");
    String monthlyFy = (String) request.getAttribute("monthlyFy");
    String monthlyOpening = (String) request.getAttribute("monthlyOpening");
    String instCodeD = com.Bean.AppConfig.code();
%>
<%!
    /** An amount that opens the detail popup; "-" (nil) stays plain text. */
    private String dl(String value, String view, String key, String col, String fy) {
        if (value == null || "-".equals(value) || "0".equals(value) || "0.0%".equals(value)) return escapeHtml(value);
        return "<a href=\"#\" class=\"dd-link\" data-view=\"" + view + "\" data-key=\"" + escapeHtml(key) + "\" data-col=\"" + col + "\""
             + (fy == null ? "" : " data-fy=\"" + escapeHtml(fy) + "\"") + " title=\"Show details\">" + escapeHtml(value) + "</a>";
    }
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
.csr-co-card { margin-top:14px; background:#fff; border:1px solid var(--fin-line); border-radius:7px; box-shadow:0 1px 2px rgba(15,23,42,.05); }
.csr-co-card .csr-card-head { padding:10px 14px; border-bottom:1px solid var(--fin-line); }
.csr-co-table td.csr-num, .csr-co-table th.csr-num { text-align:right; white-space:nowrap; }
.csr-co-table th { white-space:normal; line-height:1.25; vertical-align:bottom; }
.csr-co-table tr.csr-co-total td { font-weight:700; background:#f8fafc; border-top:2px solid #cbd5e1; }
.csr-co-table .csr-co-neg { color:#b91c1c; }
.csr-co-table td.csr-cum-neg { background:#fde4d8; color:#b91c1c; }
.csr-co-table a.dd-link { color:inherit; text-decoration:none; border-bottom:1px dashed #0f766e; }
.csr-co-table a.dd-link:hover { color:#0f766e; background:#f0fdfa; }
.dd-modal { position:fixed; inset:0; z-index:2000; display:none; align-items:flex-start; justify-content:center; padding:60px 16px 20px; background:rgba(15,23,42,.45); }
.dd-modal.open { display:flex; }
.dd-box { width:min(1320px,100%); max-height:calc(100vh - 90px); display:flex; flex-direction:column; background:#fff; border-radius:7px; box-shadow:0 10px 30px rgba(15,23,42,.25); }
.dd-head { display:flex; justify-content:space-between; align-items:center; gap:10px; padding:10px 14px; border-bottom:1px solid var(--fin-line); }
.dd-title { font-size:14px; font-weight:600; color:var(--fin-ink); }
.dd-body { overflow:auto; padding:0 0 6px; }
.dd-body .csr-table td.n, .dd-body .csr-table th.n { text-align:right; white-space:nowrap; }
.dd-body .csr-table tfoot td { font-weight:700; background:#f8fafc; border-top:2px solid #cbd5e1; }
.dd-body .csr-table { width:100%; }
.dd-body .csr-table td { vertical-align:top; }
.dd-body .csr-table th { white-space:nowrap !important; }
.dd-body .csr-table td.n, .dd-body .csr-table td.d { white-space:nowrap !important; }
.dd-body .csr-table td.t { white-space:normal !important; overflow-wrap:anywhere; min-width:150px; max-width:340px; overflow:visible !important; text-overflow:clip !important; }
.dd-msg { padding:16px 14px; color:var(--fin-muted); }
.csr-co-fy { display:flex; align-items:center; gap:8px; font-size:12px; color:var(--fin-muted); }
.csr-co-fy select { height:28px; padding:0 6px; border:1px solid var(--fin-line); border-radius:4px; font:inherit; color:var(--fin-ink); background:#fff; }
.csr-co-card .csr-card-head { display:flex; justify-content:space-between; align-items:center; gap:10px; flex-wrap:wrap; }
.csr-co-note { padding:8px 14px 10px; color:var(--fin-muted); font-size:11.5px; line-height:1.5; }
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
  <%-- Company-wise and Unit-wise Position (unit = Kind of CSR Activity of the approval): same columns and formulas --%>
  <% Object[][] positions = { { "co", "Company-wise Position", "Company", companyPosition },
                              { "unit", "Unit / Institution-wise Position", "Unit", unitPosition } };
     for (Object[] pos : positions) {
       @SuppressWarnings("unchecked")
       List<Map<String, String>> posRows = (List<Map<String, String>>) pos[3]; %>
  <section class="csr-co-card" aria-labelledby="<%= pos[0] %>-title" id="<%= pos[0] %>Position">
    <div class="csr-card-head"><div class="csr-card-title" id="<%= pos[0] %>-title"><%= pos[1] %> <span class="csr-small">(&#8377;)</span></div></div>
    <% if (companyError != null) { %>
    <div class="csr-alert csr-alert-err" style="margin:10px 14px;"><%= escapeHtml(companyError) %></div>
    <% } else if (posRows != null) { %>
    <div class="csr-table-wrap">
      <table class="csr-table csr-co-table">
        <thead>
          <tr>
            <th><%= pos[2] %></th>
            <th class="csr-num">Projects</th>
            <th class="csr-num">Approved</th>
            <th class="csr-num">Received</th>
            <th class="csr-num">Yet to Receive</th>
            <th class="csr-num">Utilised</th>
            <th class="csr-num">Unspent with <%= escapeHtml(instCodeD) %></th>
            <th class="csr-num">Retention Held</th>
            <th class="csr-num">Bills Unpaid</th>
            <th class="csr-num">Free Balance</th>
            <th class="csr-num">Utilisation %</th>
          </tr>
        </thead>
        <tbody>
          <% for (Map<String, String> c : posRows) {
               boolean tot = "1".equals(c.get("total"));
               String cid = c.get("companyId");
               String vw = (String) pos[0];
               String k = tot ? "all" : ("co".equals(vw) ? (cid == null || cid.isEmpty() ? "0" : cid) : c.get("name")); %>
          <tr class="<%= tot ? "csr-co-total" : "csr-row" %>">
            <td><% if (!tot && cid != null && !cid.isEmpty() && !"0".equals(c.get("projects"))) { %><a class="csr-open" href="CsrLetterServlet?companyId=<%= escapeHtml(cid) %>"><%= escapeHtml(c.get("name")) %></a><% } else { %><%= escapeHtml(c.get("name")) %><% } %></td>
            <td class="csr-num"><%= dl(c.get("projects"), vw, k, "projects", null) %></td>
            <td class="csr-num"><%= dl(c.get("approved"), vw, k, "approved", null) %></td>
            <td class="csr-num"><%= dl(c.get("received"), vw, k, "received", null) %></td>
            <td class="csr-num"><%= dl(c.get("yetToReceive"), vw, k, "yetToReceive", null) %></td>
            <td class="csr-num"><%= dl(c.get("utilised"), vw, k, "utilised", null) %></td>
            <td class="csr-num <%= "1".equals(c.get("unspentNeg")) ? "csr-co-neg" : "" %>"><%= dl(c.get("unspent"), vw, k, "unspent", null) %></td>
            <td class="csr-num"><%= dl(c.get("retention"), vw, k, "retention", null) %></td>
            <td class="csr-num"><%= dl(c.get("unpaid"), vw, k, "unpaid", null) %></td>
            <td class="csr-num <%= "1".equals(c.get("freeNeg")) ? "csr-co-neg" : "" %>"><%= dl(c.get("free"), vw, k, "free", null) %></td>
            <td class="csr-num"><%= dl(c.get("utilisation"), vw, k, "utilisation", null) %></td>
          </tr>
          <% } %>
          <% if (posRows.size() == 1) { %>
          <tr><td colspan="11" class="csr-empty">No Management Approvals yet.</td></tr>
          <% } %>
        </tbody>
      </table>
    </div>
    <% } %>
  </section>
  <% if (companyError != null) break; } %>

  <% if (monthly != null) { %>
  <section class="csr-co-card" aria-labelledby="month-title" id="monthPosition">
    <div class="csr-card-head">
      <div class="csr-card-title" id="month-title">Month-wise Receipts vs Utilisation <span class="csr-small">(&#8377;)</span></div>
      <label class="csr-co-fy" for="fySelect">Financial year
        <select id="fySelect">
          <% for (String[] y : monthlyYears) { %>
          <option value="<%= y[0] %>" <%= y[0].equals(monthlyFy) ? "selected" : "" %>><%= y[1] %></option>
          <% } %>
        </select>
        <span>starts <b><%= request.getAttribute("monthlyFyStart") %></b></span>
      </label>
    </div>
    <div class="csr-table-wrap">
      <table class="csr-table csr-co-table">
        <thead>
          <tr>
            <th>Month</th>
            <th class="csr-num">Received from Company</th>
            <th class="csr-num">Net Paid to Vendors</th>
            <th class="csr-num">TDS Deducted</th>
            <th class="csr-num">Total Utilised</th>
            <th class="csr-num">Net Flow</th>
            <th class="csr-num">Cumulative Unspent</th>
          </tr>
        </thead>
        <tbody>
          <% for (Map<String, String> mrow : monthly) { boolean tot = "1".equals(mrow.get("total")); String mk = mrow.get("key"); %>
          <tr class="<%= tot ? "csr-co-total" : "csr-row" %>">
            <td><%= mrow.get("month") %></td>
            <td class="csr-num"><%= dl(mrow.get("received"), "month", mk, "received", monthlyFy) %></td>
            <td class="csr-num"><%= dl(mrow.get("paid"), "month", mk, "paid", monthlyFy) %></td>
            <td class="csr-num"><%= dl(mrow.get("tds"), "month", mk, "tds", monthlyFy) %></td>
            <td class="csr-num"><%= dl(mrow.get("utilised"), "month", mk, "utilised", monthlyFy) %></td>
            <td class="csr-num <%= "1".equals(mrow.get("flowNeg")) ? "csr-co-neg" : "" %>"><%= dl(mrow.get("flow"), "month", mk, "flow", monthlyFy) %></td>
            <td class="csr-num <%= "1".equals(mrow.get("cumNeg")) ? "csr-cum-neg" : "" %>"><%= dl(mrow.get("cumulative"), "month", mk, "cumulative", monthlyFy) %></td>
          </tr>
          <% } %>
        </tbody>
      </table>
    </div>
  </section>
  <% } %>

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

<div class="dd-modal" id="ddModal" role="dialog" aria-modal="true" aria-labelledby="ddTitle">
  <div class="dd-box">
    <div class="dd-head">
      <div class="dd-title" id="ddTitle"></div>
      <button type="button" class="csr-btn csr-btn-sm csr-btn-outline" id="ddClose">Close</button>
    </div>
    <div class="dd-body" id="ddBody"></div>
  </div>
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

  // ---- amount popups: CsrDashboardServlet?action=detail&view=&key=&col=[&fy=]
  var modal = document.getElementById('ddModal'), ddTitle = document.getElementById('ddTitle'), ddBody = document.getElementById('ddBody');
  function el(tag, cls, txt) { var e = document.createElement(tag); if (cls) e.className = cls; if (txt != null) e.textContent = txt; return e; }
  function closeDd() { modal.classList.remove('open'); }
  // n = amount (right, one line), d = date / month / short code (one line), t = text (wraps)
  function cellClass(d, i, v) {
    if (d.num[i]) return 'n';
    return (v == null || v.length <= 14 || /^\d{2}-\d{2}-\d{4}$/.test(v)) ? 'd' : 't';
  }
  function showDd(d) {
    ddTitle.textContent = d.title;
    ddBody.replaceChildren();
    if (!d.rows || !d.rows.length) { ddBody.appendChild(el('div', 'dd-msg', 'No entries.')); return; }
    var t = el('table', 'csr-table'), th = el('thead'), hr = el('tr'), tb = el('tbody');
    d.cols.forEach(function (c, i) { hr.appendChild(el('th', d.num[i] ? 'n' : '', c)); });
    th.appendChild(hr); t.appendChild(th);
    d.rows.forEach(function (r) {
      var tr = el('tr');
      r.forEach(function (v, i) { tr.appendChild(el('td', cellClass(d, i, v), v)); });
      tb.appendChild(tr);
    });
    t.appendChild(tb);
    if (d.foot) {
      var tf = el('tfoot'), fr = el('tr');
      d.foot.forEach(function (v, i) { fr.appendChild(el('td', cellClass(d, i, v), v)); });
      tf.appendChild(fr); t.appendChild(tf);
    }
    ddBody.appendChild(t);
  }
  document.addEventListener('click', function (e) {
    var a = e.target.closest ? e.target.closest('a.dd-link') : null;
    if (!a) return;
    e.preventDefault();
    var q = 'action=detail&view=' + encodeURIComponent(a.dataset.view) + '&key=' + encodeURIComponent(a.dataset.key)
          + '&col=' + encodeURIComponent(a.dataset.col) + (a.dataset.fy ? '&fy=' + encodeURIComponent(a.dataset.fy) : '');
    ddTitle.textContent = 'Loading...';
    ddBody.replaceChildren();
    modal.classList.add('open');
    fetch('CsrDashboardServlet?' + q, { headers: { 'Accept': 'application/json' } })
      .then(function (r) { return r.json(); })
      .then(function (d) {
        if (!d.ok) { ddTitle.textContent = 'Details'; ddBody.appendChild(el('div', 'dd-msg', d.message || 'Details could not be loaded.')); return; }
        showDd(d);
      })
      .catch(function () { ddTitle.textContent = 'Details'; ddBody.appendChild(el('div', 'dd-msg', 'Details could not be loaded. Please try again.')); });
  });
  document.getElementById('ddClose').addEventListener('click', closeDd);
  modal.addEventListener('click', function (e) { if (e.target === modal) closeDd(); });
  document.addEventListener('keydown', function (e) { if (e.key === 'Escape') closeDd(); });
  var fy = document.getElementById('fySelect');
  if (fy) fy.addEventListener('change', function () {
    location.href = 'CsrDashboardServlet?fy=' + encodeURIComponent(fy.value) + (select.value ? '&letterId=' + encodeURIComponent(select.value) : '') + '#monthPosition';
  });
  if (select.value) loadApproval();
}());
</script>
</body>
</html>
