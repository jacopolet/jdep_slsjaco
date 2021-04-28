/**
* @author        Karen Hung
* @date          31.Oct.2018
* @description   Apex class used to schedule Physical Asset Update batch
* @revision(s)   
*                
*/
global with sharing class TS_PhysicalAssetUpdate_Scheduler implements schedulable{

	String CONST_OP_BATCH_HOUR = '22';
    Integer CONST_RANDOM_DELAY_TIME = Integer.valueOf('17');

    public static Boolean hasException = false;

    public class TS_PhysicalAssetUpdate_SchedulerException extends Exception {

    }

	Date runDate;

	//constructor
    global TS_PhysicalAssetUpdate_Scheduler(Date rDate){
    	if (rdate!=null) runDate = rdate; else runDate = Date.today();     
    }

    global void execute(SchedulableContext SC) {
		CustomLogging.push('execute', 'TS_PhysicalAssetUpdate_Scheduler');
		//Date nextDate = runDate.addDays(1);
        //String day = string.valueOf(nextDate.day()); 
        //String month = string.valueOf(nextDate.month());
        //String year = string.valueOf(nextDate.year());
		
	    try {

            if (Test.isRunningTest() && hasException) {
                throw new TS_PhysicalAssetUpdate_SchedulerException('Force to throw an exception');
            }

            //CHECK IF THE UPDATE JOB IS STILL RUNNING
            List<AsyncApexJob> paUpdateBatchJobs = [SELECT Id, ApexClassID 
                                                     FROM AsyncApexJob 
                                                     WHERE Status IN ('Processing', 'Preparing') 
                                                      AND ApexClassId IN (SELECT Id FROM ApexClass WHERE Name = 'TS_PhysicalAssetUpdate_Batch') ];
            
            //COUNT THE PROCESSING JOBS AND THOSE IN QUEUE
            Integer batchCount_ProcessingPreparing = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Processing\', \'Preparing\')');
            Integer batchCount_HoldingQueued = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Queued\', \'Holding\')');

            if (batchCount_ProcessingPreparing < 5 && batchCount_HoldingQueued < 100 && (paUpdateBatchJobs == null || paUpdateBatchJobs.size() == 0) && !Test.isRunningTest()) { 
               Database.executeBatch(new TS_PhysicalAssetUpdate_Batch(runDate), 40);

            } else {
               //EXECUTE THIS SCHEDULER AGAIN IN NTH MINS.
               TS_PhysicalAssetUpdate_Scheduler schedClass = new TS_PhysicalAssetUpdate_Scheduler(runDate);
               Datetime dt = Datetime.now().addMinutes(10);
               String timeForScheduler = dt.format('s m H d M \'?\' yyyy');
               System.schedule('Physical asset update Job Retry ' + timeForScheduler, timeForScheduler, schedClass);
            }

        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
        }



        /*TS_PhysicalAssetUpdate_Batch updateRecord = new TS_PhysicalAssetUpdate_Batch(runDate);
        Database.executeBatch(updateRecord,40);
	    //---START-----------to avoid batch processing error when there is an active batch more than 4  ---//      
        if ([SELECT count() FROM AsyncApexJob WHERE JobType='BatchApex' AND (Status = 'Processing' OR Status = 'Preparing')] < 5){ 
            // run batch as there is a batch slot   
            //System.debug('Batch Type: >>>' + batchType);         
            Database.executeBatch(updateRecord,40);
            String strSchedule = '0 0 '+ CONST_OP_BATCH_HOUR +' ' + day + ' ' + month + ' ? ' + year;
            System.schedule('Update Physical Asset Scheduler :' + strSchedule, strSchedule, new TS_PhysicalAssetUpdate_Scheduler(nextDate));
        } else {
            //postpone the batch if busy         
            Datetime dt = Datetime.now().addMinutes(CONST_RANDOM_DELAY_TIME);  
            String timeForScheduler = dt.format('s m H d M \'?\' yyyy');
            Id schedId = System.Schedule('Create Task Batch, Retry:'+timeForScheduler,timeForScheduler,new TS_PhysicalAssetUpdate_Scheduler(nextDate));
        }*/
    }

}