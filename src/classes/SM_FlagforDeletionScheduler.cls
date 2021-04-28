global without sharing class SM_FlagforDeletionScheduler implements Schedulable {
    public static Boolean hasException = false;
    
    public class SM_SchedulerException extends Exception {

    }
    global void execute(SchedulableContext SC) {
        CustomLogging.push('execute', 'SM_FlagforDeletionScheduler');
        
        try {
            //CHECK IF THE ROUTESALES JOB IS STILL RUNNING
            List<AsyncApexJob> flagfordeletionbatchjob = [SELECT Id, ApexClassID 
                                                FROM AsyncApexJob 
                                                WHERE Status IN ('Processing', 'Preparing') 
                                                AND ApexClassId IN (SELECT Id FROM ApexClass WHERE Name = 'SM_FlaggedforDeletionBatch') ];
            
            //COUNT THE PROCESSING JOBS AND THOSE IN QUEUE
            Integer batchCount_ProcessingPreparing = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Processing\', \'Preparing\')');
            Integer batchCount_HoldingQueued = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Queued\', \'Holding\')');

            if (batchCount_ProcessingPreparing < 5 && batchCount_HoldingQueued < 100 && (flagfordeletionbatchjob == null || flagfordeletionbatchjob.size() == 0) && !Test.isRunningTest()) { 
               Database.executeBatch(new SM_FlaggedforDeletionBatch(), 40);

            } else {
               //EXECUTE THIS SCHEDULER AGAIN IN NTH MINS.
               SM_FlagforDeletionScheduler schedClass = new SM_FlagforDeletionScheduler();
               Datetime dt = Datetime.now().addMinutes(10);
               String timeForScheduler = dt.format('s m H d M \'?\' yyyy');
               System.schedule('Flag for Deletion Job Retry ' + timeForScheduler, timeForScheduler, schedClass);
            }
            
            if (Test.isRunningTest() && hasException) {
                throw new SM_SchedulerException('Force to throw an exception');
            }
            
        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
        }
    }
}