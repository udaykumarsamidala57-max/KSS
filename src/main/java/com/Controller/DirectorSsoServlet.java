package com.Controller;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.MessageDigest;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.HexFormat;
import java.util.Iterator;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.logging.Logger;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.Bean.AppConfig;
import com.Bean.DBUtil;

/**
 * POST /sso/director - one-click sign-in from the Director Portal (secret SSO, no password typed again).
 *
 * The Director Portal renders an auto-submitting HTML form (POST, so the token never appears in a URL,
 * browser history, proxy log or Referer) with the fields:
 *     user   username in KSS users (must be a Global user)
 *     inst   institution code: KSS or SSS
 *     to     page to open after sign-in, relative, e.g. CsrDashboardServlet (optional; empty = home page)
 *     ts     Unix time in seconds when the token was made
 *     nonce  32 random hex characters, new for every token
 *     sig    HMAC-SHA256 (hex) with the key DIRECTOR_HIGHEDU_SSO_SECRET (environment variable or -D, 64 hex chars) of
 *            "DIRECTOR>HIGHEDU-SSO\n" + ts + "\n" + nonce + "\n" + user + "\n" + inst + "\n" + to
 *
 * Rules: signature checked in constant time; token valid for 60 s; each nonce works once (replay blocked);
 * user must exist and be Global in KSS users (password never read); "to" must be a page of this application.
 * Success creates a new session (new session id) exactly like LoginServlet does for a Global user, plus
 * session attribute "loginVia" = "DIRECTOR_SSO". Every success and failure is written to the server log.
 * Failures show one generic message, so the reason is never revealed to the browser.
 *
 * Note: used nonces are kept in memory, which is correct for the single Tomcat instance on Railway.
 * If the application is ever run on more than one instance, move the nonce store to a shared table.
 */
