public without sharing class  AccountTaxTriggerHandler implements ITriggerHandler{
    
    public static Boolean isTriggerDisabled = true;
    
    public void BeforeInsert(List<SObject> newItems){
        checkrecursive.run = false;
    } 
 
    public void BeforeUpdate(List<SObject> newAccountTaxMap, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldAccountTaxMap){
        financeControllerNoManager((List<Account_Tax__c>) newAccountTaxMap, (Map<Id, Account_Tax__c>) oldAccountTaxMap);
        if (checkrecursive.run == true) {
            changeFieldValueAccountTax((List<Account_Tax__c>)newAccountTaxMap, (Map<Id, Account_Tax__c>)oldAccountTaxMap);
        }
    }
 
    public void BeforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems){
        
    } 
 
    public void AfterInsert(List<SObject> newList, Map<Id, SObject> newItems){
        checkrecursive.run = false;
    }
 
    public void AfterUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldItems){
        if (checkrecursive.run == true) {
        	reassignToManagerApprovalRequest((List<Account_Tax__c>) newList, (Map<Id, Account_Tax__c>) newItems);
        }
    }
 
    public void AfterDelete(List<SObject> oldList, Map<Id, SObject> oldItems){
        
    }
 
    public void AfterUndelete(List<SObject> newList, Map<Id, SObject> newItems){
        
    }
 
    public Boolean IsDisabled(){
        if (TriggerSettings__c.getInstance().AccountTaxTrigger__c == true) {
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
    private static Boolean fieldApproval(Account_Tax__c accountTax, Map<Id, Account_Tax__c> oldAccountTaxMap, Map<Id, User> ufinance) {
		Account_Tax__c oldAccTax;
		Boolean approvalFields = false;
		if(!oldAccountTaxMap.isEmpty()) {
			oldAccTax = oldAccountTaxMap.get(accountTax.Id);
            if ((accountTax.Mini_Tax_Classification__c != oldAccTax.Mini_Tax_Classification__c) ||
                (accountTax.Mini_Tax_Category__c != oldAccTax.Mini_Tax_Category__c) ||
                (accountTax.Mini_Tax_Country__c != oldAccTax.Mini_Tax_Country__c)) {
                if (UserInfo.getUserId() == ufinance.get(accountTax.Id).Id && ufinance.get(accountTax.Id).ManagerId == Null) {
                    approvalFields = true;
                }
            }
		} 
		
		return approvalFields;
	}
    
    public static void financeControllerNoManager(List<Account_Tax__c> newAccountTaxMap, Map<Id, Account_Tax__c> oldAccountTaxMap) {
        CustomLogging.push('financeControllerNoManager', 'AccountTaxTriggerHandler');
		try {
			List<Account_Tax__c> accountTaxFiltered = new List<Account_Tax__c>();
            Map<Id, User> ufinance = UserDAO.accountTaxFinanceController(newAccountTaxMap);
			for (Account_Tax__c a : newAccountTaxMap) {
				if (fieldApproval(a, oldAccountTaxMap, ufinance)) {
					accountTaxFiltered.add(a);
				}
			}
			
			if (!accountTaxFiltered.isEmpty()) {
				for (Account_Tax__c accTax : accountTaxFiltered) {
                    accTax.addError('The Manager information on finance controller is missing, and therefore the system cant initiate an approval flow for the approval request submitted by the approver him/herself');
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
    * @description   Reassign current approval to User's Manager
    * @revision(s)   
    */
    
    public static void reassignToManagerApprovalRequest(List<Account_Tax__c> newList, Map<Id, Account_Tax__c> newItems) {
        CustomLogging.push('reassignToManagerApprovalRequest', 'AccountTaxTriggerHandler');
        try {
            Map<Id, Account_Tax__c> validAccountTaxMap = new Map<Id, Account_Tax__c>();
            Set<Id> financeIds = new Set<Id>();
            
            for (Account_Tax__c acctTax : newList) {
                if (acctTax.Reject_to_Transfer__c == true) {
                    validAccountTaxMap.put(acctTax.Id, acctTax);
                    financeIds.add(acctTax.Finance_Controller_Tax_Validation__c);
                }
            }
            
            if (validAccountTaxMap.size() > 0 && financeIds != Null) {
            	List<ProcessInstanceWorkitem> accountTaxApprovalToUpdate = new List<ProcessInstanceWorkitem>();
                accountTaxApprovalToUpdate = SM_AccountTaxUtil.updateAssignedApprover(validAccountTaxMap, financeIds);
                
                if (!accountTaxApprovalToUpdate.isEmpty()) {
                    update accountTaxApprovalToUpdate;
                }
            }
            
        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop(); 
    }
    
    //Description: Update Request Field - This is used to updated the fields with old values and new values
    public static void changeFieldValueAccountTax(List<Account_Tax__c> newAccountTaxMap, Map<Id,Account_Tax__c> oldAccountTaxMap){
        CustomLogging.push('changeFieldValueAccountTax', 'AccountTaxTriggerHandler');
        try {
            Account_Tax__c oldAccTax;
            List<Account_Tax__c> taxesTobeUpdate = new List<Account_Tax__c>();
            if (oldAccountTaxMap != Null){
                for (Account_Tax__c acctTax : newAccountTaxMap) {
                    oldAccTax = oldAccountTaxMap.get(acctTax.Id);
                    if (acctTax.SAP_PO_Updated__c == false && (acctTax.Mini_Tax_Classification__c != oldAccTax.Mini_Tax_Classification__c || acctTax.Mini_Tax_Category__c != oldAccTax.Mini_Tax_Category__c || acctTax.Mini_Tax_Country__c != oldAccTax.Mini_Tax_Country__c)) {
                    	taxesTobeUpdate.add(acctTax);
                	}
                }
                
                if (!taxesTobeUpdate.isEmpty()) {
                    SM_AccountTaxUtil.changeFieldValue(taxesTobeUpdate, oldAccountTaxMap);
                }
            }
            
        } catch (Exception e) {
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop(); 
    }
}