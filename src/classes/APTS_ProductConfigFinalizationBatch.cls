/*************************************************************
@Name: APTS_ProductConfigFinalizationBatch
@Author: Raul Orozco
@CreateDate: 09-05-2018
@Description: Batch class created for migration purposes.
@UsedBy: APTS_ProductConfigFinalizationBatch
******************************************************************/
global class APTS_ProductConfigFinalizationBatch implements Database.Batchable<sObject> {
	
	String strQuery;
    Boolean bAPI;
    Boolean bcreateCER;
    Set<String> setTriggers;
    global Set<Id> productConfigIdSet;

	global APTS_ProductConfigFinalizationBatch() {
        //Get the query from custom metadata
        List<APTS_Batch_Queries__mdt> lstMetadata = new APTS_BatchMetadataCoverage().getMetadataCoverageRecords(
            'SELECT APTS_Batch_Name__c,'+
            'APTS_Query_String__c, '+
            'DeveloperName, '+
            'APTS_API__c, '+
            'APTS_Triggers__c '+
            'FROM APTS_Batch_Queries__mdt '+
            'WHERE DeveloperName = \'ProductConfiguration_Finalization\''
        );

        //Set variables
        strQuery = lstMetadata[0].APTS_Query_String__c;
        bAPI = lstMetadata[0].APTS_API__c;
        List<String> splitString = lstMetadata[0].APTS_Triggers__c.split(',');
        setTriggers = new Set<String>(splitString);
    }

    //New constructor with line items id set as parameter, used for
    //batch scheduler class
    global APTS_ProductConfigFinalizationBatch(Set<Id> setProductConfigId) {
        productConfigIdSet = setProductConfigId;

        //Get the query from custom metadata
        List<APTS_Batch_Queries__mdt> lstMetadata = new APTS_BatchMetadataCoverage().getMetadataCoverageRecords(
            'SELECT APTS_Batch_Name__c,'+
            'APTS_Query_String__c,'+
            'DeveloperName,'+
            'APTS_API__c, '+
            'APTS_Triggers__c '+
            'FROM APTS_Batch_Queries__mdt '+
            'WHERE DeveloperName = \'Product_Config_Finalization_Scheduled\''
        );

        //Set variables
        strQuery = lstMetadata[0].APTS_Query_String__c;
        bAPI = lstMetadata[0].APTS_API__c;
        List<String> splitString = lstMetadata[0].APTS_Triggers__c.split(',');
        setTriggers = new Set<String>(splitString);
    }

	global Database.QueryLocator start(Database.BatchableContext BC) {
        // a) Inactivate triggers
        if(setTriggers.size() > 0){
            APTS_AgreementLoadBatchHelper.modifyTriggers(setTriggers,'Deactivate');
        }        
        
        return Database.getQueryLocator(strQuery);
	}

   	global void execute(Database.BatchableContext BC, List<Apttus_Config2__ProductConfiguration__c> lstProductConfigurations) {
		APTS_AgreementLoadBatchHelper.processProductConfigurations(lstProductConfigurations,bAPI);
	}
	
	global void finish(Database.BatchableContext BC) {
		//h)    Activate triggers
        if(setTriggers.size() > 0){
            APTS_AgreementLoadBatchHelper.modifyTriggers(setTriggers,'Activate');
        }           
	}
	
}