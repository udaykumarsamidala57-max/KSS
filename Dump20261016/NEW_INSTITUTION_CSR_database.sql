-- =====================================================================
-- NEW DATABASE FOR ONE MORE INSTITUTION (CSR module only), e.g. SSS_CSR
--   Run this whole file ONCE on the new, empty MySQL database of that institution.
--   It creates: the users table (login) and all CSR tables, in their final form.
--   Do NOT run it on the KSS database.
-- =====================================================================

CREATE TABLE users (
  id          INT NOT NULL AUTO_INCREMENT,
  username    VARCHAR(50)  NOT NULL,
  password    VARCHAR(255) NOT NULL,
  role        VARCHAR(255) NOT NULL,          -- 'Global' can use CSR
  department  VARCHAR(45)  DEFAULT NULL,
  mail        VARCHAR(100) DEFAULT NULL,
  otp         VARCHAR(10)  DEFAULT NULL,
  otp_expiry  DATETIME     DEFAULT NULL,
  branch      VARCHAR(45)  DEFAULT NULL,
  created_at  TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  ins         VARCHAR(45)  DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY username (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;



-- ---------------------------------------------------------------- KSS_csr_approval_letter.sql
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


-- ---------------------------------------------------------------- KSS_csr_work_order.sql
-- =====================================================================
-- KSS CSR Amount Spending - Step 2 : Work Orders (against Approval Letters)
-- Run AFTER kss_csr_approval_letter exists.
-- =====================================================================

-- Work order header + vendor details + attachment
CREATE TABLE kss_csr_work_order (
  id               INT NOT NULL AUTO_INCREMENT,
  letter_id        INT NOT NULL,                          -- kss_csr_approval_letter.id
  wo_number        VARCHAR(100)  NOT NULL,                -- Work order number (unique)
  wo_date          DATE          NOT NULL,
  vendor_name      VARCHAR(200)  NOT NULL,
  vendor_phone     VARCHAR(20)   DEFAULT NULL,
  vendor_address   VARCHAR(500)  DEFAULT NULL,
  vendor_email     VARCHAR(150)  DEFAULT NULL,
  vendor_gstin     VARCHAR(15)   DEFAULT NULL,
  subtotal         DECIMAL(14,2) NOT NULL DEFAULT 0.00,   -- sum of prices
  gst_total        DECIMAL(14,2) NOT NULL DEFAULT 0.00,   -- sum of GST
  total_amount     DECIMAL(14,2) NOT NULL DEFAULT 0.00,   -- subtotal + GST
  attachment       LONGBLOB      DEFAULT NULL,            -- PDF / JPG / PNG
  attachment_name  VARCHAR(255)  DEFAULT NULL,
  attachment_type  VARCHAR(50)   DEFAULT NULL,
  attachment_size  INT           DEFAULT NULL,
  created_by       VARCHAR(50)   DEFAULT NULL,
  created_at       TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_by       VARCHAR(50)   DEFAULT NULL,
  updated_at       TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_csr_wo_number (wo_number),
  KEY idx_csr_wo_letter (letter_id),
  CONSTRAINT fk_csr_wo_letter FOREIGN KEY (letter_id)
    REFERENCES kss_csr_approval_letter (id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Work order line items : Particulars - Price - GST - Amount
CREATE TABLE kss_csr_work_order_item (
  id               INT NOT NULL AUTO_INCREMENT,
  work_order_id    INT NOT NULL,                          -- kss_csr_work_order.id
  line_no          INT NOT NULL,
  particulars      VARCHAR(500)  NOT NULL,
  price            DECIMAL(14,2) NOT NULL,                -- price before GST
  gst_percent      DECIMAL(5,2)  NOT NULL DEFAULT 0.00,   -- e.g. 18.00
  gst_amount       DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  amount           DECIMAL(14,2) NOT NULL,                -- price + GST
  PRIMARY KEY (id),
  KEY idx_csr_woi_wo (work_order_id),
  CONSTRAINT fk_csr_woi_wo FOREIGN KEY (work_order_id)
    REFERENCES kss_csr_work_order (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- Useful queries ------------------------------------------------------

-- Approval letter vs work orders (committed and balance)
-- SELECT l.letter_number, l.amount AS approved,
--        COALESCE(SUM(w.total_amount), 0) AS committed,
--        l.amount - COALESCE(SUM(w.total_amount), 0) AS balance
--   FROM kss_csr_approval_letter l
--   LEFT JOIN kss_csr_work_order w ON w.letter_id = l.id
--  GROUP BY l.id, l.letter_number, l.amount;


-- ---------------------------------------------------------------- KSS_csr_invoice.sql
-- =====================================================================
-- KSS CSR Amount Spending - Step 3 : Invoices (against Work Orders)
-- Run AFTER kss_csr_work_order exists.
-- =====================================================================

CREATE TABLE kss_csr_invoice (
  id               INT NOT NULL AUTO_INCREMENT,
  work_order_id    INT NOT NULL,                          -- kss_csr_work_order.id
  invoice_number   VARCHAR(100)  NOT NULL,
  invoice_date     DATE          NOT NULL,
  price            DECIMAL(14,2) NOT NULL,                -- price before GST
  gst_percent      DECIMAL(5,2)  NOT NULL DEFAULT 0.00,
  gst_amount       DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  amount           DECIMAL(14,2) NOT NULL,                -- price + GST
  attachment       LONGBLOB      DEFAULT NULL,            -- invoice copy (PDF / JPG / PNG)
  attachment_name  VARCHAR(255)  DEFAULT NULL,
  attachment_type  VARCHAR(50)   DEFAULT NULL,
  attachment_size  INT           DEFAULT NULL,
  created_by       VARCHAR(50)   DEFAULT NULL,
  created_at       TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_by       VARCHAR(50)   DEFAULT NULL,
  updated_at       TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_csr_invoice_per_wo (work_order_id, invoice_number),
  KEY idx_csr_inv_wo (work_order_id),
  CONSTRAINT fk_csr_inv_wo FOREIGN KEY (work_order_id)
    REFERENCES kss_csr_work_order (id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- Useful query: work order vs invoices
-- SELECT w.wo_number, w.total_amount AS wo_total,
--        COALESCE(SUM(i.amount), 0) AS invoiced,
--        w.total_amount - COALESCE(SUM(i.amount), 0) AS balance
--   FROM kss_csr_work_order w
--   LEFT JOIN kss_csr_invoice i ON i.work_order_id = w.id
--  GROUP BY w.id, w.wo_number, w.total_amount;


-- ---------------------------------------------------------------- KSS_csr_fund_receipt.sql
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


-- ---------------------------------------------------------------- KSS_csr_fund_request.sql
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


-- ---------------------------------------------------------------- KSS_csr_flow_invoice_frl.sql
-- =====================================================================
-- KSS CSR Amount Spending : new flow
--   Approval Letter -> Work Order -> Proforma / Tax Invoices
--                   -> Funds Request Letter (against one or more invoices)
--                   -> Fund Receipts (against the FRL)
-- Run AFTER KSS_csr_invoice.sql and KSS_csr_fund_request.sql.
-- =====================================================================

-- 1. Invoice type: Proforma or Tax Invoice (existing invoices become Tax Invoice)
ALTER TABLE kss_csr_invoice
  ADD COLUMN invoice_type ENUM('Proforma','Tax Invoice') NOT NULL DEFAULT 'Tax Invoice' AFTER work_order_id;

-- 2. Which invoices are covered by which FRL (an invoice can be in only one FRL)
CREATE TABLE kss_csr_frl_invoice (
  frl_id      INT NOT NULL,
  invoice_id  INT NOT NULL,
  PRIMARY KEY (frl_id, invoice_id),
  UNIQUE KEY uq_csr_frl_invoice (invoice_id),
  CONSTRAINT fk_csr_frlinv_frl FOREIGN KEY (frl_id)
    REFERENCES kss_csr_fund_request (id) ON DELETE CASCADE,
  CONSTRAINT fk_csr_frlinv_invoice FOREIGN KEY (invoice_id)
    REFERENCES kss_csr_invoice (id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- Useful query: FRL with its invoices
-- SELECT r.frl_number, r.amount, i.invoice_type, i.invoice_number, i.amount AS invoice_amount
--   FROM kss_csr_fund_request r
--   JOIN kss_csr_frl_invoice fi ON fi.frl_id = r.id
--   JOIN kss_csr_invoice i ON i.id = fi.invoice_id
--  ORDER BY r.id, i.invoice_date;


-- ---------------------------------------------------------------- KSS_csr_proforma_settle.sql
-- =====================================================================
-- KSS CSR Amount Spending : Proforma (advance) settled by Tax Invoice
--   * A Proforma is an advance request, not a bill.
--   * When the final Tax Invoice comes, it is linked to the Proforma it settles
--     (one Proforma -> one Tax Invoice). The Proforma then stops counting.
--   * An FRL stores how much it claims for each invoice:
--       Proforma     -> full proforma amount (advance)
--       Tax Invoice  -> invoice amount minus the advance already claimed on its proforma
-- Run AFTER KSS_csr_flow_invoice_frl.sql.
-- =====================================================================

-- 1. Tax invoice -> the proforma it settles
ALTER TABLE kss_csr_invoice
  ADD COLUMN proforma_id INT NULL AFTER invoice_type,
  ADD UNIQUE KEY uq_csr_inv_proforma (proforma_id),
  ADD CONSTRAINT fk_csr_inv_proforma FOREIGN KEY (proforma_id)
    REFERENCES kss_csr_invoice (id) ON DELETE RESTRICT;

-- 2. Amount claimed for each invoice inside an FRL
ALTER TABLE kss_csr_frl_invoice
  ADD COLUMN claim_amount DECIMAL(14,2) NULL;

UPDATE kss_csr_frl_invoice fi
  JOIN kss_csr_invoice i ON i.id = fi.invoice_id
   SET fi.claim_amount = i.amount
 WHERE fi.claim_amount IS NULL;

ALTER TABLE kss_csr_frl_invoice
  MODIFY claim_amount DECIMAL(14,2) NOT NULL;


-- ---------------------------------------------------------------- KSS_csr_invoice_frl_required.sql
-- =====================================================================
-- KSS CSR Amount Spending : "Raise FRL for this bill?" on tax invoices
--   1 = Yes (default): the bill is claimed from KSS through an FRL
--   0 = No: money already received through the proforma advance, no FRL for this bill
-- Run AFTER KSS_csr_proforma_settle.sql.
-- =====================================================================
ALTER TABLE kss_csr_invoice
  ADD COLUMN frl_required TINYINT(1) NOT NULL DEFAULT 1 AFTER proforma_id;


-- ---------------------------------------------------------------- KSS_csr_vendor_payment.sql
-- =====================================================================
-- KSS CSR Amount Spending : Payments to vendors
--   1) Particulars on each invoice (what the bill is for)
--   2) Advances paid to a vendor against a work order
--   3) Payment vouchers against tax invoices, with deductions. A bill can be paid in parts (one or more vouchers);
--        each voucher settles net paid + debit note + TDS + retention + advance adjusted, never more than the balance due
-- Run AFTER KSS_csr_invoice_frl_required.sql.
-- Error 1060 (duplicate column) / 1050 (table exists) = that step already ran, skip it.
-- =====================================================================

ALTER TABLE kss_csr_invoice
  ADD COLUMN particulars VARCHAR(500) DEFAULT NULL AFTER invoice_date;


CREATE TABLE kss_csr_vendor_advance (
  id               INT NOT NULL AUTO_INCREMENT,
  work_order_id    INT NOT NULL,                          -- kss_csr_work_order.id
  advance_date     DATE          NOT NULL,
  amount           DECIMAL(14,2) NOT NULL,
  payment_mode     ENUM('NEFT','RTGS','IMPS','UPI','Cheque','DD','Cash','Other') NOT NULL DEFAULT 'NEFT',
  reference_no     VARCHAR(100)  DEFAULT NULL,            -- UTR / cheque / DD number
  bank_name        VARCHAR(150)  DEFAULT NULL,
  remarks          VARCHAR(500)  DEFAULT NULL,
  attachment       LONGBLOB      DEFAULT NULL,            -- payment proof (PDF / JPG / PNG)
  attachment_name  VARCHAR(255)  DEFAULT NULL,
  attachment_type  VARCHAR(50)   DEFAULT NULL,
  attachment_size  INT           DEFAULT NULL,
  created_by       VARCHAR(50)   DEFAULT NULL,
  created_at       TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_by       VARCHAR(50)   DEFAULT NULL,
  updated_at       TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_csr_adv_wo (work_order_id),
  CONSTRAINT fk_csr_adv_wo FOREIGN KEY (work_order_id)
    REFERENCES kss_csr_work_order (id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


CREATE TABLE kss_csr_vendor_payment (
  id                 INT NOT NULL AUTO_INCREMENT,
  invoice_id         INT NOT NULL,                        -- kss_csr_invoice.id (tax invoice only); several vouchers allowed
  voucher_no         VARCHAR(100)  NOT NULL,
  payment_date       DATE          NOT NULL,
  bill_amount        DECIMAL(14,2) NOT NULL,              -- copy of the invoice amount when the voucher was saved
  debit_note_amount  DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  debit_note_remarks VARCHAR(500)  DEFAULT NULL,
  tds_section        VARCHAR(20)   DEFAULT NULL,          -- 194C / 194J / 194I / 194Q ; NULL = not deducted
  tds_percent        DECIMAL(5,2)  NOT NULL DEFAULT 0.00,
  tds_amount         DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  retention_percent  DECIMAL(5,2)  NOT NULL DEFAULT 0.00,
  retention_amount   DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  advance_adjusted   DECIMAL(14,2) NOT NULL DEFAULT 0.00, -- from kss_csr_vendor_advance of the same work order
  net_paid           DECIMAL(14,2) NOT NULL,              -- amount paid now by bank / cheque
  payment_mode       ENUM('NEFT','RTGS','IMPS','UPI','Cheque','DD','Cash','Other') NOT NULL DEFAULT 'NEFT',
  reference_no       VARCHAR(100)  DEFAULT NULL,
  bank_name          VARCHAR(150)  DEFAULT NULL,
  remarks            VARCHAR(500)  DEFAULT NULL,
  attachment         LONGBLOB      DEFAULT NULL,          -- payment proof (PDF / JPG / PNG)
  attachment_name    VARCHAR(255)  DEFAULT NULL,
  attachment_type    VARCHAR(50)   DEFAULT NULL,
  attachment_size    INT           DEFAULT NULL,
  created_by         VARCHAR(50)   DEFAULT NULL,
  created_at         TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_by         VARCHAR(50)   DEFAULT NULL,
  updated_at         TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_csr_pay_invoice (invoice_id),
  UNIQUE KEY uq_csr_pay_voucher (voucher_no),
  CONSTRAINT fk_csr_pay_invoice FOREIGN KEY (invoice_id)
    REFERENCES kss_csr_invoice (id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ---------------------------------------------------------------- KSS_csr_company.sql
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
