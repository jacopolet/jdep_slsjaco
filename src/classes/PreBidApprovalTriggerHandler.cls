/**
 * Class Name: PreBidApprovalTriggerHandler
 * @author: Alvin Lomod
 * Date: 29-Nov-2017
 * Requirement: Trigger for Pre-Bid Approval
 * @description: Handles the functions to be executed by the trigger
 *          Created by S&M Team
 *
 */
 
 public without sharing class PreBidApprovalTriggerHandler implements ITriggerHandler{
    public static Boolean isTriggerDisabled = true;
    
    public void BeforeInsert(List<SObject> newMap){

    } 
 
    public void BeforeUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldMap){
        
    }
 
    public void BeforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems){
        
    }
 
    public void AfterInsert(List<SObject> newList, Map<Id, SObject> newItems){
        
    }
 
    public void AfterUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldMap){
        OnAfterUpdateReassignToManagerApprovalRequest((List<Pre_Bid_Approval__c>)newList, (Map<Id, Pre_Bid_Approval__c>)oldMap);
    }
 
    public void AfterDelete(List<SObject> oldList, Map<Id, SObject> oldItems){
        
    }
 
    public void AfterUndelete(List<SObject> newList, Map<Id, SObject> newItems){
        
    }
    
    public Boolean IsDisabled(){
        if (TriggerSettings__c.getInstance().PreBidApprovalTrigger__c == true) {
            return false;
        } else {
            return isTriggerDisabled;
        }
    }
    
    /**
     * Method Name: OnAfterUpdateReassignToManagerApprovalRequest
     * @author: Alvin Lomod
     * Date: 29-Nov-2017
     * Requirement: 
     * @description: Reassign current approval request to User's Manager
     *
     */
   
    public static void OnAfterUpdateReassignToManagerApprovalRequest(List<Pre_Bid_Approval__c> newPBAList, Map<Id, Pre_Bid_Approval__c> oldPBAMap){
    	
        CustomLogging.push('OnAfterUpdateReassignToManagerApprovalRequest', 'PreBidApprovalTriggerHandler');
        
        //List<Pre_Bid_Approval__c> validPBAList = new List<Pre_Bid_Approval__c>();
        Map<Id, Pre_Bid_Approval__c> validPBAMap = new Map<Id, Pre_Bid_Approval__c>();
        Set<Id> userIds = new Set<Id>();
        
        //Get Updated PBAs by workflow
        for(Pre_Bid_Approval__c pba : newPBAList){
            
            //Check if previous Approval Status is changed to "Pending Approval"
            if(pba.Approval_Status__c == 'Reject to Transfer' && oldPBAMap.get(pba.Id).Approval_Status__c == 'Pending Approval'){
                
                //validPBAList.add(pba);
                validPBAMap.put(pba.Id, pba);
                userIds.add(pba.User__c);
            }
            
        }
        
        if(validPBAMap.size() > 0){
            
            //Get user's manager            
            Map<Id, Id> UserMgrMap = new Map<Id, Id>();
            
            If(Schema.sObjectType.User.fields.Id.isAccessible() &&
               Schema.sObjectType.User.fields.ManagerId.isAccessible()){            
            
                for(User u : [SELECT Id, ManagerId FROM User WHERE Id  in: userIDs]){
                    UserMgrMap.put(u.Id, u.ManagerId);
                }
                   
            }
            
            //Get all pending approval request related to pre bid approval record            
            List<ProcessInstanceWorkItem> ApprovalRequestList = new List<ProcessInstanceWorkItem>();
            
            if(Schema.sObjectType.ProcessInstanceWorkitem.fields.Id.isAccessible() &&
               Schema.sObjectType.ProcessInstanceWorkitem.fields.ActorId.isAccessible() &&
               Schema.sObjectType.ProcessInstanceWorkitem.fields.OriginalActorId.isAccessible() &&
               Schema.sObjectType.ProcessInstanceWorkitem.fields.ProcessInstanceId.isAccessible() &&
               Schema.sObjectType.ProcessInstance.fields.Id.isAccessible() &&
               Schema.sObjectType.ProcessInstance.fields.TargetObjectId.isAccessible()){
            
                ApprovalRequestList = [SELECT Id, ActorId, OriginalActorId, ProcessInstanceId FROM ProcessInstanceWorkitem piwi WHERE piwi.ProcessInstanceId in (SELECT Id FROM ProcessInstance WHERE TargetObjectId in: validPBAMap.keySet())];
            
            }
            
            system.debug('Approval List: ' + ApprovalRequestList);
            
            if(ApprovalRequestList.size() > 0){
                
                Id UserMgr;
                //Update all the Approval request
                for(ProcessInstanceWorkItem piwi : ApprovalRequestList){
                    
                    UserMgr = UserMgrMap.get(piwi.ActorId);
                    system.debug('User Manager : '+ UserMgrMap.get(piwi.ActorId));
                    
                    if(UserMgr != null){
                        piwi.ActorId = UserMgrMap.get(piwi.ActorId);
                    }
                    
                    //return usermgr variable to null
                    UserMgr = null;
                }
                
                try{
                    If(Schema.sObjectType.ProcessInstanceWorkitem.fields.ActorId.isUpdateable()){                    
                           update ApprovalRequestList;                    
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