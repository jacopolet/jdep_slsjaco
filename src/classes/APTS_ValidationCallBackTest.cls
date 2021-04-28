//v101 15/06/2019 Akanksha: Added data for OM part coverage
@isTest
private class APTS_ValidationCallBackTest {
    private static final String BILLING_PREFRENCE = 'JDETestPrefrence';
    private static final String ACCOUNT_NAME = 'JDETestAccount';
    private static final String CONTACT_NUMBER = '1010101011';
    private static final String OPPORTUNITY_NAME = 'JDETestOpportunity';
    private static final String PRICELIST_NAME = 'JDETest Price List';
    private static final String PROD_CONFIG_STANDALONE = 'Standalone';
    private static final String PRICE_TYPE_ONETIME = 'One Time';
    private static final String PRICE_UNIT_PER = 'Per Unit';
    private static final String PRICE_UNIT_EACH = 'Each';
    private static final String BILLING_FREQ_MONTHLY = 'Monthly';
    private static final String BILLING_TYPE_ADVANCED = 'Bill In Advance';
    private static final String BLANK_STR = '';
    private static final String VALIDATIONCALLBACK_NAME = 'ValidationCallback';
    private static final String SYSTEMPROPERTIES_NAME = 'SystemProperties';
    private static final String PRODUCT_SERVICE = 'PRODUCT/SERVICE';
    private static final String FINALIZED = 'Finalized';
    private static final String COMPLETED = 'Completed';
    private static final String PENDING = 'Pending';
    private static final String CUSTOM_FIELD = 'APTS_ATP_Cleared__c,' + 'APTS_Expected_Delivery_Quantity__c,' + 'APTS_Requested_Delivery_Date__c,' + 'APTS_is_Tax_and_VAT_calculated__c';
    private static final String NGDEFAULT = System.Label.APTS_NGDefault;
    private static final String NGSTANDARD_ORDER = System.Label.APTS_NGStandardOrder;
    private static final String NGMACHINE_ORDER = System.Label.APTS_NGMachineOrder;

