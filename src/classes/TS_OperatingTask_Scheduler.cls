/**
* @author        Archi Delphinanto
* @date          5.feb.2018
* @description   Apex class used to schedule Operating tasks 
* @revision(s)   Marvin Gatchalian, update the class to add holiday and regulare batch logic
*                5 March 2018, Archi Delphinanto adds a SQL to check curent number of active batch to prevent error
*/

global with sharing class TS_OperatingTask_Scheduler implements Schedulable {
    
    public String country_Name;
    Integer numberDayToLookup = 0;
    Integer CONST_RANDOM_DELAY_TIME = Integer.valueOf('17');
    String CONST_OP_BATCH_HOUR = '22';

    //Karen Hung
    public Integer addedDay;

    public static Boolean hasException = false;

    public class TS_OperatingTask_SchedulerException extends Exception {
      
    }
    
    /* global TS_OperatingTask_Scheduler(Date rdate, String countryname){
      country_Name = countryname;
      runDate = rdate;
    } */

    /*Karen Hung 27.03.19 added parameter for Thursday scenario*/
    global TS_OperatingTask_Scheduler(Integer addDays){
        if(addDays == null){
          addedDay = 0; 
        }else{
           addedDay = addDays;   
        }     
    }

    global void execute(SchedulableContext SC) {
      CustomLogging.push('execute', 'TS_OperatingTask_Scheduler');

      /********Karen Hung 3/14/19 KTS-2666  transfer code from constructor to execute***************/
      Integer numberDayToLookup;

      Date runDate;
      if(runDate == null){
        runDate = Date.today().addDays(addedDay);
      }

      /* Jan. 16, 2019 XEN REYES KTS-2484 */
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
      /* Jan. 16, 2019 XEN REYES KTS-2484 */
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
          /* if(BusinessHours.isWithin(busineshourId, dtime)){
              DAYSET.add(D1);
              COUNTER ++;
          } */

          //XEN REYES INC0119960 DOO-665 July 17, 2019
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
      TS_OperatingTask_Batch operatingTaskBatch = new TS_OperatingTask_Batch(batchType, nextDate, forwardHolidayMap, previousHolidayMap, countrySettings[0]); 

      try {

        if (Test.isRunningTest() && hasException) {
          throw new TS_OperatingTask_SchedulerException('Force to throw an exception');
        }

        //CHECK IF THE OPERATING TASK JOB IS STILL RUNNING
        List<AsyncApexJob> operatingTaskBatchJobs = [SELECT Id, ApexClassID 
                                                    FROM AsyncApexJob 
                                                    WHERE Status IN ('Processing', 'Preparing') 
                                                    AND ApexClassId IN (SELECT Id FROM ApexClass WHERE Name = 'TS_OperatingTask_Batch') ];
        
        //COUNT THE PROCESSING JOBS AND THOSE IN QUEUE
        Integer batchCount_ProcessingPreparing = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Processing\', \'Preparing\')');
        Integer batchCount_HoldingQueued = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Queued\', \'Holding\')');

        Boolean isRetry = FALSE;
        if((batchCount_ProcessingPreparing < 5 || batchCount_HoldingQueued < 100) && (operatingTaskBatchJobs == null || operatingTaskBatchJobs.size() == 0) && !Test.isRunningTest()) {
          Database.executeBatch(operatingTaskBatch, 20);

        } else {
          isRetry = TRUE;
          //EXECUTE THIS SCHEDULER AGAIN IN NTH MINS.
          TS_OperatingTask_Scheduler schedClass = new TS_OperatingTask_Scheduler(addedDay);
          schedClass.country_Name = country_Name;
          Datetime dt = Datetime.now().addMinutes(10);
          String timeForScheduler = dt.format('s m H d M \'?\' yyyy');
          System.schedule('Operating Task (Daily) Job Retry ' + timeForScheduler, timeForScheduler, schedClass);
        }

        String PRELOAD_STRING = '';
        PRELOAD_STRING = PRELOAD_SCRIPT(nextDate, batchType, busineshourId, SEND_COUNTER);

        /*Custom log creation to check parameter*/
        Custom_Log__c log = new Custom_Log__c(
          Name = 'Operating Task (Daily) ' + String.valueOf(System.now()),
          StackTrace__c = 'TS_OperatingTask_Batch',
          Message__c = 'This is custom log to monitor the parameter provided to the operating daily scheduler class.' 
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

        insert log;

      } catch (Exception ex) {
        CustomLogging.debugException(ex);
        CustomLogging.pop();
      }   
    }

    /**
    * @author        Abram Vixen Reyes
    * @date          March 28, 2019
    * @description   Method to generate pre-load script and attach basic information in custom log.
    * @revision(s)
    */
    public String PRELOAD_SCRIPT (Date nextDate, String batchType, String BUSINESS_ID, Boolean IS_CR_DAY) {

      String CONST_SmallTask_API = Label.TS_Operating_Small,CONST_LargeTask_API = Label.TS_Operating_Large, CONST_RinseTask_API = Label.TS_Operating_Rinse, CONST_CupsTask_API = Label.TS_Operating_Cups;
      List<String> CSVROWVALUES_SMALL = new List<String>(); List<String> CSVROWVALUES_LARGE = new List<String>(); List<String> CSVROWVALUES_CUP = new List<String>(); List<String> CSVROWVALUES_RINSE = new List<String>();
      Integer TOTAL_CUPS = 0, TOTAL_RINSE = 0, TOTAL_LARGE = 0, TOTAL_LARGE_CR = 0, TOTAL_SMALL = 0, NUM_WORKORDER = 0, OP_SCHED_SIZE = 0;

      DateTime scheduledDate = nextDate;
      Boolean isHoliday = false;
      if(batchType == null || batchType == 'null'){
        isHoliday = true;
      }

      DescribeSObjectResult operatingScheduleDescribe = OperatingSchedule__c.getSObjectType().getDescribe();
      List<String> fields = new List<String>(operatingScheduleDescribe.fields.getMap().keySet());
      String QUERY_STRING = 'SELECT ' + String.join(fields, ',') +
                ', PhysicalAsset__r.Name, PhysicalAsset__r.CounterReading__c, PhysicalAsset__r.Connected__c, PhysicalAsset__r.Machine_Care__c' + ' FROM ' + operatingScheduleDescribe.getName() + 
                ' WHERE Active__c = true AND PhysicalAsset__c != null AND TypeofContract__c != null AND Schedule_Type__c = \'Regular\' AND PhysicalAsset__r.MothballAssetIndicator__c = false' +
                ' AND PhysicalAsset__r.AccountLocation__c != null ' +
                ' AND PhysicalAsset__r.AssetStatus__c = \'Activated\' ' +
                (isHoliday ? ' AND Schedule_Tasks_for_Holiday__c = true' : '' );

      List<OperatingSchedule__c> OPS_LIST = Database.query(QUERY_STRING);
  
      if(!OPS_LIST.isEmpty()){
        OP_SCHED_SIZE = OPS_LIST.size();
        for(OperatingSchedule__c OP_VAR : OPS_LIST){

          Boolean TASK_CREATED = false;

          //GET WEEK NUMBER
          Date d1 = OP_VAR.Start_Date__c.toStartOfWeek();
          Date d2 = scheduledDate.date().toStartOfWeek();
          Integer numberOfWeeks = d1.daysBetween(d2) / 7;
          String WEEK_NUM = String.valueOf(Math.mod(numberOfWeeks, 2) == 0 ? 1 : 2);

          //GET RINSE
          String RINSE_API = CONST_RinseTask_API + '_' + WEEK_NUM + '_' + scheduledDate.format('EEEE') + '__c';
          if(OP_VAR.get(RINSE_API) != null){
            Boolean VAL_RINSE = (Boolean) OP_VAR.get(RINSE_API);
            if(VAL_RINSE) {

              TASK_CREATED = true;
              TOTAL_RINSE++;

              String OPSCHED_NAME = OP_VAR.Name != null ? OP_VAR.Name : '';
              String OPSCHED_PHYSICALASSET = OP_VAR.PhysicalAsset__r.Name != null ? OP_VAR.PhysicalAsset__r.Name : '';
              String OPSCHED_STARTDATE = String.valueOf(OP_VAR.Start_Date__c);
              String FIELD_API = RINSE_API != null ? RINSE_API : '';
              String FIELD_VALUE = String.valueOf(1);
                  
              String rowStr = OPSCHED_NAME + ',' + OPSCHED_PHYSICALASSET + ',' + OPSCHED_STARTDATE + ',' + FIELD_API + ','+ FIELD_VALUE;
              CSVROWVALUES_RINSE.add(rowStr);
              //TASK_CREATED = true;
            }
          }

          //GET LARGE
          String LARGE_API = CONST_LargeTask_API + '_' + WEEK_NUM + '_' + scheduledDate.format('EEEE') + '__c';
          if(OP_VAR.get(LARGE_API) != null){
            String VAL_LARGE = String.valueOf(OP_VAR.get(LARGE_API));
            if (!VAL_LARGE.equals('0') && VAL_LARGE != null) {
                TOTAL_LARGE++;

                if(OP_VAR.PhysicalAsset__r.CounterReading__c == 'Yes' &&
                    OP_VAR.PhysicalAsset__r.Connected__c == 'No' &&
                    (OP_VAR.PhysicalAsset__r.Machine_Care__c == 'Full Operating' || OP_VAR.PhysicalAsset__r.Machine_Care__c == 'Comfort Operating')){
                    TOTAL_LARGE_CR++;
                }

                String OPSCHED_NAME = OP_VAR.Name != null ? OP_VAR.Name : '';
                String OPSCHED_PHYSICALASSET = OP_VAR.PhysicalAsset__r.Name != null ? OP_VAR.PhysicalAsset__r.Name : '';
                String OPSCHED_STARTDATE = String.valueOf(OP_VAR.Start_Date__c);
                String FIELD_API = LARGE_API != null ? LARGE_API : '';
                String FIELD_VALUE = String.valueOf(1);
                    
                String rowStr = OPSCHED_NAME + ',' + OPSCHED_PHYSICALASSET + ',' + OPSCHED_STARTDATE + ',' + FIELD_API + ','+ FIELD_VALUE;
                CSVROWVALUES_LARGE.add(rowStr);
                TASK_CREATED = true;
            }
          }

          //GET SMALL
          String SMALL_API = CONST_SmallTask_API + '_' + WEEK_NUM + '_' + scheduledDate.format('EEEE') + '__c';
          if(OP_VAR.get(SMALL_API) != null){
            String VAL_SMALL = String.valueOf(OP_VAR.get(SMALL_API));
            if (!VAL_SMALL.equals('0') && VAL_SMALL != null) {
                  
                  Integer INDICATOR_VAR_SMALL = 0;
                  if (VAL_SMALL.equals('AM') || VAL_SMALL.equals('PM')) {
                      TOTAL_SMALL++;
                      INDICATOR_VAR_SMALL = 1;
                  } else if (Integer.valueOf(VAL_SMALL) > 0) {
                      Integer int_val = Integer.valueOf(VAL_SMALL);
                      TOTAL_SMALL = TOTAL_SMALL + int_val;
                      INDICATOR_VAR_SMALL = int_val;
                  }

                  String OPSCHED_NAME = OP_VAR.Name != null ? OP_VAR.Name : '';
                  String OPSCHED_PHYSICALASSET = OP_VAR.PhysicalAsset__r.Name != null ? OP_VAR.PhysicalAsset__r.Name : '';
                  String OPSCHED_STARTDATE = String.valueOf(OP_VAR.Start_Date__c);
                  String FIELD_API = SMALL_API != null ? SMALL_API : '';
                  String FIELD_VALUE = String.valueOf(INDICATOR_VAR_SMALL) != null ? String.valueOf(INDICATOR_VAR_SMALL) : '';
                  
                  String rowStr = OPSCHED_NAME + ',' + OPSCHED_PHYSICALASSET + ',' + OPSCHED_STARTDATE + ',' + FIELD_API + ','+ FIELD_VALUE;
                  CSVROWVALUES_SMALL.add(rowStr);
                  TASK_CREATED = true;
              }
          }

          //GET CUPS
          String CUP_API = CONST_CupsTask_API + '_' + WEEK_NUM + '_' + scheduledDate.format('EEEE') + '__c';
          if(OP_VAR.get(CUP_API) != null){
            String CUP_VAL = String.valueOf(OP_VAR.get(CUP_API));
              if (!CUP_VAL.equals('0') && CUP_VAL != null) {
                if (Integer.valueOf(CUP_VAL) > 0){
                  TOTAL_CUPS = TOTAL_CUPS + Integer.valueOf(CUP_VAL);

                  String OPSCHED_NAME = OP_VAR.Name != null ? OP_VAR.Name : '';
                  String OPSCHED_PHYSICALASSET = OP_VAR.PhysicalAsset__r.Name != null ? OP_VAR.PhysicalAsset__r.Name : '';
                  String OPSCHED_STARTDATE = String.valueOf(OP_VAR.Start_Date__c);
                  String FIELD_API = CUP_API != null ? CUP_API : '';
                  String FIELD_VALUE = CUP_VAL;
                      
                  String rowStr = OPSCHED_NAME + ',' + OPSCHED_PHYSICALASSET + ',' + OPSCHED_STARTDATE + ',' + FIELD_API + ','+ FIELD_VALUE;
                  CSVROWVALUES_CUP.add(rowStr);
                  TASK_CREATED = true;
                }
              }
          }

          if(TASK_CREATED == true){
            NUM_WORKORDER++;
          }
        }
      }

      String csvColumnHeader;
      String docId;
      String myDomain = Url.getOrgDomainUrl().toExternalForm();
      String initialURL = myDomain + '/servlet/servlet.FileDownload?file=';
      List<Folder> folders = [SELECT Id, Name FROM Folder WHERE Name = 'Batch Pre-Load Reports'];
             
      if(!folders.isEmpty()){
          String documentName = 'PRELOAD_OPERATING_FOR_'+ String.valueOf(scheduledDate.format('MMMdd')) + ' ' + String.valueOf(Datetime.now());
          csvColumnHeader = 'NAME, PHYSICAL ASSET, START DATE, FIELD API, NUMBER OF TASK\n';
          String csvFile = csvColumnHeader + String.join(CSVROWVALUES_SMALL,'\n') + '\n' + String.join(CSVROWVALUES_LARGE,'\n') + '\n' + String.join(CSVROWVALUES_RINSE,'\n') + '\n' + String.join(CSVROWVALUES_CUP,'\n');
         
          Document doc = new Document(Name = documentName, Body = Blob.valueOf(csvFile), FolderId = folders[0].Id, Type = 'csv', ContentType='application/vnd.ms-excel');
          insert doc;

          docId = doc.Id;
      }

      if(!IS_CR_DAY) TOTAL_LARGE_CR = 0;
      String RET_STR = 'TOTAL_CUPS: ' + String.valueOf(TOTAL_CUPS)
                        + '\n' + 'TOTAL_RINSE: ' + String.valueOf(TOTAL_RINSE)
                        + '\n' + 'TOTAL_LARGE: ' + String.valueOf(TOTAL_LARGE)
                        + '\n' + 'TOTAL_LARGE_WITHCR: ' + String.valueOf(TOTAL_LARGE_CR)
                        + '\n' + 'TOTAL_SMALL: ' + String.valueOf(TOTAL_SMALL)
                        + '\n' + 'IS_NULL_BATCH_TYPE: ' + String.valueOf(isHoliday)
                        + '\n' + 'PRELOAD_REPORT_LINK: ' + initialURL + docId;
      
      return RET_STR;
    }
}