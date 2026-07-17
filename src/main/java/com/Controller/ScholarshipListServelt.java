package com.Controller;

import java.io.IOException;
import java.util.List;

import javax.servlet.RequestDispatcher;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.Bean.ScholarshipBean;
import com.DAO.scholarshipListDAO;

@WebServlet("/ScholarshipListServelt")
public class ScholarshipListServelt extends HttpServlet {

	private static final long serialVersionUID = 1L;

	scholarshipListDAO dao = new scholarshipListDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		String action = request.getParameter("action");

		if (action == null) {
			action = "list";
		}

		switch (action) {

		case "delete":

			int deleteId = Integer.parseInt(request.getParameter("id"));

			dao.deleteScholarship(deleteId);

			response.sendRedirect("ScholarshipListServelt");
			break;

		case "edit":

			int editId = Integer.parseInt(request.getParameter("id"));

			ScholarshipBean bean = dao.getScholarshipById(editId);

			request.setAttribute("bean", bean);

			RequestDispatcher edit = request.getRequestDispatcher("/ScholarshipApplication.jsp");

			edit.forward(request, response);

			break;

		default:

			List<ScholarshipBean> list = dao.getAllScholarships();

			request.setAttribute("list", list);

			RequestDispatcher listPage = request.getRequestDispatcher("/scholarshipList.jsp");

			listPage.forward(request, response);

			break;
		}

	}

	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		ScholarshipBean bean = new ScholarshipBean();

		bean.setId(Integer.parseInt(request.getParameter("id")));
		bean.setOrgName(request.getParameter("orgName"));
		bean.setEmpNo(request.getParameter("empNo"));
		bean.setEmpName(request.getParameter("empName"));
		bean.setDesignation(request.getParameter("designation"));

		bean.setChildrenName(request.getParameter("childrenName"));
		bean.setDob(request.getParameter("dob"));
		bean.setGender(request.getParameter("gender"));
		bean.setRelationship(request.getParameter("relationship"));
		bean.setChildOrder(request.getParameter("childOrder"));

		bean.setSpouseWorkingSMIORE(request.getParameter("spouseWorkingSMIORE"));
		bean.setSpouseWorkingGroupCompanies(request.getParameter("spouseWorkingGroupCompanies"));

		bean.setCollegeName(request.getParameter("collegeName"));
		bean.setCourse(request.getParameter("course"));
		bean.setPresentYear(request.getParameter("presentYear"));

		String percentage = request.getParameter("previousAyPercentage");

		if (percentage != null && !percentage.trim().isEmpty()) {
			bean.setPreviousAyPercentage(Double.parseDouble(percentage));
		}

		String fee = request.getParameter("feeAmountCurrentAy");

		if (fee != null && !fee.trim().isEmpty()) {
			bean.setFeeAmountCurrentAy(Double.parseDouble(fee));
		}

		bean.setEmployeeNamePassbook(request.getParameter("employeeNamePassbook"));
		bean.setBankAccountNo(request.getParameter("bankAccountNo"));
		bean.setIfscCode(request.getParameter("ifscCode"));
		bean.setBankName(request.getParameter("bankName"));
		bean.setBranchName(request.getParameter("branchName"));

		dao.updateScholarship(bean);

		response.sendRedirect("ScholarshipListServelt");

	}

}