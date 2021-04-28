/*************************************************************
@Name: APTS_RepriceFinalizationQueue
@Author: Neev Shah
@CreateDate: 18-01-2018
@Description: Reprice and Finalize Order
@UsedBy: ReturnOrder Apex Class
******************************************************************/
/******************************************************************
//v101 -- 18 Feb 2019 -- Defect 5088 -- SOQL 202 where line items > 15
//v102 -- 14 Jun 2019 -- Defect 24638 -- Amend partial fulfillment issue
//v103 -- 10 Jul 2020 -- Aarthi Pitchai - DQ-1682 -- Partial cancel Apttus upgrade issue
//v104---28 Aug 2020-----Sneha Jaiwant  -DQ2949 Added extra parameter to the updateOLIAndsubmit
******************************************************************/

public with sharing class APTS_RepriceFinalizationQueue implements Queueable {
    private static final String EMAIL = System.Label.APTS_Email;
    private static final String STANDARD_RETURN = System.Label.APTS_Standard_Return;
    private static final String DE_INSTALLATION = System.Label.APTS_De_installation;
    private static final String INTERNAL_MOVEMENT = System.Label.APTS_Internal_Movement;
    private static final String EXTERNAL_MOVEMENT = System.Label.APTS_External_Movement;
    private static final String TECHNICAL_SWAP = System.Label.APTS_Technical_Swap;
    private static final String COMMERCIAL_SWAP = System.Label.APTS_Commercial_Swap;
    private static final String XB13 = 'XB13';
    private static final String DIGITAL = 'Digital';
    private static final String RSO = 'RSO';
    private static final String FINALIZE = 'Finalize';
    private static final String SUBMIT = 'Submit';
    private static final String PARTIALORDER = 'PartialOrder';


    private Id cartId;
    private Id orderId;
    private Boolean isOrderNeedAccept;
    private String sOrderType;
    private String sCartAction;
    private Map<String, APTS_DOEPIReqWrapper.EPIOrderLI> mapEPIOLI;

    public APTS_RepriceFinalizationQueue(Id cartId) {
        this.cartId = cartId;
    }

    public APTS_RepriceFinalizationQueue(Id cartId, Id orderId, Boolean isOrderNeedAccept) {
        this.cartId = cartId;
        this.orderId = orderId;
        this.isOrderNeedAccept = isOrderNeedAccept;
    }

    //v101 start
    //constructor created for Batch Job SOQL issue
    public APTS_RepriceFinalizationQueue(Id cartId, String sOrderType, String sCartAction) {
        this.cartId = cartId;
        this.sOrderType = sOrderType;
        this.sCartAction = sCartAction;
        this.mapEPIOLI = mapEPIOLI;
    }
    //v101 end

    public void execute(QueueableContext context) {
        try {
             //v104 <++          
            set<String> sourceNumberSet = new Set<String>();
            Map<String, Id> mapInterface = new Map<String, Id>();
            for(Apttus_Config2__ProductConfiguration__c  prdConfig : [SELECT id, Apttus_Config2__OrderId__c,Apttus_Config2__OrderId__r.APTS_Source_Order_Number__c FROM Apttus_Config2__ProductConfiguration__c
                                    WHERE Id = :cartId]){
                if(string.IsNotBlank(prdConfig.Apttus_Config2__OrderId__r.APTS_Source_Order_Number__c)){
                    sourceNumberSet.add(prdConfig.Apttus_Config2__OrderId__r.APTS_Source_Order_Number__c);
                }
            }
             for (APTS_Order_Interface_Log__c olog : [SELECT id,  APTS_SourceOrderNumber__c FROM APTS_Order_Interface_Log__c where APTS_SourceOrderNumber__c IN:sourceNumberSet Limit 200]) {
                mapInterface.put(olog.APTS_SourceOrderNumber__c, olog.Id);
            }
            //v104 ++>
            if (String.isNotBlank(cartId)) {
           

                //v101 start
                if (DIGITAL.equalsIgnoreCase(sOrderType) || RSO.equalsIgnoreCase(sOrderType) || PARTIALORDER.equalsIgnoreCase(sOrderType)) {

                    if (FINALIZE.equalsIgnoreCase(sCartAction)) {
                        //if price is complete than finalize cart
                        APTS_DigitalOrderBatchHelper.finalizeCart(false, cartId,mapInterface);

                        //V102 ++ <<
                        if (PARTIALORDER.equalsIgnoreCase(sOrderType)) {

                            Set<Id> setOrders = new Set<Id> ();

                            for (Apttus_Config2__ProductConfiguration__c cartObj : [SELECT id, Apttus_Config2__OrderId__c FROM Apttus_Config2__ProductConfiguration__c
                                    WHERE Id = :cartId]) {
                                setOrders.add(cartObj.Apttus_Config2__OrderId__c);
                            }

                            // update ready for activation date on Order
                            if (!setOrders.isEmpty()) {
                               APTS_AmendPartialOrderBatchHelper.fulfillAmendedOrder(setOrders);
                               // System.enqueueJob(new APTS_AmendPartialOrderQueueable(setOrders)); //V103 ++ <<>>
                            }
                        } else {
                            //invoke submit order in seperate queue to avoid SOQL
                            System.enqueueJob(new APTS_RepriceFinalizationQueue(cartId, sOrderType, SUBMIT));
                        } //V102 ++ >>
                    } else if (SUBMIT.equalsIgnoreCase(sCartAction)) {
                        String sourceOrderNum, orderJSON = '';
                        Set<Id> setOrderId = new Set<Id> ();
                        Set<Id> setOrderInterfaceId = new Set<Id> ();
                        Map<String, APTS_DOEPIReqWrapper.EPIOrderLI> mapEPIOLI = new Map<String, APTS_DOEPIReqWrapper.EPIOrderLI>();

                        for (Apttus_Config2__ProductConfiguration__c cartObj : [SELECT Apttus_Config2__OrderId__c, Apttus_Config2__OrderId__r.APTS_Source_Order_Number__c FROM Apttus_Config2__ProductConfiguration__c WHERE Id = :cartId AND Apttus_Config2__OrderId__c <> null]) {
                            setOrderId.add(cartObj.Apttus_Config2__OrderId__c);
                            sourceOrderNum = cartObj.Apttus_Config2__OrderId__r.APTS_Source_Order_Number__c;
                        }

                        //prepare string json from child interface logs
                        for (APTS_Order_Interface_Log__c oLogObj : [SELECT id, APTS_SourceOrderNumber__c, APTS_Message__c, APTS_Parent_Log__c, APTS_Sequence__c, APTS_Status__c
                                FROM APTS_Order_Interface_Log__c WHERE APTS_SourceOrderNumber__c <> null
                                AND (APTS_SourceOrderNumber__c = :sourceOrderNum OR APTS_Parent_Log__r.APTS_SourceOrderNumber__c = :sourceOrderNum)
                                ORDER BY APTS_Sequence__c]) {
                            orderJSON += oLogObj.APTS_Message__c;
                            setOrderInterfaceId.add(oLogObj.Id);
                        }

                        if (String.isNotBlank(orderJSON)) {
                            try {
                                //deserilize JSONstr
                                APTS_DOEPIReqWrapper oDOWrap = (APTS_DOEPIReqWrapper)JSON.deserialize(orderJSON, APTS_DOEPIReqWrapper.class);
                                if (oDOWrap != NULL && oDOWrap.OrderLineItems != null) {

                                    //Loop EPIOrderLineItems
                                    for (APTS_DOEPIReqWrapper.EPIOrderLI oEPILI : oDOWrap.OrderLineItems) {
                                        mapEPIOLI.put(oEPILI.SourceLineNumber, oEPILI);
                                    }
                                }
                            } catch (Exception ex) {

                            }
                        }

                        Group queue = APTS_DigitalOrderBatchHelper.getCSQueue();
                        //Submit Order, invokes AcceptOrder API and create interface log, moving to sync execution will throw SOQL202 error
                        
                        APTS_DigitalOrderBatchHelper.updateOLIAndsubmit(queue, setOrderId, mapEPIOLI,mapInterface);

                        //update order interface log status
                        List<APTS_Order_Interface_Log__c> listLog = APTS_DigitalOrderBatchHelper.getStatusInterfaceLog(queue, setOrderInterfaceId);

                        if (listLog != null && !listLog.isEmpty()) {
                            Database.update(listLog, false);
                        }

                    } else {
                        //else reprice until all line items are priced
                        Boolean isPricePending = APTS_DigitalOrderBatchHelper.repriceCart(cartId);
                        // if price is complete invoke same queue to finalize cart
                        //else invoke same queue to reprice until all line items are priced
                        sCartAction = isPricePending ? sCartAction : FINALIZE;
                        System.enqueueJob(new APTS_RepriceFinalizationQueue(cartId, sOrderType, sCartAction));
                    }

                    //v101 end
                } else {
                    //Update Pricing until isPricingPending flag becomes 'False'
                    Boolean isPricePending = true;
                    while (isPricePending) {
                        isPricePending = APTS_OrderUtils.repriceCart(cartId);
                        if (!isPricePending) {
                            break;
                        }
                    }

                    //Finalize
                    APTS_OrderUtils.finalizeCart(cartId);

                    //Syncronize
                    Boolean isSuccess = APTS_OrderUtils.syncCart(cartId);

                    //Submission Order
                    Set<String> setOrdType = new Set<String>();
                    setOrdType.add(STANDARD_RETURN);
                    setOrdType.add(DE_INSTALLATION);
                    setOrdType.add(INTERNAL_MOVEMENT);
                    setOrdType.add(EXTERNAL_MOVEMENT);
                    setOrdType.add(TECHNICAL_SWAP);
                    setOrdType.add(COMMERCIAL_SWAP);

                    // 13 May 2018 - Added - Moved the query here to avoid finalize in case of External Movement.
                    List<Apttus_Config2__ProductConfiguration__c> listConfig = [SELECT Apttus_Config2__OrderId__c,
                                                                  Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c, Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c,
                                                                  Apttus_Config2__OrderId__r.Apttus_Config2__ParentOrderId__c
                                                                  FROM Apttus_Config2__ProductConfiguration__c
                                                                  WHERE Id = : cartId AND Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c IN: setOrdType LIMIT 1];

                    if (!listConfig.isEmpty() && String.isNotBlank(listConfig[0].Apttus_Config2__OrderId__c)) {
                        Apttus_Config2__ProductConfiguration__c oCart = listConfig[0];
                        Id orderId = oCart.Apttus_Config2__OrderId__c;
                        Id parentOrderId = oCart.Apttus_Config2__OrderId__r.Apttus_Config2__ParentOrderId__c;

                        //Technical Swap
                        //If technical swap then change, serial number and physical asset from parent to child order
                        if (parentOrderId != NULL && TECHNICAL_SWAP.equalsIgnoreCase(oCart.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c)) {
                            Set<Id> setOrderId = new Set<Id>();
                            setOrderId.add(orderId);
                            setOrderId.add(parentOrderId);

                            //check if order is deinstall order
                            List<Apttus_Config2__OrderLineItem__c> listToUpdate = new List<Apttus_Config2__OrderLineItem__c>();
                            List<Apttus_Config2__OrderLineItem__c> listChildOrderLine = new List<Apttus_Config2__OrderLineItem__c>();
                            Map<String, Apttus_Config2__OrderLineItem__c> mapParentOrderLine = new map<String, Apttus_Config2__OrderLineItem__c>();

                            //get order line item of both order
                            for (Apttus_Config2__OrderLineItem__c oOrderLineItem : [SELECT id, Apttus_Config2__LineNumber__c, Apttus_Config2__OrderId__c,
                                    Apttus_Config2__OrderId__r.Apttus_Config2__ParentOrderId__c, APTS_Physical_Asset__c, APTS_Serial_Number__c,
                                    Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c, Apttus_Config2__ProductId__c, Apttus_Config2__OptionId__c,
                                    Apttus_Config2__ChargeType__c
                                    FROM Apttus_Config2__OrderLineItem__c
                                    WHERE Apttus_Config2__OrderId__c IN :setOrderId LIMIT 10000]) {

                                //Prepare list of child orders
                                if (XB13.equalsIgnoreCase(oOrderLineItem.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c) ) {
                                    listChildOrderLine.add(oOrderLineItem);
                                } else {
                                    //prepare map of order  and order line item
                                    String key = oOrderLineItem.Apttus_Config2__LineNumber__c + '_' + oOrderLineItem.Apttus_Config2__ProductId__c;
                                    if (oOrderLineItem.Apttus_Config2__OptionId__c != NULL) {
                                        key += '_' + oOrderLineItem.Apttus_Config2__OptionId__c;
                                    }
                                    key += '_' + oOrderLineItem.Apttus_Config2__ChargeType__c;

                                    mapParentOrderLine.put(key, oOrderLineItem);
                                }

                            }

                            //copy phy.asset and serial number
                            for (Apttus_Config2__OrderLineItem__c oOrderLineItem : listChildOrderLine) {
                                String key = oOrderLineItem.Apttus_Config2__LineNumber__c + '_' + oOrderLineItem.Apttus_Config2__ProductId__c;
                                if (oOrderLineItem.Apttus_Config2__OptionId__c != NULL) {
                                    key += '_' + oOrderLineItem.Apttus_Config2__OptionId__c;
                                }
                                key += '_' + oOrderLineItem.Apttus_Config2__ChargeType__c;
                                Apttus_Config2__OrderLineItem__c oParentOrderLine = mapParentOrderLine.get(key);

                                if (oParentOrderLine != NULL && oParentOrderLine.APTS_Physical_Asset__c != NULL) {
                                    oOrderLineItem.APTS_Physical_Asset__c = oParentOrderLine.APTS_Physical_Asset__c;
                                    oOrderLineItem.APTS_Serial_Number__c = oParentOrderLine.APTS_Serial_Number__c;
                                    oParentOrderLine.APTS_Physical_Asset__c = NULL;
                                    oParentOrderLine.APTS_Serial_Number__c = NULL;
                                    listToUpdate.add(oParentOrderLine);
                                }
                                listToUpdate.add(oOrderLineItem);
                            }

                            if (!listToUpdate.isEmpty()) {
                                update listToUpdate;
                            }


                            if (!setOrderId.isEmpty()) {
                                APTS_OrderUtils.submitMultipleOrders(setOrderId);
                            }
                        } else {
                            APTS_OrderUtils.submitOrder(orderId);
                        }
                    }
                }
            }
        } catch (Exception e) {
            APTS_CustomLogging.createErrorLog('APTS_RepriceFinalizationQueue', 'Apex', e.getStackTraceString(), 'Order', '', 'OM', false, false, NULL, true);
        }
    }
}