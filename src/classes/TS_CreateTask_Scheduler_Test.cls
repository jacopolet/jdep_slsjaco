/*
* @author        Karen Hung
* @date          6.Sep.2018          
* @description   Test class for TS_CreateTask_Scheduler
* @revision(s)
*/
@isTest
public with sharing class TS_CreateTask_Scheduler_Test {
    
    /*test with no exception*/
    private static testMethod void TriggerSchedule() {
        Test.startTest();
        
        Datetime currentDate = System.now();
        Datetime computedDate = currentDate.addMinutes(1);
        
        String day = string.valueOf(computedDate .day());
        String month = string.valueOf(computedDate .month());
        String hour = string.valueOf(computedDate .hour());
        String minute = string.valueOf(computedDate .minute()); 
        String second = string.valueOf(computedDate .second());
        String year = string.valueOf(computedDate .year());
        String strSchedule = second + ' ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ?' + ' ' + year;
        
        TS_CreateTask_Scheduler createTaskSched = new TS_CreateTask_Scheduler();       
        String jobID = System.schedule('Create Task Scheduler Test Class:', strSchedule, createTaskSched);
        
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
                          FROM CronTrigger WHERE id = :jobId];
        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);
        
        Test.stopTest();
        
    }
    
    /*test with exception*/   
     private static testMethod void TriggerScheduleEx() {
        Test.startTest();
        
        Datetime currentDate = System.now();
        Datetime computedDate = currentDate.addMinutes(1);
        
        String day = string.valueOf(computedDate .day());
        String month = string.valueOf(computedDate .month());
        String hour = string.valueOf(computedDate .hour());
        String minute = string.valueOf(computedDate .minute()); 
        String second = string.valueOf(computedDate .second());
        String year = string.valueOf(computedDate .year());
        String strSchedule = second + ' ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ?' + ' ' + year;
        
        TS_CreateTask_Scheduler createTaskSched = new TS_CreateTask_Scheduler(); 
        TS_CreateTask_Scheduler.hasException =  true;
        String jobID = System.schedule('Create Task Scheduler Test Class:', strSchedule, createTaskSched);
        
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
                          FROM CronTrigger WHERE id = :jobId];
        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);
        
        Test.stopTest();
        
    }
    
}