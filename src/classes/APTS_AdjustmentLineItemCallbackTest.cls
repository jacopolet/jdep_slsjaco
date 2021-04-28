/*************************************************************
@Name: APTS_AdjustmentLineItemCallbackTest
@Author: Ariel Quesada
@CreateDate:  12th June, 2018
@Description: Test CallBack for APTS_AdjustmentLineItemCallback
******************************************************************/
@isTest
public class APTS_AdjustmentLineItemCallbackTest {
    @testSetup static void setupTestData() {
        User oTestUser = APTS_TestFacade.createTestUser();
        APTS_TestFacade.createMandatoryRecords(oTestUser);
        APTS_TestFacade.createAndConfigureAgreement(oTestUser);
        APTS_TestFacade.createAndConfigureOrder(oTestUser);

        Apttus_Config2__ConfigCustomClasses__c configCustomClassesProperty = new Apttus_Config2__ConfigCustomClasses__c();
        configCustomClassesProperty.Name = 'Config Custom Classes';
        configCustomClassesProperty.Apttus_Config2__AdjustmentLineItemCallbackClass__c = 'APTS_AdjustmentLineItemCallback';
        insert configCustomClassesProperty;

        Apttus_Config2__ConfigLineItemCustomFields__c oConfigLineItemCustomFields = new Apttus_Config2__ConfigLineItemCustomFields__c();
        oConfigLineItemCustomFields.Name = 'System Properties';
        oConfigLineItemCustomFields.Apttus_Config2__CustomFieldNames__c = 'APTS_ATP_Check_Status__c,Apttus_Config2__HasIncentives__c,Apttus_Config2__AttributeValueId__r.APTS_Type_of_contract__c,Apttus_Config2__PriceListItemId__r.APTS_Default_Selling_Uom__c,Apttus_Config2__SellingUom__c,APTS_Requested_Delivery_Date__c';
        oConfigLineItemCustomFields.Apttus_Config2__CustomFieldNames2__c = 'Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__ParentOptionGroupId__r.Apttus_Config2__Label__c, Apttus_Config2__OptionId__r.Name';
        oConfigLineItemCustomFields.Apttus_Config2__CustomFieldNames3__c = 'Apttus_Config2__PriceListItemId__r.APTS_Call_Out_Coverage__c, Apttus_Config2__PriceListItemId__r.APTS_Labour_Coverage__c, Apttus_Config2__PriceListItemId__r.APTS_Spare_Parts_Coverage__c';
        oConfigLineItemCustomFields.Apttus_Config2__CustomFieldNames4__c = 'Apttus_Config2__AttributeValueId__r.APTS_Call_Out_Coverage_chk__c, Apttus_Config2__AttributeValueId__r.APTS_Labour_Coverage_chk__c, Apttus_Config2__AttributeValueId__r.APTS_Spare_Parts_Coverage_chk__c';
        insert oConfigLineItemCustomFields;

        Apttus_Config2__ConfigLineItemCustomFields__c oConfigLineItemCustomFields1 = new Apttus_Config2__ConfigLineItemCustomFields__c();
        oConfigLineItemCustomFields1.Name = 'System Properties 1';
        oConfigLineItemCustomFields1.Apttus_Config2__CustomFieldNames__c = 'Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Is_Amended_for_Indexation__c,Apttus_Config2__ConfigurationId__r.APTS_Max_Requested_Delivery_Date__c';
        oConfigLineItemCustomFields1.Apttus_Config2__CustomFieldNames2__c = 'APTS_Type_of_Contract__c';
        oConfigLineItemCustomFields1.Apttus_Config2__CustomFieldNames3__c = '';
        oConfigLineItemCustomFields1.Apttus_Config2__CustomFieldNames4__c = '';
        insert oConfigLineItemCustomFields1;
    }


