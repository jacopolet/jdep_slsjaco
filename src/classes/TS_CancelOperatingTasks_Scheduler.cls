/**
* @author        Karen Hung
* @date          27.Nov.2018
* @description   Apex class used to schedule TS_CancelOperatingTasks_Batch
* @revision(s)   
*                
*/
global with sharing class TS_CancelOperatingTasks_Scheduler implements schedulable{
    
    public static Boolean hasException = false;
    
    public class TS_CancelOperatingTasks_SchedulerException extends Exception {}
    
    /*execution of batch*/
    global void execute(SchedulableContext SC) {
		CustomLogging.push('execute', 'TS_CancelOperatingTasks_Scheduler');

        try {

            if (Test.isRunningTest() && hasException) {
                throw new TS_CancelOperatingTasks_SchedulerException('Force to throw an exception');
            }

            //CHECK IF THE ROUTESALES JOB IS STILL RUNNING
            List<AsyncApexJob> cancelBatchJobs = [SELECT Id, ApexClassID 
                                                FROM AsyncApexJob 
                                                WHERE Status IN ('Processing', 'Preparing') 
                                                AND ApexClassId IN (SELECT Id FROM ApexClass WHERE Name = 'TS_CancelOperatingTasks_Batch') ];
            
            //COUNT THE PROCESSING JOBS AND THOSE IN QUEUE
            Integer batchCount_ProcessingPreparing = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Processing\', \'Preparing\')');
            Integer batchCount_HoldingQueued = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Queued\', \'Holding\')');

            if (batchCount_ProcessingPreparing < 5 && batchCount_HoldingQueued < 100 && (cancelBatchJobs == null || cancelBatchJobs.size() == 0) && !Test.isRunningTest()) { 
               Database.executeBatch(new TS_CancelOperatingTasks_Batch(), 40);

            } else {
               //EXECUTE THIS SCHEDULER AGAIN IN NTH MINS.
               TS_CancelOperatingTasks_Scheduler schedClass = new TS_CancelOperatingTasks_Scheduler();
               Datetime dt = Datetime.now().addMinutes(10);
               String timeForScheduler = dt.format('s m H d M \'?\' yyyy');
               System.schedule('Cancel Job Retry ' + timeForScheduler, timeForScheduler, schedClass);
            }

        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
        }
    }

}