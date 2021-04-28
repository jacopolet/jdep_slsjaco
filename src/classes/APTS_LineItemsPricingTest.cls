@isTest
public class APTS_LineItemsPricingTest {
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
    }

    private static testMethod void test1() {
        //Set metadata
        APTS_BatchMetadataCoverageTest.setMetadata(
            'SELECT APTS_Batch_Name__c,'+
            'APTS_Query_String__c,'+
            'DeveloperName,'+
            'APTS_Triggers__c '+
            'FROM APTS_Batch_Queries__mdt '+
            'WHERE DeveloperName = \'LineItems_Pricing\'',
            (List<APTS_Batch_Queries__mdt>) JSON.deserialize('[{"APTS_Query_String__c":"SELECT Id, Apttus_Config2__ConfigurationId__c,Apttus_Config2__LineNumber__c FROM Apttus_Config2__LineItem__c",'+
                '"APTS_Triggers__c":"Agreement__c,AssetLineItemTrigger__c,APTS_Configuration_Trigger__c,TaskTrigger__c,APTS_AgreementLineItemTrigger__c"}]', 
                List<APTS_Batch_Queries__mdt>.class
                )
            );

        test.startTest();
            APTS_LineItemsPricingSch scheduler = new APTS_LineItemsPricingSch();      
            String sch = '0  00 1 3 * ?';
            system.schedule('Test APTS_LineItemsPricingSch', sch, scheduler);
        test.stopTest();   
    }

    private static testMethod void test2() {
        Set<Id> setLineItemId = (new Map<Id,Apttus_Config2__LineItem__c>([SELECT Id FROM Apttus_Config2__LineItem__c])).keySet();

        //Set metadata
        APTS_BatchMetadataCoverageTest.setMetadata(
           'SELECT APTS_Batch_Name__c,'+
            'APTS_Query_String__c,'+
            'DeveloperName,'+
            'APTS_Triggers__c '+
            'FROM APTS_Batch_Queries__mdt '+
            'WHERE DeveloperName = \'LineItems_Pricing_Scheduler\'',
            (List<APTS_Batch_Queries__mdt>) JSON.deserialize('[{"APTS_Query_String__c":"SELECT ID, Apttus_Config2__LineNumber__c,Apttus_Config2__PrimaryLineNumber__c,Apttus_Config2__ConfigurationId__c'+ 
            ' FROM Apttus_Config2__LineItem__c WHERE Id IN :lineItemsIdSet",'+
                '"APTS_Triggers__c":"Agreement__c,AssetLineItemTrigger__c,APTS_Configuration_Trigger__c,TaskTrigger__c,APTS_AgreementLineItemTrigger__c"}]', 
                List<APTS_Batch_Queries__mdt>.class
                )
            );

        test.startTest();
            APTS_LineItemsPricingBatch obj = new APTS_LineItemsPricingBatch(setLineItemId);      
            Database.executebatch(obj);
        test.stopTest();   
    }
}