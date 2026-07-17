<%@page import="java.util.List"%>
<%@page import="com.Bean.ScholarshipBean"%>

<%
List<ScholarshipBean> list = (List<ScholarshipBean>) request.getAttribute("list");
%>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Scholarship List</title>

<style>

body{
    font-family:Arial;
    background:#f5f5f5;
    margin:20px;
}

.container{
    width:98%;
    margin:auto;
    background:#fff;
    padding:20px;
    box-shadow:0px 0px 5px #ccc;
}

table{
    width:100%;
    border-collapse:collapse;
}

table th,table td{
    border:1px solid #ddd;
    padding:8px;
    text-align:center;
}

table th{
    background:#007bff;
    color:white;
}

.btnAdd{
    background:green;
    color:white;
    padding:8px 15px;
    text-decoration:none;
    border-radius:4px;
}

.btnEdit{
    background:#ffc107;
    color:black;
    padding:5px 10px;
    text-decoration:none;
    border-radius:4px;
}

.btnDelete{
    background:red;
    color:white;
    padding:5px 10px;
    text-decoration:none;
    border-radius:4px;
}

</style>

</head>

<body>

<div class="container">

<h2 align="center">Scholarship Applications</h2>

<p align="right">
<a href="scholarship.jsp" class="btnAdd">Add New Application</a>
</p>

<table>

<tr>
    <th>ID</th>
    <th>Organization</th>
    <th>Emp No</th>
    <th>Employee Name</th>
    <th>Student Name</th>
    <th>College</th>
    <th>Course</th>
    <th>Fee Amount</th>
    <th>Action</th>
</tr>

<%

if(list!=null){

for(ScholarshipBean bean:list){

%>

<tr>

<td><%=bean.getId()%></td>

<td><%=bean.getOrgName()%></td>

<td><%=bean.getEmpNo()%></td>

<td><%=bean.getEmpName()%></td>

<td><%=bean.getChildrenName()%></td>

<td><%=bean.getCollegeName()%></td>

<td><%=bean.getCourse()%></td>

<td><%=bean.getFeeAmountCurrentAy()%></td>

<td>

<a class="btnEdit"
href="ScholarshipListServelt?action=edit&id=<%=bean.getId()%>">
Edit
</a>

&nbsp;

<a class="btnDelete"
href="ScholarshipListServelt?action=delete&id=<%=bean.getId()%>"
onclick="return confirm('Are you sure you want to delete this record?');">
Delete
</a>

</td>

</tr>

<%
}
}
else{
%>

<tr>
<td colspan="9">No Records Found</td>
</tr>

<%
}
%>

</table>

</div>

</body>
</html>