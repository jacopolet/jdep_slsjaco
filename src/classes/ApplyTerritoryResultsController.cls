/**
* Class Name: ApplyTerritoryResultsController
* @author: James Azana
* Date: 16-Jun-2017
* Requirement: Batch process to update territory model on accounts
* @description: Updates territory model on the accounts
*
*/

public with sharing class ApplyTerritoryResultsController{
    
    public Territory_Model__c model;
    public boolean showButton{get;set;}
    public String messageValue{get;set;}
    public String buttonValue{get;set;}
      
    public ApplyTerritoryResultsController(ApexPages.StandardController controller) {

        this.model = (Territory_Model__c)controller.getRecord();
        //get territory model record that triggers the process
        if(Schema.sObjectType.Territory_Model__c.fields.Id.isAccessible() &&
           Schema.sObjectType.Territory_Model__c.fields.name.isAccessible() &&
           Schema.sObjectType.Territory_Model__c.fields.Country__c.isAccessible() &&
           Schema.sObjectType.Territory_Model__c.fields.Account_Type__c.isAccessible()){
            model = [SELECT id, name, Country__c, Last_Run__c FROM Territory_Model__c WHERE Id = :model.id];
        }
        showButton = false;
    }
    
    public void applyResults(){
        CustomLogging.push('applyResults', 'ApplyTerritoryResultsController');
        try{
            //update Territory Model definition status
            model.Definition_Status__c = SM_Constants.modelStatusApplying;
            
            if(Schema.sObjectType.Territory_Model__c.fields.Definition_Status__c.isUpdateable()){
                update model;
            }
            
            //trigger update batch
            TerritoryResult_UpdateBatch updateBat = new TerritoryResult_UpdateBatch();
            updateBat.modelId =  model.id;
            updateBat.modelCountry = model.Country__c;
            
            //get value from custom settings
            Map<String, AccountTerritoryAssignmentValues__c> cons = null;
            cons = AccountTerritoryAssignmentValues__c.getAll();
            AccountTerritoryAssignmentValues__c consVal = cons.get('updateBatchScope');
            
            database.executeBatch(updateBat, integer.valueOf(consVal.Value__c));
            
        } catch(Exception ex){
        	CustomLogging.debugException(ex);
            CustomLogging.pop();      
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());   
        }
    }
            
    public void applyResultsAndReturnToModel(){
        CustomLogging.push('applyResultsAndReturnToModel', 'ApplyTerritoryResultsController');
        //call method to apply results
        try{
            if (model.Last_Run__c != Null) {
                Datetime nextRun = model.Last_Run__c + 7;
                if (nextRun > Date.today() && ValidationRulesSettings__c.getInstance().AccountTerritory__c == true) {
                    modelCannotRun();
                } else {
                    applyModelAlert();
                }
            } else {
                applyModelAlert();
            }
            
        }
        catch(Exception ex){
        	CustomLogging.debugException(ex);
            CustomLogging.pop();      
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());   
        }
    }
    
    public pageReference modelCannotRun(){
  
        showButton = false;
        messageValue = 'Cannot run territory for the meantime. Please execute after 7 days of last run';
        buttonValue = 'Return Back';
        return null; 
        
    }
    
    public pageReference applyModelAlert() {
        showButton = true;
        messageValue = 'Irreversible, Existing Models will be inactivated. Do you want to continue?';
        buttonValue = 'No';
        return null;
        
    }
    
    public pageReference applyModeResult() {
        applyResults();
        PageReference pageRef = new PageReference('/'+model.id);
        return pageRef;
    }
    
    public pageReference returnToModel(){
        
        //open Territory Model details page
        PageReference pageRef = new PageReference('/'+model.id);
        return pageRef;
    }
    
}