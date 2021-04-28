/**
 * @author        Archi Delphinanto
 * @date          5.March.2018
 * @description   Apex batch class used to schedule Counter Reading tasks and run Monthly. only run by system admin
 * @revision(s)   7.13.2018 Paul Aguiling KTS-1829: Updated createCounterReadingList()
 */
global with sharing class TS_CounterReading_Batch implements Database.Batchable < sObject > {

    String CONST_WORKORDER_CR_RT = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('Counter Reading').getRecordTypeId();
    String CONST_PHYSICALASSET_MACHINE_RT = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get('Machine').getRecordTypeId();
    String CONST_WOLI_TASK_CR_RT = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Counter Reading Task').getRecordTypeId();
    String CONST_WOLI_CHILD_CR_RT = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Counter Reading').getRecordTypeId();
    String CONST_COUNTRYSETTING_CR_RT = Schema.SObjectType.CountrySetting__c.getRecordTypeInfosByName().get('Counter Reading Scheduler').getRecordTypeId();
    String CONST_WOLI_OPEN_STATUS = 'Open';
    String CONST_WORKORDER_CR_TYPE = 'S21'; // S21 --> counter Reading
    String CONST_WOLI_CRTASK_TYPE = 'Counter'; //'Counter Reading Task';
    String CONST_WOLI_CHILD_CR_TYPE = 'Counter Reading';
    String CONST_WOLI_TYPECR_ORDINARY = 'Ordinary';
    Integer CONST_WOLI_SLA_INTERVAL = 10;
    Integer CONST_NUM_MONTH_TO_LOOKBACK = Integer.valueOf('-1'); // define the filter to get the counter reading records from physical asset
    Integer CONST_NUM_MONTH_TO_SCHEDULE = Integer.valueOf('1');
    Integer CONST_HOUR_STARTTIME = Integer.valueOf('6');
    Integer CONST_HOUR_ENDTIME = Integer.valueOf('18');
    String CONST_BATCH_ADMIN_EMAIL = Operating_Task__c.getInstance().Batch_Email__c; //'a.delphinanto@gmail.com';
    Boolean CONST_IS_SEND_EMAIL_WHEN_BATCH_FINISHED = Operating_Task__c.getInstance().Send_Email_Upon_Batch_Completion__c; //false;

    Date runDate;

    long starttime = Datetime.now().getTime();

    //XEN REYES 9.28.2018 KTS-2196: This is to ensure that even if the default owner is Individual, the work order will be routed to the correct queue.
    public Map<String, String> countrySAPCodeMap = new Map<String, String>();
    public Map<String, String> queueNameIdMap = new Map<String, String>();

    private Exception[] errors = new Exception[0];
    /******************************************************************************
     * @author        Karen Hung
     * @date          27.feb.2019
     * @description   Constructor KTS-2648 allow flexible date
     * @revision(s)
     ******************************************************************************/
    global TS_CounterReading_Batch(Date rDate) {
        CustomLogging.push('TS_CounterReading_Batch', 'TS_CounterReading_Batch');
        if(rDate == null){
            runDate = Date.Today();
        }else{
            runDate = rDate; 
        }   
        CustomLogging.pop();
    }


    global Database.QueryLocator start(Database.BatchableContext BC) {
        CustomLogging.push('start', 'TS_CounterReading_Batch');
        CustomLogging.pop();


        return Database.getQueryLocator(getQuery());
    }
    /******************************************************************************
     * @author         Archi Delphinanto
     * @date           5.March.2018
     * @description    This method proceses the result of query. Where the WOLI tasks are generated. 
     *                
     * @revision(s)
     ******************************************************************************/
    global void execute(Database.BatchableContext BC, List < PhysicalAsset__c > psl) {
        CustomLogging.push('execute', 'TS_CounterReading_Batch');

        //XEN REYES 9.28.2018 KTS-2196: This is to ensure that even if the default owner is Individual, the work order will be routed to the correct queue.
        //CREATE A MAP OF COUNTRY CODES
        countrySAPCodeMap = TS_UtilityClass.countrySAPCodeUtility();

        //CREATE A MAP FOR SERVICE PLANNING QUEUE
        queueNameIdMap = TS_UtilityClass.queueNameIdMapUtility();

        try {
            runCounterReadingbatch(psl);

        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
            //errors.add(ex);
        }

        CustomLogging.pop();
    }

    /******************************************************************************
     * @author         Archi Delphinanto
     * @date           5.March.2018
     * @description    This method to perform actions when the batch is finished
     * @revision(s)
     ******************************************************************************/
    global void finish(Database.BatchableContext BC) {
        CustomLogging.push('finish', 'TS_CounterReading_Batch');

        if (CONST_IS_SEND_EMAIL_WHEN_BATCH_FINISHED) {
            AsyncApexJob a = [Select Id, Status, ExtendedStatus, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email from AsyncApexJob where Id =: BC.getJobId()];
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {
                CONST_BATCH_ADMIN_EMAIL
            }; //{a.CreatedBy.Email};
            long endTime = Datetime.now().getTime();
            long totalbatchtime = (endtime - starttime) / 1000;
            String infoTime = String.valueOf(totalbatchtime);
            //email message
            string emailMessage = '=======================Batch Summary============================ \n' +
                'Batch jobs processed: ' + a.JobItemsProcessed + '<br/>' +
                'Total batch process time (Second): ' + totalbatchtime + '<br/>' +
                'Number of errors: ' + a.NumberOfErrors + '<br/>' +
                'Batch submmitted by: ' + a.CreatedBy.Email + '<br/>' +
                '================================================================';
            mail.setToAddresses(toAddresses);
            mail.setSubject('Counter Reading Batch Result: ' + a.Status); // 
            mail.setPlainTextBody(emailMessage);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {
                mail
            });
        }

        System.debug('errors >> ' + errors);
        CustomLogging.pop();
    }


    /******************************************************************************
     * @author         Archi Delphinanto
     * @date           5.March.2018
     * @description    This method returns a SQL syntax on active operating schedule table
     * @revision(s)
     ******************************************************************************/
    private String getQuery() {
        CustomLogging.push('getQuery', 'TS_CounterReading_Batch');
        DescribeSObjectResult physicalAsseteDescribe = PhysicalAsset__c.getSObjectType().getDescribe();
        List<String> fields = new List<String>(physicalAsseteDescribe.fields.getMap().keySet());
        CustomLogging.pop();

        return 'SELECT ' +
            ' AccountLocation__c, Building__c, Floor__c, OP_PCB_Changed__c, Area__c, Machine_Care__c,PostalCode__c, Street__c, LastPreventiveMaintenanceDate__c, Product__c, OP_PreferredOperator__c, SalesOrganization__c, ' +
            ' LastWTSDate__c, AccountLocation__r.SAP_Customer_ID__c, SoldTo__c, MothballAssetIndicator__c' +
            ' FROM ' + physicalAsseteDescribe.getName() +
            ' WHERE AssetStatus__c = \'Activated\' AND CounterReading__c = \'Yes\' AND RecordTypeId =:CONST_PHYSICALASSET_MACHINE_RT AND Connected__c = \'No\' AND MothballAssetIndicator__c = false';
    } 

    /******************************************************************************
     * @author         Archi Delphinanto
     * @date           5.March.2018
     * @description     
     * @revision(s)
     ******************************************************************************/
    public void runCounterReadingbatch(List < PhysicalAsset__c > psal) {
        CustomLogging.push('runCounterReadingbatch', 'TS_CounterReading_Batch');

        //-------------create pricebook entry map for woli task  
        Map < String, PricebookEntry > priceBookMap = createPriceBookEntryMap(psal);
        System.debug('TS Counter reading batch, priceBookMap size: ' + priceBookMap.size());

        // ------------create country setting map ---------------
        Map < String, CountrySetting__c > countrysettingMap = createCountrySettingMap(psal);
        System.debug('TS Counter reading batch, country setting Map size: ' + countrysettingMap.size());

        //------------------------Create work order map      
        Map < Id, WorkOrder > workOrderMap = createWorkOrderMap(psal, priceBookMap);
        System.debug('TS Counter reading batch, work order Map size: ' + workOrderMap.size());

        //--->>>>>to create a refence date to get the list of counter reading records on physical asset ------------///
        Date refdate = runDate.addMonths(CONST_NUM_MONTH_TO_LOOKBACK); //Karen Hung KTS-2648 2.28.2019 to base from rundate
        refdate = refdate.toStartOfMonth();

        // ------------------------Create Counter Reading List
        List < APTS_CounterReadingData__c > allCounterReadingList = createCounterReadingList(psal, refdate);
        System.debug('TS Counter reading batch, allCounterReadingList size: ' + allCounterReadingList.size());

        //------------------------Create WOLI Counter Reading Task------------------------
        Date nextTaskDate = runDate.addMonths(CONST_NUM_MONTH_TO_SCHEDULE); //Karen Hung KTS-2648 2.28.2019 to base in rundate
        nextTaskDate = nextTaskDate.toStartOfMonth();
        //nextBatchDate= nextBatchDate.addDays(CONST_DAY_ON_THE_MONTH);
        Time nextTaskTime = Time.newInstance(CONST_HOUR_STARTTIME, 0, 0, 0);

        DateTime nextTaskDateTime = Datetime.newInstance(nextTaskDate, nextTaskTime);
        // Date taskStartDate = system.today().addMonths(CONST_NUM_MONTH_TO_SCHEDULE);//initialize start date
        // taskStartDate taskStartDate.toStartOfMonth();
        //taskStartDate= taskStartDate.addDays(CONST_DAY_ON_THE_MONTH);

        //potential fix
        // list <WorkOrderLineItem> woliList;
        // list <WorkOrderLineItem> subWoliList;

        List < WorkOrderLineItem > crTaskList = new List < WorkOrderLineItem > ();
        if (!workOrderMap.isEmpty() && !priceBookMap.isEmpty() && !countrysettingMap.isEmpty() && !psal.isEmpty()) {
            crTaskList = createCounterReadingTaskList(psal, nextTaskDateTime, workOrderMap, priceBookMap, countrysettingMap);
        }

        System.debug('TS Counter reading batch, crTaskList size: ' + crTaskList.size());
        System.debug('TS Counter reading batch, crTaskList: ' + crTaskList);

        /* potential fix May 2018
          if (!crTaskList.isEmpty()) {
            woliList.addAll(crTaskList);
            subWoliList= createCounterReadingSubTask(crTaskList, allCounterReadingList );
            woliList.addAll(subWoliList);

          if (Schema.sObjectType.WorkOrderLineItem.isCreateable())   Database.SaveResult[] saveResults =Database.insert(woliList, false);
        } */

        //if no woli generated, then delete the work order has been created

        if (crTaskList.isEmpty()) {
            delete workOrderMap.values();
        }

        //------------------------Create Sub WOLI for WOLI Counter Reading Task------------------------
        ////potential fix May 2018 disable below line
        else if (!crTaskList.isEmpty()) {
            //createCounterReadingSubTask(crTaskList, allCounterReadingList); COMMENT XEN REYES Nov. 19, 2018

            for (WorkOrderLineItem crw: crTaskList) {
                crw.isCRswoliisloaded__c = true;
            }

            if (!crTaskList.isEmpty()) { //KTS-2040 Add null checking to prevent creation issues
                update crTaskList;
            }

        }
        CustomLogging.pop();
    }

    /******************************************************************************
     * @author         Archi Delphinanto
     * @date           
     * @description    .
     * @revision(s)
     ******************************************************************************/
    public List < APTS_CounterReadingData__c > createCounterReadingList(List < PhysicalAsset__c > psl, Date referencedDate) {
        CustomLogging.push('createCounterReadingList', 'TS_CounterReading_Batch');
        List < APTS_CounterReadingData__c > crList = new List < APTS_CounterReadingData__c > ();

        if (psl.size() > 0) {
            for (APTS_CounterReadingData__c cr: [select id,
                    APTS_AvgConsumptionFree__c, APTS_AvgConsumptionPaid__c,
                    APTS_ConsumerPrice__c,
                    APTS_CounterID__c,
                    APTS_CounterSequence__c,
                    APTS_Cup_Size__c, APTS_Current_Reading_Date__c, APTS_Current_Reading_ValueFree__c, APTS_Current_Reading_ValuePaid__c,
                    //APTS_Grammages__c, // as per mike request                
                    Name,
                    TS_Physical_Asset__c,
                    //APTS_Machine_Serial_No__c, 
                    APTS_Counter_Description__c
                    //APTS_Asset_Line_Item__c,  APTS_Atrribute_Value__c, APTS_Charge_Type__c,  LastReferencedDate,LastViewedDate
                    //SystemModstamp,CurrencyIsoCode,IsDeleted,
                    FROM APTS_CounterReadingData__c
                    WHERE TS_Physical_Asset__c IN: psl
                    AND APTS_Counter_Status__c = 'Active' //KTS-1829: All inactive values should not be retrieved. 7.13.2018 Added by Paul Aguiling 
                    AND APTS_CounterId__c != null
                    //AND APTS_Current_Reading_Date__c >= :referencedDate XEN REYES 9.19.2018
                    ORDER BY TS_Physical_Asset__c ASC
                ]) {

                crList.add(cr);
            }

        }
        CustomLogging.pop();
        return crList;
    }


    /******************************************************************************
     * @author         Archi Delphinanto
     * @date           5.March.2018
     * @description    to create work order records for woli 
     * @revision(s)
     ******************************************************************************/
    private Map < Id,
    WorkOrder > createWorkOrderMap(List < PhysicalAsset__c > psl, Map < String, PricebookEntry > priceBookMap) {
        CustomLogging.push('createWorkOrders', 'TS_CounterReading_Batch');
        Map < Id, workOrder > lworkOrderMap = new Map < Id, WorkOrder > ();

        for (PhysicalAsset__c ps: psl) {
            WorkOrder workOrder = new WorkOrder();
            workOrder.RecordTypeId = CONST_WORKORDER_CR_RT;

            //-------------to set pricebook entry
            String priceBookKey = String.valueOf(ps.Product__c) + ps.SalesOrganization__c;
            workOrder.Pricebook2Id = priceBookMap.get(priceBookKey) != null ? priceBookMap.get(priceBookKey).Pricebook2Id : null; //KTS-2040 Add null checking to prevent creation issues
            //----------------------------------        
            workOrder.OP_Physical_Asset__c = ps.Id;
            workOrder.SalesOrganization__c = ps.SalesOrganization__c;
            workOrder.AccountId = ps.SoldTo__c;
            workOrder.WorkOrderType__c = CONST_WORKORDER_CR_TYPE;

            //XEN REYES 9.28.2018 KTS-2196: This is to ensure that even if the default owner is Individual, the work order will be routed to the correct queue.
            workOrder.OwnerId = UserInfo.getUserId();
            if(countrySAPCodeMap.containsKey(workOrder.SalesOrganization__c)){
                if(queueNameIdMap.containsKey(countrySAPCodeMap.get(workOrder.SalesOrganization__c))){
                    workOrder.OwnerId = queueNameIdMap.get(countrySAPCodeMap.get(workOrder.SalesOrganization__c));
                } 
            }

            lworkOrderMap.put(ps.Id, workOrder);
        }
        if (Schema.sObjectType.WorkOrder.isCreateable()) {
            Database.SaveResult[] lsr2 = Database.insert(lworkOrderMap.values(), false);
            // for (Database.SaveResult ds:lsr2 ){if (!ds.isSuccess())system.debug('Error in inserting Operating Task work order>>>>>> '+ lsr2);} 
        }
        //System.debug(' wo map : '+lworkOrderMap);
        CustomLogging.pop();
        return lworkOrderMap;
    }
    /******************************************************************************
     * @author         Archi Delphinanto
     * @date           5.March.2018
     * @description    
     * @revision(s)
     ******************************************************************************/
    private Map < String,
    PricebookEntry > createPriceBookEntryMap(List < PhysicalAsset__c > psl) {
        CustomLogging.push('createCounterReadingList', 'TS_CounterReading_Batch');
        Map < String, PricebookEntry > prMap = new Map < String, PricebookEntry > ();

        set < ID > productSet = new set < ID > ();
        Set < String > salesOrganizationSet = new Set < string > ();
        for (PhysicalAsset__c ps: psl) {
            productSet.add(ps.Product__c);
            salesOrganizationSet.add(ps.SalesOrganization__c);
        }

        //GET PRICEBOOK ENTRY
        //List <PricebookEntry> pbeList;
        if (!(productSet.isEmpty() || salesOrganizationSet.isEmpty())) {

            for (PricebookEntry pbe: [SELECT Id, Product2Id, Pricebook2Id, Sales_Organization__c
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
     * @author         Archi Delphinanto
     * @date           5.March.2018
     * @description    
     * @revision(s)
     ******************************************************************************/
    private Map < String,
    CountrySetting__c > createCountrySettingMap(List < PhysicalAsset__c > psl) {
        CustomLogging.push('createCounterReadingList', 'TS_CounterReading_Batch');
        Map < String, CountrySetting__c > csMap = new Map < String, CountrySetting__c > ();

        //set<ID> productSet =  new set<ID>();
        List < String > countrySettingSet = new List < String > ();

        for (PhysicalAsset__c ps: psl) {
            countrySettingSet.add(ps.SalesOrganization__c);
        }

        //GET COUNTRY SETTING

        if (!countrySettingSet.isEmpty()) {

            for (CountrySetting__c crs: [SELECT id, country__c, DefaultStartTime__c, DefaultEndTime__c, Number_SLA_day__c from countrysetting__c
                    WHERE recordtypeid =: CONST_COUNTRYSETTING_CR_RT
                    //AND sales_organization__c!=null 
                    AND country__c in: countrySettingSet
                    AND Active__c = true
                    ORDER BY country__c ASC
                ]) {
                //String cMapKey =  ;                
                csMap.put(crs.country__c, crs);
            }
        }

        CustomLogging.pop();
        return csMap;
    }
    /******************************************************************************
     * @author         Archi Delphinanto
     * @date           5.March.2018
     * @description    to Create the list of WOLI task based on the inputs
     * @revision(s)
     ******************************************************************************/
    Private list < WorkOrderLineItem > createCounterReadingTaskList(List < PhysicalAsset__c > psalist, Datetime taskStartDate, Map < Id, WorkOrder > woMap, Map < String, PricebookEntry > priceBookMap, Map < String, CountrySetting__c > csMap) {
        CustomLogging.push('createCounterReadingTask', 'TS_CounterReading_Batch');

        List < WorkOrderLineItem > parentWoliList = new List < WorkOrderLineItem > ();
        for (PhysicalAsset__c ps: psalist) {
            WorkOrderLineItem woliTask = new WorkOrderLineItem();
            woliTask.AccountLocation__c = ps.AccountLocation__c;
            woliTask.WorkOrderLineItemType__c = CONST_WOLI_CRTASK_TYPE; //    

            Date startDate = runDate.addMonths(CONST_NUM_MONTH_TO_SCHEDULE); //Karen Hung KTS-2648 to base from runDate
            startDate = startDate.toStartOfMonth();
            Time defStartTime = Time.newInstance(Integer.valueOf(csMap.get(ps.SalesOrganization__c).DefaultStartTime__c), 0, 0, 0);
            DateTime startDateTime = Datetime.newInstance(startDate, defStartTime);
            //woliTask.StartDate__c=startDateTime;
            //woliTask.EarlyStart__c = startDateTime;
            Time endtime = Time.newInstance(Integer.valueOf(csMap.get(ps.SalesOrganization__c).DefaultEndTime__c), 0, 0, 0);
            Integer intDayToAddforSLA = Integer.valueOf(csMap.get(ps.SalesOrganization__c).Number_SLA_day__c);
            intDayToAddforSLA = intDayToAddforSLA < 0 ? 0 : intDayToAddforSLA - 1;
            Date enddate = startDate.addDays(intDayToAddforSLA);
            DateTime enddatetime = Datetime.newInstance(enddate, endtime);
            //Integer intSLAday =Integer.valueOf(csMap.get(ps.SalesOrganization__c).Number_SLA_day__c);
            woliTask.SLADate__c = enddatetime; //taskStartDate.addDays(intSLAday);
            //woliTask.SLADate__c= taskStartDate.addDays(CONST_WOLI_SLA_INTERVAL);

            woliTask.Building__c = ps.Building__c;
            //woliTask.SAP_Customer_ID__c= ps.AccountLocation__r.SAP_Customer_ID__c; // it is formula field
            woliTask.Floor__c = ps.Floor__c;
            woliTask.OP_PCBchanged__c = ps.OP_PCB_Changed__c;
            woliTask.PhysicalAsset__c = ps.Id;
            woliTask.RecordTypeId = CONST_WOLI_TASK_CR_RT;
            woliTask.Status = CONST_WOLI_OPEN_STATUS;
            woliTask.WorkOrderId = woMap.get(ps.id).Id;
            //workOrderMap.get(task.PhysicalAsset__c).Id;
            woliTask.MachineCare__c = ps.Machine_Care__c;
            woliTask.Area__c = ps.Area__c;
            woliTask.WorkOrderType__c = CONST_WORKORDER_CR_TYPE;
            woliTask.PostalCode__c = ps.PostalCode__c;
            woliTask.StreetAndHouseNumber__c = ps.Street__c;
            woliTask.OP_PreferredOperator__c = ps.OP_PreferredOperator__c;
            woliTask.PreventiveMaintenancePerformedDate__c = ps.LastPreventiveMaintenanceDate__c;
            //-------------to set pricebook entry
            String priceBookKey = String.valueOf(ps.Product__c) + ps.SalesOrganization__c;
            woliTask.PricebookEntryId = priceBookMap.get(priceBookKey) != null ? priceBookMap.get(priceBookKey).Id : null; //KTS-2040 Add null checking to prevent creation issues
            //-----------------------------------------------------//
            //woliTask.Product__c = ps.Product__c;
            woliTask.FilterChangeDate__c = ps.LastWTSDate__c;
            woliTask.TypeofCounterReadingTask__c = CONST_WOLI_TYPECR_ORDINARY;

            //KTS-2189 XEN REYES 9.22.2018
            woliTask.Re_active__c = true;

            parentWoliList.add(woliTask);
        }

        if (!parentWoliList.isempty() && Schema.sObjectType.WorkOrderLineItem.isCreateable()) {
            Database.SaveResult[] saveResults = Database.insert(parentWoliList, false);
            //System.debug ('save results:  '+saveResults);
        }

        CustomLogging.pop();
        return parentWoliList;
    }
    /******************************************************************************
     * @author         Archi Delphinanto
     * @date           5.March.2018
     * @description    to Create sub WOLI of counter reading for Counter reading task 
     * @revision(s)
     ******************************************************************************/
    /* private void createCounterReadingSubTask(List < WorkOrderLineItem > crTaskList, List < APTS_CounterReadingData__c > allCounterReadingList) {
        //WorkOrderLineItem createCounterReadingChildWOLI(WorkOrderLineItem parentWoli){
        CustomLogging.push('createCounterReadingChildWOLI', 'TS_CounterReading_Batch');
        //WorkOrderLineItem woliChild = new WorkOrderLineItem();
        List < WorkOrderLineItem > allWoliChildList = new List < WorkOrderLineItem > ();

        for (WorkOrderLineItem parentWoli: crTaskList) {
            List < APTS_CounterReadingData__c > crSamePAList = groupCRListBasedOnPA(allCounterReadingList, parentWoli.PhysicalAsset__c);

            for (APTS_CounterReadingData__c cr: crSamePAList) {
                WorkOrderLineItem woliChild = new WorkOrderLineItem();
                woliChild.WorkOrderLineItemType__c = CONST_WOLI_CHILD_CR_TYPE; //parentWoli.WorkOrderLineItemType__c ;CONST_WOLI_CHILD_CR_TYPE = 'Counter Reading'; 
                woliChild.WorkOrderId = parentWoli.WorkOrderId;
                woliChild.OP_AverageFreeConsumptions__c = String.valueOf(cr.APTS_AvgConsumptionFree__c);
                woliChild.OP_AveragePaidConsumptions__c = String.valueOf(cr.APTS_AvgConsumptionPaid__c);
                woliChild.OP_ConsumptionGroup__c = String.valueOf(cr.APTS_Counter_Description__c);
                woliChild.PhysicalAsset__c = parentWoli.PhysicalAsset__c;//it is not included so will not be listed in the physical asset related list 
                woliChild.ParentWorkOrderLineItemId = parentwoli.id;
                woliChild.RecordTypeId = CONST_WOLI_CHILD_CR_RT;
                woliChild.OP_LastFreeVendingCounterReading__c = cr.APTS_Current_Reading_ValueFree__c;
                woliChild.OP_LastPaidCounterReading__c = cr.APTS_Current_Reading_ValuePaid__c;
                if (cr.APTS_Current_Reading_Date__c != null) {
                    woliChild.OP_LastReadingDate__c = cr.APTS_Current_Reading_Date__c.date();
                }

                woliChild.Asset_Counter_Reading_Data__c = cr.id; //Karen Hung 11.9.2018 KTS-2313
                woliChild.OP_UniquecounterID__c = cr.APTS_CounterID__c;
                woliChild.Status = CONST_WOLI_OPEN_STATUS;
                woliChild.OP_CounterSequence__c = cr.APTS_CounterSequence__c;
                wolichild.OP_CupSize__c = cr.APTS_Cup_Size__c;
                //woliChild.OP_Grammages__c = cr.APTS_Grammages__c; 
                woliChild.OP_ConsumerPrice__c = cr.APTS_ConsumerPrice__c;
                //below inserted by engineer
                //woliChild.CounterMissingOnMachine__c = ;
                //woliChild.MeterMissingonContract__c = ;
                //woliChild.OutofboundReading__c = ;
                allWoliChildList.add(woliChild);
            }
        }
        //potential fix May 2018
        //disable below line
        System.debug('TS Counter reading batch, allWoliChildList.size: ' + allWoliChildList.size());

        if (!allWoliChildList.isempty() && Schema.sObjectType.WorkOrderLineItem.isCreateable()) {
            Database.SaveResult[] saveResults = Database.insert(allWoliChildList, false);
            //for (Database.SaveResult ds:saveResults ){if (!ds.isSuccess())system.debug('Error in inserting Counter Readingk work order>>>>>> '+ ds);} 
            System.debug(saveResults);
        }

        customLogging.pop();

        //potential fix May 2018
        // return allWoliChildList;

    } */
    
    /******************************************************************************
     * @author         Archi Delphinanto
     * @date           
     * @description    .
     * @revision(s)
     ******************************************************************************/
    public List < APTS_CounterReadingData__c > groupCRListBasedOnPA(List < APTS_CounterReadingData__c > allCRDList, Id physicalAssetID) {
        CustomLogging.push('groupCRListBasedOnPA', 'TS_CounterReading_Batch');
        List < APTS_CounterReadingData__c > crPAList = new List < APTS_CounterReadingData__c > ();

        for (APTS_CounterReadingData__c crd: allCRDList) {
            if (crd.TS_Physical_Asset__c == physicalAssetID) crPAList.add(crd);
        }
        CustomLogging.pop();
        return crPAList;
    }
}