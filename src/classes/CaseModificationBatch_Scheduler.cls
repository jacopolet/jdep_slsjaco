/*
* @author        Karen Hung
* @date          1.16.19       
* @description   Class responsible for scheduling CaseModificationBatch
* @revision(s)
*/
global with sharing class CaseModificationBatch_Scheduler implements Schedulable{
    
    public static Boolean hasException = false;

    public List<Case> caseList = null;
    public List<Id> accountIds = null;
    public List<Id> accLocIds = null;
    public List<Id> productIds = null;
    /******************************************************************************
    * @author         Karen Hung
    * @date           1.16.19
    * @description    Method responsible for throwing an exception
    * @revision(s)
    ******************************************************************************/ 
    public class TS_SchedulerException extends Exception {

    }

    //constructor
    global CaseModificationBatch_Scheduler(List<Case> caseList, List<Id> accountIds, List<Id> accLocIds, List<Id> productIds){
    	this.caseList = caseList;
        this.accountIds = accountIds;
        this.accLocIds = accLocIds;
        this.productIds = productIds;   
    }
    /******************************************************************************
    * @author         Karen Hung
    * @date           1.16.19
    * @description    Method responsible executing the main logic
    * @revision(s)
    ******************************************************************************/ 
    global void execute(SchedulableContext SC) {
        CustomLogging.push('execute', 'CaseModificationBatch_Scheduler');
        
        try {

            if (Test.isRunningTest() && hasException) {
                throw new TS_SchedulerException('Force to throw an exception');
            }

           //CHECK IF THE ROUTESALES JOB IS STILL RUNNING
            List<AsyncApexJob> caseModBatchJobs = [SELECT Id, ApexClassID 
                                                FROM AsyncApexJob 
                                                WHERE Status IN ('Processing', 'Preparing') 
                                                AND ApexClassId IN (SELECT Id FROM ApexClass WHERE Name = 'CaseModificationBatch') ];
            
           //COUNT THE PROCESSING JOBS AND THOSE IN QUEUE
            Integer batchCount_ProcessingPreparing = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Processing\', \'Preparing\')');
            Integer batchCount_HoldingQueued = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Queued\', \'Holding\')');

            if (batchCount_ProcessingPreparing < 5 && batchCount_HoldingQueued < 100 && (caseModBatchJobs == null || caseModBatchJobs.size() == 0) && !Test.isRunningTest()) { 
               Database.executeBatch(new CaseModificationBatch(caseList,accountIds,accLocIds,productIds), 40);

            } else {
               //EXECUTE THIS SCHEDULER AGAIN IN NTH MINS.
               CaseModificationBatch_Scheduler schedClass = new CaseModificationBatch_Scheduler(caseList,accountIds,accLocIds,productIds);
               Datetime dt = Datetime.now().addMinutes(10);
               String timeForScheduler = dt.format('s m H d M \'?\' yyyy');
               System.schedule('Case Modification Job Retry ' + timeForScheduler, timeForScheduler, schedClass);
            }

        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
        }
    }

}