package com.Bean;

import java.util.ArrayList;
import java.util.List;

public class AuditUtil {

    public static String getDetailedChanges(ScholarshipBean oldB, ScholarshipBean newB) {
        if (oldB == null) return "Updated record via Servlet";

        List<String> changes = new ArrayList<>();

        // Company & Employee Info
        checkAndAdd(changes, "Org Name", oldB.getOrgName(), newB.getOrgName());
        checkAndAdd(changes, "Emp No", oldB.getEmpNo(), newB.getEmpNo());
        checkAndAdd(changes, "Emp Name", oldB.getEmpName(), newB.getEmpName());
        checkAndAdd(changes, "Designation", oldB.getDesignation(), newB.getDesignation());
        checkAndAdd(changes, "Emp Contact", oldB.getEmpContact(), newB.getEmpContact());

        // Child Info
        checkAndAdd(changes, "Child Name", oldB.getChildrenName(), newB.getChildrenName());
        checkAndAdd(changes, "DOB", oldB.getDob(), newB.getDob());
        checkAndAdd(changes, "Gender", oldB.getGender(), newB.getGender());
        checkAndAdd(changes, "Relationship", oldB.getRelationship(), newB.getRelationship());
        checkAndAdd(changes, "Child Order", oldB.getChildOrder(), newB.getChildOrder());

        // Spouse Info
        checkAndAdd(changes, "Spouse Working SMIORE", oldB.getSpouseWorkingSMIORE(), newB.getSpouseWorkingSMIORE());
        checkAndAdd(changes, "Spouse Working Group", oldB.getSpouseWorkingGroupCompanies(), newB.getSpouseWorkingGroupCompanies());

        // Education Info
        checkAndAdd(changes, "College", oldB.getCollegeName(), newB.getCollegeName());
        checkAndAdd(changes, "Place College", oldB.getPlaceCollege(), newB.getPlaceCollege());
        checkAndAdd(changes, "Course", oldB.getCourse(), newB.getCourse());
        checkAndAdd(changes, "Present Year", oldB.getPresentYear(), newB.getPresentYear());

        // Financial & Academic Percentages
        if (Double.compare(oldB.getPreviousAyPercentage(), newB.getPreviousAyPercentage()) != 0) {
            changes.add("Prev AY % (" + oldB.getPreviousAyPercentage() + " -> " + newB.getPreviousAyPercentage() + ")");
        }
        if (Double.compare(oldB.getFeeAmountCurrentAy(), newB.getFeeAmountCurrentAy()) != 0) {
            changes.add("Fee Amt (" + oldB.getFeeAmountCurrentAy() + " -> " + newB.getFeeAmountCurrentAy() + ")");
        }
        if (Double.compare(oldB.getActualFeePaid(), newB.getActualFeePaid()) != 0) {
            changes.add("Actual Fee Paid (" + oldB.getActualFeePaid() + " -> " + newB.getActualFeePaid() + ")");
        }

        // Bank Details
        checkAndAdd(changes, "Passbook Name", oldB.getEmployeeNamePassbook(), newB.getEmployeeNamePassbook());
        checkAndAdd(changes, "Bank Acc No", oldB.getBankAccountNo(), newB.getBankAccountNo());
        checkAndAdd(changes, "IFSC", oldB.getIfscCode(), newB.getIfscCode());
        checkAndAdd(changes, "Bank Name", oldB.getBankName(), newB.getBankName());
        checkAndAdd(changes, "Branch Name", oldB.getBranchName(), newB.getBranchName());

        if (changes.isEmpty()) {
            return "Updated record (No field values changed)";
        }

        return "Updated: " + String.join(", ", changes);
    }

    private static void checkAndAdd(List<String> changes, String fieldName, String oldVal, String newVal) {
        String v1 = oldVal == null ? "" : oldVal.trim();
        String v2 = newVal == null ? "" : newVal.trim();
        if (!v1.equals(v2)) {
            changes.add(fieldName + " ('" + v1 + "' -> '" + v2 + "')");
        }
    }
}