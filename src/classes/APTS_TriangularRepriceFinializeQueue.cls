//V100 Aarthi 30-Apr-2020 Unplanned return - prevent Order submission without approval
public class APTS_TriangularRepriceFinializeQueue implements Queueable {
    @testVisible

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


    private Id cartId;
    private Id orderId;
    private Boolean isOrderNeedAccept;
    private String sOrderType;
    private String sCartAction;

    private APTS_TriangleInvoiceOrders__c currentOrder;
    @testVisible private static Boolean doChainJob = true;


    //v101 start
    //constructor created for Batch Job SOQL issue
    public APTS_TriangularRepriceFinializeQueue(Id cartId, String sOrderType, String sCartAction, APTS_TriangleInvoiceOrders__c currentOrder) {
        this.cartId = cartId;
        this.sOrderType = sOrderType;
        this.sCartAction = sCartAction;
        this.currentOrder = currentOrder;
    }

    //v101 end
    public void execute(QueueableContext context) {
        if (doChainJob) {
            try {
                if (String.isNotBlank(cartId)) {

                    //v101 start

                    if (FINALIZE.equalsIgnoreCase(sCartAction)) {
                        //if price is complete than finalize cart
                        APTS_TriangularInvoiceBatchHandler.updatePricing(cartId, currentOrder,true);

                        //invoke submit order in seperate queue to avoid SOQL
                        if (!Test.isRunningTest()) {
                            System.enqueueJob(new APTS_TriangularRepriceFinializeQueue(cartId, sOrderType, SUBMIT, currentOrder));
                        }
                    }

                    else if (SUBMIT.equalsIgnoreCase(sCartAction)) { submitTriangularOrders(cartId);}
                    //catch (Exception e) {APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', null, 'OM', false, true, null, true);}



                    else {
                        //else reprice until all line items are priced
                        Boolean isPricePending = APTS_TriangularInvoiceBatchHandler.repriceCart(cartId);

                        // if price is complete invoke same queue to finalize cart
                        //else invoke same queue to reprice until all line items are priced
                        sCartAction = isPricePending ? sCartAction : FINALIZE;
                        if (!Test.isRunningTest()) { System.enqueueJob(new APTS_TriangularRepriceFinializeQueue(cartId, sOrderType, sCartAction, currentOrder));}
                    }

                    //update setTriangleOrders;
                    //update TriangleOrderList;
                    //v101 end

                }
            } catch (Exception e) {APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString(), 'Order', '', 'OM', false, false, null, true);}
        }




    }

    public void submitTriangularOrders(Id cartId) {
        String sourceOrderNum, orderJSON = '';
        Set<Id> setOrderId = new Set<Id> ();
        Set<Id> setTriangleOrders = new Set<Id> ();
          List<APTS_TriangleInvoiceOrders__c> triangleOrderList = new List<APTS_TriangleInvoiceOrders__c>();


        //fetch the Triangular Invoice Order
        for (APTS_TriangleInvoiceOrders__c oLogObj : [SELECT id, Cart_Id__c, ErrorMessage__c, SAP_OrderType__c, Requested_Delivery_Date__c, HasError__c, OrderReference__c, SAP_Customer_ID__c, Processing_Status__c,Order__c
                FROM APTS_TriangleInvoiceOrders__c WHERE Order__c <> null AND Cart_Id__c = : cartId LIMIT 1]) {
            
            oLogObj.Processing_Status__c  = 'Cart Pricing Completed Succesfully';
            setTriangleOrders.add(oLogObj.Id);
            triangleOrderList.add(oLogObj);
        }
        
        try {
        
        // QUERY REF Using BATCH ID and SEND Email
        //APTS_OrderUtils.stopOrderLineItemTrigger();
        //APTS_OrderUtils.stopOrderTrigger();

        List<String> sendTo = new List<String>();

        // List<APTS_TriangleInvoiceOrders__c> batchRecords = [select BillTo__c,Name,Id,SAP_Customer_ID__c,OrderReference__c,Payer__c,AccountLocationSapId__c,ProductId__c,Quantity__c,Requested_Delivery_Date__c,SAP_OrderType__c,Order_Sub_Type__c,SellingUom__c,SoldTo__c,HasError__c,ErrorMessage__c, Order__c,Cart_Id__c, Order_Name__c,Pricing_Date__c, Invoice_Remarks__c, PO__c,APTS_Stock_Partner__c from APTS_TriangleInvoiceOrders__c Where BatchId__c = :batchId order by OrderReference__c];
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
        system.debug('------------triangleOrderList------'+triangleOrderList);
        for (APTS_TriangleInvoiceOrders__c x : triangleOrderList) {
            if (x.Order__c != null) {
                orderIds.add(x.Order__c);
                orderRefIdMap.put(x.OrderReference__c, x.Order__c);
            }
            if (x.HasError__c) { badOrderRefSet.add(x.OrderReference__c);}
        }
        List<Apttus_Config2__Order__c> orderListToSubmit = new List<Apttus_Config2__Order__c>();     //V100++ << >> 
        List<Apttus_Config2__Order__c> orderList = [Select Name, Id, Apttus_Config2__Status__c, APTS_Status__c, APTS_Order_Sub_Type__c, Apttus_Config2__PreviousVersion__c,
                                       Apttus_Config2__SoldToAccountId__c, Apttus_Config2__SoldToAccountId__r.SAP_Customer_Id__c,
                                       Apttus_Config2__SoldToAccountId__r.RecordType.Name, Apttus_Config2__SoldToAccountId__r.Parent_Change_Indicator__c,
                                       Apttus_Config2__SoldToAccountId__r.Parent_Valid_From__c, Apttus_Config2__SoldToAccountId__r.Parent_Valid_To__c From Apttus_Config2__Order__c WHERE Id IN :orderIds];
        for (Apttus_Config2__Order__c order : orderList) {
            orderIdNameMap.put(order.Id, order.Name);
            if(order.APTS_Order_Sub_Type__c != APTS_OrderConstants.UNPLANNED_RETURN) //V100 ++<< >>
            {
                orderIDsToSubmit.add(order.Id);
                orderListToSubmit.add(order);
            }
        }

        //APTS_OrderUtils.startOrderLineItemTrigger();
        //APTS_OrderUtils.startOrderTrigger();

        if (!orderIds.isEmpty()) {
            
            APTS_CustomLogging.createErrorLog('OM_TRIO_DEBUG', 'Apex', cartId + 'BeforeOrderSubmission_CARTID', 'APTS_TriangularRepriceFinializeQueue', null, 'OM', false, false, null, false);
            APTS_SubmitTriangularOrderQueueable sTIQ = new APTS_SubmitTriangularOrderQueueable(orderListToSubmit);
            System.enqueueJob(sTIQ);
            APTS_CustomLogging.createErrorLog('OM_TRIO_DEBUG', 'Apex', cartId + 'AfterOrderSubmission_CARTID' + String.valueOf(orderIds) , 'APTS_TriangularRepriceFinializeQueue', null, 'OM', false, false, null, false);
        }
        for (APTS_TriangleInvoiceOrders__c a : triangleOrderList) {
            if (badOrderRefSet.contains(a.OrderReference__c)) {
                a.Order_Name__c = 'Order Failed';
                if (a.Order__c != null && a.Order__c != '') { badOrders.add(a.Order__c); }
                if (a.Cart_Id__c != null && a.Cart_Id__c != '') { badCarts.add(a.Cart_Id__c);} }
            if (!badOrderRefSet.contains(a.OrderReference__c)) { a.Order_Name__c = orderIdNameMap.get(orderRefIdMap.get(a.OrderReference__c));}
        }

        update triangleOrderList;

        // Delete Order and Cart IDs which were generated but are invalid
        APTS_TriangularInvoiceBatchHandler.DeleteBadOrdersAndCarts(badOrders, badCarts);
        sendTo.add(UserInfo.getUserEmail());
        APTS_CustomLogging.createErrorLog('OM_TRIO_DEBUG', 'Apex', 'BeforeSendEmail' + String.valueOf(sendTo), 'APTS_TriangularRepriceFinializeQueue', null, 'OM', false, false, null, false);

        APTS_TriangularInvoiceBatchHandler.sendOrderConfirmationMail(sendTo, badOrderRefSet, triangleOrderList);

         } catch (Exception e) {APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'Order', null, 'OM', false, false, null, true);}
    }
}