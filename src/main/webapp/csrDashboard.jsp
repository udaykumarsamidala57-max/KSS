<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@page import="java.util.Map"%>
<%@page import="java.util.List"%>
<%
    @SuppressWarnings("unchecked")
    Map<String, String> stats = (Map<String, String>) request.getAttribute("stats");
    if (stats == null) {
        response.sendRedirect("CsrDashboardServlet");
        return;
    }
    String loadError = (String) request.getAttribute("loadError");
    @SuppressWarnings("unchecked")
    List<Map<String, String>> approvalLetters = (List<Map<String, String>>) request.getAttribute("approvalLetters");
    @SuppressWarnings("unchecked")
    Map<String, String> letterStats = (Map<String, String>) request.getAttribute("letterStats");
    String selectedLetterId = (String) request.getAttribute("selectedLetterId");
    @SuppressWarnings("unchecked")
    List<Map<String, String>> companyPosition = (List<Map<String, String>>) request.getAttribute("companyPosition");
    @SuppressWarnings("unchecked")
    List<Map<String, String>> unitPosition = (List<Map<String, String>>) request.getAttribute("unitPosition");
    String companyError = (String) request.getAttribute("companyError");
    @SuppressWarnings("unchecked")
    List<Map<String, String>> projectPosition = (List<Map<String, String>>) request.getAttribute("projectPosition");
    @SuppressWarnings("unchecked")
    List<Map<String, String>> monthly = (List<Map<String, String>>) request.getAttribute("monthly");
    @SuppressWarnings("unchecked")
    List<String[]> monthlyYears = (List<String[]>) request.getAttribute("monthlyYears");
    String monthlyFy = (String) request.getAttribute("monthlyFy");
    String monthlyOpening = (String) request.getAttribute("monthlyOpening");
    String instCodeD = com.Bean.AppConfig.code();
