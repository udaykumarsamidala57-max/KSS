# PROJECT_STATUS — HighEducation
Last updated: 2026-10-23 (Vendor Payments added)

## Summary
Scholarship module is stable. The KSS CSR module (Global only) is feature-complete for the flow **Management Approval → Work Orders → Proforma/Tax Invoices → Funds Request Letters → Fund Receipts**, with accounting view per approval, a CSR dashboard, a 9-dots launcher and the finance theme on all Global pages.

## Done
| Area | Status |
|---|---|
| 9-dots launcher (Approvals, KSS CSR, Masters), Global only | Done |
| Finance theme (IBM Plex Sans, slate/teal, compact) on all Global pages | Done (re-done twice after owner feedback) |
| Approval letters CRUD + signed PDF | Done |
| Work orders with line items, GST, attachment | Done |
| Invoices: Proforma / Tax Invoice, settle proforma, "Raise FRL Yes/No" | Done |
| Funds Request Letters: many invoices per FRL, per-invoice claim, remarks, required copy | Done |
| Fund receipts against FRL | Done |
| Approval letter view page (accounts statement A–E/T, tabs, ledger, print) | Done |
| CSR Dashboard (`CsrDashboardServlet`/`csrDashboard.jsp`) | Added by owner/another session on the PC |
| Rename to "Management Approvals", "SMIORE Ledger", per-WO bills panel | Done on the PC copy |
| All example placeholders removed | Done |
| Vendor Payments (2026-10-23): advances to vendors per WO, payment voucher per tax invoice (debit note, TDS, retention, advance adjusted, net paid), Vendor Payments tab + summary statement on the letter page, invoice particulars, locks | Built and tested locally (34 rule checks + page regression). Needs `KSS_csr_vendor_payment.sql` on Railway **before** deploying. |

## Open items (in priority order)
00. **SSS (second institution, CSR only)** — done in code and tested locally (2026-10-23): one app, Global users choose KSS / SSS after login and switch from the header; non-Global users stay in KSS scholarship; SSS data in schema `SSS_CSR` on the same server. Pending: SSS full name (AppConfig.SSS), deploy. Not needed any more (from the earlier two-service idea): `KSS_users_institutions.sql`, Railway `APP_DB_*` / `AUTH_DB_*` / `INSTITUTION_*` variables, MySQL users `sss_app` / `sss_login`. Known: CSR dashboard shows amounts in western grouping (₹500,000.00), not Indian.
0. **Vendor Payments go-live:** run `Dump20261016\KSS_csr_vendor_payment.sql` on Railway first (if it was already run before part payments were added, run `KSS_csr_vendor_payment_partial.sql` instead of re-running it) (invoice list/form and letter page payment tab need it), then F5 + restart Tomcat, then commit + push. Delete the four files of the withdrawn first attempt if still present: `CsrPaymentProcedureServlet.java`, `csrPaymentProcedures.jsp`, `csrPaymentProcedureForm.jsp`, `Dump20261016\KSS_csr_payment_procedure.sql`. Not built yet (ask owner): retention release entry, printable payment voucher, TDS register, `&back=letter` on WO / FRL / receipt forms.
1. **"+ New Receipt" from the approval letter page — built and tested, NOT on the PC yet.** The PC's `csrLetterView.jsp` and `csrFundForm.jsp` were modified after my copy (renames, WO bills panel), so overwriting would lose those edits. Changes must be merged, not copied — see HANDOVER §4 for the exact edits.
2. **Run SQL on the Railway DB:** `KSS_csr_invoice_frl_required.sql`, and finish `claim_amount` (`UPDATE` then `MODIFY ... NOT NULL`, with `SET SQL_SAFE_UPDATES=0` if error 1175). Confirm with `SHOW COLUMNS FROM kss_csr_frl_invoice;` and `SHOW COLUMNS FROM kss_csr_invoice;`.
3. **Re-verify** that the "+ New Receipt" button is hidden when the letter has no FRL due (last test still showed it visible; the hide line `else $('#btnRc').hide();` exists — check for a stale JSP cache or tab/hash effect).
4. Owner to **confirm two proforma assumptions**: (a) one proforma ↔ one tax invoice; (b) tax-invoice FRL claim = invoice amount − advance already claimed.
5. **Security (recommended before wider use):** move DB credentials out of `DBUtil.java` into environment variables and rotate the Railway password (it is in git history); hash user passwords; add CSRF protection to the AJAX posts.
6. Commit + push to git so Railway redeploys (after item 1–2).
7. `Approved List`, `Rejected List`, `Reimbursement` menu entries are placeholders (`#`).
8. `kss_course_master` has no CREATE TABLE in the dumps — add one to the schema folder.

## Known behaviours / not bugs
* Stale Eclipse copy hides new JSPs — F5 + restart Tomcat.
* Playwright test server dies on its time limit — harmless, restart it with a background run.
* Deleting is blocked (by design) for: letters with WOs/FRLs/receipts; invoices inside an FRL; settled proformas; FRLs with receipts.

## Owner decisions so far (for context)
Type on the same Invoice page · many invoices in one FRL · count both (proforma and tax) at first, later changed: proforma is **not** a bill · open tab in URL hash · dedicated accounts-style page per approval letter · FRL columns order WO → Invoices → FRLs → Funds Received.

## Account note
The previous conversation ended on a usage limit. Billing/credit status cannot be seen from the session; check the Claude account's usage and billing settings.
