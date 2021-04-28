//-------------------------------------------------------------------------------------------//
// Author       :   Glenn Serrano - Accenture
// Created Date :   July 29 2020
// Usage        :   Apex Action Test Class
//
//-------------------------------------------------------------------------------------------//
@isTest
public class SM_ActionFlow_Test {
    private static testMethod void actionflowTest() {
        Test.startTest();
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Task tasks = new Task();
        tasks.Touchpoint_Type__c = 'CAMPAIGN';
        tasks.ActivityDate = System.today();
        tasks.Task_Source__c = 'SFDC';
        tasks.Subject = 'OVERWRITE';
        tasks.RecordTypeId = recordTypeId;

        insert tasks;
        List<String> placeinput = new List<String>();
        placeinput.add(tasks.Id);
        List<List<String>> taskreclist = new List<List<String>>();
        taskreclist.add(placeinput);
        List<List<Task>> result = new List<List<Task>>();
        result = SM_ActiononFlow.getSelectedTask(taskreclist);
        Test.stopTest();
        System.assert(result != null);
    }
}