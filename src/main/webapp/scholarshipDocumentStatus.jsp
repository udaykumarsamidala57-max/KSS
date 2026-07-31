<%@ page import="java.sql.*" %>
<%@ page import="com.Bean.DBUtil" %>
<%
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
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

  /* Interactive Status Link & Badge Styling */
  .doc-link {
    text-decoration: none;
    display: inline-block;
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
    
    // Performance optimized SQL query checking length without fetching heavy BLOB payloads
    String sql = "SELECT id, emp_no, emp_name, children_name, " +
                 "OCTET_LENGTH(previous_ay_marks_card) AS len_marks, " +
                 "OCTET_LENGTH(kss_application) AS len_kss, " +
                 "OCTET_LENGTH(fee_structure) AS len_fee_struct, " +
                 "OCTET_LENGTH(fee_receipts) AS len_fee_rec, " +
                 "OCTET_LENGTH(parent_aadhar_copy) AS len_parent_id, " +
                 "OCTET_LENGTH(student_aadhar_copy) AS len_student_id, " +
                 "OCTET_LENGTH(bank_passbook_first_page) AS len_bank " +
                 "FROM kss_student_scholarship ORDER BY emp_no";

    ps = con.prepareStatement(sql);
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
              <a href="ScholarshipDocumentDownloadServlet?id=<%=recId%>&field=previousAyMarksCard" target="_blank" class="doc-link" title="View Document">
                <span class="status-badge tick">&#10004; View</span>
              </a>
            <% } else { %>
              <span class="status-badge cross">&#10008; Missing</span>
            <% } %>
          </td>

          <!-- KSS Application -->
          <td class="center-align">
            <% if(hasKss) { %>
              <a href="ScholarshipDocumentDownloadServlet?id=<%=recId%>&field=kssApplication" target="_blank" class="doc-link" title="View Document">
                <span class="status-badge tick">&#10004; View</span>
              </a>
            <% } else { %>
              <span class="status-badge cross">&#10008; Missing</span>
            <% } %>
          </td>

          <!-- Fee Structure -->
          <td class="center-align">
            <% if(hasFeeStruct) { %>
              <a href="ScholarshipDocumentDownloadServlet?id=<%=recId%>&field=feeStructure" target="_blank" class="doc-link" title="View Document">
                <span class="status-badge tick">&#10004; View</span>
              </a>
            <% } else { %>
              <span class="status-badge cross">&#10008; Missing</span>
            <% } %>
          </td>

          <!-- Fee Receipts -->
          <td class="center-align">
            <% if(hasFeeRec) { %>
              <a href="ScholarshipDocumentDownloadServlet?id=<%=recId%>&field=feeReceipts" target="_blank" class="doc-link" title="View Document">
                <span class="status-badge tick">&#10004; View</span>
              </a>
            <% } else { %>
              <span class="status-badge cross">&#10008; Missing</span>
            <% } %>
          </td>

          <!-- Parent Aadhar Copy -->
          <td class="center-align">
            <% if(hasParentId) { %>
              <a href="ScholarshipDocumentDownloadServlet?id=<%=recId%>&field=parentAadharCopy" target="_blank" class="doc-link" title="View Document">
                <span class="status-badge tick">&#10004; View</span>
              </a>
            <% } else { %>
              <span class="status-badge cross">&#10008; Missing</span>
            <% } %>
          </td>

          <!-- Student Aadhar Copy -->
          <td class="center-align">
            <% if(hasStudentId) { %>
              <a href="ScholarshipDocumentDownloadServlet?id=<%=recId%>&field=studentAadharCopy" target="_blank" class="doc-link" title="View Document">
                <span class="status-badge tick">&#10004; View</span>
              </a>
            <% } else { %>
              <span class="status-badge cross">&#10008; Missing</span>
            <% } %>
          </td>

          <!-- Bank Passbook -->
          <td class="center-align">
            <% if(hasBank) { %>
              <a href="ScholarshipDocumentDownloadServlet?id=<%=recId%>&field=bankPassbookFirstPage" target="_blank" class="doc-link" title="View Document">
                <span class="status-badge tick">&#10004; View</span>
              </a>
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