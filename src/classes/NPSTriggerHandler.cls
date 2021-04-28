public without sharing class NPSTriggerHandler implements ITriggerHandler{
    public static Boolean isTriggerDisabled = true;
    
    public void beforeInsert(List<SObject> newListTask){
        
    } 
 
    public void beforeUpdate(List<SObject> npsList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldMap){

    }
 
    public void beforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems){

    }
 
    public void afterInsert(List<SObject> npsList, Map<Id, SObject> newItems){
        createTaskRecord((List<NPS__c>) npsList);
    }
 
    public void afterUpdate(List<SObject> npsList , Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldMap){
        
    }
 
    public void afterDelete(List<SObject> oldList, Map<Id, SObject> oldItems){
        
    }
 
    public void afterUndelete(List<SObject> newList, Map<Id, SObject> newItems){
        
    }
    
    public Boolean IsDisabled(){
        if (TriggerSettings__c.getInstance().NPSDetailTrigger__c == true) {
            return false;
        } else {
            return isTriggerDisabled;
        }
    }
    
    public static void createTaskRecord (List<NPS__c> npsList) {
        CustomLogging.push('createTaskRecord', 'NPSTriggerHandler');
        try {
            List<Task> createTask = new List<Task>();
            List<NPS__c> npsRecords = new List<NPS__c>();
            if (Schema.sObjectType.NPS__c.fields.Id.isAccessible() && Schema.sObjectType.NPS__c.fields.Name.isAccessible() && Schema.sObjectType.NPS__c.fields.Account__c.isAccessible() && Schema.sObjectType.NPS__c.fields.Contact__c.isAccessible()) {
                npsRecords = [Select Id, Name, Account__r.Name, Account__r.Customer_Relations_1__c, Contact__c
                                FROM NPS__c 
                                WHERE Id IN :npsList];
            }
            Id automatedRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();    
            for(NPS__c npsRecord : npsRecords) {
                Datetime dateToday = datetime.now();
                String monthName = dateToday.format('MMMMM');
                Task t = new Task();
                t.WhatId = npsRecord.Id;
                t.Subject = 'NPS ' + npsRecord.Account__r.Name + ' ' + monthName + ' ' + dateToday.year();
                t.Touchpoint_Type__c = 'NPS';
                t.Task_Source__c = 'SFDC';
                t.Type = 'Outbound Non-Commercial';
                t.WhoId = npsRecord.Contact__c;
                if (npsRecord.Account__r.Customer_Relations_1__c <> Null){
                   t.OwnerId = npsRecord.Account__r.Customer_Relations_1__c; 
                } 
                t.RecordTypeId = automatedRecordTypeId;
                createTask.add(t);
            }
            
            if (!createTask.isEmpty()) {
                if (Schema.sObjectType.Task.fields.WhatId.isCreateable() && Schema.sObjectType.Task.fields.Subject.isCreateable() && Schema.sObjectType.Task.fields.Touchpoint_Type__c.isCreateable() && Schema.sObjectType.Task.fields.Task_Source__c.isCreateable()
                    && Schema.sObjectType.Task.fields.Type.isCreateable() && Schema.sObjectType.Task.fields.WhoId.isCreateable()) {
                    insert createTask;
                }
            }
            
        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        
    }
}