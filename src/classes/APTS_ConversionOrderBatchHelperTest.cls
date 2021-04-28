/******************************************************
Name: APTS_ConversionOrderBatchHelperTest
Date: 25th Aug 2020
Desciption: Test Class for APTS_CreateConversionOrderBatchHelper , APTS_RepriceFinalizeConvOrdBatchHelper, APTS_ActivateConversionOrderBatchHelper
Author: Sai Sagar
Change Verison History: 
********************************************************/
@isTest
public with sharing class APTS_ConversionOrderBatchHelperTest {
    public static Account grandParent = new Account();
    public static Account parentAccount= new Account();
    public static Account childAccount= new Account();
    public static List<Account> accounts = new List<Account>();
    @testSetup
    private static void testDataSetup() {

         //insert custom settings
        TriggerSettings__c objTriggerSettings = new TriggerSettings__c();
        objTriggerSettings.Agreement__c = false;
        objTriggerSettings.AssetLineItemTrigger__c = false;
        objTriggerSettings.APTS_Configuration_Trigger__c = false;
        insert objTriggerSettings;

        Apttus_Billing__BillingSystemProperties__c syspropty = new Apttus_Billing__BillingSystemProperties__c();
        syspropty.Name = 'System Properties';
        syspropty.Apttus_Billing__CreateRedundantBillingSchedules__c = true;
        syspropty.Apttus_Billing__AllowBillingPreferenceOverride__c = true;
        insert syspropty;
        
        Product2 product =APTS_TestUtils.createProduct('Piazza DOro Estremo Bonen 1000 Gram','26940998','Espresso');
        insert product;

        
        Apttus_Config2__BillingPreference__c billingPreference = new Apttus_Config2__BillingPreference__c();
                billingPreference.Name = 'BillingPreference';
                billingPreference.Apttus_Config2__Active__c = True;
                billingPreference.Apttus_Config2__DoNotCreateInformational__c  = true;
                billingPreference.Apttus_Config2__BillingCycleStart__c = 'Billing Day of Month';
                billingPreference.Apttus_Config2__BillingDayOfMonth2__c = '1st of the Month';
                billingPreference.Apttus_Config2__BillingInterval__c = 'Anytime ';
                billingPreference.Apttus_Config2__CalendarCycleStart__c = ' Account Calendar Cycle Start'; 
        insert billingPreference;
        
               
        Apttus_Config2__PriceList__c priceList = new  Apttus_Config2__PriceList__c();
                priceList.Name =  'Belgium General Pricelist - EUR';
                priceList.Apttus_Config2__Active__c = true;
                priceList.APTS_SalesOrg__c = 'SalesOrg';
              
        insert priceList;
         Apttus_Config2__PriceList__c priceList1 = new  Apttus_Config2__PriceList__c();
                priceList1.Name =  'Belgium General Pricelist - EUR';
                priceList1.Apttus_Config2__Active__c = true;
                priceList1.APTS_SalesOrg__c = 'SalesOrg'; 
        insert priceList1;  
        
        
        Apttus_Config2__PriceListItem__c priceListItem = APTS_TestUtils.createPriceListItem(priceList.id,product.id);
        insert priceListItem; 
                grandParent.Name = 'Grand Parent Account';
                grandParent.Phone = '+2222222222';
                grandParent.Main_Street_Only__c = 'Test Street';
                grandParent.Main_House_Number__c = 'Test no.';
                grandParent.billingcountry = 'Netherlands';
         insert grandParent;
        
        
        
                parentAccount.Apttus_Config2__BillingPreferenceId__c = billingPreference.Id;
                parentAccount.Name = 'Parent Account';
                parentAccount.Phone = '+919898468401';
                parentAccount.Main_Street_Only__c = 'Test Street';
                parentAccount.Main_House_Number__c = 'Test no.';
                parentAccount.Parent = grandParent;
                parentAccount.ParentId = grandParent.Id;
        insert  parentAccount;   
        
         
                 childAccount.Name = 'Child Account';
                 childAccount.Phone = '+919898468401';
                 childAccount.Main_Street_Only__c = 'Test Street';
                 childAccount.Main_House_Number__c = 'Test no.';
                 childAccount.Parent = parentAccount;
                 childAccount.ParentId = parentAccount.Id;
               
        insert childAccount;
        
        
       accounts.add(grandParent);
       accounts.add(parentAccount);
       accounts.add(childAccount);
      
       Apttus__APTS_Agreement__c agreementRec = new Apttus__APTS_Agreement__c(recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId(),
                Name = 'Test Agreement',
                Apttus__Agreement_Category__c = 'Standard',
                Apttus_CMConfig__PriceListId__c = priceList.Id,
                Apttus__Account__c = parentAccount.Id);
      insert agreementRec;
        
        PhysicalAsset__c physicalAsset =  new   PhysicalAsset__c(recordtypeid = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get('Machine').getRecordTypeId(),
               Name = 'Physical Asset',
               Product__c=product.Id,
               AssetStatus__c = 'Activated',
               SerialNumber__c = 'ABCTest');
        insert physicalAsset; 
        
         Apttus_Config2__Order__c orderobj = new Apttus_Config2__Order__c( 
         APTS_Order_Type__c = 'Admin Order',
                            APTS_Order_Sub_Type__c = 'Conversion Order',
                            Apttus_Config2__PriceListId__c = priceList.Id,
                            Apttus_Config2__BillingPreferenceId__c = parentAccount.Apttus_Config2__BillingPreferenceId__c,
                            Apttus_Config2__BillToAccountId__c = parentAccount.Id,
                            Apttus_Config2__ShipToAccountId__c = parentAccount.Id,
                            Apttus_Config2__SoldToAccountId__c = parentAccount.Id,
                            Apttus_Config2__Source__c = 'Account',
                            Apttus_Config2__OrderStartDate__c = Date.today(),
                            Apttus_Config2__OrderEndDate__c = Date.today().addDays(30),
                            Apttus_Config2__OrderDate__c = Date.today(),
                            Apttus_Config2__Status__c = 'Draft');
        insert orderobj;
    
        Apttus_Config2__AssetLineItem__c parentAssetLineItem1 = new Apttus_Config2__AssetLineItem__c(Name = 'Parent Asset Line Item',
               Apttus_CMConfig__AgreementId__c = agreementRec.id,
               Apttus_Config2__AssetStatus__c= 'New',
               Apttus_Config2__LineNumber__c = 1,
               APTS_Physical_Asset__c = physicalAsset.Id,
               Apttus_Config2__ProductId__c = product.Id,
               Apttus_Config2__PriceListId__c = priceList.Id,
               Apttus_Config2__PriceListItemId__c = priceListItem.Id,
               Apttus_Config2__BillToAccountId__c = parentAccount.Id,
               Apttus_Config2__ShipToAccountId__c = parentAccount.Id,
               Apttus_Config2__PriceMethod__c = 'Per Unit',
               Apttus_Config2__PriceType__c = 'One Time',
               Apttus_Config2__PriceUom__c = 'Each', 
               Apttus_Config2__Quantity__c = 1,
               Apttus_Config2__SellingFrequency__c = 'Hourly', 
               Apttus_Config2__SellingTerm__c = 5, 
               Apttus_Config2__StartDate__c = system.today(), 
              // Apttus_Config2__SellingUom__c = 'Box',
               Apttus_Config2__BillingFrequency__c = 'Hourly',
               Apttus_Config2__BillingRule__c = ' Bill In Advance',
               Apttus_Config2__EndDate__c  = system.today().adddays(10),
               Apttus_Config2__AccountId__c = parentAccount.Id,
               Apttus_Config2__InitialActivationDate__c = system.today(),
               Apttus_Config2__Comments__c = 'this is a test comment',
               Apttus_Config2__BillThroughDate__c  = system.today(),
               APTS_Batch_Billing_Schedules__c = False,
               //RM 19-12-2018. Include 3 fields. Defect #22992
               APTS_Cumulative_Call_Out_Coverage__c = 11,
               APTS_Cumulative_Labour_coverage__c = 12,
               APTS_Cumulative_Spare_Parts_Coverage__c = 13,
               //RM 08-01-2019. Include Base Price Override field. Defect #23455
               APTS_BasePriceOverride__c = 14,
               APTS_ZX10__c = 100,
               APTS_Calculated_Base_Extended_Price__c = 1,
               APTS_SourceSystem__c = 'BEC');
         insert parentAssetLineItem1; 
      
          Apttus_Config2__OrderLineItem__c orderltobj = new Apttus_Config2__OrderLineItem__c(); 
        orderltobj.Apttus_Config2__OrderId__c = orderobj.id; 
        orderltobj.Apttus_Config2__Status__c = 'Draft'; 
        orderltobj.APTS_Migrated_Asset_Line_Item__c = parentAssetLineItem1.id; 
        orderltobj.Apttus_Config2__AssetLineItemId__c = parentAssetLineItem1.id;  
        insert orderltobj; 
        Apttus_Config2__AssetLineItem__c parentAssetLineItem = new Apttus_Config2__AssetLineItem__c(Name = 'Parent Asset Line Item',
               Apttus_CMConfig__AgreementId__c = agreementRec.id,
               Apttus_Config2__AssetStatus__c= 'New',
               Apttus_Config2__LineNumber__c = 1,
               APTS_Physical_Asset__c = physicalAsset.Id,
               Apttus_Config2__ProductId__c = product.Id,
               Apttus_Config2__PriceListId__c = priceList.Id,
               Apttus_Config2__PriceListItemId__c = priceListItem.Id,
               Apttus_Config2__BillToAccountId__c = parentAccount.Id,
               Apttus_Config2__ShipToAccountId__c = parentAccount.Id,
               Apttus_Config2__PriceMethod__c = 'Per Unit',
               Apttus_Config2__PriceType__c = 'One Time',
               Apttus_Config2__PriceUom__c = 'Each', 
               Apttus_Config2__Quantity__c = 1,
               Apttus_Config2__SellingFrequency__c = 'Hourly', 
               Apttus_Config2__SellingTerm__c = 5, 
               Apttus_Config2__StartDate__c = system.today(), 
              // Apttus_Config2__SellingUom__c = 'Box',
               Apttus_Config2__BillingFrequency__c = 'Hourly',
               Apttus_Config2__BillingRule__c = ' Bill In Advance',
               Apttus_Config2__EndDate__c  = system.today().adddays(10),
               Apttus_Config2__AccountId__c = parentAccount.Id,
               Apttus_Config2__InitialActivationDate__c = system.today(),
               Apttus_Config2__Comments__c = 'this is a test comment',
               Apttus_Config2__BillThroughDate__c  = system.today(),
               APTS_Batch_Billing_Schedules__c = False, 
               Apttus_Config2__BusinessLineItemId__c = orderltobj.id,
               Apttus_Config2__BusinessObjectId__c = orderobj.id,
               Apttus_Config2__BusinessObjectType__c = 'Apttus_Config2__Order__c',
               //RM 19-12-2018. Include 3 fields. Defect #22992
               APTS_Cumulative_Call_Out_Coverage__c = 11,
               APTS_Cumulative_Labour_coverage__c = 12,
               APTS_Cumulative_Spare_Parts_Coverage__c = 13,
               //RM 08-01-2019. Include Base Price Override field. Defect #23455
               APTS_BasePriceOverride__c = 14,APTS_Option_Group_Text__c = 'OP',
               APTS_SourceSystem__c = 'BEC');
         insert parentAssetLineItem; 
         
          Apttus_Config2__AssetUsagePriceTier__c aptsPriceTier = new Apttus_Config2__AssetUsagePriceTier__c(Apttus_Config2__AssetLineItemId__c = parentAssetLineItem.Id,Apttus_Config2__Sequence__c = 1); 
          insert aptsPriceTier;
          
           Apttus_Config2__OrderSystemProperties__c orderSystemProperties = new Apttus_Config2__OrderSystemProperties__c();
           orderSystemProperties.Name = 'System Properties';
           orderSystemProperties.Apttus_Config2__CreateAssetOnOrderActivation__c = true;
           orderSystemProperties.Apttus_Config2__EnableInflightChangesAndCancellation__c = true;
           orderSystemProperties.Apttus_Config2__InitiateBillingOnOrderActivation__c = true;
           orderSystemProperties.APTS_Orders_to_display__c = 5;
           insert orderSystemProperties;
    }

    private static testMethod void testOrderCreation() {
        APTS_Batch_Jobs__mdt currentInput = (APTS_Batch_Jobs__mdt) JSON.deserialize(' { "APTS_Batch_Class_Name__c": "APTS_CreateConversionOrderBatchHelper", "APTS_Batch_Size__c": 100, "APTS_Control__c": false, "APTS_Is_Active__c": true, "APTS_Next_Jobs__c": "B_0003", "APTS_Primary__c": true, "APTS_Query__c": "Select Id,APTS_relatedlist_agreement__r.Id,APTS_relatedlist_agreement__r.Name, APTS_relatedlist_agreement__r.APTS_Check_on_Account_Machines__c,APTS_relatedlist_agreement__r.APTS_Check_on_Account_Ingredients__c,APTS_relatedlist_agreement__r.Apttus_CMConfig__PriceListId__c, APTS_relatedlist_agreement__r.Apttus_CMConfig__BillingPreferenceId__c,APTS_relatedlist_agreement__r.Apttus_CMConfig__PONumber__c, APTS_relatedlist_agreement__r.Apttus_CMConfig__PaymentTermId__c,APTS_relatedlist_agreement__r.APTS_Language__c,APTS_relatedlist_agreement__r.APTS_Bill_to_Party_Ingredients__c,APTS_relatedlist_agreement__r.APTS_Payer_Ingredients__c,APTS_relatedlist_agreement__r.APTS_Bill_to_Party_MachServ__c,APTS_relatedlist_agreement__r.APTS_Payer_Machines_Services__c,Apttus_Config2__BundleAssetId__c,CurrencyIsoCode,Apttus_Config2__AccountId__r.id, Apttus_Config2__AccountId__r.Apttus_Config2__BillingPreferenceId__c,Apttus_Config2__AccountId__r.Apttus_Config2__PaymentTermId__c, Apttus_Config2__AccountId__r.Language__c,Apttus_Config2__AccountId__r.Sales_Organization__c, Apttus_Config2__AccountId__r.Division__c,Apttus_Config2__AccountId__r.Distribution_Channel__c,Apttus_Config2__AccountId__r.Bill_To_Payer_Account__c,Apttus_Config2__AccountId__r.Related_Payer_Account__c,Apttus_Config2__AccountId__r.Related_Payer_Machines_Services__c FROM Apttus_Config2__AssetLineItem__c", "APTS_Triggers_to_Disable__c": "Agreement__c,AssetLineItemTrigger__c,APTS_Configuration_Trigger__c,TaskTrigger__c,APTS_AgreementLineItemTrigger__c", "DeveloperName": "B_0002", "Id": "m0F4E0000004G47UAE", "Label": "APTS_LineItemsPricingBatchHelper", "MasterLabel": "APTS_LineItemsPricingBatchHelper", "QualifiedApiName": "B_0002" }', APTS_Batch_Jobs__mdt.class);
        system.debug('**'+currentInput);
        APTS_CommonBatch batch = new APTS_CommonBatch(currentInput,'BEC');
        Database.Executebatch(batch,Integer.valueOf(currentInput.APTS_Batch_Size__c));         
    }

    private static testMethod void testRepriceOrder() {
        APTS_Batch_Jobs__mdt currentInput = (APTS_Batch_Jobs__mdt) JSON.deserialize(' { "APTS_Batch_Class_Name__c": "APTS_RepriceFinalizeConvOrdBatchHelper", "APTS_Batch_Size__c": 100, "APTS_Control__c": false, "APTS_Is_Active__c": true, "APTS_Next_Jobs__c": "B_0003", "APTS_Primary__c": true, "APTS_Query__c": "Select Id,APTS_L1_Asset_Line_Item__c, APTS_L1_Asset_Line_Item__r.Apttus_Config2__BundleAssetId__c FROM Apttus_Config2__Order__c where APTS_Order_Sub_Type__c = \'Conversion Order\'", "APTS_Triggers_to_Disable__c": "Agreement__c,AssetLineItemTrigger__c,APTS_Configuration_Trigger__c,TaskTrigger__c,APTS_AgreementLineItemTrigger__c", "DeveloperName": "B_0002", "Id": "m0F4E0000004G47UAE", "Label": "APTS_LineItemsPricingBatchHelper", "MasterLabel": "APTS_LineItemsPricingBatchHelper", "QualifiedApiName": "B_0002" }', APTS_Batch_Jobs__mdt.class);
        system.debug('**'+currentInput);
        APTS_CommonBatch batch = new APTS_CommonBatch(currentInput,'BEC');
        Database.Executebatch(batch,Integer.valueOf(currentInput.APTS_Batch_Size__c));         
    }   
    
    private static testMethod void testActivateOrder() {
        APTS_Batch_Jobs__mdt currentInput = (APTS_Batch_Jobs__mdt) JSON.deserialize(' { "APTS_Batch_Class_Name__c": "APTS_ActivateConversionOrderBatchHelper", "APTS_Batch_Size__c": 100, "APTS_Control__c": false, "APTS_Is_Active__c": true, "APTS_Next_Jobs__c": "B_0003", "APTS_Primary__c": true, "APTS_Query__c": "Select Id,APTS_L1_Asset_Line_Item__c, APTS_L1_Asset_Line_Item__r.Apttus_Config2__BundleAssetId__c FROM Apttus_Config2__Order__c where APTS_Order_Sub_Type__c = \'Conversion Order\'", "APTS_Triggers_to_Disable__c": "Agreement__c,AssetLineItemTrigger__c,APTS_Configuration_Trigger__c,TaskTrigger__c,APTS_AgreementLineItemTrigger__c", "DeveloperName": "B_0002", "Id": "m0F4E0000004G47UAE", "Label": "APTS_LineItemsPricingBatchHelper", "MasterLabel": "APTS_LineItemsPricingBatchHelper", "QualifiedApiName": "B_0002" }', APTS_Batch_Jobs__mdt.class);
        system.debug('**'+currentInput);
        APTS_CommonBatch batch = new APTS_CommonBatch(currentInput,'BEC');
        Database.Executebatch(batch,Integer.valueOf(currentInput.APTS_Batch_Size__c));         
    }       
}