
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.Bean.ScholarshipBean"%>
<%
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    ScholarshipBean bean = (ScholarshipBean) request.getAttribute("bean");
%>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Scholarship Application Details</title>

<div class="no-print">
  <%@ include file="header.jsp"%>
</div>

<style>
  :root {
    --primary-color: #7a1f35;       /* Primary maroon */
    --primary-hover: #5e1627;       /* Darker hover state */
    --accent-bg: #fdf6f7;           /* Soft warm background tint */
    --border-color: #d8c3c7;        /* Soft neutral maroon border */
    --slds-border: #dddbda;         /* Salesforce standard border */
    --text-main: #2b2b2b;
    --text-muted: #54698d;          /* Salesforce muted gray text */
    --bg-main: #f3f3f3;             /* Salesforce canvas gray */
    --card-bg: #ffffff;
  }

  * {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
  }

  body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    background-color: var(--bg-main);
    color: var(--text-main);
    padding: 16px 20px 32px;
    -webkit-font-smoothing: antialiased;
  }

  .container {
    max-width: 1100px;
    margin: 0 auto;
  }

  /* Salesforce Style Card Base */
  .slds-card {
    background: var(--card-bg);
    border: 1px solid var(--slds-border);
    border-radius: 4px;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.04);
    overflow: hidden;
    margin-bottom: 16px;
  }

  /* Salesforce Page Header Banner */
  .slds-page-header {
    background: #ffffff;
    border-bottom: 3px solid var(--primary-color);
    padding: 14px 20px;
    display: flex;
    align-items: center;
    justify-content: space-between;
  }

  .slds-page-header__title {
    font-size: 16px;
    font-weight: 700;
    color: var(--primary-color);
    letter-spacing: 0.3px;
    text-transform: uppercase;
  }

  .slds-page-header__subtitle {
    font-size: 12px;
    color: var(--text-muted);
    margin-top: 2px;
  }

  .detail-body {
    padding: 16px 20px;
  }

  /* Salesforce Section Header */
  .slds-section-header {
    display: flex;
    align-items: center;
    background-color: var(--accent-bg);
    border-top: 1px solid var(--border-color);
    border-bottom: 1px solid var(--border-color);
    padding: 6px 12px;
    margin: 16px 0 12px 0;
    border-left: 4px solid var(--primary-color);
  }

  .slds-section-header:first-of-type {
    margin-top: 0;
  }

  .slds-section-title {
    font-size: 12px;
    font-weight: 700;
    color: var(--primary-color);
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }

  /* Salesforce Record Details Grid */
  .slds-detail-grid {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 12px 24px;
    padding: 0 8px;
  }

  .slds-detail-item {
    display: flex;
    flex-direction: column;
    padding: 4px 0;
    border-bottom: 1px solid #f3f3f3;
  }

  .slds-item-label {
    font-size: 11px;
    font-weight: 600;
    color: var(--text-muted);
    text-transform: uppercase;
    letter-spacing: 0.3px;
    margin-bottom: 2px;
  }

  .slds-item-value {
    font-size: 13px;
    color: var(--text-main);
    font-weight: 500;
    word-break: break-word;
  }

  /* Documents Grid Component */
  .doc-grid {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 12px 24px;
    padding: 0 8px;
  }

  .doc-card {
    background: #fafafa;
    border: 1px solid var(--slds-border);
    border-radius: 4px;
    padding: 12px;
    display: flex;
    flex-direction: column;
    gap: 8px;
  }

  .doc-card-title {
    font-size: 11px;
    font-weight: 700;
    color: var(--text-muted);
    text-transform: uppercase;
    letter-spacing: 0.3px;
  }

  .file-container {
    display: flex;
    align-items: center;
    gap: 10px;
    flex-wrap: wrap;
  }

  /* Document Status Badges */
  .status-badge {
    display: inline-flex;
    align-items: center;
    padding: 3px 10px;
    font-size: 11px;
    font-weight: 600;
    border-radius: 4px;
    text-decoration: none;
  }

  .status-badge.view {
    background-color: #e2f0d9;
    color: #2e591b;
    border: 1px solid #a9d18e;
  }

  .status-badge.view:hover {
    background-color: #c5e0b4;
  }

  .status-badge.none {
    background-color: #fff2cc;
    color: #7f6000;
    border: 1px solid #ffd966;
  }

  input[type=file] {
    font-size: 11px;
    color: var(--text-muted);
  }

  /* Salesforce Buttons */
  .btn-actions {
    display: flex;
    justify-content: flex-end;
    gap: 10px;
    padding: 16px 20px;
    border-top: 1px solid var(--slds-border);
    background-color: #fafafa;
  }

  .btn {
    background-color: var(--primary-color);
    color: #ffffff;
    border: 1px solid var(--primary-hover);
    padding: 7px 20px;
    font-size: 12px;
    font-weight: 600;
    border-radius: 4px;
    cursor: pointer;
    text-decoration: none;
    display: inline-flex;
    align-items: center;
    transition: background-color 0.15s ease-in-out;
    box-shadow: 0 1px 2px rgba(0,0,0,0.08);
  }

  .btn:hover {
    background-color: var(--primary-hover);
    color: #ffffff;
  }

  .btn-secondary {
    background-color: #ffffff;
    color: var(--text-main);
    border: 1px solid var(--slds-border);
  }

  .btn-secondary:hover {
    background-color: #f3f3f3;
    color: var(--text-main);
  }

  .error-card {
    text-align: center;
    color: #c9372c;
    font-size: 15px;
    font-weight: 600;
    padding: 40px 20px;
  }

  @media (max-width: 768px) {
    .slds-detail-grid,
    .doc-grid {
      grid-template-columns: 1fr;
    }
  }

  /* PRINT STYLES - Ensures clean output for Sections 1-3 when using window.print() */
  @media print {
    body {
      background-color: #ffffff !important;
      padding: 0 !important;
      color: #000000 !important;
    }

    /* Hide non-printable areas */
    header, footer, nav, .btn-actions, .no-print, .non-printable {
      display: none !important;
    }

    .container {
      max-width: 100% !important;
      margin: 0 !important;
      padding: 0 !important;
    }

    .slds-card {
      border: none !important;
      box-shadow: none !important;
      margin: 0 !important;
    }

    .slds-page-header {
      border-bottom: 2px solid var(--primary-color) !important;
      padding: 10px 0 !important;
    }

    .detail-body {
      padding: 10px 0 !important;
    }

    .slds-section-header {
      -webkit-print-color-adjust: exact;
      print-color-adjust: exact;
      background-color: var(--accent-bg) !important;
      border-left: 4px solid var(--primary-color) !important;
      margin: 12px 0 8px 0 !important;
    }

    .slds-detail-grid {
      grid-template-columns: repeat(2, 1fr) !important;
      gap: 8px 16px !important;
      page-break-inside: avoid;
    }

    .slds-detail-item {
      border-bottom: 1px solid #e0e0e0 !important;
    }
  }
