<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Scholarship Applications Management</title>
    <style>
        /* Salesforce Lightning Design System (SLDS) Inspired Variables */
        :root {
            --slds-brand: #0176d3;
            --slds-brand-hover: #014486;
            --slds-bg-page: #f3f3f3;
            --slds-bg-card: #ffffff;
            --slds-border-color: #dddbda;
            --slds-text-primary: #181818;
            --slds-text-secondary: #514f4d;
            --slds-text-header: #514f4d;
            --slds-row-hover: #f3f3f3;
            --slds-header-bg: #fafaf9;
            --slds-shadow: 0 2px 4px 0 rgba(0, 0, 0, 0.05);

            /* Status Badge Colors */
            --badge-success-bg: #e6f4ea;
            --badge-success-text: #137333;
            --badge-success-border: #ceead6;
            
            --badge-missing-bg: #fce8e6;
            --badge-missing-text: #c5221f;
            --badge-missing-border: #fad2cf;
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

        .container {
            max-width: 1600px;
            margin: 0 auto;
            width: 100%;
        }

        /* Header Container */
        .header-container {
            background-color: var(--slds-bg-card);
            border: 1px solid var(--slds-border-color);
            border-radius: 4px;
            padding: 16px 24px;
            margin-bottom: 20px;
            box-shadow: var(--slds-shadow);
        }

        .header-title {
            margin: 0;
            font-size: 20px;
            font-weight: 700;
            color: var(--slds-text-primary);
            letter-spacing: -0.2px;
        }

        .header-subtitle {
            margin: 4px 0 0 0;
            font-size: 13px;
            color: var(--slds-text-secondary);
        }

        /* Alert Notifications */
        .alert { 
            padding: 12px 16px; 
            margin-bottom: 16px; 
            border-radius: 4px; 
            font-weight: 600; 
            font-size: 13px;
            box-shadow: var(--slds-shadow);
        }
        .alert-success { 
            background-color: var(--badge-success-bg); 
            color: var(--badge-success-text); 
            border: 1px solid var(--badge-success-border); 
        }
        .alert-danger { 
            background-color: var(--badge-missing-bg); 
            color: var(--badge-missing-text); 
            border: 1px solid var(--badge-missing-border); 
        }

        /* Table Card Container */
        .table-card { 
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
            min-width: 900px;
            font-size: 13px;
            text-align: left; 
        }

        /* Standard SLDS Headers */
        th { 
            background-color: var(--slds-header-bg); 
            color: var(--slds-text-header); 
            font-size: 12px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            padding: 12px 16px;
            border-bottom: 1px solid var(--slds-border-color);
            white-space: nowrap;
            position: sticky;
            top: 0;
            z-index: 2;
        }

        td { 
            padding: 12px 16px; 
            border-bottom: 1px solid var(--slds-border-color); 
            vertical-align: top;
            color: var(--slds-text-primary);
        }

        tbody tr:last-child td {
            border-bottom: none;
        }

        tbody tr:hover { 
            background-color: var(--slds-row-hover); 
        }

        /* Basic Info Formatting */
        .basic-info {
            display: flex;
            flex-direction: column;
            gap: 2px;
        }
        .basic-title {
            font-weight: 600;
            color: var(--slds-text-primary);
            font-size: 13px;
        }
        .basic-sub {
            color: var(--slds-text-secondary);
            font-size: 12px;
        }

        /* Accordion Details Dropdown */
        details.more-details {
            border: 1px solid var(--slds-border-color);
            border-radius: 4px;
            background: var(--slds-bg-card);
            padding: 8px 12px;
            cursor: pointer;
            width: 100%;
        }

        details.more-details summary {
            font-weight: 600;
            color: var(--slds-brand);
            font-size: 13px;
            outline: none;
            user-select: none;
        }

        details.more-details summary:hover {
            color: var(--slds-brand-hover);
        }

        /* Structured Container Inside View */
        .dropdown-content {
            display: flex;
            flex-direction: column;
            gap: 16px;
            margin-top: 12px;
            padding-top: 12px;
            border-top: 1px solid var(--slds-border-color);
            cursor: default;
            text-align: left; /* Ensures strict left-alignment */
        }

        .details-section {
            background: var(--slds-header-bg);
            padding: 12px 16px;
            border-radius: 4px;
            border: 1px solid var(--slds-border-color);
        }

        .section-header {
            font-size: 11px;
            font-weight: 700;
            color: var(--slds-text-header);
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-bottom: 10px;
            border-bottom: 1px solid var(--slds-border-color);
            padding-bottom: 4px;
            text-align: left;
        }

        /* Left-Aligned Field Layout */
        .details-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 8px 24px;
        }

        .info-row {
            display: flex;
            align-items: center;
            line-height: 1.4;
            text-align: left;
        }

        .label {
            font-weight: 600;
            color: var(--slds-text-secondary);
            font-size: 12px;
            width: 140px;
            flex-shrink: 0;
            text-align: left;
        }

        .value {
            color: var(--slds-text-primary);
            font-weight: 500;
            font-size: 12px;
            text-align: left;
        }

        /* Status Badges */
        .badge { 
            display: inline-flex;
            align-items: center;
            justify-content: center;
            padding: 2px 8px; 
            border-radius: 12px; 
            font-size: 11px; 
            font-weight: 700; 
            text-align: center;
        }
        .badge-uploaded { 
            background-color: var(--badge-success-bg); 
            color: var(--badge-success-text); 
            border: 1px solid var(--badge-success-border);
        }
        .badge-missing { 
            background-color: var(--badge-missing-bg); 
            color: var(--badge-missing-text); 
            border: 1px solid var(--badge-missing-border);
        }

        /* Left-Aligned Document Grid */
        .doc-group {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 8px 24px;
        }

        .doc-item {
            display: flex;
            align-items: center;
            gap: 12px;
            font-size: 12px;
            padding: 4px 0;
            border-bottom: 1px dashed var(--slds-border-color);
        }

        .doc-name {
            width: 140px;
            font-weight: 600;
            color: var(--slds-text-secondary);
            flex-shrink: 0;
        }

        /* Actions Section */
        .action-section {
            background-color: var(--slds-header-bg);
            border: 1px solid var(--slds-border-color);
            padding: 12px 16px;
            border-radius: 4px;
        }

        .action-form {
            display: flex;
            justify-content: flex-start;
            margin-top: 4px;
        }

        .btn-update { 
            background-color: var(--slds-brand); 
            color: #ffffff; 
            border: 1px solid var(--slds-brand); 
            padding: 8px 20px; 
            border-radius: 4px; 
            cursor: pointer; 
            font-weight: 600;
            font-size: 13px;
            transition: background-color 0.15s ease-in-out;
            text-align: center;
        }

        .btn-update:hover { 
            background-color: var(--slds-brand-hover); 
            border-color: var(--slds-brand-hover);
        }

        @media (max-width: 992px) {
            .details-grid, .doc-group {
                grid-template-columns: 1fr;
            }
        }

        @media (max-width: 768px) {
            body {
                padding: 12px;
            }
            .header-title {
                font-size: 18px;
            }
        }
    </style>
