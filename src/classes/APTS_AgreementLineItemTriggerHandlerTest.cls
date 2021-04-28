/**************************************************************
 * @Author: jason.e.mactal
 * @Company: Accenture
 * @Description: Test class for APTS_AgreementLineItemTriggerHandler
 * @Created Date: May 3, 2018
 * @Revisions:
 *      <Name>              <Date>          <Description>
 *      jason.e.mactal      May 4, 2018     Initial Version
 * 
 *************************************************************/
@isTest
public class APTS_AgreementLineItemTriggerHandlerTest {
    @testSetup
    static void testSetup() {
        
        User testUser = APTS_TestDataFactory.createUser();
        
        
        insert new TriggerSettings__c(APTS_AgreementLineItemTrigger__c = true);
        
        List<Product2> productList = new List<Product2>();
        Product2 oBundleProd = APTS_TestDataFactory.createProduct('Cafitesse Excellence', '8100021', null, 'Bundle', TRUE, TRUE);
        productList.add(oBundleProd);
        
        Product2 oOptionProd1 = APTS_TestDataFactory.createProduct('All-in Coverage', 'TEST1', null, 'Option', FALSE, FALSE);
        productList.add(oOptionProd1);
        
        Product2 oOptionProd2 = APTS_TestDataFactory.createProduct('Basic Coverage', 'TEST2', null, 'Option', FALSE, FALSE);
        productList.add(oOptionProd2);
        
        Product2 oOptionProd3 = APTS_TestDataFactory.createProduct('Full Co Operating Low', 'TEST3', null, 'Option', FALSE, FALSE);
        productList.add(oOptionProd3);
        
        Product2 oOptionProd4 = APTS_TestDataFactory.createProduct('Full Operating Low', 'TEST4', null, 'Option', FALSE, FALSE);
        productList.add(oOptionProd4);
        insert productList;
        
        Apttus_Config2__ClassificationName__c serviceOG = APTS_TestDataFactory.createCategory();
        serviceOG.Apttus_Config2__HierarchyLabel__c = 'Service';
        serviceOG.Apttus_Config2__Type__c = 'Option Group';        
        insert serviceOG;
        
        Apttus_Config2__ClassificationHierarchy__c serviceCH = APTS_TestDataFactory.createCategoryHierarchy(serviceOG.Id, 'Service');
        insert serviceCH;
        
        Apttus_Config2__ClassificationHierarchy__c machinecareCH = APTS_TestDataFactory.createSubCategory(serviceOG.Id,serviceCH.id);
        machinecareCH.Name = 'Machine Care';
        machinecareCH.Apttus_Config2__Label__c = 'Machine Care';
        insert machinecareCH;
        
        Apttus_Config2__ProductOptionGroup__c optionGroup = APTS_TestDataFactory.createProductOptionGroup(serviceCH.id, machinecareCH.id);
        insert optionGroup;
        
        List<Apttus_Config2__ProductOptionComponent__c> optionComponentList = new List<Apttus_Config2__ProductOptionComponent__c>();
        Apttus_Config2__ProductOptionComponent__c oOptComponent1 = APTS_TestDataFactory.createProductOptionComponent(optionGroup.id);
        oOptComponent1.Apttus_Config2__ParentProductId__c = oBundleProd.id;
        oOptComponent1.Apttus_Config2__ComponentProductId__c = oOptionProd1.id;
        oOptComponent1.Apttus_Config2__ProductOptionGroupId__c = optionGroup.id;
        optionComponentList.add(oOptComponent1);
        
        Apttus_Config2__ProductOptionComponent__c oOptComponent2 = APTS_TestDataFactory.createProductOptionComponent(optionGroup.id);
        oOptComponent2.Apttus_Config2__ParentProductId__c = oBundleProd.id;
        oOptComponent2.Apttus_Config2__ComponentProductId__c = oOptionProd2.id;
        oOptComponent2.Apttus_Config2__ProductOptionGroupId__c = optionGroup.id;
        optionComponentList.add(oOptComponent2);
        
        Apttus_Config2__ProductOptionComponent__c oOptComponent3 = APTS_TestDataFactory.createProductOptionComponent(optionGroup.id);
        oOptComponent3.Apttus_Config2__ParentProductId__c = oBundleProd.id;
        oOptComponent3.Apttus_Config2__ComponentProductId__c = oOptionProd3.id;
        oOptComponent3.Apttus_Config2__ProductOptionGroupId__c = optionGroup.id;
        optionComponentList.add(oOptComponent3);
        
        Apttus_Config2__ProductOptionComponent__c oOptComponent4 = APTS_TestDataFactory.createProductOptionComponent(optionGroup.id);
        oOptComponent4.Apttus_Config2__ParentProductId__c = oBundleProd.id;
        oOptComponent4.Apttus_Config2__ComponentProductId__c = oOptionProd4.id;
        oOptComponent4.Apttus_Config2__ProductOptionGroupId__c = optionGroup.id;
        optionComponentList.add(oOptComponent4);
        insert optionComponentList;
        
        Account oAcc = APTS_TestDataFactory.createAccount('Test Account');
        insert oAcc;
        
        Apttus_Config2__PriceList__c oPriceList = APTS_TestDataFactory.createPriceList('Test');
        oPriceList.APTS_Region__c = 'SAP_0111';
        insert oPriceList;
        
        Apttus__APTS_Agreement__c oAgg = APTS_TestDataFactory.createAgreement(null, null, oAcc.id, 'Standard Deal');
        oAgg.APTS_PricingDate__c = date.today().addDays(1);
        insert oAgg;
        
        Apttus__AgreementLineItem__c oALI = APTS_TestDataFactory.createAgreementLineItem(null, oAgg.id, oAcc.id, null);
        oALI.Apttus__ProductId__c = oBundleProd.id;
        oALI.Apttus_CMConfig__LineType__c = 'Option';
        oALI.Apttus_CMConfig__ParentBundleNumber__c=1;
        oALI.Apttus_CMConfig__NetUnitPrice__c=10;
        oALI.Apttus__Quantity__c=2;
        oALI.Apttus_CMConfig__PriceType__c='Recurring';
        oALI.APTS_PricingDate__c = date.today().addDays(1);
        oALI.Apttus_CMConfig__PriceListId__c = oPriceList.id;
        oALI.Apttus_CMConfig__ClassificationHierarchy__c = 'Coffee | Cafitesse';
        oALI.Apttus_CMConfig__ClassificationId__c = serviceCH.ID;
        insert oALI;
        
        Apttus_CMConfig__AgreementProductAttributeValue__c oAggAV = new Apttus_CMConfig__AgreementProductAttributeValue__c();
        oAggAV.Apttus_CMConfig__LineItemId__c = oALI.id;
        oAggAV.APTS_Number_of_hours_per_month__c = 12;
        insert oAggAV;

        APTS_AverageServiceCostPrice__c oASCP = new APTS_AverageServiceCostPrice__c();
        oASCP.APTS_ASCP_BundleProduct__c = oBundleProd.Id;
        oASCP.APTS_ASCP_AllServCP__c = 99;
        oASCP.APTS_ASCP_BasServCP__c = 79;
        oASCP.APTS_ASCP_COCP__c = 109;
        oASCP.APTS_ASCP_FOCP__c = 119;
        oASCP.APTS_End_Date__c = date.today().addMonths(2);
        oASCP.APTS_Start_Date__c = date.today();
        oASCP.APTS_ASCP_SalesOrg__c = 'SAP_0111';
        insert oASCP;
        
        APTS_AverageServiceCostPrice__c oASCPold = new APTS_AverageServiceCostPrice__c();
        oASCPold.APTS_ASCP_BundleProduct__c = oBundleProd.Id;
        oASCPold.APTS_ASCP_AllServCP__c = 89;
        oASCPold.APTS_ASCP_BasServCP__c = 69;
        oASCPold.APTS_ASCP_COCP__c = 99;
        oASCPold.APTS_ASCP_FOCP__c = 109;
        oASCPold.APTS_End_Date__c = date.today().addDays(-1);
        oASCPold.APTS_Start_Date__c = date.today().addMonths(-2);
        oASCP.APTS_ASCP_SalesOrg__c = 'SAP_0111';
        insert oASCPold;
    }

