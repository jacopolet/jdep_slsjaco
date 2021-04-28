@isTest
public with sharing class APTS_AddRemoveOptionControllerTest {
   
    @isTest static void test_useCase1() {
        User oTestUser = APTS_TestFacade.createTestUser();
        APTS_TestFacade.createMandatoryRecords(oTestUser);
        APTS_TestFacade.createAndConfigureAgreement(oTestUser);
        APTS_TestFacade.createAndConfigureOrder(oTestUser);

        Account acct= APTS_TestUtils.createOrganisationproduct();
        insert acct;

        Contact oTestContact = APTS_TestUtils.createContact();
        insert oTestContact;

        Apttus_Config2__PriceList__c oTestPricelist = APTS_TestUtils.createPriceList();
        insert oTestPricelist;

        Apttus__APTS_Agreement__c oAggreement = APTS_TestUtils.createAgreement(oTestContact.Id, null, oTestPricelist.Id, acct.Id);
        oAggreement.Apttus__Status_Category__c = 'In Effect';
        oAggreement.Apttus__Status__c = 'Activated';
        oAggreement.Apttus__Contract_End_Date__c = Date.today().addYears(3);
        insert oAggreement;

        Product2 prod = APTS_TestUtils.createProduct('Package Caffetise1', '26940992', 'Machines');       
        insert prod;

        Product2 prod1 = APTS_TestUtils.createProduct('Package Caffetise2', '26940992', 'Machines');       
        insert prod1;

        Product2 prod2 = APTS_TestUtils.createProduct('Package Caffetise3', '26940992', 'Machines');       
        insert prod2;

        Product2 prod3 = APTS_TestUtils.createProduct('Package Caffetise4', '26940992', 'Machines');       
        insert prod3;

        Product2 prod4 = APTS_TestUtils.createProduct('Package Caffetise4', '26940992', 'Machines');       
        insert prod4;

        Apttus_Config2__PriceListItem__c pricelistItem = APTS_TestDataFactory.createPriceListItem(oTestPricelist.id,prod4.id);
        pricelistItem.Apttus_Config2__ChargeType__c = 'Rental Fee';
        pricelistItem.Apttus_Config2__Criteria__c='ABC';
        pricelistItem.Apttus_Config2__ListPrice__c=10;
        insert pricelistItem;

        Apttus_Config2__PriceMatrix__c priceMatrix = new Apttus_Config2__PriceMatrix__c();
        priceMatrix.Apttus_Config2__PriceListItemId__c = pricelistItem.id;
        priceMatrix.Apttus_Config2__Sequence__c=1;
        insert priceMatrix;

        Apttus_Config2__PriceMatrixEntry__c pme = new Apttus_Config2__PriceMatrixEntry__c();
        pme.Apttus_Config2__Dimension1Value__c = '90';
        pme.Apttus_Config2__Sequence__c =1;
        pme.Apttus_Config2__PriceMatrixId__c = priceMatrix.id;
        pme.Apttus_Config2__AdjustmentAmount__c=50;
        insert pme;

        Apttus_Config2__AssetLineItem__c  alineItem = APTS_TestUtils.createAssetLineItem(acct.id,prod.id,null,null,null,null);
        alineItem.Apttus_Config2__Frequency__c='Monthly';
        alineItem.Apttus_Config2__PriceType__c='Recurring';
        alineItem.APTS_Type_Of_Contract__c = 'Rent';
        alineItem.Apttus_Config2__AssetStatus__c ='Activated';
        alineItem.Apttus_Config2__AccountId__c = acct.id;
        alineItem.APTS_relatedlist_agreement__c = oAggreement.id;
        alineItem.APTS_Is_Primary_L1_Line__c = true;
        alineItem.Apttus_Config2__HasOptions__c = true;
        alineItem.Apttus_Config2__ProductId__c=prod.id;
        alineItem.Apttus_Config2__StartDate__c=system.today().addYears(-2);
        alineItem.Apttus_Config2__EndDate__c=system.today().addYears(4);
        alineItem.Apttus_Config2__PriceListId__c = oTestPricelist.id;
        insert alineItem;

        Apttus_Config2__AssetLineItem__c  alineItem2 = APTS_TestUtils.createAssetLineItem(acct.id,prod.id,null,null,null,null);
        alineItem2.Apttus_Config2__Frequency__c='Monthly';
        alineItem2.Apttus_Config2__PriceType__c='Recurring';
        alineItem2.APTS_Type_Of_Contract__c = 'Rent';
        alineItem2.Apttus_Config2__AssetStatus__c ='Renewed';
        alineItem2.APTS_Is_Primary_L1_Asset__c=alineItem.id;
        alineItem2.Apttus_Config2__PriceType__c='Recurring' ;
        alineItem2.Apttus_Config2__AssetStatus__c = 'Activated';
        alineItem2.Apttus_Config2__LineType__c='Option';
        alineItem2.Apttus_Config2__AccountId__c = acct.id;
        alineItem2.Apttus_Config2__ProductId__c=prod.id;
        alineItem2.Apttus_Config2__OptionId__c=prod1.id;
        alineItem2.Apttus_Config2__BundleAssetId__c=alineItem.id;
        //alineItem2.Apttus_Config2__PriceType__c='Recurring';
        alineItem2.APTS_Option_Group_Text__c='Technical Service';
        alineItem2.Apttus_Config2__StartDate__c=system.today().addYears(-2);
        alineItem2.Apttus_Config2__EndDate__c=system.today().addYears(4);
        alineItem2.Apttus_Config2__PriceListId__c = oTestPricelist.id;
        insert alineItem2;


        Apttus_Config2__AssetLineItem__c  alineItem1 = APTS_TestUtils.createAssetLineItem(acct.id,prod.id,null,null,null,null);
        alineItem1.Apttus_Config2__Frequency__c='Monthly';
        alineItem1.APTS_Type_Of_Contract__c = 'Free On Loan';
        alineItem1.Apttus_Config2__LineType__c='Option';
        alineItem1.Apttus_Config2__OptionId__c = prod2.id;
        alineItem1.Apttus_Config2__ParentAssetId__c = alineItem.id;
        alineItem1.Apttus_Config2__PriceType__c='Recurring';
        alineItem1.APTS_Option_Group_Text__c='Technical Service';
        alineItem1.Apttus_Config2__ProductId__c=prod.id;
        alineItem1.APTS_Is_Primary_L1_Asset__c=alineItem.id;
        alineItem1.Apttus_Config2__StartDate__c=system.today().addYears(-2);
        alineItem1.Apttus_Config2__EndDate__c=system.today().addYears(4);
        alineItem1.APTS_Option_Group_Text__c='Response time';
        alineItem1.Apttus_Config2__BundleAssetId__c=alineItem.id;
        alineItem1.Apttus_Config2__PriceListId__c = oTestPricelist.id;
        insert alineItem1;

        Apttus_Config2__AssetLineItem__c  alineItem3 = APTS_TestUtils.createAssetLineItem(acct.id,prod.id,null,null,null,null);
        alineItem3.Apttus_Config2__Frequency__c='Monthly';
        alineItem3.Apttus_Config2__PriceType__c='Recurring';
        alineItem3.APTS_Type_Of_Contract__c = 'Rent';
        alineItem3.Apttus_Config2__LineType__c='Option';
        alineItem3.Apttus_Config2__AssetStatus__c ='Activated';
        alineItem3.Apttus_Config2__AccountId__c = acct.id;
        alineItem3.APTS_relatedlist_agreement__c = oAggreement.id;
        alineItem3.APTS_Is_Primary_L1_Asset__c=alineItem.id;
        alineItem3.Apttus_Config2__HasOptions__c = true;
        alineItem3.Apttus_Config2__PriceType__c='Recurring';
        alineItem3.APTS_Option_Group_Text__c='Response time';
        alineItem3.Apttus_Config2__ProductId__c=prod.id;
        alineItem3.Apttus_Config2__OptionId__c=prod3.id;
        alineItem3.Apttus_Config2__StartDate__c=system.today().addYears(-2);
        alineItem3.Apttus_Config2__EndDate__c=system.today().addYears(4);
        alineItem3.Apttus_Config2__BundleAssetId__c=alineItem.id;
        alineItem3.Apttus_Config2__PriceListId__c = oTestPricelist.id;
        insert alineItem3;

        Apttus_Config2__AssetAttributeValue__c assetattribute = new Apttus_Config2__AssetAttributeValue__c();
        assetattribute.Apttus_Config2__AssetLineItemId__c=alineItem.id;
        assetattribute.APTS_Type_Of_Contract__c='Rent';
        insert assetattribute;

        Apttus_Config2_AssetAdjustItem__c adjustment = new Apttus_Config2_AssetAdjustItem__c();
        adjustment.Apttus_Config2_AssetAdjustAmount__c=100;
        adjustment.Apttus_Config2_AssetAdjustType__c='% Discount';
        adjustment.Apttus_Config2_SubType__c='ZX10';
        adjustment.Apttus_Config2_AssetLineItemId__c=alineItem2.id;
        insert adjustment;

        Apttus_Config2__ClassificationName__c category = new Apttus_Config2__ClassificationName__c();
        category.name='Machine';
        category.Apttus_Config2__Type__c='Option Group';
        category.Apttus_Config2__HierarchyLabel__c='Machine';
        insert category;

        Apttus_Config2__ClassificationHierarchy__c oGroupCategory = new Apttus_Config2__ClassificationHierarchy__c();
        oGroupCategory.name='Technical service';
        oGroupCategory.Apttus_Config2__HierarchyId__c=category.id;
        oGroupCategory.Apttus_Config2__Label__c='Technical service';
        insert oGroupCategory;

        Apttus_Config2__ProductOptionGroup__c prodOpGroup = new Apttus_Config2__ProductOptionGroup__c();
        prodOpGroup.Apttus_Config2__OptionGroupId__c=oGroupCategory.id;
        prodOpGroup.Apttus_Config2__MaxOptions__c=1;
        prodOpGroup.Apttus_Config2__Sequence__c=1;
        insert prodOpGroup;

        Apttus_Config2__ProductOptionGroup__c prodOpGroup1 = new Apttus_Config2__ProductOptionGroup__c();
        prodOpGroup1.Apttus_Config2__OptionGroupId__c=oGroupCategory.id;
        prodOpGroup1.Apttus_Config2__MaxOptions__c=99999;
        prodOpGroup1.Apttus_Config2__Sequence__c=1;
        insert prodOpGroup1;

        Apttus_Config2__ProductOptionComponent__c prodOpGroupComp = new Apttus_Config2__ProductOptionComponent__c();
        prodOpGroupComp.Apttus_Config2__ProductOptionGroupId__c=prodOpGroup.id;
        prodOpGroupComp.Apttus_Config2__ComponentProductId__c=prod1.id;
        prodOpGroupComp.Apttus_Config2__ParentProductId__c=prod.id;
        prodOpGroupComp.Apttus_Config2__Sequence__c=1;
        insert prodOpGroupComp;

        Apttus_Config2__ProductAttributeGroup__c productAttGroup = new Apttus_Config2__ProductAttributeGroup__c();
        productAttGroup.name='testAttGroup';
        insert productAttGroup;

        Apttus_Config2__ProductAttributeGroupMember__c productAttGroupMem = new Apttus_Config2__ProductAttributeGroupMember__c();
        productAttGroupMem.name='testAttGroupMem';
        productAttGroupMem.Apttus_Config2__ProductId__c=prod.id;
        productAttGroupMem.Apttus_Config2__Sequence__c=1;
        productAttGroupMem.Apttus_Config2__AttributeGroupId__c=productAttGroup.id;
        insert productAttGroupMem;

        Apttus_Config2__ProductAttributeGroupMember__c productAttGroupMem1 = new Apttus_Config2__ProductAttributeGroupMember__c();
        productAttGroupMem1.name='testAttGroupMem';
        productAttGroupMem1.Apttus_Config2__ProductId__c=prod1.id;
        productAttGroupMem1.Apttus_Config2__Sequence__c=1;
        productAttGroupMem1.Apttus_Config2__AttributeGroupId__c=productAttGroup.id;
        insert productAttGroupMem1;

        Apttus_Config2__ProductAttribute__c productAttribute = new Apttus_Config2__ProductAttribute__c();
        productAttribute.Apttus_Config2__AttributeGroupId__c=productAttGroup.id;
        productAttribute.Apttus_Config2__IsHidden__c=false;
        productAttribute.Apttus_Config2__Sequence__c=1;
        productAttribute.Apttus_Config2__Field__c='APTS_Type_of_contract__c';
        insert productAttribute;

        Test.startTest();
        String assetid=alineItem.id;
        String ogId=prodOpGroup1.id;
        List<APTS_AddRemoveOptionController.AttributeWrapper> bundleAttributes = APTS_AddRemoveOptionController.getDefaultAttributesForBundle(assetid);
        list<APTS_AddRemoveOptionController.AddRemoveOptionWrapper> listOfOptions =APTS_AddRemoveOptionController.getRecsForModifyOptionAction(alineItem.id);
        List<Apttus_Config2__ProductOptionComponent__c> productOptionCompList =APTS_AddRemoveOptionController.getOptionGroupRecs(alineItem.id,listOfOptions,bundleAttributes);
        List<Apttus_Config2__ProductOptionComponent__c> options = APTS_AddRemoveOptionController.getOptions(assetid,ogId,listOfOptions,bundleAttributes);
        List<APTS_AddRemoveOptionController.AttributeWrapper> optionAttributes = APTS_AddRemoveOptionController.getRelatedAttributes(prod1.id,'Technical service',bundleAttributes);
        
         List<APTS_AddRemoveOptionController.AttributeWrapper> optionLevelAttributes = new List<APTS_AddRemoveOptionController.AttributeWrapper>();
        APTS_AddRemoveOptionController.AttributeWrapper optionattribute = new APTS_AddRemoveOptionController.AttributeWrapper();
        optionattribute.attributeFieldName='APTS_One_Time_Purchase__c';
        optionattribute.assignedValue='No';
        optionattribute.productId=prod4.id;
        optionLevelAttributes.add(optionattribute);
        
        List<APTS_AddRemoveOptionController.AddRemoveOptionWrapper> listOfModifiedOptions = APTS_AddRemoveOptionController.determinePriceOfOptions(assetid,prod4.id,'ABC',System.today(),'Cabinet',listOfOptions,true,10,'Discount%',10,'Monthly',optionLevelAttributes,bundleAttributes);
        Decimal sellingTerm = APTS_AddRemoveOptionController.calculateSellingTerm(system.today(),System.today().addYears(1));
        Test.stopTest();
    }

    @isTest static void test_useCase2() {
        User oTestUser = APTS_TestFacade.createTestUser();
        APTS_TestFacade.createMandatoryRecords(oTestUser);
        APTS_TestFacade.createAndConfigureAgreement(oTestUser);
        APTS_TestFacade.createAndConfigureOrder(oTestUser);

        Account acct= APTS_TestUtils.createOrganisationproduct();
        insert acct;

        Contact oTestContact = APTS_TestUtils.createContact();
        insert oTestContact;

        Apttus_Config2__PriceList__c oTestPricelist = APTS_TestUtils.createPriceList();
        insert oTestPricelist;

        Apttus__APTS_Agreement__c oAggreement = APTS_TestUtils.createAgreement(oTestContact.Id, null, oTestPricelist.Id, acct.Id);
        oAggreement.Apttus__Status_Category__c = 'In Effect';
        oAggreement.Apttus__Status__c = 'Activated';
        oAggreement.Apttus__Contract_End_Date__c = Date.today().addYears(3);
        insert oAggreement;

        Product2 prod = APTS_TestUtils.createProduct('Package Caffetise1', '26940992', 'Machines');       
        insert prod;

        Product2 prod1 = APTS_TestUtils.createProduct('Package Caffetise2', '26940992', 'Machines');       
        insert prod1;

        Product2 prod2 = APTS_TestUtils.createProduct('Package Caffetise3', '26940992', 'Machines');       
        insert prod2;

        Product2 prod3 = APTS_TestUtils.createProduct('Package Caffetise4', '26940992', 'Machines');       
        insert prod3;

        Product2 prod4 = APTS_TestUtils.createProduct('Package Caffetise4', '26940992', 'Machines');       
        insert prod4;

        Apttus_Config2__PriceListItem__c pricelistItem = APTS_TestDataFactory.createPriceListItem(oTestPricelist.id,prod4.id);
        pricelistItem.Apttus_Config2__ChargeType__c = 'Sales Price';
        pricelistItem.Apttus_Config2__Criteria__c='ABC';
        pricelistItem.Apttus_Config2__ListPrice__c=10;
        insert pricelistItem;

        Apttus_Config2__AssetLineItem__c  alineItem = APTS_TestUtils.createAssetLineItem(acct.id,prod.id,null,null,null,null);
        alineItem.Apttus_Config2__Frequency__c='Monthly';
        alineItem.Apttus_Config2__PriceType__c='Recurring';
        alineItem.APTS_Type_Of_Contract__c = 'Rent';
        alineItem.Apttus_Config2__AssetStatus__c ='Activated';
        alineItem.Apttus_Config2__AccountId__c = acct.id;
        alineItem.APTS_relatedlist_agreement__c = oAggreement.id;
        alineItem.APTS_Is_Primary_L1_Line__c = true;
        alineItem.Apttus_Config2__HasOptions__c = true;
        alineItem.Apttus_Config2__ProductId__c=prod.id;
        alineItem.Apttus_Config2__StartDate__c=system.today().addYears(-2);
        alineItem.Apttus_Config2__EndDate__c=system.today().addYears(4);
        alineItem.Apttus_Config2__PriceListId__c = oTestPricelist.id;
        insert alineItem;

        Apttus_Config2__AssetLineItem__c  alineItem2 = APTS_TestUtils.createAssetLineItem(acct.id,prod.id,null,null,null,null);
        alineItem2.Apttus_Config2__Frequency__c='Monthly';
        alineItem2.Apttus_Config2__PriceType__c='Recurring';
        alineItem2.APTS_Type_Of_Contract__c = 'Rent';
        alineItem2.Apttus_Config2__AssetStatus__c ='Renewed';
        alineItem2.APTS_Is_Primary_L1_Asset__c=alineItem.id;
        alineItem2.Apttus_Config2__PriceType__c='Recurring' ;
        alineItem2.Apttus_Config2__AssetStatus__c = 'Activated';
        alineItem2.Apttus_Config2__LineType__c='Option';
        alineItem2.Apttus_Config2__AccountId__c = acct.id;
        alineItem2.Apttus_Config2__ProductId__c=prod.id;
        alineItem2.Apttus_Config2__OptionId__c=prod1.id;
        alineItem2.Apttus_Config2__BundleAssetId__c=alineItem.id;
        //alineItem2.Apttus_Config2__PriceType__c='Recurring';
        alineItem2.APTS_Option_Group_Text__c='Technical Service';
        alineItem2.Apttus_Config2__StartDate__c=system.today().addYears(-2);
        alineItem2.Apttus_Config2__EndDate__c=system.today().addYears(4);
        alineItem2.Apttus_Config2__PriceListId__c = oTestPricelist.id;
        insert alineItem2;


        Apttus_Config2__AssetLineItem__c  alineItem1 = APTS_TestUtils.createAssetLineItem(acct.id,prod.id,null,null,null,null);
        alineItem1.Apttus_Config2__Frequency__c='Monthly';
        alineItem1.APTS_Type_Of_Contract__c = 'Free On Loan';
        alineItem1.Apttus_Config2__LineType__c='Option';
        alineItem1.Apttus_Config2__OptionId__c = prod2.id;
        alineItem1.Apttus_Config2__ParentAssetId__c = alineItem.id;
        alineItem1.Apttus_Config2__PriceType__c='Recurring';
        alineItem1.APTS_Option_Group_Text__c='Technical Service';
        alineItem1.Apttus_Config2__ProductId__c=prod.id;
        alineItem1.APTS_Is_Primary_L1_Asset__c=alineItem.id;
        alineItem1.Apttus_Config2__StartDate__c=system.today().addYears(-2);
        alineItem1.Apttus_Config2__EndDate__c=system.today().addYears(4);
        alineItem1.APTS_Option_Group_Text__c='Response time';
        alineItem1.Apttus_Config2__BundleAssetId__c=alineItem.id;
        alineItem1.Apttus_Config2__PriceListId__c = oTestPricelist.id;
        insert alineItem1;

        Apttus_Config2__AssetLineItem__c  alineItem3 = APTS_TestUtils.createAssetLineItem(acct.id,prod.id,null,null,null,null);
        alineItem3.Apttus_Config2__Frequency__c='Monthly';
        alineItem3.Apttus_Config2__PriceType__c='Recurring';
        alineItem3.APTS_Type_Of_Contract__c = 'Rent';
        alineItem3.Apttus_Config2__LineType__c='Option';
        alineItem3.Apttus_Config2__AssetStatus__c ='Activated';
        alineItem3.Apttus_Config2__AccountId__c = acct.id;
        alineItem3.APTS_relatedlist_agreement__c = oAggreement.id;
        alineItem3.APTS_Is_Primary_L1_Asset__c=alineItem.id;
        alineItem3.Apttus_Config2__HasOptions__c = true;
        alineItem3.Apttus_Config2__PriceType__c='Recurring';
        alineItem3.APTS_Option_Group_Text__c='Response time';
        alineItem3.Apttus_Config2__ProductId__c=prod.id;
        alineItem3.Apttus_Config2__OptionId__c=prod3.id;
        alineItem3.Apttus_Config2__StartDate__c=system.today().addYears(-2);
        alineItem3.Apttus_Config2__EndDate__c=system.today().addYears(4);
        alineItem3.Apttus_Config2__BundleAssetId__c=alineItem.id;
        alineItem3.Apttus_Config2__PriceListId__c = oTestPricelist.id;
        insert alineItem3;

        Apttus_Config2__AssetAttributeValue__c assetattribute = new Apttus_Config2__AssetAttributeValue__c();
        assetattribute.Apttus_Config2__AssetLineItemId__c=alineItem.id;
        assetattribute.APTS_Type_Of_Contract__c='Rent';
        insert assetattribute;

        Apttus_Config2_AssetAdjustItem__c adjustment = new Apttus_Config2_AssetAdjustItem__c();
        adjustment.Apttus_Config2_AssetAdjustAmount__c=100;
        adjustment.Apttus_Config2_AssetAdjustType__c='% Discount';
        adjustment.Apttus_Config2_SubType__c='ZX10';
        adjustment.Apttus_Config2_AssetLineItemId__c=alineItem2.id;
        insert adjustment;

        Apttus_Config2__ClassificationName__c category = new Apttus_Config2__ClassificationName__c();
        category.name='Machine';
        category.Apttus_Config2__Type__c='Option Group';
        category.Apttus_Config2__HierarchyLabel__c='Machine';
        insert category;

        Apttus_Config2__ClassificationHierarchy__c oGroupCategory = new Apttus_Config2__ClassificationHierarchy__c();
        oGroupCategory.name='Technical service';
        oGroupCategory.Apttus_Config2__HierarchyId__c=category.id;
        oGroupCategory.Apttus_Config2__Label__c='Technical service';
        insert oGroupCategory;

        Apttus_Config2__ProductOptionGroup__c prodOpGroup = new Apttus_Config2__ProductOptionGroup__c();
        prodOpGroup.Apttus_Config2__OptionGroupId__c=oGroupCategory.id;
        prodOpGroup.Apttus_Config2__MaxOptions__c=1;
        prodOpGroup.Apttus_Config2__Sequence__c=1;
        insert prodOpGroup;

        Apttus_Config2__ProductOptionGroup__c prodOpGroup1 = new Apttus_Config2__ProductOptionGroup__c();
        prodOpGroup1.Apttus_Config2__OptionGroupId__c=oGroupCategory.id;
        prodOpGroup1.Apttus_Config2__MaxOptions__c=99999;
        prodOpGroup1.Apttus_Config2__Sequence__c=1;
        insert prodOpGroup1;

        Apttus_Config2__ProductOptionComponent__c prodOpGroupComp = new Apttus_Config2__ProductOptionComponent__c();
        prodOpGroupComp.Apttus_Config2__ProductOptionGroupId__c=prodOpGroup.id;
        prodOpGroupComp.Apttus_Config2__ComponentProductId__c=prod1.id;
        prodOpGroupComp.Apttus_Config2__ParentProductId__c=prod.id;
        prodOpGroupComp.Apttus_Config2__Sequence__c=1;
        insert prodOpGroupComp;

        Apttus_Config2__ProductAttributeGroup__c productAttGroup = new Apttus_Config2__ProductAttributeGroup__c();
        productAttGroup.name='testAttGroup';
        insert productAttGroup;

        Apttus_Config2__ProductAttributeGroupMember__c productAttGroupMem = new Apttus_Config2__ProductAttributeGroupMember__c();
        productAttGroupMem.name='testAttGroupMem';
        productAttGroupMem.Apttus_Config2__ProductId__c=prod.id;
        productAttGroupMem.Apttus_Config2__Sequence__c=1;
        productAttGroupMem.Apttus_Config2__AttributeGroupId__c=productAttGroup.id;
        insert productAttGroupMem;

        Apttus_Config2__ProductAttributeGroupMember__c productAttGroupMem1 = new Apttus_Config2__ProductAttributeGroupMember__c();
        productAttGroupMem1.name='testAttGroupMem';
        productAttGroupMem1.Apttus_Config2__ProductId__c=prod1.id;
        productAttGroupMem1.Apttus_Config2__Sequence__c=1;
        productAttGroupMem1.Apttus_Config2__AttributeGroupId__c=productAttGroup.id;
        insert productAttGroupMem1;

        Apttus_Config2__ProductAttribute__c productAttribute = new Apttus_Config2__ProductAttribute__c();
        productAttribute.Apttus_Config2__AttributeGroupId__c=productAttGroup.id;
        productAttribute.Apttus_Config2__IsHidden__c=false;
        productAttribute.Apttus_Config2__Sequence__c=1;
        productAttribute.Apttus_Config2__Field__c='APTS_Type_of_contract__c';
        insert productAttribute;

        Test.startTest();
        String assetid=alineItem.id;
        String ogId=prodOpGroup1.id;

        List<APTS_AddRemoveOptionController.AttributeWrapper> bundleAttributes = APTS_AddRemoveOptionController.getDefaultAttributesForBundle(assetid);
        list<APTS_AddRemoveOptionController.AddRemoveOptionWrapper> listOfOptions =APTS_AddRemoveOptionController.getRecsForModifyOptionAction(alineItem.id);
        List<Apttus_Config2__ProductOptionComponent__c> productOptionCompList =APTS_AddRemoveOptionController.getOptionGroupRecs(alineItem.id,listOfOptions,bundleAttributes);
       List<Apttus_Config2__ProductOptionComponent__c> options = APTS_AddRemoveOptionController.getOptions(assetid,ogId,listOfOptions,bundleAttributes);
        List<APTS_AddRemoveOptionController.AttributeWrapper> optionAttributes = APTS_AddRemoveOptionController.getRelatedAttributes(prod1.id,'Technical service',bundleAttributes);
        
        //Adding option Attributes
        List<APTS_AddRemoveOptionController.AttributeWrapper> optionLevelAttributes = new List<APTS_AddRemoveOptionController.AttributeWrapper>();
        APTS_AddRemoveOptionController.AttributeWrapper optionattribute = new APTS_AddRemoveOptionController.AttributeWrapper();
        optionattribute.attributeFieldName='APTS_One_Time_Purchase__c';
        optionattribute.assignedValue='Yes';
        optionattribute.productId=prod4.id;
        optionLevelAttributes.add(optionattribute);
        List<APTS_AddRemoveOptionController.AddRemoveOptionWrapper> listOfModifiedOptions = APTS_AddRemoveOptionController.determinePriceOfOptions(assetid,prod4.id,'ABC',System.today(),'Cabinet',listOfOptions,true,10,'Discount%',10,'Monthly',optionLevelAttributes,bundleAttributes);
        Decimal sellingTerm = APTS_AddRemoveOptionController.calculateSellingTerm(system.today(),System.today().addYears(1));
        Test.stopTest();
    }
    @isTest static void test_useCase3() {
         User oTestUser = APTS_TestFacade.createTestUser();
        APTS_TestFacade.createMandatoryRecords(oTestUser);
        APTS_TestFacade.createAndConfigureAgreement(oTestUser);
        APTS_TestFacade.createAndConfigureOrder(oTestUser);
        Account acct= APTS_TestUtils.createOrganisationproduct();
        insert acct;
        Contact oTestContact = APTS_TestUtils.createContact();
        insert oTestContact;
        Apttus_Config2__PriceList__c oTestPricelist = APTS_TestUtils.createPriceList();
        insert oTestPricelist;
        
        Apttus__APTS_Agreement__c oAggreement = APTS_TestUtils.createAgreement(oTestContact.Id, null, oTestPricelist.Id, acct.Id);
        oAggreement.Apttus__Status_Category__c = 'In Effect';
        oAggreement.Apttus__Status__c = 'Activated';
        oAggreement.Apttus__Contract_End_Date__c = Date.today().addYears(3);
        insert oAggreement;
        
        Product2 prod = APTS_TestUtils.createProduct('Package Caffetise2', '26940992', 'Machines');       
        insert prod;
        
        Product2 prod1 = APTS_TestUtils.createProduct('Package Caffetise3', '26940993', 'Machines');       
        insert prod1;

        Apttus_Config2__ClassificationName__c catego = APTS_TestDataFactory.createCategory();
        insert catego;
        
        Apttus_Config2__ClassificationHierarchy__c catehi = APTS_TestDataFactory.createCategoryHierarchy(catego.id, 'test');
        insert catehi;
        
        Apttus_Config2__ClassificationHierarchy__c catSub = APTS_TestDataFactory.createSubCategory(catego.id,catehi.id);
        insert catSub; 
            
        Apttus_Config2__ProductOptionGroup__c optionGr = APTS_TestDataFactory.createProductOptionGroup(catehi.id,catSub.id);
        optionGr.Apttus_Config2__ParentOptionGroupId__c =catehi.id;
        insert optionGr;
        
        Apttus_Config2__ProductOptionComponent__c produOp = APTS_TestDataFactory.createProductOptionComponent(optionGr.id);
        produOp.Apttus_Config2__ParentProductId__c= prod.id;
        produOp.Apttus_Config2__ComponentProductId__c=prod1.id;
        insert produOp;
        
        Apttus_Config2__ProductClassification__c classpr = APTS_TestDataFactory.createProductClassification(catsub.id,prod1.id);
        insert classpr;

        Apttus_Config2__PriceListCategory__c pricelistHierarchy = new Apttus_Config2__PriceListCategory__c();
        pricelistHierarchy.Apttus_Config2__HierarchyId__c = catego.id;
        pricelistHierarchy.Apttus_Config2__PriceListId__c=oTestPricelist.id;
        pricelistHierarchy.Apttus_Config2__Sequence__c=1;
        insert pricelistHierarchy;

        Apttus_Config2__PriceListItem__c pricelistItem = APTS_TestDataFactory.createPriceListItem(oTestPricelist.id,prod1.id);
        pricelistItem.Apttus_Config2__ChargeType__c = 'Sales Price';
        pricelistItem.Apttus_Config2__Criteria__c='ABC';
        pricelistItem.Apttus_Config2__ListPrice__c=10;
        insert pricelistItem;
        System.debug('pricelistItem=====TESTCLASS======>'+pricelistItem);

        Apttus_Config2__ProductHierarchyView__c hierarchyView = new Apttus_Config2__ProductHierarchyView__c();
        hierarchyView.Apttus_Config2__HierarchyId__c = catego.id;
        hierarchyView.Apttus_Config2__ParentClassificationId__c = catehi.id;
        hierarchyView.Apttus_Config2__ChildClassificationId__c = catSub.id;
        hierarchyView.Apttus_Config2__PriceListId__c = oTestPricelist.id;
        hierarchyView.Apttus_Config2__ProductClassificationId__c = classpr.id;
        hierarchyView.Apttus_Config2__IsInactive__c=false;
        hierarchyView.Apttus_Config2__ChildProductId__c=prod1.id;
        hierarchyView.Apttus_Config2__ChildLevel__c=1;
        hierarchyView.Apttus_Config2__ParentLevel__c=0;
        hierarchyView.Apttus_Config2__IsDetail__c=true;
        hierarchyView.Apttus_Config2__RelationshipType__c = 'Classification Node';
        insert hierarchyView;
        /*Apttus_Config2__AssetLineItem__c  alineItem = APTS_TestUtils.createAssetLineItem(acct.id,prod.id,null,null,null,null);
        alineItem.Apttus_Config2__Frequency__c='Monthly';
        alineItem.Apttus_Config2__PriceType__c='Recurring';
        alineItem.APTS_Type_Of_Contract__c = 'Rent';
        alineItem.Apttus_Config2__AssetStatus__c ='Activated';
        alineItem.Apttus_Config2__AccountId__c = acct.id;
        alineItem.APTS_relatedlist_agreement__c = oAggreement.id;
        alineItem.APTS_Is_Primary_L1_Line__c = true;
        alineItem.Apttus_Config2__HasOptions__c = true;
        insert alineItem;
        
        Apttus_Config2__AssetLineItem__c  alineItem2 = APTS_TestUtils.createAssetLineItem(acct.id,prod.id,null,null,null,null);
        alineItem2.Apttus_Config2__Frequency__c='Monthly';
        alineItem2.Apttus_Config2__PriceType__c='Recurring';
        alineItem2.APTS_Type_Of_Contract__c = 'Rent';
        alineItem2.Apttus_Config2__AssetStatus__c ='Renewed';
        alineItem2.APTS_Is_Primary_L1_Asset__c=alineItem.id;
        alineItem2.Apttus_Config2__PriceType__c='Recurring' ;
        alineItem2.Apttus_Config2__AssetStatus__c = 'Activated';
        alineItem2.Apttus_Config2__LineType__c='Option';
        alineItem2.Apttus_Config2__AccountId__c = acct.id;
        alineItem2.APTS_Is_Primary_L1_Line__c = true;
        insert alineItem2;
        
        Apttus_Config2__AssetLineItem__c  alineItem1 = APTS_TestUtils.createAssetLineItem(acct.id,prod.id,null,null,null,null);
        alineItem1.Apttus_Config2__Frequency__c='Monthly';
        alineItem1.Apttus_Config2__PriceType__c='Renewed';
        alineItem1.APTS_Type_Of_Contract__c = 'Free On Loan';
        alineItem1.Apttus_Config2__OptionId__c = prod1.id;
        alineItem1.Apttus_Config2__ParentAssetId__c = alineItem.id;
        alineItem1.APTS_Is_Primary_L1_Line__c = true;
        insert alineItem1;
        
        Apttus_Config2__AssetLineItem__c  alineItem3 = APTS_TestUtils.createAssetLineItem(acct.id,prod.id,null,null,null,null);
        alineItem3.Apttus_Config2__Frequency__c='Monthly';
        alineItem3.Apttus_Config2__PriceType__c='Recurring';
        alineItem3.APTS_Type_Of_Contract__c = 'Rent';
        alineItem3.Apttus_Config2__AssetStatus__c ='Activated';
        alineItem3.Apttus_Config2__AccountId__c = acct.id;
        alineItem3.APTS_relatedlist_agreement__c = oAggreement.id;
        alineItem3.APTS_Is_Primary_L1_Line__c = true;
        alineItem3.Apttus_Config2__HasOptions__c = true;
        insert alineItem3;*/
        
        Test.startTest();
        Map<ID,Apttus_Config2__LineItem__c> lineItemMap = New Map<ID,Apttus_Config2__LineItem__c>();
        List<Apttus_Config2__ProductConfiguration__c> productConfig  = [select id,Apttus_Config2__BillToAccountId__c,Apttus_Config2__ShipToAccountId__c,Apttus_Config2__ExpectedStartDate__c,Apttus_Config2__ExpectedEndDate__c,Apttus_Config2__PriceListId__c from Apttus_Config2__ProductConfiguration__c limit 1];

        Apttus_Config2__LineItem__c primarylineLI = APTS_TestDataFactory.createLineItem(productConfig[0], pricelistItem.Id, NULL, prod.Id, NULL, NULL, 1, 1, 1, 'Product/Service', NULL , 'Monthly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100, 2);
        primarylineLI.Apttus_Config2__IsOptionRollupLine__c=false;
        primarylineLI.Apttus_Config2__HasOptions__c=true;
        primarylineLI.Apttus_Config2__LineNumber__c=1;
        insert primarylineLI;

        if(lineItemMap.get(primarylineLI.id)==null){
            lineItemMap.put(primarylineLI.id,primarylineLI); 
         }

        //Apttus_Config2__LineItem__c freightChargesLI = APTS_TestDataFactory.createLineItem(oProductConfiguration, oPriceListFC.Id, NULL, freightCharges.Id, NULL, NULL, 1, 1, 1, 'Product/Service', NULL , 'Monthly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100, 2);
        String orderInputJSON = '[{"rowNumber":"8","assetName":"'+prod1.name+'","attributeList":[],"autoRenew":true,"basePrice":33,"chargeType":"Sales Price","discountPercentage":100,"endDate":"2029-03-22","linestatus":"New","netUnitPrice":0,"optionGroupText":"Technical Service","originalStartDate":"2028-01-02","priceListItemId":"a4l1x00000082yCAAQ","productid":"'+prod1.id+'","sellingTerm":14.67742,"startDate":"2028-01-02","subType":"ZX10","modifiedLineItem":"slds-is-edited slds-text-color_success customFontChanged","assetid":null}]';
        String bundleLevelAttributeJSON='[{"assignedValue":"Rent","attributeFieldName":"APTS_Type_of_contract__c","priceListId": "'+oTestPricelist.id+'","productId":"01t1v00000D02hXAAR","readOnly":true},{"assignedValue":"No","attributeFieldName":"APTS_Include_Free_Service__c","priceListId":"'+oTestPricelist.id+'","productId":"01t1v00000D02hXAAR","readOnly":false}]';
        String cartId = productConfig[0].id;
        APTS_AddRemoveOptionController.processAddRemoveOptions(lineItemMap,orderInputJSON,cartId,bundleLevelAttributeJSON);
        
        lineItemMap.clear();
        Apttus_Config2__LineItem__c newlyAddedOption = APTS_TestDataFactory.createLineItem(productConfig[0], pricelistItem.Id, NULL, prod.Id, NULL, NULL, 1, 1, 1, 'Option', NULL , 'Monthly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100, 2);
        newlyAddedOption.Apttus_Config2__OptionId__c=prod1.id;
        insert newlyAddedOption;
        if(lineItemMap.get(newlyAddedOption.id)==null){
            lineItemMap.put(newlyAddedOption.id,newlyAddedOption); 
         }
        List<APTS_AddRemoveOptionController.AddRemoveOptionWrapper> addRemoveWrapperList = (List<APTS_AddRemoveOptionController.AddRemoveOptionWrapper>)JSON.deserializeStrict(orderInputJSON, List<APTS_AddRemoveOptionController.AddRemoveOptionWrapper>.class);
        List<APTS_AddRemoveOptionController.AttributeWrapper> bundleAttributesJSONList = (List<APTS_AddRemoveOptionController.AttributeWrapper>)JSON.deserializeStrict(bundleLevelAttributeJSON, List<APTS_AddRemoveOptionController.AttributeWrapper>.class);
        Map<Id,APTS_AddRemoveOptionController.AddRemoveOptionWrapper> addingOptionMap = new Map<Id,APTS_AddRemoveOptionController.AddRemoveOptionWrapper>();
        List<Apttus_Config2__LineItem__c> addList = new List<Apttus_Config2__LineItem__c>();
        Map<id,Apttus_Config2__ProductAttributeValue__c> productAttributeMap = new Map<id,Apttus_Config2__ProductAttributeValue__c>();
        for(APTS_AddRemoveOptionController.AddRemoveOptionWrapper addRemoveObj : addRemoveWrapperList){
            if(addRemoveObj.linestatus.equalsIgnoreCase('New')){
                if(addingOptionMap.get(addRemoveObj.productid)==null){
                    addingOptionMap.put(addRemoveObj.productid,addRemoveObj);
                }
            }
        }
        System.debug('addingOptionMap======TEST CLASS=========>'+addingOptionMap);
        APTS_AddRemoveOptionController.processAttributes(lineItemMap.values(),addingOptionMap,productAttributeMap,bundleAttributesJSONList);    
        APTS_AddRemoveOptionController.processNewlyAddedOptions(productConfig[0].id,lineItemMap.values(),addingOptionMap,addList,bundleAttributesJSONList);
        Test.stopTest();
    }
    @isTest static void test_useCase4() {
        User oTestUser = APTS_TestFacade.createTestUser();
       APTS_TestFacade.createMandatoryRecords(oTestUser);
       APTS_TestFacade.createAndConfigureAgreement(oTestUser);
       APTS_TestFacade.createAndConfigureOrder(oTestUser);
       Account acct= APTS_TestUtils.createOrganisationproduct();
       insert acct;
       Contact oTestContact = APTS_TestUtils.createContact();
       insert oTestContact;
       Apttus_Config2__PriceList__c oTestPricelist = APTS_TestUtils.createPriceList();
       insert oTestPricelist;
       
       Apttus__APTS_Agreement__c oAggreement = APTS_TestUtils.createAgreement(oTestContact.Id, null, oTestPricelist.Id, acct.Id);
       oAggreement.Apttus__Status_Category__c = 'In Effect';
       oAggreement.Apttus__Status__c = 'Activated';
       oAggreement.Apttus__Contract_End_Date__c = Date.today().addYears(3);
       insert oAggreement;
       
       Product2 prod = APTS_TestUtils.createProduct('Package Caffetise2', '26940992', 'Machines');       
       insert prod;
       
       Product2 prod1 = APTS_TestUtils.createProduct('ALL-IN COVERAGE', '26940993', 'Machines');       
       insert prod1;

       Apttus_Config2__ClassificationName__c catego = APTS_TestDataFactory.createCategory();
       insert catego;
       
       Apttus_Config2__ClassificationHierarchy__c catehi = APTS_TestDataFactory.createCategoryHierarchy(catego.id, 'test');
       insert catehi;
       
       Apttus_Config2__ClassificationHierarchy__c catSub = APTS_TestDataFactory.createSubCategory(catego.id,catehi.id);
       insert catSub; 
           
       Apttus_Config2__ProductOptionGroup__c optionGr = APTS_TestDataFactory.createProductOptionGroup(catehi.id,catSub.id);
       optionGr.Apttus_Config2__ParentOptionGroupId__c =catehi.id;
       insert optionGr;
       
       Apttus_Config2__ProductOptionComponent__c produOp = APTS_TestDataFactory.createProductOptionComponent(optionGr.id);
       produOp.Apttus_Config2__ParentProductId__c= prod.id;
       produOp.Apttus_Config2__ComponentProductId__c=prod1.id;
       insert produOp;
       
       Apttus_Config2__ProductClassification__c classpr = APTS_TestDataFactory.createProductClassification(catsub.id,prod1.id);
       insert classpr;

       Apttus_Config2__PriceListCategory__c pricelistHierarchy = new Apttus_Config2__PriceListCategory__c();
       pricelistHierarchy.Apttus_Config2__HierarchyId__c = catego.id;
       pricelistHierarchy.Apttus_Config2__PriceListId__c=oTestPricelist.id;
       pricelistHierarchy.Apttus_Config2__Sequence__c=1;
       insert pricelistHierarchy;

       Apttus_Config2__PriceListItem__c pricelistItem = APTS_TestDataFactory.createPriceListItem(oTestPricelist.id,prod1.id);
       pricelistItem.Apttus_Config2__ChargeType__c = 'Service Fee';
       insert pricelistItem;
       System.debug('pricelistItem=====TESTCLASS======>'+pricelistItem);

       Apttus_Config2__ProductHierarchyView__c hierarchyView = new Apttus_Config2__ProductHierarchyView__c();
       hierarchyView.Apttus_Config2__HierarchyId__c = catego.id;
       hierarchyView.Apttus_Config2__ParentClassificationId__c = catehi.id;
       hierarchyView.Apttus_Config2__ChildClassificationId__c = catSub.id;
       hierarchyView.Apttus_Config2__PriceListId__c = oTestPricelist.id;
       hierarchyView.Apttus_Config2__ProductClassificationId__c = classpr.id;
       hierarchyView.Apttus_Config2__IsInactive__c=false;
       hierarchyView.Apttus_Config2__ChildProductId__c=prod1.id;
       hierarchyView.Apttus_Config2__ChildLevel__c=1;
       hierarchyView.Apttus_Config2__ParentLevel__c=0;
       hierarchyView.Apttus_Config2__IsDetail__c=true;
       hierarchyView.Apttus_Config2__RelationshipType__c = 'Classification Node';
       insert hierarchyView;
       /*Apttus_Config2__AssetLineItem__c  alineItem = APTS_TestUtils.createAssetLineItem(acct.id,prod.id,null,null,null,null);
       alineItem.Apttus_Config2__Frequency__c='Monthly';
       alineItem.Apttus_Config2__PriceType__c='Recurring';
       alineItem.APTS_Type_Of_Contract__c = 'Rent';
       alineItem.Apttus_Config2__AssetStatus__c ='Activated';
       alineItem.Apttus_Config2__AccountId__c = acct.id;
       alineItem.APTS_relatedlist_agreement__c = oAggreement.id;
       alineItem.APTS_Is_Primary_L1_Line__c = true;
       alineItem.Apttus_Config2__HasOptions__c = true;
       insert alineItem;
       
       Apttus_Config2__AssetLineItem__c  alineItem2 = APTS_TestUtils.createAssetLineItem(acct.id,prod.id,null,null,null,null);
       alineItem2.Apttus_Config2__Frequency__c='Monthly';
       alineItem2.Apttus_Config2__PriceType__c='Recurring';
       alineItem2.APTS_Type_Of_Contract__c = 'Rent';
       alineItem2.Apttus_Config2__AssetStatus__c ='Renewed';
       alineItem2.APTS_Is_Primary_L1_Asset__c=alineItem.id;
       alineItem2.Apttus_Config2__PriceType__c='Recurring' ;
       alineItem2.Apttus_Config2__AssetStatus__c = 'Activated';
       alineItem2.Apttus_Config2__LineType__c='Option';
       alineItem2.Apttus_Config2__AccountId__c = acct.id;
       alineItem2.APTS_Is_Primary_L1_Line__c = true;
       insert alineItem2;
       
       Apttus_Config2__AssetLineItem__c  alineItem1 = APTS_TestUtils.createAssetLineItem(acct.id,prod.id,null,null,null,null);
       alineItem1.Apttus_Config2__Frequency__c='Monthly';
       alineItem1.Apttus_Config2__PriceType__c='Renewed';
       alineItem1.APTS_Type_Of_Contract__c = 'Free On Loan';
       alineItem1.Apttus_Config2__OptionId__c = prod1.id;
       alineItem1.Apttus_Config2__ParentAssetId__c = alineItem.id;
       alineItem1.APTS_Is_Primary_L1_Line__c = true;
       insert alineItem1;
       
       Apttus_Config2__AssetLineItem__c  alineItem3 = APTS_TestUtils.createAssetLineItem(acct.id,prod.id,null,null,null,null);
       alineItem3.Apttus_Config2__Frequency__c='Monthly';
       alineItem3.Apttus_Config2__PriceType__c='Recurring';
       alineItem3.APTS_Type_Of_Contract__c = 'Rent';
       alineItem3.Apttus_Config2__AssetStatus__c ='Activated';
       alineItem3.Apttus_Config2__AccountId__c = acct.id;
       alineItem3.APTS_relatedlist_agreement__c = oAggreement.id;
       alineItem3.APTS_Is_Primary_L1_Line__c = true;
       alineItem3.Apttus_Config2__HasOptions__c = true;
       insert alineItem3;*/
       
       Test.startTest();
       Map<ID,Apttus_Config2__LineItem__c> lineItemMap = New Map<ID,Apttus_Config2__LineItem__c>();
       List<Apttus_Config2__ProductConfiguration__c> productConfig  = [select id,Apttus_Config2__BillToAccountId__c,Apttus_Config2__ShipToAccountId__c,Apttus_Config2__ExpectedStartDate__c,Apttus_Config2__ExpectedEndDate__c,Apttus_Config2__PriceListId__c from Apttus_Config2__ProductConfiguration__c limit 1];

       Apttus_Config2__LineItem__c primarylineLI = APTS_TestDataFactory.createLineItem(productConfig[0], pricelistItem.Id, NULL, prod.Id, NULL, NULL, 1, 1, 1, 'Product/Service', NULL , 'Monthly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100, 2);
       primarylineLI.Apttus_Config2__IsOptionRollupLine__c=false;
       primarylineLI.Apttus_Config2__HasOptions__c=true;
       primarylineLI.Apttus_Config2__LineNumber__c=1;
       insert primarylineLI;

       if(lineItemMap.get(primarylineLI.id)==null){
           lineItemMap.put(primarylineLI.id,primarylineLI); 
        }

       //Apttus_Config2__LineItem__c freightChargesLI = APTS_TestDataFactory.createLineItem(oProductConfiguration, oPriceListFC.Id, NULL, freightCharges.Id, NULL, NULL, 1, 1, 1, 'Product/Service', NULL , 'Monthly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100, 2);
       String orderInputJSON = '[{"rowNumber":"8","assetName":"'+prod1.name+'","attributeList":[{"assignedValue":"Rent","attributeFieldName":"APTS_Type_of_contract__c","priceListId": "'+oTestPricelist.id+'","productId":"01t1v00000D02hXAAR","readOnly":true},{"assignedValue":"10","attributeFieldName":"APTS_Number_of_hours_per_month__c","priceListId": "'+oTestPricelist.id+'","productId":"01t1v00000D02hXAAR","readOnly":true}],"autoRenew":true,"basePrice":33,"chargeType":"Service Fee","discountPercentage":100,"endDate":"2029-03-22","linestatus":"New","netUnitPrice":0,"optionGroupText":"Technical Service","originalStartDate":"2028-01-02","priceListItemId":"a4l1x00000082yCAAQ","productid":"'+prod1.id+'","sellingTerm":14.67742,"startDate":"2028-01-02","subType":"ZX10","modifiedLineItem":"slds-is-edited slds-text-color_success customFontChanged","assetid":null}]';
       String bundleLevelAttributeJSON='[{"assignedValue":"Rent","attributeFieldName":"APTS_Type_of_contract__c","priceListId": "'+oTestPricelist.id+'","productId":"01t1v00000D02hXAAR","readOnly":true},{"assignedValue":"No","attributeFieldName":"APTS_Include_Free_Service__c","priceListId":"'+oTestPricelist.id+'","productId":"01t1v00000D02hXAAR","readOnly":false},{"assignedValue":"10","attributeFieldName":"APTS_Number_of_hours_per_month__c","priceListId":"'+oTestPricelist.id+'","productId":"01t1v00000D02hXAAR","readOnly":false},{"assignedValue":"100","attributeFieldName":"APTS_Consumer_Price__c","priceListId":"'+oTestPricelist.id+'","productId":"01t1v00000D02hXAAR","readOnly":false},{"assignedValue":"10","attributeFieldName":"APTS_First_Line_Response_Time__c","priceListId":"'+oTestPricelist.id+'","productId":"01t1v00000D02hXAAR","readOnly":false},{"assignedValue":"10","attributeFieldName":"APTS_ConversionId__c","priceListId":"'+oTestPricelist.id+'","productId":"01t1v00000D02hXAAR","readOnly":false},{"assignedValue":"10","attributeFieldName":"APTS_Labour_Coverage_Percent__c","priceListId":"'+oTestPricelist.id+'","productId":"01t1v00000D02hXAAR","readOnly":false}]';
       String cartId = productConfig[0].id;
       APTS_AddRemoveOptionController.processAddRemoveOptions(lineItemMap,orderInputJSON,cartId,bundleLevelAttributeJSON);
       
       lineItemMap.clear();
       Apttus_Config2__LineItem__c newlyAddedOption = APTS_TestDataFactory.createLineItem(productConfig[0], pricelistItem.Id, NULL, prod.Id, NULL, NULL, 1, 1, 1, 'Option', NULL , 'Monthly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100, 2);
       newlyAddedOption.Apttus_Config2__OptionId__c=prod1.id;
       insert newlyAddedOption;
       if(lineItemMap.get(newlyAddedOption.id)==null){
           lineItemMap.put(newlyAddedOption.id,newlyAddedOption); 
        }
       List<APTS_AddRemoveOptionController.AddRemoveOptionWrapper> addRemoveWrapperList = (List<APTS_AddRemoveOptionController.AddRemoveOptionWrapper>)JSON.deserializeStrict(orderInputJSON, List<APTS_AddRemoveOptionController.AddRemoveOptionWrapper>.class);
       List<APTS_AddRemoveOptionController.AttributeWrapper> bundleAttributesJSONList = (List<APTS_AddRemoveOptionController.AttributeWrapper>)JSON.deserializeStrict(bundleLevelAttributeJSON, List<APTS_AddRemoveOptionController.AttributeWrapper>.class);
       Map<Id,APTS_AddRemoveOptionController.AddRemoveOptionWrapper> addingOptionMap = new Map<Id,APTS_AddRemoveOptionController.AddRemoveOptionWrapper>();
       List<Apttus_Config2__LineItem__c> addList = new List<Apttus_Config2__LineItem__c>();
       Map<id,Apttus_Config2__ProductAttributeValue__c> productAttributeMap = new Map<id,Apttus_Config2__ProductAttributeValue__c>();
       for(APTS_AddRemoveOptionController.AddRemoveOptionWrapper addRemoveObj : addRemoveWrapperList){
           if(addRemoveObj.linestatus.equalsIgnoreCase('New')){
               if(addingOptionMap.get(addRemoveObj.productid)==null){
                   addingOptionMap.put(addRemoveObj.productid,addRemoveObj);
               }
           }
       }
       System.debug('addingOptionMap======TEST CLASS=========>'+addingOptionMap);
       APTS_AddRemoveOptionController.processAttributes(lineItemMap.values(),addingOptionMap,productAttributeMap,bundleAttributesJSONList);     
       APTS_AddRemoveOptionController.processNewlyAddedOptions(productConfig[0].id,lineItemMap.values(),addingOptionMap,addList,bundleAttributesJSONList);
       Test.stopTest();
   }
   @isTest static void test_useCase5() {
    User oTestUser = APTS_TestFacade.createTestUser();
    APTS_TestFacade.createMandatoryRecords(oTestUser);
    APTS_TestFacade.createAndConfigureAgreement(oTestUser);
    APTS_TestFacade.createAndConfigureOrder(oTestUser);
    List<Id> optionIds = new List<Id>();

    Account acct= APTS_TestUtils.createOrganisationproduct();
    insert acct;

    Contact oTestContact = APTS_TestUtils.createContact();
    insert oTestContact;

    Apttus_Config2__PriceList__c oTestPricelist = APTS_TestUtils.createPriceList();
    insert oTestPricelist;

    Apttus__APTS_Agreement__c oAggreement = APTS_TestUtils.createAgreement(oTestContact.Id, null, oTestPricelist.Id, acct.Id);
    oAggreement.Apttus__Status_Category__c = 'In Effect';
    oAggreement.Apttus__Status__c = 'Activated';
    oAggreement.Apttus__Contract_End_Date__c = Date.today().addYears(3);
    insert oAggreement;

    Product2 prod = APTS_TestUtils.createProduct('Package Caffetise1', '26940992', 'Machines');       
    insert prod;

    Product2 prod1 = APTS_TestUtils.createProduct('Package Caffetise2', '26940992', 'Machines');       
    insert prod1;

    Product2 prod2 = APTS_TestUtils.createProduct('Package Caffetise3', '26940992', 'Machines');       
    insert prod2;

    Product2 prod3 = APTS_TestUtils.createProduct('Package Caffetise4', '26940992', 'Machines');       
    insert prod3;

    Product2 prod4 = APTS_TestUtils.createProduct('Package Caffetise4', '26940992', 'Machines');       
    insert prod4;

    Apttus_Config2__PriceListItem__c pricelistItem = APTS_TestDataFactory.createPriceListItem(oTestPricelist.id,prod4.id);
    pricelistItem.Apttus_Config2__ChargeType__c = 'Service Fee';
    //pricelistItem.Apttus_Config2__Criteria__c='ABC';
    //pricelistItem.Apttus_Config2__ListPrice__c=10;
    insert pricelistItem;

    Apttus_Config2__PriceMatrix__c priceMatrix = new Apttus_Config2__PriceMatrix__c();
    priceMatrix.Apttus_Config2__PriceListItemId__c = pricelistItem.id;
    priceMatrix.Apttus_Config2__Sequence__c=1;
    insert priceMatrix;

    Apttus_Config2__PriceMatrixEntry__c pme = new Apttus_Config2__PriceMatrixEntry__c();
    pme.Apttus_Config2__Dimension1Value__c = '90';
    pme.Apttus_Config2__Sequence__c =1;
    pme.Apttus_Config2__PriceMatrixId__c = priceMatrix.id;
    pme.Apttus_Config2__AdjustmentAmount__c=50;
    insert pme;

    Apttus_Config2__AssetLineItem__c  alineItem = APTS_TestUtils.createAssetLineItem(acct.id,prod.id,null,null,null,null);
    alineItem.Apttus_Config2__Frequency__c='Monthly';
    alineItem.Apttus_Config2__PriceType__c='Recurring';
    alineItem.APTS_Type_Of_Contract__c = 'Rent';
    alineItem.Apttus_Config2__AssetStatus__c ='Activated';
    alineItem.Apttus_Config2__AccountId__c = acct.id;
    alineItem.APTS_relatedlist_agreement__c = oAggreement.id;
    alineItem.APTS_Is_Primary_L1_Line__c = true;
    alineItem.Apttus_Config2__HasOptions__c = true;
    alineItem.Apttus_Config2__ProductId__c=prod.id;
    alineItem.Apttus_Config2__StartDate__c=system.today().addYears(-2);
    alineItem.Apttus_Config2__EndDate__c=system.today().addYears(4);
    alineItem.Apttus_Config2__PriceListId__c = oTestPricelist.id;
    insert alineItem;

    Apttus_Config2__AssetLineItem__c  alineItem2 = APTS_TestUtils.createAssetLineItem(acct.id,prod.id,null,null,null,null);
    alineItem2.Apttus_Config2__Frequency__c='Monthly';
    alineItem2.Apttus_Config2__PriceType__c='Recurring';
    alineItem2.APTS_Type_Of_Contract__c = 'Rent';
    alineItem2.Apttus_Config2__AssetStatus__c ='Renewed';
    alineItem2.APTS_Is_Primary_L1_Asset__c=alineItem.id;
    alineItem2.Apttus_Config2__PriceType__c='Recurring' ;
    alineItem2.Apttus_Config2__AssetStatus__c = 'Activated';
    alineItem2.Apttus_Config2__LineType__c='Option';
    alineItem2.Apttus_Config2__AccountId__c = acct.id;
    alineItem2.Apttus_Config2__ProductId__c=prod.id;
    alineItem2.Apttus_Config2__OptionId__c=prod1.id;
    alineItem2.Apttus_Config2__BundleAssetId__c=alineItem.id;
    //alineItem2.Apttus_Config2__PriceType__c='Recurring';
    alineItem2.APTS_Option_Group_Text__c='Technical Service';
    alineItem2.Apttus_Config2__StartDate__c=system.today().addYears(-2);
    alineItem2.Apttus_Config2__EndDate__c=system.today().addYears(4);
    alineItem2.Apttus_Config2__PriceListId__c = oTestPricelist.id;
    insert alineItem2;


    Apttus_Config2__AssetLineItem__c  alineItem1 = APTS_TestUtils.createAssetLineItem(acct.id,prod.id,null,null,null,null);
    alineItem1.Apttus_Config2__Frequency__c='Monthly';
    alineItem1.APTS_Type_Of_Contract__c = 'Free On Loan';
    alineItem1.Apttus_Config2__LineType__c='Option';
    alineItem1.Apttus_Config2__OptionId__c = prod2.id;
    alineItem1.Apttus_Config2__ParentAssetId__c = alineItem.id;
    alineItem1.Apttus_Config2__PriceType__c='Recurring';
    alineItem1.APTS_Option_Group_Text__c='Technical Service';
    alineItem1.Apttus_Config2__ProductId__c=prod.id;
    alineItem1.APTS_Is_Primary_L1_Asset__c=alineItem.id;
    alineItem1.Apttus_Config2__StartDate__c=system.today().addYears(-2);
    alineItem1.Apttus_Config2__EndDate__c=system.today().addYears(4);
    alineItem1.APTS_Option_Group_Text__c='Response time';
    alineItem1.Apttus_Config2__BundleAssetId__c=alineItem.id;
    alineItem1.Apttus_Config2__PriceListId__c = oTestPricelist.id;
    insert alineItem1;

    Apttus_Config2__AssetLineItem__c  alineItem3 = APTS_TestUtils.createAssetLineItem(acct.id,prod.id,null,null,null,null);
    alineItem3.Apttus_Config2__Frequency__c='Monthly';
    alineItem3.Apttus_Config2__PriceType__c='Recurring';
    alineItem3.APTS_Type_Of_Contract__c = 'Rent';
    alineItem3.Apttus_Config2__LineType__c='Option';
    alineItem3.Apttus_Config2__AssetStatus__c ='Activated';
    alineItem3.Apttus_Config2__AccountId__c = acct.id;
    alineItem3.APTS_relatedlist_agreement__c = oAggreement.id;
    alineItem3.APTS_Is_Primary_L1_Asset__c=alineItem.id;
    alineItem3.Apttus_Config2__HasOptions__c = true;
    alineItem3.Apttus_Config2__PriceType__c='Recurring';
    alineItem3.APTS_Option_Group_Text__c='Response time';
    alineItem3.Apttus_Config2__ProductId__c=prod.id;
    alineItem3.Apttus_Config2__OptionId__c=prod3.id;
    alineItem3.Apttus_Config2__StartDate__c=system.today().addYears(-2);
    alineItem3.Apttus_Config2__EndDate__c=system.today().addYears(4);
    alineItem3.Apttus_Config2__BundleAssetId__c=alineItem.id;
    alineItem3.Apttus_Config2__PriceListId__c = oTestPricelist.id;
    insert alineItem3;

    Apttus_Config2__AssetAttributeValue__c assetattribute = new Apttus_Config2__AssetAttributeValue__c();
    assetattribute.Apttus_Config2__AssetLineItemId__c=alineItem.id;
    assetattribute.APTS_Type_Of_Contract__c='Rent';
    assetattribute.APTS_Purchase_Value__c=200;
    assetattribute.APTS_SourceSystem__c='123';
    assetattribute.APTS_Include_Free_Service__c='Yes';
    assetattribute.APTS_Number_of_hours_per_month__c=1;
    insert assetattribute;

    Apttus_Config2_AssetAdjustItem__c adjustment = new Apttus_Config2_AssetAdjustItem__c();
    adjustment.Apttus_Config2_AssetAdjustAmount__c=100;
    adjustment.Apttus_Config2_AssetAdjustType__c='% Discount';
    adjustment.Apttus_Config2_SubType__c='ZX10';
    adjustment.Apttus_Config2_AssetLineItemId__c=alineItem2.id;
    insert adjustment;

    Apttus_Config2__ClassificationName__c category = new Apttus_Config2__ClassificationName__c();
    category.name='Machine';
    category.Apttus_Config2__Type__c='Option Group';
    category.Apttus_Config2__HierarchyLabel__c='Machine';
    insert category;

    Apttus_Config2__ClassificationHierarchy__c oGroupCategory = new Apttus_Config2__ClassificationHierarchy__c();
    oGroupCategory.name='Technical service';
    oGroupCategory.Apttus_Config2__HierarchyId__c=category.id;
    oGroupCategory.Apttus_Config2__Label__c='Technical service';
    insert oGroupCategory;

    Apttus_Config2__ProductOptionGroup__c prodOpGroup = new Apttus_Config2__ProductOptionGroup__c();
    prodOpGroup.Apttus_Config2__OptionGroupId__c=oGroupCategory.id;
    prodOpGroup.Apttus_Config2__MaxOptions__c=1;
    prodOpGroup.Apttus_Config2__Sequence__c=1;
    insert prodOpGroup;

    Apttus_Config2__ProductOptionGroup__c prodOpGroup1 = new Apttus_Config2__ProductOptionGroup__c();
    prodOpGroup1.Apttus_Config2__OptionGroupId__c=oGroupCategory.id;
    prodOpGroup1.Apttus_Config2__MaxOptions__c=99999;
    prodOpGroup1.Apttus_Config2__Sequence__c=1;
    insert prodOpGroup1;

    Apttus_Config2__ProductOptionComponent__c prodOpGroupComp = new Apttus_Config2__ProductOptionComponent__c();
    prodOpGroupComp.Apttus_Config2__ProductOptionGroupId__c=prodOpGroup.id;
    prodOpGroupComp.Apttus_Config2__ComponentProductId__c=prod1.id;
    prodOpGroupComp.Apttus_Config2__ParentProductId__c=prod.id;
    prodOpGroupComp.Apttus_Config2__Sequence__c=1;
    insert prodOpGroupComp;

    Apttus_Config2__ProductAttributeGroup__c productAttGroup = new Apttus_Config2__ProductAttributeGroup__c();
    productAttGroup.name='testAttGroup';
    insert productAttGroup;

    Apttus_Config2__ProductAttributeGroupMember__c productAttGroupMem = new Apttus_Config2__ProductAttributeGroupMember__c();
    productAttGroupMem.name='testAttGroupMem';
    productAttGroupMem.Apttus_Config2__ProductId__c=prod.id;
    productAttGroupMem.Apttus_Config2__Sequence__c=1;
    productAttGroupMem.Apttus_Config2__AttributeGroupId__c=productAttGroup.id;
    insert productAttGroupMem;

    Apttus_Config2__ProductAttributeGroupMember__c productAttGroupMem1 = new Apttus_Config2__ProductAttributeGroupMember__c();
    productAttGroupMem1.name='testAttGroupMem';
    productAttGroupMem1.Apttus_Config2__ProductId__c=prod1.id;
    productAttGroupMem1.Apttus_Config2__Sequence__c=1;
    productAttGroupMem1.Apttus_Config2__AttributeGroupId__c=productAttGroup.id;
    insert productAttGroupMem1;

    Apttus_Config2__ProductAttribute__c productAttribute = new Apttus_Config2__ProductAttribute__c();
    productAttribute.Apttus_Config2__AttributeGroupId__c=productAttGroup.id;
    productAttribute.Apttus_Config2__IsHidden__c=false;
    productAttribute.Apttus_Config2__Sequence__c=1;
    productAttribute.Apttus_Config2__Field__c='APTS_Type_of_contract__c';
    insert productAttribute;

    Test.startTest();
    String assetid=alineItem.id;
    String ogId=prodOpGroup1.id;
    List<APTS_AddRemoveOptionController.AttributeWrapper> bundleAttributes = APTS_AddRemoveOptionController.getDefaultAttributesForBundle(assetid);
    list<APTS_AddRemoveOptionController.AddRemoveOptionWrapper> listOfOptions =APTS_AddRemoveOptionController.getRecsForModifyOptionAction(alineItem.id);
    List<Apttus_Config2__ProductOptionComponent__c> productOptionCompList =APTS_AddRemoveOptionController.getOptionGroupRecs(alineItem.id,listOfOptions,bundleAttributes);
    List<Apttus_Config2__ProductOptionComponent__c> options = APTS_AddRemoveOptionController.getOptions(assetid,ogId,listOfOptions,bundleAttributes);
    List<APTS_AddRemoveOptionController.AttributeWrapper> optionAttributes = APTS_AddRemoveOptionController.getRelatedAttributes(prod1.id,'Technical service',bundleAttributes);
    
     List<APTS_AddRemoveOptionController.AttributeWrapper> optionLevelAttributes = new List<APTS_AddRemoveOptionController.AttributeWrapper>();
    APTS_AddRemoveOptionController.AttributeWrapper optionattribute = new APTS_AddRemoveOptionController.AttributeWrapper();
    optionattribute.attributeFieldName='APTS_One_Time_Purchase__c';
    optionattribute.assignedValue='No';
    optionattribute.productId=prod4.id;
    optionLevelAttributes.add(optionattribute);
    
    List<APTS_AddRemoveOptionController.AddRemoveOptionWrapper> listOfModifiedOptions = APTS_AddRemoveOptionController.determinePriceOfOptions(assetid,prod4.id,'ABC',System.today(),'Cabinet',listOfOptions,true,10,'Discount%',10,'Monthly',optionLevelAttributes,bundleAttributes);
    List<APTS_AddRemoveOptionController.AddRemoveOptionWrapper> listOfModifiedOptions1 = APTS_AddRemoveOptionController.determinePriceOfOptions(assetid,prod4.id,'ABC',System.today(),'Cabinet',listOfOptions,true,10,'Discount%',100,'Monthly',optionLevelAttributes,bundleAttributes);
    List<APTS_AddRemoveOptionController.AddRemoveOptionWrapper> listOfModifiedOptions2 = APTS_AddRemoveOptionController.determinePriceOfOptions(assetid,prod4.id,'ABC',System.today(),'Cabinet',listOfOptions,true,10,'DiscountAmount',10,'Monthly',optionLevelAttributes,bundleAttributes);
    Decimal sellingTerm = APTS_AddRemoveOptionController.calculateSellingTerm(system.today(),System.today().addYears(1));
    Test.stopTest();
}


 @isTest static void test_useCase6() {
     List<Id> optionIds = new List<Id>();
    User oTestUser = APTS_TestFacade.createTestUser();
    APTS_TestFacade.createMandatoryRecords(oTestUser);
    APTS_TestFacade.createAndConfigureAgreement(oTestUser);
    APTS_TestFacade.createAndConfigureOrder(oTestUser);

    Account acct= APTS_TestUtils.createOrganisationproduct();
    insert acct;

    Contact oTestContact = APTS_TestUtils.createContact();
    insert oTestContact;

    Apttus_Config2__PriceList__c oTestPricelist = APTS_TestUtils.createPriceList();
    insert oTestPricelist;

    Apttus__APTS_Agreement__c oAggreement = APTS_TestUtils.createAgreement(oTestContact.Id, null, oTestPricelist.Id, acct.Id);
    oAggreement.Apttus__Status_Category__c = 'In Effect';
    oAggreement.Apttus__Status__c = 'Activated';
    oAggreement.Apttus__Contract_End_Date__c = Date.today().addYears(3);
    insert oAggreement;

    Product2 prod = APTS_TestUtils.createProduct('Package Caffetise1', '26940992', 'Machines');       
    insert prod;

    Product2 prod1 = APTS_TestUtils.createProduct('Package Caffetise2', '26940992', 'Machines');       
    insert prod1;

    Product2 prod2 = APTS_TestUtils.createProduct('Package Caffetise3', '26940992', 'Machines');       
    insert prod2;

    Product2 prod3 = APTS_TestUtils.createProduct('Package Caffetise4', '26940992', 'Machines');       
    insert prod3;

    Product2 prod4 = APTS_TestUtils.createProduct('Package Caffetise4', '26940992', 'Machines');       
    insert prod4;

    Apttus_Config2__PriceListItem__c pricelistItem = APTS_TestDataFactory.createPriceListItem(oTestPricelist.id,prod4.id);
    pricelistItem.Apttus_Config2__ChargeType__c = 'Service Fee';
    //pricelistItem.Apttus_Config2__Criteria__c='ABC';
    //pricelistItem.Apttus_Config2__ListPrice__c=10;
    insert pricelistItem;
    
     Apttus_Config2__PriceListItem__c pricelistItem2 = APTS_TestDataFactory.createPriceListItem(oTestPricelist.id,prod1.id);
    pricelistItem.Apttus_Config2__ChargeType__c = 'Sales Price';
    //pricelistItem.Apttus_Config2__Criteria__c='ABC';
    //pricelistItem.Apttus_Config2__ListPrice__c=10;
    insert pricelistItem2;
    
     Apttus_Config2__PriceListItem__c pricelistItem3 = APTS_TestDataFactory.createPriceListItem(oTestPricelist.id,prod2.id);
    pricelistItem.Apttus_Config2__ChargeType__c = 'Additional Service Fee';
    //pricelistItem.Apttus_Config2__Criteria__c='ABC';
    //pricelistItem.Apttus_Config2__ListPrice__c=10;
    insert pricelistItem3;
    
     Apttus_Config2__PriceListItem__c pricelistItem4 = APTS_TestDataFactory.createPriceListItem(oTestPricelist.id,prod3.id);
    pricelistItem.Apttus_Config2__ChargeType__c = 'Additional Service Fee';
    //pricelistItem.Apttus_Config2__Criteria__c='ABC';
    //pricelistItem.Apttus_Config2__ListPrice__c=10;
    insert pricelistItem4;

    Apttus_Config2__PriceMatrix__c priceMatrix = new Apttus_Config2__PriceMatrix__c();
    priceMatrix.Apttus_Config2__PriceListItemId__c = pricelistItem.id;
    priceMatrix.Apttus_Config2__Sequence__c=1;
    insert priceMatrix;

    Apttus_Config2__PriceMatrixEntry__c pme = new Apttus_Config2__PriceMatrixEntry__c();
    pme.Apttus_Config2__Dimension1Value__c = '90';
    pme.Apttus_Config2__Sequence__c =1;
    pme.Apttus_Config2__PriceMatrixId__c = priceMatrix.id;
    pme.Apttus_Config2__AdjustmentAmount__c=50;
    insert pme;

    Apttus_Config2__AssetLineItem__c  alineItem = APTS_TestUtils.createAssetLineItem(acct.id,prod.id,null,null,null,null);
    alineItem.Apttus_Config2__Frequency__c='Monthly';
    alineItem.Apttus_Config2__PriceType__c='Recurring';
    alineItem.APTS_Type_Of_Contract__c = 'Rent';
    alineItem.Apttus_Config2__AssetStatus__c ='Activated';
    alineItem.Apttus_Config2__AccountId__c = acct.id;
    alineItem.APTS_relatedlist_agreement__c = oAggreement.id;
    alineItem.APTS_Is_Primary_L1_Line__c = true;
    alineItem.Apttus_Config2__HasOptions__c = true;
    alineItem.Apttus_Config2__ProductId__c=prod.id;
    alineItem.Apttus_Config2__StartDate__c=system.today().addYears(-2);
    alineItem.Apttus_Config2__EndDate__c=system.today().addYears(4);
    alineItem.Apttus_Config2__PriceListId__c = oTestPricelist.id;
    insert alineItem;

    Apttus_Config2__AssetLineItem__c  alineItem2 = APTS_TestUtils.createAssetLineItem(acct.id,prod.id,null,null,null,null);
    alineItem2.Apttus_Config2__Frequency__c='Monthly';
    alineItem2.Apttus_Config2__PriceType__c='Recurring';
    alineItem2.APTS_Type_Of_Contract__c = 'Rent';
    alineItem2.Apttus_Config2__AssetStatus__c ='Renewed';
    alineItem2.APTS_Is_Primary_L1_Asset__c=alineItem.id;
    alineItem2.Apttus_Config2__PriceType__c='Recurring' ;
    alineItem2.Apttus_Config2__AssetStatus__c = 'Activated';
    alineItem2.Apttus_Config2__LineType__c='Option';
    alineItem2.Apttus_Config2__AccountId__c = acct.id;
    alineItem2.Apttus_Config2__ProductId__c=prod.id;
    alineItem2.Apttus_Config2__OptionId__c=prod1.id;
    alineItem2.Apttus_Config2__BundleAssetId__c=alineItem.id;
    //alineItem2.Apttus_Config2__PriceType__c='Recurring';
    alineItem2.APTS_Option_Group_Text__c='Technical Service';
    alineItem2.Apttus_Config2__StartDate__c=system.today().addYears(-2);
    alineItem2.Apttus_Config2__EndDate__c=system.today().addYears(4);
    alineItem2.Apttus_Config2__PriceListId__c = oTestPricelist.id;
    insert alineItem2;


    Apttus_Config2__AssetLineItem__c  alineItem1 = APTS_TestUtils.createAssetLineItem(acct.id,prod.id,null,null,null,null);
    alineItem1.Apttus_Config2__Frequency__c='Monthly';
    alineItem1.APTS_Type_Of_Contract__c = 'Free On Loan';
    alineItem1.Apttus_Config2__LineType__c='Option';
    alineItem1.Apttus_Config2__OptionId__c = prod2.id;
    alineItem1.Apttus_Config2__ParentAssetId__c = alineItem.id;
    alineItem1.Apttus_Config2__PriceType__c='Recurring';
    alineItem1.APTS_Option_Group_Text__c='Technical Service';
    alineItem1.Apttus_Config2__ProductId__c=prod.id;
    alineItem1.APTS_Is_Primary_L1_Asset__c=alineItem.id;
    alineItem1.Apttus_Config2__StartDate__c=system.today().addYears(-2);
    alineItem1.Apttus_Config2__EndDate__c=system.today().addYears(4);
    alineItem1.APTS_Option_Group_Text__c='Response time';
    alineItem1.Apttus_Config2__BundleAssetId__c=alineItem.id;
    alineItem1.Apttus_Config2__PriceListId__c = oTestPricelist.id;
    insert alineItem1;

    Apttus_Config2__AssetLineItem__c  alineItem3 = APTS_TestUtils.createAssetLineItem(acct.id,prod.id,null,null,null,null);
    alineItem3.Apttus_Config2__Frequency__c='Monthly';
    alineItem3.Apttus_Config2__PriceType__c='Recurring';
    alineItem3.APTS_Type_Of_Contract__c = 'Rent';
    alineItem3.Apttus_Config2__LineType__c='Option';
    alineItem3.Apttus_Config2__AssetStatus__c ='Activated';
    alineItem3.Apttus_Config2__AccountId__c = acct.id;
    alineItem3.APTS_relatedlist_agreement__c = oAggreement.id;
    alineItem3.APTS_Is_Primary_L1_Asset__c=alineItem.id;
    alineItem3.Apttus_Config2__HasOptions__c = true;
    alineItem3.Apttus_Config2__PriceType__c='Recurring';
    alineItem3.APTS_Option_Group_Text__c='Response time';
    alineItem3.Apttus_Config2__ProductId__c=prod.id;
    alineItem3.Apttus_Config2__OptionId__c=prod3.id;
    alineItem3.Apttus_Config2__StartDate__c=system.today().addYears(-2);
    alineItem3.Apttus_Config2__EndDate__c=system.today().addYears(4);
    alineItem3.Apttus_Config2__BundleAssetId__c=alineItem.id;
    alineItem3.Apttus_Config2__PriceListId__c = oTestPricelist.id;
    insert alineItem3;
    
   /* Apttus_Config2__AssetLineItem__c  alineItem4 = APTS_TestUtils.createAssetLineItem(acct.id,prod.id,null,null,null,null);
    alineItem4.Apttus_Config2__Frequency__c='Monthly';
    alineItem4.Apttus_Config2__PriceType__c='Recurring';
    alineItem4.APTS_Type_Of_Contract__c = 'Rent';
    alineItem4.Apttus_Config2__LineType__c='Option';
    alineItem4.Apttus_Config2__AssetStatus__c ='Activated';
    alineItem4.Apttus_Config2__AccountId__c = acct.id;
    alineItem4.APTS_relatedlist_agreement__c = oAggreement.id;
    alineItem4.APTS_Is_Primary_L1_Asset__c=alineItem.id;
    alineItem4.Apttus_Config2__HasOptions__c = true;
    alineItem4.Apttus_Config2__PriceType__c='Recurring';
    alineItem4.APTS_Option_Group_Text__c='Response time';
    alineItem4.Apttus_Config2__ProductId__c=prod.id;
    alineItem4.Apttus_Config2__OptionId__c=prod4.id;
    alineItem4.Apttus_Config2__StartDate__c=system.today().addYears(-2);
    alineItem4.Apttus_Config2__EndDate__c=system.today().addYears(4);
    alineItem4.Apttus_Config2__BundleAssetId__c=alineItem.id;
    alineItem4.Apttus_Config2__PriceListId__c = oTestPricelist.id;
    insert alineItem4;
*/
    Apttus_Config2__AssetAttributeValue__c assetattribute = new Apttus_Config2__AssetAttributeValue__c();
    assetattribute.Apttus_Config2__AssetLineItemId__c=alineItem.id;
    assetattribute.APTS_Type_Of_Contract__c='Rent';
    assetattribute.APTS_Purchase_Value__c=200;
    assetattribute.APTS_SourceSystem__c='123';
    assetattribute.APTS_Include_Free_Service__c='Yes';
    assetattribute.APTS_Number_of_hours_per_month__c=1;
    insert assetattribute;

    Apttus_Config2_AssetAdjustItem__c adjustment = new Apttus_Config2_AssetAdjustItem__c();
    adjustment.Apttus_Config2_AssetAdjustAmount__c=100;
    adjustment.Apttus_Config2_AssetAdjustType__c='% Discount';
    adjustment.Apttus_Config2_SubType__c='ZX10';
    adjustment.Apttus_Config2_AssetLineItemId__c=alineItem2.id;
    insert adjustment;

    Apttus_Config2__ClassificationName__c category = new Apttus_Config2__ClassificationName__c();
    category.name='Machine';
    category.Apttus_Config2__Type__c='Option Group';
    category.Apttus_Config2__HierarchyLabel__c='Machine';
    insert category;

    Apttus_Config2__ClassificationHierarchy__c oGroupCategory = new Apttus_Config2__ClassificationHierarchy__c();
    oGroupCategory.name='Technical service';
    oGroupCategory.Apttus_Config2__HierarchyId__c=category.id;
    oGroupCategory.Apttus_Config2__Label__c='Technical service';
    insert oGroupCategory;

    Apttus_Config2__ProductOptionGroup__c prodOpGroup = new Apttus_Config2__ProductOptionGroup__c();
    prodOpGroup.Apttus_Config2__OptionGroupId__c=oGroupCategory.id;
    prodOpGroup.Apttus_Config2__MaxOptions__c=1;
    prodOpGroup.Apttus_Config2__Sequence__c=1;
    insert prodOpGroup;

    Apttus_Config2__ProductOptionGroup__c prodOpGroup1 = new Apttus_Config2__ProductOptionGroup__c();
    prodOpGroup1.Apttus_Config2__OptionGroupId__c=oGroupCategory.id;
    prodOpGroup1.Apttus_Config2__MaxOptions__c=99999;
    prodOpGroup1.Apttus_Config2__Sequence__c=1;
    insert prodOpGroup1;

    Apttus_Config2__ProductOptionComponent__c prodOpGroupComp = new Apttus_Config2__ProductOptionComponent__c();
    prodOpGroupComp.Apttus_Config2__ProductOptionGroupId__c=prodOpGroup.id;
    prodOpGroupComp.Apttus_Config2__ComponentProductId__c=prod1.id;
    prodOpGroupComp.Apttus_Config2__ParentProductId__c=prod.id;
    prodOpGroupComp.Apttus_Config2__Sequence__c=1;
    insert prodOpGroupComp;

    Apttus_Config2__ProductAttributeGroup__c productAttGroup = new Apttus_Config2__ProductAttributeGroup__c();
    productAttGroup.name='testAttGroup';
    insert productAttGroup;

    Apttus_Config2__ProductAttributeGroupMember__c productAttGroupMem = new Apttus_Config2__ProductAttributeGroupMember__c();
    productAttGroupMem.name='testAttGroupMem';
    productAttGroupMem.Apttus_Config2__ProductId__c=prod.id;
    productAttGroupMem.Apttus_Config2__Sequence__c=1;
    productAttGroupMem.Apttus_Config2__AttributeGroupId__c=productAttGroup.id;
    insert productAttGroupMem;

    Apttus_Config2__ProductAttributeGroupMember__c productAttGroupMem1 = new Apttus_Config2__ProductAttributeGroupMember__c();
    productAttGroupMem1.name='testAttGroupMem';
    productAttGroupMem1.Apttus_Config2__ProductId__c=prod1.id;
    productAttGroupMem1.Apttus_Config2__Sequence__c=1;
    productAttGroupMem1.Apttus_Config2__AttributeGroupId__c=productAttGroup.id;
    insert productAttGroupMem1;

    Apttus_Config2__ProductAttribute__c productAttribute = new Apttus_Config2__ProductAttribute__c();
    productAttribute.Apttus_Config2__AttributeGroupId__c=productAttGroup.id;
    productAttribute.Apttus_Config2__IsHidden__c=false;
    productAttribute.Apttus_Config2__Sequence__c=1;
    productAttribute.Apttus_Config2__Field__c='APTS_Type_of_contract__c';
    insert productAttribute;

    Test.startTest();
    String assetid=alineItem.id;
    String ogId=prodOpGroup1.id;
    List<APTS_ContractChangeNewUXController.AttributeWrapper> bundleAttributes = APTS_ContractChangeNewUXController.getDefaultAttributesForBundle(assetid);
    List<APTS_ContractChangeNewUXController.AttributeWrapper> bundleAttributesNew = APTS_ContractChangeNewUXController.getDefaultAttributesForNewBundle(assetid,'Sales');
    list<APTS_ContractChangeNewUXController.AddRemoveOptionWrapper> listOfOptions =APTS_ContractChangeNewUXController.getRecsForModifyOptionAction(alineItem.id);
   
    //List<Apttus_Config2__ProductOptionComponent__c> options = APTS_ContractChangeNewUXController.getOptions(assetid,ogId,listOfOptions,bundleAttributes);
    List<APTS_ContractChangeNewUXController.AttributeWrapper> optionAttributes = APTS_ContractChangeNewUXController.getRelatedAttributes(prod1.id,'Technical service',bundleAttributes);
    
     List<APTS_ContractChangeNewUXController.AttributeWrapper> optionLevelAttributes = new List<APTS_ContractChangeNewUXController.AttributeWrapper>();
    APTS_ContractChangeNewUXController.AttributeWrapper optionattribute = new APTS_ContractChangeNewUXController.AttributeWrapper();
    optionattribute.attributeFieldName='APTS_One_Time_Purchase__c';
    optionattribute.assignedValue='No';
    optionattribute.productId=prod4.id;
    optionLevelAttributes.add(optionattribute);
    
    optionIds.add(prod1.id);
    optionIds.add(prod2.id);
    optionIds.add(prod4.id);
    optionIds.add(prod3.id);
    
     List<String> tocList = APTS_ContractChangeNewUXController.getAvailableTOC(assetid);
    List<APTS_ContractChangeNewUXController.AddRemoveOptionWrapper> listOfModifiedOptions1 = APTS_ContractChangeNewUXController.determinePriceOfOptions(assetid,prod4.id,'ABC',System.today(),'Cabinet',listOfOptions,true,10,'Discount%',100,'Monthly',optionLevelAttributes,bundleAttributes);
    List<APTS_ContractChangeNewUXController.AddRemoveOptionWrapper> listOfModifiedOptions2 = APTS_ContractChangeNewUXController.determinePriceOfOptions(assetid,prod4.id,'ABC',System.today(),'Cabinet',listOfOptions,true,10,'DiscountAmount',10,'Monthly',optionLevelAttributes,bundleAttributes);
    Decimal sellingTerm = APTS_ContractChangeNewUXController.calculateSellingTerm(system.today(),System.today().addYears(1));
    System.debug('Lavanya test'+bundleAttributesNew.size()+''+optionIds.size());
    List<APTS_ContractChangeNewUXController.AddRemoveOptionWrapper> listOfModifiedOptions = APTS_ContractChangeNewUXController.determineCTCOptionPrice(assetid,bundleAttributesNew,System.today(),optionIds);
    String finalWrapData =  JSON.serialize(listOfModifiedOptions);
   // String finalWrapData = '[{"assetName":"WATERFILTER REPLACEMENT","basePrice":10,"typeOfContract":"Sales","sellingTerm":56.80645,"startDate":"2021-01-28","endDate":"2025-10-21","chargeType":"Additional Service Fee","basePriceOverride":"100","billingFrequency":"Yearly","netUnitPrice":"100","assetid":"'+assetid+'","attributeList":[{"assignedValue":"Sales","attributeFieldName":"APTS_Type_of_contract__c","EndDate":"2025-10-21","priceListId":"'+oTestPricelist.id+'","productId"'+prod4.id+'","readOnly":true,"StartDate":"2021-01-28"},{"assignedValue":"No","attributeFieldName":"APTS_Refurbished__c","EndDate":"2025-10-21","priceListId":"'+oTestPricelist.id+'","productId":"'+prod4.id+'","readOnly":true,"StartDate":"2021-01-28"},{"assignedValue":"24","attributeFieldName":"APTS_Number_of_months__c","EndDate":"2025-10-21","priceListId":"'+oTestPricelist.id+'","productId":"'+prod4.id+'","readOnly":false,"StartDate":"2021-01-28"}],"autoRenew":true,"linestatus":"New","optionGroupText":"Value Added Service","originalStartDate":"2021-01-28","priceListItemId":"'+pricelistItem.id+'","productid":"'+prod4.id+'","bpoModified":"slds-is-edited slds-text-color_success customFontChanged","netUnitPriceModified":"slds-is-edited slds-text-color_success customFontChanged"}]';
    Apttus_Config2__Order__c machineOrder = APTS_ContractChangeNewUXController.createOrder(assetid,finalWrapData,System.today().addMonths(5));
    
    //CloneBundleLogic 
   /* Apttus_Config2__BillingPreference__c billpref = APTS_TestUtils.createBillingPrefrence('January');
            insert billpref;
    
    machineOrder = APTS_TestUtils.createOrder('New',oTestPricelist.id,acct.Id,billpref.id);        
    machineOrder.RecordTypeId = Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByName().get(System.Label.APTS_Machine_Order).getRecordTypeId();    
    machineOrder.Apttus_Config2__SoldToAccountId__c = acct.id;
    machineOrder.APTS_Requested_Installation_Date__c =Date.newInstance(2018, 10, 22);
    insert machineOrder;
   */

    Apttus_Config2__ProductConfiguration__c machineProdConfig = new Apttus_Config2__ProductConfiguration__c(
        Apttus_Config2__AccountId__c=acct.id, 
        Name = 'Sample', 
        Apttus_Config2__OrderId__c = machineOrder.id, 
        Apttus_Config2__PriceListId__c = oTestPricelist.id);
    insert machineProdConfig;
    
    
    
    Apttus_Config2__LineItem__c machineLineItem = new Apttus_Config2__LineItem__c(
        Apttus_Config2__ConfigurationId__c = machineProdConfig.id, 
        Apttus_Config2__ProductId__c=prod.id,currencyISOCode='EUR',Apttus_Config2__LineType__c = 'Product/Service',
        Apttus_Config2__HasIncentives__c=false,Apttus_Config2__LineStatus__c='Upgraded',Apttus_Config2__PrimaryLineNumber__c=1,
        Apttus_Config2__ItemSequence__c=1, Apttus_Config2__LineNumber__c=1,
        APTS_Category_Level__c = 'Category');
    insert machineLineItem;
    
    Apttus_Config2__LineItem__c optionLineItem = new Apttus_Config2__LineItem__c(
        Apttus_Config2__ConfigurationId__c = machineProdConfig.id, 
        Apttus_Config2__ProductId__c=prod.id,
        Apttus_Config2__OptionId__c=prod1.id,
        Apttus_Config2__HasIncentives__c=false,
        Apttus_Config2__LineStatus__c='Upgraded',currencyISOCode='EUR',
        Apttus_Config2__ItemSequence__c=2,
        Apttus_Config2__LineNumber__c=1,
        Apttus_Config2__ParentBundleNumber__c=1,
        Apttus_Config2__LineType__c = 'Option');
    insert optionLineItem;
    
    
   
    
    Apttus_Config2__LineItem__c optionLineItem1 = new Apttus_Config2__LineItem__c(
        Apttus_Config2__ConfigurationId__c = machineProdConfig.id, 
        Apttus_Config2__ProductId__c=prod.id,
        Apttus_Config2__OptionId__c=prod4.id,
        Apttus_Config2__HasIncentives__c=false,Apttus_Config2__LineStatus__c='Upgraded',currencyISOCode='EUR',
        Apttus_Config2__ItemSequence__c=3,Apttus_Config2__LineNumber__c=1,Apttus_Config2__ParentBundleNumber__c=1,Apttus_Config2__LineType__c = 'Option');
    insert optionLineItem1;


    Apttus_Config2__LineItem__c optionLineItem2 = new Apttus_Config2__LineItem__c(
        Apttus_Config2__ConfigurationId__c = machineProdConfig.id, 
        Apttus_Config2__ProductId__c=prod.id,
        Apttus_Config2__OptionId__c=prod3.id,
        Apttus_Config2__HasIncentives__c=false,Apttus_Config2__LineStatus__c='Upgraded',currencyISOCode='EUR',
        Apttus_Config2__ItemSequence__c=4,Apttus_Config2__LineNumber__c=1,Apttus_Config2__ParentBundleNumber__c=1,Apttus_Config2__LineType__c = 'Option');
    insert optionLineItem2;


    Apttus_Config2__LineItem__c optionLineItem3 = new Apttus_Config2__LineItem__c(
        Apttus_Config2__ConfigurationId__c = machineProdConfig.id, 
        Apttus_Config2__ProductId__c=prod.id,
        Apttus_Config2__OptionId__c=prod2.id,
        Apttus_Config2__HasIncentives__c=false,Apttus_Config2__LineStatus__c='Upgraded',currencyISOCode='EUR',
        Apttus_Config2__ItemSequence__c=5,Apttus_Config2__LineNumber__c=1,Apttus_Config2__ParentBundleNumber__c=1,Apttus_Config2__LineType__c = 'Option');
    insert optionLineItem3;


    //New Lines

    Apttus_Config2__LineItem__c machineLineItem11 = new Apttus_Config2__LineItem__c(
        Apttus_Config2__ConfigurationId__c = machineProdConfig.id, 
        Apttus_Config2__ProductId__c=prod.id,currencyISOCode='EUR',Apttus_Config2__LineType__c = 'Product/Service',
        Apttus_Config2__HasIncentives__c=false,Apttus_Config2__LineStatus__c='New',Apttus_Config2__PrimaryLineNumber__c=1,
        Apttus_Config2__ItemSequence__c=1, Apttus_Config2__LineNumber__c=1,
        APTS_Category_Level__c = 'Category');
    insert machineLineItem11;
    
    Apttus_Config2__LineItem__c optionLineItem11 = new Apttus_Config2__LineItem__c(
        Apttus_Config2__ConfigurationId__c = machineProdConfig.id, 
        Apttus_Config2__ProductId__c=prod.id,
        Apttus_Config2__OptionId__c=prod1.id,
        Apttus_Config2__HasIncentives__c=false,
        Apttus_Config2__LineStatus__c='New',currencyISOCode='EUR',
        Apttus_Config2__ItemSequence__c=2,
        Apttus_Config2__LineNumber__c=1,
        Apttus_Config2__ParentBundleNumber__c=1,
        Apttus_Config2__LineType__c = 'Option');
    insert optionLineItem11;
    
    
   
    
    Apttus_Config2__LineItem__c optionLineItem12 = new Apttus_Config2__LineItem__c(
        Apttus_Config2__ConfigurationId__c = machineProdConfig.id, 
        Apttus_Config2__ProductId__c=prod.id,
        Apttus_Config2__OptionId__c=prod4.id,
        Apttus_Config2__HasIncentives__c=false,Apttus_Config2__LineStatus__c='New',currencyISOCode='EUR',
        Apttus_Config2__ItemSequence__c=3,Apttus_Config2__LineNumber__c=1,Apttus_Config2__ParentBundleNumber__c=1,Apttus_Config2__LineType__c = 'Option');
    insert optionLineItem12;


    Apttus_Config2__LineItem__c optionLineItem23 = new Apttus_Config2__LineItem__c(
        Apttus_Config2__ConfigurationId__c = machineProdConfig.id, 
        Apttus_Config2__ProductId__c=prod.id,
        Apttus_Config2__OptionId__c=prod3.id,
        Apttus_Config2__HasIncentives__c=false,Apttus_Config2__LineStatus__c='New',currencyISOCode='EUR',
        Apttus_Config2__ItemSequence__c=4,Apttus_Config2__LineNumber__c=1,Apttus_Config2__ParentBundleNumber__c=1,Apttus_Config2__LineType__c = 'Option');
    insert optionLineItem23;


    Apttus_Config2__LineItem__c optionLineItem33 = new Apttus_Config2__LineItem__c(
        Apttus_Config2__ConfigurationId__c = machineProdConfig.id, 
        Apttus_Config2__ProductId__c=prod.id,
        Apttus_Config2__OptionId__c=prod2.id,
        Apttus_Config2__HasIncentives__c=false,Apttus_Config2__LineStatus__c='New',currencyISOCode='EUR',
        Apttus_Config2__ItemSequence__c=5,Apttus_Config2__LineNumber__c=1,Apttus_Config2__ParentBundleNumber__c=1,Apttus_Config2__LineType__c = 'Option');
    insert optionLineItem33;
    
    
    
    Apttus_Config2__ProductAttributeValue__c machinePav = new Apttus_Config2__ProductAttributeValue__c();
    machinePav.CurrencyIsoCode='EUR';
    machinePav.Apttus_Config2__LineItemId__c = machineLineItem.id;
    Database.insert(machinePav);
    
    
    Apttus_Config2__ProductAttributeValue__c optionPav = new Apttus_Config2__ProductAttributeValue__c();
    optionPav.Apttus_Config2__LineItemId__c = optionLineItem.id;
    optionPav.CurrencyIsoCode='EUR';
    Database.insert(optionPav);
    
    Apttus_Config2__ProductAttributeValue__c machinePav1 = new Apttus_Config2__ProductAttributeValue__c();
    machinePav1.Apttus_Config2__LineItemId__c = machineLineItem.id;
    Database.insert(machinePav1);
    
    
    Apttus_Config2__ProductAttributeValue__c optionPav1 = new Apttus_Config2__ProductAttributeValue__c();
    optionPav1.Apttus_Config2__LineItemId__c = optionLineItem1.id;
    optionPav1.CurrencyIsoCode='EUR';
    Database.insert(optionPav1);
    
    Apttus_Config2__TempObject__c oTempObject = new Apttus_Config2__TempObject__c();
    oTempObject.Apttus_Config2__Data__c = '<?xml version="1.0" encoding="UTF-8"?> <ConfigRequest> <Params> <Param> <Name>flow</Name> <Value>' + 'NGChangeContract' + '</Value> </Param> </Params> </ConfigRequest>';
    oTempObject.Apttus_Config2__ConfigurationId__c = machineProdConfig.Id;
    insert oTempObject;
   
    APTS_CloneBundle2.CloneBundleLogic(machineProdConfig.id,System.today(),System.today().addMonths(60),listOfModifiedOptions);     

    Test.stopTest();
}
}