/**
* Class Name : APTS_BatchLogEventTriggerHandler
* Description :  Batch Log Event Trigger Handler which implements ITriggerHandler interface
* Author : Nagavi Babu
* Date Created : 22-03-2018
**/
public class APTS_BatchLogEventTriggerHandler implements ITriggerHandler{
    
    public void BeforeInsert(List<SObject> newItems){}
 
    public void BeforeUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldItems){}
 
    public void BeforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems){}
 
    public void AfterInsert(List<SObject> newList, Map<Id, SObject> newItems){
        createBatchError(newList);        
    }
 
    public void AfterUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldItems){}
 
    public void AfterDelete(List<SObject> oldList, Map<Id, SObject> oldItems){}
    
    public void AfterUndelete(List<SObject> newList, Map<Id, SObject> newItems){}
 
    public Boolean IsDisabled(){
        return (TriggerSettings__c.getInstance().BatchLogEventTrigger__c == true ? false : true);
    }
    
    public static void createBatchError(List<SObject> newList){
        List<APTS_Batch_Error__c> batchErrorList = new List<APTS_Batch_Error__c>();
        for(APTS_Batch_Log_Event__e logEvent : (List<APTS_Batch_Log_Event__e>)newList){
            APTS_Batch_Error__c batchError = new APTS_Batch_Error__c();
            batchError.APTS_Error_Name__c = logEvent.APTS_Error_Name__c;
            batchError.Error_Date_Time__c = logEvent.APTS_Error_Date_Time__c;
            batchError.APTS_Error_Level__c = logEvent.APTS_Error_Level__c;
            batchError.APTS_Error_Description__c = logEvent.APTS_Error_Description__c;
            batchError.APTS_Parent_ID__c = logEvent.APTS_Object_Id__c;
            batchError.APTS_Parent_Object_Name__c = logEvent.APTS_Object_Name__c;
            batchErrorList.add(batchError);
        }
        if(!batchErrorList.IsEmpty()){
            try{
                Database.Insert(batchErrorList, false);
            }catch(Exception ex){}
        }
    }
}