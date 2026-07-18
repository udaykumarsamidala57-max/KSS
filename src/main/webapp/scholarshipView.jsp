<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="com.Bean.ScholarshipBean"%>

<%
ScholarshipBean bean = (ScholarshipBean) request.getAttribute("bean");
%>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Scholarship Application Details</title>

<%@ include file="header.jsp"%>

<style>
body{
    font-family: Arial, Helvetica, sans-serif;
    background:#f5f5f5;
    margin:0;
}

.container{
    width:90%;
    max-width:1100px;
    margin:30px auto;
    background:#fff;
    border-radius:8px;
    box-shadow:0 2px 8px rgba(0,0,0,.2);
    overflow:hidden;
}

.header{
    background:#7a1f35;
    color:#fff;
    padding:15px 20px;
}

.header h2{
    margin:0;
}

table{
    width:100%;
    border-collapse:collapse;
    margin-bottom: 20px;
}

th{
    width:35%;
    background:#f8f8f8;
    text-align:left;
    padding:12px;
    border:1px solid #ddd;
}

td{
    padding:12px;
    border:1px solid #ddd;
}

tr:nth-child(even){
    background:#fafafa;
}

.buttons{
    text-align:center;
    padding:20px;
}

.btn{
    background:#7a1f35;
    color:white;
    text-decoration:none;
    padding:10px 20px;
    border-radius:5px;
    border: none;
    cursor: pointer;
    font-size: 14px;
}

.btn:hover{
    background:#5d1728;
}

.error{
    text-align:center;
    color:red;
    font-size:18px;
    padding:40px;
}

.section{
    background:#eeeeee;
    font-weight:bold;
    color:#7a1f35;
    font-size:15px;
}

/* Document Status Styles */
.file-container {
    display: flex;
    flex-direction: column;
    gap: 8px;
}

.status-badge {
    display: inline-flex;
    align-items: center;
    align-self: flex-start;
    padding: 4px 10px;
    font-size: 12px;
    font-weight: bold;
    border-radius: 4px;
    text-decoration: none;
}

.status-badge.view {
    background-color: #e2f0d9;
    color: #385723;
    border: 1px solid #a9d18e;
}

.status-badge.view:hover {
    background-color: #c5e0b4;
    cursor: pointer;
}

.status-badge.none {
    background-color: #fff2cc;
    color: #7f6000;
    border: 1px solid #ffd966;
}
</style>

</head>

<body>

<div class="container">

<div class="header">
    <h2>Scholarship Application Details</h2>
</div>

