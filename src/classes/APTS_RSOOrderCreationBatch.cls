/*************************************************************
@Name: APTS_RSOOrderCreationBatch
@Author: Neev Shah
@CreateDate: 29-05-2018
@Description: Batch job to process RSO Order one by one
******************************************************************/
//v100 22-10-2018 Akanksha: code changes for defect# 20299
//v101 22-10-2018 Aarthi: code changes for defect# 20299 based on Static code analysis - P1 violations found on deployment
//v102 26-10-2018 Aarthi: Modified the code to resolve an issue related to SAPOrderType  for defect# 20705
//v103 27-10-2018 Aarthi: Added the logic to set the requested delivery date based on Country settings whenever the date is not sent from MobileApp - defect# 20696
//v104 30-10-2018 Mahesh: Added logic to default the Order Reason - Defect #20714 resolution
//v105 30-10-2018 Rajesh : Added this logic set to UOM defaulted  value from Lineitem for defect# 20684
//v106 31-10-2018 Added: Added logic to set the correct API Name of Selling UOM from MobileApp for defect# 20924
//v107 11-03-2019 Akanksha: Changed logic for CR2241 (Defect# 5570) - Removing ATP Check for warehouse
//v108 28-Aug-2020 Added extra parameter to the creteerrorlog  

global class APTS_RSOOrderCreationBatch implements Database.Batchable<sObject>, Database.Stateful {
    private final static String STATUS_NEW = 'New';
    private final static String SOURCE_RSO = 'RSOApp';
    private final static String SOURCE_TYPE_ATTACH = 'Attachment';

    private Map<Id, Apttus_Config2__Order__c> mapLogIdNewOrder;
    private Map<String, APTS_DOEPIReqWrapper.EPIOrderLI> mapEPILineItems;
    private List<APTS_Order_Error_Log__c> listErrorLog;
    


    public APTS_RSOOrderCreationBatch() {
        mapLogIdNewOrder = new Map<Id, Apttus_Config2__Order__c>();
        mapEPILineItems = new Map<String, APTS_DOEPIReqWrapper.EPIOrderLI>();
        listErrorLog = new List<APTS_Order_Error_Log__c>();
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        //Query only RSOAPP Interface logs records with 'New' Status
        String query = 'SELECT id, APTS_SourceOrderNumber__c, APTS_Message__c, APTS_Status__c FROM APTS_Order_Interface_Log__c WHERE APTS_Status__c = :STATUS_NEW AND APTS_Source__c = :SOURCE_RSO AND APTS_Parent_Log__c = NULL AND APTS_Type__c <> :SOURCE_TYPE_ATTACH';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<APTS_Order_Interface_Log__c> listEPILog) {
        listErrorLog = new List<APTS_Order_Error_Log__c>();
        Group queue;
        //v108
        Map<String,Id> mapInterfacelog = new Map<String,Id>();
         for(APTS_Order_Interface_Log__c olog:listEPILog){
         mapInterfacelog.put(olog.APTS_SourceOrderNumber__c, olog.Id);
            }
         //v108

        try {
            queue = APTS_DigitalOrderBatchHelper.getCSQueue();

            //Create Order Header
            APTS_DigitalOrderBatchHelper.EPIOrderCreationResp oOrderResponse = APTS_DigitalOrderBatchHelper.createExternalOrderHeader('RSO', queue, listEPILog);
            system.debug('@@@@'+oOrderResponse.mapDigitalWrapper);


            if (oOrderResponse != NULL && oOrderResponse.mapDigitalWrapper != NULL && oOrderResponse.mapLogIdNewOrders != NULL && !oOrderResponse.mapLogIdNewOrders.isEmpty()) {
                mapLogIdNewOrder.putAll(oOrderResponse.mapLogIdNewOrders);
                system.debug('$$$$'+mapLogIdNewOrder);
                //Create Cart, add Product, apply constraint rules, reprice, save configuration
                Map<String, APTS_DOEPIReqWrapper.EPIOrderLI> mapTemp = APTS_DigitalOrderBatchHelper.createCartAddProdcts(queue, oOrderResponse.mapDigitalWrapper, oOrderResponse.mapLogIdNewOrders,mapInterfacelog);
                mapEPILineItems.putAll(mapTemp);
            }

        } catch (Exception ex) {

            APTS_Order_Error_Log__c oErrLog = APTS_DigitalOrderBatchHelper.createErrorLog(ex.getStackTraceString(), listEPILog[0].APTS_SourceOrderNumber__c, NULL, NULL, NULL,listEPILog[0].id, queue);
            if (oErrLog != null) {
                listErrorLog.add(oErrLog);
            }
        }

    }

    global void finish(Database.BatchableContext BC) {
        Map<Id, Id> mapOrderVanWarehouse = new Map<Id, Id>();
        Map<String, Id> mapSourceNum = new Map<String, Id>();

        try {

            if (mapLogIdNewOrder != NULL && !mapLogIdNewOrder.isEmpty()) {
                for (Id logId : mapLogIdNewOrder.keySet()) {
                    Apttus_Config2__Order__c oNewOrder = mapLogIdNewOrder.get(logId);

                    if (oNewOrder != NULL) {
                        mapSourceNum.put(oNewOrder.APTS_Source_Order_Number__c, logId);
                        //v107 ++ <<
                        mapOrderVanWarehouse.put(logId, oNewOrder.Id);
                        //v107 ++ >>
                    }
                }

                //upload attachment
                Map<Id, APTS_Order_Interface_Log__c> mapInterfacelog = new Map<Id, APTS_Order_Interface_Log__c>([SELECT ID, APTS_SourceOrderNumber__c, APTS_Status__c FROM APTS_Order_Interface_Log__c WHERE APTS_SourceOrderNumber__c = :mapSourceNum.keySet() AND APTS_Status__c = : STATUS_NEW AND APTS_Type__c = 'Attachment']);
                if (!mapInterfacelog.isEmpty()) {
                    List<Attachment> insertAttList = new List<Attachment>();

                    for (Attachment a : [SELECT id, name, body, parentId  FROM Attachment WHERE parentId IN :mapInterfacelog.keySet()]) {
                        APTS_Order_Interface_Log__c olog = mapInterfacelog.get(a.parentId);
                        Id logId = olog != null ? mapSourceNum.get(olog.APTS_SourceOrderNumber__c) : null;
                        Id orderID = logId != null && mapLogIdNewOrder.containsKey(logId) ? mapLogIdNewOrder.get(logId).Id : null;
                        System.debug('orderID = ' + orderID);

                        if (orderID != NULL) {
                            Attachment att = new Attachment(name = a.name, body = a.body, parentid = orderID);
                            insertAttList.add(att);
                        }
                    }

                    if (!insertAttList.isEmpty()) {
                        insert insertAttList;
                    }

                    for (APTS_Order_Interface_Log__c olog : mapInterfacelog.values()) {
                        olog.APTS_Status__c = 'Completed';
                    }

                    Database.update(mapInterfacelog.values(), false);
                }
                //v107 ++ <<
                //if Order from Van and wareshouse than Finalize Cart
                if (!mapOrderVanWarehouse.isEmpty()) {
                    Set<Id> newOrderId = new Set<Id>();
                    newOrderId.addAll(mapOrderVanWarehouse.values());
                    APTS_RSOOrderFinalizeBatch batchClone2 = new APTS_RSOOrderFinalizeBatch(newOrderId, mapOrderVanWarehouse.keySet(), mapEPILineItems);
                    database.executeBatch(batchClone2, 1);
                }
                //v107 ++ >>


            }
        } catch (Exception ex) {

        }
    }
}