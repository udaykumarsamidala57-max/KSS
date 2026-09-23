<%@ page import="java.sql.*" %>
<%@ page import="com.Bean.DBUtil" %>
<%
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    String users = (String) sess.getAttribute("username");
    String roles = (String) sess.getAttribute("role");
    String depts = (String) sess.getAttribute("department");
    String branch = (String) sess.getAttribute("branch");
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Scholarship Document Upload Status</title>

<style>
  /* Professional Maroon Color Scheme & Elevation Variables */
  :root {
    --brand-primary: #7a1f35;       
    --brand-primary-dark: #5e1627;  
    --brand-accent-bg: #fdf6f7;     
    --brand-border: #e2cece;        
    --text-main: #2b2b2b;
    --text-muted: #666666;

    --bg-page: #f8f9fa;
    --bg-card: #ffffff;
    --header-bg: #fdf6f7;
    --row-hover: #fcf2f4;

    /* Status Badges */
    --badge-success-bg: #e6f4ea;
    --badge-success-text: #137333;
    --badge-success-border: #ceead6;
    
    --badge-missing-bg: #fce8e6;
    --badge-missing-text: #c5221f;
    --badge-missing-border: #fad2cf;

    /* Shadows */
    --card-shadow: 0 4px 12px rgba(122, 31, 53, 0.08);
    --card-shadow-hover: 0 6px 16px rgba(122, 31, 53, 0.15);
  }

  * {
    box-sizing: border-box;
  }

  body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
    background-color: var(--bg-page);
    margin: 0;
    padding: 24px;
    padding-bottom: 70px;
    color: var(--text-main);
    line-height: 1.5;
  }

  .page-wrapper {
    max-width: 1600px;
    margin: 0 auto;
    width: 100%;
  }

  /* Header Banner with Left Accent Line */
  .header-container {
    background-color: var(--bg-card);
    border: 1px solid var(--brand-border);
    border-left: 5px solid var(--brand-primary);
    border-radius: 8px;
    padding: 18px 24px;
    margin-bottom: 24px;
    box-shadow: var(--card-shadow);
  }

  .header-title {
    margin: 0;
    font-size: 20px;
    font-weight: 700;
    color: var(--brand-primary-dark);
    letter-spacing: -0.2px;
  }

  .header-subtitle {
    margin: 4px 0 0 0;
    font-size: 13px;
    color: var(--text-muted);
  }

  /* Responsive Table Container */
  .table-container {
    background: var(--bg-card);
    border: 1px solid var(--brand-border);
    border-radius: 8px;
    box-shadow: var(--card-shadow);
    overflow-x: auto;
    -webkit-overflow-scrolling: touch;
  }

  table {
    width: 100%;
    border-collapse: collapse;
    min-width: 900px;
    font-size: 13px;
  }

  /* Styled Sticky Headers */
  th {
    background-color: var(--header-bg);
    color: var(--brand-primary-dark);
    font-size: 12px;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    padding: 14px 16px;
    text-align: left;
    border-bottom: 2px solid var(--brand-border);
    white-space: nowrap;
    position: sticky;
    top: 0;
    z-index: 2;
  }

  th.center-align, td.center-align {
    text-align: center;
  }

  td {
    padding: 12px 16px;
    border-bottom: 1px solid var(--brand-border);
    color: var(--text-main);
    vertical-align: middle;
  }

  tbody tr:last-child td {
    border-bottom: none;
  }

  tbody tr:hover {
    background-color: var(--row-hover);
  }

  /* Interactive Form & Badge Styling */
  .doc-form {
    display: inline-block;
    margin: 0;
    padding: 0;
  }

  .doc-btn {
    background: none;
    border: none;
    padding: 0;
    margin: 0;
    cursor: pointer;
    font-family: inherit;
  }

  .status-badge {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 4px;
    padding: 4px 12px;
    font-size: 11px;
    font-weight: 700;
    border-radius: 12px;
    min-width: 85px;
    text-align: center;
    transition: all 0.15s ease-in-out;
  }

  /* Green badge for uploaded documents */
  .tick {
    background-color: var(--badge-success-bg);
    color: var(--badge-success-text);
    border: 1px solid var(--badge-success-border);
    cursor: pointer;
  }

  .tick:hover {
    background-color: #d2e3d6;
    transform: translateY(-1px);
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  }

  /* Red badge for missing documents */
  .cross {
    background-color: var(--badge-missing-bg);
    color: var(--badge-missing-text);
    border: 1px solid var(--badge-missing-border);
    cursor: default;
  }

  .emp-badge {
    font-weight: 600;
    color: var(--brand-primary-dark);
  }

  .error-box {
    margin: 20px;
    padding: 16px;
    background-color: #fdf2e9;
    border: 1px solid #f5c6cb;
    color: #a93226;
    border-radius: 6px;
    font-size: 13px;
    font-weight: 600;
    box-shadow: var(--card-shadow);
  }

  @media (max-width: 768px) {
    body {
      padding: 12px;
      padding-bottom: 80px;
    }

    .header-title {
      font-size: 18px;
    }
  }
