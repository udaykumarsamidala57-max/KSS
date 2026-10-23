# CLAUDE.md — HighEducation (Karnataka Seva Sangha scholarship + CSR portal)

Read this file first in every new conversation. Then read `PROJECT_STATUS.md` (what is done / pending) and `HANDOVER.md` (how to continue, deploy, test). `SQL schema.md` in the project root is the table-by-table schema map; keep it updated whenever a table changes.

---------------------------------------------------------------------
## 1. What the project is
A Java web app for **Karnataka Seva Sangha (KSS)** with two business areas:
1. **Scholarship** — employees apply for children's education scholarships; documents are verified and approved by KSS.
2. **KSS CSR Amount Spending** — tracks CSR money from an approval letter, through vendor work orders and invoices, to funds-request letters and money received. **Global role only.**

Owner path on PC: `C:\Users\srsad\eclipse-workspace\HighEducation` (Windows, Eclipse). Git repo exists in that folder; deployed on **Railway** (Docker) with a Railway MySQL database.

**Two institutions in one application (owner, 2026-10-23):** **KSS** (scholarship + CSR, schema `KSS`) and **SSS** (CSR only, schema `SSS_CSR`) on the **same MySQL server**, one Railway service, one login (`KSS.users`). After login a **Global** user chooses KSS or SSS (`selectInstitution.jsp` → `InstitutionServlet?code=`) and can switch any time with the header button "KSS ⇄ SSS"; the choice is session attribute `inst`. **Non-Global** users always work in KSS (scholarship portal). `com.Bean.AppConfig` holds the list (code, name, schema, csrOnly) — add an institution with one line there plus its schema; `ModuleFilter` (`@WebFilter("/*")`) sets the institution of every request (ThreadLocal), sends Global users who have not chosen yet to the choose page, and in SSS sends the site root, `Dashboard.jsp` and all scholarship URLs to `CsrDashboardServlet`; `DBUtil.getConnection()` connects as before and switches to the institution's schema (`setCatalog`), so every servlet reads/writes the chosen institution only. Header, footer, page titles ("SSS CSR Amount Spending"), 9-dots tiles and the print report use `AppConfig.code()/name()`. Table names stay `kss_csr_*` in both schemas. New schema: `Dump20261016\NEW_INSTITUTION_CSR_database.sql` (its `users` table is not used). SSS full name: set in `AppConfig.SSS` (currently "SSS").

---------------------------------------------------------------------
## 2. Technology stack
| Layer | Choice |
|---|---|
| Language | Java 17 (`maven-compiler-plugin` 3.11.0, source/target 17, UTF-8) |
| Web | Servlets 4.0.1 (`javax.servlet`, **not** `jakarta`) + JSP, JSTL 1.2; annotations `@WebServlet` (no web.xml; `failOnMissingWebXml=false`) |
| Server | Tomcat 9 (`tomcat:9.0-jdk17` in Docker); Eclipse WTP for local run |
| Packaging | Maven WAR → `ROOT.war` (see `Dockerfile`, 2-stage: `maven:3.9.6-eclipse-temurin-17` build, then Tomcat) |
| DB | MySQL 8 (Railway), `mysql-connector-j` 8.0.33, plain JDBC via `com.Bean.DBUtil.getConnection()` (no ORM, no pool) |
| JSON | Gson 2.10.1 (data embedded in JSP as `var x = <%= gson.toJson(...) %>`; AJAX responses) |
| PDF | iTextPDF 5.5.13.3 |
| Mail | javax.mail 1.6.2 |
| Logging | slf4j-simple 2.0.12 |
| Front end | JSP + **jQuery** AJAX, hand-written CSS (no Bootstrap/Tailwind), no build step |
| Fonts | Google Fonts `@import` (IBM Plex Sans on Global pages) |

Source layout
```
src/main/java/com/Bean         DBUtil, AuditUtil, ScholarshipBean
src/main/java/com/Controller   all servlets (one servlet per module, list + form + file + save + delete)
src/main/java/com/DAO          scholarship DAOs
src/main/webapp                JSPs, css/, WEB-INF/lib, META-INF
src/main/webapp/css            csrLetter.css, finance.css, scholarshipList.css
Dump20261016 / (1)             SQL dumps (CSR scripts + scholarship tables)
```

