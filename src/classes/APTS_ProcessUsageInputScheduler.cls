/**
* Class Name : APTS_ProcessUsageInputScheduler  
* Description : Apex Class to schedule APTS_ProcessUsageInputBatch  Class
* Author : Amit Singh

**/
global without sharing class APTS_ProcessUsageInputScheduler implements Schedulable {
  /** Method Name : execute
    * Description : Schedular Class to call APTS_ProcessUsageInputBatch.cls
    **/
    global void execute(SchedulableContext sc) {
        APTS_ProcessUsageInputBatch obj = new APTS_ProcessUsageInputBatch();
        // 28-10-2019 Added scope for Batch job to process with 1 record at time. Apttus rating api is not bulkified.
        Database.executeBatch(obj,1);
    }
}