/*
 *Created by: Karen Hung 
 *Date: 29.03.2021 DOO-5146
 *Description: Apex Controller for TS_GenereatePreloadReports lightning component 
 * 
*/
public without sharing class TS_GeneratePreloadReportsController {
    
    public class TS_GeneratePreloadReportsControllerException extends Exception {}
    public static Boolean hasException = false;
    
	/**check if user is third party portal user*/ 
    @AuraEnabled
    public static string checkifThirdParty(){
		LightningResponse lResponse = new LightningResponse();
        try{
            
            String userId = UserInfo.getUserId();
            List<Resource__c> resourceList = [SELECT Id,Name, EmployeeFirstName__c, EmployeeLastName__c, RLS_Portal_User__c FROM Resource__c WHERE RelatedUser__c =:userId AND RLS_Portal_User__c = TRUE];
			lResponse.returnValue = JSON.serialize(resourceList);
            
            if (Test.isRunningTest() && hasException) {
                throw new TS_GeneratePreloadReportsControllerException('Force to throw an exception');
            }
        }catch (Exception e){
            lResponse.status = 'ERROR';
            lResponse.message = 'Error: ' + e.getMessage() + '\nSTACK TRACE: ' + e.getStackTraceString();
        }
        
		return JSON.serialize(lResponse);   
    }
    
    /*get third party resource options*/
    @AuraEnabled
    public static String get3pResource(Boolean isThirdPartyPortalUser){
        LightningResponse lResponse = new LightningResponse();
        
        try{
            
            String userId = UserInfo.getUserId();
            List<Resource__c> resourceList = new List<Resource__c>();
            if(isThirdPartyPortalUser){
                resourceList = [SELECT Id, Name, EmployeeFirstName__c, EmployeeLastName__c FROM Resource__c WHERE RelatedUser__c =:userId];
            }else{    
                resourceList = [SELECT Id, Name, EmployeeFirstName__c, EmployeeLastName__c FROM Resource__c WHERE Id IN (SELECT Third_Party_Resource__c FROM Apttus_Config2__AccountLocation__c WHERE Third_Party_Resource__c != NULL)];  
            }  
           
            lResponse.returnValue = JSON.serialize(resourceList);
            
            if (Test.isRunningTest() && hasException) {
                throw new TS_GeneratePreloadReportsControllerException('Force to throw an exception');
            }
            
        }catch (Exception e){
            lResponse.status = 'ERROR';
            lResponse.message = 'Error: ' + e.getMessage() + '\nSTACK TRACE: ' + e.getStackTraceString();
        }
        
        return JSON.serialize(lResponse);
    }
    
    @AuraEnabled
    public static String generatePreload(Date taskDate,  Date taskDate2, String selectedResource){
        LightningResponse lResponse = new LightningResponse();
        String docURL='';
        String userId = UserInfo.getUserId();
        
        try{
            
            //get resource record id of the current user
            String resourceId = selectedResource;
            
            
            //process taskdate evaluation 
            Date runDate = taskDate.addDays(-1);
            String country_Name = 'Netherlands';
            Integer numberDayToLookup;
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
            
            Integer addedDay = (date.today()+2).daysBetween(taskDate);
            
            //execute preload queueable
            /*TS_ThirdPartyPreloadQueueable preload = new TS_ThirdPartyPreloadQueueable();
            preload.taskDate = nextDate;
            preload.batchType = batchType;
            preload.BUSINESS_ID = busineshourId;
            preload.SEND_COUNTER =  SEND_COUNTER;
            preload.isRetry = FALSE;
            preload.runDate = runDate;
            preload.addedDay = addedDay;
            preload.country_Name = country_Name;
            preload.isThirdParty = true;
            preload.resourceId = resourceId;
            System.enqueueJob(preload);*/           
            
            
            docURL = PRELOAD_SCRIPT_NEW(nextDate,batchType,busineshourId,SEND_COUNTER,true,resourceId,country_Name);
            
             if (Test.isRunningTest() && hasException) {
                throw new TS_GeneratePreloadReportsControllerException('Force to throw an exception');
            }
            
        }catch (Exception e){
            lResponse.status = 'ERROR';
            lResponse.message = 'Error: ' + e.getMessage() + '\nSTACK TRACE: ' + e.getStackTraceString();
        }
        
		return docURL;
    }
    
    /*response format*/
    public class LightningResponse{
        @AuraEnabled
        public String returnValue;
        @AuraEnabled
        public String status;
        @AuraEnabled
        public String message;

        public LightningResponse(){
            this.returnValue = returnValue;
            this.status = status;
            this.message = message;
        }
    }
    
    /**
    * @author        Karen Hung
    * @date          Dec 23, 2020
    * @description   DOO-5149 Method to generate pre-load script and attach basic information for custom log for daily route.
    * @revision(s)
    */ 
    public static String PRELOAD_SCRIPT_NEW (Date nextDate, String batchType, String BUSINESS_ID, Boolean IS_CR_DAY, Boolean isThirdPartyPortal, String engineerId, String country_Name) {
        Map<String, String> activityAPIMap = new Map<String, String> { 'Large' => 'MTTO_FO_Large_Bucket__c', 'Small' => 'MTTO_FO_Small_Bucket__c', 'Cups' => 'MTTO_FO_Cups_Bucket__c'};   
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
            ( (engineerId !='' && engineerId !='JDE Only' && engineerId !='ALL') ? ' AND  PhysicalAsset__r.AccountLocation__r.Third_Party_Resource__c = :engineerId' : '' ) +
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
                            
                            String rowStr = EARLY_START_DATE + ';' + ACCLOC_NAME + ';' + ACCLOC_STREET + ';' + ACCLOC_CITY + ';' + ACCLOC_PC + ';' + OPSCHED_PHYSICALASSET + ';' + PHA_PRODUCTNAME + ';' + PHA_BUILDING + ';' + PHA_FLOOR + ';' + PHA_AREA + ';' + PHA_CUSTOMERREF + ';' + ACTIVITY_TYPE + ';' + OPG_BUCKET + ';' + FIELD_VALUE + ';' + IS_HOLIDAY;
                            String thirdPartyResource = locationMap.get(OP_VAR.Account_Location__c).Third_Party_Resource__c;
                            
                            
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
        //String myDomain = Url.getOrgDomainUrl().toExternalForm();
        //String initialURL = myDomain + '/servlet/servlet.FileDownload?file=';
        
        //List<Folder> folders = [SELECT Id, Name FROM Folder WHERE Name = 'Batch Pre-Load Reports'];
        //List<Document> doctoInsert = new List<Document>();
        //List<Custom_Log__c> logstoInsert = new List<Custom_Log__c>();
        
        List<ContentDistribution> cdList = new List<ContentDistribution>();
        List<ContentVersion> contentList = new List<ContentVersion>();
        
        List<String> JDEAllRows = new List<String>();
		JDEAllRows.addAll(CSVROWVALUES_SMALL);
        JDEAllRows.addAll(CSVROWVALUES_LARGE);
        JDEAllRows.addAll(CSVROWVALUES_CUP);
        JDEAllRows.addAll(CSVROWVALUES_RINSE);
        
        if(engineerId =='JDE Only' && JDEAllRows.size() > 0){
            String documentName = 'MANUAL_PRELOAD_ROUTE_OPERATING_FOR_' + String.valueOf(scheduledDate.format('MMMdd')) + ' ' + String.valueOf(Datetime.now());
            csvColumnHeader = 'NAME; PHYSICAL ASSET; START DATE; FIELD API; OPG BUCKET; NUMBER OF TASK; ROUTE ID; IS HOLIDAY?; ROUTE\n';  
            String csvFile = csvColumnHeader + String.join(CSVROWVALUES_SMALL, '\n') + '\n' + String.join(CSVROWVALUES_LARGE, '\n') + '\n' + String.join(CSVROWVALUES_CUP, '\n') + '\n' + String.join(CSVROWVALUES_RINSE, '\n');
            
            /* Document doc = new Document(Name = documentName, Body = Blob.valueOf(csvFile), FolderId = folders[0].Id, Type = 'csv', ContentType = 'application/vnd.ms-excel');
            insert doc;
            
            return initialURL+doc.Id; */
            
            ContentVersion preloadFile = new ContentVersion();
                preloadFile.VersionData = Blob.valueOf(csvFile);
                preloadFile.Title = documentName;
                preloadFile.PathOnClient = documentName + '.csv';
                preloadFile.ContentLocation='S';
                contentList.add(preloadFile);
                insert contentList;
                
            for(ContentVersion cont : [SELECT ContentDocumentId,Description,PathOnClient, ObjectReferenceID__c FROM ContentVersion WHERE id =: contentList]) {
                ContentDistribution cd = new ContentDistribution();
                cd.PreferencesAllowPDFDownload = true;
                cd.Name = cont.PathOnClient;
                cd.ContentVersionId = cont.Id;
                cd.RelatedRecordId = cont.Description;
                cd.PreferencesAllowOriginalDownload = true;
                cd.PreferencesAllowViewInBrowser = false;
                cd.PreferencesNotifyOnVisit = false;
                //cd.PreferencesPasswordRequired = true;
                cdList.add(cd);
            }
        }
        
        /********************************File creation for ThirdParty****************************************************************************/
        //Map<String, Document> resourceDocMap = new Map<String, Document>();
        if(!resourceRowsMap.isEmpty()){
           
            csvColumnHeader = 'Activity Date; Account Location Name; Account Location Street; Account Location City; Account Location PC; Physical Asset; PhA Product Name; PhA Building; PhA Floor; PhA Area; PhA Customer Reference; Activity Type; OPG Bucket; NUMBER OF TASK; IS HOLIDAY? \n';
            for(Resource__c resourceRec : [SELECT Id, Name FROM Resource__c WHERE Id IN :resourceRowsMap.keySet()]){
                //prep file for insertion
                String documentName = 'MANUAL_PRELOAD_ROUTE_OPERATING_FOR_' + resourceRec.Name + '_' + String.valueOf(scheduledDate.format('MMMdd')) + ' ' + String.valueOf(Datetime.now());
                String csvFile = csvColumnHeader + 
                                 (resourceRowsMap.containsKey(resourceRec.Id) ? String.join(resourceRowsMap.get(resourceRec.Id), '\n') : '');
                
                /* Document doc = new Document(Name = documentName, Body = Blob.valueOf(csvFile), FolderId = folders[0].Id, Type = 'csv', ContentType = 'application/vnd.ms-excel', IsPublic= true);
                doctoInsert.add(doc);
                resourceDocMap.put(resourceRec.Id, doc); */

                ContentVersion preloadFile = new ContentVersion();
                preloadFile.VersionData = Blob.valueOf(csvFile);
                preloadFile.Title = documentName;
                preloadFile.PathOnClient = documentName + '.csv';
                preloadFile.ContentLocation='S';
                contentList.add(preloadFile);
            }
            
            if(!contentList.isEmpty()){
                insert contentList;
                
                for(ContentVersion cont : [SELECT ContentDocumentId,Description,PathOnClient, ObjectReferenceID__c FROM ContentVersion WHERE id =: contentList]) {
                    ContentDistribution cd = new ContentDistribution();
                    cd.PreferencesAllowPDFDownload = true;
                    cd.Name = cont.PathOnClient;
                    cd.ContentVersionId = cont.Id;
                    cd.RelatedRecordId = cont.Description;
                    cd.PreferencesAllowOriginalDownload = true;
                    cd.PreferencesAllowViewInBrowser = false;
                    cd.PreferencesNotifyOnVisit = false;
                    //cd.PreferencesPasswordRequired = true;
                    cdList.add(cd);
                }
            }
            
        }
        
        //if(!cdList.isEmpty() && engineerId !='JDE Only' && engineerId !='ALL'){
        if(!cdList.isEmpty()){
            insert cdList;
            List<ContentDistribution> newList_content = [SELECT Id, Name, ContentDownloadUrl,DistributionPublicUrl, PdfDownloadUrl FROM ContentDistribution WHERE Id =: cdList];
            //if with password, use DistributionPublicUrl, otherwise ContentDownloadUrl
            return (newList_content[0].ContentDownloadUrl);
        }
        
      return ''; 
    }
}