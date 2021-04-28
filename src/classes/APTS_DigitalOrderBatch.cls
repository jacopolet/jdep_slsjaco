/*************************************************************
@Name: APTS_DigitalOrderBatch
@Author: Akanksha
@CreateDate: 11-09-2018
@Description: Cloned class 1 for Digital Order Batch
******************************************************************/

global class APTS_DigitalOrderBatch implements Database.Batchable<sObject>, Database.Stateful {
    private final static String STATUS_NEW = System.Label.APTS_New;
    private Set<Id> setNewOrderId;
    private Set<Id> setInterfaceId;
    private Map<String, APTS_DOEPIReqWrapper.EPIOrderLI> mapEPILineItems;


    public APTS_DigitalOrderBatch() {
        setNewOrderId = new Set<Id>();
        setInterfaceId = new Set<Id>();
        mapEPILineItems = new Map<String, APTS_DOEPIReqWrapper.EPIOrderLI>();
    }

    /** Method : start
    ** Description : Query locator which will query records with Status = New and ParentLog = NULL
    **/
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT id, APTS_SourceOrderNumber__c, APTS_Message__c, APTS_Status__c FROM APTS_Order_Interface_Log__c WHERE APTS_Status__c =: STATUS_NEW AND APTS_Parent_Log__c = NULL AND APTS_Source__c = \'Digital\'';
        return Database.getQueryLocator(query);
    }

    /** Method : execute
    ** Description : batch execute method would process EPI Interface Logs and create Digital Order
    **/
    global void execute(Database.BatchableContext BC, List<APTS_Order_Interface_Log__c> listEPILog) {
        Group queue;
        Map<Id, APTS_Order_Interface_Log__c> mapLogs;
        //v100 
         Map<String, ID> mapInterfacelog = new Map<String, ID>();

        try {
            //create map of interface log
            mapLogs = new Map<Id, APTS_Order_Interface_Log__c> (listEPILog);
            setInterfaceId.addAll(mapLogs.keySet());

            queue = APTS_DigitalOrderBatchHelper.getCSQueue();
            APTS_DigitalOrderBatchHelper.EPIOrderCreationResp oOrderResponse = APTS_DigitalOrderBatchHelper.createExternalOrderHeader(APTS_OrderConstants.ORDER_TYPE_DIGITAL, queue, listEPILog);
           //v100
            for(APTS_Order_Interface_Log__c olog:listEPILog){
         mapInterfacelog.put(olog.APTS_SourceOrderNumber__c, olog.Id);
            }
            //v100
            if (oOrderResponse != NULL && oOrderResponse.mapDigitalWrapper != NULL && oOrderResponse.mapLogIdNewOrders != NULL) {
                for (Apttus_Config2__Order__c oNewOrder : oOrderResponse.mapLogIdNewOrders.values()) {
                    setNewOrderId.add(oNewOrder.Id);
                }

                if (!setNewOrderId.isEmpty()) {
                    //setInterfaceId.addAll(oOrderResponse.mapLogIdNewOrders.keySet());
                    Map<String, APTS_DOEPIReqWrapper.EPIOrderLI> mapTemp = APTS_DigitalOrderBatchHelper.createCartAddProdcts(queue, oOrderResponse.mapDigitalWrapper, oOrderResponse.mapLogIdNewOrders,mapInterfacelog);
                    mapEPILineItems.putAll(mapTemp);

                }
            }

            if (Test.isRunningTest()){
                Decimal dc = 1/0;
            }

        } catch (Exception ex) {

            //v101
            List<APTS_Order_Interface_Log__c> listLog = APTS_DigitalOrderBatchHelper.getStatusInterfaceLog(queue, mapLogs.keySet());

            if (listLog != null && !listLog.isEmpty()) {
                Database.update(listLog, false);
            }

            APTS_CustomLogging.createErrorLog('Digital Order Creation Batch', 'Apex', 'Line # ' + ex.getLineNumber() + '_' + ex.getMessage() , 'Order', listLog[0].Id, 'OM', false, false, null, true);
        }
    }

    /** Method : finish
    ** Description : batch finish
    **/
    global void finish(Database.BatchableContext BC) {
        //if (!setNewOrderId.isEmpty()) {
            APTS_DigitalOrderFinalizeBatch batchClone2 = new APTS_DigitalOrderFinalizeBatch(setNewOrderId, setInterfaceId, mapEPILineItems);
            database.executeBatch(batchClone2, 1);
        /*} else {
            //v101
            //if no orders created, finalize batch will not update interface log status
            Group queue = APTS_DigitalOrderBatchHelper.getCSQueue();
            List<APTS_Order_Interface_Log__c> listLog = APTS_DigitalOrderBatchHelper.getStatusInterfaceLog(queue, setInterfaceId);

            if (listLog != null && !listLog.isEmpty()) {
                Database.update(listLog, false);
            }
        }*/
    }
}