<%
if(bean == null){
%>

<div class="error">
    Record Not Found.
</div>

<div class="buttons">
    <a href="ScholarshipListServelt" class="btn">Back to List</a>
</div>

<%
}else{
%>

    <table>
        <tr class="section">
            <td colspan="2">Employee Details</td>
        </tr>
        <tr>
            <th>ID</th>
            <td><%=bean.getId()%></td>
        </tr>
        <tr>
            <th>Organization</th>
            <td><%=bean.getOrgName()%></td>
        </tr>
        <tr>
            <th>Employee No</th>
            <td><%=bean.getEmpNo()%></td>
        </tr>
        <tr>
            <th>Employee Name</th>
            <td><%=bean.getEmpName()%></td>
        </tr>
        <tr>
            <th>Designation</th>
            <td><%=bean.getDesignation()%></td>
        </tr>
        <tr>
            <th>Spouse Working in SMIORE</th>
            <td><%=bean.getSpouseWorkingSMIORE()%></td>
        </tr>
        <tr>
            <th>Spouse Working in Group Company</th>
            <td><%=bean.getSpouseWorkingGroupCompanies()%></td>
        </tr>

        <tr class="section">
            <td colspan="2">Student Details</td>
        </tr>
        <tr>
            <th>Child Name</th>
            <td><%=bean.getChildrenName()%></td>
        </tr>
        <tr>
            <th>Date of Birth</th>
            <td><%=bean.getDob()%></td>
        </tr>
        <tr>
            <th>Gender</th>
            <td><%=bean.getGender()%></td>
        </tr>
        <tr>
            <th>Relationship</th>
            <td><%=bean.getRelationship()%></td>
        </tr>
        <tr>
            <th>Child Order</th>
            <td><%=bean.getChildOrder()%></td>
        </tr>

        <tr class="section">
            <td colspan="2">Academic Details</td>
        </tr>
        <tr>
            <th>College Name</th>
            <td><%=bean.getCollegeName()%></td>
        </tr>
        <tr>
            <th>Course</th>
            <td><%=bean.getCourse()%></td>
        </tr>
        <tr>
            <th>Present Year</th>
            <td><%=bean.getPresentYear()%></td>
        </tr>
        <tr>
            <th>Previous AY Percentage</th>
            <td><%=bean.getPreviousAyPercentage()%></td>
        </tr>
        <tr>
            <th>Fee Amount (Current AY)</th>
            <td><%=bean.getFeeAmountCurrentAy()%></td>
        </tr>

        <tr class="section">
            <td colspan="2">Bank Details</td>
        </tr>
        <tr>
            <th>Name as per Passbook</th>
            <td><%=bean.getEmployeeNamePassbook()%></td>
        </tr>
        <tr>
            <th>Bank Account Number</th>
            <td><%=bean.getBankAccountNo()%></td>
        </tr>
        <tr>
            <th>IFSC Code</th>
            <td><%=bean.getIfscCode()%></td>
        </tr>
        <tr>
            <th>Bank Name</th>
            <td><%=bean.getBankName()%></td>
        </tr>
        <tr>
            <th>Branch Name</th>
            <td><%=bean.getBranchName()%></td>
        </tr>
    </table>

    <form action="ScholarshipDocumentUploadServlet" method="post" enctype="multipart/form-data">
        <input type="hidden" name="id" value="<%=bean.getId()%>">
        
        <table>
            <tr class="section">
                <td colspan="2">Documents Upload</td>
            </tr>

            <tr>
                <th>Previous AY Marks Card</th>
                <td>
                    <div class="file-container">
                        <% if(bean.getPreviousAyMarksCard() != null) { %>
                            <a href="ScholarshipDocumentDownloadServlet?id=<%=bean.getId()%>&field=previousAyMarksCard" target="_blank" class="status-badge view">✓ View Document</a>
                        <% } else { %>
                            <span class="status-badge none">⚠ No file uploaded yet</span>
                        <% } %>
                        <input type="file" name="previousAyMarksCard" accept=".pdf,.jpg,.jpeg,.png">
                    </div>
                </td>
            </tr>

            <tr>
                <th>KSS Application</th>
                <td>
                    <div class="file-container">
                        <% if(bean.getKssApplication() != null) { %>
                            <a href="ScholarshipDocumentDownloadServlet?id=<%=bean.getId()%>&field=kssApplication" target="_blank" class="status-badge view">✓ View Document</a>
                        <% } else { %>
                            <span class="status-badge none">⚠ No file uploaded yet</span>
                        <% } %>
                        <input type="file" name="kssApplication" accept=".pdf,.jpg,.jpeg,.png">
                    </div>
                </td>
            </tr>

            <tr>
                <th>Fee Structure</th>
                <td>
                    <div class="file-container">
                        <% if(bean.getFeeStructure() != null) { %>
                            <a href="ScholarshipDocumentDownloadServlet?id=<%=bean.getId()%>&field=feeStructure" target="_blank" class="status-badge view">✓ View Document</a>
                        <% } else { %>
                            <span class="status-badge none">⚠ No file uploaded yet</span>
                        <% } %>
                        <input type="file" name="feeStructure" accept=".pdf,.jpg,.jpeg,.png">
                    </div>
                </td>
            </tr>

            <tr>
                <th>Fee Receipts</th>
                <td>
                    <div class="file-container">
                        <% if(bean.getFeeReceipts() != null) { %>
                            <a href="ScholarshipDocumentDownloadServlet?id=<%=bean.getId()%>&field=feeReceipts" target="_blank" class="status-badge view">✓ View Document</a>
                        <% } else { %>
                            <span class="status-badge none">⚠ No file uploaded yet</span>
                        <% } %>
                        <input type="file" name="feeReceipts" accept=".pdf,.jpg,.jpeg,.png">
                    </div>
                </td>
            </tr>

            <tr>
                <th>Parent Aadhaar Copy</th>
                <td>
                    <div class="file-container">
                        <% if(bean.getParentAadharCopy() != null) { %>
                            <a href="ScholarshipDocumentDownloadServlet?id=<%=bean.getId()%>&field=parentAadharCopy" target="_blank" class="status-badge view">✓ View Document</a>
                        <% } else { %>
                            <span class="status-badge none">⚠ No file uploaded yet</span>
                        <% } %>
                        <input type="file" name="parentAadharCopy" accept=".pdf,.jpg,.jpeg,.png">
                    </div>
                </td>
            </tr>

            <tr>
                <th>Student Aadhaar Copy</th>
                <td>
                    <div class="file-container">
                        <% if(bean.getStudentAadharCopy() != null) { %>
                            <a href="ScholarshipDocumentDownloadServlet?id=<%=bean.getId()%>&field=studentAadharCopy" target="_blank" class="status-badge view">✓ View Document</a>
                        <% } else { %>
                            <span class="status-badge none">⚠ No file uploaded yet</span>
                        <% } %>
                        <input type="file" name="studentAadharCopy" accept=".pdf,.jpg,.jpeg,.png">
                    </div>
                </td>
            </tr>

            <tr>
                <th>Bank Passbook First Page</th>
                <td>
                    <div class="file-container">
                        <% if(bean.getBankPassbookFirstPage() != null) { %>
                            <a href="ScholarshipDocumentDownloadServlet?id=<%=bean.getId()%>&field=bankPassbookFirstPage" target="_blank" class="status-badge view">✓ View Document</a>
                        <% } else { %>
                            <span class="status-badge none">⚠ No file uploaded yet</span>
                        <% } %>
                        <input type="file" name="bankPassbookFirstPage" accept=".pdf,.jpg,.jpeg,.png">
                    </div>
                </td>
            </tr>

            <tr>
                <td colspan="2" style="text-align:center; padding: 20px;">
                    <input type="submit" value="Upload Documents" class="btn">
                </td>
            </tr>
        </table>
    </form>

    <div class="buttons">
        <a href="ScholarshipListServelt" class="btn">Back to List</a>
    </div>

<%
}
%>

</div>

</body>
</html>