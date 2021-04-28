global without sharing class TerritoryResult_PartialCreateBatch implements Database.Batchable<SObject>, Database.Stateful{
    
    global id modelId;
    global List<Territory__c> territories;
    global integer errors = 0;
    
    //query all accounts which belong to those territories
    public String accQuery = 'SELECT Id, Main_Country__c, Segment__c, Exclude_from_Territory_Assignment__c, Applied_Territory_Rule__c, '
                             + 'Account_Lifecycle__c, Main_Postal_Code__c, Territory__c, Main_Address_Validation_Timestamp__c, OwnerId, Territory__r.Territory_Model__c '
                             + 'FROM Account WHERE Territory__c IN :territories AND Approval_Required__c = false';
    
    global Database.QueryLocator start(Database.BatchableContext BC) {     
        //execute query
        return Database.getQueryLocator(accQuery);
    }
   
    global void execute(Database.BatchableContext BC, List<SObject> scope){
        List<Territory_Result__c> resultList = new List<Territory_Result__c>();
        List<Account> accList = scope;
        
        CustomLogging.push('execute', 'TerritoryResult_PartialCreateBatch');
        try{
            for(Account a : accList){
                Territory_Result__c result = new Territory_Result__c();
                result.Account__c = a.id;
                result.Assigned_Territory__c = a.Territory__c;
                result.Territory_Model__c = a.Territory__r.Territory_Model__c; 
                result.Excl_on_Account__c = a.Exclude_from_Territory_Assignment__c;
                result.Territory_Rule__c = a.Applied_Territory_Rule__c;
                resultList.add(result);
            }        
            
            if(!resultList.isEmpty()){
                insert resultList;    
            }           
            
        }catch(Exception ex){           
            errors = errors + 1;
            CustomLogging.debugException(ex);
            CustomLogging.pop();       
        }

	}
    
     global void finish(Database.BatchableContext BC) {
        
        Territory_Model__c model = [SELECT id, name, Definition_Status__c, RecordTypeId, Country__c, Description__c FROM Territory_Model__c WHERE Id = :modelId];
        
        //get value from custom settings
        Map<String, AccountTerritoryAssignmentValues__c> cons = null;
        cons = AccountTerritoryAssignmentValues__c.getAll();
        AccountTerritoryAssignmentValues__c consVal;
            
        AsyncApexJob a = [SELECT Id, CreatedById FROM AsyncApexJob where Id =:BC.getJobId()];

         //update Definition Status and Generate Batch Id of Model
         model.RecordTypeId = Schema.SObjectType.Territory_Model__c.getRecordTypeInfosByName().get(SM_Constants.modelRecTypeGenerated).getRecordTypeId(); //@Updated - Alvin Lomod - added recordtype on result generated
         model.Definition_Status__c = SM_Constants.modelStatusGenerated;
         update model;
         
         
         if(!Test.isRunningTest()){
             ConnectApi.FeedItem post = (ConnectApi.FeedItem) ConnectApiHelper.postFeedItemWithMentions(Network.getNetworkId(), model.Id,  '{' + a.CreatedById + '}' + ' the Territory Model has finished creating results!');
         }
     }
}