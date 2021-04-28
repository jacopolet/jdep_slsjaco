//-------------------------------------------------------------------------------------------//
// Author       :   Jed Samaniego - Accenture
// Created Date :   November 10, 2017
//-------------------------------------------------------------------------------------------//
public without sharing class OpportunityTriggerHandler implements ITriggerHandler{
    private static final User u = UserDAO.userInformation();
    Map<Id, Opportunity> oldMap = new  Map<Id, Opportunity>();
    public static Boolean isTriggerDisabled = true;

    
    public void beforeInsert(List<Opportunity> newOpportunityList){
        oneTimeNOSCalculation(newOpportunityList, oldMap);
        stampSalesorganization(newOpportunityList);
        prepopulateOneTimeNOS(newOpportunityList);
        stampifaccountisprospect(newOpportunityList);
        stampexpectedrevstartdate(newOpportunityList, oldMap);
    } 
 

    public void beforeUpdate(List<Opportunity> newOpportunityList, Map<Id, SObject> newItems, List<Opportunity> oldList, Map<Id, SObject> oldOpportunityMap){
        Map<Id, Opportunity> oldOpptyMap = (Map<Id, Opportunity>) oldOpportunityMap;
        createContactRole(newOpportunityList);
        oneTimeNOSCalculation(newOpportunityList, oldOpptyMap);
        stampexpectedrevstartdate(newOpportunityList, oldOpptyMap);
    }
 
    public void beforeDelete(List<Opportunity> oldList, Map<Id, SObject> oldItems){
    
    }
 

    public void afterInsert(List<Opportunity> newOpportunityList, Map<Id, SObject> newItems){
        createContactRole(newOpportunityList);
        updateTaskWhatId(newOpportunityList);
    }
 
    public void afterUpdate(List<Opportunity> newOpportunityList , Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldOpportunityMap){
    }
 
    public void afterDelete(List<Opportunity> oldList, Map<Id, SObject> oldItems){
        
    }
 
    public void afterUndelete(List<Opportunity> newList, Map<Id, SObject> newItems){
        
    }
    
    public Boolean IsDisabled(){
        if (TriggerSettings__c.getInstance().OpportunityTrigger__c == true) {
            return false;
        } else {
            return isTriggerDisabled;
        }
    }


    public static void updateTaskWhatId (List<Opportunity> newOpportunityList){
        CustomLogging.push('updateTaskWhatId', 'OpportunityTriggerHandler');
        try {
            Map<String, Id> taskMap = new Map<String,Id>();
            List<Task> updateTask = new List<Task>();
            List<Opportunity> updateOpp = new List<Opportunity>();
            
            for(Opportunity opp: newOpportunityList){
                if(opp.Task_Id__c <> '' && opp.Task_Id__c <> null){          
                    taskMap.put(opp.Task_Id__c, opp.id);
                }
            }
            
            if (taskMap.size() > 0) {
                List<Task> taskRecs = [Select WhatId from Task where id in: taskMap.keyset()];
                
                if (taskRecs.size() > 0) {
                    for (Task t : taskRecs){
                        t.WhatId = taskMap.get(t.id);
                        updateTask.add(t);                
                    }
                }
            }
            
            if (updateTask.size() > 0) {
                update updateTask;
            }
        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
    }
    
    public static void createContactRole (List<Opportunity> newOpportunityList){
        CustomLogging.push('createContactRole', 'OpportunityTriggerHandler');
        try {
            Map<String, Id> taskMap = new Map<String,Id>();
            Map<Id, Task> taskMapRecs = new Map<Id,Task>();
            Set<Id> taskSet = new Set<Id>();
            Map<Id,TaskWhoRelation> taskWithConMap = new Map<Id,TaskWhoRelation>();
            Set<Id> taskWithConSet = new Set<Id>();
            Set<Id> taskWithMultiConSet = new Set<Id>();
            List<OpportunityContactRole> insertContactRole = new List<OpportunityContactRole>();
            Map<Id,Contact> contactMap = new Map<Id,Contact>();
            Set<Id> accountIdSet = new Set<Id>();
            Map<Id,Id> accountMap = new Map<Id,Id>();
    
            
            for(Opportunity opp: newOpportunityList){
                if(opp.Task_Id__c <> '' && opp.Task_Id__c <> null){          
                    taskMap.put(opp.Task_Id__c, opp.id);
                }
            }
            
            if (taskMap.size() > 0) {
                List<Task> taskRecs = [Select WhatId, WhoId from Task where id in: taskMap.keyset()];
                
                if (taskRecs.size() > 0) {
                    for (Task t : taskRecs){
                        if (t.WhatID <> Null && String.valueOf(t.WhatId).left(3)  == '001' || t.WhoID <> Null && t.WhatId <> Null && String.valueOf(t.WhatID).left(3) == '001' && String.valueOf(t.WhoId).left(3) == '003') {
                            taskSet.add(t.id);
                            taskMapRecs.put(t.id,t);
                        }
                    }
                }
            }
            
            if (taskSet.size() > 0) {
                List<TaskWhoRelation> taskWhoRelRecs = [Select TaskId, RelationId from TaskWhoRelation where Taskid in: taskSet];
                
                if (taskWhoRelRecs.size() > 0) {
                    for (TaskWhoRelation twr : taskWhoRelRecs){
                        if (taskWithConMap.containsKey(twr.TaskId)){
                            taskWithMultiConSet.add(twr.Taskid);
                        } else {
                            taskWithConSet.add(twr.TaskId);
                            taskWithConMap.put(twr.TaskId,twr);
                        }
                    }
                }
            }
            
            if (taskWithConSet.size() > 0) {
                for (Id i : taskWithConSet){
                    if (!taskWithMultiConSet.contains(i)) {
                        OpportunityContactRole oppConRole = new OpportunityContactRole();
                        oppConRole.ContactId = taskMapRecs.get(i).WhoId;
                        oppConRole.OpportunityId = TaskMap.get(i);
                        oppConRole.IsPrimary = True;
                        oppConRole.Role = 'Decision Maker';
                        
                        insertContactRole.add(oppConRole);
                    }
                }
            }
            
            if (taskWithMultiConSet.size() > 0) {
                for (Id i : taskWithMultiConSet){
                    accountIdSet.add(taskMapRecs.get(i).WhatId);
                    accountMap.put(taskMapRecs.get(i).WhatId,taskMap.get(i));
                }
            }
    
            If (accountIdSet.size() > 0) {
                List<Contact> mcpContacts = [Select Id, AccountId from Contact where AccountId in: accountIdSet and Main_Commercial_Person__c = True];
                if (mcpContacts.size() > 0){
                    for (Contact c : mcpContacts){
                        for (Id t : accountIdSet) {
                            if (t == c.AccountId) {
                                contactMap.put(t,c);    
                            }
                        }    
                    }
                }
            }
             
            if (contactMap.size() > 0) {
                for (Id i : accountIdSet){
                    OpportunityContactRole oppConRole = new OpportunityContactRole();
                    oppConRole.ContactId = contactMap.get(i).id;
                    oppConRole.OpportunityId = accountMap.get(i);
                    oppConRole.IsPrimary = True;
                    oppConRole.Role = 'Decision Maker';
                                    
                    insertContactRole.add(oppConRole);
                }    
            }    
    
            if (insertContactRole.size() > 0){
                insert insertContactRole;
            }
        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
    }
    
    /*
    * @author        Arianne Ayusa
    * @date          Jan 20 2020
    * @description   Calculation for Amount / One-Time NOS field
    */    
    
    private static Boolean checkUpdatesForOneTimeNOSCalculation(Opportunity oppty, Map<Id,Opportunity> oldOpptyMap){
        Opportunity oldOppty = oldOpptyMap.get(oppty.Id);
        Boolean relatedFieldUpdated = false;
        if (!oldOpptyMap.isEmpty()) {
            if (oppty.One_Time_NOS__c != oldOppty.One_Time_NOS__c || oppty.Expected_Revenue_Start_Date__c != oldOppty.Expected_Revenue_Start_Date__c ||
                   oppty.Estimated_Annual_NOS_Turnover__c != oldOppty.Estimated_Annual_NOS_Turnover__c || oppty.Annual_NOS_Current_Agreement__c != oldOppty.Annual_NOS_Current_Agreement__c || 
                   oppty.Percentage_Rewarded__c != oldOppty.Percentage_Rewarded__c) {
                relatedFieldUpdated = true;
            }
        } 
        return relatedFieldUpdated;
    }
    
    
    public static void oneTimeNOSCalculation(List<Opportunity> newOpptyList, Map<Id,Opportunity> oldOpptyMap){
        CustomLogging.push('oneTimeNOSCalculation', 'OpportunityTriggerHandler');
        try {
            Set<Opportunity> opptyToUpdate = new Set<Opportunity>();
            for(Opportunity oppty : newOpptyList){
                if(!oldOpptyMap.isEmpty()){
                    if(checkUpdatesForOneTimeNOSCalculation(oppty,oldOpptyMap)){
                        opptyToUpdate.add(oppty);
                    }
                }else{
                    opptyToUpdate.add(oppty);
                }
            }
            if (!opptyToUpdate.isEmpty()) {
                    SM_OpportunityUtil.oneTimeNOSCalculation(opptyToUpdate);
            }
        } catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        } 
        CustomLogging.pop(); 
    }
    // DOS-2241 Pre-populate the one-time NOS with value '0,-' for specific markets
    // Author: Glenn Serrano
    // 11/17/2020
    public static void prepopulateOneTimeNOS(List<Opportunity> newOpptyList){
        CustomLogging.push('prepopulateOneTimeNOS', 'OpportunityTriggerHandler');
        try {
            Set<Opportunity> populateonetimenos = new Set<Opportunity>();
            Map<String, Decimal> getmapofprepopulatedval = SM_GetMetadata.getonetimenosval();
            
            for(Opportunity oppty : newOpptyList){
                if(getmapofprepopulatedval.get(oppty.Sales_Organization__c) != null){
                   oppty.One_Time_NOS__c = getmapofprepopulatedval.get(oppty.Sales_Organization__c);
                }
            }
            
        } catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        } 
        CustomLogging.pop(); 
    }
    
    // DOS-2241 Pre-populate the one-time NOS with value '0,-' for specific markets
    // Author: Glenn Serrano
    // 11/17/2020
    // needed to be transferred from Process Builder to Apex
    
    public static void stampSalesorganization(List<Opportunity> newList){
        CustomLogging.push('stampSalesorganization', 'OpportunityTriggerHandler');
        try{
            if (!newList.isEmpty()){
                if (u.Profile.Name != Label.JDE_Integ_Digital && u.Profile.Name != Label.JDE_Integ_Sap && u.Profile.Name != Label.JDE_Integ_CTI && u.Profile.Name != Label.JDE_Integ_MC){
                    for (Opportunity oppty : newList){
                        if (u.Sales_Organization__c != null && oppty.Sales_Organization__c == null){
                            oppty.Sales_Organization__c = u.Sales_Organization__c;
                        }
                    }
                }
            }
        
        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop();   
    }
    
    // DOS-2222 if customer is a prospect, pre-populate the Annual NOS current agreement with '0,-' 
    // Author: Glenn Serrano
    // 12/15/2020
    
    public static void stampifaccountisprospect(List<Opportunity> newList){
        CustomLogging.push('stampifaccountisprospect', 'OpportunityTriggerHandler');
        try{
            Set<Id> accountIds = new Set<Id>();
            Set<Opportunity> opportunityrec = new Set<Opportunity>();
            if (!newList.isEmpty()){
                for (Opportunity oppty : newList){
                    if (oppty.AccountId != null){
                        accountIds.add(oppty.AccountId);
                        opportunityrec.add(oppty);
                    }
                }
                
                if (!accountIds.isEmpty()){
                    SM_OpportunityUtil.stampifaccountisprospect(accountIds, opportunityrec);
                }
            }
        
        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop();   
    }
    
    // DOS-2266 opportunity value on standard oppt mapped from close date to expected rev start date
    // Author: Glenn Serrano
    // 12/15/2020
    
    public static void stampexpectedrevstartdate(List<Opportunity> newList, Map<Id,Opportunity> oldopptyMap){
        CustomLogging.push('stampexpectedrevstartdate', 'OpportunityTriggerHandler');
        try{
            Set<Opportunity> opportunityrec = new Set<Opportunity>();
            if (!newList.isEmpty()){
                for (Opportunity oppty : newList){
                    if (checkUpdatesForclosedate(oppty, oldopptyMap) && oppty.RecordTypeId == SM_Constants.recordTypeIdStandardOpportunity){
                        opportunityrec.add(oppty);
                    }
                }
                
                if (!opportunityrec.isEmpty()){
                    SM_OpportunityUtil.stampexpectedrevstartdate(opportunityrec);
                }
            }
        
        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop();   
    }
    
    private static Boolean checkUpdatesForclosedate(Opportunity oppty, Map<Id,Opportunity> oldOpptyMap){
        Opportunity oldOppty = oldOpptyMap.get(oppty.Id);
        Boolean relatedFieldUpdated = false;
        if (!oldOpptyMap.isEmpty()) {
            if (oppty.CloseDate != oldOppty.CloseDate) {
                relatedFieldUpdated = true;
            }
        } else {
            if (oppty.CloseDate != null){
                relatedFieldUpdated = true;
            }
        }
        return relatedFieldUpdated;
    }
    
}