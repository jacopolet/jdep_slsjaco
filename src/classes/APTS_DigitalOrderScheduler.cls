/*************************************************************
@Name: APTS_DigitalOrderScheduler
@Author: Neev Shah
@CreateDate: 14-08-2018
@Description: Batch scheduler for Digital/EPI Order. Frequency - every hour.
******************************************************************/
global without sharing class APTS_DigitalOrderScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        //Query if any batch job is in Progress or on hold
        List<AsyncApexJob> listDigitalOrderBatch = [SELECT id, ApexClass.name, Status FROM AsyncApexJob WHERE ApexClass.name IN ('APTS_DigitalOrderBatch', 'CriteriaUpdateJob') AND Status NOT IN ('Completed', 'Failed', 'Aborted') ORDER BY CreatedDate DESC];

        //if no batch are there than schedule another one
        if (listDigitalOrderBatch.isEmpty()) {
            APTS_DigitalOrderBatch b = new APTS_DigitalOrderBatch();
            database.executebatch(b, 1);
        }

    }
}