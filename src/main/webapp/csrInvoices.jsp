<%
    // Must be opened through CsrInvoiceServlet (loads data + checks Global role)
    if (request.getAttribute("rows") == null) {
        response.sendRedirect("CsrInvoiceServlet");
        return;
    }
    com.google.gson.Gson gson = new com.google.gson.Gson();   // escapes < > & : safe inside <script>
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>KSS CSR Invoices</title>

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

<div class="csr-page">

  <div class="csr-header">
    <div>
      <div class="csr-subtitle">KSS CSR Amount Spending &rsaquo; Step 3</div>
      <h1 class="csr-title">Invoices</h1>
    </div>
    <div class="csr-stats">
      <div class="csr-stat"><div class="csr-stat-label">Invoices</div><div class="csr-stat-value" id="statCount">0</div></div>
      <div class="csr-stat"><div class="csr-stat-label" id="statWoLabel">Work Order Total</div><div class="csr-stat-value" id="statWo">-</div></div>
      <div class="csr-stat"><div class="csr-stat-label">Billed (Tax Invoices)</div><div class="csr-stat-value" id="statInvoiced">-</div></div>
      <div class="csr-stat"><div class="csr-stat-label">Balance</div><div class="csr-stat-value" id="statBalance">-</div></div>
    </div>
  </div>

  <div id="csrError" class="csr-alert csr-alert-err" style="display:none;"></div>
  <div id="csrToast" class="csr-alert" style="display:none;"></div>

  <div class="csr-card">
    <div class="csr-card-head">
      <div class="csr-card-title">Invoices <small id="listCount"></small></div>
      <div class="csr-controls">
        <select id="typeFilter">
          <option value="ALL">All Types</option>
          <option value="Tax Invoice">Tax Invoices</option>
          <option value="Proforma">Proforma Invoices</option>
        </select>
        <select id="woFilter"><option value="ALL">All Work Orders</option></select>
        <input type="text" id="searchBox" placeholder="Search invoice no / WO / vendor">
        <a href="CsrLetterServlet" class="csr-btn csr-btn-outline csr-link-btn">&#8592; Back to Management Approvals</a>
        <a href="CsrInvoiceServlet?action=form" class="csr-btn csr-link-btn" id="btnNew">+ New Invoice</a>
      </div>
    </div>
    <div class="csr-table-wrap">
      <table class="csr-table">
        <thead>
          <tr>
            <th>#</th>
            <th>Type</th>
            <th>Invoice No / Date</th>
            <th>Work Order / Vendor</th>
            <th class="csr-num">Price</th>
            <th class="csr-num">GST</th>
            <th class="csr-num">Amount</th>
            <th>FRL</th>
            <th>Invoice Copy</th>
            <th>Added</th>
            <th>Action</th>
          </tr>
        </thead>
        <tbody id="invBody"></tbody>
        <tfoot>
          <tr class="csr-total-row" id="totalRow">
            <td colspan="4">Total (shown)</td>
            <td class="csr-num" id="sumPrice">-</td>
            <td class="csr-num" id="sumGst">-</td>
            <td class="csr-num" id="sumAmount">-</td>
            <td colspan="4"></td>
          </tr>
        </tfoot>
      </table>
    </div>
  </div>
</div>

