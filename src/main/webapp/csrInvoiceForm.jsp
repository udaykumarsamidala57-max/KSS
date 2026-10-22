<%@page import="java.util.Map"%>
<%
    // Must be opened through CsrInvoiceServlet?action=form (loads data + checks Global role)
    if (request.getAttribute("workOrders") == null) {
        response.sendRedirect("CsrInvoiceServlet?action=form");
        return;
    }
    @SuppressWarnings("unchecked")
    Map<String, String> inv = (Map<String, String>) request.getAttribute("inv");   // null = new
    boolean isEdit = inv != null;
    com.google.gson.Gson gson = new com.google.gson.Gson();   // escapes < > & : safe inside <script>
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><%= isEdit ? "Edit Invoice" : "New Invoice" %></title>

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
      <div class="csr-subtitle">KSS CSR Amount Spending &rsaquo; Step 3</div>
      <h1 class="csr-title" id="pageTitle"></h1>
    </div>
    <a href="CsrInvoiceServlet" class="csr-btn csr-btn-outline csr-link-btn">&#8592; Back to Invoices</a>
  </div>

  <div id="csrError" class="csr-alert csr-alert-err" style="display:none;"></div>
  <div id="csrToast" class="csr-alert" style="display:none;"></div>

  <form id="invForm" enctype="multipart/form-data" autocomplete="off">
    <input type="hidden" name="action" value="save">
    <input type="hidden" name="id" id="fId" value="">

    <div class="csr-card">
      <div class="csr-card-head"><div class="csr-card-title">Invoice</div></div>
      <div class="csr-form">
        <div class="csr-field span-3">
          <label for="fWo">Against Work Order <span class="req">*</span></label>
          <select id="fWo" name="woId" class="csr-input"></select>
          <div class="csr-budget" id="budgetBox" style="display:none;">
            <span>Work order total <b id="bTotal"></b></span>
            <span>Other invoices <b id="bOthers"></b></span>
            <span>Available <b id="bAvailable"></b></span>
          </div>
        </div>

        <div class="csr-field">
          <label for="fNumber">Invoice Number <span class="req">*</span></label>
          <input type="text" id="fNumber" name="invoiceNumber" class="csr-input" maxlength="100">
        </div>
        <div class="csr-field">
          <label for="fDate">Invoice Date <span class="req">*</span></label>
          <input type="date" id="fDate" name="invoiceDate" class="csr-input">
        </div>
        <div class="csr-field"></div>

        <div class="csr-field">
          <label for="fPrice">Price (&#8377;) <span class="req">*</span></label>
          <input type="number" id="fPrice" name="price" class="csr-input csr-amount" min="0.01" step="0.01" placeholder="0.00">
        </div>
        <div class="csr-field">
          <label for="fGst">GST %</label>
          <select id="fGst" name="gst" class="csr-input">
            <option value="0">0 %</option>
            <option value="5">5 %</option>
            <option value="12">12 %</option>
            <option value="18" selected>18 %</option>
            <option value="28">28 %</option>
          </select>
        </div>
        <div class="csr-field">
          <label>GST (&#8377;)</label>
          <div class="csr-readonly" id="vGst">-</div>
        </div>

        <div class="csr-field span-3">
          <div class="csr-amount-box">
            <span>Invoice Amount (Price + GST)</span>
            <b id="vAmount">-</b>
          </div>
          <div class="csr-over" id="overWarn" style="display:none; margin:8px 0 0;"></div>
        </div>

        <div class="csr-field span-2">
          <label for="fFile">Invoice Copy (PDF / JPG / PNG)</label>
          <input type="file" id="fFile" name="attachment" class="csr-file" accept="application/pdf,.pdf,image/jpeg,.jpg,.jpeg,image/png,.png">
          <div class="csr-hint">Optional, maximum 10 MB.<span id="fileKeepHint" style="display:none;"> Leave empty to keep the current copy.</span></div>
          <div class="csr-hint csr-current-pdf" id="currentFile"></div>
        </div>

        <div class="csr-form-actions">
          <a href="CsrInvoiceServlet" class="csr-btn csr-btn-outline csr-link-btn">Cancel</a>
          <button type="submit" class="csr-btn" id="btnSave"></button>
        </div>
      </div>
    </div>
  </form>
</div>

<script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
<script>
$(function () {
  var inv        = <%= gson.toJson(inv) %>;                     // null when adding
  var workOrders = <%= gson.toJson(request.getAttribute("workOrders")) %>;
  var preset     = <%= gson.toJson(request.getAttribute("presetWoId")) %>;
  var loadError  = <%= gson.toJson(request.getAttribute("error")) %>;
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

  // ---- work orders + balance
  var $wo = $('#fWo').append('<option value="">-- Select work order --</option>');
  function othersFor(w) {
    return Number(w.invoiced) - (inv && String(inv.woId) === String(w.id) ? Number(inv.amount) : 0);
  }
  workOrders.forEach(function (w) {
    var avail = Number(w.total) - othersFor(w);
    $wo.append($('<option></option>').attr('value', w.id)
      .text(w.woNumber + '  |  ' + w.vendorName + '  |  ' + w.letterNumber + '  |  Available ' + money(avail)));
  });
  function currentWo() {
    var id = $wo.val();
    for (var i = 0; i < workOrders.length; i++) if (String(workOrders[i].id) === String(id)) return workOrders[i];
    return null;
  }
  function available() {
    var w = currentWo();
    if (!w) return null;
    return { total: Number(w.total), others: othersFor(w), avail: r2(Number(w.total) - othersFor(w)) };
  }
  function recalc() {
    var price = r2($('#fPrice').val()), g = r2(price * Number($('#fGst').val()) / 100), amt = r2(price + g);
    $('#vGst').text(price ? money(g) : '-');
    $('#vAmount').text(price ? money(amt) : '-');
    var b = available();
    if (b) {
      $('#bTotal').text(money(b.total)); $('#bOthers').text(money(b.others)); $('#bAvailable').text(money(b.avail));
      $('#budgetBox').show();
    } else {
      $('#budgetBox').hide();
    }
    if (b && amt > b.avail) {
      $('#overWarn').text('Invoice amount ' + money(amt) + ' is more than the available ' + money(b.avail) + ' on this work order.').show();
    } else {
      $('#overWarn').hide();
    }
    return amt;
  }
  $wo.on('change', recalc);
  $('#fPrice, #fGst').on('input change', recalc);

  // ---- fill form
  if (inv) {
    $('#pageTitle').text('Edit Invoice');
    $('#btnSave').text('Update Invoice');
    $('#fId').val(inv.id);
    $wo.val(inv.woId);
    $('#fNumber').val(inv.invoiceNumber);
    $('#fDate').val(inv.invoiceDate);
    $('#fPrice').val(inv.price);
    if ($('#fGst option[value="' + inv.gst + '"]').length === 0) $('#fGst').append($('<option></option>').attr('value', inv.gst).text(inv.gst + ' %'));
    $('#fGst').val(inv.gst);
    $('#fileKeepHint').show();
    if (inv.attachmentSize) {
      $('#currentFile').append('Current copy: ')
        .append($('<a target="_blank"></a>').attr('href', 'CsrInvoiceServlet?action=file&id=' + inv.id).text(inv.attachmentName || 'View'))
        .append(' (' + kb(inv.attachmentSize) + ')');
    }
  } else {
    $('#pageTitle').text('New Invoice');
    $('#btnSave').text('Save Invoice');
    if (preset) $wo.val(preset);
    var d = new Date();
    $('#fDate').val(d.getFullYear() + '-' + ('0' + (d.getMonth() + 1)).slice(-2) + '-' + ('0' + d.getDate()).slice(-2));
  }
  recalc();
  if (!workOrders.length && !loadError) $('#csrError').text('No work orders yet. Create a work order first (KSS CSR > Work Orders).').show();

  // ---- save (AJAX), then back to the list
  $('#invForm').on('submit', function (e) {
    e.preventDefault();
    if (!$wo.val()) { showToast(false, 'Please select the Work Order.'); return; }
    if ($.trim($('#fNumber').val()) === '') { showToast(false, 'Please enter the Invoice Number.'); $('#fNumber').trigger('focus'); return; }
    if (!$('#fDate').val()) { showToast(false, 'Please enter the Invoice Date.'); return; }
    if (!(Number($('#fPrice').val()) > 0)) { showToast(false, 'Please enter a valid Price.'); $('#fPrice').trigger('focus'); return; }
    var amt = recalc(), b = available();
    if (b && amt > b.avail) { showToast(false, $('#overWarn').text()); return; }
    var file = $('#fFile')[0].files[0];
    if (file) {
      if (!/\.(pdf|jpe?g|png)$/i.test(file.name)) { showToast(false, 'Invoice copy must be a PDF, JPG or PNG file.'); return; }
      if (file.size > 10 * 1024 * 1024) { showToast(false, 'The invoice copy is too large (maximum 10 MB).'); return; }
    }

    var $btn = $('#btnSave'), label = $btn.text();
    $btn.prop('disabled', true).text('Saving...');
    $.ajax({
      url: 'CsrInvoiceServlet', type: 'POST', dataType: 'json',
      data: new FormData(this), processData: false, contentType: false
    }).done(function (res) {
      if (!res.ok) { showToast(false, res.message); $btn.prop('disabled', false).text(label); return; }
      window.location.href = 'CsrInvoiceServlet?msg=' + encodeURIComponent(res.message) + '&hl=' + res.id;
    }).fail(function (xhr) {
      showToast(false, (xhr.responseJSON && xhr.responseJSON.message) ? xhr.responseJSON.message : 'Could not save. Please try again.');
      $btn.prop('disabled', false).text(label);
    });
  });
});
</script>

</body>
</html>
