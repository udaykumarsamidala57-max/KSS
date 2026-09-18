<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.Bean.ScholarshipBean"%>
<%
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    
    ScholarshipBean bean = (ScholarshipBean) request.getAttribute("bean");
    if (bean == null) {
        response.sendRedirect("ScholarshipListServelt");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>View Scholarship Application</title>

<!-- INCLUDE SHARED HEADER & MENU -->
<%@ include file="header.jsp" %>

<style>
  :root {
    --slds-brand: #0176d3;
    --slds-bg-page: #f3f5f8;
    --slds-card-bg: #ffffff;
    --slds-border: #dddbda;
    --slds-text-primary: #080707;
    --slds-text-secondary: #444444;
    --slds-text-label: #514f4d;
    --slds-radius: 4px;
  }

  body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    background-color: var(--slds-bg-page);
    margin: 0;
    padding: 16px 20px 80px 20px;
    color: var(--slds-text-primary);
  }

  .slds-container {
    max-width: 1200px;
    margin: 0 auto;
  }

  .slds-page-header {
    background-color: var(--slds-card-bg);
    border: 1px solid var(--slds-border);
    border-radius: var(--slds-radius);
    padding: 16px 24px;
    margin-bottom: 16px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    box-shadow: 0 2px 2px 0 rgba(0, 0, 0, 0.1);
  }

  .slds-header-title {
    margin: 0;
    font-size: 20px;
    font-weight: 700;
  }

  .slds-card {
    background: var(--slds-card-bg);
    border: 1px solid var(--slds-border);
    border-radius: var(--slds-radius);
    padding: 24px;
    box-shadow: 0 2px 2px 0 rgba(0, 0, 0, 0.1);
    margin-bottom: 20px;
  }

  .slds-section-title {
    background-color: #f3f5f8;
    color: var(--slds-text-primary);
    padding: 8px 12px;
    font-size: 12px;
    font-weight: 700;
    border-left: 3px solid var(--slds-brand);
    margin: 24px 0 16px 0;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }

  .slds-section-title:first-of-type {
    margin-top: 0;
  }

  .detail-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
    gap: 16px 24px;
  }

  .detail-item {
    display: flex;
    flex-direction: column;
  }

  .detail-label {
    font-size: 12px;
    font-weight: 600;
    color: var(--slds-text-label);
    margin-bottom: 4px;
  }

  .detail-value {
    font-size: 14px;
    color: var(--slds-text-primary);
    font-weight: 500;
    background-color: #fcfcfc;
    border: 1px solid var(--slds-border);
    padding: 8px 12px;
    border-radius: var(--slds-radius);
    min-height: 20px;
  }

  .slds-btn {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    padding: 0 16px;
    height: 32px;
    font-size: 13px;
    font-weight: 600;
    border-radius: var(--slds-radius);
    text-decoration: none;
    border: 1px solid var(--slds-border);
    background-color: #ffffff;
    color: var(--slds-brand);
  }

  .slds-btn:hover {
    background-color: #f4f6f9;
  }
</style>
</head>
<body>