    @isTest static void test_AdjustmentLineItemCallbackcreateAdjustmentLineItems() {
        String standardDeal = 'Standard Deal';
        String billingPrefrence = 'JDETestPrefrence';
        String accountName = 'JDETestAccount';
        String contactNumber = '1010101011';
        String opportunityName = 'JDETestOpportunity';
        String priceListName = 'JDETest Price List';
        String prodFamilyName = 'MA';
        String prodConfigBundle = 'Bundle';
        String prodConfigOption = 'Option';
        String productService = 'PRODUCT/SERVICE';
        String billingFreqMonthly = 'Monthly';
        String billingTypeAdvanced = 'Bill In Advance';
        String priceTypeOnetime = 'One Time';
        String priceUnitPer = 'Per Unit';
        String priceUnitEach = 'Each';
        String orderTypeMachineOrder = 'Machine Order';
        String orderSubtypeTechnicalSwap = 'Technical Swap';
        String commercialSwap = 'Commercial Swap';
        String pageParamId = 'id';
        String pageParamFirstParam = 'firstParam';
        String agreementActivated = 'Activated';
        String agrrementInEffect = 'In Effect';

        User oTestUser = APTS_TestFacade.getTestUser();

        Apttus_Config2__BillingPreference__c billPref = APTS_TestDataFactory.createBillingPrefrence(billingPrefrence);
        Database.insert(billPref, FALSE);

        Account acc = APTS_TestDataFactory.createAccount('testAccount');
        Database.insert(acc);

        Contact con = APTS_TestDataFactory.createContact(acc, 'testContact');
        con.Email = 'test@test.com';
        Database.insert(con);

        Apttus_Config2__PriceList__c pricelist = APTS_TestDataFactory.createPriceList('testPriceList');
        Database.insert(pricelist);

        Product2 prod1 = APTS_TestDataFactory.createProduct(accountName, accountName, prodFamilyName, prodConfigBundle, FALSE, TRUE);
        Database.insert(prod1);

        Apttus_Config2__PriceListItem__c pli1 = APTS_TestDataFactory.createPriceListItem(pricelist.Id, prod1.Id);
        pli1.Apttus_Config2__ChargeType__c = 'Additional Service Fee';
        Database.insert(pli1);

        Apttus__APTS_Agreement__c oAgreement = APTS_TestDataFactory.createAgreement(con.id, pricelist.id, acc.id, 'Standard Deal');
        Database.insert(oAgreement);

        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestDataFactory.createProductConfig(oAgreement);
        Database.insert(oProductConfiguration);

        Apttus_Config2__LineItem__c lineItem = APTS_TestDataFactory.createLineItem(oProductConfiguration, pli1.Id, NULL, prod1.Id, NULL, NULL, 1, 1, 1, productService, billPref.Id, billingFreqMonthly, billingTypeAdvanced, priceTypeOnetime, priceUnitPer, priceUnitEach, 200, 10);
        lineItem.Apttus_Config2__LineType__c = 'Product/Service';
        Database.insert(lineItem);



        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder();
        oOrder.APTS_Order_Type__c  = System.Label.APTS_Order_Type_Operating;
        oOrder.APTS_Order_Sub_Type__c = System.Label.APTS_Order_Type_Digital;
        oOrder.APTS_Source_Order_Number__c = '8909';
        Database.update(oOrder);

        oProductConfiguration.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
        oProductConfiguration.Apttus_Config2__Status__c = 'Finalized';
        oProductConfiguration.Apttus_Config2__OrderId__c = oOrder.id;
        Database.update(oProductConfiguration);


        Apttus_Config2__LineItem__c lineItem11 = APTS_TestDataFactory.createLineItem(oProductConfiguration, pli1.Id, NULL, prod1.Id, NULL, NULL, 1, 1, 1, productService, billPref.Id, billingFreqMonthly, billingTypeAdvanced, priceTypeOnetime, priceUnitPer, priceUnitEach, 200, 10);
        lineItem11.Apttus_Config2__LineType__c = 'Option';
        Database.insert(lineItem11);

        oAgreement.APTS_Is_Amended_for_Indexation__c = true;
        Database.update(oAgreement);

        Apttus_Config2__ProductAttributeValue__c pav = new Apttus_Config2__ProductAttributeValue__c();
        pav.Apttus_Config2__LineItemId__c = lineItem.id;
        pav.APTS_Type_of_contract__c = 'Consumption';
        Database.insert(pav);

        List<APTS_Contract_Entitlement_Repository__c> repoList = new List<APTS_Contract_Entitlement_Repository__c>();

        APTS_Contract_Entitlement_Repository__c repo1 = new APTS_Contract_Entitlement_Repository__c();
        repo1.APTS_Adjustment_Type__c = 'PPR';
        repo1.APTS_Adjustment_Value__c = 20.0;
        repo1.APTS_Agreement_Type__c = 'Standard Deal';
        repo1.APTS_Exclusion_Exception_Available__c = false;
        repo1.APTS_Is_Pending__c = false;
        repo1.APTS_Max_Volume__c = false;
        repo1.APTS_Product__c = prod1.Id;
        repo1.APTS_Sub_Type__c = 'ZP03';
        repoList.add(repo1);

        APTS_Contract_Entitlement_Repository__c repo2 = new APTS_Contract_Entitlement_Repository__c();
        repo2.APTS_Adjustment_Type__c = 'TPR';
        repo2.APTS_Adjustment_Value__c = 20.0;
        repo2.APTS_Agreement_Type__c = 'Standard Deal';
        repo2.APTS_Exclusion_Exception_Available__c = false;
        repo2.APTS_Is_Pending__c = false;
        repo2.APTS_Max_Volume__c = false;
        repo2.APTS_Product__c = prod1.Id;
        repo2.APTS_Sub_Type__c = 'ZP06';
        repoList.add(repo2);

        APTS_Contract_Entitlement_Repository__c repo3 = new APTS_Contract_Entitlement_Repository__c();
        repo3.APTS_Adjustment_Type__c = 'EFF';
        repo3.APTS_Adjustment_Value__c = 20.0;
        repo3.APTS_Agreement_Type__c = 'Standard Deal';
        repo3.APTS_Exclusion_Exception_Available__c = false;
        repo3.APTS_Is_Pending__c = false;
        repo3.APTS_Max_Volume__c = false;
        repo3.APTS_Product__c = prod1.Id;
        repo3.APTS_Sub_Type__c = 'ZP07';
        repoList.add(repo3);

        APTS_Contract_Entitlement_Repository__c repo11 = new APTS_Contract_Entitlement_Repository__c();
        repo11.APTS_Adjustment_Type__c = 'PPR';
        repo11.APTS_Adjustment_Value__c = 20.0;
        repo11.APTS_Agreement_Type__c = 'Standard Deal';
        repo11.APTS_Exclusion_Exception_Available__c = false;
        repo11.APTS_Is_Pending__c = false;
        repo11.APTS_Max_Volume__c = false;
        repo11.APTS_Product__c = prod1.Id;
        repo11.APTS_Sub_Type__c = 'ZP04';
        repoList.add(repo11);

        APTS_Contract_Entitlement_Repository__c repo12 = new APTS_Contract_Entitlement_Repository__c();
        repo12.APTS_Adjustment_Type__c = 'PPR';
        repo12.APTS_Adjustment_Value__c = 20.0;
        repo12.APTS_Agreement_Type__c = 'Standard Deal';
        repo12.APTS_Exclusion_Exception_Available__c = false;
        repo12.APTS_Is_Pending__c = false;
        repo12.APTS_Max_Volume__c = false;
        repo12.APTS_Product__c = prod1.Id;
        repo12.APTS_Sub_Type__c = 'ZP08';
        repoList.add(repo12);

        APTS_Contract_Entitlement_Repository__c repo13 = new APTS_Contract_Entitlement_Repository__c();
        repo13.APTS_Adjustment_Type__c = 'PPR';
        repo13.APTS_Adjustment_Value__c = 20.0;
        repo13.APTS_Agreement_Type__c = 'Standard Deal';
        repo13.APTS_Exclusion_Exception_Available__c = false;
        repo13.APTS_Is_Pending__c = false;
        repo13.APTS_Max_Volume__c = false;
        repo13.APTS_Product__c = prod1.Id;
        repo13.APTS_Sub_Type__c = 'ZP10';
        repoList.add(repo13);

        APTS_Contract_Entitlement_Repository__c repo14 = new APTS_Contract_Entitlement_Repository__c();
        repo14.APTS_Adjustment_Type__c = 'PPR';
        repo14.APTS_Adjustment_Value__c = 20.0;
        repo14.APTS_Agreement_Type__c = 'Standard Deal';
        repo14.APTS_Exclusion_Exception_Available__c = false;
        repo14.APTS_Is_Pending__c = false;
        repo14.APTS_Max_Volume__c = false;
        repo14.APTS_Product__c = prod1.Id;
        repo14.APTS_Sub_Type__c = 'ZP11';
        repoList.add(repo14);

        APTS_Contract_Entitlement_Repository__c repo15 = new APTS_Contract_Entitlement_Repository__c();
        repo15.APTS_Adjustment_Type__c = 'PPR';
        repo15.APTS_Adjustment_Value__c = 20.0;
        repo15.APTS_Agreement_Type__c = 'Standard Deal';
        repo15.APTS_Exclusion_Exception_Available__c = false;
        repo15.APTS_Is_Pending__c = false;
        repo15.APTS_Max_Volume__c = false;
        repo15.APTS_Product__c = prod1.Id;
        repo15.APTS_Sub_Type__c = 'ZP12';
        repoList.add(repo15);

        APTS_Contract_Entitlement_Repository__c repo16 = new APTS_Contract_Entitlement_Repository__c();
        repo16.APTS_Adjustment_Type__c = 'PPR';
        repo16.APTS_Adjustment_Value__c = 20.0;
        repo16.APTS_Agreement_Type__c = 'Standard Deal';
        repo16.APTS_Exclusion_Exception_Available__c = false;
        repo16.APTS_Is_Pending__c = false;
        repo16.APTS_Max_Volume__c = false;
        repo16.APTS_Product__c = prod1.Id;
        repo16.APTS_Sub_Type__c = 'ZP13';
        repoList.add(repo16);

        APTS_Contract_Entitlement_Repository__c repo161 = new APTS_Contract_Entitlement_Repository__c();
        repo161.APTS_Adjustment_Type__c = 'PPR';
        repo161.APTS_Adjustment_Value__c = 20.0;
        repo161.APTS_Agreement_Type__c = 'Standard Deal';
        repo161.APTS_Exclusion_Exception_Available__c = false;
        repo161.APTS_Is_Pending__c = false;
        repo161.APTS_Max_Volume__c = false;
        repo161.APTS_Product__c = prod1.Id;
        repo161.APTS_Sub_Type__c = 'ZP15';
        repoList.add(repo161);

        APTS_Contract_Entitlement_Repository__c repo17 = new APTS_Contract_Entitlement_Repository__c();
        repo17.APTS_Adjustment_Type__c = 'PPR';
        repo17.APTS_Adjustment_Value__c = 20.0;
        repo17.APTS_Agreement_Type__c = 'Standard Deal';
        repo17.APTS_Exclusion_Exception_Available__c = false;
        repo17.APTS_Is_Pending__c = false;
        repo17.APTS_Max_Volume__c = false;
        repo17.APTS_Product__c = prod1.Id;
        repo17.APTS_Sub_Type__c = 'ZX10';
        repoList.add(repo17);
        APTS_Contract_Entitlement_Repository__c repo18 = new APTS_Contract_Entitlement_Repository__c();
        repo18.APTS_Adjustment_Type__c = 'PPR';
        repo18.APTS_Adjustment_Value__c = 20.0;
        repo18.APTS_Agreement_Type__c = 'Standard Deal';
        repo18.APTS_Exclusion_Exception_Available__c = false;
        repo18.APTS_Is_Pending__c = false;
        repo18.APTS_Max_Volume__c = false;
        repo18.APTS_Product__c = prod1.Id;
        repo18.APTS_Sub_Type__c = 'YOCI';
        repoList.add(repo18);
        APTS_Contract_Entitlement_Repository__c repo19 = new APTS_Contract_Entitlement_Repository__c();
        repo19.APTS_Adjustment_Type__c = 'PPR';
        repo19.APTS_Adjustment_Value__c = 20.0;
        repo19.APTS_Agreement_Type__c = 'Standard Deal';
        repo19.APTS_Exclusion_Exception_Available__c = false;
        repo19.APTS_Is_Pending__c = false;
        repo19.APTS_Max_Volume__c = false;
        repo19.APTS_Product__c = prod1.Id;
        repo19.APTS_Sub_Type__c = 'YOFT';
        repoList.add(repo19);



        Database.insert(repoList, false);


        /*
        Apttus_Config2__ProductConfiguration__c oProductConfiguration11 = APTS_TestDataFactory.createProductConfig(oOrder);
              oProductConfiguration11.APTS_Flow__c = 'NGSTANDARDORDER';
              oProductConfiguration11.Apttus_Config2__Status__c = 'Finalized';
              oProductConfiguration11.Apttus_Config2__OrderId__c = oOrder.id;
              insert oProductConfiguration11;*/



        //lineItem.Apttus_Config2__ConfigurationId__c = oProductConfiguration.Id;
        lineItem.Apttus_Config2__BasePriceOverride__c = 100;
        lineItem.Apttus_Config2__ChargeType__c = APTS_CPQConstants.SALES_PRICE;
        lineItem.Apttus_Config2__AttributeValueId__c = pav.id;
        Database.update(lineItem);
        /*
          Apttus_Config2__ClassificationName__c category = APTS_TestDataFactory.createCategory();
         Database.insert(category);

         Apttus_Config2__ClassificationHierarchy__c categoryHrchy = APTS_TestDataFactory.createCategoryHierarchy(category.id, 'Cat Hierarchy');
         categoryHrchy.Apttus_Config2__Label__c = APTS_CPQConstants.LABEL_ConsignmentIngredients;
         Database.insert(categoryHrchy);

          Product2 prod2 = APTS_TestDataFactory.createProduct(accountName, accountName, prodFamilyName, prodConfigBundle, FALSE, TRUE);
         Database.insert(prod2);

         Apttus_Config2__ProductOptionGroup__c prodOpGroup = APTS_TestDataFactory.createProductOptionGroup(categoryHrchy.id, categoryHrchy.id);
         Database.insert(prodOpGroup);

         Apttus_Config2__ProductOptionComponent__c productOptionComp = APTS_TestDataFactory.createProductOptionComponent(prodOpGroup.id);
         productOptionComp.Apttus_Config2__ComponentProductId__c = prod2.id;
         productOptionComp.Apttus_Config2__ParentProductId__c = prod2.id;
         productOptionComp.Apttus_Config2__ProductOptionGroupId__c= prodOpGroup.id;
         Database.insert(productOptionComp);
         */



        lineItem11.Apttus_Config2__BasePriceOverride__c = 100;
        lineItem11.Apttus_Config2__ChargeType__c = APTS_CPQConstants.SALES_PRICE;
        lineItem11.Apttus_Config2__AttributeValueId__c = pav.id;
        //lineItem11.APTS_Type_of_contract__c = 'Consumption';
        //lineItem11.Apttus_Config2__ProductOptionId__c = productOptionComp.id;


        //lineItem11.Apttus_Config2__ConfigurationId__c = oProductConfiguration.Id;
        // System.assertequals(null,oProductConfiguration.Id);
        //System.assertequals(lineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c,System.Label.APTS_Order_Type_Digital);

//System.assertequals(lineItem11.Apttus_Config2__ConfigurationId__r.id,oProductConfiguration.id);
        Database.update(lineItem11);
        //System.assertequals(lineItem11.Apttus_Config2__ConfigurationId__r.id,oProductConfiguration.id);
        // System.assertequals(lineItem11.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.id,oOrder.id);
        // System.assertequals(lineItem11.Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c,System.Label.APTS_Order_Type_Digital);

        Apttus_Config2__LineItem__c lineItem1 = [select id, APTS_Type_of_contract__c, Apttus_Config2__ChargeType__c, Apttus_Config2__LineType__c from Apttus_Config2__LineItem__c where id = : lineItem.id];
        System.debug('lineItem1==========>' + lineItem1);

        Apttus__APTS_Related_Agreement__c oRelatedAgreement = new Apttus__APTS_Related_Agreement__c();
        oRelatedAgreement.Apttus__APTS_Contract_to__c = oAgreement.Id;
        oRelatedAgreement.Apttus__APTS_Contract_From__c = oAgreement.Id;
        Database.insert(oRelatedAgreement);

        APTS_Indexation_Executing__c oIndexationExecuting = new APTS_Indexation_Executing__c();
        oIndexationExecuting.APTS_Indexation_Contract__c = oRelatedAgreement.Apttus__APTS_Contract_From__c;
        oIndexationExecuting.Is_Indexation_Executed__c = false;
        oIndexationExecuting.APTS_Indexation_Number__c = 10;
        oIndexationExecuting.APTS_Execution_Date__c = System.today().addDays(30);
        Database.insert(oIndexationExecuting);

        APTS_AdjustmentLineItemCallback oCallback = new APTS_AdjustmentLineItemCallback();

        Map<String, Apttus_Config2__AdjustmentLineItem__c> ceradjustmentMap = oCallback.processcerdata(lineItem, repoList, false);
        Map<String, Apttus_Config2__AdjustmentLineItem__c> ceradjustmentMap1 = oCallback.processcerdata(lineItem, repoList);
        System.debug('Before Calling');
        //oCallback.createCPQAdjustmentLineItems(lineItem11);
        Test.startTest();




        Apttus_Config2.LineItem configLineItem;
        /*configLineItem
        List<Apttus_Config2__AdjustmentLineItem__c> result =
            oCallback.createAdjustmentLineItems(configLineItem);*/

        Apttus_Config2__AdjustmentLineItem__c adjustlineItem = new Apttus_Config2__AdjustmentLineItem__c (Apttus_Config2__LineNumber__c = 12345,
                Apttus_Config2__LineItemId__c = lineItem.id,
                Apttus_Config2__Type__c = APTS_CPQConstants.PPR);
        Database.insert(adjustlineItem);

        Apttus_Config2__AdjustmentLineItem__c adjustlineItem11 = new Apttus_Config2__AdjustmentLineItem__c (Apttus_Config2__LineNumber__c = 12345,
                Apttus_Config2__LineItemId__c = lineItem11.id,
                Apttus_Config2__Type__c = APTS_CPQConstants.PPR);
        Database.insert(adjustlineItem11);
        System.assertEquals(adjustlineItem11.Apttus_Config2__Type__c, APTS_CPQConstants.PPR);
        //System.runAs(oTestUser) {

        /*Apttus_Config2.PricingWebService.computeTotalPriceForCart(oProductConfiguration.Id);
        Apttus_Config2.PricingWebService.computeBasePriceForItemColl(oProductConfiguration.Id, 1);
        Apttus_Config2.PricingWebService.computeNetPriceForItemColl(oProductConfiguration.Id, 1);
        Apttus_Config2.PricingWebService.computeBasicPriceForItemColl(oProductConfiguration, lineItemList);*/
        Apttus_Config2.CallbackTester.testAdjustmentLineItemCallback
        ( oProductConfiguration.id
          , lineItem
          , new APTS_AdjustmentLineItemCallback ());

        Apttus_Config2.CallbackTester.testAdjustmentLineItemCallback
        ( oProductConfiguration.id
          , lineItem11
          , new APTS_AdjustmentLineItemCallback ());

        //}
        Apttus_Config2__AdjustmentLineItem__c adj11 = [select id, Apttus_Config2__Type__c from Apttus_Config2__AdjustmentLineItem__c where Apttus_Config2__LineItemId__c = :lineItem11.Id][0];
        System.assertEquals(adj11.Apttus_Config2__Type__c, APTS_CPQConstants.PPR);

        try {oCallback.beforeSaveAdjustmentLineItems(null, null); } catch (Exception ex) {}
        Test.stopTest();
    }

