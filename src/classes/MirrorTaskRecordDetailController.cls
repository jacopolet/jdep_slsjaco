//-------------------------------------------------------------------------------------------//
// Author       :   Catherine Aragon - Accenture
// Created Date :   September 22, 2017
// Usage        :   Class for lightning component that will return task details
//-------------------------------------------------------------------------------------------//
public without sharing class MirrorTaskRecordDetailController {
    @AuraEnabled
    public static Task getTask(String OTrecordId) {
        CustomLogging.push('getTask', 'MirrorTaskRecordDetailController');
        Task taskRec = new Task();
        try {
            Operational_Tasks__c otRec = new Operational_Tasks__c();
            otRec = [Select Id, Name, Updated_by_Trigger__c, Task_ID__c, OwnerId
                      FROM Operational_Tasks__c 
                      WHERE Id = : OTrecordId];
        
            
            if(otRec.Task_ID__c <> Null || otRec.Task_ID__c <> ''){
                 taskRec = [Select Id, OwnerId, Subject, Updated_by_Trigger__c, Operational_Tasks__c,
                                   ActivityDate, WhoId, WhatId, Priority, Type, Status,
                                   Description, Task_Source__c, Campaign__c, Contact__c, 
                                   Reason__c, Start_DateCS__c, Sales_Organization__c,
                                   DurationInMin__c, Role_Id__c, Date_Time_Closed__c, Owner.Name, What.Name,
                                   Who.Name, Operational_Tasks__r.Name, Campaign__r.Name, Contact__r.Name
                            FROM Task 
                            WHERE ID = : otRec.Task_ID__c]; 
            }
           
            
        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        
        return taskRec;
    }
    
    @AuraEnabled
    public static Task saveTask(Task OTrecord) {
        CustomLogging.push('saveTask', 'MirrorTaskRecordDetailController');
        Task taskRec = new Task();
        
        try {
        update OTrecord;
        
            taskRec = [Select Id, OwnerId, Subject, Updated_by_Trigger__c, Operational_Tasks__c,
                                   ActivityDate, WhoId, WhatId, Priority, Type, Status,
                                   Description, Task_Source__c, Campaign__c, Contact__c, 
                                   Reason__c, Start_DateCS__c, Sales_Organization__c,
                                   DurationInMin__c, Role_Id__c, Date_Time_Closed__c, Owner.Name, What.Name,
                                   Who.Name, Operational_Tasks__r.Name, Campaign__r.Name, Contact__r.Name
                            FROM Task 
                            WHERE ID = : OTrecord.Id];
            
            System.debug('OTrecord: ' + OTrecord);
                
        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }

        return taskRec;
        
    }
}