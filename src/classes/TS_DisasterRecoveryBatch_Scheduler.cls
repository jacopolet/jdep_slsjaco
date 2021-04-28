/*
* @author        Karen Hung
* @date          1.16.19       
* @description   Class responsible for scheduling TS_DisasterRecoveryBatch
* @revision(s)
*/
global with sharing class TS_DisasterRecoveryBatch_Scheduler implements Schedulable {
    public static Boolean hasException = false;
    
    /******************************************************************************
    * @author         Karen Hung
    * @date           1.16.19
    * @description    Method responsible for throwing an exception
    * @revision(s)
    ******************************************************************************/ 
    public class TS_SchedulerException extends Exception {

    }
    
    /******************************************************************************
    * @author         Karen Hung
    * @date           1.16.19
    * @description    Method responsible executing the main logic
    * @revision(s)
    ******************************************************************************/ 
    global void execute(SchedulableContext SC) {
        CustomLogging.push('execute', 'TS_DisasterRecoveryBatch_Scheduler');
        
        try {

            if (Test.isRunningTest() && hasException) {
                throw new TS_SchedulerException('Force to throw an exception');
            }

           //CHECK IF THE ROUTESALES JOB IS STILL RUNNING
            List<AsyncApexJob> disasterRecBatchJobs = [SELECT Id, ApexClassID 
                                                FROM AsyncApexJob 
                                                WHERE Status IN ('Processing', 'Preparing') 
                                                AND ApexClassId IN (SELECT Id FROM ApexClass WHERE Name = 'TS_DisasterRecoveryBatch') ];
            
           //COUNT THE PROCESSING JOBS AND THOSE IN QUEUE
            Integer batchCount_ProcessingPreparing = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Processing\', \'Preparing\')');
            Integer batchCount_HoldingQueued = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Queued\', \'Holding\')');

            if (batchCount_ProcessingPreparing < 5 && batchCount_HoldingQueued < 100 && (disasterRecBatchJobs == null || disasterRecBatchJobs.size() == 0) && !Test.isRunningTest()) { 
               Database.executeBatch(new TS_DisasterRecoveryBatch(), 40);

            } else {
               //EXECUTE THIS SCHEDULER AGAIN IN NTH MINS.
               TS_DisasterRecoveryBatch_Scheduler schedClass = new TS_DisasterRecoveryBatch_Scheduler();
               Datetime dt = Datetime.now().addMinutes(10);
               String timeForScheduler = dt.format('s m H d M \'?\' yyyy');
               System.schedule('Disaster Recovery Job Retry ' + timeForScheduler, timeForScheduler, schedClass);
            }

        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
        }
    }

}