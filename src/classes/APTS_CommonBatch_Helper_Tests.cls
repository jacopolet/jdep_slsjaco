@isTest 
private class APTS_CommonBatch_Helper_Tests {


    @testSetup
    private static void testDataSetup() {

        //insert custom settings
        TriggerSettings__c objTriggerSettings = new TriggerSettings__c();
        objTriggerSettings.Agreement__c = false;
        objTriggerSettings.AssetLineItemTrigger__c = false;
        objTriggerSettings.APTS_Configuration_Trigger__c = false;
        insert objTriggerSettings;

        Account childAccount = new Account();
        childAccount.Name = 'Grand Parent Account';
        childAccount.Phone = '+919898468401';
        childAccount.Main_Street_Only__c = 'Test Street';
        childAccount.Main_House_Number__c = 'Test no.';
        childAccount.billingcountry = 'Netherlands';
        insert childAccount;
        
        Product2 product = new Product2();
        product.Name = 'Piazza DOro Estremo Bonen 1000 Gram';
        product.ProductCode = '26940998';
        product.Family = 'Espresso';
        product.IsActive = true;
        product.Apttus_Config2__ConfigurationType__c = 'Standalone';
        insert product;

        Apttus_Config2__PriceList__c priceList = new Apttus_Config2__PriceList__c();
        priceList.Name = 'JDE Price List';
        priceList.Apttus_Config2__Active__c = true;
        priceList.APTS_SalesOrg__c = 'SalesOrg';
        insert priceList;
        
        Apttus_Config2__PriceListItem__c priceListItem = new Apttus_Config2__PriceListItem__c();
        priceListItem.Apttus_Config2__PriceListId__c = priceList.id;
        priceListItem.Apttus_Config2__ProductId__c = product.id;
        priceListItem.Apttus_Config2__ListPrice__c = 0;
        priceListItem.Apttus_Config2__ChargeType__c = 'Sales Price';
        priceListItem.Apttus_Config2__PriceType__c = 'One Time';
        priceListItem.Apttus_Config2__PriceMethod__c = 'Per Unit';
        priceListItem.Apttus_Config2__Active__c = true;
        priceListItem.Apttus_Config2__BillingFrequency__c = 'One Time';
        priceListItem.Apttus_Config2__BillingRule__c = 'Bill In Advance';
        insert priceListItem;
        
        Apttus__APTS_Agreement__c agreement = new Apttus__APTS_Agreement__c(recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId(),
                Name = 'Agreement',
                Apttus__Agreement_Category__c = 'Standard',
                Apttus_CMConfig__PriceListId__c = priceList.Id,
                Apttus__Account__c = childAccount.Id);
        insert agreement;
        
        Apttus_Config2__ProductConfiguration__c agreementCart = new Apttus_Config2__ProductConfiguration__c(Name='Sample',Apttus_CMConfig__AgreementId__c=agreement.id,Apttus_Config2__PriceListId__c=priceList.id);
        agreementCart.Apttus_Config2__BusinessObjectType__c = 'Agreement';
        insert agreementCart;

        Apttus_Config2__LineItem__c lineItem = new Apttus_Config2__LineItem__c();
        lineItem.Apttus_Config2__ConfigurationId__c = agreementCart.Id;
        lineItem.Apttus_Config2__LineNumber__c = 1;
        lineItem.Apttus_Config2__IsPrimaryLine__c = true;
        lineItem.Apttus_Config2__PrimaryLineNumber__c = 1;
        lineItem.Apttus_Config2__ItemSequence__c = 2;
        lineItem.Apttus_Config2__ProductId__c = product.Id;
        lineItem.Apttus_Config2__PriceListId__c = priceList.Id;
        lineItem.Apttus_Config2__PriceListItemId__c = priceListItem.Id;
        lineItem.Apttus_Config2__ListPrice__c = 11.00;
        lineItem.Apttus_Config2__BasePrice__c = 11.00;
        lineItem.Apttus_Config2__ExtendedPrice__c = 11.00;
        lineItem.Apttus_Config2__AdjustedPrice__c = 0;
        insert lineItem;

        Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem = new Apttus_Config2__AdjustmentLineItem__c();
        adjustmentLineItem.Apttus_Config2__AdjustmentAmount__c = 1;
        adjustmentLineItem.Apttus_Config2__AdjustmentAppliesTo__c = 'Previous Price';
        adjustmentLineItem.Apttus_Config2__AdjustmentType__c = '% Discount';
        adjustmentLineItem.Apttus_Config2__LineItemId__c = lineItem.Id;
        adjustmentLineItem.Apttus_Config2__LineNumber__c = 1;
        adjustmentLineItem.Apttus_Config2__LineType__c = 'Manual';
        adjustmentLineItem.Apttus_Config2__Type__c = 'TPR';
        adjustmentLineItem.Apttus_Config2__SubType__c = 'Trade';
        insert adjustmentLineItem;
        
        Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem1 = new Apttus_Config2__AdjustmentLineItem__c();
        adjustmentLineItem1.Apttus_Config2__AdjustmentAmount__c = 1;
        adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Previous Price';
        adjustmentLineItem1.Apttus_Config2__AdjustmentType__c = '% Discount';
        adjustmentLineItem1.Apttus_Config2__LineItemId__c = lineItem.Id;
        adjustmentLineItem1.Apttus_Config2__LineNumber__c = 1;
        adjustmentLineItem1.Apttus_Config2__LineType__c = 'Manual';
        adjustmentLineItem1.Apttus_Config2__Type__c = 'TPR';
        adjustmentLineItem1.Apttus_Config2__SubType__c = 'Trade';
        insert adjustmentLineItem1;
        Apttus_Config2__Order__c orderobj = new Apttus_Config2__Order__c(); 
        insert orderobj;
        Apttus_Config2__AssetLineItem__c astlineitm = new Apttus_Config2__AssetLineItem__c();
        astlineitm.Name ='Test';
        insert astlineitm;
        
        Apttus_Config2__AssetAttributeValue__c Attribute = new Apttus_Config2__AssetAttributeValue__c(); 
        Attribute.Apttus_Config2__AssetLineItemId__c = astlineitm.id;
        insert Attribute;
        Apttus_Config2__OrderLineItem__c orderltobj = new Apttus_Config2__OrderLineItem__c(); 
        orderltobj.Apttus_Config2__OrderId__c = orderobj.id;
        orderltobj.Apttus_Config2__AssetLineItemId__c = astlineitm.id;
        orderltobj.APTS_Migrated_Asset_Line_Item__c = astlineitm.id;
        insert orderltobj;  
        
        Apttus_Config2_AssetAdjustItem__c aca = new Apttus_Config2_AssetAdjustItem__c();
        aca.Apttus_Config2_AssetLineItemId__c = orderltobj.APTS_Migrated_Asset_Line_Item__c;
        insert aca;
        
        APTS_CounterReadingData__c acr = new APTS_CounterReadingData__c();
        acr.APTS_Asset_Line_Item__c = orderltobj.APTS_Migrated_Asset_Line_Item__c;
        insert acr; 
    }

