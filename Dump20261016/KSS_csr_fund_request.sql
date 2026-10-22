-- =====================================================================
-- KSS CSR Amount Spending : Funds Request Letters (FRL)
--   Approval Letter  ->  Funds Request Letters (many)  ->  Fund Receipts (many per FRL)
-- Run AFTER kss_csr_approval_letter and kss_csr_fund_receipt exist.
-- =====================================================================

-- 1. Funds Request Letters
CREATE TABLE kss_csr_fund_request (
  id               INT NOT NULL AUTO_INCREMENT,
  letter_id        INT NOT NULL,                          -- kss_csr_approval_letter.id
  frl_number       VARCHAR(100)  NOT NULL,
  frl_date         DATE          NOT NULL,
  amount           DECIMAL(14,2) NOT NULL,
  remarks          VARCHAR(500)  DEFAULT NULL,
  attachment       LONGBLOB      DEFAULT NULL,            -- FRL copy (PDF / JPG / PNG)
  attachment_name  VARCHAR(255)  DEFAULT NULL,
  attachment_type  VARCHAR(50)   DEFAULT NULL,
  attachment_size  INT           DEFAULT NULL,
  created_by       VARCHAR(50)   DEFAULT NULL,
  created_at       TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_by       VARCHAR(50)   DEFAULT NULL,
  updated_at       TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_csr_frl_number (frl_number),
  KEY idx_csr_frl_letter (letter_id),
  CONSTRAINT fk_csr_frl_letter FOREIGN KEY (letter_id)
    REFERENCES kss_csr_approval_letter (id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. Link each fund receipt to the FRL it was received against
ALTER TABLE kss_csr_fund_receipt
  ADD COLUMN frl_id INT NULL AFTER letter_id,
  ADD KEY idx_csr_fund_frl (frl_id),
  ADD CONSTRAINT fk_csr_fund_frl FOREIGN KEY (frl_id)
    REFERENCES kss_csr_fund_request (id) ON DELETE RESTRICT;


-- If you already created kss_csr_fund_request WITHOUT remarks, run only this:
-- ALTER TABLE kss_csr_fund_request ADD COLUMN remarks VARCHAR(500) NULL AFTER amount;


-- Useful query: requested vs received per FRL
-- SELECT r.frl_number, l.letter_number, r.amount AS requested,
--        COALESCE(SUM(f.amount), 0) AS received
--   FROM kss_csr_fund_request r
--   JOIN kss_csr_approval_letter l ON l.id = r.letter_id
--   LEFT JOIN kss_csr_fund_receipt f ON f.frl_id = r.id
--  GROUP BY r.id, r.frl_number, l.letter_number, r.amount;
