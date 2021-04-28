/*
* @author        Xen Reyes
* @date          11.09.2017          
* @description   Server-Side Controller class for SM_OperationalTaskHeaderController Lightning Component
* @revision(s)
*/
public without sharing class SM_OperationalTaskHeaderController {
    
    @AuraEnabled
    public static String getRelatedOTId(String recordId){
        CustomLogging.push('getRelatedOTId', 'SM_OperationalTaskHeaderController');
        String relatedOTId = '';
        try{
            Task t = [SELECT Id, Operational_Tasks__c FROM Task WHERE Id =: recordId];
            if(t != null && t.Operational_Tasks__c != null){
                relatedOTId = t.Operational_Tasks__c;
            }
            return relatedOTId; 
        } catch(Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
            System.debug(e);
            return null;
        }
        
    }
}