<%@page import="java.util.Map"%>
<%
    // Must be opened through CsrActivityPlaceServlet?action=form[&id=N|&kind=] (loads data + checks Global role)
    if (request.getAttribute("formReady") == null) {
        response.sendRedirect("CsrActivityPlaceServlet?action=form");
        return;
    }
    @SuppressWarnings("unchecked")
    Map<String, String> row = (Map<String, String>) request.getAttribute("row");   // null = new entry
    String presetKind = (String) request.getAttribute("presetKind");
    String loadError = (String) request.getAttribute("error");
    boolean isEdit = row != null;
    com.google.gson.Gson gson = new com.google.gson.Gson();   // escapes < > & : safe inside <script>
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><%= isEdit ? "Edit CSR Activity / Place" : "New CSR Activity / Place" %></title>

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
    <a href="CsrActivityPlaceServlet" class="csr-btn csr-btn-outline csr-link-btn">&#8592; Back to Activities &amp; Places</a>
  </div>

  <div id="csrError" class="csr-alert csr-alert-err" style="display:none;"></div>
  <div id="csrToast" class="csr-alert" style="display:none;"></div>

  <div class="csr-card">
    <div class="csr-card-head">
      <div class="csr-card-title" id="formTitle">Details</div>
    </div>
    <form id="csrForm" class="csr-form" autocomplete="off">
      <input type="hidden" name="action" value="save">
      <input type="hidden" name="id" id="fId" value="">

      <div class="csr-field">
        <label for="fKind">Type <span class="req">*</span></label>
        <select id="fKind" name="kind" class="csr-input">
          <option value="Activity">Kind of CSR Activity</option>
          <option value="Place">Place</option>
        </select>
        <div class="csr-hint" id="kindHint"></div>
      </div>
      <div class="csr-field">
        <label for="fName" id="nameLabel">Name <span class="req">*</span></label>
        <input type="text" id="fName" name="name" class="csr-input" maxlength="150">
        <div class="csr-hint" id="nameHint"></div>
      </div>
      <div class="csr-field">
        <label for="fStatus">Status <span class="req">*</span></label>
        <select id="fStatus" name="status" class="csr-input">
          <option value="Active">Active</option>
          <option value="Inactive">Inactive</option>
        </select>
        <div class="csr-hint">Inactive entries are not offered for new approvals.</div>
      </div>

      <div class="csr-form-actions">
        <a href="CsrActivityPlaceServlet" class="csr-btn csr-btn-outline csr-link-btn">Cancel</a>
        <button type="submit" class="csr-btn" id="btnSave"></button>
      </div>
    </form>
  </div>
</div>

<script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
<script>
$(function () {
  var row = <%= gson.toJson(row) %>;          // null when adding
  var presetKind = <%= gson.toJson(presetKind) %>;
  var loadError = <%= gson.toJson(loadError) %>;
  var LABEL = { Activity: 'Kind of CSR Activity', Place: 'Place' }, MAX = { Activity: 150, Place: 200 };

  if (loadError) $('#csrError').text(loadError).show();

  function showToast(ok, text) {
    var $t = $('#csrToast');
    $t.removeClass('csr-alert-ok csr-alert-err').addClass(ok ? 'csr-alert-ok' : 'csr-alert-err').text(text).stop(true, true).fadeIn(150);
    clearTimeout($t.data('timer'));
    $t.data('timer', setTimeout(function () { $t.fadeOut(300); }, 4000));
  }
  function kindChanged() {
    var k = $('#fKind').val();
    $('#nameLabel').html('').text(LABEL[k] + ' ').append('<span class="req">*</span>');
    $('#fName').attr('maxlength', MAX[k]);
    if (!row) $('#pageTitle').text('New ' + LABEL[k]);
  }

  if (row) {
    $('#pageTitle').text('Edit ' + LABEL[row.kind]);
    $('#formTitle').text(row.name);
    $('#btnSave').text('Update');
    $('#fId').val(row.id);
    $('#fKind').val(row.kind).prop('disabled', true);
    $('#kindHint').text('The type cannot be changed.');
    $('#fName').val(row.name);
    $('#fStatus').val(row.status);
    var used = parseInt(row.letterCount, 10) || 0;
    if (used) $('#nameHint').text('Used on ' + used + ' Management Approval' + (used === 1 ? '' : 's') + '. A new name is changed on them too.');
  } else {
    $('#fKind').val(presetKind === 'Place' ? 'Place' : 'Activity');
    $('#btnSave').text('Save');
  }
  kindChanged();
  $('#fKind').on('change', kindChanged);
  $('#fName').trigger('focus');

  $('#csrForm').on('submit', function (e) {
    e.preventDefault();
    var k = $('#fKind').val();
    if ($.trim($('#fName').val()) === '') { showToast(false, 'Please enter the ' + LABEL[k] + '.'); $('#fName').trigger('focus'); return; }

    var $btn = $('#btnSave'), label = $btn.text();
    $btn.prop('disabled', true).text('Saving...');
    $.ajax({ url: 'CsrActivityPlaceServlet', type: 'POST', dataType: 'json',
             data: $(this).serialize()   // on edit the disabled Type is not sent; the server keeps the stored type
    }).done(function (res) {
      if (!res.ok) { showToast(false, res.message); $btn.prop('disabled', false).text(label); return; }
      window.location.href = 'CsrActivityPlaceServlet?msg=' + encodeURIComponent(res.message) + '&hl=' + res.id;
    }).fail(function (xhr) {
      showToast(false, (xhr.responseJSON && xhr.responseJSON.message) ? xhr.responseJSON.message : 'Could not save. Please try again.');
      $btn.prop('disabled', false).text(label);
    });
  });
});
</script>

</body>
</html>
