/*
* @author        Karen Hung
* @date          17.5.2019          
* @description   Test class for TS_LargeCounterReadingQueueable
* @revision(s)
*/
@isTest
public class TS_LargeCounterReadingQueueable_Test{
    static Account acct;
    static Contact con;
    static Case c;
    static WorkOrder wo;
    static Apttus_Config2__AssetLineItem__c ali;
    static Apttus_Config2__Order__c order;
    static Apttus_Config2__OrderLineItem__c oli;
    static WorkOrderLineItem woli;
    static Resource__c engr;
    static PhysicalAsset__c pAsset;
    static Apttus_Config2__AccountLocation__c accLoc;

    static String woRecTypeCReading = TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_WorkOrder, Label.TS_CounterReading);
    static String woRecTypeOperating = TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_WorkOrder, Label.TS_OperatingWorkOrder);
    static String woliRecTypeCReading = TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_WOLI, Label.TS_CounterReadingTask);
    static String woliRecTypeOperating = TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_WOLI, Label.TS_OperatingTaskRecordType);

    /**
    * @author        Karen Hung
    * @date          17.5.2019             
    * @description   Method responsible for creating custom setting records
    * @revision(s)
    */
    @testSetup
    static void dataSetup() {
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
    
    /**
    * @author        Karen Hung
    * @date          17.5.2019           
    * @description   Method responsible for creating test data
    * @revision(s)
    */
    static void setupTestData() {
        acct = new Account(Name='Account', Phone='+31302979111');
        //acct.Segment__c = 'SAP_A';
        //acct.High_Segment__c = 'Business';
        insert acct;
        
        con = TS_TestDataFactory.createContact();  
        con.Preferred_Language__c = 'SAP_EN';
        Insert con;
        
        accLoc = TS_TestDataFactory.createAccountLocationTest('123456753', acct.Id);
        accLoc.Apttus_Config2__AccountId__c = acct.Id;
        insert accLoc;
        
        pAsset = TS_TestDataFactory.createPhysicalAsset();
        insert pAsset;
        
        c = TS_TestDataFactory.createFieldServiceCase();
        c.ContactId = con.Id;
        c.AccountId = acct.Id;
        c.PO_Number__c = '123456';
        c.SalesOrganization__c= 'SAP_0333';//Click__c = true;//added may 2018
        insert c;
        
        wo = TS_TestDataFactory.createWorkOrder();
        wo.CaseId = c.Id;
        wo.WorkOrderType__c = Label.TS_Case_SubType_CorrectMaint;
        wo.ContactId = con.Id;
        insert wo;
        
        ali = TS_TestDataFactory.createAssetLineItem();
        ali.Name = Label.TS_Assetlinitem_PrevMain;
        ali.Apttus_Config2__IsPrimaryLine__c = true;
        ali.Apttus_Config2__AssetStatus__c = 'Activated';
        ali.Apttus_Config2__AccountId__c = acct.Id;
        ali.Apttus_Config2__BillToAccountId__c = acct.Id;
        insert ali;
        
        order = TS_TestDataFactory.createOrderRecord('Draft', 'New');
        order.Apttus_Config2__ShipToAccountId__c = acct.Id;
        order.Apttus_Config2__SoldToAccountId__c = acct.Id;
        order.Apttus_Config2__BillToAccountId__c = acct.Id;
        insert order;
        
        oli = new Apttus_Config2__OrderLineItem__c();
        oli.Apttus_Config2__OrderId__c = order.Id;
        oli.Apttus_Config2__Quantity__c = 1.0;
        oli.Apttus_Config2__AssetLineItemId__c = ali.Id;
        insert oli;
        
        engr = new Resource__c();
        engr.Name = '1232343434';
        engr.Sales_Organization__c = 'SAP_0333';
        engr.SAPStorageLocation__c ='3q432';
        //engr.RelatedUser__c = TS_TestDataFactory.createUser('JDE - END USER - STC COMMUNITY EXTERNAL').Id;
        insert engr;
        
        woli = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);         
        woli.Case__c = c.Id;
        woli.PhysicalAsset__c = pAsset.Id;
        woli.WorkOrderLineItemType__c = Label.TS_Type_Task;
        woli.AssetLineItem__c = ali.Id;
        woli.AccountLocation__c = accLoc.Id;
        woli.OrderLineItem__c = oli.Id;
        woli.EndDate__c = DateTime.now();
    
    }

    /**
    * @author        Karen Hung
    * @date          10.29.2018           
    * @description   
    * @revision(s)
    */
    static testMethod void TEST_execute () {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {  
            setupTestData();          
           
            Test.startTest();
                        
            //INSERT LARGE TASK
            woli.WorkOrderType__c = 'S20';
            woli.WorkOrderLineItemType__c = 'Large';
            insert woli;
            
            woli.ExecutingEngineer__c = engr.id;
            woli.InternalOrderSAP__c = '12345678913';
            woli.Status = Label.TS_WOLI_Status_Scheduled;
            update woli;
                     
            woli.SendCounterReadingsOperating__c = true;
            woli.Status = 'Completed';
            woli.OP_CreateParent__c = true;
            update woli;
            
            WorkOrderLineItem woliCounter = new WorkOrderLineItem();
            woliCounter.WorkOrderId = wo.Id;
            woliCounter.OP_CreateParent__c = true;
            woliCounter.ParentWorkOrderLineItemId = woli.Id;
            insert woliCounter; 
            
            woliCounter.Status = 'Completed';
            woliCounter.WorkOrderType__c = 'Large';
            woliCounter.SendCounterReadingsOperating__c = true;
            woliCounter.AccountLocation__c=accLoc.id;
            woliCounter.ExecutingEngineer__c = engr.id;
            woliCounter.RelateTo__c = woli.Id;
            woliCounter.RecordTypeId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Counter Reading Task').getRecordTypeId();
            update woliCounter;
            
            
            List<WorkOrderLineItem> CR_WOLI_LIST = new List<WorkOrderLineItem>{woliCounter};
			Map<Id, List<WorkOrderLineItem>> WORKORDER_COUNTEREADING_MAP = new Map<Id,List<WorkOrderLineItem>>();
            WORKORDER_COUNTEREADING_MAP.put(woli.id,CR_WOLI_LIST);
            
            TS_LargeCounterReadingQueueable LARGE_QUEUEABLE = new TS_LargeCounterReadingQueueable();
            LARGE_QUEUEABLE.CR_WOLI_LIST = CR_WOLI_LIST;
            LARGE_QUEUEABLE.WORKORDER_COUNTEREADING_MAP = WORKORDER_COUNTEREADING_MAP;
            System.enqueueJob(LARGE_QUEUEABLE);
            
            Test.stopTest();

            System.assert(woli !=null);
            
        }
    }
    
}