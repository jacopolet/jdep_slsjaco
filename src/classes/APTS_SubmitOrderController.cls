/*************************************************************
@Name: APTS_SubmitOrderController 
@Author: Galin Georgiev
@CreateDate: 09-11-2018
@Description: Submit Order
@UsedBy: Submit Order button on Order page
******************************************************************/
//v100 09-11-2018 Galin Georgiev: Initial version.
//v101 27-02-2019 Akanksha : Added code for defect 5173
//v102 06-03-2019 Sethu : Added condition on line-32 for defect 5632
//v103 11-03-2019 Akanksha : Removed condition for Appproved status for defect# 5768
//v104 25-04-2019 Neev : Machine Cancel
//v105 15-05-2019 Aarthi : Added logic to populate the Invoice line Item number on OLIs for Return order - DOQOM-39
//v106 23-05-2019 Aarthi :Use External_Invoice_Line_Number_c on the Invoice line Item number on OLIs for Return order - DOQOM-39
//V107 15-07-2020 Aarthi Pitchai : DQ-2521 - Remove the OFLI check in Amendment usecases

//Comments in this format are mandatory for each change of code. 
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes

public without sharing class APTS_SubmitOrderController {

    private Apttus_Config2__Order__c oOrderToSubmit;
    private Id submitObjectId = null;

    public Boolean bErrorOccurred {get; set;}

    public APTS_SubmitOrderController() {

        submitObjectId = ApexPages.currentPage().getParameters().get(Label.APTS_Id);
        bErrorOccurred = false;
    }

    public void submitOrder() 
    {

        Set<String> validationMsgSet = submitOrder(submitObjectId, true);

        if (!validationMsgSet.isEmpty()) 
        {

            bErrorOccurred = true;

            for (String sValidationMsg : validationMsgSet) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.Severity.ERROR, sValidationMsg));
            }
        }
    }

    public static Set<String> submitOrder(Id submitObjectId, Boolean bUsedInVFPage) {

        Map<Id, Apttus_Config2__Order__c> orderToSubmitMap = new Map<Id, Apttus_Config2__Order__c>();
        Map<Id, Apttus_Config2__Order__c> orderToUpdateMap = new Map<Id, Apttus_Config2__Order__c>();

        Apttus_Config2__Order__c oOrderToSubmit = getSubmitOrder(submitObjectId);
        Set<String> validationMsgSet = validate(oOrderToSubmit);
       
        Boolean bDoStatusValidation = oOrderToSubmit.Apttus_Config2__Status__c != 'Pending' && oOrderToSubmit.APTS_Status__c != 'Submitted';
        bDoStatusValidation = bUsedInVFPage ? bDoStatusValidation && oOrderToSubmit.Approval_Status__c != 'Approved' : bDoStatusValidation;
       
        if (validationMsgSet.isEmpty() && bDoStatusValidation)
        {
            try {
                orderToSubmitMap.put(oOrderToSubmit.Id, oOrderToSubmit);

                if (APTS_OrderConstants.PO_HAS_EXPIRED.equalsIgnoreCase(oOrderToSubmit.Apttus_Config2__PONumber__c)) {

                    if (APTS_OrderConstants.ORDER_TYPE_DIGITAL == oOrderToSubmit.APTS_Order_Sub_Type__c ||
                            APTS_OrderConstants.ORDER_TYPE_ROUTESALES == oOrderToSubmit.APTS_Order_Type__c ||
                            APTS_OrderConstants.ORDER_TYPE_OPERATING == oOrderToSubmit.APTS_Order_Type__c) {

                        Group oCSQueue = APTS_DigitalOrderBatchHelper.getCSQueue();
                        oOrderToSubmit.ownerId = oCSQueue.Id;

                        orderToUpdateMap.put(oOrderToSubmit.Id, oOrderToSubmit);
                    }
                }
                //v105 ++ <<
                if(oOrderToSubmit.APTS_Order_Sub_Type__c == APTS_OrderConstants.STANDARD_RETURN){
                    //Get all the Business Line Item list from Asset line item associated with new order'
                    setInvoiceLineItemOnOLI(oOrderToSubmit);
                }
                //v105 ++ >>
                
                if (APTS_OrderConstants.COMMERCIAL_SWAP.equalsIgnoreCase(oOrderToSubmit.APTS_Order_Sub_Type__c) || APTS_OrderConstants.TECHNICAL_SWAP.equalsIgnoreCase(oOrderToSubmit.APTS_Order_Sub_Type__c)) 
                {
                    Map<Id, Apttus_Config2__Order__c> childOrderMap = new Map<Id, Apttus_Config2__Order__c>([
                                SELECT Id,
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
                                FROM Apttus_Config2__Order__c
                                WHERE Id = :oOrderToSubmit.Apttus_Config2__ParentOrderId__c AND (APTS_Order_Sub_Type__c = :APTS_OrderConstants.COMMERCIAL_SWAP OR APTS_Order_Sub_Type__c = :APTS_OrderConstants.TECHNICAL_SWAP) LIMIT 1]);

                    if (!childOrderMap.isEmpty()) {
                        orderToSubmitMap.putAll(childOrderMap.values());
                    }
                }
                
                //update Amend / cancel order headers needs to be update before submission so SAP picksup correct order
                if (oOrderToSubmit.Apttus_Config2__PreviousVersion__c != null) 
                {
                   for (Apttus_Config2__Order__c previousOrder : [SELECT Id, APTS_Order_Header_SAP_ID__c FROM Apttus_Config2__Order__c
                            WHERE Id = :oOrderToSubmit.Apttus_Config2__PreviousVersion__c LIMIT 1]) {
                        oOrderToSubmit.APTS_Order_Header_SAP_ID__c = previousOrder.APTS_Order_Header_SAP_ID__c;
                        orderToUpdateMap.put(oOrderToSubmit.Id, oOrderToSubmit);

                        previousOrder.APTS_Order_Header_SAP_ID__c = null;
                        orderToUpdateMap.put(oOrderToSubmit.Apttus_Config2__PreviousVersion__c, previousOrder);
                    }
                }

                //reset data on Amended Orders
                if (!orderToUpdateMap.isEmpty()) 
                {
                    APTS_OrderTriggerHandler.setTriggerDisabled(true);
                    Database.update(orderToUpdateMap.values());
                    APTS_OrderTriggerHandler.setTriggerDisabled(false);
                }

                //submit order
                APTS_OrderUtils.submitMultipleOrders(false, orderToSubmitMap.values());

                //update data after submitting order
                //clear ATP check result on Order Line Items
                List<Apttus_Config2__OrderLineItem__c> orderLineItemList = APTS_OrderUtils.clearATPResultsMultiOrders(orderToSubmitMap.keySet());
                if (!orderLineItemList.isEmpty()) 
                {
                    APTS_OrderUtils.stopOrderLineItemTrigger();
                    Database.update(orderLineItemList);
                    APTS_OrderUtils.startOrderLineItemTrigger();
                }

                if (oOrderToSubmit.Apttus_CMConfig__AgreementId__c != null && oOrderToSubmit.Apttus_CMConfig__AgreementId__r.RecordType.Name == APTS_OrderConstants.CONSUMPTION_MODEL) 
                {
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
                validationMsgSet.add(e.getStackTraceString());
            }
        }

        return validationMsgSet;
    }

    public static Apttus_Config2__Order__c getSubmitOrder(Id submitObjectId) {

        Apttus_Config2__Order__c oOrderToSubmit = null;

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
                                       APTS_SAP_OrderType__c,
                                       Approval_Status__c,
                                       APTS_External_Invoice_Number__c,
                                       APTS_Invoice__r.APTS_External_Invoice_Number__c
                                       FROM Apttus_Config2__Order__c WHERE Id = :submitObjectId LIMIT 1];

        if (!listOrdersToSub.isEmpty()) { 

            oOrderToSubmit = listOrdersToSub[0];
        }

        return  oOrderToSubmit;
    }

    public static Set<String> validate(Apttus_Config2__Order__c oOrderToSubmit) {

        Set<String> validationMsgSet = new Set<String>();

        String sValidationMsg = '';

        if (oOrderToSubmit != null) {

            sValidationMsg = oOrderToSubmit.Apttus_Config2__SoldToAccountId__c == null || oOrderToSubmit.Apttus_Config2__SoldToAccountId__r.SAP_Customer_ID__c == null ? APTS_OrderConstants.SOLD_TO : sValidationMsg;
            sValidationMsg = oOrderToSubmit.Apttus_Config2__BillToAccountId__c == null || oOrderToSubmit.Apttus_Config2__BillToAccountId__r.SAP_Customer_ID__c == null ?  APTS_OrderConstants.BILL_TO : sValidationMsg;
            sValidationMsg = oOrderToSubmit.Apttus_Config2__ShipToAccountId__c == null || oOrderToSubmit.Apttus_Config2__ShipToAccountId__r.SAP_Customer_ID__c == null ? APTS_OrderConstants.SHIP_TO : sValidationMsg;
            sValidationMsg = oOrderToSubmit.APTS_Payer__c == null || oOrderToSubmit.APTS_Payer__r.SAP_Customer_ID__c == null ? APTS_OrderConstants.PAYER_TO : sValidationMsg;

            if (APTS_OrderConstants.PO_HAS_EXPIRED.equalsIgnoreCase(oOrderToSubmit.Apttus_Config2__PONumber__c)) {
                sValidationMsg = oOrderToSubmit.Apttus_Config2__PONumber__c;
            }

            if (String.isNotBlank(sValidationMsg)) {
                validationMsgSet.add('SAP Customer Id can\'t be NULL on ' + sValidationMsg + ' account');
            }

            if (oOrderToSubmit.Apttus_Config2__PreviousVersion__c != null && !(oOrderToSubmit.APTS_SAP_OrderType__c.containsIgnoreCase(APTS_OrderConstants.XD) || oOrderToSubmit.APTS_SAP_OrderType__c.containsIgnoreCase(APTS_OrderConstants.XL))) {
             //V107 ++<<
              /*  List<Apttus_Config2__OrderFulfillmentLineItem__c> listFul = [
                            SELECT Id
                            FROM Apttus_Config2__OrderFulfillmentLineItem__c
                            WHERE Apttus_Config2__OrderId__c = :oOrderToSubmit.Apttus_Config2__PreviousVersion__c and APTS_Fulfilled_Quantity__c > 0 LIMIT 10000]; //V107 ++ <<>>

                if (!listFul.isEmpty()) {
                    validationMsgSet.add(APTS_OrderConstants.SUB_ERR_ORDER_IN_FUL);
                } else { */ //V107 ++ >>
                    //v104 ++ << Machine Cancel
                    Boolean isPendingCase = false;
                    String caseNumber = '';

                    for (Case oCase : [SELECT Status, CaseNumber FROM Case WHERE ApptusOrder__c = : oOrderToSubmit.Id AND ApptusOrder__r.Apttus_Config2__Status__c = :APTS_OrderConstants.STATUS_PENDING_CANCEL AND ApptusOrder__r.APTS_Order_Type__c =: APTS_OrderConstants.MACHINE_ORDER]) {
                        if (!(APTS_OrderConstants.CLOSED.equalsIgnoreCase(oCase.Status) || APTS_OrderConstants.CANCELED.equalsIgnoreCase(oCase.Status))) {
                            isPendingCase = true;
                            caseNumber += oCase.CaseNumber + ' ';
                        }
                    }

                    if (isPendingCase) {
                        validationMsgSet.add(APTS_OrderConstants.OPEN_CASE_VALIDATION_CANCELLATION + caseNumber);
                    } else {

                        //If Machine Cancellation, check if Primary L1 has reason for rejection or not
                        //Else we need to check all OLI
                        List<Boolean> isPrimaryLI1 = new List<Boolean>();
                        isPrimaryLI1.add(true);
                        if (!APTS_OrderConstants.MACHINE_ORDER.equalsIgnoreCase(oOrderToSubmit.APTS_Order_Type__c)) {
                            isPrimaryLI1.add(false);
                        }

                        List<Apttus_Config2__OrderLineItem__c> orderLineItemList = [
                                    SELECT Id,
                                    Apttus_Config2__Status__c
                                    FROM Apttus_Config2__OrderLineItem__c
                                    WHERE Apttus_Config2__OrderId__c = :oOrderToSubmit.Id AND Apttus_Config2__Status__c = :APTS_OrderConstants.STATUS_PENDING_CANCEL AND APTS_Reason_For_Rejection__c = null AND APTS_Is_Primary_L1_Line__c IN :isPrimaryLI1 LIMIT 10000];

                        if (!orderLineItemList.isEmpty()) {
                            validationMsgSet.add(APTS_OrderConstants.REJECT_REASON_REQ);
                        }
                    }
                    //v104 ++ >>
              //  } //V107 ++<<>>
            }
        } else {
            validationMsgSet.add(APTS_OrderConstants.INVALID_ORDER);
        }

        return validationMsgSet;
    }



    public PageReference back() {

        PageReference pageRef = new PageReference('/' + submitObjectId);

        return pageRef;
    }
    
    //v105 ++ <<
    public static void setInvoiceLineItemOnOLI(Apttus_Config2__Order__c oOrder)
    {
        try{
        if(oOrder != null && oOrder.APTS_Invoice__c != null)
        {
            List<Apttus_Config2__OrderLineItem__c> orderLineItemList = [
                                        SELECT Id,
                                        Apttus_Config2__AssetLineItemId__c,
                                        Apttus_Config2__AssetLineItemId__r.Apttus_Config2__BusinessLineItemId__c,
                                        APTS_Ext_Invoice_Line_Number__c,
                                        Apttus_Config2__OrderId__c
                                        FROM Apttus_Config2__OrderLineItem__c
                                        WHERE Apttus_Config2__OrderId__c = :oOrder.Id 
                                        AND Apttus_Config2__AssetLineItemId__c != null];
            
           
            set<Id> setOriginalOLIs = new set<ID>();
            Map<id, string> mapInvoiceNumberToOLI = new Map<id, string>();
            List<Apttus_Config2__OrderLineItem__c> oLIToUpdateList = new List<Apttus_Config2__OrderLineItem__c>();
            
            //V106 ++ <<
            Apttus_Config2__Order__c oReturnOrder = new Apttus_Config2__Order__c();
            oReturnOrder.Id = oOrder.Id;
            oReturnOrder.APTS_External_Invoice_Number__c = oOrder.APTS_Invoice__r.APTS_External_Invoice_Number__c;
            APTS_OrderUtils.stopOrderTrigger();
            database.update(oReturnOrder, false);
            APTS_OrderUtils.startOrderTrigger();
            //V106 ++ >>
            
            if(!orderLineItemList.isEmpty())
            {
                for(Apttus_Config2__OrderLineItem__c oli: orderLineItemList)
                {
                    setOriginalOLIs.add(oli.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__BusinessLineItemId__c);
                }
                
                List<Apttus_Billing__InvoiceLineItem__c> oListILI = [Select id,Apttus_Billing__InvoiceId__c, External_Invoice_Line_Number__c, APTS_Order_Line__c, APTS_RefOrderLineNumber__c from Apttus_Billing__InvoiceLineItem__c where Apttus_Billing__InvoiceId__c =: oOrder.APTS_Invoice__c and APTS_Order_Line__c IN:setOriginalOLIs];
                    
                if(!oListILI.isEmpty()){
                    for(Apttus_Billing__InvoiceLineItem__c invoiceLineItem : oListILI){
                        mapInvoiceNumberToOLI.put(invoiceLineItem.APTS_Order_Line__c, invoiceLineItem.APTS_RefOrderLineNumber__c); 
                    }
                    for(Apttus_Config2__OrderLineItem__c oLI: orderLineItemList){
                        string invoiceLineNumber = mapInvoiceNumberToOLI.get(oLI.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__BusinessLineItemId__c);
                        oLI.APTS_Ext_Invoice_Line_Number__c = invoiceLineNumber;
                        oLIToUpdateList.add(oLI);
                    }
                    if(!oLIToUpdateList.isEmpty()){
                        APTS_OrderUtils.stopOrderLineItemTrigger();
                        Database.update(oLIToUpdateList, false);
                        APTS_OrderUtils.startOrderLineItemTrigger();
                    }
                }
            }
            }
        }
        catch(Exception e){
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', oOrder.Id, 'OM', false, false, null, false);      
        }
    }
    //v105 ++ >> 
}