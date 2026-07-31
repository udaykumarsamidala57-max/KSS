<%@page import="java.sql.*"%>
<%@page import="com.Bean.DBUtil"%>
<%
    
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    %>
<%
Connection con = null;
PreparedStatement ps = null;

try{
    con = DBUtil.getConnection();

    String action = request.getParameter("action");

    // Save
    if("save".equals(action)){

        ps = con.prepareStatement("INSERT INTO organization_master(org_name,status) VALUES(?,?)");
        ps.setString(1, request.getParameter("orgName"));
        ps.setString(2, request.getParameter("status"));
        ps.executeUpdate();

        response.sendRedirect("organization.jsp");
        return;
    }

    // Update
    if("update".equals(action)){

        ps = con.prepareStatement("UPDATE organization_master SET org_name=?,status=? WHERE org_id=?");
        ps.setString(1, request.getParameter("orgName"));
        ps.setString(2, request.getParameter("status"));
        ps.setInt(3, Integer.parseInt(request.getParameter("orgId")));
        ps.executeUpdate();

        response.sendRedirect("organization.jsp");
        return;
    }

    // Delete
    if("delete".equals(action)){

        ps = con.prepareStatement("DELETE FROM organization_master WHERE org_id=?");
        ps.setInt(1, Integer.parseInt(request.getParameter("id")));
        ps.executeUpdate();

        response.sendRedirect("organization.jsp");
        return;
    }

}catch(Exception e){
    out.println(e);
}
%>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Organization Master</title>

