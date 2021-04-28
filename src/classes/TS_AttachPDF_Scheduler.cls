/**
* @author        Karen Hung
* @date          17.Sep.2018
* @description   Apex class used to schedule TS_AttachPDF_Batch
* @revision(s)   
*                
*/
global with sharing class TS_AttachPDF_Scheduler implements schedulable{

    public static Boolean hasException = false;
    public class TS_AttachPDF_SchedulerException extends Exception {}
    
    
    /*constructor*/
    global TS_AttachPDF_Scheduler(){
    	
    }
    
    /*execution of batch*/
    global void execute(SchedulableContext SC) {
        CustomLogging.push('execute', 'TS_AttachPDF_Scheduler');
        
        try {

            if (Test.isRunningTest() && hasException) {
                throw new TS_AttachPDF_SchedulerException('Force to throw an exception');
            }

            //CHECK IF THE ATTACHPDF JOB IS STILL RUNNING
            List<AsyncApexJob> attachBatchJobs = [SELECT Id, ApexClassID 
                                                FROM AsyncApexJob 
                                                WHERE Status IN ('Processing', 'Preparing') 
                                                AND ApexClassId IN (SELECT Id FROM ApexClass WHERE Name = 'TS_AttachPDF_Batch') ];
            
            //COUNT THE PROCESSING JOBS AND THOSE IN QUEUE
            Integer batchCount_ProcessingPreparing = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Processing\', \'Preparing\')');
            Integer batchCount_HoldingQueued = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Queued\', \'Holding\')');

            Integer batchSize = 1;
            if(System.Label.TS_AttachPDFBatchSize != null){
                batchSize = Integer.valueOf(System.Label.TS_AttachPDFBatchSize);
            }

            if ((batchCount_ProcessingPreparing < 5 || batchCount_HoldingQueued < 100) && (attachBatchJobs == null || attachBatchJobs.size() == 0) && !Test.isRunningTest()) { 
               Database.executeBatch(new TS_AttachPDF_Batch(), batchSize);

            } else {
               //EXECUTE THIS SCHEDULER AGAIN IN NTH MINS.
               TS_AttachPDF_Scheduler schedClass = new TS_AttachPDF_Scheduler();
               Datetime dt = Datetime.now().addMinutes(10);
               String timeForScheduler = dt.format('s m H d M \'?\' yyyy');
               System.schedule('AttachPDF Job Retry ' + timeForScheduler, timeForScheduler, schedClass);
            }

        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
        }
    }

}