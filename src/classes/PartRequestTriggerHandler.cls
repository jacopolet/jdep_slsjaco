/**
* @author        Karen Hung
* @date          13.11.2019
* @description   Class responsible for the trigger business logic of Part Request, part of DOO-2196
* @revision(s)   
*/
public without sharing class PartRequestTriggerHandler implements ITriggerHandler {
    
    public static Boolean isTriggerDisabled = true;
    
    public class PartRequestTriggerHandlerException extends Exception {}
    
    public static boolean hasException = false;
    
    public void BeforeInsert(List<SObject> newList) {
        validateItem(newList,null,null);
        
    }
    
    public void BeforeUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldMap) {
        validateItem(newList,oldMap,newItems);	
    }
    
    public void BeforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems) {
        
    }
    
    public void AfterInsert(List<SObject> newList, Map<Id, SObject> newItems) {
        
    }
    
    public void AfterUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldItems) {
        Map<Id, Part_Request__c> newMapItems = (Map<Id, Part_Request__c>) newItems;
        Map<Id, Part_Request__c> oldMapItems = (Map<Id, Part_Request__c>) oldItems;
        createIntegrationLogs(newList, oldMapItems, newMapItems);
    }
    
    public void AfterDelete(List<SObject> oldList, Map <Id, SObject> oldItems) {
        
    }
    
    public void AfterUndelete(List<SObject> newList, Map <Id, SObject> newItems) {
        
    }
    
    public Boolean IsDisabled() {
        if (TriggerSettings__c.getInstance().PartRequestTrigger__c == true) {
            return false;
        } else {
            return isTriggerDisabled;
        }
    }
    
    /****Method for custom validation***/
    public void validateItem(List<SObject> newItems, Map<Id, SObject> oldMapItems, Map<Id, SObject> newMapItems){
        CustomLogging.push('validateItem', 'PartRequestTriggerHandler');
        
        List<Part_Request__c> newList = (List<Part_Request__c>) newItems;
        Map<Id,Part_Request__c> newMap = (Map<Id,Part_Request__c>) newMapItems;
        Map<Id,Part_Request__c> oldMap = (Map<Id,Part_Request__c>) oldMapItems;
        
        try{
            if (Test.isRunningTest() && hasException) {
                throw new PartRequestTriggerHandlerException(TS_Constants.FORCE_EXCEPTION);
            }
            
            /**Validation : You can only create a part request if there is an active country setting for the related resource company code**/
            
            //get company codes in country settings - Country Purchasing Setting Recordtype
            Set<String> companyCodes = new Set<String>();
            for(CountrySetting__c cset : [SELECT Id, Company_Code__c FROM CountrySetting__c WHERE Active__c = true AND RecordType.Name = :TS_Constants.TS_COUNTRYSETTING_RECORDTYPE_COUNTRYPURCHASING]){
                companyCodes.add(cset.Company_Code__c);    
            }
            
            //put errors
            for(Part_Request__c partR : newList){
                if(!companyCodes.contains(partR.Company_Code__c)){
                    //put error on insert and status change
                    if(oldMapItems == null || (oldMap.get(partR.Id).Status__c != newMap.get(partR.Id).Status__c && newMap.get(partR.Id).Status__c == TS_Constants.STATUS_COMPLETED)){
                   		partR.addError(TS_Constants.ERRORMESSAGE_NOCOUNTRYSETTING); // Please contact your administrator to activate the purchasing settings for your company.     
                    }                     
                }	    
            }
                        
        }catch(Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());           
        }        
        
        CustomLogging.pop(); 
    }
    
    /*Method to create Integration Logs*/
    public void createIntegrationLogs(List<Part_Request__c> newList, Map<Id, Part_Request__c> oldRecordMap, Map<Id, Part_Request__c> newRecordMap) {
        CustomLogging.push('createIntegrationLogs', 'PartRequestTriggerHandler');
        try{
            
            if (Test.isRunningTest() && hasException) {
                throw new PartRequestTriggerHandlerException(TS_Constants.FORCE_EXCEPTION);
            }
            
            List<Integration_Log__c> integLogsToInsertList = new List<Integration_Log__c>();
            for(Part_Request__c pReq : newList){
                //when request is updated to Completed
                if(oldRecordMap.get(pReq.Id).Status__c != newRecordMap.get(pReq.Id).Status__c && newRecordMap.get(pReq.Id).Status__c == TS_Constants.STATUS_COMPLETED){
                    integLogsToInsertList.addAll(validatePartRequest(pReq));	      
                }
            }
            //check if integLogsToInsertList is not empty and proceed to insertion
            if(integLogsToInsertList != null && !integLogsToInsertList.isEmpty()  && Schema.sObjectType.Integration_Log__c.isCreateable()) {
                insert integLogsToInsertList;    
            }
            
        }catch(Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());            
        }
        CustomLogging.pop();      
    }
    
    /*integration log creation*/
    public List<Integration_Log__c> validatePartRequest(Part_Request__c pRequest){
        CustomLogging.push('validatePartRequest', 'PartRequestTriggerHandler');
        List<Integration_Log__c> integLogsList = new List<Integration_Log__c>();
        
        //CREATE INTEGRATION LOGS
        integLogsList.add(new Integration_Log__c(Object_Id__c = pRequest.Id,
                                                 Object__c = 'Part Request - Car Stock Replenishment',
                                                 Integration_Status__c = INT_Constants.INITIAL,
                                                 Part_Request__c = pRequest.Id));  
        
        CustomLogging.pop(); 
        return integLogsList; 
        
    }
    
}