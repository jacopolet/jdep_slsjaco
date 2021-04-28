/*************************************************************
@Name: APTS_WorkOrderUtils
@Author: Galin Georgiev
@CreateDate: 26-02-2018
@Description: Work Order utils
@UsedBy:
******************************************************************/
//v100 26-02-2018 Galin Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes
//v101.1 10-10-2018 Akanksha : added code for defect 19637
//v102 12-24-2018 Akanksha : Removed DML statements inside loops
//v103 15-03-2018 Nikita : EXTERNAL_MOVEMENT_WITH_CONTRACT_CHANGE Movement Order
//v104 20-06-2019 Aarthi : DOQOM - 284 - Physical Asset mapping on Optional WOT
//v105 25-06-2019 Akanksha : DOK31-263 - Requested Activity date for movement
//v106 20-11-2019 Aarthi : QTCFLEX1-1732 - Refer to Location From for DeInstall WOLI for XA14
//v107 15-4-2021 Aarthi: DQ-5655 - Populate LPlant on WOT

public with sharing class APTS_WorkOrderUtils {

    private static final String OPTION = System.Label.APTS_Option;
    private static final String INSTALLATION = System.Label.APTS_Installation;
    private static final String DE_INSTALLATION = System.Label.APTS_De_installation;
    private static final String DE_INSTALLATIONTS = System.Label.APTS_De_InstallationTS;
    private static final String INTERNAL_MOVEMENT = System.Label.APTS_Internal_Movement;
    private static final String EXTERNAL_MOVEMENT_WITH_CONTRACT_CHANGE = 'External Movement With Contract Change';
    private static final String EXTERNAL_MOVEMENT_WITHOUT_CONTRACT_CHANGE = 'External Movement Without Contract Change';
    private static final String MOVEMENT = System.Label.APTS_Movement;
    private static final String SWAP = System.Label.APTS_Swap;
    private static final String LINE_ITEM = System.Label.APTS_Line_Item;
    private static final String WOT = System.Label.APTS_WOT;
    private static final String HEADER = System.Label.APTS_Header;
    private static final String TECHNICAL_SWAP = 'Technical Swap';
    private static final String COMMERCIAL_SWAP = 'Commercial Swap';
    private static final String XA13 = 'XA13';
    private static final String XB13 = 'XB13';
    private static final String EMAIL = System.Label.APTS_Email;
    private static final String WTYPE_SWAP = 'swap';      

    /*@methodName- createWorkOrders
    *@description- method is used to create Work Order List.
    *@param- String to know the Work Order Type, Order, Order Line Item.
    *@return- List retrieved Work Order List.
    */

    public static List<WorkOrderTrigger__c> createWorkOrders(String sWOTType, Apttus_Config2__Order__c oOrder, List<Apttus_Config2__OrderLineItem__c> orderLineItemList,
            Map<Id, List<Apttus_Config2__OrderLineItem__c>> bundleIdToOptionsMap, Map<Id, APTS_Order_LSP_Details__c> bundleIdToLSPDetailMap) {

        List<WorkOrderTrigger__c> workOrderToCreateList = new List<WorkOrderTrigger__c>();

        //try
        if (sWOTType != null && oOrder != null && orderLineItemList != null) {

            Map<Id, Apttus_Config2__OrderLineItem__c> idToOrderLineItemMap = new Map<Id, Apttus_Config2__OrderLineItem__c>(orderLineItemList);

            if (APTS_OrderConstants.INSTALL.equalsIgnoreCase(sWOTType)) {
                workOrderToCreateList = createWorkOrdersInstallFlow(oOrder, idToOrderLineItemMap, bundleIdToOptionsMap, bundleIdToLSPDetailMap);
            } else if (APTS_OrderConstants.DEINSTALL.equalsIgnoreCase(sWOTType)) {
                workOrderToCreateList = createWorkOrdersDeInstallFlow(oOrder, idToOrderLineItemMap, bundleIdToOptionsMap, bundleIdToLSPDetailMap);
            } else if (APTS_OrderConstants.CONVERSION.equalsIgnoreCase(sWOTType)) {
                workOrderToCreateList = createWorkOrdersConversionFlow(oOrder, idToOrderLineItemMap, bundleIdToOptionsMap, bundleIdToLSPDetailMap);
            } else if (APTS_OrderConstants.MOVEMENT.equalsIgnoreCase(sWOTType)) {
                workOrderToCreateList = createWorkOrdersMovementFlow(oOrder, idToOrderLineItemMap, bundleIdToOptionsMap, bundleIdToLSPDetailMap);
            }
        }
        //} catch (Exception e) {
        //    APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id), 'OM', false, true, EMAIL, true);
        //}

        return workOrderToCreateList;
    }

    /*@methodName- createWorkOrderSwap
    *@description- method is used to swap Work Order List.
    *@param- String to know the Work Order Type, Order, Order Line Item, Parent Order and Order Line Item.
    *@return- List retrieved Work Order List.
    */

    public static List<WorkOrderTrigger__c> createWorkOrderSwap(String sWOTType, Apttus_Config2__Order__c oOrder, List<Apttus_Config2__OrderLineItem__c> curOLIList, Apttus_Config2__Order__c oParentOrder, List<Apttus_Config2__OrderLineItem__c> parentOLIList,
            Map<Id, List<Apttus_Config2__OrderLineItem__c>> bundleIdToOptionsMap, Map<Id, APTS_Order_LSP_Details__c> bundleIdToLSPDetailMap) {

        List<WorkOrderTrigger__c> workOrderToCreateList = new List<WorkOrderTrigger__c>();
        if (sWOTType != null && oOrder != null && curOLIList != null && parentOLIList != null) {
            Map<Id, Apttus_Config2__OrderLineItem__c> idToOrderLineItemMap = new Map<Id, Apttus_Config2__OrderLineItem__c>(parentOLIList);
            Date dPickingDate = getPickingDate(idToOrderLineItemMap, bundleIdToOptionsMap.keySet());

            //create WOTHeader
            WorkOrderTrigger__c oHeaderWOT = createWorkOrderForOrderHeader(oOrder, null, dPickingDate, true);

            //create Deinstall WOT
            WOTOrderWrapper oWrap = createWorkOrdersSwapFlow(oParentOrder, idToOrderLineItemMap, bundleIdToOptionsMap, bundleIdToLSPDetailMap, oHeaderWOT, NULL);
            workOrderToCreateList.addAll(oWrap.listOptionWOT);

            //create install WOT
            idToOrderLineItemMap = new Map<Id, Apttus_Config2__OrderLineItem__c>(curOLIList);
            bundleIdToOptionsMap = prepareBundleIdToOptionsMap(curOLIList);
            bundleIdToLSPDetailMap = prepareBundleIdToLSPDetailMap(bundleIdToOptionsMap.keySet(), idToOrderLineItemMap);
            oWrap = createWorkOrdersSwapFlow(oOrder, idToOrderLineItemMap, bundleIdToOptionsMap, bundleIdToLSPDetailMap, oHeaderWOT, oWrap.oLineItemWOT);
            workOrderToCreateList.addAll(oWrap.listOptionWOT);
        }
        System.debug('--- createWorkOrderSwap end --- ');
        return workOrderToCreateList;
    }



    /*@methodName- createWorkOrdersInstallFlow
    *@description- method is used to Create work order for install order.
    *@param- String to know the Work Order, Order Line Item.
    *@return- List retrieved Work Order List.
    */
    public static List<WorkOrderTrigger__c> createWorkOrdersInstallFlow(Apttus_Config2__Order__c oOrder, Map<Id, Apttus_Config2__OrderLineItem__c> idToOrderLineItemMap, Map<Id, List<Apttus_Config2__OrderLineItem__c>> bundleIdToOptionsMap, Map<Id, APTS_Order_LSP_Details__c> bundleIdToLSPDetailMap) {

        List<WorkOrderTrigger__c> workOrderToCreateList = new List<WorkOrderTrigger__c>();

        Date dPickingDate = getPickingDate(idToOrderLineItemMap, bundleIdToOptionsMap.keySet());
        APTS_Order_LSP_Details__c oLSPDetail;

        Map<Id, WorkOrderTrigger__c> oWorkOrderMap = new Map<Id, WorkOrderTrigger__c>();

        for (Id bundleId : bundleIdToOptionsMap.keySet()) {

            Apttus_Config2__OrderLineItem__c oBundleLineItem = idToOrderLineItemMap.get(bundleId);
            WorkOrderTrigger__c oWorkOrder = new WorkOrderTrigger__c();
            oLSPDetail = bundleIdToLSPDetailMap.get(oBundleLineItem.Id);

            if (oLSPDetail != null) {


                oWorkOrder = createWorkOrderForBundle(oOrder, oBundleLineItem, oLSPDetail, true);
                oWorkOrderMap.put(oBundleLineItem.Id, oWorkOrder);

                workOrderToCreateList.add(oWorkOrder); //++G
            }
        }

        for (Id bundleId : bundleIdToOptionsMap.keySet()) {

            List<Apttus_Config2__OrderLineItem__c> optionLineItemList = bundleIdToOptionsMap.get(bundleId);
            Apttus_Config2__OrderLineItem__c oBundleLineItem = idToOrderLineItemMap.get(bundleId);
            WorkOrderTrigger__c oWorkOrder = oWorkOrderMap.get(oBundleLineItem.Id);
            if (optionLineItemList != null) {
                for (Apttus_Config2__OrderLineItem__c oOptionLineItem : optionLineItemList) {

                    WorkOrderTrigger__c oOptionWorkOrder = createWorkOrderForOption(oOrder, oWorkOrder, oBundleLineItem, oOptionLineItem, true);
                    workOrderToCreateList.add(oOptionWorkOrder);
                }
            }

        }

        if (!workOrderToCreateList.isEmpty()) {
            workOrderToCreateList.add(createWorkOrderForOrderHeader(oOrder, oLSPDetail, dPickingDate, true));
        }

        return workOrderToCreateList;
    }



    /*@methodName- createWorkOrdersDeInstallFlow
    *@description- method is used to Create work orde for de-install order.
    *@param- String to know the Work Order, Order Line Item.
    *@return- List retrieved Work Order List.
    */

    public static List<WorkOrderTrigger__c> createWorkOrdersDeInstallFlow(Apttus_Config2__Order__c oOrder, Map<Id, Apttus_Config2__OrderLineItem__c> idToOrderLineItemMap, Map<Id, List<Apttus_Config2__OrderLineItem__c>> bundleIdToOptionsMap, Map<Id, APTS_Order_LSP_Details__c> bundleIdToLSPDetailMap) {

        List<WorkOrderTrigger__c> workOrderToCreateList = new List<WorkOrderTrigger__c>();

        Date dPickingDate = getPickingDate(idToOrderLineItemMap, bundleIdToOptionsMap.keySet());
        APTS_Order_LSP_Details__c oLSPDetail;

        Map<Id, WorkOrderTrigger__c> oWorkOrderMap = new Map<Id, WorkOrderTrigger__c>();

        for (Id bundleId : bundleIdToOptionsMap.keySet()) {

            WorkOrderTrigger__c oDeInstallWorkOrder = new WorkOrderTrigger__c();
            Apttus_Config2__OrderLineItem__c oBundleLineItem = idToOrderLineItemMap.get(bundleId);
            oLSPDetail = bundleIdToLSPDetailMap.get(oBundleLineItem.Id);

            if (oLSPDetail != null) {

                oDeInstallWorkOrder = createWorkOrderForBundle(oOrder, oBundleLineItem, oLSPDetail, false);
                oWorkOrderMap.put(oBundleLineItem.Id, oDeInstallWorkOrder);

                workOrderToCreateList.add(oDeInstallWorkOrder); //++G
            }
        }

        for (Id bundleId : bundleIdToOptionsMap.keySet()) {
            List<Apttus_Config2__OrderLineItem__c> optionLineItemList = bundleIdToOptionsMap.get(bundleId);
            Apttus_Config2__OrderLineItem__c oBundleLineItem = idToOrderLineItemMap.get(bundleId);
            WorkOrderTrigger__c oDeInstallWorkOrder = oWorkOrderMap.get(oBundleLineItem.Id);
            if (optionLineItemList != null) {
                for (Apttus_Config2__OrderLineItem__c oOptionLineItem : optionLineItemList) {

                    WorkOrderTrigger__c odOptionWorkOrder = createWorkOrderForOption(oOrder, oDeInstallWorkOrder, oBundleLineItem, oOptionLineItem, false);
                    workOrderToCreateList.add(odOptionWorkOrder);

                }
            }
        }

        if (!workOrderToCreateList.isEmpty()) {
            workOrderToCreateList.add(createWorkOrderForOrderHeader(oOrder, oLSPDetail, dPickingDate, false));
        }

        return workOrderToCreateList;
    }



    /*@methodName- createWorkOrdersConversionFlow
    *@description- method is used to Create work orde for conversion order.
    *@param- String to know the Work Order, Bundle Order Line Item.
    *@return- List retrieved Work Order List.
    */

    public static List<WorkOrderTrigger__c> createWorkOrdersConversionFlow(Apttus_Config2__Order__c oOrder, Map<Id, Apttus_Config2__OrderLineItem__c> idToOrderLineItemMap, Map<Id, List<Apttus_Config2__OrderLineItem__c>> bundleIdToOptionsMap, Map<Id, APTS_Order_LSP_Details__c> bundleIdToLSPDetailMap) {

        List<WorkOrderTrigger__c> workOrderToCreateList = new List<WorkOrderTrigger__c>();

        Date dPickingDate = getPickingDate(idToOrderLineItemMap, bundleIdToOptionsMap.keySet());
        APTS_Order_LSP_Details__c oLSPDetail;

        for (Id bundleId : bundleIdToOptionsMap.keySet()) {

            Apttus_Config2__OrderLineItem__c oBundleLineItem = idToOrderLineItemMap.get(bundleId);
            oLSPDetail = bundleIdToLSPDetailMap.get(oBundleLineItem.Id);

            if (oLSPDetail != null && oOrder.APTS_SAP_OrderType__c == XA13) {
                if (oBundleLineItem.Apttus_Config2__LineStatus__c.equalsIgnoreCase(APTS_OrderConstants.AMENDED) ) {

                    List<Apttus_Config2__OrderLineItem__c> optionLineItemList = bundleIdToOptionsMap.get(bundleId);

                    if (optionLineItemList != null) {
                        for (Apttus_Config2__OrderLineItem__c oOptionLineItem : optionLineItemList) {

                            if (oOptionLineItem.Apttus_Config2__LineStatus__c.equalsIgnoreCase(APTS_OrderConstants.LABEL_NEW)) {
                                WorkOrderTrigger__c oOptionWorkOrder = createWorkOrderForBundleConversion(oOrder, oOptionLineItem, oBundleLineItem, oLSPDetail, true);
                                workOrderToCreateList.add(oOptionWorkOrder);
                            } else if (oOptionLineItem.Apttus_Config2__LineStatus__c.equalsIgnoreCase(APTS_OrderConstants.CANCELLED)) {
                                WorkOrderTrigger__c oOptionWorkOrder = createWorkOrderForBundleConversion(oOrder, oOptionLineItem, oBundleLineItem, oLSPDetail, false);
                                workOrderToCreateList.add(oOptionWorkOrder);
                            }
                        }
                    }
                }
            }
        }

        if (!workOrderToCreateList.isEmpty()) {
            workOrderToCreateList.add(createWorkOrderForOrderHeader(oOrder, dPickingDate, true));
        }

        return workOrderToCreateList;
    }


    /*@methodName- createWorkOrdersMovementFlow
    *@description- method is used to Create work orde for internal movement and external movement without contract change.
    *@param- String to know the Work Order, Bundle Order Line Item.
    *@return- List retrieved Work Order List.
    */

    public static List<WorkOrderTrigger__c> createWorkOrdersMovementFlow(Apttus_Config2__Order__c oOrder, Map<Id, Apttus_Config2__OrderLineItem__c> idToOrderLineItemMap, Map<Id, List<Apttus_Config2__OrderLineItem__c>> bundleIdToOptionsMap, Map<Id, APTS_Order_LSP_Details__c> bundleIdToLSPDetailMap) {

        List<WorkOrderTrigger__c> workOrderToCreateList = new List<WorkOrderTrigger__c>();
        Map<Id, WorkOrderTrigger__c> oWorkOrderMapDeInstall = new Map<Id, WorkOrderTrigger__c>();
        Map<Id, WorkOrderTrigger__c> oWorkOrderMapInstall = new Map<Id, WorkOrderTrigger__c>();
        Map<Id, WorkOrderTrigger__c> oWorkOrderMapDeInstallElse = new Map<Id, WorkOrderTrigger__c>();
        Date dPickingDate = getPickingDate(idToOrderLineItemMap, bundleIdToOptionsMap.keySet());
        APTS_Order_LSP_Details__c oLSPDetail;

        for (Id bundleId : bundleIdToOptionsMap.keySet()) {

            Apttus_Config2__OrderLineItem__c oBundleLineItem = idToOrderLineItemMap.get(bundleId);
            oLSPDetail = bundleIdToLSPDetailMap.get(oBundleLineItem.Id);

            if (oLSPDetail != null) {
               // if (oOrder.APTS_Order_Sub_Type__c == INTERNAL_MOVEMENT || oOrder.APTS_Order_Sub_Type__c == EXTERNAL_MOVEMENT_WITHOUT_CONTRACT_CHANGE) {

                    WorkOrderTrigger__c oDeInstallWorkOrder;
                    oLSPDetail.APTS_Require_De_Installation__c = true;
                    oLSPDetail.APTS_Require_Installation__c = true;
                    if (oLSPDetail.APTS_Require_De_Installation__c) {
                        oDeInstallWorkOrder = createWorkOrderForBundle(oOrder, oBundleLineItem, oLSPDetail, false);
                        oWorkOrderMapDeInstall.put(oBundleLineItem.Id, oDeInstallWorkOrder);

                        workOrderToCreateList.add(oDeInstallWorkOrder); //++G
                    }
                    if (oLSPDetail.APTS_Require_Installation__c || oOrder.APTS_Require_Installation__c) {
                        WorkOrderTrigger__c oWorkOrder = createWorkOrderForBundle(oOrder, oBundleLineItem, oLSPDetail, true);
                        oWorkOrder.DependentDeInstallation__c = oDeInstallWorkOrder != null ? oDeInstallWorkOrder.Id : null;
                        oWorkOrderMapInstall.put(oBundleLineItem.Id, oWorkOrder);

                        workOrderToCreateList.add(oWorkOrder); //++G
                    }
                /*}else {
                    WorkOrderTrigger__c oDeInstallWorkOrder = createWorkOrderForBundle(oOrder, oBundleLineItem, oLSPDetail, false);
                    oWorkOrderMapDeInstallElse.put(oBundleLineItem.Id, oDeInstallWorkOrder);

                    workOrderToCreateList.add(oDeInstallWorkOrder); 
                } */
            }
        }
        
        /*for (Id bundleId : bundleIdToOptionsMap.keySet()) {

            Apttus_Config2__OrderLineItem__c oBundleLineItem = idToOrderLineItemMap.get(bundleId);
            oLSPDetail = bundleIdToLSPDetailMap.get(oBundleLineItem.Id);
            List<Apttus_Config2__OrderLineItem__c> optionLineItemList = bundleIdToOptionsMap.get(bundleId);

            if (oLSPDetail != null && optionLineItemList != null) {
                if (oOrder.APTS_Order_Sub_Type__c == INTERNAL_MOVEMENT || oOrder.APTS_Order_Sub_Type__c == EXTERNAL_MOVEMENT_WITHOUT_CONTRACT_CHANGE ||
                 oOrder.APTS_Order_Sub_Type__c == EXTERNAL_MOVEMENT_WITH_CONTRACT_CHANGE ) { //v103
                    WorkOrderTrigger__c oDeInstallWorkOrder;

                    if (oLSPDetail.APTS_Require_De_Installation__c) {
                        oDeInstallWorkOrder = oWorkOrderMapDeInstall.get(oBundleLineItem.Id);
                        for (Apttus_Config2__OrderLineItem__c oOptionLineItem : optionLineItemList) {

                            WorkOrderTrigger__c oOptionWorkOrder = createWorkOrderForOption(oOrder, oDeInstallWorkOrder, oBundleLineItem, oOptionLineItem, false);
                            workOrderToCreateList.add(oOptionWorkOrder);
                        }
                    }
                    if (oLSPDetail.APTS_Require_Installation__c || oOrder.APTS_Require_Installation__c) {
                        WorkOrderTrigger__c oWorkOrder = oWorkOrderMapInstall.get(oBundleLineItem.Id);

                        for (Apttus_Config2__OrderLineItem__c oOptionLineItem : optionLineItemList) {

                            WorkOrderTrigger__c oOptionWorkOrder = createWorkOrderForOption(oOrder, oWorkOrder, oBundleLineItem, oOptionLineItem, true);
                            workOrderToCreateList.add(oOptionWorkOrder);
                        }
                    }

                } else {
                    WorkOrderTrigger__c oDeInstallWorkOrder = oWorkOrderMapDeInstallElse.get(oBundleLineItem.Id);
                    for (Apttus_Config2__OrderLineItem__c oOptionLineItem : optionLineItemList) {

                        WorkOrderTrigger__c oOptionWorkOrder = createWorkOrderForOption(oOrder, oDeInstallWorkOrder, oBundleLineItem, oOptionLineItem, false);
                        workOrderToCreateList.add(oOptionWorkOrder);
                    }

                }
            }
        }*/
        
        if (!workOrderToCreateList.isEmpty()) {
            workOrderToCreateList.add(createWorkOrderForOrderHeader(oOrder, oLSPDetail, dPickingDate, true));
        }

        return workOrderToCreateList;
    }

    /*@methodName- createWorkOrdersSwapFlow
    *@description- method is used to Create work order for swap flow.
    *@param- String to know the Work Order, Bundle Order Line Item.
    *@return- List retrieved Work Order List.
    */

    public static WOTOrderWrapper createWorkOrdersSwapFlow(Apttus_Config2__Order__c oOrder, Map<Id, Apttus_Config2__OrderLineItem__c> idToOrderLineItemMap, Map<Id, List<Apttus_Config2__OrderLineItem__c>> bundleIdToOptionsMap, Map<Id, APTS_Order_LSP_Details__c> bundleIdToLSPDetailMap,  WorkOrderTrigger__c oHeaderWOT, WorkOrderTrigger__c oParentWorkOrderLI) {
        System.debug('--- APTS_WorkOrderUtils createWorkOrdersSwapFlow start ---  ');
        List<WorkOrderTrigger__c> workOrderToCreateList = new List<WorkOrderTrigger__c>();
        WOTOrderWrapper oWrap = new WOTOrderWrapper();
        Boolean isInstall = oParentWorkOrderLI == NULL ? false : true;

        Map<Id, WorkOrderTrigger__c> oWorkOrderMap = new Map<Id, WorkOrderTrigger__c>();

        //create WOTOptions installation Order
        for (Id bundleId : bundleIdToOptionsMap.keySet()) {
            WorkOrderTrigger__c oWorkOrder = new WorkOrderTrigger__c();
            Apttus_Config2__OrderLineItem__c oBundleLineItem = idToOrderLineItemMap.get(bundleId);
            APTS_Order_LSP_Details__c oLSPDetail = bundleIdToLSPDetailMap.get(oBundleLineItem.Id);

            if (oLSPDetail != null) {

                oWorkOrder = createWorkOrderForBundle(oOrder, oBundleLineItem, oLSPDetail, isInstall);
                oWorkOrder.ParentHeader__c = oHeaderWOT.Id;
                oWorkOrder.Load_ID__c = WOT + oOrder.Id; //++G

                oWorkOrder.DependentDeInstallation__c = oParentWorkOrderLI != NULL ? oParentWorkOrderLI.Id : NULL;
                oWorkOrderMap.put(oBundleLineItem.Id, oWorkOrder);

                workOrderToCreateList.add(oWorkOrder);
            }
        }

        for (Id bundleId : bundleIdToOptionsMap.keySet()) {
            Apttus_Config2__OrderLineItem__c oBundleLineItem = idToOrderLineItemMap.get(bundleId);
            WorkOrderTrigger__c oWorkOrder = oWorkOrderMap.get(oBundleLineItem.Id);
            oWrap.oLineItemWOT = oWorkOrder;
            List<Apttus_Config2__OrderLineItem__c> optionLineItemList = bundleIdToOptionsMap.get(bundleId);
            if (optionLineItemList != null) {

                for (Apttus_Config2__OrderLineItem__c oOptionLineItem : optionLineItemList) {

                    WorkOrderTrigger__c oOptionWorkOrder = createWorkOrderForOption(oOrder, oWorkOrder, oBundleLineItem, oOptionLineItem, isInstall);
                    oOptionWorkOrder.ParentHeader__c = oHeaderWOT.Id;
                    System.debug('oOptionWorkOrder = ' + oOptionWorkOrder);
                    workOrderToCreateList.add(oOptionWorkOrder);
                }
            }

        }

        System.debug('workOrderToCreateList = ' + workOrderToCreateList);
        System.debug('--- APTS_WorkOrderUtils createWorkOrdersSwapFlow start ---  ');

        oWrap.listOptionWOT = workOrderToCreateList;
        return oWrap;
    }


    /*@methodName- prepareBundleIdToOptionsMap
    *@description- method is used to Prepare map of Bundle which is Primary L1 and List of Options which are Relevant for SAP.
    *@param- String to know the Order Line Item List.
    *@return- List retrieved Work Line Item List.
    */

    public static Map<Id, List<Apttus_Config2__OrderLineItem__c>> prepareBundleIdToOptionsMap(List<Apttus_Config2__OrderLineItem__c> orderLineItemList) {

        Map<Id, List<Apttus_Config2__OrderLineItem__c>> bundleIdToOptionsMap = new Map<Id, List<Apttus_Config2__OrderLineItem__c>>();

        Map<Decimal, Apttus_Config2__OrderLineItem__c> lineNumberToPrimaryOrderLineItem = new Map<Decimal, Apttus_Config2__OrderLineItem__c>();
        Map<Decimal, List<Apttus_Config2__OrderLineItem__c>> lineNumberToOptionsMap = new Map<Decimal, List<Apttus_Config2__OrderLineItem__c>>();

        for (Apttus_Config2__OrderLineItem__c orderLineItem : orderLineItemList) {
            if (orderLineItem.APTS_Is_Primary_L1_Line__c) {
                lineNumberToPrimaryOrderLineItem.put(orderLineItem.Apttus_Config2__LineNumber__c, orderLineItem);
            } else if (orderLineItem.Apttus_Config2__LineType__c == OPTION && orderLineItem.APTS_Item_Relevant_for_SAP__c) {

                List<Apttus_Config2__OrderLineItem__c> tmpOptionsList = lineNumberToOptionsMap.get(orderLineItem.Apttus_Config2__LineNumber__c);
                if (tmpOptionsList == null) {
                    tmpOptionsList = new List<Apttus_Config2__OrderLineItem__c>();
                    lineNumberToOptionsMap.put(orderLineItem.Apttus_Config2__LineNumber__c, tmpOptionsList);
                }
                tmpOptionsList.add(orderLineItem);
            }
        }

        for (Decimal lineNumber : lineNumberToPrimaryOrderLineItem.keySet()) {
            Apttus_Config2__OrderLineItem__c oBundle = lineNumberToPrimaryOrderLineItem.get(lineNumber);
            bundleIdToOptionsMap.put(oBundle.Id, lineNumberToOptionsMap.get(lineNumber));
        }

        return bundleIdToOptionsMap;
    }



    /*@methodName- prepareBundleIdToLSPDetailMap
    *@description- method is used to Prepare map of Bundle which is Primary L1 and LSP Details for this bundle.
    *@param- String to know the Order Line Item List.
    *@return- List retrieved Bundle Order List.
    */
    public static Map<Id, APTS_Order_LSP_Details__c> prepareBundleIdToLSPDetailMap(Set<Id> bundleIdSet, Map<Id, Apttus_Config2__OrderLineItem__c> idToOrderLineItemMap) {

        Map<Id, APTS_Order_LSP_Details__c> bundleIdToLSPDetailMap = new Map<Id, APTS_Order_LSP_Details__c>();
        Set<Id> lspDetailIdSet = new Set<Id>();

        for (Id bundleId : bundleIdSet) {
            Apttus_Config2__OrderLineItem__c oOrderLineItem = idToOrderLineItemMap.get(bundleId);

            lspDetailIdSet.add(oOrderLineItem.APTS_Order_LSP_Detail__c);
        }


         Map<Id, APTS_Order_LSP_Details__c> idToLSPDetailMap = new Map<Id, APTS_Order_LSP_Details__c>([
                    SELECT Id, APTS_Subject__c, APTS_LSP_Description__c,APTS_isProject__c,APTS_Project_Number__c,APTS_Schedule_Exceptions__c,APTS_Second_Service_Contact__c,
                    APTS_PlugPlay__c, APTS_Workshop__c, APTS_Deinstall_NonJDEMachine__c, APTS_Stopover__c,APTS_CollectCounters__c,
                    APTS_RefurbishedMachine__c, APTS_CommercialMachine__c, APTS_SmokingArea__c, APTS_OwnedByCustomer__c,
                    APTS_Building__c, APTS_Floor__c, APTS_Area__c, APTS_CustomerReference__c,
                    APTS_From_Building__c, APTS_From_Floor__c, APTS_From_Area__c,
                    APTS_StairClimber__c, APTS_Requires_LSP__c, APTS_ConfigurationFileURL__c, APTS_ConfigurationManualAgreementsURL__c,
                    APTS_JDE_crockeryVolumeSize__c, APTS_IncludesWaterfilterCoverage__c,
                    APTS_Require_Installation__c, APTS_Require_De_Installation__c, APTS_From_ShipTo_Location__c, APTS_Installation_Contact__c
                    FROM APTS_Order_LSP_Details__c
                    WHERE Id IN :lspDetailIdSet LIMIT 50000]);

        for (Id bundleId : bundleIdSet) {
            Apttus_Config2__OrderLineItem__c oOrderLineItem = idToOrderLineItemMap.get(bundleId);

            if (oOrderLineItem.APTS_Order_LSP_Detail__c != null) {
                APTS_Order_LSP_Details__c oLSPDetails = idToLSPDetailMap.get(oOrderLineItem.APTS_Order_LSP_Detail__c);
                bundleIdToLSPDetailMap.put(bundleId, oLSPDetails);
            }
        }

        return bundleIdToLSPDetailMap;
    }

    /*@methodName- getPickingDate
    *@description- method is used to get the Picking Date.
    *@param- String to know the Order Line Item Map and Bundle Id.
    *@return- Picking date.
    */

    public static Date getPickingDate(Map<Id, Apttus_Config2__OrderLineItem__c> idToOrderLineItemMap, Set<Id> bundleIdSet) {

        Date dPickingDate = null;
        List<Date> materialAvailabilityDateList = new List<Date>();
        system.debug('materialAvailabilityDateList ' + materialAvailabilityDateList);
        for (Id bundleId : bundleIdSet) {

            Date dMaterialAvailabilityDate = idToOrderLineItemMap.get(bundleId).APTS_Material_Availability_Date__c;
            system.debug('materialAvailabilityDateList ' + materialAvailabilityDateList);

            if (dMaterialAvailabilityDate != null) {
                materialAvailabilityDateList.add(dMaterialAvailabilityDate);
            }
        }
        system.debug('materialAvailabilityDateList ' + materialAvailabilityDateList);
        materialAvailabilityDateList.sort();
        Integer iSize = materialAvailabilityDateList.size();
        if (iSize != 0) {
            dPickingDate = materialAvailabilityDateList.get(0);
        }
        system.debug('dPickingDate' + dPickingDate);
        return dPickingDate;
    }

    /*@methodName- createWorkOrderForBundle
    *@description- method is used to get the Work Order Bundle.
    *@param- String to know the Order, Order Line Item.
    *@return- Bundle Work Order.
    */

    public static WorkOrderTrigger__c createWorkOrderForBundle(Apttus_Config2__Order__c oOrder, Apttus_Config2__OrderLineItem__c orderLineItem, APTS_Order_LSP_Details__c oLSPDetail, Boolean isInstall) {

        WorkOrderTrigger__c oWorkOrder = new WorkOrderTrigger__c();

        oWorkOrder.Subject__c = oLSPDetail.APTS_Subject__c;
        oWorkOrder.Description__c = oLSPDetail.APTS_LSP_Description__c;
        oWorkOrder.OrderType__c = getOrderType(oOrder.APTS_Order_Sub_Type__c);
        oWorkOrder.Type__c = LINE_ITEM;
        oWorkOrder.Product__c = orderLineItem.Apttus_Config2__ProductId__c;
        //V106 ++ <<
        //oWorkOrder.AccountLocation__c = oOrder.Apttus_Config2__LocationId__c;        
        oWorkOrder.AccountLocation__c = (getOrderType(oOrder.APTS_Order_Sub_Type__c) == MOVEMENT && !isInstall) ? oOrder.APTS_Location_From__c : oOrder.Apttus_Config2__LocationId__c;
        //V106 ++ >>
        oWorkOrder.PlugPlay__c = oLSPDetail.APTS_PlugPlay__c;
        oWorkOrder.Workshop__c = oLSPDetail.APTS_Workshop__c;
        oWorkOrder.Deinstall_NonJDEMachine__c = oLSPDetail.APTS_Deinstall_NonJDEMachine__c;
        oWorkOrder.Stopover__c = oLSPDetail.APTS_Stopover__c;
        oWorkOrder.RefurbishedMachine__c = oLSPDetail.APTS_RefurbishedMachine__c;
        oWorkOrder.CommercialMachine__c = oLSPDetail.APTS_CommercialMachine__c;
        oWorkOrder.SmokingArea__c = oLSPDetail.APTS_SmokingArea__c;
        oWorkOrder.OwnedByCustomer__c = oLSPDetail.APTS_OwnedByCustomer__c;
        oWorkOrder.CustomerReference__c = oLSPDetail.APTS_CustomerReference__c;
        oWorkOrder.OrderLineItem__c = orderLineItem.Id;
        oWorkOrder.ParentOrder__c = oOrder.Id;
        oWorkOrder.PhysicalAsset__c = orderLineItem.APTS_Physical_Asset__c;
        oWorkOrder.StairClimber__c = oLSPDetail.APTS_StairClimber__c;
        oWorkOrder.Requires_LSP__c = oLSPDetail.APTS_Requires_LSP__c;
        oWorkOrder.ConfigurationFileURL__c = oLSPDetail.APTS_ConfigurationFileURL__c;
        oWorkOrder.ConfigurationManualAgreementsURL__c = oLSPDetail.APTS_ConfigurationManualAgreementsURL__c;
        oWorkOrder.JDE_crockeryVolumeSize__c = oLSPDetail.APTS_JDE_crockeryVolumeSize__c;
        //v105 << ++
        Datetime mDt = null;
        if(oOrder.APTS_Requested_Movement_Date__c != null){
            mDt = oOrder.APTS_Requested_Movement_Date__c;
        }
        oWorkOrder.RequestedActivityDate__c = getOrderType(oOrder.APTS_Order_Sub_Type__c) == MOVEMENT ? Date.newinstance(mDt.year(),mDt.month(),mDt.day()) : (isInstall ? oOrder.APTS_Requested_Installation_Date__c : oOrder.APTS_Requested_De_Installation_Date__c.date());
        //v105 ++ >>
        oWorkOrder.SalesOrganization__c = oOrder.APTS_Sales_Organization__c;
        oWorkOrder.OrderSubType__c = !isInstall ? DE_INSTALLATIONTS : INSTALLATION;
        oWorkOrder.IncludesWaterfilterCoverage__c = oLSPDetail.APTS_IncludesWaterfilterCoverage__c;
        oWorkOrder.Load_ID__c = WOT + orderLineItem.Id;
        oWorkOrder.ScheduleExceptions__c = oOrder.APTS_Manual_Scheduling__c;
        //v101.1 ++ <<
        oWorkOrder.PlugPlay__c = orderLineItem.APTS_PlugPlay__c;
        //v101.1 ++ >>
        oWorkOrder.Machine_care__c = getMachineCareValue(oWorkOrder, orderLineItem);
        oWorkOrder.L_Plant_Code__c = orderLineItem.APTS_Plant_Code__c; //v107 ++ <<>>
        
        system.debug('---------oWorkOrder Bundle' + oWorkOrder.Machine_care__c);
         if (oOrder.APTS_Order_Sub_Type__c == INTERNAL_MOVEMENT && !isInstall) {
            oWorkOrder.Building__c = oLSPDetail.APTS_From_Building__c;
            oWorkOrder.Floor__c = oLSPDetail.APTS_From_Floor__c;
            oWorkOrder.Area__c = oLSPDetail.APTS_From_Area__c;
        } else if ((oOrder.APTS_Order_Sub_Type__c == EXTERNAL_MOVEMENT_WITHOUT_CONTRACT_CHANGE || oOrder.APTS_Order_Sub_Type__c == EXTERNAL_MOVEMENT_WITH_CONTRACT_CHANGE) && isInstall) {
            //From Movement Screen Input
            //oWorkOrder.AccountLocation__c = oOrder.Apttus_Config2__LocationId__c;
            oWorkOrder.Building__c=oLSPDetail.APTS_Building__c;
            oWorkOrder.Area__c=oLSPDetail.APTS_Area__c;
            oWorkOrder.Floor__c=oLSPDetail.APTS_Floor__c;
            oWorkOrder.CommercialMachine__c=oLSPDetail.APTS_CommercialMachine__c;
            oWorkOrder.Requires_LSP__c=oLSPDetail.APTS_Requires_LSP__c;
            oWorkOrder.StairClimber__c=oLSPDetail.APTS_StairClimber__c;
            oWorkOrder.CustomerReference__c=oLSPDetail.APTS_CustomerReference__c;
            oWorkOrder.SmokingArea__c=oLSPDetail.APTS_SmokingArea__c;
            oWorkOrder.JDE_crockeryVolumeSize__c=oLSPDetail.APTS_JDE_crockeryVolumeSize__c;

            // From Bundle Detail COnfiguration
            oWorkOrder.IsProject__c = oLSPDetail.APTS_isProject__c;
            oWorkOrder.ProjectNumber__c =oLSPDetail.APTS_Project_Number__c;
            oWorkOrder.OwnedByCustomer__c=oLSPDetail.APTS_OwnedByCustomer__c;
            oWorkOrder.ServiceContact__c=oLSPDetail.APTS_Installation_Contact__c;
            oWorkOrder.AdditionalServiceContact__c=oLSPDetail.APTS_Second_Service_Contact__c;
            oWorkOrder.CollectCounters__c=oLSPDetail.APTS_CollectCounters__c;
            oWorkOrder.ExternalMovement__c = true;
            

        } else if ((oOrder.APTS_Order_Sub_Type__c == EXTERNAL_MOVEMENT_WITHOUT_CONTRACT_CHANGE || oOrder.APTS_Order_Sub_Type__c == EXTERNAL_MOVEMENT_WITH_CONTRACT_CHANGE) && !isInstall) {
                        
            //oWorkOrder.AccountLocation__c = orderLineItem.APTS_Physical_Asset__r.AccountLocation__c;
           /* oWorkOrder.Building__c=orderLineItem.APTS_Physical_Asset__r.Building__c;
            oWorkOrder.Area__c=orderLineItem.APTS_Physical_Asset__r.Area__c;
            oWorkOrder.Floor__c=orderLineItem.APTS_Physical_Asset__r.Floor__c; */
            //V106 ++ <<
            oWorkOrder.Building__c = oLSPDetail.APTS_From_Building__c; 
            oWorkOrder.Floor__c = oLSPDetail.APTS_From_Floor__c;
            oWorkOrder.Area__c = oLSPDetail.APTS_From_Area__c;
            //V106 ++ >>
            oWorkOrder.OwnedByCustomer__c=orderLineItem.APTS_Physical_Asset__r.OwnedByCustomer__c;
            oWorkOrder.StairClimber__c=orderLineItem.APTS_Physical_Asset__r.StairClimber__c;
            oWorkOrder.CustomerReference__c=orderLineItem.APTS_Physical_Asset__r.CustomerReferenceNumber__c;
            oWorkOrder.SmokingArea__c=orderLineItem.APTS_Physical_Asset__r.SmokingArea__c;
            oWorkOrder.JDE_crockeryVolumeSize__c=orderLineItem.APTS_Physical_Asset__r.JDECrockeryVolumeSize__c;
            oWorkOrder.Requires_LSP__c=orderLineItem.APTS_Physical_Asset__r.RequiresLSP__c;
            oWorkOrder.CommercialMachine__c=orderLineItem.APTS_Physical_Asset__r.CommercialUsage__c;
            oWorkOrder.ServiceContact__c=orderLineItem.APTS_Physical_Asset__r.AccountLocation__r.Main_Service_Contact__c;
            oWorkOrder.ConfigurationManualAgreementsURL__c =orderLineItem.APTS_Physical_Asset__r.ConfigurationManualAgreementsURL__c;

            // From Bundle Detail COnfiguration
            oWorkOrder.IsProject__c = oLSPDetail.APTS_isProject__c;
            oWorkOrder.ProjectNumber__c =oLSPDetail.APTS_Project_Number__c;
            oWorkOrder.CollectCounters__c=oLSPDetail.APTS_CollectCounters__c;
            oWorkOrder.ExternalMovement__c = true;
                    
           
        } else {
            oWorkOrder.Building__c = oLSPDetail.APTS_Building__c;
            oWorkOrder.Floor__c = oLSPDetail.APTS_Floor__c;
            oWorkOrder.Area__c = oLSPDetail.APTS_Area__c;
        }

        return oWorkOrder;
    }

    /*@methodName- createWorkOrderForBundleConversion
    *@description- method is used to get the Work Order Bundle Conversion.
    *@param- String to know the Order, Order Line Item.
    *@return- Bundle Work Order Conversion.
    */

    public static WorkOrderTrigger__c createWorkOrderForBundleConversion(Apttus_Config2__Order__c oOrder, Apttus_Config2__OrderLineItem__c orderLineItem, Apttus_Config2__OrderLineItem__c bundleLineItem, APTS_Order_LSP_Details__c oLSPDetail, Boolean isInstall) {

        WorkOrderTrigger__c oWorkOrder = new WorkOrderTrigger__c();

        oWorkOrder.Subject__c = oLSPDetail.APTS_Subject__c;
        oWorkOrder.Description__c = oLSPDetail.APTS_LSP_Description__c;
        oWorkOrder.OrderType__c = getOrderType(oOrder.APTS_Order_Sub_Type__c);
        oWorkOrder.Type__c = LINE_ITEM;
        oWorkOrder.Product__c = orderLineItem.Apttus_Config2__OptionId__c;
        oWorkOrder.AccountLocation__c =  oOrder.Apttus_Config2__LocationId__c;
        oWorkOrder.PlugPlay__c = oLSPDetail.APTS_PlugPlay__c;
        oWorkOrder.Workshop__c = oLSPDetail.APTS_Workshop__c;
        oWorkOrder.Deinstall_NonJDEMachine__c = oLSPDetail.APTS_Deinstall_NonJDEMachine__c;
        oWorkOrder.Stopover__c = oLSPDetail.APTS_Stopover__c;
        oWorkOrder.RefurbishedMachine__c = oLSPDetail.APTS_RefurbishedMachine__c;
        oWorkOrder.CommercialMachine__c = oLSPDetail.APTS_CommercialMachine__c;
        oWorkOrder.SmokingArea__c = oLSPDetail.APTS_SmokingArea__c;
        oWorkOrder.OwnedByCustomer__c = oLSPDetail.APTS_OwnedByCustomer__c;
        oWorkOrder.Building__c = oLSPDetail.APTS_Building__c;
        oWorkOrder.Floor__c = oLSPDetail.APTS_Floor__c;
        oWorkOrder.Area__c = oLSPDetail.APTS_Area__c;
        oWorkOrder.CustomerReference__c = oLSPDetail.APTS_CustomerReference__c;
        oWorkOrder.OrderLineItem__c = orderLineItem.Id;
        oWorkOrder.ParentOrder__c = oOrder.Id;
        oWorkOrder.PhysicalAsset__c = bundleLineItem.APTS_Physical_Asset__c;
        oWorkOrder.StairClimber__c = oLSPDetail.APTS_StairClimber__c;
        oWorkOrder.Requires_LSP__c = oLSPDetail.APTS_Requires_LSP__c;
        oWorkOrder.ConfigurationFileURL__c = oLSPDetail.APTS_ConfigurationFileURL__c;
        oWorkOrder.ConfigurationManualAgreementsURL__c = oLSPDetail.APTS_ConfigurationManualAgreementsURL__c;
        oWorkOrder.JDE_crockeryVolumeSize__c = oLSPDetail.APTS_JDE_crockeryVolumeSize__c;
        oWorkOrder.RequestedActivityDate__c = (isInstall) ? oOrder.APTS_Requested_Installation_Date__c : oOrder.APTS_Requested_De_Installation_Date__c.date();
        oWorkOrder.SalesOrganization__c = oOrder.APTS_Sales_Organization__c;
        oWorkOrder.OrderSubType__c =  !isInstall ? DE_INSTALLATIONTS : INSTALLATION;
        oWorkOrder.IncludesWaterfilterCoverage__c = oLSPDetail.APTS_IncludesWaterfilterCoverage__c;
        oWorkOrder.ScheduleExceptions__c = oOrder.APTS_Manual_Scheduling__c;
        oWorkOrder.Load_ID__c = WOT + orderLineItem.Id;
        //v101.1 ++ <<
        oWorkOrder.PlugPlay__c = orderLineItem.APTS_PlugPlay__c;
        //v101.1 ++ >>
        oWorkOrder.Machine_care__c = getMachineCareValue(oWorkOrder, orderLineItem);
        return oWorkOrder;
    }

    /*@methodName- createWorkOrderForOption
    *@description- method is used to get the Work Order For Options.
    *@param- String to know the Order, Order Line Item.
    *@return- Work Order For Option.
    */

    public static WorkOrderTrigger__c createWorkOrderForOption(Apttus_Config2__Order__c oOrder, WorkOrderTrigger__c oBundleWorkOrder, Apttus_Config2__OrderLineItem__c oBundleLineItem, Apttus_Config2__OrderLineItem__c orderLineItem, Boolean isInstall) {

        WorkOrderTrigger__c oWorkOrder = new WorkOrderTrigger__c();

        oWorkOrder.OrderType__c = getOrderType(oOrder.APTS_Order_Sub_Type__c);
        oWorkOrder.Type__c = OPTION;
        oWorkOrder.Product__c = orderLineItem.Apttus_Config2__OptionId__c;        
        oWorkOrder.OwnedByCustomer__c = oBundleWorkOrder.OwnedByCustomer__c;
        oWorkOrder.OrderLineItem__c = orderLineItem.Id;
        oWorkOrder.ParentLineItem__c = oBundleWorkOrder.Id;
        oWorkOrder.ParentOrder__c = oOrder.Id;
        oWorkOrder.PhysicalAsset__c = orderLineItem.APTS_Physical_Asset__c; //V104 ++ << oBundleLineItem.APTS_Physical_Asset__c;
        //oWorkOrder.Load_ID__c = WOT + orderLineItem.Id;
        oWorkOrder.Load_ID__c = WOT + oBundleLineItem.Id; //G++
        oWorkOrder.SalesOrganization__c = oOrder.APTS_Sales_Organization__c;
        oWorkOrder.OrderSubType__c =  !isInstall ? DE_INSTALLATIONTS : INSTALLATION;
        oWorkOrder.ScheduleExceptions__c = oOrder.APTS_Manual_Scheduling__c;
        //v101.1 ++ <<
        oWorkOrder.PlugPlay__c = orderLineItem.APTS_PlugPlay__c;
        //v101.1 ++ >>
        oWorkOrder.Machine_care__c = getMachineCareValue(oWorkOrder, orderLineItem);
        system.debug('---------oWorkOrder Option' + oWorkOrder.Machine_care__c);
        oWorkOrder.L_Plant_Code__c = orderLineItem.APTS_Plant_Code__c; //v107 ++ <<>>
        return oWorkOrder;
    }

    /*@methodName- createWorkOrderForOrderHeader
    *@description- method is used to get the Work Order Header.
    *@param- String to know the Order, Order Line Item.
    *@return- Work Order Header.
    */
    public static WorkOrderTrigger__c createWorkOrderForOrderHeader(Apttus_Config2__Order__c oOrder, APTS_Order_LSP_Details__c oLSPDetail, Date dPickingDate, Boolean isInstall) {

        WorkOrderTrigger__c oWorkOrder = new WorkOrderTrigger__c();

        oWorkOrder.Subject__c = oOrder.APTS_Subject__c;
        oWorkOrder.Description__c = oOrder.APTS_LSP_Description__c;
        oWorkOrder.OrderType__c = getOrderType(oOrder.APTS_Order_Sub_Type__c);
        oWorkOrder.Type__c = HEADER;
        oWorkOrder.ServiceContact__c = oOrder.Apttus_Config2__PrimaryContactId__c;
        oWorkOrder.ProjectNumber__c = oOrder.APTS_ProjectNumber__c;
        oWorkOrder.IsProject__c = oOrder.APTS_IsProject__c;
        //v105 << ++
        Datetime mDt = null;
        if(oOrder.APTS_Requested_Movement_Date__c != null){
            mDt = oOrder.APTS_Requested_Movement_Date__c;
        }
        oWorkOrder.RequestedActivityDate__c = getOrderType(oOrder.APTS_Order_Sub_Type__c) == MOVEMENT ? Date.newinstance(mDt.year(),mDt.month(),mDt.day()) : (isInstall ? oOrder.APTS_Requested_Installation_Date__c : oOrder.APTS_Requested_De_Installation_Date__c.date());
        //v105 ++ >>
        oWorkOrder.ScheduleExceptions__c = oOrder.APTS_ScheduleExceptions__c;
        oWorkOrder.ParentOrder__c = oOrder.Id;
        oWorkOrder.SalesOrganization__c = oOrder.APTS_Sales_Organization__c;
        oWorkOrder.AdditionalServiceContact__c = oOrder.APTS_ServiceContact__c;
        //oWorkOrder.ChildOrder__c = first order
        oWorkOrder.Load_ID__c = WOT + oOrder.Id;
        oWorkOrder.PickingDate__c = dPickingDate;
        oWorkOrder.AccountLocation__c = oOrder.Apttus_Config2__LocationId__c;
        oWorkOrder.ScheduleExceptions__c = oOrder.APTS_Manual_Scheduling__c;

        String sPONumber = oOrder.Apttus_Config2__PONumber__c;
        if (String.isNotBlank(sPONumber)) {
            if (sPONumber.length() > 80) {
                sPONumber = sPONumber.substring(0, 79);
            }
        }
        oWorkOrder.PO_Number__c = sPONumber;
        oWorkOrder.GenerateServiceOrder__c = true;
        oWorkOrder.PotentialRoundTrip__c = false;

        //commercial swap, Deinstall Order should be mapped with ChildOrder__c and installation Order should be mapped with ParentOrder__c
        if (COMMERCIAL_SWAP.equalsIgnoreCase(oOrder.APTS_Order_Sub_Type__c)) {
            oWorkOrder.ParentOrder__c = oOrder.Apttus_Config2__ParentOrderId__c;
            oWorkOrder.ChildOrder__c = oOrder.Id;
            oWorkOrder.GenerateServiceOrder__c = false;
        }
        // External Order Movement HEADER from Bundle Detail Page During Cart COnfiguration
        if (oOrder.APTS_Order_Sub_Type__c == EXTERNAL_MOVEMENT_WITHOUT_CONTRACT_CHANGE || oOrder.APTS_Order_Sub_Type__c == EXTERNAL_MOVEMENT_WITH_CONTRACT_CHANGE) {
            oWorkOrder.ServiceContact__c = oLSPDetail.APTS_Installation_Contact__c;
            oWorkOrder.AdditionalServiceContact__c = oLSPDetail.APTS_Second_Service_Contact__c;
            oWorkOrder.IsProject__c = oLSPDetail.APTS_isProject__c;
            oWorkOrder.ProjectNumber__c = oLSPDetail.APTS_Project_Number__c;
            oWorkOrder.ScheduleExceptions__c = oLSPDetail.APTS_Schedule_Exceptions__c;
            oWorkOrder.ExternalMovement__c = true;
        }

        return oWorkOrder;
    }

    /*@methodName- createWorkOrderForOrderHeader
    *@description- method is used to get the Work Order Header.
    *@param- String to know the Order, Order Line Item.
    *@return- Work Order Header.
    */

    public static WorkOrderTrigger__c createWorkOrderForOrderHeader(Apttus_Config2__Order__c oOrder, Date dPickingDate, Boolean isInstall) {

        WorkOrderTrigger__c oWorkOrder = new WorkOrderTrigger__c();

        oWorkOrder.Subject__c = oOrder.APTS_Subject__c;
        oWorkOrder.Description__c = oOrder.APTS_LSP_Description__c;
        oWorkOrder.OrderType__c = getOrderType(oOrder.APTS_Order_Sub_Type__c);
        oWorkOrder.Type__c = HEADER;
        //oWorkOrder.ServiceContact__c = ;
        oWorkOrder.ProjectNumber__c = oOrder.APTS_ProjectNumber__c;
        oWorkOrder.IsProject__c = oOrder.APTS_IsProject__c;
        oWorkOrder.RequestedActivityDate__c = (isInstall) ? oOrder.APTS_Requested_Installation_Date__c : oOrder.APTS_Requested_De_Installation_Date__c.date();
        oWorkOrder.ScheduleExceptions__c = oOrder.APTS_ScheduleExceptions__c;
        oWorkOrder.ParentOrder__c = oOrder.Id;
        oWorkOrder.SalesOrganization__c = oOrder.APTS_Sales_Organization__c;
        oWorkOrder.AdditionalServiceContact__c = oOrder.Apttus_Config2__PrimaryContactId__c;
        //oWorkOrder.ChildOrder__c = first order
        oWorkOrder.Load_ID__c = WOT + oOrder.Id;
        oWorkOrder.PickingDate__c = dPickingDate;
        oWorkOrder.AccountLocation__c = oOrder.Apttus_Config2__LocationId__c;
        oWorkOrder.ScheduleExceptions__c = oOrder.APTS_Manual_Scheduling__c;

        String sPONumber = oOrder.Apttus_Config2__PONumber__c;
        if (String.isNotBlank(sPONumber)) {
            if (sPONumber.length() > 80) {
                sPONumber = sPONumber.substring(0, 79);
            }
        }
        oWorkOrder.PO_Number__c = sPONumber;
        oWorkOrder.GenerateServiceOrder__c = true;
        oWorkOrder.PotentialRoundTrip__c = false;

        //commercial swap, Deinstall Order should be mapped with ChildOrder__c and installation Order should be mapped with ParentOrder__c
        if (COMMERCIAL_SWAP.equalsIgnoreCase(oOrder.APTS_Order_Sub_Type__c)) {
            oWorkOrder.ParentOrder__c = oOrder.Apttus_Config2__ParentOrderId__c;
            oWorkOrder.ChildOrder__c = oOrder.Id;
            oWorkOrder.GenerateServiceOrder__c = false;
        }

        return oWorkOrder;
    }

    public static void doDMLWorkOrderCreation(Map<Id, Apttus_Config2__Order__c> orderIdToOrderMap, List<WorkOrderTrigger__c> workOrderToCreateList, String sWOTType, DescribeSObjectResult objResultWorkOrder) {

        if (WTYPE_SWAP.equalsIgnoreCase(sWOTType)) {

            List<WorkOrderTrigger__c> headerWOTToCreateList = new List<WorkOrderTrigger__c>();
            List<WorkOrderTrigger__c> bundleWOTToCreateList = new List<WorkOrderTrigger__c>();
            List<WorkOrderTrigger__c> optionWOTToCreateList = new List<WorkOrderTrigger__c>();

            for (WorkOrderTrigger__c oWOT : workOrderToCreateList) {
                if (oWOT.Type__c == 'Header') {
                    headerWOTToCreateList.add(oWOT);
                } else if (oWOT.Type__c == 'Line Item') {
                    bundleWOTToCreateList.add(oWOT);
                } else {
                    optionWOTToCreateList.add(oWOT);
                }
            }

            if (!headerWOTToCreateList.isEmpty()) {
                if (objResultWorkOrder.isCreateable()) {
                    Database.insert(headerWOTToCreateList);
                }
            }

            //Fix bundle WOT
            for (WorkOrderTrigger__c oWOTBundle : bundleWOTToCreateList) {

                for (WorkOrderTrigger__c oWOTHeader : headerWOTToCreateList) {
                    if (oWOTBundle.Load_ID__c == ('WOT-' + oWOTHeader.ParentOrder__c) || oWOTBundle.Load_ID__c == ('WOT-' + oWOTHeader.ChildOrder__c)) {
                        oWOTBundle.ParentHeader__c = oWOTHeader.Id;
                        oWOTBundle.Load_ID__c = 'WOT-' + oWOTBundle.OrderLineItem__c;
                    }
                }
            }

            if (!bundleWOTToCreateList.isEmpty()) {
                if (objResultWorkOrder.isCreateable()) {
                    Database.insert(bundleWOTToCreateList);
                }
            }

            //Fix option WOT
            for (WorkOrderTrigger__c oWOTOption : optionWOTToCreateList) {

                for (WorkOrderTrigger__c oWOTBundle : bundleWOTToCreateList) {
                    if (oWOTOption.Load_ID__c == ('WOT-' + oWOTBundle.OrderLineItem__c)) {
                        oWOTOption.Load_ID__c = 'WOT-' + oWOTOption.OrderLineItem__c;
                        oWOTOption.ParentLineItem__c = oWOTBundle.Id;
                    }
                }
            }

            if (!optionWOTToCreateList.isEmpty()) {
                if (objResultWorkOrder.isCreateable()) {
                    Database.insert(optionWOTToCreateList);
                }
            }

            Map<Id, WorkOrderTrigger__c> mapWOTHeadUpdate = new Map<Id, WorkOrderTrigger__c> ();
            for (WorkOrderTrigger__c oWOT : workOrderToCreateList) {
                if (!mapWOTHeadUpdate.containsKey(oWOT.ParentHeader__c) && orderIdToOrderMap.containsKey(oWOT.ParentOrder__c) && COMMERCIAL_SWAP.equalsIgnoreCase(orderIdToOrderMap.get(oWOT.ParentOrder__c).APTS_Order_Sub_Type__c)) {
                    WorkOrderTrigger__c oWOTHead = new WorkOrderTrigger__c();
                    oWOTHead.Id = oWOT.ParentHeader__c;
                    oWOTHead.GenerateServiceOrder__c = true;
                    mapWOTHeadUpdate.put(oWOTHead.Id, oWOTHead);
                }
            }
            if (!mapWOTHeadUpdate.isEmpty()) {
                if (objResultWorkOrder.isUpdateable()) {
                    Database.update(mapWOTHeadUpdate.values());
                }
            }
        } else {
            List<WorkOrderTrigger__c> bundleWOTToCreateList = new List<WorkOrderTrigger__c>();
            List<WorkOrderTrigger__c> otherWOTToCreateList = new List<WorkOrderTrigger__c>();

            for (WorkOrderTrigger__c oWOT : workOrderToCreateList) {
                if (oWOT.Type__c == 'Line Item') {
                    bundleWOTToCreateList.add(oWOT);
                } else {
                    otherWOTToCreateList.add(oWOT);
                }
            }

            if (!bundleWOTToCreateList.isEmpty()) {
                if (objResultWorkOrder.isCreateable()) {
                    Database.insert(bundleWOTToCreateList);
                }
            }

            //fix option WOT
            for (WorkOrderTrigger__c oWOTOption : otherWOTToCreateList) {

                if (oWOTOption.Type__c == 'Option') {

                    for (WorkOrderTrigger__c oWOTBundle : bundleWOTToCreateList) {
                        if (oWOTOption.Load_ID__c == ('WOT-' + oWOTBundle.OrderLineItem__c)) {
                            oWOTOption.Load_ID__c = 'WOT-' + oWOTOption.OrderLineItem__c;
                            oWOTOption.ParentLineItem__c = oWOTBundle.Id;
                        }
                    }
                }
            }

            if (!otherWOTToCreateList.isEmpty()) {
                if (objResultWorkOrder.isCreateable()) {
                    Database.insert(otherWOTToCreateList);
                }
            }
            // v103 Added Logic to Populate DependentDeInstallation__c 
            if ('movement'.equalsIgnoreCase(sWOTType)) {
                    Map<String,WorkOrderTrigger__c> MapLoadIdWOT = new Map<String,WorkOrderTrigger__c>();
                    List<WorkOrderTrigger__c> updateWOT = new List<WorkOrderTrigger__c>();
            
                    for(WorkOrderTrigger__c oWOTOption : bundleWOTToCreateList){
                        if (oWOTOption.OrderSubType__c == 'De-Installation') {
                            
                            MapLoadIdWOT.put(oWOTOption.Load_ID__c,oWOTOption);
                        }
                    }
                    for(WorkOrderTrigger__c oWOTOption : bundleWOTToCreateList){
                        if (oWOTOption.OrderSubType__c == 'Installation') {
                            oWOTOption.DependentDeInstallation__c = MapLoadIdWOT.get(oWOTOption.Load_ID__c).id;
                            updateWOT.add(oWOTOption);
                        }
                        
                    }
                    if (!updateWOT.isEmpty()) {
                        if (objResultWorkOrder.isUpdateable()) {
                            Database.Update(updateWOT);
                        }
                    }
                    // v103 Added Logic to Populate DependentDeInstallation__c 
            }
        }
        
    }

    /*@methodName- getOrderType
    *@description- method is used to get the Work Order Type.
    *@param- String to know the Order, Order Line Item.
    *@return- Work Order Type.
    */

    public static String getOrderType(String sOrderType) {

        String sOrderTypeConverted = sOrderType;

        if (DE_INSTALLATION.equalsIgnoreCase(sOrderType)) {
            sOrderTypeConverted = DE_INSTALLATIONTS;
        } else if (INTERNAL_MOVEMENT.equalsIgnoreCase(sOrderType) || EXTERNAL_MOVEMENT_WITHOUT_CONTRACT_CHANGE.equalsIgnoreCase(sOrderType) || EXTERNAL_MOVEMENT_WITH_CONTRACT_CHANGE.equalsIgnoreCase(sOrderType)) {
            sOrderTypeConverted = MOVEMENT;
        } else if (TECHNICAL_SWAP.equalsIgnoreCase(sOrderType) || COMMERCIAL_SWAP.equalsIgnoreCase(sOrderType)) {
            sOrderTypeConverted = SWAP;
        } else {
            sOrderTypeConverted = sOrderType;
        }

        return sOrderTypeConverted;
    }
    /* Method to fetch Machine Care Field */
    public Static String getMachineCareValue (WorkOrderTrigger__c oWorkOrder, Apttus_Config2__OrderLineItem__c oLI) {
        String machineCareValue;
        if (oLI.APTS_Option_Group_Text__c != Null ) {
            if (oLI.APTS_Option_Group_Text__c.containsIgnoreCase(APTS_OrderConstants.MACHINECARE)) {
                if (oLI.Apttus_Config2__Description__c.containsIgnoreCase(APTS_OrderConstants.COMFORT_OPERATING)) {
                    machineCareValue = APTS_OrderConstants.COMFORT_OPERATING;
                } else if (oLI.Apttus_Config2__Description__c.containsIgnoreCase(APTS_OrderConstants.FULL_CO_OPERATING)) {
                    machineCareValue = APTS_OrderConstants.FULL_CO_OPERATING;
                } else if (oLI.Apttus_Config2__Description__c.containsIgnoreCase(APTS_OrderConstants.FULL_OPERATING)) {
                    machineCareValue = APTS_OrderConstants.FULL_OPERATING;
                } else if (oLI.Apttus_Config2__Description__c.containsIgnoreCase(APTS_OrderConstants.SEMI_OPERATING)) {
                    machineCareValue = APTS_OrderConstants.SEMI_OPERATING;
                }
            }
        }
        system.debug('machineCareValue-----------' + machineCareValue);
        return machineCareValue;
    }

    /*@methodName- WOTOrderWrapper
    *@description-
    *@param-
    *@return-
    */

    public class WOTOrderWrapper {
        public WorkOrderTrigger__c oLineItemWOT {get; set;}
        public List<WorkOrderTrigger__c> listOptionWOT {get; set;}
    }
}