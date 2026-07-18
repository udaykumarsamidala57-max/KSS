<%@ page import="java.sql.*" %>
<%@ page import="com.Bean.DBUtil" %>

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

  .status-badge {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 4px;
    padding: 4px 8px;
    font-size: 10px;
    font-weight: bold;
    border-radius: 3px;
    min-width: 85px;
    text-align: center;
  }

  .tick {
    background-color: #e2f0d9;
    color: #385723;
    border: 1px solid #a9d18e;
  }

  .cross {
    background-color: #fce8e6;
    color: #a51d24;
    border: 1px solid #f5c2c1;
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
    ps = con.prepareStatement("SELECT * FROM kss_student_scholarship ORDER BY emp_no");
    rs = ps.executeQuery();

    boolean hasData = false;
    while(rs.next()){
        hasData = true;
%>
        <tr>
          <td><%=rs.getInt("id")%></td>
          <td><span class="emp-badge"><%=rs.getString("emp_no") != null ? rs.getString("emp_no") : ""%></span></td>
          <td><%=rs.getString("emp_name") != null ? rs.getString("emp_name") : ""%></td>
          <td><%=rs.getString("children_name") != null ? rs.getString("children_name") : ""%></td>

          <td class="center-align">
            <span class="status-badge <%=rs.getBytes("previous_ay_marks_card")!=null?"tick":"cross"%>">
              <%=rs.getBytes("previous_ay_marks_card")!=null?"&#10004; Uploaded":"&#10008; Missing"%>
            </span>
          </td>

          <td class="center-align">
            <span class="status-badge <%=rs.getBytes("kss_application")!=null?"tick":"cross"%>">
              <%=rs.getBytes("kss_application")!=null?"&#10004; Uploaded":"&#10008; Missing"%>
            </span>
          </td>

          <td class="center-align">
            <span class="status-badge <%=rs.getBytes("fee_structure")!=null?"tick":"cross"%>">
              <%=rs.getBytes("fee_structure")!=null?"&#10004; Uploaded":"&#10008; Missing"%>
            </span>
          </td>

          <td class="center-align">
            <span class="status-badge <%=rs.getBytes("fee_receipts")!=null?"tick":"cross"%>">
              <%=rs.getBytes("fee_receipts")!=null?"&#10004; Uploaded":"&#10008; Missing"%>
            </span>
          </td>

          <td class="center-align">
            <span class="status-badge <%=rs.getBytes("parent_aadhar_copy")!=null?"tick":"cross"%>">
              <%=rs.getBytes("parent_aadhar_copy")!=null?"&#10004; Uploaded":"&#10008; Missing"%>
            </span>
          </td>

          <td class="center-align">
            <span class="status-badge <%=rs.getBytes("student_aadhar_copy")!=null?"tick":"cross"%>">
              <%=rs.getBytes("student_aadhar_copy")!=null?"&#10004; Uploaded":"&#10008; Missing"%>
            </span>
          </td>

          <td class="center-align">
            <span class="status-badge <%=rs.getBytes("bank_passbook_first_page")!=null?"tick":"cross"%>">
              <%=rs.getBytes("bank_passbook_first_page")!=null?"&#10004; Uploaded":"&#10008; Missing"%>
            </span>
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