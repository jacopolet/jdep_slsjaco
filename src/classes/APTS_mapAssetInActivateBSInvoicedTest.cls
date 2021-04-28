@isTest 
private class APTS_mapAssetInActivateBSInvoicedTest {


    @testSetup
    private static void testDataSetup() {

        //insert custom settings
        TriggerSettings__c objTriggerSettings = new TriggerSettings__c();
        objTriggerSettings.Agreement__c = false;
        objTriggerSettings.AssetLineItemTrigger__c = false;
        objTriggerSettings.APTS_Configuration_Trigger__c = false;
        insert objTriggerSettings;
 
        
        Apttus_Config2__Order__c orderobj = new Apttus_Config2__Order__c(); 
        insert orderobj;
        Apttus_Config2__AssetLineItem__c astlineitmp1 = new Apttus_Config2__AssetLineItem__c();
        astlineitmp1.Name ='Parent'; 
        astlineitmp1.Apttus_Config2__BillingFrequency__c = 'Quarterly';
        astlineitmp1.Apttus_Config2__BillThroughDate__c = system.today();
        insert astlineitmp1;
        Apttus_Config2__AssetLineItem__c astlineitmp2 = new Apttus_Config2__AssetLineItem__c();
        astlineitmp2.Name ='Parent'; 
        astlineitmp2.Apttus_Config2__BillingFrequency__c = 'Yearly';
        astlineitmp2.Apttus_Config2__BillThroughDate__c = system.today();
        insert astlineitmp2;
        Apttus_Config2__AssetLineItem__c astlineitmp = new Apttus_Config2__AssetLineItem__c();
        astlineitmp.Name ='Parent'; 
        astlineitmp.Apttus_Config2__ParentAssetId__c = astlineitmp1.Id;
        astlineitmp.Apttus_Config2__BundleAssetId__c = astlineitmp1.Id;
        astlineitmp.Apttus_Config2__BillThroughDate__c = system.today();
        astlineitmp.Apttus_Config2__BillingFrequency__c = 'Half Yearly';
        insert astlineitmp;
        Apttus_Config2__AssetLineItem__c astlineitm = new Apttus_Config2__AssetLineItem__c();
        astlineitm.Name ='Test';
        astlineitm.Apttus_Config2__ParentAssetId__c = astlineitmp.Id;
        astlineitm.Apttus_Config2__BundleAssetId__c = astlineitmp.Id;
        astlineitm.Apttus_Config2__BillThroughDate__c = system.today();
        astlineitm.Apttus_Config2__BillingFrequency__c = 'Monthly';
        insert astlineitm;
        
        Apttus_Config2__AssetAttributeValue__c Attribute = new Apttus_Config2__AssetAttributeValue__c(); 
        Attribute.Apttus_Config2__AssetLineItemId__c = astlineitm.id;
        insert Attribute;
        Apttus_Config2__OrderLineItem__c orderltobj = new Apttus_Config2__OrderLineItem__c(); 
        orderltobj.Apttus_Config2__OrderId__c = orderobj.id;
        orderltobj.Apttus_Config2__AssetLineItemId__c = astlineitmp.id;
        orderltobj.APTS_Migrated_Asset_Line_Item__c = astlineitm.id; 
        
        insert orderltobj;  
        
        Apttus_Config2_AssetAdjustItem__c aca = new Apttus_Config2_AssetAdjustItem__c();
        aca.Apttus_Config2_AssetLineItemId__c = orderltobj.APTS_Migrated_Asset_Line_Item__c;
        insert aca;
        
        APTS_CounterReadingData__c acr = new APTS_CounterReadingData__c();
        acr.APTS_Asset_Line_Item__c = orderltobj.APTS_Migrated_Asset_Line_Item__c;
        insert acr;
        
        Apttus_Billing__BillingSchedule__c billingsch = new Apttus_Billing__BillingSchedule__c();
        billingsch.Apttus_Billing__AssetLineItemId__c = astlineitmp1.id;
        billingsch.Apttus_Billing__ReadyForInvoiceDate__c = system.today().addmonths(-3); 
        insert billingsch;
        
        Apttus_Billing__BillingSchedule__c billingsch1 = new Apttus_Billing__BillingSchedule__c();
        billingsch1.Apttus_Billing__AssetLineItemId__c = astlineitmp2.id;
        billingsch1.Apttus_Billing__ReadyForInvoiceDate__c = system.today().addmonths(-3); 
        insert billingsch1;
        
        Apttus_Billing__BillingSchedule__c billingsch2 = new Apttus_Billing__BillingSchedule__c();
        billingsch2.Apttus_Billing__AssetLineItemId__c = astlineitm.id;
        billingsch2.Apttus_Billing__ReadyForInvoiceDate__c = system.today().addmonths(-3); 
        insert billingsch2;
        
        Apttus_Billing__BillingSchedule__c billingsch3 = new Apttus_Billing__BillingSchedule__c();
        billingsch3.Apttus_Billing__AssetLineItemId__c = astlineitmp.id;
        billingsch3.Apttus_Billing__ReadyForInvoiceDate__c = system.today().addmonths(-3); 
        insert billingsch3;
    }
    
