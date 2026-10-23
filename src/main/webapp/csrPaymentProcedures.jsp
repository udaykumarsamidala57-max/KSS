<%
    if (request.getAttribute("procedures") == null) {
        response.sendRedirect("CsrPaymentProcedureServlet");
        return;
    }
    com.google.gson.Gson gson = new com.google.gson.Gson();
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Payment Procedures</title>
<%@ include file="header.jsp" %>
<style>
<%@ include file="css/csrLetter.css" %>
</style>
<style>
<%@ include file="css/finance.css" %>
</style>
</head>
<body>

<div class="csr-page">

  <div class="csr-header">
    <div>
      <div class="csr-subtitle">KSS CSR Amount Spending &rsaquo; Step 3</div>
      <h1 class="csr-title">Payment Procedures</h1>
    </div>
    <div class="csr-stats">
      <div class="csr-stat"><div class="csr-stat-label">Procedures</div><div class="csr-stat-value" id="statCount">0</div></div>
      <div class="csr-stat"><div class="csr-stat-label">Total Deductions</div><div class="csr-stat-value" id="statDeductions">-</div></div>
    </div>
  </div>

  <div id="csrError" class="csr-alert csr-alert-err" style="display:none;"></div>
  <div id="csrToast" class="csr-alert" style="display:none;"></div>

  <div class="csr-card">
    <div class="csr-card-head">
      <div class="csr-card-title">Payment Procedures <small id="listCount"></small></div>
      <div class="csr-controls">
        <select id="invoiceFilter"><option value="ALL">All Invoices</option></select>
        <a href="CsrInvoiceServlet" class="csr-btn csr-btn-outline csr-link-btn">&#8592; Back to Invoices</a>
        <a href="CsrPaymentProcedureServlet?action=form" class="csr-btn csr-link-btn" id="btnNew">+ New Procedure</a>
      </div>
    </div>
    <div class="csr-table-wrap">
      <table class="csr-table">
        <thead>
          <tr>
            <th>#</th>
            <th>Invoice / Date</th>
            <th>Payment Date</th>
            <th class="csr-num">Debit Note</th>
            <th class="csr-num">TDS</th>
            <th class="csr-num">Retention</th>
            <th class="csr-num">Advance Paid</th>
            <th class="csr-num csr-strong">Total Deductions</th>
            <th>Added</th>
            <th>Action</th>
          </tr>
        </thead>
        <tbody id="ppBody"></tbody>
        <tfoot>
          <tr class="csr-total-row" id="totalRow">
            <td colspan="3">Total (shown)</td>
            <td class="csr-num" id="sumDebit">-</td>
            <td class="csr-num" id="sumTds">-</td>
            <td class="csr-num" id="sumRetention">-</td>
            <td class="csr-num" id="sumAdvance">-</td>
            <td class="csr-num csr-strong" id="sumTotal">-</td>
            <td colspan="2"></td>
          </tr>
        </tfoot>
      </table>
    </div>
  </div>
</div>

