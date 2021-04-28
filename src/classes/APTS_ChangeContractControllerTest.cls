/**********************************************************************************
* @Author: Lavanya Ravindran
* @Company: Accenture
* @Description: Test class for APTS_ChangeContractController
* @Created Date: Jan-9-2020
* @History:
*      <Name>              <Date>          <Description>
*      Lavanya              09.01.2020       Created
**********************************************************************************/
@isTest
public class APTS_ChangeContractControllerTest {
    
    
    public static Apttus_Config2__ProductConfiguration__c machineProdConfig;    
    public static Apttus_Config2__LineItem__c machineLineItem;
    public static Apttus_Config2__LineItem__c optionLineItem;
    public static Apttus_Config2__LineItem__c machineLineItem1;
    public static Apttus_Config2__LineItem__c optionLineItem1;
    public static Product2 machineProduct;   
    public static Apttus_Config2__TempObject__c oTempObject ;
    public static Apttus_Config2__Order__c machineOrder;
    public static Apttus__AgreementLineItem__c standardAgreementLineItem;
    public static Apttus__AgreementLineItem__c machineAgreementLineItem;
    
    
    
    public static void filldata()
    {
        Apttus_Config2__ConfigLineItemCustomFields__c instCustSetting = new Apttus_Config2__ConfigLineItemCustomFields__c();
        instCustSetting.Name = 'AssetContractChange';
        instCustSetting.Apttus_Config2__CustomFieldNames__c = 'Apttus_Config2__HasIncentives__c';       
        insert instCustSetting;
        
        // Creation of test accounts
        User testUser = APTS_TestUtils.createUser();
        testUser.LocaleSidKey = 'nl_NL';
        
        System.runAs(testUser) {
            
            Account machineAccount = new Account(Name = 'Machine Account', Phone = '+3209999999');
            insert machineAccount;
            
            
            machineProduct = APTS_TestUtils.createProduct('Machine Product', '26940992', 'Machines');       
            machineProduct.Apttus_Config2__ConfigurationType__c = 'Bundle';
            insert machineProduct;
            
            
            
            Apttus_Config2__ClassificationName__c machinecategory = new Apttus_Config2__ClassificationName__c();
            machinecategory.Name = 'Machines';
            machinecategory.Apttus_Config2__Active__c = true;
            machinecategory.Apttus_Config2__HierarchyLabel__c = 'Machines';
            machinecategory.Apttus_Config2__Type__c = 'Offering';
            machinecategory.APTS_Allow_Adjustments__c = true;
            insert machinecategory;
            
            
            
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
            
            
            Apttus_Config2__PriceListItem__c machinePriceListItem = APTS_TestUtils.createPriceListItem(priceList.id,machineProduct.id);
            insert machinePriceListItem;
            
            
            APTS_Sales_Org_Data__c machineSod =new APTS_Sales_Org_Data__c (
                APTS_Product__c =machineProduct.id,
                APTS_Price_List__c=priceList.id,
                APTS_Product_web_enabled__c = true);
            insert machineSod;
            
            
            
            
            Apttus_Config2__BillingPreference__c billpref = APTS_TestUtils.createBillingPrefrence('January');
            insert billpref;
            
            
            
            machineOrder = APTS_TestUtils.createOrder('New',priceList.id,machineAccount.Id,billpref.id);        
            machineOrder.RecordTypeId = Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByName().get(System.Label.APTS_Machine_Order).getRecordTypeId();    
            machineOrder.Apttus_Config2__SoldToAccountId__c = machineAccount.id;
            machineOrder.APTS_Requested_Installation_Date__c =Date.newInstance(2018, 10, 22);
            insert machineOrder;
            
            
            
            machineProdConfig = new Apttus_Config2__ProductConfiguration__c(
                Apttus_Config2__AccountId__c=machineAccount.id, 
                Name = 'Sample', 
                Apttus_Config2__OrderId__c = machineOrder.id, 
                Apttus_Config2__PriceListId__c = priceList.id);
            insert machineProdConfig;
            
            
            
            machineLineItem = new Apttus_Config2__LineItem__c(
                Apttus_Config2__ConfigurationId__c = machineProdConfig.id, 
                Apttus_Config2__ProductId__c=machineProduct.id,currencyISOCode='EUR',
                Apttus_Config2__OptionId__c=machineProduct.id,
                Apttus_Config2__HasIncentives__c=false,Apttus_Config2__LineStatus__c='Upgraded',Apttus_Config2__PrimaryLineNumber__c=1,
                Apttus_Config2__ItemSequence__c=1, Apttus_Config2__LineNumber__c=1,
                APTS_Category_Level__c = 'Category');
            insert machineLineItem;
            
            optionLineItem = new Apttus_Config2__LineItem__c(
                Apttus_Config2__ConfigurationId__c = machineProdConfig.id, 
                Apttus_Config2__ProductId__c=machineProduct.id,
                Apttus_Config2__OptionId__c=machineProduct.id,
                Apttus_Config2__HasIncentives__c=false,Apttus_Config2__LineStatus__c='Upgraded',currencyISOCode='EUR',
                Apttus_Config2__ItemSequence__c=1,Apttus_Config2__LineNumber__c=1,Apttus_Config2__ParentBundleNumber__c=1,Apttus_Config2__LineType__c = 'Option');
            insert optionLineItem;
            
            
            machineLineItem1 = new Apttus_Config2__LineItem__c(
                Apttus_Config2__ConfigurationId__c = machineProdConfig.id, 
                Apttus_Config2__ProductId__c=machineProduct.id,currencyISOCode='EUR',
                Apttus_Config2__OptionId__c=machineProduct.id,
                Apttus_Config2__HasIncentives__c=false,Apttus_Config2__LineStatus__c='New',Apttus_Config2__PrimaryLineNumber__c=1,
                Apttus_Config2__ItemSequence__c=1, Apttus_Config2__LineNumber__c=1,
                APTS_Category_Level__c = 'Category');
            insert machineLineItem1;
            
            optionLineItem1 = new Apttus_Config2__LineItem__c(
                Apttus_Config2__ConfigurationId__c = machineProdConfig.id, 
                Apttus_Config2__ProductId__c=machineProduct.id,
                Apttus_Config2__OptionId__c=machineProduct.id,
                Apttus_Config2__HasIncentives__c=false,Apttus_Config2__LineStatus__c='New',currencyISOCode='EUR',
                Apttus_Config2__ItemSequence__c=1,Apttus_Config2__LineNumber__c=1,Apttus_Config2__ParentBundleNumber__c=1,Apttus_Config2__LineType__c = 'Option');
            insert optionLineItem1;
            
            
            
            Apttus_Config2__ProductAttributeValue__c machinePav = new Apttus_Config2__ProductAttributeValue__c();
            machinePav.Apttus_Config2__LineItemId__c = machineLineItem.id;
            Database.insert(machinePav);
            
            
            Apttus_Config2__ProductAttributeValue__c optionPav = new Apttus_Config2__ProductAttributeValue__c();
            optionPav.Apttus_Config2__LineItemId__c = optionLineItem.id;
            optionPav.CurrencyIsoCode='EUR';
            Database.insert(optionPav);
            
            Apttus_Config2__ProductAttributeValue__c machinePav1 = new Apttus_Config2__ProductAttributeValue__c();
            machinePav1.Apttus_Config2__LineItemId__c = machineLineItem1.id;
            Database.insert(machinePav1);
            
            
            Apttus_Config2__ProductAttributeValue__c optionPav1 = new Apttus_Config2__ProductAttributeValue__c();
            optionPav1.Apttus_Config2__LineItemId__c = optionLineItem1.id;
            optionPav1.CurrencyIsoCode='EUR';
            Database.insert(optionPav1);
            
            oTempObject = new Apttus_Config2__TempObject__c();
            oTempObject.Apttus_Config2__Data__c = '<?xml version="1.0" encoding="UTF-8"?> <ConfigRequest> <Params> <Param> <Name>flow</Name> <Value>' + 'NGChangeContract' + '</Value> </Param> </Params> </ConfigRequest>';
            oTempObject.Apttus_Config2__ConfigurationId__c = machineProdConfig.Id;
            insert oTempObject;
            
            
        } 
    }
    public static testMethod void testPageWithMachineOrder() 
    {
        filldata();
        Test.startTest();
        ApexPages.currentPage().getParameters().put('LineItemId',machineLineItem.id);
        ApexPages.currentPage().getParameters().put('Id',machineProdConfig.Id);
        ApexPages.currentPage().getParameters().put('configRequestId',oTempObject.id);
        ApexPages.currentPage().getParameters().put('flow','NGChangeContract');
        ApexPages.currentPage().getParameters().put('primaryLineNumber','1');
        
        APTS_CloneBundle controller = new APTS_CloneBundle();
        PageReference resultChangeContract = controller.Goback();
        
        APTS_CloneBundle2 clonecontroller = new APTS_CloneBundle2();
        PageReference resultChangeContract2 = clonecontroller.APTS_CloneBundle2();
        
        Test.stopTest();
    }
}