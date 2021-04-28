/*************************************************************
@Name: APTS_RSOOrderSchedulerTest
@Author: Neev Shah
@CreateDate: 14-08-2018
@Description: Batch scheduler test
******************************************************************/
@isTest
private class APTS_DigitalOrderSchedulerTest {
	
	@isTest static void test_method_one() {
		Test.startTest();
		String sch = '0 15 * * * ?';
		String jobId = System.schedule('DigitalJob30MinTest', '0 15 * * * ?', new APTS_DigitalOrderScheduler());
		System.assertNotEquals(NULL, jobId);

		// Get the information from the CronTrigger API object
		CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
		// Verify the job has not run
		System.assertEquals(0, ct.TimesTriggered);

		// Verify the next time the job will run
		Datetime dtNow = ct.NextFireTime;
		String min = dtNow.format('mm');
		System.assertEquals('15', min);
		Test.stopTest();
	}
}