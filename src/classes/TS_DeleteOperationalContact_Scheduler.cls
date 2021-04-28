/**
 * @author        Francis Allen Alindogan
 * @date          November 16, 2020
 * @description   Apex scheduler class used to delete operational contact with an incativity on cases
 * @revision(s)
 */
global with sharing class TS_DeleteOperationalContact_Scheduler implements Schedulable{
    
    public class TS_DeleteOperationalContact_SchedulerException extends Exception {}
    
    public static Boolean hasException = false;
    public Integer addedDay;
           
    global void execute(SchedulableContext SC) {
		CustomLogging.push('execute', 'TS_DeleteOperationalContact_Scheduler');
        try {
     
            if (Test.isRunningTest() && hasException) {
                throw new TS_DeleteOperationalContact_SchedulerException('Force to throw an exception');
            }

            //CHECK IF THE BATCH JOB IS STILL RUNNING
            List<AsyncApexJob> mcBatchJobs = [SELECT Id, ApexClassID 
                                              FROM AsyncApexJob 
                                              WHERE Status IN ('Processing', 'Preparing') 
                                              AND ApexClassId IN (SELECT Id FROM ApexClass WHERE Name = 'TS_DeleteOperationalContact_Batch') ];
            
            //COUNT THE PROCESSING JOBS AND THOSE IN QUEUE
            Integer batchCount_ProcessingPreparing = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Processing\', \'Preparing\')');
            Integer batchCount_HoldingQueued = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Queued\', \'Holding\')');
            
            if (batchCount_ProcessingPreparing < 5 && batchCount_HoldingQueued < 100 && (mcBatchJobs == null || mcBatchJobs.size() == 0) && !Test.isRunningTest()) { 
                Database.executeBatch(new TS_DeleteOperationalContact_Batch(0), Integer.valueOf(Label.TS_DeleteOperationalContactBatchSize));
                
            } else {
                //EXECUTE THIS SCHEDULER AGAIN IN NTH MINS.
                TS_DeleteOperationalContact_Scheduler schedClass = new TS_DeleteOperationalContact_Scheduler();
                Datetime dt = Datetime.now().addMinutes(10);
               	String timeForScheduler = dt.format('s m H d M \'?\' yyyy');
                System.schedule('TS_DeleteOperationalContact_Batch Retry ' + timeForScheduler, timeForScheduler, schedClass);
            }                    

        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
        }
    }

}