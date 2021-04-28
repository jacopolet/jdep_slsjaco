global class APTS_BillingSchedulesLoadBatch implements Database.Batchable<sObject> {
    
    String agreementQuery;
    Set<string> setTriggers;
    Boolean deleteALIFlag;
    String assetUsagePriceTierFields;
    
    global APTS_BillingSchedulesLoadBatch(){
        
        //Get fields from object AssetUsagePriceTier
        assetUsagePriceTierFields = '';
        Schema.describefieldresult dfield;
        Map <String, Schema.SObjectField> fieldMap = 
        Apttus_Config2__AssetUsagePriceTier__c.SObjectType.getDescribe().fields.getMap();

        for(Schema.SObjectField sfield : fieldMap.Values())
        {
            dfield = sfield.getDescribe();
            if(dfield.isUpdateable()){
                assetUsagePriceTierFields += dfield.getname() + ',';
            }
        }

        assetUsagePriceTierFields = assetUsagePriceTierFields.removeEnd(',');
 
        //Get the query from custom metadata
        List<APTS_Batch_Queries__mdt> lstMetadata = new APTS_BatchMetadataCoverage().getMetadataCoverageRecords(
            'SELECT APTS_Batch_Name__c,'+
            'APTS_Query_String__c,'+
            'DeveloperName,'+
            'APTS_Control__c,'+
            'APTS_Triggers__c '+
            'FROM APTS_Batch_Queries__mdt '+ 
            'WHERE DeveloperName = \'Billing_Schedules\''
        );

        List<String> splitString = lstMetadata[0].APTS_Triggers__c.split(',');
        setTriggers = new Set<String>(splitString);
        agreementQuery = lstMetadata[0].APTS_Query_String__c;
        deleteALIFlag = lstMetadata[0].APTS_Control__c;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        //Inactivate triggers
        APTS_BillingSchedulesLoadBatchHelper.modifyTriggers(setTriggers,'Deactivate');

        return Database.getQueryLocator(agreementQuery);
    }

    global void execute(Database.BatchableContext BC, List<Account> lstAccounts) {
        APTS_BillingSchedulesLoadBatchHelper.processAccounts(lstAccounts, deleteALIFlag, assetUsagePriceTierFields);
    }
    
    global void finish(Database.BatchableContext BC) {
        //Activate triggers
        APTS_BillingSchedulesLoadBatchHelper.modifyTriggers(setTriggers,'Activate');
    }
    
}