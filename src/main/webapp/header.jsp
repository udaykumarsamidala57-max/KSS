<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    HttpSession sesso = request.getSession(false);
    if (sesso == null || sesso.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    String userss = (String) sesso.getAttribute("username");
    String roless = (String) sesso.getAttribute("role");
    boolean isGlobalUser = roless != null && "Global".equalsIgnoreCase(roless.replace('\u00A0', ' ').trim());
    String deptss = (String) sesso.getAttribute("department");
    String branchs = (String) sesso.getAttribute("branch");
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
    text-decoration: Lucida Handwriting Bold;
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
    font-family: Lucida Handwriting;
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

  /* Core Navigation Menu styling - pushed towards the right */
  .kss-navbar-scope .navbar-menu {
    list-style: none;
    display: flex;
    gap: 4px;
    align-items: center;
    margin: 0 0 0 auto;
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
    white-space: nowrap;
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
    padding-left: 16px;
    margin-left: 12px;
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
    margin-bottom: 3px;
  }

  .kss-navbar-scope .user-meta-group {
    align-items: center;
    gap: 6px;
  }

  .kss-navbar-scope .user-role-badge {
    font-size: 10px;
    font-weight: 600;
    color: #ffffff;
    background-color: rgba(255, 255, 255, 0.18);
    border: 1px solid rgba(255, 255, 255, 0.25);
    padding: 2px 8px;
    border-radius: 12px;
    text-transform: uppercase;
    letter-spacing: 0.4px;
    display: inline-flex;
    align-items: center;
    white-space: nowrap;
    box-shadow: 0 1px 3px rgba(0,0,0,0.1);
  }

  .kss-navbar-scope .user-branch-badge {
    font-size: 10px;
    font-weight: 600;
    color: #fce8ec;
    background-color: rgba(0, 0, 0, 0.25);
    border: 1px solid rgba(255, 255, 255, 0.15);
    padding: 2px 8px;
    border-radius: 12px;
    text-transform: uppercase;
    letter-spacing: 0.4px;
    align-items: center;
    white-space: nowrap;
    box-shadow: 0 1px 3px rgba(0,0,0,0.1);
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
      margin: 0;
    }

    .kss-navbar-scope .user-profile-section {
      border-left: none;
      border-top: 1px solid rgba(255, 255, 255, 0.2);
      padding-left: 0;
      padding-top: 10px;
      margin-left: 0;
      width: 100%;
      justify-content: center;
    }

    .kss-navbar-scope .user-details {
      align-items: center;
      text-align: center;
    }

    .kss-navbar-scope .user-meta-group {
      justify-content: center;
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

  /* 9-dots launcher (Global only) */
  .kss-navbar-scope .kss-apps { position: relative; flex-shrink: 0; margin-left: auto; }
  .kss-navbar-scope .kss-apps-btn {
    width: 40px; height: 40px; border-radius: 50%; border: none; cursor: pointer;
    background: transparent; color: #f6e3e8; display: inline-flex; align-items: center; justify-content: center;
    transition: background .15s ease, color .15s ease;
  }
  .kss-navbar-scope .kss-apps-btn:hover { background: rgba(255,255,255,.14); color: #fff; }
  .kss-navbar-scope .kss-apps-btn.is-active { background: rgba(255,255,255,.18); color: #fff; box-shadow: inset 0 0 0 1px rgba(255,255,255,.35); }
  .kss-navbar-scope .kss-apps-btn.open { background: #fff; color: var(--nav-primary); }
  .kss-navbar-scope .kss-apps-btn:focus-visible { outline: none; box-shadow: 0 0 0 3px rgba(255,255,255,.4); }
  .kss-navbar-scope .kss-apps-panel {
    display: none; position: absolute; top: calc(100% + 10px); right: -6px; z-index: 10050;
    width: 400px; max-width: calc(100vw - 16px); background: #fff; color: var(--nav-text-main);
    border-radius: 14px; border: 1px solid #ecdfe2; overflow: hidden;
    box-shadow: 0 10px 28px rgba(122,31,53,.16), 0 2px 6px rgba(122,31,53,.08);
  }
  .kss-navbar-scope .kss-apps-panel.open { display: block; animation: kssAppsIn .14s ease-out; }
  @keyframes kssAppsIn { from { opacity: 0; transform: translateY(-4px) scale(.98); } to { opacity: 1; transform: none; } }
  .kss-navbar-scope .kss-apps-search { padding: 12px 14px 6px; }
  .kss-navbar-scope .kss-apps-search input {
    width: 100%; height: 36px; border-radius: 18px; border: 1px solid #efe4e7; background: #faf6f7;
    padding: 0 14px; font: inherit; font-size: 13px; color: var(--nav-text-main); outline: none;
  }
  .kss-navbar-scope .kss-apps-search input:focus { background: #fff; border-color: #d9b9c1; box-shadow: 0 0 0 3px rgba(122,31,53,.08); }
  .kss-navbar-scope .kss-apps-body { max-height: min(70vh, 540px); overflow-y: auto; padding: 0 10px 10px; }
  .kss-navbar-scope .kss-apps-sec { padding: 6px 0 2px; }
  .kss-navbar-scope .kss-apps-sec + .kss-apps-sec { border-top: 1px solid #f3eaec; }
  .kss-navbar-scope .kss-apps-sec h4 {
    margin: 6px 8px 4px; font-size: 11px; font-weight: 700; letter-spacing: .6px;
    text-transform: uppercase; color: var(--nav-primary);
  }
  .kss-navbar-scope .kss-apps-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 2px; }
  .kss-navbar-scope .kss-apps-panel a.kss-app-tile {
    display: flex; flex-direction: column; align-items: center; gap: 7px; padding: 11px 4px 9px;
    border-radius: 10px; border: 1px solid transparent; text-decoration: none; color: #3c3c3c;
    background: transparent; min-width: 0; transition: background .12s ease, border-color .12s ease;
  }
  .kss-navbar-scope .kss-apps-panel a.kss-app-tile:hover { background: #fbf4f6; border-color: #f0e1e5; color: #3c3c3c; }
  .kss-navbar-scope .kss-apps-panel a.kss-app-tile.is-current { background: #fbf1f3; border-color: #e6c9d0; }
  .kss-navbar-scope .kss-app-icon {
    width: 42px; height: 42px; border-radius: 50%; display: flex; align-items: center; justify-content: center;
    font-size: 18px; font-weight: 700; line-height: 1; background: #f8eaee; color: var(--nav-primary);
  }
  .kss-navbar-scope .kss-app-icon.tone-b { background: #fdf1e6; color: #a8540f; }
  .kss-navbar-scope .kss-app-icon.tone-c { background: #e9f6ee; color: #1e7e46; }
  .kss-navbar-scope .kss-app-icon.tone-d { background: #eaf2fb; color: #2a63a3; }
  .kss-navbar-scope .kss-app-icon.tone-e { background: #f1edfb; color: #5f4bb6; }
  .kss-navbar-scope .kss-app-icon.tone-f { background: #f1f1f2; color: #55595f; }
  .kss-navbar-scope .kss-app-label {
    font-size: 12px; line-height: 1.3; text-align: center; color: #3c3c3c;
    display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; max-width: 100%;
  }
  .kss-navbar-scope .kss-apps-panel a.kss-app-tile.is-current .kss-app-label { color: var(--nav-primary); font-weight: 600; }
  .kss-navbar-scope .kss-apps-none { padding: 18px; text-align: center; color: #888; font-size: 13px; }
  @media (max-width: 1100px) {
    .kss-navbar-scope .kss-apps { margin-left: 0; }
    .kss-navbar-scope .kss-apps-panel { position: fixed; top: 70px; left: 8px; right: 8px; width: auto; max-width: none; }
  }
  @media (max-width: 420px) {
    .kss-navbar-scope .kss-apps-grid { grid-template-columns: repeat(2, 1fr); }
  }
</style>

<!-- TOP NAVIGATION BAR -->
<nav class="kss-navbar-scope navbar">
  <div class="navbar-container">
    <a href="Dashboard.jsp" class="navbar-brand">
      <div class="brand-text-group">
        <span class="brand-title">Karnataka Seva Sangha</span>
        <span class="brand-subtitle">Higher Education Scholarship Portal</span>
      </div>
    </a>
    
    <%
      String currentURI = request.getRequestURI();
      
      // Compute helper states to keep top-level folder links highlighted if inner items are active
      boolean isScholarshipActive = currentURI.contains("ScholarshipApplication.jsp") || 
                                    currentURI.contains("ScholarshipListServelt") || 
                                    currentURI.contains("scholarshipDocumentStatus.jsp");

      boolean isApprovalActive = currentURI.contains("approveDocuments.jsp") || 
                                 currentURI.contains("approveScholarship.jsp") || 
                                 currentURI.contains("approvalAction.jsp") ||
                                 currentURI.contains("KssCourseServlet") ||
                                 currentURI.contains("kssCourse.jsp") ||
                                 currentURI.contains("VerifyDocumentsServlet") ||
                                 currentURI.contains("verifyDocuments.jsp") ||
                                 currentURI.contains("ApproveScholarshipServlet");
                                 
      boolean isReportsActive = currentURI.contains("approvedList.jsp") || 
                                currentURI.contains("rejectedList.jsp") || 
                                currentURI.contains("reimbursement.jsp");
    %>
    
    <ul class="navbar-menu">
      <!-- Combined Scholarship Options Dropdown -->
      <li>
        <a href="Dashboard.jsp" class="<%= currentURI.contains("Dashboard.jsp") ? "active" : "" %>">
          Dashboard
        </a>
      <li>
        <a href="#" class="dropdown-toggle <%= isScholarshipActive ? "active" : "" %>" onclick="return false;">
          Scholarships
        </a>
        <ul class="dropdown-menu">
          <li>
            <a href="ScholarshipApplication.jsp" class="<%= currentURI.contains("ScholarshipApplication.jsp") ? "active" : "" %>">
              Apply Scholarship
            </a>
          </li>
          <li>
            <a href="ScholarshipListServelt" class="<%= currentURI.contains("ScholarshipListServelt") || currentURI.contains("scholarshipList.jsp") ? "active" : "" %>">
              Scholarship List
            </a>
          </li>
          <li>
            <a href="scholarshipDocumentStatus.jsp" class="<%= currentURI.contains("scholarshipDocumentStatus.jsp") ? "active" : "" %>">
              Document Status
            </a>
          </li>
        </ul>
      </li>

      <li>
        <a href="UpdateStatusServlet" class="<%= currentURI.contains("UpdateStatusServlet") ? "active" : "" %>">
          Submit to KSS
        </a>
      </li>

      
      <!-- Dropdown Item: Status Summaries & Lists Reports -->
      <li>
        <a href="#" class="dropdown-toggle <%= isReportsActive ? "active" : "" %>" onclick="return false;">
          Lists & Claims
        </a>
        <ul class="dropdown-menu">
          <li>
            <a href="submitted_list.jsp" class="<%= currentURI.contains("submitted_list.jsp") ? "active" : "" %>">
              Submitted List
            </a>
          </li>
          <% if (isGlobalUser) { %>
          <li>
            <a href="#" class="<%= currentURI.contains("approvedList.jsp") ? "active" : "" %>">
              Approved List
            </a>
          </li>
          <li>
            <a href="#" class="<%= currentURI.contains("rejectedList.jsp") ? "active" : "" %>">
              Rejected List
            </a>
          </li>
          <li>
            <a href="#" class="<%= currentURI.contains("reimbursement.jsp") ? "active" : "" %>">
              Reimbursement
            </a>
          </li>
          <% } %>
        </ul>
      </li>
    </ul>

    <% if (isGlobalUser) {
         // 9-dots launcher, Global only: { section, label, href, icon entity, tone, active-match... }
         String[][] apps = {
           { "Approvals", "Step 1 : Apply KSS Course",   "KssCourseServlet",          "1",        "a", "KssCourseServlet", "kssCourse.jsp" },
           { "Approvals", "Step 2 : Verify Documents",   "VerifyDocumentsServlet",    "2",        "a", "VerifyDocumentsServlet", "verifyDocuments.jsp" },
           { "Approvals", "Step 3 : Approve Scholarship","ApproveScholarshipServlet", "3",        "a", "ApproveScholarshipServlet", "approveScholarship.jsp" },
           { "KSS CSR",   "Dashboard",                  "CsrDashboardServlet",       "&#9635;",  "b", "CsrDashboardServlet", "csrDashboard.jsp" },
           { "KSS CSR",   "Management Approvals",            "CsrLetterServlet",          "&#9993;",  "b", "CsrLetterServlet", "csrLetter" },
           { "KSS CSR",   "Work Orders",                 "CsrWorkOrderServlet",       "&#9998;",  "d", "CsrWorkOrderServlet", "csrWorkOrder" },
           { "KSS CSR",   "Invoices",                    "CsrInvoiceServlet",         "&#9783;",  "e", "CsrInvoiceServlet", "csrInvoice" },
           { "KSS CSR",   "Funds Request Letters",       "CsrFrlServlet",             "&#9997;",  "a", "CsrFrlServlet", "csrFrl" },
           { "KSS CSR",   "Fund Receipts",               "CsrFundServlet",            "&#8377;",  "c", "CsrFundServlet", "csrFund" },
           { "Masters",   "Organization Master",         "organization.jsp",          "&#9873;",  "f", "organization.jsp" },
           { "Masters",   "KSS Course Master",           "KssCourseMasterServlet",    "&#9881;",  "f", "KssCourseMasterServlet", "kssCourseMaster.jsp" }
         };
         boolean appsActive = false;
         for (String[] a : apps) for (int k = 5; k < a.length; k++) if (currentURI.contains(a[k])) appsActive = true;
    %>
    <!-- Gmail-style 9-dots launcher: Approvals, KSS CSR, Masters (Global only) -->
    <div class="kss-apps">
      <button type="button" class="kss-apps-btn <%= appsActive ? "is-active" : "" %>" id="kssAppsBtn" aria-label="Apps" aria-haspopup="true" aria-expanded="false" title="Approvals, KSS CSR &amp; Masters">
        <svg viewBox="0 0 24 24" width="22" height="22" aria-hidden="true"><path fill="currentColor" d="M6 8a2 2 0 1 0 0-4 2 2 0 0 0 0 4zm6 0a2 2 0 1 0 0-4 2 2 0 0 0 0 4zm6 0a2 2 0 1 0 0-4 2 2 0 0 0 0 4zM6 14a2 2 0 1 0 0-4 2 2 0 0 0 0 4zm6 0a2 2 0 1 0 0-4 2 2 0 0 0 0 4zm6 0a2 2 0 1 0 0-4 2 2 0 0 0 0 4zM6 20a2 2 0 1 0 0-4 2 2 0 0 0 0 4zm6 0a2 2 0 1 0 0-4 2 2 0 0 0 0 4zm6 0a2 2 0 1 0 0-4 2 2 0 0 0 0 4z"/></svg>
      </button>
      <div class="kss-apps-panel" id="kssAppsPanel" role="dialog" aria-label="Apps">
        <div class="kss-apps-search">
          <input type="search" id="kssAppsSearch" placeholder="Search menus" autocomplete="off">
        </div>
        <div class="kss-apps-body">
        <%
          String lastSec = null;
          for (String[] a : apps) {
            boolean on = false;
            for (int k = 5; k < a.length; k++) if (currentURI.contains(a[k])) on = true;
            if (!a[0].equals(lastSec)) {
              if (lastSec != null) { %></div></div><% }
              lastSec = a[0]; %>
          <div class="kss-apps-sec"><h4><%= a[0] %></h4><div class="kss-apps-grid">
        <%  } %>
            <a href="<%= a[2] %>" class="kss-app-tile <%= on ? "is-current" : "" %>" data-search="<%= (a[0] + " " + a[1]).toLowerCase() %>">
              <span class="kss-app-icon tone-<%= a[4] %>"><%= a[3] %></span>
              <span class="kss-app-label"><%= a[1] %></span>
            </a>
        <% } %>
          </div></div>
          <div class="kss-apps-none" id="kssAppsNone" style="display:none;">No menu matches</div>
        </div>
      </div>
    </div>
    <% } %>

    <!-- Right Side: User Details & Logout Button -->
    <div class="user-profile-section">
      <div class="user-details">
        <span class="user-name"><%= userss != null ? userss : "User" %></span>
        <div class="user-meta-group">
          <% if (roless != null && !roless.trim().isEmpty()) { %>
            <span class="user-role-badge"><%= roless %></span>
          <% } %>
          <% if (branchs != null && !branchs.trim().isEmpty()) { %>
            <span class="user-branch-badge"><%= branchs %></span>
          <% } %>
        </div>
      </div>
      <a href="Logout.jsp" class="logout-btn" title="Sign out of system">
        Logout &#x279F;
      </a>
    </div>

  </div>
</nav>
<% if (isGlobalUser) { %>
<script>
(function () {
  var btn = document.getElementById('kssAppsBtn'), panel = document.getElementById('kssAppsPanel');
  var search = document.getElementById('kssAppsSearch'), none = document.getElementById('kssAppsNone');
  if (!btn || !panel) return;
  function filter(q) {
    q = (q || '').trim().toLowerCase(); var shown = 0;
    panel.querySelectorAll('.kss-apps-sec').forEach(function (sec) {
      var n = 0;
      sec.querySelectorAll('.kss-app-tile').forEach(function (t) {
        var ok = !q || t.getAttribute('data-search').indexOf(q) > -1;
        t.style.display = ok ? '' : 'none'; if (ok) n++;
      });
      sec.style.display = n ? '' : 'none'; shown += n;
    });
    none.style.display = shown ? 'none' : '';
  }
  function open(v) {
    panel.classList.toggle('open', v); btn.classList.toggle('open', v);
    btn.setAttribute('aria-expanded', v ? 'true' : 'false');
    if (v) { search.value = ''; filter(''); setTimeout(function () { search.focus(); }, 30); }
  }
  btn.addEventListener('click', function (e) { e.stopPropagation(); open(!panel.classList.contains('open')); });
  panel.addEventListener('click', function (e) { e.stopPropagation(); });
  search.addEventListener('input', function () { filter(search.value); });
  search.addEventListener('keydown', function (e) {
    if (e.key === 'Enter') {
      var first = Array.prototype.filter.call(panel.querySelectorAll('.kss-app-tile'), function (t) { return t.style.display !== 'none'; })[0];
      if (first) location.href = first.href;
    }
  });
  document.addEventListener('click', function () { open(false); });
  document.addEventListener('keydown', function (e) { if (e.key === 'Escape') open(false); });
})();
</script>
<% } %>

<!-- FOOTER COMPONENT -->
<footer class="kss-footer-scope">
  <div class="footer-container">
    <div>
      &copy; <%= java.time.Year.now().getValue() %> Karnataka Seva Sangha. All rights reserved.
    </div>
    <div>
      Developed by <span class="developer-credit">SSS IT | OFFICE CENTRAL</span>&nbsp;&nbsp;<span class="tagline"></span>
    </div>
  </div>
</footer>
