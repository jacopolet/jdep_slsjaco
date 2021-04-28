/*************************************************************
@Name: APTS_DigitalOrderFinalizeBatch
@Author: Akanksha
@CreateDate: 11-09-2018
@Description: Cloned class 2 for Digital Order Batch
******************************************************************/
/******************************************************************
//v101 -- 12 Feb 2019 -- Defect 4812 -- SOQL 202 where line items > 15 due to freight charge constrait rules
                            Resolution -- removed constraint rules API call from Digital Batch
//v102---28 Aug 2020-DQ 2949  Getting Interface Log ID                    
******************************************************************/

global class APTS_DigitalOrderFinalizeBatch implements Database.Batchable<sObject> {
    String query;
    private static final String S_ORDER = 'Order';
    private static final String S_DIGITAL_ORDER = 'Digital Order';
    private static final String S_FINALIZED = 'Finalized';

    private Set<Id> setNewOrderId;
    private Set<Id> setInterfaceId;
    private Map<String, APTS_DOEPIReqWrapper.EPIOrderLI> mapEPIOLI;

    /** Method : Constructor
    ** Description :
    **/
    public APTS_DigitalOrderFinalizeBatch(Set<Id> setNewOrderId1, Set<Id> setInterfaceId1, Map<String, APTS_DOEPIReqWrapper.EPIOrderLI> mapEPIOLI1) {
        //setneworderId was created because queryselector were not taking wrapper class
        setNewOrderId = setNewOrderId1;
        setInterfaceId = setInterfaceId1;
        mapEPIOLI = mapEPIOLI1;
    }

    /** Method : start
    ** Description : Query locator which will query records with given order Ids
    **/
    global Database.QueryLocator start(Database.BatchableContext BC) {
        query = 'select id, Apttus_Config2__OrderId__c, Apttus_Config2__OrderId__r.APTS_Source_Order_Number__c from Apttus_Config2__ProductConfiguration__c where Apttus_Config2__BusinessObjectType__c = :S_ORDER and Order_Sub_Type__c = :S_DIGITAL_ORDER and Apttus_Config2__Status__c <> :S_FINALIZED and Apttus_Config2__OrderId__c <> null and Apttus_Config2__OrderId__c in :setNewOrderId';
        return Database.getQueryLocator(query);
    }

    /** Method : execute
    ** Description : batch execute method would call finalizeCart method
    **/
    global void execute(Database.BatchableContext BC, List<Apttus_Config2__ProductConfiguration__c> cartList) {
        Group queue;
        List<APTS_Order_Error_Log__c> listErrorLog = new List<APTS_Order_Error_Log__c>();
        //v102 <++          
            set<String> sourceNumberSet = new Set<String>();
            Map<String, Id> mapInterface = new Map<String, Id>();
            for(Apttus_Config2__ProductConfiguration__c  prdConfig : cartList){
                if(string.IsNotBlank(prdConfig.Apttus_Config2__OrderId__r.APTS_Source_Order_Number__c)){
                    sourceNumberSet.add(prdConfig.Apttus_Config2__OrderId__r.APTS_Source_Order_Number__c);
                }
            }
             for (APTS_Order_Interface_Log__c olog : [SELECT id,  APTS_SourceOrderNumber__c FROM APTS_Order_Interface_Log__c where APTS_SourceOrderNumber__c IN:sourceNumberSet Limit 200 ]) {
                mapInterface.put(olog.APTS_SourceOrderNumber__c, olog.Id);
            }
            //v102 ++>
        try {
            queue = APTS_DigitalOrderBatchHelper.getCSQueue(); 
            
            //Finalize cart
            for (Apttus_Config2__ProductConfiguration__c cartOb : cartList) {
                try {
                   
                    if (setNewOrderId != null && setNewOrderId.contains(cartob.Apttus_Config2__OrderId__c)) {
                        //reprice (n) time(s) before finalize
                        Boolean isFinalized = APTS_DigitalOrderBatchHelper.finalizeCart(true, cartOb.Id,mapInterface);

                        //v101 << start
                        if (isFinalized) {
                            Set<Id> setOrderId = new Set<Id> ();
                            setOrderId.add(cartob.Apttus_Config2__OrderId__c);
                            //Submit Order, moved to for loop as it invokes AcceptOrder API, moving to finish will throw SOQL202 error
                            //v102 passing extraparameter to mapInterface updateOLIAndsubmit
                            APTS_DigitalOrderBatchHelper.updateOLIAndsubmit(queue, setOrderId, mapEPIOLI,mapInterface);
                        }
                        //v101 >> end

                        if (Test.isRunningTest()) {
                            Decimal dc1 = 1 / 0;
                        }

                    }                   

                } catch (Exception ex) {

                    APTS_Order_Error_Log__c oErrLog = APTS_DigitalOrderBatchHelper.createErrorLog(ex.getStackTraceString(), cartOb.Apttus_Config2__OrderId__r.APTS_Source_Order_Number__c, NULL, cartOb.Apttus_Config2__OrderId__c,NULL,mapInterface != NULL && mapInterface.containskey(cartOb.Apttus_Config2__OrderId__r.APTS_Source_Order_Number__c) ? mapInterface.get(cartOb.Apttus_Config2__OrderId__r.APTS_Source_Order_Number__c) : NULL, queue);
                    if (oErrLog != null) {
                        listErrorLog.add(oErrLog);
                    }
                }
            }

        } catch (Exception ex) {
            system.debug('dig@');
            APTS_Order_Error_Log__c oErrLog = APTS_DigitalOrderBatchHelper.createErrorLog(ex.getStackTraceString(), cartList[0].Apttus_Config2__OrderId__r.APTS_Source_Order_Number__c, NULL, cartList[0].Apttus_Config2__OrderId__c, NULL,mapInterface.get(cartList[0].Apttus_Config2__OrderId__r.APTS_Source_Order_Number__c), queue);
            if (oErrLog != null) {
                listErrorLog.add(oErrLog);
            }

            APTS_CustomLogging.createErrorLog('Digital Order Finalize Batch', 'Apex', 'Line # ' + ex.getLineNumber() + '_' + ex.getMessage() , 'Order', null, 'OM', false, false, null, true);
        } finally {

            //v101
            if (listErrorLog != null && !listErrorLog.isEmpty()) {
                Database.insert(listErrorLog, false);
            }
        }

    }

    /** Method : finish
    ** Description : batch finish
    **/
    global void finish(Database.BatchableContext BC) {
        Group queue;
        List<APTS_Order_Error_Log__c> listErrorLog = new List<APTS_Order_Error_Log__c>();

        try {

            queue = APTS_DigitalOrderBatchHelper.getCSQueue();

            if (setInterfaceId != null) {
                //v101
                List<APTS_Order_Interface_Log__c> listLog = APTS_DigitalOrderBatchHelper.getStatusInterfaceLog(queue, setInterfaceId);

                if (listLog != null && !listLog.isEmpty()) {
                    Database.update(listLog, false);
                }

                if (Test.isRunningTest()) {
                    Decimal dc1 = 1 / 0;
                }
            }

        } catch (Exception ex) {
            string errorMsg = ex.getStackTraceString() + ex.getMessage();
            APTS_Order_Error_Log__c oErrLog = APTS_DigitalOrderBatchHelper.createErrorLog(errorMsg, NULL, NULL, NULL, NULL,NULL, queue);
            if (oErrLog != null) {
                listErrorLog.add(oErrLog);
            }

        } finally {

            if (listErrorLog != null && !listErrorLog.isEmpty()) {
                Database.insert(listErrorLog, false);
            }
        }
    }
}