<script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
<script>
$(function () {
  var rows       = <%= gson.toJson(request.getAttribute("rows")) %>;
  var workOrders = <%= gson.toJson(request.getAttribute("workOrders")) %>;
  var preset     = <%= gson.toJson(request.getAttribute("woFilter")) %>;
  var loadError  = <%= gson.toJson(request.getAttribute("error")) %>;
  var RS = String.fromCharCode(8377);

  if (loadError) $('#csrError').text(loadError).show();

  function money(v) {
    return RS + ' ' + Number(v || 0).toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  }
  function kb(bytes) {
    var n = parseInt(bytes, 10) || 0;
    return n >= 1048576 ? (n / 1048576).toFixed(1) + ' MB' : Math.max(1, Math.round(n / 1024)) + ' KB';
  }
  function showToast(ok, text) {
    var $t = $('#csrToast');
    $t.removeClass('csr-alert-ok csr-alert-err').addClass(ok ? 'csr-alert-ok' : 'csr-alert-err').text(text).stop(true, true).fadeIn(150);
    clearTimeout($t.data('timer'));
    $t.data('timer', setTimeout(function () { $t.fadeOut(300); }, 4500));
  }
  function byId(list, id) { for (var i = 0; i < list.length; i++) if (String(list[i].id) === String(id)) return i; return -1; }

  workOrders.forEach(function (w) {
    $('#woFilter').append($('<option></option>').attr('value', w.id).text(w.woNumber + ' - ' + w.vendorName));
  });
  if (preset && byId(workOrders, preset) !== -1) $('#woFilter').val(preset);

  function rowHtml(r, n) {
    var $tr = $('<tr class="csr-row inv-row"></tr>').attr('data-id', r.id);
    $tr.append($('<td></td>').text(n));
    var isPi = r.invoiceType === 'Proforma';
    var sub = isPi ? (r.settledByNumber ? 'Settled by ' + r.settledByNumber : 'Open proforma invoice')
                   : (r.proformaNumber ? 'Against proforma invoice ' + r.proformaNumber : '');
    $tr.append($('<td></td>').append($('<span class="csr-badge"></span>')
      .text(isPi ? 'Proforma Invoice' : 'Tax Invoice').toggleClass('csr-badge-pi', isPi))
      .append($('<div class="csr-small" style="margin-top:3px;"></div>').text(sub)));
    $tr.append($('<td></td>')
      .append($('<div class="csr-strong"></div>').text(r.invoiceNumber))
      .append($('<div class="csr-small"></div>').text(r.invoiceDateTxt)));
    $tr.append($('<td></td>')
      .append($('<div class="csr-strong"></div>').text(r.woNumber))
      .append($('<div class="csr-small"></div>').text(r.vendorName + ' | ' + r.letterNumber)));
    $tr.append($('<td class="csr-num"></td>').text(money(r.price)));
    $tr.append($('<td class="csr-num"></td>').append($('<div></div>').text(money(r.gstAmount)))
      .append($('<div class="csr-small"></div>').text(r.gst + ' %')));
    $tr.append($('<td class="csr-num csr-strong"></td>').text(money(r.amount)));
    var $f = $('<td></td>');
    if (r.frlId) {
      $f.append($('<a class="csr-strong" style="color:inherit"></a>').attr('href', 'CsrFrlServlet?letterId=' + r.letterId).text(r.frlNumber))
        .append($('<div class="csr-small"></div>').text('Claimed ' + money(r.claimAmount)));
    } else if (Number(r.claimable) > 0) {
      $f.append($('<a class="csr-btn csr-btn-sm csr-link-btn">+ FRL</a>')
        .attr('href', 'CsrFrlServlet?action=form&letterId=' + r.letterId + '&invoiceId=' + r.id)
        .attr('title', 'Raise a funds request letter for this invoice'));
      if (Number(r.claimable) !== Number(r.amount))
        $f.append($('<div class="csr-small"></div>').text('To claim ' + money(r.claimable)));
    } else {
      $f.append($('<span class="csr-small"></span>').text(isPi ? 'Settled, not claimed'
        : (r.frlRequired === '0' ? 'No FRL (received via proforma invoice)' : 'Covered by proforma invoice')));
    }
    $tr.append($f);
    var $a = $('<td></td>');
    if (r.attachmentSize) {
      $a.append($('<a class="csr-pdf" target="_blank"></a>').attr('href', 'CsrInvoiceServlet?action=file&id=' + r.id).html('&#128206; View'))
        .append($('<div class="csr-small"></div>').text(kb(r.attachmentSize)));
    } else {
      $a.append('<span class="csr-small">None</span>');
    }
    $tr.append($a);
    $tr.append($('<td></td>')
      .append($('<div></div>').text(r.createdAt || ''))
      .append($('<div class="csr-small"></div>').text(r.createdBy ? 'by ' + r.createdBy : '')));
    $tr.append($('<td></td>').append(
      $('<div class="csr-actions"></div>')
        .append($('<a class="csr-btn csr-btn-sm csr-btn-outline csr-link-btn">&#9998; Edit</a>').attr('href', 'CsrInvoiceServlet?action=form&id=' + r.id))
        .append('<button type="button" class="csr-btn csr-btn-sm csr-btn-bad js-del">Delete</button>')));
    return $tr;
  }

  function render() {
    var tf = $('#typeFilter').val(), wf = $('#woFilter').val(), q = $.trim($('#searchBox').val()).toLowerCase();
    var $body = $('#invBody').empty(), n = 0, sp = 0, sg = 0, sa = 0;
    rows.forEach(function (r) {
      var hay = [r.invoiceNumber, r.woNumber, r.vendorName, r.letterNumber, r.frlNumber].join(' ').toLowerCase();
      if ((tf === 'ALL' || (r.invoiceType || 'Tax Invoice') === tf) && (wf === 'ALL' || String(r.woId) === String(wf)) && (q === '' || hay.indexOf(q) !== -1)) {
        $body.append(rowHtml(r, ++n));
        sp += Number(r.price); sg += Number(r.gstAmount); sa += Number(r.amount);
      }
    });
    if (n === 0) {
      $body.append('<tr><td colspan="12" class="csr-empty">' + (rows.length ? 'No invoices match the filter.'
        : 'No invoices yet. Click <b>+ New Invoice</b> to add the first one.') + '</td></tr>');
    }
    $('#sumPrice').text(money(sp)); $('#sumGst').text(money(sg)); $('#sumAmount').text(money(sa));
    $('#totalRow').toggle(n > 0);
    $('#listCount').text('(' + n + (n !== rows.length ? ' of ' + rows.length : '') + ')');

    var woTotal = 0, invoiced = 0;
    workOrders.forEach(function (w) {
      if (wf === 'ALL' || String(w.id) === String(wf)) { woTotal += Number(w.total); invoiced += Number(w.invoiced); }
    });
    $('#statCount').text(n);
    $('#statWoLabel').text(wf === 'ALL' ? 'Work Order Total (all)' : 'Work Order Total');
    $('#statWo').text(money(woTotal));
    $('#statInvoiced').text(money(invoiced));
    $('#statBalance').text(money(woTotal - invoiced)).toggleClass('csr-neg', woTotal - invoiced < 0);
    $('#btnNew').attr('href', 'CsrInvoiceServlet?action=form' + (wf !== 'ALL' ? '&woId=' + wf : ''));
  }

  // delete (inline confirm, AJAX)
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
    $.ajax({ url: 'CsrInvoiceServlet', type: 'POST', dataType: 'json', data: { action: 'delete', id: id }
    }).done(function (res) {
      if (!res.ok) { showToast(false, res.message); render(); return; }
      // reload: deleting a tax invoice can re-open its proforma, so totals are taken fresh from the server
      window.location.href = 'CsrInvoiceServlet?msg=' + encodeURIComponent(res.message);
    }).fail(function (xhr) {
      showToast(false, (xhr.responseJSON && xhr.responseJSON.message) ? xhr.responseJSON.message : 'Could not delete. Please try again.');
      render();
    });
  });

  $('#woFilter, #typeFilter').on('change', render);
  $('#searchBox').on('input keyup', render);
  render();

  var params = new URLSearchParams(window.location.search);
  if (params.get('msg')) {
    showToast(true, params.get('msg'));
    var $tr = $('tr.inv-row[data-id="' + (params.get('hl') || '').replace(/\D/g, '') + '"]').addClass('csr-flash');
    setTimeout(function () { $tr.removeClass('csr-flash'); }, 1500);
    if (window.history.replaceState) window.history.replaceState(null, '', 'CsrInvoiceServlet');
  }
});
</script>

</body>
</html>
