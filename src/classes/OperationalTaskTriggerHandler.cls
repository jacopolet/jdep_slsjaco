public without sharing class OperationalTaskTriggerHandler implements ITriggerHandler{
    public static Boolean isTriggerDisabled = true;
    
    public void beforeInsert(List<SObject> newListTask){
        
    } 
 
    public void beforeUpdate(List<SObject> newListTask, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldMapTask){
        validationforqueueanduser((List<Operational_Tasks__c>) newListTask, oldMapTask);
    }
 
    public void beforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems){
        preventDeletion((List<Operational_Tasks__c>) oldList);
    }
 
    public void afterInsert(List<SObject> newListTask, Map<Id, SObject> newItems){
        
    }
 
    public void afterUpdate(List<SObject> newListTask , Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldMapTask){
        if(SM_CheckRecursive.run == True){
            updateTaskRecordRelatedToOT((List<Operational_Tasks__c>) newListTask, oldMapTask);
        }
    }
 
    public void afterDelete(List<SObject> oldList, Map<Id, SObject> oldItems){
        
    }
 
    public void afterUndelete(List<SObject> newList, Map<Id, SObject> newItems){
        
    }
    
    public Boolean IsDisabled(){
        if (TriggerSettings__c.getInstance().OperationalTaskTrigger__c == true) {
            return false;
        } else {
            return isTriggerDisabled;
        }
    }
    
    public static void preventDeletion(List<Operational_Tasks__c> oldList) {
       CustomLogging.push('preventDeletion', 'OperationalTaskTriggerHandler');
       try {    
           String UserID = UserInfo.getUserId(); 
           User currentUser = new User();
           currentUser = [Select Id, Name, Sales_Organization__c, Profile.Name FROM User WHERE ID = :UserID];
           
           Country_Super_Users__c csu = Country_Super_Users__c.getInstance(UserID);
           if (currentUser != null){
                for(Operational_Tasks__c ot : oldList){
                    if (csu != null){
                        if (currentUser.Id != csu.Name && currentUser.Sales_Organization__c != csu.Sales_Organization__c && currentUser.Profile.Name != SM_Constants.SystemAdmin) {
                            ot.addError('You cannot delete this record. Insufficient Privilege');
                        }
                    }
                    else {
                        if (currentUser.Profile.Name != SM_Constants.SystemAdmin){
                            ot.addError('You cannot delete this record. Insufficient Privilege');
                        }
                    }
                }
           }
          
       } catch (Exception e) {
           CustomLogging.debugException(e);
           CustomLogging.pop();      
           System.debug(e.getMessage() + '\n' + e.getStackTraceString());
       }
           
    }
    
    public static void validationforqueueanduser(List<Operational_Tasks__c> newListTask,  Map<Id, SObject> oldMapTask){
        CustomLogging.push('updateTaskRecordRelatedToOT', 'OperationalTaskTriggerHandler');
        try {
            String UserID = UserInfo.getUserId(); 
            User currentUser = new User();
            if(UserID != null){
                currentUser = [Select Id, Name, Sales_Organization__c FROM User WHERE ID = :UserID];
            }
            if (oldMapTask != null){
                for(Operational_Tasks__c OT : newListTask){
                    Operational_Tasks__c oldOT = (Operational_Tasks__c) oldMapTask.get(OT.Id);
                    if (OT.OwnerId != oldOT.OwnerId){
                        if (OT.OwnerId != null && String.valueOf(OT.OwnerId).left(3) == SM_Constants.queuePrefix) {
                            QueueGateKeepers__c gatekeeper = QueueGateKeepers__c.getInstance(OT.OwnerId);
                            if (gatekeeper != null) {
                                if (currentUser.Sales_Organization__c != gatekeeper.Sales_Org_ID__c){
                                    OT.addError('Country of the Queue and your Sales Organization does not match, you can not add this to the queue');
                                }
                            }
                           
                        }
                    }
                }
            }
    
           
        } catch (Exception e) {
           CustomLogging.debugException(e);
           CustomLogging.pop();      
           System.debug(e.getMessage() + '\n' + e.getStackTraceString());
       }
    }
    public static void updateTaskRecordRelatedToOT(List<Operational_Tasks__c> newListTask,  Map<Id, SObject> oldMapTask){
        CustomLogging.push('updateTaskRecordRelatedToOT', 'OperationalTaskTriggerHandler');
        try {
            List<Task> taskRecs = new List<Task>();
            List<Task> updateTaskList = new List<Task>();
            Set<Id> TaskID = new Set<Id>();
            Map<Id, Operational_Tasks__c> otrecsMap = new Map<Id, Operational_Tasks__c>();
            if (!oldMapTask.isEmpty()){
                for (Operational_Tasks__c otrecs : newListTask){
                    Operational_Tasks__c oldtask = (Operational_Tasks__c) oldMapTask.get(otrecs.Id);
                    if (otrecs.OwnerId != oldTask.OwnerId || otrecs.Due_Date__c != oldTask.Due_Date__c || otrecs.Status__c != oldTask.Status__c || otrecs.Task_Source__c != oldTask.Task_Source__c ||
                            otrecs.Comments__c != oldTask.Comments__c || otrecs.Priority__c != oldTask.Priority__c || otrecs.Type__c != oldTask.Type__c || otrecs.Contact__c != oldTask.Contact__c ||
                            otrecs.Campaign__c != oldTask.Campaign__c || otrecs.Reason__c != oldTask.Reason__c || otrecs.Start_Date__c != oldTask.Start_Date__c || otrecs.ReminderSet__c != oldTask.ReminderSet__c ||
                            otrecs.ReminderDateTime__c != oldTask.ReminderDateTime__c){
                                TaskID.add(otrecs.Task_ID__c);
                                otrecsMap.put(otrecs.Task_ID__c, otrecs);
                    }
                }
            }
            
            if (!otrecsMap.isEmpty()){
                taskRecs = [Select Id, OwnerId, Subject, Updated_by_Trigger__c, Operational_Tasks__c, ActivityDate, Status, 
                            Task_Source__c, Priority, Type, Reason__c, WhatId, WhoId, Start_DateCS__c,
                            Date_Time_Closed__c, IsReminderSet, ReminderDateTime
                            FROM Task 
                            WHERE ID in : TaskID];
                
                if (!taskRecs.isEmpty()){
                    for (Task taskrec : taskRecs){
                        if (String.valueOf(otrecsMap.get(taskrec.Id).OwnerID).left(3) == '00G'){
                            QueueGateKeepers__c gatekeeper = QueueGateKeepers__c.getInstance(otrecsMap.get(taskrec.Id).OwnerId);
                            taskRec.OwnerId = gatekeeper.User_Keeper__c;
                        }
                        else {
                            taskRec.OwnerId = otrecsMap.get(taskrec.Id).OwnerId; 
                        }
                        taskRec.ActivityDate = otrecsMap.get(taskrec.Id).Due_Date__c;
                        taskRec.Status = otrecsMap.get(taskrec.Id).Status__c;
                        taskRec.Updated_by_Trigger__c = true;
                        taskRec.Task_Source__c = otrecsMap.get(taskrec.Id).Task_Source__c;
                        taskRec.Description = otrecsMap.get(taskrec.Id).Comments__c;
                        taskRec.Priority = otrecsMap.get(taskrec.Id).Priority__c;
                        taskRec.Type = otrecsMap.get(taskrec.Id).Type__c;
                        if (otrecsMap.get(taskrec.Id).Contact__c != Null) {
                            taskRec.WhoId = otrecsMap.get(taskrec.Id).Contact__c;  
                        }
                        if (otrecsMap.get(taskrec.Id).Campaign__c != Null) {
                            taskRec.Campaign__c = otrecsMap.get(taskrec.Id).Campaign__c;  
                        }
                        taskRec.Reason__c = otrecsMap.get(taskrec.Id).Reason__c;
                        taskRec.Start_DateCS__c = otrecsMap.get(taskrec.Id).Start_Date__c;
                        taskRec.IsReminderSet = otrecsMap.get(taskrec.Id).ReminderSet__c;
                        taskRec.ReminderDateTime = otrecsMap.get(taskrec.Id).ReminderDateTime__c;
                        updateTaskList.add(taskrec);
                    }
                }
                if (!updateTaskList.isEmpty()){
                    SM_CheckRecursive.run = false;
                    update updateTaskList;
                }
            }
            
       } catch (Exception e) {
           CustomLogging.debugException(e);
           CustomLogging.pop();      
           System.debug(e.getMessage() + '\n' + e.getStackTraceString());
       }
    
    }
}