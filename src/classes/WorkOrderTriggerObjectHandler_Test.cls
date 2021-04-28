/**
* @author        Paul Jarred Aguiling
* @date          01.26.2018           
* @description   Test class for WorkOrderTriggerObjectHandler
* @revision(s)   
*/
@isTest
private class WorkOrderTriggerObjectHandler_Test {
	
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
            trg.WorkOrderTriggerObject__c = true;
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
        prod.APTS_Technician_Not_Required__c = true;
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
        prod2.APTS_Technician_Not_Required__c = true;
        insert prod2;

        acctLoc = new Apttus_Config2__AccountLocation__c(Name='AL Test Account', 
                                                        Apttus_Config2__AccountId__c = acct.Id, 
                                                        Customer_calendar_key__c = 'SAP_BE');
        insert acctLoc;

        Apttus_Config2__AccountLocation__c acctLoc2 = new Apttus_Config2__AccountLocation__c(Name='AL Test Account 2', 
                                                                                            Apttus_Config2__AccountId__c = acct.Id, 
                                                                                            Customer_calendar_key__c = 'SAP_BE');
        insert acctLoc2;
        
        PhysicalAsset__c pa = TS_TestDataFactory.createPhysicalAsset();
        insert pa;
        
        Apttus_Config2__OrderLineItem__c oli = TS_TestDataFactory.createOrderLineItem('Active',prod2.Id,order.Id,null);
		insert oli;
        
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
        wotObjLineItem.Stopover__c = false;
        wotObjLineItem.AccountLocation__c = acctLoc.Id;

        insert wotObjLineItem;

        wotObjLineItem2 = new WorkOrderTrigger__c();
        wotObjLineItem2.ServiceContact__c = con.Id;
        wotObjLineItem2.ParentOrder__c = order2.Id;
        wotObjLineItem2.GenerateServiceOrder__c = true;
        wotObjLineItem2.SalesOrganization__c = 'SAP_0333';
        wotObjLineItem2.Type__c = Label.TS_WOTType_LineItem;
        wotObjLineItem2.OrderType__c = Label.TS_WOTOrderType_Installation;
        wotObjLineItem2.Product__c = prod.Id;
        wotObjLineItem2.RequestedActivityDate__c = Date.today();
        wotObjLineItem2.Subject__c = 'Test Subject Line Item 2';
        wotObjLineItem2.Description__c = 'Test Description Line Item 2';
        wotObjLineItem2.Stopover__c = false;
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
        wotObjHeader.ChildOrder__c = order2.Id;

        insert wotObjHeader;
        
        WorkOrderTrigger__c wot = new WorkOrderTrigger__c();
        wot.PhysicalAsset__c = pa.Id;
        wot.ServiceContact__c = con.Id;
        wot.ParentOrder__c = order.Id;
        wot.OrderLineItem__c = oli.id;
        wot.GenerateServiceOrder__c = true;
        wot.SalesOrganization__c = 'SAP_0333';
        wot.Type__c = Label.TS_WOTType_Header;
        wot.OrderType__c = Label.APTS_De_InstallationTS;
        wot.Product__c = prod.Id;
        wot.RequestedActivityDate__c = Date.today();
        wot.Subject__c = 'Test Subject Header';
        wot.Description__c = 'Test Description Header';
        wot.ChildOrder__c = order2.Id;
        
        insert wot;
    }

    /**
    * @author        Paul Aguiling
    * @date          1.26.2018           
    * @description   Method responsible for insert scenario
    * @revision(s)
    */
    static testMethod void testInsert() {
        User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(usr) {
            setupTestData();

            Test.startTest();
	            List<Case> caseList = [SELECT Id FROM Case WHERE ApptusOrder__c = :order.Id];
	            System.assert(caseList != null);
            Test.stopTest();
        }
    }

    /**
    * @author        Paul Aguiling
    * @date          1.26.2018           
    * @description   Method responsible for insert exception scenario
    * @revision(s)
    */
    static testMethod void testInsertException() {
        User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(usr) {
        	WorkOrderTriggerObjectHandler.hasException = true;
            setupTestData();

            Test.startTest();
	            System.assert(WorkOrderTriggerObjectHandler.hasException);
            Test.stopTest();
        }
    }

    /**
    * @author        Paul Aguiling
    * @date          1.26.2018           
    * @description   Method responsible for update scenario
    * @revision(s)
    */
    static testMethod void testUpdate() {
        User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(usr) {
            setupTestData();

            wotObjHeader.OrderType__c = Label.TS_WOTOrderType_DeInstallation;
            wotObjHeader.GenerateServiceOrder__c = false;
            update wotObjHeader;

            wotObjHeader.GenerateServiceOrder__c = true;
            update wotObjHeader;

            Test.startTest();
	            List<Case> caseList = [SELECT Id FROM Case WHERE ApptusOrder__c = :order.Id];
	            System.assert(caseList != null);
            Test.stopTest();
        }
    }

    /**
    * @author        Paul Aguiling
    * @date          1.26.2018           
    * @description   Method responsible for update exception scenario
    * @revision(s)
    */
    static testMethod void testUpdateException() {
        User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(usr) {
            setupTestData();
			WorkOrderTriggerObjectHandler.hasException = true;
			
            wotObjHeader.OrderType__c = Label.TS_WOTOrderType_DeInstallation;
            wotObjHeader.GenerateServiceOrder__c = false;
            update wotObjHeader;

            wotObjHeader.GenerateServiceOrder__c = true;
            update wotObjHeader;

            Test.startTest();
	            System.assert(WorkOrderTriggerObjectHandler.hasException);
            Test.stopTest();
        }
    }

    /**
    * @author        Paul Aguiling
    * @date          2.28.2018           
    * @description   Test method for assignWOTRecordType
    * @revision(s)
    */
    static testMethod void testAssignWOTRecordType() {
        User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(usr) {
            setupTestData();
            WorkOrderTrigger__c wotOption = new WorkOrderTrigger__c();
            wotOption.GenerateServiceOrder__c = true;
            wotOption.SalesOrganization__c = 'SAP_0333';
            wotOption.Type__c = Label.TS_WOTType_Option;
            wotOption.OrderType__c = Label.TS_WOTOrderType_Installation;
            wotOption.Subject__c = 'Test Subject Line Item';

            insert wotOption;

            Test.startTest();
                System.assertEquals(Label.TS_WOTType_Option, [SELECT Id, RecordType.Name FROM WorkOrderTrigger__c WHERE Id =: wotOption.Id].RecordType.Name);
            Test.stopTest();
        }
    }

    /**
    * @author        Paul Aguiling
    * @date          2.28.2018           
    * @description   Test method for assignWOTRecordType
    * @revision(s)
    */
    static testMethod void testAssignWOTRecordType2() {
        User usr = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(usr) {
            setupTestData();
            wotObjLineItem.Type__c = Label.TS_WOTType_Option;
            update wotObjLineItem;

            wotObjLineItem.Type__c = Label.TS_WOTType_LineItem;
            update wotObjLineItem;

            wotObjLineItem.Type__c = Label.TS_WOTType_Header;
            update wotObjLineItem;

            Test.startTest();
                 System.assertEquals(Label.TS_WOTType_Header, [SELECT Id, RecordType.Name FROM WorkOrderTrigger__c WHERE Id =: wotObjLineItem.Id].RecordType.Name);
            Test.stopTest();
        }
    }
	
}