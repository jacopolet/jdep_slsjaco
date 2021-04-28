@isTest 
private class APTS_LineItemUpdatePricebatch_Tests {


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
    private static void PricingTest() {
        APTS_LineItemPricingUpdatePriceCartBatch batch = new APTS_LineItemPricingUpdatePriceCartBatch(1,'Select id from Apttus_Config2__ProductConfiguration__c ');
        Database.Executebatch(batch,1);
    }    
}