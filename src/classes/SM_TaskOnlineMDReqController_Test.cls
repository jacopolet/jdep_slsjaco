@isTest
public class SM_TaskOnlineMDReqController_Test {
	
    static void testSetup(){
        
        

    }
    
    private static testMethod void testRetrieveMethod(){
        
        Account acc = new Account();
        acc.Name = 'Account Name';
        insert acc;
        
        Apttus_Config2__AccountLocation__c accLoc = new Apttus_Config2__AccountLocation__c();
        accLoc.Apttus_Config2__AccountId__c = acc.Id;
        accLoc.Name = 'Account Loc Name';
        insert accLoc;
        
        Task tsk1 = new Task();
        tsk1.Subject = 'Task Name';
        tsk1.WhatId = acc.Id;
        tsk1.Touchpoint_Type__c = 'ONLINE MASTER DATA CHANGE REQ';
        tsk1.Requested_Operation__c = 'Update Account';
        insert tsk1;
        
        Task tsk2 = new Task();
        tsk2.Subject = 'Task Name';
        tsk2.WhatId = accLoc.Id;
        tsk2.Touchpoint_Type__c = 'ONLINE MASTER DATA CHANGE REQ';
        tsk2.Requested_Operation__c = 'Update Account Location';
        insert tsk2;
        
        Task tsk3 = SM_TaskOnlineMDReqController.getTaskRecord(tsk1.Id);
        system.assertEquals(tsk3.Requested_Operation__c , tsk1.Requested_Operation__c);
        
        String idString = SM_TaskOnlineMDReqController.getRelatedWhatId(tsk1.Id);
        system.assert(idString != null);
        
        String operation = SM_TaskOnlineMDReqController.requestedOperation(tsk2.Id);
        system.assertEquals(operation, tsk2.Requested_Operation__c);
        
    }
}