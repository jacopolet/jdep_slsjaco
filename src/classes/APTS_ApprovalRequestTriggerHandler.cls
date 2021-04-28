/**
* Class Name : APTS_ApprovalRequestTriggerHandler 
* Description :  Handler for APTS_ApprovalRequestTrigger
* Author : Juhi Rawal (Apttus)
* Date Created : 5th June,2018
**/
public class APTS_ApprovalRequestTriggerHandler implements ITriggerHandler{

    public void beforeInsert(List<SObject> newList){
        try{
            updateLookupFields(newList);
            System.debug('newList=====> ' + newList);
        }catch(Exception e){APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Approval Request', null,'CPQ',false,true,'cpqerror@accenture.com',true);}
        
    }

    public void beforeUpdate(List<SObject> newList, Map<Id, SObject> newItems,List<SObject> oldList, Map<Id, SObject> oldItems){
        try{
            updateLookupFields(newList);
            System.debug('newList=====> ' + newList);
        }catch(Exception e){APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Approval Request', null,'CPQ',false,true,'cpqerror@accenture.com',true);}
    }

    public void BeforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems){}

    public void AfterInsert(List<SObject> newList, Map<Id, SObject> newItems){}


    public void AfterUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldItems){}

    public void AfterDelete(List<SObject> oldList, Map<Id, SObject> oldItems){}
    
    public void AfterUndelete(List<SObject> newList, Map<Id, SObject> newItems){}
    
    public Boolean IsDisabled(){
        return (TriggerSettings__c.getInstance().APTS_ApprovalRequestTrigger__c == true ? false : true);
    }
    
    public void updateLookupFields(List<SObject> newList){
        for (Apttus_Approval__Approval_Request__c request : (List<Apttus_Approval__Approval_Request__c>) newList) { 
            if(String.isBlank(request.APTS_Related_Order__c) && request.Apttus_Approval__Object_Id__c!=null && request.Apttus_Approval__Object_Type__c=='Apttus_Config2__Order__c'){ 
                request.APTS_Related_Order__c = request.Apttus_Approval__Object_Id__c; 
            }
            if(String.isBlank(request.APTS_Related_Credit_Memo__c) && request.Apttus_Approval__Object_Id__c!=null && request.Apttus_Approval__Object_Type__c=='Apttus_Billing__CreditMemo__c'){ 
                request.APTS_Related_Credit_Memo__c = request.Apttus_Approval__Object_Id__c; 
            }
            if(String.isBlank(request.APTS_Related_IncentivePayoutSchedule__c) && request.Apttus_Approval__Object_Id__c!=null && request.Apttus_Approval__Object_Type__c=='Apttus_Rebate__IncentivePayoutSchedule__c'){ 
                request.APTS_Related_IncentivePayoutSchedule__c= request.Apttus_Approval__Object_Id__c; 
            }
        } 
    }

}