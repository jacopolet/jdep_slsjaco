/**
 * @author        Archi Delphinanto
 * @date          5.feb.2018
 * @description   Apex batch class used to schedule Operating tasks and run nightly
 * @revision(s)
 */

global with sharing class TS_OperatingTask_Batch implements Database.Batchable < sObject > {
    Map<String,Integer> numberOfTasksMap = new Map<String,Integer > { null => 0, 'null' => 0, '0' => 0, '1' => 1, '2' => 2, '3' => 3, '4' => 4, 'AM' => 1, 'PM' => 1 };
    List<WorkOrderLineItem> tasks;
    String CONST_SmallTask_API = Label.TS_Operating_Small, CONST_LargeTask_API = Label.TS_Operating_Large, CONST_RinseTask_API = Label.TS_Operating_Rinse, CONST_CupsTask_API = Label.TS_Operating_Cups;
    String CONST_SmallTask_ACTIVITY = 'Small', CONST_LargeTask_ACTIVITY = 'Large', CONST_RinseTask_Activity = 'Rinse', CONST_CupsTask_Activity = 'Cups';
    String CONST_AM_Time = 'AM', CONST_PM_Time = 'PM';
    String CONST_REG = 'regularbatch', CONST_BWK = 'holidaybatchBWK', CONST_FWD = 'holidaybatchFWD', CONST_FWDBWK = 'holidaybatchFWDBWK';
    String CONST_COMFORTOP = 'Comfort Operating', CONST_FULLOP = 'Full Operating';
    String CONST_WORKORDER_OP_RT = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('Operating Work Order').getRecordTypeId();
    String CONST_WORKORDER_OP_TYPE = Label.TS_Activity_Type_S20;
    String CONST_WOLI_OP_RT = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Operating Task').getRecordTypeId();
    String CONST_WOLI_OPEN_STATUS = 'Open';
    Boolean CONST_IS_SEND_EMAIL_WHEN_BATCH_FINISHED = Operating_Task__c.getInstance().Send_Email_Upon_Batch_Completion__c; //false;
    String CONST_BATCH_ADMIN_EMAIL = Operating_Task__c.getInstance().Batch_Email__c;
    long starttime;

    private Exception[] errors = new Exception[0];
    Map<Integer,Boolean> futureholidayMap = new Map<Integer,Boolean>();
    Map<Integer,Boolean> pastholidayMap = new Map<Integer,Boolean>();
    Integer defaultstarttime;
    Integer defaultendtime;
    Date runDate;
    String batchType;

    //ALM 6243 XEN REYES March 26, 2019
    Boolean SENDCOUNTER_LARGE = false;

    //XEN REYES 9.28.2018 KTS-2196: This is to ensure that even if the default owner is Individual, the work order will be routed to the correct queue.
    public Map<String, String> countrySAPCodeMap = new Map<String, String>();
    public Map<String, String> queueNameIdMap = new Map<String, String>();

    //XEN REYES April 17, 2019 - ALM 6752
    public Boolean SOQL_OVERRIDE = false;
    public String NEW_SOQL_STRING;

    global TS_OperatingTask_Batch() {

    }

    /******************************************************************************
     * @author         Archi Delphinanto
     * @date           19.feb.2018
     * @description    Constructor
     * @revision(s)
     ******************************************************************************/
    global TS_OperatingTask_Batch(String btype, Date taskDate, Map < Integer, Boolean > fhMap, Map < Integer, Boolean > phMap, CountrySetting__c cs) {
        CustomLogging.push('TS_OperatingTasksBatch', 'TS_OperatingTasks_Batch');
        // initialize variables////////////////////
        runDate = taskDate;
        futureholidayMap.putAll(fhMap);
        pastholidayMap.putAll(phMap);
        batchType = btype;
        defaultstarttime = Integer.valueOf(cs.DefaultStartTime__c);
        defaultendtime = Integer.valueOf(cs.DefaultEndTime__c);
        //////////////////////////////////////////    

        //ALM 6243 XEN REYES March 26, 2019
        SENDCOUNTER_LARGE = EVALUATEDATE(runDate, cs);

        CustomLogging.pop();
    }

    /******************************************************************************
     * @author         Archi Delphinanto
     * @date           19.feb.2018
     * @description    This method is the start of the batch job
     * @revision(s)
     ******************************************************************************/
    global Database.QueryLocator start(Database.BatchableContext BC) {
        CustomLogging.push('start', 'TS_OperatingTasks_Batch');
        CustomLogging.pop();
        return Database.getQueryLocator(getQuery());
    }

    /******************************************************************************
    * @author         Archi Delphinanto
    * @date           19.feb.2018
    * @description    This method proceses the result of query. Where the WOLI tasks are generated. 
    *                 There are two main logics: 
                      1. runregularbatch (generating task during non holidays)
                      2. runHolidayBatch (generating task upon holidays)
    * @revision(s)
    ******************************************************************************/
    global void execute(Database.BatchableContext BC, List < OperatingSchedule__c > operatingSchedules) {
        CustomLogging.push('execute', 'TS_OperatingTasks_Batch');

        //Xen Reyes May 8, 2019
        WorkOrderLineItemTriggerHandler.IS_OPERATING_TASK = true;

        //XEN REYES 9.28.2018 KTS-2196: This is to ensure that even if the default owner is Individual, the work order will be routed to the correct queue.
        //CREATE A MAP OF COUNTRY CODES
        countrySAPCodeMap = TS_UtilityClass.countrySAPCodeUtility();

        //CREATE A MAP FOR SERVICE PLANNING QUEUE
        queueNameIdMap = TS_UtilityClass.queueNameIdMapUtility();

        try {
            System.debug('XEN 9/18 batchType: ' + batchType);

            if(batchType != null){
                if (batchType.equals(CONST_REG)) {
                    runRegularBatch(runDate, operatingSchedules);
                } else if (batchType.equals(CONST_FWD) || batchType.equals(CONST_BWK) || batchType.equals(CONST_FWDBWK)) {
                    runHolidayBatch(runDate.addDays(-1), operatingSchedules, futureholidayMap, pastholidayMap, batchType);
                }

            //IF BATCH TYPE IS NULL - TOMMORROW IS HOLIDAY    
            } else {
                List<OperatingSchedule__c> regularOperatingSchedules = new List<OperatingSchedule__c>();

                //CHECK ALL OPERATING SCHEDULES IF SOME SHOULD BE SCHEDULED IN HOLIDAY
                for(OperatingSchedule__c op : operatingSchedules){
                    if(op.Schedule_Tasks_for_Holiday__c) regularOperatingSchedules.add(op);
                }

                if(!regularOperatingSchedules.isEmpty()) runRegularBatch(runDate, regularOperatingSchedules);
            }

            /* if (batchType.equals(CONST_REG)) {
                runRegularBatch(runDate, operatingSchedules);
            } else if (batchType.equals(CONST_FWD) || batchType.equals(CONST_BWK) || batchType.equals(CONST_FWDBWK)) {
                runHolidayBatch(runDate.addDays(-1), operatingSchedules, futureholidayMap, pastholidayMap, batchType);
            } */

        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
            errors.add(ex);
        }

        CustomLogging.pop();
    }

    /******************************************************************************
     * @author         Archi Delphinanto
     * @date           19.feb.2018
     * @description    This method to perform actions when the batch is finished
     * @revision(s)
     ******************************************************************************/
    global void finish(Database.BatchableContext BC) {
        CustomLogging.push('finish', 'TS_OperatingTasks_Batch');
        System.debug('errors >> ' + errors);

        /* if (CONST_IS_SEND_EMAIL_WHEN_BATCH_FINISHED) {
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
            mail.setSubject('Operating Batch Result: ' + a.Status); // 
            mail.setPlainTextBody(emailMessage);
            if (Operating_Task__c.getInstance().Send_Email_Upon_Batch_Completion__c) Messaging.sendEmail(new Messaging.SingleEmailMessage[] {
                mail
            });
        } */

        CustomLogging.pop();
    }

    /******************************************************************************
     * @author         Archi Delphinanto
     * @date           19.feb.2018
     * @description    This method returns a SQL syntax on active operating schedule table
     * @revision(s)
     ******************************************************************************/
    String getQuery() {
        CustomLogging.push('getQuery', 'TS_OperatingTasks_Batch');
        DescribeSObjectResult operatingScheduleDescribe = OperatingSchedule__c.getSObjectType().getDescribe();
        List < String > fields = new List < String > (operatingScheduleDescribe.fields.getMap().keySet());
        CustomLogging.pop();

        String DEFAULT_SOQL = 'SELECT ' + String.join(fields, ',') +
            ', PhysicalAsset__r.Product__c,  PhysicalAsset__r.SalesOrganization__c, PhysicalAsset__r.AccountLocation__c' +
            ', PhysicalAsset__r.Building__c,PhysicalAsset__r.AccountLocation__r.SAP_Customer_ID__c,PhysicalAsset__r.Floor__c' +
            ', PhysicalAsset__r.SoldTo__c, PhysicalAsset__r.OP_PreferredOperator__c, PhysicalAsset__r.MothballAssetIndicator__c, PhysicalAsset__r.Machine_Care__c' +
            ', PhysicalAsset__r.CounterReading__c, PhysicalAsset__r.Connected__c' + //ADDED Xen Reyes April 8,. 2019
            ', PhysicalAsset__r.AssetStatus__c' + //ADDED Xen Reyes April 17, 2019 ALM 6752
            ', Account_Location__r.Apttus_Config2__AccountId__c' + //Added by Karen Hung 26.06.2019 DOO-288
            ' FROM ' + operatingScheduleDescribe.getName() +
            ' WHERE Active__c = true ' +
            ' AND PhysicalAsset__c != null ' +
            ' AND TypeofContract__c != null ' +
            ' AND Schedule_Type__c = \'Regular\' ' +
            ' AND PhysicalAsset__r.MothballAssetIndicator__c = false ' +
            ' AND PhysicalAsset__r.AccountLocation__c != null ' + //ADDED Xen Reyes April 17, 2019 ALM 6752
            ' AND PhysicalAsset__r.AssetStatus__c = \'Activated\' '; //ADDED Xen Reyes April 17, 2019 ALM 6752

        if(SOQL_OVERRIDE){
            return NEW_SOQL_STRING;
        } else {
            return DEFAULT_SOQL;
        }
        
    }

    /******************************************************************************
    * @author         Archi Delphinanto
    * @date           19.feb.2018
    * @description    This method returns a set of Strings of physical asset ID of WOLI that has L 
                      task on the given date and contract type. This is to check if there is L task has been created
                      before a new operating task will be created for tomorrow.
    * @revision(s)
    ******************************************************************************/
    public set < String > getTomorrowWOLI_list(Set < ID > lPhysicalAsset, Datetime lDate, String contracttype) {
        CustomLogging.push('getTomorrowWOLI_list', 'TS_OperatingTasks_Batch');
        set < String > woliList = new set < String > ();

        if (lPhysicalAsset.size() > 0 && contracttype.equals(CONST_FULLOP)) {
            for (Workorderlineitem woli: [select id, PhysicalAsset__c from workorderlineitem
                    Where WorkOrderLineItemType__c =: CONST_LargeTask_ACTIVITY //'Large' 
                    And WorkOrderType__c =: CONST_WORKORDER_OP_TYPE // 'S20' //S20 is machine care
                    And MachineCare__c =: CONST_FULLOP //'Full Operating' 
                    And OP_247Customer__c = false
                    And PhysicalAsset__c in: lPhysicalAsset
                    And StartDate__c >=: lDate
                    And StartDate__c <: ldate.addDays(1)
                ]) {

                wolilist.add(woli.PhysicalAsset__c);
            }

            System.debug('XEN 9/17 lDate: ' + lDate);
            System.debug('XEN 9/17 FULLOPP: ' + wolilist);
        }
        if (lPhysicalAsset.size() > 0 && contracttype.equals(CONST_COMFORTOP)) {
            for (Workorderlineitem woli: [select id, PhysicalAsset__c from workorderlineitem
                    Where WorkOrderLineItemType__c =: CONST_LargeTask_ACTIVITY //'Large' 
                    And WorkOrderType__c =: CONST_WORKORDER_OP_TYPE //'S20' //S20 is machine care
                    And MachineCare__c =: CONST_COMFORTOP //'Comfort Operating'                                       
                    And PhysicalAsset__c in: lPhysicalAsset
                    And StartDate__c >=: lDate
                    And StartDate__c <: ldate.addDays(1)
                ]) {
                wolilist.add(woli.PhysicalAsset__c);
            }
        }
        CustomLogging.pop();
        return wolilist;
    }

    /******************************************************************************
     * @author         Archi Delphinanto
     * @date           19.feb.2018
     * @description    to return week number 1 or 2 on a scheduleddate from a start date
     * @revision(s)
     ******************************************************************************/
    Integer getWeekNumber(Date startDate, Date scheduledDate) {
        CustomLogging.push('getWeekNumber', 'TS_OperatingTasksBatch');
        Date d1 = startDate.toStartOfWeek();
        Date d2 = scheduledDate.toStartOfWeek();
        Integer numberOfWeeks = d1.daysBetween(d2) / 7;
        CustomLogging.pop();
        return Math.mod(numberOfWeeks, 2) == 0 ? 1 : 2;
    }
    /******************************************************************************
     * @author         Archi Delphinanto
     * @date           5.March.2018
     * @description    
     * @revision(s)
     ******************************************************************************/
    private Map < String,
    PricebookEntry > createPriceBookEntryMap(List < OperatingSchedule__c > osl) {
        CustomLogging.push('createCounterReadingList', 'TS_CounterReading_Batch');
        Map < String, PricebookEntry > prMap = new Map < String, PricebookEntry > ();

        set < ID > productSet = new set < ID > ();
        Set < String > salesOrganizationSet = new Set < string > ();
        for (OperatingSchedule__c os: osl) {
            productSet.add(os.PhysicalAsset__r.Product__c);
            salesOrganizationSet.add(os.PhysicalAsset__r.SalesOrganization__c);
        }

        //GET PRICEBOOK ENTRY
        List < PricebookEntry > pbeList;
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
     * @date           19.feb.2018
     * @description    to create work order records for woli 
     * @revision(s)
     ******************************************************************************/
    Map < Id,
    WorkOrder > createWorkOrders(List < OperatingSchedule__c > operatingSchedules, Map < String, PricebookEntry > priceBookMap) {
        CustomLogging.push('createWorkOrders', 'TS_OperatingTasks_Batch');
        Map < Id, WorkOrder > lworkOrderMap = new Map < Id, WorkOrder > ();

        //Karen Hung 25.06.2019 DOO-288 mapping to be used to populate main service contact
        Map<Id, Id> accountAccLocMap = new Map<Id,Id>();
        Map<Id, Contact> accLocContactMap = new Map<Id,Contact>();

        //put mapping for account and accountlocation
        for(OperatingSchedule__c ops : operatingSchedules){
            if(ops.Account_Location__r.Apttus_Config2__AccountId__c !=null){
                accountAccLocMap.put(ops.Account_Location__r.Apttus_Config2__AccountId__c,ops.Account_Location__c);   
            }
        }

        //put mapping for account location and main service person based on account in accountAccLocMap
        for(Contact con : [SELECT ID, AccountId FROM Contact WHERE Main_Service_Person__c = TRUE AND AccountId IN :accountAccLocMap.keySet()]){
            accLocContactMap.put(accountAccLocMap.get(con.AccountId), con);     
        }

        for (OperatingSchedule__c operatingSchedule: operatingSchedules) {
            WorkOrder workOrder = new WorkOrder();
            //-------------to set pricebook entry
            String priceBookKey = String.valueOf(operatingSchedule.physicalAsset__r.Product__c) + operatingSchedule.physicalAsset__r.SalesOrganization__c;

            workOrder.Pricebook2Id = priceBookMap.get(priceBookKey) != null ? priceBookMap.get(priceBookKey).Pricebook2Id : null;
            //----------------------------------    

            workOrder.RecordTypeId = CONST_WORKORDER_OP_RT;
            workOrder.OP_Physical_Asset__c = operatingSchedule.PhysicalAsset__c;
            workOrder.WorkOrderType__c = CONST_WORKORDER_OP_TYPE; //CONST_WORKORDER_OP_WT;

            //Karen Hung 26.06.2019 DOO-288 populate main service contact
            if(accLocContactMap.containsKey(operatingSchedule.Account_Location__c)){
                workOrder.Main_Service_Contact__c = accLocContactMap.get(operatingSchedule.Account_Location__c).Id;
            }
            
            workOrder.SalesOrganization__c = operatingSchedule.PhysicalAsset__r.SalesOrganization__c;
            workOrder.AccountId = operatingSchedule.PhysicalAsset__r.SoldTo__c;

            //XEN REYES 9.28.2018 KTS-2196: This is to ensure that even if the default owner is Individual, the work order will be routed to the correct queue.
            workOrder.OwnerId = UserInfo.getUserId();
            if(countrySAPCodeMap.containsKey(workOrder.SalesOrganization__c)){
                if(queueNameIdMap.containsKey(countrySAPCodeMap.get(workOrder.SalesOrganization__c))){
                    workOrder.OwnerId = queueNameIdMap.get(countrySAPCodeMap.get(workOrder.SalesOrganization__c));
                } 
            }

            lworkOrderMap.put(workOrder.OP_Physical_Asset__c, workOrder);
        }
        if (Schema.sObjectType.WorkOrder.isCreateable()) {
            Database.SaveResult[] lsr2 = Database.insert(lworkOrderMap.values(), false);
            //  for (Database.SaveResult ds:lsr2 ){if (!ds.isSuccess())system.debug('Error in inserting Operating Task work order>>>>>> '+ lsr2);} 
        }
        CustomLogging.pop();
        return lworkOrderMap;
    }

    /******************************************************************************
     * @author         Archi Delphinanto
     * @date           19.feb.2018
     * @description    Create WOLI Task for batch type regularbatch
     * @revision(s)
     ******************************************************************************/
    private void runRegularBatch(Date taskDate, List < OperatingSchedule__c > lOperatingSchedules) {
        CustomLogging.push('createWOLI', 'TS_OperatingTasks_Batch');

        Map < String, PricebookEntry > pBMap = createPriceBookEntryMap(lOperatingSchedules);

        //Create work order map, to make a reference to physical asset in WOLI
        Map < Id, WorkOrder > workOrderMap = createWorkOrders(lOperatingSchedules, pBMap);

        //Get a list of WOLI L task for tomorrow on full operating non 247 or comfort operating 
        Set < string > fullOP_Ltask_list = getTomorrowWOLI_list(workOrderMap.keySet(), taskDate, CONST_FULLOP);
        Set < string > ComfortOp_Ltask_list = getTomorrowWOLI_list(workOrderMap.keySet(), taskDate, CONST_COMFORTOP);

        List < WorkOrderLineItem > allTaskList = new List < WorkOrderLineItem > ();
        List < WorkOrder > unusedWorkOrderList = new List < workOrder > ();

        //Initialize the task date
        DateTime scheduledDate = taskDate; //addBusinessDays(taskDate,    

        try{

            //Create woli 
            for (OperatingSchedule__c operatingSchedule: lOperatingSchedules) {

                //SEND COUNTER READING FOR LARGE TASK - Xen Reyes, April 8, 2019 - ALM 6589
                Boolean SEND_COUNTER_VAR = SENDCOUNTER_LARGE;
                if(operatingSchedule.PhysicalAsset__r.CounterReading__c != 'Yes' ||
                    operatingSchedule.PhysicalAsset__r.Connected__c != 'No' ||
                    (operatingSchedule.PhysicalAsset__r.Machine_Care__c != 'Full Operating' && operatingSchedule.PhysicalAsset__r.Machine_Care__c != 'Comfort Operating')){
                    SEND_COUNTER_VAR = false;
                }

                boolean isWorkOrderUsed = false; // this is a token if the workorder record generate is used or not, if not then to be deleted           
                // define task for rinse            
                String getRinseAPIName = CONST_RinseTask_API + '_' + getWeekNumber(operatingSchedule.Start_Date__c, scheduledDate.date()) + '_' + scheduledDate.format('EEEE') + '__c';
                boolean valueRinseTask = (boolean) operatingSchedule.get(getRinseAPIName);
                String timeIndicator = '0';

                // define task for large   ///////////
                String getLargeAPIName = CONST_LargeTask_API + '_' + getWeekNumber(operatingSchedule.Start_Date__c, scheduledDate.date()) + '_' + scheduledDate.format('EEEE') + '__c';
                String valueLargeTask = String.valueOf(operatingSchedule.get(getLargeAPIName)); // Large has value of 0 or 1

                Boolean isFullOpNon247_LTask_Found = false;
                if (operatingSchedule.TypeofContract__c.equals(CONST_FULLOP) &&
                    !operatingSchedule.OP_247Customer__c &&
                    fullOP_Ltask_list.contains(String.valueOf(OperatingSchedule.PhysicalAsset__c))) {
                    //system.debug('inside full operating 247, L woli is found');
                    isFullOpNon247_LTask_Found = true;
                }

                //check woli L task exist in Comfort
                Boolean isComfort_LTask_Found = false;
                if (operatingSchedule.TypeofContract__c.equals(CONST_COMFORTOP) &&
                    ComfortOp_Ltask_list.contains(String.valueOf(OperatingSchedule.PhysicalAsset__c))) {
                    //system.debug('inside comfor operating, L woli is found');
                    isComfort_LTask_Found = true;

                }

                // specific condition if there is a postponed L task (already scheduled in woli ) on full operating non 24 7 contract             
                // Boolean isFullOpNon247_LTask_Found = operatingSchedule.TypeofContract__c.equals('Full Operating') && operatingSchedule.OP_247Customer__c && fullOP_Ltask_list.contains(OperatingSchedule.PhysicalAsset__c)==false? true:false;
                if (isFullOpNon247_LTask_Found || isComfort_LTask_Found) valueLargeTask = '0'; // it is zero because there is an L task has been planned

                List < WorkOrderLineItem > largeTaskList = new List < WorkOrderLineItem > ();

                if (!valueLargeTask.equals('0') && valueLargeTask != null) { //if there is  L task is planned
                    largeTaskList = createOperatingTasks(CONST_LargeTask_ACTIVITY, valueLargeTask, timeIndicator, operatingSchedule, scheduledDate, valueRinseTask, workOrderMap, pBMap, SEND_COUNTER_VAR);
                    valueRinseTask = false; // L should win over S over rinse task.
                }

                if (!largeTaskList.isempty()) { // there is L task to be created and the generated work order record is used
                    allTaskList.addAll(largeTaskList);
                    isWorkOrderUsed = true;
                }

                // define task for small   //////////////         
                timeIndicator = '0';
                String getsmallAPIName = CONST_SmallTask_API + '_' + getWeekNumber(operatingSchedule.Start_Date__c, scheduledDate.date()) + '_' + scheduledDate.format('EEEE') + '__c';
                String valueSmallTask = String.valueOf(operatingSchedule.get(getsmallAPIName));
                List < WorkOrderLineItem > smallTaskList = new List < WorkOrderLineItem > ();

                if (!valueSmallTask.equals('0') && valueSmallTask != null) {
                    if (valueSmallTask.equals(CONST_AM_Time) || valueSmallTask.equals(CONST_PM_Time)) {
                        timeIndicator = valueSmallTask;
                        valueSmallTask = isFullOpNon247_LTask_Found ? '0' : '1'; // specific condition if there is a postponed L task (already scheduled in woli ) on full operating non 24 7 contract  then reduce s by 1
                    } else if (Integer.valueOf(valueSmallTask) > 0 && isFullOpNon247_LTask_Found) {
                        Integer iv = Integer.valueOf(valueSmallTask) - 1;
                        valueSmallTask = string.valueof(iv);
                    }
                    smallTaskList = createOperatingTasks(CONST_SmallTask_ACTIVITY, valueSmallTask, timeIndicator, operatingSchedule, scheduledDate, valueRinseTask, workOrderMap, pBMap, false);
                    valueRinseTask = false; // L should win over S over rinse task.
                }
                if (!smallTaskList.isempty()) { // there is S task to be created and the generated work order record is used
                    allTaskList.addAll(smallTaskList);
                    isWorkOrderUsed = true;
                }

                // define task for cup /////////////
                timeIndicator = '0';
                String getcupsAPIName = CONST_CupsTask_API + '_' + getWeekNumber(operatingSchedule.Start_Date__c, scheduledDate.date()) + '_' + scheduledDate.format('EEEE') + '__c';
                String valueCupsTask = String.valueOf(operatingSchedule.get(getcupsAPIName));
                List < WorkOrderLineItem > cupTaskList = new List < WorkOrderLineItem > ();
                if (!valueCupsTask.equals('0') && valueCupsTask != null) {
                    cupTaskList = createOperatingTasks(CONST_CupsTask_ACTIVITY, valueCupsTask, timeIndicator, operatingSchedule, scheduledDate, valueRinseTask, workOrderMap, pBMap, false);
                }
                if (!cupTaskList.isempty()) { //// there is L task to be created and the generated work order record is used
                    allTaskList.addAll(cupTaskList);
                    isWorkOrderUsed = true;
                }

                if (!isWorkOrderUsed || operatingSchedule.TypeofContract__c == NULL) { // to list unused work order record
                    WorkOrder wo = workOrderMap.get(operatingSchedule.PhysicalAsset__c);
                    unusedWorkOrderList.add(wo);
                }
            }
            system.debug('Number of operating woli task (regular batch)' + allTaskList);
            system.debug('Number of operating work order records to be deleted  (regular batch)' + unusedWorkOrderList);
            // insert all task to woli table
            // System.debug(allTaskList);

            if (!allTaskList.isempty() && Schema.sObjectType.WorkOrderLineItem.isCreateable()) {
                
                /* XEN REYES March 4, 2019 */
                Database.SaveResult[] saveResults = Database.insert(allTaskList, false);

                //Custom Logging - Xen Reyes Mar. 14, 2019 - April 8, 2019
                INSERT_LOGGING(saveResults);                          
            }

            //7.30.2018 KTS-2014: Fix for creation of integration log to trigger field set operating task Added by Paul Aguiling -- START
            //if (!allTaskList.isEmpty() && Schema.sObjectType.WorkOrderLineItem.isUpdateable()) {
            //    for (WorkOrderLineItem crw :allTaskList) {
            //        crw.isCRswoliisloaded__c = true;
            //    }

            //    update allTaskList;
            //}
            //7.30.2018 KTS-2014: Fix for creation of integration log to trigger field set operating task Added by Paul Aguiling -- END

            //delete unused work order record
            if (!unusedWorkOrderList.isempty() && Schema.sObjectType.WorkOrderLineItem.isDeletable()) {
                Database.DeleteResult[] deleteResults = Database.delete(unusedWorkOrderList, false);
                // for (Database.DeleteResult ds:deleteResults ){if (!ds.isSuccess())system.debug('Error in deleting unused Work Order (regular batch) >>>>>'+ ds);}                
            }

        } catch(Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }

        CustomLogging.pop();
    }

    /******************************************************************************
     * @author         Archi Delphinanto
     * @date           19.feb.2018
     * @description    Look in the map forward for preponed task or look backward for posponed task, or both, then generate the task.
     * @revision(s)
     ******************************************************************************/
    public void runHolidayBatch(Date batchdrunDate, List < OperatingSchedule__c > lOperatingSchedules, Map < Integer, Boolean > lFutureholidayMap, Map < Integer, Boolean > lPastholidayMap, String batchType) {

        CustomLogging.push('runHolidayBatch', 'TS_OperatingTasks_RegularBatch');

        //----------------------Create work order-----------------------//
        //------------->> as it is requrired to create WOLI, and put into a map as a reference to generate woli
        //to get price book entry map
        Map < String, PricebookEntry > pBMap = createPriceBookEntryMap(loperatingSchedules);
        Map < Id, WorkOrder > workOrderMap = createWorkOrders(lOperatingSchedules, pBMap);

        //-------------->> Find any L task on physical asset for tomorrow  
        Set < string > fullOP_Ltask_list = getTomorrowWOLI_list(workOrderMap.keySet(), batchdrunDate.addDays(1), CONST_FULLOP);
        Set < string > ComfortOp_Ltask_list = getTomorrowWOLI_list(workOrderMap.keySet(), batchdrunDate.addDays(1), CONST_COMFORTOP);

        //-----------initialize list variables ------------------------//
        List < WorkOrderLineItem > allTaskList = new List < WorkOrderLineItem > (); // List to create WOLI
        List < WorkOrder > unusedWorkOrderList = new List < workOrder > (); // list to delete unused work order

        boolean isholidaybatchBWK = batchType.equals(CONST_BWK) ? true : false; // if the batch should look backward  in case  holidays.
        boolean isholidaybatchFWD = batchType.equals(CONST_FWD) ? true : false; // if the batch should look forward  in case  holidays.
        boolean isholidaybatchFWDBWK = batchType.equals(CONST_FWDBWK) ? true : false; //Xen Reyes 8.30.2018

        //------------->>to create type of tasks during some days ahead or backward  
        TS_HolidayWrapper holidaytool = new TS_HolidayWrapper();
        Map < Integer, TS_HolidayWrapper.OpSched > fwMap = new Map < Integer, TS_HolidayWrapper.OpSched > ();
        Map < Integer, TS_HolidayWrapper.OpSched > bwMap = new Map < Integer, TS_HolidayWrapper.OpSched > ();

        // init tomorrow task with the original operating schedule for tomorrow
        TS_HolidayWrapper.OpSched finalTomorrowTask = new TS_HolidayWrapper.OpSched();

        // in below loop, the final tomorrow task will be changed/updadate when necessary based on business logic for tasks on holidays
        system.debug('Batch Run Date >>> ' + batchdrunDate);

        try{

            for (OperatingSchedule__c operatingSchedule: lOperatingSchedules) {

                //SEND COUNTER READING FOR LARGE TASK - Xen Reyes, April 8, 2019 - ALM 6589
                Boolean SEND_COUNTER_VAR = SENDCOUNTER_LARGE;
                if(operatingSchedule.PhysicalAsset__r.CounterReading__c != 'Yes' ||
                    operatingSchedule.PhysicalAsset__r.Connected__c != 'No' ||
                    (operatingSchedule.PhysicalAsset__r.Machine_Care__c != 'Full Operating' && operatingSchedule.PhysicalAsset__r.Machine_Care__c != 'Comfort Operating')){
                    SEND_COUNTER_VAR = false;
                }

                //system.debug('Operating Schedule Retrieved >>> ' + operatingSchedule);

                //------------------process the input of operating schedule record with holiday logic only for full operating and comfort contract
                //--------------->>>the result is estimated task for tomorrow for S, L, Cup and Rinse Task
                //--------------->>>the tomorrow task may change due to existing L task
                Boolean isComfortContract = operatingSchedule.TypeofContract__c.equals(CONST_COMFORTOP) ? true : false;
                Boolean isFullOpContract = operatingSchedule.TypeofContract__c.equals(CONST_FULLOP) ? true : false;
                
                fwMap = holidaytool.getFwdHolidayMap(batchdrunDate, operatingSchedule, lFutureholidayMap);
                bwMap = holidaytool.getBwkHolidayMap(batchdrunDate, operatingSchedule, lPastholidayMap);
                
                if (isComfortContract || isFullOpContract) finalTomorrowTask = scheduleTomorrowTask(fwMap, bwMap, batchType);
                system.debug('XEN 9/18 finalTomorrowTask: ' + finalTomorrowTask);

                //-----------------Initialize task per operating schedule based on the result of holiday logic processing ----------------------//
                DateTime scheduledDate = finalTomorrowTask.actualDate;
                String valueSmallTask = finalTomorrowTask.sTask;
                String valueLargeTask = finalTomorrowTask.lTask;
                String valueCupsTask = finalTomorrowTask.cTask;
                String valueRinseTask = finalTomorrowTask.rTask;
                String valuePostponedLTask = finalTomorrowTask.postponed_LTask;
                DateTime postponedLTaskDate = finalTomorrowTask.postponed_LTask_Date;
                boolean isRinseTask = finalTomorrowTask.isRinse;
                boolean isWorkOrderUsed = false; // this is clean up unused workorder records

                //------------------ initialize Task variables ///////////                                                                            
                List < WorkOrderLineItem > largeTaskList = new List < WorkOrderLineItem > (); // define task for large   ///////////    
                List < WorkOrderLineItem > postponedlargeTaskList = new List < WorkOrderLineItem > ();
                List < WorkOrderLineItem > smallTaskList = new List < WorkOrderLineItem > ();
                List < WorkOrderLineItem > cupTaskList = new List < WorkOrderLineItem > ();
                List < WorkOrderLineItem > rinseTaskList = new List < WorkOrderLineItem > ();
                //----------------- Prepare for Rinse task-------------------------------//

                String timeIndicator;
                //-----------> Check if there is Rinse Task on holiday for Comfort or full operating contract, if yes then create an Rinse Task for next business day
                if (!valueRinseTask.equals('0') && valueRinseTask != null) {
                    timeIndicator = CONST_AM_Time;
                    isRinseTask = false; // if rinse task exist then cancel the rinse on L or S task
                    Date rinseTaskDate;

                    //if (isholidaybatchBWK) { //Xen Reyes 8.20.2018
                    if (isholidaybatchBWK || isholidaybatchFWDBWK) rinseTaskDate = fwMap.get(1).actualDate;
                    else if (isholidaybatchFWD) {
                        //---> find the next business day for Rinse task
                        for (Integer i = 2; i <= fwMap.size(); i++) {
                            if (fwMap.get(i).isBusinessDay) {
                                rinseTaskDate = fwMap.get(i).actualDate;
                                break;
                            }
                        }
                    }
                    rinseTaskList = createOperatingTasks(CONST_RinseTask_ACTIVITY, valueRinseTask, timeIndicator, operatingSchedule, rinseTaskDate, isRinseTask, workOrderMap, pBMap, false);

                }

                //------------>create Rinse task if any 
                if (!rinseTaskList.isempty()) {
                    allTaskList.addAll(rinseTaskList);
                    isWorkOrderUsed = true;
                }

                //----------------- prepare for L task-------------------------------//

                //-----------> check if woli L task full operating non 24/7 exist in physical asset for tomorrow
                Boolean isFullOpNon247_LTask_Found = false;
                if (isFullOpContract &&
                    !operatingSchedule.OP_247Customer__c && fullOP_Ltask_list.contains(String.valueOf(OperatingSchedule.PhysicalAsset__c))) {
                    isFullOpNon247_LTask_Found = true;
                }

                //-----------> check if woli L task Comfort exist in physical asset for tomorrow
                Boolean isComfort_LTask_Found = false;
                if (isComfortContract && ComfortOp_Ltask_list.contains(String.valueOf(OperatingSchedule.PhysicalAsset__c))) {
                    isComfort_LTask_Found = true;
                }

                //-----------> if there is an L task existed, then  tomorrow L task should be canceled.
                if (isFullOpNon247_LTask_Found || isComfort_LTask_Found) valueLargeTask = '0'; // it is zero because there is an L task has been planned

                //-----------> create L task for non tomorrow if any   only for comfort and full operating non 24/7
                if ((isComfortContract || (isFullOpContract && !operatingSchedule.OP_247Customer__c)) && valuePostponedLTask.equals('1')) {
                    timeIndicator = '0';
                    boolean noRinse = false;
                    postponedlargeTaskList = createOperatingTasks(CONST_LargeTask_ACTIVITY, valuePostponedLTask, timeIndicator, operatingSchedule, postponedLTaskDate, noRinse, workOrderMap, pBMap, SEND_COUNTER_VAR);
                }

                if (!postponedlargeTaskList.isEmpty()) {
                    allTaskList.addAll(postponedlargeTaskList);
                    isWorkOrderUsed = true;
                }

                //-----------> create L task for tomorrow if any
                timeIndicator = '0';
                if (!valueLargeTask.equals('0') && valueLargeTask != null) {
                    if (finalTomorrowTask.lam) timeindicator = CONST_AM_Time;
                    else if (finalTomorrowTask.lpm) timeindicator = CONST_PM_Time;
                    largeTaskList = createOperatingTasks(CONST_LargeTask_ACTIVITY, valueLargeTask, timeIndicator, operatingSchedule, scheduledDate, isRinseTask, workOrderMap, pBMap, SEND_COUNTER_VAR);
                    isRinseTask = false;
                }

                if (!largeTaskList.isempty()) {
                    allTaskList.addAll(largeTaskList);
                    isWorkOrderUsed = true;
                }

                //----------------- prepare for S task-------------------------------// 
                timeIndicator = '0';

                if (!valueSmallTask.equals('0') && valueSmallTask != NULL) {
                    if (valueSmallTask.equals(CONST_AM_Time) || valueSmallTask.equals(CONST_PM_Time) || valueSmallTask.equals('1')) {
                        timeIndicator = valueSmallTask;
                        valueSmallTask = isFullOpNon247_LTask_Found ? '0' : '1'; // specific condition if there is a postponed L task (already scheduled in woli ) on full operating non 24 7 contract  then reduce s by 1
                        // comfort has no S task
                    }
                    if (finalTomorrowTask.remainingStask > 0) {
                        Integer totalSTask = Integer.valueOf(valueSmallTask) + finalTomorrowTask.remainingSTask;
                        valueSmallTask = String.valueOf(totalSTask);
                    }

                    //XEN REYES 9.18.2018 Added: || Integer.value(valuePostponedLTask) > 0
                    if (Integer.valueOf(valueSmallTask) > 1 && (isFullOpNon247_LTask_Found || Integer.valueOf(valuePostponedLTask) > 0)) {
                        Integer totalSTask = Integer.valueOf(valueSmallTask) - 1;
                        valueSmallTask = String.valueOf(totalSTask);
                    }

                    smallTaskList = createOperatingTasks(CONST_SmallTask_ACTIVITY, valueSmallTask, timeIndicator, operatingSchedule, scheduledDate, isRinseTask, workOrderMap, pBMap, false);
                    isRinseTask = false; // S should win over cup over rinse task.
                }

                if (!smallTaskList.isempty()) {
                    allTaskList.addAll(smallTaskList);
                    isWorkOrderUsed = true;
                }


                //----------------- prepare for Cups task-------------------------------// 
                timeIndicator = '0';

                if (!valueCupsTask.equals('0') && valueCupsTask != null) {
                    cupTaskList = createOperatingTasks(CONST_CupsTask_ACTIVITY, valueCupsTask, timeIndicator, operatingSchedule, scheduledDate, isRinseTask, workOrderMap, pBMap, false);
                }
                if (!cupTaskList.isEmpty()) {
                    allTaskList.addAll(cupTaskList);
                    isWorkOrderUsed = true;
                }

                //----------------- check for unused Work order-------------------------------//
                if (!isWorkOrderUsed) { // to list unused work order record
                    WorkOrder wo = workOrderMap.get(operatingSchedule.PhysicalAsset__c);
                    unusedWorkOrderList.add(wo);
                }

            }

            //----------------- add alltask to database-------------------------------//  
            if (!allTaskList.isempty() && Schema.sObjectType.WorkOrderLineItem.isCreateable()) {
                
                /* XEN REYES March 4, 2019 */
                Database.SaveResult[] saveResults = Database.insert(allTaskList, false);

                //Custom Logging - Xen Reyes Mar. 14, 2019 - April 8, 2019
                INSERT_LOGGING(saveResults);
            }
            //----------------- delete unused work order record-------------------------------//
            if (!unusedWorkOrderList.isempty() && Schema.sObjectType.WorkOrderLineItem.isDeletable()) {
                Database.DeleteResult[] deleteResults = Database.delete(unusedWorkOrderList, false);
                // for (Database.DeleteResult ds:deleteResults ){if (!ds.isSuccess())system.debug('Error in deleting unused Work order (Holiday batch)>>>>>'+ ds);}                         
            }

        } catch(Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }

        CustomLogging.pop();
    }

    /******************************************************************************
     * @author         Archi Delphinanto
     * @date           19.feb.2018
     * @description    It is used by Runholidaybatch to schedule Operating Task for tomorrow based on the forward and backward MAP
     * @revision(s)
     ******************************************************************************/
    private TS_HolidayWrapper.OpSched scheduleTomorrowTask(Map < Integer, TS_HolidayWrapper.OpSched > fwSchMap, Map < Integer, TS_HolidayWrapper.OpSched > bwSchMap, String batchType) {
        CustomLogging.push('scheduleTomorrowTask', 'TS_OperatingTasks_RegularBatch');

        TS_HolidayWrapper.OpSched idayTask = new TS_HolidayWrapper.OpSched();

        //--------------- initialize tomorrow task with information obtained from Schema----------------//
        TS_HolidayWrapper.OpSched tomorrowTask = new TS_HolidayWrapper.OpSched();
        fill_Opsched(fwSchMap.get(1), tomorrowTask); //-->> to avoid pass by reference, the value of fwSchMap Map must not not be changed 

        System.debug('Tomorrow Task >>> ' + tomorrowTask);
        //---------------initialize logic variable from the tomorrow task        
        boolean isFullOp247contract = tomorrowTask.typeOfContract.equals(CONST_FULLOP) && tomorrowTask.is247 ? true : false; //full operating, 24/7        
        boolean isFullOpNon247contract = tomorrowTask.typeOfContract.equals(CONST_FULLOP) && !tomorrowTask.is247 ? true : false; //full operating, non 24/7
        boolean isComfortContract = tomorrowTask.typeOfContract.equals(CONST_COMFORTOP); //Comfort operating
        boolean isholidaybatchBWK = batchType.equals(CONST_BWK) ? true : false; // if the batch should look forward and backward in case between holidays.
        boolean isholidaybatchFWD = batchType.equals(CONST_FWD) ? true : false; // if the batch should look forward and backward in case between holidays.
        boolean isholidaybatchFWDBWK = batchType.equals(CONST_FWDBWK) ? true : false; // if the batch should look forward and backward in case between holidays.
        boolean isforcedtobusinessday = tomorrowTask.forceSchedule; // init with user opted criteria to define the plan of L task

        //--------------processing the forward Holiday logic i.e. find task on days ahead to be preponed ---------//

        if (isholidaybatchFWD || isholidaybatchFWDBWK) {
            for (Integer iday: fwSchMap.keySet()) {

                fill_Opsched(fwSchMap.get(iday), idayTask);

                if (iday > 1) { // starts from  the day after tomorrow              

                    if (idayTask.isBusinessDay) break; //--->look only for holidays 

                    // case (logic) 1. (Contract type: full operating, 24/7) If in any holidays ahead  there is S = pm, then shift if to the business day before holiday with (pm)
                    // ---------------but if there is L task on the business day then remove the S, and update the L with PM

                    if (isFullOp247contract && idayTask.sTask.equals(CONST_PM_Time)) {
                        //update the tomorrow task

                        if (idayTask.isRinse) {
                            tomorrowTask.rTask = '1';
                            tomorrowTask.isRinse = false; // if tomorrow task originally has rinse it will be replaced by the rinse task                                
                        }

                        //system.debug('tomorrowTask: ' + tomorrowTask);
                        if (tomorrowTask.lTask.equals('1')) {
                            tomorrowTask.lpm = true;
                            if (tomorrowTask.sTask.equals(CONST_PM_Time)) tomorrowTask.sTask = '0';
                        }
                        // case if L task is 0 or null
                        else if (tomorrowTask.lTask == null || tomorrowTask.lTask.equals('0')) {
                            //case if  S task is 0 or null
                            if (tomorrowTask.sTask == null || tomorrowTask.sTask.equals('0') || tomorrowTask.sTask.equals('1') || tomorrowTask.sTask.equals(CONST_AM_Time)) {
                                tomorrowTask.sTask = CONST_PM_Time;
                            }
                            //if there is s task
                            else if (tomorrowTask.sTask.equals('2') || tomorrowTask.sTask.equals('3') || tomorrowTask.sTask.equals('4')) {
                                tomorrowTask.remainingStask = Integer.valueOf(tomorrowTask.sTask) - 1;
                                tomorrowTask.sTask = CONST_PM_Time;
                            }
                        }
                        break;

                    }
                }

            }
        }

        system.debug('Back Map >>>>' + bwSchMap);
        if (isholidaybatchBWK || isholidaybatchFWDBWK) { //find tasks to be postponed in the past holiday
            boolean isFullOp_sTask_AM_found = false; //to stop loop for full operating 24/7 with s am task
            boolean isFullOp_lTask_found = false; // to stop loop for full operating 24/7 with l task
            boolean isRinseTaskFound = false; //            
            system.debug('isFullOp247contract: ' + isFullOp247contract);
            system.debug('isFullOpNon247contract:' + isFullOpNon247contract);
            system.debug('isComfortContract: ' + isComfortContract);
            // the loop is to find any postponed task  
            for (Integer iday: bwSchMap.keySet()) {
                fill_Opsched(bwSchMap.get(iday), idayTask);
                system.debug('Current Day >>>> ' + iday + ' >>> ' + idayTask);
                //only loop backward for holidays in the map, and stop when find business day
                if (idayTask.isBusinessDay || (isFullOp_lTask_found && isRinseTaskFound)) break;

                // case 2. full operating, 24/7, find any L =1, if an L  task is found then stop the search for S Am task which is done by isFullOp_lTask_found
                if (isFullOp247contract && idayTask.lTask.equals('1') && !isFullOp_lTask_found) {
                    isFullOp_lTask_found = true;

                    //System.debug(iday + '. begin tommorow s task :'+ tomorrowTask.sTask);                        
                    if (idayTask.isRinse) {
                        tomorrowTask.rTask = '1';
                        tomorrowTask.isRinse = false; // if tomorrow task originally has rinse it will be replaced by the rinse task  
                        isRinseTaskFound = true;
                    }
                    // if tomorrow has no L task, create a new L task 
                    if (!tomorrowTask.lTask.equals('1')) tomorrowTask.lTask = '1';
                    tomorrowTask.lam = true; //L task should alwasy be postponed as L am task

                    if (tomorrowTask.sTask.equals('1') || tomorrowTask.sTask.equals(CONST_AM_Time)) tomorrowTask.sTask = '0'; // remember although s task can be 0 , the remaining task can be non zero and should be scheduled as operating task too.
                    // if tommorow has S task more than 1, then reduce it by 1                                       
                    else if (tomorrowTask.sTask.equals('2') || tomorrowTask.sTask.equals('3') || tomorrowTask.sTask.equals('4')) {
                        tomorrowTask.remainingStask = Integer.valueOf(tomorrowTask.sTask) - 2;
                        tomorrowTask.sTask = '1';
                    }
                    // if tommorow has 1 (with or without AM ) S task  then remove it                                                    
                    else if (tomorrowTask.sTask.equals(CONST_PM_Time)) {
                        if (tomorrowTask.remainingStask < 1 || tomorrowTask.remainingStask == null) tomorrowTask.sTask = '0'; // if S pm is the only one then it is covered by the L am
                        else tomorrowTask.remainingStask = Integer.valueOf(tomorrowTask.sTask) - 1; // If S pm and there are remaining task, the remaining task is reduced by 1 as covered by L am
                    }
                    //System.debug(iday + '. end tommorow s task :'+ tomorrowTask.sTask);

                }
                //system.debug(iday + '. scheduleTomorrowTask --> is full op l task found : '+ isFullOp_lTask_found);
                //system.debug('isFullOp_lTask_found : ' +isFullOp_lTask_found );
                //system.debug('isFullOp_sTask_AM_found: ' +isFullOp_sTask_AM_found);

                // case 3. full operating, 24/7, find any S = am. if an S am   is found then check if tomorrow has L , the search should continue to find L                 
                if (isFullOp247contract && idayTask.sTask.equals(CONST_AM_Time) && !isFullOp_sTask_AM_found && (!isFullOp_lTask_found || !isRinseTaskFound)) {
                    // if tomorrow has no  L task update only the S task
                    // if iday has  rinse, then move it to tomorrow task
                    // if (idayTask.isRinse) tomorrowTask.isRinse = true;
                    if (idayTask.isRinse) {
                        tomorrowTask.rTask = '1';
                        tomorrowTask.isRinse = false; // if tomorrow task originally has rinse it will be replaced by the rinse task                 
                    }
                    if (!tomorrowTask.lTask.equals('1') && !isFullOp_lTask_found) {
                        //if iday has  rinse, then move it to tomorrow task
                        //  if (idayTask.isRinse) tomorrowTask.isRinse = true;

                        //in case there is 1 task
                        if (tomorrowTask.sTask.equals('0') || tomorrowTask.sTask == null || tomorrowTask.sTask.equals('1') || tomorrowTask.sTask.equals(CONST_PM_Time)) {
                            tomorrowTask.sTask = CONST_AM_Time;
                            //tomorrowTask.remainingStask = 0;                                 
                        }
                        // in case there are more than 1 s Task
                        if (tomorrowTask.sTask.equals('2') || tomorrowTask.sTask.equals('3') || tomorrowTask.sTask.equals('4')) {
                            tomorrowTask.remainingStask = Integer.valueOf(tomorrowTask.sTask) - 1;
                            tomorrowTask.sTask = CONST_AM_Time;
                        }

                    }
                    //if tomorrow has L task update only the L task to L am task.
                    if (tomorrowTask.lTask.equals('1') && !isFullOp_lTask_found) tomorrowTask.lam = true;
                    isRinseTaskFound = true; // this is to look for rinse task but if in Sam cannot be found, it should stop searching.    
                    isFullOp_sTask_AM_found = true;
                }
                // case 4. Comfort operating, L Task --> shift to H+2 but if h+2 is holiday then find a day after H+2 that is business day
                if (isComfortContract && idayTask.lTask.equals('1')) {

                    //tomorrowTask.cTask = '0'; // we just shift the L task, separate C task will be handled separatedly.
                    //tomorrowTask.sTask = '0'; // comfort has no S task, also we just shift the L task
                    //tomorrowTask.lTask ='1';//only for comfort,this is not really tomorrow task
                    tomorrowTask.postponed_LTask = '1';
                    // tomorrowTask.isRinse = idayTask.isRinse;// set rinse if the L task on the holiday has rinse task
                    if (idayTask.isRinse) {
                        tomorrowTask.rTask = '1';
                        tomorrowTask.isRinse = false; // if tomorrow task originally has rinse it will be replaced by the rinse task                 
                    }

                    Date comfortLtaskdate = tomorrowTask.actualDate; // initialize the task date

                    for (Integer i = 2; i <= fwSchMap.size(); i++) { //find the next business day from H+2
                        if (fwSchMap.get(i).isBusinessDay) {
                            comfortLtaskdate = fwSchMap.get(i).actualDate;
                            break;
                        }
                    }
                    tomorrowTask.postponed_LTask_Date = comfortLtaskdate; // this is the shifted/postponed date for L task for comfort
                    //  tomorrowTask.actualDate= comfortLtaskdate; // this is the shifted/postponed date for L task for comfort
                    break;
                }
                // Case 5. full operating, non 24/7 , to find L task --> shift to the next S day or the next business day in the same week. reduce s task by 1 
                if (isFullOpNon247contract && idayTask.lTask.equals('1')) {
                    //tomorrowTask.lTask ='1';//  tomorrow task
                    //tomorrowTask.cTask = '0';
                    //tomorrowTask.sTask = '0';
                    tomorrowTask.postponed_LTask = '1';

                    if (idayTask.isRinse) {
                        tomorrowTask.rTask = '1';
                        tomorrowTask.isRinse = false; // if tomorrow task originally has rinse it will be replaced by the rinse task                 
                    }

                    Date fullnon247Ltaskdate = tomorrowTask.actualDate;

                    System.debug('XEN 9/18 fwSchMap: ' + fwSchMap);
                    //Original: i = 1 && fwSchMap.size() 8.30.2018 Xen Reyes
                    for (Integer i = 0; i <= (fwSchMap.size() - 1); i++) { //find the next s business day

                        if (!isforcedtobusinessday && fwSchMap.get(i).isBusinessDay && (!fwSchMap.get(i).sTask.equals('0') && fwSchMap.get(i).sTask != null)) {
                            fullnon247Ltaskdate = fwSchMap.get(i).actualDate; // L task shift to next S day as user opts for that
                            // tomorrowTask.isRinse = idayTask.isRinse;//||fwSchMap.get(i).isRinse?true:false;
                            System.debug(iday + 'is NOT forced to businessday -->fullnon247Ltaskdate: ' + fullnon247Ltaskdate);
                            break;
                        } else if (isforcedtobusinessday && fwSchMap.get(i).isBusinessDay) { // L task shift to next business day as user opts for that
                            fullnon247Ltaskdate = fwSchMap.get(i).actualDate;
                            // tomorrowTask.isRinse = idayTask.isRinse;//||fwSchMap.get(i).isRinse?true:false;
                            System.debug(iday + 'is forced to businessday -->fullnon247Ltaskdate: ' + fullnon247Ltaskdate);
                            break;
                        }
                    }

                    tomorrowTask.postponed_LTask_Date = fullnon247Ltaskdate;
                    //tomorrowTask.actualDate= fullnon247Ltaskdate;                         
                    break;
                }
            }
        }
        CustomLogging.pop();
        return tomorrowTask;
    }

    /******************************************************************************
     * @author         Archi Delphinanto
     * @date           19.feb.2018
     * @description    Copy the map values of tofill into tobefilled (to avoid pass by reference)
     * @revision(s)
     ******************************************************************************/
    public void fill_Opsched(TS_HolidayWrapper.OpSched tofill, TS_HolidayWrapper.OpSched tobefilled) {
        tobefilled.osId = tofill.osId;
        tobefilled.typeOfContract = tofill.typeOfContract;
        tobefilled.cTask = tofill.cTask;
        tobefilled.sTask = tofill.sTask;
        tobefilled.lTask = tofill.lTask;
        tobefilled.rTask = tofill.rTask;
        tobefilled.timeIndicator = tofill.timeIndicator;
        tobefilled.isRinse = tofill.isRinse;
        tobefilled.is247 = tofill.is247;
        tobefilled.isBusinessDay = tofill.isBusinessDay;
        tobefilled.lpm = tofill.lpm;
        tobefilled.lam = tofill.lam;
        tobefilled.forceSchedule = tofill.forceSchedule;
        tobefilled.remainingSTask = tofill.remainingSTask;
        tobefilled.actualDate = tofill.actualDate;
    }

    /******************************************************************************
     * @author         Archi Delphinanto
     * @date           19.feb.2018
     * @description    to Create the list of WOLI task based on the inputs
     * @revision(s)
     ******************************************************************************/
    List < WorkOrderLineItem > createOperatingTasks(String activityType, String activityvalue, String timeindicator, OperatingSchedule__c operatingSchedule, DateTime scheduledDate, boolean isRinse, Map < Id, WorkOrder > workOrderMap, Map < String, PricebookEntry > priceBookMap, Boolean sendCounterReading) {

        CustomLogging.push('createTasks', 'TS_OperatingTasks_RegularBatch');
        List < WorkOrderLineItem > woliList = new List < WorkOrderLineItem > ();
        Integer starthour = defaultstarttime; //Integer.valueOf(Operating_Task__c.getInstance().DefaultStartTime__c); // get default start time hour from custom setting
        Integer endhour = defaultendTime; //Integer.valueOf(Operating_Task__c.getInstance().DefaultEndTime__c); // get default end time hour from custom setting
        boolean isTimeIndicatorExecutedOnce = false;
        for (Integer i = 0; i < numberOfTasksMap.get(activityvalue); i++) {
            WorkOrderLineItem task = new WorkOrderLineItem();
            task.WorkOrderType__c = CONST_WORKORDER_OP_TYPE;
            task.AccountLocation__c = operatingSchedule.PhysicalAsset__r.AccountLocation__c;
            task.WorkOrderLineItemType__c = activityType; // activityTypeMap.get(activityType);
            //task.StartDate__c = DateTime.newInstance(scheduledDate.year(), scheduledDate.month(), scheduledDate.day(), starthour, 0, 0);

            //XEN REYES Nov. 22, 2018
            if(numberOfTasksMap.get(activityvalue) != 0 && numberOfTasksMap.get(activityvalue) != 1){
                task.EarlyStart__c = DateTime.newInstance(scheduledDate.year(), scheduledDate.month(), scheduledDate.day(), starthour, i, 0);
            } else {
                task.EarlyStart__c = DateTime.newInstance(scheduledDate.year(), scheduledDate.month(), scheduledDate.day(), starthour, 0, 0);
            }

            //task.EndDate__c = DateTime.newInstance(scheduledDate.year(), scheduledDate.month(), scheduledDate.day(), endhour, 0, 0);
            task.SLADate__c = DateTime.newInstance(scheduledDate.year(), scheduledDate.month(), scheduledDate.day(), endhour, 0, 0);
            task.Building__c = operatingSchedule.PhysicalAsset__r.Building__c;
            task.AccountLocationID__c = operatingSchedule.PhysicalAsset__r.AccountLocation__r.SAP_Customer_ID__c;
            task.Floor__c = operatingSchedule.PhysicalAsset__r.Floor__c;
            task.OP_IsHoliday__c = false;
            task.PhysicalAsset__c = operatingSchedule.PhysicalAsset__c;
            task.OP_PreferredOperator__c = operatingSchedule.PhysicalAsset__r.OP_PreferredOperator__c;
            //task.RecordTypeId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get(CONST_OP_WOLI_RT).getRecordTypeId();

            //-------------to set pricebook entry
            String priceBookKey = String.valueOf(operatingSchedule.PhysicalAsset__r.Product__c) + operatingSchedule.PhysicalAsset__r.SalesOrganization__c;
            task.PricebookEntryId = priceBookMap.get(priceBookKey) != null ? priceBookMap.get(priceBookKey).Id : null;
            //-----------------------------------------------------//

            task.RecordTypeId = CONST_WOLI_OP_RT;
            task.Status = CONST_WOLI_OPEN_STATUS; //'Open';
            if (!isTimeIndicatorExecutedOnce && !timeindicator.equals('0')) {
                task.OP_TimeIndicator__c = timeindicator == CONST_AM_Time || timeindicator == CONST_PM_Time ? timeindicator : null;
                isTimeIndicatorExecutedOnce = true;
            }
            task.WorkOrderId = workOrderMap.get(task.PhysicalAsset__c).Id;
            task.OP_247Customer__c = operatingSchedule.OP_247Customer__c;
            task.MachineCare__c = operatingSchedule.PhysicalAsset__r.Machine_Care__c;
            task.OP_RinseRequired__c = isRinse;

            //ALM 6243 XEN REYES March 26, 2019
            task.SendCounterReadingsOperating__c = sendCounterReading;

            woliList.add(task);
        }
        CustomLogging.pop();
        return woliList;
    }

    /**
    * @author        Abram Vixen Reyes
    * @date          Jan. 25, 2019
    * @description   Method to create a custom log record if there is failed record processed in the batch execution.
    * @revision(s)
    */
    public void INSERT_LOGGING (List<Database.SaveResult> saveResultList) {

        //XEN REYES - Custom Logging for Database.Error
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

        /* Create custom log record per batch. If there is an error. */
        if(!exception_List_batch.isEmpty()){
            String mainMessage = '';

            for(String err : exception_List_batch){
                mainMessage = err + '\n';
            }

            //CREATE CUSTOM LOG
            Custom_Log__c log = new Custom_Log__c(
                StackTrace__c = 'Operating Task (Daily)',
                Message__c = mainMessage,
                ExceptionType__c = TS_Constants.DATABASE_ERROR);
            insert log;
        }
    }

    /**
    * @author        Abram Vixen Reyes
    * @date          March 26, 2019
    * @description   ALM 6243: Method to evaluate if the date is within the first 10 working days
    * @revision(s)
    */
    public Boolean EVALUATEDATE (Date taskDate, CountrySetting__c cs) {

        Boolean SEND_COUNTER = Boolean.valueOf(Label.TS_EnforceCounterReadingForOperating);
        Integer NUM_WORKINGDAYS = Integer.valueOf(Label.TS_NumberOfWorkingDaysCounterReading);
        String SATURDAY = 'Saturday';
        String SUNDAY = 'Sunday';
        Set<Date> DAYSET = new Set<Date>();

        String busineshourId = String.valueOf(cs.Business_Hours__r.Id); 
        Date D1 = taskDate.toStartofMonth();
        Date D2 = D1.addMonths(1);

        Integer COUNTER = 0;
        while (D1 < D2)
        {   
            if(COUNTER == NUM_WORKINGDAYS){
                break;
            }

            Datetime dtime = datetime.newInstanceGMT(D1.year(), D1.month(),D1.day(), 12, 0, 0);
            /* if(BusinessHours.isWithin(busineshourId, dtime)){
                DAYSET.add(D1);
                COUNTER ++;
            }*/

            //XEN REYES INC0119960 DOO-665 July 17, 2019
            if(dtime.format('EEEE') != SATURDAY && dtime.format('EEEE') != SUNDAY){
              DAYSET.add(D1);
              COUNTER ++;
            }

            D1 = D1.addDays(1);
        }

        if(!DAYSET.isEmpty() && DAYSET.contains(taskDate)){
            SEND_COUNTER = true;
        }

        return SEND_COUNTER;

    }
}