    @isTest static void test_AdjustmentLineItemCallbackcreateAdjustmentLineItems1() {

        String standardDeal = 'Standard Deal';
        String billingPrefrence = 'JDETestPrefrence';
        String accountName = 'JDETestAccount';
        String contactNumber = '1010101011';
        String opportunityName = 'JDETestOpportunity';
        String priceListName = 'JDETest Price List';
        String prodFamilyName = 'MA';
        String prodConfigBundle = 'Bundle';
        String prodConfigOption = 'Option';
        String productService = 'PRODUCT/SERVICE';
        String billingFreqMonthly = 'Monthly';
        String billingTypeAdvanced = 'Bill In Advance';
        String priceTypeOnetime = 'One Time';
        String priceUnitPer = 'Per Unit';
        String priceUnitEach = 'Each';
        String orderTypeMachineOrder = 'Machine Order';
        String orderSubtypeTechnicalSwap = 'Technical Swap';
        String commercialSwap = 'Commercial Swap';
        String pageParamId = 'id';
        String pageParamFirstParam = 'firstParam';
        String agreementActivated = 'Activated';
        String agrrementInEffect = 'In Effect';

        User oTestUser = APTS_TestFacade.getTestUser();

        Apttus_Config2__BillingPreference__c billPref = APTS_TestDataFactory.createBillingPrefrence(billingPrefrence);
        Database.insert(billPref, FALSE);

        Account acc = APTS_TestDataFactory.createAccount('testAccount');
        Database.insert(acc);

        Contact con = APTS_TestDataFactory.createContact(acc, 'testContact');
        con.Email = 'test@test.com';
        Database.insert(con);

        Apttus_Config2__PriceList__c pricelist = APTS_TestDataFactory.createPriceList('testPriceList');
        Database.insert(pricelist);

        Product2 prod1 = APTS_TestDataFactory.createProduct(accountName, accountName, prodFamilyName, prodConfigBundle, FALSE, TRUE);
        Database.insert(prod1);

        Product2 prod2 = APTS_TestDataFactory.createProduct(accountName, accountName, prodFamilyName, prodConfigBundle, FALSE, TRUE);
        Database.insert(prod2);

        Apttus_Config2__PriceListItem__c pli1 = APTS_TestDataFactory.createPriceListItem(pricelist.Id, prod1.Id);
        Database.insert(pli1);

        Apttus__APTS_Agreement__c oAgreement = APTS_TestDataFactory.createAgreement(con.id, pricelist.id, acc.id, 'Standard Deal');
        Database.insert(oAgreement);

        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestDataFactory.createProductConfig(oAgreement);
        Database.insert(oProductConfiguration);

        Apttus_Config2__LineItem__c lineItem = APTS_TestDataFactory.createLineItem(oProductConfiguration, pli1.Id, NULL, prod1.Id, NULL, NULL, 1, 1, 1, productService, billPref.Id, billingFreqMonthly, billingTypeAdvanced, priceTypeOnetime, priceUnitPer, priceUnitEach, 200, 10);
        Database.insert(lineItem);

        Apttus_Config2__ClassificationName__c category = APTS_TestDataFactory.createCategory();
        Database.insert(category);

        Apttus_Config2__ClassificationHierarchy__c categoryHrchy = APTS_TestDataFactory.createCategoryHierarchy(category.id, 'Cat Hierarchy');
        categoryHrchy.Apttus_Config2__Label__c = APTS_CPQConstants.LABEL_ConsignmentIngredients;
        Database.insert(categoryHrchy);

        Apttus_Config2__ProductOptionGroup__c prodOpGroup = APTS_TestDataFactory.createProductOptionGroup(categoryHrchy.id, categoryHrchy.id);
        Database.insert(prodOpGroup);

        Apttus_Config2__ProductOptionComponent__c productOptionComp = APTS_TestDataFactory.createProductOptionComponent(prodOpGroup.id);
        productOptionComp.Apttus_Config2__ComponentProductId__c = prod2.id;
        productOptionComp.Apttus_Config2__ParentProductId__c = prod2.id;
        Database.insert(productOptionComp);

        Apttus_Config2__LineItem__c lineItem1 = APTS_TestDataFactory.createLineItem(oProductConfiguration, pli1.Id, NULL, prod1.Id, NULL, NULL, 1, 1, 1, productService, billPref.Id, billingFreqMonthly, billingTypeAdvanced, priceTypeOnetime, priceUnitPer, priceUnitEach, 200, 10);
        lineItem1.Apttus_Config2__ProductOptionId__c = productOptionComp.id;
        Database.insert(lineItem1);


        oProductConfiguration.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
        Database.update(oProductConfiguration);

        oAgreement.APTS_Is_Amended_for_Indexation__c = true;
        Database.update(oAgreement);

        Apttus_Config2__ProductAttributeValue__c pav = new Apttus_Config2__ProductAttributeValue__c();
        pav.Apttus_Config2__LineItemId__c = lineItem.id;
        pav.APTS_Type_of_contract__c = 'Consumption';
        Database.insert(pav);

        Apttus_Config2__ProductAttributeValue__c pav1 = new Apttus_Config2__ProductAttributeValue__c();
        pav1.Apttus_Config2__LineItemId__c = lineItem1.id;
        pav1.APTS_Type_of_contract__c = 'Consumption';
        Database.insert(pav1);

        lineItem.Apttus_Config2__BasePriceOverride__c = 100;
        lineItem.Apttus_Config2__ChargeType__c = APTS_CPQConstants.SALES_PRICE;
        lineItem.Apttus_Config2__AttributeValueId__c = pav.id;
        Database.update(lineItem);

        lineItem1.Apttus_Config2__BasePriceOverride__c = 100;
        lineItem1.Apttus_Config2__ChargeType__c = APTS_CPQConstants.SALES_PRICE;
        lineItem1.Apttus_Config2__AttributeValueId__c = pav1.id;
        Database.update(lineItem1);

        Apttus__APTS_Related_Agreement__c oRelatedAgreement = new Apttus__APTS_Related_Agreement__c();
        oRelatedAgreement.Apttus__APTS_Contract_to__c = oAgreement.Id;
        oRelatedAgreement.Apttus__APTS_Contract_From__c = oAgreement.Id;
        Database.insert(oRelatedAgreement);

        APTS_Indexation_Executing__c oIndexationExecuting = new APTS_Indexation_Executing__c();
        oIndexationExecuting.APTS_Indexation_Contract__c = oRelatedAgreement.Apttus__APTS_Contract_From__c;
        oIndexationExecuting.Is_Indexation_Executed__c = false;
        oIndexationExecuting.APTS_Indexation_Number__c = 10;
        oIndexationExecuting.APTS_Execution_Date__c = System.today().addDays(30);
        Database.insert(oIndexationExecuting);

        Apttus_Config2__AdjustmentLineItem__c adjustlineItem = new Apttus_Config2__AdjustmentLineItem__c (Apttus_Config2__LineNumber__c = 12345,
                Apttus_Config2__LineItemId__c = lineItem.id,
                Apttus_Config2__Type__c = APTS_CPQConstants.PPR);

        Test.startTest();
        //System.assertEquals(adjustlineItem.Apttus_Config2__Type__c, APTS_CPQConstants.PPR);
        Apttus_Config2.LineItem configLineItem;

        Apttus_Config2.CallbackTester.testAdjustmentLineItemCallback
        ( oProductConfiguration.id
          , lineItem
          , new APTS_AdjustmentLineItemCallback ());
        Apttus_Config2.CallbackTester.testAdjustmentLineItemCallback
        ( oProductConfiguration.id
          , lineItem1
          , new APTS_AdjustmentLineItemCallback ());

        //}
        
        
        category.Name = 'Tea';
        Database.update(category);
        //System.assertEquals(category.Name, 'Tea');
        
        APTS_AdjustmentLineItemCallback oCallback = new APTS_AdjustmentLineItemCallback();
        oCallback.createCPQAdjustmentLineItems(lineItem);
        List<Apttus_Config2__AdjustmentLineItem__c> adjUpdatedLineItem = [select id, Apttus_Config2__Type__c from Apttus_Config2__AdjustmentLineItem__c where Apttus_Config2__LineItemId__c = :lineItem.Id];
        system.assertNotEquals(NULL, adjUpdatedLineItem);
        Test.stopTest();
    }
    @isTest static void test_AdjustmentLineItemCallback_processAdjustmentLineItemfields() {

        String standardDeal = 'Standard Deal';
        String billingPrefrence = 'JDETestPrefrence';
        String accountName = 'JDETestAccount';
        String contactNumber = '1010101011';
        String opportunityName = 'JDETestOpportunity';
        String priceListName = 'JDETest Price List';
        String prodFamilyName = 'MA';
        String prodConfigBundle = 'Bundle';
        String prodConfigOption = 'Option';
        String productService = 'PRODUCT/SERVICE';
        String billingFreqMonthly = 'Monthly';
        String billingTypeAdvanced = 'Bill In Advance';
        String priceTypeOnetime = 'One Time';
        String priceUnitPer = 'Per Unit';
        String priceUnitEach = 'Each';
        String orderTypeMachineOrder = 'Machine Order';
        String orderSubtypeTechnicalSwap = 'Technical Swap';
        String commercialSwap = 'Commercial Swap';
        String pageParamId = 'id';
        String pageParamFirstParam = 'firstParam';
        String agreementActivated = 'Activated';
        String agrrementInEffect = 'In Effect';
        List<Apttus_Config2__AdjustmentLineItem__c> adjustlineItemList = new List<Apttus_Config2__AdjustmentLineItem__c>();

        User oTestUser = APTS_TestFacade.getTestUser();

        Apttus_Config2__BillingPreference__c billPref = APTS_TestDataFactory.createBillingPrefrence(billingPrefrence);
        Database.insert(billPref, FALSE);

        Account acc = APTS_TestDataFactory.createAccount('testAccount');
        Database.insert(acc);

        Contact con = APTS_TestDataFactory.createContact(acc, 'testContact');
        con.Email = 'test@test.com';
        Database.insert(con);

        Apttus_Config2__PriceList__c pricelist = APTS_TestDataFactory.createPriceList('testPriceList');
        Database.insert(pricelist);

        Product2 prod1 = APTS_TestDataFactory.createProduct(accountName, accountName, prodFamilyName, prodConfigBundle, FALSE, TRUE);
        Database.insert(prod1);

        Product2 prod2 = APTS_TestDataFactory.createProduct(accountName, accountName, prodFamilyName, prodConfigBundle, FALSE, TRUE);
        Database.insert(prod2);

        Apttus_Config2__PriceListItem__c pli1 = APTS_TestDataFactory.createPriceListItem(pricelist.Id, prod1.Id);
        Database.insert(pli1);

        Apttus__APTS_Agreement__c oAgreement = APTS_TestDataFactory.createAgreement(con.id, pricelist.id, acc.id, 'Standard Deal');
        Database.insert(oAgreement);

        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestDataFactory.createProductConfig(oAgreement);
        Database.insert(oProductConfiguration);

        Apttus_Config2__LineItem__c lineItem = APTS_TestDataFactory.createLineItem(oProductConfiguration, pli1.Id, NULL, prod1.Id, NULL, NULL, 1, 1, 1, productService, billPref.Id, billingFreqMonthly, billingTypeAdvanced, priceTypeOnetime, priceUnitPer, priceUnitEach, 200, 10);
        Database.insert(lineItem);

        Apttus_Config2__ClassificationName__c category = APTS_TestDataFactory.createCategory();
        Database.insert(category);

        Apttus_Config2__ClassificationHierarchy__c categoryHrchy = APTS_TestDataFactory.createCategoryHierarchy(category.id, 'Cat Hierarchy');
        categoryHrchy.Apttus_Config2__Label__c = APTS_CPQConstants.LABEL_ConsignmentIngredients;
        Database.insert(categoryHrchy);

        Apttus_Config2__ProductOptionGroup__c prodOpGroup = APTS_TestDataFactory.createProductOptionGroup(categoryHrchy.id, categoryHrchy.id);
        Database.insert(prodOpGroup);

        Apttus_Config2__ProductOptionComponent__c productOptionComp = APTS_TestDataFactory.createProductOptionComponent(prodOpGroup.id);
        productOptionComp.Apttus_Config2__ComponentProductId__c = prod2.id;
        productOptionComp.Apttus_Config2__ParentProductId__c = prod2.id;
        Database.insert(productOptionComp);

        Apttus_Config2__LineItem__c lineItem1 = APTS_TestDataFactory.createLineItem(oProductConfiguration, pli1.Id, NULL, prod1.Id, NULL, NULL, 1, 1, 1, productService, billPref.Id, billingFreqMonthly, billingTypeAdvanced, priceTypeOnetime, priceUnitPer, priceUnitEach, 200, 10);
        //lineItem1.Apttus_Config2__ProductOptionId__c=productOptionComp.id;
        Database.insert(lineItem1);

        Apttus_Config2__LineItem__c lineItem2 = APTS_TestDataFactory.createLineItem(oProductConfiguration, pli1.Id, NULL, prod1.Id, NULL, NULL, 1, 1, 1, productService, billPref.Id, billingFreqMonthly, billingTypeAdvanced, priceTypeOnetime, priceUnitPer, priceUnitEach, 200, 10);
        Database.insert(lineItem2);

        oProductConfiguration.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
        Database.update(oProductConfiguration);

        oAgreement.APTS_Is_Amended_for_Indexation__c = true;
        Database.update(oAgreement);

        Apttus_Config2__ProductAttributeValue__c pav = new Apttus_Config2__ProductAttributeValue__c();
        pav.Apttus_Config2__LineItemId__c = lineItem.id;
        pav.APTS_Type_of_contract__c = 'Consumption';
        Database.insert(pav);

        Apttus_Config2__ProductAttributeValue__c pav1 = new Apttus_Config2__ProductAttributeValue__c();
        pav1.Apttus_Config2__LineItemId__c = lineItem1.id;
        pav1.APTS_Type_of_contract__c = 'Consumption';
        Database.insert(pav1);

        Apttus_Config2__ProductAttributeValue__c pav2 = new Apttus_Config2__ProductAttributeValue__c();
        pav2.Apttus_Config2__LineItemId__c = lineItem2.id;
        pav2.APTS_Type_of_contract__c = 'Consumption';
        Database.insert(pav2);

        lineItem.Apttus_Config2__BasePriceOverride__c = 100;
        lineItem.Apttus_Config2__ChargeType__c = APTS_CPQConstants.SALES_PRICE;
        lineItem.Apttus_Config2__AttributeValueId__c = pav.id;
        Database.update(lineItem);

        lineItem1.Apttus_Config2__BasePriceOverride__c = 100;
        lineItem1.Apttus_Config2__ChargeType__c = APTS_CPQConstants.SALES_PRICE;
        lineItem1.Apttus_Config2__AttributeValueId__c = pav1.id;
        Database.update(lineItem1);

        lineItem2.Apttus_Config2__BasePriceOverride__c = 100;
        lineItem2.Apttus_Config2__ChargeType__c = APTS_CPQConstants.SALES_PRICE;
        lineItem2.Apttus_Config2__AttributeValueId__c = pav1.id;
        Database.update(lineItem2);

        Apttus__APTS_Related_Agreement__c oRelatedAgreement = new Apttus__APTS_Related_Agreement__c();
        oRelatedAgreement.Apttus__APTS_Contract_to__c = oAgreement.Id;
        oRelatedAgreement.Apttus__APTS_Contract_From__c = oAgreement.Id;
        Database.insert(oRelatedAgreement);

        APTS_Indexation_Executing__c oIndexationExecuting = new APTS_Indexation_Executing__c();
        oIndexationExecuting.APTS_Indexation_Contract__c = oRelatedAgreement.Apttus__APTS_Contract_From__c;
        oIndexationExecuting.Is_Indexation_Executed__c = false;
        oIndexationExecuting.APTS_Indexation_Number__c = 10;
        oIndexationExecuting.APTS_Execution_Date__c = System.today().addDays(30);
        Database.insert(oIndexationExecuting);

        Apttus_Config2__AdjustmentLineItem__c adjustlineItem = new Apttus_Config2__AdjustmentLineItem__c (Apttus_Config2__LineNumber__c = 12345,
                Apttus_Config2__LineItemId__c = lineItem.id,
                Apttus_Config2__SubType__c = 'ZP03');
        Database.insert(adjustlineItem);
        adjustlineItemList.add(adjustlineItem);
        Apttus_Config2__AdjustmentLineItem__c adjustlineItem1 = new Apttus_Config2__AdjustmentLineItem__c (Apttus_Config2__LineNumber__c = 12345,
                Apttus_Config2__LineItemId__c = lineItem.id,
                Apttus_Config2__SubType__c  = 'ZP02');
        Database.insert(adjustlineItem1);
        adjustlineItemList.add(adjustlineItem1);
        Apttus_Config2__AdjustmentLineItem__c adjustlineItem2 = new Apttus_Config2__AdjustmentLineItem__c (Apttus_Config2__LineNumber__c = 12345,
                Apttus_Config2__LineItemId__c = lineItem.id,
                Apttus_Config2__SubType__c  = 'ZP06');
        Database.insert(adjustlineItem2);
        Apttus_Config2__AdjustmentLineItem__c adjustlineItem3 = new Apttus_Config2__AdjustmentLineItem__c (Apttus_Config2__LineNumber__c = 12345,
                Apttus_Config2__LineItemId__c = lineItem.id,
                Apttus_Config2__SubType__c  = 'ZP07');
        Database.insert(adjustlineItem3);
        Apttus_Config2__AdjustmentLineItem__c adjustlineItem4 = new Apttus_Config2__AdjustmentLineItem__c (Apttus_Config2__LineNumber__c = 12345,
                Apttus_Config2__LineItemId__c = lineItem.id,
                Apttus_Config2__SubType__c  = 'ZP04');
        Database.insert(adjustlineItem4);
        Apttus_Config2__AdjustmentLineItem__c adjustlineItem5 = new Apttus_Config2__AdjustmentLineItem__c (Apttus_Config2__LineNumber__c = 12345,
                Apttus_Config2__LineItemId__c = lineItem.id,
                Apttus_Config2__SubType__c  = 'ZP08');
        Database.insert(adjustlineItem5);
        Apttus_Config2__AdjustmentLineItem__c adjustlineItem6 = new Apttus_Config2__AdjustmentLineItem__c (Apttus_Config2__LineNumber__c = 12345,
                Apttus_Config2__LineItemId__c = lineItem.id,
                Apttus_Config2__SubType__c  = 'ZP10');
        Database.insert(adjustlineItem6);
        Apttus_Config2__AdjustmentLineItem__c adjustlineItem7 = new Apttus_Config2__AdjustmentLineItem__c (Apttus_Config2__LineNumber__c = 12345,
                Apttus_Config2__LineItemId__c = lineItem.id,
                Apttus_Config2__SubType__c  = 'ZX10');
        Database.insert(adjustlineItem7);
        Apttus_Config2__AdjustmentLineItem__c adjustlineItem8 = new Apttus_Config2__AdjustmentLineItem__c (Apttus_Config2__LineNumber__c = 12345,
                Apttus_Config2__LineItemId__c = lineItem.id,
                Apttus_Config2__SubType__c  = 'ZP15');
        Database.insert(adjustlineItem8);
        Apttus_Config2__AdjustmentLineItem__c adjustlineItem9 = new Apttus_Config2__AdjustmentLineItem__c (Apttus_Config2__LineNumber__c = 12345,
                Apttus_Config2__LineItemId__c = lineItem.id,
                Apttus_Config2__SubType__c  = 'ZP11');
        Database.insert(adjustlineItem9);
        Apttus_Config2__AdjustmentLineItem__c adjustlineItem10 = new Apttus_Config2__AdjustmentLineItem__c (Apttus_Config2__LineNumber__c = 12345,
                Apttus_Config2__LineItemId__c = lineItem.id,
                Apttus_Config2__SubType__c  = 'ZP13');
        Database.insert(adjustlineItem10);
        Apttus_Config2__AdjustmentLineItem__c adjustlineItem11 = new Apttus_Config2__AdjustmentLineItem__c (Apttus_Config2__LineNumber__c = 12345,
                Apttus_Config2__LineItemId__c = lineItem.id,
                Apttus_Config2__SubType__c  = 'ZP12');
        Database.insert(adjustlineItem11);
        Apttus_Config2__AdjustmentLineItem__c adjustlineItem12 = new Apttus_Config2__AdjustmentLineItem__c (Apttus_Config2__LineNumber__c = 12345,
                Apttus_Config2__LineItemId__c = lineItem.id,
                Apttus_Config2__SubType__c  = 'YOCI');
        Database.insert(adjustlineItem12);
        Apttus_Config2__AdjustmentLineItem__c adjustlineItem13 = new Apttus_Config2__AdjustmentLineItem__c (Apttus_Config2__LineNumber__c = 12345,
                Apttus_Config2__LineItemId__c = lineItem.id,
                Apttus_Config2__SubType__c  = 'YOFT');
        Database.insert(adjustlineItem13);
        adjustlineItemList.add(adjustlineItem1);
        adjustlineItemList.add(adjustlineItem2);
        adjustlineItemList.add(adjustlineItem3);
        adjustlineItemList.add(adjustlineItem4);
        adjustlineItemList.add(adjustlineItem5);
        adjustlineItemList.add(adjustlineItem6);
        adjustlineItemList.add(adjustlineItem7);
        adjustlineItemList.add(adjustlineItem8);
        adjustlineItemList.add(adjustlineItem9);
        adjustlineItemList.add(adjustlineItem10);
        adjustlineItemList.add(adjustlineItem11);
        adjustlineItemList.add(adjustlineItem12);
        adjustlineItemList.add(adjustlineItem13);
        System.assert([Select id FROM Apttus_Config2__AdjustmentLineItem__c].size() > 0);
        Test.startTest();
        APTS_AdjustmentLineItemCallback oCallback = new APTS_AdjustmentLineItemCallback();
        oCallback.processAdjustmentLineItemfields(adjustlineItemList);
        oCallback.processAdjustmentLineItemfieldsnew(adjustlineItemList);
        Apttus_Config2.LineItem configLineItem;


        //}

        Test.stopTest();
    }

