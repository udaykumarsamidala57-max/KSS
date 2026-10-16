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

-- Dump completed on 2026-10-16 10:51:03
