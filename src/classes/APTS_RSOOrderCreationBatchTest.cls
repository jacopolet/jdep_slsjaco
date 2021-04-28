@isTest
public class APTS_RSOOrderCreationBatchTest {
  private static final String ORDERTYPE_ROUTESALES = 'Route Sales Order';
  private static final String ORDERSUBTYPE_STANDARDORDER = 'Standard Order';

  @testSetup static void setupTestData() {
    User oTestUser = APTS_TestFacade.createTestUser();
    String acctName = 'Test' + string.valueOf(Math.random());
    Account acc = APTS_TestDataFactory.createAccount(acctName);
    acc.Account_Status__c = 'Valid';
    Database.insert(acc, false);
    System.assert(acc != Null);

    Contact con = APTS_TestDataFactory.createContact(acc, '+912121212121');
    Database.insert(con, false);

    Case cse = TS_TestDataFactory.createFieldServiceCase();
    cse.ContactId = con.Id;
    insert cse;

    Apttus_Config2__AccountLocation__c loc = new Apttus_Config2__AccountLocation__c();
    loc.Apttus_Config2__AccountId__c = acc.Id;
    loc.Account_Location_Status__c  = 'Valid';
    insert loc;

    Product2 prod = APTS_TestDataFactory.createProduct('TestCoffee', 'pc123', 'Coffee', 'Standalone', true, false);
    Database.Insert(prod, false);

    Apttus_Config2__PriceList__c plist = APTS_TestDataFactory.createPriceList('testPriceList');
    Database.insert(plist, false);

    Apttus_Config2__PriceListItem__c plistItem = APTS_TestDataFactory.createPriceListItem(plist.Id, prod.Id);
    Database.Insert(plistItem, false);

    Apttus__APTS_Agreement__c agr = APTS_TestDataFactory.createAgreement(con.Id, plist.Id, acc.Id, 'Standard Deal');
    agr.Apttus_CMConfig__LocationId__c = loc.Id;
    agr.APTS_Sold_To__c = acc.Id;
    agr.APTS_Routesales__c = true;
    agr.Apttus__Status__c = System.Label.APTS_Activated;
    agr.Apttus__Status_Category__c =  System.Label.APTS_In_Effect;
    agr.Apttus__Contract_End_Date__c =  System.today();
    insert agr;

    Apttus__AgreementLineItem__c agLine = APTS_TestDataFactory.createAgreementLineItem(prod.Id, agr.Id, acc.Id, plistItem.Id);
    insert agLine;

    APTS_Agreement_PO_Details__c oPODetails = new APTS_Agreement_PO_Details__c();
    oPODetails.APTS_Agreement__c = agr.Id;
    oPODetails.APTS_PO_Number__c = '';
    oPODetails.APTS_PO_Number_Required__c = 'Yes';
    oPODetails.APTS_PO_Number_Type__c = 'Variable';
    oPODetails.APTS_PO_Category__c = 'Ingredients';
    insert oPODetails;

    APTS_Contract_Entitlement_Repository__c oCERRecord = new APTS_Contract_Entitlement_Repository__c();
    oCERRecord.APTS_Sold_to_Party__c = acc.Id;
    oCERRecord.APTS_Product__c = prod.Id;
    oCERRecord.APTS_Contributing_Agreement__c = agr.Id;
    oCERRecord.APTS_Agreement_Line_Item__c = agLine.Id;
    oCERRecord.APTS_Contributing_Agreement_Level__c = 'Child';
    oCERRecord.APTS_Agreement_Type__c = 'Standard Deal';
    insert oCERRecord;

    WorkOrder parentWO = TS_TestDataFactory.createWorkOrder();
    parentWO.ContactId = con.Id;
    parentWO.CaseId = cse.Id;
    parentWO.WorkOrderType__c = Label.TS_Case_SubType_CorrectMaint;
    insert parentWO;

    Resource__c testResource = TS_TestDataFactory.createResourceSingle('TestRSONumber');
    testResource.EmailAddress__c = 'testRSO@JDECoffee.com';
    insert testResource;

    WorkOrderLineItem woliParent = TS_TestDataFactory.createWorkOrderLineItem(parentWO.Id);
    woliParent.ExecutingEngineer__c = testResource.Id;
    woliParent.Status = 'Dispatched';
    woliParent.InternalOrderSAP__c = '123';
    woliParent.WorkOrderLineItemType__c = Label.TS_Type_Task;
    woliParent.Case__c = cse.Id;
    woliParent.WorkOrderId = parentWO.Id;
    woliParent.StartDate__c = system.today();
    woliParent.WorkOrderType__c = 'S25';
    woliParent.AccountLocation__c = loc.Id;
    insert woliParent;

    APTS_DOEPIReqWrapper oWrapper = new APTS_DOEPIReqWrapper();
    oWrapper.SourceOrderNumber = 'sn1232';
    oWrapper.SalesforceAccountID = acc.Id;
    oWrapper.SalesforceContactID = con.Id;
    oWrapper.SalesforceAccountLocationID = loc.Id;
    oWrapper.CaseID =  cse.Id;
    oWrapper.Source = 'MobileApp';
    oWrapper.PONumber = 'PO5678';
    oWrapper.OrderType = ORDERTYPE_ROUTESALES;
    oWrapper.OrderSubType = ORDERSUBTYPE_STANDARDORDER;
    oWrapper.FulfilledFromVan = true;
    oWrapper.CustomerComment = 'test comments';
    oWrapper.RSOEmployeeEmail = 'testRSO@JDECoffee.com';

    oWrapper.OrderLineItems = new List<APTS_DOEPIReqWrapper.EPIOrderLI>();
    APTS_DOEPIReqWrapper.EPIOrderLI orderLineItem = new APTS_DOEPIReqWrapper.EPIOrderLI();
    orderLineItem.ProductId = prod.Id;
    orderLineItem.Quantity = 1;
    orderLineItem.SourceLineNumber = '1';
    orderLineItem.SellingUnitofMeasure = 'Box';
    orderLineItem.ReasonCode = '1';
    oWrapper.OrderLineItems.add(orderLineItem);
    
    String sJSONClass = JSON.serializePretty(oWrapper);
    system.debug('sJSONClass = ' + sJSONClass);

    APTS_Order_Interface_Log__c oLog = new APTS_Order_Interface_Log__c();
    oLog.APTS_Message__c = sJSONClass;
    oLog.APTS_SourceOrderNumber__c = 'sn1232';
    oLog.APTS_Status__c = 'New';
    oLog.APTS_Source__c = 'RSOApp';
    oLog.APTS_Type__c = 'OrderData';
    insert oLog;

    APTS_Order_Interface_Log__c oLog1 = new APTS_Order_Interface_Log__c();
    oLog1.APTS_SourceOrderNumber__c = 'sn1232';
    oLog1.APTS_Status__c = 'New';
    oLog1.APTS_Source__c = 'RSOApp';
    oLog1.APTS_Type__c = 'Attachment';
    insert oLog1;

    Attachment attach=new Attachment();    
    attach.Name='Unit Test Attachment';
    Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
    attach.body=bodyBlob;
    attach.parentId=oLog1.id;
    insert attach;
    System.assertEquals('Unit Test Attachment',attach.Name);

    system.debug('oLog1 = ' + oLog1.Id);
  }

