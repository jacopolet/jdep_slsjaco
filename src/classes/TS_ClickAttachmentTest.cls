/*
* @author        Harold Marilag
* @date          6.29.2017          
* @description   Test Class for TS_ClickAttachment
* @revision(s)
*/
@isTest
private class TS_ClickAttachmentTest {
    
    
    static void dataSetup(){
        
        TriggerSettings__c trg = TriggerSettings__c.getOrgDefaults();
        trg.WorkOrderLineItemTrigger__c = true;
        upsert trg;
        
        IntegrationTriggerSettings__c trg1 = IntegrationTriggerSettings__c.getOrgDefaults();
        trg1.IntegrationLogTrigger__c = true;
        upsert trg1; 
        
        ProcessBuilderSettings__c pb = new ProcessBuilderSettings__c();
        pb.CasePBFlows__c = true;
        insert pb;
        
    }
    
    private static testMethod void testAttachFile(){
        
        IntegrationTriggerSettings__c trg = new IntegrationTriggerSettings__c();
        trg.IntegrationLogTrigger__c = true;
        insert trg;
        
        Account newAccount = new Account(Name = 'Sample', Phone='+31302979111');
        insert newAccount;
        
        Contact c = TS_TestDataFactory.createContact();  
        c.Preferred_Language__c = 'SAP_EN';
        Insert c;
        
        Case newCase = new Case(Subject = 'Sample Case', AccountId = newAccount.Id, SLADate__c=datetime.now(), Status = 'New', SubType__c='Corrective Maintenance', Type='Field Service', ContactId = c.Id, Origin='E-mail',
                                SalesOrganization__c='SAP_0333' );
        insert newCase;
        
        WorkOrder wo = TS_TestDataFactory.createWorkOrder();
        wo.CaseId = newCase.Id;
        wo.WorkOrderType__c = Label.TS_Case_SubType_CorrectMaint;
        wo.ContactId = c.Id;
        insert wo;
        
        Resource__c testResource = TS_TestDataFactory.createResourceSingle('Test Resource Number');
        insert testResource;
        
        WorkOrderLineItem woli = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);
        woli.ExecutingEngineer__c = testResource.Id;
        woli.Status = Label.TS_Status_CompleteD;
        woli.InternalOrderSAP__c = '123';  
        woli.WorkOrderLineItemType__c = Label.TS_Type_Task;   
        woli.Case__c = newCase.Id;
        insert woli;
        
        List<Integration_Log__c> iLogList = new List<Integration_Log__c>();
        Integration_Log__c i1 = new Integration_Log__c();
        i1.Object_Id__c = woli.Id;
        i1.Work_Order_Line_Item__c  = woli.Id;
        i1.Object__c = INT_Constants.CLICK_ATTACHMENT;
        i1.Useful_Container__c = '/jdedev01/(S3)b0f8a244(S3)_MasterData_Relations_Dic.jpg';
        iLogList.add(i1);
        
        Integration_Log__c i2 = new Integration_Log__c();
        i2.Object_Id__c = woli.Id;
        i2.Work_Order_Line_Item__c  = woli.Id;
        i2.Object__c = INT_Constants.CLICK_ATTACHMENT;
        i2.Useful_Container__c = 'iVBORw0KGgoAAAANSUhEUgAAADsAAAArCAIAAABJkWd/AAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAACUSURBVFhH7dTBDYAgEERR69qCqIdqaIZi0DWonFdnko3zT4TTy4SwjWxJjE9ifBLjkxifxPgkxicxvv+IW9lmVvu84xQSO/eC+rm088gpIu7VlmUPMnXm8Mb3ruyRg+/YmTMzyyBeSrLxExv8Vuxe8vcWEvtnMWP/xl+8Y3YS45MYn8T4JMYnMT6J8UmMT2J82cRj7GL5WfT8jo00AAAAAElFTkSuQmCC';
        iLogList.add(i2);
        
        Integration_Log__c i3 = new Integration_Log__c();
        i3.Object_Id__c = woli.Id;
        i3.Work_Order_Line_Item__c  = woli.Id;
        i3.Object__c = INT_Constants.CLICK_ATTACHMENT;
        iLogList.add(i3);
        
        insert iLogList;
        
        
        IntegrationUserAndProfile__c integ = new IntegrationUserAndProfile__c(Click_Delete_Success_Logs__c = true, 
                                                                              Click_Token_Server__c = 'https://eu01-int.cloud.clicksoftware.com//SO/api/S3Token', 
                                                                              AWS_Endpoint__c = 'https://eu01-s3-store.s3.amazonaws.com/',
                                                                              AWS_Password__c = 'ClickJDE2016',
                                                                              AWS_Username__c = 'integration@JDEDev01');
        upsert integ;
        
        QueueableAPILogin_Mock awsfileresult= new QueueableAPILogin_Mock();       
        awsfileresult.body = '{"User": null, "Bucket": "eu01-s3-store", "AccessKeyId": "ASIAJWHUXVYYGGXO272Q", "SecretAccessKey": "vCVHLTRnMQInW4bxFVqNrh3RA3C/iEoiUvA5qhgd", "Token": "FQoDYXdzEOr//////////wEaDBMeLgAq9I5kToJjdSK+AhCFUgs4+79ft9RXLAlWhiXw6v3EzSV/OJeGMfVh/2wKVTx60kxgO26ppNj7Gy0UHFZ6yH+m0vXgt4LB0ETLxMCLqf+zuyDOHUCLoxihN0SUoG7s/80ROQqyHXEnk0RUbhZdaYIFlguGGBEkq56PEqPI7oiebS/PdtKvFjKS8skNOLAVk+LMK1KIUGszFO4gMHbMRW0bBMWhTB+qXBe9EJNmsDEqfXxKUzF7xFy+Aypl5DA6ZY1TSDyNUXx6CCmMQfewlKNg932SsLLj+7CAzYLpvjqLm+vHUd0iAZxMP3FqqdoHKjh1BBWVfhzSuH0YKpdxI706HzsHTBxPQ0y79Oq59ZEDjcEylez0fdULjVQ7zE0B7O3Qh92dBqPmtetLhfWpr88H3zUezvk+1CKRqzaPadTnTMdArsOWdqsDISiXqu3KBQ==", "Expiration": "2017-07-04T16:43:03+00:00", "AWSRegion": "eu-central-1"}';
        awsfileresult.callstatus =404;
        Test.setMock(HttpCalloutMock.class, awsfileresult);
        
        
        TS_ClickAttachment ca = new TS_ClickAttachment();
        ca.AttachFile(iLogList);
        
        List<ContentVersion> cvList = [Select ContentDocumentId from ContentVersion];
        system.assertEquals(0, cvList.size());
    }
    
}