</style>
</head>
<body>

<%@ include file="header.jsp" %>

<div class="page-wrapper">

  <div class="header-container">
    <h1 class="header-title">Student Scholarship Document Status</h1>
    <p class="header-subtitle">Click on any uploaded document badge to view or download the attachment.</p>
  </div>

  <div class="table-container">
    <table>
      <thead>
        <tr>
          <th>ID</th>
          <th>Emp No</th>
          <th>Employee Name</th>
          <th>Child Name</th>
          <th class="center-align">Marks Card</th>
          <th class="center-align">KSS App</th>
          <th class="center-align">Fee Structure</th>
          <th class="center-align">Fee Receipt</th>
          <th class="center-align">Parent ID</th>
          <th class="center-align">Student ID</th>
          <th class="center-align">Bank Passbook</th>
        </tr>
      </thead>
      <tbody>
<%
Connection con = null;
PreparedStatement ps = null;
ResultSet rs = null;

try {
    con = DBUtil.getConnection();
    
    String sql;
    boolean isSandurEducationSociety = branch != null && "SANDUR EDUCATION SOCIETY".equalsIgnoreCase(branch.trim());
    boolean isSandurHatcheries = branch != null && "SANDUR HATCHERIES PVT LTD".equalsIgnoreCase(branch.trim());

    if ("Global".equalsIgnoreCase(roles)) {
        sql = "SELECT id, emp_no, emp_name, children_name, " +
              "OCTET_LENGTH(previous_ay_marks_card) AS len_marks, " +
              "OCTET_LENGTH(kss_application) AS len_kss, " +
              "OCTET_LENGTH(fee_structure) AS len_fee_struct, " +
              "OCTET_LENGTH(fee_receipts) AS len_fee_rec, " +
              "OCTET_LENGTH(parent_aadhar_copy) AS len_parent_id, " +
              "OCTET_LENGTH(student_aadhar_copy) AS len_student_id, " +
              "OCTET_LENGTH(bank_passbook_first_page) AS len_bank " +
              "FROM kss_student_scholarship " +
              "ORDER BY emp_no";

        ps = con.prepareStatement(sql);
    } else if (isSandurEducationSociety) {
        sql = "SELECT id, emp_no, emp_name, children_name, " +
              "OCTET_LENGTH(previous_ay_marks_card) AS len_marks, " +
              "OCTET_LENGTH(kss_application) AS len_kss, " +
              "OCTET_LENGTH(fee_structure) AS len_fee_struct, " +
              "OCTET_LENGTH(fee_receipts) AS len_fee_rec, " +
              "OCTET_LENGTH(parent_aadhar_copy) AS len_parent_id, " +
              "OCTET_LENGTH(student_aadhar_copy) AS len_student_id, " +
              "OCTET_LENGTH(bank_passbook_first_page) AS len_bank " +
              "FROM kss_student_scholarship " +
              "WHERE LOWER(TRIM(org_name)) IN (" +
              "LOWER(TRIM(?)), LOWER(TRIM(?)), LOWER(TRIM(?)), LOWER(TRIM(?)), LOWER(TRIM(?)), LOWER(TRIM(?)), LOWER(TRIM(?))) " +
              "ORDER BY emp_no";

        ps = con.prepareStatement(sql);
        ps.setString(1, "SANDUR EDUCATION SOCIETY");
        ps.setString(2, "SES VIDYAMANDIR PU COLLEGE");
        ps.setString(3, "SMIORE PRIMARY ENGLISH MEDIUM SCHOOL, DEOGIRI");
        ps.setString(4, "SMIORE HIGHER PRIMARY SCHOOL, DEOGIRI");
        ps.setString(5, "SMIORE HIGH SCHOOL, DEOGIRI");
        ps.setString(6, "SMIORE VYASAPURI HIGHER PRIMARY SCHOOL");
        ps.setString(7, "SANDUR EDUCATION SOCIETY, SANDUR");
    
    } else if (isSandurHatcheries) {
        sql = "SELECT id, emp_no, emp_name, children_name, " +
              "OCTET_LENGTH(previous_ay_marks_card) AS len_marks, " +
              "OCTET_LENGTH(kss_application) AS len_kss, " +
              "OCTET_LENGTH(fee_structure) AS len_fee_struct, " +
              "OCTET_LENGTH(fee_receipts) AS len_fee_rec, " +
              "OCTET_LENGTH(parent_aadhar_copy) AS len_parent_id, " +
              "OCTET_LENGTH(student_aadhar_copy) AS len_student_id, " +
              "OCTET_LENGTH(bank_passbook_first_page) AS len_bank " +
              "FROM kss_student_scholarship " +
              "WHERE LOWER(TRIM(org_name)) IN (" +
              "LOWER(TRIM(?)), LOWER(TRIM(?)), LOWER(TRIM(?))) " +
              "ORDER BY emp_no";

        ps = con.prepareStatement(sql);
        ps.setString(1, "SANDUR HATCHERIES PVT LTD");
        ps.setString(2, "SANDUR POULTRY FARM");
        ps.setString(3, "SANDUR POULTRY BREEDERS");
    } else {
        sql = "SELECT id, emp_no, emp_name, children_name, " +
              "OCTET_LENGTH(previous_ay_marks_card) AS len_marks, " +
              "OCTET_LENGTH(kss_application) AS len_kss, " +
              "OCTET_LENGTH(fee_structure) AS len_fee_struct, " +
              "OCTET_LENGTH(fee_receipts) AS len_fee_rec, " +
              "OCTET_LENGTH(parent_aadhar_copy) AS len_parent_id, " +
              "OCTET_LENGTH(student_aadhar_copy) AS len_student_id, " +
              "OCTET_LENGTH(bank_passbook_first_page) AS len_bank " +
              "FROM kss_student_scholarship " +
              "WHERE LOWER(TRIM(org_name)) = LOWER(TRIM(?)) " +
              "ORDER BY emp_no";

        ps = con.prepareStatement(sql);
        ps.setString(1, branch != null ? branch.trim() : "");
    }

    rs = ps.executeQuery();

    boolean hasData = false;
    while(rs.next()){
        hasData = true;
        int recId = rs.getInt("id");
        
        boolean hasMarks = rs.getLong("len_marks") > 0;
        boolean hasKss = rs.getLong("len_kss") > 0;
        boolean hasFeeStruct = rs.getLong("len_fee_struct") > 0;
        boolean hasFeeRec = rs.getLong("len_fee_rec") > 0;
        boolean hasParentId = rs.getLong("len_parent_id") > 0;
        boolean hasStudentId = rs.getLong("len_student_id") > 0;
        boolean hasBank = rs.getLong("len_bank") > 0;
%>
        <tr>
          <td><%=recId%></td>
          <td><span class="emp-badge"><%=rs.getString("emp_no") != null ? rs.getString("emp_no") : ""%></span></td>
          <td><%=rs.getString("emp_name") != null ? rs.getString("emp_name") : ""%></td>
          <td><%=rs.getString("children_name") != null ? rs.getString("children_name") : ""%></td>

          <!-- Marks Card -->
          <td class="center-align">
            <% if(hasMarks) { %>
              <form action="ScholarshipDocumentDownloadServlet" method="POST" target="_blank" class="doc-form">
                <input type="hidden" name="id" value="<%=recId%>" />
                <input type="hidden" name="field" value="previousAyMarksCard" />
                <button type="submit" class="doc-btn" title="View Document">
                  <span class="status-badge tick">&#10004; View</span>
                </button>
              </form>
            <% } else { %>
              <span class="status-badge cross">&#10008; Missing</span>
            <% } %>
          </td>

          <!-- KSS Application -->
          <td class="center-align">
            <% if(hasKss) { %>
              <form action="ScholarshipDocumentDownloadServlet" method="POST" target="_blank" class="doc-form">
                <input type="hidden" name="id" value="<%=recId%>" />
                <input type="hidden" name="field" value="kssApplication" />
                <button type="submit" class="doc-btn" title="View Document">
                  <span class="status-badge tick">&#10004; View</span>
                </button>
              </form>
            <% } else { %>
              <span class="status-badge cross">&#10008; Missing</span>
            <% } %>
          </td>

          <!-- Fee Structure -->
          <td class="center-align">
            <% if(hasFeeStruct) { %>
              <form action="ScholarshipDocumentDownloadServlet" method="POST" target="_blank" class="doc-form">
                <input type="hidden" name="id" value="<%=recId%>" />
                <input type="hidden" name="field" value="feeStructure" />
                <button type="submit" class="doc-btn" title="View Document">
                  <span class="status-badge tick">&#10004; View</span>
                </button>
              </form>
            <% } else { %>
              <span class="status-badge cross">&#10008; Missing</span>
            <% } %>
          </td>

          <!-- Fee Receipts -->
          <td class="center-align">
            <% if(hasFeeRec) { %>
              <form action="ScholarshipDocumentDownloadServlet" method="POST" target="_blank" class="doc-form">
                <input type="hidden" name="id" value="<%=recId%>" />
                <input type="hidden" name="field" value="feeReceipts" />
                <button type="submit" class="doc-btn" title="View Document">
                  <span class="status-badge tick">&#10004; View</span>
                </button>
              </form>
            <% } else { %>
              <span class="status-badge cross">&#10008; Missing</span>
            <% } %>
          </td>

          <!-- Parent ID Copy -->
          <td class="center-align">
            <% if(hasParentId) { %>
              <form action="ScholarshipDocumentDownloadServlet" method="POST" target="_blank" class="doc-form">
                <input type="hidden" name="id" value="<%=recId%>" />
                <input type="hidden" name="field" value="parentAadharCopy" />
                <button type="submit" class="doc-btn" title="View Document">
                  <span class="status-badge tick">&#10004; View</span>
                </button>
              </form>
            <% } else { %>
              <span class="status-badge cross">&#10008; Missing</span>
            <% } %>
          </td>

          <!-- Student ID Copy -->
          <td class="center-align">
            <% if(hasStudentId) { %>
              <form action="ScholarshipDocumentDownloadServlet" method="POST" target="_blank" class="doc-form">
                <input type="hidden" name="id" value="<%=recId%>" />
                <input type="hidden" name="field" value="studentAadharCopy" />
                <button type="submit" class="doc-btn" title="View Document">
                  <span class="status-badge tick">&#10004; View</span>
                </button>
              </form>
            <% } else { %>
              <span class="status-badge cross">&#10008; Missing</span>
            <% } %>
          </td>

          <!-- Bank Passbook -->
          <td class="center-align">
            <% if(hasBank) { %>
              <form action="ScholarshipDocumentDownloadServlet" method="POST" target="_blank" class="doc-form">
                <input type="hidden" name="id" value="<%=recId%>" />
                <input type="hidden" name="field" value="bankPassbookFirstPage" />
                <button type="submit" class="doc-btn" title="View Document">
                  <span class="status-badge tick">&#10004; View</span>
                </button>
              </form>
            <% } else { %>
              <span class="status-badge cross">&#10008; Missing</span>
            <% } %>
          </td>
        </tr>
<%
    }
    if (!hasData) {
%>
        <tr>
          <td colspan="11" style="text-align: center; padding: 24px; color: var(--text-muted);">No scholarship application records available.</td>
        </tr>
<%
    }
} catch(Exception e) {
%>
    </table>
    <div class="error-box">
      Error retrieving scholarship document status: <%=e.getMessage()%>
    </div>
    <table>
<%
} finally {
    if(rs!=null) try { rs.close(); } catch(SQLException se) {}
    if(ps!=null) try { ps.close(); } catch(SQLException se) {}
    if(con!=null) try { con.close(); } catch(SQLException se) {}
}
%>
      </tbody>
    </table>
  </div>
</div>

</body>
</html>