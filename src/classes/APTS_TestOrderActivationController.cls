public with sharing class APTS_TestOrderActivationController {

    private Id orderId;
    private Id billingPreferenceID;
    private List<Apttus_Config2__Order__c> olist = new List<Apttus_Config2__Order__c>();
    private List<Apttus_Config2__OrderLineItem__c> oli = new List<Apttus_Config2__OrderLineItem__c>();
    private Set<Id> oliIdSet = new Set<Id>();
    private Apttus_Config2__OrderFulfillment__c oFLI;

    public Date installDate {get; set;}
    public Decimal fulfilledQty {get; set;}
    public List<Apttus_Config2__OrderFulfillmentLineItem__c> partialFLI {get; set;}
    public List<orderLineItemWrapper> listoliWrap {get; set;}

    public class orderLineItemWrapper {
        public Apttus_Config2__OrderLineItem__c oli {get; set;}
        public Double fulfilledQty {get; set;}
        public String reasonforRejection {get; set;}
    }

    public APTS_TestOrderActivationController() {

        orderId = ApexPages.currentPage().getParameters().get('Id');
        Apttus_Config2__BillingPreference__c  oBP =  [select id from Apttus_Config2__BillingPreference__c  LIMIT 1];
      if(oBP != null)
           billingPreferenceID = oBP.id;

        olist = [select id, APTS_Order_Header_SAP_ID__c, Apttus_Config2__SoldToAccountId__c, APTS_Requested_Delivery_Date__c from Apttus_Config2__Order__c where id = :orderid];

        oli = [select id, name, Apttus_Config2__ProductId__r.name, APTS_Reason_For_Rejection__c, Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c, APTS_SAP_Order_Line_Item_Number__c, APTS_Installation_Date_Authorized__c,
               APTS_De_installation_Date_Authorized__c,
               APTS_Expected_Delivery_Quantity__c, Apttus_Config2__Quantity__c,
               APTS_Expected_Delivery_Date__c, APTS_Requested_Delivery_Date__c, Apttus_Config2__HasOptions__c,
               APTS_ATP_Cleared__c, APTS_Item_Relevant_for_SAP__c,  Apttus_Config2__OptionId__r.Apttus_Config2__HasDefaults__c,
               APTS_Is_Primary_L1_Line__c,
               Apttus_Config2__BillingPreferenceId__c, Apttus_Config2__BillingFrequency__c, Apttus_Config2__BillingRule__c,
               Apttus_Config2__StartDate__c, Apttus_Config2__EndDate__c, APTS_Replaced_Product_Code__c,// Apttus_Config2__Status__c, APTS_Status__c,
                Apttus_Config2__OptionId__c, Apttus_Config2__OptionId__r.ProductCode, Apttus_Config2__ProductId__r.ProductCode, Apttus_Config2__LineNumber__c
               from Apttus_Config2__OrderLineItem__c where Apttus_Config2__OrderId__c = :orderid];

        listoliWrap = new List<orderLineItemWrapper>();

        for (Apttus_Config2__OrderLineItem__c o : oli) {
            oliIdSet.add(o.Id);

            orderLineItemWrapper oWrap = new orderLineItemWrapper();
            oWrap.oli = o;
            listoliWrap.add(oWrap);
        }

        oFLI = [select id from Apttus_Config2__OrderFulfillment__c limit 1];

        partialFLI = [select id, Apttus_Config2__OrderLineItemId__c, APTS_Fulfilled_Quantity__c from Apttus_Config2__OrderFulfillmentLineItem__c where Apttus_Config2__OrderId__c = : orderId];
    }

    public PageReference stopOrder() {

        APTS_OrderUtils.stopOrderTrigger();

        return null;
    }

    public PageReference submitOrder() {

        APTS_OrderUtils.submitOrder(orderid);

        return null;
    }

    public PageReference firstSAP() {

        olist[0].APTS_Order_Header_SAP_ID__c = '123';
        update olist;

        for (Apttus_Config2__OrderLineItem__c o : oli) {

            //o.Apttus_Config2__BillingFrequency__c = 'Monthly';
            //o.Apttus_Config2__BillingRule__c = 'Bill In Advance';
            o.Apttus_Config2__BillingPreferenceId__c = billingPreferenceID;
            //o.Apttus_Config2__StartDate__c =  Date.today();
            //o.Apttus_Config2__EndDate__c = Date.today().addYears(4);

            if (o.APTS_Item_Relevant_for_SAP__c) {
                //o.APTS_ATP_Cleared__c = true;
                o.APTS_SAP_Order_Line_Item_Number__c = '123';
                o.APTS_Expected_Delivery_Quantity__c = o.Apttus_Config2__Quantity__c;
                o.APTS_Expected_Delivery_Date__c = Date.today();
                o.APTS_Material_Availability_Date__c = Date.today();
                o.APTS_Requested_Delivery_Date__c = Date.today();
                o.APTS_Requested_Installation_Date__c = Date.today() + 10;
            }
        }
        update oli;

        return null;
    }

    public PageReference firstSAPNoMA() {

        olist[0].APTS_Order_Header_SAP_ID__c = '123';
        update olist;

        for (Apttus_Config2__OrderLineItem__c o : oli) {
            if (o.APTS_Item_Relevant_for_SAP__c) {
                o.APTS_ATP_Cleared__c = true;
                o.APTS_SAP_Order_Line_Item_Number__c = '123';
                o.APTS_Expected_Delivery_Quantity__c = o.Apttus_Config2__Quantity__c;
                o.APTS_Expected_Delivery_Date__c = Date.today();
                //o.APTS_Material_Availability_Date__c = Date.today();
            }
        }
        update oli;

        return null;
    }

    public PageReference movementFirstSAP() {

        olist[0].APTS_Order_Header_SAP_ID__c = '123';
        update olist;

        for (Apttus_Config2__OrderLineItem__c o : oli) {
            if (o.APTS_Item_Relevant_for_SAP__c) {
                o.APTS_ATP_Cleared__c = true;
                o.APTS_SAP_Order_Line_Item_Number__c = '123';
            }
        }
        update oli;

        return null;
    }

    public PageReference setMA() {

        olist[0].APTS_Order_Header_SAP_ID__c = '123';
        update olist;

        for (Apttus_Config2__OrderLineItem__c o : oli) {
            if (o.APTS_Item_Relevant_for_SAP__c) {
                o.APTS_Material_Availability_Date__c = Date.today();
            }
        }
        update oli;

        return null;
    }

    public PageReference partialFirstSAP() {

        olist[0].APTS_Order_Header_SAP_ID__c = '123';
        Date rdd = olist[0].APTS_Requested_Delivery_Date__c;
        update olist;

        Integer size = oli.size();
        Integer i = 0;
        for (Apttus_Config2__OrderLineItem__c o : oli) {
            if (o.APTS_Item_Relevant_for_SAP__c) {
                o.APTS_ATP_Cleared__c = true;
                o.APTS_SAP_Order_Line_Item_Number__c = '123';
                o.APTS_Expected_Delivery_Quantity__c = o.Apttus_Config2__Quantity__c;
                o.APTS_Expected_Delivery_Date__c = rdd + 7 + i;
                o.APTS_Material_Availability_Date__c = Date.today();
                i++;
            }
        }
        update oli;

        return null;
    }

    public PageReference revertFirstSAP() {

        olist[0].APTS_Order_Header_SAP_ID__c = null;
        olist[0].APTS_ATP_Check_Status__c = null;
        olist[0].APTS_Work_Order_Created__c = false;
        update olist;

        for (Apttus_Config2__OrderLineItem__c o : oli) {
            o.APTS_SAP_Order_Line_Item_Number__c = null;
            o.APTS_Expected_Delivery_Quantity__c = null;
            o.APTS_Expected_Delivery_Date__c = null;
            o.APTS_ATP_Cleared__c = false;
        }
        update oli;

        List<WorkOrderTrigger__c> wol = [select id from WorkOrderTrigger__c where OrderLineItem__c in :oliIdSet];

        if (!wol.isEmpty()) delete wol;

        return null;
    }

    public PageReference firstTS() {
        /*
                olist[0].APTS_LSP_Delivery_Date__c = Date.today() + 7;
                olist[0].APTS_LSP_Pick_Up_Date__c = Date.today() + 8;
                olist[0].APTS_LSP_Movement_Date__c = Date.today() + 9;
        */
        olist[0].APTS_Delivery_Date_Authorized__c = Date.today() + 7;
        olist[0].APTS_Pick_Up_Date_Authorized__c = Date.today() + 8;
        olist[0].APTS_Movement_Date_Authorized__c = Date.today() + 9;

        update olist;

        return null;
    }

    public PageReference secondSAP() {

        List<Apttus_Config2__OrderFulfillmentLineItem__c> fliList = new List<Apttus_Config2__OrderFulfillmentLineItem__c>();

        for (Apttus_Config2__OrderLineItem__c o : oli) {
            if (o.APTS_Item_Relevant_for_SAP__c ) {
                Apttus_Config2__OrderFulfillmentLineItem__c fli = new Apttus_Config2__OrderFulfillmentLineItem__c();
                fli.Apttus_Config2__LineNumber__c = 1;
                fli.Apttus_Config2__OrderFulfillmentId__c = oFLI.Id;
                fli.APTS_GoodsIssue_Status__c = 'Not yet processed';
                fli.Apttus_Config2__OrderLineItemId__c = o.Id;
                fli.Apttus_Config2__OrderId__c = orderid;
                fli.APTS_POD_Status__c = 'Not Relevant';
                fli.APTS_Fulfilled_Quantity__c = o.Apttus_Config2__Quantity__c;
                fli.APTS_Material_Number_SAP__c = (o.Apttus_Config2__OptionId__c != null)? o.Apttus_Config2__OptionId__r.ProductCode : o.Apttus_Config2__ProductId__r.ProductCode;
                fliList.add(fli);
            }
        }

        insert fliList;

        return null;
    }

    public PageReference secondSAPReal() {

        if (fulfilledQty == 0 || fulfilledQty == null || fulfilledQty > 0) {
            partialFLI = new List<Apttus_Config2__OrderFulfillmentLineItem__c>();

            for (Apttus_Config2__OrderLineItem__c o : oli) {
                if (o.APTS_Item_Relevant_for_SAP__c) {
                if(fulfilledQty == 0 || fulfilledQty == null)
                {
                    if (o.Apttus_Config2__OptionId__r.Apttus_Config2__HasDefaults__c) {
                        Apttus_Config2__OrderFulfillmentLineItem__c fli = new Apttus_Config2__OrderFulfillmentLineItem__c();
                        fli.Apttus_Config2__LineNumber__c = 1;
                        fli.Apttus_Config2__OrderFulfillmentId__c = oFLI.Id;
                        fli.APTS_GoodsIssue_Status__c = 'Not Relevant';
                        fli.Apttus_Config2__OrderLineItemId__c = o.Id;
                        fli.Apttus_Config2__OrderId__c = orderid;
                        fli.APTS_POD_Status__c = 'Not Relevant';
                        fli.APTS_Fulfilled_Quantity__c = fulfilledQty > 0 ? fulfilledQty : o.Apttus_Config2__Quantity__c;
                        fli.APTS_Material_Number_SAP__c = (o.Apttus_Config2__OptionId__c != null)? o.Apttus_Config2__OptionId__r.ProductCode : o.Apttus_Config2__ProductId__r.ProductCode;
                        partialFLI.add(fli);
                        Apttus_Config2__OrderFulfillmentLineItem__c fli1 = new Apttus_Config2__OrderFulfillmentLineItem__c();
                        fli1.Apttus_Config2__LineNumber__c = 1;
                        fli1.Apttus_Config2__OrderFulfillmentId__c = oFLI.Id;
                        fli1.APTS_GoodsIssue_Status__c = 'Not yet processed';
                        fli1.Apttus_Config2__OrderLineItemId__c = o.Id;
                        fli1.Apttus_Config2__OrderId__c = orderid;
                        fli1.APTS_POD_Status__c = 'Not Relevant';
                        fli1.APTS_Fulfilled_Quantity__c = fulfilledQty > 0 ? fulfilledQty : o.Apttus_Config2__Quantity__c;
                        fli1.APTS_Material_Number_SAP__c = (o.Apttus_Config2__OptionId__c != null)? o.Apttus_Config2__OptionId__r.ProductCode : o.Apttus_Config2__ProductId__r.ProductCode;
                        partialFLI.add(fli1);
                    } else {
                        Apttus_Config2__OrderFulfillmentLineItem__c fli = new Apttus_Config2__OrderFulfillmentLineItem__c();
                        fli.Apttus_Config2__LineNumber__c = 1;
                        fli.Apttus_Config2__OrderFulfillmentId__c = oFLI.Id;
                        fli.APTS_GoodsIssue_Status__c = 'Not Relevant';//'Not yet processed';
                        fli.Apttus_Config2__OrderLineItemId__c = o.Id;
                        fli.Apttus_Config2__OrderId__c = orderid;
                        fli.APTS_POD_Status__c = 'Not Relevant';
                        fli.APTS_Fulfilled_Quantity__c = fulfilledQty > 0 ? fulfilledQty : o.Apttus_Config2__Quantity__c;
                        fli.APTS_Material_Number_SAP__c = (o.Apttus_Config2__OptionId__c != null)? o.Apttus_Config2__OptionId__r.ProductCode : o.Apttus_Config2__ProductId__r.ProductCode;
                        partialFLI.add(fli);
                    }
                    }
                    else
                    {
                    if(fulfilledQty == o.Apttus_Config2__LineNumber__c)
                    {
                         Apttus_Config2__OrderFulfillmentLineItem__c fli = new Apttus_Config2__OrderFulfillmentLineItem__c();
                        fli.Apttus_Config2__LineNumber__c = fulfilledQty;
                        fli.Apttus_Config2__OrderFulfillmentId__c = oFLI.Id;
                        fli.APTS_GoodsIssue_Status__c = 'Not Relevant';
                        fli.Apttus_Config2__OrderLineItemId__c = o.Id;
                        fli.Apttus_Config2__OrderId__c = orderid;
                        fli.APTS_POD_Status__c = 'Not Relevant';
                        fli.APTS_Fulfilled_Quantity__c = fulfilledQty > 0 ? fulfilledQty : o.Apttus_Config2__Quantity__c;
                        fli.APTS_Material_Number_SAP__c = (o.Apttus_Config2__OptionId__c != null)? o.Apttus_Config2__OptionId__r.ProductCode : o.Apttus_Config2__ProductId__r.ProductCode;
                        partialFLI.add(fli);
                    }
                    }
                }
            }

            if (!partialFLI.isEmpty()) {
                insert partialFLI;
            }
        } else {
            for (Apttus_Config2__OrderLineItem__c o : oli) {
                o.APTS_Reason_For_Rejection__c = '27';
            }

            update oli;

        }

        return null;
    }

    public PageReference PartialFLIUpdate() {

        List<Apttus_Config2__OrderFulfillmentLineItem__c> fliList = new List<Apttus_Config2__OrderFulfillmentLineItem__c>();
        List<Apttus_Config2__OrderLineItem__c> oLIToUpdateList = new List<Apttus_Config2__OrderLineItem__c>();

        if (listoliWrap != null && !listoliWrap.isEmpty()) {
            
            for (orderLineItemWrapper oWrap : listoliWrap) {
                Apttus_Config2__OrderLineItem__c o = oWrap.oli;
                fulfilledQty = oWrap.fulfilledQty;

                if (fulfilledQty != null  && o != null && o.APTS_Item_Relevant_for_SAP__c) {
                    if (o.Apttus_Config2__OptionId__r.Apttus_Config2__HasDefaults__c) {
                        Apttus_Config2__OrderFulfillmentLineItem__c fli = new Apttus_Config2__OrderFulfillmentLineItem__c();
                        fli.Apttus_Config2__LineNumber__c = 1;
                        fli.Apttus_Config2__OrderFulfillmentId__c = oFLI.Id;
                        fli.APTS_GoodsIssue_Status__c = 'Not Relevant';
                        fli.Apttus_Config2__OrderLineItemId__c = o.Id;
                        fli.Apttus_Config2__OrderId__c = orderid;
                        fli.APTS_POD_Status__c = 'Not Relevant';
                        fli.APTS_Fulfilled_Quantity__c = fulfilledQty > -1 ? fulfilledQty : o.Apttus_Config2__Quantity__c;
                        fli.APTS_Material_Number_SAP__c = (o.Apttus_Config2__OptionId__c != null)? o.Apttus_Config2__OptionId__r.ProductCode : o.Apttus_Config2__ProductId__r.ProductCode;
                        fliList.add(fli);
                        Apttus_Config2__OrderFulfillmentLineItem__c fli1 = new Apttus_Config2__OrderFulfillmentLineItem__c();
                        fli1.Apttus_Config2__LineNumber__c = 1;
                        fli1.Apttus_Config2__OrderFulfillmentId__c = oFLI.Id;
                        fli1.APTS_GoodsIssue_Status__c = 'Not yet processed';
                        fli1.Apttus_Config2__OrderLineItemId__c = o.Id;
                        fli1.Apttus_Config2__OrderId__c = orderid;
                        fli1.APTS_POD_Status__c = 'Not Relevant';
                        fli1.APTS_Fulfilled_Quantity__c = fulfilledQty > -1 ? fulfilledQty : o.Apttus_Config2__Quantity__c;
                        fli1.APTS_Material_Number_SAP__c = (o.Apttus_Config2__OptionId__c != null)? o.Apttus_Config2__OptionId__r.ProductCode : o.Apttus_Config2__ProductId__r.ProductCode;
                        fliList.add(fli1);
                        if(fli.APTS_Fulfilled_Quantity__c == 0)
                        {
                            o.APTS_Reason_For_Rejection__c = '27';
                            oLIToUpdateList.add(o);
                        }
                    } else {
                        Apttus_Config2__OrderFulfillmentLineItem__c fli = new Apttus_Config2__OrderFulfillmentLineItem__c();
                        fli.Apttus_Config2__LineNumber__c = 1;
                        fli.Apttus_Config2__OrderFulfillmentId__c = oFLI.Id;
                        fli.APTS_GoodsIssue_Status__c = 'Not Relevant';//'Not yet processed';
                        fli.Apttus_Config2__OrderLineItemId__c = o.Id;
                        fli.Apttus_Config2__OrderId__c = orderid;
                        fli.APTS_POD_Status__c = 'Not Relevant';
                        fli.APTS_Fulfilled_Quantity__c = fulfilledQty > -1 ? fulfilledQty : o.Apttus_Config2__Quantity__c;
                        fli.APTS_Material_Number_SAP__c = (o.Apttus_Config2__OptionId__c != null)? o.Apttus_Config2__OptionId__r.ProductCode : o.Apttus_Config2__ProductId__r.ProductCode;
                        fliList.add(fli);  
                        if(fli.APTS_Fulfilled_Quantity__c == 0)
                        {
                            o.APTS_Reason_For_Rejection__c = '27';
                            oLIToUpdateList.add(o);
                        }                      
                    }
                    
                }
                else {                   
                       
                        o.APTS_Reason_For_Rejection__c = '27';
                        oLIToUpdateList.add(o);
                    }                    

                }
                if(!oLIToUpdateList.isEmpty())
                {
                    Database.Update(oLIToUpdateList, false);
                }
            
        

        insert fliList;
        }
        return null;
    }

    public PageReference FinalPGI() {

        Apttus_Config2__Order__c o = new Apttus_Config2__Order__c(Id=orderId);
        o.APTS_IsPGICompleted__c = true;
        update o;

        Database.executeBatch(new APTS_AmendPartialOrderBatch(), 1);
        
        return null;
    }

    public PageReference secondSAPConversion() {

        List<Apttus_Config2__OrderFulfillmentLineItem__c> fliList = new List<Apttus_Config2__OrderFulfillmentLineItem__c>();

        for (Apttus_Config2__OrderLineItem__c o : oli) {
            if ( o.APTS_Item_Relevant_for_SAP__c) {
                Apttus_Config2__OrderFulfillmentLineItem__c fli = new Apttus_Config2__OrderFulfillmentLineItem__c();
                fli.Apttus_Config2__LineNumber__c = 1;
                fli.Apttus_Config2__OrderFulfillmentId__c = oFLI.Id;
                fli.APTS_GoodsIssue_Status__c = 'Not yet processed';
                fli.Apttus_Config2__OrderLineItemId__c = o.Id;
                fli.Apttus_Config2__OrderId__c = orderid;
                fli.APTS_POD_Status__c = 'Not Relevant';
                fli.APTS_Material_Number_SAP__c = (o.Apttus_Config2__OptionId__c != null)? o.Apttus_Config2__OptionId__r.ProductCode : o.Apttus_Config2__ProductId__r.ProductCode;
                fliList.add(fli);
            }
        }

        insert fliList;

        return null;
    }

    public PageReference thirdSAP() {

        List<Apttus_Config2__OrderFulfillmentLineItem__c> fliSList = [
                    select id, APTS_GoodsIssue_Status__c, APTS_Fulfilled_Quantity__c,
                    APTS_POD_Status__c, APTS_POD_Date__c, Apttus_Config2__OrderLineItemId__r.Apttus_Config2__Quantity__c,
                    Apttus_Config2__OrderLineItemId__r.Apttus_Config2__IsPrimaryLine__c,
                    Apttus_Config2__OrderLineItemId__r.Apttus_Config2__ProductId__r.ProductCode,
                     Apttus_Config2__OrderLineItemId__r.Apttus_Config2__OptionId__c,
                     Apttus_Config2__OrderLineItemId__r.Apttus_Config2__OptionId__r.ProductCode,
                    APTS_Material_Number_SAP__c
                    from Apttus_Config2__OrderFulfillmentLineItem__c where Apttus_Config2__OrderLineItemId__c in : oliIdSet];


        for (Apttus_Config2__OrderFulfillmentLineItem__c fli : fliSList) {
            fli.APTS_GoodsIssue_Status__c = 'Completely processed';
            fli.APTS_POD_Status__c = 'Completely processed';
            //fli.APTS_Fulfilled_Quantity__c  = 0;
            fli.APTS_GoodsIssue_Date__c = Date.today();
            fli.APTS_Material_Number_SAP__c =  (fli.Apttus_Config2__OrderLineItemId__r.Apttus_Config2__OptionId__c != null)? fli.Apttus_Config2__OrderLineItemId__r.Apttus_Config2__OptionId__r.ProductCode : fli.Apttus_Config2__OrderLineItemId__r.Apttus_Config2__ProductId__r.ProductCode;
        }

        update fliSList;

        for (Apttus_Config2__OrderLineItem__c o : oli) {
            if (o.APTS_Is_Primary_L1_Line__c) {
                o.APTS_Serial_Number__c = String.valueOf(Crypto.getRandomInteger());//'12345';
            }
        }
        update oli;

        return null;
    }

    public PageReference thirdSAPPartial() {

        List<Apttus_Config2__OrderFulfillmentLineItem__c> fliSList = [
                    select id, APTS_GoodsIssue_Status__c, APTS_Fulfilled_Quantity__c,
                    APTS_POD_Status__c, APTS_POD_Date__c, Apttus_Config2__OrderLineItemId__r.Apttus_Config2__Quantity__c,
                    Apttus_Config2__OrderLineItemId__r.Apttus_Config2__IsPrimaryLine__c,
                    Apttus_Config2__OrderLineItemId__r.Apttus_Config2__ProductId__r.ProductCode,
                     Apttus_Config2__OrderLineItemId__r.Apttus_Config2__OptionId__c,
                     Apttus_Config2__OrderLineItemId__r.Apttus_Config2__OptionId__r.ProductCode,
                    APTS_Material_Number_SAP__c
                    from Apttus_Config2__OrderFulfillmentLineItem__c where Apttus_Config2__OrderLineItemId__c in : oliIdSet ];


        for (Apttus_Config2__OrderFulfillmentLineItem__c fli : fliSList) {
            fli.APTS_GoodsIssue_Status__c = 'Completely processed';
            fli.APTS_POD_Status__c = 'Completely processed';
            fli.APTS_GoodsIssue_Date__c = Date.today();
            fli.APTS_Material_Number_SAP__c =   (fli.Apttus_Config2__OrderLineItemId__r.Apttus_Config2__OptionId__c != null)? fli.Apttus_Config2__OrderLineItemId__r.Apttus_Config2__OptionId__r.ProductCode : fli.Apttus_Config2__OrderLineItemId__r.Apttus_Config2__ProductId__r.ProductCode;
            break;
        }

        update fliSList;

        for (Apttus_Config2__OrderLineItem__c o : oli) {
            if (o.APTS_Is_Primary_L1_Line__c) {
                o.APTS_Serial_Number__c = String.valueOf(Crypto.getRandomInteger());//'12345';
            }
        }
        update oli;

        return null;
    }

    public PageReference thirdSAPConversion() {

        List<Apttus_Config2__OrderFulfillmentLineItem__c> fliSList = [
                    select id, APTS_GoodsIssue_Status__c, APTS_Fulfilled_Quantity__c,
                    APTS_POD_Status__c, APTS_POD_Date__c, Apttus_Config2__OrderLineItemId__r.Apttus_Config2__Quantity__c,
                    Apttus_Config2__OrderLineItemId__r.Apttus_Config2__IsPrimaryLine__c
                    from Apttus_Config2__OrderFulfillmentLineItem__c where Apttus_Config2__OrderLineItemId__c in : oliIdSet];

        for (Apttus_Config2__OrderFulfillmentLineItem__c fli : fliSList) {
            //if (fli.Apttus_Config2__OrderLineItemId__r.Apttus_Config2__IsPrimaryLine__c) {
            fli.APTS_GoodsIssue_Status__c = 'Completely processed';
            fli.APTS_POD_Status__c = 'Completely processed';
            fli.APTS_GoodsIssue_Date__c = Date.today();
            //}
        }

        update fliSList;

        return null;
    }

    public PageReference revertThirdSAP() {

        List<Apttus_Config2__OrderFulfillmentLineItem__c> fliSList = [
                    select id, APTS_GoodsIssue_Status__c, APTS_Fulfilled_Quantity__c,
                    APTS_POD_Status__c, APTS_POD_Date__c, Apttus_Config2__OrderLineItemId__r.Apttus_Config2__Quantity__c,
                    Apttus_Config2__OrderLineItemId__r.Apttus_Config2__IsPrimaryLine__c
                    from Apttus_Config2__OrderFulfillmentLineItem__c where Apttus_Config2__OrderLineItemId__c in : oliIdSet];

        for (Apttus_Config2__OrderFulfillmentLineItem__c fli : fliSList) {
            if (fli.Apttus_Config2__OrderLineItemId__r.Apttus_Config2__IsPrimaryLine__c) {
                fli.APTS_GoodsIssue_Status__c = 'Not yet processed';
                fli.APTS_POD_Status__c = 'Not Relevant';
                fli.APTS_GoodsIssue_Date__c = null;
            }
        }

        update fliSList;

        for (Apttus_Config2__OrderLineItem__c o : oli) {
            if (o.Apttus_Config2__IsPrimaryLine__c) {
                o.APTS_Serial_Number__c = null;
            }
        }
        update oli;

        Id accountId = olist[0].Apttus_Config2__SoldToAccountId__c;
        List<PhysicalAsset__c> pal = [select id from PhysicalAsset__c where SoldTo__c = :accountId];

        delete pal;

        return null;
    }

    public PageReference setOLIInstDate() {

        Integer i = 0;
        for (Apttus_Config2__OrderLineItem__c o : oli) {
            if (o.APTS_Is_Primary_L1_Line__c) {
                if (o.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c == 'Installation') {
                    o.APTS_Installation_Date_Authorized__c = installDate + i;
                    i++;
                } else if (o.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c == 'De-installation') {
                    o.APTS_De_installation_Date_Authorized__c = installDate + i;
                    i++;
                } else {
                    o.APTS_Installation_Date_Authorized__c = installDate + i;
                    // o.APTS_De_installation_Date_Authorized__c = installDate + i;
                    i++;
                }
            }
        }
        update oli;

        return null;
    }

    public PageReference setOLIInstDateWithBatch() {

        APTS_ActivateOrdersBatch oSetOrderInstallationDateBatch = new APTS_ActivateOrdersBatch();
        //APTS_OrderInstallationDateBatch oSetOrderInstallationDateBatch = new APTS_OrderInstallationDateBatch();
        Database.executebatch(oSetOrderInstallationDateBatch, 1);

        return null;
    }

    public PageReference clearAsset() {

        Id accountId = olist[0].Apttus_Config2__SoldToAccountId__c;

        list<Integration_Log__c> i = [select id from Integration_Log__c where Account__c = :accountId];
        delete i;

        List<Apttus_Config2__AssetLineItem__c> ali = [select id from Apttus_Config2__AssetLineItem__c where Apttus_Config2__AccountId__c = :accountId];
        delete ali;

        List<PhysicalAsset__c> pal = [select id from PhysicalAsset__c where SoldTo__c = :accountId];
        delete pal;

        delete olist;

        return null;
    }

    public PageReference clearAccount() {

        Id accountId = olist[0].Apttus_Config2__SoldToAccountId__c;

        list<Integration_Log__c> i = [select id from Integration_Log__c where Account__c = :accountId];
        delete i;

        list<Apttus_Config2__Order__c> ol = [select id from Apttus_Config2__Order__c where Apttus_Config2__SoldToAccountId__c = :accountId];
        delete ol;

        list<Apttus__APTS_Agreement__c> al = [select id from Apttus__APTS_Agreement__c where Apttus__Account__c = :accountId];
        delete al;

        list<APTS_Contract_Entitlement_Repository__c> erl = [select id from APTS_Contract_Entitlement_Repository__c where APTS_Sold_to_Party__c = :accountId];
        delete erl;

        List<Apttus_Config2__AssetLineItem__c> ali = [select id from Apttus_Config2__AssetLineItem__c where Apttus_Config2__AccountId__c = :accountId];
        delete ali;

        List<PhysicalAsset__c> pal = [select id from PhysicalAsset__c where SoldTo__c = :accountId];
        delete pal;

        return null;
    }

    public PageReference activateAsset() {

        Id accountId = olist[0].Apttus_Config2__SoldToAccountId__c;

        List<Apttus_Config2__AssetLineItem__c> ali = [select id, Apttus_Config2__AssetStatus__c from Apttus_Config2__AssetLineItem__c where Apttus_Config2__AccountId__c = :accountId];
        for (Apttus_Config2__AssetLineItem__c oA : ali) {
            oA.Apttus_Config2__CancelledDate__c = null;
            oA.Apttus_Config2__IsInactive__c = false;
            oA.Apttus_Config2__AssetStatus__c = 'Activated';
        }

        update ali;

        return null;
    }

    public PageReference partialFulfillment() {

        List<Apttus_Config2__OrderFulfillmentLineItem__c> fliList = new List<Apttus_Config2__OrderFulfillmentLineItem__c>();

        for (Apttus_Config2__OrderLineItem__c o : oli) {
            if (o.APTS_Item_Relevant_for_SAP__c) {

                Apttus_Config2__OrderFulfillmentLineItem__c fli = new Apttus_Config2__OrderFulfillmentLineItem__c();
                fli.Apttus_Config2__LineNumber__c = 1;
                fli.Apttus_Config2__OrderFulfillmentId__c = oFLI.Id;
                fli.APTS_GoodsIssue_Status__c = 'Not Relevant';
                fli.Apttus_Config2__OrderLineItemId__c = o.Id;
                fli.Apttus_Config2__OrderId__c = orderid;
                fli.APTS_POD_Status__c = 'Not Relevant';
                fli.APTS_Fulfilled_Quantity__c = 5;
                fli.APTS_Material_Number_SAP__c = (o.Apttus_Config2__OptionId__c != null)? o.Apttus_Config2__OptionId__r.ProductCode : o.Apttus_Config2__ProductId__r.ProductCode;
                fliList.add(fli);

                Apttus_Config2__OrderFulfillmentLineItem__c fli1 = new Apttus_Config2__OrderFulfillmentLineItem__c();
                fli1.Apttus_Config2__LineNumber__c = 1;
                fli1.Apttus_Config2__OrderFulfillmentId__c = oFLI.Id;
                fli1.APTS_GoodsIssue_Status__c = 'Not yet processed';
                fli1.Apttus_Config2__OrderLineItemId__c = o.Id;
                fli1.Apttus_Config2__OrderId__c = orderid;
                fli1.APTS_POD_Status__c = 'Not Relevant';
                fli1.APTS_Fulfilled_Quantity__c = 3;
                fli1.APTS_Material_Number_SAP__c = (o.Apttus_Config2__OptionId__c != null)? o.Apttus_Config2__OptionId__r.ProductCode : o.Apttus_Config2__ProductId__r.ProductCode;
                fliList.add(fli1);

                Apttus_Config2__OrderFulfillmentLineItem__c fli2 = new Apttus_Config2__OrderFulfillmentLineItem__c();
                fli2.Apttus_Config2__LineNumber__c = 1;
                fli2.Apttus_Config2__OrderFulfillmentId__c = oFLI.Id;
                fli2.APTS_GoodsIssue_Status__c = 'Not Relevant';//'Not yet processed';
                fli2.Apttus_Config2__OrderLineItemId__c = o.Id;
                fli2.Apttus_Config2__OrderId__c = orderid;
                fli2.APTS_POD_Status__c = 'Not Relevant';
                fli2.APTS_Fulfilled_Quantity__c = 2;
                fli2.APTS_Material_Number_SAP__c = (o.Apttus_Config2__OptionId__c != null)? o.Apttus_Config2__OptionId__r.ProductCode : o.Apttus_Config2__ProductId__r.ProductCode;
                fliList.add(fli2);
            }
        }

        insert fliList;

        return null;
    }

    public PageReference deliverPart() {


        List<Apttus_Config2__OrderFulfillmentLineItem__c> fliSList = [
                    select id, APTS_GoodsIssue_Status__c, APTS_Fulfilled_Quantity__c,
                    APTS_POD_Status__c, APTS_POD_Date__c
                    from Apttus_Config2__OrderFulfillmentLineItem__c where APTS_GoodsIssue_Status__c <> 'Completely processed' AND Apttus_Config2__OrderLineItemId__c in : oliIdSet];

        fliSList[0].APTS_GoodsIssue_Status__c = 'Completely processed';
        fliSList[0].APTS_POD_Status__c = 'Completely processed';
        fliSList[0].APTS_POD_Date__c = Date.today();
        fliSList[0].APTS_GoodsIssue_Date__c = Date.today();

        update fliSList;

        return null;
    }







    public PageReference setSAPIdOnOrder() {

        olist[0].APTS_Order_Header_SAP_ID__c = '123';
        update olist;

        return null;
    }

    public PageReference setSAPIdOnOrderLI() {

        for (Apttus_Config2__OrderLineItem__c o : oli) {
            if (o.Apttus_Config2__IsPrimaryLine__c) {
                o.APTS_SAP_Order_Line_Item_Number__c = '123';
                o.APTS_Expected_Delivery_Quantity__c = o.Apttus_Config2__Quantity__c;
                o.APTS_Expected_Delivery_Date__c = Date.today();
                o.APTS_Requested_Delivery_Date__c = Date.today();
            }
        }
        update oli;

        return null;
    }

    public PageReference setSAPIdNotOnAllOrderLI() {

        Integer i = 0;
        for (Apttus_Config2__OrderLineItem__c o : oli) {

            if (o.Apttus_Config2__IsPrimaryLine__c && i < 3) {
                o.APTS_SAP_Order_Line_Item_Number__c = '123';
                o.APTS_Expected_Delivery_Quantity__c = o.Apttus_Config2__Quantity__c;
                o.APTS_Expected_Delivery_Date__c = o.APTS_Requested_Delivery_Date__c;
            }

            i++;
        }
        update oli;

        return null;
    }

    public PageReference createFLINYPNR() {

        List<Apttus_Config2__OrderFulfillmentLineItem__c> fliList = new List<Apttus_Config2__OrderFulfillmentLineItem__c>();

        for (Apttus_Config2__OrderLineItem__c o : oli) {
            Apttus_Config2__OrderFulfillmentLineItem__c fli = new Apttus_Config2__OrderFulfillmentLineItem__c();
            fli.Apttus_Config2__LineNumber__c = 1;
            fli.Apttus_Config2__OrderFulfillmentId__c = oFLI.Id;
            fli.APTS_GoodsIssue_Status__c = 'Not yet processed';
            fli.Apttus_Config2__OrderLineItemId__c = o.Id;
            fli.Apttus_Config2__OrderId__c = orderid;
            fli.APTS_POD_Status__c = 'Not Relevant';
            fliList.add(fli);
        }

        insert fliList;

        return null;
    }

    public PageReference updateFLICP() {

        List<Apttus_Config2__OrderFulfillmentLineItem__c> fliSList = [
                    select id, APTS_GoodsIssue_Status__c, APTS_Fulfilled_Quantity__c,
                    APTS_POD_Status__c, APTS_POD_Date__c
                    from Apttus_Config2__OrderFulfillmentLineItem__c where Apttus_Config2__OrderLineItemId__c in : oliIdSet];

        for (Apttus_Config2__OrderFulfillmentLineItem__c fli : fliSList) {

            fli.APTS_GoodsIssue_Status__c = 'Completely processed';
            fli.APTS_POD_Status__c = 'Completely processed';
            fli.APTS_Fulfilled_Quantity__c = 1;
            fli.APTS_POD_Date__c = Date.today();
        }
        update fliSList;

        return null;
    }

    public PageReference deleteLogs() {

        /*list<APTS_Debug_Log__c> l = [select id from APTS_Debug_Log__c];
        delete l; */

        return null;
    }
}