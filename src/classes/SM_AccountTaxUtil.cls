public without sharing class SM_AccountTaxUtil {
    public static void changeFieldValue(List<Account_Tax__c> newAccountTaxMap, Map<Id,Account_Tax__c> oldAccountTaxMap) {
        CustomLogging.push('changeFieldValue', 'SM_AccountTaxUtil');
        try {
            Account_Tax__c oldAccTax;
            String profileName = [Select Id, Name FROM Profile WHERE Id = :UserInfo.getProfileId()].Name;
            for(Account_Tax__c acctax : newAccountTaxMap){ 
                oldAccTax = oldAccountTaxMap.get(acctax.Id);
                if (acctax.Mini_Tax_Classification__c != oldAccTax.Mini_Tax_Classification__c) {
                    acctax.Updated_Tax_Classification__c = acctax.Mini_Tax_Classification__c;
                    acctax.Mini_Tax_Classification__c = oldAccTax.Mini_Tax_Classification__c;
                    if (acctax.Updated_Request_Validation__c == SM_Constants.ApprovalRecall || acctax.Updated_Request_Validation__c == SM_Constants.NoUpdateRequest || acctax.Updated_Request_Validation__c == SM_Constants.ApprovalDeclined || acctax.Updated_Request_Validation__c == SM_Constants.ApprovalApproved || acctax.Updated_Request_Validation__c == SM_Constants.SAPIntegSuccessful || acctax.Updated_Request_Validation__c == SM_Constants.SAPIntegFailed) {
                        acctax.Updated_Request_Validation__c = SM_Constants.ApprovalPending;
                    }
                    
                }
                
                if (acctax.Mini_Tax_Category__c != oldAccTax.Mini_Tax_Category__c ){
                    acctax.Updated_Tax_Category__c = acctax.Mini_Tax_Category__c;
                    acctax.Mini_Tax_Category__c = oldAccTax.Mini_Tax_Category__c;
                    if (acctax.Updated_Request_Validation__c == SM_Constants.ApprovalRecall || acctax.Updated_Request_Validation__c == SM_Constants.NoUpdateRequest || acctax.Updated_Request_Validation__c == SM_Constants.ApprovalDeclined || acctax.Updated_Request_Validation__c == SM_Constants.ApprovalApproved || acctax.Updated_Request_Validation__c == SM_Constants.SAPIntegSuccessful || acctax.Updated_Request_Validation__c == SM_Constants.SAPIntegFailed) {
                        acctax.Updated_Request_Validation__c = SM_Constants.ApprovalPending;
                    }
                }
                
                if(acctax.Mini_Tax_Country__c != oldAccTax.Mini_Tax_Country__c){
                    acctax.Updated_Tax_Country__c = acctax.Mini_Tax_Country__c;
                    acctax.Mini_Tax_Country__c = oldAccTax.Mini_Tax_Country__c;
                    if (acctax.Updated_Request_Validation__c == SM_Constants.ApprovalRecall || acctax.Updated_Request_Validation__c == SM_Constants.NoUpdateRequest || acctax.Updated_Request_Validation__c == SM_Constants.ApprovalDeclined || acctax.Updated_Request_Validation__c == SM_Constants.ApprovalApproved || acctax.Updated_Request_Validation__c == SM_Constants.SAPIntegSuccessful || acctax.Updated_Request_Validation__c == SM_Constants.SAPIntegFailed) {
                        acctax.Updated_Request_Validation__c = SM_Constants.ApprovalPending;
                    }
                }
            }  
        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        
    }
    
    public static List<ProcessInstanceWorkitem> updateAssignedApprover(Map<Id, Account_Tax__c> validAccountTaxMap, Set<Id> financeIds) {
        CustomLogging.push('updateAssignedApprover', 'SM_AccountTaxUtil');
        try{
            List<ProcessInstanceWorkitem> ApprovalRequestList = new List<ProcessInstanceWorkitem>();
            if (validAccountTaxMap.size() > 0 && financeIds != Null) {
                Map<Id, Id> financeManagerMap = new Map <Id, Id>();
                for (User u : [Select Id, ManagerId FROM USER WHERE Id in: financeIds]) {
                    financeManagerMap.put(u.Id, u.ManagerId);
                }
                ApprovalRequestList = [SELECT Id, ActorId, OriginalActorId, ProcessInstanceId 
                                       FROM ProcessInstanceWorkitem piwi 
                                       WHERE piwi.ProcessInstanceId in (SELECT Id FROM ProcessInstance WHERE TargetObjectId in: validAccountTaxMap.keySet())];
                                        
                if (ApprovalRequestList.size() > 0) {
                    Id financeManager;
                    
                    for (ProcessInstanceWorkitem piwi : ApprovalRequestList) {
                        financeManager = financeManagerMap.get(piwi.ActorId);
                        
                        if (financeManager <> Null) {
                            piwi.ActorId = financeManager;
                        }
                    }
                }
            }
            return ApprovalRequestList;
            
        } catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
            return null;
        }
    }	
}