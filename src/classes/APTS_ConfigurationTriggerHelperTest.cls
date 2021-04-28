@isTest
private class APTS_ConfigurationTriggerHelperTest
{
	@testSetup
    private static void testDataSetup() {
		//insert custom settings
        /*TriggerSettings__c objTriggerSettings = new TriggerSettings__c();
        objTriggerSettings.Agreement__c = false;
		objTriggerSettings.AssetLineItemTrigger__c = false;
		objTriggerSettings.APTS_Configuration_Trigger__c = false;
        insert objTriggerSettings;*/

        Account objGrandParentAccount = new Account();
        objGrandParentAccount.Name = 'Grand Parent Account';
        objGrandParentAccount.Phone = '+919898468401';
        objGrandParentAccount.Main_Street_Only__c = 'Test Street';
        objGrandParentAccount.Main_House_Number__c = 'Test no.';
        objGrandParentAccount.billingcountry = 'Netherlands';
        insert objGrandParentAccount;
    
        /* create Parent Account **/
        Account objParentAccount = new Account();
        objParentAccount.Name = 'Parent Account';
        objParentAccount.Phone = '+919898468401';
        objParentAccount.Main_Street_Only__c = 'Test Street';
        objParentAccount.Main_House_Number__c = 'Test no.';
        objParentAccount.Parent = objGrandParentAccount;
        objParentAccount.ParentId = objGrandParentAccount.Id;
        insert objParentAccount;

        Account objChildAccount = new Account();
        objChildAccount.Name = 'Test Account';
        objChildAccount.Phone = '+919898468401';
        objChildAccount.Main_Street_Only__c = 'Test Street';
        objChildAccount.Main_House_Number__c = 'Test no.';
        objChildAccount.Parent = objParentAccount;
        objChildAccount.ParentId = objParentAccount.Id;
        insert objChildAccount;

		Account objChildAccount2 = new Account();
        objChildAccount2.Name = 'Test Account 2';
        objChildAccount2.Phone = '+919898468406';
        objChildAccount2.Main_Street_Only__c = 'Test Street';
        objChildAccount2.Main_House_Number__c = 'Test no.';
        objChildAccount2.Parent = objParentAccount;
        objChildAccount2.ParentId = objParentAccount.Id;
        insert objChildAccount2;
		
        Product2 product = new Product2();
        product.Name = 'Category Product';
        product.IsActive = true;
        product.Apttus_Config2__ConfigurationType__c = 'Standalone';
        product.APTS_Category_Adjustments_Product__c = True;
        insert product;

        Apttus_Config2__ClassificationName__c category = new Apttus_Config2__ClassificationName__c();
        category.Name = 'Tea';
        category.Apttus_Config2__Active__c = true;
        category.Apttus_Config2__HierarchyLabel__c = 'Tea';
        category.Apttus_Config2__Type__c = 'Offering';
        category.APTS_Allow_Adjustments__c = true;
        insert category;

        /* create category hierarchy */
        Apttus_Config2__ClassificationHierarchy__c categoryHierarchy = new Apttus_Config2__ClassificationHierarchy__c();
        categoryHierarchy.Name = 'Tea';
        categoryHierarchy.Apttus_Config2__HierarchyId__c = category.Id;
        categoryHierarchy.Apttus_Config2__AncestorId__c = null;
        categoryHierarchy.Apttus_Config2__DefaultSearchCategory__c = false;
        categoryHierarchy.Apttus_Config2__ExpandedByDefault__c = false;
        categoryHierarchy.Apttus_Config2__HideAllSearchFilters__c = false;
        categoryHierarchy.Apttus_Config2__IncludeInTotalsView__c = true;
        categoryHierarchy.Apttus_Config2__IsHidden__c = false;
        categoryHierarchy.Apttus_Config2__IsPicklist__c = false;
        categoryHierarchy.Apttus_Config2__Label__c = 'Tea';
        categoryHierarchy.Apttus_Config2__LargeImageSize__c = '20x20';
        categoryHierarchy.Apttus_Config2__Left__c = 1;
        categoryHierarchy.Apttus_Config2__Level__c = 0;
        categoryHierarchy.Apttus_Config2__MaxOptions__c = 1.00000;
        categoryHierarchy.Apttus_Config2__MinOptions__c = 1.00000;
        categoryHierarchy.Apttus_Config2__Modifiable__c = true;
        categoryHierarchy.Apttus_Config2__PrimordialId__c = null;
        categoryHierarchy.Apttus_Config2__ProductAttributeGroupId__c = null;
        categoryHierarchy.Apttus_Config2__Right__c = 20;
        insert categoryHierarchy;

        /* create sub-category */
        Apttus_Config2__ClassificationHierarchy__c subCategoryHierarchy = new Apttus_Config2__ClassificationHierarchy__c();
        subCategoryHierarchy.Name = 'Other Tea Brands';
        subCategoryHierarchy.CurrencyIsoCode = 'EUR';
        subCategoryHierarchy.Apttus_Config2__HierarchyId__c = category.Id;
        subCategoryHierarchy.Apttus_Config2__AncestorId__c = categoryHierarchy.Id;
        subCategoryHierarchy.Apttus_Config2__DefaultSearchCategory__c = false;
        subCategoryHierarchy.Apttus_Config2__ExpandedByDefault__c = false;
        subCategoryHierarchy.Apttus_Config2__HideAllSearchFilters__c = false;
        subCategoryHierarchy.Apttus_Config2__IncludeInTotalsView__c = true;
        subCategoryHierarchy.Apttus_Config2__IsHidden__c = false;
        subCategoryHierarchy.Apttus_Config2__IsPicklist__c = false;
        subCategoryHierarchy.Apttus_Config2__Label__c = 'Other Tea Brands';
        subCategoryHierarchy.Apttus_Config2__Left__c = 2;
        subCategoryHierarchy.Apttus_Config2__Level__c = 1;
        subCategoryHierarchy.Apttus_Config2__MaxOptions__c = 1.00000;
        subCategoryHierarchy.Apttus_Config2__MinOptions__c = 1.00000;
        subCategoryHierarchy.Apttus_Config2__Modifiable__c = true;
        subCategoryHierarchy.Apttus_Config2__PrimordialId__c = categoryHierarchy.Id;
        subCategoryHierarchy.Apttus_Config2__ProductAttributeGroupId__c = null;
        subCategoryHierarchy.Apttus_Config2__Right__c = 3;
        insert subCategoryHierarchy;

        /* create sub-sub-category */
        Apttus_Config2__ClassificationHierarchy__c subSubCategoryHierarchy = new Apttus_Config2__ClassificationHierarchy__c();
        subSubCategoryHierarchy.Name = 'Hornimans';
        subSubCategoryHierarchy.CurrencyIsoCode = 'EUR';
        subSubCategoryHierarchy.Apttus_Config2__HierarchyId__c = category.Id;
        subSubCategoryHierarchy.Apttus_Config2__AncestorId__c = subCategoryHierarchy.Id;
        subSubCategoryHierarchy.Apttus_Config2__DefaultSearchCategory__c = false;
        subSubCategoryHierarchy.Apttus_Config2__ExpandedByDefault__c = false;
        subSubCategoryHierarchy.Apttus_Config2__HideAllSearchFilters__c = false;
        subSubCategoryHierarchy.Apttus_Config2__IncludeInTotalsView__c = true;
        subSubCategoryHierarchy.Apttus_Config2__IsHidden__c = false;
        subSubCategoryHierarchy.Apttus_Config2__IsPicklist__c = false;
        subSubCategoryHierarchy.Apttus_Config2__Label__c = 'Hornimans';
        subSubCategoryHierarchy.Apttus_Config2__Left__c = 2;
        subSubCategoryHierarchy.Apttus_Config2__Level__c = 1;
        subSubCategoryHierarchy.Apttus_Config2__MaxOptions__c = 1.00000;
        subSubCategoryHierarchy.Apttus_Config2__MinOptions__c = 1.00000;
        subSubCategoryHierarchy.Apttus_Config2__Modifiable__c = true;
        subSubCategoryHierarchy.Apttus_Config2__PrimordialId__c = categoryHierarchy.Id;
        subSubCategoryHierarchy.Apttus_Config2__ProductAttributeGroupId__c = null;
        subSubCategoryHierarchy.Apttus_Config2__Right__c = 3;
        insert subSubCategoryHierarchy;
        
        Apttus_Config2__PriceList__c priceList = new Apttus_Config2__PriceList__c();
        priceList.Name = 'JDE Price List';
        priceList.Apttus_Config2__Active__c = true;
        priceList.APTS_SalesOrg__c = '0333';
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
        
        Apttus_Config2__PriceListItem__c pli = new Apttus_Config2__PriceListItem__c();
        pli.Apttus_Config2__PriceListId__c = priceList.Id;
        pli.Apttus_Config2__ProductId__c = product.Id;
        pli.Apttus_Config2__ListPrice__c = 0;
        pli.Apttus_Config2__ChargeType__c = 'Sales Price';
        pli.Apttus_Config2__PriceType__c = 'One Time';
        pli.Apttus_Config2__PriceMethod__c = 'Per Unit';
        pli.Apttus_Config2__Active__c = true;
        pli.Apttus_Config2__BillingFrequency__c = 'One Time';
        pli.Apttus_Config2__BillingRule__c = 'Bill In Advance';
        
        Apttus__APTS_Agreement__c agreement = new Apttus__APTS_Agreement__c();
        agreement.recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        agreement.Name = 'Test Agreement';
        agreement.Apttus__Agreement_Category__c = 'Standard';
        agreement.Apttus_CMConfig__PriceListId__c = priceList.Id;
        agreement.Apttus_CMConfig__PricingDate__c = System.Today();
        agreement.Apttus__Account__c = objChildAccount2.Id;
        insert agreement;

		Apttus__APTS_Agreement__c amendedAgreement = new Apttus__APTS_Agreement__c();
        amendedAgreement.recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        amendedAgreement.Name = 'Test Amended Agreement';
        amendedAgreement.Apttus__Agreement_Category__c = 'Standard';
        amendedAgreement.Apttus_CMConfig__PriceListId__c = priceList.Id;
        amendedAgreement.Apttus_CMConfig__PricingDate__c = System.Today();
        amendedAgreement.Apttus__Account__c = objChildAccount.Id;
        amendedAgreement.APTS_Agreement_Request__c = 'Amendment';
        insert amendedAgreement;

		Apttus__APTS_Agreement__c parentAgreement = new Apttus__APTS_Agreement__c();
        parentAgreement.recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        parentAgreement.Name = 'Parent Test Agreement';
        parentAgreement.Apttus__Agreement_Category__c = 'Standard';
        parentAgreement.Apttus_CMConfig__PriceListId__c = priceList.Id;
        parentAgreement.Apttus_CMConfig__PricingDate__c = System.Today();
        parentAgreement.Apttus__Account__c = objParentAccount.Id;
        insert parentAgreement;

        Apttus_Config2__ProductConfiguration__c agreementCart = new Apttus_Config2__ProductConfiguration__c();
		agreementCart.Name ='Sample Agreement Cart';
		agreementCart.Apttus_CMConfig__AgreementId__c = agreement.Id;
		agreementCart.Apttus_Config2__PriceListId__c = priceList.Id;
		agreementCart.Apttus_Config2__BusinessObjectType__c = 'Agreement';
		agreementCart.Apttus_Config2__AccountId__c = objChildAccount2.Id;
        insert agreementCart;

		Apttus_Config2__ProductConfiguration__c agreementAmendedCart = new Apttus_Config2__ProductConfiguration__c();
		agreementAmendedCart.Name ='Sample Agreement Amended Cart';
		agreementAmendedCart.Apttus_CMConfig__AgreementId__c = amendedAgreement.Id;
		agreementAmendedCart.Apttus_Config2__PriceListId__c = priceList.Id;
		agreementAmendedCart.Apttus_Config2__BusinessObjectType__c = 'Agreement';
		agreementAmendedCart.Apttus_Config2__AccountId__c = objChildAccount.Id;
        insert agreementAmendedCart;

		Apttus_Config2__ProductConfiguration__c parentAgreementCart = new Apttus_Config2__ProductConfiguration__c();
		parentAgreementCart.Name ='Sample Parent Agreement Cart';
		parentAgreementCart.Apttus_CMConfig__AgreementId__c = agreement.Id;
		parentAgreementCart.Apttus_Config2__PriceListId__c = priceList.Id;
		parentAgreementCart.Apttus_Config2__BusinessObjectType__c = 'Agreement';
		parentAgreementCart.Apttus_Config2__AccountId__c = objChildAccount.Id;
        insert parentAgreementCart;

        Apttus_Config2__LineItem__c lineItem = new Apttus_Config2__LineItem__c();
        lineItem.Apttus_Config2__ConfigurationId__c = agreementCart.Id;
        lineItem.Apttus_Config2__LineNumber__c = 1;
        lineItem.Apttus_Config2__IsPrimaryLine__c = true;
        lineItem.Apttus_Config2__PrimaryLineNumber__c = 1;
        lineItem.Apttus_Config2__ItemSequence__c = 2;
        lineItem.Apttus_Config2__ProductId__c = product.Id;
        lineItem.Apttus_Config2__PriceListId__c = priceList.Id;
        lineItem.Apttus_Config2__PriceListItemId__c = priceListItem.Id;
		lineItem.Apttus_Config2__ClassificationId__c = categoryHierarchy.Id;
        lineItem.APTS_Sub_Category__c = subCategoryHierarchy.Id;
        lineItem.APTS_Sub_Sub_Category__c = subSubcategoryHierarchy.Id;
        lineItem.Apttus_Config2__ListPrice__c = 11.00;
        lineItem.Apttus_Config2__BasePrice__c = 11.00;
        lineItem.Apttus_Config2__ExtendedPrice__c = 11.00;
        lineItem.Apttus_Config2__AdjustedPrice__c = 0;
        lineItem.Apttus_Config2__Comments__c = 'Added by Code';
        lineItem.APTS_Category_Level__c = 'Category';
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

		Apttus_Config2__LineItem__c parentLineItem = new Apttus_Config2__LineItem__c();
        parentLineItem.Apttus_Config2__ConfigurationId__c = parentAgreementCart.Id;
        parentLineItem.Apttus_Config2__LineNumber__c = 1;
        parentLineItem.Apttus_Config2__IsPrimaryLine__c = true;
        parentLineItem.Apttus_Config2__PrimaryLineNumber__c = 1;
        parentLineItem.Apttus_Config2__ItemSequence__c = 2;
        parentLineItem.Apttus_Config2__ProductId__c = product.Id;
        parentLineItem.Apttus_Config2__PriceListId__c = priceList.Id;
        parentLineItem.Apttus_Config2__PriceListItemId__c = priceListItem.Id;
		parentLineItem.Apttus_Config2__ClassificationId__c = categoryHierarchy.Id;
        parentLineItem.APTS_Sub_Category__c = subCategoryHierarchy.Id;
        parentLineItem.APTS_Sub_Sub_Category__c = subSubcategoryHierarchy.Id;
        parentLineItem.Apttus_Config2__ListPrice__c = 11.00;
        parentLineItem.Apttus_Config2__BasePrice__c = 11.00;
        parentLineItem.Apttus_Config2__ExtendedPrice__c = 11.00;
        parentLineItem.Apttus_Config2__AdjustedPrice__c = 0;
        parentLineItem.Apttus_Config2__Comments__c = 'Added by Code';
        parentLineItem.APTS_Category_Level__c = 'Category';
        insert parentLineItem;

        Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem6 = new Apttus_Config2__AdjustmentLineItem__c();
        adjustmentLineItem6.Apttus_Config2__AdjustmentAmount__c = 1;
        adjustmentLineItem6.Apttus_Config2__AdjustmentAppliesTo__c = 'Previous Price';
        adjustmentLineItem6.Apttus_Config2__AdjustmentType__c = '% Discount';
        adjustmentLineItem6.Apttus_Config2__LineItemId__c = parentLineItem.Id;
        adjustmentLineItem6.Apttus_Config2__LineNumber__c = 1;
        adjustmentLineItem6.Apttus_Config2__LineType__c = 'Manual';
        adjustmentLineItem6.Apttus_Config2__Type__c = 'BMC';
        adjustmentLineItem6.Apttus_Config2__SubType__c = 'Trade';
        insert adjustmentLineItem6;

        APTS_Contract_Entitlement_Repository__c CER1 = new APTS_Contract_Entitlement_Repository__c();
        CER1.APTS_Sold_to_Party__c = objChildAccount2.Id;
        CER1.APTS_CategoryCER__c = categoryHierarchy.Id;
        CER1.APTS_Contributing_Agreement__c = agreement.Id;
        CER1.APTS_Agreement_Type__c = 'Standard Deal';
        CER1.APTS_Product__c = product.Id;
        CER1.APTS_Category_Level__c = 'Category';
        CER1.APTS_Is_Pending__c = true;
        CER1.APTS_Pending_Adjustment_Line_Item__c = adjustmentLineItem.Id;
        CER1.APTS_Pending_Line_Item__c = lineItem.Id;
		CER1.APTS_Contributing_Agreement_Level__c = 'Child';
		CER1.APTS_CER_from_Parent__c = true;
        insert CER1;

		APTS_Contract_Entitlement_Repository__c CER4 = new APTS_Contract_Entitlement_Repository__c();
        CER4.APTS_Sold_to_Party__c = objParentAccount.Id;
        CER4.APTS_CategoryCER__c = categoryHierarchy.Id;
        CER4.APTS_Contributing_Agreement__c = agreement.Id;
        CER4.APTS_Agreement_Type__c = 'Standard Deal';
        CER4.APTS_Product__c = product.Id;
        CER4.APTS_Category_Level__c = 'Category';
        CER4.APTS_Is_Pending__c = true;
        CER4.APTS_Pending_Adjustment_Line_Item__c = adjustmentLineItem6.Id;
        CER4.APTS_Pending_Line_Item__c = parentLineItem.Id;
		CER4.APTS_Contributing_Agreement_Level__c = 'Parent';
        insert CER4;

		APTS_Contract_Entitlement_Repository__c CER2 = new APTS_Contract_Entitlement_Repository__c();
        CER2.APTS_Sold_to_Party__c = objChildAccount.Id;
        CER2.APTS_CategoryCER__c = categoryHierarchy.Id;
        CER2.APTS_Contributing_Agreement__c = amendedAgreement.Id;
        CER2.APTS_Agreement_Type__c = 'Standard Deal';
        CER2.APTS_Product__c = product.Id;
        CER2.APTS_Category_Level__c = 'Category';
        CER2.APTS_Is_Pending__c = true;
        //CER2.APTS_Pending_Adjustment_Line_Item__c = adjustmentLineItem.Id;
        //CER2.APTS_Pending_Line_Item__c = lineItem.Id;
		CER2.APTS_Contributing_Agreement_Level__c = 'Child';
		CER2.APTS_CER_from_Parent__c = true;
		CER2.APTS_Category_Discount_Amendment__c = true;
		CER2.APTS_Type__c = 'PPR';
        insert CER2;

		APTS_Contract_Entitlement_Repository__c CERAmendment = new APTS_Contract_Entitlement_Repository__c();
        CERAmendment.APTS_Sold_to_Party__c = objChildAccount.Id;
        CERAmendment.APTS_CategoryCER__c = categoryHierarchy.Id;
        CERAmendment.APTS_Contributing_Agreement__c = agreement.Id;
        CERAmendment.APTS_Agreement_Type__c = 'Standard Deal';
        CERAmendment.APTS_Product__c = product.Id;
        CERAmendment.APTS_Category_Level__c = 'Category';
        CERAmendment.APTS_Is_Pending__c = true;
        CERAmendment.APTS_Pending_Adjustment_Line_Item__c = adjustmentLineItem.Id;
        CERAmendment.APTS_Pending_Line_Item__c = lineItem.Id;
		CERAmendment.APTS_Contributing_Agreement_Level__c = 'Child';
		CERAmendment.APTS_CER_from_Parent__c = true;
		CERAmendment.APTS_Type__c = 'PPR';  
        insert CERAmendment;
    }

