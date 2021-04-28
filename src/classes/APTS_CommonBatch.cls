/************************************************************
Apex Class: 
@Author: Sai Sagar
@CreateDate: 24-05-2018
Description: Common Batch for Data Migration to Invoike Apttus API's 
             like Pricing, Finalize, CER Record Creation, Asset Rollup etc 
       Batch Jobs will be configured in Custom Metadata APTS_Batch_Job__mdt

*************************************************************/
global class APTS_CommonBatch implements Database.Batchable<SObject> {
  
	global String queryString;
	global string country;
	global string secondQuery;
	global String invokingClass;
	global APTS_Batch_Jobs__mdt batchScope;
	global boolean control;
	global APTS_Batch_Job_Execution__c jobExecution;
	global set<String> triggersToDisable = new set<String>();
  
	global APTS_CommonBatch(APTS_Batch_Jobs__mdt currentJobInput, String country) {
	  this.country = country;
	  this.queryString = currentJobInput.APTS_Query__c; 
	  if(country != null && country != '' && this.queryString.contains('<<Country>>')){
		this.queryString = this.queryString.replace('<<Country>>',country);
	  }
	  this.invokingClass = currentJobInput.APTS_Batch_Class_Name__c;
	  this.batchScope = currentJobInput;
	  control = currentJobInput.APTS_Control__c;
		  secondQuery = currentJobInput.Second_Query__c;
	}
	
	/**
	 * @description gets invoked when the batch job starts
	 * @param context contains the job ID
	 * @returns the record set as a QueryLocator object that will be batched for execution
	 */ 
	global Database.QueryLocator start(Database.BatchableContext context) {
	  if(String.isNotBlank(queryString) && batchScope != null && batchScope.id != null) {      
		// LOG Batch Execution with JOB ID
		jobExecution = new APTS_Batch_Job_Execution__c();
		jobExecution.APTS_Batch_Job_Number__c = batchScope.DeveloperName;
		jobExecution.APTS_Batch_Job_Name__c = batchScope.APTS_Batch_Class_Name__c;
		jobExecution.APTS_Job_ID__c  = context.getJobId();
			  jobExecution.APTS_Batch_Size__c = batchScope.APTS_Batch_Size__c;
		jobExecution.APTS_Country__c = country;
		jobExecution.APTS_Status__c = 'Started';
		jobExecution.APTS_Final_Query__c =  queryString;
		jobExecution.APTS_Start_Time__c = System.now();
			  if(secondQuery != null && secondQuery != '')
			  jobExecution.Second_Query__c = secondQuery;
		insert jobExecution;
		triggersToDisable = new set<String>();
		if(batchScope.APTS_Triggers_to_Disable__c !=  null){
		  List<String> tiggerList = batchScope.APTS_Triggers_to_Disable__c.split(',');
		  triggersToDisable.addAll(tiggerList);
		}
		if(APTS_CommonBatch_Helper.modifyTriggers(triggersToDisable,'Deactivate')){        
		  return Database.getQueryLocator(queryString); 
		}
		  return null;          
	  } else { 
		return null;
	  }
	}
  
	/**
	 * @description gets invoked when the batch job executes and operates on one batch of records. Contains or calls the main execution logic for the batch job.
	 * @param context contains the job ID
	 * @param scope contains the batch of records to process.
	 */ 
	global void execute(Database.BatchableContext context, List<sObject> scope ) {
	  // Create an instance of the APTS_CommonBatchHandler class
	  Type batchHandler = Type.forName(invokingClass);
	  APTS_CommonBatchHandler batchProcessHandler = (APTS_CommonBatchHandler) batchHandler.newInstance();  
	  batchProcessHandler.processBatchRecords(context, scope, control );
	}
	
	/**
	 * @description gets invoked when the batch job finishes. Place any clean up code in this method.
	 * @param context contains the job ID
	 */ 
	global void finish(Database.BatchableContext context) {
	  // Update Batch Execution with Results
	  List<APTS_Batch_Job_Execution__c> batchExecutionList = [Select id,APTS_Batch_Job_Number__c from APTS_Batch_Job_Execution__c where APTS_Job_ID__c =: context.getJobId()];
	  if(batchExecutionList.size() > 0) {
		APTS_Batch_Job_Execution__c currentBatch = batchExecutionList[batchExecutionList.size() - 1];
		// Update batch Excution Log
		APTS_CommonBatch_Helper.updateExecutionLog(context.getJobId(), 'Completed', null, null);
  
		Map<String,APTS_Batch_Jobs__mdt> mdtJobMap = new Map<String,APTS_Batch_Jobs__mdt>([select id,DeveloperName,APTS_Query__c,APTS_Control__c,APTS_Triggers_to_Disable__c,APTS_Next_Jobs__c,APTS_Batch_Class_Name__c,Second_Query__c,APTS_Batch_Size__c from APTS_Batch_Jobs__mdt where APTS_Is_Active__c = true ]);
		Map<String,APTS_Batch_Jobs__mdt> jobNameClassMap = new Map<String,APTS_Batch_Jobs__mdt>();
		for(String mdtId: mdtJobMap.keySet()){
		  jobNameClassMap.put(mdtJobMap.get(mdtId).DeveloperName,mdtJobMap.get(mdtId));
		}
		// Check for Next Batch Execution and Execute the Next JOB for the Country
		if(currentBatch.APTS_Batch_Job_Number__c != null && jobNameClassMap.containsKey(currentBatch.APTS_Batch_Job_Number__c) && 
		jobNameClassMap.get(currentBatch.APTS_Batch_Job_Number__c).APTS_Next_Jobs__c != null){
		  list<String> nextJobs = new list<String>();
		  nextJobs = jobNameClassMap.get(currentBatch.APTS_Batch_Job_Number__c).APTS_Next_Jobs__c.split(',');        
		  for(String job: nextJobs){
			if(jobNameClassMap.containsKey(job)){
			integer batchSize = 10;// Set Default to 10
			if(jobNameClassMap.get(job).APTS_Batch_Size__c != null){
			  batchSize = Integer.valueOf(jobNameClassMap.get(job).APTS_Batch_Size__c);
			}
			APTS_CommonBatch batch = new APTS_CommonBatch(jobNameClassMap.get(job),country);
			Database.Executebatch(batch,batchSize);
			}            
		  }
		}
		List<APTS_Batch_Job_Execution__c> batchExecutionInProgressList = [Select id from APTS_Batch_Job_Execution__c where APTS_Status__c = 'Started' OR  APTS_Status__c = 'In Progress' limit 1 ];      
		if(batchExecutionInProgressList.size() == 0){
		  APTS_CommonBatch_Helper.modifyTriggers(triggersToDisable,'Activate'); 
		}
	  }
	}
  
	global class BatchResults{
	  global Integer processedRecords;
	  global Integer totalRecordsFailed;
	  global Integer totalRecords;
	  global Integer totalParentRecords;    
	}
  
  }