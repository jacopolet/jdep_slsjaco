/**
* @author        Karen Hung
* @date          27.Nov.2018
* @description   Test class used for  TS_CancelOperatingTasks_Scheduler
* @revision(s)   
*                
*/
@isTest
private class TS_CancelOperatingTasks_Scheduler_Test {
    
    /*test scheduler*/
    static testMethod void testCancelTaskScheduler(){   
        Test.startTest();
            String jobId = System.schedule('testCancelTaskScheduler', '0 0 4 * * ?', new TS_CancelOperatingTasks_Scheduler());
        Test.stopTest();
        
        List<CronTrigger> cronJob = [select Id, cronExpression, TimesTriggered, NextFireTime from CronTrigger where (Id = :jobId)];
        
        if(!cronJob.isEmpty()){

            CronTrigger schedJob = cronJob.get(0);
            system.assert(schedJob.CronExpression.equals('0 0 4 * * ?'));
            system.assert(schedJob.TimesTriggered == 0);
            system.assert(schedJob.NextFireTime.hour() == 4);
        }   
    }
    
    /*test scheduler with error*/
    static testMethod void testErrorCancelTaskScheduler(){
        TS_CancelOperatingTasks_Scheduler.hasException = true;
        System.schedule('testCancelTaskScheduler', '0 0 4 * * ?', new TS_CancelOperatingTasks_Scheduler());

        System.assert(TS_CancelOperatingTasks_Scheduler.hasException == true);
    } 

}