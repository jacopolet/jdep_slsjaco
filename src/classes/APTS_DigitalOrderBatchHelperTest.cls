@isTest
private class APTS_DigitalOrderBatchHelperTest {

    @testSetup static void setupTestData() {
        User oTestUser = APTS_TestFacade.createTestUser();

        TriggerSettings__c oTriggerSettings = new TriggerSettings__c(AccountTrigger__c = false, Agreement__c = false, APTS_Order_Trigger__c = false, APTS_OrderLineItemTrigger__c = false, APTS_OrderFulfillmentLineItemTrigger__c = false, APTS_Order_Adjustment_Trigger__c = false, SetupOwnerId = oTestUser.ProfileId);
        Database.insert(oTriggerSettings);

        String acctName = 'Test' + string.valueOf(Math.random());

        Apttus_Config2__ConfigLineItemCustomFields__c oConfigLineItemCustomFields = new Apttus_Config2__ConfigLineItemCustomFields__c();
        oConfigLineItemCustomFields.Name = 'System Properties';
        oConfigLineItemCustomFields.Apttus_Config2__CustomFieldNames__c = 'Apttus_Config2__HasIncentives__c, Apttus_Config2__IncentiveCode__c';
        insert oConfigLineItemCustomFields;

        Apttus_Config2__PriceList__c testPriceList = APTS_TestDataFactory.createPriceList('testPriceList');
        testPriceList.APTS_Region__c = 'SAP_0111';
        testPriceList.APTS_PriceList_Type__c  = 'Direct';
        Database.insert(testPriceList, false);

        Account testAccount = APTS_TestDataFactory.createAccount(acctName);
        testAccount.APTS_Price_List__c = testPriceList.Id;
        testAccount.Sales_Organization__c = 'SAP_0111';
        insert testAccount;

        Group queue = new Group();
        queue.name = System.Label.APTS_CS_Queue;
        queue.Type = 'Queue';
        insert queue;

        Contact testContact = APTS_TestDataFactory.createContact(testAccount, '+912121212121');
        Database.insert(testContact, false);

        

        Product2 testProduct = APTS_TestDataFactory.createProduct('TestCoffee', 'pc123', 'Coffee', 'Standalone', true, false);
        Database.Insert(testProduct, false);

        Product2 frieghtProduct = APTS_TestDataFactory.createProduct('TestCoffee', System.Label.APTS_FREIGHT_CHARGE, 'Coffee', 'Standalone', true, false);
        Database.Insert(frieghtProduct, false);

        Apttus_Config2__PriceListItem__c oPriceListItemStandalone = APTS_TestDataFactory.createPriceListItem(testPriceList.Id, testProduct.Id);
        Database.Insert(oPriceListItemStandalone, false);

        Apttus__APTS_Agreement__c oAgr = APTS_TestDataFactory.createAgreement(testContact.Id, testPriceList.Id, testAccount.Id, 'Standard Deal');
        oAgr.Apttus__Status_Category__c = 'In Effect';
        oAgr.Apttus__Status__c = 'Activated';
        oAgr.Apttus__Contract_End_Date__c = system.today();
        insert oAgr;

        Apttus_Config2__PaymentTerm__c payment = new Apttus_Config2__PaymentTerm__c(APTS_Ext_ID__c = System.Label.APTS_ZOLP, Apttus_Config2__Sequence__c = 1, Apttus_Config2__Label__c = 'Net 30 Days');
        insert payment;

        APTS_Billing_Settings__c billSet = new APTS_Billing_Settings__c();
        billSet.APTS_Agreement_ID__c = oAgr.id;
        insert billSet;

        APTS_DOEPIReqWrapper oDOEPIReqWrapper = new APTS_DOEPIReqWrapper();
        oDOEPIReqWrapper.SourceOrderNumber = 'sn1232';
        oDOEPIReqWrapper.SalesforceAccountID = testAccount.Id;
        oDOEPIReqWrapper.SalesforceContactID = testContact.Id;
        oDOEPIReqWrapper.SalesforcePriceListID = testPriceList.Id;
        oDOEPIReqWrapper.SalesOrganization = 'SAP_0111';
        oDOEPIReqWrapper.AdjustmentType = 'Test Adjustment Type';
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
        oDOEPIReqWrapper.FulfilledFromVan = false;

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

        APTS_Order_Interface_Log__c oLog1 = new APTS_Order_Interface_Log__c();
        oLog1.APTS_Parent_Log__c = oLog.id;
        oLog1.APTS_Message__c = null;
        oLog1.APTS_SourceOrderNumber__c = 'sn1233';
        oLog1.APTS_Status__c = 'New';
        oLog1.APTS_Sequence__c = 1;
        insert oLog1;

    }

