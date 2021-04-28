/*************************************************************
@Name: APTS_SubscriptionBatchScheduler
@Author: Neev Shah
@CreateDate: 21-03-2018
@Description: Scheduler class to schedule Subscription Batch
******************************************************************/
global without sharing class APTS_SubscriptionBatchScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new APTS_SubscriptionOrderBatch(), 30);
    }
}