/**
* @author        Catherine Kia Aragon
* @date                   
* @description   Handler for Bank detail trigger
* @revision(s)   N/A
*/
public without sharing class BankDetailsTriggerHandler implements ITriggerHandler{
    
    public static Boolean isTriggerDisabled = true;
    Map<Id, Bank_Details__c> oldBnkDetailMap = new Map<Id, Bank_Details__c>();
    
    public void BeforeInsert(List<SObject> newItems){
        stampExternalId((List<Bank_Details__c>)newItems);
        onBeforeUpdateChangeFieldValueBankDetail((List<Bank_Details__c>)newItems, oldBnkDetailMap);
    }
    
    public void BeforeUpdate(List<SObject> newBankDetailMap, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldBankDetailMap){
        financeControllerNoManager((List<Bank_Details__c>)newBankDetailMap, (Map<Id, Bank_Details__c>)oldBankDetailMap);
        if (SM_CheckRecursive.run == true){
            onBeforeUpdateChangeFieldValueBankDetail((List<Bank_Details__c>)newBankDetailMap, (Map<Id, Bank_Details__c>)oldBankDetailMap);
        }
        
    }
    
    public void BeforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems){
        
    } 
    
    public void AfterInsert(List<SObject> newList, Map<Id, SObject> newItems){
        submitApproval((List<Bank_Details__c>)newList, oldBnkDetailMap);
        createIntegrationLogs(newList, null);
    }
    
    public void AfterUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldItems){
        createIntegrationLogs(newList, oldItems);
        //createIntegrationLogsIfUpdatedFieldsFilledIn(newList, (Map<Id, Bank_Details__c>) oldItems);
        onAfterUpdateReassignToManagerApprovalRequest((List<Bank_Details__c>) newList, (Map<Id, Bank_Details__c>) newItems );
    }
    
    public void AfterDelete(List<SObject> oldList, Map<Id, SObject> oldItems){
        
    }
    
    public void AfterUndelete(List<SObject> newList, Map<Id, SObject> newItems){
        
    }
    
    public Boolean IsDisabled(){
        if (TriggerSettings__c.getInstance().BankDetailsTrigger__c == true) {
            return false;
        } else {
            return isTriggerDisabled;
        }
    }
    
     /**
    * @author        Catherine Kia Aragon
    * @date                   
    * @description   Validation rule if manager is not populated on finance controller
    * @revision(s)   N/A
    */
    private static Boolean fieldApproval(Bank_Details__c bankDetail, Map<Id, Bank_Details__c> oldBankDetailMap, Map<Id, User> ufinance) {
		Bank_Details__c oldBank; 
		Boolean approvalFields = false;
		if(!oldBankDetailMap.isEmpty()) {
			oldBank = oldBankDetailMap.get(bankDetail.Id);
            if ((bankDetail.Bank_account__c != oldBank.Bank_account__c) ||
                (bankDetail.Bank_country__c != oldBank.Bank_country__c) ||
                (bankDetail.Bank_key__c != oldBank.Bank_key__c) ||
                (bankDetail.Control_key__c != oldBank.Control_key__c) || 
                (bankDetail.IBAN__c != oldBank.IBAN__c) ||
                (bankDetail.Collection_authorization__c != oldBank.Collection_authorization__c)) {
                    if (UserInfo.getUserId() == ufinance.get(bankDetail.Id).Id && ufinance.get(bankDetail.Id).ManagerId == Null) {
                        approvalFields = true;
                    }
            }
		} 
		
		return approvalFields;
	}
    
    public static void financeControllerNoManager(List<Bank_Details__c> newBankDetailMap, Map<Id, Bank_Details__c> oldBankDetailMap) {
        CustomLogging.push('financeControllerNoManager', 'BankDetailsTriggerHandler');
		try {
			List<Bank_Details__c> bankDetailFiltered = new List<Bank_Details__c>();
            Map<Id, User> ufinance = UserDAO.bankDetailFinanceController(newBankDetailMap);
			for (Bank_Details__c b : newBankDetailMap) {
				if (fieldApproval(b, oldBankDetailMap, ufinance)) {
					bankDetailFiltered.add(b);
				}
			}
			
			if (!bankDetailFiltered.isEmpty()) {
				for (Bank_Details__c bank : bankDetailFiltered) {
                    bank.addError('The Manager information on finance controller is missing, and therefore the system cant initiate an approval flow for the approval request submitted by the approver him/herself');
                }
			}
		} catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop(); 
    }
    
    /**
    * @author        Catherine Kia Aragon
    * @date                   
    * @description   On insert of bank detail record and external id is empty stamp value with createguidutility
    * @revision(s)   N/A
    */
    public static void stampExternalId(List<Bank_Details__c> newBankDetailMap) {
		CustomLogging.push('stampExternalId', 'BankDetailsTriggerHandler');
        try {
            for(Bank_Details__c bankDetail : newBankDetailMap) {
                if (String.isBlank(bankDetail.External_ID__c)) {
                   bankDetail.External_ID__c = KeyGenerator.generateGUID();
                }
            }
            
        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop(); 
	}
    
    /**
    * @author        Catherine Kia Aragon
    * @date                   
    * @description   Reassign current approval to User's Manager
    * @revision(s)   N/A
    */
    
    public static void onAfterUpdateReassignToManagerApprovalRequest(List<Bank_Details__c> newList, Map<Id, Bank_Details__c> newItems ) {
        CustomLogging.push('onAfterUpdateReassignToManagerApprovalRequest', 'BankDetailsTriggerHandler');
        try {
            Map<Id, Bank_Details__c> validBankDetailMap = new Map<Id, Bank_Details__c>();
            Set<Id> financeIds = new Set<Id>();
            
            for (Bank_Details__c bank : newList) {
                if (bank.Reject_to_Transfer__c == true) {
                    validBankDetailMap.put(bank.Id, bank);
                    financeIds.add(bank.Finance_Controller_BD_Validation__c);
                }
            }
            
            if (validBankDetailMap.size() > 0) {
                Map<Id, Id> financeManagerMap = new Map<Id, Id>();
                
                if (financeIds <> Null) {
                    for (User u : [Select Id, ManagerId FROM User WHERE Id in: financeIds]) {
                        financeManagerMap.put(u.id, u.ManagerId);
                    }
                }
                
                List<ProcessInstanceWorkitem> ApprovalRequestList = new List<ProcessInstanceWorkitem>();
               
                ApprovalRequestList = [SELECT Id, ActorId, OriginalActorId, ProcessInstanceId 
                                       FROM ProcessInstanceWorkitem piwi 
                                       WHERE piwi.ProcessInstanceId in (SELECT Id FROM ProcessInstance WHERE TargetObjectId in: validBankDetailMap.keySet())];

                
                if (ApprovalRequestList.size() > 0) {
                    Id financeManager;
                    
                    for (ProcessInstanceWorkitem piwi : ApprovalRequestList) {
                        financeManager = financeManagerMap.get(piwi.ActorId);
                        
                        if (financeManager <> Null) {
                            piwi.ActorId = financeManager;
                        }
                    }
                    
                    update ApprovalRequestList;
                }
            }
            
        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop(); 
    }
    
    
    /**
    * @author        Catherine Aragon
    * @date                    
    * @description   Update Request Field - This is used to updated the fields with old values and new values
    * @revision(s)   N/A
    */
    public static void onBeforeUpdateChangeFieldValueBankDetail(List<Bank_Details__c> newBankDetailMap, Map<Id,Bank_Details__c> oldBankDetailMap){
        CustomLogging.push('onBeforeUpdateChangeFieldValueBankDetail', 'BankDetailsTriggerHandler');
        try {
            Boolean setToUpdateRequestValidationReq = false;
            Id currentUser = UserInfo.getUserId();
            Map<String, Id> financeController = new Map<String, Id>();
            Set<String> salesOrg = new Set<String>();
            for (Bank_Details__c bnk : newBankDetailMap) {
                salesOrg.add(bnk.Sales_Organization__c);
            }
            List<Approval_Configurations__mdt> approvers = new List<Approval_Configurations__mdt>();
            approvers = [Select Id, Approver__c, Sales_Organization__c, Approver_Manager__c, Approval_Role__c FROM Approval_Configurations__mdt WHERE Sales_Organization__c IN :salesOrg];
            if (!approvers.isEmpty()) {
                for (Approval_Configurations__mdt a : approvers) {
                    if (currentUser == a.Approver__c && a.Approver_Manager__c != Null) {
                        financeController.put(a.Approval_Role__c + ' ' + a.Approver_Manager__c, a.Approver_Manager__c);
                    } else {
                        financeController.put(a.Approval_Role__c + ' '  + a.Approver__c, a.Approver__c);
                    }
                }
            }

            List<Id> financeControllerId = new List<Id>();
            if(financeController.size() > 0) {
                for (String finances : financeController.keySet()) {
                    if (finances.contains('Finance Controller')) {
                        financeControllerId.add(financeController.get(finances));
                    }
                }
            }
            for(Bank_Details__c bankDetail : newBankDetailMap){
                if (!oldBankDetailMap.isEmpty()){
                    Bank_Details__c oldAl = (Bank_Details__c)oldBankDetailMap.get(bankDetail.Id);
                    if(bankDetail.SAP_PO_Updated__c == false){
                        if(bankDetail.Updated_Request_Validation__c == SM_Constants.ApprovalApproved && bankDetail.Updated_Request_Validation__c != oldAl.Updated_Request_Validation__c){
                            if (bankDetail.Approval_Bank_Account__c != Null && oldAl.Updated_Bank_account__c == Null) {
                                bankDetail.Updated_Bank_account__c = bankDetail.Approval_Bank_Account__c;
                                bankDetail.Approval_Bank_Account__c = null;
                            }

                            if (bankDetail.Approval_Bank_Country__c != Null && oldAl.Updated_Bank_account__c == Null) {
                                bankDetail.Updated_Bank_Country__c = bankDetail.Approval_Bank_Country__c;
                                bankDetail.Approval_Bank_Country__c = null;
                            }

                            if (bankDetail.Approval_Bank_Key__c != Null && oldAl.Updated_Bank_Key__c == Null) {
                                bankDetail.Updated_Bank_Key__c = bankDetail.Approval_Bank_Key__c;
                                bankDetail.Approval_Bank_Key__c = null;
                            }

                            if (bankDetail.Approval_Control_Key__c != Null && oldAl.Updated_Control_Key__c == Null) {
                                bankDetail.Updated_Control_Key__c = bankDetail.Approval_Control_Key__c;
                                bankDetail.Approval_Control_Key__c = null;
                            }

                            if (bankDetail.Approval_IBAN__c != Null && oldAl.Updated_IBAN__c == Null) {
                                bankDetail.Updated_IBAN__c = bankDetail.Approval_IBAN__c;
                                bankDetail.Approval_IBAN__c = null;
                            }

                            if (oldAl.Updated_Collection_Authorizations__c == Null) {
                                if (bankDetail.Approval_Collection_Authorization__c) {
                                    bankDetail.Updated_Collection_Authorizations__c = 'true';
                                } else {
                                    bankDetail.Updated_Collection_Authorizations__c = 'false';
                                }
                                bankDetail.Approval_Collection_Authorization__c = false;
                            }
                        }
                    } 
                } else {
                    if(bankDetail.SAP_PO_Updated__c == false){
                        if (bankDetail.Bank_account__c != Null) {
                            bankDetail.Approval_Bank_Account__c = bankDetail.Bank_account__c;
                            bankDetail.Bank_account__c = Null;
                            if(bankDetail.Updated_Request_Validation__c == SM_Constants.ApprovalRecall || bankDetail.Updated_Request_Validation__c == SM_Constants.NoUpdateRequest || bankDetail.Updated_Request_Validation__c == SM_Constants.ApprovalDeclined || bankDetail.Updated_Request_Validation__c == SM_Constants.ApprovalApproved || bankDetail.Updated_Request_Validation__c == SM_Constants.SAPIntegSuccessful || bankDetail.Updated_Request_Validation__c == SM_Constants.SAPIntegFailed){
                                setToUpdateRequestValidationReq = true;
                            }
                            
                        }
                        
                        if (bankDetail.Bank_country__c != Null) {
                            bankDetail.Approval_Bank_Country__c = bankDetail.Bank_country__c;
                            bankDetail.Bank_country__c = Null;
                            if(bankDetail.Updated_Request_Validation__c == SM_Constants.ApprovalRecall || bankDetail.Updated_Request_Validation__c == SM_Constants.NoUpdateRequest || bankDetail.Updated_Request_Validation__c == SM_Constants.ApprovalDeclined || bankDetail.Updated_Request_Validation__c == SM_Constants.ApprovalApproved || bankDetail.Updated_Request_Validation__c == SM_Constants.SAPIntegSuccessful || bankDetail.Updated_Request_Validation__c == SM_Constants.SAPIntegFailed){
                                setToUpdateRequestValidationReq = true;
                            }
                        }
                        
                        if (bankDetail.Bank_key__c != Null) {
                            bankDetail.Approval_Bank_Key__c = bankDetail.Bank_key__c;
                            bankDetail.Bank_key__c = Null;
                            if(bankDetail.Updated_Request_Validation__c == SM_Constants.ApprovalRecall || bankDetail.Updated_Request_Validation__c == SM_Constants.NoUpdateRequest || bankDetail.Updated_Request_Validation__c == SM_Constants.ApprovalDeclined || bankDetail.Updated_Request_Validation__c == SM_Constants.ApprovalApproved || bankDetail.Updated_Request_Validation__c == SM_Constants.SAPIntegSuccessful || bankDetail.Updated_Request_Validation__c == SM_Constants.SAPIntegFailed){
                                setToUpdateRequestValidationReq = true;
                            }
                        }
                        
                        if (bankDetail.Control_key__c != Null) {
                            bankDetail.Approval_Control_Key__c = bankDetail.Control_key__c;
                            bankDetail.Control_key__c = Null;
                            if(bankDetail.Updated_Request_Validation__c == SM_Constants.ApprovalRecall || bankDetail.Updated_Request_Validation__c == SM_Constants.NoUpdateRequest || bankDetail.Updated_Request_Validation__c == SM_Constants.ApprovalDeclined || bankDetail.Updated_Request_Validation__c == SM_Constants.ApprovalApproved || bankDetail.Updated_Request_Validation__c == SM_Constants.SAPIntegSuccessful || bankDetail.Updated_Request_Validation__c == SM_Constants.SAPIntegFailed){
                                setToUpdateRequestValidationReq = true;
                            }
                        }
                        
                        if (bankDetail.IBAN__c != Null) {
                            bankDetail.Approval_IBAN__c = bankDetail.IBAN__c;
                            bankDetail.IBAN__c = Null;
                            if (bankDetail.Updated_Request_Validation__c == SM_Constants.ApprovalRecall || bankDetail.Updated_Request_Validation__c == SM_Constants.NoUpdateRequest || bankDetail.Updated_Request_Validation__c == SM_Constants.ApprovalDeclined || bankDetail.Updated_Request_Validation__c == SM_Constants.ApprovalApproved || bankDetail.Updated_Request_Validation__c == SM_Constants.SAPIntegSuccessful || bankDetail.Updated_Request_Validation__c == SM_Constants.SAPIntegFailed){
                                setToUpdateRequestValidationReq = true;
                            }
                        }
                        
                        if (bankDetail.Collection_authorization__c) {
                            bankDetail.Approval_Collection_Authorization__c = true;
                            bankDetail.Collection_authorization__c = false;
                            if(bankDetail.Updated_Request_Validation__c == SM_Constants.ApprovalRecall || bankDetail.Updated_Request_Validation__c == SM_Constants.NoUpdateRequest || bankDetail.Updated_Request_Validation__c == SM_Constants.ApprovalDeclined || bankDetail.Updated_Request_Validation__c == SM_Constants.ApprovalApproved || bankDetail.Updated_Request_Validation__c == SM_Constants.SAPIntegSuccessful || bankDetail.Updated_Request_Validation__c == SM_Constants.SAPIntegFailed){
                                setToUpdateRequestValidationReq = true;
                            }
                        }

                        if (setToUpdateRequestValidationReq) {
                            bankDetail.Updated_Request_Validation__c = 'Approval Pending';
                            bankDetail.Approval_Required__c = true;
                            bankDetail.Sent_for_Approval_Date__c = Date.today();
                            bankDetail.Finance_Controller_BD_Validation__c = financeControllerId[0];
                            bankDetail.Finance_Controller_BD_Validation_2__c = financeControllerId[1];
                            bankDetail.Approval_Submitter__c = currentUser;
                        }
                    }
                }
            }
             SM_CheckRecursive.run = false;
        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop(); 
    }

    private void submitApproval(List<Bank_Details__c> newBankDetailMap, Map<Id,Bank_Details__c> oldBankDetailMap) {
        if (oldBankDetailMap.isEmpty()) {
            for (Bank_Details__c bnk : newBankDetailMap) {
                if (bnk.Updated_Request_Validation__c == 'Approval Pending') {
                    // Create an approval request for the sObject
                    Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
                    req1.setObjectId(bnk.Id);

                    // Submit the approval request for the sObject
                    Approval.ProcessResult result = Approval.process(req1);
                    ApprovalProcessService.unlockApproval(bnk.Id);
                }
            }

        }
       
    }
    
    /**
    * @author        Catherine Aragon
    * @date          09.07.2018           
    * @description   Method responsible for creating Integration Logs
    * @revision(s)   N/A
    */
    
    public void createIntegrationLogs(List<SObject> newList, Map<Id, SObject> oldRecordMap){
        CustomLogging.push('createIntegrationLogs', 'BankDetailsTriggerHandler');
        try {
            List<Integration_Log__c> integLogsToInsertList = new List<Integration_Log__c>();
            
            //Checker if an Integration Log for SAP is already created
            Boolean SAPiLogCreated = false;
            
            List<Bank_Details__c> bankdetails = new List<Bank_Details__c>();
            bankdetails = [Select Id, Account__c, Account__r.SAP_Customer_ID__c, SAP_PO_Updated__c, Updated_Request_Validation__c FROM Bank_Details__c WHERE ID IN :newList];
            
            for(Bank_Details__c b: bankdetails){
                if (b.Updated_Request_Validation__c == SM_Constants.ApprovalApproved && b.SAP_PO_Updated__c == false && b.Account__r.SAP_Customer_ID__c != Null) {
                    integLogsToInsertList.add(new Integration_Log__c(Object_Id__c = b.Account__c, 
                                                                     Object__c = 'Account',
                                                                     Account__c = b.Account__c,
                                                                     Bank_Detail__c = b.id));
                    
                    SAPiLogCreated = true;
                }
                
            }
            
            if(integLogsToInsertList != null && !integLogsToInsertList.isEmpty()) {
            	insert integLogsToInsertList;
            }
            
        } catch(Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();      
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        CustomLogging.pop(); 
    }
}