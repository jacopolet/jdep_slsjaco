/**
* @author        Adrian Reyes
* @date          3.13.2018
* @description   Test class for RescheduleRequestTriggerHandler
* @revision(s)
*/

@isTest
private class RescheduleRequestTriggerHandlerTest {
    static Case c;
    static RescheduleRequest__c rescheduleRequest;

    /**
    * @author        Adrian Reyes
    * @date          3.13.2018
    * @description   Method responsible for creating custom setting records
    * @revision(s)
    */
    @testSetup
    static void dataSetup() {
        TriggerSettings__c trg = TriggerSettings__c.getOrgDefaults();
        trg.RescheduleRequest__c = true;
        upsert trg;
        
        CountrySetting__c countryScheduleDateTimeSettings = new CountrySetting__c();
        countryScheduleDateTimeSettings.RecordTypeId = Schema.SObjectType.CountrySetting__c.getRecordTypeInfosByName().get('Country Schedule Date/Time Settings').getRecordTypeId();
        countryScheduleDateTimeSettings.Name = 'Belgium - Installation';
        countryScheduleDateTimeSettings.Country__c = 'SAP_0333';
        countryScheduleDateTimeSettings.OrderType__c = Label.TS_WOTOrderType_Installation;
        countryScheduleDateTimeSettings.CustomerScheduleDateOffset__c = 2;
        countryScheduleDateTimeSettings.LSPScheduleDateOffset__c = 1;
        countryScheduleDateTimeSettings.LSPScheduleTimeOffset__c = 16;
        countryScheduleDateTimeSettings.Active__c = true;
        insert countryScheduleDateTimeSettings;
        
        CountrySetting__c countryDefaultBusinessHours = new CountrySetting__c();
        countryDefaultBusinessHours.RecordTypeId = Schema.SObjectType.CountrySetting__c.getRecordTypeInfosByName().get('Country Default Business Hours').getRecordTypeId();
        countryDefaultBusinessHours.Name = 'Belgium - Business Hours';
        countryDefaultBusinessHours.Country__c = 'SAP_0333';
        countryDefaultBusinessHours.Business_Hours__c = [SELECT Id FROM BusinessHours LIMIT 1].Id;
        countryDefaultBusinessHours.Active__c = true;
        insert countryDefaultBusinessHours;
        
        CountrySetting__c countrySchedulingRules = new CountrySetting__c();
        countrySchedulingRules.RecordTypeId = Schema.SObjectType.CountrySetting__c.getRecordTypeInfosByName().get('Country Scheduling Rules').getRecordTypeId();
        countrySchedulingRules.Name = 'Belgium - Without Round-Trip';
        countrySchedulingRules.Country__c = 'SAP_0333';
        countrySchedulingRules.RoundTrip__c = false;
        countrySchedulingRules.DeliveryOffset__c = 1;
        countrySchedulingRules.PickupOffset__c = 1;
        countrySchedulingRules.Active__c = true;
        insert countrySchedulingRules;
    }
    
