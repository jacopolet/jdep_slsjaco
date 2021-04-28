public without sharing class SM_TaskHistoryRecord {
    @AuraEnabled(cacheable=true)
    public static List<Task_History__c> getTaskHistory(Id taskId){
        return [SELECT Name, Task_Name__c, Status__c, Touchpoint_Type__c, Owner.Name, Valid_From__c, Valid_To__c,Task_Source__c, Type__c  FROM Task_History__c WHERE Task_ID__c = :taskId ORDER BY Valid_To__c DESC];
    }
}