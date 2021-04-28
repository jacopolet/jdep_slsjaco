/**
* @author        Paul Aguiling
* @date          3.08.2018           
* @description   Test class for TS_CloseTaskWOLIController
* @revision(s)   
*/
@isTest
private class TS_CloseTaskWOLIController_Test {

    static Account acct;
    static Contact con;
    static Case c;
    static WorkOrder wo;
	static WorkOrderLineItem woli;
	static PricebookEntry standardPrice;
	static Product2 prod;
    static PhysicalAsset__c pa;

    /**
    * @author        Paul Jarred Aguiling
    * @date          03.08.2018          
    * @description   Method responsible for creating test data
    * @revision(s)
    */
    static void setupTestData() {
        prod = new Product2(Name = 'Laptop X200', Family = 'Hardware');
        insert prod;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        standardPrice = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prod.Id, UnitPrice = 10000, IsActive = true);
        insert standardPrice;

        acct = new Account(Name='Account', Phone='+31302979111');
        insert acct;
        
        con = TS_TestDataFactory.createContact();  
        con.Preferred_Language__c = 'SAP_EN';
        Insert con;
        
        c = TS_TestDataFactory.createFieldServiceCase();
        c.ContactId = con.Id;
        insert c;
        
        wo = TS_TestDataFactory.createWorkOrder();
        wo.CaseId = c.Id;
        wo.WorkOrderType__c = Label.TS_Case_SubType_CorrectMaint;
        wo.ContactId = con.Id;
        wo.Pricebook2Id = pricebookId;
        insert wo;
        
