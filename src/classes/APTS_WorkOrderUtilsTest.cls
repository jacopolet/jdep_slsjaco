/*************************************************************
@Name: APTS_WorkOrderUtilsTest
@Author: Galin Georgiev
@CreateDate: 19-02-2018
@Description: Work Order Utils Test
@UsedBy: APTS_WorkOrderUtils
******************************************************************/
//v100 19-02-2018 Galin Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes

@isTest
private with sharing class APTS_WorkOrderUtilsTest {

    private static final String OPTION = System.Label.APTS_Option;
    private static final String INTERNAL_MOVEMENT = System.Label.APTS_Internal_Movement;
    private static final String EXTERNAL_MOVEMENT_WITHOUT_CONTRACT_CHANGE = 'External Movement Without Contract Change';

    @testSetup static void setupTestData() {

        User oTestUser = APTS_TestFacade.createTestUser();
        APTS_TestFacade.createMandatoryRecords(oTestUser);

        APTS_OrderUtils.stopOrderTrigger();
        APTS_OrderUtils.stopOrderLineItemTrigger();
        APTS_TestFacade.createAndConfigureOrder(oTestUser);
        APTS_TestFacade.createMachineAmendOrder(oTestUser);
    }

    @isTest static void test_createWorkOrdersInstallFlow() {

        User oTestUser = APTS_TestFacade.getTestUser();

        //Apttus_Config2__Order__c oOrder = APTS_TestFacade.getMachineOrder();
        Apttus_Config2__Order__c oOrder =  [
                                               SELECT Id, Name, APTS_Name__c, Apttus_Config2__Status__c, RecordTypeId,
                                               Apttus_Config2__OrderStartDate__c, Apttus_Config2__OrderEndDate__c,
                                               Apttus_CMConfig__AgreementId__c, Apttus_Config2__BillingPreferenceId__c,
                                               Apttus_Config2__BillToAccountId__c, Apttus_Config2__PriceListId__c, Apttus_Config2__ShipToAccountId__c,
                                               Apttus_Config2__SoldToAccountId__c, Apttus_Config2__Source__c, APTS_Status__c, Apttus_Config2__PrimaryContactId__c,
                                               APTS_Subject__c, APTS_LSP_Description__c, APTS_ServiceContact__c, APTS_ProjectNumber__c, APTS_IsProject__c,
                                               APTS_ScheduleDate__c, APTS_ScheduleExceptions__c, Apttus_Config2__ParentOrderId__c, APTS_Requested_Delivery_Date__c,
                                               APTS_Order_Sub_Type__c, APTS_Requested_Installation_Date__c, Apttus_Config2__PONumber__c,
                                               APTS_Sales_Organization__c, APTS_Order_Type__c, Apttus_Config2__LocationId__c,
                                               APTS_SAP_OrderType__c, APTS_Work_Order_Created__c, Apttus_CMConfig__AgreementId__r.Apttus__Version_Number__c,
                                               APTS_Require_Installation__c, APTS_Requested_De_Installation_Date__c,APTS_Requested_Movement_Date__c, APTS_Manual_Scheduling__c
                                               FROM Apttus_Config2__Order__c
                                               WHERE Apttus_Config2__Description__c = 'MachineOrder' LIMIT 1];

        List<Apttus_Config2__OrderLineItem__c> orderLineItemList = APTS_TestFacade.getOrderLineItemList(oOrder.Id);
        APTS_Order_LSP_Details__c oLSPDetails = APTS_TestFacade.getLSPDetails(orderLineItemList[0].APTS_Order_LSP_Detail__c);
        Map<Id, List<Apttus_Config2__OrderLineItem__c>> bundleIdToOptionsMap = new Map<Id, List<Apttus_Config2__OrderLineItem__c>>();
        bundleIdToOptionsMap = APTS_WorkOrderUtils.prepareBundleIdToOptionsMap(orderLineItemList);
        
        Map<Id, Apttus_Config2__OrderLineItem__c> idToOrderLineItemMap = new Map<Id, Apttus_Config2__OrderLineItem__c>();
        for(Apttus_Config2__OrderLineItem__c OLI :orderLineItemList ){
            idToOrderLineItemMap.put(oli.id, oli);
        }
        Map<Id, APTS_Order_LSP_Details__c> bundleIdToLSPDetailMap = APTS_WorkOrderUtils.prepareBundleIdToLSPDetailMap(bundleIdToOptionsMap.keySet(), idToOrderLineItemMap);

        
        /*
        Map<Id, Apttus_Config2__OrderLineItem__c> idToOrderLineItemMap = new Map<Id, Apttus_Config2__OrderLineItem__c>(orderLineItemList);
        Map<Id, List<Apttus_Config2__OrderLineItem__c>> bundleIdToOptionsMap = prepareBundleIdToOptionsMap(orderLineItemList);
        Map<Id, APTS_Order_LSP_Details__c> bundleIdToLSPDetailMap = prepareBundleIdToLSPDetailMap(bundleIdToOptionsMap.keySet(), idToOrderLineItemMap);
        */
        
        
        
        Test.startTest();

        System.runAs(oTestUser) {

            List<WorkOrderTrigger__c> workOrderToCreateList = APTS_WorkOrderUtils.createWorkOrders('install', oOrder, orderLineItemList,bundleIdToOptionsMap,bundleIdToLSPDetailMap);            
            Map<Id, Apttus_Config2__Order__c> orderIdToOrderMap = new Map<Id, Apttus_Config2__Order__c>();
            orderIdToOrderMap.put(oOrder.Id, oOrder);
            DescribeSObjectResult objResultWorkOrder = APTS_OTCUtil.getsObjectAccess('WorkOrderTrigger__c');
            APTS_WorkOrderUtils.doDMLWorkOrderCreation(orderIdToOrderMap, workOrderToCreateList, 'install', objResultWorkOrder);

            APTS_WorkOrderUtils.createWorkOrders('deInstall', oOrder, orderLineItemList,bundleIdToOptionsMap,bundleIdToLSPDetailMap);

            //Apttus_Config2__Order__c oMachineAmendOrder = APTS_TestFacade.getOrder('MachineAmendOrder');
            Apttus_Config2__Order__c oMachineAmendOrder = [
                        SELECT Id, Name, APTS_Name__c, Apttus_Config2__Status__c, RecordTypeId,
                        Apttus_Config2__OrderStartDate__c, Apttus_Config2__OrderEndDate__c,
                        Apttus_CMConfig__AgreementId__c, Apttus_Config2__BillingPreferenceId__c,
                        Apttus_Config2__BillToAccountId__c, Apttus_Config2__PriceListId__c, Apttus_Config2__ShipToAccountId__c,
                        Apttus_Config2__SoldToAccountId__c, Apttus_Config2__Source__c, APTS_Status__c, Apttus_Config2__PrimaryContactId__c,
                        APTS_Subject__c, APTS_LSP_Description__c, APTS_ServiceContact__c, APTS_ProjectNumber__c, APTS_IsProject__c,
                        APTS_ScheduleDate__c, APTS_ScheduleExceptions__c, Apttus_Config2__ParentOrderId__c, APTS_Requested_Delivery_Date__c,
                        APTS_Order_Sub_Type__c, APTS_Requested_Installation_Date__c, Apttus_Config2__PONumber__c,
                        APTS_Sales_Organization__c, APTS_Order_Type__c, Apttus_Config2__LocationId__c,
                        APTS_SAP_OrderType__c, APTS_Work_Order_Created__c, Apttus_CMConfig__AgreementId__r.Apttus__Version_Number__c,
                        APTS_Require_Installation__c, APTS_Requested_De_Installation_Date__c, APTS_Requested_Movement_Date__c, APTS_Manual_Scheduling__c
                        FROM Apttus_Config2__Order__c
                        WHERE Apttus_Config2__Description__c = 'MachineAmendOrder' LIMIT 1];

           // List<Apttus_Config2__OrderLineItem__c> orderMachineAmendLineItemList = APTS_TestFacade.getOrderLineItemList(oMachineAmendOrder.Id);
            // APTS_WorkOrderUtils.createWorkOrders('conversion', oOrder, orderMachineAmendLineItemList,bundleIdToOptionsMap,bundleIdToLSPDetailMap);

            oOrder.APTS_Order_Sub_Type__c = INTERNAL_MOVEMENT;
            Database.update(oOrder);
            oLSPDetails.APTS_Require_Installation__c = true;
            oLSPDetails.APTS_Require_De_Installation__c = true;
            Database.update(oLSPDetails);

            APTS_WorkOrderUtils.createWorkOrders('movement', oOrder, orderLineItemList,bundleIdToOptionsMap,bundleIdToLSPDetailMap);
            APTS_WorkOrderUtils.createWorkOrderSwap('swap', oOrder, orderLineItemList,oOrder,orderLineItemList,bundleIdToOptionsMap,bundleIdToLSPDetailMap);


            


            APTS_WorkOrderUtils.createWorkOrderForOrderHeader(oOrder, oLSPDetails, System.today(), true);
            APTS_WorkOrderUtils.createWorkOrderForOrderHeader(oOrder, System.today(), true);

            WorkOrderTrigger__c oBundleWorkOrder = new WorkOrderTrigger__c();
            Apttus_Config2__OrderLineItem__c oBundleLineItem = new Apttus_Config2__OrderLineItem__c();
            Apttus_Config2__OrderLineItem__c orderLineItem = new Apttus_Config2__OrderLineItem__c();
            APTS_WorkOrderUtils.createWorkOrderForOption(oOrder, oBundleWorkOrder, oBundleLineItem, orderLineItem, true);
            APTS_WorkOrderUtils.createWorkOrderForBundleConversion(oOrder, oBundleLineItem, orderLineItem, oLSPDetails, true);
        }

        Test.stopTest();
    }
    @isTest static void test_createWorkOrdersExternalMovementFlow() {

        User oTestUser = APTS_TestFacade.getTestUser();

        //Apttus_Config2__Order__c oOrder = APTS_TestFacade.getMachineOrder();
        Apttus_Config2__Order__c oOrder =  [
                                               SELECT Id, Name, APTS_Name__c, Apttus_Config2__Status__c, RecordTypeId,
                                               Apttus_Config2__OrderStartDate__c, Apttus_Config2__OrderEndDate__c,
                                               Apttus_CMConfig__AgreementId__c, Apttus_Config2__BillingPreferenceId__c,
                                               Apttus_Config2__BillToAccountId__c, Apttus_Config2__PriceListId__c, Apttus_Config2__ShipToAccountId__c,
                                               Apttus_Config2__SoldToAccountId__c, Apttus_Config2__Source__c, APTS_Status__c, Apttus_Config2__PrimaryContactId__c,
                                               APTS_Subject__c, APTS_LSP_Description__c, APTS_ServiceContact__c, APTS_ProjectNumber__c, APTS_IsProject__c,
                                               APTS_ScheduleDate__c, APTS_ScheduleExceptions__c, Apttus_Config2__ParentOrderId__c, APTS_Requested_Delivery_Date__c,
                                               APTS_Order_Sub_Type__c, APTS_Requested_Installation_Date__c, Apttus_Config2__PONumber__c,
                                               APTS_Sales_Organization__c, APTS_Order_Type__c, Apttus_Config2__LocationId__c,
                                               APTS_SAP_OrderType__c, APTS_Work_Order_Created__c, Apttus_CMConfig__AgreementId__r.Apttus__Version_Number__c,
                                               APTS_Require_Installation__c, APTS_Requested_De_Installation_Date__c, APTS_Requested_Movement_Date__c, APTS_Manual_Scheduling__c
                                               FROM Apttus_Config2__Order__c
                                               WHERE Apttus_Config2__Description__c = 'MachineOrder' LIMIT 1];

        List<Apttus_Config2__OrderLineItem__c> orderLineItemList = APTS_TestFacade.getOrderLineItemList(oOrder.Id);
        APTS_Order_LSP_Details__c oLSPDetails = APTS_TestFacade.getLSPDetails(orderLineItemList[0].APTS_Order_LSP_Detail__c);
        Map<Id, List<Apttus_Config2__OrderLineItem__c>> bundleIdToOptionsMap = new Map<Id, List<Apttus_Config2__OrderLineItem__c>>();
        bundleIdToOptionsMap = APTS_WorkOrderUtils.prepareBundleIdToOptionsMap(orderLineItemList);
        
        Map<Id, Apttus_Config2__OrderLineItem__c> idToOrderLineItemMap = new Map<Id, Apttus_Config2__OrderLineItem__c>();
        for(Apttus_Config2__OrderLineItem__c OLI :orderLineItemList ){
            idToOrderLineItemMap.put(oli.id, oli);
        }
        Map<Id, APTS_Order_LSP_Details__c> bundleIdToLSPDetailMap = APTS_WorkOrderUtils.prepareBundleIdToLSPDetailMap(bundleIdToOptionsMap.keySet(), idToOrderLineItemMap);
        
        Test.startTest();

        System.runAs(oTestUser) {

            List<WorkOrderTrigger__c> workOrderToCreateList = APTS_WorkOrderUtils.createWorkOrders('install', oOrder, orderLineItemList,bundleIdToOptionsMap,bundleIdToLSPDetailMap);            
            Map<Id, Apttus_Config2__Order__c> orderIdToOrderMap = new Map<Id, Apttus_Config2__Order__c>();
            orderIdToOrderMap.put(oOrder.Id, oOrder);
            DescribeSObjectResult objResultWorkOrder = APTS_OTCUtil.getsObjectAccess('WorkOrderTrigger__c');
            APTS_WorkOrderUtils.doDMLWorkOrderCreation(orderIdToOrderMap, workOrderToCreateList, 'install', objResultWorkOrder);

            APTS_WorkOrderUtils.createWorkOrders('deInstall', oOrder, orderLineItemList,bundleIdToOptionsMap,bundleIdToLSPDetailMap);

            //Apttus_Config2__Order__c oMachineAmendOrder = APTS_TestFacade.getOrder('MachineAmendOrder');
            Apttus_Config2__Order__c oMachineAmendOrder = [
                        SELECT Id, Name, APTS_Name__c, Apttus_Config2__Status__c, RecordTypeId,
                        Apttus_Config2__OrderStartDate__c, Apttus_Config2__OrderEndDate__c,
                        Apttus_CMConfig__AgreementId__c, Apttus_Config2__BillingPreferenceId__c,
                        Apttus_Config2__BillToAccountId__c, Apttus_Config2__PriceListId__c, Apttus_Config2__ShipToAccountId__c,
                        Apttus_Config2__SoldToAccountId__c, Apttus_Config2__Source__c, APTS_Status__c, Apttus_Config2__PrimaryContactId__c,
                        APTS_Subject__c, APTS_LSP_Description__c, APTS_ServiceContact__c, APTS_ProjectNumber__c, APTS_IsProject__c,
                        APTS_ScheduleDate__c, APTS_ScheduleExceptions__c, Apttus_Config2__ParentOrderId__c, APTS_Requested_Delivery_Date__c,
                        APTS_Order_Sub_Type__c, APTS_Requested_Installation_Date__c, Apttus_Config2__PONumber__c,
                        APTS_Sales_Organization__c, APTS_Order_Type__c, Apttus_Config2__LocationId__c,
                        APTS_SAP_OrderType__c, APTS_Work_Order_Created__c, Apttus_CMConfig__AgreementId__r.Apttus__Version_Number__c,
                        APTS_Require_Installation__c, APTS_Requested_De_Installation_Date__c, APTS_Requested_Movement_Date__c, APTS_Manual_Scheduling__c
                        FROM Apttus_Config2__Order__c
                        WHERE Apttus_Config2__Description__c = 'MachineAmendOrder' LIMIT 1];

     
            oOrder.APTS_Order_Sub_Type__c = EXTERNAL_MOVEMENT_WITHOUT_CONTRACT_CHANGE;
            Database.update(oOrder);
            oLSPDetails.APTS_Require_Installation__c = true;
            oLSPDetails.APTS_Require_De_Installation__c = true;
            Database.update(oLSPDetails);
            
            APTS_WorkOrderUtils.createWorkOrders('movement', oOrder, orderLineItemList,bundleIdToOptionsMap,bundleIdToLSPDetailMap);
            APTS_WorkOrderUtils.createWorkOrderForOrderHeader(oOrder, oLSPDetails, System.today(), true);
            APTS_WorkOrderUtils.createWorkOrderForOrderHeader(oOrder, System.today(), true);

            WorkOrderTrigger__c oBundleWorkOrder = new WorkOrderTrigger__c();
            Apttus_Config2__OrderLineItem__c oBundleLineItem = new Apttus_Config2__OrderLineItem__c();
            Apttus_Config2__OrderLineItem__c orderLineItem = new Apttus_Config2__OrderLineItem__c();
            APTS_WorkOrderUtils.createWorkOrderForOption(oOrder, oBundleWorkOrder, oBundleLineItem, orderLineItem, true);
            APTS_WorkOrderUtils.createWorkOrderForBundleConversion(oOrder, oBundleLineItem, orderLineItem, oLSPDetails, true);
        }

        Test.stopTest();
    }
}