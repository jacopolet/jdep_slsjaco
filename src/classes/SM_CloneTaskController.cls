public with sharing class SM_CloneTaskController {

    @AuraEnabled
    public static Task getTaskInfo(String taskId){
        return [SELECT Id, 
                Subject, 
                RecordTypeId, 
                ActivityDate, 
                Priority, 
                Type, 
                Task_Source__c, 
                Status,  
                Reason__c, 
                Sales_Organization__c, 
                Role_Id__c, 
                WhoType__c, 
                WhatType__c, 
                Campaign__c, 
                Contact__c, 
                Date_Time_Closed__c, 
                WhatId, 
                WhoId, 
                Description, 
                Start_DateCS__c,
                Suggested_Completion_Date__c, 
                Contract_Asset_Expiration_Date__c, 
                Task_Expiration_Date__c,
                Contract_Asset_Lifetime__c, 
                Touchpoint_Type__c,
                Guidance__c, 
                Account_Segment_HANA__c, 
                Account_Lifecycle_HANA__c, 
                Oldest_Contract_End_Date_Expiration_F__c, 
                Oldest_Contract_End_Date_Relationship__c, 
                Oldest_Machine_Installation_Date_Expira__c, 
                Oldest_Machine_Installation_Date_Relati__c,
                Newest_Contract_End_Date_Expiration_F__c, 
                Newest_Contract_End_Date_Relationship__c, 
                Newest_Machine_Installation_Date_Expira__c, 
                Newest_Machine_Installation_Date_Relati__c, 
                Cloned__c FROM Task WHERE Id =:taskId LIMIT 1 ];
    }
    
}