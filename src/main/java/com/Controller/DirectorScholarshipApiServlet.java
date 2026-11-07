package com.Controller;

import java.io.IOException;
import java.io.InputStream;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.MessageDigest;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;
import java.util.logging.Logger;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.Bean.AppConfig;
import com.Bean.DBUtil;
import com.google.gson.JsonObject;

/**
 * POST /api/director/scholarship-decision - Step 3 decision sent by the Director Portal (server to server).
 * Signed with HMAC-SHA256 using the key DIRECTOR_HIGHEDU_API_SECRET (environment variable or -D), canonical text
 *     "DIRECTOR>HIGHEDU\n" + timestamp + "\n" + METHOD + "\n" + request URI (+ "?" + query) + "\n" + body
 * Timestamp within ±60 s. Body: user, id, decision (Approved / Rejected), amount, remarks (URL-encoded).
 * Same rules as the Approve Scholarship page: the user must be a Global user in KSS users, and
 * ApproveScholarshipServlet.decide() does the checks, the update and the audit entry. KSS only (scholarship institution).
 */
@WebServlet("/api/director/scholarship-decision")
public class DirectorScholarshipApiServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private static final Logger LOG = Logger.getLogger(DirectorScholarshipApiServlet.class.getName());
    static final String AUDIENCE = "DIRECTOR>HIGHEDU";
    private static final int MAX_BODY = 16 * 1024;

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String secret = setting("DIRECTOR_HIGHEDU_API_SECRET");
        if (secret == null || !secret.matches("[0-9a-fA-F]{64}")) {
            resp.sendError(HttpServletResponse.SC_SERVICE_UNAVAILABLE, "Director Portal connection is not configured.");
            return;
        }
        byte[] raw;
        try (InputStream in = req.getInputStream()) {
            raw = in.readNBytes(MAX_BODY + 1);
        }
        if (raw.length > MAX_BODY) {
            resp.sendError(HttpServletResponse.SC_REQUEST_ENTITY_TOO_LARGE);
            return;
        }
        String body = new String(raw, StandardCharsets.UTF_8);
        String path = req.getRequestURI() + (req.getQueryString() == null ? "" : "?" + req.getQueryString());
        if (!verify(secret, req.getMethod(), path, req.getHeader("X-Director-Timestamp"), req.getHeader("X-Director-Signature"),
                body, System.currentTimeMillis() / 1000L)) {
            LOG.warning("[director-api] rejected unsigned/invalid POST " + req.getRequestURI() + " from " + req.getRemoteAddr());
            resp.sendError(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }
        Map<String, String> f = form(body);
        String decision = f.get("decision");
        if (!"Approved".equals(decision) && !"Rejected".equals(decision)) {
            reply(resp, HttpServletResponse.SC_BAD_REQUEST, "Invalid decision.");
            return;
        }
        AppConfig.Inst before = AppConfig.current();
        AppConfig.setCurrent(AppConfig.KSS);                       // scholarships are KSS only
        try {
            String user = f.get("user");
            if (!isGlobalUser(user)) {
                reply(resp, HttpServletResponse.SC_FORBIDDEN, "Only Global users of the KSS portal can approve scholarships.");
                return;
            }
            ApproveScholarshipServlet.Decision d = ApproveScholarshipServlet.decide(user.trim(), f.get("id"), decision,
                    f.get("amount"), f.get("remarks"));
            resp.setStatus(d.status);
            resp.setContentType("application/json");
            resp.setCharacterEncoding("UTF-8");
            resp.getWriter().write(d.json.toString());
        } catch (Exception e) {
            e.printStackTrace();
            reply(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "The decision was not saved. Please try again.");
        } finally {
            AppConfig.setCurrent(before);
        }
    }

    /** Same Global check as the portal pages, against KSS users (password never read). */
    private static boolean isGlobalUser(String username) throws Exception {
        if (username == null || username.isBlank() || username.length() > 50) return false;
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement("SELECT role FROM users WHERE username = ?")) {
            ps.setString(1, username.trim());
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return false;
                String role = rs.getString(1);
                return role != null && "Global".equalsIgnoreCase(role.replace(' ', ' ').trim());
            }
        }
    }

    static boolean verify(String secret, String method, String path, String timestamp, String signature, String body, long now) {
        if (timestamp == null || signature == null || !signature.matches("[0-9a-fA-F]{64}")) return false;
        try {
            long issuedAt = Long.parseLong(timestamp);
            if (Math.abs(now - issuedAt) > 60) return false;
            String canonical = AUDIENCE + "\n" + timestamp + "\n" + method.toUpperCase(Locale.ROOT) + "\n" + path + "\n" + body;
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(HexFormat.of().parseHex(secret), "HmacSHA256"));
            byte[] expected = HexFormat.of().formatHex(mac.doFinal(canonical.getBytes(StandardCharsets.UTF_8)))
                    .getBytes(StandardCharsets.US_ASCII);
            return MessageDigest.isEqual(expected, signature.toLowerCase(Locale.ROOT).getBytes(StandardCharsets.US_ASCII));
        } catch (RuntimeException | GeneralSecurityException e) {
            return false;
        }
    }

    static Map<String, String> form(String body) {
        Map<String, String> out = new LinkedHashMap<>();
        if (body == null || body.isEmpty()) return out;
        for (String pair : body.split("&")) {
            int eq = pair.indexOf('=');
            String k = URLDecoder.decode(eq < 0 ? pair : pair.substring(0, eq), StandardCharsets.UTF_8);
            String v = eq < 0 ? "" : URLDecoder.decode(pair.substring(eq + 1), StandardCharsets.UTF_8);
            out.putIfAbsent(k, v);
        }
        return out;
    }

    private static String setting(String name) {
        String v = System.getenv(name);
        if (v == null || v.isBlank()) v = System.getProperty(name);
        return v == null || v.isBlank() ? null : v.trim();
    }

    private static void reply(HttpServletResponse resp, int status, String message) throws IOException {
        JsonObject json = new JsonObject();
        json.addProperty("ok", false);
        json.addProperty("message", message);
        resp.setStatus(status);
        resp.setContentType("application/json");
        resp.setCharacterEncoding("UTF-8");
        resp.getWriter().write(json.toString());
    }
}
