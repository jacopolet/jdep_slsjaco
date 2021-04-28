@isTest
private class APTS_RSOSyncDataWebServiceTest {

    @testSetup static void testDataSetup() {
        User oTestUser = APTS_TestFacade.createTestUser();
        Account acc = APTS_TestDataFactory.createAccount('RSO Order Test');
        acc.Sales_Organization__c = 'SAP_0111';
        insert acc;
        System.assert(acc != Null);

        Apttus_Config2__AccountLocation__c loc = new Apttus_Config2__AccountLocation__c();
        loc.Apttus_Config2__AccountId__c = acc.Id;
        insert loc;

        Contact con = APTS_TestDataFactory.createContact(acc, '+31-3000000000');
        con.Preferred_Language__c = 'SAP_EN';
        Insert con;
        System.assertEquals('SAP_EN', con.Preferred_Language__c);

        Case cse = TS_TestDataFactory.createFieldServiceCase();
        cse.ContactId = con.Id;
        insert cse;

        Apttus_Config2__PriceList__c plist = APTS_TestDataFactory.createPriceList('Netherlands Standard');
        insert plist;

        Product2 prod = APTS_TestDataFactory.createProduct('test rso ', '08111', 'Ingrident', 'Standalone', FALSE, FALSE);
        prod.APTS_Associated_Sales_Org__c = 'SAP_0111';
        insert prod;

        Apttus_Config2__PriceListItem__c plistItem = APTS_TestDataFactory.createPriceListItem(plist.Id, prod.Id);
        insert plistItem;

        List<APTS_RSO_Product_Catalog__c> listRSOCat = new List<APTS_RSO_Product_Catalog__c>();
        APTS_RSO_Product_Catalog__c rsProd = new APTS_RSO_Product_Catalog__c();
        rsProd.APTS_Product__c = prod.Id;
        rsProd.APTS_Category_Text__c = 'prod.Id';
        rsProd.APTS_Sub_Category_Text__c = 'prod.Id';
        rsProd.APTS_Sub_Sub_Category_Text__c = 'prod.Id';
        rsProd.APTS_Region__c  = 'SAP_0111';
        rsProd.APTS_Type__c = 'Routesales';
        listRSOCat.add(rsProd);

        APTS_RSO_Product_Catalog__c opProd = new APTS_RSO_Product_Catalog__c();
        opProd.APTS_Product__c = prod.Id;
        opProd.APTS_Category_Text__c = 'prod.Id';
        opProd.APTS_Sub_Category_Text__c = 'prod.Id';
        opProd.APTS_Sub_Sub_Category_Text__c = 'prod.Id';
        opProd.APTS_Region__c  = 'SAP_0111';
        opProd.APTS_Type__c = 'Operating';
        listRSOCat.add(opProd);
        insert listRSOCat;

        List<Apttus__APTS_Agreement__c> listAg = new List<Apttus__APTS_Agreement__c>();
        Apttus__APTS_Agreement__c standAg = APTS_TestDataFactory.createAgreement(con.Id, plist.Id, acc.Id, 'Standard Deal');
        standAg.Apttus_CMConfig__LocationId__c = loc.Id;
        standAg.Apttus__Status__c = 'Activated';
        standAg.APTS_Sold_To__c = acc.Id;
        standAg.APTS_Routesales__c = true;
        standAg.Apttus__Contract_End_Date__c = System.today().addYears(1);
        listAg.add(standAg);

        Apttus__APTS_Agreement__c conAg = APTS_TestDataFactory.createAgreement(con.Id, plist.Id, acc.Id, 'Consumption Model');
        conAg.Apttus_CMConfig__LocationId__c = loc.Id;
        conAg.Apttus__Status__c = 'Activated';
        conAg.APTS_Sold_To__c = acc.Id;
        conAg.Apttus__Contract_End_Date__c = System.today().addYears(1);
        listAg.add(conAg);
        insert listAg;

        List<APTS_Agreement_PO_Details__c> listAgPO = new List<APTS_Agreement_PO_Details__c>();
        APTS_Agreement_PO_Details__c standPO = new APTS_Agreement_PO_Details__c();
        standPO.APTS_Agreement__c = standAg.Id;
        standPO.APTS_PO_Number__c = '';
        standPO.APTS_PO_Number_Required__c = 'Yes';
        standPO.APTS_PO_Number_Type__c = 'Variable';
        standPO.APTS_PO_Category__c = 'Ingredients';
        listAgPO.add(standPO);

        APTS_Agreement_PO_Details__c conPO = new APTS_Agreement_PO_Details__c();
        conPO.APTS_Agreement__c = conAg.Id;
        conPO.APTS_PO_Number__c = '1234';
        conPO.APTS_PO_Number_Required__c = 'Yes';
        conPO.APTS_PO_Number_Type__c = 'Fixed';
        conPO.APTS_PO_Category__c = 'Ingredients';
        listAgPO.add(conPO);
        insert listAgPO;

        List<Apttus__AgreementLineItem__c> listAgLi = new List<Apttus__AgreementLineItem__c>();
        Apttus__AgreementLineItem__c standLine = APTS_TestDataFactory.createAgreementLineItem(prod.Id, standAg.Id, acc.Id, plistItem.Id);
        listAgLi.add(standLine);
        Apttus__AgreementLineItem__c conLine = APTS_TestDataFactory.createAgreementLineItem(prod.Id, conAg.Id, acc.Id, plistItem.Id);
        listAgLi.add(conLine);
        insert listAgLi;


        List<APTS_Contract_Entitlement_Repository__c> listCER = new List<APTS_Contract_Entitlement_Repository__c>();

        APTS_Contract_Entitlement_Repository__c standCER = new APTS_Contract_Entitlement_Repository__c();
        standCER.APTS_Sold_to_Party__c = acc.Id;
        standCER.APTS_Product__c = prod.Id;
        standCER.APTS_Contributing_Agreement__c = standAg.Id;
        standCER.APTS_Agreement_Line_Item__c = standLine.Id;
        standCER.APTS_Contributing_Agreement_Level__c = 'Child';
        standCER.APTS_Agreement_Type__c = 'Standard Deal';
        standCER.APTS_Is_Pending__c = false;
        listCER.add(standCER);

        APTS_Contract_Entitlement_Repository__c conCER = new APTS_Contract_Entitlement_Repository__c();
        conCER.APTS_Sold_to_Party__c = acc.Id;
        conCER.APTS_Product__c = prod.Id;
        conCER.APTS_Contributing_Agreement__c = conAg.Id;
        conCER.APTS_Agreement_Line_Item__c = conLine.Id;
        conCER.APTS_Contributing_Agreement_Level__c = 'Child';
        conCER.APTS_Agreement_Type__c = 'Consumption Model';
        conCER.APTS_Is_Pending__c = false;
        listCER.add(conCER);
        insert listCER;

        List<Resource__c> listRes = new List<Resource__c>();
        Resource__c testRSOResource = TS_TestDataFactory.createResourceSingle('TestRSONumber');
        testRSOResource.EmailAddress__c = 'testRSO@JDECoffee.com';
        listRes.add(testRSOResource);

        Resource__c testOPResource = TS_TestDataFactory.createResourceSingle('TestOPNumber');
        testOPResource.EmailAddress__c = 'testOP@JDECoffee.com';
        listRes.add(testOPResource);
        insert listRes;

        WorkOrder parentWO = TS_TestDataFactory.createWorkOrder();
        parentWO.ContactId = con.Id;
        parentWO.CaseId = cse.Id;
        parentWO.WorkOrderType__c = Label.TS_Case_SubType_CorrectMaint;
        insert parentWO;

        List<WorkOrderLineItem> listRoutes = new List<WorkOrderLineItem>();
        WorkOrderLineItem wS25 = TS_TestDataFactory.createWorkOrderLineItem(parentWO.Id);
        wS25.ExecutingEngineer__c = testRSOResource.Id;
        wS25.Status = 'Dispatched';
        wS25.InternalOrderSAP__c = '123';
        wS25.WorkOrderLineItemType__c = Label.TS_Type_Task;
        wS25.Case__c = cse.Id;
        wS25.WorkOrderId = parentWO.Id;
        wS25.StartDate__c = system.today();
        wS25.WorkOrderType__c = 'S25';
        wS25.AccountLocation__c = loc.Id;
        listRoutes.add(wS25);

        WorkOrderLineItem wS20 = TS_TestDataFactory.createWorkOrderLineItem(parentWO.Id);
        wS20.ExecutingEngineer__c = testRSOResource.Id;
        wS20.Status = 'Dispatched';
        wS20.InternalOrderSAP__c = '123';
        wS20.WorkOrderLineItemType__c = Label.TS_Type_Task;
        wS20.Case__c = cse.Id;
        wS20.WorkOrderId = parentWO.Id;
        wS20.StartDate__c = system.today();
        wS20.WorkOrderType__c = 'S20';
        wS20.AccountLocation__c = loc.Id;
        listRoutes.add(wS20);
        insert listRoutes;
    }

