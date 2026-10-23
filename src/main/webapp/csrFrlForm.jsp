<%@page import="java.util.Map"%>
<%
    // Must be opened through CsrFrlServlet?action=form (loads data + checks Global role)
    if (request.getAttribute("letters") == null) {
        response.sendRedirect("CsrFrlServlet?action=form");
        return;
    }
    @SuppressWarnings("unchecked")
    Map<String, String> frl = (Map<String, String>) request.getAttribute("frl");   // null = new
    boolean isEdit = frl != null;
    com.google.gson.Gson gson = new com.google.gson.Gson();   // escapes < > & : safe inside <script>
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><%= isEdit ? "Edit Funds Request Letter" : "New Funds Request Letter" %></title>

<!-- INCLUDE SHARED HEADER & MENU -->
<%@ include file="header.jsp" %>

<%-- CSS is included inline: ScholarshipListServelt is mapped to "/" and would intercept a separate .css request --%>
<style>
<%@ include file="css/csrLetter.css" %>
</style>
<style>
<%@ include file="css/finance.css" %>
</style>
</head>
<body>

<div class="csr-page csr-page-narrow">

  <div class="csr-header">
    <div>
      <div class="csr-subtitle"><%= com.Bean.AppConfig.code() %> CSR Amount Spending &rsaquo; Funds Request Letters</div>
      <h1 class="csr-title" id="pageTitle"></h1>
    </div>
    <a href="CsrLetterServlet" class="csr-btn csr-btn-outline csr-link-btn">&#8592; Back to Management Approvals</a>
  </div>

  <div id="csrError" class="csr-alert csr-alert-err" style="display:none;"></div>
  <div id="csrToast" class="csr-alert" style="display:none;"></div>

  <form id="frlForm" enctype="multipart/form-data" autocomplete="off">
    <input type="hidden" name="action" value="save">
    <input type="hidden" name="id" id="fId" value="">
    <input type="hidden" name="invoiceIds" id="fInvoiceIds" value="">

    <div class="csr-card">
      <div class="csr-card-head"><div class="csr-card-title">Funds Request Letter</div></div>
      <div class="csr-form">
        <div class="csr-field span-3">
          <label for="fLetter">Against Approval Letter <span class="req">*</span></label>
          <select id="fLetter" name="letterId" class="csr-input"></select>
          <div class="csr-hint" id="coHint"></div>
        </div>

        <div class="csr-field span-3">
          <label>Invoices in this FRL <span class="req">*</span></label>
          <div class="csr-table-wrap csr-inv-pick">
            <table class="csr-subtable" style="width:100%;">
              <thead>
                <tr>
                  <th style="width:34px;"><input type="checkbox" id="tickAll" title="Tick all"></th>
                  <th>Type</th>
                  <th>Invoice No</th>
                  <th>Date</th>
                  <th>Work Order / Vendor</th>
                  <th class="csr-num">Bill Amount</th>
                  <th class="csr-num">Less Proforma Invoice</th>
                  <th class="csr-num">Claim</th>
                </tr>
              </thead>
              <tbody id="invBody"></tbody>
            </table>
          </div>
        </div>

        <div class="csr-field">
          <label for="fNumber">FRL Number <span class="req">*</span></label>
          <input type="text" id="fNumber" name="frlNumber" class="csr-input" maxlength="100">
        </div>
        <div class="csr-field">
          <label for="fDate">FRL Date <span class="req">*</span></label>
          <input type="date" id="fDate" name="frlDate" class="csr-input">
        </div>
        <div class="csr-field">
          <label>Amount Requested (&#8377;)</label>
          <div class="csr-readonly csr-num" id="vAmount">-</div>
        </div>

        <div class="csr-field span-3">
          <label for="fRemarks">Remarks</label>
          <textarea id="fRemarks" name="remarks" class="csr-textarea" maxlength="500"></textarea>
          <div class="csr-over" id="overWarn" style="display:none; margin:8px 0 0;"></div>
        </div>

        <div class="csr-field span-2">
          <label for="fFile">FRL Copy (PDF / JPG / PNG) <span class="req" id="fileReq">*</span></label>
          <input type="file" id="fFile" name="attachment" class="csr-file" accept="application/pdf,.pdf,image/jpeg,.jpg,.jpeg,image/png,.png">
          <div class="csr-hint">Maximum 10 MB.<span id="fileKeepHint" style="display:none;"> Leave empty to keep the current copy.</span></div>
          <div class="csr-hint csr-current-pdf" id="currentFile"></div>
        </div>

        <div class="csr-form-actions">
          <a href="CsrLetterServlet" class="csr-btn csr-btn-outline csr-link-btn">Cancel</a>
          <button type="submit" class="csr-btn" id="btnSave"></button>
        </div>
      </div>
    </div>
  </form>
</div>

<script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
<script>
$(function () {
  var frl       = <%= gson.toJson(frl) %>;                     // null when adding
  var letters   = <%= gson.toJson(request.getAttribute("letters")) %>;
  var invoices  = <%= gson.toJson(request.getAttribute("invoices")) %>;
  var preset    = <%= gson.toJson(request.getAttribute("presetLetterId")) %>;
  var presetInv = <%= gson.toJson(request.getAttribute("presetInvoiceId")) %>;
  var loadError = <%= gson.toJson(request.getAttribute("error")) %>;
  var RS = String.fromCharCode(8377);

  if (loadError) $('#csrError').text(loadError).show();

  function money(v) {
    return RS + ' ' + Number(v || 0).toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  }
  function r2(v) { return Math.round((Number(v) || 0) * 100) / 100; }
  function kb(bytes) {
    var n = parseInt(bytes, 10) || 0;
    return n >= 1048576 ? (n / 1048576).toFixed(1) + ' MB' : Math.max(1, Math.round(n / 1024)) + ' KB';
  }
  function showToast(ok, text) {
    var $t = $('#csrToast');
    $t.removeClass('csr-alert-ok csr-alert-err').addClass(ok ? 'csr-alert-ok' : 'csr-alert-err').text(text).stop(true, true).fadeIn(150);
    clearTimeout($t.data('timer'));
    $t.data('timer', setTimeout(function () { $t.fadeOut(300); }, 4500));
    $('html, body').animate({ scrollTop: 0 }, 150);
  }

  var myIds = frl && frl.invoiceIds ? String(frl.invoiceIds).split(',') : [];
  var $sel = $('#fLetter').append('<option value="">-- Select approval letter --</option>');
  letters.forEach(function (l) {
    $sel.append($('<option></option>').attr('value', l.id)
      .text(l.letterNumber + '  |  ' + l.letterName + '  |  ' + (l.companyName || 'company not set')));
  });
  // the FRL is a request to the approval's funding company
  function showCompany() {
    var l = null, id = $sel.val();
    letters.forEach(function (x) { if (String(x.id) === String(id)) l = x; });
    if (!l) { $('#coHint').text('').css('color', ''); return; }
    if (l.companyName) $('#coHint').text('Request to: ' + l.companyName).css('color', '#0f766e');
    else $('#coHint').text('This approval has no funding company. Edit the approval and select the company first.').css('color', '#b91c1c');
  }
  $sel.on('change', showCompany);

  // invoices of the chosen letter that are free, or already in this FRL
  function renderInvoices(keepTicks) {
    var ticked = keepTicks ? $('.inv-tick:checked').map(function () { return this.value; }).get() : null;
    var lid = $sel.val(), $b = $('#invBody').empty(), n = 0;
    invoices.forEach(function (v) {
      if (!lid || String(v.letterId) !== String(lid)) return;
      var mine = myIds.indexOf(String(v.id)) !== -1;
      if (v.frlId && !mine) return;
      var claim = mine ? Number(v.claimAmount || v.amount) : Number(v.claimable);
      if (!mine && !(claim > 0)) return;                       // nothing left to claim (settled proforma / fully covered by advance)
      var less = Number(v.amount) - claim;
      var on = ticked ? ticked.indexOf(String(v.id)) !== -1 : (mine || String(v.id) === String(presetInv));
      var $tr = $('<tr></tr>');
      $tr.append($('<td></td>').append($('<input type="checkbox" class="inv-tick">').val(v.id).prop('checked', on)));
      $tr.append($('<td></td>').append($('<span class="csr-badge"></span>').text(v.invoiceType === 'Proforma' ? 'Proforma Invoice' : 'Tax Invoice').toggleClass('csr-badge-pi', v.invoiceType === 'Proforma')));
      $tr.append($('<td></td>').append($('<div class="csr-strong"></div>').text(v.invoiceNumber))
        .append($('<div class="csr-small"></div>').text(v.invoiceType === 'Proforma' ? 'Proforma Invoice' : (v.proformaNumber ? 'Against ' + v.proformaNumber : ''))));
      $tr.append($('<td></td>').text(v.invoiceDateTxt));
      $tr.append($('<td></td>').append($('<div></div>').text(v.woNumber)).append($('<div class="csr-small"></div>').text(v.vendorName)));
      $tr.append($('<td class="csr-num"></td>').text(money(v.amount)));
      $tr.append($('<td class="csr-num"></td>').text(less > 0 ? money(less) : '-')
        .attr('title', less > 0 ? 'Amount already claimed against ' + (v.proformaNumber || 'the proforma invoice') : ''));
      $tr.append($('<td class="csr-num csr-strong"></td>').text(money(claim)).attr('data-amt', claim));
      $b.append($tr); n++;
    });
    if (!lid) $b.append('<tr><td colspan="8" class="csr-empty">Select the approval letter to see its invoices.</td></tr>');
    else if (!n) $b.append('<tr><td colspan="8" class="csr-empty">No invoices waiting for an FRL on this approval letter. Add the invoice first (<%= com.Bean.AppConfig.code() %> CSR &gt; Invoices).</td></tr>');
    total();
  }
  function total() {
    var sum = 0, ids = [];
    $('.inv-tick:checked').each(function () {
      ids.push(this.value);
      sum += Number($(this).closest('tr').find('[data-amt]').attr('data-amt'));
    });
    sum = r2(sum);
    $('#fInvoiceIds').val(ids.join(','));
    $('#vAmount').text(ids.length ? money(sum) : '-');
    $('#tickAll').prop('checked', ids.length > 0 && ids.length === $('.inv-tick').length);
    var msg = '';
    if (frl && ids.length && sum < Number(frl.received))
      msg = 'The ticked invoices total ' + money(sum) + ', less than the ' + money(frl.received) + ' already received against this FRL.';
    if (msg) $('#overWarn').text(msg).show(); else $('#overWarn').hide();
    return { ids: ids, sum: sum, msg: msg };
  }
  $sel.on('change', function () { presetInv = ''; renderInvoices(false); });
  $(document).on('change', '.inv-tick', total);
  $('#tickAll').on('change', function () { $('.inv-tick').prop('checked', this.checked); total(); });

  if (frl) {
    $('#pageTitle').text('Edit Funds Request Letter');
    $('#btnSave').text('Update FRL');
    $('#fId').val(frl.id);
    $sel.val(frl.letterId);
    if (Number(frl.rcptCount) > 0) $sel.prop('disabled', true).after($('<input type="hidden" name="letterId">').val(frl.letterId));
    $('#fNumber').val(frl.frlNumber);
    $('#fDate').val(frl.frlDate);
    $('#fRemarks').val(frl.remarks || '');
    $('#fileReq').hide();
    $('#fileKeepHint').show();
    if (frl.attachmentSize) {
      $('#currentFile').append('Current copy: ')
        .append($('<a target="_blank"></a>').attr('href', 'CsrFrlServlet?action=file&id=' + frl.id).text(frl.attachmentName || 'View'))
        .append(' (' + kb(frl.attachmentSize) + ')');
    }
  } else {
    $('#pageTitle').text('New Funds Request Letter');
    $('#btnSave').text('Save FRL');
    if (preset) $sel.val(preset);
    var d = new Date();
    $('#fDate').val(d.getFullYear() + '-' + ('0' + (d.getMonth() + 1)).slice(-2) + '-' + ('0' + d.getDate()).slice(-2));
  }
  renderInvoices(false);
  showCompany();
  if (!letters.length && !loadError) $('#csrError').text('No Management Approvals yet. Add an approval letter first.').show();

  $('#frlForm').on('submit', function (e) {
    e.preventDefault();
    if (!$sel.val()) { showToast(false, 'Please select the Approval Letter.'); return; }
    var t = total();
    if (!t.ids.length) { showToast(false, 'Please tick at least one invoice for this FRL.'); return; }
    if (t.msg) { showToast(false, t.msg); return; }
    if ($.trim($('#fNumber').val()) === '') { showToast(false, 'Please enter the FRL Number.'); $('#fNumber').trigger('focus'); return; }
    if (!$('#fDate').val()) { showToast(false, 'Please enter the FRL Date.'); return; }
    var file = $('#fFile')[0].files[0];
    if (!file && !frl) { showToast(false, 'Please attach the Funds Request Letter copy.'); return; }
    if (file) {
      if (!/\.(pdf|jpe?g|png)$/i.test(file.name)) { showToast(false, 'Attachment must be a PDF, JPG or PNG file.'); return; }
      if (file.size > 10 * 1024 * 1024) { showToast(false, 'The attachment is too large (maximum 10 MB).'); return; }
    }
    var $btn = $('#btnSave'), label = $btn.text();
    $btn.prop('disabled', true).text('Saving...');
    $.ajax({
      url: 'CsrFrlServlet', type: 'POST', dataType: 'json',
      data: new FormData(this), processData: false, contentType: false
    }).done(function (res) {
      if (!res.ok) { showToast(false, res.message); $btn.prop('disabled', false).text(label); return; }
      window.location.href = 'CsrFrlServlet?msg=' + encodeURIComponent(res.message) + '&hl=' + res.id;
    }).fail(function (xhr) {
      showToast(false, (xhr.responseJSON && xhr.responseJSON.message) ? xhr.responseJSON.message : 'Could not save. Please try again.');
      $btn.prop('disabled', false).text(label);
    });
  });
});
</script>

</body>
</html>
