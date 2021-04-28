@isTest
private class APTS_RepriceFinalizationQueueTest {

    @testSetup static void setupTestData() {
        // create billingprefrence
        Apttus_Config2__BillingPreference__c billPref = APTS_TestDataFactory.createBillingPrefrence('JDETestPrefrence');
        insert billPref;

        // create account
        Account oAccount = APTS_TestDataFactory.createAccount('JDETestAccount');
        insert oAccount;

        // create contact
        Contact oContact = APTS_TestDataFactory.createContact(oAccount, '1010101011');
        insert oContact;

        // create opportunity
        opportunity opportunityObj = APTS_TestDataFactory.createOpportunity('JDETestOpportunity', oAccount.Id);
        insert opportunityObj;

        //create price list
        Apttus_Config2__PriceList__c pricelist = APTS_TestDataFactory.createPriceList('JDETest Price List');
        insert pricelist;

        //Create Products
        Product2 prod1 = APTS_TestDataFactory.createProduct('Test1', '101', 'Ingredients', 'Standalone', FALSE, FALSE);
        insert prod1;

        //Create Price List Items
        Apttus_Config2__PriceListItem__c pli1 = APTS_TestDataFactory.createPriceListItem(priceList.Id, prod1.Id);
        insert pli1;

        Apttus_Config2__Order__c order = APTS_TestDataFactory.createOrder(oAccount.Id, pricelist.Id, oContact.Id);
        order.APTS_Order_Sub_Type__c = 'Technical Swap';
        order.APTS_Order_Type__c = 'Machine Order';
        order.APTS_SAP_OrderType__c = 'XA13';
        insert order;

        Apttus_Config2__Order__c childOrder = APTS_TestDataFactory.createOrder(oAccount.Id, pricelist.Id, oContact.Id);
        childOrder.APTS_Order_Sub_Type__c = 'Technical Swap';
        childOrder.APTS_Order_Type__c = 'Machine Order';
        childOrder.APTS_SAP_OrderType__c = 'XB13';
        childOrder.Apttus_Config2__ParentOrderId__c = order.Id;
        insert childOrder;

        Apttus_Config2__ProductConfiguration__c config = APTS_TestDataFactory.createProductConfig(order);
        insert config;

        Apttus_Config2__ProductConfiguration__c childConfig = APTS_TestDataFactory.createProductConfig(childOrder);
        insert childConfig;

        Apttus_Config2__LineItem__c line1 = APTS_TestDataFactory.createLineItem(config, pli1.id, null, prod1.Id, null, null, 1, 1, 1, 'Product/Service', billPref.Id, 'One Time', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100.0, 10.0);
        line1.Apttus_Config2__IsPrimaryLine__c = true;
        insert line1;

        Apttus_Config2__LineItem__c line2 = APTS_TestDataFactory.createLineItem(childConfig, pli1.id, null, prod1.Id, null, null, 1, 1, 1, 'Product/Service', billPref.Id, 'One Time', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100.0, 10.0);
        line2.Apttus_Config2__IsPrimaryLine__c = true;
        insert line2;

        Apttus_Config2__OrderLineItem__c orderline1 = APTS_TestDataFactory.createOrderLineItem(order, pli1.Id, null, prod1.Id, null, null, null, 1, 1, 1, 'Product/Service', billPref.Id, 'One Time', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100.0, 10.0);
        orderline1.Apttus_Config2__IsPrimaryLine__c = true;
        insert orderline1;
    }

    static testMethod void repriceAndFinalize() {
        List<Apttus_Config2__Order__c> listOrder = [SELECT id FROM Apttus_Config2__Order__c WHERE Apttus_Config2__BillToAccountId__r.Name = 'JDETestAccount' AND APTS_SAP_OrderType__c = 'XB13' ORDER BY CreatedDate DESC LIMIT 1];
        System.assertEquals(TRUE, !listOrder.isEmpty());

        List<Apttus_Config2__ProductConfiguration__c> listConfig = [SELECT id FROM Apttus_Config2__ProductConfiguration__c WHERE Apttus_Config2__OrderId__c = : listOrder[0].Id];
        System.assertEquals(TRUE, !listConfig.isEmpty());

        Test.startTest();
        System.enqueueJob(new APTS_RepriceFinalizationQueue(listConfig[0].Id));
        System.enqueueJob(new APTS_RepriceFinalizationQueue(listConfig[0].Id, listOrder[0].Id, true));
        Test.stopTest();

        System.assertEquals(1, [SELECT count() FROM Apttus_Config2__ProductConfiguration__c WHERE Apttus_Config2__OrderId__c = : listOrder[0].Id AND Apttus_Config2__Status__c = 'Finalized']);
    }


    static testMethod void repriceAndFinalizeDigital() {
        
        List<Apttus_Config2__ProductConfiguration__c> listConfig = [SELECT id FROM Apttus_Config2__ProductConfiguration__c];
        System.assertEquals(TRUE, !listConfig.isEmpty());

        Test.startTest();
        System.enqueueJob(new APTS_RepriceFinalizationQueue(listConfig[0].Id, 'Digital', 'Pricing'));
        System.enqueueJob(new APTS_RepriceFinalizationQueue(listConfig[0].Id, 'Digital', 'Finalize'));
        System.enqueueJob(new APTS_RepriceFinalizationQueue(listConfig[0].Id, 'Digital', 'Submit'));
        Test.stopTest();

        System.assertEquals(1, [SELECT count() FROM Apttus_Config2__ProductConfiguration__c WHERE Id = :listConfig[0].Id AND Apttus_Config2__Status__c = 'Finalized']);
    }

}