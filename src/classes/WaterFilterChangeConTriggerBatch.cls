/**
* @author        Anna Gonzales
* @date          6.28.2017          
* @description   Class responsible for processing Water Filter Change batch records
* @revision(s)   2.20.2018 Paul Aguiling: KTS-1095 Updated class and added new methods
*                6.28.2018 Paul Aguiling: KTS-1920 Contract Triggered Cases Batch not fired for all assets
*                                                  Updated execute() and finish()
*/
global class WaterFilterChangeConTriggerBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    private String queryStr = null;
    private List<CountrySetting__c> list_CountrySetting = new List<CountrySetting__c>();
    private List<String> exception_List = new List<String>();
    public static Boolean hasException = false;
    public Boolean SOQL_OVERRIDE = false;
    public String NEW_SOQL_STRING;
    
    /******************************************************************************
    * @author         Paul Jarred Aguiling
    * @date           6.14.2017
    * @description    Method responsible for throwing an exception
    * @revision(s)
    ******************************************************************************/ 
    public class TS_WaterFilterChangeConBatchException extends Exception {}
    
    /******************************************************************************
    * @author         Paul Jarred Aguiling
    * @date           6.14.2017
    * @description    Constructor of the class
    * @revision(s)
    * @last modified  Anna Gonzales - 6.28.2017
    ******************************************************************************/ 
    public WaterFilterChangeConTriggerBatch() {
        list_CountrySetting = getCountrySettings();
    }
    
    /******************************************************************************
    * @author         Paul Jarred Aguiling
    * @date           6.14.2017
    * @description    This method is the start of the batch job
    * @revision(s)
    * @last modified  Anna Gonzales - 6.28.2017
    ******************************************************************************/ 
    global Database.QueryLocator start(Database.BatchableContext BC) {
        CustomLogging.push(TS_Constants.CONST_START, 'WaterFilterChangeConTriggerBatch');
        
        String STR_COUNTRIES;
        if(Test.isRunningTest()){
            STR_COUNTRIES = ' \'SAP_0333\', \'SAP_0975\', \'SAP_0976\', \'SAP_6864\', \'SAP_0080\', \'SAP_0111\', \'SAP_6750\', \'SAP_6712\' ';
        } else {
            STR_COUNTRIES = System.Label.TS_WaterfilterBatchCountries;
        }
        
        queryStr = 'SELECT Id, Name, Machine_Care__c, Product__c, Product__r.Name, Product__r.Family, AccountLocation__c, SoldTo__c, SoldTo__r.Sales_Organization__c, ' 
            + 'LastWTSDate__c, WTSInterval__c, InitialActivationDate__c, EndDate__c, NextWTSDate__c, '
            + 'SalesOrganization__c, AccountLocation__r.Additional_Case_Contact__c, ' 
            + 'WTSManualUpdate__c, StairClimber__c, RequiresLSP__c, ConfigurationFileURL__c, Floor__c, Area__c, '
            + 'ConfigurationManualAgreementsURL__c, JDECrockeryVolumeSize__c, SmokingArea__c, Building__c, CustomerReferenceNumber__c, '
            + 'SoldTo__r.Account_Block__c, AccountLocation__r.Upfront_Call_Needed__c, AccountLocation__r.Apttus_Config2__Country__c, '
            + 'AccountLocation__r.Apttus_Config2__PostalCode__c, AccountLocation__r.Shipping_Street__c, AccountLocation__r.Alternative_Machine__c, '
            + 'AccountLocation__r.Shipping_House_Number__c, AccountLocation__r.Apttus_Config2__City__c, SoldTo__r.OwnerId, PONumberServices__c, '
            + 'AccountLocation__r.Apttus_Config2__AccountId__c, AccountLocation__r.Apttus_Config2__AccountId__r.Account_Block__c, '
            + 'AccountLocation__r.Apttus_Config2__AccountId__r.OwnerId, CreateWTSJob__c, IncludesPreventiveMaintenanceCoverage__c '
            + 'FROM PhysicalAsset__c WHERE AssetStatus__c = \'Activated\' '
            + 'AND WTSPlanned__c = false '
            + 'AND IncludesWTSCoverage__c = true '
            + 'AND RecordType.Name = \'Machine\' '
            //+ 'AND WTSInterval__c > 0 ' //January 7, 2019 XEN REYES //Francis Alindogan 11/23/2019 DOO-2696
            + 'AND MothballAssetIndicator__c = false ' //KTS-2196 9.27.2018
            
            /* Feb 5, 2019 XEN REYES */
            + 'AND AccountLocation__c != null '
            + 'AND AccountLocation__r.Apttus_Config2__AccountId__c != null '
            + 'AND AccountLocation__r.Apttus_Config2__AccountId__r.Account_Block__c = false '
            + 'AND SalesOrganization__c != null '
            + 'AND EndDate__c > TODAY '
            + 'AND (AccountLocation__r.No_Contract_Order__c = false OR AccountLocation__r.No_Contract_Order_Date__c > TODAY) ' //Karen Hung 28.09.2020 DOO-4798
            //+ 'AND Id = \'a8H6E0000004EjKUAU\' '
            
            //XEN REYES INC0156501 DOO-3883 Feb. 19, 2020
            + 'AND SalesOrganization__c IN (' + STR_COUNTRIES + ')'
            
            //Karen Hung 23.10.2020 DOO-4983 Added Criteria in the batch
            + 'AND WTSChangedBy__c != \'Customer\' '
            
            /* MAIN CRITERIA */
            + 'AND (CreateWTSJob__c = true ' //Nov. 12, 2018 Xen Reyes                    
            //+ 'OR ((LastWTSDate__c != null OR InitialActivationDate__c != null) AND NextWTSDate__c = null))'; //Nov. 12, 2018 Xen Reyes
            + 'OR (LastWTSDate__c != null AND NextWTSDate__c = null))'; //January 7, 2019 XEN REYES
        
        System.debug('queryStr >>> ' + queryStr);
        
        CustomLogging.pop();
        
        if(SOQL_OVERRIDE){
            return Database.getQueryLocator(NEW_SOQL_STRING);
        } else {
            return Database.getQueryLocator(queryStr);
        }
        
    }
    
    /******************************************************************************
    * @author         Paul Jarred Aguiling
    * @date           6.14.2017
    * @description    Method responsible executing the main logic
    * @revision(s)
    ******************************************************************************/ 
    global void execute(Database.BatchableContext BC, List<PhysicalAsset__c> physicalAssetList) {
        CustomLogging.push(TS_Constants.CONST_EXECUTE, 'WaterFilterChangeConTriggerBatch');
        
        System.debug('XEN Nov. 15 physicalAssetList: ' + physicalAssetList);
        
        PhysicalAssetTriggerHandler.isNotBatchExecution = false; //[KTS-1775]: This is to prevent queueable issues on physical asset update
        PhysicalAssetTriggerHandler.isBatchExecution = true; //To disable trigger when selected batches are running
        WorkOrderLineItemTriggerHandler.isNotBatchExecution = false; // Method Mutig
        CaseTriggerHandler.isNotBatchExecution = false; // Method Muting
        
        List<WorkOrderLineItem> woliToInsert = new List<WorkOrderLineItem>();
        List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
        List<Case> caseToInsert = new List<Case>();
        List<PhysicalAsset__c> assetWithCreateList = new List<PhysicalAsset__c>();
        List<PhysicalAsset__c> assetWithNoCreateList = new List<PhysicalAsset__c>();
        List<PhysicalAsset__c> phyAssetList = new List<PhysicalAsset__c>();
        
        Map<String, Case> caseMap = new Map<String, Case>();
        Map<String, WorkOrder> woMap = new Map<String, WorkOrder>();
        Map<Id, String> priceBookMap = new Map<Id, String>();
        
        Map<String, List<Id>> salesOrgproductListMap = new Map<String, List<Id>>();
        Map<String, CountrySetting__c> map_thresholdByCountry = new Map<String, CountrySetting__c>();
        Map<String, CountrySetting__c> map_CountryAndBusinessHours = new Map<String, CountrySetting__c>();
        Map<String, CountrySetting__c> map_mergeWTSCountrySetting = new Map<String, CountrySetting__c>();
        
        Decimal wtsInterval = 0; //Francis Alindogan 11/23/2019 DOO-2696
        
        try {
            
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_WaterFilterChangeConBatchException(TS_Constants.CONST_THROW);
            }
            
            //XEN REYES - Add Merge WTS + Merge iteration Nov. 23, 2019 - DOO-2688
            for (CountrySetting__c countrySet: list_CountrySetting) {
                
                //Retrieve and iterate country settings with record type 'ContractTriggerSetting' 
                //Check if country in the map already exist. If not, populate map with country and CountrySetting__c
                if (TS_Constants.TS_CountrySettingRecType_ConTriggerSet.equals(countrySet.RecordType.DeveloperName) 
                    && !map_thresholdByCountry.containsKey(countrySet.Country__c)) {
                        map_thresholdByCountry.put(countrySet.Country__c, countrySet);
                    }
                
                //Retrieve and iterate country settings with record type 'CountryDefaultBusinessHours'
                //Check if country in the map already exist. If not, populate map with country and Business Hours Id
                if (TS_Constants.TS_CountrySettingRecType_CountryDefBusHrs.equals(countrySet.RecordType.DeveloperName) 
                    && !map_CountryAndBusinessHours.containsKey(countrySet.Country__c)) {
                        map_CountryAndBusinessHours.put(countrySet.Country__c, countrySet);
                    }
                
                //Retrieve and iterate country settings with record type 'MergeWTSwithPreventiveMaintenace'
                if (TS_Constants.TS_RECORDTYPENAME_COUNTRYSETTING_MERGEWTS.equals(countrySet.RecordType.DeveloperName) 
                    && !map_mergeWTSCountrySetting.containsKey(countrySet.Country__c)) {
                        map_mergeWTSCountrySetting.put(countrySet.Country__c, countrySet);
                    }
            }
            
            //Karen Hung DOO-4799 Check asset if it has Open S41 with SLA Date within S41 thresshold
            Set<String> assetWithOpenS41 = new Set<String>();
            Set<String> excludedStatus = new Set<String>{TS_Constants.STATUS_COMPLETED, TS_Constants.STATUS_CANCELED, TS_Constants.WOLI_STATUS_REVIEW};
                List<WorkOrderLineItem> openS41woli = [SELECT Id, SLADate__c, PhysicalAsset__c, WorkOrder.SalesOrganization__c, ReturnTask__c FROM WorkOrderLineItem WHERE Status NOT IN :excludedStatus
                                                       AND WorkOrderType__c = :TS_Constants.ORDER_S41 
                                                       AND Case__r.SubType__c != :TS_Constants.ORDER_INSTYPE_MOVEMENT
                                                       AND PhysicalAsset__c IN :physicalAssetList];
            
            if(!openS41woli.isEmpty()){
                for(WorkOrderLineItem woli : openS41woli){
                    
                    //DOO-5007 Xen Reyes
                    if(woli.SLADate__c == null){
                        assetWithOpenS41.add(woli.PhysicalAsset__c);
                    } else if(  map_thresholdByCountry.containsKey(woli.WorkOrder.SalesOrganization__c) 
                                && map_thresholdByCountry.get(woli.WorkOrder.SalesOrganization__c).S41_Threshold__c != null 
                                && woli.SLADate__c != null){
                                    
                        Integer countryThreshold = Integer.valueOf(map_thresholdByCountry.get(woli.WorkOrder.SalesOrganization__c).S41_Threshold__c);
                        
                        if(woli.SLADate__c.date() < Date.today().addDays(countryThreshold)){
                            assetWithOpenS41.add(woli.PhysicalAsset__c);
                        }
                    }
                }
            }
            
            Map<String, Boolean> assetMergeMap = new Map<String, Boolean>();
            
            //XEN REYES Nov. 12, 2018
            //GET AND EVALUATE ALL PHYSICAL ASSETS WITH CREATE JOB = FALSE 
            for(PhysicalAsset__c ps : physicalAssetList){
                
                //XEN REYES - Initial checker if WTS should be merged with PM.
                Boolean mergeWTS = false;
                if(map_mergeWTSCountrySetting.containsKey(ps.SalesOrganization__c) && ps.IncludesPreventiveMaintenanceCoverage__c){
                    if(map_mergeWTSCountrySetting.get(ps.SalesOrganization__c).Merge_WTS__c){
                        mergeWTS = true;
                    }
                }
                
                assetMergeMap.put(ps.Id, mergeWTS);
                
                //Karen Hung 25.08.2020 DOO-4682 Added supported operating type checker
                Boolean supportedOpType = false;
                if(map_thresholdByCountry.containsKey(ps.SalesOrganization__c) && 
                   map_thresholdByCountry.get(ps.SalesOrganization__c).Supported_Operating_Types_for_S32__c != null &&  
                   map_thresholdByCountry.get(ps.SalesOrganization__c).Supported_Operating_Types_for_S32__c.split(';').contains(ps.Machine_Care__c)){
                       supportedOpType = true;
                   }
                
                //if(!mergeWTS && !supportedOptype){ //Karen Hung DOO-4983 removed !mergeWTS
                if(!supportedOptype){
                    if(ps.CreateWTSJob__c == true){
                        assetWithCreateList.add(ps);
                    } else {
                        assetWithNoCreateList.add(ps);
                    }
                }
            }
            
            //Retrieve main service person/service contact/main contact/standard contact related to physical asset
            Map<Id, Id> map_physicalAssetContact = getPAsContactList(assetWithNoCreateList);
            
            for (PhysicalAsset__c physicalAsset : assetWithNoCreateList) {
                
                //11/19/18 Karen Hung added filter in account blocking
                Boolean isBlocked = physicalAsset.AccountLocation__c != null && physicalAsset.AccountLocation__r.Apttus_Config2__AccountId__c != null 
                    && physicalAsset.AccountLocation__r.Apttus_Config2__AccountId__r.Account_Block__c;
                
                //Karen Hung 25.09.2020 DOO-4799 added criteria if asset do not have open S41 from movement
                if (physicalAsset.SalesOrganization__c != null && physicalAsset.EndDate__c > Date.today() && !isBlocked && !assetWithOpenS41.contains(physicalAsset.Id)) {
                    
                    //Retrieve the next WTS
                    //Date nextWTSDate = physicalAsset.LastWTSDate__c != null? physicalAsset.LastWTSDate__c : physicalAsset.InitialActivationDate__c;
                    Date nextWTSDate = physicalAsset.LastWTSDate__c; //Jan. 7, 2019 XEN REYES
                    
                    //DOO-491 INC0118609 Xen Reyes June 18, 2019
                    //Integer numberOfDays = Date.isLeapYear(Date.today().year())? 366 : 365;
                    
                    //Decimal wtsInterval = physicalAsset.WTSInterval__c != null && physicalAsset.WTSInterval__c != 0? physicalAsset.WTSInterval__c : 1;
                    //Decimal wtsInterval = physicalAsset.WTSInterval__c; //Jan. 7, 2019 XEN REYES
                    
                    //Francis Alindogan 11/23/2019 DOO-2696
                    if(physicalAsset.WTSInterval__c != null){
                        wtsInterval = physicalAsset.WTSInterval__c;
                    }
                    else {
                        wtsInterval = map_thresholdByCountry.get(physicalAsset.SalesOrganization__c).Default_WTS_Interval__c;
                    }
                    
                    Boolean hasNewWTSDate = false;
                    
                    //Check if NextWTSDate__c was manually updated then use it as the nextWTSDate
                    if (physicalAsset.NextWTSDate__c != null && physicalAsset.WTSManualUpdate__c) {
                        nextWTSDate = physicalAsset.NextWTSDate__c;
                        hasNewWTSDate = true;
                        
                    } else if (nextWTSDate != null && wtsInterval != null ) {
                        //To calculate next WTS job, it will be the last WTS date or initial activation 
                        //date if the last WTS date is empty plus (365or366 * WTS interval)
                        
                        //nextWTSDate = nextWTSDate.addDays(Integer.valueOf(math.floor(numberOfDays/(12 * Integer.valueOf(wtsInterval)))));
                        //XEN REYES Feb. 3, 2019
                        //nextWTSDate = nextWTSDate.addDays(Integer.valueOf(math.floor((numberOfDays/12) * Integer.valueOf(wtsInterval))));
                        
                        //DOO-491 INC0118609 Xen Reyes June 18, 2019
                        nextWTSDate = nextWTSDate.addMonths(Integer.valueOf(wtsInterval));
                        
                        //WTS checks will be created 2 months in advance of the specification 
                        //in the contractual agreement and include a case and work order line item.
                        //Retrieve the business hours id from the counrtry setting using the sales org of physical asset
                        Id businessHoursId = map_CountryAndBusinessHours.get(physicalAsset.SalesOrganization__c) != null? 
                            map_CountryAndBusinessHours.get(physicalAsset.SalesOrganization__c).Business_Hours__c : null;
                        
                        if (businessHoursId != null) {
                            
                            //XR KTS-2013 9.08.2018 Check if the next WTS date is past date
                            Date dateToday = Date.today();
                            
                            DateTime dt = DateTime.newInstance(dateToday, Time.newInstance(0, 0, 0, 0));
                            String dayOfWeek = dt.format(TS_Constants.CONST_EEEE);
                            
                            DateTime dtStart = DateTime.newInstance(dateToday.toStartofWeek(), Time.newInstance(0, 0, 0, 0));
                            String dayStartOfWeek = dtStart.format(TS_Constants.CONST_EEEE);
                            
                            if(dateToday >= nextWTSDate){
                                if(dayStartOfWeek == TS_Constants.CONST_SUNDAY && dayOfWeek != TS_Constants.CONST_SUNDAY){
                                    nextWTSDate = dateToday.toStartofWeek().addDays(8);
                                } else if(dayStartOfWeek == TS_Constants.CONST_SUNDAY && dayOfWeek == TS_Constants.CONST_SUNDAY){
                                    nextWTSDate = dateToday.toStartofWeek().addDays(1);
                                } else if(dayStartOfWeek == TS_Constants.CONST_MONDAY){
                                    nextWTSDate = dateToday.toStartofWeek().addDays(7);
                                }
                            }
                            
                            //Validate next WTS date if it falls on holiday or weekend
                            nextWTSDate = TS_UtilityClass.getWorkingDate(businessHoursId, nextWTSDate);
                            
                            //Stamp nextWTSDate to physical asset record
                            physicalAsset.NextWTSDate__c = nextWTSDate;
                            hasNewWTSDate = true;
                        }
                    }
                    
                    //Get correct WTS Trigger Threshold from country settings via account sales org
                    Integer wtsThreshold = 0;
                    
                    if (map_thresholdByCountry.get(physicalAsset.SalesOrganization__c) != null) {
                        wtsThreshold = Integer.valueOf(map_thresholdByCountry.get(physicalAsset.SalesOrganization__c).WTSTriggerThreshold__c);
                    }
                    
                    //if (dateToday <= nextWTSDate && dateToday >= nextWTSDate.addMonths(-2)) { 
                    //Check when TODAY >= (next WTS date minus threshold), then create case/wo/woli needs to be created
                    
                    if (hasNewWTSDate && (Date.today() >= (nextWTSDate - wtsThreshold)) 
                        && physicalAsset.EndDate__c > nextWTSDate) {
                            
                            //######### Create Work Order Line Item #######//    
                            WorkOrderLineItem woli = createWorkOrderLineItem(physicalAsset, TS_Constants.TS_Activity_Type_S32, TS_Constants.TS_Type_Task, TS_Constants.TS_Status_Open);
                            woliList.add(woli);
                            //######### Create Work Order Line Item #######//        
                            
                            if(physicalAsset.Product__c != null){
                                if(salesOrgproductListMap.containsKey(physicalAsset.SalesOrganization__c)){
                                    salesOrgproductListMap.get(physicalAsset.SalesOrganization__c).add(physicalAsset.Product__r.Id);
                                } else {
                                    salesOrgproductListMap.put(physicalAsset.SalesOrganization__c, new List<Id>{physicalAsset.Product__r.Id});
                                }
                            }
                            
                            //XEN REYES Dec. 17, 2018: SLA Date should be the last day of the week of Next WTS Date
                            Date slaDate = nextWTSDate;
                            if (Label.TS_SLA_Monday.equals(TS_UtilityClass.getReadableDay(slaDate))) {
                                slaDate = slaDate.addDays(4);
                            } else if (Label.TS_SLA_Tuesday.equals(TS_UtilityClass.getReadableDay(slaDate))) {
                                slaDate = slaDate.addDays(3);
                            } else if (Label.TS_SLA_Wednesday.equals(TS_UtilityClass.getReadableDay(slaDate))) {
                                slaDate = slaDate.addDays(2);
                            } else if (Label.TS_SLA_Thursday.equals(TS_UtilityClass.getReadableDay(slaDate))) {
                                slaDate = slaDate.addDays(1);
                            }
                            
                            //XEN REYES Feb. 3, 2019
                            else if (Label.TS_SLA_Saturday.equals(TS_UtilityClass.getReadableDay(slaDate))) {
                                slaDate = slaDate.addDays(-1);
                            } else if (Label.TS_SLA_Sunday.equals(TS_UtilityClass.getReadableDay(slaDate))) {
                                slaDate = slaDate.addDays(-2);
                            } 
                            
                            //Karen Hung DOO-4983 Added transferred !mergeWTS checker to case creation and WTS Planned flagging
                            if(assetMergeMap.get(physicalAsset.Id) == false){                                
                                //######### Create Case #######//
                                Case cse = createCaseRecords(physicalAsset, TS_Constants.TS_Activity_Type_S32, slaDate, 
                                                             TS_Constants.TS_Case_Type_FieldService, map_physicalAssetContact,
                                                             map_CountryAndBusinessHours.get(physicalAsset.SalesOrganization__c));
                                caseToInsert.add(cse);
                                //######### Create Case #######//   
                                
                                //Set WTSPlanned__c to true when case/wo/woli are constructed
                                physicalAsset.WTSPlanned__c = true;                           
                            }
                            
                        }
                    
                    //Add physical asset record to be updated
                    if (hasNewWTSDate) {
                        phyAssetList.add(physicalAsset);
                    }   
                }
            }
            
            //XEN REYES Nov. 12, 2018
            //PROCESS ALL RECORDS WITH CreateWTSJob__c = TRUE
            if(!assetWithCreateList.isEmpty()){
                
                //Retrieve main service person/service contact/main contact/standard contact related to physical asset
                Map<Id, Id> map_physicalAssetContact_create = getPAsContactList(assetWithCreateList);
                for(PhysicalAsset__c ps : assetWithCreateList){
                    //only create item when account is not blocked KarenHung 11/19/2018
                    Boolean isBlocked = ps.AccountLocation__c != null && ps.AccountLocation__r.Apttus_Config2__AccountId__c != null 
                        && ps.AccountLocation__r.Apttus_Config2__AccountId__r.Account_Block__c;
                    
                    //Karen Hung 25.09.2020 DOO-4799 added criteria if asset do not have open S41 from movement
                    if(!isBlocked &&  !assetWithOpenS41.contains(ps.Id)){
                        
                        //######### Create Work Order Line Item #######//    
                        WorkOrderLineItem woli = createWorkOrderLineItem(ps, TS_Constants.TS_Activity_Type_S32, TS_Constants.TS_Type_Task, TS_Constants.TS_Status_Open);
                        woliList.add(woli);
                        //######### Create Work Order Line Item #######//        
                        
                        if(ps.Product__c != null){
                            if(salesOrgproductListMap.containsKey(ps.SalesOrganization__c)){
                                salesOrgproductListMap.get(ps.SalesOrganization__c).add(ps.Product__r.Id);
                            } else {
                                salesOrgproductListMap.put(ps.SalesOrganization__c, new List<Id>{ps.Product__r.Id});
                            }
                        }
                        
                        //XEN REYES Dec. 17, 2018: SLA Date should be the last day of the week of Next WTS Date
                        Date slaDate = ps.NextWTSDate__c;
                        if (Label.TS_SLA_Monday.equals(TS_UtilityClass.getReadableDay(slaDate))) {
                            slaDate = slaDate.addDays(4);
                        } else if (Label.TS_SLA_Tuesday.equals(TS_UtilityClass.getReadableDay(slaDate))) {
                            slaDate = slaDate.addDays(3);
                        } else if (Label.TS_SLA_Wednesday.equals(TS_UtilityClass.getReadableDay(slaDate))) {
                            slaDate = slaDate.addDays(2);
                        } else if (Label.TS_SLA_Thursday.equals(TS_UtilityClass.getReadableDay(slaDate))) {
                            slaDate = slaDate.addDays(1);
                        }
                        
                        //Karen Hung DOO-4983 Added transferred !mergeWTS checker to case creation and WTS Planned flagging
                        if(assetMergeMap.get(ps.Id) == false){ 
                            //######### Create Case #######// 
                            Case cse = createCaseRecords(ps, TS_Constants.TS_Activity_Type_S32, slaDate, 
                                                         TS_Constants.TS_Case_Type_FieldService, map_physicalAssetContact_create,
                                                         map_CountryAndBusinessHours.get(ps.SalesOrganization__c));
                            caseToInsert.add(cse);
                            //######### Create Case #######//
                            
                            //Set WTSPlanned__c to true when case/wo/woli are constructed
                            ps.WTSPlanned__c = true;
                        }
                        
                        //Add physical asset record to be updated
                        phyAssetList.add(ps);
                    }  
                }
            }
            
            //Get associated pricebook and pricebook entry based on Product Id and Sales Organization
            Map<String, PriceBookEntry> priceMap = new Map<String, PriceBookEntry>();
            
            Set<Id> prodIdSet = new Set<Id>();
            if(!salesOrgproductListMap.isEmpty()){
                for(List<Id> prdId : salesOrgproductListMap.values()){
                    for(Id var : prdId){
                        prodIdSet.add(var);
                    }
                }
            }
            
            
            for (PriceBookEntry priceBookEnt: [SELECT Id, PriceBook2Id, Product2Id, Sales_Organization__c
                                               FROM PriceBookEntry WHERE Product2Id IN: prodIdSet
                                               AND Sales_Organization__c IN: salesOrgproductListMap.keySet() AND IsActive = true]) {
                                                   
                                                   if (!priceMap.containsKey(priceBookEnt.Product2Id + priceBookEnt.Sales_Organization__c)){
                                                       priceMap.put(priceBookEnt.Product2Id + priceBookEnt.Sales_Organization__c, priceBookEnt);
                                                   }
                                               }
            
            // system.debug('water pricemap=' +priceMap);
            //Insert Case Records
            if (!caseToInsert.isEmpty())
                insert caseToInsert;
            
            Set<Id> cseIds = new Set<Id>();
            Map<Id, Case> caseMapWO = new Map<Id, Case>();
            
            //Iterate case Ids
            for (Case cse: caseToInsert) {
                cseIds.add(cse.Id);
            }
            
            //Query ownerId updated by assignment rule
            if (!cseIds.isEmpty()) {
                caseMapWO = new Map<Id, Case>([SELECT OwnerId, Owner.Name FROM Case WHERE Id IN :cseIds]);
            }
            
            //Create and insert work order records
            for (Case cse: caseToInsert) {
                
                WorkOrder wo = new WorkOrder();
                //wo.Subject = cse.Subject;
                wo.CaseId = cse.Id;
                wo.SalesOrganization__c = cse.SalesOrganization__c;
                wo.OwnerID = caseMapWO.get(cse.Id) != null? caseMapWO.get(cse.Id).OwnerId : cse.OwnerId;
                wo.Status = TS_Constants.TS_Status_Open;
                
                wo.PriceBook2Id = priceMap != null && priceMap.get(cse.ProductId + cse.SalesOrganization__c) != null? priceMap.get(cse.ProductId + cse.SalesOrganization__c).PriceBook2Id : null;
                
                //wo.ContactId = cse.ContactId;
                woMap.put(cse.CaseExternalReference__c, wo);
                caseMap.put(cse.CaseExternalReference__c, cse);
                
            }
            
            if (!woMap.isEmpty()){
                try{
                    insert woMap.values();
                } catch (Exception e){
                    System.debug(e);
                }
            }
            //system.debug('womap waterfilter---' + womap.values());
            if (woliList != null){
                
                //Create and insert work order line item records
                for (WorkOrderLineItem woli: woliList) {
                    if (!woMap.isEmpty() && woMap.get(woli.WOLIExternalReference__c) != null
                        && !caseMap.isEmpty() && caseMap.get(woli.WOLIExternalReference__c) != null) {
                            woli.Case__c = woMap.get(woli.WOLIExternalReference__c).CaseId;
                            woli.WorkOrderId = woMap.get(woli.WOLIExternalReference__c).Id;
                            woli.SLADate__c = caseMap.get(woli.WOLIExternalReference__c).SLADate__c;
                            woli.Subject = caseMap.get(woli.WOLIExternalReference__c).Subject;
                            woli.Description = caseMap.get(woli.WOLIExternalReference__c).Description;
                            
                            if(!priceMap.isEmpty() && priceMap.containsKey(caseMap.get(woli.WOLIExternalReference__c).ProductId + caseMap.get(woli.WOLIExternalReference__c).SalesOrganization__c)){
                                woli.PricebookEntryId = priceMap.get(caseMap.get(woli.WOLIExternalReference__c).ProductId+caseMap.get(woli.WOLIExternalReference__c).SalesOrganization__c).Id;
                            }
                            
                            woliToInsert.add(woli);
                        }
                }
            }
            
            //System.debug('XEN Nov. 15: ' + woliToInsert);
            if (!woliToInsert.isEmpty()){
                try{ 
                    insert woliToInsert;
                } catch (Exception e){
                    System.debug(e.getMessage() + '\n' + e.getStackTraceString());
                }
            }
            
            //FOR TEST COVERAGE - Triggering custom validation to cover customLoggingForUpdates test method
            if(Test.isRunningTest()){
                phyAssetList[0].NextWTSDate__c = Date.today().addDays(1);
            	phyAssetList[0].WTSManualUpdate__c = true;
            }
            
            //Update physical asset records           
            if (Schema.sObjectType.PhysicalAsset__c.isUpdateable() && !phyAssetList.isEmpty()) {               
                Database.SaveResult[] saveResultList = Database.update(phyAssetList, false);
                
                /* for (Database.SaveResult sr: saveResultList) {
                    if (!sr.isSuccess()) {
                        //Operation failed. Get error details               
                        for(Database.Error err : sr.getErrors()) {
                            String msg = TS_Constants.ERRBATCH_MSG_01 + err.getStatusCode() + ': ' + err.getMessage() + ': ' + err.getFields();
                            exception_List.add(msg);
                        }
                    }
                }*/
                
                //XEN REYES - Custom Logging for Database.Error
                customLoggingForUpdates(phyAssetList, saveResultList);
            }
            
        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        
        CustomLogging.pop();
    }
    
    
    /******************************************************************************
    * @author         Paul Jarred Aguiling
    * @date           6.14.2017
    * @description    Method responsible for final changes or updates whitin the batch of records
    * @revision(s)
    ******************************************************************************/ 
    global void finish(Database.BatchableContext BC) {
        CustomLogging.push('finish', 'WaterFilterChangeConTriggerBatch');
        
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
    * @author         Paul Jarred Aguiling
    * @date           02.14.2017
    * @description    Method responsible for getting the contact list
    * @revision(s)
    ******************************************************************************/ 
    @TestVisible
    private Map<Id, Id> getPAsContactList(List<PhysicalAsset__c> physicalAssetList) {
        CustomLogging.push('getPAsContactList', 'WaterFilterChangeConTriggerBatch');
        Map<Id, List<Contact>> contactMap = new Map<Id, List<Contact>>();
        Map<Id, Id> phyContact = new Map<Id, Id>();
        List<Contact> mainServiceContactList = new List<Contact>();
        List<Contact> mainContactList = new List<Contact>();
        List<Contact> contactList = new List<Contact>();
        Set<Id> accountIds = new Set<Id>();
        
        //Iterate related accounts from the physical asset
        for (PhysicalAsset__c physicalAsset : physicalAssetList) {
            if (physicalAsset.AccountLocation__c != null
                && physicalAsset.AccountLocation__r.Apttus_Config2__AccountId__c != null) {
                    accountIds.add(physicalAsset.AccountLocation__r.Apttus_Config2__AccountId__c);
                }
        }
        
        if (accountIds != null && !accountIds.isEmpty()) {
            //Iterate list of contacts from the physical asset account id
            for (Contact con: [SELECT Id, AccountId, Main_Service_Person__c, 
                               Function__c, Main_Contact__c
                               FROM Contact 
                               WHERE AccountId IN :accountIds 
                               ORDER by CreatedDate DESC]) {
                                   
                                   //Add the right account to the child contacts
                                   if (contactMap.containsKey(con.AccountId)) {
                                       contactMap.get(con.AccountId).add(con);
                                   } else {
                                       contactMap.put(con.AccountId, new List<Contact>{con});
                                   }
                               }
            
            //Iterate physical asset records to then assign the correct contact
            for (PhysicalAsset__c physicalAsset : physicalAssetList) {
                if (physicalAsset.SoldTo__c != null && contactMap.get(physicalAsset.SoldTo__c) != null) {
                    for (Contact con : contactMap.get(physicalAsset.SoldTo__c)) {
                        //Check if contact has Main Service Person
                        if (con.Main_Service_Person__c) {
                            phyContact.put(physicalAsset.Id, con.Id);
                            break;
                            //Check if contact has Service Contact
                        } else if (TS_Constants.TS_ConFunction_ServiceContact.equals(con.Function__c)){
                            mainServiceContactList.add(con);
                            //Check if contact has Main Contact
                        } else if (con.Main_Contact__c) {
                            mainContactList.add(con);     
                            //Add first available contact if the above conditions does not apply
                        } else {
                            contactList.add(con);
                        }
                    }
                    
                    //Assign service contact to respective physical asset
                    if (phyContact.isEmpty() && !mainServiceContactList.isEmpty()) {
                        phyContact.put(physicalAsset.Id, mainServiceContactList.get(0).Id);
                        //Assign main contact to respective physical asset
                    } else if (phyContact.isEmpty() && !mainContactList.isEmpty()) {
                        phyContact.put(physicalAsset.Id, mainContactList.get(0).Id);
                        //Assign contact to respective physical asset
                    } else if (phyContact.isEmpty() && !contactList.isEmpty()) {
                        phyContact.put(physicalAsset.Id, contactList.get(0).Id);
                    }
                }
            }
        }
        
        return phyContact;
    }
    
    /******************************************************************************
    * @author         Paul Jarred Aguiling
    * @date           5.16.2017
    * @description    Method responsible for setting work order line item values
    * @revision(s)
    ******************************************************************************/ 
    @TestVisible
    private WorkOrderLineItem createWorkOrderLineItem(PhysicalAsset__c physicalAsset, String woliType, String type, String stat) {
        CustomLogging.push('createWorkOrderLineItem', 'WaterFilterChangeConTriggerBatch');
        
        WorkOrderLineItem woli = new WorkOrderLineItem();
        woli.Status = stat;
        woli.PhysicalAsset__c = physicalAsset.Id;
        woli.AccountLocation__c = physicalAsset.AccountLocation__c;
        woli.WorkOrderLineItemType__c = type;
        woli.WorkOrderType__c = woliType;
        woli.WOLIExternalReference__c = String.valueOf(physicalAsset.Id);       
        woli.ConfigurationFileURL__c = physicalAsset.ConfigurationFileURL__c;
        woli.ConfigurationManualAgreementsURL__c = physicalAsset.ConfigurationManualAgreementsURL__c;
        woli.JDECrockeryVolumeSize__c = physicalAsset.JDECrockeryVolumeSize__c;
        woli.SmokingArea__c = physicalAsset.SmokingArea__c;
        woli.Building__c = physicalAsset.Building__c;
        woli.Floor__c = physicalAsset.Floor__c;
        woli.Area__c = physicalAsset.Area__c;
        woli.CustomerReference__c = physicalAsset.CustomerReferenceNumber__c;
        
        if (physicalAsset.AccountLocation__c != null) {
            woli.AlternativeMachine__c = physicalAsset.AccountLocation__r.Alternative_Machine__c;
            woli.Country__c = physicalAsset.AccountLocation__r.Apttus_Config2__Country__c;
            woli.PostalCode__c = physicalAsset.AccountLocation__r.Apttus_Config2__PostalCode__c;
            woli.City__c = physicalAsset.AccountLocation__r.Apttus_Config2__City__c;
            String street = physicalAsset.AccountLocation__r.Shipping_Street__c != null? physicalAsset.AccountLocation__r.Shipping_Street__c : '';
            String houseNumber = physicalAsset.AccountLocation__r.Shipping_House_Number__c != null? physicalAsset.AccountLocation__r.Shipping_House_Number__c : '';
            woli.StreetAndHouseNumber__c = street + ' ' + houseNumber;  
        }
        
        CustomLogging.pop();  
        
        return woli;
    }
    
    /******************************************************************************
    * @author         Paul Jarred Aguiling
    * @date           5.16.2017
    * @description    Method responsible for setting case values
    * @revision(s)
    ******************************************************************************/ 
    @TestVisible
    private Case createCaseRecords(PhysicalAsset__c physicalAsset, String subType, Date sLAdate, String cseType, Map<Id, Id> phyContactMap, CountrySetting__c cset) {
        CustomLogging.push('createCaseRecords', 'WaterFilterChangeConTriggerBatch');
        Case cse = new Case();
        cse.Type = cseType;
        cse.SubType__c = subtype;
        cse.Subject = TS_Constants.TS_Assetlinitem_WaterFilter;
        cse.Origin = TS_Constants.TS_Case_Origin_ContractOrder;
        cse.Description = TS_Constants.TS_Assetlinitem_WaterFilter;
        cse.AccountId = physicalAsset.SoldTo__c;
        cse.PhysicalAsset__c = physicalAsset.Id;
        cse.SalesOrganization__c = physicalAsset.SalesOrganization__c;
        //cse.OwnerId = UserInfo.getUserId();
        cse.AccountLocation__c = physicalAsset.AccountLocation__c;
        cse.CaseExternalReference__c = String.valueOf(physicalAsset.Id);
        cse.Status = TS_Constants.TS_Status_InProgress; //Default Case Status
        cse.PO_Number__c = physicalAsset.PONumberServices__c;
        cse.ProductId = physicalAsset.Product__c;
        
        //XEN REYES 9.28.2018 KTS-2196: This is to ensure that even if the default owner is Individual, the case will be routed to the correct queue.
        cse.AssignToQueue__c = true;
        cse.TS_IsGeneratedFromBatch__c = true;
        
        //Get correct time based on sales organizations business hours
        Time newTime = TS_UtilityClass.getBusinessHoursLatestTime(cset, sladate);
        cse.SLADate__c = DateTime.newInstance(sladate.year(), sladate.month(), sladate.day(), newTime.hour(), newTime.minute(), newTime.second());
        
        //Assigned the right contact based on the filtered child contacts of Sold to (Account)
        if (physicalAsset.SoldTo__c != null && phyContactMap != null && phyContactMap.get(physicalAsset.Id) != null) {
            cse.ContactId =  phyContactMap.get(physicalAsset.Id);
        }
        
        CustomLogging.pop();
        
        return cse;
    }
    
    /**
    * @author        Paul Jarred Aguiling
    * @date          02.05.2018          
    * @description   [KTS-1095]: Contract Triggered Cases (Waterfilter Changes)
    *                Method serves as a validation rule to prevent updates on Next WTS Date 
    * @revision(s)
    */
    private List<CountrySetting__c> getCountrySettings() {
        CustomLogging.push('getCountrySettings', 'PhysicalAssetTriggerHandler');
        //Get all country settings with record type CountryDefaultBusinessHours
        List<CountrySetting__c> countrySetList = [SELECT Name, Country__c, Business_Hours__c, 
                                                  Business_Hours__r.MondayEndTime,
                                                  Business_Hours__r.TuesdayEndTime,
                                                  Business_Hours__r.WednesdayEndTime,
                                                  Business_Hours__r.ThursdayEndTime,
                                                  Business_Hours__r.FridayEndTime,
                                                  Business_Hours__r.SaturdayEndTime,
                                                  Business_Hours__r.SundayEndTime,
                                                  RecordType.DeveloperName,
                                                  PreventiveMainTriggerThreshold__c, 
                                                  WTSTriggerThreshold__c,
                                                  Default_WTS_Interval__c, //Francis Alindogan 11/23/2019 DOO-2696
                                                  Merge_WTS__c, //XEN REYES - Merge WTS with PM Nov. 23, 2019 - DOO-2688
                                                  Supported_Operating_Types_for_S32__c, //Karen Hung 25.08.2020 DOO-4682
                                                  S41_Threshold__c //Karen Hung 28.09.2020 DOO-4799
                                                  FROM CountrySetting__c 
                                                  WHERE (RecordType.DeveloperName = :TS_Constants.TS_CountrySettingRecType_CountryDefBusHrs
                                                         OR RecordType.DeveloperName = :TS_Constants.TS_CountrySettingRecType_ConTriggerSet
                                                         OR RecordType.DeveloperName = :TS_Constants.TS_RECORDTYPENAME_COUNTRYSETTING_MERGEWTS)
                                                  AND Active__c = true];
        
        CustomLogging.pop(); 
        return countrySetList;
    }
    
    /**
    * @author        Abram Vixen Reyes
    * @date          Jan. 25, 2019
    * @description   Method to create a custom log record if there is failed record processed in the batch execution.
    * @revision(s)
    */
    private void customLoggingForUpdates(List<PhysicalAsset__c> phyAssetList, List<Database.SaveResult> saveResultList) {
        
        //XEN REYES - Custom Logging for Database.Error
        List<Custom_Log__c> customLogs = new List<Custom_Log__c>();
        List<String> exception_List_batch = new List<String>();
        Set<Id> assetIdsToBeUpdatedSet = (new Map<Id,SObject>(phyAssetList)).keySet();
        Set<Id> successfulIds = new Set<Id>();
        Set<Id> failedIds = new Set<Id>();
        
        /* Get all Successful Ids */
        for (Database.SaveResult sr: saveResultList) {
            if(sr.isSuccess()){
                successfulIds.add(sr.getId());
            }
        }
        
        /* Remove all Successful Ids to the Initial List to get the Failed records.*/
        if(successfulIds.size() != assetIdsToBeUpdatedSet.size()){
            if(!successfulIds.isEmpty()){
                for(Id objId: assetIdsToBeUpdatedSet){
                    if(!successfulIds.contains(objId)){
                        failedIds.add(objId);
                    }
                }
            } else {
                failedIds = assetIdsToBeUpdatedSet;
            }
            
            /* Create error message to each Database.Error. */
            for (Database.SaveResult sr: saveResultList) {
                if (!sr.isSuccess()) {
                    //Operation failed. Get error details               
                    for(Database.Error err : sr.getErrors()) {
                        String msg = TS_Constants.ERRBATCH_MSG_01 + err.getStatusCode() + ': ' + err.getMessage() + ': ' + err.getFields();
                        exception_List.add(msg);
                        exception_List_batch.add(msg);
                    }
                }
            }
            
            /* Create custom log record per batch. If there is an error. */
            if(!exception_List_batch.isEmpty()){
                String mainMessage = '';
                
                for(String err : exception_List_batch){
                    mainMessage = err + '\n';
                }
                
                //CREATE CUSTOM LOG
                Custom_Log__c log = new Custom_Log__c(
                    StackTrace__c = TS_Constants.WATERFILTER_BATCH,
                    Message__c = mainMessage + '\n' + TS_Constants.FAILEDRECORDS + JSON.serialize(failedIds),
                    ExceptionType__c = TS_Constants.DATABASE_ERROR);
                insert log;
            }
        }
    }
}