/*************************************************************
@Name: APTS_OrderAdjustmentTriggerHandler
@Author: Neev Shah
@CreateDate: 30-07-2018
@Description: Trigger on Order Adjustment Line Item
@TestClass Name: APTS_OrderAdjustmentTriggerHandlerTest
******************************************************************/
//v100 30-07-2018 Neev Shah: Initial version.

public with sharing class APTS_OrderAdjustmentTriggerHandler implements ITriggerHandler {
    private static Boolean isTriggerDisabled = false;

    public APTS_OrderAdjustmentTriggerHandler() {

    }

    //@Description : Method to get executed afterInsert
    public void beforeInsert(List<SObject> newItems) {
        //System.debug('OrderAdjustmentLineItem trigger in beforeInsert');

        //Variable Section
        List<Apttus_Config2__OrderAdjustmentLineItem__c> orderList = NULL;
        Set<Id> setOLI = new Set<Id>();
        //Variable Section

        try {
            orderList = (List<Apttus_Config2__OrderAdjustmentLineItem__c>) newItems;

            //Initial loop
            for (Apttus_Config2__OrderAdjustmentLineItem__c oOrderAdj : orderList) {
                setOLI.add(oOrderAdj.Apttus_Config2__LineItemId__c);
            }
            //system.debug('setOLI = ' + setOLI);

            if (!setOLI.isEmpty()) {
                Map<Id, Apttus_Config2__OrderLineItem__c> mapOLI = new Map<Id, Apttus_Config2__OrderLineItem__c>([SELECT Id, APTS_Returned_Quantity__c, Apttus_Config2__AssetLineItemId__c, Apttus_Config2__AssetLineItemId__r.Apttus_Config2__ListPrice__c FROM Apttus_Config2__OrderLineItem__c WHERE ID = :setOLI]);
                //system.debug('mapOLI = ' + mapOLI);

                if (!mapOLI.isEmpty()) {
                    Decimal tempPrice = 0, assetPrice = 0;

                    for (Apttus_Config2__OrderAdjustmentLineItem__c oOrderAdj : orderList) {
                        tempPrice = 0;
                        assetPrice = 0;
                        Apttus_Config2__OrderLineItem__c oOLI = mapOLI.get(oOrderAdj.Apttus_Config2__LineItemId__c);
                        //system.debug('assetPrice = ' + assetPrice);

                        if (oOLI != NULL && oOLI.Apttus_Config2__AssetLineItemId__c != NULL) {
                            assetPrice = oOLI.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__ListPrice__c;
                            assetPrice = oOLI.APTS_Returned_Quantity__c != NULL ? assetPrice * oOLI.APTS_Returned_Quantity__c : assetPrice;
                            //system.debug('assetPrice = ' + assetPrice);
                            if (oOrderAdj.Apttus_Config2__AdjustmentType__c == '% Discount' && assetPrice != NULL 
                                    && oOrderAdj.Apttus_Config2__AdjustmentAmount__c != NULL && tempPrice != NULL) {
                                    tempPrice = (tempPrice + (assetPrice * (oOrderAdj.Apttus_Config2__AdjustmentAmount__c / 100)));
                                    //system.debug('return price = ' + tempPrice);
                                } else if (oOrderAdj.Apttus_Config2__AdjustmentType__c == 'Discount Amount' 
                                    && oOrderAdj.Apttus_Config2__AdjustmentAmount__c != NULL && tempPrice != NULL) {
                                    tempPrice = (tempPrice + oOrderAdj.Apttus_Config2__AdjustmentAmount__c);
                                    //system.debug('return price = ' + tempPrice);
                                } else if (oOrderAdj.Apttus_Config2__AdjustmentType__c == '% Markup' && assetPrice != NULL 
                                    && oOrderAdj.Apttus_Config2__AdjustmentAmount__c != NULL && tempPrice != NULL) {
                                    tempPrice = (tempPrice - (assetPrice * (oOrderAdj.Apttus_Config2__AdjustmentAmount__c / 100)));
                                    //system.debug('return price = ' + tempPrice);
                                } else if (oOrderAdj.Apttus_Config2__AdjustmentType__c == 'Markup Amount' 
                                    && oOrderAdj.Apttus_Config2__AdjustmentAmount__c != NULL && tempPrice != NULL) {
                                    tempPrice = (tempPrice - oOrderAdj.Apttus_Config2__AdjustmentAmount__c);
                                    //system.debug('return price = ' + tempPrice);
                                } else if (oOrderAdj.Apttus_Config2__AdjustmentType__c == 'Price Override' 
                                    && oOrderAdj.Apttus_Config2__AdjustmentAmount__c != NULL) {
                                    tempPrice = oOrderAdj.Apttus_Config2__AdjustmentAmount__c;
                                    //system.debug('return price = ' + tempPrice);
                                }
                            oOrderAdj.APTS_Return_Adjustment_Price__c = tempPrice * -1;
                            //system.debug('return price = ' + oOrderAdj.APTS_Return_Adjustment_Price__c);
                        }
                    }
                }
            }
        } catch (Exception ex) {
           APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString(),'APTS_OrderAdjustmentTriggerHandler',null, 'OM', false, false, null, true);/*** PI fix #918045****/ 
        }
    }

    //@Description : Method to get executed afterInsert
    public void afterInsert(List<SObject> newList, Map<Id, SObject> newItems) {
        //System.debug('OrderAdjustmentLineItem trigger in afterInsert');
    }

    //@Description : Method to get executed beforeUpdate
    public void beforeUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldItems) {
        //System.debug('OrderAdjustmentLineItem trigger in beforeUpdate');
    }

    //@Description : Method to get executed afterUpdate
    public void afterUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldItems) {
        //System.debug('OrderAdjustmentLineItem trigger in afterUpdate');
    }

    //@Description : Method to get executed beforeDelete
    public void beforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems) {
        //System.debug('OrderAdjustmentLineItem trigger in beforeInsert');
    }

    //@Description : Method to get executed afterDelete
    public void afterDelete(List<SObject> oldList, Map<Id, SObject> oldItems) {
        //System.debug('OrderAdjustmentLineItem trigger in afterDelete');
    }

    //@Description : Method to get executed afterUndelete
    public void afterUndelete(List<SObject> newList, Map<Id, SObject> newItems) {
        //System.debug('OrderAdjustmentLineItem trigger in afterUndelete');
    }

    //@Description : Method to get the isDisabled on OrderTriggerHandler
    public Boolean isDisabled() {
        return isTriggerDisabled;
    }
}