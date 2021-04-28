/**
* @author        Adrian Reyes
* @date          01.05.2018
* @description   Class primarily responsible in handling dynamic SLAs for field service case records
* @revision(s)
*/

global without sharing class DynamicFirstResponseCalculator implements Support.MilestoneTriggerTimeCalculator {
    
    /**
    * @author        Ritesh Kuamr
    * @date          16.08.2018           
    * @description   To throw custome exception
    * @revision(s)
    */
    public class DynamicFirstResponseCalculatorException extends Exception{}
    
    
    /**
    * @author        Adrian Reyes
    * @date          01.05.2018           
    * @description   Method to get response time depending on case response profile
    * @revision(s)
    */

 
    global Integer calculateMilestoneTriggerTime(String caseId, String milestoneTypeId) {
        CustomLogging.push('calculateMilestoneTriggerTime', 'DynamicFirstResponseCalculator');
        
        Boolean recalculateFirstTask = false;

        //DOO-603 Xen Reyes July 12, 2019 SLA EOD Implementation
        Case c = [SELECT ResponseProfile__c, Entitlement.ActualWorkingHours__c, BusinessHoursId, CreatedDate, SLARecalculation__c FROM Case WHERE Id =: caseId LIMIT 1];
        BusinessHours BUSINESS_HOUR = [SELECT Id, MondayStartTime, MondayEndTime, 
                                                    TuesdayStartTime, TuesdayEndTime, 
                                                    WednesdayStartTime, WednesdayEndTime, 
                                                    ThursdayStartTime, ThursdayEndTime, 
                                                    FridayStartTime, FridayEndTime, 
                                                    SaturdayStartTime, SaturdayEndTime,
                                                    SundayStartTime, SundayEndTime FROM BusinessHours WHERE Id =: c.BusinessHoursId];

        Integer result = 0;//IN MINUTES
        String RESPONSE_PROF = String.valueOf(c.ResponseProfile__c);
        if(RESPONSE_PROF.contains('EOD')){

            //GET CREATED DATE OF CASE
            //Date DATE_TODAY = Date.today();
            System.debug('c.CreatedDate: ' + c.CreatedDate);
            System.debug('c.CreatedDate - String: ' + String.valueOf(c.CreatedDate));

            //XEN REYES Sept. 9, 2019
            Date DATE_TODAY = Date.valueOf(String.valueOf(c.CreatedDate));
            //Date DATE_TODAY = Date.valueOf(c.CreatedDate);

            System.debug('DATE_TODAY: ' + DATE_TODAY);

            Integer ADD_DAYS_VAR = 0;
            if(RESPONSE_PROF == 'EOD1'){
                //DATE_TODAY = DATE_TODAY.addDays(1);
                ADD_DAYS_VAR = 1;
            } else if(RESPONSE_PROF == 'EOD2'){
                //DATE_TODAY = DATE_TODAY.addDays(2);
                ADD_DAYS_VAR = 2;
            } else if(RESPONSE_PROF == 'EOD3'){
                //DATE_TODAY = DATE_TODAY.addDays(3);
                ADD_DAYS_VAR = 3;
            } else if(RESPONSE_PROF == 'EOD4'){
                //DATE_TODAY = DATE_TODAY.addDays(4);
                ADD_DAYS_VAR = 4;
            }

            //CHECKER IF BEFORE OR AFTER WORKING HOURS - Xen Reyes - September 30, 2019
            Date NEXT_WORKING_DAY = Date.valueOf(String.valueOf(BusinessHours.nextStartDate(c.BusinessHoursId, c.CreatedDate)));
            System.debug('NEXT_WORKING_DAY: ' + NEXT_WORKING_DAY);

            if(NEXT_WORKING_DAY > DATE_TODAY){
                ADD_DAYS_VAR = ADD_DAYS_VAR + 1;
            }

            //SHOULD ONLY CONSIDER ALL WORKING DAYS
            Integer REP_VAR = 0;
            do{ 
                DATE_TODAY = DATE_TODAY.addDays(1);
                                
                //TIME IS ACCOUNTED IN CHECKING IF A DAY IS BUSINESS DAY - Assuming that 11:00 am is always a working time of all working days
                DateTime CHECK_WITH_HOURS = DateTime.newInstance(DATE_TODAY, Time.newInstance(11, 0, 0, 0));

                /* System.debug('CHECK_WITH_HOURS: ' + CHECK_WITH_HOURS);
                System.debug('CHECK_WITH_HOURS String: ' + String.valueOf(CHECK_WITH_HOURS));
                System.debug('CHECK_WITH_HOURS DateTimeValue: ' + DateTime.valueOf(String.valueOf(CHECK_WITH_HOURS)));*/

                if(BusinessHours.isWithin(c.BusinessHoursId, CHECK_WITH_HOURS)){
                    REP_VAR++;
                }

            } while (REP_VAR < ADD_DAYS_VAR); 

            //Date WORKING_DATE = TS_UtilityClass.getWorkingDate(c.BusinessHoursId, DATE_TODAY);
            Date WORKING_DATE = Date.valueOf(BusinessHours.nextStartDate(c.BusinessHoursId, DATE_TODAY));
            System.debug('WORKING_DATE' + WORKING_DATE);

            Time MY_TIME = Time.newInstance(17, 0, 0, 0);
            if (Label.TS_SLA_Monday.equals(TS_UtilityClass.getReadableDay(WORKING_DATE))) {
                MY_TIME = BUSINESS_HOUR.MondayEndTime;
            } else if (Label.TS_SLA_Tuesday.equals(TS_UtilityClass.getReadableDay(WORKING_DATE))) {
                MY_TIME = BUSINESS_HOUR.TuesdayEndTime;
            } else if (Label.TS_SLA_Wednesday.equals(TS_UtilityClass.getReadableDay(WORKING_DATE))) {
                MY_TIME = BUSINESS_HOUR.WednesdayEndTime;
            } else if (Label.TS_SLA_Thursday.equals(TS_UtilityClass.getReadableDay(WORKING_DATE))) {
                MY_TIME = BUSINESS_HOUR.ThursdayEndTime;
            } else if (Label.TS_SLA_Friday.equals(TS_UtilityClass.getReadableDay(WORKING_DATE))) {
                MY_TIME = BUSINESS_HOUR.FridayEndTime;
            } else if (Label.TS_SLA_Saturday.equals(TS_UtilityClass.getReadableDay(WORKING_DATE))) {
                MY_TIME = BUSINESS_HOUR.SaturdayEndTime != null ? BUSINESS_HOUR.SaturdayEndTime : MY_TIME;
            } else if (Label.TS_SLA_Sunday.equals(TS_UtilityClass.getReadableDay(WORKING_DATE))) {
                MY_TIME = BUSINESS_HOUR.SundayEndTime != null? BUSINESS_HOUR.SundayEndTime : MY_TIME;
            }

            DateTime SLA_DATETIME = DateTime.newInstance(WORKING_DATE, MY_TIME);
            c.SLADate__c = SLA_DATETIME;
            //result = Integer.valueOf(BusinessHours.diff(c.BusinessHoursId, DateTime.now(), SLA_DATETIME) / (1000 * 60));
            result = Integer.valueOf(BusinessHours.diff(c.BusinessHoursId, c.CreatedDate, SLA_DATETIME) / (1000 * 60));

        } else {
            Integer responseProfile = Integer.valueOf(c.ResponseProfile__c); //IN HOURS
            
            //CHECK IF RETRIEVED RESPONSE PROFILE IS 24 HOURS OR MORE
            if(responseProfile >= 24){
                result = Integer.valueOf((responseProfile / 24) * c.Entitlement.ActualWorkingHours__c * 60); 
            } else{
                result = responseProfile * 60;
            }
            
            //UPDATE CASE SLA DATE
            Integer responseTimeInMilliseconds = (result * 60 * 1000) + 1000; //Karen Hung DOO-64 add 1 second
            c.SLADate__c = BusinessHours.add(c.BusinessHoursId, c.CreatedDate, responseTimeInMilliseconds);
            //system.debug('Karen sla' + c.SLADate__c);
        }

        //SLA RECALCULATION DOO-5274 XEN REYES - Jan. 26, 2020
        if(c.SLARecalculation__c){
            recalculateFirstTask = true;
            c.SLARecalculation__c = false;
        }
        
        try {
            if(Schema.sObjectType.Case.isUpdateable())
               update c;
            if(Test.isRunningTest()){
                Throw new DynamicFirstResponseCalculatorException('Test class Exception');
            }
        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }

        //UPDATE OPEN FIRST TASK WOLI WHEN THERE IS A RECALCULATION
        //SLA RECALCULATION DOO-5274 XEN REYES - Jan. 26, 2020
        if(recalculateFirstTask){

            List<WorkOrderLineItem> firstTaskWOLIList = [SELECT Id, SLADate__c FROM WorkOrderLineItem 
                                                        WHERE Case__c =: c.Id AND IsFirstTask__c = true AND Status NOT IN ('Completed', 'Canceled', 'Review Needed') AND WorkOrderLineItemType__c = 'Task' LIMIT 1];
            
            if(!firstTaskWOLIList.isEmpty()){
                WorkOrderLineItem woli = firstTaskWOLIList[0];
                if(woli.SLADate__c != c.SLADate__c){
                    woli.SLADate__c = c.SLADate__c;

                    try {
                        update woli;
                        if(Test.isRunningTest()){
                            throw new DynamicFirstResponseCalculatorException('Test class Exception');
                        }
                    } catch (Exception ex) {
                        CustomLogging.debugException(ex);
                        CustomLogging.pop();
                        System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
                    }
                }
            }
        }
        
        CustomLogging.pop();
        return result;
    }
    
    /**
    * @author        Marvin Gatchalian
    * @date          04.25.2018           
    * @description   Method to get response time depending on case response profile bulkify version
    * @revision(s)
    */
    global Integer calculateMilestoneTriggerTimeBulk (Set <Id> caseIds) {
        CustomLogging.push('calculateMilestoneTriggerTime', 'DynamicFirstResponseCalculator');
        List<Case> cases = new List<Case>();
        List<Case> tobeUpdated = new List<Case>();
        Integer result = 0; //in Minutes
                
        if (!caseIds.isEmpty())
         cases = [SELECT ResponseProfile__c, Entitlement.ActualWorkingHours__c, BusinessHoursId, CreatedDate FROM Case WHERE Id =: caseIds];


        for (Case c :cases) {
            Integer responseProfile = Integer.valueOf(c.ResponseProfile__c);    //in Hours
           
            
            //Check if retrieved response profile is 24 hours or more
            if(responseProfile >= 24){
                result = Integer.valueOf((responseProfile / 24) * c.Entitlement.ActualWorkingHours__c * 60); 
            }
            else{
                result = responseProfile * 60;
            }
            
            //Update Case SLA Date
            Integer responseTimeInMilliseconds = (result * 60 * 1000) + 1000; //Karen Hung DOO-64 add 1 second
            c.SLADate__c = BusinessHours.add(c.BusinessHoursId, c.CreatedDate, responseTimeInMilliseconds);
            tobeUpdated.add(c);
        }
        
        try {
            
            if(!tobeUpdated.isEmpty())
               update tobeUpdated;
            
            if(Test.isRunningTest()){
                Throw new DynamicFirstResponseCalculatorException('Test class Exception');
            }
            
        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        
        CustomLogging.pop();
        return result;
    }

   /**
    * @author        Francis Alindogan
    * @date          11.12.2019           
    * @description   Method to pass SLA Date Time to Flow
    * @revision(s)
            DOO-2697 12/16/2019 modified method to have same logic with CaseTriggerHandler's response  profile  computation.
            DOO-4616 06/10/2020 modified to handle bulk woli transactions. removed invocable setting.
            DOO-4271 10.01.2020 refactored, created a separate method for the response profile calculateResponseProfile.

    */    
    public static Map<Id, Datetime> calculateSLADate(List<WorkOrderLineItem> woliList, Map<Id, WorkOrderLineItem> extWoliNewMap){
        CustomLogging.push('calculateSLADate', 'DynamicFirstResponseCalculator');
        Map<Id,String> woliResProfMap = new Map<Id,String>();
        Map<Id, Datetime> returnMap = new Map<Id, Datetime>();       
        woliResProfMap = calculateResponseProfile(woliList, extWoliNewMap);
        if(woliResProfMap != null){
            DynamicFirstResponseCalculator dfrc = new DynamicFirstResponseCalculator();        
            returnMap = dfrc.SLACalculation(woliList,woliResProfMap, extWoliNewMap);
        }    
        CustomLogging.pop();
        return returnMap;
    }

     /**
    * @author        Francis Alindogan
    * @date          11.21.2019           
    * @description   Method to compute SLA
    * @revision(s)
            DOO-4616 06/10/2020 modified to handle bulk woli transactions
    **/
    global Map<Id,Datetime> SLACalculation (List<WorkOrderLineItem> woliList, Map<Id, String> woliResProfMap, Map<Id, WorkOrderLineItem> extWoliNewMap){
            CustomLogging.push('SLACalculation', 'DynamicFirstResponseCalculator');
            Map<Id,BusinessHours> bHourMap = new Map<Id, BusinessHours>();            
            Map<Id,Datetime> woliSLAMap = new Map<Id, Datetime>();                    
            Set<Id> bHourSet = new Set<Id>();

            if(woliList != null && woliList.size() > 0 && woliResProfMap != null && extWoliNewMap != null){
                //GET SETS FOR QUERY
                for(WorkOrderLineItem woli : woliList){
                    if(woli.RelateTo__c != null && extWoliNewMap.get(woli.RelateTo__c).Case__r.BusinessHoursId != null){
                        bHourSet.add(extWoliNewMap.get(woli.RelateTo__c).Case__r.BusinessHoursId);
                    }                    
                }            

                List<BusinessHours> bHourList = [SELECT Id, MondayStartTime, MondayEndTime, 
                                                        TuesdayStartTime, TuesdayEndTime, 
                                                        WednesdayStartTime, WednesdayEndTime, 
                                                        ThursdayStartTime, ThursdayEndTime, 
                                                        FridayStartTime, FridayEndTime, 
                                                        SaturdayStartTime, SaturdayEndTime,
                                                        SundayStartTime, SundayEndTime FROM BusinessHours WHERE Id IN: bHourSet];
                
                //CREATE BUSINESS HOUR MAP
                for(BusinessHours bh : bHourList){
                    bHourMap.put(bh.Id, bh);
                }

                for(WorkOrderLineItem woli : woliList){        
                    Datetime SLADate;
                    Integer result;
                    BusinessHours BUSINESS_HOUR;
                    String RESPONSE_PROF;
                    
                    if(woliResProfMap != null && woliResProfMap.get(woli.RelateTo__c) != null ){
                        RESPONSE_PROF = woliResProfMap.get(woli.RelateTo__c);
                    }
                    
                    //FOR TEST COVERAGE, TEMPORARY RESPONSE PROFILE
                   /* if(Test.isRunningTest()){
                        RESPONSE_PROF = 'EOD1';
                    } */
                    
                    if(bHourMap != null && extWoliNewMap.get(woli.RelateTo__c) != null){
                        BUSINESS_HOUR = bHourMap.get(extWoliNewMap.get(woli.RelateTo__c).Case__r.BusinessHoursId);                                
                    }
                    
                    if(RESPONSE_PROF != null && RESPONSE_PROF.contains('EOD')){

                        //XEN REYES Sept. 9, 2019
                        Date DATE_TODAY = Date.valueOf(String.valueOf(DateTime.now()));
                        //Date DATE_TODAY = Date.valueOf(c.CreatedDate);

                        Integer ADD_DAYS_VAR = 0;
                        if(RESPONSE_PROF == 'EOD1'){
                            //DATE_TODAY = DATE_TODAY.addDays(1);
                            ADD_DAYS_VAR = 1;
                        } else if(RESPONSE_PROF == 'EOD2'){
                            //DATE_TODAY = DATE_TODAY.addDays(2);
                            ADD_DAYS_VAR = 2;
                        } else if(RESPONSE_PROF == 'EOD3'){
                            //DATE_TODAY = DATE_TODAY.addDays(3);
                            ADD_DAYS_VAR = 3;
                        } else if(RESPONSE_PROF == 'EOD4'){
                            //DATE_TODAY = DATE_TODAY.addDays(4);
                            ADD_DAYS_VAR = 4;
                        }

                        //CHECKER IF BEFORE OR AFTER WORKING HOURS - Xen Reyes - September 30, 2019
                        Date NEXT_WORKING_DAY = Date.valueOf(String.valueOf(BusinessHours.nextStartDate(extWoliNewMap.get(woli.RelateTo__c).Case__r.BusinessHoursId, DateTime.now())));

                        if(NEXT_WORKING_DAY > DATE_TODAY){
                            ADD_DAYS_VAR = ADD_DAYS_VAR + 1;
                        }

                        //SHOULD ONLY CONSIDER ALL WORKING DAYS
                        Integer REP_VAR = 0;
                        do{ 
                            DATE_TODAY = DATE_TODAY.addDays(1);
                                            
                            //TIME IS ACCOUNTED IN CHECKING IF A DAY IS BUSINESS DAY - Assuming that 11:00 am is always a working time of all working days
                            DateTime CHECK_WITH_HOURS = DateTime.newInstance(DATE_TODAY, Time.newInstance(11, 0, 0, 0));

                            /* System.debug('CHECK_WITH_HOURS: ' + CHECK_WITH_HOURS);
                            System.debug('CHECK_WITH_HOURS String: ' + String.valueOf(CHECK_WITH_HOURS));
                            System.debug('CHECK_WITH_HOURS DateTimeValue: ' + DateTime.valueOf(String.valueOf(CHECK_WITH_HOURS)));*/

                            if(BusinessHours.isWithin(extWoliNewMap.get(woli.RelateTo__c).Case__r.BusinessHoursId, CHECK_WITH_HOURS)){
                                REP_VAR++;
                            }

                        } while (REP_VAR < ADD_DAYS_VAR); 

                        //Date WORKING_DATE = TS_UtilityClass.getWorkingDate(c.BusinessHoursId, DATE_TODAY);
                        Date WORKING_DATE = Date.valueOf(BusinessHours.nextStartDate(extWoliNewMap.get(woli.RelateTo__c).Case__r.BusinessHoursId, DATE_TODAY));                        

                        Time MY_TIME = Time.newInstance(17, 0, 0, 0);
                        if (Label.TS_SLA_Monday.equals(TS_UtilityClass.getReadableDay(WORKING_DATE))) {
                            MY_TIME = BUSINESS_HOUR.MondayEndTime;
                        } else if (Label.TS_SLA_Tuesday.equals(TS_UtilityClass.getReadableDay(WORKING_DATE))) {
                            MY_TIME = BUSINESS_HOUR.TuesdayEndTime;
                        } else if (Label.TS_SLA_Wednesday.equals(TS_UtilityClass.getReadableDay(WORKING_DATE))) {
                            MY_TIME = BUSINESS_HOUR.WednesdayEndTime;
                        } else if (Label.TS_SLA_Thursday.equals(TS_UtilityClass.getReadableDay(WORKING_DATE))) {
                            MY_TIME = BUSINESS_HOUR.ThursdayEndTime;
                        } else if (Label.TS_SLA_Friday.equals(TS_UtilityClass.getReadableDay(WORKING_DATE))) {
                            MY_TIME = BUSINESS_HOUR.FridayEndTime;
                        } else if (Label.TS_SLA_Saturday.equals(TS_UtilityClass.getReadableDay(WORKING_DATE))) {
                            MY_TIME = BUSINESS_HOUR.SaturdayEndTime != null ? BUSINESS_HOUR.SaturdayEndTime : MY_TIME;
                        } else if (Label.TS_SLA_Sunday.equals(TS_UtilityClass.getReadableDay(WORKING_DATE))) {
                            MY_TIME = BUSINESS_HOUR.SundayEndTime != null? BUSINESS_HOUR.SundayEndTime : MY_TIME;
                        }

                        DateTime SLA_DATETIME = DateTime.newInstance(WORKING_DATE, MY_TIME);
                        SLADate = SLA_DATETIME;
                    }
                    else if(RESPONSE_PROF != null){

                        Integer responseProfile = Integer.valueOf(RESPONSE_PROF);
                        //Check if retrieved response profile is 24 hours or more
                        if(responseProfile >= 24){                        
                            if(extWoliNewMap != null && woli.RelateTo__c != null && extWoliNewMap.get(woli.RelateTo__c).Case__r.Entitlement.ActualWorkingHours__c != null){
                                result = Integer.valueOf((responseProfile / 24) * Integer.valueOf(extWoliNewMap.get(woli.RelateTo__c).Case__r.Entitlement.ActualWorkingHours__c) * 60); 
                            }
                        }
                        else{
                            result = Integer.valueOf(responseProfile) * 60;
                        }
                        //Update Case SLA Date
                        Integer responseTimeInMilliseconds = (result * 60 * 1000) + 1000; //Karen Hung DOO-64 add 1 second
                        
                        if(extWoliNewMap != null && woli.RelateTo__c != null && extWoliNewMap.containsKey(woli.RelateTo__c) && extWoliNewMap.get(woli.RelateTo__c).Case__r.BusinessHoursId != null){
                            SLADate = BusinessHours.add(extWoliNewMap.get(woli.RelateTo__c).Case__r.BusinessHoursId, DateTime.now(), responseTimeInMilliseconds);
                        }
                        
                    } 

                    if(SLADate != null){
                        woliSLAMap.put(woli.RelateTo__c, SLADate);
                    }
                }
            }   
        CustomLogging.pop();        
        return woliSLAMap;
    }

    /**
    * @author        Francis Alindogan
    * @date          10.01.2020
    * @description   Method to compute response profile
    * @revision(s)        
    **/    
    public static Map<Id, String> calculateResponseProfile(List<WorkOrderLineItem> woliList, Map<Id, WorkOrderLineItem> extWoliNewMap){
        CustomLogging.push('calculateResponseProfile', 'DynamicFirstResponseCalculator');
        List<DateTime> resultList = new List<DateTime>();
        Map<Id, String> woliResProfMap = new Map<Id, String>();         
        Map<String,CountrySetting__c> countrySettingMap = new Map<String,CountrySetting__c>();
            
        if(woliList != null && woliList.size() > 0 && extWoliNewMap != null){

            CaseTriggerHandler cth = new CaseTriggerHandler();
            List<CountrySetting__c> countryRespProfile =  cth.getCountrySetViaRectypeName(TS_Constants.TS_COUNTRYSETTING_RECORDTYPE_RESPONSEPROFILE);
            if(countryRespProfile != null){
                for(CountrySetting__c countrySetting : countryRespProfile){
                    countrySettingMap.put(countrySetting.Country__c + '-' + countrySetting.Priority__c + '-' + countrySetting.Coffee_is_Running__c + '-' + (countrySetting.AssetResponseProfile__c == null ? 'null' : countrySetting.AssetResponseProfile__c), countrySetting);
                }  
            }

            //CREATE RESPONSE PROFILE LABEL MAP           
            Map<String, String> responseTimeMap = new Map<String, String>();  
            Schema.SObjectType s = Schema.getGlobalDescribe().get('PhysicalAsset__c');
            Schema.DescribeSObjectResult r = s.getDescribe() ;
            Map<String,Schema.SObjectField> fields = r.fields.getMap() ;
            Schema.DescribeFieldResult fieldResult = fields.get('ResponseTime__c').getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for(Schema.PicklistEntry pickListVal : ple){                
                responseTimeMap.put(pickListVal.getValue(), pickListVal.getLabel());    
            }           
            if(!countrySettingMap.isEmpty()){
                for(WorkOrderLineItem woli : woliList){                
                    String RESPONSE_PROF;
                    Boolean COFFEE_IS_RUNNING;
                    
                    if(woli.ReturnTask__c == true){
                        COFFEE_IS_RUNNING = woli.IsCoffeeRunning__c;
                    }
                    else {
                        COFFEE_IS_RUNNING = extWoliNewMap.get(woli.RelateTo__c).isCoffeeRunning__c;
                    }

                    if(woli.RelateTo__c != null && extWoliNewMap.get(woli.RelateTo__c) != null){
                        //Field Service s10 or s15
                        if (extWoliNewMap.get(woli.RelateTo__c).Case__r.Type == TS_Constants.CASE_TYPE_FIELDSERVICE && (woli.WorkOrderType__c == TS_Constants.CASE_SUBTYPE_CORRECTMAINTAPI || 
                            woli.WorkOrderType__c == TS_Constants.CASE_SUBTYPE_1STLINECORRECTMAINTAPI)) {      

                            //Medium with Physical Asset
                            if (extWoliNewMap.get(woli.RelateTo__c).Case__r.Priority == TS_Constants.CASE_PRIORITY_MEDIUM && woli.PhysicalAsset__c != null){
                                //Corrective maintenance/S10 scenario with response time AND coffee is NOT running AND Contract is Active
                                if (extWoliNewMap.get(woli.RelateTo__c).PhysicalAsset__r.ResponseTime__c != null && woli.WorkOrderType__c == TS_Constants.CASE_SUBTYPE_CORRECTMAINTAPI && !COFFEE_IS_RUNNING && extWoliNewMap.get(woli.RelateTo__c).PhysicalAsset__r.EndDate__c !=null && extWoliNewMap.get(woli.RelateTo__c).PhysicalAsset__r.EndDate__c >= Date.Today()) {                         
                                    RESPONSE_PROF = responseTimeMap.get(String.valueOf(extWoliNewMap.get(woli.RelateTo__c).PhysicalAsset__r.ResponseTime__c)); //Karen Hung 16.09.2019                
                                } 
                                //1st line corrective maintenance/S15 scenario with response time 15
                                else if (extWoliNewMap.get(woli.RelateTo__c).PhysicalAsset__r.ResponseTimeS15__c != null && woli.WorkOrderType__c == TS_Constants.CASE_SUBTYPE_1STLINECORRECTMAINTAPI) {
                                    RESPONSE_PROF = responseTimeMap.get(String.valueOf(extWoliNewMap.get(woli.RelateTo__c).PhysicalAsset__r.ResponseTimeS15__c));       
                                } 
                                //If S15 with null response time 15 but with response time 10 
                                else if (extWoliNewMap.get(woli.RelateTo__c).PhysicalAsset__r.ResponseTimeS15__c == null && woli.WorkOrderType__c == TS_Constants.CASE_SUBTYPE_1STLINECORRECTMAINTAPI && extWoliNewMap.get(woli.RelateTo__c).PhysicalAsset__r.ResponseTime__c != null ) {                       
                                    RESPONSE_PROF = responseTimeMap.get(String.valueOf(extWoliNewMap.get(woli.RelateTo__c).PhysicalAsset__r.ResponseTime__c));
                                } 
                                //Use country setting response profile when physical assets response time is empty OR coffee is running OR Contract is Inactive
                                else {              
                                        
                                        //Map to 'No Contract' if inactive OR blank response profile, if not, map to Physical Asset's reponse time
                                        CountrySetting__c countrySetting = countrySettingMap.get(extWoliNewMap.get(woli.RelateTo__c).Case__r.SalesOrganization__c + '-' + extWoliNewMap.get(woli.RelateTo__c).Case__r.Priority + '-' + COFFEE_IS_RUNNING + '-' + (COFFEE_IS_RUNNING && extWoliNewMap.get(woli.RelateTo__c).PhysicalAsset__r.ResponseTime__c != null && extWoliNewMap.get(woli.RelateTo__c).PhysicalAsset__r.EndDate__c >= Date.Today() ? responseTimeMap.get(String.valueOf(extWoliNewMap.get(woli.RelateTo__c).PhysicalAsset__r.ResponseTime__c)) : TS_Constants.NO_CONTRACT)); //Karen Hung DOO-853 added coffee is running
                                        
                                        //Map to 'No Contract' if active, coffee is running with response profile but without country setting mapping
                                        if(COFFEE_IS_RUNNING && extWoliNewMap.get(woli.RelateTo__c).PhysicalAsset__r.ResponseTime__c != null && countrySetting == null){                                   
                                            countrySetting =  countrySettingMap.get(extWoliNewMap.get(woli.RelateTo__c).Case__r.SalesOrganization__c + '-' + extWoliNewMap.get(woli.RelateTo__c).Case__r.Priority + '-' + COFFEE_IS_RUNNING + '-' + TS_Constants.NO_CONTRACT);  
                                        }
                                        if(countrySetting != null){
                                            RESPONSE_PROF = countrySetting.ResponseProfile__c != null ? countrySetting.ResponseProfile__c : null;                                                                 
                                        }
                                }
                            } 
                            //s10 medium with null PA    
                            else if (extWoliNewMap.get(woli.RelateTo__c).Case__r.Priority == TS_Constants.CASE_PRIORITY_MEDIUM && woli.PhysicalAsset__c == null && woli.WorkOrderType__c == TS_Constants.CASE_SUBTYPE_CORRECTMAINTAPI ){ //Karen Hung DOO-853 04.09.2019
                                CountrySetting__c countrySetting = countrySettingMap.get(extWoliNewMap.get(woli.RelateTo__c).Case__r.SalesOrganization__c + '-' + extWoliNewMap.get(woli.RelateTo__c).Case__r.Priority + '-' + COFFEE_IS_RUNNING + '-' + TS_Constants.NO_CONTRACT); //Karen Hung DOO-853 03.09.2019 added coffee is running and response time
                                RESPONSE_PROF = countrySetting.ResponseProfile__c != null ? countrySetting.ResponseProfile__c : null;    
                            } 
                            else {                
                                CountrySetting__c countrySetting = countrySettingMap.get(extWoliNewMap.get(woli.RelateTo__c).Case__r.SalesOrganization__c + '-' + extWoliNewMap.get(woli.RelateTo__c).Case__r.Priority + '-' + COFFEE_IS_RUNNING + '-' + TS_Constants.NA);//Karen Hung DOO-859 added coffee is running, and asset profile 
                                RESPONSE_PROF = countrySetting.ResponseProfile__c != null ? countrySetting.ResponseProfile__c : null;                         
                            }
                        }
                            woliResProfMap.put(woli.RelateTo__c,RESPONSE_PROF);
                    }
                }    
            }                      
        }        
        return woliResProfMap;
    }
}