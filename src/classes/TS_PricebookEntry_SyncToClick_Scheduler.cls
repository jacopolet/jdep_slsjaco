/**
* @author        Marvin Gatchalian
* @date          8.mar.2018
* @description   Apex class used to schedule Pricebook Sync to Click 
* @revision(s)   6.08.2018 Paul Aguiling: KTS-1804 Modified limit of 50 on execute()
*                
*/

global with sharing class TS_PricebookEntry_SyncToClick_Scheduler implements Schedulable {
	Datetime runDate;
	//Integer CONST_RANDOM_DELAY_TIME = Integer.valueOf('17'); // time (in minute) to postpone the batch if bussy
	
    public static Boolean hasException = false;

    public class TS_PricebookEntry_SyncToClick_SchedulerException extends Exception {

    }  
    //constructor
    global TS_PricebookEntry_SyncToClick_Scheduler (Datetime rDate){
    	//set a reference date for h=0    
        if (rDate!=null) runDate = rdate; else runDate = System.now(); 
    } 
    
    global void execute(SchedulableContext SC) {
    	CustomLogging.push('execute', 'TS_PricebookEntry_SyncToClick_Scheduler');
    	Integer frequency = Integer.valueOf(IntegrationUserAndProfile__c.getInstance().ClickPriceBookEntryScheduleDuration__c);
    	Integer batchSize = Integer.valueOf(IntegrationUserAndProfile__c.getInstance().Click_Product_Batch_Limit__c);
    	if (batchSize > 50) batchSize = 50;   //Limit to 50
    	
    	Datetime nextRunDate = runDate.addMinutes(frequency);
		String day = string.valueOf(nextRunDate.day()); 
		String month = string.valueOf(nextRunDate.month());
		String year = string.valueOf(nextRunDate.year());
		//Datetime dt = Datetime.now().addMinutes(CONST_RANDOM_DELAY_TIME);  
        //String timeForScheduler = dt.format('s m H d M \'?\' yyyy');

        try {

            if (Test.isRunningTest() && hasException) {
                throw new TS_PricebookEntry_SyncToClick_SchedulerException('Force to throw an exception');
            }

            //CHECK IF THE ROUTESALES JOB IS STILL RUNNING
            List<AsyncApexJob> syncToClickBatchJobs = [SELECT Id, ApexClassID 
                                                FROM AsyncApexJob 
                                                WHERE Status IN ('Processing', 'Preparing') 
                                                AND ApexClassId IN (SELECT Id FROM ApexClass WHERE Name = 'TS_PricebookEntry_SyncToClick_Batch') ];
            
            //COUNT THE PROCESSING JOBS AND THOSE IN QUEUE
            Integer batchCount_ProcessingPreparing = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Processing\', \'Preparing\')');
            Integer batchCount_HoldingQueued = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Queued\', \'Holding\')');

            if (batchCount_ProcessingPreparing < 5 && batchCount_HoldingQueued < 100 && (syncToClickBatchJobs == null || syncToClickBatchJobs.size() == 0) && !Test.isRunningTest()) { 
               Database.executeBatch(new TS_PricebookEntry_SyncToClick_Batch(), Integer.valueOf(System.label.TS_PBESyncBatchSize)); //Karen Hung DOO-3536 put batch size in custom label

            } else {
               //EXECUTE THIS SCHEDULER AGAIN IN NTH MINS.
               TS_PricebookEntry_SyncToClick_Scheduler schedClass = new TS_PricebookEntry_SyncToClick_Scheduler(runDate);
               Datetime dt = Datetime.now().addMinutes(10);
               String timeForScheduler = dt.format('s m H d M \'?\' yyyy');
               System.schedule('Sync to click Job Retry ' + timeForScheduler, timeForScheduler, schedClass);
            }

        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
        }
        /*
  
		TS_PricebookEntry_SyncToClick_Batch priceBookEntrySync = new TS_PricebookEntry_SyncToClick_Batch();

        if ([SELECT count() FROM AsyncApexJob WHERE JobType='BatchApex' AND (Status = 'Processing' OR Status = 'Preparing')] < 5){ 
            // run batch as there is a batch slot            
            Database.executeBatch(priceBookEntrySync, batchSize); // put 50 as max limit for Click Sync.
            String strSchedule = '0 0 22 ' + day + ' ' + month + ' ? ' + year;
            System.schedule('Pricebook SyncToClick Scheduler :' + strSchedule, strSchedule, 
            				 new TS_PricebookEntry_SyncToClick_Scheduler(nextRunDate));
        } else {
           //postpone the batch if busy         
           Id schedId = System.Schedule('Pricebook SyncToClick Batch, Retry:'+timeForScheduler, timeForScheduler, new TS_PricebookEntry_SyncToClick_Scheduler(nextRunDate));
        }*/
    }
}