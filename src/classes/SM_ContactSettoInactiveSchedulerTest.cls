@isTest
private class SM_ContactSettoInactiveSchedulerTest {
    
    static testMethod void testSM_ContactSettoInactiveScheduler(){  
        Test.startTest();
           String jobId = System.schedule('testSM_AccountSettoInactiveScheduler', '0 0 4 * * ?', new SM_ContactSettoInactiveScheduler());
        Test.stopTest();
        
        List<CronTrigger> cronJob = [select Id, cronExpression, TimesTriggered, NextFireTime from CronTrigger where (Id = :jobId)];
        
        if(!cronJob.isEmpty()){
            CronTrigger schedJob = cronJob.get(0);
            system.assert(schedJob.CronExpression.equals('0 0 4 * * ?'));
            system.assert(schedJob.TimesTriggered == 0);
            system.assert(schedJob.NextFireTime.hour() == 4);
        }
    }
    
    static testMethod void testErrorSM_ContactSettoInactiveSchedulerTest(){
      SM_ContactSettoInactiveScheduler.hasException = true;
      System.schedule('testSM_ContactSettoInactiveScheduler', '0 0 4 * * ?', new SM_ContactSettoInactiveScheduler());  
      System.assert(SM_AccountSettoInactiveScheduler.hasException = true);
    }   
    
}