    @isTest static void test_StandardReturnAdjustment() {
        User oTestUser = APTS_TestFacade.getTestUser();

        Account oAccount = APTS_TestFacade.getAccount();
        System.assert([Select id FROM Apttus_Config2__Order__c].size() > 0);
        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder();
        List<Apttus_Config2__AssetLineItem__c> listAsset = APTS_TestFacade.getAssetLineItem();
        List<Apttus_Config2__LineItem__c> listAmendedLineItems = new List<Apttus_Config2__LineItem__c>();

        Apttus_Config2__Order__c oReturnOrder = oOrder.clone(FALSE, FALSE, FALSE, FALSE);
        oReturnOrder.APTS_Order_Type__c = 'Standard Order';
        oReturnOrder.APTS_Order_Sub_Type__c = 'Standard Return';
        oReturnOrder.Apttus_Config2__Status__c = 'Draft';
        oReturnOrder.APTS_Status__c = 'Draft';
        insert oReturnOrder;

        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestDataFactory.createProductConfig(oReturnOrder);
        oProductConfiguration.APTS_Flow__c = 'NGSTANDARDORDER';
        oProductConfiguration.Apttus_Config2__Status__c = 'Finalized';
        insert oProductConfiguration;

        if (listAsset != NULL) {
            Apttus_Config2_AssetAdjustItem__c oAssetAdj = new Apttus_Config2_AssetAdjustItem__c();
            for (Apttus_Config2__AssetLineItem__c oAsset : listAsset) {
                oAssetAdj.Apttus_Config2_AssetLineItemId__c = oAsset.Id;
                oAssetAdj.Apttus_Config2_AssetAdjustAmount__c = 10;
                oAssetAdj.Apttus_Config2_AssetAdjustType__c = '% Discount';
                break;
            }
            insert oAssetAdj;


            Integer cnt = 0;
            for (Apttus_Config2__LineItem__c oLineItem : APTS_TestFacade.getLineItemList()) {
                oLineItem.Apttus_Config2__AssetLineItemId__c = listAsset[0].Id;
                oLineItem.Apttus_Config2__LineStatus__c = 'Amended';
                oLineItem.Apttus_Config2__ConfigurationId__c = oProductConfiguration.Id;
                oLineItem.Id = NULL;
                oLineItem.Apttus_Config2__ItemSequence__c = cnt;
                oLineItem.Apttus_Config2__LineNumber__c = cnt;
                listAmendedLineItems.add(oLineItem);
                cnt++;
            }

            insert listAmendedLineItems;
        }

        test.startTest();

        System.runAs(oTestUser) {
            Apttus_Config2.CallbackTester.testAdjustmentLineItemCallback(oProductConfiguration.id, listAmendedLineItems[0], new APTS_AdjustmentLineItemCallback ());

        }

        test.stopTest();
    }

