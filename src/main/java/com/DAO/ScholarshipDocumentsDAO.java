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

            // SQL update query targeting the exact column definitions
            String sql = "UPDATE kss_student_scholarship SET "
                       + "previous_ay_marks_card = ?, "
                       + "kss_application = ?, "
                       + "fee_structure = ?, "
                       + "fee_receipts = ?, "
                       + "parent_aadhar_copy = ?, "
                       + "student_aadhar_copy = ?, "
                       + "bank_passbook_first_page = ? "
                       + "WHERE id = ?";

            ps = con.prepareStatement(sql);

            // Bind binary stream chunks using setBytes
            ps.setBytes(1, previousAyMarksCard);
            ps.setBytes(2, kssApplication);
            ps.setBytes(3, feeStructure);
            ps.setBytes(4, feeReceipts);
            ps.setBytes(5, parentAadharCopy);
            ps.setBytes(6, studentAadharCopy);
            ps.setBytes(7, bankPassbookFirstPage);
            
            // Bind the where clause row key id
            ps.setInt(8, id);

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