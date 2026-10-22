<%
    // Must be opened through CsrFundServlet (loads data + checks Global role)
    if (request.getAttribute("rows") == null) {
        response.sendRedirect("CsrFundServlet");
        return;
    }
    com.google.gson.Gson gson = new com.google.gson.Gson();   // escapes < > & : safe inside <script>
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>KSS CSR Fund Receipts</title>

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
      <div class="csr-subtitle">KSS CSR Amount Spending &rsaquo; Approval Letters</div>
      <h1 class="csr-title">Fund Receipts</h1>
    </div>
    <div class="csr-stats">
      <div class="csr-stat"><div class="csr-stat-label">Receipts</div><div class="csr-stat-value" id="statCount">0</div></div>
      <div class="csr-stat"><div class="csr-stat-label" id="statApprLabel">Approved</div><div class="csr-stat-value" id="statApproved">-</div></div>
      <div class="csr-stat"><div class="csr-stat-label">Received</div><div class="csr-stat-value" id="statReceived">-</div></div>
      <div class="csr-stat"><div class="csr-stat-label">Pending</div><div class="csr-stat-value" id="statPending">-</div></div>
    </div>
  </div>

  <div id="csrError" class="csr-alert csr-alert-err" style="display:none;"></div>
  <div id="csrToast" class="csr-alert" style="display:none;"></div>

  <div class="csr-card">
    <div class="csr-card-head">
      <div class="csr-card-title">Funds Received <small id="listCount"></small></div>
      <div class="csr-controls">
        <select id="letterFilter"><option value="ALL">All Approval Letters</option></select>
        <input type="text" id="searchBox" placeholder="Search letter / reference / bank">
        <a href="CsrFundServlet?action=form" class="csr-btn csr-link-btn" id="btnNew">+ New Fund Receipt</a>
      </div>
    </div>
    <div class="csr-table-wrap">
      <table class="csr-table">
        <thead>
          <tr>
            <th>#</th>
            <th>Receipt Date</th>
            <th>Approval Letter</th>
            <th class="csr-num">Amount</th>
            <th>Mode / Reference</th>
            <th>Bank</th>
            <th>Remarks</th>
            <th>Attachment</th>
            <th>Added</th>
            <th>Action</th>
          </tr>
        </thead>
        <tbody id="fundBody"></tbody>
        <tfoot>
          <tr class="csr-total-row" id="totalRow">
            <td colspan="3">Total (shown)</td>
            <td class="csr-num" id="sumAmount">-</td>
            <td colspan="6"></td>
          </tr>
        </tfoot>
      </table>
    </div>
  </div>
</div>

