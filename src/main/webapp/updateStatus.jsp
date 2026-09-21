<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Scholarship Applications Management</title>
    <style>
        :root {
            /* Header Matched Color Palette */
            --primary-color: #104c82;
            --primary-light: #1a68aa;
            --primary-hover: #0b3760;
            --bg-color: #f4f6f9;
            --card-bg: #ffffff;
            --border-color: #dce2e6;
            --text-main: #2c3e50;
            --text-muted: #6c757d;
            --success-bg: #e6f4ea;
            --success-text: #137333;
            --danger-bg: #fce8e6;
            --danger-text: #c5221f;
            --warning-bg: #fef7e0;
            --warning-text: #b06000;
        }

        * {
            box-sizing: border-box;
        }

        body { 
            font-family: 'Segoe UI', -apple-system, BlinkMacSystemFont, Roboto, Oxygen, Ubuntu, Cantarell, sans-serif; 
            margin: 0;
            padding: 15px;
            background-color: var(--bg-color); 
            color: var(--text-main);
            width: 100%;
            overflow-x: hidden;
        }

        .container {
            width: 100%;
            max-width: 100%;
            margin: 0 auto;
        }

        .page-title {
            color: var(--primary-color);
            margin: 0 0 15px 0;
            font-size: 1.35rem;
            font-weight: 700;
            border-bottom: 3px solid var(--primary-light);
            padding-bottom: 6px;
            display: inline-block;
        }

        /* Alert Notifications */
        .alert { 
            padding: 12px 16px; 
            margin-bottom: 15px; 
            border-radius: 6px; 
            font-weight: 600; 
            font-size: 0.85rem;
            box-shadow: 0 1px 3px rgba(0,0,0,0.05);
        }
        .alert-success { 
            background-color: var(--success-bg); 
            color: var(--success-text); 
            border-left: 4px solid #137333; 
        }
        .alert-danger { 
            background-color: var(--danger-bg); 
            color: var(--danger-text); 
            border-left: 4px solid #c5221f; 
        }

        /* Responsive Table Card Container */
        .table-card { 
            background: var(--card-bg); 
            padding: 15px; 
            border-radius: 8px; 
            box-shadow: 0 2px 8px rgba(0,0,0,0.06); 
            border: 1px solid var(--border-color);
            width: 100%;
            overflow-x: auto;
            -webkit-overflow-scrolling: touch;
        }

        table { 
            width: 100%; 
            border-collapse: separate;
            border-spacing: 0;
            font-size: 0.8rem; 
            text-align: left; 
        }

        /* Header Styling */
        th { 
            background-color: var(--primary-color); 
            color: #ffffff; 
            padding: 10px 8px;
            font-weight: 600;
            text-transform: uppercase;
            font-size: 0.7rem;
            letter-spacing: 0.5px;
            position: sticky;
            top: 0;
            z-index: 10;
            white-space: nowrap;
        }
        th:first-child { border-top-left-radius: 6px; }
        th:last-child { border-top-right-radius: 6px; }

        td { 
            padding: 10px 8px; 
            border-bottom: 1px solid var(--border-color); 
            vertical-align: middle;
            white-space: normal; 
            word-break: break-word;
        }

        tr:hover td { 
            background-color: #f8fafc; 
        }

        /* Basic Info Column Formatting */
        .basic-info {
            display: flex;
            flex-direction: column;
            gap: 2px;
        }
        .basic-title {
            font-weight: 700;
            color: var(--text-main);
            font-size: 0.8rem;
        }
        .basic-sub {
            color: var(--text-muted);
            font-size: 0.72rem;
        }

        /* Details Accordion / Dropdown Styling */
        details.more-details {
            border: 1px solid var(--border-color);
            border-radius: 6px;
            background: #fff;
            padding: 6px 10px;
            cursor: pointer;
            min-width: 280px;
        }

        details.more-details summary {
            font-weight: 600;
            color: var(--primary-light);
            font-size: 0.75rem;
            outline: none;
            user-select: none;
            padding: 2px 0;
        }

        details.more-details summary:hover {
            color: var(--primary-hover);
        }

        .dropdown-content {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 12px;
            margin-top: 8px;
            padding-top: 8px;
            border-top: 1px dashed var(--border-color);
            cursor: default;
        }

        .details-section {
            background: #f8fafc;
            padding: 8px;
            border-radius: 6px;
            border: 1px solid #edf2f7;
        }

        .section-header {
            font-size: 0.7rem;
            font-weight: 700;
            color: var(--primary-color);
            text-transform: uppercase;
            margin-bottom: 5px;
            border-bottom: 1px solid #e2e8f0;
            padding-bottom: 2px;
        }

        /* Structured Info Formatting inside Dropdown */
        .info-block {
            display: flex;
            flex-direction: column;
            gap: 3px;
        }
        .info-row {
            display: flex;
            gap: 4px;
            align-items: baseline;
            line-height: 1.3;
        }
        .label {
            font-weight: 600;
            color: var(--text-muted);
            font-size: 0.7rem;
            min-width: 70px;
            flex-shrink: 0;
        }
        .value {
            color: var(--text-main);
            font-weight: 500;
            font-size: 0.75rem;
        }

        /* Status Badges */
        .badge { 
            padding: 2px 5px; 
            border-radius: 3px; 
            font-size: 0.65rem; 
            font-weight: 700; 
            display: inline-block; 
            text-transform: uppercase;
            text-align: center;
        }
        .badge-uploaded { 
            background-color: var(--success-bg); 
            color: var(--success-text); 
        }
        .badge-missing { 
            background-color: var(--danger-bg); 
            color: var(--danger-text); 
        }

        /* Documents Container inside Dropdown */
        .doc-group {
            display: flex;
            flex-direction: column;
            gap: 3px;
        }
        .doc-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            font-size: 0.7rem;
            gap: 6px;
        }

        /* Form Controls */
        .action-form {
            display: flex;
            flex-direction: column;
            gap: 5px;
            margin-top: 4px;
        }
        .btn-update { 
            background-color: var(--primary-light); 
            color: white; 
            border: none; 
            padding: 8px 14px; 
            border-radius: 4px; 
            cursor: pointer; 
            font-weight: 600;
            font-size: 0.75rem;
            width: 100%;
            transition: background-color 0.2s ease;
            text-align: center;
        }
        .btn-update:hover { 
            background-color: var(--primary-hover); 
        }
    </style>
