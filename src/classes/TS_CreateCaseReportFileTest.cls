/**
* @author        Rey Austral
* @date          9.29.2017           
* @description   Test Class for TS_CreateCaseReportFile
* @revision(s)
*/
@isTest
private class TS_CreateCaseReportFileTest {
    @isTest static void test_execute() {
        Contact con = TS_TestDataFactory.createContact();  
        con.Preferred_Language__c = 'SAP_EN';
        Insert con;
        
        Case cse = TS_TestDataFactory.createFieldServiceCase();
        cse.ContactId = con.Id;
        cse.RequiresCostEstimate__c = true;
        insert cse;
        
        WorkOrder parentWO = TS_TestDataFactory.createWorkOrder();
        parentWO.ContactId = con.Id;
        parentWO.CaseId = cse.Id;
        parentWO.WorkOrderType__c = Label.TS_Case_SubType_CorrectMaint;
        insert parentWO;
        
        Resource__c testResource = TS_TestDataFactory.createResourceSingle('Test Resource Number');
        insert testResource;
        
        WorkOrderLineItem woliParent = TS_TestDataFactory.createWorkOrderLineItem(parentWO.Id);
        woliParent.ExecutingEngineer__c = testResource.Id;
        woliParent.Status = Label.TS_WOLI_Status_Completed;
        woliParent.InternalOrderSAP__c = '123';  
        woliParent.WorkOrderLineItemType__c = Label.TS_Type_Task;   
        woliParent.Case__c = cse.Id;
        woliParent.WorkOrderId = parentWO.Id;
        
        insert woliParent;
        
        List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
        WorkOrderLineItem serviceMaterial = TS_TestDataFactory.createWorkOrderLineItem(parentWO.Id);         
        serviceMaterial.Status = Label.TS_WOLI_Status_Completed;       
        serviceMaterial.WorkOrderLineItemType__c = Label.TS_Type_Service;   
        serviceMaterial.Case__c = cse.Id;
        serviceMaterial.ParentWorkOrderLineItemId = woliParent.Id;         
        woliList.add(serviceMaterial);
        
        WorkOrderLineItem dummy = TS_TestDataFactory.createWorkOrderLineItem(parentWO.Id);         
        dummy.Status = Label.TS_WOLI_Status_Completed;       
        dummy.WorkOrderLineItemType__c = Label.TS_Type_Service;   
        dummy.Case__c = cse.Id;
        dummy.ParentWorkOrderLineItemId = woliParent.Id;         
        dummy.IsReadyToSummarize__c = true;
        woliList.add(dummy);
        
        
        insert woliList;
        
        Map<Id, Boolean> requireEstimateMap = new Map<Id, Boolean>{dummy.Id=>true, serviceMaterial.Id=>true, woliParent.Id=>true};//
        Set<Id> parentWOLI = new Set<Id>{woliParent.Id};//
                
        Test.startTest();
        TS_CreateCaseReportFile_2 ccrp = new TS_CreateCaseReportFile_2();
        ccrp.newList = woliList;         
        ccrp.requireEstimateMap = requireEstimateMap;//
        ccrp.parentWOLI = parentWOLI;//
        ccrp.isSalesOrder = false;//
        System.enqueueJob(ccrp);
        
        TS_CreateCaseReportFile_2 ccrp2 = new TS_CreateCaseReportFile_2();
        ccrp2.parentWOLI = new Set<Id>();//
        ccrp2.isSalesOrder = true;//
        ccrp2.caseIdSet = new Set<Id>{cse.Id};
        System.enqueueJob(ccrp2);
        System.assert(ccrp2 != null);
        Test.stopTest();
        
        List<ContentDistribution> cdList = [Select Id from ContentDistribution];
        List<ContentVersion> cdlList = [Select Id from ContentVersion];
    }
}