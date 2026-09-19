package com.DAO;

import java.sql.Connection;
import java.sql.PreparedStatement;

import com.Bean.ScholarshipBean;
import com.Bean.DBUtil;

public class SholrarshipDAO {

    public boolean saveScholarship(ScholarshipBean bean) {

        boolean status = false;

        Connection con = null;
        PreparedStatement ps = null;

        try {

            con = DBUtil.getConnection();

            String sql = "INSERT INTO kss_student_scholarship("
                    + "org_name,"
                    + "emp_no,"
                    + "emp_name,"
                    + "designation,"
                    + "emp_contact," // Added column 5
                    + "children_name,"
                    + "dob,"
                    + "gender,"
                    + "relationship,"
                    + "child_order,"
                    + "spouse_working_smiore,"
                    + "spouse_working_group_companies,"
                    + "college_name,"
                    + "place_college,"
                    + "course,"
                    + "present_year,"
                    + "previous_ay_percentage,"
                    + "fee_amount_current_ay,"
                    + "actual_fee_paid," // Added column 19
                    + "employee_name_passbook,"
                    + "bank_account_no,"
                    + "ifsc_code,"
                    + "bank_name,"
                    + "branch_name"
                    
                    + ") VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)"; // 24 placeholders

            ps = con.prepareStatement(sql);

            ps.setString(1, bean.getOrgName());
            ps.setString(2, bean.getEmpNo());
            ps.setString(3, bean.getEmpName());
            ps.setString(4, bean.getDesignation());
            ps.setString(5, bean.getEmpContact()); // Added parameter mapping

            ps.setString(6, bean.getChildrenName());
            ps.setString(7, bean.getDob());
            ps.setString(8, bean.getGender());
            ps.setString(9, bean.getRelationship());
            ps.setString(10, bean.getChildOrder());

            ps.setString(11, bean.getSpouseWorkingSMIORE());
            ps.setString(12, bean.getSpouseWorkingGroupCompanies());

            ps.setString(13, bean.getCollegeName());
            ps.setString(14, bean.getPlaceCollege());
            ps.setString(15, bean.getCourse());
            ps.setString(16, bean.getPresentYear());

            ps.setDouble(17, bean.getPreviousAyPercentage());
            ps.setDouble(18, bean.getFeeAmountCurrentAy());
            ps.setDouble(19, bean.getActualFeePaid()); // Added parameter mapping

            ps.setString(20, bean.getEmployeeNamePassbook());
            ps.setString(21, bean.getBankAccountNo());
            ps.setString(22, bean.getIfscCode());
            ps.setString(23, bean.getBankName());
            ps.setString(24, bean.getBranchName());

            int i = ps.executeUpdate();

            if (i > 0) {
                status = true;
            }

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