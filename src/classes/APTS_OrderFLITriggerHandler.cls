/*************************************************************
@Name: APTS_OrderFLITriggerHandler
@Author: Galin Georgiev
@CreateDate: 03-04-2018
@Description: Order fulfillment line item trigger handler
@UsedBy: Order trigger
******************************************************************/
//v100 03-04-2018 Galin Georgiev: Rewrite.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes
//V101 Rajesh Patel - Defect#5320 Standard order return error msg
//V102 Nikita Modi - Defect#6051 Order status doesn't update correctly (in case of multiple deliveries)
//V103 Nikita Modi - If multiple responses for OFLI is received
//V104 12-Apr-2018 Aarthi Pitchai - Defect #6167 - Fix to prevent the Status updates on OLI and OH in case of Multiple SAP updates on OFLI
//V105 15-Apr-2018 Nikita Modi - Defect #6167 - Fix to prevent the Status updates on Order to partially fulfilled in case of Multiple SAP updates on OFLI
//V106 18-Apr-2018 Nikita Modi - Defect #6167 - Fix to prevent the Status updates on De-installation Order in case of Multiple SAP updates on OFLI
//v107 15-May-2019 Neev Shah -- code Merge 3.1 original change --> 20-Mar-2019  Sanjay - Movement Order Changes
//v108 15-May-2019 Neev Shah -- code Merge 3.1 original change --> Partial Cancel CR
//v109 15-May-2019 Neev Shah -- code Merge 3.1 original change --> 21-mar-2019 Akanksha - CR2909 changes
//v110 22-May-2019 Neev Shah --  3.1 --> Added conditons to stop going to previous status
//v111 23-May-2019 Neev Shah --  code Merge 3.1 original change --> 10-May-2018 Nikita Modi - DOQOM-36 Logic to populate Delivery Number on Order line item
//V112 30-May-2019 Aarthi Pitchai - DOK31-127 changes
//V113 09-May-2019 Aarthi Pitchai - DOQOM-20 - In case of deInstall mark OLIs returned only if it is already activated
//V114 20-May-2019 Aarthi Pitchai - DOQOM-20 - In case of deInstall mark Orders returned only if it is already activated
//V115 24-May-2019 Aarthi Pitchai - DOQOM-123 - Delivery only and Return Only related changes
//V116 11-Sep-2019 Aarthi Pitchai - QTCFLEX1-1258 - Order header change fix for multiple updates from SAP
//V117 06-Dec-2019 Aarthi Pitchai - QTCFLEX1-1806 - SAP Delivery number issue fix
//V118 13-Dec-2019 Aarthi Pitchai - QTCFLEX1-1818 - Avoid setting Authorized date in case of Zero delivery
//V119 07-May-2020 Aarthi Pitchai - DQ-2306 - Avoid setting Authorized date in case of Return only with Zero picking
//V120 28-May-2020 Venky Muppalaneni - DQ-2521- 0 picking -> Ingredients  back to pending
//V121 22-06-2020 Venky Muppalaneni: DQ-3038 Implementing new error handling 
//v122 20-07-2020 Lavanya DQ-177 Pending Status Update logic if no delivery/fulfilment is done in OFLI
//V123 13-08-2020 Aarthi Pitchai - DQ-3509 - Fix to set fulfilled status on non relevant lines w.r.t bundle
//V124 20-11-2020 Aarthi Pitchai - DQ-3999 - Fix - Post DeInstall Activation, when PGR done on Primary L1, non relevant lines goes to Fulfilled
//V125 23-11-2020 Aarthi Pitchai - DQ-4386 - Bug fix in 0 picking logic - DeInstall - O picked item not goes to Pending to fulfilled when PGR done with Qty =1
//V126 25-01-2021 Aarthi Pitchai - DQ-4735 - Subscription Order Changes