    @isTest
    private static void mapAssetAttributeTest() {
        APTS_Batch_Jobs__mdt currentInput = (APTS_Batch_Jobs__mdt) JSON.deserialize(' { "APTS_Batch_Class_Name__c": "APTS_MapAssetAttributeBatchHelper", "APTS_Batch_Size__c": 1, "APTS_Control__c": false, "APTS_Is_Active__c": false, "APTS_Next_Jobs__c": "B_0003", "APTS_Primary__c": true, "APTS_Query__c": "SELECT Id, APTS_Migrated_Asset_Line_Item__r.Apttus_Config2__ParentAssetId__c,APTS_Migrated_Asset_Line_Item__c,APTS_Migrated_Asset_Line_Item__r.Apttus_Config2__BundleAssetId__c,Apttus_Config2__AssetLineItemId__c FROM Apttus_Config2__OrderLineItem__c", "APTS_Triggers_to_Disable__c": "Agreement__c,AssetLineItemTrigger__c,APTS_Configuration_Trigger__c,TaskTrigger__c,APTS_AgreementLineItemTrigger__c", "DeveloperName": "B_0002", "Id": "m0F4E0000004G47UAE", "Label": "APTS_LineItemsPricingBatchHelper", "MasterLabel": "APTS_LineItemsPricingBatchHelper", "QualifiedApiName": "B_0002" }', APTS_Batch_Jobs__mdt.class);
        system.debug('**'+currentInput);
        APTS_CommonBatch batch = new APTS_CommonBatch(currentInput,'BEC');
        Database.Executebatch(batch,Integer.valueOf(currentInput.APTS_Batch_Size__c));
    }
    
    @isTest
    private static void inActivateAssetLineItemsTest() {
        APTS_Batch_Jobs__mdt currentInput = (APTS_Batch_Jobs__mdt) JSON.deserialize(' { "APTS_Batch_Class_Name__c": "APTS_InActivateAssetLineItemsBatchHelper", "APTS_Batch_Size__c": 1, "APTS_Control__c": false, "APTS_Is_Active__c": false, "APTS_Next_Jobs__c": "B_0003", "APTS_Primary__c": true, "APTS_Query__c": "SELECT Id, APTS_Migrated_Asset_Line_Item__r.Apttus_Config2__ParentAssetId__c,APTS_Migrated_Asset_Line_Item__c,APTS_Migrated_Asset_Line_Item__r.Apttus_Config2__BundleAssetId__c,Apttus_Config2__AssetLineItemId__c FROM Apttus_Config2__OrderLineItem__c", "APTS_Triggers_to_Disable__c": "Agreement__c,AssetLineItemTrigger__c,APTS_Configuration_Trigger__c,TaskTrigger__c,APTS_AgreementLineItemTrigger__c", "DeveloperName": "B_0002", "Id": "m0F4E0000004G47UAE", "Label": "APTS_LineItemsPricingBatchHelper", "MasterLabel": "APTS_LineItemsPricingBatchHelper", "QualifiedApiName": "B_0002" }', APTS_Batch_Jobs__mdt.class);
        system.debug('**'+currentInput);
        APTS_CommonBatch batch = new APTS_CommonBatch(currentInput,'BEC');
        Database.Executebatch(batch,Integer.valueOf(currentInput.APTS_Batch_Size__c));
    } 
    
    @isTest
    private static void billingScheduleInvoicedTest() {
        APTS_Batch_Jobs__mdt currentInput = (APTS_Batch_Jobs__mdt) JSON.deserialize(' { "APTS_Batch_Class_Name__c": "APTS_BillingScheduleInvoicedBatchHelper", "APTS_Batch_Size__c": 5, "APTS_Control__c": false, "APTS_Is_Active__c": false, "APTS_Next_Jobs__c": "B_0003", "APTS_Primary__c": true, "APTS_Query__c": "Select Id,Apttus_Billing__HideInvoiceDisplay__c,Apttus_Billing__ReadyForInvoiceDate__c,Apttus_Billing__Status__c,Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillingFrequency__c,Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillThroughDate__c From Apttus_Billing__BillingSchedule__c Where (Apttus_Billing__Status__c !=\'Invoiced\' OR Apttus_Billing__HideInvoiceDisplay__c = False) AND Apttus_Billing__ReadyForInvoiceDate__c != null AND Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillThroughDate__c != null", "APTS_Triggers_to_Disable__c": "Agreement__c,AssetLineItemTrigger__c,APTS_Configuration_Trigger__c,TaskTrigger__c,APTS_AgreementLineItemTrigger__c", "DeveloperName": "B_0002", "Id": "m0F4E0000004G47UAE", "Label": "APTS_LineItemsPricingBatchHelper", "MasterLabel": "APTS_LineItemsPricingBatchHelper", "QualifiedApiName": "B_0002" }', APTS_Batch_Jobs__mdt.class);
        system.debug('**'+currentInput);
        APTS_CommonBatch batch = new APTS_CommonBatch(currentInput,'BEC');
        Database.Executebatch(batch,Integer.valueOf(currentInput.APTS_Batch_Size__c));
    }
}