@isTest
public class APTS_scheduleAllBizIslandBatchesTest
{

    static testmethod void schedulerTest() 
    {
    
     Test.startTest();
       Bonsai__c customSetting = new Bonsai__c();
        customSetting.Name = 'test';
        customSetting.Delta_Load__c = true;
        customSetting.Full_Load__c = true;
        insert customSetting;
        String CRON_EXP = '0 0 0 15 3 ? *';
       

            String jobId = System.schedule('APTS_scheduleAllBizIslandBatches',CRON_EXP,new APTS_scheduleAllBizIslandBatches());
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
            System.assertEquals(CRON_EXP, ct.CronExpression);
            System.assertEquals(0, ct.TimesTriggered);

        Test.stopTest();
        
    }
}