    private static testMethod void allInServiceCostTest() {
        user testUser = [SELECT Id FROM USER LIMIT 1];
        
        Apttus__AgreementLineItem__c oALI = [SELECT Id FROM Apttus__AgreementLineItem__c LIMIT 1];
        oALI.Apttus_CMConfig__ProductOptionId__c = [SELECT Id FROM Apttus_Config2__ProductOptionComponent__c WHERE Apttus_Config2__ComponentProductId__r.Name = 'All-in Coverage'].id;
        oALI.Apttus__Description__c = 'All-In Service Coverage';
        oALI.APTS_Option_Group_Text__c = 'Technical Service';
        //oALI.Apttus_CMConfig__DerivedFromId__c = oLineItem.Id;
        oALI.Apttus_CMConfig__ClassificationId__c = [select id from Apttus_Config2__ClassificationHierarchy__c where name = 'Service'].Id;
        system.runAs(testUser) {
            test.startTest();
            update oALI;
            test.stopTest();
        }
        Apttus__AgreementLineItem__c oALICheck = [SELECT Id, APTS_All_in_Service_Cost_Price__c FROM Apttus__AgreementLineItem__c LIMIT 1];
        system.assertEquals(99, oALICheck.APTS_All_in_Service_Cost_Price__c);
    }
    
