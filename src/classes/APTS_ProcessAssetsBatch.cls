/*******************************************************************************************
Name            : APTS_ProcessAssetsBatch
Created By      : Kushal Bhalodiya
Created Date    : 03/07/2019
Description     : Batch to update the Asset Line Items and Physical Assets on Agreement Activation.
Version history : v1.0 - Created.
Test Class      : APTS_AgreementTriggerHandlerTest
*********************************************************************************************/
global class APTS_ProcessAssetsBatch implements Database.Batchable<sObject> {
	
	public Set<ID> agreementIdSet;
	public Map<String, Id> agreementNoToIdMap;
	public Map<String, APTS_Agreement_PO_Details__c> agreementPODetailsMap;
	
	global APTS_ProcessAssetsBatch(Set<ID> agreementIdSet, Map<String, Id> agreementNoToIdMap, Map<String, APTS_Agreement_PO_Details__c> agreementPODetailsMap) {
		this.agreementIdSet = agreementIdSet;
		this.agreementNoToIdMap = agreementNoToIdMap;
		this.agreementPODetailsMap = agreementPODetailsMap;
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		String query = 'SELECT Id, APTS_relatedlist_agreement__c, Apttus_CMConfig__AgreementId__r.Apttus__Agreement_Number__c, ';
		query += 'APTS_Physical_Asset__r.PONumberMachines__c, APTS_Physical_Asset__r.PONumberRequiredMachines__c, ';
		query += 'APTS_Physical_Asset__r.PONumberTypeMachines__c, APTS_Physical_Asset__r.PONumberServices__c, ';
		query += 'APTS_Physical_Asset__r.PONumberRequiredServices__c, APTS_Physical_Asset__r.PONumberTypeServices__c, ';
        query += 'Apttus_CMConfig__AgreementId__c, APTS_Physical_Asset__c FROM Apttus_Config2__AssetLineItem__c ';
        query += 'WHERE Apttus_CMConfig__AgreementId__c IN: agreementIdSet';
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<Apttus_Config2__AssetLineItem__c> assetLineItemList) {
   		
   		APTS_CLMUtil.updateAssetsOnAgreementActivation(assetLineItemList, agreementIdSet, agreementNoToIdMap, agreementPODetailsMap);
	}

	global void finish(Database.BatchableContext BC) {
		
	}
}