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
