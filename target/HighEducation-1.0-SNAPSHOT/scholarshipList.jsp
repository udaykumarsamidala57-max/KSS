<%@page import="java.util.List"%>
<%@page import="com.Bean.ScholarshipBean"%>
<%
    
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    %>
<%
List<ScholarshipBean> list = (List<ScholarshipBean>) request.getAttribute("list");
%>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Scholarship Applications - Master List</title>

<!-- INCLUDE SHARED HEADER & MENU -->
<%@ include file="header.jsp" %>

<style>
  :root {
    --primary-color: #7a1f35;
    --primary-hover: #5e1627;
    --accent-bg: #fdf6f7;
    --border-color: #e2cece;
    --text-main: #2b2b2b;
    --text-muted: #666666;
  }

  body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    background-color: #f4f6f8;
    margin: 0;
    padding: 24px 12px;
    color: var(--text-main);
  }

  .container {
    width: 100%;
    max-width: 1600px;
    margin: 0 auto 20px auto;
    background: #ffffff;
    border-radius: 8px;
    box-shadow: 0 4px 16px rgba(0, 0, 0, 0.04);
    border: 1px solid var(--border-color);
    overflow: hidden;
  }

  .page-title-bar {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 20px 24px;
    background-color: var(--primary-color);
    border-bottom: 1px solid var(--primary-hover);
    color: #ffffff;
  }

  .page-title-bar h2 {
    margin: 0;
    font-size: 18px;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.8px;
    color: #ffffff;
  }

  .btn-add {
    background-color: #ffffff;
    color: var(--primary-color);
    padding: 8px 16px;
    text-decoration: none;
    font-size: 11px;
    font-weight: 700;
    border-radius: 4px;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    transition: background-color 0.2s ease;
    display: inline-block;
    border: 1px solid transparent;
  }

  .btn-add:hover {
    background-color: var(--accent-bg);
  }

  .table-responsive {
    padding: 24px;
    overflow-x: auto;
  }

  .data-table {
    width: 100%;
    border-collapse: separate;
    border-spacing: 0;
    font-size: 13px;
    white-space: nowrap;
    border: 1px solid var(--border-color);
    border-radius: 4px;
    overflow: hidden;
  }

  .data-table th {
    background-color: var(--primary-color);
    color: #ffffff;
    font-weight: 600;
    text-transform: uppercase;
    font-size: 11px;
    letter-spacing: 0.5px;
    padding: 12px 14px;
    text-align: left;
    border-bottom: 2px solid var(--primary-hover);
    border-right: 1px solid rgba(255, 255, 255, 0.15);
    position: sticky;
    top: 0;
    z-index: 2;
  }

  .data-table td {
    padding: 12px 14px;
    border-bottom: 1px solid var(--border-color);
    border-right: 1px solid var(--border-color);
    color: var(--text-main);
    vertical-align: middle;
  }
  
  .data-table tr:last-child td {
    border-bottom: none;
  }

  .data-table td:last-child, 
  .data-table th:last-child {
    border-right: none;
  }

  .data-table td:first-child, 
  .data-table th:first-child {
    position: sticky;
    left: 0;
    background-color: #ffffff;
    z-index: 1;
    box-shadow: 2px 0 5px rgba(0, 0, 0, 0.02);
  }

  .data-table th:first-child {
    background-color: var(--primary-color);
    z-index: 3;
  }

  .data-table td:last-child,
  .data-table th:last-child {
    position: sticky;
    right: 0;
    background-color: #ffffff;
    z-index: 1;
    box-shadow: -2px 0 5px rgba(0, 0, 0, 0.02);
  }

  .data-table th:last-child {
    background-color: var(--primary-color);
    z-index: 3;
  }

  .data-table tr:nth-child(even) td { 
    background-color: #fafbfc; 
  }
  
  .data-table tr:nth-child(even) td:first-child,
  .data-table tr:nth-child(even) td:last-child { 
    background-color: #fafbfc; 
  }

  .data-table tr:hover td { 
    background-color: var(--accent-bg); 
  }

  .data-table tr:hover td:first-child,
  .data-table tr:hover td:last-child { 
    background-color: var(--accent-bg); 
  }

  .action-cell {
    display: flex;
    gap: 6px;
    justify-content: center;
    align-items: center;
  }

  .btn-action {
    text-decoration: none;
    font-weight: 500;
    font-size: 12px;
    padding: 5px 12px;
    border-radius: 4px;
    border: 1px solid var(--border-color);
    cursor: pointer;
    background-color: #ffffff;
    transition: all 0.15s ease;
    display: inline-block;
  }

  .btn-view {
    color: #17a2b8;
    border-color: #bee5eb;
  }
  
  .btn-view:hover {
    background-color: #e2f0d9;
    border-color: #17a2b8;
  }

  .btn-edit {
    color: var(--text-main);
    border-color: var(--border-color);
  }

  .btn-edit:hover {
    background-color: #f4f6f8;
    border-color: #999;
  }

  .btn-delete {
    color: #c0392b;
    border-color: #f5c6cb;
  }

  .btn-delete:hover {
    background-color: #fce8e6;
    border-color: #c0392b;
  }

  /* MODAL MODIFICATIONS TO MATCH PICTURE DIALOG INPUTS */
  .modal-overlay {
    display: none;
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background-color: rgba(0, 0, 0, 0.4);
    backdrop-filter: blur(1px);
    z-index: 1000;
    justify-content: center;
    align-items: center;
  }

  .modal-card {
    background: #ffffff;
    width: 92%;
    max-width: 950px;
    max-height: 90vh;
    border-radius: 6px;
    box-shadow: 0 8px 30px rgba(0, 0, 0, 0.15);
    border: 1px solid var(--border-color);
    overflow: hidden;
    display: flex;
    flex-direction: column;
    animation: fadeIn 0.15s ease-out;
  }

  .modal-card form {
    display: flex;
    flex-direction: column;
    height: 100%;
    min-height: 0;
    margin: 0;
  }

  @keyframes fadeIn {
    from { opacity: 0; transform: scale(0.98); }
    to { opacity: 1; transform: scale(1); }
  }

  .modal-header {
    background: var(--primary-color);
    color: #ffffff;
    padding: 16px 24px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    flex-shrink: 0;
  }

  .modal-header h3 {
    margin: 0;
    font-size: 16px;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.6px;
  }

  .modal-close {
    background: none;
    border: none;
    color: #ffffff;
    font-size: 24px;
    line-height: 1;
    cursor: pointer;
    opacity: 0.8;
  }

  .modal-close:hover { opacity: 1; }

  .modal-body {
    padding: 24px;
    overflow-y: auto;
    flex: 1 1 auto;
  }

  .modal-section-title {
    background-color: var(--accent-bg);
    color: var(--primary-color);
    padding: 8px 14px;
    font-size: 12px;
    font-weight: 700;
    border-left: 4px solid var(--primary-color);
    margin: 24px 0 16px 0;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    border-radius: 0 4px 4px 0;
  }

  .modal-section-title:first-of-type {
    margin-top: 0;
  }

  .modal-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
    gap: 16px 20px;
  }

  .modal-grid > .modal-group.full-width {
    grid-column: 1 / -1;
  }

  .modal-group {
    display: flex;
    flex-direction: column;
  }

  .modal-group label {
    font-size: 13px;
    font-weight: 600;
    color: var(--text-main);
    margin-bottom: 6px;
  }

  .modal-group input,
  .modal-group select {
    width: 100%;
    padding: 8px 12px;
    font-size: 13px;
    height: 38px;
    border: 1px solid var(--border-color);
    border-radius: 4px;
    outline: none;
    box-sizing: border-box;
    color: var(--text-main);
    transition: border-color 0.2s;
  }

  .modal-group input:focus,
  .modal-group select:focus {
    border-color: var(--primary-color);
  }

  .modal-group input[readonly] {
    background-color: #f4f6f8;
    color: var(--text-muted);
    cursor: not-allowed;
  }

  .modal-footer {
    padding: 16px 24px;
    background-color: #fafbfc;
    border-top: 1px solid var(--border-color);
    display: flex;
    justify-content: flex-end;
    gap: 12px;
    flex-shrink: 0;
  }

  .btn-save {
    background-color: var(--primary-color);
    color: #ffffff;
    border: none;
    padding: 10px 24px;
    font-size: 12px;
    font-weight: 700;
    text-transform: uppercase;
    border-radius: 4px;
    cursor: pointer;
    letter-spacing: 0.5px;
    transition: background-color 0.2s;
  }

  .btn-save:hover { background-color: var(--primary-hover); }

  .btn-cancel {
    background-color: #ffffff;
    color: var(--text-main);
    border: 1px solid var(--border-color);
    padding: 10px 20px;
    font-size: 12px;
    font-weight: 600;
    text-transform: uppercase;
    border-radius: 4px;
    cursor: pointer;
    letter-spacing: 0.5px;
  }

  .btn-cancel:hover { background-color: #f4f6f8; }
</style>
</head>

<body>

<%!
  public String escapeJs(String str) {
      if (str == null) return "";
      return str.replace("\\", "\\\\")
                .replace("'", "\\'")
                .replace("\"", "\\\"")
                .replace("\r", "")
                .replace("\n", " ");
  }
%>

<div class="container">

  <div class="page-title-bar">
    <h2>Scholarship Applications Master List</h2>
    <a href="ScholarshipApplication.jsp" class="btn-add">+ Add New Application</a>
  </div>

  <div class="table-responsive">
    <table class="data-table">
      <thead>
        <tr>
          <th>ID</th>
          <th>Organization</th>
          <th>Emp No</th>
          <th>Emp Name</th>
          <th>Designation</th>
          <th>Spouse SMIORE</th>
          <th>Spouse Group</th>
          <th>Child Name</th>
          <th>DOB</th>
          <th>Gender</th>
          <th>Relation</th>
          <th>Child Order</th>
          <th>College Name</th>
          <th>Course</th>
          <th style="text-align: center;">Actions</th>
        </tr>
      </thead>
      <tbody>
<%
if(list != null && !list.isEmpty()){
    for(ScholarshipBean bean : list){
%>
        <tr>
          <td><%=bean.getId()%></td>
          <td><%=bean.getOrgName() != null ? bean.getOrgName() : ""%></td>
          <td><strong><%=bean.getEmpNo() != null ? bean.getEmpNo() : ""%></strong></td>
          <td><strong><%=bean.getEmpName() != null ? bean.getEmpName() : ""%></strong></td>
          <td><%=bean.getDesignation() != null ? bean.getDesignation() : ""%></td>
          <td><%=bean.getSpouseWorkingSMIORE() != null ? bean.getSpouseWorkingSMIORE() : ""%></td>
          <td><%=bean.getSpouseWorkingGroupCompanies() != null ? bean.getSpouseWorkingGroupCompanies() : ""%></td>
          <td><%=bean.getChildrenName() != null ? bean.getChildrenName() : ""%></td>
          <td><%=bean.getDob() != null ? bean.getDob() : ""%></td>
          <td><%=bean.getGender() != null ? bean.getGender() : ""%></td>
          <td><%=bean.getRelationship() != null ? bean.getRelationship() : ""%></td>
          <td><%=bean.getChildOrder() != null ? bean.getChildOrder() : ""%></td>
          <td><%=bean.getCollegeName() != null ? bean.getCollegeName() : ""%></td>
          <td><%=bean.getCourse() != null ? bean.getCourse() : ""%></td>
       
          <td class="action-cell">
            <a href="ScholarshipViewServlet?id=<%=bean.getId()%>" class="btn-action btn-view">View</a>

            <button type="button" class="btn-action btn-edit"
                onclick="openEditModal(
                '<%=bean.getId()%>',
                '<%=escapeJs(bean.getOrgName())%>',
                '<%=escapeJs(bean.getEmpNo())%>',
                '<%=escapeJs(bean.getEmpName())%>',
                '<%=escapeJs(bean.getDesignation())%>',
                '<%=escapeJs(bean.getSpouseWorkingSMIORE())%>',
                '<%=escapeJs(bean.getSpouseWorkingGroupCompanies())%>',
                '<%=escapeJs(bean.getChildrenName())%>',
                '<%=escapeJs(bean.getDob())%>',
                '<%=escapeJs(bean.getGender())%>',
                '<%=escapeJs(bean.getRelationship())%>',
                '<%=escapeJs(bean.getChildOrder())%>',
                '<%=escapeJs(bean.getCollegeName())%>',
                '<%=escapeJs(bean.getCourse())%>',
                '<%=escapeJs(bean.getPresentYear())%>',
                '<%=bean.getPreviousAyPercentage()%>',
                '<%=bean.getFeeAmountCurrentAy()%>',
                '<%=escapeJs(bean.getEmployeeNamePassbook())%>',
                '<%=escapeJs(bean.getBankAccountNo())%>',
                '<%=escapeJs(bean.getIfscCode())%>',
                '<%=escapeJs(bean.getBankName())%>',
                '<%=escapeJs(bean.getBranchName())%>'
                )">
                Edit
            </button>

            <a class="btn-action btn-delete"
               href="ScholarshipListServelt?action=delete&id=<%=bean.getId()%>"
               onclick="return confirm('Are you sure you want to delete this record?');">
                Delete
            </a>
          </td>
        </tr>
<%
    }
} else {
%>
        <tr>
          <td colspan="15" style="text-align: center; color: var(--text-muted); padding: 40px;">No Applications Found</td>
        </tr>
<%
}
%>
      </tbody>
    </table>
  </div>

