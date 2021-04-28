/*
* @author        Abram Vixen Retes
* @date          Oct. 7, 2019
* @description   Controller class for TS_MeanTimeOverview
*/
public without sharing class TS_MeanTimeOverviewController {
       
    public class LightningResponse{
        @AuraEnabled
        public String returnValue;
        @AuraEnabled
        public String status;
        @AuraEnabled
        public String message;
    }

    public class MainWrapper_OperatorWithRoute{
        @AuraEnabled
        public List<MainWrapper_Operator> mainwrapper_list_operator;
        @AuraEnabled
        public List<MainWrapper> mainwrapper_list;
    }

    public class MainWrapper_Operator{
        @AuraEnabled
        public Integer day_num;
        @AuraEnabled
        public Decimal total;
        @AuraEnabled
        public String total_formatted;
        @AuraEnabled
        public List<MainWrapper> mainwrapper_list;
    }

    public class MainWrapper_AccountLocation{
        @AuraEnabled
        public String account_location_name_total;
        @AuraEnabled
        public String account_location_postalcode;
        @AuraEnabled
        public String account_location_id;
        @AuraEnabled
        public Boolean account_loc_withoutSched;
        @AuraEnabled
        public Boolean account_loc_withUnassignedMachines;
        @AuraEnabled
        public List<MainWrapper> mainwrapper_list;
        @AuraEnabled
        public List<PerDayTotalObject_AccountLocation> per_day_all_accloc;
    }

    public class PerDayTotalObject_AccountLocation{
        @AuraEnabled
        public Integer day_num;
        @AuraEnabled
        public Decimal total;
        @AuraEnabled
        public String total_formatted;
        @AuraEnabled
        public String total_count;
        @AuraEnabled
        public String total_formatted_JDE;
        @AuraEnabled
        public String total_count_JDE;
    }

    public class MainWrapper{
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String account_location_name;
        @AuraEnabled
        public String account_location_id;
        @AuraEnabled
        public String account_location_postal_code;
        @AuraEnabled
        public String routeId;
        @AuraEnabled
        public String routeName;
        @AuraEnabled
        public List<TaskTypePerDayTotalObject> info_all;
        @AuraEnabled
        public List<PerDayTotalObject> per_day_all;
        @AuraEnabled
        public List<PerDayCountObject> per_day_count;
    }

    public class PerDayTotalObject{
        @AuraEnabled
        public Integer day_num;
        @AuraEnabled
        public Decimal total;
        @AuraEnabled
        public String total_formatted;
        @AuraEnabled
        public Decimal total_JDE;
        @AuraEnabled
        public String total_formatted_JDE;
    }
    
    public class PerDayCountObject {
        @AuraEnabled
        public Integer day_num;
        @AuraEnabled
        public Integer small_num;
        @AuraEnabled
        public Integer cups_num;
        @AuraEnabled
        public Integer large_num;        
        @AuraEnabled
        public Integer small_num_JDE;
        @AuraEnabled
        public Integer cups_num_JDE;
        @AuraEnabled
        public Integer large_num_JDE;    
    }

    public class TaskTypePerDayTotalObject{
        @AuraEnabled
        public List<AssetPerDayTotalObject> asset_per_day_list_wrapper;
        @AuraEnabled
        public String tasktype;
    }

    public class AssetPerDayTotalObject{
        @AuraEnabled
        public List<AssetPerValueObject> asset_per_value_list_wrapper;
        @AuraEnabled
        public Decimal total;
        @AuraEnabled
        public Integer day_num;
    }

    public class AssetPerValueObject{
        @AuraEnabled
        public Id assetId;
        /* @AuraEnabled
        public Integer number_of_visit;
        @AuraEnabled
        public Decimal mtto_pbentry;
        @AuraEnabled
        public Decimal mt_accloc_location;
        @AuraEnabled
        public Decimal mt_accloc_site;
        @AuraEnabled
        public Decimal mt_accloc_averagePrep; */
        @AuraEnabled
        public Decimal computed_value;
    }

    @AuraEnabled
    public static string getInformation(List<String> recordId, Boolean isRoute, Boolean isOverview, Boolean isOptimizer, Boolean isOperator, Boolean showMachineWithoutSchedule, Boolean showUnassignedMachines, Boolean showCustomersWithoutRoutes, 
                                        List<String> listAccIdUnfiltered, List<String> listAccIdUnassignedMachine, List<String> listAccIdWithoutSchedule, Boolean isNordics, String filterType, Boolean showLarge){
        
        LightningResponse lResponse = new LightningResponse();
        List<MainWrapper> mw_List = new List<MainWrapper>();
        List<MainWrapper_AccountLocation> mw_accLoc_List = new List<MainWrapper_AccountLocation>();
        List<MainWrapper_OperatorWithRoute> mw_RouteOperator_view_list = new List<MainWrapper_OperatorWithRoute>();
        
        Set<Id> accLoc_no_opSched = new Set<Id>();
        Set<Id> accLoc_no_opSched_nonZero = new Set<Id>();

        Map<Id, List<Route__c>> accLocId_route_map = new Map<Id, List<Route__c>>();
        Map<Id, List<Route_Line_Item__c>> accLocId_routeLineItem_map = new Map<Id, List<Route_Line_Item__c>>();

        DescribeSObjectResult routeDescribe = Route__c.getSObjectType().getDescribe();
        List <String> fieldsRoute = new List <String> (routeDescribe.fields.getMap().keySet());

        try{

            Map<Id, Route__c> map_route = new Map<Id, Route__c>();
            
            if(isRoute){
                
                map_route = new Map<Id, Route__c>([SELECT Id, Name, Unique_Route_Number__c, Preferred_Operator__c, Has_Stock_Location__c, Account_Location__c, Account_Location__r.Name, Account_Location__r.Apttus_Config2__PostalCode__c, Account_Location__r.Second_Account_Name__c, Account_Location__r.SAP_Customer_ID__c, Day1__c, Day2__c, Day3__c, Day4__c, Day5__c, Day6__c, Day7__c, Day8__c, Day9__c, Day10__c, Day11__c, Day12__c, Day13__c, Day14__c, Nordics_1__c, Nordics_2__c, Nordics_3__c, Nordics_4__c, Nordics_5__c, Nordics_6__c, Nordics_7__c, Nordics_8__c, Nordics_9__c, Nordics_10__c, Nordics_11__c, Nordics_12__c, Cups__c, Large__c, Small__c, MTTO_All__c, MCO__c, MTTO_3rd_Party__c, Small_3rd_Party__c, Cups_3rd_Party__c, MTTO_JDEOnly__c, Small_JDEOnly__c, Cups_JDEOnly__c, Large_JDEOnly__c FROM Route__c WHERE Id IN: recordId]);

            } else if (isOverview || isOptimizer){
                
                map_route = new Map<Id, Route__c>([SELECT Id, Name, Unique_Route_Number__c, Preferred_Operator__c, Has_Stock_Location__c, Account_Location__c, Account_Location__r.Name, Account_Location__r.Apttus_Config2__PostalCode__c, Account_Location__r.Second_Account_Name__c, Account_Location__r.SAP_Customer_ID__c, Day1__c, Day2__c, Day3__c, Day4__c, Day5__c, Day6__c, Day7__c, Day8__c, Day9__c, Day10__c, Day11__c, Day12__c, Day13__c, Day14__c, Nordics_1__c, Nordics_2__c, Nordics_3__c, Nordics_4__c, Nordics_5__c, Nordics_6__c, Nordics_7__c, Nordics_8__c, Nordics_9__c, Nordics_10__c, Nordics_11__c, Nordics_12__c, Cups__c, Large__c, Small__c, MTTO_All__c, MCO__c, MTTO_3rd_Party__c, Small_3rd_Party__c, Cups_3rd_Party__c, MTTO_JDEOnly__c, Small_JDEOnly__c, Cups_JDEOnly__c, Large_JDEOnly__c FROM Route__c WHERE Account_Location__c IN: recordId]);
            
            } else if(isOperator){

                map_route = new Map<Id, Route__c>([SELECT Id, Name, Unique_Route_Number__c, Preferred_Operator__c, Has_Stock_Location__c, Account_Location__c, Account_Location__r.Name, Account_Location__r.Apttus_Config2__PostalCode__c, Account_Location__r.Second_Account_Name__c, Account_Location__r.SAP_Customer_ID__c, Day1__c, Day2__c, Day3__c, Day4__c, Day5__c, Day6__c, Day7__c, Day8__c, Day9__c, Day10__c, Day11__c, Day12__c, Day13__c, Day14__c, Nordics_1__c, Nordics_2__c, Nordics_3__c, Nordics_4__c, Nordics_5__c, Nordics_6__c, Nordics_7__c, Nordics_8__c, Nordics_9__c, Nordics_10__c, Nordics_11__c, Nordics_12__c, Cups__c, Large__c, Small__c, MTTO_All__c, MCO__c, MTTO_3rd_Party__c, Small_3rd_Party__c, Cups_3rd_Party__c, MTTO_JDEOnly__c, Small_JDEOnly__c, Cups_JDEOnly__c, Large_JDEOnly__c FROM Route__c WHERE Preferred_Operator__c IN: recordId OR Required_Operator__c IN: recordId]);
            }
            
            //GET ALL ROUTES
            if(!map_route.isEmpty()){

                //FORM THE WRAPPER CLASS & CALCULATION (LARGE, SMALL, CUPS)
                for(Id route_var : map_route.keySet()){
                    
                    //Map<String,Map<Integer, AssetPerDayTotalObject>> map_taskResult = new Map<String,Map<Integer, AssetPerDayTotalObject>>();
                    MainWrapper mw = new MainWrapper();
                    List<TaskTypePerDayTotalObject> task_type_list = new List<TaskTypePerDayTotalObject>();
                    List<PerDayCountObject> per_day_count_list = new List<PerDayCountObject>();
                    List<PerDayTotalObject> per_day_total_list = new List<PerDayTotalObject>();
                    
                    /*
                    if(isNordics){
                        for(Integer i = 1; i <= 12; i++){
                        
                            PerDayTotalObject per_day_total_cont = new PerDayTotalObject();
                            Route__c routeVar = map_route.get(route_var);
                            Decimal totalPerDay = 0;
                            String apiName = 'Nordics_' + i + '__c';
                                                            
                            if(routeVar.get(apiName) != null){
                                totalPerDay = Decimal.valueOf(String.valueOf(routeVar.get(apiName)));
                            }
    
                            per_day_total_cont.day_num = i;
                            per_day_total_cont.total = totalPerDay;
                            per_day_total_cont.total_formatted = formatHHMM(totalPerDay);
                            per_day_total_list.add(per_day_total_cont);
                        }
                    } else {
                        for(Integer i = 1; i <= 14; i++){
                        
                            PerDayTotalObject per_day_total_cont = new PerDayTotalObject();
                            Route__c routeVar = map_route.get(route_var);
                            Decimal totalPerDay = 0;
                            String apiName = 'Day' + i + '__c';
    
                            if(routeVar.get(apiName) != null){
                                totalPerDay = Decimal.valueOf(String.valueOf(routeVar.get(apiName)));
                            }
    
                            per_day_total_cont.day_num = i;
                            per_day_total_cont.total = totalPerDay;
                            per_day_total_cont.total_formatted = formatHHMM(totalPerDay);
                            per_day_total_list.add(per_day_total_cont);
                        }
                    }*/
                    
                    //map_route_type_day_calc.put(map_route.get(route_var),map_taskResult);
                    mw.name = map_route.get(route_var).Name;

                    if(map_route.get(route_var).Account_Location__r.SAP_Customer_ID__c != null){
                        mw.account_location_name = map_route.get(route_var).Account_Location__r.Name + ' (' + map_route.get(route_var).Account_Location__r.SAP_Customer_ID__c + ')';
                    } else {
                        mw.account_location_name = map_route.get(route_var).Account_Location__r.Name;
                    }

                    mw.account_location_id = map_route.get(route_var).Account_Location__c;
                    mw.account_location_postal_code = map_route.get(route_var).Account_Location__r.Apttus_Config2__PostalCode__c;
                    mw.routeId = route_var;
                    mw.routeName = map_route.get(route_var).Name;
                    
                    //MANUAL TRUNCATION
                    if(mw.routeName != null) mw.routeName = mw.routeName.left(17) + (mw.routeName.length() > 17 ? '...' : '');
                    
                    mw.info_all = task_type_list;
                                                  
                    //TOTAL                                                                                   
                    if(filterType == 'all'){
                        //GET MTTO
                        //FOR NORDICS
                        if(isNordics){
                            if(map_route.get(route_var) != null && map_route.get(route_var).MCO__c != null){
                                Map<String,Object> MCOPlaceHolder = (Map<String, Object>)JSON.deserializeUntyped(map_route.get(route_var).MCO__c);
                                for(Integer i = 1; i <= 12; i++){                            
                                    PerDayTotalObject per_day_total_cont = new PerDayTotalObject();
                                    Route__c routeVar = map_route.get(route_var);
                                    Decimal totalPerDay = 0;
                                    String apiName = 'nordics_' + i;
                                                                    
                                    if(MCOPlaceHolder.get(apiName) != null){
                                        totalPerDay = Decimal.valueOf(String.valueOf(MCOPlaceHolder.get(apiName)));
                                    }
                                    else {
                                        totalPerDay = 0;
                                    }
        
                                    per_day_total_cont.day_num = i;
                                    per_day_total_cont.total = totalPerDay;
                                    per_day_total_cont.total_formatted = formatHHMM(totalPerDay);
                                    per_day_total_list.add(per_day_total_cont);
                                }
                            }
                            //IF MCO NULL, POPULATE WITH 0                            
                            else {
                                Integer totalPerDay = 0;
                                for(Integer i = 1; i <= 12; i++){
                                    PerDayTotalObject per_day_total_cont = new PerDayTotalObject();
                                    per_day_total_cont.day_num = i;
                                    per_day_total_cont.total = totalPerDay;
                                    per_day_total_cont.total_formatted = formatHHMM(totalPerDay);
                                    per_day_total_list.add(per_day_total_cont);
                                }
                            }
                        }                         
                        //FOR NL
                        else {
                            if(map_route.get(route_var) != null && map_route.get(route_var).MTTO_All__c != null && map_route.get(route_var).MTTO_JDEOnly__c != null){
                                Map<String,Object> MTTOPlaceHolder = (Map<String, Object>)JSON.deserializeUntyped(map_route.get(route_var).MTTO_All__c);
                                Map<String,Object> MTTOJDEPlaceHolder = (Map<String, Object>)JSON.deserializeUntyped(map_route.get(route_var).MTTO_JDEOnly__c);
                                for(Integer i = 1; i <= 14; i++){                        
                                                                    
                                    PerDayTotalObject per_day_total_cont = new PerDayTotalObject();
                                    Route__c routeVar = map_route.get(route_var);
                                    Decimal totalPerDay = 0;                                
                                    Decimal totalPerDay_JDE = 0;   
                                    String day_name = 'day_'+i;
        
                                    if(MTTOPlaceHolder.get(day_name) != null){
                                        totalPerDay = Decimal.valueOf(String.valueOf(MTTOPlaceHolder.get(day_name)));
                                    }
                                    else {
                                        totalPerDay = 0;
                                    }

                                    if(MTTOJDEPlaceHolder.get(day_name) != null){
                                        totalPerDay_JDE = Decimal.valueOf(String.valueOf(MTTOJDEPlaceHolder.get(day_name)));
                                    }
                                    else {
                                        totalPerDay_JDE = 0;
                                    }
        
                                    per_day_total_cont.day_num = i;
                                    per_day_total_cont.total = totalPerDay;
                                    per_day_total_cont.total_formatted = formatHHMM(totalPerDay);
                                    per_day_total_cont.total_JDE = totalPerDay_JDE;
                                    per_day_total_cont.total_formatted_JDE = formatHHMM(totalPerDay_JDE);
                                    per_day_total_list.add(per_day_total_cont);                                    
                                }
                            }
                            //IF MTTO NULL, POPULATE WITH 0
                            else {
                                Integer totalPerDay = 0;
                                Integer totalPerDay_JDE = 0;
                                for(Integer i = 1; i <= 14; i++){
                                    PerDayTotalObject per_day_total_cont = new PerDayTotalObject();
                                    per_day_total_cont.day_num = i;
                                    per_day_total_cont.total = totalPerDay;
                                    per_day_total_cont.total_formatted = formatHHMM(totalPerDay);
                                    per_day_total_cont.total_JDE = totalPerDay_JDE;
                                    per_day_total_cont.total_formatted_JDE = formatHHMM(totalPerDay_JDE);
                                    per_day_total_list.add(per_day_total_cont);
                                }
                            }
                        }
                        
                        //GET S/C
                        if(map_route.get(route_var) != null && map_route.get(route_var).Cups__c != null && map_route.get(route_var).Large__c != null && map_route.get(route_var).Small__c != null &&
                           map_route.get(route_var) != null && map_route.get(route_var).Cups_JDEOnly__c != null && map_route.get(route_var).Large_JDEOnly__c != null && map_route.get(route_var).Small_JDEOnly__c != null
                          ){                                            
                            Map<String,Object> CupsPlaceHolder  = (Map<String, Object>)JSON.deserializeUntyped(map_route.get(route_var).Cups__c);
                            Map<String,Object> SmallPlaceHolder = (Map<String, Object>)JSON.deserializeUntyped(map_route.get(route_var).Small__c);
                            Map<String,Object> LargePlaceHolder = (Map<String, Object>)JSON.deserializeUntyped(map_route.get(route_var).Large__c);
                            Map<String,Object> CupsJDEPlaceHolder  = (Map<String, Object>)JSON.deserializeUntyped(map_route.get(route_var).Cups_JDEOnly__c);
                            Map<String,Object> SmallJDEPlaceHolder = (Map<String, Object>)JSON.deserializeUntyped(map_route.get(route_var).Small_JDEOnly__c);
                            Map<String,Object> LargeJDEPlaceHolder = (Map<String, Object>)JSON.deserializeUntyped(map_route.get(route_var).Large_JDEOnly__c);
                        
                            for(Integer i = 1; i <= 14; i++){
                                String day_name = 'day_'+i;
                                PerDayCountObject per_day_cnt = new PerDayCountObject();                                                   
                                per_day_cnt.day_num = i;
                                per_day_cnt.small_num = Integer.valueOf(SmallPlaceHolder.get(day_name));
                                per_day_cnt.cups_num =  Integer.valueOf(CupsPlaceHolder.get(day_name));
                                per_day_cnt.large_num = Integer.valueOf(LargePlaceHolder.get(day_name));                        
                                per_day_cnt.small_num_JDE = Integer.valueOf(SmallJDEPlaceHolder.get(day_name));
                                per_day_cnt.cups_num_JDE =  Integer.valueOf(CupsJDEPlaceHolder.get(day_name));
                                per_day_cnt.large_num_JDE = Integer.valueOf(LargeJDEPlaceHolder.get(day_name));    
                                per_day_count_list.add(per_day_cnt);
                            }
                            mw.per_day_count = per_day_count_list;
                        }  
                        //IF S/C NULL, POPULATE WITH 0
                        else {
                            for(Integer i = 1; i <= 14; i++){
                                String day_name = 'day_'+i;
                                PerDayCountObject per_day_cnt = new PerDayCountObject();                                                   
                                per_day_cnt.day_num = i;
                                per_day_cnt.small_num = 0;
                                per_day_cnt.cups_num =  0;
                                per_day_cnt.large_num = 0;  
                                per_day_cnt.small_num_JDE = 0;
                                per_day_cnt.cups_num_JDE = 0;
                                per_day_cnt.large_num_JDE = 0;                         
                                per_day_count_list.add(per_day_cnt);
                            }
                            mw.per_day_count = per_day_count_list;                      
                        } 
                    }        
                    else if(filterType == '3po'){
                        //GET MTTO                                                            
                        if(map_route.get(route_var) != null && map_route.get(route_var).MTTO_3rd_Party__c != null){
                            Map<String,Object> MTTOPlaceHolder = (Map<String, Object>)JSON.deserializeUntyped(map_route.get(route_var).MTTO_3rd_Party__c);
                            for(Integer i = 1; i <= 14; i++){                        
                                
                                PerDayTotalObject per_day_total_cont = new PerDayTotalObject();
                                Route__c routeVar = map_route.get(route_var);
                                Decimal totalPerDay = 0;                                
                                String day_name = 'day_'+i;
                                
                                if(MTTOPlaceHolder.get(day_name) != null){
                                    totalPerDay = Decimal.valueOf(String.valueOf(MTTOPlaceHolder.get(day_name)));
                                }
                                else {
                                    totalPerDay = 0;
                                }                                
                                per_day_total_cont.day_num = i;
                                per_day_total_cont.total = totalPerDay;
                                per_day_total_cont.total_formatted = formatHHMM(totalPerDay);
                                per_day_total_list.add(per_day_total_cont);                                    
                            }
                        }
                        //IF MTTO NULL, POPULATE WITH 0
                        else {
                            Integer totalPerDay = 0;
                            for(Integer i = 1; i <= 14; i++){
                                PerDayTotalObject per_day_total_cont = new PerDayTotalObject();
                                per_day_total_cont.day_num = i;
                                per_day_total_cont.total = totalPerDay;
                                per_day_total_cont.total_formatted = formatHHMM(totalPerDay);
                                per_day_total_list.add(per_day_total_cont);
                            }
                        }
                                                
                        //GET S/C
                        if(map_route.get(route_var) != null && map_route.get(route_var).Cups_3rd_Party__c != null && map_route.get(route_var).Small_3rd_Party__c != null){                                            
                            Map<String,Object> CupsPlaceHolder = (Map<String, Object>)JSON.deserializeUntyped(map_route.get(route_var).Cups_3rd_Party__c);                            
                            Map<String,Object> SmallPlaceHolder = (Map<String, Object>)JSON.deserializeUntyped(map_route.get(route_var).Small_3rd_Party__c);
                        
                            for(Integer i = 1; i <= 14; i++){
                                String day_name = 'day_'+i;
                                PerDayCountObject per_day_cnt = new PerDayCountObject();                                                   
                                per_day_cnt.day_num = i;
                                per_day_cnt.small_num = Integer.valueOf(SmallPlaceHolder.get(day_name));
                                per_day_cnt.cups_num =  Integer.valueOf(CupsPlaceHolder.get(day_name));                                                     
                                per_day_count_list.add(per_day_cnt);
                            }
                            mw.per_day_count = per_day_count_list;
                        }  
                        //IF S/C NULL, POPULATE WITH 0
                        else {
                            for(Integer i = 1; i <= 14; i++){
                                String day_name = 'day_'+i;
                                PerDayCountObject per_day_cnt = new PerDayCountObject();                                                   
                                per_day_cnt.day_num = i;
                                per_day_cnt.small_num = 0;
                                per_day_cnt.cups_num =  0;                                                
                                per_day_count_list.add(per_day_cnt);
                            }
                            mw.per_day_count = per_day_count_list;                      
                        } 
                        
                    }                          
                    mw.per_day_all = per_day_total_list;
                    mw_List.add(mw);                                        
                }                

                if(isOverview || isOptimizer || isOperator){

                    //CONSTRUCT THE TOTAL PER ACCOUNT LOCATION                    
                    //GROUP THE DAILY ROUTE TOTALS BY ACCOUNT LOCATION
                    Map<String, List<MainWrapper>> accLoc_per_mw_map = new Map<String, List<MainWrapper>>();
                    for(MainWrapper mw_var : mw_List){
                        if(accLoc_per_mw_map.containsKey(mw_var.account_location_id)){
                            accLoc_per_mw_map.get(mw_var.account_location_id).add(mw_var);
                        } else {
                            accLoc_per_mw_map.put(mw_var.account_location_id, new List<MainWrapper>{mw_var});
                        }
                    }

                    if(!accLoc_per_mw_map.isEmpty()){
                        for(String id_var : accLoc_per_mw_map.keySet()){
                            List<MainWrapper> all_wrap_accloc = accLoc_per_mw_map.get(id_var);

                            Map<Integer, Decimal> per_day_per_accountloc_total = new Map<Integer, Decimal>();
                            Map<Integer, String>  per_day_per_accountloc_count_total = new Map<Integer, String>();                            
                            Map<Integer, Decimal> per_day_per_accountloc_count_large = new Map<Integer, Decimal>();
                            Map<Integer, Decimal> per_day_per_accountloc_count_small = new Map<Integer, Decimal>();
                            Map<Integer, Decimal> per_day_per_accountloc_count_cups  = new Map<Integer, Decimal>();

                            Map<Integer, Decimal> per_day_per_accountloc_total_JDE = new Map<Integer, Decimal>();
                            Map<Integer, String>  per_day_per_accountloc_count_total_JDE  = new Map<Integer, String>();                            
                            Map<Integer, Decimal> per_day_per_accountloc_count_large_JDE = new Map<Integer, Decimal>();
                            Map<Integer, Decimal> per_day_per_accountloc_count_small_JDE = new Map<Integer, Decimal>();
                            Map<Integer, Decimal> per_day_per_accountloc_count_cups_JDE = new Map<Integer, Decimal>();
                                                        
                            for(MainWrapper mw_var : all_wrap_accloc){
                                for(PerDayTotalObject pd_var : mw_var.per_day_all){                                    
                                    //FOR ALL AND 3PO
                                    if(per_day_per_accountloc_total.containsKey(pd_var.day_num)){
                                        per_day_per_accountloc_total.put(pd_var.day_num, per_day_per_accountloc_total.get(pd_var.day_num) + pd_var.total);
                                    } else {
                                        per_day_per_accountloc_total.put(pd_var.day_num, pd_var.total);
                                    }
                                    //ADDITIONAL FOR ALL SCENARIO (TO INCLUDE JDE ONLY)
                                    if(filterType == 'all'){                                                                            
                                        if(per_day_per_accountloc_total_JDE.containsKey(pd_var.day_num)){
                                            per_day_per_accountloc_total_JDE.put(pd_var.day_num, per_day_per_accountloc_total_JDE.get(pd_var.day_num) + pd_var.total_JDE);
                                        } else {
                                            per_day_per_accountloc_total_JDE.put(pd_var.day_num, pd_var.total_JDE);
                                        }
                                    }                                       
                                }
                                
                                if(mw_var.per_day_count != null){                                    
                                    for(PerDayCountObject pd_var : mw_var.per_day_count){  
                                        //FOR ALL  
                                        //SMALL
                                        if(per_day_per_accountloc_count_small.containsKey(pd_var.day_num)){                                                                                                                                    
                                            per_day_per_accountloc_count_small.put(pd_var.day_num, per_day_per_accountloc_count_small.get(pd_var.day_num) + pd_var.small_num);                               
                                        } 
                                        else {                                            
                                            per_day_per_accountloc_count_small.put(pd_var.day_num, pd_var.small_num);                                       
                                        }
                                        //CUPS
                                        if(per_day_per_accountloc_count_cups.containsKey(pd_var.day_num)){                                                                                                                                                                                
                                            per_day_per_accountloc_count_cups.put(pd_var.day_num,  per_day_per_accountloc_count_cups.get(pd_var.day_num)  + pd_var.cups_num);                                           
                                        } 
                                        else {                                                                                        
                                            per_day_per_accountloc_count_cups.put(pd_var.day_num, pd_var.cups_num);                                                  
                                        }                                                                                
                                        //LARGE
                                        if(per_day_per_accountloc_count_large.containsKey(pd_var.day_num)){                                                                                                                                                                                
                                            if(filterType == 'all'){
                                                if(showLarge){
                                                    per_day_per_accountloc_count_large.put(pd_var.day_num,  per_day_per_accountloc_count_large.get(pd_var.day_num)  + pd_var.large_num);
                                                }                                                    
                                            }
                                        } 
                                        else {                                                                           
                                            if(filterType == 'all'){
                                                if(showLarge){
                                                    per_day_per_accountloc_count_large.put(pd_var.day_num, pd_var.large_num);
                                                }
                                            }
                                        }
                                        
                                        //ADDITIONAL FOR ALL SCENARIO (TO INCLUDE JDE ONLY)
                                    	if(filterType == 'all'){                                           
                                            //SMALL
                                            if(per_day_per_accountloc_count_small_JDE.containsKey(pd_var.day_num)){                                                                                                                                    
                                                per_day_per_accountloc_count_small_JDE.put(pd_var.day_num, per_day_per_accountloc_count_small_JDE.get(pd_var.day_num) + pd_var.small_num_JDE);                               
                                            } 
                                            else {                                            
                                                per_day_per_accountloc_count_small_JDE.put(pd_var.day_num, pd_var.small_num_JDE);                                       
                                            }
                                            //CUPS
                                            if(per_day_per_accountloc_count_cups_JDE.containsKey(pd_var.day_num)){                                                                                                                                                                                
                                                per_day_per_accountloc_count_cups_JDE.put(pd_var.day_num,  per_day_per_accountloc_count_cups_JDE.get(pd_var.day_num)  + pd_var.cups_num_JDE);                                           
                                            } 
                                            else {                                                                                        
                                                per_day_per_accountloc_count_cups_JDE.put(pd_var.day_num, pd_var.cups_num_JDE);                                                  
                                            }   
                                            //LARGE
                                            if(per_day_per_accountloc_count_large_JDE.containsKey(pd_var.day_num)){                                                                                                                                                                                                                            
                                                per_day_per_accountloc_count_large_JDE.put(pd_var.day_num,  per_day_per_accountloc_count_large_JDE.get(pd_var.day_num)  + pd_var.large_num_JDE);                                        
                                            } 
                                            else {                                                                           
                                                per_day_per_accountloc_count_large_JDE.put(pd_var.day_num, pd_var.large_num_JDE);
                                            }
                                        }                                            
                                    }
                                    //LOOP SMALL TO MAKE SURE THAT BOTH ALL AND 3PO SCENARIOS WOULD LOOP 14 TIMES
                                    for(Integer s : per_day_per_accountloc_count_small.keySet()){
                                        Integer small = Integer.valueOf(per_day_per_accountloc_count_small.get(s));
                                        Integer cups  = Integer.valueOf(per_day_per_accountloc_count_cups.get(s));                 
                                        Integer large  = Integer.valueOf(per_day_per_accountloc_count_large.get(s));  
                                        Integer small_JDE  = Integer.valueOf(per_day_per_accountloc_count_small_JDE.get(s));     
                                        Integer cups_JDE  = Integer.valueOf(per_day_per_accountloc_count_cups_JDE.get(s));     
                                        Integer large_JDE  = Integer.valueOf(per_day_per_accountloc_count_large_JDE.get(s));     
                                        if(filterType == 'all'){                                            
                                            if(showLarge){                                                
                                                per_day_per_accountloc_count_total.put(s, String.valueOf(cups)+'c / '+String.valueOf(small)+'s / '+String.valueOf(large)+'L');                                                                                
                                                per_day_per_accountloc_count_total_JDE.put(s, String.valueOf(cups_JDE)+'c / '+String.valueOf(small_JDE)+'s / '+String.valueOf(large_JDE)+'L');                                                                                
                                            }
                                            else {
                                                per_day_per_accountloc_count_total.put(s, String.valueOf(cups)+'c / '+String.valueOf(small)+'s');        
                                                per_day_per_accountloc_count_total_JDE.put(s, String.valueOf(cups_JDE)+'c / '+String.valueOf(small_JDE)+'s / '+String.valueOf(large_JDE)+'L');                                                                                
                                            }                                            
                                        }
                                        else {
                                            per_day_per_accountloc_count_total.put(s, String.valueOf(cups)+'c / '+String.valueOf(small)+'s');                                                                                
                                        }                                                                                                                           
                                    }                                                                        
                                }                                                                                                                              
                            }
                            

                            //CREATE THE WRAPPER FOR TOTAL
                            List<PerDayTotalObject_AccountLocation> per_day_total_acc_list = new List<PerDayTotalObject_AccountLocation>();
                            if(!per_day_per_accountloc_total.isEmpty()){
                                for(Integer int_var : per_day_per_accountloc_total.keySet()){

                                    PerDayTotalObject_AccountLocation per_day_total_accLoc = new PerDayTotalObject_AccountLocation();
                                    per_day_total_accLoc.day_num = int_var;
                                    per_day_total_accLoc.total = per_day_per_accountloc_total.get(int_var);
                                    per_day_total_accLoc.total_formatted = formatHHMM(per_day_per_accountloc_total.get(int_var));                                    
                                    if(per_day_per_accountloc_count_total != null && per_day_per_accountloc_count_total.get(int_var) != null){
                                        per_day_total_accLoc.total_count = per_day_per_accountloc_count_total.get(int_var);    
                                    }           

                                    //FOR JDE ONLY
                                    per_day_total_accLoc.total_count_JDE = per_day_per_accountloc_count_total_JDE.get(int_var);    
                                    per_day_total_accLoc.total_formatted_JDE = formatHHMM(per_day_per_accountloc_total_JDE.get(int_var));

                                    per_day_total_acc_list.add(per_day_total_accLoc);
                                }
                            }

                            MainWrapper_AccountLocation mw_accloc_var = new MainWrapper_AccountLocation();
                            mw_accloc_var.mainwrapper_list = all_wrap_accloc;
                            mw_accloc_var.per_day_all_accloc = per_day_total_acc_list;
                            mw_accloc_var.account_location_id = id_var;
                            mw_accloc_var.account_location_name_total = all_wrap_accloc[0].account_location_name;
                            mw_accloc_var.account_location_postalcode = all_wrap_accloc[0].account_location_postal_code;
                            
                            mw_accloc_var.account_loc_withUnassignedMachines = false;
                            mw_accloc_var.account_loc_withoutSched = false;

                            if(listAccIdUnassignedMachine.contains(id_var)){
                                mw_accloc_var.account_loc_withUnassignedMachines = true;
                            }

                            if(listAccIdWithoutSchedule.contains(id_var)){
                                mw_accloc_var.account_loc_withoutSched = true;
                            }

                            mw_accLoc_List.add(mw_accloc_var);
                        }
                    }

                    if(isOperator){
                        
                        //CONSTRUCT THE TOTAL PER DAY
                        Map<Integer, Decimal> per_day_total_operator = new Map<Integer, Decimal>();
                        if(!mw_accLoc_List.isEmpty()){
                            for(MainWrapper_AccountLocation mwa_var : mw_accLoc_List){
                                for(PerDayTotalObject_AccountLocation pw_var : mwa_var.per_day_all_accloc){
                                    if(per_day_total_operator.containsKey(pw_var.day_num)){
                                        per_day_total_operator.put(pw_var.day_num, per_day_total_operator.get(pw_var.day_num) + pw_var.total);
                                    } else {
                                        per_day_total_operator.put(pw_var.day_num, pw_var.total);
                                    }
                                }
                            }
                        }

                        //CREATE THE WRAPPER FOR TOTAL
                        List<MainWrapper_Operator> wrap_operator_list = new List<MainWrapper_Operator>();
                        if(!per_day_total_operator.isEmpty()){
                            for(Integer int_var : per_day_total_operator.keySet()){

                                MainWrapper_Operator per_day_total_accLoc_operator = new MainWrapper_Operator();
                                per_day_total_accLoc_operator.day_num = int_var;
                                per_day_total_accLoc_operator.total = per_day_total_operator.get(int_var);
                                per_day_total_accLoc_operator.total_formatted = formatHHMM(per_day_total_operator.get(int_var));
                                wrap_operator_list.add(per_day_total_accLoc_operator);
                            }
                        }

                        MainWrapper_OperatorWithRoute mw_RouteOperator_view = new MainWrapper_OperatorWithRoute();
                        mw_RouteOperator_view.mainwrapper_list_operator = wrap_operator_list;
                        mw_RouteOperator_view.mainwrapper_list = mw_List;
                        mw_RouteOperator_view_list.add(mw_RouteOperator_view);
                    }

                    if(showUnassignedMachines || showMachineWithoutSchedule){
                        //mw_accLoc_List.addAll(createContainers(showUnassignedMachines, showMachineWithoutSchedule, listAccIdUnassignedMachine, listAccIdWithoutSchedule, accLocId_route_map, accLocId_routeLineItem_map, recordId));
                    }
                    
                }
                    
                lResponse.status = 'SUCCESS';

                if(isOverview || isOptimizer){
                    lResponse.returnValue = JSON.serialize(mw_accLoc_List);
                } else if(isOperator) {
                    lResponse.returnValue = JSON.serialize(mw_RouteOperator_view_list);
                } else {
                    lResponse.returnValue = JSON.serialize(mw_List);
                }

            } else {    
                
                if(!showUnassignedMachines && !showMachineWithoutSchedule && !showCustomersWithoutRoutes){
                    lResponse.status = 'ERROR';
                    
                    if(isOperator){
                        lResponse.message = 'No routes assigned to this operator.';
                    } else {
                        lResponse.message = 'No route found in the account locations assigned to this team.';    
                    }
                    
                } else {
                    //mw_accLoc_List.addAll(createContainers(showUnassignedMachines, showMachineWithoutSchedule, listAccIdUnassignedMachine, listAccIdWithoutSchedule, accLocId_route_map, accLocId_routeLineItem_map, recordId));

                    if(showCustomersWithoutRoutes){
                        mw_accLoc_List.addAll(createContainersNoRoutes(recordId, isNordics, filterType, showLarge));
                    }

                    
                    lResponse.status = 'SUCCESS';
                    lResponse.returnValue = JSON.serialize(mw_accLoc_List);
                }

            }

        } catch (Exception e){
            lResponse.status = 'ERROR';
            lResponse.message = 'Error: ' + e.getMessage() + '\nSTACK TRACE: ' + e.getStackTraceString();
            System.debug(e);
        }
        
        return JSON.serialize(lResponse);         
    }

    @AuraEnabled
    public static List<MainWrapper_AccountLocation> createContainers(Boolean showUnassignedMachines, Boolean showMachineWithoutSchedule, List<String> listAccIdUnassignedMachine, List<String> listAccIdWithoutSchedule, 
                                                                        Map<Id, List<Route__c>> accLocId_route_map,  Map<Id, List<Route_Line_Item__c>> accLocId_routeLineItem_map, List<String> recordId){
        
        //CREATE NEW INSTANCE OF ENTRY FOR IDS NOT IN THE MAPS ABOVE IF FILTER IS ENABLED
        //Account Locations with Unassigned Machines

        List<MainWrapper_AccountLocation> toAdd_mw = new List<MainWrapper_AccountLocation>();
        Map<Id, Apttus_Config2__AccountLocation__c> map_listAccIdUnassignedMachine = new Map<Id, Apttus_Config2__AccountLocation__c>();
        Map<Id, Apttus_Config2__AccountLocation__c> map_listAccIdWithoutSchedule = new Map<Id, Apttus_Config2__AccountLocation__c>();

        Map<Id, Apttus_Config2__AccountLocation__c> map_currentRecords = new Map<Id, Apttus_Config2__AccountLocation__c>();

        //DAY CONTAINER FOR PLACEHOLDER
        List<PerDayTotalObject_AccountLocation> container_zeroes = new List<PerDayTotalObject_AccountLocation>();
        for(Integer i = 1; i <= 14; i++){
            PerDayTotalObject_AccountLocation perday_var = new PerDayTotalObject_AccountLocation();
            perday_var.day_num = 0;
            perday_var.total = 0;
            perday_var.total_formatted = '0';
            container_zeroes.add(perday_var);
        }
        
        map_currentRecords = new Map<Id, Apttus_Config2__AccountLocation__c>([SELECT Id, Name, SAP_Customer_ID__c, Apttus_Config2__PostalCode__c FROM Apttus_Config2__AccountLocation__c WHERE Id IN: recordId]);
        
        Map<Id, MainWrapper_AccountLocation> exist_checker = new Map<Id, MainWrapper_AccountLocation>();
        if(showUnassignedMachines){

            for(String id_var : recordId){
                if(
                    (!accLocId_route_map.containsKey(id_var) || (accLocId_route_map.containsKey(id_var) && !accLocId_routeLineItem_map.containsKey(id_var))) && listAccIdUnassignedMachine.contains(id_var)
                    ){
                    MainWrapper_AccountLocation mw_accloc_var = new MainWrapper_AccountLocation();
                    mw_accloc_var.account_location_id = id_var;
                    mw_accloc_var.account_location_name_total = map_currentRecords.get(id_var).Name;
                    mw_accloc_var.account_location_postalcode = map_currentRecords.get(id_var).Apttus_Config2__PostalCode__c;

                    mw_accloc_var.mainwrapper_list = new List<MainWrapper>();
                    mw_accloc_var.per_day_all_accloc = container_zeroes;

                    mw_accloc_var.account_loc_withUnassignedMachines = true;
                    toAdd_mw.add(mw_accloc_var);

                    exist_checker.put(id_var, mw_accloc_var);
                }
            }
        }

        if(showMachineWithoutSchedule){

            for(String id_var : recordId){
                if(
                    (!accLocId_route_map.containsKey(id_var) || (accLocId_route_map.containsKey(id_var) && !accLocId_routeLineItem_map.containsKey(id_var))) && listAccIdWithoutSchedule.contains(id_var)
                    ){
                    
                    //CHECK IF ALREADY EXISTING IN THE LIST ABOVE
                    if(exist_checker.containsKey(id_var)){
                        MainWrapper_AccountLocation cont_var = exist_checker.get(id_var);
                        cont_var.account_loc_withoutSched = true;
                        exist_checker.put(id_var, cont_var);
                        
                    } else {
                        MainWrapper_AccountLocation mw_accloc_var = new MainWrapper_AccountLocation();
                        mw_accloc_var.account_location_id = id_var;
                        mw_accloc_var.account_location_name_total = map_currentRecords.get(id_var).Name;
                        mw_accloc_var.account_location_postalcode = map_currentRecords.get(id_var).Apttus_Config2__PostalCode__c;

                        mw_accloc_var.mainwrapper_list = new List<MainWrapper>();
                        mw_accloc_var.per_day_all_accloc = container_zeroes;

                        mw_accloc_var.account_loc_withoutSched = true;
                        toAdd_mw.add(mw_accloc_var);
                    }
                }
            }
        }

        return toAdd_mw;
    }

    @AuraEnabled
    public static List<MainWrapper_AccountLocation> createContainersNoRoutes (List<String> recordId, Boolean isNordics, String filterType, Boolean showLarge){
        
        //CREATE NEW INSTANCE OF ENTRY FOR IDS NOT IN THE MAPS ABOVE IF FILTER IS ENABLED
        List<MainWrapper_AccountLocation> toAdd_mw = new List<MainWrapper_AccountLocation>();
        Map<Id, Apttus_Config2__AccountLocation__c> map_currentRecords = new Map<Id, Apttus_Config2__AccountLocation__c>();

        //DAY CONTAINER FOR PLACEHOLDER
        List<PerDayTotalObject_AccountLocation> container_zeroes = new List<PerDayTotalObject_AccountLocation>();
        
        if(isNordics){
            for(Integer i = 1; i <= 12; i++){
                PerDayTotalObject_AccountLocation perday_var = new PerDayTotalObject_AccountLocation();
                perday_var.day_num = 0;
                perday_var.total = 0;
                perday_var.total_formatted = '0';
                container_zeroes.add(perday_var);
            }
        } else {
            for(Integer i = 1; i <= 14; i++){
                PerDayTotalObject_AccountLocation perday_var = new PerDayTotalObject_AccountLocation();
                perday_var.day_num = 0;
                perday_var.total = 0;
                perday_var.total_formatted = '0';
                
                String total_count;
                if(filterType == 'all'){                                            
                    if(showLarge){                        
                        total_count = '0c / 0s / 0L';
                    }
                    else {
                        total_count = '0c / 0s';
                    }                                            
                }
                else {
                    total_count = '0c / 0s';
                }   
                
                
                perday_var.total_count = total_count;
                perday_var.total_count_JDE = total_count;
                container_zeroes.add(perday_var);
            }
        }
    
        map_currentRecords = new Map<Id, Apttus_Config2__AccountLocation__c>([SELECT Id, Name, SAP_Customer_ID__c, Apttus_Config2__PostalCode__c FROM Apttus_Config2__AccountLocation__c WHERE Id IN: recordId]);
        for(String id_var : recordId){
            MainWrapper_AccountLocation mw_accloc_var = new MainWrapper_AccountLocation();
            mw_accloc_var.account_location_id = id_var;
            mw_accloc_var.account_location_name_total = map_currentRecords.get(id_var).Name;
            mw_accloc_var.account_location_postalcode = map_currentRecords.get(id_var).Apttus_Config2__PostalCode__c;

            mw_accloc_var.mainwrapper_list = new List<MainWrapper>();
            mw_accloc_var.per_day_all_accloc = container_zeroes;

            mw_accloc_var.account_loc_withUnassignedMachines = true;
            toAdd_mw.add(mw_accloc_var);
        }

        return toAdd_mw;
    }

    private static String formatHHMM (Decimal total){
        String retStr = '0';
        if(total != null && total != 0){

            /* Integer hours = 0; hours = Integer.valueOf(Math.floor(Math.abs(total / 60)));
            Integer mins = 0; mins = Integer.valueOf(Math.ceil(Math.mod(hours, 60) * 60));
            retStr = String.valueOf(hours + 'h' + (mins < 10 ? '0' : '') + mins); */

            Decimal resultingHours = total;
            String HH = String.valueOf(Math.floor(resultingHours));
            String MM = String.valueOf(Math.ceil((resultingHours - Math.floor(resultingHours)) * 60) );

            if(MM == '60'){
                MM = '0';
                HH = String.valueOf(Integer.valueOf(HH) + 1);
            }

            String finaltime = HH + 'h' + MM + 'm';
            retStr = finaltime;
        }

        return retStr;
    }
}