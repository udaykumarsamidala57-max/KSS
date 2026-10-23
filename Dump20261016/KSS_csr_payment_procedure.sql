-- Payment Procedure: Deductions for tax invoices (TDS, retention, debit notes, advance payments)
-- Global users enter these during payment processing

CREATE TABLE IF NOT EXISTS kss_csr_payment_procedure (
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  invoice_id INT NOT NULL,
  payment_date DATE NOT NULL,

  -- Deductions (each optional, defaults to 0)
  debit_note_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  debit_note_description VARCHAR(500) NULL,

  tds_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  retention_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  advance_paid DECIMAL(14,2) NOT NULL DEFAULT 0.00,

  -- Total deductions (computed: sum of above 4 fields)
  total_deductions DECIMAL(14,2) NOT NULL DEFAULT 0.00,

  remarks VARCHAR(500) NULL,
  created_by VARCHAR(50) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_by VARCHAR(50) NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  KEY invoice_id (invoice_id),
  FOREIGN KEY (invoice_id) REFERENCES kss_csr_invoice(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
