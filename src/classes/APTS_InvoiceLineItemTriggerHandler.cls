/**
* @author        Balashanthi A
* @date          07.07.2018           
* @description   Invoice Line Item Trigger Handler
* @revision(s)
*/
// V101 Balashanthi A : Defect # 22559 - Order Status not to Completed even after Invoice is linked
// V102 Renuka 03-09-2019 DFT2C-1366 - To avoid Exception-Duplicate id in list, List is coverted into Map.
// V103 Renuka 20-02-2019 DQ-869 - Stop updating OneTime BS 'Invoiced Cancelled' to 'Invoiced'.
// V104 Renuka 25-08-2020 DQ-2752 - Update BS with correct Invoice
// V105 Aarthi 03-12-2020 DQ-3871 - Modified the criteria of machine order status to completed
// V106 Renuka 11-03-2021 DQ-5440 - Fix fo null pointer exception

public with sharing class APTS_InvoiceLineItemTriggerHandler implements ITriggerHandler{
    private static final String XA = 'XA';
    private static final String XC = 'XC';
    private static final String XD = 'XD';
    private static final String XL = 'XL';
    private static final String XB = 'XB';
    Set<String> orderSubType = new Set<String>{'Conversion Order','Renewal','Indexation'};//V106
    Set<String> contractChange = new Set<String>{'Yes'};//V106
    Set<String> adminOrderTypes = new Set<String>{'XD09','XD12','XC09'};//V106
  
    /** Method Name  : isDisabled
    * Description : isDisabled of Invoice Line Item Trigger
    **/
    public boolean isDisabled(){
        try{return (TriggerSettings__c.getInstance().APTS_InvoiceLineItemTrigger__c == true ? true : false);}catch(Exception ex){return false;}
    }

    /** Method Name : beforeInsert
    * Description   : Method to get executed before Inserting a Invoice Line Item record
    **/
    public void beforeInsert(List<SObject> newItems){
        // Type Casting to invoice Line item
        Map<String, Id> prodSapSfIdMap = new Map<String, Id>();
        Map<String, Id> shilToIdMap = new Map<String, Id>();
        Set<String> prodSapIdSet = new Set<String>();
        Set<String> refOrderLine = new Set<String>();
        Set<String> refOrder = new Set<String>();
        Map<String, Id> invoiceLIIdMap = new Map<String, Id>();
        Set<String> invoiceExtIdSet = new Set<String>();
        set<string> invoiceShipToIdSet = new set<string>();
        Map<String,Map<String,Apttus_Config2__OrderLineItem__c>> orderOLISAPReferenceMap = new Map<String,Map<String,Apttus_Config2__OrderLineItem__c>>();
        List<Apttus_Billing__InvoiceLineItem__c>  invoiceLineItemList = (List<Apttus_Billing__InvoiceLineItem__c>)newItems;
        try{
            for(Apttus_Billing__InvoiceLineItem__c invoiceLineitem : invoiceLineItemList){
                if(invoiceLineitem.APTS_Product_SAP_External_Id__c != null){
                    prodSapIdSet.add(invoiceLineitem.APTS_Product_SAP_External_Id__c);
                }
                if(invoiceLineitem.APTS_External_Invoice_Line_Number__c != null){
                    invoiceExtIdSet.add(invoiceLineitem.APTS_External_Invoice_Line_Number__c);
                }
                if(invoiceLineitem.Apttus_Billing__ShipToAccountId__c != null){
                    invoiceShipToIdSet.add(invoiceLineitem.Apttus_Billing__ShipToAccountId__c);
                }
                // Ref Order line from SAP
                if(String.isNotBlank(invoiceLineitem.APTS_RefOrderLineNumber__c)){
                    if(invoiceLineitem.APTS_RefOrderLineNumber__c.length() < 6){
                        String modifiedString = APTS_BIRUtils.addLeadingZeros(invoiceLineitem.APTS_RefOrderLineNumber__c,6);
                        refOrderLine.add(modifiedString);
                    }
                    refOrderLine.add(invoiceLineitem.APTS_RefOrderLineNumber__c);
                }
                // Ref Order Number from SAP
                if(String.isNotBlank(invoiceLineitem.APTS_RefOrderNumber__c)){
                    if(invoiceLineitem.APTS_RefOrderNumber__c.length() < 10){
                        String tempValue = APTS_BIRUtils.addLeadingZeros(invoiceLineitem.APTS_RefOrderNumber__c,10);
                        refOrder.add(tempValue);
                    }
                    refOrder.add(invoiceLineitem.APTS_RefOrderNumber__c);
                }  
            }
            if(!prodSapIdSet.isEmpty()){
                for(Product2 prod : [SELECT Id,
                                                APTS_SAPExtID__c 
                                                FROM product2 
                                                WHERE APTS_SAPExtID__c In : prodSapIdSet limit 50000]){
                    prodSapSfIdMap.put(prod.APTS_SAPExtID__c, prod.Id);
                }
            }

            if(!invoiceExtIdSet.isEmpty()){
                for(Apttus_Billing__Invoice__c inv : [SELECT Id,
                                                            APTS_External_Invoice_Number__c 
                                                        FROM Apttus_Billing__Invoice__c 
                                                        WHERE APTS_External_Invoice_Number__c IN : invoiceExtIdSet 
                                                        LIMIT 50000]){
                    invoiceLIIdMap.put(inv.APTS_External_Invoice_Number__c, inv.Id);
                }
            }
            if(!invoiceShipToIdSet.isEmpty()){
                for(Account acc : [select Id, SAP_Customer_ID__c from Account where SAP_Customer_ID__c IN : invoiceShipToIdSet ]){
                    
                    shilToIdMap.put(acc.SAP_Customer_ID__c, acc.Id);
                }
                
            }
            // Retrieve the related order Line item  which is invoiced
            //system.debug('%%%%% refOrderLine ==> '+refOrderLine);
            //system.debug('%%%%% refOrder ==> '+refOrder);
            if(!refOrderLine.isEmpty()
                && !refOrder.isEmpty()){
                for(Apttus_Config2__OrderLineItem__c orderLineItem :[SELECT Id,
                                                                            Apttus_Config2__OrderId__c,
                                                                            Apttus_Config2__OrderId__r.APTS_Order_Type__c,
                                                                            APTS_SAP_Order_Line_Item_Number__c,
                                                                            APTS_Original_Order_Line_Item__r.Apttus_Config2__OrderId__r.APTS_Order_Type__c,
                                                                            APTS_Original_Order_Line_Item__c,
                                                                            Apttus_Config2__OrderId__r.APTS_Order_Header_SAP_ID__c,
                                                                            APTS_BillingSchedule__c,Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c
                                                                        FROM Apttus_Config2__OrderLineItem__c
                                                                        WHERE APTS_SAP_Order_Line_Item_Number__c IN: refOrderLine 
                                                                        AND Apttus_Config2__OrderId__r.APTS_Order_Header_SAP_ID__c IN : refOrder
                                                                        LIMIT 50000]){
                    
                    if(orderOLISAPReferenceMap.containsKey(orderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Header_SAP_ID__c)){
                        Map<String,Apttus_Config2__OrderLineItem__c> tempList = orderOLISAPReferenceMap.get(orderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Header_SAP_ID__c);
                        if (!tempList.containsKey(orderLineItem.APTS_SAP_Order_Line_Item_Number__c)){
                            tempList.put(orderLineItem.APTS_SAP_Order_Line_Item_Number__c,orderLineItem);
                            orderOLISAPReferenceMap.put(orderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Header_SAP_ID__c,tempList);
                        }
                    }else{
                        orderOLISAPReferenceMap.put(orderLineItem.Apttus_Config2__OrderId__r.APTS_Order_Header_SAP_ID__c, new Map<String,Apttus_Config2__OrderLineItem__c>{orderLineItem.APTS_SAP_Order_Line_Item_Number__c => orderLineItem});
                    }  
                }
            }
            //system.debug('%%%%%% orderOLISAPReferenceMap Keyset ==>'+orderOLISAPReferenceMap.keySet());
            for(Apttus_Billing__InvoiceLineItem__c invoiceLineitem : invoiceLineItemList){
                //populate product lookup
                if(invoiceLineitem.APTS_Product_SAP_External_Id__c != null){
                    if(!prodSapSfIdMap.isEmpty()
                        && prodSapSfIdMap.containsKey(invoiceLineitem.APTS_Product_SAP_External_Id__c)
                        && prodSapSfIdMap.get(invoiceLineitem.APTS_Product_SAP_External_Id__c) != null){
                         invoiceLineitem.APTS_Product__c = prodSapSfIdMap.get(invoiceLineitem.APTS_Product_SAP_External_Id__c);
                    }
                }
                //populate invoice lookup
                if(invoiceLineitem.APTS_External_Invoice_Line_Number__c != null){
                    if(!invoiceLIIdMap.isEmpty() 
                        && invoiceLIIdMap.containsKey(invoiceLineitem.APTS_External_Invoice_Line_Number__c)
                        && invoiceLIIdMap.get(invoiceLineitem.APTS_External_Invoice_Line_Number__c) != null){
                        invoiceLineitem.Apttus_Billing__InvoiceId__c = invoiceLIIdMap.get(invoiceLineitem.APTS_External_Invoice_Line_Number__c);
                    }
                }
                //populate ShipTo lookup
                if(invoiceLineitem.Apttus_Billing__ShipToAccountId__c !=null){
                    if(!shilToIdMap.isEmpty() && shilToIdMap.containsKey(invoiceLineitem.Apttus_Billing__ShipToAccountId__c) && shilToIdMap.get(invoiceLineitem.Apttus_Billing__ShipToAccountId__c) != null){
                        invoiceLineitem.Apttus_Billing__ShipToAccountId__c = shilToIdMap.get(invoiceLineitem.Apttus_Billing__ShipToAccountId__c);
                    }
                    
                }
                // Populate Original Order line Number and Billing Schedule for Admin Order and  only Orde Line for one time order
                if(String.isNotBlank(invoiceLineitem.APTS_RefOrderLineNumber__c)
                    && String.isNotBlank(invoiceLineitem.APTS_RefOrderNumber__c)
                    && !orderOLISAPReferenceMap.isEmpty()){
                    if(orderOLISAPReferenceMap.containsKey(invoiceLineitem.APTS_RefOrderNumber__c)
                        && orderOLISAPReferenceMap.get(invoiceLineitem.APTS_RefOrderNumber__c) != null){
                            Map<String,Apttus_Config2__OrderLineItem__c> orderOrderLineMap = orderOLISAPReferenceMap.get(invoiceLineitem.APTS_RefOrderNumber__c);
                            if(orderOrderLineMap.containsKey(invoiceLineitem.APTS_RefOrderLineNumber__c)
                                && orderOrderLineMap.get(invoiceLineitem.APTS_RefOrderLineNumber__c) != null){
                                Apttus_Config2__OrderLineItem__c orderLineRef = orderOrderLineMap.get(invoiceLineitem.APTS_RefOrderLineNumber__c);
                                if(orderLineRef.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c != null 
                                    && adminOrderTypes.contains(orderLineRef.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c)){
                                    invoiceLineitem.APTS_Order_Line__c = orderLineRef.APTS_Original_Order_Line_Item__c;
                                    invoiceLineitem.Apttus_Billing__BillingScheduleId__c = orderLineRef.APTS_BillingSchedule__c;
                                    invoiceLineitem.APTS_AdminOrder_Line__c = orderLineRef.Id;
                                }else{
                                    invoiceLineitem.APTS_Order_Line__c = orderLineRef.Id;
                                } 
                            }else{// if the Invoice SAP reference length is less than 6
                                if(orderOrderLineMap.containsKey(APTS_BIRUtils.addLeadingZeros(invoiceLineitem.APTS_RefOrderLineNumber__c,6))
                                    && orderOrderLineMap.get(APTS_BIRUtils.addLeadingZeros(invoiceLineitem.APTS_RefOrderLineNumber__c,6)) != null){
                                    Apttus_Config2__OrderLineItem__c orderLineRef = orderOrderLineMap.get(APTS_BIRUtils.addLeadingZeros(invoiceLineitem.APTS_RefOrderLineNumber__c,6));
                                    if(orderLineRef.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c != null 
                                        && adminOrderTypes.contains(orderLineRef.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c)){
                                        invoiceLineitem.APTS_Order_Line__c = orderLineRef.APTS_Original_Order_Line_Item__c;
                                        invoiceLineitem.Apttus_Billing__BillingScheduleId__c = orderLineRef.APTS_BillingSchedule__c;
                                        invoiceLineitem.APTS_AdminOrder_Line__c = orderLineRef.Id;
                                    }else{
                                        invoiceLineitem.APTS_Order_Line__c = orderLineRef.Id;
                                    } 
                                }
                            }// End of else
                    }else{// if the SAP Order Reference number is less than 10
                        if(orderOLISAPReferenceMap.containsKey(APTS_BIRUtils.addLeadingZeros(invoiceLineitem.APTS_RefOrderNumber__c, 10))
                            && orderOLISAPReferenceMap.get(APTS_BIRUtils.addLeadingZeros(invoiceLineitem.APTS_RefOrderNumber__c, 10)) != null){
                            Map<String,Apttus_Config2__OrderLineItem__c> orderOrderLineMap = orderOLISAPReferenceMap.get(APTS_BIRUtils.addLeadingZeros(invoiceLineitem.APTS_RefOrderNumber__c, 10));
                            if(orderOrderLineMap.containsKey(invoiceLineitem.APTS_RefOrderLineNumber__c)
                                && orderOrderLineMap.get(invoiceLineitem.APTS_RefOrderLineNumber__c) != null){
                                //system.debug('inside APTS_RefOrderLineNumber__c ==>'+orderOrderLineMap.get(invoiceLineitem.APTS_RefOrderLineNumber__c));
                                Apttus_Config2__OrderLineItem__c orderLineRef = orderOrderLineMap.get(invoiceLineitem.APTS_RefOrderLineNumber__c);
                                if(orderLineRef.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c != null 
                                    && adminOrderTypes.contains(orderLineRef.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c)){
                                    invoiceLineitem.APTS_Order_Line__c = orderLineRef.APTS_Original_Order_Line_Item__c;
                                    invoiceLineitem.Apttus_Billing__BillingScheduleId__c = orderLineRef.APTS_BillingSchedule__c;
                                    invoiceLineitem.APTS_AdminOrder_Line__c = orderLineRef.Id;
                                }else{
                                    invoiceLineitem.APTS_Order_Line__c = orderLineRef.Id;
                                } 
                            }else{// if the SAP order Line number is less than 6
                                if(orderOrderLineMap.containsKey(APTS_BIRUtils.addLeadingZeros(invoiceLineitem.APTS_RefOrderLineNumber__c,6))
                                    && orderOrderLineMap.get(APTS_BIRUtils.addLeadingZeros(invoiceLineitem.APTS_RefOrderLineNumber__c,6)) != null){
                                    Apttus_Config2__OrderLineItem__c orderLineRef = orderOrderLineMap.get(APTS_BIRUtils.addLeadingZeros(invoiceLineitem.APTS_RefOrderLineNumber__c,6));
                                    if(orderLineRef.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c != null 
                                        && adminOrderTypes.contains(orderLineRef.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c)){
                                        invoiceLineitem.APTS_Order_Line__c = orderLineRef.APTS_Original_Order_Line_Item__c;
                                        invoiceLineitem.Apttus_Billing__BillingScheduleId__c = orderLineRef.APTS_BillingSchedule__c;
                                        invoiceLineitem.APTS_AdminOrder_Line__c = orderLineRef.Id;
                                    }else{
                                        invoiceLineitem.APTS_Order_Line__c = orderLineRef.Id;
                                    } 
                                }
                            } // End of Else less than 6
                        }
                    }// end of else
                }// End of if
            }// End of for   
            //system.debug('%%%%% Invoice to Update ==> '+invoiceLineItemList);
        }catch(Exception ex){
            //system.debug('*****Exception Caught in method beforeInsert****'+ex);
            //system.debug('*****Exception e.getLineNumber() in beforeInsert****'+ex.getLineNumber());
            APTS_BIRUtils.logError(null,null,null,ex,APTS_BIRUtils.TRIGGERVALUE,APTS_BIRUtils.ORDEROBJECTNAME,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,true);
        }
    } 

    /** Method Name : beforeUpdate
    *   Description : Method to get executed before Updating a Invoice Line Item record
    **/ 
    public void beforeUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldItems){}

    /** Method Name : beforeDelete
    *   Description : before Delete of Invoice Line Item record
    **/
    public void beforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems){} 
   
    /** Method Name : afterInsert
    *   Description : afterInsert of Invoice Line Item record
    **/
    public void afterInsert(List<SObject> newInvoiceList, Map<Id, SObject> newItems){
        Map<Id,Id> orderLineIdInvoiceMap = new Map<Id,Id>();
        Map<String, Id> refOrder = new Map<String, Id>();
        List<Apttus_Config2__Order__c> orderToUpdateList = new List<Apttus_Config2__Order__c>();
        Map<Id,Id> billingScheduleToInvoiceMap = new Map<Id,Id>();
        
        try{
            // Type Casting to invoice Line item
            Map<Id,Apttus_Billing__InvoiceLineItem__c>  invoiceNewLineItemMap = (Map<Id,Apttus_Billing__InvoiceLineItem__c>)newItems;
            for(Apttus_Billing__InvoiceLineItem__c invoiceLineitem : invoiceNewLineItemMap.values()){
                // Original Order Line
                if(invoiceLineitem.APTS_Order_Line__c != null){
                    orderLineIdInvoiceMap.put(invoiceLineitem.APTS_Order_Line__c,invoiceLineitem.Apttus_Billing__InvoiceId__c);
                }
                //V104 - AdminOrders store BillingSchedule in the map
                if(invoiceLineitem.Apttus_Billing__BillingScheduleId__c != null){
                    billingScheduleToInvoiceMap.put(invoiceLineitem.Apttus_Billing__BillingScheduleId__c,invoiceLineitem.Apttus_Billing__InvoiceId__c);
                }
                // Ref Order Number from SAP
                if(String.isNotBlank(invoiceLineitem.APTS_RefOrderNumber__c)){
                    if(invoiceLineitem.APTS_RefOrderNumber__c.length() < 10){
                        String tempValue = APTS_BIRUtils.addLeadingZeros(invoiceLineitem.APTS_RefOrderNumber__c,10);
                        refOrder.put(tempValue,invoiceLineitem.Apttus_Billing__InvoiceId__c);
                    }
                    refOrder.put(invoiceLineitem.APTS_RefOrderNumber__c,invoiceLineitem.Apttus_Billing__InvoiceId__c);
                }
            }
            //system.debug('*****orderLineIdInvoiceMap Size*****'+orderLineIdInvoiceMap.size());
            //system.debug('*****orderLineIdInvoiceMap*****'+orderLineIdInvoiceMap.keySet());
            // Invoice Update on billing Schedules -- Logic starts
            List<Apttus_Billing__BillingSchedule__c> billingSchedulesToUpdate = new List<Apttus_Billing__BillingSchedule__c>();
            Map<Id,Id> orderIdToUpdateStatus = new Map<Id,Id>();
            //V105 ++ << - Map to hold the current status of the original machine orders
            Map<Id, OrderDetailsWrapper> mapOriginalOrderStatuses = new Map<Id, OrderDetailsWrapper>();
            if(!orderLineIdInvoiceMap.isEmpty()){
                for(Apttus_Billing__BillingSchedule__c billingSchedule :[SELECT Id,
                                                                            Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__r.APTS_Order_Type__c,
                                                                            Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c,
                                                                            Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__r.APTS_Contract_Change__c,
                                                                            Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__r.APTS_Status__c,
                                                                            Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__c,
                                                                            Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c,
                                                                            Apttus_Billing__OrderLineItemId__c,
                                                                            Apttus_Billing__Status__c,
                                                                            Apttus_Billing__ReadyForInvoiceDate__c,
                                                                            Apttus_Billing__OrderLineItemId__r.Apttus_Config2__PriceType__c,
                                                                            Apttus_Billing__OrderLineItemId__r.Apttus_Config2__BillingFrequency__c,
                                                                            APTS_Admin_Order_Line__c,
                                                                            APTS_Admin_Order_Line__r.Apttus_Config2__OrderId__c
                                                                        FROM Apttus_Billing__BillingSchedule__c
                                                                        WHERE Apttus_Billing__OrderLineItemId__c IN:orderLineIdInvoiceMap.keySet()
                                                                        LIMIT 50000]){
                    //V105 ++ <<
                    OrderDetailsWrapper oOrderWrapper = new OrderDetailsWrapper();  
                    if(billingSchedule.Apttus_Billing__OrderLineItemId__c != null && 
                        billingSchedule.Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__c != null &&
                        billingSchedule.Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c != null){
                        
                        oOrderWrapper = getOriginalOrderDetails(billingSchedule);
                    }
                    
                    //V105 ++ >>                                 
                    if(billingSchedule.APTS_Admin_Order_Line__c != null 
                        && APTS_BIRUtils.PENDINGINVOICED.equalsIgnoreCase(billingSchedule.Apttus_Billing__Status__c)
                        && billingSchedule.Apttus_Billing__ReadyForInvoiceDate__c <= system.today()){ // Processed by Batch
                        if(billingScheduleToInvoiceMap.containsKey(billingSchedule.Id)
                            && billingScheduleToInvoiceMap.get(billingSchedule.Id) != null){//V104 
                            billingSchedule.APTS_Invoice__c = billingScheduleToInvoiceMap.get(billingSchedule.Id);
                            billingSchedule.Apttus_Billing__Status__c = APTS_BIRUtils.INVOICEDSTATUS;
							billingSchedulesToUpdate.add(billingSchedule);
						}
                        // Original Order Status != Completed, then add in the update Order Set
                        if(billingSchedule.Apttus_Billing__OrderLineItemId__c != null 
                            && (contractChange.contains(billingSchedule.Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__r.APTS_Contract_Change__c)
                                || !orderSubType.contains(billingSchedule.Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c))
                            && !APTS_BIRUtils.COMPLETED.equalsIgnoreCase(billingSchedule.Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__r.APTS_Status__c)){
                            orderIdToUpdateStatus.put(billingSchedule.APTS_Admin_Order_Line__r.Apttus_Config2__OrderId__c,billingSchedule.Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__c);
                            mapOriginalOrderStatuses.put(billingSchedule.Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__c, oOrderWrapper); //V105 ++ <<>>
                        }
                        
                    }else{
                        // Recurring billing
                        if(APTS_BIRUtils.MACHINE_ORDER.equalsIgnoreCase(billingSchedule.Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__r.APTS_Order_Type__c)){
                            // Machine Order One Time Lines
                            if(APTS_BIRUtils.ONETIME.equalsIgnoreCase(billingSchedule.Apttus_Billing__OrderLineItemId__r.Apttus_Config2__PriceType__c)
                                && APTS_BIRUtils.PENDINGBILLING.equalsIgnoreCase(billingSchedule.Apttus_Billing__Status__c)){//v103
                                billingSchedule.Apttus_Billing__Status__c = APTS_BIRUtils.INVOICEDSTATUS;
                                if(orderLineIdInvoiceMap.containsKey(billingSchedule.Apttus_Billing__OrderLineItemId__c)
                                    && orderLineIdInvoiceMap.get(billingSchedule.Apttus_Billing__OrderLineItemId__c) != null){
                                    billingSchedule.APTS_Invoice__c = orderLineIdInvoiceMap.get(billingSchedule.Apttus_Billing__OrderLineItemId__c);
                                }
                                billingSchedulesToUpdate.add(billingSchedule);
                            }
                           
                            // v101 >> changes for defect #22559 Starts
                            // One time billing invoice also update the status as "Completed"
                            if((contractChange.contains(billingSchedule.Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__r.APTS_Contract_Change__c)
                                || !orderSubType.contains(billingSchedule.Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c))
                                && !APTS_BIRUtils.COMPLETED.equalsIgnoreCase(billingSchedule.Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__r.APTS_Status__c)){
                                orderIdToUpdateStatus.put(billingSchedule.Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__c,billingSchedule.Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__c);
                                mapOriginalOrderStatuses.put(billingSchedule.Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__c, oOrderWrapper); //V105 ++ <<>>
                            }
                            // v101 << changes for defect #22559 Ends
                        }
                        // one time
                        else if(String.isNotEmpty(billingSchedule.Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c)
                                && (billingSchedule.Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c.containsIgnoreCase(XA) 
                                        || billingSchedule.Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c.containsIgnoreCase(XC)
                                        || billingSchedule.Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c.containsIgnoreCase(XD) 
                                        || billingSchedule.Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c.containsIgnoreCase(XL)
                                        || billingSchedule.Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c.containsIgnoreCase(XB))
                            && APTS_BIRUtils.PENDINGBILLING.equalsIgnoreCase(billingSchedule.Apttus_Billing__Status__c)
                            && APTS_BIRUtils.ONETIME.equalsIgnoreCase(billingSchedule.Apttus_Billing__OrderLineItemId__r.Apttus_Config2__PriceType__c)){
                                billingSchedule.Apttus_Billing__Status__c = APTS_BIRUtils.INVOICEDSTATUS;
                                if(orderLineIdInvoiceMap.containsKey(billingSchedule.Apttus_Billing__OrderLineItemId__c)
                                    && orderLineIdInvoiceMap.get(billingSchedule.Apttus_Billing__OrderLineItemId__c) != null){
                                    billingSchedule.APTS_Invoice__c = orderLineIdInvoiceMap.get(billingSchedule.Apttus_Billing__OrderLineItemId__c);
                                }
                                if((contractChange.contains(billingSchedule.Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__r.APTS_Contract_Change__c)
                                    || !orderSubType.contains(billingSchedule.Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c))
                                    && !APTS_BIRUtils.COMPLETED.equalsIgnoreCase(billingSchedule.Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__r.APTS_Status__c)){
                                    orderIdToUpdateStatus.put(billingSchedule.Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__c,billingSchedule.Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__c);
                                    mapOriginalOrderStatuses.put(billingSchedule.Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__c, oOrderWrapper); //V105 ++ <<>>
                                }
                                billingSchedulesToUpdate.add(billingSchedule);
                        }
                    }
                }// End of for Loop
            }
            //system.debug('*****billingSchedulesToUpdate Size*****'+billingSchedulesToUpdate.size());
            //system.debug('*****billingSchedulesToUpdate*****'+billingSchedulesToUpdate);
            if(!billingSchedulesToUpdate.isEmpty()){
                APTS_BillingScheduleTriggerHandler.isSkipBillingScheduleTrigger = true;
                Database.SaveResult[] updateList = Database.update(billingSchedulesToUpdate,false);
                APTS_BillingScheduleTriggerHandler.isSkipBillingScheduleTrigger = false;
                APTS_BIRUtils.logError(null,updateList,null,null,APTS_BIRUtils.TRIGGERVALUE,APTS_BIRUtils.BILLINGSCHEDULEOBJECTNAME,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,false);
            }
            //system.debug('*****orderIdToUpdateStatus Size*****'+orderIdToUpdateStatus.size());
            //system.debug('*****orderIdToUpdateStatus *****'+orderIdToUpdateStatus);

            // Update of Invoice and Order status @ Order Object Starts
            if(!refOrder.isEmpty()){
                for(Apttus_Config2__Order__c oOrder : [SELECT Id, 
                                                                APTS_Order_Type__c,
                                                                APTS_Order_Sub_Type__c,
                                                                Apttus_Config2__Status__c,
                                                                APTS_Status__c,APTS_SAP_OrderType__c,
                                                                APTS_Order_Header_SAP_ID__c
                                                            FROM Apttus_Config2__Order__c
                                                            WHERE APTS_Order_Header_SAP_ID__c IN : refOrder.keySet()
                                                            LIMIT 50000]){
                    if(adminOrderTypes.contains(oOrder.APTS_SAP_OrderType__c)){
                        //update Invoice @ Admin Order Header
                        if(refOrder.containsKey(oOrder.APTS_Order_Header_SAP_ID__c)
                            && refOrder.get(oOrder.APTS_Order_Header_SAP_ID__c) != null){
                            Apttus_Config2__Order__c adminOrderToUpdate = new Apttus_Config2__Order__c();
                            adminOrderToUpdate.Id = oOrder.Id;
                            adminOrderToUpdate.APTS_Invoice__c = refOrder.get(oOrder.APTS_Order_Header_SAP_ID__c);
                            adminOrderToUpdate.APTS_Status__c = APTS_BIRUtils.COMPLETED;
                            orderToUpdateList.add(adminOrderToUpdate); 
                        }
                        // Update the Status of the Original Order to Completed
                        if(!orderIdToUpdateStatus.isEmpty()
                            && orderIdToUpdateStatus.containsKey(oOrder.Id)){
                            if(orderIdToUpdateStatus.get(oOrder.Id) != null){
                                boolean bUpdateOriginalOrder = checkIfOrderUpdateNeeded(orderIdToUpdateStatus.get(oOrder.Id),mapOriginalOrderStatuses); //V105 ++ <<>>
                                if(bUpdateOriginalOrder){ //V105 ++ <<>>
                                    Apttus_Config2__Order__c originalOrderToUpdate = new Apttus_Config2__Order__c();
                                    originalOrderToUpdate.APTS_Status__c = APTS_BIRUtils.COMPLETED;
                                    originalOrderToUpdate.Id = orderIdToUpdateStatus.get(oOrder.Id);
                                    orderToUpdateList.add(originalOrderToUpdate);
                                } //V105 ++ <<>>
                            }
                        } 
                    }else{
                        Apttus_Config2__Order__c oOrderToUpdate = new Apttus_Config2__Order__c();
                        oOrderToUpdate.Id = oOrder.Id;
                        if(refOrder.containsKey(oOrder.APTS_Order_Header_SAP_ID__c)
                                && refOrder.get(oOrder.APTS_Order_Header_SAP_ID__c) != null){
                            oOrderToUpdate.APTS_Invoice__c = refOrder.get(oOrder.APTS_Order_Header_SAP_ID__c); 
                        }
                        if(!orderIdToUpdateStatus.isEmpty()
                            && orderIdToUpdateStatus.containsKey(oOrder.Id)
                            && !APTS_BIRUtils.COMPLETED.equalsIgnoreCase(oOrder.APTS_Status__c)){
                            //V105 ++ <<
                            boolean bUpdateOriginalOrder = checkIfOrderUpdateNeeded(oOrder.Id,mapOriginalOrderStatuses); //V105 ++ <<>>
                            if(bUpdateOriginalOrder){                                   
                                oOrderToUpdate.APTS_Status__c =  APTS_BIRUtils.COMPLETED;
                            } //V105 ++ >> 
                        }else{
                            if(!APTS_BIRUtils.COMPLETED.equalsIgnoreCase(oOrder.APTS_Status__c)
                                && (APTS_BIRUtils.CREDITMEMO.equalsIgnoreCase(oOrder.APTS_Order_Type__c)
                                        || APTS_BIRUtils.DEBITMEMO.equalsIgnoreCase(oOrder.APTS_Order_Type__c))){
                                oOrderToUpdate.APTS_Status__c =  APTS_BIRUtils.COMPLETED;
                            }
                        }                     
                        orderToUpdateList.add(oOrderToUpdate);
                    }
                }// End of "For"
            }
            //V102 >>
            Map<id,Apttus_Config2__Order__c> orderToUpdateMap = new Map<id,Apttus_Config2__Order__c>();
            orderToUpdateMap.putall(orderToUpdateList);
            //system.debug('*****orderToUpdateList Size*****'+orderToUpdateList.size());
            //system.debug('*****orderToUpdateList*****'+orderToUpdateList);
            if(orderToUpdateMap.values().size()>0){
                APTS_OrderUtils.stopOrderTrigger();
                Database.SaveResult[] srList = Database.update(orderToUpdateMap.values(), false);
                APTS_BIRUtils.logError(null,srList,null,null,APTS_BIRUtils.TRIGGERVALUE,APTS_BIRUtils.ORDEROBJECTNAME,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,false);
                APTS_OrderUtils.startOrderTrigger();
            }
            //V102 <<
        }catch(Exception ex){
            //system.debug('*****Exception Caught in method afterInsert****'+ex);
            //system.debug('*****Exception e.getLineNumber() in afterInsert****'+ex.getLineNumber());
            APTS_BIRUtils.logError(null,null,null,ex,APTS_BIRUtils.TRIGGERVALUE,APTS_BIRUtils.ORDEROBJECTNAME,APTS_BIRUtils.EMPTY_STRING,false,false,APTS_BIRUtils.EMPTY_STRING,true);
        }
    }
 
    /*** Method Name  : afterUpdate
    * Description : afterUpdate of Invoice Line Item record
    **/
    public void afterUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldItems){}
 
    /*** Method Name  : afterDelete
    * Description : after Delete of Invoice Line Item record
    **/ 
    public void afterDelete(List<SObject> oldList, Map<Id, SObject> oldItems){}
   
    /*** Method Name  : afterUndelete
    * Description : after Undelete of Invoice Line Item record
    **/
    public void afterUndelete(List<SObject> newList, Map<Id, SObject> newItems){}

    //V105 ++ <<
    /*** Method Name  : getOriginalOrderDetails
    * Description : This method copies the original order details from Billing schedule record to OrderDetailsWrapper
    **/
    public orderDetailsWrapper getOriginalOrderDetails(Apttus_Billing__BillingSchedule__c oBillingSchedule)
    {
        OrderDetailsWrapper objOrderWrapper = new OrderDetailsWrapper();
        if(oBillingSchedule.Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__c != null){
            objOrderWrapper.orderId = oBillingSchedule.Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__c;
            objOrderWrapper.customStatus = oBillingSchedule.Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__r.APTS_Status__c;
            objOrderWrapper.sapOrderType = oBillingSchedule.Apttus_Billing__OrderLineItemId__r.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c;
        }
        return objOrderWrapper;
    }

    /*** Class Name  : OrderDetailsWrapper
    * Description : Wrapper class to store the orderDetailsWrapper
    **/
    public class OrderDetailsWrapper{
       public Id orderId {get; set;}
       public string customStatus {get; set;}
       public string sapOrderType {get; set;}
    }

    /*** Method Name  : checkIfOrderUpdateNeeded
    * Description : Method to validate if the physical orders does need update of custom status = completed
    **/
    public boolean checkIfOrderUpdateNeeded(Id orderId, Map<Id, OrderDetailsWrapper> mapOriginalOrderStatuses){
        boolean bUpdateOrder = true;
        if(!mapOriginalOrderStatuses.IsEmpty() && mapOriginalOrderStatuses.containsKey(orderId)){
            OrderDetailsWrapper objOrderWrapper = mapOriginalOrderStatuses.get(orderId);
            Set<string> setEligibleOrderStatuses = new Set<string>{APTS_BIRUtils.ACTIVATED, APTS_OrderConstants.RETURNED, APTS_BIRUtils.INVOICINGSTATUS};
            if(objOrderWrapper != null && objOrderWrapper.sapOrderType != null 
                && (objOrderWrapper.sapOrderType.containsIgnoreCase(XA) || objOrderWrapper.sapOrderType.containsIgnoreCase(XB))){
                bUpdateOrder = setEligibleOrderStatuses.contains(objOrderWrapper.customStatus);
            }
            if(objOrderWrapper != null && objOrderWrapper.sapOrderType == null){
                bUpdateOrder=false;
            }
        }
        return bUpdateOrder;
    }
    //V105 ++ >> 
}