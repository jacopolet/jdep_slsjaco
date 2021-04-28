@isTest
private class SM_FlagforDeletionSchedulerTest {

	static testMethod void testSM_FlagforDeletionScheduler(){  
        Test.startTest();
           String jobId = System.schedule('SM_FlagforDeletionScheduler', '0 0 4 * * ?', new SM_FlagforDeletionScheduler());
        Test.stopTest();
        
        List<CronTrigger> cronJob = [select Id, cronExpression, TimesTriggered, NextFireTime from CronTrigger where (Id = :jobId)];
        
        if(!cronJob.isEmpty()){
            CronTrigger schedJob = cronJob.get(0);
            system.assert(schedJob.CronExpression.equals('0 0 4 * * ?'));
            system.assert(schedJob.TimesTriggered == 0);
            system.assert(schedJob.NextFireTime.hour() == 4);
        }
    }
    
    static testMethod void testErrorSM_FlagforDeletionSchedulerTest(){
      SM_FlagforDeletionScheduler.hasException = true;
      System.schedule('SM_FlagforDeletionScheduler', '0 0 4 * * ?', new SM_FlagforDeletionScheduler());  
      System.assert(SM_FlagforDeletionScheduler.hasException = true);
    }   

}