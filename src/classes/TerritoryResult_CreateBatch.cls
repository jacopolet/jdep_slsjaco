/**
* Class Name: TerritoryResult_CreateBatch 
* @author: James Azana
* Date: 13-Jun-2017
* Requirement: Batch process to create Territory Results
* @description: Create new Territory Results linked to the Territory Model where it is triggered
* @Revisions : 24.07.2017 - Create results even if the account didn't matched any Territory Rule.
*            : 03.08.2017 - Only accounts with valid address (determined by Main Address Validation Code) will be matched to a rule and valid to apply the changes to account
*/
 
global without sharing class TerritoryResult_CreateBatch implements Database.Batchable<SObject>, Database.Stateful{

    global id modelId;
    global String modelCountry;
    global String modelAccountType;
    global Map<String, List<Territory_Rule__c>> ruleMap;
    global integer errors = 0;
    
    
    //define query statement to retrieve account records
    public String accQuery = 'SELECT id, Segment__c, Exclude_from_Territory_Assignment__c, '
                             + 'Account_Lifecycle__c, Main_Postal_Code__c, Main_Address_Validation_Timestamp__c, OwnerId, Main_Country__c '
                             + 'FROM Account '
                             + 'WHERE Main_Country__c = :modelCountry AND Segment__c != null '
                             + 'AND Main_Address_Validation_Timestamp__c != null AND Exclude_from_Territory_Assignment__c = false AND Main_Postal_Code__c != null AND Approval_Required__c = false';
     
    global Database.QueryLocator start(Database.BatchableContext BC) {      
        return Database.getQueryLocator(accQuery);
    }
    
    global void execute(Database.BatchableContext BC, List<SObject> scope){
        List<Account> accList = scope;
        String regex = '[a-zA-Z]{1,}|\\-';
        String postalCode;
        Decimal postalCodeNumber;
        Boolean RuleMatch = false;
        List<Territory_Result__c> resultList = new List<Territory_Result__c>();
        
        try{
            for(Account acc : accList){
                postalCode = acc.Main_Postal_Code__c;
                postalCodeNumber = decimal.valueOf(postalCode.replaceAll(regex, '').replaceAll('[^0-9]', ''));        
                RuleMatch = false; //No rule was matched
                List<Territory_Rule__c> rule = new List<Territory_Rule__c>();
                //if account matches a rule, create a territory result record and it will be applied to the account if user clicks "Apply to Account"
                if(ruleMap.containsKey(acc.Segment__c)){
                    rule = ruleMap.get(acc.Segment__c);
                    for(Territory_Rule__c tr : rule){
                        if(tr.Territory_Model__r.Country__c == acc.Main_Country__c && (acc.Account_Lifecycle__c == null || tr.Account_Lifecycle__c == acc.Account_Lifecycle__c) &&
                          (postalCodeNumber == null || (decimal.valueof(tr.Postal_Code_From__c) <= postalCodeNumber && postalCodeNumber <= decimal.valueof(tr.Postal_Code_To__c)))){
                            Territory_Result__c result = new Territory_Result__c();
                                result.Account__c = acc.id;
                                result.Assigned_Territory__c = tr.Assigned_Territory__c;
                                result.Territory_Model__c = tr.Territory_Model__c;
                                result.Territory_Rule__c = tr.id;  
                                resultList.add(result);    
                        }
                    }
                }
            }         

            if(!resultList.isEmpty()){
                insert resultList;    
            }     

        } catch(Exception ex){     
            CustomLogging.push('execute', 'TerritoryResult_CreateBatch');      
            errors = errors + 1;
            CustomLogging.debugException(ex);
            CustomLogging.pop();       
        }
    }

    global void finish(Database.BatchableContext BC) {
        Territory_Model__c model = [SELECT id, name, Definition_Status__c, RecordTypeId, Country__c, Description__c FROM Territory_Model__c WHERE Id = :modelId];
        //update Definition Status and Generate Batch Id of Model
        model.RecordTypeId = Schema.SObjectType.Territory_Model__c.getRecordTypeInfosByName().get(SM_Constants.modelRecTypeGenerated).getRecordTypeId(); //@Updated - Alvin Lomod - added recordtype on result generated
        model.Definition_Status__c = SM_Constants.modelStatusGenerated;
        model.Last_Run__c = date.today();
        
        if(Schema.sObjectType.Territory_Model__c.fields.RecordTypeId.isUpdateable() &&
        Schema.sObjectType.Territory_Model__c.fields.Definition_Status__c.isUpdateable() &&
        Schema.sObjectType.Territory_Model__c.fields.Generate_Batch_Id__c.isUpdateable()){
            update model;
        }
        
        if(!Test.isRunningTest()){
            AsyncApexJob a = [SELECT Id, CreatedById FROM AsyncApexJob where Id =:BC.getJobId()];
            ConnectApi.FeedItem post = (ConnectApi.FeedItem) ConnectApiHelper.postFeedItemWithMentions(Network.getNetworkId(), model.Id,  '{' + a.CreatedById + '}' + ' the Territory Model has finished creating results!');
        }
    }
}