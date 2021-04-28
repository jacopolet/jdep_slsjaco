global class APTS_SubmitTriangularOrderQueueable implements Queueable {

    private List<Apttus_Config2__Order__c> orderList = null;
    private static final String ACCOUNT_HIERARCHY = 'Account Hierarchy';
    private static final String ORDER = System.Label.APTS_Order;

    global APTS_SubmitTriangularOrderQueueable(List<Apttus_Config2__Order__c> submitOrderList) {

        this.orderList = submitOrderList;

       APTS_CustomLogging.createErrorLog('OM_TRIO_DEBUG', 'Apex', String.valueOf(submitOrderList) , 'APTS_SubmitTriangularOrderQueueable', null, 'OM', false, false, null, false);

    }

    global void execute(QueueableContext context) {

        try {
            List<sObject> objList = new List<sObject>();
            List<sObject> objOLIList = new List<sObject>();

            if (!orderList.isEmpty()) {
                List<Integration_Log__c> listIntegrationLog = new List<Integration_Log__c>();
                set<Id> orderIDsToSubmit = new set<Id>();
                for (Apttus_Config2__Order__c oOrder : orderList) {
                    //Create Integration Log
                    //v100 << ++ Added as part of the Duplicate Integration Log Issue
                    if ((oOrder.APTS_Status__c == 'Draft') && !(oOrder.APTS_Status__c == 'Submitted')) {

                        //v100 ++ >>
                        Integration_Log__c oIntegrationLog = new Integration_Log__c(Object_Id__c = oOrder.Id,
                                Object__c = ORDER, Integration_Status__c = INT_Constants.INITIAL,
                                Account__c = oOrder.Apttus_Config2__SoldToAccountId__c, Order__c = oOrder.Id);
                        listIntegrationLog.add(oIntegrationLog);
                        if (oOrder.Apttus_Config2__SoldToAccountId__r.SAP_Customer_Id__c == null && oOrder.Apttus_Config2__SoldToAccountId__r.RecordType.Name == 'Prospect' &&
                                oOrder.Apttus_Config2__SoldToAccountId__r.Parent_Valid_From__c == null && oOrder.Apttus_Config2__SoldToAccountId__r.Parent_Valid_To__c == null && oOrder.Apttus_Config2__SoldToAccountId__r.Parent_Change_Indicator__c != 'I') {
                            listIntegrationLog.add(new Integration_Log__c(Object_Id__c = oOrder.Apttus_Config2__SoldToAccountId__c, Object__c = ACCOUNT_HIERARCHY, Integration_Status__c = INT_Constants.INITIAL, Account__c = oOrder.Apttus_Config2__SoldToAccountId__c, Order__c = oOrder.Id));
                        }
                        oOrder.Apttus_Config2__Status__c = APTS_OrderConstants.PENDING;
                        oOrder.APTS_Status__c = APTS_OrderConstants.SUBMITTED;
                        objList.add(oOrder);
                        orderIDsToSubmit.add(oOrder.Id);

                    }
                }

                if (!listIntegrationLog.isEmpty()) {
                    Database.insert(listIntegrationLog, false);
                }
                Map<Id, Apttus_Config2__OrderLineItem__c> submittedOliMaptoOrder = APTS_OrderLineItemDAO.getAllOrderLineItems(orderIDsToSubmit);
                for (Apttus_Config2__OrderLineItem__c submittedOli : submittedOliMaptoOrder.Values()) {

                    submittedOli.Apttus_Config2__Status__c = APTS_OrderConstants.PENDING;
                    submittedOli.APTS_Status__c = APTS_OrderConstants.SUBMITTED;
                    objOLIList.add(submittedOli);
                     

                }
                if (objList != null) {
                    try {
                        APTS_OrderUtils.stopOrderTrigger();
                        APTS_OrderUtils.stopOrderLineItemTrigger();
                        APTS_TriangularInvoiceBatchHandler.updatesObject(objOLIList);
                        APTS_TriangularInvoiceBatchHandler.updatesObject(objList);                    
                        APTS_OrderUtils.startOrderLineItemTrigger();
                        APTS_OrderUtils.startOrderTrigger();
                        
                    } catch (Exception e) {APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', null, 'OM', false, false, null, true);}
                }

            }
        } catch (Exception e) {APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', null, 'OM', false, false, null, true);}

    }
}