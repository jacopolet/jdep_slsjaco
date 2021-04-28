@isTest
private class APTS_RSOCreateOrderWebServiceTest {
  private static final String ORDERTYPE_ROUTESALES = 'Route Sales Order';
  private static final String ORDERSUBTYPE_STANDARDORDER = 'Standard Order';
    

  @testSetup static void testDataSetup() {
    User oTestUser = APTS_TestFacade.createTestUser();
    Account acc = APTS_TestDataFactory.createAccount('RSO Order Test');
    insert acc;

    Apttus_Config2__AccountLocation__c loc = new Apttus_Config2__AccountLocation__c();
    loc.Apttus_Config2__AccountId__c = acc.Id;
    insert loc;
    System.assert(acc.Id != Null);

    Contact con = APTS_TestDataFactory.createContact(acc, '+31-3000000000');
    con.Preferred_Language__c = 'SAP_EN';
    System.assertEquals('SAP_EN',con.Preferred_Language__c);
    Insert con;

    Case cse = TS_TestDataFactory.createFieldServiceCase();
    cse.ContactId = con.Id;
    insert cse;

    Product2 prod = APTS_TestDataFactory.createProduct('test rso ', '08111', 'Ingrident', 'Standalone', FALSE, FALSE);
    insert prod;
  }

  @isTest static void test_Webservice() {
    String sAccId = '', sConId = '', sLocId = '', sProdId = '', sCaseId = '';
    List<Account> listAcc = [SELECT Id FROM Account LIMIT 1];
    List<Contact> listCon = [SELECT Id FROM Contact LIMIT 1];
    List<Product2> listProd = [SELECT Id FROM Product2 LIMIT 1];
    List<Case> listCase = [SELECT Id FROM Case LIMIT 1];
    List<Apttus_Config2__AccountLocation__c> listLoc = [SELECT Id FROM Apttus_Config2__AccountLocation__c LIMIT 1];
    

    if(!listAcc.isEmpty()){
        sAccId = listAcc[0].Id;
    }

    if(!listCon.isEmpty()){
        sConId = listCon[0].Id;
    }
    
    if(!listProd.isEmpty()){
        sProdId = listProd[0].Id;
    }

    if(!listCase.isEmpty()){
        sCaseId = listCase[0].Id;
    }

    if(!listLoc.isEmpty()){
        sLocId = listLoc[0].Id;
    }

    List<APTS_DOEPIReqWrapper> oWrapperLst = new List<APTS_DOEPIReqWrapper>();
    APTS_DOEPIReqWrapper oWrapper = new APTS_DOEPIReqWrapper();
    oWrapper.SourceOrderNumber = 'Test 001';
    oWrapper.SalesforceAccountID = sAccId;
    oWrapper.SalesforceContactID = sConId;
    oWrapper.SalesforceAccountLocationID = sLocId;
    oWrapper.CaseID =  sCaseId;
    oWrapper.Source = 'MobileApp';
    oWrapper.PONumber = 'PO5678';
    oWrapper.OrderType = ORDERTYPE_ROUTESALES;
    oWrapper.OrderSubType = ORDERSUBTYPE_STANDARDORDER;
    oWrapper.FulfilledFromVan = true;
    oWrapper.CustomerComment = 'test comments';

    oWrapper.OrderLineItems = new List<APTS_DOEPIReqWrapper.EPIOrderLI>();
    APTS_DOEPIReqWrapper.EPIOrderLI orderLineItem = new APTS_DOEPIReqWrapper.EPIOrderLI();
    orderLineItem.ProductId = sProdId;
    orderLineItem.Quantity = 1;
    orderLineItem.SourceLineNumber = '1';
    orderLineItem.SellingUnitofMeasure = 'Box';
    orderLineItem.ReasonCode = '1';
    oWrapper.OrderLineItems.add(orderLineItem);
    oWrapperLst.add(oWrapper);
    
    System.assertEquals('Box',orderLineItem.SellingUnitofMeasure);

    JSONGenerator gen = JSON.createGenerator(true);
    gen.writeStartObject();
    gen.writeStringField('RSOEmployeeEmail', 'testRSO@JDECoffee.com');
    gen.writeStringField('Source', 'MobileApp');
    gen.writeFieldName('Orders');
    gen.writeStartArray();
    for (APTS_DOEPIReqWrapper oWrapperobj : oWrapperLst){
        gen.writeObject(oWrapperobj);
    }
    gen.writeEndArray();
    gen.writeEndObject();

    String jSONClass = gen.getAsString();
    system.debug('jSONClass = ' + jSONClass);

    User oTestUser = APTS_TestFacade.getTestUser();
    test.startTest();

    System.runAs(oTestUser) {
      RestRequest request = new RestRequest();
      RestResponse res = new RestResponse();
      request.requestUri = '/services/apexrest/RSOOrder/CreateOrder/';
      request.httpMethod = 'POST';
      request.requestBody = Blob.valueof(jSONClass);
      RestContext.request = request;
      RestContext.response = res;
      APTS_RSOCreateOrderWebService.createRSOOrder();

      APTS_RSOCreateOrderWebService.createRSOOrder();
    }

    test.stopTest();
  }


  @isTest static void test_Webservice1() {
    JSONGenerator gen = JSON.createGenerator(true);
    gen.writeStartObject();
    gen.writeStringField('RSOEmployeeEmail', '');
    gen.writeEndObject();
    String jSONClass = gen.getAsString();

    User oTestUser = APTS_TestFacade.getTestUser();
    test.startTest();

    System.runAs(oTestUser) {
      RestRequest request = new RestRequest();
      RestResponse res = new RestResponse();
      request.requestUri = '/services/apexrest/RSOOrder/CreateOrder/';
      request.httpMethod = 'POST';
      request.requestBody = Blob.valueof(jSONClass);
      RestContext.request = request;
      RestContext.response = res;
      APTS_RSOCreateOrderWebService.createRSOOrder();
      
      System.assertEquals('/services/apexrest/RSOOrder/CreateOrder/',request.requestUri);


      gen = JSON.createGenerator(true);
      gen.writeStartObject();
      gen.writeStringField('RSOEmployeeEmail', 'testRSO@JDECoffee.com');
      gen.writeEndObject();
      jSONClass = gen.getAsString();

      request = new RestRequest();
      res = new RestResponse();
      request.requestUri = '/services/apexrest/RSOOrder/CreateOrder/';
      request.httpMethod = 'POST';
      request.requestBody = Blob.valueof(jSONClass);
      RestContext.request = request;
      RestContext.response = res;
      APTS_RSOCreateOrderWebService.createRSOOrder();

      gen = JSON.createGenerator(true);
      gen.writeStartObject();
      gen.writeStringField('RSOEmployeeEmail', 'testRSO@JDECoffee.com');
      gen.writeStringField('Source', 'MobileApp');
      gen.writeEndObject();
      jSONClass = gen.getAsString();

      request = new RestRequest();
      res = new RestResponse();
      request.requestUri = '/services/apexrest/RSOOrder/CreateOrder/';
      request.httpMethod = 'POST';
      request.requestBody = Blob.valueof(jSONClass);
      RestContext.request = request;
      RestContext.response = res;
      APTS_RSOCreateOrderWebService.createRSOOrder();

    }
    test.stopTest();
  }

}