</div>

<!-- EDIT POPUP MODAL -->
<div id="editModal" class="modal-overlay">
  <div class="modal-card">
    
    <div class="modal-header">
      <h3>Edit Scholarship Application</h3>
      <button type="button" class="modal-close" onclick="closeEditModal()">&times;</button>
    </div>

    <form action="ScholarshipListServelt" method="post">
      <input type="hidden" name="action" value="update">
      <input type="hidden" id="edit_id" name="id">

      <div class="modal-body">
        
        <div class="modal-section-title">1. Employee Details</div>
        <div class="modal-grid">
          <div class="modal-group full-width">
            <label for="edit_orgName">Organization Name *</label>
            <input type="text" id="edit_orgName" name="orgName" required>
          </div>

          <div class="modal-group">
            <label for="edit_empNo">Employee No *</label>
            <input type="text" id="edit_empNo" name="empNo" required>
          </div>

          <div class="modal-group">
            <label for="edit_empName">Employee Name *</label>
            <input type="text" id="edit_empName" name="empName" required>
          </div>

          <div class="modal-group">
            <label for="edit_designation">Designation</label>
            <input type="text" id="edit_designation" name="designation">
          </div>

          <div class="modal-group">
            <label for="edit_spouseWorkingSMIORE">Spouse Working in SMIORE? *</label>
            <select id="edit_spouseWorkingSMIORE" name="spouseWorkingSMIORE">
              <option value="No">No</option>
              <option value="Yes">Yes</option>
            </select>
          </div>

          <div class="modal-group">
            <label for="edit_spouseWorkingGroupCompanies">Spouse Working in Group Co.? *</label>
            <select id="edit_spouseWorkingGroupCompanies" name="spouseWorkingGroupCompanies">
              <option value="No">No</option>
              <option value="Yes">Yes</option>
            </select>
          </div>
        </div>

        <div class="modal-section-title">2. Child / Student Details</div>
        <div class="modal-grid">
          <div class="modal-group">
            <label for="edit_childrenName">Child's Name</label>
            <input type="text" id="edit_childrenName" name="childrenName">
          </div>

          <div class="modal-group">
            <label for="edit_dob">Date of Birth</label>
            <input type="date" id="edit_dob" name="dob" onchange="calculateModalAge()">
          </div>

          <div class="modal-group">
            <label for="edit_age">Calculated Age</label>
            <input type="text" id="edit_age" readonly>
          </div>

          <div class="modal-group">
            <label for="edit_gender">Gender</label>
            <select id="edit_gender" name="gender">
              <option value="">Select Gender</option>
              <option value="Male">Male</option>
              <option value="Female">Female</option>
              <option value="Other">Other</option>
            </select>
          </div>

          <div class="modal-group">
            <label for="edit_relationship">Relationship</label>
            <input type="text" id="edit_relationship" name="relationship">
          </div>

          <div class="modal-group">
            <label for="edit_childOrder">Child Order</label>
            <select id="edit_childOrder" name="childOrder">
              <option value="">Select Child Order</option>
              <option value="First">First Child</option>
              <option value="Second">Second Child</option>
            </select>
          </div>
        </div>

        <div class="modal-section-title">3. Academic Details</div>
        <div class="modal-grid">
          <div class="modal-group full-width">
            <label for="edit_collegeName">College Name</label>
            <input type="text" id="edit_collegeName" name="collegeName">
          </div>

          <div class="modal-group">
            <label for="edit_course">Course Name</label>
            <input type="text" id="edit_course" name="course">
          </div>

          <div class="modal-group">
            <label for="edit_presentYear">Present Year</label>
            <input type="text" id="edit_presentYear" name="presentYear">
          </div>

          <div class="modal-group">
            <label for="edit_previousAyPercentage">Prev AY Percentage (%)</label>
            <input type="number" step="0.01" id="edit_previousAyPercentage" name="previousAyPercentage">
          </div>

          <div class="modal-group">
            <label for="edit_feeAmountCurrentAy">Fee Amount for Current AY</label>
            <input type="number" step="0.01" id="edit_feeAmountCurrentAy" name="feeAmountCurrentAy">
          </div>
        </div>

        <div class="modal-section-title">4. Bank Account Details</div>
        <div class="modal-grid">
          <div class="modal-group full-width">
            <label for="edit_employeeNamePassbook">Name as per Passbook</label>
            <input type="text" id="edit_employeeNamePassbook" name="employeeNamePassbook">
          </div>

          <div class="modal-group">
            <label for="edit_bankAccountNo">Bank Account Number</label>
            <input type="text" id="edit_bankAccountNo" name="bankAccountNo">
          </div>

          <div class="modal-group">
            <label for="edit_ifscCode">IFSC Code</label>
            <input type="text" id="edit_ifscCode" name="ifscCode">
          </div>

          <div class="modal-group">
            <label for="edit_bankName">Bank Name</label>
            <input type="text" id="edit_bankName" name="bankName">
          </div>

          <div class="modal-group">
            <label for="edit_branchName">Branch Name</label>
            <input type="text" id="edit_branchName" name="branchName">
          </div>
        </div>

      </div>

      <div class="modal-footer">
        <button type="button" class="btn-cancel" onclick="closeEditModal()">Cancel</button>
        <button type="submit" class="btn-save">Update Application</button>
      </div>
    </form>

  </div>