    @testSetup static void setupTestData() {
        Apttus_Config2__ConfigLineItemCustomFields__c ocustsetting = new Apttus_Config2__ConfigLineItemCustomFields__c();
        ocustsetting.Name = APTS_ValidationCallBackTest.VALIDATIONCALLBACK_NAME;
        ocustsetting.Apttus_Config2__CustomFieldNames2__c = CUSTOM_FIELD + ',APTS_ATP_Cleared__c,Apttus_Config2__Quantity__c,APTS_Expected_Delivery_Quantity__c,Apttus_Config2__PricingStatus__c';
        ocustsetting.Apttus_Config2__CustomFieldNames3__c = CUSTOM_FIELD + ',Apttus_Config2__ConfigurationId__r.Apttus_Config2__BusinessObjectType__c,Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.RecordType.Name,APTS_Unlimited_Machine_Ordering__c';
        ocustsetting.Apttus_Config2__CustomFieldNames4__c = CUSTOM_FIELD + ',Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__c,APTS_Agreement__c,APTS_Business_type__c,Apttus_Config2__Description__c';
        ocustsetting.Apttus_Config2__CustomFieldNames__c = 'Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Type__c,Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type,Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Fulfill_From_To_Van__c';

        Database.insert(ocustsetting, FALSE);

        Apttus_Config2__ConfigLineItemCustomFields__c ocustsetting1 = new Apttus_Config2__ConfigLineItemCustomFields__c();
        ocustsetting1.Name = 'Tax/Vat Summary';
        ocustsetting1.Apttus_Config2__CustomFieldNames__c = 'APTS_Additional_charges__c, APTS_Serial_Number2__c,Apttus_Config2__ConfigurationId__r.Apttus_Config2__BillToAccountId__c,Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c';
        ocustsetting1.Apttus_Config2__CustomFieldNames2__c = 'APTS_Tax__c,APTS_VAT__c,APTS_Net_Price_Inc_taxes__c,Apttus_Config2__ProductId__r.APTS_Category_Adjustments_Product__c,Apttus_Config2__AssetLineItemId__r.Apttus_Config2__OriginalStartDate__c';
        ocustsetting1.Apttus_Config2__CustomFieldNames3__c = 'APTS_is_Tax_and_VAT_calculated__c,APTS_Order_LSP_Detail__c,Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c';
        ocustsetting1.Apttus_Config2__CustomFieldNames4__c = 'APTS_VAT_classifier_0__c,APTS_VAT_classifier_1__c,APTS_VAT_classifier_2__c,APTS_VAT_classifier_3__c,APTS_VAT_classifier_4__c,APTS_VAT_classifier_5__c,APTS_VAT_classifier_6__c';
        ocustsetting1.Apttus_Config2__CustomFieldNames5__c = 'Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Exclude_TAX__c,Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Exclude_VAT__c';
        Database.insert(ocustsetting1, FALSE);

        Apttus_Config2__ConfigSystemProperties__c custsetting = new Apttus_Config2__ConfigSystemProperties__c();
        custsetting.Name = APTS_ValidationCallBackTest.SYSTEMPROPERTIES_NAME;
        custsetting.Apttus_Config2__CustomPricingFields__c = APTS_ValidationCallBackTest.CUSTOM_FIELD + ', APTS_Requested_Delivery_Date__c';
        Database.insert(custsetting, FALSE);

        // create billingprefrence
        Apttus_Config2__BillingPreference__c billPref = APTS_TestDataFactory.createBillingPrefrence(APTS_ValidationCallBackTest.BILLING_PREFRENCE);
        Database.insert(billPref, FALSE);

        // create account
        Account oAccount = APTS_TestDataFactory.createAccount(APTS_ValidationCallBackTest.ACCOUNT_NAME);
        Database.insert(oAccount, FALSE);

        // create contact
        Contact oContact = APTS_TestDataFactory.createContact(oAccount, APTS_ValidationCallBackTest.CONTACT_NUMBER);
        Database.insert(oContact, FALSE);

        // create opportunity
        opportunity opportunityObj = APTS_TestDataFactory.createOpportunity(APTS_ValidationCallBackTest.OPPORTUNITY_NAME, oAccount.Id);
        Database.insert(opportunityObj, FALSE);

        //create price list
        Apttus_Config2__PriceList__c pricelist = APTS_TestDataFactory.createPriceList(APTS_ValidationCallBackTest.PRICELIST_NAME);
        Database.insert(pricelist, FALSE);

        //Create Products
        List<Product2> prodList = new List<Product2>();
        Product2 prod1 = APTS_TestDataFactory.createProduct(APTS_ValidationCallBackTest.ACCOUNT_NAME, APTS_ValidationCallBackTest.ACCOUNT_NAME, APTS_ValidationCallBackTest.ACCOUNT_NAME, APTS_ValidationCallBackTest.PROD_CONFIG_STANDALONE, FALSE, FALSE);
        Product2 prod2 = APTS_TestDataFactory.createProduct(APTS_ValidationCallBackTest.ACCOUNT_NAME, APTS_ValidationCallBackTest.ACCOUNT_NAME, APTS_ValidationCallBackTest.ACCOUNT_NAME, APTS_ValidationCallBackTest.PROD_CONFIG_STANDALONE, FALSE, FALSE);
        prod1.APTS_Category_Adjustments_Product__c = false;
        prod2.APTS_Category_Adjustments_Product__c = false;
        prodList.add(prod1);
        prodList.add(prod2);
        Database.insert(prodList, FALSE);

        //Create Price List Items
        List<Apttus_Config2__PriceListItem__c> pliList = new List<Apttus_Config2__PriceListItem__c>();
        //Apttus_Config2__PriceListItem__c pli1 = APTS_TestDataFactory.createPriceListItem(priceList.Id,prodList[0].Id,APTS_ValidationCallBackTest.PROD_CONFIG_STANDALONE,APTS_ValidationCallBackTest.PRICE_TYPE_ONETIME,APTS_ValidationCallBackTest.PRICE_UNIT_PER, 20.0, APTS_ValidationCallBackTest.BLANK_STR,APTS_ValidationCallBackTest.PRICE_UNIT_EACH,APTS_ValidationCallBackTest.BILLING_FREQ_MONTHLY,APTS_ValidationCallBackTest.BILLING_TYPE_ADVANCED);
        //Apttus_Config2__PriceListItem__c pli2 = APTS_TestDataFactory.createPriceListItem(priceList.Id,prodList[1].Id,APTS_ValidationCallBackTest.PROD_CONFIG_STANDALONE,APTS_ValidationCallBackTest.PRICE_TYPE_ONETIME,APTS_ValidationCallBackTest.PRICE_UNIT_PER, 30.0, APTS_ValidationCallBackTest.BLANK_STR,APTS_ValidationCallBackTest.PRICE_UNIT_EACH,APTS_ValidationCallBackTest.BILLING_FREQ_MONTHLY,APTS_ValidationCallBackTest.BILLING_TYPE_ADVANCED);
        Apttus_Config2__PriceListItem__c pli1 = APTS_TestDataFactory.createPriceListItem(priceList.Id, prodList[0].Id);
        Apttus_Config2__PriceListItem__c pli2 = APTS_TestDataFactory.createPriceListItem(priceList.Id, prodList[1].Id);

        pliList.add(pli1);
        pliList.add(pli2);
        Database.insert(pliList, FALSE);
        
       /* Apttus_Config2__Order__c order = APTS_TestDataFactory.createOrder(oAccount.Id, pricelist.Id, oContact.Id);
        order.APTS_Requested_Delivery_Date__c = System.today()
        order.APTS_Order_Sub_Type__c = 'De-Installation';
        Database.insert(order, FALSE);*/
        
        Apttus__APTS_Agreement__c agrmt = APTS_TestDataFactory.createAgreement(oContact.id, priceList.id, oAccount.id, 'Standard Deal');

        Apttus_Config2__ProductConfiguration__c config = APTS_TestDataFactory.createProductConfig(agrmt);
        config.APTS_Flow__c = NGDEFAULT;
        //config.Apttus_Config2__OrderId__c = order.id;
        config.Apttus_Config2__Status__c = APTS_ValidationCallBackTest.FINALIZED;
        Database.insert(config, FALSE);

        List<Apttus_Config2__LineItem__c> listLineItems = new List<Apttus_Config2__LineItem__c>();
        Apttus_Config2__LineItem__c lineItem1 = APTS_TestDataFactory.createLineItem(config, pli1.Id, NULL, prod1.Id, NULL, NULL, 1, 1, 1, APTS_ValidationCallBackTest.PRODUCT_SERVICE, billPref.Id, APTS_ValidationCallBackTest.BILLING_FREQ_MONTHLY, APTS_ValidationCallBackTest.BILLING_TYPE_ADVANCED, APTS_ValidationCallBackTest.PRICE_TYPE_ONETIME, APTS_ValidationCallBackTest.PRICE_UNIT_PER, APTS_ValidationCallBackTest.PRICE_UNIT_EACH, 100, 2);
        lineItem1.Apttus_Config2__PricingStatus__c = APTS_ValidationCallBackTest.COMPLETED;
        lineItem1.APTS_Requested_Delivery_Date__c = System.today();
        lineitem1.Apttus_Config2__HasOptions__c = false;
        listLineItems.add(lineItem1);

        Apttus_Config2__LineItem__c lineItem2 = APTS_TestDataFactory.createLineItem(config, pli2.Id, NULL, prod2.Id, NULL, NULL, 2, 2, 2, APTS_ValidationCallBackTest.PRODUCT_SERVICE, billPref.Id, APTS_ValidationCallBackTest.BILLING_FREQ_MONTHLY, APTS_ValidationCallBackTest.BILLING_TYPE_ADVANCED, APTS_ValidationCallBackTest.PRICE_TYPE_ONETIME, APTS_ValidationCallBackTest.PRICE_UNIT_PER, APTS_ValidationCallBackTest.PRICE_UNIT_EACH, 300, 1);
        lineItem2.Apttus_Config2__PricingStatus__c = APTS_ValidationCallBackTest.COMPLETED;
        lineItem2.APTS_Requested_Delivery_Date__c = System.today();
        lineitem2.Apttus_Config2__HasOptions__c = false;
        listLineItems.add(lineItem2);
        //v101  << ++
        /*Apttus_Config2__LineItem__c lineItem3 = APTS_TestDataFactory.createLineItem(config, pli2.Id, NULL, prod2.Id, NULL, NULL, 2, 2, 2, APTS_ValidationCallBackTest.PRODUCT_SERVICE, billPref.Id, APTS_ValidationCallBackTest.BILLING_FREQ_MONTHLY, APTS_ValidationCallBackTest.BILLING_TYPE_ADVANCED, APTS_ValidationCallBackTest.PRICE_TYPE_ONETIME, APTS_ValidationCallBackTest.PRICE_UNIT_PER, APTS_ValidationCallBackTest.PRICE_UNIT_EACH, 300, 1);
        lineItem3.Apttus_Config2__PricingStatus__c = APTS_ValidationCallBackTest.COMPLETED;
        lineItem3.Apttus_Config2__StartDate__c = System.today();
        lineitem3.Apttus_Config2__EndDate__c = System.today().addDays(-10);
        lineitem3.Apttus_Config2__LineStatus__c = 'New';
        lineItem3.APTS_Requested_Delivery_Date__c = System.today();
        lineitem3.Apttus_Config2__HasOptions__c = true;
        lineitem3.Apttus_Config2__IsPrimaryLine__c =true;
        listLineItems.add(lineItem3);

        Apttus_Config2__LineItem__c lineItem4 = APTS_TestDataFactory.createLineItem(config, pli2.Id, NULL, prod2.Id, NULL, NULL, 2, 2, 2, APTS_ValidationCallBackTest.PRODUCT_SERVICE, billPref.Id, APTS_ValidationCallBackTest.BILLING_FREQ_MONTHLY, APTS_ValidationCallBackTest.BILLING_TYPE_ADVANCED, APTS_ValidationCallBackTest.PRICE_TYPE_ONETIME, APTS_ValidationCallBackTest.PRICE_UNIT_PER, APTS_ValidationCallBackTest.PRICE_UNIT_EACH, 300, 1);
        lineItem4.Apttus_Config2__PricingStatus__c = APTS_ValidationCallBackTest.COMPLETED;
        lineItem4.APTS_Requested_Delivery_Date__c = System.today();
        lineitem4.Apttus_Config2__HasOptions__c = false;
        lineitem4.Apttus_Config2__LineStatus__c = 'Amended';
        listLineItems.add(lineItem4);*/
        //v101 ++ >>    

        Database.insert(listLineItems, FALSE);

        //adding Adjustments
        List<Apttus_Config2__AdjustmentLineItem__c> adjustlineItemlist = new List<Apttus_Config2__AdjustmentLineItem__c>();
        Apttus_Config2__AdjustmentLineItem__c adjustlineItem1 = new Apttus_Config2__AdjustmentLineItem__c(
            Apttus_Config2__LineNumber__c = 12345,
            Apttus_Config2__LineItemId__c = lineItem1.id,
            Apttus_Config2__Type__c = 'PPR',
            Apttus_Config2__AdjustmentAmount__c = 101, Apttus_Config2__AdjustmentType__c = '% Discount');
        adjustlineItemlist.add(adjustlineItem1);

        Apttus_Config2__AdjustmentLineItem__c adjustlineItem2 = new Apttus_Config2__AdjustmentLineItem__c(
            Apttus_Config2__LineNumber__c = 12345,
            Apttus_Config2__LineItemId__c = lineItem2.id,
            Apttus_Config2__Type__c = 'PPR',
            Apttus_Config2__AdjustmentAmount__c = 999999999, Apttus_Config2__AdjustmentType__c = 'Discount Amount');
        adjustlineItemlist.add(adjustlineItem2);
        Database.insert(adjustlineItemlist);
    }

