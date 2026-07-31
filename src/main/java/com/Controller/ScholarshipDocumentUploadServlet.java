package com.Controller;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.Part;

import com.DAO.ScholarshipDocumentsDAO;

@WebServlet("/ScholarshipDocumentUploadServlet")
@MultipartConfig(
        fileSizeThreshold = 1024 * 1024,      // 1 MB
        maxFileSize = 10 * 1024 * 1024,       // 10 MB per file
        maxRequestSize = 70 * 1024 * 1024     // 70 MB total request size
)
public class ScholarshipDocumentUploadServlet extends HttpServlet {

	
	
    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        try {
            int id = Integer.parseInt(request.getParameter("id"));

            // Read the file Parts directly into byte arrays from request streams
            byte[] previousAyMarksCard = getBytesFromPart(request.getPart("previousAyMarksCard"));
            byte[] kssApplication = getBytesFromPart(request.getPart("kssApplication"));
            byte[] feeStructure = getBytesFromPart(request.getPart("feeStructure"));
            byte[] feeReceipts = getBytesFromPart(request.getPart("feeReceipts"));
            byte[] parentAadharCopy = getBytesFromPart(request.getPart("parentAadharCopy"));
            byte[] studentAadharCopy = getBytesFromPart(request.getPart("studentAadharCopy"));
            byte[] bankPassbookFirstPage = getBytesFromPart(request.getPart("bankPassbookFirstPage"));

            ScholarshipDocumentsDAO dao = new ScholarshipDocumentsDAO();

            // Fire database update containing raw bytes
            boolean status = dao.uploadDocuments(
                    id,
                    previousAyMarksCard,
                    kssApplication,
                    feeStructure,
                    feeReceipts,
                    parentAadharCopy,
                    studentAadharCopy,
                    bankPassbookFirstPage);

            if (status) {
                response.sendRedirect("ScholarshipViewServlet?id=" + id);
            } else {
                response.setContentType("text/html");
                response.getWriter().println("Failed to update documents in database.");
            }

        } catch (NumberFormatException e) {
            getServletContext().log("Invalid format target record ID inside upload parameters", e);
            response.sendRedirect("ScholarshipListServelt");
        } catch (Exception e) {
            getServletContext().log("Exception encountered during document binary streaming pipeline processing", e);
            throw new ServletException(e);
        }
    }

    /**
     * Extracts byte data out of incoming HTTP part chunks directly into memory buffers
     */
    private byte[] getBytesFromPart(Part part) throws IOException {
        if (part == null || part.getSize() == 0) {
            return null; // Return null so the database layer doesn't overwrite existing uploads with empty data
        }
        
        try (InputStream inputStream = part.getInputStream();
             ByteArrayOutputStream buffer = new ByteArrayOutputStream()) {
            
            byte[] temp = new byte[4096];
            int bytesRead;
            
            while ((bytesRead = inputStream.read(temp)) != -1) {
                buffer.write(temp, 0, bytesRead);
            }
            
            return buffer.toByteArray();
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        doPost(request, response);
    }
}