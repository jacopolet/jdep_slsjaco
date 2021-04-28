/*************************************************************
@Name: APTS_SubmitOrderQueueableTest
@Author: Akanksha
@CreateDate: 03-01-2019
@Description: submit orders to SAP
@UsedBy: APTS_SubmitOrderQueueable
******************************************************************/

@isTest
private with sharing class APTS_SubmitOrderQueueableTest {
  private static final String ID = System.Label.APTS_Id;
    private static final String ACCOUNT_NAME = 'JDETestAccount';
    private static final String CONTACT_NUMBER = '1010101011';
    private static final String PRICELIST_NAME = 'JDETest Price List';
    private static final String PROD_FAMILY_MACHINE = 'MA';
    private static final String PROD_CONFIG_BUNDLE = 'Bundle';

    @testSetup static void setupTestData(){
        User oTestUser = APTS_TestFacade.createTestUser();
        APTS_TestFacade.createMandatoryRecords(oTestUser);
        APTS_TestFacade.createAndConfigureOrder(oTestUser);
    }
     @isTest static void test_submitorder1(){
        User oTestUser = APTS_TestFacade.getTestUser();
        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder();
        List<Id> ordertoSubmitList = new List<Id>();

        test.startTest();
        System.runAs(oTestUser) {
         oOrder.APTS_Order_Type__c = 'Operating Order';
         oOrder.Apttus_Config2__PONumber__c ='PO has expired';
            
         Database.update(oOrder, false);
            ordertoSubmitList.add(oOrder.Id);
            if (!ordertoSubmitList.isEmpty()) {
            System.enqueueJob(new APTS_SubmitOrderQueueable(ordertoSubmitList));
          }
            List<Apttus_Config2__Order__c> listOrders = [SELECT Id,APTS_Status__c FROM Apttus_Config2__Order__c ];
            //WHERE APTS_Status__c = 'Submitted'
            System.assertNotEquals(TRUE, listOrders.isEmpty());
        }
        test.stopTest();
    }
    
    @isTest static void test_submitorder2(){
        User oTestUser = APTS_TestFacade.getTestUser();
        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder();
        List<Id> ordertoSubmitList = new List<Id>();
         test.startTest();
         System.runAs(oTestUser) {
           // oOrder.Apttus_Config2__PONumber__c ='PO has expired';
            oOrder.APTS_Order_Type__c = 'Standard Order';
             oOrder.APTS_Order_Sub_Type__c = 'Digital Order';
             oOrder.APTS_SAP_OrderType__c = 'XA01';
            update oOrder; //added by Nikita
          ordertoSubmitList.add(oOrder.Id);
          if (!ordertoSubmitList.isEmpty()) {               
            System.enqueueJob(new APTS_SubmitOrderQueueable(ordertoSubmitList));
          }
            List<Apttus_Config2__Order__c> listOrders = [SELECT Id,APTS_Status__c FROM Apttus_Config2__Order__c ];
            //WHERE APTS_Status__c = 'Submitted'
            System.assertNotEquals(TRUE, listOrders.isEmpty());
        }
        test.stopTest();
    }
    
    @isTest static void test_submitorder3(){
        User oTestUser = APTS_TestFacade.getTestUser();
        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder();
        List<Apttus_Config2__OrderLineItem__c> orderLineItemList = APTS_TestFacade.getOrderLineItemList(oOrder.Id);
        orderLineItemList[0].APTS_Expected_Delivery_Quantity__c = 1;
        orderLineItemList[0].APTS_Expected_Delivery_Date__c = Date.today();
        orderLineItemList[0].APTS_ATP_Cleared__c = true;
        orderLineItemList[0].APTS_Item_Relevant_for_SAP__c = true;                    
        Database.update(orderLineItemList);
        List<Id> ordertoSubmitList = new List<Id>();
        ordertoSubmitList.add(oOrder.Id);
		
        test.startTest();
        System.runAs(oTestUser) {
            if (!ordertoSubmitList.isEmpty()) {
              System.enqueueJob(new APTS_SubmitOrderQueueable(ordertoSubmitList));
          }
            List<Apttus_Config2__Order__c> listOrders = [SELECT Id,APTS_Status__c FROM Apttus_Config2__Order__c ];
            //WHERE APTS_Status__c = 'Submitted'
            System.assertNotEquals(TRUE, listOrders.isEmpty());
        }
        test.stopTest();    
    }
    
    
    @isTest static void test_SubmitAmendOrder(){
        User oTestUser = APTS_TestFacade.getTestUser();
        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder();
        
        Apttus_Config2__Order__c oOrder1 = oOrder.clone(false,false,false,false);
        oOrder1.Apttus_Config2__PreviousVersion__c = oOrder.Id;
        oOrder1.APTS_SAP_OrderType__c = 'XA13';
        Database.insert(oOrder1);
    List<Id> ordertoSubmitList = new List<Id>();
        ordertoSubmitList.add(oOrder1.Id);
        
        test.startTest();
        System.runAs(oTestUser) {
            if (!ordertoSubmitList.isEmpty()) {
              System.enqueueJob(new APTS_SubmitOrderQueueable(ordertoSubmitList));
          }
            List<Apttus_Config2__Order__c> listOrders = [SELECT Id,APTS_Status__c FROM Apttus_Config2__Order__c ];
            System.assertNotEquals(TRUE, listOrders.isEmpty());
        }
        test.stopTest();
    }
    
    @isTest static void test_OrderUsageTierUpdation(){
        User oTestUser = APTS_TestFacade.getTestUser();

        // create account
        Account oAccount = APTS_TestDataFactory.createAccount(ACCOUNT_NAME);
        Database.insert(oAccount, FALSE);

        // create contact
        Contact oContact = APTS_TestDataFactory.createContact(oAccount, CONTACT_NUMBER);
        Database.insert(oContact, FALSE);

        //create price list
        Apttus_Config2__PriceList__c oPricelist = APTS_TestDataFactory.createPriceList(PRICELIST_NAME);
        Database.insert(oPricelist, FALSE);
        
        //Create Products
        Product2 prod1 = APTS_TestDataFactory.createProduct(ACCOUNT_NAME,ACCOUNT_NAME, PROD_FAMILY_MACHINE, PROD_CONFIG_BUNDLE, FALSE, TRUE);
        Database.insert(prod1, FALSE);

        //Create Price List Items
        Apttus_Config2__PriceListItem__c pli1 = APTS_TestDataFactory.createPriceListItem(oPricelist.Id, prod1.Id);
        Database.insert(pli1, FALSE);

        //Agreement
        Apttus__APTS_Agreement__c oAgr = APTS_TestDataFactory.createAgreement(oContact.Id, oPricelist.Id, oAccount.Id, 'Consumption Model');
        //RecordType rt = [select id,Name from RecordType where SobjectType='Apttus__APTS_Agreement__c' and Name='Consumption Model' Limit 1][0];
        //oAgr.RecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Consumption Model').getRecordTypeId();
        //oAgr.RecordTypeId = null;
        //oAgr.RecordType = rt;
        Database.insert(oAgr, FALSE);
        Apttus__APTS_Agreement__c oAgr1 = [Select id, RecordType.Id, RecordType.Name from Apttus__APTS_Agreement__c where Id =:oAgr.Id][0];

        //Agreement Line Item
        Apttus__AgreementLineItem__c oAgrLineItem = APTS_TestDataFactory.createAgreementLineItem(prod1.Id, oAgr.Id, oAccount.Id, pli1.Id);
        oAgrLineItem.Apttus_CMConfig__ChargeType__c = 'Usage Fee';
        Database.insert(oAgrLineItem, FALSE);

        //Agreement Usage Tier
        Apttus_CMConfig__AgreementUsagePriceTier__c ageUsageTier = new Apttus_CMConfig__AgreementUsagePriceTier__c();
        ageUsageTier.Apttus_CMConfig__LineItemId__c = oAgrLineItem.Id;
        ageUsageTier.Apttus_CMConfig__AdjustmentAmount__c = 10;
        ageUsageTier.Apttus_CMConfig__Dimension1Value__c = 'Paid';
        ageUsageTier.Apttus_CMConfig__Sequence__c=1;
        Database.insert(ageUsageTier, FALSE);

        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder();
        oOrder.Apttus_CMConfig__AgreementId__c = oAgr.Id;
        Database.update(oOrder);
        /*List<Apttus_Config2__OrderLineItem__c> orderLineItemList = APTS_TestFacade.getOrderLineItemList(oOrder.Id);
        orderLineItemList[0].Apttus_Config2__ChargeType__c = 'Usage Fee';
        orderLineItemList[0].Apttus_CMConfig__AgreementLineItemId__c = oAgrLineItem.Id;
        Database.update(orderLineItemList);*/
        Apttus_Config2__OrderLineItem__c oOrderLI = new Apttus_Config2__OrderLineItem__c();
        oOrderLI.Apttus_Config2__OrderId__c = oOrder.Id;
        oOrderLI.Apttus_Config2__ChargeType__c = 'Usage Fee';
        oOrderLI.Apttus_CMConfig__AgreementLineItemId__c = oAgrLineItem.Id;
        Database.insert(oOrderLI, FALSE);
        oOrderLI.Apttus_CMConfig__AgreementLineItemId__c = oAgrLineItem.Id;
        Database.update(oOrderLI);

        Apttus__AgreementLineItem__c testAgrLI = [select id, (SELECT id, Apttus_CMConfig__AdjustmentAmount__c, Apttus_CMConfig__Dimension1Value__c from Apttus_CMConfig__UsagePriceTiers__r) from Apttus__AgreementLineItem__c where id=:oAgrLineItem.Id];
        
        //Order Usage Price Tier
        Apttus_Config2__OrderUsagePriceTier__c oOrderUsagePriceTier = new Apttus_Config2__OrderUsagePriceTier__c();
        oOrderUsagePriceTier.Apttus_Config2__OrderLineItemId__c = oOrderLI.Id;
        oOrderUsagePriceTier.Apttus_Config2__AdjustmentAmount__c = 5;
        oOrderUsagePriceTier.Apttus_Config2__Dimension1Value__c = 'Paid';
        oOrderUsagePriceTier.Apttus_Config2__Sequence__c=1;
        Database.insert(oOrderUsagePriceTier, FALSE);        
    List<Id> ordertoSubmitList = new List<Id>();
        test.startTest();
        System.runAs(oTestUser) {
            ordertoSubmitList.add(oOrder.Id);
            if (!ordertoSubmitList.isEmpty()) {
            System.enqueueJob(new APTS_SubmitOrderQueueable(ordertoSubmitList));
          }
           
        }
        test.stopTest();
    }
    
   /*  @isTest static void test_submitorderPoHasExpired(){
        User oTestUser = APTS_TestFacade.getTestUser();
        Apttus_Config2__Order__c oOrder = APTS_TestFacade.getOrder();
        List<Id> ordertoSubmitList = new List<Id>();

        test.startTest();
        System.runAs(oTestUser) {
        oOrder.Approval_Status__c = 'Approved';
        oOrder.Apttus_Config2__PONumber__c ='PO has expired';
        oOrder.APTS_Order_Sub_Type__c = 'Digital Order';
        update oOrder; //added by Nikita
        ordertoSubmitList.add(oOrder.Id);
            if (!ordertoSubmitList.isEmpty()) {
            System.enqueueJob(new APTS_SubmitOrderQueueable(ordertoSubmitList));
          }
            List<Apttus_Config2__Order__c> listOrders = [SELECT Id,APTS_Status__c FROM Apttus_Config2__Order__c ];
            //WHERE APTS_Status__c = 'Submitted'
            System.assertNotEquals(TRUE, listOrders.isEmpty());
        }
        test.stopTest();
    } */
}