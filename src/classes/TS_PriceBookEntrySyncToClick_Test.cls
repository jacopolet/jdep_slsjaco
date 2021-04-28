/*
* @author        Marvin Gatchalian
* @date          9.mar.2018          
* @description   Test class for TS_PriceBookEntrySyncToClick this method has been called from Trigger
* @revision(s)
*/


@isTest
public with sharing class TS_PriceBookEntrySyncToClick_Test {

	public static void dataSetup() {
		//Create Product
		product2 p = new product2();
		p.Name = 'KTS-1028';
		p.APTS_Material_Type__c = 'ZSPR';
        p.IsActive = true;
		insert p;
		
		//Create sales org pricebook
		pricebook2 orgPB = new pricebook2();
		orgPB.name = 'BE Price Book';
		orgPB.IsActive = true;
		orgPB.Sales_Organization__c = 'SAP_0333';
		insert orgPB;
		
		//Create Pricebookentry with standard and sales org pricebook
		Pricebookentry pbe = new pricebookentry();
		pbe.product2id = p.id;
		pbe.pricebook2id = Test.getStandardPricebookId();
		pbe.UnitPrice = 1;
		pbe.IsActive = true;
		pbe.TS_Load_Id__c = String.valueOf(p.id) + String.valueOf(Test.getStandardPricebookId());
		insert pbe;
		
		Pricebookentry pbe2 = new pricebookentry();
		pbe2.product2id = p.id;
		pbe2.pricebook2id = orgPB.id;
		pbe2.UnitPrice = 11;
		pbe2.IsActive = true;
		pbe2.TS_Load_Id__c = String.valueOf(p.id) + String.valueOf(orgPB.id);
		insert pbe2;
        
        APTS_Sales_Org_Data__c aptsData = new APTS_Sales_Org_Data__c();
        aptsData.APTS_Sales_Org_Data_Name__c = '0333';
        aptsData.APTS_Product__c = p.id;   
		aptsData.APTS_Distribution_chain_specific_materia__c = 'SAP_01';
        insert aptsData;
            
    }

    private static testMethod void TS_PriceBookEntrySyncToClick() {
		dataSetup();
		
		Test.startTest();
			DescribeSObjectResult priceBookEntries = pricebookentry.getSObjectType().getDescribe();
	    	List <String> fields = new List<String>(priceBookEntries.fields.getMap().keySet());
	    	List <pricebookentry> pbeRecords  = new List <pricebookentry>();
	        pbeRecords = Database.query('SELECT ' + String.join(fields,',') + 
	           							' FROM ' + priceBookEntries.getName() + 
	    	   							' WHERE TS_Click_Synchronized__c = false AND TS_Load_Id__c != null');
	    	
	    	Map <pricebookentry, Integration_Log__c> priceBookEntryIntegrationLogMap = new 
	        Map <pricebookentry, Integration_Log__c>();
	    	   							
			for(PricebookEntry eachPriceBookEntry :pbeRecords) {
	            if (!eachPriceBookEntry.TS_Click_Synchronized__c) {
	            	
	            	Integration_Log__c integLog = new Integration_Log__c();
	            	
	                integLog.Object_Id__c = eachPriceBookEntry.Id;
	                integLog.Object__c = INT_Constants.CLICK_SYNCMASTERPRODUCT;
	                integLog.Integration_Status__c = INT_Constants.INITIAL;
	                integLog.Triggered_Timestamp__c = Datetime.now();
	                
	                eachPriceBookEntry.TS_Click_Synchronized__c = true;
	                
	                priceBookEntryIntegrationLogMap.put(eachPriceBookEntry, integLog);
	            }
			}
			if (!priceBookEntryIntegrationLogMap.values().isEmpty()) {
				insert priceBookEntryIntegrationLogMap.values();
				
				List<Integration_Log__c> updatedIlogList = [SELECT Id, Integration_Status__c, Work_Order_Line_Item__c, Object__c, Object_Id__c
	                                                    	 FROM Integration_Log__c WHERE Object__c =: INT_Constants.CLICK_SYNCMASTERPRODUCT];
	        	
	        	TS_PriceBookEntrySyncToClick.hasException=true;
                TS_PriceBookEntrySyncToClick sendToClick = new TS_PriceBookEntrySyncToClick();
	        	sendToClick.executeSendPartType(updatedIlogList);
			}
			if (!pbeRecords.isEmpty()) update pbeRecords;
				
			system.assertequals(pbeRecords[0].TS_Click_Synchronized__c, true);
		Test.stopTest();
	    	
    }
}