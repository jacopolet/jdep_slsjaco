/**
* Class Name   : APTS_DigitalOrderUtils_Test
* Description  : Test class for APTS_DigitalOrderUtils
* Author       : Hariharan
* Date Created : 04/18/2018
**/
@isTest
private class APTS_DigitalOrderUtilsTest {

    @testSetup static void setupTestData() {
        User oTestUser = APTS_TestFacade.createTestUser();

        TriggerSettings__c oTriggerSettings = new TriggerSettings__c(AccountTrigger__c = false, Agreement__c = false, APTS_Order_Trigger__c = false, APTS_OrderLineItemTrigger__c = false, APTS_OrderFulfillmentLineItemTrigger__c = false, APTS_Order_Adjustment_Trigger__c = false, SetupOwnerId = oTestUser.ProfileId);
        Database.insert(oTriggerSettings);

        Apttus_Config2__ConfigLineItemCustomFields__c oConfigLineItemCustomFields = new Apttus_Config2__ConfigLineItemCustomFields__c();
        oConfigLineItemCustomFields.Name = 'System Properties';
        oConfigLineItemCustomFields.Apttus_Config2__CustomFieldNames__c = 'Apttus_Config2__HasIncentives__c';
        insert oConfigLineItemCustomFields;

        String acctName = 'Test' + string.valueOf(Math.random());
        Account testAccount = APTS_TestDataFactory.createAccount(acctName);
        insert testAccount;

        Group queue = new Group();
        queue.name = System.Label.APTS_CS_Queue;
        queue.Type = 'Queue';
        insert queue;

        Contact testContact = APTS_TestDataFactory.createContact(testAccount, '+912121212121');
        Database.insert(testContact, false);

        Apttus_Config2__PriceList__c testPriceList = APTS_TestDataFactory.createPriceList('testPriceList');
        Database.insert(testPriceList, false);

        Product2 testProduct = APTS_TestDataFactory.createProduct('TestCoffee', 'pc123', 'Coffee', 'Standalone', true, false);
        Database.Insert(testProduct, false);

        Apttus_Config2__PriceListItem__c oPriceListItemStandalone = APTS_TestDataFactory.createPriceListItem(testPriceList.Id, testProduct.Id);
        Database.Insert(oPriceListItemStandalone, false);

        Apttus__APTS_Agreement__c oAgr = APTS_TestDataFactory.createAgreement(testContact.Id, testPriceList.Id, testAccount.Id, 'Standard Deal');
        oAgr.Apttus__Status__c = 'Activated';
        oAgr.Apttus__Contract_End_Date__c = System.today().addYears(1);
        Database.insert(oAgr, FALSE);

        APTS_DOEPIReqWrapper oDOEPIReqWrapper = new APTS_DOEPIReqWrapper();
        oDOEPIReqWrapper.SourceOrderNumber = 'sn1232';
        oDOEPIReqWrapper.SalesforceAccountID = testAccount.Id;
        oDOEPIReqWrapper.SalesforceContactID = testContact.Id;
        oDOEPIReqWrapper.SalesforcePriceListID = testPriceList.Id;
        oDOEPIReqWrapper.SalesOrganization = 'SAP_0111';
        oDOEPIReqWrapper.AdjustmentType = 'Test Adjustment Type';
        /*oDOEPIReqWrapper.BillToCity = 'Test City';
        oDOEPIReqWrapper.BillToCompanyName = 'Test Company Name';
        oDOEPIReqWrapper.BillToContactName = 'Contact Name';
        oDOEPIReqWrapper.BillToCountry = 'Test Country';
        oDOEPIReqWrapper.BillToEmail = 'Test Email';
        oDOEPIReqWrapper.BillToOverride = 'No';
        oDOEPIReqWrapper.BillToPostalCode = '123545';
        oDOEPIReqWrapper.BillToStreet = 'Test Street'; */
        oDOEPIReqWrapper.CurrencyCode = 'EUR';
        oDOEPIReqWrapper.OneTimeContactName = 'Test OneTime Contact';
        oDOEPIReqWrapper.OneTimeCustomer = 'Yes';
        oDOEPIReqWrapper.OneTimeEmail = 'neshah@apttus.com';
        oDOEPIReqWrapper.ShipToCompanyName = 'Test ShipToCompanyName';
        oDOEPIReqWrapper.ShipToCountry = 'Test ShipToCountry';
        oDOEPIReqWrapper.ShipToCity = 'Test ShipToCity';
        oDOEPIReqWrapper.ShipToPostalCode = 'Test ShipToPostalCode';
        oDOEPIReqWrapper.ShipToStreetOnly = 'Test ShipToStreetOnly';
        oDOEPIReqWrapper.ShipToHouseNumber = 'Test ShipToHouseNumber';
        oDOEPIReqWrapper.ShipToHouseNumberSupplement = 'Test ShipToHouseNumberSupplement';
        oDOEPIReqWrapper.BillToContactName = 'Test BillToContactName';
        oDOEPIReqWrapper.BillToEmail = 'Test BillToEmail';
        oDOEPIReqWrapper.BillToCompanyName = 'Test BillToCompanyName';
        oDOEPIReqWrapper.BillToCountry = 'Test BillToCountry';
        oDOEPIReqWrapper.BillToCity = 'Test BillToCity';
        oDOEPIReqWrapper.BillToPostalCode = 'Test BillToPostalCode';
        oDOEPIReqWrapper.BillToStreetOnly = 'Test BillToStreetOnly';
        oDOEPIReqWrapper.BillToHouseNumber = 'Test BillToHouseNumber';
        oDOEPIReqWrapper.BillToHouseNumberSupplement = 'Test BillToHouseNumberSupplement';
        oDOEPIReqWrapper.ShipToOverride = 'Yes';
        oDOEPIReqWrapper.BillToOverride = 'Yes';
        oDOEPIReqWrapper.RequestDeliveryDate = dateTime.Now();
        oDOEPIReqWrapper.Source = 'Digital';
        oDOEPIReqWrapper.PrepaidFlag = 'Yes';
        oDOEPIReqWrapper.PaymentReferenceNumber = 'test Payment reference Number';
        oDOEPIReqWrapper.PaymentMethod = 'Test Payment Method';
        oDOEPIReqWrapper.PONumber = 'test PO';
        oDOEPIReqWrapper.ReferenceNumber = 'Test Reference Number';
        oDOEPIReqWrapper.AdjustmentType = 'Test Adjustment';
        oDOEPIReqWrapper.TotalOrderAmount = 4;
        oDOEPIReqWrapper.TotalShippingCost = 5;
        oDOEPIReqWrapper.TotalOrderAdjustment = 5;
        oDOEPIReqWrapper.TotalAdjustment = 5;
        oDOEPIReqWrapper.TotalAdjustedPrice = 5;
        oDOEPIReqWrapper.TotalTaxAmount = 8;
        oDOEPIReqWrapper.TotalVATAmount = 8;

        oDOEPIReqWrapper.OrderLineItems = new List<APTS_DOEPIReqWrapper.EPIOrderLI>();
        APTS_DOEPIReqWrapper.EPIOrderLI orderLineItem = new APTS_DOEPIReqWrapper.EPIOrderLI();
        orderLineItem.ProductCode = testProduct.productcode;
        orderLineItem.Quantity = 1;
        orderLineItem.ConfigurationType = 'Standalone';
        orderLineItem.SourceLineNumber = '1';
        orderLineItem.SellingUnitofMeasure = 'SAP_PCE';
        orderLineItem.ProductId = testProduct.id;
        orderLineItem.ReasonCode = 'Test Reason';
        orderLineItem.ParentBundleNumber = 1;
        orderLineItem.LineItemListPrice = 8;
        orderLineItem.LineItemAdjustmentAmount = 8;
        orderLineItem.LineItemAdustedPrice = 8;
        orderLineItem.LineItemTaxAmount = 8;
        orderLineItem.LineItemVATAmount = 8;

        orderLineItem.Adjustments = new List<APTS_DOEPIReqWrapper.EPIAdjustmentLI>();
        APTS_DOEPIReqWrapper.EPIAdjustmentLI oAdjust = new APTS_DOEPIReqWrapper.EPIAdjustmentLI();
        oAdjust.IncentiveAmount = 10;
        oAdjust.SubType = 'ZP08';
        orderLineItem.Adjustments.add(oAdjust);
        oDOEPIReqWrapper.OrderLineItems.add(orderLineItem);

        APTS_DOEPIReqWrapper.EPIOrderLI orderLineItem1 = new APTS_DOEPIReqWrapper.EPIOrderLI();
        orderLineItem1.ProductCode = testProduct.productcode;
        orderLineItem1.Quantity = 1;
        orderLineItem1.ConfigurationType = 'Standalone';
        orderLineItem1.SourceLineNumber = '2';
        orderLineItem1.SellingUnitofMeasure = 'SAP_PCE';
        orderLineItem1.ProductId = testProduct.id;
        orderLineItem1.ReasonCode = 'Test Reason';
        orderLineItem1.ParentBundleNumber = 1;
        orderLineItem1.LineItemListPrice = 8;
        orderLineItem1.LineItemAdjustmentAmount = 8;
        orderLineItem1.LineItemAdustedPrice = 8;
        orderLineItem1.LineItemTaxAmount = 8;
        orderLineItem1.LineItemVATAmount = 8;

        orderLineItem1.Adjustments = new List<APTS_DOEPIReqWrapper.EPIAdjustmentLI>();
        orderLineItem1.Adjustments.add(oAdjust);
        oDOEPIReqWrapper.OrderLineItems.add(orderLineItem1);

        String sJSONClass = JSON.serialize(oDOEPIReqWrapper);

        APTS_Order_Interface_Log__c oLog = new APTS_Order_Interface_Log__c();
        oLog.APTS_Message__c = sJSONClass;
        oLog.APTS_SourceOrderNumber__c = 'sn1232';
        oLog.APTS_Status__c = 'New';
        oLog.APTS_Sequence__c = 1;
        insert oLog;

        Apttus_Config2__PaymentTerm__c oTerm = new Apttus_Config2__PaymentTerm__c();
        oTerm.APTS_Ext_ID__c = 'SAP_ZOLP';
        oTerm.Name = 'Default';
        oTerm.Apttus_Config2__Sequence__c = 1;
        insert oTerm;
    }

