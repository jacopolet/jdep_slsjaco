/*************************************************************
@Name: APTS_LineItemsPricingSchedulerBatch
@Author: Raul Orozco
@CreateDate: 15-05-2018
@Description: Batch class to enqueue line items pricing batch.
@UsedBy: N/A
******************************************************************/
global class APTS_LineItemsPricingSchedulerBatch implements Database.Stateful,Database.Batchable<sObject> {
	
	String strQuery;
	global List<Set<Id>> lineItemsList;
	global Integer batchLimit;
	global Integer batchNumber;
	global Integer batchSize;

	global APTS_LineItemsPricingSchedulerBatch(Integer bNumber, Integer bLimit) {
		//Initialize variables
		lineItemsList = new List<Set<Id>>();
		batchNumber = bNumber;
		batchLimit = bLimit;

		//Get the query from custom metadata
        List<APTS_Batch_Queries__mdt> lstMetadata = new APTS_BatchMetadataCoverage().getMetadataCoverageRecords(
            'SELECT APTS_Query_String__c,'+
            'DeveloperName, '+
            'APTS_Times_Reprice__c '+
            'FROM APTS_Batch_Queries__mdt '+
            'WHERE DeveloperName = \'Batch_Scheduler\''
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
		List<Apttus_Config2__LineItem__c> lstLI = (List<Apttus_Config2__LineItem__c>)scope;
		for(Apttus_Config2__LineItem__c lineItem : lstLI){
			if(lineItemsList.size() == 0){
				Set<Id> lineItemsId = new Set<Id>();
				lineItemsList.add(lineItemsId);
			}

			Set<Id> currentLIIdSet = lineItemsList[lineItemsList.size() - 1];

			if(currentLIIdSet.size() == batchLimit){
				Set<Id> lineItemIdsNew = new Set<Id>();
				lineItemIdsNew.add(lineItem.Id);
				lineItemsList.add(lineItemIdsNew);
			}else{
				currentLIIdSet.add(lineItem.Id);
			}
		}
	}
	
	global void finish(Database.BatchableContext BC) {
		//Loop through the list of set<Id>, for each element of list
		//enqueue batch
		for(Integer i = 0; i < batchNumber; i++){
			if(lineItemsList.size() > 0){
				system.debug(Logginglevel.ERROR,'List size:::::::' + lineItemsList[i].size());
				APTS_LineItemsPricingBatch obj = new APTS_LineItemsPricingBatch(lineItemsList[i]);
				Database.executeBatch(obj,batchSize);
			}
		}
	}	
}