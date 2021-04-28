/**
* Class Name : APTS_OrderUsagePriceTierTriggerHandler
* Description : Populate From and To as per the assets so it doesnt get override
* Author : Karan Khatri
* Date Created : 10-08-2019
**/
public with sharing class APTS_OrderUsagePriceTierTriggerHandler implements ITriggerHandler{

    
    
    public void BeforeInsert(List<Apttus_Config2__OrderUsagePriceTier__c> newItems){
       List<Apttus_Config2__OrderUsagePriceTier__c> oliTierList = new List<Apttus_Config2__OrderUsagePriceTier__c>();
        Set<Id> oliIdList = new Set<Id>();
        Map<Id,id> assetIdMap = new Map<Id,id>();
        Map<Id,Decimal> usageRateFVMap = new Map<Id,Decimal>();
        Map<Id,Decimal> usageRatePaidMap = new Map<Id,Decimal>();
        Map<Id,Decimal> unitPriceFVMap = new Map<Id,Decimal>();
        Map<Id,Decimal> unitPricePaidMap = new Map<Id,Decimal>();
        Map<String,Apttus_Config2__AssetUsagePriceTier__c> assetUsageTierMap = new Map<String,Apttus_Config2__AssetUsagePriceTier__c>();
        For(Apttus_Config2__OrderUsagePriceTier__c oupt : newItems){
            oliIdList.add(oupt.Apttus_Config2__OrderLineItemId__c);
        }
        System.debug('oliIdList====>'+oliIdList);
        if(!oliIdList.isEmpty()){
            For(Apttus_Config2__OrderLineItem__c orderlineitem : [select id,
            Apttus_Config2__AssetLineItemId__c,
            Apttus_Config2__OrderId__r.APTS_Order_Type__c,
            Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c,
            Apttus_Config2__DerivedFromId__c,
            Apttus_Config2__DerivedFromId__r.Apttus_Config2__AttributeValueId__c,
            Apttus_Config2__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Base_Price_Override_per_cup__c,
            Apttus_Config2__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_List_Price_per_cup__c,
            Apttus_Config2__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Base_Price_Override_per_cup_FV__c,
            Apttus_Config2__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_List_Price_per_cup_FV__c,
            Apttus_Config2__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Type_of_Consumption__c 
            from Apttus_Config2__OrderLineItem__c where id IN: oliIdList]){
                if(orderlineitem.Apttus_Config2__OrderId__r.APTS_Order_Type__c.equalsIgnoreCase(APTS_OrderConstants.ADMIN_ORDER) && !orderlineitem.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c.equalsIgnoreCase(APTS_BIRUtils.ORDERSUBTYPE)){
                    if(assetIdMap.get(orderlineitem.id)==null){
                        assetIdMap.put(orderlineitem.id,orderlineitem.Apttus_Config2__AssetLineItemId__c);
                    }
                    System.debug('***BU***orderlineitem.orderlineitem.Apttus_Config2__DerivedFromId__r.Apttus_Config2__AttributeValueId__r====>'+orderlineitem.Apttus_Config2__DerivedFromId__r.Apttus_Config2__AttributeValueId__c);
                    System.debug('***BU***Type of consumption====>'+orderlineitem.Apttus_Config2__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Type_of_Consumption__c);
                    
                    if(orderlineitem.Apttus_Config2__DerivedFromId__r.Apttus_Config2__AttributeValueId__c!=null && orderlineitem.Apttus_Config2__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Type_of_Consumption__c!=null){
                        if(usageRateFVMap.get(orderlineitem.id)==null && orderlineitem.Apttus_Config2__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Type_of_Consumption__c.equalsIgnoreCase('Free Vend')){
                            if(orderlineitem.Apttus_Config2__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Base_Price_Override_per_cup_FV__c!=null){
                                usageRateFVMap.put(orderlineitem.id,orderlineitem.Apttus_Config2__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Base_Price_Override_per_cup_FV__c);
                            }else{
                                usageRateFVMap.put(orderlineitem.id,orderlineitem.Apttus_Config2__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_List_Price_per_cup_FV__c);
                            }
                            unitPriceFVMap.put(orderlineitem.id,orderlineitem.Apttus_Config2__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_List_Price_per_cup_FV__c);
                        }else if(usageRatePaidMap.get(orderlineitem.id)==null && orderlineitem.Apttus_Config2__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Type_of_Consumption__c.equalsIgnoreCase('Paid')){
                            if(orderlineitem.Apttus_Config2__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Base_Price_Override_per_cup__c!=null){
                                usageRatePaidMap.put(orderlineitem.id,orderlineitem.Apttus_Config2__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Base_Price_Override_per_cup__c);
                            }else{
                                usageRatePaidMap.put(orderlineitem.id,orderlineitem.Apttus_Config2__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_List_Price_per_cup__c);
                            }
                            unitPricePaidMap.put(orderlineitem.id,orderlineitem.Apttus_Config2__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_List_Price_per_cup__c);
                        }
                        else{
                            if(usageRateFVMap.get(orderlineitem.id)==null){
                                if(orderlineitem.Apttus_Config2__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Base_Price_Override_per_cup_FV__c!=null){
                                    usageRateFVMap.put(orderlineitem.id,orderlineitem.Apttus_Config2__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Base_Price_Override_per_cup_FV__c);
                                }else{
                                    usageRateFVMap.put(orderlineitem.id,orderlineitem.Apttus_Config2__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_List_Price_per_cup_FV__c);
                                }
                                unitPriceFVMap.put(orderlineitem.id,orderlineitem.Apttus_Config2__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_List_Price_per_cup_FV__c);
                            }
                            if(usageRatePaidMap.get(orderlineitem.id)==null){
                                if(orderlineitem.Apttus_Config2__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Base_Price_Override_per_cup__c!=null){
                                    usageRatePaidMap.put(orderlineitem.id,orderlineitem.Apttus_Config2__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Base_Price_Override_per_cup__c);
                                }else{
                                    usageRatePaidMap.put(orderlineitem.id,orderlineitem.Apttus_Config2__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_List_Price_per_cup__c);
                                }
                                unitPricePaidMap.put(orderlineitem.id,orderlineitem.Apttus_Config2__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_List_Price_per_cup__c);
                            }
                        }
                    }
                }
            }
        }
        System.debug('assetIdMap====>'+assetIdMap);
         if(!assetIdMap.isEmpty()){
            For(Apttus_Config2__AssetUsagePriceTier__c assetUsageTier : [select id,Apttus_Config2__TierStartValue__c, Apttus_Config2__TierEndValue__c,Apttus_Config2__Dimension1Value__c,Apttus_Config2__AssetLineItemId__c from Apttus_Config2__AssetUsagePriceTier__c where Apttus_Config2__AssetLineItemId__c IN: assetIdMap.values()]){
                System.debug('assetUsageTier====>'+assetUsageTier);
                if(assetUsageTier.Apttus_Config2__Dimension1Value__c!=null && assetUsageTier.Apttus_Config2__AssetLineItemId__c!=null && assetUsageTierMap.get(assetUsageTier.Apttus_Config2__Dimension1Value__c+assetUsageTier.Apttus_Config2__AssetLineItemId__c)==null){
                    assetUsageTierMap.put(assetUsageTier.Apttus_Config2__Dimension1Value__c+assetUsageTier.Apttus_Config2__AssetLineItemId__c,assetUsageTier);
                }
            }
        }
        System.debug('usageRatePaidMap====>'+usageRatePaidMap);
        System.debug('assetUsageTierMap====>'+assetUsageTierMap);
        System.debug('usageRateFVMap====>'+usageRateFVMap);
        if(!assetUsageTierMap.isEmpty() && !assetIdMap.isEmpty()){
            For(Apttus_Config2__OrderUsagePriceTier__c oupt : newItems){    
                
                if(oupt.Apttus_Config2__Dimension1Value__c!=null && assetIdMap.get(oupt.Apttus_Config2__OrderLineItemId__c)!=null && assetUsageTierMap.get(oupt.Apttus_Config2__Dimension1Value__c+assetIdMap.get(oupt.Apttus_Config2__OrderLineItemId__c))!=null){
                    oupt.Apttus_Config2__TierStartValue__c=assetUsageTierMap.get(oupt.Apttus_Config2__Dimension1Value__c+assetIdMap.get(oupt.Apttus_Config2__OrderLineItemId__c)).Apttus_Config2__TierStartValue__c;
                    oupt.Apttus_Config2__TierEndValue__c=assetUsageTierMap.get(oupt.Apttus_Config2__Dimension1Value__c+assetIdMap.get(oupt.Apttus_Config2__OrderLineItemId__c)).Apttus_Config2__TierEndValue__c;
                    if(oupt.Apttus_Config2__Dimension1Value__c.equalsIgnoreCase('Free Vend') && !usageRateFVMap.isEmpty() && usageRateFVMap.get(oupt.Apttus_Config2__OrderLineItemId__c)!=null && !unitPriceFVMap.isEmpty() && unitPriceFVMap.get(oupt.Apttus_Config2__OrderLineItemId__c)!=null){
                        oupt.Apttus_Config2__AdjustmentAmount__c = usageRateFVMap.get(oupt.Apttus_Config2__OrderLineItemId__c);
                        oupt.Apttus_Config2__UsageRate__c = unitPriceFVMap.get(oupt.Apttus_Config2__OrderLineItemId__c);
                    }
                    if(oupt.Apttus_Config2__Dimension1Value__c.equalsIgnoreCase('Paid') && !usageRatePaidMap.isEmpty() && usageRatePaidMap.get(oupt.Apttus_Config2__OrderLineItemId__c)!=null && !unitPricePaidMap.isEmpty() && unitPricePaidMap.get(oupt.Apttus_Config2__OrderLineItemId__c)!=null){
                        oupt.Apttus_Config2__AdjustmentAmount__c = usageRatePaidMap.get(oupt.Apttus_Config2__OrderLineItemId__c);
                        oupt.Apttus_Config2__UsageRate__c = unitPricePaidMap.get(oupt.Apttus_Config2__OrderLineItemId__c);
                    }
                }
            }
        }
    }
    public void BeforeUpdate(List<Apttus_Config2__OrderUsagePriceTier__c> newItems, Map<Id, SObject> newItemsMap, List<SObject> oldList, Map<Id, SObject> oldItemsMap){
       
    }
    public void BeforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems){
    
    }
    public void AfterInsert(List<Apttus_Config2__OrderUsagePriceTier__c> newItems, Map<Id, SObject> newItemsMap){
        
    }
    
    public void AfterUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldItems){}
 
    public void AfterDelete(List<SObject> oldList, Map<Id, SObject> oldItems){}
 
    public void AfterUndelete(List<SObject> newList, Map<Id, SObject> newItems){}
    
    public Boolean IsDisabled(){
        return (TriggerSettings__c.getInstance().APTS_OrderUsagePriceTierTrigger__c == true ? false : true);
    }
}