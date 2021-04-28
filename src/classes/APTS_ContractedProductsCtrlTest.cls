@isTest
public class APTS_ContractedProductsCtrlTest { 
    public static Apttus_Config2__ProductConfiguration__c ncProdConfig;
    public static Apttus_Config2__ProductConfiguration__c standardProdConfig;
    public static Apttus_Config2__ProductConfiguration__c machineProdConfig;
    public static Apttus_Config2__ProductConfiguration__c ncProdOrderConfig;
    public static Apttus_Config2__ProductConfiguration__c standardOrderProdConfig;
    public static Apttus_Config2__ProductConfiguration__c machineOrderProdConfig;
    

    public static Product2 standardProduct;
    public static Product2 machineProduct;
  

    public static Apttus_Config2__Order__c ncOrder;
    public static Apttus_Config2__Order__c standardOrder;
    public static Apttus_Config2__Order__c machineOrder;
   

    public static Apttus__AgreementLineItem__c standardAgreementLineItem;
    public static Apttus__AgreementLineItem__c machineAgreementLineItem;


    public static void filldata()
    {
        // Creation of test accounts
         User testUser = APTS_TestUtils.createUser();
        testUser.LocaleSidKey = 'nl_NL';
        
        System.runAs(testUser) {
        Account ncAccount = new Account(Name = 'NC Account', Phone = '+3209999999');
        ncAccount.Sales_Organization__c='SAP_0111';
        insert ncAccount;

        Account standardAccount = new Account(Name = 'STD Account', Phone = '+3209999999');
        standardAccount.Sales_Organization__c='SAP_0111';
        insert standardAccount;

        Account machineAccount = new Account(Name = 'Machine Account', Phone = '+3209999999');
        machineAccount.Sales_Organization__c='SAP_0111';
        insert machineAccount;
        
       
        standardProduct = APTS_TestUtils.createProduct('Standard Product', '26940998', 'Coffee'); 
        standardProduct.Apttus_Config2__ConfigurationType__c = 'Standalone';
        standardProduct.APTS_Associated_Sales_Org__c='SAP_0333';
        insert standardProduct;
                    
        machineProduct = APTS_TestUtils.createProduct('Machine Product', '26940992', 'Machines');       
        machineProduct.Apttus_Config2__ConfigurationType__c = 'Bundle';
        machineProduct.APTS_Associated_Sales_Org__c='SAP_0333';
        insert machineProduct;
        
    
                    
        Apttus_Config2__ClassificationName__c standardcategory = new Apttus_Config2__ClassificationName__c();
        standardcategory.Name = 'Coffee';
        standardcategory.Apttus_Config2__Active__c = true;
        standardcategory.Apttus_Config2__HierarchyLabel__c = 'Coffee';
        standardcategory.Apttus_Config2__Type__c = 'Offering';
        standardcategory.APTS_Allow_Adjustments__c = true;
        insert standardcategory;

        Apttus_Config2__ClassificationName__c machinecategory = new Apttus_Config2__ClassificationName__c();
        machinecategory.Name = 'Machines';
        machinecategory.Apttus_Config2__Active__c = true;
        machinecategory.Apttus_Config2__HierarchyLabel__c = 'Machines';
        machinecategory.Apttus_Config2__Type__c = 'Offering';
        machinecategory.APTS_Allow_Adjustments__c = true;
        insert machinecategory;
        
        Apttus_Config2__ClassificationHierarchy__c standardCategoryHierarchy = new Apttus_Config2__ClassificationHierarchy__c();
        standardCategoryHierarchy.Name = 'Coffee';
        standardCategoryHierarchy.Apttus_Config2__HierarchyId__c = standardcategory.Id;
        standardCategoryHierarchy.Apttus_Config2__AncestorId__c = null;
        standardCategoryHierarchy.Apttus_Config2__DefaultSearchCategory__c = false;
        standardCategoryHierarchy.Apttus_Config2__ExpandedByDefault__c = false;
        standardCategoryHierarchy.Apttus_Config2__HideAllSearchFilters__c = false;
        standardCategoryHierarchy.Apttus_Config2__IncludeInTotalsView__c = true;
        standardCategoryHierarchy.Apttus_Config2__IsHidden__c = false;
        standardCategoryHierarchy.Apttus_Config2__IsPicklist__c = false;
        standardCategoryHierarchy.Apttus_Config2__Label__c = 'Coffee';
        standardCategoryHierarchy.Apttus_Config2__LargeImageSize__c = '20x20';
        standardCategoryHierarchy.Apttus_Config2__Left__c = 1;
        standardCategoryHierarchy.Apttus_Config2__Level__c = 0;
        standardCategoryHierarchy.Apttus_Config2__MaxOptions__c = 1.00000;
        standardCategoryHierarchy.Apttus_Config2__MinOptions__c = 1.00000;
        standardCategoryHierarchy.Apttus_Config2__Modifiable__c = true;
        standardCategoryHierarchy.Apttus_Config2__PrimordialId__c = null;
        standardCategoryHierarchy.Apttus_Config2__ProductAttributeGroupId__c = null;
        standardCategoryHierarchy.Apttus_Config2__Right__c = 20;
        insert standardCategoryHierarchy;

        Apttus_Config2__ClassificationHierarchy__c machineCategoryHierarchy = new Apttus_Config2__ClassificationHierarchy__c();
        machineCategoryHierarchy.Name = 'Machines';
        machineCategoryHierarchy.Apttus_Config2__HierarchyId__c = machinecategory.Id;
        machineCategoryHierarchy.Apttus_Config2__AncestorId__c = null;
        machineCategoryHierarchy.Apttus_Config2__DefaultSearchCategory__c = false;
        machineCategoryHierarchy.Apttus_Config2__ExpandedByDefault__c = false;
        machineCategoryHierarchy.Apttus_Config2__HideAllSearchFilters__c = false;
        machineCategoryHierarchy.Apttus_Config2__IncludeInTotalsView__c = true;
        machineCategoryHierarchy.Apttus_Config2__IsHidden__c = false;
        machineCategoryHierarchy.Apttus_Config2__IsPicklist__c = false;
        machineCategoryHierarchy.Apttus_Config2__Label__c = 'Machines';
        machineCategoryHierarchy.Apttus_Config2__LargeImageSize__c = '20x20';
        machineCategoryHierarchy.Apttus_Config2__Left__c = 1;
        machineCategoryHierarchy.Apttus_Config2__Level__c = 0;
        machineCategoryHierarchy.Apttus_Config2__MaxOptions__c = 1.00000;
        machineCategoryHierarchy.Apttus_Config2__MinOptions__c = 1.00000;
        machineCategoryHierarchy.Apttus_Config2__Modifiable__c = true;
        machineCategoryHierarchy.Apttus_Config2__PrimordialId__c = null;
        machineCategoryHierarchy.Apttus_Config2__ProductAttributeGroupId__c = null;
        machineCategoryHierarchy.Apttus_Config2__Right__c = 20;
        insert machineCategoryHierarchy;
        
        // Create subcategory
        Apttus_Config2__ClassificationHierarchy__c substandardCategoryHierarchy = new Apttus_Config2__ClassificationHierarchy__c();
        substandardCategoryHierarchy.Name = 'Cafitesse';
        substandardCategoryHierarchy.CurrencyIsoCode = 'EUR';
        substandardCategoryHierarchy.Apttus_Config2__HierarchyId__c = standardcategory.Id;
        substandardCategoryHierarchy.Apttus_Config2__AncestorId__c = standardCategoryHierarchy.Id;
        substandardCategoryHierarchy.Apttus_Config2__DefaultSearchCategory__c = false;
        substandardCategoryHierarchy.Apttus_Config2__ExpandedByDefault__c = false;
        substandardCategoryHierarchy.Apttus_Config2__HideAllSearchFilters__c = false;
        substandardCategoryHierarchy.Apttus_Config2__IncludeInTotalsView__c = true;
        substandardCategoryHierarchy.Apttus_Config2__IsHidden__c = false;
        substandardCategoryHierarchy.Apttus_Config2__IsPicklist__c = false;
        substandardCategoryHierarchy.Apttus_Config2__Label__c = 'Cafitesse';
        substandardCategoryHierarchy.Apttus_Config2__Left__c = 2;
        substandardCategoryHierarchy.Apttus_Config2__Level__c = 1;
        substandardCategoryHierarchy.Apttus_Config2__MaxOptions__c = 1.00000;
        substandardCategoryHierarchy.Apttus_Config2__MinOptions__c = 1.00000;
        substandardCategoryHierarchy.Apttus_Config2__Modifiable__c = true;
        substandardCategoryHierarchy.Apttus_Config2__PrimordialId__c = standardCategoryHierarchy.Id;
        substandardCategoryHierarchy.Apttus_Config2__ProductAttributeGroupId__c = null;
        substandardCategoryHierarchy.Apttus_Config2__Right__c = 3;
        insert substandardCategoryHierarchy;

        Apttus_Config2__ClassificationHierarchy__c subMachineCategoryHierarchy = new Apttus_Config2__ClassificationHierarchy__c();
        subMachineCategoryHierarchy.Name = 'Cafitesse';
        subMachineCategoryHierarchy.CurrencyIsoCode = 'EUR';
        subMachineCategoryHierarchy.Apttus_Config2__HierarchyId__c = machineCategory.Id;
        subMachineCategoryHierarchy.Apttus_Config2__AncestorId__c = machineCategoryHierarchy.Id;
        subMachineCategoryHierarchy.Apttus_Config2__DefaultSearchCategory__c = false;
        subMachineCategoryHierarchy.Apttus_Config2__ExpandedByDefault__c = false;
        subMachineCategoryHierarchy.Apttus_Config2__HideAllSearchFilters__c = false;
        subMachineCategoryHierarchy.Apttus_Config2__IncludeInTotalsView__c = true;
        subMachineCategoryHierarchy.Apttus_Config2__IsHidden__c = false;
        subMachineCategoryHierarchy.Apttus_Config2__IsPicklist__c = false;
        subMachineCategoryHierarchy.Apttus_Config2__Label__c = 'Cafitesse';
        subMachineCategoryHierarchy.Apttus_Config2__Left__c = 2;
        subMachineCategoryHierarchy.Apttus_Config2__Level__c = 1;
        subMachineCategoryHierarchy.Apttus_Config2__MaxOptions__c = 1.00000;
        subMachineCategoryHierarchy.Apttus_Config2__MinOptions__c = 1.00000;
        subMachineCategoryHierarchy.Apttus_Config2__Modifiable__c = true;
        subMachineCategoryHierarchy.Apttus_Config2__PrimordialId__c = machineCategoryHierarchy.Id;
        subMachineCategoryHierarchy.Apttus_Config2__ProductAttributeGroupId__c = null;
        subMachineCategoryHierarchy.Apttus_Config2__Right__c = 3;
        insert subMachineCategoryHierarchy;
        
        // Create subsubcategory
        Apttus_Config2__ClassificationHierarchy__c subSubstandardCategoryHierarchy = new Apttus_Config2__ClassificationHierarchy__c();
        subSubstandardCategoryHierarchy.Name = 'Sub Sub Category Beans';
        subSubstandardCategoryHierarchy.CurrencyIsoCode = 'EUR';
        subSubstandardCategoryHierarchy.Apttus_Config2__HierarchyId__c = standardcategory.Id;
        subSubstandardCategoryHierarchy.Apttus_Config2__AncestorId__c = substandardCategoryHierarchy.Id;
        subSubstandardCategoryHierarchy.Apttus_Config2__DefaultSearchCategory__c = false;
        subSubstandardCategoryHierarchy.Apttus_Config2__ExpandedByDefault__c = false;
        subSubstandardCategoryHierarchy.Apttus_Config2__HideAllSearchFilters__c = false;
        subSubstandardCategoryHierarchy.Apttus_Config2__IncludeInTotalsView__c = true;
        subSubstandardCategoryHierarchy.Apttus_Config2__IsHidden__c = false;
        subSubstandardCategoryHierarchy.Apttus_Config2__IsPicklist__c = false;
        subSubstandardCategoryHierarchy.Apttus_Config2__Label__c = 'Espresso Beans';
        subSubstandardCategoryHierarchy.Apttus_Config2__Left__c = 2;
        subSubstandardCategoryHierarchy.Apttus_Config2__Level__c = 1;
        subSubstandardCategoryHierarchy.Apttus_Config2__MaxOptions__c = 1.00000;
        subSubstandardCategoryHierarchy.Apttus_Config2__MinOptions__c = 1.00000;
        subSubstandardCategoryHierarchy.Apttus_Config2__Modifiable__c = true;
        subSubstandardCategoryHierarchy.Apttus_Config2__PrimordialId__c = standardCategoryHierarchy.Id;
        subSubstandardCategoryHierarchy.Apttus_Config2__ProductAttributeGroupId__c = null;
        subSubstandardCategoryHierarchy.Apttus_Config2__Right__c = 3;
        insert subSubstandardCategoryHierarchy;

        Apttus_Config2__ClassificationHierarchy__c subSubMachineCategoryHierarchy = new Apttus_Config2__ClassificationHierarchy__c();
        subSubMachineCategoryHierarchy.Name = 'Sub Sub Category Beans';
        subSubMachineCategoryHierarchy.CurrencyIsoCode = 'EUR';
        subSubMachineCategoryHierarchy.Apttus_Config2__HierarchyId__c = machineCategory.Id;
        subSubMachineCategoryHierarchy.Apttus_Config2__AncestorId__c = submachineCategoryHierarchy.Id;
        subSubMachineCategoryHierarchy.Apttus_Config2__DefaultSearchCategory__c = false;
        subSubMachineCategoryHierarchy.Apttus_Config2__ExpandedByDefault__c = false;
        subSubMachineCategoryHierarchy.Apttus_Config2__HideAllSearchFilters__c = false;
        subSubMachineCategoryHierarchy.Apttus_Config2__IncludeInTotalsView__c = true;
        subSubMachineCategoryHierarchy.Apttus_Config2__IsHidden__c = false;
        subSubMachineCategoryHierarchy.Apttus_Config2__IsPicklist__c = false;
        subSubMachineCategoryHierarchy.Apttus_Config2__Label__c = 'Espresso Beans';
        subSubMachineCategoryHierarchy.Apttus_Config2__Left__c = 2;
        subSubMachineCategoryHierarchy.Apttus_Config2__Level__c = 1;
        subSubMachineCategoryHierarchy.Apttus_Config2__MaxOptions__c = 1.00000;
        subSubMachineCategoryHierarchy.Apttus_Config2__MinOptions__c = 1.00000;
        subSubMachineCategoryHierarchy.Apttus_Config2__Modifiable__c = true;
        subSubMachineCategoryHierarchy.Apttus_Config2__PrimordialId__c = machineCategoryHierarchy.Id;
        subSubMachineCategoryHierarchy.Apttus_Config2__ProductAttributeGroupId__c = null;
        subSubMachineCategoryHierarchy.Apttus_Config2__Right__c = 3;
        insert subSubMachineCategoryHierarchy;
        
        
        Apttus_Config2__ProductClassification__c stdProductClassification = new Apttus_Config2__ProductClassification__c();
        stdProductClassification.Apttus_Config2__ClassificationId__c = standardCategoryHierarchy.Id;
        stdProductClassification.Apttus_Config2__DefaultQuantity__c = 1.00000;
        stdProductClassification.Apttus_Config2__MaxQuantity__c =  1.00000;
        stdProductClassification.Apttus_Config2__MinQuantity__c = 0.00000;
        stdProductClassification.Apttus_Config2__MinQuantity__c = 0.00000;
        stdProductClassification.Apttus_Config2__Modifiable__c = true;
        stdProductClassification.Apttus_Config2__ProductId__c = standardProduct.Id;
        insert stdProductClassification;
        
       
        
        Apttus_Config2__ProductClassification__c standardProductClassification = new Apttus_Config2__ProductClassification__c();
        standardProductClassification.Apttus_Config2__ClassificationId__c = substandardCategoryHierarchy.Id;
        standardProductClassification.Apttus_Config2__DefaultQuantity__c = 1.00000;
        standardProductClassification.Apttus_Config2__MaxQuantity__c =  1.00000;
        standardProductClassification.Apttus_Config2__MinQuantity__c = 0.00000;
        standardProductClassification.Apttus_Config2__MinQuantity__c = 0.00000;
        standardProductClassification.Apttus_Config2__Modifiable__c = true;
        standardProductClassification.Apttus_Config2__ProductId__c = standardProduct.Id;
        insert standardProductClassification;

        Apttus_Config2__ProductClassification__c machineProductClassification = new Apttus_Config2__ProductClassification__c();
        machineProductClassification.Apttus_Config2__ClassificationId__c = subMachineCategoryHierarchy.Id;
        machineProductClassification.Apttus_Config2__DefaultQuantity__c = 1.00000;
        machineProductClassification.Apttus_Config2__MaxQuantity__c =  1.00000;
        machineProductClassification.Apttus_Config2__MinQuantity__c = 0.00000;
        machineProductClassification.Apttus_Config2__MinQuantity__c = 0.00000;
        machineProductClassification.Apttus_Config2__Modifiable__c = true;
        machineProductClassification.Apttus_Config2__ProductId__c = machineProduct.Id;
        insert machineProductClassification;
                    
        Apttus_Config2__PriceList__c priceList = APTS_TestUtils.createPriceList();
        insert priceList;    

        Apttus_Config2__PriceListItem__c standardPriceListItem = APTS_TestUtils.createPriceListItem(priceList.id,standardProduct.id);
        insert standardPriceListItem;
        Apttus_Config2__PriceListItem__c machinePriceListItem = APTS_TestUtils.createPriceListItem(priceList.id,machineProduct.id);
        insert machinePriceListItem;

        APTS_Sales_Org_Data__c standardSod =new APTS_Sales_Org_Data__c (
                APTS_Product__c =standardProduct.id,
                APTS_Price_List__c=priceList.id,
                APTS_Product_web_enabled__c = true);
        insert standardSod;
        APTS_Sales_Org_Data__c machineSod =new APTS_Sales_Org_Data__c (
                APTS_Product__c =machineProduct.id,
                APTS_Price_List__c=priceList.id,
                APTS_Product_web_enabled__c = true);
        insert machineSod;
                
       
        Apttus__APTS_Agreement__c standardAgreement = new Apttus__APTS_Agreement__c(
                    Apttus__Account__c = standardAccount.Id,
                    APTS_Sold_To__c = standardAccount.Id, 
                    Name = 'Test Agreement',
                    RecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId(),
                    Apttus__Contract_Start_Date__c = Date.today(), 
                    Apttus__Contract_End_Date__c = Date.today()+100);
        insert standardAgreement;

        Apttus__APTS_Agreement__c machineAgreement = new Apttus__APTS_Agreement__c(
                    Apttus__Account__c = machineAccount.Id,
                    APTS_Sold_To__c = machineAccount.Id, 
                    Name = 'Test Agreement',
                    RecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId(),
                    Apttus__Contract_Start_Date__c = Date.today(), 
                    Apttus__Contract_End_Date__c = Date.today()+100);
        insert machineAgreement;
            
        Apttus_Config2__BillingPreference__c billpref = APTS_TestUtils.createBillingPrefrence('January');
        insert billpref;
        
        ncOrder = APTS_TestUtils.createOrder('New',priceList.id,ncAccount.Id,billpref.id);
        ncOrder.Apttus_CMConfig__AgreementId__c = standardAgreement.id;
        ncOrder.RecordTypeId = Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByName().get(System.Label.APTS_Standard_Order).getRecordTypeId();    
        insert ncOrder;

        standardOrder = APTS_TestUtils.createOrder('New',priceList.id,standardAccount.Id,billpref.id);
        standardOrder.Apttus_CMConfig__AgreementId__c = standardAgreement.id;
        standardOrder.RecordTypeId = Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByName().get(System.Label.APTS_Standard_Order).getRecordTypeId();    
        standardOrder.Apttus_Config2__SoldToAccountId__c = standardAccount.id;
        insert standardOrder;

        system.assertNotEquals(standardOrder,null);

        machineOrder = APTS_TestUtils.createOrder('New',priceList.id,machineAccount.Id,billpref.id);
        machineOrder.Apttus_CMConfig__AgreementId__c = machineAgreement.id;
        machineOrder.RecordTypeId = Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByName().get(System.Label.APTS_Machine_Order).getRecordTypeId();    
        machineOrder.Apttus_Config2__SoldToAccountId__c = machineAccount.id;
        machineOrder.APTS_Requested_Installation_Date__c =Date.newInstance(2018, 10, 22);
        machineOrder.APTS_SAP_OrderType__c ='XA23';
        insert machineOrder;
        
            
        ncProdConfig = new Apttus_Config2__ProductConfiguration__c(
            Apttus_Config2__AccountId__c=ncAccount.id, 
            Name = 'Sample', 
            Apttus_Config2__OrderId__c = ncOrder.id, 
            Apttus_Config2__PriceListId__c = priceList.id);
        insert ncProdConfig;

        standardProdConfig = new Apttus_Config2__ProductConfiguration__c(
            Apttus_Config2__AccountId__c=standardAccount.id, 
            Name = 'Sample', 
            Apttus_Config2__OrderId__c = standardOrder.id, 
            Apttus_Config2__PriceListId__c = priceList.id);
        insert standardProdConfig;

        machineProdConfig = new Apttus_Config2__ProductConfiguration__c(
            Apttus_Config2__AccountId__c=machineAccount.id, 
            Name = 'Sample', 
            Apttus_Config2__OrderId__c = machineOrder.id, 
            Apttus_Config2__PriceListId__c = priceList.id);
        insert machineProdConfig;
            
        Apttus_Config2__LineItem__c standardlineitem = new Apttus_Config2__LineItem__c(
            Apttus_Config2__ConfigurationId__c=standardProdConfig.id, 
            Apttus_Config2__ProductId__c=standardProduct.id,
            Apttus_Config2__OptionId__c=standardProduct.id,
            Apttus_Config2__ItemSequence__c=1, Apttus_Config2__LineNumber__c=1,
            APTS_Category_Level__c = 'Category');
        insert standardlineitem;
            
        standardAgreementLineItem = new Apttus__AgreementLineItem__c();
        standardAgreementLineItem.Apttus_CMConfig__DerivedFromId__c = standardlineitem.id;
        standardAgreementLineItem.Apttus__ProductId__c = standardProduct.Id;
        standardAgreementLineItem.Apttus__AgreementId__c = standardAgreement.Id;
        standardAgreementLineItem.Apttus__Quantity__c = 1;
        standardAgreementLineItem.Apttus_CMConfig__HasOptions__c = false;
        standardAgreementLineItem.Apttus_CMConfig__LineType__c = 'Product/service';
        standardAgreementLineItem.APTS_Option_Group_Text__c = '';
        standardAgreementLineItem.APTS_Category_Level__c = 'Category';
        standardAgreementLineItem.Apttus_CMConfig__ClassificationId__c = standardCategoryHierarchy.Id;
        standardAgreementLineItem.Apttus_CMConfig__ClassificationHierarchy__c = 'Coffee | Beans | Douwe Egberts';
        standardAgreementLineItem.APTS_Sold_to_Party__c = standardAccount.Id;
        standardAgreementLineItem.Apttus_CMConfig__PriceListItemId__c = standardPriceListItem.Id;
        standardAgreementLineItem.APTS_Type_of_Contract__c = 'Trial';
        standardAgreementLineItem.Apttus_CMConfig__BasePriceOverride__c = 2;
        insert standardAgreementLineItem;

        standardAgreement.Apttus__Status_Category__c = 'In Effect';
        standardAgreement.Apttus__Status__c = 'Activated';
        standardAgreement.Apttus__Subtype__c = 'Fixed End date';
        update standardAgreement;

                Apttus_Config2__LineItem__c machineLineItem = new Apttus_Config2__LineItem__c(
                Apttus_Config2__ConfigurationId__c = machineProdConfig.id, 
                Apttus_Config2__ProductId__c=machineProduct.id,
                Apttus_Config2__LineNumber__c=1,
                Apttus_Config2__PricingStatus__c='Pending',
                Apttus_Config2__OptionId__c=machineProduct.id,
                Apttus_Config2__ItemSequence__c=1, 
                APTS_Category_Level__c = 'Category');
                insert machineLineItem;
            
        machineAgreementLineItem = new Apttus__AgreementLineItem__c();
        machineAgreementLineItem.Apttus_CMConfig__DerivedFromId__c = machinelineitem.id;
        machineAgreementLineItem.Apttus__ProductId__c = machineProduct.Id;
        machineAgreementLineItem.Apttus__AgreementId__c = machineAgreement.Id;
        machineAgreementLineItem.Apttus__Quantity__c = 1;
        machineAgreementLineItem.Apttus_CMConfig__HasOptions__c = true;
        machineAgreementLineItem.Apttus_CMConfig__LineType__c = 'Product/Service';
        machineAgreementLineItem.APTS_Category_Level__c = 'Category';
        machineAgreementLineItem.Apttus_CMConfig__ClassificationId__c = machineCategoryHierarchy.Id;
        machineAgreementLineItem.Apttus_CMConfig__ClassificationHierarchy__c = 'Machines';
        machineAgreementLineItem.APTS_Sold_to_Party__c = machineAccount.Id;
        machineAgreementLineItem.APTS_Type_of_Contract__c = 'Trial';
        machineAgreementLineItem.Apttus_CMConfig__BasePriceOverride__c = 2;
            machineAgreementLineItem.Apttus_CMConfig__HasOptions__c = true;
        insert machineAgreementLineItem;
        machineAgreement.Apttus__Status_Category__c = 'In Effect';
        machineAgreement.Apttus__Status__c = 'Activated';
        update machineAgreement;

        List <Apttus__APTS_Agreement__c> agreementsToUpdate = new List <Apttus__APTS_Agreement__c> ();   

        agreementsToUpdate.clear();           
        agreementsToUpdate.add(standardAgreement);            
        APTS_ManageCER.manageCERRecords(agreementsToUpdate,'Agreement','Update');
        
        agreementsToUpdate.clear();
        agreementsToUpdate.add(machineAgreement);
        APTS_ManageCER.manageCERRecords(agreementsToUpdate,'Agreement','Update');
        
        ncProdOrderConfig = new Apttus_Config2__ProductConfiguration__c(
            Apttus_Config2__AccountId__c= ncAccount.id, 
            Name = 'Sample', 
            Apttus_Config2__OrderId__c = ncOrder.id, 
            Apttus_Config2__PriceListId__c = priceList.id);
        insert ncProdOrderConfig;

        Apttus_Config2__LineItem__c currentCartnclineitem = new Apttus_Config2__LineItem__c(
            Apttus_Config2__ConfigurationId__c=ncProdConfig.id, 
            Apttus_Config2__SellingUom__c='SAP_PCE',
            Apttus_Config2__Quantity__c=1, 
            Apttus_Config2__ProductId__c=standardProduct.id,
            Apttus_Config2__OptionId__c=standardProduct.id,
            Apttus_Config2__ItemSequence__c=1, Apttus_Config2__LineNumber__c=1,
            APTS_Category_Level__c = 'Category');
        insert currentCartnclineitem;


        standardOrderProdConfig = new Apttus_Config2__ProductConfiguration__c(
            Apttus_Config2__AccountId__c=standardAccount.id, 
            Name = 'Sample', 
            Apttus_Config2__OrderId__c = standardOrder.id, 
            Apttus_Config2__PriceListId__c = priceList.id);
        insert standardOrderProdConfig;

        
        Apttus_Config2__LineItem__c currentCartstandardlineitem = new Apttus_Config2__LineItem__c(
            Apttus_Config2__ConfigurationId__c=standardOrderProdConfig.id, 
            Apttus_Config2__SellingUom__c='SAP_PCE',
            Apttus_Config2__Quantity__c=1, 
            Apttus_Config2__ProductId__c=standardProduct.id,
            Apttus_Config2__OptionId__c=standardProduct.id,
            Apttus_Config2__ItemSequence__c=1, Apttus_Config2__LineNumber__c=1,
            APTS_Category_Level__c = 'Category');
        insert currentCartstandardlineitem;

        machineOrderProdConfig = new Apttus_Config2__ProductConfiguration__c(
            Apttus_Config2__AccountId__c=machineAccount.id, 
            Name = 'Sample', 
            Apttus_Config2__OrderId__c = machineOrder.id, 
            Apttus_Config2__PriceListId__c = priceList.id);
        insert machineOrderProdConfig;  
        } 

System.debug('testclass ncProdConfig'+ncProdConfig);
    System.debug('testclass standardProdConfig'+standardProdConfig);
    System.debug('testclass machineProdConfig'+machineProdConfig);
    System.debug('testclass ncProdOrderConfig'+ncProdOrderConfig);
    System.debug('testclass standardOrderProdConfig'+standardOrderProdConfig);
    System.debug('testclass machineOrderProdConfig'+machineOrderProdConfig);		
	
    }  

