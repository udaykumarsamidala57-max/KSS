<%@page import="java.util.List"%>
<%@page import="java.util.Map"%>
<%!
    private static String esc(String s) {
        if (s == null) return "";
        StringBuilder b = new StringBuilder(s.length());
        for (char c : s.toCharArray()) {
            switch (c) {
                case '<': b.append("&lt;"); break;
                case '>': b.append("&gt;"); break;
                case '&': b.append("&amp;"); break;
                case '"': b.append("&quot;"); break;
                case '\'': b.append("&#39;"); break;
                default: b.append(c);
            }
        }
        return b.toString();
    }
%>
<%
    // Must be opened through KssCourseMasterServlet (loads data + checks Global role)
    @SuppressWarnings("unchecked")
    List<Map<String, String>> rows = (List<Map<String, String>>) request.getAttribute("rows");
    if (rows == null) {
        response.sendRedirect("KssCourseMasterServlet");
        return;
    }
    String loadError = (String) request.getAttribute("error");
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>KSS Course Master</title>

<!-- INCLUDE SHARED HEADER & MENU -->
<%@ include file="header.jsp" %>

<style>

  :root {
    --brand-primary: #0f766e;
    --brand-primary-dark: #115e59;
    --brand-accent-bg: #f0fdfa;
    --brand-border: #e2e8f0;
    --brand-border-dark: #cbd5e1;
    --text-main: #0f172a;
    --text-muted: #64748b;
    --bg-page: #f1f5f9;
    --table-header-bg: #f8fafc;
    --row-hover: #f0fdfa;
    --radius: 4px;
    --card-shadow: 0 4px 12px rgba(15, 23, 42, 0.08);
    --ok: #047857;  --ok-bg: #ecfdf5;  --ok-bd: #a7f3d0;
    --bad: #b91c1c; --bad-bg: #fef2f2; --bad-bd: #fecaca;
  }
  body { background: var(--bg-page); color: var(--text-main);
         font-family: 'Inter', 'Salesforce Sans', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Arial, sans-serif; font-variant-numeric: tabular-nums;  }

  .cm-page { padding: 20px 24px; max-width: 1100px; margin: 0 auto; }
  .cm-header { display: flex; flex-wrap: wrap; justify-content: space-between; align-items: flex-end; gap: 12px; margin-bottom: 14px; }
  .cm-subtitle { font-size: 12px; text-transform: uppercase; letter-spacing: .5px; color: var(--text-muted); }
  .cm-title { margin: 2px 0 0; font-size: 22px; color: var(--brand-primary); }
  .cm-summary { margin-top: 4px; font-size: 13px; color: var(--text-muted); }
  .cm-summary b { color: var(--brand-primary); }
  .cm-search { height: 32px; width: 240px; padding: 0 10px; border: 1px solid var(--brand-border); border-radius: var(--radius); font-size: 13px; }
  .cm-search:focus { outline: none; border-color: var(--brand-primary); }

  .cm-alert { padding: 10px 14px; border-radius: var(--radius); margin-bottom: 14px; font-size: 13px; }
  .cm-alert-ok  { background: var(--ok-bg); color: var(--ok); border: 1px solid var(--ok-bd); }
  .cm-alert-err { background: var(--bad-bg); color: var(--bad); border: 1px solid var(--bad-bd); }
  #cmToast { position: sticky; top: 8px; z-index: 50; box-shadow: var(--card-shadow); }

  .cm-card { background: #fff; border: 1px solid var(--brand-border); border-radius: var(--radius); box-shadow: var(--card-shadow); overflow: hidden; }
  .cm-add { display: flex; flex-wrap: wrap; gap: 10px; align-items: flex-end; padding: 14px; border-bottom: 1px solid var(--brand-border); background: var(--brand-accent-bg); }
  .cm-field { display: flex; flex-direction: column; gap: 4px; }
  .cm-field label { font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: .3px; color: var(--text-muted); }
  .cm-in { height: 30px; padding: 0 8px; border: 1px solid var(--brand-border); border-radius: var(--radius); font-size: 13px; background: #fff; }
  .cm-in:focus { outline: none; border-color: var(--brand-primary); }
  .cm-in-name { width: 320px; }
  .cm-in-amt { width: 150px; text-align: right; }
  .cm-in-sort { width: 80px; text-align: right; }

  .cm-table-wrap { overflow-x: auto; }
  table.cm-table { width: 100%; border-collapse: collapse; font-size: 13px; }
  .cm-table th { background: var(--table-header-bg); color: var(--brand-primary); text-align: left; font-size: 11px;
      text-transform: uppercase; letter-spacing: .4px; padding: 10px; border-bottom: 1px solid var(--brand-border); white-space: nowrap; }
  .cm-table td { padding: 8px 10px; border-bottom: 1px solid #eef2f6; vertical-align: middle; }
  .cm-table tr:hover td { background: var(--row-hover); }
  .cm-table tr.cm-inactive td { color: #9a9a9a; background: #f7f7f7; }
  .cm-table tr.cm-flash td { background: #ccfbef !important; transition: background .6s; }
  .cm-num { text-align: right; white-space: nowrap; }
  .cm-name { font-weight: 600; }

  .cm-badge { display: inline-block; padding: 2px 9px; font-size: 10px; font-weight: 700; letter-spacing: .3px;
              text-transform: uppercase; border-radius: 10px; white-space: nowrap; border: 1px solid; }
  .cm-b-on  { color: var(--ok); background: var(--ok-bg); border-color: var(--ok-bd); }
  .cm-b-off { color: var(--text-muted); background: #f3f3f3; border-color: #dcdcdc; }
  .cm-used { font-size: 12px; color: var(--text-muted); }

  .cm-btn { height: 28px; padding: 0 11px; border-radius: var(--radius); font-size: 12px; font-weight: 600; cursor: pointer;
            border: 1px solid var(--brand-primary); background: var(--brand-primary); color: #fff; white-space: nowrap; }
  .cm-btn:hover { background: var(--brand-primary-dark); }
  .cm-btn:disabled { opacity: .45; cursor: default; }
  .cm-btn-outline { background: #fff; color: var(--brand-primary); border-color: var(--brand-border-dark); box-shadow: 0 1px 4px rgba(15, 23, 42,.15); }
  .cm-btn-outline:hover { background: var(--brand-accent-bg); border-color: var(--brand-primary); }
  .cm-btn-bad { background: #fff; color: var(--bad); border-color: var(--bad-bd); }
  .cm-btn-bad:hover { background: var(--bad-bg); border-color: var(--bad); }
  .cm-actions { display: flex; gap: 6px; flex-wrap: wrap; align-items: center; }
  .cm-confirm { font-size: 12px; color: var(--bad); font-weight: 600; }

  .cm-empty { text-align: center; color: var(--text-muted); padding: 34px; }
</style>
<style>
<%@ include file="css/finance.css" %>
</style>
</head>
<body>

<div class="cm-page">

  <div class="cm-header">
    <div>
      <div class="cm-subtitle">Masters</div>
      <h1 class="cm-title">KSS Course Master</h1>
      <div class="cm-summary">Courses: <b id="cntTotal"><%= rows.size() %></b> &nbsp;|&nbsp; Active: <b id="cntActive">0</b></div>
    </div>
    <input type="text" id="searchBox" class="cm-search" placeholder="Search course">
  </div>

  <% if (loadError != null) { %>
    <div class="cm-alert cm-alert-err"><%= esc(loadError) %></div>
  <% } %>

  <div id="cmToast" class="cm-alert" style="display:none;"></div>

  <div class="cm-card">
    <!-- Add new course -->
    <div class="cm-add">
      <div class="cm-field"><label>Course name</label><input type="text" id="addName" class="cm-in cm-in-name" maxlength="150" placeholder="e.g. ENGINEERING"></div>
      <div class="cm-field"><label>Sanctioned amount (&#8377;)</label><input type="number" id="addAmount" class="cm-in cm-in-amt" min="0" step="0.01" value="0"></div>
      <div class="cm-field"><label>Order</label><input type="number" id="addSort" class="cm-in cm-in-sort" placeholder="auto"></div>
      <button type="button" id="addBtn" class="cm-btn">+ Add Course</button>
    </div>

    <div class="cm-table-wrap">
      <table class="cm-table">
        <thead>
          <tr>
            <th style="width:50px">Order</th>
            <th>Course Name</th>
            <th class="cm-num">Sanctioned Amount</th>
            <th>Used by</th>
            <th>Status</th>
            <th style="width:270px">Action</th>
          </tr>
        </thead>
        <tbody id="cmBody">
        <% for (Map<String, String> r : rows) { %>
          <tr class="cm-row" data-id="<%= esc(r.get("id")) %>" data-name="<%= esc(r.get("name")) %>"
              data-amount="<%= esc(r.get("amount")) %>" data-sort="<%= esc(r.get("sort")) %>"
              data-active="<%= esc(r.get("active")) %>" data-used="<%= esc(r.get("used")) %>"></tr>
        <% } %>
          <tr id="emptyRow" style="display:none;"><td colspan="6" class="cm-empty">No courses found.</td></tr>
        </tbody>
      </table>
    </div>
  </div>
</div>

<script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
<script>
$(function () {
  var RS = String.fromCharCode(8377);

  function money(v) {
    return RS + ' ' + Number(v || 0).toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  }

  function showToast(ok, text) {
    var $t = $('#cmToast');
    $t.removeClass('cm-alert-ok cm-alert-err').addClass(ok ? 'cm-alert-ok' : 'cm-alert-err').text(text).stop(true, true).fadeIn(150);
    clearTimeout($t.data('timer'));
    $t.data('timer', setTimeout(function () { $t.fadeOut(300); }, 4000));
  }

  // Draw a row (view mode) from its data-* attributes
  function render($tr) {
    var active = $tr.attr('data-active') === '1', used = parseInt($tr.attr('data-used'), 10) || 0;
    $tr.toggleClass('cm-inactive', !active).empty()
      .append($('<td class="cm-num"></td>').text($tr.attr('data-sort')))
      .append($('<td class="cm-name"></td>').text($tr.attr('data-name')))
      .append($('<td class="cm-num"></td>').text(money($tr.attr('data-amount'))))
      .append($('<td class="cm-used"></td>').text(used === 0 ? '-' : used + ' application' + (used === 1 ? '' : 's')))
      .append($('<td></td>').append($('<span class="cm-badge"></span>').addClass(active ? 'cm-b-on' : 'cm-b-off').text(active ? 'Active' : 'Inactive')))
      .append($('<td></td>').append(
        $('<div class="cm-actions"></div>')
          .append('<button type="button" class="cm-btn cm-btn-outline cm-edit">&#9998; Edit</button>')
          .append($('<button type="button" class="cm-btn cm-btn-outline cm-toggle"></button>').text(active ? 'Deactivate' : 'Activate'))
          .append($('<button type="button" class="cm-btn cm-btn-bad cm-del">Delete</button>')
                    .prop('disabled', used > 0).attr('title', used > 0 ? 'Used by applications - deactivate instead' : ''))
      ));
  }

  function setData($tr, d) {
    $tr.attr({ 'data-id': d.id, 'data-name': d.name, 'data-amount': d.amount, 'data-sort': d.sort,
               'data-active': d.active, 'data-used': d.used });
  }

  function flash($tr) { $tr.addClass('cm-flash'); setTimeout(function () { $tr.removeClass('cm-flash'); }, 1200); }

  function recount() {
    $('#cntTotal').text($('tr.cm-row').length);
    $('#cntActive').text($('tr.cm-row[data-active="1"]').length);
    applySearch();
  }

  function applySearch() {
    var q = $.trim($('#searchBox').val()).toLowerCase(), visible = 0;
    $('tr.cm-row').each(function () {
      var ok = q === '' || ($(this).attr('data-name') || '').toLowerCase().indexOf(q) !== -1;
      $(this).toggle(ok); if (ok) visible++;
    });
    $('#emptyRow').toggle(visible === 0);
  }

  function failMsg(xhr) {
    return (xhr.responseJSON && xhr.responseJSON.message) ? xhr.responseJSON.message : 'Could not save. Please try again.';
  }

  $('tr.cm-row').each(function () { render($(this)); });
  recount();

  // ---- Add
  $('#addBtn').on('click', function () {
    var $b = $(this), name = $.trim($('#addName').val());
    if (name === '') { showToast(false, 'Please enter the course name.'); $('#addName').trigger('focus'); return; }
    $b.prop('disabled', true).text('Saving...');
    $.ajax({ url: 'KssCourseMasterServlet', type: 'POST', dataType: 'json',
             data: { action: 'save', name: name, amount: $('#addAmount').val(), sort: $('#addSort').val() }
    }).done(function (res) {
      if (!res.ok) { showToast(false, res.message); return; }
      var $tr = $('<tr class="cm-row"></tr>');
      setData($tr, res); render($tr);
      // insert in order
      var placed = false;
      $('tr.cm-row').each(function () {
        if (parseInt($(this).attr('data-sort'), 10) > res.sort) { $tr.insertBefore(this); placed = true; return false; }
      });
      if (!placed) $tr.insertBefore('#emptyRow');
      $('#addName').val(''); $('#addAmount').val('0'); $('#addSort').val('');
      flash($tr); recount(); showToast(true, res.message);
    }).fail(function (xhr) { showToast(false, failMsg(xhr)); })
      .always(function () { $b.prop('disabled', false).text('+ Add Course'); });
  });
  $('#addName, #addAmount, #addSort').on('keydown', function (e) { if (e.key === 'Enter') { e.preventDefault(); $('#addBtn').trigger('click'); } });

  // ---- Edit (inline)
  $(document).on('click', '.cm-edit', function () {
    var $tr = $(this).closest('tr');
    $tr.find('td').eq(0).empty().append($('<input type="number" class="cm-in cm-in-sort e-sort">').val($tr.attr('data-sort')));
    $tr.find('td').eq(1).empty().append($('<input type="text" maxlength="150" class="cm-in cm-in-name e-name">').val($tr.attr('data-name')));
    $tr.find('td').eq(2).empty().append($('<input type="number" min="0" step="0.01" class="cm-in cm-in-amt e-amt">').val($tr.attr('data-amount')));
    $tr.find('td').eq(5).empty().append(
      $('<div class="cm-actions"></div>')
        .append('<button type="button" class="cm-btn cm-save">Update</button>')
        .append('<button type="button" class="cm-btn cm-btn-outline cm-cancel">Cancel</button>'));
    $tr.find('.e-name').trigger('focus');
  });
  $(document).on('click', '.cm-cancel', function () { render($(this).closest('tr')); });
  $(document).on('keydown', '.e-name, .e-amt, .e-sort', function (e) {
    if (e.key === 'Enter') { e.preventDefault(); $(this).closest('tr').find('.cm-save').trigger('click'); }
    if (e.key === 'Escape') { render($(this).closest('tr')); }
  });
  $(document).on('click', '.cm-save', function () {
    var $b = $(this), $tr = $b.closest('tr');
    $b.prop('disabled', true).text('Saving...');
    $.ajax({ url: 'KssCourseMasterServlet', type: 'POST', dataType: 'json',
             data: { action: 'save', id: $tr.attr('data-id'), name: $.trim($tr.find('.e-name').val()),
                     amount: $tr.find('.e-amt').val(), sort: $tr.find('.e-sort').val() }
    }).done(function (res) {
      if (!res.ok) { showToast(false, res.message); $b.prop('disabled', false).text('Update'); return; }
      setData($tr, res); render($tr); flash($tr); recount(); showToast(true, res.message);
    }).fail(function (xhr) { showToast(false, failMsg(xhr)); $b.prop('disabled', false).text('Update'); });
  });

  // ---- Activate / Deactivate
  $(document).on('click', '.cm-toggle', function () {
    var $b = $(this), $tr = $b.closest('tr');
    $b.prop('disabled', true);
    $.ajax({ url: 'KssCourseMasterServlet', type: 'POST', dataType: 'json', data: { action: 'toggle', id: $tr.attr('data-id') }
    }).done(function (res) {
      if (!res.ok) { showToast(false, res.message); $b.prop('disabled', false); return; }
      setData($tr, res); render($tr); flash($tr); recount(); showToast(true, res.message);
    }).fail(function (xhr) { showToast(false, failMsg(xhr)); $b.prop('disabled', false); });
  });

  // ---- Delete (inline confirm, no browser popup)
  $(document).on('click', '.cm-del', function () {
    var $cell = $(this).closest('td');
    $cell.empty().append(
      $('<div class="cm-actions"></div>')
        .append('<span class="cm-confirm">Delete this course?</span>')
        .append('<button type="button" class="cm-btn cm-btn-bad cm-del-yes">Yes, delete</button>')
        .append('<button type="button" class="cm-btn cm-btn-outline cm-cancel">No</button>'));
  });
  $(document).on('click', '.cm-del-yes', function () {
    var $b = $(this), $tr = $b.closest('tr');
    $b.prop('disabled', true).text('Deleting...');
    $.ajax({ url: 'KssCourseMasterServlet', type: 'POST', dataType: 'json', data: { action: 'delete', id: $tr.attr('data-id') }
    }).done(function (res) {
      if (!res.ok) { showToast(false, res.message); render($tr); return; }
      $tr.fadeOut(250, function () { $tr.remove(); recount(); });
      showToast(true, res.message);
    }).fail(function (xhr) { showToast(false, failMsg(xhr)); render($tr); });
  });

  $('#searchBox').on('input keyup', applySearch);
});
</script>

</body>
</html>