    @isTest static void testOrder() {
        Group queue = [SELECT Id FROM Group LIMIT 1];
        User oTestUser = APTS_TestFacade.getTestUser();

        //remove all Callbacks
        List<Apttus_Config2__ConfigCustomClasses__c> listConfigSetting = [SELECT id FROM Apttus_Config2__ConfigCustomClasses__c];
        if (!listConfigSetting.isEmpty()) {
            delete listConfigSetting;
        }

        //disable Order triggers
        TaskTriggerHandler.isTriggerDisabled = true;
        Id userProfileId = userinfo.getProfileId();
        List<TriggerSettings__c> triggerSettingsList = [SELECT Id, APTS_Order_Trigger__c FROM TriggerSettings__c WHERE SetupOwnerId = :userProfileId LIMIT 1];
        if (!triggerSettingsList.isEmpty()) {
            triggerSettingsList[0].APTS_Order_Trigger__c = false;
            triggerSettingsList[0].APTS_OrderLineItemTrigger__c = FALSE;
            triggerSettingsList[0].TaskTrigger__c = FALSE;
            Database.update(triggerSettingsList);
        }

        List<APTS_Order_Interface_Log__c> listLog = [SELECT Id, APTS_Message__c, APTS_SourceOrderNumber__c, APTS_Status__c FROM APTS_Order_Interface_Log__c WHERE APTS_Parent_Log__c = NULL LIMIT 1];
        System.assertNotEquals(true, listLog.isEmpty());

        String sJSONStr = listLog != null ? listLog[0].APTS_Message__c : null;
        System.assertNotEquals(TRUE, String.isBlank(sJSONStr));

        APTS_DOEPIReqWrapper objWrapper = (APTS_DOEPIReqWrapper)JSON.deserialize(sJSONStr, APTS_DOEPIReqWrapper.class);
        System.assertNotEquals(null, objWrapper);
        System.assertNotEquals(null, objWrapper.OrderLineItems);
        System.assertNotEquals(true, objWrapper.OrderLineItems.isEmpty());

        Test.startTest();

        String sErrmsg = APTS_DigitalOrderUtils.validateData(objWrapper);
        System.assertEquals(TRUE, String.isBlank(sErrmsg));

        Set<Id> setSoldToID = new Set<Id> {};
        setSoldToID.add(objWrapper.SalesforceAccountID);

        //accounts
        Map<Id, Account> mapSoldTo = APTS_DigitalOrderUtils.getAccounts(setSoldToID);
        System.assertNotEquals(null, mapSoldTo);
        System.assertNotEquals(true, mapSoldTo.isEmpty());

        //contacts
        Map<Id, Contact> mapContacts = APTS_DigitalOrderUtils.getContacts(setSoldToID);
        System.assertNotEquals(null, mapContacts);
        System.assertNotEquals(true, mapContacts.isEmpty());

        //payment term
        Apttus_Config2__PaymentTerm__c oPaymentTerm = APTS_DigitalOrderUtils.getDefaultPaymentTerm();
        System.assertNotEquals(null, oPaymentTerm);

        Set<String> setProdCodes = new Set<String>();
        setProdCodes.add(objWrapper.OrderLineItems[0].ProductCode);
        Map<String, Product2> mapProducts = APTS_DigitalOrderUtils.getProductCodes(setProdCodes);
        System.assertNotEquals(null, mapProducts);
        System.assertNotEquals(true, mapProducts.isEmpty());

        Map<String, Product2> mapprod = APTS_DigitalOrderUtils.getProductCodes(new Set<String> {'pc123'});
        System.assertEquals(false, mapprod.isEmpty());

        Test.stopTest();
    }

