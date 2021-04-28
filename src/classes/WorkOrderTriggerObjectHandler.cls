/**
* @author        Paul Jarred Aguiling
* @date          01.10.2018           
* @description   Class responsible for the trigger business logic of Work Order Trigger Object
* @revision(s)   2.28.2018 Paul Aguiling KTS-1489 Added assignWOTRecordType
*/
public with sharing class WorkOrderTriggerObjectHandler implements ITriggerHandler {
    public static Boolean isTriggerDisabled = true;
    public static Boolean hasException = false;
    public static Boolean fromSalesTrigger = false;

    /**
    * @author         Paul Jarred Aguiling
    * @date           01.10.2018
    * @description    Method responsible for throwing an exception
    * @revision(s)
    */ 
    public class TS_WorkOrderTriggerObjHandlerException extends Exception {}
    
    public void BeforeInsert(List<SObject> newItems) {
        CustomLogging.push('BeforeInsert', 'WorkOrderTriggerObjectHandler');

        try {

            //tickPotentialRoundTrip(newItems);
            //assignWOTRecordType(newItems, null);

            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_WorkOrderTriggerObjHandlerException('Force to throw an exception');
            }

        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }

        CustomLogging.pop(); 
    }
    
    public void BeforeUpdate(List<SObject> newList, Map<Id, SObject> newMapItems, List<SObject> oldList, Map<Id, SObject> oldMapItems) {
        CustomLogging.push('BeforeUpdate', 'WorkOrderTriggerObjectHandler');

        try {

            //tickPotentialRoundTrip(newList);
            //assignWOTRecordType(newList, oldMapItems);

            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_WorkOrderTriggerObjHandlerException('Force to throw an exception');
            }

        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }

        CustomLogging.pop(); 
    }
    
    public void BeforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems) {
        
    }
    
    public void AfterInsert(List<SObject> newList, Map<Id, SObject> newMapItems) {
        CustomLogging.push('AfterInsert', 'WorkOrderTriggerObjectHandler');

        try {

            updateParentHeader(newList);
            invokeSalesTriggerController(newList, null);
            //updateforDeinstallation(newList); XEN REYES May 20, 2019

            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_WorkOrderTriggerObjHandlerException('Force to throw an exception');
            }

        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }

        CustomLogging.pop(); 
    }
    
    public void AfterUpdate(List<SObject> newList , Map<Id, SObject> newMapItems, List<SObject> oldList, Map<Id, SObject> oldMapItems){
        CustomLogging.push('AfterUpdate', 'WorkOrderTriggerObjectHandler');

        try {

            invokeSalesTriggerController(newList, oldMapItems);
			
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_WorkOrderTriggerObjHandlerException('Force to throw an exception');
            }

        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }

        CustomLogging.pop();
    }
    
    public void AfterDelete(List<SObject> oldList, Map<Id, SObject> oldMapItems) {
        
    }
    
    public void AfterUndelete(List<SObject> newList, Map<Id, SObject> newMapItems) {
        
    }
    
    public Boolean IsDisabled() {
        if (TriggerSettings__c.getInstance().WorkOrderTriggerObject__c) {
            return false;
        } else {
            return isTriggerDisabled;
        }
    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          01.10.2018          
    * @description   KTS-1489: assign record type upon WOT creation and update 
    * @revision(s)
    */
    /*public void assignWOTRecordType(List<SObject> newList, Map<Id, SObject> oldMapItems) {
        CustomLogging.push('assignWOTRecordType', 'CaseTriggerHandler');

        //Insert Scenario
        if (oldMapItems == null) {
            for (WorkOrderTrigger__c wotRec: (List<WorkOrderTrigger__c>) newList) {
                //Record type = Header
                if (Label.TS_WOTType_Header.equals(wotRec.Type__c)) {
                    wotRec.RecordTypeId = TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_WorkOrderTrigger, Label.TS_WOTType_Header);
                //Record type = Line Item
                } else if (Label.TS_WOTType_LineItem.equals(wotRec.Type__c)) {
                    wotRec.RecordTypeId = TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_WorkOrderTrigger, Label.TS_WOTType_LineItem);
                //Record type = Option
                } else if (Label.TS_WOTType_Option.equals(wotRec.Type__c)) {
                    wotRec.RecordTypeId = TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_WorkOrderTrigger, Label.TS_WOTType_Option);
                }
            }
        //Update Scenario
        } else {
            for (WorkOrderTrigger__c wotRec: (List<WorkOrderTrigger__c>) newList) {
                WorkOrderTrigger__c oldwotRec = (WorkOrderTrigger__c) oldMapItems.get(wotRec.Id);

                if (wotRec.Type__c != oldwotRec.Type__c) {
                    //Record type = Header
                    if (Label.TS_WOTType_Header.equals(wotRec.Type__c)) {
                        wotRec.RecordTypeId = TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_WorkOrderTrigger, Label.TS_WOTType_Header);
                    //Record type = Line Item
                    } else if (Label.TS_WOTType_LineItem.equals(wotRec.Type__c)) {
                        wotRec.RecordTypeId = TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_WorkOrderTrigger, Label.TS_WOTType_LineItem);
                    //Record type = Option
                    } else if (Label.TS_WOTType_Option.equals(wotRec.Type__c)) {
                        wotRec.RecordTypeId = TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_WorkOrderTrigger, Label.TS_WOTType_Option);
                    }
                }
            }
        }

        CustomLogging.pop();
    }*/

    /**
    * @author        Paul Jarred Aguiling
    * @date          01.10.2018          
    * @description   KTS 99 - Sales Triggered Cases (Installation Conversion). 
    *                Method used to relate WOT line items to WOT parent header record
    * @revision(s)
    */
    public void updateParentHeader(List<SObject> newList) {
        CustomLogging.push('updateParentHeader', 'TS_SalesTriggerController'); 
        Map<Id, List<WorkOrderTrigger__c>> lineItemMap = new Map<Id, List<WorkOrderTrigger__c>>();
        List<WorkOrderTrigger__c> headerList = new List<WorkOrderTrigger__c>();
        Set<Id> parentOrderIds = new Set<Id>();
        List<WorkOrderTrigger__c> wotListToUpdate = new List<WorkOrderTrigger__c>();

        //Collect WOT parent order and child order record Ids
        for (WorkOrderTrigger__c wotRec: (List<WorkOrderTrigger__c>) newList) {
            if (Label.TS_WOTType_Header.equals(wotRec.Type__c) && wotRec.GenerateServiceOrder__c) {
                if (wotRec.ChildOrder__c != null) {
                    parentOrderIds.add(wotRec.ChildOrder__c);
                }

                parentOrderIds.add(wotRec.ParentOrder__c);
                headerList.add(wotRec);
            }
        }

        //Check if header record are added on the list
        if (!parentOrderIds.isEmpty()) {
            //Retrieve work order triggers based on parent order ids executed from the platform event (Work Order Trigger Event)
            List<WorkOrderTrigger__c> workOrderTriggerList = [SELECT Id, Type__c, ParentOrder__c
                                                              FROM WorkOrderTrigger__c 
                                                              WHERE ParentOrder__c IN :parentOrderIds];

            //Iterate WOT records and group them per parent order with the format of 1 header record has option and line item records 
            for (WorkOrderTrigger__c wotRec: workOrderTriggerList) {

                //Get all line item record type
                if (Label.TS_WOTType_LineItem.equals(wotRec.Type__c)) {

                    //Group line item per parent order
                    if (lineItemMap.containsKey(wotRec.ParentOrder__c)) {
                        lineItemMap.get(wotRec.ParentOrder__c).add(wotRec);
                    } else {
                        lineItemMap.put(wotRec.ParentOrder__c, new List<WorkOrderTrigger__c>{wotRec});
                    }
                }
            }

            //Iterate header to map the right line items then stamp WOT Header Id to WOT Line Items ParentHeader__c field
            for (WorkOrderTrigger__c wotRec: headerList) {

                //Check for the parent order of the WOT header
                for (WorkOrderTrigger__c wotRecParent: lineItemMap.get(wotRec.ParentOrder__c)) {
                    WorkOrderTrigger__c wotNew = new WorkOrderTrigger__c();
                    wotNew.Id = wotRecParent.Id;
                    wotNew.ParentHeader__c = wotRec.Id;                        
                    wotListToUpdate.add(wotNew);
                }

                //Check for child order records of the WOT header
                if (wotRec.ChildOrder__c != null) {
                    for (WorkOrderTrigger__c wotRecChild: lineItemMap.get(wotRec.ChildOrder__c)) {
                        WorkOrderTrigger__c wotChild = new WorkOrderTrigger__c();
                        wotChild.Id = wotRecChild.Id;
                        wotChild.ParentHeader__c = wotRec.Id;
                        wotListToUpdate.add(wotChild);
                    }
                }
            }

            //Update WOT line item records
            if (!wotListToUpdate.isEmpty() && Schema.sObjectType.WorkOrderTrigger__c.isUpdateable()) {
                update wotListToUpdate;
            }
        }

        CustomLogging.pop();
    }


    /**
    * @author        Paul Jarred Aguiling
    * @date          01.10.2018          
    * @description   KTS 99 - Sales Triggered Cases (Installation Conversion). 
    *                Method used to execute the Sales Trigger Requirement
    * @revision(s)
    */
    private void invokeSalesTriggerController(List<SObject> newList, Map<Id, SObject> oldMapItems) {
        CustomLogging.push('invokeSalesTriggerController', 'WorkOrderTriggerObjectHandler');
        List<SObject> eventList = new List<SObject>();
        List<Id> parentOrderIdList = new List<Id>();

        //Execute sales trigger upon CREATION
        if (oldMapItems == null) {
            for (WorkOrderTrigger__c wotRec: (List<WorkOrderTrigger__c>) newList) {
                if (Label.TS_WOTType_Header.equals(wotRec.Type__c) && wotRec.GenerateServiceOrder__c) {
                    //WorkOrderTriggerEvent__e wotEvent = new WorkOrderTriggerEvent__e();
                    //wotEvent.WOTParentOrderID__c = String.valueOf(wotRec.ParentOrder__c);
                    //wotEvent.WOTChildOrderID__c = wotRec.ChildOrder__c != null || wotRec.ChildOrder__c != ''? String.valueOf(wotRec.ChildOrder__c) : null;
                    //eventList.add(wotEvent);

                    parentOrderIdList.add(Id.valueOf(wotRec.ParentOrder__c));

                    if (wotRec.ChildOrder__c != null) {
                       parentOrderIdList.add(Id.valueOf(wotRec.ChildOrder__c));
                    }
                }
            }
        //Execute sales trigger upon UPDATE
        } else {
            for (WorkOrderTrigger__c wotRec: (List<WorkOrderTrigger__c>) newList) {
                WorkOrderTrigger__c oldWOT = (WorkOrderTrigger__c) oldMapItems.get(wotRec.Id);

                if (Label.TS_WOTType_Header.equals(wotRec.Type__c) && oldWOT.GenerateServiceOrder__c != wotRec.GenerateServiceOrder__c
                        && wotRec.GenerateServiceOrder__c) {
                    /* WorkOrderTriggerEvent__e wotEvent = new WorkOrderTriggerEvent__e();
                    wotEvent.WOTParentOrderID__c = String.valueOf(wotRec.ParentOrder__c);
                    wotEvent.WOTChildOrderID__c = wotRec.ChildOrder__c != null || wotRec.ChildOrder__c != ''? String.valueOf(wotRec.ChildOrder__c) : null;
                    eventList.add(wotEvent) */
                            
                    parentOrderIdList.add(Id.valueOf(wotRec.ParentOrder__c));

                    if (wotRec.ChildOrder__c != null) {
                       parentOrderIdList.add(Id.valueOf(wotRec.ChildOrder__c));
                    }
                }
            }
        }

        //if (!eventList.isEmpty()) {
             //EventBus.publish(eventList);
        if (!parentOrderIdList.isEmpty()) {
            //TS_SalesTriggerController ts = new TS_SalesTriggerController();
            //ts.getWorkOrderTriggerRecords(parentOrderIdList);
            //EventBus.publish(eventList);
            //insert eventList;
        
            //QUEUEABLE
            TS_AsyncExecutionSalesTrigger queueableSalesTrigger = new TS_AsyncExecutionSalesTrigger();
            queueableSalesTrigger.parentOrderIdList = parentOrderIdList;
            System.enqueueJob(queueableSalesTrigger);
        }

        CustomLogging.pop(); 
    }
    
    /**
    * @author        Adrian Reyes
    * @date          02.05.2018          
    * @description   Method used to tick Potential Round-Trip depending on the order type
    * @revision(s)
    */
    /*private void tickPotentialRoundTrip(List<SObject> newList) {
        CustomLogging.push('tickPotentialRoundTrip', 'WorkOrderTriggerObjectHandler');
        
        List<WorkOrderTrigger__c> workOrderTriggers = (List<WorkOrderTrigger__c>) newList;
        Set<Id> orderIDs = new Set<Id>();
        for(WorkOrderTrigger__c workOrderTrigger: workOrderTriggers){
            if(workOrderTrigger.Type__c == Label.TS_WOTType_Header){
                if(workOrderTrigger.OrderType__c == Label.TS_Order_Instype_Installation || workOrderTrigger.OrderType__c == Label.TS_Case_SubType_Swap)
                    orderIDs.add(workOrderTrigger.ParentOrder__c);
                else if(workOrderTrigger.OrderType__c == Label.TS_Order_Instype_DeInstallation)
                    workOrderTrigger.PotentialRoundTrip__c = true;
                else
                    workOrderTrigger.PotentialRoundTrip__c = false;
            }
        }
        
        Set<String> countryRoundTripSettings = new Set<String>();
        for(CountrySetting__c countrySetting: [SELECT Country__c, Product__c FROM CountrySetting__c WHERE RecordType.DeveloperName = 'CountryRoundTripSettings' AND Active__c = true]){
            countryRoundTripSettings.add(countrySetting.Country__c + '-' + countrySetting.Product__c);
        }
        
        Map<Id,Apttus_Config2__Order__c> orderMap = new Map<Id,Apttus_Config2__Order__c>([SELECT (SELECT Type__c, Stopover__c, OrderType__c, OrderSubType__c, Product__c FROM WorkOrderTriggers__r) FROM Apttus_Config2__Order__c WHERE Id IN: orderIDs]);
        for(WorkOrderTrigger__c workOrderTrigger: workOrderTriggers){
            if(workOrderTrigger.Type__c == Label.TS_WOTType_Header){
                if(workOrderTrigger.OrderType__c == Label.TS_Order_Instype_Installation || workOrderTrigger.OrderType__c == Label.TS_Case_SubType_Swap){
                    if(orderMap.containsKey(workOrderTrigger.ParentOrder__c)){
                        Apttus_Config2__Order__c order = orderMap.get(workOrderTrigger.ParentOrder__c);
                        Boolean isStopOver = false;
                        for(WorkOrderTrigger__c relatedWorkOrderTrigger: order.WorkOrderTriggers__r){
                            if(relatedWorkOrderTrigger.Type__c == Label.TS_WOTType_LineItem && relatedWorkOrderTrigger.Stopover__c && (relatedWorkOrderTrigger.OrderType__c == Label.TS_Order_Instype_Installation || (relatedWorkOrderTrigger.OrderType__c == Label.TS_Case_SubType_Swap && relatedWorkOrderTrigger.OrderSubType__c == Label.TS_Order_Instype_Installation))){
                                isStopOver = true;
                                break;
                            }
                        }
                        
                        if(!isStopOver){
                            Boolean potentialRoundTrip = true;
                            for(WorkOrderTrigger__c relatedWorkOrderTrigger: order.WorkOrderTriggers__r){
                                if(relatedWorkOrderTrigger.Type__c == Label.TS_WOTType_LineItem || relatedWorkOrderTrigger.Type__c == Label.TS_WOTType_Option){
                                    if(!countryRoundTripSettings.contains(workOrderTrigger.SalesOrganization__c + '-' + relatedWorkOrderTrigger.Product__c)){
                                        potentialRoundTrip = false;
                                        break;
                                    }
                                }
                            }
                            workOrderTrigger.PotentialRoundTrip__c = potentialRoundTrip;
                        }
                    }
                }
            }
        }
        
        CustomLogging.pop();
    }*/
    /**
    * @author         Karen Hung
    * @date           24.09.2018
    * @description    Method responsible for updating fields for deinstallation
    * @revision(s)
    */    
    /* private void updateforDeinstallation(List<SObject> newList){
        CustomLogging.push('updateforDeinstallation', 'WorkOrderTriggerObjectHandler');
        
        List<WorkOrderTrigger__c> workOrderTriggers = (List<WorkOrderTrigger__c>) newList;
        List<PhysicalAsset__c> assetForUpdateList = new List<PhysicalAsset__c>();
        List<Apttus_Config2__OrderLineItem__c> oliForUpdateList = new List<Apttus_Config2__OrderLineItem__c>();
        Map<Id,Product2> woProductMap = new Map<Id,Product2>();
        Map<Id,Product2> prodIdMap = new Map<Id,Product2>();
        Set<Id> productIdSet = new Set<Id>();
        
        Map<Id,PhysicalAsset__c> woAssetMap = new Map<Id,PhysicalAsset__c>();
        Map<Id,PhysicalAsset__c> assetIdMap = new Map<Id,PhysicalAsset__c>();
        Set<Id> assetIdSet = new Set<Id>();
        
        Map<Id,Apttus_Config2__OrderLineItem__c> wOliMap = new Map<Id,Apttus_Config2__OrderLineItem__c>();
        Map<Id,Apttus_Config2__OrderLineItem__c> oliIdMap = new Map<Id,Apttus_Config2__OrderLineItem__c>();
        Set<Id> oliIdSet = new Set<Id>();

        //Karen Hung Apr 11, 2019 KTS-2680 ALM-6641 map of oli to be updated
        Map<Id,Apttus_Config2__OrderLineItem__c> oliForUpdateMap = new Map<Id,Apttus_Config2__OrderLineItem__c>();
        Map<Id,PhysicalAsset__c> assetForUpdateMap = new Map<Id,PhysicalAsset__c>(); //Karen Hung Apr 26, 2019 KTS-2703 ALM 6985
               
        for(WorkOrderTrigger__c wot : workOrderTriggers){
            if(wot.Product__c != null){
                productIdSet.add(wot.Product__c);
            }
            if(wot.PhysicalAsset__c != null){
                assetIdSet.add(wot.PhysicalAsset__c);
            }
            if(wot.OrderLineItem__c != null){
                oliIdSet.add(wot.OrderLineItem__c);
            }
        }
        if(!productIdSet.isEmpty()){
            prodIdMap = new Map<Id,Product2>([SELECT Id, APTS_Technician_Not_Required__c FROM Product2 WHERE Id IN: productIdSet]);
            if(!assetIdSet.isEmpty()){
                assetIdMap = new Map<Id,PhysicalAsset__c>([SELECT Id, DeInstallationDate__c,AssetStatus__c FROM PhysicalAsset__c WHERE Id IN: assetIdSet]);
            }
            if(!oliIdSet.isEmpty()){
                oliIdMap = new Map<Id,Apttus_Config2__OrderLineItem__c>([SELECT Id, APTS_De_installation_Date_Authorized__c FROM Apttus_Config2__OrderLineItem__c WHERE Id IN: oliIdSet]);
            }
            if(!prodIdMap.isEmpty()){
                for(WorkOrderTrigger__c woTrigger : (List<WorkOrderTrigger__c>) newList){
                    if(prodIdMap.containsKey(woTrigger.Product__c)){
                        woProductMap.put(woTrigger.Id, prodIdMap.get(woTrigger.Product__c));
                    }
                    if(assetIdMap.containsKey(woTrigger.PhysicalAsset__c)){
                        woAssetMap.put(woTrigger.id, assetIdMap.get(woTrigger.PhysicalAsset__c));
                    }
                    if(oliIdMap.containsKey(woTrigger.OrderLineItem__c)){
                        wOliMap.put(woTrigger.id,oliIdMap.get(woTrigger.OrderLineItem__c));
                    }
                    Id lineItemId = Schema.SObjectType.WorkOrderTrigger__c.getRecordTypeInfosByName().get(TS_Constants.TS_WOT_RECORDTYPE_LINEITEM).getRecordTypeId();
                    if(woProductMap.containsKey(woTrigger.Id)){ //KAREN HUNG 11.12.2018 KTS-2399
                        if(woProductMap.get(woTrigger.Id).APTS_Technician_Not_Required__c == true && woTrigger.RecordTypeId == lineItemId){ //if delivery only and rectype is line item             	
                            //if order type is de-installation or swap with de-installation
                            if(woTrigger.OrderType__c == TS_Constants.ORDER_INSTYPE_DEINSTALLATION || (woTrigger.OrderType__c == TS_Constants.CASE_SUBTYPE_SWAP && woTrigger.OrderSubType__c == TS_Constants.ORDER_INSTYPE_DEINSTALLATION)){
                                //update physical asset's de-installation date and status
                                if(woAssetMap.containsKey(woTrigger.id)){
                                    PhysicalAsset__c pa =  woAssetMap.get(woTrigger.id);
                                    pa.DeInstallationDate__c = Date.today();
                                    pa.AssetStatus__c = Label.TS_Order_Cancelled; //Cancelled
                                    assetForUpdateList.add(pa);
                                }
                             	//update order line item with de-installation authorized
                                if(wOliMap.containsKey(woTrigger.Id)){
                                    Apttus_Config2__OrderLineItem__c oli = wOliMap.get(woTrigger.Id);
                                    oli.APTS_De_installation_Date_Authorized__c = date.today();
                                    oliForUpdateList.add(oli);
                                }
                            }
                            //if order type is installation or swap with installation
                            if(woTrigger.OrderType__c == TS_Constants.ORDER_INSTYPE_INSTALLATION ||(woTrigger.OrderType__c == TS_Constants.CASE_SUBTYPE_SWAP && woTrigger.OrderSubType__c == TS_Constants.ORDER_INSTYPE_INSTALLATION)){
                                if(wOliMap.containsKey(woTrigger.Id)){
                                    Apttus_Config2__OrderLineItem__c oli = wOliMap.get(woTrigger.Id);
                                    oli.APTS_Installation_Date_Authorized__c = system.now();
                                    oliForUpdateList.add(oli);
                                }                            
                            }
                        }
                    }
                }
            }

            //Karen Hung Apr 26, 2019 KTS-2703 ALM 6985
            assetForUpdateMap.putAll(assetForUpdateList);
            
            if(Schema.sObjectType.PhysicalAsset__c.isUpdateable() && assetForUpdateMap.size() > 0){
                List<PhysicalAsset__c> paList = TS_PhysicalAssetDataRemover.removeOperationalDataFieldValues(assetForUpdateMap.values());
                database.update(paList);
            }

            //Karen Hung Apr 11, 2019 KTS-2680 ALM-6641 put all list in the map to prevent duplicate error
            oliForUpdateMap.putAll(oliForUpdateList);

            if(Schema.sObjectType.Apttus_Config2__OrderLineItem__c.isUpdateable() && oliForUpdateMap.size() > 0){
                database.update(oliForUpdateMap.values()); //Karen Hung Apr 11, 2019 KTS-2680 ALM-6641 changed list to map 
            }
        }

        
        CustomLogging.pop();        
    } */    
}