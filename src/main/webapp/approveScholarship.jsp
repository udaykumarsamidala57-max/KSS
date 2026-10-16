<%@page import="java.util.List"%>
<%@page import="java.util.Map"%>
<%@page import="java.util.Set"%>
<%@page import="java.util.TreeSet"%>
<%@page import="java.util.Locale"%>
<%@page import="java.text.NumberFormat"%>
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
    private static String money(String v) {
        if (v == null || v.trim().isEmpty()) return "-";
        try {
            NumberFormat nf = NumberFormat.getNumberInstance(new Locale("en", "IN"));
            nf.setMinimumFractionDigits(2);
            nf.setMaximumFractionDigits(2);
            return "&#8377; " + nf.format(Double.parseDouble(v));
        } catch (Exception e) { return esc(v); }
    }
    private static String plain(String v) {
        if (v == null || v.trim().isEmpty()) return "";
        try { return new java.math.BigDecimal(v).setScale(2, java.math.RoundingMode.HALF_UP).toPlainString(); }
        catch (Exception e) { return ""; }
    }
%>
<%
    // Must be opened through ApproveScholarshipServlet (loads data + checks Global role)
    @SuppressWarnings("unchecked")
    List<Map<String, String>> rows = (List<Map<String, String>>) request.getAttribute("rows");
    if (rows == null) {
        response.sendRedirect("ApproveScholarshipServlet");
        return;
    }
    String loadError = (String) request.getAttribute("error");
    Integer waiting = (Integer) request.getAttribute("waitingForVerification");

    Set<String> orgs = new TreeSet<String>();
    int cntPending = 0, cntApproved = 0, cntRejected = 0;
    for (Map<String, String> r : rows) {
        String o = r.get("orgName");
        orgs.add(o == null || o.trim().isEmpty() ? "Uncategorized" : o.trim());
        String fs = r.get("finalStatus");
        if ("Approved".equals(fs)) cntApproved++; else if ("Rejected".equals(fs)) cntRejected++; else cntPending++;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Approve Scholarship</title>

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
    --ok: #137333;  --ok-bg: #e6f4ea;  --ok-bd: #ceead6;
    --bad: #c5221f; --bad-bg: #fce8e6; --bad-bd: #fad2cf;
  }
  body { background: var(--bg-page); color: var(--text-main);
         font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Arial, sans-serif; }

  .as-page { padding: 20px 24px; }
  .as-header { display: flex; flex-wrap: wrap; justify-content: space-between; align-items: flex-end; gap: 12px; margin-bottom: 14px; }
  .as-subtitle { font-size: 12px; text-transform: uppercase; letter-spacing: .5px; color: var(--text-muted); }
  .as-title { margin: 2px 0 0; font-size: 22px; color: var(--brand-primary); }
  .as-summary { margin-top: 4px; font-size: 13px; color: var(--text-muted); }
  .as-summary b { color: var(--brand-primary); }

  .as-controls { display: flex; flex-wrap: wrap; gap: 10px; align-items: center; }
  .as-controls label { font-size: 12px; font-weight: 600; color: var(--text-muted); }
  .as-controls select, .as-controls input { height: 32px; padding: 0 10px; border: 1px solid var(--brand-border);
      border-radius: var(--radius); background: #fff; font-size: 13px; }
  .as-controls input { width: 220px; }
  .as-controls select:focus, .as-controls input:focus { outline: none; border-color: var(--brand-primary); }

  .as-alert { padding: 10px 14px; border-radius: var(--radius); margin-bottom: 14px; font-size: 13px; }
  .as-alert-ok  { background: var(--ok-bg); color: var(--ok); border: 1px solid var(--ok-bd); }
  .as-alert-err { background: var(--bad-bg); color: var(--bad); border: 1px solid var(--bad-bd); }
  .as-alert-info { background: var(--brand-accent-bg); color: var(--brand-primary); border: 1px solid var(--brand-border); }
  #asToast { position: sticky; top: 8px; z-index: 50; box-shadow: var(--card-shadow); }

  .as-card { background: var(--bg-card); border: 1px solid var(--brand-border); border-radius: var(--radius);
             box-shadow: var(--card-shadow); overflow: hidden; }
  .as-table-wrap { overflow-x: auto; }
  table.as-table { width: 100%; border-collapse: collapse; font-size: 13px; }
  .as-table th { background: var(--table-header-bg); color: var(--brand-primary); text-align: left; font-size: 11px;
      text-transform: uppercase; letter-spacing: .4px; padding: 10px; border-bottom: 1px solid var(--brand-border); white-space: nowrap; }
  .as-table td { padding: 9px 10px; border-bottom: 1px solid #f1e6e8; vertical-align: middle; }
  .as-table tr.as-app:hover > td { background: var(--row-hover); }
  .as-table tr.as-app.as-open > td { background: var(--brand-accent-bg); border-bottom-color: transparent; }
  .as-table tr.as-app.as-flash > td { background: #fdf0f3; transition: background .6s; }
  .as-num { text-align: right; white-space: nowrap; }
  .as-small { font-size: 11px; color: var(--text-muted); }
  .as-remarks { font-size: 12px; color: var(--text-muted); }
  .as-remarks.bad { color: var(--bad); }

  .as-badge { display: inline-block; padding: 2px 9px; font-size: 10px; font-weight: 700; letter-spacing: .3px;
              text-transform: uppercase; border-radius: 10px; white-space: nowrap; border: 1px solid; }
  .as-b-pending  { color: var(--brand-primary); background: var(--brand-accent-bg); border-color: var(--brand-border-dark);
                   box-shadow: 0 1px 4px rgba(122, 31, 53, 0.15); }
  .as-b-approved { color: var(--ok); background: var(--ok-bg); border-color: var(--ok-bd); }
  .as-b-rejected { color: var(--bad); background: var(--bad-bg); border-color: var(--bad-bd); }
  .as-b-muted    { color: var(--text-muted); background: #f3f3f3; border-color: #dcdcdc; }
  .as-amount { font-weight: 700; color: var(--ok); margin-top: 3px; }

  .as-btn { height: 28px; padding: 0 11px; border-radius: var(--radius); font-size: 12px; font-weight: 600; cursor: pointer;
            border: 1px solid var(--brand-primary); background: var(--brand-primary); color: #fff; white-space: nowrap; }
  .as-btn:hover { background: var(--brand-primary-dark); }
  .as-btn:disabled { opacity: .45; cursor: default; }
  .as-btn-outline { background: #fff; color: var(--brand-primary); border-color: var(--brand-border-dark);
                    box-shadow: 0 1px 4px rgba(122, 31, 53, 0.15); }
  .as-btn-outline:hover { background: var(--brand-accent-bg); border-color: var(--brand-primary); }
  .as-btn-ok  { background: #fff; color: var(--ok); border-color: var(--ok-bd); }
  .as-btn-ok:hover  { background: var(--ok-bg); border-color: var(--ok); }
  .as-btn-bad { background: #fff; color: var(--bad); border-color: var(--bad-bd); }
  .as-btn-bad:hover { background: var(--bad-bg); border-color: var(--bad); }
  .as-btn.as-busy { opacity: .6; cursor: progress; }
  .as-actions { display: flex; gap: 6px; flex-wrap: wrap; }

  .as-panel > td { padding: 0 10px 14px 10px; background: var(--brand-accent-bg); border-bottom: 1px solid var(--brand-border); }
  .as-form { display: flex; flex-wrap: wrap; gap: 10px; align-items: flex-end; background: #fff; border: 1px solid var(--brand-border);
             border-radius: var(--radius); padding: 12px; }
  .as-field { display: flex; flex-direction: column; gap: 4px; }
  .as-field label { font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: .3px; color: var(--text-muted); }
  .as-field input { height: 30px; padding: 0 8px; border: 1px solid var(--brand-border); border-radius: var(--radius); font-size: 13px; }
  .as-field input:focus { outline: none; border-color: var(--brand-primary); }
  .as-field .as-amount-in { width: 160px; text-align: right; }
  .as-field .as-remarks-in { width: 340px; }
  .as-form-title { width: 100%; font-weight: 700; font-size: 13px; }
  .as-form-title.ok { color: var(--ok); } .as-form-title.bad { color: var(--bad); } .as-form-title.rev { color: var(--brand-primary); }

  .as-empty { text-align: center; color: var(--text-muted); padding: 40px; }
</style>
</head>
<body>

<div class="as-page">

  <div class="as-header">
    <div>
      <div class="as-subtitle">Approvals &rsaquo; Step 3</div>
      <h1 class="as-title">Approve Scholarship</h1>
      <div class="as-summary">
        Ready: <b><%= rows.size() %></b> &nbsp;|&nbsp;
        Pending: <b id="cntPending"><%= cntPending %></b> &nbsp;|&nbsp;
        Approved: <b id="cntApproved"><%= cntApproved %></b> &nbsp;|&nbsp;
        Rejected: <b id="cntRejected"><%= cntRejected %></b>
      </div>
    </div>

    <div class="as-controls">
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
        <option value="Approved">Approved</option>
        <option value="Rejected">Rejected</option>
      </select>

      <input type="text" id="searchBox" placeholder="Search App No / Emp / Child">
    </div>
  </div>

  <% if (loadError != null) { %>
    <div class="as-alert as-alert-err"><%= esc(loadError) %></div>
  <% } %>
  <% if (waiting != null && waiting > 0) { %>
    <div class="as-alert as-alert-info">
      <%= waiting %> application<%= waiting == 1 ? " is" : "s are" %> still waiting for
      <a href="VerifyDocumentsServlet" style="color:inherit;font-weight:700;">Step 2 : Verify Documents</a>
      (all <%= com.Controller.VerifyDocumentsServlet.DOCS.size() %> documents must be verified) and not shown here yet.
    </div>
  <% } %>

  <div id="asToast" class="as-alert" style="display:none;"></div>

  <div class="as-card">
    <div class="as-table-wrap">
      <table class="as-table">
        <thead>
          <tr>
            <th>#</th>
            <th>App No</th>
            <th>Organization</th>
            <th>Emp No</th>
            <th>Emp Name</th>
            <th>Child Name</th>
            <th>KSS Course</th>
            <th>College / Course</th>
            <th class="as-num">Prev %</th>
            <th class="as-num">Fee (AY)</th>
            <th class="as-num">Actual Paid</th>
            <th>Decision</th>
            <th>Action</th>
          </tr>
        </thead>
        <tbody>
        <% if (rows.isEmpty()) { %>
          <tr><td colspan="13" class="as-empty">No applications with all documents verified yet.</td></tr>
        <% } else {
             int n = 0;
             for (Map<String, String> r : rows) {
               String org = r.get("orgName");
               org = (org == null || org.trim().isEmpty()) ? "Uncategorized" : org.trim();
               String id = r.get("id");
               String fs = r.get("finalStatus") == null ? "Pending" : r.get("finalStatus");
               String reimb = r.get("reimbursementStatus");
               boolean reimbursed = "Reimbursed".equalsIgnoreCase(reimb);
               String bcls = "Approved".equals(fs) ? "as-b-approved" : ("Rejected".equals(fs) ? "as-b-rejected" : "as-b-pending");

               StringBuilder sb = new StringBuilder();
               for (String key : new String[]{"appNo", "empNo", "empName", "childName"}) {
                   String val = r.get(key);
                   if (val != null) sb.append(val).append(' ');
               }
        %>
          <tr class="as-app" data-id="<%= esc(id) %>" data-org="<%= esc(org) %>" data-status="<%= esc(fs) %>"
              data-search="<%= esc(sb.toString().toLowerCase()) %>" data-default-amount="<%= plain(r.get("actualFeePaid")) %>">
            <td><%= ++n %></td>
            <td><strong><%= esc(r.get("appNo")) %></strong></td>
            <td><%= esc(org) %></td>
            <td><%= esc(r.get("empNo")) %></td>
            <td><%= esc(r.get("empName")) %></td>
            <td><%= esc(r.get("childName")) %></td>
            <td><span class="as-badge as-b-pending"><%= esc(r.get("kssCourse")) %></span></td>
            <td>
              <%= esc(r.get("college")) %>
              <div class="as-small"><%= esc(r.get("course")) %><%= r.get("presentYear") != null ? " &middot; " + esc(r.get("presentYear")) : "" %></div>
            </td>
            <td class="as-num"><%= r.get("percentage") == null ? "-" : esc(r.get("percentage")) %></td>
            <td class="as-num"><%= money(r.get("feeAmount")) %></td>
            <td class="as-num"><%= money(r.get("actualFeePaid")) %></td>
            <td class="as-decision">
              <span class="as-badge <%= bcls %>"><%= esc(fs) %></span>
              <% if ("Approved".equals(fs)) { %><div class="as-amount"><%= money(r.get("approvedAmount")) %></div><% } %>
              <% if (r.get("finalRemarks") != null && !r.get("finalRemarks").isEmpty()) { %>
                <div class="as-remarks <%= "Rejected".equals(fs) ? "bad" : "" %>"><%= esc(r.get("finalRemarks")) %></div>
              <% } %>
              <% if (r.get("approvedBy") != null && !"Pending".equals(fs)) { %>
                <div class="as-small">by <%= esc(r.get("approvedBy")) %><%= r.get("approvedAt") != null ? " on " + esc(r.get("approvedAt")) : "" %></div>
              <% } %>
              <% if (reimbursed) { %><span class="as-badge as-b-muted" style="margin-top:3px;">Reimbursed</span><% } %>
            </td>
            <td class="as-action">
              <% if (reimbursed) { %>
                <span class="as-small">Locked (reimbursed)</span>
              <% } else if ("Pending".equals(fs)) { %>
                <div class="as-actions">
                  <button type="button" class="as-btn as-btn-ok as-open" data-mode="Approved">&#10003; Approve</button>
                  <button type="button" class="as-btn as-btn-bad as-open" data-mode="Rejected">&#10007; Reject</button>
                </div>
              <% } else { %>
                <div class="as-actions">
                  <button type="button" class="as-btn as-btn-outline as-open" data-mode="Pending">&#8634; Revert</button>
                </div>
              <% } %>
            </td>
          </tr>
          <tr class="as-panel" data-for="<%= esc(id) %>" style="display:none;"><td colspan="13"></td></tr>
        <%   }
           } %>
          <tr id="noMatchRow" style="display:none;"><td colspan="13" class="as-empty">No applications match the filter.</td></tr>
        </tbody>
      </table>
    </div>
  </div>
</div>

<script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
<script>
$(function () {

  function showToast(ok, text) {
    var $t = $('#asToast');
    $t.removeClass('as-alert-ok as-alert-err').addClass(ok ? 'as-alert-ok' : 'as-alert-err').text(text).stop(true, true).fadeIn(150);
    clearTimeout($t.data('timer'));
    $t.data('timer', setTimeout(function () { $t.fadeOut(300); }, 3500));
  }

  function money(v) {
    if (v === null || v === undefined || v === '') return '-';
    return String.fromCharCode(8377) + ' ' + Number(v).toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  }

  function closePanel($app) {
    $('tr.as-panel[data-for="' + $app.attr('data-id') + '"]').hide().children('td').empty();
    $app.removeClass('as-open');
  }

  function recount() {
    var c = { Pending: 0, Approved: 0, Rejected: 0 };
    $('tr.as-app').each(function () { c[$(this).attr('data-status')]++; });
    $('#cntPending').text(c.Pending); $('#cntApproved').text(c.Approved); $('#cntRejected').text(c.Rejected);
  }

  // Open the Approve / Reject / Revert form under the row
  $(document).on('click', '.as-open', function () {
    var mode = $(this).attr('data-mode'), $app = $(this).closest('tr.as-app');
    var $panel = $('tr.as-panel[data-for="' + $app.attr('data-id') + '"]');
    $('tr.as-app.as-open').not($app).each(function () { closePanel($(this)); });

    var $f = $('<div class="as-form"></div>');
    if (mode === 'Approved') {
      $f.append('<div class="as-form-title ok">Approve scholarship</div>')
        .append($('<div class="as-field"><label>Approved amount (&#8377;)</label><input type="number" min="1" step="0.01" class="as-amount-in"></div>'))
        .append('<div class="as-field"><label>Remarks (optional)</label><input type="text" maxlength="500" class="as-remarks-in"></div>')
        .append('<button type="button" class="as-btn as-save" data-decision="Approved">Confirm Approve</button>');
      $f.find('.as-amount-in').val($app.attr('data-default-amount'));
    } else if (mode === 'Rejected') {
      $f.append('<div class="as-form-title bad">Reject scholarship</div>')
        .append('<div class="as-field"><label>Reason for rejection (required)</label><input type="text" maxlength="500" class="as-remarks-in"></div>')
        .append('<button type="button" class="as-btn as-btn-bad as-save" data-decision="Rejected">Confirm Reject</button>');
    } else {
      $f.append('<div class="as-form-title rev">Revert decision back to Pending</div>')
        .append('<div class="as-field"><label>Reason (optional)</label><input type="text" maxlength="500" class="as-remarks-in"></div>')
        .append('<button type="button" class="as-btn as-save" data-decision="Pending">Confirm Revert</button>');
    }
    $f.append('<button type="button" class="as-btn as-btn-outline as-cancel">Cancel</button>');

    $panel.children('td').empty().append($f);
    $panel.show();
    $app.addClass('as-open');
    $f.find('input').first().trigger('focus');
  });

  $(document).on('click', '.as-cancel', function () {
    var id = $(this).closest('tr.as-panel').attr('data-for');
    closePanel($('tr.as-app[data-id="' + id + '"]'));
  });

  $(document).on('keydown', '.as-form input', function (e) {
    if (e.key === 'Enter') { e.preventDefault(); $(this).closest('.as-form').find('.as-save').trigger('click'); }
  });

  // Save decision (AJAX, no page reload)
  $(document).on('click', '.as-save', function () {
    var $btn = $(this), $form = $btn.closest('.as-form'), $panel = $btn.closest('tr.as-panel');
    var id = $panel.attr('data-for'), $app = $('tr.as-app[data-id="' + id + '"]');
    var decision = $btn.attr('data-decision');
    var amount = $.trim($form.find('.as-amount-in').val() || '');
    var remarks = $.trim($form.find('.as-remarks-in').val() || '');

    if (decision === 'Approved' && !(Number(amount) > 0)) { showToast(false, 'Please enter a valid approved amount.'); return; }
    if (decision === 'Rejected' && remarks === '') { showToast(false, 'Please enter a reason for rejecting.'); return; }

    var label = $btn.text();
    $form.find('.as-btn').prop('disabled', true);
    $btn.addClass('as-busy').text('Saving...');

    $.ajax({
      url: 'ApproveScholarshipServlet', type: 'POST', dataType: 'json',
      data: { id: id, decision: decision, amount: amount, remarks: remarks }
    }).done(function (res) {
      if (!res.ok) { showToast(false, res.message); return; }

      var fs = res.finalStatus;
      var cls = fs === 'Approved' ? 'as-b-approved' : (fs === 'Rejected' ? 'as-b-rejected' : 'as-b-pending');
      var $d = $app.find('.as-decision').empty().append($('<span class="as-badge"></span>').addClass(cls).text(fs));
      if (fs === 'Approved') $d.append($('<div class="as-amount"></div>').text(money(res.amount)));
      if (res.remarks) $d.append($('<div class="as-remarks"></div>').toggleClass('bad', fs === 'Rejected').text(res.remarks));
      if (res.by) $d.append($('<div class="as-small"></div>').text('by ' + res.by + (res.at ? ' on ' + res.at : '')));

      var $a = $app.find('.as-action').empty(), $wrap = $('<div class="as-actions"></div>');
      if (fs === 'Pending') {
        $wrap.append('<button type="button" class="as-btn as-btn-ok as-open" data-mode="Approved">&#10003; Approve</button>')
             .append('<button type="button" class="as-btn as-btn-bad as-open" data-mode="Rejected">&#10007; Reject</button>');
      } else {
        $wrap.append('<button type="button" class="as-btn as-btn-outline as-open" data-mode="Pending">&#8634; Revert</button>');
      }
      $a.append($wrap);

      $app.attr('data-status', fs);
      closePanel($app);
      $app.addClass('as-flash');
      setTimeout(function () { $app.removeClass('as-flash'); }, 1200);
      recount();
      showToast(true, res.message);
    }).fail(function (xhr) {
      showToast(false, (xhr.responseJSON && xhr.responseJSON.message) ? xhr.responseJSON.message : 'Could not save. Please try again.');
    }).always(function () {
      $btn.removeClass('as-busy').text(label);
      $form.find('.as-btn').prop('disabled', false);
    });
  });

  // Filters
  function applyFilters() {
    var org = $('#orgFilter').val(), status = $('#statusFilter').val(), q = $.trim($('#searchBox').val()).toLowerCase();
    var visible = 0, $apps = $('tr.as-app');
    $apps.each(function () {
      var $tr = $(this);
      var ok = (org === 'ALL' || $tr.attr('data-org') === org)
            && (status === 'ALL' || $tr.attr('data-status') === status)
            && (q === '' || $tr.attr('data-search').indexOf(q) !== -1);
      $tr.toggle(ok);
      if (!ok && $tr.hasClass('as-open')) closePanel($tr);
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