Servlets (all `@WebServlet("/<ClassName>")` unless noted)
LoginServlet, ScholarshipListServelt (**also mapped to `/`** — that is why CSS is included inline, see §7), SholarshipServelt, ScholarshipViewServlet, ScholarshipDocumentUploadServlet, ScholarshipDocumentDownloadServlet, UpdateStatusServlet (Submit to KSS), KssCourseServlet (Step 1), VerifyDocumentsServlet (Step 2), ApproveScholarshipServlet (Step 3), KssCourseMasterServlet, and the CSR set: CsrDashboardServlet, CsrLetterServlet, CsrWorkOrderServlet, CsrInvoiceServlet, CsrFrlServlet, CsrFundServlet, CsrPaymentServlet (vendor advances + payment vouchers), CsrCompanyServlet (funding companies master).

---------------------------------------------------------------------
## 3. Security / session model
* `LoginServlet` (POST) reads `users` (username + password compared **in plain text**) and stores session attributes `username`, `role`, `department`, `branch`. Values are cleaned of non-breaking spaces (char 160). Non-Global users land on `Dashboard.jsp`; Global users on `selectInstitution.jsp` (choose KSS / SSS). The session is renewed at every login.
* Global check, used everywhere: `"Global".equalsIgnoreCase(role.replace('\u00A0',' ').trim())`. Every CSR servlet redirects non-Global users to `Dashboard.jsp` and not-logged-in users to `login.jsp`.
* **Known risks (not yet fixed, see PROJECT_STATUS):** DB host/user/password are hard-coded in `DBUtil.java` and are in git; passwords stored/compared in plain text. Never print the credentials in docs or chat. Preferred fix: read `MYSQLHOST/MYSQLPORT/MYSQLUSER/MYSQLPASSWORD` env vars (commented hints already in `DBUtil`), rotate the Railway password, hash passwords.

---------------------------------------------------------------------
## 4. Standing user preferences (apply to all work)
1. **Global-only** access for Approvals, KSS CSR and Masters pages and for the 9-dots menu.
2. **jQuery AJAX, no page reload** for save/delete; list and form are **separate pages**; forms are **not in navigation**, only opened from buttons (e.g. "+ New", "Edit").
3. **Compact accounts/finance look** on Global pages (see §5): small padding, more rows visible, IBM Plex Sans.
4. **Non-Global pages and the maroon header stay as they are.** Do not restyle them.
5. **No example placeholders** ("e.g.", sample values) anywhere in labels, placeholders or help text — it must not look AI-made.
6. Work like an accounts person: statements, ledgers, Dr/Cr, A/B/C totals; clear, plain labels.
7. Test every change locally (Playwright screenshots + rule checks) before delivering. Deliver files by writing them into the PC project (staging copies under `outputs/`).
8. Do not start new features unless asked. Say plainly what was done in one or two sentences.

---------------------------------------------------------------------
## 5. Design system
### 5.1 Header (all users, unchanged) — `header.jsp`
Maroon brand: `--nav-primary #7a1f35`, `--nav-primary-dark #5e1627`, `--nav-accent-bg #fdf6f7`, `--nav-border #e2cece`, text `#2b2b2b` / muted `#666666`. Font: system stack (`-apple-system, Segoe UI, Roboto, Helvetica Neue, Arial`); logo text uses `Lucida Handwriting`. `header.jsp` is `@include`d by every page, defines `isGlobalUser`, `userss`, `roless`, `branchs`, `currentURI`.

Top menu (all users): **Dashboard** (`Dashboard.jsp`) · **Scholarships** dropdown (Apply Scholarship → `ScholarshipApplication.jsp`, Scholarship List → `ScholarshipListServelt`, Document Status → `scholarshipDocumentStatus.jsp`) · **Submit to KSS** (`UpdateStatusServlet`) · **Lists & Claims** dropdown (Submitted List; Global also sees Approved / Rejected / Reimbursement placeholders `#`).

