<%
    // Must be opened through CsrLetterServlet?action=view&id=N (loads data + checks Global role)
    if (request.getAttribute("letter") == null) {
        response.sendRedirect("CsrLetterServlet");
        return;
    }
    com.google.gson.Gson gson = new com.google.gson.Gson();   // escapes < > & : safe inside <script>
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
  .lv-info { display: grid; grid-template-columns: 1.2fr 1fr 1fr 1fr 2fr; gap: 6px 18px; padding: 9px 12px; }
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

  @media (max-width: 1000px) {
    .lv-info { grid-template-columns: 1fr 1fr; }
    .lv-two { grid-template-columns: 1fr; }
  }

  /* ---- print: the whole file, without menus or buttons ---- */
  @media print {
    .kss-navbar-scope, .kss-footer-scope, .lv-tabs, .lv-noprint, .lv-act, .lv-pt .csr-btn { display: none !important; }
    body { background: #fff !important; padding: 0 !important; }
    .csr-page { padding: 0 !important; }
    .lv-pane { display: block !important; padding-top: 6px; }
    .lv-pane::before { content: attr(data-title); display: block; font-weight: 700; font-size: 14px; margin: 12px 0 6px; }
    .csr-card { box-shadow: none !important; }
    a { color: inherit !important; text-decoration: none !important; border: none !important; }
  }
</style>
</head>
<body>

<div class="csr-page">

  <div class="csr-header">
    <div>
      <div class="csr-subtitle"><a href="CsrLetterServlet" style="color:inherit;">KSS CSR Amount Spending &rsaquo; Approval Letters</a></div>
      <h1 class="csr-title" id="lvTitle"></h1>
      <div id="lvName" style="font-size:13px; color:#334155;"></div>
    </div>
    <div class="csr-actions lv-noprint" id="lvActions">
      <button type="button" class="csr-btn csr-btn-sm csr-btn-outline" onclick="window.print()">&#128424; Print</button>
      <a href="CsrLetterServlet" class="csr-btn csr-btn-sm csr-btn-outline csr-link-btn">&#8592; Approval Letters</a>
    </div>
  </div>

  <div id="csrError" class="csr-alert csr-alert-err" style="display:none;"></div>

  <div class="csr-card"><div class="lv-info" id="lvInfo"></div></div>

  <div class="lv-tabs" id="lvTabs">
    <button type="button" class="lv-tab" data-tab="summary">Summary</button>
    <button type="button" class="lv-tab" data-tab="wo">Work Orders <span class="lv-n" id="nWo">0</span></button>
    <button type="button" class="lv-tab" data-tab="bills">Bills <span class="lv-n" id="nInv">0</span></button>
    <button type="button" class="lv-tab" data-tab="frl">Fund Requests (FRL) <span class="lv-n" id="nFrl">0</span></button>
    <button type="button" class="lv-tab" data-tab="rcpt">Receipts <span class="lv-n" id="nRc">0</span></button>
    <button type="button" class="lv-tab" data-tab="ledger">KSS Ledger</button>
  </div>

  <!-- ================= SUMMARY ================= -->
  <div class="lv-pane" id="tab-summary" data-title="Summary">
    <div class="lv-two">
      <div class="csr-card">
        <div class="csr-card-head"><div class="csr-card-title">Budget &amp; Spending <span class="csr-small">(&#8377;)</span></div></div>
        <table class="lv-stmt" id="stBudget"></table>
      </div>
      <div class="csr-card">
        <div class="csr-card-head"><div class="csr-card-title">Funds from KSS <span class="csr-small">(&#8377;)</span></div></div>
        <table class="lv-stmt" id="stFunds"></table>
      </div>
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
            <th>WO No</th><th>Vendor</th><th class="csr-num">WO Value</th><th class="csr-num">Billed</th>
            <th class="csr-num">To be Billed</th><th class="csr-num">Claimed (FRL)</th><th class="csr-num">Bills not Claimed</th>
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
            <th class="csr-num">GST %</th><th class="csr-num">GST</th><th class="csr-num">Bill Amount</th><th>Claimed in FRL</th><th>Copy</th><th class="lv-act">Action</th>
          </tr></thead>
          <tbody id="bInv"></tbody>
        </table>
      </div>
    </div>
  </div>

  <!-- ================= FRLs ================= -->
  <div class="lv-pane" id="tab-frl" data-title="Fund Requests (FRL)">
    <div class="csr-card">
      <div class="csr-card-head">
        <div class="csr-card-title">Fund Requests sent to KSS <span class="csr-small">(&#8377;)</span></div>
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
      <div class="csr-card-head"><div class="csr-card-title">Funds Received from KSS <span class="csr-small">(&#8377;)</span></div></div>
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
  <div class="lv-pane" id="tab-ledger" data-title="KSS Ledger">
    <div class="csr-card">
      <div class="csr-card-head"><div class="csr-card-title">KSS Receivable Ledger <span class="csr-small">(&#8377;)</span></div></div>
      <div class="csr-table-wrap">
        <table class="csr-table">
          <thead><tr>
            <th>Date</th><th>Voucher</th><th>Ref No</th><th>Particulars</th>
            <th class="csr-num">Debit (Claimed)</th><th class="csr-num">Credit (Received)</th><th class="csr-num">Balance</th>
          </tr></thead>
          <tbody id="bLed"></tbody>
        </table>
      </div>
      <div class="lv-note">Debit: amount claimed from KSS through an FRL. Credit: amount received. Balance Dr: still to be received.</div>
    </div>
  </div>
</div>

<script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
<script>
$(function () {
  var L   = <%= gson.toJson(request.getAttribute("letter")) %>;
  var WO  = <%= gson.toJson(request.getAttribute("workOrders")) %> || [];
  var INV = <%= gson.toJson(request.getAttribute("invoices")) %> || [];
  var FRL = <%= gson.toJson(request.getAttribute("frls")) %> || [];
  var RC  = <%= gson.toJson(request.getAttribute("receipts")) %> || [];
  var loadError = <%= gson.toJson(request.getAttribute("error")) %>;
  var RS = String.fromCharCode(8377);

  if (loadError) $('#csrError').text(loadError).show();

  // ---------- helpers
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
  var TI = 0, PI = 0, CL = 0;                              // tax invoices, proforma, bills claimed in FRLs
  INV.forEach(function (v) {
    if (v.invoice_type === 'Proforma') PI += +v.amount; else TI += +v.amount;
    if (v.frl_number) CL += +v.amount;
  });
  TI = r2(TI); PI = r2(PI); var C = r2(TI + PI); CL = r2(CL);
  var D = 0; FRL.forEach(function (r) { D += +r.amount; }); D = r2(D);       // claimed through FRLs
  var E = 0, OTH = 0;                                                        // received against FRL / without FRL
  RC.forEach(function (f) { if (f.frl_id) E += +f.amount; else OTH += +f.amount; });
  E = r2(E); OTH = r2(OTH);

  // ---------- header + strip
  document.title = L.letterNumber + ' - Approval Letter';
  $('#lvTitle').text(L.letterNumber);
  $('#lvName').text(L.letterName);
  $('#lvActions').prepend(btn('&#9998; Edit Letter', 'CsrLetterServlet?action=form&id=' + L.id, true));
  if (L.pdfSize) $('#lvActions').prepend(btn('&#128196; Letter PDF', 'CsrLetterServlet?action=pdf&id=' + L.id, true).attr('target', '_blank'));
  function info(k, v) { $('#lvInfo').append($('<div></div>').append($('<div class="lv-k"></div>').text(k)).append($('<div class="lv-v"></div>').text(v || '-'))); }
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
  line($b, '', 'Tax invoices received', TI, 'lv-sub');
  line($b, '', 'Proforma invoices received', PI, 'lv-sub');
  line($b, 'C', 'Total bills received', C, 'lv-tot');
  line($b, '', 'Work order value not yet billed', B - C, B - C < 0 ? 'lv-bad' : '', 'B - C');

  var $f = $('#stFunds');
  line($f, 'C', 'Total bills received', C);
  line($f, 'D', 'Claimed from KSS through FRLs', D, '', FRL.length + ' FRL' + (FRL.length === 1 ? '' : 's'));
  line($f, '', 'Bills not yet claimed', C - CL, C - CL > 0 ? 'lv-due' : '', 'bills not in any FRL');
  line($f, 'E', 'Received from KSS against FRLs', E, 'lv-tot');
  line($f, '', 'Outstanding from KSS', D - E, D - E > 0 ? 'lv-due' : (D - E < 0 ? 'lv-bad' : 'lv-ok'), 'D - E');
  if (OTH) {
    line($f, '', 'Received without FRL (old entries)', OTH, 'lv-sub');
    line($f, '', 'Total received', E + OTH, 'lv-tot');
  }

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
  if (B - C > 0)  point('Work order value not yet billed by vendors', B - C);
  if (C - CL > 0) point('Bills received but not yet claimed from KSS', C - CL, btn('+ Raise FRL', 'CsrFrlServlet?action=form&letterId=' + L.id));
  if (D - E > 0)  point('Claimed from KSS, not yet received', D - E);
  if (!pts) $p.append($('<div class="lv-pt ok"></div>').append('<span class="lv-dot"></span>')
                 .append($('<span></span>').text('Nothing pending. All bills claimed and all claims received.')));

  // ---------- summary: WO-wise position
  var pos = { v: 0, b: 0, tb: 0, c: 0, nc: 0 };
  WO.forEach(function (w) {
    var billed = 0, claimed = 0;
    INV.forEach(function (v) { if (String(v.wo_id) === String(w.id)) { billed += +v.amount; if (v.frl_number) claimed += +v.amount; } });
    var tb = +w.total_amount - billed, nc = billed - claimed;
    pos.v += +w.total_amount; pos.b += billed; pos.tb += tb; pos.c += claimed; pos.nc += nc;
    $('#bWoPos').append($('<tr class="csr-row"></tr>').append(td(w.wo_number, 'csr-strong')).append(td(w.vendor_name))
      .append(nTd(w.total_amount, true)).append(nTd(billed)).append(nTd(tb)).append(nTd(claimed))
      .append($('<td class="csr-num"></td>').text(amt(nc)).css({ color: nc > 0 ? '#b45309' : '', fontWeight: nc > 0 ? 600 : '' })));
  });
  if (WO.length) $('#bWoPos').append(totRow(['Total', '', pos.v, pos.b, pos.tb, pos.c, pos.nc]));
  else $('#bWoPos').append(none(7, 'No work orders yet.'));

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
      .append(actTd(btn('+ Bill', 'CsrInvoiceServlet?action=form&woId=' + w.id), btn('&#9998; Edit', 'CsrWorkOrderServlet?action=form&id=' + w.id, true))));
  });
  if (WO.length) $('#bWo').append(totRow(['Total', '', '', '', s1[0], s1[1], s1[2], '', 'ACT']));
  else $('#bWo').append(none(9, 'No work orders yet.'));

  // ---------- bills (date order)
  $('#nInv').text(INV.length);
  var s2 = [0, 0, 0];
  INV.slice().sort(function (a, b) { return dmy(a.invoice_date) < dmy(b.invoice_date) ? -1 : 1; }).forEach(function (v) {
    s2[0] += +v.price; s2[1] += +v.gst_amount; s2[2] += +v.amount;
    var pi = v.invoice_type === 'Proforma';
    $('#bInv').append($('<tr class="csr-row"></tr>')
      .append(td(v.invoice_date))
      .append($('<td></td>').append($('<span class="csr-badge"></span>').text(pi ? 'Proforma' : 'Tax Invoice').toggleClass('csr-badge-pi', pi)))
      .append(td(v.invoice_number, 'csr-strong')).append(td(v.wo_number)).append(td(v.vendor_name))
      .append(nTd(v.price)).append(td(Number(v.gst_percent) + ' %', 'csr-num')).append(nTd(v.gst_amount)).append(nTd(v.amount, true))
      .append(v.frl_number ? td(v.frl_number)
        : $('<td></td>').append($('<span class="csr-small" style="color:#b45309;font-weight:600;">Not claimed</span>')))
      .append(fileTd(v.attachment_size, 'CsrInvoiceServlet?action=file&id=' + v.id))
      .append(actTd(btn('&#9998; Edit', 'CsrInvoiceServlet?action=form&id=' + v.id, true))));
  });
  if (INV.length) $('#bInv').append(totRow(['Total', '', '', '', '', s2[0], '', s2[1], s2[2], '', '', 'ACT']));
  else $('#bInv').append(none(12, 'No bills yet.'));

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

  // ---------- tabs (the open tab is kept in the address, so Back returns to it)
  function show(tab) {
    if (!$('#tab-' + tab).length) tab = 'summary';
    $('.lv-tab').removeClass('on').filter('[data-tab="' + tab + '"]').addClass('on');
    $('.lv-pane').removeClass('on'); $('#tab-' + tab).addClass('on');
    if (window.history.replaceState) window.history.replaceState(null, '', '#' + tab);
  }
  $('#lvTabs').on('click', '.lv-tab', function () { show($(this).attr('data-tab')); });
  show((location.hash || '#summary').substring(1));
});
</script>

</body>
</html>
