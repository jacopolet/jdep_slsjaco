/**
* @author        Adrian Reyes
* @date          02.19.2018           
* @description   Test class for TS_LSPDatesCalculator
* @revision(s)   
*/
@isTest
private class TS_LSPDatesCalculatorTest {
    static WorkOrderTrigger__c wotObjHeader;
    static WorkOrderTrigger__c wotObjLineItem;
    static WorkOrderTrigger__c wotObjLineItem2;
    static Apttus_Config2__Order__c order;
    static Apttus_Config2__Order__c order2;
    static BusinessHours bHours;
	
    /**
    * @author        Adrian Reyes
    * @date          02.19.2018
    * @description   Testmethod for setting up default values
    * @revision(s)   
    */
    @testSetup
    static void dataSetup() {
        TriggerSettings__c trg = TriggerSettings__c.getOrgDefaults();
        trg.WorkOrderTrigger__c = true;
        upsert trg;
        
        ProcessBuilderSettings__c pb = new ProcessBuilderSettings__c();
        pb.WorkOrderPBFlows__c = true;
        insert pb;
        
       
        bHours =[select id from BusinessHours where Name = 'Default'];
        
        CountrySetting__c countryScheduleDateTimeSettings = new CountrySetting__c();
        countryScheduleDateTimeSettings.RecordTypeId = Schema.SObjectType.CountrySetting__c.getRecordTypeInfosByName().get('Country Schedule Date/Time Settings').getRecordTypeId();
        countryScheduleDateTimeSettings.Name = 'Belgium - Installation';
        countryScheduleDateTimeSettings.Country__c = 'SAP_0333';
        countryScheduleDateTimeSettings.Business_Hours__c = bHours.id;//
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
        countryDefaultBusinessHours.Business_Hours__c = bHours.id; //
        countryDefaultBusinessHours.Active__c = true;
        insert countryDefaultBusinessHours;
        
        CountrySetting__c countrySchedulingRules = new CountrySetting__c();
        countrySchedulingRules.RecordTypeId = Schema.SObjectType.CountrySetting__c.getRecordTypeInfosByName().get('Country Scheduling Rules').getRecordTypeId();
        countrySchedulingRules.Name = 'Belgium - Without Round-Trip';
        countrySchedulingRules.Business_Hours__c = [select id from BusinessHours where Name = 'Default'].id; //
        countrySchedulingRules.Country__c = 'SAP_0333';
        countrySchedulingRules.RoundTrip__c = false;
        countrySchedulingRules.DeliveryOffset__c = 1;
        countrySchedulingRules.PickupOffset__c = 1;
        countrySchedulingRules.Active__c = true;
        insert countrySchedulingRules;
    }
	
