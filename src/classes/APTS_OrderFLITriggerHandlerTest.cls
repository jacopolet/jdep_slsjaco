/*************************************************************
@Name: APTS_OrderFLITriggerHandlerTest
@Author: Galin Georgiev
@CreateDate: 26-04-2018
@Description: Order Fulfilment Line Item Trigger Handler Test
@UsedBy: APTS_OrderFLITriggerHandler
******************************************************************/
//v100 26-04-2018 Galin Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes

@isTest
private with sharing class APTS_OrderFLITriggerHandlerTest {

    @testSetup static void setupTestData() {

        User oTestUser = APTS_TestFacade.createTestUser();
        APTS_TestFacade.createMandatoryRecords(oTestUser);
        APTS_TestFacade.createAndConfigureOrder(oTestUser);
        System.assert(oTestUser != Null);
    }

    @isTest static void test_OrderFLITriggerHandler() {

        User oTestUser = APTS_TestFacade.getTestUser();
        Account oAccount = APTS_TestFacade.getAccount();

        Test.startTest();

        System.runAs(oTestUser) {

            Apttus_Config2__Order__c oOrder = APTS_TestFacade.getMachineOrder();
            List<Apttus_Config2__OrderLineItem__c> orderLineItemList = APTS_TestFacade.getOrderLineItemList(oOrder.Id);
            System.assertNotEquals(TRUE, orderLineItemList.isEmpty());

            Apttus_Config2__OrderFulfillment__c oOrderFulfillment = APTS_TestDataFactory.createOrderFulfillment(oAccount.Id);
            Database.insert(oOrderFulfillment);

            List<Apttus_Config2__OrderFulfillmentLineItem__c> orderFulfillmentLineItemList = new List<Apttus_Config2__OrderFulfillmentLineItem__c>();
            Apttus_Config2__OrderFulfillmentLineItem__c oOrderBundleFulfillmentLineItem = APTS_TestDataFactory.createOrderFLI(oOrder.Id, orderLineItemList[0].Id, oOrderFulfillment.Id);
            oOrderBundleFulfillmentLineItem.APTS_Fulfilled_Quantity__c = null;
            oOrderBundleFulfillmentLineItem.APTS_GoodsIssue_Status__c = 'Not yet processed';
            oOrderBundleFulfillmentLineItem.APTS_POD_Status__c = 'Not Relevant';
            orderFulfillmentLineItemList.add(oOrderBundleFulfillmentLineItem);
            System.assertNotEquals(TRUE, orderFulfillmentLineItemList.isEmpty());

            Apttus_Config2__OrderFulfillmentLineItem__c oOrderOptionFulfillmentLineItem = APTS_TestDataFactory.createOrderFLI(oOrder.Id, orderLineItemList[1].Id, oOrderFulfillment.Id);
            oOrderOptionFulfillmentLineItem.APTS_Fulfilled_Quantity__c = null;
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
        }

        Test.stopTest();
    }

    @isTest static void test_Delete() {

        User oTestUser = APTS_TestFacade.getTestUser();
        System.assert(oTestUser != Null);

        Test.startTest();

        System.runAs(oTestUser) {

            APTS_OrderFLITriggerHandler oOrderFLITriggerHandler = new APTS_OrderFLITriggerHandler();
            oOrderFLITriggerHandler.afterDelete(null, null);
            oOrderFLITriggerHandler.afterUndelete(null, null);
            oOrderFLITriggerHandler.beforeDelete(null, null);
        }

        Test.stopTest();
    }
    @isTest static void test_OrderFLITriggerHandlerNoOFLI() {

        User oTestUser = APTS_TestFacade.getTestUser();
        Account oAccount = APTS_TestFacade.getAccount();

        Test.startTest();

        System.runAs(oTestUser) {

            Apttus_Config2__Order__c oOrder = APTS_TestFacade.getMachineOrder();
            oOrder.APTS_SAP_OrderType__c = 'XB13';
            update oOrder;

            List<Apttus_Config2__OrderLineItem__c> orderLineItemList = APTS_TestFacade.getOrderLineItemList(oOrder.Id);
            orderLineItemList[0].APTS_Item_Relevant_for_SAP__c = false;
            orderLineItemList[0].APTS_Type_of_Contract__c = 'Subscription';
            update orderLineItemList;
            Apttus_Config2__OrderFulfillment__c oOrderFulfillment = APTS_TestDataFactory.createOrderFulfillment(oAccount.Id);
            Database.insert(oOrderFulfillment);

            List<Apttus_Config2__OrderFulfillmentLineItem__c> orderFulfillmentLineItemList = new List<Apttus_Config2__OrderFulfillmentLineItem__c>();
            Apttus_Config2__OrderFulfillmentLineItem__c oOrderBundleFulfillmentLineItem = APTS_TestDataFactory.createOrderFLI(oOrder.Id, orderLineItemList[0].Id, oOrderFulfillment.Id);
            oOrderBundleFulfillmentLineItem.APTS_Fulfilled_Quantity__c = null;
            oOrderBundleFulfillmentLineItem.APTS_GoodsIssue_Status__c = 'Not yet processed';
            oOrderBundleFulfillmentLineItem.APTS_POD_Status__c = 'Not Relevant';
            orderFulfillmentLineItemList.add(oOrderBundleFulfillmentLineItem);
            System.assertNotEquals(TRUE, orderFulfillmentLineItemList.isEmpty());

            Apttus_Config2__OrderFulfillmentLineItem__c oOrderOptionFulfillmentLineItem = APTS_TestDataFactory.createOrderFLI(oOrder.Id, orderLineItemList[1].Id, oOrderFulfillment.Id);
            oOrderOptionFulfillmentLineItem.APTS_Fulfilled_Quantity__c = null;
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

            Test.stopTest();
        }

    }
    
     @isTest static void test_OrderFLITriggerHandler2() {

        User oTestUser = APTS_TestFacade.getTestUser();
        Account oAccount = APTS_TestFacade.getAccount();

        Test.startTest();

        System.runAs(oTestUser) {

            Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder();
            oOrder.APTS_Order_Type__c = 'Standard Order';
            oOrder.Apttus_Config2__Status__c = 'In Fulfilment';
            update oOrder;
            Map<id, Apttus_Config2__Order__c> mapOrder = new Map<id, Apttus_Config2__Order__c>();
            maporder.put(oOrder.id, oOrder);
            List<Apttus_Config2__OrderLineItem__c> orderLineItemList = APTS_TestFacade.getOrderLineItemList(oOrder.Id);
            System.assertNotEquals(TRUE, orderLineItemList.isEmpty());
            
            orderLineItemList[0].APTS_Item_Relevant_for_SAP__c = true;
            orderLineItemList[0].Apttus_Config2__Status__c = 'Fulfilled';
            orderLineItemList[0].Apttus_Config2__FulfilledQuantity__c = 1;
            update orderLineItemList[0];

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
            
            Apttus_Config2__OrderFulfillmentLineItem__c oOrderOptionFulfillmentLineItem2 = APTS_TestDataFactory.createOrderFLI(oOrder.Id, orderLineItemList[1].Id, oOrderFulfillment.Id);
            oOrderOptionFulfillmentLineItem2.APTS_Fulfilled_Quantity__c = 1;
            oOrderOptionFulfillmentLineItem2.APTS_GoodsIssue_Status__c = 'Completely processed';
            oOrderOptionFulfillmentLineItem2.APTS_POD_Status__c = 'Not Relevant';
            orderFulfillmentLineItemList.add(oOrderOptionFulfillmentLineItem2);
            Database.insert(orderFulfillmentLineItemList);

            for (Apttus_Config2__OrderFulfillmentLineItem__c oOrderFulfillmentLineItem : orderFulfillmentLineItemList) {

                oOrderFulfillmentLineItem.APTS_GoodsIssue_Status__c = 'Completely processed';
                oOrderFulfillmentLineItem.APTS_POD_Status__c = 'Completely processed';
                oOrderFulfillmentLineItem.APTS_GoodsIssue_Date__c = Date.today();
            }

            Database.update(orderFulfillmentLineItemList);
            Map<id,Apttus_Config2__OrderLineItem__c> orderLineItemToUpdateMap = new Map<id,Apttus_Config2__OrderLineItem__c>();
            orderLineItemToUpdateMap.put(orderLineItemList[0].Id, orderLineItemList[0]);
            Set<Id> OLIID = new Set<Id>();           
            OLIID.add(orderLineItemList[0].Id);
            APTS_OrderFLITriggerHandler ooFLI = new APTS_OrderFLITriggerHandler();
            ooFLI.getOrderLineItems(OLIID);
            ooFLI.setAuthorizedDate(orderLineItemList, orderLineItemList[0].Id, system.today(), false);
            ooFLI.setAuthorizedDate(orderLineItemList, orderLineItemList[0].Id, system.today(), true);
           ooFLI.activateIngredientOrders(maporder, orderLineItemToUpdateMap, maporder.keySet());
    
        }

        Test.stopTest();
    }

}