<div class="slds-container">

  <div class="slds-page-header">
    <h1 class="slds-header-title">Application Details (#<%= bean.getId() %>)</h1>
    <a href="ScholarshipListServelt" class="slds-btn">&larr; Back to List</a>
  </div>

  <div class="slds-card">

    <!-- 1. Employee Details -->
    <div class="slds-section-title">1. Employee Details</div>
    <div class="detail-grid">
      <div class="detail-item">
        <span class="detail-label">Organization Name</span>
        <span class="detail-value"><%= bean.getOrgName() != null ? bean.getOrgName() : "-" %></span>
      </div>
      <div class="detail-item">
        <span class="detail-label">Employee No</span>
        <span class="detail-value"><%= bean.getEmpNo() != null ? bean.getEmpNo() : "-" %></span>
      </div>
      <div class="detail-item">
        <span class="detail-label">Employee Name</span>
        <span class="detail-value"><%= bean.getEmpName() != null ? bean.getEmpName() : "-" %></span>
      </div>
      <div class="detail-item">
        <span class="detail-label">Designation</span>
        <span class="detail-value"><%= bean.getDesignation() != null ? bean.getDesignation() : "-" %></span>
      </div>
      <div class="detail-item">
        <span class="detail-label">Spouse Working in SMIORE?</span>
        <span class="detail-value"><%= bean.getSpouseWorkingSMIORE() != null ? bean.getSpouseWorkingSMIORE() : "-" %></span>
      </div>
      <div class="detail-item">
        <span class="detail-label">Spouse Working in Group Co.?</span>
        <span class="detail-value"><%= bean.getSpouseWorkingGroupCompanies() != null ? bean.getSpouseWorkingGroupCompanies() : "-" %></span>
      </div>
    </div>

    <!-- 2. Child / Student Details -->
    <div class="slds-section-title">2. Child / Student Details</div>
    <div class="detail-grid">
      <div class="detail-item">
        <span class="detail-label">Child's Name</span>
        <span class="detail-value"><%= bean.getChildrenName() != null ? bean.getChildrenName() : "-" %></span>
      </div>
      <div class="detail-item">
        <span class="detail-label">Date of Birth</span>
        <span class="detail-value"><%= bean.getDob() != null ? bean.getDob() : "-" %></span>
      </div>
      <div class="detail-item">
        <span class="detail-label">Gender</span>
        <span class="detail-value"><%= bean.getGender() != null ? bean.getGender() : "-" %></span>
      </div>
      <div class="detail-item">
        <span class="detail-label">Relationship</span>
        <span class="detail-value"><%= bean.getRelationship() != null ? bean.getRelationship() : "-" %></span>
      </div>
      <div class="detail-item">
        <span class="detail-label">Child Order</span>
        <span class="detail-value"><%= bean.getChildOrder() != null ? bean.getChildOrder() : "-" %></span>
      </div>
    </div>

    <!-- 3. Academic Details -->
    <div class="slds-section-title">3. Academic Details</div>
    <div class="detail-grid">
      <div class="detail-item">
        <span class="detail-label">College Name</span>
        <span class="detail-value"><%= bean.getCollegeName() != null ? bean.getCollegeName() : "-" %></span>
      </div>
      <div class="detail-item">
        <span class="detail-label">Place of College</span>
        <span class="detail-value"><%= bean.getPlaceCollege() != null ? bean.getPlaceCollege() : "-" %></span>
      </div>
      <div class="detail-item">
        <span class="detail-label">Course Name</span>
        <span class="detail-value"><%= bean.getCourse() != null ? bean.getCourse() : "-" %></span>
      </div>
      <div class="detail-item">
        <span class="detail-label">Present Year</span>
        <span class="detail-value"><%= bean.getPresentYear() != null ? bean.getPresentYear() : "-" %></span>
      </div>
      <div class="detail-item">
        <span class="detail-label">Prev AY Percentage (%)</span>
        <span class="detail-value"><%= bean.getPreviousAyPercentage() %>%</span>
      </div>
      <div class="detail-item">
        <span class="detail-label">Fee Amount Current AY</span>
        <span class="detail-value"><%= bean.getFeeAmountCurrentAy() %></span>
      </div>
    </div>

    <!-- 4. Bank Account Details -->
    <div class="slds-section-title">4. Bank Account Details</div>
    <div class="detail-grid">
      <div class="detail-item">
        <span class="detail-label">Name as per Passbook</span>
        <span class="detail-value"><%= bean.getEmployeeNamePassbook() != null ? bean.getEmployeeNamePassbook() : "-" %></span>
      </div>
      <div class="detail-item">
        <span class="detail-label">Bank Account Number</span>
        <span class="detail-value"><%= bean.getBankAccountNo() != null ? bean.getBankAccountNo() : "-" %></span>
      </div>
      <div class="detail-item">
        <span class="detail-label">IFSC Code</span>
        <span class="detail-value"><%= bean.getIfscCode() != null ? bean.getIfscCode() : "-" %></span>
      </div>
      <div class="detail-item">
        <span class="detail-label">Bank Name</span>
        <span class="detail-value"><%= bean.getBankName() != null ? bean.getBankName() : "-" %></span>
      </div>
      <div class="detail-item">
        <span class="detail-label">Branch Name</span>
        <span class="detail-value"><%= bean.getBranchName() != null ? bean.getBranchName() : "-" %></span>
      </div>
    </div>

  </div>

</div>

</body>
</html>