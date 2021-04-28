/**
 * @author        Karen Hung
 * @date          04.03.2020
 * @description   Apex batch class for generating Route Tasks for Nordics DOO-3001
 * @revision(s)  
 */
global without sharing class TS_MCOperating_Batch implements Database.Batchable <sObject> {

    //override variables
    public Boolean SOQL_OVERRIDE = false;
    public String NEW_SOQL_STRING;

    //This is to ensure that even if the default owner is Individual, the work order will be routed to the correct queue.
    public Map<String, String> countrySAPCodeMap = new Map<String, String>();
    public Map<String, String> queueNameIdMap = new Map<String, String>();

    //Information variables
    String CONST_WORKORDER_OP_RT = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get(TS_Constants.TS_WO_RECORDTYPE_OPERATINGROUTEWO).getRecordTypeId();
    String CONST_WORKORDER_OP_TYPE = Label.TS_Activity_Type_S20;
    String CONST_WOLI_OP_RT = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get(TS_Constants.TS_WOLI_RECORDTYPE_OPERATINGTASK).getRecordTypeId();
    String CONST_WOLI_OPEN_STATUS = TS_Constants.STATUS_OPEN;
    
    Map<String, String> set_task_types_map = TS_UtilityClass.letterActivityMap();
                                                                            
    Map<String, String> set_task_types_map_field = new Map<String, String>{     'Large' => 'MTTO_MCO_Large__c', 
                                                                                'Preventive Maintenance' => 'MTTO_MCO_PM__c', 
                                                                                'Waterfilter' => 'MTTO_MCO_Waterfilter__c', 
                                                                                'Descaling' => 'MTTO_MCO_Descaling__c', 
                                                                                'Bottle' => 'MTTO_MCO_Bottles__c', 
                                                                                'Ingredients' => 'MTTO_MCO_Ingredients__c'};
	
    //Karen Hung 1/3/2021 DOO-5269
    public static Map<Id,TS_Feature_Flag__mdt> featureFlags =  new Map<Id,TS_Feature_Flag__mdt>([SELECT Id, QualifiedApiName, Enable__c FROM TS_Feature_Flag__mdt WHERE QualifiedApiName != null and Enable__c = true]);
    public static Boolean operatingBucketEnabled = false;
    
    //Integration variables
    Integer runCount;
    Boolean isFirstRun = false;
    public Boolean RUN_INTEGRATION = true;

    //Exception variables
    public static Boolean hasException = false;
    public class TS_MCOperating_BatchException extends Exception {}

    Date runDate;
    Integer defaultstarttime;
    Integer defaultendtime;

    private List<String> exception_List = new List<String>();
    
    Map<String, CountrySetting__c> countrySettingMap = new Map<String, CountrySetting__c>();
   // Map<String, WorkOrder> slaAssetWOMap = new Map<String, WorkOrder>();
    
    /******************************************************************************
     *  Karen Hung
     *  05.03.2020 Batch Constructor
     ******************************************************************************/
    global TS_MCOperating_Batch(Date dateRun, Integer countRun) {
        CustomLogging.push('TS_MCOperating_Batch', 'TS_MCOperating_Batch');
        if (dateRun== null){
            runDate= date.today();
        }else{
            runDate = dateRun;
        }

        runCount = countRun;
        CustomLogging.pop();
    }

    /******************************************************************************
     * Karen Hung
     * 15.01.2020 Start
     ******************************************************************************/
    global Database.QueryLocator start(Database.BatchableContext BC) {
        CustomLogging.push(TS_Constants.CONST_START, 'TS_MCOperating_Batch');
        CustomLogging.pop();
        return Database.getQueryLocator(getQuery());
    }

    /******************************************************************************
     * Karen Hung           
     * 15.01.2020 Method to execute regular and holiday tasks creation
     ******************************************************************************/
    global void execute(Database.BatchableContext BC, List<Route__c> routes) {
        CustomLogging.push(TS_Constants.CONST_EXECUTE, 'TS_MCOperating_Batch');

        try{

            //MUTING variables
            WorkOrderLineItemTriggerHandler.IS_OPERATING_TASK = true;
            WorkOrderLineItemTriggerHandler.isRouteOperating = true;

            //CREATE A MAP OF COUNTRY CODES This is to ensure that even if the default owner is Individual, the work order will be routed to the correct queue.
            countrySAPCodeMap = TS_UtilityClass.countrySAPCodeUtility();

            //CREATE A MAP FOR SERVICE PLANNING QUEUE
            queueNameIdMap = TS_UtilityClass.queueNameIdMapUtility();

            //put mapping for country and cs
            String recordTypeId = Schema.SObjectType.CountrySetting__c.getRecordTypeInfosByName().get('Operating Task').getRecordTypeId(); //9.14.18 changed record type by karen hung
            List<CountrySetting__c> cList = [SELECT Country__c, DefaultStartTime__c, DefaultEndTime__c, Business_Hours__c FROM CountrySetting__c WHERE Active__c = true AND RecordTypeId =: recordTypeId];
            
            if(!cList.isEmpty()){
                for(CountrySetting__c cset : cList){
                    countrySettingMap.put(cset.Country__c, cset);   
                }
            }
            
            //Karen Hung 1/3/2021 Feature flag enablement
            if(!featureFlags.isEmpty()){
                for(TS_Feature_Flag__mdt flag : featureFlags.values()){
                    if(flag.Enable__c && !Test.isRunningTest()){                        
                        if(flag.QualifiedApiName == 'DOO_5269_Operating_Task_Bucket'){
                            operatingBucketEnabled = true; 
                        }    
                    }   
                }
            }

            //query operating schedules from the route
            DescribeSObjectResult opSchedule = OperatingSchedule__c.getSObjectType().getDescribe();
            List<String> fields = new List<String>(opSchedule.fields.getMap().keySet());
            String query = 'SELECT ' + String.join(fields, ',') + 
                        ', PhysicalAsset__r.Product__c,  PhysicalAsset__r.SalesOrganization__c, PhysicalAsset__r.AccountLocation__c' +
                        ', PhysicalAsset__r.Building__c,PhysicalAsset__r.AccountLocation__r.SAP_Customer_ID__c,PhysicalAsset__r.Floor__c' +
                        ', PhysicalAsset__r.SoldTo__c, PhysicalAsset__r.OP_PreferredOperator__c, PhysicalAsset__r.MothballAssetIndicator__c, PhysicalAsset__r.Machine_Care__c' +
                        ', PhysicalAsset__r.CounterReading__c, PhysicalAsset__r.Connected__c, PhysicalAsset__r.EndDate__c' + 
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
                        'AND PhysicalAsset__c IN (SELECT PhysicalAssetId__c FROM Route_Line_Item__c WHERE RouteId__c IN :routes)';
            
            List<OperatingSchedule__c> schedList = Database.query(query);

            //to get Pricebook of a Sales Organization
            Map<String, Pricebook2> pricebookMap = getPriceBookMap();
            //to get Product+SalesOrg => PricebokEntry
            Map<String, PricebookEntry> pBMap = TS_UtilityClass.createPriceBookEntryMap(schedList);

            //mapping to be used to populate main service contact
            Map<Id, Id> accountAccLocMap = new Map<Id, Id>();
            Map<String, Contact> accLocContactMap = new Map<String, Contact>();
            
            List<WorkOrder> wotoInsert = new List<WorkOrder>();
            List<WorkOrderLineItem> wolitoInsert = new List<WorkOrderLineItem>();
            Map<Id, OperatingSchedule__c> schedtoUpdateMap = new Map<Id, OperatingSchedule__c>();

            //Karen Hung 26.05.2020 DOO-4580
            Map<String, List<CountrySetting__c>> orgSettingsMap = orgCountrySettingsMap();

            Map<String, Route_Line_Item__c> assetRouteItemMap = new Map<String, Route_Line_Item__c>();
            Map<String, Integer> largeAPIDaysMap = new Map<String, Integer>{'LM_1_Monday__c' => 0,'LM_1_Tuesday__c' => 1,'LM_1_Wednesday__c' => 2,'LM_1_Thursday__c' => 3,'LM_1_Friday__c' => 4, 'LM_1_Saturday__c' => 5, 'LM_1_Sunday__c' => 6};

            if(!schedList.isEmpty()){

                //get schedule rules map : Operating Sched Id => List of rules
               // Map<String, List<Operating_Schedule_Rule__c>> schedRulesMap = schedRuleListMap(schedList);

                for(Route_Line_Item__c rli : [SELECT Id, PhysicalAssetId__c,PhysicalAssetId__r.Product__c, RouteId__c, RouteId__r.Name, RouteId__r.Unique_Route_Number__c, RouteId__r.Preferred_Operator__c, RouteId__r.Required_Operator__c , RouteId__r.Account_Location__r.Mini_Sales_Organization__c, RouteId__r.Account_Location__c, RouteId__r.Account_Location__r.Apttus_Config2__AccountId__c
                                            FROM Route_Line_Item__c where PhysicalAssetId__c IN (SELECT PhysicalAsset__c FROM OperatingSchedule__c WHERE ID IN :schedList)]){
                    assetRouteItemMap.put(rli.PhysicalAssetId__c, rli);
                    accountAccLocMap.put(rli.RouteId__r.Account_Location__r.Apttus_Config2__AccountId__c, rli.RouteId__r.Account_Location__c);
                }

                for(Contact con : [SELECT ID,AccountId FROM Contact WHERE Main_Service_Person__c = TRUE AND AccountId IN :accountAccLocMap.keySet()]){
                    accLocContactMap.put(accountAccLocMap.get(con.AccountId), con);
                }

                for(OperatingSchedule__c ops : schedList){

                    Integer countrySetting = Integer.valueOf(Label.TS_CountrySetting);
                                    
                    String monthToday = String.valueOf(runDate.addDays(countrySetting).month());
                    //String nextMonth = String.valueOf(runDate.addDays(countrySetting).addMonths(1).month());

                    //TODAY + a country dependent value
                    Date todayPlusValue =  runDate.addDays(countrySetting);
                     //todayPlusValue is => first day of next month
                    Boolean isFirstofNextMonth = runDate.addMonths(1).toStartOfMonth() <= todayPlusValue && todayPlusValue.addDays(-7) < runDate.addMonths(1).toStartOfMonth();

                    if(isFirstofNextMonth){
                        //has large? checker
                        Boolean hasLarge = ops.FrequencyofL__c != null && ops.FrequencyofL__c != TS_Constants.NA ? true : false;

                        List<String> descalingMonths = ops.Descaling_Months__c != null ? ops.Descaling_Months__c.split(';') : null;
                        List<String> pmMonths = ops.PM_Months__c != null ? ops.PM_Months__c.split(';') : null;
                        List<String> waterFilterMonths = ops.Waterfilter_Months__c != null ? ops.Waterfilter_Months__c.split(';') : null;
                        List<String> bottleMonths = ops.Bottle_Months__c != null ? ops.Bottle_Months__c.split(';') : null;
                        List<String> largeMonths = ops.L_Months__c != null ? ops.L_Months__c.split(';') : null;
                        List<String> ingredientsMonths = ops.Ingredients_Months__c != null ? ops.Ingredients_Months__c.split(';') : null;
                                        
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

                        //check if there's already PM created before and PM to be created in advanced from Schedule Rules
                        Boolean withPMAlready = false;
                        Boolean withWFAlready = false;
                        Boolean withLargeAlready = false;
                        Set<String> advancedPMmonths = new Set<String>();
                        /*if(schedRulesMap != null  && schedRulesMap.containsKey(ops.Id)){      
                            for(Operating_Schedule_Rule__c rule : schedRulesMap.get(ops.Id)){
                                //if(rule.From__c >= monthToday && rule.To__c < monthToday && rule.Machine_Clean_Operating_Types__c == 'Preventive Maintenance'){
                                  //  withPMAlready = true;
                                //}
                                if(rule.From__c == monthToday && rule.Machine_Clean_Operating_Types__c == TS_Constants.ACTIVITY_PM){ //'Preventive Maintenance'
                                    withPMAlready = true;
                                }
                                if(rule.To__c == monthToday && rule.Machine_Clean_Operating_Types__c == TS_Constants.ACTIVITY_PM){//'Preventive Maintenance'
                                    advancedPMmonths.add(rule.From__c);    
                                }
                            }     
                        }*/

                        //Karen Hung DOO-4580 check if there's already PM created before and PM to be created in advanced using PM rules country setting for monthly schedule
                        if(orgSettingsMap != null && orgSettingsMap.containsKey(ops.Sales_Organization__c) && (!hasLarge || ops.FrequencyofL__c == TS_CONSTANTS.FREQUENCY_MONTHLY)){
                            for(CountrySetting__c pmRule : orgSettingsMap.get(ops.Sales_Organization__c)){
                                if(pmRule.From__c == monthToday && pmMonths != null && pmMonths.contains(pmRule.From__c)){
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

                        String activityCombination = '';

                        //check if there's PM for the month
                        if(pmMonths != null && pmMonths.contains(monthToday) && !withPMAlready){
                            activityCombination += 'P';
                        }

                        //check if there's Waterfilter for the month //Karen Hung DOO-4580 added  !withWFAlready
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

                        // has large && (daily or weekly)
                        if(hasLarge && (ops.FrequencyofL__c == TS_CONSTANTS.FREQUENCY_DAILY || ops.FrequencyofL__c == TS_Constants.FREQUENCY_WEEKLY)){
                            
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
                                        //Karen Hung 17.6.2020 DOO-2695 added contract enddate filter
                                        if(ops.PhysicalAsset__r.EndDate__c >= startDate && activityCombination != '' && (ops.Schedule_Tasks_for_Holiday__c ||
                                           BusinessHours.isWithin(countrySettingMap.get(ops.Sales_Organization__c).Business_Hours__c, DateTime.newInstance(startDate.year(), startDate.month(), startDate.day(), endhour-1, 59, 59)))){
                                            wotoInsert.add(createWorkOrders(ops, assetRouteItemMap.get(ops.PhysicalAsset__c), startDate, startDate, pricebookMap, countrySettingMap,accLocContactMap));
                                            wolitoInsert.add(createOperatingTasks(activityCombination, CONST_WORKORDER_OP_TYPE, ops, startDate, startDate, pBMap, countrySettingMap,assetRouteItemMap.get(ops.PhysicalAsset__c)));     
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

                                                    //Karen Hung 17.6.2020 DOO-2695 added contract enddate filter
                                                    if(ops.PhysicalAsset__r.EndDate__c >= startDate && activityCombination != '' && (ops.Schedule_Tasks_for_Holiday__c ||
                                                       BusinessHours.isWithin(countrySettingMap.get(ops.Sales_Organization__c).Business_Hours__c, DateTime.newInstance(startDate.year(), startDate.month(), startDate.day(), endhour-1, 59, 59)))){
                                                        wotoInsert.add(createWorkOrders(ops, assetRouteItemMap.get(ops.PhysicalAsset__c), startDate, startDate, pricebookMap, countrySettingMap,accLocContactMap));
                                                        wolitoInsert.add(createOperatingTasks(activityCombination, CONST_WORKORDER_OP_TYPE, ops, startDate, startDate, pBMap, countrySettingMap,assetRouteItemMap.get(ops.PhysicalAsset__c)));
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
                                            
                                            //Karen Hung 17.6.2020 DOO-2695 added contract enddate filter
                                            if(ops.PhysicalAsset__r.EndDate__c >= earlyStartWeekly && activityCombination != ''){
                                                wotoInsert.add(createWorkOrders(ops, assetRouteItemMap.get(ops.PhysicalAsset__c), earlyStartWeekly, slaWeekly, pricebookMap, countrySettingMap,accLocContactMap));
                                                wolitoInsert.add(createOperatingTasks(activityCombination, CONST_WORKORDER_OP_TYPE, ops, earlyStartWeekly, slaWeekly, pBMap, countrySettingMap,assetRouteItemMap.get(ops.PhysicalAsset__c)));
                                            }
                                            largeOccurrence++;
                                        }
                                        
                                        ops.Last_Early_Start_Date__c = earlyStartWeekly;
                                        calculatedEarlyStart = ops.Last_Early_Start_Date__c.addDays(interval * 7); //Karen Hung DOO-4580 4.6.2020 calculate next early start
                                        schedtoUpdateMap.put(ops.Id, ops);
                                    }
                                }

                                earlyStartWeekly = earlyStartWeekly.addDays(7);
                                slaWeekly = earlyStartWeekly.addDays(4); 
                            }

                            //for skip month scenario //Karen Hung 17.6.2020 DOO-2695 added contract enddate filter
                            if(ops.PhysicalAsset__r.EndDate__c >= earlyStartDate && ops.FrequencyofL__c == TS_Constants.FREQUENCY_WEEKLY && !schedtoUpdateMap.containsKey(ops.Id) && activityCombination != ''){
                                activityCombination = activityCombination == 'L' ? TS_CONSTANTS.ACTIVITY_LARGE : activityCombination == 'P' ? TS_CONSTANTS.ACTIVITY_PM : activityCombination == 'W' ? TS_CONSTANTS.ACTIVITY_WATERFILTER : activityCombination == 'D' ? TS_CONSTANTS.ACTIVITY_DESCALING :  activityCombination == 'B' ? TS_CONSTANTS.ACTIVITY_BOTTLE : activityCombination == 'I' ? TS_CONSTANTS.ACTIVITY_INGREDIENTS : activityCombination;
                                wotoInsert.add(createWorkOrders(ops, assetRouteItemMap.get(ops.PhysicalAsset__c), earlyStartDate, slaDateMonthly, pricebookMap, countrySettingMap,accLocContactMap));
                                wolitoInsert.add(createOperatingTasks(activityCombination, CONST_WORKORDER_OP_TYPE, ops, earlyStartDate, slaDateMonthly, pBMap, countrySettingMap,assetRouteItemMap.get(ops.PhysicalAsset__c)));   
                            }

                        //SCENARIO 3: WITHOUT LARGE OR HAS MONTHLY FREQUENCY  
                        }else{ 

                            //check if there's Large for the month                
                            String comboMonthly = largeMonths != null && largeMonths.contains(monthToday) && !withLargeAlready ? 'L' + activityCombination : activityCombination; //Karen Hung DOO-4580 added  !withPMAlready   
                            comboMonthly = comboMonthly == 'L' ? TS_CONSTANTS.ACTIVITY_LARGE : comboMonthly == 'P' ? TS_CONSTANTS.ACTIVITY_PM : comboMonthly == 'W' ? TS_CONSTANTS.ACTIVITY_WATERFILTER : comboMonthly == 'D' ? TS_CONSTANTS.ACTIVITY_DESCALING :  comboMonthly == 'B' ? TS_CONSTANTS.ACTIVITY_BOTTLE : comboMonthly == 'I' ? TS_CONSTANTS.ACTIVITY_INGREDIENTS : comboMonthly;
                            
                            //create workOrder for monthly jobs with woli for combined monthly type
                            if(ops.PhysicalAsset__r.EndDate__c >= earlyStartDate && comboMonthly != ''){ //Karen Hung 17.6.2020 DOO-2695 added contract enddate filter
                                wotoInsert.add(createWorkOrders(ops, assetRouteItemMap.get(ops.PhysicalAsset__c), earlyStartDate, slaDateMonthly, pricebookMap, countrySettingMap,accLocContactMap));
                                wolitoInsert.add(createOperatingTasks(comboMonthly, CONST_WORKORDER_OP_TYPE, ops, earlyStartDate, slaDateMonthly, pBMap, countrySettingMap,assetRouteItemMap.get(ops.PhysicalAsset__c)));
                            }

                        }

                        //check PM jobs to be created in advance
                        if(!advancedPMmonths.isEmpty() && (ops.FrequencyofL__c == TS_Constants.FREQUENCY_MONTHLY || !hasLarge)){ //Karen Hung 4.6.2020 DOO-4580 added criteria
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

                                //Karen Hung 17.6.2020 DOO-2695 added contract enddate filter
                                if(ops.PhysicalAsset__r.EndDate__c >= earlyStartDate){
                                    //create PM tasks in advance
                                    wotoInsert.add(createWorkOrders(ops, assetRouteItemMap.get(ops.PhysicalAsset__c), earlyStartDate, pmSLA, pricebookMap, countrySettingMap,accLocContactMap));
                                    //wolitoInsert.add(createOperatingTasks(TS_CONSTANTS.ACTIVITY_PM, CONST_WORKORDER_OP_TYPE, ops, earlyStartDate, pmSLA, pBMap, countrySettingMap,assetRouteItemMap.get(ops.PhysicalAsset__c)));
                                    //Karen Hung 3.6.2020 DOO-4580 String Combination for advanced task changed first parameter value
                                    wolitoInsert.add(createOperatingTasks(advancedTasks == 'P'? TS_CONSTANTS.ACTIVITY_PM : advancedTasks, CONST_WORKORDER_OP_TYPE, ops, earlyStartDate, pmSLA, pBMap, countrySettingMap,assetRouteItemMap.get(ops.PhysicalAsset__c)));
                                }                                
                            }
                        }                          
                    }                   
                }

                //Route + earlystart + enddate => workorder
                Map<String, WorkOrder> finalWOtoInsert = new Map<String, WorkOrder>();
                
                ///---------------Records Insertion and Update----------------///////////////

                //Insert WorkOrders
                if(!wotoInsert.isEmpty() && Schema.sObjectType.WorkOrder.isCreateable()){

                    for(WorkOrder  wo: wotoInsert){
                        if(!finalWOtoInsert.containsKey(wo.Route_Id__c + String.valueOf(wo.Early_Start_Date__c.date()) + String.valueOf(wo.SLA_Date__c.date()))){
                            finalWOtoInsert.put(wo.Route_Id__c + String.valueOf(wo.Early_Start_Date__c.date()) + String.valueOf(wo.SLA_Date__c.date()) , wo);
                        }
                        
                         if(operatingBucketEnabled) wo.OPG_Source__c = 'MCO Batch';
                    }

                    Database.SaveResult[] woResult = Database.insert(finalWOtoInsert.values(), false);
                    //Custom Logging 
                    INSERT_LOGGING(woResult, 'WorkOrder Insert'); 
                }

                //Populate workorder detail and Insert WOLI's
                if(!wolitoInsert.isEmpty() && Schema.sObjectType.WorkOrderLineItem.isCreateable()){
                    
                    //Karen Hung DOO-5269 variables to process operating bucket logic                                                                                        
                    Map<String, String> activitiesMTTOBucketMap = TS_UtilityClass.mcoActivityBucketAPIMap();
                                                                                                
                    //populate workorderId before insert
                    for(WorkOrderLineItem woli : wolitoInsert){

                        if(assetRouteItemMap.containsKey(woli.PhysicalAsset__c) && 
                            finalWOtoInsert.containsKey(assetRouteItemMap.get(woli.PhysicalAsset__c).RouteId__c + String.valueOf(woli.EarlyStart__c.date()) + String.valueOf(woli.SLADate__c.date()))){
                            
                            WorkOrder wo = finalWOtoInsert.get(assetRouteItemMap.get(woli.PhysicalAsset__c).RouteId__c + String.valueOf(woli.EarlyStart__c.date()) + String.valueOf(woli.SLADate__c.date()));
                            woli.WorkOrderId = wo.Id;
                             
                            //Karen Hung DOO-5269 process and populate operating bucket
                            if(operatingBucketEnabled){                                
                                PriceBookEntry pbe = pBMap.get(assetRouteItemMap.get(woli.PhysicalAsset__c)?.PhysicalAssetId__r.Product__c + wo.SalesOrganization__c);
                                
                                //for normal tasks
                                if(activitiesMTTOBucketMap.containsKey(woli.WorkOrderLineItemType__c)){
                                	woli.Operating_Bucket__c = String.valueOf(pbe?.get(activitiesMTTOBucketMap.get(woli.WorkOrderLineItemType__c)));    
                                //for combination tasks
                                }else{
                                    /*List<String> woliMTTOs = new List<String>();
                                    //get the mtto bucket values and sort
                                    for(Integer i=0; i<woli.WorkOrderLineItemType__c.length(); i++){
                                        String activityType = set_task_types_map.get(woli.WorkOrderLineItemType__c?.substring(i, i+1));
                                    	woliMTTOs.add(String.valueOf(pbe?.get(activitiesMTTOBucketMap.get(activityType)))); 
                                    }
                                    woliMTTOs.sort();
                                    //get the last index(biggest) of mtto bucket values
                                    woli.Operating_Bucket__c = woliMTTOs.size() > 0 ? woliMTTOs[woliMTTOs.size()-1] : null;*/
                                    woli.Operating_Bucket__c = TS_UtilityClass.operatingBucket(woli.WorkOrderLineItemType__c, pbe);
                                }
                            	woli.OPG_Source__c = 'MCO Batch';
                            }
                        }

                    }
                    Database.SaveResult[] woliResult = Database.insert(wolitoInsert, false);                    
                    //Custom Logging 
                    INSERT_LOGGING(woliResult, 'WorkOrderLineItem Insert'); 
                }

                //CALCULATE ACTUAL DURATION

                /********************************************************************* */
                //PERFORM ACTUAL DURATION CALCULATION HERE
                //Xen Reyes May 11, 2020 - DOO-4456
                /********************************************************************* */
                
                //LIST OF WO-WOLI PAIRING
                Map<Id, List<WorkOrderLineItem>> map_wo_woli = new Map<Id, List<WorkOrderLineItem>>();
                for(WorkOrderLineItem wo_var : wolitoInsert){
                    if(map_wo_woli.containsKey(wo_var.WorkOrderId)){
                        map_wo_woli.get(wo_var.WorkOrderId).add(wo_var);
                    } else {
                        map_wo_woli.put(wo_var.WorkOrderId, new List<WorkOrderLineItem>{wo_var});
                    }
                }

                //GET ALL WORK ORDER RECORDS
                List<WorkOrder> list_final_wo = finalWOtoInsert.values();
                Map<Id, WorkOrder> map_wo_final = new Map<Id, WorkOrder>(list_final_wo);

                //GET ALL SALES ORGANIZATION
                Set<String> salesOrg_set = new Set<String>();
                for(WorkOrder wo_var : list_final_wo){
                    salesOrg_set.add(wo_var.SalesOrganization__c);
                }

                //GET ALL PRICEBOOKENTRY DETAILS
                Set<Id> pbEntry_set = new Set<Id>();
                Map<Id, PricebookEntry> map_id_pbEntry = new Map<Id, PricebookEntry>();
                Map<Id, Integer> map_countTasks = new Map<Id, Integer>();
                for(Id str : map_wo_woli.keySet()){
                    for(WorkOrderLineItem woli_var : map_wo_woli.get(str)){
                        pbEntry_set.add(woli_var.PricebookEntryId);
                    }
                    map_countTasks.put(str, map_wo_woli.get(str).size());
                }

                if(!pbEntry_set.isEmpty()){
                    map_id_pbEntry = new Map<Id, PricebookEntry>([SELECT Id, Product2Id, Pricebook2Id, Sales_Organization__c, MeanTimeToOperateC__c, MeanTimeToOperateLM__c, MeanTimeToOperateSM__c, MTTO_MCO_Bottles__c, MTTO_MCO_Descaling__c, MTTO_MCO_Ingredients__c, MTTO_MCO_Large__c, MTTO_MCO_PM__c, MTTO_MCO_Waterfilter__c FROM PricebookEntry WHERE Id IN: pbEntry_set AND Sales_Organization__c IN: salesOrg_set]);
                }

                System.debug('map_id_pbEntry: ' + map_id_pbEntry);

                //GET ALL CALL TYPE PER COUNTRY SETTING
                Map<String, Map<String, Decimal>> map_woType_country_mttoCallType = new Map<String, Map<String, Decimal>>();
                for(CountrySetting__c cs_var : [SELECT Id, WorkOrderType__c, Country__c, Mean_Time_To_Operate__c FROM CountrySetting__c WHERE RecordType.Name = 'Mean Time To Operate per Call Type' AND Active__c = true]){
                    if(map_woType_country_mttoCallType.containsKey(cs_var.WorkOrderType__c)){
                        if(!map_woType_country_mttoCallType.get(cs_var.WorkOrderType__c).containsKey(cs_var.Country__c)){
                            map_woType_country_mttoCallType.get(cs_var.WorkOrderType__c).put(cs_var.Country__c, cs_var.Mean_Time_To_Operate__c);
                        }
                    } else {
                        map_woType_country_mttoCallType.put(cs_var.WorkOrderType__c, new Map<String, Decimal>{cs_var.Country__c => cs_var.Mean_Time_To_Operate__c});
                    }
                }

                System.debug('map_woType_country_mttoCallType: ' + map_woType_country_mttoCallType);

                //GET ROUTE AND ACCOUNT LOCATION DETAILS
                Map<Id, Route__c> map_routeMap = new Map<Id, Route__c>();
                if(!list_final_wo.isEmpty()){

                    //GET ALL ROUTE IDS
                    Set<Id> set_routeId = new Set<Id>();
                    for(WorkOrder wo_var : list_final_wo){
                        set_routeId.add(wo_var.Route_Id__c);
                    }

                    //QUERY ACCOUNT LOCATION INFORMATION PER ROUTE
                    if(!set_routeId.isEmpty()){
                        map_routeMap = new Map<Id, Route__c>([SELECT Id, Name, Unique_Route_Number__c, Account_Location__c, Account_Location__r.Apttus_Config2__AccountId__c, Account_Location__r.Mini_Sales_Organization__c, Account_Location__r.AverageRoutePrep__c, Account_Location__r.MTTTWithinSite__c, Account_Location__r.MTTOLocationSpecific__c FROM Route__c WHERE Id IN :set_routeId]);
                    }
                }

                System.debug('map_routeMap: ' + map_routeMap);

                //CALCULATE PER ROUTE AND PUT IN WORKORDER
                List<WorkOrder> list_wo_update = new List<WorkOrder>();
                Set<String> baseTypesSet = new Set<String>{'Large', 'Preventive Maintenance', 'Waterfilter', 'Descaling', 'Bottle', 'Ingredients'};

                for(Id wo_var : map_wo_woli.keySet()){
                    
                    WorkOrder wo_update = new WorkOrder();
                    wo_update.Id = wo_var;

                    Decimal totalMTTO = 0;
                    Integer num_task = map_countTasks.get(wo_var);
                    String routeId = map_wo_final.containsKey(wo_var) ? map_wo_final.get(wo_var).Route_Id__c : null;
                    String salesOrg = map_wo_final.containsKey(wo_var) ? map_wo_final.get(wo_var).SalesOrganization__c : null;
                    
                    Decimal aveRoutePrep = 0;
                    if(map_routeMap.containsKey(routeId)){
                        if(map_routeMap.get(routeId).Account_Location__r.AverageRoutePrep__c != null){
                            aveRoutePrep = map_routeMap.get(routeId).Account_Location__r.AverageRoutePrep__c;
                        }
                    }

                    Decimal mtttWithinSite = 0;
                    if(map_routeMap.containsKey(routeId)){
                        if(map_routeMap.get(routeId).Account_Location__r.MTTTWithinSite__c != null){
                            mtttWithinSite = map_routeMap.get(routeId).Account_Location__r.MTTTWithinSite__c;
                        }
                    }

                    Decimal mtttoLocationSpecific = 0;
                    if(map_routeMap.containsKey(routeId)){
                        if(map_routeMap.get(routeId).Account_Location__r.MTTOLocationSpecific__c != null){
                            mtttoLocationSpecific = map_routeMap.get(routeId).Account_Location__r.MTTOLocationSpecific__c != null ? map_routeMap.get(routeId).Account_Location__r.MTTOLocationSpecific__c : 0;
                        }
                    }
                    
                    Decimal calc_perTask = 0;
                    for(WorkOrderLineItem woli_var :  map_wo_woli.get(wo_var)){
                        
                        Decimal perCallType = map_woType_country_mttoCallType.get('S20').get(salesOrg) != null ? map_woType_country_mttoCallType.get('S20').get(salesOrg) : 0 ;
                        System.debug('woli_var.WorkOrderLineItemType__c: ' + woli_var.WorkOrderLineItemType__c);

                        //GET VALUE DEPENDS ON THE ACTIVITY TYPE
                        if(baseTypesSet.contains(woli_var.WorkOrderLineItemType__c)){
                            
                            Decimal perPriceBook = 0;
                            String api_var = set_task_types_map_field.get(woli_var.WorkOrderLineItemType__c);

                            if(map_id_pbEntry.get(woli_var.PricebookEntryId).get(api_var) != null){
                                PricebookEntry pbe = map_id_pbEntry.get(woli_var.PricebookEntryId);
                                perPriceBook = Decimal.valueOf(String.valueOf(pbe.get(api_var))) != null ? Decimal.valueOf(String.valueOf(pbe.get(api_var))) : 0;
                            }

                            calc_perTask = calc_perTask + (perCallType + perPriceBook + mtttoLocationSpecific);
                            
                        } else if(woli_var.WorkOrderLineItemType__c != null) {

                            String taskType = woli_var.WorkOrderLineItemType__c;
                            for(String str_type : taskType.split('')){

                                Decimal perPriceBook = 0;
                                String api_var = set_task_types_map_field.get(set_task_types_map.get(str_type));

                                if(map_id_pbEntry.get(woli_var.PricebookEntryId).get(api_var) != null){
                                    PricebookEntry pbe = map_id_pbEntry.get(woli_var.PricebookEntryId);
                                    perPriceBook = Decimal.valueOf(String.valueOf(pbe.get(api_var))) != null ? Decimal.valueOf(String.valueOf(pbe.get(api_var))) : 0;
                                }

                                calc_perTask = calc_perTask + (perCallType + perPriceBook + mtttoLocationSpecific);
                            }
                        }

                    }

                    totalMTTO = calc_perTask + aveRoutePrep + ((num_task - 1) * mtttWithinSite);
                   // wo_update.Actual_Duration__c = totalMTTO / 60; Karen Hung DOO-4886 Changed actual duration field to planned duration
                     wo_update.Planned_Duration__c = totalMTTO / 60;
                    list_wo_update.add(wo_update);
                }

                //UPDATE WORKORDER
                if(!list_wo_update.isEmpty()){
                    Database.SaveResult[] saveResults_MTTO = Database.update(list_wo_update, false);
                    INSERT_LOGGING(saveResults_MTTO, 'WorkOrder Update');
                }                

                //update Operating Schedule
                if(!schedtoUpdateMap.values().isEmpty() && Schema.sObjectType.OperatingSchedule__c.isUpdateable()){
                    Database.SaveResult[] schedResult = Database.update(schedtoUpdateMap.values(), false);
                    //Custom Logging 
                    INSERT_LOGGING(schedResult, 'Operating Schedule Update'); 
                }
            }
           
            if(Test.isRunningTest() && hasException){
                throw new TS_MCOperating_BatchException('Force to throw an exception');
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
     * 15.01.2020    This method to perform actions when the batch is finished , call integration batch
     ******************************************************************************/
    global void finish(Database.BatchableContext BC) {
        CustomLogging.push('finish', 'TS_MCOperating_Batch');

       //Check queue capacity
       List<AsyncApexJob> routeIntegrationBatch = [SELECT Id, ApexClassID 
                                            FROM AsyncApexJob 
                                            WHERE Status IN ('Processing', 'Preparing') 
                                            AND ApexClassId IN (SELECT Id FROM ApexClass WHERE Name = 'TS_RouteTaskIntegration_Batch') ];
        
        //COUNT THE PROCESSING JOBS AND THOSE IN QUEUE
        Integer batchCount_ProcessingPreparing = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Processing\', \'Preparing\')');
        Integer batchCount_HoldingQueued = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Queued\', \'Holding\')');
        TS_RouteTaskIntegration_Batch intbatch = new TS_RouteTaskIntegration_Batch(runDate, isFirstRun, runCount);
        intBatch.nordicsBatch = true;
        if (batchCount_ProcessingPreparing < 5 && batchCount_HoldingQueued < 100 && (routeIntegrationBatch == null || routeIntegrationBatch.size() == 0) && !Test.isRunningTest()) {
            if(RUN_INTEGRATION) Database.executeBatch(intbatch, Integer.valueOf(System.Label.TS_RouteTaskIntBatchSize));
        } /*else {

        }*/
          

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

    /*String query method*/
    String getQuery(){
        CustomLogging.push('getQuery', 'TS_MCOperating_Batch');

        DescribeSObjectResult routeDescribe = Route__c.getSObjectType().getDescribe();
        List<String> fields = new List<String> (routeDescribe.fields.getMap().keySet());
        String DEFAULT_SOQL = 'SELECT ' + String.join(fields, ',') + ' FROM Route__c WHERE Account_Location__r.Mini_Sales_Organization__c IN( \'SAP_6864\', \'SAP_0975\')';

        CustomLogging.pop();

        if(SOQL_OVERRIDE){
            return NEW_SOQL_STRING;
        } else {
            return DEFAULT_SOQL;
        }
    }
    
    /*WorkOrder creation method*/
    WorkOrder createWorkOrders(OperatingSchedule__c sched, Route_Line_Item__c routeItemObj, Date startDate, Date taskDate, Map<String, Pricebook2> countryPricebookMap, Map<String, CountrySetting__c> cSettingMap, Map<String, Contact> accLocContactMap){
        CustomLogging.push('createWorkOrders', 'TS_MCOperating_Batch');
        //List<WorkOrder> woList = new List<WorkOrder>();

        Integer starthour = cSettingMap.get(routeItemObj.RouteId__r.Account_Location__r.Mini_Sales_Organization__c).DefaultStartTime__c == null ? 8 : Integer.valueOf(cSettingMap.get(routeItemObj.RouteId__r.Account_Location__r.Mini_Sales_Organization__c).DefaultStartTime__c); //default starthour is 8 if null mapping
        Integer endhour =  cSettingMap.get(routeItemObj.RouteId__r.Account_Location__r.Mini_Sales_Organization__c).DefaultEndTime__c == null ? 17 : Integer.valueOf(cSettingMap.get(routeItemObj.RouteId__r.Account_Location__r.Mini_Sales_Organization__c).DefaultEndTime__c);

        WorkOrder workOrder = new WorkOrder();
        workOrder.Route_Number__c = routeItemObj.RouteId__r.Unique_Route_Number__c;
        workOrder.Route_Name__c = routeItemObj.RouteId__r.Name;
        workOrder.Preferred_Operator__c = routeItemObj.RouteId__r.Preferred_Operator__c;
        workOrder.Required_Operator__c = routeItemObj.RouteId__r.Required_Operator__c;
        workOrder.Pricebook2Id = countryPricebookMap.get(routeItemObj.RouteId__r.Account_Location__r.Mini_Sales_Organization__c) != null ? countryPricebookMap.get(routeItemObj.RouteId__r.Account_Location__r.Mini_Sales_Organization__c).Id : null;
        workOrder.RecordTypeId = CONST_WORKORDER_OP_RT;
        workOrder.WorkOrderType__c = CONST_WORKORDER_OP_TYPE; 

        if(accLocContactMap.containsKey(routeItemObj.RouteId__r.Account_Location__c)){
            workOrder.Main_Service_Contact__c = accLocContactMap.get(routeItemObj.RouteId__r.Account_Location__c).Id;
        }

        workOrder.SalesOrganization__c = routeItemObj.RouteId__r.Account_Location__r.Mini_Sales_Organization__c;
        workOrder.AccountId = routeItemObj.RouteId__r.Account_Location__r.Apttus_Config2__AccountId__c;
        workOrder.Route_Id__c = routeItemObj.RouteId__c;
        workOrder.Early_Start_Date__c = DateTime.newInstance(startDate.year(), startDate.month(), startDate.day(), starthour, 0, 0);
        workOrder.SLA_Date__c = DateTime.newInstance(taskDate.year(), taskDate.month(), taskDate.day(), endhour, 0, 0);
        workOrder.Account_Location__c = routeItemObj.RouteId__r.Account_Location__c;

        //This is to ensure that even if the default owner is Individual, the work order will be routed to the correct queue.
        workOrder.OwnerId = UserInfo.getUserId();
        
        if(countrySAPCodeMap.containsKey(workOrder.SalesOrganization__c)){
            if(queueNameIdMap.containsKey(countrySAPCodeMap.get(workOrder.SalesOrganization__c))){
                workOrder.OwnerId = queueNameIdMap.get(countrySAPCodeMap.get(workOrder.SalesOrganization__c));
            } 
        }
        
        //put mapping sla+opsched => workOrder
        //slaAssetWOMap.put(String.valueOf(startDate) + String.valueOf(taskDate) + routeItemObj.PhysicalAssetId__c, workOrder);
        //woList.add(workOrder);

        CustomLogging.pop();
        return workOrder;
    }

    /*WorkOrderLineItem creation method*/
    WorkOrderLineItem createOperatingTasks(String activityType, String workOrdertype, OperatingSchedule__c operatingSchedule, Date startDate, DateTime scheduledDate, Map <String, PricebookEntry> pbeMap, Map<String, CountrySetting__c> cSettingMap,Route_Line_Item__c routeItemObj) {
        CustomLogging.push('createOperatingTasks', 'TS_MCOperating_Batch');

        Integer defaultstarttime = cSettingMap.get(routeItemObj.RouteId__r.Account_Location__r.Mini_Sales_Organization__c).DefaultStartTime__c == null ? 8 : Integer.valueOf(cSettingMap.get(routeItemObj.RouteId__r.Account_Location__r.Mini_Sales_Organization__c).DefaultStartTime__c); //default starthour is 8 if null mapping
        Integer defaultendTime =  cSettingMap.get(routeItemObj.RouteId__r.Account_Location__r.Mini_Sales_Organization__c).DefaultEndTime__c == null ? 17 : Integer.valueOf(cSettingMap.get(routeItemObj.RouteId__r.Account_Location__r.Mini_Sales_Organization__c).DefaultEndTime__c);

        WorkOrderLineItem task = new WorkOrderLineItem();
        task.WorkOrderType__c = workOrdertype;
        task.AccountLocation__c = operatingSchedule.PhysicalAsset__r.AccountLocation__c;
        task.WorkOrderLineItemType__c = activityType;

        task.EarlyStart__c = DateTime.newInstance(startDate.year(), startDate.month(), startDate.day(), defaultstarttime, 0, 0);
        task.SLADate__c = DateTime.newInstance(scheduledDate.year(), scheduledDate.month(), scheduledDate.day(), defaultendTime, 0, 0);
        task.Building__c = operatingSchedule.PhysicalAsset__r.Building__c;
        task.AccountLocationID__c = operatingSchedule.PhysicalAsset__r.AccountLocation__r.SAP_Customer_ID__c;
        task.Floor__c = operatingSchedule.PhysicalAsset__r.Floor__c;
        //task.OP_IsHoliday__c = false;
        task.PhysicalAsset__c = operatingSchedule.PhysicalAsset__c;
        task.OP_PreferredOperator__c = operatingSchedule.PhysicalAsset__r.OP_PreferredOperator__c;
        //task.Sequence_Number__c = null;

        //to set pricebook entry
        String priceBookKey = String.valueOf(operatingSchedule.PhysicalAsset__r.Product__c) + operatingSchedule.PhysicalAsset__r.SalesOrganization__c;
        task.PricebookEntryId = pbeMap.get(priceBookKey) != null ? pbeMap.get(priceBookKey).Id : null;

        task.RecordTypeId = CONST_WOLI_OP_RT;
        task.Status = CONST_WOLI_OPEN_STATUS; //'Open'


        task.OP_247Customer__c = operatingSchedule.OP_247Customer__c;
        task.MachineCare__c = operatingSchedule.PhysicalAsset__r.Machine_Care__c;
        //task.OP_RinseRequired__c = isRinse;

        //task.SendCounterReadingsOperating__c = sendCounterReading;
        task.isFromRoute__c = true;     

        CustomLogging.pop();
        return task;
    }

    /******************************************************************************
     * Karen Hung
     * 18.03.2020  to return pricebookMap (Sales Org => PB)
     ******************************************************************************/
    private Map<String, Pricebook2> getPriceBookMap(){
        CustomLogging.push('getPriceBookMap', 'TS_MCOperating_Batch');
        Map<String, Pricebook2> countryPricebookMap = new Map<String, Pricebook2>();
        for(Pricebook2 pb: [SELECT Id, Sales_Organization__c FROM Pricebook2 WHERE IsActive = true]){
            countryPricebookMap.put(pb.Sales_Organization__c, pb);
        }
        CustomLogging.pop();
        return countryPricebookMap;
    }

    /******************************************************************************
     * Karen Hung
     * 24.03.2020   Method to create a custom log record if there is failed record processed in the batch execution.
     ******************************************************************************/
    public void INSERT_LOGGING (List<Database.SaveResult> saveResultList, String description) {
        CustomLogging.push('INSERT_LOGGING', 'TS_MCOperating_Batch');

        try{
            
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
                    StackTrace__c = 'Machine Clean Operating Batch: ' + description,
                    Message__c = mainMessage,
                    ExceptionType__c = TS_Constants.DATABASE_ERROR);
                insert log;
            }

            if(Test.isRunningTest() && hasException){
                throw new TS_MCOperating_BatchException('Force to throw an exception');
            }

        }catch(Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        CustomLogging.pop();
    }

    /*Karen Hung 26.05.2020 DOO-4580 mapping for country settings for an org*/
    Map<String, List<CountrySetting__c>> orgCountrySettingsMap (){
        CustomLogging.push('schedRuleListMap', 'TS_MCOperating_Batch');
        Map<String, List<CountrySetting__c>> orgSettingMap = new  Map<String, List<CountrySetting__c>>();
        for(CountrySetting__c cset: [SELECT Id, Country__c, From__c, To__c FROM CountrySetting__c
                                     WHERE Recordtype.Name = :TS_Constants.TS_COUNTRYSETTING_RECORDTYPE_MCO_PM_RULES
                                     AND Country__c IN (:TS_Constants.SAP_6864, :TS_Constants.SAP_0975)
                                     AND From__c != null
                                     AND To__c != null
                                     AND Active__c= true]){
            
            if(orgSettingMap.containsKey(cset.Country__c)){
                orgSettingMap.get(cset.Country__c).add(cset);
            }else{
                orgSettingMap.put(cset.Country__c, new List<CountrySetting__c>{cset});    
            } 
        }

        CustomLogging.pop();
        return orgSettingMap;
    }
}