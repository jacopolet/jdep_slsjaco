/*
* @author        Marvin Gatchalian
* @date          3.23.2018          
* @description   Class responsible for updating related case. Please use this class for related case only. 
* 			     Do not execute DML operation here, just return the list of case to be updated. The calling
*				 class should be the one to performed the dml.	 
* @revision(s)   
*/

public without sharing class TS_UpdateRelatedCase {
	
	Id tsWOLIRecordType = TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_WOLI, Label.TS_WOLI_RecordType_RegTask);
	public static List<Contact> relatedContactList = new List<Contact>();
	public static List<Workorderlineitem> filteredWolilist = new List<Workorderlineitem>();
	
	public List<Case> actionsForInsertedWoli (List<SObject> newList, Map<Id, SObject> newMapItems) {
		List<Case> caseListToReturn = new List<Case>();
		
		caseListToReturn = woliStatusCompletedAndOpenCount (newList);
		return caseListToReturn;
	}
	
	// Should add action for change of status to Canceled to replace the whole TS_Cancel Case Based On WOLI process builder
	public List<Case> actionsForUpdatedWoli (List<SObject> newList, Map<Id, SObject> oldMapItems) {
		List<Case> caseListToReturn = new List<Case>();
		Set<Id> caseIds = new Set<Id>();
		List<WorkOrderLineItem> filteredWoli = new List<WorkOrderLineItem>();
		
		try {
			for(WorkOrderLineItem woli : (List<WorkOrderLineItem>) newList){
				WorkOrderLineItem oldWoli = (WorkOrderLineItem) oldMapItems.get(woli.id);
				if(woli.RecordTypeId == tsWOLIRecordType && woli.WorkOrderLineItemType__c == 'Task' &&
				  ((woli.Status != oldWoli.Status && woli.Status != TS_Constants.STATUS_CANCELED) || woli.Status == TS_Constants.STATUS_CANCELED) ) { //Karen Hung 8.7.2020 DOO-4620 TO Accommodate canceled tasks for TS_Cancel Case Based On WOLI process builder
	               //woli.Status != oldWoli.Status && woli.Status != TS_Constants.STATUS_CANCELED) {
	            	
	            	filteredWoli.add(woli);
	            }
	           
	        }

	        caseListToReturn = woliStatusCompletedAndOpenCount(filteredWoli);
        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }

		return  caseListToReturn;
	}
	
	public List<Case> actionsForDeletedWoli (List<SObject> oldList, Map<Id, SObject> oldMapItems) {
		List<Case> caseListToReturn = new List<Case>();
		caseListToReturn = woliStatusCompletedAndOpenCount (oldList);
		return  caseListToReturn;
	}
	
	
	private List<Case> woliStatusCompletedAndOpenCount (List<SObject> recordList) {
		CustomLogging.push('woliStatusCompletedAndOpenCount', 'TS_UpdateRelatedCase');
		Map<id, List<WorkOrderLineItem>> caseIdWoliListMap = new Map<id, List<WorkOrderLineItem>>();
		List<Case> caseListToReturn = new List<Case>();
		Set<Id> caseIds = new Set<Id>();
		String CONST_WOLI_CHILD_CR_RT = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Counter Reading').getRecordTypeId();
		 
		Map<Id, Case> caseMapforBI = new Map<Id, Case>(); //Karen Hung DOO-4662
		
		for(WorkOrderLineItem woli : (List<WorkOrderLineItem>) recordList){
			//filter out for operating task, counter reading, route sales
			Boolean isOperatingTask = woli.RecordtypeId.equals(CONST_WOLI_CHILD_CR_RT)|| Label.TS_Activity_Type_S20.equals(woli.WorkOrderType__c) ||Label.TS_Activity_Type_S21.equals(woli.WorkOrderType__c)||Label.TS_Activity_Type_S22.equals(woli.WorkOrderType__c ) ;            
        	//Boolean isRouteSalesTask =Label.TS_Activity_Type_S25.equals(woli.WorkOrderType__c)  ;   
            if(!(isOperatingTask) && woli.RecordTypeId == tsWOLIRecordType && woli.WorkOrderLineItemType__c == 'Task') {
				caseIds.add(woli.Case__c);
			}
        }
        
		if (!caseIds.isEmpty()) {
			
			//if (filteredWolilist.isEmpty()) // Karen Hung DOO-4662 added query fields
				filteredWolilist =[Select Id, Case__c, Status, Case__r.TS_BI_WorkOrder_Start__c, StartDate__c, EndDate__c, IsFirstTask__c, WorkOrderType__c From Workorderlineitem
											  Where Status != :TS_Constants.STATUS_CANCELED AND 
											  RecordTypeId = :tsWOLIRecordType AND
											  Case__c in :caseIds];
			
			for (WorkOrderLineItem eachWoli :filteredWolilist) {
	            if (caseIdWoliListMap.containsKey(eachWoli.Case__c)){
					caseIdWoliListMap.get(eachWoli.Case__c).add(eachWoli);
				}else{
					caseIdWoliListMap.put(eachWoli.Case__c, new List<WorkOrderLineItem> {eachWoli});
				}
						
				// Karen Hung DOO-4662 PB TS_BI_TimeStamp_Start_finish_work additional criteria
				if(eachWoli.WorkOrderType__c != TS_Constants.TYPE_S25_ROUTESALES &&
				  ((eachWoli.Status == TS_Constants.WOLI_STATUS_STARTWORK &&  eachWoli.StartDate__c != null) || (eachWoli.Status == TS_Constants.STATUS_COMPLETED && eachWoli.EndDate__c != null))){
					Case newCase = new Case();
					newCase.Id = eachWoli.Case__c;
					newCase.TS_BI_WorkOrder_Finish__c = eachWoli.EndDate__c;
					newCase.TS_BI_WorkOrder_Start__c = (eachWoli.IsFirstTask__c == true || eachWoli.Case__r.TS_BI_WorkOrder_Start__c == null || eachWoli.Case__r.TS_BI_WorkOrder_Start__c > eachWoli.StartDate__c ) ? eachWoli.StartDate__c : eachWoli.Case__r.TS_BI_WorkOrder_Start__c;
					caseMapforBI.put(eachWoli.Case__c, newCase);
				}   
			}
		}
	
		for (Id eachCaseID :caseIds) {
			List<WorkOrderLineItem> woliStatusCompleted = new List<WorkOrderLineItem>();
			List<WorkOrderLineItem> woliStatusOpen = new List<WorkOrderLineItem>();
			Case eachCase = new Case();
			eachCase.id = eachCaseID;
						
			if (caseIdWoliListMap.containsKey(eachCaseID)) {
				for (WorkOrderLineItem eachWoliFromMap :caseIdWoliListMap.get(eachCaseID) ) {
					if (eachWoliFromMap.status == TS_Constants.STATUS_COMPLETED)
						woliStatusCompleted.add(eachWoliFromMap);
					else 
						woliStatusOpen.add(eachWoliFromMap);
				}
				eachCase.Number_of_Completed_WOLI_Tasks__c = woliStatusCompleted.size();
				eachCase.Number_of_Open_WOLI_Tasks__c = woliStatusOpen.size();
			}
			else {
				eachCase.Number_of_Completed_WOLI_Tasks__c = 0;
				eachCase.Number_of_Open_WOLI_Tasks__c = 0;
			}

			// Karen Hung DOO-4662 PB TS_BI_TimeStamp_Start_finish_work additional criteria
			if(caseMapforBI.containsKey(eachCaseID)){
				eachCase.TS_BI_WorkOrder_Finish__c = caseMapforBI.get(eachCaseID).TS_BI_WorkOrder_Finish__c;
				eachCase.TS_BI_WorkOrder_Start__c = caseMapforBI.get(eachCaseID).TS_BI_WorkOrder_Start__c;
			}
			
			caseListToReturn.add(eachCase);
		}
		
        CustomLogging.pop();     
        Return caseListToReturn;
	} 
	
	/******************************************************************************
    * @author         Marvin Gatchalian
    * @date           03.27.2018
    * @description    Method responsible Filtering records for Inserted Case. This has been called from Case Before Insert Event
    * @revision(s)
    ******************************************************************************/ 
	public void caseRoutingSettingsForInsertedCase (List<SObject> recordList) {
		
		Map <Id, List<Case>> contactIdsCaseMap = new Map <Id, List<Case>> ();
		
		for (Case eachCase :(List<Case>) recordList) {

			if (eachCase.ContactId != null){ // Checking when account filled from null to not null
				//System.debug ('Marvin >>> When Account Filled AccountID Inside: ' + eachCase.accountId);
					
				if ((eachCase.Type == TS_Constants.CASE_TYPE_CUSTOMERCARE || 
					 eachCase.Type == TS_Constants.CASE_TYPE_COMPLAINT || 
					 eachCase.Type == TS_Constants.CASE_TYPE_FIELDSERVICE)) {
					
					if (contactIdsCaseMap.containsKey(eachCase.ContactId))
						contactIdsCaseMap.get(eachCase.ContactId).add(eachCase);
					else
						contactIdsCaseMap.put(eachCase.ContactId, new List<Case> {eachCase});
				}
			}	
		}
		//System.debug ('Marvin >>> in Insert contactIdsCaseMap: ' + contactIdsCaseMap);
		//System.debug ('Marvin >>> in Insert contactIdsCaseMap.KeySet: ' + contactIdsCaseMap.keySet());
		if (!contactIdsCaseMap.keySet().isEmpty())
			performAssigningValue(contactIdsCaseMap);
		
	}
	
	/******************************************************************************
    * @author         Marvin Gatchalian
    * @date           03.27.2018
    * @description    Method responsible Filtering records for updated Case. This has been called from Case Before Update Event
    * @revision(s)
    ******************************************************************************/ 
	public void caseRoutingSettingsForUpdatedCase (List<SObject> recordList, Map<Id, SObject> oldMapItems ) {

		Map <Id, List<Case>> contactIdsCaseMap = new Map <Id, List<Case>> ();

		//Setting creteria for records should only include
		for (Case eachCase :(List<Case>) recordList) {
			//System.debug ('Marvin >>> in Update ContactId: ' + eachCase.ContactId);
			
			Case oldCase = (Case) oldMapItems.get(eachCase.id);
			if (eachCase.ContactId != null) {
				if ((eachCase.Type == TS_Constants.TS_CASE_RECORDTYPE_QUALIFYCASE && eachCase.Type != oldCase.Type &&
					 eachCase.CaseQualificationDate__c != null) 
					 || 
					(eachCase.CaseQualificationDate__c != null && 
					 eachCase.CaseQualificationDate__c != oldCase.CaseQualificationDate__c && 
					 eachCase.Type == TS_Constants.TS_CASE_RECORDTYPE_QUALIFYCASE) ) {
	
					if (contactIdsCaseMap.containsKey(eachCase.ContactId))
						contactIdsCaseMap.get(eachCase.ContactId).add(eachCase);
					else
						contactIdsCaseMap.put(eachCase.ContactId, new List<Case> {eachCase});
				}
			}
		}
		//System.debug ('Marvin >>> in Update contactIdsCaseMap: ' + contactIdsCaseMap);
		//System.debug ('Marvin >>> in Update contactIdsCaseMap.KeySet: ' + contactIdsCaseMap.keySet());
		if (!contactIdsCaseMap.keySet().isEmpty())
			performAssigningValue(contactIdsCaseMap);
		
	}

	/******************************************************************************
    * @author         Marvin Gatchalian
    * @date           03.27.2018
    * @description    Method responsible for Actual assigning of value for Case Routing.
    * @revision(s)
    ******************************************************************************/ 
	private void performAssigningValue(Map <Id, List<Case>> contactIdsCaseMap) {
		final String INDIVIDUAL = 'Individual';
		final String QUEUE = 'Queue';
		
		//System.debug ('Marvin >>> before query caseFieldExtensionList: ' + relatedContactList);
		
		if (relatedContactList.isEmpty())
			relatedContactList = [SELECT Id, Account.Default_Case_Owner__c, Account.Customer_Relations_1__c 
			      			  	  FROM Contact WHERE Id in :contactIdsCaseMap.keySet()];
		
		//System.debug ('Marvin >>> after query caseFieldExtensionList: ' + relatedContactList);
					       			  	 
		for (Contact relatedContact :relatedContactList) {
					       			    	
			if 	(contactIdsCaseMap.containsKey(relatedContact.Id)) {
				
				for (Case eachCase :contactIdsCaseMap.get(relatedContact.Id)) {
					//System.debug ('Marvin >>> eachCase.AssignToQueue__c :' + eachCase.AssignToQueue__c);
					//System.debug ('Marvin >>> Default_Owner_by_Country_Setting__c :' + eachCase.Default_Owner_by_Country_Setting__c);
					if(!eachCase.TS_IsGeneratedFromBatch__c){ //Karen Hung DOO-136 added checker
						/*if (!eachCase.AssignToQueue__c || 
						   (eachCase.AssignToQueue__c && eachCase.Default_Owner_by_Country_Setting__c == INDIVIDUAL)) {
							//System.debug ('Marvin >>> performAssigningValue 1st Criteria ');
							eachCase.OwnerId = userInfo.getUserId();
							eachCase.Run_Default_Case_Process__c = true;
							eachCase.Status = TS_Constants.STATUS_OPEN;
						}*/

						//Karen Hung 2019.07.08 DOO-490 if default owner is individual and use routing = false, assign to queue
						if(eachCase.Default_Owner_by_Country_Setting__c == INDIVIDUAL){
							if(eachCase.AssignToQueue__c){
								eachCase.OwnerId = userInfo.getUserId();
							}else{
								eachCase.AssignToQueue__c = true;
								eachCase.Default_Owner_by_Country_Setting__c = QUEUE;			
							}
							eachCase.Run_Default_Case_Process__c = true;
							eachCase.Status = TS_Constants.STATUS_OPEN;	
						}else if(!eachCase.AssignToQueue__c){
							eachCase.OwnerId = userInfo.getUserId();
							eachCase.Run_Default_Case_Process__c = true;
							eachCase.Status = TS_Constants.STATUS_OPEN;
						}
						
						if (relatedContact.Account.Default_Case_Owner__c &&
							relatedContact.Account.Customer_Relations_1__c != null &&
						    eachCase.ContactId != null ) {
						    //System.debug ('Marvin >>> performAssigningValue 2nd Criteria ');
						    eachCase.OwnerId = relatedContact.Account.Customer_Relations_1__c;
							eachCase.Run_Default_Case_Process__c = true;
							eachCase.Status = TS_Constants.STATUS_OPEN;
						}
					}
				}
			}       			    	
		}
	}
}