@isTest
private class APTS_AgreementLoadBatchTest {
	@testSetup
    private static void testDataSetup() {
		//insert custom settings
        TriggerSettings__c objTriggerSettings = new TriggerSettings__c();
        objTriggerSettings.Agreement__c = false;
		objTriggerSettings.AssetLineItemTrigger__c = false;
		objTriggerSettings.APTS_Configuration_Trigger__c = false;
        insert objTriggerSettings;

        Account grandParentAccount = APTS_TestClassUtils.createGrandParentAccount();
        insert grandParentAccount;

        Account parentAccount = APTS_TestClassUtils.createParentAccount(grandParentAccount);
        insert parentAccount;

        Account childAccount = APTS_TestClassUtils.createChildAccount(parentAccount);
        insert childAccount;
		
        Product2 product =APTS_TestClassUtils.createProduct(true,'Piazza DOro Estremo Bonen 1000 Gram','26940998','Espresso');

        /*Apttus_Config2__ClassificationName__c category = APTS_TestClassUtils.createCategory(true);

        Apttus_Config2__ClassificationHierarchy__c categoryHierarchy = APTS_TestClassUtils.createCategoryHierarchy(true, category.Id);

        Apttus_Config2__ClassificationHierarchy__c subCategoryHierarchy = APTS_TestUtils.createSubCategory(true, category.Id, categoryHierarchy.Id);

        Apttus_Config2__ClassificationHierarchy__c subSubCategoryHierarchy = APTS_TestUtils.createSubSubCategory(category.Id,categoryHierarchy.Id ,subCategoryHierarchy.Id);
        insert subSubCategoryHierarchy;

        Apttus_Config2__ProductClassification__c productClassification = APTS_TestUtils.createProductClassification(subCategoryHierarchy.Id, product.id);
        insert productClassification;

        Apttus_Config2__ProductClassification__c productClassification1 = APTS_TestUtils.createProductClassification(subCategoryHierarchy.Id, product.id);
        insert productClassification1;*/
        
        Apttus_Config2__PriceList__c priceList = APTS_TestClassUtils.createPriceList(false);
        priceList.APTS_SalesOrg__c = 'SAP_0033';
        insert priceList;
        
        Apttus_Config2__PriceListItem__c priceListItem = APTS_TestClassUtils.createPriceListItem(true,priceList.id,product.id);
        
        Apttus__APTS_Agreement__c agreement = APTS_TestClassUtils.createAgreement(true, priceList.Id, childAccount.Id);

        Apttus_Config2__ProductConfiguration__c agreementCart = 
        APTS_TestClassUtils.createProductConfigurationAgreement(false, agreement.id, priceList.id);
        agreementCart.Apttus_Config2__BusinessObjectRefId__c = agreement.Id;
        insert agreementCart;

        Apttus_Config2__LineItem__c lineItem1 = APTS_TestClassUtils.createConfigLineItem(false,agreementCart.id, null, 1, true, 2, '', product.id, false, null,product.id, null, '', 2.3, false, '', 1, priceList.id, priceListItem.Id, '', '', 'Sales Price', '',false, false, 22.00, 24.00, '', 34.00, 23.00, 33.50, '');
        lineItem1.Apttus_Config2__IsPrimaryLine__c = true;
        lineItem1.Apttus_Config2__LineType__c = system.label.APTS_ProductService;
        insert lineItem1;

        Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem = APTS_TestClassUtils.createAdjustmentLineItem(true, lineItem1.Id);
    }

    private static testMethod void test1() {

        test.startTest();
            APTS_AgreementLoadSch scheduler = new APTS_AgreementLoadSch();      
			String sch = '0  00 1 3 * ?';
			system.schedule('Test APTS_AgreementLoadSch', sch, scheduler);
        test.stopTest();
   
    }
}