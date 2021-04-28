/*************************************************************
@Name: APTS_ProductConfigFinalizeSchedulerBatch
@Author: Raul Orozco
@CreateDate: 20-06-2018
@Description: Batch class to enqueue product config finalization batch.
@UsedBy: N/A
******************************************************************/
global class APTS_ProductConfigFinalizeSchedulerBatch implements Database.Stateful,Database.Batchable<sObject> {
	
	String strQuery;
	global List<Set<Id>> productConfigList;
	global Integer batchLimit;
	global Integer batchNumber;
	global Integer batchSize;

	global APTS_ProductConfigFinalizeSchedulerBatch(Integer bNumber, Integer bLimit) {
		//Initialize variables
		productConfigList = new List<Set<Id>>();
		batchNumber = bNumber;
		batchLimit = bLimit;

		//Get the query from custom metadata
        List<APTS_Batch_Queries__mdt> lstMetadata = new APTS_BatchMetadataCoverage().getMetadataCoverageRecords(
            'SELECT APTS_Query_String__c,'+
            'DeveloperName, '+
            'APTS_Times_Reprice__c '+
            'FROM APTS_Batch_Queries__mdt '+
            'WHERE DeveloperName = \'Product_Config_Batch_Scheduler\''
        );

        strQuery = lstMetadata[0].APTS_Query_String__c;
        batchSize = lstMetadata[0].APTS_Times_Reprice__c != null ? lstMetadata[0].APTS_Times_Reprice__c.intValue() : 8;
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(strQuery);
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope) {
		//Create the list of set<Id> that will be passed to the line item
		//pricing batch
		Integer batchCount = 1;
		List<Apttus_Config2__ProductConfiguration__c> lstLI = (List<Apttus_Config2__ProductConfiguration__c>)scope;
		for(Apttus_Config2__ProductConfiguration__c lineItem : lstLI){
			if(productConfigList.size() == 0){
				Set<Id> productConfigsId = new Set<Id>();
				productConfigList.add(productConfigsId);
			}

			Set<Id> currentProductConfigIdSet = productConfigList[productConfigList.size() - 1];

			if(currentProductConfigIdSet.size() == batchLimit){
				Set<Id> productConfigIdsNew = new Set<Id>();
				productConfigIdsNew.add(lineItem.Id);
				productConfigList.add(productConfigIdsNew);
			}else{
				currentProductConfigIdSet.add(lineItem.Id);
			}
		}
	}
	
	global void finish(Database.BatchableContext BC) {
		//Loop through the list of set<Id>, for each element of list
		//enqueue batch
		for(Integer i = 0; i < batchNumber; i++){
			if(productConfigList.size() > 0){
				system.debug(Logginglevel.ERROR,'List size:::::::' + productConfigList[i].size());
				APTS_ProductConfigFinalizationBatch obj = new APTS_ProductConfigFinalizationBatch(productConfigList[i]);
				Database.executeBatch(obj,batchSize);
			}
		}
	}	
}