/**
* @author           Abram Vixen Reyes
* @date				Jan. 10, 2019
* @description      Apex class used to schedule Click SessionId
* @revision(s)   
*                
*/
global with sharing class TS_ClickSessionId_Scheduler implements schedulable{

    public static Boolean hasException = false;
    public class TS_ClickSessionId_SchedulerException extends Exception {}
    
    
    /* CONSTRUCTOR */
    global TS_ClickSessionId_Scheduler(){
    	
    }
    
    /* BATCH EXECUTION */
    global void execute(SchedulableContext SC) {
        CustomLogging.push('execute', 'TS_ClickSessionId_Scheduler');
        
        try {

            if (Test.isRunningTest() && hasException) {
                throw new TS_ClickSessionId_SchedulerException('Force to throw an exception');
            }
            
            //REMOVE ALL CHECKERS - ALM 6750 - Xen Reyes - April 15, 2019
            /* List<AsyncApexJob> clickSessionJobs = [SELECT Id, ApexClassID 
                                                FROM AsyncApexJob 
                                                WHERE Status IN ('Processing', 'Preparing') 
                                                AND ApexClassId IN (SELECT Id FROM ApexClass WHERE Name = 'QueueableAPILogin') ];
            
            //COUNT THE PROCESSING JOBS AND THOSE IN QUEUE
            Integer batchCount_ProcessingPreparing = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Processing\', \'Preparing\')');
            Integer batchCount_HoldingQueued = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Queued\', \'Holding\')');

            if ((batchCount_ProcessingPreparing < 5 || batchCount_HoldingQueued < 100) && (clickSessionJobs == null || clickSessionJobs.size() == 0) && !Test.isRunningTest()) { 
                 System.enqueueJob(new QueueableAPILogin());

            } else {
               //EXECUTE THIS SCHEDULER AGAIN IN NTH MINS.
               TS_ClickSessionId_Scheduler schedClass = new TS_ClickSessionId_Scheduler();
               Datetime dt = Datetime.now().addMinutes(10);
               String timeForScheduler = dt.format('s m H d M \'?\' yyyy');
               System.schedule('Click Session Id Job Retry ' + timeForScheduler, timeForScheduler, schedClass);
            } */

            if(!Test.isRunningTest()){
                System.enqueueJob(new QueueableAPILogin());
            }

        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
        }
    }

}