public with sharing class APTS_InstalledAssetsController {

    @AuraEnabled(cacheable=true)
    public static List<Apttus_Config2__AssetLineItem__c> getAssetsRelatedToAccount(string recordId) {
        list<APTS_Batch_Queries__mdt> metadataQuery = [select id, APTS_Query_String__c,  DeveloperName from APTS_Batch_Queries__mdt where DeveloperName = 'Installed_Assets_Query'];
        List<Apttus_Config2__AssetLineItem__c> assetLineItems = new List<Apttus_Config2__AssetLineItem__c>();
        if(metadataQuery.size() > 0 &&  metadataQuery[0].APTS_Query_String__c != null){
            assetLineItems =  database.query(metadataQuery[0].APTS_Query_String__c);       
        }
        return assetLineItems;        
    }    

}