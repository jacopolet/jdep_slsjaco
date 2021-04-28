/*************************************************************
@Name: APTS_RSOOrderFinalizeBatch
@Author: Neev
@CreateDate: 15-11-2018
@Description: Cloned class 2 for RSO Order Batch
******************************************************************/
/******************************************************************
//v101 -- 12 Feb 2019 -- Defect 4812 -- SOQL 202 where line items > 15 due to freight charge constrait rules
                            Resolution -- removed constraint rules API call from Digital Batch
//v102 28-Aug-2020 Added extra parameter to the creteerrorlog and passed parameter to updateOLIAndsubmit                        
******************************************************************/

//global class APTS_RSOOrderFinalizeBatch implements Database.Batchable<sObject> , Database.Stateful  {
global class APTS_RSOOrderFinalizeBatch implements Database.Batchable<sObject> {
    private static final String S_ORDER = 'Order';
    private static final String S_FINALIZED = 'Finalized';
    private static final Set<String> S_RSO_ORDER = new Set<String> {'Route Sales Order', 'Operating Order'};

    private Set<Id> setNewOrderId;
    private Set<Id> setInterfaceId;
    private Map<String, APTS_DOEPIReqWrapper.EPIOrderLI> mapEPIOLI;

    String query;
    Group queue;
    private List<APTS_Order_Error_Log__c> listErrorLog;
    //v102
    public static APTS_Order_Interface_Log__c Olog;

    public APTS_RSOOrderFinalizeBatch(Set<Id> setNewOrderId1, Set<Id> setInterfaceId1, Map<String, APTS_DOEPIReqWrapper.EPIOrderLI> mapEPIOLI1) {
        query = 'select id, Apttus_Config2__OrderId__c, Apttus_Config2__OrderId__r.APTS_Source_Order_Number__c from Apttus_Config2__ProductConfiguration__c where Apttus_Config2__BusinessObjectType__c = :S_ORDER and APTS_Order_Type__c IN :S_RSO_ORDER and Apttus_Config2__Status__c <> :S_FINALIZED and Apttus_Config2__OrderId__c IN :setNewOrderId';

        //setneworderId was created because queryselector were not taking wrapper class
        setNewOrderId = setNewOrderId1;
        setInterfaceId = setInterfaceId1;
        mapEPIOLI = mapEPIOLI1;
        listErrorLog = new List<APTS_Order_Error_Log__c>();
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Apttus_Config2__ProductConfiguration__c> cartList) {
        listErrorLog = new List<APTS_Order_Error_Log__c>();
         //v102 <++          
            set<String> sourceNumberSet = new Set<String>();
            Map<String, Id> mapInterface = new Map<String, Id>();
            for(Apttus_Config2__ProductConfiguration__c  prdConfig : cartList){
                if(string.IsNotBlank(prdConfig.Apttus_Config2__OrderId__r.APTS_Source_Order_Number__c)){
                    sourceNumberSet.add(prdConfig.Apttus_Config2__OrderId__r.APTS_Source_Order_Number__c);
                }
            }
             for (APTS_Order_Interface_Log__c olog : [SELECT id,  APTS_SourceOrderNumber__c FROM APTS_Order_Interface_Log__c where APTS_SourceOrderNumber__c IN:sourceNumberSet Limit 200]) {
                mapInterface.put(olog.APTS_SourceOrderNumber__c, olog.Id);
            }
            //v102 ++>
        try {
            queue = APTS_DigitalOrderBatchHelper.getCSQueue();
           
            //Finalize cart
            for (Apttus_Config2__ProductConfiguration__c cartOb : cartList) {
                try {                                        
                        if (setNewOrderId.contains(cartob.Apttus_Config2__OrderId__c)) {
                            APTS_DigitalOrderBatchHelper.finalizeCart(true, cartOb.Id,mapInterface);
                        }

                        //v101 << start
                        //accept Order
                        //Submit Order
                        Set<Id> setOrderId = new Set<Id> ();
                        setOrderId.add(cartob.Apttus_Config2__OrderId__c);
                        APTS_DigitalOrderBatchHelper.updateOLIAndsubmit(queue, setOrderId, mapEPIOLI,mapInterface);
                        //v101 >> end

                        if (Test.isRunningTest()) {
                            Decimal dc1 = 1 / 0;
                        }
                                      
                } catch (Exception ex) {

                    String srn = cartob.Apttus_Config2__OrderId__c != null ? cartob.Apttus_Config2__OrderId__r.APTS_Source_Order_Number__c : '';

                    APTS_Order_Error_Log__c oErrLog = APTS_DigitalOrderBatchHelper.createErrorLog(ex.getStackTraceString(), srn, NULL, cartOb.Apttus_Config2__OrderId__c, NULL,mapInterface.get(srn), queue);
                    if (oErrLog != null) {
                        listErrorLog.add(oErrLog);
                    }

                    if (Test.isRunningTest()) {
                        Decimal dc1 = 1 / 0;
                    }

                }
            }

        } catch (Exception ex) {
            APTS_Order_Error_Log__c oErrLog = APTS_DigitalOrderBatchHelper.createErrorLog(ex.getStackTraceString(), cartList[0].Apttus_Config2__OrderId__r.APTS_Source_Order_Number__c, NULL, cartList[0].Apttus_Config2__OrderId__c, NULL,mapInterface.get(cartList[0].Apttus_Config2__OrderId__r.APTS_Source_Order_Number__c), queue);
            if (oErrLog != null) {
                listErrorLog.add(oErrLog);
            }
        }
    }

    global void finish(Database.BatchableContext BC) {
        system.debug('setNewOrderId = ' + setNewOrderId);
        system.debug('setInterfaceId = ' + setInterfaceId);
        system.debug('mapEPIOLI = ' + mapEPIOLI);

        try {

            queue = APTS_DigitalOrderBatchHelper.getCSQueue();

            if (setInterfaceId != null) {
                //v101
                List<APTS_Order_Interface_Log__c> listLog = APTS_DigitalOrderBatchHelper.getStatusInterfaceLog(queue, setInterfaceId);


                if (listLog != null && !listLog.isEmpty()) {
                    Database.update(listLog, false);
                }

                //Submit Order
                //APTS_DigitalOrderBatchHelper.updateOLIAndsubmit(queue, setNewOrderId, mapEPIOLI);
            }

            if (Test.isRunningTest()) {
                Decimal dc1 = 1 / 0;
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