    static testMethod void testPageWithNoContractedProducts() 
    {
        filldata();
        Test.startTest();
        PageReference page = Page.APTS_ContractedProducts;
        Test.setCurrentPage(page);
        ApexPages.currentPage().getParameters().put('id', ncProdOrderConfig.Id);
        ApexPages.currentPage().getParameters().put('businessObjectId', ncOrder.id);
        ApexPages.currentPage().getParameters().put('selectedProductId', standardProduct.id);
        APTS_ContractedProductsCtrl controller = new APTS_ContractedProductsCtrl();
        controller.displaySelectedProduct();
        Test.stopTest();
    }

    static testMethod void testPageWithStandardOrder() 
    {
        filldata();
        Test.startTest();
        PageReference page = Page.APTS_ContractedProducts;
        Test.setCurrentPage(page);
        ApexPages.currentPage().getParameters().put('id', standardOrderProdConfig.Id);
        ApexPages.currentPage().getParameters().put('businessObjectId', standardOrder.id);
        ApexPages.currentPage().getParameters().put('selectedProductId', standardProduct.id);
        
        APTS_ContractedProductsCtrl controller = new APTS_ContractedProductsCtrl();
        System.debug(logginglevel.error, 'CX_Message: List of Contracted Products: ' + controller.lstContractedProducts);
        System.assert(controller.lstContractedProducts.ingredientsList.Size() > 0);
        controller.productId = standardProduct.Id;
        controller.agreementLineItemId = standardAgreementLineItem.Id;
        controller.addProducttoCart();
        controller.gotoCatalog();
        controller.displaySelectedProduct();
        Test.stopTest();
    }
 

