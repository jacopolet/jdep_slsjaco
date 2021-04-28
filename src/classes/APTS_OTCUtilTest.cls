/*******************************************************************************************
Name            : APTS_OTCUtilTest 
Created By      : Monika Jayachamaraja
Created Date    : 12/06/2018
Description     : This test class is used for code cover for APTS_OTCUtil class
********************************************************************************************/
@isTest
public with sharing class APTS_OTCUtilTest {
@isTest
    public static void beforeUpdateTestMethod() {
    String ORDERLINEITEM = 'Apttus_Config2__OrderLineItem__c';
     String ORDER ='Apttus_Config2__Order__c';
    Apttus_Config2__OrderLineItem__c obj= new Apttus_Config2__OrderLineItem__c();
    APTS_OTCUtil.getsObjectAccess(ORDERLINEITEM);
    APTS_OTCUtil.describeFields(ORDERLINEITEM);
    APTS_OTCUtil.getRecordTypeDetails(ORDERLINEITEM);
    APTS_OTCUtil.getRecordTypeDetails(ORDER);
    APTS_OTCUtil.getPicklistValues(obj,'Apttus_Config2__BillingRule__c');
    APTS_OTCUtil.getRecordLevelAccess(null);
    }
}