/**
 * @author        Karen Hung
 * @date          8/29/2018
 * @description   Apex batch class for generating weekly operating task for Denmark and Norway
 * @revision(s)  9/14/18 Karen Hung Changed record type of country setting
 */

global with sharing class TS_CreateTask_Batch implements Database.Batchable <sObject>{

    String CONST_SmallTask_ACTIVITY = 'Small';
    String CONST_WORKORDER_OP_RT = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('Operating Work Order').getRecordTypeId();
    String CONST_WORKORDER_OP_TYPE = Label.TS_Activity_Type_S20; // S20 --> operating task
    String CONST_WOLI_OP_RT = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Operating Task').getRecordTypeId();
    String CONST_WOLI_OPEN_STATUS = 'Open';
    Boolean CONST_IS_SEND_EMAIL_WHEN_BATCH_FINISHED = Operating_Task__c.getInstance().Send_Email_Upon_Batch_Completion__c; //false;
    String CONST_BATCH_ADMIN_EMAIL = Operating_Task__c.getInstance().Batch_Email__c;
    long starttime;
    /////////////////////////////
    private Exception[] errors = new Exception[0];
    Date runDate;

    //XEN REYES 9.28.2018 KTS-2196: This is to ensure that even if the default owner is Individual, the work order will be routed to the correct queue.
    public Map<String, String> countrySAPCodeMap = new Map<String, String>();
    public Map<String, String> queueNameIdMap = new Map<String, String>();

    //XEN REYES April 17, 2019 - ALM 6752
    public Boolean SOQL_OVERRIDE = false;
    public String NEW_SOQL_STRING;

    global TS_CreateTask_Batch() {

    }

    /******************************************************************************
     * @author        Karen Hung
     * @date          30.aug.2018
     * @description   Constructor
     * @revision(s)
     ******************************************************************************/
    global TS_CreateTask_Batch(Date taskDate) {
        CustomLogging.push('TS_CreateTask_Batch', 'TS_CreateTask_Batch');
        //Karen Hung KTS-2666 3.18.19 assign date.today rundate if taskDate is null
        if(taskDate != null){
            runDate = taskDate;
        } else {
            runDate = Date.today();
        } 
        
        CustomLogging.pop();
    }

    /******************************************************************************
     * @author         Karen Hung
     * @date           30.aug.2018
     * @description    This method is the start of the batch job
     * @revision(s)
     ******************************************************************************/
    global Database.QueryLocator start(Database.BatchableContext BC) {
        CustomLogging.push('start', 'TS_CreateTask_Batch');
        CustomLogging.pop();
        System.debug('start'+ Limits.getCpuTime());
        return Database.getQueryLocator(getQuery());
    }

    /******************************************************************************
    * @author         Karen Hung
    * @date           30.aug.2018
    * @description    This method proceses the result of query. Where the WOLI tasks are generated. 
    *                 There are 3 main Scenarios: 
                      1. weekly task -Scenario 1, 1 wo and 1 woli for the whole week ---- Specific_Days_in_Week__c == false
                      2. daily task - scenario 2 daily workorders with woli---Specific_Days_in_Week__c == true AND Schedule_Tasks_for_Holiday__c == true
                      3. daily without holiday - scenario 3 daily workorders with woli except holiday---Specific_Days_in_Week__c == true AND Schedule_Tasks_for_Holiday__c == FALSE
    * @revision(s)
    ******************************************************************************/
    global void execute(Database.BatchableContext BC, List <OperatingSchedule__c> operatingSchedules) {
        CustomLogging.push('execute', 'TS_CreateTask_Batch');

        System.debug('XEN 11/22: '+ operatingSchedules);

        //XEN REYES 9.28.2018 KTS-2196: This is to ensure that even if the default owner is Individual, the work order will be routed to the correct queue.
        //CREATE A MAP OF COUNTRY CODES
        countrySAPCodeMap = TS_UtilityClass.countrySAPCodeUtility();

        //CREATE A MAP FOR SERVICE PLANNING QUEUE
        queueNameIdMap = TS_UtilityClass.queueNameIdMapUtility();

        try {
            Map<String, Integer> countryMapStart = new Map<String, Integer>();
            Map<String, Integer> countryMapEnd = new Map<String, Integer>();
            Map<String, String> countryBusinessHoursMap = new  Map<String, String>();

            String recordTypeId = Schema.SObjectType.CountrySetting__c.getRecordTypeInfosByName().get('Operating Task').getRecordTypeId(); //9.14.18 changed record type by karen hung
            List<CountrySetting__c> cList = [SELECT Country__c, DefaultStartTime__c, DefaultEndTime__c, Business_Hours__c FROM CountrySetting__c WHERE Active__c = true AND RecordTypeId =: recordTypeId];
            
            for (CountrySetting__c cset: cList) {
                countryMapStart.put(cset.Country__c, Integer.valueOf(cset.DefaultStartTime__c));
                countryMapEnd.put(cset.Country__c, Integer.valueOf(cset.DefaultEndTime__c));
                countryBusinessHoursMap.put(cset.Country__c, cset.Business_Hours__c);
            }

            Map<String,PricebookEntry> priceBookMap = createPriceBookEntryMap(operatingSchedules); 
            Map<Id,WorkOrder> lworkOrderMap = new Map <Id,WorkOrder>(); //mapping of workorder to create whe specific day in week is false
            List<WorkOrderLineItem> woliToCreateList = new List<WorkOrderLineItem>();
            Map<String,WorkOrder> wHolidayWorkOrderMap = new Map<String,WorkOrder>(); //mapping of workorder to create whe specific day in week is true and no work in holiday
            Map<String,String> taskPerDayMap = new Map<String,String>();
            Map<String,String> taskPerDayHolidayMap = new Map<String,String>();
            Map<String,String> workDayMap = new Map<String,String>(); //mapping of work order vs which day or the week, scenario 2
            Map<String,String> workDayHolidayMap = new Map<String,String>(); //mapping of work order vs which day or the week, scenario 3
            List<WorkOrder> workList = new List<WorkOrder>(); //work orders to be inserted per schedule for daily
            List<WorkOrder> weeklyWorkList = new List<WorkOrder>();
            List<WorkOrder> workWOholidayList = new List<WorkOrder>();

            Map<Id,OperatingSchedule__c> assetIdOpMap = new Map<Id,OperatingSchedule__c>();
            Map<Id,OperatingSchedule__c> assetIdOpHolidayMap = new Map<Id,OperatingSchedule__c>();
            Map<Id,OperatingSchedule__c> assetIdOpWeeklyMap = new Map<Id,OperatingSchedule__c>();
            List<String> workKeys = new List<String>(); //List of keys of fieldValueMap with work order, scenario 2
            List<String> workValues = new List<String>(); //list of values of fieldValueMap with work order, scenario 2
            List<String> holidayWorkKeys = new List<String>(); //List of keys of fieldValueMap with work order, scenario 3
            List<String> holidayWorkValues = new List<String>(); //list of values of fieldValueMap with work order, scenario 3
            
            Map<WorkOrder,Boolean> workOrderHoliday2Map = new Map<WorkOrder,Boolean>();

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
            
            /*******************Create Work Orders***************************/
            for(OperatingSchedule__c ops : operatingSchedules){

                Map<String,String> fieldValueMap = new Map<String,String>(); //mapping of maintenance field to value
                fieldValueMap.put('1', (ops.SM_1_Monday__c == 'AM' || ops.SM_1_Monday__c == 'PM') ? '1' : ops.SM_1_Monday__c);
                fieldValueMap.put('2', (ops.SM_1_Tuesday__c == 'AM' || ops.SM_1_Tuesday__c == 'PM') ? '1' : ops.SM_1_Tuesday__c);   
                fieldValueMap.put('3', (ops.SM_1_Wednesday__c == 'AM' || ops.SM_1_Wednesday__c == 'PM') ? '1' : ops.SM_1_Wednesday__c);   
                fieldValueMap.put('4', (ops.SM_1_Thursday__c == 'AM' || ops.SM_1_Thursday__c == 'PM') ? '1' : ops.SM_1_Thursday__c);   
                fieldValueMap.put('5', (ops.SM_1_Friday__c == 'AM' || ops.SM_1_Friday__c == 'PM') ? '1' : ops.SM_1_Friday__c);   
                fieldValueMap.put('6', (ops.SM_1_Saturday__c == 'AM' || ops.SM_1_Saturday__c == 'PM') ? '1' : ops.SM_1_Saturday__c);   
                fieldValueMap.put('7', (ops.SM_1_Sunday__c == 'AM' || ops.SM_1_Sunday__c == 'PM') ? '1' : ops.SM_1_Sunday__c);

                List<String> mapValues = fieldValueMap.values();
                Set<String> keys = fieldValueMap.keyset();
                List<String> keyList= new List<String>(keys);

                //SCENARIO 1
                if(ops.Specific_Days_in_Week__c == false){ 

                        WorkOrder workOrder = new WorkOrder(); 
                        
                        String priceBookKey = String.valueOf(ops.physicalAsset__r.Product__c) + ops.physicalAsset__r.SalesOrganization__c;               
                        workOrder.Pricebook2Id = priceBookMap.get(priceBookKey) != null ? priceBookMap.get(priceBookKey).Pricebook2Id : null;
                        workOrder.RecordTypeId = CONST_WORKORDER_OP_RT;
                        workOrder.OP_Physical_Asset__c = ops.PhysicalAsset__c;
                        workOrder.WorkOrderType__c = CONST_WORKORDER_OP_TYPE; //CONST_WORKORDER_OP_WT;               
                        workOrder.SalesOrganization__c = ops.PhysicalAsset__r.SalesOrganization__c;
                        workOrder.AccountId = ops.PhysicalAsset__r.SoldTo__c;

                        //Karen Hung 26.06.2019 DOO-288 populate main service contact
                        if(accLocContactMap.containsKey(ops.Account_Location__c)){
                            workOrder.Main_Service_Contact__c = accLocContactMap.get(ops.Account_Location__c).Id;
                        }

                        //XEN REYES 9.28.2018 KTS-2196: This is to ensure that even if the default owner is Individual, the work order will be routed to the correct queue.
                        workOrder.OwnerId = UserInfo.getUserId();
                        if(countrySAPCodeMap.containsKey(workOrder.SalesOrganization__c)){
                            if(queueNameIdMap.containsKey(countrySAPCodeMap.get(workOrder.SalesOrganization__c))){
                                workOrder.OwnerId = queueNameIdMap.get(countrySAPCodeMap.get(workOrder.SalesOrganization__c));
                            } 
                        }

                        weeklyWorkList.add(workOrder);
                        assetIdOpWeeklyMap.put(workOrder.OP_Physical_Asset__c,ops);
                        lworkOrderMap.put(workOrder.OP_Physical_Asset__c, workOrder);

                }else if(ops.Specific_Days_in_Week__c == true){
                    
                    //SCENARIO 2
                    if(ops.Schedule_Tasks_for_Holiday__c == true){
                        Integer endhour = countryMapEnd.get(ops.PhysicalAsset__r.SalesOrganization__c) == null ? 17 : countryMapEnd.get(ops.PhysicalAsset__r.SalesOrganization__c);
                        system.debug('scenario 2 endhour ' + endhour);
                        Integer fieldValueMapSize = fieldValueMap.values().size(); //7                       
                        for(Integer i=1; i <= fieldValueMapSize; i++){  
                            //Boolean busHour = BusinessHours.isWithin(ops.OP_Business_Hours__c, DateTime.newInstance(runDate.addDays(i).year(), runDate.addDays(i).month(), runDate.addDays(i).day(), endhour-1, 59, 59));
                            if(fieldValueMap.containsKey(String.valueOf(i))){
                                if(fieldValueMap.get(String.valueOf(i)) != '0' && fieldValueMap.get(String.valueOf(i)) != null){

                                    WorkOrder workOrder = new WorkOrder();

                                    String priceBookKey = String.valueOf(ops.physicalAsset__r.Product__c) + ops.physicalAsset__r.SalesOrganization__c;               
                                    workOrder.Pricebook2Id = priceBookMap.get(priceBookKey) != null ? priceBookMap.get(priceBookKey).Pricebook2Id : null;
                                    workOrder.RecordTypeId = CONST_WORKORDER_OP_RT;
                                    workOrder.OP_Physical_Asset__c = ops.PhysicalAsset__c;
                                    workOrder.WorkOrderType__c = CONST_WORKORDER_OP_TYPE; //CONST_WORKORDER_OP_WT;               
                                    workOrder.SalesOrganization__c = ops.PhysicalAsset__r.SalesOrganization__c;
                                    workOrder.AccountId = ops.PhysicalAsset__r.SoldTo__c; 

                                    //Karen Hung 26.06.2019 DOO-288 populate main service contact
                                    if(accLocContactMap.containsKey(ops.Account_Location__c)){
                                        workOrder.Main_Service_Contact__c = accLocContactMap.get(ops.Account_Location__c).Id;
                                    }                                  

                                    //XEN REYES 9.28.2018 KTS-2196: This is to ensure that even if the default owner is Individual, the work order will be routed to the correct queue.
                                    workOrder.OwnerId = UserInfo.getUserId();
                                    if(countrySAPCodeMap.containsKey(workOrder.SalesOrganization__c)){
                                        if(queueNameIdMap.containsKey(countrySAPCodeMap.get(workOrder.SalesOrganization__c))){
                                            workOrder.OwnerId = queueNameIdMap.get(countrySAPCodeMap.get(workOrder.SalesOrganization__c));
                                        } 
                                    }

                                    workList.add(workOrder);
                                    
                                    workKeys.add(String.valueOf(i));
                                    workValues.add(fieldValueMap.get(String.valueOf(i)));
                                    //workOrderHoliday2Map.put(workOrder,busHour);
                                    assetIdOpMap.put(workOrder.OP_Physical_Asset__c,ops);
                                    
                                }
                            }
                        }

                    }else if(ops.Schedule_Tasks_for_Holiday__c == false){
                       // scenario 3 - do not create work order on a holiday
                        Integer endhour = countryMapEnd.get(ops.PhysicalAsset__r.SalesOrganization__c) == null ? 17 : countryMapEnd.get(ops.PhysicalAsset__r.SalesOrganization__c);
                        Integer fieldValueMapSize = fieldValueMap.values().size(); //7
                        
                        for(Integer i=1; i <= fieldValueMapSize; i++){
                            Integer addDays = i;
                            
                            //Boolean busHour = BusinessHours.isWithin(ops.OP_Business_Hours__c, DateTime.newInstance(runDate.addDays(i).year(), runDate.addDays(i).month(), runDate.addDays(i).day(), endhour-1, 59, 59));
                            Boolean busHour = BusinessHours.isWithin(countryBusinessHoursMap.get(ops.Sales_Organization__c), DateTime.newInstance(runDate.addDays(i).year(), runDate.addDays(i).month(), runDate.addDays(i).day(), endhour-1, 59, 59));
                            
                            if(fieldValueMap.containsKey(String.valueOf(i))){
                                if(fieldValueMap.get(String.valueOf(i)) != '0' && fieldValueMap.get(String.valueOf(i)) != null && 
                                    //BusinessHours.isWithin(ops.OP_Business_Hours__c, DateTime.newInstance(runDate.addDays(addDays).year(), runDate.addDays(addDays).month(), runDate.addDays(addDays).day(), endhour-1, 59, 59))
                                    BusinessHours.isWithin(countryBusinessHoursMap.get(ops.Sales_Organization__c), DateTime.newInstance(runDate.addDays(addDays).year(), runDate.addDays(addDays).month(), runDate.addDays(addDays).day(), endhour-1, 59, 59))
                                    ){
                                    
                                    WorkOrder workOrder = new WorkOrder();
                                    
                                    String priceBookKey = String.valueOf(ops.physicalAsset__r.Product__c) + ops.physicalAsset__r.SalesOrganization__c;               
                                    workOrder.Pricebook2Id = priceBookMap.get(priceBookKey) != null ? priceBookMap.get(priceBookKey).Pricebook2Id : null;
                                    workOrder.RecordTypeId = CONST_WORKORDER_OP_RT;
                                    workOrder.OP_Physical_Asset__c = ops.PhysicalAsset__c;
                                    workOrder.WorkOrderType__c = CONST_WORKORDER_OP_TYPE; //CONST_WORKORDER_OP_WT;               
                                    workOrder.SalesOrganization__c = ops.PhysicalAsset__r.SalesOrganization__c;
                                    workOrder.AccountId = ops.PhysicalAsset__r.SoldTo__c;

                                    //Karen Hung 26.06.2019 DOO-288 populate main service contact
                                    if(accLocContactMap.containsKey(ops.Account_Location__c)){
                                        workOrder.Main_Service_Contact__c = accLocContactMap.get(ops.Account_Location__c).Id;
                                    }                                     

                                    //XEN REYES 9.28.2018 KTS-2196: This is to ensure that even if the default owner is Individual, the work order will be routed to the correct queue.
                                    workOrder.OwnerId = UserInfo.getUserId();
                                    if(countrySAPCodeMap.containsKey(workOrder.SalesOrganization__c)){
                                        if(queueNameIdMap.containsKey(countrySAPCodeMap.get(workOrder.SalesOrganization__c))){
                                            workOrder.OwnerId = queueNameIdMap.get(countrySAPCodeMap.get(workOrder.SalesOrganization__c));
                                        } 
                                    }

                                    workWOholidayList.add(workOrder);
                                    
                                    holidayWorkKeys.add(String.valueOf(i));
                                    holidayWorkValues.add(fieldValueMap.get(String.valueOf(i)));
                                    assetIdOpHolidayMap.put(workOrder.OP_Physical_Asset__c,ops);
                                }
                            }   
                        }               
                    }   
                }
            }
            
            List<WorkOrder> allWorkOrders = new List<WorkOrder>(); //list of all work orders to be inserted
            if(!weeklyWorkList.isEmpty()){
                allWorkOrders.addAll(weeklyWorkList); //Scenario 1 WorkOrders
            }
            if(!workList.isEmpty()){
                allWorkOrders.addAll(workList);  //Scenario 2 WorkOrders
            }
            if(!workWOholidayList.isEmpty()){
                allWorkOrders.addAll(workWOholidayList);  //Scenario 3 WorkOrders
            }
            if(Schema.sObjectType.WorkOrder.isCreateable()){
               Database.SaveResult[] allWork = Database.insert(allWorkOrders, false);
               INSERT_LOGGING(allWork, 'WorkOrder Insert');  //Karen Hung 13.05.2020 DOO-4481 Added insert logging
            }
            /*insert all Work Orders for all scenarios*/
            /*if(!weeklyWorkList.isEmpty()){
                Database.SaveResult[] weeklyWorkOrders = database.insert(weeklyWorkList); //Scenario 1 WorkOrders
                system.debug('scenario1 wo' + weeklyWorkOrders);
            }
            if(!workList.isEmpty()){
                Database.SaveResult[] dailyWorkOrders = database.insert(workList);  //Scenario 2 WorkOrders
                system.debug('scenario2 wo' + dailyWorkOrders);
            }
            if(!workWOholidayList.isEmpty()){
                Database.SaveResult[] dailyWOHolidayWorkOrders = database.insert(workWOholidayList);  //Scenario 3 WorkOrders
                system.debug('scenario3 wo' + dailyWOHolidayWorkOrders);
            }*/
            System.debug('execute workOrder'+Limits.getCpuTime());            
            /******************create woli for all scenarios***********************************/
            
            /**START - Scenario 1 WOLI CREATION**/                             
            for(WorkOrder weeklyWo : weeklyWorkList){
                Integer starthour = countryMapStart.get(assetIdOpWeeklyMap.get(weeklyWo.OP_Physical_Asset__c).PhysicalAsset__r.SalesOrganization__c) == null ? 8 : countryMapStart.get(assetIdOpWeeklyMap.get(weeklyWo.OP_Physical_Asset__c).PhysicalAsset__r.SalesOrganization__c); //default starthour
                Integer endhour = countryMapEnd.get(assetIdOpWeeklyMap.get(weeklyWo.OP_Physical_Asset__c).PhysicalAsset__r.SalesOrganization__c) == null ? 17 : countryMapEnd.get(assetIdOpWeeklyMap.get(weeklyWo.OP_Physical_Asset__c).PhysicalAsset__r.SalesOrganization__c);

                WorkOrderLineItem lineItem = new WorkOrderLineItem();
                lineItem.WorkOrderType__c = CONST_WORKORDER_OP_TYPE;
                lineItem.AccountLocation__c = assetIdOpWeeklyMap.get(weeklyWo.OP_Physical_Asset__c).PhysicalAsset__r.AccountLocation__c;
                lineItem.WorkOrderLineItemType__c = CONST_SmallTask_ACTIVITY;                
                lineItem.EarlyStart__c = DateTime.newInstance(runDate.addDays(1).year(), runDate.addDays(1).month(), runDate.addDays(1).day(), starthour, 0, 0);
                lineItem.SLADate__c=DateTime.newInstance(runDate.addDays(5).year(), runDate.addDays(5).month(), runDate.addDays(5).day(), endhour, 0, 0);
                lineItem.Building__c = assetIdOpWeeklyMap.get(weeklyWo.OP_Physical_Asset__c).PhysicalAsset__r.Building__c;
                lineItem.AccountLocationID__c = assetIdOpWeeklyMap.get(weeklyWo.OP_Physical_Asset__c).PhysicalAsset__r.AccountLocation__r.SAP_Customer_ID__c;
                lineItem.Floor__c = assetIdOpWeeklyMap.get(weeklyWo.OP_Physical_Asset__c).PhysicalAsset__r.Floor__c;
                lineItem.OP_IsHoliday__c = false;
                lineItem.PhysicalAsset__c = assetIdOpWeeklyMap.get(weeklyWo.OP_Physical_Asset__c).PhysicalAsset__c;
                lineItem.OP_PreferredOperator__c = assetIdOpWeeklyMap.get(weeklyWo.OP_Physical_Asset__c).PhysicalAsset__r.OP_PreferredOperator__c;
                
                //-------------to set pricebook entry
                String priceBookKey1 = String.valueOf(assetIdOpWeeklyMap.get(weeklyWo.OP_Physical_Asset__c).PhysicalAsset__r.Product__c) + assetIdOpWeeklyMap.get(weeklyWo.OP_Physical_Asset__c).PhysicalAsset__r.SalesOrganization__c;
                lineItem.PricebookEntryId = priceBookMap.get(priceBookKey1) != null ? priceBookMap.get(priceBookKey1).Id : null;
                //-----------------------------------------------------//
                
                lineItem.RecordTypeId = CONST_WOLI_OP_RT;
                lineItem.Status = CONST_WOLI_OPEN_STATUS; //'Open';
                lineItem.WorkOrderId = weeklyWo.id;
                lineItem.OP_247Customer__c = assetIdOpWeeklyMap.get(weeklyWo.OP_Physical_Asset__c).OP_247Customer__c;
                lineItem.MachineCare__c = assetIdOpWeeklyMap.get(weeklyWo.OP_Physical_Asset__c).PhysicalAsset__r.Machine_Care__c;
                woliToCreateList.add(lineItem);
            }                       
            /**END - Scenario 1 WOLI CREATION**/
            
            /**START - Scenario 2 WOLI CREATION**/
            for(integer i=0; i<workList.size(); i++){
                if(!workKeys.isEmpty() && workList.size() != 0){
                    workDayMap.put(workList[i].id,workKeys[i]); 
                    taskPerDayMap.put(workList[i].id,workValues[i]);  
                }
            }
            
            for(WorkOrder dailyWo : workList){ 
                Integer starthour = countryMapStart.get(assetIdOpMap.get(dailyWo.OP_Physical_Asset__c).PhysicalAsset__r.SalesOrganization__c) == null ? 8 : countryMapStart.get(assetIdOpMap.get(dailyWo.OP_Physical_Asset__c).PhysicalAsset__r.SalesOrganization__c); 
                Integer endhour =  countryMapEnd.get(assetIdOpMap.get(dailyWo.OP_Physical_Asset__c).PhysicalAsset__r.SalesOrganization__c) == null ? 17 : countryMapEnd.get(assetIdOpMap.get(dailyWo.OP_Physical_Asset__c).PhysicalAsset__r.SalesOrganization__c); 
                
                Map<String,String> indicatorMap = new Map<String,String>();
                indicatorMap.put('1',assetIdOpMap.get(dailyWo.OP_Physical_Asset__c).SM_1_Monday__c);
                indicatorMap.put('5',assetIdOpMap.get(dailyWo.OP_Physical_Asset__c).SM_1_Friday__c);

                //XEN REYES Nov. 22, 2018
                Integer taskperDay = Integer.valueOf(taskPerDayMap.get(dailyWo.Id));

                for(integer i=0; i<Integer.valueOf(taskPerDayMap.get(dailyWo.Id)); i++){
                    OperatingSchedule__c opSched = assetIdOpMap.get(dailyWo.OP_Physical_Asset__c);
                    WorkOrderLineItem lineItem = new WorkOrderLineItem();   
                    Integer daysAfterRun = Integer.valueOf(workDayMap.get(dailyWo.id));
                    String timeIndicator;
                    if(daysAfterRun == 1 || daysAfterRun == 5){
                        timeIndicator = indicatorMap.get(String.valueOf(daysAfterRun));
                        if(timeIndicator == 'AM' || timeIndicator =='PM'){
                             lineitem.OP_TimeIndicator__c = timeIndicator ;    
                        }                    
                    }
                    
                    //Boolean busHour = BusinessHours.isWithin(opSched.OP_Business_Hours__c, DateTime.newInstance(runDate.addDays(daysAfterRun).year(), runDate.addDays(daysAfterRun).month(), runDate.addDays(daysAfterRun).day(), endhour-1, 59, 59));
                    
                    Boolean busHour = BusinessHours.isWithin(countryBusinessHoursMap.get(opSched.Sales_Organization__c), DateTime.newInstance(runDate.addDays(daysAfterRun).year(), runDate.addDays(daysAfterRun).month(), runDate.addDays(daysAfterRun).day(), endhour-1, 59, 59));

                    lineItem.WorkOrderType__c = CONST_WORKORDER_OP_TYPE;
                    lineItem.AccountLocation__c = opSched.PhysicalAsset__r.AccountLocation__c;
                    lineItem.WorkOrderLineItemType__c = CONST_SmallTask_ACTIVITY;

                    //XEN REYES Nov. 22, 2018
                    if(taskperDay > 1){
                        lineItem.EarlyStart__c = DateTime.newInstance(runDate.addDays(daysAfterRun).year(), runDate.addDays(daysAfterRun).month(), runDate.addDays(daysAfterRun).day(), starthour, i, 0);    
                    } else {
                        lineItem.EarlyStart__c = DateTime.newInstance(runDate.addDays(daysAfterRun).year(), runDate.addDays(daysAfterRun).month(), runDate.addDays(daysAfterRun).day(), starthour, 0, 0);
                    }
                    
                    lineItem.SLADate__c=DateTime.newInstance(runDate.addDays(daysAfterRun).year(), runDate.addDays(daysAfterRun).month(), runDate.addDays(daysAfterRun).day(), endhour, 0, 0);
                    lineItem.Building__c = opSched.PhysicalAsset__r.Building__c;
                    lineItem.AccountLocationID__c = opSched.PhysicalAsset__r.AccountLocation__r.SAP_Customer_ID__c;
                    lineItem.Floor__c = opSched.PhysicalAsset__r.Floor__c;
                    lineItem.OP_IsHoliday__c = busHour == true ? false : true;
                    lineItem.PhysicalAsset__c = opSched.PhysicalAsset__c;
                    lineItem.OP_PreferredOperator__c = opSched.PhysicalAsset__r.OP_PreferredOperator__c;
                    
                    //-------------to set pricebook entry
                    String priceBookKey1 = String.valueOf(opSched.PhysicalAsset__r.Product__c) + opSched.PhysicalAsset__r.SalesOrganization__c;
                    lineItem.PricebookEntryId = priceBookMap.get(priceBookKey1) != null ? priceBookMap.get(priceBookKey1).Id : null;
                    //-----------------------------------------------------//
                    
                    lineItem.RecordTypeId = CONST_WOLI_OP_RT;
                    lineItem.Status = CONST_WOLI_OPEN_STATUS; //'Open';
                    lineItem.WorkOrderId = dailyWo.id;
                    lineItem.OP_247Customer__c = opSched.OP_247Customer__c;
                    lineItem.MachineCare__c = opSched.PhysicalAsset__r.Machine_Care__c;
                    
                    woliToCreateList.add(lineItem);    
                }
            }
            /**END - Scenario 2 WOLI CREATION**/
            
            /**START - Scenario 3 WOLI CREATION**/
            for(integer i=0; i<workWOholidayList.size(); i++){
                if(!holidayWorkKeys.isEmpty() && workWOholidayList.size() != 0){
                    workDayHolidayMap.put(workWOholidayList[i].id,holidayWorkKeys[i]); 
                    taskPerDayHolidayMap.put(workWOholidayList[i].id,holidayWorkValues[i]);  
                }
            }

            for(WorkOrder noHolidayWorkOrd : workWOholidayList){
                Integer starthour = countryMapStart.get(assetIdOpHolidayMap.get(noHolidayWorkOrd.OP_Physical_Asset__c).PhysicalAsset__r.SalesOrganization__c) == null ? 8 : countryMapStart.get(assetIdOpHolidayMap.get(noHolidayWorkOrd.OP_Physical_Asset__c).PhysicalAsset__r.SalesOrganization__c);  //default
                Integer endhour = countryMapEnd.get(assetIdOpHolidayMap.get(noHolidayWorkOrd.OP_Physical_Asset__c).PhysicalAsset__r.SalesOrganization__c) == null ? 17 : countryMapEnd.get(assetIdOpHolidayMap.get(noHolidayWorkOrd.OP_Physical_Asset__c).PhysicalAsset__r.SalesOrganization__c); //default

                Map<String,String> indicatorMap = new Map<String,String>();
                indicatorMap.put('1',assetIdOpHolidayMap.get(noHolidayWorkOrd.OP_Physical_Asset__c).SM_1_Monday__c);
                indicatorMap.put('5',assetIdOpHolidayMap.get(noHolidayWorkOrd.OP_Physical_Asset__c).SM_1_Friday__c);

                //XEN REYES Nov. 22, 2018
                Integer taskperDay = Integer.valueOf(taskPerDayHolidayMap.get(noHolidayWorkOrd.Id));

                for(integer i=0; i<Integer.valueOf(taskPerDayHolidayMap.get(noHolidayWorkOrd.Id)); i++){
                    OperatingSchedule__c opSched = assetIdOpHolidayMap.get(noHolidayWorkOrd.OP_Physical_Asset__c);
                    WorkOrderLineItem lineItem = new WorkOrderLineItem();   
                    Integer daysAfterRun = Integer.valueOf(workDayHolidayMap.get(noHolidayWorkOrd.id));
                    String timeIndicator;
                    if(daysAfterRun == 1 || daysAfterRun == 5){
                        timeIndicator = indicatorMap.get(String.valueOf(daysAfterRun));
                        if(timeIndicator == 'AM' || timeIndicator =='PM'){
                             lineitem.OP_TimeIndicator__c = timeIndicator ;    
                        }                    
                    }
                    lineItem.WorkOrderType__c = CONST_WORKORDER_OP_TYPE;
                    lineItem.AccountLocation__c = opSched.PhysicalAsset__r.AccountLocation__c;
                    lineItem.WorkOrderLineItemType__c = CONST_SmallTask_ACTIVITY;

                    //XEN REYES Nov. 22, 2018
                    if(taskperDay > 1){
                        lineItem.EarlyStart__c = DateTime.newInstance(runDate.addDays(daysAfterRun).year(), runDate.addDays(daysAfterRun).month(), runDate.addDays(daysAfterRun).day(), starthour, i, 0);    
                    } else {
                        lineItem.EarlyStart__c = DateTime.newInstance(runDate.addDays(daysAfterRun).year(), runDate.addDays(daysAfterRun).month(), runDate.addDays(daysAfterRun).day(), starthour, 0, 0);
                    }

                    lineItem.SLADate__c=DateTime.newInstance(runDate.addDays(daysAfterRun).year(), runDate.addDays(daysAfterRun).month(), runDate.addDays(daysAfterRun).day(), endhour, 0, 0);
                    lineItem.Building__c = opSched.PhysicalAsset__r.Building__c;
                    lineItem.AccountLocationID__c = opSched.PhysicalAsset__r.AccountLocation__r.SAP_Customer_ID__c;
                    lineItem.Floor__c = opSched.PhysicalAsset__r.Floor__c;
                    lineItem.PhysicalAsset__c = opSched.PhysicalAsset__c;
                    lineItem.OP_PreferredOperator__c = opSched.PhysicalAsset__r.OP_PreferredOperator__c;
                    
                    //-------------to set pricebook entry
                    String priceBookKey1 = String.valueOf(opSched.PhysicalAsset__r.Product__c) + opSched.PhysicalAsset__r.SalesOrganization__c;
                    lineItem.PricebookEntryId = priceBookMap.get(priceBookKey1) != null ? priceBookMap.get(priceBookKey1).Id : null;
                    //-----------------------------------------------------//
                    
                    lineItem.RecordTypeId = CONST_WOLI_OP_RT;
                    lineItem.Status = CONST_WOLI_OPEN_STATUS; //'Open';
                    lineItem.WorkOrderId = noHolidayWorkOrd.id;
                    lineItem.OP_247Customer__c = opSched.OP_247Customer__c;
                    lineItem.MachineCare__c = opSched.PhysicalAsset__r.Machine_Care__c;
                    woliToCreateList.add(lineItem);    
                } 
            }
              
            
            /********************insert all woli for all scenarios*****************************/
            if(Schema.sObjectType.WorkOrderLineItem.isCreateable()){
                Database.SaveResult[] allWoli = Database.insert(woliToCreateList, true);
                INSERT_LOGGING(allWoli, 'WorkOrderLineItem Insert');  //Karen Hung 13.05.2020 DOO-4481 Added insert logging
            }
            System.debug('execute workOrderlineitem'+Limits.getCpuTime());      

        }catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
            errors.add(ex);
        }
        
        CustomLogging.pop();
    }

    /******************************************************************************
     * @author         Karen Hung
     * @date           30.aug.2018
     * @description    This method to perform actions when the batch is finished
     * @revision(s)
     ******************************************************************************/
    global void finish(Database.BatchableContext BC) {
        CustomLogging.push('finish', 'TS_CreateTask_Batch');
        System.debug('errors >> ' + errors);
    
        List<OperatingSchedule__c> opsToUpdate = new List<OperatingSchedule__c>();
        opsToUpdate = database.query(getQuery());
        for(OperatingSchedule__c opSched : opsToUpdate){
            opSched.Last_Batch_Date__c = runDate;
        }
        Database.SaveResult[] schedResult = database.update(opsToUpdate,false); //Karen Hung DOO-4481 13.5.2020 to allow partial update.
        INSERT_LOGGING(schedResult, 'Operating Schedule Update'); //Karen Hung DOO-4481 13.5.2020 added insert logging

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
            mail.setSubject('Operating Batch Result: ' + a.Status); // 
            mail.setPlainTextBody(emailMessage);
            if (Operating_Task__c.getInstance().Send_Email_Upon_Batch_Completion__c) Messaging.sendEmail(new Messaging.SingleEmailMessage[] {
                mail
            });
        }
        CustomLogging.pop();
        System.debug('finish'+Limits.getCpuTime());      
    }

    /******************************************************************************
     * @author         Karen Hung
     * @date          30.aug.2018
     * @description    This method returns a SQL syntax on active operating schedule table
     * @revision(s)
     ******************************************************************************/
    String getQuery() {
        String s = String.valueOf(runDate);
        CustomLogging.push('getQuery', 'TS_CreateTask_Batch');
        DescribeSObjectResult operatingScheduleDescribe = OperatingSchedule__c.getSObjectType().getDescribe();
        List<String> fields = new List<String>(operatingScheduleDescribe.fields.getMap().keySet());
        CustomLogging.pop();

        String DEFAULT_SOQL = 'SELECT ' + String.join(fields, ',') +
            ', PhysicalAsset__r.Product__c,  PhysicalAsset__r.SalesOrganization__c, PhysicalAsset__r.AccountLocation__c' +
            ', PhysicalAsset__r.Building__c,PhysicalAsset__r.AccountLocation__r.SAP_Customer_ID__c,PhysicalAsset__r.Floor__c' +
            ', PhysicalAsset__r.SoldTo__c, PhysicalAsset__r.OP_PreferredOperator__c, PhysicalAsset__r.MothballAssetIndicator__c, PhysicalAsset__r.Machine_Care__c ' +
            ', PhysicalAsset__r.AssetStatus__c, OP_Business_Hours__r.MondayStartTime, OP_Business_Hours__r.MondayEndTime ' +
            ', Account_Location__r.Apttus_Config2__AccountId__c' + ////Added by Karen Hung 26.06.2019 DOO-288
            ' FROM ' + operatingScheduleDescribe.getName() +
            ' WHERE Active__c = true  ' +
            ' AND PhysicalAsset__c != null  ' +
            ' AND TypeofContract__c != null  ' +
            ' AND Schedule_Type__c = \'Weekly\'  ' +
            ' AND PhysicalAsset__r.MothballAssetIndicator__c = false  ' +
            ' AND PhysicalAsset__r.AccountLocation__c != null ' + //ADDED Xen Reyes April 17, 2019 ALM 6752
            ' AND PhysicalAsset__r.AssetStatus__c = \'Activated\' ' + //ADDED Xen Reyes April 17, 2019 ALM 6752
            ' AND (Start_Date__c = ' + s + ' OR Next_Batch_Date__c = ' + s + ' )';

        if(SOQL_OVERRIDE){
            return NEW_SOQL_STRING;
        } else {
            return DEFAULT_SOQL;
        }
    }
    
    /******************************************************************************
     * @author         Karen Hung
     * @date           30.aug.2018
     * @description    
     * @revision(s)
     ******************************************************************************/
    private Map<String,PricebookEntry> createPriceBookEntryMap(List<OperatingSchedule__c> osl) {
        CustomLogging.push('createCounterReadingList', 'TS_CreateTask_Batch');
        Map<String,PricebookEntry> prMap = new Map <String,PricebookEntry>();

        Set<ID> productSet = new Set<ID>();
        Set<String> salesOrganizationSet = new Set<String> ();
        for (OperatingSchedule__c os: osl) {
            productSet.add(os.PhysicalAsset__r.Product__c);
            salesOrganizationSet.add(os.PhysicalAsset__r.SalesOrganization__c);
        }

        //GET PRICEBOOK ENTRY
        List<PricebookEntry> pbeList;
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
     * Karen Hung
     * 13.05.2020  DOO-4481 Method to create a custom log record if there is failed record processed in the batch execution.
     ******************************************************************************/
    public void INSERT_LOGGING (List<Database.SaveResult> saveResultList, String description) {

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
        if(!exception_List_batch.isEmpty() || Test.isRunningTest()){
            String mainMessage = '';

            for(String err : exception_List_batch){
                mainMessage = err + '\n';
            }

            //CREATE CUSTOM LOG
            Custom_Log__c log = new Custom_Log__c(
                StackTrace__c = 'Operating Weekly Batch: ' + description,
                Message__c = mainMessage,
                ExceptionType__c = TS_Constants.DATABASE_ERROR);
            insert log;
        }
    }
}