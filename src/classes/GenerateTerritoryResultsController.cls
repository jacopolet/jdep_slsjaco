/**
 * Class Name: GenerateTerritoryResultsController
 * @author: James Azana
 * Date: 13-Jun-2017
 * Requirement: Automated creation of Territory Results
 * @description: Executes the batch processes that creates the Territory Result records
 *
 */
 
 public with sharing class GenerateTerritoryResultsController{
    
    public Territory_Model__c model;
    public List<Territory_Result__c> result = new List<Territory_Result__c>();
    public List<Territory_Rule__c> rule = new List<Territory_Rule__c>();
    public Map<String, List<Territory_Rule__c>> ruleMap = new Map<String, List<Territory_Rule__c>>();
    public boolean noRule;
    
    public GenerateTerritoryResultsController(ApexPages.StandardController controller) {
        this.model = (Territory_Model__c)controller.getRecord();
        noRule = false;
        //get territory model record that triggers the process
        model = [SELECT id, name, Country__c, RecordTypeId FROM Territory_Model__c WHERE Id = :model.id];

        //get existing territory results associated with the territory model that triggers the process
        result = [SELECT id, Territory_Model__c FROM Territory_Result__c WHERE Territory_Model__c = :model.id LIMIT 100];
    }

    public void ProcessResults(){
        
        //populate Map for the territory results associated with the territory model
        String[] segmentValues;
        
        for(Territory_Rule__c ruleRec : [SELECT id, Segment__c, Territory_Model__c, Assigned_Owner__c, Assigned_Territory__c,
                                         Assigned_Territory__r.Commercial_Territory_Owner__c, Account_Lifecycle__c,
                                         Postal_Code_From__c, Postal_Code_To__c, Territory_Model__r.Country__c
                                         FROM Territory_Rule__c WHERE Territory_Model__c = :model.id]){
            
            //split segment values since it is a multi-select picklist and may contain more than one values
            if(ruleRec.Segment__c != null){
                segmentValues = ruleRec.Segment__c.split(';');
                
                for(String seg : segmentValues){
                    if(ruleMap.containsKey(seg)){
                        List<Territory_Rule__c> ruleList = ruleMap.get(seg);
                        ruleList.add(ruleRec);
                        ruleMap.put(seg, ruleList);
                    }else{
                        ruleMap.put(seg, new List<Territory_Rule__c> {ruleRec});
                    }
                }
            }
        }
        
        if(!ruleMap.isEmpty()){
            //get value from custom settings
            Map<String, AccountTerritoryAssignmentValues__c> cons = null;
            cons = AccountTerritoryAssignmentValues__c.getAll();
            AccountTerritoryAssignmentValues__c consVal;
            
            //if there are existing territory results associated with the territory model, execute delete batch
            if(!result.isEmpty()){
                TerritoryResult_DeleteBatch delBat = new TerritoryResult_DeleteBatch();
                delBat.modelId =  model.id;
                delBat.modelCountry =  model.Country__c;
                delBat.ruleMap = ruleMap;
                delBat.isPartial = false;
                
                consVal = cons.get('deleteBatchScope');
                database.executeBatch(delBat, integer.valueOf(consVal.Value__c));
            }else{
            //if there are NO existing territory results associated with the territory model, execute create batch
                TerritoryResult_CreateBatch newBat = new TerritoryResult_CreateBatch();
                newBat.modelId =  model.id;
                newBat.modelCountry =  model.Country__c;
                newBat.ruleMap = ruleMap;
                
                consVal = cons.get('createBatchScope');
                database.executeBatch(newBat, integer.valueOf(consVal.Value__c));
            }
            
            //update Definition Status of Model
            model.Definition_Status__c = SM_Constants.modelStatusGenerating;
            model.RecordTypeId = Schema.SObjectType.Territory_Model__c.getRecordTypeInfosByName().get(SM_Constants.modelRecTypeGenerating).getRecordTypeId(); //@Updated - Alvin Lomod - added recordtype when batch job is still running
            
            if(Schema.sObjectType.Territory_Model__c.fields.RecordTypeId.isUpdateable() &&
               Schema.sObjectType.Territory_Model__c.fields.Definition_Status__c.isUpdateable()){
                update model;
            }
            
        }else{
            //if no Territory Rule associated to the Territory Model, set checker 'noRule' to true
            noRule = true;
        }
    }
    
    public pageReference RefreshPage(){
        
        CustomLogging.push('RefreshPage', 'GenerateTerritoryResultsController');
        
        //call method to trigger batch processes
        try{
            ProcessResults();
        }
        catch(Exception ex){
        	CustomLogging.debugException(ex);
            CustomLogging.pop();      
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());   
        }
        
        if(noRule){
            //display error
            return null;
        }else{
            //reload model details page with updated definition status
            PageReference pageRef = new PageReference('/'+model.id);
            return pageRef;
        }
    }
    
    public pageReference ReturnToModelPage(){
    
        //open Territory Model details page
        PageReference pageRef = new PageReference('/'+model.id);
        return pageRef;
    }
 }