    /**
    * @author        Adrian Reyes
    * @date          02.19.2018
    * @description   Method responsible for creating test data
    * @revision(s)
    */
    static void setupTestData() {
        Account acct = new Account(Name='Account', Phone='+31302979111');
        insert acct;
        
        Contact con = TS_TestDataFactory.createContact();  
        con.Preferred_Language__c = 'SAP_EN';
        insert con;
        
        order = TS_TestDataFactory.createOrderRecord('Draft', 'New');
        order.Apttus_Config2__ShipToAccountId__c = acct.Id;
        order.Apttus_Config2__SoldToAccountId__c = acct.Id;
        order.Apttus_Config2__BillToAccountId__c = acct.Id;
        insert order;
		
        order2 = TS_TestDataFactory.createOrderRecord('Draft', 'New');
        order.Apttus_Config2__ShipToAccountId__c = acct.Id;
        order.Apttus_Config2__SoldToAccountId__c = acct.Id;
        order.Apttus_Config2__BillToAccountId__c = acct.Id;
        insert order2;
		
        Product2 prod = TS_TestDataFactory.createProduct('Test Product I', 'MA');
        insert prod;
		
        Apttus_Config2__AccountLocation__c acctLoc = new Apttus_Config2__AccountLocation__c(Name='AL Test Account', Apttus_Config2__AccountId__c = acct.Id, Customer_calendar_key__c = 'SAP_BE');
        insert acctLoc;
		
        Apttus_Config2__AccountLocation__c acctLoc2 = new Apttus_Config2__AccountLocation__c(Name='AL Test Account 2', Apttus_Config2__AccountId__c = acct.Id, Customer_calendar_key__c = 'SAP_BE');
        insert acctLoc2;
		
        wotObjLineItem = new WorkOrderTrigger__c();
        wotObjLineItem.ServiceContact__c = con.Id;
        wotObjLineItem.ParentOrder__c = order.Id;
        wotObjLineItem.GenerateServiceOrder__c = true;
        wotObjLineItem.SalesOrganization__c = 'SAP_0333';
        wotObjLineItem.Type__c = Label.TS_WOTType_LineItem;
        wotObjLineItem.Product__c = prod.Id;
        wotObjLineItem.RequestedActivityDate__c = Date.today();
        wotObjLineItem.Subject__c = 'Test Subject Line Item';
        wotObjLineItem.Requires_LSP__c = true;
        wotObjLineItem.Description__c = 'Test Description Line Item';
        wotObjLineItem.Stopover__c = true;
        wotObjLineItem.AccountLocation__c = acctLoc.Id;
        
        wotObjLineItem2 = new WorkOrderTrigger__c();
        wotObjLineItem2.ServiceContact__c = con.Id;
        wotObjLineItem2.ParentOrder__c = order.Id;
        wotObjLineItem2.GenerateServiceOrder__c = true;
        wotObjLineItem2.SalesOrganization__c = 'SAP_0333';
        wotObjLineItem2.Type__c = Label.TS_WOTType_LineItem;
        wotObjLineItem2.Product__c = prod.Id;
        wotObjLineItem2.RequestedActivityDate__c = Date.today();
        wotObjLineItem2.Subject__c = 'Test Subject Line Item 2';
        wotObjLineItem2.Requires_LSP__c = true;
        wotObjLineItem2.Description__c = 'Test Description Line Item 2';
        wotObjLineItem2.Stopover__c = true;
        wotObjLineItem2.AccountLocation__c = acctLoc2.Id;
        
        wotObjHeader = new WorkOrderTrigger__c();
        wotObjHeader.ServiceContact__c = con.Id;
        wotObjHeader.ParentOrder__c = order.Id;
        wotObjHeader.GenerateServiceOrder__c = true;
        wotObjHeader.SalesOrganization__c = 'SAP_0333';
        wotObjHeader.Type__c = Label.TS_WOTType_Header;
        wotObjHeader.Requires_LSP__c = true;
        wotObjHeader.Product__c = prod.Id;
        wotObjHeader.RequestedActivityDate__c = Date.today();
        wotObjHeader.Subject__c = 'Test Subject Header';
        wotObjHeader.Description__c = 'Test Description Header';
        wotObjHeader.PickingDate__c = Date.newInstance(2018, 1, 10);
    }
    
    /**
    * @author        Adrian Reyes
    * @date          02.19.2018
    * @description   Method to cover delivery date
    * @revision(s)
    */
    static testMethod void testDeliveryDate() {
        User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(usr) {
            setupTestData();
            
            wotObjLineItem.OrderType__c = Label.TS_WOTOrderType_Installation;
            insert wotObjLineItem;
            
            wotObjHeader.OrderType__c = Label.TS_WOTOrderType_Installation;
            insert wotObjHeader;
            
            TS_SalesTriggerController salesTrigger = new TS_SalesTriggerController();
            salesTrigger.getWorkOrderTriggerRecords(new List<Id>{order.Id});
            
            Test.startTest();
            List<String> woIds = new List<String>();
            List<WorkOrder> woUpdate = new List<WorkOrder>();
            List<WorkOrderLineItem> workOrderLineItems = [SELECT Id, WorkOrderId, WorkOrder.S40_Notice_Count__c FROM WorkOrderLineItem WHERE Case__r.ApptusOrder__c =: order.Id AND WorkOrderType__c =: Label.TS_Order_S40];
            for(WorkOrderLineItem workOrderLineItem: workOrderLineItems){
                workOrderLineItem.Status = Label.TS_WOLI_Status_Scheduled;
                workOrderLineItem.StartDate__c = DateTime.newInstance(2018, 3, 7);
                workOrderLineItem.RequiresLSP__c = true;//
                workOrderLineItem.WorkOrderType__c = 'S40';
                workOrderLineItem.WorkOrderLineItemType__c = 'Task';//
                workOrderLineItem.Installation_Date_S40__c = DateTime.newInstance(2018, 3, 7);
                woIds.add(workOrderLineItem.WorkOrderId);
            }
            update workOrderLineItems;

            TS_LSPDatesCalculator.calculateLSPDates(woIds);
            //TS_LSPDatesCalculator.getNextBusinessDay([SELECT ID FROM BusinessHours WHERE Name = 'Default'].id,system.now() ,1,true);

            Test.stopTest();
            List<Case> apt = [SELECT Id,PlannedDeliveryDate__c FROM Case WHERE ApptusOrder__c =: order.Id LIMIT 1];
            List<WorkOrder> woList = [SELECT ID FROM WorkOrder];
            System.assertEquals(woList.size(), 1);
          
            //Verify results
            //System.assertEquals(Date.newInstance(2018, 3, 6), [SELECT PlannedDeliveryDate__c FROM Case WHERE ApptusOrder__c =: order.Id LIMIT 1].PlannedDeliveryDate__c);
        }
    }
    