<script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
<script>
$(function () {
  var procedures   = <%= gson.toJson(request.getAttribute("procedures")) %>;
  var taxInvoices  = <%= gson.toJson(request.getAttribute("taxInvoices")) %>;
  var preset       = <%= gson.toJson(request.getAttribute("invoiceFilter")) %>;
  var loadError    = <%= gson.toJson(request.getAttribute("error")) %>;
  var RS = String.fromCharCode(8377);

  if (loadError) $('#csrError').text(loadError).show();

  function money(v) {
    return RS + ' ' + Number(v || 0).toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  }
  function showToast(ok, text) {
    var $t = $('#csrToast');
    $t.removeClass('csr-alert-ok csr-alert-err').addClass(ok ? 'csr-alert-ok' : 'csr-alert-err').text(text).stop(true, true).fadeIn(150);
    clearTimeout($t.data('timer'));
    $t.data('timer', setTimeout(function () { $t.fadeOut(300); }, 4500));
  }
  function byId(list, id) { for (var i = 0; i < list.length; i++) if (String(list[i].id) === String(id)) return i; return -1; }

  var $invFilter = $('#invoiceFilter');
  taxInvoices.forEach(function (inv) {
    $invFilter.append($('<option></option>').attr('value', inv.id).text(inv.invoiceNumber + ' - ' + inv.vendorName));
  });
  if (preset && byId(taxInvoices, preset) !== -1) $invFilter.val(preset);

  function rowHtml(p, n) {
    var $tr = $('<tr class="csr-row pp-row"></tr>').attr('data-id', p.id);
    $tr.append($('<td></td>').text(n));
    $tr.append($('<td></td>')
      .append($('<div class="csr-strong"></div>').text(p.invoiceNumber))
      .append($('<div class="csr-small"></div>').text(p.invoiceAmount ? money(p.invoiceAmount) : '-')));
    $tr.append($('<td></td>').text(p.paymentDateTxt || '-'));
    $tr.append($('<td class="csr-num"></td>').text(Number(p.debitNoteAmount) > 0 ? money(p.debitNoteAmount) : '-')
      .append($('<div class="csr-small"></div>').text(p.debitNoteDescription || '')));
    $tr.append($('<td class="csr-num"></td>').text(Number(p.tdsAmount) > 0 ? money(p.tdsAmount) : '-'));
    $tr.append($('<td class="csr-num"></td>').text(Number(p.retentionAmount) > 0 ? money(p.retentionAmount) : '-'));
    $tr.append($('<td class="csr-num"></td>').text(Number(p.advancePaid) > 0 ? money(p.advancePaid) : '-'));
    $tr.append($('<td class="csr-num csr-strong"></td>').text(money(p.totalDeductions)));
    $tr.append($('<td></td>')
      .append($('<div></div>').text(p.createdAt || ''))
      .append($('<div class="csr-small"></div>').text(p.createdBy ? 'by ' + p.createdBy : '')));
    $tr.append($('<td></td>').append(
      $('<div class="csr-actions"></div>')
        .append($('<a class="csr-btn csr-btn-sm csr-btn-outline csr-link-btn">&#9998; Edit</a>').attr('href', 'CsrPaymentProcedureServlet?action=form&id=' + p.id))
        .append('<button type="button" class="csr-btn csr-btn-sm csr-btn-bad js-del">Delete</button>')));
    return $tr;
  }

  function render() {
    var invF = $('#invoiceFilter').val();
    var $body = $('#ppBody').empty(), n = 0, sdb = 0, stds = 0, sret = 0, sadv = 0, stot = 0;
    procedures.forEach(function (p) {
      if (invF !== 'ALL' && String(p.invoiceId) !== String(invF)) return;
      $body.append(rowHtml(p, ++n));
      sdb += Number(p.debitNoteAmount);
      stds += Number(p.tdsAmount);
      sret += Number(p.retentionAmount);
      sadv += Number(p.advancePaid);
      stot += Number(p.totalDeductions);
    });
    if (n === 0) {
      $body.append('<tr><td colspan="11" class="csr-empty">' + (procedures.length ? 'No procedures match the filter.'
        : 'No payment procedures yet. Click <b>+ New Procedure</b> to add the first one.') + '</td></tr>');
    }
    $('#sumDebit').text(money(sdb)); $('#sumTds').text(money(stds)); $('#sumRetention').text(money(sret));
    $('#sumAdvance').text(money(sadv)); $('#sumTotal').text(money(stot));
    $('#totalRow').toggle(n > 0);
    $('#listCount').text('(' + n + (n !== procedures.length ? ' of ' + procedures.length : '') + ')');
    $('#statCount').text(n);
    $('#statDeductions').text(money(stot));
    $('#btnNew').attr('href', 'CsrPaymentProcedureServlet?action=form' + (invF !== 'ALL' ? '&invoiceId=' + invF : ''));
  }

  // delete
  $(document).on('click', '.js-del', function () {
    $(this).closest('.csr-actions').empty()
      .append('<span class="csr-confirm">Delete?</span>')
      .append('<button type="button" class="csr-btn csr-btn-sm csr-btn-bad js-del-yes">Yes</button>')
      .append('<button type="button" class="csr-btn csr-btn-sm csr-btn-outline js-del-no">No</button>');
  });
  $(document).on('click', '.js-del-no', render);
  $(document).on('click', '.js-del-yes', function () {
    var $b = $(this), id = $b.closest('tr').attr('data-id');
    $b.prop('disabled', true).text('Deleting...');
    $.ajax({ url: 'CsrPaymentProcedureServlet', type: 'POST', dataType: 'json', data: { action: 'delete', id: id }
    }).done(function (res) {
      if (!res.ok) { showToast(false, res.message); render(); return; }
      procedures = procedures.filter(function (p) { return String(p.id) !== String(id); });
      showToast(true, res.message);
      render();
    }).fail(function (xhr) {
      showToast(false, (xhr.responseJSON && xhr.responseJSON.message) ? xhr.responseJSON.message : 'Could not delete.');
      render();
    });
  });

  $('#invoiceFilter').on('change', render);
  render();

  var params = new URLSearchParams(window.location.search);
  if (params.get('msg')) {
    showToast(true, params.get('msg'));
    var $tr = $('tr.pp-row[data-id="' + (params.get('hl') || '').replace(/\D/g, '') + '"]').addClass('csr-flash');
    setTimeout(function () { $tr.removeClass('csr-flash'); }, 1500);
    if (window.history.replaceState) window.history.replaceState(null, '', 'CsrPaymentProcedureServlet');
  }
});
</script>

</body>
</html>
