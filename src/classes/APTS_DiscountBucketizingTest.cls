/**************************************************************
* @Author: Shahul
* @Company: Accenture
* @Description: Test class for APTS_DiscountBucketizing
* @Created Date: OCt 11, 2018
* @Revisions:
*      <Name>              <Date>          <Description>
*      shahul      Oct 11, 2018    Initial Version
* 
*************************************************************/
@isTest
public class APTS_DiscountBucketizingTest
{
    
    public static testmethod void testBucket() {
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

        List<Apttus_Config2__AdjustmentLineItem__c> AAdjustment=new List<Apttus_Config2__AdjustmentLineItem__c>();
        Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem = new Apttus_Config2__AdjustmentLineItem__c();
        adjustmentLineItem.Apttus_Config2__AdjustmentType__c = '% Discount';
        adjustmentLineItem.Apttus_Config2__LineItemId__c = lineItem.Id;
        adjustmentLineItem.Apttus_Config2__LineNumber__c = 1;
        adjustmentLineItem.Apttus_Config2__LineType__c = 'Manual';
        adjustmentLineItem.Apttus_Config2__AdjustmentAmount__c = 1;
        adjustmentLineItem.Apttus_Config2__SubType__c = 'ZP03';
        AAdjustment.add(adjustmentLineItem);

        Apttus_Config2__AdjustmentLineItem__c adjustmentLineItemA = new Apttus_Config2__AdjustmentLineItem__c();
        adjustmentLineItemA.Apttus_Config2__AdjustmentType__c = '% Discount';
        adjustmentLineItemA.Apttus_Config2__LineItemId__c = lineItem.Id;
        adjustmentLineItemA.Apttus_Config2__LineNumber__c = 1;
        adjustmentLineItemA.Apttus_Config2__LineType__c = 'Manual';
        adjustmentLineItemA.Apttus_Config2__AdjustmentAmount__c = 1;
        adjustmentLineItemA.Apttus_Config2__SubType__c = 'ZX10';
        AAdjustment.add(adjustmentLineItemA);

        Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem2 = new Apttus_Config2__AdjustmentLineItem__c();
        adjustmentLineItem2.Apttus_Config2__AdjustmentType__c = '% Discount';
        adjustmentLineItem2.Apttus_Config2__LineItemId__c = lineItem.Id;
        adjustmentLineItem2.Apttus_Config2__LineNumber__c = 1;
        adjustmentLineItem2.Apttus_Config2__LineType__c = 'Manual';
        adjustmentLineItem2.Apttus_Config2__AdjustmentAmount__c = 1;
        adjustmentLineItem2.Apttus_Config2__SubType__c = 'ZP06';
        AAdjustment.add(adjustmentLineItem2);

        Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem3 = new Apttus_Config2__AdjustmentLineItem__c();
        adjustmentLineItem3.Apttus_Config2__AdjustmentType__c = '% Discount';
        adjustmentLineItem3.Apttus_Config2__LineItemId__c = lineItem.Id;
        adjustmentLineItem3.Apttus_Config2__LineNumber__c = 1;
        adjustmentLineItem3.Apttus_Config2__LineType__c = 'Manual';
        adjustmentLineItem3.Apttus_Config2__AdjustmentAmount__c = 1;
        adjustmentLineItem3.Apttus_Config2__SubType__c = 'ZP07';
        AAdjustment.add(adjustmentLineItem3);
        
                Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem4 = new Apttus_Config2__AdjustmentLineItem__c();
        adjustmentLineItem4.Apttus_Config2__AdjustmentType__c = '% Discount';
        adjustmentLineItem4.Apttus_Config2__LineItemId__c = lineItem.Id;
        adjustmentLineItem4.Apttus_Config2__LineNumber__c = 1;
        adjustmentLineItem4.Apttus_Config2__LineType__c = 'Manual';
        adjustmentLineItem4.Apttus_Config2__AdjustmentAmount__c = 1;
        adjustmentLineItem4.Apttus_Config2__SubType__c = 'ZP04';
        AAdjustment.add(adjustmentLineItem4);
        
        Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem5 = new Apttus_Config2__AdjustmentLineItem__c();
        adjustmentLineItem5.Apttus_Config2__AdjustmentType__c = '% Discount';
        adjustmentLineItem5.Apttus_Config2__LineItemId__c = lineItem.Id;
        adjustmentLineItem5.Apttus_Config2__LineNumber__c = 1;
        adjustmentLineItem5.Apttus_Config2__LineType__c = 'Manual';
        adjustmentLineItem5.Apttus_Config2__AdjustmentAmount__c = 1;
        adjustmentLineItem5.Apttus_Config2__SubType__c = 'ZP08';
        AAdjustment.add(adjustmentLineItem5);
        
        Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem6 = new Apttus_Config2__AdjustmentLineItem__c();
        adjustmentLineItem6.Apttus_Config2__AdjustmentType__c = '% Discount';
        adjustmentLineItem6.Apttus_Config2__LineItemId__c = lineItem.Id;
        adjustmentLineItem6.Apttus_Config2__LineNumber__c = 1;
        adjustmentLineItem6.Apttus_Config2__LineType__c = 'Manual';
        adjustmentLineItem6.Apttus_Config2__AdjustmentAmount__c = 1;
        adjustmentLineItem6.Apttus_Config2__SubType__c = 'ZP10';
        AAdjustment.add(adjustmentLineItem6);
        
        Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem7 = new Apttus_Config2__AdjustmentLineItem__c();
        adjustmentLineItem7.Apttus_Config2__AdjustmentType__c = '% Discount';
        adjustmentLineItem7.Apttus_Config2__LineItemId__c = lineItem.Id;
        adjustmentLineItem7.Apttus_Config2__LineNumber__c = 1;
        adjustmentLineItem7.Apttus_Config2__LineType__c = 'Manual';
        adjustmentLineItem7.Apttus_Config2__AdjustmentAmount__c = 1;
        adjustmentLineItem7.Apttus_Config2__SubType__c = 'ZX10';
        AAdjustment.add(adjustmentLineItem7);
        
        Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem8 = new Apttus_Config2__AdjustmentLineItem__c();
        adjustmentLineItem8.Apttus_Config2__AdjustmentType__c = '% Discount';
        adjustmentLineItem8.Apttus_Config2__LineItemId__c = lineItem.Id;
        adjustmentLineItem8.Apttus_Config2__LineNumber__c = 1;
        adjustmentLineItem8.Apttus_Config2__LineType__c = 'Manual';
        adjustmentLineItem8.Apttus_Config2__AdjustmentAmount__c = 1;
        adjustmentLineItem8.Apttus_Config2__SubType__c = 'ZP15';
        AAdjustment.add(adjustmentLineItem8);
        
        Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem9 = new Apttus_Config2__AdjustmentLineItem__c();
        adjustmentLineItem9.Apttus_Config2__AdjustmentType__c = '% Discount';
        adjustmentLineItem9.Apttus_Config2__LineItemId__c = lineItem.Id;
        adjustmentLineItem9.Apttus_Config2__LineNumber__c = 1;
        adjustmentLineItem9.Apttus_Config2__LineType__c = 'Manual';
        adjustmentLineItem9.Apttus_Config2__AdjustmentAmount__c = 1;
        adjustmentLineItem9.Apttus_Config2__SubType__c = 'ZP11';
        AAdjustment.add(adjustmentLineItem9);
        
                Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem10 = new Apttus_Config2__AdjustmentLineItem__c();
        adjustmentLineItem10.Apttus_Config2__AdjustmentType__c = '% Discount';
        adjustmentLineItem10.Apttus_Config2__LineItemId__c = lineItem.Id;
        adjustmentLineItem10.Apttus_Config2__LineNumber__c = 1;
        adjustmentLineItem10.Apttus_Config2__LineType__c = 'Manual';
        adjustmentLineItem10.Apttus_Config2__AdjustmentAmount__c = 1;
        adjustmentLineItem10.Apttus_Config2__SubType__c = 'ZP13';
        AAdjustment.add(adjustmentLineItem10);
        
        Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem11 = new Apttus_Config2__AdjustmentLineItem__c();
        adjustmentLineItem11.Apttus_Config2__AdjustmentType__c = '% Discount';
        adjustmentLineItem11.Apttus_Config2__LineItemId__c = lineItem.Id;
        adjustmentLineItem11.Apttus_Config2__LineNumber__c = 1;
        adjustmentLineItem11.Apttus_Config2__LineType__c = 'Manual';
        adjustmentLineItem11.Apttus_Config2__AdjustmentAmount__c = 1;
        adjustmentLineItem11.Apttus_Config2__SubType__c = 'ZP12';
        AAdjustment.add(adjustmentLineItem11);
        
        Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem12 = new Apttus_Config2__AdjustmentLineItem__c();
        adjustmentLineItem12.Apttus_Config2__AdjustmentType__c = '% Discount';
        adjustmentLineItem12.Apttus_Config2__LineItemId__c = lineItem.Id;
        adjustmentLineItem12.Apttus_Config2__LineNumber__c = 1;
        adjustmentLineItem12.Apttus_Config2__LineType__c = 'Manual';
        adjustmentLineItem12.Apttus_Config2__AdjustmentAmount__c = 1;
        adjustmentLineItem12.Apttus_Config2__SubType__c = 'YOCI';
        AAdjustment.add(adjustmentLineItem12);
        
        Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem13 = new Apttus_Config2__AdjustmentLineItem__c();
        adjustmentLineItem13.Apttus_Config2__AdjustmentType__c = '% Discount';
        adjustmentLineItem13.Apttus_Config2__LineItemId__c = lineItem.Id;
        adjustmentLineItem13.Apttus_Config2__LineNumber__c = 1;
        adjustmentLineItem13.Apttus_Config2__LineType__c = 'Manual';
        adjustmentLineItem13.Apttus_Config2__AdjustmentAmount__c = 1;
        adjustmentLineItem13.Apttus_Config2__SubType__c = 'YOFT';
        AAdjustment.add(adjustmentLineItem13);
        
        insert AAdjustment;   

    APTS_DiscountBucketizing.processAdjustmentLineItemfields(AAdjustment);
}
}