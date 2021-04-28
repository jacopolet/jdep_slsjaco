/*
* @author        Marvin Gatchalian
* @date          9.mar.2018          
* @description   Test class for TS_PricebookEntry_SyncToClick_Batch
* @revision(s)
*/


@isTest
public with sharing class TS_PricebookEntry_SyncToClick_Batch_Test {

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
		pbe.TS_Load_Id__c = String.valueOf(p.id) + String.valueOf(Test.getStandardPricebookId());
		insert pbe;
		
		pbe = new pricebookentry();
		pbe.product2id = p.id;
		pbe.pricebook2id = orgPB.id;
		pbe.UnitPrice = 11;
		pbe.IsActive = true;
		pbe.TS_Load_Id__c = String.valueOf(p.id) + String.valueOf(orgPB.id);
		insert pbe;
		
		
		
    }

    private static testMethod void TS_PricebookEntry_SyncToClick_Batch() {
		dataSetup();
		
		Test.startTest();
			TS_PricebookEntry_SyncToClick_Batch pbeSyncBatch = new TS_PricebookEntry_SyncToClick_Batch();
			Database.executeBatch(pbeSyncBatch);
		Test.stopTest();
		system.assertequals(1, [SELECT id from pricebookentry WHERE TS_Click_Synchronized__c = true
								AND TS_Load_Id__c != null AND Pricebook2.IsStandard = false].size());
	    	
    }
}