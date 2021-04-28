/*************************************************************
@Name: APTS_LineItemsPricingBatch
@Author: Raul Orozco
@CreateDate: 09-05-2018
@Description: Batch class created for migration purposes.
@UsedBy: 
******************************************************************/
global class APTS_LineItemsPricingBatch implements Database.Batchable<sObject> {
    
    String strQuery;
    Boolean bAPI;
    Integer repriceTimes;
    Set<String> setTriggers;
    global Set<Id> lineItemsIdSet;

    global APTS_LineItemsPricingBatch() {
        //Get the query from custom metadata
        List<APTS_Batch_Queries__mdt> lstMetadata = new APTS_BatchMetadataCoverage().getMetadataCoverageRecords(
            'SELECT APTS_Batch_Name__c,'+
            'APTS_Query_String__c,'+
            'DeveloperName,'+
            'APTS_Triggers__c '+
            'FROM APTS_Batch_Queries__mdt '+
            'WHERE DeveloperName = \'LineItems_Pricing\''
        );

        //Set variables
        strQuery = lstMetadata[0].APTS_Query_String__c;
        List<String> splitString = lstMetadata[0].APTS_Triggers__c.split(',');
        setTriggers = new Set<String>(splitString);
    }

    //New constructor with line items id set as parameter, used for
    //batch scheduler class
    global APTS_LineItemsPricingBatch(Set<Id> setLineItemId) {
        lineItemsIdSet = setLineItemId;

        //Get the query from custom metadata
        List<APTS_Batch_Queries__mdt> lstMetadata = new APTS_BatchMetadataCoverage().getMetadataCoverageRecords(
            'SELECT APTS_Batch_Name__c,'+
            'APTS_Query_String__c,'+
            'DeveloperName,'+
            'APTS_Triggers__c '+
            'FROM APTS_Batch_Queries__mdt '+
            'WHERE DeveloperName = \'LineItems_Pricing_Scheduler\''
        );

        //Set variables
        strQuery = lstMetadata[0].APTS_Query_String__c;
        List<String> splitString = lstMetadata[0].APTS_Triggers__c.split(',');
        setTriggers = new Set<String>(splitString);
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        // a) Inactivate triggers
        APTS_AgreementLoadBatchHelper.modifyTriggers(setTriggers,'Deactivate');
        
        return Database.getQueryLocator(strQuery);
    }

    global void execute(Database.BatchableContext BC, List<Apttus_Config2__LineItem__c> lstLineItems) {
        APTS_AgreementLoadBatchHelper.repriceLineItems(lstLineItems);
    }
    
    global void finish(Database.BatchableContext BC) {
        //h)    Activate triggers
        APTS_AgreementLoadBatchHelper.modifyTriggers(setTriggers,'Activate');        
    }   
}