/*
* @author        Karen Hung
* @date          2.13.2019
* @description   Test class for TS_WorkOrderNotificationEmail
* @revision(s)
*/
@isTest
private class TS_WorkOrderNotificationEmail_Test {

static Contact con;
    static Case c;
    static WorkOrder wo;
    static Resource__c resource;
    static WorkOrderLineItem parentWOLI;
    static List<WorkOrderLineItem> workOrderLineItems;
    static EmailTemplate template;
    static TS_WorkOrderNotificationEmail.TS_EmailAttributes email;
    
    /**
    * @author        Rey Austral
    * @date          10.24.2017           
    * @description   Method responsible for creating custom setting records
    * @revision(s)   12.05.2017   Adrian Reyes: Updated test methods to meet the required code coverage
    */
    @testSetup
    static void dataSetup() {
        TriggerSettings__c trg = TriggerSettings__c.getOrgDefaults();        
        trg.WorkOrderLineItemTrigger__c = true;
        insert trg;
    }
    
    /**
    * @author        Rey Austral
    * @date          10.24.2017           
    * @description   Method responsible for creating test data
    * @revision(s)   12.05.2017   Adrian Reyes: Updated test methods to meet the required code coverage
    */
    static void setupTestData() {
        con = TS_TestDataFactory.createContact();
        con.Preferred_Language__c = 'SAP_EN';
        con.CaseClosureNotification__c = true;
        con.Communication_Preference__c = 'Email';
        con.Email = 'test@jde.com';
        insert con;
        
        c = TS_TestDataFactory.createFieldServiceCase();
        c.ContactId = con.Id;
        insert c;
        
        wo = TS_TestDataFactory.createWorkOrder();
        wo.ContactId = con.Id;
        wo.CaseId = c.Id;
        wo.WorkOrderType__c = Label.TS_Case_SubType_CorrectMaint;
        insert wo;
        
        resource = TS_TestDataFactory.createResourceSingle('Test Resource');
        insert resource;
        
        parentWOLI = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);
        parentWOLI.ExecutingEngineer__c = resource.Id;
        parentWOLI.Status = Label.TS_WOLI_Status_Completed;
        parentWOLI.InternalOrderSAP__c = '123';
        parentWOLI.WorkOrderLineItemType__c = Label.TS_Type_Task;
        parentWOLI.Case__c = c.Id;
        parentWOLI.WorkOrderId = wo.Id;
        parentWOLI.WorkOrderType__c = 'S10';
        insert parentWOLI;
        parentWOLI = [SELECT Id,Case__r.ContactId,Case__r.SalesOrganization__c,Case__r.Contact.Preferred_Language__c,Case__c,JDELineItemNumber__c FROM WorkOrderLineItem WHERE Id =: parentWOLI.Id LIMIT 1];
               
        template = new EmailTemplate(DeveloperName = 'Task_Closure_SAP_EN',FolderId = [SELECT Id FROM Folder WHERE Name = 'Case Communication' LIMIT 1].Id,TemplateType = 'Text',Name = 'Task_Closure_SAP_EN',IsActive = true);
        insert template;
        
        email = new TS_WorkOrderNotificationEmail.TS_EmailAttributes();
        email.recordId = parentWOLI.Id;
        email.targetRecipientId = parentWOLI.Case__r.ContactId;
        email.emailAddress = 'email2@test.com';
        email.emailfromAddress = [SELECT Address FROM OrgWideEmailAddress LIMIT 1].Address;
        email.hasEmailMessage = true;
        email.ccAddress = 'ccAddress@test.com';
        email.bccAddress = 'bccAddress@test.com';
        email.replyTo = 'replyTo@test.com';
        email.emailTemplateName = 'Task_Closure_SAP_EN';
        email.selectedlanguage = 'SAP_EN';
        email.selectedCountry = parentWOLI.Case__r.SalesOrganization__c;
        email.isTargetNotRecepient = true;
    }
    
    
    /**
    * @author        Karen Hung
    * @date          2.13.19          
    * @description   Test method to cover email sending
    * @revision(s)   
    */
    static testMethod void testemail() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
            
            Test.startTest();                                 
            TS_WorkOrderNotificationEmail.sendWorkOderEmail(New TS_WorkOrderNotificationEmail.TS_EmailAttributes[]{email});
            Test.stopTest();
            
            //Verify Results
            System.assertEquals(0,[SELECT COUNT() FROM EmailMessage WHERE ParentId =: parentWOLI.Case__c]);
        }
    }
    
        /**
    * @author        Karen Hung
    * @date          2.13.19          
    * @description   Test method to cover email sending exception
    * @revision(s)   
    */
    static testMethod void testemailEx() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
            
            Test.startTest();                      
            TS_WorkOrderNotificationEmail.hasException = true;
            TS_WorkOrderNotificationEmail.sendWorkOderEmail(New TS_WorkOrderNotificationEmail.TS_EmailAttributes[]{email});
            Test.stopTest();
            
            //Verify Results
            System.assertEquals(0,[SELECT COUNT() FROM EmailMessage WHERE ParentId =: parentWOLI.Case__c]);
        }
    }
}