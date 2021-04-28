/**
* @author        Karen Hung
* @date          04.02.2020
* @description   Test class used for  TS_CancelRouteTasks_Batch
* @revision(s)   
*                
*/
@isTest
private class TS_CancelRouteTasks_Batch_Test {
    
    static Account acct;
    static Contact con;
    static Case c;
    static WorkOrder wo;
    static Apttus_Config2__AssetLineItem__c ali;
    static Apttus_Config2__Order__c order;
    static Apttus_Config2__OrderLineItem__c oli;
    static WorkOrderLineItem woli;
    static Resource__c engr;
    
    /*setup testdata*/
    @testSetup
    static void createData() {
		acct = new Account(Name='Account', Phone='+31302979111');
        insert acct;
        
        con = TS_TestDataFactory.createContact();  
        con.Preferred_Language__c = 'SAP_EN';
        Insert con;
        
        c = TS_TestDataFactory.createFieldServiceCase();
        c.ContactId = con.Id;
        c.PO_Number__c = '123456';
        c.SalesOrganization__c= 'SAP_0333';//Click__c = true;//added may 2018
        insert c;
        
        wo = TS_TestDataFactory.createWorkOrder();
        wo.CaseId = c.Id;
        wo.WorkOrderType__c = 'S20';
        wo.ContactId = con.Id;
        wo.SalesOrganization__c = 'SAP_0111';
        wo.Status ='Open';
        wo.RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('WorkOrder', 'Operating (Route) Work Order');
        wo.SLA_Date__c = datetime.now();
        insert wo;
        
        WorkOrder wo2 = new WorkOrder();
        wo2 = TS_TestDataFactory.createWorkOrder();
        wo2.WorkOrderType__c = 'S20';
        wo2.ContactId = con.Id;
        wo2.SalesOrganization__c = 'SAP_0111';
        wo2.Status ='Open';
        wo2.RecordTypeId = TS_UtilityClass.getRecordTypeIdByName('WorkOrder', 'Operating (Route) Work Order');
        wo2.SLA_Date__c = datetime.now();
        insert wo2;
        
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
        engr.Sales_Organization__c = 'SAP_0111';
        engr.SAPStorageLocation__c ='3q432';
        insert engr;
        
        String recordTypeId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get(TS_Constants.TS_WOLI_RECORDTYPE_OPERATINGTASK).getRecordTypeId();
        woli = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);         
        woli.Case__c = c.Id;
        woli.WorkOrderType__c= 'S20'; 
        woli.RecordTypeId= recordTypeId;
        woli.Status = TS_Constants.WOLI_STATUS_OPEN;
        woli.AssetLineItem__c = ali.Id;
        woli.OrderLineItem__c = oli.Id;
        woli.isFromRoute__c = true;
        woli.SLADate__c = DateTime.now();
        woli.SendCounterReadingsOperating__c = true;
        insert woli;
    }
        
    /*test batch*/
    static testMethod void testCancelBatch() {
        User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(usr) {
            Test.startTest();            
            Id result = Database.executeBatch(new TS_CancelRouteTasks_Batch());
            Test.stopTest();
            System.assert(result != null);
        }
    }
    /*test batch*/
    static testMethod void testCancelBatchEx() {
        User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(usr) {
            Test.startTest();
            TS_CancelRouteTasks_Batch.hasException = true;
            Id result = Database.executeBatch(new TS_CancelRouteTasks_Batch());
            Test.stopTest();
            System.assert(result != null);
        }
    }

}