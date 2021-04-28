/*************************************************************
    @Name: APTS_ActivateOrderQueueableTest
    @Author: Galin Georgiev
    @CreateDate: 28-08-2018
    @Description: Set instalation date batch test
    @UsedBy: APTS_ActivateOrderQueueable
    ******************************************************************/
    //v100 28-08-2018 Galin Georgiev: Initial version.
    //Comments in this format are mandatory for each change of code.
    //Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
    //Removing code comment example: v100--<< means start of changes and v100-->> mPeans end of changes
    @isTest
    private with sharing class APTS_ActivateOrderQueueableTest {

        @testSetup static void setupTestData() {

            User oTestUser = APTS_TestFacade.createTestUser();
            APTS_TestFacade.createMandatoryRecords(oTestUser);
            APTS_TestFacade.createAndConfigureOrder(oTestUser);
        }

        @isTest static void test_ActivateOrderQueueable() {

            User oTestUser = APTS_TestFacade.getTestUser();
            Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder();
            List<Apttus_Config2__OrderLineItem__c> orderLineItemList = APTS_TestFacade.getOrderLineItemList(oOrder.Id);
            orderLineItemList[0].APTS_Installation_Date_Authorized__c = Datetime.now();
             orderLineItemList[0].Apttus_Config2__OrderId__r.APTS_Order_Type__c = 'Admin Order';
            List<Apttus_Config2__OrderLineItem__c> orderLineItemListToTest = new List<Apttus_Config2__OrderLineItem__c>();
            List<Apttus_Config2__OrderLineItem__c> orderLineItemListToTest1 = new List<Apttus_Config2__OrderLineItem__c>();
            orderLineItemListToTest.add(orderLineItemList[0]);

            test.startTest();
            System.runAs(oTestUser) {
                System.assertNotEquals(NULL, orderLineItemListToTest);
                System.assertNotEquals(NULL, orderLineItemListToTest.isEmpty());
                System.enqueueJob(new APTS_ActivateOrderQueueable(orderLineItemListToTest));
                System.enqueueJob(new APTS_ActivateOrderQueueable(orderLineItemListToTest1));
            }
            test.stopTest();        
        }
        
        @isTest static void test_ActivateOrderQueueable1() {

            User oTestUser = APTS_TestFacade.getTestUser();
            Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder();
            List<Apttus_Config2__OrderLineItem__c> orderLineItemList = APTS_TestFacade.getOrderLineItemList(oOrder.Id);
            orderLineItemList[0].Apttus_Config2__ItemSequence__c = null;
             orderLineItemList[0].Apttus_Config2__OrderId__r.APTS_Order_Type__c = 'Admin Order';
            List<Apttus_Config2__OrderLineItem__c> orderLineItemListToTest = new List<Apttus_Config2__OrderLineItem__c>();
            orderLineItemListToTest.add(orderLineItemList[0]);

            test.startTest();
            System.runAs(oTestUser) {
                System.assertNotEquals(NULL, orderLineItemListToTest);
                System.assertNotEquals(NULL, orderLineItemListToTest.isEmpty());
                System.enqueueJob(new APTS_ActivateOrderQueueable(orderLineItemListToTest));
            }
            test.stopTest();        
        }
        @isTest static void test_ActivateOrderQueueable2() {

            User oTestUser = APTS_TestFacade.getTestUser();
            Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder();
            List<Apttus_Config2__OrderLineItem__c> orderLineItemList = APTS_TestFacade.getOrderLineItemList(oOrder.Id);
            orderLineItemList[0].Apttus_Config2__ItemSequence__c = null;
            orderLineItemList[0].Apttus_Config2__OrderId__r.APTS_Order_Type__c = 'Admin Order';
            oOrder.id= orderLineItemList[0].Apttus_Config2__OrderId__c;
            oOrder.APTS_Accept_Order_Check__c = false;
            List<Apttus_Config2__OrderLineItem__c> orderLineItemListToTest = new List<Apttus_Config2__OrderLineItem__c>();
            orderLineItemListToTest.add(orderLineItemList[0]);

            test.startTest();
            System.runAs(oTestUser) {
                System.assertNotEquals(NULL, orderLineItemListToTest);
                System.assertNotEquals(NULL, orderLineItemListToTest.isEmpty());
                System.enqueueJob(new APTS_ActivateOrderQueueable(orderLineItemListToTest,'Admin Order'));
            }
            test.stopTest();        
        }
        
    }