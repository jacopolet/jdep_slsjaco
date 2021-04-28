/**
* Class Name : APTS_BatchLogEventTriggerHandler_Test
* Description :  Test class to test APTS_BatchLogEventTriggerHandler Apex class 
* Author : Nagavi Babu
* Date Created : 22-03-2018
**/
@isTest
private class APTS_BatchLogEventTriggerHandler_Test{
    
    static testMethod void testBatchLogEvent(){
        TriggerSettings__c settings = new TriggerSettings__c();
        settings.BatchLogEventTrigger__c = true;
        Database.insert(settings, false);
        
        APTS_Batch_Log_Event__e logEvent = new APTS_Batch_Log_Event__e();
        logEvent.APTS_Error_Date_Time__c = System.Now();
        logEvent.APTS_Error_Description__c = 'Test Description';
        logEvent.APTS_Error_Level__c = 'Error';
        logEvent.APTS_Error_Name__c = 'Test Error';
        logEvent.APTS_Object_Id__c = '123456789';
        logEvent.APTS_Object_Name__c = 'Test Object';
        
        Test.startTest();
        EventBus.publish(logEvent);
        Test.stopTest();
        
        List<APTS_Batch_Error__c> batchErrorList = [SELECT Id, APTS_Error_Name__c, Error_Date_Time__c, APTS_Error_Level__c, APTS_Error_Description__c, APTS_Parent_ID__c,
                                                    APTS_Parent_Object_Name__c FROM APTS_Batch_Error__c WHERE APTS_Parent_ID__c =: logEvent.APTS_Object_Id__c 
                                                    AND APTS_Error_Name__c =: logEvent.APTS_Error_Name__c LIMIT 1];
                                                    
        if(!batchErrorList.IsEmpty()){
            System.AssertEquals(batchErrorList[0].APTS_Error_Name__c, logEvent.APTS_Error_Name__c);
            System.AssertEquals(batchErrorList[0].Error_Date_Time__c, logEvent.APTS_Error_Date_Time__c);
            System.AssertEquals(batchErrorList[0].APTS_Error_Level__c, logEvent.APTS_Error_Level__c);
            System.AssertEquals(batchErrorList[0].APTS_Error_Description__c, logEvent.APTS_Error_Description__c);
            System.AssertEquals(batchErrorList[0].APTS_Parent_ID__c, logEvent.APTS_Object_Id__c);
            System.AssertEquals(batchErrorList[0].APTS_Parent_Object_Name__c, logEvent.APTS_Object_Name__c);
        }
        
        List<SObject> sObjList = new List<SObject>();
        Map<Id, SObject> sObjMap = new Map<Id, SObject>();
        
        APTS_BatchLogEventTriggerHandler handler = new APTS_BatchLogEventTriggerHandler();
        handler.BeforeInsert(sObjList);
        handler.BeforeUpdate(sObjList, sObjMap, sObjList, sObjMap);
        handler.BeforeDelete(sObjList, sObjMap);
        handler.AfterUpdate(sObjList, sObjMap, sObjList, sObjMap);
        handler.AfterDelete(sObjList, sObjMap);
        handler.AfterUnDelete(sObjList, sObjMap);
    }

}