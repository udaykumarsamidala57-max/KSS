<%@page import="java.util.Map"%>
<%
    // Must be opened through CsrPaymentServlet?action=advanceForm (loads data + checks Global role)
    if (request.getAttribute("workOrders") == null) {
        response.sendRedirect("CsrLetterServlet");
        return;
    }
    @SuppressWarnings("unchecked")
    Map<String, String> adv = (Map<String, String>) request.getAttribute("adv");   // null = new
    boolean isEdit = adv != null;
    com.google.gson.Gson gson = new com.google.gson.Gson();   // escapes < > & : safe inside <script>
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><%= isEdit ? "Edit Advance to Vendor" : "New Advance to Vendor" %></title>

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
      <div class="csr-subtitle"><a id="crumb" style="color:inherit;"><%= com.Bean.AppConfig.code() %> CSR Amount Spending &rsaquo; Management Approvals</a></div>
      <h1 class="csr-title" id="pageTitle"></h1>
    </div>
    <a class="csr-btn csr-btn-outline csr-link-btn" id="btnBack">&#8592; Back to Management Approval</a>
  </div>

  <div id="csrError" class="csr-alert csr-alert-err" style="display:none;"></div>
  <div id="csrToast" class="csr-alert" style="display:none;"></div>

  <form id="advForm" enctype="multipart/form-data" autocomplete="off">
    <input type="hidden" name="action" value="saveAdvance">
    <input type="hidden" name="id" id="fId" value="">

    <div class="csr-card">
      <div class="csr-card-head"><div class="csr-card-title">Advance Paid to Vendor</div></div>
      <div class="csr-form">
        <div class="csr-field span-3">
          <label for="fWo">Against Work Order <span class="req">*</span></label>
          <select id="fWo" name="woId" class="csr-input"></select>
          <div class="csr-budget" id="woBox" style="display:none;">
            <span>Work order value <b id="bTotal"></b></span>
            <span>Advance paid earlier <b id="bPaid"></b></span>
            <span>Adjusted in bills <b id="bAdj"></b></span>
            <span>Can still be paid as advance <b id="bRoom"></b></span>
          </div>
        </div>

        <div class="csr-field">
          <label for="fDate">Advance Date <span class="req">*</span></label>
          <input type="date" id="fDate" name="advanceDate" class="csr-input">
        </div>
        <div class="csr-field">
          <label for="fAmount">Advance Amount (&#8377;) <span class="req">*</span></label>
          <input type="number" id="fAmount" name="amount" class="csr-input csr-amount" min="0.01" step="0.01">
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
          <div class="csr-over" id="overWarn" style="display:none; margin:8px 0 0;"></div>
        </div>

        <div class="csr-field span-2">
          <label for="fFile">Payment Proof (PDF / JPG / PNG)</label>
          <input type="file" id="fFile" name="attachment" class="csr-file" accept="application/pdf,.pdf,image/jpeg,.jpg,.jpeg,image/png,.png">
          <div class="csr-hint">Bank advice or cheque copy. Optional, maximum 10 MB.<span id="fileKeepHint" style="display:none;"> Leave empty to keep the current file.</span></div>
          <div class="csr-hint csr-current-pdf" id="currentFile"></div>
        </div>

        <div class="csr-form-actions">
          <span id="delBox" style="display:none; margin-right:auto;"><button type="button" class="csr-btn csr-btn-bad" id="btnDel">Delete Advance</button></span>
          <a class="csr-btn csr-btn-outline csr-link-btn" id="btnCancel">Cancel</a>
          <button type="submit" class="csr-btn" id="btnSave"></button>
        </div>
      </div>
    </div>
  </form>
</div>

<script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
<script>
$(function () {
  var A         = <%= gson.toJson(adv) %>;                          // null when adding
  var L         = <%= gson.toJson(request.getAttribute("letter")) %> || {};
  var WO        = <%= gson.toJson(request.getAttribute("workOrders")) %> || [];
  var preset    = <%= gson.toJson(request.getAttribute("presetWoId")) %>;
  var modes     = <%= gson.toJson(request.getAttribute("modes")) %> || [];
  var loadError = <%= gson.toJson(request.getAttribute("error")) %>;
  var RS = String.fromCharCode(8377);

  if (loadError) $('#csrError').text(loadError).show();

  function r2(v) { return Math.round((Number(v) || 0) * 100) / 100; }
  function money(v) {
    return RS + ' ' + r2(v).toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  }
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

  var letterUrl = 'CsrLetterServlet?action=view&id=' + L.id;
  $('#crumb').attr('href', letterUrl + '#pay').html('<%= com.Bean.AppConfig.code() %> CSR Amount Spending &rsaquo; Management Approvals &rsaquo; ')
    .append(document.createTextNode(L.letter_number || ''));
  $('#btnBack, #btnCancel').attr('href', letterUrl + '#pay');

  modes.forEach(function (m) { $('#fMode').append($('<option></option>').attr('value', m).text(m)); });
  var $wo = $('#fWo').append('<option value="">-- Select work order --</option>');
  WO.forEach(function (w) {
    $wo.append($('<option></option>').attr('value', w.id).text(w.wo_number + '  |  ' + w.vendor_name + '  |  ' + money(w.total_amount)));
  });
  function current() {
    for (var i = 0; i < WO.length; i++) if (String(WO[i].id) === String($wo.val())) return WO[i];
    return null;
  }
  // figures of the work order without this advance
  function figures() {
    var w = current();
    if (!w) return null;
    var paid = r2(w.adv_paid) - (A && String(A.work_order_id) === String(w.id) ? r2(A.amount) : 0);
    return { total: r2(w.total_amount), paid: r2(paid), adj: r2(w.adv_adjusted), room: r2(r2(w.total_amount) - paid) };
  }
  function check() {
    var f = figures(), amt = r2($('#fAmount').val()), msg = '';
    if (f) {
      $('#bTotal').text(money(f.total)); $('#bPaid').text(money(f.paid)); $('#bAdj').text(money(f.adj)); $('#bRoom').text(money(f.room));
      $('#woBox').show();
      if (amt > f.room) msg = 'Advance ' + money(amt) + ' is more than the ' + money(f.room) + ' that can still be paid against this work order.';
      else if (amt > 0 && f.paid + amt < f.adj) msg = money(f.adj) + ' of advance is already adjusted against bills of this work order. The total advance cannot be less than that.';
    } else {
      $('#woBox').hide();
    }
    $('#overWarn').text(msg).toggle(!!msg);
    return msg;
  }
  $wo.on('change', check);
  $('#fAmount').on('input', check);

  if (A) {
    $('#pageTitle').text('Edit Advance to Vendor');
    $('#btnSave').text('Update Advance');
    $('#fId').val(A.id);
    $wo.val(A.work_order_id);
    $('#fDate').val(A.advance_date);
    $('#fAmount').val(A.amount);
    $('#fMode').val(A.payment_mode);
    $('#fRef').val(A.reference_no || '');
    $('#fBank').val(A.bank_name || '');
    $('#fRemarks').val(A.remarks || '');
    $('#fileKeepHint').show();
    if (A.attachment_size) {
      $('#currentFile').append('Current file: ')
        .append($('<a target="_blank"></a>').attr('href', 'CsrPaymentServlet?action=file&kind=advance&id=' + A.id).text(A.attachment_name || 'View'))
        .append(' (' + kb(A.attachment_size) + ')');
    }
  } else {
    $('#pageTitle').text('New Advance to Vendor');
    $('#btnSave').text('Save Advance');
    if (preset) $wo.val(preset);
    var d = new Date();
    $('#fDate').val(d.getFullYear() + '-' + ('0' + (d.getMonth() + 1)).slice(-2) + '-' + ('0' + d.getDate()).slice(-2));
  }
  check();
  if (!WO.length && !loadError) $('#csrError').text('This management approval has no work order yet. Add a work order first.').show();

  $('#advForm').on('submit', function (e) {
    e.preventDefault();
    if (!$wo.val()) { showToast(false, 'Please select the Work Order.'); return; }
    if (!$('#fDate').val()) { showToast(false, 'Please enter the Advance Date.'); return; }
    if (!(r2($('#fAmount').val()) > 0)) { showToast(false, 'Please enter a valid Advance Amount.'); $('#fAmount').trigger('focus'); return; }
    var msg = check();
    if (msg) { showToast(false, msg); return; }
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
      window.location.href = 'CsrLetterServlet?action=view&id=' + res.letterId + '&msg=' + encodeURIComponent(res.message) + '#pay';
    }).fail(function (xhr) {
      showToast(false, (xhr.responseJSON && xhr.responseJSON.message) ? xhr.responseJSON.message : 'Could not save. Please try again.');
      $btn.prop('disabled', false).text(label);
    });
  });
  // ---------- delete (edit only): inline confirm, then back to the approval page
  if (A) $('#delBox').show();
  $(document).on('click', '#btnDel', function () {
    $('#delBox').html('<span class="csr-confirm">Delete this advance?</span> '
      + '<button type="button" class="csr-btn csr-btn-bad" id="btnDelYes">Yes, delete</button> '
      + '<button type="button" class="csr-btn csr-btn-outline" id="btnDelNo">No</button>');
  });
  $(document).on('click', '#btnDelNo', function () {
    $('#delBox').html('<button type="button" class="csr-btn csr-btn-bad" id="btnDel">Delete Advance</button>');
  });
  $(document).on('click', '#btnDelYes', function () {
    var $b = $(this).prop('disabled', true).text('Deleting...');
    $.ajax({ url: 'CsrPaymentServlet', type: 'POST', dataType: 'json', data: { action: 'deleteAdvance', id: A.id }
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