**9-dots launcher (Global only)** — `#kssAppsBtn` opens `#kssAppsPanel` (search box + tiles, closes on outside click). Built from a `String[][] apps` table `{section, label, href, icon, tone, activeMatch...}`:
| Section | Tiles (label → href) |
|---|---|
| Approvals | Step 1 Apply KSS Course → `KssCourseServlet`; Step 2 Verify Documents → `VerifyDocumentsServlet`; Step 3 Approve Scholarship → `ApproveScholarshipServlet` |
| KSS CSR | Dashboard → `CsrDashboardServlet`; Management Approvals → `CsrLetterServlet`; Work Orders → `CsrWorkOrderServlet`; Invoices → `CsrInvoiceServlet`; Funds Request Letters → `CsrFrlServlet`; Fund Receipts → `CsrFundServlet` |
| Masters | Companies (CSR Funders) → `CsrCompanyServlet` (also in SSS); Organization Master → `organization.jsp`; KSS Course Master → `KssCourseMasterServlet` |
The launcher highlights the active tile via `currentURI.contains(...)`. Add a new Global page by adding one row to `apps`.

### 5.2 Finance theme (Global pages) — `css/finance.css` (loaded AFTER the page's own `<style>`, rules use `!important` to win)
* Font **IBM Plex Sans** (400/500/600/700), fallback Segoe UI/Roboto/Arial; `font-variant-numeric: tabular-nums` (equal-width digits); body 13px; tables 12.5px; headers 10.5px caps; title 19px/600.
* Tokens: `--fin-ink #0f172a` (text), `--fin-ink-2 #334155`, `--fin-muted #64748b`, `--fin-line #e2e8f0`, `--fin-line-soft #eef2f6`, `--fin-head #f8fafc`, `--fin-teal #0f766e` (actions), `--fin-amber #b45309`.
* Other fixed colours: row hover `#f0fdfa`; table head underline `#cbd5e1`; total row bg `#f8fafc` with 2px `#cbd5e1` top border; negative `#b91c1c`; proforma badge text `#b45309` on `#fffbeb` border `#fde68a`; success greens `#047857/#ecfdf5/#a7f3d0`; danger `#b91c1c/#fef2f2/#fecaca`; teal dark `#115e59`, teal light `#ccfbef`.
* Density: page padding `10px 16px`, full width (`max-width:none`; `.csr-page-narrow` 1120px for forms); cells `5px 8px`, headers `6px 8px`; buttons 28px high (small 24px, 11.5px font); inputs 30px; radius 4–6px; shadow `0 1px 2px rgba(15,23,42,.05)`; badges 10px font, 3px radius.
* Money columns right-aligned (`.csr-num`), no wrapping; `.csr-particulars` max-width 220px; `.csr-inv-pick` scrollable checklist (max-height 280px); `.csr-open` teal dashed-underline link.
* `css/csrLetter.css` = base component set (`.csr-page`, `.csr-header`, `.csr-card`, `.csr-table`, `.csr-btn[-sm|-outline|-primary|-danger]`, `.csr-badge`, `.csr-alert[-ok|-err]`, `.csr-form`, `.csr-field`, `.csr-input`, `.csr-stats/.csr-stat`, `.csr-budget`, `.csr-amount-box`), recoloured to slate/teal.
* Pages restyled with finance.css: all `csr*.jsp`, `kssCourse.jsp`, `verifyDocuments.jsp`, `approveScholarship.jsp`, `organization.jsp`, `kssCourseMaster.jsp`.
* **CSS include rule:** `<style><%@ include file="css/csrLetter.css" %></style><style><%@ include file="css/finance.css" %> ...page rules...</style>` — inline JSP include, NOT `<link>`, because `ScholarshipListServelt` is mapped to `/` and would swallow `/css/...` requests.

