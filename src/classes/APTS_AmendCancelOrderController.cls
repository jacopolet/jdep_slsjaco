/*************************************************************
@Name: APTS_AmendCancelOrderController
@Author: Neev Shah
@CreateDate: 17-08-2018
@Description: Amend, Cancel or Amend Dates Order
@UsedBy: APTS_AmendOrderDate page on Order Header
******************************************************************/
//v100 17-08-2018 Neev Shah: Initial version.
//v101 25-04-2019 Neev Shah: machine cancel
//v102 23-05-2019 Rajesh Patel : Cancel order if order status is in Draft
//V103 15-07-2020 Aarthi Pitchai : DQ-2521 - Remove the OFLI check in Amendment usecases

public with sharing class APTS_AmendCancelOrderController {
    private static final String ACTION_AMEND = 'Amend';
    private static final String ACTION_CANCEL = 'Cancel';
    private static final String ORDER_AMEND = '/apex/Apttus_Config2__OrderAmend?id=';
    private static final String ORDER_CANCEL = '/apex/Apttus_Config2__OrderCancel?id=';
    private static final String FLOW = '&flow=';
    private static final String STR_CANCEL = 'Cancel';
    private static final String STR_CLOSED = 'Closed';
    private static final Set<String> setAllowedAction = new Set<String> {'Amend', 'Cancel'};

    private Apttus_Config2__Order__c oOldOrder;

    public String sAction {get; set;}
    public String sFlow {get; set;}
    public Date dtDeinstallDate {get; set;}
    public Boolean isAmendDate {get; set;}
    public Boolean isValidOrder {get; set;}
    public Boolean isDeInstallationDateVisible {get; set;}
    public Boolean isInstallationDateVisible {get; set;}
    public Apttus_Config2__Order__c oOrder {get; set;}


    public APTS_AmendCancelOrderController() {
        //initialization
        isValidOrder = false;
        isAmendDate = false;
        isDeInstallationDateVisible = false;
        isInstallationDateVisible = false;


        try {

            // Get Page params
            String orderId = ApexPages.currentPage().getParameters().get('Id');
            sAction = ApexPages.currentPage().getParameters().get('action');
            sFlow = ApexPages.currentPage().getParameters().get('flow');


            if (setAllowedAction.contains(sAction) && orderId != NULL) {
                oOrder = [SELECT Id, APTS_Order_Header_SAP_ID__c, APTS_Order_Type__c, APTS_Requested_Delivery_Date__c, APTS_Sales_Organization__c,
                          APTS_Requested_De_Installation_Date__c, APTS_Requested_Installation_Date__c, APTS_Order_Sub_Type__c, Apttus_Config2__Status__c,
                          APTS_SAP_OrderType__c, APTS_Lock_Order__c, APTS_Status__c
                          FROM Apttus_Config2__Order__c WHERE Id = :orderId limit 1 FOR UPDATE];

                if (!oOrder.APTS_Lock_Order__c) {
                    //v102 << ++
                    if (APTS_OrderConstants.DRAFT.equalsIgnoreCase(oOrder.Apttus_Config2__Status__c) && APTS_OrderConstants.DRAFT.equalsIgnoreCase(oOrder.APTS_Status__c)) {
                        PageReference pageRef = new PageReference('/' +  orderId);
                        //v102 >> ++
                    } else if (APTS_OrderConstants.PENDING.equalsIgnoreCase(oOrder.Apttus_Config2__Status__c) && oOrder.APTS_Order_Header_SAP_ID__c != NULL) {
                        //if (oOrder.APTS_Order_Header_SAP_ID__c != NULL) {
                        //V103 ++ <<>>
                       //List<Apttus_Config2__OrderFulfillmentLineItem__c> listFul = [SELECT id FROM Apttus_Config2__OrderFulfillmentLineItem__c WHERE Apttus_Config2__OrderId__c = :orderId FOR UPDATE];
                       // if (listFul.isEmpty()) {

                            String sAmendDate = ApexPages.currentPage().getParameters().get('isAmendDate');
                            oOldOrder = oOrder.clone(false, false, false, false);

                            if (sAmendDate != NULL) {
                                isValidOrder = true;
                                isAmendDate = Boolean.valueOf(sAmendDate);
                                isInstallationDateVisible = !APTS_OrderConstants.MACHINE_ORDER.equalsIgnoreCase(oOrder.APTS_Order_Type__c) || APTS_OrderConstants.DE_INSTALLATION .equalsIgnoreCase(oOrder.APTS_Order_Sub_Type__c) || APTS_OrderConstants.XB13.equalsIgnoreCase(oOrder.APTS_SAP_OrderType__c) ? false : true;
                                isDeInstallationDateVisible = !APTS_OrderConstants.MACHINE_ORDER.equalsIgnoreCase(oOrder.APTS_Order_Type__c) || APTS_OrderConstants.INSTALLATION.equalsIgnoreCase(oOrder.APTS_Order_Sub_Type__c) || APTS_OrderConstants.XA13.equalsIgnoreCase(oOrder.APTS_SAP_OrderType__c) ? false : true;

                                //initiate dates if null values
                                oOrder.APTS_Requested_Delivery_Date__c = oOrder.APTS_Requested_Delivery_Date__c == null ? system.today() : oOrder.APTS_Requested_Delivery_Date__c;
                                if (isInstallationDateVisible || isDeInstallationDateVisible) {
                                    Date nextMonday = system.today().toStartOfWeek().addDays(7);
                                    oOrder.APTS_Requested_Installation_Date__c = isInstallationDateVisible && oOrder.APTS_Requested_Installation_Date__c == null ? nextMonday : oOrder.APTS_Requested_Installation_Date__c;
                                    oOrder.APTS_Requested_De_Installation_Date__c = isDeInstallationDateVisible && oOrder.APTS_Requested_De_Installation_Date__c == null ? nextMonday : oOrder.APTS_Requested_De_Installation_Date__c;
                                    dtDeinstallDate = isDeInstallationDateVisible ? oOrder.APTS_Requested_De_Installation_Date__c.date() : NULL;

                                    ApexPages.addmessage(new ApexPages.message(ApexPages.Severity.Info, APTS_OrderConstants.AMENDORDER_PAGEMESSAGE));
                                }
                            } else if (APTS_OrderConstants.MACHINE_ORDER.equalsIgnoreCase(oOrder.APTS_Order_Type__c) && STR_CANCEL.equalsIgnoreCase(sAction)) { //v101 ++ <<
                                Boolean isPendingCase = false;
                                String caseNumber = '';

                                for (Case oCase : [SELECT Status, CaseNumber FROM Case WHERE ApptusOrder__c = :orderId]) {
                                    if (!(APTS_OrderConstants.CLOSED.equalsIgnoreCase(oCase.Status) || APTS_OrderConstants.CANCELED.equalsIgnoreCase(oCase.Status))) {
                                        isPendingCase = true;
                                        caseNumber += oCase.CaseNumber + ' ';
                                    }
                                }

                                if (isPendingCase) {
                                    ApexPages.addmessage(new ApexPages.message(ApexPages.Severity.ERROR, APTS_OrderConstants.OPEN_CASE_VALIDATION_CANCELLATION + caseNumber));
                                }
                            } //v101 ++ >>
                             //V103 ++ <<
                       /* } else {
                            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Order can only ' + sAction  + ' before SAP creates delivery'));
                        } */ //V103 ++ >>
                    } else {
                        // throw error, Order must be Submitted and SAP must not have created Delivery
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Order can only ' + sAction  + ' after SAP receives initial and before delivery is created'));
                    }
                } else {
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'This Order record is locked.'));
                }
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invalid Action'));
            }
        } catch (Exception ex) {
            APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getMessage(), 'APTS_AmendCancelOrderController', null, 'OM', false, false, null, true);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
    }

    public PageReference submitOrder() {
        PageReference pageRef;

        //try {
        //Performance issue fixes by Ajith
        if (Apttus_Config2__Order__c.sObjectType.getDescribe().isUpdateable() && Apttus_Config2__LineItem__c.sObjectType.getDescribe().isUpdateable() && Apttus_Config2__OrderLineItem__c.sObjectType.getDescribe().isUpdateable()) {
            if (isAmendDate && oOrder != NULL) {
                pageRef = new PageReference('/' + oOrder.Id);
                Boolean isOrderUpdatedRequired = false;
                //If Requested de-installation date is changed
                if (isDeInstallationDateVisible && dtDeinstallDate != null && dtDeinstallDate != oOldOrder.APTS_Requested_De_Installation_Date__c.date()) {

                    //check if de-installation date is Monday or not
                    DateTime myDateTime =  (DateTime) dtDeinstallDate;
                    String dayOfWeek = myDateTime == NULL ? '' : myDateTime.format('E');

                    if (!'Mon'.equalsIgnoreCase(dayOfWeek)) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Requested  De-Installation Date must be set to Monday.'));
                    } else {
                        oOrder.APTS_Requested_De_Installation_Date__c = dtDeinstallDate;
                        oOrder.APTS_Requested_Delivery_Date__c = dtDeinstallDate;
                        isOrderUpdatedRequired = true;
                    }
                }

                //If Requested Installation date is changed
                if (isInstallationDateVisible && oOrder.APTS_Requested_Installation_Date__c != null && oOrder.APTS_Requested_Installation_Date__c != oOldOrder.APTS_Requested_Installation_Date__c) {

                    //Check if Installation date is Monday or not
                    DateTime myDateTime =  (DateTime) oOrder.APTS_Requested_Installation_Date__c;
                    String dayOfWeek = myDateTime == NULL ? '' : myDateTime.format('E');

                    if (!'Mon'.equalsIgnoreCase(dayOfWeek)) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Requested Installation Date must be set to Monday.'));
                    } else {
                        //set country offset
                        oOrder.APTS_Requested_Delivery_Date__c = APTS_OrderUtils.checkRequestedDeliveryDateInWorkingHours(oOrder, oOrder.APTS_Requested_Installation_Date__c);
                        isOrderUpdatedRequired = true;
                    }
                }


                //check if  Delivery Date is changed
                if (!isOrderUpdatedRequired && oOrder.APTS_Requested_Delivery_Date__c != null && oOrder.APTS_Requested_Delivery_Date__c != oOldOrder.APTS_Requested_Delivery_Date__c) {
                    if (oOrder.APTS_Requested_Installation_Date__c != null && oOrder.APTS_Requested_Delivery_Date__c > oOrder.APTS_Requested_Installation_Date__c) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Requested Delivery Date must be earlier than Requested Installation date.'));
                    } else {
                        //no need to apply country offset as installation / de-installation dates didnt change
                        isOrderUpdatedRequired = true;
                    }
                }

                if (isOrderUpdatedRequired && oOrder != NULL) {
                    //update Order
                    APTS_OrderTriggerHandler.setTriggerDisabled(true);
                    update oOrder;
                    APTS_OrderTriggerHandler.setTriggerDisabled(false);

                    //update line item so if this order is Amended or changed it preserves changed dates
                    List<Apttus_Config2__LineItem__c> listLineItems = [SELECT id, APTS_Requested_Delivery_Date__c, APTS_Requested_Installation_Date__c FROM Apttus_Config2__LineItem__c
                            WHERE Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__c = :oOrder.Id FOR UPDATE];

                    for (Apttus_Config2__LineItem__c oLI : listLineItems) {
                        oLI.APTS_Requested_Delivery_Date__c = oOrder.APTS_Requested_Delivery_Date__c;
                        oLI.APTS_Requested_Installation_Date__c = isDeInstallationDateVisible ?  oOrder.APTS_Requested_De_Installation_Date__c.date() : oOrder.APTS_Requested_Installation_Date__c;
                    }

                    if (listLineItems != NULL && !listLineItems.isEmpty()) {
                        update listLineItems;
                    }

                    //update Order Line Item before submitting order again
                    List<Apttus_Config2__OrderLineItem__c> listToUpdate = new List<Apttus_Config2__OrderLineItem__c>();
                    for (Apttus_Config2__OrderLineItem__c oOLI : [SELECT Id, APTS_Requested_Delivery_Date__c, APTS_Requested_Installation_Date__c,
                            APTS_Expected_Delivery_Quantity__c, APTS_Expected_Delivery_Date__c, APTS_ATP_Cleared__c
                            FROM Apttus_Config2__OrderLineItem__c WHERE Apttus_Config2__OrderId__c = :oOrder.Id FOR UPDATE] ) {
                        oOLI.APTS_Requested_Delivery_Date__c = oOrder.APTS_Requested_Delivery_Date__c;
                        oOLI.APTS_Expected_Delivery_Quantity__c = null;
                        oOLI.APTS_Expected_Delivery_Date__c = null;
                        oOLI.APTS_ATP_Cleared__c = false;
                        oOLI.APTS_Requested_Installation_Date__c = isDeInstallationDateVisible ?  oOrder.APTS_Requested_De_Installation_Date__c.date() : oOrder.APTS_Requested_Installation_Date__c;
                        listToUpdate.add(oOLI);
                    }

                    if (listToUpdate != NULL && !listToUpdate.isEmpty()) {
                        update listToUpdate;
                    }

                    List<Apttus_Config2__Order__c> listOrders = new List<Apttus_Config2__Order__c> {oOrder};
                    APTS_OrderUtils.submitMultipleOrders(true, listOrders);
                }

            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Requested Date must not be blank.'));
            }
        }

        /* } catch (Exception ex) {
             ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getStackTraceString()));
             APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString(), 'APTS_AmendCancelOrderController', null, 'OM', false, false, null, true);
         } */

        return ApexPages.hasMessages() ? null : pageRef;
    }

