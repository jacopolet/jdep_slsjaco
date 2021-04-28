/**
* @author        Marvin Gatchalian
* @date          11.April.2018
* @description   Apex class used to execute Case, WO, WOLI from Disaster Recovery Object records 
* @revision(s)
*/

global with sharing  class TS_DisasterRecoveryBatch implements Database.Batchable<sObject> , Database.Stateful  {
    
    Id caseRecTypeId = TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_DR, Label.TS_Obj_API_Name_Case);
    private List <Id> woliForFixCost = new List <Id>();

    global Database.QueryLocator start(Database.BatchableContext BC) {
        CustomLogging.push('start', 'TS_DisasterRecovery');
        CustomLogging.pop();
        return Database.getQueryLocator(getQuery());
    }
    
    String getQuery () {
        CustomLogging.push('getQuery', 'TS_DisasterRecovery');
        DescribeSObjectResult drRecords = Disaster_Recovery__c.getSObjectType().getDescribe();
        List<String> fields = new List<String>(drRecords.fields.getMap().keySet());
        CustomLogging.pop(); 
        return ' SELECT ' + String.join(fields,',') + 
               ' , Physical_Asset__r.PONumberMachines__c , Physical_Asset__r.Building__c, ' +
               ' Physical_Asset__r.Floor__c, Physical_Asset__r.SmokingArea__c, ' +
               ' Physical_Asset__r.Area__c, Physical_Asset__r.CustomerReferenceNumber__c, ' +
               ' TS_Case_Reference__r.WorkOrderType__c, TS_Case_Reference__r.SLADate__c, ' +
               ' TS_Case_Reference__r.RepeatVisit__c FROM ' + drRecords.getName() + 
               ' WHERE ProcessRecord__c = true AND RecordTypeId = :caseRecTypeId' +
               ' AND Already_Processed__c = false';
    }
    
    global void execute(Database.BatchableContext BC, List<Disaster_Recovery__c> drRecords) {
        CustomLogging.push('Execute', 'TS_DisasterRecovery');
        List <Case> caseToBeInserted = new List <Case>();
        Map <Id, Case> drIdCaseMap = new Map <Id, Case>();
        Map <Id, Case> drIdSuccesfulCaseMap = new Map <Id, Case>();
        
        List <WorkOrder> woToBeInserted = new List <WorkOrder>();
        Map <Id, WorkOrder> drIdWoMap = new Map <Id, WorkOrder>();
        Map <Id, WorkOrder> drIdSuccesfulWoMap = new Map <Id, WorkOrder>();
        
        List <WorkOrderLineItem> woliToBeInserted = new List <WorkOrderLineItem>();
        Map <Id, WorkOrderLineItem> drIdWoliMap = new Map <Id, WorkOrderLineItem>();
        Map <Id, WorkOrderLineItem> drIdSuccesfulWoliMap = new Map <Id, WorkOrderLineItem>();
        
        Set <Id> casesInserted = new Set<Id>();
        Set <Id> wosInserted = new Set<Id>();
        Set <Id> wolisInserted = new Set<Id>();
        Set <Id> caseClosedIds = new Set <Id>();
        
        TS_DisasterRecoveryExecute drExecuter = new TS_DisasterRecoveryExecute();
         
        //Case Creation 
        drIdCaseMap = drExecuter.generateCaseList(drRecords);
        caseToBeInserted = drIdCaseMap.values();
        system.debug('Marvin +++ caseToBeInserted: ' + caseToBeInserted);
        
        if (!caseToBeInserted.isEmpty()) {      
            Database.SaveResult[] srList = Database.insert(caseToBeInserted, false);
            system.debug ('Marvin +++ srList:' + srList);
            for (Case eachCase :[Select Id, TS_Disaster_Recovery_Id__c, OwnerId, PhysicalAsset__c, CreatedDate, Status 
            					 From Case Where Id in :caseToBeInserted]) {
                drIdSuccesfulCaseMap.put(eachCase.TS_Disaster_Recovery_Id__c, eachCase);
                if (eachCase.Status == TS_Constants.STATUS_CLOSED)
                	caseClosedIds.add(eachCase.Id);
            }
        }
       	if (!caseClosedIds.isEmpty()) {
       		DynamicFirstResponseCalculator firstResposeCalc = new DynamicFirstResponseCalculator();
       		firstResposeCalc.calculateMilestoneTriggerTimeBulk(caseClosedIds);
       	}
       	
       	system.debug('Marvin +++ drIdSuccesfulCaseMap: ' + drIdSuccesfulCaseMap);	
        //Work Order Creation
        drIdWoMap = drExecuter.generateWorkOrderList (drIdSuccesfulCaseMap);
        woToBeInserted = drIdWoMap.values();
        
        system.debug('Marvin +++ woToBeInserted: ' + woToBeInserted);
        if (!woToBeInserted.isEmpty()) {
            Database.SaveResult[] srList = Database.insert(woToBeInserted, false);
            for (WorkOrder eachWo : [Select Id, CaseId, Case.TS_Disaster_Recovery_Id__c, Case.OwnerId,
                            			Status, Case.WorkOrderType__c, Case.SLADate__c, Case.RepeatVisit__c 
                         			 From WorkOrder Where Id In :woToBeInserted]) {
            
                drIdSuccesfulWoMap.put(eachWo.Case.TS_Disaster_Recovery_Id__c, eachWo);
            }
        }
        
        //Work Order Line Item Creation
        drIdWoliMap = drExecuter.generateWorkOrderLineItemList (drIdSuccesfulWoMap);
        woliToBeInserted = drIdWoliMap.values();
        
        system.debug('Marvin +++ woliToBeInserted: ' + woliToBeInserted);
        if (!woliToBeInserted.isEmpty()) {
            Database.SaveResult[] srList = Database.insert(woliToBeInserted, false);
            for (WorkOrderLineItem eachWoli : [Select id, Case__c, WorkOrderId, WorkOrderType__c, Case__r.SalesOrganization__c, 
            									Case__r.PhysicalAsset__c, WorkOrder.PriceBook2Id, RecordTypeId,  
            									Case__r.ProductId, PricebookEntryId, PricebookEntry.TS_ProductGroup__c, 
            									Case__r.PhysicalAsset__r.ActiveWarranty__c, 
            									Case__r.Country_Setting_Signature_Record__r.IsLabour__c, 
            									PricebookEntry.Product2.Material_group__c, Case__r.TS_Disaster_Recovery_Id__c,
            									Case__r.PhysicalAsset__r.LabourChargeCoverage__c, Status, 
												Case__r.PhysicalAsset__r.WaterfilterCoverage__c, ServiceMaterialsLoaded__c,
												Case__r.PhysicalAsset__r.CallOutChargeCoverage__c, 
												Case__r.PhysicalAsset__r.SparePartCoverage__c ,
												Case__r.PhysicalAsset__r.FullOperatingCoverage__c, 
												Case__r.PhysicalAsset__r.PreventiveMaintenanceCoverage__c
                                               From WorkOrderLineItem Where Id In :woliToBeInserted]) {
                drIdSuccesfulWoliMap.put(eachWoli.Case__r.TS_Disaster_Recovery_Id__c, eachWoli);
                woliForFixCost.add(eachWoli.Id);
            }
        }

        drExecuter.updateFinalDrRecords(drIdSuccesfulWoliMap); 
		
        CustomLogging.pop();
    }
    
    /******************************************************************************
    * @author         Marvin Gatchalian
    * @date           11.April.2018
    * @description    This method to perform actions when the batch is finished
    * @revision(s)
    ******************************************************************************/ 
    global void finish(Database.BatchableContext BC) {
        CustomLogging.push('finish', 'TS_DisasterRecovery');

		//TS_FlowProcessor.executeFixCostFlow (woliForFixCost);
         
        CustomLogging.pop();
    }
    
    
}