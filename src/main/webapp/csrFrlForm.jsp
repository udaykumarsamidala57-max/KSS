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
      <div class="csr-subtitle">KSS CSR Amount Spending &rsaquo; Funds Request Letters</div>
      <h1 class="csr-title" id="pageTitle"></h1>
    </div>
    <a href="CsrFrlServlet" class="csr-btn csr-btn-outline csr-link-btn">&#8592; Back to Funds Request Letters</a>
  </div>

  <div id="csrError" class="csr-alert csr-alert-err" style="display:none;"></div>
  <div id="csrToast" class="csr-alert" style="display:none;"></div>

  <form id="frlForm" enctype="multipart/form-data" autocomplete="off">
    <input type="hidden" name="action" value="save">
    <input type="hidden" name="id" id="fId" value="">

    <div class="csr-card">
      <div class="csr-card-head"><div class="csr-card-title">Funds Request Letter</div></div>
      <div class="csr-form">
        <div class="csr-field span-3">
          <label for="fLetter">Against Approval Letter <span class="req">*</span></label>
          <select id="fLetter" name="letterId" class="csr-input"></select>
          <div class="csr-budget" id="budgetBox" style="display:none;">
            <span>Approved <b id="bApproved"></b></span>
            <span>Requested in other FRLs <b id="bOthers"></b></span>
            <span>Can request <b id="bAvail"></b></span>
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
          <label for="fAmount">Amount Requested (&#8377;) <span class="req">*</span></label>
          <input type="number" id="fAmount" name="amount" class="csr-input csr-amount" min="0.01" step="0.01" placeholder="0.00">
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
          <a href="CsrFrlServlet" class="csr-btn csr-btn-outline csr-link-btn">Cancel</a>
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
  var preset    = <%= gson.toJson(request.getAttribute("presetLetterId")) %>;
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

  var $sel = $('#fLetter').append('<option value="">-- Select approval letter --</option>');
  function othersFor(l) {
    return Number(l.requested) - (frl && String(frl.letterId) === String(l.id) ? Number(frl.amount) : 0);
  }
  letters.forEach(function (l) {
    $sel.append($('<option></option>').attr('value', l.id)
      .text(l.letterNumber + '  |  ' + l.letterName + '  |  Can request ' + money(Number(l.amount) - othersFor(l))));
  });
  function current() {
    var id = $sel.val();
    for (var i = 0; i < letters.length; i++) if (String(letters[i].id) === String(id)) return letters[i];
    return null;
  }
  function budget() {
    var l = current();
    if (!l) return null;
    return { approved: Number(l.amount), others: othersFor(l), avail: r2(Number(l.amount) - othersFor(l)) };
  }
  function check() {
    var b = budget(), amt = r2($('#fAmount').val());
    if (b) {
      $('#bApproved').text(money(b.approved)); $('#bOthers').text(money(b.others)); $('#bAvail').text(money(b.avail));
      $('#budgetBox').show();
    } else {
      $('#budgetBox').hide();
    }
    var msg = '';
    if (b && amt > b.avail) msg = 'Amount ' + money(amt) + ' is more than the ' + money(b.avail) + ' still available to request on this approval letter.';
    else if (frl && amt && amt < Number(frl.received)) msg = 'Amount cannot be less than the ' + money(frl.received) + ' already received against this FRL.';
    if (msg) $('#overWarn').text(msg).show(); else $('#overWarn').hide();
    return msg;
  }
  $sel.on('change', check);
  $('#fAmount').on('input', check);

  if (frl) {
    $('#pageTitle').text('Edit Funds Request Letter');
    $('#btnSave').text('Update FRL');
    $('#fId').val(frl.id);
    $sel.val(frl.letterId);
    if (Number(frl.rcptCount) > 0) $sel.prop('disabled', true).after($('<input type="hidden" name="letterId">').val(frl.letterId));
    $('#fNumber').val(frl.frlNumber);
    $('#fDate').val(frl.frlDate);
    $('#fAmount').val(frl.amount);
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
  check();
  if (!letters.length && !loadError) $('#csrError').text('No approval letters yet. Add an approval letter first.').show();

  $('#frlForm').on('submit', function (e) {
    e.preventDefault();
    if (!$sel.val()) { showToast(false, 'Please select the Approval Letter.'); return; }
    if ($.trim($('#fNumber').val()) === '') { showToast(false, 'Please enter the FRL Number.'); $('#fNumber').trigger('focus'); return; }
    if (!$('#fDate').val()) { showToast(false, 'Please enter the FRL Date.'); return; }
    if (!(Number($('#fAmount').val()) > 0)) { showToast(false, 'Please enter a valid Amount.'); $('#fAmount').trigger('focus'); return; }
    var msg = check();
    if (msg) { showToast(false, msg); return; }
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
