/*-------------------------------------------------------------------------------------------
Author       :   Catherine Aragon - Accenture
Created Date :   August 08, 2017
Usage        :   This class is for identifiying the type of whatId and whoId from Event object
                 and assign its value on custom fields.
-------------------------------------------------------------------------------------------*/
public without sharing class EventWhoIdWhatId {
    @InvocableMethod
    public static void assignWhatIdWhoID (List<Id> ListID){
        CustomLogging.push('assignWhatIdWhoID', 'EventWhoIdWhatId');
        try {
            List<Event> updateEvent = new List<Event>();
            List<Event> EventRecs = new List<Event>();
            EventRecs = [Select Id, Who.type, What.type from Event WHERE ID in : ListID LIMIT 10000];
                
            for (Event Eventrec : EventRecs){
                Eventrec.WhatType__c = Eventrec.What.type;
                Eventrec.WhoType__c = Eventrec.Who.type;
                updateEvent.add(Eventrec);
            }
            
    
            if (!updateEvent.isEmpty()){
                update updateEvent;    
            }
            
        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
    }
}