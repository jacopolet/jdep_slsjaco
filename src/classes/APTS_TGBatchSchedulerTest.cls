/**********************************************************************************
 * @Author: Shahul
 * @Company: Accenture
 * @Description: Scheduler to run the TGBtach jobs on weekly batches
 * @Created Date: Jan 24, 2019
 * @History:
 *      <Name>              <Date>          <Description>
 *      Shahul          01.24.2019       Created
 **********************************************************************************/
 @isTest
private class APTS_TGBatchSchedulerTest{
    
    static String schedule = '0 0 0 1 1 ? 2052';
    
    /**Method Name : testScheduler
    * Description : Method to test scheduler 
    **/
    static testMethod void testScheduler(){
        APTS_TGBatchScheduler schedulerClass = new APTS_TGBatchScheduler();
        test.startTest();
        String jobId = System.Schedule('Test TGScheduler', schedule, schedulerClass);
        test.stopTest();
        
        CronTrigger cronTgr = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id =: jobId];
        System.assertEquals(schedule, cronTgr.CronExpression);
        System.assertEquals(0, cronTgr.TimesTriggered);
        System.assertEquals('2052-01-01 00:00:00', String.valueOf(cronTgr.NextFireTime));
    }

}