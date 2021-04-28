//-------------------------------------------------------------------------------------------//
// Author       :   Anna Gonzales - Accenture
// Created Date :   May 19, 2017
// Usage        :   Test Class for TS_ClickSyncMasterDataTest 
//-------------------------------------------------------------------------------------------//

@isTest
public class TS_ClickSyncMasterDataTest {
     //DOO 5427 - Pandian Sundaramoorthy - March 16, 2021
  /*  static testMethod void testCreateIntegrationLog(){
        
        
        Product2 prod = new Product2(Name = 'Laptop X200', 
            Family = 'Hardware');
        insert prod;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;
         
        Pricebook2 customPB = new Pricebook2(Name='Custom Pricebook', isActive=true, Is_Country_Standard_Price__c = true);
        insert customPB;
        
        PricebookEntry customPrice = new PricebookEntry(
            Pricebook2Id = customPB.Id, Product2Id = prod.Id,
            UnitPrice = 12000, OldStandardPrice__c=100.0, IsActive = true);
        insert customPrice;
        
        customPrice.UnitPrice = 1212;
        update customPrice;
        
        upsert new IntegrationTriggerSettings__c (IntegrationLogTrigger__c = true);
        test.startTest();
         Test.setMock(WebServiceMock.class, new JDEServicesCallout_PartTypeMock());

        SchedulePricebookEntry newSchedulePricebookEntry = new SchedulePricebookEntry();
        newSchedulePricebookEntry.createIntegrationLog();
        test.stopTest();
        List<Integration_Log__c> count = [Select Id from Integration_Log__c];
        System.assertnotequals(0, count.size());
    }

    static testMethod void testCreateIntegrationBatchLog(){
        
        
        Product2 prod = new Product2(Name = 'Laptop X200', 
            Family = 'Hardware');
        insert prod;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        
        Pricebook2 customPB = new Pricebook2(Name='Custom Pricebook', isActive=true, Is_Country_Standard_Price__c = true);
        insert customPB;
        
        PricebookEntry customPrice = new PricebookEntry(
            Pricebook2Id = customPB.Id, Product2Id = prod.Id,
            UnitPrice = 12000, OldStandardPrice__c=100.0, IsActive = true);
        insert customPrice;
        
        customPrice.UnitPrice = 1212;
        update customPrice;
        
        upsert new IntegrationTriggerSettings__c (IntegrationLogTrigger__c = true);
        insert new IntegrationUserAndProfile__c (Click_Product_Batch_Limit__c  = 1);

        test.startTest();
         Test.setMock(WebServiceMock.class, new JDEServicesCallout_PartTypeMock());

        SchedulePricebookEntry newSchedulePricebookEntry = new SchedulePricebookEntry();
        newSchedulePricebookEntry.createIntegrationLog();
        test.stopTest();
        List<Integration_Log__c> count = [Select Id from Integration_Log__c where Integration_Status__c =: INT_Constants.TARGET_SYSTEM_SUCCESS];
        System.assertnotequals(0, count.size());
        
    } */

    static testMethod void testfailCreateIntegrationBatchLog(){
        List<Integration_Log__c> integList = new List<Integration_Log__c>();

        insert new IntegrationTriggerSettings__c (IntegrationLogTrigger__c = true);
        Integration_Log__c integ = new Integration_Log__c();
        integ.Object__c = INT_Constants.CLICK_SESSIONID;
        integ.Object_Id__c = '123dfsdfsdf';
        integ.Integration_Status__c = INT_Constants.INITIAL;
        integ.Triggered_Timestamp__c = Datetime.now();
        integ.SessionID__c = '123dfsdfsdf';
        integList.add( integ );
        insert integList;

        test.startTest();
            ExecuteQueueableCallOut csa = new ExecuteQueueableCallOut();
            csa.hasException = true;      
            csa.iLogList  =  integList;     
            System.enqueueJob(csa);
        test.stopTest();
        Integration_Log__c updateInteg = [ Select Integration_Status__c from Integration_Log__c where id =: integ.Id];
        System.assertEquals( INT_Constants.TARGET_SYSTEM_ERROR, updateInteg.Integration_Status__c);
     }

     static testMethod void testSessionIdLog(){
        List<Integration_Log__c> integList = new List<Integration_Log__c>();

        insert new IntegrationTriggerSettings__c (IntegrationLogTrigger__c = true);
		Integration_Log__c integ = new Integration_Log__c();
		integ.Object__c = INT_Constants.CLICK_SESSIONID;
		integ.Object_Id__c = '123dfsdfsdf';
		integ.Integration_Status__c = INT_Constants.INITIAL;
		integ.Triggered_Timestamp__c = Datetime.now();
		integ.SessionID__c = '123dfsdfsdf';
		integList.add( integ );
		insert integList;

        test.startTest();
        Test.setMock(WebServiceMock.class, new JDEServicesCallout_SessionMock());

        TS_ClickSyncMasterData controller = new TS_ClickSyncMasterData();
        controller.executeSessionId(integList);
        test.stopTest();
        List<Integration_Log__c> count = [Select Id from Integration_Log__c where Integration_Status__c =: INT_Constants.TARGET_SYSTEM_SUCCESS];
        System.assertnotequals(0, count.size());
        
    }

    static testMethod void testSessionIdCalloutErrorLog(){
        List<Integration_Log__c> integList = new List<Integration_Log__c>();

        insert new IntegrationTriggerSettings__c (IntegrationLogTrigger__c = true);
		Integration_Log__c integ = new Integration_Log__c();
		integ.Object__c = INT_Constants.CLICK_SESSIONID;
		integ.Object_Id__c = '123dfsdfsdf';
		integ.Integration_Status__c = INT_Constants.INITIAL;
		integ.Triggered_Timestamp__c = Datetime.now();
		integ.SessionID__c = '123dfsdfsdf';
		integList.add( integ );
		insert integList;
        test.startTest();
        
        TS_ClickSyncMasterData controller = new TS_ClickSyncMasterData();
        controller.executeSessionId(integList);
        test.stopTest();
        List<Integration_Log__c> count = [Select Id from Integration_Log__c where Integration_Status__c !=: INT_Constants.TARGET_SYSTEM_SUCCESS];
        System.assertnotequals(0, count.size());
        
    }
}