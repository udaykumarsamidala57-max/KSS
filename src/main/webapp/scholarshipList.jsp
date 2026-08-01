<%@page import="java.util.List"%>
<%@page import="com.Bean.ScholarshipBean"%>
<%
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    String users = (String) sess.getAttribute("username");
    String roles = (String) sess.getAttribute("role");
    String depts = (String) sess.getAttribute("department");
%>
<%
List<ScholarshipBean> list = (List<ScholarshipBean>) request.getAttribute("list");
%>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Scholarship Application</title>

<!-- INCLUDE SHARED HEADER & MENU -->
<%@ include file="header.jsp" %>

<style>
  /* Salesforce Lightning Design System (SLDS) Theme Variables */
  :root {
    --slds-brand: #0176d3;
    --slds-brand-hover: #014486;
    --slds-bg-page: #f3f5f8;
    --slds-card-bg: #ffffff;
    --slds-border: #dddbda;
    --slds-border-dark: #c9c7c5;
    --slds-text-primary: #080707;
    --slds-text-secondary: #444444;
    --slds-text-label: #514f4d;
    --slds-table-header-bg: #fafaf9;
    --slds-table-hover: #f3f3f3;
    --slds-radius: 4px;
    --slds-focus-ring: 0 0 0 2px #ffffff, 0 0 0 4px #0176d3;
  }

  body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    background-color: var(--slds-bg-page);
    margin: 0;
    padding: 16px 20px 80px 20px;
    color: var(--slds-text-primary);
  }

  .slds-container {
    max-width: 1600px;
    margin: 0 auto;
  }

  /* Salesforce Page Header / Title Component */
  .slds-page-header {
    background-color: var(--slds-card-bg);
    border: 1px solid var(--slds-border);
    border-radius: var(--slds-radius);
    padding: 16px 24px;
    margin-bottom: 16px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    box-shadow: 0 2px 2px 0 rgba(0, 0, 0, 0.1);
  }

  .slds-header-title-wrapper {
    display: flex;
    align-items: center;
    gap: 12px;
  }

 

  .slds-header-details {
    display: flex;
    flex-direction: column;
  }

  .slds-header-subtitle {
    font-size: 11px;
    font-weight: 600;
    text-transform: uppercase;
    color: var(--slds-text-secondary);
    letter-spacing: 0.5px;
  }

  .slds-header-title {
    margin: 2px 0 0 0;
    font-size: 20px;
    font-weight: 700;
    color: var(--slds-text-primary);
    line-height: 1.2;
  }

  /* Salesforce Standard Buttons */
  .slds-btn {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    padding: 0 16px;
    height: 32px;
    font-size: 13px;
    font-weight: 600;
    border-radius: var(--slds-radius);
    text-decoration: none;
    cursor: pointer;
    transition: all 0.15s ease-in-out;
    border: 1px solid transparent;
    line-height: 1;
    box-sizing: border-box;
  }

  .slds-btn-brand {
    background-color: var(--slds-brand);
    color: #ffffff;
    border-color: var(--slds-brand);
  }

  .slds-btn-brand:hover {
    background-color: var(--slds-brand-hover);
    border-color: var(--slds-brand-hover);
    color: #ffffff;
  }

  .slds-btn-neutral {
    background-color: #ffffff;
    color: var(--slds-brand);
    border-color: var(--slds-border);
  }

  .slds-btn-neutral:hover {
    background-color: #f4f6f9;
    border-color: var(--slds-border-dark);
    color: var(--slds-brand-hover);
  }

  .slds-btn-danger {
    background-color: #ffffff;
    color: #ea001e;
    border-color: var(--slds-border);
  }

  .slds-btn-danger:hover {
    background-color: #fef1f2;
    border-color: #ea001e;
  }

  /* Salesforce Card & Datatable Wrapper */
  .slds-card {
    background: var(--slds-card-bg);
    border: 1px solid var(--slds-border);
    border-radius: var(--slds-radius);
    box-shadow: 0 2px 2px 0 rgba(0, 0, 0, 0.1);
    overflow: hidden;
  }

  .table-responsive {
    width: 100%;
    overflow-x: auto;
  }

  .slds-data-table {
    width: 100%;
    border-collapse: separate;
    border-spacing: 0;
    font-size: 13px;
    white-space: nowrap;
  }

  .slds-data-table th {
    background-color: var(--slds-table-header-bg);
    color: var(--slds-text-label);
    font-weight: 700;
    text-transform: uppercase;
    font-size: 11px;
    letter-spacing: 0.5px;
    padding: 10px 14px;
    text-align: left;
    border-bottom: 1px solid var(--slds-border);
    border-right: 1px solid var(--slds-border);
    position: sticky;
    top: 0;
    z-index: 2;
  }

  .slds-data-table td {
    padding: 10px 14px;
    border-bottom: 1px solid var(--slds-border);
    border-right: 1px solid var(--slds-border);
    color: var(--slds-text-primary);
    vertical-align: middle;
  }

  .slds-data-table tr:last-child td {
    border-bottom: none;
  }

  .slds-data-table td:last-child, 
  .slds-data-table th:last-child {
    border-right: none;
  }

  /* Sticky First and Last Columns */
  .slds-data-table td:first-child, 
  .slds-data-table th:first-child {
    position: sticky;
    left: 0;
    background-color: var(--slds-card-bg);
    z-index: 1;
    box-shadow: 2px 0 4px rgba(0, 0, 0, 0.04);
  }

  .slds-data-table th:first-child {
    background-color: var(--slds-table-header-bg);
    z-index: 3;
  }

  .slds-data-table td:last-child,
  .slds-data-table th:last-child {
    position: sticky;
    right: 0;
    background-color: var(--slds-card-bg);
    z-index: 1;
    box-shadow: -2px 0 4px rgba(0, 0, 0, 0.04);
  }

  .slds-data-table th:last-child {
    background-color: var(--slds-table-header-bg);
    z-index: 3;
  }

  .slds-data-table tr:hover td { 
    background-color: var(--slds-table-hover) !important; 
  }

  .action-cell {
    display: flex;
    gap: 6px;
    justify-content: center;
    align-items: center;
  }

  /* Salesforce Style Modal Panel */
  .slds-modal-overlay {
    display: none;
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background-color: rgba(8, 7, 7, 0.6);
    backdrop-filter: blur(2px);
    z-index: 1000;
    justify-content: center;
    align-items: center;
  }

  .slds-modal-card {
    background: #ffffff;
    width: 90%;
    max-width: 920px;
    max-height: 88vh;
    border-radius: var(--slds-radius);
    box-shadow: 0 8px 24px rgba(0, 0, 0, 0.25);
    overflow: hidden;
    display: flex;
    flex-direction: column;
    animation: modalSlide 0.2s ease-out;
  }

  @keyframes modalSlide {
    from { opacity: 0; transform: translateY(-10px); }
    to { opacity: 1; transform: translateY(0); }
  }

  .slds-modal-card form {
    display: flex;
    flex-direction: column;
    height: 100%;
    min-height: 0;
    margin: 0;
  }

  .slds-modal-header {
    background-color: #fafaf9;
    border-bottom: 1px solid var(--slds-border);
    padding: 16px 24px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    flex-shrink: 0;
  }

  .slds-modal-header h3 {
    margin: 0;
    font-size: 16px;
    font-weight: 700;
    color: var(--slds-text-primary);
  }

  .slds-modal-close {
    background: none;
    border: none;
    color: var(--slds-text-secondary);
    font-size: 22px;
    line-height: 1;
    cursor: pointer;
    border-radius: 4px;
    padding: 2px 8px;
  }

  .slds-modal-close:hover {
    background-color: var(--slds-border);
    color: var(--slds-text-primary);
  }

  .slds-modal-body {
    padding: 20px 24px;
    overflow-y: auto;
    flex: 1 1 auto;
    background-color: #ffffff;
  }

  .slds-section-title {
    background-color: #f3f5f8;
    color: var(--slds-text-primary);
    padding: 8px 12px;
    font-size: 12px;
    font-weight: 700;
    border-left: 3px solid var(--slds-brand);
    margin: 20px 0 16px 0;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    border-radius: 0 2px 2px 0;
  }

  .slds-section-title:first-of-type {
    margin-top: 0;
  }

  .slds-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
    gap: 16px 20px;
  }

  .slds-grid > .slds-form-element.full-width {
    grid-column: 1 / -1;
  }

  .slds-form-element {
    display: flex;
    flex-direction: column;
  }

  .slds-form-element label {
    font-size: 12px;
    font-weight: 600;
    color: var(--slds-text-label);
    margin-bottom: 4px;
  }

  .slds-form-element input,
  .slds-form-element select {
    width: 100%;
    padding: 6px 12px;
    font-size: 13px;
    height: 36px;
    border: 1px solid var(--slds-border);
    border-radius: var(--slds-radius);
    outline: none;
    box-sizing: border-box;
    color: var(--slds-text-primary);
    background-color: #ffffff;
    transition: border-color 0.15s ease, box-shadow 0.15s ease;
  }

  .slds-form-element input:focus,
  .slds-form-element select:focus {
    border-color: var(--slds-brand);
    box-shadow: 0 0 0 1px var(--slds-brand);
  }

  .slds-form-element input[readonly] {
    background-color: #f3f5f8;
    color: var(--slds-text-secondary);
    cursor: not-allowed;
  }

  .slds-modal-footer {
    padding: 14px 24px;
    background-color: #fafaf9;
    border-top: 1px solid var(--slds-border);
    display: flex;
    justify-content: flex-end;
    gap: 12px;
    flex-shrink: 0;
  }
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

