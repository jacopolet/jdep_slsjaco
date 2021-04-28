/**
* @author        Harold Marilag
* @date          8.2.2017           
* @description   Test class for SignatureLayoutController
* @revision(s)
*/
@isTest
private class SignatureLayoutController_Test {
    
    @testSetup
    static void dataSetup() {
        //Custom settings is being shared by all test class, if another test class has already inserted the record 
        //this test class will throw "UNABLE_TO_LOCK_ROW, unable to obtain exclusive access to this record"
        try {
            TriggerSettings__c trg = TriggerSettings__c.getOrgDefaults();
            trg.WorkOrderTrigger__c = true;
            trg.WorkOrderLineItemTrigger__c = true;
            upsert trg;      
            system.debug('trg is:'+trg);
        } catch(Exception ex) {
            system.debug(ex);
        }

         try {
            IntegrationTriggerSettings__c trg1 = IntegrationTriggerSettings__c.getOrgDefaults();
            trg1.IntegrationLogTrigger__c = true;
            upsert trg1; 
        } catch(Exception ex) {
            system.debug(ex);
        }

        ProcessBuilderSettings__c pb = new ProcessBuilderSettings__c();
        pb.WorkOrderPBFlows__c = true;
        pb.CasePBFlows__c = true;
        insert pb;
    }
    
    private static testMethod void testSignatureLayoutController(){
        
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
         woliParent.Status = Label.TS_Status_CompleteD;
         woliParent.InternalOrderSAP__c = '123';  
         woliParent.WorkOrderLineItemType__c = Label.TS_Type_Task;   
         woliParent.Case__c = cse.Id;
         insert woliParent;
            

         test.startTest();
         List<WorkOrderLineItem> woliInsert = new List<WorkOrderLineItem>();
         //create I/O
         WorkOrderLineItem woliChild = TS_TestDataFactory.createWorkOrderLineItem(parentWO.Id);
         woliChild.ExecutingEngineer__c = testResource.Id;
         woliChild.ParentWorkOrderLineItemId = woliParent.Id;
         woliChild.WorkOrderLineItemType__c = Label.TS_Type_Task;         
         woliChild.Case__c = cse.Id;
         woliInsert.add(woliChild);

         //create cats
         WorkOrderLineItem woliChildCATS = TS_TestDataFactory.createWorkOrderLineItem(parentWO.Id);
         woliChildCATS.ExecutingEngineer__c = testResource.Id;
         woliChildCATS.ParentWorkOrderLineItemId = woliParent.Id;
         woliChildCATS.WorkOrderLineItemType__c = 'UsedSpareParts';
         woliChildCATS.InternalOrderSAP__c = '123';
         woliChildCATS.Status = Label.TS_Status_CompleteD;       
         woliChildCATS.ActualTravelTime__c  = 2;
         woliChildCATS.EstimatePartCost__c = '100';
         woliChildCATS.WorkQuarters__c =  'test';
         woliChildCATS.Case__c = cse.Id;
         woliInsert.add( woliChildCATS );

         //create goods movement
         WorkOrderLineItem woliChildGoods = TS_TestDataFactory.createWorkOrderLineItem(parentWO.Id);
         woliChildGoods.ExecutingEngineer__c = testResource.Id;
         woliChildGoods.ParentWorkOrderLineItemId = woliParent.Id; 
         woliChildGoods.WorkOrderLineItemType__c = 'Service Materials'; 
         woliChildGoods.EstimateMaterialCost__c = '100';
         woliChildGoods.Case__c = cse.Id;
         woliInsert.add( woliChildGoods );

         Insert woliInsert;
         test.stopTest();
        
        List<Attachment> aList = new List<Attachment>();
        Attachment a = new Attachment();
        a.Name = 'Signature';
        a.Body = Blob.valueOf('Test Blob');
        a.ParentId = woliParent.Id;
        aList.add(a);
        Attachment a2 = new Attachment();
        a2.Name = 'Quote_Signature';
        a2.Body = Blob.valueOf('Test Blob');
        a2.ParentId = woliParent.Id;
        aList.add(a2);
        insert aList;

        ApexPages.StandardController stdController = new ApexPages.StandardController(woliParent); 
        
        SignatureLayoutController closeTask = new SignatureLayoutController(stdController); 

        System.assert(closeTask != null);     
    }
}