    @isTest
    private static void lineItemPricingTest() {
        APTS_Batch_Jobs__mdt currentInput = (APTS_Batch_Jobs__mdt) JSON.deserialize(' { "APTS_Batch_Class_Name__c": "APTS_LineItemsPricingBatchHelper", "APTS_Batch_Size__c": 1, "APTS_Control__c": true, "APTS_Is_Active__c": false, "APTS_Next_Jobs__c": "B_0003", "APTS_Primary__c": true, "APTS_Query__c": "SELECT Id,Apttus_Config2__PricingStatus__c, Apttus_Config2__LineNumber__c,Apttus_Config2__ConfigurationId__c FROM Apttus_Config2__LineItem__c", "APTS_Triggers_to_Disable__c": "Agreement__c,AssetLineItemTrigger__c,APTS_Configuration_Trigger__c,TaskTrigger__c,APTS_AgreementLineItemTrigger__c", "DeveloperName": "B_0002", "Id": "m0F4E0000004G47UAE", "Label": "APTS_LineItemsPricingBatchHelper", "MasterLabel": "APTS_LineItemsPricingBatchHelper", "QualifiedApiName": "B_0002" }', APTS_Batch_Jobs__mdt.class);
        system.debug('**'+currentInput);
        APTS_CommonBatch batch = new APTS_CommonBatch(currentInput,'BEC');
        Database.Executebatch(batch,Integer.valueOf(currentInput.APTS_Batch_Size__c));
    }

    @isTest
    private static void FinalizeBatchHelperTest() {
        APTS_Batch_Jobs__mdt currentInput = (APTS_Batch_Jobs__mdt) JSON.deserialize(' { "APTS_Batch_Class_Name__c": "APTS_ProductConfigFinalizeBatchHelper", "APTS_Batch_Size__c": 1, "APTS_Control__c": false, "APTS_Is_Active__c": false, "APTS_Next_Jobs__c": "B_0003", "APTS_Primary__c": true, "APTS_Query__c": "SELECT Id FROM Apttus_Config2__ProductConfiguration__c", "APTS_Triggers_to_Disable__c": "Agreement__c,AssetLineItemTrigger__c,APTS_Configuration_Trigger__c,TaskTrigger__c,APTS_AgreementLineItemTrigger__c", "DeveloperName": "B_0002", "Id": "m0F4E0000004G47UAE", "Label": "APTS_LineItemsPricingBatchHelper", "MasterLabel": "APTS_LineItemsPricingBatchHelper", "QualifiedApiName": "B_0002" }', APTS_Batch_Jobs__mdt.class);
        system.debug('**'+currentInput);
        APTS_CommonBatch batch = new APTS_CommonBatch(currentInput,'BEC');
        Database.Executebatch(batch,Integer.valueOf(currentInput.APTS_Batch_Size__c));       
    }


