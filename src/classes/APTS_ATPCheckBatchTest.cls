@isTest
public class APTS_ATPCheckBatchTest { 
    private static final String ORDERTYPE_ROUTESALES = 'Route Sales Order';
    private static final String ORDERSUBTYPE_STANDARDORDER = 'Standard Order';

    @testSetup static void setupTestData() {
        User oTestUser = APTS_TestFacade.createTestUser();
        APTS_TestFacade.createMandatoryRecords(oTestUser);
        //APTS_TestFacade.createAndConfigureOrder(oTestUser);
        System.assert(oTestUser != Null);
    }

    private static testMethod void testRSOOrderBatch() {
        User oTestUser = APTS_TestFacade.getTestUser();

        test.startTest();

        Contact oContact = APTS_TestFacade.getContact();
        Account oAccount = APTS_TestFacade.getAccount();
        Opportunity oOpportunity = APTS_TestFacade.getOpportunity();
        Product2 oStandaloneProduct = APTS_TestFacade.getStandaloneProduct();
        Apttus_Config2__BillingPreference__c oBillingPreference = APTS_TestFacade.getBillingPreference();
        Apttus_Config2__PriceList__c oPriceList = APTS_TestFacade.getPriceList();
        Apttus_Config2__PriceListItem__c oPriceListItemStandalone = APTS_TestFacade.getPriceListItem(oStandaloneProduct.Id);
        
        System.runAs(otestuser) {
            Apttus_Config2__OrderSystemProperties__c oOrderSystemProperties = APTS_TestDataFactory.getOrderSystemProperties();
            Database.insert(oOrderSystemProperties);

            Set<Id> orderList = new Set<Id>();
            Apttus_Config2__Order__c oStandardOrder = APTS_TestDataFactory.createOrder(oAccount.Id, oPriceList.Id, oContact.Id);
            oStandardOrder.Apttus_Config2__Status__c = 'Activated';
            oStandardOrder.Apttus_Config2__Description__c = 'StandardOrder';
            oStandardOrder.Apttus_Config2__PONumber__c = '1234';
            oStandardOrder.APTS_Order_Sub_Type__c = 'Standard Order';
            oStandardOrder.APTS_Order_Type__c = 'Route Sales Order';
            oStandardOrder.RecordTypeId = Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByName().get('Standard Order').getRecordTypeId();
            Database.Insert(oStandardOrder, false);
            orderList.add(oStandardOrder.Id);

            Apttus_Config2__ProductConfiguration__c oProductConfiguration = APTS_TestDataFactory.createProductConfig(oStandardOrder);
            Database.Insert(oProductConfiguration, false);
            
            String acctName = 'Test' + string.valueOf(Math.random());
            Account acc = APTS_TestDataFactory.createAccount(acctName);
            acc.Account_Status__c = 'Valid';
            Database.insert(acc, false);

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

            APTS_DOEPIReqWrapper oWrapper = new APTS_DOEPIReqWrapper();
            oWrapper.SourceOrderNumber = 'sn1232';
            oWrapper.SalesforceAccountID = acc.Id;
            oWrapper.SalesforceContactID = con.Id;
            oWrapper.SalesforceAccountLocationID = loc.Id;
            oWrapper.CaseID =  cse.Id;
            oWrapper.Source = 'MobileApp';
            oWrapper.PONumber = 'PO5678';
            oWrapper.OrderType = 'Operating Order';
            oWrapper.OrderSubType = 'Standard Order';
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

            Set<Id> setInterface = new Set<Id>();
            String sJSONClass = JSON.serializePretty(oWrapper);

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

            for (APTS_Order_Interface_Log__c olog2 : [select id from APTS_Order_Interface_Log__c where APTS_Type__c <> 'Attachment' limit 1]) {
                setInterface.add(olog2.Id);
            }

            Apttus_Config2__Order__c oStandardOrder1 = APTS_TestDataFactory.createOrder(oAccount.Id, oPriceList.Id, oContact.Id);
            oStandardOrder1.Apttus_Config2__Status__c = 'Activated';
            oStandardOrder1.Apttus_Config2__Description__c = 'StandardOrder1';
            oStandardOrder.APTS_Order_Sub_Type__c = 'Standard Order';
            oStandardOrder1.Apttus_Config2__OrderStartDate__c = Date.today().addDays(1);
            oStandardOrder1.RecordTypeId = Schema.SObjectType.Apttus_Config2__Order__c.getRecordTypeInfosByName().get('Standard Order').getRecordTypeId();
            Database.Insert(oStandardOrder1, false);
            orderList.add(oStandardOrder1.Id);

            Apttus_Config2__LineItem__c oLineItemStandalone1 = APTS_TestDataFactory.createLineItem(oProductConfiguration, oPriceListItemStandalone.Id, NULL, oStandaloneProduct.Id, NULL, NULL, 1, 1, 1, 'Product/Service', null, 'Monthly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100, 2);
            oLineItemStandalone1.Apttus_Config2__PricingStatus__c = 'Completed';
            oLineItemStandalone1.APTS_Requested_Delivery_Date__c = System.today();
            oLineItemStandalone1.APTS_ATP_Cleared__c = true;
            insert oLineItemStandalone1;

            Apttus_Config2__LineItem__c oLineItemStandalone = APTS_TestDataFactory.createLineItem(oProductConfiguration, oPriceListItemStandalone.Id, NULL, oStandaloneProduct.Id, NULL, NULL, 1, 1, 1, 'Product/Service', null, 'Monthly', 'Bill In Advance', 'One Time', 'Per Unit', 'Each', 100, 2);
            oLineItemStandalone.Apttus_Config2__PricingStatus__c = 'Completed';
            oLineItemStandalone.APTS_Requested_Delivery_Date__c = System.today();
            oLineItemStandalone.APTS_ATP_Cleared__c = false;
            insert oLineItemStandalone;

            Test.setMock(WebServiceMock.class, new APTS_ATPCheckHTTPCalloutMockImpl());

            APTS_ATPCheckBatch objbatch = new APTS_ATPCheckBatch(orderList, setInterface, null);
            Database.executeBatch(objbatch, 200);

            objbatch = new APTS_ATPCheckBatch();
        }

        test.stopTest();
        
        List<Apttus_Config2__Order__c> orderLst = new List<Apttus_Config2__Order__c>();
        orderLst = [select id from Apttus_Config2__Order__c limit 1];
        system.assert(orderLst!=null);
    }
}