<script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
<script>
$(function () {
  var rows      = <%= gson.toJson(request.getAttribute("rows")) %>;
  var letters   = <%= gson.toJson(request.getAttribute("letters")) %>;
  var preset    = <%= gson.toJson(request.getAttribute("letterFilter")) %>;
  var loadError = <%= gson.toJson(request.getAttribute("error")) %>;
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

  letters.forEach(function (l) {
    $('#letterFilter').append($('<option></option>').attr('value', l.id).text(l.letterNumber + ' - ' + l.letterName));
  });
  if (preset && byId(letters, preset) !== -1) $('#letterFilter').val(preset);

  function rowHtml(r, n) {
    var $tr = $('<tr class="csr-row fund-row"></tr>').attr('data-id', r.id);
    $tr.append($('<td></td>').text(n));
    $tr.append($('<td class="csr-strong"></td>').text(r.receiptDateTxt));
    $tr.append($('<td></td>')
      .append($('<div class="csr-strong"></div>').text(r.letterNumber))
      .append($('<div class="csr-small"></div>').text(r.letterName)));
    $tr.append($('<td class="csr-num csr-strong"></td>').text(money(r.amount)));
    $tr.append($('<td></td>')
      .append($('<div></div>').text(r.paymentMode))
      .append($('<div class="csr-small"></div>').text(r.referenceNo || '')));
    $tr.append($('<td></td>').text(r.bankName || '-'));
    $tr.append($('<td class="csr-small"></td>').text(r.remarks || ''));
    var $a = $('<td></td>');
    if (r.attachmentSize) {
      $a.append($('<a class="csr-pdf" target="_blank"></a>').attr('href', 'CsrFundServlet?action=file&id=' + r.id).html('&#128206; View'))
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
        .append($('<a class="csr-btn csr-btn-sm csr-btn-outline csr-link-btn">&#9998; Edit</a>').attr('href', 'CsrFundServlet?action=form&id=' + r.id))
        .append('<button type="button" class="csr-btn csr-btn-sm csr-btn-bad js-del">Delete</button>')));
    return $tr;
  }

  function render() {
    var lf = $('#letterFilter').val(), q = $.trim($('#searchBox').val()).toLowerCase();
    var $body = $('#fundBody').empty(), n = 0, sa = 0;
    rows.forEach(function (r) {
      var hay = [r.letterNumber, r.letterName, r.referenceNo, r.bankName, r.paymentMode, r.remarks].join(' ').toLowerCase();
      if ((lf === 'ALL' || String(r.letterId) === String(lf)) && (q === '' || hay.indexOf(q) !== -1)) {
        $body.append(rowHtml(r, ++n));
        sa += Number(r.amount);
      }
    });
    if (n === 0) {
      $body.append('<tr><td colspan="10" class="csr-empty">' + (rows.length ? 'No receipts match the filter.'
        : 'No fund receipts yet. Click <b>+ New Fund Receipt</b> to add the first one.') + '</td></tr>');
    }
    $('#sumAmount').text(money(sa));
    $('#totalRow').toggle(n > 0);
    $('#listCount').text('(' + n + (n !== rows.length ? ' of ' + rows.length : '') + ')');

    var approved = 0, received = 0;
    letters.forEach(function (l) {
      if (lf === 'ALL' || String(l.id) === String(lf)) { approved += Number(l.amount); received += Number(l.received); }
    });
    $('#statCount').text(n);
    $('#statApprLabel').text(lf === 'ALL' ? 'Approved (all)' : 'Approved');
    $('#statApproved').text(money(approved));
    $('#statReceived').text(money(received));
    $('#statPending').text(money(approved - received)).toggleClass('csr-neg', approved - received < 0);
    $('#btnNew').attr('href', 'CsrFundServlet?action=form' + (lf !== 'ALL' ? '&letterId=' + lf : ''));
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
    $.ajax({ url: 'CsrFundServlet', type: 'POST', dataType: 'json', data: { action: 'delete', id: id }
    }).done(function (res) {
      if (!res.ok) { showToast(false, res.message); render(); return; }
      var i = byId(rows, id);
      if (i !== -1) {
        var li = byId(letters, rows[i].letterId);
        if (li !== -1) letters[li].received = (Number(letters[li].received) - Number(rows[i].amount)).toFixed(2);
        rows.splice(i, 1);
      }
      render();
      showToast(true, res.message);
    }).fail(function (xhr) {
      showToast(false, (xhr.responseJSON && xhr.responseJSON.message) ? xhr.responseJSON.message : 'Could not delete. Please try again.');
      render();
    });
  });

  $('#letterFilter').on('change', render);
  $('#searchBox').on('input keyup', render);
  render();

  var params = new URLSearchParams(window.location.search);
  if (params.get('msg')) {
    showToast(true, params.get('msg'));
    var $tr = $('tr.fund-row[data-id="' + (params.get('hl') || '').replace(/\D/g, '') + '"]').addClass('csr-flash');
    setTimeout(function () { $tr.removeClass('csr-flash'); }, 1500);
    if (window.history.replaceState) window.history.replaceState(null, '', 'CsrFundServlet');
  }
});
</script>

</body>
</html>
