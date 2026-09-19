package com.DAO;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import com.Bean.ScholarshipBean;
import com.Bean.DBUtil;

public class SholrarshipDAO {

    public boolean saveScholarship(ScholarshipBean bean) {

        boolean status = false;

        Connection con = null;
        PreparedStatement psAppNo = null;
        PreparedStatement psInsert = null;
        ResultSet rs = null;

        try {
            con = DBUtil.getConnection();

            // 1. Query to find the lowest unused/deleted application number
            String appNoQuery = "SELECT MIN(t1.id) AS next_num "
                              + "FROM ("
                              + "    SELECT 1 AS id "
                              + "    UNION ALL "
                              + "    SELECT (CAST(SUBSTRING(App_no, 9) AS UNSIGNED) + 1) "
                              + "    FROM kss_student_scholarship "
                              + "    WHERE App_no LIKE 'KSSH26/%' "
                              + ") t1 "
                              + "LEFT JOIN kss_student_scholarship t2 "
                              + "       ON t1.id = CAST(SUBSTRING(t2.App_no, 9) AS UNSIGNED) "
                              + "      AND t2.App_no LIKE 'KSSH26/%' "
                              + "WHERE t2.App_no IS NULL";

            psAppNo = con.prepareStatement(appNoQuery);
            rs = psAppNo.executeQuery();

            int nextNum = 1;
            if (rs.next()) {
                nextNum = rs.getInt("next_num");
                if (nextNum == 0) {
                    nextNum = 1;
                }
            }

            // Format string: e.g., KSSH/26/0002
            String generatedAppNo = String.format("KSSH26/%04d", nextNum);

            // 2. Insert query including App_no
            String sql = "INSERT INTO kss_student_scholarship("
                    + "App_no, org_name, emp_no, emp_name, designation, emp_contact, "
                    + "children_name, dob, gender, relationship, child_order, "
                    + "spouse_working_smiore, spouse_working_group_companies, college_name, "
                    + "place_college, course, present_year, previous_ay_percentage, "
                    + "fee_amount_current_ay, actual_fee_paid, employee_name_passbook, "
                    + "bank_account_no, ifsc_code, bank_name, branch_name"
                    + ") VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)"; // 25 placeholders

            psInsert = con.prepareStatement(sql);

            psInsert.setString(1, generatedAppNo); // Pass the generated App_no
            psInsert.setString(2, bean.getOrgName());
            psInsert.setString(3, bean.getEmpNo());
            psInsert.setString(4, bean.getEmpName());
            psInsert.setString(5, bean.getDesignation());
            psInsert.setString(6, bean.getEmpContact());
            psInsert.setString(7, bean.getChildrenName());
            psInsert.setString(8, bean.getDob());
            psInsert.setString(9, bean.getGender());
            psInsert.setString(10, bean.getRelationship());
            psInsert.setString(11, bean.getChildOrder());
            psInsert.setString(12, bean.getSpouseWorkingSMIORE());
            psInsert.setString(13, bean.getSpouseWorkingGroupCompanies());
            psInsert.setString(14, bean.getCollegeName());
            psInsert.setString(15, bean.getPlaceCollege());
            psInsert.setString(16, bean.getCourse());
            psInsert.setString(17, bean.getPresentYear());
            psInsert.setDouble(18, bean.getPreviousAyPercentage());
            psInsert.setDouble(19, bean.getFeeAmountCurrentAy());
            psInsert.setDouble(20, bean.getActualFeePaid());
            psInsert.setString(21, bean.getEmployeeNamePassbook());
            psInsert.setString(22, bean.getBankAccountNo());
            psInsert.setString(23, bean.getIfscCode());
            psInsert.setString(24, bean.getBankName());
            psInsert.setString(25, bean.getBranchName());

            int i = psInsert.executeUpdate();
            if (i > 0) {
                status = true;
            }

        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            try { if (rs != null) rs.close(); } catch (Exception e) {}
            try { if (psAppNo != null) psAppNo.close(); } catch (Exception e) {}
            try { if (psInsert != null) psInsert.close(); } catch (Exception e) {}
            try { if (con != null) con.close(); } catch (Exception e) {}
        }

        return status;
    }
}