    private static testMethod void basicServiceCostTest() {
        user testUser = [SELECT Id FROM USER LIMIT 1];
        Apttus__AgreementLineItem__c oALI = [SELECT Id FROM Apttus__AgreementLineItem__c LIMIT 1];
        oALI.Apttus_CMConfig__ProductOptionId__c = [SELECT Id FROM Apttus_Config2__ProductOptionComponent__c WHERE Apttus_Config2__ComponentProductId__r.Name = 'Basic Coverage'].id;
        oALI.Apttus__Description__c = 'Basic Coverage';
        oALI.APTS_Option_Group_Text__c = 'Technical Service';
        oALI.Apttus_CMConfig__ClassificationHierarchy__c = 'Concepts|Value Added Services';
        oALI.APTS_Type_of_Contract__c = 'Trial';
        system.runAs(testUser) {
            test.startTest();
            update oALI;
            test.stopTest();
        }
        Apttus__AgreementLineItem__c oALICheck = [SELECT Id, APTS_Basic_Service_Cost_Price__c FROM Apttus__AgreementLineItem__c LIMIT 1];
        system.assertEquals(79, oALICheck.APTS_Basic_Service_Cost_Price__c);
    }
    
    private static testMethod void comfortOperatingCostTest() {
        user testUser = [SELECT Id FROM USER LIMIT 1];
        Apttus__AgreementLineItem__c oALI = [SELECT Id FROM Apttus__AgreementLineItem__c LIMIT 1];
        oALI.Apttus_CMConfig__ProductOptionId__c = [SELECT Id FROM Apttus_Config2__ProductOptionComponent__c WHERE Apttus_Config2__ComponentProductId__r.Name = 'Full Co Operating Low'].id;
        oALI.Apttus__Description__c = 'Full Co Operating Low';
        oALI.APTS_Option_Group_Text__c = 'Machine Care';
        system.runAs(testUser) {
            test.startTest();
            update oALI;
            test.stopTest();
        }
        Apttus__AgreementLineItem__c oALICheck = [SELECT Id, APTS_Comfort_Operating_Cost_Price__c FROM Apttus__AgreementLineItem__c LIMIT 1];
        //system.assertEquals(109, oALICheck.APTS_Comfort_Operating_Cost_Price__c);
    }
    private static testMethod void fullOperatingCostTest() {
        user testUser = [SELECT Id FROM USER LIMIT 1];
        Apttus__AgreementLineItem__c oALI = [SELECT Id FROM Apttus__AgreementLineItem__c LIMIT 1];
        oALI.Apttus_CMConfig__ProductOptionId__c = [SELECT Id FROM Apttus_Config2__ProductOptionComponent__c WHERE Apttus_Config2__ComponentProductId__r.Name = 'Full Operating Low'].id;
        oALI.Apttus__Description__c = 'Full Operating Low';
        oALI.APTS_Option_Group_Text__c = 'Machine Care';
        system.runAs(testUser) {
            test.startTest();
            update oALI;
            delete oALI;
            undelete oALI;
            test.stopTest();
        }
        Apttus__AgreementLineItem__c oALICheck = [SELECT Id, APTS_Full_Operating_Cost_Price__c FROM Apttus__AgreementLineItem__c LIMIT 1];
        //system.assertEquals(119, oALICheck.APTS_Full_Operating_Cost_Price__c);
    }
    private static testMethod void noMatchProductTest() {
        user testUser = [SELECT Id FROM USER LIMIT 1];
        
        Apttus__AgreementLineItem__c oALI = [SELECT Id FROM Apttus__AgreementLineItem__c LIMIT 1];
        oALI.Apttus__Description__c = 'Test Prod';
        oALI.Apttus_CMConfig__ClassificationId__c = [select id from Apttus_Config2__ClassificationHierarchy__c where name = 'Service'].Id;
        system.runAs(testUser) {
            test.startTest();
            update oALI;
            test.stopTest();
        }
        Apttus__AgreementLineItem__c oALICheck = [SELECT Id, APTS_Average_Service_Cost_Price__c FROM Apttus__AgreementLineItem__c LIMIT 1];
        system.assertEquals(null, oALICheck.APTS_Average_Service_Cost_Price__c);
        list<Apttus__AgreementLineItem__c > aLIlist = new list<Apttus__AgreementLineItem__c >();
        aLIlist.add(oALICheck);
        
    }
    private static testMethod void templateTest(){
        
        List<Product2> productList = new List<Product2>();
        Product2 oBundleProd = APTS_TestDataFactory.createProduct('Cafitesse Excellence', '8100021', null, 'Bundle', TRUE, TRUE);
        productList.add(oBundleProd);
        
        Product2 oOptionProd1 = APTS_TestDataFactory.createProduct('All-in Coverage', 'TEST1', null, 'Option', FALSE, FALSE);
        productList.add(oOptionProd1);
        
        Product2 oOptionProd2 = APTS_TestDataFactory.createProduct('Basic Coverage', 'TEST2', null, 'Option', FALSE, FALSE);
        productList.add(oOptionProd2);
        
        Product2 oOptionProd3 = APTS_TestDataFactory.createProduct('Full Co Operating Low', 'TEST3', null, 'Option', FALSE, FALSE);
        productList.add(oOptionProd3);
        
        Product2 oOptionProd4 = APTS_TestDataFactory.createProduct('Full Operating Low', 'TEST4', null, 'Option', FALSE, FALSE);
        productList.add(oOptionProd4);
        insert productList;
        
        Apttus_Config2__ClassificationName__c serviceOG = APTS_TestDataFactory.createCategory();
        serviceOG.Apttus_Config2__HierarchyLabel__c = 'Service';
        serviceOG.Apttus_Config2__Type__c = 'Option Group';        
        insert serviceOG;
        
        Apttus_Config2__ClassificationHierarchy__c serviceCH = APTS_TestDataFactory.createCategoryHierarchy(serviceOG.Id, 'Service');
        insert serviceCH;
        
        Apttus_Config2__ClassificationHierarchy__c machinecareCH = APTS_TestDataFactory.createSubCategory(serviceOG.Id,serviceCH.id);
        machinecareCH.Name = 'Machine Care';
        machinecareCH.Apttus_Config2__Label__c = 'Machine Care';
        insert machinecareCH;
        
        Apttus_Config2__ProductOptionGroup__c optionGroup = APTS_TestDataFactory.createProductOptionGroup(serviceCH.id, machinecareCH.id);
        insert optionGroup;
        
        List<Apttus_Config2__ProductOptionComponent__c> optionComponentList = new List<Apttus_Config2__ProductOptionComponent__c>();
        Apttus_Config2__ProductOptionComponent__c oOptComponent1 = APTS_TestDataFactory.createProductOptionComponent(optionGroup.id);
        oOptComponent1.Apttus_Config2__ParentProductId__c = oBundleProd.id;
        oOptComponent1.Apttus_Config2__ComponentProductId__c = oOptionProd1.id;
        oOptComponent1.Apttus_Config2__ProductOptionGroupId__c = optionGroup.id;
        optionComponentList.add(oOptComponent1);
        
        Apttus_Config2__ProductOptionComponent__c oOptComponent2 = APTS_TestDataFactory.createProductOptionComponent(optionGroup.id);
        oOptComponent2.Apttus_Config2__ParentProductId__c = oBundleProd.id;
        oOptComponent2.Apttus_Config2__ComponentProductId__c = oOptionProd2.id;
        oOptComponent2.Apttus_Config2__ProductOptionGroupId__c = optionGroup.id;
        optionComponentList.add(oOptComponent2);
        
        Apttus_Config2__ProductOptionComponent__c oOptComponent3 = APTS_TestDataFactory.createProductOptionComponent(optionGroup.id);
        oOptComponent3.Apttus_Config2__ParentProductId__c = oBundleProd.id;
        oOptComponent3.Apttus_Config2__ComponentProductId__c = oOptionProd3.id;
        oOptComponent3.Apttus_Config2__ProductOptionGroupId__c = optionGroup.id;
        optionComponentList.add(oOptComponent3);
        
        Apttus_Config2__ProductOptionComponent__c oOptComponent4 = APTS_TestDataFactory.createProductOptionComponent(optionGroup.id);
        oOptComponent4.Apttus_Config2__ParentProductId__c = oBundleProd.id;
        oOptComponent4.Apttus_Config2__ComponentProductId__c = oOptionProd4.id;
        oOptComponent4.Apttus_Config2__ProductOptionGroupId__c = optionGroup.id;
        optionComponentList.add(oOptComponent4);
        insert optionComponentList;
        
        Account oAcc = APTS_TestDataFactory.createAccount('Test Account');
        insert oAcc;
        
        Apttus_Config2__PriceList__c oPriceList = APTS_TestDataFactory.createPriceList('Test');
        oPriceList.APTS_Region__c = 'SAP_0111';
        insert oPriceList;
        
        Apttus__APTS_Agreement__c oAgg = APTS_TestDataFactory.createAgreement(null, null, oAcc.id, 'Standard Deal');
        oAgg.APTS_PricingDate__c = date.today().addDays(1);
        insert oAgg;
        List<Apttus__AgreementLineItem__c> agreementLineItemList = new List<Apttus__AgreementLineItem__c>();
        Apttus__AgreementLineItem__c oALI2 = APTS_TestDataFactory.createAgreementLineItem(null, oAgg.id, oAcc.id, null);
        oALI2.Apttus__ProductId__c = oBundleProd.id;
        oALI2.Apttus_CMConfig__LineType__c = 'Product/Service';
        oALI2.Apttus_CMConfig__IsOptionRollupLine__c = false;
        oALI2.Apttus_CMConfig__HasOptions__c = true; 
        oALI2.Apttus_CMConfig__NetUnitPrice__c=10;
        oALI2.Apttus__Quantity__c=2;
        oALI2.Apttus_CMConfig__PrimaryLineNumber__c=1;
        oALI2.Apttus_CMConfig__PriceType__c='Recurring';
        oALI2.APTS_PricingDate__c = date.today().addDays(1);
        oALI2.Apttus_CMConfig__PriceListId__c = oPriceList.id;
        oALI2.Apttus_CMConfig__ClassificationHierarchy__c = 'Coffee | Cafitesse';
        oALI2.Apttus_CMConfig__ClassificationId__c = serviceCH.ID;
        agreementLineItemList.add(oALI2);
        
        Apttus__AgreementLineItem__c oALI = APTS_TestDataFactory.createAgreementLineItem(null, oAgg.id, oAcc.id, null);
        oALI.Apttus__ProductId__c = oBundleProd.id;
        oALI.Apttus_CMConfig__LineType__c = 'Option';
        oALI.Apttus_CMConfig__ParentBundleNumber__c=1;
        oALI.Apttus_CMConfig__NetUnitPrice__c=10;
        oALI.Apttus__Quantity__c=2;
        oALI.Apttus_CMConfig__PriceType__c='Recurring';
        oALI.APTS_PricingDate__c = date.today().addDays(1);
        oALI.Apttus_CMConfig__PriceListId__c = oPriceList.id;
        oALI.Apttus_CMConfig__ClassificationHierarchy__c = 'Coffee | Cafitesse';
        oALI.Apttus_CMConfig__ClassificationId__c = serviceCH.ID;
        agreementLineItemList.add(oALI);
        
        Apttus__AgreementLineItem__c oALI1 = APTS_TestDataFactory.createAgreementLineItem(null, oAgg.id, oAcc.id, null);
        oALI1.Apttus__ProductId__c = oBundleProd.id;
        oALI1.Apttus_CMConfig__LineType__c = 'Option';
        oALI1.Apttus_CMConfig__NetUnitPrice__c=10;
        oALI1.Apttus_CMConfig__ParentBundleNumber__c=1;
        oALI1.Apttus__Quantity__c=2;
        oALI1.Apttus_CMConfig__PriceType__c='Recurring';
        oALI1.APTS_PricingDate__c = date.today().addDays(1);
        oALI1.Apttus_CMConfig__PriceListId__c = oPriceList.id;
        oALI1.Apttus_CMConfig__ClassificationHierarchy__c = 'Coffee | Cafitesse';
        oALI1.Apttus_CMConfig__ClassificationId__c = serviceCH.ID;
        agreementLineItemList.add(oALI1);
        
        
        Apttus__AgreementLineItem__c oALI3 = APTS_TestDataFactory.createAgreementLineItem(null, oAgg.id, oAcc.id, null);
        oALI3.Apttus__ProductId__c = oBundleProd.id;
        oALI3.Apttus_CMConfig__LineType__c = 'Option';
        oALI3.Apttus_CMConfig__ParentBundleNumber__c=1;
        oALI3.Apttus_CMConfig__NetUnitPrice__c=10;
        oALI3.Apttus__Quantity__c=2;
        oALI3.Apttus_CMConfig__PriceType__c='One Time';
        oALI3.APTS_PricingDate__c = date.today().addDays(1);
        oALI3.Apttus_CMConfig__PriceListId__c = oPriceList.id;
        oALI3.Apttus_CMConfig__ClassificationHierarchy__c = 'Coffee | Cafitesse';
        oALI3.Apttus_CMConfig__ClassificationId__c = serviceCH.ID;
        agreementLineItemList.add(oALI3);
        
        Apttus__AgreementLineItem__c oALI4 = APTS_TestDataFactory.createAgreementLineItem(null, oAgg.id, oAcc.id, null);
        oALI4.Apttus__ProductId__c = oBundleProd.id;
        oALI4.Apttus_CMConfig__LineType__c = 'Option';
        oALI4.Apttus_CMConfig__NetUnitPrice__c=10;
        oALI4.Apttus_CMConfig__ParentBundleNumber__c=1;
        oALI4.Apttus__Quantity__c=2;
        oALI4.Apttus_CMConfig__PriceType__c='One Time';
        oALI4.APTS_PricingDate__c = date.today().addDays(1);
        oALI4.Apttus_CMConfig__PriceListId__c = oPriceList.id;
        oALI4.Apttus_CMConfig__ClassificationHierarchy__c = 'Coffee | Cafitesse';
        oALI4.Apttus_CMConfig__ClassificationId__c = serviceCH.ID;
        agreementLineItemList.add(oALI4);
        
        Insert agreementLineItemList;
         
        Apttus_CMConfig__AgreementProductAttributeValue__c oAggAV = new Apttus_CMConfig__AgreementProductAttributeValue__c();
        oAggAV.Apttus_CMConfig__LineItemId__c = oALI.id;
        oAggAV.APTS_Number_of_hours_per_month__c = 12;
        insert oAggAV;

        APTS_AverageServiceCostPrice__c oASCP = new APTS_AverageServiceCostPrice__c();
        oASCP.APTS_ASCP_BundleProduct__c = oBundleProd.Id;
        oASCP.APTS_ASCP_AllServCP__c = 99;
        oASCP.APTS_ASCP_BasServCP__c = 79;
        oASCP.APTS_ASCP_COCP__c = 109;
        oASCP.APTS_ASCP_FOCP__c = 119;
        oASCP.APTS_End_Date__c = date.today().addMonths(2);
        oASCP.APTS_Start_Date__c = date.today();
        oASCP.APTS_ASCP_SalesOrg__c = 'SAP_0111';
        insert oASCP;
        
        APTS_AverageServiceCostPrice__c oASCPold = new APTS_AverageServiceCostPrice__c();
        oASCPold.APTS_ASCP_BundleProduct__c = oBundleProd.Id;
        oASCPold.APTS_ASCP_AllServCP__c = 89;
        oASCPold.APTS_ASCP_BasServCP__c = 69;
        oASCPold.APTS_ASCP_COCP__c = 99;
        oASCPold.APTS_ASCP_FOCP__c = 109;
        oASCPold.APTS_End_Date__c = date.today().addDays(-1);
        oASCPold.APTS_Start_Date__c = date.today().addMonths(-2);
        oASCP.APTS_ASCP_SalesOrg__c = 'SAP_0111';
        insert oASCPold;
    }
}