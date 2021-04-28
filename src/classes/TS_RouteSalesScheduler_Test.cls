/**
* @author        Paul Jarred Aguiling
* @date          04.14.2018          
* @description   Test class for TS_RouteSalesScheduler
* @revision(s)
*/
@isTest
private class TS_RouteSalesScheduler_Test {

    static testMethod void testRouteSalesSchedulerScheduler(){   
        Test.startTest();
            String jobId = System.schedule('testRouteSalesSchedulerScheduler', '0 0 4 * * ?', new TS_RouteSalesScheduler());
        Test.stopTest();
        
        List<CronTrigger> cronJob = [select Id, cronExpression, TimesTriggered, NextFireTime from CronTrigger where (Id = :jobId)];
        
        if(!cronJob.isEmpty()){

            CronTrigger schedJob = cronJob.get(0);
            system.assert(schedJob.CronExpression.equals('0 0 4 * * ?'));
            system.assert(schedJob.TimesTriggered == 0);
            system.assert(schedJob.NextFireTime.hour() == 4);
        }   
    }
    
    static testMethod void testErrorRouteSalesSchedulerScheduler(){
        TS_RouteSalesScheduler.hasException = true;
        System.schedule('testRouteSalesSchedulerScheduler', '0 0 4 * * ?', new TS_RouteSalesScheduler());

        System.assert(TS_RouteSalesScheduler.hasException == true);
    } 
}