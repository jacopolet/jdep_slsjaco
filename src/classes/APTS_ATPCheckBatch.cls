global class APTS_ATPCheckBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
    private static final String S_ORDER = 'Order';
    private static final String S_FINALIZED = 'Finalized';
    private static final Set<String> S_RSO_ORDER = new Set<String> {'Route Sales Order', 'Operating Order'};

    private Set<Id> setNewOrderId;
    private Set<Id> setInterfaceId;
    private Map<String, APTS_DOEPIReqWrapper.EPIOrderLI> mapEPIOLI;

    public class testException extends Exception {}

    public APTS_ATPCheckBatch() {}

    public APTS_ATPCheckBatch(Set<Id> setNewOrderIdTmp, Set<Id> setInterfaceIdTmp, Map<String, APTS_DOEPIReqWrapper.EPIOrderLI> mapEPIOLITmp) {
        setNewOrderId = setNewOrderIdTmp;
        setInterfaceId = setInterfaceIdTmp;
        mapEPIOLI = mapEPIOLITmp;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, Apttus_Config2__OrderId__c FROM Apttus_Config2__ProductConfiguration__c WHERE Apttus_Config2__BusinessObjectType__c = :S_ORDER and APTS_Order_Type__c IN :S_RSO_ORDER and Apttus_Config2__Status__c <> :S_FINALIZED AND Apttus_Config2__OrderId__c IN :setNewOrderId';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Apttus_Config2__ProductConfiguration__c> listPrevCart) {
        Boolean isATPPass;
        Group queue;
        Id orderID, cartId;
        APTS_ATPResultWrapper oATPResultWrapper;
        Set<Id> cartIdATPPass = new Set<id>();
        List<Apttus_Config2__LineItem__c> lineItemsToUpdateList = new List<Apttus_Config2__LineItem__c>();
        List<Apttus_Config2__TaxBreakup__c> taxBreakupsToInsertList = new List<Apttus_Config2__TaxBreakup__c>();
        List<APTS_Order_Freight_Data__c> freightDataToInsertList = new List<APTS_Order_Freight_Data__c>();
        List<APTS_Order_Error_Log__c> listErrorLog = new List<APTS_Order_Error_Log__c>();

        try {
            queue = APTS_DigitalOrderBatchHelper.getCSQueue();

            /*if (Test.isRunningTest()) {
                oATPResultWrapper = new APTS_ATPResultWrapper();
                oATPResultWrapper.lineItemsToUpdateList = [SELECT Id, APTS_ATP_Cleared__c FROM Apttus_Config2__LineItem__c];
            }*/

            for (Apttus_Config2__ProductConfiguration__c prevCart : listPrevCart) {
                isATPPass = false;
                cartId = prevCart.Id;
                orderID = prevCart.Apttus_Config2__OrderId__c;

                try {
                    oATPResultWrapper = APTS_OrderWSUtils.doATPCheck(orderID, cartId);
                } catch (exception e) {
                    APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', orderID, 'OM', false, true, null, true);
                }

                if (oATPResultWrapper != null) {
                    if (oATPResultWrapper.lineItemsToUpdateList != null && !oATPResultWrapper.lineItemsToUpdateList.isEmpty()) {
                        lineItemsToUpdateList.addAll(oATPResultWrapper.lineItemsToUpdateList);

                        isATPPass = true;
                        for (Apttus_Config2__LineItem__c oLineItem : oATPResultWrapper.lineItemsToUpdateList) {
                            isATPPass = oLineItem.APTS_ATP_Cleared__c == null || !oLineItem.APTS_ATP_Cleared__c ? false : isATPPass;
                        }
                    }

                    if (!oATPResultWrapper.taxBreakupsToInsertList.isEmpty()) {
                        taxBreakupsToInsertList.addAll(oATPResultWrapper.taxBreakupsToInsertList);
                    }

                    if (!oATPResultWrapper.freightDataToInsertList.isEmpty()) {
                        freightDataToInsertList.addAll(oATPResultWrapper.freightDataToInsertList);
                    }
                }

                if (isATPPass) {
                    cartIdATPPass.add(cartId);
                }
            }

            if (!lineItemsToUpdateList.isEmpty()) {
                Database.update(lineItemsToUpdateList);
            }

            if (!taxBreakupsToInsertList.isEmpty()) {
                Database.insert(taxBreakupsToInsertList);
            }

            if (!freightDataToInsertList.isEmpty()) {
                Database.insert(freightDataToInsertList);
            }

            Set<Id> setFinalizedOrder = new Set<Id>();
            List<Apttus_Config2__Order__c> listOrderToCSQue = new List<Apttus_Config2__Order__c>();

            for (Apttus_Config2__ProductConfiguration__c prevCart : listPrevCart) {
                system.debug('Inside Cart');

                cartId = prevCart.Id;
                orderID = prevCart.Apttus_Config2__OrderId__c;

                //IF ATP pass, than finalize cart
                if (cartIdATPPass.contains(cartId)) {
                    system.debug('ATP Pass');

                    //Finalize
                    APTS_OrderUtils.finalizeCart(cartId);
                    //Syncronize
                    Boolean isSuccess = APTS_OrderUtils.syncCart(cartId);

                    if (isSuccess) {
                        setFinalizedOrder.add(orderID);
                    }
                } else {
                    system.debug('ATP failed');

                    //IF ATP fails, than assign to CS Queue
                    Apttus_Config2__Order__c order = new Apttus_Config2__Order__c(Id = orderID, ownerId = queue.Id);
                    listOrderToCSQue.add(order);

                    APTS_Order_Error_Log__c oErrLog = APTS_DigitalOrderBatchHelper.createErrorLog('ATP Check failed, please reconfigure cart for more details', orderID, NULL, orderID, NULL, queue);
                    if (oErrLog != null) {
                        listErrorLog.add(oErrLog);
                    }
                }
            }

            //update order line items after finalizing cart
            if (!setFinalizedOrder.isEmpty()) {
                system.debug('after finalize code');
                APTS_DigitalOrderBatchHelper.updateOLIAndsubmit(queue, setFinalizedOrder, mapEPIOLI);
            }

            //assign order to CS-Queue
            if (!listOrderToCSQue.isEmpty()) {
                update listOrderToCSQue;
            }

            if (Test.isRunningTest()) {
                throw new testException('Test');
            }

        } catch (Exception ex) {
            String strMsg = 'Exception on Line Number = ' + ex.getLineNumber() + ' StraceTrace :: ' + ex.getStackTraceString() + ' error msg = ' + ex.getMessage();
            APTS_Order_Error_Log__c oErrLog = APTS_DigitalOrderBatchHelper.createErrorLog(strMsg, orderID, NULL, orderID, NULL, queue);
            if (oErrLog != null) {
                listErrorLog.add(oErrLog);
            }
        } finally {

            if (listErrorLog != null && !listErrorLog.isEmpty()) {
                Database.insert(listErrorLog, false);
            }
        }
    }

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

                //Submit Order
                //APTS_DigitalOrderBatchHelper.updateOLIAndsubmit(queue, setNewOrderId, mapEPIOLI);
            }
            if (Test.isRunningTest()) {
                throw new testException('Test');
            }

        } catch (Exception ex) {
            string errorMsg = ex.getStackTraceString() + ex.getMessage();
            APTS_Order_Error_Log__c oErrLog = APTS_DigitalOrderBatchHelper.createErrorLog(errorMsg, NULL, NULL, NULL, NULL, queue);
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