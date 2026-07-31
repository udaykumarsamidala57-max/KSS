<%@ page import="java.sql.*" %>
<%@ page import="com.Bean.DBUtil" %>
<%
    
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    %>
<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Scholarship Application Form</title>

<style>
  :root {
    --primary-color: #7a1f35;       /* Muted rich burgundy */
    --primary-hover: #5e1627;       /* Darker shade for buttons */
    --accent-bg: #fdf6f7;           /* Extra soft warm white background */
    --border-color: #e2cece;        /* Muted reddish gray border */
    --text-main: #2b2b2b;
    --text-muted: #555555;
    --bg-main: #f9f6f6;              
  }

  * {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
  }

  body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
    background-color: var(--bg-main);
    color: var(--text-main);
    padding: 24px 12px;
    -webkit-font-smoothing: antialiased;
  }

  /* Main Wrapper: Flex Layout for Form + Right Sidebar */
  .page-layout {
    max-width: 1140px;
    margin: 0 auto;
    display: flex;
    gap: 20px;
    align-items: flex-start;
  }

  /* Form Main Container */
  .container {
    flex: 1;
    background: #ffffff;
    border-radius: 8px;
    box-shadow: 0 4px 16px rgba(0, 0, 0, 0.04);
    border: 1px solid var(--border-color);
    overflow: hidden;
  }

  /* Header Section */
  .form-header {
    background: linear-gradient(180deg, var(--primary-color) 0%, var(--primary-hover) 100%);
    color: #ffffff;
    padding: 16px 20px;
    text-align: center;
  }

  .form-header h2 {
    font-size: 18px;
    font-weight: 700;
    letter-spacing: 0.5px;
    text-transform: uppercase;
  }

  .form-header p {
    font-size: 12px;
    margin-top: 3px;
    opacity: 0.9;
  }

  .form-body {
    padding: 20px 25px;
  }

  /* PF Style Section Cards */
  .section-title {
    background-color: var(--accent-bg);
    color: var(--primary-color);
    padding: 6px 12px;
    font-size: 13px;
    font-weight: 700;
    border-left: 3px solid var(--primary-color);
    margin-top: 18px;
    margin-bottom: 12px;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }

  .section-title:first-of-type {
    margin-top: 0;
  }

  /* Compact Grid Layout */
  .form-grid {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 10px 18px;
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
    color: #4a4a4a;
    margin-bottom: 3px;
  }

  label .required {
    color: var(--primary-color);
    font-weight: bold;
  }

  /* Compact Input & Select Controls */
  input[type=text],
  input[type=date],
  input[type=number],
  select {
    width: 100%;
    padding: 6px 10px;
    font-size: 13px;
    height: 32px;
    color: var(--text-main);
    background-color: #fff;
    border: 1px solid var(--border-color);
    border-radius: 4px;
    transition: all 0.2s ease-in-out;
    outline: none;
  }

  /* Read-only age field styling */
  input[readonly] {
    background-color: #f7f7f7;
    color: #555555;
    font-weight: 600;
  }

  input[type=text]:focus,
  input[type=date]:focus,
  input[type=number]:focus,
  select:focus {
    border-color: var(--primary-color);
    box-shadow: 0 0 0 2px rgba(122, 31, 53, 0.15);
  }

  /* Submit Button Styling */
  .form-actions {
    text-align: center;
    margin-top: 20px;
    padding-top: 15px;
    border-top: 1px solid #f0e6e6;
  }

  input[type=submit] {
    background-color: var(--primary-color);
    color: #ffffff;
    border: none;
    padding: 8px 30px;
    font-size: 13px;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    border-radius: 4px;
    cursor: pointer;
    transition: background-color 0.2s ease, transform 0.1s ease;
  }

  input[type=submit]:hover {
    background-color: var(--primary-hover);
  }

  input[type=submit]:active {
    transform: scale(0.98);
  }

  /* RIGHT SIDEBAR PANEL */
  .info-sidebar {
    width: 290px;
    flex-shrink: 0;
    display: flex;
    flex-direction: column;
    gap: 15px;
    position: sticky;
    top: 20px;
  }

  .sidebar-card {
    background: #ffffff;
    border-radius: 8px;
    border: 1px solid var(--border-color);
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.03);
    overflow: hidden;
  }

  .sidebar-header {
    background-color: var(--primary-color);
    color: #ffffff;
    padding: 10px 14px;
    font-size: 13px;
    font-weight: 700;
    letter-spacing: 0.5px;
    text-transform: uppercase;
    display: flex;
    align-items: center;
    gap: 8px;
  }

  .sidebar-body {
    padding: 12px 14px;
    font-size: 12px;
    color: var(--text-muted);
    line-height: 1.5;
  }

  /* Urgent Highlight Box for Last Date */
  .deadline-box {
    background-color: #fff0f3;
    border: 1px solid #f5c2c7;
    border-radius: 6px;
    padding: 10px;
    text-align: center;
    margin-bottom: 4px;
  }

  .deadline-label {
    font-size: 11px;
    text-transform: uppercase;
    font-weight: 700;
    color: #842029;
  }

  .deadline-date {
    font-size: 15px;
    font-weight: 800;
    color: #b02a37;
    margin-top: 2px;
  }

  /* Bullet List Rules */
  .rules-list {
    list-style: none;
    margin-top: 4px;
  }

  .rules-list li {
    position: relative;
    padding-left: 16px;
    margin-bottom: 8px;
    font-size: 12px;
    color: #333;
  }

  .rules-list li::before {
    content: "•";
    color: var(--primary-color);
    font-size: 16px;
    font-weight: bold;
    position: absolute;
    left: 2px;
    top: -2px;
  }

  .contact-item {
    display: flex;
    flex-direction: column;
    margin-bottom: 8px;
  }

  .contact-item:last-child {
    margin-bottom: 0;
  }

  .contact-label {
    font-weight: 700;
    font-size: 11px;
    color: var(--primary-color);
    text-transform: uppercase;
  }

  .contact-val {
    font-size: 12px;
    color: #333;
  }

  /* Responsive Design */
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

<%@ include file="header.jsp" %>

<div class="page-layout">

  <!-- LEFT SIDE: MAIN FORM CONTAINER -->
  <div class="container">

    <div class="form-header">
      <h2>Scholarship Application Form</h2>
      <p>Please fill in all mandatory details accurately</p>
    </div>

    <form action="ScholarshipServlet" method="post" class="form-body">

      <!-- Section 1: Employment Details -->
      <div class="section-title">1. Employee Details</div>
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
                    ps = con.prepareStatement(
                        "SELECT org_name FROM organization_master WHERE status='Active' ORDER BY org_name");
                    rs = ps.executeQuery();

                    while(rs.next()){
            %>
            <option value="<%=rs.getString("org_name")%>">
                <%=rs.getString("org_name")%>
            </option>
            <%
                    }
                } catch(Exception e){
                    out.println("<option>Error Loading Organizations</option>");
                } finally{
                    if(rs!=null) rs.close();
                    if(ps!=null) ps.close();
                    if(con!=null) con.close();
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
      <div class="section-title">2. Child / Student Details</div>
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
          <input type="text" id="age" name="age" readonly placeholder="Age">
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
      <div class="section-title">3. Academic Details</div>
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
      <div class="section-title">4. Bank Account Details</div>
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
        <input type="submit" value="Save Basic Details">
      </div>

    </form>

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
        <p style="font-size: 11px; text-align: center; color: #777; margin-top: 6px;">
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