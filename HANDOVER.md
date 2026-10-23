# HANDOVER — HighEducation (for a new conversation or a new developer)

## 1. Start here
1. Read `CLAUDE.md` (full spec, design system, rules, CSR flow, institutions).
2. Read `PROJECT_STATUS.md` (done / open).
3. For tables read `SQL schema.md`.
4. The PC folder is the single source of truth: `C:\Users\srsad\eclipse-workspace\HighEducation`. **Always read the PC copy of a file before editing it** — the owner edits files too.

First message to paste in a new conversation:
> Read CLAUDE.md, PROJECT_STATUS.md and HANDOVER.md in C:\Users\srsad\eclipse-workspace\HighEducation, then continue with the open items. Keep Global-only access, jQuery AJAX, the finance theme and no example placeholders.

## 2. Run locally
* Eclipse → HighEducation → Tomcat 9 (Java 17) → Run on Server.
* After any file change outside Eclipse: **F5 the project → Project → Clean → Servers: Clean + Restart Tomcat → Ctrl+F5** in the browser.
* Maven build (as Railway does): `mvn clean package -DskipTests` → `target/HighEducation-1.0-SNAPSHOT.war`.
* DB: Railway MySQL; connection in `com.Bean.DBUtil` (hard-coded, see security item).
* Log in as a `Global` user to choose KSS / SSS and see CSR pages; a non-Global user sees only the KSS scholarship portal.

## 3. Deploy
```
git add -A
git commit -m "message"
git push
```
Railway builds from the `Dockerfile` (Maven → Tomcat 9 `ROOT.war`). Run any new SQL **before** the new code goes live — in **both** schemas `KSS` and `SSS_CSR` when it is a CSR table change.

## 4. Institutions (KSS and SSS) — how it works
* One app, one Railway service, one MySQL server. Schemas: `KSS` (scholarship + CSR) and `SSS_CSR` (CSR only). Table names are the same (`kss_csr_*`).
* Logins always come from `KSS.users` (`LoginServlet` runs before any choice).
* Global user after login → `selectInstitution.jsp` → `InstitutionServlet?code=KSS|SSS` → session attribute `inst`. Header button "KSS ⇄ SSS" switches.
* `ModuleFilter` (`@WebFilter("/*")`) sets the institution of each request (`AppConfig` ThreadLocal); not chosen yet → choose page; in SSS the site root, `Dashboard.jsp` and scholarship URLs go to `CsrDashboardServlet`. Non-Global users are always KSS.
* `DBUtil.getConnection()` connects as before and switches to the institution's schema (`setCatalog`), so every servlet works on the chosen institution only.
* Add another institution: one line in `AppConfig.ALL` + a schema created with `Dump20261016\NEW_INSTITUTION_CSR_database.sql` (run with safe updates off; the script sets it).
* SQL checks if the KSS database was migrated by hand:
```sql
SET SQL_SAFE_UPDATES=0;
ALTER TABLE kss_csr_invoice ADD COLUMN frl_required TINYINT(1) NOT NULL DEFAULT 1 AFTER proforma_id;
UPDATE kss_csr_frl_invoice fi JOIN kss_csr_invoice i ON i.id=fi.invoice_id SET fi.claim_amount=i.amount WHERE fi.claim_amount IS NULL;
ALTER TABLE kss_csr_frl_invoice MODIFY claim_amount DECIMAL(14,2) NOT NULL;
SET SQL_SAFE_UPDATES=1;
```
Skip any statement that returns 1060 / 1061 (already applied).

## 4a. Funding companies (2026-10-23)
* Masters > Companies (`CsrCompanyServlet`, `csrCompanies.jsp`, `csrCompanyForm.jsp`), table `kss_csr_company` in each institution schema.
* `kss_csr_approval_letter.company_id` links each approval to its company. FRLs and receipts take the company from their approval (no column on those tables).
* SQL: `Dump20261016\KSS_csr_company.sql`, run once in `KSS` and once in `SSS_CSR`. Already included in `NEW_INSTITUTION_CSR_database.sql` for new institutions.
* Not changed: CSR Dashboard (all companies together). A company-wise dashboard can be added later if wanted.

