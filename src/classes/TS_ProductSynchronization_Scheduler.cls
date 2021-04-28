/**
* @author        Marvin Gatchalian
* @date          8.mar.2018
* @description   Apex class used to schedule Product Synchronization Batch 
* @revision(s)   
*                
*/

global with sharing class TS_ProductSynchronization_Scheduler implements Schedulable {
	Datetime runDate;
	Integer CONST_RANDOM_DELAY_TIME = Integer.valueOf('17'); // time (in minute) to postpone the batch if bussy
	
    public static Boolean hasException = false;

    public class TS_ProductSynchronization_SchedulerException extends Exception {

    }   
    //constructor
    global TS_ProductSynchronization_Scheduler (Datetime rDate){
	    if (rDate!=null) runDate = rdate; else runDate = System.now(); 
    } 
    
    global void execute(SchedulableContext SC) {
    	CustomLogging.push('execute', 'TS_ProductSynchronization_Scheduler');
    	Integer frequency = 7;
    	Datetime nextRunDate = runDate.addDays(frequency);
		//String day = string.valueOf(nextRunDate.day()); 
		//String month = string.valueOf(nextRunDate.month());
		//String year = string.valueOf(nextRunDate.year());


        try {

            if (Test.isRunningTest() && hasException) {
                throw new TS_ProductSynchronization_SchedulerException('Force to throw an exception');
            }

            //CHECK IF THE ROUTESALES JOB IS STILL RUNNING
            List<AsyncApexJob> prodSyncBatchJobs = [SELECT Id, ApexClassID 
                                                FROM AsyncApexJob 
                                                WHERE Status IN ('Processing', 'Preparing') 
                                                AND ApexClassId IN (SELECT Id FROM ApexClass WHERE Name = 'TS_ProductSynchronization_Batch') ];
            
            //COUNT THE PROCESSING JOBS AND THOSE IN QUEUE
            Integer batchCount_ProcessingPreparing = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Processing\', \'Preparing\')');
            Integer batchCount_HoldingQueued = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Queued\', \'Holding\')');

            TS_ProductSynchronization_Batch productSync = new TS_ProductSynchronization_Batch();
            if (batchCount_ProcessingPreparing < 5 && batchCount_HoldingQueued < 100 && (prodSyncBatchJobs == null || prodSyncBatchJobs.size() == 0) && !Test.isRunningTest()) { 
                Database.executeBatch(productSync, Integer.valueOf(System.Label.TS_ProdSyncBatchSize)); //Karen Hung Feb. 17, 2020 DOO-3536 put custom label as batch size
                //String strSchedule = '0 0 22 ' + day + ' ' + month + ' ? ' + year;
               // System.schedule('Product Sync Scheduler :' + strSchedule, strSchedule,  new TS_ProductSynchronization_Scheduler(nextRunDate));
            } else {
                Datetime dt = Datetime.now().addMinutes(CONST_RANDOM_DELAY_TIME);  
                String timeForScheduler = dt.format('s m H d M \'?\' yyyy');
                Id schedId = System.Schedule('Product Sync Batch, Retry:'+timeForScheduler, timeForScheduler, new TS_ProductSynchronization_Scheduler(runDate));
               //EXECUTE THIS SCHEDULER AGAIN IN NTH MINS.
               /*TS_ProductSynchronization_Scheduler schedClass = new TS_ProductSynchronization_Scheduler(runDate);
               Datetime dt = Datetime.now().addMinutes(10);
               String timeForScheduler = dt.format('s m H d M \'?\' yyyy');
               System.schedule('Product Sync Job Retry ' + timeForScheduler, timeForScheduler, schedClass);*/
            }

        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
        }
           
		/*TS_ProductSynchronization_Batch productSync = new TS_ProductSynchronization_Batch();

        if ([SELECT count() FROM AsyncApexJob WHERE JobType='BatchApex' AND (Status = 'Processing' OR Status = 'Preparing')] < 5){ 
            // run batch as there is a batch slot            
            Database.executeBatch(productSync);
            String strSchedule = '0 0 22 ' + day + ' ' + month + ' ? ' + year;
            System.schedule('Product Sync Scheduler :' + strSchedule, strSchedule, 
            				 new TS_ProductSynchronization_Scheduler(nextRunDate));
        } else {
           //postpone the batch if busy         
           Id schedId = System.Schedule('Product Sync Batch, Retry:'+timeForScheduler, timeForScheduler, 
           								new TS_ProductSynchronization_Scheduler(nextRunDate));
        }*/
    }
}