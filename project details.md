# Project Details — HighEducation

## Project at a glance

**HighEducation** is a Java web application for KSS higher-education scholarship administration and CSR funding administration. It provides browser-based JSP pages backed by Java servlets and MySQL. Scholarship records and uploaded documents are managed alongside review, approval, and reimbursement data. CSR records follow an approval-letter, work-order, invoice, fund-request, and receipt flow.

| Item | Project value |
|---|---|
| Eclipse project | `HighEducation` |
| Project folder | `C:\Users\srsad\eclipse-workspace\HighEducation` |
| Maven coordinates | `com.HighEducation:HighEducation:1.0-SNAPSHOT` |
| Packaging | WAR |
| Java source/target | 17 |
| Web/API baseline | Java EE `javax.*`; Servlet API 4.0.1 (provided by container) |
| View layer | JSP and JSTL 1.2 |
| Database | MySQL; application configuration targets schema `KSS` |
| Primary runtime packaging | Tomcat 9 on JDK 17 |
| Container build | Multi-stage Maven + Tomcat Dockerfile |

## What the application does

### Scholarship administration

- Accept and store student/child scholarship applications associated with an employee and organization.
- Record education, academic results, fee amounts, bank details, submission state, and supporting documents.
- List, view, print, and update submitted applications.
- Upload and download application documents stored in MySQL BLOB columns.
- Verify required documents and record verification statuses/remarks.
- Record a final approval/rejection decision, approved amount, and reimbursement/payment details.
- Record application changes in the scholarship audit table.
- Maintain the organization list and course-related values used by application pages.

### CSR funding administration

- Store CSR approval letters, activity details, approved amounts, and files.
- Create vendor work orders and itemized charges with GST.
- Record proforma and tax invoices against work orders, including proforma settlement links.
- Create Funds Request Letters (FRLs), associate invoices with claims, and record claim amounts.
- Record incoming fund receipts, with optional association to an FRL.

The flow and table descriptions are summarized in [SQL schema.md](SQL%20schema.md). The SQL file contains setup/migration statements, while that Markdown guide is the quicker reference for future project work.

## Product direction and user experience requirements

The product is intended for **accountants and staff handling scholarship and CSR financial records**. Keep workflows clear, task-focused, and hard to misnavigate.

### Required interaction model for the whole application

- The target experience is AJAX-driven across the entire application: internal navigation, lists, filters, forms, validation, saves, status changes, and document uploads should update the relevant content without a full-page reload.
- Use one consistent application shell and update the active content area as the user moves between modules. Internal links should not unexpectedly send the user to a separate JSP page or reset their current context.
- Keep the browser URL and history meaningful for internal screens so refresh, back, and forward remain predictable while views are loaded asynchronously.
- Show clear loading, success, validation, and failure feedback close to the task being performed. Preserve entered data after recoverable errors.
- Handle document upload/download and scholarship printing in ways that keep the main application session in place and avoid an unnecessary full application reload.
- Use accountant-friendly labels and a small, stable set of top-level destinations. A proposed grouping is **Dashboard**, **Scholarships**, **CSR Finance**, and **Master Data**; group CSR letters, work orders, invoices, FRLs, and receipts inside CSR Finance. Add reports only when their actual scope is defined.
- Keep the active module and current task visible. Use consistent placement for actions such as New, Save, Cancel, Search, and Back. Avoid duplicate menu routes and unexplained technical terms.
- In **Admin → KSS CSR**, **Approval Letters** is the default/home screen. Every KSS CSR screen must provide a consistent, easy-to-find **Approval Letters** navigation action that returns directly to that screen using the AJAX navigation model, regardless of which CSR subpage the user is on.

These are product requirements for future implementation, not a description of the current application. The present project is JSP-based, has separate page files, and includes direct navigation and some direct JDBC in JSPs. It does not yet meet the no-full-page-reload requirement. Treat a complete AJAX navigation and interaction refactor as a project-level change that must cover scholarship, CSR, course, organization, login/session, upload/download, and print paths together.
## Application architecture

The project uses a traditional Java web application structure:

- **JSP pages** render forms, lists, detail views, dashboards, document status, and printed scholarship applications.
- **Servlet controllers** handle login, scholarship submission/list/detail/document handling, verification/approval, course operations, and CSR operations.
- **DAO classes** provide shared data access for scholarship applications, lists/views, and documents.
- **Bean/util classes** hold scholarship data and shared database/audit helpers.
- **MySQL** stores application data and document attachments.

The implementation is not uniformly layered: some JSP files contain direct JDBC work as well as presentation logic. When changing a workflow, inspect the relevant JSP, controller, and DAO together to find the full request path.

### Main Java areas

- `src/main/java/com/Controller/` — servlets for scholarship, CSR, login, and course workflows.
- `src/main/java/com/DAO/` — scholarship application/list/view/document access.
- `src/main/java/com/Bean/` — `ScholarshipBean`, `DBUtil`, and `AuditUtil`.

Key controller groups:

- Scholarship submission/list/view: `SholarshipServelt`, `ScholarshipListServelt`, `ScholarshipViewServlet`, `UpdateStatusServlet`.
- Documents and review: `ScholarshipDocumentUploadServlet`, `ScholarshipDocumentDownloadServlet`, `VerifyDocumentsServlet`, `ApproveScholarshipServlet`.
- CSR: `CsrLetterServlet`, `CsrWorkOrderServlet`, `CsrInvoiceServlet`, `CsrFrlServlet`, `CsrFundServlet`.
- Course and account flows: `KssCourseServlet`, `KssCourseMasterServlet`, `LoginServlet`.

