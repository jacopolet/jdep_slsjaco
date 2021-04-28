/**
 * Class Name: TerritoryModelTriggerHandler
 * @author: James Azana
 * Date: 23-Jun-2017
 * Requirement: Trigger for Territory Model object
 * @description: Handles the functions to be executed by the trigger
 *
 */
 
 public with sharing class TerritoryModelTriggerHandler implements ITriggerHandler{
    public static Boolean isTriggerDisabled = true;
    
    public void BeforeInsert(List<SObject> newMap){

    } 
 
    public void BeforeUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldMap){
        
    }
 
    public void BeforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems){
        
    }
 
    public void AfterInsert(List<SObject> newList, Map<Id, SObject> newItems){
        OnAfterInsertCopyAllTerritoryRulesOnClone((List<Territory_Model__c>)newList, (Map<Id, Territory_Model__c>)newItems);
    }
 
    public void AfterUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldMap){
        
    }
 
    public void AfterDelete(List<SObject> oldList, Map<Id, SObject> oldItems){
        
    }
 
    public void AfterUndelete(List<SObject> newList, Map<Id, SObject> newItems){
        
    }
    
    public Boolean IsDisabled(){
        if (TriggerSettings__c.getInstance().TerritoryModelTrigger__c == true) {
            return false;
        } else {
            return isTriggerDisabled;
        }
    }
    
    /**
     * Method Name: onAfterInsertCopyAllTerritoryRulesOnClone
     * @author: Alvin Lomod
     * Date: 27-Jun-2017
     * Requirement: 
     * @description: Copies all Territory Rules associated with Territory Model when cloned.
     *
     */
   
    public static void OnAfterInsertCopyAllTerritoryRulesOnClone(List<Territory_Model__c> modelList, Map<Id, Territory_Model__c> modelMap){
        
        CustomLogging.push('OnAfterInsertCopyAllTerritoryRulesOnClone', 'TerritoryModelTriggerHandler');
        
        Map<Id,Id> cloneIdNewModelId = new Map<Id,Id>();
        List<Id> modelRecordIds = new List<Id>();
        
        //Put cloned territory models' Ids and new territory model ids into a map
        for(Territory_Model__c model : modelList){
            system.debug(model.Record_Id__c);
            if(model.Record_Id__c != null){
                cloneIdNewModelId.put(model.Record_Id__c, model.Id);
                modelRecordIds.add(model.Record_Id__c);
            }
        }
        
        system.debug(modelRecordIds.size());
        
        if(modelRecordIds.size() > 0){
            
            system.debug('Enter Territory rule query');    
            
            // Get all Territory Rules from cloned models
            List<Territory_Rule__c> ruleList = new List<Territory_Rule__c>();
            
            if(Schema.sObjectType.Territory_Rule__c.fields.Account_Lifecycle__c.isAccessible() &&
               Schema.sObjectType.Territory_Rule__c.fields.Industry_Code_To__c.isAccessible() &&
               Schema.sObjectType.Territory_Rule__c.fields.Industry_Code_From__c.isAccessible() &&
               Schema.sObjectType.Territory_Rule__c.fields.Area_Code_To__c.isAccessible() &&
               Schema.sObjectType.Territory_Rule__c.fields.Area_Code_From__c.isAccessible() &&
               Schema.sObjectType.Territory_Rule__c.fields.Assigned_Owner__c.isAccessible() &&
               Schema.sObjectType.Territory_Rule__c.fields.Assigned_Territory__c.isAccessible() &&
               Schema.sObjectType.Territory_Rule__c.fields.Beds_To__c.isAccessible() &&
               Schema.sObjectType.Territory_Rule__c.fields.Beds_From__c.isAccessible() &&
               Schema.sObjectType.Territory_Rule__c.fields.Drinks_To__c.isAccessible() &&
               Schema.sObjectType.Territory_Rule__c.fields.Drinks_From__c.isAccessible() &&
               Schema.sObjectType.Territory_Rule__c.fields.Employees_To__c.isAccessible() &&
               Schema.sObjectType.Territory_Rule__c.fields.Employees_From__c.isAccessible() &&
               Schema.sObjectType.Territory_Rule__c.fields.Name.isAccessible() &&
               Schema.sObjectType.Territory_Rule__c.fields.OwnerId.isAccessible() && 
               Schema.sObjectType.Territory_Rule__c.fields.Postal_Code_To__c.isAccessible() &&
               Schema.sObjectType.Territory_Rule__c.fields.Postal_Code_From__c.isAccessible() &&
               Schema.sObjectType.Territory_Rule__c.fields.Seats_To__c.isAccessible() &&
               Schema.sObjectType.Territory_Rule__c.fields.Seats_From__c.isAccessible() &&
               Schema.sObjectType.Territory_Rule__c.fields.Visitors_To__c.isAccessible() &&
               Schema.sObjectType.Territory_Rule__c.fields.Visitors_From__c.isAccessible() &&
               Schema.sObjectType.Territory_Rule__c.fields.Segment__c.isAccessible() &&
               Schema.sObjectType.Territory_Rule__c.fields.Territory_Model__c.isAccessible()){
                ruleList = [SELECT Account_Lifecycle__c,Industry_Code_To__c,Industry_Code_From__c,Area_Code_From__c,Area_Code_To__c,Assigned_Owner__c,Assigned_Territory__c,Beds_From__c,Beds_To__c,Drinks_From__c,Drinks_To__c,Employees_From__c,Employees_To__c,Name,OwnerId,Postal_Code_From__c,Postal_Code_To__c,Seats_From__c,Seats_To__c,Visitors_To__c,Visitors_From__c,Segment__c,Territory_Model__r.Id FROM Territory_Rule__c WHERE Territory_Model__r.Id in: cloneIdNewModelId.keySet() ORDER BY CreatedDate ASC];            
            }
               system.debug('Rule List size: ' + ruleList.size());
            
            //check if there are rules related to the model, then proceed to following logic
            if(ruleList.size() > 0){
            
                Map<Id, List<Territory_Rule__c>> modelIdRuleListMap = new Map<Id, List<Territory_Rule__c>>();
                
                // map list temp placeholder
                List<Territory_Rule__c> tempRuleList = new List<Territory_Rule__c>();
                List<Territory_Rule__c> FinalRuleList = new List<Territory_Rule__c>();
                
                for(Integer count = 0; count < modelRecordIds.size(); count++){
                    
                    modelIdRuleListMap.put(modelRecordIds[count], new List<Territory_Rule__c>());
                    
                    for(Territory_Rule__c rule : ruleList){
                        
                        if(rule.Territory_Model__r.Id == modelRecordIds[count]){
                            //assign new territory model Id to the rule that will be clone
                            system.debug(cloneIdNewModelId.get(modelRecordIds[count]));
                            rule.Territory_Model__c = cloneIdNewModelId.get(modelRecordIds[count]);
                            rule.Id = null;
                            system.debug(rule.Territory_Model__r.Id);
                            tempRuleList.add(rule);
                            FinalRuleList.add(rule);
                        }
                    
                    }
                    
                    //Debug if Territory Model has the correct list of Territory rules
                    modelIdRuleListMap.put(modelRecordIds[count], tempRuleList);
                    
                    system.debug('Model Id: ' + modelRecordIds[count]);
                    system.debug('Rule List: ' + modelIdRuleListMap.get(modelRecordIds[count]));
                    
                    tempRuleList.clear();
                }
                
                //Insert territory rules
                if(FinalRuleList.size() > 0){
                    system.debug('Final Size: ' + FinalRuleList.size());
                    
                    try{
                        if(Schema.sObjectType.Territory_Rule__c.fields.Territory_Model__c.isCreateable()){
                            insert FinalRuleList;
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
    
    }
 
 }