</div>

<script>
  function openEditModal(
    id, orgName, empNo, empName, designation, spouseSMIORE, spouseGroup,
    childrenName, dob, gender, relationship, childOrder,
    collegeName, course, presentYear, previousAyPercentage, feeAmountCurrentAy,
    employeeNamePassbook, bankAccountNo, ifscCode, bankName, branchName
  ) {
    document.getElementById('edit_id').value = id;
    document.getElementById('edit_orgName').value = orgName;
    document.getElementById('edit_empNo').value = empNo;
    document.getElementById('edit_empName').value = empName;
    document.getElementById('edit_designation').value = designation;
    document.getElementById('edit_spouseWorkingSMIORE').value = spouseSMIORE || "No";
    document.getElementById('edit_spouseWorkingGroupCompanies').value = spouseGroup || "No";

    document.getElementById('edit_childrenName').value = childrenName;
    document.getElementById('edit_dob').value = dob;
    document.getElementById('edit_gender').value = gender;
    document.getElementById('edit_relationship').value = relationship;
    document.getElementById('edit_childOrder').value = childOrder;

    document.getElementById('edit_collegeName').value = collegeName;
    document.getElementById('edit_course').value = course;
    document.getElementById('edit_presentYear').value = presentYear;
    document.getElementById('edit_previousAyPercentage').value = previousAyPercentage;
    document.getElementById('edit_feeAmountCurrentAy').value = feeAmountCurrentAy;

    document.getElementById('edit_employeeNamePassbook').value = employeeNamePassbook;
    document.getElementById('edit_bankAccountNo').value = bankAccountNo;
    document.getElementById('edit_ifscCode').value = ifscCode;
    document.getElementById('edit_bankName').value = bankName;
    document.getElementById('edit_branchName').value = branchName;

    calculateModalAge();
    document.getElementById('editModal').style.display = 'flex';
  }

  function closeEditModal() {
    document.getElementById('editModal').style.display = 'none';
  }

  function calculateModalAge() {
    const dobInput = document.getElementById('edit_dob').value;
    const ageInput = document.getElementById('edit_age');

    if (!dobInput) {
      ageInput.value = '';
      return;
    }

    const birthDate = new Date(dobInput);
    const today = new Date();

    if (isNaN(birthDate.getTime())) {
      ageInput.value = '';
      return;
    }

    let age = today.getFullYear() - birthDate.getFullYear();
    const monthDiff = today.getMonth() - birthDate.getMonth();

    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birthDate.getDate())) {
      age--;
    }

    if (age < 0) {
      ageInput.value = 'Invalid DOB';
    } else {
      ageInput.value = age + (age === 1 ? ' year old' : ' years old');
    }
  }

  window.onclick = function(event) {
    const modal = document.getElementById('editModal');
    if (event.target === modal) {
      closeEditModal();
    }
  };
</script>

</body>
</html>