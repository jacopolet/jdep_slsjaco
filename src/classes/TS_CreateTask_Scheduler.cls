/**
* @author        Karen Hung
* @date          5.Sep.2018
* @description   Apex class used to schedule Operating tasks for operating schedule with weekly schedule type
* @revision(s)   Karen Hung 3/4/2019 adjust rundate, batch to be run on saturday but need to make it seem run on a sunday
*                
*/
global with sharing class TS_CreateTask_Scheduler implements schedulable{
    
  public static Boolean hasException = false;

  public class TS_CreateTask_SchedulerException extends Exception { }
      
  /*execution*/
  global void execute(SchedulableContext SC) {
    CustomLogging.push('execute', 'TS_CreateTask_Scheduler');
    
    TS_CreateTask_Batch weeklyOperatingBatch = new TS_CreateTask_Batch(null);
    
    try {

        if (Test.isRunningTest() && hasException) {
            throw new TS_CreateTask_SchedulerException('Force to throw an exception');
        }

        //CHECK IF THE ROUTESALES JOB IS STILL RUNNING
        List<AsyncApexJob> createTaskBatchJobs = [SELECT Id, ApexClassID 
                                            FROM AsyncApexJob 
                                            WHERE Status IN ('Processing', 'Preparing') 
                                            AND ApexClassId IN (SELECT Id FROM ApexClass WHERE Name = 'TS_CreateTask_Batch') ];
        
        //COUNT THE PROCESSING JOBS AND THOSE IN QUEUE
        Integer batchCount_ProcessingPreparing = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Processing\', \'Preparing\')');
        Integer batchCount_HoldingQueued = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Queued\', \'Holding\')');

        if ((batchCount_ProcessingPreparing < 5 || batchCount_HoldingQueued < 100) && (createTaskBatchJobs == null || createTaskBatchJobs.size() == 0) && !Test.isRunningTest()) { 
           Database.executeBatch(weeklyOperatingBatch, 40);

        } else {
           //EXECUTE THIS SCHEDULER AGAIN IN NTH MINS.
           //Karen Hung KTS-2666 3.18.19 removed parameter of scheduler
           TS_CreateTask_Scheduler schedClass = new TS_CreateTask_Scheduler();
           Datetime dt = DateTime.now().addMinutes(10); 
           String timeForScheduler = dt.format('s m H d M \'?\' yyyy');
           System.schedule('Create Tasks Job Retry ' + timeForScheduler, timeForScheduler, schedClass);
        }

    } catch (Exception ex) {
        CustomLogging.debugException(ex);
        CustomLogging.pop();
    }
  }
}