  @isTest static void testRSOOrderBatch() {
    User oTestUser = APTS_TestFacade.getTestUser();
    System.assert(oTestUser != Null);

    test.startTest();

    System.runAs(oTestUser) {
      APTS_RSOOrderCreationBatch batch = new APTS_RSOOrderCreationBatch();
      Database.executeBatch(batch, 200);
    }

    test.stopTest();
  }  

  @isTest static void testRSOOrderBatchMethods() {
    User oTestUser = APTS_TestFacade.getTestUser();
    List<APTS_Order_Interface_Log__c> listInterfacelog = [SELECT Id,APTS_Status__c FROM APTS_Order_Interface_Log__c LIMIT 1];
    if(!listInterfacelog.isEmpty()){
        listInterfacelog[0].APTS_Status__c = 'New';
        APTS_DOEPIReqWrapper oWrapper = new APTS_DOEPIReqWrapper();
        listInterfacelog[0].APTS_Message__c = JSON.serializePretty(oWrapper);
        update listInterfacelog;
        System.assertEquals('New',listInterfacelog[0].APTS_Status__c);
    }

    test.startTest();

    System.runAs(oTestUser) {
        APTS_RSOOrderCreationBatch obatch = new APTS_RSOOrderCreationBatch();
        Database.executeBatch(obatch, 1);
    }

    test.stopTest();
  }
}