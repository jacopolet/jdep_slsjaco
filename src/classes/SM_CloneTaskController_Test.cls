@isTest
private class SM_CloneTaskController_Test {
    private static testMethod void clonetask(){
        Id taskAutomated = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Office__c = null;
        acc.Archiving_Flag__c = true;
        acc.BillingStreet = 'mainstreet';
        acc.Main_House_Number__c = '123';
        acc.Main_Street_Only__c = 'streetOnly';
        acc.BillingCity = 'mainCity';
        acc.BillingState = 'state';
        acc.BillingPostalCode = 'pCode';
        acc.BillingCountry = 'country';
        acc.Main_Country_ISO__c = 'countryISO' ;
        acc.Main_Postal_Box__c = 'pBox';
        acc.Language__c = 'SAP_SR';
        acc.Bill_Block_Reason__c = 'SAP_00';
        acc.Transactional_Block_Reason__c = 'SAP_00';
        acc.Delivery_Block_Reason__c = 'SAP_D3';
        acc.SAP_Customer_ID__c = '1234567890';
        acc.Phone = '+31302979111';
        insert acc;
        
        Task taskRec = new Task();
        taskRec.WhatId = acc.Id;
        taskRec.Subject = 'asdfggg';
        taskRec.RecordTypeId = taskAutomated;
        taskRec.ActivityDate = System.today();
        taskRec.Priority = 'High Priority';
        taskRec.Type = 'Call';
        taskRec.Task_Source__c = 'EPI';
        taskRec.Status = 'Open'; 
        taskRec.Reason__c = null;
        taskRec.Sales_Organization__c = 'SAP_0111'; 
        taskRec.Role_Id__c = null;
        taskRec.WhoType__c = null;
        taskRec.WhatType__c = null;
        taskRec.Campaign__c = null;
        taskRec.Contact__c = null;
        taskRec.Date_Time_Closed__c = null;
        taskRec.WhoId = null;
        taskRec.Description = 'asdfasdfasdfsadfsadf';
        taskRec.Start_DateCS__c = null;
        taskRec.Suggested_Completion_Date__c = null; 
        taskRec.Contract_Asset_Expiration_Date__c = null; 
        taskRec.Task_Expiration_Date__c = null;
        taskRec.Contract_Asset_Lifetime__c = null;
        taskRec.Touchpoint_Type__c = 'INBOUND CALL';
        taskRec.Guidance__c = null;
        taskRec.Account_Segment_HANA__c = null;
        taskRec.Account_Lifecycle_HANA__c = null;
        taskRec.Oldest_Contract_End_Date_Expiration_F__c = null;
        taskRec.Oldest_Contract_End_Date_Relationship__c = null;
        taskRec.Oldest_Machine_Installation_Date_Expira__c = null;
        taskRec.Oldest_Machine_Installation_Date_Relati__c = null;
        taskRec.Newest_Contract_End_Date_Expiration_F__c = null;
        taskRec.Newest_Contract_End_Date_Relationship__c = null;
        taskRec.Newest_Machine_Installation_Date_Expira__c = null;
        taskRec.Newest_Machine_Installation_Date_Relati__c = null;
        taskRec.Cloned__c = false;
               
        Test.startTest();
        
        insert taskRec;
        
        SM_CloneTaskController.getTaskInfo(taskRec.Id);
        
        Task taskCloned = SM_CloneTaskController.getTaskInfo(taskRec.Id);
        
        System.assertEquals(taskRec.Priority, taskCloned.Priority);
        
        Test.stopTest();
    }
}