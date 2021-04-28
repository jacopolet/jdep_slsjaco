/**********************************************************************
Name: APTS_CreateConversionOrderController
Date: 06 July 2020
DEsciption: Contorller for Creating Conversion Orders from lwc Componant
Reference: aptsConverionOrderSelection - Lwc
Author: Sai Sagar
Change Verison History: 
**********************************************************************/

public with sharing class APTS_CreateConversionOrderController {
    public class AssetLineItem{
        @AuraEnabled public Apttus_Config2__AssetLineItem__c assetLine {get;set;}
        @AuraEnabled public Date nextInvoicedDate {get;set;}
        public AssetLineItem(Apttus_Config2__AssetLineItem__c assetLine, Date nextInvoicedDate){
            this.assetLine = assetLine;
            this.nextInvoicedDate = nextInvoicedDate;
        }
    }
    public class ReturnWrapper{
        @AuraEnabled public Apttus_Config2__Order__c order {get;set;}
        @AuraEnabled public String message {get;set;}
        @AuraEnabled public Boolean isSuccess {get;set;}
        public ReturnWrapper(Apttus_Config2__Order__c order,Boolean isSuccess, String message){
            this.order = order;
            this.message = message;
            this.isSuccess = isSuccess;
        }
    } 

    public class BillingSettingWrapper{
        public String Id;
        public Date startDate;
        public String billingPreferenceId;
        public String billingFrequency;
    }

    public class DiscountWrapper{
        @AuraEnabled public Integer rowNumber {get;set;}
        @AuraEnabled public String assetLink {get;set;}
        @AuraEnabled public ID id {get;set;}
        @AuraEnabled public String name {get;set;}
        @AuraEnabled public String billingFrequency {get;set;}
        @AuraEnabled public Date minPendingInvoice {get;set;}
        @AuraEnabled public Date nextInvoiceDate {get;set;}
        @AuraEnabled public Date originalStartDate {get;set;}
        @AuraEnabled public Date startDate {get;set;}
        @AuraEnabled public Date endDate {get;set;}
        @AuraEnabled public Decimal sellingTerm {get;set;}
        @AuraEnabled public String chargeType {get;set;}
        @AuraEnabled public Decimal basePrice {get;set;}
        @AuraEnabled public Decimal basePriceOverride {get;set;}
        @AuraEnabled public String  subType {get;set;}
        @AuraEnabled public Decimal discountAmount {get;set;}
        @AuraEnabled public Decimal discountPercentage {get;set;}
        @AuraEnabled public Decimal netUnitPrice {get;set;}
        @AuraEnabled public String startDateModified {get;set;}
        @AuraEnabled public String sellingTermModified {get;set;}
        @AuraEnabled public String bpoModified {get;set;}
        @AuraEnabled public String percentageModified {get;set;}
        @AuraEnabled public String netUnitPriceModified {get;set;}
    }
    public class TerminationWrapper{
        @AuraEnabled public ID id {get;set;}
        @AuraEnabled public String name {get;set;}
        @AuraEnabled public String chargeType {get;set;}
        @AuraEnabled public Date originalStartDate {get;set;}
        @AuraEnabled public Date assetEndDate {get;set;}
        @AuraEnabled public Date lastInvoicedPeriod {get;set;}
        @AuraEnabled public Date nextInvoiceDate {get;set;}
    }
    public class RenewalWrapper{
        @AuraEnabled public ID id {get;set;}
        @AuraEnabled public String name {get;set;}
        @AuraEnabled public String chargeType {get;set;}
        @AuraEnabled public String billingCycleStart {get;set;}
        @AuraEnabled public String billingDayOfMonth {get;set;}
        @AuraEnabled public Date assetStartDate {get;set;}
        @AuraEnabled public Date assetEndDate {get;set;}
        @AuraEnabled public Date nextInvoiceDate {get;set;}
        @AuraEnabled public String billingRule {get;set;}
    }
 
    public class OrderStatusWrapper{
        @AuraEnabled public ID id {get;set;}
        @AuraEnabled public String subType {get;set;}
        @AuraEnabled public String action {get;set;}
        @AuraEnabled public String name {get;set;}
        @AuraEnabled public Datetime createdDate {get;set;}
        @AuraEnabled public String createdBy {get;set;}
        @AuraEnabled public String status {get;set;}
        @AuraEnabled public Id errorId {get;set;}
        @AuraEnabled public String errorName {get;set;}
        @AuraEnabled public Boolean cancelOrder {get;set;}
        @AuraEnabled public String sapOrder {get;set;}
        @AuraEnabled public object invoice {get;set;}
    }

    @AuraEnabled(cacheable=true)
    public static List<APTS_Conversion_Order_Options__mdt> getConversionOrderOptions() {
        return [SELECT Id, DeveloperName, MasterLabel, APTS_Description__c,APTS_Sequence__c  FROM APTS_Conversion_Order_Options__mdt where APTS_Active__c = true order by APTS_Sequence__c asc];        
    }   
   
    @AuraEnabled(cacheable=true)
    public static list<AssetLineItem> getAssetOptions(string bundelHeaderId){        
        list<AssetLineItem> assetOptions = new list<AssetLineItem>();
        Map<Id, Apttus_Config2__AssetLineItem__c>  assetOptionMap = new Map<Id,Apttus_Config2__AssetLineItem__c>([select id, Name, APTS_Type_Of_Contract__c,Apttus_Config2__ChargeType__c,Apttus_Config2__AssetStatus__c,
                                                                    Apttus_Config2__BillingPreferenceId__c,Apttus_Config2__BillThroughDate__c,Apttus_Config2__AccountId__r.Sales_Organization__c,
                                                                    Apttus_Config2__BillingPreferenceId__r.Name,Apttus_Config2__OriginalStartDate__c,
                                                                    Apttus_Config2__BillingPreferenceId__r.Apttus_Config2__BillingCycleStart__c ,
                                                                    Apttus_Config2__BillingPreferenceId__r.Apttus_Config2__BillingDayOfMonth2__c,
                                                                    Apttus_Config2__BillingDayOfMonth__c,Apttus_Config2__BillingFrequency__c,
                                                                    Apttus_Config2__StartDate__c,Apttus_Config2__EndDate__c,Apttus_Config2__SellingTerm__c,Apttus_Config2__BillingRule__c
                                                                    from Apttus_Config2__AssetLineItem__c where APTS_Is_Primary_L1_Asset__c =: bundelHeaderId and  
                                                                    Apttus_Config2__LineType__c = 'Option' and Apttus_Config2__PriceType__c='Recurring' and Apttus_Config2__AssetStatus__c = 'Activated']);

        if(assetOptionMap != null && assetOptionMap.size() > 0){
            Map<String, Date> assetIdLastInvoceDate = APTS_MovementOrderUtils.calculateMinPendingBillingDate(assetOptionMap.keyset());
            for(Apttus_Config2__AssetLineItem__c asset: assetOptionMap.values()){
                Date nextInvoiceDate ;
                if(assetIdLastInvoceDate != null && assetIdLastInvoceDate.containsKey(asset.Id)){
                    nextInvoiceDate = assetIdLastInvoceDate.get(asset.Id);
                }
                assetOptions.add(new AssetLineItem(asset, nextInvoiceDate) );
            }   
        }     
        return assetOptions;
    }

    @AuraEnabled(cacheable=true)
    public static List<Apttus_Config2__Order__c> getConversionOrdersForMachine(string bundelHeaderId) {
        return [select id, Name, CreatedDate,  APTS_Order_Sub_Sub_Type__c,Apttus_Config2__Status__c  from Apttus_Config2__Order__c where APTS_L1_Asset_Line_Item__c =: bundelHeaderId order by CreatedDate desc];        
    }     

    //Discounts
    @AuraEnabled(cacheable=true)
    public static List<DiscountWrapper> getOptionLines(string recordId) {
        list<DiscountWrapper> returnObject = new list<DiscountWrapper>();
        Map<Id, Apttus_Config2__AssetLineItem__c>  assetOptionMap=new  Map<Id, Apttus_Config2__AssetLineItem__c>();
        assetOptionMap = new Map<Id,Apttus_Config2__AssetLineItem__c>([SELECT Id,Name,Apttus_Config2__ChargeType__c, Apttus_Config2__StartDate__c,Apttus_Config2__OriginalStartDate__c, 
                                                                        Apttus_Config2__EndDate__c,Apttus_Config2__SellingTerm__c,Apttus_Config2__BillingFrequency__c, Apttus_Config2__BasePrice__c, APTS_BasePriceOverride__c, 
                                                                        Apttus_Config2__NetUnitPrice__c,(select id,Apttus_Config2_SubType__c,Apttus_Config2_AssetAdjustType__c,Apttus_Config2_AssetAdjustAmount__c 
                                                                        from Asset_Adjustment_Line_Item__r)  from Apttus_Config2__AssetLineItem__c  
                                                                        where APTS_Is_Primary_L1_Asset__c =:recordId and  Apttus_Config2__LineType__c = 'Option' and 
                                                                        Apttus_Config2__AssetStatus__c = 'Activated' and Apttus_Config2__PriceType__c='Recurring']);   
        if(assetOptionMap.size() > 0){
            Map<String, Date> assetIdLastInvoceDate = APTS_MovementOrderUtils.calculateMinPendingBillingDate(assetOptionMap.keyset());
            Map<String,Date> minPendingInvoiceBillingDateMap = new Map<String,Date>(); 
            for(AggregateResult billingSch : [select Apttus_Billing__AssetLineItemId__c,MIN(Apttus_Billing__ReadyForInvoiceDate__c) from Apttus_Billing__BillingSchedule__c where Apttus_Billing__Status__c ='Pending Invoiced' and Apttus_Billing__AssetLineItemId__c IN: assetOptionMap.keyset() group by Apttus_Billing__AssetLineItemId__c]){
                if(minPendingInvoiceBillingDateMap.get(String.valueOf(billingSch.get('Apttus_Billing__AssetLineItemId__c')))==null){
                    minPendingInvoiceBillingDateMap.put(String.valueOf(billingSch.get('Apttus_Billing__AssetLineItemId__c')),Date.valueOf(billingSch.get('expr0')));
                }
            }
            for(Apttus_Config2__AssetLineItem__c asset: assetOptionMap.values()){
                DiscountWrapper dw=new DiscountWrapper();
                dw.Id =asset.Id;
                dw.name =asset.Name;
                if(assetIdLastInvoceDate != null && assetIdLastInvoceDate.containsKey(asset.Id)){
                    dw.nextInvoiceDate= assetIdLastInvoceDate.get(asset.Id);
                }
                if(minPendingInvoiceBillingDateMap != null && minPendingInvoiceBillingDateMap.containsKey(asset.Id)){
                    dw.minPendingInvoice= minPendingInvoiceBillingDateMap.get(asset.Id);
                }
                dw.originalStartDate =asset.Apttus_Config2__OriginalStartDate__c;
                dw.startDate =asset.Apttus_Config2__StartDate__c;
                dw.endDate =asset.Apttus_Config2__EndDate__c;
                dw.sellingTerm=asset.Apttus_Config2__SellingTerm__c;
                dw.billingFrequency= asset.Apttus_Config2__BillingFrequency__c;
                dw.chargeType =asset.Apttus_Config2__ChargeType__c;
                dw.basePrice =asset.Apttus_Config2__BasePrice__c;
                dw.basePriceOverride =asset.APTS_BasePriceOverride__c;
                dw.netUnitPrice =asset.Apttus_Config2__NetUnitPrice__c;
                for(Apttus_Config2_AssetAdjustItem__c currentAdj : asset.Asset_Adjustment_Line_Item__r){
                    if(currentAdj.Apttus_Config2_AssetAdjustAmount__c!=null && currentAdj.Apttus_Config2_AssetAdjustType__c!=null){
                        dw.subType= currentAdj.Apttus_Config2_SubType__c;
                        if(currentAdj.Apttus_Config2_AssetAdjustType__c=='Base Price Discount'){
                            dw.discountAmount=currentAdj.Apttus_Config2_AssetAdjustAmount__c;
                        }
                        else if(currentAdj.Apttus_Config2_AssetAdjustType__c=='% Discount'){
                            dw.discountPercentage=currentAdj.Apttus_Config2_AssetAdjustAmount__c;
                        }
                    }
                    break;
                }

                returnObject.add(dw);
            }   
        } 
        return returnObject;
    } 
    @AuraEnabled(cacheable=true)
    public static List<TerminationWrapper> getOptionLinesForTermination(string recordId) {
        list<TerminationWrapper> returnObject = new list<TerminationWrapper>();
        system.debug('recordId-->'+recordId);
        Map<Id, Apttus_Config2__AssetLineItem__c>  assetOptionMap=new  Map<Id, Apttus_Config2__AssetLineItem__c>();
        assetOptionMap = new Map<Id,Apttus_Config2__AssetLineItem__c>([SELECT  id,Name,Apttus_Config2__ChargeType__c,Apttus_Config2__OriginalStartDate__c, Apttus_Config2__EndDate__c from Apttus_Config2__AssetLineItem__c  
                                                                        where APTS_Is_Primary_L1_Asset__c =:recordId and  Apttus_Config2__LineType__c = 'Option' and 
                                                                        Apttus_Config2__AssetStatus__c = 'Activated' and Apttus_Config2__PriceType__c='Recurring']);   
        if(assetOptionMap.size() > 0){
            Map<String, Date> assetIdLastInvoceDate = APTS_MovementOrderUtils.calculateMinPendingBillingDate(assetOptionMap.keyset());
            Map<String,Date> maxPendingBillingDateMap = new Map<String,Date>(); 
            for(AggregateResult billingSch : [select Apttus_Billing__AssetLineItemId__c,MAX(Apttus_Billing__ReadyForInvoiceDate__c) from Apttus_Billing__BillingSchedule__c where Apttus_Billing__Status__c ='Invoiced' and Apttus_Billing__AssetLineItemId__c IN: assetOptionMap.keyset() group by Apttus_Billing__AssetLineItemId__c]){
                if(maxPendingBillingDateMap.get(String.valueOf(billingSch.get('Apttus_Billing__AssetLineItemId__c')))==null){
                    maxPendingBillingDateMap.put(String.valueOf(billingSch.get('Apttus_Billing__AssetLineItemId__c')),Date.valueOf(billingSch.get('expr0')));
                }
            }
            
            for(Apttus_Config2__AssetLineItem__c asset: assetOptionMap.values()){
                TerminationWrapper tw=new TerminationWrapper();
                tw.Id =asset.Id;
                tw.name =asset.Name;
                if(assetIdLastInvoceDate != null && assetIdLastInvoceDate.containsKey(asset.Id)){
                    tw.nextInvoiceDate= assetIdLastInvoceDate.get(asset.Id);
                }
                if(maxPendingBillingDateMap != null && maxPendingBillingDateMap.containsKey(asset.Id)){
                    tw.lastInvoicedPeriod= maxPendingBillingDateMap.get(asset.Id);
                }
                tw.originalStartDate=asset.Apttus_Config2__OriginalStartDate__c;
                tw.assetEndDate =asset.Apttus_Config2__EndDate__c;
                tw.chargeType =asset.Apttus_Config2__ChargeType__c;
                returnObject.add(tw);
            }   
        } 
        system.debug('returnObject-->'+returnObject);
        return returnObject;
    } 
    @AuraEnabled(cacheable=true)
    public static List<RenewalWrapper> getOptionLinesForRenewal(string recordId) {
        list<RenewalWrapper> returnObject = new list<RenewalWrapper>();
        system.debug('recordId-->'+recordId);
        Map<Id, Apttus_Config2__AssetLineItem__c>  assetOptionMap=new  Map<Id, Apttus_Config2__AssetLineItem__c>();
        assetOptionMap = new Map<Id,Apttus_Config2__AssetLineItem__c>([SELECT  id,Name,Apttus_Config2__ChargeType__c,
        Apttus_Config2__BillingPreferenceId__r.Apttus_Config2__BillingCycleStart__c ,Apttus_Config2__BillingRule__c,
                                                                    Apttus_Config2__BillingPreferenceId__r.Apttus_Config2__BillingDayOfMonth2__c,
                                                                    Apttus_Config2__StartDate__c, Apttus_Config2__EndDate__c from Apttus_Config2__AssetLineItem__c  
                                                                        where APTS_Is_Primary_L1_Asset__c =:recordId and  Apttus_Config2__LineType__c = 'Option' and 
                                                                        Apttus_Config2__AssetStatus__c = 'Activated' and Apttus_Config2__PriceType__c='Recurring']);   
        if(assetOptionMap.size() > 0){
            Map<String, Date> assetIdLastInvoceDate = APTS_MovementOrderUtils.calculateMinPendingBillingDate(assetOptionMap.keyset());
            for(Apttus_Config2__AssetLineItem__c asset: assetOptionMap.values()){
                RenewalWrapper rw=new RenewalWrapper();
                rw.Id =asset.Id;
                rw.name =asset.Name;
                if(assetIdLastInvoceDate != null && assetIdLastInvoceDate.containsKey(asset.Id)){
                    rw.nextInvoiceDate= assetIdLastInvoceDate.get(asset.Id);
                }

                rw.assetStartDate =asset.Apttus_Config2__StartDate__c;
                rw.assetEndDate =asset.Apttus_Config2__EndDate__c;
                rw.chargeType =asset.Apttus_Config2__ChargeType__c;
                rw.billingCycleStart =asset.Apttus_Config2__BillingPreferenceId__r.Apttus_Config2__BillingCycleStart__c;
                rw.billingDayOfMonth  =asset.Apttus_Config2__BillingPreferenceId__r.Apttus_Config2__BillingDayOfMonth2__c;
                rw.billingRule  =asset.Apttus_Config2__BillingRule__c;
                returnObject.add(rw);
            }   
        } 
        system.debug('returnObject-->'+returnObject);
        return returnObject;
    }
 
    @AuraEnabled
    public static List<OrderStatusWrapper> getOrderStatus(string recordId) {
        list<OrderStatusWrapper> returnObject = new list<OrderStatusWrapper>();
        Map<Id,String> deInstallationmap = new Map<Id,String>();
        if(recordId!=null){
            list<Id> orderIds = new list<Id>();
            List<String> deInstallationOrderStatus = System.Label.APTS_DeInstallationABOStatus.split(',');
            List<String> tempDependentOrderSubTypes =new List<String>();
            List<String> tempInDependentOrderSubTypes = new List<String>();
            Date tempDeploymentDate;
            for(APTS_New_Conversion_Order__mdt com:[select id,APTS_Dependent_Order_Sub_Types__c, APTS_InDependent_Order_Sub_Types__c, APTS_Deployed_Date__c from APTS_New_Conversion_Order__mdt]){
                tempDependentOrderSubTypes=com.APTS_Dependent_Order_Sub_Types__c.split(';');
                tempInDependentOrderSubTypes=com.APTS_InDependent_Order_Sub_Types__c.split(';');
                tempDeploymentDate=com.APTS_Deployed_Date__c;
            }
            for(Apttus_Config2__OrderLineItem__c  oli:[select id,Apttus_Config2__OrderId__c,APTS_Status__c,Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c,Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c from Apttus_Config2__OrderLineItem__c  where Apttus_Config2__AssetLineItemId__c=:recordId AND (Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c in:tempInDependentOrderSubTypes OR ( Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c in:tempDependentOrderSubTypes AND CreatedDate>:tempDeploymentDate) )]){
                if(oli.Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c=='XA23' && oli.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c =='Installation'){
                orderIds.add(oli.Apttus_Config2__OrderId__c);
                }
                if(oli.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c !='Installation'){
                orderIds.add(oli.Apttus_Config2__OrderId__c);
                }
                if(oli.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c == 'De-Installation' ){
                    deInstallationmap.put(oli.Apttus_Config2__OrderId__c,oli.APTS_Status__c);
                }
            }   
            Map<Id, Apttus_Config2__Order__c>  orderMap=new  Map<Id, Apttus_Config2__Order__c>();
            orderMap = new Map<Id,Apttus_Config2__Order__c>([SELECT  id,Name,APTS_Order_Sub_Type__c,APTS_Order_Sub_Sub_Type__c,Apttus_Config2__Status__c,CreatedDate,CreatedBy.name,APTS_SAP_OrderType__c,APTS_Invoice__c,(Select Id,Name from Error_Objects__r)   from Apttus_Config2__Order__c where (APTS_L1_Asset_Line_Item__c=:recordId  OR ID in :orderIds) and APTS_Conversion_UX_Exclude__c=false order by CreatedDate desc]);   
            if(orderMap.size() > 0){
                for(Apttus_Config2__Order__c record: orderMap.values()){
                    OrderStatusWrapper osw=new OrderStatusWrapper();
                    osw.id =record.id;
                    osw.name =record.Name;
                    osw.createdBy=record.CreatedBy.name;
                    osw.subType =record.APTS_Order_Sub_Type__c;
                    osw.action =record.APTS_Order_Sub_Sub_Type__c;
                    osw.createdDate =record.CreatedDate;
                    osw.invoice=record.APTS_Invoice__c;
                    osw.sapOrder=record.APTS_SAP_OrderType__c;
                    if(deInstallationOrderStatus.contains(record.Apttus_Config2__Status__c) && record.APTS_Order_Sub_Type__c=='Conversion Order'){
                    osw.cancelOrder = false;
                    }else{
                        osw.cancelOrder = true; 
                    }
                    if(deInstallationmap.containskey(record.id)){
                      osw.status = deInstallationmap.get(record.id);
                      }
                      else{
                      osw.status =record.Apttus_Config2__Status__c;
                      }
                    for(APTS_Error_Object__c  errObj : record.Error_Objects__r){
                        osw.errorId  =errObj.Id;
                        osw.errorName  =errObj.Name;
                        break;
                    }
                    returnObject.add(osw);
                }   
            } 
        }
        return returnObject;
    }

    @AuraEnabled
    public static Apttus_Config2__Order__c cancelOrderStatus(String orderId){
        system.debug('Into the loop==>'+orderId);
        Apttus_Config2__Order__c orderRec = [select id,Apttus_Config2__Status__c from Apttus_Config2__Order__c
                                                where Name=:orderId];
        orderRec.Apttus_Config2__Status__c='Cancelled';
        system.debug('Passed==>'+orderRec);
        update orderRec;
        return orderRec;
    }

    @AuraEnabled
    public static ReturnWrapper createConversionOrder(ID primaryL1AssetId,String subSubType,
                                                        String orderInput,Date assetNewDate,
                                                        string bundleLevelAttributes,Boolean creditBlock,
                                                        String invoiceRemark, Case orderCase){
        List<Apttus_Config2__Order__c> orderList = new List<Apttus_Config2__Order__c>();
        List<Apttus_Config2__AssetLineItem__c> primaryL1Asset=new List<Apttus_Config2__AssetLineItem__c>();
        Apttus_Config2__Order__c oOrder=new Apttus_Config2__Order__c();
        APTS_CustomErrorLogging.assignTransactionId(null);
        ReturnWrapper rw;
        try{
            primaryL1Asset=[Select Id,
            APTS_relatedlist_agreement__r.Id,
            APTS_relatedlist_agreement__r.Name, 
            APTS_relatedlist_agreement__r.APTS_Check_on_Account_Machines__c,
            APTS_relatedlist_agreement__r.APTS_Check_on_Account_Ingredients__c,
            APTS_relatedlist_agreement__r.Apttus_CMConfig__PriceListId__c, 
            APTS_relatedlist_agreement__r.Apttus_CMConfig__BillingPreferenceId__c,
            APTS_relatedlist_agreement__r.Apttus_CMConfig__PONumber__c, 
            APTS_relatedlist_agreement__r.Apttus_CMConfig__PaymentTermId__c, 
            APTS_relatedlist_agreement__r.APTS_Language__c,
            APTS_relatedlist_agreement__r.APTS_Bill_to_Party_Ingredients__c,
            APTS_relatedlist_agreement__r.APTS_Payer_Ingredients__c,
            APTS_relatedlist_agreement__r.APTS_Bill_to_Party_MachServ__c,
            APTS_relatedlist_agreement__r.APTS_Payer_Machines_Services__c,
            Apttus_Config2__BundleAssetId__c,
            CurrencyIsoCode,
            Apttus_Config2__AccountId__r.id, 
            Apttus_Config2__AccountId__r.Apttus_Config2__BillingPreferenceId__c,
            Apttus_Config2__AccountId__r.Apttus_Config2__PaymentTermId__c, 
            Apttus_Config2__AccountId__r.Language__c,
            Apttus_Config2__AccountId__r.Sales_Organization__c, 
            Apttus_Config2__AccountId__r.Division__c,
            Apttus_Config2__AccountId__r.Distribution_Channel__c,
            Apttus_Config2__AccountId__r.Bill_To_Payer_Account__c,
            Apttus_Config2__AccountId__r.Related_Payer_Account__c,
            Apttus_Config2__AccountId__r.Related_Payer_Machines_Services__c
            FROM Apttus_Config2__AssetLineItem__c where id=:primaryL1AssetId];
            if(primaryL1Asset.size() > 0){
                oOrder = APTS_CLMUtil.createAdminOrder(primaryL1Asset[0].APTS_relatedlist_agreement__r,primaryL1Asset[0].Apttus_Config2__AccountId__r,'Conversion Order');
                oOrder.APTS_Order_Sub_Sub_Type__c=subSubType;
                if(orderInput!=null){
                    oOrder.APTS_Conversion_Order_Input__c=orderInput;
                }
                else if(assetNewDate!=null){
                    oOrder.APTS_Conversion_Order_Input__c=assetNewDate.format();
                }
                oOrder.APTS_L1_Asset_Line_Item__c  = primaryL1AssetId;
                oOrder.CurrencyIsoCode=primaryL1Asset[0].CurrencyIsoCode;
                oOrder.APTS_Credit_Proposal_XC09_Block__c = creditBlock != null ? creditBlock : null;
                oOrder.APTS_Case__c = orderCase != null ? orderCase.Id : null ;
                oOrder.APTS_Invoice_Remark__c = invoiceRemark != null ? invoiceRemark : null;
                orderList.add(oOrder);
                if(orderList.size() > 0){
                    APTS_OrderUtils.stopOrderTrigger();
                    Database.insert(orderList, false);
                    APTS_OrderUtils.startOrderTrigger();
                    if(orderList[0].ID!=null){
                        Id bundleId;
                        bundleId=primaryL1Asset[0].Apttus_Config2__BundleAssetId__c!=null?primaryL1Asset[0].Apttus_Config2__BundleAssetId__c:primaryL1AssetId;
                        activateOrder(orderList[0].ID,bundleId,orderInput,subSubType,APTS_CustomErrorLogging.transactionId,assetNewDate,bundleLevelAttributes);
                    }
                }
            }
            rw=new ReturnWrapper(oOrder,true,'');
        } catch(Exception ex) {
            rw=new ReturnWrapper(oOrder,false,ex.getMessage());        
        }
        return rw;
    } 


    @future
    public Static void activateOrder(ID orderId,ID primaryL1AssetId,String orderInput,String subSubType,string transactionId,Date assetNewDate,string bundleLevelAttributes)
    {
        Id cartId;
        try{
            APTS_CustomErrorLogging.assignTransactionId(transactionId);
            APTS_AssetRenewalRollbackBatch.bypassCurrentUserfromTriggersandFlows();
            cartId = APTS_OrderUtils.createCart(orderId);
            if(cartId!=null){
                List<ID> assetLIIdList=new List<ID>();
                Map<ID,Apttus_Config2__LineItem__c> lineItemMap=new Map<ID,Apttus_Config2__LineItem__c>();
                assetLIIdList.add(primaryL1AssetId);
                Boolean hasError=false;
                If(subSubType=='Discounts' ||subSubType=='Billing Settings' || subSubType=='Add/Remove Options'){
                    Apttus_Config2.CPQStruct.ChangeAssetsRequestDO request = new Apttus_Config2.CPQStruct.ChangeAssetsRequestDO();
                    request.AssetIds = assetLIIdList;
                    request.CartId = cartId;
                    Apttus_Config2.CPQStruct.ChangeAssetsResponseDO response = Apttus_Config2.AssetService.changeAssets(request);
                    if((response.LineItemMap==null || (response.LineItemMap!=null && response.LineItemMap.isEmpty())) ){
                        hasError=true;
                        APTS_CustomErrorLogging.createErrorLog('APTS_CreateConversionOrderController', 'Apex', 'Apttus_Config2.changeAssets' + ':' + string.valueOf(response), 'Order',orderId, 'OM', false, false, null, true,orderId, null, string.valueOf(response));
                    }
                    else{
                        lineItemMap=response.LineItemMap;
                    }
                }
                else if(subSubType=='Termination'){
                    Apttus_Config2.CPQStruct.CancelAssetsRequestDO request = new Apttus_Config2.CPQStruct.CancelAssetsRequestDO();
                    request.CancelDate = assetNewDate;
                    request.AssetIds = assetLIIdList;
                    request.CartId = cartId;
                    Apttus_Config2.CPQStruct.CancelAssetsResponseDO response = Apttus_Config2.AssetService.cancelAssets(request);
                    if((response.LineItemMap==null || (response.LineItemMap!=null && response.LineItemMap.isEmpty())) ){
                        hasError=true;
                        APTS_CustomErrorLogging.createErrorLog('APTS_CreateConversionOrderController', 'Apex', 'Apttus_Config2.cancelAssets' + ':' + string.valueOf(response), 'Order',orderId, 'OM', false, false, null, true,orderId, null, string.valueOf(response));
                    }
                    else{
                        lineItemMap=response.LineItemMap;
                    }
                }
                else if(subSubType=='Renewal'){
                    Apttus_Config2.CPQStruct.RenewAssetsRequestDO request = new Apttus_Config2.CPQStruct.RenewAssetsRequestDO();
                    request.RenewEndDate = assetNewDate;
                    request.AssetIds = assetLIIdList;
                    //request.RenewTerm=12;
                    request.FarthestAssetEndDate=false;
                    request.CartId = cartId;
                    Apttus_Config2.CPQStruct.RenewAssetsResponseDO response =Apttus_Config2.AssetService.renewAssets(request);
                    if((response.LineItemMap==null || (response.LineItemMap!=null && response.LineItemMap.isEmpty())) ){
                        hasError=true;
                        APTS_CustomErrorLogging.createErrorLog('APTS_CreateConversionOrderController', 'Apex', 'Apttus_Config2.renewAssets' + ':' + string.valueOf(response), 'Order',orderId, 'OM', false, false, null, true,orderId, null, string.valueOf(response));
                    }
                    else{
                        lineItemMap=response.LineItemMap;
                        APTS_AssetLineItemTriggerHandler.createTransDatanewUX(assetLIIdList,assetNewDate);
                    }
                }
                if(!hasError){
                    Apttus_Config2__LineItem__c  lineItemObj=new Apttus_Config2__LineItem__c();
                    List<Apttus_Config2__LineItem__c>  updateLineItemList=new List<Apttus_Config2__LineItem__c>();
                    if(subSubType=='Discounts'){
                        List<DiscountWrapper> discountInputList = (List<DiscountWrapper>)JSON.deserializeStrict(orderInput, List<DiscountWrapper>.class);
                        List<Apttus_Config2__AdjustmentLineItem__c> adjustmentList=new List<Apttus_Config2__AdjustmentLineItem__c>();

                        Apttus_CPQApi.CPQ.UpdateManualAdjustmentsRequestDO adjRequest = new  Apttus_CPQApi.CPQ.UpdateManualAdjustmentsRequestDO();
                        adjRequest.CartId = cartId;
                        List<Apttus_CPQApi.CPQ.AdjustmentItemCollDO> lineItemAdjustments = new List<Apttus_CPQApi.CPQ.AdjustmentItemCollDO>();
                        for(DiscountWrapper dw:discountInputList)
                        {
                            lineItemObj=lineItemMap.get(dw.id);
                            adjustmentList=new List<Apttus_Config2__AdjustmentLineItem__c>();
                            Boolean isLineItemUpdated=false;
                            if(lineItemObj!=null){
                                if(dw.startDate!=null || dw.basePriceOverride!=null){
                                    if(dw.startDate!=null)
                                    {
                                        lineItemObj.Apttus_Config2__StartDate__c=dw.startDate;
                                        lineItemObj.Apttus_Config2__SellingTerm__c=null;
                                    }
                                    if (dw.basePriceOverride!=null)
                                    {
                                        lineItemObj.Apttus_Config2__BasePriceOverride__c=dw.basePriceOverride==0?null:dw.basePriceOverride;
                                        lineItemObj.APTS_is_Indexation_skip__c=true;
                                    }
                                    isLineItemUpdated=true;
                                    //updateLineItemList.add(lineItemObj);
                                }
                                Apttus_CPQApi.CPQ.AdjustmentItemCollDO adjItemColl = new Apttus_CPQApi.CPQ.AdjustmentItemCollDO(); 
                                adjItemColl.LineItemId = lineItemObj.Id;
                                Apttus_Config2__AdjustmentLineItem__c adjLineItemObj=new Apttus_Config2__AdjustmentLineItem__c();
                                if(dw.discountAmount!=null || dw.discountPercentage!=null ){   
                                    if(dw.discountAmount!=null){
                                        
                                        adjLineItemObj.Apttus_Config2__SubType__c=dw.subType;
                                        adjLineItemObj.Apttus_Config2__AdjustmentType__c='Base Price Discount';
                                        adjLineItemObj.Apttus_Config2__AdjustmentAmount__c=dw.discountAmount;
                                    }
                                    else if(dw.discountPercentage!=null){
                                        adjLineItemObj.Apttus_Config2__SubType__c=dw.subType;
                                        adjLineItemObj.Apttus_Config2__AdjustmentType__c='% Discount';
                                        adjLineItemObj.Apttus_Config2__AdjustmentAmount__c=dw.discountPercentage;
                                    }
                                    if(adjLineItemObj.Apttus_Config2__AdjustmentAmount__c!=null && adjLineItemObj.Apttus_Config2__AdjustmentAmount__c==0){
                                        lineItemObj.APTS_ABO_Applied__c=true;
                                        isLineItemUpdated=true;
                                    }
                                    else {
                                        adjustmentList.add(adjLineItemObj);
                                    }
                                }
                                adjItemColl.AdjustmentItems =APTS_DiscountBucketizing.processAdjustmentLineItemfields(adjustmentList);
                                lineItemAdjustments.add(adjItemColl);
                                if(isLineItemUpdated==true){
                                    updateLineItemList.add(lineItemObj);
                                }
                            }
                        }
                        adjRequest.AdjustmentItemColls = lineItemAdjustments;
                        if(updateLineItemList.size()>0)
                        {
                            Database.update(updateLineItemList,false);
                        }
                        Apttus_CPQApi.CPQ.UpdateManualAdjustmentsResponseDO result =  Apttus_CPQApi.CPQWebService.updateManualAdjustmentsForCart(adjRequest);
                    }
                    else if(subSubType=='Billing Settings'){
                        updateLineItemList = getUpdatedLinesWithBillingSettings(lineItemMap, orderInput);
                        if(updateLineItemList.size() > 0){                            
                            Database.update(updateLineItemList,false);
                        }
                    }else if(subSubType=='Add/Remove Options'){
                        APTS_AddRemoveOptionController.processAddRemoveOptions(lineItemMap, orderInput,cartId,bundleLevelAttributes);
                    }
                    if(!lineItemMap.isEmpty()){
                        //Apttus_CPQApi.CPQWebService.associateConstraintRules(cartId,null);
                        //Apttus_CPQApi.CPQWebService.applyConstraintRules(cartId, false);
                        APTS_OrderUtils.repriceCart(cartId);
                        APTS_OrderUtils.repriceCart(cartId);
                        APTS_OrderUtils.repriceCart(cartId);
                        APTS_OrderUtils.finalizeCart(cartId);
                        APTS_OrderUtils.syncCart(cartId);
                        APTS_OrderUtils.acceptOrder(orderId);
                    }else{
                        APTS_CustomErrorLogging.createErrorLog('APTS_CreateConversionOrderController', 'Apex','Error occurred when performing ChangeAsset API! No line items were pulled in the cart!', 'Order',orderId, 'OM', false, false, null, true,orderId, null,null);
                    }
                }
            }
            if(TriggerSettings__c.getValues(UserInfo.getUserId())!=null){
                TriggerSettings__c triggerSettings = TriggerSettings__c.getValues(UserInfo.getUserId());
                Database.delete(triggerSettings,false);
            }
            if(ProcessBuilderSettings__c.getValues(UserInfo.getUserId())!=null){            
                ProcessBuilderSettings__c PBSettings = ProcessBuilderSettings__c.getValues(UserInfo.getUserId());
                Database.delete(PBSettings,false);
            }
        }
        catch(Exception ex){
            Apttus_Config2__Order__c errorOrder=new Apttus_Config2__Order__c();
            errorOrder.id=orderId;
            errorOrder.APTS_Configuration_Status__c='Finalized';
            Database.update(errorOrder,false);
            if(TriggerSettings__c.getValues(UserInfo.getUserId())!=null){
                TriggerSettings__c triggerSettings = TriggerSettings__c.getValues(UserInfo.getUserId());
                Database.delete(triggerSettings,false);
            }
            if(ProcessBuilderSettings__c.getValues(UserInfo.getUserId())!=null){            
                ProcessBuilderSettings__c PBSettings = ProcessBuilderSettings__c.getValues(UserInfo.getUserId());
                Database.delete(PBSettings,false);
            }
            APTS_CustomErrorLogging.createErrorLog('APTS_CreateConversionOrderController', 'Apex', ex.getMessage() + ':' + ex.getStackTraceString(), 'Order',orderId, 'OM', false, false, null, true,orderId, null, ex.getMessage());
        }
        APTS_CustomErrorLogging.saveErrorLog();

    }

    public static List<Apttus_Config2__LineItem__c>  getUpdatedLinesWithBillingSettings(Map<ID,Apttus_Config2__LineItem__c> lineItemMap, string orderInput){
        List<Apttus_Config2__LineItem__c>  updateLineItemList = new List<Apttus_Config2__LineItem__c> ();
        List<BillingSettingWrapper> billingSettingInputList = (List<BillingSettingWrapper>)JSON.deserializeStrict(orderInput, List<BillingSettingWrapper>.class);
      
        ID billingPreferenceId; 
        Map<String,String> chargeTypeMap=new  Map<String,String>();
        for(BillingSettingWrapper rec:billingSettingInputList){
            Apttus_Config2__LineItem__c lineItemObj =lineItemMap.get(rec.id);
            if(lineItemObj!=null){
                if(rec.startDate != null || rec.billingPreferenceId != null  || rec.billingFrequency != null){
                    if(rec.startDate!=null){
                        lineItemObj.Apttus_Config2__StartDate__c=rec.startDate;
                        lineItemObj.Apttus_Config2__SellingTerm__c=null;
                    }
                    if (rec.billingPreferenceId!=null){
                        lineItemObj.Apttus_Config2__BillingPreferenceId__c=rec.billingPreferenceId;
                        billingPreferenceId=rec.billingPreferenceId;
                        lineItemObj.Apttus_Config2__LineStatus__c='Amended';
                    }
                    if (rec.billingFrequency!=null){
                        lineItemObj.Apttus_Config2__BillingFrequency__c=rec.billingFrequency;
                        lineItemObj.Apttus_Config2__LineStatus__c='Amended';
                        if(chargeTypeMap.get(lineItemObj.Apttus_Config2__ChargeType__c)==null){
                            chargeTypeMap.put(lineItemObj.Apttus_Config2__ChargeType__c,rec.billingFrequency);
                        }
                    }                    
                    updateLineItemList.add(lineItemObj);
                }
            }
        }
        for(Id rec: lineItemMap.keySet()){
            Apttus_Config2__LineItem__c lineItemObj =lineItemMap.get(rec);
            if(lineItemObj.Apttus_Config2__LineType__c=='Product/Service' && lineItemObj.Apttus_Config2__PriceType__c=='Recurring' ){
                if(billingPreferenceId!=null || chargeTypeMap.get(lineItemObj.Apttus_Config2__ChargeType__c)!=null){
                    if(billingPreferenceId!=null){
                        lineItemObj.Apttus_Config2__BillingPreferenceId__c=billingPreferenceId;
                        lineItemObj.Apttus_Config2__LineStatus__c='Amended';
                    }
                    if(chargeTypeMap.get(lineItemObj.Apttus_Config2__ChargeType__c)!=null){
                        lineItemObj.Apttus_Config2__BillingFrequency__c=chargeTypeMap.get(lineItemObj.Apttus_Config2__ChargeType__c);
                        lineItemObj.Apttus_Config2__LineStatus__c='Amended';
                    }
                    updateLineItemList.add(lineItemObj);
                }

            }
        }


        System.debug('billingPreferenceId==>'+billingPreferenceId);            
        return updateLineItemList;
    }
    @AuraEnabled(cacheable=true)
    public static List<DiscountWrapper> reCalculateSellingTermForOptions (List<DiscountWrapper> modifiedOptionList){
        List<DiscountWrapper> modifiedList = new List<DiscountWrapper>();
        for(DiscountWrapper discWrap : modifiedOptionList){
            if(discWrap.startDateModified!=null){
                discWrap.sellingTerm = APTS_AddRemoveOptionController.calculateSellingTerm(discWrap.startDate,discWrap.endDate);
                discWrap.sellingTermModified='slds-is-edited slds-text-color_success customFontChanged';
                System.debug('ASSET NAME===>'+discWrap.name);
                System.debug('ASSET START DATE===>'+discWrap.startDate);
                System.debug('ASSET END DATE===>'+discWrap.endDate);
                System.debug('ASSET SELLING TERM===>'+discWrap.sellingTerm);
            }
            modifiedList.add(discWrap);
        }
        return modifiedList;
    }
}