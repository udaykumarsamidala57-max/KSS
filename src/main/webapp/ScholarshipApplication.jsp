<%@ page import="java.sql.*" %>
<%@ page import="com.Bean.DBUtil" %>
<%
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    String roles = (String) sess.getAttribute("role");
%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Scholarship Application Form</title>

<!-- INCLUDE SHARED HEADER & MENU -->
<%@ include file="header.jsp" %>

<style>
  /* Salesforce Lightning Design System (SLDS) Core Variables */
  :root {
    --slds-brand: #0176d3;
    --slds-brand-hover: #014486;
    --slds-bg-page: #f3f5f8;
    --slds-card-bg: #ffffff;
    --slds-border: #dddbda;
    --slds-border-dark: #c9c7c5;
    --slds-text-primary: #080707;
    --slds-text-secondary: #444444;
    --slds-text-label: #514f4d;
    --slds-section-bg: #f3f5f8;
    --slds-radius: 4px;
  }

  * {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
  }

  body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
    background-color: var(--slds-bg-page);
    color: var(--slds-text-primary);
    padding: 16px 20px 80px 20px;
    -webkit-font-smoothing: antialiased;
  }

  /* Main Wrapper: Flex Layout for Form + Right Sidebar */
  .page-layout {
    max-width: 1400px;
    margin: 0 auto;
    display: flex;
    gap: 20px;
    align-items: flex-start;
  }

  /* Form Main Container Container */
  .main-form-area {
    flex: 1;
    display: flex;
    flex-direction: column;
    gap: 16px;
  }

  /* Salesforce Page Header / Title Component */
  .slds-page-header {
    background-color: var(--slds-card-bg);
    border: 1px solid var(--slds-border);
    border-radius: var(--slds-radius);
    padding: 16px 24px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    box-shadow: 0 2px 2px 0 rgba(0, 0, 0, 0.1);
  }

  .slds-header-title-wrapper {
    display: flex;
    align-items: center;
    gap: 12px;
  }

  .slds-icon-box {
    width: 38px;
    height: 38px;
    background-color: #4bca81;
    border-radius: 4px;
    display: flex;
    align-items: center;
    justify-content: center;
    color: #ffffff;
    font-weight: 700;
    font-size: 18px;
    box-shadow: inset 0 -1px 0 rgba(0,0,0,0.2);
  }

  .slds-header-details {
    display: flex;
    flex-direction: column;
  }

  .slds-header-subtitle {
    font-size: 11px;
    font-weight: 600;
    text-transform: uppercase;
    color: var(--slds-text-secondary);
    letter-spacing: 0.5px;
  }

  .slds-header-title {
    margin: 2px 0 0 0;
    font-size: 20px;
    font-weight: 700;
    color: var(--slds-text-primary);
    line-height: 1.2;
  }

  /* Salesforce Card Container */
  .slds-card {
    background: var(--slds-card-bg);
    border: 1px solid var(--slds-border);
    border-radius: var(--slds-radius);
    box-shadow: 0 2px 2px 0 rgba(0, 0, 0, 0.1);
    overflow: hidden;
  }

  .form-body {
    padding: 20px 24px;
  }

  /* Salesforce Section Headers */
  .slds-section-title {
    background-color: var(--slds-section-bg);
    color: var(--slds-text-primary);
    padding: 8px 12px;
    font-size: 12px;
    font-weight: 700;
    border-left: 3px solid var(--slds-brand);
    margin: 20px 0 16px 0;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    border-radius: 0 2px 2px 0;
  }

  .slds-section-title:first-of-type {
    margin-top: 0;
  }

  /* Compact Grid Layout */
  .form-grid {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 14px 20px;
  }

  .form-group {
    display: flex;
    flex-direction: column;
  }

  .form-group.full-width {
    grid-column: span 2;
  }

  label {
    font-size: 12px;
    font-weight: 600;
    color: var(--slds-text-label);
    margin-bottom: 4px;
  }

  label .required {
    color: #ea001e;
    font-weight: bold;
    margin-left: 2px;
  }

  /* Salesforce Input & Select Controls */
  input[type=text],
  input[type=date],
  input[type=number],
  select {
    width: 100%;
    padding: 6px 12px;
    font-size: 13px;
    height: 36px;
    color: var(--slds-text-primary);
    background-color: #ffffff;
    border: 1px solid var(--slds-border);
    border-radius: var(--slds-radius);
    transition: border-color 0.15s ease, box-shadow 0.15s ease;
    outline: none;
  }

  /* Read-only field styling */
  input[readonly] {
    background-color: var(--slds-section-bg);
    color: var(--slds-text-secondary);
    cursor: not-allowed;
  }

  input[type=text]:focus,
  input[type=date]:focus,
  input[type=number]:focus,
  select:focus {
    border-color: var(--slds-brand);
    box-shadow: 0 0 0 1px var(--slds-brand);
  }

  /* Salesforce Standard Buttons */
  .form-actions {
    text-align: right;
    margin-top: 24px;
    padding-top: 16px;
    border-top: 1px solid var(--slds-border);
  }

  .slds-btn {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    padding: 0 20px;
    height: 36px;
    font-size: 13px;
    font-weight: 600;
    border-radius: var(--slds-radius);
    text-decoration: none;
    cursor: pointer;
    transition: all 0.15s ease-in-out;
    border: 1px solid transparent;
    line-height: 1;
    box-sizing: border-box;
  }

  .slds-btn-brand {
    background-color: var(--slds-brand);
    color: #ffffff;
    border-color: var(--slds-brand);
  }

  .slds-btn-brand:hover {
    background-color: var(--slds-brand-hover);
    border-color: var(--slds-brand-hover);
    color: #ffffff;
  }

  /* RIGHT SIDEBAR PANEL */
  .info-sidebar {
    width: 310px;
    flex-shrink: 0;
    display: flex;
    flex-direction: column;
    gap: 16px;
    position: sticky;
    top: 20px;
  }

  .sidebar-card {
    background: var(--slds-card-bg);
    border-radius: var(--slds-radius);
    border: 1px solid var(--slds-border);
    box-shadow: 0 2px 2px 0 rgba(0, 0, 0, 0.1);
    overflow: hidden;
  }

  .sidebar-header {
    background-color: #fafaf9;
    border-bottom: 1px solid var(--slds-border);
    color: var(--slds-text-primary);
    padding: 10px 14px;
    font-size: 12px;
    font-weight: 700;
    letter-spacing: 0.5px;
    text-transform: uppercase;
    display: flex;
    align-items: center;
    gap: 8px;
  }

  .sidebar-body {
    padding: 14px;
    font-size: 12px;
    color: var(--slds-text-secondary);
    line-height: 1.5;
  }

  /* Deadline Box */
  .deadline-box {
    background-color: #fef1f2;
    border: 1px solid #fecdd3;
    border-radius: var(--slds-radius);
    padding: 12px;
    text-align: center;
  }

  .deadline-label {
    font-size: 11px;
    text-transform: uppercase;
    font-weight: 700;
    color: #9f1239;
  }

  .deadline-date {
    font-size: 16px;
    font-weight: 800;
    color: #e11d48;
    margin-top: 2px;
  }

  /* Bullet List Rules */
  .rules-list {
    list-style: none;
  }

  .rules-list li {
    position: relative;
    padding-left: 16px;
    margin-bottom: 8px;
    font-size: 12px;
    color: var(--slds-text-primary);
  }

  .rules-list li::before {
    content: "•";
    color: var(--slds-brand);
    font-size: 16px;
    font-weight: bold;
    position: absolute;
    left: 2px;
    top: -2px;
  }

  .contact-item {
    display: flex;
    flex-direction: column;
    margin-bottom: 10px;
  }

  .contact-item:last-child {
    margin-bottom: 0;
  }

  .contact-label {
    font-weight: 700;
    font-size: 11px;
    color: var(--slds-text-label);
    text-transform: uppercase;
  }

  .contact-val {
    font-size: 12px;
    color: var(--slds-text-primary);
  }

  /* Responsive Layout */
  @media (max-width: 992px) {
    .page-layout {
      flex-direction: column;
    }
    .info-sidebar {
      width: 100%;
      position: static;
    }
  }

  @media (max-width: 768px) {
    .form-grid {
      grid-template-columns: 1fr;
    }
    .form-group.full-width {
      grid-column: span 1;
    }
  }