</head>
<body>

    <%-- Include Header --%>
    <%@ include file="header.jsp" %>

    <div class="container">
        <h2 class="page-title">Scholarship Applications Management</h2>

        <%-- Success & Error Alerts --%>
        <c:if test="${not empty message}">
            <div class="alert alert-success">${message}</div>
        </c:if>
        <c:if test="${not empty error}">
            <div class="alert alert-danger">${error}</div>
        </c:if>

        <div class="table-card">
            <table>
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>App No</th>
                        <th>Employee & Org</th>
                        <th>Student Name</th>
                        <th>Course</th>
                        <th>Details & Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <c:forEach var="app" items="${applicationList}">
                        <tr>
                            <%-- 1. ID --%>
                            <td><strong>${app.id}</strong></td>

                            <%-- 2. App No --%>
                            <td><span style="color: var(--primary-light); font-weight: 700;">${app.app_no}</span></td>

                            <%-- 3. Basic Employee & Org --%>
                            <td>
                                <div class="basic-info">
                                    <span class="basic-title">${app.empName}</span>
                                    <span class="basic-sub">${app.orgName} (${app.empNo})</span>
                                </div>
                            </td>

                            <%-- 4. Basic Child Details --%>
                            <td>
                                <div class="basic-info">
                                    <span class="basic-title">${app.childrenName}</span>
                                    <span class="basic-sub">Rel: ${app.relationship}</span>
                                </div>
                            </td>

                            <%-- 5. Basic Course Details --%>
                            <td>
                                <div class="basic-info">
                                    <span class="basic-title">${app.course}</span>
                                    <span class="basic-sub">${app.presentYear}</span>
                                </div>
                            </td>

                            <%-- 6. Full Details & Action Dropdown --%>
                            <td>
                                <details class="more-details">
                                    <summary>View Full Details & Actions</summary>
                                    <div class="dropdown-content">
                                        
                                        <%-- Employee Details --%>
                                        <div class="details-section">
                                            <div class="section-header">Employee Details</div>
                                            <div class="info-block">
                                                <div class="info-row"><span class="label">Designation:</span><span class="value">${app.designation}</span></div>
                                                <div class="info-row"><span class="label">Contact:</span><span class="value">${app.empContact}</span></div>
                                                <div class="info-row"><span class="label">Spouse SMIORE:</span><span class="value">${app.spouseWorkingSMIORE}</span></div>
                                                <div class="info-row"><span class="label">Spouse Group Co:</span><span class="value">${app.spouseWorkingGroupCompanies}</span></div>
                                            </div>
                                        </div>

                                        <%-- Child Details --%>
                                        <div class="details-section">
                                            <div class="section-header">Child Details</div>
                                            <div class="info-block">
                                                <div class="info-row"><span class="label">DOB:</span><span class="value">${app.dob}</span></div>
                                                <div class="info-row"><span class="label">Gender:</span><span class="value">${app.gender}</span></div>
                                                <div class="info-row"><span class="label">Child Order:</span><span class="value">${app.childOrder}</span></div>
                                            </div>
                                        </div>

                                        <%-- College & Academic --%>
                                        <div class="details-section">
                                            <div class="section-header">College & Academic</div>
                                            <div class="info-block">
                                                <div class="info-row"><span class="label">College:</span><span class="value">${app.collegeName}</span></div>
                                                <div class="info-row"><span class="label">Place:</span><span class="value">${app.placeCollege}</span></div>
                                                <div class="info-row"><span class="label">Prev AY %:</span><span class="value">${app.previousAyPercentage}%</span></div>
                                                <div class="info-row"><span class="label">Curr Fee:</span><span class="value">₹${app.feeAmountCurrentAy}</span></div>
                                                <div class="info-row"><span class="label">Fee Paid:</span><span class="value" style="color: var(--primary-light); font-weight:700;">₹${app.actualFeePaid}</span></div>
                                            </div>
                                        </div>

                                        <%-- Bank Account Details --%>
                                        <div class="details-section">
                                            <div class="section-header">Bank Account</div>
                                            <div class="info-block">
                                                <div class="info-row"><span class="label">Passbook Name:</span><span class="value">${app.employeeNamePassbook}</span></div>
                                                <div class="info-row"><span class="label">Bank:</span><span class="value">${app.bankName}</span></div>
                                                <div class="info-row"><span class="label">Branch:</span><span class="value">${app.branchName}</span></div>
                                                <div class="info-row"><span class="label">Acc No:</span><span class="value">${app.bankAccountNo}</span></div>
                                                <div class="info-row"><span class="label">IFSC:</span><span class="value">${app.ifscCode}</span></div>
                                            </div>
                                        </div>

                                        <%-- Document Statuses --%>
                                        <div class="details-section" style="grid-column: span 1 / -1;">
                                            <div class="section-header">Document Status</div>
                                            <div class="doc-group">
                                                <div class="doc-item">
                                                    <span>Marks Card</span>
                                                    <span class="badge ${app.marksCardStatus == 'Uploaded' ? 'badge-uploaded' : 'badge-missing'}">
                                                        ${app.marksCardStatus == 'Uploaded' ? '✓ Uploaded' : '✕ Missing'}
                                                    </span>
                                                </div>
                                                <div class="doc-item">
                                                    <span>KSS App</span>
                                                    <span class="badge ${app.kssAppStatus == 'Uploaded' ? 'badge-uploaded' : 'badge-missing'}">
                                                        ${app.kssAppStatus == 'Uploaded' ? '✓ Uploaded' : '✕ Missing'}
                                                    </span>
                                                </div>
                                                <div class="doc-item">
                                                    <span>Fee Structure</span>
                                                    <span class="badge ${app.feeStructureStatus == 'Uploaded' ? 'badge-uploaded' : 'badge-missing'}">
                                                        ${app.feeStructureStatus == 'Uploaded' ? '✓ Uploaded' : '✕ Missing'}
                                                    </span>
                                                </div>
                                                <div class="doc-item">
                                                    <span>Fee Receipts</span>
                                                    <span class="badge ${app.feeReceiptsStatus == 'Uploaded' ? 'badge-uploaded' : 'badge-missing'}">
                                                        ${app.feeReceiptsStatus == 'Uploaded' ? '✓ Uploaded' : '✕ Missing'}
                                                    </span>
                                                </div>
                                                <div class="doc-item">
                                                    <span>Parent Aadhar Copy</span>
                                                    <span class="badge ${app.parentAadharCopyStatus == 'Uploaded' ? 'badge-uploaded' : 'badge-missing'}">
                                                        ${app.parentAadharCopyStatus == 'Uploaded' ? '✓ Uploaded' : '✕ Missing'}
                                                    </span>
                                                </div>
                                                <div class="doc-item">
                                                    <span>Student Aadhar Copy</span>
                                                    <span class="badge ${app.studentAadharCopyStatus == 'Uploaded' ? 'badge-uploaded' : 'badge-missing'}">
                                                        ${app.studentAadharCopyStatus == 'Uploaded' ? '✓ Uploaded' : '✕ Missing'}
                                                    </span>
                                                </div>
                                                <div class="doc-item">
                                                    <span>Bank Passbook</span>
                                                    <span class="badge ${app.passbookStatus == 'Uploaded' ? 'badge-uploaded' : 'badge-missing'}">
                                                        ${app.passbookStatus == 'Uploaded' ? '✓ Uploaded' : '✕ Missing'}
                                                    </span>
                                                </div>
                                                <div class="doc-item">
                                                    <span>Parent Aadhar</span>
                                                    <span class="badge ${app.parentAadharStatus == 'Uploaded' ? 'badge-uploaded' : 'badge-missing'}">
                                                        ${app.parentAadharStatus == 'Uploaded' ? '✓ Uploaded' : '✕ Missing'}
                                                    </span>
                                                </div>
                                                <div class="doc-item">
                                                    <span>Student Aadhar</span>
                                                    <span class="badge ${app.studentAadharStatus == 'Uploaded' ? 'badge-uploaded' : 'badge-missing'}">
                                                        ${app.studentAadharStatus == 'Uploaded' ? '✓ Uploaded' : '✕ Missing'}
                                                    </span>
                                                </div>
                                            </div>
                                        </div>

                                        <%-- Actions Section Inside Dropdown --%>
                                        <div class="details-section" style="grid-column: span 1 / -1; background-color: #f1f5f9; border-top: 2px solid var(--primary-light);">
                                            <div class="section-header">Application Actions</div>
                                            <form action="UpdateStatusServlet" method="post" class="action-form">
                                                <input type="hidden" name="scholarshipId" value="${app.id}" />
                                                <input type="hidden" name="submitted" value="Submitted" />
                                                <button type="submit" class="btn-update">Forward to KSS</button>
                                            </form>
                                        </div>

                                    </div>
                                </details>
                            </td>
                        </tr>
                    </c:forEach>
                    
                    <%-- Empty Fallback --%>
                    <c:if test="${empty applicationList}">
                        <tr>
                            <td colspan="6" style="text-align: center; padding: 30px; color: var(--text-muted);">
                                No scholarship records found.
                            </td>
                        </tr>
                    </c:if>
                </tbody>
            </table>
        </div>
    </div>

</body>
</html>