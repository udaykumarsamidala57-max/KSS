-- =====================================================================
-- KSS CSR Amount Spending : Approval Letters
-- One row per approval letter (with the signed PDF stored in the row)
-- =====================================================================

CREATE TABLE kss_csr_approval_letter (
  id              INT NOT NULL AUTO_INCREMENT,
  letter_name     VARCHAR(200)  NOT NULL,                 -- Letter name / subject
  letter_number   VARCHAR(100)  NOT NULL,                 -- Letter number (unique)
  activity_kind   VARCHAR(150)  NOT NULL,                 -- Kind of CSR activity
  place           VARCHAR(200)  NOT NULL,                 -- Place
  particulars     TEXT          DEFAULT NULL,             -- Particulars / details
  amount          DECIMAL(14,2) NOT NULL DEFAULT 0.00,    -- Approved amount (Rs)
  pdf_file        LONGBLOB      DEFAULT NULL,             -- Approval letter PDF
  pdf_name        VARCHAR(255)  DEFAULT NULL,             -- Original file name
  pdf_size        INT           DEFAULT NULL,             -- File size in bytes
  created_by      VARCHAR(50)   DEFAULT NULL,
  created_at      TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_by      VARCHAR(50)   DEFAULT NULL,
  updated_at      TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_csr_letter_number (letter_number),
  KEY idx_csr_activity (activity_kind)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- Useful queries ------------------------------------------------------

-- Total approved amount
-- SELECT SUM(amount) FROM kss_csr_approval_letter;

-- Amount by kind of CSR activity
-- SELECT activity_kind, COUNT(*) AS letters, SUM(amount) AS total
--   FROM kss_csr_approval_letter GROUP BY activity_kind ORDER BY total DESC;
