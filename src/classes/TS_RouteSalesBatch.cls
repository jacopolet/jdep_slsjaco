/**
* @author        Paul Jarred Aguiling
* @date          04.14.2018          
* @description   [KTS-53]: RouteSales tasks in Salesforce. 
*                Class responsible for processing route sales batch records
* @revision(s)   6.28.2018 Paul Aguiling: KTS-1920 Contract Triggered Cases Batch not fired for all assets
*                                                  Updated execute() and finish()
*/
global without sharing class TS_RouteSalesBatch implements Database.Batchable<sObject>, Database.Stateful {

    private String queryStr = null;
    private List<CountrySetting__c> list_CountrySetting = new List<CountrySetting__c>();
    private List<String> exception_List = new List<String>();
    public static Boolean hasException = false;
    public Date runDate;
    public Date referenceDate;
    public static Boolean forceError = false;
    public Boolean SOQL_OVERRIDE = false;
    public String NEW_SOQL_STRING;

    /******************************************************************************
    * @author         Paul Jarred Aguiling
    * @date           04.14.2018
    * @description    Method responsible for throwing an exception
    * @revision(s)
    ******************************************************************************/ 
    public class TS_RouteSalesBatchException extends Exception {}

    /******************************************************************************
    * @author         Paul Jarred Aguiling
    * @date           04.14.2018
    * @description    Constructor of the class
    * @revision(s)
    ******************************************************************************/ 
    public TS_RouteSalesBatch(Date getDate) {
        list_CountrySetting = getCountrySettings();
        
        if(getDate != null){
            runDate = getDate;
        } else {
            runDate = Date.today();
        }

        referenceDate = runDate.addDays(4); //Karen Hung KTS-2479 Add Days 4 if Wednesday for the batch to assume that it is Sunday.
    }

    /******************************************************************************
    * @author         Paul Jarred Aguiling
    * @date           04.14.2018
    * @description    This method is the start of the batch job
    * @revision(s)
    ******************************************************************************/ 
    global Database.QueryLocator start(Database.BatchableContext BC) {
        CustomLogging.push(TS_Constants.CONST_START, TS_Constants.CONST_BATCH);

        queryStr = 'SELECT Id, LastRoutesalesDate__c, NextRoutesalesDate__c, RoutesalesDateOverriden__c, NextRoutesalesVisit__c, NextRoutesalesWeek__c, Preferred_Routesales_Employee__c, ' 
                    + 'RequestedRoutesalesVisit__c, RoutesalesConfirmationDate__c, RoutesalesInterval__c,CreateRoutesalesJob__c, RoutesalesPlanned__c, Mini_Sales_Organization__c, ' //Karen Hung 11/14/18 added CreateRoutesalesJob__c
                    + 'Additional_Case_Contact__c, Apttus_Config2__AccountId__c, Route_Sales_Main_Contact__c, Day_of_Visit__c '
                    + 'FROM Apttus_Config2__AccountLocation__c WHERE RoutesalesInterval__c > 0 '
                    + 'AND (Mini_Sales_Organization__c = \'SAP_0111\' ' //NETHERLANDS
                    + 'OR Mini_Sales_Organization__c = \'SAP_0975\' ' //DENMARK
                    + 'OR Mini_Sales_Organization__c = \'SAP_0333\' '  //BELGIUM KTS-2086
                    + 'OR Mini_Sales_Organization__c = \'SAP_6712\') ' //GERMANY KTS-2086
                    + 'AND ((CreateRoutesalesJob__c  = true AND RoutesalesPlanned__c = false) ' //Nov. 12, 2018 Xen Reyes                    
                    + 'OR (LastRoutesalesDate__c != null AND NextRoutesalesDate__c = null AND RoutesalesPlanned__c = false) '//Nov. 12, 2018 Xen Reyes
                    + 'OR ((LastRoutesalesDate__c != null OR NextRoutesalesDate__c != null) AND RoutesalesInterval__c = 1))'; //Karen Hung 1.3.19 RouteSales change, Xen Reyes Jan. 18, 2019

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
    * @date           04.14.2018
    * @description    Method responsible executing the main logic
    * @revision(s)
    ******************************************************************************/ 
    global void execute(Database.BatchableContext BC, List<Apttus_Config2__AccountLocation__c> accountLocList) {
        CustomLogging.push(TS_Constants.CONST_EXECUTE, TS_Constants.CONST_BATCH);

        AccountLocationTriggerHandler.isNotBatchExecution = false; //[KTS-1775]: This is to prevent queueable issues on account location update
        AccountLocationTriggerHandler.isBatchExecution = true; //XEN REYES 11.11.2018

        PhysicalAssetTriggerHandler.isNotBatchExecution = false; //Karen Hung 11/14/18
        PhysicalAssetTriggerHandler.isBatchExecution = true; //Karen Hung 11/14/18
        WorkOrderLineItemTriggerHandler.isNotBatchExecution = false; //Karen Hung 11/14/18

        List<WorkOrderLineItem> woliToInsert = new List<WorkOrderLineItem>();
        Map<String, Case> caseMap = new Map<String, Case>();
        Map<String, WorkOrder> woMap = new Map<String, WorkOrder>();
        List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
        List<Case> caseToInsert = new List<Case>();

        List<Apttus_Config2__AccountLocation__c> accLocWithCreateList = new List<Apttus_Config2__AccountLocation__c>(); //Karen Hung 11/14/18
        List<Apttus_Config2__AccountLocation__c> accLocWithNoCreateList = new List<Apttus_Config2__AccountLocation__c>();//Karen Hung 11/14/18

        Map<String, CountrySetting__c> map_thresholdByCountry = new Map<String, CountrySetting__c>();
        Map<String, CountrySetting__c> map_CountryAndBusinessHours = new Map<String, CountrySetting__c>();

        List<Apttus_Config2__AccountLocation__c> accLocationList = new List<Apttus_Config2__AccountLocation__c>();
        List<Apttus_Config2__AccountLocation__c> accLocList = new List<Apttus_Config2__AccountLocation__c>();

        //KAREN HUNG Nov. 14, 2018
        //GET AND EVALUATE ALL PHYSICAL ASSETS WITH CREATE JOB = FALSE
        for(Apttus_Config2__AccountLocation__c acc : accountLocList){
            if(acc.CreateRoutesalesJob__c && acc.RoutesalesInterval__c != 1){ //XEN REYES Jan. 23, 2019
                accLocWithCreateList.add(acc);
            } else {
                accLocWithNoCreateList.add(acc);
            }
        }

        try {

            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_RouteSalesBatchException(TS_Constants.CONST_THROW);
            }

            //Retrieve main service person/service contact/main contact/standard contact related to account location
            Map<Id, Id> map_accLocContact = getAccLocContactList(accLocWithNoCreateList);

            for (CountrySetting__c countrySet: list_CountrySetting) {
                //Retrieve and iterate country settings with record type 'RouteSales' 
                //Check if country in the map already exist. If not, populate map with country and CountrySetting__c
                if (TS_Constants.TS_CountrySettingRecType_RouteSales.equals(countrySet.RecordType.DeveloperName) 
                    && !map_thresholdByCountry.containsKey(countrySet.Country__c)) {
                    map_thresholdByCountry.put(countrySet.Country__c, countrySet);
                }

                //Retrieve and iterate country settings with record type 'CountryDefaultBusinessHours'
                //Check if country in the map already exist. If not, populate map with country and Business Hours Id
                if (TS_Constants.TS_CountrySettingRecType_CountryDefBusHrs.equals(countrySet.RecordType.DeveloperName) 
                    && !map_CountryAndBusinessHours.containsKey(countrySet.Country__c)) {
                    map_CountryAndBusinessHours.put(countrySet.Country__c, countrySet);
                } 
            }

            for (Apttus_Config2__AccountLocation__c accLoc : accLocWithNoCreateList) {
                //Retrieve the next route sales
                Date nextRouteSales = accLoc.LastRoutesalesDate__c != null? accLoc.LastRoutesalesDate__c : accLoc.NextRoutesalesDate__c;

                //Retrieve the business hours id from the country setting using the sales org of account location
                Id businessHoursId = map_CountryAndBusinessHours.get(accLoc.Mini_Sales_Organization__c) != null? 
                        map_CountryAndBusinessHours.get(accLoc.Mini_Sales_Organization__c).Business_Hours__c : null;

                //Skips the current record and goes to the next loop/record
                if (businessHoursId == null) {
                    System.debug(TS_Constants.ERRBATCH_MSG_03 + accLoc.Id);
                    continue;
                }

                //Check if NextRoutesalesDate__c was manually updated then use it as the nextRouteSales
                if (accLoc.NextRoutesalesDate__c != null && (accLoc.RoutesalesDateOverriden__c || accLoc.LastRoutesalesDate__c == null)) {
                    nextRouteSales = accLoc.NextRoutesalesDate__c;
                } else {
                    //To calculate next route sales, it will be the last route sales date + 7 (days in a week) multiploed by route sales interval 
                    nextRouteSales = nextRouteSales.addDays(Integer.valueOf(7 * accLoc.RoutesalesInterval__c));

                    //XR KTS-2013 9.08.2018 Check if the next routesales date is past date
                    //Date dateToday = Date.today().addDays(3); //Karen Hung 1.3.19 added 3days
                    Date dateToday = referenceDate;
                    
                    DateTime dt = DateTime.newInstance(dateToday, Time.newInstance(0, 0, 0, 0));
                    String dayOfWeek = dt.format(TS_Constants.CONST_EEEE);

                    DateTime dtStart = DateTime.newInstance(dateToday.toStartofWeek(), Time.newInstance(0, 0, 0, 0));
                    String dayStartOfWeek = dtStart.format(TS_Constants.CONST_EEEE);

                    System.debug('dateToday: ' + dateToday);
                    System.debug('dayStartOfWeek: ' + dayStartOfWeek);
                    System.debug('dayOfWeek: ' + dayOfWeek);
                    System.debug('nextRouteSales BEFORE: ' + nextRouteSales);

                    if(dateToday >= nextRouteSales){
                        if(dayStartOfWeek == TS_Constants.CONST_SUNDAY && dayOfWeek != TS_Constants.CONST_SUNDAY){
                            nextRouteSales = dateToday.toStartofWeek().addDays(8);
                        } else if(dayStartOfWeek == TS_Constants.CONST_SUNDAY && dayOfWeek == TS_Constants.CONST_SUNDAY){
                            nextRouteSales = dateToday.toStartofWeek().addDays(1);
                        } else if(dayStartOfWeek == TS_Constants.CONST_MONDAY){
                            nextRouteSales = dateToday.toStartofWeek().addDays(7);
                        }
                    }
                            
                    //Validate next route sales if it falls on holiday or weekend
                    nextRouteSales = TS_UtilityClass.getWorkingDate(businessHoursId, nextRouteSales);

                    //Stamp nextRouteSales to account location record
                    accLoc.NextRoutesalesDate__c = nextRouteSales;
                }

                //Calculate Route Sales Confirmation Date
                accLoc.RoutesalesConfirmationDate__c = getConfirmationDate(businessHoursId, nextRouteSales, 10).date();

                /* XEN REYES Feb 6, 2019 */
                if(accLoc.RoutesalesConfirmationDate__c < Date.today()){
                    accLoc.RoutesalesConfirmationDate__c = Date.today();
                }

                //Get correct route sales threshold from country settings via account location sales org
                Integer routeSalesThreshold = 0;

                if (map_thresholdByCountry.get(accLoc.Mini_Sales_Organization__c) != null) {
                    routeSalesThreshold = Integer.valueOf(map_thresholdByCountry.get(accLoc.Mini_Sales_Organization__c).RouteSalesThreshold__c);
                }

                //the system will need to calculate whether a work order will need to be created for a particular account location. 
                //To do so the system needs to crosscheck if there is not a work order planned already by verifying if the field Routesales Planned = FALSE. 
                //Secondly, the system needs to retrieve the country specific routesales threshold. Using this threshold the system will then 
                //need to compute the following formula: Today > = Next Routesales Date – Country Specific Treshold
                //Karen Hung 1.3.19 RouteSales change, to create case when interval ==1, added 3 of date.today
                if (referenceDate >= (nextRouteSales - routeSalesThreshold) || accLoc.RoutesalesInterval__c == 1) {
                    //Set the Early Start Date with the first business day of the week of the Next Routesales Date using the business hours as a reference.
                    DateTime startTime = getStartAndEndDates(nextRouteSales, 
                                         map_CountryAndBusinessHours.get(accLoc.Mini_Sales_Organization__c).Business_Hours__r.MondayStartTime, 
                                         true);

                    //Set the SLA Date with the last business day of the week of the Next Routesales Date using the business hours as a reference.
                    DateTime endTime = getStartAndEndDates(nextRouteSales, 
                                       map_CountryAndBusinessHours.get(accLoc.Mini_Sales_Organization__c).Business_Hours__r.FridayEndTime, 
                                       false);

                    //XEN REYES DOO-4265 Mar. 26, 2020
                    if(accLoc.Day_of_Visit__c != null && accLoc.Day_of_Visit__c != 0 && accLoc.Day_of_Visit__c <= 5){
                        startTime = startTime.addDays(Integer.valueOf(accLoc.Day_of_Visit__c) - 1);
                        endTime = DateTime.newInstance(startTime.date(), endTime.time());
                    }

                    //######### Create Work Order Line Item #######//    
                    WorkOrderLineItem woli = createWorkOrderLineItem(accLoc);
                    woliList.add(woli);
                    //######### Create Work Order Line Item #######//        

                    //######### Create Case #######//
                    Case cse = createCaseRecords(accLoc, startTime, endTime, map_accLocContact);
                    caseToInsert.add(cse);
                    //######### Create Case #######//   

                    //Set RoutesalesPlanned__c to true when case/wo/woli are constructed
                    accLoc.RoutesalesPlanned__c = true;
                }

                //Add account location records on the list to be updated
                accLocationList.add(accLoc);
            }


            //Karen Hung Nov. 14, 2018
            //PROCESS ALL RECORDS WITH CreateRoutesalesJob__c = TRUE
            if(!accLocWithCreateList.isEmpty()){

                Map<Id,Id> map_acctLocContact_create = getAccLocContactList(accLocWithCreateList);
                for(Apttus_Config2__AccountLocation__c accLoc : accLocWithCreateList){
                    
                    //######### Create Work Order Line Item #######//    
                    WorkOrderLineItem woli = createWorkOrderLineItem(accLoc);
                    woliList.add(woli);
                    //######### Create Work Order Line Item #######//
                      
                    //Date nextRouteSales = accLoc.LastRoutesalesDate__c != null? accLoc.LastRoutesalesDate__c : accLoc.NextRoutesalesDate__c;
                    Date nextRouteSales = accLoc.NextRoutesalesDate__c != null? accLoc.NextRoutesalesDate__c : accLoc.LastRoutesalesDate__c;

                    DateTime startTime = getStartAndEndDates(nextRouteSales, 
                                    map_CountryAndBusinessHours.get(accLoc.Mini_Sales_Organization__c).Business_Hours__r.MondayStartTime, 
                                    true);

                    //Set the SLA Date with the last business day of the week of the Next Routesales Date using the business hours as a reference.
                     DateTime endTime = getStartAndEndDates(nextRouteSales, 
                                    map_CountryAndBusinessHours.get(accLoc.Mini_Sales_Organization__c).Business_Hours__r.FridayEndTime, 
                                    false);

                    //XEN REYES DOO-4265 Mar. 26, 2020
                    if(accLoc.Day_of_Visit__c != null && accLoc.Day_of_Visit__c != 0 && accLoc.Day_of_Visit__c <= 5){
                        startTime = startTime.addDays(Integer.valueOf(accLoc.Day_of_Visit__c) - 1);
                        endTime = DateTime.newInstance(startTime.date(), endTime.time());
                    }

                    //######### Create Case #######//
                    Case cse = createCaseRecords(accLoc,startTime,endTime, map_acctLocContact_create);
                    caseToInsert.add(cse);
                    //######### Create Case #######// 

                    //Set RoutesalesPlanned__c to true when case/wo/woli are constructed
                    accLoc.RoutesalesPlanned__c = true; 

                    //Add account location records on the list to be updated
                    accLocationList.add(accLoc); 
                }
            }

            //Insert Case Records
            if (!caseToInsert.isEmpty()){
                insert caseToInsert;
            }

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
                    wo.CaseId = cse.Id;
                    wo.OwnerID = caseMapWO.get(cse.Id) != null? caseMapWO.get(cse.Id).OwnerId : cse.OwnerId;
                    wo.Status = TS_Constants.TS_Status_Open;
                    wo.SalesOrganization__c = cse.SalesOrganization__c;

                    woMap.put(cse.CaseExternalReference__c, wo);
                    caseMap.put(cse.CaseExternalReference__c, cse);
            }

            if (!woMap.isEmpty()){
                insert woMap.values(); 
            }

            system.debug('Casemap route' + casemap);

            //The field Next Routesales Visit needs to be populated with the created Case Id.
            for (Apttus_Config2__AccountLocation__c accLoc : accountLocList) {
                if (caseMap.get(accLoc.Id) != null) {
                    system.debug('karen  casemap' + caseMap);
                    accLoc.NextRoutesalesVisit__c = caseMap.get(accLoc.Id).Id;
                    accLocList.add(accLoc);
                } else {
                    accLocList.add(accLoc);
                }
            }

            //Create and insert work order line item records
            for (WorkOrderLineItem woli: woliList) {
                if (!woMap.isEmpty() && woMap.get(woli.WOLIExternalReference__c) != null
                    && !caseMap.isEmpty() && caseMap.get(woli.WOLIExternalReference__c) != null) {
                    woli.Case__c = woMap.get(woli.WOLIExternalReference__c).CaseId;
                    woli.WorkOrderId = woMap.get(woli.WOLIExternalReference__c).Id;
                    woli.EarlyStart__c = caseMap.get(woli.WOLIExternalReference__c).EarlyStartDate__c;
                    woli.SLADate__c = caseMap.get(woli.WOLIExternalReference__c).SLADate__c;
                    woli.Subject = caseMap.get(woli.WOLIExternalReference__c).Subject;
                    woli.Description = caseMap.get(woli.WOLIExternalReference__c).Description;
                    woli.FirstRoutesalesVisit__c =  caseMap.get(woli.WOLIExternalReference__c).FirstRoutesalesVisit__c;
                    woliToInsert.add(woli);
                }
            }

            if (!woliToInsert.isEmpty()){  
                insert woliToInsert;
            }

            //System.debug('XEN Nov 15: ' + accLocList);
            //Update account location records
            if (Schema.sObjectType.Apttus_Config2__AccountLocation__c.isUpdateable() && !accLocList.isEmpty()) {

                //FOR TEST CLASS COVERAGE
                if(forceError && Test.isRunningTest()){
                    accLocList[0].Name = '';
                    accLocList[0].Apttus_Config2__AccountId__c = null;
                }

                Database.SaveResult[] saveResultList = Database.update(accLocList, false);
                
                /* for (Database.SaveResult sr: saveResultList) {
                    if (!sr.isSuccess()) {
                        //Operation failed. Get error details               
                        for(Database.Error err : sr.getErrors()) {
                            String msg = TS_Constants.ERRBATCH_MSG_01 + err.getStatusCode() + ': ' + err.getMessage() + ': ' + err.getFields();
                            exception_List.add(msg);
                        }
                    }
                } */

                //XEN REYES - Custom Logging for Database.Error
                customLoggingForUpdates(accLocList, saveResultList);
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
    * @date           04.14.2018
    * @description    Method responsible for final changes or updates whitin the batch of records
    * @revision(s)
    ******************************************************************************/ 
    global void finish(Database.BatchableContext BC) {
        CustomLogging.push(TS_Constants.CONST_FINISH, TS_Constants.CONST_BATCH);

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
    * @date           04.14.2018
    * @description    Method responsible for setting work order line item values
    * @revision(s)
    ******************************************************************************/ 
    @TestVisible
    private WorkOrderLineItem createWorkOrderLineItem(Apttus_Config2__AccountLocation__c accLoc) {
        CustomLogging.push(TS_Constants.CONST_CREATEWOLI, TS_Constants.CONST_BATCH);
        WorkOrderLineItem woli = new WorkOrderLineItem();
        woli.Status = TS_Constants.TS_Status_Open;
        woli.AccountLocation__c = accLoc.Id;
        woli.WorkOrderLineItemType__c = TS_Constants.TS_Type_Task;
        woli.WorkOrderType__c = TS_Constants.TS_Case_SubType_S25;
        woli.WOLIExternalReference__c = String.valueOf(accLoc.Id); 
        if(accloc.Preferred_Routesales_Employee__c!=null){
       		woli.PreferredEngineer__c = accLoc.Preferred_Routesales_Employee__c;
        }

        CustomLogging.pop();  
        return woli;
    }

    /******************************************************************************
    * @author         Paul Jarred Aguiling
    * @date           04.14.2018
    * @description    Method responsible for setting case values
    * @revision(s)
    ******************************************************************************/ 
    @TestVisible
    private Case createCaseRecords(Apttus_Config2__AccountLocation__c accLoc, DateTime startDate, DateTime endDate, Map<Id, Id> accLocContactMap) {
        CustomLogging.push(TS_Constants.CONST_CREATECASE, TS_Constants.CONST_BATCH);
        Case cse = new Case();
        cse.SalesOrganization__c = accLoc.Mini_Sales_Organization__c;
        //cse.OwnerId = UserInfo.getUserId();
        cse.Status = TS_Constants.TS_Status_New; 
        cse.Type = TS_Constants.TS_Case_Type_RouteSales;
        cse.SubType__c = TS_Constants.TS_Case_SubType_S25;
        cse.Subject = TS_Constants.ROUTESALES_DESCSUBJ;
        cse.Description = TS_Constants.ROUTESALES_DESCSUBJ;
        cse.AccountLocation__c = accLoc.Id;
        cse.EarlyStartDate__c = startDate;
        cse.SLADate__c = endDate;
        cse.CaseExternalReference__c = String.valueOf(accLoc.Id);
        cse.Origin = TS_Constants.TS_CaseOrigin_RouteSalesBatch;
        cse.FirstRoutesalesVisit__c = accLoc.LastRoutesalesDate__c != null? false : true;

        //XEN REYES 9.28.2018 KTS-2196: This is to ensure that even if the default owner is Individual, the case will be routed to the correct queue.
        cse.AssignToQueue__c = true;
        cse.TS_IsGeneratedFromBatch__c = true;

        //KTS-1821 6.27.2018 Added By Paul Aguiling
        if (accLoc.Route_Sales_Main_Contact__c != null) {
            cse.ContactId = accLoc.Route_Sales_Main_Contact__c; 
        //Assigned the right contact based on the filtered child contacts of Accounts account location (Account)
        } else if (accLoc.Apttus_Config2__AccountId__c != null 
            && accLocContactMap != null 
            && accLocContactMap.get(accLoc.Id) != null) {
            cse.ContactId =  accLocContactMap.get(accLoc.Id);
        }
 
        CustomLogging.pop();
        return cse;
    }


    /**
    * @author        Paul Jarred Aguiling
    * @date          04.14.2018         
    * @description   Method responsible for retrieving start and end dates of the landing week of route sales date
    * @revision(s)
    */
    private static DateTime getStartAndEndDates(Date nextRouteSalesDate, Time dayTime, Boolean isStartDay) {
        CustomLogging.push(TS_Constants.CONST_STARTENDDATES, TS_Constants.CONST_BATCH);
        Date newTargetDate = nextRouteSalesDate;
        DateTime resultDateTime = null;

        //Get the business start day of the week which is Monday
        if (isStartDay) {
            while (!TS_Constants.TS_SLA_Monday.equals(TS_UtilityClass.getReadableDay(newTargetDate))) {
                newTargetDate = newTargetDate.addDays(-1);
            }

            //Assign the date of Monday and time coming from business hours
            resultDateTime = DateTime.newInstance(newTargetDate, dayTime);

        //Get the business end day of the week which is Friday
        } else {
            while (!TS_Constants.TS_SLA_Friday.equals(TS_UtilityClass.getReadableDay(newTargetDate))) {
                newTargetDate = newTargetDate.addDays(1);
            }

            //Assign the date of Friday and time coming from business hours
            resultDateTime = DateTime.newInstance(newTargetDate, dayTime);
        }

        CustomLogging.pop();
        return resultDateTime;
    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          04.14.2018         
    * @description   Method responsible for retrieving country specific settings for Netherlands sales org
    * @revision(s)
    */
    private List<CountrySetting__c> getCountrySettings() {
        CustomLogging.push(TS_Constants.CONST_GETCOUNTRY, TS_Constants.CONST_BATCH);
        //Get all country settings with record type CountryDefaultBusinessHours
        List<CountrySetting__c> countrySetList = [SELECT Name, Country__c, Business_Hours__c, 
                                                         Business_Hours__r.MondayStartTime,
                                                         Business_Hours__r.FridayEndTime,
                                                         RecordType.DeveloperName,
                                                         RouteSalesThreshold__c
                                                  FROM CountrySetting__c 
                                                  WHERE (RecordType.DeveloperName = :TS_Constants.TS_CountrySettingRecType_CountryDefBusHrs
                                                  OR RecordType.DeveloperName = :TS_Constants.TS_CountrySettingRecType_RouteSales)
                                                  AND Active__c = true
                                                  AND (Country__c = :TS_Constants.TS_SalesOrg_Netherlands
                                                  OR Country__c = :TS_Constants.TS_SalesOrg_Denmark 
                                                  OR Country__c = : TS_Constants.CONST_SAP_0333
                                                  OR Country__c = : TS_Constants.CONST_SAP_6712)];
        
        CustomLogging.pop(); 
        return countrySetList;
    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          04.14.2018           
    * @description   Method used to get business confirmation date
    * @revision(s)
    */
    private static DateTime getConfirmationDate(Id businessHoursId, Date targetDate, Integer offSet) {
        CustomLogging.push(TS_Constants.CONST_GETCONDATE, TS_Constants.CONST_BATCH);
        Integer newOffSet = offSet != null? offSet : 0;

        //Convert LastRouteSales Date/targetDate into Date/Time to avoid issue in computation of within business hours 
        DateTime newTargetDate = Datetime.newInstance(targetDate.year(), targetDate.month(), targetDate.day());
        newTargetDate = BusinessHours.nextStartDate(businessHoursId, newTargetDate);
        newTargetDate = targetDate != newTargetDate.date() ? BusinessHours.add(businessHoursId, newTargetDate, -1000) : newTargetDate;

        //Use offset param to indicate the loop count
        for (Integer i = 1; i <= newOffSet; i++) {
            newTargetDate = newTargetDate.addDays(-1); //Deduct 1 day before calculating business day

            //Check for days falling on weekends in 24/7 business hours 
            if (TS_Constants.TS_SLA_Saturday.equals(TS_UtilityClass.getReadableDay(newTargetDate.date()))) {
                newTargetDate = newTargetDate.addDays(-1);
            } else if (TS_Constants.TS_SLA_Sunday.equals(TS_UtilityClass.getReadableDay(newTargetDate.date()))) {
                newTargetDate = newTargetDate.addDays(-2);
            } 

            //Check the working day after validating weekend dates
            while (!BusinessHours.isWithin(businessHoursId, newTargetDate)) {
                newTargetDate = newTargetDate.addDays(-1);
            }
        }

        //After computing the given offset days. Determine that date is set on Monday within that week.
        while (!TS_Constants.TS_SLA_Monday.equals(TS_UtilityClass.getReadableDay(newTargetDate.date()))) {
            newTargetDate = newTargetDate.addDays(-1);
        }
        
        //Validate if Monday is a business day
        while (!BusinessHours.isWithin(businessHoursId, newTargetDate)) {
            newTargetDate = newTargetDate.addDays(-1);
        }

        CustomLogging.pop();
        return newTargetDate;
    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          06.27.2018           
    * @description   Method used to get account locations contact
    * @revision(s)
    */
    @TestVisible
    private Map<Id, Id> getAccLocContactList(List<Apttus_Config2__AccountLocation__c> accountLocList) {
        CustomLogging.push(TS_Constants.CONST_GETACCLOC, TS_Constants.CONST_BATCH);
        Map<Id, List<Contact>> contactMap = new Map<Id, List<Contact>>();
        Map<Id, Id> accLocContact = new Map<Id, Id>();
        List<Contact> mainServiceContactList = new List<Contact>();
        List<Contact> mainContactList = new List<Contact>();
        List<Contact> contactList = new List<Contact>();
        Set<Id> accountIds = new Set<Id>();

        //Iterate related accounts from the account location
        for (Apttus_Config2__AccountLocation__c accLoc : accountLocList) {
            if (accLoc.Apttus_Config2__AccountId__c != null) {
                accountIds.add(accLoc.Apttus_Config2__AccountId__c);
            }
        }

        if (accountIds != null && !accountIds.isEmpty()) {
            //Iterate list of contacts from the account location account id
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

            //Iterate account location records to then assign the correct contact
            for (Apttus_Config2__AccountLocation__c accLoc : accountLocList) {
                if (accLoc.Apttus_Config2__AccountId__c != null && contactMap.get(accLoc.Apttus_Config2__AccountId__c) != null) {
                    for (Contact con : contactMap.get(accLoc.Apttus_Config2__AccountId__c)) {
                        //Check if contact has Main Service Person
                        if (con.Main_Service_Person__c) {
                            accLocContact.put(accLoc.Id, con.Id);
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

                    //Assign service contact to respective account location
                    if (accLocContact.isEmpty() && !mainServiceContactList.isEmpty()) {
                        accLocContact.put(accLoc.Id, mainServiceContactList.get(0).Id);
                    //Assign main contact to respective account location
                    } else if (accLocContact.isEmpty() && !mainContactList.isEmpty()) {
                        accLocContact.put(accLoc.Id, mainContactList.get(0).Id);
                    //Assign contact to respective account location
                    } else if (accLocContact.isEmpty() && !contactList.isEmpty()) {
                        accLocContact.put(accLoc.Id, contactList.get(0).Id);
                    }
                }
            }
        }

        return accLocContact;
    }

    /**
    * @author        Abram Vixen Reyes
    * @date          Jan. 25, 2019
    * @description   Method to create a custom log record if there is failed record processed in the batch execution.
    * @revision(s)
    */
    private void customLoggingForUpdates(List<Apttus_Config2__AccountLocation__c> accLocList, List<Database.SaveResult> saveResultList) {

        //XEN REYES - Custom Logging for Database.Error
        List<Custom_Log__c> customLogs = new List<Custom_Log__c>();
        List<String> exception_List_batch = new List<String>();
        Set<Id> assetIdsToBeUpdatedSet = (new Map<Id,SObject>(accLocList)).keySet();
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
                    StackTrace__c = TS_Constants.ROUTESALES_BATCH,
                    Message__c = mainMessage + '\n' + TS_Constants.FAILEDRECORDS + JSON.serialize(failedIds),
                    ExceptionType__c = TS_Constants.DATABASE_ERROR);
                insert log;
            }
        }
    }
}