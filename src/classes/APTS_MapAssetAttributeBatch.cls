global class APTS_MapAssetAttributeBatch implements Database.Batchable<sObject> {
    
    String agreementQuery;
    Set<string> setTriggers; 
    String assetAttributeValueFields;
    String assetAdjLineItemFields;
    
    global APTS_MapAssetAttributeBatch(){
        
        //Get fields from object AssetAttributeValue
        String SobjectApiName = 'Apttus_Config2__AssetAttributeValue__c';
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Map<String, Schema.SObjectField> fieldMap = schemaMap.get(SobjectApiName).getDescribe().fields.getMap();
 
        assetAttributeValueFields = '';
        for(String fieldName : fieldMap.keyset()){
            if(assetAttributeValueFields == null || assetAttributeValueFields == ''){
                assetAttributeValueFields = fieldName;
            }else{
                assetAttributeValueFields = assetAttributeValueFields + ', ' + fieldName;
            }
        }  
                
        
        //Get fields from object Asset Adjustment Line Item
        String SobjectApiName1 = 'Apttus_Config2_AssetAdjustItem__c';
        Map<String, Schema.SObjectType> schemaMap1 = Schema.getGlobalDescribe();
        Map<String, Schema.SObjectField> fieldMap1 = schemaMap1.get(SobjectApiName1).getDescribe().fields.getMap();
 
        assetAdjLineItemFields = '';
        for(String fieldName : fieldMap1.keyset()){
            if(assetAdjLineItemFields == null || assetAdjLineItemFields == ''){
                assetAdjLineItemFields = fieldName;
            }else{
                assetAdjLineItemFields = assetAdjLineItemFields + ', ' + fieldName;
            }
        }
        
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
        }
        
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        //Inactivate triggers
        APTS_BillingSchedulesLoadBatchHelper.modifyTriggers(setTriggers,'Deactivate');

        return Database.getQueryLocator(agreementQuery);
    }

    global void execute(Database.BatchableContext BC, List<Apttus_Config2__OrderLineItem__c> lstOrderLineItem) {
        APTS_ScriptBatchHelper.processOrderLineItems(lstOrderLineItem,assetAttributeValueFields,assetAdjLineItemFields);
    }
    
    global void finish(Database.BatchableContext BC) {
        //Activate triggers
        APTS_BillingSchedulesLoadBatchHelper.modifyTriggers(setTriggers,'Activate');
    }
    
}