	@isTest
	static void test_recoverCERRecordParent()
	{
		Set<Id> setPC = (new Map<Id,Apttus_Config2__ProductConfiguration__c>([SELECT Id FROM Apttus_Config2__ProductConfiguration__c WHERE Name ='Sample Agreement Cart'])).keySet();

		Test.startTest();
			APTS_ConfigurationTriggerHelper.deleteRecoverCERRecords(setPC);
		Test.stopTest();
	}

	@isTest
	static void test_recoverCERRecordParentAmendment()
	{
		List<APTS_Contract_Entitlement_Repository__c> lstCER = 
		[
			SELECT Id, 
			APTS_Pending_Line_Item__c,
			APTS_CER_from_Parent__c,
			APTS_Contributing_Agreement_Level__c,
			APTS_Pending_Line_Item__r.Apttus_Config2__ConfigurationId__c,
			APTS_Category_Discount_Amendment__c,
			APTS_CategoryCER__c,
			APTS_Type__c,
			APTS_Sub_Type__c,
			APTS_Sub_Category__c,
			APTS_Sub_Sub_Category__c,
			APTS_Sold_to_Party__c,
			APTS_Product__c,
			APTS_Contributing_Agreement__c
			FROM APTS_Contract_Entitlement_Repository__c 
			WHERE APTS_Type__c = 'PPR'
		];

		Test.startTest();
			APTS_ConfigurationTriggerHelper.recoverCERRecordParentAmendment(lstCER, lstCER[0].APTS_Sold_to_Party__c);
		Test.stopTest();
	}
}