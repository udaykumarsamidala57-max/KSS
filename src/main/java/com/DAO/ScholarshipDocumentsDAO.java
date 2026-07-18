package com.DAO;

import java.sql.Connection;
import java.sql.PreparedStatement;
import com.Bean.DBUtil;

public class ScholarshipDocumentsDAO {

    public boolean uploadDocuments(int id, 
                                   byte[] previousAyMarksCard, 
                                   byte[] kssApplication, 
                                   byte[] feeStructure, 
                                   byte[] feeReceipts, 
                                   byte[] parentAadharCopy, 
                                   byte[] studentAadharCopy, 
                                   byte[] bankPassbookFirstPage) {
        
        boolean status = false;
        Connection con = null;
        PreparedStatement ps = null;

        try {
            con = DBUtil.getConnection();

            // 1. Identify which documents are actually provided (not empty)
            boolean hasMarksCard = (previousAyMarksCard != null && previousAyMarksCard.length > 0);
            boolean hasKssApp    = (kssApplication != null && kssApplication.length > 0);
            boolean hasFeeStruct = (feeStructure != null && feeStructure.length > 0);
            boolean hasReceipts  = (feeReceipts != null && feeReceipts.length > 0);
            boolean hasParentAd  = (parentAadharCopy != null && parentAadharCopy.length > 0);
            boolean hasStudentAd = (studentAadharCopy != null && studentAadharCopy.length > 0);
            boolean hasPassbook  = (bankPassbookFirstPage != null && bankPassbookFirstPage.length > 0);

            // 2. Build the dynamic SQL query string
            StringBuilder sql = new StringBuilder("UPDATE kss_student_scholarship SET ");
            
            if (hasMarksCard) sql.append("previous_ay_marks_card = ?, ");
            if (hasKssApp)    sql.append("kss_application = ?, ");
            if (hasFeeStruct) sql.append("fee_structure = ?, ");
            if (hasReceipts)  sql.append("fee_receipts = ?, ");
            if (hasParentAd)  sql.append("parent_aadhar_copy = ?, ");
            if (hasStudentAd) sql.append("student_aadhar_copy = ?, ");
            if (hasPassbook)  sql.append("bank_passbook_first_page = ?, ");

            // Remove the trailing comma and space if at least one document is being updated
            if (sql.toString().endsWith(", ")) {
                sql.setLength(sql.length() - 2);
            } else {
                // No new files were uploaded at all; return true to indicate success with no action needed
                return true;
            }

            sql.append(" WHERE id = ?");

            // 3. Prepare the statement and bind parameters sequentially
            ps = con.prepareStatement(sql.toString());
            int paramIndex = 1;

            if (hasMarksCard) ps.setBytes(paramIndex++, previousAyMarksCard);
            if (hasKssApp)    ps.setBytes(paramIndex++, kssApplication);
            if (hasFeeStruct) ps.setBytes(paramIndex++, feeStructure);
            if (hasReceipts)  ps.setBytes(paramIndex++, feeReceipts);
            if (hasParentAd)  ps.setBytes(paramIndex++, parentAadharCopy);
            if (hasStudentAd) ps.setBytes(paramIndex++, studentAadharCopy);
            if (hasPassbook)  ps.setBytes(paramIndex++, bankPassbookFirstPage);
            
            // Final index assignment binds the WHERE clause id
            ps.setInt(paramIndex, id);

            int rowsUpdated = ps.executeUpdate();
            if (rowsUpdated > 0) {
                status = true;
            }

        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            try {
                if (ps != null) ps.close();
            } catch (Exception e) {
                // Suppressed resource close exception
            }
            try {
                if (con != null) con.close();
            } catch (Exception e) {
                // Suppressed resource close exception
            }
        }

        return status;
    }
}