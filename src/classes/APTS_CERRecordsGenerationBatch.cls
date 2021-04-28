global class APTS_CERRecordsGenerationBatch implements Database.Batchable<sObject> {
	
	String agreementQuery;
    Set<string> setTriggers;
	
	global APTS_CERRecordsGenerationBatch() {
		//Get the query from custom metadata
        List<APTS_Batch_Queries__mdt> lstMetadata = new APTS_BatchMetadataCoverage().getMetadataCoverageRecords(
            'SELECT APTS_Batch_Name__c,'+
            'APTS_Query_String__c,'+
            'DeveloperName,'+
            'APTS_Triggers__c '+ 
            'FROM APTS_Batch_Queries__mdt '+ 
            'WHERE DeveloperName = \'CER_Creation\''
        );

        List<String> splitString = lstMetadata[0].APTS_Triggers__c.split(',');
        setTriggers = new Set<String>(splitString);
        agreementQuery = lstMetadata[0].APTS_Query_String__c;
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		 //Inactivate triggers
        APTS_AgreementLoadBatchHelper.modifyTriggers(setTriggers,'Deactivate');

        return Database.getQueryLocator(agreementQuery);
	}

   	global void execute(Database.BatchableContext BC, List<Apttus__APTS_Agreement__c> lstAgreements) {
		APTS_AgreementLoadBatchHelper.createCERRecords(lstAgreements);
	}
	
	global void finish(Database.BatchableContext BC) {
		//Activate triggers
        APTS_AgreementLoadBatchHelper.modifyTriggers(setTriggers,'Activate');
	}
}