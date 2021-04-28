/**
* Class Name: TerritoryResult_DeleteBatch 
* @author: James Azana
* Date: 13-Jun-2017
* Requirement: Batch process to delete Territory Results
* @description: Deletes all Territory Results linked to the Territory Model where it is triggered
*
*/
 
global without sharing class TerritoryResult_DeleteBatch implements Database.Batchable<SObject>, Database.Stateful{
    
    global id modelId;
    global String modelCountry;
    global String modelAccountType;
    global Map<String, List<Territory_Rule__c>> ruleMap;
    global integer errors = 0;
    global Boolean isPartial;
    global List<Territory__c> territories;
    
    //define query statement to retrieve existing territory results to be deleted
    public String resultQuery =  'SELECT Id, Territory_Model__c, Territory_Model__r.Sales_Organization__c FROM Territory_Result__c WHERE Territory_Model__c = :modelId';
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        //execute query
        return Database.getQueryLocator(resultQuery);
    }
    
    global void execute(Database.BatchableContext BC, List<SObject> scope){
        CustomLogging.push('execute', 'TerritoryResult_DeleteBatch');
        //delete existing territory results associated with the territory model       
        try{
            delete scope;
        }
        catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();      
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());   
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        CustomLogging.push('finish', 'TerritoryResult_DeleteBatch');
        Territory_Model__c model = [SELECT Id, Delete_Batch_Id__c FROM Territory_Model__c WHERE Id = :modelId];
        
        AsyncApexJob a = [SELECT Id, Status, ExtendedStatus, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email 
                          FROM AsyncApexJob where Id =:BC.getJobId()];
        
        String[] toAddresses = new String[] {a.CreatedBy.Email};
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage(); 
        mail.setToAddresses(toAddresses);
        
        //get value from custom settings
        Map<String, AccountTerritoryAssignmentValues__c> cons = null;
        cons = AccountTerritoryAssignmentValues__c.getAll();
        AccountTerritoryAssignmentValues__c consVal;
        
        if(a.NumberOfErrors == 0){
            if (!isPartial) {
                //after all existing territory results are deleted, execute create batch
                TerritoryResult_CreateBatch new_bat = new TerritoryResult_CreateBatch();
                new_bat.modelId =  modelId;
                new_bat.modelCountry =  modelCountry;
                new_bat.modelAccountType =  modelAccountType;
                new_bat.ruleMap = ruleMap;
                
                consVal = cons.get('createBatchScope');
                database.executeBatch(new_bat, integer.valueOf(consVal.Value__c));
            } else {
                TerritoryResult_PartialCreateBatch newBat = new TerritoryResult_PartialCreateBatch();
                newBat.modelId =  modelId;
                newBat.territories = territories;
                
                consVal = cons.get('createBatchScope');
                database.executeBatch(newBat, integer.valueOf(consVal.Value__c));
            }
            
            
            //update Territory Model Delete Batch Id technical field
            model.Delete_Batch_Id__c = BC.getJobId();
                        
            try{
                if(Schema.sObjectType.Territory_Model__c.fields.Delete_Batch_Id__c.isUpdateable()){
                	update model;
            	}
            }
            catch(Exception ex){
                CustomLogging.debugException(ex);
                CustomLogging.pop();      
                System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());   
            }
        }
    }
 }