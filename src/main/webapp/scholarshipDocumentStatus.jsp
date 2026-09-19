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
  :root {
    --primary-color: #7a1f35;
    --primary-hover: #5e1627;
    --accent-bg: #fdf6f7;
    --border-color: #e2cece;
    --text-main: #2b2b2b;
    --text-muted: #666666;
    --success-color: #27ae60;
    --danger-color: #c0392b;
  }

  body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    background-color: #f4f6f8;
    margin: 0;
    padding: 24px;
    color: var(--text-main);
  }

  .container {
    max-width: 1600px;
    margin: 0 auto;
    background: #ffffff;
    border-radius: 8px;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
    border: 1px solid #e1e4e8;
    overflow: hidden;
  }

  .header-bar {
    padding: 16px 24px;
    background-color: var(--accent-bg);
    border-bottom: 1px solid var(--border-color);
  }

  .header-bar h2 {
    margin: 0;
    font-size: 16px;
    font-weight: 700;
    color: var(--primary-color);
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }
  
  .header-bar p {
    margin: 4px 0 0 0;
    font-size: 12px;
    color: var(--text-muted);
  }

  .table-responsive {
    overflow-x: auto;
    padding: 20px;
  }

  table {
    width: 100%;
    border-collapse: separate;
    border-spacing: 0;
    font-size: 12px;
    white-space: nowrap;
  }

  th {
    background-color: var(--primary-color);
    color: #ffffff;
    font-weight: 600;
    text-transform: uppercase;
    font-size: 11px;
    letter-spacing: 0.5px;
    padding: 12px 10px;
    text-align: left;
    border-bottom: 2px solid var(--primary-hover);
    position: sticky;
    top: 0;
    z-index: 10;
  }

  th.center-align, td.center-align {
    text-align: center;
  }

  td {
    padding: 10px;
    border-bottom: 1px solid #eef1f4;
    border-right: 1px solid #f0f0f0;
    color: var(--text-main);
    vertical-align: middle;
  }

  tr:last-child td {
    border-bottom: 1px solid #eef1f4;
  }

  tr:nth-child(even) td {
    background-color: #fafbfc;
  }

  tr:hover td {
    background-color: #f7e8ec;
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
    padding: 5px 10px;
    font-size: 11px;
    font-weight: 600;
    border-radius: 4px;
    min-width: 90px;
    text-align: center;
    transition: all 0.2s ease-in-out;
  }

  .tick {
    background-color: #e2f0d9;
    color: #2e5b1e;
    border: 1px solid #a9d18e;
    cursor: pointer;
  }

  .tick:hover {
    background-color: #d4e8c4;
    box-shadow: 0 2px 4px rgba(0,0,0,0.08);
    transform: translateY(-1px);
  }

  .cross {
    background-color: #fce8e6;
    color: #a51d24;
    border: 1px solid #f5c2c1;
    cursor: default;
  }

  .emp-badge {
    font-weight: bold;
  }
  
  .error-box {
    margin: 20px;
    padding: 16px;
    background-color: #fce8e6;
    border: 1px solid #f5c2c1;
    color: #a51d24;
    border-radius: 4px;
    font-size: 13px;
  }
</style>
</head>
<body>
<%@ include file="header.jsp" %>
<div class="container">
  
  <div class="header-bar">
    <h2>Student Scholarship Document Status</h2>
    <p>Click on any uploaded document badge to view or download the attachment.</p>
  </div>

  <div class="table-responsive">
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
              "LOWER(TRIM(?)), LOWER(TRIM(?)), LOWER(TRIM(?)), LOWER(TRIM(?)), LOWER(TRIM(?)), LOWER(TRIM(?))) " +
              "ORDER BY emp_no";

        ps = con.prepareStatement(sql);
        ps.setString(1, "SANDUR EDUCATION SOCIETY");
        ps.setString(2, "SES VIDYAMANDIR PU COLLEGE");
        ps.setString(3, "SMIORE PRIMARY ENGLISH MEDIUM SCHOOL, DEOGIRI");
        ps.setString(4, "SMIORE HIGHER PRIMARY SCHOOL, DEOGIRI");
        ps.setString(5, "SMIORE HIGH SCHOOL, DEOGIRI");
        ps.setString(6, "SMIORE VYASAPURI HIGHER PRIMARY SCHOOL");
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
          <td colspan="11" style="text-align: center; padding: 32px; color: var(--text-muted);">No scholarship application records available.</td>
        </tr>
<%
    }
} catch(Exception e) {
%>
    </table>
    <div class="error-box">
      <strong>Database Error:</strong> <%=e.getMessage()%>
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