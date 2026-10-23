-- =====================================================================
-- CSR Amount Spending : Funding companies (Masters > Companies)
--   Funds now come from different companies, not only SMIORE.
--   1) Company master
--   2) Each Management Approval belongs to one funding company; its FRLs and receipts follow that company
--   3) Existing approvals are linked to SMIORE (edit the SMIORE row afterwards in Masters > Companies if needed)
-- Run in EVERY institution schema: first USE KSS; run it; then USE SSS_CSR; run it again.
-- Error 1050 (table exists) / 1060 (duplicate column) / 1061 (duplicate key) / 1826 (duplicate foreign key)
--   = that step already ran, skip it.
-- =====================================================================

SET SQL_SAFE_UPDATES = 0;

CREATE TABLE kss_csr_company (
  id              INT NOT NULL AUTO_INCREMENT,
  company_name    VARCHAR(200)  NOT NULL,                 -- Company name (unique)
  short_name      VARCHAR(50)   DEFAULT NULL,             -- Short name shown on screens
  gstin           VARCHAR(15)   DEFAULT NULL,
  pan             VARCHAR(10)   DEFAULT NULL,
  contact_person  VARCHAR(150)  DEFAULT NULL,
  phone           VARCHAR(20)   DEFAULT NULL,
  email           VARCHAR(150)  DEFAULT NULL,
  address         VARCHAR(500)  DEFAULT NULL,
  status          ENUM('Active','Inactive') NOT NULL DEFAULT 'Active',  -- Inactive = not offered for new approvals
  created_by      VARCHAR(50)   DEFAULT NULL,
  created_at      TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_by      VARCHAR(50)   DEFAULT NULL,
  updated_at      TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_csr_company_name (company_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


INSERT IGNORE INTO kss_csr_company (company_name, short_name, status, created_by, updated_by)
VALUES ('SMIORE', 'SMIORE', 'Active', 'system', 'system');


ALTER TABLE kss_csr_approval_letter
  ADD COLUMN company_id INT DEFAULT NULL AFTER id;

ALTER TABLE kss_csr_approval_letter
  ADD KEY idx_csr_letter_company (company_id);

ALTER TABLE kss_csr_approval_letter
  ADD CONSTRAINT fk_csr_letter_company FOREIGN KEY (company_id)
    REFERENCES kss_csr_company (id) ON DELETE RESTRICT;


-- existing approvals were all funded by SMIORE
UPDATE kss_csr_approval_letter
   SET company_id = (SELECT id FROM kss_csr_company WHERE company_name = 'SMIORE')
 WHERE company_id IS NULL;

SET SQL_SAFE_UPDATES = 1;


-- Check ---------------------------------------------------------------
-- SELECT c.company_name, COUNT(l.id) AS approvals, COALESCE(SUM(l.amount), 0) AS sanctioned
--   FROM kss_csr_company c LEFT JOIN kss_csr_approval_letter l ON l.company_id = c.id
--  GROUP BY c.id, c.company_name;
