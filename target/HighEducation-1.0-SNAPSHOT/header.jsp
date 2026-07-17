<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>

<style>
  :root {
    /* Refined Color Palette - Softer, Corporate Crimson */
    --primary-color: #7a1f35;       /* Muted rich burgundy */
    --primary-dark: #5e1627;        /* Deeper shade for soft gradients */
    --accent-bg: #fdf6f7;           /* Extra soft warm white background */
    --border-color: #e2cece;        /* Muted reddish gray border */
    --text-main: #2b2b2b;
    --text-muted: #666666;
    --bg-main: #f9f6f6;              
  }

  * {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
  }

  body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
    background-color: var(--bg-main);
    color: var(--text-main);
    padding: 24px 12px;
    -webkit-font-smoothing: antialiased;
  }

  /* Executive Top Navigation Bar */
  .navbar {
    background: linear-gradient(180deg, var(--primary-color) 0%, var(--primary-dark) 100%);
    color: #ffffff;
    box-shadow: 0 4px 12px rgba(122, 31, 53, 0.12);
    border-radius: 8px;
    border-bottom: 2px solid #a83d56;
    margin-bottom: 20px;
  }

  .navbar-container {
    max-width: 900px;
    margin: 0 auto;
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 12px 24px;
    min-height: 60px;
  }

  /* Portal Brand Container */
  .navbar-brand {
    text-decoration: none;
    display: flex;
    align-items: center;
    gap: 12px;
    opacity: 0.96;
    transition: opacity 0.2s ease;
  }

  .navbar-brand:hover {
    opacity: 1;
  }

  /* Professional Two-Tier Brand Heading Structure */
  .brand-text-group {
    display: flex;
    flex-direction: column;
    justify-content: center;
  }

  .brand-title {
    font-size: 16px;
    font-weight: 700;
    letter-spacing: 0.6px;
    text-transform: uppercase;
    color: #ffffff;
    line-height: 1.25;
  }

  .brand-subtitle {
    font-size: 11px;
    font-weight: 500;
    letter-spacing: 0.4px;
    color: #fce8ec;
    line-height: 1.25;
    margin-top: 1px;
    opacity: 0.9;
  }

  /* Subtitle/Badge Tag */
  .brand-badge {
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
  }

  /* Navigation Links */
  .navbar-menu {
    list-style: none;
    display: flex;
    gap: 6px;
    align-items: center;
  }

  .navbar-menu li a {
    color: #f3e5e8;
    text-decoration: none;
    font-size: 13px;
    font-weight: 500;
    padding: 7px 14px;
    border-radius: 5px;
    transition: all 0.2s ease-in-out;
    display: inline-block;
  }

  .navbar-menu li a:hover {
    color: #ffffff;
    background-color: rgba(255, 255, 255, 0.12);
  }

  /* Active Menu Item Highlight */
  .navbar-menu li a.active {
    color: #ffffff;
    background-color: rgba(255, 255, 255, 0.22);
    font-weight: 600;
    box-shadow: inset 0 1px 2px rgba(0, 0, 0, 0.15);
  }

  /* Main Page Container Styling */
  .container {
    max-width: 900px;
    margin: 0 auto;
    background: #ffffff;
    border-radius: 8px;
    box-shadow: 0 4px 16px rgba(0, 0, 0, 0.04);
    border: 1px solid var(--border-color);
    overflow: hidden;
  }

  /* Mobile Responsive Tweaks */
  @media (max-width: 768px) {
    .navbar {
      margin-bottom: 16px;
    }

    .navbar-container {
      flex-direction: column;
      padding: 14px 16px;
      gap: 12px;
      align-items: center;
      text-align: center;
    }

    .navbar-brand {
      flex-direction: column;
      gap: 6px;
    }
    
    .navbar-menu {
      width: 100%;
      justify-content: center;
      flex-wrap: wrap;
    }

    .navbar-menu li a {
      padding: 6px 10px;
      font-size: 12px;
    }
  }
</style>

<!-- TOP NAVIGATION BAR -->
<nav class="navbar">
  <div class="navbar-container">
    <a href="index.jsp" class="navbar-brand">
      <div class="brand-text-group">
        <span class="brand-title">Karnataka Seva Sangha</span>
        <span class="brand-subtitle">Higher Education Scholarship Portal</span>
      </div>
      <span class="brand-badge">Admin</span>
    </a>
    
    <%
      // Detect current URI for automatic active menu tab highlighting
      String currentURI = request.getRequestURI();
    %>
    
    <ul class="navbar-menu">
      <li>
        <a href="ScholarshipApplication.jsp" class="<%= currentURI.contains("ScholarshipApplication.jsp") ? "active" : "" %>">
          Apply Scholarship
        </a>
      </li>
      <li>
        <a href="organization.jsp" class="<%= currentURI.contains("organization.jsp") ? "active" : "" %>">
          Organization Master
        </a>
      </li>
    </ul>
  </div>
</nav>