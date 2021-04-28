public with sharing class APTS_ViewATPResultsController {

    public String productWrapper { get; set; }
    public String i { get; set; }
    public String x { get; set; }
    public String y { get; set; }
    public String z { get; set; }
    public String errormsg { get; set; }
    public Apttus_Config2__Order__c oOrder {get; set;}
    public String sATPResultMessage {get; set;}
    private Id OrderId;
    public Boolean isATPCleared {get; set;}
    public List<ProductWrapper> productWrapperList {get; set;}
   

    public APTS_ViewATPResultsController() {
    
 OrderId= ApexPages.currentPage().getParameters().get('id');
                   system.debug('OrderId ::'+OrderId);
                  
     Apttus_Config2__Order__c ord = [Select id, APTS_ATP_Check_Status__c from Apttus_Config2__Order__c where id=: OrderId];
             if(ord != null)
             {                 
              if(ord.APTS_ATP_Check_Status__c != System.Label.APTS_Pass)
             {
   system.debug('isATPCleared = beforefalse :::::::::');         
             isATPCleared = false;
   system.debug('isATPCleared = afterfalse :::::::::');
   errormsg=System.Label.APTS_Errormsg;
           // errormsg= 'Please clickon "ConfigureProducts" Button on Order & change either "Expected Delivery Date" or "Quantity" for the Machines, which has received negative ATP Result';
           // ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Please clickon "ConfigureProducts" Button on Order & change either "Expected Delivery Date" or "Quantity" for the Machines, which has received negative ATP Result'));
             }
             else
             {     
             isATPCleared = true;      
                     
    Set<ID> setLineItemIds = new Set<ID>();
   Map<Id, Apttus_Config2__OrderLineItem__c> OrderLineItemMap = new Map<Id, Apttus_Config2__OrderLineItem__c>([
   SELECT id,Apttus_Config2__OrderId__c,Apttus_Config2__DerivedFromId__c FROM Apttus_Config2__OrderLineItem__c WHERE Apttus_Config2__OrderId__c = :OrderId]);
   system.debug('size of OLI :: '+ OrderLineItemMap.size());
                 for(Apttus_Config2__OrderLineItem__c oli : OrderLineItemMap.values())
                 {
                     if(oli.Apttus_Config2__DerivedFromId__c != null)
                     {
                         setLineItemIds.add(oli.Apttus_Config2__DerivedFromId__c);
                     }
                 }
    
   Map<Id, Apttus_Config2__OrderLineItem__c> OrderLIMap = new Map<Id, Apttus_Config2__OrderLineItem__c>([
                            SELECT Apttus_Config2__ProductId__r.Name, APTS_ATP_Check_Status__c, 
                            Apttus_Config2__PriceUom__c, Apttus_Config2__Quantity__c, Apttus_Config2__BasePrice__c,APTS_Expected_Delivery_Date__c,
                            Apttus_Config2__NetPrice__c, Apttus_Config2__SellingTerm__c, Apttus_Config2__ShipToAccountId__c,
                            APTS_Plant_Details__c, APTS_Expected_Delivery_Quantity__c, APTS_ATP_cleared__c,Apttus_Config2__OrderId__c 
                            FROM Apttus_Config2__OrderLineItem__c WHERE  Apttus_Config2__OrderId__c = :OrderId]);
     system.debug('size of OrderLIMap :: '+ OrderLIMap .size());                                                  

                List<Apttus_Config2__OrderAdjustmentLineItem__c> adjustmentAllList = [
                            SELECT Apttus_Config2__LineItemId__c, Name
                            FROM Apttus_Config2__OrderAdjustmentLineItem__c
                            WHERE Apttus_Config2__LineItemId__c = :OrderLIMap.keySet()];
system.debug('size of adjustmentAllList :: '+ adjustmentAllList .size()); 
  
                List<Apttus_Config2__OrderTaxBreakup__c> taxAllList = [
                            SELECT Apttus_Config2__OrderLineItemId__c, Name
                            FROM Apttus_Config2__OrderTaxBreakup__c
                            WHERE Apttus_Config2__OrderLineItemId__c = :OrderLIMap.keySet()];
system.debug('size of taxAllList :: '+ taxAllList.size());   

                List<APTS_Order_Freight_Data__c> freightchargeAllList= [
                            SELECT APTS_Order_Line_Item__c, Name
                            FROM APTS_Order_Freight_Data__c
                            WHERE APTS_Order_Line_Item__c= :OrderLIMap.keySet()];
system.debug('size of freightchargeAllList:: '+ freightchargeAllList.size());   
                oOrder = [SELECT APTS_Requested_Delivery_Date__c FROM Apttus_Config2__Order__c WHERE Id = :OrderId LIMIT 1];
                sATPResultMessage = 'ATP is successful';
                              
 Map<Id, List<Apttus_Config2__OrderAdjustmentLineItem__c>> lineItemIdToAdjustmentMap = new Map<Id, List<Apttus_Config2__OrderAdjustmentLineItem__c>>();
                for (Apttus_Config2__OrderAdjustmentLineItem__c oAdjustmentLineItem : adjustmentAllList) {

                    List<Apttus_Config2__OrderAdjustmentLineItem__c> adjustmentList = lineItemIdToAdjustmentMap.get(oAdjustmentLineItem.Apttus_Config2__LineItemId__c);
                    if (adjustmentList == null) {
                        adjustmentList = new List<Apttus_Config2__OrderAdjustmentLineItem__c>();
                        lineItemIdToAdjustmentMap.put(oAdjustmentLineItem.Apttus_Config2__LineItemId__c, adjustmentList);
                    }
                    adjustmentList.add(oAdjustmentLineItem);
                }

                Map<Id, List<Apttus_Config2__OrderTaxBreakup__c>> lineItemIdToTaxMap = new Map<Id, List<Apttus_Config2__OrderTaxBreakup__c>>();
                for (Apttus_Config2__OrderTaxBreakup__c oTax : taxAllList)   {

                    List<Apttus_Config2__OrderTaxBreakup__c> taxList = lineItemIdToTaxMap.get(oTax.Apttus_Config2__OrderLineItemId__c);
                    if (taxList == null) {
                        taxList = new List<Apttus_Config2__OrderTaxBreakup__c>();
                        lineItemIdToTaxMap.put(oTax.Apttus_Config2__OrderLineItemId__c, taxList);
                    }
                    taxList.add(oTax);
                }
                
                Map<Id, List<APTS_Order_Freight_Data__c>> lineItemIdTofreightcharge = new Map<Id, List<APTS_Order_Freight_Data__c>>();
                for (APTS_Order_Freight_Data__c ofreightcharge : freightchargeAllList)   {

                    List<APTS_Order_Freight_Data__c> freightchargeList = lineItemIdTofreightcharge.get(ofreightcharge.APTS_Order_Line_Item__c);
                    if (freightchargeList == null) {
                        freightchargeList = new List<APTS_Order_Freight_Data__c>();
                        lineItemIdTofreightcharge.put(ofreightcharge.APTS_Order_Line_Item__c, freightchargeList);
                    }
                    freightchargeList.add(ofreightcharge);
                }

                productWrapperList = new List<ProductWrapper>();
                for (Apttus_Config2__OrderLineItem__c oOLI : OrderLIMap.values()) {

                    String sATPLineResultMessage = 'ATP OK';
                    if(oOLI.Apttus_Config2__Quantity__c > oOLI.APTS_Expected_Delivery_Quantity__c){
                        sATPLineResultMessage = 'Confirmed quantity less than requested quantity';
                        sATPResultMessage = 'ATP is not successful';
                    }
                    ProductWrapper oProductWrapper = new ProductWrapper(oOLI, lineItemIdToAdjustmentMap.get(oOLI.Id),
                    lineItemIdToTaxMap.get(oOLI.Id), lineItemIdTofreightcharge.get(oOLI.Id), sATPLineResultMessage);
                    productWrapperList.add(oProductWrapper);
                }
                     
                productWrapperList.sort();   
                }            
             } 
                }

/**
    public PageReference doATPCheck() {

        List<Apttus_Config2__LineItem__c> lineItemList = [
                    SELECT APTS_Expected_Delivery_Quantity__c, APTS_ATP_Cleared__c,
                    APTS_Plant_Code__c, Apttus_Config2__Quantity__c, Apttus_Config2__PricingStatus__c,
                    APTS_Requested_Delivery_Date__c
                    FROM Apttus_Config2__LineItem__c
                    WHERE Apttus_Config2__OrderLineItemId__c = :OrderId];

        List<Apttus_Config2__TaxBreakup__c> taxToInsertList = new List<Apttus_Config2__TaxBreakup__c>();
        List<APTS_Order_Freight_Data__c> freightDataToInsertList = new List<APTS_Order_Freight_Data__c>();

        Integer i = 0;
        for (Apttus_Config2__LineItem__c olineItem : lineItemList) {

            if (!olineItem.APTS_ATP_Cleared__c) {
                olineItem.APTS_Expected_Delivery_Date__c = Date.today();
                olineItem.APTS_Expected_Delivery_Quantity__c = ((math.mod(i, 2) == 0) ? olineItem.Apttus_Config2__Quantity__c : olineItem.Apttus_Config2__Quantity__c - 1);
                olineItem.APTS_ATP_Cleared__c = true;
                i++;
                olineItem.APTS_Plant_Code__c = '0001';                

                Apttus_Config2__TaxBreakup__c oTaxBreakup = new Apttus_Config2__TaxBreakup__c();
                oTaxBreakup.Apttus_Config2__Sequence__c = 1;
                oTaxBreakup.Apttus_Config2__TaxAmount__c = 100;
                oTaxBreakup.Apttus_Config2__LineItemId__c = olineItem.Id;
                oTaxBreakup.CurrencyIsoCode = 'EUR';
                taxToInsertList.add(oTaxBreakup);

                APTS_Order_Freight_Data__c oFreightData = new APTS_Order_Freight_Data__c();
                oFreightData.APTS_Sequence__c = 1;
                oFreightData.APTS_Freight_Amount__c = 50;
                oFreightData.APTS_Line_Item__c = olineItem.Id;
                freightDataToInsertList.add(oFreightData); 
                
                oLineItem.APTS_Freight_Charge__c = oFreightData.APTS_Freight_Amount__c;               
            } else {
                olineItem.APTS_Expected_Delivery_Quantity__c = olineItem.Apttus_Config2__Quantity__c;
            }

        }

        List<Date> requestDateList = new List<Date>();

        for (Apttus_Config2__LineItem__c olineItem : lineItemList) {
            requestDateList.add(olineItem.APTS_Requested_Delivery_Date__c);
        }

        Date dRequestedDate;
        if (requestDateList.isEmpty()) {
            dRequestedDate = Date.today();
        } else {
            dRequestedDate = requestDateList.get(0);
        }

        for (Apttus_Config2__LineItem__c olineItem : lineItemList) {
            olineItem.APTS_Requested_Delivery_Date__c = dRequestedDate;
        }

        Database.update(lineItemList);
        Database.insert(taxToInsertList);
        Database.insert(freightDataToInsertList);
        
        return null;
    }

**/

    public class ProductWrapper implements Comparable {

        public Apttus_Config2__OrderLineItem__c oOLI {get; set;}
        public List<Apttus_Config2__OrderAdjustmentLineItem__c> adjustmentList {get; set;}
        public List<Apttus_Config2__OrderTaxBreakup__c> taxList {get; set;}
        public List<APTS_Order_Freight_Data__c> freightChargeList{get; set;}

        public String sATPResultMessage {get; set;}
        public Integer iId;
         public Integer xId;
         public Integer yId;
         public Integer zId;
     

        public ProductWrapper(Apttus_Config2__OrderLineItem__c oOLI , List<Apttus_Config2__OrderAdjustmentLineItem__c> adjustmentList,
        List<Apttus_Config2__OrderTaxBreakup__c> taxList,List<APTS_Order_Freight_Data__c> freightChargeList, String sATPResultMessage) {

            this.oOLI = oOLI;
            this.adjustmentList = adjustmentList;
            this.taxList = taxList;
            this.freightChargeList=freightChargeList;
            this.sATPResultMessage = sATPResultMessage;
            iId = 0;
            xId = 0;
            yId = 0;
            zId = 0;
        }

        public Integer compareTo(Object productWrapper) {
            ProductWrapper compareToPW = (ProductWrapper)productWrapper;
            if (iId == compareToPW.iId) return 0;
            if (iId > compareToPW.iId) return 1;
            return -1;
            }
    }
    
    
    public PageReference back() {

        PageReference pageRef;

        pageRef = new PageReference('/' + OrderId);

        return pageRef;
    }
    
}