/**
* @author        Paul Jarred Aguiling
* @date          07.10.2018          
* @description   [KTS-1932]: Scheduled class that synchronize related user to resource records 
* @revision(s)   
*/
global without sharing class TS_SyncRelatedUserScheduler implements Schedulable {
   public static Boolean hasException = false;

    /**
    * @author         Paul Jarred Aguiling
    * @date           04.14.2018 
    * @description    Method responsible for throwing an exception
    * @revision(s)
    */ 
    public class TS_SyncRelatedUserSchedulerException extends Exception {

    }

    /**
	* @author        Paul Jarred Aguiling
	* @date          07.10.2018 
    * @description    Method responsible executing the main logic
    * @revision(s)
    */ 
    global void execute(SchedulableContext SC) {
        CustomLogging.push('execute', 'TS_SyncRelatedUserScheduler');

        try {

            if (Test.isRunningTest() && hasException) {
                throw new TS_SyncRelatedUserSchedulerException('Force to throw an exception');
            }

            //CHECK IF THE SYNC JOB IS STILL RUNNING
            List<AsyncApexJob> relatedUserSyncBatchJobs = [SELECT Id, ApexClassID 
                                                FROM AsyncApexJob 
                                                WHERE Status IN ('Processing', 'Preparing') 
                                                AND ApexClassId IN (SELECT Id FROM ApexClass WHERE Name = 'TS_SyncRelatedUserBatch') ];
            
            //COUNT THE PROCESSING JOBS AND THOSE IN QUEUE
            Integer batchCount_ProcessingPreparing = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Processing\', \'Preparing\')');
            Integer batchCount_HoldingQueued = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Queued\', \'Holding\')');

            if (batchCount_ProcessingPreparing < 5 && batchCount_HoldingQueued < 100 && (relatedUserSyncBatchJobs == null || relatedUserSyncBatchJobs.size() == 0) && !Test.isRunningTest()) { 
               Database.executeBatch(new TS_SyncRelatedUserBatch(), 40);

            } else {
               //EXECUTE THIS SCHEDULER AGAIN IN NTH MINS.
               TS_SyncRelatedUserScheduler schedClass = new TS_SyncRelatedUserScheduler();
               Datetime dt = Datetime.now().addMinutes(10);
               String timeForScheduler = dt.format('s m H d M \'?\' yyyy');
               System.schedule('Sync related user Job Retry ' + timeForScheduler, timeForScheduler, schedClass);
            }

        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
        }

     }
}