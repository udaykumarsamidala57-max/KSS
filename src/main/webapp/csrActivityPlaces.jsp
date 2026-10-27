<%@page import="java.util.List"%>
<%@page import="java.util.Map"%>
<%
    // Must be opened through CsrActivityPlaceServlet (loads data + checks Global role)
    @SuppressWarnings("unchecked")
    List<Map<String, String>> rows = (List<Map<String, String>>) request.getAttribute("rows");
    if (rows == null) {
        response.sendRedirect("CsrActivityPlaceServlet");
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
<title><%= com.Bean.AppConfig.code() %> CSR Activities &amp; Places</title>

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
      <h1 class="csr-title">CSR Activities &amp; Places</h1>
    </div>
    <div class="csr-stats">
      <div class="csr-stat"><div class="csr-stat-label">Kinds of Activity</div><div class="csr-stat-value" id="statAct">0</div></div>
      <div class="csr-stat"><div class="csr-stat-label">Places</div><div class="csr-stat-value" id="statPlace">0</div></div>
    </div>
  </div>

  <div id="csrError" class="csr-alert csr-alert-err" style="display:none;"></div>
  <div id="csrToast" class="csr-alert" style="display:none;"></div>

  <div class="csr-card">
    <div class="csr-card-head">
      <div class="csr-card-title">Entries <small id="listCount"></small></div>
      <div class="csr-controls">
        <select id="kindFilter">
          <option value="ALL">All types</option>
          <option value="Activity">Kind of CSR Activity</option>
          <option value="Place">Place</option>
        </select>
        <select id="statusFilter">
          <option value="ALL">All</option>
          <option value="Active">Active</option>
          <option value="Inactive">Inactive</option>
        </select>
        <input type="text" id="searchBox" placeholder="Search name">
        <a href="CsrActivityPlaceServlet?action=form&amp;kind=Activity" class="csr-btn csr-link-btn">+ New Activity</a>
        <a href="CsrActivityPlaceServlet?action=form&amp;kind=Place" class="csr-btn csr-link-btn">+ New Place</a>
      </div>
    </div>
    <div class="csr-table-wrap">
      <table class="csr-table">
        <thead>
          <tr>
            <th>#</th>
            <th>Type</th>
            <th>Name</th>
            <th>Status</th>
            <th class="csr-num">Approvals</th>
            <th class="csr-num">Sanctioned</th>
            <th>Last Updated</th>
            <th>Action</th>
          </tr>
        </thead>
        <tbody id="csrBody"></tbody>
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
  var LABEL = { Activity: 'Kind of CSR Activity', Place: 'Place' };

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
    var used = parseInt(r.letterCount, 10) || 0;
    var $tr = $('<tr class="csr-row"></tr>').attr('data-id', r.id);
    $tr.append($('<td></td>').text(n));
    $tr.append($('<td></td>').text(LABEL[r.kind] || r.kind));
    $tr.append($('<td class="csr-strong"></td>').text(r.name));
    $tr.append($('<td></td>').append($('<span class="csr-badge"></span>').text(r.status)
      .css(r.status === 'Active' ? { color: '#047857', background: '#ecfdf5', borderColor: '#a7f3d0' }
                                 : { color: '#64748b', background: '#f8fafc', borderColor: '#e2e8f0' })));
    $tr.append($('<td class="csr-num"></td>').text(used));
    $tr.append($('<td class="csr-num"></td>').text(money(r.sanctioned)));
    $tr.append($('<td></td>')
      .append($('<div></div>').text(r.updatedAt || r.createdAt || '-'))
      .append($('<div class="csr-small"></div>').text(r.updatedBy || r.createdBy || '')));
    var $act = $('<div class="csr-actions"></div>')
      .append($('<a class="csr-btn csr-btn-sm csr-btn-outline csr-link-btn">&#9998; Edit</a>').attr('href', 'CsrActivityPlaceServlet?action=form&id=' + r.id));
    if (!used) $act.append('<button type="button" class="csr-btn csr-btn-sm csr-btn-bad js-del">Delete</button>');
    $tr.append($('<td></td>').append($act));
    return $tr;
  }

  function render() {
    var kd = $('#kindFilter').val(), st = $('#statusFilter').val(), q = $.trim($('#searchBox').val()).toLowerCase();
    var $body = $('#csrBody').empty(), n = 0, a = 0, p = 0;
    rows.forEach(function (r) {
      if (r.kind === 'Activity') a++; else p++;
      if ((kd === 'ALL' || r.kind === kd) && (st === 'ALL' || r.status === st)
          && (q === '' || String(r.name).toLowerCase().indexOf(q) !== -1)) {
        $body.append(rowHtml(r, ++n));
      }
    });
    if (n === 0) {
      $body.append('<tr><td colspan="8" class="csr-empty">' + (rows.length ? 'No entries match the filter.'
        : 'No entries yet. Click <b>+ New Activity</b> or <b>+ New Place</b> to add the first one.') + '</td></tr>');
    }
    $('#statAct').text(a);
    $('#statPlace').text(p);
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
    $.ajax({ url: 'CsrActivityPlaceServlet', type: 'POST', dataType: 'json', data: { action: 'delete', id: id }
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

  $('#kindFilter, #statusFilter').on('change', render);
  $('#searchBox').on('input keyup', render);
  render();

  var params = new URLSearchParams(window.location.search);
  if (params.get('msg')) {
    showToast(true, params.get('msg'));
    var $tr = $('tr.csr-row[data-id="' + (params.get('hl') || '').replace(/\D/g, '') + '"]').addClass('csr-flash');
    setTimeout(function () { $tr.removeClass('csr-flash'); }, 1500);
    if (window.history.replaceState) window.history.replaceState(null, '', 'CsrActivityPlaceServlet');
  }
});
</script>

</body>
</html>
