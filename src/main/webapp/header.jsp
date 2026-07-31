<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    HttpSession sesso = request.getSession(false);
    if (sesso == null || sesso.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    String userss = (String) sesso.getAttribute("username");
    String roless = (String) sesso.getAttribute("role");
    String deptss = (String) sesso.getAttribute("department");
%>
<style>
  /* Scoped Variables & Isolated CSS to prevent leaking into main page body */
  :root {
    --nav-primary: #7a1f35;       
    --nav-primary-dark: #5e1627;  
    --nav-accent-bg: #fdf6f7;     
    --nav-border: #e2cece;        
    --nav-text-main: #2b2b2b;
    --nav-text-muted: #666666;
  }

  /* Wrapped rules inside an explicit parent selector scope */
  .kss-navbar-scope.navbar {
    box-sizing: border-box;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
    background: linear-gradient(180deg, var(--nav-primary) 0%, var(--nav-primary-dark) 100%);
    color: #ffffff;
    box-shadow: 0 4px 12px rgba(122, 31, 53, 0.12);
    border-radius: 8px;
    border-bottom: 2px solid #a83d56;
    margin-bottom: 20px;
    padding: 0;
    width: 100%;
    text-align: left;
  }

  .kss-navbar-scope.navbar * {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
    line-height: normal;
  }

  .kss-navbar-scope .navbar-container {
    max-width: 1400px;
    margin: 0 auto;
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 10px 24px;
    min-height: 60px;
    background: transparent;
    gap: 16px;
  }

  .kss-navbar-scope .navbar-brand {
    text-decoration: none;
    display: flex;
    align-items: center;
    gap: 12px;
    opacity: 0.96;
    transition: opacity 0.2s ease;
    background: transparent;
    border: none;
    flex-shrink: 0;
  }

  .kss-navbar-scope .navbar-brand:hover {
    opacity: 1;
    background: transparent;
  }

  .kss-navbar-scope .brand-text-group {
    display: flex;
    flex-direction: column;
    justify-content: center;
    text-align: left;
  }

  .kss-navbar-scope .brand-title {
    font-size: 16px;
    font-weight: 700;
    letter-spacing: 0.6px;
    text-transform: uppercase;
    color: #ffffff;
    line-height: 1.25;
    display: block;
  }

  .kss-navbar-scope .brand-subtitle {
    font-size: 11px;
    font-weight: 500;
    letter-spacing: 0.4px;
    color: #fce8ec;
    line-height: 1.25;
    margin-top: 1px;
    opacity: 0.9;
    display: block;
  }

  .kss-navbar-scope .brand-badge {
    font-size: 10px;
    font-weight: 600;
    background-color: rgba(255, 255, 255, 0.15);
    color: #ffffff;
    padding: 3px 8px;
    border-radius: 4px;
    letter-spacing: 0.5px;
    text-transform: uppercase;
    border: 1px solid rgba(255, 255, 255, 0.2);
    white-space: nowrap;
    display: inline-block;
  }

  /* Core Navigation Menu styling */
  .kss-navbar-scope .navbar-menu {
    list-style: none;
    display: flex;
    gap: 4px;
    align-items: center;
    margin: 0;
    padding: 0;
    background: transparent;
  }

  .kss-navbar-scope .navbar-menu > li {
    margin: 0;
    padding: 0;
    position: relative;
    list-style-type: none;
    background: transparent;
  }

  .kss-navbar-scope .navbar-menu li a {
    color: #f3e5e8;
    text-decoration: none;
    font-size: 13px;
    font-weight: 500;
    padding: 8px 12px;
    border-radius: 5px;
    transition: all 0.2s ease-in-out;
    display: flex;
    align-items: center;
    gap: 4px;
    line-height: 1.5;
  }

  .kss-navbar-scope .navbar-menu li a:hover {
    color: #ffffff;
    background-color: rgba(255, 255, 255, 0.12);
  }

  .kss-navbar-scope .navbar-menu li a.active {
    color: #ffffff;
    background-color: rgba(255, 255, 255, 0.22);
    font-weight: 600;
    box-shadow: inset 0 1px 2px rgba(0, 0, 0, 0.15);
  }

  /* Dropdown indicator caret symbols */
  .kss-navbar-scope .dropdown-toggle::after {
    content: ' \25BE';
    font-size: 10px;
    vertical-align: middle;
  }

  /* Dropdown Menu Container Panel */
  .kss-navbar-scope .dropdown-menu {
    display: none;
    position: absolute;
    top: 100%;
    left: 0;
    z-index: 1000;
    min-width: 200px;
    padding: 6px 0;
    margin-top: 2px;
    list-style: none;
    background-color: #ffffff;
    border: 1px solid var(--nav-border);
    border-radius: 6px;
    box-shadow: 0 6px 16px rgba(0, 0, 0, 0.12);
  }

  .kss-navbar-scope .navbar-menu > li:last-child .dropdown-menu {
    left: auto;
    right: 0;
  }

  .kss-navbar-scope .dropdown-menu li {
    width: 100%;
  }

  .kss-navbar-scope .dropdown-menu li a {
    color: var(--nav-text-main) !important;
    display: block;
    width: 100%;
    padding: 10px 16px;
    font-size: 13px;
    font-weight: 400;
    border-radius: 0;
    text-align: left;
    transition: background-color 0.15s ease;
  }

  .kss-navbar-scope .dropdown-menu li a:hover {
    background-color: var(--nav-accent-bg);
    color: var(--nav-primary) !important;
  }

  .kss-navbar-scope .dropdown-menu li a.active {
    background-color: var(--nav-primary);
    color: #ffffff !important;
    font-weight: 500;
    box-shadow: none;
  }

  .kss-navbar-scope .navbar-menu > li:hover .dropdown-menu {
    display: block;
  }

  /* Right-Aligned User Profile & Logout Controls */
  .kss-navbar-scope .user-profile-section {
    display: flex;
    align-items: center;
    gap: 12px;
    padding-left: 12px;
    border-left: 1px solid rgba(255, 255, 255, 0.2);
    flex-shrink: 0;
  }

  .kss-navbar-scope .user-details {
    display: flex;
    flex-direction: column;
    align-items: flex-end;
    text-align: right;
  }

  .kss-navbar-scope .user-name {
    font-size: 13px;
    font-weight: 600;
    color: #ffffff;
    line-height: 1.2;
  }

  .kss-navbar-scope .user-role {
    font-size: 10px;
    font-weight: 500;
    color: #fce8ec;
    background-color: rgba(0, 0, 0, 0.2);
    padding: 1px 6px;
    border-radius: 3px;
    margin-top: 2px;
    text-transform: uppercase;
    letter-spacing: 0.3px;
    display: inline-block;
  }

  .kss-navbar-scope .logout-btn {
    color: #ffffff !important;
    background-color: rgba(255, 255, 255, 0.15);
    border: 1px solid rgba(255, 255, 255, 0.25);
    font-size: 12px;
    font-weight: 600;
    padding: 6px 12px;
    border-radius: 5px;
    text-decoration: none;
    transition: all 0.2s ease-in-out;
    display: inline-flex;
    align-items: center;
    gap: 4px;
    white-space: nowrap;
  }

  .kss-navbar-scope .logout-btn:hover {
    background-color: #c0392b;
    border-color: #a93226;
    box-shadow: 0 2px 6px rgba(0,0,0,0.2);
  }

  /* Fixed Bottom Footer Styling */
  .kss-footer-scope {
    position: fixed;
    bottom: 0;
    left: 0;
    right: 0;
    z-index: 999;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
    background: linear-gradient(180deg, var(--nav-primary) 0%, var(--nav-primary-dark) 100%);
    color: #ffffff;
    border-top: 3px solid #a83d56;
    padding: 12px 24px;
    width: 100%;
    box-sizing: border-box;
  }

  .kss-footer-scope .footer-container {
    max-width: 1400px;
    margin: 0 auto;
    display: flex;
    justify-content: space-between;
    align-items: center;
    font-size: 12px;
    color: #fce8ec;
  }

  .kss-footer-scope .developer-credit {
    font-weight: 600;
    color: #ffffff;
    background-color: rgba(255, 255, 255, 0.15);
    padding: 3px 10px;
    border-radius: 4px;
    border: 1px solid rgba(255, 255, 255, 0.25);
    letter-spacing: 0.5px;
  }

  /* Add padding to page body to ensure content isn't covered by fixed footer */
  body {
    padding-bottom: 60px;
  }

  /* Responsive Breakpoints */
  @media (max-width: 1100px) {
    body {
      padding-bottom: 90px;
    }

    .kss-navbar-scope.navbar {
      margin-bottom: 16px;
    }

    .kss-navbar-scope .navbar-container {
      flex-direction: column;
      padding: 14px 16px;
      gap: 12px;
      align-items: center;
    }

    .kss-navbar-scope .navbar-brand {
      flex-direction: column;
      gap: 6px;
    }
    
    .kss-navbar-scope .brand-text-group {
      text-align: center;
    }
    
    .kss-navbar-scope .navbar-menu {
      width: 100%;
      justify-content: center;
      flex-wrap: wrap;
    }

    .kss-navbar-scope .user-profile-section {
      border-left: none;
      border-top: 1px solid rgba(255, 255, 255, 0.2);
      padding-left: 0;
      padding-top: 10px;
      width: 100%;
      justify-content: center;
    }

    .kss-navbar-scope .user-details {
      align-items: center;
      text-align: center;
    }

    .kss-navbar-scope .dropdown-menu {
      position: static;
      display: none;
      width: 100%;
      box-shadow: none;
      border: none;
      background-color: rgba(255, 255, 255, 0.05);
      padding: 0;
      margin-top: 4px;
    }

    .kss-navbar-scope .navbar-menu > li:hover .dropdown-menu {
      display: block;
    }

    .kss-navbar-scope .dropdown-menu li a {
      color: #f3e5e8 !important;
      padding: 8px 20px;
    }

    .kss-navbar-scope .dropdown-menu li a:hover {
      background-color: rgba(255, 255, 255, 0.12);
      color: #ffffff !important;
    }

    .kss-footer-scope .footer-container {
      flex-direction: column;
      gap: 8px;
      text-align: center;
    }
  }
</style>

<!-- TOP NAVIGATION BAR -->
<nav class="kss-navbar-scope navbar">
  <div class="navbar-container">
    <a href="ScholarshipApplication.jsp" class="navbar-brand">
      <div class="brand-text-group">
        <span class="brand-title">Karnataka Seva Sangha</span>
        <span class="brand-subtitle">Higher Education Scholarship Portal</span>
      </div>
      <span class="brand-badge">Admin</span>
    </a>
    
    <%
      String currentURI = request.getRequestURI();
      
      // Compute helper states to keep core folder links highlighted if drop items are selected
      boolean isApprovalActive = currentURI.contains("approveDocuments.jsp") || 
                                 currentURI.contains("approveScholarship.jsp") || 
                                 currentURI.contains("approvalAction.jsp");
                                 
      boolean isReportsActive = currentURI.contains("approvedList.jsp") || 
                                currentURI.contains("rejectedList.jsp") || 
                                currentURI.contains("reimbursement.jsp");
    %>
    
    <ul class="navbar-menu">
      <li>
        <a href="ScholarshipApplication.jsp" class="<%= currentURI.contains("ScholarshipApplication.jsp") ? "active" : "" %>">
          Apply
        </a>
      </li>
      <li>
        <a href="ScholarshipListServelt" class="<%= currentURI.contains("ScholarshipListServelt") ? "active" : "" %>">
          Scholarship List
        </a>
      </li>
      <li>
        <a href="organization.jsp" class="<%= currentURI.contains("organization.jsp") ? "active" : "" %>">
          Organization Master
        </a>
      </li>
      <li>
        <a href="scholarshipDocumentStatus.jsp" class="<%= currentURI.contains("scholarshipDocumentStatus.jsp") ? "active" : "" %>">
          Document Status
        </a>
      </li>
      
      <!-- Dropdown Item: Verification & Approvals Actions -->
      <li>
        <a href="#" class="dropdown-toggle <%= isApprovalActive ? "active" : "" %>" onclick="return false;">
          Approvals
        </a>
        <ul class="dropdown-menu">
          <li>
            <a href="approveDocuments.jsp" class="<%= currentURI.contains("approveDocuments.jsp") ? "active" : "" %>">
              Approve Documents
            </a>
          </li>
          <li>
            <a href="approveScholarship.jsp" class="<%= currentURI.contains("approveScholarship.jsp") ? "active" : "" %>">
              Approve Scholarship
            </a>
          </li>
        </ul>
      </li>

      <!-- Dropdown Item: Status Summaries & Lists Reports -->
      <li>
        <a href="#" class="dropdown-toggle <%= isReportsActive ? "active" : "" %>" onclick="return false;">
          Lists & Claims
        </a>
        <ul class="dropdown-menu">
          <li>
            <a href="approvedList.jsp" class="<%= currentURI.contains("approvedList.jsp") ? "active" : "" %>">
              Approved List
            </a>
          </li>
          <li>
            <a href="rejectedList.jsp" class="<%= currentURI.contains("rejectedList.jsp") ? "active" : "" %>">
              Rejected List
            </a>
          </li>
          <li>
            <a href="reimbursement.jsp" class="<%= currentURI.contains("reimbursement.jsp") ? "active" : "" %>">
              Reimbursement
            </a>
          </li>
        </ul>
      </li>
    </ul>

    <!-- Right Side: User Details & Logout Button -->
    <div class="user-profile-section">
      <div class="user-details">
        <span class="user-name"><%= userss != null ? userss : "User" %></span>
        <% if (roless != null && !roless.trim().isEmpty()) { %>
          <span class="user-role"><%= roless %></span>
        <% } %>
      </div>
      <a href="Logout.jsp" class="logout-btn" title="Sign out of system">
        Logout &#x279F;
      </a>
    </div>

  </div>
</nav>

<!-- FOOTER COMPONENT -->
<footer class="kss-footer-scope">
  <div class="footer-container">
    <div>
      &copy; <%= java.time.Year.now().getValue() %> Karnataka Seva Sangha. All rights reserved.
    </div>
    <div>
      Developed by <span class="developer-credit">SSS IT</span>
    </div>
  </div>
</footer>