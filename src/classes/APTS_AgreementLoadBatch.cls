/*************************************************************
@Name: APTS_AgreementLoadBatch
@Author: Raul Orozco
@CreateDate: 03-27-2018
@Description: Batch class created for migration purposes.
@UsedBy: APTS_AgreementLoadSch
******************************************************************/
global class APTS_AgreementLoadBatch implements Database.Batchable<sObject> {
    
    String agreementQuery;
    Boolean bAPI;
    Integer repriceTimes;
    Set<String> setTriggers;

    global APTS_AgreementLoadBatch() {
    try
    {
        //Get the query from custom metadata
        List<APTS_Batch_Queries__mdt> lstMetadata = new APTS_BatchMetadataCoverage().getMetadataCoverageRecords(
            'SELECT APTS_Batch_Name__c,'+
            'APTS_Query_String__c,'+
            'DeveloperName,'+
            'APTS_API__c,'+
            'APTS_Triggers__c,'+
            'APTS_Times_Reprice__c '+
            'FROM APTS_Batch_Queries__mdt '+ 
            'WHERE DeveloperName = \'Query1\''
        );

        //Set variables
        agreementQuery = lstMetadata[0].APTS_Query_String__c;
        bAPI = lstMetadata[0].APTS_API__c;
        repriceTimes = lstMetadata[0].APTS_Times_Reprice__c.intValue();
        List<String> splitString = lstMetadata[0].APTS_Triggers__c.split(',');
        setTriggers = new Set<String>(splitString);
        }
        catch(Exception ex)
            {
            APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Batch', ex.getStackTraceString() ,'Agreement', null,'CLM',false,false, null, true);
            } 
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        // a) Inactivate triggers
        APTS_AgreementLoadBatchHelper.modifyTriggers(setTriggers,'Deactivate');
        
        return Database.getQueryLocator(agreementQuery);
    }

    global void execute(Database.BatchableContext BC, List<Apttus_Config2__ProductConfiguration__c> lstProductConfigurations) {
        APTS_AgreementLoadBatchHelper.repriceProductConfigurations(lstProductConfigurations, bAPI, repriceTimes);
    }
    
    global void finish(Database.BatchableContext BC) {
        //h)    Activate triggers
        APTS_AgreementLoadBatchHelper.modifyTriggers(setTriggers,'Activate');        
    }   
}