Some class names retain spelling/capitalization inconsistencies from the existing code; preserve exact names when following current servlet mappings and references.

### Main web pages

The JSP application is in `src/main/webapp/`. Pages include:

- Scholarship: `ScholarshipApplication.jsp`, `scholarshipList.jsp`, `scholarshipView.jsp`, `submitted_list.jsp`, `printScholarshipApplication.jsp`.
- Document review and decision: `scholarshipDocumentStatus.jsp`, `verifyDocuments.jsp`, `approveScholarship.jsp`, `updateStatus.jsp`.
- CSR: `csrLetters.jsp`, `csrLetterForm.jsp`, `csrLetterView.jsp`, `csrWorkOrders.jsp`, `csrWorkOrderForm.jsp`, `csrInvoices.jsp`, `csrInvoiceForm.jsp`, `csrFrls.jsp`, `csrFrlForm.jsp`, `csrFunds.jsp`, `csrFundForm.jsp`.
- Supporting pages: `Dashboard.jsp`, `login.jsp`, `Logout.jsp`, `organization.jsp`, `kssCourse.jsp`, `kssCourseMaster.jsp`, and shared `header.jsp`.

Static stylesheets are in `src/main/webapp/css/`.

## Data model summary

The project schema exports define these 12 tables:

| Area | Tables | Purpose |
|---|---|---|
| Scholarship | `kss_student_scholarship` | Application, person, academic, fee, bank, document, and submission data. |
| Scholarship | `kss_scholarship_approval` | One-to-one review, decision, and reimbursement record per application. |
| Scholarship | `kss_scholarship_audit` | Application change history. |
| Reference/access | `organization_master` | Organization names and active state. |
| Reference/access | `users` | Login and user/role attributes. |
| CSR | `kss_csr_approval_letter` | Approved activity and amount. |
| CSR | `kss_csr_work_order` | Vendor work order under an approval. |
| CSR | `kss_csr_work_order_item` | Itemized work-order charges. |
| CSR | `kss_csr_invoice` | Proforma and tax invoices; may link a tax invoice to its settled proforma. |
| CSR | `kss_csr_fund_request` | FRL request under an approval letter. |
| CSR | `kss_csr_frl_invoice` | Invoice-to-FRL claim link and claimed amount. |
| CSR | `kss_csr_fund_receipt` | Funds received against an approval and optionally an FRL. |

The detailed field list, keys, nullability, defaults, enums, and delete rules are in [SQL schema.md](SQL%20schema.md). The exports store scholarship and CSR attachments as `LONGBLOB` data in their parent tables.

### Relationships at a glance

- Scholarship application → optional one-to-one approval/reimbursement record.
- Scholarship application → audit entries by application logic; no audit foreign key is declared.
- CSR approval letter → work orders and FRLs.
- Work order → line items and invoices.
- FRL ↔ invoices through `kss_csr_frl_invoice`; each invoice is unique in that bridge table.
- Receipts retain a required approval-letter link and can also point to an FRL.
- A tax invoice can reference the proforma it settles through the self-reference `proforma_id`.

## Build and deployment

- `pom.xml` defines a Maven WAR, compiler level Java 17, and the Maven WAR plugin.
- Main dependencies include Servlet API 4 (provided), JSTL, MySQL Connector/J 8.0.33, Gson, iText PDF, JavaMail, and SLF4J Simple.
- `Dockerfile` builds the WAR using Maven 3.9.6 with Temurin 17, then copies the WAR into a Tomcat 9 / JDK 17 image as the root web application. Container port 8080 is exposed.
- The Docker build invokes Maven with tests skipped. The repository does not include a separate deployment/runbook document describing environment-specific setup.



## SQL export sources and confidence

- CSR workflow SQL source identified by the project owner: `C:\Users\srsad\eclipse-workspace\PInventory\Dump20261016`.
- Scholarship, organization, and user SQL exports in this project: `Dump20261016 (1)`.
- The CSR scripts are sequential table-creation and `ALTER TABLE` steps. `SQL schema.md` represents the resulting structure as reconstructed from them.
- The exports are dated snapshots and were not compared with a live MySQL database. They may not contain every current production table or later change.
- Application code references `kss_course_master`, but no `CREATE TABLE kss_course_master` was found in the inspected exports. Obtain its DDL from the authoritative source before changing or documenting its columns.
- Some SQL values/associations are application-level conventions rather than declared database foreign keys; do not assume all business rules are enforced by MySQL constraints.

## Current repository notes

At the time this project reference was updated, existing repository changes included edits to the CSR invoice/letter servlets and related JSPs, generated files under `target/`, and deletions of two KSS process-guide PNG files under `Dump20261016`. These changes predated this project-details update and were not modified by it. Check the current Git status before editing those areas or preparing a commit.

## Guidance for future AI-assisted project work

1. Read this file for the project purpose, architecture, and runtime context.
2. Read `SQL schema.md` for the table and relationship map; use the source SQL exports when an exact DDL or migration step matters.
3. Trace the relevant JSP, servlet, DAO, and SQL together because database work is not isolated to DAOs everywhere.
4. Keep credentials, document contents, and production data out of project documentation and generated examples.
5. When adding/changing a schema object, update `SQL schema.md` and this project overview if the architecture or feature description also changes.