---------------------------------------------------------------------
## 6. KSS CSR — business flow (the heart of the project)
```
Funding Company (Masters > Companies, kss_csr_company)
 └─ Management Approval (letter, sanctioned amount A; one funding company each)
   └─ Work Orders (WO, vendor, line items, total B)           B ≤ A
        └─ Invoices: Proforma (advance request) / Tax Invoice (the real bill)
              └─ Funds Request Letter (FRL) claims one or more invoices
                    └─ Fund Receipts (money received) against an FRL

Payments to vendors (separate from FRLs, owner wording "Vendor Payments"):
Work Order ── Advances paid to vendor (kss_csr_vendor_advance)
Tax Invoice ── Payment Vouchers (kss_csr_vendor_payment, one or more per tax invoice = part payments)
      Each voucher settles: amount paid now + debit note + TDS + retention + advance adjusted
      Balance due on bill = bill − Σ settled; a voucher can never settle more than the balance due
```
**Navigation rule (owner, 2026-10-23):** most work and navigation goes through the Management Approval page (`CsrLetterServlet?action=view&id=N`). Forms opened from it return to it (`#pay` for payments; invoice form uses `&back=letter` → `#bills`).
Menu/UI labels were renamed by the owner from "Approval Letters" to **"Management Approvals"** (letter page ledger tab "KSS Ledger" → "SMIORE Ledger", now "<company> Ledger"). Keep the owner's current wording.

### 6.1 Money rules (enforced server-side in the servlets, mirrored in JS)
* **Funding company** (owner 2026-10-23: funds come from different companies, not only SMIORE): each Management Approval has one company (`company_id`, required on save; new choice must be Active). Its FRLs are requests to that company and its receipts are money from it; the letter page, print, FRL / receipt lists and forms show the company name (short name when given) where they used to say SMIORE. The company cannot change once the approval has FRLs or receipts; an FRL cannot be raised for an approval without a company. A company in use cannot be deleted (set it Inactive). Lists of approvals, FRLs and receipts have a company filter; `CsrLetterServlet?companyId=N` opens approvals of one company.
* **Letter amount** cannot be edited below committed work orders, or below FRL totals/receipts. A letter cannot be deleted if it has WOs, FRLs or receipts.
* **Work order total** (= subtotal + GST, from line items price/GST%/GST amount) ≤ letter balance. WO "billed" = **tax invoices only**.
* **Proforma is NOT a bill.** It is an advance request. It never counts toward WO billed (`counted()` is 0 for proforma). It may still be claimed in an FRL (advance).
* **Tax invoice** may be linked to the proforma it settles (`proforma_id`, same WO, type Proforma, not already settled, **one proforma → one tax invoice**, tax amount ≥ proforma amount). Once settled, the proforma stops being claimable.
* **"Raise FRL for this bill? Yes/No"** on a tax invoice (`frl_required`, form field `frlRequired`, tax invoices only). **No** = money already received through the proforma, so the invoice is never offered for an FRL (`claimable` = 0) and is shown as "No FRL (received via proforma)". Proformas always have `frl_required=1`.
* **FRL claim per invoice** (`kss_csr_frl_invoice.claim_amount`): proforma → full amount; tax invoice → amount **minus** advance already claimed on its proforma. FRL amount = sum of its claims (auto-computed, read-only in the form). An invoice can be in only one FRL (UNIQUE invoice_id). Invoices in an FRL are locked (type, WO, amount, proforma link, frl_required cannot change; cannot delete). A settled proforma cannot be removed from its FRL.
* **Receipts** are against an FRL; receipt ≤ FRL amount − other receipts. An FRL with receipts cannot be deleted, edited below received, or moved to another letter.
* **Vendor advance** (per WO): total advances ≤ WO total; cannot be reduced/deleted below the amount adjusted in vouchers; WO with advances cannot be deleted or reduced below them.
* **Payment vouchers / part payments** (owner 2026-10-23: one invoice may have one or more payments; unique voucher_no; `invoice_id` is a plain index, not unique): each voucher stores `net_paid` = amount paid now (typed, form fills the balance; "Pay Full Balance" button) plus its deductions; settled = net + debit note + TDS + retention + advance adjusted (`CsrPaymentServlet.SETTLED`). Rules: settled > 0 and ≤ bill − settled by the bill's other vouchers; total TDS of the bill ≤ taxable value; total retention ≤ bill; payment date ≥ bill date; debit note needs a reason; TDS section 194C/194J (owner removed 194I/194Q); TDS/retention % auto-fill = % of the full bill less what earlier vouchers already deducted; advance adjusted ≤ WO advances − adjusted in other vouchers. While any voucher exists the invoice's type/WO/amount are locked and it cannot be deleted. Proformas never get a voucher.
* **How payments are calculated (owner rule, 2026-10-23 — target; current code differs, see PROJECT_STATUS):**
  * **Advance:** TDS on the advance; Net = Advance − TDS. No retention.
  * **Running / Final Bill:** TDS on (Gross − GST − Advance adjusted), so TDS already cut on the advance is not cut twice. Retention = Retention % × (Gross − GST). Net paid = Gross − Advance adjusted − TDS − Retention.
  * **Retention Release:** paid in full, no TDS (it was deducted on the bill); reduces retention held.
  * TDS and retention are calculated (formula) fields; if a case differs, the user may type over that one value and must note it in Remarks.
