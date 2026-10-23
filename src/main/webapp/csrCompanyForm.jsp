<%@page import="java.util.Map"%>
<%
    // Must be opened through CsrCompanyServlet?action=form[&id=N] (loads data + checks Global role)
    if (request.getAttribute("formReady") == null) {
        response.sendRedirect("CsrCompanyServlet?action=form");
        return;
    }
    @SuppressWarnings("unchecked")
    Map<String, String> row = (Map<String, String>) request.getAttribute("row");   // null = new company
    String loadError = (String) request.getAttribute("error");
    boolean isEdit = row != null;
    com.google.gson.Gson gson = new com.google.gson.Gson();   // escapes < > & : safe inside <script>
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><%= isEdit ? "Edit Company" : "New Company" %></title>

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
      <div class="csr-subtitle"><%= com.Bean.AppConfig.code() %> CSR &middot; Masters</div>
      <h1 class="csr-title" id="pageTitle"></h1>
    </div>
    <a href="CsrCompanyServlet" class="csr-btn csr-btn-outline csr-link-btn">&#8592; Back to Companies</a>
  </div>

  <div id="csrError" class="csr-alert csr-alert-err" style="display:none;"></div>
  <div id="csrToast" class="csr-alert" style="display:none;"></div>

  <div class="csr-card">
    <div class="csr-card-head">
      <div class="csr-card-title" id="formTitle">Company Details</div>
    </div>
    <form id="csrForm" class="csr-form" autocomplete="off">
      <input type="hidden" name="action" value="save">
      <input type="hidden" name="id" id="fId" value="">

      <div class="csr-field span-2">
        <label for="fName">Company Name <span class="req">*</span></label>
        <input type="text" id="fName" name="companyName" class="csr-input" maxlength="200">
      </div>
      <div class="csr-field">
        <label for="fShort">Short Name</label>
        <input type="text" id="fShort" name="shortName" class="csr-input" maxlength="50">
        <div class="csr-hint">Shown on screens and prints. Leave empty to use the full name.</div>
      </div>

      <div class="csr-field">
        <label for="fGstin">GSTIN</label>
        <input type="text" id="fGstin" name="gstin" class="csr-input" maxlength="15" style="text-transform:uppercase;">
      </div>
      <div class="csr-field">
        <label for="fPan">PAN</label>
        <input type="text" id="fPan" name="pan" class="csr-input" maxlength="10" style="text-transform:uppercase;">
      </div>
      <div class="csr-field">
        <label for="fStatus">Status <span class="req">*</span></label>
        <select id="fStatus" name="status" class="csr-input">
          <option value="Active">Active</option>
          <option value="Inactive">Inactive</option>
        </select>
        <div class="csr-hint">Inactive companies are not offered for new approvals.</div>
      </div>

      <div class="csr-field">
        <label for="fContact">Contact Person</label>
        <input type="text" id="fContact" name="contactPerson" class="csr-input" maxlength="150">
      </div>
      <div class="csr-field">
        <label for="fPhone">Phone</label>
        <input type="text" id="fPhone" name="phone" class="csr-input" maxlength="20">
      </div>
      <div class="csr-field">
        <label for="fEmail">Email</label>
        <input type="email" id="fEmail" name="email" class="csr-input" maxlength="150">
      </div>

      <div class="csr-field span-3">
        <label for="fAddress">Address</label>
        <textarea id="fAddress" name="address" class="csr-textarea" maxlength="500"></textarea>
      </div>

      <div class="csr-form-actions">
        <a href="CsrCompanyServlet" class="csr-btn csr-btn-outline csr-link-btn">Cancel</a>
        <button type="submit" class="csr-btn" id="btnSave"></button>
      </div>
    </form>
  </div>
</div>

<script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
<script>
$(function () {
  var row = <%= gson.toJson(row) %>;          // null when adding
  var loadError = <%= gson.toJson(loadError) %>;
  var GSTIN = /^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$/, PAN = /^[A-Z]{5}[0-9]{4}[A-Z]$/;

  if (loadError) $('#csrError').text(loadError).show();

  function showToast(ok, text) {
    var $t = $('#csrToast');
    $t.removeClass('csr-alert-ok csr-alert-err').addClass(ok ? 'csr-alert-ok' : 'csr-alert-err').text(text).stop(true, true).fadeIn(150);
    clearTimeout($t.data('timer'));
    $t.data('timer', setTimeout(function () { $t.fadeOut(300); }, 4000));
  }

  if (row) {
    $('#pageTitle').text('Edit Company');
    $('#formTitle').text(row.companyName);
    $('#btnSave').text('Update Company');
    $('#fId').val(row.id);
    $('#fName').val(row.companyName);
    $('#fShort').val(row.shortName || '');
    $('#fGstin').val(row.gstin || '');
    $('#fPan').val(row.pan || '');
    $('#fStatus').val(row.status);
    $('#fContact').val(row.contactPerson || '');
    $('#fPhone').val(row.phone || '');
    $('#fEmail').val(row.email || '');
    $('#fAddress').val(row.address || '');
  } else {
    $('#pageTitle').text('New Company');
    $('#btnSave').text('Save Company');
  }
  $('#fName').trigger('focus');

  // PAN from GSTIN when PAN is empty
  $('#fGstin').on('change', function () {
    var g = $.trim($(this).val()).toUpperCase();
    $(this).val(g);
    if (GSTIN.test(g) && !$.trim($('#fPan').val())) $('#fPan').val(g.substring(2, 12));
  });

  $('#csrForm').on('submit', function (e) {
    e.preventDefault();
    var g = $.trim($('#fGstin').val()).toUpperCase(), p = $.trim($('#fPan').val()).toUpperCase();
    if ($.trim($('#fName').val()) === '') { showToast(false, 'Please enter the Company Name.'); $('#fName').trigger('focus'); return; }
    if (g && !GSTIN.test(g)) { showToast(false, 'GSTIN is not valid (15 characters).'); $('#fGstin').trigger('focus'); return; }
    if (p && !PAN.test(p)) { showToast(false, 'PAN is not valid (10 characters).'); $('#fPan').trigger('focus'); return; }
    if (g && p && g.substring(2, 12) !== p) { showToast(false, 'PAN does not match the PAN inside the GSTIN.'); $('#fPan').trigger('focus'); return; }

    var $btn = $('#btnSave'), label = $btn.text();
    $btn.prop('disabled', true).text('Saving...');
    $.ajax({ url: 'CsrCompanyServlet', type: 'POST', dataType: 'json', data: $(this).serialize()
    }).done(function (res) {
      if (!res.ok) { showToast(false, res.message); $btn.prop('disabled', false).text(label); return; }
      window.location.href = 'CsrCompanyServlet?msg=' + encodeURIComponent(res.message) + '&hl=' + res.id;
    }).fail(function (xhr) {
      showToast(false, (xhr.responseJSON && xhr.responseJSON.message) ? xhr.responseJSON.message : 'Could not save. Please try again.');
      $btn.prop('disabled', false).text(label);
    });
  });
});
</script>

</body>
</html>
