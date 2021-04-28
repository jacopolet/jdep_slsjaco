@isTest
private class APTS_CategoryBasedAdjustmentsTest
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
        agreement.Apttus__Account__c = objChildAccount.Id;
        insert agreement;

        Apttus_Config2__ProductConfiguration__c agreementCart = new Apttus_Config2__ProductConfiguration__c();
        agreementCart.Name ='Sample Agreement Cart';
        agreementCart.Apttus_CMConfig__AgreementId__c = agreement.Id;
        agreementCart.Apttus_Config2__PriceListId__c = priceList.Id;
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

        Apttus_Config2__LineItem__c lineItem2 = new Apttus_Config2__LineItem__c();
        lineItem2.Apttus_Config2__ConfigurationId__c = agreementCart.Id;
        lineItem2.Apttus_Config2__LineNumber__c = 1;
        lineItem2.Apttus_Config2__IsPrimaryLine__c = true;
        lineItem2.Apttus_Config2__PrimaryLineNumber__c = 1;
        lineItem2.Apttus_Config2__ItemSequence__c = 2;
        lineItem2.Apttus_Config2__ProductId__c = product.Id;
        lineItem2.Apttus_Config2__PriceListId__c = priceList.Id;
        lineItem2.Apttus_Config2__PriceListItemId__c = priceListItem.Id;
        lineItem2.Apttus_Config2__ClassificationId__c = categoryHierarchy.Id;
        lineItem2.APTS_Sub_Category__c = subCategoryHierarchy.Id;
        lineItem2.APTS_Sub_Sub_Category__c = subSubcategoryHierarchy.Id;
        lineItem2.Apttus_Config2__ListPrice__c = 11.00;
        lineItem2.Apttus_Config2__BasePrice__c = 11.00;
        lineItem2.Apttus_Config2__ExtendedPrice__c = 11.00;
        lineItem2.Apttus_Config2__AdjustedPrice__c = 0;
        lineItem2.Apttus_Config2__Comments__c = 'Added by Code';
        lineItem2.APTS_Category_Level__c = 'Sub Category';
        insert lineItem2;

        Apttus_Config2__LineItem__c lineItem3 = new Apttus_Config2__LineItem__c();
        lineItem3.Apttus_Config2__ConfigurationId__c = agreementCart.Id;
        lineItem3.Apttus_Config2__LineNumber__c = 1;
        lineItem3.Apttus_Config2__IsPrimaryLine__c = true;
        lineItem3.Apttus_Config2__PrimaryLineNumber__c = 1;
        lineItem3.Apttus_Config2__ItemSequence__c = 2;
        lineItem3.Apttus_Config2__ProductId__c = product.Id;
        lineItem3.Apttus_Config2__PriceListId__c = priceList.Id;
        lineItem3.Apttus_Config2__PriceListItemId__c = priceListItem.Id;
        lineItem3.Apttus_Config2__ClassificationId__c = categoryHierarchy.Id;
        lineItem3.APTS_Sub_Category__c = subCategoryHierarchy.Id;
        lineItem3.APTS_Sub_Sub_Category__c = subSubcategoryHierarchy.Id;
        lineItem3.Apttus_Config2__ListPrice__c = 11.00;
        lineItem3.Apttus_Config2__BasePrice__c = 11.00;
        lineItem3.Apttus_Config2__ExtendedPrice__c = 11.00;
        lineItem3.Apttus_Config2__AdjustedPrice__c = 0;
        lineItem3.Apttus_Config2__Comments__c = 'Added by Code';
        lineItem3.APTS_Category_Level__c = 'Sub Sub Category';
        insert lineItem3;

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

        Apttus_Config2__AdjustmentLineItem__c adjustmentLineItemA = new Apttus_Config2__AdjustmentLineItem__c();
        adjustmentLineItemA.Apttus_Config2__AdjustmentAmount__c = 1;
        adjustmentLineItemA.Apttus_Config2__AdjustmentAppliesTo__c = 'Previous Price';
        adjustmentLineItemA.Apttus_Config2__AdjustmentType__c = '% Discount';
        adjustmentLineItemA.Apttus_Config2__LineItemId__c = lineItem.Id;
        adjustmentLineItemA.Apttus_Config2__LineNumber__c = 1;
        adjustmentLineItemA.Apttus_Config2__LineType__c = 'Manual';
        adjustmentLineItemA.Apttus_Config2__Type__c = 'TPR';
        adjustmentLineItemA.Apttus_Config2__SubType__c = 'Trade';
        insert adjustmentLineItemA;

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
        adjustmentLineItem3.Apttus_Config2__Type__c = 'TPR';
        adjustmentLineItem3.Apttus_Config2__SubType__c = 'Trade';
        insert adjustmentLineItem3;

        Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem4 = new Apttus_Config2__AdjustmentLineItem__c();
        adjustmentLineItem4.Apttus_Config2__AdjustmentAmount__c = 1;
        adjustmentLineItem4.Apttus_Config2__AdjustmentAppliesTo__c = 'Previous Price';
        adjustmentLineItem4.Apttus_Config2__AdjustmentType__c = '% Discount';
        adjustmentLineItem4.Apttus_Config2__LineItemId__c = lineItem.Id;
        adjustmentLineItem4.Apttus_Config2__LineNumber__c = 1;
        adjustmentLineItem4.Apttus_Config2__LineType__c = 'Manual';
        adjustmentLineItem4.Apttus_Config2__Type__c = 'BMC';
        adjustmentLineItem4.Apttus_Config2__SubType__c = 'Trade';
        insert adjustmentLineItem4;

        Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem5 = new Apttus_Config2__AdjustmentLineItem__c();
        adjustmentLineItem5.Apttus_Config2__AdjustmentAmount__c = 1;
        adjustmentLineItem5.Apttus_Config2__AdjustmentAppliesTo__c = 'Previous Price';
        adjustmentLineItem5.Apttus_Config2__AdjustmentType__c = '% Discount';
        adjustmentLineItem5.Apttus_Config2__LineItemId__c = lineItem2.Id;
        adjustmentLineItem5.Apttus_Config2__LineNumber__c = 1;
        adjustmentLineItem5.Apttus_Config2__LineType__c = 'Manual';
        adjustmentLineItem5.Apttus_Config2__Type__c = 'BMC';
        adjustmentLineItem5.Apttus_Config2__SubType__c = 'Trade';
        insert adjustmentLineItem5;

        Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem6 = new Apttus_Config2__AdjustmentLineItem__c();
        adjustmentLineItem6.Apttus_Config2__AdjustmentAmount__c = 1;
        adjustmentLineItem6.Apttus_Config2__AdjustmentAppliesTo__c = 'Previous Price';
        adjustmentLineItem6.Apttus_Config2__AdjustmentType__c = '% Discount';
        adjustmentLineItem6.Apttus_Config2__LineItemId__c = lineItem3.Id;
        adjustmentLineItem6.Apttus_Config2__LineNumber__c = 1;
        adjustmentLineItem6.Apttus_Config2__LineType__c = 'Manual';
        adjustmentLineItem6.Apttus_Config2__Type__c = 'BMC';
        adjustmentLineItem6.Apttus_Config2__SubType__c = 'Trade';
        insert adjustmentLineItem6;

        Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem7 = new Apttus_Config2__AdjustmentLineItem__c();
        adjustmentLineItem7.Apttus_Config2__AdjustmentAmount__c = 1;
        adjustmentLineItem7.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 5';
        adjustmentLineItem7.Apttus_Config2__AdjustmentType__c = '% Discount';
        adjustmentLineItem7.Apttus_Config2__LineItemId__c = lineItem3.Id;
        adjustmentLineItem7.Apttus_Config2__LineNumber__c = 1;
        adjustmentLineItem7.Apttus_Config2__LineType__c = 'Manual';
        adjustmentLineItem7.Apttus_Config2__Type__c = 'YOCI';
        adjustmentLineItem7.Apttus_Config2__SubType__c = 'YOCI';
        insert adjustmentLineItem7;


        
        CERDiscountCache__c cac=new CERDiscountCache__c();
        cac.Name=lineItem3.Id+adjustmentLineItem6.Apttus_Config2__SubType__c;
        cac.Sub_Type__c=adjustmentLineItem6.Apttus_Config2__SubType__c;
        cac.Name__c=adjustmentLineItem6.Apttus_Config2__LineItemId__c;
        cac.Configuration__c=adjustmentLineItem6.Apttus_Config2__LineItemId__r.Apttus_Config2__ConfigurationId__c;
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
        insert CER3;

        APTS_Contract_Entitlement_Repository__c CER4 = new APTS_Contract_Entitlement_Repository__c();
        CER4.APTS_Sold_to_Party__c = objChildAccount.Id;
        CER4.APTS_CategoryCER__c = categoryHierarchy.Id;
        CER4.APTS_Contributing_Agreement__c = agreement.Id;
        CER4.APTS_Agreement_Type__c = 'Standard Deal';
        CER4.APTS_Product__c = product.Id;
        CER4.APTS_Category_Level__c = 'Category';
        CER4.APTS_Is_Pending__c = true;
        CER4.APTS_Pending_Adjustment_Line_Item__c = adjustmentLineItem4.Id;
        insert CER4;

        APTS_Contract_Entitlement_Repository__c CER5 = new APTS_Contract_Entitlement_Repository__c();
        CER5.APTS_Sold_to_Party__c = objChildAccount.Id;
        CER5.APTS_CategoryCER__c = categoryHierarchy.Id;
        CER5.APTS_Sub_Category__c = subCategoryHierarchy.Id;
        CER5.APTS_Contributing_Agreement__c = agreement.Id;
        CER5.APTS_Agreement_Type__c = 'Standard Deal';
        CER5.APTS_Product__c = product.Id;
        CER5.APTS_Category_Level__c = 'Sub Category';
        CER5.APTS_Is_Pending__c = true;
        CER5.APTS_Pending_Adjustment_Line_Item__c = adjustmentLineItem5.Id;
        insert CER5;

        APTS_Contract_Entitlement_Repository__c CER6 = new APTS_Contract_Entitlement_Repository__c();
        CER6.APTS_Sold_to_Party__c = objChildAccount.Id;
        CER6.APTS_CategoryCER__c = categoryHierarchy.Id;
        CER6.APTS_Sub_Category__c = subCategoryHierarchy.Id;
        CER6.APTS_Sub_Sub_Category__c = subSubcategoryHierarchy.Id;
        CER6.APTS_Contributing_Agreement__c = agreement.Id;
        CER6.APTS_Agreement_Type__c = 'Standard Deal';
        CER6.APTS_Product__c = product.Id;
        CER6.APTS_Category_Level__c = 'Sub Sub Category';
        CER6.APTS_Is_Pending__c = true;
        CER6.APTS_Pending_Adjustment_Line_Item__c = adjustmentLineItem6.Id;
        insert CER6;

        APTS_Contract_Entitlement_Repository__c CER7 = new APTS_Contract_Entitlement_Repository__c();
        CER7.APTS_Sold_to_Party__c = objChildAccount.Id;
        CER7.APTS_CategoryCER__c = categoryHierarchy.Id;
        CER7.APTS_Sub_Category__c = subCategoryHierarchy.Id;
        CER7.APTS_Sub_Sub_Category__c = subSubcategoryHierarchy.Id;
        CER7.APTS_Contributing_Agreement__c = agreement.Id;
        CER7.APTS_Agreement_Type__c = 'Standard Deal';
        CER7.APTS_Product__c = product.Id;
        CER7.APTS_Category_Level__c = 'Sub Sub Category';
        CER7.APTS_Is_Pending__c = true;
        CER7.APTS_Pending_Adjustment_Line_Item__c = adjustmentLineItem.Id;
        insert CER7;

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
    static void test1()
    {
        List<Apttus_Config2__ProductConfiguration__c> lstPC = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];
        List<Apttus_Config2__ClassificationHierarchy__c> lstCH = [SELECT Id, Name FROM Apttus_Config2__ClassificationHierarchy__c WHERE Name = 'Tea'];
        List<Apttus_Config2__ClassificationHierarchy__c> lstCHSub = [SELECT Id, Name FROM Apttus_Config2__ClassificationHierarchy__c WHERE Name = 'Other Tea Brands'];
        List<Apttus_Config2__ClassificationHierarchy__c> lstCHSubSub = [SELECT Id, Name FROM Apttus_Config2__ClassificationHierarchy__c WHERE Name = 'Hornimans'];

        PageReference pr = Page.APTS_CategoryBasedAdjustments;
        pr.getParameters().put('Id', String.valueOf(lstPC[0].Id));
        pr.getParameters().put('index', '0');

        Test.startTest();
            Test.setCurrentPage(pr);
            APTS_CategoryBasedAdjustmentsCtrl objCtrl = new APTS_CategoryBasedAdjustmentsCtrl();
            objCtrl.getCategoryPicklist();
            objCtrl.getDiscountTypes();
            objCtrl.getSubTypes();
            objCtrl.getAdjTypes();
            objCtrl.getUomTypes();            
            objCtrl.addNewCategoryAdjustmentLine();
            objCtrl.addNewSubCategoryAdjustmentLine();
            objCtrl.addNewSubSubCategoryAdjustmentLine();
           
            objCtrl.listCategoryAdjustmentLines[0].levelId = lstCH[0].Id;
            objCtrl.listCategoryAdjustmentLines[0].oAdjustmentLineItem.Apttus_Config2__Type__c = lstCH[0].Id;
            objCtrl.listCategoryAdjustmentLines[0].oAdjustmentLineItem.Apttus_Config2__AdjustmentAmount__c = 1;
            objCtrl.listCategoryAdjustmentLines[0].oAdjustmentLineItem.Apttus_Config2__AdjustmentUom__c = 'SAP_EA';
            
            objCtrl.listSubCategoryAdjustmentLines[0].sCategoryId = lstCHSub[0].Id;
            objCtrl.listSubSubCategoryAdjustmentLines[0].sCategoryId = lstCHSub[0].Id;
            objCtrl.listSubSubCategoryAdjustmentLines[0].sSubCategoryId = lstCHSubSub[0].Id;
            objCtrl.changeSubCatForLine();
            objCtrl.changeSSCSubCatForLine();
            objCtrl.changeSSCSubSubCatForLine();
            //objCtrl.save();
            APTS_Cercachedeletion cerc=new APTS_Cercachedeletion(objCtrl);
            cerc.Deletecercache();
        Test.stopTest();
    }    

    @isTest
    static void test2()
    {
        List<Apttus_Config2__ProductConfiguration__c> lstPC = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];
        PageReference pr = Page.APTS_CategoryBasedAdjustments;
        pr.getParameters().put('Id', String.valueOf(lstPC[0].Id));
        pr.getParameters().put('index', '0');

        Test.startTest();
            Test.setCurrentPage(pr);
            APTS_CategoryBasedAdjustmentsCtrl objCtrl = new APTS_CategoryBasedAdjustmentsCtrl();
            //objCtrl.populateExistingAdjustmentLines();
            objCtrl.getAllCategoryAdjustments();
            pr.getParameters().put('index', '1');
            objCtrl.cancel();
        Test.stopTest();
    }

    @isTest
    static void test3()
    {
        List<Apttus_Config2__ProductConfiguration__c> lstPC = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];
        PageReference pr = Page.APTS_CategoryBasedAdjustments;
        pr.getParameters().put('Id', String.valueOf(lstPC[0].Id));
        pr.getParameters().put('index', '0');

        Test.startTest();
            Test.setCurrentPage(pr);
            APTS_CategoryBasedAdjustmentsCtrl objCtrl = new APTS_CategoryBasedAdjustmentsCtrl();
            objCtrl.getCategoryPicklist();
            objCtrl.getDiscountTypes();
            objCtrl.getSubTypes();
            objCtrl.getAdjTypes();
            objCtrl.getUomTypes();
            //objCtrl.populateExistingAdjustmentLines();
            objCtrl.addNewCategoryAdjustmentLine();
            objCtrl.addNewSubCategoryAdjustmentLine();
            objCtrl.addNewSubSubCategoryAdjustmentLine();
            objCtrl.removeCategoryAdjustmentLine();
            objCtrl.removeSubCategoryAdjustmentLine();
            objCtrl.removeSubSubCategoryAdjustmentLine();
            //objCtrl.saveAndGoToCart();
        Test.stopTest();
    }

    @isTest
    static void test4()
    {
        Test.startTest();
            List<Account> lstAccount = [SELECT Id, Name FROM Account];

            Id idGrandParentAccount;
            Id idParentAccount;

            for(Account currentAccount : lstAccount){
                if(currentAccount.Name == 'Grand Parent Account'){
                    idGrandParentAccount = currentAccount.Id;
                }

                if(currentAccount.Name == 'Parent Account'){
                    idParentAccount = currentAccount.Id;
                }
            }

            APTS_CERUtility.getCerRecordAccountForRelatedAccount(idParentAccount,true);
            APTS_CERUtility.getCerRecordAccountForRelatedAccount(idGrandParentAccount,true);
        Test.stopTest();
    }

    @isTest
    static void testSave()
    {
        List<Apttus_Config2__ProductConfiguration__c> lstPC = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];
        List<Apttus_Config2__ClassificationHierarchy__c> lstCH = [SELECT Id, Name FROM Apttus_Config2__ClassificationHierarchy__c WHERE Name = 'Tea'];
        List<Apttus_Config2__ClassificationHierarchy__c> lstCHSub = [SELECT Id, Name FROM Apttus_Config2__ClassificationHierarchy__c WHERE Name = 'Other Tea Brands'];
        List<Apttus_Config2__ClassificationHierarchy__c> lstCHSubSub = [SELECT Id, Name FROM Apttus_Config2__ClassificationHierarchy__c WHERE Name = 'Hornimans'];

        List<APTS_Contract_Entitlement_Repository__c> lstCER = [SELECT Id FROM APTS_Contract_Entitlement_Repository__c];
        delete lstCER;

        PageReference pr = Page.APTS_CategoryBasedAdjustments;
        pr.getParameters().put('Id', String.valueOf(lstPC[0].Id));
        pr.getParameters().put('index', '0');

        Test.startTest();
            Test.setCurrentPage(pr);
            APTS_CategoryBasedAdjustmentsCtrl objCtrl = new APTS_CategoryBasedAdjustmentsCtrl();
            objCtrl.getCategoryPicklist();
            objCtrl.getDiscountTypes();
            objCtrl.getSubTypes();
            objCtrl.getAdjTypes();
            objCtrl.getUomTypes();            
            objCtrl.addNewCategoryAdjustmentLine();
            objCtrl.addNewSubCategoryAdjustmentLine();
            objCtrl.addNewSubSubCategoryAdjustmentLine();
           
            objCtrl.listCategoryAdjustmentLines[0].levelId = lstCH[0].Id;
            objCtrl.listCategoryAdjustmentLines[0].oAdjustmentLineItem.Apttus_Config2__Type__c = 'PPR';
            objCtrl.listCategoryAdjustmentLines[0].oAdjustmentLineItem.Apttus_Config2__AdjustmentAmount__c = 1;
            objCtrl.listCategoryAdjustmentLines[0].oAdjustmentLineItem.Apttus_Config2__AdjustmentUom__c = 'SAP_EA';
            objCtrl.changeSubTypeForCategoryLine();
            
            objCtrl.listSubCategoryAdjustmentLines[0].sCategoryId = lstCHSub[0].Id;
            objCtrl.listSubCategoryAdjustmentLines[0].subLevelId = lstCHSub[0].Id;
            objCtrl.listSubCategoryAdjustmentLines[0].oAdjustmentLineItem.Apttus_Config2__Type__c = 'PPR';
            objCtrl.listSubCategoryAdjustmentLines[0].oAdjustmentLineItem.Apttus_Config2__AdjustmentAmount__c = 1;
            objCtrl.listSubCategoryAdjustmentLines[0].oAdjustmentLineItem.Apttus_Config2__AdjustmentUom__c = 'SAP_EA';
            objCtrl.changeSubTypeForSubCategoryLine();
            
            objCtrl.listSubSubCategoryAdjustmentLines[0].sCategoryId = lstCH[0].Id;            
            objCtrl.listSubSubCategoryAdjustmentLines[0].sSubCategoryId = lstCHSub[0].Id;            
            objCtrl.listSubSubCategoryAdjustmentLines[0].subSubLevelId = lstCHSubSub[0].Id;
            objCtrl.listSubSubCategoryAdjustmentLines[0].oAdjustmentLineItem.Apttus_Config2__Type__c = 'PPR';
            objCtrl.listSubSubCategoryAdjustmentLines[0].oAdjustmentLineItem.Apttus_Config2__AdjustmentAmount__c = 1;
            objCtrl.listSubSubCategoryAdjustmentLines[0].oAdjustmentLineItem.Apttus_Config2__AdjustmentUom__c = 'SAP_EA';
            objCtrl.changeSubTypeForSubSubCategoryLine();
            objCtrl.removeCategoryAdjustmentLine();
            objCtrl.removeSubCategoryAdjustmentLine();
            objCtrl.removeSubSubCategoryAdjustmentLine();


            /*objCtrl.changeSubCatForLine();
            objCtrl.changeSSCSubCatForLine();
            objCtrl.changeSSCSubSubCatForLine();*/
            objCtrl.save();
        Test.stopTest();
    }

    @isTest
    static void testSaveGoToCart()
    {
        List<Apttus_Config2__ProductConfiguration__c> lstPC = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];
        List<Apttus_Config2__ClassificationHierarchy__c> lstCH = [SELECT Id, Name FROM Apttus_Config2__ClassificationHierarchy__c WHERE Name = 'Tea'];
        List<Apttus_Config2__ClassificationHierarchy__c> lstCHSub = [SELECT Id, Name FROM Apttus_Config2__ClassificationHierarchy__c WHERE Name = 'Other Tea Brands'];
        List<Apttus_Config2__ClassificationHierarchy__c> lstCHSubSub = [SELECT Id, Name FROM Apttus_Config2__ClassificationHierarchy__c WHERE Name = 'Hornimans'];

        List<APTS_Contract_Entitlement_Repository__c> lstCER = [SELECT Id FROM APTS_Contract_Entitlement_Repository__c];
        delete lstCER;

        PageReference pr = Page.APTS_CategoryBasedAdjustments;
        pr.getParameters().put('Id', String.valueOf(lstPC[0].Id));
        pr.getParameters().put('index', '0');

        Test.startTest();
            Test.setCurrentPage(pr);
            APTS_CategoryBasedAdjustmentsCtrl objCtrl = new APTS_CategoryBasedAdjustmentsCtrl();
            objCtrl.getCategoryPicklist();
            objCtrl.getDiscountTypes();
            objCtrl.getSubTypes();
            objCtrl.getAdjTypes();
            objCtrl.getUomTypes();            
            objCtrl.addNewCategoryAdjustmentLine();
            objCtrl.addNewSubCategoryAdjustmentLine();
            objCtrl.addNewSubSubCategoryAdjustmentLine();
           
            objCtrl.listCategoryAdjustmentLines[0].levelId = lstCH[0].Id;
            objCtrl.listCategoryAdjustmentLines[0].oAdjustmentLineItem.Apttus_Config2__Type__c = 'PPR';
            objCtrl.listCategoryAdjustmentLines[0].oAdjustmentLineItem.Apttus_Config2__AdjustmentAmount__c = 1;
            objCtrl.listCategoryAdjustmentLines[0].oAdjustmentLineItem.Apttus_Config2__AdjustmentUom__c = 'SAP_EA';
            objCtrl.changeSubTypeForCategoryLine();
            
            objCtrl.listSubCategoryAdjustmentLines[0].sCategoryId = lstCHSub[0].Id;
            objCtrl.listSubCategoryAdjustmentLines[0].subLevelId = lstCHSub[0].Id;
            objCtrl.listSubCategoryAdjustmentLines[0].oAdjustmentLineItem.Apttus_Config2__Type__c = 'PPR';
            objCtrl.listSubCategoryAdjustmentLines[0].oAdjustmentLineItem.Apttus_Config2__AdjustmentAmount__c = 1;
            objCtrl.listSubCategoryAdjustmentLines[0].oAdjustmentLineItem.Apttus_Config2__AdjustmentUom__c = 'SAP_EA';
            objCtrl.changeSubTypeForSubCategoryLine();
            
            objCtrl.listSubSubCategoryAdjustmentLines[0].sCategoryId = lstCH[0].Id;            
            objCtrl.listSubSubCategoryAdjustmentLines[0].sSubCategoryId = lstCHSub[0].Id;            
            objCtrl.listSubSubCategoryAdjustmentLines[0].subSubLevelId = lstCHSubSub[0].Id;
            objCtrl.listSubSubCategoryAdjustmentLines[0].oAdjustmentLineItem.Apttus_Config2__Type__c = 'PPR';
            objCtrl.listSubSubCategoryAdjustmentLines[0].oAdjustmentLineItem.Apttus_Config2__AdjustmentAmount__c = 1;
            objCtrl.listSubSubCategoryAdjustmentLines[0].oAdjustmentLineItem.Apttus_Config2__AdjustmentUom__c = 'SAP_EA';
            objCtrl.changeSubTypeForSubSubCategoryLine();


            /*objCtrl.changeSubCatForLine();
            objCtrl.changeSSCSubCatForLine();
            objCtrl.changeSSCSubSubCatForLine();*/
            objCtrl.saveAndGoToCart();
        Test.stopTest();
    }

     @isTest
    static void testAdd()
    {
        List<Apttus_Config2__ProductConfiguration__c> lstPC = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];
        List<APTS_Contract_Entitlement_Repository__c> lstCER = 
        [
            SELECT Id,
            APTS_Type__c, 
            APTS_Sub_Type__c,
            APTS_Adjustment_Type__c,
            APTS_Adjustment_Value__c,
            APTS_Adjustment_Applies_To__c,
            APTS_Bucket__c,
            APTS_UOM__c,
            APTS_Start_Date__c,
            APTS_End_Date__c,
            APTS_Contributing_Agreement_Level__c,
            APTS_Contributing_Agreement__c,
            APTS_Contributing_Agreement__r.Apttus__FF_Agreement_Number__c,
            APTS_CategoryCER__r.Name,
            APTS_Category_Discount_Amendment__c,
            APTS_CER_from_Parent__c
            FROM APTS_Contract_Entitlement_Repository__c
        ];

        PageReference pr = Page.APTS_CategoryBasedAdjustments;
        pr.getParameters().put('Id', String.valueOf(lstPC[0].Id));
        pr.getParameters().put('index', '0');

        Test.startTest();
            Test.setCurrentPage(pr);
            APTS_CategoryBasedAdjustmentsCtrl objCtrl = new APTS_CategoryBasedAdjustmentsCtrl();
            objCtrl.addNewCategoryAdjustmentLineCER(lstCER);
            objCtrl.addNewSubCategoryAdjustmentLineCER(lstCER);
            objCtrl.addNewSubSubCategoryAdjustmentLineCER(lstCER);
        Test.stopTest();
    }

    @isTest
    static void testSaveError1()
    {
        List<Apttus_Config2__ProductConfiguration__c> lstPC = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];
        List<Apttus_Config2__ClassificationHierarchy__c> lstCH = [SELECT Id, Name FROM Apttus_Config2__ClassificationHierarchy__c WHERE Name = 'Tea'];

        PageReference pr = Page.APTS_CategoryBasedAdjustments;
        pr.getParameters().put('Id', String.valueOf(lstPC[0].Id));
        pr.getParameters().put('index', '0');

        Test.startTest();
            Test.setCurrentPage(pr);
            APTS_CategoryBasedAdjustmentsCtrl objCtrl = new APTS_CategoryBasedAdjustmentsCtrl();
            objCtrl.addNewCategoryAdjustmentLine();
           
            objCtrl.listCategoryAdjustmentLines[0].levelId = lstCH[0].Id;
            objCtrl.listCategoryAdjustmentLines[0].oAdjustmentLineItem.Apttus_Config2__Type__c = null;
            objCtrl.save();
        Test.stopTest();
    }

    @isTest
    static void testSaveError2()
    {
        List<Apttus_Config2__ProductConfiguration__c> lstPC = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];
        List<Apttus_Config2__ClassificationHierarchy__c> lstCH = [SELECT Id, Name FROM Apttus_Config2__ClassificationHierarchy__c WHERE Name = 'Tea'];

        PageReference pr = Page.APTS_CategoryBasedAdjustments;
        pr.getParameters().put('Id', String.valueOf(lstPC[0].Id));
        pr.getParameters().put('index', '0');

        Test.startTest();
            Test.setCurrentPage(pr);
            APTS_CategoryBasedAdjustmentsCtrl objCtrl = new APTS_CategoryBasedAdjustmentsCtrl();
            objCtrl.addNewCategoryAdjustmentLine();
           
            objCtrl.listCategoryAdjustmentLines[0].levelId = lstCH[0].Id;
            objCtrl.listCategoryAdjustmentLines[0].oAdjustmentLineItem.Apttus_Config2__Type__c = 'PPR';
            objCtrl.listCategoryAdjustmentLines[0].oAdjustmentLineItem.Apttus_Config2__SubType__c = null;
            objCtrl.save();
        Test.stopTest();
    }

    @isTest
    static void testSaveError3()
    {
        List<Apttus_Config2__ProductConfiguration__c> lstPC = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];
        List<Apttus_Config2__ClassificationHierarchy__c> lstCH = [SELECT Id, Name FROM Apttus_Config2__ClassificationHierarchy__c WHERE Name = 'Tea'];

        PageReference pr = Page.APTS_CategoryBasedAdjustments;
        pr.getParameters().put('Id', String.valueOf(lstPC[0].Id));
        pr.getParameters().put('index', '0');

        Test.startTest();
            Test.setCurrentPage(pr);
            APTS_CategoryBasedAdjustmentsCtrl objCtrl = new APTS_CategoryBasedAdjustmentsCtrl();
            objCtrl.addNewCategoryAdjustmentLine();
           
            objCtrl.listCategoryAdjustmentLines[0].levelId = lstCH[0].Id;
            objCtrl.listCategoryAdjustmentLines[0].oAdjustmentLineItem.Apttus_Config2__Type__c = 'PPR';
            objCtrl.listCategoryAdjustmentLines[0].oAdjustmentLineItem.Apttus_Config2__SubType__c = 'TPR';
            objCtrl.listCategoryAdjustmentLines[0].oAdjustmentLineItem.Apttus_Config2__AdjustmentAmount__c = null;
            objCtrl.save();
        Test.stopTest();
    }

    @isTest
    static void testSaveError4()
    {
        List<Apttus_Config2__ProductConfiguration__c> lstPC = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];
        List<Apttus_Config2__ClassificationHierarchy__c> lstCH = [SELECT Id, Name FROM Apttus_Config2__ClassificationHierarchy__c WHERE Name = 'Tea'];

        PageReference pr = Page.APTS_CategoryBasedAdjustments;
        pr.getParameters().put('Id', String.valueOf(lstPC[0].Id));
        pr.getParameters().put('index', '0');

        Test.startTest();
            Test.setCurrentPage(pr);
            APTS_CategoryBasedAdjustmentsCtrl objCtrl = new APTS_CategoryBasedAdjustmentsCtrl();
            objCtrl.addNewCategoryAdjustmentLine();
           
            objCtrl.listCategoryAdjustmentLines[0].levelId = lstCH[0].Id;
            objCtrl.listCategoryAdjustmentLines[0].oAdjustmentLineItem.Apttus_Config2__Type__c = 'PPR';
            objCtrl.listCategoryAdjustmentLines[0].oAdjustmentLineItem.Apttus_Config2__SubType__c = 'TPR';
            objCtrl.listCategoryAdjustmentLines[0].oAdjustmentLineItem.Apttus_Config2__AdjustmentAmount__c = 100;
            objCtrl.listCategoryAdjustmentLines[0].oAdjustmentLineItem.Apttus_Config2__AdjustmentUom__c = null;
            objCtrl.save();
        Test.stopTest();
    }

     @isTest
    static void testSaveError5()
    {
        List<Apttus_Config2__ProductConfiguration__c> lstPC = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];
        List<Apttus_Config2__ClassificationHierarchy__c> lstCH = [SELECT Id, Name FROM Apttus_Config2__ClassificationHierarchy__c WHERE Name = 'Tea'];

        PageReference pr = Page.APTS_CategoryBasedAdjustments;
        pr.getParameters().put('Id', String.valueOf(lstPC[0].Id));
        pr.getParameters().put('index', '0');

        Test.startTest();
            Test.setCurrentPage(pr);
            APTS_CategoryBasedAdjustmentsCtrl objCtrl = new APTS_CategoryBasedAdjustmentsCtrl();
            objCtrl.addNewCategoryAdjustmentLine();
           
            objCtrl.listCategoryAdjustmentLines[0].levelId = lstCH[0].Id;
            objCtrl.listCategoryAdjustmentLines[0].oAdjustmentLineItem.Apttus_Config2__AdjustmentType__c = '% Discount';
            objCtrl.listCategoryAdjustmentLines[0].oAdjustmentLineItem.Apttus_Config2__Type__c = 'PPR';
            objCtrl.listCategoryAdjustmentLines[0].oAdjustmentLineItem.Apttus_Config2__SubType__c = 'TPR';
            objCtrl.listCategoryAdjustmentLines[0].oAdjustmentLineItem.Apttus_Config2__AdjustmentAmount__c = 200;
            objCtrl.save();
        Test.stopTest();
    }

     @isTest
    static void testupdateCERRecords()
    {
        List<APTS_Contract_Entitlement_Repository__c> lstCER = [SELECT Id,APTS_Pending_Adjustment_Line_Item__c FROM APTS_Contract_Entitlement_Repository__c];
        List<Apttus_Config2__AdjustmentLineItem__c> lstADLI = [SELECT Id FROM Apttus_Config2__AdjustmentLineItem__c WHERE Id = :lstCER[0].APTS_Pending_Adjustment_Line_Item__c];
        lstADLI[0].APTS_Temp_Id_String__c = '123456';
        update lstADLI;
        
        Map<Id,Double> mapCERIdValue = new Map<Id,Double>();
        mapCERIdValue.put(lstCER[0].Id,1);

        Map<Id,String> mapCERIdKeyADLI = new Map<Id,String>();
        mapCERIdKeyADLI.put(lstCER[0].Id,'123456');

        List<Apttus_Config2__ProductConfiguration__c> lstPC = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];

        PageReference pr = Page.APTS_CategoryBasedAdjustments;
        pr.getParameters().put('Id', String.valueOf(lstPC[0].Id));
        pr.getParameters().put('index', '0');

        Test.startTest();
            Test.setCurrentPage(pr);
            APTS_CategoryBasedAdjustmentsCtrl objCtrl = new APTS_CategoryBasedAdjustmentsCtrl();
            objCtrl.updateCERRecords(mapCERIdValue,lstADLI,mapCERIdKeyADLI,new Set<Id>());
        Test.stopTest();

    }
}