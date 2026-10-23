# Project Handover

## What is here

HighEducation is a Java 17 Maven web application packaged as a WAR. It uses JSP pages and Java servlets, connects to MySQL database `KSS`, and has a Dockerfile for Tomcat 9 deployment. The application covers scholarships and CSR funding workflows.

## Useful starting points

- Build configuration: `pom.xml`
- Container configuration: `Dockerfile`
- Database connection utility: `src/main/java/com/Bean/DBUtil.java`
- Scholarship controllers and DAO: `src/main/java/com/Controller` and `src/main/java/com/DAO`
- JSP user interface: `src/main/webapp`
- Dated database SQL: `Dump20261016`, `Dump20261016 (1)`
- Consolidated schema reference created for this handover: `SQL schema.sql`, with notes in `SQL schema.md`

## Handover notes

- The SQL is based on dated project snapshots and has not been checked against a live database. Confirm the current schema before applying any SQL, especially where data already exists.
- Course-related code refers to `kss_course_master`; no definition for it was present in the inspected SQL files.
- The database utility contains connection configuration in source. Keep connection secrets out of documentation and rotate/manage them through deployment secrets in a follow-up task.
- The recent design conversation raised private service URLs and repository boundaries. Confirm the intended Railway topology before changing connection or deployment configuration.
- Existing working-tree edits were present in `CsrInvoiceServlet.java`, `CsrLetterServlet.java`, `csrInvoiceForm.jsp`, `csrInvoices.jsp`, and `csrLetterView.jsp` when this handover was prepared. They were left untouched.

## Next operator

Review the five new project-root files and give the next task. No source code, deployment configuration, or live database was changed while preparing these files.