    /**
    * @author        Adrian Reyes
    * @date          02.19.2018
    * @description   Method to cover pickup date
    * @revision(s)
    */
    static testMethod void testPickUpDate() {
        User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(usr) {
            setupTestData();
            
            wotObjLineItem.OrderType__c = Label.TS_WOTOrderType_DeInstallation;
            insert wotObjLineItem;
            
            wotObjHeader.OrderType__c = Label.TS_WOTOrderType_DeInstallation;
            insert wotObjHeader;
            
            TS_SalesTriggerController salesTrigger = new TS_SalesTriggerController();
            salesTrigger.getWorkOrderTriggerRecords(new List<Id>{order.Id});
            
            Test.startTest();
            List<String> woIds = new List<String>();
            List<WorkOrderLineItem> workOrderLineItems = [SELECT Id,WorkOrderId FROM WorkOrderLineItem WHERE Case__r.ApptusOrder__c =: order.Id AND WorkOrderType__c =: Label.TS_Order_S41];
            for(WorkOrderLineItem workOrderLineItem: workOrderLineItems){
                workOrderLineItem.Status = Label.TS_WOLI_Status_Scheduled;
                workOrderLineItem.StartDate__c = DateTime.newInstance(2018, 3, 7);
                workOrderLineItem.RequiresLSP__c = true;
                workOrderLineItem.DeInstallationDateS41__c = DateTime.newInstance(2018, 3, 7);
                woIds.add(workOrderLineItem.WorkOrderId);
            }
            update workOrderLineItems;
            
            TS_LSPDatesCalculator.calculateLSPDates(woIds);
            Test.stopTest();
            
            System.assertEquals(woIds.size(), 1);
            List<Case> apt = [SELECT Id,PlannedPickUpDate__c FROM Case WHERE ApptusOrder__c =: order.Id LIMIT 1];
            
            //Verify results
            //System.assertEquals(Date.newInstance(2018, 3, 8), [SELECT PlannedPickUpDate__c FROM Case WHERE ApptusOrder__c =: order.Id LIMIT 1].PlannedPickUpDate__c);
        }
    }
    
    /**
    * @author        Adrian Reyes
    * @date          02.19.2018
    * @description   Method to cover movement date
    * @revision(s)
    */
    static testMethod void testMovementDate() {
        User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(usr) {
            setupTestData();
            
            wotObjLineItem2.OrderType__c = Label.TS_Order_Instype_Movement;
            wotObjLineItem2.OrderSubType__c = Label.TS_WOTOrderType_DeInstallation;
            insert wotObjLineItem2;
            
            wotObjLineItem.OrderType__c = Label.TS_Order_Instype_Movement;
            wotObjLineItem.OrderSubType__c = Label.TS_WOTOrderType_Installation;
            wotObjLineItem.ParentOrder__c = order2.Id;
            wotObjLineItem.DependentDeInstallation__c = wotObjLineItem2.Id;
            insert wotObjLineItem;
            
            wotObjHeader.OrderType__c = Label.TS_Order_Instype_Movement;
            insert wotObjHeader;
            
            TS_SalesTriggerController salesTrigger = new TS_SalesTriggerController();
            salesTrigger.getWorkOrderTriggerRecords(new List<Id>{order.Id, order2.Id});
            
            Test.startTest();
            List<String> woIds = new List<String>();
            List<WorkOrderLineItem> workOrderLineItems = [SELECT Id FROM WorkOrderLineItem WHERE Case__r.ApptusOrder__c =: order.Id AND WorkOrderType__c =: Label.TS_Order_S41];
            for(WorkOrderLineItem workOrderLineItem: workOrderLineItems){
                workOrderLineItem.Status = Label.TS_WOLI_Status_Scheduled;
                workOrderLineItem.StartDate__c = DateTime.newInstance(2018, 3, 7);
                workOrderLineItem.RequiresLSP__c = true;
                workOrderLineItem.DeInstallationDateS41__c = DateTime.newInstance(2018, 3, 7);
                 woIds.add(workOrderLineItem.WorkOrderId);
            }
            update workOrderLineItems;
            TS_LSPDatesCalculator.calculateLSPDates(woIds);
            Test.stopTest();

            System.assertEquals(woIds.size(), 1);

            //Verify results
           // System.assertEquals(Date.newInstance(2018, 3, 8), [SELECT PlannedMovementDate__c FROM Case WHERE ApptusOrder__c =: order.Id LIMIT 1].PlannedMovementDate__c);
        }
    }
}