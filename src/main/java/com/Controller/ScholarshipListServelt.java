package com.Controller;

import java.io.IOException;
import java.util.List;

import javax.servlet.RequestDispatcher;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.Bean.ScholarshipBean;
import com.DAO.scholarshipListDAO;

@WebServlet("/ScholarshipListServelt")
public class ScholarshipListServelt extends HttpServlet {

	private static final long serialVersionUID = 1L;

	scholarshipListDAO dao = new scholarshipListDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		
		HttpSession sess = request.getSession(false);
	        if (sess == null || sess.getAttribute("username") == null) {
	            response.sendRedirect("login.jsp");
	            return;
	        }
		String action = request.getParameter("action");

		if (action == null) {
			action = "list";
		}
		

		try {
			switch (action) {

			case "delete":
				String deleteIdParam = request.getParameter("id");
				if (deleteIdParam != null && !deleteIdParam.trim().isEmpty()) {
					int deleteId = Integer.parseInt(deleteIdParam);
					dao.deleteScholarship(deleteId);
				}
				response.sendRedirect("ScholarshipListServelt");
				break;

			case "edit":
				String editIdParam = request.getParameter("id");
				if (editIdParam != null && !editIdParam.trim().isEmpty()) {
					int editId = Integer.parseInt(editIdParam);
					ScholarshipBean bean = dao.getScholarshipById(editId);
					request.setAttribute("bean", bean);
				}
				
				// Forwarding back to list page to let the modal pop up with data if desired
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
		} catch (NumberFormatException e) {
			e.printStackTrace();
			response.sendRedirect("ScholarshipListServelt"); // Fallback on parsing errors
		}
	}

	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		// Handle structural updates safely
		String action = request.getParameter("action");
		
		if ("update".equals(action) || action == null) {
			try {
				ScholarshipBean bean = new ScholarshipBean();

				String idParam = request.getParameter("id");
				if (idParam != null && !idParam.trim().isEmpty()) {
					bean.setId(Integer.parseInt(idParam));
				} else {
					// Fallback redirect if ID is missing or broken
					response.sendRedirect("ScholarshipListServelt");
					return;
				}

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
				} else {
					bean.setPreviousAyPercentage(0.0);
				}

				String fee = request.getParameter("feeAmountCurrentAy");
				if (fee != null && !fee.trim().isEmpty()) {
					bean.setFeeAmountCurrentAy(Double.parseDouble(fee));
				} else {
					bean.setFeeAmountCurrentAy(0.0);
				}

				bean.setEmployeeNamePassbook(request.getParameter("employeeNamePassbook"));
				bean.setBankAccountNo(request.getParameter("bankAccountNo"));
				bean.setIfscCode(request.getParameter("ifscCode"));
				bean.setBankName(request.getParameter("bankName"));
				bean.setBranchName(request.getParameter("branchName"));

				dao.updateScholarship(bean);
				
			} catch (NumberFormatException e) {
				e.printStackTrace();
				// Log error context if structural data conversions break down
			}
		}

		response.sendRedirect("ScholarshipListServelt");
	}
}