<style>
  :root {
    --primary-color: #8b263e;       /* Deep Classic Crimson/Burgundy */
    --primary-hover: #6e1c2f;       /* Darker shade for buttons */
    --accent-bg: #fff5f5;           /* Very light soft red for section headers */
    --border-color: #d8b8b8;        /* Soft reddish-gray border */
    --text-main: #333333;
    --bg-main: #fcf8f8;              
  }

  * {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
  }

  body {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    background-color: var(--bg-main);
    color: var(--text-main);
    padding: 20px 10px;
  }

  .container {
    max-width: 850px;
    margin: 0 auto;
    background: #ffffff;
    border-radius: 6px;
    box-shadow: 0 2px 10px rgba(139, 38, 62, 0.08);
    border: 1px solid var(--border-color);
    overflow: hidden;
  }

  /* Header Section */
  .form-header {
    background: linear-gradient(135deg, var(--primary-color), #a8324e);
    color: #ffffff;
    padding: 16px 20px;
    text-align: center;
  }

  .form-header h2 {
    font-size: 20px;
    font-weight: 600;
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
    margin-top: 15px;
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

  input[type=text]:focus,
  select:focus {
    border-color: var(--primary-color);
    box-shadow: 0 0 0 2px rgba(139, 38, 62, 0.15);
  }

  /* Submit Button Styling */
  .form-actions {
    text-align: center;
    margin-top: 15px;
    padding-top: 12px;
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

  /* Corporate PF Data Table */
  .data-table {
    width: 100%;
    border-collapse: collapse;
    margin-top: 10px;
    font-size: 13px;
  }

  .data-table th {
    background-color: var(--primary-color);
    color: #ffffff;
    font-weight: 600;
    text-transform: uppercase;
    font-size: 12px;
    letter-spacing: 0.5px;
    padding: 8px 12px;
    text-align: left;
    border: 1px solid var(--primary-color);
  }

  .data-table td {
    padding: 8px 12px;
    border: 1px solid #e8d0d0;
    color: var(--text-main);
  }

  .data-table tr:nth-child(even) {
    background-color: #fffafb;
  }

  .data-table tr:hover {
    background-color: #f7e8ec;
  }

  /* Status Badges */
  .badge {
    padding: 3px 8px;
    border-radius: 12px;
    font-size: 11px;
    font-weight: 600;
    display: inline-block;
  }

  .badge-active {
    background-color: #e6f4ea;
    color: #137333;
  }

  .badge-inactive {
    background-color: #fce8e6;
    color: #c5221f;
  }

  /* Action Links */
  .btn-action {
    text-decoration: none;
    font-weight: 600;
    font-size: 12px;
    padding: 3px 8px;
    border-radius: 3px;
    transition: all 0.2s;
  }

  .btn-edit {
    color: var(--primary-color);
    border: 1px solid var(--border-color);
    background: #fff;
    margin-right: 4px;
  }

  .btn-edit:hover {
    background: var(--accent-bg);
  }

  .btn-delete {
    color: #d93025;
    border: 1px solid #f5c6cb;
    background: #fff;
  }

  .btn-delete:hover {
    background: #f8d7da;
  }

  /* Responsive Design */
  @media (max-width: 768px) {
    .form-grid {
      grid-template-columns: 1fr;
    }
    .form-group.full-width {
      grid-column: span 1;
    }
    .container {
      margin: 5px;
    }
  }
</style>
</head>

<body>
<%@ include file="header.jsp" %>
<div class="container">

  <div class="form-header">
    <h2>Organization Master</h2>
    <p>Manage corporate entities and status configurations</p>
  </div>

  <div class="form-body">

<%
String id = request.getParameter("edit");

String orgName = "";
String status = "Active";

if(id != null){
    con = DBUtil.getConnection();
    ps = con.prepareStatement("select * from organization_master where org_id=?");
    ps.setInt(1, Integer.parseInt(id));

    ResultSet rs = ps.executeQuery();
    if(rs.next()){
        orgName = rs.getString("org_name");
        status = rs.getString("status");
    }
}
%>

    <!-- FORM SECTION -->
    <div class="section-title"><%= id == null ? "Add New Organization" : "Edit Organization Details" %></div>

    <form method="post">
      <input type="hidden" name="action" value="<%= id == null ? "save" : "update" %>">
      <input type="hidden" name="orgId" value="<%= id == null ? "" : id %>">

      <div class="form-grid">
        <div class="form-group">
          <label>Organization Name <span class="required">*</span></label>
          <input type="text" name="orgName" value="<%= orgName %>" placeholder="Enter Organization Name" required>
        </div>

        <div class="form-group">
          <label>Status <span class="required">*</span></label>
          <select name="status">
            <option value="Active" <%= "Active".equals(status) ? "selected" : "" %>>Active</option>
            <option value="Inactive" <%= "Inactive".equals(status) ? "selected" : "" %>>Inactive</option>
          </select>
        </div>
      </div>

      <div class="form-actions">
        <input type="submit" value="<%= id == null ? "Save Organization" : "Update Details" %>">
      </div>
    </form>

    <!-- DATA TABLE SECTION -->
    <div class="section-title">Registered Organizations</div>

    <table class="data-table">
      <thead>
        <tr>
          <th style="width: 10%;">ID</th>
          <th>Organization Name</th>
          <th style="width: 20%;">Status</th>
          <th style="width: 25%; text-align: center;">Actions</th>
        </tr>
      </thead>
      <tbody>
<%
con = DBUtil.getConnection();
ps = con.prepareStatement("select * from organization_master order by org_name");
ResultSet rs = ps.executeQuery();

boolean hasData = false;
while(rs.next()){
    hasData = true;
    String currentStatus = rs.getString("status");
%>
        <tr>
          <td><%= rs.getInt("org_id") %></td>
          <td><strong><%= rs.getString("org_name") %></strong></td>
          <td>
            <span class="badge <%= "Active".equalsIgnoreCase(currentStatus) ? "badge-active" : "badge-inactive" %>">
              <%= currentStatus %>
            </span>
          </td>
          <td style="text-align: center;">
            <a href="organization.jsp?edit=<%= rs.getInt("org_id") %>" class="btn-action btn-edit">
              Edit
            </a>
            <a href="organization.jsp?action=delete&id=<%= rs.getInt("org_id") %>" class="btn-action btn-delete" onclick="return confirm('Are you sure you want to delete this record?')">
              Delete
            </a>
          </td>
        </tr>
<%
}
if(!hasData){
%>
        <tr>
          <td colspan="4" style="text-align: center; color: #777; padding: 15px;">No records found.</td>
        </tr>
<%
}
%>
      </tbody>
    </table>

  </div>

</div>

</body>
</html>