/*
* @author        Marvin Gatchalian
* @date          8.mar.2018          
* @description   Test class for TS_ProductSynchronization_Batch
* @revision(s)
*/


@isTest
public with sharing class TS_ProductSynchronization_Batch_Test {

	public static void dataSetup() {
        
        IntegrationUserAndProfile__c customSettings = new IntegrationUserAndProfile__c();
        customSettings.ClickPriceBookEntryScheduleDuration__c = 10800;
        customSettings.Click_Product_Batch_Limit__c = 50; 
        insert customSettings;
		//Create Product
		product2 p = new product2();
		p.Name = 'KTS-1028';
		p.APTS_Material_Type__c = 'ZSPR';
		insert p;
		
		//Create Price List
		Apttus_Config2__PriceList__c pl = new Apttus_Config2__PriceList__c();
		pl.APTS_SalesOrg__c = '0333';
		pl.Apttus_Config2__Active__c = true;
		pl.APTS_PriceList_Type__c = 'Direct';
		insert pl;				
		
		//Create Price List Item
		Apttus_Config2__PriceListItem__c pli = new Apttus_Config2__PriceListItem__c();
		pli.Apttus_Config2__ProductId__c = p.id;
		pli.Apttus_Config2__PriceListId__c = pl.id;
		pli.Apttus_Config2__ListPrice__c = 10;
		pli.Apttus_Config2__ChargeType__c = 'Sales Price';
		pli.APTS_ConditionType__c = 'Z000';
		insert pli;
		
		//Create sales org pricebook
		pricebook2 orgPB = new pricebook2();
		orgPB.name = 'BE Price Book';
		orgPB.IsActive = true;
		orgPB.Sales_Organization__c = 'SAP_0333';
		insert orgPB;
		
    }

    private static testMethod void TS_ProductSynchronization_Batch() {
		dataSetup();
		
		Test.startTest();
			TS_ProductSynchronization_Batch psBatch = new TS_ProductSynchronization_Batch();
			Database.executeBatch(psBatch);
		Test.stopTest();
		system.assertequals(2, [select id from pricebookentry where TS_Load_Id__c != null].size());
	    	
    }
}