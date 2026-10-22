<%@page import="java.util.List"%>
<%@page import="java.util.Map"%>
<%
    // Must be opened through CsrLetterServlet (loads data + checks Global role)
    @SuppressWarnings("unchecked")
    List<Map<String, String>> rows = (List<Map<String, String>>) request.getAttribute("rows");
    if (rows == null) {
        response.sendRedirect("CsrLetterServlet");
        return;
    }
    String loadError = (String) request.getAttribute("error");
    com.google.gson.Gson gson = new com.google.gson.Gson();   // escapes < > & : safe inside <script>
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>KSS CSR Approval Letters</title>

<!-- INCLUDE SHARED HEADER & MENU -->
<%@ include file="header.jsp" %>

<%-- CSS is included inline: ScholarshipListServelt is mapped to "/" and would intercept a separate .css request --%>
<style>
<%@ include file="css/csrLetter.css" %>
</style>
</head>
<body>

<div class="csr-page">

  <div class="csr-header">
    <div>
      <div class="csr-subtitle">KSS CSR Amount Spending</div>
      <h1 class="csr-title">Approval Letters</h1>
    </div>
    <div class="csr-stats">
      <div class="csr-stat"><div class="csr-stat-label">Letters</div><div class="csr-stat-value" id="statCount">0</div></div>
      <div class="csr-stat"><div class="csr-stat-label">Total Approved</div><div class="csr-stat-value" id="statTotal">-</div></div>
    </div>
  </div>

  <div id="csrError" class="csr-alert csr-alert-err" style="display:none;"></div>
  <div id="csrToast" class="csr-alert" style="display:none;"></div>

  <div class="csr-card">
    <div class="csr-card-head">
      <div class="csr-card-title">Approval Letters <small id="listCount"></small></div>
      <div class="csr-controls">
        <select id="kindFilter"><option value="ALL">All Activities</option></select>
        <input type="text" id="searchBox" placeholder="Search letter no / name / place">
        <a href="CsrLetterServlet?action=form" class="csr-btn csr-link-btn">+ New Approval Letter</a>
      </div>
    </div>
    <div class="csr-table-wrap">
      <table class="csr-table">
        <thead>
          <tr>
            <th>#</th>
            <th>Letter No / Name</th>
            <th>Kind of CSR Activity</th>
            <th>Place</th>
            <th>Particulars</th>
            <th class="csr-num">Amount</th>
            <th>PDF</th>
            <th>Funds Received</th>
            <th>Work Orders</th>
            <th>Added</th>
            <th>Action</th>
          </tr>
        </thead>
        <tbody id="csrBody"></tbody>
        <tfoot>
          <tr class="csr-total-row" id="totalRow">
            <td colspan="5">Total (shown)</td>
            <td class="csr-num" id="totalShown">-</td>
            <td colspan="5"></td>
          </tr>
        </tfoot>
      </table>
    </div>
  </div>
</div>

