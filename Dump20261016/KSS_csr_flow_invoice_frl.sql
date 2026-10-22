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
