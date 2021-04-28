public without sharing class EventTriggerHandler implements ITriggerHandler{
    public static Boolean isTriggerDisabled = true;
    private static final User u = UserDAO.userInformation();
    Map<Id, Event> oldMap = new  Map<Id, Event>();
    
    public void beforeInsert(List<Event> newListEvent){  
         populateAccountLookup(newListEvent, oldMap);
         populateRoleId(newListEvent, oldMap);
         stampAccountLifecycleandSegment(newListEvent, oldMap);
         stampCampaignIdFromContactorLead(newListEvent);
         stampSalesOrg(newListEvent);
    } 
 
    public void beforeUpdate(List<Event> newListEvent, Map<Id, SObject> newItems, List<Event> oldList, Map<Id, SObject> oldMapEvent){
        Map<Id, Event> oldEventMap = (Map<Id, Event>) oldMapEvent;
         if(checkRecursive.run == true){
            populateAccountLookup (newListEvent, oldEventMap);
            populateRoleId (newListEvent, oldEventMap);
            stampAccountLifecycleandSegment (newListEvent, oldEventMap);
            checkRecursive.run = false;
        }
    }
 
    public void beforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems){
    }
 
    public void afterInsert(List<Event> newListEvent, Map<Id, SObject> newItems){
         populateWhatTypeWhoType(newListEvent, oldMap);
         setAccountLastEventDateRelevantDate(newListEvent, oldMap);
    }
 
    public void afterUpdate(List<Event> newListEvent , Map<Id, SObject> newItems, List<Event> oldList, Map<Id, SObject> oldMapEvent){
         Map<Id, Event> oldEventMap = (Map<Id, Event>) oldMapEvent;
         populateWhatTypeWhoType (newListEvent, oldEventMap);
         setAccountLastEventDateRelevantDate(newListEvent, oldEventMap);
    }
 
    public void afterDelete(List<SObject> oldList, Map<Id, SObject> oldItems){
    }
 
    public void afterUndelete(List<SObject> newList, Map<Id, SObject> newItems){        
    }
    
    public Boolean IsDisabled(){
        if (TriggerSettings__c.getInstance().EventTrigger__c == true) {
            return false;
        } else {
            return isTriggerDisabled;
        }
    }

    private static List<Event> filtertaskswithchangedWhatIdaccountornew (List<Event> events, Map<Id, SObject> oldMapEvent){
        List<Event> filtertaskswithWhatIdAccount = new List<Event>();
        
        for (Event e : events){
            if (!oldMapEvent.isEmpty()){
                Event oldEvents = (Event) oldMapEvent.get(e.Id);
                if (e.WhatId != oldEvents.WhatId || oldEvents == null){
                    filtertaskswithWhatIdAccount.add(e);
                }
            }
            else{
                filtertaskswithWhatIdAccount.add(e);
            }
        }
        
        return filtertaskswithWhatIdAccount;
    }
    
    private static List<Event> filtertaskswithchangedAssignedtoornew (List<Event> events, Map<Id, SObject> oldMapEvent){
        List<Event> filtertaskswithAssignedto = new List<Event>();
        
        for (Event e : events){
            if (!oldMapEvent.isEmpty()){
                Event oldEvents = (Event) oldMapEvent.get(e.Id);
                if (e.OwnerId != oldEvents.OwnerId || oldEvents == null){
                    filtertaskswithAssignedto.add(e);
                }
            }
            else{
                filtertaskswithAssignedto.add(e);
            }
        }
        
        return filtertaskswithAssignedto;
    }
    
    private static List<Event> filtertaskswithchangedWhatIdorWhoIDornew (List<Event> events, Map<Id, SObject> oldMapEvent){
        List<Event> filtertaskswithWhatIdorWhoId = new List<Event>();
        
        for (Event e : events){
            if (!oldMapEvent.isEmpty()){
                Event oldEvents = (Event) oldMapEvent.get(e.Id);
                if (e.WhatId != oldEvents.WhatId || e.WhoId != oldEvents.WhoId || oldEvents == null){
                    filtertaskswithWhatIdorWhoId.add(e);
                }
            }
            else{
                filtertaskswithWhatIdorWhoId.add(e);
            }
        }
        
        return filtertaskswithWhatIdorWhoId;
    }
    
    public static void populateWhatTypeWhoType (List<Event> newListEvent, Map<Id, Event> oldMapEvent){
        CustomLogging.push('populateWhatTypeWhoType', 'EventTriggerHandler');
        try {
            List<Event> filterchangesonWhatIdWhoId = filtertaskswithchangedWhatIdorWhoIDornew(newListEvent, oldMapEvent);
            if (!filterchangesonWhatIdWhoId.isEmpty()){
                Set<ID> filteredEvents = new Set<ID>();
                
                for (Event e: filterchangesonWhatIdWhoId){
                    if (e.WhatId != null && String.valueOf(e.WhatId).left(3) == SM_Constants.accountPrefix || e.WhoId != null && String.valueOf(e.WhoId).left(3) == SM_Constants.contactPrefix){
                        filteredEvents.add(e.Id);
                    }
                }
                if (!filteredEvents.isEmpty()){
                    SM_EventUtil.StampWhatTypeWhoType(filteredEvents);
                } 
            }
        } catch (Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
    }

    public static void populateAccountLookup (List<Event> newListEvent, Map<Id, Event> oldMapEvent){
        CustomLogging.push('populateAccountLookup', 'EventTriggerHandler');
        try {
            List<Event> populateAccountLookuponEvents = filtertaskswithchangedWhatIdaccountornew(newListEvent, oldMapEvent);
            if (!populateAccountLookuponEvents.isEmpty()){
                List<Event> filteredEvents = new List<Event>();
                
                for (Event e: populateAccountLookuponEvents){
                    if (e.WhatId != null && String.valueOf(e.WhatId).left(3) == SM_Constants.accountPrefix){
                        filteredEvents.add(e);
                    }
                }
                List<Event> processedEvents = new List<Event>();
                processedEvents = SM_EventUtil.populateAccountLookuponEvents(filteredEvents);
            }
            
        } catch (Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
                                                
    }
    
    public static void populateRoleId (List<Event> newListEvent, Map<Id, Event> oldMapEvent){
        CustomLogging.push('populateRoleId', 'EventTriggerHandler');
        try {
            List<Event> eventswithownerID = filtertaskswithchangedAssignedtoornew(newListEvent, oldMapEvent);
            if (!eventswithownerID.isEmpty()){
                List<Event> filteredEvents = new List<Event>();
                
                for (Event e : eventswithownerID){
                    if(e.OwnerId != null){
                        filteredEvents.add(e);
                    }
                }
                List<Event> processedEvents = new List<Event>();
                processedEvents = SM_EventUtil.populateRoleId(filteredEvents);
            }
        } catch (Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
                                                
    }
    
    public static void stampAccountLifecycleandSegment (List<Event> newListEvent, Map<Id, Event> oldMapEvent){
        CustomLogging.push('stampAccountLifecycleandSegment', 'EventTriggerHandler');
        try {
            List<Event> stampLifecycleandsegment = filtertaskswithchangedWhatIdaccountornew(newListEvent, oldMapEvent);
            if (!stampLifecycleandsegment.isEmpty()){
                List<Event> filteredEvents = new List<Event>();
                
                for (Event e : stampLifecycleandsegment){
                    if(e.WhatId != null && (String.valueOf(e.WhatId).left(3) == SM_Constants.accountPrefix || String.valueOf(e.WhatId).left(3) == SM_Constants.oppPrefix ||
                       String.valueOf(e.WhatId).left(3) == Label.Account_Location_Prefix)){
                        filteredEvents.add(e);
                    }
                }
                List<Event> processedEvents = new List<Event>();
                processedEvents = SM_EventUtil.stampAccountLifecycleandSegment(filteredEvents);
            }
        } catch (Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
                                                
    }
    public static void stampCampaignIdFromContactorLead(List<Event> newListEvent){
        CustomLogging.push('stampCampaignIdFromContactorLead', 'EventTriggerHandler');
        try {
            List<Event> EventRelatedToContactorLead = new List<Event>(newListEvent);
            if (!EventRelatedToContactorLead.isEmpty()){
                List<Event> eventmeetscriteriaforcampaign = new List<Event>();
                for (Event e : EventRelatedToContactorLead){
                    if (e.WhoId != null && (String.valueOf(e.WhoId).left(3) == SM_Constants.contactPrefix || String.valueOf(e.WhoId).left(3) == SM_Constants.leadPrefix)){
                        eventmeetscriteriaforcampaign.add(e);
                    }
                }
                List<Event> processedEvents = SM_EventUtil.stampCampaignIdFromContactorLead(eventmeetscriteriaforcampaign);
            }
            
        } catch (Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
    }

    public static void stampSalesOrg(List<Event> newListEvent){
        CustomLogging.push('stampSalesOrg', 'EventTriggerHandler');
        try {
            if (!newListEvent.isEmpty()){
                For (Event e : newListEvent){
                    if (u.Sales_Organization__c != null && u.Profile.Name != SM_Constants.JDESAP && u.Profile.Name != SM_Constants.JDECTI && u.Profile.Name != SM_Constants.JDEMARKETING
                        && u.Profile.Name != SM_Constants.JDEDigital){
                        e.Sales_Organization__c = u.Sales_Organization__c;
                    }
                }
            }

        } catch (Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
    }
    
    private static Boolean eventisCompleted(Event e, Map<ID, Event> oldEventMap){
        Event oldEvent;
        Boolean eventUpdate = false;
        
        if (!oldEventMap.isEmpty()){
            oldEvent = oldEventMap.get(e.Id);
            if (e.Status__c != oldEvent.Status__c && e.Status__c == 'Completed' && String.valueOf(e.WhatId).left(3) == SM_Constants.accountPrefix){
                eventUpdate = true;
            }
        } else {
            if (e.Status__c == 'Completed' && String.valueOf(e.WhatId).left(3) == SM_Constants.accountPrefix){
                eventUpdate = true;
            }
        }
        
        return eventUpdate;
    }
    
    public static void setAccountLastEventDateRelevantDate(List<Event> events, Map<ID, Event> oldEventMap){
        CustomLogging.push('setAccountLastEventDateRelevantDate', 'EventTriggerHandler');
        try{
            Set<Id> accountIds = new Set<Id>();
            for (Event e : events){
                if (eventisCompleted(e, oldEventMap)){
                    accountIds.add(e.WhatId);
                }
            }
            if (!accountIds.isEmpty()){
                SM_EventUtil.setAccountLastEventDateRelevantDate(accountIds);
            }
        } catch (Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
    }
}