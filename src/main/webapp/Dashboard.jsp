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
        /* Salesforce Lightning Design System (SLDS) Inspired Palette */
        :root {
            --slds-brand: #0176d3;
            --slds-brand-hover: #014486;
            --slds-bg-page: #f3f3f3;
            --slds-bg-card: #ffffff;
            --slds-border-color: #dddbda;
            --slds-text-primary: #181818;
            --slds-text-secondary: #444444;
            --slds-text-header: #514f4d;
            --slds-row-hover: #f3f3f3;
            --slds-header-bg: #fafaf9;
            --slds-shadow: 0 2px 4px 0 rgba(0, 0, 0, 0.05);
        }

        * {
            box-sizing: border-box;
        }

        body { 
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; 
            margin: 0;
            padding: 24px;
            background-color: var(--slds-bg-page); 
            color: var(--slds-text-primary);
            line-height: 1.5;
        }

        .page-wrapper {
            max-width: 1400px;
            margin: 0 auto;
            width: 100%;
        }
        
        /* Salesforce Header Banner */
        .header-container {
            background-color: var(--slds-bg-card);
            border: 1px solid var(--slds-border-color);
            border-radius: 4px;
            padding: 16px 24px;
            margin-bottom: 20px;
            box-shadow: var(--slds-shadow);
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 12px;
        }

        .header-title {
            color: var(--slds-text-primary);
            margin: 0;
            font-size: 20px;
            font-weight: 700;
            letter-spacing: -0.2px;
        }

        .branch-badge {
            background-color: #eef4fe;
            color: var(--slds-brand);
            border: 1px solid #aecbfa;
            padding: 4px 12px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        /* Summary Metric Cards */
        .summary-box { 
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
            gap: 16px; 
            margin-bottom: 20px; 
        }

        .card { 
            background: var(--slds-bg-card); 
            padding: 16px 20px; 
            border-radius: 4px; 
            border: 1px solid var(--slds-border-color);
            box-shadow: var(--slds-shadow);
            transition: border-color 0.15s ease-in-out;
        }

        .card:hover {
            border-color: var(--slds-brand);
        }

        .card h3 { 
            margin: 0 0 6px 0; 
            font-size: 12px; 
            color: var(--slds-text-header); 
            text-transform: uppercase;
            font-weight: 700;
            letter-spacing: 0.5px;
        }

        .card p { 
            margin: 0; 
            font-size: 26px; 
            font-weight: 700; 
            color: var(--slds-brand); 
        }

        /* Responsive Table Container */
        .table-container {
            background: var(--slds-bg-card);
            border: 1px solid var(--slds-border-color);
            border-radius: 4px;
            box-shadow: var(--slds-shadow);
            overflow-x: auto;
            -webkit-overflow-scrolling: touch;
        }

        table { 
            width: 100%; 
            border-collapse: collapse;
            min-width: 650px;
            font-size: 13px;
        }

        /* Standard Normalized Headers */
        th { 
            background-color: var(--slds-header-bg); 
            color: var(--slds-text-header); 
            font-size: 12px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            padding: 12px 16px;
            text-align: left;
            border-bottom: 1px solid var(--slds-border-color);
            border-top: none;
            white-space: nowrap;
        }

        td { 
            padding: 12px 16px; 
            text-align: left; 
            border-bottom: 1px solid var(--slds-border-color); 
            color: var(--slds-text-primary);
        }

        tbody tr:last-child td {
            border-bottom: none;
        }

        tbody tr:hover {
            background-color: var(--slds-row-hover);
        }

        .total-row {
            font-weight: 700; 
            background-color: #f8f9fa !important;
            border-top: 2px solid var(--slds-border-color);
        }

        .total-row td {
            color: var(--slds-text-primary);
        }

        .error { 
            color: #ea001e; 
            font-weight: 600; 
            background: #fef0f0;
            padding: 16px;
            border-radius: 4px;
            border: 1px solid #fca5a5;
            margin-top: 20px;
        }

        @media (max-width: 768px) {
            body {
                padding: 12px;
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
                    <td colspan="5" style="text-align: center; color: var(--slds-text-secondary); padding: 24px;">No records found for the selected branch.</td>
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