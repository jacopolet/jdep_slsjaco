/*
* @author        Paul Jarred Aguiling
* @date          6.14.2017          
* @description   Class responsible for executing PrevMaintenanceConTriggerBatch
* @revision(s)
*/
global with sharing class PrevMaintenanceConTriggerScheduler implements Schedulable {

    public static Boolean hasException = false;

    /******************************************************************************
    * @author         Paul Jarred Aguiling
    * @date           6.14.2017
    * @description    Method responsible for throwing an exception
    * @revision(s)
    ******************************************************************************/ 
    public class TS_SchedulerException extends Exception {

    }

    /******************************************************************************
    * @author         Paul Jarred Aguiling
    * @date           6.14.2017
    * @description    Method responsible executing the main logic
    * @revision(s)
    ******************************************************************************/ 
    global void execute(SchedulableContext SC) {
        CustomLogging.push('execute', 'PrevMaintenanceConTriggerScheduler');
        
        try {

            if (Test.isRunningTest() && hasException) {
                throw new TS_SchedulerException('Force to throw an exception');
            }

           //CHECK IF THE ROUTESALES JOB IS STILL RUNNING
            List<AsyncApexJob> prevMainBatchJobs = [SELECT Id, ApexClassID 
                                                FROM AsyncApexJob 
                                                WHERE Status IN ('Processing', 'Preparing') 
                                                AND ApexClassId IN (SELECT Id FROM ApexClass WHERE Name = 'PrevMaintenanceConTriggerBatch') ];
            
           //COUNT THE PROCESSING JOBS AND THOSE IN QUEUE
            Integer batchCount_ProcessingPreparing = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Processing\', \'Preparing\')');
            Integer batchCount_HoldingQueued = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Queued\', \'Holding\')');

            if (batchCount_ProcessingPreparing < 5 && batchCount_HoldingQueued < 100 && (prevMainBatchJobs == null || prevMainBatchJobs.size() == 0) && !Test.isRunningTest()) { 
               Database.executeBatch(new PrevMaintenanceConTriggerBatch(), 40);

            } else {
               //EXECUTE THIS SCHEDULER AGAIN IN NTH MINS.
               PrevMaintenanceConTriggerScheduler schedClass = new PrevMaintenanceConTriggerScheduler();
               Datetime dt = Datetime.now().addMinutes(10);
               String timeForScheduler = dt.format('s m H d M \'?\' yyyy');
               System.schedule('Prev Maintenance Job Retry ' + timeForScheduler, timeForScheduler, schedClass);
            }

        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
        }
    }

}