    /**
    * @author        Adrian Reyes
    * @date          3.13.2018
    * @description   Method responsible for creating test data
    * @revision(s)
    */
    static void setupTestData() {
        Account acct = new Account(Name='Account', Phone='+31302979111');
        insert acct;
        
        Contact con = TS_TestDataFactory.createContact();  
        con.Preferred_Language__c = 'SAP_EN';
        insert con;
        
        Apttus_Config2__Order__c order = TS_TestDataFactory.createOrderRecord('Draft', 'New');
        order.Apttus_Config2__ShipToAccountId__c = acct.Id;
        order.Apttus_Config2__SoldToAccountId__c = acct.Id;
        order.Apttus_Config2__BillToAccountId__c = acct.Id;
        insert order;
		
        Product2 prod = TS_TestDataFactory.createProduct('Test Product I', 'MA');
        insert prod;
		
        Apttus_Config2__AccountLocation__c acctLoc = new Apttus_Config2__AccountLocation__c(Name='AL Test Account', Apttus_Config2__AccountId__c = acct.Id, Customer_calendar_key__c = 'SAP_BE');
        insert acctLoc;
		
        WorkOrderTrigger__c wotObjLineItem = new WorkOrderTrigger__c();
        wotObjLineItem.ServiceContact__c = con.Id;
        wotObjLineItem.ParentOrder__c = order.Id;
        wotObjLineItem.GenerateServiceOrder__c = true;
        wotObjLineItem.SalesOrganization__c = 'SAP_0333';
        wotObjLineItem.Type__c = Label.TS_WOTType_LineItem;
        wotObjLineItem.Product__c = prod.Id;
        wotObjLineItem.RequestedActivityDate__c = Date.newInstance(2018, 4, 2);
        wotObjLineItem.Subject__c = 'Test Subject Line Item';
        wotObjLineItem.Description__c = 'Test Description Line Item';
        wotObjLineItem.Stopover__c = true;
        wotObjLineItem.AccountLocation__c = acctLoc.Id;
        wotObjLineItem.OrderType__c = Label.TS_WOTOrderType_Installation;
        insert wotObjLineItem;
        
        WorkOrderTrigger__c wotObjHeader = new WorkOrderTrigger__c();
        wotObjHeader.ServiceContact__c = con.Id;
        wotObjHeader.ParentOrder__c = order.Id;
        wotObjHeader.GenerateServiceOrder__c = true;
        wotObjHeader.SalesOrganization__c = 'SAP_0333';
        wotObjHeader.Type__c = Label.TS_WOTType_Header;
        wotObjHeader.Product__c = prod.Id;
        wotObjHeader.RequestedActivityDate__c = Date.newInstance(2018, 4, 2);
        wotObjHeader.Subject__c = 'Test Subject Header';
        wotObjHeader.Description__c = 'Test Description Header';
        wotObjHeader.PickingDate__c = Date.newInstance(2018, 4, 2);
        wotObjHeader.OrderType__c = Label.TS_WOTOrderType_Installation;
        insert wotObjHeader;
        
        TS_SalesTriggerController salesTrigger = new TS_SalesTriggerController();
        salesTrigger.getWorkOrderTriggerRecords(new List<Id>{order.Id});
        
        c = [SELECT Id FROM Case WHERE ApptusOrder__c =: order.Id LIMIT 1];
        
        rescheduleRequest = new RescheduleRequest__c();
        rescheduleRequest.Case__c = c.Id;
        rescheduleRequest.ExpectedDeliveryDate__c = null;
        rescheduleRequest.InitiatedBy__c = 'JDE';
        rescheduleRequest.ParentOrder__c = order.Id;
        rescheduleRequest.PickingDate__c = Date.newInstance(2018, 4, 9);
        rescheduleRequest.RequestedActivityDate__c = Date.newInstance(2018, 4, 9);
        rescheduleRequest.RescheduleReason__c = 'Test Reschedule Reason';
        rescheduleRequest.RescheduleSource__c = 'Order';
    }
    
    /**
    * @author        Adrian Reyes
    * @date          3.13.2018
    * @description   Test method to cover updateCase
    * @revision(s)
    */
    static testMethod void testUpdateCase() {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        // Create PermissionSet with Custom Permission and assign to test user
        PermissionSet ps = new PermissionSet();
        ps.Name = 'TestPermission';
        ps.Label = 'TestPermission';
        insert ps;

        SetupEntityAccess sea = new SetupEntityAccess();
        sea.ParentId = ps.Id;
        sea.SetupEntityId = [SELECT Id FROM CustomPermission WHERE DeveloperName = 'TS_Allow_Order_Rescheduling'][0].Id;
        insert sea;

        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.PermissionSetId = ps.Id;
        psa.AssigneeId = u.Id;
        insert psa;
        
        System.runAs(u) {
            setupTestData();
        
            Test.startTest();
                insert rescheduleRequest;
                
                //Cover methods of other trigger events
                update rescheduleRequest;
                delete rescheduleRequest;
                undelete rescheduleRequest;
            Test.stopTest();
            
            //Verify Results
            //System.assertEquals(Date.newInstance(2018, 4, 9), [SELECT PickingDate__c FROM Case WHERE Id =: c.Id LIMIT 1].PickingDate__c);
        }
    }
}