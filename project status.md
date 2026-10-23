# Project Status

**Snapshot date:** October 23, 2026  
**Status:** Existing application project; AI-readable schema/project references added and a KSS CSR dashboard implemented.

## Current state observed

- Maven WAR project configured for Java 17, Servlet API 4, JSP/JSTL, and MySQL.
- Dockerfile packages the application into a Tomcat 9 / JDK 17 image.
- Scholarship and CSR pages/controllers are present.
- KSS CSR has an admin-only dashboard entry at `CsrDashboardServlet` / `csrDashboard.jsp`, with all-time totals for approvals, work orders, invoices, FRLs, FRL claims, and receipts.
- Dated SQL snapshots cover scholarship, organization, users, and CSR workflows.
- Course pages/controllers refer to `kss_course_master`, whose DDL was not found in the inspected SQL snapshots.
- A recent working-tree state includes edits to two CSR servlets and three JSP files; these were not changed as part of this request.

## Files created

- `SQL schema.sql` — consolidated setup sequence based on checked-in SQL snapshots.
- `SQL schema.md` — schema contents and limitations.
- `project details.md` — project overview and architecture context.
- `project handover.md` — starting points and handover notes.
- `project status.md` — observed project state at this snapshot.

## Open follow-up items

- Compare the dated schema with the current database before using it.
- Confirm the missing `kss_course_master` definition/source.
- Confirm private Railway networking and application/database repository/deployment boundaries.
- Review database connection secret handling in a separate task.
