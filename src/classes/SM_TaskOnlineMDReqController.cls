public with sharing class SM_TaskOnlineMDReqController {

    @AuraEnabled(cacheable=true)
    public static Task getTaskRecord(Id taskId) {
        Task taskrec = [SELECT Id, RecordTypeId, Requested_Operation__c, Touchpoint_Type__c, Requested_Account_Name__c, Requested_Second_Name__c, Requested_Third_Name__c, Requested_Fourth_Name__c, Requested_Main_Street_Only__c,
                        Requested_Main_House_Number__c,	Requested_Main_House_Number_Supplement__c, Requested_Main_Postal_Code__c, Requested_Main_State__c, Requested_Main_City__c, Requested_Main_Country__c, 
                        Requested_Main_Country_ISO__c, Requested_Main_Postal_Box__c, Requested_Main_Postal_Box_City__c, Requested_Commercial_Register_Number__c, Requested_VAT_Number__c, Requested_AddressValidationTimestamp__c, 
                        Description, Requested_Account_Location_Name__c, Requested_Shipping_Street__c, Requested_Shipping_House_number__c, Requested_Shipping_House_No_Supplement__c, Requested_Shipping_Postal_Code__c, 
                        Requested_Shipping_City__c, Requested_State__c, Requested_Shipping_Country__c, Requested_CountryISO__c
                        FROM Task WHERE Id  = : taskId LIMIT 1];
        system.debug(taskrec);
        return taskrec;
    }
    
    @AuraEnabled(cacheable=true)
    public static Id getRelatedWhatId(Id taskId){
        Task taskrec = [SELECT Id, WhatId FROM Task WHERE Id = : taskId LIMIT 1];
        String relatedId = taskrec.WhatId;
        return relatedId;
    }

    @AuraEnabled(cacheable=true)
    public static String requestedOperation(Id taskId){
        system.debug('Id:' + taskId);
        Task taskrec = [SELECT Id, Requested_Operation__c FROM Task where Id =: taskId];
        String reqoperation = taskrec.Requested_Operation__c;
        System.debug('picklist val:' +reqoperation);
        return reqoperation;
    }
    
}