@WebServlet("/sso/director")
public class DirectorSsoServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private static final Logger LOG = Logger.getLogger(DirectorSsoServlet.class.getName());

    static final String AUDIENCE = "DIRECTOR>HIGHEDU-SSO";
    static final String SECRET_NAME = "DIRECTOR_HIGHEDU_SSO_SECRET";
    static final long MAX_AGE_SECONDS = 60;

    /** nonce -> expiry (Unix seconds). */
    private static final Map<String, Long> USED_NONCES = new ConcurrentHashMap<>();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.sendRedirect(req.getContextPath() + "/login.jsp");     // tokens are accepted by POST only
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String secret = setting(SECRET_NAME);
        if (secret == null || !secret.matches("[0-9a-fA-F]{64}")) {
            LOG.severe("[director-sso] " + SECRET_NAME + " is not set (64 hex characters); sign-in refused");
            fail(resp, HttpServletResponse.SC_SERVICE_UNAVAILABLE);
            return;
        }
        req.setCharacterEncoding("UTF-8");
        String user  = req.getParameter("user");
        String inst  = req.getParameter("inst");
        String to    = req.getParameter("to") == null ? "" : req.getParameter("to");
        String ts    = req.getParameter("ts");
        String nonce = req.getParameter("nonce");
        String sig   = req.getParameter("sig");
        long now = System.currentTimeMillis() / 1000L;
        String ip = req.getRemoteAddr();

        if (user == null || user.isBlank() || user.length() > 50 || inst == null || AppConfig.byCode(inst) == null
                || nonce == null || !nonce.matches("[0-9a-fA-F]{32}") || !safeTarget(to)) {
            LOG.warning("[director-sso] rejected: bad fields from " + ip);
            fail(resp, HttpServletResponse.SC_BAD_REQUEST);
            return;
        }
        if (!verify(secret, ts, nonce, user, inst, to, sig, now)) {
            LOG.warning("[director-sso] rejected: bad or expired signature for user '" + user + "' from " + ip);
            fail(resp, HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }
        if (!useNonce(nonce.toLowerCase(Locale.ROOT), now)) {
            LOG.warning("[director-sso] rejected: token already used, user '" + user + "' from " + ip);
            fail(resp, HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }

        String[] account;
        AppConfig.Inst before = AppConfig.current();
        AppConfig.setCurrent(AppConfig.KSS);                      // logins live in KSS users
        try {
            account = globalAccount(user.trim());
        } catch (Exception e) {
            e.printStackTrace();
            fail(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            return;
        } finally {
            AppConfig.setCurrent(before);
        }
        if (account == null) {
            LOG.warning("[director-sso] rejected: '" + user + "' is not a Global user, from " + ip);
            fail(resp, HttpServletResponse.SC_FORBIDDEN);
            return;
        }

        HttpSession old = req.getSession(false);
        if (old != null) old.invalidate();                        // new session id, as in LoginServlet
        HttpSession session = req.getSession(true);
        session.setAttribute("username", user.trim());
        session.setAttribute("role", account[0]);
        session.setAttribute("department", account[1]);
        session.setAttribute("branch", account[2]);
        AppConfig.Inst chosen = AppConfig.byCode(inst);
        session.setAttribute(AppConfig.SESSION_KEY, chosen.code);
        session.setAttribute("loginVia", "DIRECTOR_SSO");
        LOG.info("[director-sso] signed in '" + user.trim() + "' to " + chosen.code + " from " + ip);

        String target = to.isEmpty() ? (chosen.csrOnly ? "CsrDashboardServlet" : "Dashboard.jsp") : to;
        resp.sendRedirect(req.getContextPath() + "/" + target);
    }

    /** { role, department, branch } of a Global user in KSS users, or null. Same cleaning as LoginServlet. */
    private static String[] globalAccount(String username) throws Exception {
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement("SELECT role, department, branch FROM users WHERE username = ?")) {
            ps.setString(1, username);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return null;
                String role = clean(rs.getString("role"));
                if (role == null || !"Global".equalsIgnoreCase(role)) return null;
                return new String[] { role, clean(rs.getString("department")), clean(rs.getString("branch")) };
            }
        }
    }

    static boolean verify(String secret, String ts, String nonce, String user, String inst, String to, String sig, long now) {
        if (ts == null || sig == null || !sig.matches("[0-9a-fA-F]{64}") || !ts.matches("\\d{1,12}")) return false;
        try {
            long issuedAt = Long.parseLong(ts);
            if (Math.abs(now - issuedAt) > MAX_AGE_SECONDS) return false;
            String canonical = AUDIENCE + "\n" + ts + "\n" + nonce + "\n" + user + "\n" + inst + "\n" + to;
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(HexFormat.of().parseHex(secret), "HmacSHA256"));
            byte[] expected = HexFormat.of().formatHex(mac.doFinal(canonical.getBytes(StandardCharsets.UTF_8)))
                    .getBytes(StandardCharsets.US_ASCII);
            return MessageDigest.isEqual(expected, sig.toLowerCase(Locale.ROOT).getBytes(StandardCharsets.US_ASCII));
        } catch (RuntimeException | GeneralSecurityException e) {
            return false;
        }
    }

    /** True the first time a nonce is seen within its lifetime; old entries are removed as we go. */
    static boolean useNonce(String nonce, long now) {
        for (Iterator<Map.Entry<String, Long>> it = USED_NONCES.entrySet().iterator(); it.hasNext();) {
            if (it.next().getValue() < now) it.remove();
        }
        return USED_NONCES.putIfAbsent(nonce, now + 2 * MAX_AGE_SECONDS + 5) == null;
    }

    /** Only a page of this application: letters, digits, _ and optional .jsp, then an optional simple query. */
    static boolean safeTarget(String to) {
        if (to == null || to.isEmpty()) return true;
        return to.length() <= 200 && to.matches("[A-Za-z][A-Za-z0-9_]*(\\.jsp)?(\\?[A-Za-z0-9_=&%.\\-]*)?")
                && !to.equalsIgnoreCase("Logout.jsp") && !to.startsWith("sso");
    }

    private static String clean(String value) {
        return value == null ? null : value.replace(' ', ' ').strip();
    }

    private static String setting(String name) {
        String v = System.getenv(name);
        if (v == null || v.isBlank()) v = System.getProperty(name);
        return v == null || v.isBlank() ? null : v.trim();
    }

    private static void fail(HttpServletResponse resp, int status) throws IOException {
        resp.setStatus(status);
        resp.setHeader("Cache-Control", "no-store");
        resp.setContentType("text/html");
        resp.setCharacterEncoding("UTF-8");
        resp.getWriter().write("<!DOCTYPE html><html><head><meta charset='UTF-8'><title>Sign-in failed</title></head>"
                + "<body style='font-family:IBM Plex Sans,Arial,sans-serif;padding:40px;color:#1e293b'>"
                + "<h3>Single sign-on from the Director Portal did not succeed.</h3>"
                + "<p>The link may have expired or already been used. Open it again from the Director Portal, or "
                + "<a href='../login.jsp'>sign in with your username and password</a>.</p></body></html>");
    }
}
