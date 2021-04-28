/*
*Created by: Karen Hung
*Date: 11.03.2020
*Description: DOO-3001 Schedulable class for TS_MCOperating_Batch
*/
global with sharing class TS_MCOperating_Scheduler implements Schedulable{
    
    public static Boolean hasException = false;
    
    public class TS_MCOperating_SchedulerException extends Exception {}

    public Integer addedDay;

    global TS_MCOperating_Scheduler(Integer addDays){
        if(addDays == null){
            addedDay = 0; 
        } else{
            addedDay = addDays;   
        }      
    }
    
    /*execution of batch*/
    global void execute(SchedulableContext SC) {
		CustomLogging.push('execute', 'TS_MCOperating_Scheduler');

        try {

            Date runDate = Date.today().addDays(addedDay);

            if (Test.isRunningTest() && hasException) {
                throw new TS_MCOperating_SchedulerException('Force to throw an exception');
            }


            //Karen Hung 27.04.2020 DOO-4373 execute preload report for Nordics
            TS_PreloadReportQueueable preload = new TS_PreloadReportQueueable();
            preload.nordicsPreload = true;
            preload.runDate = runDate;
            System.enqueueJob(preload);            

            Integer countrySettingValue = Integer.valueOf(Label.TS_CountrySetting);

            //TODAY + a country dependent value
            Date todayPlusValue =  runDate.addDays(countrySettingValue);

            //todayPlusValue is => first day of next month
            Boolean isFirstofNextMonth = runDate.addMonths(1).toStartOfMonth() <= todayPlusValue && todayPlusValue.addDays(-7) < runDate.addMonths(1).toStartOfMonth();


            //check if todayPlusValue is => first day of next month, if true, run batch
            if(isFirstofNextMonth || Test.isRunningTest()){

                //CHECK IF THE ROUTESALES JOB IS STILL RUNNING
                List<AsyncApexJob> mcBatchJobs = [SELECT Id, ApexClassID 
                FROM AsyncApexJob 
                WHERE Status IN ('Processing', 'Preparing') 
                AND ApexClassId IN (SELECT Id FROM ApexClass WHERE Name = 'TS_MCOperating_Batch') ];

                //COUNT THE PROCESSING JOBS AND THOSE IN QUEUE
                Integer batchCount_ProcessingPreparing = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Processing\', \'Preparing\')');
                Integer batchCount_HoldingQueued = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Queued\', \'Holding\')');

                if (batchCount_ProcessingPreparing < 5 && batchCount_HoldingQueued < 100 && (mcBatchJobs == null || mcBatchJobs.size() == 0) && !Test.isRunningTest()) { 
                    Database.executeBatch(new TS_MCOperating_Batch(runDate, 0), Integer.valueOf(Label.TS_MCBatchSize));

                } else {
                    //EXECUTE THIS SCHEDULER AGAIN IN NTH MINS.
                    TS_MCOperating_Scheduler schedClass = new TS_MCOperating_Scheduler(addedDay);
                    Datetime dt = Datetime.now().addMinutes(10);
                    String timeForScheduler = dt.format('s m H d M \'?\' yyyy');
                    System.schedule('TS_MCOperating Retry ' + timeForScheduler, timeForScheduler, schedClass);
                }
            }
            

        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
        }
    }

}