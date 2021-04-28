@isTest
public class APTS_scheduledBizIslandBatchableTest
{

    static testmethod void schedulerTest() 
    {
        String CRON_EXP = '0 0 0 15 3 ? *';
        Test.startTest();

            String jobId = System.schedule('APTS_scheduledBizIslandBatchable',CRON_EXP,new APTS_scheduledBizIslandBatchable());
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
            System.assertEquals(CRON_EXP, ct.CronExpression);
            System.assertEquals(0, ct.TimesTriggered);

        Test.stopTest();
        // Add assert here to validate result
    }
}