    static testMethod void testMethod1() {
        Apttus_Config2__ProductConfiguration__c pConfig = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];
        List<Apttus_Config2__LineItem__c> lineItems = [SELECT Id, APTS_ATP_Cleared__c, APTS_Expected_Delivery_Quantity__c,
                                          APTS_is_Tax_and_VAT_calculated__c, Apttus_Config2__Quantity__c, Apttus_Config2__PricingStatus__c, Apttus_Config2__ExtendedPrice__c,Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c FROM Apttus_Config2__LineItem__c];
        Apttus_Config2.CallbackTester.testValidationCallback(pConfig.Id, lineItems, null, new APTS_ValidationCallBack());
    }

    static testMethod void testMethod2() {
        Apttus_Config2__ProductConfiguration__c pConfig = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];
        List<Apttus_Config2__LineItem__c> lineItems = [SELECT Id, APTS_ATP_Cleared__c, APTS_Expected_Delivery_Quantity__c,
                                          Apttus_Config2__Quantity__c, Apttus_Config2__PricingStatus__c, Apttus_Config2__ExtendedPrice__c,Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c FROM Apttus_Config2__LineItem__c];
        for (Apttus_Config2__LineItem__c oLineItem : lineItems) {
            oLineItem.APTS_Expected_Delivery_Quantity__c = 0;
            oLineItem.APTS_ATP_Cleared__c = true;
        }
        update lineItems;
        Apttus_Config2.CallbackTester.testValidationCallback(pConfig.Id, lineItems, null, new APTS_ValidationCallBack());
    }

    static testMethod void testMethod3() {
        Apttus_Config2__ProductConfiguration__c pConfig = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];
        List<Apttus_Config2__LineItem__c> lineItems = [SELECT Id, APTS_ATP_Cleared__c, APTS_Expected_Delivery_Quantity__c,
                                          Apttus_Config2__Quantity__c, Apttus_Config2__PricingStatus__c, Apttus_Config2__ExtendedPrice__c,Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c FROM Apttus_Config2__LineItem__c];
        for (Apttus_Config2__LineItem__c oLineItem : lineItems) {
            oLineItem.APTS_Expected_Delivery_Quantity__c = 1;
            oLineItem.APTS_ATP_Cleared__c = true;
            oLineItem.APTS_Requested_Delivery_Date__c = System.today().addDays(4);
        }
        update lineItems;
        Apttus_Config2.CallbackTester.testValidationCallback(pConfig.Id, lineItems, null, new APTS_ValidationCallBack());
    }

    static testMethod void testMethod4() {
        Apttus_Config2__ProductConfiguration__c pConfig = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];
        List<Apttus_Config2__LineItem__c> lineItems = [SELECT Id, APTS_ATP_Cleared__c, APTS_Expected_Delivery_Quantity__c,
                                          Apttus_Config2__Quantity__c, Apttus_Config2__PricingStatus__c, Apttus_Config2__ExtendedPrice__c,Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c FROM Apttus_Config2__LineItem__c];
        for (Apttus_Config2__LineItem__c oLineItem : lineItems) {
            oLineItem.Apttus_Config2__PricingStatus__c = APTS_ValidationCallBackTest.PENDING;
            break;
        }
        update lineItems;
        Apttus_Config2.CallbackTester.testValidationCallback(pConfig.Id, lineItems, null, new APTS_ValidationCallBack());
    }

    static testMethod void testMethod5() {
        Apttus_Config2__ProductConfiguration__c pConfig = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];
        List<Apttus_Config2__LineItem__c> lineItems = [SELECT Id, APTS_ATP_Cleared__c, APTS_Expected_Delivery_Quantity__c,
                                          Apttus_Config2__Quantity__c, Apttus_Config2__PricingStatus__c, Apttus_Config2__ExtendedPrice__c,Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c FROM Apttus_Config2__LineItem__c];

        for (Apttus_Config2__LineItem__c oLineItem : lineItems) {
            oLineItem.APTS_Expected_Delivery_Quantity__c = 0;
            oLineItem.APTS_ATP_Cleared__c = true;
        }
        update lineItems;

        Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem = new Apttus_Config2__AdjustmentLineItem__c();
        adjustmentLineItem.Apttus_Config2__AdjustmentAmount__c = 50;
        adjustmentLineItem.Apttus_Config2__AdjustmentAppliesTo__c = 'Previous Price';
        adjustmentLineItem.Apttus_Config2__AdjustmentType__c = '% Discount';
        adjustmentLineItem.Apttus_Config2__LineItemId__c = lineItems.get(0).Id;
        adjustmentLineItem.Apttus_Config2__LineNumber__c = 1;
        adjustmentLineItem.Apttus_Config2__LineType__c = 'Manual';
        adjustmentLineItem.Apttus_Config2__Type__c = 'TPR';
        adjustmentLineItem.Apttus_Config2__SubType__c = 'Trade';
        insert adjustmentLineItem;

        List<Apttus_Config2__AdjustmentLineItem__c> ali = [SELECT Id FROM Apttus_Config2__AdjustmentLineItem__c];
        System.assertEquals(FALSE, ali.isEmpty());

        Apttus_Config2.CallbackTester.testValidationCallback(pConfig.Id, lineItems, null, new APTS_ValidationCallBack());
    }

    static testMethod void testMethod6() {
        Apttus_Config2__ProductConfiguration__c pConfig = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];
        List<Apttus_Config2__LineItem__c> lineItems =
            [SELECT Id, APTS_ATP_Cleared__c, APTS_Expected_Delivery_Quantity__c, Apttus_Config2__Quantity__c,
             Apttus_Config2__PricingStatus__c, Apttus_Config2__ExtendedPrice__c,Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c FROM Apttus_Config2__LineItem__c];

        for (Apttus_Config2__LineItem__c oLineItem : lineItems) {
            oLineItem.APTS_Expected_Delivery_Quantity__c = 0;
            oLineItem.APTS_ATP_Cleared__c = true;
            oLineItem.Apttus_Config2__ExtendedPrice__c = 90;
        }
        update lineItems;

        // Line items
        /* Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem = new Apttus_Config2__AdjustmentLineItem__c();
         adjustmentLineItem.Apttus_Config2__AdjustmentAmount__c = 120;
         adjustmentLineItem.Apttus_Config2__AdjustmentAppliesTo__c = 'Previous Price';
         adjustmentLineItem.Apttus_Config2__AdjustmentType__c = '% Discount';

         adjustmentLineItem.Apttus_Config2__LineItemId__c = lineItems.get(0).Id;
         adjustmentLineItem.Apttus_Config2__LineNumber__c = 1;
         adjustmentLineItem.Apttus_Config2__LineType__c = 'Manual';
         adjustmentLineItem.Apttus_Config2__Type__c = 'TPR';
         adjustmentLineItem.Apttus_Config2__SubType__c = 'Trade';
         insert adjustmentLineItem;*/


        Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem1 = new Apttus_Config2__AdjustmentLineItem__c();
        adjustmentLineItem1.Apttus_Config2__AdjustmentAmount__c = 99;
        adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Previous Price';
        adjustmentLineItem1.Apttus_Config2__AdjustmentType__c = 'Discount Amount';

        adjustmentLineItem1.Apttus_Config2__LineItemId__c = lineItems.get(0).Id;
        adjustmentLineItem1.Apttus_Config2__LineNumber__c = 1;
        adjustmentLineItem1.Apttus_Config2__LineType__c = 'Manual';
        adjustmentLineItem1.Apttus_Config2__Type__c = 'TPR';
        adjustmentLineItem1.Apttus_Config2__SubType__c = 'Trade';
        insert adjustmentLineItem1;

        List<Apttus_Config2__AdjustmentLineItem__c> ali = [SELECT Id FROM Apttus_Config2__AdjustmentLineItem__c];
        System.assertEquals(FALSE, ali.isEmpty());


        Apttus_Config2.CallbackTester.testValidationCallback(pConfig.Id, lineItems, null, new APTS_ValidationCallBack());
    }


    static testMethod void testMethod7() {
        Apttus_Config2__ProductConfiguration__c pConfig = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];
        List<Apttus_Config2__LineItem__c> lineItems =
            [SELECT Id, APTS_ATP_Cleared__c, APTS_Expected_Delivery_Quantity__c, Apttus_Config2__Quantity__c,
             Apttus_Config2__PricingStatus__c, Apttus_Config2__ExtendedPrice__c,Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c FROM Apttus_Config2__LineItem__c];

        for (Apttus_Config2__LineItem__c oLineItem : lineItems) {
            oLineItem.APTS_Expected_Delivery_Quantity__c = 0;
            oLineItem.APTS_ATP_Cleared__c = true;
            oLineItem.Apttus_Config2__ExtendedPrice__c = 90;
        }
        update lineItems;

        // Line items
        Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem = new Apttus_Config2__AdjustmentLineItem__c();
        adjustmentLineItem.Apttus_Config2__AdjustmentAmount__c = 120;
        adjustmentLineItem.Apttus_Config2__AdjustmentAppliesTo__c = 'Previous Price';
        adjustmentLineItem.Apttus_Config2__AdjustmentType__c = '% Discount';

        adjustmentLineItem.Apttus_Config2__LineItemId__c = lineItems.get(0).Id;
        adjustmentLineItem.Apttus_Config2__LineNumber__c = 1;
        adjustmentLineItem.Apttus_Config2__LineType__c = 'Manual';
        adjustmentLineItem.Apttus_Config2__Type__c = 'TPR';
        adjustmentLineItem.Apttus_Config2__SubType__c = 'Trade';
        insert adjustmentLineItem;



        List<Apttus_Config2__AdjustmentLineItem__c> ali = [SELECT Id FROM Apttus_Config2__AdjustmentLineItem__c];
        System.assertEquals(FALSE, ali.isEmpty());


        Apttus_Config2.CallbackTester.testValidationCallback(pConfig.Id, lineItems, null, new APTS_ValidationCallBack());
    }

    @isTest static void testMethod8() {
        Apttus_Config2__ProductConfiguration__c pConfig = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];
        pConfig.APTS_Flow__c = NGMACHINE_ORDER;
        update pConfig;

        List<Apttus_Config2__LineItem__c> lineItems = [SELECT Id, APTS_ATP_Cleared__c, APTS_Expected_Delivery_Quantity__c,
                                          APTS_is_Tax_and_VAT_calculated__c, Apttus_Config2__Quantity__c, Apttus_Config2__PricingStatus__c,
                                          Apttus_Config2__ExtendedPrice__c, Apttus_Config2__LineType__c, Apttus_Config2__HasOptions__c,
                                          APTS_Serial_Number2__c, Apttus_Config2__BasePriceOverride__c,
                                          Apttus_Config2__LineStatus__c, Apttus_Config2__IsPrimaryLine__c, APTS_Order_LSP_Detail__c,Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c
                                          FROM Apttus_Config2__LineItem__c];

        lineItems[0].APTS_Serial_Number2__c = 'ValidationCallbacknotfound';
        update lineItems[0];

        Test.startTest();
        Apttus_Config2.CallbackTester.testValidationCallback(pConfig.Id, lineItems, null, new APTS_ValidationCallBack());

        lineItems[0].APTS_Serial_Number2__c = NULL;
        update lineItems[0];
        Test.stopTest();

        Apttus_Config2.CallbackTester.testValidationCallback(pConfig.Id, lineItems, null, new APTS_ValidationCallBack());
    }
    
    @isTest static void testMethod9() {
        Apttus_Config2__ProductConfiguration__c pConfig = [SELECT Id,Apttus_Config2__Status__c FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];
        pConfig.Apttus_Config2__Status__c = 'Saved';
        update pConfig;
        List<Apttus_Config2__LineItem__c> lineItems = [SELECT Id, APTS_ATP_Cleared__c, APTS_Expected_Delivery_Quantity__c,
                                          Apttus_Config2__Quantity__c, Apttus_Config2__PricingStatus__c, Apttus_Config2__ExtendedPrice__c,Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c FROM Apttus_Config2__LineItem__c];

        for (Apttus_Config2__LineItem__c oLineItem : lineItems) {
            oLineItem.Apttus_Config2__BasePriceOverride__c = 2;
            oLineItem.Apttus_Config2__NetAdjustmentPercent__c = 50;
            oLineItem.Apttus_Config2__HasOptions__c=true;
            oLineItem.Apttus_Config2__NetUnitPrice__c=100;
            oLineItem.Apttus_Config2__BasePrice__c=200;
        }
        update lineItems;
        Apttus_Config2.CallbackTester.testValidationCallback(pConfig.Id, lineItems, null, new APTS_ValidationCallBack());
    }

    @isTest static void testMethod10() {
        Apttus_Config2__ProductConfiguration__c pConfig = [SELECT Id,Apttus_Config2__Status__c FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];
        pConfig.Apttus_Config2__Status__c = 'Saved';
        update pConfig;
        List<Apttus_Config2__LineItem__c> lineItems = [SELECT Id, APTS_ATP_Cleared__c, APTS_Expected_Delivery_Quantity__c,
                                          Apttus_Config2__Quantity__c, Apttus_Config2__PricingStatus__c, Apttus_Config2__ExtendedPrice__c,Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c FROM Apttus_Config2__LineItem__c];

        for (Apttus_Config2__LineItem__c oLineItem : lineItems) {
            oLineItem.Apttus_Config2__BasePriceOverride__c = 0;
            oLineItem.Apttus_Config2__NetAdjustmentPercent__c = 50;
            oLineItem.Apttus_Config2__HasOptions__c=true;
            oLineItem.Apttus_Config2__NetUnitPrice__c=100;
            oLineItem.Apttus_Config2__BasePrice__c=200;
        }
        update lineItems;
        Apttus_Config2.CallbackTester.testValidationCallback(pConfig.Id, lineItems, null, new APTS_ValidationCallBack());
    }
    
    @isTest static void testMethod11() {
        Apttus_Config2__ProductConfiguration__c pConfig = [SELECT Id,Apttus_Config2__Status__c FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];
        pConfig.Apttus_Config2__Status__c = 'Saved';
        //pConfig.APTS_Flow__c = NGDEFAULT;
        update pConfig;
        Product2 prod3 = APTS_TestDataFactory.createProduct(APTS_ValidationCallBackTest.ACCOUNT_NAME, APTS_ValidationCallBackTest.ACCOUNT_NAME, APTS_ValidationCallBackTest.ACCOUNT_NAME, APTS_ValidationCallBackTest.PROD_CONFIG_STANDALONE, FALSE, FALSE);
        prod3.name= 'Fixed Term Test';
        insert prod3;

        List<Apttus_Config2__LineItem__c> lineItems = [SELECT Id, APTS_ATP_Cleared__c, APTS_Expected_Delivery_Quantity__c,
                                          Apttus_Config2__Quantity__c,Apttus_Config2__OptionId__c, Apttus_Config2__PricingStatus__c, Apttus_Config2__ExtendedPrice__c,Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c FROM Apttus_Config2__LineItem__c];

        for (Apttus_Config2__LineItem__c oLineItem : lineItems) {
            oLineItem.Apttus_Config2__BasePriceOverride__c = 0;
            oLineItem.Apttus_Config2__NetAdjustmentPercent__c = 50;
            oLineItem.Apttus_Config2__HasOptions__c=true;
            oLineItem.Apttus_Config2__NetUnitPrice__c=100;
            oLineItem.Apttus_Config2__BasePrice__c=0;
            oLineItem.Apttus_Config2__OptionId__c = prod3.id;
        }
        update lineItems;
        Apttus_Config2.CallbackTester.testValidationCallback(pConfig.Id, lineItems, null, new APTS_ValidationCallBack());
    }
    
   
     @isTest static void testMethod12() {
        Apttus_Config2__ProductConfiguration__c pConfig = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];
        pConfig.APTS_Flow__c = NGSTANDARD_ORDER;
        update pConfig;

        List<Apttus_Config2__LineItem__c> lineItems = [SELECT Id, APTS_ATP_Cleared__c, APTS_Expected_Delivery_Quantity__c,
                                          APTS_is_Tax_and_VAT_calculated__c, Apttus_Config2__Quantity__c, Apttus_Config2__PricingStatus__c,
                                          Apttus_Config2__ExtendedPrice__c, Apttus_Config2__LineType__c, Apttus_Config2__HasOptions__c,
                                          APTS_Serial_Number2__c, Apttus_Config2__BasePriceOverride__c,
                                          Apttus_Config2__LineStatus__c, Apttus_Config2__IsPrimaryLine__c, APTS_Order_LSP_Detail__c,Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__c,
                                          Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c FROM Apttus_Config2__LineItem__c];

        lineItems[0].APTS_Serial_Number2__c = 'ValidationCallbacknotfound';
        lineItems[0].APTS_is_Tax_and_VAT_calculated__c = true;
        update lineItems[0];

        Test.startTest();
        Apttus_Config2.CallbackTester.testValidationCallback(pConfig.Id, lineItems, null, new APTS_ValidationCallBack());

        lineItems[0].APTS_Serial_Number2__c = NULL;
        update lineItems[0];
        Test.stopTest();

        Apttus_Config2.CallbackTester.testValidationCallback(pConfig.Id, lineItems, null, new APTS_ValidationCallBack());
    }
    
    @isTest static void testMethod13() {
        Apttus_Config2__ProductConfiguration__c pConfig = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];
        pConfig.APTS_Flow__c = NGMACHINE_ORDER;
        update pConfig;

        List<Apttus_Config2__LineItem__c> lineItems = [SELECT Id, APTS_ATP_Cleared__c, APTS_Expected_Delivery_Quantity__c,
                                          APTS_is_Tax_and_VAT_calculated__c, Apttus_Config2__Quantity__c, Apttus_Config2__PricingStatus__c,
                                          Apttus_Config2__ExtendedPrice__c, Apttus_Config2__LineType__c, Apttus_Config2__HasOptions__c,
                                          APTS_Serial_Number2__c, Apttus_Config2__BasePriceOverride__c,
                                          Apttus_Config2__LineStatus__c, Apttus_Config2__IsPrimaryLine__c, APTS_Order_LSP_Detail__c,
                                          Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c FROM Apttus_Config2__LineItem__c];

        lineItems[0].APTS_Serial_Number2__c = 'ValidationCallbacknotfound';
        lineItems[0].Apttus_Config2__NetPrice__c = -10;
        
        update lineItems[0];

        Test.startTest();
        Apttus_Config2.CallbackTester.testValidationCallback(pConfig.Id, lineItems, null, new APTS_ValidationCallBack());

        lineItems[0].APTS_Serial_Number2__c = NULL;
        update lineItems[0];
        Test.stopTest();

        Apttus_Config2.CallbackTester.testValidationCallback(pConfig.Id, lineItems, null, new APTS_ValidationCallBack());
    }
    @isTest static void testMethod17() {

         Test.startTest();
        Apttus_Config2__PriceList__c pricelist = APTS_TestDataFactory.createPriceList(APTS_ValidationCallBackTest.PRICELIST_NAME);
        Database.insert(pricelist, FALSE);


         // create account
        Account oAccount = APTS_TestDataFactory.createAccount(APTS_ValidationCallBackTest.ACCOUNT_NAME);
        Database.insert(oAccount, FALSE);

        // create contact
        Contact oContact = APTS_TestDataFactory.createContact(oAccount, APTS_ValidationCallBackTest.CONTACT_NUMBER);
        Database.insert(oContact, FALSE);

        // create opportunity
        opportunity opportunityObj = APTS_TestDataFactory.createOpportunity(APTS_ValidationCallBackTest.OPPORTUNITY_NAME, oAccount.Id);
        Database.insert(opportunityObj, FALSE);

        Product2 prod2 = APTS_TestDataFactory.createProduct(APTS_ValidationCallBackTest.ACCOUNT_NAME, APTS_ValidationCallBackTest.ACCOUNT_NAME, APTS_ValidationCallBackTest.ACCOUNT_NAME, APTS_ValidationCallBackTest.PROD_CONFIG_STANDALONE, FALSE, FALSE);
        insert prod2;

        Apttus_Config2__PriceListItem__c pli2 = APTS_TestDataFactory.createPriceListItem(priceList.Id, prod2.Id);
        insert pli2;
        
        Apttus_Config2__Order__c order = APTS_TestDataFactory.createOrder(oAccount.Id, pricelist.Id, oContact.Id);
        order.APTS_Requested_Delivery_Date__c = System.today();
        order.APTS_Order_Sub_Type__c = 'De-Installation';
        order.APTS_SAP_OrderType__c = 'XB13';
        Database.insert(order, FALSE);

        Apttus_Config2__ProductConfiguration__c config = APTS_TestDataFactory.createProductConfig(order);
        config.APTS_Flow__c = 'NGMachineDeinstallOrder';
        //config.Apttus_Config2__NumberOfItems__c = 180;
        config.Apttus_Config2__OrderId__c = order.id;
        
        //config.Apttus_Config2__Status__c = APTS_ValidationCallBackTest.FINALIZED;
        Database.insert(config, FALSE);


        Apttus_Config2__ProductConfiguration__c pConfig = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c where id=:config.id LIMIT 1];
        /*pConfig.APTS_Flow__c = NGMACHINE_ORDER;
        update pConfig;*/

        
       

        Apttus_Config2__BillingPreference__c billPref = APTS_TestDataFactory.createBillingPrefrence(APTS_ValidationCallBackTest.BILLING_PREFRENCE);
        Database.insert(billPref, FALSE);

        List<Apttus_Config2__LineItem__c> listItem = new List<Apttus_Config2__LineItem__c>();
        

        Apttus_Config2__LineItem__c lineItem4 = APTS_TestDataFactory.createLineItem(config, pli2.Id, NULL, prod2.Id, NULL, NULL, 2, 2, 2, APTS_ValidationCallBackTest.PRODUCT_SERVICE, billPref.Id, APTS_ValidationCallBackTest.BILLING_FREQ_MONTHLY, APTS_ValidationCallBackTest.BILLING_TYPE_ADVANCED, APTS_ValidationCallBackTest.PRICE_TYPE_ONETIME, APTS_ValidationCallBackTest.PRICE_UNIT_PER, APTS_ValidationCallBackTest.PRICE_UNIT_EACH, 300, 1);
        //lineItem4.Apttus_Config2__PricingStatus__c = APTS_ValidationCallBackTest.COMPLETED;
        lineItem4.APTS_Requested_Delivery_Date__c = System.today();
        lineitem4.Apttus_Config2__HasOptions__c = false;
        lineItem4.Apttus_Config2__StartDate__c = System.today();
        lineitem4.Apttus_Config2__EndDate__c = System.today()-1;
        listItem.add(lineitem4);
        insert listItem;

        List<Apttus_Config2__LineItem__c> lineItems = [SELECT Id, APTS_ATP_Cleared__c, APTS_Expected_Delivery_Quantity__c,
                                          APTS_is_Tax_and_VAT_calculated__c, Apttus_Config2__Quantity__c, Apttus_Config2__PricingStatus__c,
                                          Apttus_Config2__ExtendedPrice__c, Apttus_Config2__LineType__c, Apttus_Config2__HasOptions__c,
                                          APTS_Serial_Number2__c, Apttus_Config2__BasePriceOverride__c,
                                          Apttus_Config2__LineStatus__c, Apttus_Config2__IsPrimaryLine__c, APTS_Order_LSP_Detail__c,
                                          Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c,Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c
                                          FROM Apttus_Config2__LineItem__c WHERE Apttus_Config2__ConfigurationId__c =:Config.Id];
        
        Apttus_Config2.CallbackTester.testValidationCallback(config.Id, lineItems, null, new APTS_ValidationCallBack());
        Test.stopTest();

    }

    @isTest static void testMethod14() {

        Apttus_Config2__ProductConfiguration__c pConfig = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];
        List<Apttus_Config2__LineItem__c> lineItems = [SELECT Id, APTS_ATP_Cleared__c, APTS_Expected_Delivery_Quantity__c,
                                          Apttus_Config2__Quantity__c, Apttus_Config2__PricingStatus__c, Apttus_Config2__ExtendedPrice__c,Apttus_Config2__HasOptions__c,Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c FROM Apttus_Config2__LineItem__c];
        for (Apttus_Config2__LineItem__c oLineItem : lineItems) {
            oLineItem.Apttus_Config2__PricingStatus__c = APTS_ValidationCallBackTest.PENDING;
            lineItems[0].Apttus_Config2__HasOptions__c=true;
        }
        update lineItems;
        Apttus_Config2__AdjustmentLineItem__c adjustlineItem11 = new Apttus_Config2__AdjustmentLineItem__c (Apttus_Config2__LineNumber__c = 999,
                Apttus_Config2__LineItemId__c = lineItems[0].id);
        Database.insert(adjustlineItem11);

        Test.startTest();
        Apttus_Config2.CallbackTester.testValidationCallback(pConfig.Id, lineItems, null, new APTS_ValidationCallBack());
        Test.stopTest();
    }
     @isTest static void testMethod15() {

        Apttus_Config2__ProductConfiguration__c pConfig = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];
        List<Apttus_Config2__LineItem__c> lineItems = [SELECT Id, APTS_ATP_Cleared__c, APTS_Expected_Delivery_Quantity__c,
                                          Apttus_Config2__Quantity__c, Apttus_Config2__PricingStatus__c, Apttus_Config2__ExtendedPrice__c,Apttus_Config2__BasePriceOverride__c,Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c  FROM Apttus_Config2__LineItem__c];
        for (Apttus_Config2__LineItem__c oLineItem : lineItems) {
            oLineItem.Apttus_Config2__PricingStatus__c = APTS_ValidationCallBackTest.PENDING;
            oLineItem.Apttus_Config2__BasePriceOverride__c=100;
            oLineItem.Apttus_Config2__HasOptions__c=true;
        }
        update lineItems;

        Test.startTest();
        Apttus_Config2.CallbackTester.testValidationCallback(pConfig.Id, lineItems, null, new APTS_ValidationCallBack());
        Test.stopTest();
    }
     @isTest static void testMethod16() {

        Apttus_Config2__ProductConfiguration__c pConfig = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];
        List<Apttus_Config2__LineItem__c> lineItems = [SELECT Id, APTS_ATP_Cleared__c, APTS_Expected_Delivery_Quantity__c,
                                          Apttus_Config2__Quantity__c, Apttus_Config2__PricingStatus__c, Apttus_Config2__ExtendedPrice__c,Apttus_Config2__BasePriceOverride__c, Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c  FROM Apttus_Config2__LineItem__c];
        for (Apttus_Config2__LineItem__c oLineItem : lineItems) {
            oLineItem.Apttus_Config2__PricingStatus__c = APTS_ValidationCallBackTest.PENDING;
        }
        update lineItems;
        Apttus_Config2__AdjustmentLineItem__c adjustlineItem11 = new Apttus_Config2__AdjustmentLineItem__c (Apttus_Config2__LineNumber__c = 999,
                Apttus_Config2__LineItemId__c = lineItems[0].id,APTS_Adjustment_Source__c='Parent');
        adjustlineItem11.APTS_End_Date__c =  system.today()-10;
        adjustlineItem11.APTS_Start_Date__c = system.today();
        Database.insert(adjustlineItem11);

        Test.startTest();
        Apttus_Config2.CallbackTester.testValidationCallback(pConfig.Id, lineItems, null, new APTS_ValidationCallBack());
        Test.stopTest();
    }

    
    @isTest static void testMethod18() {

        Test.startTest();
        Apttus_Config2__PriceList__c pricelist = APTS_TestDataFactory.createPriceList(APTS_ValidationCallBackTest.PRICELIST_NAME);
        Database.insert(pricelist, FALSE);


         // create account
        Account oAccount = APTS_TestDataFactory.createAccount(APTS_ValidationCallBackTest.ACCOUNT_NAME);
        Database.insert(oAccount, FALSE);

        // create contact
        Contact oContact = APTS_TestDataFactory.createContact(oAccount, APTS_ValidationCallBackTest.CONTACT_NUMBER);
        Database.insert(oContact, FALSE);

        // create opportunity
        opportunity opportunityObj = APTS_TestDataFactory.createOpportunity(APTS_ValidationCallBackTest.OPPORTUNITY_NAME, oAccount.Id);
        Database.insert(opportunityObj, FALSE);

        Product2 prod2 = APTS_TestDataFactory.createProduct(APTS_ValidationCallBackTest.ACCOUNT_NAME, APTS_ValidationCallBackTest.ACCOUNT_NAME, APTS_ValidationCallBackTest.ACCOUNT_NAME, APTS_ValidationCallBackTest.PROD_CONFIG_STANDALONE, FALSE, FALSE);
        insert prod2;

        Apttus_Config2__PriceListItem__c pli2 = APTS_TestDataFactory.createPriceListItem(priceList.Id, prod2.Id);
        insert pli2;
        
        Apttus_Config2__Order__c order = APTS_TestDataFactory.createOrder(oAccount.Id, pricelist.Id, oContact.Id);
        order.APTS_Requested_Delivery_Date__c = System.today();
        order.APTS_Order_Sub_Type__c = 'De-Installation';
        Database.insert(order, FALSE);

        Apttus_Config2__ProductConfiguration__c config = APTS_TestDataFactory.createProductConfig(order);
        config.APTS_Flow__c = 'NGMachineDeinstallOrder';
        //config.Apttus_Config2__NumberOfItems__c = 180;
        config.Apttus_Config2__OrderId__c = order.id;
        
        //config.Apttus_Config2__Status__c = APTS_ValidationCallBackTest.FINALIZED;
        Database.insert(config, FALSE);


        Apttus_Config2__ProductConfiguration__c pConfig = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c where id=:config.id LIMIT 1];
        /*pConfig.APTS_Flow__c = NGMACHINE_ORDER;
        update pConfig;*/

        
       

        Apttus_Config2__BillingPreference__c billPref = APTS_TestDataFactory.createBillingPrefrence(APTS_ValidationCallBackTest.BILLING_PREFRENCE);
        Database.insert(billPref, FALSE);

        List<Apttus_Config2__LineItem__c> listItem = new List<Apttus_Config2__LineItem__c>();

        Apttus_Config2__LineItem__c lineItem4 = APTS_TestDataFactory.createLineItem(config, pli2.Id, NULL, prod2.Id, NULL, NULL, 2, 2, 2, APTS_ValidationCallBackTest.PRODUCT_SERVICE, billPref.Id, APTS_ValidationCallBackTest.BILLING_FREQ_MONTHLY, APTS_ValidationCallBackTest.BILLING_TYPE_ADVANCED, APTS_ValidationCallBackTest.PRICE_TYPE_ONETIME, APTS_ValidationCallBackTest.PRICE_UNIT_PER, APTS_ValidationCallBackTest.PRICE_UNIT_EACH, 300, 1);
        //lineItem4.Apttus_Config2__PricingStatus__c = APTS_ValidationCallBackTest.COMPLETED;
        lineItem4.APTS_Requested_Delivery_Date__c = System.today();
        lineitem4.Apttus_Config2__HasOptions__c = false;
        lineitem4.Apttus_Config2__LineStatus__c = 'Amended';
        listItem.add(lineitem4);
        insert listItem;

        
        Apttus_Config2.CallbackTester.testValidationCallback(config.Id, listItem, null, new APTS_ValidationCallBack());
        Test.stopTest();

    } 
  @isTest static void testMethod19() {

        Apttus_Config2__ProductConfiguration__c pConfig = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];
        List<Apttus_Config2__LineItem__c> lineItems = [SELECT Id, APTS_ATP_Cleared__c, APTS_Expected_Delivery_Quantity__c,
                                          Apttus_Config2__Quantity__c, Apttus_Config2__PricingStatus__c, Apttus_Config2__ExtendedPrice__c,Apttus_Config2__HasOptions__c,Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c FROM Apttus_Config2__LineItem__c];
        for (Apttus_Config2__LineItem__c oLineItem : lineItems) {
            oLineItem.Apttus_Config2__PricingStatus__c = APTS_ValidationCallBackTest.PENDING;
            lineItems[0].Apttus_Config2__HasOptions__c=true;
        }
        update lineItems;
       
                Apttus_Config2__AdjustmentLineItem__c adjustlineItem12 = new Apttus_Config2__AdjustmentLineItem__c (Apttus_Config2__LineNumber__c = 999,APTS_End_Date__c = System.today(),APTS_Start_Date__c=System.today().addDays(1),Apttus_Config2__LineItemId__c = lineItems[0].id);
                
        Database.insert(adjustlineItem12);

        Test.startTest();
    
        Apttus_Config2.CallbackTester.testValidationCallback(pConfig.Id, lineItems, null, new APTS_ValidationCallBack());
        Test.stopTest();
    }
    
    @isTest static void testMethod20() {

        Apttus_Config2__ProductConfiguration__c pConfig = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];
        List<Apttus_Config2__LineItem__c> lineItems = [SELECT Id, APTS_ATP_Cleared__c, APTS_Expected_Delivery_Quantity__c,
                                          Apttus_Config2__Quantity__c, Apttus_Config2__PricingStatus__c, Apttus_Config2__ExtendedPrice__c,Apttus_Config2__HasOptions__c,Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c FROM Apttus_Config2__LineItem__c];
        for (Apttus_Config2__LineItem__c oLineItem : lineItems) {
            oLineItem.Apttus_Config2__PricingStatus__c = APTS_ValidationCallBackTest.PENDING;
            lineItems[0].Apttus_Config2__HasOptions__c=true;
        }
        update lineItems;
        Apttus_Config2__AdjustmentLineItem__c adjustlineItem11 = new Apttus_Config2__AdjustmentLineItem__c (Apttus_Config2__LineNumber__c = 999,Apttus_Config2__SubType__c = null,Apttus_Config2__LineItemId__c = lineItems[0].id);
                
        Database.insert(adjustlineItem11);

        Test.startTest();
      
        Apttus_Config2.CallbackTester.testValidationCallback(pConfig.Id, lineItems, null, new APTS_ValidationCallBack());
        Test.stopTest();
    }
    @isTest static void testMethod21() {

        Apttus_Config2__ProductConfiguration__c pConfig = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];
        List<Apttus_Config2__LineItem__c> lineItems = [SELECT Id, APTS_ATP_Cleared__c, APTS_Expected_Delivery_Quantity__c,
                                          Apttus_Config2__Quantity__c, Apttus_Config2__PricingStatus__c, Apttus_Config2__ExtendedPrice__c,Apttus_Config2__HasOptions__c,Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c FROM Apttus_Config2__LineItem__c];
        for (Apttus_Config2__LineItem__c oLineItem : lineItems) {
            oLineItem.Apttus_Config2__PricingStatus__c = APTS_ValidationCallBackTest.PENDING;
            lineItems[0].Apttus_Config2__HasOptions__c=true;
        }
        update lineItems;
        
                Apttus_Config2__AdjustmentLineItem__c adjustlineItem13 = new Apttus_Config2__AdjustmentLineItem__c (Apttus_Config2__LineNumber__c = 999,APTS_Asset_Sub_Type__c='ZP02', APTS_Asset_Adjustment_Amount__c=5,Apttus_Config2__AdjustmentAmount__c=10,Apttus_Config2__SubType__c='ZP03',Apttus_Config2__LineItemId__c = lineItems[0].id);
        Database.insert(adjustlineItem13);

        Test.startTest();
      
        Apttus_Config2.CallbackTester.testValidationCallback(pConfig.Id, lineItems, null, new APTS_ValidationCallBack());
        Test.stopTest();
    }
    
    @isTest static void testMethod22() {

        Apttus_Config2__ProductConfiguration__c pConfig = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];
        List<Apttus_Config2__LineItem__c> lineItems = [SELECT Id, APTS_ATP_Cleared__c, APTS_Expected_Delivery_Quantity__c,
                                          Apttus_Config2__Quantity__c, Apttus_Config2__PricingStatus__c, Apttus_Config2__ExtendedPrice__c,Apttus_Config2__HasOptions__c,Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c FROM Apttus_Config2__LineItem__c];
        for (Apttus_Config2__LineItem__c oLineItem : lineItems) {
            oLineItem.Apttus_Config2__PricingStatus__c = APTS_ValidationCallBackTest.PENDING;
            oLineItem.Apttus_Config2__BillingFrequency__c=null;
            lineItems[0].Apttus_Config2__HasOptions__c=false;
        }
        update lineItems;
       

        Test.startTest();
       
        Apttus_Config2.CallbackTester.testValidationCallback(pConfig.Id, lineItems, null, new APTS_ValidationCallBack());
        Test.stopTest();
    }

    @isTest static void testMethod23() {
        Test.startTest();
        Apttus_Config2__PriceList__c pricelist = APTS_TestDataFactory.createPriceList(APTS_ValidationCallBackTest.PRICELIST_NAME);
        Database.insert(pricelist, FALSE);


         // create account
        Account oAccount = APTS_TestDataFactory.createAccount(APTS_ValidationCallBackTest.ACCOUNT_NAME);
        Database.insert(oAccount, FALSE);

        // create contact
        Contact oContact = APTS_TestDataFactory.createContact(oAccount, APTS_ValidationCallBackTest.CONTACT_NUMBER);
        Database.insert(oContact, FALSE);

        // create opportunity
        opportunity opportunityObj = APTS_TestDataFactory.createOpportunity(APTS_ValidationCallBackTest.OPPORTUNITY_NAME, oAccount.Id);
        Database.insert(opportunityObj, FALSE);

        Product2 prod2 = APTS_TestDataFactory.createProduct(APTS_ValidationCallBackTest.ACCOUNT_NAME, APTS_ValidationCallBackTest.ACCOUNT_NAME, APTS_ValidationCallBackTest.ACCOUNT_NAME, APTS_ValidationCallBackTest.PROD_CONFIG_STANDALONE, FALSE, FALSE);
        insert prod2;

        Apttus_Config2__PriceListItem__c pli2 = APTS_TestDataFactory.createPriceListItem(priceList.Id, prod2.Id);
        insert pli2;

        Apttus_Config2__Order__c order1 = APTS_TestDataFactory.createOrder(oAccount.Id, pricelist.Id, oContact.Id);
        order1.APTS_Requested_Delivery_Date__c = System.today();
        order1.APTS_Order_Sub_Type__c = 'De-Installation';
        order1.APTS_SAP_OrderType__c = 'XB13';
        order1.Apttus_Config2__Status__c = 'Activated';
        order1.APTS_Requested_Installation_Date__c = NULL;
        Database.insert(order1, FALSE);
        
        Apttus_Config2__Order__c order = APTS_TestDataFactory.createOrder(oAccount.Id, pricelist.Id, oContact.Id);
        order.APTS_Requested_Delivery_Date__c = System.today();
        order.APTS_Order_Sub_Type__c = 'Conversion order';
        order.APTS_SAP_OrderType__c = 'XA13';
        Database.insert(order, FALSE);

        Apttus_Config2__ProductConfiguration__c config = APTS_TestDataFactory.createProductConfig(order);
        config.APTS_Flow__c = 'NGAdminOrder';
        config.Apttus_Config2__Status__c=APTS_ValidationCallBackTest.FINALIZED;
        //config.Apttus_Config2__NumberOfItems__c = 180;
        config.Apttus_Config2__OrderId__c = order.id;
        
        //config.Apttus_Config2__Status__c = APTS_ValidationCallBackTest.FINALIZED;
        Database.insert(config, FALSE);

        Apttus_Config2__BillingPreference__c billPref = APTS_TestDataFactory.createBillingPrefrence(APTS_ValidationCallBackTest.BILLING_PREFRENCE);
        Database.insert(billPref, FALSE);

        Apttus_Config2__AssetLineItem__c oAssetLineItem = APTS_TestDataFactory.createAssetLineItem(order, pli2.Id, null, prod2.Id, null, 1, 1, 'Option', billPref.Id, 'Monthly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100.0, 10.0);
        insert oAssetLineItem; 
        
        Apttus_Config2__OrderLineItem__c oli = APTS_TestUtils.createOrderLineItem(prod2.Id, order1.Id, oAssetLineItem.Id, billPref.Id, priceList.Id, pli2.Id);
        insert oli;
        
        Apttus_Config2__ProductConfiguration__c pConfig1 = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];
        pConfig1.APTS_Flow__c = 'NGAdminOrder';
        update pConfig1;
        List<Apttus_Config2__LineItem__c> lineItems = [SELECT Id, APTS_ATP_Cleared__c, APTS_Expected_Delivery_Quantity__c,
                                          Apttus_Config2__Quantity__c, Apttus_Config2__PricingStatus__c, Apttus_Config2__ExtendedPrice__c,Apttus_Config2__HasOptions__c,Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c FROM Apttus_Config2__LineItem__c];
        for (Apttus_Config2__LineItem__c oLineItem : lineItems) {
            oLineItem.Apttus_Config2__PricingStatus__c = APTS_ValidationCallBackTest.COMPLETED;
            oLineItem.Apttus_Config2__AssetLineItemId__c=oAssetLineItem.id;
            oLineItem.APTS_is_Tax_and_VAT_calculated__c=true;
            lineItems[0].Apttus_Config2__HasOptions__c=false;
        }
        update lineItems;
       
        Apttus_Config2.CallbackTester.testValidationCallback(pConfig1.Id, lineItems, null, new APTS_ValidationCallBack());
        Test.stopTest();
    }

    @isTest static void testMethod24() {

        Test.startTest();
        Apttus_Config2__PriceList__c pricelist = APTS_TestDataFactory.createPriceList(APTS_ValidationCallBackTest.PRICELIST_NAME);
        Database.insert(pricelist, FALSE);


         // create account
        Account oAccount = APTS_TestDataFactory.createAccount(APTS_ValidationCallBackTest.ACCOUNT_NAME);
        Database.insert(oAccount, FALSE);

        // create contact
        Contact oContact = APTS_TestDataFactory.createContact(oAccount, APTS_ValidationCallBackTest.CONTACT_NUMBER);
        Database.insert(oContact, FALSE);

        // create opportunity
        opportunity opportunityObj = APTS_TestDataFactory.createOpportunity(APTS_ValidationCallBackTest.OPPORTUNITY_NAME, oAccount.Id);
        Database.insert(opportunityObj, FALSE);

        Product2 prod2 = APTS_TestDataFactory.createProduct(APTS_ValidationCallBackTest.ACCOUNT_NAME, APTS_ValidationCallBackTest.ACCOUNT_NAME, APTS_ValidationCallBackTest.ACCOUNT_NAME, APTS_ValidationCallBackTest.PROD_CONFIG_STANDALONE, FALSE, FALSE);
        insert prod2;

        Apttus_Config2__PriceListItem__c pli2 = APTS_TestDataFactory.createPriceListItem(priceList.Id, prod2.Id);
        insert pli2;
        
        Apttus_Config2__Order__c order = APTS_TestDataFactory.createOrder(oAccount.Id, pricelist.Id, oContact.Id);
        order.APTS_Requested_Delivery_Date__c = System.today();
        order.APTS_Order_Sub_Type__c = 'De-Installation';
        order.APTS_SAP_OrderType__c = 'XB13';
        Database.insert(order, FALSE);

        Apttus_Config2__ProductConfiguration__c config = APTS_TestDataFactory.createProductConfig(order);
        config.APTS_Flow__c = 'NGMachineDeinstallOrder';
        config.Apttus_Config2__Status__c=APTS_ValidationCallBackTest.FINALIZED;
        //config.Apttus_Config2__NumberOfItems__c = 180;
        config.Apttus_Config2__OrderId__c = order.id;
        
        //config.Apttus_Config2__Status__c = APTS_ValidationCallBackTest.FINALIZED;
        Database.insert(config, FALSE);

        Apttus_Config2__BillingPreference__c billPref = APTS_TestDataFactory.createBillingPrefrence(APTS_ValidationCallBackTest.BILLING_PREFRENCE);
        Database.insert(billPref, FALSE);

        Apttus_Config2__AssetLineItem__c oAssetLineItem = APTS_TestDataFactory.createAssetLineItem(order, pli2.Id, null, prod2.Id, null, 1, 1, 'Option', billPref.Id, 'Monthly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100.0, 10.0);
        oAssetLineItem.Apttus_Config2__OriginalStartDate__c=System.today();
        insert oAssetLineItem;    

        Apttus_Config2__ProductConfiguration__c pConfig1 = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];
        List<Apttus_Config2__LineItem__c> lineItems = [SELECT Id, APTS_ATP_Cleared__c, APTS_Expected_Delivery_Quantity__c,
                                          Apttus_Config2__Quantity__c, Apttus_Config2__PricingStatus__c, Apttus_Config2__ExtendedPrice__c,Apttus_Config2__HasOptions__c,Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c FROM Apttus_Config2__LineItem__c];
        for (Apttus_Config2__LineItem__c oLineItem : lineItems) {
            oLineItem.Apttus_Config2__PricingStatus__c = APTS_ValidationCallBackTest.COMPLETED;
            oLineItem.Apttus_Config2__AssetLineItemId__c=oAssetLineItem.id;
            oLineItem.Apttus_Config2__StartDate__c=System.today().addDays(-10);
            oLineItem.APTS_is_Tax_and_VAT_calculated__c=true;
            lineItems[0].Apttus_Config2__HasOptions__c=false;
        }
        update lineItems;
    
        Apttus_Config2.CallbackTester.testValidationCallback(pConfig1.Id, lineItems, null, new APTS_ValidationCallBack());
        Test.stopTest();

    }

}