@isTest
private class APTS_CategoryAdjustmentsHelperTest
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
        
        Product2 product = new Product2();
        product.Name = 'Category Product';
        product.IsActive = true;
        product.Apttus_Config2__ConfigurationType__c = 'Standalone';
        product.APTS_Category_Adjustments_Product__c = True;
        insert product;

        Product2 testProduct = new Product2();
        testProduct.Name = 'Test Product';
        testProduct.IsActive = true;
        testProduct.Apttus_Config2__ConfigurationType__c = 'Standalone';
        testProduct.APTS_Category_Adjustments_Product__c = True;
        insert testProduct;

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

        Apttus_Config2__ClassificationHierarchy__c categoryHierarchyb = new Apttus_Config2__ClassificationHierarchy__c();
        categoryHierarchyb.Name = 'Sub Tea';
        categoryHierarchyb.Apttus_Config2__HierarchyId__c = category.Id;
        categoryHierarchyb.Apttus_Config2__Label__c = 'Sub Tea';
        categoryHierarchyb.Apttus_Config2__PrimordialId__c = categoryHierarchy.Id;
        insert categoryHierarchyb;

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

        /* create sub-category */
        Apttus_Config2__ClassificationHierarchy__c subCategoryHierarchyb = new Apttus_Config2__ClassificationHierarchy__c();
        subCategoryHierarchyb.Name = 'Other Tea Brands B';
        subCategoryHierarchyb.CurrencyIsoCode = 'EUR';
        subCategoryHierarchyb.Apttus_Config2__HierarchyId__c = category.Id;
        subCategoryHierarchyb.Apttus_Config2__AncestorId__c = subCategoryHierarchy.Id;
        subCategoryHierarchyb.Apttus_Config2__PrimordialId__c = categoryHierarchy.Id;
        subCategoryHierarchyb.Apttus_Config2__Label__c = 'Other Tea Brands B';
        insert subCategoryHierarchyb;

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

        /* create sub-sub-category */
        Apttus_Config2__ClassificationHierarchy__c subSubCategoryHierarchyb = new Apttus_Config2__ClassificationHierarchy__c();
        subSubCategoryHierarchyb.Name = 'Hornimans';
        subSubCategoryHierarchyb.CurrencyIsoCode = 'EUR';
        subSubCategoryHierarchyb.Apttus_Config2__HierarchyId__c = category.Id;
        subSubCategoryHierarchyb.Apttus_Config2__AncestorId__c = subSubCategoryHierarchy.Id;
        subSubCategoryHierarchyb.Apttus_Config2__Label__c = 'Hornimans B';
        subSubCategoryHierarchyb.Apttus_Config2__PrimordialId__c = categoryHierarchy.Id;
        insert subSubCategoryHierarchyb;
        
        Apttus_Config2__PriceList__c priceList = new Apttus_Config2__PriceList__c();
        priceList.Name = 'JDE Price List';
        priceList.Apttus_Config2__Active__c = true;
        priceList.APTS_SalesOrg__c = '0333';
        insert priceList;

        Apttus_Config2__PriceListItem__c pliCategoryProduct = new Apttus_Config2__PriceListItem__c();
        pliCategoryProduct.Apttus_Config2__PriceListId__c = priceList.id;
        pliCategoryProduct.Apttus_Config2__ProductId__c = product.id;
        pliCategoryProduct.Apttus_Config2__ListPrice__c = 0;
        pliCategoryProduct.Apttus_Config2__ChargeType__c = 'Sales Price';
        pliCategoryProduct.Apttus_Config2__PriceType__c = 'One Time';
        pliCategoryProduct.Apttus_Config2__PriceMethod__c = 'Per Unit';
        pliCategoryProduct.Apttus_Config2__Active__c = true;
        pliCategoryProduct.Apttus_Config2__BillingFrequency__c = 'One Time';
        pliCategoryProduct.Apttus_Config2__BillingRule__c = 'Bill In Advance';
        insert pliCategoryProduct;
        
        Apttus_Config2__PriceListItem__c pli = new Apttus_Config2__PriceListItem__c();
        pli.Apttus_Config2__PriceListId__c = priceList.Id;
        pli.Apttus_Config2__ProductId__c = testProduct.Id;
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
        agreement.Apttus__Account__c = objChildAccount.Id;
        insert agreement;

        Apttus__APTS_Agreement__c agreementAmendment = new Apttus__APTS_Agreement__c();
        agreementAmendment.recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        agreementAmendment.Name = 'Test Agreement Amendment';
        agreementAmendment.Apttus__Agreement_Category__c = 'Standard';
        agreementAmendment.Apttus_CMConfig__PriceListId__c = priceList.Id;
        agreementAmendment.Apttus_CMConfig__PricingDate__c = System.Today();
        agreementAmendment.Apttus__Account__c = objChildAccount.Id;
        agreementAmendment.APTS_Agreement_Request__c = 'Amendment';
        insert agreementAmendment;

        Apttus_Config2__ProductConfiguration__c agreementCartAmendment = new Apttus_Config2__ProductConfiguration__c();
        agreementCartAmendment.Name ='Sample Agreement Cart Amendment';
        agreementCartAmendment.Apttus_CMConfig__AgreementId__c = agreementAmendment.Id;
        agreementCartAmendment.Apttus_Config2__PriceListId__c = priceList.Id;
        agreementCartAmendment.Apttus_Config2__BusinessObjectType__c = 'Agreement';
        insert agreementCartAmendment;

        Apttus_Config2__LineItem__c lineItemAmendment = new Apttus_Config2__LineItem__c();
        lineItemAmendment.Apttus_Config2__ConfigurationId__c = agreementCartAmendment.Id;
        lineItemAmendment.Apttus_Config2__LineNumber__c = 1;
        lineItemAmendment.Apttus_Config2__IsPrimaryLine__c = true;
        lineItemAmendment.Apttus_Config2__PrimaryLineNumber__c = 1;
        lineItemAmendment.Apttus_Config2__ItemSequence__c = 2;
        lineItemAmendment.Apttus_Config2__ProductId__c = product.Id;
        lineItemAmendment.Apttus_Config2__PriceListId__c = priceList.Id;
        lineItemAmendment.Apttus_Config2__PriceListItemId__c = pliCategoryProduct.Id;
        lineItemAmendment.Apttus_Config2__ClassificationId__c = categoryHierarchy.Id;
        lineItemAmendment.Apttus_Config2__ListPrice__c = 11.00;
        lineItemAmendment.Apttus_Config2__BasePrice__c = 11.00;
        lineItemAmendment.Apttus_Config2__ExtendedPrice__c = 11.00;
        lineItemAmendment.Apttus_Config2__AdjustedPrice__c = 0;
        lineItemAmendment.Apttus_Config2__Comments__c = 'Added by Code';
        lineItemAmendment.APTS_Category_Level__c = 'Category';
        lineItemAmendment.Apttus_Config2__LineType__c = 'Product/Service';
        lineItemAmendment.Apttus_Config2__HasOptions__c = false;
        insert lineItemAmendment;

        Apttus_Config2__AdjustmentLineItem__c adjustmentLineItemAmendment = new Apttus_Config2__AdjustmentLineItem__c();
        adjustmentLineItemAmendment.Apttus_Config2__AdjustmentAmount__c = 1;
        adjustmentLineItemAmendment.Apttus_Config2__AdjustmentAppliesTo__c = 'Previous Price';
        adjustmentLineItemAmendment.Apttus_Config2__AdjustmentType__c = '% Discount';
        adjustmentLineItemAmendment.Apttus_Config2__LineItemId__c = lineItemAmendment.Id;
        adjustmentLineItemAmendment.Apttus_Config2__LineNumber__c = 1;
        adjustmentLineItemAmendment.Apttus_Config2__LineType__c = 'Manual';
        adjustmentLineItemAmendment.Apttus_Config2__Type__c = 'TPR';
        adjustmentLineItemAmendment.Apttus_Config2__SubType__c = 'Trade';
        insert adjustmentLineItemAmendment;

        Apttus_Config2__ProductConfiguration__c agreementCartAmendmentFinalized = new Apttus_Config2__ProductConfiguration__c();
        agreementCartAmendmentFinalized.Name ='Sample Agreement Cart Amendment Finalized';
        agreementCartAmendmentFinalized.Apttus_CMConfig__AgreementId__c = agreementAmendment.Id;
        agreementCartAmendmentFinalized.Apttus_Config2__PriceListId__c = priceList.Id;
        agreementCartAmendmentFinalized.Apttus_Config2__BusinessObjectType__c = 'Agreement';
        agreementCartAmendmentFinalized.Apttus_Config2__Status__c = 'Finalized';
        insert agreementCartAmendmentFinalized;

        Apttus_Config2__LineItem__c lineItemAmendmentFinalized  = new Apttus_Config2__LineItem__c();
        lineItemAmendmentFinalized .Apttus_Config2__ConfigurationId__c = agreementCartAmendmentFinalized.Id;
        lineItemAmendmentFinalized .Apttus_Config2__LineNumber__c = 1;
        lineItemAmendmentFinalized .Apttus_Config2__IsPrimaryLine__c = true;
        lineItemAmendmentFinalized .Apttus_Config2__PrimaryLineNumber__c = 1;
        lineItemAmendmentFinalized .Apttus_Config2__ItemSequence__c = 2;
        lineItemAmendmentFinalized .Apttus_Config2__ProductId__c = product.Id;
        lineItemAmendmentFinalized .Apttus_Config2__PriceListId__c = priceList.Id;
        lineItemAmendmentFinalized .Apttus_Config2__PriceListItemId__c = pliCategoryProduct.Id;
        lineItemAmendmentFinalized .Apttus_Config2__ClassificationId__c = categoryHierarchy.Id;
        lineItemAmendmentFinalized .Apttus_Config2__ListPrice__c = 11.00;
        lineItemAmendmentFinalized .Apttus_Config2__BasePrice__c = 11.00;
        lineItemAmendmentFinalized .Apttus_Config2__ExtendedPrice__c = 11.00;
        lineItemAmendmentFinalized .Apttus_Config2__AdjustedPrice__c = 0;
        lineItemAmendmentFinalized .Apttus_Config2__Comments__c = 'Added by Code';
        lineItemAmendmentFinalized .APTS_Category_Level__c = 'Category';
        lineItemAmendmentFinalized .Apttus_Config2__LineType__c = 'Product/Service';
        lineItemAmendmentFinalized .Apttus_Config2__HasOptions__c = false;
        insert lineItemAmendmentFinalized;

        Apttus_Config2__AdjustmentLineItem__c adjustmentLineItemAmendmentFinalized = new Apttus_Config2__AdjustmentLineItem__c();
        adjustmentLineItemAmendmentFinalized.Apttus_Config2__AdjustmentAmount__c = 1;
        adjustmentLineItemAmendmentFinalized.Apttus_Config2__AdjustmentAppliesTo__c = 'Previous Price';
        adjustmentLineItemAmendmentFinalized.Apttus_Config2__AdjustmentType__c = '% Discount';
        adjustmentLineItemAmendmentFinalized.Apttus_Config2__LineItemId__c = lineItemAmendmentFinalized.Id;
        adjustmentLineItemAmendmentFinalized.Apttus_Config2__LineNumber__c = 1;
        adjustmentLineItemAmendmentFinalized.Apttus_Config2__LineType__c = 'Manual';
        adjustmentLineItemAmendmentFinalized.Apttus_Config2__Type__c = 'TPR';
        adjustmentLineItemAmendmentFinalized.Apttus_Config2__SubType__c = 'Trade';
        insert adjustmentLineItemAmendmentFinalized;

        Apttus_Config2__ProductConfiguration__c agreementCart = new Apttus_Config2__ProductConfiguration__c();
        agreementCart.Name ='Sample Agreement Cart';
        agreementCart.Apttus_CMConfig__AgreementId__c = agreement.Id;
        agreementCart.Apttus_Config2__PriceListId__c = priceList.Id;
        agreementCart.Apttus_Config2__BusinessObjectType__c = 'Agreement';
        agreementCart.Apttus_Config2__AccountId__c = objChildAccount.Id;
        insert agreementCart;

        system.debug(Logginglevel.ERROR,'sample cart id>>>>>>>>>>>>>>' + agreementCart.Id);
        system.debug(Logginglevel.ERROR,'sample cart account id>>>>>>>>>>>>>>' + agreementCart.Apttus_Config2__AccountId__c);

        Apttus_Config2__LineItem__c lineItem = new Apttus_Config2__LineItem__c();
        lineItem.Apttus_Config2__ConfigurationId__c = agreementCart.Id;
        lineItem.Apttus_Config2__LineNumber__c = 1;
        lineItem.Apttus_Config2__IsPrimaryLine__c = true;
        lineItem.Apttus_Config2__PrimaryLineNumber__c = 1;
        lineItem.Apttus_Config2__ItemSequence__c = 2;
        lineItem.Apttus_Config2__ProductId__c = product.Id;
        lineItem.Apttus_Config2__PriceListId__c = priceList.Id;
        lineItem.Apttus_Config2__PriceListItemId__c = pliCategoryProduct.Id;
        lineItem.Apttus_Config2__ClassificationId__c = categoryHierarchy.Id;
        lineItem.Apttus_Config2__ListPrice__c = 11.00;
        lineItem.Apttus_Config2__BasePrice__c = 11.00;
        lineItem.Apttus_Config2__ExtendedPrice__c = 11.00;
        lineItem.Apttus_Config2__AdjustedPrice__c = 0;
        lineItem.Apttus_Config2__Comments__c = 'Added by Code';
        lineItem.APTS_Category_Level__c = 'Category';
        lineItem.Apttus_Config2__LineType__c = 'Product/Service';
        lineItem.Apttus_Config2__HasOptions__c = false;
        insert lineItem;

        Apttus_Config2__LineItem__c lineItemSubCategory = new Apttus_Config2__LineItem__c();
        lineItemSubCategory.Apttus_Config2__ConfigurationId__c = agreementCart.Id;
        lineItemSubCategory.Apttus_Config2__LineNumber__c = 1;
        lineItemSubCategory.Apttus_Config2__IsPrimaryLine__c = true;
        lineItemSubCategory.Apttus_Config2__PrimaryLineNumber__c = 1;
        lineItemSubCategory.Apttus_Config2__ItemSequence__c = 2;
        lineItemSubCategory.Apttus_Config2__ProductId__c = product.Id;
        lineItemSubCategory.Apttus_Config2__PriceListId__c = priceList.Id;
        lineItemSubCategory.Apttus_Config2__PriceListItemId__c = pliCategoryProduct.Id;
        lineItemSubCategory.Apttus_Config2__ClassificationId__c = categoryHierarchy.Id;
        lineItemSubCategory.APTS_Sub_Category__c = subCategoryHierarchy.Id;
        lineItemSubCategory.Apttus_Config2__ListPrice__c = 11.00;
        lineItemSubCategory.Apttus_Config2__BasePrice__c = 11.00;
        lineItemSubCategory.Apttus_Config2__ExtendedPrice__c = 11.00;
        lineItemSubCategory.Apttus_Config2__AdjustedPrice__c = 0;
        lineItemSubCategory.Apttus_Config2__Comments__c = 'Added by Code';
        lineItemSubCategory.APTS_Category_Level__c = 'Sub Category';
        lineItemSubCategory.Apttus_Config2__LineType__c = 'Product/Service';
        lineItemSubCategory.Apttus_Config2__HasOptions__c = false;
        insert lineItemSubCategory;

        Apttus_Config2__LineItem__c lineItemSubSubCategory = new Apttus_Config2__LineItem__c();
        lineItemSubSubCategory.Apttus_Config2__ConfigurationId__c = agreementCart.Id;
        lineItemSubSubCategory.Apttus_Config2__LineNumber__c = 1;
        lineItemSubSubCategory.Apttus_Config2__IsPrimaryLine__c = true;
        lineItemSubSubCategory.Apttus_Config2__PrimaryLineNumber__c = 1;
        lineItemSubSubCategory.Apttus_Config2__ItemSequence__c = 2;
        lineItemSubSubCategory.Apttus_Config2__ProductId__c = product.Id;
        lineItemSubSubCategory.Apttus_Config2__PriceListId__c = priceList.Id;
        lineItemSubSubCategory.Apttus_Config2__PriceListItemId__c = pliCategoryProduct.Id;
        lineItemSubSubCategory.Apttus_Config2__ClassificationId__c = categoryHierarchy.Id;
        lineItemSubSubCategory.APTS_Sub_Category__c = subCategoryHierarchy.Id;
        lineItemSubSubCategory.APTS_Sub_Category__c = subSubCategoryHierarchy.Id;
        lineItemSubSubCategory.Apttus_Config2__ListPrice__c = 11.00;
        lineItemSubSubCategory.Apttus_Config2__BasePrice__c = 11.00;
        lineItemSubSubCategory.Apttus_Config2__ExtendedPrice__c = 11.00;
        lineItemSubSubCategory.Apttus_Config2__AdjustedPrice__c = 0;
        lineItemSubSubCategory.Apttus_Config2__Comments__c = 'Added by Code';
        lineItemSubSubCategory.APTS_Category_Level__c = 'Sub Sub Category';
        lineItemSubSubCategory.Apttus_Config2__LineType__c = 'Product/Service';
        lineItemSubSubCategory.Apttus_Config2__HasOptions__c = false;
        insert lineItemSubSubCategory;

        Apttus_Config2__LineItem__c lineItem2 = new Apttus_Config2__LineItem__c();
        lineItem2.Apttus_Config2__ConfigurationId__c = agreementCart.Id;
        lineItem2.Apttus_Config2__LineNumber__c = 1;
        lineItem2.Apttus_Config2__IsPrimaryLine__c = true;
        lineItem2.Apttus_Config2__PrimaryLineNumber__c = 1;
        lineItem2.Apttus_Config2__ItemSequence__c = 2;
        lineItem2.Apttus_Config2__ProductId__c = testProduct.Id;
        lineItem2.Apttus_Config2__PriceListId__c = priceList.Id;
        lineItem2.Apttus_Config2__PriceListItemId__c = pli.Id;
        lineItem2.Apttus_Config2__ClassificationId__c = categoryHierarchyb.Id;
        lineItem2.Apttus_Config2__ListPrice__c = 11.00;
        lineItem2.Apttus_Config2__BasePrice__c = 11.00;
        lineItem2.Apttus_Config2__ExtendedPrice__c = 11.00;
        lineItem2.Apttus_Config2__AdjustedPrice__c = 0;
        lineItem2.Apttus_Config2__Comments__c = 'Added by Code';
        lineItem2.APTS_Category_Level__c = 'Category';
        lineItem2.Apttus_Config2__LineType__c = 'Product/Service';
        lineItem2.Apttus_Config2__HasOptions__c = false;
        insert lineItem2;

        Apttus_Config2__LineItem__c lineItem3 = new Apttus_Config2__LineItem__c();
        lineItem3.Apttus_Config2__ConfigurationId__c = agreementCart.Id;
        lineItem3.Apttus_Config2__LineNumber__c = 1;
        lineItem3.Apttus_Config2__IsPrimaryLine__c = true;
        lineItem3.Apttus_Config2__PrimaryLineNumber__c = 1;
        lineItem3.Apttus_Config2__ItemSequence__c = 2;
        lineItem3.Apttus_Config2__ProductId__c = product.Id;
        lineItem3.Apttus_Config2__PriceListId__c = priceList.Id;
        lineItem3.Apttus_Config2__PriceListItemId__c = pliCategoryProduct.Id;
        lineItem3.Apttus_Config2__ClassificationId__c = categoryHierarchy.Id;
        lineItem3.APTS_Sub_Category__c = subCategoryHierarchy.Id;
        lineItem3.Apttus_Config2__ListPrice__c = 11.00;
        lineItem3.Apttus_Config2__BasePrice__c = 11.00;
        lineItem3.Apttus_Config2__ExtendedPrice__c = 11.00;
        lineItem3.Apttus_Config2__AdjustedPrice__c = 0;
        lineItem3.Apttus_Config2__Comments__c = 'Added by Code';
        lineItem3.APTS_Category_Level__c = 'Sub Category';
        insert lineItem3;

        Apttus_Config2__LineItem__c lineItem4 = new Apttus_Config2__LineItem__c();
        lineItem4.Apttus_Config2__ConfigurationId__c = agreementCart.Id;
        lineItem4.Apttus_Config2__LineNumber__c = 1;
        lineItem4.Apttus_Config2__IsPrimaryLine__c = true;
        lineItem4.Apttus_Config2__PrimaryLineNumber__c = 1;
        lineItem4.Apttus_Config2__ItemSequence__c = 2;
        lineItem4.Apttus_Config2__ProductId__c = testProduct.Id;
        lineItem4.Apttus_Config2__PriceListId__c = priceList.Id;
        lineItem4.Apttus_Config2__PriceListItemId__c = pli.Id;
        lineItem4.Apttus_Config2__ClassificationId__c = subCategoryHierarchyb.Id;
        lineItem4.Apttus_Config2__ListPrice__c = 11.00;
        lineItem4.Apttus_Config2__BasePrice__c = 11.00;
        lineItem4.Apttus_Config2__ExtendedPrice__c = 11.00;
        lineItem4.Apttus_Config2__AdjustedPrice__c = 0;
        lineItem4.Apttus_Config2__Comments__c = 'Added by Code';
        insert lineItem4;

        Apttus_Config2__LineItem__c lineItemSubSubCategoryProduct = new Apttus_Config2__LineItem__c();
        lineItemSubSubCategoryProduct.Apttus_Config2__ConfigurationId__c = agreementCart.Id;
        lineItemSubSubCategoryProduct.Apttus_Config2__LineNumber__c = 1;
        lineItemSubSubCategoryProduct.Apttus_Config2__IsPrimaryLine__c = true;
        lineItemSubSubCategoryProduct.Apttus_Config2__PrimaryLineNumber__c = 1;
        lineItemSubSubCategoryProduct.Apttus_Config2__ItemSequence__c = 2;
        lineItemSubSubCategoryProduct.Apttus_Config2__ProductId__c = product.Id;
        lineItemSubSubCategoryProduct.Apttus_Config2__PriceListId__c = priceList.Id;
        lineItemSubSubCategoryProduct.Apttus_Config2__PriceListItemId__c = pliCategoryProduct.Id;
        lineItemSubSubCategoryProduct.Apttus_Config2__ClassificationId__c = categoryHierarchy.Id;
        lineItemSubSubCategoryProduct.APTS_Sub_Category__c = subCategoryHierarchy.Id;
        lineItemSubSubCategoryProduct.APTS_Sub_Category__c = categoryHierarchy.Id;
        lineItemSubSubCategoryProduct.Apttus_Config2__ListPrice__c = 11.00;
        lineItemSubSubCategoryProduct.Apttus_Config2__BasePrice__c = 11.00;
        lineItemSubSubCategoryProduct.Apttus_Config2__ExtendedPrice__c = 11.00;
        lineItemSubSubCategoryProduct.Apttus_Config2__AdjustedPrice__c = 0;
        lineItemSubSubCategoryProduct.Apttus_Config2__Comments__c = 'Added by Code';
        lineItemSubSubCategoryProduct.APTS_Category_Level__c = 'Sub Sub Category';
        insert lineItemSubSubCategoryProduct;

        Apttus_Config2__LineItem__c lineItem5 = new Apttus_Config2__LineItem__c();
        lineItem5.Apttus_Config2__ConfigurationId__c = agreementCart.Id;
        lineItem5.Apttus_Config2__LineNumber__c = 1;
        lineItem5.Apttus_Config2__IsPrimaryLine__c = true;
        lineItem5.Apttus_Config2__PrimaryLineNumber__c = 1;
        lineItem5.Apttus_Config2__ItemSequence__c = 2;
        lineItem5.Apttus_Config2__ProductId__c = testProduct.Id;
        lineItem5.Apttus_Config2__PriceListId__c = priceList.Id;
        lineItem5.Apttus_Config2__PriceListItemId__c = pli.Id;
        lineItem5.Apttus_Config2__ClassificationId__c = subSubCategoryHierarchyb.Id;
        lineItem5.Apttus_Config2__ListPrice__c = 11.00;
        lineItem5.Apttus_Config2__BasePrice__c = 11.00;
        lineItem5.Apttus_Config2__ExtendedPrice__c = 11.00;
        lineItem5.Apttus_Config2__AdjustedPrice__c = 0;
        lineItem5.Apttus_Config2__Comments__c = 'Added by Code';
        insert lineItem5;

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

        Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem2 = new Apttus_Config2__AdjustmentLineItem__c();
        adjustmentLineItem2.Apttus_Config2__AdjustmentAmount__c = 1;
        adjustmentLineItem2.Apttus_Config2__AdjustmentAppliesTo__c = 'Previous Price';
        adjustmentLineItem2.Apttus_Config2__AdjustmentType__c = '% Discount';
        adjustmentLineItem2.Apttus_Config2__LineItemId__c = lineItem2.Id;
        adjustmentLineItem2.Apttus_Config2__LineNumber__c = 1;
        adjustmentLineItem2.Apttus_Config2__LineType__c = 'Manual';
        adjustmentLineItem2.Apttus_Config2__Type__c = 'TPR';
        adjustmentLineItem2.Apttus_Config2__SubType__c = 'Trade';
        insert adjustmentLineItem2;

        Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem3 = new Apttus_Config2__AdjustmentLineItem__c();
        adjustmentLineItem3.Apttus_Config2__AdjustmentAmount__c = 1;
        adjustmentLineItem3.Apttus_Config2__AdjustmentAppliesTo__c = 'Previous Price';
        adjustmentLineItem3.Apttus_Config2__AdjustmentType__c = '% Discount';
        adjustmentLineItem3.Apttus_Config2__LineItemId__c = lineItem3.Id;
        adjustmentLineItem3.Apttus_Config2__LineNumber__c = 1;
        adjustmentLineItem3.Apttus_Config2__LineType__c = 'Manual';
        adjustmentLineItem3.Apttus_Config2__Type__c = 'PPR';
        adjustmentLineItem3.Apttus_Config2__SubType__c = 'Trade';
        insert adjustmentLineItem3;

        Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem4 = new Apttus_Config2__AdjustmentLineItem__c();
        adjustmentLineItem4.Apttus_Config2__AdjustmentAmount__c = 1;
        adjustmentLineItem4.Apttus_Config2__AdjustmentAppliesTo__c = 'Previous Price';
        adjustmentLineItem4.Apttus_Config2__AdjustmentType__c = '% Discount';
        adjustmentLineItem4.Apttus_Config2__LineItemId__c = lineItemSubCategory.Id;
        adjustmentLineItem4.Apttus_Config2__LineNumber__c = 1;
        adjustmentLineItem4.Apttus_Config2__LineType__c = 'Manual';
        adjustmentLineItem4.Apttus_Config2__Type__c = 'TPR';
        adjustmentLineItem4.Apttus_Config2__SubType__c = 'Trade';
        insert adjustmentLineItem4;

        Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem5 = new Apttus_Config2__AdjustmentLineItem__c();
        adjustmentLineItem5.Apttus_Config2__AdjustmentAmount__c = 1;
        adjustmentLineItem5.Apttus_Config2__AdjustmentAppliesTo__c = 'Previous Price';
        adjustmentLineItem5.Apttus_Config2__AdjustmentType__c = '% Discount';
        adjustmentLineItem5.Apttus_Config2__LineItemId__c = lineItem4.Id;
        adjustmentLineItem5.Apttus_Config2__LineNumber__c = 1;
        adjustmentLineItem5.Apttus_Config2__LineType__c = 'Manual';
        adjustmentLineItem5.Apttus_Config2__Type__c = 'PPR';
        adjustmentLineItem5.Apttus_Config2__SubType__c = 'Trade';
        insert adjustmentLineItem5;

        Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem6 = new Apttus_Config2__AdjustmentLineItem__c();
        adjustmentLineItem6.Apttus_Config2__AdjustmentAmount__c = 1;
        adjustmentLineItem6.Apttus_Config2__AdjustmentAppliesTo__c = 'Previous Price';
        adjustmentLineItem6.Apttus_Config2__AdjustmentType__c = '% Discount';
        adjustmentLineItem6.Apttus_Config2__LineItemId__c = lineItemSubSubCategory.Id;
        adjustmentLineItem6.Apttus_Config2__LineNumber__c = 1;
        adjustmentLineItem6.Apttus_Config2__LineType__c = 'Manual';
        adjustmentLineItem6.Apttus_Config2__Type__c = 'TPR';
        adjustmentLineItem6.Apttus_Config2__SubType__c = 'Trade';
        insert adjustmentLineItem6;

        Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem7 = new Apttus_Config2__AdjustmentLineItem__c();
        adjustmentLineItem7.Apttus_Config2__AdjustmentAmount__c = 1;
        adjustmentLineItem7.Apttus_Config2__AdjustmentAppliesTo__c = 'Previous Price';
        adjustmentLineItem7.Apttus_Config2__AdjustmentType__c = '% Discount';
        adjustmentLineItem7.Apttus_Config2__LineItemId__c = lineItem5.Id;
        adjustmentLineItem7.Apttus_Config2__LineNumber__c = 1;
        adjustmentLineItem7.Apttus_Config2__LineType__c = 'Manual';
        adjustmentLineItem7.Apttus_Config2__Type__c = 'PPR';
        adjustmentLineItem7.Apttus_Config2__SubType__c = 'Trade';
        insert adjustmentLineItem7;
        
        CERDiscountCache__c cac=new CERDiscountCache__c();
        cac.Name=lineItem5.Id+adjustmentLineItem7.Apttus_Config2__SubType__c;
        cac.Sub_Type__c=adjustmentLineItem7.Apttus_Config2__SubType__c;
        cac.Name__c=adjustmentLineItem7.Apttus_Config2__LineItemId__c;
        cac.Configuration__c=adjustmentLineItem7.Apttus_Config2__LineItemId__r.Apttus_Config2__ConfigurationId__c;
        insert cac;


        APTS_Contract_Entitlement_Repository__c CER1 = new APTS_Contract_Entitlement_Repository__c();
        CER1.APTS_Sold_to_Party__c = objChildAccount.Id;
        CER1.APTS_CategoryCER__c = categoryHierarchy.Id;
        CER1.APTS_Contributing_Agreement__c = agreement.Id;
        CER1.APTS_Agreement_Type__c = 'Standard Deal';
        CER1.APTS_Product__c = product.Id;
        CER1.APTS_Category_Level__c = 'Category';
        CER1.APTS_Is_Pending__c = true;
        CER1.APTS_Pending_Adjustment_Line_Item__c = adjustmentLineItem.Id;
        CER1.APTS_Adjustment_Value__c = 1;
        insert CER1;

        APTS_Contract_Entitlement_Repository__c CER2 = new APTS_Contract_Entitlement_Repository__c();
        CER2.APTS_Sold_to_Party__c = objChildAccount.Id;
        CER2.APTS_CategoryCER__c = categoryHierarchy.Id;
        CER2.APTS_Sub_Category__c = subCategoryHierarchy.Id;
        CER2.APTS_Contributing_Agreement__c = agreement.Id;
        CER2.APTS_Agreement_Type__c = 'Standard Deal';
        CER2.APTS_Product__c = product.Id;
        CER2.APTS_Category_Level__c = 'Sub Category';
        CER2.APTS_Is_Pending__c = true;
        CER2.APTS_Pending_Adjustment_Line_Item__c = adjustmentLineItem2.Id;
        CER2.APTS_Adjustment_Value__c = 1;
        insert CER2;

        APTS_Contract_Entitlement_Repository__c CER3 = new APTS_Contract_Entitlement_Repository__c();
        CER3.APTS_Sold_to_Party__c = objChildAccount.Id;
        CER3.APTS_CategoryCER__c = categoryHierarchy.Id;
        CER3.APTS_Sub_Category__c = subCategoryHierarchy.Id;
        CER3.APTS_Sub_Sub_Category__c = subSubcategoryHierarchy.Id;
        CER3.APTS_Contributing_Agreement__c = agreement.Id;
        CER3.APTS_Agreement_Type__c = 'Standard Deal';
        CER3.APTS_Product__c = product.Id;
        CER3.APTS_Category_Level__c = 'Sub Sub Category';
        CER3.APTS_Is_Pending__c = true;
        CER3.APTS_Pending_Adjustment_Line_Item__c = adjustmentLineItem3.Id;
        CER3.APTS_Adjustment_Value__c = 1;
        insert CER3;

        APTS_AgreementTotalVolumeObligation__c sobj = new APTS_AgreementTotalVolumeObligation__c(
        APTS_Agreement__c= agreement.Id,
        APTS_Value__c = subCategoryHierarchy.Id,                  
        APTS_VolumeAssumption__c = 5000 );
        insert sobj;
        APTS_AgreementTotalVolumeObligation__c sobj1 = new APTS_AgreementTotalVolumeObligation__c(
        APTS_Agreement__c= agreement.Id,
        APTS_Value__c = categoryHierarchy.Id,                  
        APTS_VolumeAssumption__c = 5000 );
        insert sobj1;
        APTS_AgreementTotalVolumeObligation__c sobj2 = new APTS_AgreementTotalVolumeObligation__c(
        APTS_Agreement__c= agreement.Id,
        APTS_Value__c = subSubcategoryHierarchy.Id,                  
        APTS_VolumeAssumption__c = 5000 );
        insert sobj2;
    }

    @isTest
    static void test_getCategoryProducts(){
        List<Product2> lstProducts = [SELECT Id FROM Product2];
        List<Account> lstAccounts = [SELECT Id FROM Account];
        List<Apttus_Config2__ClassificationHierarchy__c> lstCH = [SELECT Id, Name,Apttus_Config2__Level__c FROM Apttus_Config2__ClassificationHierarchy__c WHERE Name = 'Tea'];
        List<Apttus_Config2__ClassificationHierarchy__c> lstCHSub = [SELECT Id, Name,Apttus_Config2__Level__c FROM Apttus_Config2__ClassificationHierarchy__c WHERE Name = 'Other Tea Brands'];
        List<Apttus_Config2__ClassificationHierarchy__c> lstCHSubSub = [SELECT Id, Name,Apttus_Config2__Level__c FROM Apttus_Config2__ClassificationHierarchy__c WHERE Name = 'Hornimans'];

        Test.startTest();
        APTS_CategoryBasedAdjustmentsCtrl acb=new APTS_CategoryBasedAdjustmentsCtrl();
        APTS_Cercachedeletion cerc=new APTS_Cercachedeletion(acb);
            cerc.Deletecercache();
            APTS_CategoryBasedAdjustmentsHelper.getCategoryProducts(lstAccounts[0].Id, lstProducts[0].Id, 'Category', lstCH[0].Id, lstCHSub[0].Id, lstCHSubSub[0].Id, true);
        Test.stopTest();
    }

    static testMethod void test_getAdjustmentsStructure(){
        List<Product2> lstProducts = [SELECT Id FROM Product2 WHERE Name = 'Category Product'];
        List<Apttus_Config2__ProductConfiguration__c> lstPC = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c WHERE Name = 'Sample Agreement Cart'];

        system.debug(Logginglevel.ERROR,'sample cart id test method>>>>>>>>>>>>>>' + lstPC[0].Id);        
        
        Test.startTest();
            Map<Id,List<Apttus_Config2__AdjustmentLineItem__c>> mapNewCategoryAdjustments =  APTS_CategoryBasedAdjustmentsHelper.getAdjustmentsStructure(lstPC[0].Id, lstProducts[0].Id);

            System.assertEquals(mapNewCategoryAdjustments.isEmpty(),false);

            APTS_CategoryBasedAdjustmentsHelper.createNewAdjustments(mapNewCategoryAdjustments, lstPC[0].Id);
        Test.stopTest();
    }

    @isTest
    static void test_calculateECDA(){
        List<Apttus_Config2__ProductConfiguration__c> lstPC = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c];
        List<Account> lstAccounts = [SELECT Id FROM Account];

        Test.startTest();
            APTS_CategoryBasedAdjustmentsHelper.calculateECDA(lstAccounts[0].Id, lstPC[0].Id);
        Test.stopTest();
    }

    @isTest
    static void test_validateCERAmendment(){
        List<Apttus_Config2__ProductConfiguration__c> lstPC = [SELECT Id,Apttus_CMConfig__AgreementId__c FROM Apttus_Config2__ProductConfiguration__c WHERE Name = 'Sample Agreement Cart Amendment'];

        Test.startTest();
            APTS_CategoryBasedAdjustmentsHelper.validateCERAmendment(lstPC[0].Id,lstPC[0].Apttus_CMConfig__AgreementId__c);
        Test.stopTest();
    }

    @isTest
    static void test_getListCERAmendment(){
        List<Apttus__APTS_Agreement__c> lstAgreement = [SELECT Id FROM Apttus__APTS_Agreement__c WHERE Name = 'Test Agreement Amendment'];
        List<Product2> lstProducts = [SELECT Id FROM Product2 WHERE Name = 'Category Product'];

        Test.startTest();
            APTS_CategoryBasedAdjustmentsHelper.getListCERAmendment(lstAgreement[0].Id, lstProducts[0].Id,
            null, null, null, 'TPR', 'Trade');
        Test.stopTest();
    }

    @isTest
    static void test_createNewCERAmendment(){
        List<Apttus__APTS_Agreement__c> lstAgreement = [SELECT Id,Apttus__Account__c FROM Apttus__APTS_Agreement__c WHERE Name = 'Test Agreement'];
        List<Product2> lstProducts = [SELECT Id FROM Product2 WHERE Name = 'Category Product'];
        List<Apttus_Config2__ClassificationHierarchy__c> lstCH = [SELECT Id, Name FROM Apttus_Config2__ClassificationHierarchy__c WHERE Name = 'Tea'];

        List<APTS_Contract_Entitlement_Repository__c> lstCERUpdate = [SELECT Id, APTS_CER_Changed_Amendment__c FROM APTS_Contract_Entitlement_Repository__c];

        for(APTS_Contract_Entitlement_Repository__c current : lstCERUpdate){
            current.APTS_CER_Changed_Amendment__c = true;
        }

        update lstCERUpdate;

        List<APTS_Contract_Entitlement_Repository__c> lstCER = APTS_CategoryBasedAdjustmentsHelper.getCERRecord(lstAgreement[0].Apttus__Account__c, lstProducts[0].Id,
        lstCH[0].Id, null, null, null, null);
        
        Test.startTest();
            APTS_CategoryBasedAdjustmentsHelper.createNewCERAmendment(lstCER[0].Id, lstAgreement[0].Id, 10, lstAgreement[0].Apttus__Account__c);
        Test.stopTest();
    }
}