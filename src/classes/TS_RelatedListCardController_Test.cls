/*

* @author        Marvin Gatchalian
* @date          9.mar.2018          
* @description   Test class for TS_PriceBookEntrySyncToClick this method has been called from Trigger
* @revision(s)
*/

@isTest
public with sharing class TS_RelatedListCardController_Test {
	static Case testCase;
	static WorkOrderLineItem  woli;
	static WorkOrderLineItem  woliChild;
	static Resource__c  testResource;
    /*
	*@author	Ritesh Kumar
	*@date		15.08.2018
	*@description	update the test class to increace the code coverage.
	*/
	public static void dataSetup(String status, String recordTypeName) {
        
        testCase = new Case();
        woli = new WorkOrderLineItem();
        woliChild = new WorkOrderLineItem();
        
		Id taskId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
		Id woRecTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('TS Work Order').getRecordTypeId();
		
		//Create Resource
		testResource = TS_TestDataFactory.createResourceSingle('TestRSONumber');
		testResource.EmailAddress__c = 'testRSO@JDECoffee.com';
		testResource.EmployeeLastName__c = 'Skywalker';
		testResource.EmployeeFirstName__c = 'Anakin';
		testResource.CompanyCode__c = '6864';
		testResource.TeamNumber__c = '619';
		testResource.RequiresClickUser__c = true;
		testResource.UserProfile__c = 'Admin';
		testResource.ActiveUser__c = true;
		testResource.EmployeeStatus__c = '3';
        testResource.Username__c = 'testusername@test1.com';
        testResource.NickName__c = 'testnickname@test1.com';
		insert testResource;

		//Create Case
		testCase = TS_TestDataFactory.createCase ('Test Class');
		
		//Create Wo
		Workorder wo = TS_TestDataFactory.createWorkOrder();
		wo.RecordTypeId = woRecTypeId;
		wo.Status = 'Open';
		wo.CaseId = testCase.id;
		insert wo;
		
		//Create WOLi
		WorkOrderLineItem  woli = TS_TestDataFactory.createWorkOrderLineItem(wo.id);
		woli.RecordTypeId = taskId;
		woli.Case__c = testCase.id;
		woli.WorkOrderLineItemType__c = 'Task';
		woli.Status = status;
		woli.ExecutingEngineer__c = testResource.Id;
		insert woli;
		
		//Create child woli
		woliChild = TS_TestDataFactory.createWorkOrderLineItem(wo.id);
		woliChild.RecordTypeId = taskId;
		woliChild.Case__c = testCase.id;
		woliChild.WorkOrderLineItemType__c = 'Task';
		woliChild.Status = 'Open';
		woliChild.ParentWorkOrderLineItemId = woli.id;
		insert woliChild;
		
    }

    private static testMethod void TS_RelatedListCardControllerReturnRecs() {
		dataSetup('Open','Register Task');//update by Ritesh Kumar
		Test.startTest();
			List<WorkOrderLineItem> wolis = TS_RelatedListCardController.returnRecs(String.valueOf(testCase.id), 'Open', 'Task', true, false, false, false,false);
			system.assertequals(wolis.size(), 2);
		Test.stopTest();
	    	
    }
    
    private static testMethod void TS_RelatedListCardControllerReturnRecs1() {
		dataSetup('Dispatched','Register Task');
		Test.startTest();
			List<WorkOrderLineItem> wolis1 = TS_RelatedListCardController.returnRecs(String.valueOf(testCase.id), 'Dispatched', 'Task', true, false, false, false,false);
			system.assertequals(wolis1.size(), 1);
		Test.stopTest();
	    	
    }
    
    
    private static testMethod void TS_RelatedListCardControllerGetParts() {
		dataSetup('Open','Register Task');
		
		Test.startTest();
			List<WorkOrderLineItem> wolis 
			= 	TS_RelatedListCardController.getParts(String.valueOf(testCase.id), 'Task', false, null);
			system.assertequals(wolis.size(), 2);
			
			WorkOrderLineItem woliQueried = [select id from WorkOrderLineItem where ParentWorkOrderLineItemId = null];
			
			List<WorkOrderLineItem> wolis1 
			= 	TS_RelatedListCardController.getParts(String.valueOf(testCase.id), 'Task', true, String.valueOf(woliQueried.id));
			system.assertequals(wolis1.size(), 1);
				
		Test.stopTest();
	    	
    }
    
    /*
	*@author	Ritesh Kumar
	*@date		15.08.2018
	*@description	update the test class to increace the code coverage.
	*/    
    private static testMethod void TS_RelatedListCardControllerReturnRecs_A() {
		dataSetup('Open','Routesales Task');
		
		Test.startTest();
			List<WorkOrderLineItem> wolis = TS_RelatedListCardController.returnRecs(String.valueOf(testCase.id), 'Open', 'Task', false, true, false, false,false);
			system.assertequals(wolis.size(), 2);
		Test.stopTest();
	    	
    }
    
    private static testMethod void TS_RelatedListCardControllerReturnRecs_B() {
		dataSetup('Open','Counter Reading Task');
		
		Test.startTest();
			List<WorkOrderLineItem> wolis = TS_RelatedListCardController.returnRecs(String.valueOf(testCase.id), 'Open', 'Task', false, false, true, false,true);
			system.assertequals(0, wolis.size());
		Test.stopTest();
	    	
    }
    
    private static testMethod void TS_RelatedListCardControllerReturnRecs_C() {
		dataSetup('Open','Operating Task');
		
		Test.startTest();
			List<WorkOrderLineItem> wolis = TS_RelatedListCardController.returnRecs(String.valueOf(testCase.id), 'Open', 'Task', false, false, false, true,false);
			system.assertequals(0, wolis.size());
		Test.stopTest();
	    	
    }
    
     private static testMethod void TS_RelatedListCardControllerReturnRecs1_A() {
		dataSetup('Scheduled','Register Task');
		Test.startTest();
			List<WorkOrderLineItem> wolis1 = TS_RelatedListCardController.returnRecs(String.valueOf(testCase.id), 'Scheduled', 'Task', true, false, false, false,true);
			system.assertequals(wolis1.size(), 1);
		Test.stopTest();
	    	
    }
    
    private static testMethod void TS_RelatedListCardControllerReturnRecs1_B() {
		dataSetup('Scheduled','Operating Task');
		Test.startTest();
			List<WorkOrderLineItem> wolis1 = TS_RelatedListCardController.returnRecs(String.valueOf(testCase.id), 'Scheduled', 'Task', false, false, false, true,false);
			system.assertequals(0, wolis1.size());
		Test.stopTest();
	    	
    }
    
    private static testMethod void TS_RelatedListCardControllerReturnRecs1_C() {
		dataSetup('Scheduled','Operating Task');
        Test.startTest();
        	List<WorkOrderLineItem> wolis1 = TS_RelatedListCardController.returnRecs(String.valueOf(testCase.id), 'Scheduled', 'Task', false, false, false, false,true);
        	system.assertequals(0, wolis1.size());
        Test.stopTest();
	    	
    }
    
    private static testMethod void TS_RelatedListCardControllerReturnRecs_D() {
		dataSetup('Open','Operating Task');
		
		Test.startTest();
			List<WorkOrderLineItem> wolis = TS_RelatedListCardController.returnRecs(String.valueOf(testCase.id), 'Open', 'Task', false, false, false, false,true);
            system.assertequals(0, wolis.size());
		Test.stopTest();
	    	
    }
    
    private static testMethod void TS_RelatedListCardControllerReturnRecs2() {
		dataSetup('Dispatched','Operating Task');
		Test.startTest();
			List<WorkOrderLineItem> wolis1 = TS_RelatedListCardController.returnRecs(String.valueOf(testCase.id), 'Dispatched', 'Task', false, false, false, true,false);
			system.assertequals(0, wolis1.size());
        Test.stopTest();
	    	
    }
    
    private static testMethod void TS_RelatedListCardControllerReturnRecs3() {
		dataSetup('Dispatched','Operating Task');
		Test.startTest();
			List<WorkOrderLineItem> wolis1 = TS_RelatedListCardController.returnRecs(String.valueOf(testCase.id), 'Dispatched', 'Task', false, false, false, false,true);
			system.assertequals(0, wolis1.size());
		Test.stopTest();
	    	
    }
    
}