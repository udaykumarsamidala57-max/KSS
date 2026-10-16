<%@page import="java.util.List"%>
<%@page import="java.util.Map"%>
<%@page import="java.util.Set"%>
<%@page import="java.util.TreeSet"%>
<%!
    // HTML-escape helper
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
    // This page must be opened through KssCourseServlet (it loads the data and checks the Global role)
    @SuppressWarnings("unchecked")
    List<Map<String, String>> rows = (List<Map<String, String>>) request.getAttribute("rows");
    @SuppressWarnings("unchecked")
    List<String> courses = (List<String>) request.getAttribute("courses");
    if (rows == null || courses == null) {
        response.sendRedirect("KssCourseServlet");
        return;
    }

    String okMsg = request.getParameter("msg");
    String errMsg = request.getParameter("err");
    if (errMsg == null) errMsg = (String) request.getAttribute("error");

    Set<String> orgs = new TreeSet<String>();
    int pendingCount = 0;
    for (Map<String, String> r : rows) {
        String o = r.get("orgName");
        orgs.add(o == null || o.trim().isEmpty() ? "Uncategorized" : o.trim());
        String k = r.get("kssCourse");
        if (k == null || k.trim().isEmpty()) pendingCount++;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>KSS Course Mapping</title>

<!-- INCLUDE SHARED HEADER & MENU -->
<%@ include file="header.jsp" %>

<style>
  :root {
    --brand-primary: #7a1f35;
    --brand-primary-dark: #5e1627;
    --brand-accent-bg: #fdf6f7;
    --brand-border: #e2cece;
    --brand-border-dark: #c8b1b1;
    --text-main: #2b2b2b;
    --text-muted: #666666;
    --bg-page: #f8f9fa;
    --bg-card: #ffffff;
    --table-header-bg: #faf0f2;
    --row-hover: #fcf2f4;
    --radius: 4px;
    --card-shadow: 0 4px 12px rgba(122, 31, 53, 0.08);
  }

  body { background: var(--bg-page); color: var(--text-main);
         font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Arial, sans-serif; }

  .kc-page { padding: 20px 24px; }

  .kc-header { display: flex; flex-wrap: wrap; justify-content: space-between; align-items: flex-end;
               gap: 12px; margin-bottom: 16px; }
  .kc-subtitle { font-size: 12px; text-transform: uppercase; letter-spacing: .5px; color: var(--text-muted); }
  .kc-title { margin: 2px 0 0; font-size: 22px; color: var(--brand-primary); }
  .kc-summary { margin-top: 4px; font-size: 13px; color: var(--text-muted); }
  .kc-summary b { color: var(--brand-primary); }

  .kc-controls { display: flex; flex-wrap: wrap; gap: 10px; align-items: center; }
  .kc-controls label { font-size: 12px; font-weight: 600; color: var(--text-muted); }
  .kc-controls select, .kc-controls input {
      height: 32px; padding: 0 10px; border: 1px solid var(--brand-border); border-radius: var(--radius);
      background: #fff; font-size: 13px; }
  .kc-controls input { width: 220px; }
  .kc-controls select:focus, .kc-controls input:focus { outline: none; border-color: var(--brand-primary); }

  .kc-alert { padding: 10px 14px; border-radius: var(--radius); margin-bottom: 14px; font-size: 13px; }
  .kc-alert-ok  { background: #e6f4ea; color: #137333; border: 1px solid #ceead6; }
  .kc-alert-err { background: #fce8e6; color: #c5221f; border: 1px solid #fad2cf; }
  .kc-row.kc-saved td { background: #fdf6f7 !important; transition: background .6s; }
  .kc-btn.kc-busy { opacity: .6; cursor: progress; }

  .kc-card { background: var(--bg-card); border: 1px solid var(--brand-border); border-radius: var(--radius);
             box-shadow: var(--card-shadow); overflow: hidden; }
  .kc-table-wrap { overflow-x: auto; }
  table.kc-table { width: 100%; border-collapse: collapse; font-size: 13px; }
  .kc-table th { background: var(--table-header-bg); color: var(--brand-primary); text-align: left;
                 font-size: 11px; text-transform: uppercase; letter-spacing: .4px; padding: 10px;
                 border-bottom: 1px solid var(--brand-border); white-space: nowrap; }
  .kc-table td { padding: 8px 10px; border-bottom: 1px solid #f1e6e8; vertical-align: middle; }
  .kc-table tr:hover td { background: var(--row-hover); }

  .kc-form { display: flex; gap: 6px; align-items: center; margin: 0; }
  .kc-form select { height: 30px; min-width: 210px; padding: 0 8px; border: 1px solid var(--brand-border);
                    border-radius: var(--radius); background: #fff; font-size: 12px; }
  .kc-form select:focus { outline: none; border-color: var(--brand-primary); }
  .kc-btn { height: 30px; padding: 0 12px; border-radius: var(--radius); font-size: 12px; font-weight: 600;
            cursor: pointer; border: 1px solid var(--brand-primary); background: var(--brand-primary); color: #fff; }
  .kc-btn:hover { background: var(--brand-primary-dark); }
  .kc-btn:disabled { opacity: .45; cursor: default; }
  .kc-btn-outline { background: #fff; color: var(--brand-primary); border: 1px solid var(--brand-border-dark);
                    box-shadow: 0 1px 4px rgba(122, 31, 53, 0.15); }
  .kc-btn-outline:hover { background: var(--brand-accent-bg); border-color: var(--brand-primary); }

  .kc-badge { display: inline-block; padding: 2px 9px; font-size: 10px; font-weight: 700; letter-spacing: .3px;
              text-transform: uppercase; border-radius: 10px; white-space: nowrap;
              color: var(--brand-primary); background: var(--brand-accent-bg);
              border: 1px solid var(--brand-border-dark); box-shadow: 0 1px 4px rgba(122, 31, 53, 0.15); }
  .kc-badge-muted { color: var(--text-muted); background: #f3f3f3; border-color: #dcdcdc; box-shadow: none; }

  .kc-empty { text-align: center; color: var(--text-muted); padding: 40px; }
</style>
</head>
<body>

<div class="kc-page">

  <div class="kc-header">
    <div>
      <div class="kc-subtitle">Scholarship Management</div>
      <h1 class="kc-title">KSS Course Mapping</h1>
      <div class="kc-summary">
        Submitted applications: <b><%= rows.size() %></b> &nbsp;|&nbsp;
        KSS course not set: <b id="kcPendingCount"><%= pendingCount %></b>
      </div>
    </div>

    <div class="kc-controls">
      <label for="orgFilter">Organization:</label>
      <select id="orgFilter">
        <option value="ALL">All Organizations</option>
        <% for (String o : orgs) { %>
          <option value="<%= esc(o) %>"><%= esc(o) %></option>
        <% } %>
      </select>

      <label for="statusFilter">Show:</label>
      <select id="statusFilter">
        <option value="ALL">All</option>
        <option value="NOTSET">KSS course not set</option>
        <option value="SET">KSS course set</option>
      </select>

      <input type="text" id="searchBox" placeholder="Search App No / Emp / Child / College">
    </div>
  </div>

  <% if (okMsg != null && !okMsg.isEmpty()) { %>
    <div class="kc-alert kc-alert-ok"><%= esc(okMsg) %></div>
  <% } %>
  <% if (errMsg != null && !errMsg.isEmpty()) { %>
    <div class="kc-alert kc-alert-err"><%= esc(errMsg) %></div>
  <% } %>

  <div id="kcToast" class="kc-alert" style="display:none;"></div>

  <div class="kc-card">
    <div class="kc-table-wrap">
      <table class="kc-table">
        <thead>
          <tr>
            <th>#</th>
            <th>App No</th>
            <th>Organization</th>
            <th>Emp No</th>
            <th>Emp Name</th>
            <th>Child Name</th>
            <th>College</th>
            <th>Course (Applied)</th>
            <th>Year</th>
            <th>Current KSS Course</th>
            <th>Set KSS Course</th>
          </tr>
        </thead>
        <tbody>
        <%
          if (rows.isEmpty()) {
        %>
          <tr><td colspan="11" class="kc-empty">No submitted applications found.</td></tr>
        <%
          } else {
            int n = 0;
            for (Map<String, String> r : rows) {
              String org = r.get("orgName");
              org = (org == null || org.trim().isEmpty()) ? "Uncategorized" : org.trim();
              String kss = r.get("kssCourse");
              boolean isSet = kss != null && !kss.trim().isEmpty();
              StringBuilder sb = new StringBuilder();
              for (String key : new String[]{"appNo", "empNo", "empName", "childName", "college", "course"}) {
                  String v = r.get(key);
                  if (v != null) sb.append(v).append(' ');
              }
              String searchText = sb.toString().toLowerCase();
        %>
          <tr class="kc-row" data-org="<%= esc(org) %>" data-set="<%= isSet ? "SET" : "NOTSET" %>"
              data-search="<%= esc(searchText) %>">
            <td><%= ++n %></td>
            <td><strong><%= esc(r.get("appNo")) %></strong></td>
            <td><%= esc(org) %></td>
            <td><%= esc(r.get("empNo")) %></td>
            <td><%= esc(r.get("empName")) %></td>
            <td><%= esc(r.get("childName")) %></td>
            <td><%= esc(r.get("college")) %></td>
            <td><%= esc(r.get("course")) %></td>
            <td><%= esc(r.get("presentYear")) %></td>
            <td class="kc-current">
              <% if (isSet) { %>
                <span class="kc-badge"><%= esc(kss) %></span>
              <% } else { %>
                <span class="kc-badge kc-badge-muted">Not set</span>
              <% } %>
            </td>
            <td class="kc-action">
              <%-- View mode (course saved): Edit button --%>
              <div class="kc-view" <%= isSet ? "" : "style=\"display:none;\"" %>>
                <button type="button" class="kc-btn kc-btn-outline kc-edit">&#9998; Edit</button>
              </div>
              <%-- Edit mode: dropdown + Save/Update (+ Cancel when a course is already saved) --%>
              <form class="kc-form" method="post" action="KssCourseServlet" <%= isSet ? "style=\"display:none;\"" : "" %>>
                <input type="hidden" name="id" value="<%= esc(r.get("id")) %>">
                <select name="kssCourse" data-original="<%= esc(isSet ? kss.trim() : "") %>">
                  <option value="">-- Select KSS Course --</option>
                  <%
                    boolean matched = false;
                    for (String c : courses) {
                      boolean sel = isSet && c.equals(kss.trim());
                      if (sel) matched = true;
                  %>
                    <option value="<%= esc(c) %>" <%= sel ? "selected" : "" %>><%= esc(c) %></option>
                  <% } %>
                  <% if (isSet && !matched) { %>
                    <%-- Value saved earlier that is no longer in the list --%>
                    <option value="<%= esc(kss.trim()) %>" selected disabled><%= esc(kss.trim()) %> (old)</option>
                  <% } %>
                </select>
                <button type="submit" class="kc-btn kc-save" disabled><%= isSet ? "Update" : "Save" %></button>
                <button type="button" class="kc-btn kc-btn-outline kc-cancel" <%= isSet ? "" : "style=\"display:none;\"" %>>Cancel</button>
              </form>
            </td>
          </tr>
        <%
            }
          }
        %>
          <tr id="noMatchRow" style="display:none;"><td colspan="11" class="kc-empty">No applications match the filter.</td></tr>
        </tbody>
      </table>
    </div>
  </div>
</div>

<script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
<script>
$(function () {

  function showToast(ok, text) {
    var $t = $('#kcToast');
    $t.removeClass('kc-alert-ok kc-alert-err').addClass(ok ? 'kc-alert-ok' : 'kc-alert-err').text(text).stop(true, true).fadeIn(150);
    clearTimeout($t.data('timer'));
    $t.data('timer', setTimeout(function () { $t.fadeOut(300); }, 3500));
  }

  function resetSelect($sel) {
    $sel.val($sel.attr('data-original'));
    $sel.closest('form').find('.kc-save').prop('disabled', true);
  }

  // Enable Save/Update only when the dropdown value changed
  $(document).on('change', '.kc-form select', function () {
    var $sel = $(this);
    $sel.closest('form').find('.kc-save').prop('disabled', $sel.val() === $sel.attr('data-original'));
  });

  // Edit: show dropdown + Update/Cancel
  $(document).on('click', '.kc-edit', function () {
    var $cell = $(this).closest('td');
    $cell.find('.kc-view').hide();
    $cell.find('.kc-form').css('display', 'flex').find('select').trigger('focus');
  });

  // Cancel: restore saved value, back to Edit button
  $(document).on('click', '.kc-cancel', function () {
    var $cell = $(this).closest('td');
    resetSelect($cell.find('select'));
    $cell.find('.kc-form').hide();
    $cell.find('.kc-view').show();
  });

  // Save / Update with AJAX (no page reload)
  $(document).on('submit', '.kc-form', function (e) {
    e.preventDefault();
    var $form = $(this), $row = $form.closest('tr'), $sel = $form.find('select'), $btn = $form.find('.kc-save');
    var wasSet = $sel.attr('data-original') !== '';

    $btn.prop('disabled', true).addClass('kc-busy').text('Saving...');

    $.ajax({
      url: 'KssCourseServlet',
      type: 'POST',
      data: $form.serialize(),
      dataType: 'json'
    }).done(function (res) {
      if (!res.ok) {
        showToast(false, res.message || 'Update failed.');
        $btn.prop('disabled', false);
        return;
      }
      var value = res.value || '';
      var isSet = value !== '';

      // Current KSS Course badge
      var $badge = $('<span class="kc-badge"></span>').text(isSet ? value : 'Not set');
      if (!isSet) $badge.addClass('kc-badge-muted');
      $row.find('.kc-current').empty().append($badge);

      // Remember the new saved value, drop any "(old)" option
      $sel.attr('data-original', value);
      $sel.find('option:disabled').remove();
      $sel.val(value);

      // Switch row to Edit mode
      $form.find('.kc-cancel').toggle(isSet);
      if (isSet) { $form.hide(); $row.find('.kc-view').show(); }
      $row.attr('data-set', isSet ? 'SET' : 'NOTSET');

      // Update "not set" counter
      if (wasSet !== isSet) {
        var $c = $('#kcPendingCount');
        $c.text(parseInt($c.text(), 10) + (isSet ? -1 : 1));
      }

      $row.addClass('kc-saved');
      setTimeout(function () { $row.removeClass('kc-saved'); }, 1500);
      showToast(true, res.message);
      applyFilters();
    }).fail(function (xhr) {
      var msg = 'Could not save. Please try again.';
      if (xhr.responseJSON && xhr.responseJSON.message) msg = xhr.responseJSON.message;
      else if (xhr.status === 200) msg = 'Your session has expired. Please log in again.';
      showToast(false, msg);
      $btn.prop('disabled', false);
    }).always(function () {
      $btn.removeClass('kc-busy').text($sel.attr('data-original') !== '' ? 'Update' : 'Save');
      if ($sel.val() === $sel.attr('data-original')) $btn.prop('disabled', true);
    });
  });

  $('#orgFilter, #statusFilter').on('change', applyFilters);
  $('#searchBox').on('keyup', applyFilters);
});

function applyFilters() {
  var org = $('#orgFilter').val();
  var status = $('#statusFilter').val();
  var q = $.trim($('#searchBox').val()).toLowerCase();
  var visible = 0, $rows = $('.kc-row');
  $rows.each(function () {
    var $tr = $(this);
    var ok = (org === 'ALL' || $tr.attr('data-org') === org)
          && (status === 'ALL' || $tr.attr('data-set') === status)
          && (q === '' || $tr.attr('data-search').indexOf(q) !== -1);
    $tr.toggle(ok);
    if (ok) visible++;
  });
  $('#noMatchRow').toggle($rows.length > 0 && visible === 0);
}
</script>

</body>
</html>
