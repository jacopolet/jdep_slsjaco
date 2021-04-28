@isTest
private class APTS_AmendPartialOrderBatchTest {
    private static final String ACTIVATED = System.Label.APTS_Activated;
    private static final String IN_EFFECT = System.Label.APTS_In_Effect;
    private static final String STANDARD_DEAL = System.Label.APTS_Standard_Deal;
    private static final String STANDARD_ORDER = System.Label.APTS_Standard_Order;
    private static final String MACHINE_ORDER = System.Label.APTS_Machine_Order;
    private static final String NGSTANDARD_ORDER = System.Label.APTS_NGStandardOrder;
    private static final String NGMACHINE_ORDER = System.Label.APTS_NGMachineOrder;
    private static final String BEINGAMENDED = System.Label.APTS_Being_Amended;
    private static final String INSTALLATION = System.Label.APTS_Installation;
    private static final String OPTION = System.Label.APTS_Option;

    @testSetup static void setupTestData() {
        
        Apttus_Config2__ConfigLineItemCustomFields__c oConfigLineItemCustomFields = new Apttus_Config2__ConfigLineItemCustomFields__c();
        oConfigLineItemCustomFields.Name = 'System Properties';
        oConfigLineItemCustomFields.Apttus_Config2__CustomFieldNames__c = 'Apttus_Config2__HasIncentives__c';
        insert oConfigLineItemCustomFields;
        
        User oTestUser = APTS_TestFacade.createTestUser();
        APTS_TestFacade.createMandatoryRecords(oTestUser);

        Contact oContact = APTS_TestFacade.getContact();
        Account oAccount = APTS_TestFacade.getAccount();
        Opportunity oOpportunity = APTS_TestFacade.getOpportunity();
        Product2 oStandaloneProduct = APTS_TestFacade.getStandaloneProduct();
        Product2 oAllInCvrgProduct = APTS_TestFacade.getProductByName('ALL-IN COVERAGE');
        Product2 oBasicCvrgProduct = APTS_TestFacade.getProductByName('BASIC COVERAGE');
        Apttus_Config2__BillingPreference__c oBillingPreference = APTS_TestFacade.getBillingPreference();
        Apttus_Config2__PriceList__c oPriceList = APTS_TestFacade.getPriceList();
        Apttus_Config2__PriceListItem__c oPriceListItemStandalone = APTS_TestFacade.getPriceListItem(oStandaloneProduct.Id);

        Apttus_Config2__OrderSystemProperties__c oOrderSystemProperties = APTS_TestDataFactory.getOrderSystemProperties();
        oOrderSystemProperties.Apttus_Config2__EnableInflightChangesAndCancellation__c = true;
        Database.insert(oOrderSystemProperties);

        List<Apttus_Config2__Order__c> orderList = new List<Apttus_Config2__Order__c>();
        Apttus_Config2__Order__c oStandardOrder = APTS_TestDataFactory.createOrder(oAccount.Id, oPriceList.Id, oContact.Id);
        oStandardOrder.APTS_Order_Type__c = STANDARD_ORDER;
        oStandardOrder.Apttus_Config2__Status__c = 'Partially Fulfilled';
        oStandardOrder.Apttus_Config2__Description__c = 'StandardOrder';
        oStandardOrder.Apttus_Config2__PONumber__c = '1234';
        oStandardOrder.APTS_Order_Sub_Type__c = STANDARD_ORDER;
        oStandardOrder.RecordTypeId = Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByName().get(STANDARD_ORDER).getRecordTypeId();
        orderList.add(oStandardOrder);

        Database.insert(orderList);


        List<Apttus_Config2__ProductConfiguration__c> productConfigurationList = new List<Apttus_Config2__ProductConfiguration__c>();
        Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestDataFactory.createProductConfig(oStandardOrder);
        oProductConfiguration.APTS_Flow__c = NGSTANDARD_ORDER;
        oProductConfiguration.Apttus_Config2__Status__c = 'Finalized';
        productConfigurationList.add(oProductConfiguration);
        Database.insert(productConfigurationList);

        List<Apttus_Config2__LineItem__c> lineItemList = new List<Apttus_Config2__LineItem__c>();
        Apttus_Config2__LineItem__c oLineItemStandalone = APTS_TestDataFactory.createLineItem(oProductConfiguration, oPriceListItemStandalone.Id, NULL, oStandaloneProduct.Id, NULL, NULL, 1, 1, 1, 'Product/Service', oBillingPreference.Id, 'Monthly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100, 20);
        oLineItemStandalone.Apttus_Config2__PricingStatus__c = 'Completed';
        oLineItemStandalone.APTS_Requested_Delivery_Date__c = System.today();
        lineItemList.add(oLineItemStandalone);

        Apttus_Config2__LineItem__c oLineItemStandalone1 = APTS_TestDataFactory.createLineItem(oProductConfiguration, oPriceListItemStandalone.Id, NULL, oStandaloneProduct.Id, NULL, NULL, 1, 1, 1, 'Product/Service', oBillingPreference.Id, 'Monthly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100, 20);
        oLineItemStandalone1.Apttus_Config2__PricingStatus__c = 'Completed';
        oLineItemStandalone1.APTS_Requested_Delivery_Date__c = System.today();
        lineItemList.add(oLineItemStandalone1);


        Database.insert(lineItemList);

        List<Apttus_Config2__OrderLineItem__c> orderLineItemList = new List<Apttus_Config2__OrderLineItem__c>();
        Apttus_Config2__OrderLineItem__c oOrderLineItemStandalone = APTS_TestDataFactory.createOrderLineItem(oStandardOrder, oPriceListItemStandalone.Id, null, oStandaloneProduct.Id, null, null, null, 1, 1, 1, 'Product/Service', oBillingPreference.Id, 'One Time', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100.0, 10.0);
        oOrderLineItemStandalone.Apttus_Config2__IsPrimaryLine__c = true;
        oOrderLineItemStandalone.APTS_Item_Relevant_for_SAP__c = true;
        oOrderLineItemStandalone.Apttus_Config2__Status__c = 'Pending';
        oOrderLineItemStandalone.Apttus_Config2__DerivedFromId__c = oLineItemStandalone.Id;
        orderLineItemList.add(oOrderLineItemStandalone);

        Apttus_Config2__OrderLineItem__c oOrder1LineItemStandalone = APTS_TestDataFactory.createOrderLineItem(oStandardOrder, oPriceListItemStandalone.Id, null, oStandaloneProduct.Id, null, null, null, 1, 1, 1, 'Product/Service', oBillingPreference.Id, 'One Time', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100.0, 10.0);
        oOrder1LineItemStandalone.Apttus_Config2__IsPrimaryLine__c = true;
        oOrder1LineItemStandalone.APTS_Item_Relevant_for_SAP__c = true;
        oOrder1LineItemStandalone.Apttus_Config2__Status__c = 'Pending';
        oOrder1LineItemStandalone.Apttus_Config2__DerivedFromId__c = oLineItemStandalone1.Id;
        orderLineItemList.add(oOrder1LineItemStandalone);

        Database.insert(orderLineItemList);
    }


    @isTest static void partialFulfillment() {
        User oTestUser = APTS_TestFacade.getTestUser();
        Account oAccount = APTS_TestFacade.getAccount();

        Test.startTest();

        System.runAs(oTestUser) {
            Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder();
            List<Apttus_Config2__OrderLineItem__c> orderLineItemList = new List<Apttus_Config2__OrderLineItem__c>();
            for (Apttus_Config2__OrderLineItem__c oliTmp : [SELECT Id, APTS_Item_Relevant_for_SAP__c, APTS_Reason_For_Rejection__c, Apttus_Config2__OrderId__c, Apttus_Config2__Quantity__c, Apttus_Config2__FulfilledQuantity__c, Apttus_Config2__Status__c
                    FROM Apttus_Config2__OrderLineItem__c WHERE Apttus_Config2__OrderId__c = :oOrder.Id]) {
                orderLineItemList.add(oliTmp);
            }
            System.assertNotEquals(TRUE, orderLineItemList.isEmpty());

            Apttus_Config2__OrderFulfillment__c oOrderFulfillment = APTS_TestDataFactory.createOrderFulfillment(oAccount.Id);
            Database.insert(oOrderFulfillment);

            List<Apttus_Config2__OrderFulfillmentLineItem__c> orderFulfillmentLineItemList = new List<Apttus_Config2__OrderFulfillmentLineItem__c>();
            Apttus_Config2__OrderFulfillmentLineItem__c oOrderBundleFulfillmentLineItem = APTS_TestDataFactory.createOrderFLI(oOrder.Id, orderLineItemList[0].Id, oOrderFulfillment.Id);
            oOrderBundleFulfillmentLineItem.APTS_Fulfilled_Quantity__c = 1;
            oOrderBundleFulfillmentLineItem.APTS_GoodsIssue_Status__c = 'Not yet processed';
            oOrderBundleFulfillmentLineItem.APTS_POD_Status__c = 'Not Relevant';
            orderFulfillmentLineItemList.add(oOrderBundleFulfillmentLineItem);
            System.assertNotEquals(TRUE, orderFulfillmentLineItemList.isEmpty());

            Apttus_Config2__OrderFulfillmentLineItem__c oOrderOptionFulfillmentLineItem = APTS_TestDataFactory.createOrderFLI(oOrder.Id, orderLineItemList[1].Id, oOrderFulfillment.Id);
            oOrderOptionFulfillmentLineItem.APTS_Fulfilled_Quantity__c = 1;
            oOrderOptionFulfillmentLineItem.APTS_GoodsIssue_Status__c = 'Not yet processed';
            oOrderOptionFulfillmentLineItem.APTS_POD_Status__c = 'Not Relevant';
            orderFulfillmentLineItemList.add(oOrderOptionFulfillmentLineItem);
            Database.insert(orderFulfillmentLineItemList);

            for (Apttus_Config2__OrderFulfillmentLineItem__c oOrderFulfillmentLineItem : orderFulfillmentLineItemList) {
                oOrderFulfillmentLineItem.APTS_GoodsIssue_Status__c = 'Completely processed';
                oOrderFulfillmentLineItem.APTS_POD_Status__c = 'Completely processed';
                oOrderFulfillmentLineItem.APTS_GoodsIssue_Date__c = Date.today();
            }
            Database.update(orderFulfillmentLineItemList);

            Apttus_Config2__OrderLineItem__c oli = new Apttus_Config2__OrderLineItem__c();
            oli.Id = orderLineItemList[0].Id;
            oli.Apttus_Config2__Status__c = 'Partially Fulfilled';
            oli.Apttus_Config2__FulfilledQuantity__c = 1;
            oli.APTS_Item_Relevant_for_SAP__c = true;
            Database.update(oli);
            Apttus_Config2__OrderLineItem__c olii = new Apttus_Config2__OrderLineItem__c();
            olii.Id = orderLineItemList[1].Id;
            olii.Apttus_Config2__Status__c = 'Partially Fulfilled';
            olii.Apttus_Config2__FulfilledQuantity__c = 1;
            olii.APTS_Item_Relevant_for_SAP__c = true;
            Database.update(olii);


            oOrder.APTS_IsPGICompleted__c = true;
            oOrder.APTS_Order_Type__c = 'Standard Order';
            oOrder.Apttus_Config2__Status__c = 'Partially Fulfilled';
            update oOrder;

            List<Apttus_Config2__Order__c> listOrder = [SELECT Id, APTS_IsPGICompleted__c, Apttus_Config2__Status__c FROM Apttus_Config2__Order__c WHERE APTS_IsPGICompleted__c = true];
            
            APTS_AmendPartialOrderBatch batch2 = new APTS_AmendPartialOrderBatch();
            Database.executeBatch(batch2, 2);
        }

        Test.stopTest();
    }
    
    @isTest static void allCancelled() {
        User oTestUser = APTS_TestFacade.getTestUser();
        Account oAccount = APTS_TestFacade.getAccount();

        Test.startTest();

        System.runAs(oTestUser) {
            Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder();
            List<Apttus_Config2__OrderLineItem__c> orderLineItemList = new List<Apttus_Config2__OrderLineItem__c>();
            for (Apttus_Config2__OrderLineItem__c oliTmp : [SELECT Id, APTS_Item_Relevant_for_SAP__c, APTS_Reason_For_Rejection__c, Apttus_Config2__OrderId__c, Apttus_Config2__Quantity__c, Apttus_Config2__FulfilledQuantity__c, Apttus_Config2__Status__c
                    FROM Apttus_Config2__OrderLineItem__c WHERE Apttus_Config2__OrderId__c = :oOrder.Id]) {
                orderLineItemList.add(oliTmp);
            }
            System.assertNotEquals(TRUE, orderLineItemList.isEmpty());
            Apttus_Config2__OrderLineItem__c oli = new Apttus_Config2__OrderLineItem__c();
            oli.Id = orderLineItemList[0].Id;
            oli.APTS_Reason_For_Rejection__c = 'C6';
            oli.Apttus_Config2__FulfilledQuantity__c = 0;
            oli.APTS_Item_Relevant_for_SAP__c = true;
            Database.update(oli);
            Apttus_Config2__OrderLineItem__c olii = new Apttus_Config2__OrderLineItem__c();
            olii.Id = orderLineItemList[1].Id;
            olii.APTS_Reason_For_Rejection__c = 'C6';
            olii.Apttus_Config2__FulfilledQuantity__c = 0;
            olii.APTS_Item_Relevant_for_SAP__c = true;
            Database.update(olii);
            

            oOrder.Apttus_Config2__Status__c = 'Pending';
            oOrder.APTS_Order_Type__c = 'Standard Order';
            update oOrder;

            List<Apttus_Config2__Order__c> listOrder = [SELECT Id, APTS_IsPGICompleted__c, Apttus_Config2__Status__c FROM Apttus_Config2__Order__c WHERE APTS_IsPGICompleted__c = true];
            
            APTS_AmendPartialOrderBatch batch2 = new APTS_AmendPartialOrderBatch();
            Database.executeBatch(batch2, 2);
        }

        Test.stopTest();
    }
    
    
    @isTest static void partialAndFulfilled() {
        User oTestUser = APTS_TestFacade.getTestUser();
        Account oAccount = APTS_TestFacade.getAccount();

        Test.startTest();

        System.runAs(oTestUser) {
            Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder();
            List<Apttus_Config2__OrderLineItem__c> orderLineItemList = new List<Apttus_Config2__OrderLineItem__c>();
            for (Apttus_Config2__OrderLineItem__c oliTmp : [SELECT Id,  APTS_Reason_For_Rejection__c, Apttus_Config2__OrderId__c, Apttus_Config2__Quantity__c, Apttus_Config2__FulfilledQuantity__c, Apttus_Config2__Status__c
                    FROM Apttus_Config2__OrderLineItem__c WHERE Apttus_Config2__OrderId__c = :oOrder.Id]) {
                orderLineItemList.add(oliTmp);
            }
            System.assertNotEquals(TRUE, orderLineItemList.isEmpty());

            Apttus_Config2__OrderFulfillment__c oOrderFulfillment = APTS_TestDataFactory.createOrderFulfillment(oAccount.Id);
            Database.insert(oOrderFulfillment);

            List<Apttus_Config2__OrderFulfillmentLineItem__c> orderFulfillmentLineItemList = new List<Apttus_Config2__OrderFulfillmentLineItem__c>();
            Apttus_Config2__OrderFulfillmentLineItem__c oOrderBundleFulfillmentLineItem = APTS_TestDataFactory.createOrderFLI(oOrder.Id, orderLineItemList[0].Id, oOrderFulfillment.Id);
            oOrderBundleFulfillmentLineItem.APTS_Fulfilled_Quantity__c = 1;
            oOrderBundleFulfillmentLineItem.APTS_GoodsIssue_Status__c = 'Not yet processed';
            oOrderBundleFulfillmentLineItem.APTS_POD_Status__c = 'Not Relevant';
            orderFulfillmentLineItemList.add(oOrderBundleFulfillmentLineItem);
            System.assertNotEquals(TRUE, orderFulfillmentLineItemList.isEmpty());

            Apttus_Config2__OrderFulfillmentLineItem__c oOrderOptionFulfillmentLineItem = APTS_TestDataFactory.createOrderFLI(oOrder.Id, orderLineItemList[1].Id, oOrderFulfillment.Id);
            oOrderOptionFulfillmentLineItem.APTS_Fulfilled_Quantity__c = 1;
            oOrderOptionFulfillmentLineItem.APTS_GoodsIssue_Status__c = 'Not yet processed';
            oOrderOptionFulfillmentLineItem.APTS_POD_Status__c = 'Not Relevant';
            orderFulfillmentLineItemList.add(oOrderOptionFulfillmentLineItem);
            Database.insert(orderFulfillmentLineItemList);

            for (Apttus_Config2__OrderFulfillmentLineItem__c oOrderFulfillmentLineItem : orderFulfillmentLineItemList) {
                oOrderFulfillmentLineItem.APTS_GoodsIssue_Status__c = 'Completely processed';
                oOrderFulfillmentLineItem.APTS_POD_Status__c = 'Completely processed';
                oOrderFulfillmentLineItem.APTS_GoodsIssue_Date__c = Date.today();
            }
            Database.update(orderFulfillmentLineItemList);

            Apttus_Config2__OrderLineItem__c oli = new Apttus_Config2__OrderLineItem__c();
            oli.Id = orderLineItemList[0].Id;
            oli.Apttus_Config2__Status__c = 'Fulfilled';
            oli.Apttus_Config2__FulfilledQuantity__c = 1;
            Database.update(oli);
            Apttus_Config2__OrderLineItem__c olii = new Apttus_Config2__OrderLineItem__c();
            olii.Id = orderLineItemList[1].Id;
            olii.Apttus_Config2__Status__c = 'Partially Fulfilled';
            olii.Apttus_Config2__FulfilledQuantity__c = 1;
            Database.update(olii);


            oOrder.APTS_IsPGICompleted__c = true;
            update oOrder;

            List<Apttus_Config2__Order__c> listOrder = [SELECT Id, APTS_IsPGICompleted__c, Apttus_Config2__Status__c FROM Apttus_Config2__Order__c WHERE APTS_IsPGICompleted__c = true];
            
            APTS_AmendPartialOrderBatch batch2 = new APTS_AmendPartialOrderBatch();
            Database.executeBatch(batch2, 2);
        }

        Test.stopTest();
    }
    
    @isTest static void partialAndCancelled() {
        User oTestUser = APTS_TestFacade.getTestUser();
        Account oAccount = APTS_TestFacade.getAccount();

        Test.startTest();

        System.runAs(oTestUser) {
            Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder();
            List<Apttus_Config2__OrderLineItem__c> orderLineItemList = new List<Apttus_Config2__OrderLineItem__c>();
            for (Apttus_Config2__OrderLineItem__c oliTmp : [SELECT Id,  APTS_Reason_For_Rejection__c, Apttus_Config2__OrderId__c, Apttus_Config2__Quantity__c, Apttus_Config2__FulfilledQuantity__c, Apttus_Config2__Status__c
                    FROM Apttus_Config2__OrderLineItem__c WHERE Apttus_Config2__OrderId__c = :oOrder.Id]) {
                orderLineItemList.add(oliTmp);
            }
            System.assertNotEquals(TRUE, orderLineItemList.isEmpty());

            Apttus_Config2__OrderFulfillment__c oOrderFulfillment = APTS_TestDataFactory.createOrderFulfillment(oAccount.Id);
            Database.insert(oOrderFulfillment);

            List<Apttus_Config2__OrderFulfillmentLineItem__c> orderFulfillmentLineItemList = new List<Apttus_Config2__OrderFulfillmentLineItem__c>();
            Apttus_Config2__OrderFulfillmentLineItem__c oOrderBundleFulfillmentLineItem = APTS_TestDataFactory.createOrderFLI(oOrder.Id, orderLineItemList[0].Id, oOrderFulfillment.Id);
            oOrderBundleFulfillmentLineItem.APTS_Fulfilled_Quantity__c = 1;
            oOrderBundleFulfillmentLineItem.APTS_GoodsIssue_Status__c = 'Not yet processed';
            oOrderBundleFulfillmentLineItem.APTS_POD_Status__c = 'Not Relevant';
            orderFulfillmentLineItemList.add(oOrderBundleFulfillmentLineItem);
            System.assertNotEquals(TRUE, orderFulfillmentLineItemList.isEmpty());

            Apttus_Config2__OrderFulfillmentLineItem__c oOrderOptionFulfillmentLineItem = APTS_TestDataFactory.createOrderFLI(oOrder.Id, orderLineItemList[1].Id, oOrderFulfillment.Id);
            oOrderOptionFulfillmentLineItem.APTS_Fulfilled_Quantity__c = 1;
            oOrderOptionFulfillmentLineItem.APTS_GoodsIssue_Status__c = 'Not yet processed';
            oOrderOptionFulfillmentLineItem.APTS_POD_Status__c = 'Not Relevant';
            orderFulfillmentLineItemList.add(oOrderOptionFulfillmentLineItem);
            Database.insert(orderFulfillmentLineItemList);

            for (Apttus_Config2__OrderFulfillmentLineItem__c oOrderFulfillmentLineItem : orderFulfillmentLineItemList) {
                oOrderFulfillmentLineItem.APTS_GoodsIssue_Status__c = 'Completely processed';
                oOrderFulfillmentLineItem.APTS_POD_Status__c = 'Completely processed';
                oOrderFulfillmentLineItem.APTS_GoodsIssue_Date__c = Date.today();
            }
            Database.update(orderFulfillmentLineItemList);

            Apttus_Config2__OrderLineItem__c oli = new Apttus_Config2__OrderLineItem__c();
            oli.Id = orderLineItemList[0].Id;
            oli.Apttus_Config2__Status__c = 'Partially Fulfilled';
            oli.Apttus_Config2__FulfilledQuantity__c = 1;
            Database.update(oli);
            Apttus_Config2__OrderLineItem__c olii = new Apttus_Config2__OrderLineItem__c();
            olii.Id = orderLineItemList[1].Id;
            olii.APTS_Reason_For_Rejection__c = 'C6';
            olii.Apttus_Config2__FulfilledQuantity__c = 0;
            Database.update(olii);


            oOrder.APTS_IsPGICompleted__c = true;
            update oOrder;

            List<Apttus_Config2__Order__c> listOrder = [SELECT Id, APTS_IsPGICompleted__c, Apttus_Config2__Status__c FROM Apttus_Config2__Order__c WHERE APTS_IsPGICompleted__c = true];
            
            APTS_AmendPartialOrderBatch batch2 = new APTS_AmendPartialOrderBatch();
            Database.executeBatch(batch2, 2);
        }

        Test.stopTest();
    }
    
}