<%@page import="java.util.Map"%>
<%
    if (request.getAttribute("taxInvoices") == null) {
        response.sendRedirect("CsrPaymentProcedureServlet?action=form");
        return;
    }
    @SuppressWarnings("unchecked")
    Map<String, String> pp = (Map<String, String>) request.getAttribute("pp");
    boolean isEdit = pp != null;
    com.google.gson.Gson gson = new com.google.gson.Gson();
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><%= isEdit ? "Edit Payment Procedure" : "New Payment Procedure" %></title>
<%@ include file="header.jsp" %>
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
      <div class="csr-subtitle">KSS CSR Amount Spending &rsaquo; Step 3</div>
      <h1 class="csr-title" id="pageTitle"></h1>
    </div>
    <a href="CsrPaymentProcedureServlet" class="csr-btn csr-btn-outline csr-link-btn">&#8592; Back to Payment Procedures</a>
  </div>

  <div id="csrError" class="csr-alert csr-alert-err" style="display:none;"></div>
  <div id="csrToast" class="csr-alert" style="display:none;"></div>

  <form id="ppForm" autocomplete="off">
    <input type="hidden" name="action" value="save">
    <input type="hidden" name="id" id="fId" value="">

    <div class="csr-card">
      <div class="csr-card-head"><div class="csr-card-title">Payment Procedure</div></div>
      <div class="csr-form">
        <div class="csr-field span-2">
          <label for="fInvoice">Tax Invoice <span class="req">*</span></label>
          <select id="fInvoice" name="invoiceId" class="csr-input"></select>
          <div class="csr-budget" id="invoiceInfo" style="display:none;">
            <span>Invoice Amount <b id="invAmount"></b></span>
          </div>
        </div>

        <div class="csr-field">
          <label for="fPaymentDate">Payment Date <span class="req">*</span></label>
          <input type="date" id="fPaymentDate" name="paymentDate" class="csr-input">
        </div>

        <div style="border-top: 1px solid var(--fin-line); margin: 16px 0; padding-top: 16px;">
          <div class="csr-field-label">Deductions</div>
        </div>

        <div class="csr-field span-2">
          <label for="fDebitNoteAmount">Debit Note Amount (&#8377;)</label>
          <input type="number" id="fDebitNoteAmount" name="debitNoteAmount" class="csr-input csr-amount" min="0" step="0.01" placeholder="0.00">
        </div>
        <div class="csr-field span-3">
          <label for="fDebitNoteDesc">Debit Note Description</label>
          <input type="text" id="fDebitNoteDesc" name="debitNoteDescription" class="csr-input" placeholder="Reason for debit note" maxlength="500">
        </div>

        <div class="csr-field span-2">
          <label for="fTdsAmount">TDS Amount (&#8377;)</label>
          <input type="number" id="fTdsAmount" name="tdsAmount" class="csr-input csr-amount" min="0" step="0.01" placeholder="0.00">
        </div>

        <div class="csr-field span-2">
          <label for="fRetentionAmount">Retention Amount (&#8377;)</label>
          <input type="number" id="fRetentionAmount" name="retentionAmount" class="csr-input csr-amount" min="0" step="0.01" placeholder="0.00">
        </div>

        <div class="csr-field span-2">
          <label for="fAdvancePaid">Advance Paid (&#8377;)</label>
          <input type="number" id="fAdvancePaid" name="advancePaid" class="csr-input csr-amount" min="0" step="0.01" placeholder="0.00">
        </div>

        <div class="csr-field span-3">
          <div class="csr-amount-box">
            <span>Total Deductions</span>
            <b id="vTotal">&#8377; 0.00</b>
          </div>
        </div>

        <div class="csr-field span-3">
          <label for="fRemarks">Remarks</label>
          <textarea id="fRemarks" name="remarks" class="csr-input" placeholder="Any additional notes" maxlength="500" rows="2"></textarea>
        </div>

        <div class="csr-form-actions">
          <a href="CsrPaymentProcedureServlet" class="csr-btn csr-btn-outline csr-link-btn">Cancel</a>
          <button type="submit" class="csr-btn" id="btnSave"></button>
        </div>
      </div>
    </div>
  </form>
</div>

<script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
<script>
$(function () {
  var pp           = <%= gson.toJson(pp) %>;
  var taxInvoices  = <%= gson.toJson(request.getAttribute("taxInvoices")) %>;
  var preset       = <%= gson.toJson(request.getAttribute("presetInvoiceId")) %>;
  var loadError    = <%= gson.toJson(request.getAttribute("error")) %>;
  var RS = String.fromCharCode(8377);

  if (loadError) $('#csrError').text(loadError).show();

  function money(v) {
    return RS + ' ' + Number(v || 0).toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  }
  function r2(v) { return Math.round((Number(v) || 0) * 100) / 100; }
  function showToast(ok, text) {
    var $t = $('#csrToast');
    $t.removeClass('csr-alert-ok csr-alert-err').addClass(ok ? 'csr-alert-ok' : 'csr-alert-err').text(text).stop(true, true).fadeIn(150);
    clearTimeout($t.data('timer'));
    $t.data('timer', setTimeout(function () { $t.fadeOut(300); }, 4500));
    $('html, body').animate({ scrollTop: 0 }, 150);
  }

  $('#pageTitle').text(pp ? 'Edit Payment Procedure' : 'New Payment Procedure');
  $('#btnSave').text(pp ? 'Update' : 'Create');
  if (pp) {
    $('#fId').val(pp.id);
    $('#fPaymentDate').val(pp.paymentDateIso);
    $('#fDebitNoteAmount').val(pp.debitNoteAmount);
    $('#fDebitNoteDesc').val(pp.debitNoteDescription);
    $('#fTdsAmount').val(pp.tdsAmount);
    $('#fRetentionAmount').val(pp.retentionAmount);
    $('#fAdvancePaid').val(pp.advancePaid);
    $('#fRemarks').val(pp.remarks);
  }

  // invoices dropdown
  var $inv = $('#fInvoice').append('<option value="">-- Select tax invoice --</option>');
  taxInvoices.forEach(function (inv) {
    $inv.append($('<option></option>').attr('value', inv.id)
      .text(inv.invoiceNumber + '  |  ' + inv.vendorName + '  |  ' + money(inv.amount)));
  });
  if (pp) {
    $inv.val(pp.invoiceId);
  } else if (preset) {
    $inv.val(preset);
  }

  function updateInvoiceInfo() {
    var invId = $('#fInvoice').val();
    var inv = null;
    if (invId) {
      for (var i = 0; i < taxInvoices.length; i++) {
        if (String(taxInvoices[i].id) === String(invId)) { inv = taxInvoices[i]; break; }
      }
    }
    if (inv) {
      $('#invAmount').text(money(inv.amount));
      $('#invoiceInfo').show();
    } else {
      $('#invoiceInfo').hide();
    }
  }

  function updateTotal() {
    var db = r2($('#fDebitNoteAmount').val() || 0);
    var tds = r2($('#fTdsAmount').val() || 0);
    var ret = r2($('#fRetentionAmount').val() || 0);
    var adv = r2($('#fAdvancePaid').val() || 0);
    var tot = r2(db + tds + ret + adv);
    $('#vTotal').text(money(tot));
  }

  $('#fInvoice').on('change', updateInvoiceInfo);
  $('#fDebitNoteAmount, #fTdsAmount, #fRetentionAmount, #fAdvancePaid').on('input change', updateTotal);

  $('#ppForm').on('submit', function (e) {
    e.preventDefault();
    var invId = $('#fInvoice').val();
    var paymentDate = $('#fPaymentDate').val();
    if (!invId || !paymentDate) {
      showToast(false, 'Invoice and payment date are required');
      return;
    }
    var $btn = $('#btnSave').prop('disabled', true).text(pp ? 'Updating...' : 'Creating...');
    var fd = new FormData(this);
    $.ajax({
      url: 'CsrPaymentProcedureServlet',
      type: 'POST',
      dataType: 'json',
      data: fd,
      processData: false,
      contentType: false
    }).done(function (res) {
      if (!res.ok) { showToast(false, res.message); $btn.prop('disabled', false).text(pp ? 'Update' : 'Create'); return; }
      window.location.href = 'CsrPaymentProcedureServlet?msg=' + encodeURIComponent(res.message) + '&hl=' + res.id;
    }).fail(function (xhr) {
      showToast(false, (xhr.responseJSON && xhr.responseJSON.message) ? xhr.responseJSON.message : 'Could not save. Please try again.');
      $btn.prop('disabled', false).text(pp ? 'Update' : 'Create');
    });
  });

  updateInvoiceInfo();
  updateTotal();
});
</script>

</body>
</html>
