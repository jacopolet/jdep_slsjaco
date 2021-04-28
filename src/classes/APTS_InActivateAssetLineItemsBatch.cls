global class APTS_InActivateAssetLineItemsBatch implements Database.Batchable<sObject> {
    
    String agreementQuery;
    boolean deleteInActivateALI;
    Set<string> setTriggers;  
    
    global APTS_InActivateAssetLineItemsBatch(){ 
        
        //Get the query from custom metadata
        List<APTS_Batch_Queries__mdt> lstMetadata = new APTS_BatchMetadataCoverage().getMetadataCoverageRecords(
            'SELECT APTS_Batch_Name__c,'+
            'APTS_Query_String__c,'+
            'DeveloperName,'+
            'APTS_Control__c,'+
            'APTS_Triggers__c '+
            'FROM APTS_Batch_Queries__mdt '+ 
            'WHERE DeveloperName = \'Order_Line_Items\''
        );
        
        if(lstMetadata.size()>0){
            List<String> splitString = lstMetadata[0].APTS_Triggers__c.split(',');
            setTriggers = new Set<String>(splitString);
            agreementQuery = lstMetadata[0].APTS_Query_String__c; 
            deleteInActivateALI =  lstMetadata[0].APTS_Control__c; 
        }
        
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        //Inactivate triggers
        APTS_BillingSchedulesLoadBatchHelper.modifyTriggers(setTriggers,'Deactivate');

        return Database.getQueryLocator(agreementQuery);
    }

    global void execute(Database.BatchableContext BC, List<Apttus_Config2__OrderLineItem__c> lstOrderLineItem) {
        APTS_ScriptBatchHelper.InActivateAssetLineItems(lstOrderLineItem,deleteInActivateALI);
    }
    
    global void finish(Database.BatchableContext BC) {
        //Activate triggers
        APTS_BillingSchedulesLoadBatchHelper.modifyTriggers(setTriggers,'Activate');
    }
    
}