    @isTest static void test_method_one() {
        Group queue = APTS_DigitalOrderBatchHelper.getCSQueue();
        Map<String,Id> mapInterfacelog= new Map<String,Id>();
        List<APTS_Order_Interface_Log__c> listEPILog = [SELECT id, APTS_SourceOrderNumber__c, APTS_Message__c, APTS_Status__c FROM APTS_Order_Interface_Log__c WHERE APTS_SourceOrderNumber__c = 'sn1232'];
        APTS_Order_Error_Log__c oerr = APTS_DigitalOrderBatchHelper.createErrorLog(null, listEPILog[0].APTS_SourceOrderNumber__c, null, listEPILog[0].id, null,mapInterfacelog.get(listEPILog[0].APTS_SourceOrderNumber__c), queue);
        system.assertNotEquals(null, oerr);
        for(APTS_Order_Interface_Log__c olog:listEPILog ){
        mapInterfacelog.put(olog.APTS_SourceOrderNumber__c,olog.Id);
        }

        APTS_DigitalOrderBatchHelper.EPIOrderCreationResp oOrderResponse = APTS_DigitalOrderBatchHelper.processDigitalOrders(queue, listEPILog);
        Database.insert(oOrderResponse.mapLogIdNewOrders.values(), false);
        APTS_DigitalOrderBatchHelper.createCartAddProdcts(queue, oOrderResponse.mapDigitalWrapper, oOrderResponse.mapLogIdNewOrders,mapInterfacelog);
        APTS_DigitalOrderBatchHelper.finalizeCart(false, null,mapInterfacelog);


        APTS_DOEPIReqWrapper oWrap = oOrderResponse.mapDigitalWrapper.values()[0];
        Map<String, Product2> mapProductCodes = new Map<String, Product2>();
        for (Product2 oProd :  [SELECT id, ProductCode FROM product2 ]) {
            mapProductCodes.put(oProd.ProductCode, oProd);
        }
        APTS_DigitalOrderBatchHelper.addProductsToCart(null, null, oWrap, queue, mapProductCodes, null,mapInterfacelog);
        Map<Id, Apttus_Config2__Order__c> mapOrder = new Map<Id, Apttus_Config2__Order__c> ([select id from Apttus_Config2__Order__c]);
        APTS_DigitalOrderBatchHelper.updateOLIAndsubmit(queue, mapOrder.keySet(), null,mapInterfacelog);
    }

    @isTest static void test_method_two() {
        Group queue = [SELECT Id FROM Group LIMIT 1];
        system.assertNotEquals(null, queue);

        List<APTS_Order_Interface_Log__c> listEPILog = [SELECT id, APTS_SourceOrderNumber__c, APTS_Message__c, APTS_Status__c FROM APTS_Order_Interface_Log__c limit 1];
        system.assertNotEquals(true, listEPILog.isEmpty());

        Map<Id, APTS_DOEPIReqWrapper> mapEPI = APTS_DigitalOrderBatchHelper.getDigitalOrderData(queue, listEPILog);
        system.assertNotEquals(null, mapEPI);
        system.assertNotEquals(true, mapEPI.isEmpty());

        APTS_DOEPIReqWrapper oWrap = mapEPI.values()[0];
        oWrap.Source = 'RSOApp';
        oWrap.OrderType = 'Operating Order';
        oWrap.OrderSubType = 'Standard Order';
        oWrap.FulfilledFromVan = true;

        APTS_DigitalOrderBatchHelper.createExternalOrderHeader('rso', queue, listEPILog);
    }


    @isTest static void test_method_three() {
        Group queue = [SELECT Id FROM Group LIMIT 1];
        system.assertNotEquals(null, queue);
        
        Map<String,Id> mapInterfacelog= new Map<String,Id>();
        
        List<APTS_Order_Interface_Log__c> listEPILog = [SELECT id, APTS_SourceOrderNumber__c, APTS_Message__c, APTS_Status__c FROM APTS_Order_Interface_Log__c WHERE APTS_SourceOrderNumber__c = 'sn1232' ];
        system.assertNotEquals(true, listEPILog.isEmpty());
        for(APTS_Order_Interface_Log__c olog:listEPILog ){
        mapInterfacelog.put(olog.APTS_SourceOrderNumber__c,olog.Id);
        }
        APTS_DigitalOrderBatchHelper.EPIOrderCreationResp oResp = APTS_DigitalOrderBatchHelper.createExternalOrderHeader('Digital Order', queue, listEPILog);
        APTS_DigitalOrderBatchHelper.createCartAddProdcts(queue, oResp.mapDigitalWrapper, oResp.mapLogIdNewOrders,mapInterfacelog);
        Map<String, APTS_DOEPIReqWrapper.EPIOrderLI> mapEPIOLI = new Map<String, APTS_DOEPIReqWrapper.EPIOrderLI>();
        for (Id interfaceLogId : oResp.mapDigitalWrapper.keySet()) {
            APTS_DOEPIReqWrapper oWrap = oResp.mapDigitalWrapper.get(interfaceLogId);
            for (APTS_DOEPIReqWrapper.EPIOrderLI oEPILI : oWrap.OrderLineItems) {
                mapEPIOLI.put(oEPILI.SourceLineNumber, oEPILI);
            }
        }
        APTS_DigitalOrderBatchHelper.updateOLIAndsubmit(queue, oResp.mapLogIdNewOrders.keyset(), mapEPIOLI,mapInterfacelog);

    }

