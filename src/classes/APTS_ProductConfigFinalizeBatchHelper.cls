/************************************************************
Apex Class: APTS_ProductConfigFinalizeBatchHelper
@Author: Sai Sagar
@CreateDate: 24-05-2018
Description: Batch helper for Finalizaing Carts
Test Class: APTS_CommonBatch_Helper_Tests 
*************************************************************/
public with sharing class APTS_ProductConfigFinalizeBatchHelper implements  APTS_CommonBatchHandler {
	
	// Interface Method to Process the Batch Records
	public void  processBatchRecords(Database.BatchableContext context, List<Apttus_Config2__ProductConfiguration__c> cartList,boolean control){
		System.debug('****************'+control);
		APTS_CommonBatch.BatchResults results = new APTS_CommonBatch.BatchResults(); 
		List<APTS_Batch_Job_Execution__c> currentBatch = [Select id,APTS_Total_Records__c,APTS_Total_Records_Failed__c from APTS_Batch_Job_Execution__c where APTS_Job_ID__c =: context.getJobId()];
		integer processedRecords = cartList.size();
		results.processedRecords = currentBatch[currentBatch.size() - 1].APTS_Total_Records__c == null? processedRecords: Integer.valueOf(currentBatch[currentBatch.size() - 1].APTS_Total_Records__c+processedRecords);
		results.totalRecordsFailed =  currentBatch[currentBatch.size() - 1].APTS_Total_Records_Failed__c == null? 0: Integer.valueOf(currentBatch[currentBatch.size() - 1].APTS_Total_Records_Failed__c);

		List<APTS_Batch_Error__c> lstErrorLogs = new List<APTS_Batch_Error__c>();
		Set<Id> agreementsIdSet = new Set<Id>();
		if(currentBatch.size() > 0){
			for(Apttus_Config2__ProductConfiguration__c currentConfig : cartList){
				try{			
					Apttus_CpqApi.CPQ.FinalizeCartRequestDO request = new Apttus_CpqApi.CPQ.FinalizeCartRequestDO();
					request.CartId = currentConfig.Id;
					Apttus_CpqApi.CPQ.FinalizeCartResponseDO response = Apttus_CpqApi.CPQWebService.finalizeCart(request);
					// Agreement Ids to Activate 
					agreementsIdSet.add(currentConfig.Apttus_CMConfig__AgreementId__c);
				}Catch(Exception e){
					results.totalRecordsFailed = results.totalRecordsFailed+1;
					String errorMessage = e.getMessage() + '<>' +  e.getStackTraceString();
					lstErrorLogs.add(APTS_CommonBatch_Helper.createBatchErrorObject( currentBatch[0].Id, errorMessage, currentConfig.Id, 'Apttus_Config2__ProductConfiguration__c', 'Error Occured During Parallel Batch Processing Apttus Finalize API Exception ', 'APTS_ProductConfigFinalizeBatchHelper'));	
				}
			}
		}
		//Log errors
		if(lstErrorLogs.size() > 0){
			APTS_CommonBatch_Helper.createBatchErrorLogs(lstErrorLogs);
		}
		
		if(currentBatch.size() > 0){									
			APTS_CommonBatch_Helper.updateExecutionLog(context.getJobId(),'In Progress',results.processedRecords,results.totalRecordsFailed );
		}			      
	}

}