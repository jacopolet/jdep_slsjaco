/*************************************************************
@Name: APTS_RSOOrderScheduler
@Author: Neev Shah
@CreateDate: 14-08-2018
@Description: Batch scheduler for RSO Order. Frequency - every 15min.
******************************************************************/
global without sharing class APTS_RSOOrderScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        //Query if any batch job is in Progress or on hold
        List<AsyncApexJob> listRSOOrderBatch = [SELECT id, ApexClass.name, Status FROM AsyncApexJob WHERE ApexClass.name = 'APTS_RSOOrderCreationBatch' AND Status NOT IN ('Completed', 'Failed', 'Aborted') ORDER BY CreatedDate DESC];

        //if no batch are there than schedule another one
        if (listRSOOrderBatch.isEmpty()) {

            APTS_RSOOrderCreationBatch b = new APTS_RSOOrderCreationBatch();
            database.executebatch(b, 1);

        }
    }
}