<%@page import="java.util.Map"%>
<%
    // Must be opened through CsrPaymentServlet?action=voucherForm (loads data + checks Global role)
    if (request.getAttribute("bill") == null) {
        response.sendRedirect("CsrLetterServlet");
        return;
    }
    @SuppressWarnings("unchecked")
    Map<String, String> voucher = (Map<String, String>) request.getAttribute("voucher");   // null = new
    boolean isEdit = voucher != null;
    com.google.gson.Gson gson = new com.google.gson.Gson();   // escapes < > & : safe inside <script>
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><%= isEdit ? "Edit Payment Voucher" : "New Payment Voucher" %></title>

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
  .pv-grid { display: grid; grid-template-columns: 1.15fr 1fr; gap: 10px; align-items: start; }
  .pv-grid .csr-card + .csr-card { margin-top: 10px; }
  .pv-info { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 8px 16px; padding: 10px 12px; }
  .pv-info .pv-wide { grid-column: 1 / -1; }
  .pv-k { font-size: 10.5px; font-weight: 600; letter-spacing: .5px; text-transform: uppercase; color: #64748b; }
  .pv-v { font-size: 13px; color: #0f172a; margin-top: 2px; white-space: pre-wrap; }
  table.pv-stmt { width: 100%; border-collapse: collapse; font-size: 13px; }
  .pv-stmt td { padding: 6px 12px; border-bottom: 1px solid #eef2f6; }
  .pv-stmt td.pv-ref { width: 30px; color: #94a3b8; font-size: 11px; font-weight: 600; text-align: center; }
  .pv-stmt td.pv-amt { text-align: right; white-space: nowrap; width: 150px; font-weight: 500; }
  .pv-stmt tr.pv-sub td { color: #475569; }
  .pv-stmt tr.pv-sub td:nth-child(2) { padding-left: 24px; }
  .pv-stmt tr.pv-tot td { font-weight: 700; border-top: 1px solid #cbd5e1; background: #f8fafc; }
  .pv-stmt tr.pv-net td { font-weight: 700; font-size: 14px; color: #047857; background: #f0fdf4; border-top: 2px solid #cbd5e1; }
  .pv-stmt tr.pv-bad td { font-weight: 700; color: #b91c1c; background: #fef2f2; }
  .pv-stmt .pv-hint { font-weight: 400; color: #94a3b8; font-size: 11px; margin-left: 6px; }
  .pv-sec { grid-column: 1 / -1; font-size: 10.5px; font-weight: 700; letter-spacing: .5px; text-transform: uppercase; color: #0f766e;
            border-bottom: 1px solid #e2e8f0; padding-bottom: 4px; margin-top: 4px; }
  @media (max-width: 1000px) { .pv-grid { grid-template-columns: 1fr; } .pv-info { grid-template-columns: 1fr 1fr; } }
</style>
</head>
<body>

<div class="csr-page">

  <div class="csr-header">
    <div>
      <div class="csr-subtitle"><a id="crumb" style="color:inherit;"><%= com.Bean.AppConfig.code() %> CSR Amount Spending &rsaquo; Management Approvals</a></div>
      <h1 class="csr-title" id="pageTitle"></h1>
    </div>
    <a class="csr-btn csr-btn-outline csr-link-btn" id="btnBack">&#8592; Back to Management Approval</a>
  </div>

  <div id="csrError" class="csr-alert csr-alert-err" style="display:none;"></div>
  <div id="csrToast" class="csr-alert" style="display:none;"></div>

  <form id="pvForm" enctype="multipart/form-data" autocomplete="off">
    <input type="hidden" name="action" value="saveVoucher">
    <input type="hidden" name="id" id="fId" value="">
    <input type="hidden" name="invoiceId" id="fInvoice" value="">

    <div class="pv-grid">
      <div>
        <div class="csr-card">
          <div class="csr-card-head"><div class="csr-card-title">Bill (Tax Invoice)</div><span id="billCopy"></span></div>
          <div class="pv-info" id="billInfo"></div>
          <div id="earlierWrap" style="display:none; padding:0 12px 10px;">
            <div class="pv-k" style="margin-bottom:4px;">Earlier payments of this bill</div>
            <table class="pv-stmt" id="earlier" style="border:1px solid #e2e8f0;"></table>
          </div>
        </div>

        <div class="csr-card">
          <div class="csr-card-head"><div class="csr-card-title">Deductions</div></div>
          <div class="csr-form">
            <div class="pv-sec">Debit Note</div>
            <div class="csr-field">
              <label for="fDn">Debit Note Amount (&#8377;)</label>
              <input type="number" id="fDn" name="debitNoteAmount" class="csr-input csr-amount" min="0" step="0.01">
            </div>
            <div class="csr-field span-2">
              <label for="fDnRemarks">Reason for Debit Note</label>
              <input type="text" id="fDnRemarks" name="debitNoteRemarks" class="csr-input" maxlength="500">
            </div>

            <div class="pv-sec">TDS</div>
            <div class="csr-field">
              <label for="fTdsSec">TDS Section</label>
              <select id="fTdsSec" name="tdsSection" class="csr-input"></select>
            </div>
            <div class="csr-field">
              <label for="fTdsPct">TDS %</label>
              <input type="number" id="fTdsPct" name="tdsPercent" class="csr-input csr-amount" min="0" max="100" step="0.01">
            </div>
            <div class="csr-field">
              <label for="fTds">TDS Amount (&#8377;)</label>
              <input type="number" id="fTds" name="tdsAmount" class="csr-input csr-amount" min="0" step="0.01">
              <div class="csr-hint" id="tdsHint"></div>
            </div>

            <div class="pv-sec">Retention</div>
            <div class="csr-field">
              <label for="fRetPct">Retention %</label>
              <input type="number" id="fRetPct" name="retentionPercent" class="csr-input csr-amount" min="0" max="100" step="0.01">
            </div>
            <div class="csr-field">
              <label for="fRet">Retention Amount (&#8377;)</label>
              <input type="number" id="fRet" name="retentionAmount" class="csr-input csr-amount" min="0" step="0.01">
              <div class="csr-hint" id="retHint"></div>
            </div>
            <div class="csr-field"></div>

            <div class="pv-sec">Advance Paid to Vendor</div>
            <div class="csr-field">
              <label for="fAdv">Advance Adjusted (&#8377;)</label>
              <input type="number" id="fAdv" name="advanceAdjusted" class="csr-input csr-amount" min="0" step="0.01">
            </div>
            <div class="csr-field span-2">
              <label>Advance on this Work Order</label>
              <div class="csr-budget" id="advBox"></div>
            </div>
          </div>
        </div>
      </div>

      <div>
        <div class="csr-card">
          <div class="csr-card-head"><div class="csr-card-title">Payment Statement <span class="csr-small">(&#8377;)</span></div></div>
          <table class="pv-stmt" id="stmt"></table>
        </div>

        <div class="csr-card">
          <div class="csr-card-head"><div class="csr-card-title">Payment</div></div>
          <div class="csr-form">
            <div class="csr-field span-2">
              <label for="fNet">Amount Paid Now (&#8377;) <span class="req">*</span></label>
              <input type="number" id="fNet" name="netPaid" class="csr-input csr-amount" min="0" step="0.01">
              <div class="csr-hint" id="netHint"></div>
            </div>
            <div class="csr-field" style="justify-content:flex-end;">
              <label>&nbsp;</label>
              <button type="button" class="csr-btn csr-btn-outline" id="btnFull">Pay Full Balance</button>
            </div>
            <div class="csr-field">
              <label for="fVno">Voucher No <span class="req">*</span></label>
              <input type="text" id="fVno" name="voucherNo" class="csr-input" maxlength="100">
            </div>
            <div class="csr-field">
              <label for="fDate">Payment Date <span class="req">*</span></label>
              <input type="date" id="fDate" name="paymentDate" class="csr-input">
            </div>
            <div class="csr-field">
              <label for="fMode">Payment Mode <span class="req">*</span></label>
              <select id="fMode" name="paymentMode" class="csr-input"></select>
            </div>
            <div class="csr-field">
              <label for="fRef">UTR / Cheque No</label>
              <input type="text" id="fRef" name="referenceNo" class="csr-input" maxlength="100">
            </div>
            <div class="csr-field span-2">
              <label for="fBank">Bank Name</label>
              <input type="text" id="fBank" name="bankName" class="csr-input" maxlength="150">
            </div>
            <div class="csr-field span-3">
              <label for="fRemarks">Remarks</label>
              <textarea id="fRemarks" name="remarks" class="csr-textarea" maxlength="500"></textarea>
            </div>
            <div class="csr-field span-3">
              <label for="fFile">Payment Proof (PDF / JPG / PNG)</label>
              <input type="file" id="fFile" name="attachment" class="csr-file" accept="application/pdf,.pdf,image/jpeg,.jpg,.jpeg,image/png,.png">
              <div class="csr-hint">Bank advice or cheque copy. Optional, maximum 10 MB.<span id="fileKeepHint" style="display:none;"> Leave empty to keep the current file.</span></div>
              <div class="csr-hint csr-current-pdf" id="currentFile"></div>
            </div>
            <div class="csr-over" id="overWarn" style="display:none; margin:0; grid-column:1 / -1;"></div>
            <div class="csr-form-actions">
              <span id="delBox" style="display:none; margin-right:auto;"><button type="button" class="csr-btn csr-btn-bad" id="btnDel">Delete Voucher</button></span>
              <a class="csr-btn csr-btn-outline csr-link-btn" id="btnCancel">Cancel</a>
              <button type="submit" class="csr-btn" id="btnSave"></button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </form>
</div>

<script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
<script>
$(function () {
  var V         = <%= gson.toJson(voucher) %>;                       // null when adding
  var BILL      = <%= gson.toJson(request.getAttribute("bill")) %>;
  var OTHERS    = <%= gson.toJson(request.getAttribute("others")) %> || [];   // other vouchers of this bill
  var modes     = <%= gson.toJson(request.getAttribute("modes")) %> || [];
  var sections  = <%= gson.toJson(request.getAttribute("tdsSections")) %> || [];
  var loadError = <%= gson.toJson(request.getAttribute("error")) %>;
  var RS = String.fromCharCode(8377);

  if (loadError) $('#csrError').text(loadError).show();
  if (!BILL || !BILL.id) { $('#pvForm').hide(); return; }

  function r2(v) { return Math.round((Number(v) || 0) * 100) / 100; }
  function amt(v) {                       // accounts style: 1,23,456.00 ; zero "-" ; negative in brackets
    v = r2(v);
    if (v === 0) return '-';
    var s = Math.abs(v).toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    return v < 0 ? '(' + s + ')' : s;
  }
  function money(v) { return RS + ' ' + (r2(v) === 0 ? '0.00' : amt(v)); }
  function kb(bytes) {
    var n = parseInt(bytes, 10) || 0;
    return n >= 1048576 ? (n / 1048576).toFixed(1) + ' MB' : Math.max(1, Math.round(n / 1024)) + ' KB';
  }
  function showToast(ok, text) {
    var $t = $('#csrToast');
    $t.removeClass('csr-alert-ok csr-alert-err').addClass(ok ? 'csr-alert-ok' : 'csr-alert-err').text(text).stop(true, true).fadeIn(150);
    clearTimeout($t.data('timer'));
    $t.data('timer', setTimeout(function () { $t.fadeOut(300); }, 6000));
    $('html, body').animate({ scrollTop: 0 }, 150);
  }

  var letterUrl = 'CsrLetterServlet?action=view&id=' + BILL.letter_id;
  $('#crumb').attr('href', letterUrl + '#pay').html('<%= com.Bean.AppConfig.code() %> CSR Amount Spending &rsaquo; Management Approvals &rsaquo; ')
    .append(document.createTextNode(BILL.letter_number));
  $('#btnBack, #btnCancel').attr('href', letterUrl + '#pay');

  // ---------- bill (read only, from the tax invoice)
  var price = r2(BILL.price), bill = r2(BILL.amount);
  function info(k, v, wide) {
    $('#billInfo').append($('<div></div>').toggleClass('pv-wide', !!wide)
      .append($('<div class="pv-k"></div>').text(k)).append($('<div class="pv-v"></div>').text(v || '-')));
  }
  info('Vendor', BILL.vendor_name);
  info('GSTIN', BILL.vendor_gstin);
  info('Work Order', BILL.wo_number);
  info('Bill No', BILL.invoice_number);
  info('Bill Date', BILL.invoice_date);
  info('Management Approval', BILL.letter_number);
  info('Particulars', BILL.particulars || BILL.wo_particulars, true);
  if (BILL.attachment_size)
    $('#billCopy').append($('<a class="csr-pdf" target="_blank"></a>').attr('href', 'CsrInvoiceServlet?action=file&id=' + BILL.id).html('&#128206; Bill copy'));
  var settledOthers = r2(BILL.settled_others), tdsOthers = r2(BILL.tds_others), retOthers = r2(BILL.ret_others);
  var dueBefore = r2(bill - settledOthers);                       // balance due on the bill before this voucher
  $('#tdsHint').text('Calculated on the taxable value ' + money(price) + ', rounded to the rupee'
    + (tdsOthers ? ', less ' + money(tdsOthers) + ' already deducted in earlier vouchers.' : '.'));
  $('#retHint').text('Calculated on the bill amount' + (retOthers ? ', less ' + money(retOthers) + ' already held in earlier vouchers.' : '.'));
  if (OTHERS.length) {
    $('#earlier').append('<tr><td class="pv-k" style="padding:4px 8px;">Voucher No</td><td class="pv-k">Date</td><td class="pv-k pv-amt">Paid</td><td class="pv-k pv-amt">Settled</td></tr>');
    OTHERS.forEach(function (o) {
      $('#earlier').append($('<tr></tr>').append($('<td></td>').text(o.voucher_no)).append($('<td></td>').text(o.payment_date))
        .append($('<td class="pv-amt"></td>').text(amt(o.net_paid))).append($('<td class="pv-amt"></td>').text(amt(o.settled))));
    });
    $('#earlier').append($('<tr class="pv-tot"></tr>').append('<td>Total</td><td></td>').append($('<td class="pv-amt"></td>').text(amt(
      OTHERS.reduce(function (s, o) { return s + (+o.net_paid); }, 0)))).append($('<td class="pv-amt"></td>').text(amt(settledOthers))));
    $('#earlierWrap').show();
  }

  // ---------- advance on the work order
  var advPaid = r2(BILL.adv_paid), advOthers = r2(BILL.adv_adjusted_others), advAvail = r2(advPaid - advOthers);
  $('#advBox').append($('<span>Paid </span>').append($('<b></b>').text(money(advPaid))))
    .append($('<span>Adjusted in other bills </span>').append($('<b></b>').text(money(advOthers))))
    .append($('<span>Available </span>').append($('<b></b>').text(money(advAvail))));
  if (advAvail <= 0 && !(V && r2(V.advance_adjusted) > 0)) $('#fAdv').prop('readonly', true).attr('title', 'No advance paid on this work order');

  // ---------- options
  modes.forEach(function (m) { $('#fMode').append($('<option></option>').attr('value', m).text(m)); });
  $('#fTdsSec').append('<option value="">Not deducted</option>');
  sections.forEach(function (s) { $('#fTdsSec').append($('<option></option>').attr('value', s[0]).text(s[1])); });

  // ---------- statement
  function vals() {
    return { dn: r2($('#fDn').val()), tds: r2($('#fTds').val()), ret: r2($('#fRet').val()), adv: r2($('#fAdv').val()),
             net: r2($('#fNet').val()), tdsPct: r2($('#fTdsPct').val()), retPct: r2($('#fRetPct').val()), sec: $('#fTdsSec').val() };
  }
  function line(ref, label, value, cls, hint) {
    var $l = $('<td></td>').text(label);
    if (hint) $l.append($('<span class="pv-hint"></span>').text(hint));
    $('#stmt').append($('<tr></tr>').addClass(cls || '').append($('<td class="pv-ref"></td>').text(ref || ''))
      .append($l).append($('<td class="pv-amt"></td>').text(amt(value))));
  }
  function problems(v, settles) {
    if (v.dn < 0 || v.tds < 0 || v.ret < 0 || v.adv < 0 || v.net < 0) return 'Amount paid and deductions cannot be negative.';
    if (v.dn > 0 && !$.trim($('#fDnRemarks').val())) return 'Please enter the reason for the Debit Note.';
    if (!v.sec && (v.tds > 0 || v.tdsPct > 0)) return 'Please select the TDS Section.';
    if (v.sec && v.tds <= 0) return 'Please enter the TDS Amount, or set TDS Section to Not deducted.';
    if (v.tdsPct > 100 || v.retPct > 100) return 'TDS % and Retention % must be between 0 and 100.';
    if (r2(v.tds + tdsOthers) > price) return 'Total TDS on this bill ' + money(v.tds + tdsOthers) + ' cannot be more than the taxable value ' + money(price) + '.';
    if (r2(v.ret + retOthers) > bill) return 'Total retention on this bill ' + money(v.ret + retOthers) + ' cannot be more than the bill amount ' + money(bill) + '.';
    if (v.adv > advAvail) return 'Advance adjusted ' + money(v.adv) + ' is more than the advance available ' + money(advAvail) + ' on work order ' + BILL.wo_number + '.';
    if (settles <= 0) return 'Please enter the Amount Paid Now or a deduction.';
    if (settles > dueBefore) return 'This voucher settles ' + money(settles) + ' but only ' + money(dueBefore) + ' is due on this bill.';
    return '';
  }
  var netAuto = !V;                      // new voucher: Amount Paid Now follows the balance until it is typed
  function fullNet() { var v = vals(); return Math.max(0, r2(dueBefore - v.dn - v.tds - v.ret - v.adv)); }
  function render() {
    if (netAuto) $('#fNet').val(fullNet() ? fullNet().toFixed(2) : '');
    var v = vals(), ded = r2(v.dn + v.tds + v.ret + v.adv), settles = r2(ded + v.net), after = r2(dueBefore - settles);
    $('#stmt').empty();
    line('', 'Taxable value', price, 'pv-sub');
    line('', 'Add: GST @ ' + Number(BILL.gst_percent) + ' %', r2(BILL.gst_amount), 'pv-sub');
    line('A', 'Bill amount', bill, 'pv-tot');
    if (settledOthers) {
      line('', 'Less: settled by earlier vouchers', -settledOthers, 'pv-sub', OTHERS.map(function (o) { return o.voucher_no; }).join(', '));
      line('B', 'Balance due before this voucher', dueBefore, 'pv-tot');
    }
    line('', 'Debit note', v.dn, 'pv-sub');
    line('', 'TDS' + (v.sec ? ' u/s ' + v.sec : ''), v.tds, 'pv-sub', v.tdsPct ? '@ ' + v.tdsPct + ' %' : '');
    line('', 'Retention', v.ret, 'pv-sub', v.retPct ? '@ ' + v.retPct + ' %' : '');
    line('', 'Advance adjusted', v.adv, 'pv-sub');
    line('', 'Amount paid now', v.net, 'pv-net');
    line(settledOthers ? 'C' : 'B', 'Settled by this voucher', settles, 'pv-tot');
    line('', after === 0 ? 'Balance due on the bill: nil (fully paid)' : 'Balance due on the bill after this voucher', after,
         after < 0 ? 'pv-bad' : 'pv-sub', settledOthers ? 'B - C' : 'A - B');
    $('#netHint').text('Balance due ' + money(dueBefore) + '; after deductions ' + money(fullNet()) + ' can be paid now.');
    var p = problems(v, settles);
    $('#overWarn').text(p).toggle(!!p);
    return p;
  }
  $('#fNet').on('input', function () { netAuto = false; render(); });
  $('#btnFull').on('click', function () { netAuto = false; $('#fNet').val(fullNet().toFixed(2)); render(); });

  // percentage -> amount (the amount can still be typed directly)
  $('#fTdsPct').on('input', function () {
    var pct = r2($(this).val());
    var t = Math.max(0, Math.round(price * pct / 100) - tdsOthers);
    $('#fTds').val(pct > 0 && t > 0 ? t.toFixed(2) : '');
    render();
  });
  $('#fRetPct').on('input', function () {
    var pct = r2($(this).val());
    var t = Math.max(0, r2(r2(bill * pct / 100) - retOthers));
    $('#fRet').val(pct > 0 && t > 0 ? t.toFixed(2) : '');
    render();
  });
  $('#fTdsSec').on('change', function () {
    if (!$(this).val()) { $('#fTdsPct').val(''); $('#fTds').val(''); }
    $('#fTdsPct, #fTds').prop('readonly', !$(this).val());
    render();
  });
  $('#fDn, #fDnRemarks, #fTds, #fRet, #fAdv').on('input', render);

  // ---------- fill
  $('#fInvoice').val(BILL.id);
  function z(v) { return r2(v) ? r2(v).toFixed(2) : ''; }
  if (V) {
    $('#pageTitle').text('Edit Payment Voucher ' + V.voucher_no);
    $('#btnSave').text('Update Voucher');
    $('#fId').val(V.id);
    $('#fVno').val(V.voucher_no);
    $('#fDate').val(V.payment_date);
    $('#fDn').val(z(V.debit_note_amount));
    $('#fDnRemarks').val(V.debit_note_remarks || '');
    $('#fTdsSec').val(V.tds_section || '');
    $('#fTdsPct').val(z(V.tds_percent));
    $('#fTds').val(z(V.tds_amount));
    $('#fRetPct').val(z(V.retention_percent));
    $('#fRet').val(z(V.retention_amount));
    $('#fAdv').val(z(V.advance_adjusted));
    $('#fNet').val(z(V.net_paid));
    $('#fMode').val(V.payment_mode);
    $('#fRef').val(V.reference_no || '');
    $('#fBank').val(V.bank_name || '');
    $('#fRemarks').val(V.remarks || '');
    $('#fileKeepHint').show();
    if (V.attachment_size) {
      $('#currentFile').append('Current file: ')
        .append($('<a target="_blank"></a>').attr('href', 'CsrPaymentServlet?action=file&kind=voucher&id=' + V.id).text(V.attachment_name || 'View'))
        .append(' (' + kb(V.attachment_size) + ')');
    }
  } else {
    $('#pageTitle').text(OTHERS.length ? 'New Payment Voucher (part payment ' + (OTHERS.length + 1) + ')' : 'New Payment Voucher');
    $('#btnSave').text('Save Voucher');
    if (dueBefore <= 0) {
      $('#csrError').text('Bill ' + BILL.invoice_number + ' is fully paid. No balance is due.').show();
      $('#btnSave, #btnFull').prop('disabled', true);
    }
    var d = new Date();
    $('#fDate').val(d.getFullYear() + '-' + ('0' + (d.getMonth() + 1)).slice(-2) + '-' + ('0' + d.getDate()).slice(-2));
  }
  $('#fTdsPct, #fTds').prop('readonly', !$('#fTdsSec').val());
  render();

  // ---------- save
  $('#pvForm').on('submit', function (e) {
    e.preventDefault();
    if (!$.trim($('#fVno').val())) { showToast(false, 'Please enter the Voucher No.'); $('#fVno').trigger('focus'); return; }
    if (!$('#fDate').val()) { showToast(false, 'Please enter the Payment Date.'); return; }
    if ($('#fDate').val() < BILL.invoice_date_iso) { showToast(false, 'Payment Date cannot be before the bill date ' + BILL.invoice_date + '.'); return; }
    var p = render();
    if (p) { showToast(false, p); return; }
    var file = $('#fFile')[0].files[0];
    if (file) {
      if (!/\.(pdf|jpe?g|png)$/i.test(file.name)) { showToast(false, 'Payment proof must be a PDF, JPG or PNG file.'); return; }
      if (file.size > 10 * 1024 * 1024) { showToast(false, 'The file is too large (maximum 10 MB).'); return; }
    }
    var $btn = $('#btnSave'), label = $btn.text();
    $btn.prop('disabled', true).text('Saving...');
    $.ajax({
      url: 'CsrPaymentServlet', type: 'POST', dataType: 'json',
      data: new FormData(this), processData: false, contentType: false
    }).done(function (res) {
      if (!res.ok) { showToast(false, res.message); $btn.prop('disabled', false).text(label); return; }
      window.location.href = letterUrl + '&msg=' + encodeURIComponent(res.message) + '#pay';
    }).fail(function (xhr) {
      showToast(false, (xhr.responseJSON && xhr.responseJSON.message) ? xhr.responseJSON.message : 'Could not save. Please try again.');
      $btn.prop('disabled', false).text(label);
    });
  });
  // ---------- delete (edit only): inline confirm, then back to the approval page
  if (V) $('#delBox').show();
  $(document).on('click', '#btnDel', function () {
    $('#delBox').html('<span class="csr-confirm">Delete this payment voucher?</span> '
      + '<button type="button" class="csr-btn csr-btn-bad" id="btnDelYes">Yes, delete</button> '
      + '<button type="button" class="csr-btn csr-btn-outline" id="btnDelNo">No</button>');
  });
  $(document).on('click', '#btnDelNo', function () {
    $('#delBox').html('<button type="button" class="csr-btn csr-btn-bad" id="btnDel">Delete Voucher</button>');
  });
  $(document).on('click', '#btnDelYes', function () {
    var $b = $(this).prop('disabled', true).text('Deleting...');
    $.ajax({ url: 'CsrPaymentServlet', type: 'POST', dataType: 'json', data: { action: 'deleteVoucher', id: V.id }
    }).done(function (res) {
      if (!res.ok) { showToast(false, res.message); $('#btnDelNo').trigger('click'); return; }
      window.location.href = letterUrl + '&msg=' + encodeURIComponent(res.message) + '#pay';
    }).fail(function (xhr) {
      showToast(false, (xhr.responseJSON && xhr.responseJSON.message) ? xhr.responseJSON.message : 'Could not delete. Please try again.');
      $('#btnDelNo').trigger('click');
    });
  });
});
</script>

</body>
</html>
