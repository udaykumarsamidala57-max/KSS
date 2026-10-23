-- HighEducation / KSS database schema reference
-- MySQL 8.x. Consolidated from the dated SQL files under Dump20261016 and Dump20261016 (1).
-- This is a sequential setup/migration script for a fresh KSS database. Review before applying to any database containing data.
-- No connection credentials are included.
SET NAMES utf8mb4;
-- Scholarship application core
-- MySQL dump 10.13  Distrib 8.0.43, for Win64 (x86_64)
--
-- Host: shuttle.proxy.rlwy.net    Database: KSS
-- ------------------------------------------------------
-- Server version	9.7.2

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
SET @MYSQLDUMP_TEMP_LOG_BIN = @@SESSION.SQL_LOG_BIN;
SET @@SESSION.SQL_LOG_BIN= 0;

--
-- GTID state at the beginning of the backup 
--

SET @@GLOBAL.GTID_PURGED=/*!80000 '+'*/ '';

--
-- Table structure for table `kss_student_scholarship`
--

DROP TABLE IF EXISTS `kss_student_scholarship`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `kss_student_scholarship` (
  `id` int NOT NULL AUTO_INCREMENT,
  `App_no` varchar(45) DEFAULT NULL,
  `org_name` varchar(150) NOT NULL,
  `emp_no` varchar(50) NOT NULL,
  `emp_name` varchar(150) NOT NULL,
  `designation` varchar(100) DEFAULT NULL,
  `emp_contact` varchar(45) DEFAULT NULL,
  `children_name` varchar(150) NOT NULL,
  `dob` date DEFAULT NULL,
  `gender` enum('Male','Female','Other') DEFAULT NULL,
  `relationship` varchar(50) DEFAULT NULL,
  `child_order` enum('First','Second') DEFAULT NULL,
  `spouse_working_smiore` enum('Yes','No') DEFAULT 'No',
  `spouse_working_group_companies` enum('Yes','No') DEFAULT 'No',
  `college_name` varchar(200) DEFAULT NULL,
  `place_college` varchar(450) DEFAULT NULL,
  `course` varchar(150) DEFAULT NULL,
  `KSS_courses` varchar(150) DEFAULT NULL,
  `present_year` varchar(50) DEFAULT NULL,
  `previous_ay_percentage` decimal(5,2) DEFAULT NULL,
  `fee_amount_current_ay` decimal(12,2) DEFAULT NULL,
  `actual_fee_paid` decimal(12,0) DEFAULT NULL,
  `employee_name_passbook` varchar(150) DEFAULT NULL,
  `bank_account_no` varchar(50) DEFAULT NULL,
  `ifsc_code` varchar(20) DEFAULT NULL,
  `bank_name` varchar(100) DEFAULT NULL,
  `branch_name` varchar(100) DEFAULT NULL,
  `previous_ay_marks_card` longblob,
  `kss_application` longblob,
  `fee_structure` longblob,
  `fee_receipts` longblob,
  `parent_aadhar_copy` longblob,
  `student_aadhar_copy` longblob,
  `bank_passbook_first_page` longblob,
  `parent_aadhar` longblob,
  `student_aadhar` longblob,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `submiited` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `App_no_UNIQUE` (`App_no`)
) ENGINE=InnoDB AUTO_INCREMENT=169 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
SET @@SESSION.SQL_LOG_BIN = @MYSQLDUMP_TEMP_LOG_BIN;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-10-16 17:34:22

-- MySQL dump 10.13  Distrib 8.0.43, for Win64 (x86_64)
--
-- Host: shuttle.proxy.rlwy.net    Database: KSS
-- ------------------------------------------------------
-- Server version	9.7.2

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
SET @MYSQLDUMP_TEMP_LOG_BIN = @@SESSION.SQL_LOG_BIN;
SET @@SESSION.SQL_LOG_BIN= 0;

--
-- GTID state at the beginning of the backup 
--

SET @@GLOBAL.GTID_PURGED=/*!80000 '+'*/ '';

--
-- Table structure for table `organization_master`
--

