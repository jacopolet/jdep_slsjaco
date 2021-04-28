/************************************************************
Apex Class: APTS_AdjustmentAPIBatchHelper
@Author: Sai Sagar
@CreateDate: Dec 10th 2019
Description: Common Batch helper for Adjustment Load
*************************************************************/   
global with sharing class APTS_AdjustmentAPIBatchHelper implements APTS_CommonBatchHandler {

	global void processBatchRecords(Database.BatchableContext context, List<Apttus_Config2__AdjustmentLineItem__c> listAdjustmentLineItems,boolean control){
    

		// Get Current Batch Execution State
		List<APTS_Batch_Job_Execution__c> currentBatch = [Select id,APTS_Total_Records__c,APTS_Total_Records_Failed__c,Second_Query__c from APTS_Batch_Job_Execution__c where APTS_Job_ID__c =: context.getJobId()];
		integer processedRecords = listAdjustmentLineItems.size();
		processedRecords = currentBatch[currentBatch.size() - 1].APTS_Total_Records__c == null? processedRecords: Integer.valueOf(currentBatch[currentBatch.size() - 1].APTS_Total_Records__c+processedRecords);
		integer totalRecordsFailed =  currentBatch[currentBatch.size() - 1].APTS_Total_Records_Failed__c == null? 0: Integer.valueOf(currentBatch[currentBatch.size() - 1].APTS_Total_Records_Failed__c);
		//Variables declaration
		List<APTS_Batch_Error__c> lstErrorLogs = new List<APTS_Batch_Error__c>(); 


		Map<id,map<Id,List<Apttus_Config2__AdjustmentLineItem__c>>> cartlineItemAdjustmentMap = new Map<Id,map<Id,List<Apttus_Config2__AdjustmentLineItem__c>>>();
		for(Apttus_Config2__AdjustmentLineItem__c adjItem: listAdjustmentLineItems){	
			if(adjItem.Apttus_Config2__LineItemId__r.Apttus_Config2__ConfigurationId__c != null && cartlineItemAdjustmentMap.containskey(adjItem.Apttus_Config2__LineItemId__r.Apttus_Config2__ConfigurationId__c)){
				if(cartlineItemAdjustmentMap.get(adjItem.Apttus_Config2__LineItemId__r.Apttus_Config2__ConfigurationId__c) != null && 
					cartlineItemAdjustmentMap.get(adjItem.Apttus_Config2__LineItemId__r.Apttus_Config2__ConfigurationId__c).containskey(adjItem.Apttus_Config2__LineItemId__c)){
					cartlineItemAdjustmentMap.get(adjItem.Apttus_Config2__LineItemId__r.Apttus_Config2__ConfigurationId__c).get(adjItem.Apttus_Config2__LineItemId__c).add(adjItem);
				}else{
					cartlineItemAdjustmentMap.get(adjItem.Apttus_Config2__LineItemId__r.Apttus_Config2__ConfigurationId__c).put(adjItem.Apttus_Config2__LineItemId__c,new list<Apttus_Config2__AdjustmentLineItem__c>{adjItem});
				}
			}else{
				cartlineItemAdjustmentMap.put(adjItem.Apttus_Config2__LineItemId__r.Apttus_Config2__ConfigurationId__c, new map<Id,List<Apttus_Config2__AdjustmentLineItem__c>>{adjItem.Apttus_Config2__LineItemId__c => new list<Apttus_Config2__AdjustmentLineItem__c>{adjItem} });	
			}
		}

		for(Id cartId: cartlineItemAdjustmentMap.keyset()){
			try{
				Apttus_CPQApi.CPQ.UpdateManualAdjustmentsRequestDO request = new  Apttus_CPQApi.CPQ.UpdateManualAdjustmentsRequestDO();
				request.CartId = cartId;
				List<Apttus_CPQApi.CPQ.AdjustmentItemCollDO> lineItemAdjustments = new List<Apttus_CPQApi.CPQ.AdjustmentItemCollDO>();
				for(Id lineItemId:  cartlineItemAdjustmentMap.get(cartId).keyset()){
					Apttus_CPQApi.CPQ.AdjustmentItemCollDO adjItemColl = new Apttus_CPQApi.CPQ.AdjustmentItemCollDO(); 
					adjItemColl.LineItemId = lineItemId;
					adjItemColl.AdjustmentItems = APTS_DiscountBucketizing.processAdjustmentLineItemfields(cartlineItemAdjustmentMap.get(cartId).get(lineItemId));
					lineItemAdjustments.add(adjItemColl);
				}	
				request.AdjustmentItemColls = lineItemAdjustments;
				system.debug('@@@---'+request);
				Apttus_CPQApi.CPQ.UpdateManualAdjustmentsResponseDO result =  Apttus_CPQApi.CPQWebService.updateManualAdjustmentsForCart(request);
			}catch(Exception e){
				totalRecordsFailed = totalRecordsFailed+1;
				system.debug(Logginglevel.ERROR,'Exception on Adjust Load Batch:::::' + e.getMessage() + '<>' +  e.getStackTraceString());        
				lstErrorLogs.add(APTS_CommonBatch_Helper.createBatchErrorObject(currentBatch[0].Id, e.getMessage() + '<>' +  e.getStackTraceString(), cartId, 'Apttus_Config2__ProductConfiguration__c', 'Error Occured During Parallel Batch Processing', 'APTS_AdjustmentAPIBatchHelper'));			
			}
		}
		//Log errors
		if(lstErrorLogs.size() > 0){
			APTS_CommonBatch_Helper.createBatchErrorLogs(lstErrorLogs);        
		}      
    
		if(currentBatch.size() > 0){                  
			APTS_CommonBatch_Helper.updateExecutionLog(context.getJobId(),'In Progress',processedRecords,totalRecordsFailed );
		}    
	}
}