/**
* @author        Abram Vixen Reyes
* @date          Jan. 16, 2019  
* @description   This is the controller of the VF page called when running manually the case modification batch.
* @revision(s)   
*/
public with sharing class TS_DisasterRecoveryButtonController {

	public static List<Disaster_Recovery__c> disasterList = new List<Disaster_Recovery__c>();

    public TS_DisasterRecoveryButtonController(ApexPages.StandardSetController controller) {
    	//disasterList = controller.getSelected();
    }
    
    public static void executeDisaster() {
        //return true;
        CustomLogging.push('executeDisaster', 'TS_DisasterRecoveryButtonController');

        /* JANUARY 16, 2019: Queue Capacity Checker - XEN REYES */
        //CHECK IF THE JOB IS STILL RUNNING
        /* List<AsyncApexJob> batchJob = [SELECT Id, ApexClassID 
                                            FROM AsyncApexJob 
                                            WHERE Status IN ('Processing', 'Preparing') 
                                            AND ApexClassId IN (SELECT Id FROM ApexClass WHERE Name = 'TS_DisasterRecoveryBatch') ]; */
        
        //COUNT THE PROCESSING JOBS AND THOSE IN QUEUE
        Integer batchCount_ProcessingPreparing = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Processing\', \'Preparing\')');
        Integer batchCount_HoldingQueued = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Queued\', \'Holding\')');

        if (batchCount_ProcessingPreparing < 5 && batchCount_HoldingQueued < 100 && !Test.isRunningTest()) { 
           Database.executeBatch(new TS_DisasterRecoveryBatch(), 20);

        } else {
           //EXECUTE THE SCHEDULER AGAIN IN NTH MINS.
           TS_DisasterRecoveryBatch_Scheduler schedClass = new TS_DisasterRecoveryBatch_Scheduler();
           Datetime dt = Datetime.now().addMinutes(10);
           String timeForScheduler = dt.format('s m H d M \'?\' yyyy');
           System.schedule('Disaster Recovery Job Retry ' + timeForScheduler, timeForScheduler, schedClass);
        }

        CustomLogging.pop();
        
    }
    
}