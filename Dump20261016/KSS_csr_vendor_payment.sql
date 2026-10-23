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
