/*
* @author        Karen Hung
* @date          1.16.19       
* @description   Test class for CaseModificationBatch_Scheduler
* @revision(s)
*/
@isTest
private class CaseModificationBatch_Scheduler_Test {
    
    static List<Case> caseList;
    static List<Id> accountIds;
    static List<Id> accLocIds;
    static List<Id> productIds;
    
    static testMethod void testCaseModificationScheduler(){   
        Test.startTest();
        String jobId = System.schedule('testCaseModificationScheduler', '0 0 4 * * ?', new CaseModificationBatch_Scheduler(caseList,accountIds,accLocIds,productIds));
        Test.stopTest();
        
        List<CronTrigger> cronJob = [select Id, cronExpression, TimesTriggered, NextFireTime from CronTrigger where (Id = :jobId)];
        
        if(!cronJob.isEmpty()){
            
            CronTrigger schedJob = cronJob.get(0);
            system.assert(schedJob.CronExpression.equals('0 0 4 * * ?'));
            system.assert(schedJob.TimesTriggered == 0);
            system.assert(schedJob.NextFireTime.hour() == 4);
        }   
    }
    
    static testMethod void testErrorCaseModificationScheduler(){
        CaseModificationBatch_Scheduler.hasException = true;
        System.schedule('testErrorCaseModificationScheduler', '0 0 4 * * ?', new CaseModificationBatch_Scheduler(caseList,accountIds,accLocIds,productIds));
        
        System.assert(CaseModificationBatch_Scheduler.hasException == true);
    } 

}