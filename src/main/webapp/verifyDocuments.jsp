<%@page import="java.util.List"%>
<%@page import="java.util.Map"%>
<%@page import="java.util.Set"%>
<%@page import="java.util.TreeSet"%>
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
    // Must be opened through VerifyDocumentsServlet (loads data + checks Global role)
    @SuppressWarnings("unchecked")
    List<Map<String, String>> rows = (List<Map<String, String>>) request.getAttribute("rows");
    @SuppressWarnings("unchecked")
    List<String[]> docs = (List<String[]>) request.getAttribute("docs");
    if (rows == null || docs == null) {
        response.sendRedirect("VerifyDocumentsServlet");
        return;
    }
    String loadError = (String) request.getAttribute("error");
    Integer waiting = (Integer) request.getAttribute("waitingForKssCourse");
    int totalDocs = docs.size();

    Set<String> orgs = new TreeSet<String>();
    int cntAll = 0, cntPending = 0, cntRejected = 0;
    for (Map<String, String> r : rows) {
        String o = r.get("orgName");
        orgs.add(o == null || o.trim().isEmpty() ? "Uncategorized" : o.trim());
        int v = 0, rj = 0;
        for (String[] d : docs) {
            String st = r.get("st_" + d[0]);
            if ("Verified".equals(st)) v++; else if ("Rejected".equals(st)) rj++;
        }
        if (rj > 0) cntRejected++; else if (v == totalDocs) cntAll++; else cntPending++;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Verify Documents</title>

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
    --bg-card: #ffffff;
    --table-header-bg: #f8fafc;
    --row-hover: #f0fdfa;
    --radius: 4px;
    --card-shadow: 0 4px 12px rgba(15, 23, 42, 0.08);
    --ok: #047857;  --ok-bg: #ecfdf5;  --ok-bd: #a7f3d0;
    --bad: #b91c1c; --bad-bg: #fef2f2; --bad-bd: #fecaca;
  }
  body { background: var(--bg-page); color: var(--text-main);
         font-family: 'Inter', 'Salesforce Sans', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Arial, sans-serif; font-variant-numeric: tabular-nums;  }

  .vd-page { padding: 20px 24px; }
  .vd-header { display: flex; flex-wrap: wrap; justify-content: space-between; align-items: flex-end; gap: 12px; margin-bottom: 14px; }
  .vd-subtitle { font-size: 12px; text-transform: uppercase; letter-spacing: .5px; color: var(--text-muted); }
  .vd-title { margin: 2px 0 0; font-size: 22px; color: var(--brand-primary); }
  .vd-summary { margin-top: 4px; font-size: 13px; color: var(--text-muted); }
  .vd-summary b { color: var(--brand-primary); }

  .vd-controls { display: flex; flex-wrap: wrap; gap: 10px; align-items: center; }
  .vd-controls label { font-size: 12px; font-weight: 600; color: var(--text-muted); }
  .vd-controls select, .vd-controls input { height: 32px; padding: 0 10px; border: 1px solid var(--brand-border);
      border-radius: var(--radius); background: #fff; font-size: 13px; }
  .vd-controls input { width: 220px; }
  .vd-controls select:focus, .vd-controls input:focus { outline: none; border-color: var(--brand-primary); }

  .vd-alert { padding: 10px 14px; border-radius: var(--radius); margin-bottom: 14px; font-size: 13px; }
  .vd-alert-ok  { background: var(--ok-bg); color: var(--ok); border: 1px solid var(--ok-bd); }
  .vd-alert-err { background: var(--bad-bg); color: var(--bad); border: 1px solid var(--bad-bd); }
  .vd-alert-info { background: var(--brand-accent-bg); color: var(--brand-primary); border: 1px solid var(--brand-border); }
  #vdToast { position: sticky; top: 8px; z-index: 50; box-shadow: var(--card-shadow); }

  .vd-card { background: var(--bg-card); border: 1px solid var(--brand-border); border-radius: var(--radius);
             box-shadow: var(--card-shadow); overflow: hidden; }
  .vd-table-wrap { overflow-x: auto; }
  table.vd-table { width: 100%; border-collapse: collapse; font-size: 13px; }
  .vd-table > thead th { background: var(--table-header-bg); color: var(--brand-primary); text-align: left; font-size: 11px;
      text-transform: uppercase; letter-spacing: .4px; padding: 10px; border-bottom: 1px solid var(--brand-border); white-space: nowrap; }
  .vd-table > tbody > tr.vd-app > td { padding: 9px 10px; border-bottom: 1px solid #eef2f6; vertical-align: middle; }
  .vd-table > tbody > tr.vd-app:hover > td { background: var(--row-hover); }
  .vd-table > tbody > tr.vd-app.vd-open > td { background: var(--brand-accent-bg); border-bottom-color: transparent; }

  /* progress */
  .vd-progress { display: flex; align-items: center; gap: 8px; min-width: 150px; }
  .vd-bar { flex: 1; height: 6px; background: #eee; border-radius: 3px; overflow: hidden; display: flex; }
  .vd-bar-ok { background: #047857; height: 100%; }
  .vd-bar-bad { background: #b91c1c; height: 100%; }
  .vd-progress-txt { font-size: 12px; color: var(--text-muted); white-space: nowrap; }

  /* badges */
  .vd-badge { display: inline-block; padding: 2px 9px; font-size: 10px; font-weight: 700; letter-spacing: .3px;
              text-transform: uppercase; border-radius: 10px; white-space: nowrap; border: 1px solid; }
  .vd-b-pending  { color: var(--brand-primary); background: var(--brand-accent-bg); border-color: var(--brand-border-dark);
                   box-shadow: 0 1px 4px rgba(15, 23, 42, 0.15); }
  .vd-b-verified { color: var(--ok); background: var(--ok-bg); border-color: var(--ok-bd); }
  .vd-b-rejected { color: var(--bad); background: var(--bad-bg); border-color: var(--bad-bd); }
  .vd-b-muted    { color: var(--text-muted); background: #f3f3f3; border-color: #dcdcdc; }

  /* buttons */
  .vd-btn { height: 28px; padding: 0 11px; border-radius: var(--radius); font-size: 12px; font-weight: 600; cursor: pointer;
            border: 1px solid var(--brand-primary); background: var(--brand-primary); color: #fff; white-space: nowrap; }
  .vd-btn:hover { background: var(--brand-primary-dark); }
  .vd-btn:disabled { opacity: .45; cursor: default; }
  .vd-btn-outline { background: #fff; color: var(--brand-primary); border-color: var(--brand-border-dark);
                    box-shadow: 0 1px 4px rgba(15, 23, 42, 0.15); }
  .vd-btn-outline:hover { background: var(--brand-accent-bg); border-color: var(--brand-primary); }
  .vd-btn-ok  { background: #fff; color: var(--ok); border-color: var(--ok-bd); }
  .vd-btn-ok:hover  { background: var(--ok-bg); border-color: var(--ok); }
  .vd-btn-bad { background: #fff; color: var(--bad); border-color: var(--bad-bd); }
  .vd-btn-bad:hover { background: var(--bad-bg); border-color: var(--bad); }
  .vd-btn.vd-busy { opacity: .6; cursor: progress; }

  /* document panel */
  .vd-detail > td { padding: 0 10px 14px 10px; background: var(--brand-accent-bg); border-bottom: 1px solid var(--brand-border); }
  .vd-docs { width: 100%; border-collapse: collapse; background: #fff; border: 1px solid var(--brand-border); border-radius: var(--radius); }
  .vd-docs th { font-size: 11px; text-transform: uppercase; letter-spacing: .3px; color: var(--text-muted); text-align: left;
                padding: 8px 10px; background: #fff; border-bottom: 1px solid var(--brand-border); }
  .vd-docs td { padding: 8px 10px; border-bottom: 1px solid #eef2f6; vertical-align: middle; font-size: 13px; }
  .vd-docs tr:last-child td { border-bottom: none; }
  .vd-docs tr.vd-flash td { background: #ccfbef; transition: background .6s; }
  .vd-doc-actions { display: flex; gap: 6px; flex-wrap: wrap; align-items: center; }
  .vd-reject-box { display: none; gap: 6px; align-items: center; margin-top: 6px; }
  .vd-reject-box input { height: 28px; width: 260px; padding: 0 8px; border: 1px solid var(--bad-bd); border-radius: var(--radius); font-size: 12px; }
  .vd-reject-box input:focus { outline: none; border-color: var(--bad); }
  .vd-remarks { color: var(--bad); font-size: 12px; }
  .vd-view-link { color: var(--brand-primary); font-weight: 600; text-decoration: none; }
  .vd-view-link:hover { text-decoration: underline; }
  .vd-none { color: var(--text-muted); font-style: italic; font-size: 12px; }
  .vd-meta { font-size: 11px; color: var(--text-muted); padding: 8px 2px 0; }
  .vd-locked { font-size: 12px; color: var(--text-muted); }

  .vd-empty { text-align: center; color: var(--text-muted); padding: 40px; }
</style>
<style>
<%@ include file="css/finance.css" %>
</style>
</head>
<body>

<div class="vd-page">

  <div class="vd-header">
    <div>
      <div class="vd-subtitle">Approvals &rsaquo; Step 2</div>
      <h1 class="vd-title">Verify Documents</h1>
      <div class="vd-summary">
        Applications: <b id="cntTotal"><%= rows.size() %></b> &nbsp;|&nbsp;
        Pending: <b id="cntPending"><%= cntPending %></b> &nbsp;|&nbsp;
        All verified: <b id="cntAll"><%= cntAll %></b> &nbsp;|&nbsp;
        Has rejected: <b id="cntRejected"><%= cntRejected %></b>
      </div>
    </div>

    <div class="vd-controls">
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
        <option value="Pending">Pending</option>
        <option value="All Verified">All Verified</option>
        <option value="Has Rejected">Has Rejected</option>
      </select>

      <input type="text" id="searchBox" placeholder="Search App No / Emp / Child">
    </div>
  </div>

  <% if (loadError != null) { %>
    <div class="vd-alert vd-alert-err"><%= esc(loadError) %></div>
  <% } %>
  <% if (waiting != null && waiting > 0) { %>
    <div class="vd-alert vd-alert-info">
      <%= waiting %> submitted application<%= waiting == 1 ? " is" : "s are" %> waiting for
      <a href="KssCourseServlet" class="vd-view-link">Step 1 : Apply KSS Course</a> and not shown here yet.
    </div>
  <% } %>

  <div id="vdToast" class="vd-alert" style="display:none;"></div>

  <div class="vd-card">
    <div class="vd-table-wrap">
      <table class="vd-table">
        <thead>
          <tr>
            <th>#</th>
            <th>App No</th>
            <th>Organization</th>
            <th>Emp No</th>
            <th>Emp Name</th>
            <th>Child Name</th>
            <th>KSS Course</th>
            <th>Progress</th>
            <th>Documents</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
        <% if (rows.isEmpty()) { %>
          <tr><td colspan="10" class="vd-empty">No applications ready for document verification.</td></tr>
        <% } else {
             int n = 0;
             for (Map<String, String> r : rows) {
               String org = r.get("orgName");
               org = (org == null || org.trim().isEmpty()) ? "Uncategorized" : org.trim();
               String id = r.get("id");
               String finalStatus = r.get("finalStatus");
               boolean locked = finalStatus != null && !"Pending".equalsIgnoreCase(finalStatus);

               int v = 0, rj = 0;
               for (String[] d : docs) {
                   String st = r.get("st_" + d[0]);
                   if ("Verified".equals(st)) v++; else if ("Rejected".equals(st)) rj++;
               }
               String docsStatus = rj > 0 ? "Has Rejected" : (v == totalDocs ? "All Verified" : "Pending");
               String badgeCls = rj > 0 ? "vd-b-rejected" : (v == totalDocs ? "vd-b-verified" : "vd-b-pending");

               StringBuilder sb = new StringBuilder();
               for (String key : new String[]{"appNo", "empNo", "empName", "childName"}) {
                   String val = r.get(key);
                   if (val != null) sb.append(val).append(' ');
               }
        %>
          <tr class="vd-app" data-id="<%= esc(id) %>" data-org="<%= esc(org) %>" data-status="<%= docsStatus %>"
              data-search="<%= esc(sb.toString().toLowerCase()) %>">
            <td><%= ++n %></td>
            <td><strong><%= esc(r.get("appNo")) %></strong></td>
            <td><%= esc(org) %></td>
            <td><%= esc(r.get("empNo")) %></td>
            <td><%= esc(r.get("empName")) %></td>
            <td><%= esc(r.get("childName")) %></td>
            <td><span class="vd-badge vd-b-pending"><%= esc(r.get("kssCourse")) %></span></td>
            <td>
              <div class="vd-progress">
                <div class="vd-bar">
                  <div class="vd-bar-ok" style="width:<%= (v * 100) / totalDocs %>%"></div>
                  <div class="vd-bar-bad" style="width:<%= (rj * 100) / totalDocs %>%"></div>
                </div>
                <span class="vd-progress-txt"><%= v %>/<%= totalDocs %> verified</span>
              </div>
            </td>
            <td class="vd-app-status">
              <span class="vd-badge <%= badgeCls %>"><%= docsStatus %></span>
              <% if (locked) { %><span class="vd-badge vd-b-muted"><%= esc(finalStatus) %></span><% } %>
            </td>
            <td><button type="button" class="vd-btn vd-btn-outline vd-toggle">Verify &#9662;</button></td>
          </tr>
          <tr class="vd-detail" data-for="<%= esc(id) %>" style="display:none;">
            <td colspan="10">
              <table class="vd-docs">
                <thead>
                  <tr>
                    <th style="width:28%">Document</th>
                    <th style="width:10%">File</th>
                    <th style="width:14%">Status</th>
                    <th>Action</th>
                  </tr>
                </thead>
                <tbody>
                <% for (String[] d : docs) {
                     String st = r.get("st_" + d[0]);
                     String rm = r.get("rm_" + d[0]);
                     boolean hasFile = "1".equals(r.get("has_" + d[0]));
                     String stCls = "Verified".equals(st) ? "vd-b-verified" : ("Rejected".equals(st) ? "vd-b-rejected" : "vd-b-pending");
                %>
                  <tr class="vd-doc" data-doc="<%= d[0] %>" data-has-file="<%= hasFile ? "1" : "0" %>">
                    <td><strong><%= esc(d[1]) %></strong></td>
                    <td>
                      <% if (hasFile) { %>
                        <a class="vd-view-link" target="_blank"
                           href="ScholarshipDocumentDownloadServlet?id=<%= esc(id) %>&field=<%= d[3] %>">View &#8599;</a>
                      <% } else { %>
                        <span class="vd-none">Not uploaded</span>
                      <% } %>
                    </td>
                    <td class="vd-doc-status">
                      <span class="vd-badge <%= stCls %>"><%= esc(st) %></span>
                      <% if ("Rejected".equals(st) && rm != null && !rm.isEmpty()) { %>
                        <div class="vd-remarks"><%= esc(rm) %></div>
                      <% } %>
                    </td>
                    <td>
                      <% if (locked) { %>
                        <span class="vd-locked">Locked (application <%= esc(finalStatus) %>)</span>
                      <% } else { %>
                      <div class="vd-doc-actions">
                        <button type="button" class="vd-btn vd-btn-ok vd-act" data-status="Verified"
                                <%= (!hasFile || "Verified".equals(st)) ? "disabled" : "" %>
                                title="<%= hasFile ? "" : "Not uploaded" %>">&#10003; Verify</button>
                        <button type="button" class="vd-btn vd-btn-bad vd-open-reject"
                                <%= "Rejected".equals(st) ? "disabled" : "" %>>&#10007; Reject</button>
                        <button type="button" class="vd-btn vd-btn-outline vd-act" data-status="Pending"
                                <%= "Pending".equals(st) ? "style=\"display:none;\"" : "" %>>Reset</button>
                      </div>
                      <div class="vd-reject-box">
                        <input type="text" class="vd-reason" maxlength="300" placeholder="Reason for rejection (required)">
                        <button type="button" class="vd-btn vd-btn-bad vd-act" data-status="Rejected">Confirm Reject</button>
                        <button type="button" class="vd-btn vd-btn-outline vd-close-reject">Cancel</button>
                      </div>
                      <% } %>
                    </td>
                  </tr>
                <% } %>
                </tbody>
              </table>
              <div class="vd-meta">
                Last updated by: <span class="vd-by"><%= esc(r.get("verifiedBy") == null ? "-" : r.get("verifiedBy")) %></span>
                <span class="vd-at"><%= r.get("verifiedAt") == null ? "" : "on " + esc(r.get("verifiedAt")) %></span>
              </div>
            </td>
          </tr>
        <%   }
           } %>
          <tr id="noMatchRow" style="display:none;"><td colspan="10" class="vd-empty">No applications match the filter.</td></tr>
        </tbody>
      </table>
    </div>
  </div>
</div>

<script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
<script>
$(function () {
  var TOTAL = <%= totalDocs %>;

  function showToast(ok, text) {
    var $t = $('#vdToast');
    $t.removeClass('vd-alert-ok vd-alert-err').addClass(ok ? 'vd-alert-ok' : 'vd-alert-err').text(text).stop(true, true).fadeIn(150);
    clearTimeout($t.data('timer'));
    $t.data('timer', setTimeout(function () { $t.fadeOut(300); }, 3500));
  }

  function badgeClass(st) {
    return st === 'Verified' || st === 'All Verified' ? 'vd-b-verified'
         : (st === 'Rejected' || st === 'Has Rejected' ? 'vd-b-rejected' : 'vd-b-pending');
  }

  function recount() {
    var c = { 'Pending': 0, 'All Verified': 0, 'Has Rejected': 0 };
    $('tr.vd-app').each(function () { c[$(this).attr('data-status')]++; });
    $('#cntPending').text(c['Pending']);
    $('#cntAll').text(c['All Verified']);
    $('#cntRejected').text(c['Has Rejected']);
  }

  // Expand / collapse document panel
  $(document).on('click', '.vd-toggle', function () {
    var $app = $(this).closest('tr.vd-app');
    var $detail = $('tr.vd-detail[data-for="' + $app.attr('data-id') + '"]');
    var open = !$detail.is(':visible');
    $detail.toggle(open);
    $app.toggleClass('vd-open', open);
    $(this).html(open ? 'Close &#9652;' : 'Verify &#9662;');
  });

  // Reject: show reason box
  $(document).on('click', '.vd-open-reject', function () {
    var $doc = $(this).closest('tr.vd-doc');
    $doc.find('.vd-doc-actions').hide();
    $doc.find('.vd-reject-box').css('display', 'flex').find('.vd-reason').val('').trigger('focus');
  });
  $(document).on('click', '.vd-close-reject', function () {
    var $doc = $(this).closest('tr.vd-doc');
    $doc.find('.vd-reject-box').hide();
    $doc.find('.vd-doc-actions').css('display', 'flex');
  });
  $(document).on('keydown', '.vd-reason', function (e) {
    if (e.key === 'Enter') { e.preventDefault(); $(this).siblings('.vd-act').trigger('click'); }
  });

  // Verify / Reject / Reset one document (AJAX, no page reload)
  $(document).on('click', '.vd-act', function () {
    var $btn = $(this), $doc = $btn.closest('tr.vd-doc'), $detail = $doc.closest('tr.vd-detail');
    var id = $detail.attr('data-for'), status = $btn.attr('data-status');
    var remarks = status === 'Rejected' ? $.trim($doc.find('.vd-reason').val()) : '';

    if (status === 'Rejected' && remarks === '') {
      showToast(false, 'Please enter a reason for rejecting.');
      $doc.find('.vd-reason').trigger('focus');
      return;
    }

    var label = $btn.html();
    $doc.find('.vd-btn').prop('disabled', true);
    $btn.addClass('vd-busy').text('Saving...');

    $.ajax({
      url: 'VerifyDocumentsServlet',
      type: 'POST',
      dataType: 'json',
      data: { id: id, doc: $doc.attr('data-doc'), status: status, remarks: remarks }
    }).done(function (res) {
      if (!res.ok) { showToast(false, res.message); return; }

      // Document status cell
      var $cell = $doc.find('.vd-doc-status').empty()
          .append($('<span class="vd-badge"></span>').addClass(badgeClass(res.status)).text(res.status));
      if (res.status === 'Rejected' && res.remarks) $cell.append($('<div class="vd-remarks"></div>').text(res.remarks));

      $doc.find('.vd-reject-box').hide();
      $doc.find('.vd-doc-actions').css('display', 'flex');
      $doc.addClass('vd-flash');
      setTimeout(function () { $doc.removeClass('vd-flash'); }, 1200);

      // Application summary row
      var $app = $('tr.vd-app[data-id="' + id + '"]');
      $app.attr('data-status', res.docsStatus);
      $app.find('.vd-bar-ok').css('width', (res.verified * 100 / TOTAL) + '%');
      $app.find('.vd-bar-bad').css('width', (res.rejected * 100 / TOTAL) + '%');
      $app.find('.vd-progress-txt').text(res.verified + '/' + TOTAL + ' verified');
      $app.find('.vd-app-status .vd-badge').first()
          .removeClass('vd-b-pending vd-b-verified vd-b-rejected').addClass(badgeClass(res.docsStatus)).text(res.docsStatus);
      $detail.find('.vd-by').text(res.verifiedBy || '-');
      $detail.find('.vd-at').text(res.verifiedAt ? 'on ' + res.verifiedAt : '');

      recount();
      showToast(true, res.message);
    }).fail(function (xhr) {
      var msg = (xhr.responseJSON && xhr.responseJSON.message) ? xhr.responseJSON.message : 'Could not save. Please try again.';
      showToast(false, msg);
    }).always(function () {
      $btn.removeClass('vd-busy').html(label);
      // Re-enable buttons according to the current status
      var st = $doc.find('.vd-doc-status .vd-badge').text();
      var hasFile = $doc.attr('data-has-file') === '1';
      $doc.find('.vd-btn').prop('disabled', false);
      $doc.find('.vd-act[data-status="Verified"]').prop('disabled', !hasFile || st === 'Verified');
      $doc.find('.vd-open-reject').prop('disabled', st === 'Rejected');
      $doc.find('.vd-act[data-status="Pending"]').toggle(st !== 'Pending');
    });
  });

  // Filters (organization / status / search)
  function applyFilters() {
    var org = $('#orgFilter').val(), status = $('#statusFilter').val(), q = $.trim($('#searchBox').val()).toLowerCase();
    var visible = 0, $apps = $('tr.vd-app');
    $apps.each(function () {
      var $tr = $(this);
      var ok = (org === 'ALL' || $tr.attr('data-org') === org)
            && (status === 'ALL' || $tr.attr('data-status') === status)
            && (q === '' || $tr.attr('data-search').indexOf(q) !== -1);
      $tr.toggle(ok);
      var $detail = $('tr.vd-detail[data-for="' + $tr.attr('data-id') + '"]');
      if (!ok) $detail.hide(); else if ($tr.hasClass('vd-open')) $detail.show();
      if (ok) visible++;
    });
    $('#noMatchRow').toggle($apps.length > 0 && visible === 0);
  }
  $('#orgFilter, #statusFilter').on('change', applyFilters);
  $('#searchBox').on('keyup', applyFilters);
});
</script>

</body>
</html>
