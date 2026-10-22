<%@page import="java.util.List"%>
<%@page import="java.util.Map"%>
<%
    // Must be opened through CsrLetterServlet?action=form[&id=N] (loads data + checks Global role)
    if (request.getAttribute("kinds") == null) {
        response.sendRedirect("CsrLetterServlet?action=form");
        return;
    }
    @SuppressWarnings("unchecked")
    Map<String, String> row = (Map<String, String>) request.getAttribute("row");   // null = new letter
    @SuppressWarnings("unchecked")
    List<String> kinds = (List<String>) request.getAttribute("kinds");
    String loadError = (String) request.getAttribute("error");
    boolean isEdit = row != null;
    com.google.gson.Gson gson = new com.google.gson.Gson();   // escapes < > & : safe inside <script>
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><%= isEdit ? "Edit Approval Letter" : "New Approval Letter" %></title>

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
      <div class="csr-subtitle">KSS CSR Amount Spending</div>
      <h1 class="csr-title" id="pageTitle"></h1>
    </div>
    <a href="CsrLetterServlet" class="csr-btn csr-btn-outline csr-link-btn">&#8592; Back to Approval Letters</a>
  </div>

  <div id="csrError" class="csr-alert csr-alert-err" style="display:none;"></div>
  <div id="csrToast" class="csr-alert" style="display:none;"></div>

  <div class="csr-card">
    <div class="csr-card-head">
      <div class="csr-card-title" id="formTitle">Letter Details</div>
    </div>
    <form id="csrForm" class="csr-form" enctype="multipart/form-data" autocomplete="off">
      <input type="hidden" name="action" value="save">
      <input type="hidden" name="id" id="fId" value="">

      <div class="csr-field span-2">
        <label for="fName">Letter Name <span class="req">*</span></label>
        <input type="text" id="fName" name="letterName" class="csr-input" maxlength="200">
      </div>
      <div class="csr-field">
        <label for="fNumber">Letter Number <span class="req">*</span></label>
        <input type="text" id="fNumber" name="letterNumber" class="csr-input" maxlength="100">
      </div>

      <div class="csr-field">
        <label for="fKind">Kind of CSR Activity <span class="req">*</span></label>
        <input type="text" id="fKind" name="activityKind" class="csr-input" maxlength="150" list="kindList" placeholder="Select or type">
        <datalist id="kindList"></datalist>
      </div>
      <div class="csr-field">
        <label for="fPlace">Place <span class="req">*</span></label>
        <input type="text" id="fPlace" name="place" class="csr-input" maxlength="200">
      </div>
      <div class="csr-field">
        <label for="fAmount">Amount (&#8377;) <span class="req">*</span></label>
        <input type="number" id="fAmount" name="amount" class="csr-input csr-amount" min="0.01" step="0.01" placeholder="0.00">
      </div>

      <div class="csr-field span-3">
        <label for="fParticulars">Particulars</label>
        <textarea id="fParticulars" name="particulars" class="csr-textarea" placeholder="Details of the CSR activity"></textarea>
      </div>

      <div class="csr-field span-2">
        <label for="fPdf">Approval Letter (PDF) <span class="req" id="pdfReq">*</span></label>
        <input type="file" id="fPdf" name="pdfFile" class="csr-file" accept="application/pdf,.pdf">
        <div class="csr-hint">PDF only, maximum 10 MB.<span id="pdfKeepHint" style="display:none;"> Leave empty to keep the current PDF.</span></div>
        <div class="csr-hint csr-current-pdf" id="currentPdf"></div>
      </div>

      <div class="csr-form-actions">
        <a href="CsrLetterServlet" class="csr-btn csr-btn-outline csr-link-btn">Cancel</a>
        <button type="submit" class="csr-btn" id="btnSave"></button>
      </div>
    </form>
  </div>
</div>

<script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
<script>
$(function () {
  var row = <%= gson.toJson(row) %>;          // null when adding
  var usedKinds = <%= gson.toJson(kinds) %>;
  var loadError = <%= gson.toJson(loadError) %>;
  var DEFAULT_KINDS = ['Education', 'Health Care', 'Rural Development', 'Environment', 'Sanitation & Drinking Water',
                       'Women Empowerment', 'Sports', 'Disaster Relief', 'Art & Culture', 'Animal Welfare'];

  if (loadError) $('#csrError').text(loadError).show();

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

  // Kind of activity suggestions
  var kinds = DEFAULT_KINDS.slice();
  (usedKinds || []).forEach(function (k) { if (k && kinds.indexOf(k) === -1) kinds.push(k); });
  kinds.forEach(function (k) { $('#kindList').append($('<option></option>').attr('value', k)); });

  // Fill the form
  if (row) {
    $('#pageTitle').text('Edit Approval Letter');
    $('#formTitle').text('Letter ' + row.letterNumber);
    $('#btnSave').text('Update Letter');
    $('#fId').val(row.id);
    $('#fName').val(row.letterName);
    $('#fNumber').val(row.letterNumber);
    $('#fKind').val(row.activityKind);
    $('#fPlace').val(row.place);
    $('#fAmount').val(row.amount);
    $('#fParticulars').val(row.particulars || '');
    $('#pdfReq').hide();
    $('#pdfKeepHint').show();
    if (row.pdfSize) {
      $('#currentPdf').append('Current PDF: ')
        .append($('<a target="_blank"></a>').attr('href', 'CsrLetterServlet?action=pdf&id=' + row.id).text(row.pdfName || 'View'))
        .append(' (' + kb(row.pdfSize) + ')');
    }
  } else {
    $('#pageTitle').text('New Approval Letter');
    $('#btnSave').text('Save Letter');
  }
  $('#fName').trigger('focus');

  // Save (AJAX), then go back to the list
  $('#csrForm').on('submit', function (e) {
    e.preventDefault();
    var isNew = !row;
    var checks = [['#fName', 'Letter Name'], ['#fNumber', 'Letter Number'], ['#fKind', 'Kind of CSR Activity'], ['#fPlace', 'Place']];
    for (var i = 0; i < checks.length; i++) {
      if ($.trim($(checks[i][0]).val()) === '') { showToast(false, 'Please enter the ' + checks[i][1] + '.'); $(checks[i][0]).trigger('focus'); return; }
    }
    if (!(Number($('#fAmount').val()) > 0)) { showToast(false, 'Please enter a valid Amount.'); $('#fAmount').trigger('focus'); return; }
    var file = $('#fPdf')[0].files[0];
    if (isNew && !file) { showToast(false, 'Please attach the approval letter PDF.'); return; }
    if (file) {
      if (!/\.pdf$/i.test(file.name)) { showToast(false, 'Please attach a PDF file.'); return; }
      if (file.size > 10 * 1024 * 1024) { showToast(false, 'The PDF is too large (maximum 10 MB).'); return; }
    }

    var $btn = $('#btnSave'), label = $btn.text();
    $btn.prop('disabled', true).text('Saving...');
    $.ajax({
      url: 'CsrLetterServlet', type: 'POST', dataType: 'json',
      data: new FormData(this), processData: false, contentType: false
    }).done(function (res) {
      if (!res.ok) { showToast(false, res.message); $btn.prop('disabled', false).text(label); return; }
      window.location.href = 'CsrLetterServlet?msg=' + encodeURIComponent(res.message) + '&hl=' + res.id;
    }).fail(function (xhr) {
      showToast(false, (xhr.responseJSON && xhr.responseJSON.message) ? xhr.responseJSON.message : 'Could not save. Please try again.');
      $btn.prop('disabled', false).text(label);
    });
  });
});
</script>

</body>
</html>