<script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
<script>
$(function () {
  var rows = <%= gson.toJson(rows) %>;
  var loadError = <%= gson.toJson(loadError) %>;
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
    $t.data('timer', setTimeout(function () { $t.fadeOut(300); }, 4000));
  }
  function byId(id) { for (var i = 0; i < rows.length; i++) if (String(rows[i].id) === String(id)) return i; return -1; }

  function rowHtml(r, n) {
    var $tr = $('<tr class="csr-row"></tr>').attr('data-id', r.id);
    $tr.append($('<td></td>').text(n));
    $tr.append($('<td></td>')
      .append($('<div class="csr-strong"></div>').text(r.letterNumber))
      .append($('<div class="csr-small"></div>').text(r.letterName)));
    $tr.append($('<td></td>').append($('<span class="csr-badge"></span>').text(r.activityKind)));
    $tr.append($('<td></td>').text(r.place));
    $tr.append($('<td class="csr-particulars"></td>').text(r.particulars || ''));
    $tr.append($('<td class="csr-num csr-strong"></td>').text(money(r.amount)));
    var $pdf = $('<td></td>');
    if (r.pdfSize) {
      $pdf.append($('<a class="csr-pdf" target="_blank"></a>').attr('href', 'CsrLetterServlet?action=pdf&id=' + r.id).html('&#128196; View'))
          .append($('<div class="csr-small"></div>').text(kb(r.pdfSize)));
    } else {
      $pdf.append('<span class="csr-small">No PDF</span>');
    }
    $tr.append($pdf);
    var fundCount = parseInt(r.fundCount, 10) || 0, pend = Number(r.amount) - Number(r.fundTotal || 0);
    var $fd = $('<td class="csr-wo-cell"></td>');
    if (fundCount) {
      $fd.append($('<a class="csr-strong" style="color:inherit"></a>').attr('href', 'CsrFundServlet?letterId=' + r.id)
                   .text(fundCount + ' receipt' + (fundCount === 1 ? '' : 's') + ': ' + money(r.fundTotal)));
    } else {
      $fd.append('<div class="csr-small">No funds received</div>');
    }
    $fd.append($('<div class="csr-small"></div>').append('Pending ').append($('<b></b>').text(money(pend)).toggleClass('csr-neg', pend < 0)));
    $tr.append($fd);
    var woCount = parseInt(r.woCount, 10) || 0, bal = Number(r.amount) - Number(r.woTotal || 0);
    var $wo = $('<td class="csr-wo-cell"></td>');
    if (woCount) {
      $wo.append($('<a class="csr-strong" style="color:inherit"></a>').attr('href', 'CsrWorkOrderServlet?letterId=' + r.id)
                   .text(woCount + ' WO' + (woCount === 1 ? '' : 's') + ': ' + money(r.woTotal)));
    } else {
      $wo.append('<div class="csr-small">No work orders</div>');
    }
    $wo.append($('<div class="csr-small"></div>').append('Balance ').append($('<b></b>').text(money(bal)).toggleClass('csr-neg', bal < 0)));
    $tr.append($wo);
    $tr.append($('<td></td>')
      .append($('<div></div>').text(r.createdAt || ''))
      .append($('<div class="csr-small"></div>').text(r.createdBy ? 'by ' + r.createdBy : '')));
    $tr.append($('<td></td>').append(
      $('<div class="csr-actions"></div>')
        .append($('<a class="csr-btn csr-btn-sm csr-link-btn">+ Fund</a>').attr('href', 'CsrFundServlet?action=form&letterId=' + r.id).attr('title', 'Record funds received against this letter'))
        .append($('<a class="csr-btn csr-btn-sm csr-link-btn">+ WO</a>').attr('href', 'CsrWorkOrderServlet?action=form&letterId=' + r.id).attr('title', 'New work order against this letter'))
        .append($('<a class="csr-btn csr-btn-sm csr-btn-outline csr-link-btn">&#9998; Edit</a>').attr('href', 'CsrLetterServlet?action=form&id=' + r.id))
        .append('<button type="button" class="csr-btn csr-btn-sm csr-btn-bad js-del">Delete</button>')));
    return $tr;
  }

  function render() {
    var kind = $('#kindFilter').val(), q = $.trim($('#searchBox').val()).toLowerCase();
    var $body = $('#csrBody').empty(), n = 0, shownTotal = 0, allTotal = 0;
    rows.forEach(function (r) {
      allTotal += Number(r.amount || 0);
      var hay = [r.letterNumber, r.letterName, r.place, r.activityKind, r.particulars].join(' ').toLowerCase();
      if ((kind === 'ALL' || r.activityKind === kind) && (q === '' || hay.indexOf(q) !== -1)) {
        $body.append(rowHtml(r, ++n));
        shownTotal += Number(r.amount || 0);
      }
    });
    if (n === 0) {
      $body.append('<tr><td colspan="11" class="csr-empty">' + (rows.length ? 'No letters match the filter.'
        : 'No approval letters yet. Click <b>+ New Approval Letter</b> to add the first one.') + '</td></tr>');
    }
    $('#totalShown').text(money(shownTotal));
    $('#totalRow').toggle(n > 0);
    $('#statCount').text(rows.length);
    $('#statTotal').text(money(allTotal));
    $('#listCount').text('(' + n + (n !== rows.length ? ' of ' + rows.length : '') + ')');
  }

  function refreshKinds() {
    var current = $('#kindFilter').val() || 'ALL', used = [];
    rows.forEach(function (r) { if (r.activityKind && used.indexOf(r.activityKind) === -1) used.push(r.activityKind); });
    used.sort();
    var $f = $('#kindFilter').empty().append('<option value="ALL">All Activities</option>');
    used.forEach(function (k) { $f.append($('<option></option>').attr('value', k).text(k)); });
    $f.val(used.indexOf(current) !== -1 ? current : 'ALL');
  }

  // Delete (inline confirm, AJAX)
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
    $.ajax({ url: 'CsrLetterServlet', type: 'POST', dataType: 'json', data: { action: 'delete', id: id }
    }).done(function (res) {
      if (!res.ok) { showToast(false, res.message); render(); return; }
      var i = byId(id); if (i !== -1) rows.splice(i, 1);
      refreshKinds(); render();
      showToast(true, res.message);
    }).fail(function (xhr) {
      showToast(false, (xhr.responseJSON && xhr.responseJSON.message) ? xhr.responseJSON.message : 'Could not delete. Please try again.');
      render();
    });
  });

  $('#kindFilter').on('change', render);
  $('#searchBox').on('input keyup', render);

  refreshKinds();
  render();

  // Message after saving on the form page (?msg=...&hl=id)
  var params = new URLSearchParams(window.location.search);
  if (params.get('msg')) {
    showToast(true, params.get('msg'));
    var $tr = $('tr.csr-row[data-id="' + (params.get('hl') || '').replace(/\D/g, '') + '"]').addClass('csr-flash');
    setTimeout(function () { $tr.removeClass('csr-flash'); }, 1500);
    if (window.history.replaceState) window.history.replaceState(null, '', 'CsrLetterServlet');
  }
});
</script>

</body>
</html>
