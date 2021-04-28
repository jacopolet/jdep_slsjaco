/**
 * @author        Karen Hung
 * @date          24.12.2019
 * @description   Apex batch class for generating Route Tasks DOO-2995
 * @revision(s)  
 */
global without sharing class TS_RouteTask_Batch implements Database.Batchable <sObject>{
    Map<String,Integer> numberOfTasksMap = new Map<String,Integer > { null => 0, 'null' => 0, '0' => 0, '1' => 1, '2' => 2, '3' => 3, '4' => 4, 'AM' => 1, 'PM' => 1};
    List<WorkOrderLineItem> tasks;
    String CONST_SmallTask_API = Label.TS_Operating_Small;
    String CONST_LargeTask_API = Label.TS_Operating_Large;
    String CONST_RinseTask_API = Label.TS_Operating_Rinse;
    String CONST_CupsTask_API = Label.TS_Operating_Cups;

    String CONST_SmallTask_ACTIVITY = 'Small';
    String CONST_LargeTask_ACTIVITY = 'Large';
    String CONST_RinseTask_Activity = 'Rinse';
    String CONST_CupsTask_Activity = 'Cups';

    String CONST_AM_Time = 'AM';
    String CONST_PM_Time = 'PM';

    String CONST_REG = 'regularbatch';
    String CONST_BWK = 'holidaybatchBWK';
    String CONST_FWD = 'holidaybatchFWD';
    String CONST_FWDBWK = 'holidaybatchFWDBWK';

    String CONST_COMFORTOP = 'Comfort Operating';
    String CONST_FULLOP = 'Full Operating';
    
    String CONST_WORKORDER_OP_RT = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('Operating (Route) Work Order').getRecordTypeId();
    String CONST_WORKORDER_OP_TYPE = Label.TS_Activity_Type_S20;
    String CONST_WOLI_OP_RT = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Operating Task').getRecordTypeId();
    String CONST_WOLI_OPEN_STATUS = 'Open';
    Boolean CONST_IS_SEND_EMAIL_WHEN_BATCH_FINISHED = Operating_Task__c.getInstance().Send_Email_Upon_Batch_Completion__c;
    String CONST_BATCH_ADMIN_EMAIL = Operating_Task__c.getInstance().Batch_Email__c;
    long starttime;
    Integer runCount;
    Boolean isFirstRun;

    private List<String> exception_List = new List<String>();
    
    Set<String> woliAssets = new Set<String>();

    private Exception[] errors = new Exception[0];
    Map<Integer,Boolean> futureholidayMap = new Map<Integer,Boolean>();
    Map<Integer,Boolean> pastholidayMap = new Map<Integer,Boolean>();
    Integer defaultstarttime;
    Integer defaultendtime;
    Date runDate;
    String batchType;
    
    Map<String, Set<Boolean>> location3POSetMap = new Map<String, Set<Boolean>>();
    Set<String> thirdPartyMachines = new Set<String>();
    Set<String> nonThirdPartyMachines = new Set<String>();

    Boolean SENDCOUNTER_LARGE = false;

    //This is to ensure that even if the default owner is Individual, the work order will be routed to the correct queue.
    public Map<String, String> countrySAPCodeMap = new Map<String, String>();
    public Map<String, String> queueNameIdMap = new Map<String, String>();

    public Boolean SOQL_OVERRIDE = false;
    public String NEW_SOQL_STRING;

    public Boolean RUN_INTEGRATION = true;

    //for Exception 
    public static Boolean hasException = false;
    public class TS_RouteTask_SchedulerException extends Exception {}
    
    //Karen Hung 19/1/2021 DOO-5148
    public static Map<Id,TS_Feature_Flag__mdt> featureFlags =  new Map<Id,TS_Feature_Flag__mdt>([SELECT Id, QualifiedApiName, Enable__c FROM TS_Feature_Flag__mdt WHERE QualifiedApiName != null]);
    public static Boolean flagEnabled = false;
    public static Boolean thirdPartyEnabled = false;
    public static Boolean surveySettingEnabled = false;
    public static Boolean operatingBucketEnabled = false;
    
    Map<String, Set<String>> surveySettingMap = new Map<String, Set<String>>();
    Map<String, String> activityAPIMap = new Map<String, String> { 'Large' => 'MTTO_FO_Large_Bucket__c', 'Small' => 'MTTO_FO_Small_Bucket__c', 'Cups' => 'MTTO_FO_Cups_Bucket__c'};

    global TS_RouteTask_Batch(){}

    /******************************************************************************
     *  Karen Hung
     *  15.01.2020 Batch Constructor
     ******************************************************************************/
    global TS_RouteTask_Batch(String btype, Date taskDate, Map<Integer, Boolean> fhMap, Map<Integer, Boolean> phMap, CountrySetting__c cs, Boolean first, Integer cnt) {
        CustomLogging.push('TS_RouteTask_Batch', 'TS_RouteTask_Batch');
        // initialize variables
        runDate = taskDate;
        futureholidayMap.putAll(fhMap);
        pastholidayMap.putAll(phMap);
        batchType = btype;
        defaultstarttime = Integer.valueOf(cs.DefaultStartTime__c);
        defaultendtime = Integer.valueOf(cs.DefaultEndTime__c);   

        SENDCOUNTER_LARGE = EVALUATEDATE(runDate, cs);

        isFirstRun = first;
        runCount = cnt;

        CustomLogging.pop();
    }

    /******************************************************************************
     * Karen Hung
     * 15.01.2020 Start
     ******************************************************************************/
    global Database.QueryLocator start(Database.BatchableContext BC) {
        CustomLogging.push('start', 'TS_RouteTask_Batch');
        CustomLogging.pop();
        return Database.getQueryLocator(getQuery());
    }

    /******************************************************************************
     * Karen Hung           
     * 15.01.2020 Method to execute regular and holiday tasks creation
     ******************************************************************************/
    global void execute(Database.BatchableContext BC, List<Route__c> routes) {
        CustomLogging.push('execute', 'TS_RouteTask_Batch');      

        WorkOrderLineItemTriggerHandler.IS_OPERATING_TASK = true;
        WorkOrderLineItemTriggerHandler.isRouteOperating = true;

        //CREATE A MAP OF COUNTRY CODES This is to ensure that even if the default owner is Individual, the work order will be routed to the correct queue.
        countrySAPCodeMap = TS_UtilityClass.countrySAPCodeUtility();

        //CREATE A MAP FOR SERVICE PLANNING QUEUE
        queueNameIdMap = TS_UtilityClass.queueNameIdMapUtility();

        try {
            System.debug('batchType: ' + batchType);
            
            //Karen Hung 19/1/2021 DOO-5161 feature flag for routetask change
            if(!featureFlags.isEmpty()){
                for(TS_Feature_Flag__mdt flag : featureFlags.values()){
                    if(flag.Enable__c && !Test.isRunningTest()){
                        if(flag.QualifiedApiName == 'DOO_5161_RouteTaskChange') thirdPartyEnabled = true;                        
                        if(flag.QualifiedApiName == 'DOO_5166_Indicate_Survey') surveySettingEnabled = true; 
                        if(flag.QualifiedApiName == 'DOO_5269_Operating_Task_Bucket') operatingBucketEnabled = true; 
                    }
                      
                }
            }
            if(surveySettingEnabled)surveySettingMap = WorkOrderTriggerHandler.getSurveySetting();
           
            List<OperatingSchedule__c> operatingSchedules = new List<OperatingSchedule__c>();
            
            List<String> assetIds = new List<String>();

            //Karen Hung 14.03.2020 updated query
            //get assets from routelineitem to be used for opsched query
            for(Route_Line_Item__c routeItem : [SELECT Id, RouteId__c, PhysicalAssetId__c, PhysicalAssetId__r.MothballAssetIndicator__c, PhysicalAssetid__r.AccountLocation__c, PhysicalAssetId__r.AssetStatus__c, RouteId__r.Account_Location__r.Third_Party_Resource__c 
                                                FROM Route_Line_Item__c WHERE RouteId__c IN :routes 
                                                AND PhysicalAssetId__c != null
                                                AND PhysicalAssetId__r.MothballAssetIndicator__c = false 
                                                AND PhysicalAssetId__r.AccountLocation__c != null
                                                AND (PhysicalAssetId__r.AssetStatus__c = :TS_Constants.PA_STATUS_ACTIVATED OR PhysicalAssetId__r.AssetStatus__c = :TS_Constants.PA_STATUS_PENDINGCANCELATION)]){
                assetIds.add(routeItem.PhysicalAssetId__c);
            }

            if(!assetIds.isEmpty()){
                DescribeSObjectResult operatingScheduleDescribe = OperatingSchedule__c.getSObjectType().getDescribe();
                List<String> fields = new List<String> (operatingScheduleDescribe.fields.getMap().keySet());
                String opSchedQuery = 'SELECT ' + String.join(fields, ',') + 
                                    ', PhysicalAsset__r.Product__c,  PhysicalAsset__r.SalesOrganization__c, PhysicalAsset__r.AccountLocation__c, PhysicalAsset__r.AccountLocation__r.Third_Party_Resource__c' +
                                    ', PhysicalAsset__r.Building__c,PhysicalAsset__r.AccountLocation__r.SAP_Customer_ID__c,PhysicalAsset__r.Floor__c' +
                                    ', PhysicalAsset__r.SoldTo__c, PhysicalAsset__r.OP_PreferredOperator__c, PhysicalAsset__r.MothballAssetIndicator__c, PhysicalAsset__r.Machine_Care__c' +
                                    ', PhysicalAsset__r.CounterReading__c, PhysicalAsset__r.Connected__c' + 
                                    ', PhysicalAsset__r.AssetStatus__c' + 
                                    ', Account_Location__r.Apttus_Config2__AccountId__c' +
                                    ' FROM OperatingSchedule__c' +
                                    ' WHERE Active__c = true ' +
                                    ' AND PhysicalAsset__c != null ' +
                                    ' AND TypeofContract__c != null ' +
                                    ' AND Schedule_Type__c = \'Regular\' ' +
                                    ' AND PhysicalAsset__c IN :assetIds ' +
                                    ' AND PhysicalAsset__r.EndDate__c >= :runDate'; //Karen Hung 16.6.2020 DOO-2695 include contract end date
                
                //List down operation schedules
                List<OperatingSchedule__c> opList = Database.query(opSchedQuery);
                operatingSchedules.addAll(opList);
            }

            if(!operatingSchedules.isEmpty()){
                if(batchType != null){
                    if (batchType.equals(CONST_REG)) {
                        runRegularBatch(runDate, operatingSchedules);
                    }else if (batchType.equals(CONST_FWD) || batchType.equals(CONST_BWK) || batchType.equals(CONST_FWDBWK)) {
                        runHolidayBatch(runDate.addDays(-1), operatingSchedules, futureholidayMap, pastholidayMap, batchType);
                    }

                //IF BATCH TYPE IS NULL - TOMMORROW IS HOLIDAY    
                } else {
                    List<OperatingSchedule__c> regularOperatingSchedules = new List<OperatingSchedule__c>();

                    //CHECK ALL OPERATING SCHEDULES IF SOME SHOULD BE SCHEDULED IN HOLIDAY
                    for(OperatingSchedule__c op : operatingSchedules){
                        if(op.Schedule_Tasks_for_Holiday__c) regularOperatingSchedules.add(op);
                    }

                    if(!regularOperatingSchedules.isEmpty()) runRegularBatch(runDate, regularOperatingSchedules);
                }               

            }

        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
            errors.add(ex);
        }

        CustomLogging.pop();
    }

    /******************************************************************************
     * Karen Hung
     * 15.01.2020    This method to perform actions when the batch is finished , call integration batch
     ******************************************************************************/
    global void finish(Database.BatchableContext BC) {
        CustomLogging.push('finish', 'TS_RouteTask_Batch');

        //Check queue capacity
        List<AsyncApexJob> routeIntegrationBatch = [SELECT Id, ApexClassID 
                                            FROM AsyncApexJob 
                                            WHERE Status IN ('Processing', 'Preparing') 
                                            AND ApexClassId IN (SELECT Id FROM ApexClass WHERE Name = 'TS_RouteTaskIntegration_Batch') ];
        
        //COUNT THE PROCESSING JOBS AND THOSE IN QUEUE
        Integer batchCount_ProcessingPreparing = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Processing\', \'Preparing\')');
        Integer batchCount_HoldingQueued = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Queued\', \'Holding\')');

        if (batchCount_ProcessingPreparing < 5 && batchCount_HoldingQueued < 100 && (routeIntegrationBatch == null || routeIntegrationBatch.size() == 0) && !Test.isRunningTest()) {
            if(RUN_INTEGRATION) Database.executeBatch(new TS_RouteTaskIntegration_Batch(runDate, isFirstRun, runCount), Integer.valueOf(System.Label.TS_RouteTaskIntBatchSize));
            //System.scheduleBatch(new TS_RouteTaskIntegration_Batch(runDate), 'Send Route Operating Tasks to Click', 1, 40);
        } else {
           //EXECUTE THIS SCHEDULER AGAIN IN NTH MINS.
           /*TS_RouteTaskIntegration_Scheduler schedClass = new TS_RouteTaskIntegration_Scheduler();
           Datetime dt = Datetime.now().addMinutes(10);
           String timeForScheduler = dt.format('s m H d M \'?\' yyyy');
           System.schedule('Water Filter Job Retry ' + timeForScheduler, timeForScheduler, schedClass);*/
        }
        
        //Karen Hung 19/1/2021 DOO-5148 generate and send post load to third party
        if(!featureFlags.isEmpty()){
            for(TS_Feature_Flag__mdt flag : featureFlags.values()){
                if(flag.QualifiedApiName == 'DOO_5148_third_party_postload' && flag.Enable__c){
                    flagEnabled = true;    
                }    
            }
        }
        if(flagEnabled || Test.isRunningTest()){
        	TS_PostLoadReport.generateAndSendReport(runDate,0);    
        }        

        //Display summary of failed records
       if (!exception_List.isEmpty()) {
            System.debug(TS_Constants.ERRBATCH_MSG_02 + exception_List.size());

            //Detailed log of errors
            for (String err : exception_List) {
                System.debug(err);
            }
        }

        CustomLogging.pop();
    }

    /******************************************************************************
     * Karen Hung
     * 15.01.2020    String query to be used in start
     ******************************************************************************/
    String getQuery() {
        CustomLogging.push('getQuery', 'TS_RouteTask_Batch');

        DescribeSObjectResult routeDescribe = Route__c.getSObjectType().getDescribe();
        List<String> fields = new List<String> (routeDescribe.fields.getMap().keySet());
        String DEFAULT_SOQL = 'SELECT ' + String.join(fields, ',') + ' FROM Route__c WHERE Account_Location__r.Mini_Sales_Organization__c = \'SAP_0111\'';

        CustomLogging.pop();

        if(SOQL_OVERRIDE){
            return NEW_SOQL_STRING;
        } else {
            return DEFAULT_SOQL;
        }
        
    }

    /******************************************************************************
     * Karen Hung
     * 15.01.2020   This method returns a set of Strings of physical asset ID of WOLI that has L task on the given date and contract type. 
                    This is to check if there is L task has been created before a new operating task will be created for tomorrow.
     ******************************************************************************/
    public Set<String> getTomorrowWOLI_list(Set<ID> lPhysicalAsset, Datetime lDate, String contracttype) {
        CustomLogging.push('getTomorrowWOLI_list', 'TS_RouteTask_Batch');
        set < String > woliList = new set < String > ();

        if (lPhysicalAsset.size() > 0 && contracttype.equals(CONST_FULLOP)) {
            for (Workorderlineitem woli: [SELECT id, PhysicalAsset__c FROM WorkOrderLineItem
                    WHERE WorkOrderLineItemType__c =: CONST_LargeTask_ACTIVITY //'Large' 
                    AND WorkOrderType__c =: CONST_WORKORDER_OP_TYPE // 'S20'
                    AND MachineCare__c =: CONST_FULLOP //'Full Operating' 
                    AND OP_247Customer__c = false
                    AND PhysicalAsset__c in: lPhysicalAsset

                    //XEN REYES DOO-3543 April 29, 2020
                    AND EarlyStart__c >=: lDate
                    AND EarlyStart__c <: ldate.addDays(1)
                    AND Status !=: TS_Constants.STATUS_COMPLETED
                    AND Status !=: TS_Constants.STATUS_CANCELED

                    /* AND SLADate__c >=: lDate
                    AND SLADate__c <: ldate.addDays(1) */

                ]) {

                wolilist.add(woli.PhysicalAsset__c);
            }

            System.debug('XEN 9/17 lDate: ' + lDate);
            System.debug('XEN 9/17 FULLOPP: ' + wolilist);
        }
        if (lPhysicalAsset.size() > 0 && contracttype.equals(CONST_COMFORTOP)) {
            for (Workorderlineitem woli: [SELECT id, PhysicalAsset__c FROM WorkOrderLineItem
                    WHERE WorkOrderLineItemType__c =: CONST_LargeTask_ACTIVITY //'Large' 
                    AND WorkOrderType__c =: CONST_WORKORDER_OP_TYPE //'S20'
                    AND MachineCare__c =: CONST_COMFORTOP //'Comfort Operating'                                       
                    AND PhysicalAsset__c in: lPhysicalAsset
                    
                    //XEN REYES DOO-3543 April 29, 2020
                    AND EarlyStart__c >=: lDate
                    AND EarlyStart__c <: ldate.addDays(1)
                    AND Status !=: TS_Constants.STATUS_COMPLETED
                    AND Status !=: TS_Constants.STATUS_CANCELED

                    /* AND SLADate__c >=: lDate
                    AND SLADate__c <: ldate.addDays(1) */
                    
                ]) {
                wolilist.add(woli.PhysicalAsset__c);
            }
        }
        CustomLogging.pop();
        return wolilist;
    }

 
    /******************************************************************************
     * Karen Hung
     * 15.01.2020  to return week number 1 or 2 on a scheduleddate from a start date
     ******************************************************************************/
    Integer getWeekNumber(Date startDate, Date scheduledDate) {
        CustomLogging.push('getWeekNumber', 'TS_RouteTask_Batch');
        Date d1 = startDate.toStartOfWeek();
        Date d2 = scheduledDate.toStartOfWeek();
        Integer numberOfWeeks = d1.daysBetween(d2) / 7;
        CustomLogging.pop();
        return Math.mod(numberOfWeeks, 2) == 0 ? 1 : 2;
    }

    /******************************************************************************
     * Karen Hung
     * 15.01.2020  to return pricebookMap (Sales Org => PB)
     ******************************************************************************/
    private Map<String, Pricebook2> getPriceBookMap(){
        CustomLogging.push('getPriceBookMap', 'TS_RouteTaskBatch');
        Map<String, Pricebook2> countryPricebookMap = new Map<String, Pricebook2>();
        for(Pricebook2 pb: [SELECT Id, Sales_Organization__c FROM Pricebook2 WHERE IsActive = true]){
            countryPricebookMap.put(pb.Sales_Organization__c, pb);
        }
        CustomLogging.pop();
        return countryPricebookMap;
    }

    /******************************************************************************
     * Karen Hung
     * 15.01.2020  to return pricebookentry map (Product+SalesOrg => PricebokEntry) 
     ******************************************************************************/
    private Map <String, PricebookEntry> createPriceBookEntryMap(List<OperatingSchedule__c> osl) {
        CustomLogging.push('createPriceBookEntryMap', 'TS_RouteTaskBatch');
        Map<String, PricebookEntry > prMap = new Map < String, PricebookEntry > ();

        Set<ID> productSet = new set<ID> ();
        Set<String > salesOrganizationSet = new Set < string > ();
        for (OperatingSchedule__c os: osl) {
            productSet.add(os.PhysicalAsset__r.Product__c);
            salesOrganizationSet.add(os.PhysicalAsset__r.SalesOrganization__c);
        }

        //GET PRICEBOOK ENTRY
        List<PricebookEntry> pbeList;
        if (!(productSet.isEmpty() || salesOrganizationSet.isEmpty())) {

            for (PricebookEntry pbe: [SELECT Id, Product2Id, Pricebook2Id, Sales_Organization__c, MeanTimeToOperateC__c, MeanTimeToOperateLM__c, MeanTimeToOperateSM__c, MTTO_FO_Cups_Bucket__c, MTTO_FO_Large_Bucket__c, MTTO_FO_Small_Bucket__c
                    FROM PricebookEntry
                    WHERE Product2Id IN: productSet AND Sales_Organization__c IN: salesOrganizationSet ORDER BY Sales_Organization__c ASC
                ]) {
                String pbeMapKey = String.valueOf(pbe.Product2Id) + pbe.Sales_Organization__c;

                prMap.put(pbeMapKey, pbe);
            }

        }

        CustomLogging.pop();
        return prMap;
    }


    /******************************************************************************
     * Karen Hung
     * 15.01.2020  to return set of asset Ids of operating schedules
     ******************************************************************************/
    Set<Id> getMachines (List<OperatingSchedule__c> operatingSchedules){
        CustomLogging.push('getMachines', 'TS_RouteTask_Batch');
        Set<Id> assets = new Set<Id>();

        for(OperatingSchedule__c ops : operatingSchedules){
            assets.add(ops.PhysicalAsset__c);
        }
        
        CustomLogging.pop();
        return assets;
    }

    /******************************************************************************
     * Karen Hung
     * 15.01.2020   Create WO & WOLI Task for batch type regularbatch
     ******************************************************************************/
    private void runRegularBatch(Date taskDate, List<OperatingSchedule__c> lOperatingSchedules) {
        CustomLogging.push('runRegularBatch', 'TS_RouteTask_Batch');

        Map<String, PricebookEntry> pBMap = createPriceBookEntryMap(lOperatingSchedules);
        Map<String, Pricebook2> pricebookMap = getPriceBookMap();

        Set<Id> machineSet = getMachines(lOperatingSchedules);

        Set<string> fullOP_Ltask_list = getTomorrowWOLI_list(machineSet, taskDate, CONST_FULLOP);
        Set<string> ComfortOp_Ltask_list = getTomorrowWOLI_list(machineSet, taskDate, CONST_COMFORTOP);

        List<WorkOrderLineItem> allTaskList = new List<WorkOrderLineItem> ();

        //Initialize the task date
        DateTime scheduledDate = taskDate; //addBusinessDays(taskDate,    

        try{

            //Create woli 
            for (OperatingSchedule__c operatingSchedule: lOperatingSchedules) {

                //SEND COUNTER READING FOR LARGE TASK
                Boolean SEND_COUNTER_VAR = SENDCOUNTER_LARGE;
                if(operatingSchedule.PhysicalAsset__r.CounterReading__c != 'Yes' ||
                    operatingSchedule.PhysicalAsset__r.Connected__c != 'No' ||
                    (operatingSchedule.PhysicalAsset__r.Machine_Care__c != 'Full Operating' && operatingSchedule.PhysicalAsset__r.Machine_Care__c != 'Comfort Operating')){
                    SEND_COUNTER_VAR = false;
                }
         
                // define task for rinse            
                String getRinseAPIName = CONST_RinseTask_API + '_' + getWeekNumber(operatingSchedule.Start_Date__c, scheduledDate.date()) + '_' + scheduledDate.format('EEEE') + '__c';
                boolean valueRinseTask = (boolean) operatingSchedule.get(getRinseAPIName);
                String timeIndicator = '0';

                // define task for large 
                String getLargeAPIName = CONST_LargeTask_API + '_' + getWeekNumber(operatingSchedule.Start_Date__c, scheduledDate.date()) + '_' + scheduledDate.format('EEEE') + '__c';
                String valueLargeTask = String.valueOf(operatingSchedule.get(getLargeAPIName)); // Large has value of 0 or 1

                Boolean isFullOpNon247_LTask_Found = false;
                if (operatingSchedule.TypeofContract__c.equals(CONST_FULLOP) &&
                    !operatingSchedule.OP_247Customer__c &&
                    fullOP_Ltask_list.contains(String.valueOf(OperatingSchedule.PhysicalAsset__c))) {
                    //system.debug('inside full operating 247, L woli is found');
                    isFullOpNon247_LTask_Found = true;
                }

                //check woli L task exist in Comfort
                Boolean isComfort_LTask_Found = false;
                if (operatingSchedule.TypeofContract__c.equals(CONST_COMFORTOP) &&
                    ComfortOp_Ltask_list.contains(String.valueOf(OperatingSchedule.PhysicalAsset__c))) {
                    isComfort_LTask_Found = true;

                }

                // specific condition if there is a postponed L task (already scheduled in woli ) on full operating non 24 7 contract             
                // Boolean isFullOpNon247_LTask_Found = operatingSchedule.TypeofContract__c.equals('Full Operating') && operatingSchedule.OP_247Customer__c && fullOP_Ltask_list.contains(OperatingSchedule.PhysicalAsset__c)==false? true:false;
                if (isFullOpNon247_LTask_Found || isComfort_LTask_Found) valueLargeTask = '0'; // it is zero because there is an L task has been planned

                List<WorkOrderLineItem> largeTaskList = new List <WorkOrderLineItem> ();

                if (!valueLargeTask.equals('0') && valueLargeTask != null) { //if there is  L task is planned
                    largeTaskList = createOperatingTasks(CONST_LargeTask_ACTIVITY, valueLargeTask, timeIndicator, operatingSchedule, scheduledDate, valueRinseTask, pBMap, SEND_COUNTER_VAR);
                    valueRinseTask = false; // L should win over S over rinse task.
                }

                if (!largeTaskList.isempty()) { // there is L task to be created and the generated work order record is used
                    allTaskList.addAll(largeTaskList);
                }

                // define task for small          
                timeIndicator = '0';
                String getsmallAPIName = CONST_SmallTask_API + '_' + getWeekNumber(operatingSchedule.Start_Date__c, scheduledDate.date()) + '_' + scheduledDate.format('EEEE') + '__c';
                String valueSmallTask = String.valueOf(operatingSchedule.get(getsmallAPIName));
                List <WorkOrderLineItem> smallTaskList = new List<WorkOrderLineItem> ();

                if (!valueSmallTask.equals('0') && valueSmallTask != null) {
                    if (valueSmallTask.equals(CONST_AM_Time) || valueSmallTask.equals(CONST_PM_Time)) {
                        timeIndicator = valueSmallTask;
                        valueSmallTask = isFullOpNon247_LTask_Found ? '0' : '1'; // specific condition if there is a postponed L task (already scheduled in woli ) on full operating non 24 7 contract  then reduce s by 1
                    } else if (Integer.valueOf(valueSmallTask) > 0 && isFullOpNon247_LTask_Found) {
                        Integer iv = Integer.valueOf(valueSmallTask) - 1;
                        valueSmallTask = string.valueof(iv);
                    }
                    smallTaskList = createOperatingTasks(CONST_SmallTask_ACTIVITY, valueSmallTask, timeIndicator, operatingSchedule, scheduledDate, valueRinseTask,  pBMap, false);
                    valueRinseTask = false; // L should win over S over rinse task.
                }
                if (!smallTaskList.isempty()) { // there is S task to be created and the generated work order record is used
                    allTaskList.addAll(smallTaskList);
                }

                // define task for cup
                timeIndicator = '0';
                String getcupsAPIName = CONST_CupsTask_API + '_' + getWeekNumber(operatingSchedule.Start_Date__c, scheduledDate.date()) + '_' + scheduledDate.format('EEEE') + '__c';
                String valueCupsTask = String.valueOf(operatingSchedule.get(getcupsAPIName));
                List<WorkOrderLineItem> cupTaskList = new List<WorkOrderLineItem > ();
                if (!valueCupsTask.equals('0') && valueCupsTask != null) {
                    cupTaskList = createOperatingTasks(CONST_CupsTask_ACTIVITY, valueCupsTask, timeIndicator, operatingSchedule, scheduledDate, valueRinseTask, pBMap, false);
                }
                if (!cupTaskList.isempty()) { //there is L task to be created and the generated work order record is used
                    allTaskList.addAll(cupTaskList);
                }
            }
           
            system.debug('Number of operating woli task (regular batch)' + allTaskList);

            //create work orders and populate the workorderIds in woli and insert the woli to be created
            if(!thirdPartyEnabled) generateRouteTasks(allTaskList,pricebookMap,taskDate);  
			if(thirdPartyEnabled) generateRouteTasks2(allTaskList,pricebookMap,taskDate);  
            
        } catch(Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }

        CustomLogging.pop();
    }
    
	/******************************************************************************
     * Karen Hung
     * 15.01.2020   Processes generation of WO and WOLI for Operating Route
     ******************************************************************************/
    public void generateRouteTasks(List<WorkOrderLineItem> allTaskList, Map<String, Pricebook2> countryPricebookMap, Date taskDate){
        CustomLogging.push('generateRouteTasks', 'TS_RouteTask_Batch');
        try{

            Integer starthour = defaultstarttime;
            Integer endhour = defaultendTime;
 
            if (!allTaskList.isempty()){

                Map<String, WorkOrder> routeSLAWOMap = new Map<String, WorkOrder>();
                List<WorkOrder> wotoInsertList = new List<WorkOrder>();
                List<WorkOrderLineItem> finalWolitoInsertList = new List<WorkOrderLineItem>();
                
                Set<String> routeWithTask = new Set<String>();
                Map<String, String> assetRouteMap = new Map<String, String>();
                Map<String, String> assetRouteItemMap = new Map<String, String>();
                Set<String> comboSet = new Set<String>(); //String combination of PhysicalAsset Id + WorkOrderLineItemType
                
                //mapping to be used to populate main service contact
                Map<Id, Id> accountAccLocMap = new Map<Id,Id>();
                Map<Id, Contact> accLocContactMap = new Map<Id,Contact>();
                
                //Karen Hung 26.02.2020 DOO-3914 Holiday Variables
                Map<String, Boolean> locationSLAisHolidayMap = new Map<String, Boolean>();
                //DOO-4355 23.04.2020
                Map<String, String> assetRouteLocationMap = new Map<String, String>();
                                
                //get all routes from items to be created //DOO-4355 23.04.2020 added route location in query
                for(Route_Line_Item__c rli : [SELECT Id, RouteId__c, RouteId__r.Account_Location__c, PhysicalAssetId__c FROM Route_Line_Item__c WHERE PhysicalAssetId__c IN :woliAssets]){
                	routeWithTask.add (rli.RouteId__c);
                    assetRouteMap.put(rli.PhysicalAssetId__c, rli.RouteId__c);
                    assetRouteItemMap.put(rli.PhysicalAssetId__c, rli.Id);
                    //DOO-4355 23.04.2020 put mapping of asset and route's account location
                    assetRouteLocationMap.put(rli.PhysicalAssetId__c, rli.RouteId__r.Account_Location__c);
                }
                
                //put mapping for account and accountlocation, to be used in Main_Service_Contact__c info
                for(Route__c rt: [SELECT Id, Account_Location__c, Account_Location__r.Apttus_Config2__AccountId__c FROM Route__c WHERE Id IN :routeWithTask]){
                    if(rt.Account_Location__r.Apttus_Config2__AccountId__c !=null){
                        accountAccLocMap.put(rt.Account_Location__r.Apttus_Config2__AccountId__c,rt.Account_Location__c);   
                    }
                }
                
                //put mapping for account location and main service person based on account in accountAccLocMap, to be used in Main_Service_Contact__c info
                for(Contact con : [SELECT Id, AccountId FROM Contact WHERE Main_Service_Person__c = TRUE AND AccountId IN :accountAccLocMap.keySet()]){
                    accLocContactMap.put(accountAccLocMap.get(con.AccountId), con);     
                }
                
                //Karen Hung 26.02.2020 DOO-3914 Get Custom Holidays from the account locations
                Map<Id, Customer_Holiday__c> holidayList = new Map<Id, Customer_Holiday__c>([SELECT Account_Location__c, From__c, Day__c FROM Customer_Holiday__c WHERE Account_Location__c IN :accountAccLocMap.values()]);
                Map<String, List<Customer_Holiday__c>> locationHolidaysMap = new  Map<String, List<Customer_Holiday__c>>();
                for(Customer_Holiday__c holiday : holidayList.values()){
                    if(locationHolidaysMap.containsKey(holiday.Account_Location__c)){
                        locationHolidaysMap.get(holiday.Account_Location__c).add(holiday);
                    }else{
                        locationHolidaysMap.put(holiday.Account_Location__c, new List<Customer_Holiday__c>{holiday});   
                    }
                }

                 //Get routes with regular and postponed schedule
                Set<String> regularRoute = new Set<String>();
                Set<String> postponedRoute = new Set<String>();
                Map<String, Set<Date>> routeSLAsMap = new Map<String, Set<Date>>();
                Set<Date> slaDates = new Set<Date>();
                for(WorkOrderLineItem woli : allTaskList){
                    
                    //Karen Hung 26.02.2020 DOO-3914 Flag customer holiday if sla falls within the location holiday
                    //DOO-4355 23.04.2020 changed key for locationholidaysMap
                    if(assetRouteLocationMap.containsKey(woli.PhysicalAsset__c) && locationHolidaysMap.containsKey(assetRouteLocationMap.get(woli.PhysicalAsset__c))){
                        for(Customer_Holiday__c locHoliday : locationHolidaysMap.get(assetRouteLocationMap.get(woli.PhysicalAsset__c))){
                            if(woli.SLADate__c.Date() >= locHoliday.From__c && woli.SLADate__c.Date() <= locHoliday.Day__c){
                                locationSLAisHolidayMap.put(assetRouteLocationMap.get(woli.PhysicalAsset__c) + String.valueOf(woli.SLADate__c), true);
                            }
                        }
                    }

                    //Karen Hung 26.02.2020 DOO-3914 execute only if SLA is NOT in custom holiday
                    //DOO-4355 23.04.2020 changed key for locationSLAisholidaysMap
                    if(assetRouteLocationMap.containsKey(woli.PhysicalAsset__c) && woli.SLADate__c != null && !locationSLAisHolidayMap.containsKey(assetRouteLocationMap.get(woli.PhysicalAsset__c) + String.valueOf(woli.SLADate__c))){
                        if(woli.SLADate__c.date() == taskDate){
                            if(assetRouteMap.containsKey(woli.PhysicalAsset__c)){
                                regularRoute.add(assetRouteMap.get(woli.PhysicalAsset__c));
                            }
                        }else{
                            if(assetRouteMap.containsKey(woli.PhysicalAsset__c)){
                                postponedRoute.add(assetRouteMap.get(woli.PhysicalAsset__c));
                                slaDates.add(woli.SLADate__c.date());
                                if(routeSLAsMap.containsKey(assetRouteMap.get(woli.PhysicalAsset__c))){
                                    routeSLAsMap.get(assetRouteMap.get(woli.PhysicalAsset__c)).add(woli.SLADate__c.date());
                                }else{
                                    routeSLAsMap.put(assetRouteMap.get(woli.PhysicalAsset__c) , new Set<Date>{woli.SLADate__c.date()});
                                }
                            }
                        }
                    }                    
                }
                
                //system.assertEquals(routeSLAsMap, null);
                //--------------REGULAR WORKORDER CREATION------

                //Check Routes with existing WorkOrder on taskdate
                Map<String, String> routeWoMap = new Map<String, String>();
                Map<WorkOrder, List<WorkOrderLineItem>> map_wo_woliList = new Map<WorkOrder, List<WorkOrderLineItem>>();
                for(WorkOrder wo : [SELECT Id, Account_Location__c, Route_Id__c, SLA_Date__c, SalesOrganization__c, (SELECT Id, WorkOrderId,WorkOrderLineItemType__c, PricebookEntryId FROM WorkOrderLineItems) FROM WorkOrder WHERE Route_Id__c IN :routeWithTask AND DAY_ONLY(SLA_Date__c) = :taskDate]){
                    
                    //Karen Hung 26.02.2020 DOO-3914 execute only if SLA is NOT in custom holiday
                    if(wo.SLA_Date__c != null && !locationSLAisHolidayMap.containsKey(wo.Account_Location__c + String.valueOf(wo.SLA_Date__c))){
                        routeWoMap.put(wo.Route_Id__c, wo.Id);
                        routeSLAWOMap.put(wo.Route_Id__c + String.valueOf(wo.SLA_Date__c.date()),wo);
                        for(WorkOrderLineItem woli : wo.WorkOrderLineItems){
                            if(map_wo_woliList.containsKey(wo)){
                                map_wo_woliList.get(wo).add(woli);    
                            }else{
                                map_wo_woliList.put(wo, new List<WorkOrderLineItem>{woli});    
                            }    
                        }
                    }
                    //map_wo_woliList.put(wo, wo.WorkOrderLineItems);
                }

                //Create WorkOrders Per Route for regular tasks. Exclude route with existing work orders in creation.
                for(Route__c route: [SELECT Id, Name, Unique_Route_Number__c, Preferred_Operator__c, Required_Operator__c, Account_Location__c,Account_Location__r.Apttus_Config2__AccountId__c,Account_Location__r.Mini_Sales_Organization__c, Account_Location__r.AverageRoutePrep__c, Account_Location__r.MTTTWithinSite__c, Account_Location__r.MTTOLocationSpecific__c FROM Route__c WHERE Id IN :regularRoute AND ID NOT IN :routeWoMap.keySet()]){
                    
                    WorkOrder workOrder = new WorkOrder();
                    workOrder.Route_Number__c = route.Unique_Route_Number__c;
                    workOrder.Route_Name__c = route.Name;
                    workOrder.Preferred_Operator__c = route.Preferred_Operator__c;
                    workOrder.Required_Operator__c = route.Required_Operator__c;
                    workOrder.Pricebook2Id = countryPricebookMap.get(route.Account_Location__r.Mini_Sales_Organization__c) != null ? countryPricebookMap.get(route.Account_Location__r.Mini_Sales_Organization__c).Id : null;
                    workOrder.RecordTypeId = CONST_WORKORDER_OP_RT;
                    workOrder.WorkOrderType__c = CONST_WORKORDER_OP_TYPE; 

                    if(accLocContactMap.containsKey(route.Account_Location__c)){
                        workOrder.Main_Service_Contact__c = accLocContactMap.get(route.Account_Location__c).Id;
                    }

                    workOrder.SalesOrganization__c = route.Account_Location__r.Mini_Sales_Organization__c;
                    workOrder.AccountId = route.Account_Location__r.Apttus_Config2__AccountId__c;
                    workOrder.Route_Id__c = route.Id;
                    workOrder.Early_Start_Date__c = DateTime.newInstance(taskDate.year(), taskDate.month(), taskDate.day(), starthour, 0, 0);
                    workOrder.SLA_Date__c = DateTime.newInstance(taskDate.year(), taskDate.month(), taskDate.day(), endhour, 0, 0);
                    workOrder.Account_Location__c = route.Account_Location__c;

                    //This is to ensure that even if the default owner is Individual, the work order will be routed to the correct queue.
                    workOrder.OwnerId = UserInfo.getUserId();
                    if(countrySAPCodeMap.containsKey(workOrder.SalesOrganization__c)){
                        if(queueNameIdMap.containsKey(countrySAPCodeMap.get(workOrder.SalesOrganization__c))){
                            workOrder.OwnerId = queueNameIdMap.get(countrySAPCodeMap.get(workOrder.SalesOrganization__c));
                        } 
                    }
                    routeSLAWOMap.put(route.Id + String.valueOf(workOrder.SLA_Date__c.date()),workOrder);
                    wotoInsertList.add(workOrder);
                }

                //------------POSTPONED WORKORDER CREATION------

                //Check Routes with existing WorkOrder on postponed taskdates
                Map<String, String> routeWoPostponedMap = new Map<String, String>();
                for(WorkOrder wo : [SELECT Id, Route_Id__c, SLA_Date__c FROM WorkOrder WHERE Route_Id__c IN :postponedRoute]){
                    if(routeSLAsMap.get(wo.Route_Id__c).contains(wo.SLA_Date__c.date())){
                        routeWoPostponedMap.put(wo.Route_Id__c, wo.Id);
                        routeSLAWOMap.put(wo.Route_Id__c + String.valueOf(wo.SLA_Date__c.date()),wo);
                    }
                }

                //Create WorkOrders Per Route for postponed tasks. Exclude route with existing work orders in creation.
                for(Route__c route: [SELECT Id, Name, Unique_Route_Number__c, Preferred_Operator__c, Required_Operator__c, Account_Location__c,Account_Location__r.Apttus_Config2__AccountId__c,Account_Location__r.Mini_Sales_Organization__c FROM Route__c WHERE Id IN :postponedRoute AND ID NOT IN :routeWoPostponedMap.keySet()]){
                    //system.assertEquals('CREATE WORKORDER', null);
                    if(routeSLAsMap.containsKey(route.Id)){
                        for(Date slaDate : routeSLAsMap.get(route.Id)){

                            WorkOrder workOrder = new WorkOrder();
                            workOrder.Route_Number__c = route.Unique_Route_Number__c;
                            workOrder.Route_Name__c = route.Name;
                            workOrder.Preferred_Operator__c = route.Preferred_Operator__c;
                            workOrder.Required_Operator__c = route.Required_Operator__c;
                            workOrder.Pricebook2Id = countryPricebookMap.get(route.Account_Location__r.Mini_Sales_Organization__c) != null ? countryPricebookMap.get(route.Account_Location__r.Mini_Sales_Organization__c).Id : null;
                            workOrder.RecordTypeId = CONST_WORKORDER_OP_RT;
                            workOrder.WorkOrderType__c = CONST_WORKORDER_OP_TYPE; 

                            if(accLocContactMap.containsKey(route.Account_Location__c)){
                                workOrder.Main_Service_Contact__c = accLocContactMap.get(route.Account_Location__c).Id;
                            }

                            workOrder.SalesOrganization__c = route.Account_Location__r.Mini_Sales_Organization__c;
                            workOrder.AccountId = route.Account_Location__r.Apttus_Config2__AccountId__c;
                            workOrder.Route_Id__c = route.Id;
                            workOrder.Early_Start_Date__c = DateTime.newInstance(slaDate.year(), slaDate.month(), slaDate.day(), starthour, 0, 0);
                            workOrder.SLA_Date__c = DateTime.newInstance(slaDate.year(), slaDate.month(), slaDate.day(), endhour, 0, 0);
                            workOrder.Account_Location__c = route.Account_Location__c;

                            //This is to ensure that even if the default owner is Individual, the work order will be routed to the correct queue.
                            workOrder.OwnerId = UserInfo.getUserId();
                            if(countrySAPCodeMap.containsKey(workOrder.SalesOrganization__c)){
                                if(queueNameIdMap.containsKey(countrySAPCodeMap.get(workOrder.SalesOrganization__c))){
                                    workOrder.OwnerId = queueNameIdMap.get(countrySAPCodeMap.get(workOrder.SalesOrganization__c));
                                } 
                            }

                            routeSLAWOMap.put(route.Id + String.valueOf(workOrder.SLA_Date__c.date()), workOrder);
                            wotoInsertList.add(workOrder);

                        }
                    }
                }

                //Insert all WorkOrders for Insert
                if(!wotoInsertList.isEmpty()){
                    Database.SaveResult[] lsr2 = Database.insert(wotoInsertList, false);
                    //Custom Logging 
                    INSERT_LOGGING(lsr2, 'WorkOrder Insert'); 
                }

                //link all woli to inserted workorder and route line item if applicable and add woli in finalwolito insert list
                for(WorkOrderLineItem woli : allTaskList){
                    
                    //Karen Hung 26.02.2020 DOO-3914 execute only if SLA is NOT in custom holiday
                    if(woli.SLADate__c != null && !locationSLAisHolidayMap.containsKey(woli.AccountLocation__c + String.valueOf(woli.SLADate__c))){
                        //populate Route Line Item
                        if(assetRouteItemMap.containsKey(woli.PhysicalAsset__c)){
                            woli.Route_Line_Item__c = assetRouteItemMap.get(woli.PhysicalAsset__c);
                        }
                        //populate Work Order
                        if(assetRouteMap.containsKey(woli.PhysicalAsset__c) && routeSLAWOMap.containsKey(assetRouteMap.get(woli.PhysicalAsset__c) + String.valueOf(woli.SLADate__c.date()))){

                            woli.WorkOrderId = routeSLAWOMap.get(assetRouteMap.get(woli.PhysicalAsset__c) + String.valueOf(woli.SLADate__c.date())).Id;
                            finalWolitoInsertList.add(woli);
                            comboSet.add(woli.PhysicalAsset__c + woli.WorkOrderLineItemType__c);
                        }
                    }
        
                }

                //For Sequence Number stamping
                if(!finalWolitoInsertList.isEmpty()){
                    
                    //Insert FINAL WOLI
                    Database.SaveResult[] saveResults = Database.insert(finalWolitoInsertList, false);
                    INSERT_LOGGING(saveResults, 'WorkOrderLineItem Insert');

                    /********************************************************************* */
                    //CALL QUEUEABLE PROCESS HERE TO UPDATE SEQUENCING AND MTTO CALCULATION
                    /********************************************************************* */

                    TS_QueueableProcesses cs = new TS_QueueableProcesses();
                    cs.METHOD_UPDATESEQUENCE_ACTUALDURATION = true;
                    cs.taskDate = taskDate;
                    cs.runDate = runDate;
                    cs.comboSet = comboSet;
                    cs.finalWolitoInsertList = finalWolitoInsertList;
                    cs.map_wo_woliList = map_wo_woliList;
                    cs.wotoInsertList = wotoInsertList;
                    System.enqueueJob(cs);

                }
                
                //update Work Order to flag click sending
                /*Map<Id, WorkOrder> workOrdertoUpdate = new Map<Id, WorkOrder>();
                for(WorkOrderLineItem insertedWoli : finalWolitoInsertList){
                    if(insertedWoli.Id != null){
                        WorkOrder wo = new WorkOrder();
                        wo.Id = insertedWoli.WorkOrderId;
                        wo.Click_Ready__c = true;
                        workOrdertoUpdate.put(wo.Id, wo);
                    }
                }

                if(!workOrdertoUpdate.isEmpty()){
                    Database.SaveResult[] saveResults = Database.update(workOrdertoUpdate.values(), false);
                    INSERT_LOGGING(saveResults,'WorkOrder Update'); 
                }*/                   
            }

        }catch(Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        CustomLogging.pop();
    }    

    /******************************************************************************
     * Karen Hung
     * 15.01.2020   Processes generation of WO and WOLI for Operating Route
     ******************************************************************************/
    public void generateRouteTasks2(List<WorkOrderLineItem> allTaskList, Map<String, Pricebook2> countryPricebookMap, Date taskDate){
        CustomLogging.push('generateRouteTasks2', 'TS_RouteTask_Batch');
        try{

            Integer starthour = defaultstarttime;
            Integer endhour = defaultendTime;
 
            if (!allTaskList.isempty()){

                Map<String, WorkOrder> routeSLAWOMap = new Map<String, WorkOrder>();
                List<WorkOrder> wotoInsertList = new List<WorkOrder>();
                List<WorkOrderLineItem> finalWolitoInsertList = new List<WorkOrderLineItem>();
                
                Set<String> routeWithTask = new Set<String>();
                Map<String, String> assetRouteMap = new Map<String, String>();
                Map<String, String> assetRouteItemMap = new Map<String, String>();
                Set<String> comboSet = new Set<String>(); //String combination of PhysicalAsset Id + WorkOrderLineItemType
                
                //mapping to be used to populate main service contact
                Map<Id, Id> accountAccLocMap = new Map<Id,Id>();
                Map<Id, Contact> accLocContactMap = new Map<Id,Contact>();
                
                //Karen Hung 26.02.2020 DOO-3914 Holiday Variables
                Map<String, Boolean> locationSLAisHolidayMap = new Map<String, Boolean>();
                //DOO-4355 23.04.2020
                Map<String, String> assetRouteLocationMap = new Map<String, String>();
                                
                //get all routes from items to be created //DOO-4355 23.04.2020 added route location in query
                for(Route_Line_Item__c rli : [SELECT Id, RouteId__c, RouteId__r.Account_Location__c, PhysicalAssetId__c FROM Route_Line_Item__c WHERE PhysicalAssetId__c IN :woliAssets]){
                	routeWithTask.add(rli.RouteId__c);
                    assetRouteMap.put(rli.PhysicalAssetId__c, rli.RouteId__c);
                    assetRouteItemMap.put(rli.PhysicalAssetId__c, rli.Id);
                    //DOO-4355 23.04.2020 put mapping of asset and route's account location
                    assetRouteLocationMap.put(rli.PhysicalAssetId__c, rli.RouteId__r.Account_Location__c);
                }
                
                //Karen Hung DOO-5166 set of location with third party operator
                Set<String> locationWith3PO = new Set<String>();
                //put mapping for account and accountlocation, to be used in Main_Service_Contact__c info
                for(Route__c rt: [SELECT Id, Account_Location__c, Account_Location__r.Apttus_Config2__AccountId__c,Account_Location__r.Third_Party_Resource__c FROM Route__c WHERE Id IN :routeWithTask]){
                    if(rt.Account_Location__r.Apttus_Config2__AccountId__c !=null){
                        accountAccLocMap.put(rt.Account_Location__r.Apttus_Config2__AccountId__c,rt.Account_Location__c);   
                    }
                    //Karen Hung DOO-5166
                    if(rt.Account_Location__r.Third_Party_Resource__c !=null){
                        locationWith3PO.add(rt.Account_Location__c);    
                    }
                }
                
                //put mapping for account location and main service person based on account in accountAccLocMap, to be used in Main_Service_Contact__c info
                for(Contact con : [SELECT Id, AccountId FROM Contact WHERE Main_Service_Person__c = TRUE AND AccountId IN :accountAccLocMap.keySet()]){
                    accLocContactMap.put(accountAccLocMap.get(con.AccountId), con);     
                }
                
                //Karen Hung 26.02.2020 DOO-3914 Get Custom Holidays from the account locations
                Map<Id, Customer_Holiday__c> holidayList = new Map<Id, Customer_Holiday__c>([SELECT Account_Location__c, From__c, Day__c FROM Customer_Holiday__c WHERE Account_Location__c IN :accountAccLocMap.values()]);
                Map<String, List<Customer_Holiday__c>> locationHolidaysMap = new  Map<String, List<Customer_Holiday__c>>();
                for(Customer_Holiday__c holiday : holidayList.values()){
                    if(locationHolidaysMap.containsKey(holiday.Account_Location__c)){
                        locationHolidaysMap.get(holiday.Account_Location__c).add(holiday);
                    }else{
                        locationHolidaysMap.put(holiday.Account_Location__c, new List<Customer_Holiday__c>{holiday});   
                    }
                }

                 //Get routes with regular and postponed schedule
                Set<String> regularRoute = new Set<String>();
                Set<String> postponedRoute = new Set<String>();
                Map<String, Set<Boolean>> regularRoute2 = new Map<String, Set<Boolean>>();
                Map<String, Set<Boolean>> postponedRoute2 = new Map<String, Set<Boolean>>();
                Map<String, Set<Date>> routeSLAsMap = new Map<String, Set<Date>>();
                Set<Date> slaDates = new Set<Date>();
                
                for(WorkOrderLineItem woli : allTaskList){
                    
                    Boolean thirdPartyTask = woli.ExecutingEngineer__c != null;
                    
                    //Karen Hung 26.02.2020 DOO-3914 Flag customer holiday if sla falls within the location holiday
                    //DOO-4355 23.04.2020 changed key for locationholidaysMap
                    if(assetRouteLocationMap.containsKey(woli.PhysicalAsset__c) && locationHolidaysMap.containsKey(assetRouteLocationMap.get(woli.PhysicalAsset__c))){
                        for(Customer_Holiday__c locHoliday : locationHolidaysMap.get(assetRouteLocationMap.get(woli.PhysicalAsset__c))){
                            if(woli.SLADate__c.Date() >= locHoliday.From__c && woli.SLADate__c.Date() <= locHoliday.Day__c){
                                locationSLAisHolidayMap.put(assetRouteLocationMap.get(woli.PhysicalAsset__c) + String.valueOf(woli.SLADate__c), true);
                            }
                        }
                    }

                    //Karen Hung 26.02.2020 DOO-3914 execute only if SLA is NOT in custom holiday
                    //DOO-4355 23.04.2020 changed key for locationSLAisholidaysMap
                    if(assetRouteLocationMap.containsKey(woli.PhysicalAsset__c) && woli.SLADate__c != null && !locationSLAisHolidayMap.containsKey(assetRouteLocationMap.get(woli.PhysicalAsset__c) + String.valueOf(woli.SLADate__c))){
                       
                        if(woli.SLADate__c.date() == taskDate){
                            if(assetRouteMap.containsKey(woli.PhysicalAsset__c)){
                                String routeStr = assetRouteMap.get(woli.PhysicalAsset__c);
                                regularRoute.add(routeStr);
                                if(regularRoute2.containsKey(routeStr)){
                                	regularRoute2.get(routeStr).add(thirdPartyTask); 
                                }else{
                                    regularRoute2.put(routeStr,new Set<Boolean>{thirdPartyTask});     
                                }
                                
                            }
                        }else{
                            if(assetRouteMap.containsKey(woli.PhysicalAsset__c)){
                                String routeStr = assetRouteMap.get(woli.PhysicalAsset__c);
                                postponedRoute.add(assetRouteMap.get(woli.PhysicalAsset__c));
                               
                                slaDates.add(woli.SLADate__c.date());
                                if(routeSLAsMap.containsKey(assetRouteMap.get(woli.PhysicalAsset__c))){
                                    routeSLAsMap.get(assetRouteMap.get(woli.PhysicalAsset__c)).add(woli.SLADate__c.date());
                                }else{
                                    routeSLAsMap.put(assetRouteMap.get(woli.PhysicalAsset__c) , new Set<Date>{woli.SLADate__c.date()});
                                }
                                if(postponedRoute2.containsKey(routeStr)){
                                    postponedRoute2.get(routeStr).add(thirdPartyTask); 
                                }else{
                                    postponedRoute2.put(routeStr,new Set<Boolean>{thirdPartyTask});     
                                }
                            }
                        }
                    }                    
                }
                
                //--------------REGULAR WORKORDER CREATION------

                //Check Routes with existing WorkOrder on taskdate
                Map<String, String> routeWoMap = new Map<String, String>();
                Set<String> routeSet = new Set<String>();
                Map<WorkOrder, List<WorkOrderLineItem>> map_wo_woliList = new Map<WorkOrder, List<WorkOrderLineItem>>();
                for(WorkOrder wo : [SELECT Id,Third_Party__c, Account_Location__c, Route_Id__c, SLA_Date__c, SalesOrganization__c, (SELECT Id, WorkOrderId,WorkOrderLineItemType__c, PricebookEntryId FROM WorkOrderLineItems) FROM WorkOrder WHERE Route_Id__c IN :routeWithTask AND DAY_ONLY(SLA_Date__c) = :taskDate]){
                    
                    //Karen Hung 26.02.2020 DOO-3914 execute only if SLA is NOT in custom holiday
                    if(wo.SLA_Date__c != null && !locationSLAisHolidayMap.containsKey(wo.Account_Location__c + String.valueOf(wo.SLA_Date__c))){
                        routeWoMap.put(wo.Route_Id__c + String.valueOf(wo.Third_Party__c), wo.Id);
                        routeSLAWOMap.put(wo.Route_Id__c + String.valueOf(wo.SLA_Date__c.date()) + String.valueOf(wo.Third_Party__c),wo);
                        routeSet.add(wo.Route_Id__c);
                        for(WorkOrderLineItem woli : wo.WorkOrderLineItems){
                            if(map_wo_woliList.containsKey(wo)){
                                map_wo_woliList.get(wo).add(woli);    
                            }else{
                                map_wo_woliList.put(wo, new List<WorkOrderLineItem>{woli});    
                            }    
                        }
                    }
                    //map_wo_woliList.put(wo, wo.WorkOrderLineItems);
                }

                //Create WorkOrders Per Route for regular tasks. Exclude route with existing work orders in creation.
                for(Route__c route: [SELECT Id, Name, Unique_Route_Number__c, Preferred_Operator__c, Required_Operator__c, Account_Location__c,Account_Location__r.Apttus_Config2__AccountId__c,Account_Location__r.Mini_Sales_Organization__c, Account_Location__r.AverageRoutePrep__c, Account_Location__r.MTTTWithinSite__c, Account_Location__r.MTTOLocationSpecific__c, Account_Location__r.Third_Party_Resource__c FROM Route__c WHERE Id IN :regularRoute]){
                    if(regularRoute2.containsKey(route.Id)){
                        for(Boolean routeThirdParty :regularRoute2.get(route.Id)){
                            //exclude existing already
                            if(!routeWoMap.containsKey(route.Id + String.valueOf(routeThirdParty))){ 
                                WorkOrder workOrder = new WorkOrder();
                                workOrder.Route_Number__c = route.Unique_Route_Number__c;
                                workOrder.Route_Name__c = route.Name;
                                workOrder.Preferred_Operator__c = route.Preferred_Operator__c;
                                workOrder.Required_Operator__c = route.Required_Operator__c;
                                workOrder.Pricebook2Id = countryPricebookMap.get(route.Account_Location__r.Mini_Sales_Organization__c) != null ? countryPricebookMap.get(route.Account_Location__r.Mini_Sales_Organization__c).Id : null;
                                workOrder.RecordTypeId = CONST_WORKORDER_OP_RT;
                                workOrder.WorkOrderType__c = CONST_WORKORDER_OP_TYPE; 
                                
                                if(accLocContactMap.containsKey(route.Account_Location__c)){
                                    workOrder.Main_Service_Contact__c = accLocContactMap.get(route.Account_Location__c).Id;
                                }
                                
                                workOrder.Third_Party__c = routeThirdParty;
                                
                                if(routeThirdParty){
                                    workOrder.Status = TS_Constants.WOLI_STATUS_SCHEDULED;
                                    workOrder.ExecutingEngineer__c = route.Account_Location__r.Third_Party_Resource__c;
                                    workOrder.Travel_Start_Time__c = DateTime.newInstance(taskDate.year(), taskDate.month(), taskDate.day(), starthour, 0, 0);
                                    workOrder.Travel_Stop_Time__c = DateTime.newInstance(taskDate.year(), taskDate.month(), taskDate.day(), starthour, 0, 0);
                                    workOrder.StartDate__c = DateTime.newInstance(taskDate.year(), taskDate.month(), taskDate.day(), starthour, 0, 0);
                                    workOrder.EndDate__c = DateTime.newInstance(taskDate.year(), taskDate.month(), taskDate.day(), starthour, 0, 0);
                                }
                                
                                workOrder.SalesOrganization__c = route.Account_Location__r.Mini_Sales_Organization__c;
                                workOrder.AccountId = route.Account_Location__r.Apttus_Config2__AccountId__c;
                                workOrder.Route_Id__c = route.Id;
                                workOrder.Early_Start_Date__c = DateTime.newInstance(taskDate.year(), taskDate.month(), taskDate.day(), starthour, 0, 0);
                                workOrder.SLA_Date__c = DateTime.newInstance(taskDate.year(), taskDate.month(), taskDate.day(), endhour, 0, 0);
                                workOrder.Account_Location__c = route.Account_Location__c;
                                
                                if(operatingBucketEnabled) workOrder.OPG_Source__c = 'OPG Daily Batch';
                                
                                //This is to ensure that even if the default owner is Individual, the work order will be routed to the correct queue.
                                workOrder.OwnerId = UserInfo.getUserId();
                                if(countrySAPCodeMap.containsKey(workOrder.SalesOrganization__c)){
                                    if(queueNameIdMap.containsKey(countrySAPCodeMap.get(workOrder.SalesOrganization__c))){
                                        workOrder.OwnerId = queueNameIdMap.get(countrySAPCodeMap.get(workOrder.SalesOrganization__c));
                                    } 
                                }
                                routeSLAWOMap.put(route.Id + String.valueOf(workOrder.SLA_Date__c.date()) + String.valueOf(routeThirdParty),workOrder);
                                wotoInsertList.add(workOrder);    
                            }                               
                        }   
                    }   
                }

                //------------POSTPONED WORKORDER CREATION------

                //Check Routes with existing WorkOrder on postponed taskdates
                Map<String, String> routeWoPostponedMap = new Map<String, String>();
                for(WorkOrder wo : [SELECT Id, Route_Id__c, SLA_Date__c, Third_Party__c FROM WorkOrder WHERE Route_Id__c IN :postponedRoute]){
                    if(routeSLAsMap.get(wo.Route_Id__c).contains(wo.SLA_Date__c.date())){
                        routeWoPostponedMap.put(wo.Route_Id__c + String.valueOf(wo.Third_Party__c), wo.Id);
                        routeSLAWOMap.put(wo.Route_Id__c + String.valueOf(wo.SLA_Date__c.date()) + String.valueOf(wo.Third_Party__c),wo);
                    }
                }

                //Create WorkOrders Per Route for postponed tasks. Exclude route with existing work orders in creation.
                for(Route__c route: [SELECT Id, Name, Unique_Route_Number__c, Preferred_Operator__c, Required_Operator__c, Account_Location__c,Account_Location__r.Apttus_Config2__AccountId__c,Account_Location__r.Mini_Sales_Organization__c,Account_Location__r.Third_Party_Resource__c FROM Route__c WHERE Id IN :postponedRoute]){
                    //system.assertEquals('CREATE WORKORDER', null);
                    if(postponedRoute2.containsKey(route.Id)){
                        for(Boolean routeThirdPartyPostponed : postponedRoute2.get(route.Id)){
                            //exclude existing already
                            if(!routeWoPostponedMap.containsKey(route.Id + String.valueOf(routeThirdPartyPostponed))){                                
                                for(Date slaDate : routeSLAsMap.get(route.Id)){							
                                    if(!routeSLAWOMap.containsKey(route.Id + String.valueOf(slaDate) + String.valueOf(routeThirdPartyPostponed))){
                                        WorkOrder workOrder = new WorkOrder();
                                        workOrder.Route_Number__c = route.Unique_Route_Number__c;
                                        workOrder.Route_Name__c = route.Name;
                                        workOrder.Preferred_Operator__c = route.Preferred_Operator__c;
                                        workOrder.Required_Operator__c = route.Required_Operator__c;
                                        workOrder.Pricebook2Id = countryPricebookMap.get(route.Account_Location__r.Mini_Sales_Organization__c) != null ? countryPricebookMap.get(route.Account_Location__r.Mini_Sales_Organization__c).Id : null;
                                        workOrder.RecordTypeId = CONST_WORKORDER_OP_RT;
                                        workOrder.WorkOrderType__c = CONST_WORKORDER_OP_TYPE; 
                                        
                                        if(accLocContactMap.containsKey(route.Account_Location__c)){
                                            workOrder.Main_Service_Contact__c = accLocContactMap.get(route.Account_Location__c).Id;
                                        }
                                        
                                        workOrder.Third_Party__c = routeThirdPartyPostponed;
                                        
                                        if(routeThirdPartyPostponed){
                                            workOrder.Status = TS_Constants.WOLI_STATUS_SCHEDULED;
                                            workOrder.ExecutingEngineer__c = route.Account_Location__r.Third_Party_Resource__c;
                                            workOrder.Travel_Start_Time__c = DateTime.newInstance(taskDate.year(), taskDate.month(), taskDate.day(), starthour, 0, 0);
                                            workOrder.Travel_Stop_Time__c = DateTime.newInstance(taskDate.year(), taskDate.month(), taskDate.day(), starthour, 0, 0);
                                            workOrder.StartDate__c = DateTime.newInstance(taskDate.year(), taskDate.month(), taskDate.day(), starthour, 0, 0);
                                            workOrder.EndDate__c = DateTime.newInstance(taskDate.year(), taskDate.month(), taskDate.day(), starthour, 0, 0);
                                        }
                                        
                                        workOrder.SalesOrganization__c = route.Account_Location__r.Mini_Sales_Organization__c;
                                        workOrder.AccountId = route.Account_Location__r.Apttus_Config2__AccountId__c;
                                        workOrder.Route_Id__c = route.Id;
                                        workOrder.Early_Start_Date__c = DateTime.newInstance(slaDate.year(), slaDate.month(), slaDate.day(), starthour, 0, 0);
                                        workOrder.SLA_Date__c = DateTime.newInstance(slaDate.year(), slaDate.month(), slaDate.day(), endhour, 0, 0);
                                        workOrder.Account_Location__c = route.Account_Location__c;
                                        
                                        if(operatingBucketEnabled) workOrder.OPG_Source__c = 'OPG Daily Batch';
                                        
                                        //This is to ensure that even if the default owner is Individual, the work order will be routed to the correct queue.
                                        workOrder.OwnerId = UserInfo.getUserId();
                                        if(countrySAPCodeMap.containsKey(workOrder.SalesOrganization__c)){
                                            if(queueNameIdMap.containsKey(countrySAPCodeMap.get(workOrder.SalesOrganization__c))){
                                                workOrder.OwnerId = queueNameIdMap.get(countrySAPCodeMap.get(workOrder.SalesOrganization__c));
                                            } 
                                        }
                                        
                                        routeSLAWOMap.put(route.Id + String.valueOf(workOrder.SLA_Date__c.date()) + String.valueOf(routeThirdPartyPostponed) , workOrder);
                                        wotoInsertList.add(workOrder); 
                                    }
                                } 
                            }
                        }
                    }
                }

                //Insert all WorkOrders for Insert
                if(!wotoInsertList.isEmpty()){
                    Database.SaveResult[] lsr2 = Database.insert(wotoInsertList, false);
                    //Custom Logging 
                    INSERT_LOGGING(lsr2, 'WorkOrder Insert'); 
                }
				
                //link all woli to inserted workorder and route line item if applicable and add woli in finalwolito insert list
                for(WorkOrderLineItem woli : allTaskList){
                    
                    Boolean thirdParty = woli.ExecutingEngineer__c !=null;
                    //Karen Hung 26.02.2020 DOO-3914 execute only if SLA is NOT in custom holiday
                    if(woli.SLADate__c != null && !locationSLAisHolidayMap.containsKey(woli.AccountLocation__c + String.valueOf(woli.SLADate__c))){
                        //populate Route Line Item
                        if(assetRouteItemMap.containsKey(woli.PhysicalAsset__c)){
                            woli.Route_Line_Item__c = assetRouteItemMap.get(woli.PhysicalAsset__c);
                        }
                        //populate Work Order
                        if(assetRouteMap.containsKey(woli.PhysicalAsset__c) && routeSLAWOMap.containsKey(assetRouteMap.get(woli.PhysicalAsset__c) + String.valueOf(woli.SLADate__c.date()) + String.valueOf(thirdParty))){

                            woli.WorkOrderId = routeSLAWOMap.get(assetRouteMap.get(woli.PhysicalAsset__c) + String.valueOf(woli.SLADate__c.date()) + String.valueOf(thirdParty)).Id;
                            //Karen Hung DOO-5166 put value if location has third party operator and survey is applicable
                            if(surveySettingEnabled && locationWith3PO.contains(woli.AccountLocation__c) && surveySettingMap.containsKey(TS_Constants.TS_SalesOrg_Netherlands + woli.WorkOrderType__c + woli.WorkOrderLineItemType__c) && woli.WorkOrderLineItemType__c == TS_Constants.ACTIVITY_LARGE){
                                String surveyType;
                                List<String> surveyTypes = new List<String>();
                                surveyTypes.addAll(surveySettingMap.get(TS_Constants.TS_SalesOrg_Netherlands + woli.WorkOrderType__c + woli.WorkOrderLineItemType__c));
                                for(String surType : surveyTypes){
                                    surveyType = surveyType == null ? surType : (surveyType + ';' + surType);
                                }
                                woli.Enabled_Survey_in_Click__c = surveyType;
                            }
                                
                            finalWolitoInsertList.add(woli);
                            comboSet.add(woli.PhysicalAsset__c + woli.WorkOrderLineItemType__c);
                        }
                    }
        
                }
                               
				system.debug('allTaskList size ' + allTaskList.size());
                system.debug('finalWolitoInsertList size ' + finalWolitoInsertList.size());
                
                //For Sequence Number stamping
                if(!finalWolitoInsertList.isEmpty()){
                    
                    //Insert FINAL WOLI
                    Database.SaveResult[] saveResults = Database.insert(finalWolitoInsertList, false);
                    INSERT_LOGGING(saveResults, 'WorkOrderLineItem Insert');
                    
                    //DOO-5166 17/2/2020 update Enabled Survey in Click field of workorders
                    if(surveySettingEnabled && !wotoInsertList.isEmpty()){
                        List<WorkOrder> forUpdateSurvey = workOrderSurveys(wotoInsertList);
                        if(!forUpdateSurvey.isEmpty()){
                            //Update WorkOrders
                            Database.SaveResult[] saveResults2 = Database.update(forUpdateSurvey, false);
                            INSERT_LOGGING(saveResults2, 'WorkOrder Survey Update');    
                        }
                    }

                    /********************************************************************* */
                    //CALL QUEUEABLE PROCESS HERE TO UPDATE SEQUENCING AND MTTO CALCULATION
                    /********************************************************************* */

                    TS_QueueableProcesses cs = new TS_QueueableProcesses();
                    cs.METHOD_UPDATESEQUENCE_ACTUALDURATION = true;
                    cs.taskDate = taskDate;
                    cs.runDate = runDate;
                    cs.comboSet = comboSet;
                    cs.finalWolitoInsertList = finalWolitoInsertList;
                    cs.map_wo_woliList = map_wo_woliList;
                    cs.wotoInsertList = wotoInsertList;
                    System.enqueueJob(cs);
                    
                }
                               
            }

        }catch(Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        CustomLogging.pop();
    }    
    
    /*
     * Karen Hung DOO-5166
	 * Method to process survey setting
	*/
	public List<WorkOrder> workOrderSurveys (List<WorkOrder> woList){
        Map<String, Set<String>> surveySetMap = WorkOrderTriggerHandler.getSurveySetting();
        List<WorkOrder> wotoUpdate = new List<WorkOrder>();
        for(WorkOrder wo : [SELECT Id, WorkOrderType__c,Third_Party__c, (SELECT Id, WorkOrderLineItemType__c FROM WorkOrderLineItems), Enabled_Survey_in_Click__c,SalesOrganization__c FROM WorkOrder where Id in :woList AND Account_Location__r.Third_Party_Resource__c !=null]){
			
			Set<String> acTypes = new Set<String>();
            if(!wo.WorkOrderLineItems.isEmpty()){
                for(WorkOrderLineItem woli: wo.WorkOrderLineItems){
                	acTypes.add(woli.WorkOrderLineItemType__c);    
                }    
            }
            //get all survey types for all activities
            Set<String> surveyTypes = new Set<String>();
            if(surveySetMap.containsKey(wo.SalesOrganization__c + wo.WorkOrderType__c + 'null')){
                surveyTypes.addAll(surveySetMap.get(wo.SalesOrganization__c + wo.WorkOrderType__c + 'null'));   
            }
            List<String> allSurveys = new List<String>();
            allSurveys.addAll(surveyTypes);
            String combinedSurveys;
            for(String survey : allSurveys){
            	combinedSurveys =  combinedSurveys == null? survey : (combinedSurveys + ';' + survey);    
            }
            
            if(acTypes.contains(TS_Constants.ACTIVITY_LARGE) && wo.Third_Party__c == false){
           		wo.Enabled_Survey_in_Click__c = combinedSurveys;
            	wotoUpdate.add(wo);     
            }
            
        }
        return wotoUpdate;
    }
    

    /******************************************************************************
     * Karen Hung
     * 15.01.2020  Method to run holiday batch
     ******************************************************************************/
    public void runHolidayBatch(Date batchdrunDate, List<OperatingSchedule__c> lOperatingSchedules, Map <Integer, Boolean> lFutureholidayMap, Map < Integer, Boolean > lPastholidayMap, String batchType) {

        CustomLogging.push('runHolidayBatch', 'TS_RouteTasks_RegularBatch');

        //to get price book entry map
        Map<String, PricebookEntry> pBMap = createPriceBookEntryMap(loperatingSchedules);
        Map<String, Pricebook2> pricebookMap = getPriceBookMap();
        Set<Id> machineSet = getMachines(lOperatingSchedules);

        //-------------->> Find any L task on physical asset for tomorrow  
        Set<String> fullOP_Ltask_list = getTomorrowWOLI_list(machineSet, batchdrunDate.addDays(1), CONST_FULLOP);
        Set<String> ComfortOp_Ltask_list = getTomorrowWOLI_list(machineSet, batchdrunDate.addDays(1), CONST_COMFORTOP);

        //-----------initialize list variables ------------------------//
        List < WorkOrderLineItem > allTaskList = new List < WorkOrderLineItem > (); // List to create WOLI
        List < WorkOrder > unusedWorkOrderList = new List < workOrder > (); // list to delete unused work order

        boolean isholidaybatchBWK = batchType.equals(CONST_BWK) ? true : false; // if the batch should look backward  in case  holidays.
        boolean isholidaybatchFWD = batchType.equals(CONST_FWD) ? true : false; // if the batch should look forward  in case  holidays.
        boolean isholidaybatchFWDBWK = batchType.equals(CONST_FWDBWK) ? true : false; //Xen Reyes 8.30.2018

        //------------->>to create type of tasks during some days ahead or backward  
        TS_HolidayWrapper holidaytool = new TS_HolidayWrapper();
        Map <Integer, TS_HolidayWrapper.OpSched > fwMap = new Map <Integer, TS_HolidayWrapper.OpSched> ();
        Map <Integer, TS_HolidayWrapper.OpSched > bwMap = new Map <Integer, TS_HolidayWrapper.OpSched> ();

        // init tomorrow task with the original operating schedule for tomorrow
        TS_HolidayWrapper.OpSched finalTomorrowTask = new TS_HolidayWrapper.OpSched();

        // in below loop, the final tomorrow task will be changed/updated when necessary based on business logic for tasks on holidays
        system.debug('Batch Run Date >>> ' + batchdrunDate);

        try{

            for (OperatingSchedule__c operatingSchedule: lOperatingSchedules) {

                //SEND COUNTER READING FOR LARGE TASK - Xen Reyes, April 8, 2019 - ALM 6589
                Boolean SEND_COUNTER_VAR = SENDCOUNTER_LARGE;
                if(operatingSchedule.PhysicalAsset__r.CounterReading__c != 'Yes' ||
                    operatingSchedule.PhysicalAsset__r.Connected__c != 'No' ||
                    (operatingSchedule.PhysicalAsset__r.Machine_Care__c != 'Full Operating' && operatingSchedule.PhysicalAsset__r.Machine_Care__c != 'Comfort Operating')){
                    SEND_COUNTER_VAR = false;
                }

                //process the input of operating schedule record with holiday logic only for full operating and comfort contract
                //the result is estimated task for tomorrow for S, L, Cup and Rinse Task
                //the tomorrow task may change due to existing L task
                Boolean isComfortContract = operatingSchedule.TypeofContract__c.equals(CONST_COMFORTOP) ? true : false;
                Boolean isFullOpContract = operatingSchedule.TypeofContract__c.equals(CONST_FULLOP) ? true : false;
                
                fwMap = holidaytool.getFwdHolidayMap(batchdrunDate, operatingSchedule, lFutureholidayMap);
                bwMap = holidaytool.getBwkHolidayMap(batchdrunDate, operatingSchedule, lPastholidayMap);
                
                if (isComfortContract || isFullOpContract) finalTomorrowTask = scheduleTomorrowTask(fwMap, bwMap, batchType);
                system.debug('XEN 9/18 finalTomorrowTask: ' + finalTomorrowTask);

                //Initialize task per operating schedule based on the result of holiday logic processing
                DateTime scheduledDate = finalTomorrowTask.actualDate;
                String valueSmallTask = finalTomorrowTask.sTask;
                String valueLargeTask = finalTomorrowTask.lTask;
                String valueCupsTask = finalTomorrowTask.cTask;
                String valueRinseTask = finalTomorrowTask.rTask;
                String valuePostponedLTask = finalTomorrowTask.postponed_LTask;
                DateTime postponedLTaskDate = finalTomorrowTask.postponed_LTask_Date;
                boolean isRinseTask = finalTomorrowTask.isRinse;

                //initialize Task variables                                                                            
                List<WorkOrderLineItem> largeTaskList = new List<WorkOrderLineItem>(); 
                List<WorkOrderLineItem> postponedlargeTaskList = new List<WorkOrderLineItem>();
                List<WorkOrderLineItem> smallTaskList = new List<WorkOrderLineItem>();
                List<WorkOrderLineItem> cupTaskList = new List<WorkOrderLineItem>();
                List<WorkOrderLineItem> rinseTaskList = new List<WorkOrderLineItem>();
                //Prepare for Rinse task

                String timeIndicator;
                //Check if there is Rinse Task on holiday for Comfort or full operating contract, if yes then create an Rinse Task for next business day
                if (!valueRinseTask.equals('0') && valueRinseTask != null) {
                    timeIndicator = CONST_AM_Time;
                    isRinseTask = false; // if rinse task exist then cancel the rinse on L or S task
                    Date rinseTaskDate;

                    if (isholidaybatchBWK || isholidaybatchFWDBWK) rinseTaskDate = fwMap.get(1).actualDate;
                    else if (isholidaybatchFWD) {
                        //find the next business day for Rinse task
                        for (Integer i = 2; i <= fwMap.size(); i++) {
                            if (fwMap.get(i).isBusinessDay) {
                                rinseTaskDate = fwMap.get(i).actualDate;
                                break;
                            }
                        }
                    }
                    rinseTaskList = createOperatingTasks(CONST_RinseTask_ACTIVITY, valueRinseTask, timeIndicator, operatingSchedule, rinseTaskDate, isRinseTask, pBMap, false);

                }

                //create Rinse task if any 
                if (!rinseTaskList.isempty()) {
                    allTaskList.addAll(rinseTaskList);
                }

                //----------------- prepare for L task-------------------------------//

                //-----------> check if woli L task full operating non 24/7 exist in physical asset for tomorrow
                Boolean isFullOpNon247_LTask_Found = false;
                if (isFullOpContract &&
                    !operatingSchedule.OP_247Customer__c && fullOP_Ltask_list.contains(String.valueOf(OperatingSchedule.PhysicalAsset__c))) {
                    isFullOpNon247_LTask_Found = true;
                }

                //-----------> check if woli L task Comfort exist in physical asset for tomorrow
                Boolean isComfort_LTask_Found = false;
                if (isComfortContract && ComfortOp_Ltask_list.contains(String.valueOf(OperatingSchedule.PhysicalAsset__c))) {
                    isComfort_LTask_Found = true;
                }

                //-----------> if there is an L task existed, then  tomorrow L task should be canceled.
                if (isFullOpNon247_LTask_Found || isComfort_LTask_Found) valueLargeTask = '0'; // it is zero because there is an L task has been planned

                //-----------> create L task for non tomorrow if any   only for comfort and full operating non 24/7
                if ((isComfortContract || (isFullOpContract && !operatingSchedule.OP_247Customer__c)) && valuePostponedLTask.equals('1')) {
                    timeIndicator = '0';
                    boolean noRinse = false;
                    postponedlargeTaskList = createOperatingTasks(CONST_LargeTask_ACTIVITY, valuePostponedLTask, timeIndicator, operatingSchedule, postponedLTaskDate, noRinse, pBMap, SEND_COUNTER_VAR);
                }

                if (!postponedlargeTaskList.isEmpty()) {
                    allTaskList.addAll(postponedlargeTaskList);
                }

                //-----------> create L task for tomorrow if any
                timeIndicator = '0';
                if (!valueLargeTask.equals('0') && valueLargeTask != null) {
                    if (finalTomorrowTask.lam) timeindicator = CONST_AM_Time;
                    else if (finalTomorrowTask.lpm) timeindicator = CONST_PM_Time;
                    largeTaskList = createOperatingTasks(CONST_LargeTask_ACTIVITY, valueLargeTask, timeIndicator, operatingSchedule, scheduledDate, isRinseTask, pBMap, SEND_COUNTER_VAR);
                    isRinseTask = false;
                }

                if (!largeTaskList.isempty()) {
                    allTaskList.addAll(largeTaskList);
                }

                //----------------- prepare for S task-------------------------------// 
                timeIndicator = '0';

                if (!valueSmallTask.equals('0') && valueSmallTask != null) {
                    if (valueSmallTask.equals(CONST_AM_Time) || valueSmallTask.equals(CONST_PM_Time) || valueSmallTask.equals('1')) {
                        timeIndicator = valueSmallTask;
                        valueSmallTask = isFullOpNon247_LTask_Found ? '0' : '1'; // specific condition if there is a postponed L task (already scheduled in woli ) on full operating non 24 7 contract  then reduce s by 1
                        // comfort has no S task
                    }
                    if (finalTomorrowTask.remainingStask > 0) {
                        Integer totalSTask = Integer.valueOf(valueSmallTask) + finalTomorrowTask.remainingSTask;
                        valueSmallTask = String.valueOf(totalSTask);
                    }

                    if (Integer.valueOf(valueSmallTask) > 1 && (isFullOpNon247_LTask_Found || Integer.valueOf(valuePostponedLTask) > 0)) {
                        Integer totalSTask = Integer.valueOf(valueSmallTask) - 1;
                        valueSmallTask = String.valueOf(totalSTask);
                    }

                    smallTaskList = createOperatingTasks(CONST_SmallTask_ACTIVITY, valueSmallTask, timeIndicator, operatingSchedule, scheduledDate, isRinseTask, pBMap, false);
                    isRinseTask = false; // S should win over cup over rinse task.
                }

                if (!smallTaskList.isempty()) {
                    allTaskList.addAll(smallTaskList);
                }

                //----------------- prepare for Cups task-------------------------------// 
                timeIndicator = '0';

                if (!valueCupsTask.equals('0') && valueCupsTask != null) {
                    cupTaskList = createOperatingTasks(CONST_CupsTask_ACTIVITY, valueCupsTask, timeIndicator, operatingSchedule, scheduledDate, isRinseTask, pBMap, false);
                }
                if (!cupTaskList.isEmpty()) {
                    allTaskList.addAll(cupTaskList);
                }
            }

            //Create WorkOrder and Insert WorkOrderLineItem
            if(!thirdPartyEnabled) generateRouteTasks(allTaskList,pricebookMap,batchdrunDate.addDays(1)); 
			if(thirdPartyEnabled) generateRouteTasks2(allTaskList,pricebookMap,batchdrunDate.addDays(1)); 
            
        } catch(Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }

        CustomLogging.pop();
    }

    /******************************************************************************
     * Karen Hung
     * 15.01.2020  Used by Runholidaybatch to schedule Operating Task for tomorrow based on the forward and backward MAP
     ******************************************************************************/
    private TS_HolidayWrapper.OpSched scheduleTomorrowTask(Map <Integer, TS_HolidayWrapper.OpSched> fwSchMap, Map <Integer, TS_HolidayWrapper.OpSched> bwSchMap, String batchType) {
        CustomLogging.push('scheduleTomorrowTask', 'TS_OperatingTasks_RegularBatch');

        TS_HolidayWrapper.OpSched idayTask = new TS_HolidayWrapper.OpSched();

        //--------------- initialize tomorrow task with information obtained from Schema----------------//
        TS_HolidayWrapper.OpSched tomorrowTask = new TS_HolidayWrapper.OpSched();
        fill_Opsched(fwSchMap.get(1), tomorrowTask); //-->> to avoid pass by reference, the value of fwSchMap Map must not not be changed 

        System.debug('Tomorrow Task >>> ' + tomorrowTask);
        //---------------initialize logic variable from the tomorrow task        
        boolean isFullOp247contract = tomorrowTask.typeOfContract.equals(CONST_FULLOP) && tomorrowTask.is247 ? true : false; //full operating, 24/7        
        boolean isFullOpNon247contract = tomorrowTask.typeOfContract.equals(CONST_FULLOP) && !tomorrowTask.is247 ? true : false; //full operating, non 24/7
        boolean isComfortContract = tomorrowTask.typeOfContract.equals(CONST_COMFORTOP); //Comfort operating
        boolean isholidaybatchBWK = batchType.equals(CONST_BWK) ? true : false; // if the batch should look forward and backward in case between holidays.
        boolean isholidaybatchFWD = batchType.equals(CONST_FWD) ? true : false; // if the batch should look forward and backward in case between holidays.
        boolean isholidaybatchFWDBWK = batchType.equals(CONST_FWDBWK) ? true : false; // if the batch should look forward and backward in case between holidays.
        boolean isforcedtobusinessday = tomorrowTask.forceSchedule; // init with user opted criteria to define the plan of L task

        //--------------processing the forward Holiday logic i.e. find task on days ahead to be preponed ---------//

        if (isholidaybatchFWD || isholidaybatchFWDBWK) {
            for (Integer iday: fwSchMap.keySet()) {

                fill_Opsched(fwSchMap.get(iday), idayTask);

                if (iday > 1) { // starts from  the day after tomorrow              

                    if (idayTask.isBusinessDay) break; //--->look only for holidays 

                    // case (logic) 1. (Contract type: full operating, 24/7) If in any holidays ahead  there is S = pm, then shift if to the business day before holiday with (pm)
                    // but if there is L task on the business day then remove the S, and update the L with PM

                    if (isFullOp247contract && idayTask.sTask.equals(CONST_PM_Time)) {
                        //update the tomorrow task

                        if (idayTask.isRinse) {
                            tomorrowTask.rTask = '1';
                            tomorrowTask.isRinse = false; // if tomorrow task originally has rinse it will be replaced by the rinse task                                
                        }

                        if (tomorrowTask.lTask.equals('1')) {
                            tomorrowTask.lpm = true;
                            if (tomorrowTask.sTask.equals(CONST_PM_Time)) tomorrowTask.sTask = '0';
                        }
                        // case if L task is 0 or null
                        else if (tomorrowTask.lTask == null || tomorrowTask.lTask.equals('0')) {
                            //case if  S task is 0 or null
                            if (tomorrowTask.sTask == null || tomorrowTask.sTask.equals('0') || tomorrowTask.sTask.equals('1') || tomorrowTask.sTask.equals(CONST_AM_Time)) {
                                tomorrowTask.sTask = CONST_PM_Time;
                            }
                            //if there is s task
                            else if (tomorrowTask.sTask.equals('2') || tomorrowTask.sTask.equals('3') || tomorrowTask.sTask.equals('4')) {
                                tomorrowTask.remainingStask = Integer.valueOf(tomorrowTask.sTask) - 1;
                                tomorrowTask.sTask = CONST_PM_Time;
                            }
                        }
                        break;
                    }
                }

            }
        }

        system.debug('Back Map >>>>' + bwSchMap);
        if (isholidaybatchBWK || isholidaybatchFWDBWK) { //find tasks to be postponed in the past holiday
            boolean isFullOp_sTask_AM_found = false; //to stop loop for full operating 24/7 with s am task
            boolean isFullOp_lTask_found = false; // to stop loop for full operating 24/7 with l task
            boolean isRinseTaskFound = false; //            
            system.debug('isFullOp247contract: ' + isFullOp247contract);
            system.debug('isFullOpNon247contract:' + isFullOpNon247contract);
            system.debug('isComfortContract: ' + isComfortContract);
            // the loop is to find any postponed task  
            for (Integer iday: bwSchMap.keySet()) {
                fill_Opsched(bwSchMap.get(iday), idayTask);
                system.debug('Current Day >>>> ' + iday + ' >>> ' + idayTask);
                //only loop backward for holidays in the map, and stop when find business day
                if (idayTask.isBusinessDay || (isFullOp_lTask_found && isRinseTaskFound)) break;

                // case 2. full operating, 24/7, find any L =1, if an L  task is found then stop the search for S Am task which is done by isFullOp_lTask_found
                if (isFullOp247contract && idayTask.lTask.equals('1') && !isFullOp_lTask_found) {
                    isFullOp_lTask_found = true;

                    //System.debug(iday + '. begin tommorow s task :'+ tomorrowTask.sTask);                        
                    if (idayTask.isRinse) {
                        tomorrowTask.rTask = '1';
                        tomorrowTask.isRinse = false; // if tomorrow task originally has rinse it will be replaced by the rinse task  
                        isRinseTaskFound = true;
                    }
                    // if tomorrow has no L task, create a new L task 
                    if (!tomorrowTask.lTask.equals('1')) tomorrowTask.lTask = '1';
                    tomorrowTask.lam = true; //L task should alwasy be postponed as L am task

                    if (tomorrowTask.sTask.equals('1') || tomorrowTask.sTask.equals(CONST_AM_Time)) tomorrowTask.sTask = '0'; // remember although s task can be 0 , the remaining task can be non zero and should be scheduled as operating task too.
                    // if tommorow has S task more than 1, then reduce it by 1                                       
                    else if (tomorrowTask.sTask.equals('2') || tomorrowTask.sTask.equals('3') || tomorrowTask.sTask.equals('4')) {
                        tomorrowTask.remainingStask = Integer.valueOf(tomorrowTask.sTask) - 2;
                        tomorrowTask.sTask = '1';
                    }
                    // if tommorow has 1 (with or without AM ) S task  then remove it                                                    
                    else if (tomorrowTask.sTask.equals(CONST_PM_Time)) {
                        if (tomorrowTask.remainingStask < 1 || tomorrowTask.remainingStask == null) tomorrowTask.sTask = '0'; // if S pm is the only one then it is covered by the L am
                        else tomorrowTask.remainingStask = Integer.valueOf(tomorrowTask.sTask) - 1; // If S pm and there are remaining task, the remaining task is reduced by 1 as covered by L am
                    }

                }

                // case 3. full operating, 24/7, find any S = am. if an S am   is found then check if tomorrow has L , the search should continue to find L                 
                if (isFullOp247contract && idayTask.sTask.equals(CONST_AM_Time) && !isFullOp_sTask_AM_found && (!isFullOp_lTask_found || !isRinseTaskFound)) {
                    // if tomorrow has no  L task update only the S task
                    // if iday has  rinse, then move it to tomorrow task
                    // if (idayTask.isRinse) tomorrowTask.isRinse = true;
                    if (idayTask.isRinse) {
                        tomorrowTask.rTask = '1';
                        tomorrowTask.isRinse = false; // if tomorrow task originally has rinse it will be replaced by the rinse task                 
                    }
                    if (!tomorrowTask.lTask.equals('1') && !isFullOp_lTask_found) {
                        //if iday has  rinse, then move it to tomorrow task
                        //  if (idayTask.isRinse) tomorrowTask.isRinse = true;

                        //in case there is 1 task
                        if (tomorrowTask.sTask.equals('0') || tomorrowTask.sTask == null || tomorrowTask.sTask.equals('1') || tomorrowTask.sTask.equals(CONST_PM_Time)) {
                            tomorrowTask.sTask = CONST_AM_Time;
                            //tomorrowTask.remainingStask = 0;                                 
                        }
                        // in case there are more than 1 s Task
                        if (tomorrowTask.sTask.equals('2') || tomorrowTask.sTask.equals('3') || tomorrowTask.sTask.equals('4')) {
                            tomorrowTask.remainingStask = Integer.valueOf(tomorrowTask.sTask) - 1;
                            tomorrowTask.sTask = CONST_AM_Time;
                        }

                    }
                    //if tomorrow has L task update only the L task to L am task.
                    if (tomorrowTask.lTask.equals('1') && !isFullOp_lTask_found) tomorrowTask.lam = true;
                    isRinseTaskFound = true; // this is to look for rinse task but if in Sam cannot be found, it should stop searching.    
                    isFullOp_sTask_AM_found = true;
                }
                // case 4. Comfort operating, L Task --> shift to H+2 but if h+2 is holiday then find a day after H+2 that is business day
                if (isComfortContract && idayTask.lTask.equals('1')) {

                    tomorrowTask.postponed_LTask = '1';
                    // tomorrowTask.isRinse = idayTask.isRinse;// set rinse if the L task on the holiday has rinse task
                    if (idayTask.isRinse) {
                        tomorrowTask.rTask = '1';
                        tomorrowTask.isRinse = false; // if tomorrow task originally has rinse it will be replaced by the rinse task                 
                    }

                    Date comfortLtaskdate = tomorrowTask.actualDate; // initialize the task date

                    for (Integer i = 2; i <= fwSchMap.size(); i++) { //find the next business day from H+2
                        if (fwSchMap.get(i).isBusinessDay) {
                            comfortLtaskdate = fwSchMap.get(i).actualDate;
                            break;
                        }
                    }
                    tomorrowTask.postponed_LTask_Date = comfortLtaskdate; // this is the shifted/postponed date for L task for comfort
                    break;
                }
                // Case 5. full operating, non 24/7 , to find L task --> shift to the next S day or the next business day in the same week. reduce s task by 1 
                if (isFullOpNon247contract && idayTask.lTask.equals('1')) {

                    tomorrowTask.postponed_LTask = '1';

                    if (idayTask.isRinse) {
                        tomorrowTask.rTask = '1';
                        tomorrowTask.isRinse = false; // if tomorrow task originally has rinse it will be replaced by the rinse task                 
                    }

                    Date fullnon247Ltaskdate = tomorrowTask.actualDate;

                    System.debug('XEN 9/18 fwSchMap: ' + fwSchMap);

                    for (Integer i = 0; i <= (fwSchMap.size() - 1); i++) { //find the next s business day

                        if (!isforcedtobusinessday && fwSchMap.get(i).isBusinessDay && (!fwSchMap.get(i).sTask.equals('0') && fwSchMap.get(i).sTask != null)) {
                            fullnon247Ltaskdate = fwSchMap.get(i).actualDate; // L task shift to next S day as user opts for that
                            // tomorrowTask.isRinse = idayTask.isRinse;//||fwSchMap.get(i).isRinse?true:false;
                            System.debug(iday + 'is NOT forced to businessday -->fullnon247Ltaskdate: ' + fullnon247Ltaskdate);
                            break;
                        } else if (isforcedtobusinessday && fwSchMap.get(i).isBusinessDay) { // L task shift to next business day as user opts for that
                            fullnon247Ltaskdate = fwSchMap.get(i).actualDate;
                            // tomorrowTask.isRinse = idayTask.isRinse;//||fwSchMap.get(i).isRinse?true:false;
                            System.debug(iday + 'is forced to businessday -->fullnon247Ltaskdate: ' + fullnon247Ltaskdate);
                            break;
                        }
                    }

                    tomorrowTask.postponed_LTask_Date = fullnon247Ltaskdate;

                    break;
                }
            }
        }
        CustomLogging.pop();
        return tomorrowTask;
    }

    /******************************************************************************
     * Karen Hung
     * 15.01.2020  Copy the map values of tofill into tobefilled (to avoid pass by reference)
     ******************************************************************************/
    public void fill_Opsched(TS_HolidayWrapper.OpSched tofill, TS_HolidayWrapper.OpSched tobefilled) {
        tobefilled.osId = tofill.osId;
        tobefilled.typeOfContract = tofill.typeOfContract;
        tobefilled.cTask = tofill.cTask;
        tobefilled.sTask = tofill.sTask;
        tobefilled.lTask = tofill.lTask;
        tobefilled.rTask = tofill.rTask;
        tobefilled.timeIndicator = tofill.timeIndicator;
        tobefilled.isRinse = tofill.isRinse;
        tobefilled.is247 = tofill.is247;
        tobefilled.isBusinessDay = tofill.isBusinessDay;
        tobefilled.lpm = tofill.lpm;
        tobefilled.lam = tofill.lam;
        tobefilled.forceSchedule = tofill.forceSchedule;
        tobefilled.remainingSTask = tofill.remainingSTask;
        tobefilled.actualDate = tofill.actualDate;
    }

    /******************************************************************************
     * Karen Hung
     * 15.01.2020  to Create the list of WOLI task based on the inputs
     ******************************************************************************/
    List<WorkOrderLineItem> createOperatingTasks(String activityType, String activityvalue, String timeindicator, OperatingSchedule__c operatingSchedule, DateTime scheduledDate, boolean isRinse, Map <String, PricebookEntry> priceBookMap, Boolean sendCounterReading) {
        CustomLogging.push('createTasks', 'TS_RouteTask_Batch');

        List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem> ();
        Integer starthour = defaultstarttime;  
        Integer endhour = defaultendTime;

        boolean isTimeIndicatorExecutedOnce = false;
        for (Integer i = 0; i < numberOfTasksMap.get(activityvalue); i++) {

            WorkOrderLineItem task = new WorkOrderLineItem();
            task.WorkOrderType__c = CONST_WORKORDER_OP_TYPE;
            task.AccountLocation__c = operatingSchedule.PhysicalAsset__r.AccountLocation__c;
            task.WorkOrderLineItemType__c = activityType;
			
            DateTime earlyStart;
            if(numberOfTasksMap.get(activityvalue) != 0 && numberOfTasksMap.get(activityvalue) != 1){
                task.EarlyStart__c = DateTime.newInstance(scheduledDate.year(), scheduledDate.month(), scheduledDate.day(), starthour, i, 0);
                earlyStart = DateTime.newInstance(scheduledDate.year(), scheduledDate.month(), scheduledDate.day(), starthour, i, 0);
            } else {
                task.EarlyStart__c = DateTime.newInstance(scheduledDate.year(), scheduledDate.month(), scheduledDate.day(), starthour, 0, 0);
                earlyStart = DateTime.newInstance(scheduledDate.year(), scheduledDate.month(), scheduledDate.day(), starthour, 0, 0);
            }

            task.SLADate__c = DateTime.newInstance(scheduledDate.year(), scheduledDate.month(), scheduledDate.day(), endhour, 0, 0);
            task.Building__c = operatingSchedule.PhysicalAsset__r.Building__c;
            task.AccountLocationID__c = operatingSchedule.PhysicalAsset__r.AccountLocation__r.SAP_Customer_ID__c;
            task.Floor__c = operatingSchedule.PhysicalAsset__r.Floor__c;
            task.OP_IsHoliday__c = false;
            task.PhysicalAsset__c = operatingSchedule.PhysicalAsset__c;
            task.OP_PreferredOperator__c = operatingSchedule.PhysicalAsset__r.OP_PreferredOperator__c;
            task.Sequence_Number__c = null;

            //to set pricebook entry
            String priceBookKey = String.valueOf(operatingSchedule.PhysicalAsset__r.Product__c) + operatingSchedule.PhysicalAsset__r.SalesOrganization__c;
            task.PricebookEntryId = priceBookMap.get(priceBookKey) != null ? priceBookMap.get(priceBookKey).Id : null;
			
            //Karen Hung 2/3/2021 DOO-5269
            if(operatingBucketEnabled){
            	task.Operating_Bucket__c = activityAPIMap.containsKey(activityType) ? String.valueOf(priceBookMap.get(priceBookKey)?.get(activityAPIMap.get(activityType))) : null;
                task.OPG_Source__c = 'OPG Daily Batch';
            } 
            
            task.RecordTypeId = CONST_WOLI_OP_RT;
            
            if (!isTimeIndicatorExecutedOnce && !timeindicator.equals('0')) {
                task.OP_TimeIndicator__c = timeindicator == CONST_AM_Time || timeindicator == CONST_PM_Time ? timeindicator : null;
                isTimeIndicatorExecutedOnce = true;
            }

            task.OP_247Customer__c = operatingSchedule.OP_247Customer__c;
            task.MachineCare__c = operatingSchedule.PhysicalAsset__r.Machine_Care__c;
            task.OP_RinseRequired__c = isRinse;

            task.SendCounterReadingsOperating__c = sendCounterReading;
            task.isFromRoute__c = true;

            woliList.add(task);

            if(operatingSchedule.PhysicalAsset__c != null){
                woliAssets.add(operatingSchedule.PhysicalAsset__c);
            }
            
            //Karen Hung 9/2/2021 DOO-5161
            if((activityType == TS_Constants.ACTIVITY_CUPS || activityType == TS_Constants.ACTIVITY_SMALL || activityType == TS_Constants.ACTIVITY_RINSE) && operatingSchedule.PhysicalAsset__r.AccountLocation__r.Third_Party_Resource__c != null && thirdPartyEnabled){
              
             	task.Status = TS_Constants.WOLI_STATUS_SCHEDULED;
                task.ExecutingEngineer__c = operatingSchedule.PhysicalAsset__r.AccountLocation__r.Third_Party_Resource__c;
                task.Travel_Start_Time__c = earlyStart;
                task.Travel_Stop_Time__c = earlyStart;
				task.StartDate__c = earlyStart;
				task.EndDate__c = earlyStart;
                   
            }else{            	
            	task.Status = CONST_WOLI_OPEN_STATUS; //'Open'       
            }
        }

        CustomLogging.pop();
        return woliList;
    }

    /******************************************************************************
     * Karen Hung
     * 15.01.2020   Method to create a custom log record if there is failed record processed in the batch execution.
     ******************************************************************************/
    public void INSERT_LOGGING (List<Database.SaveResult> saveResultList, String description) {

        //Custom Logging for Database.Error
        Set<String> exception_List_batch = new Set<String>();

        /* Create error message to each Database.Error. */
        for (Database.SaveResult sr: saveResultList) {
            if (!sr.isSuccess()) {
                //Operation failed. Get error details               
                for(Database.Error err : sr.getErrors()) {
                    String msg = TS_Constants.ERRBATCH_MSG_01 + err.getStatusCode() + ': ' + err.getMessage() + ': ' + err.getFields();
                    exception_List_batch.add(msg);
                }
            }
        }

        //Create custom log record per batch if there is an error.
        if(!exception_List_batch.isEmpty()){
            String mainMessage = '';

            for(String err : exception_List_batch){
                mainMessage = err + '\n';
            }

            //CREATE CUSTOM LOG
            Custom_Log__c log = new Custom_Log__c(
                StackTrace__c = 'Route Task Batch: ' + description,
                Message__c = mainMessage,
                ExceptionType__c = TS_Constants.DATABASE_ERROR);
            insert log;
        }
    }

    /*******************************************************************************
     * @author         Karen Hung
     * @description    15.01.2020   Method to evaluate if the date is within the first 10 working days
     *******************************************************************************/
    public static Boolean EVALUATEDATE (Date taskDate, CountrySetting__c cs) {

        Boolean SEND_COUNTER = Boolean.valueOf(Label.TS_EnforceCounterReadingForOperating);
        Integer NUM_WORKINGDAYS = Integer.valueOf(Label.TS_NumberOfWorkingDaysCounterReading);
        String SATURDAY = 'Saturday';
        String SUNDAY = 'Sunday';
        Set<Date> DAYSET = new Set<Date>();

        String busineshourId = String.valueOf(cs.Business_Hours__r.Id); 
        Date D1 = taskDate.toStartofMonth();
        Date D2 = D1.addMonths(1);

        Integer COUNTER = 0;
        while (D1 < D2){

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

        if(!DAYSET.isEmpty() && DAYSET.contains(taskDate)){
            SEND_COUNTER = true;
        }
        return SEND_COUNTER;

    }
}