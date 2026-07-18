package com.Bean;

import java.io.Serializable;

public class ScholarshipBean implements Serializable {

    private static final long serialVersionUID = 1L;

    private int id;
    private String orgName;
    private String empNo;
    private String empName;
    private String designation;

    private String childrenName;
    private String dob;
    private String gender;
    private String relationship;
    private String childOrder;

    private String spouseWorkingSMIORE;
    private String spouseWorkingGroupCompanies;

    private String collegeName;
    private String course;
    private String presentYear;

    private double previousAyPercentage;
    private double feeAmountCurrentAy;

    private String employeeNamePassbook;
    private String bankAccountNo;
    private String ifscCode;
    private String bankName;
    private String branchName;

    // Document properties updated to binary byte arrays
    private byte[] previousAyMarksCard;
    private byte[] kssApplication;
    private byte[] feeStructure;
    private byte[] feeReceipts;
    private byte[] parentAadharCopy;
    private byte[] studentAadharCopy;
    private byte[] bankPassbookFirstPage;

    public ScholarshipBean() {
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getOrgName() {
        return orgName;
    }

    public void setOrgName(String orgName) {
        this.orgName = orgName;
    }

    public String getEmpNo() {
        return empNo;
    }

    public void setEmpNo(String empNo) {
        this.empNo = empNo;
    }

    public String getEmpName() {
        return empName;
    }

    public void setEmpName(String empName) {
        this.empName = empName;
    }

    public String getDesignation() {
        return designation;
    }

    public void setDesignation(String designation) {
        this.designation = designation;
    }

    public String getChildrenName() {
        return childrenName;
    }

    public void setChildrenName(String childrenName) {
        this.childrenName = childrenName;
    }

    public String getDob() {
        return dob;
    }

    public void setDob(String dob) {
        this.dob = dob;
    }

    public String getGender() {
        return gender;
    }

    public void setGender(String gender) {
        this.gender = gender;
    }

    public String getRelationship() {
        return relationship;
    }

    public void setRelationship(String relationship) {
        this.relationship = relationship;
    }

    public String getChildOrder() {
        return childOrder;
    }

    public void setChildOrder(String childOrder) {
        this.childOrder = childOrder;
    }

    public String getSpouseWorkingSMIORE() {
        return spouseWorkingSMIORE;
    }

    public void setSpouseWorkingSMIORE(String spouseWorkingSMIORE) {
        this.spouseWorkingSMIORE = spouseWorkingSMIORE;
    }

    public String getSpouseWorkingGroupCompanies() {
        return spouseWorkingGroupCompanies;
    }

    public void setSpouseWorkingGroupCompanies(String spouseWorkingGroupCompanies) {
        this.spouseWorkingGroupCompanies = spouseWorkingGroupCompanies;
    }

    public String getCollegeName() {
        return collegeName;
    }

    public void setCollegeName(String collegeName) {
        this.collegeName = collegeName;
    }

    public String getCourse() {
        return course;
    }

    public void setCourse(String course) {
        this.course = course;
    }

    public String getPresentYear() {
        return presentYear;
    }

    public void setPresentYear(String presentYear) {
        this.presentYear = presentYear;
    }

    public double getPreviousAyPercentage() {
        return previousAyPercentage;
    }

    public void setPreviousAyPercentage(double previousAyPercentage) {
        this.previousAyPercentage = previousAyPercentage;
    }

    public double getFeeAmountCurrentAy() {
        return feeAmountCurrentAy;
    }

    public void setFeeAmountCurrentAy(double feeAmountCurrentAy) {
        this.feeAmountCurrentAy = feeAmountCurrentAy;
    }

    public String getEmployeeNamePassbook() {
        return employeeNamePassbook;
    }

    public void setEmployeeNamePassbook(String employeeNamePassbook) {
        this.employeeNamePassbook = employeeNamePassbook;
    }

    public String getBankAccountNo() {
        return bankAccountNo;
    }

    public void setBankAccountNo(String bankAccountNo) {
        this.bankAccountNo = bankAccountNo;
    }

    public String getIfscCode() {
        return ifscCode;
    }

    public void setIfscCode(String ifscCode) {
        this.ifscCode = ifscCode;
    }

    public String getBankName() {
        return bankName;
    }

    public void setBankName(String bankName) {
        this.bankName = bankName;
    }

    public String getBranchName() {
        return branchName;
    }

    public void setBranchName(String branchName) {
        this.branchName = branchName;
    }

    // Getters and Setters modified for byte[]
    public byte[] getPreviousAyMarksCard() {
        return previousAyMarksCard;
    }

    public void setPreviousAyMarksCard(byte[] previousAyMarksCard) {
        this.previousAyMarksCard = previousAyMarksCard;
    }

    public byte[] getKssApplication() {
        return kssApplication;
    }

    public void setKssApplication(byte[] kssApplication) {
        this.kssApplication = kssApplication;
    }

    public byte[] getFeeStructure() {
        return feeStructure;
    }

    public void setFeeStructure(byte[] feeStructure) {
        this.feeStructure = feeStructure;
    }

    public byte[] getFeeReceipts() {
        return feeReceipts;
    }

    public void setFeeReceipts(byte[] feeReceipts) {
        this.feeReceipts = feeReceipts;
    }

    public byte[] getParentAadharCopy() {
        return parentAadharCopy;
    }

    public void setParentAadharCopy(byte[] parentAadharCopy) {
        this.parentAadharCopy = parentAadharCopy;
    }

    public byte[] getStudentAadharCopy() {
        return studentAadharCopy;
    }

    public void setStudentAadharCopy(byte[] studentAadharCopy) {
        this.studentAadharCopy = studentAadharCopy;
    }

    public byte[] getBankPassbookFirstPage() {
        return bankPassbookFirstPage;
    }

    public void setBankPassbookFirstPage(byte[] bankPassbookFirstPage) {
        this.bankPassbookFirstPage = bankPassbookFirstPage;
    }
}