</style>
</head>
<body>

<div class="page-layout">

  <!-- LEFT SIDE: MAIN FORM AREA -->
  <div class="main-form-area">

    <!-- PAGE HEADER BAR -->
    <div class="slds-page-header">
      <div class="slds-header-title-wrapper">
      
        <div class="slds-header-details">
          
          <h1 class="slds-header-title">Scholarship Application Form</h1>
        </div>
      </div>
    </div>

    <!-- MAIN FORM CARD -->
    <div class="slds-card">
      <form action="ScholarshipServlet" method="post" class="form-body">

        <!-- Section 1: Employment Details -->
        <div class="slds-section-title">1. Employee Details</div>
        <div class="form-grid">
          <div class="form-group full-width">
            <label>Organization Name <span class="required">*</span></label>
            <select name="orgName" required>
              <option value="">-- Select Organization --</option>
             <%
Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

try {

    con = DBUtil.getConnection();

    if ("Global".equalsIgnoreCase(roles)) {

        ps = con.prepareStatement(
            "SELECT org_name FROM organization_master WHERE status='Active' ORDER BY org_name");

    } else {

        ps = con.prepareStatement(
            "SELECT org_name FROM organization_master WHERE status='Active' AND org_name=? ORDER BY org_name");

        ps.setString(1, roles);
    }

    rs = ps.executeQuery();

    while (rs.next()) {
%>

<option value="<%= rs.getString("org_name") %>">
    <%= rs.getString("org_name") %>
</option>

<%
    }

} catch (Exception e) {

    e.printStackTrace();
    out.println("<option>Error Loading Organizations</option>");

} finally {

    if (rs != null) rs.close();
    if (ps != null) ps.close();
    if (con != null) con.close();
}
%>
</select>
          </div>

          <div class="form-group">
            <label>Employee No <span class="required">*</span></label>
            <input type="text" name="empNo" required placeholder="Enter Employee Number">
          </div>

          <div class="form-group">
            <label>Employee Name <span class="required">*</span></label>
            <input type="text" name="empName" required placeholder="Enter Full Name">
          </div>

          <div class="form-group">
            <label>Designation</label>
            <input type="text" name="designation" placeholder="Enter Designation">
          </div>

          <div class="form-group">
            <label>Spouse Working in SMIORE?</label>
            <select name="spouseWorkingSMIORE">
              <option value="No">No</option>
              <option value="Yes">Yes</option>
            </select>
          </div>

          <div class="form-group full-width">
            <label>Spouse Working in Group Companies?</label>
            <select name="spouseWorkingGroupCompanies">
              <option value="No">No</option>
              <option value="Yes">Yes</option>
            </select>
          </div>
        </div>

        <!-- Section 2: Student Details -->
        <div class="slds-section-title">2. Child / Student Details</div>
        <div class="form-grid">
          <div class="form-group">
            <label>Child's Name</label>
            <input type="text" name="childrenName" placeholder="Enter Child's Full Name">
          </div>

          <div class="form-group">
            <label>Date of Birth</label>
            <input type="date" id="dob" name="dob" onchange="calculateAge()">
          </div>

          <div class="form-group">
            <label>Calculated Age</label>
            <input type="text" id="age" name="age" readonly placeholder="Calculated Age">
          </div>

          <div class="form-group">
            <label>Gender</label>
            <select name="gender">
              <option value="">Select Gender</option>
              <option value="Male">Male</option>
              <option value="Female">Female</option>
              <option value="Other">Other</option>
            </select>
          </div>

          <div class="form-group">
            <label>Relationship</label>
            <input type="text" name="relationship" placeholder="e.g. Son / Daughter">
          </div>

          <div class="form-group">
            <label>Child Order</label>
            <select name="childOrder">
              <option value="">Select Child Order</option>
              <option value="First">First Child</option>
              <option value="Second">Second Child</option>
            </select>
          </div>
        </div>

        <!-- Section 3: Academic Details -->
        <div class="slds-section-title">3. Academic Details</div>
        <div class="form-grid">
          <div class="form-group full-width">
            <label>College Name</label>
            <input type="text" name="collegeName" placeholder="Enter College Name">
          </div>

          <div class="form-group">
            <label>Course Name</label>
            <input type="text" name="course" placeholder="e.g. B.Tech, B.Sc">
          </div>

          <div class="form-group">
            <label>Present Year</label>
            <input type="text" name="presentYear" placeholder="e.g. 1st Year, 2nd Year">
          </div>

          <div class="form-group">
            <label>Previous Academic Year (%)</label>
            <input type="number" step="0.01" name="previousAyPercentage" placeholder="e.g. 85.50">
          </div>

          <div class="form-group">
            <label>Fee Amount for Current AY</label>
            <input type="number" step="0.01" name="feeAmountCurrentAy" placeholder="e.g. 50000.00">
          </div>
        </div>

        <!-- Section 4: Bank Account Details -->
        <div class="slds-section-title">4. Bank Account Details</div>
        <div class="form-grid">
          <div class="form-group full-width">
            <label>Name as per Bank Passbook</label>
            <input type="text" name="employeeNamePassbook" placeholder="Enter Name as shown in Passbook">
          </div>

          <div class="form-group">
            <label>Bank Account Number</label>
            <input type="text" name="bankAccountNo" placeholder="Enter Account Number">
          </div>

          <div class="form-group">
            <label>IFSC Code</label>
            <input type="text" name="ifscCode" placeholder="Enter IFSC Code">
          </div>

          <div class="form-group">
            <label>Bank Name</label>
            <input type="text" name="bankName" placeholder="Enter Bank Name">
          </div>

          <div class="form-group">
            <label>Branch Name</label>
            <input type="text" name="branchName" placeholder="Enter Branch Name">
          </div>
        </div>

        <!-- Submit Section -->
        <div class="form-actions">
          <button type="submit" class="slds-btn slds-btn-brand">Save Basic Details</button>
        </div>

      </form>
    </div>

  </div>

  <!-- RIGHT SIDE: INFORMATION / RULES SIDEBAR -->
  <aside class="info-sidebar">

    <!-- Card 1: Application Deadline -->
    <div class="sidebar-card">
      <div class="sidebar-header">
        Important Deadline
      </div>
      <div class="sidebar-body">
        <div class="deadline-box">
          <div class="deadline-label">Last Date for Submission</div>
          <div class="deadline-date">31st August 2026</div>
        </div>
        <p style="font-size: 11px; text-align: center; color: var(--slds-text-secondary); margin-top: 8px;">
          Late or incomplete applications will not be processed.
        </p>
      </div>
    </div>

    <!-- Card 2: Key Guidelines & Rules -->
    <div class="sidebar-card">
      <div class="sidebar-header">
        Eligibility & Guidelines
      </div>
      <div class="sidebar-body">
        <ul class="rules-list">
          <li>Minimum <strong>60% marks</strong> required in previous academic year.</li>
          <li>Scholarship is applicable for up to <strong>two children</strong> per employee.</li>
          <li>Employee bank account details must match the passbook exactly.</li>
          <li>Ensure course details are for full-time higher education programs.</li>
        </ul>
      </div>
    </div>

    <!-- Card 3: Support Contact -->
    <div class="sidebar-card">
      <div class="sidebar-header">
        Help & Support
      </div>
      <div class="sidebar-body">
        <div class="contact-item">
          <span class="contact-label">Email Support</span>
          <span class="contact-val">saritha@sandurschool.com</span>
        </div>
        <div class="contact-item">
          <span class="contact-label">Helpdesk Helpline</span>
          <span class="contact-val">+91 999999999</span>
        </div>
        <div class="contact-item">
          <span class="contact-label">Office Hours</span>
          <span class="contact-val">Mon - Fri (9:30 AM - 5:30 PM)</span>
        </div>
      </div>
    </div>

  </aside>

</div>

<script>
  function calculateAge() {
    const dobInput = document.getElementById('dob').value;
    const ageInput = document.getElementById('age');

    if (!dobInput) {
      ageInput.value = '';
      return;
    }

    const birthDate = new Date(dobInput);
    const today = new Date();

    let age = today.getFullYear() - birthDate.getFullYear();
    const monthDiff = today.getMonth() - birthDate.getMonth();

    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birthDate.getDate())) {
      age--;
    }

    if (age < 0) {
      ageInput.value = 'Invalid DOB';
    } else {
      ageInput.value = age + (age === 1 ? ' year old' : ' years old');
    }
  }
</script>

</body>
</html>