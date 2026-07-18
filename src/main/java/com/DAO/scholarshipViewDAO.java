package com.DAO;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import com.Bean.ScholarshipBean;
import com.Bean.DBUtil;

public class scholarshipViewDAO {

    public ScholarshipBean getScholarshipById(int id) {

        ScholarshipBean bean = null;

        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            con = DBUtil.getConnection();

            // SQL query maps perfectly to the kss_student_scholarship schema
            String sql = "SELECT * FROM kss_student_scholarship WHERE id = ?";

            ps = con.prepareStatement(sql);
            ps.setInt(1, id);

            rs = ps.executeQuery();

            if (rs.next()) {
                bean = new ScholarshipBean();

                // Base Details
                bean.setId(rs.getInt("id"));
                bean.setOrgName(rs.getString("org_name"));
                bean.setEmpNo(rs.getString("emp_no"));
                bean.setEmpName(rs.getString("emp_name"));
                bean.setDesignation(rs.getString("designation"));
                bean.setSpouseWorkingSMIORE(rs.getString("spouse_working_smiore"));
                bean.setSpouseWorkingGroupCompanies(rs.getString("spouse_working_group_companies"));
                
                // Student Details
                bean.setChildrenName(rs.getString("children_name"));
                bean.setDob(rs.getString("dob"));
                bean.setGender(rs.getString("gender"));
                bean.setRelationship(rs.getString("relationship"));
                bean.setChildOrder(rs.getString("child_order"));
                
                // Academic Details
                bean.setCollegeName(rs.getString("college_name"));
                bean.setCourse(rs.getString("course"));
                bean.setPresentYear(rs.getString("present_year"));
                bean.setPreviousAyPercentage(rs.getDouble("previous_ay_percentage"));
                bean.setFeeAmountCurrentAy(rs.getDouble("fee_amount_current_ay"));
                
                // Bank Details
                bean.setEmployeeNamePassbook(rs.getString("employee_name_passbook"));
                bean.setBankAccountNo(rs.getString("bank_account_no"));
                bean.setIfscCode(rs.getString("ifsc_code"));
                bean.setBankName(rs.getString("bank_name"));
                bean.setBranchName(rs.getString("branch_name"));
                
                // Binary Document BLOB Data (Updated from rs.getString to rs.getBytes)
                bean.setPreviousAyMarksCard(rs.getBytes("previous_ay_marks_card"));
                bean.setKssApplication(rs.getBytes("kss_application"));
                bean.setFeeStructure(rs.getBytes("fee_structure"));
                bean.setFeeReceipts(rs.getBytes("fee_receipts"));
                bean.setParentAadharCopy(rs.getBytes("parent_aadhar_copy"));
                bean.setStudentAadharCopy(rs.getBytes("student_aadhar_copy"));
                bean.setBankPassbookFirstPage(rs.getBytes("bank_passbook_first_page"));
            }

        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            try {
                if (rs != null) rs.close();
            } catch (Exception e) {
                // Suppressed close exception
            }
            try {
                if (ps != null) ps.close();
            } catch (Exception e) {
                // Suppressed close exception
            }
            try {
                if (con != null) con.close();
            } catch (Exception e) {
                // Suppressed close exception
            }
        }

        return bean;
    }
}