* **How fund utilisation is measured, per project (owner rule, 2026-10-23 — target; not yet shown on screen, see PROJECT_STATUS):**
  * **Utilised** = Net paid to vendors + TDS deducted (TDS is paid to Govt on the vendor's behalf).
  * **Unspent with SSS** = Received from company − Utilised. A negative figure means SSS has paid from its own funds and must claim it.
  * **Free balance** = Unspent − Retention still held − Vendor bills unpaid. Money not committed to anything: surplus to refund / adjust with the company.
  * Shown on the CSR Dashboard per company (Company-wise Position) and per unit (Unit / Institution-wise Position, unit = `activity_kind` (Kind of CSR Activity) of the approval, grouped ignoring case and extra spaces), 2026-10-23. Also **Month-wise Receipts vs Utilisation** for a financial year April–March (`?fy=2026` = 01-Apr-2026 to 31-Mar-2027; selector lists years with entries, default current FY in IST): Received from Company (receipt date), Net Paid to Vendors (advances by advance date + voucher net paid by payment date), TDS (voucher payment date), Total Utilised, Net Flow, Cumulative Unspent (starts from the unspent before the FY; negative shaded), FY TOTAL. **Every amount in the three tables is a link** (owner 2026-10-23): `CsrDashboardServlet?action=detail&view=co|unit|month&key=<company id, 0 = not set | activity | yyyy-mm>|all&col=<column>[&fy=]` returns `{title, cols, num, rows, foot}` shown in the `#ddModal` popup; the popup total always equals the clicked amount (receipts list, advances + payments list, retention list, bills unpaid less advances not adjusted per WO, approval-wise breakdown for Approved / Yet to Receive / Unspent / Free / %, month in-out lines for Net Flow, month-by-month for Cumulative). No explanation notes under the dashboard tables (owner removed them). Not yet shown per approval on the letter page.
* **Attachments** are stored as `LONGBLOB`; validated by **magic bytes** (PDF `%PDF`, JPG `FFD8FF`, PNG `89504E47`), max 10 MB (`@MultipartConfig`). BLOBs are never selected in list queries — only in `action=file` download/preview.

### 6.2 Letter view page (`csrLetterView.jsp`) — accounting statements
**Work Orders tab** (owner request 2026-10-23): under each work order, after the owner's summary line (WO value, tax bills raised, remaining to bill, open proformas), a Tally-style **ledger of that work order** (`ledgerBlock(w)`, replaces the plain bills list): Date dd-Mon-yyyy | Dr/Cr | Particulars (bold) + italic narration | Vch Type | Vch No. | Debit | Credit; footer Opening Balance / Current Total / Closing Balance; line below with advance paid / adjusted / not adjusted, retention held, TDS. Entries from `ledgerOf()`: tax invoice = Purchase **Cr**; advance = Payment Dr; from each voucher: Debit Note Dr, TDS Payable u/s … (Journal) Dr, Retention Money Payable (Journal) Dr, Bank (mode) Payment Dr = net paid (advance adjusted only in narration). Proformas are not bills, so they are not in the ledger (still on the Bills tab and in the summary line). **Vendor Payments tab** (`#pay`) keeps only Vendor-wise Summary (click a row → Work Orders tab, that ledger) and Bills Awaiting Payment (bills with balance due: Bill Amount, Paid so far, Balance Due, "Payments (n)" → bill popup, "+ Payment" / "+ Part Payment"); the separate "Ledger Vouchers" card was removed by the owner. Clicking any ledger entry, or the "Voucher …" button on the Bills tab, opens a **popup** (`#vModal`: payment voucher — bill A, less settled by earlier vouchers, balance B, this voucher's deductions + amount paid, settled C, balance after; bill — settled, balance due and its vouchers list (click to open); advance; amount in words via `words()` Indian lakh/crore, Edit · Print · Delete inline; Esc or outside click closes). Printing while the popup is open prints only the voucher. Summary has a "Payments to Vendors" statement (C, less DN/TDS/retention = N, P advances, Q paid, balance N − P − Q). Payment data loads in `loadVendorPayments()` in its own try-block, so the page still opens (with an error line) if the payment SQL has not been run.
Statement: **A** sanctioned · **B** work-order total · **C** tax-invoice bills · **D** claimed via FRLs · **E** received against FRLs · open advances (proformas not settled) · "Less: bills marked No FRL" · **T = C + open advances − No-FRL**. Tabs: Work Orders, Invoices, FRLs, Receipts, ledger tab (FRL = debit, receipt = credit, running Dr/Cr balance), pending points. Open tab is kept in URL hash (`#rcpt` etc.). **Print** (owner request 2026-10-23: short, easy format) prints only `#printReport`, a one-page A4 statement built in `buildPrint()`: header (letter no, approval, activity, place, sanctioned, printed date/user) · 1 Summary (Budget A–C, Funds from SMIORE T/D/E, Payments to Vendors C/N/P) side by side · 2 Work Order-wise Position (WO value, billed, to bill, deductions, paid, payable, claimed) · 3 Bills (amount, settled, due, FRL) · 4 FRLs & receipts · 5 Pending · Prepared / Checked / Approved by. Tabs, ledgers and buttons are not printed. With the voucher popup open, Print prints only the voucher. Owner has since added a per-WO "bills" sub-panel (`.lv-wo-bills`) — present on the PC copy only.

