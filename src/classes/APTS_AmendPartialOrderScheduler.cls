/*****************************************************************
@Name: APTS_AmendPartialOrderScheduler
@Author: Rajesh Patel
@CreateDate: 11-03-2019
@Description: Batch scheduler for Amend-Partial Order.
@UsedBy:APTS_AmendPartialOrderBatch class.
******************************************************************/
//v100 11-03-2019 Rajesh Patel: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes   
    
global without sharing class APTS_AmendPartialOrderScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        //Query if any batch job is in Progress or on hold
        List<AsyncApexJob> listAmndPartialOrderBatch = [SELECT id, ApexClass.name, Status FROM AsyncApexJob WHERE ApexClass.name = 'APTS_AmendPartialOrderBatch' AND Status NOT IN ('Completed', 'Failed', 'Aborted') ORDER BY CreatedDate DESC];

        //Shedule new batch if no batch job is pending.
        if (listAmndPartialOrderBatch.isEmpty()) {

            APTS_AmendPartialOrderBatch amdPartialOrder = new APTS_AmendPartialOrderBatch();
            database.executebatch(amdPartialOrder, 1);

        }
    }
}