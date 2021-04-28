/**
* @author        Paul Jarred Aguiling
* @date          04.14.2018          
* @description   [KTS-53]: RouteSales tasks in Salesforce. 
*                Class responsible for scheduling TS_RouteSalesBatch
* @revision(s)
*/
global without sharing class TS_RouteSalesScheduler implements Schedulable {

    public static Boolean hasException = false;

    /******************************************************************************
    * @author         Paul Jarred Aguiling
    * @date           04.14.2018 
    * @description    Method responsible for throwing an exception
    * @revision(s)
    ******************************************************************************/ 
    public class TS_RouteSalesSchedulerException extends Exception {

    }

    /******************************************************************************
    * @author         Paul Jarred Aguiling
    * @date           04.14.2018 
    * @description    Method responsible executing the main logic
    * @revision(s)
    ******************************************************************************/ 
    global void execute(SchedulableContext SC) {
        CustomLogging.push('execute', 'TS_RouteSalesScheduler');
        
        try {

            if (Test.isRunningTest() && hasException) {
                throw new TS_RouteSalesSchedulerException('Force to throw an exception');
            }

            //CHECK IF THE ROUTESALES JOB IS STILL RUNNING
            List<AsyncApexJob> routeSalesBatchJobs = [SELECT Id, ApexClassID 
                                                FROM AsyncApexJob 
                                                WHERE Status IN ('Processing', 'Preparing') 
                                                AND ApexClassId IN (SELECT Id FROM ApexClass WHERE Name = 'TS_RouteSalesBatch') ];
            
            //COUNT THE PROCESSING JOBS AND THOSE IN QUEUE
            Integer batchCount_ProcessingPreparing = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Processing\', \'Preparing\')');
            Integer batchCount_HoldingQueued = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Queued\', \'Holding\')');

            if (batchCount_ProcessingPreparing < 5 && batchCount_HoldingQueued < 100 && (routeSalesBatchJobs == null || routeSalesBatchJobs.size() == 0) && !Test.isRunningTest()) { 
               Database.executeBatch(new TS_RouteSalesBatch(null), 40);

            } else {
               //EXECUTE THIS SCHEDULER AGAIN IN NTH MINS.
               TS_RouteSalesScheduler schedClass = new TS_RouteSalesScheduler();
               Datetime dt = Datetime.now().addMinutes(10);
               String timeForScheduler = dt.format('s m H d M \'?\' yyyy');
               System.schedule('Routesales Job Retry ' + timeForScheduler, timeForScheduler, schedClass);
            }

        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
        }
    }
}