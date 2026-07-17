package com.DAO;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

import com.Bean.DBUtil;
import com.Bean.ScholarshipBean;

public class scholarshipListDAO {

    // Get All Records
    public List<ScholarshipBean> getAllScholarships() {

        List<ScholarshipBean> list = new ArrayList<>();

        try {

            Connection con = DBUtil.getConnection();

            PreparedStatement ps = con.prepareStatement(
                    "SELECT * FROM kss_student_scholarship ORDER BY id DESC");

            ResultSet rs = ps.executeQuery();

            while (rs.next()) {

                ScholarshipBean bean = new ScholarshipBean();

                bean.setId(rs.getInt("id"));
                bean.setOrgName(rs.getString("org_name"));
                bean.setEmpNo(rs.getString("emp_no"));
                bean.setEmpName(rs.getString("emp_name"));
                bean.setDesignation(rs.getString("designation"));

                bean.setChildrenName(rs.getString("children_name"));
                bean.setDob(rs.getString("dob"));
                bean.setGender(rs.getString("gender"));
                bean.setRelationship(rs.getString("relationship"));
                bean.setChildOrder(rs.getString("child_order"));

                bean.setSpouseWorkingSMIORE(rs.getString("spouse_working_smiore"));
                bean.setSpouseWorkingGroupCompanies(rs.getString("spouse_working_group_companies"));

                bean.setCollegeName(rs.getString("college_name"));
                bean.setCourse(rs.getString("course"));
                bean.setPresentYear(rs.getString("present_year"));

                bean.setPreviousAyPercentage(rs.getDouble("previous_ay_percentage"));
                bean.setFeeAmountCurrentAy(rs.getDouble("fee_amount_current_ay"));

                bean.setEmployeeNamePassbook(rs.getString("employee_name_passbook"));
                bean.setBankAccountNo(rs.getString("bank_account_no"));
                bean.setIfscCode(rs.getString("ifsc_code"));
                bean.setBankName(rs.getString("bank_name"));
                bean.setBranchName(rs.getString("branch_name"));

                list.add(bean);
            }

            rs.close();
            ps.close();
            con.close();

        } catch (Exception e) {
            e.printStackTrace();
        }

        return list;
    }

    // Get Record By ID
    public ScholarshipBean getScholarshipById(int id) {

        ScholarshipBean bean = new ScholarshipBean();

        try {

            Connection con = DBUtil.getConnection();

            PreparedStatement ps = con.prepareStatement(
                    "SELECT * FROM kss_student_scholarship WHERE id=?");

            ps.setInt(1, id);

            ResultSet rs = ps.executeQuery();

            if (rs.next()) {

                bean.setId(rs.getInt("id"));
                bean.setOrgName(rs.getString("org_name"));
                bean.setEmpNo(rs.getString("emp_no"));
                bean.setEmpName(rs.getString("emp_name"));
                bean.setDesignation(rs.getString("designation"));

                bean.setChildrenName(rs.getString("children_name"));
                bean.setDob(rs.getString("dob"));
                bean.setGender(rs.getString("gender"));
                bean.setRelationship(rs.getString("relationship"));
                bean.setChildOrder(rs.getString("child_order"));

                bean.setSpouseWorkingSMIORE(rs.getString("spouse_working_smiore"));
                bean.setSpouseWorkingGroupCompanies(rs.getString("spouse_working_group_companies"));

                bean.setCollegeName(rs.getString("college_name"));
                bean.setCourse(rs.getString("course"));
                bean.setPresentYear(rs.getString("present_year"));

                bean.setPreviousAyPercentage(rs.getDouble("previous_ay_percentage"));
                bean.setFeeAmountCurrentAy(rs.getDouble("fee_amount_current_ay"));

                bean.setEmployeeNamePassbook(rs.getString("employee_name_passbook"));
                bean.setBankAccountNo(rs.getString("bank_account_no"));
                bean.setIfscCode(rs.getString("ifsc_code"));
                bean.setBankName(rs.getString("bank_name"));
                bean.setBranchName(rs.getString("branch_name"));
            }

            rs.close();
            ps.close();
            con.close();

        } catch (Exception e) {
            e.printStackTrace();
        }

        return bean;
    }

    // Update
    public boolean updateScholarship(ScholarshipBean bean) {

        boolean status = false;

        try {

            Connection con = DBUtil.getConnection();

            PreparedStatement ps = con.prepareStatement(

                    "UPDATE kss_student_scholarship SET "
                    + "org_name=?,"
                    + "emp_no=?,"
                    + "emp_name=?,"
                    + "designation=?,"
                    + "children_name=?,"
                    + "dob=?,"
                    + "gender=?,"
                    + "relationship=?,"
                    + "child_order=?,"
                    + "spouse_working_smiore=?,"
                    + "spouse_working_group_companies=?,"
                    + "college_name=?,"
                    + "course=?,"
                    + "present_year=?,"
                    + "previous_ay_percentage=?,"
                    + "fee_amount_current_ay=?,"
                    + "employee_name_passbook=?,"
                    + "bank_account_no=?,"
                    + "ifsc_code=?,"
                    + "bank_name=?,"
                    + "branch_name=? "
                    + "WHERE id=?");

            ps.setString(1, bean.getOrgName());
            ps.setString(2, bean.getEmpNo());
            ps.setString(3, bean.getEmpName());
            ps.setString(4, bean.getDesignation());
            ps.setString(5, bean.getChildrenName());
            ps.setString(6, bean.getDob());
            ps.setString(7, bean.getGender());
            ps.setString(8, bean.getRelationship());
            ps.setString(9, bean.getChildOrder());
            ps.setString(10, bean.getSpouseWorkingSMIORE());
            ps.setString(11, bean.getSpouseWorkingGroupCompanies());
            ps.setString(12, bean.getCollegeName());
            ps.setString(13, bean.getCourse());
            ps.setString(14, bean.getPresentYear());
            ps.setDouble(15, bean.getPreviousAyPercentage());
            ps.setDouble(16, bean.getFeeAmountCurrentAy());
            ps.setString(17, bean.getEmployeeNamePassbook());
            ps.setString(18, bean.getBankAccountNo());
            ps.setString(19, bean.getIfscCode());
            ps.setString(20, bean.getBankName());
            ps.setString(21, bean.getBranchName());
            ps.setInt(22, bean.getId());

            status = ps.executeUpdate() > 0;

            ps.close();
            con.close();

        } catch (Exception e) {
            e.printStackTrace();
        }

        return status;
    }

    // Delete
    public boolean deleteScholarship(int id) {

        boolean status = false;

        try {

            Connection con = DBUtil.getConnection();

            PreparedStatement ps = con.prepareStatement(
                    "DELETE FROM kss_student_scholarship WHERE id=?");

            ps.setInt(1, id);

            status = ps.executeUpdate() > 0;

            ps.close();
            con.close();

        } catch (Exception e) {
            e.printStackTrace();
        }

        return status;
    }
}