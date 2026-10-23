<%
    // Global users choose the institution to work in (KSS / SSS). Others always work in KSS.
    if (session.getAttribute("username") == null) { response.sendRedirect("login.jsp"); return; }
    String r0 = (String) session.getAttribute("role");
    if (r0 == null || !"Global".equalsIgnoreCase(r0.replace((char) 160, ' ').trim())) { response.sendRedirect("Dashboard.jsp"); return; }
    String chosen = (String) session.getAttribute(com.Bean.AppConfig.SESSION_KEY);
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Choose Institution</title>

<!-- INCLUDE SHARED HEADER & MENU -->
<%@ include file="header.jsp" %>

<%-- CSS is included inline: ScholarshipListServelt is mapped to "/" and would intercept a separate .css request --%>
<style>
<%@ include file="css/csrLetter.css" %>
</style>
<style>
<%@ include file="css/finance.css" %>
  .si-wrap { max-width: 760px; margin: 30px auto 0; }
  .si-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; margin-top: 12px; }
  .si-card { display: block; padding: 18px 18px 16px; background: #fff; border: 1px solid #e2e8f0; border-radius: 6px;
             text-decoration: none !important; color: #0f172a !important; box-shadow: 0 1px 2px rgba(15,23,42,.05); }
  .si-card:hover { border-color: #0f766e; background: #f0fdfa; }
  .si-card.on { border: 2px solid #0f766e; }
  .si-code { font-size: 22px; font-weight: 700; color: #0f766e; }
  .si-name { font-size: 14px; font-weight: 600; margin-top: 2px; }
  .si-what { font-size: 12px; color: #64748b; margin-top: 8px; }
  .si-tag { display: inline-block; margin-top: 10px; font-size: 10.5px; font-weight: 600; color: #047857; }
  @media (max-width: 640px) { .si-grid { grid-template-columns: 1fr; } }
</style>
</head>
<body>

<div class="csr-page">
  <div class="si-wrap">
    <div class="csr-header">
      <div>
        <div class="csr-subtitle">Welcome <%= userss %></div>
        <h1 class="csr-title">Choose the institution to work in</h1>
      </div>
    </div>
    <div class="si-grid">
      <% String[][] siList = com.Bean.AppConfig.choices();   // { code, name, what }
         for (int si = 0; si < siList.length; si++) { boolean isOn = siList[si][0].equals(chosen); %>
      <a class="si-card <%= isOn ? "on" : "" %>" href="InstitutionServlet?code=<%= siList[si][0] %>">
        <div class="si-code"><%= siList[si][0] %></div>
        <div class="si-name"><%= siList[si][1] %></div>
        <div class="si-what"><%= siList[si][2] %></div>
        <% if (isOn) { %><div class="si-tag">Current</div><% } %>
      </a>
      <% } %>
    </div>
    <div class="lv-note" style="padding:10px 2px; font-size:11.5px; color:#64748b;">You can switch any time with the button next to your name at the top.</div>
  </div>
</div>

</body>
</html>
