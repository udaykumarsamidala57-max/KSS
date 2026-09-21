package com.DAO;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;

import com.Bean.AuditUtil;
import com.Bean.DBUtil;
import com.Bean.ScholarshipBean;

public class scholarshipListDAO {

    // Helper method to map ResultSet row to ScholarshipBean
    private ScholarshipBean mapResultSetToBean(ResultSet rs) throws Exception {
        ScholarshipBean bean = new ScholarshipBean();
        bean.setId(rs.getInt("id"));
        bean.setApp_no(rs.getString("App_no"));
        bean.setOrgName(rs.getString("org_name"));
        bean.setEmpNo(rs.getString("emp_no"));
        bean.setEmpName(rs.getString("emp_name"));
        bean.setDesignation(rs.getString("designation"));

        bean.setEmpContact(rs.getString("emp_contact"));

        bean.setChildrenName(rs.getString("children_name"));
        bean.setDob(rs.getString("dob"));
        bean.setGender(rs.getString("gender"));
        bean.setRelationship(rs.getString("relationship"));
        bean.setChildOrder(rs.getString("child_order"));

        bean.setSpouseWorkingSMIORE(rs.getString("spouse_working_smiore"));
        bean.setSpouseWorkingGroupCompanies(rs.getString("spouse_working_group_companies"));

        bean.setCollegeName(rs.getString("college_name"));
        bean.setPlaceCollege(rs.getString("place_college"));
        bean.setCourse(rs.getString("course"));
        bean.setPresentYear(rs.getString("present_year"));

        bean.setPreviousAyPercentage(rs.getDouble("previous_ay_percentage"));
        bean.setFeeAmountCurrentAy(rs.getDouble("fee_amount_current_ay"));
        bean.setActualFeePaid(rs.getDouble("actual_fee_paid"));

        bean.setEmployeeNamePassbook(rs.getString("employee_name_passbook"));
        bean.setBankAccountNo(rs.getString("bank_account_no"));
        bean.setIfscCode(rs.getString("ifsc_code"));
        bean.setBankName(rs.getString("bank_name"));
        bean.setBranchName(rs.getString("branch_name"));

        return bean;
    }

