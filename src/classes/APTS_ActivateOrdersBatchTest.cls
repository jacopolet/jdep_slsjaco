/*************************************************************
@Name: APTS_ActivateOrdersBatchTest
@Author: Galin Georgiev
@CreateDate: 28-08-2018
@Description: Set instalation date batch test
@UsedBy: APTS_ActivateOrdersBatch
******************************************************************/
//v100 28-08-2018 Galin Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> mPeans end of changes
@isTest
private with sharing class APTS_ActivateOrdersBatchTest {

    @testSetup static void setupTestData() {

        User oTestUser = APTS_TestFacade.createTestUser();
        APTS_TestFacade.createMandatoryRecords(oTestUser);
        APTS_TestFacade.createAndConfigureOrder(oTestUser);
    }

   @isTest static void test_ActivateOrdersBatch() {

        User oTestUser = APTS_TestFacade.getTestUser();        
        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder();
        
        List<Apttus_Config2__OrderLineItem__c> orderLineItemList = APTS_TestFacade.getOrderLineItemList(oOrder.Id);

        orderLineItemList[0].APTS_Installation_Date_Authorized__c = Datetime.now();
        orderLineItemList[0].Apttus_Config2__Status__c = 'Fulfilled';
        orderLineItemList[0].Apttus_Config2__IsPrimaryLine__c = false;
        orderLineItemList[0].APTS_De_installation_Date_Authorized__c = date.today() + 10;
        System.assert(orderLineItemList[0] != Null);


        orderLineItemList[1].APTS_Installation_Date_Authorized__c = Datetime.now();
        orderLineItemList[1].Apttus_Config2__Status__c = 'Fulfilled';        
        orderLineItemList[1].APTS_De_installation_Date_Authorized__c = date.today() + 10; 
        System.assert(orderLineItemList[1] != Null);
  

        orderLineItemList[2].Apttus_Config2__HasOptions__c = true;                     

        APTS_OrderUtils.stopOrderLineItemTrigger();
        Database.update(orderLineItemList);
        APTS_OrderUtils.startOrderLineItemTrigger();
        
        test.startTest();

        System.runAs(oTestUser) {

            APTS_ActivateOrdersBatch oActivateOrdersBatch = new APTS_ActivateOrdersBatch();
            Database.executebatch(oActivateOrdersBatch);
        }

        test.stopTest();
    }
    @isTest static void test_ActivateOrdersBatch_deinstall() {

        User oTestUser = APTS_TestFacade.getTestUser();        
        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder();
        
        List<Apttus_Config2__OrderLineItem__c> orderLineItemList = APTS_TestFacade.getOrderLineItemList(oOrder.Id);

        orderLineItemList[0].APTS_Installation_Date_Authorized__c = Datetime.now();
        orderLineItemList[0].Apttus_Config2__Status__c = 'Fulfilled';
        orderLineItemList[0].Apttus_Config2__IsPrimaryLine__c = false;
        orderLineItemList[0].APTS_De_installation_Date_Authorized__c = date.today() + 10;
        orderLineItemList[0].APTS_SAP_OrderType__c = 'XB13';        

        APTS_OrderUtils.stopOrderLineItemTrigger();
        Database.update(orderLineItemList);
        APTS_OrderUtils.startOrderLineItemTrigger();
        
        test.startTest();

        System.runAs(oTestUser) {

            APTS_ActivateOrdersBatch oActivateOrdersBatch = new APTS_ActivateOrdersBatch();
            Database.executebatch(oActivateOrdersBatch);
        }

        test.stopTest();
    }
}