</style>
</head>

<body>

<div class="container">

<% if(bean == null) { %>

  <div class="slds-card">
    <div class="slds-page-header">
      <div class="slds-page-header__title">Scholarship Application Details</div>
    </div>
    <div class="error-card">
      Record Not Found.
    </div>
    <div class="btn-actions">
      <a href="ScholarshipListServelt" class="btn btn-secondary">Back to List</a>
    </div>
  </div>

<% } else { %>

  <div class="slds-card">

    <div class="slds-page-header">
      <div>
        <div class="slds-page-header__title">Scholarship Application Details</div>
        <div class="slds-page-header__subtitle">Record ID: #<%=bean.getId()%> | <%=bean.getEmpName()%></div>
      </div>
      <div class="no-print" style="display: flex; gap: 8px;">
        <button
    onclick="location.href='printScholarshipApplication.jsp?id=<%=bean.getId()%>';"
    class="btn">
    🖨 Print Application
</button>
        <a href="ScholarshipListServelt" class="btn btn-secondary">Back to List</a>
      </div>
    </div>

    <div class="detail-body">

      <!-- START PRINTABLE AREA (Sections 1 to 3) -->
      <div class="printable-section">

        <!-- 1. Employee Details -->
        <div class="slds-section-header">
          <span class="slds-section-title">1. Employee Details</span>
        </div>

        <div class="slds-detail-grid">
          <div class="slds-detail-item">
            <span class="slds-item-label">Application ID</span>
            <span class="slds-item-value"><%=bean.getId()%></span>
          </div>
          <div class="slds-detail-item">
            <span class="slds-item-label">Organization</span>
            <span class="slds-item-value"><%=bean.getOrgName()%></span>
          </div>
          <div class="slds-detail-item">
            <span class="slds-item-label">Employee No</span>
            <span class="slds-item-value"><%=bean.getEmpNo()%></span>
          </div>
          <div class="slds-detail-item">
            <span class="slds-item-label">Employee Name</span>
            <span class="slds-item-value"><%=bean.getEmpName()%></span>
          </div>
          <div class="slds-detail-item">
            <span class="slds-item-label">Designation</span>
            <span class="slds-item-value"><%=bean.getDesignation()%></span>
          </div>
          <div class="slds-detail-item">
            <span class="slds-item-label">Spouse Working in SMIORE</span>
            <span class="slds-item-value"><%=bean.getSpouseWorkingSMIORE()%></span>
          </div>
          <div class="slds-detail-item">
            <span class="slds-item-label">Spouse Working in Group Company</span>
            <span class="slds-item-value"><%=bean.getSpouseWorkingGroupCompanies()%></span>
          </div>
        </div>

        <!-- 2. Student Details -->
        <div class="slds-section-header">
          <span class="slds-section-title">2. Child / Student Details</span>
        </div>

        <div class="slds-detail-grid">
          <div class="slds-detail-item">
            <span class="slds-item-label">Child Name</span>
            <span class="slds-item-value"><%=bean.getChildrenName()%></span>
          </div>
          <div class="slds-detail-item">
            <span class="slds-item-label">Date of Birth</span>
            <span class="slds-item-value"><%=bean.getDob()%></span>
          </div>
          <div class="slds-detail-item">
            <span class="slds-item-label">Gender</span>
            <span class="slds-item-value"><%=bean.getGender()%></span>
          </div>
          <div class="slds-detail-item">
            <span class="slds-item-label">Relationship</span>
            <span class="slds-item-value"><%=bean.getRelationship()%></span>
          </div>
          <div class="slds-detail-item">
            <span class="slds-item-label">Child Order</span>
            <span class="slds-item-value"><%=bean.getChildOrder()%></span>
          </div>
        </div>

        <!-- 3. Academic Details -->
        <div class="slds-section-header">
          <span class="slds-section-title">3. Academic Details</span>
        </div>

        <div class="slds-detail-grid">
          <div class="slds-detail-item">
            <span class="slds-item-label">College Name</span>
            <span class="slds-item-value"><%=bean.getCollegeName()%></span>
          </div>
          <div class="slds-detail-item">
            <span class="slds-item-label">Course</span>
            <span class="slds-item-value"><%=bean.getCourse()%></span>
          </div>
          <div class="slds-detail-item">
            <span class="slds-item-label">Present Year</span>
            <span class="slds-item-value"><%=bean.getPresentYear()%></span>
          </div>
          <div class="slds-detail-item">
            <span class="slds-item-label">Previous AY Percentage</span>
            <span class="slds-item-value"><%=bean.getPreviousAyPercentage()%>%</span>
          </div>
          <div class="slds-detail-item">
            <span class="slds-item-label">Fee Amount (Current AY)</span>
            <span class="slds-item-value">₹<%=bean.getFeeAmountCurrentAy()%></span>
          </div>
        </div>

      </div>
      <!-- END PRINTABLE AREA -->

      <!-- START NON-PRINTABLE AREA (Bank Details & Document Uploads) -->
      <div class="non-printable">

        <!-- 4. Bank Details -->
        <div class="slds-section-header">
          <span class="slds-section-title">4. Bank Account Details</span>
        </div>

        <div class="slds-detail-grid">
          <div class="slds-detail-item">
            <span class="slds-item-label">Name as per Passbook</span>
            <span class="slds-item-value"><%=bean.getEmployeeNamePassbook()%></span>
          </div>
          <div class="slds-detail-item">
            <span class="slds-item-label">Bank Account Number</span>
            <span class="slds-item-value"><%=bean.getBankAccountNo()%></span>
          </div>
          <div class="slds-detail-item">
            <span class="slds-item-label">IFSC Code</span>
            <span class="slds-item-value"><%=bean.getIfscCode()%></span>
          </div>
          <div class="slds-detail-item">
            <span class="slds-item-label">Bank Name</span>
            <span class="slds-item-value"><%=bean.getBankName()%></span>
          </div>
          <div class="slds-detail-item">
            <span class="slds-item-label">Branch Name</span>
            <span class="slds-item-value"><%=bean.getBranchName()%></span>
          </div>
        </div>

        <!-- 5. Document Upload Section -->
        <form action="ScholarshipDocumentUploadServlet" method="post" enctype="multipart/form-data">
          <input type="hidden" name="id" value="<%=bean.getId()%>">

          <div class="slds-section-header">
            <span class="slds-section-title">5. Document Uploads</span>
          </div>

          <div class="doc-grid">

            <div class="doc-card">
              <span class="doc-card-title">Previous AY Marks Card</span>
              <div class="file-container">
                <% if(bean.getPreviousAyMarksCard() != null) { %>
                  <a href="ScholarshipDocumentDownloadServlet?id=<%=bean.getId()%>&field=previousAyMarksCard" target="_blank" class="status-badge view">✓ View Document</a>
                <% } else { %>
                  <span class="status-badge none">⚠ No file uploaded</span>
                <% } %>
              </div>
              <input type="file" name="previousAyMarksCard" accept=".pdf,.jpg,.jpeg,.png">
            </div>

            <div class="doc-card">
              <span class="doc-card-title">KSS Application</span>
              <div class="file-container">
                <% if(bean.getKssApplication() != null) { %>
                  <a href="ScholarshipDocumentDownloadServlet?id=<%=bean.getId()%>&field=kssApplication" target="_blank" class="status-badge view">✓ View Document</a>
                <% } else { %>
                  <span class="status-badge none">⚠ No file uploaded</span>
                <% } %>
              </div>
              <input type="file" name="kssApplication" accept=".pdf,.jpg,.jpeg,.png">
            </div>

            <div class="doc-card">
              <span class="doc-card-title">Fee Structure</span>
              <div class="file-container">
                <% if(bean.getFeeStructure() != null) { %>
                  <a href="ScholarshipDocumentDownloadServlet?id=<%=bean.getId()%>&field=feeStructure" target="_blank" class="status-badge view">✓ View Document</a>
                <% } else { %>
                  <span class="status-badge none">⚠ No file uploaded</span>
                <% } %>
              </div>
              <input type="file" name="feeStructure" accept=".pdf,.jpg,.jpeg,.png">
            </div>

            <div class="doc-card">
              <span class="doc-card-title">Fee Receipts</span>
              <div class="file-container">
                <% if(bean.getFeeReceipts() != null) { %>
                  <a href="ScholarshipDocumentDownloadServlet?id=<%=bean.getId()%>&field=feeReceipts" target="_blank" class="status-badge view">✓ View Document</a>
                <% } else { %>
                  <span class="status-badge none">⚠ No file uploaded</span>
                <% } %>
              </div>
              <input type="file" name="feeReceipts" accept=".pdf,.jpg,.jpeg,.png">
            </div>

            <div class="doc-card">
              <span class="doc-card-title">Parent Identity Document</span>
              <div class="file-container">
                <% if(bean.getParentAadharCopy() != null) { %>
                  <a href="ScholarshipDocumentDownloadServlet?id=<%=bean.getId()%>&field=parentAadharCopy" target="_blank" class="status-badge view">✓ View Document</a>
                <% } else { %>
                  <span class="status-badge none">⚠ No file uploaded</span>
                <% } %>
              </div>
              <input type="file" name="parentAadharCopy" accept=".pdf,.jpg,.jpeg,.png">
            </div>

            <div class="doc-card">
              <span class="doc-card-title">Student Identity Document</span>
              <div class="file-container">
                <% if(bean.getStudentAadharCopy() != null) { %>
                  <a href="ScholarshipDocumentDownloadServlet?id=<%=bean.getId()%>&field=studentAadharCopy" target="_blank" class="status-badge view">✓ View Document</a>
                <% } else { %>
                  <span class="status-badge none">⚠ No file uploaded</span>
                <% } %>
              </div>
              <input type="file" name="studentAadharCopy" accept=".pdf,.jpg,.jpeg,.png">
            </div>

            <div class="doc-card" style="grid-column: span 2;">
              <span class="doc-card-title">Bank Passbook First Page</span>
              <div class="file-container">
                <% if(bean.getBankPassbookFirstPage() != null) { %>
                  <a href="ScholarshipDocumentDownloadServlet?id=<%=bean.getId()%>&field=bankPassbookFirstPage" target="_blank" class="status-badge view">✓ View Document</a>
                <% } else { %>
                  <span class="status-badge none">⚠ No file uploaded</span>
                <% } %>
              </div>
              <input type="file" name="bankPassbookFirstPage" accept=".pdf,.jpg,.jpeg,.png">
            </div>

          </div>

          <div class="btn-actions" style="margin-top: 20px;">
            <input type="submit" value="Upload Documents" class="btn">
            <a href="ScholarshipListServelt" class="btn btn-secondary">Back to List</a>
          </div>

        </form>

      </div>
      <!-- END NON-PRINTABLE AREA -->

    </div>

  </div>

<% } %>

</div>

</body>
</html>