</head>
<body>

    <%-- Include Header --%>
    <%@ include file="header.jsp" %>

    <div class="container">
        <div class="header-container">
            <h1 class="header-title">Forward Applications to KSS</h1>
            <p class="header-subtitle">Review application details and forward processed scholarship requests.</p>
        </div>

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
                            <td><span style="color: var(--slds-brand); font-weight: 700;">${app.app_no}</span></td>

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

                            <%-- 6. Left-Aligned Full Details Dropdown --%>
                            <td style="min-width: 450px;">
                                <details class="more-details">
                                    <summary>View Full Details & Actions</summary>
                                    <div class="dropdown-content">
                                        
                                        <%-- Employee Details --%>
                                        <div class="details-section">
                                            <div class="section-header">Employee Details</div>
                                            <div class="details-grid">
                                                <div class="info-row"><span class="label">Designation:</span><span class="value">${app.designation}</span></div>
                                                <div class="info-row"><span class="label">Contact:</span><span class="value">${app.empContact}</span></div>
                                                <div class="info-row"><span class="label">Spouse SMIORE:</span><span class="value">${app.spouseWorkingSMIORE}</span></div>
                                                <div class="info-row"><span class="label">Spouse Group:</span><span class="value">${app.spouseWorkingGroupCompanies}</span></div>
                                            </div>
                                        </div>

                                        <%-- Child Details --%>
                                        <div class="details-section">
                                            <div class="section-header">Child Details</div>
                                            <div class="details-grid">
                                                <div class="info-row"><span class="label">DOB:</span><span class="value">${app.dob}</span></div>
                                                <div class="info-row"><span class="label">Gender:</span><span class="value">${app.gender}</span></div>
                                                <div class="info-row"><span class="label">Child Order:</span><span class="value">${app.childOrder}</span></div>
                                            </div>
                                        </div>

                                        <%-- College & Academic --%>
                                        <div class="details-section">
                                            <div class="section-header">College & Academic Details</div>
                                            <div class="details-grid">
                                                <div class="info-row"><span class="label">College:</span><span class="value">${app.collegeName}</span></div>
                                                <div class="info-row"><span class="label">Place:</span><span class="value">${app.placeCollege}</span></div>
                                                <div class="info-row"><span class="label">Prev AY %:</span><span class="value">${app.previousAyPercentage}%</span></div>
                                                <div class="info-row"><span class="label">Curr Fee:</span><span class="value">₹${app.feeAmountCurrentAy}</span></div>
                                                <div class="info-row"><span class="label">Fee Paid:</span><span class="value" style="color: var(--slds-brand); font-weight:700;">₹${app.actualFeePaid}</span></div>
                                            </div>
                                        </div>

                                        <%-- Bank Account Details --%>
                                        <div class="details-section">
                                            <div class="section-header">Bank Account Details</div>
                                            <div class="details-grid">
                                                <div class="info-row"><span class="label">Passbook Name:</span><span class="value">${app.employeeNamePassbook}</span></div>
                                                <div class="info-row"><span class="label">Bank Name:</span><span class="value">${app.bankName}</span></div>
                                                <div class="info-row"><span class="label">Branch Name:</span><span class="value">${app.branchName}</span></div>
                                                <div class="info-row"><span class="label">Account No:</span><span class="value">${app.bankAccountNo}</span></div>
                                                <div class="info-row"><span class="label">IFSC Code:</span><span class="value">${app.ifscCode}</span></div>
                                            </div>
                                        </div>

                                        <%-- Document Statuses --%>
                                        <div class="details-section">
                                            <div class="section-header">Document Status</div>
                                            <div class="doc-group">
                                                <div class="doc-item">
                                                    <span class="doc-name">Marks Card:</span>
                                                    <span class="badge ${app.marksCardStatus == 'Uploaded' ? 'badge-uploaded' : 'badge-missing'}">
                                                        ${app.marksCardStatus == 'Uploaded' ? '✓ Uploaded' : '✕ Missing'}
                                                    </span>
                                                </div>
                                                <div class="doc-item">
                                                    <span class="doc-name">KSS App:</span>
                                                    <span class="badge ${app.kssAppStatus == 'Uploaded' ? 'badge-uploaded' : 'badge-missing'}">
                                                        ${app.kssAppStatus == 'Uploaded' ? '✓ Uploaded' : '✕ Missing'}
                                                    </span>
                                                </div>
                                                <div class="doc-item">
                                                    <span class="doc-name">Fee Structure:</span>
                                                    <span class="badge ${app.feeStructureStatus == 'Uploaded' ? 'badge-uploaded' : 'badge-missing'}">
                                                        ${app.feeStructureStatus == 'Uploaded' ? '✓ Uploaded' : '✕ Missing'}
                                                    </span>
                                                </div>
                                                <div class="doc-item">
                                                    <span class="doc-name">Fee Receipts:</span>
                                                    <span class="badge ${app.feeReceiptsStatus == 'Uploaded' ? 'badge-uploaded' : 'badge-missing'}">
                                                        ${app.feeReceiptsStatus == 'Uploaded' ? '✓ Uploaded' : '✕ Missing'}
                                                    </span>
                                                </div>
                                                <div class="doc-item">
                                                    <span class="doc-name">Parent ID Copy:</span>
                                                    <span class="badge ${app.parentAadharCopyStatus == 'Uploaded' ? 'badge-uploaded' : 'badge-missing'}">
                                                        ${app.parentAadharCopyStatus == 'Uploaded' ? '✓ Uploaded' : '✕ Missing'}
                                                    </span>
                                                </div>
                                                <div class="doc-item">
                                                    <span class="doc-name">Student ID Copy:</span>
                                                    <span class="badge ${app.studentAadharCopyStatus == 'Uploaded' ? 'badge-uploaded' : 'badge-missing'}">
                                                        ${app.studentAadharCopyStatus == 'Uploaded' ? '✓ Uploaded' : '✕ Missing'}
                                                    </span>
                                                </div>
                                                <div class="doc-item">
                                                    <span class="doc-name">Bank Passbook:</span>
                                                    <span class="badge ${app.passbookStatus == 'Uploaded' ? 'badge-uploaded' : 'badge-missing'}">
                                                        ${app.passbookStatus == 'Uploaded' ? '✓ Uploaded' : '✕ Missing'}
                                                    </span>
                                                </div>
                                                <div class="doc-item">
                                                    <span class="doc-name">Parent ID Doc:</span>
                                                    <span class="badge ${app.parentAadharStatus == 'Uploaded' ? 'badge-uploaded' : 'badge-missing'}">
                                                        ${app.parentAadharStatus == 'Uploaded' ? '✓ Uploaded' : '✕ Missing'}
                                                    </span>
                                                </div>
                                                <div class="doc-item">
                                                    <span class="doc-name">Student ID Doc:</span>
                                                    <span class="badge ${app.studentAadharStatus == 'Uploaded' ? 'badge-uploaded' : 'badge-missing'}">
                                                        ${app.studentAadharStatus == 'Uploaded' ? '✓ Uploaded' : '✕ Missing'}
                                                    </span>
                                                </div>
                                            </div>
                                        </div>

                                        <%-- Actions Section --%>
                                        <div class="action-section">
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
                            <td colspan="6" style="text-align: center; padding: 24px; color: var(--slds-text-secondary);">
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