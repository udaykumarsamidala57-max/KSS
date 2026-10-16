<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.Connection" %>
<%@ page import="java.sql.PreparedStatement" %>
<%@ page import="java.sql.ResultSet" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="com.Bean.DBUtil" %>

<%
    // Session Validation
    if (session == null || session.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String role = (String) session.getAttribute("role");
    String branch = (String) session.getAttribute("branch");

    // Access evaluation flags
    boolean isGlobal = "global".equalsIgnoreCase(role) 
                    || "admin".equalsIgnoreCase(role) 
                    || "superadmin".equalsIgnoreCase(role) 
                    || "all".equalsIgnoreCase(role);

    boolean isSandurEducationSociety = branch != null && "SANDUR EDUCATION SOCIETY".equalsIgnoreCase(branch.trim());
    boolean isSandurHatcheries = branch != null && "SANDUR HATCHERIES PVT LTD".equalsIgnoreCase(branch.trim());
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>KSS Scholarship Applications Summary</title>
    <style>
        /* Professional Maroon Color Scheme & Shadows */
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
            
            /* Professional Elevation & Shadows */
            --card-shadow: 0 4px 12px rgba(122, 31, 53, 0.08);
            --card-shadow-hover: 0 6px 16px rgba(122, 31, 53, 0.15);
            --header-shadow: 0 4px 12px rgba(122, 31, 53, 0.12);
        }

        * {
            box-sizing: border-box;
        }

        body { 
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif; 
            margin: 0;
            padding: 24px;
            padding-bottom: 70px;
            background-color: var(--bg-page); 
            color: var(--text-main);
            line-height: 1.5;
        }

        .page-wrapper {
            max-width: 1400px;
            margin: 0 auto;
            width: 100%;
        }
        
        /* Header Banner with Gradient Accent */
        .header-container {
            background-color: var(--bg-card);
            border: 1px solid var(--brand-border);
            border-left: 5px solid var(--brand-primary);
            border-radius: 8px;
            padding: 18px 24px;
            margin-bottom: 24px;
            box-shadow: var(--card-shadow);
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 12px;
        }

        .header-title {
            color: var(--brand-primary-dark);
            margin: 0;
            font-size: 20px;
            font-weight: 700;
            letter-spacing: -0.2px;
        }

        /* Summary Metric Cards */
        .summary-box { 
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
            gap: 18px; 
            margin-bottom: 24px; 
        }

        .card { 
            background: var(--bg-card); 
            padding: 18px 22px; 
            border-radius: 8px; 
            border: 1px solid var(--brand-border);
            border-top: 3px solid var(--brand-primary);
            box-shadow: var(--card-shadow);
            transition: all 0.2s ease-in-out;
        }

        .card:hover {
            transform: translateY(-2px);
            border-color: var(--brand-primary);
            box-shadow: var(--card-shadow-hover);
        }

        .card h3 { 
            margin: 0 0 6px 0; 
            font-size: 11px; 
            color: var(--text-muted); 
            text-transform: uppercase;
            font-weight: 700;
            letter-spacing: 0.6px;
        }

        .card p { 
            margin: 0; 
            font-size: 28px; 
            font-weight: 800; 
            color: var(--brand-primary); 
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
            min-width: 650px;
            font-size: 13px;
        }

        /* Styled Headers */
        th { 
            background-color: var(--header-bg); 
            color: var(--brand-primary-dark); 
            font-size: 12px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            padding: 14px 18px;
            text-align: left;
            border-bottom: 2px solid var(--brand-border);
            border-top: none;
            white-space: nowrap;
        }

        td { 
            padding: 14px 18px; 
            text-align: left; 
            border-bottom: 1px solid var(--brand-border); 
            color: var(--text-main);
        }

        tbody tr:last-child td {
            border-bottom: none;
        }

        tbody tr:hover {
            background-color: var(--row-hover);
        }

        .total-row {
            font-weight: 700; 
            background-color: var(--brand-accent-bg) !important;
            border-top: 2px solid var(--brand-border);
        }

        .total-row td {
            color: var(--brand-primary-dark);
            font-size: 14px;
        }

        .error { 
            color: #a93226; 
            font-weight: 600; 
            background: #fdf2e9;
            padding: 16px;
            border-radius: 6px;
            border: 1px solid #f5c6cb;
            margin-top: 20px;
            box-shadow: var(--card-shadow);
        }

        @media (max-width: 768px) {
            body {
                padding: 12px;
                padding-bottom: 80px;
            }

            .header-container {
                flex-direction: column;
                align-items: flex-start;
            }

            .header-title {
                font-size: 18px;
            }

            .summary-box {
                grid-template-columns: repeat(2, 1fr);
            }
        }

        @media (max-width: 480px) {
            .summary-box {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>

<%@ include file="header.jsp" %>

<div class="page-wrapper">

    <div class="header-container">
        <h1 class="header-title">KSS Student Scholarship Summary</h1>
    </div>

<%
    int grandTotal = 0;
    int grandBasicFilled = 0;
    int grandDocsUploaded = 0;
    int grandSubmitted = 0;

    // Base Select Projection
    StringBuilder sql = new StringBuilder();
    sql.append("SELECT ")
       .append("  org_name, ")
       .append("  COUNT(id) AS total_applications, ")
       .append("  SUM(CASE WHEN org_name IS NOT NULL AND emp_no IS NOT NULL AND emp_name IS NOT NULL AND children_name IS NOT NULL THEN 1 ELSE 0 END) AS basic_details_filled, ")
       .append("  SUM(CASE WHEN OCTET_LENGTH(previous_ay_marks_card) > 0 ")
       .append("            AND OCTET_LENGTH(kss_application) > 0 ")
       .append("            AND OCTET_LENGTH(fee_structure) > 0 ")
       .append("            AND OCTET_LENGTH(fee_receipts) > 0 ")
       .append("            AND OCTET_LENGTH(parent_aadhar_copy) > 0 ")
       .append("            AND OCTET_LENGTH(student_aadhar_copy) > 0 ")
       .append("            AND OCTET_LENGTH(bank_passbook_first_page) > 0 ")
       .append("            AND OCTET_LENGTH(parent_aadhar) > 0 ")
       .append("            AND OCTET_LENGTH(student_aadhar) > 0 THEN 1 ELSE 0 END) AS all_docs_uploaded, ")
       .append("  SUM(CASE WHEN LOWER(TRIM(submiited)) = 'submitted' THEN 1 ELSE 0 END) AS total_submitted ")
       .append("FROM kss_student_scholarship ");

    // Dynamic WHERE clause based on branch group or role criteria
    if (!isGlobal) {
        if (isSandurEducationSociety) {
            sql.append("WHERE LOWER(TRIM(org_name)) IN (")
               .append("LOWER(TRIM(?)), LOWER(TRIM(?)), LOWER(TRIM(?)), LOWER(TRIM(?)), LOWER(TRIM(?)), LOWER(TRIM(?)), LOWER(TRIM(?))) ");
        } else if (isSandurHatcheries) {
            sql.append("WHERE LOWER(TRIM(org_name)) IN (")
               .append("LOWER(TRIM(?)), LOWER(TRIM(?)), LOWER(TRIM(?))) ");
        } else {
            sql.append("WHERE LOWER(TRIM(org_name)) = LOWER(TRIM(?)) ");
        }
    }

    sql.append("GROUP BY org_name");

    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    try {
        conn = DBUtil.getConnection();
        pstmt = conn.prepareStatement(sql.toString());

        // Parameter binding matching conditions
        if (!isGlobal) {
            if (isSandurEducationSociety) {
                pstmt.setString(1, "SANDUR EDUCATION SOCIETY");
                pstmt.setString(2, "SES VIDYAMANDIR PU COLLEGE");
                pstmt.setString(3, "SMIORE PRIMARY ENGLISH MEDIUM SCHOOL, DEOGIRI");
                pstmt.setString(4, "SMIORE HIGHER PRIMARY SCHOOL, DEOGIRI");
                pstmt.setString(5, "SMIORE HIGH SCHOOL, DEOGIRI");
                pstmt.setString(6, "SMIORE VYASAPURI HIGHER PRIMARY SCHOOL");
                pstmt.setString(7, "SANDUR EDUCATION SOCIETY, SANDUR");
            } else if (isSandurHatcheries) {
                pstmt.setString(1, "SANDUR HATCHERIES PVT LTD");
                pstmt.setString(2, "SANDUR POULTRY FARM");
                pstmt.setString(3, "SANDUR POULTRY BREEDERS");
            } else {
                pstmt.setString(1, branch != null ? branch.trim() : "");
            }
        }

        rs = pstmt.executeQuery();

        java.util.List<java.util.Map<String, Object>> rows = new java.util.ArrayList<>();
        
        while (rs.next()) {
            java.util.Map<String, Object> row = new java.util.HashMap<>();
            String orgName = rs.getString("org_name");
            int totalApps = rs.getInt("total_applications");
            int basicFilled = rs.getInt("basic_details_filled");
            int docsUploaded = rs.getInt("all_docs_uploaded");
            int totalSubmitted = rs.getInt("total_submitted");

            row.put("orgName", orgName);
            row.put("totalApps", totalApps);
            row.put("basicFilled", basicFilled);
            row.put("docsUploaded", docsUploaded);
            row.put("totalSubmitted", totalSubmitted);
            
            rows.add(row);

            grandTotal += totalApps;
            grandBasicFilled += basicFilled;
            grandDocsUploaded += docsUploaded;
            grandSubmitted += totalSubmitted;
        }
%>

    <!-- Top Summary Metric Cards -->
    <div class="summary-box">
        <div class="card">
            <h3>Total Applications</h3>
            <p><%= grandTotal %></p>
        </div>
        <div class="card">
            <h3>Basic Details Filled</h3>
            <p><%= grandBasicFilled %></p>
        </div>
        <div class="card">
            <h3>All Docs Uploaded</h3>
            <p><%= grandDocsUploaded %></p>
        </div>
        <div class="card">
            <h3>Submitted</h3>
            <p><%= grandSubmitted %></p>
        </div>
    </div>

    <!-- Data Table Container -->
    <div class="table-container">
        <table>
            <thead>
                <tr>
                    <th>Organization Name</th>
                    <th>Total Applications</th>
                    <th>Basic Details Filled</th>
                    <th>All Documents Uploaded</th>
                    <th>Submitted</th>
                </tr>
            </thead>
            <tbody>
<%
        if (rows.isEmpty()) {
%>
                <tr>
                    <td colspan="5" style="text-align: center; color: var(--text-muted); padding: 24px;">No records found for the selected branch.</td>
                </tr>
<%
        } else {
            for (java.util.Map<String, Object> row : rows) {
                String orgName = (String) row.get("orgName");
%>
                <tr>
                    <td><%= (orgName != null) ? orgName : "N/A" %></td>
                    <td><%= row.get("totalApps") %></td>
                    <td><%= row.get("basicFilled") %></td>
                    <td><%= row.get("docsUploaded") %></td>
                    <td><%= row.get("totalSubmitted") %></td>
                </tr>
<%
            }
        }
%>
                <tr class="total-row">
                    <td>TOTAL</td>
                    <td><%= grandTotal %></td>
                    <td><%= grandBasicFilled %></td>
                    <td><%= grandDocsUploaded %></td>
                    <td><%= grandSubmitted %></td>
                </tr>
            </tbody>
        </table>
    </div>

<%
    } catch (Exception e) {
%>
        <div class="error">Error retrieving scholarship data: <%= e.getMessage() %></div>
<%
        e.printStackTrace();
    } finally {
        if (rs != null) try { rs.close(); } catch (SQLException ignored) {}
        if (pstmt != null) try { pstmt.close(); } catch (SQLException ignored) {}
        if (conn != null) try { conn.close(); } catch (SQLException ignored) {}
    }
%>

</div>

</body>
</html>