%>
<%!
    /** An amount that opens the detail popup; "-" (nil) stays plain text. */
    private String dl(String value, String view, String key, String col, String fy) {
        if (value == null || "-".equals(value) || "0".equals(value) || "0.0%".equals(value)) return escapeHtml(value);
        return "<a href=\"#\" class=\"dd-link\" data-view=\"" + view + "\" data-key=\"" + escapeHtml(key) + "\" data-col=\"" + col + "\""
             + (fy == null ? "" : " data-fy=\"" + escapeHtml(fy) + "\"") + " title=\"Show details\">" + escapeHtml(value) + "</a>";
    }
    private String escapeHtml(String value) {
        if (value == null) return "";
        return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
                .replace("\"", "&quot;").replace("'", "&#39;");
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><%= com.Bean.AppConfig.code() %> CSR Dashboard</title>

<%@ include file="header.jsp" %>

<style>
<%@ include file="css/csrLetter.css" %>
</style>
<style>
<%@ include file="css/finance.css" %>
.csr-page { padding:18px 22px !important; }
.csr-header { align-items:flex-end !important; margin-bottom:16px !important; }
.csr-title { font-size:25px !important; letter-spacing:-.35px; }
.csr-subtitle { font-weight:600; }
.csr-export-toolbar { display:flex; align-items:center; flex-wrap:wrap; gap:8px; margin:0 0 16px; padding:10px 12px; background:#fff; border:1px solid var(--fin-line); border-radius:8px; box-shadow:0 1px 2px rgba(15,23,42,.05); }
.csr-export-toolbar button { min-height:34px; padding:0 13px; border:1px solid var(--fin-line); border-radius:5px; color:var(--fin-ink-2); background:#fff; font-size:12px; font-weight:600; cursor:pointer; transition:background .15s ease,border-color .15s ease,color .15s ease; }
.csr-export-toolbar button:first-child { color:#fff; background:var(--fin-teal); border-color:var(--fin-teal); }
.csr-export-toolbar button:first-child:hover { background:#115e59; border-color:#115e59; }
.csr-export-toolbar button:not(:first-child):hover { color:var(--fin-teal); background:#f0fdfa; border-color:var(--fin-teal); }
.csr-export-toolbar > span { margin-left:auto !important; display:flex; align-items:center; gap:8px; }
.csr-export-toolbar select { min-height:34px; padding:0 10px !important; border:1px solid var(--fin-line); border-radius:5px; color:var(--fin-ink); background:#fff; font:inherit; }
.csr-dashboard-prime { margin-top:0; border:1px solid var(--fin-line); border-top:3px solid var(--fin-teal); border-radius:9px; box-shadow:0 3px 12px rgba(15,23,42,.05); overflow:hidden; }
.csr-dashboard-prime-item { padding:20px 22px; background:#fff; }
.csr-dashboard-prime-item + .csr-dashboard-prime-item { border-left:1px solid var(--fin-line); }
.csr-dashboard-prime .csr-dashboard-label { display:flex; align-items:center; gap:8px; margin:0 0 12px; color:var(--fin-ink-2); font-size:12px; font-weight:700; letter-spacing:.7px; text-transform:uppercase; }
.csr-dashboard-prime .csr-dashboard-label::before { content:""; width:7px; height:7px; flex:0 0 7px; border-radius:50%; background:#0f766e; }
.csr-dashboard-prime .csr-dashboard-prime-item:nth-child(2) .csr-dashboard-label::before { background:var(--fin-teal); }
.csr-dashboard-prime .csr-dashboard-prime-item:nth-child(3) .csr-dashboard-label::before { background:var(--fin-teal); }
.csr-dashboard-prime .csr-dashboard-value { color:var(--fin-ink); font-size:clamp(26px,2.4vw,34px); font-weight:700; letter-spacing:-.5px; font-variant-numeric:tabular-nums; }
.csr-dashboard-balance { margin-top:10px; padding-top:9px; border-top:1px solid #eef2f6; color:var(--fin-muted); font-size:12px; }
.csr-dashboard-balance b { color:var(--fin-teal); font-size:14px; font-weight:700; font-variant-numeric:tabular-nums; }
.csr-dashboard-subline { align-items:baseline; margin:0; padding:7px 0; border-bottom:1px solid var(--fin-line-soft); color:#64748b; font-size:12px; line-height:1.4; }
.csr-dashboard-subline:last-of-type { border-bottom:0; }
.csr-dashboard-subline b { color:var(--fin-ink); font-size:12px; font-weight:600; font-variant-numeric:tabular-nums; }
.csr-letter-summary { margin-top:18px; padding:16px 18px; border-color:var(--fin-line); border-radius:9px; box-shadow:0 3px 12px rgba(15,23,42,.05); }
.csr-letter-card-title { margin-bottom:12px; font-size:15px; letter-spacing:-.1px; }
.csr-letter-filter select { min-width:min(460px,75vw); height:38px; border-color:#cbd5e1; border-radius:5px; }
.csr-letter-filter select:focus, .csr-export-toolbar select:focus { outline:0; border-color:var(--fin-teal); box-shadow:0 0 0 3px rgba(15,118,110,.12); }
.csr-letter-status { min-height:0; margin:0 0 8px; }
.csr-pdf-list { padding-top:11px; border-top:1px solid #eef2f6; }
.csr-pdf-link { min-width:190px; padding:9px 11px; border-color:var(--fin-line); border-radius:6px; font-size:12px; font-weight:600; transition:background .15s ease,border-color .15s ease; }
.csr-pdf-link:hover { border-color:var(--fin-teal); }
.csr-co-card { margin-top:18px; border-color:var(--fin-line); border-radius:9px; box-shadow:0 3px 12px rgba(15,23,42,.05); }
.csr-co-card .csr-card-head { min-height:44px; padding:12px 16px; background:var(--fin-head); }
.csr-co-card .csr-card-title { font-size:14px; letter-spacing:-.1px; }
.csr-co-table { min-width:100%; }
.csr-co-table th { padding:9px 10px !important; color:var(--fin-ink-2) !important; background:var(--fin-head) !important; font-size:10px !important; letter-spacing:.55px !important; }
.csr-co-table td { padding:8px 10px !important; line-height:1.4 !important; }
.csr-co-table tbody tr.csr-row:hover td { background:#f0fdfa !important; }
.csr-co-table td.csr-num { color:var(--fin-ink); font-variant-numeric:tabular-nums; }
.csr-co-table tr.csr-co-total td { background:var(--fin-head) !important; border-top:2px solid #cbd5e1 !important; }
.csr-co-table td.csr-co-neg, .csr-co-table td.csr-cum-neg { color:#b91c1c; }
.csr-co-note { padding:9px 16px 12px; font-size:11.5px; line-height:1.5; }
.csr-co-fy { font-weight:600; }
.csr-co-fy select { height:34px; padding:0 9px; border-color:#cbd5e1; border-radius:5px; }
.csr-co-fy select:focus { outline:0; border-color:var(--fin-teal); box-shadow:0 0 0 3px rgba(15,118,110,.12); }
.csr-pj-table { min-width:1080px; }
.csr-co-card .csr-table-wrap { overflow-x:auto; scrollbar-color:#cbd5e1 #f8fafc; }
.csr-export-toolbar button:focus-visible, .csr-pdf-link:focus-visible, .csr-co-table a:focus-visible { outline:3px solid rgba(15,118,110,.28); outline-offset:2px; }
.csr-dashboard-label {
  margin-bottom: 7px;
  color: var(--fin-muted);
  font-size: 12px;
  font-weight: 600;
  letter-spacing: .5px;
  text-transform: uppercase;
}
.csr-dashboard-value {
  color: var(--fin-ink);
  font-size: clamp(22px, 2vw, 28px);
  font-weight: 700;
  line-height: 1.2;
  overflow-wrap: anywhere;
}
.csr-dashboard-prime { display:grid; grid-template-columns:repeat(3,minmax(0,1fr)); width:100%; box-sizing:border-box; margin-top:10px; background:#fff; border:1px solid var(--fin-line); border-top:2px solid var(--fin-teal); border-radius:7px; box-shadow:0 1px 2px rgba(15,23,42,.05); }
.csr-dashboard-prime-item { min-width:0; padding:16px 20px; }
.csr-dashboard-prime-item + .csr-dashboard-prime-item { border-left:1px solid var(--fin-line); }
.csr-dashboard-prime .csr-dashboard-label { margin:0 0 7px; color:var(--fin-muted); font-size:13px; line-height:1.4; }
.csr-dashboard-prime .csr-dashboard-value { font-size:clamp(23px,2.2vw,30px); line-height:1.25; }
.csr-dashboard-balance { margin-top:7px; color:var(--fin-muted); font-size:13px; line-height:1.4; }
.csr-dashboard-subline { display:flex; justify-content:space-between; gap:10px; margin-top:6px; color:var(--fin-muted); font-size:13px; line-height:1.4; }
.csr-dashboard-subline b { color:var(--fin-ink); font-weight:600; text-align:right; }
.csr-letter-summary { margin-top:14px; padding:14px 16px; background:#fff; border:1px solid var(--fin-line); border-radius:7px; box-shadow:0 1px 2px rgba(15,23,42,.05); }
.csr-letter-summary .csr-dashboard-prime { margin-top:8px; border:0; border-top:1px solid var(--fin-line); border-radius:0; box-shadow:none; }
.csr-letter-filter { display:flex; flex-wrap:wrap; align-items:end; gap:8px; margin-bottom:10px; }
.csr-letter-filter label { display:flex; flex-direction:column; gap:4px; color:var(--fin-muted); font-size:12px; font-weight:600; }
.csr-letter-filter select { min-width:min(420px,75vw); height:34px; padding:0 9px; border:1px solid var(--fin-line); border-radius:4px; color:var(--fin-ink); background:#fff; font:inherit; }
.csr-letter-card-title { margin:0 0 9px; color:var(--fin-ink); font-size:14px; font-weight:600; }
.csr-letter-status { min-height:18px; margin:2px 0 8px; color:var(--fin-muted); font-size:12px; }
.csr-pdf-list { display:flex; flex-wrap:wrap; gap:8px; margin-top:12px; }
.csr-pdf-link { display:flex; flex-direction:column; gap:2px; min-width:160px; max-width:280px; padding:8px 10px; border:1px solid var(--fin-line); border-radius:5px; color:var(--fin-teal); text-decoration:none; background:#fff; }
.csr-pdf-link:hover { background:#f0fdfa; border-color:var(--fin-teal); }
.csr-pdf-link small { color:var(--fin-muted); font-size:10px; overflow-wrap:anywhere; }
.csr-co-card { margin-top:14px; background:#fff; border:1px solid var(--fin-line); border-radius:7px; box-shadow:0 1px 2px rgba(15,23,42,.05); }
.csr-co-card .csr-card-head { padding:10px 14px; border-bottom:1px solid var(--fin-line); }
.csr-co-table td.csr-num, .csr-co-table th.csr-num { text-align:right; white-space:nowrap; }
.csr-co-table th { white-space:normal; line-height:1.25; vertical-align:bottom; }
.csr-co-table tr.csr-co-total td { font-weight:700; background:#f8fafc; border-top:2px solid #cbd5e1; }
.csr-co-table .csr-co-neg { color:#b91c1c; }
.csr-co-table td.csr-cum-neg { background:#fde4d8; color:#b91c1c; }
.csr-co-table a.dd-link { color:inherit; text-decoration:none; border-bottom:1px dashed #0f766e; }
.csr-co-table a.dd-link:hover { color:#0f766e; background:#f0fdfa; }
.dd-modal { position:fixed; inset:0; z-index:2000; display:none; align-items:flex-start; justify-content:center; padding:60px 16px 20px; background:rgba(15,23,42,.45); }
.dd-modal.open { display:flex; }
.dd-box { width:min(1320px,100%); max-height:calc(100vh - 90px); display:flex; flex-direction:column; background:#fff; border-radius:7px; box-shadow:0 10px 30px rgba(15,23,42,.25); }
.dd-head { display:flex; justify-content:space-between; align-items:center; gap:10px; padding:10px 14px; border-bottom:1px solid var(--fin-line); }
.dd-title { font-size:14px; font-weight:600; color:var(--fin-ink); }
.dd-body { overflow:auto; padding:0 0 6px; }
.dd-body .csr-table td.n, .dd-body .csr-table th.n { text-align:right; white-space:nowrap; }
.dd-body .csr-table tfoot td { font-weight:700; background:#f8fafc; border-top:2px solid #cbd5e1; }
.dd-body .csr-table { width:100%; }
.dd-body .csr-table td { vertical-align:top; }
.dd-body .csr-table th { white-space:nowrap !important; }
.dd-body .csr-table td.n, .dd-body .csr-table td.d { white-space:nowrap !important; }
.dd-body .csr-table td.ma { white-space:normal !important; min-width:240px; max-width:420px; }
.dd-body .csr-table td.ma .ma-no { font-weight:600; color:var(--fin-ink); }
.dd-body .csr-table td.ma .ma-desc { margin-top:2px; font-size:11.5px; line-height:1.4; color:var(--fin-muted); }
.dd-body .csr-table td.t { white-space:normal !important; overflow-wrap:anywhere; min-width:150px; max-width:340px; overflow:visible !important; text-overflow:clip !important; }
.dd-msg { padding:16px 14px; color:var(--fin-muted); }
.csr-co-table td.csr-co-neg a.dd-link, .csr-co-table td.csr-cum-neg a.dd-link { color:#b91c1c !important; }
.csr-pj-table { table-layout:auto; }
.csr-pj-table th, .csr-pj-table td { padding-left:6px !important; padding-right:6px !important; }
.csr-pj-table th { white-space:normal !important; }
.csr-pj-table td.pj-unit { white-space:normal !important; min-width:80px; max-width:120px; }
.csr-pj-table td.pj-text { white-space:normal !important; min-width:130px; max-width:240px; }
.csr-pj-table .pj-desc { margin-top:2px; font-size:11px; line-height:1.35; color:var(--fin-muted); }
.csr-pj-st { display:inline-block; padding:1px 6px; border-radius:3px; font-size:10.5px; font-weight:600; line-height:1.3; border:1px solid; }
.csr-pj-st.s-ns { color:#64748b; background:#f8fafc; border-color:#e2e8f0; }
.csr-pj-st.s-wip { color:#b45309; background:#fffbeb; border-color:#fde68a; }
.csr-pj-st.s-done { color:#047857; background:#ecfdf5; border-color:#a7f3d0; }
.csr-pj-table td.pj-alert { white-space:normal !important; min-width:105px; max-width:140px; font-size:11.5px; line-height:1.35; font-weight:600; color:#b91c1c; }
.csr-pj-table td.pj-alert.ok { color:#047857; }
.csr-co-fy { display:flex; align-items:center; gap:8px; font-size:12px; color:var(--fin-muted); }
.csr-co-fy select { height:28px; padding:0 6px; border:1px solid var(--fin-line); border-radius:4px; font:inherit; color:var(--fin-ink); background:#fff; }
.csr-co-card .csr-card-head { display:flex; justify-content:space-between; align-items:center; gap:10px; flex-wrap:wrap; }
.csr-co-note { padding:8px 14px 10px; color:var(--fin-muted); font-size:11.5px; line-height:1.5; }
.csr-export-toolbar { display:flex; gap:8px; margin-bottom:14px; padding:0 0 10px; border-bottom:1px solid var(--fin-line); }
.csr-export-toolbar button { padding:8px 12px; border:1px solid var(--fin-line); background:#fff; color:var(--fin-ink); font-size:12px; font-weight:600; border-radius:4px; cursor:pointer; }
.csr-export-toolbar button:hover { background:var(--fin-head); border-color:#cbd5e1; }

@media print {
  body { background:#fff; color:#000; font-size:10pt; }
  .csr-page { max-width:100%; padding:0; }
  .csr-header, .csr-export-toolbar, .csr-letter-summary, .dd-modal, .csr-dashboard-prime { display:none !important; }
  .csr-co-card { page-break-inside:avoid; margin-bottom:20px; border:1px solid #000; }
  .csr-co-card .csr-card-head { background:#f5f5f5; border-bottom:1px solid #000; padding:8px; font-weight:bold; }
  .csr-co-table { width:100%; border-collapse:collapse; font-size:9pt; }
  .csr-co-table th, .csr-co-table td { border:1px solid #000; padding:4px; text-align:left; }
  .csr-co-table th { background:#f5f5f5; font-weight:bold; }
  .csr-co-table .csr-num { text-align:right; }
  .csr-co-table tr.csr-co-total { font-weight:bold; background:#f5f5f5; }
  .csr-co-table a { color:#000; text-decoration:none; }
  @page { size:A4; margin:10mm; }
}
@media (max-width: 900px) {
  .csr-dashboard-prime { grid-template-columns:repeat(2,minmax(0,1fr)); }
  .csr-dashboard-prime-item:nth-child(3) { grid-column:1 / -1; border-left:0; border-top:1px solid var(--fin-line); }
}
@media (max-width: 560px) {
  .csr-dashboard-prime { grid-template-columns:1fr; }
  .csr-dashboard-prime-item + .csr-dashboard-prime-item { border-left:0; border-top:1px solid var(--fin-line); }
  .csr-dashboard-prime-item:nth-child(3) { grid-column:auto; }
}
/* Final dashboard theme overrides */
body { background:var(--fin-head); color:var(--fin-ink); }
.csr-page { max-width:none !important; padding:18px 22px !important; }
.csr-export-toolbar { align-items:center; flex-wrap:wrap; margin:0 0 12px; padding:7px 9px; background:#fff; border:1px solid var(--fin-line); border-radius:6px; box-shadow:none; }
.csr-export-toolbar button { min-height:34px; padding:0 14px; border:1px solid var(--fin-line); border-radius:4px; color:var(--fin-ink); background:#fff; font-weight:600; }
.csr-export-toolbar button:first-child { color:#fff; background:var(--fin-teal); border-color:var(--fin-teal); }
.csr-export-toolbar button:first-child:hover { background:#115e59; border-color:#115e59; }
.csr-export-toolbar button:not(:first-child):hover { color:#115e59; background:var(--fin-head); border-color:var(--fin-teal); }
.csr-dashboard-prime { margin-top:0; border:1px solid var(--fin-line); border-top:3px solid var(--fin-teal); border-radius:6px; box-shadow:0 1px 2px rgba(15,23,42,.05); overflow:hidden; }
.csr-dashboard-prime-item { padding:14px 16px; background:#fff; }
.csr-dashboard-prime-item + .csr-dashboard-prime-item { border-left:1px solid var(--fin-line); }
.csr-dashboard-prime .csr-dashboard-label { display:flex; align-items:center; gap:8px; margin:0 0 12px; color:var(--fin-ink-2); font-size:12px; font-weight:700; letter-spacing:.65px; text-transform:uppercase; }
.csr-dashboard-prime .csr-dashboard-label::before { content:""; width:3px; height:16px; flex:0 0 3px; border-radius:1px; background:var(--fin-teal); }
.csr-dashboard-prime .csr-dashboard-prime-item:nth-child(2) .csr-dashboard-label::before,
.csr-dashboard-prime .csr-dashboard-prime-item:nth-child(3) .csr-dashboard-label::before { background:var(--fin-teal); }
.csr-dashboard-prime .csr-dashboard-value { color:var(--fin-ink); font-size:clamp(26px,2.4vw,34px); font-weight:700; letter-spacing:-.35px; font-variant-numeric:tabular-nums; }
.csr-dashboard-subline { align-items:baseline; margin:0; padding:7px 0; border-bottom:1px solid var(--fin-head); color:var(--fin-muted); font-size:12px; line-height:1.45; }
.csr-dashboard-subline b { color:var(--fin-ink); font-size:12px; font-weight:600; font-variant-numeric:tabular-nums; }
.csr-dashboard-balance { margin-top:10px; padding-top:9px; border-top:1px solid var(--fin-line); color:var(--fin-muted); font-size:12px; }
.csr-dashboard-balance b { color:#115e59; font-size:14px; font-weight:700; font-variant-numeric:tabular-nums; }
.csr-letter-summary, .csr-co-card { border-color:var(--fin-line); border-radius:6px; box-shadow:0 1px 2px rgba(15,23,42,.05); }
.csr-letter-summary { margin-top:12px; padding:10px 12px; }
.csr-letter-card-title { color:var(--fin-ink); font-size:15px; font-weight:700; }
.csr-co-card { margin-top:12px; overflow:hidden; }
.csr-co-card .csr-card-head { min-height:38px; padding:8px 12px; background:var(--fin-head); }
.csr-co-card .csr-card-title { color:var(--fin-ink); font-size:14px; font-weight:700; letter-spacing:0; }
.csr-co-table th { padding:6px 8px !important; color:var(--fin-ink-2) !important; background:var(--fin-head) !important; font-size:10px !important; letter-spacing:.45px !important; }
.csr-co-table td { padding:5px 8px !important; line-height:1.35 !important; }
.csr-co-table tbody tr.csr-row:hover td { background:#f0fdfa !important; }
.csr-co-table td.csr-num { color:var(--fin-ink); font-variant-numeric:tabular-nums; }
.csr-co-table tr.csr-co-total td { background:var(--fin-head) !important; border-top:2px solid #cbd5e1 !important; }
.csr-co-note { padding:9px 16px 12px; color:var(--fin-muted); font-size:11.5px; line-height:1.5; }
.csr-co-table a.dd-link { border-bottom-color:var(--fin-teal); }
.csr-co-table a.dd-link:hover { color:#115e59; background:#f0fdfa; }
.csr-letter-filter select { border-color:var(--fin-line); border-radius:4px; }
.csr-letter-filter select:focus, .csr-co-fy select:focus, .csr-export-toolbar select:focus { outline:0; border-color:var(--fin-teal); box-shadow:0 0 0 1px var(--fin-teal); }
.csr-pdf-link { border-color:var(--fin-line); border-radius:4px; color:var(--fin-teal); }
.csr-pdf-link:hover { background:#f0fdfa; border-color:var(--fin-teal); }
.csr-co-card .csr-table-wrap { overflow-x:auto; scrollbar-color:#cbd5e1 #f8fafc; }
.csr-position-grid { display:block; }
body.report-abstract .csr-position-grid { display:grid; grid-template-columns:minmax(0,1fr); align-items:start; gap:4px; }
body.report-abstract .csr-position-grid .csr-co-card { min-width:0; margin-top:12px; }
body.report-abstract .csr-position-grid .csr-co-card { border-top:2px solid var(--fin-teal); box-shadow:0 1px 3px rgba(15,23,42,.07); }
body.report-abstract .csr-position-grid .csr-card-head { min-height:42px; padding:9px 12px; background:#fff; }
body.report-abstract .csr-position-grid .csr-card-title { font-size:13px; font-weight:700; }
body.report-abstract .csr-position-grid .csr-table-wrap { padding:0 8px 8px; }
body.report-abstract .csr-position-grid .csr-co-table { border-collapse:separate; border-spacing:0; }
body.report-abstract .csr-position-grid .csr-co-table thead th { padding:7px 7px !important; border-bottom:1px solid var(--fin-line); white-space:nowrap; }
body.report-abstract .csr-position-grid .csr-co-table tbody td { padding:7px !important; border-bottom:1px solid var(--fin-line-soft); background:#fff; }
body.report-abstract .csr-position-grid .csr-co-table tbody tr:last-child td { border-bottom:0; }
body.report-abstract .csr-position-grid .csr-co-table tbody td:first-child { color:var(--fin-ink); font-weight:600; }
body.report-abstract .csr-position-grid .csr-co-table tbody tr.csr-co-total td { background:var(--fin-head) !important; border-top:1px solid var(--fin-line); color:var(--fin-ink); font-weight:700; }
body.report-abstract .csr-position-grid .csr-co-table td.csr-num { font-size:11px; }
.csr-export-toolbar button:focus-visible, .csr-pdf-link:focus-visible, .csr-co-table a:focus-visible { outline:2px solid var(--fin-teal); outline-offset:2px; }
@media (max-width:900px) {
  .csr-dashboard-prime-item { padding:17px; }
  .csr-co-fy { flex-wrap:wrap; }
}
@media (max-width:560px) {
  .csr-page { padding:10px 12px !important; }
  .csr-dashboard-prime-item { padding:12px; }
  .csr-export-toolbar > span { margin-left:0 !important; width:100%; }
  .csr-letter-summary { padding:13px; }
  .csr-letter-filter select { min-width:0; width:100%; }
  .csr-letter-filter label { width:100%; }
  .csr-co-card .csr-card-head { align-items:flex-start; }
  body.report-abstract .csr-position-grid { grid-template-columns:1fr; }
}
/* Abstract Report Mode */
body.report-abstract .csr-co-table th:nth-child(8),
body.report-abstract .csr-co-table td:nth-child(8),
body.report-abstract .csr-co-table th:nth-child(9),
body.report-abstract .csr-co-table td:nth-child(9),
body.report-abstract .csr-co-table th:nth-child(10),
body.report-abstract .csr-co-table td:nth-child(10) {
  display: none;
}
body.report-abstract #monthPosition {
  display: none;
}
</style>
</head>
<body>
<div class="csr-page">
  <div class="csr-header">
    <div>
      <div class="csr-subtitle"><%= com.Bean.AppConfig.code() %> CSR Amount Spending</div>
      <h1 class="csr-title">Dashboard</h1>
    </div>
  </div>

  <div class="csr-export-toolbar">
    <button type="button" id="btnExcelExport" onclick="exportDashboardToExcel();">Export to Excel</button>
    <button type="button" id="btnPdfExport" onclick="exportDashboardToPdf();">Export to PDF</button>
    <button type="button" id="btnPrint" onclick="window.print();">Print</button>
    <span style="margin-left: auto; display: flex; align-items: center; gap: 8px;">
      <label style="color: var(--fin-muted); font-size: 12px; font-weight: 600; margin: 0;">Report Type:</label>
      <select id="reportTypeSelect" onchange="switchReportType(this.value);" style="height: 34px; padding: 0 9px; border: 1px solid var(--fin-line); border-radius: 4px; color: var(--fin-ink); background: #fff; font: inherit; cursor: pointer;">
        <option value="detailed" selected>Detailed</option>
        <option value="abstract">Abstract</option>
      </select>
    </span>
  </div>

  <% if (loadError != null) { %>
  <div class="csr-alert csr-alert-err" role="alert"><%= loadError %></div>
  <% } %>

  <section class="csr-dashboard-prime" aria-label="Key CSR position">
    <div class="csr-dashboard-prime-item">
      <div class="csr-dashboard-label">Approved Budget</div>
      <div class="csr-dashboard-value"><%= stats.getOrDefault("approvedAmount", "₹0.00") %></div>
      <div class="csr-dashboard-balance">Balance: <b><%= stats.getOrDefault("workOrderBalance", "₹0.00") %></b></div>
    </div>
    <div class="csr-dashboard-prime-item">
      <div class="csr-dashboard-label">Work Orders Raised</div>
      <div class="csr-dashboard-subline"><span>Work orders</span><b><%= stats.getOrDefault("workOrderCount", "0") %> nos. · <%= stats.getOrDefault("workOrderAmount", "₹0.00") %></b></div>
      <div class="csr-dashboard-subline"><span>Tax invoices raised</span><b><%= stats.getOrDefault("taxInvoiceCount", "0") %> nos. · <%= stats.getOrDefault("taxInvoiceAmount", "₹0.00") %></b></div>
      <div class="csr-dashboard-subline"><span>Payments done</span><b><%= stats.getOrDefault("paymentCount", "0") %> nos. · <%= stats.getOrDefault("paymentAmount", "₹0.00") %></b></div>
      <div class="csr-dashboard-subline"><span>Balance to pay</span><b><%= stats.getOrDefault("balanceInvoiceCount", "0") %> nos. · <%= stats.getOrDefault("balanceToPay", "₹0.00") %></b></div>
    </div>
    <div class="csr-dashboard-prime-item">
      <div class="csr-dashboard-label">Funds Received</div>
      <div class="csr-dashboard-subline"><span>FRLs Raised</span><b><%= stats.getOrDefault("frlAmount", "₹0.00") %> · <%= stats.getOrDefault("frlCount", "0") %> nos.</b></div>
      <div class="csr-dashboard-subline"><span>FRLs Received</span><b><%= stats.getOrDefault("frlReceivedAmount", "₹0.00") %> · <%= stats.getOrDefault("frlReceivedCount", "0") %> nos.</b></div>
      <div class="csr-dashboard-balance">Balance to receive: <b><%= stats.getOrDefault("fundsBalance", "₹0.00") %></b></div>
    </div>
  </section>
  <div class="csr-position-grid">
  <%-- Company-wise and Unit-wise Position (unit = Kind of CSR Activity of the approval): same columns and formulas --%>
  <% Object[][] positions = { { "co", "Company-wise Position", "Company", companyPosition },
                              { "unit", "Unit / Institution-wise Position", "Unit", unitPosition } };
     for (Object[] pos : positions) {
       @SuppressWarnings("unchecked")
       List<Map<String, String>> posRows = (List<Map<String, String>>) pos[3]; %>
  <section class="csr-co-card" aria-labelledby="<%= pos[0] %>-title" id="<%= pos[0] %>Position">
    <div class="csr-card-head"><div class="csr-card-title" id="<%= pos[0] %>-title"><%= pos[1] %> <span class="csr-small">(&#8377;)</span></div></div>
    <% if (companyError != null) { %>
    <div class="csr-alert csr-alert-err" style="margin:10px 14px;"><%= escapeHtml(companyError) %></div>
    <% } else if (posRows != null) { %>
    <div class="csr-table-wrap">
      <table class="csr-table csr-co-table">
        <thead>
          <tr>
            <th><%= pos[2] %></th>
            <th class="csr-num">Projects</th>
            <th class="csr-num">Approved</th>
            <th class="csr-num">Received</th>
            <th class="csr-num">Yet to Receive</th>
            <th class="csr-num">Utilised</th>
            <th class="csr-num">Unspent with <%= escapeHtml(instCodeD) %></th>
            <th class="csr-num">Retention Held</th>
            <th class="csr-num">Bills Unpaid</th>
            <th class="csr-num">Free Balance</th>
            <th class="csr-num">Utilisation %</th>
          </tr>
        </thead>
        <tbody>
          <% for (Map<String, String> c : posRows) {
               boolean tot = "1".equals(c.get("total"));
               String cid = c.get("companyId");
               String vw = (String) pos[0];
               String k = tot ? "all" : ("co".equals(vw) ? (cid == null || cid.isEmpty() ? "0" : cid) : c.get("name")); %>
          <tr class="<%= tot ? "csr-co-total" : "csr-row" %>">
            <td><% if (!tot && cid != null && !cid.isEmpty() && !"0".equals(c.get("projects"))) { %><a class="csr-open" href="CsrLetterServlet?companyId=<%= escapeHtml(cid) %>"><%= escapeHtml(c.get("name")) %></a><% } else { %><%= escapeHtml(c.get("name")) %><% } %></td>
            <td class="csr-num"><%= dl(c.get("projects"), vw, k, "projects", null) %></td>
            <td class="csr-num"><%= dl(c.get("approved"), vw, k, "approved", null) %></td>
            <td class="csr-num"><%= dl(c.get("received"), vw, k, "received", null) %></td>
            <td class="csr-num"><%= dl(c.get("yetToReceive"), vw, k, "yetToReceive", null) %></td>
            <td class="csr-num"><%= dl(c.get("utilised"), vw, k, "utilised", null) %></td>
            <td class="csr-num <%= "1".equals(c.get("unspentNeg")) ? "csr-co-neg" : "" %>"><%= dl(c.get("unspent"), vw, k, "unspent", null) %></td>
            <td class="csr-num"><%= dl(c.get("retention"), vw, k, "retention", null) %></td>
            <td class="csr-num"><%= dl(c.get("unpaid"), vw, k, "unpaid", null) %></td>
            <td class="csr-num <%= "1".equals(c.get("freeNeg")) ? "csr-co-neg" : "" %>"><%= dl(c.get("free"), vw, k, "free", null) %></td>
            <td class="csr-num"><%= dl(c.get("utilisation"), vw, k, "utilisation", null) %></td>
          </tr>
          <% } %>
          <% if (posRows.size() == 1) { %>
          <tr><td colspan="11" class="csr-empty">No Management Approvals yet.</td></tr>
          <% } %>
        </tbody>
      </table>
    </div>
    <% } %>
  </section>
  <% if (companyError != null) break; } %>
  </div>

  <% if (monthly != null) { %>
  <section class="csr-co-card" aria-labelledby="month-title" id="monthPosition">
    <div class="csr-card-head">
      <div class="csr-card-title" id="month-title">Month-wise Receipts vs Utilisation <span class="csr-small">(&#8377;)</span></div>
      <label class="csr-co-fy" for="fySelect">Financial year
        <select id="fySelect">
          <% for (String[] y : monthlyYears) { %>
          <option value="<%= y[0] %>" <%= y[0].equals(monthlyFy) ? "selected" : "" %>><%= y[1] %></option>
          <% } %>
        </select>
        <span>starts <b><%= request.getAttribute("monthlyFyStart") %></b></span>
      </label>
    </div>
    <div class="csr-table-wrap">
      <table class="csr-table csr-co-table">
        <thead>
          <tr>
            <th>Month</th>
            <th class="csr-num">Received from Company</th>
            <th class="csr-num">Net Paid to Vendors</th>
            <th class="csr-num">TDS Deducted</th>
            <th class="csr-num">Total Utilised</th>
            <th class="csr-num">Net Flow</th>
            <th class="csr-num">Cumulative Unspent</th>
          </tr>
        </thead>
        <tbody>
          <% for (Map<String, String> mrow : monthly) { boolean tot = "1".equals(mrow.get("total")); String mk = mrow.get("key"); %>
          <tr class="<%= tot ? "csr-co-total" : "csr-row" %>">
            <td><%= mrow.get("month") %></td>
            <td class="csr-num"><%= dl(mrow.get("received"), "month", mk, "received", monthlyFy) %></td>
            <td class="csr-num"><%= dl(mrow.get("paid"), "month", mk, "paid", monthlyFy) %></td>
            <td class="csr-num"><%= dl(mrow.get("tds"), "month", mk, "tds", monthlyFy) %></td>
            <td class="csr-num"><%= dl(mrow.get("utilised"), "month", mk, "utilised", monthlyFy) %></td>
            <td class="csr-num <%= "1".equals(mrow.get("flowNeg")) ? "csr-co-neg" : "" %>"><%= dl(mrow.get("flow"), "month", mk, "flow", monthlyFy) %></td>
            <td class="csr-num <%= "1".equals(mrow.get("cumNeg")) ? "csr-cum-neg" : "" %>"><%= dl(mrow.get("cumulative"), "month", mk, "cumulative", monthlyFy) %></td>
          </tr>
          <% } %>
        </tbody>
      </table>
    </div>
  </section>
  <% } %>

  <section class="csr-letter-summary" aria-labelledby="letter-summary-title">
    <h2 class="csr-letter-card-title" id="letter-summary-title">Approval-wise Summary</h2>
    <div class="csr-letter-filter">
      <label for="letterId">Management Approval
        <select id="letterId" name="letterId">
          <option value="">Select a Management Approval</option>
          <% if (approvalLetters != null) { for (Map<String, String> letter : approvalLetters) {
               String id = letter.get("id");
               String label = (letter.get("number") == null ? "" : letter.get("number"))
                       + (letter.get("name") == null || letter.get("name").isEmpty() ? "" : " — " + letter.get("name")); %>
          <option value="<%= escapeHtml(id) %>" <%= id.equals(selectedLetterId) ? "selected" : "" %>><%= escapeHtml(label) %></option>
          <% } } %>
        </select>
      </label>
    </div>
    <div class="csr-letter-status" id="letterSummaryStatus" aria-live="polite"><%= letterStats == null || letterStats.isEmpty() ? "Choose an approval to load its summary and PDFs." : "" %></div>
    <div id="letterStatsSummary" <%= letterStats == null || letterStats.isEmpty() ? "hidden" : "" %>>
    <div class="csr-dashboard-prime" aria-label="Selected Management Approval summary">
      <div class="csr-dashboard-prime-item">
        <div class="csr-dashboard-label">Approved Budget</div>
        <div class="csr-dashboard-value" id="letterApprovedAmount"><%= letterStats == null ? "₹0.00" : letterStats.getOrDefault("approvedAmount", "₹0.00") %></div>
        <div class="csr-dashboard-balance">Balance: <b id="letterWorkOrderBalance"><%= letterStats == null ? "₹0.00" : letterStats.getOrDefault("workOrderBalance", "₹0.00") %></b></div>
      </div>
      <div class="csr-dashboard-prime-item">
        <div class="csr-dashboard-label">Work Orders Raised</div>
        <div class="csr-dashboard-subline"><span>Work orders</span><b id="letterWorkOrderSummary"><%= letterStats == null ? "0 nos. · ₹0.00" : letterStats.getOrDefault("workOrderCount", "0") + " nos. · " + letterStats.getOrDefault("workOrderAmount", "₹0.00") %></b></div>
        <div class="csr-dashboard-subline"><span>Tax invoices raised</span><b id="letterInvoiceSummary"><%= letterStats == null ? "0 nos. · ₹0.00" : letterStats.getOrDefault("taxInvoiceCount", "0") + " nos. · " + letterStats.getOrDefault("taxInvoiceAmount", "₹0.00") %></b></div>
        <div class="csr-dashboard-subline"><span>Payments done</span><b id="letterPaymentSummary"><%= letterStats == null ? "0 nos. · ₹0.00" : letterStats.getOrDefault("paymentCount", "0") + " nos. · " + letterStats.getOrDefault("paymentAmount", "₹0.00") %></b></div>
        <div class="csr-dashboard-subline"><span>Balance to pay</span><b id="letterBalanceToPaySummary"><%= letterStats == null ? "0 nos. · ₹0.00" : letterStats.getOrDefault("balanceInvoiceCount", "0") + " nos. · " + letterStats.getOrDefault("balanceToPay", "₹0.00") %></b></div>
      </div>
      <div class="csr-dashboard-prime-item">
        <div class="csr-dashboard-label">Funds Received</div>
        <div class="csr-dashboard-subline"><span>FRLs Raised</span><b id="letterFrlRaisedSummary"><%= letterStats == null ? "₹0.00 · 0 nos." : letterStats.getOrDefault("frlAmount", "₹0.00") + " · " + letterStats.getOrDefault("frlCount", "0") + " nos." %></b></div>
        <div class="csr-dashboard-subline"><span>FRLs Received</span><b id="letterFrlReceivedSummary"><%= letterStats == null ? "₹0.00 · 0 nos." : letterStats.getOrDefault("frlReceivedAmount", "₹0.00") + " · " + letterStats.getOrDefault("frlReceivedCount", "0") + " nos." %></b></div>
        <div class="csr-dashboard-balance">Balance to receive: <b id="letterFundsBalance"><%= letterStats == null ? "₹0.00" : letterStats.getOrDefault("fundsBalance", "₹0.00") %></b></div>
      </div>
    </div>
    <div id="letterPdfList" class="csr-pdf-list" aria-label="Approval PDFs"></div>
    </div>
  </section>
</div>

<div class="dd-modal" id="ddModal" role="dialog" aria-modal="true" aria-labelledby="ddTitle">
  <div class="dd-box">
    <div class="dd-head">
      <div class="dd-title" id="ddTitle"></div>
      <button type="button" class="csr-btn csr-btn-sm csr-btn-outline" id="ddClose">Close</button>
    </div>
    <div class="dd-body" id="ddBody"></div>
  </div>
</div>
<script>
(function () {
  var select = document.getElementById('letterId');
  var summary = document.getElementById('letterStatsSummary');
  var status = document.getElementById('letterSummaryStatus');
  var pdfList = document.getElementById('letterPdfList');
  function text(id, value) { document.getElementById(id).textContent = value || '0'; }
  function showStats(s) {
    text('letterApprovedAmount', s.approvedAmount);
    text('letterWorkOrderBalance', s.workOrderBalance);
    text('letterWorkOrderSummary', s.workOrderCount + ' nos. · ' + s.workOrderAmount);
    text('letterInvoiceSummary', s.taxInvoiceCount + ' nos. · ' + s.taxInvoiceAmount);
    text('letterPaymentSummary', s.paymentCount + ' nos. · ' + s.paymentAmount);
    text('letterBalanceToPaySummary', s.balanceInvoiceCount + ' nos. · ' + s.balanceToPay);
    text('letterFrlRaisedSummary', s.frlAmount + ' · ' + s.frlCount + ' nos.');
    text('letterFrlReceivedSummary', s.frlReceivedAmount + ' · ' + s.frlReceivedCount + ' nos.');
    text('letterFundsBalance', s.fundsBalance);
  }
  function showPdfs(pdfs) {
    pdfList.replaceChildren();
    if (!pdfs || !pdfs.length) {
      var empty = document.createElement('span');
      empty.className = 'csr-dashboard-balance';
      empty.textContent = 'No PDF files attached to this Management Approval.';
      pdfList.appendChild(empty);
      return;
    }
    pdfs.forEach(function (pdf) {
      var link = document.createElement('a');
      link.className = 'csr-pdf-link';
      link.href = pdf.url;
      link.target = '_blank';
      link.rel = 'noopener';
      link.textContent = pdf.label || 'Open PDF';
      if (pdf.fileName) {
        var name = document.createElement('small');
        name.textContent = pdf.fileName;
        link.appendChild(name);
      }
      pdfList.appendChild(link);
    });
  }
  function loadApproval() {
    var id = select.value;
    pdfList.replaceChildren();
    if (!id) {
      summary.hidden = true;
      status.textContent = 'Choose an approval to load its summary and PDFs.';
      return;
    }
    status.textContent = 'Loading approval details…';
    fetch('CsrDashboardServlet?action=letterData&letterId=' + encodeURIComponent(id), { headers: { 'Accept': 'application/json' } })
      .then(function (response) { return response.json().then(function (data) { if (!response.ok) throw new Error(data.message || 'Could not load approval details.'); return data; }); })
      .then(function (data) {
        if (!data.ok) throw new Error(data.message || 'Could not load approval details.');
        showStats(data.stats);
        showPdfs(data.pdfs);
        summary.hidden = false;
        status.textContent = '';
      })
      .catch(function (error) {
        summary.hidden = true;
        status.textContent = error.message || 'Approval details could not be loaded.';
      });
  }
  select.addEventListener('change', loadApproval);

  // ---- amount popups: CsrDashboardServlet?action=detail&view=&key=&col=[&fy=]
  var modal = document.getElementById('ddModal'), ddTitle = document.getElementById('ddTitle'), ddBody = document.getElementById('ddBody');
  function el(tag, cls, txt) { var e = document.createElement(tag); if (cls) e.className = cls; if (txt != null) e.textContent = txt; return e; }
  function closeDd() { modal.classList.remove('open'); }
  // n = amount (right, one line), d = date / month / short code (one line), t = text (wraps)
  function cellClass(d, i, v) {
    if (d.num[i]) return 'n';
    return (v == null || v.length <= 14 || /^\d{2}-\d{2}-\d{4}$/.test(v)) ? 'd' : 't';
  }
  function showDd(d) {
    ddTitle.textContent = d.title;
    ddBody.replaceChildren();
    if (!d.rows || !d.rows.length) { ddBody.appendChild(el('div', 'dd-msg', 'No entries.')); return; }
    // the Description column is shown as a second, smaller line under the Management Approval
    var di = d.cols.indexOf('Description'), ai = d.cols.indexOf('Management Approval');
    if (ai === -1) di = -1;
    var t = el('table', 'csr-table'), th = el('thead'), hr = el('tr'), tb = el('tbody');
    d.cols.forEach(function (c, i) { if (i !== di) hr.appendChild(el('th', d.num[i] ? 'n' : '', c)); });
    th.appendChild(hr); t.appendChild(th);
    d.rows.forEach(function (r) {
      var tr = el('tr');
      r.forEach(function (v, i) {
        if (i === di) return;
        if (i === ai) {
          var td = el('td', 'ma');
          td.appendChild(el('div', 'ma-no', v));
          if (di !== -1 && r[di]) td.appendChild(el('div', 'ma-desc', r[di]));
          tr.appendChild(td);
          return;
        }
        tr.appendChild(el('td', cellClass(d, i, v), v));
      });
      tb.appendChild(tr);
    });
    t.appendChild(tb);
    if (d.foot) {
      var tf = el('tfoot'), fr = el('tr');
      d.foot.forEach(function (v, i) { if (i !== di) fr.appendChild(el('td', i === ai ? 'ma' : cellClass(d, i, v), v)); });
      tf.appendChild(fr); t.appendChild(tf);
    }
    ddBody.appendChild(t);
  }
  document.addEventListener('click', function (e) {
    var a = e.target.closest ? e.target.closest('a.dd-link') : null;
    if (!a) return;
    e.preventDefault();
    var q = 'action=detail&view=' + encodeURIComponent(a.dataset.view) + '&key=' + encodeURIComponent(a.dataset.key)
          + '&col=' + encodeURIComponent(a.dataset.col) + (a.dataset.fy ? '&fy=' + encodeURIComponent(a.dataset.fy) : '');
    ddTitle.textContent = 'Loading...';
    ddBody.replaceChildren();
    modal.classList.add('open');
    fetch('CsrDashboardServlet?' + q, { headers: { 'Accept': 'application/json' } })
      .then(function (r) { return r.json(); })
      .then(function (d) {
        if (!d.ok) { ddTitle.textContent = 'Details'; ddBody.appendChild(el('div', 'dd-msg', d.message || 'Details could not be loaded.')); return; }
        showDd(d);
      })
      .catch(function () { ddTitle.textContent = 'Details'; ddBody.appendChild(el('div', 'dd-msg', 'Details could not be loaded. Please try again.')); });
  });
  document.getElementById('ddClose').addEventListener('click', closeDd);
  modal.addEventListener('click', function (e) { if (e.target === modal) closeDd(); });
  document.addEventListener('keydown', function (e) { if (e.key === 'Escape') closeDd(); });
  var fy = document.getElementById('fySelect');
  if (fy) fy.addEventListener('change', function () {
    location.href = 'CsrDashboardServlet?fy=' + encodeURIComponent(fy.value) + (select.value ? '&letterId=' + encodeURIComponent(select.value) : '') + '#monthPosition';
  });
  if (select.value) loadApproval();

  // Load Project Details
  // Switch between Abstract and Detailed reports
  window.switchReportType = function(reportType) {
    var body = document.body;
    if (reportType === 'abstract') {
      body.classList.add('report-abstract');
    } else {
      body.classList.remove('report-abstract');
    }
  };

  // Export functions
  window.exportDashboardToExcel = function() {
    var btn = document.getElementById('btnExcelExport');
    btn.disabled = true;
    btn.textContent = 'Exporting...';
    var form = document.createElement('form');
    form.method = 'POST';
    form.action = 'CsrDashboardServlet?action=exportExcel';
    document.body.appendChild(form);
    form.submit();
    document.body.removeChild(form);
    btn.disabled = false;
    btn.textContent = 'Export to Excel';
  };

  window.exportDashboardToPdf = function() {
    var btn = document.getElementById('btnPdfExport');
    btn.disabled = true;
    btn.textContent = 'Exporting...';
    var form = document.createElement('form');
    form.method = 'POST';
    form.action = 'CsrDashboardServlet?action=exportPdf';
    document.body.appendChild(form);
    form.submit();
    document.body.removeChild(form);
    btn.disabled = false;
    btn.textContent = 'Export to PDF';
  };
}());
</script>
</body>
</html>
