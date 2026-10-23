<%
    // Must be opened through CsrLetterServlet?action=view&id=N (loads data + checks Global role)
    if (request.getAttribute("letter") == null) {
        response.sendRedirect("CsrLetterServlet");
        return;
    }
    com.google.gson.Gson gson = new com.google.gson.Gson();   // escapes < > & : safe inside <script>
    // funding company of this approval (Masters > Companies); shown wherever the page used to say SMIORE
    @SuppressWarnings("unchecked")
    String coName = ((java.util.Map<String, String>) request.getAttribute("letter")).get("companyName");
    if (coName == null || coName.trim().isEmpty()) coName = "Company";
    String coH = coName.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Approval Letter</title>

<!-- INCLUDE SHARED HEADER & MENU -->
<%@ include file="header.jsp" %>

<%-- CSS is included inline: ScholarshipListServelt is mapped to "/" and would intercept a separate .css request --%>
<style>
<%@ include file="css/csrLetter.css" %>
</style>
<style>
<%@ include file="css/finance.css" %>
</style>
<style>
  /* ---- letter strip ---- */
  .lv-info { display: grid; grid-template-columns: 1.2fr 1.2fr 1fr 1fr 1fr 2fr; gap: 6px 18px; padding: 9px 12px; }
  .lv-k { font-size: 10.5px; font-weight: 600; letter-spacing: .5px; text-transform: uppercase; color: #64748b; }
  .lv-v { font-size: 13px; color: #0f172a; margin-top: 2px; white-space: pre-wrap; }

  /* ---- tabs ---- */
  .lv-tabs { display: flex; gap: 2px; border-bottom: 1px solid #cbd5e1; margin: 12px 0 0; flex-wrap: wrap; }
  .lv-tab { padding: 7px 14px; font-size: 12.5px; font-weight: 600; color: #475569; background: transparent; border: 1px solid transparent;
            border-bottom: none; border-radius: 6px 6px 0 0; cursor: pointer; margin-bottom: -1px; }
  .lv-tab:hover { color: #0f172a; background: #f8fafc; }
  .lv-tab.on { color: #0f766e; background: #fff; border-color: #cbd5e1; }
  .lv-tab .lv-n { display: inline-block; min-width: 18px; padding: 0 5px; margin-left: 5px; border-radius: 9px; background: #f1f5f9;
                  color: #334155; font-size: 10.5px; text-align: center; }
  .lv-pane { display: none; padding-top: 10px; }
  .lv-pane.on { display: block; }
  .lv-pane > .csr-card + .csr-card, .lv-pane > .lv-two + .csr-card { margin-top: 10px; }

  /* ---- statements ---- */
  .lv-two { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; }
  table.lv-stmt { width: 100%; border-collapse: collapse; font-size: 13px; }
  .lv-stmt td { padding: 6px 12px; border-bottom: 1px solid #eef2f6; }
  .lv-stmt td.lv-ref { width: 34px; color: #94a3b8; font-size: 11px; font-weight: 600; text-align: center; }
  .lv-stmt td.lv-amt { text-align: right; white-space: nowrap; width: 150px; font-weight: 500; }
  .lv-stmt tr.lv-sub td { color: #475569; font-size: 12.5px; }
  .lv-stmt tr.lv-sub td:nth-child(2) { padding-left: 28px; }
  .lv-stmt tr.lv-tot td { font-weight: 700; border-top: 1px solid #cbd5e1; background: #f8fafc; }
  .lv-stmt tr.lv-due td { font-weight: 700; color: #b45309; background: #fffbeb; }
  .lv-stmt tr.lv-ok td { font-weight: 700; color: #047857; background: #f0fdf4; }
  .lv-stmt tr.lv-bad td { font-weight: 700; color: #b91c1c; background: #fef2f2; }
  .lv-stmt .lv-hint { font-weight: 400; color: #94a3b8; font-size: 11px; margin-left: 6px; }

  /* ---- pending points ---- */
  .lv-points { padding: 4px 12px 6px; }
  .lv-pt { display: flex; align-items: center; gap: 10px; padding: 7px 0; border-bottom: 1px dashed #e2e8f0; font-size: 13px; }
  .lv-pt:last-child { border-bottom: none; }
  .lv-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; background: #b45309; }
  .lv-pt.ok .lv-dot { background: #047857; }
  .lv-pt .lv-pt-amt { margin-left: auto; font-weight: 700; white-space: nowrap; }
  .lv-pt .csr-btn { margin-left: 8px; }

  .lv-none { padding: 14px; text-align: center; color: #64748b; font-size: 12.5px; }
  .lv-cr { color: #047857; }
  .lv-note { font-size: 11px; color: #64748b; padding: 6px 12px 8px; }
  .lv-wo-bills { padding: 10px 12px; background: #f8fafc; }
  .lv-wo-bills-summary { display: flex; flex-wrap: wrap; gap: 6px 18px; margin-bottom: 8px; color: #334155; font-size: 12px; }
  .lv-wo-bills-summary strong { color: #0f172a; }
  .lv-wo-bills table { width: 100%; border-collapse: collapse; background: #fff; font-size: 12px; }
  .lv-wo-bills th, .lv-wo-bills td { padding: 6px 8px; border: 1px solid #e2e8f0; text-align: left; }
  .lv-wo-bills th { color: #64748b; font-size: 10px; letter-spacing: .35px; text-transform: uppercase; }
  .lv-wo-bills .csr-num { text-align: right; white-space: nowrap; }
  .lv-confirm { font-size: 11.5px; font-weight: 600; color: #b91c1c; margin-right: 4px; }

  /* ---- Tally style ledger ---- */
  .tl-led + .tl-led { border-top: 6px solid #f1f5f9; }
  .tl-head { display: flex; justify-content: space-between; align-items: flex-end; gap: 12px; padding: 10px 12px 8px; border-bottom: 1px solid #cbd5e1; }
  .tl-name { font-size: 15px; font-weight: 700; color: #0f172a; }
  .tl-sub { font-size: 11.5px; color: #64748b; margin-top: 2px; }
  .tl-period { font-size: 11.5px; color: #334155; text-align: right; white-space: nowrap; }
  table.tl-table { width: 100%; border-collapse: collapse; font-size: 12.5px; }
  .tl-table th { padding: 6px 8px; font-size: 10.5px; font-weight: 600; letter-spacing: .4px; text-transform: uppercase; color: #475569;
                 text-align: left; border-bottom: 1px solid #cbd5e1; background: #f8fafc; }
  .tl-table td { padding: 5px 8px; border-bottom: 1px solid #eef2f6; vertical-align: top; }
  .tl-table .tl-num { text-align: right; white-space: nowrap; width: 130px; }
  .tl-table .tl-dc { width: 26px; color: #64748b; font-weight: 600; }
  .tl-table .tl-date { width: 92px; white-space: nowrap; }
  .tl-table .tl-vt { width: 96px; color: #334155; }
  .tl-table .tl-vn { width: 130px; color: #334155; }
  .tl-table .tl-part { font-weight: 600; color: #0f172a; }
  .tl-table .tl-narr { font-style: italic; font-weight: 400; color: #64748b; font-size: 11.5px; margin-top: 1px; }
  .tl-table tr.tl-row { cursor: pointer; }
  .tl-table tr.tl-row:hover td { background: #f0fdfa; }
  .tl-table tr.tl-foot td { font-weight: 600; background: #fff; border-bottom: none; }
  .tl-table tr.tl-foot.tl-total td { border-top: 1px solid #94a3b8; }
  .tl-table tr.tl-foot.tl-close td { border-top: 1px solid #94a3b8; border-bottom: 2px double #94a3b8; font-weight: 700; }
  .tl-table tr.tl-foot td.tl-lbl { text-align: right; color: #334155; }
  .tl-extra { display: flex; flex-wrap: wrap; gap: 4px 18px; padding: 6px 12px 10px; font-size: 11.5px; color: #475569; }
  .tl-extra b { color: #0f172a; }
  #bPayPos tr.csr-row { cursor: pointer; }
  .lv-wo-bills .tl-led { background: #fff; border: 1px solid #e2e8f0; border-radius: 4px; }
  .lv-wo-bills .tl-head { padding: 7px 10px 6px; }
  .lv-wo-bills .tl-name { font-size: 13px; }
  .lv-wo-bills .tl-table th, .lv-wo-bills .tl-table td { border-left: none; border-right: none; border-top: none; }
  .lv-wo-bills .tl-table tr.tl-foot.tl-total td, .lv-wo-bills .tl-table tr.tl-foot.tl-close td { border-top: 1px solid #94a3b8; }

  /* ---- voucher popup ---- */
  .lv-modal { display: none; position: fixed; inset: 0; z-index: 2000; background: rgba(15, 23, 42, .45); padding: 30px 16px; overflow-y: auto; }
  .lv-modal.on { display: block; }
  .lv-modal-box { max-width: 760px; margin: 0 auto; background: #fff; border-radius: 6px; box-shadow: 0 10px 30px rgba(15, 23, 42, .25); }
  .lv-modal-head { display: flex; justify-content: space-between; align-items: flex-start; padding: 12px 16px; border-bottom: 2px solid #0f766e; }
  .lv-modal-type { font-size: 10.5px; font-weight: 700; letter-spacing: .6px; text-transform: uppercase; color: #0f766e; }
  .lv-modal-title { font-size: 16px; font-weight: 700; color: #0f172a; margin-top: 2px; }
  .lv-modal-x { border: none; background: none; font-size: 24px; line-height: 1; color: #64748b; cursor: pointer; padding: 0 4px; }
  .lv-modal-x:hover { color: #0f172a; }
  .lv-modal-body { padding: 12px 16px; }
  .lv-modal-foot { display: flex; justify-content: space-between; align-items: center; gap: 8px; padding: 10px 16px; border-top: 1px solid #e2e8f0; background: #f8fafc; border-radius: 0 0 6px 6px; }
  .vm-info { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 8px 16px; margin-bottom: 12px; }
  .vm-info .vm-wide { grid-column: 1 / -1; }
  .vm-k { font-size: 10.5px; font-weight: 600; letter-spacing: .5px; text-transform: uppercase; color: #64748b; }
  .vm-v { font-size: 13px; color: #0f172a; margin-top: 2px; white-space: pre-wrap; }
  table.vm-stmt { width: 100%; border-collapse: collapse; font-size: 13px; border: 1px solid #e2e8f0; }
  .vm-stmt td { padding: 5px 10px; border-bottom: 1px solid #eef2f6; }
  .vm-stmt td.vm-amt { text-align: right; white-space: nowrap; width: 150px; }
  .vm-stmt tr.vm-sub td:first-child { padding-left: 24px; color: #475569; }
  .vm-stmt tr.vm-tot td { font-weight: 700; background: #f8fafc; border-top: 1px solid #cbd5e1; }
  .vm-stmt tr.vm-net td { font-weight: 700; font-size: 14px; color: #047857; background: #f0fdf4; border-top: 2px solid #cbd5e1; }
  .vm-stmt .vm-hint { color: #94a3b8; font-size: 11px; margin-left: 6px; }
  .vm-words { margin-top: 8px; font-size: 12px; color: #334155; }
  .vm-words b { color: #0f172a; }
  @media (max-width: 700px) { .vm-info { grid-template-columns: 1fr 1fr; } }

  @media (max-width: 1000px) {
    .lv-info { grid-template-columns: 1fr 1fr; }
    .lv-two { grid-template-columns: 1fr; }
  }

  /* ---- print: one compact statement (#printReport) instead of every tab ---- */
  #printReport { display: none; }
  @page { size: A4 portrait; margin: 11mm 10mm; }
  @media print {
    .kss-navbar-scope, .kss-footer-scope { display: none !important; }
    body { background: #fff !important; padding: 0 !important; }
    a { color: inherit !important; text-decoration: none !important; border: none !important; }
    body:not(.lv-modal-open) .csr-page, body:not(.lv-modal-open) .lv-modal { display: none !important; }
    body:not(.lv-modal-open) #printReport { display: block !important; }
    body.lv-modal-open .csr-page, body.lv-modal-open #printReport { display: none !important; }
    body.lv-modal-open .lv-modal { position: static !important; background: none !important; padding: 0 !important; }
    body.lv-modal-open .lv-modal-box { box-shadow: none !important; max-width: none !important; }
    .lv-modal-foot, .lv-modal-x { display: none !important; }
  }
  .pr { font-family: 'IBM Plex Sans', 'Segoe UI', Roboto, Arial, sans-serif; color: #0f172a; font-size: 10px; line-height: 1.35;
        font-variant-numeric: tabular-nums; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
  .pr-top { display: flex; justify-content: space-between; align-items: flex-end; border-bottom: 2px solid #0f172a; padding-bottom: 4px; }
  .pr-org { font-size: 9px; font-weight: 700; letter-spacing: .6px; text-transform: uppercase; color: #475569; }
  .pr-title { font-size: 15px; font-weight: 700; }
  .pr-meta { font-size: 9px; color: #475569; text-align: right; }
  .pr-info { display: flex; flex-wrap: wrap; gap: 2px 16px; padding: 4px 0 2px; font-size: 9.5px; color: #334155; }
  .pr-info b { color: #0f172a; }
  .pr h3 { font-size: 10px; font-weight: 700; letter-spacing: .5px; text-transform: uppercase; color: #0f766e; margin: 9px 0 3px;
           border-bottom: 1px solid #cbd5e1; padding-bottom: 2px; }
  .pr-three { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 8px; }
  .pr table { width: 100%; border-collapse: collapse; }
  .pr th { font-size: 8.5px; font-weight: 600; text-transform: uppercase; letter-spacing: .3px; color: #475569; text-align: left;
           border-bottom: 1px solid #94a3b8; padding: 2px 4px; }
  .pr td { padding: 2px 4px; border-bottom: 1px solid #e2e8f0; vertical-align: top; }
  .pr .n { text-align: right; white-space: nowrap; }
  .pr tr.t td { font-weight: 700; border-top: 1px solid #94a3b8; border-bottom: 1px solid #94a3b8; }
  .pr tr.s td:first-child { padding-left: 12px; color: #475569; }
  .pr tr.k td { font-weight: 700; }
  .pr .pr-st td:first-child { width: 14px; color: #94a3b8; font-weight: 600; }
  .pr-due { color: #b45309; font-weight: 700; }
  .pr-pend { margin: 0; padding-left: 14px; }
  .pr-pend li { padding: 1px 0; }
  .pr-sign { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 24px; margin-top: 34px; font-size: 9.5px; text-align: center; }
  .pr-sign div { border-top: 1px solid #0f172a; padding-top: 3px; }
  .pr-note { font-size: 8.5px; color: #64748b; margin-top: 6px; }
  .pr tr, .pr-three { page-break-inside: avoid; }
</style>
</head>
<body>

<div class="csr-page">

  <div class="csr-header">
    <div>
      <div class="csr-subtitle"><a href="CsrLetterServlet" style="color:inherit;"><%= com.Bean.AppConfig.code() %> CSR Amount Spending &rsaquo; Management Approvals</a></div>
      <h1 class="csr-title" id="lvTitle"></h1>
      <div id="lvName" style="font-size:13px; color:#334155;"></div>
    </div>
    <div class="csr-actions lv-noprint" id="lvActions">
      <button type="button" class="csr-btn csr-btn-sm csr-btn-outline" onclick="window.print()">&#128424; Print</button>
      <a href="CsrLetterServlet" class="csr-btn csr-btn-sm csr-btn-outline csr-link-btn">&#8592; Back to Management Approvals</a>
    </div>
  </div>

  <div id="csrError" class="csr-alert csr-alert-err" style="display:none;"></div>
  <div id="csrToast" class="csr-alert lv-noprint" style="display:none;"></div>

  <div class="csr-card"><div class="lv-info" id="lvInfo"></div></div>

  <div class="lv-tabs" id="lvTabs">
    <button type="button" class="lv-tab" data-tab="summary">Summary</button>
    <button type="button" class="lv-tab" data-tab="wo">Work Orders <span class="lv-n" id="nWo">0</span></button>
    <button type="button" class="lv-tab" data-tab="bills">Bills <span class="lv-n" id="nInv">0</span></button>
    <button type="button" class="lv-tab" data-tab="pay">Vendor Payments <span class="lv-n" id="nPay">0</span></button>
    <button type="button" class="lv-tab" data-tab="frl">Fund Requests (FRL) <span class="lv-n" id="nFrl">0</span></button>
    <button type="button" class="lv-tab" data-tab="rcpt">Receipts <span class="lv-n" id="nRc">0</span></button>
    <button type="button" class="lv-tab" data-tab="ledger"><%= coH %> Ledger</button>
  </div>

  <!-- ================= SUMMARY ================= -->
  <div class="lv-pane" id="tab-summary" data-title="Summary">
    <div class="lv-two">
      <div class="csr-card">
        <div class="csr-card-head"><div class="csr-card-title">Budget &amp; Spending <span class="csr-small">(&#8377;)</span></div></div>
        <table class="lv-stmt" id="stBudget"></table>
      </div>
      <div class="csr-card">
        <div class="csr-card-head"><div class="csr-card-title">Funds from <%= coH %> <span class="csr-small">(&#8377;)</span></div></div>
        <table class="lv-stmt" id="stFunds"></table>
      </div>
    </div>

    <div class="csr-card">
      <div class="csr-card-head"><div class="csr-card-title">Payments to Vendors <span class="csr-small">(&#8377;)</span></div></div>
      <table class="lv-stmt" id="stVendor"></table>
    </div>

    <div class="csr-card">
      <div class="csr-card-head"><div class="csr-card-title">Pending Points</div></div>
      <div class="lv-points" id="stPoints"></div>
    </div>

    <div class="csr-card">
      <div class="csr-card-head"><div class="csr-card-title">Work Order-wise Position <span class="csr-small">(&#8377;)</span></div></div>
      <div class="csr-table-wrap">
        <table class="csr-table">
          <thead><tr>
            <th>WO No</th><th>Vendor</th><th class="csr-num">WO Value</th><th class="csr-num">Billed (Tax Inv)</th>
            <th class="csr-num">To be Billed</th><th class="csr-num">Open Proforma Invoices</th><th class="csr-num">Claimed (FRL)</th>
            <th class="csr-num">Not Claimed</th>
          </tr></thead>
          <tbody id="bWoPos"></tbody>
        </table>
      </div>
    </div>
  </div>

  <!-- ================= WORK ORDERS ================= -->
  <div class="lv-pane" id="tab-wo" data-title="Work Orders">
    <div class="csr-card">
      <div class="csr-card-head">
        <div class="csr-card-title">Work Orders <span class="csr-small">(&#8377;)</span></div>
        <a class="csr-btn csr-btn-sm csr-link-btn lv-act" id="btnWo">+ New Work Order</a>
      </div>
      <div class="csr-table-wrap">
        <table class="csr-table">
          <thead><tr>
            <th>WO No</th><th>Date</th><th>Vendor</th><th>GSTIN</th><th class="csr-num">Taxable Value</th><th class="csr-num">GST</th>
            <th class="csr-num">WO Value</th><th>Copy</th><th class="lv-act">Action</th>
          </tr></thead>
          <tbody id="bWo"></tbody>
        </table>
      </div>
    </div>
  </div>

  <!-- ================= BILLS ================= -->
  <div class="lv-pane" id="tab-bills" data-title="Bills (Proforma / Tax Invoices)">
    <div class="csr-card">
      <div class="csr-card-head"><div class="csr-card-title">Bills: Proforma &amp; Tax Invoices <span class="csr-small">(&#8377;)</span></div></div>
      <div class="csr-table-wrap">
        <table class="csr-table">
          <thead><tr>
            <th>Date</th><th>Type</th><th>Bill No</th><th>WO No</th><th>Vendor</th><th class="csr-num">Taxable Value</th>
            <th class="csr-num">GST %</th><th class="csr-num">GST</th><th class="csr-num">Amount</th><th>Proforma / Settlement</th>
            <th class="csr-num">Claim</th><th>FRL</th><th>Copy</th><th class="lv-act">Action</th>
          </tr></thead>
          <tbody id="bInv"></tbody>
        </table>
      </div>
    </div>
  </div>

  <!-- ================= VENDOR PAYMENTS ================= -->
  <div class="lv-pane" id="tab-pay" data-title="Vendor Payments">
    <div class="csr-card">
      <div class="csr-card-head"><div class="csr-card-title">Vendor-wise Summary <span class="csr-small">(&#8377;)</span></div></div>
      <div class="csr-table-wrap">
        <table class="csr-table">
          <thead><tr>
            <th>WO No</th><th>Vendor</th><th class="csr-num">Bills (Tax Inv)</th><th class="csr-num">Debit Notes</th><th class="csr-num">TDS</th>
            <th class="csr-num">Retention</th><th class="csr-num">Net Payable</th><th class="csr-num">Advance Paid</th>
            <th class="csr-num">Paid against Bills</th><th class="csr-num">Closing Balance</th><th class="csr-num">Advance not Adjusted</th>
          </tr></thead>
          <tbody id="bPayPos"></tbody>
        </table>
      </div>
      <div class="lv-note">Click a vendor to open its ledger under Work Orders. Closing Balance Cr = still payable to the vendor; Dr = paid more than billed (advance).</div>
    </div>

    <div class="csr-card">
      <div class="csr-card-head"><div class="csr-card-title">Bills Awaiting Payment <span class="csr-small">(&#8377;)</span></div></div>
      <div class="csr-table-wrap">
        <table class="csr-table">
          <thead><tr>
            <th>Bill Date</th><th>Bill No</th><th>WO No</th><th>Vendor</th><th>Particulars</th><th class="csr-num">Taxable Value</th>
            <th class="csr-num">GST</th><th class="csr-num">Bill Amount</th><th class="csr-num">Paid so far</th>
            <th class="csr-num">Balance Due</th><th class="lv-act">Action</th>
          </tr></thead>
          <tbody id="bPayDue"></tbody>
        </table>
      </div>
    </div>
  </div>

  <!-- ================= FRLs ================= -->
  <div class="lv-pane" id="tab-frl" data-title="Fund Requests (FRL)">
    <div class="csr-card">
      <div class="csr-card-head">
        <div class="csr-card-title">Fund Requests sent to <%= coH %> <span class="csr-small">(&#8377;)</span></div>
        <a class="csr-btn csr-btn-sm csr-link-btn lv-act" id="btnFrl">+ New FRL</a>
      </div>
      <div class="csr-table-wrap">
        <table class="csr-table">
          <thead><tr>
            <th>Date</th><th>FRL No</th><th>Bills Covered</th><th class="csr-num">Amount Claimed</th><th class="csr-num">Received</th>
            <th class="csr-num">Outstanding</th><th>Status</th><th>Remarks</th><th>Copy</th><th class="lv-act">Action</th>
          </tr></thead>
          <tbody id="bFrl"></tbody>
        </table>
      </div>
    </div>
  </div>

  <!-- ================= RECEIPTS ================= -->
  <div class="lv-pane" id="tab-rcpt" data-title="Receipts">
    <div class="csr-card">
      <div class="csr-card-head"><div class="csr-card-title">Funds Received from <%= coH %> <span class="csr-small">(&#8377;)</span></div></div>
      <div class="csr-table-wrap">
        <table class="csr-table">
          <thead><tr>
            <th>Date</th><th>Against FRL</th><th>Mode</th><th>UTR / Cheque No</th><th>Bank</th>
            <th class="csr-num">Amount</th><th>Remarks</th><th>Copy</th><th class="lv-act">Action</th>
          </tr></thead>
          <tbody id="bRc"></tbody>
        </table>
      </div>
    </div>
  </div>

  <!-- ================= LEDGER ================= -->
  <div class="lv-pane" id="tab-ledger" data-title="<%= coH %> Ledger">
    <div class="csr-card">
      <div class="csr-card-head"><div class="csr-card-title"><%= coH %> Receivable Ledger <span class="csr-small">(&#8377;)</span></div></div>
      <div class="csr-table-wrap">
        <table class="csr-table">
          <thead><tr>
            <th>Date</th><th>Voucher</th><th>Ref No</th><th>Particulars</th>
            <th class="csr-num">Debit (Claimed)</th><th class="csr-num">Credit (Received)</th><th class="csr-num">Balance</th>
          </tr></thead>
          <tbody id="bLed"></tbody>
        </table>
      </div>
      <div class="lv-note">Debit: amount claimed from <%= coH %> through an FRL. Credit: amount received. Balance Dr: still to be received from <%= coH %>; Cr: received more than claimed.</div>
    </div>
  </div>
</div>

<!-- ================= PRINT REPORT (filled by script) ================= -->
<div id="printReport" class="pr"></div>

<!-- ================= VOUCHER POPUP ================= -->
<div class="lv-modal" id="vModal" role="dialog" aria-modal="true" aria-labelledby="vTitle">
  <div class="lv-modal-box">
    <div class="lv-modal-head">
      <div>
        <div class="lv-modal-type" id="vType"></div>
        <div class="lv-modal-title" id="vTitle"></div>
      </div>
      <button type="button" class="lv-modal-x js-vclose" title="Close (Esc)">&times;</button>
    </div>
    <div class="lv-modal-body" id="vBody"></div>
    <div class="lv-modal-foot">
      <div class="csr-actions" id="vActions"></div>
      <button type="button" class="csr-btn csr-btn-sm csr-btn-outline js-vclose">Close</button>
    </div>
  </div>
</div>

<script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
<script>
$(function () {
  var L   = <%= gson.toJson(request.getAttribute("letter")) %>;
  var CO  = <%= gson.toJson(coName) %>;   // funding company
  var WO  = <%= gson.toJson(request.getAttribute("workOrders")) %> || [];
  var INV = <%= gson.toJson(request.getAttribute("invoices")) %> || [];
  var FRL = <%= gson.toJson(request.getAttribute("frls")) %> || [];
  var RC  = <%= gson.toJson(request.getAttribute("receipts")) %> || [];
  var ADV = <%= gson.toJson(request.getAttribute("advances")) %> || [];
  var PV  = <%= gson.toJson(request.getAttribute("vouchers")) %> || [];
  var BP  = <%= gson.toJson(request.getAttribute("billParticulars")) %> || [];
  var loadError = <%= gson.toJson(request.getAttribute("error")) %>;
  var payError  = <%= gson.toJson(request.getAttribute("payError")) %>;
  var RS = String.fromCharCode(8377);

  if (loadError || payError) $('#csrError').text([loadError, payError].filter(Boolean).join(' ')).show();

  // ---------- helpers
  function noFrl(v) { var x = String(v.frl_required); return x === '0' || x === 'false'; }   // tax invoice marked "No FRL"
  function r2(v) { return Math.round((Number(v) || 0) * 100) / 100; }
  function amt(v) {                       // accounts style: 1,23,456.00 ; zero "-" ; negative in brackets
    v = r2(v);
    if (v === 0) return '-';
    var s = Math.abs(v).toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    return v < 0 ? '(' + s + ')' : s;
  }
  function money(v) { return RS + ' ' + (r2(v) === 0 ? '0.00' : amt(v)); }
  function dmy(s) { var p = String(s || '').split('-'); return p.length === 3 ? p[2] + p[1] + p[0] : ''; }   // dd-mm-yyyy -> yyyymmdd
  function td(text, cls) { return $('<td></td>').addClass(cls || '').text(text == null ? '' : text); }
  function nTd(v, strong) { return $('<td class="csr-num"></td>').toggleClass('csr-strong', !!strong).text(amt(v)); }
  function fileTd(size, href) {
    return size ? $('<td></td>').append($('<a class="csr-pdf" target="_blank"></a>').attr('href', href).html('&#128206; View'))
                : td('-', 'csr-small');
  }
  function btn(text, href, outline) {
    return $('<a class="csr-btn csr-btn-sm csr-link-btn"></a>').toggleClass('csr-btn-outline', !!outline).attr('href', href).html(text);
  }
  function actTd() {
    var $d = $('<div class="csr-actions"></div>');
    for (var i = 0; i < arguments.length; i++) $d.append(arguments[i]);
    return $('<td class="lv-act"></td>').append($d);
  }
  function totRow(cells) {               // number -> amount cell, 'ACT' -> hidden-on-print cell, text -> text
    var $tr = $('<tr class="csr-total-row"></tr>');
    cells.forEach(function (c) {
      if (typeof c === 'number') $tr.append(nTd(c));
      else if (c === 'ACT') $tr.append('<td class="lv-act"></td>');
      else $tr.append(td(c));
    });
    return $tr;
  }
  function none(cols, text) { return $('<tr></tr>').append($('<td class="lv-none"></td>').attr('colspan', cols).text(text)); }

  // ---------- figures
  var A  = r2(L.amount);                                   // sanctioned
  var B  = 0; WO.forEach(function (w) { B += +w.total_amount; }); B = r2(B);
  // C = tax invoices only. Proforma invoices count separately while open (not settled by a tax invoice).
  var C = 0, PO = 0, POC = 0, U = 0;                       // tax invoices, open proformas, claimed open proformas, not yet claimed
  INV.forEach(function (v) {
    if (v.invoice_type === 'Proforma') {
      if (!v.settled_by) { PO += +v.amount; if (v.frl_number) POC += +v.claim_amount; }
    } else {
      C += +v.amount;
    }
    if (!v.frl_number) U += +v.claimable;
  });
  C = r2(C); PO = r2(PO); POC = r2(POC); U = r2(U);
  // Tax invoices marked "No FRL": subtract any amount already claimed against their proforma invoice.
  var NF = 0;
  INV.forEach(function (v) {
    if (v.invoice_type === 'Proforma' || !noFrl(v)) return;
    var adv = 0;
    INV.forEach(function (p) { if (p.invoice_type === 'Proforma' && p.invoice_number === v.proforma_number && p.frl_number) adv = +p.claim_amount; });
    NF += +v.amount - adv;
  });
  NF = r2(NF);
  var D = 0; FRL.forEach(function (r) { D += +r.amount; }); D = r2(D);       // claimed through FRLs
  var E = 0, OTH = 0;                                                        // received against FRL / without FRL
  RC.forEach(function (f) { if (f.frl_id) E += +f.amount; else OTH += +f.amount; });
  E = r2(E); OTH = r2(OTH);

  // ---------- payments to vendors (advances against work orders, vouchers against tax invoices)
  var PART = {}; BP.forEach(function (b) { PART[b.id] = b.particulars || ''; });
  // a bill can be paid in parts: PVBY[invoice id] = its vouchers in date order; each voucher settles net + deductions
  function settledBy(p) { return r2(+p.net_paid + +p.debit_note_amount + +p.tds_amount + +p.retention_amount + +p.advance_adjusted); }
  var PVBY = {};
  PV.forEach(function (p) { (PVBY[p.invoice_id] = PVBY[p.invoice_id] || []).push(p); });
  function billPaid(v) { return r2((PVBY[v.id] || []).reduce(function (s, p) { return s + settledBy(p); }, 0)); }
  function billDue(v) { return r2(+v.amount - billPaid(v)); }
  function settledBefore(p) {               // settled on the same bill by vouchers before this one
    var s = 0, list = PVBY[p.invoice_id] || [];
    for (var i = 0; i < list.length && String(list[i].id) !== String(p.id); i++) s += settledBy(list[i]);
    return r2(s);
  }
  var VP = {};                                                     // per work order
  WO.forEach(function (w) { VP[w.id] = { bills: 0, dn: 0, tds: 0, ret: 0, adv: 0, adj: 0, paid: 0 }; });
  function vp(woId) { return VP[woId] || (VP[woId] = { bills: 0, dn: 0, tds: 0, ret: 0, adv: 0, adj: 0, paid: 0 }); }
  INV.forEach(function (v) { if (v.invoice_type !== 'Proforma') vp(v.wo_id).bills += +v.amount; });
  PV.forEach(function (p) {
    var x = vp(p.wo_id);
    x.dn += +p.debit_note_amount; x.tds += +p.tds_amount; x.ret += +p.retention_amount; x.adj += +p.advance_adjusted; x.paid += +p.net_paid;
  });
  ADV.forEach(function (a) { vp(a.wo_id).adv += +a.amount; });
  var VT = { bills: 0, dn: 0, tds: 0, ret: 0, adv: 0, adj: 0, paid: 0 };
  Object.keys(VP).forEach(function (k) { Object.keys(VT).forEach(function (f) { VT[f] += VP[k][f]; }); });
  Object.keys(VT).forEach(function (f) { VT[f] = r2(VT[f]); });
  var VNET = r2(VT.bills - VT.dn - VT.tds - VT.ret);                // net payable to vendors
  var VBAL = r2(VNET - VT.adv - VT.paid);                          // still to pay
  var UNPAID = INV.filter(function (v) { return v.invoice_type !== 'Proforma' && billDue(v) > 0; });
  var UNPAIDAMT = r2(UNPAID.reduce(function (s, v) { return s + billDue(v); }, 0));

  // ---------- header + strip
  document.title = L.letterNumber + ' - Approval Letter';
  $('#lvTitle').text(L.letterNumber);
  $('#lvName').text(L.letterName);
  $('#lvActions').prepend(btn('&#9998; Edit Letter', 'CsrLetterServlet?action=form&id=' + L.id, true));
  if (L.pdfSize) $('#lvActions').prepend(btn('&#128196; Letter PDF', 'CsrLetterServlet?action=pdf&id=' + L.id, true).attr('target', '_blank'));
  function info(k, v) { $('#lvInfo').append($('<div></div>').append($('<div class="lv-k"></div>').text(k)).append($('<div class="lv-v"></div>').text(v || '-'))); }
  info('Funding Company', L.companyName || 'Not set (edit the approval)');
  info('CSR Activity', L.activityKind);
  info('Place', L.place);
  info('Sanctioned Amount', money(A));
  info('Entered', (L.createdAt || '') + (L.createdBy ? ' by ' + L.createdBy : ''));
  info('Particulars', L.particulars);

  // ---------- summary: statements
  function line($t, ref, label, value, cls, hint) {
    var $tr = $('<tr></tr>').addClass(cls || '');
    $tr.append($('<td class="lv-ref"></td>').text(ref || ''));
    var $l = $('<td></td>').text(label); if (hint) $l.append($('<span class="lv-hint"></span>').text(hint));
    $tr.append($l).append($('<td class="lv-amt"></td>').text(amt(value)));
    $t.append($tr);
  }
  var $b = $('#stBudget');
  line($b, 'A', 'Sanctioned amount (approval letter)', A, 'lv-tot');
  line($b, 'B', 'Work orders issued', B, '', WO.length + ' WO' + (WO.length === 1 ? '' : 's'));
  line($b, '', 'Balance available for new work orders', A - B, A - B < 0 ? 'lv-bad' : 'lv-ok', 'A - B');
  line($b, 'C', 'Bills received (tax invoices)', C, 'lv-tot');
  line($b, '', 'Work order value not yet billed', B - C, B - C < 0 ? 'lv-bad' : '', 'B - C');
  line($b, '', 'of which open proforma invoices', PO, 'lv-sub');

  var $f = $('#stFunds');
  line($f, 'C', 'Bills received (tax invoices)', C);
  line($f, '', 'Add: open proforma invoices', PO, 'lv-sub');
  if (NF) line($f, '', 'Less: bills marked No FRL (covered by proforma invoices)', -NF, 'lv-sub');
  line($f, 'T', 'Total to be claimed from ' + CO, C + PO - NF, 'lv-tot', NF ? 'C + proforma invoices - No FRL' : 'C + proforma invoices');
  line($f, 'D', 'Claimed from ' + CO + ' through FRLs', D, '', FRL.length + ' FRL' + (FRL.length === 1 ? '' : 's'));
  line($f, '', 'Not yet claimed', U, U > 0 ? 'lv-due' : '', 'T - D');
  line($f, 'E', 'Received from ' + CO + ' against FRLs', E, 'lv-tot');
  line($f, '', 'Outstanding from ' + CO, D - E, D - E > 0 ? 'lv-due' : (D - E < 0 ? 'lv-bad' : 'lv-ok'), 'D - E');
  if (OTH) {
    line($f, '', 'Received without FRL (old entries)', OTH, 'lv-sub');
    line($f, '', 'Total received', E + OTH, 'lv-tot');
  }

  var $vs = $('#stVendor');
  line($vs, 'C', 'Bills received (tax invoices)', VT.bills, 'lv-tot');
  line($vs, '', 'Less: debit notes', -VT.dn, 'lv-sub');
  line($vs, '', 'Less: TDS deducted', -VT.tds, 'lv-sub');
  line($vs, '', 'Less: retention held', -VT.ret, 'lv-sub');
  line($vs, 'N', 'Net payable to vendors', VNET, 'lv-tot');
  line($vs, 'P', 'Advances paid to vendors', VT.adv, '', ADV.length + ' advance' + (ADV.length === 1 ? '' : 's'));
  line($vs, 'Q', 'Paid against bills (payment vouchers)', VT.paid, '', PV.length + ' voucher' + (PV.length === 1 ? '' : 's'));
  line($vs, '', VBAL < 0 ? 'Paid in advance, bills awaited' : 'Balance payable to vendors', VBAL,
       VBAL > 0 ? 'lv-due' : (VBAL < 0 ? 'lv-bad' : 'lv-ok'), 'N - P - Q');
  if (VT.ret) line($vs, '', 'Retention held, to be released to vendors', VT.ret, 'lv-sub');

  // ---------- summary: pending points
  var $p = $('#stPoints'), pts = 0;
  function point(text, value, $btn) {
    pts++;
    var $d = $('<div class="lv-pt"></div>').append('<span class="lv-dot"></span>').append($('<span></span>').text(text))
      .append($('<span class="lv-pt-amt"></span>').text(money(value)));
    if ($btn) $d.append($btn);
    $p.append($d);
  }
  if (!WO.length && A > 0) point('No work order issued yet', A, btn('+ Work Order', 'CsrWorkOrderServlet?action=form&letterId=' + L.id));
  if (B - C > 0)  point('Work order value not yet billed by vendors (tax invoice awaited)', B - C);
  if (POC > 0)    point('Proforma invoice claimed; final tax invoice awaited', POC);
  if (U > 0)      point('Bills / proforma invoices not yet claimed from ' + CO, U, btn('+ Raise FRL', 'CsrFrlServlet?action=form&letterId=' + L.id));
  if (D - E > 0)  point('Claimed from ' + CO + ', not yet received', D - E);
  if (UNPAID.length) point(UNPAID.length + ' tax invoice' + (UNPAID.length === 1 ? '' : 's') + ' not fully paid to vendors (balance due)', UNPAIDAMT,
                           btn('Pay Bills', '#pay').addClass('js-tab'));
  if (r2(VT.adv - VT.adj) > 0) point('Advance paid to vendors, not yet adjusted against bills', VT.adv - VT.adj,
                           btn('View', '#pay', true).addClass('js-tab'));
  if (!pts) $p.append($('<div class="lv-pt ok"></div>').append('<span class="lv-dot"></span>')
                 .append($('<span></span>').text('Nothing pending. All work billed, all bills claimed and paid, and all claims received.')));

  // ---------- summary: WO-wise position
  var pos = { v: 0, b: 0, tb: 0, a: 0, c: 0, nc: 0 };
  WO.forEach(function (w) {
    var tb = +w.total_amount - +w.tax_billed, nc = +w.unclaimed;
    pos.v += +w.total_amount; pos.b += +w.tax_billed; pos.tb += tb; pos.a += +w.pi_open; pos.c += +w.claimed; pos.nc += nc;
    $('#bWoPos').append($('<tr class="csr-row"></tr>').append(td(w.wo_number, 'csr-strong')).append(td(w.vendor_name))
      .append(nTd(w.total_amount, true)).append(nTd(w.tax_billed)).append(nTd(tb)).append(nTd(w.pi_open)).append(nTd(w.claimed))
      .append($('<td class="csr-num"></td>').text(amt(nc)).css({ color: nc > 0 ? '#b45309' : '', fontWeight: nc > 0 ? 600 : '' })));
  });
  if (WO.length) $('#bWoPos').append(totRow(['Total', '', pos.v, pos.b, pos.tb, pos.a, pos.c, pos.nc]));
  else $('#bWoPos').append(none(8, 'No work orders yet.'));

  var WOBY = {}; WO.forEach(function (w) { WOBY[w.id] = w; });
  var MON = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  function tdate(s) { var p = String(s || '').split('-'); return p.length === 3 ? p[0] + '-' + MON[+p[1] - 1] + '-' + p[2] : (s || ''); }   // dd-mm-yyyy -> dd-Mon-yyyy
  function pct(v) { return Number(v) ? Number(v) + ' %' : ''; }

  // Indian amount in words: Rupees One Lakh Sixty Nine Thousand Two Hundred Only
  function words(v) {
    var ones = ['', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten', 'Eleven', 'Twelve', 'Thirteen',
                'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'];
    var tens = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];
    function two(n) { return n < 20 ? ones[n] : tens[Math.floor(n / 10)] + (n % 10 ? ' ' + ones[n % 10] : ''); }
    function three(n) { return (n >= 100 ? ones[Math.floor(n / 100)] + ' Hundred' + (n % 100 ? ' ' : '') : '') + (n % 100 ? two(n % 100) : ''); }
    v = r2(Math.abs(v));
    var r = Math.floor(v), p = Math.round((v - r) * 100), out = [];
    var cr = Math.floor(r / 10000000); r %= 10000000;
    var lk = Math.floor(r / 100000); r %= 100000;
    var th = Math.floor(r / 1000); r %= 1000;
    if (cr) out.push((cr > 999 ? words(cr).replace(/^Rupees | Only$/g, '') : three(cr)) + ' Crore');
    if (lk) out.push(two(lk) + ' Lakh');
    if (th) out.push(two(th) + ' Thousand');
    if (r) out.push(three(r));
    var s = 'Rupees ' + (out.length ? out.join(' ') : 'Zero');
    if (p) s += ' and ' + two(p) + ' Paise';
    return s + ' Only';
  }

  // ---------- ledger entries per work order (books of KSS: bill = credit to the vendor, payment = debit)
  function ledgerOf(woId) {
    var e = [];
    INV.forEach(function (v) {
      if (String(v.wo_id) !== String(woId) || v.invoice_type === 'Proforma') return;
      e.push({ k: dmy(v.invoice_date) + '1' + ('00000' + v.id).slice(-6), date: v.invoice_date, dc: 'Cr', part: 'Purchase - CSR Expenses',
               narr: 'Bill ' + v.invoice_number + (PART[v.id] ? ': ' + PART[v.id] : '') + ' (taxable ' + amt(v.price) + ' + GST ' + amt(v.gst_amount) + ')',
               vt: 'Purchase', vn: v.invoice_number, dr: 0, cr: +v.amount, kind: 'bill', id: v.id });
    });
    ADV.forEach(function (a) {
      if (String(a.wo_id) !== String(woId)) return;
      e.push({ k: dmy(a.advance_date) + '0' + ('00000' + a.id).slice(-6), date: a.advance_date, dc: 'Dr', part: 'Bank (' + a.payment_mode + ')',
               narr: 'Advance paid' + (a.reference_no ? ', UTR / Cheque ' + a.reference_no : '') + (a.bank_name ? ', ' + a.bank_name : '') + (a.remarks ? '. ' + a.remarks : ''),
               vt: 'Payment', vn: a.reference_no || '-', dr: +a.amount, cr: 0, kind: 'advance', id: a.id });
    });
    PV.forEach(function (p) {
      if (String(p.wo_id) !== String(woId)) return;
      var k = dmy(p.payment_date) + '2' + ('00000' + p.id).slice(-6), bill = ' against bill ' + p.invoice_number;
      function add(n, part, narr, vt, dr) { e.push({ k: k + n, date: p.payment_date, dc: 'Dr', part: part, narr: narr, vt: vt, vn: p.voucher_no, dr: dr, cr: 0, kind: 'voucher', id: p.id }); }
      if (+p.debit_note_amount) add(1, 'Debit Note', (p.debit_note_remarks || '') + bill, 'Debit Note', +p.debit_note_amount);
      if (+p.tds_amount) add(2, 'TDS Payable u/s ' + p.tds_section, '@ ' + pct(p.tds_percent) + ' on taxable value ' + amt(p.price) + bill, 'Journal', +p.tds_amount);
      if (+p.retention_amount) add(3, 'Retention Money Payable', (+p.retention_percent ? '@ ' + pct(p.retention_percent) + ' of ' + amt(p.bill_amount) : 'Held') + bill, 'Journal', +p.retention_amount);
      var left = r2(+p.bill_amount - settledBefore(p) - settledBy(p));
      add(4, 'Bank (' + p.payment_mode + ')', (left > 0 || settledBefore(p) > 0 ? 'Part payment' : 'Payment') + bill
           + (left > 0 ? ' (balance due ' + amt(left) + ')' : (settledBefore(p) > 0 ? ' (final)' : '')) + (+p.advance_adjusted ? '; advance ' + amt(p.advance_adjusted) + ' adjusted' : '')
           + (p.reference_no ? ', UTR / Cheque ' + p.reference_no : '') + (p.bank_name ? ', ' + p.bank_name : ''), 'Payment', +p.net_paid);
    });
    return e.sort(function (a, b) { return a.k < b.k ? -1 : 1; });
  }

  function ledgerBlock(w) {
    var e = ledgerOf(w.id), dr = 0, cr = 0;
    var $b = $('<div class="tl-led"></div>').attr('data-wo', w.id);
    var first = e.length ? e[0].date : '', last = e.length ? e[e.length - 1].date : '';
    $b.append($('<div class="tl-head"></div>')
      .append($('<div></div>').append($('<div class="tl-name"></div>').text('Ledger: ' + w.vendor_name + '  (' + w.wo_number + ')')))
      .append($('<div class="tl-period"></div>').text(e.length ? tdate(first) + ' to ' + tdate(last) : 'No entries')));
    var $t = $('<table class="tl-table"><thead><tr><th class="tl-date">Date</th><th class="tl-dc"></th><th>Particulars</th>'
      + '<th class="tl-vt">Vch Type</th><th class="tl-vn">Vch No.</th><th class="tl-num">Debit</th><th class="tl-num">Credit</th></tr></thead><tbody></tbody></table>');
    var $tb = $t.find('tbody');
    e.forEach(function (x) {
      dr += x.dr; cr += x.cr;
      $tb.append($('<tr class="tl-row"></tr>').attr('data-kind', x.kind).attr('data-id', x.id)
        .append($('<td class="tl-date"></td>').text(tdate(x.date))).append($('<td class="tl-dc"></td>').text(x.dc))
        .append($('<td></td>').append($('<div class="tl-part"></div>').text(x.part)).append($('<div class="tl-narr"></div>').text(x.narr)))
        .append($('<td class="tl-vt"></td>').text(x.vt)).append($('<td class="tl-vn"></td>').text(x.vn))
        .append($('<td class="tl-num"></td>').text(x.dr ? amt(x.dr) : '')).append($('<td class="tl-num"></td>').text(x.cr ? amt(x.cr) : '')));
    });
    if (!e.length) $tb.append(none(7, 'No bills, advances or payments for this vendor yet.'));
    dr = r2(dr); cr = r2(cr);
    var bal = r2(cr - dr);
    function foot(cls, label, d, c) {
      return $('<tr class="tl-foot"></tr>').addClass(cls).append('<td></td><td></td>').append($('<td class="tl-lbl"></td>').text(label))
        .append('<td></td><td></td>').append($('<td class="tl-num"></td>').text(d)).append($('<td class="tl-num"></td>').text(c));
    }
    $tb.append(foot('', 'Opening Balance', '', ''));
    $tb.append(foot('tl-total', 'Current Total', amt(dr), amt(cr)));
    $tb.append(foot('tl-close', 'Closing Balance', bal < 0 ? amt(-bal) + ' Dr' : '', bal > 0 ? amt(bal) + ' Cr' : (bal === 0 ? 'Nil' : '')));
    $b.append($('<div class="csr-table-wrap"></div>').append($t));
    var x = VP[w.id];
    $b.append($('<div class="tl-extra"></div>')
      .append($('<span>Advance paid </span>').append($('<b></b>').text(money(x.adv))))
      .append($('<span>Adjusted in bills </span>').append($('<b></b>').text(money(x.adj))))
      .append($('<span>Advance not adjusted </span>').append($('<b></b>').text(money(x.adv - x.adj))))
      .append($('<span>Retention held </span>').append($('<b></b>').text(money(x.ret))))
      .append($('<span>TDS deducted </span>').append($('<b></b>').text(money(x.tds)))));
    return $b;
  }

  // ---------- work orders
  $('#nWo').text(WO.length);
  $('#btnWo').attr('href', 'CsrWorkOrderServlet?action=form&letterId=' + L.id);
  var s1 = [0, 0, 0];
  WO.forEach(function (w) {
    s1[0] += +w.subtotal; s1[1] += +w.gst_total; s1[2] += +w.total_amount;
    $('#bWo').append($('<tr class="csr-row"></tr>')
      .append(td(w.wo_number, 'csr-strong')).append(td(w.wo_date))
      .append($('<td></td>').append($('<div></div>').text(w.vendor_name)).append($('<div class="csr-small"></div>').text(w.vendor_phone || '')))
      .append(td(w.vendor_gstin || '-', 'csr-small'))
      .append(nTd(w.subtotal)).append(nTd(w.gst_total)).append(nTd(w.total_amount, true))
      .append(fileTd(w.attachment_size, 'CsrWorkOrderServlet?action=file&id=' + w.id))
      .append(actTd(btn('+ Bill', 'CsrInvoiceServlet?action=form&back=letter&woId=' + w.id), btn('+ Advance', 'CsrPaymentServlet?action=advanceForm&woId=' + w.id),
                    btn('&#9998; Edit', 'CsrWorkOrderServlet?action=form&id=' + w.id, true))));

    var woBills = INV.filter(function (v) { return String(v.wo_id) === String(w.id); })
      .sort(function (a, b) { return dmy(a.invoice_date) < dmy(b.invoice_date) ? -1 : 1; });
    var taxBills = woBills.filter(function (v) { return v.invoice_type !== 'Proforma'; });
    var taxBilled = taxBills.reduce(function (sum, v) { return sum + (+v.amount || 0); }, 0);
    var openProformas = woBills.filter(function (v) { return v.invoice_type === 'Proforma' && !v.settled_by; });
    var $details = $('<div class="lv-wo-bills"></div>');
    $('<div class="lv-wo-bills-summary"></div>').append(
      $('<span></span>').append('<strong>Work order:</strong> ').append(document.createTextNode(money(w.total_amount))),
      $('<span></span>').append('<strong>Tax bills raised (' + taxBills.length + '):</strong> ').append(document.createTextNode(money(taxBilled))),
      $('<span></span>').append('<strong>Remaining to bill:</strong> ').append(document.createTextNode(money(+w.total_amount - taxBilled))),
      $('<span></span>').append('<strong>Open proforma invoices (' + openProformas.length + '):</strong> ').append(document.createTextNode(money(w.pi_open)))
    ).appendTo($details);
    $details.append(ledgerBlock(w));
    $('#bWo').append($('<tr class="lv-wo-bills-row"></tr>').append($('<td colspan="9"></td>').append($details)));
  });
  if (WO.length) $('#bWo').append(totRow(['Total', '', '', '', s1[0], s1[1], s1[2], '', 'ACT']));
  else $('#bWo').append(none(9, 'No work orders yet.'));

  // ---------- bills (date order)
  $('#nInv').text(INV.length);
  var s2 = [0, 0, 0, 0];
  INV.slice().sort(function (a, b) { return dmy(a.invoice_date) < dmy(b.invoice_date) ? -1 : 1; }).forEach(function (v) {
    if (v.invoice_type !== 'Proforma') { s2[0] += +v.price; s2[1] += +v.gst_amount; s2[2] += +v.amount; }
    s2[3] += +(v.frl_number ? v.claim_amount : v.claimable);
    var pi = v.invoice_type === 'Proforma';
    $('#bInv').append($('<tr class="csr-row"></tr>')
      .append(td(v.invoice_date))
      .append($('<td></td>').append($('<span class="csr-badge"></span>').text(pi ? 'Proforma Invoice' : 'Tax Invoice').toggleClass('csr-badge-pi', pi)))
      .append($('<td></td>').append($('<div class="csr-strong"></div>').text(v.invoice_number))
        .append($('<div class="csr-small csr-ellipsis"></div>').text(PART[v.id] || '').attr('title', PART[v.id] || '')))
      .append(td(v.wo_number)).append(td(v.vendor_name))
      .append(nTd(v.price)).append(td(Number(v.gst_percent) + ' %', 'csr-num')).append(nTd(v.gst_amount)).append(nTd(v.amount, true))
      .append(td(pi ? (v.settled_by ? 'Settled by ' + v.settled_by : 'Open proforma invoice') : (v.proforma_number ? 'Against proforma invoice ' + v.proforma_number : '-'), 'csr-small'))
      .append(nTd(v.frl_number ? v.claim_amount : v.claimable))
      .append(v.frl_number ? td(v.frl_number)
        : (+v.claimable > 0 ? $('<td></td>').append($('<span class="csr-small" style="color:#b45309;font-weight:600;">Not claimed</span>'))
                            : td(!pi && noFrl(v) ? 'No FRL' : '-', 'csr-small')))
      .append(fileTd(v.attachment_size, 'CsrInvoiceServlet?action=file&id=' + v.id))
      .append(actTd(btn('&#9998; Edit', 'CsrInvoiceServlet?action=form&back=letter&id=' + v.id, true), payBtn(v))));
  });
  if (INV.length) $('#bInv').append(totRow(['Total bills (tax invoices)', '', '', '', '', s2[0], '', s2[1], s2[2], '', s2[3], '', '', 'ACT']));
  else $('#bInv').append(none(14, 'No bills yet.'));
  $('#tab-bills .csr-table-wrap').after($('<div class="lv-note"></div>').text(
    'Proforma invoices are shown separately from tax invoices. Claim = amount put in the FRL (tax invoice less amount already claimed against its proforma invoice).'));

  // ---------- vendor payments
  function payBtn(v) {
    if (v.invoice_type === 'Proforma' || payError) return '';
    var list = PVBY[v.id] || [], $b = $();
    if (list.length) $b = $b.add($('<a class="csr-btn csr-btn-sm csr-btn-outline csr-link-btn js-bill"></a>').attr('href', '#')
      .attr('data-id', v.id).attr('title', 'Show the payments of this bill').text('Payments (' + list.length + ')'));
    if (billDue(v) > 0) $b = $b.add(btn(list.length ? '+ Part Payment' : '+ Payment', 'CsrPaymentServlet?action=voucherForm&invoiceId=' + v.id));
    return $b;
  }
  function delBtn(kind, id) {
    return $('<button type="button" class="csr-btn csr-btn-sm csr-btn-bad js-pdel">Delete</button>').attr('data-kind', kind).attr('data-id', id);
  }
  $('#nPay').text(PV.length);
  // ---------- vendor-wise summary
  var pp = [0, 0, 0, 0, 0, 0, 0, 0, 0];
  WO.forEach(function (w) {
    var x = VP[w.id], net = r2(x.bills - x.dn - x.tds - x.ret), bal = r2(net - x.adv - x.paid), un = r2(x.adv - x.adj);
    [x.bills, x.dn, x.tds, x.ret, net, x.adv, x.paid, bal, un].forEach(function (n, i) { pp[i] += n; });
    $('#bPayPos').append($('<tr class="csr-row"></tr>').attr('data-wo', w.id).attr('title', 'Open the ledger of ' + w.vendor_name)
      .append(td(w.wo_number, 'csr-strong')).append(td(w.vendor_name))
      .append(nTd(x.bills)).append(nTd(x.dn)).append(nTd(x.tds)).append(nTd(x.ret)).append(nTd(net, true)).append(nTd(x.adv))
      .append(nTd(x.paid))
      .append($('<td class="csr-num"></td>').text(bal ? amt(Math.abs(bal)) + (bal > 0 ? ' Cr' : ' Dr') : '-')
        .css({ color: bal > 0 ? '#b45309' : (bal < 0 ? '#b91c1c' : ''), fontWeight: 600 }))
      .append(nTd(un)));
  });
  if (WO.length) {
    var $tr = totRow(['Total', ''].concat(pp));
    $tr.children().eq(9).text(pp[7] ? amt(Math.abs(pp[7])) + (pp[7] > 0 ? ' Cr' : ' Dr') : '-');
    $('#bPayPos').append($tr);
  } else $('#bPayPos').append(none(11, 'No work orders yet.'));
  $('#bPayPos').on('click', 'tr[data-wo]', function () {
    show('wo');
    var $l = $('#bWo .tl-led[data-wo="' + $(this).attr('data-wo') + '"]');
    if ($l.length) $('html, body').animate({ scrollTop: $l.offset().top - 70 }, 150);
  });

  // ---------- bills awaiting payment
  var pd = [0, 0, 0, 0, 0];
  UNPAID.slice().sort(function (a, b) { return dmy(a.invoice_date) < dmy(b.invoice_date) ? -1 : 1; }).forEach(function (v) {
    pd[0] += +v.price; pd[1] += +v.gst_amount; pd[2] += +v.amount; pd[3] += billPaid(v); pd[4] += billDue(v);
    $('#bPayDue').append($('<tr class="csr-row"></tr>')
      .append(td(v.invoice_date)).append(td(v.invoice_number, 'csr-strong')).append(td(v.wo_number)).append(td(v.vendor_name))
      .append(td(PART[v.id] || '-', 'csr-small csr-ellipsis').attr('title', PART[v.id] || ''))
      .append(nTd(v.price)).append(nTd(v.gst_amount)).append(nTd(v.amount)).append(nTd(billPaid(v)))
      .append($('<td class="csr-num csr-strong"></td>').text(amt(billDue(v))).css('color', '#b45309'))
      .append(actTd(payBtn(v))));
  });
  if (UNPAID.length) $('#bPayDue').append(totRow(['Total', '', '', '', '', pd[0], pd[1], pd[2], pd[3], pd[4], 'ACT']));
  else $('#bPayDue').append(none(11, payError ? '-' : 'No tax invoice is waiting for payment.'));

  // ---------- popup: voucher / advance / bill
  function byIdIn(list, id) { for (var i = 0; i < list.length; i++) if (String(list[i].id) === String(id)) return list[i]; return null; }
  function kv(k, v, wide) {
    return $('<div></div>').toggleClass('vm-wide', !!wide).append($('<div class="vm-k"></div>').text(k)).append($('<div class="vm-v"></div>').text(v || '-'));
  }
  function proof(size, href) {
    return size ? $('<div></div>').append($('<div class="vm-k">Payment Proof</div>'))
                    .append($('<div class="vm-v"></div>').append($('<a class="csr-pdf" target="_blank"></a>').attr('href', href).html('&#128206; View')))
                : kv('Payment Proof', 'Not attached');
  }
  function stmt(rows) {
    var $t = $('<table class="vm-stmt"></table>');
    rows.forEach(function (r) {
      var $l = $('<td></td>').text(r[0]); if (r[3]) $l.append($('<span class="vm-hint"></span>').text(r[3]));
      $t.append($('<tr></tr>').addClass(r[2] || '').append($l).append($('<td class="vm-amt"></td>').text(r[1] === null ? '' : amt(r[1]))));
    });
    return $t;
  }
  function openModal(type, title, $body, actions) {
    $('#vType').text(type); $('#vTitle').text(title);
    $('#vBody').empty().append($body);
    var $a = $('#vActions').empty(); actions.forEach(function (x) { $a.append(x); });
    $('#vModal').addClass('on'); $('body').addClass('lv-modal-open');
  }
  function closeModal() { $('#vModal').removeClass('on'); $('body').removeClass('lv-modal-open'); }
  var printBtn = function () { return $('<button type="button" class="csr-btn csr-btn-sm csr-btn-outline">&#128424; Print</button>').on('click', function () { window.print(); }); };

  function openVoucher(id) {
    var p = byIdIn(PV, id); if (!p) return;
    var w = WOBY[p.wo_id] || {}, before = settledBefore(p), dueB = r2(+p.bill_amount - before), sett = settledBy(p);
    var others = (PVBY[p.invoice_id] || []).filter(function (o) { return String(o.id) !== String(p.id); });
    var $b = $('<div></div>');
    $b.append($('<div class="vm-info"></div>')
      .append(kv('Party (Vendor)', p.vendor_name)).append(kv('GSTIN', w.vendor_gstin)).append(kv('Work Order', p.wo_number))
      .append(kv('Against Bill', p.invoice_number + '  dated ' + tdate(p.invoice_date))).append(kv('Payment Date', tdate(p.payment_date)))
      .append(kv('Management Approval', L.letterNumber)).append(kv('Particulars', PART[p.invoice_id], true)));
    $b.append(stmt([
      ['Taxable value', +p.price, 'vm-sub'], ['Add: GST @ ' + pct(p.gst_percent), +p.gst_amount, 'vm-sub'],
      ['Bill amount (A)', +p.bill_amount, 'vm-tot']]
      .concat(before ? [['Less: settled by earlier vouchers', -before, 'vm-sub'], ['Balance due before this voucher (B)', dueB, 'vm-tot']] : [])
      .concat([
      ['Debit note', +p.debit_note_amount, 'vm-sub', p.debit_note_remarks || ''],
      ['TDS' + (p.tds_section ? ' u/s ' + p.tds_section : ''), +p.tds_amount, 'vm-sub', p.tds_section ? '@ ' + pct(p.tds_percent) : ''],
      ['Retention', +p.retention_amount, 'vm-sub', +p.retention_percent ? '@ ' + pct(p.retention_percent) : ''],
      ['Advance adjusted', +p.advance_adjusted, 'vm-sub'],
      ['Amount paid to vendor', +p.net_paid, 'vm-net'],
      ['Settled by this voucher (' + (before ? 'C' : 'B') + ')', sett, 'vm-tot'],
      ['Balance due on the bill after this voucher', r2(dueB - sett), 'vm-sub', before ? 'B - C' : 'A - B']])));
    if (others.length) $b.append($('<div class="vm-words"></div>').text('Other payments of this bill: ' + others.map(function (o) {
      return o.voucher_no + ' (' + tdate(o.payment_date) + ', ' + amt(settledBy(o)) + ')'; }).join(', ')));
    $b.append($('<div class="vm-words"></div>').append('Amount (in words): ').append($('<b></b>').text(words(p.net_paid))));
    $b.append($('<div class="vm-info" style="margin:12px 0 0;"></div>')
      .append(kv('Payment Mode', p.payment_mode)).append(kv('UTR / Cheque No', p.reference_no)).append(kv('Bank', p.bank_name))
      .append(kv('Remarks', p.remarks, true))
      .append(proof(p.attachment_size, 'CsrPaymentServlet?action=file&kind=voucher&id=' + p.id)).append(kv('Entered by', p.created_by)));
    openModal('Payment Voucher', 'Vch No. ' + p.voucher_no + '   |   ' + tdate(p.payment_date), $b,
      [btn('&#9998; Edit', 'CsrPaymentServlet?action=voucherForm&id=' + p.id, true), printBtn(), delBtn('Voucher', p.id)]);
  }
  function openAdvance(id) {
    var a = byIdIn(ADV, id); if (!a) return;
    var w = WOBY[a.wo_id] || {}, x = VP[a.wo_id];
    var $b = $('<div></div>');
    $b.append($('<div class="vm-info"></div>')
      .append(kv('Party (Vendor)', a.vendor_name)).append(kv('GSTIN', w.vendor_gstin)).append(kv('Work Order', a.wo_number))
      .append(kv('Advance Date', tdate(a.advance_date))).append(kv('Management Approval', L.letterNumber)).append(kv('Work Order Value', money(w.total_amount))));
    $b.append(stmt([['Advance paid (this voucher)', +a.amount, 'vm-net'],
      ['Total advance paid on ' + a.wo_number, x.adv, 'vm-sub'], ['Adjusted in bills', -x.adj, 'vm-sub'],
      ['Advance not yet adjusted', r2(x.adv - x.adj), 'vm-tot']]));
    $b.append($('<div class="vm-words"></div>').append('Amount (in words): ').append($('<b></b>').text(words(a.amount))));
    $b.append($('<div class="vm-info" style="margin:12px 0 0;"></div>')
      .append(kv('Payment Mode', a.payment_mode)).append(kv('UTR / Cheque No', a.reference_no)).append(kv('Bank', a.bank_name))
      .append(kv('Remarks', a.remarks, true))
      .append(proof(a.attachment_size, 'CsrPaymentServlet?action=file&kind=advance&id=' + a.id)).append(kv('Entered by', a.created_by)));
    openModal('Advance Payment to Vendor', a.vendor_name + '   |   ' + tdate(a.advance_date), $b,
      [btn('&#9998; Edit', 'CsrPaymentServlet?action=advanceForm&id=' + a.id, true), printBtn(), delBtn('Advance', a.id)]);
  }
  function openBill(id) {
    var v = byIdIn(INV, id); if (!v) return;
    var w = WOBY[v.wo_id] || {}, list = PVBY[v.id] || [], paid = billPaid(v), due = billDue(v);
    var $b = $('<div></div>');
    $b.append($('<div class="vm-info"></div>')
      .append(kv('Party (Vendor)', v.vendor_name)).append(kv('GSTIN', w.vendor_gstin)).append(kv('Work Order', v.wo_number))
      .append(kv('Bill Date', tdate(v.invoice_date))).append(kv('Management Approval', L.letterNumber))
      .append(kv('Payment', !list.length ? 'Not paid yet' : (due > 0 ? 'Part paid, balance due ' + money(due) : 'Fully paid')))
      .append(kv('Particulars', PART[v.id], true)));
    $b.append(stmt([['Taxable value', +v.price, 'vm-sub'], ['Add: GST @ ' + pct(v.gst_percent), +v.gst_amount, 'vm-sub'], ['Bill amount (A)', +v.amount, 'vm-tot'],
      ['Settled by payment vouchers (B)', paid, 'vm-sub'], ['Balance due (A - B)', due, due > 0 ? 'vm-tot' : 'vm-net']]));
    if (list.length) {
      var $pt = $('<table class="vm-stmt" style="margin-top:10px;"></table>')
        .append('<tr class="vm-tot"><td>Payment voucher</td><td>Date</td><td class="vm-amt">Paid</td><td class="vm-amt">Deductions</td><td class="vm-amt">Settled</td></tr>');
      list.forEach(function (o) {
        $pt.append($('<tr class="tl-row" style="cursor:pointer;"></tr>').attr('data-pv', o.id).attr('title', 'Open this voucher')
          .append($('<td class="csr-strong"></td>').text(o.voucher_no)).append($('<td></td>').text(tdate(o.payment_date)))
          .append($('<td class="vm-amt"></td>').text(amt(o.net_paid))).append($('<td class="vm-amt"></td>').text(amt(settledBy(o) - +o.net_paid)))
          .append($('<td class="vm-amt"></td>').text(amt(settledBy(o)))));
      });
      $pt.on('click', 'tr[data-pv]', function () { openVoucher($(this).attr('data-pv')); });
      $b.append($pt);
    }
    $b.append($('<div class="vm-words"></div>').append('Amount (in words): ').append($('<b></b>').text(words(v.amount))));
    var acts = [btn('&#9998; Edit Bill', 'CsrInvoiceServlet?action=form&back=letter&id=' + v.id, true)];
    if (v.attachment_size) acts.push(btn('&#128206; Bill Copy', 'CsrInvoiceServlet?action=file&id=' + v.id, true).attr('target', '_blank'));
    if (due > 0 && !payError) acts.push(btn(list.length ? '+ Part Payment' : '+ Payment', 'CsrPaymentServlet?action=voucherForm&invoiceId=' + v.id));
    openModal('Purchase (Tax Invoice)', 'Bill No. ' + v.invoice_number + '   |   ' + tdate(v.invoice_date), $b, acts);
  }
  $('#bWo').on('click', 'tr.tl-row', function () {
    var k = $(this).attr('data-kind'), id = $(this).attr('data-id');
    if (k === 'voucher') openVoucher(id); else if (k === 'advance') openAdvance(id); else openBill(id);
  });
  $(document).on('click', 'a.js-pv', function (e) { e.preventDefault(); openVoucher($(this).attr('data-id')); });
  $(document).on('click', 'a.js-bill', function (e) { e.preventDefault(); openBill($(this).attr('data-id')); });
  $(document).on('click', '.js-vclose', closeModal);
  $('#vModal').on('click', function (e) { if (e.target === this) closeModal(); });
  $(document).on('keydown', function (e) { if (e.key === 'Escape' && $('#vModal').hasClass('on')) closeModal(); });

  // delete a voucher / advance (inline confirm, AJAX), then reload so every total is fresh
  $(document).on('click', '.js-pdel', function () {
    var $b = $(this), $box = $b.closest('.csr-actions');
    $box.data('html', $box.html()).empty()
      .append('<span class="lv-confirm">Delete?</span>')
      .append($('<button type="button" class="csr-btn csr-btn-sm csr-btn-bad js-pdel-yes">Yes</button>').attr('data-kind', $b.attr('data-kind')).attr('data-id', $b.attr('data-id')))
      .append('<button type="button" class="csr-btn csr-btn-sm csr-btn-outline js-pdel-no">No</button>');
  });
  $(document).on('click', '.js-pdel-no', function () { var $box = $(this).closest('.csr-actions'); $box.html($box.data('html')); });
  $(document).on('click', '.js-pdel-yes', function () {
    var $b = $(this), $box = $b.closest('.csr-actions');
    $b.prop('disabled', true).text('Deleting...');
    $.ajax({ url: 'CsrPaymentServlet', type: 'POST', dataType: 'json', data: { action: 'delete' + $b.attr('data-kind'), id: $b.attr('data-id') }
    }).done(function (res) {
      if (!res.ok) { showToast(false, res.message); $box.html($box.data('html')); return; }
      window.location.href = 'CsrLetterServlet?action=view&id=' + L.id + '&msg=' + encodeURIComponent(res.message) + '#pay';
    }).fail(function (xhr) {
      showToast(false, (xhr.responseJSON && xhr.responseJSON.message) ? xhr.responseJSON.message : 'Could not delete. Please try again.');
      $box.html($box.data('html'));
    });
  });
  function showToast(ok, text) {
    var $t = $('#csrToast');
    $t.removeClass('csr-alert-ok csr-alert-err').addClass(ok ? 'csr-alert-ok' : 'csr-alert-err').text(text).stop(true, true).fadeIn(150);
    clearTimeout($t.data('timer'));
    $t.data('timer', setTimeout(function () { $t.fadeOut(300); }, 6000));
  }

  // ---------- FRLs
  $('#nFrl').text(FRL.length);
  $('#btnFrl').attr('href', 'CsrFrlServlet?action=form&letterId=' + L.id);
  var s3 = [0, 0, 0];
  FRL.forEach(function (r) {
    var o = r2(+r.amount - +r.received);
    s3[0] += +r.amount; s3[1] += +r.received; s3[2] += o;
    var st = +r.received === 0 ? 'Pending' : (o > 0 ? 'Part received' : 'Received');
    var $act = $('<div class="csr-actions"></div>');
    if (o > 0) $act.append(btn('+ Receipt', 'CsrFundServlet?action=form&frlId=' + r.id));
    $act.append(btn('&#9998; Edit', 'CsrFrlServlet?action=form&id=' + r.id, true));
    $('#bFrl').append($('<tr class="csr-row"></tr>')
      .append(td(r.frl_date)).append(td(r.frl_number, 'csr-strong'))
      .append(td(r.invoice_numbers || '-', 'csr-small').css('max-width', '220px'))
      .append(nTd(r.amount, true)).append(nTd(r.received))
      .append($('<td class="csr-num"></td>').text(amt(o)).css({ color: o > 0 ? '#b45309' : '', fontWeight: 600 }))
      .append($('<td></td>').append($('<span class="csr-badge"></span>').text(st).toggleClass('csr-badge-pi', st !== 'Received')))
      .append(td(r.remarks || '', 'csr-small csr-ellipsis').attr('title', r.remarks || ''))
      .append(fileTd(r.attachment_size, 'CsrFrlServlet?action=file&id=' + r.id))
      .append($('<td class="lv-act"></td>').append($act)));
  });
  if (FRL.length) $('#bFrl').append(totRow(['Total', '', '', s3[0], s3[1], s3[2], '', '', '', 'ACT']));
  else $('#bFrl').append(none(10, 'No FRLs yet.'));

  // ---------- receipts
  $('#nRc').text(RC.length);
  var s4 = 0;
  RC.forEach(function (f) {
    s4 += +f.amount;
    $('#bRc').append($('<tr class="csr-row"></tr>')
      .append(td(f.receipt_date, 'csr-strong')).append(td(f.frl_number || '-'))
      .append(td(f.payment_mode)).append(td(f.reference_no || '-')).append(td(f.bank_name || '-'))
      .append(nTd(f.amount, true))
      .append(td(f.remarks || '', 'csr-small csr-ellipsis').attr('title', f.remarks || ''))
      .append(fileTd(f.attachment_size, 'CsrFundServlet?action=file&id=' + f.id))
      .append(actTd(btn('&#9998; Edit', 'CsrFundServlet?action=form&id=' + f.id, true))));
  });
  if (RC.length) $('#bRc').append(totRow(['Total', '', '', '', '', s4, '', '', 'ACT']));
  else $('#bRc').append(none(9, 'No receipts yet.'));

  // ---------- KSS ledger: FRL = debit, receipt = credit, in date order
  var led = [];
  FRL.forEach(function (r) {
    led.push({ k: dmy(r.frl_date) + '1' + ('000000' + r.id).slice(-6), date: r.frl_date, vch: 'FRL', ref: r.frl_number,
               part: 'Claim for bills ' + (r.invoice_numbers || '-'), dr: +r.amount, cr: 0 });
  });
  RC.forEach(function (f) {
    led.push({ k: dmy(f.receipt_date) + '2' + ('000000' + f.id).slice(-6), date: f.receipt_date, vch: 'Receipt', ref: f.reference_no || '-',
               part: (f.payment_mode || '') + (f.frl_number ? ' against ' + f.frl_number : ' (no FRL)') + (f.bank_name ? ', ' + f.bank_name : ''),
               dr: 0, cr: +f.amount });
  });
  led.sort(function (a, b) { return a.k < b.k ? -1 : 1; });
  function drcr(v) { return amt(Math.abs(v)) + (v > 0 ? ' Dr' : v < 0 ? ' Cr' : ''); }
  var bal = 0, tdr = 0, tcr = 0;
  led.forEach(function (e) {
    bal = r2(bal + e.dr - e.cr); tdr += e.dr; tcr += e.cr;
    $('#bLed').append($('<tr class="csr-row"></tr>')
      .append(td(e.date)).append(td(e.vch, e.cr ? 'lv-cr' : '')).append(td(e.ref, 'csr-strong')).append(td(e.part, 'csr-small'))
      .append(nTd(e.dr)).append($('<td class="csr-num lv-cr"></td>').text(amt(e.cr)))
      .append(td(drcr(bal), 'csr-num csr-strong')));
  });
  if (led.length) {
    $('#bLed').append($('<tr class="csr-total-row"></tr>').append(td('Closing balance')).append(td('')).append(td('')).append(td(''))
      .append(nTd(tdr)).append(nTd(tcr)).append(td(drcr(bal), 'csr-num')));
  } else {
    $('#bLed').append(none(7, 'No entries yet.'));
  }

  // ---------- print: one compact statement of this approval
  (function buildPrint() {
    var PU = <%= gson.toJson(session.getAttribute("username")) %>;
    var now = new Date(), today = ('0' + now.getDate()).slice(-2) + '-' + MON[now.getMonth()] + '-' + now.getFullYear();
    var $r = $('#printReport').empty();
    function T(cls) { return $('<table></table>').addClass(cls || ''); }
    function row(cells, cls) {      // [text, isNumber]
      var $tr = $('<tr></tr>').addClass(cls || '');
      cells.forEach(function (c) { $tr.append($('<td></td>').toggleClass('n', !!c[1]).text(c[1] ? amt(c[0]) : (c[0] == null ? '' : c[0]))); });
      return $tr;
    }
    function head(cols) {           // ['Label', isNumber]
      var $tr = $('<tr></tr>'); cols.forEach(function (c) { $tr.append($('<th></th>').toggleClass('n', !!c[1]).text(c[0])); });
      return $('<thead></thead>').append($tr);
    }
    function st(lines) {            // statement: [ref, label, value, cls]
      var $t = T('pr-st');
      lines.forEach(function (l) { $t.append(row([[l[0]], [l[1]], [l[2], true]], l[3])); });
      return $t;
    }

    $r.append($('<div class="pr-top"></div>')
      .append($('<div></div>').append('<div class="pr-org"><%= com.Bean.AppConfig.name() %> &middot; CSR Amount Spending</div>')
        .append($('<div class="pr-title"></div>').text('Statement: ' + L.letterNumber)))
      .append($('<div class="pr-meta"></div>').text('Printed ' + today + (PU ? ' by ' + PU : '') + '  |  Amounts in Rs')));
    $r.append($('<div class="pr-info"></div>')
      .append($('<span></span>').append('<b>Approval:</b> ').append(document.createTextNode(L.letterName || '-')))
      .append($('<span></span>').append('<b>Funded by:</b> ').append(document.createTextNode(CO)))
      .append($('<span></span>').append('<b>Activity:</b> ').append(document.createTextNode(L.activityKind || '-')))
      .append($('<span></span>').append('<b>Place:</b> ').append(document.createTextNode(L.place || '-')))
      .append($('<span></span>').append('<b>Sanctioned:</b> ').append(document.createTextNode(money(A)))));

    // 1. three statements
    $r.append('<h3>1. Summary</h3>');
    $r.append($('<div class="pr-three"></div>')
      .append($('<div></div>').append('<div class="pr-org">Budget</div>').append(st([
        ['A', 'Sanctioned', A, 'k'], ['B', 'Work orders issued', B], ['', 'Balance for new work (A - B)', A - B, 's'],
        ['C', 'Bills received (tax invoices)', C, 'k'], ['', 'Still to be billed (B - C)', B - C, 's']])))
      .append($('<div></div>').append($('<div class="pr-org"></div>').text('Funds from ' + CO)).append(st([
        ['T', 'To be claimed', C + PO - NF, 'k'], ['D', 'Claimed through FRLs', D], ['', 'Not yet claimed', U, 's'],
        ['E', 'Received', E + OTH, 'k'], ['', 'Outstanding (D - E)', D - E, 's']])))
      .append($('<div></div>').append('<div class="pr-org">Payments to Vendors</div>').append(st([
        ['C', 'Bills received', VT.bills, 'k'], ['', 'Less: debit note, TDS, retention', -(VT.dn + VT.tds + VT.ret), 's'],
        ['N', 'Net payable', VNET, 'k'], ['P', 'Paid (advance + bills)', VT.adv + VT.paid],
        ['', 'Balance payable (N - P)', VBAL, 's']]))));

    // 2. work order-wise
    $r.append('<h3>2. Work Order-wise Position</h3>');
    var $w = T().append(head([['WO No'], ['Vendor'], ['WO Value', 1], ['Billed', 1], ['To Bill', 1], ['Deductions', 1], ['Paid', 1], ['Payable', 1], ['Claimed (FRL)', 1]]));
    var tw = [0, 0, 0, 0, 0, 0, 0];
    WO.forEach(function (w) {
      var x = VP[w.id], ded = r2(x.dn + x.tds + x.ret), paid = r2(x.adv + x.paid), bal = r2(x.bills - ded - paid);
      var f = [+w.total_amount, +w.tax_billed, +w.total_amount - +w.tax_billed, ded, paid, bal, +w.claimed];
      f.forEach(function (v, i) { tw[i] += v; });
      $w.append(row([[w.wo_number], [w.vendor_name]].concat(f.map(function (v) { return [v, true]; }))));
    });
    if (WO.length) $w.append(row([['Total'], ['']].concat(tw.map(function (v) { return [v, true]; })), 't'));
    else $w.append(row([['No work orders']]));
    $r.append($w);

    // 3. bills
    $r.append('<h3>3. Bills</h3>');
    var $b = T().append(head([['Date'], ['Bill No'], ['WO'], ['Type'], ['Amount', 1], ['Settled', 1], ['Due', 1], ['FRL']]));
    var tb = [0, 0, 0];
    INV.slice().sort(function (a, b) { return dmy(a.invoice_date) < dmy(b.invoice_date) ? -1 : 1; }).forEach(function (v) {
      var pi = v.invoice_type === 'Proforma', paid = pi ? 0 : billPaid(v), due = pi ? 0 : billDue(v);
      if (!pi) { tb[0] += +v.amount; tb[1] += paid; tb[2] += due; }
      $b.append(row([[tdate(v.invoice_date)], [v.invoice_number], [v.wo_number],
        [pi ? 'Proforma' + (v.settled_by ? ' (settled)' : '') : 'Tax Invoice'], [+v.amount, true], [paid, true], [due, true], [v.frl_number || '-']]));
    });
    if (INV.length) $b.append(row([['Total (tax invoices)'], [''], [''], [''], [tb[0], true], [tb[1], true], [tb[2], true], ['']], 't'));
    else $b.append(row([['No bills']]));
    $r.append($b);

    // 4. FRLs and receipts
    $r.append($('<h3></h3>').text('4. Fund Requests to ' + CO + ' and Receipts'));
    var $f = T().append(head([['Date'], ['FRL No'], ['Bills'], ['Claimed', 1], ['Received', 1], ['Outstanding', 1]]));
    var tf = [0, 0, 0];
    FRL.forEach(function (r) {
      var o = r2(+r.amount - +r.received); tf[0] += +r.amount; tf[1] += +r.received; tf[2] += o;
      $f.append(row([[tdate(r.frl_date)], [r.frl_number], [r.invoice_numbers || '-'], [+r.amount, true], [+r.received, true], [o, true]]));
    });
    if (FRL.length) $f.append(row([['Total'], [''], [''], [tf[0], true], [tf[1], true], [tf[2], true]], 't'));
    else $f.append(row([['No FRLs']]));
    if (OTH) $f.append(row([[''], ['Received without FRL'], [''], [0, true], [OTH, true], [0, true]], 's'));
    $r.append($f);

    // 5. pending points (same as the Summary tab)
    var $p = $('<ul class="pr-pend"></ul>');
    $('#stPoints .lv-pt').each(function () {
      var $s = $(this).children('span');
      $p.append($('<li></li>').text($s.eq(1).text() + ($(this).find('.lv-pt-amt').length ? ': ' + $(this).find('.lv-pt-amt').text() : '')));
    });
    $r.append('<h3>5. Pending</h3>').append($p);

    $r.append('<div class="pr-note">Paid = advances + payments to the vendor. Deductions = debit notes + TDS + retention. Payable = Billed - Deductions - Paid (negative = paid in advance). Settled = payment + deductions of the bill.</div>');
    $r.append('<div class="pr-sign"><div>Prepared by</div><div>Checked by</div><div>Approved by</div></div>');
  })();

  // ---------- tabs (the open tab is kept in the address, so Back returns to it)
  function show(tab) {
    if (!$('#tab-' + tab).length) tab = 'summary';
    $('.lv-tab').removeClass('on').filter('[data-tab="' + tab + '"]').addClass('on');
    $('.lv-pane').removeClass('on'); $('#tab-' + tab).addClass('on');
    if (window.history.replaceState) window.history.replaceState(null, '', '#' + tab);
  }
  $('#lvTabs').on('click', '.lv-tab', function () { show($(this).attr('data-tab')); });
  $(document).on('click', 'a.js-tab', function (e) { e.preventDefault(); show($(this).attr('href').substring(1)); $('html, body').scrollTop(0); });
  var params = new URLSearchParams(window.location.search);
  if (params.get('msg')) {
    showToast(true, params.get('msg'));
    if (window.history.replaceState) window.history.replaceState(null, '', 'CsrLetterServlet?action=view&id=' + L.id + location.hash);
  }
  show((location.hash || '#summary').substring(1));
});
</script>

</body>
</html>