    @isTest static void test_method_four() {
        Group queue = [SELECT Id FROM Group LIMIT 1];
        system.assertNotEquals(null, queue);

        List<APTS_Order_Interface_Log__c> listEPILog = [SELECT id, APTS_SourceOrderNumber__c, APTS_Message__c, APTS_Status__c FROM APTS_Order_Interface_Log__c limit 1];
        system.assertNotEquals(true, listEPILog.isEmpty());

        APTS_DigitalOrderBatchHelper.createExternalOrderHeader('Digital Order', queue, listEPILog);

        Map<Id, Apttus_Config2__Order__c> mapOrder = new Map<Id, Apttus_Config2__Order__c> ([select id from Apttus_Config2__Order__c]);

        APTS_DigitalOrderBatchHelper.updateOLIAndsubmit(queue, mapOrder.keySet(), null,null);
    }

    @isTest static void test_method_five() {
        Group queue = [SELECT Id FROM Group LIMIT 1];
        system.assertNotEquals(null, queue);

        APTS_Order_Interface_Log__c oLog = new APTS_Order_Interface_Log__c();
        oLog.APTS_Message__c = null;
        oLog.APTS_SourceOrderNumber__c = 'sn1232';
        oLog.APTS_Status__c = 'New';
        oLog.APTS_Sequence__c = 1;
        insert oLog;

        List<APTS_Order_Interface_Log__c> listEPILog = new List<APTS_Order_Interface_Log__c>();
        listEPILog.add(oLog);

        APTS_DigitalOrderBatchHelper.getDigitalOrderData(queue, listEPILog);
        APTS_DigitalOrderBatchHelper.processdigitalorders(queue, listEPILog);
        APTS_DigitalOrderBatchHelper.createExternalOrderHeader('Digital Order', queue, listEPILog);
    }
    @isTest static void test_method_negative() {
        Group queue = [SELECT Id FROM Group LIMIT 1];
        system.assertNotEquals(null, queue);

        List<APTS_Order_Interface_Log__c> listEPILog = [SELECT id, APTS_SourceOrderNumber__c, APTS_Message__c, APTS_Status__c FROM APTS_Order_Interface_Log__c limit 1];
        system.assertNotEquals(true, listEPILog.isEmpty());

        Map<Id, APTS_DOEPIReqWrapper> mapEPI = APTS_DigitalOrderBatchHelper.getDigitalOrderData(queue, listEPILog);
        system.assertNotEquals(null, mapEPI);
        system.assertNotEquals(true, mapEPI.isEmpty());

        APTS_DOEPIReqWrapper oWrap = mapEPI.values()[0];
        oWrap.Source = 'RSOApp';
        oWrap.OrderType = 'Operating Order';
        oWrap.OrderSubType = 'Standard Order';
         oWrap.FulfilledFromVan = true;

        String sJSONClass = JSON.serialize(oWrap);
        system.debug('sJSONClass = ' + sJSONClass);

        List<APTS_Order_Interface_Log__c> oLog = new List<APTS_Order_Interface_Log__c>();
        APTS_Order_Interface_Log__c oLog1 = new APTS_Order_Interface_Log__c();
        oLog1.APTS_SourceOrderNumber__c = 'sn1232';
        oLog1.APTS_Status__c = 'New';
        oLog1.APTS_Sequence__c = 1;
        oLog1.APTS_Message__c = sJSONClass;
        oLog.add(oLog1);
        insert oLog;

        mapEPI = APTS_DigitalOrderBatchHelper.getDigitalOrderData(queue, oLog);
        APTS_DigitalOrderBatchHelper.EPIOrderCreationResp oResp = APTS_DigitalOrderBatchHelper.createExternalOrderHeader('rso', queue, oLog);
        //APTS_DigitalOrderBatchHelper.createCartAddProdcts(queue, oResp.mapDigitalWrapper, oResp.mapLogIdNewOrders);

    }

}