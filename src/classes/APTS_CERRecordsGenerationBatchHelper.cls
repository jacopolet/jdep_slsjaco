public with Sharing class APTS_CERRecordsGenerationBatchHelper  implements  APTS_CommonBatchHandler  {

	public void processBatchRecords(Database.BatchableContext context, List<Apttus__APTS_Agreement__c> agreementList, boolean control){

		APTS_CommonBatch.BatchResults results = new APTS_CommonBatch.BatchResults(); 
		List<APTS_Batch_Job_Execution__c> currentBatch = [Select id,APTS_Total_Records__c,APTS_Total_Records_Failed__c from APTS_Batch_Job_Execution__c where APTS_Job_ID__c =: context.getJobId()];
		integer processedRecords = agreementList.size();
		results.processedRecords = currentBatch[currentBatch.size() - 1].APTS_Total_Records__c == null? processedRecords: Integer.valueOf(currentBatch[currentBatch.size() - 1].APTS_Total_Records__c+processedRecords);
		results.totalRecordsFailed =  currentBatch[currentBatch.size() - 1].APTS_Total_Records_Failed__c == null? 0: Integer.valueOf(currentBatch[currentBatch.size() - 1].APTS_Total_Records_Failed__c);

		//Variables declaration
		List<APTS_Batch_Error__c> lstErrorLogs = new List<APTS_Batch_Error__c>();
		List<Apttus__APTS_Agreement__c> lstAgreementsToUpdate = new List<Apttus__APTS_Agreement__c>();
		try{
			if(control){
				APTS_ManageCER.manageCERRecords(agreementList,APTS_ManageCER.BATCH,'Update');
			}else{
				APTS_ManageCER.manageCERRecords(agreementList,System.label.APTS_DMCERParam,'Update');
			}			
		}catch(Exception e){
			results.totalRecordsFailed = results.totalRecordsFailed+agreementList.size();					
			lstErrorLogs.add(APTS_CommonBatch_Helper.createBatchErrorObject(currentBatch[0].Id,e.getMessage() + '<>' +  e.getStackTraceString(), 'Batch Set of Agreements', 'Apttus__APTS_Agreement__c','Error Occured During Parallel Batch Processing:  CER records batch creation error', 'APTS_CERRecordsGenerationBatchHelper'));	
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