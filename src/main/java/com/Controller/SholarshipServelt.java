package com.Controller;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.Bean.ScholarshipBean;
import com.DAO.SholrarshipDAO;

@WebServlet("/SholarshipServelt")
public class SholarshipServelt extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        ScholarshipBean bean = new ScholarshipBean();

        // Employee Details
        bean.setOrgName(request.getParameter("orgName"));
        bean.setEmpNo(request.getParameter("empNo"));
        bean.setEmpName(request.getParameter("empName"));
        bean.setDesignation(request.getParameter("designation"));

        // Student Details
        bean.setChildrenName(request.getParameter("childrenName"));
        bean.setDob(request.getParameter("dob"));
        bean.setGender(request.getParameter("gender"));
        bean.setRelationship(request.getParameter("relationship"));
        bean.setChildOrder(request.getParameter("childOrder"));

        // Spouse Details
        bean.setSpouseWorkingSMIORE(request.getParameter("spouseWorkingSMIORE"));
        bean.setSpouseWorkingGroupCompanies(request.getParameter("spouseWorkingGroupCompanies"));

        // College Details
        bean.setCollegeName(request.getParameter("collegeName"));
        bean.setCourse(request.getParameter("course"));
        bean.setPresentYear(request.getParameter("presentYear"));

        // Percentage
        String per = request.getParameter("previousAyPercentage");
        if (per != null && !per.trim().isEmpty()) {
            bean.setPreviousAyPercentage(Double.parseDouble(per));
        }

        // Fee Amount
        String fee = request.getParameter("feeAmountCurrentAy");
        if (fee != null && !fee.trim().isEmpty()) {
            bean.setFeeAmountCurrentAy(Double.parseDouble(fee));
        }

        // Bank Details
        bean.setEmployeeNamePassbook(request.getParameter("employeeNamePassbook"));
        bean.setBankAccountNo(request.getParameter("bankAccountNo"));
        bean.setIfscCode(request.getParameter("ifscCode"));
        bean.setBankName(request.getParameter("bankName"));
        bean.setBranchName(request.getParameter("branchName"));

        SholrarshipDAO dao = new SholrarshipDAO();

        boolean status = dao.saveScholarship(bean);

        if (status) {
            response.sendRedirect("success.jsp");
        } else {
            response.sendRedirect("scholarship.jsp?msg=failed");
        }
    }
}