-- =====================================================================
-- KSS CSR Amount Spending : part payments of a tax invoice
--   Run this ONLY if KSS_csr_vendor_payment.sql was already run with the old
--   "one voucher per tax invoice" rule (UNIQUE key uq_csr_pay_invoice).
--   It allows one or more payment vouchers for the same tax invoice.
-- Error 1091 (can't drop uq_csr_pay_invoice) = already done, nothing to do.
-- =====================================================================
ALTER TABLE kss_csr_vendor_payment
  ADD KEY idx_csr_pay_invoice (invoice_id),
  DROP INDEX uq_csr_pay_invoice;
