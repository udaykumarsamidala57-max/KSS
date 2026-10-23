# PROJECT_STATUS — HighEducation
Last updated: 2026-10-23 (evening)

## Summary
One application, two institutions on the same MySQL server:
* **KSS** (schema `KSS`): Scholarship portal + CSR Amount Spending. Stable.
* **SSS** (schema `SSS_CSR`): CSR Amount Spending only.
Global users choose KSS or SSS after login and switch from the header ("KSS ⇄ SSS"). Other users always work in the KSS scholarship portal.
CSR flow is complete: Management Approval → Work Orders → Proforma / Tax Invoices → FRLs → Fund Receipts, plus **Vendor Payments** (advances, payment vouchers with deductions, part payments) and a work-order ledger.

## Done
| Area | Status |
|---|---|
| 9-dots launcher (Approvals, CSR, Masters), Global only | Done |
| Finance theme (IBM Plex Sans, slate/teal, compact) on Global pages | Done |
| Management Approvals, Work Orders, Invoices (Proforma / Tax, settle proforma, Raise FRL Yes/No), FRLs, Fund Receipts | Done |
| Management Approval page: statements A–E/T, tabs, SMIORE ledger, pending points | Done |
| CSR Dashboard | Done (added by owner) |
| Invoice **Particulars** field | Done 2026-10-23 |
| **Vendor advances** per work order (+ Advance on each WO) | Done 2026-10-23 |
| **Payment vouchers** per tax invoice: debit note, TDS (194C / 194J), retention, advance adjusted, amount paid; **part payments** (one bill, several vouchers) | Done 2026-10-23 |
| **Work Orders tab:** Debit / Credit ledger under each work order (bill = Credit, payments and deductions = Debit, closing balance) | Done 2026-10-23 |
| **Vendor Payments tab:** Vendor-wise Summary + Bills Awaiting Payment (paid so far, balance due) | Done 2026-10-23 |
| **Popup** for any payment / advance / bill (statement, amount in words, Edit / Print / Delete) | Done 2026-10-23 |
| **Print** of a Management Approval: one-page A4 statement (summary, WO position, bills, FRLs, pending, signatures) | Done 2026-10-23 |
| **SSS institution:** choose / switch after login, SSS data in `SSS_CSR`, scholarship pages hidden in SSS | Done 2026-10-23, tested locally |
| **Funding companies** (Masters > Companies): each Management Approval picks its company; FRLs / receipts / letter page / print show it instead of SMIORE; company filters on approvals, FRLs, receipts | Done 2026-10-23, tested locally (SQL not yet run by owner) |
| **Dashboard: Company-wise and Unit-wise (Kind of CSR Activity) Position + Month-wise Receipts vs Utilisation (FY selector); every amount opens a detail popup** (approved, received, utilised, unspent, retention, bills unpaid, free balance, utilisation %) + Indian ₹ format on all dashboard amounts | Done 2026-10-23, tested locally |
| Locks: invoice with a voucher cannot change amount / be deleted; advance cannot go below adjusted; WO with advances cannot be deleted | Done |

## Database state (as reported by owner, 2026-10-23)
* `KSS`: vendor payment tables created, `kss_csr_invoice.particulars` added, `idx_csr_pay_invoice` non-unique (part payments allowed).
* `SSS_CSR`: created from `NEW_INSTITUTION_CSR_database.sql` (all CSR tables). Its `users` table is not used (logins come from `KSS.users`).

## Open items (in priority order)
0. **Run `Dump20261016\KSS_csr_company.sql` in both schemas** (`USE KSS;` run it, then `USE SSS_CSR;` run it) **before** deploying the new code — without it the approval, FRL and receipt pages fail. It creates `kss_csr_company`, adds SMIORE, adds `kss_csr_approval_letter.company_id` and links existing approvals to SMIORE. Then edit SMIORE in Masters > Companies (full name, GSTIN, PAN) and add the other companies.
1. **Clean and test in Eclipse, then deploy.** F5 → Project → Clean → Tomcat Clean + Restart → Ctrl+F5. Test: login as Global → choose SSS → add a Management Approval → switch to KSS (must not show it). Then `git add -A`, commit, push.
2. **Delete files that are no longer used** (cannot be deleted from the cloud session):
   `src\main\java\com\Controller\CsrPaymentProcedureServlet.java`, `src\main\webapp\csrPaymentProcedures.jsp`, `src\main\webapp\csrPaymentProcedureForm.jsp`, `Dump20261016\KSS_csr_payment_procedure.sql`, `Dump20261016\KSS_users_institutions.sql`.
3. **Railway clean-up** from an earlier idea (two services), if any of it was added: remove variables `APP_DB_*`, `AUTH_DB_*`, `INSTITUTION_*`, `APP_MODULES`; drop MySQL users `sss_app` / `sss_login`. Column `users.institutions` is harmless and can stay.
4. **SSS full name** — owner to give it; set in `AppConfig.SSS` (header currently shows "SSS").
5. ~~CSR Dashboard money format~~ — done 2026-10-23 (Indian ₹5,00,000.00).
6. **"+ New Receipt" from the Management Approval page** — designed, not merged on the PC. See HANDOVER §5.
7. **Check on the KSS database** that `kss_csr_invoice.frl_required` exists and `kss_csr_frl_invoice.claim_amount` is NOT NULL (`SHOW COLUMNS ...`). If not, run the statements in HANDOVER §4.
8. Owner to **confirm two proforma rules**: (a) one proforma ↔ one tax invoice; (b) tax-invoice FRL claim = invoice amount − advance already claimed.
9. **Security (before wider use):** DB password is hard-coded in `DBUtil.java` and in git history — move to a Railway variable and rotate it; hash user passwords; add CSRF protection to AJAX posts.
10. **Payment calculation rules (owner, 2026-10-23)** — noted in CLAUDE.md §6.1 "How payments are calculated"; not yet built. Gaps in the current code: advance has no TDS (needs TDS + net); bill TDS base should be Gross − GST − Advance adjusted (now: taxable value less earlier TDS); retention base should be Gross − GST (now: full bill); Retention Release entry does not exist; overriding TDS / retention must require a Remarks note.
11. **Fund utilisation per project (owner, 2026-10-23)** — company-wise table on the CSR Dashboard done 2026-10-23. Still open: the same statement per approval on the Management Approval page (ask owner).
12. Not built yet (ask owner first): TDS register, plain words for "Vch Type / Vch No. / Journal" in the ledger, `&back=letter` on Work Order / FRL / Receipt forms.
13. Menu placeholders `Approved List`, `Rejected List`, `Reimbursement` (`#`); `kss_course_master` has no CREATE TABLE in the dumps.

## Known behaviours / not bugs
* "My change is not showing" = stale Eclipse copy: F5, Project → Clean, restart Tomcat, Ctrl+F5.
* Deleting is blocked by design for: letters with WOs / FRLs / receipts; invoices in an FRL or with a payment voucher; settled proformas; FRLs with receipts; advances already adjusted; work orders with invoices or advances.
* Proformas are not bills: they are not in the work-order ledger and never get a payment voucher.
* A CSR schema change must be run in **both** schemas: `KSS` and `SSS_CSR`.

## Owner decisions (for context)
Type on the same Invoice page · many invoices in one FRL · proforma is not a bill · open tab kept in the URL · dedicated accounts page per Management Approval · most work and navigation through the Management Approval page · ledger under each work order (not a separate tab) · bill = Credit, payment = Debit · one bill may have several part payments · TDS sections 194C and 194J only · no "Sundry" wording · short one-page print · one application for KSS and SSS, Global users switch, others KSS only.