    // Record transaction details into the audit table with explicit IST timestamp
    public void logAudit(Connection con, int scholarshipId, String actionType, String appNo, String empNo, String empName, String performedBy, String details) {
        String sql = "INSERT INTO kss_scholarship_audit "
                   + "(scholarship_id, action_type, app_no, emp_no, emp_name, changed_by, changed_at, details) "
                   + "VALUES (?, ?, ?, ?, ?, ?, ?, ?)";

        try (PreparedStatement ps = con.prepareStatement(sql)) {
            // Force current timestamp to Asia/Kolkata (IST)
            LocalDateTime istNow = LocalDateTime.now(ZoneId.of("Asia/Kolkata"));
            Timestamp istTimestamp = Timestamp.valueOf(istNow);

            ps.setInt(1, scholarshipId);
            ps.setString(2, actionType);
            ps.setString(3, appNo);
            ps.setString(4, empNo);
            ps.setString(5, empName);
            ps.setString(6, performedBy);
            ps.setTimestamp(7, istTimestamp);
            ps.setString(8, details);

            ps.executeUpdate();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    // Get All Records
    public List<ScholarshipBean> getAllScholarships(String branch, String role, String department, String username) {
        List<ScholarshipBean> list = new ArrayList<>();
        String sql;

        boolean isSandurEducationSociety = branch != null && "SANDUR EDUCATION SOCIETY".equalsIgnoreCase(branch.trim());
        boolean isSandurHatcheries = branch != null && "SANDUR HATCHERIES PVT LTD".equalsIgnoreCase(branch.trim());

        if ("Global".equalsIgnoreCase(role)) {
            sql = "SELECT * FROM kss_student_scholarship ORDER BY id DESC";
        } else if ("HR".equalsIgnoreCase(role)) {
            sql = "SELECT * FROM kss_student_scholarship WHERE department=? ORDER BY id DESC";
        } else if (isSandurEducationSociety) {
            sql = "SELECT * FROM kss_student_scholarship WHERE LOWER(TRIM(org_name)) IN ("
                + "LOWER(TRIM(?)), LOWER(TRIM(?)), LOWER(TRIM(?)), LOWER(TRIM(?)), LOWER(TRIM(?)), LOWER(TRIM(?))) "
                + "ORDER BY id DESC";
        } else if (isSandurHatcheries) {
            sql = "SELECT * FROM kss_student_scholarship WHERE LOWER(TRIM(org_name)) IN ("
                + "LOWER(TRIM(?)), LOWER(TRIM(?)), LOWER(TRIM(?))) "
                + "ORDER BY id DESC";
        } else {
            sql = "SELECT * FROM kss_student_scholarship WHERE LOWER(TRIM(org_name)) = LOWER(TRIM(?)) ORDER BY id DESC";
        }

        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            if ("HR".equalsIgnoreCase(role)) {
                ps.setString(1, department);
            } else if (!"Global".equalsIgnoreCase(role)) {
                if (isSandurEducationSociety) {
                    ps.setString(1, "SANDUR EDUCATION SOCIETY, SANDUR");
                    ps.setString(2, "SES VIDYAMANDIR PU COLLEGE");
                    ps.setString(3, "SMIORE PRIMARY ENGLISH MEDIUM SCHOOL, DEOGIRI");
                    ps.setString(4, "SMIORE HIGHER PRIMARY SCHOOL, DEOGIRI");
                    ps.setString(5, "SMIORE HIGH SCHOOL, DEOGIRI");
                    ps.setString(6, "SMIORE VYASAPURI HIGHER PRIMARY SCHOOL");
                } else if (isSandurHatcheries) {
                    ps.setString(1, "SANDUR HATCHERIES PVT LTD");
                    ps.setString(2, "SANDUR POULTRY FARM");
                    ps.setString(3, "SANDUR POULTRY BREEDERS");
                } else {
                    ps.setString(1, branch != null ? branch.trim() : "");
                }
            }

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapResultSetToBean(rs));
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    // Get Record By ID
    public ScholarshipBean getScholarshipById(int id) {
        ScholarshipBean bean = null;
        String sql = "SELECT * FROM kss_student_scholarship WHERE id=?";

        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    bean = mapResultSetToBean(rs);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return bean;
    }

    // Overloaded Update Method (Calls AuditUtil to compute exact changes)
    public boolean updateScholarship(ScholarshipBean bean, String performedBy) {
        boolean status = false;

        ScholarshipBean existingBean = getScholarshipById(bean.getId());

        if (existingBean != null) {
            if (bean.getApp_no() == null || bean.getApp_no().trim().isEmpty()) {
                bean.setApp_no(existingBean.getApp_no());
            }
        }

        // Delegate change string building to AuditUtil
        String auditDetails = AuditUtil.getDetailedChanges(existingBean, bean);

        String sql = "UPDATE kss_student_scholarship SET "
                   + "org_name=?, emp_no=?, emp_name=?, designation=?, emp_contact=?, "
                   + "children_name=?, dob=?, gender=?, relationship=?, child_order=?, "
                   + "spouse_working_smiore=?, spouse_working_group_companies=?, "
                   + "college_name=?, place_college=?, course=?, present_year=?, "
                   + "previous_ay_percentage=?, fee_amount_current_ay=?, actual_fee_paid=?, "
                   + "employee_name_passbook=?, bank_account_no=?, ifsc_code=?, bank_name=?, branch_name=? "
                   + "WHERE id=?";

        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, bean.getOrgName());
            ps.setString(2, bean.getEmpNo());
            ps.setString(3, bean.getEmpName());
            ps.setString(4, bean.getDesignation());
            ps.setString(5, bean.getEmpContact());

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
            ps.setDouble(19, bean.getActualFeePaid());

            ps.setString(20, bean.getEmployeeNamePassbook());
            ps.setString(21, bean.getBankAccountNo());
            ps.setString(22, bean.getIfscCode());
            ps.setString(23, bean.getBankName());
            ps.setString(24, bean.getBranchName());

            ps.setInt(25, bean.getId());

            status = ps.executeUpdate() > 0;

            if (status) {
                logAudit(con, bean.getId(), "UPDATE", bean.getApp_no(), bean.getEmpNo(), bean.getEmpName(), performedBy, auditDetails);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return status;
    }

    // Default Update Method (Fallback)
    public boolean updateScholarship(ScholarshipBean bean) {
        return updateScholarship(bean, "SYSTEM");
    }

    // Overloaded Delete Method (Accepts user for auditing)
    public boolean deleteScholarship(int id, String performedBy) {
        boolean status = false;

        ScholarshipBean bean = getScholarshipById(id);
        String sql = "DELETE FROM kss_student_scholarship WHERE id=?";

        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, id);
            status = ps.executeUpdate() > 0;

            if (status && bean != null) {
                logAudit(con, id, "DELETE", bean.getApp_no(), bean.getEmpNo(), bean.getEmpName(), performedBy, "Deleted record via Servlet");
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return status;
    }

    // Default Delete Method (Fallback)
    public boolean deleteScholarship(int id) {
        return deleteScholarship(id, "SYSTEM");
    }
}