/**
* Class Name : APTS_PricingDistBatch_Scheduler_Test
* Description :  Apex Class to test APTS_PricingDistributionBatch_Scheduler Class
* Author : Nagavi Babu (nagavi.babu@accenture.com)
* Date Created : 04/02/2018
**/
@isTest
private class APTS_PricingDistBatch_Scheduler_Test{
    
    static String schedule = '0 0 0 1 1 ? 2052';
    
    /**Method Name : testScheduler
    * Description : Method to test scheduler 
    **/
    static testMethod void testScheduler(){
        APTS_PricingDistributionBatch_Scheduler schedulerClass = new APTS_PricingDistributionBatch_Scheduler();
        test.startTest();
        String jobId = System.Schedule('Test Pricing Scheduler', schedule, schedulerClass);
        test.stopTest();
        
        CronTrigger cronTgr = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id =: jobId];
        System.assertEquals(schedule, cronTgr.CronExpression);
        System.assertEquals(0, cronTgr.TimesTriggered);
        System.assertEquals('2052-01-01 00:00:00', String.valueOf(cronTgr.NextFireTime));
    }

}