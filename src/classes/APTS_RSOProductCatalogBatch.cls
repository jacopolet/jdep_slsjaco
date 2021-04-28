/*************************************************************
@Name: APTS_RSOProductCatalogBatch
@Author: Raul Orozco
@CreateDate: 17-05-2018
@Description: RSO Product Catalog batch. 
@UsedBy: APTS_RSOProductCatalogSch
******************************************************************/
global class APTS_RSOProductCatalogBatch implements Database.Batchable<sObject> {
	
	String query;
	
	global APTS_RSOProductCatalogBatch(){
		//Get configuration to determine if the batch is running for initial load mode
		APTS_RSO_batch_settings__c mcs = APTS_RSO_batch_settings__c.getValues('General');
      	
      	Boolean initialLoad = (mcs != null && mcs.APTS_Initial_Load__c != null) ? mcs.APTS_Initial_Load__c : false;

      	if(initialLoad){
      		query = ' SELECT Id, ' +
				'Apttus_Config2__ProductId__c, ' + 
				'Apttus_Config2__PriceListId__c, ' + 
				'Apttus_Config2__ProductId__r.ProductCode, ' +
				'Apttus_Config2__PriceListId__r.APTS_Region__c, ' +
				'Apttus_Config2__PriceListId__r.APTS_PriceList_Type__c ' +
				'FROM Apttus_Config2__PriceListItem__c ' +
				'WHERE Apttus_Config2__PriceListId__r.APTS_PriceList_Type__c IN (\'Routesales\',\'Direct\') ' +
				'AND Apttus_Config2__Active__c = True  ';
  		}else{
  			query = ' SELECT Id, ' +
				'Apttus_Config2__ProductId__c, ' + 
				'Apttus_Config2__PriceListId__c, ' + 
				'Apttus_Config2__ProductId__r.ProductCode, ' +
				'Apttus_Config2__PriceListId__r.APTS_Region__c, ' +
				'Apttus_Config2__PriceListId__r.APTS_PriceList_Type__c ' +
				'FROM Apttus_Config2__PriceListItem__c ' +
				'WHERE Systemmodstamp >= LAST_N_DAYS:1 ' +
				'AND Apttus_Config2__PriceListId__r.APTS_PriceList_Type__c IN (\'Routesales\',\'Direct\') ' +
				'AND Apttus_Config2__Active__c = True ';
  		}
	}

	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<Apttus_Config2__PriceListItem__c> lstPLI) {
		APTS_RSOProductCatalogBatchHelper.createRSOProductCatalogRecords(lstPLI);
	}
	
	global void finish(Database.BatchableContext BC) {
		//Get configuration to determine if the batch Routesales should be executed
		APTS_RSO_batch_settings__c mcsFinish = APTS_RSO_batch_settings__c.getValues('General');
      	
      	Boolean executeBatch = (mcsFinish != null && mcsFinish.APTS_RSO_Routesales_Batch__c != null) ? mcsFinish.APTS_RSO_Routesales_Batch__c : false;

		if(executeBatch){
			APTS_RSOPCRoutesalesBatch obj = new APTS_RSOPCRoutesalesBatch();
    		Database.executeBatch(obj);
		}
	}
	
}