public with sharing class GeneratePartialResultController {
	public Territory_Model__c model;
    public List<Territory_Result__c> result = new List<Territory_Result__c>();
    public List<Territory__c> territories = new List<Territory__c>();
    public Integer partialAccounts;
    
    public GeneratePartialResultController(ApexPages.StandardController controller) {
        this.model = (Territory_Model__c)controller.getRecord();
        //get territory model record that triggers the process
        model = [SELECT id, name, Country__c, Last_Run__c, Definition_Status__c, RecordTypeId
                 FROM Territory_Model__c WHERE Id = :model.id];
        //get existing territory results associated with the territory model that triggers the process
		result = [SELECT id, Territory_Model__c 
                  FROM Territory_Result__c 
                  WHERE Territory_Model__c = :model.id LIMIT 100];
        territories = [Select ID FROM Territory__c WHERE isChanged__c = true AND Territory_Model__c = :model.id];
        partialAccounts = [SELECT COUNT() FROM Account WHERE Territory__c IN :territories];
    }

    public void ProcessResults(){
		if (partialAccounts > 0 ) {
            //get value from custom settings
            Map<String, AccountTerritoryAssignmentValues__c> cons = null;
            cons = AccountTerritoryAssignmentValues__c.getAll();
            AccountTerritoryAssignmentValues__c consVal;
        
            if (!result.isEmpty()) {
                TerritoryResult_DeleteBatch delBat = new TerritoryResult_DeleteBatch();
                delBat.modelId =  model.id;
                delBat.modelCountry =  model.Country__c;
                delBat.ruleMap = null;
                delBat.isPartial = true;
                delBat.territories = territories;
                
                consVal = cons.get('deleteBatchScope');
                database.executeBatch(delBat, integer.valueOf(consVal.Value__c));
            } else {
                TerritoryResult_PartialCreateBatch newBat = new TerritoryResult_PartialCreateBatch();
                newBat.modelId =  model.id;
                newBat.territories = territories;
                    
                consVal = cons.get('createBatchScope');
                database.executeBatch(newBat, integer.valueOf(consVal.Value__c));
            }
            //update Definition Status of Model
            model.Definition_Status__c = SM_Constants.modelStatusGenerating;
            model.RecordTypeId = Schema.SObjectType.Territory_Model__c.getRecordTypeInfosByName().get(SM_Constants.modelRecTypeGenerating).getRecordTypeId(); //@Updated - Alvin Lomod - added recordtype when batch job is still running
            update model;
        } 
    }
    
    public pageReference RefreshPage(){
        CustomLogging.push('RefreshPage', 'GenerateTerritoryResultsController');
        //call method to trigger batch processes
        try{
            ProcessResults(); 
            if (partialAccounts > 0) {
                PageReference pageRef = new PageReference('/'+model.id);
            	return pageRef;
            } else {
                return null;
            }
            
        }
        catch(Exception ex){
        	CustomLogging.debugException(ex);
            CustomLogging.pop();      
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());   
            return null;
        }
    }
    
    public pageReference returnToModelPage(){
    
        //open Territory Model details page
        PageReference pageRef = new PageReference('/'+model.id);
        return pageRef;
    }
}