/**
* @author        Archi Delphinanto
* @date          9.March.2018
* @description   Apex class used to schedule Counter Reading scheduler 
* @revision(s)   
*/

global with sharing class TS_CounterReading_Scheduler implements Schedulable {

Integer CONST_RANDOM_DELAY_TIME = Integer.valueOf('17'); // time (in minute) to postpone the batch if bussy
Integer CONST_NUM_MONTH_TO_SCHEDULE = Integer.valueOf('1');
Integer CONST_HOUR_TO_RUNBATCH = Integer.valueOf('23');
Integer CONST_DAY_ON_THE_MONTH = Integer.valueOf('27');
Integer CONST_BATCHSIZE = Integer.valueOf('10');

   public class TS_CounterReading_SchedulerException extends Exception {}
   public static Boolean hasException = false;

    //CONSTRUCTOR
    global  TS_CounterReading_Scheduler(){

    }

    /******************************************************************************
        * @author         Archi Delphinanto
        * @date           9.March.2018
        * @description    Schedule TS_CounterReading_Batch when there is less than  5 concurent active batches
        * @revision(s)
    ******************************************************************************/ 

     global void execute(SchedulableContext SC) {
     	CustomLogging.push('execute', 'TS_CounterReading_Scheduler');

        try {

            if (Test.isRunningTest() && hasException) {
                throw new TS_CounterReading_SchedulerException('Force to throw an exception');
            }

            //CHECK IF THE COUNTER READING JOB IS STILL RUNNING
            List<AsyncApexJob> counterReadingBatchJobs = [SELECT Id, ApexClassID 
                                                FROM AsyncApexJob 
                                                WHERE Status IN ('Processing', 'Preparing') 
                                                AND ApexClassId IN (SELECT Id FROM ApexClass WHERE Name = 'TS_CounterReading_Batch') ];
            
            //COUNT THE PROCESSING JOBS AND THOSE IN QUEUE
            Integer batchCount_ProcessingPreparing = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Processing\', \'Preparing\')');
            Integer batchCount_HoldingQueued = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Queued\', \'Holding\')');

            if (batchCount_ProcessingPreparing < 5 && batchCount_HoldingQueued < 100 && (counterReadingBatchJobs == null || counterReadingBatchJobs.size() == 0) && !Test.isRunningTest()) { 
               Database.executeBatch(new TS_CounterReading_Batch(null), 40); //Karen Hung KTS-2648 2/28/19 to allow flexible rundate

            } else {
               //EXECUTE THIS SCHEDULER AGAIN IN NTH MINS.
               TS_CounterReading_Scheduler schedClass = new TS_CounterReading_Scheduler();
               Datetime dt = Datetime.now().addMinutes(10);
               String timeForScheduler = dt.format('s m H d M \'?\' yyyy');
               System.schedule('Counter Reading Job Retry ' + timeForScheduler, timeForScheduler, schedClass);
            }

        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
        }
    }   
 
    /******************************************************************************
        * @author         Archi Delphinanto
        * @date           9.March.2018
        * @description    Schedule Counter 
        * @revision(s)
    /******************************************************************************/ 
    /*private Map<String,String> getJobMap (){
     	Map<String,String> jmap = new Map<String,String>();
     	String jobName = 'jobname';
     	String nextCRON ='nextcron' ;
     	CustomLogging.push('getJobMap', 'TS_CounterReading_Scheduler');

     	Date nextBatchDate = date.today().addMonths(CONST_NUM_MONTH_TO_SCHEDULE);
    	nextBatchDate= nextBatchDate.toStartOfMonth();
        nextBatchDate= nextBatchDate.addDays(CONST_DAY_ON_THE_MONTH);
        //System.debug('nextBatchDate: '+nextBatchDate);

    	Time nextBatchTime = Time.newInstance(CONST_HOUR_TO_RUNBATCH , 0, 0, 0);
    	DateTime nextBatchDateTime =Datetime.newInstance(nextBatchDate, nextBatchTime);
    	String jobNameValue = 'Counter Reading Batch Scheduled for: '+ nextBatchDateTime.format('d/M/yyyy');
    	String nextCRONValue = nextBatchDateTime.format('s m H d M \'?\' yyyy');

    	Jmap.put(jobName, jobNameValue);
    	Jmap.put(nextCRON, nextCRONValue);

    	CustomLogging.pop();    
     	return jmap;
     }*/


}