public without sharing  class APTS_OrderFLITriggerHandler implements ITriggerHandler {

    //3.1 v108 make trigger variable public ++ <<
    public static Boolean isTriggerDisabled = false;
    //3.1 v108 ++ >>

    private static final String SAP_INTEGRATION_USER = System.Label.APTS_SAPIntegrationUser;
    private static final String NOT_RELEVANT = system.label.APTS_Not_Relevant;
    private static final String NOT_YET_PROCESSED = system.label.APTS_Not_Yet_processed;
    private static final String COMPLETELY_PROCESSED = system.label.APTS_Completely_processed;
    private static final String OPTION = System.Label.APTS_Option;
    private static final String STANDARD_ORDER = System.Label.APTS_Standard_Order;
    private static final String MACHINE_ORDER = System.Label.APTS_Machine_Order;
    private static final String ACTIVATED = System.Label.APTS_Activated;
    private static final String EMAIL = System.Label.APTS_Email;
    private static final String ROUTESALES_ORDER = System.Label.APTS_Order_Type_Route_Sales;
    private static final String OPERATING_ORDER = System.Label.APTS_Order_Type_Operating;
    private static final String ORDERCRUD = 'Apttus_Config2__Order__c';
    private static final String ORDERLICRUD = 'Apttus_Config2__OrderLineItem__c';
    private static final String XB13 = APTS_OrderConstants.XB13;

    //3.1 v107 ++ <<
    private static final String XA14 = APTS_OrderConstants.XA14;
    //3.1 v107 ++ >>

    private Set<String> setStandardOrderTypes = new Set<String> {STANDARD_ORDER, ROUTESALES_ORDER, OPERATING_ORDER};
    private set<string> finalStatuses = new set<string> {APTS_OrderConstants.ACTIVATED, APTS_OrderConstants.RETURNED,APTS_OrderConstants.PENDING};
    private set<string> finalStatusesOnSecondSAP = new set<string> {APTS_OrderConstants.ACTIVATED, APTS_OrderConstants.RETURNED};
    
    //@Description : Method to get the beforeInsert on OrderTriggerHandler
    public void beforeInsert(List<SObject> newItems) {

        APTS_OrderUtils.stopOrderTrigger();
        APTS_OrderUtils.stopOrderLineItemTrigger();
    }

    //@Description : Method to get executed afterInsert
    public void afterInsert(List<SObject> newList, Map<Id, SObject> newItems) {

        DescribeSObjectResult objResultOrderLI = APTS_OTCUtil.getsObjectAccess(ORDERLICRUD); // CRUD/FLS Check
        DescribeSObjectResult objResultOrder = APTS_OTCUtil.getsObjectAccess(ORDERCRUD); // CRUD/FLS Check

        //Variable Section
        Decimal fulQty;

        String sStatus;

        Set<Id> setOrderIds = new Set<Id>();
        Set<Id> setOliIds = new Set<Id>();

        Apttus_Config2__Order__c orderTmp;
        Apttus_Config2__OrderLineItem__c oliTmp;
        Apttus_Config2__OrderFulfillmentLineItem__c oOFLI;
        List<Apttus_Config2__OrderLineItem__c> listOliTmp;
        List<Apttus_Config2__OrderFulfillmentLineItem__c> listOfliTmp;
        List<Apttus_Config2__Order__c> listOrderToUpdate = new List<Apttus_Config2__Order__c>();
        List<Apttus_Config2__OrderLineItem__c> listOLIToUpdate = new List<Apttus_Config2__OrderLineItem__c>();

        Map<Id, Apttus_Config2__OrderFulfillmentLineItem__c> mapNewOFLI = (Map<Id, Apttus_Config2__OrderFulfillmentLineItem__c>) newItems;
        Map<Id, Decimal> mapOLIFulQty = new Map<Id, Decimal>();
        Map<Id, List<Apttus_Config2__OrderLineItem__c>> mapOrderOLI = new Map<Id, List<Apttus_Config2__OrderLineItem__c>>();
        Map<Id, List<Apttus_Config2__OrderFulfillmentLineItem__c>> mapOLIFulfillments = new Map<Id, List<Apttus_Config2__OrderFulfillmentLineItem__c>>();
        //Variable Section

        try {
            //Initial loop
            for (Apttus_Config2__OrderFulfillmentLineItem__c oOrderFLI : mapNewOFLI.values()) {

                //Second SAP update: SAP will create FLI for all primary lines with APTS_POD_Status__c = NOT_YET_PROCESSED or NOT_RELEVANT and APTS_GoodsIssue_Status__c = NOT_YET_PROCESSED
                //On this action we will set Apttus_Config2__Status__c and APTS_Status__c to IN_FULFILLMENT on order and order line items
                //when we set Apttus_Config2__Status__c to IN_FULFILLMENT on order line items OOB process will start and will update order Apttus_Config2__Status__c to IN_FULFILLMENT
                //we will stop order trigger to skip OOB process
                //Boolean bSAPUpdate = oOrderFLI.LastModifiedBy.Name == SAP_INTEGRATION_USER;//TO DO- Add this check on all SAP updates
                Boolean isPODNotRelevant = oOrderFLI.APTS_POD_Status__c != null && (oOrderFLI.APTS_POD_Status__c.equals(NOT_RELEVANT) || oOrderFLI.APTS_POD_Status__c.equals(NOT_YET_PROCESSED));
                Boolean isGoodsIssueNotRelevant = oOrderFLI.APTS_GoodsIssue_Status__c != null && (oOrderFLI.APTS_GoodsIssue_Status__c.equals(NOT_RELEVANT) || oOrderFLI.APTS_GoodsIssue_Status__c.equals(NOT_YET_PROCESSED));

                if (isPODNotRelevant && isGoodsIssueNotRelevant) {
                    setOrderIds.add(oOrderFLI.Apttus_Config2__OrderId__c);
                    setOliIds.add(oOrderFLI.Apttus_Config2__OrderLineItemId__c);
                }
            }
            //Initial loop

            //SOQL Section
            Map<Id, Apttus_Config2__Order__c> idToOrderMap = getOrders(setOrderIds);
            Map<Id, Apttus_Config2__OrderLineItem__c> idToAllOLIMap = getOrderLineItemsByOrderId(setOrderIds);
            Map<Id, Apttus_Config2__OrderFulfillmentLineItem__c> idToAllOFLIMap = getAllOFLI(setOrderIds);
            //SOQL Section
            //Main loops

            //preapare map of Order and its line item
            for (Apttus_Config2__OrderLineItem__c oli1 :  idToAllOLIMap.values()) {

                if (oli1.Apttus_Config2__OrderId__c != null) {
                    listOliTmp = mapOrderOLI.get(oli1.Apttus_Config2__OrderId__c);
                    listOliTmp = listOliTmp == null ? new List<Apttus_Config2__OrderLineItem__c>() : listOliTmp;
                    listOliTmp.add(oli1);
                    mapOrderOLI.put(oli1.Apttus_Config2__OrderId__c, listOliTmp);
                }
            }

            Map<Id, Set<Decimal>> mapPrimaryL1Lines = new Map<Id, Set<Decimal>>(); //V123 ++ << >>
            //prepare map of Order Line Item and its fulfillments
            for (Apttus_Config2__OrderFulfillmentLineItem__c ofliTmp :  idToAllOFLIMap.values()) {

                if (ofliTmp.Apttus_Config2__OrderLineItemId__c != null) {
                    listOfliTmp = mapOLIFulfillments.get(ofliTmp.Apttus_Config2__OrderLineItemId__c);
                    listOfliTmp = listOfliTmp == null ? new List<Apttus_Config2__OrderFulfillmentLineItem__c>() : listOfliTmp;
                    listOfliTmp.add(ofliTmp);
                    mapOLIFulfillments.put(ofliTmp.Apttus_Config2__OrderLineItemId__c, listOfliTmp);
                    //add new fli in this

                    //prepare map of fulfilled qty
                    if (ofliTmp.APTS_GoodsIssue_Status__c == COMPLETELY_PROCESSED && ofliTmp.APTS_Fulfilled_Quantity__c > 0) {
                        fulQty = mapOLIFulQty.get(ofliTmp.Apttus_Config2__OrderLineItemId__c);
                        fulQty = fulQty == null || fulQty < 0 ? 0 : fulQty;
                        fulQty += ofliTmp.APTS_Fulfilled_Quantity__c;

                        if (fulQty > 0) {
                            mapOLIFulQty.put(ofliTmp.Apttus_Config2__OrderLineItemId__c, fulQty);
                        }
                    }
                    //V123 ++ <<
                   mapPrimaryL1Lines = getMapOfPrimaryL1Lines(ofliTmp, mapNewOFLI, mapPrimaryL1Lines);                
                    //V123 ++ >>
                }
            }
            //Second SAP update - set status to orders
            for (Apttus_Config2__Order__c oOrder : idToOrderMap.values()) {
                orderTmp = null;
                sStatus = '';


                if (oOrder.APTS_SAP_OrderType__c == XB13) {
                    orderTmp = new Apttus_Config2__Order__c(Id = oOrder.Id);
                    sStatus = (!finalStatusesOnSecondSAP.contains(oOrder.Apttus_Config2__Status__c)) ? APTS_OrderConstants.FULFILLED: sStatus;
                } else if (APTS_OrderConstants.FULFILLED != oOrder.Apttus_Config2__Status__c && APTS_OrderConstants.ACTIVATED != oOrder.Apttus_Config2__Status__c) {
                    Boolean isOrderPartiallyFulfilled = false;
                    orderTmp = new Apttus_Config2__Order__c(Id = oOrder.Id);
                    //standard order can have partially fulfilled staus
                    if (setStandardOrderTypes.contains(oOrder.APTS_Order_Type__c)) {
                        // Partial cancel CR
                        //3.1 v108 ++ handle status differently for Partial Cancel <<

                        listOliTmp = mapOrderOLI.get(oOrder.Id);

                        if (listOliTmp != null && !listOliTmp.isEmpty()) {
                            for (Apttus_Config2__OrderLineItem__c oOrderLineItem : listOliTmp) {
                                //3.110 ++ << added condition to orderlineitem  for partially fulfilled or activate status
                                if (oOrderLineItem.APTS_Item_Relevant_for_SAP__c && (APTS_OrderConstants.FULFILLED == oOrderLineItem.Apttus_Config2__Status__c || APTS_OrderConstants.ACTIVATED == oOrderLineItem.Apttus_Config2__Status__c || oOrderLineItem.Apttus_Config2__FulfilledQuantity__c > 0)) {
                                    //3.110 ++ >>
                                    isOrderPartiallyFulfilled = true;
                                    break;
                                }
                            }
                        }
                        //3.1 v108 ++ >>
                    }

                    //If standard order has Partially Fulfilled Order, it can't go back to In_Fulfillment
                    sStatus = isOrderPartiallyFulfilled ?  APTS_OrderConstants.PARTIALLY_FULFILLED : APTS_OrderConstants.IN_FULFILLMENT;
                }

                if (orderTmp != null && String.isNotBlank(sStatus)) {
                    orderTmp.Apttus_Config2__Status__c = sStatus;
                    orderTmp.APTS_Status__c = sStatus;
                    listOrderToUpdate.add(orderTmp);
                }            
            }

            //Second SAP update - set status to primary order line items
            for (Apttus_Config2__OrderLineItem__c oOrderLineItem : idToAllOLIMap.values()) {
                oliTmp = null;
                sStatus = '';
                
                //Set status to fulfilled for Items not Relevant for SAP DQ-177- Logic update to Pending/Fulfilled based on OFLI for machines
                if (!oOrderLineItem.APTS_Item_Relevant_for_SAP__c) {
                      //V123 ++ <<
                    boolean bIsUpdate = checkIfUpdate(oOrderLineItem, mapPrimaryL1Lines);                   
                    if(bIsUpdate)
                    {
                    oliTmp = new Apttus_Config2__OrderLineItem__c();
                    oliTmp.Id = oOrderLineItem.Id;                     
                    sStatus = (!finalStatusesOnSecondSAP.contains(oOrderLineItem.Apttus_Config2__Status__c))? APTS_OrderConstants.FULFILLED : sStatus;
                    oliTmp.Apttus_Config2__FulfilledQuantity__c = oOrderLineItem.Apttus_Config2__Quantity__c;
                    }
                    //V123 ++ >>
                } else {

                    //3.1 107 ++ << include Movement Order as well
                    //For De-install & Movements, set L1 lines to In Fulfillment and all other lines to Fulfilled
                    //Removed XA14
                    string orderType = oOrderLineItem.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c;
                    if (orderType == XB13 && !oOrderLineItem.APTS_Is_Primary_L1_Line__c && oOrderLineItem.Apttus_Config2__Status__c != APTS_OrderConstants.ACTIVATED) {
                        //3.1 107 -->>

                        oliTmp = new Apttus_Config2__OrderLineItem__c(Id = oOrderLineItem.Id);
                        oliTmp.Apttus_Config2__FulfilledQuantity__c = oOrderLineItem.Apttus_Config2__Quantity__c;
                        sStatus = (!finalstatuses.contains(oOrderLineItem.Apttus_Config2__Status__c))? APTS_OrderConstants.FULFILLED : sStatus;
                    
                        //3.1 107 ++ << exclude Movement Order as well
                    } else if (setOliIds.contains(oOrderLineItem.Id) && (oOrderLineItem.Apttus_Config2__FulfilledQuantity__c == null || oOrderLineItem.Apttus_Config2__FulfilledQuantity__c == 0) && !finalStatuses.contains(oOrderLineItem.Apttus_Config2__Status__c)) { //all without De-Install
                        //3.1 107 ++ >>
                        boolean bIsFulfilled = (oOrderLineItem.Apttus_Config2__Status__c == APTS_OrderConstants.FULFILLED);
                        if(!bIsFulfilled || (bIsFulfilled && orderType == XA14))
                        {
                            oliTmp = new Apttus_Config2__OrderLineItem__c(Id = oOrderLineItem.Id);
                            sStatus = APTS_OrderConstants.IN_FULFILLMENT;
                            fulQty = mapOLIFulQty.get(oOrderLineItem.Id);
                            oliTmp.Apttus_Config2__FulfilledQuantity__c = fulQty > 0 ? fulQty : oliTmp.Apttus_Config2__FulfilledQuantity__c;             
                        }
                    }
                }
                if (oliTmp != null && String.isNotBlank(sStatus)) {
                    oliTmp.Apttus_Config2__Status__c = sStatus;
                    oliTmp.APTS_Status__c = sStatus;
                    // v111 <<++
                    listOfliTmp = mapOLIFulfillments.get(oliTmp.Id);
                    oOFLI = listOfliTmp != null ? listOfliTmp[0] : null;
                    
                    if (oOFLI != null && APTS_OrderConstants.MACHINE_ORDER == oOFLI.Apttus_Config2__OrderId__r.APTS_Order_Type__c) { //V117 ++  <<Condition change>>
                        oliTmp.APTS_SAP_Delivery_Number__c = oOFLI.APTS_Delivery_Number__c;
                        //V119 ++ <<
                        if(oOFLI.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c == XB13 && oOFLI.Apttus_Config2__OrderLineItemId__r.APTS_Is_Primary_L1_Line__c && oOFLI.Apttus_Config2__OrderLineItemId__r.APTS_De_Installation_Required__c != null && !oOFLI.Apttus_Config2__OrderLineItemId__r.APTS_De_Installation_Required__c)
                        {
                            Boolean updateDate = (oOFLI.APTS_Fulfilled_Quantity__c > 0) && (oOFLI.APTS_GoodsIssue_Status__c == COMPLETELY_PROCESSED); //V119 ++ <<>>
                            oliTmp.APTS_De_installation_Date_Authorized__c = updateDate ? oOFLI.APTS_GoodsIssue_Date__c : null;
                        }        
                        //V119 ++ >>
                    }
                    // v111 ++>>
                    listOLIToUpdate.add(oliTmp);
                }
            }
            
            //Main loops
            //DML Section
            //Second SAP update
            if (!listOLIToUpdate.isEmpty()) {
                if (objResultOrderLI.isUpdateable()) {
                    Database.update(listOLIToUpdate);
                }
            }

            if (!listOrderToUpdate.isEmpty()) {
                if (objResultOrder.isUpdateable()) {
                    Database.update(listOrderToUpdate);
                }
            }
            //DML Section
        } catch (Exception e) {
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', null, 'OM', false, true, null, true);
        } finally {
            //Start order and order line item triggers
            APTS_OrderUtils.startOrderTrigger();
            APTS_OrderUtils.startOrderLineItemTrigger();
        }
    }

    //@Description : Method to get executed beforeUpdate
    public void beforeUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldItems) {

        APTS_OrderUtils.stopOrderTrigger();
        APTS_OrderUtils.stopOrderLineItemTrigger();
    }

    //@Description : Method to get executed afterUpdate OOB
    public void afterUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldItems) {
        //v121 ++ <<
        APTS_CustomErrorLogging.assignTransactionId(null);
        //v121 ++ >>
        DescribeSObjectResult objResultOrderLI = APTS_OTCUtil.getsObjectAccess(ORDERLICRUD); // CRUD/FLS Check
        //Variable Section
        Map<Id, Apttus_Config2__OrderFulfillmentLineItem__c> idToOrderFulfillmentLineItemMap = (Map<Id, Apttus_Config2__OrderFulfillmentLineItem__c>) newItems;
        Map<Id, Apttus_Config2__OrderFulfillmentLineItem__c> idToOrderFulfillmentLineItemMapOld = (Map<Id, Apttus_Config2__OrderFulfillmentLineItem__c>) oldItems;
        Map<Id, Apttus_Config2__OrderLineItem__c> orderLineItemToUpdateMap = new Map<Id, Apttus_Config2__OrderLineItem__c>();
        Map<Id, Apttus_Config2__Order__c> orderToBeUpdatedMap = new Map<Id, Apttus_Config2__Order__c>();
        Map<Id, List<Apttus_Config2__OrderFulfillmentLineItem__c>> orderLIIdToOFLIListMap = new Map<Id, List<Apttus_Config2__OrderFulfillmentLineItem__c>>();
        Set<Id> orderIdToBeFulfilledSet = new Set<Id>();
        set<id> setOLIId = new Set<id>();
        Boolean oldOFLICompletelyProcessed = false;
        Map<Decimal,Decimal> mapPendingRevert = new Map<Decimal,Decimal>();
        Boolean IsCompletelyProcessed = false;        
        Boolean IsPendingProcessheckFlag=false;
        List<Apttus_Config2__OrderLineItem__c> lstDeliveryOnly = new List<Apttus_Config2__OrderLineItem__c>();
        List<Apttus_Config2__OrderLineItem__c> lstReturnOnly = new List<Apttus_Config2__OrderLineItem__c>();
          
        //Variable Section
        try {
            //Initial loop
            for (Apttus_Config2__OrderFulfillmentLineItem__c oOrderFLI : idToOrderFulfillmentLineItemMap.values()) {

                orderIdToBeFulfilledSet.add(oOrderFLI.Apttus_Config2__OrderId__c);
                setOLIId.add(oOrderFLI.Apttus_Config2__OrderLineItemId__c);                
            }
            //Initial loop

            //SOQL Section
            Map<Id, Apttus_Config2__Order__c> idToOrderMap = getOrders(orderIdToBeFulfilledSet);
            Map<Id, Apttus_Config2__OrderLineItem__c> idToAllOrderLineItemMap = getOrderLineItemsByOrderId(orderIdToBeFulfilledSet);
            Map<Id, Apttus_Config2__OrderFulfillmentLineItem__c> idToAllOFLIMap = getAllOFLI(orderIdToBeFulfilledSet);
            Map<Id, Set<Decimal>> mapPrimaryL1Lines = new Map<Id, Set<Decimal>>(); //V123 ++ << >>
            Map<id, Apttus_Config2__OrderFulfillmentLineItem__c> mapLatestOFLIWithOLI = new Map<id, Apttus_Config2__OrderFulfillmentLineItem__c>(); //V125++ <<>>
            //SOQL Section

            for (Apttus_Config2__OrderFulfillmentLineItem__c oOFLI : idToAllOFLIMap.values()) {
                if(setOLIId.contains(oOFLI.Apttus_Config2__OrderLineItemId__c))
                {
                    List<Apttus_Config2__OrderFulfillmentLineItem__c> orderFLIList = orderLIIdToOFLIListMap.get(oOFLI.Apttus_Config2__OrderLineItemId__c);
                    if (orderFLIList == null) {
                        orderFLIList = new List<Apttus_Config2__OrderFulfillmentLineItem__c>();
                        orderLIIdToOFLIListMap.put(oOFLI.Apttus_Config2__OrderLineItemId__c, orderFLIList);
                    }
                    orderFLIList.add(oOFLI);
                    mapPrimaryL1Lines = getMapOfPrimaryL1Lines(oOFLI, idToOrderFulfillmentLineItemMap, mapPrimaryL1Lines);
                    //prepare map of pending qty
                 /*   if (oOFLI.APTS_GoodsIssue_Status__c == COMPLETELY_PROCESSED) {                            
                        fulQty = mapOLIFulQty.get(oOFLI.Apttus_Config2__OrderLineItemId__c);
                        fulQty = fulQty == null || fulQty == 0 ? 0 : fulQty;
                        fulQty += oOFLI.APTS_Fulfilled_Quantity__c;
                        if (fulQty > 0) {
                            mapOLIFulQty.put(oOFLI.Apttus_Config2__OrderLineItemId__c, fulQty);
                        }
                        if(fulQty == 0 && oOFLI.Apttus_Config2__OrderLineItemId__r.APTS_Is_Primary_L1_Line__c== true)
                        {
                            mapPendingRevert.put(oOFLI.Apttus_Config2__OrderLineItemId__r.Apttus_Config2__LineNumber__c,oOFLI.Apttus_Config2__OrderLineItemId__c);
                        }
                        
                    }*/
                    
                }
            }
            //Main loop
            //V120 ++ <<
                Decimal fullfilledQTY=0,tempOLICount=1;
                Map<Id,Decimal> fullfilledMap =new Map<Id,Decimal>();
                Boolean goodsIssueStatusChanged=false;
            //V120 ++ >>
            for (Apttus_Config2__OrderLineItem__c oOrderLineItem : idToAllOrderLineItemMap.values()) {
                string strStatus = null;
                boolean bdeInstallOLI = (oOrderLineItem.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c == XB13);
                boolean bOLIActivated = (oOrderLineItem.APTS_Status__c == ACTIVATED);
                boolean bIsPrimaryL1 = oOrderLineItem.APTS_Is_Primary_L1_Line__c;
                //V120 ++ <<
                fullfilledQTY=0;
                if(oOrderLineItem.APTS_Status__c== APTS_OrderConstants.PENDING)
                {
                tempOLICount=fullfilledMap.get(oOrderLineItem.Apttus_Config2__OrderId__c)!=null?fullfilledMap.get(oOrderLineItem.Apttus_Config2__OrderId__c):1;
                tempOLICount++;
                fullfilledMap.put(oOrderLineItem.Apttus_Config2__OrderId__c,tempOLICount);
                }
                goodsIssueStatusChanged=false;
                //V120 ++ >>
                if (!oOrderLineItem.APTS_Item_Relevant_for_SAP__c) {
                      boolean bIsUpdate = checkIfUpdate(oOrderLineItem, mapPrimaryL1Lines); //V123 ++ <<
                      if(bIsUpdate)
                      {
                            //V103 added oOrderLineItem.APTS_Status__c == ACTIVATED 
                            strStatus = (bdeInstallOLI && bOLIActivated) ? APTS_OrderConstants.RETURNED : ((!bdeInstallOLI && !bOLIActivated) ? APTS_OrderConstants.Fulfilled : strStatus);      
                            //V120 ++ <<
                            if(fullfilledMap.get(oOrderLineItem.Apttus_Config2__OrderId__c)!=null && oOrderLineItem.Apttus_Config2__OrderId__r.APTS_Ordered_Ingredients__c ==  fullfilledMap.get(oOrderLineItem.Apttus_Config2__OrderId__c))
                            {
                                strStatus=APTS_OrderConstants.PENDING;
                            }                           
                            //V120 ++ >>             
                            oOrderLineItem = (strStatus != null) ? setOLIStatus(oOrderLineItem, strStatus) : oOrderLineItem;  
                    }                  
                } else {

                     if(setOLIId.contains(oOrderLineItem.id))
                {
                    List<Apttus_Config2__OrderFulfillmentLineItem__c> orderFLIList = orderLIIdToOFLIListMap.get(oOrderLineItem.Id);

                    if (orderFLIList == null) {
                        strStatus = (bdeInstallOLI) ? APTS_OrderConstants.FULFILLED : APTS_OrderConstants.IN_FULFILLMENT ;
                        oOrderLineItem = setOLIStatus(oOrderLineItem, strStatus);    
                    } 
                    else 
                    {
                        Boolean bFulfilled = false;
                        Boolean bReturned = false;
                        Decimal dFulfilledQuantity = 0;
                        //V104++<<
                        Boolean bOLIExistPartiallyFulfilled = false;
                        //V104++>>
                       for (Apttus_Config2__OrderFulfillmentLineItem__c oOFLI : orderFLIList) {
                            if (oOFLI.Apttus_Config2__OrderLineItemId__c == oOrderLineItem.Id) {
                                //v101++>
                                //V104 - Renamed the below variable and added condition check for custom status = Partially fulfilled                                
                                String sMaterialNumber = oOFLI.APTS_Material_Number_SAP__c;                               
                                bOLIExistPartiallyFulfilled = oOrderLineItem.Apttus_Config2__Status__c == APTS_OrderConstants.PARTIALLY_FULFILLED && oOrderLineItem.APTS_Status__c == APTS_OrderConstants.PARTIALLY_FULFILLED;
                                String sProductCode = oOrderLineItem.APTS_Replaced_Product_Code__c;  
                                    //V120 ++ <<
                                 // boolean bSameMaterial = String.isNotBlank(sMaterialNumber) && sMaterialNumber.contains(sProductCode);                              
                                boolean bSameMaterial = String.isNotBlank(sMaterialNumber) && String.isNotBlank(sProductCode) && sMaterialNumber.contains(sProductCode);
                                //V120 ++ >> 
                                if (bSameMaterial) 
                                {
                                            dFulfilledQuantity += oOFLI.APTS_Fulfilled_Quantity__c;
                                            //V102 
                                            if(idToOrderFulfillmentLineItemMapOld.containsKey(oOFLI.Id)){    //v102 Added if Condidtion   
                                                oldOFLICompletelyProcessed = +idToOrderFulfillmentLineItemMapOld.get(oOFLI.Id).APTS_GoodsIssue_Status__c == COMPLETELY_PROCESSED;
                                                IsCompletelyProcessed = (idToOrderFulfillmentLineItemMapOld.get(oOFLI.Id).APTS_GoodsIssue_Status__c != COMPLETELY_PROCESSED && oOFLI.APTS_GoodsIssue_Status__c == COMPLETELY_PROCESSED) ? true : false;
                                                IsPendingProcessheckFlag = oOFLI.APTS_GoodsIssue_Status__c == COMPLETELY_PROCESSED; 
                                               //V125 ++ << 
                                                if(IsCompletelyProcessed)
                                               {
                                                    mapLatestOFLIWithOLI.put(oOFLI.Apttus_Config2__OrderLineItemId__c, oOFLI);
                                               } //V125 ++ >>
                                            }
                                            //V104++<< - Added else part since this forloop gets executed for OFLI associated with the OLI
                                            else{
                                                IsCompletelyProcessed =  oOFLI.APTS_GoodsIssue_Status__c == COMPLETELY_PROCESSED;
                                           } 
                                            //V104++>>

                                        }
                                        
                                         if(oOrderLineItem.APTS_Is_Primary_L1_Line__c== true && IsPendingProcessheckFlag ==true){
                                            mapPendingRevert.put(oOrderLineItem.Apttus_Config2__LineNumber__c,dFulfilledQuantity);//DQ-177 Frame Map based on Primary L1 for non relevant line status population 
                                            }
                                            
                                        //V104++<<
                                        if(!bdeInstallOLI){
                                                                                       
                                            Boolean bActivatedAlready = finalStatusesOnSecondSAP.contains(oOrderLineItem.Apttus_Config2__Status__c);
                                            if(!bActivatedAlready)
                                            {    
                                             
                                             oOrderLineItem.Apttus_Config2__Status__c = (oldOFLICompletelyProcessed && dFulfilledQuantity>0) ? APTS_OrderConstants.FULFILLED : ((bOLIExistPartiallyFulfilled || IsCompletelyProcessed) ? APTS_OrderConstants.PARTIALLY_FULFILLED : APTS_OrderConstants.IN_FULFILLMENT);
                                             if(IsPendingProcessheckFlag && dFulfilledQuantity==0) 
                                             { 
                                                 //V125 ++ << - Check if the latest OFLI is 0 picked
                                                 Apttus_Config2__OrderFulfillmentLineItem__c tempOFLI = (!mapLatestOFLIWithOLI.isEmpty())? mapLatestOFLIWithOLI.get(oOrderLineItem.id) : null;
                                                 if(tempOFLI != null)
                                                 {   
                                                    if(tempOFLI.APTS_Fulfilled_Quantity__c == 0)
                                                        oOrderLineItem.Apttus_Config2__Status__c = APTS_OrderConstants.PENDING; //DQ-177- updation to Pending for relevant lines if Good completed processed and Qty=0
                                                 } //V125 ++ >>
                                                } 
                                            }
                                            oOrderLineItem.APTS_Status__c = oOrderLineItem.Apttus_Config2__Status__c;
                                        }
                                        else{//V106++<<     
                                            
                                        if(bdeInstallOLI && oOrderLineItem.Apttus_Config2__Status__c == 'Partially Fulfilled' )
                                        {
                                            oOrderLineItem.Apttus_Config2__Status__c = oOrderLineItem.APTS_Status__c;
                                        }
                                        //DQ-177 Deinstall Relevant lines Update 
                                        if(bdeInstallOLI && IsPendingProcessheckFlag && dFulfilledQuantity==0)
                                        {
                                            //V124 ++ <<
                                            Apttus_Config2__OrderFulfillmentLineItem__c tempOFLI = (!mapLatestOFLIWithOLI.isEmpty())? mapLatestOFLIWithOLI.get(oOrderLineItem.id) : null;
                                            if(tempOFLI != null)
                                            {   
                                               if(tempOFLI.APTS_Fulfilled_Quantity__c == 0)
                                               {
                                                    oOrderLineItem.Apttus_Config2__Status__c = APTS_OrderConstants.PENDING;
                                                    oOrderLineItem.APTS_Status__c=APTS_OrderConstants.PENDING; 
                                               }                                                
                                            }
                                           }   //V124 ++ >>
                                      }//V106++>>
                                            //V104++>>     
                                       
                                if (setStandardOrderTypes.contains(oOrderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Type__c)) 
                                {
                                    oOrderLineItem.Apttus_Config2__FulfilledQuantity__c = dFulfilledQuantity;
                                  
                                } else 
                                {
                                //V118 ++ << 
                                    oOrderLineItem.APTS_Goods_Issue_Date__c = oOFLI.APTS_GoodsIssue_Date__c;
                                    oOrderLineItem.Apttus_Config2__FulfilledQuantity__c = (dFulfilledQuantity > 0 && dFulfilledQuantity >= oOFLI.APTS_Fulfilled_Quantity__c )? dFulfilledQuantity : oOFLI.APTS_Fulfilled_Quantity__c;
                                    boolean bAuthorizedDateNeeded = (oOrderLineItem.Apttus_Config2__FulfilledQuantity__c > 0) && IsCompletelyProcessed;
                                    boolean bInstallationDateUpdate = (!oOrderLineItem.APTS_Installation_Required__c && oOrderLineItem.APTS_installation_Date_Authorized__c == null);
                                    boolean bDeInstallationDateUpdate = (!oOrderLineItem.APTS_De_Installation_Required__c && oOrderLineItem.APTS_De_installation_Date_Authorized__c == null);
                                   
                                if (bdeInstallOLI) {
                                    if(!bReturned)
                                    {
                                        bReturned = IsCompletelyProcessed && (oOrderLineItem.APTS_Status__c == ACTIVATED) && bSameMaterial ? true : false;  //v106
                                    }                                     
                                    //V110 ++ << - Check if Return Only
                                    if(bAuthorizedDateNeeded && bIsPrimaryL1 && bDeInstallationDateUpdate)
                                    {
                                        lstReturnOnly = setAuthorizedDate(lstReturnOnly, oOrderLineItem.id,oOFLI.APTS_GoodsIssue_Date__c, true);
                                    } 
                                    //V110 ++ >>
                                } else {
                                    bFulfilled = IsCompletelyProcessed ? true : false;                                    
                               //V110 ++ <<
                               if(bAuthorizedDateNeeded && bIsPrimaryL1 && bFulfilled && bInstallationDateUpdate)
                                {
                                    lstDeliveryOnly = setAuthorizedDate(lstDeliveryOnly, oOrderLineItem.id,oOFLI.APTS_GoodsIssue_Date__c, false);
                                } 
                                    //V110 ++ >>
                                }
                                
                            }//V118 ++ >>
                            }
                            else
                            {
                                oOrderLineItem.Apttus_Config2__FulfilledQuantity__c = oOFLI.APTS_Fulfilled_Quantity__c;
                                oOrderLineItem = setOLIStatus(oOrderLineItem, oOrderLineItem.Apttus_Config2__Status__c);                             
                            }
                            //V120 ++ <<
                            
                                 if ( setStandardOrderTypes.contains(oOrderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Type__c)&& oOFLI.APTS_GoodsIssue_Status__c == COMPLETELY_PROCESSED && (oOFLI.Apttus_Config2__OrderLineItemId__c == oOrderLineItem.Id) ) {
                                 fullfilledQTY+= oOFLI.APTS_Fulfilled_Quantity__c;
                                 goodsIssueStatusChanged=true;
                                // oOrderLineItem = setOLIStatus(oOrderLineItem, APTS_OrderConstants.PENDING);
                                 }

                            //V120 ++ >>
                        }
                        Decimal oliQty = (oOrderLineItem.APTS_Returned_Quantity__c != null && oOrderLineItem.APTS_Returned_Quantity__c > 0) ? oOrderLineItem.APTS_Returned_Quantity__c : oOrderLineItem.Apttus_Config2__Quantity__c;
                        boolean bDeInstall = bdeInstallOLI && IsCompletelyProcessed;
                        string strOLIStatus = null;
                        //V116 ++ << //Check if Activated already
                        Boolean bOLIActivatedAlready = finalStatuses.contains(oOrderLineItem.Apttus_Config2__Status__c);
                        //V116 ++ >>
                        if (bDeInstall) {                      
                            strOLIStatus = finalStatuses.contains(oOrderLineItem.APTS_Status__c) ? oOrderLineItem.APTS_Status__c : bIsPrimaryL1 ? APTS_OrderConstants.IN_FULFILLMENT: APTS_OrderConstants.FULFILLED;
                            strOLIStatus = bReturned && dFulfilledQuantity > 0 && IsCompletelyProcessed ? APTS_OrderConstants.RETURNED : strOLIStatus;
                            //v101++<<
                                //3.1 v107 include Movement order conditions ++ <<
                            } else if ((bFulfilled || (oliQty == dFulfilledQuantity && dFulfilledQuantity>0)) && IsCompletelyProcessed && !(oOrderLineItem.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c == XA14 && bIsPrimaryL1)) {
                                //3.1 v107 >>
                            //v101++>>
                           strOLIStatus = bOLIActivatedAlready ? strOLIStatus : APTS_OrderConstants.FULFILLED;         //V116 ++ << >>                              
                        } else if (oliQty != dFulfilledQuantity && dFulfilledQuantity > 0 && IsCompletelyProcessed) {
                            strOLIStatus = bOLIActivatedAlready ? strOLIStatus : APTS_OrderConstants.PARTIALLY_FULFILLED;    //V116 ++ << >>                        
                        } else {
                            //v101++<<
                            if (IsCompletelyProcessed) {
                                strOLIStatus = bOLIActivatedAlready ? strOLIStatus : APTS_OrderConstants.IN_FULFILLMENT; //V116 ++ << >>
                                
                           } //v101++>>
                        }
                            //V120 ++ <<
                        if(goodsIssueStatusChanged && setStandardOrderTypes.contains(oOrderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Type__c) && fullfilledQTY==0 )
                            {
                            strOLIStatus = APTS_OrderConstants.PENDING;
                            tempOLICount=fullfilledMap.get(oOrderLineItem.Apttus_Config2__OrderId__c)!=null?fullfilledMap.get(oOrderLineItem.Apttus_Config2__OrderId__c):1;
                            tempOLICount++;
                            fullfilledMap.put(oOrderLineItem.Apttus_Config2__OrderId__c,tempOLICount);
                            }
                        //V120 ++ >>
                        if(strOLIStatus != null)
                        {
                            oOrderLineItem = setOLIStatus(oOrderLineItem, strOLIStatus); 
                        }
                    }
                    
                }
                
              /* if (!orderLineItemToUpdateMap.containsKey(oOrderLineItem.Id)) { Lavanya
                    orderLineItemToUpdateMap.put(oOrderLineItem.Id, oOrderLineItem);
                }*/
               
                   }
                //DQ-177 Status update for bundle non-sap relevant lines based on OFLI fulfilled qty of Primary_l1 line 
                            
                   if(!mapPendingRevert.isEmpty() &&  mapPendingRevert.size()>0 && mapPendingRevert.containsKey(oOrderLineItem.Apttus_Config2__LineNumber__c))
                    {
                      
                        if(!oOrderLineItem.APTS_Item_Relevant_for_SAP__c && mapPendingRevert.get(oOrderLineItem.Apttus_Config2__LineNumber__c)==0)
                        {
                        oOrderLineItem.Apttus_Config2__FulfilledQuantity__c = 0;
                        oOrderLineItem.Apttus_Config2__Status__c = APTS_OrderConstants.PENDING;
                        oOrderLineItem.APTS_Status__c = APTS_OrderConstants.PENDING;
                        }
                        //V124 -- <<>> - Commented below lines
                        /*else if(!oOrderLineItem.APTS_Item_Relevant_for_SAP__c && mapPendingRevert.get(oOrderLineItem.Apttus_Config2__LineNumber__c)>0)
                        {
                        oOrderLineItem.Apttus_Config2__FulfilledQuantity__c = oOrderLineItem.Apttus_Config2__Quantity__c;
                        oOrderLineItem.Apttus_Config2__Status__c = APTS_OrderConstants.FULFILLED;
                        oOrderLineItem.APTS_Status__c = APTS_OrderConstants.FULFILLED;
                        } */
                    } 
                    if (!orderLineItemToUpdateMap.containsKey(oOrderLineItem.Id)) {
                    orderLineItemToUpdateMap.put(oOrderLineItem.Id, oOrderLineItem);
                }
            }
            //Main loop
            Boolean bAllReturned = true;
            Boolean bAllFulfilled = true;
            Boolean bExistPartiallyFulfilled = false;
            Boolean bExistFulfilled = false;
            Boolean bPendingExist  = false;
            Set<Id> sFulfilledOrderIDs = new Set<Id>();
            Decimal pendingCounter=0;
            for (Apttus_Config2__Order__c oOrder : idToOrderMap.values()) {
                string strOrderStatus = null;
                pendingCounter=0;
                for (Apttus_Config2__OrderLineItem__c oOrderLineItem : orderLineItemToUpdateMap.values()) {
                    if (oOrder.Id == oOrderLineItem.Apttus_Config2__OrderId__c) {
                        
                        //DQ-177
                            if (!setStandardOrderTypes.contains(oOrderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Type__c) && oOrderLineItem.Apttus_Config2__Status__c == APTS_OrderConstants.PENDING && oOrderLineItem.APTS_Status__c == APTS_OrderConstants.PENDING) {
                                bPendingExist = true;
                                pendingCounter++;
                            }
                        //DQ-177
                        if (oOrder.APTS_SAP_OrderType__c == XB13) {
                            bAllReturned = bAllReturned && oOrderLineItem.Apttus_Config2__Status__c == APTS_OrderConstants.RETURNED;
                        } else {
                            bAllReturned = false;
                            bAllFulfilled = bAllFulfilled && oOrderLineItem.Apttus_Config2__Status__c == APTS_OrderConstants.FULFILLED;
                            //V104++ - Added extra condition check on custom status for Partial
                            if (oOrderLineItem.Apttus_Config2__Status__c == APTS_OrderConstants.PARTIALLY_FULFILLED && oOrderLineItem.APTS_Status__c == APTS_OrderConstants.PARTIALLY_FULFILLED) {
                                bExistPartiallyFulfilled = true;
                            }
                            
                            if (oOrderLineItem.APTS_Item_Relevant_for_SAP__c && oOrderLineItem.Apttus_Config2__Status__c == APTS_OrderConstants.FULFILLED) {
                                bExistFulfilled = true;
                            }
                        }
                        //V120 ++ <<
                        if(setStandardOrderTypes.contains(oOrderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Type__c) &&oOrderLineItem.Apttus_Config2__Status__c==APTS_OrderConstants.PENDING)
                            {
                                pendingCounter++;
                            }
                        //V120 ++ >>
                    }
                }
                //V118 ++ <<
                Boolean bStatusFinal = finalStatuses.contains(oOrder.Apttus_Config2__Status__c);
                //V118 ++ >>
                //3.1 v107 include movement orders ++ <<
                if (oOrder.APTS_SAP_OrderType__c == XB13  || oOrder.APTS_SAP_OrderType__c == XA14) {
                    //3.1 v107  ++ >>                    
                    strOrderStatus = (bAllReturned) ? APTS_OrderConstants.RETURNED : (!bStatusFinal ? APTS_OrderConstants.FULFILLED : strOrderStatus);   //V118 ++ << >>   
                } else if(!bStatusFinal){  //V118 ++ << >>

                    if (bAllFulfilled) {
                        if (oOrder.Apttus_Config2__Status__c != APTS_OrderConstants.FULFILLED) {
                            strOrderStatus = APTS_OrderConstants.FULFILLED;
                            sFulfilledOrderIDs.add(oOrder.Id);
                        }
                    } else if (bExistPartiallyFulfilled || bExistFulfilled) {
                        strOrderStatus = APTS_OrderConstants.PARTIALLY_FULFILLED;
                    }  //v105++<<
                    else if(!bExistPartiallyFulfilled){
                        strOrderStatus = APTS_OrderConstants.IN_FULFILLMENT;
                    }else { //v105++>>
                        //v101++<<
                        if (oldOFLICompletelyProcessed) {
                             strOrderStatus = APTS_OrderConstants.IN_FULFILLMENT;
                        } //v101++>>
                    }
                }
                //V120 ++ <<
                if(oOrder.APTS_Ordered_Ingredients__c!=0 && oOrder.APTS_Ordered_Ingredients__c==pendingCounter)
                    {
                        strOrderStatus=APTS_OrderConstants.PENDING;

                    }
                //V120 ++ >>
                //DQ-177 - Set pending status to Order if all OLI are pending                 
                if(oOrder.APTS_Number_of_Unfulfilled_Line_Item__c!=0 && pendingCounter!= 0 && oOrder.APTS_Number_of_Unfulfilled_Line_Item__c==pendingCounter)
                    {
                        strOrderStatus=APTS_OrderConstants.PENDING;
                    }
                    else if(bPendingExist && oOrder.APTS_Number_of_Unfulfilled_Line_Item__c!=0 && pendingCounter!= 0 && oOrder.APTS_Number_of_Unfulfilled_Line_Item__c!=pendingCounter)
                    {
                        strOrderStatus=APTS_OrderConstants.PARTIALLY_FULFILLED;
                    }
                //DQ-177
                if(strOrderStatus != null)
                {
                    oOrder = setOrderStatus(oOrder,strOrderStatus);
                }
                if (!orderToBeUpdatedMap.containsKey(oOrder.Id)) {
                    orderToBeUpdatedMap.put(oOrder.Id, oOrder);
                }
            }

            //DML Section
            //Third SAP update
            if (!orderLineItemToUpdateMap.isEmpty()) {
                if (objResultOrderLI.isUpdateable()) {
                    Database.update(orderLineItemToUpdateMap.values());
                }
            }
            if (!orderToBeUpdatedMap.isEmpty()) {
                if (objResultOrderLI.isUpdateable()) {
                    Database.update(orderToBeUpdatedMap.values());
                }
            }

            APTS_OrderUtils.startOrderTrigger();
            APTS_OrderUtils.startOrderLineItemTrigger();
            //V110 ++ <<
            //In case of Delivey only update the Installation date Authorised after turning on the OLI trigger since it involves date calculation
            if(!lstDeliveryOnly.isEmpty())
            {
                if (objResultOrderLI.isUpdateable()) {
                Database.update(lstDeliveryOnly, false);
                }
            }
            //In case of Return only update the deInstallation date Authorised after turning on the OLI trigger since it involves date calculation
            if(!lstReturnOnly.isEmpty())
            {
                if (objResultOrderLI.isUpdateable()) {
                Database.update(lstReturnOnly, false);
                }
            }            
            //Activate Standard Orders
            if(!sFulfilledOrderIDs.isEmpty())
            {
                activateIngredientOrders(idToOrderMap, orderLineItemToUpdateMap, sFulfilledOrderIDs);
            }
            //V110 ++ >>
            //DML Section
        } catch (Exception e) {
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', null, 'OM', false, true, null, true);
        }
    }

    //@Description : Method to get executed beforeDelete
    public void beforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems) {

    }

    //@Description : Method to get executed afterDelete
    public void afterDelete(List<SObject> oldList, Map<Id, SObject> oldItems) {

    }

    //@Description : Method to get executed afterUndelete
    public void afterUndelete(List<SObject> newList, Map<Id, SObject> newItems) {

    }

    //@Description : Method to get the isDisabled on OrderTriggerHandler
    public Boolean isDisabled() {

        return isTriggerDisabled;
    }

    public Map<Id, Apttus_Config2__Order__c> getOrders(Set<Id> orderIdSet) {

        Map<Id, Apttus_Config2__Order__c> idToOrderMap = new Map<Id, Apttus_Config2__Order__c>([
                    SELECT Id,
                    APTS_Number_of_Unfulfilled_Line_Item__c,
                    Apttus_Config2__Status__c,
                    APTS_Status__c,
                    APTS_Order_Type__c,
                    APTS_SAP_OrderType__c,
                    //V120 ++ <<
                    APTS_Ordered_Ingredients__c
                    //V120 ++ >>
                    FROM Apttus_Config2__Order__c
                    WHERE Id IN :orderIdSet]);

        return idToOrderMap;
    }

    public Map<Id, Apttus_Config2__OrderLineItem__c> getOrderLineItems(Set<Id> orderLineItemIdSet) {

        Map<Id, Apttus_Config2__OrderLineItem__c> idToOrderLineItemMap = new Map<Id, Apttus_Config2__OrderLineItem__c>([
                    SELECT Id,
                    Apttus_Config2__Status__c,
                    APTS_Status__c,
                    Apttus_Config2__Quantity__c,
                    Apttus_Config2__FulfilledQuantity__c,
                    APTS_Requested_Delivery_Date__c,
                    Apttus_Config2__ActivatedDate__c,
                    Apttus_Config2__OrderId__c,
                    Apttus_Config2__OrderId__r.APTS_Order_Type__c,
                    Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c,
                    Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c,
                    APTS_Returned_Quantity__c,
                    Apttus_Config2__HasOptions__c,
                    Apttus_Config2__LineType__c,
                    APTS_Replaced_Product_Code__c,
                    APTS_Is_Primary_L1_Line__c,//V110 ++ <<
                    APTS_De_Installation_Required__c,
                    APTS_Installation_Required__c,
                    APTS_De_installation_Date_Authorized__c,
                    APTS_Type_of_Contract__c, //V126 ++ <<>>
                    APTS_Installation_Date_Authorized__c //V110 ++ >>
                    FROM Apttus_Config2__OrderLineItem__c
                    WHERE Id IN :orderLineItemIdSet]);

        return idToOrderLineItemMap;
    }

    public Map<Id, Apttus_Config2__OrderLineItem__c> getOrderLineItemsByOrderId(Set<Id> orderIdSet) {

        Map<Id, Apttus_Config2__OrderLineItem__c> idToAllOrderLineItemMap = new Map<Id, Apttus_Config2__OrderLineItem__c>([
                    SELECT Id,
                    APTS_Item_Relevant_for_SAP__c,
                    Apttus_Config2__OrderId__c,
                    Apttus_Config2__Quantity__c,
                    Apttus_Config2__Status__c,
                    APTS_Status__c,
                    Apttus_Config2__LineNumber__c,//DQ-177
                    APTS_Requested_Delivery_Date__c,
                    Apttus_Config2__ActivatedDate__c,
                    Apttus_Config2__OrderId__r.APTS_Order_Type__c,
                    Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c,
                    Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c,
                    //V120 ++ <<
                    Apttus_Config2__OrderId__r.APTS_Ordered_Ingredients__c,
                    //V120 ++ >>
                    Apttus_Config2__FulfilledQuantity__c,
                    APTS_Returned_Quantity__c,
                    Apttus_Config2__HasOptions__c,
                    Apttus_Config2__LineType__c,
                    APTS_Replaced_Product_Code__c,
                    APTS_Is_Primary_L1_Line__c,
                    //V110 ++ <<
                    APTS_De_Installation_Required__c,
                    APTS_Installation_Required__c,
                    APTS_De_installation_Date_Authorized__c,
                    APTS_Type_of_Contract__c, //V126 ++ <<>>
                    Apttus_Config2__IsPrimaryLine__c, //V126 ++ <<>>
                    APTS_Installation_Date_Authorized__c //V110 ++ >>
                    FROM Apttus_Config2__OrderLineItem__c
                    WHERE Apttus_Config2__OrderId__c IN :orderIdSet
                    //V120 ++ <<
                    order by APTS_Item_Relevant_for_SAP__c desc
                    //V120 ++ >>
                    ]);

        return idToAllOrderLineItemMap;
    }

    public Map<Id, Apttus_Config2__OrderFulfillmentLineItem__c> getAllOFLI(Set<Id> orderIdSet) {  

        Map<Id, Apttus_Config2__OrderFulfillmentLineItem__c> idToAllOFLIMap = new Map<Id, Apttus_Config2__OrderFulfillmentLineItem__c>([
                    SELECT Id,
                    Apttus_Config2__OrderLineItemId__c,
                    APTS_GoodsIssue_Status__c,
                    APTS_GoodsIssue_Date__c,
                    APTS_Fulfilled_Quantity__c,
                    APTS_Material_Number_SAP__c,
                    Apttus_Config2__OrderId__c, //V123 ++ <<>>
                    Apttus_Config2__OrderLineItemId__r.Apttus_Config2__LineNumber__c,
                     //V117++ <<
                    Apttus_Config2__OrderId__r.APTS_Order_Type__c,
                    APTS_Delivery_Number__c,
                    Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c,
                    Apttus_Config2__OrderLineItemId__r.APTS_De_Installation_Required__c,
                    Apttus_Config2__OrderLineItemId__r.APTS_Is_Primary_L1_Line__c 
                     //V117++ >>
                    FROM Apttus_Config2__OrderFulfillmentLineItem__c
                    WHERE Apttus_Config2__OrderId__c IN :orderIdSet]);

        return idToAllOFLIMap;
    }
    
    public Apttus_Config2__OrderLineItem__c setOLIStatus(Apttus_Config2__OrderLineItem__c oOrderLineItem, string status)
    {
        oOrderLineItem.APTS_Status__c = status;
        oOrderLineItem.Apttus_Config2__Status__c = status;
        return oOrderLineItem;        
    }
    //V110 ++ <<
    public Apttus_Config2__Order__c setOrderStatus(Apttus_Config2__Order__c oOrder, string status)
    {
        oOrder.APTS_Status__c = status;
        oOrder.Apttus_Config2__Status__c = status;
        return oOrder;        
    } 
    public List<Apttus_Config2__OrderLineItem__c> setAuthorizedDate(List<Apttus_Config2__OrderLineItem__c> lstOLI, Id oLIID, Date dGoodsIssueDate, boolean bReturn)
    {
        Apttus_Config2__OrderLineItem__c objOLI = new Apttus_Config2__OrderLineItem__c();
        objOLI.id = oLIID;
        objOLI.APTS_De_installation_Date_Authorized__c = (bReturn)? dGoodsIssueDate : null;
        objOLI.APTS_Installation_Date_Authorized__c = (bReturn)? null : dGoodsIssueDate;
        lstOLI.add(objOLI);
        return lstOLI;
    }
    public void activateIngredientOrders(Map<id,Apttus_Config2__Order__c> idToOrderMap, Map<id,Apttus_Config2__OrderLineItem__c> orderLineItemToUpdateMap, set<id> sFulfilledOrderIDs)
    {
        Map<Id, Apttus_Config2__OrderLineItem__c> orderLineItemToActivateMap = new Map<Id, Apttus_Config2__OrderLineItem__c>();
        for (Apttus_Config2__Order__c oOrder : idToOrderMap.values()) {

                if (sFulfilledOrderIDs.contains(oOrder.Id) && setStandardOrderTypes.contains(oOrder.APTS_Order_Type__c)) {
                    for (Apttus_Config2__OrderLineItem__c oOrderLineItem : orderLineItemToUpdateMap.values()) {

                        if (oOrder.Id == oOrderLineItem.Apttus_Config2__OrderId__c && oOrderLineItem.Apttus_Config2__LineType__c == 'Product/Service') {
                            Boolean bSubscription = (oOrderLineItem.APTS_Type_of_Contract__c == 'Subscription'); //V126 ++ <<>>
                            oOrderLineItem.Apttus_Config2__ActivatedDate__c = (oOrderLineItem.APTS_Requested_Delivery_Date__c != null) ? oOrderLineItem.APTS_Requested_Delivery_Date__c : DateTime.now();
                            oOrderLineItem.APTS_Status__c = ACTIVATED;
                            //V126 ++ <<
                            if(!bSubscription)
                                orderLineItemToActivateMap.put(oOrderLineItem.Id, oOrderLineItem);
                            else if(bSubscription && oOrderLineItem.Apttus_Config2__IsPrimaryLine__c && oOrderLineItem.Apttus_Config2__LineType__c == 'Product/Service'){
                                orderLineItemToActivateMap.put(oOrderLineItem.Id, oOrderLineItem);
                            } //V126 ++ >>
                        }
                    }
                }
            }
            if (!orderLineItemToActivateMap.isEmpty()) {
                //v121 ++ <<
                //System.enqueueJob(new APTS_ActivateOrderQueueable(orderLineItemToActivateMap.values()));
                System.enqueueJob(new APTS_ActivateOrderQueueable(orderLineItemToActivateMap.values(),null,APTS_CustomErrorLogging.transactionId));
                //v121 ++ >>
            }
    }
    //V110 ++ >>
    //V123 ++ <<
    public boolean checkIfUpdate(Apttus_Config2__OrderLineItem__c oOrderLineItem, Map<Id, Set<Decimal>> mapPrimaryL1Lines)
    {
          boolean bIsUpdate = false;
                    if(oOrderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Type__c == 'Machine Order')
                    {                        
                        Set<Decimal> setLineNumbers = mapPrimaryL1Lines.get(oOrderLineItem.Apttus_Config2__OrderId__c);  
                        bIsUpdate = (setLineNumbers != null && setLineNumbers.contains(oOrderLineItem.Apttus_Config2__LineNumber__c));
                    }
                    else
                    {
                        bIsUpdate = true;
                    }
           return bIsUpdate;    
    }
    public Map<Id, set<Decimal>> getMapOfPrimaryL1Lines(Apttus_Config2__OrderFulfillmentLineItem__c objOFLI,  Map<Id, Apttus_Config2__OrderFulfillmentLineItem__c> mapNewOFLI,Map<Id, Set<Decimal>> mapPrimaryL1Lines)
    {        
                    Decimal lineNo = objOFLI.Apttus_Config2__OrderLineItemId__r.Apttus_Config2__LineNumber__c;                        
                    if(mapNewOFLI.keyset().contains(objOFLI.id) && lineNo != null && objOFLI.Apttus_Config2__OrderId__r.APTS_Order_Type__c == 'Machine Order' && objOFLI.Apttus_Config2__OrderLineItemId__r.APTS_Is_Primary_L1_Line__c)
                    {
                        if(!mapPrimaryL1Lines.isEmpty() && mapPrimaryL1Lines.Keyset().contains(objOFLI.Apttus_Config2__OrderId__c))
                        {
                            Set<Decimal> setLineNumbers = new Set<Decimal>();
                            setLineNumbers = mapPrimaryL1Lines.get(objOFLI.Apttus_Config2__OrderId__c);
                            if(!setLineNumbers.contains(lineNo))
                                setLineNumbers.add(lineNo);
                            mapPrimaryL1Lines.put(objOFLI.Apttus_Config2__OrderId__c, setLineNumbers);  
                        }
                        else
                        {
                            Set<Decimal> setLineNumbers = new Set<Decimal>();
                            setLineNumbers.add(lineNo);
                            mapPrimaryL1Lines.put(objOFLI.Apttus_Config2__OrderId__c, setLineNumbers);
                        }
                    }   
            return mapPrimaryL1Lines;
    }
    //V123 ++ >>
    
}