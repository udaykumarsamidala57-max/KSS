<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List, java.util.ArrayList, java.util.Map, java.util.HashMap" %>
<%@ page import="java.sql.Connection, java.sql.PreparedStatement, java.sql.ResultSet, java.sql.ResultSetMetaData, java.sql.SQLException" %>
<%@ page import="com.Bean.DBUtil" %>

<%
// Session Validation
if (session == null || session.getAttribute("username") == null) {
    response.sendRedirect("login.jsp");
    return;
}

String role = (String) session.getAttribute("role");
String branch = (String) session.getAttribute("branch");

// Role and Organization Checks
boolean isSandurEducationSociety = "SANDUR EDUCATION SOCIETY".equalsIgnoreCase(branch) || "Sandur Education Society".equalsIgnoreCase(branch);
boolean isSandurHatcheries = "SANDUR HATCHERIES PVT LTD".equalsIgnoreCase(branch) || "Sandur Hatcheries".equalsIgnoreCase(branch);

// ==========================================
// 1. EXCEL DOWNLOAD ROUTE
// ==========================================
String exportFormat = request.getParameter("export");
boolean isExcel = "excel".equalsIgnoreCase(exportFormat);

if (isExcel) {
    response.setContentType("application/vnd.ms-excel");
    response.setHeader("Content-Disposition", "attachment; filename=\"submitted_scholarship_applications.xls\"");
}

// ==========================================
// 2. PAGE PARAMS & DB QUERY
// ==========================================
int pageNum = 1;
int limit = isExcel ? 5000 : 10; // Export all records (up to 5000) or paginate
if (request.getParameter("page") != null && !isExcel) {
    try { pageNum = Integer.parseInt(request.getParameter("page")); } catch (Exception ignored) {}
}
int offset = (pageNum - 1) * limit;

// Fetch details strictly for "Submitted" applications filtered by Role & Branch/Organization
List<Map<String, Object>> applications = new ArrayList<>();

StringBuilder sqlSelect = new StringBuilder("SELECT * FROM kss_student_scholarship WHERE submiited = ? ");
List<Object> params = new ArrayList<>();
params.add("Submitted");

if (!"Global".equalsIgnoreCase(role)) {
    if (isSandurEducationSociety) {
        sqlSelect.append(" AND org_name IN (?, ?, ?, ?, ?, ?)");
        params.add("SANDUR EDUCATION SOCIETY, SANDUR");
        params.add("SES VIDYAMANDIR PU COLLEGE");
        params.add("SMIORE PRIMARY ENGLISH MEDIUM SCHOOL, DEOGIRI");
        params.add("SMIORE HIGHER PRIMARY SCHOOL, DEOGIRI");
        params.add("SMIORE HIGH SCHOOL, DEOGIRI");
        params.add("SMIORE VYASAPURI HIGHER PRIMARY SCHOOL");
    } else if (isSandurHatcheries) {
        sqlSelect.append(" AND org_name IN (?, ?, ?)");
        params.add("SANDUR HATCHERIES PVT LTD");
        params.add("SANDUR POULTRY FARM");
        params.add("SANDUR POULTRY BREEDERS");
    } else {
        sqlSelect.append(" AND org_name = ?");
        params.add(branch != null ? branch.trim() : "");
    }
}

sqlSelect.append(" ORDER BY id DESC ");

// Apply pagination only for web display
if (!isExcel) {
    sqlSelect.append("LIMIT ? OFFSET ?");
    params.add(limit);
    params.add(offset);
}

try (Connection conn = DBUtil.getConnection();
     PreparedStatement ps = conn.prepareStatement(sqlSelect.toString())) {

    for (int i = 0; i < params.size(); i++) {
        ps.setObject(i + 1, params.get(i));
    }

    try (ResultSet rs = ps.executeQuery()) {
        ResultSetMetaData md = rs.getMetaData();
        int columns = md.getColumnCount();

        while (rs.next()) {
            Map<String, Object> row = new HashMap<>();
            for (int i = 1; i <= columns; i++) {
                row.put(md.getColumnLabel(i), rs.getObject(i));
            }
            applications.add(row);
        }
    }
} catch (SQLException e) {
    e.printStackTrace();
}
%>

