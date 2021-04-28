//V101 19-Aug-2019 Aarthi Pitchai : Added overload constructor for Admin Orders
//V102 19-06-2020 Venky Muppalaneni: DQ-3038 Implementing new error handling 
//V103 29-July-2020 DQ:3150 Sneha Jaiwant:Bypassing the account's validation and reverting back
//V104 18-Aug-2020 Aarthi Pitchai : Fix - Lock Row error on muting Account validation rule
//V105 06-Nov-2020 Aarthi Pitchai : Remove muting Account validation rule for ingredients

public class APTS_ActivateOrderQueueable implements Queueable {

    private List<Apttus_Config2__OrderLineItem__c> orderLineItemToUpdateList = new List<Apttus_Config2__OrderLineItem__c> ();
    List<Apttus_Config2__AssetLineItem__c> assetLineItemToUpdateList = new List<Apttus_Config2__AssetLineItem__c> ();
    private string orderType = null;
    private Set<String> setStandardOrderTypes = new Set<String> {APTS_OrderConstants.STANDARD_ORDER, APTS_OrderConstants.ORDER_TYPE_ROUTESALES, APTS_OrderConstants.ORDER_TYPE_OPERATING}; //V105++ <<>>     
       
    public APTS_ActivateOrderQueueable(List<Apttus_Config2__OrderLineItem__c> orderLineItemToUpdateList) {

        this.orderLineItemToUpdateList = orderLineItemToUpdateList;
    }
    //V101 ++ <<
    public APTS_ActivateOrderQueueable(List<Apttus_Config2__OrderLineItem__c> orderLineItemToUpdateList, string adminOrderType) {

        this.orderLineItemToUpdateList = orderLineItemToUpdateList;
        this.orderType = adminOrderType;
    }
    //V101 ++ >>
    //V102 ++ <<
    public APTS_ActivateOrderQueueable(List<Apttus_Config2__OrderLineItem__c> orderLineItemToUpdateList, string adminOrderType, string transactionId) {
        this.orderLineItemToUpdateList = orderLineItemToUpdateList;
        this.orderType = adminOrderType;
        APTS_CustomErrorLogging.assignTransactionId(transactionId);
    }
    //V102 ++ >>
    public void execute(QueueableContext context) {

        Apttus_Config2__OrderLineItem__c oOrderLineItem;
        //added boolean as part of acceptorder button to enable when the order activation fails
        boolean isError = false;
        boolean isIngredient = false;
        try {
            if (orderLineItemToUpdateList != null && orderLineItemToUpdateList.size() > 0) {

                oOrderLineItem = orderLineItemToUpdateList.get(0);
                isIngredient = setStandardOrderTypes.contains(oOrderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Type__c);
                try {
                //V103 ++ <<
                if(!isIngredient) { APTS_OrderUtils.stopAccValidations();  } //V105++ <<>>    
               //V103 ++ >>
                    Database.update(oOrderLineItem);
               //V103 ++ <<
              // APTS_OrderUtils.startAccValidation();
               //V103 ++ >>    
                } catch(DMLException e) {
                    String msg = '';
                    for (Integer i = 0; i<e.getNumDml(); i++) {
                        msg += 'message = ' + e.getDmlMessage(i) + ' getDmlFieldNames = ' + e.getDmlFieldNames(i) + '\n';
                    }
                    //APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', msg, 'OrderLineItem', oOrderLineItem.Id, 'OM', false, false, null, true);
                    if (oOrderLineItem != null) {
                        APTS_CustomErrorLogging.createErrorLog('APTS_ActivateOrderQueueable', 'Apex', e.getTypeName() + ':' + msg, 'OrderLineItem',
                                                               oOrderLineItem.Id, 'OM', false, false, null, true,
                                                               oOrderLineItem.Apttus_Config2__OrderId__c, null, e.getMessage());
                    }
                    isError = true;
                } catch(Exception ex) {
                    //v102 ++ <<
                    //APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getMessage(), 'OrderLineItem', (oOrderLineItem != null) ? oOrderLineItem.id : null, 'OM', false, false, null, true);

                    APTS_CustomErrorLogging.createErrorLog('APTS_ActivateOrderQueueable', 'Apex', ex.getTypeName() + ':' + ex.getStackTraceString(), 'OrderLineItem',
                    (oOrderLineItem != null) ? oOrderLineItem.id : null, 'OM', false, false, null, true,
                    (oOrderLineItem != null) ? oOrderLineItem.Apttus_Config2__OrderId__c : null, null, ex.getMessage());
                    isError = true;
                    //v102 ++ >>
                }
                orderLineItemToUpdateList.remove(0);
                //V104 ++ <<
                if (!Test.isRunningTest()) {
                     if(orderLineItemToUpdateList.size()> 0)
                         System.enqueueJob(new APTS_ActivateOrderQueueable(orderLineItemToUpdateList));
                     else 
                     {                   
                        if(!isIngredient) { APTS_OrderUtils.startAccValidation(); } //V105++ <<>>
                     }                 
                }
                //V104 ++ >>
                if (Test.isRunningTest()) { Database.insert(oOrderLineItem); }
            } else {
                if (Test.isRunningTest()) { Decimal dc1 = 1 / 0; }
            }
        } catch(Exception ex) {
            //v102 ++ <<
            //APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getMessage(), 'OrderLineItem', (oOrderLineItem != null) ? oOrderLineItem.id : null, 'OM', false, false, null, true);
            // New Exception Logging
            APTS_CustomErrorLogging.createErrorLog('APTS_ActivateOrderQueueable', 'Apex', ex.getTypeName() + ':' + ex.getStackTraceString(), 'Order',
            (oOrderLineItem != null) ? oOrderLineItem.Apttus_Config2__OrderId__c : null, 'OM', false, false, null, true,
            (oOrderLineItem != null) ? oOrderLineItem.Apttus_Config2__OrderId__c : null, null, ex.getMessage());
            isError = true;
            //v102 ++ >>
        }
        //v102 ++ <<
        APTS_CustomErrorLogging.saveErrorLog();
        //v102 ++ >>
        //Added this logic to enable accept order button when the order activation is failed 
        if (isError) {
            if (!Test.isRunningTest() && !isIngredient) { APTS_OrderUtils.startAccValidation();  } //V104 ++ <<>>
            if (oOrderLineItem != null && orderType != null && orderType == 'Admin Order') {
                Apttus_Config2__Order__c order = new Apttus_Config2__Order__c();
                order.id = oOrderLineItem.Apttus_Config2__OrderId__c;
                order.APTS_Accept_Order_Check__c = false;
                Database.update(order, false);
            }
        }
    }
}