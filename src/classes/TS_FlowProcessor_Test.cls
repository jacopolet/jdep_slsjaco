/**
* @author        Marvin Gatchalian
* @date          27.April.2018
* @description   Test class for TS_FlowProcessor.
* @revision(s)
*/

@isTest
public with sharing class TS_FlowProcessor_Test {
	
	static Account acct;
    static Contact con;
    static Case c;
    static WorkOrder wo;
    static WorkOrderLineItem woli, woli1, woli2;
    static PhysicalAsset__c pa;
    
     
     public static void dataSetup() {
    	List <Disaster_Recovery__c> drToInsert = new List <Disaster_Recovery__c> ();
		id rtpa = TS_UtilityClass.getRecordTypeIdByName('PhysicalAsset__c', 'Machine');
		Id csRtID = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', 'Fixed Costs');
		
		Account acct = new Account ();
    	Contact con = new Contact();
      	
      	
	 	product2 prod = new product2();
		prod.Name = 'Operating Sched Product Test';
		prod.APTS_Material_Type__c = 'ZSPR';
		insert prod;
		
		//Create sales org pricebook
		pricebook2 orgPB = new pricebook2();
		orgPB.name = 'BE Price Book';
		orgPB.IsActive = true;
		orgPB.Sales_Organization__c = 'SAP_0333';
		insert orgPB;
		
		//Create Pricebookentry with standard and sales org pricebook
		pricebookentry pbe = new pricebookentry();
		pbe.product2id = prod.id;
		pbe.pricebook2id = Test.getStandardPricebookId();
		pbe.UnitPrice = 1;
		pbe.IsActive = true;
		//pbe.TS_Load_Id__c = String.valueOf(p.id) + String.valueOf(Test.getStandardPricebookId());
		insert pbe;
		
		pbe = new pricebookentry();
		pbe.product2id = prod.id;
		pbe.pricebook2id = orgPB.id;
		pbe.UnitPrice = 11;
		pbe.IsActive = true;
		insert pbe;
        
        PhysicalAsset__c pa = TS_TestDataFactory.createPhysicalAsset();
        pa.RecordTypeId = rtpa;
        pa.Machine_Care__c = 'Full Operating';
        pa.StartDate__c = date.today().addDays(-365);
        pa.EndDate__c = date.today().addDays(365);
        pa.TypeOfContract__c = 'Sales';
        pa.AssetStatus__c = 'Activated';
        pa.ActiveContract__c = true;
        pa.SalesOrganization__c = 'SAP_0333';
        pa.Product__c = prod.id;
        insert pa;
		
		acct = new Account(Name='Account', Phone='+31302979111');
		insert acct;
		
		con = TS_TestDataFactory.createContact();  
		con.Preferred_Language__c = 'SAP_EN';
		con.AccountId = acct.id;
		Insert con;
		
		c = TS_TestDataFactory.createFieldServiceCase();
        c.ContactId = con.Id;
        c.Status = Label.TS_Status_InProgress;
        c.SalesOrganization__c = 'SAP_0333';
        c.PhysicalAsset__c = pa.id;
        insert c;
        
        wo = TS_TestDataFactory.createWorkOrder();
        wo.CaseId = c.Id;
        wo.WorkOrderType__c = Label.TS_Case_SubType_CorrectMaint;
        wo.ContactId = con.Id;
        wo.Pricebook2Id = orgPB.Id;
        insert wo;
  
        List<WorkOrderLineItem> wolilist = new List<WorkOrderLineItem>();
        woli = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);         
        woli.Case__c = c.Id;
        woli.WorkOrderLineItemType__c = Label.TS_Type_Task;
        woli.StartDate__c = Datetime.now().addhours(-1);
        woli.EndDate__c = DateTime.now();
        woli.IsFirstTask__c = true;
        woli.CoffeeRunsUponArrival__c = true;
        woli.Status = 'Scheduled';
        woli.WorkOrderType__c = 'S10';
        woli.PricebookEntryId = pbe.id;
        wolilist.add(woli);
         
        woli1 = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);         
        woli1.Case__c = c.Id;
        woli1.WorkOrderLineItemType__c = Label.TS_Type_Task;
        woli1.StartDate__c = Datetime.now().addhours(-1);
        woli1.EndDate__c = DateTime.now();
        woli1.IsFirstTask__c = true;
        woli1.CoffeeRunsUponArrival__c = true;
        woli1.Status = 'Dispatched';
        woli1.WorkOrderType__c = 'S10';
        woli1.PricebookEntryId = pbe.id;
        wolilist.add(woli1);
        
        woli2 = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);         
        woli2.Case__c = c.Id;
        woli2.WorkOrderLineItemType__c = Label.TS_Type_Task;
        woli2.StartDate__c = Datetime.now().addhours(-1);
        woli2.EndDate__c = DateTime.now();
        woli2.IsFirstTask__c = true;
        woli2.CoffeeRunsUponArrival__c = true;
        woli2.Status = 'Received';
        woli2.WorkOrderType__c = 'S10';
        woli2.PricebookEntryId = pbe.id;
        wolilist.add(woli2);

        insert wolilist;
        
         CountrySetting__c countrySetting = new CountrySetting__c(Account__c = acct.Id, 
         	WorkOrderType__c = 'S10', 
            RecordTypeId = csRtID,
            Country__c = 'SAP_0333',  Active__c = true,
            Product__c = prod.id);

        insert countrySetting; 
        
    }
    
    private static testMethod void executeFixCostFlowTest() {
		dataSetup();
		
        Test.startTest();
        WorkOrderLineItemTriggerHandler woliTH = new WorkOrderLineItemTriggerHandler();
        Map<Id, WorkOrderLineItem> newMap = new Map<Id,WorkOrderLineItem>();        
        Set<Id> woliForFixCostSet = new Set<Id>();
		List<Id> woliForFixCost = new List <Id>();
		List<WorkOrderLineItem> wolilist = [SELECT Id FROM WorkOrderLineItem LIMIT 3];
        for (WorkOrderLineItem eachWoli :wolilist) {
            woliForFixCost.add(eachWoli.Id);  
            woliForFixCostSet.add(eachWoli.Id);
        }
        newMap = woliTH.getExtWoliMap(woliForFixCostSet);
		TS_FlowProcessor.hasException=true;
		TS_FlowProcessor.executeFixCostFlow (woliForFixCost, newMap);
		System.assert(woliForFixCost != null);
		Test.stopTest();
	    	
    }
    
}