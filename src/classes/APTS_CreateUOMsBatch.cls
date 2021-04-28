/*
 * This Batch class is used to create Permutation of UOM records based on existing UOM records.
 * Created By - Karan Khatri
 * Created Date - 14th Feb, 2019
 * 
 * v100 - Karan - initial class logic
*/
global without sharing class APTS_CreateUOMsBatch implements Database.Batchable<sObject>,Database.Stateful {

	public static final String FrequencyUOMObjectAPI = 'Apttus_Config2__FrequencyConversionRate__c';
	//String query = 'select id,Apttus_Config2__FromUom__c,Apttus_Config2__ToUom__c,Apttus_Config2__ConversionFactor__c from Apttus_Config2__FrequencyConversionRate__c where Apttus_Config2__ProductId__c!=null';
	//start nethod
	global Database.QueryLocator start(Database.BatchableContext BC) {
		//Dynamic query for existing Frequency UOM records.
		String query = APTS_CreateUOMsBatchHandler.getObjectQuery(FrequencyUOMObjectAPI) +APTS_CreateUOMsBatchHandler.EMPTY_STRING +label.APTS_UOMBatchWhereClause;
		return Database.getQueryLocator(query);
	}

	//execute Method
   	global void execute(Database.BatchableContext BC, List<sObject> scope) {
   		Map<Id,Set<String>> productIdToUomMap = new Map<Id,Set<String>>();
   		Map<String,Apttus_Config2__FrequencyConversionRate__c> productUOMFactorMap = new Map<String,Apttus_Config2__FrequencyConversionRate__c>();
   		Map<String,Apttus_Config2__FrequencyConversionRate__c> existingUOMsMap = new Map<String,Apttus_Config2__FrequencyConversionRate__c>();
   		Set<ID> productIDs = new Set<ID>();
   		Map<String,Apttus_Config2__FrequencyConversionRate__c> freqUOMsInsertMap = new Map<String,Apttus_Config2__FrequencyConversionRate__c>();
   		System.debug('scope=================>'+scope);
   		//Populate all prerequisieMap - 1) Map to capture existing UOM conversion factors 2) Map to capture "to UOMs" vs each product id
		//APTS_CreateUOMsBatchHandler.populateUOMBatchMaps(productUOMFactorMap,productIdToUomMap,scope);
		for(Apttus_Config2__FrequencyConversionRate__c freqUOM : (List<Apttus_Config2__FrequencyConversionRate__c>) scope){
			productIDs.add(freqUOM.Apttus_Config2__ProductId__c);
		}
		System.debug('productIDs=================>'+productIDs);
		if(!productIDs.isEmpty()){
			APTS_CreateUOMsBatchHandler.populateUOMBatchMaps(productUOMFactorMap,productIdToUomMap,existingUOMsMap,productIDs);
		}
		System.debug('productIdToUomMap============>'+productUOMFactorMap);
		System.debug('productIdToUomMap============>'+productIdToUomMap);
		System.debug('existingUOMsMap============>'+existingUOMsMap);
		//Brain logic to create Permutational UOM records based on existing data in the system
		APTS_CreateUOMsBatchHandler.createPermutationalUOMs(productUOMFactorMap,productIdToUomMap,existingUOMsMap,freqUOMsInsertMap);
		System.debug('freqUOMsInsertMap============>'+freqUOMsInsertMap);
		if(!freqUOMsInsertMap.isEmpty()){
			Database.upsert(freqUOMsInsertMap.values(),Apttus_Config2__FrequencyConversionRate__c.fields.APTS_UOM_External_ID__c,false);
		}
	}
	
	//Finish method 
	global void finish(Database.BatchableContext BC) {
		
	}
	
}