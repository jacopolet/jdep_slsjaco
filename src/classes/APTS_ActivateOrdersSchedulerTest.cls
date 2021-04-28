@isTest
public class APTS_ActivateOrdersSchedulerTest {

    @IsTest static void testController() { 
        Test.startTest();
        String sch = '0 15 * * * ?';
        String jobId = System.schedule('ActivateJob30MinTest', '0 15 * * * ?', new APTS_ActivateOrdersScheduler());
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