    @isTest static void test_AssetAdjustment() {
        User oTestUser = APTS_TestFacade.getTestUser();

        List<Apttus_Config2_AssetAdjustItem__c> listAssetAdjustments = new List<Apttus_Config2_AssetAdjustItem__c>();
        List<Apttus_Config2__AssetLineItem__c> listAsset = APTS_TestFacade.getAssetLineItem();

        System.assertNotEquals(NULL, listAsset);


        for (Apttus_Config2__AssetLineItem__c oAsset : listAsset) {
            Apttus_Config2_AssetAdjustItem__c oAssetAdj = new Apttus_Config2_AssetAdjustItem__c();
            oAssetAdj.Apttus_Config2_AssetLineItemId__c = oAsset.Id;
            oAssetAdj.Apttus_Config2_AssetAdjustAmount__c = 10;
            oAssetAdj.Apttus_Config2_AssetAdjustType__c = '% Discount';
            listAssetAdjustments.add(oAssetAdj);
            break;
        }


        Apttus_Config2__LineItem__c oLineItem = APTS_TestFacade.getLineItemList()[0];
        oLineItem.Apttus_Config2__AssetLineItemId__c = listAsset[0].Id;
        oLineItem.Apttus_Config2__LineStatus__c = 'Amended';
        oLineItem.Id = NULL;
        oLineItem.Apttus_Config2__ItemSequence__c = 1;
        oLineItem.Apttus_Config2__LineNumber__c = 1;


        test.startTest();

        System.runAs(oTestUser) {

            List<Apttus_Config2__AdjustmentLineItem__c> listAdjustments = APTS_AdjustmentLineItemCallback.getABOAdjustmentLineItems(listAsset[0].Id, oLineItem, listAssetAdjustments);
            System.assertNotEquals(NULL, listAdjustments);
            System.assertNotEquals(NULL, listAdjustments.isEmpty());

        }

        test.stopTest();
    }


