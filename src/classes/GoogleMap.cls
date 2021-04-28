/*
Aditya--Renamed the field from Actual Revenue (last 12 months)(Account_Annual_Value__c) to Estimated Revenue Agreement Based
*/

/*
Johan de Wild
Edit Date: 2018-11-28
Changed (BillingLongitude > 0) and (BillingLatitude > 0) to != 0 instead of > 0 in getProspectAccounts() and getCustomerAccounts() because it can also be a negative number. 0 is for addresses which are not yet validated.
*/

public with sharing class GoogleMap {
    //https://releasenotes.docs.salesforce.com/en-us/summer16/release-notes/rn_general_geocodes_aloha.htm
    //https://releasenotes.docs.salesforce.com/en-us/summer16/release-notes/data_dot_com_clean_add_geocode_information_to_all_records.htm
    //https://help.salesforce.com/articleView?id=data_dot_com_clean_admin_clean_rules.htm&type=0&language=en_US
    
    //Get Prospect Accounts ~~ Account RecordType = Prospect
    @AuraEnabled
    public static List<Account> getProspectAccounts(){     
        CustomLogging.push('getProspectAccounts', 'GoogleMap');
        try {
            //return [select Id, Name, BillingLatitude, BillingLongitude, Billing_Latitude__c, Billing_Longitude__c, Account_Status__c, Key_Account__c, Account_Annual_Value__c, Account_Lifecycle__c from Account where (Billing_Latitude__c != null and Billing_Latitude__c > 0) and (Billing_Longitude__c != null and Billing_Longitude__c > 0) AND OwnerId =: UserInfo.getUserId() AND RecordTypeId =: Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.Prospect).getRecordTypeId() AND (Account_Lifecycle__c != 'Inactive Customer' AND Account_Lifecycle__c != 'Archived')];
            return [select Id,  Name, BillingLatitude, BillingLongitude, Billing_Latitude__c, Billing_Longitude__c , Account_Status__c, Key_Account__c, Account_Annual_Value__c, Account_Lifecycle__c from Account where (BillingLatitude != null and BillingLatitude != 0) and (BillingLongitude != null and BillingLongitude != 0) AND OwnerId =: UserInfo.getUserId()  AND (RecordTypeId =: Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.Prospect).getRecordTypeId() OR RecordTypeId =: Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.ProspectValid).getRecordTypeId()) AND (Account_Lifecycle__c != 'Inactive Customer' AND Account_Lifecycle__c != 'Archived')];
        } catch (Exception e) {CustomLogging.debugException(e);CustomLogging.pop(); System.debug(e.getMessage() + '\n' + e.getStackTraceString()); return null;}
    }
    
    //Get Customer Accounts ~~ Account RecordType = Customer
    @AuraEnabled
    public static List<Account> getCustomerAccounts(){
        CustomLogging.push('getCustomerAccounts', 'GoogleMap');
        try {
            //return [select Id, Name, BillingLatitude, BillingLongitude, Billing_Latitude__c, Billing_Longitude__c, Account_Status__c, Key_Account__c, Account_Annual_Value__c, Account_Lifecycle__c from Account where (Billing_Latitude__c != null and Billing_Latitude__c > 0) and (Billing_Longitude__c != null and Billing_Longitude__c > 0) AND OwnerId =: UserInfo.getUserId() AND RecordTypeId =: Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.Customer).getRecordTypeId() AND (Account_Lifecycle__c != 'Inactive Customer' AND Account_Lifecycle__c != 'Archived')];
            return [select Id,  Name, BillingLatitude, BillingLongitude, Billing_Latitude__c, Billing_Longitude__c , Account_Status__c, Key_Account__c, Account_Annual_Value__c, Account_Lifecycle__c from Account where (BillingLatitude != null and BillingLatitude != 0) and (BillingLongitude != null and BillingLongitude != 0) AND OwnerId =: UserInfo.getUserId() AND RecordTypeId =: Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.Customer).getRecordTypeId() AND (Account_Lifecycle__c != 'Inactive Customer' AND Account_Lifecycle__c != 'Archived')];
        } catch (Exception e) {CustomLogging.debugException(e); CustomLogging.pop(); System.debug(e.getMessage() + '\n' + e.getStackTraceString()); return null;}
    }
    
    //Get Opportunities only Stage != Closed Lost
    @AuraEnabled
    public static List<Opportunity> getOpportunities(){
        CustomLogging.push('getOpportunities', 'GoogleMap');
        try {
            //return [select Id, Name, Account.Billing_Latitude__c, Account.Billing_Longitude__c, StageName, Amount, CloseDate from Opportunity where (Account.Billing_Latitude__c != null and Account.Billing_Latitude__c > 0) and (Account.Billing_Longitude__c != null and Account.Billing_Longitude__c > 0) AND OwnerId =: UserInfo.getUserId() AND StageName != 'Closed Lost' AND StageName != 'No Bid'];
            return [select Id, Name, Account.BillingLatitude, Account.BillingLongitude, Account.Billing_Latitude__c, Account.Billing_Longitude__c, StageName, Amount, CloseDate from Opportunity where (Account.BillingLatitude != null and Account.BillingLatitude != 0) and (Account.BillingLongitude != null and Account.BillingLongitude != 0) AND OwnerId =: UserInfo.getUserId() AND StageName != 'Closed Lost' AND StageName != 'Closed Won' AND StageName != 'No Bid'];
        } catch (Exception e) {CustomLogging.debugException(e); CustomLogging.pop(); System.debug(e.getMessage() + '\n' + e.getStackTraceString()); return null;}
    }
    
    //Get Leads
    @AuraEnabled
    public static List<Lead> getLeads(){
        CustomLogging.push('getLeads', 'GoogleMap');
        try {
            //return [select id, name, Latitude, Longitude, Latitude__c, Longitude__c from Lead where (Latitude__c != null and Latitude__c > 0) and (Longitude__c != null and Longitude__c > 0) AND OwnerId =: UserInfo.getUserId()];
            return [select id, name, Latitude, Longitude, Latitude__c, Longitude__c, Phone, Company, Email from Lead where (Latitude != null and Latitude > 0) and (Longitude != null and Longitude > 0) AND OwnerId =: UserInfo.getUserId()];
        } catch (Exception e) { CustomLogging.debugException(e); CustomLogging.pop(); System.debug(e.getMessage() + '\n' + e.getStackTraceString()); return null;}
    }

    //Get Host URL
    @AuraEnabled
    public static String getHostURL(){
        CustomLogging.push('getHostURL', 'GoogleMap');
        try {
            String baseURL = URL.getSalesforceBaseUrl().toExternalForm();
            return baseURL;
        } catch (Exception e) { CustomLogging.debugException(e); CustomLogging.pop(); System.debug(e.getMessage() + '\n' + e.getStackTraceString()); return null;}
    }
}