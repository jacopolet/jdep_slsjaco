/*************************************************************
@Name: APTS_AgreementExpireCERBatch
@Author: Pranjal Mittal
@CreateDate: 07-03-2018
@Description: 
@UsedBy: APTS_AgreementExpireCERBatchScheduler
******************************************************************/

global class APTS_AgreementExpireCERBatch implements Database.Batchable<sObject>, Database.Stateful {
	
	String query;
	//private List<Id> lstExpiredAgreementsId = new List<Id>();

	global APTS_AgreementExpireCERBatch() {

	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		Date yesterdayDate = Date.today().addDays(-1);
		query = 'SELECT Id FROM Apttus__APTS_Agreement__c WHERE Apttus__Contract_End_Date__c = :yesterdayDate';
		
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope) {	
		List<Apttus__APTS_Agreement__c> lstAgreements = (List<Apttus__APTS_Agreement__c>) scope;
		List<Id> lstExpiredAgreementsId = new List<Id>();
		
		for(Apttus__APTS_Agreement__c tmpAggr : lstAgreements){
			lstExpiredAgreementsId.add(tmpAggr.Id);
		}

		if(lstExpiredAgreementsId != null && lstExpiredAgreementsId.size()>0){
			APTS_ManageCER.updateCERForAgreementExpiration(lstExpiredAgreementsId);
		}
	}
	
	global void finish(Database.BatchableContext BC) {

	}
	
}