### 6.3 Static SQL helper fragments (in `CsrInvoiceServlet`, reused by other servlets)
* `settled(a)` — EXISTS a tax invoice with `proforma_id = a.id`.
* `counted(a)` — tax-invoice amount only (0 for proforma). Used for WO "invoiced" totals.
* `advanceClaimed(a)` — `claim_amount` of the proforma's FRL row.
* `claimable(a)` — proforma: amount if not settled else 0; tax invoice with `frl_required=0`: 0; otherwise amount − advanceClaimed.
* Static loaders reused across modules: `CsrInvoiceServlet.loadInvoices(con)`, `loadWorkOrders(con)`; `CsrFrlServlet.loadLetters`, `loadFrls`.

---------------------------------------------------------------------
## 7. Module-by-module reference (URL → servlet → JSP)
Every CSR servlet follows the same pattern: `doGet` = list page, `?action=form[&id=]` = form page, `?action=file&id=` = attachment, `doPost` = AJAX save/delete returning JSON `{ok, message, id}`; the JSP embeds data with Gson and renders/filters client-side.

| Module | Servlet | JSPs | Key details |
|---|---|---|---|
| Dashboard | `CsrDashboardServlet` | `csrDashboard.jsp` | **Company-wise Position** table (owner 2026-10-23): Company, Projects, Approved, Received, Yet to Receive (Approved − Received), Utilised, Unspent with <inst>, Retention Held, Bills Unpaid, Free Balance, Utilisation % (Utilised ÷ Approved), TOTAL row; formulas as in §6.1 "How fund utilisation is measured" (Utilised includes vendor advances; Bills Unpaid = balance due on tax invoices less advances not yet adjusted, per work order, never below 0); negatives in brackets; computed per approval in `POSITION_SQL`, added up per company in Java; lists Active companies, any company with approvals, and "Company not set". Money on the dashboard uses `CsrDashboardServlet.indian()` (Java's en-IN DecimalFormat groups by 3 only). Owner's original part: Global only; one SQL with 13 sub-selects (counts and sums for letters, WOs, tax/proforma invoices, FRLs, claims, receipts); six KPI cards; INR formatting `en-IN`. |
| Management Approvals (letters) | `CsrLetterServlet` | `csrLetters.jsp`, `csrLetterForm.jsp`, `csrLetterView.jsp` | List columns: Work Orders / Invoices / FRLs / Funds Received. Letter number links to the view page. Actions: + WO, Edit, Delete. `action=view&id=N` → `showView` loads workOrders, invoices, frls, receipts (generic `rows(con, sql, param)`). Letter fields: letter_name, letter_number (unique), activity_kind, place, particulars, amount, signed PDF. |
| Work Orders | `CsrWorkOrderServlet` | `csrWorkOrders.jsp`, `csrWorkOrderForm.jsp` | Vendor details (name, phone, address, email, GSTIN) + line items (particulars, price, GST %, GST amount, amount) → subtotal, GST total, total; unique `wo_number`; optional attachment. |
| Invoices | `CsrInvoiceServlet` | `csrInvoices.jsp`, `csrInvoiceForm.jsp` | Type (Proforma / Tax Invoice), WO, number (unique per WO), date, price, GST, amount, "Against Proforma (advance)" select with info box, "Raise FRL? Yes/No", budget box ("Already billed (tax invoices) / Balance to bill"). List shows Type with badges "Settled by / Open advance / Against PI" and an FRL column ("+ FRL", "To claim", "Covered by advance", "No FRL (received via proforma)"). Reloads after delete. |
| Funds Request Letters | `CsrFrlServlet` | `csrFrls.jsp`, `csrFrlForm.jsp` | POST params `invoiceIds` (comma list), `letterId`, `frlNumber`, `frlDate`, `remarks`, `attachment` (required on add). Form: letter select, invoice checklist (Bill Amount / Less Advance / Claim), auto amount, remarks, required copy. Saves in a transaction (delete + reinsert `kss_csr_frl_invoice` rows with claim_amount). Delete blocked if receipts exist. |
| Fund Receipts | `CsrFundServlet` | `csrFunds.jsp`, `csrFundForm.jsp` | Receipt against an FRL (`frlId`); date, amount, payment_mode (NEFT/RTGS/IMPS/UPI/Cheque/DD/Cash/Other), reference_no, bank_name, remarks, attachment. Form accepts `id` or `frlId`; passes `fund`, `frls`, `presetFrlId`, `presetLetterId`, `modes`. |
| Vendor Payments | `CsrPaymentServlet` | `csrPaymentVoucherForm.jsp`, `csrVendorAdvanceForm.jsp` | No list page: lists live on the letter page `#pay`. GET `action=voucherForm&invoiceId=N|id=N`, `action=advanceForm&woId=N|letterId=N|id=N`, `action=file&kind=voucher|advance&id=N`; plain GET redirects to `CsrLetterServlet`. POST `saveVoucher/deleteVoucher/saveAdvance/deleteAdvance` (transaction, WO row locked `FOR UPDATE`). Voucher form: read-only bill (vendor, GSTIN, WO, bill no/date, particulars = invoice particulars else WO line items), deductions, live payment statement, voucher no/date/mode/UTR/bank/remarks/proof. Messages use Indian format via `CsrPaymentServlet.inr()`. |
| Companies (Masters) | `CsrCompanyServlet` | `csrCompanies.jsp`, `csrCompanyForm.jsp` | Funding companies: name (unique), short name, GSTIN, PAN, contact, phone, email, address, Active/Inactive. List shows approvals, sanctioned, requested (FRLs), received, yet to receive per company. Delete only when unused. Static helpers `loadChoices(con, keepId)` (approval form) and `nameOf(alias)` (SQL for a letter's company name). Tile "Companies (CSR Funders)" under Masters, shown in KSS and SSS. |
| Masters | `KssCourseMasterServlet`, `organization.jsp` | `kssCourseMaster.jsp`, `organization.jsp` | Course master list/CRUD; organization master (`organization_master`, Active/Inactive). |
| Approvals (scholarship) | `KssCourseServlet` → Step 1, `VerifyDocumentsServlet` → Step 2, `ApproveScholarshipServlet` → Step 3 | `kssCourse.jsp`, `verifyDocuments.jsp`, `approveScholarship.jsp` | Step 1 apply KSS course; Step 2 verify the 7 documents (Pending/Verified/Rejected + remarks); Step 3 final Approved/Rejected, approved amount, reimbursement (status, mode, reference, date). Table `kss_scholarship_approval`. |

Scholarship (non-Global, untouched by themes): `ScholarshipApplication.jsp` → `SholarshipServelt`; list `scholarshipList.jsp` via `ScholarshipListServelt` (+`scholarshipListDAO`); `scholarshipView.jsp`; documents upload/download servlets; `UpdateStatusServlet` (Submit to KSS) with `updateStatus.jsp`; `submitted_list.jsp`; `printScholarshipApplication.jsp`; audit trail via `AuditUtil` → `kss_scholarship_audit`.

---------------------------------------------------------------------
## 8. Database
Single MySQL schema `KSS` on Railway. Full column-level map: **`SQL schema.md`** (root). Tables: `kss_student_scholarship`, `kss_scholarship_approval`, `kss_scholarship_audit`, `organization_master`, `users`, `kss_csr_approval_letter`, `kss_csr_work_order`, `kss_csr_work_order_item`, `kss_csr_invoice`, `kss_csr_fund_request`, `kss_csr_fund_receipt`, `kss_csr_frl_invoice`, `kss_csr_vendor_advance`, `kss_csr_vendor_payment`, `kss_csr_company`. (`kss_course_master` is used by code but has no CREATE in the dumps.)

CSR migration scripts (run in this order, `Dump20261016\`): `KSS_csr_approval_letter.sql` → `KSS_csr_work_order.sql` → `KSS_csr_invoice.sql` → `KSS_csr_fund_receipt.sql` → `KSS_csr_fund_request.sql` → `KSS_csr_flow_invoice_frl.sql` → `KSS_csr_proforma_settle.sql` → `KSS_csr_invoice_frl_required.sql` → `KSS_csr_vendor_payment.sql` → `KSS_csr_company.sql` (funding companies; links old approvals to SMIORE; run in **every** institution schema) (vendor_payment adds `kss_csr_invoice.particulars` and the two vendor-payment tables; 1060/1050 = already ran). If that script was run **before** part payments were allowed (it then had `UNIQUE uq_csr_pay_invoice`), also run `KSS_csr_vendor_payment_partial.sql` (1091 = already done).
Typical errors: 1060 duplicate column / 1061 duplicate key = that step already ran, skip it. Error 1175 on the claim_amount UPDATE → `SET SQL_SAFE_UPDATES=0;` first.
FK policy: children RESTRICT on delete (cannot delete a parent that has children) except `kss_csr_work_order_item` and `kss_csr_frl_invoice.frl_id` which CASCADE.

---------------------------------------------------------------------
## 9. Coding conventions (match these when adding code)
* One servlet per module; static helpers for shared SQL; prepared statements only; transactions for multi-row saves; `try-with-resources`.
* JSON responses via Gson; errors as `{ok:false,message:"..."}` with plain, specific messages.
* Money: `BigDecimal` / `DECIMAL(14,2)`; display Indian format. Dates `yyyy-MM-dd` in forms, `dd-MM-yyyy` style on screen.
* Audit columns on CSR tables: `created_by/at`, `updated_by/at` (username from session).
* JSP: scriptlet header guard (login + Global), `@include header.jsp`, then CSS includes (§5.2), then `.csr-page` markup, then jQuery at the bottom.
* File names: JSPs `csr<Thing>s.jsp` (list) / `csr<Thing>Form.jsp` (form).
* Write source with **CRLF** line endings when saving into the PC (the Edit tool fails on CRLF files: normalise first).

---------------------------------------------------------------------
## 10. Eclipse / deploy quirks (cause of most "my change is not showing" reports)
* Eclipse WTP keeps a stale copy at `.metadata\.plugins\org.eclipse.wst.server.core\tmp1\wtpwebapps\HighEducation`. After files change on disk: **F5 the project in Eclipse, restart Tomcat, hard-refresh (Ctrl+F5).**
* Railway deploys from git: `git add -A`, commit, push. (A Railway upstream outage paused deploys on 2026-10-22; check status if a push does not deploy.)
* `Dockerfile` copies the WAR to `ROOT.war` so URLs have no context path.
