/**
* @author        Harold Marilag
* @date          6.20.2017           
* @description   Test class for PrevMaintenanceConTriggerScheduler
* @revision(s)
*/
@isTest
private class PrevMaintenanceConTriggerSchedulerTest {

    static testMethod void testPrevMaintenanceConTriggerScheduler(){   
        Test.startTest();
            String jobId = System.schedule('testPrevMaintenanceConTriggerScheduler', '0 0 4 * * ?', new PrevMaintenanceConTriggerScheduler());
        Test.stopTest();
        
        List<CronTrigger> cronJob = [select Id, cronExpression, TimesTriggered, NextFireTime from CronTrigger where (Id = :jobId)];
        
        if(!cronJob.isEmpty()){

            CronTrigger schedJob = cronJob.get(0);
            system.assert(schedJob.CronExpression.equals('0 0 4 * * ?'));
            system.assert(schedJob.TimesTriggered == 0);
            system.assert(schedJob.NextFireTime.hour() == 4);
        }   
    }
    
    static testMethod void testErrorPrevMaintenanceConTriggerScheduler(){
        PrevMaintenanceConTriggerScheduler.hasException = true;
        System.schedule('testPrevMaintenanceConTriggerScheduler', '0 0 4 * * ?', new PrevMaintenanceConTriggerScheduler());

        System.assert(PrevMaintenanceConTriggerScheduler.hasException == true);
    } 
}