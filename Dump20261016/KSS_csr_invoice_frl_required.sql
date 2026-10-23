-- =====================================================================
-- KSS CSR Amount Spending : "Raise FRL for this bill?" on tax invoices
--   1 = Yes (default): the bill is claimed from KSS through an FRL
--   0 = No: money already received through the proforma advance, no FRL for this bill
-- Run AFTER KSS_csr_proforma_settle.sql.
-- =====================================================================
ALTER TABLE kss_csr_invoice
  ADD COLUMN frl_required TINYINT(1) NOT NULL DEFAULT 1 AFTER proforma_id;
