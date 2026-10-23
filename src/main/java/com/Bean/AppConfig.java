package com.Bean;

import java.util.Arrays;
import java.util.Collections;
import java.util.List;

/**
 * Institutions served by this one application, all on the same MySQL server (one schema each).
 *
 *  KSS  Karnataka Seva Sangha  schema of the DBUtil URL (KSS)  scholarship + CSR
 *  SSS  SSS                    schema SSS_CSR                  CSR only
 *
 * Global users choose the institution after login and can switch from the header (session attribute "inst").
 * Other users always work in KSS (scholarship portal). ModuleFilter sets the institution of each request;
 * DBUtil.getConnection() then opens that institution's schema, so KSS and SSS data never mix.
 * To add an institution: one more line in ALL, and its schema with the CSR tables (NEW_INSTITUTION_CSR_database.sql).
 */
public final class AppConfig {

    private AppConfig() { }

    /** One institution. */
    public static final class Inst {
        public final String code, name, schema;   // schema null = the default schema of DBUtil (KSS)
        public final boolean csrOnly;
        Inst(String code, String name, String schema, boolean csrOnly) {
            this.code = code; this.name = name; this.schema = schema; this.csrOnly = csrOnly;
        }
    }

    public static final Inst KSS = new Inst("KSS", "Karnataka Seva Sangha", null, false);
    public static final Inst SSS = new Inst("SSS", "SSS", "SSS_CSR", true);
    public static final List<Inst> ALL = Collections.unmodifiableList(Arrays.asList(KSS, SSS));

    /** Session attribute that holds the chosen institution code. */
    public static final String SESSION_KEY = "inst";

    private static final ThreadLocal<Inst> CURRENT = new ThreadLocal<>();

    public static Inst byCode(String code) {
        if (code != null) for (Inst i : ALL) if (i.code.equalsIgnoreCase(code.trim())) return i;
        return null;
    }

    /** Called by ModuleFilter at the start / end of every request. */
    public static void setCurrent(Inst inst) { CURRENT.set(inst); }
    public static void clearCurrent() { CURRENT.remove(); }

    /** Institution of the current request (KSS when none is chosen). */
    public static Inst current() {
        Inst i = CURRENT.get();
        return i == null ? KSS : i;
    }

    public static String code()     { return current().code; }
    public static String name()     { return current().name; }
    public static String schema()   { return current().schema; }
    public static boolean csrOnly() { return current().csrOnly; }

    /** Institutions as plain text for the pages: { code, name, what it runs } (JSPs need no AppConfig types). */
    public static String[][] choices() {
        String[][] out = new String[ALL.size()][];
        for (int k = 0; k < ALL.size(); k++) {
            Inst i = ALL.get(k);
            out[k] = new String[] { i.code, i.name, i.csrOnly ? "CSR Amount Spending" : "Scholarship Portal and CSR Amount Spending" };
        }
        return out;
    }

    /** Second line under the name in the header. */
    public static String portalTitle() {
        return csrOnly() ? "CSR Amount Spending" : "Higher Education Scholarship Portal";
    }

    /** First page of the current institution. */
    public static String homePage() {
        return csrOnly() ? "CsrDashboardServlet" : "Dashboard.jsp";
    }
}