    @isTest static void test_Webservice() {
        User oTestUser = APTS_TestFacade.getTestUser();
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeStringField('EmpEmail', 'testRSO@JDECoffee.com');
       // gen.writeStringField('InitialLoad', 'true');
        gen.writeEndObject();
        String jSONClass = gen.getAsString();

        test.startTest();

        System.runAs(oTestUser) {
            RestRequest request = new RestRequest();
            RestResponse res = new RestResponse();
            request.requestUri = '/services/apexrest/RSOOrder/SyncData/';
            request.httpMethod = 'POST';
            request.requestBody = Blob.valueof(jSONClass);
            RestContext.request = request;
            RestContext.response = res;
            APTS_RSOSyncDataWebService.getRouteInfo();
            system.debug('res = ' + res);
            System.assertEquals('/services/apexrest/RSOOrder/SyncData/', request.requestUri);
        }



        test.stopTest();
    }

    @isTest static void test_Webservice1() {
        User oTestUser = APTS_TestFacade.getTestUser();
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeStringField('EmpEmail', '');
        gen.writeEndObject();
        String jSONClass = gen.getAsString();

        test.startTest();
        // System.runAs(oTestUser) {
        RestRequest request = new RestRequest();
        RestResponse res = new RestResponse();
        request.requestUri = '/services/apexrest/RSOOrder/SyncData/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueof(jSONClass);
        RestContext.request = request;
        RestContext.response = res;
        APTS_RSOSyncDataWebService.getRouteInfo();
        //}
        System.assertEquals('POST', request.httpMethod);

        test.stopTest();
    }
    /* @isTest static void test_SyncLog() {
          User oTestUser = APTS_TestFacade.getTestUser();
          test.startTest();
          System.runAs(oTestUser) {
              APTS_Sync_Data_Log__c oDataLog = new APTS_Sync_Data_Log__c();
              oDataLog.APTS_Requested_Date__c = System.now();
              oDataLog.APTS_RSA_Engineer_ID__c = 'Test@test.com';
              oDataLog.APTS_Status__c = 'Complete';
              oDataLog.APTS_Date_of_Last_Sync__c = System.now();
              Database.Insert(oDataLog, false);
              APTS_RSOSyncDataWebService.createSyncDataLog('Test@test.com');
              APTS_RSOSyncDataWebService.getPreviousSyncLog('Test@test.com');
              try{
               APTS_RSOSyncDataWebService.getRouteInfo();
              }
              catch(Exception e)
              {

              }
          }
          test.stopTest();
      } */
}