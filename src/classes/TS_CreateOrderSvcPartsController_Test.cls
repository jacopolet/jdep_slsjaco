/**
* @author        Paul Jarred Aguiling
* @date          06.03.2018
* @description   Test class for TS_CreateOrderSvcPartsController
* @revision(s)
*/
@isTest
private class TS_CreateOrderSvcPartsController_Test {
	
    static Account acct;
    static Contact con;
    static Case c;

   /**
	* @author        Paul Jarred Aguiling
	* @date          06.03.2018         
    * @description   Method responsible for creating custom setting records
    * @revision(s)
    */
    @testSetup
    static void dataSetup() {
        TriggerSettings__c trg = TriggerSettings__c.getOrgDefaults();
        trg.WorkOrderLineItemTrigger__c = true;
        upsert trg;
        
        IntegrationTriggerSettings__c trg1 = IntegrationTriggerSettings__c.getOrgDefaults();
        trg1.IntegrationLogTrigger__c = true;
        upsert trg1;
        
        ProcessBuilderSettings__c pb = new ProcessBuilderSettings__c();
        pb.CasePBFlows__c = true;
        insert pb;  
    }
    
    /**
	* @author        Paul Jarred Aguiling
	* @date          06.03.2018        
    * @description   Method responsible for creating test data
    * @revision(s)
    */
    static void setupTestData() {
        acct = new Account(Name='Account', Phone='+31302979111');
        //acct.Segment__c = 'SAP_A';
        //acct.High_Segment__c = 'Business';
        insert acct;
        
        con = TS_TestDataFactory.createContact();  
        con.Preferred_Language__c = 'SAP_EN';
        Insert con;
        
        Apttus_Config2__AccountLocation__c accLoc = new Apttus_Config2__AccountLocation__c();
        accLoc.Name = 'Test Loc';
        accLoc.Apttus_Config2__AccountId__c = acct.id;
        accLoc.Customer_calendar_key__c = 'SAP_01';
        insert accLoc; 

        c = TS_TestDataFactory.createFieldServiceCase();
        c.ContactId = con.Id;
        c.SalesOrganization__c = 'SAP_0333';
        c.AccountLocation__c = accLoc.Id;
        insert c;
    }
	
