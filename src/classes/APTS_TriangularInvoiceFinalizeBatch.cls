/*************************************************************
@Name: APTS_TriangularInvoiceFinalizeBatch
@Author: Aarthi
@CreateDate: 13-01-2019
@Description: Finalize Invoice order
******************************************************************/
//V100 Aarthi 30-Apr-2020 Unplanned return - prevent Order submission without approval

global class APTS_TriangularInvoiceFinalizeBatch implements Database.Batchable<sObject>, Database.Stateful  {
    global string batchId;
    global list<Apttus_Config2__Order__c> orderList = new list<Apttus_Config2__Order__c>();
    global set<Id> orderIDSet = new set<Id>();
    private static final String S_ORDER = 'Order';
    private static final String S_FINALIZED = 'Finalized';
    public APTS_TriangularInvoiceFinalizeBatch(string previousbatchID,set<Id> orderIDsSet){
         this.orderIDSet = orderIDsSet; 
         this.batchId = previousbatchID; 
                 
    }
    
    /** Method : start
    ** Description : Query locator which will query records with given order Ids
    **/
    global Database.QueryLocator start(Database.BatchableContext BC) {
       string query =  'SELECT Id, Apttus_Config2__OrderId__c FROM Apttus_Config2__ProductConfiguration__c WHERE Apttus_Config2__BusinessObjectType__c = :S_ORDER and Apttus_Config2__Status__c <> :S_FINALIZED AND Apttus_Config2__OrderId__c IN :orderIDSet';
       return Database.getQueryLocator(query);
       
    }

    /** Method : execute
    ** Description : batch execute method would call finalizeCart method
    **/
    global void execute(Database.BatchableContext BC, List<Apttus_Config2__ProductConfiguration__c> cartList) {

        try
        {
            //Finalize cart
            for (Apttus_Config2__ProductConfiguration__c cart : cartList) {
                try {
                    
                     //Finalize
                     APTS_OrderUtils.finalizeCart(cart.Id); 
                    
                    //Syncronize
                    boolean isSuccess = APTS_OrderUtils.syncCart(cart.Id); 
                    
                            
                        
                } 
                catch (Exception ex) {
                system.debug('Exception occurred :: orderIDSet :: '+ orderIDSet);
                system.debug('Exception occurred :: cart.Id :: '+ cart.Id);
                system.debug('Exception occurred :: '+ ex.getMessage());
                     //APTS_OrderUtils.startOrderLineItemTrigger();   
                     //APTS_OrderUtils.startOrderTrigger();  
                }
            }

        } catch (Exception e) {APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', null, 'OM', false, true, null, true);}  


    }

    /** Method : finish
    ** Description : batch finish
    **/
    global void finish(Database.BatchableContext BC) {
    
        try {

        // QUERY REF Using BATCH ID and SEND Email 
        //APTS_OrderUtils.stopOrderLineItemTrigger();
        //APTS_OrderUtils.stopOrderTrigger();

        List<String> sendTo = new List<String>();

         List<APTS_TriangleInvoiceOrders__c> batchRecords = [select BillTo__c,Name,Id,SAP_Customer_ID__c,OrderReference__c,Payer__c,AccountLocationSapId__c,ProductId__c,Quantity__c,Requested_Delivery_Date__c,SAP_OrderType__c,Order_Sub_Type__c,SellingUom__c,SoldTo__c,HasError__c,ErrorMessage__c, Order__c,Cart_Id__c, Order_Name__c,Pricing_Date__c, Invoice_Remarks__c, PO__c,APTS_Stock_Partner__c from APTS_TriangleInvoiceOrders__c Where BatchId__c = :batchId order by OrderReference__c];
        // Map<String,List<APTS_TriangleInvoiceOrders__c>> ordIdWithLineItemsMap = new Map<String,List<APTS_TriangleInvoiceOrders__c>>();
        
        Set<String> badOrders = new Set<String>();
        Set<String> badOrderRefSet = new Set<String>();
        Set<String> badCarts  = new Set<String>();
        List<Id> orderIDsToSubmit = new List<Id>();
        
        // Retrieve all order names for all order ids in batchRecords, add to batchRecords. is x.HasError, put in 'Order Failed' message
        // set of all order ids related to this batch
        set<string> orderIds = new set<string>();
        Map<string, string> orderRefIdMap = new Map<string, string>();
        Map<string, string> orderIdNameMap = new Map<string, string>();

        for(APTS_TriangleInvoiceOrders__c x : batchRecords){
            system.debug('x.HasError__c::ErrorMessage__c '+ x.HasError__c + ':::' + x.ErrorMessage__c);
            if(x.Order__c != null){
                orderIds.add(x.Order__c);
                orderRefIdMap.put(x.OrderReference__c,x.Order__c);                
            }       
            if(x.HasError__c){
                badOrderRefSet.add(x.OrderReference__c);              
            }               
        }  
  

        List<Apttus_Config2__Order__c> orderList = [Select Name, Id, Apttus_Config2__Status__c, APTS_Status__c, APTS_Order_Sub_Type__c, Apttus_Config2__PreviousVersion__c,
                    Apttus_Config2__SoldToAccountId__c, Apttus_Config2__SoldToAccountId__r.SAP_Customer_Id__c,
                    Apttus_Config2__SoldToAccountId__r.RecordType.Name, Apttus_Config2__SoldToAccountId__r.Parent_Change_Indicator__c,
                    Apttus_Config2__SoldToAccountId__r.Parent_Valid_From__c, Apttus_Config2__SoldToAccountId__r.Parent_Valid_To__c From Apttus_Config2__Order__c WHERE Id IN :orderIds];
        List<Apttus_Config2__Order__c> orderListToSubmit = new List<Apttus_Config2__Order__c>();     //V100++<<>>  
        for(Apttus_Config2__Order__c order : orderList){
            orderIdNameMap.put(order.Id, order.Name);
            if(order.APTS_Order_Sub_Type__c != APTS_OrderConstants.UNPLANNED_RETURN) //V100++ <<>>
            {
               orderIDsToSubmit.add(order.Id); 
               orderListToSubmit.add(order);
            }
        }
  
        //APTS_OrderUtils.startOrderLineItemTrigger();   
        //APTS_OrderUtils.startOrderTrigger(); 

        if(!orderIds.isEmpty())
        {
               
              APTS_CustomLogging.createErrorLog('OM_TRIO_DEBUG', 'Apex', batchId + 'BeforeOrderSubmission', 'APTS_TriangularInvoiceFinalizeBatch', null, 'OM', false, false, null, false);

              APTS_SubmitTriangularOrderQueueable sTIQ = new APTS_SubmitTriangularOrderQueueable(orderListToSubmit); //V100++<<>>
              System.enqueueJob(sTIQ);
              APTS_CustomLogging.createErrorLog('OM_TRIO_DEBUG', 'Apex', batchId + 'AfterOrderSubmission' + String.valueOf(orderIds) , 'APTS_TriangularInvoiceFinalizeBatch', null, 'OM', false, false, null, false);

        }
        for(APTS_TriangleInvoiceOrders__c a : batchRecords){
            if(badOrderRefSet.contains(a.OrderReference__c)){
                a.Order_Name__c = 'Order Failed';
                if(a.Order__c != null && a.Order__c != ''){
                badOrders.add(a.Order__c);
                }
                if(a.Cart_Id__c != null && a.Cart_Id__c != ''){
                badCarts.add(a.Cart_Id__c);
                }
            }
            if(!badOrderRefSet.contains(a.OrderReference__c)){
                a.Order_Name__c = orderIdNameMap.get(orderRefIdMap.get(a.OrderReference__c));
            }
        }

        update batchRecords;

        // Delete Order and Cart IDs which were generated but are invalid
        APTS_TriangularInvoiceBatchHandler.DeleteBadOrdersAndCarts(badOrders,badCarts);
        sendTo.add(UserInfo.getUserEmail());
        System.debug('Email address: ' + UserInfo.getuserEmail());
        APTS_CustomLogging.createErrorLog('OM_TRIO_DEBUG', 'Apex', 'BeforeSendEmail' + String.valueOf(sendTo), 'APTS_TriangularInvoiceFinalizeBatch', null, 'OM', false, false, null, false);
        APTS_TriangularInvoiceBatchHandler.sendOrderConfirmationMail(sendTo, badOrderRefSet, batchRecords);
        APTS_CustomLogging.createErrorLog('OM_TRIO_DEBUG', 'Apex', batchId + 'AfterSendEmail' + String.valueOf(sendTo), 'APTS_TriangularInvoiceFinalizeBatch', null, 'OM', false, false, null, false);

        

        //APTS_OrderUtils.startOrderLineItemTrigger();   
        //APTS_OrderUtils.startOrderTrigger(); 
    }
    catch (Exception e) {APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', null, 'OM', false, true, null, true);}  
}
    global static string removeNull(String value){
    value = value != null ? value : '';
    return value;
  }
}