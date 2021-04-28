/*************************************************************
@Name: APTS_SubmitOrderQueueable
******************************************************************/
//v100 06-03-2019 Galin Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes
//v101 Nikita : DOQOM 317 : Added the logic for autosubmission of orders which got approved. Basically updated the status of all OLI to pending submitted
//V102 15-07-2020 Aarthi Pitchai : DQ-3315 - Remove the OFLI check in Amendment usecases
//v103 22-07-2020 Manisha Srilekha: DQ-2358 - Updated the key in orderToUpdateMap from ID to Previous Version's Order ID
//v104 05-08-2020 Manisha : DQ-3403-- Passing false instead of true for the previous version order status to be updated accordingly.

public without sharing class APTS_SubmitOrderQueueable implements Queueable {

    private Apttus_Config2__Order__c oOrderToSubmit;
    private Id submitObjectId = null;
    private String sErrorMessage = '';

    public APTS_SubmitOrderQueueable(List<Id> submitObjectIdList) {

        this.submitObjectId = submitObjectIdList.get(0);
    }

    public void execute(QueueableContext context) {

        Map<Id, Apttus_Config2__Order__c> orderToSubmitMap = new Map<Id, Apttus_Config2__Order__c>();
        Map<Id, Apttus_Config2__Order__c> orderToUpdateMap = new Map<Id, Apttus_Config2__Order__c>();

        if (validate()) {
            try {
                orderToSubmitMap.put(oOrderToSubmit.Id, oOrderToSubmit);
                if (APTS_OrderConstants.PO_HAS_EXPIRED.equalsIgnoreCase(oOrderToSubmit.Apttus_Config2__PONumber__c)) {
                    if (APTS_OrderConstants.ORDER_TYPE_DIGITAL == oOrderToSubmit.APTS_Order_Sub_Type__c ||
                            APTS_OrderConstants.ORDER_TYPE_ROUTESALES == oOrderToSubmit.APTS_Order_Type__c ||
                            APTS_OrderConstants.ORDER_TYPE_OPERATING == oOrderToSubmit.APTS_Order_Type__c) {

                        Group oCSQueue = APTS_DigitalOrderBatchHelper.getCSQueue();
                        oOrderToSubmit.ownerId = oCSQueue.Id;

                        orderToUpdateMap.put(oOrderToSubmit.Id, oOrderToSubmit);
                        system.debug('orderToUpdateMap---------------'+orderToUpdateMap.values());
                    }
                }

              
                //update Amend / cancel order headers needs to be update before submission so SAP picksup correct order
                 system.debug('orderToSubmit.Apttus_Config2__PreviousVersion__c----'+oOrderToSubmit.Apttus_Config2__PreviousVersion__c);
                if (oOrderToSubmit.Apttus_Config2__PreviousVersion__c != null) {
                    for (Apttus_Config2__Order__c previousOrder : [SELECT Id, APTS_Order_Header_SAP_ID__c FROM Apttus_Config2__Order__c
                            WHERE Id = :oOrderToSubmit.Apttus_Config2__PreviousVersion__c LIMIT 1]) {
                        oOrderToSubmit.APTS_Order_Header_SAP_ID__c = previousOrder.APTS_Order_Header_SAP_ID__c;
                        orderToUpdateMap.put(oOrderToSubmit.Id, oOrderToSubmit);
                        previousOrder.APTS_Order_Header_SAP_ID__c = null;
                        // v103++ << Updating the key in orderToUpdateMap from ID to Previous Version's Order ID
                        orderToUpdateMap.put(oOrderToSubmit.Apttus_Config2__PreviousVersion__c, previousOrder);
                        // v103++ >>
                    }

                }
                //reset data on Amended Orders
                if (!orderToUpdateMap.isEmpty()) {
                    APTS_OrderTriggerHandler.setTriggerDisabled(true);
                    Database.update(orderToUpdateMap.values());
                    APTS_OrderTriggerHandler.setTriggerDisabled(false);
                }

                //submit order
                //v104 -- Passing false instead of true for the previous version order status to be updated accordingly.
                APTS_OrderUtils.submitMultipleOrders(false, orderToSubmitMap.values());
                //update data after submitting order
                //clear ATP check result on Order Line Items
                //v101 <<++ removed APTS_OrderUtils.clearATPResultsMultiOrders()
                List<Apttus_Config2__OrderLineItem__c> orderLineItemList = [
                SELECT Id, APTS_Expected_Delivery_Quantity__c, APTS_Expected_Delivery_Date__c, APTS_ATP_Cleared__c,
                APTS_Requested_Delivery_Date__c, Apttus_Config2__OrderId__r.APTS_Requested_Delivery_Date__c,
                APTS_Requested_Installation_Date__c, Apttus_Config2__OrderId__r.APTS_Requested_Installation_Date__c
                FROM Apttus_Config2__OrderLineItem__c
                WHERE Apttus_Config2__OrderId__c IN :orderToSubmitMap.values()]; 
                // v109 -- APTS_Expected_Delivery_Quantity__c != null AND APTS_Expected_Delivery_Date__c != null];
                // v110 -- AND APTS_ATP_Cleared__c =  false

                for (Apttus_Config2__OrderLineItem__c oOrderLineItem : orderLineItemList) {
        
                    oOrderLineItem.APTS_Requested_Delivery_Date__c = oOrderLineItem.Apttus_Config2__OrderId__r.APTS_Requested_Delivery_Date__c;
                    oOrderLineItem.APTS_Requested_Installation_Date__c = oOrderLineItem.Apttus_Config2__OrderId__r.APTS_Requested_Installation_Date__c;
                    oOrderLineItem.APTS_Expected_Delivery_Quantity__c = null;
                    oOrderLineItem.APTS_Expected_Delivery_Date__c = null;
                    oOrderLineItem.APTS_ATP_Cleared__c = false;
                }
                //v101 ++>>
                
                for (Apttus_Config2__OrderLineItem__c OLIUpdate: orderLineItemList ) {
                    OLIUpdate.Apttus_Config2__Status__c = 'Pending';
                    OLIUpdate.APTS_Status__c = 'Submitted';
                }
                if (!orderLineItemList.isEmpty()) {
                    APTS_OrderUtils.stopOrderLineItemTrigger();
                    Database.update(orderLineItemList);
                    APTS_OrderUtils.startOrderLineItemTrigger();
                }

                if (oOrderToSubmit.Apttus_CMConfig__AgreementId__c != null && oOrderToSubmit.Apttus_CMConfig__AgreementId__r.RecordType.Name == APTS_OrderConstants.CONSUMPTION_MODEL) {
                    List<Apttus_Config2__OrderUsagePriceTier__c> toBeUpdatedOrderTiers = new List<Apttus_Config2__OrderUsagePriceTier__c>();
                    Map<Id, Apttus__AgreementLineItem__c> agreementTierMap = new Map<Id, Apttus__AgreementLineItem__c>([
                                SELECT Id,
                                (SELECT id, Apttus_CMConfig__AdjustmentAmount__c, Apttus_CMConfig__Dimension1Value__c, Apttus_CMConfig__TierStartValue__c ,
                                 Apttus_CMConfig__TierEndValue__c, Apttus_CMConfig__Dimension2Value__c, Apttus_CMConfig__AdjustmentType__c FROM Apttus_CMConfig__UsagePriceTiers__r LIMIT 50000)
                                FROM Apttus__AgreementLineItem__c
                                WHERE Apttus__AgreementId__c = : oOrderToSubmit.Apttus_CMConfig__AgreementId__c AND Apttus_CMConfig__ChargeType__c = :APTS_OrderConstants.USAGE_FEE LIMIT 50000]);

                    for (Apttus_Config2__OrderLineItem__c oli : [SELECT Id, Apttus_CMConfig__AgreementLineItemId__c,
                            (SELECT id, Apttus_Config2__Dimension1Value__c, Apttus_Config2__AdjustmentAmount__c FROM Apttus_Config2__OrderUsagePriceTiers__r LIMIT 50000)
                            FROM Apttus_Config2__OrderLineItem__c
                            WHERE Apttus_Config2__OrderId__c = :oOrderToSubmit.Id AND Apttus_Config2__ChargeType__c = :APTS_OrderConstants.USAGE_FEE LIMIT 50000] ) {


                        if (oli.Apttus_CMConfig__AgreementLineItemId__c != null && agreementTierMap.containsKey(oli.Apttus_CMConfig__AgreementLineItemId__c) && agreementTierMap.get(oli.Apttus_CMConfig__AgreementLineItemId__c).Apttus_CMConfig__UsagePriceTiers__r != null) {

                            for (Apttus_Config2__OrderUsagePriceTier__c orderUsageTier : oli.Apttus_Config2__OrderUsagePriceTiers__r) {

                                for (Apttus_CMConfig__AgreementUsagePriceTier__c agreementTier : agreementTierMap.get(oli.Apttus_CMConfig__AgreementLineItemId__c).Apttus_CMConfig__UsagePriceTiers__r) {
                                    if (orderUsageTier.Apttus_Config2__Dimension1Value__c == agreementTier.Apttus_CMConfig__Dimension1Value__c ) {
                                        orderUsageTier.Apttus_Config2__AdjustmentAmount__c = agreementTier.Apttus_CMConfig__AdjustmentAmount__c;
                                        orderUsageTier.Apttus_Config2__TierStartValue__c = agreementTier.Apttus_CMConfig__TierStartValue__c;
                                        orderUsageTier.Apttus_Config2__TierEndValue__c = agreementTier.Apttus_CMConfig__TierEndValue__c;
                                        orderUsageTier.Apttus_Config2__Dimension2Value__c = agreementTier.Apttus_CMConfig__Dimension2Value__c;
                                        orderUsageTier.Apttus_Config2__AdjustmentType__c = agreementTier.Apttus_CMConfig__AdjustmentType__c;
                                        toBeUpdatedOrderTiers.add(orderUsageTier);
                                        break;
                                    }
                                }
                            }
                        }
                    }

                    //Update the Order Usage Tiers
                    if (!toBeUpdatedOrderTiers.isEmpty()) {
                        update toBeUpdatedOrderTiers;
                    }
                }
            } catch (Exception e) {
                APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getMessage(), 'Order', null, 'OM', false, true, null, true);
            }
        } else {
            APTS_CustomLogging.createErrorLog('', 'Apex', sErrorMessage, 'Order', null, 'OM', false, true, null, true);
        }
    }

    public Boolean validate() {

        Boolean bResult = true;
        String sValidationMsg = '';

        List<Apttus_Config2__Order__c> listOrdersToSub = [SELECT Id,
                                       APTS_Order_Sub_Type__c,
                                       APTS_Order_Type__c,
                                       Apttus_Config2__PreviousVersion__c,
                                       Apttus_Config2__Status__c,
                                       APTS_Status__c,
                                       Apttus_Config2__SoldToAccountId__c,
                                       Apttus_Config2__SoldToAccountId__r.SAP_Customer_ID__c,
                                       Apttus_Config2__SoldToAccountId__r.RecordType.Name,
                                       Apttus_Config2__SoldToAccountId__r.Parent_Change_Indicator__c,
                                       Apttus_Config2__SoldToAccountId__r.Parent_Valid_From__c,
                                       Apttus_Config2__SoldToAccountId__r.Parent_Valid_To__c,
                                       Apttus_Config2__BillToAccountId__r.SAP_Customer_ID__c,
                                       Apttus_Config2__ShipToAccountId__r.SAP_Customer_ID__c,
                                       Apttus_Config2__BillToAccountId__c,
                                       Apttus_Config2__ShipToAccountId__c,
                                       APTS_Payer__c,
                                       APTS_Payer__r.SAP_Customer_ID__c,
                                       Apttus_Config2__ParentOrderId__c,
                                       Apttus_CMConfig__AgreementId__c,
                                       Apttus_CMConfig__AgreementId__r.RecordType.Name,
                                       Apttus_Config2__PONumber__c,
                                       APTS_SAP_OrderType__c
                                       FROM Apttus_Config2__Order__c WHERE Id = :submitObjectId LIMIT 1];

        if (!listOrdersToSub.isEmpty()) {

            oOrderToSubmit = listOrdersToSub[0];

            sValidationMsg = oOrderToSubmit.Apttus_Config2__SoldToAccountId__c == null || oOrderToSubmit.Apttus_Config2__SoldToAccountId__r.SAP_Customer_ID__c == null ? APTS_OrderConstants.SOLD_TO : sValidationMsg;
            sValidationMsg = oOrderToSubmit.Apttus_Config2__BillToAccountId__c == null || oOrderToSubmit.Apttus_Config2__BillToAccountId__r.SAP_Customer_ID__c == null ?  APTS_OrderConstants.BILL_TO : sValidationMsg;
            sValidationMsg = oOrderToSubmit.Apttus_Config2__ShipToAccountId__c == null || oOrderToSubmit.Apttus_Config2__ShipToAccountId__r.SAP_Customer_ID__c == null ? APTS_OrderConstants.SHIP_TO : sValidationMsg;
            sValidationMsg = oOrderToSubmit.APTS_Payer__c == null || oOrderToSubmit.APTS_Payer__r.SAP_Customer_ID__c == null ? APTS_OrderConstants.PAYER_TO : sValidationMsg;

            if (APTS_OrderConstants.PO_HAS_EXPIRED.equalsIgnoreCase(oOrderToSubmit.Apttus_Config2__PONumber__c)) {
                sValidationMsg = oOrderToSubmit.Apttus_Config2__PONumber__c;
            }

            if (String.isNotBlank(sValidationMsg)) {
                sValidationMsg = 'SAP Customer Id can\'t be NULL on ' + sValidationMsg + ' account';
                sErrorMessage = sValidationMsg;
                bResult = false;
            }

            if (oOrderToSubmit.Apttus_Config2__PreviousVersion__c != null && !(oOrderToSubmit.APTS_SAP_OrderType__c.containsIgnoreCase('XD') || oOrderToSubmit.APTS_SAP_OrderType__c.containsIgnoreCase('XL'))) {
            //V102 ++ <<
             /*  List<Apttus_Config2__OrderFulfillmentLineItem__c> listFul = [
                            SELECT Id
                            FROM Apttus_Config2__OrderFulfillmentLineItem__c
                            WHERE Apttus_Config2__OrderId__c = :oOrderToSubmit.Apttus_Config2__PreviousVersion__c LIMIT 10000];

                if (!listFul.isEmpty()) {
                    sErrorMessage = sErrorMessage + APTS_OrderConstants.SUB_ERR_ORDER_IN_FUL;
                    bResult = false;
                } else { */ //V102 ++ >>
                    Boolean noReason = false;
                    List<Apttus_Config2__OrderLineItem__c> orderLineItemList = [
                                SELECT Id,
                                Apttus_Config2__Status__c,
                                APTS_Is_Primary_L1_Line__c, 
                                Apttus_Config2__OrderId__c,
                                Apttus_Config2__OrderId__r.APTS_Order_Type__c
                                FROM Apttus_Config2__OrderLineItem__c
                                WHERE Apttus_Config2__OrderId__c = :submitObjectId AND Apttus_Config2__Status__c = :APTS_OrderConstants.STATUS_PENDING_CANCEL AND APTS_Reason_For_Rejection__c = null LIMIT 10000];
                    //v101 ++ << Akanksha :27-2-2019 : Defect 5173
                    if (!orderLineItemList.isEmpty()) {
                        for(Apttus_Config2__OrderLineItem__c oli : orderLineItemList){
                            if(oli.Apttus_Config2__OrderId__r.APTS_Order_Type__c == APTS_OrderConstants.MACHINE_ORDER && !oli.APTS_Is_Primary_L1_Line__c) {
                                noReason = true;
                            }
                            else {
                                noReason = false;
                            }
                        }
                        if (!noReason) {
                            sErrorMessage = sErrorMessage + APTS_OrderConstants.REJECT_REASON_REQ;
                            bResult = false;
                        }
                    }
                    //v101 ++ >>
               // } //V102 ++ <<>>
            }
        } else {
            sErrorMessage = sErrorMessage + APTS_OrderConstants.REJECT_REASON_REQ;
            bResult = false;
        }

        return bResult;
    }
}