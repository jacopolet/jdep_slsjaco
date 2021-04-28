/*************************************************************
@Name: APTS_ViewATPResultsControllerTest
@Author: sethukkarasi
@CreateDate: 08-03-2018
@Description: View ATP Results Controller
@UsedBy: APTS_ViewATPResultsController
******************************************************************/

@isTest
private with sharing class APTS_ViewATPResultsControllerTest{
  private static final String PAGE_PARAM_ID = System.Label.APTS_Id;
  private static final String BILLING_PREFRENCE = 'JDETestPrefrence';
  private static final String ACCOUNT_NAME = 'JDETestAccount';
  private static final String CONTACT_NUMBER = '1010101011';
  private static final String STANDARD_DEAL = 'Standard Deal';
  private static final String PRICELIST_NAME = 'JDETest Price List';
  private static final String PROD_FAMILY_MACHINE = 'MA';
  private static final String PROD_CONFIG_BUNDLE = 'Bundle';
  private static final String PRODUCT_SERVICE = 'PRODUCT/SERVICE';
  private static final String BILLING_FREQ_MONTHLY = 'Monthly';
  private static final String BILLING_TYPE_ADVANCED = 'Bill In Advance';
  private static final String PRICE_TYPE_ONETIME = 'One Time';
  private static final String PRICE_UNIT_PER = 'Per Unit';
  private static final String PRICE_UNIT_EACH = 'Each';
  private static final String LINETYPE_MANUAL = 'Manual';
  private static final String ADJUSTMENTTYPE_DIS = '% Discount';
  private static final String ADJUSTMENT_APPLIESTO = 'Starting Price';
  private static final String BREAKUPTYPE_DETAIL = 'Detail';
  private static final String PASS = System.Label.APTS_Pass;
  
  @testSetup static void setupTestData() {
    User oTestUser = APTS_TestFacade.createTestUser();
    // create billingprefrence
    Apttus_Config2__BillingPreference__c billPref = APTS_TestDataFactory.createBillingPrefrence(BILLING_PREFRENCE);
    Database.insert(billPref, FALSE);

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

    //Create Order
    Apttus_Config2__Order__c order = APTS_TestDataFactory.createOrder(oAccount.Id, oPricelist.Id, oContact.Id);
    Database.insert(order, FALSE);

    //Create Cart
    Apttus_Config2__ProductConfiguration__c config = APTS_TestDataFactory.createProductConfig(order);
    Database.insert(config, FALSE);

    //Create Line Items
    Apttus_Config2__LineItem__c lineItem1 = APTS_TestDataFactory.createLineItem(config, pli1.Id, NULL, prod1.Id, NULL, NULL, 1, 1, 1, PRODUCT_SERVICE, billPref.Id, BILLING_FREQ_MONTHLY, BILLING_TYPE_ADVANCED, PRICE_TYPE_ONETIME, PRICE_UNIT_PER, PRICE_UNIT_EACH, 100, 2);
    lineItem1.Apttus_Config2__Quantity__c = 2;
    lineItem1.APTS_Expected_Delivery_Quantity__c = 1;
    Database.insert(lineItem1, FALSE);

   
    //Create Order Line Items
    Apttus_Config2__OrderLineItem__c orderline1 = APTS_TestDataFactory.createOrderLineItem(order, pli1.Id, null, prod1.Id, null, null, null, 1, 1, 1, PRODUCT_SERVICE, billPref.Id, PRICE_TYPE_ONETIME, BILLING_TYPE_ADVANCED, PRICE_TYPE_ONETIME, PRICE_UNIT_PER, PRICE_UNIT_EACH, 100.0, 10.0);
    orderline1.Apttus_Config2__DerivedFromId__c = lineItem1.Id;
    Database.insert(orderline1, FALSE);
      
    Apttus_Config2__OrderAdjustmentLineItem__c adjustLineItem = new Apttus_Config2__OrderAdjustmentLineItem__c(Apttus_Config2__LineItemId__c = orderline1.Id, Apttus_Config2__LineNumber__c=1, Apttus_Config2__LineType__c=LINETYPE_MANUAL, Apttus_Config2__AdjustmentType__c = ADJUSTMENTTYPE_DIS, Apttus_Config2__AdjustmentAppliesTo__c = ADJUSTMENT_APPLIESTO, Apttus_Config2__AdjustmentAmount__c = 10);
    Database.insert(adjustLineItem, FALSE);

    Apttus_Config2__OrderTaxBreakup__c taxLineItem = new Apttus_Config2__OrderTaxBreakup__c(Apttus_Config2__OrderLineItemId__c = orderline1.Id,Apttus_Config2__Sequence__c=1,Apttus_Config2__TaxAmount__c=10,Apttus_Config2__BreakupType__c=BREAKUPTYPE_DETAIL);
    Database.insert(taxLineItem, FALSE);
      
    APTS_Order_Freight_Data__c freightchargeItem = new APTS_Order_Freight_Data__c(APTS_Order_Line_Item__c = orderline1.Id, APTS_Sequence__c=1,APTS_Freight_Amount__c=10,APTS_Breakup_Type__c=BREAKUPTYPE_DETAIL);
    Database.insert(freightchargeItem, FALSE);
  }

  @isTest static void testATPStatusPass() {
    User oTestUser = APTS_TestFacade.getTestUser();
    
    test.startTest();
    System.runAs(oTestUser) {
      List<Apttus_Config2__Order__c> listOrder = [SELECT id FROM Apttus_Config2__Order__c WHERE Apttus_Config2__BillToAccountId__r.Name =: ACCOUNT_NAME LIMIT 1];
      System.assertEquals(TRUE, !listOrder.isEmpty());
      listOrder[0].APTS_ATP_Check_Status__c = PASS;
      Database.update(listOrder[0], FALSE);
      ApexPages.currentPage().getParameters().put(PAGE_PARAM_ID, listOrder[0].Id);
      APTS_ViewATPResultsController oController = new APTS_ViewATPResultsController(); 
    }
    test.stopTest();
  }

  @isTest static void testATPStatusFail() {
    User oTestUser = APTS_TestFacade.getTestUser();
    
    test.startTest();
    System.runAs(oTestUser) {
      List<Apttus_Config2__Order__c> listOrder = [SELECT id FROM Apttus_Config2__Order__c WHERE Apttus_Config2__BillToAccountId__r.Name =: ACCOUNT_NAME LIMIT 1];
      System.assertEquals(TRUE, !listOrder.isEmpty());
      ApexPages.currentPage().getParameters().put(PAGE_PARAM_ID, listOrder[0].Id);
      APTS_ViewATPResultsController oController = new APTS_ViewATPResultsController(); 
    }
    test.stopTest();
  }

  @isTest static void testBack() {
    User oTestUser = APTS_TestFacade.getTestUser();
    
    test.startTest();
    System.runAs(oTestUser) {
      List<Apttus_Config2__Order__c> listOrder = [SELECT id FROM Apttus_Config2__Order__c WHERE Apttus_Config2__BillToAccountId__r.Name =: ACCOUNT_NAME LIMIT 1];
      System.assertEquals(TRUE, !listOrder.isEmpty());
      ApexPages.currentPage().getParameters().put(PAGE_PARAM_ID, listOrder[0].Id);
      APTS_ViewATPResultsController oController = new APTS_ViewATPResultsController();
      oController.back();
    }
    test.stopTest();
  }

}