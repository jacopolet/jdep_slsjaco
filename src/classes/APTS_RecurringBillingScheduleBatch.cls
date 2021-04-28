/**
* Class Name : APTS_RecurringBillingScheduleBatch
* Description : Admin Order Creation for Recurring Billing Schedules                    
* Author : Balashanthi
* Date Created : 12/05/2018
* Revision v101 : Ankit Joshi - 11/4/2019 - To run Recurring Batch for all countires
* Revision V102 : Balashanthi A - 21/04/2019 Defect # 6776 The 'Start date' and 'End date' on the Bundle header (machine) should reflect the period of the related Order line items
* Revision V103 - Balashanthi A - CR # 2265 To run Recurring Batch for all countires
* Revision V104 - Amit - 07-09-2019 - JIRA : DFT2C-1408 : Fix for start and end date on primary l1 line item
* Revision V105 - Renuka - 10-04-2020 - JIRA: DQ-1955: Update the Query Filter 
* Revision V106 - Renuka - 07-09-2020 - JIRA: DQ-2754: Include all contracted recurring billing schedules related to orders with fixed term flag Z
**/
global class APTS_RecurringBillingScheduleBatch  implements Database.Batchable<sObject>, Database.Stateful {
    private static final String FIXEDTERMFLAG = 'Z';
    private static final String DEINSTALLATION = 'De-installation';
    private static final String UNPLANNEDRETURN = 'Unplanned Return';
    private static final String STANDARDRETURN = 'Standard Return';
    private static final String FIXEDTERMSAPTYPE = 'XD01';
    private static final String FIXEDTERMLINETYPE = 'Misc';
    private static final String STARTDATE = 'StartDate';
    private static final String ENDDATE = 'EndDate';
    private static final String WITHPRICE = 'WithPrice';
    private static final String NOPRICE = 'NoPrice';
    private static final String EMPTY = 'EMPTY';
    
    //XD01
    public Map<String, Id> adminOrderCreatedInEachChunk = new Map<String,Id>(); 
    public String processedSalesOrg = null;
    public Map<Id,Apttus_Config2__OrderLineItem__c> primaryOrderLineToUpdate = new Map<Id,Apttus_Config2__OrderLineItem__c>();
    /*1. KeyValue Format <<L1AssetId+StartDate/EndDate+WithPrice,Date>>
    2. KeyValue Format <<L1AssetId+StartDate/EndDate+NoPrice,Date>> */
    public Map<String,Date> primaryL1DateMap = new Map<String,Date>();//V105
    public Map<String,String> invoiceMap = APTS_BIRUtils.getInvoiceDeliveryPreferenceMapping(); 

    /** Method name APTS_RecurringBillingScheduleBatch
    * Description : Parametric constructor to take values
    **/
    public APTS_RecurringBillingScheduleBatch(String processedSalesOrg){
        this.processedSalesOrg = processedSalesOrg;
        //system.debug('processedSalesOrg Present==>'+processedSalesOrg);
    }
   
   /** Method Name : start
    * Description : start method of Batch class
    **/
    global Database.QueryLocator start(Database.BatchableContext batchContext) {
        //String query = APTS_RecurringBillingScheduleBatchHelper.getReccurringBatchQueryString(processedSalesOrg);
        String query = APTS_RecurringBillingScheduleBatchHelper.getReccurringBatchQueryStringStart(processedSalesOrg);
        //system.debug('===>query===>'+query);
        return Database.getQueryLocator(query);
    }
    /** Method Name : execute
    * Description : execute method of Batch class
    **/
    global void execute(Database.BatchableContext batchContext,  
        List<Apttus_Billing__BillingSchedule__c> billingScheduleRecordsID) {
        //List<Apttus_Billing__BillingSchedule__c> billingScheduleRecords) {
        
        Set<Id> billingSchedulesID = new Set<Id>();
        List<Apttus_Billing__BillingSchedule__c> billingScheduleRecords = new List<Apttus_Billing__BillingSchedule__c>();
        List<Apttus_Billing__BillingSchedule__c> bsToBeProcessed = new List<Apttus_Billing__BillingSchedule__c>();
        Set<String> fixedTermDummyProdSet=new Set<String>();
        fixedTermDummyProdSet = APTS_RecurringBillingScheduleBatchHelper.getFTDummyProducts();
        List<Apttus_Billing__BillingSchedule__c> toBeProcessedFixedTermList = new List<Apttus_Billing__BillingSchedule__c>();
        
        try{
            
            if(!billingScheduleRecordsID.isEmpty()){
                Map<Id, Apttus_Billing__BillingSchedule__c> billingScheduleRecordsIdMap = new Map<Id, Apttus_Billing__BillingSchedule__c>(billingScheduleRecordsID);
                billingSchedulesID = billingScheduleRecordsIdMap.keySet();
                String queryString = APTS_RecurringBillingScheduleBatchHelper.getReccurringBatchQueryStringExecute(billingSchedulesID);
                billingScheduleRecords = Database.query(queryString);
            }
            //system.debug('Inside Execute ==>');
            if(!billingScheduleRecords.isEmpty()){
                //system.debug('Inside Execute Billing Schedule ==>');
                for (Apttus_Billing__BillingSchedule__c billingScheduleList : billingScheduleRecords) {
                    if(billingScheduleList.Apttus_Billing__OrderLineItemId__c != null){
                        if(billingScheduleList.Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__c != null){
                            if(FIXEDTERMFLAG.equalsIgnoreCase(billingScheduleList.Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__r.APTS_Fix_Term_Billing_Flag__c)){
                                //V106 -- Commenting the below If conditions to process all BS with Z indicator
                                // Allow XD01 SAP order Type Orders with Z indicator
                                /*if(FIXEDTERMSAPTYPE.equalsIgnoreCase(billingScheduleList.Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c)){
                                    bsToBeProcessed.add(billingScheduleList);
                                }*/
                                // Allow Consumption Type of Contract with Z indicator
                                /*else if(APTS_BIRUtils.CONSUMPTIONTYPEOFCONTRACT.equalsIgnoreCase(billingScheduleList.Apttus_Billing__AssetLineItemId__r.APTS_Type_Of_Contract__c)){*/
                                    bsToBeProcessed.add(billingScheduleList);
                            }else{
                                if(fixedTermDummyProdSet.contains(billingScheduleList.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__ProductId__r.Name) 
                                    && FIXEDTERMLINETYPE.equalsIgnoreCase(billingScheduleList.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__LineType__c)){
                                    toBeProcessedFixedTermList.add(billingScheduleList);
                                }
                                else{
                                    // Non "Z" indicator at Orders need to be processed
                                    bsToBeProcessed.add(billingScheduleList);
                                }
                            }
                        }
                    }else{
                        // Will run for Data Migration records - As migrated Records won't have Order Line item @ billing schedules
                        bsToBeProcessed.add(billingScheduleList);
                    }
                }
                //system.debug('Inside bsToBeProcessed Schedule ==>'+bsToBeProcessed);
                if(!toBeProcessedFixedTermList.IsEmpty()){
                    Map<String, Id> tempMap = APTS_RecurringBillingScheduleBatchHelper.createAdminOrderForFixedTerm(toBeProcessedFixedTermList,adminOrderCreatedInEachChunk,invoiceMap); 
                    //system.debug('########tempMap ######==>'+tempMap);
                    if(!tempMap.isEmpty()){
                        adminOrderCreatedInEachChunk.putAll(tempMap);
                    }
                }
                
                if(!bsToBeProcessed.isEmpty()){
                    Map<String, Id> tempMap = APTS_RecurringBillingScheduleBatchHelper.createAdminOrder(bsToBeProcessed,adminOrderCreatedInEachChunk,
                                                                                                primaryOrderLineToUpdate,invoiceMap,primaryL1DateMap);
                    if(!tempMap.isEmpty()){
                        adminOrderCreatedInEachChunk.putAll(tempMap);
                    }
                }
            }
        }catch(Exception e){APTS_BIRUtils.logError(null,null,null,e,APTS_BIRUtils.BATCH,APTS_BIRUtils.CREATEADMINORDEREXECUTE,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,true);}
    }
    /** Method Name : finish
    * Description : finish method of Batch class
    **/
    global void finish(Database.BatchableContext batchContext) {
        try{
            Set<Id> orderIdSet = new Set<Id>();  
            Boolean muteSAPCall  = false;
            Map<Id,Apttus_Config2__OrderLineItem__c> p1LineStartEndDtUpdateMap = new Map<Id,Apttus_Config2__OrderLineItem__c>();

            //v101 Start
            //Update the Processed checkbox for the custom setting sales org record for which the Batch ran
            String salesOrgToBeProcessed = '';
            //Map<String, APTS_Recurring_Batch_Countries__c> countryMap = APTS_Recurring_Batch_Countries__c.getAll();
            Map<Integer, APTS_Recurring_Batch_Countries__c> countrySeqMap = new Map<Integer, APTS_Recurring_Batch_Countries__c>();
            Map<Integer, APTS_Recurring_Batch_Countries__c> countryMapToUpdate = new Map<Integer, APTS_Recurring_Batch_Countries__c>();
            for(APTS_Recurring_Batch_Countries__c rbcRec : APTS_Recurring_Batch_Countries__c.getAll().values()){
               countrySeqMap.put(Integer.valueOf(rbcRec.APTS_Sequence__c), rbcRec);
            }
            //system.debug('processedSalesOrg==>'+processedSalesOrg);
            
            for(Integer i=1 ; i<=countrySeqMap.size() ; i++){    
                APTS_Recurring_Batch_Countries__c rbcRec = countrySeqMap.get(i);
                //system.debug('INSIDE IF processedSalesOrg flag ==>'+processedSalesOrg);
                if(!rbcRec.APTS_Processed__c){
                    //Update the processed checkbox
                    if(processedSalesOrg.equalsIgnoreCase(rbcRec.APTS_Sales_Org__c)){
                         rbcRec.APTS_Processed__c = true;
                        countryMapToUpdate.put(Integer.valueOf(rbcRec.APTS_Sequence__c), rbcRec);
                    }else{
                       //Getting the next sequence of Sales Organisation
                        if(countrySeqMap.size() >= (i)
                            && countrySeqMap.get(i) != null){
                            if(!countrySeqMap.get(i).APTS_Processed__c){
                                salesOrgToBeProcessed = countrySeqMap.get(i).APTS_Sales_Org__c;
                                //system.debug('salesOrg in finish method==>'+salesOrgToBeProcessed);
                                break;
                            }  
                        } 
                    } 
                }  
            }
            if(!countryMapToUpdate.values().isEmpty()){
                update countryMapToUpdate.values();
            }
            //system.debug('salesOrg in finish method==>'+salesOrgToBeProcessed);  
            
            //v101 end
            //system.debug('@@@@@@@@adminOrderCreatedInEachChunk FINAL ==> '+adminOrderCreatedInEachChunk);
            if(!adminOrderCreatedInEachChunk.isEmpty()){
                // Update all primary order line item
                
                //<<++ Revision V102 : Balashanthi A - Defect # 6776 The 'Start date' and 'End date' on the Bundle header (machine) should reflect the period of the related Order line items
                //<<++Begin  Revision V104 : Renuka - Fix for start and end date on primary l1 line item 
                for(Id key : primaryOrderLineToUpdate.keyset()){
                    
                    String keyForDate = String.valueOf(primaryOrderLineToUpdate.get(key).Apttus_Config2__AssetLineItemId__c);
                    if(primaryL1DateMap.containsKey(keyForDate+ENDDATE+WITHPRICE)){
                        primaryOrderLineToUpdate.get(key).Apttus_Config2__EndDate__c = primaryL1DateMap.get(keyForDate+ENDDATE+WITHPRICE);
                    }else if(primaryL1DateMap.containskey(keyForDate+ENDDATE+NOPRICE)){
                        primaryOrderLineToUpdate.get(key).Apttus_Config2__EndDate__c = primaryL1DateMap.get(keyForDate+ENDDATE+NOPRICE);
                    }
                    if(primaryL1DateMap.containsKey(keyForDate+STARTDATE+WITHPRICE)){
                        primaryOrderLineToUpdate.get(key).Apttus_Config2__StartDate__c = primaryL1DateMap.get(keyForDate+STARTDATE+WITHPRICE);
                    }else if(primaryL1DateMap.containskey(keyForDate+STARTDATE+NOPRICE)){
                        primaryOrderLineToUpdate.get(key).Apttus_Config2__StartDate__c =primaryL1DateMap.get(keyForDate+STARTDATE+NOPRICE);
                    }
                    p1LineStartEndDtUpdateMap.put(key,primaryOrderLineToUpdate.get(key));
                }//<<++End  Revision V104 : Renuka - Fix for start and end date on primary l1 line item 
                if(!p1LineStartEndDtUpdateMap.isEmpty()){
                    APTS_OrderUtils.stopOrderLineItemTrigger();
                    Database.SaveResult[] srList = Database.update(p1LineStartEndDtUpdateMap.values(), false);
                    APTS_BIRUtils.logError(null,srList,null,null,APTS_BIRUtils.BATCH,APTS_BIRUtils.ORDEROBJECTNAME,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,false);
                    APTS_OrderUtils.startOrderLineItemTrigger();
                }
                //<<-- Revision V102 : Balashanthi A - Defect # 6776 The 'Start date' and 'End date' on the Bundle header (machine) should reflect the period of the related Order line items
                orderIdSet.addAll(adminOrderCreatedInEachChunk.values());
                Map<String, APTS_MuteSAPSubmission__c> customSettingMap = APTS_MuteSAPSubmission__c.getAll();
                if(customSettingMap.containsKey('Mute SAP Call') 
                    && customSettingMap.get('Mute SAP Call') != null){
                    muteSAPCall = customSettingMap.get('Mute SAP Call').APTS_ISSAPCallDisabled__c;
                }
                if(!orderIdSet.isEmpty()
                    && !muteSAPCall){
                    APTS_IntegrationLogForBillingBatch sapSubmissionBatch = new APTS_IntegrationLogForBillingBatch(orderIdSet,salesOrgToBeProcessed);
                    Database.executeBatch(sapSubmissionBatch,200);
                }
            }
            else{
                //system.debug('Inside Debug===>'+salesOrgToBeProcessed);
                APTS_RecurringBillingScheduleBatchHelper.callRecurringBatchIfReqd(salesOrgToBeProcessed);
            }
        }catch(Exception e){APTS_BIRUtils.logError(null,null,null,e,APTS_BIRUtils.BATCH,APTS_BIRUtils.CREATEADMINORDERFINISH,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,true);}
    }
    
}