<div class="slds-container">

  <!-- SALESFORCE PAGE HEADER BAR -->
  <div class="slds-page-header">
    <div class="slds-header-title-wrapper">
     
      <div class="slds-header-details">
      
        <h1 class="slds-header-title">Applications Master List</h1>
      </div>
    </div>
    <div>
      <a href="ScholarshipApplication.jsp" class="slds-btn slds-btn-brand">+ New Application</a>
    </div>
  </div>

  <!-- DATA TABLE CARD CONTAINER -->
  <div class="slds-card">
    <div class="table-responsive">
      <table class="slds-data-table">
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
              <a href="ScholarshipViewServlet?id=<%=bean.getId()%>" class="slds-btn slds-btn-neutral" style="height:26px; padding:0 10px; font-size:11px;">View</a>

              <button type="button" class="slds-btn slds-btn-neutral" style="height:26px; padding:0 10px; font-size:11px;"
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

              <a class="slds-btn slds-btn-danger" style="height:26px; padding:0 10px; font-size:11px;"
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
            <td colspan="15" style="text-align: center; color: var(--slds-text-secondary); padding: 40px;">No Applications Found</td>
          </tr>
<%
}
%>
        </tbody>
      </table>
    </div>
  </div>

</div>

<!-- SALESFORCE MODAL POPUP -->
<div id="editModal" class="slds-modal-overlay">
  <div class="slds-modal-card">
    
    <div class="slds-modal-header">
      <h3>Edit Scholarship Application</h3>
      <button type="button" class="slds-modal-close" onclick="closeEditModal()">&times;</button>
    </div>

    <form action="ScholarshipListServelt" method="post">
      <input type="hidden" name="action" value="update">
      <input type="hidden" id="edit_id" name="id">

      <div class="slds-modal-body">
        
        <div class="slds-section-title">1. Employee Details</div>
        <div class="slds-grid">
          <div class="slds-form-element full-width">
            <label for="edit_orgName">Organization Name *</label>
            <input type="text" id="edit_orgName" name="orgName" required>
          </div>

          <div class="slds-form-element">
            <label for="edit_empNo">Employee No *</label>
            <input type="text" id="edit_empNo" name="empNo" required>
          </div>

          <div class="slds-form-element">
            <label for="edit_empName">Employee Name *</label>
            <input type="text" id="edit_empName" name="empName" required>
          </div>

          <div class="slds-form-element">
            <label for="edit_designation">Designation</label>
            <input type="text" id="edit_designation" name="designation">
          </div>

          <div class="slds-form-element">
            <label for="edit_spouseWorkingSMIORE">Spouse Working in SMIORE? *</label>
            <select id="edit_spouseWorkingSMIORE" name="spouseWorkingSMIORE">
              <option value="No">No</option>
              <option value="Yes">Yes</option>
            </select>
          </div>

          <div class="slds-form-element">
            <label for="edit_spouseWorkingGroupCompanies">Spouse Working in Group Co.? *</label>
            <select id="edit_spouseWorkingGroupCompanies" name="spouseWorkingGroupCompanies">
              <option value="No">No</option>
              <option value="Yes">Yes</option>
            </select>
          </div>
        </div>

        <div class="slds-section-title">2. Child / Student Details</div>
        <div class="slds-grid">
          <div class="slds-form-element">
            <label for="edit_childrenName">Child's Name</label>
            <input type="text" id="edit_childrenName" name="childrenName">
          </div>

          <div class="slds-form-element">
            <label for="edit_dob">Date of Birth</label>
            <input type="date" id="edit_dob" name="dob" onchange="calculateModalAge()">
          </div>

          <div class="slds-form-element">
            <label for="edit_age">Calculated Age</label>
            <input type="text" id="edit_age" readonly>
          </div>

          <div class="slds-form-element">
            <label for="edit_gender">Gender</label>
            <select id="edit_gender" name="gender">
              <option value="">Select Gender</option>
              <option value="Male">Male</option>
              <option value="Female">Female</option>
              <option value="Other">Other</option>
            </select>
          </div>

          <div class="slds-form-element">
            <label for="edit_relationship">Relationship</label>
            <input type="text" id="edit_relationship" name="relationship">
          </div>

          <div class="slds-form-element">
            <label for="edit_childOrder">Child Order</label>
            <select id="edit_childOrder" name="childOrder">
              <option value="">Select Child Order</option>
              <option value="First">First Child</option>
              <option value="Second">Second Child</option>
            </select>
          </div>
        </div>

        <div class="slds-section-title">3. Academic Details</div>
        <div class="slds-grid">
          <div class="slds-form-element full-width">
            <label for="edit_collegeName">College Name</label>
            <input type="text" id="edit_collegeName" name="collegeName">
          </div>

          <div class="slds-form-element">
            <label for="edit_course">Course Name</label>
            <input type="text" id="edit_course" name="course">
          </div>

          <div class="slds-form-element">
            <label for="edit_presentYear">Present Year</label>
            <input type="text" id="edit_presentYear" name="presentYear">
          </div>

          <div class="slds-form-element">
            <label for="edit_previousAyPercentage">Prev AY Percentage (%)</label>
            <input type="number" step="0.01" id="edit_previousAyPercentage" name="previousAyPercentage">
          </div>

          <div class="slds-form-element">
            <label for="edit_feeAmountCurrentAy">Fee Amount for Current AY</label>
            <input type="number" step="0.01" id="edit_feeAmountCurrentAy" name="feeAmountCurrentAy">
          </div>
        </div>

        <div class="slds-section-title">4. Bank Account Details</div>
        <div class="slds-grid">
          <div class="slds-form-element full-width">
            <label for="edit_employeeNamePassbook">Name as per Passbook</label>
            <input type="text" id="edit_employeeNamePassbook" name="employeeNamePassbook">
          </div>

          <div class="slds-form-element">
            <label for="edit_bankAccountNo">Bank Account Number</label>
            <input type="text" id="edit_bankAccountNo" name="bankAccountNo">
          </div>

          <div class="slds-form-element">
            <label for="edit_ifscCode">IFSC Code</label>
            <input type="text" id="edit_ifscCode" name="ifscCode">
          </div>

          <div class="slds-form-element">
            <label for="edit_bankName">Bank Name</label>
            <input type="text" id="edit_bankName" name="bankName">
          </div>

          <div class="slds-form-element">
            <label for="edit_branchName">Branch Name</label>
            <input type="text" id="edit_branchName" name="branchName">
          </div>
        </div>

      </div>

      <div class="slds-modal-footer">
        <button type="button" class="slds-btn slds-btn-neutral" onclick="closeEditModal()">Cancel</button>
        <button type="submit" class="slds-btn slds-btn-brand">Save Application</button>
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