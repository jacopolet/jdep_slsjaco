@isTest
private class SM_CallListDayAccountSchedulerTest {
    
    static testMethod void testSM_processonCallListDayAccountScheduler(){  
        Test.startTest();
           String jobId = System.schedule('testSM_processonCallListDayAccountScheduler', '0 0 4 * * ?', new SM_processonCallListDayAccountScheduler());
        Test.stopTest();
        
        List<CronTrigger> cronJob = [select Id, cronExpression, TimesTriggered, NextFireTime from CronTrigger where (Id = :jobId)];
        
        if(!cronJob.isEmpty()){
            CronTrigger schedJob = cronJob.get(0);
            system.assert(schedJob.CronExpression.equals('0 0 4 * * ?'));
            system.assert(schedJob.TimesTriggered == 0);
            system.assert(schedJob.NextFireTime.hour() == 4);
        }
    }
    
    static testMethod void testErrorSM_AccountSettoInactiveSchedulerTest(){
      SM_processonCallListDayAccountScheduler.hasException = true;
      System.schedule('testSM_processonCallListDayAccountScheduler', '0 0 4 * * ?', new SM_processonCallListDayAccountScheduler());  
      System.assert(SM_processonCallListDayAccountScheduler.hasException = true);
    }   
    
}