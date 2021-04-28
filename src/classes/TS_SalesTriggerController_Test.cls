/**
* @author        Paul Jarred Aguiling
* @date          01.26.2018           
* @description   Test class for TS_SalesTriggerController
* @revision(s)   
*/
@isTest
public class TS_SalesTriggerController_Test {
    static Account acct;
    static Contact con;
    static Case c;
    static WorkOrder wo;
    static Apttus_Config2__Order__c order;
    static Apttus_Config2__Order__c order2;
    static WorkOrderLineItem woli;
    static WorkOrderTrigger__c wotObjHeader;
    static WorkOrderTrigger__c wotObjLineItem;
    static WorkOrderTrigger__c wotObjLineItem2;
    static Apttus_Config2__AccountLocation__c acctLoc;

	/**
	* @author        Paul Jarred Aguiling
	* @date          01.26.2018           
	* @description   Testmethod for setting up default values
	* @revision(s)   
	*/
    @testSetup
    static void dataSetup() {
        //Custom settings is being shared by all test class, if another test class has already inserted the record 
        //this test class will throw "UNABLE_TO_LOCK_ROW, unable to obtain exclusive access to this record"
        try {
            TriggerSettings__c trg = TriggerSettings__c.getOrgDefaults();
            trg.CaseTrigger__c = true;
            trg.WorkOrderTrigger__c = true;
            trg.WorkOrderLineItemTrigger__c = true;
            upsert trg;      
            system.debug('trg is:'+trg);
        } catch(Exception ex) {
            system.debug(ex);
        }

        try {
            IntegrationTriggerSettings__c trg1 = IntegrationTriggerSettings__c.getOrgDefaults();
            trg1.IntegrationLogTrigger__c = true;
            upsert trg1; 
        } catch(Exception ex) {
            system.debug(ex);
        }

        ProcessBuilderSettings__c pb = new ProcessBuilderSettings__c();
        pb.WorkOrderPBFlows__c = true;
        pb.CasePBFlows__c = true;
        insert pb;
        
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
    }

    /**
    * @author        Paul Aguiling
    * @date          1.26.2018           
    * @description   Method responsible for creating test data
    * @revision(s)
    */
    static void setupTestData() {
        acct = new Account(Name='Account', Phone='+31302979111');
        insert acct;
        
        con = TS_TestDataFactory.createContact();  
        con.Preferred_Language__c = 'SAP_EN';
        Insert con;
        
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

		Pricebook2 customPB = new Pricebook2(Name = 'Custom Pricebook', isActive = true, 
											Is_Country_Standard_Price__c = true, 
											Sales_Organization__c = 'SAP_0333');
        insert customPB;
            
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(), 
            IsActive = true, 
            UseStandardPrice=false,
            Product2Id = prod.Id,
            UnitPrice = 100, 
            OldStandardPrice__c=100.0);
        insert standardPrice;

        PricebookEntry customPrice = new PricebookEntry(
            Pricebook2Id = customPB.Id, 
            IsActive = true, 
            UseStandardPrice=false,
            Product2Id = prod.Id,
            UnitPrice = 100, 
            OldStandardPrice__c=100.0);
        insert customPrice;


        Product2 prod2 = TS_TestDataFactory.createProduct('Test Product II', 'MA');
        prod2.APTS_Installation_Type__c = 'Installation';
        insert prod2;

        acctLoc = new Apttus_Config2__AccountLocation__c(Name='AL Test Account', 
                                                        Apttus_Config2__AccountId__c = acct.Id, 
                                                        Customer_calendar_key__c = 'SAP_BE');
        insert acctLoc;

        Apttus_Config2__AccountLocation__c acctLoc2 = new Apttus_Config2__AccountLocation__c(Name='AL Test Account 2', 
                                                                                            Apttus_Config2__AccountId__c = acct.Id, 
                                                                                            Customer_calendar_key__c = 'SAP_BE');
        insert acctLoc2;

