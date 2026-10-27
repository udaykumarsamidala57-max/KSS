-- =====================================================================
-- CSR Amount Spending : Kinds of CSR Activity and Places (Masters > CSR Activities & Places)
--   1) One master table for both lists (kind = 'Activity' or 'Place')
--   2) Filled from the values already used on Management Approvals, so nothing is lost
--   The approval keeps the name as text in activity_kind / place (dashboard Unit grouping is unchanged).
-- Run in EVERY institution schema: first USE KSS; run it; then USE SSS_CSR; run it again.
-- Error 1050 (table exists) = that step already ran, skip it. The INSERTs can be run again safely.
-- =====================================================================

CREATE TABLE kss_csr_activity_place (
  id              INT NOT NULL AUTO_INCREMENT,
  kind            ENUM('Activity','Place') NOT NULL,      -- Activity = Kind of CSR Activity, Place = Place
  name            VARCHAR(200)  NOT NULL,                 -- unique within its kind (Activity names max 150 in the app)
  status          ENUM('Active','Inactive') NOT NULL DEFAULT 'Active',  -- Inactive = not offered for new approvals
  created_by      VARCHAR(50)   DEFAULT NULL,
  created_at      TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_by      VARCHAR(50)   DEFAULT NULL,
  updated_at      TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_csr_actplace (kind, name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- values already used on approvals
INSERT IGNORE INTO kss_csr_activity_place (kind, name, status, created_by, updated_by)
SELECT DISTINCT 'Activity', TRIM(activity_kind), 'Active', 'system', 'system'
  FROM kss_csr_approval_letter
 WHERE TRIM(activity_kind) <> '';

INSERT IGNORE INTO kss_csr_activity_place (kind, name, status, created_by, updated_by)
SELECT DISTINCT 'Place', TRIM(place), 'Active', 'system', 'system'
  FROM kss_csr_approval_letter
 WHERE TRIM(place) <> '';


-- Check ---------------------------------------------------------------
-- SELECT kind, name, status FROM kss_csr_activity_place ORDER BY kind, name;
