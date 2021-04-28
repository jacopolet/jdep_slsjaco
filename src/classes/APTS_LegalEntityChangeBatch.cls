/*************************************************************
@Name: APTS_LegalEntityChangeBatch
@Author: Pranjal Mittal
@CreateDate: 04-06-2018
@Description: 
@UsedBy: APTS_LegalEntityChange.cls
******************************************************************/

global class APTS_LegalEntityChangeBatch implements Database.Batchable<sObject> {

	String query;
	Map<Id, Id> mapOldNewAggr;
	Set<Id> setOldAggr;
	
	//Constructor
	global APTS_LegalEntityChangeBatch(Map<Id, Id> mapOldNewAggr) {
		this.mapOldNewAggr = mapOldNewAggr;
		setOldAggr = mapOldNewAggr.keySet();
		query = 'SELECT Id FROM Apttus__APTS_Agreement__c WHERE Id IN: setOldAggr';
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope) {
		for(Id oldId : mapOldNewAggr.keySet()){
			List<String> lstRelations = new List<String>();
            lstRelations.add('Attachments');
            lstRelations.add('Apttus__AgreementLineItems__r');
            lstRelations.add('Apttus_CMConfig__Configurations__r');
            lstRelations.add('Apttus__Agreement_Document__r');
            lstRelations.add('Adjustment_Line_Account_Exclusions__r');
            lstRelations.add('Adjustments__r');
            lstRelations.add('Agreement_Total_Volume_Obligations__r');
            lstRelations.add('Agreement_Volume_Obligations__r');
            lstRelations.add('Agreement_Budgets__r');
            lstRelations.add('Agreement_PO_Detailss__r');
            lstRelations.add('Billing_Settings__r');
            lstRelations.add('Index_Contracts__r');
            lstRelations.add('Index_Executings__r');
            lstRelations.add('Rebate_Definition__r');
            lstRelations.add('Contracted_KPI_SLAs__r');
            lstRelations.add('Apttus_Echosign__Agreements__r');

            Apttus.ComplyWebService.copyAgreementChildSObjects(oldId, mapOldNewAggr.get(oldId), lstRelations);
		}
	}
	
	global void finish(Database.BatchableContext BC) {
		
	}
	
}