/*******************************************************************************************
Name            : APTS_AgreementBudgetHandler
Created By      : Pranjal Mittal
Created Date    : 18 July 2018
Description     : Handler class
Test Class      : 
*********************************************************************************************/

public with sharing class APTS_AgreementBudgetHandler implements ITriggerHandler{
    public void beforeInsert(List<SObject> newItems){
        List<String> lstLang = new List<String>();
        Set<Id> agreementIdSet = new Set<Id>();
        try {
			for(APTS_Agreement_Budget__c tmp : (List<APTS_Agreement_Budget__c>) newItems){
				if(tmp.APTS_Agreement_Language__c != NULL){
					lstLang.add(tmp.APTS_Agreement_Language__c);
				}
				agreementIdSet.add(tmp.Agreement__c);  
			}
			
			if(lstLang.size() > 0){
				APTS_LanguageTranslator.translateLanguage(newItems, 'APTS_Agreement_Budget__c', lstLang);
			}
			
			Map<Id, Apttus__APTS_Agreement__c> agreementMap = new Map<Id, Apttus__APTS_Agreement__c>([SELECT Id,
																												Apttus__Contract_Start_Date__c
																												FROM Apttus__APTS_Agreement__c
																												WHERE Id IN: agreementIdSet
																												LIMIT 50000]);
				
			for(APTS_Agreement_Budget__c budget: (List<APTS_Agreement_Budget__c>) newItems){
				if(agreementMap.containsKey(budget.Agreement__c) && agreementMap.get(budget.Agreement__c) != null){
					budget.APTS_Start_Date__c = agreementMap.get(budget.Agreement__c).Apttus__Contract_Start_Date__c;
				}
			}
		} catch (Exception ex) {APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString() , 'AgreementBudgetHandler beforeinsert', null, 'CLM', false, false, null, true);}
    }
 
    public void beforeUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldItems){
        List<String> lstLang = new List<String>();
		try {
			for(APTS_Agreement_Budget__c tmp : (List<APTS_Agreement_Budget__c>) newList){
				if(tmp.APTS_Agreement_Language__c != NULL){
					lstLang.add(tmp.APTS_Agreement_Language__c);
				}
			}
			if(lstLang.size() > 0){
				APTS_LanguageTranslator.translateLanguage(newList, 'APTS_Agreement_Budget__c', lstLang);
			}
		} catch (Exception ex) {APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString() , 'AgreementBudgetHandler beforeupdate', null, 'CLM', false, false, null, true);}
    }
 
    public void beforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems){} 
 
    public void afterInsert(List<SObject> newList, Map<Id, SObject> newItems){
		try {
			APTS_CLMUtil.validateLock(newList, 'APTS_Agreement_Budget__c');
		} catch (Exception ex) {APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString() , 'AgreementBudgetHandler afterinsert', null, 'CLM', false, false, null, true);}
    }
 
    public void afterUpdate(List<SObject> newList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldItems){
		try {
			APTS_CLMUtil.validateLock(newList, 'APTS_Agreement_Budget__c');  
		} catch (Exception ex) {APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString() , 'AgreementBudgetHandler afterupdate', null, 'CLM', false, false, null, true);}
    }
 
    public void afterDelete(List<SObject> oldList, Map<Id, SObject> oldItems){}
 
    public void afterUndelete(List<SObject> newList, Map<Id, SObject> newItems){}
 
    public Boolean isDisabled(){
        return false;
    }
}