        wotObjLineItem = new WorkOrderTrigger__c();
        wotObjLineItem.ServiceContact__c = con.Id;
        wotObjLineItem.ParentOrder__c = order.Id;
        wotObjLineItem.GenerateServiceOrder__c = true;
        wotObjLineItem.SalesOrganization__c = 'SAP_0333';
        wotObjLineItem.Type__c = Label.TS_WOTType_LineItem;
        wotObjLineItem.OrderType__c = Label.TS_WOTOrderType_Installation;
        wotObjLineItem.Product__c = prod.Id;
        wotObjLineItem.RequestedActivityDate__c = Date.today();
        wotObjLineItem.Subject__c = 'Test Subject Line Item';
        wotObjLineItem.Description__c = 'Test Description Line Item';
        wotObjLineItem.Stopover__c = true;
        wotObjLineItem.AccountLocation__c = acctLoc.Id;

        insert wotObjLineItem;

        wotObjLineItem2 = new WorkOrderTrigger__c();
        wotObjLineItem2.ServiceContact__c = con.Id;
        wotObjLineItem2.ParentOrder__c = order.Id;
        wotObjLineItem2.GenerateServiceOrder__c = true;
        wotObjLineItem2.SalesOrganization__c = 'SAP_0333';
        wotObjLineItem2.Type__c = Label.TS_WOTType_LineItem;
        wotObjLineItem2.OrderType__c = Label.TS_WOTOrderType_Installation;
        wotObjLineItem2.Product__c = prod.Id;
        wotObjLineItem2.RequestedActivityDate__c = Date.today();
        wotObjLineItem2.Subject__c = 'Test Subject Line Item 2';
        wotObjLineItem2.Description__c = 'Test Description Line Item 2';
        wotObjLineItem2.Stopover__c = true;
        wotObjLineItem2.AccountLocation__c = acctLoc2.Id;

        insert wotObjLineItem2;

        wotObjHeader = new WorkOrderTrigger__c();
        wotObjHeader.ServiceContact__c = con.Id;
        wotObjHeader.ParentOrder__c = order.Id;
        wotObjHeader.GenerateServiceOrder__c = true;
        wotObjHeader.SalesOrganization__c = 'SAP_0333';
        wotObjHeader.Type__c = Label.TS_WOTType_Header;
        wotObjHeader.OrderType__c = Label.TS_WOTOrderType_Installation;
        wotObjHeader.Product__c = prod.Id;
        wotObjHeader.RequestedActivityDate__c = Date.today();
        wotObjHeader.Subject__c = 'Test Subject Header';
        wotObjHeader.Description__c = 'Test Description Header';
        wotObjHeader.PickingDate__c = Date.newInstance(2018, 1, 10);

