/**
* @author        Abram Vixen Reyes
* @date          Oct. 14, 2019
* @description   Controller for TS_OperatingOptimizerTab (LightningComponent)
* @revision(s)
*/
public without sharing class TS_OperatingOptimizerTabController {
    
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

    public class Pre_Values_Wrapper{
        @AuraEnabled
        public List<String> district_set;
        @AuraEnabled
        public List<String> country_set;
        @AuraEnabled
        public List<Last_Synchronization_OPG__c> lastSync_List;
        @AuraEnabled
        public Map<String, List<String>> countryRegionMap_wrap;
        @AuraEnabled
        public Map<Integer, Integer> numberOfBusinessDaysPerMonth;
    }

    public class AccLoc_Id_Wrapper{
        @AuraEnabled
        public List<String> accId_set;
        @AuraEnabled
        public List<String> accId_set_unassigned;
        @AuraEnabled
        public List<String> accId_set_noOpsched;
        @AuraEnabled
        public List<String> combined_unfiltered_unassigned;
        @AuraEnabled
        public List<String> combined_unfiltered_noSchedule;
        @AuraEnabled
        public List<String> all_combined;
    }

    private static Map<String, String> countryName_map {
        get {
            if (countryName_map == null) {
                countryName_map = new Map<String, String>{
                        'NL' => 'SAP_0111',
                        'DK' => 'SAP_0975',
                        'NO' => 'SAP_6864'
                        };
            }

            return countryName_map;
        }
        set;
    }

    @AuraEnabled
    public static String query_pre_items(){
        
        LightningResponse lResponse = new LightningResponse();
        Pre_Values_Wrapper pv_var = new Pre_Values_Wrapper();

        try{

            Set<String> district_set = new Set<String>();
            Set<String> country_set = new Set<String>();
            Map<String, List<String>> countryRegionMap = new Map<String, List<String>>();

            //QUERY DISTRICT
            for(TS_District__mdt dis_var : [SELECT Id, Label, Country_Code__c FROM TS_District__mdt ORDER BY Label ASC]){               
                district_set.add(dis_var.Country_Code__c +' - '+ dis_var.Label);
                country_set.add(dis_var.Country_Code__c);

                /* [SELECT Id, Label, Country_Code__c, (SELECT Id, District__c, Country_Code__c FROM TS_Hierarchy_Derivations__r) FROM TS_District__mdt ORDER BY Label ASC]
                 * or(TS_Hierarchy_Derivation__mdt md_var : dis_var.TS_Hierarchy_Derivations__r){
                    country_set.add(md_var.Country_Code__c);
                } */

                String districtStr = dis_var.Country_Code__c +' - '+ dis_var.Label;
                if(countryRegionMap.containsKey(dis_var.Country_Code__c)){
                    countryRegionMap.get(dis_var.Country_Code__c).add(districtStr);
                } else {
                    countryRegionMap.put(dis_var.Country_Code__c, new List<String>{districtStr});
                }
            }

            //SORT DISTRICT
            List<String> district_List;
            if(!district_set.isEmpty()){
                district_List = new List<String>(district_set);
                district_List.sort();
            }

            //SORT COUNTRY
            List<String> country_List;
            if(!district_set.isEmpty()){
                country_List = new List<String>(country_set);
                country_List.sort();
            }
            
            //QUERY LAST TEAM SYNCRONIZED
            DescribeSObjectResult objectDescribe = Last_Synchronization_OPG__c.getSObjectType().getDescribe();
            List<String> fields = new List<String> (objectDescribe.fields.getMap().keySet());
            String stringQuery = 'SELECT ' + String.join(fields, ',') + ' FROM Last_Synchronization_OPG__c';
            List<Last_Synchronization_OPG__c> get_teamLastSync = Database.query(stringQuery);
            
            //ASSIGN VALUES TO PRE-VALUES WRAPPER
            pv_var.district_set = district_List;
            pv_var.country_set = country_List;
            pv_var.lastSync_List = get_teamLastSync;
            pv_var.countryRegionMap_wrap = countryRegionMap;

            //PUT VALUES IN LIGHTNING RESPONSE HERE
            lResponse.status = 'SUCCESS';
            lResponse.returnValue = JSON.serialize(pv_var);
            
        } catch (Exception e){
            lResponse.status = 'ERROR';
            lResponse.message = 'Error: ' + e.getMessage() + '\nSTACK TRACE: ' + e.getStackTraceString();
        }

        return JSON.serialize(lResponse); 
    }

    @AuraEnabled
    public static String query_newFTE(String district){
        
        LightningResponse lResponse = new LightningResponse();
        Pre_Values_Wrapper pv_var = new Pre_Values_Wrapper();
		Boolean is3PO = district.isNumeric(); //IF NUMERIC THEN ITS FROM 3PO RESOURCE SAP NUMBER
          
        try{            
            //QUERY LAST TEAM SYNCRONIZED
            /* List<TS_LastSyncDateOPG__c> get_teamLastSync = new List<TS_LastSyncDateOPG__c>();
            get_teamLastSync = [SELECT Id, Name, Last_Sync_Date__c, Day_1__c, Day_2__c, Day_3__c, Day_4__c, Day_5__c, Day_6__c, Day_7__c, Day_8__c, Day_9__c, Day_10__c, Day_11__c, Day_12__c, Day_13__c, Day_14__c FROM TS_LastSyncDateOPG__c]; */
            
            //QUERY LAST TEAM SYNCRONIZED
            DescribeSObjectResult objectDescribe = Last_Synchronization_OPG__c.getSObjectType().getDescribe();
            List<String> fields = new List<String> (objectDescribe.fields.getMap().keySet());
            String stringQuery = 'SELECT ' + String.join(fields, ',') + ' FROM Last_Synchronization_OPG__c';
            List<Last_Synchronization_OPG__c> get_teamLastSync = Database.query(stringQuery);
            if(!is3PO){
                String country = countryName_map.get(district.substringBefore(' - '));
                //GET NUMBER OF BUSINESS DAYS PER MONTH
                Map<Integer, Integer> numberOfBusinessDaysPerMonth_cont = new Map<Integer, Integer>();
                Map<String, CountrySetting__c> countrySettingMap_Operating = new Map<String, CountrySetting__c>();
                List<String> recTypesSet = new List<String>{'Operating Task'};
                List<CountrySetting__c> cList = [SELECT Country__c, DefaultStartTime__c, DefaultEndTime__c, Business_Hours__c, From__c, To__c, RecordType.Name FROM CountrySetting__c WHERE Active__c = true AND RecordType.Name IN: recTypesSet];
                
                if(!cList.isEmpty()){
                    for(CountrySetting__c cset : cList){
                        if(cset.RecordType.Name == 'Operating Task') countrySettingMap_Operating.put(cset.Country__c, cset);
                    }
                }
    
                for(Integer i = 1; i <= 12; i++){
                    Integer numberDays = date.daysInMonth(Date.today().year(), i);
                    Integer totalVisits = 0;
                    Integer endhour =  countrySettingMap_Operating.get(country).DefaultEndTime__c == null ? 17 : Integer.valueOf(countrySettingMap_Operating.get(country).DefaultEndTime__c);
    
                    //ITERATE ALL DAYS WITHIN THE MONTH
                    for(Integer x = 1; x <= numberDays; x++){
                        Boolean isWithinBusinessHour = BusinessHours.isWithin(countrySettingMap_Operating.get(country).Business_Hours__c, DateTime.newInstance(Date.today().year(), i, x, endhour-2, 59, 59));                
                        if(isWithinBusinessHour) totalVisits++;
     
                    }
    
                    if(!numberOfBusinessDaysPerMonth_cont.containsKey(i)){
                        numberOfBusinessDaysPerMonth_cont.put(i, totalVisits);
                    }
                }
    
                //ASSIGN VALUES TO PRE-VALUES WRAPPER
                pv_var.numberOfBusinessDaysPerMonth = numberOfBusinessDaysPerMonth_cont;
        	}
            pv_var.lastSync_List = get_teamLastSync;
            
            //PUT VALUES IN LIGHTNING RESPONSE HERE
            lResponse.status = 'SUCCESS';
            lResponse.returnValue = JSON.serialize(pv_var);
            
        } catch (Exception e){
            lResponse.status = 'ERROR';
            lResponse.message = 'Error: ' + e.getMessage() + '\nSTACK TRACE: ' + e.getStackTraceString();
        }

        return JSON.serialize(lResponse); 
    }
    
    @AuraEnabled
    public static String get_accountLocationIds(String country, String district, Boolean showMachineWithoutSchedule, Boolean showUnassignedMachines, Boolean showCustomersWithoutRoutes, Boolean isFromPortal, String selectedResource){ //Karen Hung 3/2/2021 added parameter for DOO-5155
        
        LightningResponse lResponse = new LightningResponse();
        AccLoc_Id_Wrapper acc_wrap = new AccLoc_Id_Wrapper();
                
        try{
            
            Map<Id, Apttus_Config2__AccountLocation__c> map_acc = new Map<Id, Apttus_Config2__AccountLocation__c>();
            
            List<Route__c> route_list = new List<Route__c>();
            List<PhysicalAsset__c> pa_list = new List<PhysicalAsset__c>();
            List<PhysicalAsset__c> pa_list_opsched = new List<PhysicalAsset__c>();
            
            Set<String> accId_set = new Set<String>();
            Set<String> accId_set_unassigned = new Set<String>();
            Set<String> accId_set_noOpsched = new Set<String>();
            
            Set<String> all_combined = new Set<String>();
            //ACCESSED FROM INTERNAL
            if(!isFromPortal){                          
                String subStr = district.substringAfter(' - ');
                String subStr_country = district.substringBefore(' - ');
                List<TS_Hierarchy_Derivation__mdt> get_postCodes = [SELECT Id, District__c, Postal_Code__c FROM TS_Hierarchy_Derivation__mdt WHERE District__r.Label =: subStr];
                Set<String> postCode_set = new Set<String>();
                if(!get_postCodes.isEmpty()){
                    for(TS_Hierarchy_Derivation__mdt var: get_postCodes){
                        postCode_set.add(var.Postal_Code__c + '%');
                    }
                }                      
                
                //XEN REYES DOO-4289 April 8, 2020                
                if(!showCustomersWithoutRoutes){                   
                    //ALL ACCOUNTLOCATION WITH ROUTE RELATED TO THIRD PARTY
                    if(selectedResource != null && selectedResource.length() > 5){                                  
                        route_list = [SELECT Id, Account_Location__c,Account_Location__r.Third_Party_Resource__c FROM Route__c 
                                      WHERE Account_Location__r.Account_Location_Status__c = 'Valid'
                                      AND Account_Location__r.Third_Party_Resource__r.Name =:selectedResource                                                                              
                                     ];  
                        
                    }
                    //ALL ACCOUNTLOCATION WITH ROUTE RELATED TO TEAM
                    else if(!postCode_set.isEmpty()){                             
                        route_list = [SELECT Id, Account_Location__c,Account_Location__r.Third_Party_Resource__c FROM Route__c 
                                      WHERE Account_Location__r.Account_Location_Status__c = 'Valid'
                                      AND Account_Location__r.Apttus_Config2__PostalCode__c LIKE :postCode_set 
                                      AND Account_Location__r.Mini_Sales_Organization__c =: countryName_map.get(subStr_country)
                                      //AND Id IN (SELECT RouteId__c FROM Route_Line_Item__c)
                                     ];   
                    }                                      
                    if(!route_list.isEmpty()){                                      
                        for(Route__c rs_var : route_list){
                            accId_set.add(rs_var.Account_Location__c);
                        }
                    } 
                                    
                } 
                else {     
                    List<PhysicalAsset__c> unassignedList = new List<PhysicalAsset__c>();                    
                    //3. INTERNAL + THIRD PARTY RESOURCE + CUSTOMER WITHOUT ROUTE
                    if(selectedResource != null && selectedResource.length() > 5){   
                        
                        Map<Id, Apttus_Config2__AccountLocation__c> map_accNoRoute = new Map<Id, Apttus_Config2__AccountLocation__c>();          
                        map_accNoRoute = new Map<Id, Apttus_Config2__AccountLocation__c>([SELECT Id FROM Apttus_Config2__AccountLocation__c WHERE Account_Location_Status__c = 'Valid' AND Third_Party_Resource__r.Name =:selectedResource 
                                                                                          AND Id NOT IN (SELECT Account_Location__c FROM Route__c WHERE Account_Location__r.Account_Location_Status__c = 'Valid' AND Account_Location__r.Third_Party_Resource__r.Name =:selectedResource)]);                       
                        
                        List<PhysicalAsset__c> paList = [SELECT Id, AccountLocation__c
                                                     FROM PhysicalAsset__c
                                                     WHERE AccountLocation__c IN: map_accNoRoute.keySet()                                                     
                                                     AND Recordtype.Name = :TS_Constants.PA_RECTYPE_MACHINE
                                                     AND AssetStatus__c IN (:TS_Constants.PA_STATUS_ACTIVATED, :TS_Constants.PA_STATUS_PENDINGCANCELATION)
                                                     AND Machine_Care__c IN (:TS_Constants.FULL_OPERATING , :TS_Constants.COMFORT_OPERATING, :TS_Constants.MACHINE_CLEAN_OPERATING)
                                                     AND MothballAssetIndicator__c = FALSE
                                                     AND EndDate__c >=: Date.today()
                                                     AND Machine_Care__c != null];      
                        /* DOO-5445 XEN REYES */
                        /* unassignedList = [SELECT Id, Name, Building__c, Floor__c, Area__c, CustomerReferenceNumber__c, OP_PreferredOperator__c, OP_PreferredOperator__r.Name, AccountLocation__c, AccountLocation__r.Third_Party_Resource__c 
                                          FROM PhysicalAsset__c
                                          WHERE Id IN :paList 
                                          AND Id NOT IN (SELECT PhysicalAssetId__c FROM Route_Line_Item__c WHERE PhysicalAssetId__c IN :paList)                                          
                                          ORDER BY CreatedDate DESC]; */
                                    
                        if(!paList.isEmpty()){
                            for(PhysicalAsset__c pa_var : paList){
                                all_combined.add(pa_var.AccountLocation__c);
                            }     
                        }                                           
                    }                    
                    else {                            
                        //3. INTERNAL + TEAM + CUSTOMER WITHOUT ROUTE
                        if(!postCode_set.isEmpty()){                                                    
                            Map<Id, Apttus_Config2__AccountLocation__c> map_accNoRoute = new Map<Id, Apttus_Config2__AccountLocation__c>();          
                            map_accNoRoute = new Map<Id, Apttus_Config2__AccountLocation__c>([SELECT Id FROM Apttus_Config2__AccountLocation__c WHERE Apttus_Config2__PostalCode__c LIKE :postCode_set AND Account_Location_Status__c = 'Valid' AND Mini_Sales_Organization__c =: countryName_map.get(subStr_country) 
                                                                                              AND Id NOT IN (SELECT Account_Location__c FROM Route__c WHERE Account_Location__r.Apttus_Config2__PostalCode__c LIKE :postCode_set AND Account_Location__r.Account_Location_Status__c = 'Valid' AND Account_Location__r.Mini_Sales_Organization__c =: countryName_map.get(subStr_country))]);                       
                            List<PhysicalAsset__c> paList = [SELECT Id, AccountLocation__c
                                                     FROM PhysicalAsset__c
                                                     WHERE AccountLocation__c IN: map_accNoRoute.keySet()
                                                     AND Recordtype.Name = :TS_Constants.PA_RECTYPE_MACHINE
                                                     AND AssetStatus__c IN (:TS_Constants.PA_STATUS_ACTIVATED, :TS_Constants.PA_STATUS_PENDINGCANCELATION)
                                                     AND Machine_Care__c IN (:TS_Constants.FULL_OPERATING , :TS_Constants.COMFORT_OPERATING, :TS_Constants.MACHINE_CLEAN_OPERATING)
                                                     AND MothballAssetIndicator__c = FALSE
                                                     AND EndDate__c >=: Date.today()
                                                     AND Machine_Care__c != null];         
                            
                            /* DOO-5445 XEN REYES */
                            /* unassignedList = [SELECT Id, Name, Building__c, Floor__c, Area__c, CustomerReferenceNumber__c, OP_PreferredOperator__c, OP_PreferredOperator__r.Name, AccountLocation__c, AccountLocation__r.Third_Party_Resource__c 
                                              FROM PhysicalAsset__c
                                              WHERE Id IN :paList 
                                              AND Id NOT IN (SELECT PhysicalAssetId__c FROM Route_Line_Item__c WHERE PhysicalAssetId__c IN :paList)                                              
                                              ORDER BY CreatedDate DESC]; */

                            if(!paList.isEmpty()){
                                for(PhysicalAsset__c pa_var : paList){
                                    all_combined.add(pa_var.AccountLocation__c);
                                }     
                            }

                        }                                                            
                    }                                    
                }               
       
                //GET ACCOUNT LOCATION WITH UNASSIGNED MACHINES                
                if(showUnassignedMachines){                                          
                    List<PhysicalAsset__c> unassignedList = new List<PhysicalAsset__c>();
                    //2. INTERNAL + THIRD PARTY RESOURCE + SHOW UNASSIGNED MACHINES
                    if(selectedResource != null && selectedResource.length() > 5){     
                        //ACCLOC FROM SCENARIO 3.
                        Map<Id, Apttus_Config2__AccountLocation__c> map_accNoRoute = new Map<Id, Apttus_Config2__AccountLocation__c>();          
                        map_accNoRoute = new Map<Id, Apttus_Config2__AccountLocation__c>([SELECT Id FROM Apttus_Config2__AccountLocation__c WHERE Account_Location_Status__c = 'Valid' AND Third_Party_Resource__r.Name =:selectedResource 
                                                                                          AND Id IN (SELECT Account_Location__c FROM Route__c WHERE Account_Location__r.Account_Location_Status__c = 'Valid' AND Account_Location__r.Third_Party_Resource__r.Name =:selectedResource)]);                       

                        List<PhysicalAsset__c> paList = [SELECT Id, AccountLocation__c 
                                                     FROM PhysicalAsset__c
                                                     WHERE 
                                                        (AccountLocation__r.Third_Party_Resource__r.Name =:selectedResource
                                                     	AND Recordtype.Name = :TS_Constants.PA_RECTYPE_MACHINE
                                                     	AND AssetStatus__c IN (:TS_Constants.PA_STATUS_ACTIVATED, :TS_Constants.PA_STATUS_PENDINGCANCELATION)
                                                     	AND Machine_Care__c IN (:TS_Constants.FULL_OPERATING , :TS_Constants.COMFORT_OPERATING, :TS_Constants.MACHINE_CLEAN_OPERATING)
                                                     	AND MothballAssetIndicator__c = FALSE
                                                        AND EndDate__c >=: Date.today()
                                                        AND Machine_Care__c != null)
                                                        //OR 
                                                        //(AccountLocation__c IN:map_accNoRoute.keySet())
                                                        ];

                        unassignedList = [SELECT Id, Name, Building__c, Floor__c, Area__c, CustomerReferenceNumber__c, OP_PreferredOperator__c, OP_PreferredOperator__r.Name, AccountLocation__c, AccountLocation__r.Third_Party_Resource__c
                                          FROM PhysicalAsset__c
                                          WHERE 
                                          Id IN :paList
                                          AND Id NOT IN (SELECT PhysicalAssetId__c FROM Route_Line_Item__c WHERE PhysicalAssetId__c IN :paList)
                                          ORDER BY CreatedDate DESC];
                    }

                    //2. INTERNAL + TEAM + SHOW UNASSIGNED MACHINES
                    else {
                        //ACCLOC FROM SCENARIO 3.
                        Map<Id, Apttus_Config2__AccountLocation__c> map_accNoRoute = new Map<Id, Apttus_Config2__AccountLocation__c>();          
                        map_accNoRoute = new Map<Id, Apttus_Config2__AccountLocation__c>([SELECT Id FROM Apttus_Config2__AccountLocation__c WHERE Apttus_Config2__PostalCode__c LIKE :postCode_set AND Account_Location_Status__c = 'Valid' AND Mini_Sales_Organization__c =: countryName_map.get(subStr_country) 
                                                                                              AND Id IN (SELECT Account_Location__c FROM Route__c WHERE Account_Location__r.Apttus_Config2__PostalCode__c LIKE :postCode_set AND Account_Location__r.Account_Location_Status__c = 'Valid' AND Account_Location__r.Mini_Sales_Organization__c =: countryName_map.get(subStr_country))]);                       

                        List<PhysicalAsset__c> paList = [SELECT Id, AccountLocation__c 
                                                     FROM PhysicalAsset__c
                                                     WHERE 
                                                         (AccountLocation__r.Apttus_Config2__PostalCode__c LIKE :postCode_set AND AccountLocation__r.Account_Location_Status__c = 'Valid' AND AccountLocation__r.Mini_Sales_Organization__c =: countryName_map.get(subStr_country)
                                                     	 AND Recordtype.Name = :TS_Constants.PA_RECTYPE_MACHINE
                                                     	 AND AssetStatus__c IN (:TS_Constants.PA_STATUS_ACTIVATED, :TS_Constants.PA_STATUS_PENDINGCANCELATION)
                                                     	 AND Machine_Care__c IN (:TS_Constants.FULL_OPERATING , :TS_Constants.COMFORT_OPERATING, :TS_Constants.MACHINE_CLEAN_OPERATING)
                                                     	 AND MothballAssetIndicator__c = FALSE
                                                         AND EndDate__c >=: Date.today()
                                                         AND Machine_Care__c != null)
                                                         //OR 
                                                         //(AccountLocation__c IN:map_accNoRoute.keySet())
                                                         ];

                        unassignedList = [SELECT Id, Name, Building__c, Floor__c, Area__c, CustomerReferenceNumber__c, OP_PreferredOperator__c, OP_PreferredOperator__r.Name, 
                                            AccountLocation__c, AccountLocation__r.Third_Party_Resource__c
                                          FROM PhysicalAsset__c
                                          WHERE 
                                          Id IN :paList 
                                          AND Id NOT IN (SELECT PhysicalAssetId__c FROM Route_Line_Item__c WHERE PhysicalAssetId__c IN :paList)
                                          ORDER BY CreatedDate DESC];

                    }
                    
                    if(!unassignedList.isEmpty()){
                        for(PhysicalAsset__c pa_var : unassignedList){
                            accId_set_unassigned.add(pa_var.AccountLocation__c);                        
                        }     
                    }
                                   
                }          

                else if (showMachineWithoutSchedule){      
                    //1. INTERNAL + THIRD PARTY RESOURCE + SHOW MACHINE WITHOUT SCHEDULE
                    if(selectedResource != null && selectedResource.length() > 5){    
                        List<PhysicalAsset__c> withoutOpsched = [SELECT Id, Name, Building__c, Floor__c, Area__c, CustomerReferenceNumber__c, OP_PreferredOperator__c, OP_PreferredOperator__r.Name, AccountLocation__c, AccountLocation__r.Third_Party_Resource__c 
                                                             FROM PhysicalAsset__c
                                                             WHERE AccountLocation__r.Third_Party_Resource__r.Name =:selectedResource
                                                             AND Recordtype.Name = :TS_Constants.PA_RECTYPE_MACHINE
                                                             AND AssetStatus__c IN (:TS_Constants.PA_STATUS_ACTIVATED, :TS_Constants.PA_STATUS_PENDINGCANCELATION)
                                                             AND Machine_Care__c IN (:TS_Constants.FULL_OPERATING , :TS_Constants.COMFORT_OPERATING, :TS_Constants.MACHINE_CLEAN_OPERATING)
                                                             AND MothballAssetIndicator__c = FALSE
                                                             AND EndDate__c >=: Date.today()
                                                             AND Machine_Care__c != null
                                                             AND Id NOT IN (SELECT PhysicalAsset__c FROM OperatingSchedule__c 
                                                                            WHERE OperatingReady__c = true)];
                        
                        if(!withoutOpsched.isEmpty()){
                            for(PhysicalAsset__c pa_var : withoutOpsched){
                                accId_set_noOpsched.add(pa_var.AccountLocation__c);                      
                            }
                        }
                    }
                    //1. INTERNAL + TEAM + SHOW MACHINE WITHOUT SCHEDULE
                    else {
                        List<PhysicalAsset__c> withoutOpsched = [SELECT Id, Name, Building__c, Floor__c, Area__c, CustomerReferenceNumber__c, OP_PreferredOperator__c, OP_PreferredOperator__r.Name, AccountLocation__c, AccountLocation__r.Third_Party_Resource__c 
                                                             FROM PhysicalAsset__c
                                                             WHERE AccountLocation__c IN: accId_set
                                                             AND Recordtype.Name = :TS_Constants.PA_RECTYPE_MACHINE
                                                             AND AssetStatus__c IN (:TS_Constants.PA_STATUS_ACTIVATED, :TS_Constants.PA_STATUS_PENDINGCANCELATION)
                                                             AND Machine_Care__c IN (:TS_Constants.FULL_OPERATING , :TS_Constants.COMFORT_OPERATING, :TS_Constants.MACHINE_CLEAN_OPERATING)
                                                             AND MothballAssetIndicator__c = FALSE
                                                             AND EndDate__c >=: Date.today()
                                                             AND Machine_Care__c != null
                                                             AND Id NOT IN (SELECT PhysicalAsset__c FROM OperatingSchedule__c 
                                                                            WHERE OperatingReady__c = true)];
                        
                        if(!withoutOpsched.isEmpty()){
                            for(PhysicalAsset__c pa_var : withoutOpsched){
                                accId_set_noOpsched.add(pa_var.AccountLocation__c);                      
                            }
                        }
                    }                                                    
                }                                                                                                         
            }//END INTERNAL
            
            //ACCESSED FROM PORTAL
            else{                        
                String userId = UserInfo.getUserId();
                
                //XEN REYES DOO-4289 April 8, 2020
                //PORTAL + THIRD PARTY
                if(!showCustomersWithoutRoutes){           
                    //ALL ACCOUNTLOCATION FROM ROUTE RELATED TO THIRD PARTY
                    route_list = [SELECT Id, Account_Location__c,Account_Location__r.Third_Party_Resource__c FROM Route__c WHERE Account_Location__r.Account_Location_Status__c = 'Valid' 
                                  AND Account_Location__r.Third_Party_Resource__r.RelatedUser__c =:userId
                                 ];

                    if(!route_list.isEmpty()){
                        for(Route__c rs_var : route_list){
                            accId_set.add(rs_var.Account_Location__c);
                        }
                    }                    
                } 

                //3. PORTAL + THIRD PARTY + SHOW CUSTOMER WITHOUT ROUTES
                else {                                      
                    Map<Id, Apttus_Config2__AccountLocation__c> map_accNoRoute = new Map<Id, Apttus_Config2__AccountLocation__c>([SELECT Id FROM Apttus_Config2__AccountLocation__c WHERE Account_Location_Status__c = 'Valid' AND Third_Party_Resource__r.RelatedUser__c =:userId 
                                                                                                                                  AND Id NOT IN (SELECT Account_Location__c FROM Route__c WHERE Account_Location__r.Account_Location_Status__c = 'Valid' AND Account_Location__r.Third_Party_Resource__r.RelatedUser__c =:userId )]);                                                    
                    List<PhysicalAsset__c> paList = [SELECT Id, AccountLocation__c
                                                     FROM PhysicalAsset__c
                                                     WHERE AccountLocation__c IN: map_accNoRoute.keySet()                                                     
                                                     AND Recordtype.Name = :TS_Constants.PA_RECTYPE_MACHINE
                                                     AND AssetStatus__c IN (:TS_Constants.PA_STATUS_ACTIVATED, :TS_Constants.PA_STATUS_PENDINGCANCELATION)
                                                     AND Machine_Care__c IN (:TS_Constants.FULL_OPERATING , :TS_Constants.COMFORT_OPERATING, :TS_Constants.MACHINE_CLEAN_OPERATING)
                                                     AND MothballAssetIndicator__c = FALSE
                                                     AND EndDate__c >=: Date.today()
                                                     AND Machine_Care__c != null];

                    /* DOO-5445 XEN REYES */
                    /* List<PhysicalAsset__c> unassignedList = [SELECT Id, Name, Building__c, Floor__c, Area__c, CustomerReferenceNumber__c, OP_PreferredOperator__c, OP_PreferredOperator__r.Name, AccountLocation__c, AccountLocation__r.Third_Party_Resource__c 
                                      FROM PhysicalAsset__c
                                      WHERE Id IN :paList                                       
                                      AND Id NOT IN (SELECT PhysicalAssetId__c FROM Route_Line_Item__c WHERE PhysicalAssetId__c IN :paList)
                                      ORDER BY CreatedDate DESC]; */

                    if(!paList.isEmpty()){
                        for(PhysicalAsset__c pa_var : paList){
                            all_combined.add(pa_var.AccountLocation__c);
                        }
                    }

                }
                //2. PORTAL + THIRD PARTY + SHOW UNASSIGNED MACHINES
                if(showUnassignedMachines){                  
                    //ACCLOC FROM SCENARIO 3.
                    Map<Id, Apttus_Config2__AccountLocation__c> map_accNoRoute = new Map<Id, Apttus_Config2__AccountLocation__c>([SELECT Id FROM Apttus_Config2__AccountLocation__c WHERE Account_Location_Status__c = 'Valid' AND Third_Party_Resource__r.RelatedUser__c =:userId 
                                                                                                                                  AND Id IN (SELECT Account_Location__c FROM Route__c WHERE Account_Location__r.Account_Location_Status__c = 'Valid' AND Account_Location__r.Third_Party_Resource__r.RelatedUser__c =:userId )]);                                                    
                    List<PhysicalAsset__c> paList = [SELECT Id, AccountLocation__c 
                                                     FROM PhysicalAsset__c                                                     
                                                     WHERE 
                                                     	(AccountLocation__r.Third_Party_Resource__r.RelatedUser__c =:userId
                                                     	AND Recordtype.Name = :TS_Constants.PA_RECTYPE_MACHINE
                                                     	AND AssetStatus__c IN (:TS_Constants.PA_STATUS_ACTIVATED, :TS_Constants.PA_STATUS_PENDINGCANCELATION)
                                                     	AND Machine_Care__c IN (:TS_Constants.FULL_OPERATING , :TS_Constants.COMFORT_OPERATING, :TS_Constants.MACHINE_CLEAN_OPERATING)
                                                     	AND MothballAssetIndicator__c = FALSE
                                                        AND EndDate__c >=: Date.today()
                                                        AND Machine_Care__c != null)
													    //OR 
                                                        //(AccountLocation__c IN:map_accNoRoute.keySet())
                                                        ];
  
                    List<PhysicalAsset__c> unassignedList = [SELECT Id, Name, Building__c, Floor__c, Area__c, CustomerReferenceNumber__c, OP_PreferredOperator__c, OP_PreferredOperator__r.Name, AccountLocation__c, AccountLocation__r.Third_Party_Resource__c
                                      FROM PhysicalAsset__c
                                      WHERE 
                                      Id IN :paList 
                                      AND Id NOT IN (SELECT PhysicalAssetId__c FROM Route_Line_Item__c WHERE PhysicalAssetId__c IN :paList)                                      
                                      ORDER BY CreatedDate DESC];                    
                    
                    if(!unassignedList.isEmpty()){
                        for(PhysicalAsset__c pa_var : unassignedList){
                            accId_set_unassigned.add(pa_var.AccountLocation__c);                        
                        }
                    }
                    
                } 
                //1. PORTAL + THIRD PARTY + SHOW MACHINE WITHOUT SCHEDULE
                else if (showMachineWithoutSchedule){                                          
                    List<PhysicalAsset__c> withoutOpsched = new List<PhysicalAsset__c>();           
                    withoutOpsched = [SELECT Id, Name, Building__c, Floor__c, Area__c, CustomerReferenceNumber__c, OP_PreferredOperator__c, OP_PreferredOperator__r.Name, AccountLocation__c, AccountLocation__r.Third_Party_Resource__c 
                                      FROM PhysicalAsset__c
                                      WHERE AccountLocation__c IN: accId_set                                      
                                      AND Recordtype.Name = :TS_Constants.PA_RECTYPE_MACHINE
                                      AND AssetStatus__c IN (:TS_Constants.PA_STATUS_ACTIVATED, :TS_Constants.PA_STATUS_PENDINGCANCELATION)
                                      AND Machine_Care__c IN (:TS_Constants.FULL_OPERATING , :TS_Constants.COMFORT_OPERATING, :TS_Constants.MACHINE_CLEAN_OPERATING)
                                      AND MothballAssetIndicator__c = FALSE
                                      AND EndDate__c >=: Date.today()
                                      AND Machine_Care__c != null
                                      AND Id NOT IN (SELECT PhysicalAsset__c FROM OperatingSchedule__c 
                                                     WHERE OperatingReady__c = true)];                    
                    
                    if(!withoutOpsched.isEmpty()){
                        for(PhysicalAsset__c pa_var : withoutOpsched){
                            accId_set_noOpsched.add(pa_var.AccountLocation__c);                      
                        }
                    }
                    
                }                 
            }//END PORTAL
                        
            acc_wrap.accId_set = new List<String>(accId_set);
            acc_wrap.accId_set_unassigned = new List<String>(accId_set_unassigned);
            acc_wrap.accId_set_noOpsched = new List<String>(accId_set_noOpsched);
            
            //COMBINE ALL IDS - UNFILTERED + ALL FILTERS
            if(!showUnassignedMachines && !showMachineWithoutSchedule) all_combined.addAll(accId_set);
            if(showUnassignedMachines && !showMachineWithoutSchedule) all_combined.addAll(accId_set_unassigned);
            if(!showUnassignedMachines && showMachineWithoutSchedule) all_combined.addAll(accId_set_noOpsched);
            acc_wrap.all_combined = new List<String>(all_combined);
            
            lResponse.status = 'SUCCESS';

            if(!all_combined.isEmpty()){

                //SORT BY ACCOUNT LOCATION NAME FIRST                
                List<String> list_cont = new List<String>();
                for(Apttus_Config2__AccountLocation__c accVar : [SELECT Id, Name FROM Apttus_Config2__AccountLocation__c WHERE Id IN: all_combined ORDER BY NAME ASC]){
                    list_cont.add(accVar.Id);
                }
                acc_wrap.all_combined = list_cont;

                lResponse.returnValue = JSON.serialize(acc_wrap);

            } else { 

                lResponse.status = TS_Constants.GENERAL_ERROR;

                if(showUnassignedMachines){
                    lResponse.message = TS_Constants.ERROR_MESSAGE_ALLMACHINEASSIGNED;
                } else if(showMachineWithoutSchedule) {
                    lResponse.message = TS_Constants.ERROR_MESSAGE_ALLMACHINEOPERATINGSCHED;
                } else if(showCustomersWithoutRoutes) {
                    lResponse.message = TS_Constants.ERROR_MESSAGE_NOROUTES;
                } else {
                    lResponse.message = TS_Constants.ERROR_MESSAGE_NOACCOUNTLOCATIONFOUND;
                }
            }
            
        } catch (Exception e){
            lResponse.status = TS_Constants.GENERAL_ERROR;
            lResponse.message = 'Error: ' + e.getMessage() + '\nSTACK TRACE: ' + e.getStackTraceString();
        }

        return JSON.serialize(lResponse); 
    }

    @AuraEnabled
    public static String executeRecalculationBatch(String team, Boolean isAllRegion, List<String> teams, Boolean isNordicsParam, String thirdPartyResource, String filterType){

        LightningResponse lResponse = new LightningResponse();

        //CHECK IF THE SAME JOB IS RUNNING
        List<AsyncApexJob> calculationJob = [SELECT Id, ApexClassID 
                                            FROM AsyncApexJob 
                                            WHERE Status IN ('Processing', 'Preparing', 'Queued', 'Holding') 
                                            AND ApexClassId IN (SELECT Id FROM ApexClass WHERE Name = 'TS_OperatingOptimizerCalculator_Batch') 
                                            LIMIT 1000];

        //COUNT THE PROCESSING JOBS AND THOSE IN QUEUE
        Integer batchCount_ProcessingPreparing = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Processing\', \'Preparing\') LIMIT 1000');
        Integer batchCount_HoldingQueued = Database.countQuery('SELECT count() FROM AsyncApexJob WHERE JobType=\'BatchApex\' AND Status IN (\'Queued\', \'Holding\') LIMIT 1000');

        if(!isAllRegion){

            if((calculationJob.isEmpty() && (batchCount_ProcessingPreparing < 5 || batchCount_HoldingQueued < 100)) || Test.isRunningTest()){
                TS_OperatingOptimizerCalculator_Batch batchCalculator_var = new TS_OperatingOptimizerCalculator_Batch(team);
                batchCalculator_var.isNordics = isNordicsParam;
                batchCalculator_var.thirdPartyResource = thirdPartyResource;
                batchCalculator_var.filterType = filterType;
                Database.executeBatch(batchCalculator_var, 100);

                lResponse.status = TS_Constants.RECALCULATE_SUCCESS;
                lResponse.message = TS_Constants.RECALCULATE_SUCCESS_MESSAGE;
            } else {
                lResponse.status = TS_Constants.RECALCULATE_ERROR;
                lResponse.message = TS_Constants.RECALCULATE_ERROR_MESSAGE;
            }

        } else {

            if((batchCount_ProcessingPreparing < 5 || batchCount_HoldingQueued < 100) || Test.isRunningTest()){                     
                String newTeam = teams[0];
                
                //REMOVED LOOP 03/16/2021 Francis Allen Alindogan
                TS_OperatingOptimizerCalculator_Batch batchCalculator_var = new TS_OperatingOptimizerCalculator_Batch(newTeam);
                batchCalculator_var.isNordics = isNordicsParam;
                batchCalculator_var.thirdPartyResource = thirdPartyResource;
                batchCalculator_var.filterType = filterType;              
                teams.remove(0);
                batchCalculator_var.unfinishedTeams = teams; //ALL TEAMS EXCEPT teams[0]
                Database.executeBatch(batchCalculator_var, 100);
                
                lResponse.status = TS_Constants.RECALCULATE_SUCCESS;
                lResponse.message = TS_Constants.RECALCULATE_SUCCESS_MESSAGE;                
            } else {
                lResponse.status = TS_Constants.RECALCULATE_ERROR;
                lResponse.message = TS_Constants.RECALCULATE_ERROR_MESSAGE;
            }
        }
        
        return JSON.serialize(lResponse);
    }
    
    /*get list of resource*/
    @AuraEnabled
    public static String get3pResource(Boolean isFromPortal){
        LightningResponse lResponse = new LightningResponse();
        
        try{
            
            TS_OperatingOptimizerTabController.TS_OptimizerTabControllerWithoutSharing cc = new TS_OperatingOptimizerTabController.TS_OptimizerTabControllerWithoutSharing();
            List<Resource__c> resourceList = new List<Resource__c>();
            if(isFromPortal){
                resourceList = cc.getResourceListPortal(); 
            }else{    
                resourceList = cc.getResourceList();   
            }  
           
            lResponse.returnValue = JSON.serialize(resourceList);
            
        }catch (Exception e){
            lResponse.status = 'ERROR';
            lResponse.message = 'Error: ' + e.getMessage() + '\nSTACK TRACE: ' + e.getStackTraceString();
        }
        
        return JSON.serialize(lResponse);
    }
    
    /*get list of resource*/
    @AuraEnabled
    public static String checkFeatureFlag(){
        LightningResponse lResponse = new LightningResponse();
        
        try{
            
            TS_OperatingOptimizerTabController.TS_OptimizerTabControllerWithoutSharing cc = new TS_OperatingOptimizerTabController.TS_OptimizerTabControllerWithoutSharing();
            Boolean enabledFeature = false;
            enabledFeature = cc.getFlagEnabled(); 
           
            lResponse.returnValue = JSON.serialize(enabledFeature);
            
        }catch (Exception e){
            lResponse.status = 'ERROR';
            lResponse.message = 'Error: ' + e.getMessage() + '\nSTACK TRACE: ' + e.getStackTraceString();
        }
        
        return JSON.serialize(lResponse);
    }

    /**
    * @author         Karen Hung 
    * @date           2/2/2021
    * @description    DOO-5155 Without Sharing inner class to access data info of third party resource list
    * @revision(s)
    */
    public without sharing class TS_OptimizerTabControllerWithoutSharing {
        
        /*check featureflag if enabled*/
        @AuraEnabled
        public Boolean getFlagEnabled(){
          CustomLogging.push('TS_OptimizerTabControllerWithoutSharing.getFlagEnabled', 'TS_OperatingOptimizerTabController'); 
            Boolean enabledFeature = false;
            Map<Id,TS_Feature_Flag__mdt> featureFlags =  new Map<Id,TS_Feature_Flag__mdt>([SELECT Id, QualifiedApiName, Enable__c FROM TS_Feature_Flag__mdt WHERE QualifiedApiName != null]);
            if(!featureFlags.isEmpty()){
                for(TS_Feature_Flag__mdt flag : featureFlags.values()){
                    if(flag.QualifiedApiName == 'DOO_5155_ShowThirdPartyList' && flag.Enable__c){
                      enabledFeature= true;    
                    }
                }
            }
            CustomLogging.pop();
            return enabledFeature;
        }
        
        /*get third party resource list from account locations for NON-PORTAL*/
        @AuraEnabled
        public List<Resource__c> getResourceList(){
            CustomLogging.push('TS_OptimizerTabControllerWithoutSharing.getResourceList', 'TS_OperatingOptimizerTabController');
            
            List<Resource__c> resList = new List<Resource__c>();
            resList = [SELECT Id, Name, EmployeeFirstName__c, EmployeeLastName__c FROM Resource__c WHERE Id IN (SELECT Third_Party_Resource__c FROM Apttus_Config2__AccountLocation__c WHERE Third_Party_Resource__c != NULL)];
                        
            CustomLogging.pop();
            return resList;
        }
        
        /*get third party resource list from account locations for PORTAL*/
        @AuraEnabled
        public List<Resource__c> getResourceListPortal(){
            CustomLogging.push('TS_OptimizerTabControllerWithoutSharing.getResourceListPortal', 'TS_OperatingOptimizerTabController');
            
            String userId = UserInfo.getUserId();
            List<Resource__c> resList = new List<Resource__c>();
            resList = [SELECT Id, Name, EmployeeFirstName__c, EmployeeLastName__c FROM Resource__c WHERE RelatedUser__c =:userId];
                        
            CustomLogging.pop();
            return resList;
        }
    }
}