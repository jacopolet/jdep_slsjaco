/**
* @author        Rey Austral
* @date          10.13.2017           
* @description   Test Class for TS_WorkOrderDocumentController
* @revision(s)
*/
@isTest
private class TS_WorkOrderDocumentControllerTest {
	
	@isTest static void test_initializeComponent() {
		Contact con = TS_TestDataFactory.createContact();  
        con.Preferred_Language__c = 'SAP_EN';
        Insert con;

        Case cse = TS_TestDataFactory.createFieldServiceCase();
        cse.ContactId = con.Id;
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
         serviceMaterial.EstimateMaterialCost__c = '100';   
         woliList.add(serviceMaterial);

         WorkOrderLineItem usedSpareParts = TS_TestDataFactory.createWorkOrderLineItem(parentWO.Id);         
         usedSpareParts.Status = Label.TS_WOLI_Status_Completed;       
         usedSpareParts.WorkOrderLineItemType__c = 'UsedSpareParts';   
         usedSpareParts.Case__c = cse.Id;
         usedSpareParts.ParentWorkOrderLineItemId = woliParent.Id;   
         usedSpareParts.EstimatePartCost__c = '100';
         woliList.add(usedSpareParts);

         insert woliList;

         TS_WorkOrderDocumentController controller = new TS_WorkOrderDocumentController();
         Test.startTest();
         controller.woliRecordId = woliParent.Id;
         controller.isSalesOrder = true; //
         controller.labourRecord = serviceMaterial; //
         controller.signature = null;//
         controller.quotesignature = null;
         Test.stopTest();
         System.assertEquals(2, controller.childWOLI.size());

	}
	
}