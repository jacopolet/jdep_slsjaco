/**
* Class Name : APTS_RecurringBillingBatchScheduler_Test
* Description : Apex Class to test APTS_RecurringBillingBatchScheduler Class
* Author : Balashanthi (b.arigopalan@accenture.com)
* Date Created : 09-05-2018
**/
@isTest
private class APTS_RecurringBillingBatchScheduler_Test{
    
    private static String status = 'RECURRING BATCH';
    static String schedule = '0 0 0 1 1 ? 2050';
   
    /**Method Name : testScheduler
    * Description : Method to test APTS_DeleteFireAndForgetBatch_Scheduler scheduler
    **/
    @isTest
    static void testScheduler(){
        APTS_RecurringBillingBatchScheduler schedulerClass = new APTS_RecurringBillingBatchScheduler();
        //Insert custom setting 
        List<APTS_Recurring_Batch_Countries__c> rcbList= new List<APTS_Recurring_Batch_Countries__c>();
        APTS_Recurring_Batch_Countries__c rcb1 = new APTS_Recurring_Batch_Countries__c(name='test1',APTS_Sales_Org__c='SAP_0111',APTS_Sequence__c=1);
        rcbList.add(rcb1);
        APTS_Recurring_Batch_Countries__c rcb2 = new APTS_Recurring_Batch_Countries__c(name='test2',APTS_Sales_Org__c='SAP2',APTS_Sequence__c=2);
        rcbList.add(rcb2);
        APTS_Recurring_Batch_Countries__c rcb3 = new APTS_Recurring_Batch_Countries__c(name='test3',APTS_Sales_Org__c='SAP3',APTS_Sequence__c=3);
        rcbList.add(rcb3);
        insert rcbList;

        test.startTest();
        String jobId = System.Schedule(status, schedule, schedulerClass);
        test.stopTest();
        
        CronTrigger cronTgr = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id =: jobId];
        System.assertEquals(schedule, cronTgr.CronExpression);
        System.assertEquals(0, cronTgr.TimesTriggered);
        System.assertEquals('2050-01-01 00:00:00', String.valueOf(cronTgr.NextFireTime));
    }
    
}