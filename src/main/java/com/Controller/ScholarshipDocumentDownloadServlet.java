package com.Controller;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.Bean.DBUtil;

@WebServlet("/ScholarshipDocumentDownloadServlet")
public class ScholarshipDocumentDownloadServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
    	HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return;
        }
        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            String idStr = request.getParameter("id");
            String fieldName = request.getParameter("field");
            
            if (idStr == null || fieldName == null || idStr.trim().isEmpty() || fieldName.trim().isEmpty()) {
                response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Missing required parameters.");
                return;
            }
            
            int id = Integer.parseInt(idStr);
            
            String columnName = null;
            switch(fieldName) {
                case "previousAyMarksCard":    columnName = "previous_ay_marks_card"; break;
                case "kssApplication":          columnName = "kss_application"; break;
                case "feeStructure":            columnName = "fee_structure"; break;
                case "feeReceipts":            columnName = "fee_receipts"; break;
                case "parentAadharCopy":       columnName = "parent_aadhar_copy"; break;
                case "studentAadharCopy":      columnName = "student_aadhar_copy"; break;
                case "bankPassbookFirstPage":  columnName = "bank_passbook_first_page"; break;
            }
            
            if (columnName == null) {
                response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid file token context specified.");
                return;
            }

            con = DBUtil.getConnection();
            
            // Modified SQL: Pull both the dynamic binary payload AND the associated employee's name field
            String sql = "SELECT emp_name, " + columnName + " FROM kss_student_scholarship WHERE id = ?";
            ps = con.prepareStatement(sql);
            ps.setInt(1, id);
            rs = ps.executeQuery();
            
            if (rs.next()) {
                String empName = rs.getString("emp_name");
                byte[] fileData = rs.getBytes(columnName);
                
                if (fileData != null && fileData.length > 0) {
                    response.reset();
                    
                    // Determine file extension and content type dynamically
                    String contentType = "application/pdf"; 
                    String extension = ".pdf"; 
                    
                    if (fileData.length > 4) {
                        if (fileData[0] == 0x25 && fileData[1] == 0x50 && fileData[2] == 0x44 && fileData[3] == 0x46) {
                            contentType = "application/pdf";
                            extension = ".pdf";
                        } 
                        else if ((fileData[0] & 0xFF) == 0xFF && (fileData[1] & 0xFF) == 0xD8) {
                            contentType = "image/jpeg";
                            extension = ".jpg";
                        } 
                        else if ((fileData[0] & 0xFF) == 0x89 && fileData[1] == 0x50 && fileData[2] == 0x4E && fileData[3] == 0x47) {
                            contentType = "image/png";
                            extension = ".png";
                        }
                    }
                    
                    response.setContentType(contentType);
                    response.setContentLength(fileData.length);
                    
                    // Sanitize employee name to replace spaces/special characters with clean underscores
                    if (empName == null || empName.trim().isEmpty()) {
                        empName = "Employee";
                    } else {
                        empName = empName.replaceAll("[^a-zA-Z0-9_-]", "_");
                    }
                    
                    // Combine into the requested format: "ID_EmployeeName_FieldName.extension"
                    String filename = id + "_" + empName + "_" + fieldName + extension;
                    
                    // Using "inline" opens it smoothly in the tab browser preview frame, but retains your naming structure when downloaded/saved
                    response.setHeader("Content-Disposition", "inline; filename=\"" + filename + "\"");
                    
                    response.getOutputStream().write(fileData);
                    response.getOutputStream().flush();
                    return;
                }
            }
            
            response.setContentType("text/html");
            response.getWriter().println("<h3>Error: The requested document payload could not be found or is empty.</h3>");

        } catch (NumberFormatException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid ID format pattern passed.");
        } catch (Exception e) {
            getServletContext().log("Exception encountered inside ScholarshipDocumentDownloadServlet data stream pipeline", e);
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Internal server error streaming binary data content.");
        } finally {
            try { if(rs != null) rs.close(); } catch(Exception e){}
            try { if(ps != null) ps.close(); } catch(Exception e){}
            try { if(con != null) con.close(); } catch(Exception e){}
        }
    }
}