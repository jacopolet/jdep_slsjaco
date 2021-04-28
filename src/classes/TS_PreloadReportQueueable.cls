//-------------------------------------------------------------------------------------------//
// Author       :   Karen Mae Hung
// Created Date :   Feb 25, 2020
// Usage        :   Queuable Interface to Execute Preload Report
//-------------------------------------------------------------------------------------------//
public with sharing class TS_PreloadReportQueueable implements Queueable {
    
    public Date taskDate {get; set;}
    public String batchType {get; set;}
    public String BUSINESS_ID {get; set;}
    public Boolean SEND_COUNTER {get; set;}
    public Boolean isRetry {get; set;}
    public Date runDate {get; set;}
    public Integer addedDay {get; set;}
    public String country_Name {get; set;}
    public static Boolean hasException = false;
    public Boolean nordicsPreload = false;
    
    //Karen Hung 23/12/2020 DOO-5149
    public static Map<Id,TS_Feature_Flag__mdt> featureFlags =  new Map<Id,TS_Feature_Flag__mdt>([SELECT Id, QualifiedApiName, Enable__c FROM TS_Feature_Flag__mdt WHERE QualifiedApiName != null]);
    public static Boolean flagEnabled = false;
    
    //Karen Hung 9/3/2021 DOO-5268
    public static Map<String, String> activityAPIMap = new Map<String, String> { 'Large' => 'MTTO_FO_Large_Bucket__c', 'Small' => 'MTTO_FO_Small_Bucket__c', 'Cups' => 'MTTO_FO_Cups_Bucket__c'};                                                                   
	public static Map<String, String> mcoActivityBucketAPIMap = TS_UtilityClass.mcoActivityBucketAPIMap();
    
    public class TS_PreloadReportQueueableException extends Exception {
        
    }
    
    public TS_PreloadReportQueueable() {
        
    }
    
    /**
    * @author        Karen Hung
    * @date          Feb 25, 2020
    * @description   Method to generate custom log for preload report
    * @revision(s)
    */    
    public void execute(QueueableContext context){
        CustomLogging.push('execute', 'TS_PreloadReportQueueable');
        try{
            if (Test.isRunningTest() && hasException) {
                throw new TS_PreloadReportQueueableException('Force to throw an exception');
            }
            
            if(!featureFlags.isEmpty()){
                for(TS_Feature_Flag__mdt flag : featureFlags.values()){
                    if(flag.QualifiedApiName == 'DOO_5149_csv_for_3rd_party_preload' && flag.Enable__c){
                        flagEnabled = true;    
                    }    
                }
            }
            
            if(nordicsPreload){
                PRELOAD_NORDICS(runDate);
                return;   
            }
            
            //Execute old logic if feature flag is disabled
            if(!flagEnabled || Test.isRunningTest()){
                                
                Date nextDate = runDate.addDays(1);
                DateTime nextDateTime = DateTime.newInstanceGMT(nextDate.year(), nextDate.month(), nextDate.day(), 12, 0, 0);
                
                String PRELOAD_STRING = '';
                PRELOAD_STRING = PRELOAD_SCRIPT(taskDate, batchType, BUSINESS_ID, SEND_COUNTER);
                
                //Custom log creation to check parameter
                Custom_Log__c log = new Custom_Log__c(
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
                
                insert log;
            }
            
            //Karen Hung DOO-5149 Execute New Logic if featureflag is enabled
            if(flagEnabled || Test.isRunningTest()){
                
                PRELOAD_SCRIPT_NEW(taskDate, batchType, BUSINESS_ID, SEND_COUNTER);
                
            }
            
        }catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
        }
        
        CustomLogging.pop();
    }
    
	/**
    * @author        Karen Hung
    * @date          Feb 25, 2020
    * @description   Method to generate pre-load script and attach basic information for custom log.
    * @revision(s)
    */ 
    public String PRELOAD_SCRIPT (Date nextDate, String batchType, String BUSINESS_ID, Boolean IS_CR_DAY) {
        
        //GET ROUTES WITH HOLIDAYS
        Map<Id, Route__c> routeWithHoliday = new Map<Id, Route__c>([SELECT Id FROM Route__c WHERE Account_Location__c IN (SELECT Account_Location__c FROM Customer_Holiday__c WHERE From__c <=: nextDate AND Day__c >=: nextDate)]);
        
        String CONST_SmallTask_API = Label.TS_Operating_Small;
        String CONST_LargeTask_API = Label.TS_Operating_Large;
        String CONST_RinseTask_API = Label.TS_Operating_Rinse;
        String CONST_CupsTask_API = Label.TS_Operating_Cups;

        List<String> CSVROWVALUES_SMALL = new List<String>(); 
        List<String> CSVROWVALUES_LARGE = new List<String>(); 
        List<String> CSVROWVALUES_CUP = new List<String>(); 
        List<String> CSVROWVALUES_RINSE = new List<String>();

        Integer TOTAL_CUPS = 0;
        Integer TOTAL_RINSE = 0;
        Integer TOTAL_LARGE = 0;
        Integer TOTAL_LARGE_CR = 0;
        Integer TOTAL_LARGE_CR_HOLIDAY = 0;
        Integer TOTAL_SMALL = 0;
        Integer NUM_WORKORDER = 0; 
        Integer OP_SCHED_SIZE = 0;
        Integer TOTAL_CUPS_HOLIDAY = 0;
        Integer TOTAL_RINSE_HOLIDAY = 0; 
        Integer TOTAL_LARGE_HOLIDAY = 0; 
        Integer TOTAL_SMALL_HOLIDAY = 0; 
        
        DateTime scheduledDate = nextDate;
        Boolean isHoliday = false;
        if(batchType == null || batchType == 'null'){
            isHoliday = true;
        }
        
        DescribeSObjectResult operatingScheduleDescribe = OperatingSchedule__c.getSObjectType().getDescribe();
        List<String> fields = new List<String>(operatingScheduleDescribe.fields.getMap().keySet());
        String QUERY_STRING = 'SELECT ' + String.join(fields, ',') +
            ', PhysicalAsset__r.Name, PhysicalAsset__r.CounterReading__c, PhysicalAsset__r.Connected__c, PhysicalAsset__r.Machine_Care__c' + ' FROM ' + operatingScheduleDescribe.getName() + 
            ' WHERE OperatingReady__c = true AND Schedule_Type__c = \'Regular\' AND PhysicalAsset__r.EndDate__c >= :nextDate' + //Karen Hung DOO-2695 Added contract end date filter
            (isHoliday ? ' AND Schedule_Tasks_for_Holiday__c = true' : '' ) +
            ' AND TypeofContract__c IN (\'Full Operating\', \'Comfort Operating\')' + 
            ' AND PhysicalAsset__c IN (SELECT PhysicalAssetId__c FROM Route_Line_Item__c WHERE RouteId__r.Account_Location__r.Mini_Sales_Organization__c =  \'SAP_0111\')';
        
        List<OperatingSchedule__c> OPS_LIST = Database.query(QUERY_STRING);
        Set<String> routeNames = new Set<String>();
        Set<String> routeNames_holiday = new Set<String>();
        
        if(!OPS_LIST.isEmpty()){
            
            //GET ALL PHYSICAL ASSET
            Set<Id> pa_list_set = new Set<Id>();
            for (OperatingSchedule__c OP_VAR: OPS_LIST) {
                pa_list_set.add(OP_VAR.PhysicalAsset__c);
            }
            
            //GET ALL ROUTES AND ROUTE LINE ITEMS AND PUT IN MAP
            List<Route_Line_Item__c> rli_list = new List<Route_Line_Item__c> ();
            Map<Id, Route_Line_Item__c> map_pa_rli = new Map<Id, Route_Line_Item__c> ();
            if (!pa_list_set.isEmpty()) {
                rli_list = [SELECT Id, RouteId__c, RouteId__r.Name, PhysicalAssetId__c FROM Route_Line_Item__c WHERE PhysicalAssetId__c IN: pa_list_set];
                
                if (!rli_list.isEmpty()) {
                    for (Route_Line_Item__c rli_var: rli_list) {
                        map_pa_rli.put(rli_var.PhysicalAssetId__c, rli_var);
                    }
                }
            }
            
            OP_SCHED_SIZE = OPS_LIST.size();
            for(OperatingSchedule__c OP_VAR : OPS_LIST){
                
                if (!map_pa_rli.containsKey(OP_VAR.PhysicalAsset__c)) continue;
                
                String ROUTE_NAME_STR = map_pa_rli.get(OP_VAR.PhysicalAsset__c).RouteId__r.Name;
                String ROUTE_ID_STR = map_pa_rli.get(OP_VAR.PhysicalAsset__c).RouteId__c;
                
                String IS_HOLIDAY = routeWithHoliday.containsKey(ROUTE_ID_STR) ? 'TRUE' : 'FALSE';
                //if(IS_HOLIDAY == 'TRUE') routeNames_holiday.add(ROUTE_ID_STR);//Karen Hung 4.6.2020 holiday count fix
                
                //GET WEEK NUMBER
                Date d1 = OP_VAR.Start_Date__c.toStartOfWeek();
                Date d2 = scheduledDate.date().toStartOfWeek();
                Integer numberOfWeeks = d1.daysBetween(d2) / 7;
                String WEEK_NUM = String.valueOf(Math.mod(numberOfWeeks, 2) == 0 ? 1 : 2);
                
                //GET RINSE
                /* String RINSE_API = CONST_RinseTask_API + '_' + WEEK_NUM + '_' + scheduledDate.format('EEEE') + '__c';
                if(OP_VAR.get(RINSE_API) != null){
                Boolean VAL_RINSE = (Boolean) OP_VAR.get(RINSE_API);
                if(VAL_RINSE) {
                
                TOTAL_RINSE++;
                
                String OPSCHED_NAME = OP_VAR.Name != null ? OP_VAR.Name : '';
                String OPSCHED_PHYSICALASSET = OP_VAR.PhysicalAsset__r.Name != null ? OP_VAR.PhysicalAsset__r.Name : '';
                String OPSCHED_STARTDATE = String.valueOf(OP_VAR.Start_Date__c);
                String FIELD_API = RINSE_API != null ? RINSE_API : '';
                String FIELD_VALUE = String.valueOf(1);
                String ROUTE_ID = ROUTE_ID_STR;
                String ROUTE_NAME = ROUTE_NAME_STR;
                
                String rowStr = OPSCHED_NAME + ',' + OPSCHED_PHYSICALASSET + ',' + OPSCHED_STARTDATE + ',' + FIELD_API + ',' + FIELD_VALUE + ',' + ROUTE_ID + ',' + IS_HOLIDAY + ',' + ROUTE_NAME;
                CSVROWVALUES_RINSE.add(rowStr);
                routeNames.add(ROUTE_ID_STR);
                if(IS_HOLIDAY == 'TRUE') TOTAL_RINSE_HOLIDAY = TOTAL_RINSE_HOLIDAY + 1;
                }
                } */
                
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
                               if(IS_HOLIDAY == 'TRUE') TOTAL_LARGE_CR_HOLIDAY++;
                           }
                        
                        String OPSCHED_NAME = OP_VAR.Name != null ? OP_VAR.Name : '';
                        String OPSCHED_PHYSICALASSET = OP_VAR.PhysicalAsset__r.Name != null ? OP_VAR.PhysicalAsset__r.Name : '';
                        String OPSCHED_STARTDATE = String.valueOf(OP_VAR.Start_Date__c);
                        String FIELD_API = LARGE_API != null ? LARGE_API : '';
                        String FIELD_VALUE = String.valueOf(1);
                        String ROUTE_ID = ROUTE_ID_STR;
                        String ROUTE_NAME = ROUTE_NAME_STR;
                        
                        String rowStr = OPSCHED_NAME + ';' + OPSCHED_PHYSICALASSET + ';' + OPSCHED_STARTDATE + ';' + FIELD_API + ';' + FIELD_VALUE + ';' + ROUTE_ID + ';' + IS_HOLIDAY + ';' + ROUTE_NAME;
                        CSVROWVALUES_LARGE.add(rowStr);
                        routeNames.add(ROUTE_ID_STR);

                        if(IS_HOLIDAY == 'TRUE') {
                            TOTAL_LARGE_HOLIDAY = TOTAL_LARGE_HOLIDAY + 1;
                            routeNames_holiday.add(ROUTE_ID_STR);
                        }
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
                        String ROUTE_ID = ROUTE_ID_STR;
                        String ROUTE_NAME = ROUTE_NAME_STR;
                        
                        String rowStr = OPSCHED_NAME + ';' + OPSCHED_PHYSICALASSET + ';' + OPSCHED_STARTDATE + ';' + FIELD_API + ';' + FIELD_VALUE + ';' + ROUTE_ID + ';' + IS_HOLIDAY + ';' + ROUTE_NAME;
                        CSVROWVALUES_SMALL.add(rowStr);
                        routeNames.add(ROUTE_ID_STR);

                        if(IS_HOLIDAY == 'TRUE') {
                            TOTAL_SMALL_HOLIDAY = TOTAL_SMALL_HOLIDAY + INDICATOR_VAR_SMALL;
                            routeNames_holiday.add(ROUTE_ID_STR);
                        }
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
                            String ROUTE_ID = ROUTE_ID_STR;
                            String ROUTE_NAME = ROUTE_NAME_STR;
                            
                            String rowStr = OPSCHED_NAME + ';' + OPSCHED_PHYSICALASSET + ';' + OPSCHED_STARTDATE + ';' + FIELD_API + ';' + FIELD_VALUE + ';' + ROUTE_ID + ';' + IS_HOLIDAY + ';' + ROUTE_NAME;
                            CSVROWVALUES_CUP.add(rowStr);
                            routeNames.add(ROUTE_ID_STR);

                            if(IS_HOLIDAY == 'TRUE') {
                                TOTAL_CUPS_HOLIDAY = TOTAL_CUPS_HOLIDAY + Integer.valueOf(CUP_VAL);
                                routeNames_holiday.add(ROUTE_ID_STR);
                            }
                        }
                    }
                }
            }
        }
        
        String csvColumnHeader;
        String docId;
        String myDomain = Url.getOrgDomainUrl().toExternalForm();
        String initialURL = myDomain + '/servlet/servlet.FileDownload?file=';

        List<Folder> folders = [SELECT Id, Name FROM Folder WHERE Name = 'Batch Pre-Load Reports'];
        
        if(!folders.isEmpty()){
            String documentName = 'PRELOAD_ROUTE_OPERATING_FOR_' + String.valueOf(scheduledDate.format('MMMdd')) + ' ' + String.valueOf(Datetime.now());
            csvColumnHeader = 'NAME; PHYSICAL ASSET; START DATE; FIELD API; NUMBER OF TASK; ROUTE ID; IS HOLIDAY?; ROUTE\n';
            String csvFile = csvColumnHeader + String.join(CSVROWVALUES_SMALL, '\n') + '\n' + String.join(CSVROWVALUES_LARGE, '\n') + '\n' + String.join(CSVROWVALUES_CUP, '\n') + '\n' + String.join(CSVROWVALUES_RINSE, '\n');
            
            Document doc = new Document(Name = documentName, Body = Blob.valueOf(csvFile), FolderId = folders[0].Id, Type = 'csv', ContentType = 'application/vnd.ms-excel');
            insert doc;
            
            docId = doc.Id;
        }
        
        if(!IS_CR_DAY) TOTAL_LARGE_CR = 0; TOTAL_LARGE_CR_HOLIDAY = 0;
        String RET_STR =  '\n' +
            'TOTAL_CUPS: ' + String.valueOf(TOTAL_CUPS) + '\n' +
            'TOTAL_SMALL: ' + String.valueOf(TOTAL_SMALL) + '\n' + 
            'TOTAL_LARGE: ' + String.valueOf(TOTAL_LARGE) + '\n' + '\n' +
            //'TOTAL_RINSE: ' + String.valueOf(TOTAL_RINSE) + '\n' + '\n' +
            
            'TOTAL_CUPS_HOLIDAY: ' + String.valueOf(TOTAL_CUPS_HOLIDAY) + '\n' +
            'TOTAL_SMALL_HOLIDAY: ' + String.valueOf(TOTAL_SMALL_HOLIDAY) + '\n' + 
            'TOTAL_LARGE_HOLIDAY: ' + String.valueOf(TOTAL_LARGE_HOLIDAY) + '\n' + '\n' +
            //'TOTAL_RINSE_HOLIDAY: ' + String.valueOf(TOTAL_RINSE_HOLIDAY) + '\n' + '\n' + 
            
            'TOTAL_CUPS_FINAL: ' + String.valueOf(TOTAL_CUPS - TOTAL_CUPS_HOLIDAY) + '\n' +
            'TOTAL_SMALL_FINAL: ' + String.valueOf(TOTAL_SMALL - TOTAL_SMALL_HOLIDAY) + '\n' + 
            'TOTAL_LARGE_FINAL: ' + String.valueOf(TOTAL_LARGE - TOTAL_LARGE_HOLIDAY) + '\n' + '\n' +
            //'TOTAL_RINSE_FINAL: ' + String.valueOf(TOTAL_RINSE - TOTAL_RINSE_HOLIDAY) + '\n' + '\n' + 
            
            'TOTAL_LARGE_WITHCR: ' + String.valueOf(TOTAL_LARGE_CR) + '\n' +
            'TOTAL_LARGE_WITHCR_HOLIDAY: ' + String.valueOf(TOTAL_LARGE_CR_HOLIDAY) + '\n' +
            'TOTAL_LARGE_FINAL: ' + String.valueOf(TOTAL_LARGE_CR - TOTAL_LARGE_CR_HOLIDAY) + '\n' + '\n' + 
            
            'NUMBER OF ROUTE TASK: ' + routeNames.size() + '\n' +
            'NUMBER OF ROUTE TASK (HOLIDAY): ' + routeNames_holiday.size() + '\n' +
            'NUMBER OF ROUTE TASK (FINAL): ' + (routeNames.size() - routeNames_holiday.size()) + '\n' + '\n' +
            
            'IS_NULL_BATCH_TYPE: ' + String.valueOf(isHoliday) + '\n' + 
            'PRELOAD_REPORT_LINK: ' + initialURL + docId;
        return RET_STR;
    }
    
    /**
    * @author        Karen Hung
    * @date          Apr 23, 2020
    * @description   DOO-4373 Method to generate machine clean operating pre-load script and attach basic information for custom log.
    * @revision(s)
    */ 
    public static void PRELOAD_NORDICS(Date runDate){
        CustomLogging.push('execute', 'TS_PreloadReportQueueable');
        
        List<String> CSVROWVALUES = new List<String>();
        
        Integer countrySettingValue = Integer.valueOf(Label.TS_CountrySetting);
        
        //TODAY + a country dependent value
        Date todayPlusValue =  runDate.addDays(countrySettingValue);
        
        //todayPlusValue is => first day of next month
        Boolean isFirstofNextMonth = runDate.addMonths(1).toStartOfMonth() <= todayPlusValue && todayPlusValue.addDays(-7) < runDate.addMonths(1).toStartOfMonth();

        Integer countrySetting = Integer.valueOf(Label.TS_CountrySetting);
            
        String monthToday = String.valueOf(runDate.addDays(countrySetting).month());
        
        Set<String> routeStartSLAString = new Set<String>();

        List<String> activityList = new List<String>();

        String csvColumnHeader;
        String docId;
        String myDomain = Url.getOrgDomainUrl().toExternalForm();
        String initialURL = myDomain + '/servlet/servlet.FileDownload?file=';
  
        if(!isFirstofNextMonth){

            //Custom log creation to check parameter
            Custom_Log__c log = new Custom_Log__c(
              Name = 'Machine Clean Operating ' + String.valueOf(System.now()),
              StackTrace__c = 'TS_MCOperating_Batch',
              Message__c = 'This is a log to monitor the parameters provided to the machine clean operating scheduler class and to generate a pre-load report.' 
              + '\n' + 'RUN DATE: ' + String.valueOf(runDate) 
              + '\n' + 'ADD DAYS: ' + Label.TS_CountrySetting 
              + '\n' + 'COUNTRY: NORDICS' +
              + '\n' + 'BATCH TYPE: MACHINE CLEAN OPERATING' +
              + '\n' + 'NUMBER OF WORK ORDERS: NO TASKS TO CREATE'
              );
          
            insert log;

        }else{
            DescribeSObjectResult operatingScheduleDescribe = OperatingSchedule__c.getSObjectType().getDescribe();
            List<String> fields = new List<String>(operatingScheduleDescribe.fields.getMap().keySet());
            
            String QUERY_STRING = 'SELECT ' + String.join(fields, ',') + 
                                    ', PhysicalAsset__r.Name, PhysicalAsset__r.Product__c,  PhysicalAsset__r.SalesOrganization__c, PhysicalAsset__r.AccountLocation__c' +
                                    ', PhysicalAsset__r.Building__c,PhysicalAsset__r.AccountLocation__r.SAP_Customer_ID__c,PhysicalAsset__r.Floor__c' +
                                    ', PhysicalAsset__r.SoldTo__c, PhysicalAsset__r.OP_PreferredOperator__c, PhysicalAsset__r.MothballAssetIndicator__c, PhysicalAsset__r.Machine_Care__c' +
                                    ', PhysicalAsset__r.CounterReading__c, PhysicalAsset__r.Connected__c, PhysicalAsset__r.EndDate__c' + //Karen Hung DOO-2695 Added contract end date filter
                                    ', PhysicalAsset__r.AssetStatus__c' + 
                                    ', Account_Location__r.Apttus_Config2__AccountId__c ' +
                                    'FROM OperatingSchedule__c ' +
                                    'WHERE RecordType.Name = \'Machine Clean Operating\' ' + 
                                    'AND Active__c = true ' +
                                    'AND PhysicalAsset__c != null ' +
                                    'AND PhysicalAsset__r.MothballAssetIndicator__c = false ' + 
                                    'AND (PhysicalAsset__r.AssetStatus__c = \'Activated\' OR PhysicalAsset__r.AssetStatus__c = \'Pending Cancellation\') ' +
                                    'AND PhysicalAsset__r.AccountLocation__c != null ' + 
                                    'AND TypeofContract__c != null ' +
                                    'AND PhysicalAsset__c IN (SELECT PhysicalAssetId__c FROM Route_Line_Item__c WHERE RouteId__r.Account_Location__r.Mini_Sales_Organization__c IN ( \'SAP_6864\', \'SAP_0975\'))';
            
            //Karen Hung Jan 5, 2020 DOO-5149 Include NL if featureflag is enabled 
            if(flagEnabled || Test.isRunningTest()){
                
                QUERY_STRING = 'SELECT ' + String.join(fields, ',') + 
                                    ', PhysicalAsset__r.Name, PhysicalAsset__r.Product__c,  PhysicalAsset__r.SalesOrganization__c, PhysicalAsset__r.AccountLocation__c' +
                                    ', PhysicalAsset__r.Building__c,PhysicalAsset__r.AccountLocation__r.SAP_Customer_ID__c,PhysicalAsset__r.Floor__c' +
                                    ', PhysicalAsset__r.SoldTo__c, PhysicalAsset__r.OP_PreferredOperator__c, PhysicalAsset__r.MothballAssetIndicator__c, PhysicalAsset__r.Machine_Care__c' +
                                    ', PhysicalAsset__r.CounterReading__c, PhysicalAsset__r.Connected__c, PhysicalAsset__r.EndDate__c' + //Karen Hung DOO-2695 Added contract end date filter
                                    ', PhysicalAsset__r.AssetStatus__c' + 
                                    ', Account_Location__r.Apttus_Config2__AccountId__c ' +
                                    'FROM OperatingSchedule__c ' +
                                    'WHERE RecordType.Name = \'Machine Clean Operating\' ' + 
                                    'AND Active__c = true ' +
                                    'AND PhysicalAsset__c != null ' +
                                    'AND PhysicalAsset__r.MothballAssetIndicator__c = false ' + 
                                    'AND (PhysicalAsset__r.AssetStatus__c = \'Activated\' OR PhysicalAsset__r.AssetStatus__c = \'Pending Cancellation\') ' +
                                    'AND PhysicalAsset__r.AccountLocation__c != null ' + 
                                    'AND TypeofContract__c != null ' +
                                    'AND PhysicalAsset__c IN (SELECT PhysicalAssetId__c FROM Route_Line_Item__c WHERE RouteId__r.Account_Location__r.Mini_Sales_Organization__c IN ( \'SAP_0111\',\'SAP_6864\', \'SAP_0975\'))';
                
            }
            
            
            List<OperatingSchedule__c> OPS_LIST = Database.query(QUERY_STRING);
            Set<String> routeNames = new Set<String>();
            Map<String, Integer> largeAPIDaysMap = new Map<String, Integer>{'LM_1_Monday__c' => 0,'LM_1_Tuesday__c' => 1,'LM_1_Wednesday__c' => 2,'LM_1_Thursday__c' => 3,'LM_1_Friday__c' => 4, 'LM_1_Saturday__c' => 5, 'LM_1_Sunday__c' => 6};  
                
            Map<String, CountrySetting__c> countrySettingMap = new Map<String, CountrySetting__c>();
            
            //put mapping for country and cs
            String recordTypeId = Schema.SObjectType.CountrySetting__c.getRecordTypeInfosByName().get('Operating Task').getRecordTypeId(); //9.14.18 changed record type by karen hung
            List<CountrySetting__c> cList = [SELECT Country__c, DefaultStartTime__c, DefaultEndTime__c, Business_Hours__c FROM CountrySetting__c WHERE Active__c = true AND RecordTypeId =: recordTypeId];
            
            if(!cList.isEmpty()){
                for(CountrySetting__c cset : cList){
                    countrySettingMap.put(cset.Country__c, cset);   
                }
            }
                                    
            if(!OPS_LIST.isEmpty()){
                
                Map<String, PricebookEntry> pbeMap = TS_UtilityClass.createPriceBookEntryMap(OPS_LIST); //Karen Hung 9/3/2021 DOO-5268
                //PUT MAPPING FOR SCHEDULE RULES //Karen Hung 4.6.2020 updated to country setting map
                Map<String, List<CountrySetting__c>> orgSettingsMap = new Map<String, List<CountrySetting__c>>();
                for(CountrySetting__c cset: [SELECT Id, Country__c, From__c, To__c FROM CountrySetting__c
                                            WHERE Recordtype.Name = :TS_Constants.TS_COUNTRYSETTING_RECORDTYPE_MCO_PM_RULES
                                            AND Country__c IN (:TS_Constants.SAP_6864, :TS_Constants.SAP_0975)
                                            AND From__c != null
                                            AND To__c != null
                                            AND Active__c= true]){

                    if(orgSettingsMap.containsKey(cset.Country__c)){
                        orgSettingsMap.get(cset.Country__c).add(cset);
                    }else{
                        orgSettingsMap.put(cset.Country__c, new List<CountrySetting__c>{cset});    
                    } 
                }			
                
                Map<Id, OperatingSchedule__c> schedtoUpdateMap = new Map<Id, OperatingSchedule__c>();
                
                Map<String, Route_Line_Item__c> assetRLIMap = new Map<String, Route_Line_Item__c>();
                
                for(Route_Line_Item__c rli : [SELECT Id, PhysicalAssetId__c, RouteId__c, RouteId__r.Name, RouteId__r.Unique_Route_Number__c, RouteId__r.Preferred_Operator__c, RouteId__r.Required_Operator__c , RouteId__r.Account_Location__r.Mini_Sales_Organization__c, RouteId__r.Account_Location__c, RouteId__r.Account_Location__r.Apttus_Config2__AccountId__c
                                              FROM Route_Line_Item__c where PhysicalAssetId__c IN (SELECT PhysicalAsset__c FROM OperatingSchedule__c WHERE ID IN :OPS_LIST)]){
                    assetRLIMap.put(rli.PhysicalAssetId__c, rli);
                }

                Date earlyStartDate = runDate.addDays(countrySetting).toStartOfWeek(); //Monday of the week
                Date slaDate = earlyStartDate.addDays(4); //Friday of the week
                Integer numberOfDays = Date.daysInMonth(earlyStartDate.year(), earlyStartDate.month());
                Date lastDayOfMonth = Date.newInstance(earlyStartDate.year(), earlyStartDate.month(), numberOfDays);
                DateTime lastDayOfMonthdt = DateTime.newInstance(earlyStartDate.year(), earlyStartDate.month(), numberOfDays, 0, 0, 0);
                
                //variable for iteration
                Date slaDateMonthly = earlyStartDate.addDays(4); //friday of the week
                if(lastDayOfMonthdt.format(TS_Constants.CONST_EEEEE) == TS_Constants.CONST_SUNDAY){
                    lastDayOfMonth = lastDayOfMonth.addDays(-2);
                }else if(lastDayOfMonthdt.format(TS_Constants.CONST_EEEEE) == TS_Constants.CONST_SATURDAY){
                    lastDayOfMonth = lastDayOfMonth.addDays(-1);    
                }
                while (slaDateMonthly < lastDayOfMonth){
                    slaDateMonthly = slaDateMonthly.addDays(7);   
                }
                
                for(OperatingSchedule__c ops : OPS_LIST){
                    
                    PricebookEntry pbe = pbeMap.get(ops.PhysicalAsset__r.Product__c + ops.PhysicalAsset__r.SalesOrganization__c);// Karen Hung 9/3/2021 DOO-5268

                    Boolean hasLarge = ops.FrequencyofL__c != null && ops.FrequencyofL__c != TS_Constants.NA ? true : false;
                    
                    List<String> descalingMonths = ops.Descaling_Months__c != null ? ops.Descaling_Months__c.split(';') : null;
                    List<String> pmMonths = ops.PM_Months__c != null ? ops.PM_Months__c.split(';') : null;
                    List<String> waterFilterMonths = ops.Waterfilter_Months__c != null ? ops.Waterfilter_Months__c.split(';') : null;
                    List<String> bottleMonths = ops.Bottle_Months__c != null ? ops.Bottle_Months__c.split(';') : null;
                    List<String> largeMonths = ops.L_Months__c != null ? ops.L_Months__c.split(';') : null;
                    List<String> ingredientsMonths = ops.Ingredients_Months__c != null ? ops.Ingredients_Months__c.split(';') : null;
                    
                    String activityCombination = '';
                                        
                    //check if there's already PM created before and PM to be created in advanced from Schedule Rules
                    Boolean withPMAlready = false;
                    //Karen Hung DOO-4580 additional flags for water filter and large
                    Boolean withWFAlready = false;
                    Boolean withLargeAlready = false;
                    Set<String> advancedPMmonths = new Set<String>();

                    //Karen Hung DOO-4580 check if there's already PM created before and PM to be created in advanced using PM rules country setting for monthly schedule
                    if(orgSettingsMap != null && orgSettingsMap.containsKey(ops.Sales_Organization__c) && (!hasLarge || ops.FrequencyofL__c == TS_CONSTANTS.FREQUENCY_MONTHLY)){
                        for(CountrySetting__c pmRule : orgSettingsMap.get(ops.Sales_Organization__c)){
                            if(pmRule.From__c == monthToday && pmMonths !=null && pmMonths.contains(pmRule.From__c)){
                                withPMAlready = true;

                                //WF indicator if created in advanced already
                                if(waterFilterMonths != null && waterFilterMonths.contains(pmRule.From__c)){
                                    withWFAlready = true;
                                }
                                
                                //Large indicator if created in advanced already
                                if(largeMonths != null && largeMonths.contains(pmRule.From__c)){
                                    withLargeAlready = true;
                                }
                            }

                            //get advanced months to be created this month
                            if(pmRule.To__c == monthToday && pmMonths != null && pmMonths.contains(pmRule.From__c)){
                                advancedPMmonths.add(pmRule.From__c);    
                            }
                        }
                    }
                    
                    //check if there's PM for the month
                    if(pmMonths != null && pmMonths.contains(monthToday) && !withPMAlready){
                        activityCombination += 'P';
                    }
                    
                    //check if there's Waterfilter for the month  //Karen Hung DOO-4580 added  !withWFAlready
                    if(waterFilterMonths != null && waterFilterMonths.contains(monthToday) && !withWFAlready){
                        activityCombination += 'W';
                    }
                    
                    //check if there's Descaling for the month
                    if(descalingMonths != null && descalingMonths.contains(monthToday)){
                        activityCombination += 'D';
                    }
                    
                    //check if there's Bottle for the month
                    if(bottleMonths != null && bottleMonths.contains(monthToday)){
                        activityCombination += 'B';
                    }
                    
                    //check if there's Bottle for the month
                    if(ingredientsMonths != null && ingredientsMonths.contains(monthToday)){
                        activityCombination += 'I';
                    }
                    
                    //variables to be iterated weekly
                    Date slaWeekly = slaDate;
                    Date earlyStartWeekly = earlyStartDate;
                    
                    //variables for weekly scenario
                    Integer interval = ops.Interval_in_Weeks__c != null? Integer.valueOf(ops.Interval_in_Weeks__c) : 0; 
                    Date calculatedEarlyStart = ops.Last_Early_Start_Date__c != null && interval != 0 ? ops.Last_Early_Start_Date__c.addDays(interval * 7) : null;
                    
                    Integer largeOccurrence = 1;
                    
                    Integer endhour =  countrySettingMap.get(ops.Sales_Organization__c).DefaultEndTime__c == null ? 17 : Integer.valueOf(countrySettingMap.get(ops.Sales_Organization__c).DefaultEndTime__c);
                    
                    if(ops.FrequencyofL__c == TS_CONSTANTS.FREQUENCY_DAILY || ops.FrequencyofL__c == TS_Constants.FREQUENCY_WEEKLY){
                        while (slaWeekly <= slaDateMonthly){
                            //SCENARIO 1 : HAS LARGE AND DAILY
                            if(ops.FrequencyofL__c == TS_CONSTANTS.FREQUENCY_DAILY){
                                for(String largeApi : largeAPIDaysMap.keySet()){
                                    
                                    if(largeOccurrence == 1){
                                        activityCombination = activityCombination != '' ? 'L' + activityCombination : TS_CONSTANTS.ACTIVITY_LARGE;
                                    }else{
                                        activityCombination = TS_CONSTANTS.ACTIVITY_LARGE;
                                    }
                                    
                                    Date startDate = earlyStartWeekly.addDays(largeAPIDaysMap.get(largeApi));
                                    //create task if Schedule_Tasks_for_Holiday__c = true or within business hour
                                    //Karen Hung DOO-2695 Added contract end date filter
                                    if(ops.PhysicalAsset__r.EndDate__c >= startDate && activityCombination != '' && (ops.Schedule_Tasks_for_Holiday__c ||
                                       BusinessHours.isWithin(countrySettingMap.get(ops.Sales_Organization__c).Business_Hours__c, DateTime.newInstance(startDate.year(), startDate.month(), startDate.day(), endhour-1, 59, 59)))){
                                       String rowStr = ops.Name + ';' + ops.PhysicalAsset__r.Name + ';' + activityCombination + ';' + String.valueOf(startDate) + ';' + String.valueOf(startDate) + ';' + assetRLIMap.get(ops.PhysicalAsset__c).RouteId__c + ';' + assetRLIMap.get(ops.PhysicalAsset__c).RouteId__r.Name;
                                       
                                       //Karen Hung 9/3/2021 DOO-5268 add Operating Bucket in row
                                       if(flagEnabled){
										   String OPG_BUCKET = '';
                                           //single
                                           if(mcoActivityBucketAPIMap.containsKey(activityCombination)){
                                           		OPG_BUCKET = String.valueOf(pbe?.get(mcoActivityBucketAPIMap.get(activityCombination))) != null ? String.valueOf(pbe?.get(mcoActivityBucketAPIMap.get(activityCombination))) : '';
                                           //combination
                                           }else{
                                               OPG_BUCKET = TS_UtilityClass.operatingBucket(activityCombination,pbe);
                                           }
                                       		rowStr = ops.Name + ';' + ops.PhysicalAsset__r.Name + ';' + activityCombination + ';' + (OPG_Bucket != null ? OPG_Bucket : '') + ';' + String.valueOf(startDate) + ';' + String.valueOf(startDate) + ';' + assetRLIMap.get(ops.PhysicalAsset__c).RouteId__c + ';' + assetRLIMap.get(ops.PhysicalAsset__c).RouteId__r.Name;
                                       }
                                       
                                       CSVROWVALUES.add(rowStr);
                                       activityList.add(activityCombination);
                                       routeStartSLAString.add(assetRLIMap.get(ops.PhysicalAsset__c).RouteId__c + String.valueOf(startDate) + String.valueOf(startDate));    
                                           // wotoInsert.add(createWorkOrders(ops, assetRouteItemMap.get(ops.PhysicalAsset__c), startDate, startDate, pricebookMap, countrySettingMap,accLocContactMap));
                                           // wolitoInsert.add(createOperatingTasks(activityCombination, CONST_WORKORDER_OP_TYPE, ops, startDate, startDate, pBMap, countrySettingMap,assetRouteItemMap.get(ops.PhysicalAsset__c)));     
                                       largeOccurrence++;
                                    }
                                    
                                }
                                
                             //SCENARIO 2 : HAS LARGE AND WEEKLY   
                            }else if(ops.FrequencyofL__c == TS_Constants.FREQUENCY_WEEKLY){
                                //check weekly if earlystart matches calculated EarlyStart
                                if(calculatedEarlyStart != null && calculatedEarlyStart <= earlyStartWeekly && interval != 0){
                                    //SCENARIO 2.1 Weekly and Specific_Days_in_Week__c == TRUE
                                    if(ops.Specific_Days_in_Week__c){
                                        for(String largeApi : largeAPIDaysMap.keySet()){
                                            if(ops.get(largeApi) != null && String.valueOf(ops.get(largeApi)) ==  '1'){
                                                if(largeOccurrence == 1){ //add monthly required on first L occurrence
                                                    activityCombination = activityCombination != '' ? 'L' + activityCombination : TS_CONSTANTS.ACTIVITY_LARGE;
                                                }else{
                                                    activityCombination = TS_CONSTANTS.ACTIVITY_LARGE;
                                                }
                                                
                                                Date startDate = earlyStartWeekly.addDays(largeAPIDaysMap.get(largeApi));
                                                //Karen Hung DOO-2695 Added contract end date filter
                                                if(ops.PhysicalAsset__r.EndDate__c >= startDate && activityCombination != '' && (ops.Schedule_Tasks_for_Holiday__c ||
                                                   BusinessHours.isWithin(countrySettingMap.get(ops.Sales_Organization__c).Business_Hours__c, DateTime.newInstance(startDate.year(), startDate.month(), startDate.day(), endhour-1, 59, 59)))){
                                                       //wotoInsert.add(createWorkOrders(ops, assetRouteItemMap.get(ops.PhysicalAsset__c), startDate, startDate, pricebookMap, countrySettingMap,accLocContactMap));
                                                       //wolitoInsert.add(createOperatingTasks(activityCombination, CONST_WORKORDER_OP_TYPE, ops, startDate, startDate, pBMap, countrySettingMap,assetRouteItemMap.get(ops.PhysicalAsset__c)));
                                                    String rowStr = ops.Name + ';' + ops.PhysicalAsset__r.Name + ';' + activityCombination + ';' + String.valueOf(startDate) + ';' + String.valueOf(startDate) + ';' + assetRLIMap.get(ops.PhysicalAsset__c).RouteId__c + ';' + assetRLIMap.get(ops.PhysicalAsset__c).RouteId__r.Name;
                                                   
                                                   //Karen Hung 9/3/2021 DOO-5268 add Operating Bucket in row
                                                   if(flagEnabled){
                                                       String OPG_BUCKET = '';
                                                       //single
                                                       if(mcoActivityBucketAPIMap.containsKey(activityCombination)){
                                                            OPG_BUCKET = String.valueOf(pbe?.get(mcoActivityBucketAPIMap.get(activityCombination))) != null ? String.valueOf(pbe?.get(mcoActivityBucketAPIMap.get(activityCombination))) : '';
                                                       //combination
                                                       }else{
                                                           OPG_BUCKET = TS_UtilityClass.operatingBucket(activityCombination,pbe);
                                                       }
                                                       rowStr = ops.Name + ';' + ops.PhysicalAsset__r.Name + ';' + activityCombination + ';' + (OPG_Bucket != null ? OPG_Bucket : '') + ';' + String.valueOf(startDate) + ';' + String.valueOf(startDate) + ';' + assetRLIMap.get(ops.PhysicalAsset__c).RouteId__c + ';' + assetRLIMap.get(ops.PhysicalAsset__c).RouteId__r.Name;
                                                   }
                                                    CSVROWVALUES.add(rowStr);
                                                    activityList.add(activityCombination);
                                                    routeStartSLAString.add(assetRLIMap.get(ops.PhysicalAsset__c).RouteId__c + String.valueOf(startDate) + String.valueOf(startDate));  
                                                    largeOccurrence++;
                                                }
                                            }
                                        }
                                        
                                    //SCENARIO 2.2 Weekly and Specific_Days_in_Week__c == FALSE
                                    }else{
                                        if(largeOccurrence == 1){ //add monthly required on first L occurrence
                                            activityCombination = activityCombination != '' ? 'L' + activityCombination : TS_CONSTANTS.ACTIVITY_LARGE;
                                        }else{
                                            activityCombination = TS_CONSTANTS.ACTIVITY_LARGE;
                                        }

                                        //Karen Hung DOO-2695 Added contract end date filter
                                        if(ops.PhysicalAsset__r.EndDate__c >= earlyStartWeekly && activityCombination != ''){
                                            String rowStr = ops.Name + ';' + ops.PhysicalAsset__r.Name + ';' + activityCombination + ';' + String.valueOf(earlyStartWeekly) + ';' + String.valueOf(slaWeekly) + ';' + assetRLIMap.get(ops.PhysicalAsset__c).RouteId__c + ';' + assetRLIMap.get(ops.PhysicalAsset__c).RouteId__r.Name;
                                            //Karen Hung 9/3/2021 DOO-5268 add Operating Bucket in row
                                            if(flagEnabled){
                                                String OPG_BUCKET = '';
                                                //single
                                                if(mcoActivityBucketAPIMap.containsKey(activityCombination)){
                                                    OPG_BUCKET = String.valueOf(pbe?.get(mcoActivityBucketAPIMap.get(activityCombination))) != null ? String.valueOf(pbe?.get(mcoActivityBucketAPIMap.get(activityCombination))) : '';
                                                    //combination
                                                }else{
                                                    OPG_BUCKET = TS_UtilityClass.operatingBucket(activityCombination,pbe);
                                                }
                                                rowStr = ops.Name + ';' + ops.PhysicalAsset__r.Name + ';' + activityCombination + ';' + (OPG_Bucket != null ? OPG_Bucket : '') + ';' + String.valueOf(earlyStartWeekly) + ';' + String.valueOf(slaWeekly) + ';' + assetRLIMap.get(ops.PhysicalAsset__c).RouteId__c + ';' + assetRLIMap.get(ops.PhysicalAsset__c).RouteId__r.Name;
                                            }
                                            
                                            CSVROWVALUES.add(rowStr);
                                            activityList.add(activityCombination);
                                            routeStartSLAString.add(assetRLIMap.get(ops.PhysicalAsset__c).RouteId__c + String.valueOf(earlyStartWeekly) + String.valueOf(slaWeekly));  
                                        }
        
                                        largeOccurrence++;
                                    }
                                    calculatedEarlyStart = earlyStartWeekly.addDays(interval * 7);
                                    schedtoUpdateMap.put(ops.Id, ops);                                    
                                }                                
                            }
                            earlyStartWeekly = earlyStartWeekly.addDays(7);
                            slaWeekly = earlyStartWeekly.addDays(4); 
                        }
                        
                         //for skip month scenario
                         //Karen Hung DOO-2695 Added contract end date filter
                        if(ops.PhysicalAsset__r.EndDate__c >= earlyStartDate && ops.FrequencyofL__c == TS_Constants.FREQUENCY_WEEKLY && !schedtoUpdateMap.containsKey(ops.Id) && activityCombination != ''){
                            activityCombination = activityCombination == 'L' ? TS_CONSTANTS.ACTIVITY_LARGE : activityCombination == 'P' ? TS_CONSTANTS.ACTIVITY_PM : activityCombination == 'W' ? TS_CONSTANTS.ACTIVITY_WATERFILTER : activityCombination == 'D' ? TS_CONSTANTS.ACTIVITY_DESCALING :  activityCombination == 'B' ? TS_CONSTANTS.ACTIVITY_BOTTLE : activityCombination == 'I' ? TS_CONSTANTS.ACTIVITY_INGREDIENTS : activityCombination;
                            String rowStr = ops.Name + ';' + ops.PhysicalAsset__r.Name + ';' + activityCombination + ';' + String.valueOf(earlyStartDate) + ';' + String.valueOf(slaDateMonthly) + ';' + assetRLIMap.get(ops.PhysicalAsset__c).RouteId__c + ';' + assetRLIMap.get(ops.PhysicalAsset__c).RouteId__r.Name;
                            //Karen Hung 9/3/2021 DOO-5268 add Operating Bucket in row
                            if(flagEnabled){
                                String OPG_BUCKET = '';
                                //single
                                if(mcoActivityBucketAPIMap.containsKey(activityCombination)){
                                    OPG_BUCKET = String.valueOf(pbe?.get(mcoActivityBucketAPIMap.get(activityCombination))) != null ? String.valueOf(pbe?.get(mcoActivityBucketAPIMap.get(activityCombination))) : '';
                                //combination
                                }else{
                                    OPG_BUCKET = TS_UtilityClass.operatingBucket(activityCombination,pbe);                                    
                                }
                                rowStr =  ops.Name + ';' + ops.PhysicalAsset__r.Name + ';' + activityCombination + ';' + (OPG_Bucket != null ? OPG_Bucket : '')  + ';' + String.valueOf(earlyStartDate) + ';' + String.valueOf(slaDateMonthly) + ';' + assetRLIMap.get(ops.PhysicalAsset__c).RouteId__c + ';' + assetRLIMap.get(ops.PhysicalAsset__c).RouteId__r.Name;
                            }
                            
                            CSVROWVALUES.add(rowStr);
                            activityList.add(activityCombination);
                            routeStartSLAString.add(assetRLIMap.get(ops.PhysicalAsset__c).RouteId__c + String.valueOf(earlyStartDate) + String.valueOf(slaDateMonthly));
                            
                        }
                        
                    //SCENARIO 3: WITHOUT LARGE OR HAS MONTHLY FREQUENCY      
                    }else{
                        //check if there's Large for the month  //Karen Hung 4.6.2020 DOO-4580 added withLargeAlready criteria                
                        String comboMonthly = largeMonths != null && largeMonths.contains(monthToday) && !withLargeAlready ? 'L' + activityCombination : activityCombination;
                        comboMonthly = comboMonthly == 'L' ? TS_CONSTANTS.ACTIVITY_LARGE : comboMonthly == 'P' ? TS_CONSTANTS.ACTIVITY_PM : comboMonthly == 'W' ? TS_CONSTANTS.ACTIVITY_WATERFILTER : comboMonthly == 'D' ? TS_CONSTANTS.ACTIVITY_DESCALING :  comboMonthly == 'B' ? TS_CONSTANTS.ACTIVITY_BOTTLE : comboMonthly == 'I' ? TS_CONSTANTS.ACTIVITY_INGREDIENTS : comboMonthly;
                        
                        //create workOrder for monthly jobs with woli for combined monthly type
                        //Karen Hung DOO-2695 Added contract end date filter
                        if(ops.PhysicalAsset__r.EndDate__c >= earlyStartDate && comboMonthly != ''){
                            String rowStr = ops.Name + ';' + ops.PhysicalAsset__r.Name + ';' + comboMonthly + ';' + String.valueOf(earlyStartDate) + ';' + String.valueOf(slaDateMonthly) + ';' + assetRLIMap.get(ops.PhysicalAsset__c).RouteId__c + ';' + assetRLIMap.get(ops.PhysicalAsset__c).RouteId__r.Name;
                            //Karen Hung 9/3/2021 DOO-5268 add Operating Bucket in row
                            if(flagEnabled){
                                String OPG_BUCKET = '';
                                //single
                                if(mcoActivityBucketAPIMap.containsKey(comboMonthly)){
                                    OPG_BUCKET = String.valueOf(pbe?.get(mcoActivityBucketAPIMap.get(comboMonthly))) != null ? String.valueOf(pbe?.get(mcoActivityBucketAPIMap.get(comboMonthly))) : '';
                                 //combination
                                }else{
                                    OPG_BUCKET = TS_UtilityClass.operatingBucket(comboMonthly,pbe);
                                }
                                rowStr =  ops.Name + ';' + ops.PhysicalAsset__r.Name + ';' + comboMonthly + ';' + (OPG_Bucket != null ? OPG_Bucket : '') + ';' + String.valueOf(earlyStartDate) + ';' + String.valueOf(slaDateMonthly) + ';' + assetRLIMap.get(ops.PhysicalAsset__c).RouteId__c + ';' + assetRLIMap.get(ops.PhysicalAsset__c).RouteId__r.Name;
                            }
                            CSVROWVALUES.add(rowStr);
                            activityList.add(comboMonthly);
                            routeStartSLAString.add(assetRLIMap.get(ops.PhysicalAsset__c).RouteId__c + String.valueOf(earlyStartDate) + String.valueOf(slaDateMonthly));
                            
                        }
                    }
                    
                    //check PM jobs to be created in advance
                    if(!advancedPMmonths.isEmpty() && (ops.FrequencyofL__c == 'Monthly' || !hasLarge)){ //Karen Hung 4.6.2020 DOO-4580 added criteria
                        for(String pmMonth : advancedPMmonths){
                            
                            Integer year = pmMonth > monthToday ? earlyStartDate.year() : earlyStartDate.year() + 1;
                            
                            //determine first monday of the month
                            DateTime firstOfMonth =  DateTime.newInstance(year, Integer.valueOf(pmMonth), 1, 0, 0, 0);
                            Integer day = firstOfMonth.format(TS_CONSTANTS.CONST_EEEEE)  == TS_CONSTANTS.CONST_MONDAY ? 1 : firstOfMonth.date().addDays(7).toStartOfWeek().day();
                            Date earlyStartAdvMonth = Date.newInstance(year, Integer.valueOf(pmMonth), day);
                            
                            //determine last day of that month
                            Integer numberOfDaysAdv = Date.daysInMonth(earlyStartAdvMonth.year(), earlyStartAdvMonth.month());
                            Date lastDayOfMonthAdv = Date.newInstance(earlyStartAdvMonth.year(), earlyStartAdvMonth.month(), numberOfDaysAdv);
                            DateTime lastDayOfAdvMonthdt = DateTime.newInstance(earlyStartAdvMonth.year(), earlyStartAdvMonth.month(), numberOfDaysAdv, 0, 0, 0);
                            if(lastDayOfAdvMonthdt.format(TS_CONSTANTS.CONST_EEEEE) == TS_CONSTANTS.CONST_SUNDAY){
                                lastDayOfMonthAdv = lastDayOfMonthAdv.addDays(-2);
                            }else if(lastDayOfAdvMonthdt.format(TS_CONSTANTS.CONST_EEEEE) == TS_CONSTANTS.CONST_SATURDAY){
                                lastDayOfMonthAdv = lastDayOfMonthAdv.addDays(-1);    
                            }
                            Date pmSLA = earlyStartAdvMonth.addDays(4);
                            while(pmSLA < lastDayOfMonthAdv){
                                pmSLA = pmSLA.addDays(7);
                            }

                            //Karen Hung 3.6.2020 DOO-4580 String Combination for advanced task
                            String advancedTasks = '';
                            if(largeMonths != null && largeMonths.contains(pmMonth)){
                                advancedTasks = 'L';
                            }

                            if(pmMonths != null && pmMonths.contains(pmMonth)){
                                advancedTasks += 'P';
                            }                               

                            if(waterFilterMonths != null && waterFilterMonths.contains(pmMonth)){
                                advancedTasks += 'W'; 
                            }
                            
                            //create tasks in advance
                            //String rowStr = ops.Name + ',' + ops.PhysicalAsset__r.Name + ',' + TS_CONSTANTS.ACTIVITY_PM + ',' + String.valueOf(earlyStartDate) + ',' + String.valueOf(pmSLA) + ',' + assetRLIMap.get(ops.PhysicalAsset__c).RouteId__c + ',' + assetRLIMap.get(ops.PhysicalAsset__c).RouteId__r.Name;
                            //Karen Hung DOO-2695 Added contract end date filter
                            if(ops.PhysicalAsset__r.EndDate__c >= earlyStartDate){
                                String rowStr = ops.Name + ';' + ops.PhysicalAsset__r.Name + ';' + (advancedTasks == 'P'? TS_CONSTANTS.ACTIVITY_PM : advancedTasks) + ';' + String.valueOf(earlyStartDate) + ';' + String.valueOf(pmSLA) + ';' + assetRLIMap.get(ops.PhysicalAsset__c).RouteId__c + ';' + assetRLIMap.get(ops.PhysicalAsset__c).RouteId__r.Name;
                                 //Karen Hung 9/3/2021 DOO-5268 add Operating Bucket in row
                                if(flagEnabled){
                                    String OPG_BUCKET = '';
                                    //single
                                    if(mcoActivityBucketAPIMap.containsKey((advancedTasks == 'P'? TS_CONSTANTS.ACTIVITY_PM : advancedTasks))){
                                        OPG_BUCKET = String.valueOf(pbe?.get(mcoActivityBucketAPIMap.get((advancedTasks == 'P'? TS_CONSTANTS.ACTIVITY_PM : advancedTasks)))) != null ? String.valueOf(pbe?.get(mcoActivityBucketAPIMap.get((advancedTasks == 'P'? TS_CONSTANTS.ACTIVITY_PM : advancedTasks)))) : '';
                                    //combination
                                    }else{
                                        OPG_BUCKET = TS_UtilityClass.operatingBucket(advancedTasks,pbe);
                                    }
                                    rowStr =  ops.Name + ';' + ops.PhysicalAsset__r.Name + ';' + (advancedTasks == 'P'? TS_CONSTANTS.ACTIVITY_PM : advancedTasks) + ';' + (OPG_Bucket != null ? OPG_Bucket : '') + ';' + String.valueOf(earlyStartDate) + ';' + String.valueOf(pmSLA) + ';' + assetRLIMap.get(ops.PhysicalAsset__c).RouteId__c + ';' + assetRLIMap.get(ops.PhysicalAsset__c).RouteId__r.Name;
                                }
                                
                                CSVROWVALUES.add(rowStr);
                                activityList.add(advancedTasks == 'P'? TS_CONSTANTS.ACTIVITY_PM : advancedTasks);
                                //activityList.add(TS_CONSTANTS.ACTIVITY_PM);
                                routeStartSLAString.add(assetRLIMap.get(ops.PhysicalAsset__c).RouteId__c + String.valueOf(earlyStartDate) + String.valueOf(pmSLA));
                            }
                                                      
                           // wotoInsert.add(createWorkOrders(ops, assetRouteItemMap.get(ops.PhysicalAsset__c), earlyStartDate, pmSLA, pricebookMap, countrySettingMap,accLocContactMap));
                            //wolitoInsert.add(createOperatingTasks(TS_CONSTANTS.ACTIVITY_PM, CONST_WORKORDER_OP_TYPE, ops, earlyStartDate, pmSLA, pBMap, countrySettingMap,assetRouteItemMap.get(ops.PhysicalAsset__c)));
                        }
                    }
                }
                
                List<Folder> folders = [SELECT Id, Name FROM Folder WHERE Name = 'Batch Pre-Load Reports'];
                system.debug(folders);
                if(!folders.isEmpty()){
                    //DateTime runDatedt = Datetime.newInstance(runDate.year(),runDate.month(), runDate.day(),0,0,0);
                    String documentName = 'PRELOAD_MACHINE_CLEAN_OPERATING_FOR_' + String.valueOf(runDate) + ' ' + String.valueOf(Datetime.now());
                    csvColumnHeader = 'NAME; PHYSICAL ASSET; ACTIVITY TYPE; START DATE; SLA DATE; ROUTE ID; ROUTE\n';
                    if(flagEnabled) csvColumnHeader = 'NAME; PHYSICAL ASSET; ACTIVITY TYPE; OPG BUCKET; START DATE; SLA DATE; ROUTE ID; ROUTE\n';
                    String csvFile = csvColumnHeader + String.join(CSVROWVALUES, '\n');
                    
                    Document doc = new Document(Name = documentName, Body = Blob.valueOf(csvFile), FolderId = folders[0].Id, Type = 'csv', ContentType = 'application/vnd.ms-excel');
                    insert doc;
                    
                    docId = doc.Id;
                }
                
                //summarize activity types
                Map<String, Integer> activityCountMap = new Map<String, Integer>();
                for(String act: activityList){
                    Integer count = 1;
                    if(activityCountMap.containsKey(act)){
                      count = activityCountMap.get(act) + 1;
                    }
                    activityCountMap.put(act, count);
                }
      
                String actSummary = '';
      
                for(String actStr : activityCountMap.keySet()){
                  actSummary += '\n' + actStr + ': ' + String.valueOf(activityCountMap.get(actStr));
                }
              
               //Custom log creation to check parameter
               Custom_Log__c log = new Custom_Log__c(
                  Name = 'Machine Clean Operating ' + String.valueOf(System.now()),
                  StackTrace__c = 'TS_MCOperating_Batch',
                  Message__c = 'This is a log to monitor the parameters provided to the machine clean operating scheduler class and to generate a pre-load report.' 
                  + '\n\n' + 'RUN DATE: ' + String.valueOf(runDate) 
                  + '\n' + 'ADD DAYS: ' + String.valueOf(Label.TS_CountrySetting) 
                  + '\n' + 'COUNTRY: NORDICS' 
                  + '\n' + 'BATCH TYPE: MACHINE CLEAN OPERATING'
                  + '\n' + 'BATCH COVERAGE: ' + String.valueOf(earlyStartDate) + ' to ' + String.valueOf(slaDateMonthly)
                  + '\n\n' + 'NUMBER OF WORK ORDERS: ' + (routeStartSLAString != null? String.valueOf(routeStartSLAString.size()) : '0')
                  + '\n' + 'NUMBER OF MACHINE ACTIONS: ' +  (CSVROWVALUES != null? String.valueOf(CSVROWVALUES.size()) : '0')
                  + '\n\n' + 'ACTIVITY TYPES: '
                  + actSummary
                  + '\n\n' + 'PRELOAD_REPORT_LINK: ' + initialURL + docId
                  );
            
               insert log;
            
            }

        }
       
        CustomLogging.pop();
        //return RET_STR;
    }
    
    /**
    * @author        Karen Hung
    * @date          Dec 23, 2020
    * @description   DOO-5149 Method to generate pre-load script and attach basic information for custom log for daily route.
    * @revision(s)
    */ 
    public void PRELOAD_SCRIPT_NEW (Date nextDate, String batchType, String BUSINESS_ID, Boolean IS_CR_DAY) {
        
        //GET ROUTES WITH HOLIDAYS
        Map<Id, Route__c> routeWithHoliday = new Map<Id, Route__c>([SELECT Id FROM Route__c WHERE Account_Location__c IN (SELECT Account_Location__c FROM Customer_Holiday__c WHERE From__c <=: nextDate AND Day__c >=: nextDate)]);
        
        String CONST_SmallTask_API = Label.TS_Operating_Small;
        String CONST_LargeTask_API = Label.TS_Operating_Large;
        String CONST_RinseTask_API = Label.TS_Operating_Rinse;
        String CONST_CupsTask_API = Label.TS_Operating_Cups;

        List<String> CSVROWVALUES_SMALL = new List<String>();
        List<String> CSVROWVALUES_LARGE = new List<String>();
        List<String> CSVROWVALUES_CUP = new List<String>();
        List<String> CSVROWVALUES_RINSE = new List<String>();
        List<String> CSVROWVALUES_SMALL_3RDPARTY = new List<String>();
        List<String> CSVROWVALUES_CUP_3RDPARTY = new List<String>();

        Integer TOTAL_CUPS = 0;
        Integer TOTAL_RINSE = 0;
        Integer TOTAL_LARGE = 0;
        Integer TOTAL_LARGE_CR = 0;
        Integer TOTAL_LARGE_CR_HOLIDAY = 0; 
        Integer TOTAL_SMALL = 0;
        Integer NUM_WORKORDER = 0;
        Integer OP_SCHED_SIZE = 0; 
        Integer TOTAL_CUPS_HOLIDAY = 0;
        Integer TOTAL_RINSE_HOLIDAY = 0;
        Integer TOTAL_LARGE_HOLIDAY = 0;
        Integer TOTAL_SMALL_HOLIDAY = 0; 
        
        DateTime scheduledDate = nextDate;
        Boolean isHoliday = false;
        if(batchType == null || batchType == 'null'){
            isHoliday = true;
        }
        
        DescribeSObjectResult operatingScheduleDescribe = OperatingSchedule__c.getSObjectType().getDescribe();
        List<String> fields = new List<String>(operatingScheduleDescribe.fields.getMap().keySet());
        String QUERY_STRING = 'SELECT ' + String.join(fields, ',') +
            ', PhysicalAsset__r.Name, PhysicalAsset__r.CounterReading__c, PhysicalAsset__r.AccountLocation__c, PhysicalAsset__r.AccountLocation__r.Name, PhysicalAsset__r.AccountLocation__r.Apttus_Config2__PostalCode__c, PhysicalAsset__r.AccountLocation__r.Apttus_Config2__City__c, PhysicalAsset__r.AccountLocation__r.Apttus_Config2__Street__c, PhysicalAsset__r.AccountLocation__r.Shipping_Street_Only__c' +
            ', PhysicalAsset__r.Connected__c, PhysicalAsset__r.Machine_Care__c, PhysicalAsset__r.Product__c, PhysicalAsset__r.SalesOrganization__c, PhysicalAsset__r.Product__r.Name, PhysicalAsset__r.Building__c, PhysicalAsset__r.Floor__c, PhysicalAsset__r.Area__c, PhysicalAsset__r.CustomerReferenceNumber__c' + 
            ' FROM ' + operatingScheduleDescribe.getName() + 
            ' WHERE OperatingReady__c = true AND Schedule_Type__c = \'Regular\' AND PhysicalAsset__r.EndDate__c >= :nextDate' + //Karen Hung DOO-2695 Added contract end date filter
            (isHoliday ? ' AND Schedule_Tasks_for_Holiday__c = true' : '' ) +
            ' AND TypeofContract__c IN (\'Full Operating\', \'Comfort Operating\')' + 
            ' AND PhysicalAsset__c IN (SELECT PhysicalAssetId__c FROM Route_Line_Item__c WHERE RouteId__r.Account_Location__r.Mini_Sales_Organization__c =  \'SAP_0111\')' + 
            ' ORDER BY PhysicalAsset__r.AccountLocation__r.Account_Location_ID__c, PhysicalAsset__r.Name';
        
        List<OperatingSchedule__c> OPS_LIST = Database.query(QUERY_STRING);
        Set<String> routeNames = new Set<String>();
        Set<String> routeNames_holiday = new Set<String>();
        Map<String, Set<String>> routeNames3P = new Map<String, Set<String>>();
        Map<String, Set<String>> routeNames_holiday3P = new Map<String, Set<String>>();
        
        Map<String, List<String>> resourceRowsMap = new Map<String, List<String>>();
        Map<String, Integer> resSmallCountMap = new Map<String, Integer>();
        Map<String, Integer> resSmallHolidayCountMap = new Map<String, Integer>();
        Map<String, Integer> resCupsCountMap = new Map<String, Integer>();
        Map<String, Integer> resCupsHolidayCountMap = new Map<String, Integer>();
        
        Id rt = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c', Label.TS_OperatingTaskRecordType);
        
        List<CountrySetting__c> countrySettings = [SELECT id, DefaultStartTime__c, DefaultEndTime__c, NumberDayToLookup__c, Business_Hours__r.id
                                                   FROM CountrySetting__c
                                                   WHERE tolabel(Country__c) = :country_Name
                                                   And Active__c = TRUE
                                                   And RecordTypeId = :rt limit 1];
        
        Integer startHour = countrySettings.size() != 0 && countrySettings[0].DefaultStartTime__c != null ? Integer.valueOf(countrySettings[0].DefaultStartTime__c) : 5;
        DateTime earlyStartDate = DateTime.newInstance(nextDate.year(), nextDate.month(), nextDate.day(), starthour, 0, 0);
        
        if(!OPS_LIST.isEmpty()){
            
            Map<String, PricebookEntry> pbeMap = TS_UtilityClass.createPriceBookEntryMap(OPS_LIST); //Karen Hung 9/3/2021 DOO-5268
            
            //GET ALL PHYSICAL ASSET AND ACCOUNT LOCATION
            Set<Id> pa_list_set = new Set<Id>();
            Set<Id> location_set = new Set<Id>();
            for (OperatingSchedule__c OP_VAR: OPS_LIST) {
                pa_list_set.add(OP_VAR.PhysicalAsset__c);
                location_set.add(OP_VAR.PhysicalAsset__r.AccountLocation__c);
            }
            
            //GET ALL ROUTES AND ROUTE LINE ITEMS AND PUT IN MAP
            List<Route_Line_Item__c> rli_list = new List<Route_Line_Item__c> ();
            Map<Id, Route_Line_Item__c> map_pa_rli = new Map<Id, Route_Line_Item__c> ();
            if (!pa_list_set.isEmpty()) {
                rli_list = [SELECT Id, RouteId__c, RouteId__r.Name, PhysicalAssetId__c FROM Route_Line_Item__c WHERE PhysicalAssetId__c IN: pa_list_set];
                
                if (!rli_list.isEmpty()) {
                    for (Route_Line_Item__c rli_var: rli_list) {
                        map_pa_rli.put(rli_var.PhysicalAssetId__c, rli_var);
                    }
                }
            }
            
            //create mapping for account location to add third party details
            Map<String, Apttus_Config2__AccountLocation__c> locationMap = new Map<String,Apttus_Config2__AccountLocation__c>([SELECT Id, Third_Party_Resource__c, Third_Party_Resource__r.Name FROM Apttus_Config2__AccountLocation__c WHERE Id IN :location_set]);
            
            OP_SCHED_SIZE = OPS_LIST.size();
            for(OperatingSchedule__c OP_VAR : OPS_LIST){
                
                Boolean isThirdParty = !locationMap.isEmpty() && locationMap.get(OP_VAR.PhysicalAsset__r.AccountLocation__c).Third_Party_Resource__c != null ? true : false;
                PricebookEntry pbe = pbeMap.get(OP_VAR.PhysicalAsset__r.Product__c + OP_VAR.PhysicalAsset__r.SalesOrganization__c);
                
                if (!map_pa_rli.containsKey(OP_VAR.PhysicalAsset__c)) continue;
                
                String ROUTE_NAME_STR = map_pa_rli.get(OP_VAR.PhysicalAsset__c).RouteId__r.Name;
                String ROUTE_ID_STR = map_pa_rli.get(OP_VAR.PhysicalAsset__c).RouteId__c;
                
                String IS_HOLIDAY = routeWithHoliday.containsKey(ROUTE_ID_STR) ? 'TRUE' : 'FALSE';
                
                //GET WEEK NUMBER
                Date d1 = OP_VAR.Start_Date__c.toStartOfWeek();
                Date d2 = scheduledDate.date().toStartOfWeek();
                Integer numberOfWeeks = d1.daysBetween(d2) / 7;
                String WEEK_NUM = String.valueOf(Math.mod(numberOfWeeks, 2) == 0 ? 1 : 2);
                                
                //GET LARGE (for non-third-party only)
                String LARGE_API = CONST_LargeTask_API + '_' + WEEK_NUM + '_' + scheduledDate.format('EEEE') + '__c';
                if(OP_VAR.get(LARGE_API) != null){ //Karen Hung DOO-5289 4/3/2021 removed  && !isThirdParty
                    String VAL_LARGE = String.valueOf(OP_VAR.get(LARGE_API));
                    if (!VAL_LARGE.equals('0') && VAL_LARGE != null) {
                        TOTAL_LARGE++;
                        
                        if(OP_VAR.PhysicalAsset__r.CounterReading__c == 'Yes' &&
                           OP_VAR.PhysicalAsset__r.Connected__c == 'No' &&
                           (OP_VAR.PhysicalAsset__r.Machine_Care__c == 'Full Operating' || OP_VAR.PhysicalAsset__r.Machine_Care__c == 'Comfort Operating')){
                               
                               TOTAL_LARGE_CR++;
                               if(IS_HOLIDAY == 'TRUE') TOTAL_LARGE_CR_HOLIDAY++;
                           }
                        
                        String OPSCHED_NAME = OP_VAR.Name != null ? OP_VAR.Name : '';
                        String OPSCHED_PHYSICALASSET = OP_VAR.PhysicalAsset__r.Name != null ? OP_VAR.PhysicalAsset__r.Name : '';
                        String OPSCHED_STARTDATE = String.valueOf(OP_VAR.Start_Date__c);
                        String FIELD_API = LARGE_API != null ? LARGE_API : '';
                        String OPG_BUCKET = String.valueOf(pbe?.get(activityAPIMap.get(TS_Constants.ACTIVITY_LARGE))) != null ? String.valueOf(pbe?.get(activityAPIMap.get(TS_Constants.ACTIVITY_LARGE))) : ''; //Karen Hung 8/3/2021 DOO-5268 Added Bucket
                        String FIELD_VALUE = String.valueOf(1);                        
                        
                        String ROUTE_ID = ROUTE_ID_STR;
                        String ROUTE_NAME = ROUTE_NAME_STR;
                        
                        //Karen Hung 8/3/2021 DOO-5268 Added Bucket
                        String rowStr = OPSCHED_NAME + ';' + OPSCHED_PHYSICALASSET + ';' + OPSCHED_STARTDATE + ';' + FIELD_API + ';' + OPG_BUCKET + ';' + FIELD_VALUE + ';' + ROUTE_ID + ';' + IS_HOLIDAY + ';' + ROUTE_NAME;
                        CSVROWVALUES_LARGE.add(rowStr);
                        routeNames.add(ROUTE_ID_STR);
                        
                        if(IS_HOLIDAY == 'TRUE') {
                            TOTAL_LARGE_HOLIDAY = TOTAL_LARGE_HOLIDAY + 1;
                            routeNames_holiday.add(ROUTE_ID_STR);
                        }
                    }
                }
                
                //GET SMALL
                String SMALL_API = CONST_SmallTask_API + '_' + WEEK_NUM + '_' + scheduledDate.format('EEEE') + '__c';
                if(OP_VAR.get(SMALL_API) != null){
                    String VAL_SMALL = String.valueOf(OP_VAR.get(SMALL_API));
                    if (!VAL_SMALL.equals('0') && VAL_SMALL != null) {
                        
                        Integer INDICATOR_VAR_SMALL = 0;
                        
                        if (VAL_SMALL.equals('AM') || VAL_SMALL.equals('PM')) {
                            
                            //count for non-ThirdParty TOTAL_SMALL
                            if(!isThirdParty) TOTAL_SMALL++;
                                                        
                            INDICATOR_VAR_SMALL = 1;
                            
                            //count for ThirdParty TOTAL_SMALL
                            if(isThirdParty){
                                String thirdPartyResource = locationMap.get(OP_VAR.Account_Location__c).Third_Party_Resource__c;
                                if(resSmallCountMap.containsKey(thirdPartyResource)){
                                    Integer small = resSmallCountMap.get(thirdPartyResource) + 1;
                                    resSmallCountMap.put(thirdPartyResource,small);
                                }else{
                                    resSmallCountMap.put(thirdPartyResource, 1);    
                                }
                            }
                            
                        } else if (Integer.valueOf(VAL_SMALL) > 0) {
                            
                            Integer int_val = Integer.valueOf(VAL_SMALL);
                            
                            //count for non-ThirdParty TOTAL_SMALL
                            if(!isThirdParty) TOTAL_SMALL = TOTAL_SMALL + int_val;
                            INDICATOR_VAR_SMALL = int_val;
                 
                           //count for ThirdParty TOTAL_SMALL
                            if(isThirdParty){
                                String thirdPartyResource = locationMap.get(OP_VAR.Account_Location__c).Third_Party_Resource__c;
                                if(resSmallCountMap.containsKey(thirdPartyResource)){
                                    Integer small = resSmallCountMap.get(thirdPartyResource) + INDICATOR_VAR_SMALL;
                                    resSmallCountMap.put(thirdPartyResource,small);
                                }else{
                                    resSmallCountMap.put(thirdPartyResource, INDICATOR_VAR_SMALL);    
                                }
                            }
                        }
                        
                        String OPSCHED_NAME = OP_VAR.Name != null ? OP_VAR.Name : '';
                        String OPSCHED_PHYSICALASSET = OP_VAR.PhysicalAsset__r.Name != null ? OP_VAR.PhysicalAsset__r.Name : '';
                        String OPSCHED_STARTDATE = String.valueOf(OP_VAR.Start_Date__c);
                        String FIELD_API = SMALL_API != null ? SMALL_API : '';
                        String OPG_BUCKET = String.valueOf(pbe?.get(activityAPIMap.get(TS_Constants.ACTIVITY_SMALL))) != null ? String.valueOf(pbe?.get(activityAPIMap.get(TS_Constants.ACTIVITY_SMALL))) : ''; //Karen Hung 8/3/2021 DOO-5268 Added Bucket
                        String FIELD_VALUE = String.valueOf(INDICATOR_VAR_SMALL) != null ? String.valueOf(INDICATOR_VAR_SMALL) : '';
                        String ROUTE_ID = ROUTE_ID_STR;
                        String ROUTE_NAME = ROUTE_NAME_STR;
                        String EARLY_START_DATE = String.valueOf(earlyStartDate);
                        String ACCLOC_NAME = OP_VAR.PhysicalAsset__r.AccountLocation__r.Name != null ? OP_VAR.PhysicalAsset__r.AccountLocation__r.Name : '';
                        String ACCLOC_STREET = OP_VAR.PhysicalAsset__r.AccountLocation__r.Apttus_Config2__Street__c != null ? OP_VAR.PhysicalAsset__r.AccountLocation__r.Apttus_Config2__Street__c.replace(';', ' ') : '';
                        String ACCLOC_CITY =  OP_VAR.PhysicalAsset__r.AccountLocation__r.Apttus_Config2__City__c != null ? OP_VAR.PhysicalAsset__r.AccountLocation__r.Apttus_Config2__City__c.replace(';', ' ') : '';
                        String ACCLOC_PC = OP_VAR.PhysicalAsset__r.AccountLocation__r.Apttus_Config2__PostalCode__c != null ? OP_VAR.PhysicalAsset__r.AccountLocation__r.Apttus_Config2__PostalCode__c.replace(';', ' ') : '';
                        String PHA_PRODUCTNAME = OP_VAR.PhysicalAsset__r.Product__r.Name != null ? OP_VAR.PhysicalAsset__r.Product__r.Name.replace(';', ' ') : '';
                        String PHA_BUILDING =  OP_VAR.PhysicalAsset__r.Building__c != null ? OP_VAR.PhysicalAsset__r.Building__c.replace(';', ' ') : '';
                        String PHA_FLOOR = OP_VAR.PhysicalAsset__r.Floor__c != null ? OP_VAR.PhysicalAsset__r.Floor__c.replace(';', ' ') : '';
                        String PHA_AREA = OP_VAR.PhysicalAsset__r.Area__c != null ? OP_VAR.PhysicalAsset__r.Area__c.replace(';', ' ') : '';
                        String PHA_CUSTOMERREF = OP_VAR.PhysicalAsset__r.CustomerReferenceNumber__c != null ? OP_VAR.PhysicalAsset__r.CustomerReferenceNumber__c.replace(';', ' ') : '';
                        String ACTIVITY_TYPE = TS_Constants.ACTIVITY_SMALL;                       
                        
                        //SMALL CSV LINES FOR NON 3RD PARTY
                        if(!isThirdParty){
                            //Karen Hung 8/3/2021 DOO-5268 Added Bucket
                            String rowStr = OPSCHED_NAME + ';' + OPSCHED_PHYSICALASSET + ';' + OPSCHED_STARTDATE + ';' + FIELD_API + ';' + OPG_BUCKET + ';' + FIELD_VALUE + ';' + ROUTE_ID + ';' + IS_HOLIDAY + ';' + ROUTE_NAME;
                            CSVROWVALUES_SMALL.add(rowStr);
                            routeNames.add(ROUTE_ID_STR);
                            
                            if(IS_HOLIDAY == 'TRUE') {
                                TOTAL_SMALL_HOLIDAY = TOTAL_SMALL_HOLIDAY + INDICATOR_VAR_SMALL;
                                routeNames_holiday.add(ROUTE_ID_STR);
                            }    
                        }
                        
                        //SMALL CSV LINES FOR 3RD PARTY
                        if(isThirdParty){
                            //Karen Hung 8/3/2021 DOO-5268 Added Bucket
                            String rowStr = EARLY_START_DATE + ';' + ACCLOC_NAME + ';' + ACCLOC_STREET + ';' + ACCLOC_CITY + ';' + ACCLOC_PC + ';' + OPSCHED_PHYSICALASSET + ';' + PHA_PRODUCTNAME + ';' + PHA_BUILDING + ';' + PHA_FLOOR + ';' + PHA_AREA + ';' + PHA_CUSTOMERREF + ';' + ACTIVITY_TYPE + ';' + OPG_BUCKET + ';' + FIELD_VALUE + ';' + IS_HOLIDAY;
                            String thirdPartyResource = locationMap.get(OP_VAR.Account_Location__c).Third_Party_Resource__c;
                            
                            /*if(resourceSmallMap.containsKey(thirdPartyResource)){
                                resourceSmallMap.get(thirdPartyResource).add(rowStr);    
                            }else{
                                resourceSmallMap.put(thirdPartyResource, new List<String>{rowStr});     
                            }*/
                            
                            if(resourceRowsMap.containsKey(thirdPartyResource)){
                                resourceRowsMap.get(thirdPartyResource).add(rowStr);    
                            }else{
                                resourceRowsMap.put(thirdPartyResource, new List<String>{rowStr});     
                            }
                            
                            //routes per third party
                            if(routeNames3P.containsKey(thirdPartyResource)){
                                routeNames3P.get(thirdPartyResource).add(ROUTE_ID_STR);    
                            }else{
                                routeNames3P.put(thirdPartyResource, new Set<String>{ROUTE_ID_STR});     
                            }
                            
                            if(IS_HOLIDAY == 'TRUE') {
                                
                                //routeNames_holiday per third party
                                if(routeNames_holiday3P.containsKey(thirdPartyResource)){
                                    routeNames_holiday3P.get(thirdPartyResource).add(ROUTE_ID_STR);    
                                }else{
                                    routeNames_holiday3P.put(thirdPartyResource, new Set<String>{ROUTE_ID_STR});        
                                }                                
                                
                                //TOTAL_SMALL_HOLIDAY per third party
                                if(resSmallHolidayCountMap.containsKey(thirdPartyResource)){
                                    Integer smallHoliday =  resSmallHolidayCountMap.get(thirdPartyResource) + INDICATOR_VAR_SMALL;
                                    resSmallHolidayCountMap.put(thirdPartyResource, smallHoliday);
                                }else{
                                    resSmallHolidayCountMap.put(thirdPartyResource, INDICATOR_VAR_SMALL);    
                                }
                            }    
                        }                        
                    }
                }
                
                //GET CUPS
                String CUP_API = CONST_CupsTask_API + '_' + WEEK_NUM + '_' + scheduledDate.format('EEEE') + '__c';
                if(OP_VAR.get(CUP_API) != null){
                    String CUP_VAL = String.valueOf(OP_VAR.get(CUP_API));
                    if (!CUP_VAL.equals('0') && CUP_VAL != null) {
                        if (Integer.valueOf(CUP_VAL) > 0){
                            
                            //count for non-ThirdParty TOTAL_CUPS
                            if(!isThirdParty) TOTAL_CUPS = TOTAL_CUPS + Integer.valueOf(CUP_VAL);
                            
                            //count for ThirdParty TOTAL_CUPS
                            if(isThirdParty){
                                String thirdPartyResource = locationMap.get(OP_VAR.Account_Location__c).Third_Party_Resource__c;
                                if(resCupsCountMap.containsKey(thirdPartyResource)){
                                    Integer cups = resCupsCountMap.get(thirdPartyResource) + Integer.valueOf(CUP_VAL);
                                    resCupsCountMap.put(thirdPartyResource,cups);
                                }else{
                                    resCupsCountMap.put(thirdPartyResource, Integer.valueOf(CUP_VAL));    
                                }
                            }
                            
                            String OPSCHED_NAME = OP_VAR.Name != null ? OP_VAR.Name : '';
                            String OPSCHED_PHYSICALASSET = OP_VAR.PhysicalAsset__r.Name != null ? OP_VAR.PhysicalAsset__r.Name : '';
                            String OPSCHED_STARTDATE = String.valueOf(OP_VAR.Start_Date__c);
                            String FIELD_API = CUP_API != null ? CUP_API : '';
                            String FIELD_VALUE = CUP_VAL;
                           	String OPG_BUCKET = String.valueOf(pbe?.get(activityAPIMap.get(TS_Constants.ACTIVITY_CUPS))) != null ?  String.valueOf(pbe?.get(activityAPIMap.get(TS_Constants.ACTIVITY_CUPS))) : ''; //Karen Hung 8/3/2021 DOO-5268 Added Bucket
                            String ROUTE_ID = ROUTE_ID_STR;
                            String ROUTE_NAME = ROUTE_NAME_STR;
                            String EARLY_START_DATE = String.valueOf(earlyStartDate);
                            String ACCLOC_NAME = OP_VAR.PhysicalAsset__r.AccountLocation__r.Name != null ? OP_VAR.PhysicalAsset__r.AccountLocation__r.Name : '';
                            String ACCLOC_STREET = OP_VAR.PhysicalAsset__r.AccountLocation__r.Apttus_Config2__Street__c != null ? OP_VAR.PhysicalAsset__r.AccountLocation__r.Apttus_Config2__Street__c.replace(';', ' ') : '';
                            String ACCLOC_CITY =  OP_VAR.PhysicalAsset__r.AccountLocation__r.Apttus_Config2__City__c != null ? OP_VAR.PhysicalAsset__r.AccountLocation__r.Apttus_Config2__City__c.replace(';', ' ') : '';
                            String ACCLOC_PC = OP_VAR.PhysicalAsset__r.AccountLocation__r.Apttus_Config2__PostalCode__c != null ? OP_VAR.PhysicalAsset__r.AccountLocation__r.Apttus_Config2__PostalCode__c.replace(';', ' ') : '';
                            String PHA_PRODUCTNAME = OP_VAR.PhysicalAsset__r.Product__r.Name != null ? OP_VAR.PhysicalAsset__r.Product__r.Name.replace(';', ' ') : '';
                            String PHA_BUILDING =  OP_VAR.PhysicalAsset__r.Building__c != null ? OP_VAR.PhysicalAsset__r.Building__c.replace(';', ' ') : '';
                            String PHA_FLOOR = OP_VAR.PhysicalAsset__r.Floor__c != null ? OP_VAR.PhysicalAsset__r.Floor__c.replace(';', ' ') : '';
                            String PHA_AREA = OP_VAR.PhysicalAsset__r.Area__c != null ? OP_VAR.PhysicalAsset__r.Area__c.replace(';', ' ') : '';
                            String PHA_CUSTOMERREF = OP_VAR.PhysicalAsset__r.CustomerReferenceNumber__c != null ? OP_VAR.PhysicalAsset__r.CustomerReferenceNumber__c.replace(';', ' ') : '';
                            String ACTIVITY_TYPE = TS_Constants.ACTIVITY_REFILL;
                            
                            //CUPS CSV LINES FOR NON 3RD PARTY
                            if(!isThirdParty){                                
                                //Karen Hung 8/3/2021 DOO-5268 Added Bucket
                                String rowStr = OPSCHED_NAME + ';' + OPSCHED_PHYSICALASSET + ';' + OPSCHED_STARTDATE + ';' + FIELD_API + ';' + OPG_BUCKET + ';' + FIELD_VALUE + ';' + ROUTE_ID + ';' + IS_HOLIDAY + ';' + ROUTE_NAME;
                                CSVROWVALUES_CUP.add(rowStr);
                                routeNames.add(ROUTE_ID_STR);
                                
                                if(IS_HOLIDAY == 'TRUE') {
                                    TOTAL_CUPS_HOLIDAY = TOTAL_CUPS_HOLIDAY + Integer.valueOf(CUP_VAL);
                                    routeNames_holiday.add(ROUTE_ID_STR);
                                }                                
                            }
                            
                            //CUPS CSV LINES FOR 3RD PARTY
                            if(isThirdParty){
                                //Karen Hung 8/3/2021 DOO-5268 Added Bucket
                                String rowStr = EARLY_START_DATE + ';' + ACCLOC_NAME + ';' + ACCLOC_STREET + ';' + ACCLOC_CITY + ';' + ACCLOC_PC + ';' + OPSCHED_PHYSICALASSET + ';' + PHA_PRODUCTNAME + ';' + PHA_BUILDING + ';' + PHA_FLOOR + ';' + PHA_AREA + ';' + PHA_CUSTOMERREF + ';' + ACTIVITY_TYPE + ';' + OPG_BUCKET + ';' + FIELD_VALUE + ';' + IS_HOLIDAY;
                                String thirdPartyResource = locationMap.get(OP_VAR.Account_Location__c).Third_Party_Resource__c;
                                
                               /* if(resourceCupsMap.containsKey(thirdPartyResource)){
                                    resourceCupsMap.get(thirdPartyResource).add(rowStr);    
                                }else{
                                    resourceCupsMap.put(thirdPartyResource, new List<String>{rowStr});     
                                }*/
                                
                                if(resourceRowsMap.containsKey(thirdPartyResource)){
                                    resourceRowsMap.get(thirdPartyResource).add(rowStr);    
                                }else{
                                    resourceRowsMap.put(thirdPartyResource, new List<String>{rowStr});     
                                }
                                
                                //routes per third party
                                if(routeNames3P.containsKey(thirdPartyResource)){
                                    routeNames3P.get(thirdPartyResource).add(ROUTE_ID_STR);    
                                }else{
                                    routeNames3P.put(thirdPartyResource, new Set<String>{ROUTE_ID_STR});     
                                }  
                                
                                if(IS_HOLIDAY == 'TRUE') {
                                                                        
                                    //routeNames_holiday per third party
                                    if(routeNames_holiday3P.containsKey(thirdPartyResource)){
                                        routeNames_holiday3P.get(thirdPartyResource).add(ROUTE_ID_STR);    
                                    }else{
                                        routeNames_holiday3P.put(thirdPartyResource, new Set<String>{ROUTE_ID_STR});        
                                    }                                
                                    
                                    //TOTAL_CUPS_HOLIDAY per third party
                                    if(resCupsHolidayCountMap.containsKey(thirdPartyResource)){
                                        Integer cupsHoliday =  resCupsHolidayCountMap.get(thirdPartyResource) + Integer.valueOf(CUP_VAL);
                                        resCupsHolidayCountMap.put(thirdPartyResource, cupsHoliday);
                                    }else{
                                        resCupsHolidayCountMap.put(thirdPartyResource, Integer.valueOf(CUP_VAL));    
                                    }
                                }   
                            }                            
                        }
                    }
                }
            }
        }
        
        String csvColumnHeader;
        String docId;
        String myDomain = Url.getOrgDomainUrl().toExternalForm();
        String initialURL = myDomain + '/servlet/servlet.FileDownload?file=';
        
        List<Folder> folders = [SELECT Id, Name FROM Folder WHERE Name = 'Batch Pre-Load Reports'];
        List<Document> doctoInsert = new List<Document>();
        List<Custom_Log__c> logstoInsert = new List<Custom_Log__c>();
        
        if(!folders.isEmpty()){
            String documentName = 'PRELOAD_ROUTE_OPERATING_FOR_' + String.valueOf(scheduledDate.format('MMMdd')) + ' ' + String.valueOf(Datetime.now());
            csvColumnHeader = 'NAME; PHYSICAL ASSET; START DATE; FIELD API; OPG BUCKET; NUMBER OF TASK; ROUTE ID; IS HOLIDAY?; ROUTE\n';  //Karen Hung 8/3/2021 DOO-5268 Added Bucket
            String csvFile = csvColumnHeader + String.join(CSVROWVALUES_SMALL, '\n') + '\n' + String.join(CSVROWVALUES_LARGE, '\n') + '\n' + String.join(CSVROWVALUES_CUP, '\n') + '\n' + String.join(CSVROWVALUES_RINSE, '\n');
            
            Document doc = new Document(Name = documentName, Body = Blob.valueOf(csvFile), FolderId = folders[0].Id, Type = 'csv', ContentType = 'application/vnd.ms-excel');
            insert doc;
            
            docId = doc.Id;
        }
        
        if(!IS_CR_DAY) TOTAL_LARGE_CR = 0; TOTAL_LARGE_CR_HOLIDAY = 0;
        String RET_STR =  '\n' +
            'TOTAL_CUPS: ' + String.valueOf(TOTAL_CUPS) + '\n' +
            'TOTAL_SMALL: ' + String.valueOf(TOTAL_SMALL) + '\n' + 
            'TOTAL_LARGE: ' + String.valueOf(TOTAL_LARGE) + '\n' + '\n' +
            
            'TOTAL_CUPS_HOLIDAY: ' + String.valueOf(TOTAL_CUPS_HOLIDAY) + '\n' +
            'TOTAL_SMALL_HOLIDAY: ' + String.valueOf(TOTAL_SMALL_HOLIDAY) + '\n' + 
            'TOTAL_LARGE_HOLIDAY: ' + String.valueOf(TOTAL_LARGE_HOLIDAY) + '\n' + '\n' + 
            
            'TOTAL_CUPS_FINAL: ' + String.valueOf(TOTAL_CUPS - TOTAL_CUPS_HOLIDAY) + '\n' +
            'TOTAL_SMALL_FINAL: ' + String.valueOf(TOTAL_SMALL - TOTAL_SMALL_HOLIDAY) + '\n' + 
            'TOTAL_LARGE_FINAL: ' + String.valueOf(TOTAL_LARGE - TOTAL_LARGE_HOLIDAY) + '\n' + '\n' +
            
            'TOTAL_LARGE_WITHCR: ' + String.valueOf(TOTAL_LARGE_CR) + '\n' +
            'TOTAL_LARGE_WITHCR_HOLIDAY: ' + String.valueOf(TOTAL_LARGE_CR_HOLIDAY) + '\n' +
            'TOTAL_LARGE_FINAL: ' + String.valueOf(TOTAL_LARGE_CR - TOTAL_LARGE_CR_HOLIDAY) + '\n' + '\n' + 
            
            'NUMBER OF ROUTE TASK: ' + routeNames.size() + '\n' +
            'NUMBER OF ROUTE TASK (HOLIDAY): ' + routeNames_holiday.size() + '\n' +
            'NUMBER OF ROUTE TASK (FINAL): ' + (routeNames.size() - routeNames_holiday.size()) + '\n' + '\n' +
            
            'IS_NULL_BATCH_TYPE: ' + String.valueOf(isHoliday) + '\n' + 
            'PRELOAD_REPORT_LINK: ' + initialURL + docId;
              
            //Date nextDate = runDate.addDays(1);
            DateTime nextDateTime = DateTime.newInstanceGMT(nextDate.year(), nextDate.month(), nextDate.day(), 12, 0, 0);
            
            String PRELOAD_STRING = '';
            PRELOAD_STRING = RET_STR;
            
            //Custom log creation to check parameter
            Custom_Log__c log = new Custom_Log__c(
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
            
            logstoInsert.add(log);
        
        /********************************Custom logs and file creation for ThirdParty****************************************************************************/
        
        Map<String, Document> resourceDocMap = new Map<String, Document>();
        if(!folders.isEmpty() && !resourceRowsMap.isEmpty()){
            //Karen Hung 8/3/2021 DOO-5268 Added Bucket
            csvColumnHeader = 'Activity Date; Account Location Name; Account Location Street; Account Location City; Account Location PC; Physical Asset; PhA Product Name; PhA Building; PhA Floor; PhA Area; PhA Customer Reference; Activity Type; OPG Bucket; NUMBER OF TASK; IS HOLIDAY? \n';
            for(Resource__c resourceRec : [SELECT Id, Name FROM Resource__c WHERE Id IN :resourceRowsMap.keySet()]){
                //prep file for insertion
                String documentName = 'PRELOAD_ROUTE_OPERATING_FOR_' + resourceRec.Name + '_' + String.valueOf(scheduledDate.format('MMMdd')) + ' ' + String.valueOf(Datetime.now());
                String csvFile = csvColumnHeader + 
                                 (resourceRowsMap.containsKey(resourceRec.Id) ? String.join(resourceRowsMap.get(resourceRec.Id), '\n') : '');
                Document doc = new Document(Name = documentName, Body = Blob.valueOf(csvFile), FolderId = folders[0].Id, Type = 'csv', ContentType = 'application/vnd.ms-excel');
                doctoInsert.add(doc);
                resourceDocMap.put(resourceRec.Id, doc);
            }   
        }
        
        if(!doctoInsert.isEmpty()){
            insert doctoInsert;
        }
        
        if(!resourceRowsMap.isEmpty()){
            for(Resource__c resourceRec : [SELECT Id, Name FROM Resource__c WHERE Id IN :resourceRowsMap.keySet()]){
                Integer TOTAL_CUPS3P = resCupsCountMap.containsKey(resourceRec.Id) ? resCupsCountMap.get(resourceRec.Id) : 0;
                Integer TOTAL_SMALL3P = resSmallCountMap.containsKey(resourceRec.Id) ? resSmallCountMap.get(resourceRec.Id) : 0;
                Integer TOTAL_CUPS_HOLIDAY3P = resCupsHolidayCountMap.containsKey(resourceRec.Id) ? resCupsHolidayCountMap.get(resourceRec.Id) : 0;
                Integer TOTAL_SMALL_HOLIDAY3P = resSmallHolidayCountMap.containsKey(resourceRec.Id) ? resSmallHolidayCountMap.get(resourceRec.Id) : 0;
                Integer ROUTE_SIZE3P = routeNames3P.containsKey(resourceRec.Id) ? routeNames3P.get(resourceRec.Id).size() : 0;
                Integer ROUTE_HOLIDAYSIZE3P = routeNames_holiday3P.containsKey(resourceRec.Id) ? routeNames_holiday3P.get(resourceRec.Id).size() : 0 ;
                
                String PRELOAD_STRING_3P = '\n' +
                                            'TOTAL_CUPS: ' + String.valueOf(TOTAL_CUPS3P) + '\n' +
                                            'TOTAL_SMALL: ' + String.valueOf(TOTAL_SMALL3P) + '\n' + '\n' +
                                            
                                            'TOTAL_CUPS_HOLIDAY: ' + String.valueOf(TOTAL_CUPS_HOLIDAY3P) + '\n' +
                                            'TOTAL_SMALL_HOLIDAY: ' + String.valueOf(TOTAL_SMALL_HOLIDAY3P) + '\n' + '\n' + 
                                            
                                            'TOTAL_CUPS_FINAL: ' + String.valueOf(TOTAL_CUPS3P - TOTAL_CUPS_HOLIDAY3P) + '\n' +
                                            'TOTAL_SMALL_FINAL: ' + String.valueOf(TOTAL_SMALL3P - TOTAL_SMALL_HOLIDAY3P) + '\n' +  '\n' +
                                            
                                            'NUMBER OF ROUTE TASK: ' + ROUTE_SIZE3P + '\n' +
                                            'NUMBER OF ROUTE TASK (HOLIDAY): ' + ROUTE_HOLIDAYSIZE3P + '\n' +
                                            'NUMBER OF ROUTE TASK (FINAL): ' + (ROUTE_SIZE3P - ROUTE_HOLIDAYSIZE3P) + '\n' + '\n' +
                                            
                                            'IS_NULL_BATCH_TYPE: ' + String.valueOf(isHoliday) + '\n' + 
                                            'PRELOAD_REPORT_LINK: ' + initialURL + resourceDocMap.get(resourceRec.Id).Id;
                
                Custom_Log__c thirdPartylog = new Custom_Log__c(
                    Name = 'Route Task (Daily) for Third Party Resource: ' + resourceRec.Name + ' ' + String.valueOf(System.now()),
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
                    + '\n' + PRELOAD_STRING_3P
                );
                logstoInsert.add(thirdPartylog);
            }    
        }
        
        if(!logstoInsert.isEmpty()){
            insert logstoInsert;
        } 
    }
}