# HANDOVER — HighEducation (for a new conversation or a new developer)

## 1. Start here
1. Read `CLAUDE.md` (full project spec, design system, rules, flow).
2. Read `PROJECT_STATUS.md` (what is done / open).
3. For table details read `SQL schema.md`.
4. The PC folder is the single source of truth: `C:\Users\srsad\eclipse-workspace\HighEducation`. **Always read the PC copy of a file before editing it** — the owner (or another session) edits it too, and staging copies drift.

First message to paste in a new conversation:
> Read CLAUDE.md, PROJECT_STATUS.md and HANDOVER.md in C:\Users\srsad\eclipse-workspace\HighEducation, then continue with the open items. Keep Global-only access, jQuery AJAX, the finance theme and no example placeholders.

## 2. Run locally
* Eclipse → project HighEducation → Tomcat 9 (Java 17) → Run on Server. After any file change outside Eclipse: **F5 the project, restart Tomcat, Ctrl+F5 in the browser**.
* Maven build (as Railway does): `mvn clean package -DskipTests` → `target/HighEducation-1.0-SNAPSHOT.war`.
* DB: Railway MySQL (`KSS` schema). Connection is in `com.Bean.DBUtil` (hard-coded; see security item in PROJECT_STATUS).
* Log in as a user whose `users.role` is `Global` to see the 9-dots menu and CSR pages.

## 3. Deploy
```
git add -A
git commit -m "message"
git push
```
Railway builds from the `Dockerfile` (Maven build → Tomcat 9 `ROOT.war`). Run any new `.sql` on the Railway DB **before** the new code goes live.

## 4. The one pending code change (merge by hand into the PC files)
Feature: on an approval-letter page, a **+ New Receipt** button opens the receipt form limited to that letter's FRLs, and after saving returns to the letter's Receipts tab.

### 4.1 `csrFundForm.jsp` (3 edits)
a) Near the other JS variables (after the `gson` data lines):
```js
var onlyLetter = <%= gson.toJson(request.getAttribute("presetLetterId")) %>;   // opened from an approval letter page
var backToLetter = new URLSearchParams(window.location.search).get('back') === 'letter';
```
b) In the function that builds the FRL dropdown options, inside the loop over FRLs:
```js
if (onlyLetter && !fund && String(l.letterId) !== String(onlyLetter)) return;
```
c) After the dropdown is filled (where the preset FRL is selected):
```js
else if ($sel.find('option').length === 2) $sel.val($sel.find('option').eq(1).val());   // only one FRL due: pick it
```
d) Replace the success redirect:
```js
var cur = current();
window.location.href = backToLetter && cur
  ? 'CsrLetterServlet?action=view&id=' + cur.letterId + '#rcpt'
  : 'CsrFundServlet?msg=' + encodeURIComponent(res.message) + '&hl=' + res.id;
```
No servlet change is needed (`presetLetterId` is already set by `CsrFundServlet`).

### 4.2 `csrLetterView.jsp`
* On the Receipts tab add `<a id="btnRc" class="csr-btn csr-btn-sm csr-link-btn" href="CsrFundServlet?action=form&letterId=L&back=letter">+ New Receipt</a>` (L = this letter's id); in the script show it only when at least one FRL of the letter has an amount due, otherwise `$('#btnRc').hide()` (a `noFrl()` helper decides).
* Add `&back=letter` to: the FRL-row "+ Receipt" link (also `&frlId=…`), the receipt "Edit" link, and the "+ Receipt" link in the Pending Points line.
* A reference copy of the full working file (without the owner's later renames/WO bills panel) is in the staging area `outputs/fin/csrLetterView.jsp` — diff it against the PC file and port only the `btnRc` / `back=letter` parts.

After merging: test (1) letter with a due FRL → button opens form showing only that letter's FRLs, saving returns to `#rcpt` and the receipt count rises; (2) letter with no FRL due → button hidden; (3) normal Fund Receipts menu form still lists all due FRLs.

## 5. SQL still to run on Railway
Vendor Payments (2026-10-23): run the whole file `Dump20261016\KSS_csr_vendor_payment.sql` (ALTER invoice add `particulars`, CREATE `kss_csr_vendor_advance`, CREATE `kss_csr_vendor_payment`) **before** the new code goes live; check with `SHOW TABLES LIKE 'kss_csr_vendor%';`. Part payments (several vouchers per bill): if `KSS_csr_vendor_payment.sql` had already been run with the unique key, run `KSS_csr_vendor_payment_partial.sql` (check: `SHOW INDEX FROM kss_csr_vendor_payment WHERE Column_name='invoice_id';` must show `idx_csr_pay_invoice`, Non_unique 1).
```sql
-- 1) frl_required flag
ALTER TABLE kss_csr_invoice ADD COLUMN frl_required TINYINT(1) NOT NULL DEFAULT 1 AFTER proforma_id;
-- 2) claim_amount must be NOT NULL (it was left nullable)
SET SQL_SAFE_UPDATES=0;
UPDATE kss_csr_frl_invoice fi JOIN kss_csr_invoice i ON i.id=fi.invoice_id SET fi.claim_amount=i.amount WHERE fi.claim_amount IS NULL;
ALTER TABLE kss_csr_frl_invoice MODIFY claim_amount DECIMAL(14,2) NOT NULL;
```
Skip any statement that returns 1060/1061 (already applied).

## 5a. Local test rig (cloud session, used 2026-10-23)
Maven Central is blocked from the cloud workspace, so the build used the PC's `target\HighEducation-1.0-SNAPSHOT\WEB-INF\lib` jars + Ubuntu `libtomcat9-java` (embedded Tomcat 9) + MariaDB with the `Dump20261016` scripts, a test-only `DBUtil` (never copied to the PC) and Playwright with jQuery served locally (code.jquery.com is blocked there).

## 5b. Second institution (SSS)
Same application, same Railway service and MySQL server; SSS data is in schema `SSS_CSR` (created with `Dump20261016\NEW_INSTITUTION_CSR_database.sql`). No extra Railway variables or MySQL users are needed: the existing KSS connection opens `SSS_CSR` when a Global user chooses SSS. Any later CSR schema change must be run in **both** schemas (`KSS` and `SSS_CSR`).

## 6. Working method that has worked
* Stage the PC file locally → edit → run on a local test copy (Playwright + screenshots + rule checks: budgets, locks, validation messages) → write back to the PC with an mtime guard (`expectedMtimeMs`) so nothing the owner changed is overwritten.
* Edit with LF, save to the PC with CRLF.
* Keep replies short; say what changed and the one next step.

## 7. File inventory (CSR)
Java: `CsrDashboardServlet, CsrLetterServlet, CsrWorkOrderServlet, CsrInvoiceServlet, CsrFrlServlet, CsrFundServlet, CsrPaymentServlet`.
JSP: `csrDashboard, csrLetters, csrLetterForm, csrLetterView, csrWorkOrders, csrWorkOrderForm, csrInvoices, csrInvoiceForm, csrFrls, csrFrlForm, csrFunds, csrFundForm, csrPaymentVoucherForm, csrVendorAdvanceForm`.
CSS: `css/csrLetter.css`, `css/finance.css`.
SQL: `Dump20261016\KSS_csr_*.sql` (order in CLAUDE.md §8).
Other: `header.jsp` (menu + 9-dots), `SQL schema.md/.sql`, `Dockerfile`, `pom.xml`.
