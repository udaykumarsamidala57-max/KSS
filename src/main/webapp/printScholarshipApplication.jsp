<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.io.*" %>
<%@ page import="javax.servlet.http.*" %>
<%@ page import="com.Bean.DBUtil" %>

<%
    // -------------------------------------------------------------------------
    // 1. SESSION CHECK & AUTHENTICATION
    // -------------------------------------------------------------------------
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    // -------------------------------------------------------------------------
    // 2. COMMON REQUEST PARAMETERS
    // -------------------------------------------------------------------------
    String idParam = request.getParameter("id");
    String mode = request.getParameter("mode");

    // -------------------------------------------------------------------------
    // 3. BLOB DOCUMENT DOWNLOAD HANDLER
    // -------------------------------------------------------------------------
    if ("download".equals(mode) && idParam != null && !idParam.trim().isEmpty()) {
        String field = request.getParameter("field");
        
        // Whitelist allowed BLOB columns to prevent SQL injection
        String targetColumn = null;
        if ("previous_ay_marks_card".equals(field)) targetColumn = "previous_ay_marks_card";
        else if ("kss_application".equals(field)) targetColumn = "kss_application";
        else if ("fee_structure".equals(field)) targetColumn = "fee_structure";
        else if ("fee_receipts".equals(field)) targetColumn = "fee_receipts";
        else if ("parent_aadhar_copy".equals(field)) targetColumn = "parent_aadhar_copy";
        else if ("student_aadhar_copy".equals(field)) targetColumn = "student_aadhar_copy";
        else if ("bank_passbook_first_page".equals(field)) targetColumn = "bank_passbook_first_page";

        if (targetColumn != null) {
            Connection conn = null;
            PreparedStatement pstmt = null;
            ResultSet rs = null;
            try {
                conn = DBUtil.getConnection();
                String sql = "SELECT " + targetColumn + " FROM kss_student_scholarship WHERE id = ?";
                pstmt = conn.prepareStatement(sql);
                pstmt.setInt(1, Integer.parseInt(idParam));
                rs = pstmt.executeQuery();

                if (rs.next()) {
                    byte[] blobData = rs.getBytes(targetColumn);
                    if (blobData != null && blobData.length > 0) {
                        response.reset();
                        response.setContentType("application/octet-stream");
                        response.setHeader("Content-Disposition", "inline; filename=\"" + targetColumn + "_" + idParam + ".pdf\"");
                        response.setContentLength(blobData.length);
                        
                        OutputStream os = response.getOutputStream();
                        os.write(blobData);
                        os.flush();
                        os.close();
                        return; // Halt JSP rendering after writing binary payload
                    }
                }
            } catch (Exception e) {
                e.printStackTrace();
            } finally {
                if (rs != null) try { rs.close(); } catch (Exception e) {}
                if (pstmt != null) try { pstmt.close(); } catch (Exception e) {}
                if (conn != null) try { conn.close(); } catch (Exception e) {}
            }
        }
    }

    // -------------------------------------------------------------------------
    // 4. FETCH APPLICATION DATA FROM DATABASE
    // -------------------------------------------------------------------------
    boolean recordFound = false;
    
    // Application Fields
    int id = 0;
    String orgName = "", empNo = "", empName = "", designation = "";
    String childrenName = "", dob = "", gender = "", relationship = "", childOrder = "";
    String spouseWorkingSmiore = "", spouseWorkingGroupCompanies = "";
    String collegeName = "", course = "", presentYear = "";
    double previousAyPercentage = 0.0;
    double feeAmountCurrentAy = 0.0;
    
    // Bank Details
    String employeeNamePassbook = "", bankAccountNo = "", ifscCode = "", bankName = "", branchName = "";

    // BLOB Existence Verification
    boolean hasPreviousAyMarksCard = false;
    boolean hasKssApplication = false;
    boolean hasFeeStructure = false;
    boolean hasFeeReceipts = false;
    boolean hasParentAadharCopy = false;
    boolean hasStudentAadharCopy = false;
    boolean hasBankPassbookFirstPage = false;

    if (idParam != null && !idParam.trim().isEmpty()) {
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;

        try {
            conn = DBUtil.getConnection();
            String query = "SELECT id, org_name, emp_no, emp_name, designation, children_name, dob, gender, " +
                           "relationship, child_order, spouse_working_smiore, spouse_working_group_companies, " +
                           "college_name, course, present_year, previous_ay_percentage, fee_amount_current_ay, " +
                           "employee_name_passbook, bank_account_no, ifsc_code, bank_name, branch_name, " +
                           "(previous_ay_marks_card IS NOT NULL AND LENGTH(previous_ay_marks_card) > 0) AS has_marks_card, " +
                           "(kss_application IS NOT NULL AND LENGTH(kss_application) > 0) AS has_kss_app, " +
                           "(fee_structure IS NOT NULL AND LENGTH(fee_structure) > 0) AS has_fee_struct, " +
                           "(fee_receipts IS NOT NULL AND LENGTH(fee_receipts) > 0) AS has_fee_rcpt, " +
                           "(parent_aadhar_copy IS NOT NULL AND LENGTH(parent_aadhar_copy) > 0) AS has_p_aadhar, " +
                           "(student_aadhar_copy IS NOT NULL AND LENGTH(student_aadhar_copy) > 0) AS has_s_aadhar, " +
                           "(bank_passbook_first_page IS NOT NULL AND LENGTH(bank_passbook_first_page) > 0) AS has_passbook " +
                           "FROM kss_student_scholarship WHERE id = ?";

            pstmt = conn.prepareStatement(query);
            pstmt.setInt(1, Integer.parseInt(idParam));
            rs = pstmt.executeQuery();

            if (rs.next()) {
                recordFound = true;
                id = rs.getInt("id");
                orgName = rs.getString("org_name");
                empNo = rs.getString("emp_no");
                empName = rs.getString("emp_name");
                designation = rs.getString("designation");
                childrenName = rs.getString("children_name");
                dob = rs.getString("dob");
                gender = rs.getString("gender");
                relationship = rs.getString("relationship");
                childOrder = rs.getString("child_order");
                spouseWorkingSmiore = rs.getString("spouse_working_smiore");
                spouseWorkingGroupCompanies = rs.getString("spouse_working_group_companies");
                collegeName = rs.getString("college_name");
                course = rs.getString("course");
                presentYear = rs.getString("present_year");
                previousAyPercentage = rs.getDouble("previous_ay_percentage");
                feeAmountCurrentAy = rs.getDouble("fee_amount_current_ay");
                
                employeeNamePassbook = rs.getString("employee_name_passbook");
                bankAccountNo = rs.getString("bank_account_no");
                ifscCode = rs.getString("ifsc_code");
                bankName = rs.getString("bank_name");
                branchName = rs.getString("branch_name");

                hasPreviousAyMarksCard = rs.getBoolean("has_marks_card");
                hasKssApplication = rs.getBoolean("has_kss_app");
                hasFeeStructure = rs.getBoolean("has_fee_struct");
                hasFeeReceipts = rs.getBoolean("has_fee_rcpt");
                hasParentAadharCopy = rs.getBoolean("has_p_aadhar");
                hasStudentAadharCopy = rs.getBoolean("has_s_aadhar");
                hasBankPassbookFirstPage = rs.getBoolean("has_passbook");
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) {}
            if (pstmt != null) try { pstmt.close(); } catch (Exception e) {}
            if (conn != null) try { conn.close(); } catch (Exception e) {}
        }
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Scholarship Application - Karnatak Seva Sangha</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">

<style>
  :root {
    --text-primary: #1e293b;
    --text-secondary: #64748b;
    --bg-main: #f8fafc;
    --card-bg: #ffffff;
    --border-color: #000000;
    --accent-blue: #0f172a;
    --accent-hover: #334155;
  }

  * {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
  }

  body {
    font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
    background-color: var(--bg-main);
    color: var(--text-primary);
    padding: 24px 16px;
    -webkit-font-smoothing: antialiased;
  }

  .container {
    max-width: 860px;
    margin: 0 auto;
  }

  /* Screen Control Bar */
  .action-bar {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 20px;
  }

  .action-title {
    font-size: 18px;
    font-weight: 700;
    color: var(--text-primary);
  }

  /* Printable Sheet Styling */
  .printable-sheet {
    background: var(--card-bg);
    border: 1.5px solid var(--border-color);
    padding: 28px 32px;
    box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.05);
  }

  .header-section {
    text-align: center;
    border-bottom: 2px double var(--border-color);
    padding-bottom: 12px;
    margin-bottom: 14px;
  }

  .org-title {
    font-family: 'Inter', sans-serif;
    font-size: 20px;
    font-weight: 800;
    letter-spacing: 0.5px;
    text-transform: uppercase;
    color: #000000;
  }

  .org-subtitle {
    font-size: 11px;
    font-weight: 500;
    color: #333333;
    margin-top: 3px;
    line-height: 1.3;
  }

  .doc-title {
    font-size: 14px;
    font-weight: 700;
    margin-top: 8px;
    text-transform: uppercase;
    letter-spacing: 0.3px;
    color: #000000;
  }

  .doc-subtext {
    font-size: 11px;
    font-weight: 600;
    font-style: italic;
    color: #444444;
  }

  /* Boxed Section Containers */
  .boxed-section {
    border: 1px solid var(--border-color);
    padding: 10px 14px;
    margin-bottom: 10px;
    background: #ffffff;
  }

  .section-heading-row {
    font-weight: 700;
    font-size: 11px;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    border-bottom: 1px solid var(--border-color);
    padding-bottom: 4px;
    margin-bottom: 8px;
    color: #000000;
  }

  .two-column-layout {
    display: flex;
    gap: 20px;
  }

  .col-half {
    flex: 1;
  }

  .form-row {
    display: flex;
    align-items: center;
    margin-bottom: 5px;
  }

  .form-row:last-child {
    margin-bottom: 0;
  }

  .form-label {
    width: 135px;
    font-size: 10.5px;
    font-weight: 600;
    color: #111111;
  }

  .form-colon {
    width: 10px;
    font-size: 10.5px;
    font-weight: 700;
  }

  .form-value-box {
    flex: 1;
    border: 1px solid #000000;
    min-height: 22px;
    padding: 2px 8px;
    font-size: 10.5px;
    font-weight: 600;
    background: #ffffff;
    word-break: break-word;
    display: flex;
    align-items: center;
  }

  /* Checklist Section */
  .checklist-list {
    list-style: none;
    font-size: 10.5px;
    line-height: 1.6;
    color: #111111;
  }

  .checklist-list li strong {
    font-weight: 700;
  }

  .signature-area {
    margin-top: 16px;
    display: flex;
    justify-content: flex-end;
  }

  .signature-line {
    border-top: 1px solid var(--border-color);
    width: 210px;
    text-align: center;
    padding-top: 4px;
    font-size: 10.5px;
    font-weight: 700;
  }

  /* Certificate Section Clean Alignment */
  .cert-heading {
    text-align: center;
    font-size: 12px;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    margin-bottom: 12px;
    text-decoration: underline;
  }

  .cert-text-container {
    display: flex;
    flex-direction: column;
    gap: 8px;
  }

  .cert-line-row {
    display: flex;
    align-items: flex-end;
    font-size: 10.5px;
    white-space: nowrap;
  }

  .cert-label {
    font-weight: 500;
    padding-right: 6px;
  }

  .fill-line {
    flex: 1;
    border-bottom: 1px solid var(--border-color);
    padding: 0 8px 1px 8px;
    font-weight: 700;
    font-size: 10.5px;
    min-height: 16px;
  }

  .cert-footer {
    display: flex;
    justify-content: space-between;
    align-items: flex-end;
    margin-top: 30px;
    font-size: 10.5px;
    font-weight: 700;
  }

  /* Document Upload Section Style */
  .upload-card {
    background: var(--card-bg);
    border: 1px solid #e2e8f0;
    padding: 24px;
    margin-top: 24px;
    border-radius: 8px;
    box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05);
  }

  .upload-header {
    font-size: 14px;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    color: var(--text-primary);
    margin-bottom: 16px;
    padding-bottom: 8px;
    border-bottom: 1px solid #e2e8f0;
  }

  .doc-grid {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 16px;
  }

  .doc-card {
    background: #f8fafc;
    border: 1px solid #e2e8f0;
    border-radius: 6px;
    padding: 12px 14px;
    display: flex;
    flex-direction: column;
    gap: 10px;
  }

  .doc-card-title {
    font-size: 12px;
    font-weight: 600;
    color: var(--text-primary);
  }

  .status-badge {
    display: inline-flex;
    align-items: center;
    gap: 4px;
    padding: 4px 10px;
    font-size: 11px;
    font-weight: 600;
    border-radius: 4px;
    text-decoration: none;
    width: fit-content;
  }

  .status-badge.view {
    background-color: #dcfce7;
    color: #166534;
    border: 1px solid #bbf7d0;
  }

  .status-badge.none {
    background-color: #fef3c7;
    color: #92400e;
    border: 1px solid #fde68a;
  }

  input[type="file"] {
    font-size: 11px;
    color: var(--text-secondary);
  }

  .btn-actions {
    display: flex;
    justify-content: flex-end;
    gap: 10px;
    margin-top: 20px;
  }

  .btn {
    background-color: var(--accent-blue);
    color: #ffffff;
    border: none;
    padding: 9px 20px;
    font-size: 12px;
    font-weight: 600;
    cursor: pointer;
    border-radius: 6px;
    text-decoration: none;
    display: inline-flex;
    align-items: center;
    gap: 6px;
    transition: background-color 0.15s ease;
  }

  .btn:hover {
    background-color: var(--accent-hover);
  }

  .btn-secondary {
    background-color: #ffffff;
    color: var(--text-primary);
    border: 1px solid #cbd5e1;
  }

  .btn-secondary:hover {
    background-color: #f1f5f9;
  }

  .error-card {
    text-align: center;
    color: #dc2626;
    font-size: 15px;
    font-weight: 600;
    padding: 40px 20px;
  }

  /* -------------------------------------------------------------------------
     PRINT STYLING - ABSOLUTE SINGLE PAGE A4 FIT
     ------------------------------------------------------------------------- */
  @page {
    size: A4 portrait;
    margin: 8mm 10mm;
  }

  @media print {
    *, *:before, *:after {
      background: transparent !important;
      color: #000 !important;
      box-shadow: none !important;
      text-shadow: none !important;
    }

    html, body {
      height: 100%;
      background-color: #ffffff !important;
      padding: 0 !important;
      margin: 0 !important;
      font-size: 10pt;
    }

    .no-print, .non-printable, .btn-actions, .action-bar {
      display: none !important;
    }

    .container {
      max-width: 100% !important;
      width: 100% !important;
      margin: 0 !important;
      padding: 0 !important;
    }

    .printable-sheet {
      border: 1.5pt solid #000 !important;
      padding: 12pt !important;
      height: 100% !important;
      display: flex !important;
      flex-direction: column !important;
      justify-content: space-between !important;
      box-sizing: border-box !important;
    }

    .header-section {
      border-bottom: 1.5pt double #000 !important;
      margin-bottom: 8pt !important;
      padding-bottom: 6pt !important;
    }

    .boxed-section {
      border: 1pt solid #000 !important;
      padding: 6pt 8pt !important;
      margin-bottom: 6pt !important;
    }

    .boxed-section.cert-section {
      margin-bottom: 0 !important;
      flex-grow: 1 !important;
      display: flex !important;
      flex-direction: column !important;
      justify-content: space-between !important;
    }

    .form-value-box {
      border: 0.75pt solid #000 !important;
      min-height: 18pt !important;
      padding: 1pt 4pt !important;
      font-size: 9pt !important;
    }

    .cert-footer {
      margin-top: auto !important;
      padding-top: 15pt !important;
    }
  }
