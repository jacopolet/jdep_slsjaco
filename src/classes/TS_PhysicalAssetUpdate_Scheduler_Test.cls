/*
* @author        Karen Hung
* @date          6.Sep.2018          
* @description   Test class for TS_CreateTask_Scheduler
* @revision(s)
*/
@isTest
private with sharing class TS_PhysicalAssetUpdate_Scheduler_Test {

	/*test the scheduler*/
	private static testMethod void TriggerSchedule() {
		
		String cron = '0 0 13 * * ?';
		
		Test.startTest();
        TS_PhysicalAssetUpdate_Scheduler updatePASched = new TS_PhysicalAssetUpdate_Scheduler(Date.today());
        String jobID = System.schedule('Update Physical Asset Scheduler Test Class:', cron, updatePASched);

        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
                          FROM CronTrigger WHERE id = :jobId];
        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);
		Test.stopTest();
	}
    
    /*test the scheduler with exception*/
	private static testMethod void TriggerScheduleEx() {
		
		String cron = '0 0 13 * * ?';
		
		Test.startTest();
        TS_PhysicalAssetUpdate_Scheduler.hasException = true;
        TS_PhysicalAssetUpdate_Scheduler updatePASched = new TS_PhysicalAssetUpdate_Scheduler(Date.today());
        String jobID = System.schedule('Update Physical Asset Scheduler Test Class:', cron, updatePASched);

        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
                          FROM CronTrigger WHERE id = :jobId];
        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);
		Test.stopTest();
	}
}