<% if (!isExcel) { %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Submitted Scholarship Applications</title>
    <style>
        :root {
            --theme-primary: #7a1f35;
            --theme-primary-dark: #5e1627;
            --theme-accent-bg: #fdf6f7;
            --theme-border: #e2cece;
            --theme-text-main: #2b2b2b;
            --theme-text-muted: #666666;
            --theme-hover: #a83d56;
        }

        * { box-sizing: border-box; }
        body { 
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif; 
            background: #fcf8f9; 
            margin: 15px; 
            color: var(--theme-text-main); 
            padding-bottom: 60px; 
        }

        .container { 
            background: #fff; 
            border-radius: 8px; 
            padding: 24px; 
            box-shadow: 0 4px 12px rgba(122, 31, 53, 0.08); 
            border: 1px solid var(--theme-border);
            max-width: 100%; 
            margin: 0 auto; 
        }

        .page-header { 
            display: flex;
            align-items: center;
            justify-content: space-between;
            border-bottom: 2px solid var(--theme-border); 
            padding-bottom: 12px; 
            margin-bottom: 20px;
            flex-wrap: wrap;
            gap: 10px;
        }

        h2 { 
            margin: 0; 
            color: var(--theme-primary-dark); 
            font-size: 1.5rem; 
        }

        .btn-export { 
            background: #27ae60; 
            color: #fff; 
            text-decoration: none; 
            border: none; 
            padding: 8px 14px;
            border-radius: 5px;
            font-size: 13px;
            font-weight: 600; 
            cursor: pointer; 
            display: inline-flex; 
            align-items: center; 
            gap: 6px; 
            white-space: nowrap; 
            box-shadow: 0 2px 6px rgba(39, 174, 96, 0.2);
            transition: all 0.2s ease;
        }
        .btn-export:hover { background: #219653; }
        
        /* Table Styling with Header Colors & Shadows */
        .table-container { 
            width: 100%; 
            overflow-x: auto; 
            -webkit-overflow-scrolling: touch; 
            border: 1px solid var(--theme-border); 
            border-radius: 8px; 
            margin-bottom: 15px; 
            box-shadow: 0 2px 8px rgba(0,0,0,0.04);
        }
        table { width: 100%; border-collapse: separate; border-spacing: 0; font-size: 13px; text-align: left; }
        th, td { padding: 12px 14px; border-bottom: 1px solid #f1e6e6; border-right: 1px solid #f8f1f1; vertical-align: middle; }
        th:last-child, td:last-child { border-right: none; }
        
        /* Styled Header using Burgundy Gradient */
        th { 
            background: linear-gradient(180deg, var(--theme-primary) 0%, var(--theme-primary-dark) 100%); 
            color: #ffffff; 
            font-weight: 600; 
            white-space: nowrap; 
            position: sticky; 
            top: 0; 
            letter-spacing: 0.3px;
            box-shadow: 0 2px 4px rgba(122, 31, 53, 0.15);
        }
        
        tr:nth-child(even) { background-color: #fdfafb; }
        tr:hover { background-color: #f8ecef; }
        
        /* Text Alignments & Formatting */
        .nowrap { white-space: nowrap; }
        .text-center { text-align: center; }
        .text-right { text-align: right; }
        .col-text { min-width: 130px; max-width: 220px; word-wrap: break-word; white-space: normal; }

        /* Badges */
        .badge { display: inline-block; padding: 4px 10px; border-radius: 12px; font-weight: 600; font-size: 11px; text-align: center; white-space: nowrap; }
        .badge-submitted { background: #e8f8f0; color: #1e7e34; border: 1px solid #c3e6cb; }
        
        /* Pagination Controls */
        .pagination { display: flex; justify-content: space-between; align-items: center; margin-top: 20px; flex-wrap: wrap; gap: 10px; }
        .pagination a { 
            padding: 8px 16px; 
            background: #ffffff; 
            color: var(--theme-primary-dark); 
            border: 1px solid var(--theme-border);
            text-decoration: none; 
            border-radius: 5px; 
            font-size: 13px; 
            font-weight: 600;
            transition: all 0.2s ease;
        }
        .pagination a:hover { 
            background: var(--theme-primary); 
            color: #ffffff;
            border-color: var(--theme-primary);
        }

        @media (max-width: 1100px) {
            body { padding-bottom: 90px; margin: 10px; }
            .container { padding: 14px; }
            .page-header { flex-direction: column; align-items: flex-start; }
            .btn-export { width: 100%; text-align: center; justify-content: center; }
        }
    </style>
</head>
<body>

<!-- Include Standard Header Component -->
<jsp:include page="header.jsp" />

<div class="container">
    <div class="page-header">
        <h2>Submitted Applications</h2>
        <!-- Direct Export Button -->
        <a href="submitted_list.jsp?export=excel" class="btn-export">
            &#128190; Export to Excel
        </a>
    </div>

    <!-- Responsive Scrollable Data Table Container -->
    <div class="table-container">
        <table>
            <thead>
                <tr>
                    <th class="nowrap">App No</th>
                    <th class="nowrap">Employee Name</th>
                    <th class="nowrap">Employee No</th>
                    <th class="nowrap">Organization</th>
                    <th class="nowrap">Contact</th>
                    <th class="nowrap">Student Name</th>
                    <th class="nowrap">Gender</th>
                    <th class="nowrap">Relationship</th>
                    <th class="nowrap">Child Order</th>
                    <th class="nowrap">College Name</th>
                    <th class="nowrap">Course</th>
                    <th class="nowrap">Present Year</th>
                    <th class="nowrap text-right">Fee Paid</th>
                    <th class="nowrap">Account No</th>
                    <th class="nowrap">IFSC Code</th>
                    <th class="nowrap">Bank Name</th>
                    <th class="nowrap text-center">Status</th>
                </tr>
            </thead>
            <tbody>
            <% if (!applications.isEmpty()) { 
                for (Map<String, Object> app : applications) { 
            %>
                <tr>
                    <td class="nowrap"><strong><%= app.get("App_no") != null ? app.get("App_no") : "N/A" %></strong></td>
                    <td class="col-text"><%= app.get("emp_name") != null ? app.get("emp_name") : "" %></td>
                    <td class="nowrap"><%= app.get("emp_no") != null ? app.get("emp_no") : "" %></td>
                    <td class="col-text"><%= app.get("org_name") != null ? app.get("org_name") : "" %></td>
                    <td class="nowrap"><%= app.get("emp_contact") != null ? app.get("emp_contact") : "" %></td>
                    <td class="col-text"><%= app.get("children_name") != null ? app.get("children_name") : "" %></td>
                    <td class="nowrap"><%= app.get("gender") != null ? app.get("gender") : "" %></td>
                    <td class="nowrap"><%= app.get("relationship") != null ? app.get("relationship") : "" %></td>
                    <td class="nowrap text-center"><%= app.get("child_order") != null ? app.get("child_order") : "" %></td>
                    <td class="col-text"><%= app.get("college_name") != null ? app.get("college_name") : "" %></td>
                    <td class="col-text"><%= app.get("course") != null ? app.get("course") : "" %></td>
                    <td class="nowrap text-center"><%= app.get("present_year") != null ? app.get("present_year") : "" %></td>
                    <td class="nowrap text-right">&#8377; <%= app.get("actual_fee_paid") != null ? app.get("actual_fee_paid") : "0" %></td>
                    <td class="nowrap"><%= app.get("bank_account_no") != null ? app.get("bank_account_no") : "" %></td>
                    <td class="nowrap"><%= app.get("ifsc_code") != null ? app.get("ifsc_code") : "" %></td>
                    <td class="col-text"><%= app.get("bank_name") != null ? app.get("bank_name") : "" %></td>
                    <td class="nowrap text-center">
                        <span class="badge badge-submitted">
                            <%= app.get("submiited") %>
                        </span>
                    </td>
                </tr>
            <%  } 
            } else { %>
                <tr>
                    <td colspan="17" class="text-center" style="padding: 24px; color: var(--theme-text-muted);">No submitted records found.</td>
                </tr>
            <% } %>
            </tbody>
        </table>
    </div>

    <!-- Pagination Controls -->
    <div class="pagination">
        <div>
            <% if (pageNum > 1) { %>
                <a href="submitted_list.jsp?page=<%= pageNum - 1 %>">&laquo; Previous</a>
            <% } %>
        </div>
        <div style="font-weight: 600; color: var(--theme-primary-dark);">Page <%= pageNum %></div>
        <div>
            <% if (applications.size() == limit) { %>
                <a href="submitted_list.jsp?page=<%= pageNum + 1 %>">Next &raquo;</a>
            <% } %>
        </div>
    </div>
</div>

</body>
</html>
<% } else { %>
<!-- EXCEL ONLY TABLE OUTPUT -->
<table border="1">
    <thead>
        <tr style="background-color: #7a1f35; color: #ffffff;">
            <th>App No</th>
            <th>Employee Name</th>
            <th>Employee No</th>
            <th>Organization</th>
            <th>Contact</th>
            <th>Student Name</th>
            <th>Gender</th>
            <th>Relationship</th>
            <th>Child Order</th>
            <th>College Name</th>
            <th>Course</th>
            <th>Present Year</th>
            <th>Fee Paid</th>
            <th>Bank Account No</th>
            <th>IFSC Code</th>
            <th>Bank Name</th>
            <th>Status</th>
        </tr>
    </thead>
    <tbody>
    <% for (Map<String, Object> app : applications) { %>
        <tr>
            <td>'<%= app.get("App_no") != null ? app.get("App_no") : "N/A" %></td>
            <td><%= app.get("emp_name") %></td>
            <td>'<%= app.get("emp_no") %></td>
            <td><%= app.get("org_name") %></td>
            <td>'<%= app.get("emp_contact") %></td>
            <td><%= app.get("children_name") %></td>
            <td><%= app.get("gender") %></td>
            <td><%= app.get("relationship") %></td>
            <td><%= app.get("child_order") %></td>
            <td><%= app.get("college_name") %></td>
            <td><%= app.get("course") %></td>
            <td><%= app.get("present_year") %></td>
            <td><%= app.get("actual_fee_paid") %></td>
            <td>'<%= app.get("bank_account_no") %></td>
            <td><%= app.get("ifsc_code") %></td>
            <td><%= app.get("bank_name") %></td>
            <td><%= app.get("submiited") %></td>
        </tr>
    <% } %>
    </tbody>
</table>
<% } %>