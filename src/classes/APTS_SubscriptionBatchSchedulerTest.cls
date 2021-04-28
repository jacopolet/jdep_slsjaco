/*************************************************************
@Name: APTS_SubscriptionBatchSchedulerTest
@Author: Neev Shah
@CreateDate: 21-03-2018
@Description: Scheduler test class 
******************************************************************/
@isTest
private class APTS_SubscriptionBatchSchedulerTest {
    
    @isTest static void test_method_one() {
        String sch = '0 0 8 13 2 ?';
        String jobId = System.schedule('testScheduledApex', sch, new APTS_SubscriptionBatchScheduler());
        System.assertNotEquals(NULL, jobId);
        System.assertEquals(TRUE, String.isNotBlank(jobId));
    }
}