        static testMethod void testPageWithStandardOrderForMultipleProducts() 
    {
        filldata();
        Test.startTest();
        PageReference page = Page.APTS_ContractedProducts;
        Test.setCurrentPage(page);
        ApexPages.currentPage().getParameters().put('id', standardOrderProdConfig.Id);
        ApexPages.currentPage().getParameters().put('businessObjectId', standardOrder.id);
        ApexPages.currentPage().getParameters().put('selectedProductId', standardProduct.id);
        APTS_ContractedProductsCtrl controller = new APTS_ContractedProductsCtrl();
        System.debug(logginglevel.error, 'CX_Message: List of Contracted Products: ' + controller.lstContractedProducts);
        System.assert(controller.lstContractedProducts.ingredientsList.Size() > 0);
        controller.productId = standardProduct.Id;
        controller.agreementLineItemId = standardAgreementLineItem.Id;
        controller.lstContractedProducts.ingredientsList.get(0).subcategories.get(0).products.get(0).selected = true;
        controller.addMultipleProductsToCart();
        controller.gotoCatalog();
        controller.displaySelectedProduct();
        List<SelectOption> options = controller.getUomTypes();
        Test.stopTest();
    }

    static testMethod void testPageWithMachineOrder() 
    {
        filldata();
        Test.startTest();
        PageReference page = Page.APTS_ContractedProducts;
        Test.setCurrentPage(page);
        ApexPages.currentPage().getParameters().put('id', machineOrderProdConfig.Id);
        ApexPages.currentPage().getParameters().put('businessObjectId', machineOrder.id);
        ApexPages.currentPage().getParameters().put('selectedProductId', standardProduct.id);
        ApexPages.currentPage().getParameters().put('productAdded', 'true');
        APTS_ContractedProductsCtrl controller = new APTS_ContractedProductsCtrl();
        System.assert(controller.lstContractedProducts.machineslist.Size() > 0);
        controller.productId = machineProduct.Id;
        controller.agreementLineItemId = machineAgreementLineItem.Id;
        controller.addBundleProductToCart();
        controller.gotoCatalog();
        controller.displaySelectedProduct();
        Test.stopTest();
    }
     /*static testMethod void test_addBundleProductToCart() {
        filldata();
        Test.startTest();
        APTS_ContractedProductsCtrl aPTS_ContractedProductsCtrl = new APTS_ContractedProductsCtrl();
        aPTS_ContractedProductsCtrl.addBundleProductToCart();
        Test.stopTest();
    }*/

