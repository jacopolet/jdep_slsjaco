/**
* @author        Karen Hung
* @date          17.01.2020
* @description   Apex class used to schedule Operating Route tasks 
* @revision(s)   
*/

global with sharing class TS_RouteTask_Scheduler implements Schedulable {
    
    public String country_Name;
    public Integer numberDayToLookup = 0;
    public Integer addedDay;
    public static Boolean hasException = false;
    
    public class TS_RouteTask_SchedulerException extends Exception {
        
    }
    
    global TS_RouteTask_Scheduler(Integer addDays){
        if(addDays == null){
            addedDay = 0; 
        } else{
            addedDay = addDays;   
        }     
    }
    
    global void execute(SchedulableContext SC) {
        CustomLogging.push('execute', 'TS_RouteTask_Scheduler');
        
        Integer numberDayToLookup;
        
        Date runDate;
        if(runDate == null){
            runDate = Date.today().addDays(addedDay);
        }
        
        runDate = runDate.addDays(1);
        
        Id rt = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', Label.TS_OperatingTaskRecordType);
        
        List<CountrySetting__c> countrySettings = [SELECT id, DefaultStartTime__c, DefaultEndTime__c, NumberDayToLookup__c, Business_Hours__r.id
                                                   FROM CountrySetting__c
                                                   WHERE tolabel(Country__c) = :country_Name
                                                   And Active__c = TRUE
                                                   And RecordTypeId = :rt limit 1];
        
        String busineshourId = String.valueOf(countrySettings[0].Business_Hours__r.id);               
        if (countrySettings[0] != null){
            numberDayToLookup = Integer.valueOf( countrySettings[0].NumberDayToLookup__c);
        } else {
            numberDayToLookup = 10;
        }
        
        TS_OperatingTaskUtility tsUtils = new TS_OperatingTaskUtility();
        Map<Integer, Boolean> regularHolidayMap = tsUtils.getFutureHolidayMap(2, busineshourId, runDate);
        Map<Integer, Boolean> forwardHolidayMap = tsUtils.getFutureHolidayMap(numberDayToLookup, busineshourId, runDate);
        Map<Integer, Boolean> previousHolidayMap = tsUtils.getPastHolidayMap(numberDayToLookup, busineshourId, runDate);
        
        Boolean isTodayWorkingDay = regularHolidayMap.get(0);
        Boolean isTomorrowWorkingDay = regularHolidayMap.get(1);
        Boolean isDayTomorrowWorkingDay = regularHolidayMap.get(2); 
        
        Boolean isRegularBatch = isTodayWorkingDay && isTomorrowWorkingDay && isDayTomorrowWorkingDay;
        Boolean isHolidayBatchForward = isTodayWorkingDay && isTomorrowWorkingDay && !isDayTomorrowWorkingDay;
        Boolean isHolidayBatchBackWard = !isTodayWorkingDay && isTomorrowWorkingDay && isDayTomorrowWorkingDay;
        Boolean isHolidayBatchBackForward = !isTodayWorkingDay && isTomorrowWorkingDay && !isDayTomorrowWorkingDay;
        
        String batchType;
        if (isRegularBatch) batchType = 'regularbatch';
        if (isHolidayBatchBackWard) batchType = 'holidaybatchBWK';
        if (isHolidayBatchForward) batchType = 'holidaybatchFWD';
        if (isHolidayBatchBackForward) batchType = 'holidaybatchFWDBWK';
        
        /****************************************************************************************************/
        
        Date nextDate = runDate.addDays(1);
        DateTime nextDateTime = DateTime.newInstanceGMT(nextDate.year(), nextDate.month(), nextDate.day(), 12, 0, 0);
        
        /* EVALUATE IF COUNTER READING DAY */
        Boolean SEND_COUNTER = Boolean.valueOf(Label.TS_EnforceCounterReadingForOperating);
        Integer NUM_WORKINGDAYS = Integer.valueOf(Label.TS_NumberOfWorkingDaysCounterReading);
        String SATURDAY = 'Saturday';
        String SUNDAY = 'Sunday';
        Set<Date> DAYSET = new Set<Date>();
        
        //Date D1 = Date.today().toStartofMonth();
        Date D1 = nextDate.toStartofMonth();
        Date D2 = D1.addMonths(1);
        
        Integer COUNTER = 0;
        while (D1 < D2)
        {   
            if(COUNTER == NUM_WORKINGDAYS){
                break;
            }
            
            Datetime dtime = datetime.newInstanceGMT(D1.year(), D1.month(),D1.day(), 12, 0, 0);
            
            if(dtime.format('EEEE') != SATURDAY && dtime.format('EEEE') != SUNDAY){
                DAYSET.add(D1);
                COUNTER ++;
            }
            
            D1 = D1.addDays(1);
        }
        
        if(!DAYSET.isEmpty() && DAYSET.contains(nextDate)){
            SEND_COUNTER = true;
        }
        
        /* RUN OPERATING BATCH SCHEDULER */
        TS_RouteTask_Batch routeTaskBatch = new TS_RouteTask_Batch( batchType, nextDate, forwardHolidayMap, previousHolidayMap, countrySettings[0], true, 0); 
        
        try {
            
            if (Test.isRunningTest() && hasException) {
                throw new TS_RouteTask_SchedulerException('Force to throw an exception');
            }
            
            //CHECK IF THE OPERATING TASK JOB IS STILL RUNNING
            List<AsyncApexJob> routeTaskBatchJobs = [SELECT Id, ApexClassID 
                                                     FROM AsyncApexJob 
                                                     WHERE Status IN ('Processing', 'Preparing') 
                                                     AND ApexClassId IN (SELECT Id FROM ApexClass WHERE Name = 'TS_RouteTask_Batch') ];
            
            //COUNT THE PROCESSING JOBS AND THOSE IN QUEUE
            Integer batchCount_ProcessingPreparing = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Processing\', \'Preparing\')');
            Integer batchCount_HoldingQueued = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Queued\', \'Holding\')');
            
            Boolean isRetry = FALSE;
            if((batchCount_ProcessingPreparing < 5 || batchCount_HoldingQueued < 100) && (routeTaskBatchJobs == null || routeTaskBatchJobs.size() == 0) && !Test.isRunningTest()) {
                Database.executeBatch(routeTaskBatch, Integer.valueOf(System.Label.TS_RouteTaskBatchSize));
                
            } else {
                isRetry = TRUE;
                //EXECUTE THIS SCHEDULER AGAIN IN NTH MINS.
                TS_RouteTask_Scheduler schedClass = new TS_RouteTask_Scheduler(addedDay);
                schedClass.country_Name = country_Name;
                Datetime dt = Datetime.now().addMinutes(10);
                String timeForScheduler = dt.format('s m H d M \'?\' yyyy');
                System.schedule('Route Task (Daily) Job Retry ' + timeForScheduler, timeForScheduler, schedClass);
            }
            
            
            //executePreloadReport(nextDate, batchType, busineshourId, IS_CR_DAY, SEND_COUNTER, isRetry);
            TS_PreloadReportQueueable preload = new TS_PreloadReportQueueable();
            preload.taskDate = nextDate;
            preload.batchType = batchType;
            preload.BUSINESS_ID = busineshourId;
            preload.SEND_COUNTER =  SEND_COUNTER;
            preload.isRetry = isRetry;
            preload.runDate = runDate;
            preload.addedDay = addedDay;
            preload.country_Name = country_Name;
            System.enqueueJob(preload);
            
            /*String PRELOAD_STRING = '';
                PRELOAD_STRING = PRELOAD_SCRIPT(nextDate, batchType, busineshourId, SEND_COUNTER);*/
                            
                            /*Custom log creation to check parameter*/
                            /*Custom_Log__c log = new Custom_Log__c(
                Name = 'Route Task (Daily) ' + String.valueOf(System.now()),
                StackTrace__c = 'TS_RouteTask_Batch',
                Message__c = 'This is a log to monitor the parameters provided to the route operating daily scheduler class and to generate a pre-load report.' 
                + '\n' + 'RUN DATE: ' + String.valueOf(runDate) 
                + '\n' + 'TASK DATE: ' + String.valueOf(nextDate)
                + '\n' + 'TASK DAY: ' + nextDateTime.format('EEEE')
                + '\n' + 'ADD DAYS: ' + String.valueOf(addedDay) 
                + '\n' + 'COUNTRY: ' + country_Name
                + '\n' + 'BATCH TYPE: ' + batchType
                + '\n' + 'IS RETRY: ' + String.valueOf(isRetry)
                + '\n' + 'IS CR DAY: ' + String.valueOf(SEND_COUNTER)
                + '\n' + PRELOAD_STRING
                );
                
                insert log;*/
            
        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
        }   
    }

}