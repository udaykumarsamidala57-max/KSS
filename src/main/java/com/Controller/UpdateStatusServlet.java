package com.Controller;

import com.Bean.ScholarshipBean;
import com.Bean.DBUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

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
        
        List<ScholarshipBean> applicationList = new ArrayList<>();

        // SQL Query fetching records where ALL columns are filled and ALL 9 documents are uploaded,
        // EXCEPT where submitted is empty, NULL, or 'submitted'
        String sql = "SELECT " +
                "id, App_no, org_name, emp_no, emp_name, designation, emp_contact, " +
                "children_name, dob, gender, relationship, child_order, " +
                "spouse_working_smiore, spouse_working_group_companies, " +
                "college_name, place_college, course, present_year, " +
                "previous_ay_percentage, fee_amount_current_ay, actual_fee_paid, " +
                "employee_name_passbook, bank_account_no, ifsc_code, bank_name, branch_name, submiited, " +
                "IF(LENGTH(previous_ay_marks_card) > 0, 'Uploaded', 'Not Uploaded') AS status_marks_card, " +
                "IF(LENGTH(kss_application) > 0, 'Uploaded', 'Not Uploaded') AS status_kss_app, " +
                "IF(LENGTH(fee_structure) > 0, 'Uploaded', 'Not Uploaded') AS status_fee_structure, " +
                "IF(LENGTH(fee_receipts) > 0, 'Uploaded', 'Not Uploaded') AS status_fee_receipts, " +
                "IF(LENGTH(parent_aadhar_copy) > 0, 'Uploaded', 'Not Uploaded') AS status_parent_aadhar_copy, " +
                "IF(LENGTH(student_aadhar_copy) > 0, 'Uploaded', 'Not Uploaded') AS status_student_aadhar_copy, " +
                "IF(LENGTH(bank_passbook_first_page) > 0, 'Uploaded', 'Not Uploaded') AS status_passbook, " +
                "IF(LENGTH(parent_aadhar) > 0, 'Uploaded', 'Not Uploaded') AS status_parent_aadhar, " +
                "IF(LENGTH(student_aadhar) > 0, 'Uploaded', 'Not Uploaded') AS status_student_aadhar " +
                "FROM kss_student_scholarship " +
                "WHERE " +
                "  -- 1. Include ONLY applications where 'submiited' IS NULL, empty string, 'empty', or 'submitted'\n" +
                "  (submiited IS NULL OR TRIM(submiited) = '' OR LOWER(TRIM(submiited)) IN ('submitted', 'empty')) " +

                "  -- 2. Ensure ALL 9 documents are uploaded (length > 0)\n" +
                "  AND LENGTH(previous_ay_marks_card) > 0 " +
                "  AND LENGTH(kss_application) > 0 " +
                "  AND LENGTH(fee_structure) > 0 " +
                "  AND LENGTH(fee_receipts) > 0 " +
                "  AND LENGTH(parent_aadhar_copy) > 0 " +
                "  AND LENGTH(student_aadhar_copy) > 0 " +
                "  AND LENGTH(bank_passbook_first_page) > 0 " +
                "  AND LENGTH(parent_aadhar) > 0 " +
                "  AND LENGTH(student_aadhar) > 0 " +

                "  -- 3. Ensure ALL required data columns are non-null and not empty\n" +
                "  AND App_no IS NOT NULL AND TRIM(App_no) != '' " +
                "  AND org_name IS NOT NULL AND TRIM(org_name) != '' " +
                "  AND emp_no IS NOT NULL AND TRIM(emp_no) != '' " +
                "  AND emp_name IS NOT NULL AND TRIM(emp_name) != '' " +
                "  AND designation IS NOT NULL AND TRIM(designation) != '' " +
                "  AND emp_contact IS NOT NULL AND TRIM(emp_contact) != '' " +
                "  AND children_name IS NOT NULL AND TRIM(children_name) != '' " +
                "  AND dob IS NOT NULL AND TRIM(dob) != '' " +
                "  AND gender IS NOT NULL AND TRIM(gender) != '' " +
                "  AND relationship IS NOT NULL AND TRIM(relationship) != '' " +
                "  AND child_order IS NOT NULL AND TRIM(child_order) != '' " +
                "  AND spouse_working_smiore IS NOT NULL AND TRIM(spouse_working_smiore) != '' " +
                "  AND spouse_working_group_companies IS NOT NULL AND TRIM(spouse_working_group_companies) != '' " +
                "  AND college_name IS NOT NULL AND TRIM(college_name) != '' " +
                "  AND place_college IS NOT NULL AND TRIM(place_college) != '' " +
                "  AND course IS NOT NULL AND TRIM(course) != '' " +
                "  AND present_year IS NOT NULL AND TRIM(present_year) != '' " +
                "  AND previous_ay_percentage IS NOT NULL " +
                "  AND fee_amount_current_ay IS NOT NULL " +
                "  AND actual_fee_paid IS NOT NULL " +
                "  AND employee_name_passbook IS NOT NULL AND TRIM(employee_name_passbook) != '' " +
                "  AND bank_account_no IS NOT NULL AND TRIM(bank_account_no) != '' " +
                "  AND ifsc_code IS NOT NULL AND TRIM(ifsc_code) != '' " +
                "  AND bank_name IS NOT NULL AND TRIM(bank_name) != '' " +
                "  AND branch_name IS NOT NULL AND TRIM(branch_name) != '' " +
                "ORDER BY id DESC";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql);
             ResultSet rs = pstmt.executeQuery()) {

            while (rs.next()) {
                ScholarshipBean app = new ScholarshipBean();
                
                // Primary Keys & Personal Details
                app.setId(rs.getInt("id"));
                app.setApp_no(rs.getString("App_no"));
                app.setOrgName(rs.getString("org_name"));
                app.setEmpNo(rs.getString("emp_no"));
                app.setEmpName(rs.getString("emp_name"));
                app.setDesignation(rs.getString("designation"));
                app.setEmpContact(rs.getString("emp_contact"));

                // Child Details
                app.setChildrenName(rs.getString("children_name"));
                app.setDob(rs.getString("dob"));
                app.setGender(rs.getString("gender"));
                app.setRelationship(rs.getString("relationship"));
                app.setChildOrder(rs.getString("child_order"));

                // Spouse Work Status
                app.setSpouseWorkingSMIORE(rs.getString("spouse_working_smiore"));
                app.setSpouseWorkingGroupCompanies(rs.getString("spouse_working_group_companies"));

                // College & Academic Details
                app.setCollegeName(rs.getString("college_name"));
                app.setPlaceCollege(rs.getString("place_college"));
                app.setCourse(rs.getString("course"));
                app.setPresentYear(rs.getString("present_year"));
                app.setPreviousAyPercentage(rs.getDouble("previous_ay_percentage"));
                app.setFeeAmountCurrentAy(rs.getDouble("fee_amount_current_ay"));
                app.setActualFeePaid(rs.getDouble("actual_fee_paid"));

                // Bank Details
                app.setEmployeeNamePassbook(rs.getString("employee_name_passbook"));
                app.setBankAccountNo(rs.getString("bank_account_no"));
                app.setIfscCode(rs.getString("ifsc_code"));
                app.setBankName(rs.getString("bank_name"));
                app.setBranchName(rs.getString("branch_name"));

                // Application Status
                app.setSubmitted(rs.getString("submiited"));

                // Store document upload statuses inside transient/extra fields on the Bean
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

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Database Error: " + e.getMessage());
        }

        // Attach list to request and forward
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

        // Reload all records after update
        doGet(request, response);
    }
}