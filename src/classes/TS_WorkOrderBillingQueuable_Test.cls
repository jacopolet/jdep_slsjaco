//-------------------------------------------------------------------------------------------//
// Author       :   Abram Vixen Reyes
// Created Date :   Sept 26, 2018
// Usage        :   Test Class for TS_WorkOrderBillingQueuable
//-------------------------------------------------------------------------------------------//

@isTest
public class TS_WorkOrderBillingQueuable_Test {
	
	static Account acct;
    static Contact con;
    static Case c;
    static WorkOrder wo;
	static WorkOrderLineItem woli;
	static PricebookEntry standardPrice;
	static Product2 prod;

    static void setupTestData() {
        prod = new Product2(Name = 'Laptop X200', Family = 'Hardware');
        insert prod;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        standardPrice = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prod.Id, UnitPrice = 10000, IsActive = true);
        insert standardPrice;

        acct = new Account(Name='Account', Phone='+31302979111');
        insert acct;
        
        con = TS_TestDataFactory.createContact();  
        con.Preferred_Language__c = 'SAP_EN';
        Insert con;
        
        c = TS_TestDataFactory.createFieldServiceCase();
        c.ContactId = con.Id;
        insert c;
        
        wo = TS_TestDataFactory.createWorkOrder();
        wo.CaseId = c.Id;
        wo.WorkOrderType__c = Label.TS_Case_SubType_CorrectMaint;
        wo.ContactId = con.Id;
        wo.Pricebook2Id = pricebookId;
        insert wo;
        
        Resource__c engr = new Resource__c();
        engr.Name = 'Test Engr';
        engr.Sales_Organization__c = 'SAP_0333';
        engr.SAPStorageLocation__c ='xxxx';
        engr.CompanyCode__c ='0607';
        insert engr;
        
        CountrySetting__c cs = new CountrySetting__c();
        cs.RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c','Country Purchasing Settings');
        cs.Name = '0607 Company Code';
        cs.Company_Code__c = '0607';
        cs.Active__c = true;
        insert cs;
        
        woli = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);         
        woli.Case__c = c.Id;
        woli.WorkOrderLineItemType__c = Label.TS_Type_Task;
        woli.WorkOrderType__c = 'S10'; //
        woli.EndDate__c = DateTime.now();
        woli.PricebookEntryId = standardPrice.id;
        woli.ExecutingEngineer__c = engr.Id;
    }

    static testmethod void testInsertDummyServiceMaterial() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(u) {
       		setupTestData();

        	insert woli;
        	
        	woli.Status = 'Completed';
            woli.CompletionCode__c = '100';
            woli.DefectCode__c = 'T01';
            woli.FaultLocationCategory__c = 'D';
            woli.FaultCode__c = 'D01';
            woli.StartDate__c = System.now();
            woli.EndDate__c = System.now().addDays(1);
            woli.InternalCompletionNote__c = 'Test';
            
            //Insert Parts
            WorkOrderLineItem wo_used = new WorkOrderLineItem();
            wo_used.Status = 'Completed';
            wo_used.WorkOrderLineItemType__c = TS_Constants.TYPE_API_USEDPARTS;
            wo_used.Part_used_from_own_storage_location__c = true;
            wo_used.ParentWorkOrderLineItemId = woli.Id;
            wo_used.WorkOrderId = wo.Id;
            insert wo_used;
            
            WorkOrderLineItem wo_missing = new WorkOrderLineItem();
            wo_missing.WorkOrderLineItemType__c = TS_Constants.WOLI_STATUS_MISSING;
            wo_missing.ParentWorkOrderLineItemId = woli.Id;
            wo_missing.WorkOrderId = wo.Id;
            insert wo_missing;
            
            update woli;

            Test.startTest();
                TS_CloseTaskWOLIController.insertDummyServiceMaterial(wo.Id, c.Id, woli.Id, false);
                List<WorkOrderLineItem> woliDummy = [SELECT id, IsReadyToSummarize__c, Status, RecordType.DeveloperName, ParentWorkOrderLineItemId, LastModifiedById, CreatedById,Createdby.Name, InternalOrderSAP__c FROM WorkOrderLineItem WHERE IsReadyToSummarize__c = true];
                
                TS_WorkOrderBillingQueuable cse = new TS_WorkOrderBillingQueuable();
                cse.newList = woliDummy;
                cse.parentWOLI = new Set<Id>{woliDummy[0].ParentWorkOrderLineItemId};
                System.enqueueJob(cse);
            
            Test.stopTest();
        }
    }


}