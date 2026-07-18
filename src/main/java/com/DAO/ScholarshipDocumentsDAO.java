package com.DAO;

import java.sql.Connection;
import java.sql.PreparedStatement;

import com.Bean.DBUtil;

public class ScholarshipDocumentsDAO {

    public boolean uploadDocuments(
            int id,
            String previousAyMarksCard,
            String kssApplication,
            String feeStructure,
            String feeReceipts,
            String parentAadharCopy,
            String studentAadharCopy,
            String bankPassbookFirstPage) {

        boolean status = false;

        Connection con = null;
        PreparedStatement ps = null;

        try {

            con = DBUtil.getConnection();

            String sql = "UPDATE kss_student_scholarship SET "
                    + "previous_ay_marks_card=?,"
                    + "kss_application=?,"
                    + "fee_structure=?,"
                    + "fee_receipts=?,"
                    + "parent_aadhar_copy=?,"
                    + "student_aadhar_copy=?,"
                    + "bank_passbook_first_page=? "
                    + "WHERE id=?";

            ps = con.prepareStatement(sql);

            ps.setString(1, previousAyMarksCard);
            ps.setString(2, kssApplication);
            ps.setString(3, feeStructure);
            ps.setString(4, feeReceipts);
            ps.setString(5, parentAadharCopy);
            ps.setString(6, studentAadharCopy);
            ps.setString(7, bankPassbookFirstPage);
            ps.setInt(8, id);

            status = ps.executeUpdate() > 0;

        } catch (Exception e) {

            e.printStackTrace();

        } finally {

            try {
                if (ps != null)
                    ps.close();
            } catch (Exception e) {
            }

            try {
                if (con != null)
                    con.close();
            } catch (Exception e) {
            }

        }

        return status;
    }

}