//-------------------------------------------------------------------------------------------//
// Author       :   Catherine Aragon - Accenture
// Created Date :   August 02 2019
// Usage        :   
//
//-------------------------------------------------------------------------------------------//
public without sharing class UserDAO {
	//Retrive User information
	public static User userInformation() {
		User u = [Select Id, Name, Country, Profile.Name, Sales_Organization__c, UserRole.DeveloperName FROM User where ID = :UserInfo.getUserId()];
		return u;
	}
    
    //GET ALL FIELDS FROM DEFINED SOBJECT - PARAMETER
    public static Map<String, Schema.SObjectField> sOjectFields(String sObjectString) {
        Map<String, Schema.SObjectField> fields_map = new Map<String, Schema.SObjectField>();
        Map<String, Schema.SObjectType> m = Schema.getGlobalDescribe();
        Schema.SObjectType s = m.get(sObjectString);
        Schema.DescribeSObjectResult r = s.getDescribe();
        fields_map = r.fields.getMap();
        
        return fields_map;
    }
    
    //Get Bank Detail Finance Controller
    public static Map<Id, User> bankDetailFinanceController(List<Bank_Details__c> newBankDetailList) {
        Set<String> salesOrg = new Set<String>();
        Map<String, User> salesOrgUSer = new Map<String, User>();
        Map<Id, User> bankDetailUser = new Map<Id, User>();
        for (Bank_Details__c b : newBankDetailList) {
            salesOrg.add(b.Sales_Organization__c);
        }
        if (salesOrg.size() > 0) {
            List<User> uFinance = [Select Id, ManagerId, Name, Sales_Organization__c FROM User WHERE Finance_Controller_Approver__c = true AND Sales_Organization__c IN :salesOrg];
            for (User u : uFinance) {
                salesOrgUSer.put(u.Sales_Organization__c, u);
            }
            if (salesOrgUSer.size() > 0) {
                for (Bank_Details__c b: newBankDetailList) {
                    bankDetailUser.put(b.Id, salesOrgUSer.get(b.Sales_Organization__c));
                }
            }
        }
        return bankDetailUser;
    }
    
    //Get Bank Detail Finance Controller
    public static Map<Id, User> accountTaxFinanceController(List<Account_Tax__c> newAccountTaxList) {
        Set<String> salesOrg = new Set<String>();
        Map<String, User> salesOrgUSer = new Map<String, User>();
        Map<Id, User> bankDetailUser = new Map<Id, User>();
        for (Account_Tax__c at : newAccountTaxList) {
            salesOrg.add(at.Sales_Organization__c);
        }
        if (salesOrg.size() > 0) {
            List<User> uFinance = [Select Id, ManagerId, Name, Sales_Organization__c FROM User WHERE Finance_Controller_Approver__c = true AND Sales_Organization__c IN :salesOrg];
            for (User u : uFinance) {
                salesOrgUSer.put(u.Sales_Organization__c, u);
            }
            if (salesOrgUSer.size() > 0) {
                for (Account_Tax__c at: newAccountTaxList) {
                    bankDetailUser.put(at.Id, salesOrgUSer.get(at.Sales_Organization__c));
                }
            }
        }
        return bankDetailUser;
    }
    
    public static Map<String, Boolean> digitalIntegrationInformation(String obj) {
        Map<String, Boolean> digitalInteg = new Map<String, Boolean>();
    	List <DevOps_Sales_Digital_Ilog__mdt> digitalIlog = [Select MasterLabel, Sales_Organization__c, Send_Digital_ilogs_to_EPI__c FROM DevOps_Sales_Digital_Ilog__mdt WHERE MasterLabel = :obj];
        if (!digitalIlog.isEmpty()) {
           for (DevOps_Sales_Digital_Ilog__mdt dilog : digitalIlog) {
               digitalInteg.put(dilog.Sales_Organization__c, dilog.Send_Digital_ilogs_to_EPI__c);
           }
        }
        
        return digitalInteg;
    }

    public static Map<String, String> logisticPartnerInformation() {
    	Map<String, String> logisticPartnerMap = new Map<String, String>();
     	List <Logistic_Partner__mdt> logisticPartnerList = [Select MasterLabel, Sales_Organization__c, Vendor_Code__c FROM Logistic_Partner__mdt];
        if (!logisticPartnerList.isEmpty()) {
            for (Logistic_Partner__mdt lsp : logisticPartnerList) {
                logisticPartnerMap.put(lsp.MasterLabel, lsp.Vendor_Code__c);
            }
        }
        
        return logisticPartnerMap;
    }
}