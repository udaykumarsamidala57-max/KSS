<%@page import="java.util.Map"%>
<%
    // Must be opened through CsrFundServlet?action=form (loads data + checks Global role)
    if (request.getAttribute("frls") == null) {
        response.sendRedirect("CsrFundServlet?action=form");
        return;
    }
    @SuppressWarnings("unchecked")
    Map<String, String> fund = (Map<String, String>) request.getAttribute("fund");   // null = new
    boolean isEdit = fund != null;
    com.google.gson.Gson gson = new com.google.gson.Gson();   // escapes < > & : safe inside <script>
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><%= isEdit ? "Edit Fund Receipt" : "New Fund Receipt" %></title>

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
      <div class="csr-subtitle">KSS CSR Amount Spending &rsaquo; Fund Receipts</div>
      <h1 class="csr-title" id="pageTitle"></h1>
    </div>
    <a href="CsrFundServlet" class="csr-btn csr-btn-outline csr-link-btn">&#8592; Back to Fund Receipts</a>
  </div>

  <div id="csrError" class="csr-alert csr-alert-err" style="display:none;"></div>
  <div id="csrToast" class="csr-alert" style="display:none;"></div>

  <form id="fundForm" enctype="multipart/form-data" autocomplete="off">
    <input type="hidden" name="action" value="save">
    <input type="hidden" name="id" id="fId" value="">

    <div class="csr-card">
      <div class="csr-card-head"><div class="csr-card-title">Fund Received</div></div>
      <div class="csr-form">
        <div class="csr-field span-3">
          <label for="fFrl">Against Funds Request Letter (FRL) <span class="req">*</span></label>
          <select id="fFrl" name="frlId" class="csr-input"></select>
          <div class="csr-budget" id="budgetBox" style="display:none;">
            <span>Approval letter <b id="bLetter"></b></span>
            <span>FRL amount <b id="bApproved"></b></span>
            <span>Received earlier <b id="bOthers"></b></span>
            <span>Yet to receive <b id="bPending"></b></span>
          </div>
        </div>

        <div class="csr-field">
          <label for="fDate">Receipt Date <span class="req">*</span></label>
          <input type="date" id="fDate" name="receiptDate" class="csr-input">
        </div>
        <div class="csr-field">
          <label for="fAmount">Amount Received (&#8377;) <span class="req">*</span></label>
          <input type="number" id="fAmount" name="amount" class="csr-input csr-amount" min="0.01" step="0.01" placeholder="0.00">
        </div>
        <div class="csr-field">
          <label for="fMode">Payment Mode <span class="req">*</span></label>
          <select id="fMode" name="paymentMode" class="csr-input"></select>
        </div>

        <div class="csr-field">
          <label for="fRef">Reference No (UTR / Cheque)</label>
          <input type="text" id="fRef" name="referenceNo" class="csr-input" maxlength="100">
        </div>
        <div class="csr-field span-2">
          <label for="fBank">Bank Name</label>
          <input type="text" id="fBank" name="bankName" class="csr-input" maxlength="150">
        </div>

        <div class="csr-field span-3">
          <label for="fRemarks">Remarks</label>
          <textarea id="fRemarks" name="remarks" class="csr-textarea" maxlength="500"></textarea>
          <div class="csr-over" id="overWarn" style="display:none; margin:8px 0 0;"></div>
        </div>

        <div class="csr-field span-2">
          <label for="fFile">Attachment (PDF / JPG / PNG)</label>
          <input type="file" id="fFile" name="attachment" class="csr-file" accept="application/pdf,.pdf,image/jpeg,.jpg,.jpeg,image/png,.png">
          <div class="csr-hint">Receipt / bank statement. Optional, maximum 10 MB.<span id="fileKeepHint" style="display:none;"> Leave empty to keep the current file.</span></div>
          <div class="csr-hint csr-current-pdf" id="currentFile"></div>
        </div>

        <div class="csr-form-actions">
          <a href="CsrFundServlet" class="csr-btn csr-btn-outline csr-link-btn">Cancel</a>
          <button type="submit" class="csr-btn" id="btnSave"></button>
        </div>
      </div>
    </div>
  </form>
</div>

<script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
<script>
$(function () {
  var fund      = <%= gson.toJson(fund) %>;                    // null when adding
  var frls      = <%= gson.toJson(request.getAttribute("frls")) %>;
  var modes     = <%= gson.toJson(request.getAttribute("modes")) %>;
  var preset    = <%= gson.toJson(request.getAttribute("presetFrlId")) %>;
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

  (modes || []).forEach(function (m) { $('#fMode').append($('<option></option>').attr('value', m).text(m)); });

  var $sel = $('#fFrl').append('<option value="">-- Select funds request letter --</option>');
  function othersFor(l) {
    return Number(l.received) - (fund && String(fund.frlId) === String(l.id) ? Number(fund.amount) : 0);
  }
  frls.forEach(function (l) {
    var pending = Number(l.amount) - othersFor(l);
    // show FRLs with money still to come, plus the one this receipt already belongs to
    if (pending <= 0 && !(fund && String(fund.frlId) === String(l.id))) return;
    $sel.append($('<option></option>').attr('value', l.id)
      .text(l.frlNumber + '  |  ' + l.frlDateTxt + '  |  ' + l.letterNumber + '  |  Yet to receive ' + money(pending)));
  });
  function current() {
    var id = $sel.val();
    for (var i = 0; i < frls.length; i++) if (String(frls[i].id) === String(id)) return frls[i];
    return null;
  }
  function budget() {
    var l = current();
    if (!l) return null;
    return { letter: l.letterNumber + ' - ' + l.letterName, approved: Number(l.amount), others: othersFor(l), pending: r2(Number(l.amount) - othersFor(l)) };
  }
  function check() {
    var b = budget(), amt = r2($('#fAmount').val());
    if (b) {
      $('#bLetter').text(b.letter); $('#bApproved').text(money(b.approved)); $('#bOthers').text(money(b.others)); $('#bPending').text(money(b.pending));
      $('#budgetBox').show();
    } else {
      $('#budgetBox').hide();
    }
    if (b && amt > b.pending) {
      $('#overWarn').text('Amount ' + money(amt) + ' is more than the ' + money(b.pending) + ' yet to receive against this FRL.').show();
    } else {
      $('#overWarn').hide();
    }
    return amt;
  }
  $sel.on('change', check);
  $('#fAmount').on('input', check);

  if (fund) {
    $('#pageTitle').text('Edit Fund Receipt');
    $('#btnSave').text('Update Receipt');
    $('#fId').val(fund.id);
    $sel.val(fund.frlId);
    $('#fDate').val(fund.receiptDate);
    $('#fAmount').val(fund.amount);
    $('#fMode').val(fund.paymentMode);
    $('#fRef').val(fund.referenceNo || '');
    $('#fBank').val(fund.bankName || '');
    $('#fRemarks').val(fund.remarks || '');
    $('#fileKeepHint').show();
    if (fund.attachmentSize) {
      $('#currentFile').append('Current file: ')
        .append($('<a target="_blank"></a>').attr('href', 'CsrFundServlet?action=file&id=' + fund.id).text(fund.attachmentName || 'View'))
        .append(' (' + kb(fund.attachmentSize) + ')');
    }
  } else {
    $('#pageTitle').text('New Fund Receipt');
    $('#btnSave').text('Save Receipt');
    if (preset) $sel.val(preset);
    var d = new Date();
    $('#fDate').val(d.getFullYear() + '-' + ('0' + (d.getMonth() + 1)).slice(-2) + '-' + ('0' + d.getDate()).slice(-2));
  }
  check();
  if ($sel.find('option').length < 2 && !loadError)
    $('#csrError').text('No funds request letter is waiting for money. Add a Funds Request Letter first (KSS CSR > Funds Request Letters).').show();

  $('#fundForm').on('submit', function (e) {
    e.preventDefault();
    if (!$sel.val()) { showToast(false, 'Please select the Funds Request Letter.'); return; }
    if (!$('#fDate').val()) { showToast(false, 'Please enter the Receipt Date.'); return; }
    if (!(Number($('#fAmount').val()) > 0)) { showToast(false, 'Please enter a valid Amount.'); $('#fAmount').trigger('focus'); return; }
    var amt = check(), b = budget();
    if (b && amt > b.pending) { showToast(false, $('#overWarn').text()); return; }
    var file = $('#fFile')[0].files[0];
    if (file) {
      if (!/\.(pdf|jpe?g|png)$/i.test(file.name)) { showToast(false, 'Attachment must be a PDF, JPG or PNG file.'); return; }
      if (file.size > 10 * 1024 * 1024) { showToast(false, 'The attachment is too large (maximum 10 MB).'); return; }
    }
    var $btn = $('#btnSave'), label = $btn.text();
    $btn.prop('disabled', true).text('Saving...');
    $.ajax({
      url: 'CsrFundServlet', type: 'POST', dataType: 'json',
      data: new FormData(this), processData: false, contentType: false
    }).done(function (res) {
      if (!res.ok) { showToast(false, res.message); $btn.prop('disabled', false).text(label); return; }
      window.location.href = 'CsrFundServlet?msg=' + encodeURIComponent(res.message) + '&hl=' + res.id;
    }).fail(function (xhr) {
      showToast(false, (xhr.responseJSON && xhr.responseJSON.message) ? xhr.responseJSON.message : 'Could not save. Please try again.');
      $btn.prop('disabled', false).text(label);
    });
  });
});
</script>

</body>
</html>