    static testMethod void testPageWithMachineOrderForMultipleProducts() 
    {
        filldata();
        Test.startTest();   
        PageReference page = Page.APTS_ContractedProducts;
        Test.setCurrentPage(page);
        ApexPages.currentPage().getParameters().put('id', machineOrderProdConfig.Id);
        ApexPages.currentPage().getParameters().put('businessObjectId', machineOrder.id);
        ApexPages.currentPage().getParameters().put('selectedProductId', standardProduct.id);
        APTS_ContractedProductsCtrl controller = new APTS_ContractedProductsCtrl();
        System.assert(controller.lstContractedProducts.machineslist.Size() > 0);
        controller.productId = machineProduct.Id;
        controller.agreementLineItemId = machineAgreementLineItem.Id;
        controller.addMultipleProductsToCart();
        controller.gotoCart();
      controller.displaySelectedProduct();
        Test.stopTest();
    }
    
    static testMethod void testPageWithMachineOrderForMultipleProducts1() 
    {       
          filldata();
        Apttus__AgreementLineItem__c machineAgreementLineItem1 = new Apttus__AgreementLineItem__c(); 
        
       machineAgreementLineItem1 =[select id,Apttus_CMConfig__DerivedFromId__c,Apttus__ProductId__c,Apttus__AgreementId__c,Apttus__Quantity__c,Apttus_CMConfig__HasOptions__c,Apttus_CMConfig__LineType__c,APTS_Category_Level__c,Apttus_CMConfig__ClassificationId__c,Apttus_CMConfig__ClassificationHierarchy__c,APTS_Sold_to_Party__c from Apttus__AgreementLineItem__c  where id =:machineAgreementLineItem.id];
        machineAgreementLineItem1.Apttus_CMConfig__LineType__c = 'Option';
        update machineAgreementLineItem1;
        //filldata();
        Test.startTest();   
        PageReference page = Page.APTS_ContractedProducts;
        Test.setCurrentPage(page);
        ApexPages.currentPage().getParameters().put('id', machineOrderProdConfig.Id);
        ApexPages.currentPage().getParameters().put('businessObjectId', machineOrder.id);
        ApexPages.currentPage().getParameters().put('selectedProductId', standardProduct.id);
        ApexPages.currentPage().getParameters().put('machineAdded', 'true');
      //  ApexPages.currentPage().getParameters().put('productAdded', 'true');
        ApexPages.currentPage().getParameters().put('machineQty', '1');
      APTS_ContractedProductsCtrl controller = new APTS_ContractedProductsCtrl();
        controller.StartDate = system.today();
        controller.createCERAmendment();
        System.assert(controller.lstContractedProducts.machineslist.Size() > 0);
        controller.productId = machineProduct.Id;
        controller.agreementLineItemId = machineAgreementLineItem1.Id;
        controller.addMultipleProductsToCart();
        controller.gotoCatalog();
        controller.gotoCart();
        controller.displaySelectedProduct();
        controller.selectedProductId = '5567899';
        controller.PdctId = '5567899';
        controller.SearchText = 'TestSearch';        
        
        //controller.tempMachineWrapper tempWrapper = new controller.tempMachineWrapper();
        //tempWrapper.qty = 0;
        //tempWrapper.selected = true;
        Test.stopTest();
    }
    
