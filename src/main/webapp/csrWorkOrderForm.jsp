<%@page import="java.util.List"%>
<%@page import="java.util.Map"%>
<%
    // Must be opened through CsrWorkOrderServlet?action=form (loads data + checks Global role)
    if (request.getAttribute("letters") == null) {
        response.sendRedirect("CsrWorkOrderServlet?action=form");
        return;
    }
    @SuppressWarnings("unchecked")
    Map<String, String> wo = (Map<String, String>) request.getAttribute("wo");          // null = new
    boolean isEdit = wo != null;
    com.google.gson.Gson gson = new com.google.gson.Gson();   // escapes < > & : safe inside <script>
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><%= isEdit ? "Edit Work Order" : "New Work Order" %></title>

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

<div class="csr-page csr-page-narrow">

  <div class="csr-header">
    <div>
      <div class="csr-subtitle">KSS CSR Amount Spending &rsaquo; Step 2</div>
      <h1 class="csr-title" id="pageTitle"></h1>
    </div>
    <a href="CsrWorkOrderServlet" class="csr-btn csr-btn-outline csr-link-btn">&#8592; Back to Work Orders</a>
  </div>

  <div id="csrError" class="csr-alert csr-alert-err" style="display:none;"></div>
  <div id="csrToast" class="csr-alert" style="display:none;"></div>

  <form id="woForm" enctype="multipart/form-data" autocomplete="off">
    <input type="hidden" name="action" value="save">
    <input type="hidden" name="id" id="fId" value="">
    <input type="hidden" name="items" id="fItems" value="">

    <!-- Approval letter + WO header -->
    <div class="csr-card">
      <div class="csr-card-head"><div class="csr-card-title">Work Order</div></div>
      <div class="csr-form">
        <div class="csr-field span-3">
          <label for="fLetter">Against Approval Letter <span class="req">*</span></label>
          <select id="fLetter" name="letterId" class="csr-input"></select>
          <div class="csr-budget" id="budgetBox" style="display:none;">
            <span>Approved <b id="bApproved"></b></span>
            <span>Other work orders <b id="bOthers"></b></span>
            <span>Available <b id="bAvailable"></b></span>
          </div>
        </div>
        <div class="csr-field">
          <label for="fWoNumber">WO Number <span class="req">*</span></label>
          <input type="text" id="fWoNumber" name="woNumber" class="csr-input" maxlength="100" placeholder="e.g. KSS/WO/2026/001">
        </div>
        <div class="csr-field">
          <label for="fWoDate">WO Date <span class="req">*</span></label>
          <input type="date" id="fWoDate" name="woDate" class="csr-input">
        </div>
      </div>
    </div>

    <!-- Particulars -->
    <div class="csr-card">
      <div class="csr-card-head">
        <div class="csr-card-title">Particulars</div>
        <button type="button" class="csr-btn csr-btn-sm csr-btn-outline" id="btnAddLine">+ Add Line</button>
      </div>
      <div class="csr-table-wrap">
        <table class="csr-table csr-items">
          <thead>
            <tr>
              <th style="width:40px">#</th>
              <th>Particulars</th>
              <th class="csr-num" style="width:150px">Price (&#8377;)</th>
              <th style="width:110px">GST %</th>
              <th class="csr-num" style="width:130px">GST (&#8377;)</th>
              <th class="csr-num" style="width:140px">Amount (&#8377;)</th>
              <th style="width:44px"></th>
            </tr>
          </thead>
          <tbody id="itemBody"></tbody>
          <tfoot>
            <tr class="csr-sum"><td colspan="5" class="csr-num">Subtotal</td><td class="csr-num" id="tSub">-</td><td></td></tr>
            <tr class="csr-sum"><td colspan="5" class="csr-num">GST</td><td class="csr-num" id="tGst">-</td><td></td></tr>
            <tr class="csr-total-row"><td colspan="5" class="csr-num">Total</td><td class="csr-num" id="tTotal">-</td><td></td></tr>
          </tfoot>
        </table>
      </div>
      <div class="csr-over" id="overWarn" style="display:none;"></div>
    </div>

    <!-- Vendor -->
    <div class="csr-card">
      <div class="csr-card-head"><div class="csr-card-title">Vendor Details</div></div>
      <div class="csr-form">
        <div class="csr-field span-2">
          <label for="fVName">Vendor Name <span class="req">*</span></label>
          <input type="text" id="fVName" name="vendorName" class="csr-input" maxlength="200" list="vendorList" placeholder="Type or pick a previous vendor">
          <datalist id="vendorList"></datalist>
        </div>
        <div class="csr-field">
          <label for="fVPhone">Phone Number</label>
          <input type="text" id="fVPhone" name="vendorPhone" class="csr-input" maxlength="20" placeholder="e.g. 9876543210">
        </div>
        <div class="csr-field">
          <label for="fVEmail">Email ID</label>
          <input type="email" id="fVEmail" name="vendorEmail" class="csr-input" maxlength="150" placeholder="vendor@example.com">
        </div>
        <div class="csr-field">
          <label for="fVGstin">GSTIN</label>
          <input type="text" id="fVGstin" name="vendorGstin" class="csr-input csr-upper" maxlength="15" placeholder="29ABCDE1234F1Z5">
        </div>
        <div class="csr-field span-3">
          <label for="fVAddress">Address</label>
          <textarea id="fVAddress" name="vendorAddress" class="csr-textarea" maxlength="500" placeholder="Vendor address"></textarea>
        </div>
      </div>
    </div>

    <!-- Attachment -->
    <div class="csr-card">
      <div class="csr-card-head"><div class="csr-card-title">Attachment</div></div>
      <div class="csr-form">
        <div class="csr-field span-2">
          <label for="fFile">Work Order Copy (PDF / JPG / PNG)</label>
          <input type="file" id="fFile" name="attachment" class="csr-file" accept="application/pdf,.pdf,image/jpeg,.jpg,.jpeg,image/png,.png">
          <div class="csr-hint">Maximum 10 MB.<span id="fileKeepHint" style="display:none;"> Leave empty to keep the current attachment.</span></div>
          <div class="csr-hint csr-current-pdf" id="currentFile"></div>
        </div>
        <div class="csr-form-actions">
          <a href="CsrWorkOrderServlet" class="csr-btn csr-btn-outline csr-link-btn">Cancel</a>
          <button type="submit" class="csr-btn" id="btnSave"></button>
        </div>
      </div>
    </div>
  </form>
</div>

<script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
<script>
$(function () {
  var wo       = <%= gson.toJson(wo) %>;                                  // null when adding
  var items    = <%= gson.toJson(request.getAttribute("items")) %>;
  var letters  = <%= gson.toJson(request.getAttribute("letters")) %>;
  var vendors  = <%= gson.toJson(request.getAttribute("vendors")) %>;
  var preset   = <%= gson.toJson(request.getAttribute("presetLetterId")) %>;
  var loadError = <%= gson.toJson(request.getAttribute("error")) %>;
  var RS = String.fromCharCode(8377);
  var GST_RATES = ['0', '5', '12', '18', '28'];

  if (loadError) $('#csrError').text(loadError).show();

  function money(v) {
    return RS + ' ' + Number(v || 0).toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  }
  function r2(v) { return Math.round((Number(v) || 0) * 100) / 100; }
  function kb(bytes) {
    var n = parseInt(bytes, 10) || 0;
    return n >= 1048576 ? (n / 1048576).toFixed(1) + ' MB' : Math.max(1, Math.round(n / 1024)) + ' KB';
  }
  function showToast(ok, text) {
    var $t = $('#csrToast');
    $t.removeClass('csr-alert-ok csr-alert-err').addClass(ok ? 'csr-alert-ok' : 'csr-alert-err').text(text).stop(true, true).fadeIn(150);
    clearTimeout($t.data('timer'));
    $t.data('timer', setTimeout(function () { $t.fadeOut(300); }, 4500));
    $('html, body').animate({ scrollTop: 0 }, 150);
  }

  // ---------------------------------------------------------------- approval letters + budget
  var $sel = $('#fLetter').append('<option value="">-- Select approval letter --</option>');
  letters.forEach(function (l) {
    var others = Number(l.committed) - (wo && String(wo.letterId) === String(l.id) ? Number(wo.total) : 0);
    var avail = Number(l.amount) - others;
    $sel.append($('<option></option>').attr('value', l.id)
      .text(l.letterNumber + '  |  ' + l.letterName + '  |  ' + l.activityKind + '  |  Available ' + money(avail)));
  });
  function currentLetter() {
    var id = $sel.val();
    for (var i = 0; i < letters.length; i++) if (String(letters[i].id) === String(id)) return letters[i];
    return null;
  }
  function available() {
    var l = currentLetter();
    if (!l) return null;
    var others = Number(l.committed) - (wo && String(wo.letterId) === String(l.id) ? Number(wo.total) : 0);
    return { approved: Number(l.amount), others: others, avail: r2(Number(l.amount) - others) };
  }
  function showBudget() {
    var b = available();
    if (!b) { $('#budgetBox').hide(); return; }
    $('#bApproved').text(money(b.approved));
    $('#bOthers').text(money(b.others));
    $('#bAvailable').text(money(b.avail));
    $('#budgetBox').show();
    recalc();
  }
  $sel.on('change', showBudget);

  // ---------------------------------------------------------------- items
  function gstSelect(val) {
    var $s = $('<select class="csr-input it-gst"></select>');
    GST_RATES.forEach(function (g) { $s.append($('<option></option>').attr('value', g).text(g + ' %')); });
    if (val !== undefined && val !== null && GST_RATES.indexOf(String(val)) === -1) {
      $s.append($('<option></option>').attr('value', val).text(val + ' %'));
    }
    $s.val(val === undefined || val === null ? '18' : String(val));
    return $s;
  }
  function addLine(it) {
    it = it || {};
    var $tr = $('<tr class="it-row"></tr>');
    $tr.append('<td class="it-no"></td>');
    $tr.append($('<td></td>').append($('<input type="text" class="csr-input it-part" maxlength="500" placeholder="Description of work / item">').val(it.particulars || '')));
    $tr.append($('<td></td>').append($('<input type="number" class="csr-input csr-amount it-price" min="0.01" step="0.01" placeholder="0.00">').val(it.price || '')));
    $tr.append($('<td></td>').append(gstSelect(it.gst)));
    $tr.append('<td class="csr-num it-gstamt">-</td>');
    $tr.append('<td class="csr-num csr-strong it-amt">-</td>');
    $tr.append('<td><button type="button" class="csr-btn csr-btn-sm csr-btn-bad it-del" title="Remove line">&#10005;</button></td>');
    $('#itemBody').append($tr);
    renumber();
    recalc();
    return $tr;
  }
  function renumber() {
    $('#itemBody tr.it-row').each(function (i) { $(this).find('.it-no').text(i + 1); });
    $('.it-del').prop('disabled', $('#itemBody tr.it-row').length === 1);
  }
  function recalc() {
    var sub = 0, gst = 0;
    $('#itemBody tr.it-row').each(function () {
      var price = r2($(this).find('.it-price').val());
      var g = r2(price * Number($(this).find('.it-gst').val()) / 100);
      $(this).find('.it-gstamt').text(price ? money(g) : '-');
      $(this).find('.it-amt').text(price ? money(price + g) : '-');
      sub += price; gst += g;
    });
    sub = r2(sub); gst = r2(gst);
    var total = r2(sub + gst);
    $('#tSub').text(money(sub)); $('#tGst').text(money(gst)); $('#tTotal').text(money(total));
    var b = available();
    if (b && total > b.avail) {
      $('#overWarn').text('Total ' + money(total) + ' is more than the available ' + money(b.avail) + ' on this approval letter.').show();
    } else {
      $('#overWarn').hide();
    }
    return total;
  }
  $('#btnAddLine').on('click', function () { addLine().find('.it-part').trigger('focus'); });
  $(document).on('click', '.it-del', function () { $(this).closest('tr').remove(); renumber(); recalc(); });
  $(document).on('input change', '.it-price, .it-gst', recalc);

  // ---------------------------------------------------------------- vendors (auto-fill)
  vendors.forEach(function (v) { $('#vendorList').append($('<option></option>').attr('value', v.name)); });
  $('#fVName').on('change', function () {
    var name = $.trim($(this).val()).toLowerCase();
    for (var i = 0; i < vendors.length; i++) {
      if (vendors[i].name.toLowerCase() === name) {
        var v = vendors[i];
        if (!$('#fVPhone').val()) $('#fVPhone').val(v.phone || '');
        if (!$('#fVEmail').val()) $('#fVEmail').val(v.email || '');
        if (!$('#fVGstin').val()) $('#fVGstin').val(v.gstin || '');
        if (!$('#fVAddress').val()) $('#fVAddress').val(v.address || '');
        break;
      }
    }
  });
  $('#fVGstin').on('input', function () { this.value = this.value.toUpperCase(); });

  // ---------------------------------------------------------------- fill form
  if (wo) {
    $('#pageTitle').text('Edit Work Order');
    $('#btnSave').text('Update Work Order');
    $('#fId').val(wo.id);
    $sel.val(wo.letterId);
    $('#fWoNumber').val(wo.woNumber);
    $('#fWoDate').val(wo.woDate);
    $('#fVName').val(wo.vendorName);
    $('#fVPhone').val(wo.vendorPhone || '');
    $('#fVEmail').val(wo.vendorEmail || '');
    $('#fVGstin').val(wo.vendorGstin || '');
    $('#fVAddress').val(wo.vendorAddress || '');
    (items.length ? items : [{}]).forEach(addLine);
    $('#fileKeepHint').show();
    if (wo.attachmentSize) {
      $('#currentFile').append('Current attachment: ')
        .append($('<a target="_blank"></a>').attr('href', 'CsrWorkOrderServlet?action=file&id=' + wo.id).text(wo.attachmentName || 'View'))
        .append(' (' + kb(wo.attachmentSize) + ')');
    }
  } else {
    $('#pageTitle').text('New Work Order');
    $('#btnSave').text('Save Work Order');
    if (preset) $sel.val(preset);
    var d = new Date();
    $('#fWoDate').val(d.getFullYear() + '-' + ('0' + (d.getMonth() + 1)).slice(-2) + '-' + ('0' + d.getDate()).slice(-2));
    addLine();
  }
  showBudget();

  // ---------------------------------------------------------------- save (AJAX), then back to the list
  $('#woForm').on('submit', function (e) {
    e.preventDefault();
    if (!$sel.val()) { showToast(false, 'Please select the Approval Letter.'); return; }
    if ($.trim($('#fWoNumber').val()) === '') { showToast(false, 'Please enter the WO Number.'); $('#fWoNumber').trigger('focus'); return; }
    if (!$('#fWoDate').val()) { showToast(false, 'Please enter the WO Date.'); return; }

    var list = [], bad = null;
    $('#itemBody tr.it-row').each(function (i) {
      var part = $.trim($(this).find('.it-part').val()), price = $.trim($(this).find('.it-price').val());
      if (part === '' && price === '') return;
      if (part === '') { bad = 'Line ' + (i + 1) + ': please enter the particulars.'; return false; }
      if (!(Number(price) > 0)) { bad = 'Line ' + (i + 1) + ': please enter a valid price.'; return false; }
      list.push({ particulars: part, price: price, gst: $(this).find('.it-gst').val() });
    });
    if (bad) { showToast(false, bad); return; }
    if (!list.length) { showToast(false, 'Please add at least one particulars line.'); return; }

    var total = recalc(), b = available();
    if (b && total > b.avail) { showToast(false, $('#overWarn').text()); return; }
    if ($.trim($('#fVName').val()) === '') { showToast(false, 'Please enter the Vendor Name.'); $('#fVName').trigger('focus'); return; }
    var gstin = $.trim($('#fVGstin').val());
    if (gstin && !/^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$/.test(gstin)) {
      showToast(false, 'GSTIN must be 15 characters, e.g. 29ABCDE1234F1Z5.'); $('#fVGstin').trigger('focus'); return;
    }
    var file = $('#fFile')[0].files[0];
    if (file) {
      if (!/\.(pdf|jpe?g|png)$/i.test(file.name)) { showToast(false, 'Attachment must be a PDF, JPG or PNG file.'); return; }
      if (file.size > 10 * 1024 * 1024) { showToast(false, 'The attachment is too large (maximum 10 MB).'); return; }
    }

    $('#fItems').val(JSON.stringify(list));
    var $btn = $('#btnSave'), label = $btn.text();
    $btn.prop('disabled', true).text('Saving...');
    $.ajax({
      url: 'CsrWorkOrderServlet', type: 'POST', dataType: 'json',
      data: new FormData(this), processData: false, contentType: false
    }).done(function (res) {
      if (!res.ok) { showToast(false, res.message); $btn.prop('disabled', false).text(label); return; }
      window.location.href = 'CsrWorkOrderServlet?msg=' + encodeURIComponent(res.message) + '&hl=' + res.id;
    }).fail(function (xhr) {
      showToast(false, (xhr.responseJSON && xhr.responseJSON.message) ? xhr.responseJSON.message : 'Could not save. Please try again.');
      $btn.prop('disabled', false).text(label);
    });
  });
});
</script>

</body>
</html>