    @isTest static void testValidation() {
        Group queue = [SELECT Id FROM Group LIMIT 1];
        User oTestUser = APTS_TestFacade.getTestUser();

        Test.startTest();
        APTS_DOEPIReqWrapper objWrapper;
        String sErrmsg = APTS_DigitalOrderUtils.validateData(objWrapper);
        System.assertEquals(TRUE, String.isNotBlank(sErrmsg));
        System.assertEquals(TRUE, sErrmsg.containsIgnoreCase('JSON cannot be NULL'));

        objWrapper = new APTS_DOEPIReqWrapper();
        sErrmsg = APTS_DigitalOrderUtils.validateData(objWrapper);
        System.assertEquals(TRUE, String.isNotBlank(sErrmsg));
        System.assertEquals(TRUE, sErrmsg.containsIgnoreCase('Source cannot be blank.'));

        objWrapper.Source = 'Digital';
        objWrapper.OrderLineItems = new List<APTS_DOEPIReqWrapper.EPIOrderLI>();
        sErrmsg = APTS_DigitalOrderUtils.validateData(objWrapper);
        System.assertEquals(TRUE, String.isNotBlank(sErrmsg));


        Test.stopTest();
    }

    @isTest static void testOrderMethod() {
        Group queue = [SELECT Id FROM Group LIMIT 1];
        system.assertNotEquals(null, queue);

        List<APTS_Order_Interface_Log__c> listEPILog = [SELECT Id, APTS_Message__c, APTS_SourceOrderNumber__c, APTS_Status__c FROM APTS_Order_Interface_Log__c WHERE APTS_Parent_Log__c = NULL];
        APTS_DigitalOrderBatchHelper.processdigitalorders(queue, listEPILog);
    }
}