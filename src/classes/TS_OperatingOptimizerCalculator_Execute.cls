/**
* @author        Abram Vixen Reyes
* @date          Nov. 27, 2019
* @description   Execute class of TS_OperatingOptimizerCalculator Batch
* @revision(s)
*/
public without sharing class TS_OperatingOptimizerCalculator_Execute {

    public class LightningResponse{
        @AuraEnabled
        public String returnValue;
        @AuraEnabled
        public String status;
        @AuraEnabled
        public String message;
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
        public List<TaskTypePerDayTotalObject> info_all;
        @AuraEnabled
        public List<PerDayTotalObject> per_day_all;
    }

    public class PerDayTotalObject{
        @AuraEnabled
        public Integer day_num;
        @AuraEnabled
        public Decimal total;
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
        @AuraEnabled
        public Integer total_activities;
    }

    public class AssetPerValueObject{
        @AuraEnabled
        public Id assetId;
        @AuraEnabled
        public Decimal computed_value;
    }
    
    public class BucketizeWrapper{
        public Map<String, String> Buckets; //bucket number, x(y)
        public Integer EOD_Cancel;
        public Integer TTL;     
        public Integer STTL;     
        public Integer S15;     
    }
    
    //TYPE 1.all 2.jde 3.3po
    public static Map<String, Map<Integer, Decimal>> calculateMTTO(List<Apttus_Config2__AccountLocation__c> acc_List, String teamName, Boolean isNordics, String filterType){
    /* public static string getInformation(List<String> recordId, Boolean isRoute, Boolean isOverview, Boolean isOptimizer, Boolean showMachineWithoutSchedule, Boolean showUnassignedMachines, 
                                        List<String> listAccIdUnfiltered, List<String> listAccIdUnassignedMachine, List<String> listAccIdWithoutSchedule){ */
        
        LightningResponse lResponse = new LightningResponse();
        List<MainWrapper> mw_List = new List<MainWrapper>();
        List<MainWrapper_AccountLocation> mw_accLoc_List = new List<MainWrapper_AccountLocation>();
        
        Set<Id> accLoc_no_opSched = new Set<Id>();
        Set<Id> accLoc_no_opSched_nonZero = new Set<Id>();

        Map<Id, List<Route__c>> accLocId_route_map = new Map<Id, List<Route__c>>();
        Map<Id, List<Route_Line_Item__c>> accLocId_routeLineItem_map = new Map<Id, List<Route_Line_Item__c>>();

        List<Route__c> routeToUpdate = new List<Route__c>();
        Map<Id, Route__c> routeToUpdateMap = new Map<Id, Route__c>();
        Map<String, Map<Integer, Decimal>> accLoc_map_total = new Map<String, Map<Integer, Decimal>>();
        Map<String, Map<String, Map<String,Integer>>> JSONMapFinal = new Map<String, Map<String, Map<String,Integer>>>();
        Map<String, Map<String, Decimal>> map_route_day_mtto = new Map<String, Map<String, Decimal>>();
        Map<String, String> accLoc_route_map = new Map<String, String>();
        
        //GET ALL BLANK ROUTES AND FLUSH THE DAY PER ROUTES DATA
        //DOO-3923 Xen Reyes Feb. 25, 2020
        Set<Id> routeId_toFlush = new Set<Id>();

        try {
            //INITIALIZE DMLS
            Map<Id, Route__c> map_route = new Map<Id, Route__c>();
            map_route = new Map<Id, Route__c>([SELECT Id, Name, Unique_Route_Number__c, Preferred_Operator__c, Has_Stock_Location__c, Account_Location__c, Account_Location__r.Name, Account_Location__r.Apttus_Config2__PostalCode__c, Account_Location__r.Second_Account_Name__c, Account_Location__r.SAP_Customer_ID__c, Account_Location__r.MTTOLocationSpecific__c, Account_Location__r.MTTTWithinSite__c, Account_Location__r.AverageRoutePrep__c, Day1__c, Day2__c, Day3__c, Day4__c, Day5__c, Day6__c, Day7__c, Day8__c, Day9__c, Day10__c, Day11__c, Day12__c, Day13__c, Day14__c, Nordics_1__c, Nordics_2__c, Nordics_3__c, Nordics_4__c, Nordics_5__c, Nordics_6__c, Nordics_7__c, Nordics_8__c, Nordics_9__c, Nordics_10__c, Nordics_11__c, Nordics_12__c  FROM Route__c WHERE Account_Location__c IN: acc_List]);
            
            List<Route_Line_Item__c> list_rli = [SELECT Id, RouteId__c, PhysicalAssetId__c, PhysicalAssetId__r.Product__c, PhysicalAssetId__r.SalesOrganization__c, PhysicalAssetId__r.AccountLocation__C, PhysicalAssetId__r.AccountLocation__r.Third_Party_Resource__c
                                                 FROM Route_Line_Item__c WHERE RouteId__c IN: map_route.keySet() ORDER BY PhysicalAssetId__r.AccountLocation__r.Apttus_Config2__PostalCode__c ASC];
            
            Set<String> set_salesOrg = new Set<String>(); 
            DescribeSObjectResult opsched_describe = OperatingSchedule__c.getSObjectType().getDescribe();
            List<String> fields = new List<String>(opsched_describe.fields.getMap().keySet());
            Map<Id, Id> map_asset_product = new Map<Id, Id>();
            for(Route_Line_Item__c rli_var : list_rli){
                if(rli_var.PhysicalAssetId__c != null){
                    map_asset_product.put(rli_var.PhysicalAssetId__c, rli_var.PhysicalAssetId__r.Product__c);
                    set_salesOrg.add(rli_var.PhysicalAssetId__r.SalesOrganization__c);
                }
            }
                        
            Set<Id> set_id = map_asset_product.keySet();                                    
            String DEFAULT_SOQL = 'SELECT ' + String.join(fields, ',') +
                ', PhysicalAsset__r.Product__c,  PhysicalAsset__r.SalesOrganization__c, PhysicalAsset__r.AccountLocation__c' +
                ', PhysicalAsset__r.Building__c,PhysicalAsset__r.AccountLocation__r.SAP_Customer_ID__c,PhysicalAsset__r.Floor__c' +
                ', PhysicalAsset__r.SoldTo__c, PhysicalAsset__r.OP_PreferredOperator__c, PhysicalAsset__r.MothballAssetIndicator__c, PhysicalAsset__r.Machine_Care__c' +
                ', PhysicalAsset__r.CounterReading__c, PhysicalAsset__r.Connected__c' +
                ', PhysicalAsset__r.AssetStatus__c' +                            
                ', Account_Location__r.Apttus_Config2__AccountId__c' +
                ', Account_Location__r.MTTOLocationSpecific__c' +
                ', Account_Location__r.MTTTWithinSite__c' +
                ', Account_Location__r.AverageRoutePrep__c' +
                ', Account_Location__r.Mini_Sales_Organization__c' +               
                ' FROM ' + opsched_describe.getName() +
                ' WHERE OperatingReady__c = true ' +                            
                ' AND PhysicalAsset__c IN: set_id ' ;

            List<OperatingSchedule__c> list_opsched = new List<OperatingSchedule__c>();
            list_opsched = database.query(DEFAULT_SOQL);
                        
            List<PricebookEntry> list_pbEntry = new List<PricebookEntry>();
            list_pbEntry = [SELECT Id, Product2Id, Pricebook2Id, Pricebook2.IsStandard, ProductCode, Sales_Organization__c , MeanTimeToOperateC__c, MeanTimeToOperateLM__c, MeanTimeToOperateSM__c, MTTO_MCO_Bottles__c, MTTO_MCO_Descaling__c, MTTO_MCO_Ingredients__c, MTTO_MCO_Large__c, MTTO_MCO_PM__c, MTTO_MCO_Waterfilter__c FROM PricebookEntry WHERE Product2Id IN: map_asset_product.values() AND Sales_Organization__c IN: set_salesOrg AND Pricebook2.IsStandard != true AND Sales_Organization__c != null];
            
            List<String> recTypesSet = new List<String>{'Operating Task', 'Machine Clean Operating PM Rules'};
            List<CountrySetting__c> cList = [SELECT Country__c, DefaultStartTime__c, DefaultEndTime__c, Business_Hours__c, From__c, To__c, RecordType.Name FROM CountrySetting__c WHERE Active__c = true AND RecordType.Name IN: recTypesSet];

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
            
            //DOO-5170 Francis Allen Alindogan 03/17/2021            
            if(!map_route.isEmpty()){
                Set<String> existingAccountLocation = new Set<String>();
                for(Route__c rs_var : map_route.values()){
                    if(!existingAccountLocation.contains(rs_var.Account_Location__c)){
                        accLoc_route_map.put(rs_var.Account_Location__c , rs_var.Id); 
                        existingAccountLocation.add(rs_var.Account_Location__c);          
                    }
                }
            }
            
            TS_Feature_Flag__mdt featureFlagBucketizeActuals =  [SELECT Id, QualifiedApiName, Enable__c FROM TS_Feature_Flag__mdt WHERE QualifiedApiName = 'DOO_5170_Enable_Bucketize_Actuals_Month'];
            List<WorkOrderLineItem> list_woli = new List<WorkOrderLineItem>();
            if(featureFlagBucketizeActuals.Enable__c == true || Test.isRunningTest() == true ){
            	list_woli = [SELECT Id, JDELineItemNumber__c, WorkOrderType__c, EndDate__c, Operating_Bucket__c, WorkOrderLineItemType__c, Status, OP_CancelationReasonMachine__c, AccountLocation__r.Third_Party_Resource__c, AccountLocation__r.Third_Party_Resource__r.RLS_Portal_User__c, Case__r.SendTo3rdParty__c FROM WorkOrderLineItem WHERE 
                             ( (WorkOrderType__c =:TS_Constants.WO_TYPE_S20_MACHINECARE AND (Status =:TS_Constants.STATUS_COMPLETED OR Status =:TS_Constants.STATUS_CANCELED) AND Operating_Bucket__c != null) OR
                               (WorkOrderType__c =:TS_Constants.CASE_SUBTYPE_1STLINECORRECTMAINTAPI AND Status =:TS_Constants.STATUS_COMPLETED) ) 
                             AND EndDate__c != null AND(EndDate__c = THIS_YEAR OR (CALENDAR_MONTH(EndDate__c) = 1 AND EndDate__c = NEXT_YEAR)) AND AccountLocation__c IN: acc_List];    
            }         
                                                                        
            Integer loop_counter = 1;
            //IF TYPE IS ALL LOOP 2 TIMES TO GET ALL + JDE ONLY
            if(filterType == 'all' && isNordics == false){
                loop_counter = 2;                
            }            

            for(Integer ctr = 1; ctr <= loop_counter; ctr++){

                 //IF ALL IS SLECTED, FIRST RUN OF LOOP IS FOR ALL, SECOND RUN IS FOR JDE
                 if(filterType == 'all' && ctr == 2 && isNordics == false){
                    filterType = 'jde';    
                    //FLUSH THE EXISTING MAPS FOR THE 2ND RUN
                    JSONMapFinal = new Map<String, Map<String, Map<String,Integer>>>();
                    map_route_day_mtto = new Map<String, Map<String, Decimal>>();
                }
                                
                System.debug('FilterType: ' + filterType);
                System.debug('map_route: ' + map_route); 

                //GET ALL ROUTES
                if(!map_route.isEmpty()){
                    
                    //GET ACCOUNT LOCATION WITHOUT ROUTE
                    for(Route__c rs_var : map_route.values()){
                        if(accLocId_route_map.containsKey(rs_var.Account_Location__c)){
                            accLocId_route_map.get(rs_var.Account_Location__c).add(rs_var);
                        } else {
                            accLocId_route_map.put(rs_var.Account_Location__c, new List<Route__c>{rs_var});
                        }
                    }
                    
                    //Map<Route__c, Map<String,Map<Integer, AssetPerDayTotalObject>>> map_route_type_day_calc = new Map<Route__c, Map<String,Map<Integer, AssetPerDayTotalObject>>>();
                    Map<Id, Map<String, PricebookEntry>> map_prodId_map_SalesOrgPbEntry = new Map<Id, Map<String, PricebookEntry>>();
                    Map<Id, List<Route_Line_Item__c>> map_routeId_listRLI = new Map<Id, List<Route_Line_Item__c>>();
                    Map<Id, Set<Id>> map_route_setAssetId = new Map<Id, Set<Id>>();
                    Map<Id, OperatingSchedule__c> map_assetId_opsched = new Map<Id, OperatingSchedule__c>();                    
                    Map<Id, String> map_assetId_salesOrg = new Map<Id, String>();                                                            
                    Set<String> set_pa_thirdParty = new Set<String>();                                                        
                    Set<String> set_task_types = new Set<String>{'LM', 'SM', 'C'};
                    Map<String, String> set_task_types_map = new Map<String, String>{'LM' => 'LARGE', 'SM' => 'SMALL', 'C' => 'CUPS'};
                        
                    //REMOVE LARGE IF 3PO
                    if(filterType == '3po'){
                        set_task_types.remove('LM');
                        set_task_types_map.remove('LM');
                    }
                                             
                    Set<String> set_weeknum = new Set<String>{'1', '2'};
                    Set<String> set_day = new Set<String>{'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'};
                    Set<String> set_task_types_nordics = new Set<String>{'Bottle_Months__c', 'Descaling_Months__c', 'Ingredients_Months__c', 'L_Months__c', 'PM_Months__c', 'Waterfilter_Months__c'};
                    Map<String, String> opSchedToPbEntryMap = new Map<String, String>{  'Bottle_Months__c' => 'MTTO_MCO_Bottles__c', 
                                                                                        'Descaling_Months__c' => 'MTTO_MCO_Descaling__c', 
                                                                                        'Ingredients_Months__c' => 'MTTO_MCO_Ingredients__c', 
                                                                                        'L_Months__c' => 'MTTO_MCO_Large__c',
                                                                                        'PM_Months__c' => 'MTTO_MCO_PM__c',
                                                                                        'Waterfilter_Months__c' => 'MTTO_MCO_Waterfilter__c'};
                    Map<String, Integer> dayNameToDayNumberMap = new Map<String,Integer>{   'Monday' => 1,
                                                                                            'Tuesday' => 2, 
                                                                                            'Wednesday' => 3, 
                                                                                            'Thursday' => 4, 
                                                                                            'Friday' => 5, 
                                                                                            'Saturday' => 6, 
                                                                                            'Sunday' => 7
                                                                                        };
                    Map<String, Map<String, Map<String,Integer>>> routeIdToTaskJSONMap = new Map<String, Map<String, Map<String,Integer>>>();
                    Map<String, Map<String, Integer>> routePAToTaskJSONMap = new Map<String, Map<String, Integer>>();                    

                    if(!list_rli.isEmpty()){
                        
                        System.debug('list_rli: ' + list_rli); 

                        //CREATE MAP - ROUTE TO ROUTE LINE ITEM                        
                        for(Route_Line_Item__c rli_var : list_rli){

                            if(map_route_setAssetId.containsKey(rli_var.RouteId__c)){
                                map_route_setAssetId.get(rli_var.RouteId__c).add(rli_var.PhysicalAssetId__c);
                            } else {
                                map_route_setAssetId.put(rli_var.RouteId__c, new Set<Id>{rli_var.PhysicalAssetId__c});
                            }

                            //CREATE MAP - PA TO 3PO OR NOT
                            if(rli_var.PhysicalAssetId__r.AccountLocation__r.Third_Party_Resource__c != null){                                
                                set_pa_thirdParty.add(rli_var.PhysicalAssetId__c);
                            }
                                                            
                            System.debug('rli_var: ' + rli_var);
                            
                            if(rli_var.PhysicalAssetId__c != null){
                                set_salesOrg.add(rli_var.PhysicalAssetId__r.SalesOrganization__c);
                                map_asset_product.put(rli_var.PhysicalAssetId__c, rli_var.PhysicalAssetId__r.Product__c);
                                map_assetId_salesOrg.put(rli_var.PhysicalAssetId__c, rli_var.PhysicalAssetId__r.SalesOrganization__c);

                                //GET ACCOUNT LOCATION WITHOUT ROUTE LINE ITEM - For filtering
                                if(accLocId_routeLineItem_map.containsKey(rli_var.PhysicalAssetId__r.AccountLocation__C)){
                                    accLocId_routeLineItem_map.get(rli_var.PhysicalAssetId__r.AccountLocation__C).add(rli_var);
                                } else {
                                    accLocId_routeLineItem_map.put(rli_var.PhysicalAssetId__r.AccountLocation__C, new List<Route_Line_Item__c>{rli_var});
                                }
                            }
                        }

                        //GET ALL OPERATING SCHEDULE
                        if(!map_asset_product.keySet().isEmpty()){

                            //System.debug(DEFAULT_SOQL);                       
                            if(!list_opsched.isEmpty()){
                                for(OperatingSchedule__c ops_var : list_opsched){
                                    if(!map_assetId_opsched.containsKey(ops_var.PhysicalAsset__c)){
                                        map_assetId_opsched.put(ops_var.PhysicalAsset__c, ops_var);
                                    }
                                }
                                                
                                //GET ALL PRICEBOOK ENTRIES
                                if(!map_asset_product.values().isEmpty()){
                                                                                                                            
                                    //CREATE A PRODUCT - SALES ORGANIZATION - PRICEBOOKENTRY MAP
                                    if(!list_pbEntry.isEmpty()){
                                        for(PricebookEntry pbe_var : list_pbEntry){
                                            if(map_prodId_map_SalesOrgPbEntry.containsKey(pbe_var.Product2Id)){
                                                if(!map_prodId_map_SalesOrgPbEntry.get(pbe_var.Product2Id).containsKey(pbe_var.Sales_Organization__c)){
                                                    map_prodId_map_SalesOrgPbEntry.get(pbe_var.Product2Id).put(pbe_var.Sales_Organization__c, pbe_var);
                                                }
                                            } else {
                                                map_prodId_map_SalesOrgPbEntry.put(pbe_var.Product2Id, new Map<String, PricebookEntry>{pbe_var.Sales_Organization__c => pbe_var});
                                            }
                                        }
                                    }
                                }
                                
                                //GET COUNTRY SETTINGS RULE - PM OPERATING RULE FOR NORDICS
                                Map<String, CountrySetting__c> countrySettingMap_Operating = new Map<String, CountrySetting__c>();
                                Map<String, CountrySetting__c> countrySettingMap_PMRule = new Map<String, CountrySetting__c>();
                                                                
                                if(!cList.isEmpty()){
                                    for(CountrySetting__c cset : cList){
                                        if(cset.RecordType.Name == 'Operating Task') {
                                            countrySettingMap_Operating.put(cset.Country__c, cset);
                                        }
                                        if(cset.RecordType.Name == 'Machine Clean Operating PM Rules') {
                                            countrySettingMap_PMRule.put(cset.Country__c, cset);
                                        }
                                    }
                                }
                                
                                //FORM THE WRAPPER CLASS & CALCULATION (LARGE, SMALL, CUPS)
                                for(Id route_var : map_route.keySet()){
                                    
                                    //Map<String,Map<Integer, AssetPerDayTotalObject>> map_taskResult = new Map<String,Map<Integer, AssetPerDayTotalObject>>();
                                    MainWrapper mw = new MainWrapper();
                                    List<TaskTypePerDayTotalObject> task_type_list = new List<TaskTypePerDayTotalObject>();
        
                                    if(!isNordics){
                                        for(String tasktype_var : set_task_types){

                                            //Map<Integer, AssetPerDayTotalObject> map_dayResult = new Map<Integer, AssetPerDayTotalObject>();
                                            TaskTypePerDayTotalObject task_per_day_var = new TaskTypePerDayTotalObject();
                                            List<AssetPerDayTotalObject> asset_per_day_list = new List<AssetPerDayTotalObject>();
                                            String api_name_mtto = 'MeanTimeToOperate' + tasktype_var + '__c';
                                            Integer counter = 1;

                                            Map<String,Integer> LTask = new Map<String,Integer>{'day_1' => 0, 'day_2' => 0, 'day_3' => 0, 'day_4' => 0, 'day_5' => 0, 'day_6' => 0, 'day_7' => 0, 'day_8' => 0, 'day_9' => 0, 'day_10' => 0, 'day_11' => 0, 'day_12' => 0, 'day_13' => 0, 'day_14' => 0};
                                            Map<String,Integer> STask = new Map<String,Integer>{'day_1' => 0, 'day_2' => 0, 'day_3' => 0, 'day_4' => 0, 'day_5' => 0, 'day_6' => 0, 'day_7' => 0, 'day_8' => 0, 'day_9' => 0, 'day_10' => 0, 'day_11' => 0, 'day_12' => 0, 'day_13' => 0, 'day_14' => 0};
                                            Map<String,Integer> CTask = new Map<String,Integer>{'day_1' => 0, 'day_2' => 0, 'day_3' => 0, 'day_4' => 0, 'day_5' => 0, 'day_6' => 0, 'day_7' => 0, 'day_8' => 0, 'day_9' => 0, 'day_10' => 0, 'day_11' => 0, 'day_12' => 0, 'day_13' => 0, 'day_14' => 0};

                                            for(String weeknum_var : set_weeknum){
                                                for(String day_var : set_day){

                                                    //Map<Id, Integer> map_assetResult = new Map<Id, Integer>();
                                                    AssetPerDayTotalObject asset_per_day_var = new AssetPerDayTotalObject();
                                                    List<AssetPerValueObject> asset_per_value_list = new List<AssetPerValueObject>();
                                                    
                                                    Decimal total_day = 0.0;
                                                    Integer total_activity_day = 0;
                                                    
                                                    //DOO-3923 Xen Reyes Feb. 25, 2020
                                                    if(!map_route_setAssetId.containsKey(route_var)){
                                                        routeId_toFlush.add(route_var);
                                                        continue;
                                                    }
                                                                                                                                     
                                                    for(Id pa_var : map_route_setAssetId.get(route_var)){
                                                    
                                                        //SKIP S AND C IF JDE ONLY AND HAS THIRD PARTY
                                                        if(set_pa_thirdParty.contains(pa_var) && filterType == 'jde' && (tasktype_var == 'SM' || tasktype_var == 'C')){
                                                            continue;
                                                        }
                                      
                                                        AssetPerValueObject asset_per_value_var = new AssetPerValueObject(); //INSTANTIATE WRAPPER CLASS

                                                        if(!map_assetId_opsched.containsKey(pa_var)){                                                        
                                                            continue;
                                                        }
                                                        OperatingSchedule__c op_var = map_assetId_opsched.get(pa_var); //GET THE OPERATING SCHEDULE TO EVALUATE
                                                        PricebookEntry pbe_var = new PricebookEntry();
                                                        if(map_asset_product.containsKey(pa_var)){
                                                            if( map_prodId_map_SalesOrgPbEntry.containsKey(map_asset_product.get(pa_var))){
                                                                if(map_assetId_salesOrg.containsKey(pa_var)){
                                                                    if(map_prodId_map_SalesOrgPbEntry.get(map_asset_product.get(pa_var)).containsKey(map_assetId_salesOrg.get(pa_var))){
                                                                        pbe_var = map_prodId_map_SalesOrgPbEntry.get(map_asset_product.get(pa_var)).get(map_assetId_salesOrg.get(pa_var)); //GET THE PRICEBOOK ENTRY TO EVALUATE
                                                                    } else continue;
                                                                } else continue;
                                                            } else continue;
                                                        } else continue;
                                                        
                                                        String api_name_opsched = tasktype_var + '_' + weeknum_var + '_' + day_var + '__c';                                                                                                     
                                                        if(op_var.get(api_name_opsched) != null && op_var.get(api_name_opsched) != '0'){

                                                            Integer op_var_value = 0;
                                                            if(op_var.get(api_name_opsched) == 'AM' || op_var.get(api_name_opsched) == 'PM'){
                                                                op_var_value = 1;
                                                            } else {
                                                                op_var_value = Integer.valueOf(op_var.get(api_name_opsched));
                                                            }
                                                            
                                                            //GET THE MTTO IN PRICEBOOK ENTRY
                                                            Decimal mtto_pbentry_value = 0;
                                                            if(pbe_var.get(api_name_mtto) == null){
                                                                mtto_pbentry_value = 0;
                                                            } else {
                                                                mtto_pbentry_value = Decimal.valueOf(String.valueOf(pbe_var.get(api_name_mtto)));
                                                            }
                                                            
                                                            //GET THE MTTO LOCATION SPECIFIC IN ACCOUNT LOCATION
                                                            Decimal mtto_accloc_locationspecific = 0;
                                                            if(op_var.Account_Location__r.MTTOLocationSpecific__c == null){
                                                                mtto_accloc_locationspecific = 0;
                                                            } else {
                                                                mtto_accloc_locationspecific = op_var.Account_Location__r.MTTOLocationSpecific__c;
                                                            }
                                                            
                                                            //GET THE MTTO WITHIN SITE IN ACCOUNT LOCATION
                                                            /* Decimal mtto_accloc_withinsite = 0;
                                                            if(op_var.Account_Location__r.MTTTWithinSite__c == null){
                                                                mtto_accloc_withinsite = 0;
                                                            } else {
                                                                mtto_accloc_withinsite = op_var.Account_Location__r.MTTTWithinSite__c;
                                                            } */

                                                            //GET THE ACCOUNT LOCATION AVERAGE ROUTE PREPARATION TIME
                                                            /* Decimal mtto_accloc_aveRoutePrep = 0;
                                                            if(op_var.Account_Location__r.AverageRoutePrep__c == null){
                                                                mtto_accloc_aveRoutePrep = 0;
                                                            } else {
                                                                mtto_accloc_aveRoutePrep = op_var.Account_Location__r.AverageRoutePrep__c;
                                                            } */
                                                            
                                                            //GET THE DURATION PER CALL TYPE
                                                            Decimal perCallType = 0;
                                                            if(map_woType_country_mttoCallType.containsKey('S20')){
                                                                if(map_woType_country_mttoCallType.get('S20').containsKey(op_var.Account_Location__r.Mini_Sales_Organization__c)){
                                                                    perCallType = map_woType_country_mttoCallType.get('S20').get(op_var.Account_Location__r.Mini_Sales_Organization__c) != null ? map_woType_country_mttoCallType.get('S20').get(op_var.Account_Location__r.Mini_Sales_Organization__c) : 0 ;
                                                                }
                                                            }
                                                            
                                                            //ACTUAL CALCULATION CONSIDERING ALL MEAN TIME VALUES
                                                            Decimal result_mtto = (op_var_value * (mtto_pbentry_value + mtto_accloc_locationspecific + perCallType));

                                                            //System.debug('op_var_value: ' + op_var_value);
                                                            //System.debug('mtto_pbentry_value: ' + mtto_pbentry_value);
                                                            //System.debug('mtto_accloc_locationspecific: ' + mtto_accloc_locationspecific);
                                                            //System.debug('perCallType: ' + perCallType);

                                                            //+ mtto_accloc_aveRoutePrep + mtto_accloc_withinsite
                                                            //map_assetResult.put(pa_var, result_mtto);
                                                            
                                                            asset_per_value_var.computed_value = result_mtto;
                                                            total_day = total_day + result_mtto;
                                                            total_activity_day = total_activity_day + op_var_value;

                                                            //System.debug('total_day: ' + total_day);
                                                            //System.debug('total_activity_day: ' + total_activity_day);

                                                            //asset_per_value_var.number_of_visit = op_var_value;
                                                            //asset_per_value_var.mtto_pbentry = mtto_pbentry_value;
                                                            //asset_per_value_var.mt_accloc_location = mtto_accloc_locationspecific;
                                                            //asset_per_value_var.mt_accloc_site = mtto_accloc_withinsite;
                                                            //asset_per_value_var.mt_accloc_averagePrep = mtto_accloc_aveRoutePrep; 
                                                                                                                    
                                                            //DOO-5181 SAVE JSON STRING       
                                                            if(weeknum_var != null && dayNameToDayNumberMap.get(day_var)!= null){                                                        
                                                                Integer dayCount = Integer.valueOf(dayNameToDayNumberMap.get(day_var));   
                                                                if(Integer.valueOf(weeknum_var) == 2 ){
                                                                    dayCount = dayCount+7;
                                                                }
                                                                String dayCountKey = 'day_' + dayCount;                                                                                                                                              
                                                                String comboKey = route_var+'_'+pa_var+'-'+tasktype_var;                                                        
                                                                if(routePAToTaskJSONMap.containsKey(comboKey)){
                                                                    routePAToTaskJSONMap.get(comboKey).put(dayCountKey, Integer.valueOf(op_var.get(api_name_opsched)));
                                                                }
                                                                else {                                              
                                                                    Map<String, Integer> dayValuePlaceholder = new Map<String, Integer>{ dayCountKey => Integer.valueOf(op_var.get(api_name_opsched)) };
                                                                    routePAToTaskJSONMap.put(comboKey, dayValuePlaceholder);                                                                                                                         
                                                                }
                                                                /*
                                                                if(dayCountKey != null && dayCount != 0){                                                             
                                                                    if(tasktype_var == 'LM'){
                                                                        LTask.put(dayCountKey, Integer.valueOf(op_var.get(api_name_opsched)));
                                                                    }
                                                                    else if(tasktype_var == 'SM'){
                                                                        STask.put(dayCountKey, Integer.valueOf(op_var.get(api_name_opsched)));
                                                                    }
                                                                    else if(tasktype_var == 'C'){
                                                                        CTask.put(dayCountKey, Integer.valueOf(op_var.get(api_name_opsched)));
                                                                    }
                                                                }      
                                                                */
                                                            }   
                                                            
                                                            /*
                                                            Map<String, Map<String,Integer>> opschedJSONMap = new Map<String, Map<String,Integer>>();    
                                                            if(tasktype_var == 'LM'){
                                                                opschedJSONMap.put('Large',LTask);                                                    
                                                            }
                                                            else if(tasktype_var == 'SM'){
                                                                opschedJSONMap.put('Small',STask);               
                                                            }
                                                            else if(tasktype_var == 'C'){
                                                                opschedJSONMap.put('Cups',CTask);                
                                                            }                                                           
                                                            
                                                            routeIdToTaskJSONMap.put(route_var+'_'+pa_var+'-'+tasktype_var, opschedJSONMap);     
                                                            */
                                                        } 
                                                        else {
                                                            Integer dayCount = Integer.valueOf(dayNameToDayNumberMap.get(day_var));   
                                                            if(Integer.valueOf(weeknum_var) == 2 ){
                                                                dayCount = dayCount+7;
                                                            }
                                                            String dayCountKey = 'day_' + dayCount;
                                                            String comboKey = route_var+'_'+pa_var+'-'+tasktype_var;                                                        
                                                            if(routePAToTaskJSONMap.containsKey(comboKey)){
                                                                routePAToTaskJSONMap.get(comboKey).put(dayCountKey, 0);
                                                            }
                                                            else {                                                            
                                                                Map<String, Integer> dayValuePlaceholder = new Map<String, Integer>{ dayCountKey => 0 };
                                                                routePAToTaskJSONMap.put(comboKey, dayValuePlaceholder);                                                              
                                                            }
                                                            //map_assetResult.put(pa_var, 0);
                                                            asset_per_value_var.computed_value = 0;
                                                        }                                                                                                                            
                                                    }
                                                                                                                                                                                                                                                                                                                                    
                                                    //map_dayResult.put(counter, asset_obj);
                                                    asset_per_day_var.asset_per_value_list_wrapper = asset_per_value_list;

                                                    //Decimal total_holder = (total_day / 60);
                                                    //asset_per_day_var.total =  total_holder.setscale(2);
                                                    asset_per_day_var.total =  total_day;
                                                    asset_per_day_var.day_num = counter;
                                                    asset_per_day_var.total_activities = total_activity_day;
                                                    asset_per_day_list.add(asset_per_day_var);
                                                    counter++;
                                                }//END OF DAY LOOP
                                            }//END OF WEEK LOOP                                        
                                            //map_taskResult.put(tasktype_var,map_dayResult);
                                            task_per_day_var.asset_per_day_list_wrapper = asset_per_day_list;
                                            task_per_day_var.tasktype = set_task_types_map.get(tasktype_var);
                                            task_type_list.add(task_per_day_var);                                        
                                        }//END LOOP OF TASK TYPES                                        
                                    } 
                                    else {

                                        for(String tasktype_var : set_task_types_nordics){

                                            //Map<Integer, AssetPerDayTotalObject> map_dayResult = new Map<Integer, AssetPerDayTotalObject>();
                                            TaskTypePerDayTotalObject task_per_day_var = new TaskTypePerDayTotalObject();
                                            List<AssetPerDayTotalObject> asset_per_day_list = new List<AssetPerDayTotalObject>();
                                            String api_name_mtto = opSchedToPbEntryMap.get(tasktype_var);
                                            Integer counter = 1;

                                            //for(String day_var : set_day){                                        
                                            for(Integer i = 1; i <= 12; i++){

                                                //Map<Id, Integer> map_assetResult = new Map<Id, Integer>();
                                                AssetPerDayTotalObject asset_per_day_var = new AssetPerDayTotalObject();
                                                List<AssetPerValueObject> asset_per_value_list = new List<AssetPerValueObject>();
                                                
                                                Decimal total_day = 0.0;
                                                Integer total_activity_day = 0;
                                                
                                                //DOO-3923 Xen Reyes Feb. 25, 2020
                                                if(!map_route_setAssetId.containsKey(route_var)){
                                                    routeId_toFlush.add(route_var);
                                                    continue;
                                                }

                                                for(Id pa_var : map_route_setAssetId.get(route_var)){

                                                    AssetPerValueObject asset_per_value_var = new AssetPerValueObject(); //INSTANTIATE WRAPPER CLASS

                                                    //SCENARIO 1 TO SKIP
                                                    if(!map_assetId_opsched.containsKey(pa_var)) continue; //NO OR INVALID OPERATING SCHEDULE
                                                    
                                                    OperatingSchedule__c op_var = map_assetId_opsched.get(pa_var); //GET THE OPERATING SCHEDULE TO EVALUATE

                                                    //SCENARIO 2 TO SKIP
                                                    if(tasktype_var == 'L_Months__c' && (op_var.FrequencyofL__c == null || op_var.FrequencyofL__c == 'N/A')) continue; //IF LARGE AND NO APPLICABLE CALCULATIONS
                                                    
                                                    Boolean toCalculate = false;
                                                    Double weeks = 52.0;

                                                    //CHECKING VALUES IN THE OPERATING SCHEDULE (FOR MONTHLY)
                                                    String api_name_opsched = tasktype_var;
                                                    Set<String> fieldVal = new Set<String>();
                                                    if(op_var.get(api_name_opsched) != null) fieldVal.addAll(String.valueOf(op_var.get(api_name_opsched)).split(';'));

                                                    //AVERAGE VISIT PER MONTH - INITIATE VALUE HERE
                                                    Decimal aveLargePerMonth = 0.0;

                                                    //SCENARIO 1: LARGE - WEEKLY - SPECIFIC DAYS IN A WEEK = FALSE
                                                    if(tasktype_var == 'L_Months__c' && op_var.FrequencyofL__c == 'Weekly' && op_var.Specific_Days_in_Week__c == false){
                                                        if(Integer.valueOf(op_var.Interval_in_Weeks__c) > 0) {
                                                            aveLargePerMonth = weeks / (12 * (Integer.valueOf(op_var.Interval_in_Weeks__c)));
                                                            toCalculate = true;
                                                        }
                                                    }  

                                                    //SCENARIO 2: LARGE - WEEKLY - SPECIFIC DAYS IN A WEEK = TRUE
                                                    else if(tasktype_var == 'L_Months__c' && op_var.FrequencyofL__c == 'Weekly' && op_var.Specific_Days_in_Week__c == true){
                                                        
                                                        //GET HOW MANY 1s IN THE LARGE FIELDS
                                                        Integer visitPerWeek = 0;
                                                        for(String str_var : set_day){
                                                            String apiName = 'LM_1_' + str_var + '__c';
                                                            if(op_var.get(apiName) == '1') visitPerWeek = visitPerWeek + 1;
                                                        }

                                                        if(Integer.valueOf(op_var.Interval_in_Weeks__c) > 0){
                                                            aveLargePerMonth = (weeks / (12 * (Integer.valueOf(op_var.Interval_in_Weeks__c)))) * visitPerWeek;
                                                            toCalculate = true;
                                                        }
                                                    }

                                                    //SCENARIO 3: LARGE - DAILY
                                                    else if(tasktype_var == 'L_Months__c' && op_var.FrequencyofL__c == 'Daily'){
                                                        
                                                        Integer numberDays = date.daysInMonth(Date.today().year(), i);
                                                        Integer totalVisits = 0;
                                                        Integer endhour =  countrySettingMap_Operating.get(op_var.Sales_Organization__c).DefaultEndTime__c == null ? 17 : Integer.valueOf(countrySettingMap_Operating.get(op_var.Sales_Organization__c).DefaultEndTime__c);

                                                        //ITERATE ALL DAYS WITHIN THE MONTH
                                                        for(Integer x = 1; x <= numberDays; x++){
                                                            
                                                            Boolean isWithinBusinessHour = BusinessHours.isWithin(countrySettingMap_Operating.get(op_var.Sales_Organization__c).Business_Hours__c, DateTime.newInstance(Date.today().year(), i, x,endhour-1, 59, 59));
                                                        
                                                            if(isWithinBusinessHour || op_var.Schedule_Tasks_for_Holiday__c == true) totalVisits++;
                                                            if(totalVisits != 0){
                                                                aveLargePerMonth = Decimal.valueOf(totalVisits);
                                                                toCalculate = true;
                                                            }   
                                                        }                                                    
                                                    }

                                                    //SCENARIO 4: IF PM AND THERE IS A MOVEMENT
                                                    else if(tasktype_var == 'PM_Months__c' && op_var.FrequencyofL__c == 'Monthly'){
                                                        
                                                        //SCENARIO 4.1: CHECK IF THERE IS MCO PM RULE
                                                        if(countrySettingMap_PMRule.containsKey(op_var.Sales_Organization__c)){
                                                            
                                                            Boolean check_TO = countrySettingMap_PMRule.get(op_var.Sales_Organization__c).To__c == String.valueOf(i) ? true : false;
                                                            Boolean check_FROM = countrySettingMap_PMRule.get(op_var.Sales_Organization__c).From__c == String.valueOf(i) ? true : false;
                                                            
                                                            //THIS HAS BEEN MOVED TO EARLIER MONTH
                                                            if(check_FROM) continue;

                                                            //CHECK IF PM OF OPSCHED AND 'TO' FIELD HAS A MATCH
                                                            Boolean checkPMfromMonth = false;
                                                            String PMfromMonth = countrySettingMap_PMRule.get(op_var.Sales_Organization__c).From__c;
                                                            if(op_var.get('PM_Months__c') != null) checkPMfromMonth = String.valueOf(op_var.get('PM_Months__c')).contains(PMfromMonth) ? true : false;

                                                            //PERFORM CALCULATION MOVEMENT
                                                            if(check_TO && checkPMfromMonth){
                                                                toCalculate = true;
                                                                aveLargePerMonth = 1.0;
                                                            }
                                                        
                                                        //SCENARIO 4.2: NO PM RULE - REGULAR MONTHLY CALCULATE
                                                        } else if(op_var.get(api_name_opsched) != null && fieldVal.contains(String.valueOf(i))) {
                                                            toCalculate = true;
                                                            aveLargePerMonth = 1.0;
                                                        }
                                                    }
                                                        
                                                    //SCENARIO 5: IF WF /LARGE MONTHLY AND THERE IS A MOVEMENT WITH PM
                                                    else if((tasktype_var == 'Waterfilter_Months__c' || tasktype_var == 'L_Months__c') && op_var.FrequencyofL__c == 'Monthly'){
                                                        
                                                        //SCENARIO 5.1: CHECK IF THERE IS MCO PM RULE AND THERE IS A PM FOR THIS MONTH
                                                        if(countrySettingMap_PMRule.containsKey(op_var.Sales_Organization__c)){
                                                            
                                                            //CHECK IF PM OF OPSCHED AND 'TO' FIELD HAS A MATCH
                                                            Boolean checkPMfromMonth = false;
                                                            Boolean checkWFfromMonth = false;
                                                            Boolean checkLMfromMonth = false;
                                                            String PMfromMonth = countrySettingMap_PMRule.get(op_var.Sales_Organization__c).From__c;
                                                            if(op_var.get('PM_Months__c') != null) checkPMfromMonth = String.valueOf(op_var.get('PM_Months__c')).contains(PMfromMonth) ? true : false;
                                                            if(op_var.get('Waterfilter_Months__c') != null) checkWFfromMonth = String.valueOf(op_var.get('Waterfilter_Months__c')).contains(PMfromMonth) ? true : false;
                                                            if(op_var.get('L_Months__c') != null) checkLMfromMonth = String.valueOf(op_var.get('L_Months__c')).contains(PMfromMonth) ? true : false;

                                                            if(checkPMfromMonth){
                                                                Boolean check_TO = countrySettingMap_PMRule.get(op_var.Sales_Organization__c).To__c == String.valueOf(i) ? true : false;
                                                                Boolean check_FROM = countrySettingMap_PMRule.get(op_var.Sales_Organization__c).From__c == String.valueOf(i) ? true : false;

                                                                //WHEN THE WF TASK HAS BEEN MOVED TO ANOTHER MONTH
                                                                if(check_FROM) continue;
            
                                                                //WHEN THE WF CALCULATION SHOULD BE PERFORMED ON THIS MONTH
                                                                if(check_TO && ((tasktype_var == 'Waterfilter_Months__c' && checkWFfromMonth) || (tasktype_var == 'L_Months__c' && checkLMfromMonth))){
                                                                    toCalculate = true;
                                                                    aveLargePerMonth = 1.0;
                                                                }
                                                                //WHEN ABOVE SCENARIOS NOT APPLICABLE
                                                                else if(op_var.get(api_name_opsched) != null && fieldVal.contains(String.valueOf(i))) {
                                                                    toCalculate = true;
                                                                    aveLargePerMonth = 1.0;
                                                                }
                                                            }
                                                            //WHEN NO PM IN THE 'FROM' MONTH OF THE OPERATING SCHEDULE
                                                            else if(op_var.get(api_name_opsched) != null && fieldVal.contains(String.valueOf(i))) {
                                                                toCalculate = true;
                                                                aveLargePerMonth = 1.0;
                                                            }
                                                        
                                                        //SCENARIO 5.2: NO PM RULE - REGULAR MONTHLY CALCULATE
                                                        } else if(op_var.get(api_name_opsched) != null && fieldVal.contains(String.valueOf(i))) {
                                                            toCalculate = true;
                                                            aveLargePerMonth = 1.0;
                                                        }
                                                    }
                                                    
                                                    //SCENARIO 6: OTHER MONTHLY SCENARIOS / TYPES (D, B, I)
                                                    else {

                                                        if(op_var.get(api_name_opsched) != null && fieldVal.contains(String.valueOf(i))){
                                                            toCalculate = true;
                                                            aveLargePerMonth = 1.0;
                                                        }
                                                    }
                                                    
                                                    //System.debug('type / month: ' + tasktype_var + ' ' + i);
                                                    //System.debug('toCalculate: ' + toCalculate);
                                                    //System.debug('aveLargePerMonth: ' + aveLargePerMonth);

                                                    if(toCalculate){

                                                        //PROCESS & CALCULATE DATA
                                                        PricebookEntry pbe_var = new PricebookEntry();
                                                        if(map_asset_product.containsKey(pa_var)){
                                                            if( map_prodId_map_SalesOrgPbEntry.containsKey(map_asset_product.get(pa_var))){
                                                                if(map_assetId_salesOrg.containsKey(pa_var)){
                                                                    if(map_prodId_map_SalesOrgPbEntry.get(map_asset_product.get(pa_var)).containsKey(map_assetId_salesOrg.get(pa_var))){
                                                                        pbe_var = map_prodId_map_SalesOrgPbEntry.get(map_asset_product.get(pa_var)).get(map_assetId_salesOrg.get(pa_var)); //GET THE PRICEBOOK ENTRY TO EVALUATE
                                                                    } else continue;
                                                                } else continue;
                                                            } else continue;
                                                        } else continue;
                                                        
                                                        Decimal op_var_value = aveLargePerMonth;
                                                        
                                                        //GET THE MTTO IN PRICEBOOK ENTRY
                                                        Decimal mtto_pbentry_value = 0;
                                                        if(pbe_var.get(api_name_mtto) == null){
                                                            mtto_pbentry_value = 0;
                                                        } else {
                                                            mtto_pbentry_value = Decimal.valueOf(String.valueOf(pbe_var.get(api_name_mtto)));
                                                        }

                                                        //GET THE MTTO LOCATION SPECIFIC IN ACCOUNT LOCATION
                                                        Decimal mtto_accloc_locationspecific = 0;
                                                        if(op_var.Account_Location__r.MTTOLocationSpecific__c == null){
                                                            mtto_accloc_locationspecific = 0;
                                                        } else {
                                                            mtto_accloc_locationspecific = op_var.Account_Location__r.MTTOLocationSpecific__c;
                                                        }
                                                        
                                                        //GET THE DURATION PER CALL TYPE
                                                        Decimal perCallType = 0;
                                                        if(map_woType_country_mttoCallType.containsKey('S20')){
                                                            if(map_woType_country_mttoCallType.get('S20').containsKey(op_var.Account_Location__r.Mini_Sales_Organization__c)){
                                                                perCallType = map_woType_country_mttoCallType.get('S20').get(op_var.Account_Location__r.Mini_Sales_Organization__c) != null ? map_woType_country_mttoCallType.get('S20').get(op_var.Account_Location__r.Mini_Sales_Organization__c) : 0 ;
                                                            }
                                                        }

                                                        //ACTUAL CALCULATION CONSIDERING ALL MEAN TIME VALUES
                                                        Decimal result_mtto = (op_var_value * (mtto_pbentry_value + mtto_accloc_locationspecific + perCallType));
                                                        asset_per_value_var.computed_value = result_mtto;
                                                        total_day = total_day + result_mtto;
                                                        total_activity_day = total_activity_day + Integer.valueOf(Math.ceil(op_var_value)); 

                                                    } else {

                                                        //map_assetResult.put(pa_var, 0);
                                                        asset_per_value_var.computed_value = 0;
                                                    }

                                                    asset_per_value_var.assetId = pa_var;
                                                    asset_per_value_list.add(asset_per_value_var);

                                                    //System.debug('asset_per_value_var: ' + asset_per_value_var);
                                                }

                                                //map_dayResult.put(counter, asset_obj);
                                                asset_per_day_var.asset_per_value_list_wrapper = asset_per_value_list;

                                                //Decimal total_holder = (total_day / 60);
                                                //asset_per_day_var.total =  total_holder.setscale(2);
                                                asset_per_day_var.total =  total_day;
                                                asset_per_day_var.day_num = counter;
                                                asset_per_day_var.total_activities = total_activity_day;
                                                asset_per_day_list.add(asset_per_day_var);
                                                counter++;
                                            }

                                            //System.debug('asset_per_day_list: ' + asset_per_day_list);
                                            
                                            //map_taskResult.put(tasktype_var,map_dayResult);
                                            task_per_day_var.asset_per_day_list_wrapper = asset_per_day_list;
                                            task_per_day_var.tasktype = set_task_types_map.get(tasktype_var);
                                            task_type_list.add(task_per_day_var);
                                        } 
                                    }
                                
                                    //System.debug('task_type_list: ' + task_type_list);

                                    //CALCULATE DAILY TOTALS / ACTIVITY TOTALS (ROUTE LEVEL)
                                    Map<Integer, Decimal> day_total_map = new Map<Integer, Decimal>();
                                    Map<Integer, Integer> day_total_activity_map = new Map<Integer, Integer>();

                                    if(!task_type_list.isEmpty()){
                                        for(TaskTypePerDayTotalObject obj_var : task_type_list){
                                            if(!obj_var.asset_per_day_list_wrapper.isEmpty()){
                                                for(AssetPerDayTotalObject asset_var : obj_var.asset_per_day_list_wrapper){
                                                    
                                                    //DAY TOTALS
                                                    if(day_total_map.containsKey(asset_var.day_num)){
                                                        day_total_map.put(asset_var.day_num, day_total_map.get(asset_var.day_num) + asset_var.total);
                                                    } else {
                                                        day_total_map.put(asset_var.day_num, asset_var.total);
                                                    }
                                                    
                                                    //ACTIVITY TOTALS
                                                    if(day_total_activity_map.containsKey(asset_var.day_num)){
                                                        day_total_activity_map.put(asset_var.day_num, day_total_activity_map.get(asset_var.day_num) + asset_var.total_activities);
                                                    } else {
                                                        day_total_activity_map.put(asset_var.day_num, asset_var.total_activities);
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    //CREATE THE WRAPPER FOR TOTAL
                                    List<PerDayTotalObject> per_day_total_list = new List<PerDayTotalObject>();
                                    if(!day_total_map.isEmpty()){
                                        
                                        Route__c routeVar = map_route.get(route_var);
                                        
                                        Decimal mtto_accloc_locSpecific = 0;
                                        Decimal mtto_accloc_aveRoutePrep = 0;
                                        Decimal mtto_accloc_withinsite = 0;

                                        if(routeVar.Account_Location__c != null){

                                            //GET THE MTTO LOCATION SPECIFIC IN ACCOUNT LOCATION
                                            if(routeVar.Account_Location__r.MTTOLocationSpecific__c != null){
                                                mtto_accloc_locSpecific = routeVar.Account_Location__r.MTTOLocationSpecific__c;
                                            } 

                                            //GET THE ACCOUNT LOCATION AVERAGE ROUTE PREPARATION TIME
                                            if(routeVar.Account_Location__r.AverageRoutePrep__c != null){
                                                mtto_accloc_aveRoutePrep = routeVar.Account_Location__r.AverageRoutePrep__c;
                                            }

                                            //GET THE MTTT WITHIN SITE IN ACCOUNT LOCATION
                                            if(routeVar.Account_Location__r.MTTTWithinSite__c != null){
                                                mtto_accloc_withinsite = routeVar.Account_Location__r.MTTTWithinSite__c;
                                            }

                                        }
                                        
                                        
                                        for(Integer int_var : day_total_map.keySet()){

                                            PerDayTotalObject per_day_total_cont = new PerDayTotalObject();
                                            per_day_total_cont.day_num = int_var;
                                            
                                            Integer numOfAct = 0; Decimal routePrep_holder = mtto_accloc_aveRoutePrep; Decimal withinSite_total = 0;

                                            numOfAct = day_total_activity_map.get(int_var);
                                            
                                            if(numOfAct < 1){
                                                routePrep_holder = 0;
                                                withinSite_total = 0;
                                            } else {
                                                withinSite_total = (numOfAct - 1) * mtto_accloc_withinsite;
                                            }

                                            Decimal total_per_day_route = day_total_map.get(int_var) + routePrep_holder + withinSite_total;

                                            total_per_day_route = (total_per_day_route / 60);
                                            per_day_total_cont.total = total_per_day_route.setScale(5);
                                            per_day_total_list.add(per_day_total_cont);
                                            
                                            //CONSTRUCT THE UPDATE ON ROUTE RECORDS
                                            //DOO-5315 EXCLUDE UPDATE ON DAY_XX AND NORDICS_XX FIELDS IF NOT STANDARD FILTER (3PO OR JDE)
                                            if(filterType == 'all' || filterType == 'jde'){
                                                String apiName;
                                                if(!isNordics){
                                                    apiName = 'Day' + int_var + '__c';
                                                    routeVar.put(apiName, per_day_total_cont.total);
                                                } else {
                                                    apiName = 'Nordics_' + int_var + '__c';
                                                    routeVar.put(apiName, per_day_total_cont.total);
                                                }       
                                                
                                                Decimal mttoCount = per_day_total_cont.total;
                                                if(!isNordics){   
                                                    
                                                    //IF EXIST ADD KEY VALUE
                                                    Map<String, Decimal> map_day_mtto = new Map<String, Decimal>{'day_1' => 0.00, 'day_2' => 0.00, 'day_3' => 0.00, 'day_4' => 0.00, 'day_5' => 0.00, 'day_6' => 0.00, 'day_7' => 0.00, 'day_8' => 0.00, 'day_9' => 0.00, 'day_10' => 0.00, 'day_11' => 0.00, 'day_12' => 0.00, 'day_13' => 0.00, 'day_14' => 0.00};                                                                                            
                                                    String apiNameNew = 'day_' + int_var;
                                                    if(map_route_day_mtto != null && map_route_day_mtto.containsKey(route_var)){
                                                        map_route_day_mtto.get(route_var).put(apiNameNew, mttoCount);
                                                    }
                                                    //INITIALIZE MAP
                                                    else {                                                    
                                                        map_route_day_mtto.put(route_var, map_day_mtto);
                                                        map_route_day_mtto.get(route_var).put(apiNameNew, mttoCount);
                                                    }
                                                }
                                                else {    
                                                    
                                                    //IF EXIST ADD KEY VALUE
                                                    Map<String, Decimal> map_day_mtto = new Map<String, Decimal>{'nordics_1' => 0.00, 'nordics_2' => 0.00, 'nordics_3' => 0.00, 'nordics_4' => 0.00, 'nordics_5' => 0.00, 'nordics_6' => 0.00, 'nordics_7' => 0.00, 'nordics_8' => 0.00, 'nordics_9' => 0.00, 'nordics_10' => 0.00, 'nordics_11' => 0.00, 'nordics_12' => 0.00};                                            
                                                    String apiNameNew = 'nordics_' + int_var;                                                
                                                    if(map_route_day_mtto != null && map_route_day_mtto.containsKey(route_var)){
                                                        map_route_day_mtto.get(route_var).put(apiNameNew, mttoCount);
                                                    }
                                                    //INITIALIZE MAP
                                                    else {                                                    
                                                        map_route_day_mtto.put(route_var, map_day_mtto);
                                                        map_route_day_mtto.get(route_var).put(apiNameNew, mttoCount);
                                                    }                                                
                                                }
                                            }

                                            else if(filterType == '3po'){        
                                                String apiName = 'day_' + int_var;
                                                Decimal mttoCount = per_day_total_cont.total;
                                                Map<String, Decimal> map_day_mtto = new Map<String, Decimal>{'day_1' => 0.00, 'day_2' => 0.00, 'day_3' => 0.00, 'day_4' => 0.00, 'day_5' => 0.00, 'day_6' => 0.00, 'day_7' => 0.00, 'day_8' => 0.00, 'day_9' => 0.00, 'day_10' => 0.00, 'day_11' => 0.00, 'day_12' => 0.00, 'day_13' => 0.00, 'day_14' => 0.00};                                            
                                                //IF EXIST ADD KEY VALUE
                                                if(map_route_day_mtto.containsKey(route_var)){
                                                    map_route_day_mtto.get(route_var).put(apiName, mttoCount);
                                                }
                                                //IF EXIST INITIALIZE MAP
                                                else {
                                                    map_route_day_mtto.put(route_var, map_day_mtto);
                                                    map_route_day_mtto.get(route_var).put(apiName, mttoCount);
                                                }
                                            }                                        
                                        }    
                                        
                                        //TO AVOID DUPLICATE ID ON LIST FOR ALL+JDE SCENARIO MTTO STAMPING ON OLD FIELDS
                                        if(!routeToUpdate.contains(routeVar)){
                                            //routeToUpdate.add(routeVar);                        
                                        }                                                                                   
                                    }                                                                                            
                                    
                                    //map_route_type_day_calc.put(map_route.get(route_var),map_taskResult);

                                    if(map_route.containsKey(route_var)){
                                        mw.name = map_route.get(route_var).Name;

                                        if(map_route.get(route_var).Account_Location__r.SAP_Customer_ID__c != null){
                                            mw.account_location_name = map_route.get(route_var).Account_Location__r.Name + ' (' + map_route.get(route_var).Account_Location__r.SAP_Customer_ID__c + ')';
                                        } else {
                                            mw.account_location_name = map_route.get(route_var).Account_Location__r.Name;
                                        }

                                        mw.account_location_id = map_route.get(route_var).Account_Location__c;
                                        mw.account_location_postal_code = map_route.get(route_var).Account_Location__r.Apttus_Config2__PostalCode__c;
                                        mw.routeId = route_var;
                                        mw.info_all = task_type_list;
                                        mw.per_day_all = per_day_total_list;
                                        mw_List.add(mw);
                                    }

                                }//END OF ROUTE LOOP
                                                        
                                //system.debug(JSON.serialize(routeIdToTaskJSONMap));
                                //system.debug(JSON.serialize(routePAToTaskJSONMap));
                                
                                //DOO-5181 UPDATE THE ROUTE JSON FIELDS                            
                                for(String route_pa : routePAToTaskJSONMap.keySet()){                                  
                                    String routeId = route_pa.substringBefore('_');
                                    String paId = route_pa.substringAfter('_');                        
                                    String taskType = route_pa.substringAfter('-');         
                                    
                                    //COLLATE OLD AND NEW VALUES
                                    if(JSONMapFinal.containsKey(routeId)){                                
                                        //PUT PREVIOUS VALUES IN TEMPORARY MAP
                                        Map<String, Map<String,Integer>> JSONMapInitialPlaceHolder = JSONMapFinal.get(routeId);                                                                                                                                                                                 
                                        if(taskType == 'LM'){                                                                                                                                  
                                            for(Integer i = 1; i<15; i++){                                            
                                                String day_api = 'day_'+i;                                                   
                                                JSONMapFinal.get(routeId).get('Large').put(day_api,JSONMapInitialPlaceHolder.get('Large').get(day_api) + routePAToTaskJSONMap.get(route_pa).get(day_api));                                             
                                            }                                                                                          
                                        }
                                        else if(taskType == 'SM'){                                         
                                            for(Integer i = 1; i<15; i++){                                            
                                                String day_api = 'day_'+i;
                                                JSONMapFinal.get(routeId).get('Small').put(day_api,JSONMapInitialPlaceHolder.get('Small').get(day_api) + routePAToTaskJSONMap.get(route_pa).get(day_api));
                                            }
                                            
                                        }                                    
                                        else if(taskType == 'C'){                                           
                                            for(Integer i = 1; i<15; i++){                                        
                                                String day_api = 'day_'+i;
                                                JSONMapFinal.get(routeId).get('Cups').put(day_api,JSONMapInitialPlaceHolder.get('Cups').get(day_api) + routePAToTaskJSONMap.get(route_pa).get(day_api));                                        
                                            }                                        
                                        }                                                      
                                    }
                                    //INITIALIZE
                                    else {  

                                        Map<String,Integer> LTask = new Map<String,Integer>{'day_1' => 0, 'day_2' => 0, 'day_3' => 0, 'day_4' => 0, 'day_5' => 0, 'day_6' => 0, 'day_7' => 0, 'day_8' => 0, 'day_9' => 0, 'day_10' => 0, 'day_11' => 0, 'day_12' => 0, 'day_13' => 0, 'day_14' => 0};
                                        Map<String,Integer> STask = new Map<String,Integer>{'day_1' => 0, 'day_2' => 0, 'day_3' => 0, 'day_4' => 0, 'day_5' => 0, 'day_6' => 0, 'day_7' => 0, 'day_8' => 0, 'day_9' => 0, 'day_10' => 0, 'day_11' => 0, 'day_12' => 0, 'day_13' => 0, 'day_14' => 0};
                                        Map<String,Integer> CTask = new Map<String,Integer>{'day_1' => 0, 'day_2' => 0, 'day_3' => 0, 'day_4' => 0, 'day_5' => 0, 'day_6' => 0, 'day_7' => 0, 'day_8' => 0, 'day_9' => 0, 'day_10' => 0, 'day_11' => 0, 'day_12' => 0, 'day_13' => 0, 'day_14' => 0};

                                        if(taskType == 'LM'){ 
                                            for(Integer i = 1; i<15; i++){
                                                String day_api = 'day_'+i;                                                               
                                                LTask.put(day_api,  routePAToTaskJSONMap.get(route_pa).get(day_api));                       
                                            }
                                        }
                                        else if(taskType == 'SM'){      
                                            for(Integer i = 1; i<15; i++){
                                                String day_api = 'day_'+i;                                                       
                                                STask.put(day_api,  routePAToTaskJSONMap.get(route_pa).get(day_api)); 
                                            }
                                        }                                    
                                        else if(taskType == 'C'){    
                                            for(Integer i = 1; i<15; i++){
                                                String day_api = 'day_'+i;                                                                 
                                                CTask.put(day_api,  routePAToTaskJSONMap.get(route_pa).get(day_api)); 
                                            }
                                        }                                    
                                        Map<String, Map<String,Integer>> PlaceHolderMap = new Map<String, Map<String,Integer>>{
                                            'Large' => LTask,
                                            'Small' => STask,
                                            'Cups' => CTask
                                        };
                                        JSONMapFinal.put(routeId,PlaceHolderMap);
                                    }                        
                                }//END JSON                            
                            }
                        }     

                                        
                        //CONSTRUCT THE TOTAL PER ACCOUNT LOCATION                    
                        //GROUP THE DAILY ROUTE TOTALS BY ACCOUNT LOCATION
                        Map<String, List<MainWrapper>> accLoc_per_mw_map = new Map<String, List<MainWrapper>>();
                        if(!mw_List.isEmpty()){
                            for(MainWrapper mw_var : mw_List){
                                if(accLoc_per_mw_map.containsKey(mw_var.account_location_id)){
                                    accLoc_per_mw_map.get(mw_var.account_location_id).add(mw_var);
                                } else {
                                    accLoc_per_mw_map.put(mw_var.account_location_id, new List<MainWrapper>{mw_var});
                                }
                            }
                        }

                        if(!accLoc_per_mw_map.isEmpty()){
                            for(String id_var : accLoc_per_mw_map.keySet()){
                                List<MainWrapper> all_wrap_accloc = accLoc_per_mw_map.get(id_var);

                                Map<Integer, Decimal> per_day_per_accountloc_total = new Map<Integer, Decimal>();
                                for(MainWrapper mw_var : all_wrap_accloc){
                                    for(PerDayTotalObject pd_var : mw_var.per_day_all){
                                        if(per_day_per_accountloc_total.containsKey(pd_var.day_num)){
                                            per_day_per_accountloc_total.put(pd_var.day_num, per_day_per_accountloc_total.get(pd_var.day_num) + pd_var.total);
                                        } else {
                                            per_day_per_accountloc_total.put(pd_var.day_num, pd_var.total);
                                        }
                                    }
                                }

                                //CREATE THE WRAPPER FOR TOTAL
                                List<PerDayTotalObject_AccountLocation> per_day_total_acc_list = new List<PerDayTotalObject_AccountLocation>();
                                Map<Integer, Decimal> dayTotal_accLoc = new Map<Integer, Decimal>();
                                if(!per_day_per_accountloc_total.isEmpty()){
                                    for(Integer int_var : per_day_per_accountloc_total.keySet()){

                                        /* PerDayTotalObject_AccountLocation per_day_total_accLoc = new PerDayTotalObject_AccountLocation();
                                        per_day_total_accLoc.day_num = int_var;
                                        per_day_total_accLoc.total = per_day_per_accountloc_total.get(int_var);
                                        per_day_total_acc_list.add(per_day_total_accLoc); */
                                        dayTotal_accLoc.put(int_var, per_day_per_accountloc_total.get(int_var));
                                    }
                                }

                                accLoc_map_total.put(id_var, dayTotal_accLoc);

                                /* MainWrapper_AccountLocation mw_accloc_var = new MainWrapper_AccountLocation();
                                mw_accloc_var.mainwrapper_list = all_wrap_accloc;
                                mw_accloc_var.per_day_all_accloc = per_day_total_acc_list;
                                mw_accloc_var.account_location_id = id_var;
                                mw_accloc_var.account_location_name_total = all_wrap_accloc[0].account_location_name;
                                mw_accloc_var.account_location_postalcode = all_wrap_accloc[0].account_location_postal_code;
                                mw_accLoc_List.add(mw_accloc_var); */
                            }
                        }                        
                    }
                }
                                                
                Map<String, Map<String, BucketizeWrapper>> route_month_bucket_map = new Map<String, Map<String, BucketizeWrapper>>(); //routeid+tasktype, month, wrapper object                                                                     
                //SUMMARIZE BUCKETIZE ACTUALS
                //DOO-5170 Francis Allen Alindogan 03/17/2021
                if(!list_woli.isEmpty()){
                    if((filterType == 'all' || filterType == 'jde') && isNordics == false){
                        route_month_bucket_map.putAll(performBucketizeActuals(list_woli, filterType, TS_Constants.ACTIVITY_LARGE, accLoc_route_map));
                        route_month_bucket_map.putAll(performBucketizeActuals(list_woli, filterType, TS_Constants.ACTIVITY_CUPS, accLoc_route_map));
                        route_month_bucket_map.putAll(performBucketizeActuals(list_woli, filterType, TS_Constants.ACTIVITY_SMALL, accLoc_route_map));
                    }
                    else if(filterType == '3po' && isNordics == false){
                        route_month_bucket_map.putAll(performBucketizeActuals(list_woli, filterType, TS_Constants.ACTIVITY_CUPS, accLoc_route_map));
                        route_month_bucket_map.putAll(performBucketizeActuals(list_woli, filterType, TS_Constants.ACTIVITY_SMALL, accLoc_route_map));                                        
                    }
                }
                
                route_month_bucket_map = addBucketizeActualsFieldsToFlush(route_month_bucket_map, filterType);
                system.debug('Actuals for Update:' +JSON.serialize(route_month_bucket_map));                                                                                                               
                
                //ADD THE JSON FIELDS ON ROUTE
                //FOR NL
                if(!JSONMapFinal.isEmpty() && !isNordics){ 
                    system.debug('Buckets for Update:' +JSON.serialize(JSONMapFinal));
                    for(Id routeId : JSONMapFinal.keySet()){                
                        Route__c routeObj = new Route__c();
                        routeObj.Id = routeId;     
                        if(filterType == 'all'){                        
                            routeObj.put('Large__c', JSON.serialize(JSONMapFinal.get(routeId).get('Large')));
                            routeObj.put('Cups__c',  JSON.serialize(JSONMapFinal.get(routeId).get('Cups')));
                            routeObj.put('Small__c', JSON.serialize(JSONMapFinal.get(routeId).get('Small')));                              
                            routeObj.put('MTTO_All__c',  JSON.serialize(map_route_day_mtto.get(routeId)));          
                        }
                        else if(filterType == '3po'){                                         
                            routeObj.put('Cups_3rd_Party__c',  JSON.serialize(JSONMapFinal.get(routeId).get('Cups')));
                            routeObj.put('Small_3rd_Party__c', JSON.serialize(JSONMapFinal.get(routeId).get('Small')));    
                            routeObj.put('MTTO_3rd_Party__c',  JSON.serialize(map_route_day_mtto.get(routeId)));                                       
                        }
                        //FOR JDE UPDATE IT STRAIGHT TO THE FINAL MAP
                        if(filterType == 'jde' && ctr == 2 && isNordics == false && routeToUpdateMap != null && routeToUpdateMap.containsKey(routeId)){                                                        
                            routeToUpdateMap.get(routeId).put('Large_JDEOnly__c', JSON.serialize(JSONMapFinal.get(routeId).get('Large')));
                            routeToUpdateMap.get(routeId).put('Cups_JDEOnly__c',  JSON.serialize(JSONMapFinal.get(routeId).get('Cups')));
                            routeToUpdateMap.get(routeId).put('Small_JDEOnly__c', JSON.serialize(JSONMapFinal.get(routeId).get('Small')));                              
                            routeToUpdateMap.get(routeId).put('MTTO_JDEOnly__c',  JSON.serialize(map_route_day_mtto.get(routeId)));                               
                        }
                        else {                            
                            routeToUpdateMap.put(routeId, routeObj);                                                        
                        }                        
                    }                                
                }      
                //FOR NORDICS
                else if(!map_route_day_mtto.isEmpty() && isNordics) {                   
                    for(Id routeId : map_route_day_mtto.keySet()){                           
                        Route__c routeObj = new Route__c();
                        routeObj.Id = routeId;     
                        routeObj.put('MCO__c',  JSON.serialize(map_route_day_mtto.get(routeId)));  
                        routeToUpdateMap.put(routeId, routeObj);
                    }                
                }          
                                                
                //ADD BUCKETIZE ACTUALS TO ROUTE
                //DOO-5170 Francis Allen Alindogan 03/17/2021
                if(isNordics == false){
                    if(!route_month_bucket_map.isEmpty()){
                        for(String routeAndTaskType : route_month_bucket_map.keySet()){          
                            List<String> routeSplit = routeAndTaskType.split('\\-');
                            String routeId = routeSplit[0];         
                            String taskType = routeSplit[1];
                            //IF ALREADY EXIST IN UPDATE MAP
                            if(routeToUpdateMap.containsKey(routeId)){
                                if(filterType == 'all' && isNordics == false){
                                    if(taskType == TS_Constants.ACTIVITY_SMALL){                                        
                                        if(route_month_bucket_map.get(routeAndTaskType)!= null){
                                            routeToUpdateMap.get(routeId).put('Small_Bucketize_All_Actual__c', JSON.serialize(route_month_bucket_map.get(routeAndTaskType)));
                                        }
                                        else {
                                            routeToUpdateMap.get(routeId).put('Small_Bucketize_All_Actual__c', null);    
                                        }
                                    }
                                    else if(taskType == TS_Constants.ACTIVITY_CUPS){                                        
                                        if(route_month_bucket_map.get(routeAndTaskType)!= null){
                                            routeToUpdateMap.get(routeId).put('Cups_Bucketize_All_Actual__c', JSON.serialize(route_month_bucket_map.get(routeAndTaskType)));
                                        }
                                        else {
                                            routeToUpdateMap.get(routeId).put('Cups_Bucketize_All_Actual__c', null);    
                                        }
                                    }
                                    else if(taskType == TS_Constants.ACTIVITY_LARGE){                                        
                                        if(route_month_bucket_map.get(routeAndTaskType)!= null){
                                            routeToUpdateMap.get(routeId).put('Large_Bucketize_All_Actual__c', JSON.serialize(route_month_bucket_map.get(routeAndTaskType)));
                                        }
                                        else {
                                            routeToUpdateMap.get(routeId).put('Large_Bucketize_All_Actual__c', null);    
                                        }
                                    }
                                }                                
                                if(filterType == 'jde' && ctr == 2 && isNordics == false && routeToUpdateMap != null && routeToUpdateMap.containsKey(routeId)){      
                                    if(taskType == TS_Constants.ACTIVITY_SMALL){                                        
                                        if(route_month_bucket_map.get(routeAndTaskType)!= null){
                                            routeToUpdateMap.get(routeId).put('Small_Bucketize_JDEOnly_Actual__c', JSON.serialize(route_month_bucket_map.get(routeAndTaskType)));
                                        }
                                        else {
                                            routeToUpdateMap.get(routeId).put('Small_Bucketize_JDEOnly_Actual__c', null);    
                                        }
                                    }
                                    else if(taskType == TS_Constants.ACTIVITY_CUPS){                                        
                                        if(route_month_bucket_map.get(routeAndTaskType)!= null){
                                            routeToUpdateMap.get(routeId).put('Cups_Bucketize_JDEOnly_Actual__c', JSON.serialize(route_month_bucket_map.get(routeAndTaskType)));
                                        }
                                        else {
                                            routeToUpdateMap.get(routeId).put('Cups_Bucketize_JDEOnly_Actual__c', null);    
                                        }
                                    }
                                    else if(taskType == TS_Constants.ACTIVITY_LARGE){                                        
                                        if(route_month_bucket_map.get(routeAndTaskType)!= null){
                                            routeToUpdateMap.get(routeId).put('Large_Bucketize_JDEOnly_Actual__c', JSON.serialize(route_month_bucket_map.get(routeAndTaskType)));
                                        }
                                        else {
                                            routeToUpdateMap.get(routeId).put('Large_Bucketize_JDEOnly_Actual__c', null);    
                                        }
                                    }                                    
                                }
                                
                                if(filterType == '3po' && isNordics == false){
                                    if(taskType == TS_Constants.ACTIVITY_SMALL){
                                        if(route_month_bucket_map.get(routeAndTaskType)!= null){
                                            routeToUpdateMap.get(routeId).put('Small_Bucketize_3rdParty_Actual__c', JSON.serialize(route_month_bucket_map.get(routeAndTaskType)));
                                        }
                                        else {
                                            routeToUpdateMap.get(routeId).put('Small_Bucketize_3rdParty_Actual__c', null);    
                                        }
                                    }
                                    else if(taskType == TS_Constants.ACTIVITY_CUPS){
                                        if(route_month_bucket_map.get(routeAndTaskType)!= null){
                                            routeToUpdateMap.get(routeId).put('Cups_Bucketize_3rdParty_Actual__c', JSON.serialize(route_month_bucket_map.get(routeAndTaskType)));
                                        }
                                        else {
                                            routeToUpdateMap.get(routeId).put('Cups_Bucketize_3rdParty_Actual__c', null);    
                                        }
                                    }
                                }  
                            }                        
                        }                        
                    }                          
                }
                                        
                //FLUSH ALL ROUTES TO 0
                //DOO-3923 Xen Reyes Feb. 25, 2020
                System.debug('routeId_toFlush: ' + routeId_toFlush);
                if(!routeId_toFlush.isEmpty()){                    
                    for(String routeId_var : routeId_toFlush){                        
                        Route__c rs_var = new Route__c();
                        rs_var.Id = routeId_var;                                                                                
                        if(!isNordics){
                            for(Integer int_loop = 1; int_loop <= 14; int_loop++){
                                //CONSTRUCT THE UPDATE ON ROUTE RECORDS
                                String apiName = 'Day' + int_loop + '__c';
                                rs_var.put(apiName, 0);                            
                            }
                            rs_var.put('MTTO_All__c', null);
                            rs_var.put('Large__c', null);
                            rs_var.put('Cups__c', null);
                            rs_var.put('Small__c', null);
                            
                            rs_var.put('MTTO_JDEOnly__c',  null); 
                            rs_var.put('Large_JDEOnly__c', null);
                            rs_var.put('Cups_JDEOnly__c',  null);
                            rs_var.put('Small_JDEOnly__c', null);                              
                                                                                      
                            rs_var.put('MTTO_3rd_Party__c', null);
                            rs_var.put('Cups_3rd_Party__c', null);
                            rs_var.put('Small_3rd_Party__c', null);
                                                       
                            //rs_var.put('Large_Bucketize_All_Actual__c', null);                              
                            //rs_var.put('Cups_Bucketize_All_Actual__c', null);
                            //rs_var.put('Small_Bucketize_All_Actual__c', null);                            
                            
                            //rs_var.put('Large_Bucketize_JDEOnly_Actual__c', null);
                            //rs_var.put('Cups_Bucketize_JDEOnly_Actual__c', null);
                            //rs_var.put('Small_Bucketize_JDEOnly_Actual__c', null);
                            
                            //rs_var.put('Cups_Bucketize_3rdParty_Actual__c', null);
                            //rs_var.put('Small_Bucketize_3rdParty_Actual__c', null);                                                 
                        } 
                        else {
                            /*
                            for(Integer int_loop = 1; int_loop <= 12; int_loop++){                                
                                //CONSTRUCT THE UPDATE ON ROUTE RECORDS
                                String apiName = 'Nordics_' + int_loop + '__c';
                                rs_var.put(apiName, 0);
                            }*/                            
                            rs_var.put('MCO__c', null);                            
                        }    
                        //TO AVOID DUPLICATE ID ON LIST FOR ALL+JDE SCENARIO FLUSHING
                        if(!routeToUpdateMap.containsKey(routeId_var)){
                            routeToUpdateMap.put(routeId_var, rs_var);                                           
                        }                        
                    }
                }                                          
            } //END FOR LOOP        
            system.debug('Final Update Map: ' +JSON.serialize(routeToUpdateMap));     
            if(!routeToUpdateMap.isEmpty()){
                for(Route__c r : routeToUpdateMap.values()){
                    routeToUpdate.add(r);
                }                                                        
                if(!routeToUpdate.isEmpty()){
                    update routeToUpdate;
                }
            }    
        }
        catch (Exception e){
            System.debug(e);
        }
        return accLoc_map_total;
    }
    
    /*
    * @author        Francis Allen Alindogan
    * @date          03/29/2021
    * @description   DOO - 5854 Consolidate all WOLI into Map for Bucketize Actuals
    * @revision(s)   
    */
    public static Map<String, Map<String, BucketizeWrapper>> performBucketizeActuals(List<WorkOrderLineItem> list_woli, String filterType, String taskType, Map<String, String>accLoc_route_map){    
        Map<String, Map<String, BucketizeWrapper>> route_month_bucket_map = new Map<String, Map<String, BucketizeWrapper>>(); 
        Integer currentYear = System.Today().year();
        Integer nextYear = currentYear + 1;

        if(!list_woli.isEmpty()){                        
            for(WorkOrderLineItem woli : list_woli){    
                
                String route;
                String bucket;
                
                //UNIVERSAL SKIP CONDITIONS
                //SKIP S20 AND IS NOT FOR THIS TASK TYPE
                if(taskType != woli.WorkOrderLineItemType__c && woli.WorkOrderType__c == TS_Constants.WO_TYPE_S20_MACHINECARE){
                    continue;
                }                
                                
                //SKIP S15 AND METHOD NOT RAN AS SMALL, SINCE WE SAVE S15 ON SMALL BY TECHNICAL DESIGN
                if(woli.WorkOrderType__c == TS_Constants.WO_TYPE_S15_1STLINECM && taskType != 'Small'){
                    continue;
                }
                                 
                //FILTER TYPE RELATED SKIP CONDITIONS   
                if(filterType == 'jde'){                    
                    //SKIP IF JDE ONLY + SMALL AND CUPS FROM THIRD PARTY
                    if(woli.AccountLocation__r.Third_Party_Resource__c != null && 
                       (woli.WorkOrderLineItemType__c == TS_Constants.ACTIVITY_CUPS || woli.WorkOrderLineItemType__c == TS_Constants.ACTIVITY_SMALL)){
                        continue;
                    }                                        
                    //SKIP S15 3PO IF RAN AS JDE ONLY
	                if(woli.WorkOrderType__c == TS_Constants.WO_TYPE_S15_1STLINECM && woli.Case__r.SendTo3rdParty__c == true){
	                    continue;
                	}     
                }                    
                else if(filterType == '3po'){					                           
                	//SKIP S15 NON 3PO IF RAN AS 3PO
                	if(woli.WorkOrderType__c == TS_Constants.WO_TYPE_S15_1STLINECM && (woli.Case__r.SendTo3rdParty__c == false || woli.AccountLocation__r.Third_Party_Resource__r.RLS_Portal_User__c == false)){
	                    continue;
                	}              
                }
                
                String month = woli.EndDate__c.format('MMMM');
                if(month == 'January'){
                    if(woli.EndDate__c.year() == currentYear){
                        month = month + ' ' + currentYear;
                    }
                    else {
                        month = month + ' ' + nextYear;
                    }    
                }                
                                
                route  = accLoc_route_map.get(woli.AccountLocation__c) + '-' + taskType;
                                
                //IF S15 CREATE A TEMPORARY S15 BUCKET
                if(woli.WorkOrderType__c == TS_Constants.WO_TYPE_S15_1STLINECM){
                    bucket = TS_Constants.WO_TYPE_S15_1STLINECM;
                }
                else {
                    bucket = woli.Operating_Bucket__c;
                }
                            
                //DEFAULT VALUES FOR INITIALIZE SCENARIO
                Integer x = 0;
                Integer y = 0;                        
                String  xy = '0(0)'; // example: 50(4)    
                Integer TTL = 0;
                Integer EOD_Cancel = 0;        
                Integer S15 = 0;
                Integer STTL = 0;
                                
                //BOOLEAN CONDITIONS
                Boolean isTypeX = woli.WorkOrderType__c == TS_Constants.WO_TYPE_S20_MACHINECARE && woli.Status == TS_Constants.STATUS_COMPLETED ? true : false;
                Boolean isTypeY = woli.WorkOrderType__c == TS_Constants.WO_TYPE_S20_MACHINECARE && woli.Status == TS_Constants.STATUS_CANCELED && woli.OP_CancelationReasonMachine__c != TS_Constants.EOD_BATCH ? true : false;
                Boolean isEOD_Cancel = woli.WorkOrderType__c == TS_Constants.WO_TYPE_S20_MACHINECARE && woli.Status == TS_Constants.STATUS_CANCELED && woli.OP_CancelationReasonMachine__c == TS_Constants.EOD_BATCH ? true : false;
                Boolean isS15 = woli.WorkOrderType__c == TS_Constants.WO_TYPE_S15_1STLINECM && woli.Status == TS_Constants.STATUS_COMPLETED ? true : false;                
                                                                                                                
                //IF ROUTE EXIST
                if(!route_month_bucket_map.isEmpty() && route_month_bucket_map.containsKey(route)){       
                    //IF MONTH EXIST
                    if(route_month_bucket_map.get(route) != null && route_month_bucket_map.get(route).containsKey(month)){                                                        
                        Boolean increaseTTL = false;
                        Boolean increaseSTTL = false;
                        //IF BUCKET EXIST
                        if(route_month_bucket_map.get(route).get(month) != null && route_month_bucket_map.get(route).get(month).Buckets != null &&route_month_bucket_map.get(route).get(month).Buckets.containsKey(bucket)){                                                                
                            xy = route_month_bucket_map.get(route).get(month).Buckets.get(bucket);
                            List<String> xySplit = xy.split('\\(');
                            x = Integer.valueOf(xySplit[0]);
                            if(xySplit.size() > 1){
                                y = Integer.valueOf(xySplit[1].remove(')'));        
                            }
                            else {
                                y = 0;
                            }
                                                        
                            //ADD VALUE OF X
                            if(isTypeX){                                        
                                x++;
                                increaseTTL = true;
                                increaseSTTL = true;
                            }                                    
                            //ADD VALUE OF Y 
                            if(isTypeY){  
                                x++;                                      
                                y++;
                                increaseTTL = true;
                                increaseSTTL = true;
                            }               
                            //ADD VALUE OF BUCKET
                            xy = String.valueOf(x+'('+ y +')');      
                                                                                  
                            Map<String, String> previousBucketMap = route_month_bucket_map.get(route).get(month).Buckets;
                            previousBucketMap.put(bucket, xy);                                                                     
                            route_month_bucket_map.get(route).get(month).Buckets = previousBucketMap;     
                            
                        }                                
                        //IF ROUTE EXIST, IF MONTH EXIST, IF BUCKET NEW
                        else {                               
                            //INITIALIZE VALUE OF X
                            if(isTypeX){                                        
                                x++;
                                increaseTTL = true;
                                increaseSTTL = true;
                            }
                            //INITIALIZE VALUE OF Y
                            if(isTypeY){     
                                x++;                                   
                                y++;
                                increaseTTL = true;
                                increaseSTTL = true;
                            }                 
                            //INITIALIZE VALUE OF BUCKET
                            xy = String.valueOf(x+'('+ y +')');      
                                                                                                                
                            Map<String, String> initialBucketMap = new Map<String, String>();
                            initialBucketMap.put(bucket, xy);  
                            
                            //TO ADD EXISTING BUCKETS FROM SAME MONTH
                            if(!route_month_bucket_map.get(route).get(month).Buckets.isEmpty()){
                                initialBucketMap.putAll(route_month_bucket_map.get(route).get(month).Buckets);
                            }
                            route_month_bucket_map.get(route).get(month).Buckets = initialBucketMap;                             
                        }
                        
                        //ADD VALUE OF EOD CANCEL      
                        EOD_Cancel = route_month_bucket_map.get(route).get(month).EOD_Cancel;
                        if(isEOD_Cancel){                                    
                            EOD_Cancel++;
                            increaseTTL = true;
                        }                                                                                                                                                                                                       
                        route_month_bucket_map.get(route).get(month).EOD_Cancel = EOD_Cancel; 
                                                
                        //ADD VALUE OF TTL    
                        if(increaseTTL == true){
                            route_month_bucket_map.get(route).get(month).TTL++;
                        }                                      
                        if(increaseSTTL == true){
                            route_month_bucket_map.get(route).get(month).STTL++;
                        }                 
                        
                        //ADD VALUE OF S15
                        if(isS15){
                            route_month_bucket_map.get(route).get(month).S15++;
                        }                         
                    }                            
                    //IF ROUTE EXIST, IF MONTH NEW                          
                    else {                               
                        //FLUSH TTL AND EOD CANCEL FOR EVERY NEW MONTH
                        TTL = 0;
                        STTL = 0;
                        S15 = 0;
                        EOD_Cancel = 0;                                
                        
                        Map<String, String> initialBucketizeWrapper = new Map<String, String>();
                        initialBucketizeWrapper.put(bucket, '0'); 
                        BucketizeWrapper newBW = new BucketizeWrapper();
                        newBW.TTL = 0;
						newBW.STTL = 0;
                    	newBW.S15 = 0;
                        newBW.EOD_Cancel = 0;
                        newBW.Buckets = initialBucketizeWrapper;                        
                        route_month_bucket_map.get(route).put(month, newBW);  
                        
                        //INITIALIZE BUCKET
                        //INITIALIZE VALUE OF X
                        if(isTypeX){                                    
                            x++;
                        }
                        //INITIALIZE VALUE OF Y
                        if(isTypeY){     
                            x++;                               
                            y++;
                        }       
                        
                        //INITIALIZE VALUE OF BUCKET
                        xy = String.valueOf(x+'('+ y +')');      
                                                
                        //Map<String, String> initialBucketMap = DefaultBucketMap;
                        Map<String, String> initialBucketMap = new Map<String, String>();
                        initialBucketMap.put(bucket, xy);                                                                     
                        route_month_bucket_map.get(route).get(month).Buckets = initialBucketMap; 
                        
                        //INITIALIZE VALUE OF EOD CANCEL                                    
                        if(isEOD_Cancel){                                    
                            EOD_Cancel++;
                        }                                                                                                                                                                  
                        route_month_bucket_map.get(route).get(month).EOD_Cancel = EOD_Cancel;
                        
                        //INITIALIZE VALUE OF TTL
                        TTL = x + EOD_Cancel;           
                        route_month_bucket_map.get(route).get(month).TTL = TTL;  
                        
                        STTL = x;    
                    	route_month_bucket_map.get(route).get(month).STTL = STTL;   
                        
                        //INITIALIZE VALUE OF S15
                        if(isS15){
                            S15++;
                        }
                        route_month_bucket_map.get(route).get(month).S15 = S15;  
                                                
                    }
                }    
                //IF ROUTE NEW
                else {                        
                    //INITIALIZE ROUTE
                    
                    //INITIALIZE MONTH                                                                               
                    Map<String, BucketizeWrapper> initialMonthBucketizeWrapper = new Map<String, BucketizeWrapper>();
                    Map<String, String> initialBucketizeWrapper = new Map<String, String>();
                    initialBucketizeWrapper.put(bucket, '0');                    
                    BucketizeWrapper newBW = new BucketizeWrapper();
                    newBW.TTL = 0;
                    newBW.STTL = 0;
                    newBW.S15 = 0;
                    newBW.EOD_Cancel = 0;
                    newBW.Buckets = initialBucketizeWrapper;
                    initialMonthBucketizeWrapper.put(month, newBW);                                                                                
                    route_month_bucket_map.put(route, initialMonthBucketizeWrapper);                     
                                        
                    //INITIALIZE BUCKET      
                                             
                    //INITIALIZE VALUE OF X
                    if(isTypeX){
                        x++;
                    }
                    //INITIALIZE VALUE OF Y
                    if(isTypeY){
                        x++;
                        y++;
                    }    
                                                                             
                    //INITIALIZE VALUE OF BUCKET
                    xy = String.valueOf(x+'('+ y +')');                                                                                                                      
                    route_month_bucket_map.get(route).get(month).Buckets.put(bucket, xy);       
                    
                    
                    //INITIALIZE VALUE OF EOD CANCEL
                    if(isEOD_Cancel){                                    
                        EOD_Cancel++;
                    }                      
                    route_month_bucket_map.get(route).get(month).EOD_Cancel = EOD_Cancel;
                    
                    
                    //INITIALIZE VALUE OF TTL
                    TTL = x + EOD_Cancel;    
                    route_month_bucket_map.get(route).get(month).TTL = TTL;                                                                     
                                        
                    STTL = x;    
                    route_month_bucket_map.get(route).get(month).STTL = STTL;  
                    
                    //INITIALIZE VALUE OF S15
                    if(isS15){
                        S15++;
                    }
                    route_month_bucket_map.get(route).get(month).S15 = S15;  
                }                                    
            }
        }         
        return route_month_bucket_map;
    }          
    
    /*
    * @author        Francis Allen Alindogan
    * @date          03/29/2021
    * @description   DOO - 5854 Flush route fields without updates for Bucketize Actuals
    * @revision(s)   
    */
    public static Map<String, Map<String, BucketizeWrapper>> addBucketizeActualsFieldsToFlush(Map<String, Map<String, BucketizeWrapper>> route_month_bucket_map, String filterType){
        Set<String> allRoutesWithBucketizeActual = new Set<String>();
        Set<String> routeFieldSet = new Set<String>();
        Map<String, Map<String, BucketizeWrapper>> return_route_month_bucket_map = new Map<String, Map<String, BucketizeWrapper>>();
        if(filterType == 'all' | filterType =='jde'){            
            routeFieldSet = new Set<String>{'Large', 'Cups', 'Small'};                           
        }
        else if(filterType == '3po'){             
            routeFieldSet = new Set<String>{ 'Cups', 'Small'};                           
        }
        //CONSOLIDATE ALL ROUTES WITH UPDATES
        if(!route_month_bucket_map.isEmpty()){
            for(String route_tasktype : route_month_bucket_map.keySet()){
                List<String> routeSplit = route_tasktype.split('\\-');
                String route_id = routeSplit[0];         
                String task_name = routeSplit[1];
                allRoutesWithBucketizeActual.add(route_id);
            }
                        
            if(!allRoutesWithBucketizeActual.isEmpty()){
                for(String route_id : allRoutesWithBucketizeActual){
                    for(String route_field_name : routeFieldSet){
                        String combo_key = route_id + '-' + route_field_name;
                        //IF ROUTE + TASK TYPE ALREADY HAS DATA, RE-ASSIGN IT
                        if(route_month_bucket_map.containsKey(combo_key)){
                            return_route_month_bucket_map.put(combo_key, route_month_bucket_map.get(combo_key));
                        }
                        //IF ROUTE + TASK TYPE IS NOT EXISTING, SET TO NULL
                        else {
                            return_route_month_bucket_map.put(combo_key, null);
                        }                        
                    }
                }
            }   
            else {
                return_route_month_bucket_map = route_month_bucket_map;
            }
        }             
        return return_route_month_bucket_map;        
    }
}