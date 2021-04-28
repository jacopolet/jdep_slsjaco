//-------------------------------------------------------------------------------------------//
// Author       :   Rey Austral - Accenture
// Created Date :   March 17, 2017
// Usage        :   Test Class for IntegrationLogTriggerHandler
//-------------------------------------------------------------------------------------------//
@isTest
public class IntegrationLogTriggerHandler_Test {
	
	/* Method in the main class is to be reevaluate
    static testMethod void test_SAPReadyTobeSentProcess(){
        IntegrationTriggerSettings__c trg = new IntegrationTriggerSettings__c();
        trg.IntegrationLogTrigger__c = true;
        insert trg;
        
        Integration_Log__c parent = new Integration_Log__c();
        parent.Object__c = 'Account';
        parent.Object_Id__c = '1234567689';
        parent.Integration_Status__c = INT_Constants.INITIAL;
        insert parent;
        
        List<Integration_Log__c> childList = new List<Integration_Log__c>();
        for (Integer ctr =0; ctr < 500; ctr++) {            
            Integration_Log__c child = new Integration_Log__c();
            child.Object__c = 'Account';
            child.Object_Id__c = '1234567689';
            child.Parent_Integration_Log__c = parent.Id;
            child.Integration_Status__c = INT_Constants.INITIAL;
            childList.add(child);
        }
        test.startTest();
        insert childList;
        List<Integration_Log__c> updatedchildList = [Select Id,Integration_Status__c from Integration_Log__c where ID != : parent.Id ];
        for(Integration_Log__c uChild : updatedchildList) {
            system.assertEquals(INT_Constants.WAITING_ON_PARENT_INTEGRATION, uChild.Integration_Status__c);
        }
        parent.Integration_Status__c = INT_Constants.TARGET_SYSTEM_SUCCESS;
        update parent;
        updatedchildList = [Select Id,Integration_Status__c, Ready_To_Be_Sent__c from Integration_Log__c where ID != : parent.Id ];
        for(Integration_Log__c uChild : updatedchildList) {
            system.assertEquals(true, uChild.Ready_To_Be_Sent__c);
        }
        test.stopTest();
    } 
    */

    static testMethod void test_InsertReady(){
        IntegrationTriggerSettings__c trg = new IntegrationTriggerSettings__c();
        trg.IntegrationLogTrigger__c = true;
        insert trg;
        
        test.startTest();
	        List<Integration_Log__c> iLogList = new List<Integration_Log__c>();
	
	        Set<String> oBjectValues = new Set<String>();
	        oBjectValues.add(INT_Constants.WOLI_CREATEUPDATETASK);
	        oBjectValues.add(INT_Constants.CLICK_SESSIONID);
	        oBjectValues.add(INT_Constants.CLICK_NOTIFICATION);
	        oBjectValues.add(INT_Constants.CLICK_GETAVAILABLESLOTS);
	        //oBjectValues.add(INT_Constants.CLICK_ATTACHMENT);
	        oBjectValues.add(INT_Constants.WOLI_CREATEUPDATE_OPERATING_TASK);
	        oBjectValues.add(INT_Constants.WOLI_CREATEUPDATE_COUNTERREADING_TASK);
	        //oBjectValues.add(INT_Constants.CLICK_SYNCMASTERPRODUCT);
	        oBjectValues.add('Work Order Line Item - Attachment');
            oBjectValues.add(INT_Constants.WOLI_CREATEUPDATE_OPERATINGROUTE_TASK);
            oBjectValues.add(INT_Constants.WOLI_CREATEUPDATE_OPERATING_TASK_ROUTEITEM);
	        WorkOrderTriggerObjectHandler.fromSalesTrigger = true;
	        for (String eachOjectValue :oBjectValues) {
	        	Integration_Log__c iLog = new Integration_Log__c();
	        	iLog.Object__c =  eachOjectValue;
		        iLog.Object_Id__c = '1234567689';
		        iLog.Integration_Status__c = INT_Constants.INITIAL;
		        iLogList.add(iLog);
	        }
	        insert iLogList;
	        
        test.stopTest();      
   
        List<Integration_Log__c> iLogQueriedList = [Select Id,Integration_Status__c, Ready_To_Be_Sent__c from Integration_Log__c 
        										  Where Integration_Status__c = :INT_Constants.INITIAL ];
        for (Integration_Log__c eachILog :iLogQueriedList) {
        	system.assertEquals(true, eachILog.Ready_To_Be_Sent__c);
    	}
    	
    	
    } 
    
    static testMethod void test_UpdateReady(){
        IntegrationTriggerSettings__c trg = new IntegrationTriggerSettings__c();
        trg.IntegrationLogTrigger__c = true;
        insert trg;
        
        test.startTest();
	        List<Integration_Log__c> iLogList = new List<Integration_Log__c>();
	
	        Set<String> oBjectValues = new Set<String>();
	        oBjectValues.add(INT_Constants.WOLI_CREATEUPDATETASK);
	        oBjectValues.add(INT_Constants.CLICK_SESSIONID);
	        oBjectValues.add(INT_Constants.CLICK_NOTIFICATION);
	        oBjectValues.add(INT_Constants.CLICK_GETAVAILABLESLOTS);
	        //oBjectValues.add(INT_Constants.CLICK_ATTACHMENT);
	        oBjectValues.add(INT_Constants.WOLI_CREATEUPDATE_OPERATING_TASK);
	        oBjectValues.add(INT_Constants.WOLI_CREATEUPDATE_COUNTERREADING_TASK);
	        //oBjectValues.add(INT_Constants.CLICK_SYNCMASTERPRODUCT);
	        oBjectValues.add('Work Order Line Item - Attachment');
            oBjectValues.add(INT_Constants.WOLI_CREATEUPDATE_OPERATINGROUTE_TASK);
            oBjectValues.add(INT_Constants.WOLI_CREATEUPDATE_OPERATING_TASK_ROUTEITEM);
	        WorkOrderTriggerObjectHandler.fromSalesTrigger = false;
	        for (String eachOjectValue :oBjectValues) {
	        	Integration_Log__c iLog = new Integration_Log__c();
	        	iLog.Object__c =  eachOjectValue;
		        iLog.Object_Id__c = '1234567689';
		        iLog.Integration_Status__c = INT_Constants.INITIAL;
		        iLogList.add(iLog);
	        }
	        insert iLogList;
	        
        test.stopTest();      
   
        Integration_Log__c iLog = [Select Id,Integration_Status__c, Ready_To_Be_Sent__c from Integration_Log__c 
        										    Where Object__c = :INT_Constants.WOLI_CREATEUPDATETASK ];
        
        iLog.Integration_Status__c = INT_Constants.WAITING_ON_PARENT_INTEGRATION;
        update iLog;
        delete iLog;
    	
    } 
    
    
    
}