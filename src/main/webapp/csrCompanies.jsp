<%@page import="java.util.List"%>
<%@page import="java.util.Map"%>
<%
    // Must be opened through CsrCompanyServlet (loads data + checks Global role)
    @SuppressWarnings("unchecked")
    List<Map<String, String>> rows = (List<Map<String, String>>) request.getAttribute("rows");
    if (rows == null) {
        response.sendRedirect("CsrCompanyServlet");
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
<title><%= com.Bean.AppConfig.code() %> CSR Companies</title>

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
      <div class="csr-subtitle"><%= com.Bean.AppConfig.code() %> CSR &middot; Masters</div>
      <h1 class="csr-title">Funding Companies</h1>
    </div>
    <div class="csr-stats">
      <div class="csr-stat"><div class="csr-stat-label">Companies</div><div class="csr-stat-value" id="statCount">0</div></div>
      <div class="csr-stat"><div class="csr-stat-label">Total Sanctioned</div><div class="csr-stat-value" id="statTotal">-</div></div>
    </div>
  </div>

  <div id="csrError" class="csr-alert csr-alert-err" style="display:none;"></div>
  <div id="csrToast" class="csr-alert" style="display:none;"></div>

  <div class="csr-card">
    <div class="csr-card-head">
      <div class="csr-card-title">Companies <small id="listCount"></small></div>
      <div class="csr-controls">
        <select id="statusFilter">
          <option value="ALL">All</option>
          <option value="Active">Active</option>
          <option value="Inactive">Inactive</option>
        </select>
        <input type="text" id="searchBox" placeholder="Search name / GSTIN / contact">
        <a href="CsrCompanyServlet?action=form" class="csr-btn csr-link-btn">+ New Company</a>
      </div>
    </div>
    <div class="csr-table-wrap">
      <table class="csr-table">
        <thead>
          <tr>
            <th>#</th>
            <th>Company</th>
            <th>GSTIN / PAN</th>
            <th>Contact</th>
            <th>Status</th>
            <th class="csr-num">Approvals</th>
            <th class="csr-num">Sanctioned</th>
            <th class="csr-num">Requested (FRLs)</th>
            <th class="csr-num">Received</th>
            <th class="csr-num">Yet to Receive</th>
            <th>Action</th>
          </tr>
        </thead>
        <tbody id="csrBody"></tbody>
        <tfoot>
          <tr class="csr-total-row" id="totalRow">
            <td colspan="5">Total (shown)</td>
            <td class="csr-num" id="tCount"></td>
            <td class="csr-num" id="tSan"></td>
            <td class="csr-num" id="tReq"></td>
            <td class="csr-num" id="tRec"></td>
            <td class="csr-num" id="tDue"></td>
            <td></td>
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
  function showToast(ok, text) {
    var $t = $('#csrToast');
    $t.removeClass('csr-alert-ok csr-alert-err').addClass(ok ? 'csr-alert-ok' : 'csr-alert-err').text(text).stop(true, true).fadeIn(150);
    clearTimeout($t.data('timer'));
    $t.data('timer', setTimeout(function () { $t.fadeOut(300); }, 4000));
  }
  function byId(id) { for (var i = 0; i < rows.length; i++) if (String(rows[i].id) === String(id)) return i; return -1; }

  function rowHtml(r, n) {
    var due = Number(r.requested) - Number(r.received), used = parseInt(r.letterCount, 10) || 0;
    var $tr = $('<tr class="csr-row"></tr>').attr('data-id', r.id);
    $tr.append($('<td></td>').text(n));
    $tr.append($('<td></td>')
      .append($('<div class="csr-strong"></div>').text(r.companyName))
      .append($('<div class="csr-small"></div>').text(r.shortName && r.shortName !== r.companyName ? 'Short name: ' + r.shortName : ''))
      .append($('<div class="csr-small"></div>').text(r.address || '')));
    $tr.append($('<td></td>')
      .append($('<div></div>').text(r.gstin || '-'))
      .append($('<div class="csr-small"></div>').text(r.pan ? 'PAN ' + r.pan : '')));
    $tr.append($('<td></td>')
      .append($('<div></div>').text(r.contactPerson || '-'))
      .append($('<div class="csr-small"></div>').text([r.phone, r.email].filter(Boolean).join(' | '))));
    $tr.append($('<td></td>').append($('<span class="csr-badge"></span>').text(r.status)
      .css(r.status === 'Active' ? { color: '#047857', background: '#ecfdf5', borderColor: '#a7f3d0' }
                                 : { color: '#64748b', background: '#f8fafc', borderColor: '#e2e8f0' })));
    $tr.append($('<td class="csr-num"></td>').append(used
      ? $('<a class="csr-open"></a>').attr('href', 'CsrLetterServlet?companyId=' + r.id).text(used) : $('<span></span>').text('0')));
    $tr.append($('<td class="csr-num csr-strong"></td>').text(money(r.sanctioned)));
    $tr.append($('<td class="csr-num"></td>').text(money(r.requested)));
    $tr.append($('<td class="csr-num"></td>').text(money(r.received)));
    $tr.append($('<td class="csr-num"></td>').text(money(due)).toggleClass('csr-neg', due < 0));
    var $act = $('<div class="csr-actions"></div>')
      .append($('<a class="csr-btn csr-btn-sm csr-btn-outline csr-link-btn">&#9998; Edit</a>').attr('href', 'CsrCompanyServlet?action=form&id=' + r.id));
    if (!used) $act.append('<button type="button" class="csr-btn csr-btn-sm csr-btn-bad js-del">Delete</button>');
    $tr.append($('<td></td>').append($act));
    return $tr;
  }

  function render() {
    var st = $('#statusFilter').val(), q = $.trim($('#searchBox').val()).toLowerCase();
    var $body = $('#csrBody').empty(), n = 0, t = { c: 0, s: 0, r: 0, e: 0 }, all = 0;
    rows.forEach(function (r) {
      all += Number(r.sanctioned || 0);
      var hay = [r.companyName, r.shortName, r.gstin, r.pan, r.contactPerson, r.phone, r.email].join(' ').toLowerCase();
      if ((st === 'ALL' || r.status === st) && (q === '' || hay.indexOf(q) !== -1)) {
        $body.append(rowHtml(r, ++n));
        t.c += parseInt(r.letterCount, 10) || 0; t.s += Number(r.sanctioned); t.r += Number(r.requested); t.e += Number(r.received);
      }
    });
    if (n === 0) {
      $body.append('<tr><td colspan="11" class="csr-empty">' + (rows.length ? 'No companies match the filter.'
        : 'No companies yet. Click <b>+ New Company</b> to add the first one.') + '</td></tr>');
    }
    $('#tCount').text(t.c); $('#tSan').text(money(t.s)); $('#tReq').text(money(t.r)); $('#tRec').text(money(t.e));
    $('#tDue').text(money(t.r - t.e));
    $('#totalRow').toggle(n > 0);
    $('#statCount').text(rows.length);
    $('#statTotal').text(money(all));
    $('#listCount').text('(' + n + (n !== rows.length ? ' of ' + rows.length : '') + ')');
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
    $.ajax({ url: 'CsrCompanyServlet', type: 'POST', dataType: 'json', data: { action: 'delete', id: id }
    }).done(function (res) {
      if (!res.ok) { showToast(false, res.message); render(); return; }
      var i = byId(id); if (i !== -1) rows.splice(i, 1);
      render();
      showToast(true, res.message);
    }).fail(function (xhr) {
      showToast(false, (xhr.responseJSON && xhr.responseJSON.message) ? xhr.responseJSON.message : 'Could not delete. Please try again.');
      render();
    });
  });

  $('#statusFilter').on('change', render);
  $('#searchBox').on('input keyup', render);
  render();

  var params = new URLSearchParams(window.location.search);
  if (params.get('msg')) {
    showToast(true, params.get('msg'));
    var $tr = $('tr.csr-row[data-id="' + (params.get('hl') || '').replace(/\D/g, '') + '"]').addClass('csr-flash');
    setTimeout(function () { $tr.removeClass('csr-flash'); }, 1500);
    if (window.history.replaceState) window.history.replaceState(null, '', 'CsrCompanyServlet');
  }
});
</script>

</body>
</html>
