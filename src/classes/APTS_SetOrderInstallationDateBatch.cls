/*************************************************************
@Name: APTS_SetOrderInstallationDateBatch
@Author: Galin Georgiev
@CreateDate: 27-08-2018
@Description: APTS_SetOrderInstallationDateBatch
@UsedBy:
******************************************************************/
//v100 27-08-2018 Galin Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes

global class APTS_SetOrderInstallationDateBatch implements Database.Batchable<sObject>, Database.Stateful {

    private String query;
    private List<Apttus_Config2__OrderLineItem__c> orderLineItemToUpdateList = new List<Apttus_Config2__OrderLineItem__c>();
    private List<Apttus_Config2__OrderLineItem__c> optionOLIToUpdateList = new List<Apttus_Config2__OrderLineItem__c>();
    global APTS_SetOrderInstallationDateBatch() {

        query = 'SELECT Id, APTS_Installation_Date_Authorized__c, APTS_De_installation_Date_Authorized__c, Apttus_Config2__LineNumber__c, Apttus_Config2__IsPrimaryLine__c, Apttus_Config2__ActivatedDate__c, Apttus_Config2__OrderId__c, Apttus_Config2__StartDate__c, Apttus_Config2__EndDate__c, Apttus_Config2__SellingTerm__c ' +
                'FROM Apttus_Config2__OrderLineItem__c ' +
                'WHERE (APTS_Installation_Date_Authorized__c != null OR APTS_De_installation_Date_Authorized__c != null) AND Apttus_Config2__Status__c = \'Fulfilled\' LIMIT 50';
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Apttus_Config2__OrderLineItem__c> scope) {
         Set<Id> orderIdSet = new Set<Id>();
        Set<Decimal> lineNumberSet = new Set<Decimal>();
        Map<Id, Apttus_Config2__OrderLineItem__c> idToOLIL1Map = new Map<Id, Apttus_Config2__OrderLineItem__c>();

        for (Apttus_Config2__OrderLineItem__c oOrderLineItem : scope) {

            if (!oOrderLineItem.Apttus_Config2__IsPrimaryLine__c) {
                orderIdSet.add(oOrderLineItem.Apttus_Config2__OrderId__c);
                lineNumberSet.add(oOrderLineItem.Apttus_Config2__LineNumber__c);
                idToOLIL1Map.put(oOrderLineItem.Id, oOrderLineItem);
            } else {
                oOrderLineItem.Apttus_Config2__ActivatedDate__c = oOrderLineItem.APTS_Installation_Date_Authorized__c != null ? oOrderLineItem.APTS_Installation_Date_Authorized__c : oOrderLineItem.APTS_De_installation_Date_Authorized__c;
                oOrderLineItem.Apttus_Config2__ReadyForBillingDate__c = oOrderLineItem.APTS_De_installation_Date_Authorized__c == null ? oOrderLineItem.Apttus_Config2__ActivatedDate__c : null;
                oOrderLineItem.Apttus_Config2__StartDate__c = oOrderLineItem.Apttus_Config2__ActivatedDate__c.date();
                oOrderLineItem.Apttus_Config2__EndDate__c= oOrderLineItem.Apttus_Config2__StartDate__c.addMonths(Integer.ValueOf(oOrderLineItem.Apttus_Config2__SellingTerm__c));
                orderLineItemToUpdateList.add(oOrderLineItem);
            }
        }

        if (!idToOLIL1Map.isEmpty()) {
            //5-Sep-2018 Modified the below logic to recalculate the the Order Line Item Start date same as Installation date and calculate the end date based on the selling term
            Map<Id, Apttus_Config2__OrderLineItem__c> bundleIdToOrderLineItemMap = new Map<Id, Apttus_Config2__OrderLineItem__c>([
                        SELECT Id, Apttus_Config2__LineNumber__c, Apttus_Config2__IsPrimaryLine__c, Apttus_Config2__OrderId__c,
                        APTS_Installation_Date_Authorized__c, Apttus_Config2__ActivatedDate__c, Apttus_Config2__StartDate__c, Apttus_Config2__EndDate__c, Apttus_Config2__SellingTerm__c, Apttus_Config2__HasOptions__c
                        FROM Apttus_Config2__OrderLineItem__c
                        WHERE Apttus_Config2__LineNumber__c IN :lineNumberSet AND Apttus_Config2__OrderId__c IN :orderIdSet]);
            
            for (Apttus_Config2__OrderLineItem__c oOrderLineItemL1 : idToOLIL1Map.values()) {
                DateTime installDate = oOrderLineItemL1.APTS_Installation_Date_Authorized__c != null ? oOrderLineItemL1.APTS_Installation_Date_Authorized__c : oOrderLineItemL1.APTS_De_installation_Date_Authorized__c;
                
                for (Apttus_Config2__OrderLineItem__c oOrderLineItemTmp : bundleIdToOrderLineItemMap.values()) {
                Boolean bSameLineNumber = oOrderLineItemL1.Apttus_Config2__LineNumber__c == oOrderLineItemTmp.Apttus_Config2__LineNumber__c;
                Boolean bSameOrder = oOrderLineItemL1.Apttus_Config2__OrderId__c == oOrderLineItemTmp.Apttus_Config2__OrderId__c;

                if (bSameLineNumber && bSameOrder)
                {
                    if(oOrderLineItemTmp.Apttus_Config2__IsPrimaryLine__c && oOrderLineItemTmp.Apttus_Config2__HasOptions__c)
                     {
                        oOrderLineItemTmp.Apttus_Config2__ActivatedDate__c = installDate;
                        oOrderLineItemTmp.Apttus_Config2__ReadyForBillingDate__c = oOrderLineItemTmp.APTS_De_installation_Date_Authorized__c == null ? oOrderLineItemTmp.Apttus_Config2__ActivatedDate__c : null;
                        oOrderLineItemTmp.Apttus_Config2__StartDate__c = installDate.date();
                        oOrderLineItemTmp.Apttus_Config2__EndDate__c = oOrderLineItemTmp.Apttus_Config2__StartDate__c.addMonths(Integer.ValueOf(oOrderLineItemTmp.Apttus_Config2__SellingTerm__c));
                        orderLineItemToUpdateList.add(oOrderLineItemTmp);
                    }
                    else
                    {
                        oOrderLineItemTmp.Apttus_Config2__StartDate__c = installDate.date();
                        oOrderLineItemTmp.Apttus_Config2__EndDate__c = oOrderLineItemTmp.Apttus_Config2__StartDate__c.addMonths(Integer.ValueOf(oOrderLineItemTmp.Apttus_Config2__SellingTerm__c));
                        optionOLIToUpdateList.add(oOrderLineItemTmp);
                    }
                }
                
                }
            }
        }
        if(!optionOLIToUpdateList.isEmpty())
        {
            Database.update(optionOLIToUpdateList, false);
        }

        System.enqueueJob(new APTS_ActivateOrderQueueable(orderLineItemToUpdateList));
    }

    global void finish(Database.BatchableContext BC) {

    }
}