DROP TABLE IF EXISTS `organization_master`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `organization_master` (
  `org_id` int NOT NULL AUTO_INCREMENT,
  `org_name` varchar(150) NOT NULL,
  `status` enum('Active','Inactive') DEFAULT 'Active',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`org_id`),
  UNIQUE KEY `org_name` (`org_name`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
SET @@SESSION.SQL_LOG_BIN = @MYSQLDUMP_TEMP_LOG_BIN;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-10-16 17:34:24

-- MySQL dump 10.13  Distrib 8.0.43, for Win64 (x86_64)
--
-- Host: shuttle.proxy.rlwy.net    Database: KSS
-- ------------------------------------------------------
-- Server version	9.7.2

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
SET @MYSQLDUMP_TEMP_LOG_BIN = @@SESSION.SQL_LOG_BIN;
SET @@SESSION.SQL_LOG_BIN= 0;

--
-- GTID state at the beginning of the backup 
--

SET @@GLOBAL.GTID_PURGED=/*!80000 '+'*/ '';

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` int NOT NULL AUTO_INCREMENT,
  `username` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL,
  `role` varchar(255) NOT NULL,
  `department` varchar(45) DEFAULT NULL,
  `mail` varchar(100) DEFAULT NULL,
  `otp` varchar(10) DEFAULT NULL,
  `otp_expiry` datetime DEFAULT NULL,
  `branch` varchar(45) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `ins` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
SET @@SESSION.SQL_LOG_BIN = @MYSQLDUMP_TEMP_LOG_BIN;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-10-16 17:34:27

-- MySQL dump 10.13  Distrib 8.0.43, for Win64 (x86_64)
--
-- Host: shuttle.proxy.rlwy.net    Database: KSS
-- ------------------------------------------------------
-- Server version	9.7.2

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
SET @MYSQLDUMP_TEMP_LOG_BIN = @@SESSION.SQL_LOG_BIN;
SET @@SESSION.SQL_LOG_BIN= 0;

--
-- GTID state at the beginning of the backup 
--

SET @@GLOBAL.GTID_PURGED=/*!80000 '+'*/ '';

--
-- Table structure for table `kss_scholarship_approval`
--

DROP TABLE IF EXISTS `kss_scholarship_approval`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `kss_scholarship_approval` (
  `id` int NOT NULL AUTO_INCREMENT,
  `scholarship_id` int NOT NULL,
  `app_no` varchar(45) DEFAULT NULL,
  `marks_card_status` enum('Pending','Verified','Rejected') NOT NULL DEFAULT 'Pending',
  `marks_card_remarks` varchar(300) DEFAULT NULL,
  `kss_application_status` enum('Pending','Verified','Rejected') NOT NULL DEFAULT 'Pending',
  `kss_application_remarks` varchar(300) DEFAULT NULL,
  `fee_structure_status` enum('Pending','Verified','Rejected') NOT NULL DEFAULT 'Pending',
  `fee_structure_remarks` varchar(300) DEFAULT NULL,
  `fee_receipts_status` enum('Pending','Verified','Rejected') NOT NULL DEFAULT 'Pending',
  `fee_receipts_remarks` varchar(300) DEFAULT NULL,
  `parent_aadhar_status` enum('Pending','Verified','Rejected') NOT NULL DEFAULT 'Pending',
  `parent_aadhar_remarks` varchar(300) DEFAULT NULL,
  `student_aadhar_status` enum('Pending','Verified','Rejected') NOT NULL DEFAULT 'Pending',
  `student_aadhar_remarks` varchar(300) DEFAULT NULL,
  `bank_passbook_status` enum('Pending','Verified','Rejected') NOT NULL DEFAULT 'Pending',
  `bank_passbook_remarks` varchar(300) DEFAULT NULL,
  `docs_verified_by` varchar(50) DEFAULT NULL,
  `docs_verified_at` datetime DEFAULT NULL,
  `final_status` enum('Pending','Approved','Rejected') NOT NULL DEFAULT 'Pending',
  `approved_amount` decimal(12,2) DEFAULT NULL,
  `final_remarks` varchar(500) DEFAULT NULL,
  `approved_by` varchar(50) DEFAULT NULL,
  `approved_at` datetime DEFAULT NULL,
  `reimbursement_status` enum('Not Started','Pending','Reimbursed') NOT NULL DEFAULT 'Not Started',
  `reimbursed_amount` decimal(12,2) DEFAULT NULL,
  `payment_mode` enum('NEFT','RTGS','IMPS','Cheque','Cash','Other') DEFAULT NULL,
  `payment_reference` varchar(100) DEFAULT NULL,
  `reimbursed_date` date DEFAULT NULL,
  `reimbursed_by` varchar(50) DEFAULT NULL,
  `reimbursement_remarks` varchar(500) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_approval_per_app` (`scholarship_id`),
  CONSTRAINT `fk_approval_scholarship` FOREIGN KEY (`scholarship_id`) REFERENCES `kss_student_scholarship` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
SET @@SESSION.SQL_LOG_BIN = @MYSQLDUMP_TEMP_LOG_BIN;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-10-16 17:34:29

-- MySQL dump 10.13  Distrib 8.0.43, for Win64 (x86_64)
--
-- Host: shuttle.proxy.rlwy.net    Database: KSS
-- ------------------------------------------------------
-- Server version	9.7.2

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
SET @MYSQLDUMP_TEMP_LOG_BIN = @@SESSION.SQL_LOG_BIN;
SET @@SESSION.SQL_LOG_BIN= 0;

--
-- GTID state at the beginning of the backup 
--

SET @@GLOBAL.GTID_PURGED=/*!80000 '+'*/ '';

--
-- Table structure for table `kss_scholarship_audit`
--

DROP TABLE IF EXISTS `kss_scholarship_audit`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `kss_scholarship_audit` (
  `audit_id` int NOT NULL AUTO_INCREMENT,
  `scholarship_id` int DEFAULT NULL,
  `action_type` varchar(10) NOT NULL,
  `app_no` varchar(100) DEFAULT NULL,
  `emp_no` varchar(100) DEFAULT NULL,
  `emp_name` varchar(100) DEFAULT NULL,
  `changed_by` varchar(100) DEFAULT NULL,
  `changed_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `details` text,
  PRIMARY KEY (`audit_id`)
) ENGINE=InnoDB AUTO_INCREMENT=250 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
SET @@SESSION.SQL_LOG_BIN = @MYSQLDUMP_TEMP_LOG_BIN;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-10-16 17:34:25

-- CSR base tables and setup steps, in dependency order
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

-- =====================================================================
-- KSS CSR Amount Spending : "Raise FRL for this bill?" on tax invoices
--   1 = Yes (default): the bill is claimed from KSS through an FRL
--   0 = No: money already received through the proforma advance, no FRL for this bill
-- Run AFTER KSS_csr_proforma_settle.sql.
-- =====================================================================
ALTER TABLE kss_csr_invoice
  ADD COLUMN frl_required TINYINT(1) NOT NULL DEFAULT 1 AFTER proforma_id;



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
