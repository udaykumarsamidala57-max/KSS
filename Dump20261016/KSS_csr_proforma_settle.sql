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
