//-------------------------------------------------------------------------------------------//
// Author       :   Abram Vixen Reyes
// Created Date :   Sept 26, 2018
// Usage        :   Queuable Interface to Trigger Work Order Billing
//-------------------------------------------------------------------------------------------//
public without sharing class TS_WorkOrderBillingQueuable implements Queueable , Database.AllowsCallouts{

	public List<WorkOrderLineItem> newList {get; set;}
	public Set<Id> parentWOLI {get; set;}
	public List<WorkOrderLineItem> updateList = new List<WorkOrderLineItem>();
	public static Map<String, CountrySetting__c> COUNTRYSETTING_PURCHASING_COMPANYCODE_MAP = new Map<String, CountrySetting__c>();
    //Karen Hung 25/11/2020 DOO-5035
    public static String clickName = IntegrationUserAndProfile__c.getInstance().Click_Integration_Name__c;

	public void execute(QueueableContext context) {
		CustomLogging.push('execute', 'TS_WorkOrderBillingQueuable');

		//System.debug('XEN 10/2 getUiThemeDisplayed: ' + UserInfo.getUiThemeDisplayed());
		//System.debug('XEN 10/2 getUiTheme: ' + UserInfo.getUiTheme());

		List<Integration_Log__c> integLogsList = new List<Integration_Log__c>();

		try{
			if(!parentWOLI.isEmpty()){
				Map<Id, WorkOrderLineItem> parentTaskMap = new Map<Id, WorkOrderLineItem>([SELECT Id, Status, Is_WorkOrder_Billling_Required__c, LastModifiedById, CreatedById, InternalOrderSAP__c FROM WorkOrderLineItem WHERE Id IN: parentWOLI]);
				
                //Karen Hung 21/11/2020 DOO-5035 to query createdby.name
                Map<Id, WorkOrderLineItem> extnewList = new Map<Id,WorkOrderLineItem>([SELECT Id, Createdby.Name FROM WorkOrderLineItem WHERE Id in :newList]);
                
				//SCENARIO 1: Work Order Billing Queueable
				for(WorkOrderLineItem wo : newList){
					WorkOrderLineItem parentTask = parentTaskMap.get(wo.ParentWorkOrderLineItemId);

					System.debug('XEN Jan. 11 parentTask: ' + parentTask);

					//SCENARIO 1: When Click User closed a non-review needed task, but review needed in SF. (e.g internal order sap is missing)
					Boolean isClickCreated = extnewList.get(wo.Id).CreatedBy.Name == clickName && parentTask.InternalOrderSAP__c != null;

					//SCENARIO 2: Non-Click User task completion
					Boolean isNonClickCreated = extnewList.get(wo.Id).CreatedBy.Name != clickName;

					if((isClickCreated || isNonClickCreated) && parentTask.Is_WorkOrder_Billling_Required__c == true){
						integLogsList.add(new Integration_Log__c(Object_Id__c = parentTask.Id,
                                                  Object__c = TS_Constants.WO_BILLING,
                                                  Integration_Status__c = INT_Constants.INITIAL,
                                                  Work_Order_Line_Item__c = parentTask.Id));
					}					
				}
				
				//Check the feature flag AND query child parts for Goods Movement & Car Stock Replenishment
				List<TS_Feature_Flag__mdt> featureflagList = [SELECT Id, QualifiedApiName, Enable__c FROM TS_Feature_Flag__mdt WHERE QualifiedApiName = 'DOO_5026_SF_Change_trigger_Used_Part_G' LIMIT 1];
				if((!featureflagList.isEmpty() && featureflagList[0].Enable__c) || Test.isRunningTest()){

					List<WorkOrderLineItem> childWorkOrderLineItems = [SELECT Id,
																			Status,
																			WorkOrderLineItemType__c,
																			Part_used_from_own_storage_location__c,
																			ParentWorkOrderLineItemId,
																			ParentWorkOrderLineItem.OrderHeaderSAPId__c,
																			ParentWorkOrderLineItem.ExecutingEngineer__c,
																			ParentWorkOrderLineItem.ExecutingEngineer__r.SAPStorageLocation__c,
																			ParentWorkOrderLineItem.ExecutingEngineer__r.CompanyCode__c,
																			DirectToCustomer__c
																			FROM WorkOrderLineItem WHERE ParentWorkOrderLineItemId IN:parentWOLI 
																			AND IsReadyToSummarize__c = false
																			AND (WorkOrderLineItemType__c =: TS_Constants.TYPE_API_USEDPARTS OR WorkOrderLineItemType__c =: TS_Constants.WOLI_STATUS_MISSING)
																			AND Id NOT IN (SELECT Work_Order_Line_Item__c FROM Integration_Log__c WHERE Work_Order_Line_Item__r.ParentWorkOrderLineItemId IN: parentWOLI AND (Object__c =: INT_Constants.WOLI_GOODS_MVMT OR Object__c =: INT_Constants.WOLI_CARSTOCK))];

					if(!childWorkOrderLineItems.isEmpty()){

						if(COUNTRYSETTING_PURCHASING_COMPANYCODE_MAP.isEmpty()){    
							List<CountrySetting__c> GET_COUNTRYPURCHASING_LIST = [SELECT Id, Name, Company_Code__c, Active__c FROM CountrySetting__c    
																				WHERE Active__c = true  
																				AND RecordType.Name =: TS_Constants.TS_COUNTRYSETTING_RECORDTYPE_COUNTRYPURCHASING];    
							if(!GET_COUNTRYPURCHASING_LIST.isEmpty()){  
								for(CountrySetting__c CS_VAR : GET_COUNTRYPURCHASING_LIST){ 
									COUNTRYSETTING_PURCHASING_COMPANYCODE_MAP.put(CS_VAR.Company_Code__c, CS_VAR);  
								}   
							}   
						}

						for(WorkOrderLineItem woli : childWorkOrderLineItems){

							//SCENARIO 2: Goods Movement
							if (woli.Status == TS_Constants.STATUS_COMPLETED &&
								woli.WorkOrderLineItemType__c == TS_Constants.TYPE_API_USEDPARTS &&
								woli.Part_used_from_own_storage_location__c == true && 
								woli.ParentWorkOrderLineItem.OrderHeaderSAPId__c == null &&
								woli.ParentWorkOrderLineItem.ExecutingEngineer__c != null &&
								woli.ParentWorkOrderLineItem.ExecutingEngineer__r.SAPStorageLocation__c != null
								){

								integLogsList.add(new Integration_Log__c(Object_Id__c = woli.Id,
										Object__c = INT_Constants.WOLI_GOODS_MVMT,
										Integration_Status__c = INT_Constants.INITIAL,
										Work_Order_Line_Item__c = woli.Id));
							}
							
							//SCENARIO 3: Missing Parts Car Stock Replenishment
							if (woli.DirectToCustomer__c == false &&
								woli.WorkOrderLineItemType__c == TS_Constants.WOLI_STATUS_MISSING &&
								woli.ParentWorkOrderLineItem.ExecutingEngineer__c != null &&
								woli.ParentWorkOrderLineItem.ExecutingEngineer__r.CompanyCode__c != null &&
								COUNTRYSETTING_PURCHASING_COMPANYCODE_MAP.containsKey(woli.ParentWorkOrderLineItem.ExecutingEngineer__r.CompanyCode__c)
								){
								
								integLogsList.add(new Integration_Log__c(Object_Id__c = woli.Id,
										Object__c = INT_Constants.WOLI_CARSTOCK,
										Integration_Status__c = INT_Constants.INITIAL,
										Work_Order_Line_Item__c = woli.Id));
							}				
						}
					}
				}

				if(!integLogsList.isEmpty()){
					insert integLogsList;
				}
				
			}	
		} catch (Exception e){
			System.debug(e);
		}

		CustomLogging.pop();
	}
}