// Incase of Requested installation date changed, cal new date accordingly to off-sets
    public void calcReqDeliveryDate() {

        //  try{
        if (oOrder.APTS_Requested_Installation_Date__c != null && oOrder.APTS_Requested_Installation_Date__c != oOldOrder.APTS_Requested_Installation_Date__c) {

            //Check if Installation date is Monday or not
            DateTime myDateTime =  (DateTime) oOrder.APTS_Requested_Installation_Date__c;
            String dayOfWeek = myDateTime == NULL ? '' : myDateTime.format(APTS_OrderConstants.EE);

            if (!'Mon'.equalsIgnoreCase(dayOfWeek)) {
                ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Requested Installation Date must be set to Monday.');
                ApexPages.addMessage(msg);
            } else {
                //set country offset
                oOrder.APTS_Requested_Delivery_Date__c = APTS_OrderUtils.checkRequestedDeliveryDateInWorkingHours(oOrder, oOrder.APTS_Requested_Installation_Date__c);
            }
        } else if (dtDeinstallDate != null && dtDeinstallDate != oOldOrder.APTS_Requested_De_Installation_Date__c.date()) {
            //check if de-installation date is Monday or not
            DateTime myDateTime =  (DateTime) dtDeinstallDate;
            String dayOfWeek = myDateTime == NULL ? '' : myDateTime.format(APTS_OrderConstants.EE);

            if (!'Mon'.equalsIgnoreCase(dayOfWeek)) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Requested  De-Installation Date must be set to Monday.'));
            } else {
                oOrder.APTS_Requested_De_Installation_Date__c = dtDeinstallDate;
                oOrder.APTS_Requested_Delivery_Date__c = dtDeinstallDate;
            }
        }

        ApexPages.addmessage(new ApexPages.message(ApexPages.Severity.Info, APTS_OrderConstants.AMENDORDER_PAGEMESSAGE));
        // }catch (Exception ex){ APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString(), 'APTS_AmendCancelOrderController', null, 'OM', false, false, null, true);}
    }

    public PageReference redirectAmendCancelOrder() {
        Id newOrderId = NULL;
        PageReference pageRef;
        //v102 ++<<
        Boolean oStatus = APTS_OrderConstants.DRAFT.equalsIgnoreCase(oOrder.Apttus_Config2__Status__c) && APTS_OrderConstants.DRAFT.equalsIgnoreCase(oOrder.APTS_Status__c) ? true : false;
        Boolean action = ACTION_CANCEL.equalsIgnoreCase(sAction) ? true : false;
        Boolean checkLock = !oOrder.APTS_Lock_Order__c ? true : false;
        //v102  ++>>

        //try {
        if (ACTION_AMEND.equalsIgnoreCase(sAction) && !isAmendDate) {
            //amend api
            pageRef = new PageReference(ORDER_AMEND + oOrder.Id + FLOW + sFlow);
        } else if (action && !oStatus) {
            //cancel api
            pageRef = new PageReference(ORDER_CANCEL + oOrder.Id);
        } //v102 ++<<
        else if (oStatus && action && checkLock) {
            // order Status if Draft then cancel order
            Apttus_Config2__Order__c cOrder = new Apttus_Config2__Order__c();
            cOrder.id = oOrder.Id;
            cOrder.Apttus_Config2__Status__c = APTS_OrderConstants.CANCELLED;
            cOrder.APTS_Status__c = APTS_OrderConstants.CANCELLED;
            APTS_OrderTriggerHandler.setTriggerDisabled(true);
            database.update(cOrder, false);
            APTS_OrderTriggerHandler.setTriggerDisabled(false);

            List<Apttus_Config2__OrderLineItem__c> listOLI = [SELECT id, Apttus_Config2__Status__c, APTS_Status__c FROM Apttus_Config2__OrderLineItem__c WHERE Apttus_Config2__OrderId__c = :oOrder.Id];
            for (Apttus_Config2__OrderLineItem__c oLI : listOLI) {
                oLI.Apttus_Config2__Status__c = APTS_OrderConstants.CANCELLED;
                oLI.APTS_Status__c = APTS_OrderConstants.CANCELLED;
            }
            if (listOLI.size() > 0) {
                APTS_OrderLineItemTriggerHandler.setTriggerDisabled(true);
                database.update(listOLI, false);
                APTS_OrderLineItemTriggerHandler.setTriggerDisabled(false);
            }
            pageRef = new PageReference('/' +  oOrder.Id);

        } //v102 ++<<

        if (newOrderId != NULL) {
            pageRef = new PageReference('/' +  newOrderId);
        }
        /* } catch (Exception ex) {
             APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString(), 'APTS_AmendCancelOrderController', null, 'OM', false, false, null, true);
         } */

        return ApexPages.hasMessages() ? null : pageRef;
    }

    public PageReference back() {
        PageReference pageRef = new PageReference('/' +  oOrder.Id);
        return pageRef;
    }
}