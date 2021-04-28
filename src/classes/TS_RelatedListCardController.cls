public with sharing class TS_RelatedListCardController {

	@AuraEnabled
	public static List<sObject> returnRecs(String caseId, String status, String woliType, Boolean isStandardTask, Boolean isRouteSalesTask, Boolean isCounterReading, Boolean isOperating, Boolean isRouteOperating){
		CustomLogging.push('returnRecs', 'TS_RelatedListCardController');
		List<sObject> queriedRecs = new List<sObject>();
        Id recType;

		/* Schema.SObjectType objType = Schema.getGlobalDescribe().get('WorkOrderLineItem');
		Map<String, Schema.SObjectField> schemaFieldMap = objType.getDescribe().fields.getMap(); */

		if(caseId != NULL){
            try{

                if(isRouteSalesTask){
                    recType = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Routesales Task').getRecordTypeId();
                } else if (isStandardTask){
                    recType = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Register Task').getRecordTypeId();
                } else if(isCounterReading){
                    recType = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Counter Reading Task').getRecordTypeId();
                } else if(isOperating || isRouteOperating){
                    recType = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Operating Task').getRecordTypeId();
                }

                List<String> schedStatus = new List<String>{'Scheduled','Dispatched', 'Received', 'Travelling', 'On Site','Start Work'};
                
            	if(status == 'Scheduled'){
                    
                    if(isRouteSalesTask || isStandardTask){
                        queriedRecs = [SELECT Id, SalesOrderCreated__c, EndDate__c, AccountLocation__r.Name, AccountLocation__c, TaskDueDate__c, Quantity, LineItemNumber, SLADate__c, StartDate__c, WorkOrderLineItemNumber__c, ExecutingEngineer__c, ExecutingEngineer__r.Name, JDELineItemNumber__c, toLabel(WorkOrderType__c), WorkOrderLineItemType__c, PhysicalAsset__c, PhysicalAsset__r.Name, PricebookEntryId, PricebookEntry.Name, Status, ParentWorkOrderLineItemId, ParentWorkOrderLineItem.WorkOrderLineItemNumber__c, Sequence_Number__c, ProductDescription__c, SendCounterReadingsOperating__c FROM WorkOrderLineItem WHERE Case__c =: caseId AND RecordTypeId =: recType AND Status IN: schedStatus AND ExecutingEngineer__c != null];
                    } else if (isCounterReading || isOperating) {
                        queriedRecs = [SELECT Id, SalesOrderCreated__c, EndDate__c, AccountLocation__r.Name, AccountLocation__c, TaskDueDate__c, Quantity, LineItemNumber, SLADate__c, StartDate__c, WorkOrderLineItemNumber__c, ExecutingEngineer__c, ExecutingEngineer__r.Name, JDELineItemNumber__c, toLabel(WorkOrderType__c), WorkOrderLineItemType__c, PhysicalAsset__c, PhysicalAsset__r.Name, PricebookEntryId, PricebookEntry.Name, Status, ParentWorkOrderLineItemId, ParentWorkOrderLineItem.WorkOrderLineItemNumber__c, Sequence_Number__c, ProductDescription__c, SendCounterReadingsOperating__c  FROM WorkOrderLineItem WHERE WorkOrderId =: caseId AND RecordTypeId =: recType AND Status IN: schedStatus AND ExecutingEngineer__c != null];
                    } else if (isRouteOperating){
                        queriedRecs = [SELECT Id, SalesOrderCreated__c, EndDate__c, AccountLocation__r.Name, AccountLocation__c, TaskDueDate__c, Quantity, LineItemNumber, SLADate__c, StartDate__c, WorkOrderLineItemNumber__c, ExecutingEngineer__c, ExecutingEngineer__r.Name, JDELineItemNumber__c, toLabel(WorkOrderType__c), WorkOrderLineItemType__c, PhysicalAsset__c, PhysicalAsset__r.Name, PricebookEntryId, PricebookEntry.Name, Status, ParentWorkOrderLineItemId, ParentWorkOrderLineItem.WorkOrderLineItemNumber__c, Sequence_Number__c, ProductDescription__c, SendCounterReadingsOperating__c FROM WorkOrderLineItem WHERE WorkOrderId =: caseId AND RecordTypeId =: recType AND Status IN: schedStatus AND ExecutingEngineer__c != null ORDER BY Sequence_Number__c ASC NULLS LAST];
                    }

                } else {

                    if(status == 'Open'){
                        if(isRouteSalesTask || isStandardTask){
                            queriedRecs = [SELECT Id, SalesOrderCreated__c, EndDate__c, AccountLocation__r.Name, AccountLocation__c, TaskDueDate__c, Quantity, LineItemNumber, SLADate__c, StartDate__c, WorkOrderLineItemNumber__c, ExecutingEngineer__c, ExecutingEngineer__r.Name, JDELineItemNumber__c, toLabel(WorkOrderType__c), WorkOrderLineItemType__c, PhysicalAsset__c, PhysicalAsset__r.Name, PricebookEntryId, PricebookEntry.Name, Status, ParentWorkOrderLineItemId, ParentWorkOrderLineItem.WorkOrderLineItemNumber__c, Sequence_Number__c, ProductDescription__c, SendCounterReadingsOperating__c FROM WorkOrderLineItem WHERE Case__c =: caseId AND RecordTypeId =: recType AND (Status =: status OR (Status IN: schedStatus AND ExecutingEngineer__c = null))];
                        } else if (isCounterReading || isOperating) {
                             queriedRecs = [SELECT Id, SalesOrderCreated__c, EndDate__c, AccountLocation__r.Name, AccountLocation__c, TaskDueDate__c, Quantity, LineItemNumber, SLADate__c, StartDate__c, WorkOrderLineItemNumber__c, ExecutingEngineer__c, ExecutingEngineer__r.Name, JDELineItemNumber__c, toLabel(WorkOrderType__c), WorkOrderLineItemType__c, PhysicalAsset__c, PhysicalAsset__r.Name, PricebookEntryId, PricebookEntry.Name, Status, ParentWorkOrderLineItemId, ParentWorkOrderLineItem.WorkOrderLineItemNumber__c, Sequence_Number__c, ProductDescription__c, SendCounterReadingsOperating__c FROM WorkOrderLineItem WHERE WorkOrderId =: caseId AND RecordTypeId =: recType AND (Status =: status OR (Status IN: schedStatus AND ExecutingEngineer__c = null))];
                        }  else if (isRouteOperating) {
                             queriedRecs = [SELECT Id, SalesOrderCreated__c, EndDate__c, AccountLocation__r.Name, AccountLocation__c, TaskDueDate__c, Quantity, LineItemNumber, SLADate__c, StartDate__c, WorkOrderLineItemNumber__c, ExecutingEngineer__c, ExecutingEngineer__r.Name, JDELineItemNumber__c, toLabel(WorkOrderType__c), WorkOrderLineItemType__c, PhysicalAsset__c, PhysicalAsset__r.Name, PricebookEntryId, PricebookEntry.Name, Status, ParentWorkOrderLineItemId, ParentWorkOrderLineItem.WorkOrderLineItemNumber__c, Sequence_Number__c, ProductDescription__c, SendCounterReadingsOperating__c FROM WorkOrderLineItem WHERE WorkOrderId =: caseId AND RecordTypeId =: recType AND (Status =: status OR (Status IN: schedStatus AND ExecutingEngineer__c = null)) ORDER BY Sequence_Number__c ASC NULLS LAST];
                        }

                    } else {
                        if(isRouteSalesTask || isStandardTask){
                            queriedRecs = [SELECT Id, SalesOrderCreated__c, EndDate__c, AccountLocation__r.Name, AccountLocation__c, TaskDueDate__c, Quantity, LineItemNumber, SLADate__c, StartDate__c, WorkOrderLineItemNumber__c, ExecutingEngineer__c, ExecutingEngineer__r.Name, JDELineItemNumber__c, toLabel(WorkOrderType__c), WorkOrderLineItemType__c, PhysicalAsset__c, PhysicalAsset__r.Name, PricebookEntryId, PricebookEntry.Name, Status, ParentWorkOrderLineItemId, ParentWorkOrderLineItem.WorkOrderLineItemNumber__c, Sequence_Number__c, ProductDescription__c, SendCounterReadingsOperating__c FROM WorkOrderLineItem WHERE Case__c =: caseId AND RecordTypeId =: recType AND Status =: status];
                        } else if (isCounterReading || isOperating) {
                             queriedRecs = [SELECT Id, SalesOrderCreated__c, EndDate__c, AccountLocation__r.Name, AccountLocation__c, TaskDueDate__c, Quantity, LineItemNumber, SLADate__c, StartDate__c, WorkOrderLineItemNumber__c, ExecutingEngineer__c, ExecutingEngineer__r.Name, JDELineItemNumber__c, toLabel(WorkOrderType__c), WorkOrderLineItemType__c, PhysicalAsset__c, PhysicalAsset__r.Name, PricebookEntryId, PricebookEntry.Name, Status,ParentWorkOrderLineItemId, ParentWorkOrderLineItem.WorkOrderLineItemNumber__c, Sequence_Number__c, ProductDescription__c, SendCounterReadingsOperating__c FROM WorkOrderLineItem WHERE WorkOrderId =: caseId AND Status =: status];
                             //ALM 6243 XEN REYES March 26, 2019 Removed the ff: RecordTypeId =: recType AND
                        } else if (isRouteOperating) {
                             queriedRecs = [SELECT Id, SalesOrderCreated__c, EndDate__c, AccountLocation__r.Name, AccountLocation__c, TaskDueDate__c, Quantity, LineItemNumber, SLADate__c, StartDate__c, WorkOrderLineItemNumber__c, ExecutingEngineer__c, ExecutingEngineer__r.Name, JDELineItemNumber__c, toLabel(WorkOrderType__c), WorkOrderLineItemType__c, PhysicalAsset__c, PhysicalAsset__r.Name, PricebookEntryId, PricebookEntry.Name, Status,ParentWorkOrderLineItemId, ParentWorkOrderLineItem.WorkOrderLineItemNumber__c, Sequence_Number__c, ProductDescription__c, SendCounterReadingsOperating__c FROM WorkOrderLineItem WHERE WorkOrderId =: caseId AND Status =: status ORDER BY StartDate__c ASC NULLS LAST];
                        }
                    }
                    

                }

            } catch(exception e){
                System.debug(e.getMessage());
            }
        }
		CustomLogging.pop();
		return queriedRecs;
	}

	@AuraEnabled
	public static List<sObject> getParts(String caseId, String woliType, Boolean isWOLI, String woliId){
		CustomLogging.push('getParts', 'TS_RelatedListCardController');
		List<sObject> queriedRecs = new List<sObject>();
		if(caseId != NULL && !isWOLI){
            try{
           		queriedRecs = [SELECT Id, DirectToCustomer__c, MissingReason__c, SparePartCost__c, Discount, toLabel(Warranty__c), Quantity, LineItemNumber, SLADate__c, StartDate__c, WorkOrderLineItemNumber__c, ExecutingEngineer__c, ExecutingEngineer__r.Name, JDELineItemNumber__c, toLabel(WorkOrderType__c), WorkOrderLineItemType__c, PhysicalAsset__c, PhysicalAsset__r.Name, PricebookEntryId, PricebookEntry.Name, Status, ParentWorkOrderLineItemId, ParentWorkOrderLineItem.WorkOrderLineItemNumber__c FROM WorkOrderLineItem WHERE Case__c =: caseId AND IsReadyToSummarize__c = false AND WorkOrderLineItemType__c =: woliType];
            } catch(exception e){
                System.debug(e.getMessage());
            }
        } else if(woliId != NULL && isWOLI){
            try{
                queriedRecs = [SELECT Id, DirectToCustomer__c, MissingReason__c, SparePartCost__c, Discount, toLabel(Warranty__c), Quantity, LineItemNumber, SLADate__c, StartDate__c, WorkOrderLineItemNumber__c, ExecutingEngineer__c, ExecutingEngineer__r.Name, JDELineItemNumber__c, toLabel(WorkOrderType__c), WorkOrderLineItemType__c, PhysicalAsset__c, PhysicalAsset__r.Name, PricebookEntryId, PricebookEntry.Name, Status, ParentWorkOrderLineItemId, ParentWorkOrderLineItem.WorkOrderLineItemNumber__c, OP_UniquecounterID__c, OP_CounterSequence__c, OP_ConsumptionGroup__c FROM WorkOrderLineItem WHERE ParentWorkOrderLineItemId =: woliId AND IsReadyToSummarize__c = false AND WorkOrderLineItemType__c =: woliType];
            } catch(exception e){
                System.debug(e.getMessage());
            }
        }
		CustomLogging.pop();
		return queriedRecs;
	}
}