/*************************************************************
@Name: APTS_TestClassUtils
@Author: Raul Orozco
@CreateDate: 09-04-2018
@Description: Data creation class for test classes.
@UsedBy: 
******************************************************************/
@isTest
public with sharing class APTS_TestClassUtils {
	
    /* create Organisation (Buying group) Account*/
    public static Account createPurchasingOrganisation(){
        Account organisation = new Account();
        organisation.Name = 'Purchasing Organization';
        organisation.Phone = '+919898468401';
        organisation.Main_Street_Only__c = 'Test Street';
        organisation.Main_House_Number__c = 'Test no.';
        RecordType rt = [select Id from RecordType where Name = 'Purchasing Organization' and SobjectType = 'Account' limit 1];
        organisation.RecordTypeId = rt.Id;
        organisation.Purchase_Organization__c = true;
        return organisation;
    }


    /* create Grand Parent Aaccount **/
    public static Account createGrandParentAccount() {

        Account organisation = new Account();
        organisation.Name = 'Grand Parent Account';
        organisation.Phone = '+919898468401';
        organisation.Main_Street_Only__c = 'Test Street';
        organisation.Main_House_Number__c = 'Test no.';
        organisation.billingcountry = 'Netherlands';
        return organisation;

    }
    
    /* create Parent Account **/
    public static Account createParentAccount(Account grandParentAccount) {

        Account organisation = new Account();
        organisation.Name = 'Parent Account';
        organisation.Phone = '+919898468401';
        organisation.Main_Street_Only__c = 'Test Street';
        organisation.Main_House_Number__c = 'Test no.';
        organisation.Parent = grandParentAccount;
        organisation.ParentId = grandParentAccount.Id;
        return organisation;

    }
    
    /* create Child Account **/
    public static Account createChildAccount(Account parentAccount) {

        Account organisation = new Account();
        organisation.Name = 'Child Account';
        organisation.Phone = '+919898468401';
        organisation.Main_Street_Only__c = 'Test Street';
        organisation.Main_House_Number__c = 'Test no.';
        organisation.Parent = parentAccount;
        organisation.ParentId = parentAccount.Id;
        return organisation;

    }

    /* create product */
    public static Product2 createProduct(Boolean doInsert, String productName, String productCode, String productFamily) {

        Product2 product = new Product2();
        product.Name = productName;
        product.ProductCode = productCode;
        product.Family = productFamily;
        product.IsActive = true;
        product.Apttus_Config2__ConfigurationType__c = 'Standalone';

        if(doInsert){
        	insert product;
        }

        return product;

    }

    /* create category */
    public static Apttus_Config2__ClassificationName__c createCategory(Boolean doInsert) {

        Apttus_Config2__ClassificationName__c category = new Apttus_Config2__ClassificationName__c();
        category.Name = 'Machines';
        category.Apttus_Config2__Active__c = true;
        category.Apttus_Config2__HierarchyLabel__c = 'Machines';
        category.Apttus_Config2__Type__c = 'Offering';
        category.APTS_Allow_Adjustments__c = true;

        if(doInsert){
        	insert category;
        }

        return category;

    }

    /* create category hierarchy */
    public static Apttus_Config2__ClassificationHierarchy__c createCategoryHierarchy(Boolean doInsert, Id categoryId) {

        Apttus_Config2__ClassificationHierarchy__c categoryHierarchy = new Apttus_Config2__ClassificationHierarchy__c();
        categoryHierarchy.Name = 'Machines';
        categoryHierarchy.Apttus_Config2__HierarchyId__c = categoryId;
        categoryHierarchy.Apttus_Config2__AncestorId__c = null;
        categoryHierarchy.Apttus_Config2__DefaultSearchCategory__c = false;
        categoryHierarchy.Apttus_Config2__ExpandedByDefault__c = false;
        categoryHierarchy.Apttus_Config2__HideAllSearchFilters__c = false;
        categoryHierarchy.Apttus_Config2__IncludeInTotalsView__c = true;
        categoryHierarchy.Apttus_Config2__IsHidden__c = false;
        categoryHierarchy.Apttus_Config2__IsPicklist__c = false;
        categoryHierarchy.Apttus_Config2__Label__c = 'Machines';
        categoryHierarchy.Apttus_Config2__LargeImageSize__c = '20x20';
        categoryHierarchy.Apttus_Config2__Left__c = 1;
        categoryHierarchy.Apttus_Config2__Level__c = 0;
        categoryHierarchy.Apttus_Config2__MaxOptions__c = 1.00000;
        categoryHierarchy.Apttus_Config2__MinOptions__c = 1.00000;
        categoryHierarchy.Apttus_Config2__Modifiable__c = true;
        categoryHierarchy.Apttus_Config2__PrimordialId__c = null;
        categoryHierarchy.Apttus_Config2__ProductAttributeGroupId__c = null;
        categoryHierarchy.Apttus_Config2__Right__c = 20;

        if(doInsert){
        	insert categoryHierarchy;
        }

        return categoryHierarchy;

    }

    /* create sub-category */
    public static Apttus_Config2__ClassificationHierarchy__c createSubCategory(Boolean doInsert, Id categoryId, Id categoryHierarchyId) {

        Apttus_Config2__ClassificationHierarchy__c subCategoryHierarchy = new Apttus_Config2__ClassificationHierarchy__c();
        subCategoryHierarchy.Name = 'Cafitesse';
        subCategoryHierarchy.CurrencyIsoCode = 'EUR';
        subCategoryHierarchy.Apttus_Config2__HierarchyId__c = categoryId;
        subCategoryHierarchy.Apttus_Config2__AncestorId__c = categoryHierarchyId;
        subCategoryHierarchy.Apttus_Config2__DefaultSearchCategory__c = false;
        subCategoryHierarchy.Apttus_Config2__ExpandedByDefault__c = false;
        subCategoryHierarchy.Apttus_Config2__HideAllSearchFilters__c = false;
        subCategoryHierarchy.Apttus_Config2__IncludeInTotalsView__c = true;
        subCategoryHierarchy.Apttus_Config2__IsHidden__c = false;
        subCategoryHierarchy.Apttus_Config2__IsPicklist__c = false;
        subCategoryHierarchy.Apttus_Config2__Label__c = 'Cafitesse';
        subCategoryHierarchy.Apttus_Config2__Left__c = 2;
        subCategoryHierarchy.Apttus_Config2__Level__c = 1;
        subCategoryHierarchy.Apttus_Config2__MaxOptions__c = 1.00000;
        subCategoryHierarchy.Apttus_Config2__MinOptions__c = 1.00000;
        subCategoryHierarchy.Apttus_Config2__Modifiable__c = true;
        subCategoryHierarchy.Apttus_Config2__PrimordialId__c = categoryHierarchyId;
        subCategoryHierarchy.Apttus_Config2__ProductAttributeGroupId__c = null;
        subCategoryHierarchy.Apttus_Config2__Right__c = 3;
        
        if(doInsert){
        	insert subCategoryHierarchy;
        }

        return subCategoryHierarchy;

    }

    /* create price list */
    public static Apttus_Config2__PriceList__c createPriceList(Boolean doInsert) {

        Apttus_Config2__PriceList__c priceList = new Apttus_Config2__PriceList__c();
        priceList.Name = 'JDE Price List';
        priceList.Apttus_Config2__Active__c = true;

        if(doInsert){
        	insert priceList;
        }

        return priceList;

    }

    /* create price list item */
    public static Apttus_Config2__PriceListItem__c createPriceListItem(Boolean doInsert, Id priceListId, Id productId) {

        Apttus_Config2__PriceListItem__c pli = new Apttus_Config2__PriceListItem__c();
        pli.Apttus_Config2__PriceListId__c = priceListId;
        pli.Apttus_Config2__ProductId__c = productId;
        pli.Apttus_Config2__ListPrice__c = 0;
        pli.Apttus_Config2__ChargeType__c = 'Sales Price';
        pli.Apttus_Config2__PriceType__c = 'One Time';
        pli.Apttus_Config2__PriceMethod__c = 'Per Unit';
        pli.Apttus_Config2__Active__c = true;
        pli.Apttus_Config2__BillingFrequency__c = 'One Time';
        pli.Apttus_Config2__BillingRule__c = 'Bill In Advance';

        if(doInsert){
        	insert pli;
        }

        return pli;

    }

    /*Create Agreement*/
    public static Apttus__APTS_Agreement__c createAgreement(Boolean doInsert, Id priceListId, Id accountId) {

        Apttus__APTS_Agreement__c aptContract = new Apttus__APTS_Agreement__c(
            recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId(),
                Name = 'Agreement',
                Apttus__Agreement_Category__c = 'Standard',
                Apttus_CMConfig__PriceListId__c = priceListId,
                Apttus_CMConfig__PricingDate__c = System.Today(),
                Apttus__Account__c = accountId);

        if(doInsert){
        	insert aptContract;
        }

        return aptContract;

    }

    /*Create Product Configuration for Agreement*/
	public static Apttus_Config2__ProductConfiguration__c createProductConfigurationAgreement(Boolean doInsert, Id agreementId, Id priceListId){
		Apttus_Config2__ProductConfiguration__c agreementCart = 
		new Apttus_Config2__ProductConfiguration__c(
				Name ='Sample Agreement',
				Apttus_CMConfig__AgreementId__c = agreementId,
				Apttus_Config2__PriceListId__c = priceListId,
				Apttus_Config2__BusinessObjectType__c = 'Agreement'
		);

        if(doInsert){
        	insert agreementCart;
        }
        
        return agreementCart;
	}

	/* Create Line Item */
    public static Apttus_Config2__LineItem__c createConfigLineItem(
    	Boolean doInsert,
		ID configId,
	    ID groupId,
	    Integer lineNumber,
	    Boolean isPrimaryLine,
	    Integer itemSeq,
	    String lineType,
	    ID productId,
	    Boolean customizable,
	    ID productOptionId,
	    ID optionId,
	    ID classId,
	    String classHierarchy,
	    Decimal quantity,
	    Boolean isQtyModifiable,
	    String uom,
	    Integer term,
	    ID priceListId,
	    ID plItemId,
	    String priceType,
	    String priceMethod,
	    String chargeType,
	    String frequency,
	    Boolean allowManualAdj,
	    Boolean allocateGroupAdj,
	    Decimal listPrice,
	    Decimal basePrice,
	    String basePriceMethod,
	    Decimal baseExtPrice,
	    Decimal optionPrice,
	    Decimal extPrice,
	    String lineDesc){

        Apttus_Config2__LineItem__c lineItem = new Apttus_Config2__LineItem__c(Apttus_Config2__ConfigurationId__c = configId);
        lineItem.Apttus_Config2__LineNumber__c = lineNumber;
        lineItem.Apttus_Config2__IsPrimaryLine__c = isPrimaryLine;
        lineItem.Apttus_Config2__PrimaryLineNumber__c = 1;
        lineItem.Apttus_Config2__ItemSequence__c = itemSeq;
        lineItem.Apttus_Config2__SummaryGroupId__c = groupId;
        lineItem.Apttus_Config2__LineType__c = lineType;
        lineItem.Apttus_Config2__ProductId__c = productId;
        lineItem.Apttus_Config2__Customizable__c = customizable;
        lineItem.Apttus_Config2__ProductOptionId__c = productOptionId;
        lineItem.Apttus_Config2__OptionId__c = optionId;
        lineItem.Apttus_Config2__ClassificationId__c = classId;
        lineItem.Apttus_Config2__ClassificationHierarchy__c = classHierarchy;
        lineItem.Apttus_Config2__Quantity__c = quantity;
        lineItem.Apttus_Config2__IsQuantityModifiable__c = isQtyModifiable;
        lineItem.Apttus_Config2__Uom__c = uom;
        lineItem.Apttus_Config2__Term__c = term;
        lineItem.Apttus_Config2__PriceListId__c = priceListId;
        lineItem.Apttus_Config2__PriceListItemId__c = plItemId;
        lineItem.Apttus_Config2__PriceType__c = priceType;
        lineItem.Apttus_Config2__PriceMethod__c = priceMethod;
        lineItem.Apttus_Config2__ChargeType__c = chargeType;
        lineItem.Apttus_Config2__Frequency__c = frequency;
        lineItem.Apttus_Config2__AllowManualAdjustment__c = allowManualAdj;
        lineItem.Apttus_Config2__AllocateGroupAdjustment__c = allocateGroupAdj;
        lineItem.Apttus_Config2__ListPrice__c = listPrice;
        lineItem.Apttus_Config2__BasePrice__c = basePrice;
        lineItem.Apttus_Config2__BasePriceMethod__c = basePriceMethod;
        lineItem.Apttus_Config2__BaseExtendedPrice__c = baseExtPrice;
        lineItem.Apttus_Config2__OptionPrice__c = optionPrice;
        lineItem.Apttus_Config2__ExtendedPrice__c = extPrice;
        lineItem.Apttus_Config2__Description__c = lineDesc;
        lineItem.Apttus_Config2__AdjustedPrice__c = 0;

        if(doInsert){
        	insert lineItem;
        }

        return lineItem;
    }

    //Create Adjustment Line Item
    public static Apttus_Config2__AdjustmentLineItem__c createAdjustmentLineItem(Boolean doInsert, Id lineItemId) {

        Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem = new Apttus_Config2__AdjustmentLineItem__c();
        adjustmentLineItem.Apttus_Config2__AdjustmentAmount__c = 1;
        adjustmentLineItem.Apttus_Config2__AdjustmentAppliesTo__c = 'Previous Price';
        adjustmentLineItem.Apttus_Config2__AdjustmentType__c = '% Discount';
        adjustmentLineItem.APTS_Adjustment_Type__c = '% Discount';
        adjustmentLineItem.APTS_Custom_Adjustment_Amount__c = 1;
        adjustmentLineItem.Apttus_Config2__LineItemId__c = lineItemId;
        adjustmentLineItem.Apttus_Config2__LineNumber__c = 1;
        adjustmentLineItem.Apttus_Config2__LineType__c = 'Manual';
        adjustmentLineItem.Apttus_Config2__Type__c = 'TPR';
        adjustmentLineItem.Apttus_Config2__SubType__c = 'Trade';
        adjustmentLineItem.APTS_Is_Primary__c = true;
        
        if(doInsert){
        	insert adjustmentLineItem;
        }
        
        return adjustmentLineItem;

    }
}