global without sharing class APTS_ActivateOrdersScheduler implements Schedulable {
        global void execute(SchedulableContext sc) {
            List<AsyncApexJob> listActivateOrderBatch = [SELECT id, ApexClass.name, Status FROM AsyncApexJob WHERE ApexClass.name IN ('APTS_ActivateOrdersBatch') AND Status NOT IN ('Completed', 'Failed', 'Aborted') ORDER BY CreatedDate DESC];
            //if no batch are there than schedule another one
            if (listActivateOrderBatch.isEmpty()) {
                APTS_ActivateOrdersBatch oActivateOrdersBatch = new APTS_ActivateOrdersBatch();
                database.executebatch(oActivateOrdersBatch, 1);
            }
        }
    }