    @isTest
    private static void cerRecordTest() {
        APTS_Batch_Jobs__mdt currentInput = (APTS_Batch_Jobs__mdt) JSON.deserialize(' { "APTS_Batch_Class_Name__c": "APTS_CERRecordsGenerationBatchHelper", "APTS_Batch_Size__c": 1, "APTS_Control__c": false, "APTS_Is_Active__c": false, "APTS_Next_Jobs__c": "B_0003", "APTS_Primary__c": true, "APTS_Query__c": "SELECT Id,Apttus__Account__c FROM Apttus__APTS_Agreement__c", "APTS_Triggers_to_Disable__c": "Agreement__c,AssetLineItemTrigger__c,APTS_Configuration_Trigger__c,TaskTrigger__c,APTS_AgreementLineItemTrigger__c", "DeveloperName": "B_0002", "Id": "m0F4E0000004G47UAE", "Label": "APTS_LineItemsPricingBatchHelper", "MasterLabel": "APTS_LineItemsPricingBatchHelper", "QualifiedApiName": "B_0002" }', APTS_Batch_Jobs__mdt.class);
        system.debug('**'+currentInput);
        APTS_CommonBatch batch = new APTS_CommonBatch(currentInput,'BEC');
        Database.Executebatch(batch,Integer.valueOf(currentInput.APTS_Batch_Size__c));
    } 

    @isTest
    private static void cerRecordTest2() {
        APTS_Batch_Jobs__mdt currentInput = (APTS_Batch_Jobs__mdt) JSON.deserialize(' { "APTS_Batch_Class_Name__c": "APTS_CERRecordsGenerationBatchHelper", "APTS_Batch_Size__c": 1, "APTS_Control__c": true, "APTS_Is_Active__c": false, "APTS_Next_Jobs__c": "B_0003", "APTS_Primary__c": true, "APTS_Query__c": "SELECT Id,Apttus__Account__c FROM Apttus__APTS_Agreement__c", "APTS_Triggers_to_Disable__c": "Agreement__c,AssetLineItemTrigger__c,APTS_Configuration_Trigger__c,TaskTrigger__c,APTS_AgreementLineItemTrigger__c", "DeveloperName": "B_0002", "Id": "m0F4E0000004G47UAE", "Label": "APTS_LineItemsPricingBatchHelper", "MasterLabel": "APTS_LineItemsPricingBatchHelper", "QualifiedApiName": "B_0002" }', APTS_Batch_Jobs__mdt.class);
        system.debug('**'+currentInput);
        APTS_CommonBatch batch = new APTS_CommonBatch(currentInput,'BEC');
        Database.Executebatch(batch,Integer.valueOf(currentInput.APTS_Batch_Size__c));
    } 
    
