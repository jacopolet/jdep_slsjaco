/*
* @author        Karen Hung
* @date          1.16.19       
* @description   Test class for TS_DisasterRecoveryBatch_Scheduler
* @revision(s)
*/
@isTest
private class TS_DisasterRecoveryBatch_Scheduler_Test {
 
 /*no exception test*/
 static testMethod void testDisasterScheduler(){   
        Test.startTest();
        String jobId = System.schedule('testDisasterScheduler', '0 0 4 * * ?', new TS_DisasterRecoveryBatch_Scheduler());
        Test.stopTest();
        
        List<CronTrigger> cronJob = [select Id, cronExpression, TimesTriggered, NextFireTime from CronTrigger where (Id = :jobId)];
        
        if(!cronJob.isEmpty()){
            
            CronTrigger schedJob = cronJob.get(0);
            system.assert(schedJob.CronExpression.equals('0 0 4 * * ?'));
            system.assert(schedJob.TimesTriggered == 0);
            system.assert(schedJob.NextFireTime.hour() == 4);
        }   
    } 
   
    /*with exception test*/
    static testMethod void testErrorDisasterScheduler(){
        TS_DisasterRecoveryBatch_Scheduler.hasException = true;
        System.schedule('testErrorDisasterScheduler', '0 0 4 * * ?', new TS_DisasterRecoveryBatch_Scheduler());
        
        System.assert(TS_DisasterRecoveryBatch_Scheduler.hasException == true);
    } 
}