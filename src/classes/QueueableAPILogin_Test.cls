/**
* @author        Rey Austral
* @date          5.31.2017           
* @description   Test class for QueueableAPILogin
* @revision(s)
*/
@isTest
public class QueueableAPILogin_Test {
    private static testMethod void getSessionId_Test()
     { 
        IntegrationTriggerSettings__c trg1 = IntegrationTriggerSettings__c.getOrgDefaults();
        trg1.IntegrationLogTrigger__c = true;
        upsert trg1; 

        upsert new IntegrationUserAndProfile__c(Click_Username__c= 'user',Click_Password__c='password',Click_Endpoint_URL__c = 'https://test.salesforce.com/services/Soap/c/39.0/0DF9E0000004CHR');
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new QueueableAPILogin_Mock ());

        ID jobID = System.enqueueJob(new QueueableAPILogin());
        test.stopTest();
        List<Integration_Log__c> count = [Select Id from Integration_Log__c];
        System.assertnotequals(0, count.size());
     }

    private static testMethod void getSessionIdCallOutError_Test()
     { 
        IntegrationTriggerSettings__c trg1 = IntegrationTriggerSettings__c.getOrgDefaults();
        trg1.IntegrationLogTrigger__c = true;
        upsert trg1; 
        
        upsert new IntegrationUserAndProfile__c(Click_Username__c= 'user',Click_Password__c='password',Click_Endpoint_URL__c = 'https://test.salesforce.com/services/Soap/c/39.0/0DF9E0000004CHR');
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new QueueableAPILogin_FailMock  ());
        ID jobID = System.enqueueJob(new QueueableAPILogin());
        test.stopTest();
        List<Integration_Log__c> count = [Select Id from Integration_Log__c];
        System.assertEquals(0, count.size());
     }
}