        insert wotObjHeader;
    }

    /**
    * @author        Paul Aguiling
    * @date          1.26.2018           
    * @description   Method responsible for exception scenario
    * @revision(s)
    */
    static testMethod void testException() {
        User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(usr) {

        	List<Id> parentOrderIds = new List<Id>();
        	TS_SalesTriggerController salesTrigger = new TS_SalesTriggerController();
        	TS_SalesTriggerController.hasException = true;
        	salesTrigger.getWorkOrderTriggerRecords(parentOrderIds);

            Test.startTest();
	            System.assert(TS_SalesTriggerController.hasException);
            Test.stopTest();
        }
    }

    /**
    * @author        Paul Aguiling
    * @date          1.26.2018           
    * @description   Method responsible for createInstallationOrder test method
    * @revision(s)
    */
    static testMethod void testInstallationOrder() {
        User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(usr) {
            setupTestData();

            wotObjLineItem2.AccountLocation__c = acctLoc.Id;
            update wotObjLineItem2;

        	List<Id> parentOrderIds = new List<Id>();
        	parentOrderIds.add(order.Id);

        	TS_SalesTriggerController salesTrigger = new TS_SalesTriggerController();
        	salesTrigger.getWorkOrderTriggerRecords(parentOrderIds);

            Test.startTest();
	            List<Case> caseList = [SELECT Id FROM Case WHERE ApptusOrder__c = :order.Id];
	            System.assert(caseList != null);
            Test.stopTest();
        }
    }

    /**
    * @author        Paul Aguiling
    * @date          1.26.2018           
    * @description   Method responsible for createInstallationOrder test method
    * @revision(s)
    */
    static testMethod void testInstallationOrder2() {
        User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(usr) {
            setupTestData();

            wotObjLineItem.Stopover__c = false;
            update wotObjLineItem;

        	List<Id> parentOrderIds = new List<Id>();
        	parentOrderIds.add(order.Id);

        	TS_SalesTriggerController salesTrigger = new TS_SalesTriggerController();
        	salesTrigger.getWorkOrderTriggerRecords(parentOrderIds);

            Test.startTest();
	            List<Case> caseList = [SELECT Id FROM Case WHERE ApptusOrder__c = :order.Id];
	            System.assert(caseList != null);
            Test.stopTest();
        }
    }

    /**
    * @author        Paul Aguiling
    * @date          1.26.2018           
    * @description   Method responsible for createDeInstallationOrder test method
    * @revision(s)
    */
    static testMethod void testDeInstallationOrder() {
        User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(usr) {
            setupTestData();

            wotObjLineItem.OrderType__c = Label.TS_WOTOrderType_DeInstallation;
            update wotObjLineItem;

            wotObjLineItem2.OrderType__c = Label.TS_WOTOrderType_DeInstallation;
            update wotObjLineItem2;

            wotObjHeader.OrderType__c = Label.TS_WOTOrderType_DeInstallation;
            wotObjHeader.GenerateServiceOrder__c = false;
            update wotObjHeader;

            wotObjHeader.GenerateServiceOrder__c = true;
            update wotObjHeader;

        	List<Id> parentOrderIds = new List<Id>();
        	parentOrderIds.add(order.Id);

        	TS_SalesTriggerController salesTrigger = new TS_SalesTriggerController();
        	salesTrigger.getWorkOrderTriggerRecords(parentOrderIds);

            Test.startTest();
	            List<Case> caseList = [SELECT Id FROM Case WHERE ApptusOrder__c = :order.Id];
	            System.assert(caseList != null);
            Test.stopTest();
        }
    }

    /**
    * @author        Paul Aguiling
    * @date          1.26.2018           
    * @description   Method responsible for createSwapOrder test method
    * @revision(s)
    */
    static testMethod void testSwapOrder() {
        User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(usr) {
            setupTestData();

            wotObjLineItem2.OrderType__c = Label.TS_WOTOrderType_Swap;
            wotObjLineItem2.OrderSubType__c = Label.TS_WOTOrderType_DeInstallation;
            wotObjLineItem2.AccountLocation__c = acctLoc.Id;
            update wotObjLineItem2;

            wotObjLineItem.OrderType__c = Label.TS_WOTOrderType_Swap;
            wotObjLineItem.OrderSubType__c = Label.TS_WOTOrderType_Installation;
            wotObjLineItem.ParentOrder__c = order2.Id;
            wotObjLineItem.DependentDeInstallation__c = wotObjLineItem2.Id;
            update wotObjLineItem;

            wotObjHeader.OrderType__c = Label.TS_WOTOrderType_Swap;
            wotObjHeader.GenerateServiceOrder__c = false;
            wotObjHeader.ChildOrder__c = order2.Id;
            update wotObjHeader;

            wotObjHeader.GenerateServiceOrder__c = true;
            update wotObjHeader;

        	List<Id> parentOrderIds = new List<Id>();
        	parentOrderIds.add(order.Id);
        	parentOrderIds.add(order2.Id);

        	TS_SalesTriggerController salesTrigger = new TS_SalesTriggerController();
        	salesTrigger.getWorkOrderTriggerRecords(parentOrderIds);

            Test.startTest();
	            List<Case> caseList = [SELECT Id FROM Case WHERE ApptusOrder__c = :order.Id];
	            System.assert(caseList != null);
            Test.stopTest();
        }
    }

    /**
    * @author        Paul Aguiling
    * @date          1.26.2018           
    * @description   Method responsible for createMovementOrder test method
    * @revision(s)
    */
    static testMethod void testMovementOrder() {
        User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(usr) {
            setupTestData();

            wotObjLineItem2.OrderType__c = Label.TS_WOTOrderType_Swap;
            wotObjLineItem2.OrderSubType__c = Label.TS_WOTOrderType_DeInstallation;
            wotObjLineItem2.AccountLocation__c = acctLoc.Id;
            update wotObjLineItem2;

            wotObjLineItem.OrderType__c = Label.TS_WOTOrderType_Swap;
            wotObjLineItem.OrderSubType__c = Label.TS_WOTOrderType_Installation;
            wotObjLineItem.ParentOrder__c = order2.Id;
            wotObjLineItem.DependentDeInstallation__c = wotObjLineItem2.Id;
            update wotObjLineItem;

            wotObjHeader.OrderType__c = Label.TS_WOTOrderType_Movement;
            wotObjHeader.GenerateServiceOrder__c = false;
            wotObjHeader.ChildOrder__c = order2.Id;
            update wotObjHeader;

            wotObjHeader.GenerateServiceOrder__c = true;
            update wotObjHeader;

        	List<Id> parentOrderIds = new List<Id>();
        	parentOrderIds.add(order.Id);
        	parentOrderIds.add(order2.Id);

        	TS_SalesTriggerController salesTrigger = new TS_SalesTriggerController();
        	salesTrigger.getWorkOrderTriggerRecords(parentOrderIds);

            Test.startTest();
	            List<Case> caseList = [SELECT Id FROM Case WHERE ApptusOrder__c = :order.Id];
	            System.assert(caseList != null);
            Test.stopTest();
        }
    }

    /**
    * @author        Paul Aguiling
    * @date          1.26.2018           
    * @description   Method responsible for createConversionOrder test method
    * @revision(s)
    */
    static testMethod void testConversionOrder() {
        User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(usr) {
            setupTestData();

            wotObjLineItem.OrderType__c = Label.TS_WOTOrderType_Conversion;
            wotObjLineItem.OrderSubType__c = Label.TS_WOTOrderType_Installation;
            wotObjLineItem.ParentOrder__c = order2.Id;
            update wotObjLineItem;

            wotObjLineItem2.OrderType__c = Label.TS_WOTOrderType_Conversion;
            wotObjLineItem2.OrderSubType__c = Label.TS_WOTOrderType_DeInstallation;
            wotObjLineItem2.AccountLocation__c = acctLoc.Id;
            update wotObjLineItem2;

            wotObjHeader.OrderType__c = Label.TS_WOTOrderType_Conversion;
            wotObjHeader.GenerateServiceOrder__c = false;
            wotObjHeader.ChildOrder__c = order2.Id;
            update wotObjHeader;

            wotObjHeader.GenerateServiceOrder__c = true;
            update wotObjHeader;

        	List<Id> parentOrderIds = new List<Id>();
        	parentOrderIds.add(order.Id);
        	parentOrderIds.add(order2.Id);

        	TS_SalesTriggerController salesTrigger = new TS_SalesTriggerController();
        	salesTrigger.getWorkOrderTriggerRecords(parentOrderIds);

            Test.startTest();
	            List<Case> caseList = [SELECT Id FROM Case WHERE ApptusOrder__c = :order.Id];
	            System.assert(caseList != null);
            Test.stopTest();
            
        }
    }
}