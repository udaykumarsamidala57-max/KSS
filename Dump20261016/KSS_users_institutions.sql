-- =====================================================================
-- Logins for all institutions are kept in the KSS users table.
-- Run on the KSS database only.
--   institutions = other institutions this user may also open, comma separated (SSS).
--   NULL / empty = KSS only (all existing users stay as they are).
-- Error 1060 (duplicate column) = step 1 already ran, skip it.
-- =====================================================================

-- 1) new column
ALTER TABLE users
  ADD COLUMN institutions VARCHAR(100) DEFAULT NULL AFTER branch;

-- 2) give SSS access to a user (role must be Global to use CSR)
--    UPDATE users SET institutions = 'SSS' WHERE username = 'the_login';
--    remove SSS access:
--    UPDATE users SET institutions = NULL WHERE username = 'the_login';

-- 3) read-only database login used by the SSS deployment to check passwords (it can only read users)
--    choose your own strong password and put the same one in the SSS service variable AUTH_DB_PASSWORD
--    CREATE USER 'sss_login'@'%' IDENTIFIED BY 'a_strong_password';
--    GRANT SELECT ON KSS.users TO 'sss_login'@'%';
