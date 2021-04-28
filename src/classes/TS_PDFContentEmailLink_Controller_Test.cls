/**
* @author        Abram Vixen Reyes
* @date          July 30, 2019
* @description   Test class for TS_PDFContentEmailLink_Controller
* @revision(s)
*/

@isTest
public class TS_PDFContentEmailLink_Controller_Test {
    
    static Contact con;
    static Case c;
    static WorkOrder wo;
    static Resource__c resource;
    static WorkOrderLineItem parentWOLI;
    static List<WorkOrderLineItem> workOrderLineItems;
    
    static void setupTestData() {
        con = TS_TestDataFactory.createContact();
        con.Preferred_Language__c = 'SAP_NL';
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
        
	}
    
	static testMethod void test_getContent(){
        
        setupTestData();
        Test.startTest();
            ContentVersion testFile = new ContentVersion();
            Blob b = Blob.valueOf('UNIT.Test');
            testFile.VersionData = b;
            testFile.Title = 'Test Title';
            testFile.PathOnClient = 'Test.pdf';
            testFile.ContentLocation='S';
            testFile.Description  = parentWOLI.Case__c;
            testFile.ObjectReferenceID__c = parentWOLI.Id;
            insert testFile;
        
        	List<ContentVersion> CONTENT_LIST = [SELECT ContentDocumentId, Description, PathOnClient, ObjectReferenceID__c FROM ContentVersion WHERE Id =: testFile.Id];
            
            ContentDocumentLink contDoc = new ContentDocumentLink();
            contDoc.ContentDocumentId = CONTENT_LIST[0].ContentDocumentId;
            contDoc.LinkedEntityId = CONTENT_LIST[0].ObjectReferenceID__c;
            contDoc.ShareType = 'V';
            insert contDoc;
               	
            ContentDistribution cd = new ContentDistribution();
            cd.PreferencesAllowPDFDownload = true;
            cd.Name = testFile.PathOnClient;
            cd.ContentVersionId = testFile.Id;
            cd.RelatedRecordId = testFile.Description;
            cd.PreferencesAllowOriginalDownload = false;
            cd.PreferencesAllowViewInBrowser = true;
            insert cd;
            
            TS_PDFContentEmailLink_Controller PDF_CONTENT = new TS_PDFContentEmailLink_Controller();
            PDF_CONTENT.WoliID = parentWOLI.Id;
            PDF_CONTENT.fileName = 'Test.pdf';
            PDF_CONTENT.getcontent();
        Test.stopTest();
    }
}