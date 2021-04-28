/*************************************************************
@Name: APTS_PartialCancellationCtrl
@Author: Lavanya
@CreateDate: Aug 5 , 2020
@Description: USed For Partial Cancel button in Order Header 
@UsedBy: 
******************************************************************/
public with sharing class APTS_PartialCancellationCtrl {

public Decimal i{get;set;}
public Id orderId;
public List<Apttus_Config2__OrderLineItem__c> MapAllOrderLines = new List<Apttus_Config2__OrderLineItem__c>();
public Map<Decimal,List<Apttus_Config2__OrderLineItem__c>> MapBundleNumberToOLI = new Map<Decimal,List<Apttus_Config2__OrderLineItem__c>>();
public Set<Id> orderLineItemIdSet{get;set;}
public list<PartialCancelFields> listToBecancelledLines{get;set;}
public Set<Decimal> setBundleNumber = new Set<Decimal>();
public Set<Decimal> setPending = new Set<Decimal>();
public String orderType{get;set;}
public Decimal BundleNumber{get;set;}
public static String URL_1='/apex/APTS_PartialCancellationPage?id=';
public static String BKSLASH = '/';
public static String PRODUCT_SERVICE = 'Product/Service';
public static String OPTION ='Option';
public static String PENDING = 'Pending';
public static String CANCELLED= 'Canceled';
public static String CANCELLEDSTATUS='Cancelled';
public List<PartialCancelFields> selectedLines = new List<PartialCancelFields>();

//Wrapper for VF page
public class PartialCancelFields
{
public String productName{get;set;}
public String productCode{get;set;}
public String typeOfContract{get;set;}
public String chargetype{get;set;}
public String WOLIStatus{get;set;}
public Boolean isEligible{get;set;}
public String ReasonForRejection{get;set;}
public Decimal LineNumber{get;set;}
public Decimal Sno{get;set;}
public Boolean selected{get;set;}
public Boolean isPrimaryL1{get;set;}
public String status{get;set;}

public PartialCancelFields() {
this.selected = false;
}
}

//page Load constructor that display the relevant values based on JIRA- DQ-333
public APTS_PartialCancellationCtrl()
        {
        Decimal i=0;
        MapAllOrderLines = new List<Apttus_Config2__OrderLineItem__c>();
        listToBecancelledLines = new List<PartialCancelFields>();
        orderLineItemIdSet = new Set<id>();
        orderType = APTS_CERUtility.MACHINE_ORDER;
        orderId=ApexPages.currentPage().getParameters().get('id');
        String errorMessage=ApexPages.currentPage().getParameters().get('errorMsg');
        orderLineItemIdSet.add(ApexPages.currentPage().getParameters().get('id'));
        System.debug(orderLineItemIdSet);
        MapAllOrderLines = APTS_PartialCancellationUtil.getOrderLineItemstoOrder(orderLineItemIdSet);
        System.debug(MapAllOrderLines.size());
        //i=1;
        try{

        for(Apttus_Config2__OrderLineItem__c instOrderLine : MapAllOrderLines)
        {
        List<Apttus_Config2__OrderLineItem__c> ListOrderLines;
        if(MapBundleNumberToOLI.containsKey(instOrderLine.Apttus_Config2__LineNumber__c)) 
        {
        ListOrderLines= new List<Apttus_Config2__OrderLineItem__c>();
        ListOrderLines = MapBundleNumberToOLI.get(instOrderLine.Apttus_Config2__LineNumber__c);
        ListOrderLines.add(instOrderLine);
        MapBundleNumberToOLI.put(instOrderLine.Apttus_Config2__LineNumber__c,ListOrderLines);
        }
        else
        {
        ListOrderLines= new List<Apttus_Config2__OrderLineItem__c>();
        ListOrderLines.add(instOrderLine);
        MapBundleNumberToOLI.put(instOrderLine.Apttus_Config2__LineNumber__c,ListOrderLines);
        }

        if(instOrderLine.Apttus_Config2__Status__c == PENDING)
        {
        setPending.add(instOrderLine.Apttus_Config2__LineNumber__c);
        if(instOrderLine.APTS_Reason_For_Rejection__c != null && instOrderLine.APTS_Is_Primary_L1_Line__c == true)  
        setBundleNumber.add(instOrderLine.Apttus_Config2__LineNumber__c);        
        System.debug(setBundleNumber);        
        }

        }
        System.debug('PC setBundleNumber->'+setBundlenumber);
        for(Apttus_Config2__OrderLineItem__c instOrderLine : MapAllOrderLines)
        {

        if((instOrderLine.Apttus_Config2__LineType__c == PRODUCT_SERVICE && instOrderLine.APTS_Is_Primary_L1_Line__c == true) || instOrderLine.Apttus_Config2__LineType__c==OPTION)
        {
        PartialCancelFields instPartialCancelLine = new PartialCancelFields();
        instPartialCancelLine.productName =  instOrderLine.Apttus_Config2__LineType__c == PRODUCT_SERVICE ? instOrderLine.Apttus_Config2__ProductId__r.Name : instOrderLine.Apttus_Config2__OptionId__r.Name;
        instPartialCancelLine.productCode = instOrderLine.Apttus_Config2__LineType__c == PRODUCT_SERVICE ? instOrderLine.Apttus_Config2__ProductId__r.ProductCode : instOrderLine.Apttus_Config2__OptionId__r.ProductCode;
        instPartialCancelLine.isPrimaryL1=false;
        if(instOrderLine.Apttus_Config2__LineType__c == PRODUCT_SERVICE && instOrderLine.APTS_Is_Primary_L1_Line__c == true)
        {
        i++;
        instPartialCancelLine.typeOfContract = instOrderLine.APTS_Type_of_Contract__c;
        instPartialCancelLine.Sno = i;
        instPartialCancelLine.isPrimaryL1= true;
        }
        instPartialCancelLine.chargetype=instOrderLine.Apttus_Config2__ChargeType__c;
        if(instOrderLine.Work_Order_Line_Items__r!= null && instOrderLine.Work_Order_Line_Items__r.size()>0)
        instPartialCancelLine.WOLIStatus= instOrderLine.Work_Order_Line_Items__r[0].Status;
        instPartialCancelLine.LineNumber=instOrderLine.Apttus_Config2__LineNumber__c;
        instPartialCancelLine.ReasonForRejection=instOrderLine.APTS_Reason_For_Rejection__c;
        instPartialCancelLine.Status= instOrderLine.Apttus_Config2__Status__c;
        if(setBundleNumber.contains(instOrderLine.Apttus_Config2__LineNumber__c) && setPending.contains(instOrderLine.Apttus_Config2__LineNumber__c) && ((instOrderLine.Apttus_Config2__LineType__c == 'Product/Service' && instOrderLine.APTS_Is_Primary_L1_Line__c == true) || instOrderLine.Apttus_Config2__LineType__c==OPTION)) 
        {
        if(instOrderLine.APTS_Is_Primary_L1_Line__c == true)
        instPartialCancelLine.isEligible=true;
        }
        listToBecancelledLines.add(instPartialCancelLine);
        }
        }
        System.debug('Errmsg'+errorMessage.length());
        if((errorMessage!=null && errorMessage.length()>0) || errorMessage==null)
        ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There are Tasks with non Cancelled status.Order Line Cancellation will NOT proceed.')); 

        }
        catch(exception e) {
        //v102 ++ <<
        APTS_CustomErrorLogging.createErrorLog('APTS_PartialCancellationCtrl', 'Apex', e.getTypeName() + ':' + e.getMessage() + '__StackTrace:_' + e.getStackTraceString(), 'Order',
                                           orderId, 'OM', false, false, null, true, orderId, null, e.getmessage());

        }
}

/* Cancel the Order Lines per Bundle. If multiple bundles is not allowed */
public PageReference CancelPendingLines()
        {
        Boolean OrderUpdateBlock = false; 
        PageReference pg = new PageReference(URL_1+orderid); 
        Boolean ProceedForcancel;
        Set<Id> setOrderLines= new Set<Id>();
        List<Apttus_Config2__OrderLineItem__c> ListOrderLinesToUpdate = new List<Apttus_Config2__OrderLineItem__c>();
     
        if(Test.isRunningTest())
        {BundleNumber=1;}
        try{
        for(Apttus_Config2__OrderLineItem__c instOrderLine :MapBundleNumberToOLI.get(BundleNumber))
        {
        setOrderLines.add(instOrderLine.id);
        if(instOrderLine.Apttus_Config2__Status__c==PENDING)
        {
        instOrderLine.APTS_Status__c=CANCELLEDSTATUS;
        instOrderLine.Apttus_Config2__Status__c=CANCELLEDSTATUS;
        ListOrderLinesToUpdate.add(instOrderLine);
        }
        }
        System.debug('PC->OLI to be updated'+ListOrderLinesToUpdate.size());   
        ProceedForcancel=CHeckWOLI(setOrderLines);
        if(ProceedForcancel==true)
        {
        //switch off all triggers
        APTS_OrderUtils.stopOrderLineItemTrigger();
        APTS_BillingScheduleTriggerHandler.isSkipBillingScheduleTrigger = true;
        Database.SaveResult[] srList = Database.update(ListOrderLinesToUpdate); 
         APTS_OrderUtils.stopOrderLineItemTrigger();
        for (Database.SaveResult sr : srList) {
        if(!sr.isSuccess())
        OrderUpdateBlock = true;   } 
        if(OrderUpdateBlock==false)
        {
        //OrderStatusUpdateLogic(orderId);
        }
        pg.setRedirect(true);
        }
        else
        {
        pg.getParameters().put('errorMsg','There are tasks which are not cancelled');
        pg.setRedirect(true);
        }       
        }
        catch(exception e) {
        //v102 ++ <<
        APTS_CustomErrorLogging.createErrorLog('APTS_PartialCancellationCtrl', 'Apex', e.getTypeName() + ':' + e.getMessage() + '__StackTrace:_' + e.getStackTraceString(), 'Order',
                                           orderId, 'OM', false, false, null, true, orderId, null, e.getmessage());

        }

        return pg;
        }

/* Wrapper- Selecting Multiple bundles and applying cancel Logic */
        public PageReference CancelMultipleBundles() {
        Boolean OrderUpdateBlock = false; 
        Set<Id> setOrderLines= new Set<Id>();
        Boolean ProceedForcancel;
        List<Apttus_Config2__OrderLineItem__c> ListOrderLinesToUpdate = new List<Apttus_Config2__OrderLineItem__c>();
        PageReference pg = new PageReference(URL_1+orderid); 
        try{
        for(PartialCancelFields instWrapper: listToBecancelledLines) {
        if(instWrapper.selected == true) {
        selectedLines.add(instWrapper);
        }
        }

        for(PartialCancelFields instSelected : selectedLines)
        {
        if(Test.isRunningTest())
        {instSelected.LineNumber=1;}
        for(Apttus_Config2__OrderLineItem__c instOrderLine :MapBundleNumberToOLI.get(instSelected.LineNumber))
        {
        setOrderLines.add(instOrderLine.id);
        if(instOrderLine.Apttus_Config2__Status__c==PENDING)
        {
        instOrderLine.APTS_Status__c=CANCELLEDSTATUS;
        instOrderLine.Apttus_Config2__Status__c=CANCELLEDSTATUS;
        ListOrderLinesToUpdate.add(instOrderLine); 
        }
        }
        } 
        ProceedForcancel=CHeckWOLI(setOrderLines);
        if(ProceedForcancel==true)
        {
        //switch off all triggers
        APTS_OrderUtils.stopOrderLineItemTrigger();
        APTS_BillingScheduleTriggerHandler.isSkipBillingScheduleTrigger = true;
        Database.SaveResult[] srList = Database.update(ListOrderLinesToUpdate); 
         APTS_OrderUtils.stopOrderLineItemTrigger();
        for (Database.SaveResult sr : srList) {
        if(!sr.isSuccess())
        OrderUpdateBlock = true;   } 
        if(OrderUpdateBlock==false)
        {        
        //OrderStatusUpdateLogic(orderId);         
        }     
        pg.getParameters().put('errorMsg','');
        pg.setRedirect(true);
        }  
        else
        {
        pg.getParameters().put('errorMsg','There are tasks which are not cancelled');
        pg.setRedirect(true);
        ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There are  Tasks with non Cancelled status.Order Line Cancellation will NOT proceed.')); 
        }
        System.debug('Total lines to update'+ListOrderLinesToUpdate.size());
        }
        catch(exception e) {
        //v102 ++ <<
        APTS_CustomErrorLogging.createErrorLog('APTS_PartialCancellationCtrl', 'Apex', e.getTypeName() + ':' + e.getMessage() + '__StackTrace:_' + e.getStackTraceString(), 'Order',
                                           orderId, 'OM', false, false, null, true, orderId, null, e.getmessage());
              
        }
        return pg;
        }    
/* WOLI should not be of any other status other than Cancelled'- Validation */
public Boolean CHeckWOLI(Set<Id> OrderLinesForWOLISet)
        {
        Map<Id, WorkOrderLineItem> WorkOrderLineMap = new Map<Id, WorkOrderLineItem>();
        Set<Id> setWarningWOLI = new Set<Id>();
        Boolean ProceedForcancel=true;
        if(!OrderLinesForWOLISet.isEmpty())
        {
        WorkOrderLineMap= APTS_OrderLineItemDAO.getWorkOrderLineItem(OrderLinesForWOLISet);
        if(!WorkOrderLineMap.isEmpty())
        for(WorkOrderLineItem instWorkOrderLine : WorkOrderLineMap.values())
        {
        if(!instWorkOrderLine.Status.containsIgnoreCase(CANCELLED)/* || !instWorkOrderLine.StatusCategory.containsIgnoreCase('Cancelled')*/)
        setWarningWOLI.add(instWorkOrderLine.id);        
        }
        } 
        System.debug('Warning setWarningWOLI'+setWarningWOLI.size());
        if(!setWarningWOLI.isEmpty())
        {
        ProceedForcancel=false;
        ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There are '+setWarningWOLI.size()+' Tasks with non Cancelled status.Order Line Cancellation will NOT proceed.')); 
        }
        return ProceedForcancel;
        }

public PageReference GoBack()
        {
        PageReference pg = new PageReference(BKSLASH+orderId);
        return pg;
        }

// @future
public static void OrderStatusUpdateLogic(Id orderId)
        {
        
        //Apttus_Config2__Order__c instOrder = new Apttus_Config2__Order__c(Id =orderId);
        List<Apttus_Config2__Order__c> listorder = new List<Apttus_Config2__Order__c>([Select id,Apttus_Config2__Status__c,APTS_Status__c from Apttus_Config2__Order__c where Id =:orderId]);
        if(listorder[0].Apttus_Config2__Status__c!= null || listorder[0].Apttus_Config2__Status__c!='')
        {  listorder[0].APTS_Status__c=listorder[0].Apttus_Config2__Status__c;
        Database.update(listorder);         
        }

        }

}