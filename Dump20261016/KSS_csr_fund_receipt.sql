-- =====================================================================
-- KSS CSR Amount Spending : Fund Receipts (many per Approval Letter)
-- Run AFTER kss_csr_approval_letter exists.
-- =====================================================================

CREATE TABLE kss_csr_fund_receipt (
  id               INT NOT NULL AUTO_INCREMENT,
  letter_id        INT NOT NULL,                          -- kss_csr_approval_letter.id
  receipt_date     DATE          NOT NULL,
  amount           DECIMAL(14,2) NOT NULL,
  payment_mode     ENUM('NEFT','RTGS','IMPS','UPI','Cheque','DD','Cash','Other') NOT NULL DEFAULT 'NEFT',
  reference_no     VARCHAR(100)  DEFAULT NULL,            -- UTR / cheque / DD number
  bank_name        VARCHAR(150)  DEFAULT NULL,
  remarks          VARCHAR(500)  DEFAULT NULL,
  attachment       LONGBLOB      DEFAULT NULL,            -- receipt / bank statement (PDF / JPG / PNG)
  attachment_name  VARCHAR(255)  DEFAULT NULL,
  attachment_type  VARCHAR(50)   DEFAULT NULL,
  attachment_size  INT           DEFAULT NULL,
  created_by       VARCHAR(50)   DEFAULT NULL,
  created_at       TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_by       VARCHAR(50)   DEFAULT NULL,
  updated_at       TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_csr_fund_letter (letter_id),
  CONSTRAINT fk_csr_fund_letter FOREIGN KEY (letter_id)
    REFERENCES kss_csr_approval_letter (id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- Useful query: approved vs received per letter
-- SELECT l.letter_number, l.amount AS approved,
--        COALESCE(SUM(f.amount), 0) AS received,
--        l.amount - COALESCE(SUM(f.amount), 0) AS pending
--   FROM kss_csr_approval_letter l
--   LEFT JOIN kss_csr_fund_receipt f ON f.letter_id = l.id
--  GROUP BY l.id, l.letter_number, l.amount;
