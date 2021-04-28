/**
* @author        Rey Austral
* @date          10.24.2017           
* @description   Test Class for TS_EmailUtility
* @revision(s)
12.05.2017   Adrian Reyes: Updated test methods to meet the required code coverage
*/

@isTest
public with sharing class TS_EmailUtilityTest {
    static Contact con;
    static Case c;
    static WorkOrder wo;
    static Resource__c resource;
    static WorkOrderLineItem parentWOLI;
    static List<WorkOrderLineItem> workOrderLineItems;
    static EmailTemplate template;
    
    /**
    * @author        Rey Austral
    * @date          10.24.2017           
    * @description   Method responsible for creating custom setting records
    * @revision(s)	 12.05.2017   Adrian Reyes: Updated test methods to meet the required code coverage
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
    * @revision(s)	 12.05.2017   Adrian Reyes: Updated test methods to meet the required code coverage
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
        
        workOrderLineItems = new List<WorkOrderLineItem>();
        WorkOrderLineItem serviceMaterial = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);
        serviceMaterial.Status = Label.TS_WOLI_Status_Completed;
        serviceMaterial.WorkOrderLineItemType__c = Label.TS_Type_Service;
        serviceMaterial.Case__c = c.Id;
        serviceMaterial.ParentWorkOrderLineItemId = parentWOLI.Id;
        workOrderLineItems.add(serviceMaterial);
        
        template = new EmailTemplate(DeveloperName = 'Task_Closure_SAP_EN',FolderId = [SELECT Id FROM Folder WHERE Name = 'Case Communication' LIMIT 1].Id,TemplateType = 'Text',Name = 'Task_Closure_SAP_EN',IsActive = true);
        insert template;
	}
    
    /**
    * @author        Rey Austral
    * @date          10.24.2017           
    * @description   Test method to cover sendEmailWithAttachment
    * @revision(s)	 12.05.2017   Adrian Reyes: Updated test methods to meet the required code coverage
    */
	/*
	static testMethod void testExecute() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
            
            insert new ProcessBuilderSettings__c(WorkOrderLineItemPBFlows__c = true);
            
            Test.startTest();
            WorkOrderLineItem woli = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);         
            woli.Status = Label.TS_WOLI_Status_Completed;       
            woli.WorkOrderLineItemType__c = Label.TS_Type_Service;   
            woli.Case__c = c.Id;
            woli.ParentWorkOrderLineItemId = parentWOLI.Id;         
            woli.IsReadyToSummarize__c = true;
            insert woli;
            Test.stopTest();
            
            //Verify Results
            System.assertEquals(1,[SELECT COUNT() FROM EmailMessage WHERE ParentId =: parentWOLI.Case__c]);
        }
	}
    */
    
    /**
    * @author        Rey Austral
    * @date          10.24.2017           
    * @description   Test method to cover Created PDF
    * @revision(s)	 12.05.2017   Adrian Reyes: Updated test methods to meet the required code coverage
    */
	static testMethod void testCreatedPDF() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
            
            Test.startTest();
            Blob b = Blob.valueOf('UNIT.Test');
            ContentVersion signatureFile = new ContentVersion();
            signatureFile.VersionData = b;
            signatureFile.Title = 'WO Estimate ' + parentWOLI.JDELineItemNumber__c;
            signatureFile.PathOnClient = 'WO_Estimate_' + parentWOLI.JDELineItemNumber__c  + '.pdf';
            signatureFile.ContentLocation='S';
            signatureFile.Description  = parentWOLI.Case__c;
            signatureFile.ObjectReferenceID__c = parentWOLI.Id ;
            insert signatureFile;
            
            List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
            List<ContentDistribution> cdList = new List<ContentDistribution>();
            for(ContentVersion cont : [SELECT ContentDocumentId,Description,PathOnClient, ObjectReferenceID__c FROM ContentVersion WHERE id =: signatureFile.Id]) {
                cdlList.add( new ContentDocumentLink(ContentDocumentId = cont.ContentDocumentId, LinkedEntityId = cont.ObjectReferenceID__c, ShareType = 'V') );
                cdlList.add( new ContentDocumentLink(ContentDocumentId = cont.ContentDocumentId, LinkedEntityId = cont.Description, ShareType = 'V') );
                cdList.add( new ContentDistribution(PreferencesAllowPDFDownload = true, Name = cont.PathOnClient, ContentVersionId = cont.Id, RelatedRecordId = cont.Description) );
            }
            
            insert cdlList;
            insert cdList;
            
            TS_EmailUtility.TS_EmailAttributes req = new TS_EmailUtility.TS_EmailAttributes();
            req.recordId = parentWOLI.Id;
            req.targetRecipientId = parentWOLI.Case__r.ContactId;
            req.selectedCountry = parentWOLI.Case__r.SalesOrganization__c;
            req.emailParentID = parentWOLI.Case__c;
            req.hasEmailMessage = true;
            req.hasToGenerateLinkWithPDF = true;
            req.emailTemplateName = 'Task_Closure_SAP_EN';
            req.filesId = parentWOLI.Case__c;
            req.filesId2 = parentWOLI.Case__c;
            req.filesId3 = parentWOLI.Case__c;
            req.emailfromAddress = [SELECT Address FROM OrgWideEmailAddress LIMIT 1].Address;
            req.emailAddress2 = 'emailAddress2@test.com';
            req.ccAddress = 'ccAddress@test.com';
            req.bccAddress = 'bccAddress@test.com';
            
            TS_EmailUtility.sendEmailWithAttachment(New TS_EmailUtility.TS_EmailAttributes[]{req});
            Test.stopTest();
            
            //Verify Results
            System.assertEquals(1,[SELECT COUNT() FROM EmailMessage WHERE ParentId =: parentWOLI.Case__c]);
        }
	}
    
    /**
    * @author        Rey Austral
    * @date          10.24.2017           
    * @description   Test method to cover Created Link
    * @revision(s)	 12.05.2017   Adrian Reyes: Updated test methods to meet the required code coverage
    */
	static testMethod void testCreatedLink() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
            
            Test.startTest();
            Blob b = Blob.valueOf('UNIT.Test');
            ContentVersion signatureFile = new ContentVersion();
            signatureFile.VersionData = b;
            signatureFile.Title = 'WO Estimate ' + parentWOLI.JDELineItemNumber__c;
            signatureFile.PathOnClient = 'WO_Estimate_' + parentWOLI.JDELineItemNumber__c  + '.pdf';
            signatureFile.ContentLocation='S';
            signatureFile.Description  = parentWOLI.Case__c;
            signatureFile.ObjectReferenceID__c = parentWOLI.Id ;
            insert signatureFile;
            
            List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
            List<ContentDistribution> cdList = new List<ContentDistribution>();
            for(ContentVersion cont : [SELECT ContentDocumentId,Description,PathOnClient, ObjectReferenceID__c FROM ContentVersion WHERE id =: signatureFile.Id]) {
                cdlList.add( new ContentDocumentLink(ContentDocumentId = cont.ContentDocumentId, LinkedEntityId = cont.ObjectReferenceID__c, ShareType = 'V') );
                cdlList.add( new ContentDocumentLink(ContentDocumentId = cont.ContentDocumentId, LinkedEntityId = cont.Description, ShareType = 'V') );
                cdList.add( new ContentDistribution(PreferencesAllowPDFDownload = true, Name = cont.PathOnClient, ContentVersionId = cont.Id, RelatedRecordId = cont.Description) );
            }
            
            insert cdlList;
            insert cdList;
            
            TS_EmailUtility.TS_EmailAttributes req = new TS_EmailUtility.TS_EmailAttributes();
            req.recordId = parentWOLI.Id;
            req.targetRecipientId = parentWOLI.Case__r.ContactId;
            req.selectedCountry = parentWOLI.Case__r.SalesOrganization__c;
            req.emailParentID = parentWOLI.Case__c;
            req.hasEmailMessage = true;
            req.hasToGenerateLink = true;
            req.emailTemplateName = 'Task_Closure_SAP_EN';
            req.filesId = parentWOLI.Case__c;
            req.filesId2 = parentWOLI.Case__c;
            req.filesId3 = parentWOLI.Case__c;
            
            TS_EmailUtility.sendEmailWithAttachment(New TS_EmailUtility.TS_EmailAttributes[]{req});
            Test.stopTest();
            
            //Verify Results
            System.assertEquals(1,[SELECT COUNT() FROM EmailMessage WHERE ParentId =: parentWOLI.Case__c]);
        }
	}
    
    /**
    * @author        Rey Austral
    * @date          10.24.2017           
    * @description   Test method to cover No Template
    * @revision(s)	 12.05.2017   Adrian Reyes: Updated test methods to meet the required code coverage
    */
	static testMethod void testNoTemplate() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
            
            Test.startTest();
            TS_EmailUtility.TS_EmailAttributes req = new TS_EmailUtility.TS_EmailAttributes();
            req.recordId = parentWOLI.Id;
            req.targetRecipientId = parentWOLI.Case__r.ContactId;
            req.selectedCountry = parentWOLI.Case__r.SalesOrganization__c;
            req.emailParentID = parentWOLI.Case__c;
            req.hasEmailMessage = true;
            req.hasToGenerateLink = false;
            req.emailTemplateName = 'Task_Closure_SAP_PH';
            req.filesId = parentWOLI.Case__c;
            req.filesId2 = parentWOLI.Case__c;
            req.filesId3 = parentWOLI.Case__c;
            req.setManualEmailBody = 'Test Email Body';
            req.emailAddress = con.Email;
            
            TS_EmailUtility.sendEmailWithAttachment(New TS_EmailUtility.TS_EmailAttributes[]{req});
            Test.stopTest();
            
            //Verify Results
            System.assertEquals(1,[SELECT COUNT() FROM EmailMessage WHERE ParentId =: parentWOLI.Case__c]);
        }
	}
    
    /**
    * @author        Adrian Reyes
    * @date          12.07.2017           
    * @description   Test method to cover Generate Attachment
    * @revision(s)
    */
	static testMethod void testGenerateAttachment() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
            
            Test.startTest();
            Blob b = Blob.valueOf('UNIT.Test');
            ContentVersion signatureFile = new ContentVersion();
            List <ContentVersion> sigFiles = new List <ContentVersion> ();
            
            signatureFile.VersionData = b;
            signatureFile.Title = 'WO Estimate ' + parentWOLI.JDELineItemNumber__c;
            signatureFile.PathOnClient = 'WO_Estimate_' + parentWOLI.JDELineItemNumber__c  + '.pdf';
            signatureFile.ContentLocation='S';
            signatureFile.Description  = parentWOLI.Case__c;
            signatureFile.ObjectReferenceID__c = parentWOLI.Id ;
            //insert signatureFile;
            sigFiles.add(signatureFile);
            
            signatureFile = new ContentVersion();
            signatureFile.VersionData = b;
            signatureFile.Title = 'WO Estimate 2' + parentWOLI.JDELineItemNumber__c;
            signatureFile.PathOnClient = 'WO_Estimate_2' + parentWOLI.JDELineItemNumber__c  + '.pdf';
            signatureFile.ContentLocation='S';
            signatureFile.Description  = parentWOLI.Case__c;
            signatureFile.ObjectReferenceID__c = parentWOLI.Id ;
            //insert signatureFile;
            sigFiles.add(signatureFile);
            insert sigFiles;
            
            
            List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
            List<ContentDistribution> cdList = new List<ContentDistribution>();
            for(ContentVersion cont : [SELECT ContentDocumentId,Description,PathOnClient, ObjectReferenceID__c FROM ContentVersion WHERE id =: sigFiles]) {
                cdlList.add( new ContentDocumentLink(ContentDocumentId = cont.ContentDocumentId, LinkedEntityId = cont.ObjectReferenceID__c, ShareType = 'V') );
                cdlList.add( new ContentDocumentLink(ContentDocumentId = cont.ContentDocumentId, LinkedEntityId = cont.Description, ShareType = 'V') );
                cdList.add( new ContentDistribution(PreferencesAllowPDFDownload = true, Name = cont.PathOnClient, ContentVersionId = cont.Id, RelatedRecordId = cont.Description) );
            }
            
            //SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :sObjectIds
            
            insert cdlList;
            insert cdList;
            
            TS_EmailUtility.TS_EmailAttributes req = new TS_EmailUtility.TS_EmailAttributes();
            req.recordId = parentWOLI.Id;
            req.targetRecipientId = parentWOLI.Case__r.ContactId;
            req.selectedCountry = parentWOLI.Case__r.SalesOrganization__c;
            req.emailParentID = parentWOLI.Case__c;
            req.hasEmailMessage = true;
            req.hasToGenerateAttachment = true;
            req.emailTemplateName = 'Task_Closure_SAP_EN';
            req.filesId = parentWOLI.Case__c;
            req.filesId2 = parentWOLI.Case__c;
            req.filesId3 = parentWOLI.Case__c;
            
            TS_EmailUtility.sendEmailWithAttachment(New TS_EmailUtility.TS_EmailAttributes[]{req});
            Test.stopTest();
            
            //Verify Results
            System.assertEquals(1,[SELECT COUNT() FROM EmailMessage WHERE ParentId =: parentWOLI.Case__c]);
        }
	}
    
    /**
    * @author        Adrian Reyes
    * @date          12.07.2017           
    * @description   Test method to cover Language and Country template scenario
    * @revision(s)
    */
	static testMethod void testLanguageCountry() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();

            Test.startTest();
            Blob b = Blob.valueOf('UNIT.Test');
            ContentVersion signatureFile = new ContentVersion();
            signatureFile.VersionData = b;
            signatureFile.Title = 'WO Estimate ' + parentWOLI.JDELineItemNumber__c;
            signatureFile.PathOnClient = 'WO_Estimate_' + parentWOLI.JDELineItemNumber__c  + '.pdf';
            signatureFile.ContentLocation='S';
            signatureFile.Description  = parentWOLI.Case__c;
            signatureFile.ObjectReferenceID__c = parentWOLI.Id ;
            insert signatureFile;
  
            List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
            List<ContentDistribution> cdList = new List<ContentDistribution>();
            for(ContentVersion cont : [SELECT ContentDocumentId,Description,PathOnClient, ObjectReferenceID__c FROM ContentVersion WHERE id =: signatureFile.Id]) {
                cdlList.add( new ContentDocumentLink(ContentDocumentId = cont.ContentDocumentId, LinkedEntityId = cont.ObjectReferenceID__c, ShareType = 'V') );
                cdlList.add( new ContentDocumentLink(ContentDocumentId = cont.ContentDocumentId, LinkedEntityId = cont.Description, ShareType = 'V') );
                cdList.add( new ContentDistribution(PreferencesAllowPDFDownload = true, Name = cont.PathOnClient, ContentVersionId = cont.Id, RelatedRecordId = cont.Description) );
            }
            
            insert cdlList;
            insert cdList;
            
            TS_EmailUtility.TS_EmailAttributes req = new TS_EmailUtility.TS_EmailAttributes();
            req.recordId = parentWOLI.Id;
            req.targetRecipientId = parentWOLI.Case__r.ContactId;
            req.selectedLanguage = 'EN';
            req.selectedCountry = 'PH';
            req.emailParentID = parentWOLI.Case__c;
            req.hasEmailMessage = true;
            req.hasToGenerateAttachment = true;
            req.emailTemplateName = 'Task_Closure_SAP_EN';
            req.filesId = parentWOLI.Case__c;
            req.filesId2 = parentWOLI.Case__c;
            req.filesId3 = parentWOLI.Case__c;
            req.setManualEmailBody = 'Test Email Body';
            req.emailAddress = con.Email;
            
            TS_EmailUtility.sendEmailWithAttachment(New TS_EmailUtility.TS_EmailAttributes[]{req});
            Test.stopTest();
            
            //Verify Results
            System.assertEquals(1,[SELECT COUNT() FROM EmailMessage WHERE ParentId =: parentWOLI.Case__c]);
        }
	}
    
    /**
    * @author        Adrian Reyes
    * @date          12.07.2017           
    * @description   Test method to cover Country template scenario
    * @revision(s)
    */
	static testMethod void testCountry() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
            
            Test.startTest();
            Blob b = Blob.valueOf('UNIT.Test');
            ContentVersion signatureFile = new ContentVersion();
            signatureFile.VersionData = b;
            signatureFile.Title = 'WO Estimate ' + parentWOLI.JDELineItemNumber__c;
            signatureFile.PathOnClient = 'WO_Estimate_' + parentWOLI.JDELineItemNumber__c  + '.pdf';
            signatureFile.ContentLocation='S';
            signatureFile.Description  = parentWOLI.Case__c;
            signatureFile.ObjectReferenceID__c = parentWOLI.Id ;
            insert signatureFile;
            
            List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
            List<ContentDistribution> cdList = new List<ContentDistribution>();
            for(ContentVersion cont : [SELECT ContentDocumentId,Description,PathOnClient, ObjectReferenceID__c FROM ContentVersion WHERE id =: signatureFile.Id]) {
                cdlList.add( new ContentDocumentLink(ContentDocumentId = cont.ContentDocumentId, LinkedEntityId = cont.ObjectReferenceID__c, ShareType = 'V') );
                cdlList.add( new ContentDocumentLink(ContentDocumentId = cont.ContentDocumentId, LinkedEntityId = cont.Description, ShareType = 'V') );
                cdList.add( new ContentDistribution(PreferencesAllowPDFDownload = true, Name = cont.PathOnClient, ContentVersionId = cont.Id, RelatedRecordId = cont.Description) );
            }
            
            insert cdlList;
            insert cdList;
            
            TS_EmailUtility.TS_EmailAttributes req = new TS_EmailUtility.TS_EmailAttributes();
            req.recordId = parentWOLI.Id;
            req.targetRecipientId = parentWOLI.Case__r.ContactId;
            req.selectedCountry = 'PH';
            req.emailParentID = parentWOLI.Case__c;
            req.hasEmailMessage = true;
            req.hasToGenerateAttachment = true;
            req.emailTemplateName = 'Task_Closure_SAP_EN';
            req.filesId = parentWOLI.Case__c;
            req.filesId2 = parentWOLI.Case__c;
            req.filesId3 = parentWOLI.Case__c;
            req.setManualEmailBody = 'Test Email Body';
            req.emailAddress = con.Email;
            
            TS_EmailUtility.sendEmailWithAttachment(New TS_EmailUtility.TS_EmailAttributes[]{req});
            Test.stopTest();
            
            //Verify Results
            System.assertEquals(1,[SELECT COUNT() FROM EmailMessage WHERE ParentId =: parentWOLI.Case__c]);
        }
	}
    
    /**
    * @author        Adrian Reyes
    * @date          12.07.2017           
    * @description   Test method to cover generateHyperlinksPDF
    * @revision(s)
    */
	static testMethod void testGenerateHyperlinksPDF() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
            
            Test.startTest();
            Messaging.EmailFileAttachment efa = TS_EmailUtility.generateHyperlinksPDF('objectid',false,'attcfilename');
            Test.stopTest();
            
            //Verify Results
            System.assert(efa.getFileName().endsWith('.html'));
        }
	}
}