## 5. Pending code change: "+ New Receipt" from the Management Approval page (merge by hand)
On the Receipts tab, a **+ New Receipt** button opens the receipt form limited to that approval's FRLs and returns to `#rcpt` after saving.
* `csrFundForm.jsp`: (a) `var onlyLetter = <%= gson.toJson(request.getAttribute("presetLetterId")) %>; var backToLetter = new URLSearchParams(location.search).get('back') === 'letter';` (b) in the FRL option loop: `if (onlyLetter && !fund && String(l.letterId) !== String(onlyLetter)) return;` (c) after filling: `else if ($sel.find('option').length === 2) $sel.val($sel.find('option').eq(1).val());` (d) on success: back to `CsrLetterServlet?action=view&id=<letterId>#rcpt` when `backToLetter`, else the list.
* `csrLetterView.jsp`: add `<a id="btnRc" ... href="CsrFundServlet?action=form&letterId=L&back=letter">+ New Receipt</a>` on the Receipts tab, hidden when no FRL of the letter has an amount due; add `&back=letter` to the FRL-row "+ Receipt", receipt "Edit" and pending-point "+ Receipt" links.
* Test: letter with a due FRL → only its FRLs, back to `#rcpt`; no FRL due → button hidden; normal Fund Receipts form still lists all due FRLs.

## 6. Local test rig (cloud session)
Maven Central and code.jquery.com are blocked from the cloud workspace. The rig used: the PC's `target\HighEducation-1.0-SNAPSHOT\WEB-INF\lib` jars, Ubuntu `libtomcat9-java` (embedded Tomcat 9), MariaDB with schemas `KSS` and `SSS_CSR` built from the `Dump20261016` scripts, a test-only `DBUtil` with the same schema logic (never copied to the PC), and Playwright with jQuery served locally. Suites: 53 CSR / vendor-payment checks, 40 funding-company checks and 19 institution checks (choose, switch, data kept apart, non-Global blocked).

## 7. Working method that has worked
* Stage the PC file → edit (LF) → test on the local rig (Playwright, screenshots, rule checks) → write back to the PC with CRLF and an mtime guard (`expectedMtimeMs`) so owner edits are never overwritten.
* Keep replies short; say what changed and the one next step.

## 8. File inventory
Java (CSR): `CsrDashboardServlet, CsrLetterServlet, CsrWorkOrderServlet, CsrInvoiceServlet, CsrFrlServlet, CsrFundServlet, CsrPaymentServlet, CsrCompanyServlet`.
Java (institutions): `com.Bean.AppConfig`, `com.Controller.ModuleFilter`, `com.Controller.InstitutionServlet`, `com.Bean.DBUtil` (schema switch), `LoginServlet` (Global → choose page).
JSP (CSR): `csrDashboard, csrLetters, csrLetterForm, csrLetterView, csrWorkOrders, csrWorkOrderForm, csrInvoices, csrInvoiceForm, csrFrls, csrFrlForm, csrFunds, csrFundForm, csrPaymentVoucherForm, csrVendorAdvanceForm, csrCompanies, csrCompanyForm`; `selectInstitution.jsp`; `header.jsp` (menu, 9-dots, KSS ⇄ SSS button).
CSS: `css/csrLetter.css`, `css/finance.css`.
SQL (`Dump20261016\`): CSR scripts in the order of CLAUDE.md §8, `KSS_csr_vendor_payment.sql`, `KSS_csr_vendor_payment_partial.sql`, `KSS_csr_company.sql`, `NEW_INSTITUTION_CSR_database.sql`. Not used any more (delete): `KSS_csr_payment_procedure.sql`, `KSS_users_institutions.sql`.
Other: `SQL schema.md/.sql`, `Dockerfile`, `pom.xml`.
