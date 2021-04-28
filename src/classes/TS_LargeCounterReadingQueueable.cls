//-------------------------------------------------------------------------------------------//
// Author       :   Abram Vixen Reyes
// Created Date :   May 16, 2019
// Usage        :   Queuable Interface to create counter reading task for every completed large tasks with counter reading
//-------------------------------------------------------------------------------------------//
public with sharing class TS_LargeCounterReadingQueueable implements Queueable,Database.AllowsCallouts{

	public List<WorkOrderLineItem> CR_WOLI_LIST {get; set;}
	public Map<Id, List<WorkOrderLineItem>> WORKORDER_COUNTEREADING_MAP {get; set;}

	public TS_LargeCounterReadingQueueable() {
		
	}

	public void execute(QueueableContext context) {
		CustomLogging.push('execute', 'TS_LargeCounterReadingQueueable');

		List<WorkOrderLineItem> REPARENT_LIST = new List<WorkOrderLineItem>();
        List<WorkOrderLineItem> REPARENT_DELETE_LIST = new List<WorkOrderLineItem>();
        for(WorkOrderLineItem CR_VAR: CR_WOLI_LIST){

            //PROCESS REPARENT OF COUNTER READING RECORDS
            if(WORKORDER_COUNTEREADING_MAP.containsKey(CR_VAR.RelateTo__c)){
                for(WorkOrderLineItem CR_READING_VAR : WORKORDER_COUNTEREADING_MAP.get(CR_VAR.RelateTo__c)){
                    
                    WorkOrderLineItem CR_UPDATE_VAR = CR_READING_VAR.clone();
                    CR_UPDATE_VAR.ParentWorkOrderLineItemId = CR_VAR.Id;
                    CR_UPDATE_VAR.WorkOrderId = CR_VAR.WorkOrderId;

                    REPARENT_LIST.add(CR_UPDATE_VAR);
                    REPARENT_DELETE_LIST.add(CR_READING_VAR);
                }
            }
        }

        if(!REPARENT_LIST.isEmpty()){
            try{
            	delete REPARENT_DELETE_LIST;

	            WorkOrderLineItemTriggerHandler.LARGE_INSERT_MUTE = true;
	            insert REPARENT_LIST;
	            
	        } catch (Exception e){
                System.debug(e);
                CustomLogging.debugException(e);
                CustomLogging.pop();
            }
        }

		CustomLogging.pop();
	}
}