</style>
</head>

<body>

<div class="container">

<% if(!recordFound) { %>

  <div class="printable-sheet">
    <div class="header-section">
      <div class="org-title">Karnatak Seva Sangha</div>
      <div class="doc-title">Scholarship Application Details</div>
    </div>
    <div class="error-card">
      Record Not Found or Invalid ID Parameter.
    </div>
    <div class="btn-actions">
      <a href="scholarshipList.jsp" class="btn btn-secondary">Back to List</a>
    </div>
  </div>

<% } else { %>

  <!-- SCREEN CONTROL BAR -->
  <div class="action-bar no-print">
    <div class="action-title">Scholarship Application View</div>
    <div style="display: flex; gap: 8px;">
      <button onclick="window.print();" class="btn">🖨 Print Application</button>
      <a href="scholarshipList.jsp" class="btn btn-secondary">Back to List</a>
    </div>
  </div>

  <div class="printable-sheet">

    <!-- HEADER SECTION -->
    <div class="header-section">
      <div class="org-title">KARNATAKA SEVA SANGHA</div>
      <div class="org-subtitle">(Regd. No:16 of 1983-84 dated 21.04.1983)<br>Shivapur, Palace Road, Sandur - 583119, Ballari Dist., Karnataka</div>
      <div class="doc-title">Sandur Vidya Protsaha Scholarship - Higher Education</div>
      <div class="doc-subtext">(Under Auspicious SMIORE CSR)</div>
    </div>

    <!-- 1. PARTICULARS SECTION -->
    <div class="boxed-section">
      <div class="two-column-layout">
        
        <!-- Left Column: Student Particulars -->
        <div class="col-half">
          <div class="section-heading-row">Student Particulars :</div>

          <div class="form-row">
            <span class="form-label">Student Name</span>
            <span class="form-colon">:</span>
            <div class="form-value-box"><%=childrenName != null ? childrenName : ""%></div>
          </div>

          <div class="form-row">
            <span class="form-label">Date of Birth</span>
            <span class="form-colon">:</span>
            <div class="form-value-box"><%=dob != null ? dob : ""%></div>
          </div>

          <div class="form-row">
            <span class="form-label">Gender / Relation</span>
            <span class="form-colon">:</span>
            <div class="form-value-box"><%=(gender != null ? gender : "") + " / " + (relationship != null ? relationship : "")%></div>
          </div>

          <div class="form-row">
            <span class="form-label">Child Order</span>
            <span class="form-colon">:</span>
            <div class="form-value-box"><%=childOrder != null ? childOrder : ""%></div>
          </div>

          <div class="form-row">
            <span class="form-label">College Name</span>
            <span class="form-colon">:</span>
            <div class="form-value-box"><%=collegeName != null ? collegeName : ""%></div>
          </div>

          <div class="form-row">
            <span class="form-label">Educational Course</span>
            <span class="form-colon">:</span>
            <div class="form-value-box"><%=course != null ? course : ""%></div>
          </div>

          <div class="form-row">
            <span class="form-label">Present Year</span>
            <span class="form-colon">:</span>
            <div class="form-value-box"><%=presentYear != null ? presentYear : ""%></div>
          </div>

          <div class="form-row">
            <span class="form-label">Prev. AY Marks (%)</span>
            <span class="form-colon">:</span>
            <div class="form-value-box"><%=previousAyPercentage > 0 ? String.format("%.2f%%", previousAyPercentage) : ""%></div>
          </div>

          <div class="form-row">
            <span class="form-label">Fee Amount (Current)</span>
            <span class="form-colon">:</span>
            <div class="form-value-box"><%=feeAmountCurrentAy > 0 ? String.format("₹ %.2f", feeAmountCurrentAy) : ""%></div>
          </div>
        </div>

        <!-- Right Column: Employee & Spouse Particulars -->
        <div class="col-half">
          <div class="section-heading-row">Employee Particulars :</div>

          <div class="form-row">
            <span class="form-label">Organisation Name</span>
            <span class="form-colon">:</span>
            <div class="form-value-box"><%=orgName != null ? orgName : ""%></div>
          </div>

          <div class="form-row">
            <span class="form-label">Emp. No.</span>
            <span class="form-colon">:</span>
            <div class="form-value-box"><%=empNo != null ? empNo : ""%></div>
          </div>

          <div class="form-row">
            <span class="form-label">Emp. Name</span>
            <span class="form-colon">:</span>
            <div class="form-value-box"><%=empName != null ? empName : ""%></div>
          </div>

          <div class="form-row">
            <span class="form-label">Designation</span>
            <span class="form-colon">:</span>
            <div class="form-value-box"><%=designation != null ? designation : ""%></div>
          </div>

          <div class="section-heading-row" style="margin-top: 8px;">Spouse Employment Details :</div>

          <div class="form-row">
            <span class="form-label">Working in SMIORE?</span>
            <span class="form-colon">:</span>
            <div class="form-value-box"><%=spouseWorkingSmiore != null ? spouseWorkingSmiore : ""%></div>
          </div>

          <div class="form-row">
            <span class="form-label">Working in Group Co.?</span>
            <span class="form-colon">:</span>
            <div class="form-value-box"><%=spouseWorkingGroupCompanies != null ? spouseWorkingGroupCompanies : ""%></div>
          </div>
        </div>

      </div>
    </div>

    <!-- 2. EMPLOYEE BANK DETAILS SECTION -->
    <div class="boxed-section">
      <div class="section-heading-row">Employee Bank Details :</div>

      <div class="two-column-layout">
        <div class="col-half">
          <div class="form-row">
            <span class="form-label">Account Holder</span>
            <span class="form-colon">:</span>
            <div class="form-value-box"><%=employeeNamePassbook != null ? employeeNamePassbook : ""%></div>
          </div>

          <div class="form-row">
            <span class="form-label">Account No.</span>
            <span class="form-colon">:</span>
            <div class="form-value-box"><%=bankAccountNo != null ? bankAccountNo : ""%></div>
          </div>

          <div class="form-row">
            <span class="form-label">IFSC Code</span>
            <span class="form-colon">:</span>
            <div class="form-value-box"><%=ifscCode != null ? ifscCode : ""%></div>
          </div>
        </div>

        <div class="col-half">
          <div class="form-row">
            <span class="form-label">Bank Name</span>
            <span class="form-colon">:</span>
            <div class="form-value-box"><%=bankName != null ? bankName : ""%></div>
          </div>

          <div class="form-row">
            <span class="form-label">Branch</span>
            <span class="form-colon">:</span>
            <div class="form-value-box"><%=branchName != null ? branchName : ""%></div>
          </div>

          <div class="form-row">
            <span class="form-label">Place</span>
            <span class="form-colon">:</span>
            <div class="form-value-box">Sandur</div>
          </div>
        </div>
      </div>
    </div>

    <!-- 3. ENCLOSURES & SIGNATURE SECTION -->
    <div class="boxed-section">
      <ul class="checklist-list">
        <li>I enclose the following documents:</li>
        <li>a. Fee paid receipt in <strong><u>Original</u></strong>.</li>
        <li>b. Copy of Previous Year Marks Card.</li>
        <li>c. Copy of Identity Card of Employee and Student.</li>
        <li>d. Copy of Bank Pass Book.</li>
      </ul>

      <div class="signature-area">
        <div class="signature-line">
          Signature of the Employee
        </div>
      </div>
    </div>

    <!-- 4. CERTIFICATE FROM HEAD OF INSTITUTION -->
    <div class="boxed-section cert-section">
      <div>
        <div class="cert-heading">Certificate from the Head of Institution</div>
        
        <div class="cert-text-container">
          <div class="cert-line-row">
            <span class="cert-label">This is to certify that Kumar / Kumari</span>
            <div class="fill-line"><%=childrenName != null ? childrenName : ""%></div>
          </div>

          <div class="cert-line-row">
            <span class="cert-label">S/o / D/o</span>
            <div class="fill-line"><%=empName != null ? empName : ""%></div>
            <span class="cert-label" style="padding-left: 8px;">is studying in</span>
            <div class="fill-line"><%=collegeName != null ? collegeName : ""%></div>
          </div>

          <div class="cert-line-row">
            <span class="cert-label">Course</span>
            <div class="fill-line"><%=course != null ? course : ""%></div>
            <span class="cert-label" style="padding-left: 8px;">for the year / semester</span>
            <div class="fill-line"><%=presentYear != null ? presentYear : ""%></div>
          </div>
        </div>
      </div>
<br><br><br><br><br><br>
      <div class="cert-footer">
        <div>(Seal of the Institution)</div>
        <div style="border-top: 1px solid #000; padding-top: 4px; min-width: 200px; text-align: center;">Principal Signature</div>
      </div>
    </div>

  </div>

  <!-- DOCUMENT UPLOADS (NON-PRINTABLE AREA) -->
  <div class="non-printable upload-card">
    <div class="upload-header">Document Uploads & Attachments</div>

    <form action="scholarshipApplication.jsp" method="post" enctype="multipart/form-data">
      <input type="hidden" name="id" value="<%=id%>">

      <div class="doc-grid">

        <div class="doc-card">
          <span class="doc-card-title">Previous AY Marks Card</span>
          <div>
            <% if(hasPreviousAyMarksCard) { %>
              <a href="scholarshipApplication.jsp?id=<%=id%>&mode=download&field=previous_ay_marks_card" target="_blank" class="status-badge view">✓ View Document</a>
            <% } else { %>
              <span class="status-badge none">⚠ No file uploaded</span>
            <% } %>
          </div>
          <input type="file" name="previous_ay_marks_card" accept=".pdf,.jpg,.jpeg,.png">
        </div>

        <div class="doc-card">
          <span class="doc-card-title">KSS Application</span>
          <div>
            <% if(hasKssApplication) { %>
              <a href="scholarshipApplication.jsp?id=<%=id%>&mode=download&field=kss_application" target="_blank" class="status-badge view">✓ View Document</a>
            <% } else { %>
              <span class="status-badge none">⚠ No file uploaded</span>
            <% } %>
          </div>
          <input type="file" name="kss_application" accept=".pdf,.jpg,.jpeg,.png">
        </div>

        <div class="doc-card">
          <span class="doc-card-title">Fee Structure</span>
          <div>
            <% if(hasFeeStructure) { %>
              <a href="scholarshipApplication.jsp?id=<%=id%>&mode=download&field=fee_structure" target="_blank" class="status-badge view">✓ View Document</a>
            <% } else { %>
              <span class="status-badge none">⚠ No file uploaded</span>
            <% } %>
          </div>
          <input type="file" name="fee_structure" accept=".pdf,.jpg,.jpeg,.png">
        </div>

        <div class="doc-card">
          <span class="doc-card-title">Fee Receipts</span>
          <div>
            <% if(hasFeeReceipts) { %>
              <a href="scholarshipApplication.jsp?id=<%=id%>&mode=download&field=fee_receipts" target="_blank" class="status-badge view">✓ View Document</a>
            <% } else { %>
              <span class="status-badge none">⚠ No file uploaded</span>
            <% } %>
          </div>
          <input type="file" name="fee_receipts" accept=".pdf,.jpg,.jpeg,.png">
        </div>

        <div class="doc-card">
          <span class="doc-card-title">Parent Identity Document</span>
          <div>
            <% if(hasParentAadharCopy) { %>
              <a href="scholarshipApplication.jsp?id=<%=id%>&mode=download&field=parent_aadhar_copy" target="_blank" class="status-badge view">✓ View Document</a>
            <% } else { %>
              <span class="status-badge none">⚠ No file uploaded</span>
            <% } %>
          </div>
          <input type="file" name="parent_aadhar_copy" accept=".pdf,.jpg,.jpeg,.png">
        </div>

        <div class="doc-card">
          <span class="doc-card-title">Student Identity Document</span>
          <div>
            <% if(hasStudentAadharCopy) { %>
              <a href="scholarshipApplication.jsp?id=<%=id%>&mode=download&field=student_aadhar_copy" target="_blank" class="status-badge view">✓ View Document</a>
            <% } else { %>
              <span class="status-badge none">⚠ No file uploaded</span>
            <% } %>
          </div>
          <input type="file" name="student_aadhar_copy" accept=".pdf,.jpg,.jpeg,.png">
        </div>

        <div class="doc-card" style="grid-column: span 2;">
          <span class="doc-card-title">Bank Passbook First Page</span>
          <div>
            <% if(hasBankPassbookFirstPage) { %>
              <a href="scholarshipApplication.jsp?id=<%=id%>&mode=download&field=bank_passbook_first_page" target="_blank" class="status-badge view">✓ View Document</a>
            <% } else { %>
              <span class="status-badge none">⚠ No file uploaded</span>
            <% } %>
          </div>
          <input type="file" name="bank_passbook_first_page" accept=".pdf,.jpg,.jpeg,.png">
        </div>

      </div>

      <div class="btn-actions">
        <input type="submit" value="Upload Documents" class="btn">
        <a href="scholarshipList.jsp" class="btn btn-secondary">Back to List</a>
      </div>

    </form>
  </div>

<% } %>

</div>

</body>
</html>