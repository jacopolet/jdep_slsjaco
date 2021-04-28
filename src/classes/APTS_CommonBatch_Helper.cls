public class APTS_CommonBatch_Helper  {

	@testVisible static public Map<String,SObject> MetadataBatchRecordsMap = new Map<String, SObject>();

	public static boolean modifyTriggers(Set<String> setTriggers,String action){
		//Get the list of triggers    
		String tempFields = (setTriggers != null && setTriggers.size() > 0 )? 'Id,':'Id';
		for(String current : setTriggers){
			tempFields += current + ',';
		}
		String fields = tempFields.removeEnd(',');
		//Get trigger configuration
		Id userProfileId;  
		// If the Entry for Current User is in Trigger Settings Assing Current UserId
		if(TriggerSettings__c.getInstance() != null && TriggerSettings__c.getInstance().Id != null){
			userProfileId = TriggerSettings__c.getInstance().SetupOwnerId;
		}    
		if(userProfileId != null  || Test.isRunningTest()){
			String query;
			if(Test.isRunningTest()){
				query = 'SELECT Id FROM TriggerSettings__c LIMIT 1 ';
			}else{
				query = 'SELECT ' + fields + ' FROM TriggerSettings__c WHERE SetupOwnerId = :userProfileId LIMIT 1 ';
			}
			System.debug('Query:-'+query);
			TriggerSettings__c  obj = Database.query(query);
			if(obj != null){
				//Determine action to take on triggers : activate - deactivate
				Boolean value = 'Activate'.equals(action) ? true : false;
				for(String current : setTriggers){
					obj.put(current,value);
				}
				update obj;			
			} 
			return true;
		}else{
			System.debug('JOB NOT STARTED: Create Trigger Setting record for Current User Scope User:'+UserInfo.getName());
			return false;
		}		
	}

	public static APTS_Batch_Error__c createBatchErrorObject(String jobExectionId, String errorDetailMessage , 
																string recordId,String objectName,String errorDescription,String processName){		
		return new APTS_Batch_Error__c(
			Error_Date_Time__c = System.Now(),
			Batch_Job_Execution__c = jobExectionId,
			APTS_Error_Description__c = errorDescription,
			APTS_Error_Level__c = 'Error',
			APTS_Error_Name__c = processName,
			APTS_Parent_ID__c = recordId,
			APTS_Parent_Object_Name__c = objectName,
			APTS_Error_Details_Description__c = errorDetailMessage.length() > 131070 ? errorDetailMessage.substring(0,131070) : errorDetailMessage);
	}

	public static void createBatchErrorLogs(List<APTS_Batch_Error__c> lstErrorLogs){
		insert lstErrorLogs;
	}

	public static void updateExecutionLog(string Id, String Status, integer processedRecords, integer totalRecordsFailed){
    APTS_Batch_Job_Execution__c currentBatch = new  APTS_Batch_Job_Execution__c(); 
    currentBatch.APTS_Job_ID__c = Id;
	List<AsyncApexJob> apexBatchJob = [SELECT Id,ExtendedStatus,JobItemsProcessed,NumberOfErrors FROM AsyncApexJob where Id=:currentBatch.APTS_Job_ID__c];
	if(apexBatchJob.size()>0){
		currentBatch.APTS_Batch_Status__c = apexBatchJob[0].ExtendedStatus;
		currentBatch.APTS_Total_Batch_Failed__c = apexBatchJob[0].NumberOfErrors;
		currentBatch.APTS_Total_Batch_Processed__c = apexBatchJob[0].JobItemsProcessed;
	}
    currentBatch.APTS_Status__c = Status;
    if(Status == 'Completed'){
      currentBatch.APTS_End_Time__c = System.now();
    }
    if(processedRecords != null){
      currentBatch.APTS_Total_Records__c = processedRecords;
    }
    if(totalRecordsFailed != null){
      currentBatch.APTS_Total_Records_Failed__c = totalRecordsFailed;
    }    
    upsert currentBatch APTS_Job_ID__c;
  }

}