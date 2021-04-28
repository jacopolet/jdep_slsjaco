/*************************************************************
@Name: APTS_RSOPCRoutesalesBatch
@Author: Raul Orozco
@CreateDate: 04-12-2018
@Description: Batch executed in RSO Product Catalog batch finish. 
@UsedBy: APTS_RSOProductCatalogBatch
******************************************************************/
global class APTS_RSOPCRoutesalesBatch implements Database.Batchable<sObject> {
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(
			[
				SELECT APTS_Category_Text__c,
				APTS_Category_Value__c,
				APTS_Consignment__c,
				APTS_Price_List_Item__c,
				APTS_Product_Code__c,
				APTS_Product__c,
				APTS_Region__c,
				APTS_RSO_External_Id__c,
				APTS_Sales_Org_Data__c,
				APTS_Selling_UOM__c,
				APTS_Sub_Category_Text__c,
				APTS_Sub_Category_Value__c,
				APTS_Sub_Sub_Category_Text__c,
				APTS_Sub_Sub_Category_Value__c,
				APTS_Type__c 
				FROM APTS_RSO_Product_Catalog__c 
				WHERE APTS_RSO_External_Id__c LIKE '%Operating'
			]
		);
	}

   	global void execute(Database.BatchableContext BC, List<APTS_RSO_Product_Catalog__c> scope) {
		   APTS_RSOProductCatalogBatchHelper.createRoutesalesRecords(scope);
	}
	
	global void finish(Database.BatchableContext BC) {
		
	}
		
}