    /**
	* @author        Paul Jarred Aguiling
	* @date          06.03.2018        
    * @description   Test method for fetchPicklistValues
    * @revision(s)
    */
	static testmethod void test_fetchPicklistValues() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(u) {
            Test.startTest();
	            List<String> result = TS_CreateOrderSvcPartsController.fetchPicklistValues('WorkOrderLineItem', 'Warranty__c');
	            System.assert(result != null);
            Test.stopTest();
        }
	}

    /**
	* @author        Paul Jarred Aguiling
	* @date          06.03.2018        
    * @description   Test method for convertOrderServer Required Parts Scenario
    * @revision(s)
    */
	static testmethod void test_convertOrderServer() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(u) {
        	setupTestData();
	        Product2 prod = new Product2(Name = 'Laptop X200', 
	            Family = 'Hardware');
	        insert prod;
	        
	        Id pricebookId = Test.getStandardPricebookId();
	        
	        PricebookEntry standardPrice = new PricebookEntry(
	            Pricebook2Id = pricebookId, Product2Id = prod.Id,
	            UnitPrice = 10000, IsActive = true);
	        insert standardPrice;

	        Pricebook2 customPB = new Pricebook2(Name='Custom Pricebook', 
	        	isActive=true, 
	        	Is_Country_Standard_Price__c = true,
	        	Sales_Organization__c = 'SAP_0333');
	        insert customPB;
	        
	        PricebookEntry customPrice = new PricebookEntry(
	            Pricebook2Id = customPB.Id, Product2Id = prod.Id,
	            UnitPrice = 12000, OldStandardPrice__c=100.0, IsActive = true);
	        insert customPrice;

        	TS_CreateOrderSvcPartsController.WorkOrderLineItemWrapperClass wrapper = new TS_CreateOrderSvcPartsController.WorkOrderLineItemWrapperClass();
        	wrapper.partType = 'RequiredSpareparts';
        	wrapper.existing = true;
        	wrapper.directTo = false;
        	wrapper.woPBId = pricebookId;
        	wrapper.taskpbEntryId = standardPrice.Id;
        	wrapper.matType = 'ZSPR';
        	wrapper.quantity = 1;
        	wrapper.wolipbEntry = standardPrice;
        	wrapper.billingInfo = 'K1';

			List<Object> addList = new List<Object>();
			addList.add(wrapper);
	        String jSONClass = JSON.serialize(addList);

        	Test.startTest();
        		String result = TS_CreateOrderSvcPartsController.convertOrderServer(c.Id, jSONClass);
        		System.assert(result != null);
        	Test.stopTest();
        }
    }

   /**
	* @author        Paul Jarred Aguiling
	* @date          06.03.2018        
    * @description   Test method for convertOrderServer Service Materials Scenario
    * @revision(s)
    */
	static testmethod void test_convertOrderServer2() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(u) {
        	setupTestData();
	        Product2 prod = new Product2(Name = 'Laptop X200', 
	            Family = 'Hardware');
	        insert prod;
	        
	        Id pricebookId = Test.getStandardPricebookId();
	        
	        PricebookEntry standardPrice = new PricebookEntry(
	            Pricebook2Id = pricebookId, Product2Id = prod.Id,
	            UnitPrice = 10000, IsActive = true);
	        insert standardPrice;

	        Pricebook2 customPB = new Pricebook2(Name='Custom Pricebook', 
	        	isActive=true, 
	        	Is_Country_Standard_Price__c = true,
	        	Sales_Organization__c = 'SAP_0333');
	        insert customPB;
	        
	        PricebookEntry customPrice = new PricebookEntry(
	            Pricebook2Id = customPB.Id, Product2Id = prod.Id,
	            UnitPrice = 12000, OldStandardPrice__c=100.0, IsActive = true);
	        insert customPrice;

        	TS_CreateOrderSvcPartsController.WorkOrderLineItemWrapperClass wrapper = new TS_CreateOrderSvcPartsController.WorkOrderLineItemWrapperClass();
        	wrapper.partType = 'Service Materials';
        	wrapper.existing = true;
        	wrapper.directTo = false;
        	wrapper.woPBId = pricebookId;
        	wrapper.taskpbEntryId = standardPrice.Id;
        	wrapper.matType = 'ZSPR';
        	wrapper.quantity = 1;
        	wrapper.wolipbEntry = standardPrice;
        	wrapper.billingInfo = 'K1';

			List<Object> addList = new List<Object>();
			addList.add(wrapper);
	        String jSONClass = JSON.serialize(addList);

        	Test.startTest();
        		String result = TS_CreateOrderSvcPartsController.convertOrderServer(c.Id, jSONClass);
        		System.assert(result != null);
        	Test.stopTest();
        }
    }

    /**
	* @author        Paul Jarred Aguiling
	* @date          06.03.2018        
    * @description   Test method for convertOrderServer Exception
    * @revision(s)
    */
	static testmethod void test_convertOrderServerException() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(u) {
	        Test.startTest();

	        	TS_CreateOrderSvcPartsController.WorkOrderLineItemWrapperClass wrapper = new TS_CreateOrderSvcPartsController.WorkOrderLineItemWrapperClass();
	        	wrapper.partType = 'Service Materials';
	        	wrapper.existing = true;
	        	wrapper.directTo = false;
	        	wrapper.woPBId = null;
	        	wrapper.taskpbEntryId = null;
	        	wrapper.matType = 'ZSPR';
	        	wrapper.quantity = 1;
	        	wrapper.wolipbEntry = null;
	        	wrapper.billingInfo = 'K1';

				List<Object> addList = new List<Object>();
				addList.add(wrapper);
		        String jSONClass = JSON.serialize(addList);
	        	String result;

	        	try {
		        	result = TS_CreateOrderSvcPartsController.convertOrderServer(null, jSONClass);
		        } catch(Exception e) {
			        System.assert(result != null);
		        }
	        Test.stopTest();
        }
    }

    /**
	* @author        Paul Jarred Aguiling
	* @date          06.03.2018        
    * @description   Test method for retrievePricebookEntry
    * @revision(s)
    */
	static testmethod void test_retrievePricebookEntry() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(u) {
        	Product2 prod = new Product2(Name = 'Laptop X200', 
	        Family = 'Hardware');
	        insert prod;
	        
	        Id pricebookId = Test.getStandardPricebookId();
	        
	        PricebookEntry standardPrice = new PricebookEntry(
	            Pricebook2Id = pricebookId, Product2Id = prod.Id,
	            UnitPrice = 10000, IsActive = true);
	        insert standardPrice;

	        Pricebook2 customPB = new Pricebook2(Name='Custom Pricebook', 
	        	isActive=true, 
	        	Is_Country_Standard_Price__c = true,
	        	Sales_Organization__c = 'SAP_0333');
	        insert customPB;
	        
	        PricebookEntry customPrice = new PricebookEntry(
	            Pricebook2Id = customPB.Id, Product2Id = prod.Id,
	            UnitPrice = 12000, OldStandardPrice__c=100.0, IsActive = true);
	        insert customPrice;

	        Test.startTest();
		        Object obj = TS_CreateOrderSvcPartsController.retrievePricebookEntry('SAP_0333', prod.Id);
		        System.assert(obj != null);
	        Test.stopTest();
        }
    }

    /**
	* @author        Paul Jarred Aguiling
	* @date          06.03.2018        
    * @description   Test method for retrievePricebookEntry
    * @revision(s)
    */
	static testmethod void test_retrievePricebookEntryException() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(u) {
	        Test.startTest();
	        	Object obj;
	        	try {
		        	obj = TS_CreateOrderSvcPartsController.retrievePricebookEntry(null, null);
		        } catch(Exception e) {
			        System.assert(obj == null);
		        }
	        Test.stopTest();
        }
    }
}