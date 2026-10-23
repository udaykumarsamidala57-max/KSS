<%@page import="java.util.List"%>
<%@page import="java.util.Map"%>
<%
    // Must be opened through CsrWorkOrderServlet (loads data + checks Global role)
    if (request.getAttribute("rows") == null) {
        response.sendRedirect("CsrWorkOrderServlet");
        return;
    }
    com.google.gson.Gson gson = new com.google.gson.Gson();   // escapes < > & : safe inside <script>
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>KSS CSR Work Orders</title>

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
      <div class="csr-subtitle">KSS CSR Amount Spending &rsaquo; Step 2</div>
      <h1 class="csr-title">Work Orders</h1>
    </div>
    <div class="csr-stats">
      <div class="csr-stat"><div class="csr-stat-label">Work Orders</div><div class="csr-stat-value" id="statCount">0</div></div>
      <div class="csr-stat"><div class="csr-stat-label" id="statApprovedLabel">Approved (letters)</div><div class="csr-stat-value" id="statApproved">-</div></div>
      <div class="csr-stat"><div class="csr-stat-label">Work Order Total</div><div class="csr-stat-value" id="statTotal">-</div></div>
      <div class="csr-stat"><div class="csr-stat-label">Balance</div><div class="csr-stat-value" id="statBalance">-</div></div>
    </div>
  </div>

  <div id="csrError" class="csr-alert csr-alert-err" style="display:none;"></div>
  <div id="csrToast" class="csr-alert" style="display:none;"></div>

  <div class="csr-card">
    <div class="csr-card-head">
      <div class="csr-card-title">Work Orders <small id="listCount"></small></div>
      <div class="csr-controls">
        <select id="letterFilter"><option value="ALL">All Approval Letters</option></select>
        <input type="text" id="searchBox" placeholder="Search WO no / vendor / letter">
        <a href="CsrLetterServlet" class="csr-btn csr-btn-outline csr-link-btn">&#8592; Back to Approval Letters</a>
        <a href="CsrWorkOrderServlet?action=form" class="csr-btn csr-link-btn" id="btnNew">+ New Work Order</a>
      </div>
    </div>
    <div class="csr-table-wrap">
      <table class="csr-table">
        <thead>
          <tr>
            <th>#</th>
            <th>WO No / Date</th>
            <th>Approval Letter</th>
            <th>Vendor</th>
            <th>Particulars</th>
            <th class="csr-num">Price</th>
            <th class="csr-num">GST</th>
            <th class="csr-num">Total</th>
            <th>Attachment</th>
            <th>Invoices</th>
            <th>Action</th>
          </tr>
        </thead>
        <tbody id="woBody"></tbody>
        <tfoot>
          <tr class="csr-total-row" id="totalRow">
            <td colspan="5">Total (shown)</td>
            <td class="csr-num" id="sumPrice">-</td>
            <td class="csr-num" id="sumGst">-</td>
            <td class="csr-num" id="sumTotal">-</td>
            <td colspan="3"></td>
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
  var itemsByWo = <%= gson.toJson(request.getAttribute("itemsByWo")) %>;
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

  // letter filter
  letters.forEach(function (l) {
    $('#letterFilter').append($('<option></option>').attr('value', l.id).text(l.letterNumber + ' - ' + l.letterName));
  });
  if (preset && byId(letters, preset) !== -1) $('#letterFilter').val(preset);

  function rowHtml(r, n) {
    var $tr = $('<tr class="csr-row wo-row"></tr>').attr('data-id', r.id);
    $tr.append($('<td></td>').text(n));
    $tr.append($('<td></td>')
      .append($('<div class="csr-strong"></div>').text(r.woNumber))
      .append($('<div class="csr-small"></div>').text(r.woDateTxt)));
    $tr.append($('<td></td>')
      .append($('<div class="csr-strong"></div>').text(r.letterNumber))
      .append($('<div class="csr-small"></div>').text(r.letterName))
      .append($('<span class="csr-badge"></span>').text(r.activityKind)));
    var $v = $('<td></td>').append($('<div class="csr-strong"></div>').text(r.vendorName));
    if (r.vendorPhone) $v.append($('<div class="csr-small"></div>').text(r.vendorPhone));
    if (r.vendorEmail) $v.append($('<div class="csr-small"></div>').text(r.vendorEmail));
    if (r.vendorGstin) $v.append($('<div class="csr-small"></div>').text('GSTIN ' + r.vendorGstin));
    $tr.append($v);
    var items = itemsByWo[r.id] || [];
    var $p = $('<td></td>');
    if (items.length) $p.append($('<div class="csr-ellipsis"></div>').text(items[0].particulars));
    $p.append($('<button type="button" class="csr-linklike js-items"></button>')
      .text(items.length + ' line' + (items.length === 1 ? '' : 's') + ' - show'));
    $tr.append($p);
    $tr.append($('<td class="csr-num"></td>').text(money(r.subtotal)));
    $tr.append($('<td class="csr-num"></td>').text(money(r.gstTotal)));
    $tr.append($('<td class="csr-num csr-strong"></td>').text(money(r.total)));
    var $a = $('<td></td>');
    if (r.attachmentSize) {
      $a.append($('<a class="csr-pdf" target="_blank"></a>').attr('href', 'CsrWorkOrderServlet?action=file&id=' + r.id).html('&#128206; View'))
        .append($('<div class="csr-small"></div>').text(kb(r.attachmentSize)));
    } else {
      $a.append('<span class="csr-small">None</span>');
    }
    $tr.append($a);
    var invCount = parseInt(r.invCount, 10) || 0, invBal = Number(r.total) - Number(r.invoiced || 0);
    var $inv = $('<td class="csr-wo-cell"></td>');
    if (invCount) {
      $inv.append($('<a class="csr-strong" style="color:inherit"></a>').attr('href', 'CsrInvoiceServlet?woId=' + r.id)
                    .text(invCount + ' invoice' + (invCount === 1 ? '' : 's') + ': ' + money(r.invoiced)));
    } else {
      $inv.append('<div class="csr-small">No invoices</div>');
    }
    $inv.append($('<div class="csr-small"></div>').append('Balance ').append($('<b></b>').text(money(invBal)).toggleClass('csr-neg', invBal < 0)));
    $tr.append($inv);
    $tr.append($('<td></td>').append(
      $('<div class="csr-actions"></div>')
        .append($('<a class="csr-btn csr-btn-sm csr-link-btn">+ Invoice</a>').attr('href', 'CsrInvoiceServlet?action=form&woId=' + r.id).attr('title', 'New invoice against this work order'))
        .append($('<a class="csr-btn csr-btn-sm csr-btn-outline csr-link-btn">&#9998; Edit</a>').attr('href', 'CsrWorkOrderServlet?action=form&id=' + r.id))
        .append('<button type="button" class="csr-btn csr-btn-sm csr-btn-bad js-del">Delete</button>')));
    return $tr;
  }

  function itemsRow(r) {
    var $t = $('<table class="csr-subtable"></table>')
      .append('<thead><tr><th>#</th><th>Particulars</th><th class="csr-num">Price</th><th class="csr-num">GST %</th><th class="csr-num">GST</th><th class="csr-num">Amount</th></tr></thead>');
    var $b = $('<tbody></tbody>');
    (itemsByWo[r.id] || []).forEach(function (it, i) {
      $b.append($('<tr></tr>')
        .append($('<td></td>').text(i + 1))
        .append($('<td></td>').text(it.particulars))
        .append($('<td class="csr-num"></td>').text(money(it.price)))
        .append($('<td class="csr-num"></td>').text(it.gst + ' %'))
        .append($('<td class="csr-num"></td>').text(money(it.gstAmount)))
        .append($('<td class="csr-num csr-strong"></td>').text(money(it.amount))));
    });
    $t.append($b);
    var addr = r.vendorAddress ? $('<div class="csr-small" style="margin-top:6px"></div>').text('Vendor address: ' + r.vendorAddress) : '';
    return $('<tr class="wo-items" style="display:none;"></tr>').attr('data-for', r.id)
      .append($('<td colspan="11"></td>').append($t).append(addr));
  }

  function render() {
    var lf = $('#letterFilter').val(), q = $.trim($('#searchBox').val()).toLowerCase();
    var $body = $('#woBody').empty(), n = 0, sp = 0, sg = 0, st = 0;
    rows.forEach(function (r) {
      var hay = [r.woNumber, r.vendorName, r.vendorGstin, r.letterNumber, r.letterName, r.activityKind].join(' ').toLowerCase();
      if ((lf === 'ALL' || String(r.letterId) === String(lf)) && (q === '' || hay.indexOf(q) !== -1)) {
        $body.append(rowHtml(r, ++n)).append(itemsRow(r));
        sp += Number(r.subtotal); sg += Number(r.gstTotal); st += Number(r.total);
      }
    });
    if (n === 0) {
      $body.append('<tr><td colspan="11" class="csr-empty">' + (rows.length ? 'No work orders match the filter.'
        : 'No work orders yet. Click <b>+ New Work Order</b> to create the first one.') + '</td></tr>');
    }
    $('#sumPrice').text(money(sp)); $('#sumGst').text(money(sg)); $('#sumTotal').text(money(st));
    $('#totalRow').toggle(n > 0);
    $('#listCount').text('(' + n + (n !== rows.length ? ' of ' + rows.length : '') + ')');

    // tiles: for one letter or for all letters
    var approved = 0, committed = 0;
    letters.forEach(function (l) {
      if (lf === 'ALL' || String(l.id) === String(lf)) { approved += Number(l.amount); committed += Number(l.committed); }
    });
    $('#statCount').text(n);
    $('#statApprovedLabel').text(lf === 'ALL' ? 'Approved (all letters)' : 'Approved (this letter)');
    $('#statApproved').text(money(approved));
    $('#statTotal').text(money(committed));
    $('#statBalance').text(money(approved - committed)).toggleClass('csr-neg', approved - committed < 0);
    $('#btnNew').attr('href', 'CsrWorkOrderServlet?action=form' + (lf !== 'ALL' ? '&letterId=' + lf : ''));
  }

  // show / hide line items
  $(document).on('click', '.js-items', function () {
    var id = $(this).closest('tr').attr('data-id'), $row = $('tr.wo-items[data-for="' + id + '"]');
    var open = !$row.is(':visible');
    $row.toggle(open);
    var cnt = (itemsByWo[id] || []).length;
    $(this).text(cnt + ' line' + (cnt === 1 ? '' : 's') + (open ? ' - hide' : ' - show'));
  });

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
    $.ajax({ url: 'CsrWorkOrderServlet', type: 'POST', dataType: 'json', data: { action: 'delete', id: id }
    }).done(function (res) {
      if (!res.ok) { showToast(false, res.message); render(); return; }
      var i = byId(rows, id);
      if (i !== -1) {
        var li = byId(letters, rows[i].letterId);
        if (li !== -1) letters[li].committed = (Number(letters[li].committed) - Number(rows[i].total)).toFixed(2);
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

  // message after saving on the form page
  var params = new URLSearchParams(window.location.search);
  if (params.get('msg')) {
    showToast(true, params.get('msg'));
    var $tr = $('tr.wo-row[data-id="' + (params.get('hl') || '').replace(/\D/g, '') + '"]').addClass('csr-flash');
    setTimeout(function () { $tr.removeClass('csr-flash'); }, 1500);
    if (window.history.replaceState) window.history.replaceState(null, '', 'CsrWorkOrderServlet');
  }
});
</script>

</body>
</html>
