package com.Controller;

import java.io.File;
import java.io.IOException;
import java.nio.file.Paths;
import java.util.UUID;

import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.Part;

import com.DAO.ScholarshipDocumentsDAO;

@WebServlet("/ScholarshipDocumentUploadServlet")
@MultipartConfig(
        fileSizeThreshold = 1024 * 1024,
        maxFileSize = 10 * 1024 * 1024,
        maxRequestSize = 70 * 1024 * 1024
)
public class ScholarshipDocumentUploadServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doPost(javax.servlet.http.HttpServletRequest request,
                          javax.servlet.http.HttpServletResponse response)
            throws ServletException, IOException {

        try {

            int id = Integer.parseInt(request.getParameter("id"));

            // Upload folder
            String uploadPath = getServletContext().getRealPath("") +
                    File.separator + "uploads" +
                    File.separator + "scholarship";

            File uploadDir = new File(uploadPath);

            if (!uploadDir.exists()) {
                uploadDir.mkdirs();
            }

            String previousAyMarksCard = uploadFile(request.getPart("previousAyMarksCard"), uploadPath);
            String kssApplication = uploadFile(request.getPart("kssApplication"), uploadPath);
            String feeStructure = uploadFile(request.getPart("feeStructure"), uploadPath);
            String feeReceipts = uploadFile(request.getPart("feeReceipts"), uploadPath);
            String parentAadharCopy = uploadFile(request.getPart("parentAadharCopy"), uploadPath);
            String studentAadharCopy = uploadFile(request.getPart("studentAadharCopy"), uploadPath);
            String bankPassbookFirstPage = uploadFile(request.getPart("bankPassbookFirstPage"), uploadPath);

            ScholarshipDocumentsDAO dao = new ScholarshipDocumentsDAO();

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

                response.getWriter().println("Failed to update database.");

            }

        } catch (Exception e) {

            e.printStackTrace();
            throw new ServletException(e);

        }

    }

    private String uploadFile(Part part, String uploadPath) throws IOException {

        if (part == null || part.getSize() == 0) {
            return "";
        }

        String originalFileName =
                Paths.get(part.getSubmittedFileName()).getFileName().toString();

        String extension = "";

        int index = originalFileName.lastIndexOf(".");

        if (index > 0) {
            extension = originalFileName.substring(index);
        }

        String uniqueFileName =
                UUID.randomUUID().toString() + extension;

        part.write(uploadPath + File.separator + uniqueFileName);

        return uniqueFileName;
    }

    protected void doGet(javax.servlet.http.HttpServletRequest request,
                         javax.servlet.http.HttpServletResponse response)
            throws ServletException, IOException {

        doPost(request, response);

    }

}