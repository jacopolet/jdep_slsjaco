@isTest
public class APTS_DigitalOrderBatchTest {
  @testSetup static void setupTestData() {
    User oTestUser = APTS_TestFacade.createTestUser();
    String acctName = 'Test' + string.valueOf(Math.random());
    Account testAccount = APTS_TestDataFactory.createAccount(acctName);
    Database.insert(testAccount, false);

    Contact testContact = APTS_TestDataFactory.createContact(testAccount, '+912121212121');
    Database.insert(testContact, false);

    Apttus_Config2__PriceList__c testPriceList = APTS_TestDataFactory.createPriceList('testPriceList');
    Database.insert(testPriceList, false);

    Product2 testProduct = APTS_TestDataFactory.createProduct('TestCoffee', 'pc123', 'Coffee', 'Standalone', true, false);
    Database.Insert(testProduct, false);

    Apttus_Config2__PriceListItem__c oPriceListItemStandalone = APTS_TestDataFactory.createPriceListItem(testPriceList.Id, testProduct.Id);
    Database.Insert(oPriceListItemStandalone, false);

    Apttus_Config2__PaymentTerm__c paymentTerm = APTS_TestUtils.paymentTerm();
    paymentTerm.Apttus_Config2__Sequence__c = 5;
    paymentTerm.APTS_Ext_ID__c = 'SAP_ZOLP';
    Database.Insert(paymentTerm);

    APTS_DOEPIReqWrapper oDOEPIReqWrapper = new APTS_DOEPIReqWrapper();
    oDOEPIReqWrapper.SourceOrderNumber = 'sn1233';
    oDOEPIReqWrapper.SalesforceAccountID = testAccount.Id;
    oDOEPIReqWrapper.SalesforceContactID = testContact.Id;
    oDOEPIReqWrapper.SalesforcePriceListID = testPriceList.Id;
    oDOEPIReqWrapper.SalesOrganization = 'SAP_0111';
    oDOEPIReqWrapper.AdjustmentType = 'Test Adjustment Type';
    oDOEPIReqWrapper.CurrencyCode = 'Test Currency code';
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
    oDOEPIReqWrapper.TotalVATAmount = 8;

    oDOEPIReqWrapper.OrderLineItems = new List<APTS_DOEPIReqWrapper.EPIOrderLI>();
    APTS_DOEPIReqWrapper.EPIOrderLI orderLineItem = new APTS_DOEPIReqWrapper.EPIOrderLI();
    orderLineItem.ProductCode = testProduct.productcode;
    orderLineItem.Quantity = 1;
    orderLineItem.ConfigurationType = 'Standalone';
    orderLineItem.SourceLineNumber = '1';
    orderLineItem.SellingUnitofMeasure = 'SAP_PCE';
    oDOEPIReqWrapper.OrderLineItems.add(orderLineItem);

    String sJSONClass = JSON.serialize(oDOEPIReqWrapper);

    APTS_Order_Interface_Log__c oLog = new APTS_Order_Interface_Log__c();
    oLog.APTS_Message__c = sJSONClass;
    oLog.APTS_SourceOrderNumber__c = 'sn1233';
    oLog.APTS_Status__c = 'New';
    oLog.APTS_Parent_Log__c = null;
    insert oLog;

  }

  private static testMethod void testDigitalBatch() {
    User oTestUser = APTS_TestFacade.getTestUser();

    test.startTest();

    System.runAs(oTestUser) {
      APTS_DigitalOrderBatch batch2 = new APTS_DigitalOrderBatch();
      Database.executeBatch(batch2, 2);
    }

    test.stopTest();

    List<Apttus_Config2__Order__c> listOrder = [SELECT Id FROM Apttus_Config2__Order__c];
    System.assert(listOrder != Null);
  }

}