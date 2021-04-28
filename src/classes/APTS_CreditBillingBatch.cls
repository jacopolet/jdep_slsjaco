/**
* Class Name : APTS_CreditBillingBatch
* Description : Admin Order Creation for Credit Billing Schedules                    
* Author : Renuka (Accenture)
* Date Created : 28/07/2020
**/
//v100 17-09-2020: Renuka - DQ-3868 - Populating InvoiceRemark field from the references of superseded BS.
//v101 13-01-2020: Renuka - DQ-4602 - Excluding BS with XC09 block.

global class APTS_CreditBillingBatch  implements Database.Batchable<sObject>, Database.Stateful {
    private static final String STARTDATE = 'StartDate';
    private static final String ENDDATE = 'EndDate';
    private static final String EMPTY = 'EMPTY';
    public static final String CREATEADMINORDER ='createAdminOrder() Method';
    public static final String CREATEADMINORDERFINISH ='CreditBillingBatch finish() Method';
    public static final String CREATEADMINORDEREXECUTE ='CreditBillingBatch execute() Method';
    public Map<String, Id> adminOrderCreatedInEachChunk = new Map<String,Id>(); 
    public String processedSalesOrg = null;
    public Map<Id,Apttus_Config2__OrderLineItem__c> primaryOrderLineToUpdate = new Map<Id,Apttus_Config2__OrderLineItem__c>();
    /*1. KeyValue Format <<L1AssetId+StartDate/EndDate+WithPrice,Date>>
    2. KeyValue Format <<L1AssetId+StartDate/EndDate+NoPrice,Date>> */
    public Map<String,Date> primaryL1DateMap = new Map<String,Date>();//V105
    public Map<String,String> invoiceMap = APTS_BIRUtils.getInvoiceDeliveryPreferenceMapping(); 
    //v100++
    public Map<String,String> invoiceRemarkMap = new Map<String,String>();

    /** Method name APTS_CreditBillingBatch  
    * Description : Parametric constructor to take values
    **/
    public APTS_CreditBillingBatch(String processedSalesOrg){
        this.processedSalesOrg = processedSalesOrg;
        //system.debug('processedSalesOrg Present==>'+processedSalesOrg);
    }
   
   /** Method Name : start
    * Description : start method of Batch class
    **/
    global Database.QueryLocator start(Database.BatchableContext batchContext) {
        String query = APTS_CreditBillingBatchHelper.getReccurringBatchQueryStringStart(processedSalesOrg);
        return Database.getQueryLocator(query);
    }
    /** Method Name : execute
    * Description : execute method of Batch class
    **/
    global void execute(Database.BatchableContext batchContext,  
        List<Apttus_Billing__BillingSchedule__c> billingScheduleRecordsID) {
        
        Set<Id> billingSchedulesID = new Set<Id>();
        List<Apttus_Billing__BillingSchedule__c> billingScheduleRecords = new List<Apttus_Billing__BillingSchedule__c>();
        List<Apttus_Billing__BillingSchedule__c> bsToBeProcessed = new List<Apttus_Billing__BillingSchedule__c>();
        
        try{
            
            if(!billingScheduleRecordsID.isEmpty()){
                Map<Id, Apttus_Billing__BillingSchedule__c> billingScheduleRecordsIdMap = new Map<Id, Apttus_Billing__BillingSchedule__c>(billingScheduleRecordsID);
                billingSchedulesID = billingScheduleRecordsIdMap.keySet();
                String queryString = APTS_CreditBillingBatchHelper.getReccurringBatchQueryStringExecute(billingSchedulesID);
                billingScheduleRecords = Database.query(queryString);
            }
            if(!billingScheduleRecords.isEmpty()){
                //system.debug('Inside Execute Billing Schedule ==>');
                for (Apttus_Billing__BillingSchedule__c billingScheduleList : billingScheduleRecords) {
                    //v101<<Excluding BS with XC09 block.
                    if(billingScheduleList.Apttus_Billing__OrderLineItemId__c != null 
                        && billingScheduleList.Apttus_Billing__OrderLineItemId__r.APTS_Credit_Proposal_XC09_Block__c != null 
                        && !billingScheduleList.Apttus_Billing__OrderLineItemId__r.APTS_Credit_Proposal_XC09_Block__c){
                        bsToBeProcessed.add(billingScheduleList);
                    }
                }
                if(!bsToBeProcessed.isEmpty()){
                    Map<String, Id> tempMap = APTS_CreditBillingBatchHelper.createAdminOrder(bsToBeProcessed,adminOrderCreatedInEachChunk,
                                                                                             primaryOrderLineToUpdate,invoiceMap,primaryL1DateMap,
                                                                                             invoiceRemarkMap);
                    if(!tempMap.isEmpty()){
                        adminOrderCreatedInEachChunk.putAll(tempMap);
                    }
                }
            }
        }catch(Exception e){APTS_BIRUtils.logError(null,null,null,e,APTS_BIRUtils.BATCH,CREATEADMINORDEREXECUTE,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,true);}
    }
    /** Method Name : finish
    * Description : finish method of Batch class
    **/
    global void finish(Database.BatchableContext batchContext) {
        try{
            Set<Id> orderIdSet = new Set<Id>();  
            Boolean muteSAPCall  = false;
            Map<Id,Apttus_Config2__OrderLineItem__c> p1LineStartEndDtUpdateMap = new Map<Id,Apttus_Config2__OrderLineItem__c>();
            Map<Id,Apttus_Config2__Order__c> orderHeaderUpdateMap = new Map<Id,Apttus_Config2__Order__c>();
            //Update the Processed checkbox for the custom setting sales org record for which the Batch ran
            String salesOrgToBeProcessed = '';
            Map<Integer, APTS_Credit_Batch_Countries__c> countrySeqMap = new Map<Integer, APTS_Credit_Batch_Countries__c>();
            Map<Integer, APTS_Credit_Batch_Countries__c> countryMapToUpdate = new Map<Integer, APTS_Credit_Batch_Countries__c>();
            for(APTS_Credit_Batch_Countries__c rbcRec : APTS_Credit_Batch_Countries__c.getAll().values()){
               countrySeqMap.put(Integer.valueOf(rbcRec.APTS_Sequence__c), rbcRec);
            }
            //system.debug('processedSalesOrg==>'+processedSalesOrg);
            
            for(Integer i=1 ; i<=countrySeqMap.size() ; i++){    
                APTS_Credit_Batch_Countries__c rbcRec = countrySeqMap.get(i);
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
            if(!adminOrderCreatedInEachChunk.isEmpty()){
                Apttus_Config2__Order__c orderobj;
                for(String key : adminOrderCreatedInEachChunk.keyset()){
                    if(invoiceRemarkMap.containsKey(key)){
                        orderobj = new Apttus_Config2__Order__c();
                        orderobj.Id = adminOrderCreatedInEachChunk.get(key);
                        orderobj.APTS_Invoice_Remark__c = invoiceRemarkMap.get(key);
                        orderHeaderUpdateMap.put(orderobj.Id,orderobj);
                    }
                }
                
                for(Id key : primaryOrderLineToUpdate.keyset()){
                    
                    String keyForDate = String.valueOf(primaryOrderLineToUpdate.get(key).Apttus_Config2__AssetLineItemId__c);
                    if(primaryL1DateMap.containsKey(keyForDate+ENDDATE)){
                        primaryOrderLineToUpdate.get(key).Apttus_Config2__EndDate__c = primaryL1DateMap.get(keyForDate+ENDDATE);
                    }
                    if(primaryL1DateMap.containsKey(keyForDate+STARTDATE)){
                        primaryOrderLineToUpdate.get(key).Apttus_Config2__StartDate__c = primaryL1DateMap.get(keyForDate+STARTDATE);
                    }
                    p1LineStartEndDtUpdateMap.put(key,primaryOrderLineToUpdate.get(key));
                }
                if(!p1LineStartEndDtUpdateMap.isEmpty()){
                    APTS_OrderUtils.stopOrderLineItemTrigger();
                    Database.SaveResult[] srList = Database.update(p1LineStartEndDtUpdateMap.values(), false);
                    APTS_BIRUtils.logError(null,srList,null,null,APTS_BIRUtils.BATCH,APTS_BIRUtils.ORDERLINEITEMOBJECTNAME,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,false);
                    APTS_OrderUtils.startOrderLineItemTrigger();
                }
                
                if(!orderHeaderUpdateMap.isEmpty()){
                    APTS_OrderUtils.stopOrderTrigger();
                    Database.SaveResult[] srList = Database.update(orderHeaderUpdateMap.values(), false);
                    APTS_BIRUtils.logError(null,srList,null,null,APTS_BIRUtils.BATCH,APTS_BIRUtils.ORDEROBJECTNAME,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,false);
                    APTS_OrderUtils.startOrderTrigger();
                }
                orderIdSet.addAll(adminOrderCreatedInEachChunk.values());
                Map<String, APTS_MuteCreditSAPSubmission__c> customSettingMap = APTS_MuteCreditSAPSubmission__c.getAll();
                if(customSettingMap.containsKey('Mute SAP Call') 
                    && customSettingMap.get('Mute SAP Call') != null){
                    muteSAPCall = customSettingMap.get('Mute SAP Call').APTS_ISSAPCallDisabled__c;
                }
                if(!orderIdSet.isEmpty()
                    && !muteSAPCall){
                    APTS_IntegrationLogForCreditBillingBatch sapSubmissionBatch = new APTS_IntegrationLogForCreditBillingBatch(orderIdSet,salesOrgToBeProcessed);
                    Database.executeBatch(sapSubmissionBatch,200);
                }
            }
            else{
                //system.debug('Inside Debug===>'+salesOrgToBeProcessed);
                APTS_CreditBillingBatchHelper.callRecurringBatchIfReqd(salesOrgToBeProcessed);
            }
        }catch(Exception e){APTS_BIRUtils.logError(null,null,null,e,APTS_BIRUtils.BATCH,CREATEADMINORDERFINISH,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,true);}
    }
}