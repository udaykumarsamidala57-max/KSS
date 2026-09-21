package com.Controller;

import com.Bean.ScholarshipBean;
import com.Bean.DBUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

@WebServlet("/UpdateStatusServlet")
public class UpdateStatusServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        String role = (String) sess.getAttribute("role");
        String branch = (String) sess.getAttribute("branch");

        boolean isSandurEducationSociety = "SANDUR EDUCATION SOCIETY".equalsIgnoreCase(branch);
        boolean isSandurHatcheries = "SANDUR HATCHERIES".equalsIgnoreCase(branch);

        List<ScholarshipBean> applicationList = new ArrayList<>();

        // Base SQL Query
        StringBuilder sqlBuilder = new StringBuilder();
        sqlBuilder.append("SELECT ")
                  .append("id, App_no, org_name, emp_no, emp_name, designation, emp_contact, ")
                  .append("children_name, dob, gender, relationship, child_order, ")
                  .append("spouse_working_smiore, spouse_working_group_companies, ")
                  .append("college_name, place_college, course, present_year, ")
                  .append("previous_ay_percentage, fee_amount_current_ay, actual_fee_paid, ")
                  .append("employee_name_passbook, bank_account_no, ifsc_code, bank_name, branch_name, submiited, ")
                  .append("IF(LENGTH(previous_ay_marks_card) > 0, 'Uploaded', 'Not Uploaded') AS status_marks_card, ")
                  .append("IF(LENGTH(kss_application) > 0, 'Uploaded', 'Not Uploaded') AS status_kss_app, ")
                  .append("IF(LENGTH(fee_structure) > 0, 'Uploaded', 'Not Uploaded') AS status_fee_structure, ")
                  .append("IF(LENGTH(fee_receipts) > 0, 'Uploaded', 'Not Uploaded') AS status_fee_receipts, ")
                  .append("IF(LENGTH(parent_aadhar_copy) > 0, 'Uploaded', 'Not Uploaded') AS status_parent_aadhar_copy, ")
                  .append("IF(LENGTH(student_aadhar_copy) > 0, 'Uploaded', 'Not Uploaded') AS status_student_aadhar_copy, ")
                  .append("IF(LENGTH(bank_passbook_first_page) > 0, 'Uploaded', 'Not Uploaded') AS status_passbook, ")
                  .append("IF(LENGTH(parent_aadhar) > 0, 'Uploaded', 'Not Uploaded') AS status_parent_aadhar, ")
                  .append("IF(LENGTH(student_aadhar) > 0, 'Uploaded', 'Not Uploaded') AS status_student_aadhar ")
                  .append("FROM kss_student_scholarship ")
                  .append("WHERE ")
                  .append("  (submiited IS NULL OR TRIM(submiited) = '' OR LOWER(TRIM(submiited)) = 'empty') ")
                  .append("  AND LENGTH(previous_ay_marks_card) > 0 ")
                  .append("  AND LENGTH(kss_application) > 0 ")
                  .append("  AND LENGTH(fee_structure) > 0 ")
                  .append("  AND LENGTH(fee_receipts) > 0 ")
                  .append("  AND LENGTH(parent_aadhar_copy) > 0 ")
                  .append("  AND LENGTH(student_aadhar_copy) > 0 ")
                  .append("  AND LENGTH(bank_passbook_first_page) > 0 ")
                  .append("  AND LENGTH(parent_aadhar) > 0 ")
                  .append("  AND LENGTH(student_aadhar) > 0 ")
                  .append("  AND App_no IS NOT NULL AND TRIM(App_no) != '' ")
                  .append("  AND org_name IS NOT NULL AND TRIM(org_name) != '' ")
                  .append("  AND emp_no IS NOT NULL AND TRIM(emp_no) != '' ")
                  .append("  AND emp_name IS NOT NULL AND TRIM(emp_name) != '' ")
                  .append("  AND designation IS NOT NULL AND TRIM(designation) != '' ")
                  .append("  AND emp_contact IS NOT NULL AND TRIM(emp_contact) != '' ")
                  .append("  AND children_name IS NOT NULL AND TRIM(children_name) != '' ")
                  .append("  AND dob IS NOT NULL AND TRIM(dob) != '' ")
                  .append("  AND gender IS NOT NULL AND TRIM(gender) != '' ")
                  .append("  AND relationship IS NOT NULL AND TRIM(relationship) != '' ")
                  .append("  AND child_order IS NOT NULL AND TRIM(child_order) != '' ")
                  .append("  AND spouse_working_smiore IS NOT NULL AND TRIM(spouse_working_smiore) != '' ")
                  .append("  AND spouse_working_group_companies IS NOT NULL AND TRIM(spouse_working_group_companies) != '' ")
                  .append("  AND college_name IS NOT NULL AND TRIM(college_name) != '' ")
                  .append("  AND place_college IS NOT NULL AND TRIM(place_college) != '' ")
                  .append("  AND course IS NOT NULL AND TRIM(course) != '' ")
                  .append("  AND present_year IS NOT NULL AND TRIM(present_year) != '' ")
                  .append("  AND previous_ay_percentage IS NOT NULL ")
                  .append("  AND fee_amount_current_ay IS NOT NULL ")
                  .append("  AND actual_fee_paid IS NOT NULL ")
                  .append("  AND employee_name_passbook IS NOT NULL AND TRIM(employee_name_passbook) != '' ")
                  .append("  AND bank_account_no IS NOT NULL AND TRIM(bank_account_no) != '' ")
                  .append("  AND ifsc_code IS NOT NULL AND TRIM(ifsc_code) != '' ")
                  .append("  AND bank_name IS NOT NULL AND TRIM(bank_name) != '' ")
                  .append("  AND branch_name IS NOT NULL AND TRIM(branch_name) != '' ");

        // Append org_name filtering if role is not "Global"
        if (!"Global".equalsIgnoreCase(role)) {
            if (isSandurEducationSociety) {
                sqlBuilder.append("  AND org_name IN (?, ?, ?, ?, ?, ?) ");
            } else if (isSandurHatcheries) {
                sqlBuilder.append("  AND org_name IN (?, ?, ?) ");
            } else {
                sqlBuilder.append("  AND org_name = ? ");
            }
        }

        sqlBuilder.append("ORDER BY id DESC");

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sqlBuilder.toString())) {

            // Bind parameters for non-Global roles
            if (!"Global".equalsIgnoreCase(role)) {
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
                    ScholarshipBean app = new ScholarshipBean();
                    
                    app.setId(rs.getInt("id"));
                    app.setApp_no(rs.getString("App_no"));
                    app.setOrgName(rs.getString("org_name"));
                    app.setEmpNo(rs.getString("emp_no"));
                    app.setEmpName(rs.getString("emp_name"));
                    app.setDesignation(rs.getString("designation"));
                    app.setEmpContact(rs.getString("emp_contact"));

                    app.setChildrenName(rs.getString("children_name"));
                    app.setDob(rs.getString("dob"));
                    app.setGender(rs.getString("gender"));
                    app.setRelationship(rs.getString("relationship"));
                    app.setChildOrder(rs.getString("child_order"));

                    app.setSpouseWorkingSMIORE(rs.getString("spouse_working_smiore"));
                    app.setSpouseWorkingGroupCompanies(rs.getString("spouse_working_group_companies"));

                    app.setCollegeName(rs.getString("college_name"));
                    app.setPlaceCollege(rs.getString("place_college"));
                    app.setCourse(rs.getString("course"));
                    app.setPresentYear(rs.getString("present_year"));
                    app.setPreviousAyPercentage(rs.getDouble("previous_ay_percentage"));
                    app.setFeeAmountCurrentAy(rs.getDouble("fee_amount_current_ay"));
                    app.setActualFeePaid(rs.getDouble("actual_fee_paid"));

                    app.setEmployeeNamePassbook(rs.getString("employee_name_passbook"));
                    app.setBankAccountNo(rs.getString("bank_account_no"));
                    app.setIfscCode(rs.getString("ifsc_code"));
                    app.setBankName(rs.getString("bank_name"));
                    app.setBranchName(rs.getString("branch_name"));

                    app.setSubmitted(rs.getString("submiited"));

                    app.setMarksCardStatus(rs.getString("status_marks_card"));
                    app.setKssAppStatus(rs.getString("status_kss_app"));
                    app.setFeeStructureStatus(rs.getString("status_fee_structure"));
                    app.setFeeReceiptsStatus(rs.getString("status_fee_receipts"));
                    app.setParentAadharCopyStatus(rs.getString("status_parent_aadhar_copy"));
                    app.setStudentAadharCopyStatus(rs.getString("status_student_aadhar_copy"));
                    app.setPassbookStatus(rs.getString("status_passbook"));
                    app.setParentAadharStatus(rs.getString("status_parent_aadhar"));
                    app.setStudentAadharStatus(rs.getString("status_student_aadhar"));

                    applicationList.add(app);
                }
            }

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Database Error: " + e.getMessage());
        }

        request.setAttribute("applicationList", applicationList);
        request.getRequestDispatcher("updateStatus.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        int scholarshipId = Integer.parseInt(request.getParameter("scholarshipId"));
        String newStatus = request.getParameter("submitted");

        String sql = "UPDATE kss_student_scholarship SET submiited = ? WHERE id = ?";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setString(1, newStatus);
            pstmt.setInt(2, scholarshipId);

            int rowsUpdated = pstmt.executeUpdate();
            if (rowsUpdated > 0) {
                request.setAttribute("message", "Status updated successfully for ID: " + scholarshipId);
            } else {
                request.setAttribute("error", "Failed to update status. Application ID not found.");
            }
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Database Error: " + e.getMessage());
        }

        doGet(request, response);
    }
}