    @isTest
    private static void mapAssetAttributeTest() {
        APTS_Batch_Jobs__mdt currentInput = (APTS_Batch_Jobs__mdt) JSON.deserialize(' { "APTS_Batch_Class_Name__c": "APTS_MapAssetAttributeBatchHelper", "APTS_Batch_Size__c": 1, "APTS_Control__c": false, "APTS_Is_Active__c": false, "APTS_Next_Jobs__c": "B_0003", "APTS_Primary__c": true, "APTS_Query__c": "SELECT Id, APTS_Migrated_Asset_Line_Item__r.Apttus_Config2__ParentAssetId__c,APTS_Migrated_Asset_Line_Item__c,APTS_Migrated_Asset_Line_Item__r.Apttus_Config2__BundleAssetId__c,Apttus_Config2__AssetLineItemId__c FROM Apttus_Config2__OrderLineItem__c", "APTS_Triggers_to_Disable__c": "Agreement__c,AssetLineItemTrigger__c,APTS_Configuration_Trigger__c,TaskTrigger__c,APTS_AgreementLineItemTrigger__c", "DeveloperName": "B_0002", "Id": "m0F4E0000004G47UAE", "Label": "APTS_LineItemsPricingBatchHelper", "MasterLabel": "APTS_LineItemsPricingBatchHelper", "QualifiedApiName": "B_0002" }', APTS_Batch_Jobs__mdt.class);
        system.debug('**'+currentInput);
        APTS_CommonBatch batch = new APTS_CommonBatch(currentInput,'BEC');
        Database.Executebatch(batch,Integer.valueOf(currentInput.APTS_Batch_Size__c));
    }
       @isTest
    private static void LineItemAdjustmentAPITest() {
        APTS_Batch_Jobs__mdt currentInput = (APTS_Batch_Jobs__mdt) JSON.deserialize(' { "APTS_Batch_Class_Name__c": "APTS_LineItemAdjustmentAPIBatchHelper", "APTS_Batch_Size__c": 1, "APTS_Control__c": false, "APTS_Is_Active__c": false, "APTS_Next_Jobs__c": "B_0003", "APTS_Primary__c": true, "APTS_Query__c": "Select Id from Apttus_Config2__ProductConfiguration__c", "APTS_Triggers_to_Disable__c": "Agreement__c,AssetLineItemTrigger__c,APTS_Configuration_Trigger__c,TaskTrigger__c,APTS_AgreementLineItemTrigger__c", "DeveloperName": "B_0002", "Id": "m0F4E0000004G47UAE", "Label": "APTS_LineItemsPricingBatchHelper", "MasterLabel": "APTS_LineItemsPricingBatchHelper", "QualifiedApiName": "B_0002" ,"Second_Query__c":"Id,Apttus_Config2__LineType__c,APTS_Type_of_contract__c,Apttus_Config2__AttributeValueId__r.APTS_Include_Free_Service__c,Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c,Apttus_Config2__AttributeValueId__r.APTS_Number_of_months__c,Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c,Apttus_Config2__AttributeValueId__r.APTS_Charge_for_Ingredients__c,Apttus_Config2__ConfigurationId__c,Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__c,Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Fixed_Term_Type__c,Apttus_Config2__OptionId__c,Apttus_Config2__OptionId__r.name,Apttus_Config2__ProductId__c,Apttus_Config2__ProductId__r.name,Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Agreement_Duration_Months__c"}', APTS_Batch_Jobs__mdt.class);
        system.debug('**'+currentInput);
        APTS_CommonBatch batch = new APTS_CommonBatch(currentInput,'BEC');
        Database.Executebatch(batch,Integer.valueOf(currentInput.APTS_Batch_Size__c));
    }
    
    @isTest
    private static void ActivateAgreementBatchHelperTest() {
        APTS_Batch_Jobs__mdt currentInput = (APTS_Batch_Jobs__mdt) JSON.deserialize(' { "APTS_Batch_Class_Name__c": "APTS_ActivateAgreementBatchHelper", "APTS_Batch_Size__c": 1, "APTS_Control__c": false, "APTS_Is_Active__c": false, "APTS_Next_Jobs__c": "", "APTS_Primary__c": true, "APTS_Query__c": "Select Id From Apttus__APTS_Agreement__c", "APTS_Triggers_to_Disable__c": "Agreement__c,AssetLineItemTrigger__c,APTS_Configuration_Trigger__c,TaskTrigger__c,APTS_AgreementLineItemTrigger__c", "DeveloperName": "B_0009", "Id": "m0F4E0000004G47UAE", "Label": "APTS_LineItemsPricingBatchHelper", "MasterLabel": "APTS_LineItemsPricingBatchHelper", "QualifiedApiName": "B_0002" }', APTS_Batch_Jobs__mdt.class);
        system.debug('RG**'+currentInput);
        APTS_CommonBatch batch = new APTS_CommonBatch(currentInput,'BEC');
        Database.Executebatch(batch,Integer.valueOf(currentInput.APTS_Batch_Size__c));
    }    

       @isTest
    private static void LineItemAdjustmentBatchTest() {
        APTS_Batch_Jobs__mdt currentInput = (APTS_Batch_Jobs__mdt) JSON.deserialize(' { "APTS_Batch_Class_Name__c": "APTS_AdjustmentAPIBatchHelper", "APTS_Batch_Size__c": 2, "APTS_Control__c": false, "APTS_Is_Active__c": false, "APTS_Next_Jobs__c": "", "APTS_Primary__c": true, "APTS_Query__c": "Select Id,Apttus_Config2__LineItemId__c,Apttus_Config2__LineItemId__r.Apttus_Config2__ConfigurationId__c from Apttus_Config2__AdjustmentLineItem__c", "APTS_Triggers_to_Disable__c": "Agreement__c,AssetLineItemTrigger__c,APTS_Configuration_Trigger__c,TaskTrigger__c,APTS_AgreementLineItemTrigger__c", "DeveloperName": "B_0007", "Id": "m0F4E0000004G47UAE", "Label": "APTS_LineItemsPricingBatchHelper", "MasterLabel": "APTS_LineItemsPricingBatchHelper", "QualifiedApiName": "B_0002" ,"Second_Query__c":""}', APTS_Batch_Jobs__mdt.class);
        system.debug('**'+currentInput);
        APTS_CommonBatch batch = new APTS_CommonBatch(currentInput,'BEC');
        Database.Executebatch(batch,Integer.valueOf(currentInput.APTS_Batch_Size__c));
    }
}