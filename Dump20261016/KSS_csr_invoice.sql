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
