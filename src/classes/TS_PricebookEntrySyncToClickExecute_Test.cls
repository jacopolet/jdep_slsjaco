/*
* @author        Marvin Gatchalian
* @date          9.mar.2018          
* @description   Test class for TS_PricebookEntry_SyncToClick_Execute
* @revision(s)
*/


@isTest
public with sharing class TS_PricebookEntrySyncToClickExecute_Test {

	public static void dataSetup() {
		//Create Product
		product2 p = new product2();
		p.Name = 'KTS-1028';
		p.APTS_Material_Type__c = 'ZSPR';
		insert p;
		
		//Create sales org pricebook
		pricebook2 orgPB = new pricebook2();
		orgPB.name = 'BE Price Book';
		orgPB.IsActive = true;
		orgPB.Sales_Organization__c = 'SAP_0333';
		insert orgPB;
		
		//Create Pricebookentry with standard and sales org pricebook
		pricebookentry pbe = new pricebookentry();
		pbe.product2id = p.id;
		pbe.pricebook2id = Test.getStandardPricebookId();
		pbe.UnitPrice = 1;
		pbe.IsActive = true;
		//pbe.TS_Load_Id__c = String.valueOf(p.id) + String.valueOf(Test.getStandardPricebookId());
		insert pbe;
		
		pbe = new pricebookentry();
		pbe.product2id = p.id;
		pbe.pricebook2id = orgPB.id;
		pbe.UnitPrice = 11;
		pbe.IsActive = true;
		pbe.TS_Load_Id__c = String.valueOf(p.id) + String.valueOf(orgPB.id);
		insert pbe;
		
		
		
    }

    private static testMethod void TS_PricebookEntry_SyncToClick_Execute() {
		dataSetup();
		
		Test.startTest();
			TS_PricebookEntry_SyncToClick_Execute tsExecute = new TS_PricebookEntry_SyncToClick_Execute();
			DescribeSObjectResult priceBookEntries = pricebookentry.getSObjectType().getDescribe();
        	List <String> fields = new List<String>(priceBookEntries.fields.getMap().keySet());
        	List <pricebookentry> pbeRecords  = new List <pricebookentry>();
            pbeRecords = Database.query('SELECT ' + String.join(fields,',') + 
               							' FROM ' + priceBookEntries.getName() + 
        	   							' WHERE TS_Click_Synchronized__c = false AND TS_Load_Id__c != null');
        	   
			Map <pricebookentry, Integration_Log__c> priceBookEntryIntegrationLogMap = new 
        	Map <pricebookentry, Integration_Log__c>();
        	
			priceBookEntryIntegrationLogMap = tsExecute.createIntegrationLogPerPriceBookEntry (pbeRecords);
			
			system.assertequals(priceBookEntryIntegrationLogMap.keySet().size(), 1);
			system.assertequals(priceBookEntryIntegrationLogMap.values().size(), 1);
			
			
		Test.stopTest();
	    	
    }
}