    static testMethod void testPageWithRouteSalesOrder() 
    {
        filldata();
        Test.startTest();
        PageReference page = Page.APTS_ContractedProducts;
        Apttus_Config2__Order__c oStandardOrder = new Apttus_Config2__Order__c();
        oStandardOrder.Id = standardOrder.id;        
        oStandardOrder.RecordTypeId = Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByName().get(APTS_CERUtility.ROUTE_SALES_ORDER).getRecordTypeId();    
        upsert oStandardOrder;
        
        Test.setCurrentPage(page);
        ApexPages.currentPage().getParameters().put('id', standardOrderProdConfig.Id);
        ApexPages.currentPage().getParameters().put('businessObjectId', standardOrder.id);
        ApexPages.currentPage().getParameters().put('selectedProductId', standardProduct.id);
        
        
        APTS_ContractedProductsCtrl controller = new APTS_ContractedProductsCtrl();
        //System.debug(logginglevel.error, 'CX_Message: List of Contracted Products: ' + controller.lstContractedProducts);
       // System.assert(controller.lstContractedProducts.ingredientsList.Size() > 0);
        controller.productId = standardProduct.Id;
        controller.agreementLineItemId = standardAgreementLineItem.Id;
        controller.addProducttoCart();
        controller.gotoCatalog();
        controller.displaySelectedProduct();
        Test.stopTest();
    }
     static testMethod void testPageWithOperatingOrder() 
    {
        filldata();
        Test.startTest();
        PageReference page = Page.APTS_ContractedProducts;
        Apttus_Config2__Order__c oStandardOrder = new Apttus_Config2__Order__c();
        oStandardOrder.Id = standardOrder.id;        
        oStandardOrder.RecordTypeId = Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByName().get(APTS_CERUtility.OPERATING_ORDER).getRecordTypeId();    
        upsert oStandardOrder;
        
        Test.setCurrentPage(page);
        ApexPages.currentPage().getParameters().put('id', standardOrderProdConfig.Id);
        ApexPages.currentPage().getParameters().put('businessObjectId', standardOrder.id);
        ApexPages.currentPage().getParameters().put('selectedProductId', standardProduct.id);
        
        
        APTS_ContractedProductsCtrl controller = new APTS_ContractedProductsCtrl();
        //System.debug(logginglevel.error, 'CX_Message: List of Contracted Products: ' + controller.lstContractedProducts);
       // System.assert(controller.lstContractedProducts.ingredientsList.Size() > 0);
        controller.productId = standardProduct.Id;
        controller.agreementLineItemId = standardAgreementLineItem.Id;
        controller.addProducttoCart();
        controller.gotoCatalog();
        controller.displaySelectedProduct();
        Test.stopTest();
    }
}