    @isTest static void test_CERAdjustment() {
        User oTestUser = APTS_TestFacade.getTestUser();

        Apttus_Config2__LineItem__c oLineItem = APTS_TestFacade.getLineItemList()[0];

        List<APTS_Contract_Entitlement_Repository__c> repoList = new List<APTS_Contract_Entitlement_Repository__c>();
        APTS_Contract_Entitlement_Repository__c repo1 = new APTS_Contract_Entitlement_Repository__c();
        repo1.APTS_Adjustment_Type__c = 'PPR';
        repo1.APTS_Agreement_Type__c = 'Standard Deal';
        repo1.APTS_Sub_Type__c = 'ZP03';
        repo1.APTS_Adjustment_Value__c = 20.0;
        repo1.APTS_Exclusion_Exception_Available__c = false;
        repo1.APTS_Is_Pending__c = false;
        repo1.APTS_Max_Volume__c = false;
        repo1.APTS_Product__c = oLineItem.Apttus_Config2__ProductId__c;
        repoList.add(repo1);

        Map<Id, List<APTS_Contract_Entitlement_Repository__c>> mapCER = new Map<Id, List<APTS_Contract_Entitlement_Repository__c>>();
        mapCER.put(oLineItem.Apttus_Config2__ProductId__c, repoList);

        test.startTest();

        System.runAs(oTestUser) {

            Map<String, Apttus_Config2__AdjustmentLineItem__c> adjustments = APTS_AdjustmentLineItemCallback.getCERAdjustmentLineItems('Order', oLineItem, mapCER);
            System.assertNotEquals(NULL, adjustments);
            System.assertNotEquals(NULL, adjustments.isEmpty());

            Apttus_Config2__AdjustmentLineItem__c adjst = adjustments.values()[0];
            adjst.Apttus_Config2__SubType__c = 'ZP06';
            APTS_AdjustmentLineItemCallback.setAdjustmentBucket(adjst);

            List<String> adjAppliesTo = new List<String> {'Bucket 1'};
            Map<String, Apttus_Config2__AdjustmentLineItem__c> adjustmentsTmp = APTS_AdjustmentLineItemCallback.setAdjustmentAppliesTo(oLineItem.Id, adjustments.values(), adjAppliesTo);
            System.assertNotEquals(NULL, adjustmentsTmp);

            adjst = adjustments.values()[0];

            adjst.Apttus_Config2__SubType__c = 'ZP02';
            APTS_AdjustmentLineItemCallback.setAdjustmentBucket(adjst);

            adjAppliesTo = new List<String> {'Bucket 1', 'Bucket 2'};
            adjustmentsTmp = APTS_AdjustmentLineItemCallback.setAdjustmentAppliesTo(oLineItem.Id, adjustments.values(), adjAppliesTo);
            System.assertNotEquals(NULL, adjustmentsTmp);

            adjst.Apttus_Config2__SubType__c = 'ZP07';
            APTS_AdjustmentLineItemCallback.setAdjustmentBucket(adjst);

            adjAppliesTo = new List<String> {'Bucket 1', 'Bucket 2','Bucket 3'};
            adjustmentsTmp = APTS_AdjustmentLineItemCallback.setAdjustmentAppliesTo(oLineItem.Id, adjustments.values(), adjAppliesTo);
            System.assertNotEquals(NULL, adjustmentsTmp);
            adjst.Apttus_Config2__SubType__c = 'ZP04';
            APTS_AdjustmentLineItemCallback.setAdjustmentBucket(adjst);

            adjustmentsTmp = APTS_AdjustmentLineItemCallback.setAdjustmentAppliesTo(oLineItem.Id, adjustments.values(), adjAppliesTo);
            System.assertNotEquals(NULL, adjustmentsTmp);

            adjst.Apttus_Config2__SubType__c = 'ZP08';
            APTS_AdjustmentLineItemCallback.setAdjustmentBucket(adjst);

            adjst.Apttus_Config2__SubType__c = 'ZP10';
            APTS_AdjustmentLineItemCallback.setAdjustmentBucket(adjst);

            adjAppliesTo = new List<String> {'Bucket 1', 'Bucket 2', 'Bucket 3','Bucket 4'};
            adjustmentsTmp = APTS_AdjustmentLineItemCallback.setAdjustmentAppliesTo(oLineItem.Id, adjustments.values(), adjAppliesTo);
            System.assertNotEquals(NULL, adjustmentsTmp);

            adjst.Apttus_Config2__SubType__c = 'ZX10';
            APTS_AdjustmentLineItemCallback.setAdjustmentBucket(adjst);

            adjst.Apttus_Config2__SubType__c = 'ZP15';
            APTS_AdjustmentLineItemCallback.setAdjustmentBucket(adjst);

            adjAppliesTo = new List<String> {'Bucket 1', 'Bucket 2', 'Bucket 3', 'Bucket 4','Bucket 5'};
            adjustmentsTmp = APTS_AdjustmentLineItemCallback.setAdjustmentAppliesTo(oLineItem.Id, adjustments.values(), adjAppliesTo);
            System.assertNotEquals(NULL, adjustmentsTmp);

            adjst.Apttus_Config2__SubType__c = 'ZP11';
            APTS_AdjustmentLineItemCallback.setAdjustmentBucket(adjst);

            adjst.Apttus_Config2__SubType__c = 'ZP13';
            APTS_AdjustmentLineItemCallback.setAdjustmentBucket(adjst);

            adjAppliesTo = new List<String> {'Bucket 1', 'Bucket 2', 'Bucket 3', 'Bucket 4', 'Bucket 5','Bucket 6'};
            adjustmentsTmp = APTS_AdjustmentLineItemCallback.setAdjustmentAppliesTo(oLineItem.Id, adjustments.values(), adjAppliesTo);
            System.assertNotEquals(NULL, adjustmentsTmp);

            adjst.Apttus_Config2__SubType__c = 'ZP12';
            APTS_AdjustmentLineItemCallback.setAdjustmentBucket(adjst);

            adjst.Apttus_Config2__SubType__c = 'YOCI';
            APTS_AdjustmentLineItemCallback.setAdjustmentBucket(adjst);

            adjst.Apttus_Config2__SubType__c = 'YOFT';
            APTS_AdjustmentLineItemCallback.setAdjustmentBucket(adjst);

            adjAppliesTo = new List<String> {'Bucket 1', 'Bucket 2', 'Bucket 3', 'Bucket 4', 'Bucket 5','Bucket 6'};
            adjustmentsTmp = APTS_AdjustmentLineItemCallback.setAdjustmentAppliesTo(oLineItem.Id, adjustments.values(), adjAppliesTo);
            System.assertNotEquals(NULL, adjustmentsTmp);

            APTS_AdjustmentLineItemCallback.setIsDisabled(FALSE);
        }

        test.stopTest();
    }


    @isTest static void test_DigitalAdjustment() {
        User oTestUser = APTS_TestFacade.getTestUser();

        Apttus_Config2__LineItem__c oLineItem = APTS_TestFacade.getLineItemList()[0];

        List<APTS_DOEPIReqWrapper.EPIAdjustmentLI> listEPIAdjustments = new List<APTS_DOEPIReqWrapper.EPIAdjustmentLI>();
        APTS_DOEPIReqWrapper.EPIAdjustmentLI oAdjust = new APTS_DOEPIReqWrapper.EPIAdjustmentLI();
        oAdjust.IncentiveAmount = 10;
        oAdjust.SubType = 'ZP08';
        listEPIAdjustments.add(oAdjust);

        test.startTest();

        System.runAs(oTestUser) {

            List<Apttus_Config2__AdjustmentLineItem__c> adjustments = APTS_AdjustmentLineItemCallback.getDigitalAdjustmentLineItems('Digital', 'stype', 'sAdjType',  oLineItem, null, listEPIAdjustments);
            System.assertNotEquals(NULL, adjustments);
            System.assertNotEquals(NULL, adjustments.isEmpty());

        }

        test.stopTest();
    }

}