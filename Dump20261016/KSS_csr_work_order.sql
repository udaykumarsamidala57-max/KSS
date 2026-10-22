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
