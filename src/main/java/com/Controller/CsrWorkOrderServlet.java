package com.Controller;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLIntegrityConstraintViolationException;
import java.sql.Statement;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.servlet.http.Part;

import com.Bean.DBUtil;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

/**
 * KSS CSR Amount Spending - Step 2 : Work Orders against Approval Letters (Global role only).
 *
 *  GET  CsrWorkOrderServlet[?letterId=N]                 -> list page (csrWorkOrders.jsp)
 *  GET  CsrWorkOrderServlet?action=form[&id=N|&letterId=N] -> add / edit form (csrWorkOrderForm.jsp)
 *  GET  CsrWorkOrderServlet?action=file&id=N             -> open the attachment
 *  POST action=save   (multipart, AJAX)                  -> add / update (items sent as JSON)
 *  POST action=delete (AJAX)                             -> delete
 */
@WebServlet("/CsrWorkOrderServlet")
@MultipartConfig(maxFileSize = 10 * 1024 * 1024, maxRequestSize = 12 * 1024 * 1024)
public class CsrWorkOrderServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private static final int MAX_FILE_BYTES = 10 * 1024 * 1024;
    private static final char NBSP = (char) 160;
    private static final BigDecimal HUNDRED = new BigDecimal("100");

    private static final String WO_COLUMNS =
            "w.id, w.letter_id, w.wo_number, DATE_FORMAT(w.wo_date, '%Y-%m-%d') AS wo_date_iso, "
          + "DATE_FORMAT(w.wo_date, '%d-%m-%Y') AS wo_date_txt, w.vendor_name, w.vendor_phone, w.vendor_address, "
          + "w.vendor_email, w.vendor_gstin, w.subtotal, w.gst_total, w.total_amount, "
          + "w.attachment_name, w.attachment_type, w.attachment_size, w.created_by, "
          + "DATE_FORMAT(w.created_at, '%d-%m-%Y') AS created_txt, "
          + "l.letter_number, l.letter_name, l.activity_kind, l.place, l.amount AS letter_amount, "
          + "(SELECT COALESCE(SUM(" + CsrInvoiceServlet.counted("x") + "), 0) FROM kss_csr_invoice x WHERE x.work_order_id = w.id) AS invoiced, "
          + "(SELECT COUNT(*) FROM kss_csr_invoice x WHERE x.work_order_id = w.id) AS inv_count";

    private boolean isGlobal(HttpSession sess) {
        String role = (String) sess.getAttribute("role");
        return role != null && "Global".equalsIgnoreCase(role.replace(NBSP, ' ').trim());
    }

    // ================================================================== GET
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return;
        }
        if (!isGlobal(sess)) {
            response.sendRedirect("Dashboard.jsp");
            return;
        }

        String action = request.getParameter("action");
        if ("file".equals(action)) {
            streamFile(request, response);
            return;
        }
        if ("form".equals(action)) {
            showForm(request, response);
            return;
        }

        // ---- list
        List<Map<String, String>> rows = new ArrayList<>();
        List<Map<String, String>> letters = new ArrayList<>();
        String letterFilter = request.getParameter("letterId");
        Map<String, List<Map<String, String>>> itemsByWo = new LinkedHashMap<>();
        try (Connection con = DBUtil.getConnection()) {
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT " + WO_COLUMNS + ", (SELECT COUNT(*) FROM kss_csr_work_order_item i WHERE i.work_order_id = w.id) AS item_count "
                  + "FROM kss_csr_work_order w JOIN kss_csr_approval_letter l ON l.id = w.letter_id "
                  + "ORDER BY w.wo_date DESC, w.id DESC");
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, String> r = woMap(rs);
                    r.put("itemCount", String.valueOf(rs.getInt("item_count")));
                    rows.add(r);
                }
            }
            letters = loadLetters(con);
            // Line items of all work orders (shown when a row is expanded)
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT work_order_id, particulars, price, gst_percent, gst_amount, amount "
                  + "FROM kss_csr_work_order_item ORDER BY work_order_id, line_no");
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, String> m = new LinkedHashMap<>();
                    m.put("particulars", rs.getString("particulars"));
                    m.put("price", money2(rs.getBigDecimal("price")));
                    m.put("gst", rs.getBigDecimal("gst_percent").stripTrailingZeros().toPlainString());
                    m.put("gstAmount", money2(rs.getBigDecimal("gst_amount")));
                    m.put("amount", money2(rs.getBigDecimal("amount")));
                    itemsByWo.computeIfAbsent(String.valueOf(rs.getInt("work_order_id")), k -> new ArrayList<>()).add(m);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Database error: " + e.getMessage()
                    + " (Have the kss_csr_work_order tables been created?)");
        }
        request.setAttribute("itemsByWo", itemsByWo);
        request.setAttribute("rows", rows);
        request.setAttribute("letters", letters);
        request.setAttribute("letterFilter", letterFilter != null && letterFilter.matches("\\d+") ? letterFilter : "");
        request.getRequestDispatcher("/csrWorkOrders.jsp").forward(request, response);
    }

    /** Add / edit form. */
    private void showForm(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String idParam = request.getParameter("id");
        String letterParam = request.getParameter("letterId");
        Map<String, String> wo = null;
        List<Map<String, String>> items = new ArrayList<>();
        List<Map<String, String>> letters = new ArrayList<>();
        List<Map<String, String>> vendors = new ArrayList<>();

        try (Connection con = DBUtil.getConnection()) {
            if (idParam != null && idParam.matches("\\d+")) {
                int id = Integer.parseInt(idParam);
                try (PreparedStatement ps = con.prepareStatement(
                        "SELECT " + WO_COLUMNS + " FROM kss_csr_work_order w JOIN kss_csr_approval_letter l ON l.id = w.letter_id WHERE w.id = ?")) {
                    ps.setInt(1, id);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) wo = woMap(rs);
                    }
                }
                if (wo == null) {
                    response.sendRedirect("CsrWorkOrderServlet");
                    return;
                }
                items = loadItems(con, id);
            }
            letters = loadLetters(con);
            // Previous vendors (latest details for each name) for auto-fill
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT w.vendor_name, w.vendor_phone, w.vendor_address, w.vendor_email, w.vendor_gstin "
                  + "FROM kss_csr_work_order w JOIN (SELECT vendor_name, MAX(id) AS max_id FROM kss_csr_work_order GROUP BY vendor_name) v "
                  + "ON v.max_id = w.id ORDER BY w.vendor_name");
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, String> v = new LinkedHashMap<>();
                    v.put("name", rs.getString(1));
                    v.put("phone", rs.getString(2));
                    v.put("address", rs.getString(3));
                    v.put("email", rs.getString(4));
                    v.put("gstin", rs.getString(5));
                    vendors.add(v);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Database error: " + e.getMessage()
                    + " (Have the kss_csr_work_order tables been created?)");
        }
        request.setAttribute("wo", wo);
        request.setAttribute("items", items);
        request.setAttribute("letters", letters);
        request.setAttribute("vendors", vendors);
        request.setAttribute("presetLetterId", letterParam != null && letterParam.matches("\\d+") ? letterParam : "");
        request.getRequestDispatcher("/csrWorkOrderForm.jsp").forward(request, response);
    }

    private void streamFile(HttpServletRequest request, HttpServletResponse response) throws IOException {
        String idParam = request.getParameter("id");
        if (idParam == null || !idParam.matches("\\d+")) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid work order.");
            return;
        }
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(
                     "SELECT wo_number, attachment, attachment_name, attachment_type FROM kss_csr_work_order WHERE id = ?")) {
            ps.setInt(1, Integer.parseInt(idParam));
            try (ResultSet rs = ps.executeQuery()) {
                byte[] data = rs.next() ? rs.getBytes("attachment") : null;
                if (data == null) {
                    response.sendError(HttpServletResponse.SC_NOT_FOUND, "Attachment not found.");
                    return;
                }
                String type = rs.getString("attachment_type");
                String name = rs.getString("attachment_name");
                if (name == null || name.trim().isEmpty()) name = "WorkOrder_" + rs.getString("wo_number");
                name = name.replaceAll("[^A-Za-z0-9._-]", "_");
                response.setContentType(type == null ? "application/octet-stream" : type);
                response.setContentLength(data.length);
                response.setHeader("Content-Disposition", "inline; filename=\"" + name + "\"");
                response.getOutputStream().write(data);
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Could not open the attachment.");
        }
    }

    // ================================================================== POST (AJAX)
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sess = request.getSession(false);
        if (sess == null || sess.getAttribute("username") == null) {
            sendJson(response, 401, fail("Your session has expired. Please log in again."));
            return;
        }
        if (!isGlobal(sess)) {
            sendJson(response, 403, fail("Only Global users can manage work orders."));
            return;
        }
        String user = (String) sess.getAttribute("username");

        try (Connection con = DBUtil.getConnection()) {
            String action = request.getParameter("action");
            if ("save".equals(action)) {
                save(request, response, con, user);
            } else if ("delete".equals(action)) {
                delete(request, response, con);
            } else {
                sendJson(response, 400, fail("Unknown action."));
            }
        } catch (IllegalStateException tooBig) {
            sendJson(response, 400, fail("The attachment is too large (maximum 10 MB)."));
        } catch (Exception e) {
            e.printStackTrace();
            sendJson(response, 500, fail("Database error: " + e.getMessage()));
        }
    }

    private void save(HttpServletRequest request, HttpServletResponse response, Connection con, String user) throws Exception {
        String idParam = trim(request.getParameter("id"));
        String letterParam = trim(request.getParameter("letterId"));
        String woNumber = trim(request.getParameter("woNumber"));
        String woDate = trim(request.getParameter("woDate"));
        String vName = trim(request.getParameter("vendorName"));
        String vPhone = trim(request.getParameter("vendorPhone"));
        String vAddress = trim(request.getParameter("vendorAddress"));
        String vEmail = trim(request.getParameter("vendorEmail"));
        String vGstin = trim(request.getParameter("vendorGstin")).toUpperCase();
        String itemsJson = request.getParameter("items");

        // ---- header validation
        if (!letterParam.matches("\\d+")) { sendJson(response, 400, fail("Please select the Approval Letter.")); return; }
        if (woNumber.isEmpty())           { sendJson(response, 400, fail("Please enter the WO Number.")); return; }
        if (woNumber.length() > 100)      { sendJson(response, 400, fail("WO Number is too long.")); return; }
        LocalDate date;
        try {
            date = LocalDate.parse(woDate);
        } catch (Exception e) {
            sendJson(response, 400, fail("Please enter a valid WO Date."));
            return;
        }
        if (vName.isEmpty())              { sendJson(response, 400, fail("Please enter the Vendor Name.")); return; }
        if (vName.length() > 200 || vAddress.length() > 500) { sendJson(response, 400, fail("Vendor name or address is too long.")); return; }
        if (!vPhone.isEmpty() && !vPhone.matches("[0-9+\\- ]{6,20}")) {
            sendJson(response, 400, fail("Please enter a valid vendor phone number."));
            return;
        }
        if (!vEmail.isEmpty() && (vEmail.length() > 150 || !vEmail.matches("[^@\\s]+@[^@\\s]+\\.[^@\\s]+"))) {
            sendJson(response, 400, fail("Please enter a valid vendor email ID."));
            return;
        }
        if (!vGstin.isEmpty() && !vGstin.matches("[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]")) {
            sendJson(response, 400, fail("GSTIN must be 15 characters, e.g. 29ABCDE1234F1Z5."));
            return;
        }

        // ---- line items (amounts are always recalculated here)
        List<BigDecimal[]> nums = new ArrayList<>();   // {price, gstPercent, gstAmount, amount}
        List<String> texts = new ArrayList<>();
        BigDecimal subtotal = BigDecimal.ZERO, gstTotal = BigDecimal.ZERO;
        try {
            JsonElement parsed = JsonParser.parseString(itemsJson == null ? "[]" : itemsJson);
            JsonArray arr = parsed.isJsonArray() ? parsed.getAsJsonArray() : new JsonArray();
            for (JsonElement el : arr) {
                JsonObject o = el.getAsJsonObject();
                String part = o.has("particulars") && !o.get("particulars").isJsonNull() ? trim(o.get("particulars").getAsString()) : "";
                String priceS = o.has("price") && !o.get("price").isJsonNull() ? trim(o.get("price").getAsString()) : "";
                String gstS = o.has("gst") && !o.get("gst").isJsonNull() ? trim(o.get("gst").getAsString()) : "0";
                if (part.isEmpty() && priceS.isEmpty()) continue;   // skip blank rows
                int line = texts.size() + 1;
                if (part.isEmpty()) { sendJson(response, 400, fail("Line " + line + ": please enter the particulars.")); return; }
                if (part.length() > 500) { sendJson(response, 400, fail("Line " + line + ": particulars are too long.")); return; }
                BigDecimal price, gst;
                try {
                    price = new BigDecimal(priceS.replace(",", ""));
                    gst = new BigDecimal(gstS.isEmpty() ? "0" : gstS);
                } catch (NumberFormatException e) {
                    sendJson(response, 400, fail("Line " + line + ": please enter a valid price and GST."));
                    return;
                }
                if (price.signum() <= 0 || price.compareTo(new BigDecimal("999999999999")) > 0) {
                    sendJson(response, 400, fail("Line " + line + ": please enter a valid price."));
                    return;
                }
                if (gst.signum() < 0 || gst.compareTo(HUNDRED) > 0) {
                    sendJson(response, 400, fail("Line " + line + ": GST % must be between 0 and 100."));
                    return;
                }
                price = price.setScale(2, RoundingMode.HALF_UP);
                gst = gst.setScale(2, RoundingMode.HALF_UP);
                BigDecimal gstAmt = price.multiply(gst).divide(HUNDRED, 2, RoundingMode.HALF_UP);
                BigDecimal amount = price.add(gstAmt);
                nums.add(new BigDecimal[]{price, gst, gstAmt, amount});
                texts.add(part);
                subtotal = subtotal.add(price);
                gstTotal = gstTotal.add(gstAmt);
            }
        } catch (Exception e) {
            sendJson(response, 400, fail("Could not read the particulars. Please try again."));
            return;
        }
        if (texts.isEmpty()) { sendJson(response, 400, fail("Please add at least one particulars line.")); return; }
        BigDecimal total = subtotal.add(gstTotal);

        // ---- attachment (optional)
        byte[] file = null;
        String fileName = null, fileType = null;
        Part part = request.getPart("attachment");
        if (part != null && part.getSize() > 0) {
            if (part.getSize() > MAX_FILE_BYTES) { sendJson(response, 400, fail("The attachment is too large (maximum 10 MB).")); return; }
            file = readAll(part.getInputStream());
            fileType = detectType(file);
            if (fileType == null) { sendJson(response, 400, fail("Attachment must be a PDF, JPG or PNG file.")); return; }
            fileName = part.getSubmittedFileName();
            if (fileName != null) fileName = fileName.replaceAll("^.*[\\\\/]", "");
            if (fileName != null && fileName.length() > 255) fileName = fileName.substring(fileName.length() - 255);
        }

        boolean isNew = idParam.isEmpty();
        if (!isNew && !idParam.matches("\\d+")) { sendJson(response, 400, fail("Invalid work order.")); return; }
        int letterId = Integer.parseInt(letterParam);
        int id = isNew ? 0 : Integer.parseInt(idParam);

        // ---- budget check: all work orders of the letter must not exceed its approved amount
        BigDecimal letterAmount = null;
        String letterNumber = null;
        try (PreparedStatement ps = con.prepareStatement("SELECT amount, letter_number FROM kss_csr_approval_letter WHERE id = ?")) {
            ps.setInt(1, letterId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) { letterAmount = rs.getBigDecimal(1); letterNumber = rs.getString(2); }
            }
        }
        if (letterAmount == null) { sendJson(response, 400, fail("Approval letter not found. Please reload the page.")); return; }
        BigDecimal others;
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT COALESCE(SUM(total_amount), 0) FROM kss_csr_work_order WHERE letter_id = ? AND id <> ?")) {
            ps.setInt(1, letterId);
            ps.setInt(2, id);
            try (ResultSet rs = ps.executeQuery()) { rs.next(); others = rs.getBigDecimal(1); }
        }
        if (!isNew) {
            BigDecimal invoiced;
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT COALESCE(SUM(" + CsrInvoiceServlet.counted("x") + "), 0) FROM kss_csr_invoice x WHERE x.work_order_id = ?")) {
                ps.setInt(1, id);
                try (ResultSet rs = ps.executeQuery()) { rs.next(); invoiced = rs.getBigDecimal(1); }
            }
            if (total.compareTo(invoiced) < 0) {
                sendJson(response, 400, fail("Work order total Rs " + total.toPlainString()
                        + " cannot be less than the amount already invoiced Rs " + invoiced.toPlainString() + "."));
                return;
            }
            BigDecimal advancePaid;
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT COALESCE(SUM(amount), 0) FROM kss_csr_vendor_advance WHERE work_order_id = ?")) {
                ps.setInt(1, id);
                try (ResultSet rs = ps.executeQuery()) { rs.next(); advancePaid = rs.getBigDecimal(1); }
            }
            if (total.compareTo(advancePaid) < 0) {
                sendJson(response, 400, fail("Work order total Rs " + total.toPlainString()
                        + " cannot be less than the advance already paid to the vendor Rs " + advancePaid.toPlainString() + "."));
                return;
            }
        }
        BigDecimal balance = letterAmount.subtract(others);
        if (total.compareTo(balance) > 0) {
            sendJson(response, 400, fail("Work order total Rs " + total.toPlainString() + " exceeds the balance Rs "
                    + balance.toPlainString() + " of approval letter " + letterNumber + "."));
            return;
        }

        // ---- save (header + items in one transaction)
        con.setAutoCommit(false);
        try {
            if (isNew) {
                try (PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO kss_csr_work_order (letter_id, wo_number, wo_date, vendor_name, vendor_phone, vendor_address, "
                      + "vendor_email, vendor_gstin, subtotal, gst_total, total_amount, attachment, attachment_name, attachment_type, "
                      + "attachment_size, created_by, updated_by) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
                        Statement.RETURN_GENERATED_KEYS)) {
                    int i = 1;
                    ps.setInt(i++, letterId);
                    ps.setString(i++, woNumber);
                    ps.setDate(i++, Date.valueOf(date));
                    ps.setString(i++, vName);
                    ps.setString(i++, emptyToNull(vPhone));
                    ps.setString(i++, emptyToNull(vAddress));
                    ps.setString(i++, emptyToNull(vEmail));
                    ps.setString(i++, emptyToNull(vGstin));
                    ps.setBigDecimal(i++, subtotal);
                    ps.setBigDecimal(i++, gstTotal);
                    ps.setBigDecimal(i++, total);
                    ps.setBytes(i++, file);
                    ps.setString(i++, fileName);
                    ps.setString(i++, fileType);
                    if (file == null) ps.setNull(i++, java.sql.Types.INTEGER); else ps.setInt(i++, file.length);
                    ps.setString(i++, user);
                    ps.setString(i, user);
                    ps.executeUpdate();
                    try (ResultSet keys = ps.getGeneratedKeys()) { keys.next(); id = keys.getInt(1); }
                }
            } else {
                String sql = "UPDATE kss_csr_work_order SET letter_id=?, wo_number=?, wo_date=?, vendor_name=?, vendor_phone=?, "
                           + "vendor_address=?, vendor_email=?, vendor_gstin=?, subtotal=?, gst_total=?, total_amount=?, updated_by=?"
                           + (file != null ? ", attachment=?, attachment_name=?, attachment_type=?, attachment_size=?" : "")
                           + " WHERE id=?";
                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    int i = 1;
                    ps.setInt(i++, letterId);
                    ps.setString(i++, woNumber);
                    ps.setDate(i++, Date.valueOf(date));
                    ps.setString(i++, vName);
                    ps.setString(i++, emptyToNull(vPhone));
                    ps.setString(i++, emptyToNull(vAddress));
                    ps.setString(i++, emptyToNull(vEmail));
                    ps.setString(i++, emptyToNull(vGstin));
                    ps.setBigDecimal(i++, subtotal);
                    ps.setBigDecimal(i++, gstTotal);
                    ps.setBigDecimal(i++, total);
                    ps.setString(i++, user);
                    if (file != null) {
                        ps.setBytes(i++, file);
                        ps.setString(i++, fileName);
                        ps.setString(i++, fileType);
                        ps.setInt(i++, file.length);
                    }
                    ps.setInt(i, id);
                    if (ps.executeUpdate() == 0) {
                        con.rollback();
                        sendJson(response, 404, fail("Work order not found. Please reload the page."));
                        return;
                    }
                }
                try (PreparedStatement ps = con.prepareStatement("DELETE FROM kss_csr_work_order_item WHERE work_order_id = ?")) {
                    ps.setInt(1, id);
                    ps.executeUpdate();
                }
            }
            try (PreparedStatement ps = con.prepareStatement(
                    "INSERT INTO kss_csr_work_order_item (work_order_id, line_no, particulars, price, gst_percent, gst_amount, amount) "
                  + "VALUES (?,?,?,?,?,?,?)")) {
                for (int k = 0; k < texts.size(); k++) {
                    BigDecimal[] n = nums.get(k);
                    ps.setInt(1, id);
                    ps.setInt(2, k + 1);
                    ps.setString(3, texts.get(k));
                    ps.setBigDecimal(4, n[0]);
                    ps.setBigDecimal(5, n[1]);
                    ps.setBigDecimal(6, n[2]);
                    ps.setBigDecimal(7, n[3]);
                    ps.addBatch();
                }
                ps.executeBatch();
            }
            con.commit();
        } catch (SQLIntegrityConstraintViolationException dup) {
            con.rollback();
            sendJson(response, 409, fail("WO Number \"" + woNumber + "\" already exists."));
            return;
        } catch (Exception e) {
            con.rollback();
            throw e;
        } finally {
            con.setAutoCommit(true);
        }

        JsonObject json = new JsonObject();
        json.addProperty("ok", true);
        json.addProperty("id", id);
        json.addProperty("isNew", isNew);
        json.addProperty("message", (isNew ? "Work order created: " : "Work order updated: ") + woNumber
                + " (Rs " + total.toPlainString() + ")");
        sendJson(response, 200, json);
    }

    private void delete(HttpServletRequest request, HttpServletResponse response, Connection con) throws Exception {
        String idParam = trim(request.getParameter("id"));
        if (!idParam.matches("\\d+")) { sendJson(response, 400, fail("Invalid work order.")); return; }
        int id = Integer.parseInt(idParam);
        String number = null;
        try (PreparedStatement ps = con.prepareStatement("SELECT wo_number FROM kss_csr_work_order WHERE id = ?")) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) { if (rs.next()) number = rs.getString(1); }
        }
        if (number == null) { sendJson(response, 404, fail("Work order not found. Please reload the page.")); return; }
        int invCount = 0;
        try (PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM kss_csr_invoice WHERE work_order_id = ?")) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) { if (rs.next()) invCount = rs.getInt(1); }
        }
        if (invCount > 0) {
            sendJson(response, 409, fail("Cannot delete " + number + ": it has " + invCount + " invoice"
                    + (invCount == 1 ? "" : "s") + ". Delete the invoices first."));
            return;
        }
        int advCount = 0;
        try (PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM kss_csr_vendor_advance WHERE work_order_id = ?")) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) { if (rs.next()) advCount = rs.getInt(1); }
        }
        if (advCount > 0) {
            sendJson(response, 409, fail("Cannot delete " + number + ": " + advCount + " advance payment"
                    + (advCount == 1 ? " is" : "s are") + " recorded against it. Delete the advances first."));
            return;
        }
        try (PreparedStatement ps = con.prepareStatement("DELETE FROM kss_csr_work_order WHERE id = ?")) {
            ps.setInt(1, id);
            ps.executeUpdate();   // items are removed by ON DELETE CASCADE
        }
        JsonObject json = new JsonObject();
        json.addProperty("ok", true);
        json.addProperty("id", id);
        json.addProperty("message", "Work order deleted: " + number);
        sendJson(response, 200, json);
    }

    // ================================================================== helpers
    /** Approval letters with committed (sum of work orders) and balance. */
    static List<Map<String, String>> loadLetters(Connection con) throws Exception {
        List<Map<String, String>> letters = new ArrayList<>();
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT l.id, l.letter_number, l.letter_name, l.activity_kind, l.place, l.amount, "
              + "COALESCE(SUM(w.total_amount), 0) AS committed, COUNT(w.id) AS wo_count "
              + "FROM kss_csr_approval_letter l LEFT JOIN kss_csr_work_order w ON w.letter_id = l.id "
              + "GROUP BY l.id, l.letter_number, l.letter_name, l.activity_kind, l.place, l.amount ORDER BY l.id DESC");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, String> m = new LinkedHashMap<>();
                m.put("id", String.valueOf(rs.getInt("id")));
                m.put("letterNumber", rs.getString("letter_number"));
                m.put("letterName", rs.getString("letter_name"));
                m.put("activityKind", rs.getString("activity_kind"));
                m.put("place", rs.getString("place"));
                m.put("amount", money2(rs.getBigDecimal("amount")));
                m.put("committed", money2(rs.getBigDecimal("committed")));
                m.put("woCount", String.valueOf(rs.getInt("wo_count")));
                letters.add(m);
            }
        }
        return letters;
    }

    private static List<Map<String, String>> loadItems(Connection con, int woId) throws Exception {
        List<Map<String, String>> items = new ArrayList<>();
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT particulars, price, gst_percent, gst_amount, amount FROM kss_csr_work_order_item "
              + "WHERE work_order_id = ? ORDER BY line_no")) {
            ps.setInt(1, woId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, String> m = new LinkedHashMap<>();
                    m.put("particulars", rs.getString("particulars"));
                    m.put("price", money2(rs.getBigDecimal("price")));
                    m.put("gst", rs.getBigDecimal("gst_percent").stripTrailingZeros().toPlainString());
                    m.put("gstAmount", money2(rs.getBigDecimal("gst_amount")));
                    m.put("amount", money2(rs.getBigDecimal("amount")));
                    items.add(m);
                }
            }
        }
        return items;
    }

    private static Map<String, String> woMap(ResultSet rs) throws Exception {
        Map<String, String> r = new LinkedHashMap<>();
        r.put("id", String.valueOf(rs.getInt("id")));
        r.put("letterId", String.valueOf(rs.getInt("letter_id")));
        r.put("woNumber", rs.getString("wo_number"));
        r.put("woDate", rs.getString("wo_date_iso"));
        r.put("woDateTxt", rs.getString("wo_date_txt"));
        r.put("vendorName", rs.getString("vendor_name"));
        r.put("vendorPhone", rs.getString("vendor_phone"));
        r.put("vendorAddress", rs.getString("vendor_address"));
        r.put("vendorEmail", rs.getString("vendor_email"));
        r.put("vendorGstin", rs.getString("vendor_gstin"));
        r.put("subtotal", money2(rs.getBigDecimal("subtotal")));
        r.put("gstTotal", money2(rs.getBigDecimal("gst_total")));
        r.put("total", money2(rs.getBigDecimal("total_amount")));
        r.put("attachmentName", rs.getString("attachment_name"));
        r.put("attachmentType", rs.getString("attachment_type"));
        r.put("attachmentSize", rs.getString("attachment_size"));
        r.put("createdBy", rs.getString("created_by"));
        r.put("createdAt", rs.getString("created_txt"));
        r.put("letterNumber", rs.getString("letter_number"));
        r.put("letterName", rs.getString("letter_name"));
        r.put("activityKind", rs.getString("activity_kind"));
        r.put("place", rs.getString("place"));
        r.put("letterAmount", money2(rs.getBigDecimal("letter_amount")));
        r.put("invoiced", money2(rs.getBigDecimal("invoiced")));
        r.put("invCount", String.valueOf(rs.getInt("inv_count")));
        return r;
    }

    /** Returns the MIME type for PDF / JPG / PNG, or null for anything else. */
    private static String detectType(byte[] d) {
        if (d.length > 4 && d[0] == '%' && d[1] == 'P' && d[2] == 'D' && d[3] == 'F') return "application/pdf";
        if (d.length > 3 && (d[0] & 0xFF) == 0xFF && (d[1] & 0xFF) == 0xD8 && (d[2] & 0xFF) == 0xFF) return "image/jpeg";
        if (d.length > 8 && (d[0] & 0xFF) == 0x89 && d[1] == 'P' && d[2] == 'N' && d[3] == 'G') return "image/png";
        return null;
    }

    private static String money2(BigDecimal v) {
        return v == null ? "0.00" : v.setScale(2, RoundingMode.HALF_UP).toPlainString();
    }

    private static byte[] readAll(InputStream in) throws IOException {
        try (InputStream is = in; ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            byte[] buf = new byte[8192];
            int n;
            while ((n = is.read(buf)) != -1) out.write(buf, 0, n);
            return out.toByteArray();
        }
    }

    private static String trim(String s) {
        return s == null ? "" : s.replace(NBSP, ' ').trim();
    }

    private static String emptyToNull(String s) {
        return s == null || s.isEmpty() ? null : s;
    }

    private static JsonObject fail(String message) {
        JsonObject json = new JsonObject();
        json.addProperty("ok", false);
        json.addProperty("message", message);
        return json;
    }

    private void sendJson(HttpServletResponse response, int status, JsonObject json) throws IOException {
        response.setStatus(status);
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write(json.toString());
    }
}