        woli = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);         
        woli.Case__c = c.Id;
        woli.WorkOrderLineItemType__c = Label.TS_Type_Task;
        woli.EndDate__c = DateTime.now();
        woli.PricebookEntryId = standardPrice.id;

        pa = TS_TestDataFactory.createPhysicalAsset();        
        insert pa;

    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          03.08.2018
    * @description   Method for setting default data
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
    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          03.08.2018
    * @description   Test method for fetchPicklistValues
    * @revision(s)
    */
    static testmethod void testFetchPicklistValues() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(u) {
        	Test.startTest();
        		System.assert(TS_CloseTaskWOLIController.fetchPicklistValues('Case', 'Status') != null);
        	Test.stopTest();
        }
    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          03.08.2018
    * @description   Test method for fetchPicklistValuesMap
    * @revision(s)
    */
    static testmethod void testFetchPicklistValuesMap() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(u) {
        	Test.startTest();
        		System.assert(TS_CloseTaskWOLIController.fetchPicklistValuesMap('Case', 'Status') != null);
        	Test.stopTest();
        }
    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          03.08.2018
    * @description   Test method for queryChildWOLIs
    * @revision(s)
    */
    static testmethod void testQueryChildWOLIs() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(u) {
        	setupTestData();

        	insert woli;

            WorkOrderLineItem childWOLI = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);
            childWOLI.Case__c = c.Id;
            childWOLI.ParentWorkOrderLineItemId = woli.Id;
           	childWOLI.PricebookEntryId = standardPrice.id;
            insert childWOLI;

            Test.startTest();
                System.assert(TS_CloseTaskWOLIController.queryChildWOLIs(woli.Id) != null);
            Test.stopTest();
        	
        }
    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          03.08.2018
    * @description   Test method for getPLvalueOption2
    * @revision(s)
    */
    static testmethod void testGetPLvalueOption2() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(u) {
        	Test.startTest();
        		System.assert(TS_CloseTaskWOLIController.getPLvalueOption2('Case', 'Type', 'SubType__c') != null);
        		System.assert(TS_CloseTaskWOLIController.getPLvalueOption3('Case', 'Type', 'SubType__c') != null);
        	Test.stopTest();
        }
    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          03.08.2018
    * @description   Test method for insertParts
    * @revision(s)
    */
    static testmethod void testInsertParts() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(u) {
        	setupTestData();

        	insert woli;

			TS_CloseTaskWOLIController.woliPartsWrapper wrapper = new TS_CloseTaskWOLIController.woliPartsWrapper();
			wrapper.partType = 'UsedPart';
			wrapper.productId = prod.Id;
			wrapper.directCus = true;
			wrapper.isExisting = true;
			wrapper.recordId = woli.Id;
			wrapper.quantity = 0;
			wrapper.warranty = 'K1';
			List<Object> addList = new List<Object>();
			addList.add(wrapper);
	        String sbody = JSON.serialize(addList);

        	Test.startTest();
        		System.assert(TS_CloseTaskWOLIController.insertParts(sbody, woli.Id, c.Id, wo.id, false, woli, false, false) != null);
        		TS_CloseTaskWOLIController.deleteParts(new List<String>{woli.Id});
        		
        	Test.stopTest();
        }
    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          03.08.2018
    * @description   Test method for insertParts
    * @revision(s)
    */
    static testmethod void testInsertParts2() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(u) {
        	setupTestData();

        	insert woli;

			TS_CloseTaskWOLIController.woliPartsWrapper wrapper = new TS_CloseTaskWOLIController.woliPartsWrapper();
			wrapper.partType = 'UsedPart';
			wrapper.productId = prod.Id;
			wrapper.directCus = true;
			wrapper.isExisting = false;
			wrapper.recordId = woli.Id;
			wrapper.quantity = 0;
			wrapper.warranty = 'K1';
			List<Object> addList = new List<Object>();
			addList.add(wrapper);
	        String sbody = JSON.serialize(addList);

        	Test.startTest();
        		System.assert(TS_CloseTaskWOLIController.insertParts(sbody, woli.Id, c.Id, wo.id, false, woli, false, false) != null);
        	Test.stopTest();
        }
    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          03.08.2018
    * @description   Test method for insertParts
    * @revision(s)
    */
    static testmethod void testInsertParts3() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(u) {
        	setupTestData();

        	insert woli;

			TS_CloseTaskWOLIController.woliPartsWrapper wrapper = new TS_CloseTaskWOLIController.woliPartsWrapper();
			wrapper.partType = 'MissingPart';
			wrapper.productId = prod.Id;
			wrapper.directCus = true;
			wrapper.isExisting = false;
			wrapper.recordId = woli.Id;
			wrapper.quantity = 0;
			wrapper.warranty = 'K1';
			List<Object> addList = new List<Object>();
			addList.add(wrapper);
	        String sbody = JSON.serialize(addList);

        	Test.startTest();
        		System.assert(TS_CloseTaskWOLIController.insertParts(sbody, woli.Id, c.Id, wo.id, false, woli, false, false) != null);
        	Test.stopTest();
        }
    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          03.08.2018
    * @description   Test method for insertParts
    * @revision(s)
    */
    static testmethod void testInsertParts4() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(u) {
        	setupTestData();

        	insert woli;

			TS_CloseTaskWOLIController.woliPartsWrapper wrapper = new TS_CloseTaskWOLIController.woliPartsWrapper();
			wrapper.partType = 'ServiceMaterial';
			wrapper.productId = prod.Id;
			wrapper.directCus = true;
			wrapper.isExisting = false;
			wrapper.recordId = woli.Id;
			wrapper.quantity = 0;
			wrapper.warranty = 'K1';
			List<Object> addList = new List<Object>();
			addList.add(wrapper);
	        String sbody = JSON.serialize(addList);

        	Test.startTest();
        		System.assert(TS_CloseTaskWOLIController.insertParts(sbody, woli.Id, c.Id, wo.id, false, woli, false, false) != null);
        	Test.stopTest();
        }
    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          03.08.2018
    * @description   Test method for insertParts
    * @revision(s)
    */
    static testmethod void testInsertParts5() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(u) {
        	setupTestData();

        	insert woli;

			TS_CloseTaskWOLIController.woliPartsWrapper wrapper = new TS_CloseTaskWOLIController.woliPartsWrapper();
			wrapper.partType = 'MissingPart';
			wrapper.productId = prod.Id;
			wrapper.directCus = true;
			wrapper.isExisting = true;
			wrapper.recordId = woli.Id;
			wrapper.quantity = 0;
			wrapper.warranty = 'K1';
			List<Object> addList = new List<Object>();
			addList.add(wrapper);
	        String sbody = JSON.serialize(addList);

        	Test.startTest();
        		System.assert(TS_CloseTaskWOLIController.insertParts(sbody, woli.Id, c.Id, wo.id, false, woli, false, false) != null);
        	Test.stopTest();
        }
    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          03.08.2018
    * @description   Test method for insertParts
    * @revision(s)
    */
    static testmethod void testInsertParts6() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(u) {
        	setupTestData();

        	insert woli;

			TS_CloseTaskWOLIController.woliPartsWrapper wrapper = new TS_CloseTaskWOLIController.woliPartsWrapper();
			wrapper.partType = 'ServiceMaterial';
			wrapper.productId = prod.Id;
			wrapper.directCus = true;
			wrapper.isExisting = true;
			wrapper.recordId = woli.Id;
			wrapper.quantity = 0;
			wrapper.warranty = 'K1';
			List<Object> addList = new List<Object>();
			addList.add(wrapper);
	        String sbody = JSON.serialize(addList);

        	Test.startTest();
        		System.assert(TS_CloseTaskWOLIController.insertParts(sbody, woli.Id, c.Id, wo.id, false, woli, false, false) != null);
        	Test.stopTest();
        }
    }



    /**
    * @author        Paul Jarred Aguiling
    * @date          03.08.2018
    * @description   Test method for getDifference
    * @revision(s)
    */
    static testmethod void testGetDifference() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(u) {
        	Datetime fromDateTimeval = DateTime.Now().AddDays(-1);  
        	Datetime toDateTimeval = DateTime.Now().AddDays(1);

        	Test.startTest();
        		System.assert(TS_CloseTaskWOLIController.getDifference(fromDateTimeval, toDateTimeval) != null);
        	Test.stopTest();
        }
    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          03.08.2018
    * @description   Test method for insertDummyServiceMaterial
    * @revision(s)
    */
    static testmethod void testInsertDummyServiceMaterial() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(u) {
       		setupTestData();

        	insert woli;

            Test.startTest();
                System.assert(TS_CloseTaskWOLIController.insertDummyServiceMaterial(wo.Id, c.Id, woli.Id, false) == 'SUCCESS');
            Test.stopTest();
        }
    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          03.08.2018
    * @description   Test method for getRecordWOLI
    * @revision(s)
    */
    static testmethod void testGetRecordWOLI() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(u) {
       		setupTestData();

        	insert woli;

            Test.startTest();
                System.assert(TS_CloseTaskWOLIController.getRecordWOLI(woli.Id) != null);
            Test.stopTest();
        }
    }

    /**
    * @author        Francis Alindogan
    * @date          01.21.2020
    * @description   Test method for getWTSInterval
    * @revision(s)
    */
    static testmethod void testGetWTSInterval() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(u) {
       		setupTestData();
            woli.PhysicalAsset__c = pa.Id;
        	insert woli;
            pa.WTSInterval__c = 5;
            update pa;

            Test.startTest();
                System.assert(TS_CloseTaskWOLIController.getWTSInterval(woli.Id) != null);
            Test.stopTest();
        }
    }


}