/*************************************************************
@Name: APTS_AmendPartialOrderSchedulerTest
@Author: Rajesh Patel
@CreateDate: 11-09-2019
@Description: Batch scheduler test
@UsedBy:Test class for APTS_AmendPartialOrderScheduler 
******************************************************************/
@isTest
private class APTS_AmendPartialOrderSchedulerTest{
  
  @isTest static void amndPartialScheduler() {
    Test.startTest();
    String jobId = System.schedule('AmendPartialOrderTest', '00 45 * * * ?', new APTS_AmendPartialOrderScheduler());
    System.assertNotEquals(NULL, jobId);

    // Get the information from the CronTrigger API object
    CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
    // Verify the job has not run
    System.assertEquals(0, ct.TimesTriggered);

    // Verify the next time the job will run
    Datetime dtNow = ct.NextFireTime;
    String min = dtNow.format('mm');
    System.assertEquals('45', min);
    Test.stopTest();
  }
}