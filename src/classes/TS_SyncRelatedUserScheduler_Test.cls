/**
* @author        Paul Jarred Aguiling
* @date          07.12.2018          
* @description   Test class for TS_SyncRelatedUserScheduler
* @revision(s)
*/
@isTest
public with sharing class TS_SyncRelatedUserScheduler_Test {

    static testMethod void testSyncRelatedUserScheduler(){   
        Test.startTest();
            String jobId = System.schedule('testSyncRelatedUserScheduler', '0 0 4 * * ?', new TS_SyncRelatedUserScheduler());
        Test.stopTest();
        
        List<CronTrigger> cronJob = [select Id, cronExpression, TimesTriggered, NextFireTime from CronTrigger where (Id = :jobId)];
        
        if(!cronJob.isEmpty()){

            CronTrigger schedJob = cronJob.get(0);
            system.assert(schedJob.CronExpression.equals('0 0 4 * * ?'));
            system.assert(schedJob.TimesTriggered == 0);
            system.assert(schedJob.NextFireTime.hour() == 4);
        }   
    }
    
    static testMethod void testErrorSyncRelatedUserScheduler(){
        TS_SyncRelatedUserScheduler.hasException = true;
        System.schedule('testSyncRelatedUserScheduler', '0 0 4 * * ?', new TS_SyncRelatedUserScheduler());

        System.assert(TS_SyncRelatedUserScheduler.hasException == true);
    } 
}