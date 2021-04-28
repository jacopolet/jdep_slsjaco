/*************************************************************
@Name: APTS_cerCachcleanJobSchedulerTest
@Author: Shahul
@CreateDate: 22-12-2020
@Description: Test class for APTS_cerCachcleanJobScheduler class
@UsedBy: APTS_cerCachcleanJobScheduler
**************************************************************/
@isTest
private class APTS_cerCachcleanJobSchedulerTest{

    @isTest
    static void testStagingScheduler(){
        String batchSchedule = '0 0 0 1 1 ? 2050';
        APTS_cerCachcleanJobScheduler schedulerClass = new APTS_cerCachcleanJobScheduler ();

        test.startTest();
        String jobId = System.Schedule('Staging Job', batchSchedule, schedulerClass);
        test.stopTest();
        
        CronTrigger cronTgr = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id =: jobId];
        System.assertEquals(batchSchedule, cronTgr.CronExpression);
        System.assertEquals(0, cronTgr.TimesTriggered);
        System.assertEquals('2050-01-01 00:00:00', String.valueOf(cronTgr.NextFireTime));
    }
}