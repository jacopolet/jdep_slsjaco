/**********************
  Purpose: 
  Revision History:
  #No     Name        Date        Purpose
  1.0     Nagavi      03/05/2018  Created the class to handle logics around frequency UOM Object
 ************************/
public with sharing class APTS_FreqConversionRateTriggerHandler implements ITriggerHandler {

	public class ApplicationException extends Exception { }
	private Static String EMPTY_STRING = ' ';

	/*@methodName- IsDisabled
	 *@description- method is used to prevent recursion
	 *@param- empty
	 *@return- boolean
	 */
	public Boolean isDisabled() {
		try {
			return(TriggerSettings__c.getInstance().FreqConversionRate__c == true ? false : true);
		} catch(Exception ex) { throw new ApplicationException(ex); }
	}

	/*@methodName- beforeInsert
	 *@description- method is used to call logic related to the beforeInsert event
	 *@param- List<SObject> newProductsList
	 *@return- void
	 */
	public void beforeInsert(List<SObject> newRecordsList) {
		try {
			//Need to be cleaned up as the logic was moved to product batch
			updateFreqConversionRate((List<Apttus_Config2__FrequencyConversionRate__c>) newRecordsList);
		} catch(Exception ex) { throw new ApplicationException(ex); }
	}

	/*@methodName- beforeUpdate
	 *@description- method is used to call logic related to the beforeUpdate event
	 *@param- List<SObject> newProductsList, Map<Id, SObject> newProductsMap, List<SObject> oldProductsList, Map<Id, SObject> oldProductsMap
	 *@return- void
	 */
	public void beforeUpdate(List<SObject> newRecordsList, Map<Id, SObject> newRecordsMap, List<SObject> oldRecordsList, Map<Id, SObject> oldRecordsMap) {
		try { } catch(Exception ex) { throw new ApplicationException(ex); }
	}

	/*@methodName- beforeDelete
	 *@description- method is used to call logic related to the beforeDelete event
	 *@param- List<SObject> oldProductsList, Map<Id, SObject> oldProductsMap 
	 *@return- void
	 */
	public void beforeDelete(List<SObject> oldRecordsList, Map<Id, SObject> oldRecordsMap) { }

	/*@methodName- afterInsert
	 *@description- method is used to call logic related to the afterInsert event
	 *@param- List<SObject> newProductsList, Map<Id, SObject> newProductsMap
	 *@return- void
	 */
	public void afterInsert(List<SObject> newRecordsList, Map<Id, SObject> newRecordsMap) {
		try {
			Set<Id> productIdSet = new Set<Id> ();
			Set<string> exclusionAccountList = new Set<String>();
			Set<Id> fifthLevelParentIdSet = new Set<Id> ();
			Map<Id,string> fifthLevelParentSAPCustomerIdMap = new Map<Id,string>();
			For(APTS_NetPriceExtAccountExclusionTable__mdt exlcAcc : [select id,label from APTS_NetPriceExtAccountExclusionTable__mdt where APTS_isActive__c = true]){
				exclusionAccountList.add(exlcAcc.Label);
			}
			System.debug('exclusionAccountList==========>'+exclusionAccountList);
			for (Apttus_Config2__FrequencyConversionRate__c newRec : (List<Apttus_Config2__FrequencyConversionRate__c>) newRecordsList) {
				if (newRec.Apttus_Config2__FromUom__c != NULL && newRec.Apttus_Config2__ToUom__c != NULL && newRec.Apttus_Config2__ConversionFactor__c != NULL) {
					if (!productIdSet.contains(newRec.Apttus_Config2__ProductId__c))
					{
						productIdSet.add(newRec.Apttus_Config2__ProductId__c);
					}
				}
			}
			System.debug('productIdSet========>'+productIdSet);
			Set<Id> accountSet = new Set<Id> ();
			For (Apttus__AgreementLineItem__c agrLine :[select 
														Apttus__AgreementId__r.Apttus__Account__r.Parent.parent.Parent.Parentid 
														from Apttus__AgreementLineItem__c 
														where Apttus__ProductId__c in :productIdSet and 
														Apttus__AgreementId__r.Apttus__Status_Category__c = :APTS_NetPriceExtraction.IN_EFFECT limit 50000]){
				System.debug('agrLine========>'+agrLine);
				if(agrLine.Apttus__AgreementId__r.Apttus__Account__r.Parent.parent.Parent.Parentid!=null){
					fifthLevelParentIdSet.add(agrLine.Apttus__AgreementId__r.Apttus__Account__r.Parent.parent.Parent.Parentid);
				}
			}
			if(!fifthLevelParentIdSet.IsEmpty()){
				For(Account acc : [select id,SAP_Customer_ID__c from Account where ID in : fifthLevelParentIdSet]){
					if(fifthLevelParentSAPCustomerIdMap.get(acc.id)==null){
						fifthLevelParentSAPCustomerIdMap.put(acc.id,acc.SAP_Customer_ID__c);
					}
				}
			}
			System.debug('fifthLevelParentSAPCustomerIdMap========>'+fifthLevelParentSAPCustomerIdMap);
			For (Apttus__AgreementLineItem__c agrLine :[select Apttus__AgreementId__r.Apttus__Account__c,
														Apttus__AgreementId__r.Apttus__Account__r.SAP_Customer_ID__c,
														Apttus__AgreementId__r.Apttus__Account__r.Parent.SAP_Customer_ID__c,
														Apttus__AgreementId__r.Apttus__Account__r.Parent.Parent.SAP_Customer_ID__c,
														Apttus__AgreementId__r.Apttus__Account__r.Parent.Parent.Parent.SAP_Customer_ID__c,
														Apttus__AgreementId__r.Apttus__Account__r.Parentid,
														Apttus__AgreementId__r.Apttus__Account__r.Parent.Parentid,
														Apttus__AgreementId__r.Apttus__Account__r.Parent.Parent.Parentid,
														Apttus__AgreementId__r.Apttus__Account__r.Parent.Parent.Parent.ParentId 
														from Apttus__AgreementLineItem__c where Apttus__ProductId__c in :productIdSet and Apttus__AgreementId__r.Apttus__Status_Category__c = :APTS_NetPriceExtraction.IN_EFFECT limit 50000])
			{
				String sapCustomerId;
				if(!fifthLevelParentSAPCustomerIdMap.isEmpty() 
					&& agrLine.Apttus__AgreementId__r.Apttus__Account__c!=null
					&& agrLine.Apttus__AgreementId__r.Apttus__Account__r.Parentid!=null
					&& agrLine.Apttus__AgreementId__r.Apttus__Account__r.Parent.Parentid!=null
					&& agrLine.Apttus__AgreementId__r.Apttus__Account__r.Parent.Parent.Parentid!=null
					&& agrLine.Apttus__AgreementId__r.Apttus__Account__r.Parent.Parent.Parent.ParentId!=null 
					&& fifthLevelParentSAPCustomerIdMap.get(agrLine.Apttus__AgreementId__r.Apttus__Account__r.Parent.Parent.Parent.ParentId)!=null){
						sapCustomerId = fifthLevelParentSAPCustomerIdMap.get(agrLine.Apttus__AgreementId__r.Apttus__Account__r.Parent.Parent.Parent.ParentId);
				}
				System.debug('sapCustomerId========>'+sapCustomerId);
				System.debug('agrLine.Apttus__AgreementId__r.Apttus__Account__c========>'+agrLine.Apttus__AgreementId__r.Apttus__Account__c);
				System.debug('agrLine.Apttus__AgreementId__r.Apttus__Account__r.SAP_Customer_ID__c========>'+agrLine.Apttus__AgreementId__r.Apttus__Account__r.SAP_Customer_ID__c);
				System.debug('agrLine.Apttus__AgreementId__r.Apttus__Account__r.Parent.SAP_Customer_ID__c========>'+agrLine.Apttus__AgreementId__r.Apttus__Account__r.Parent.SAP_Customer_ID__c);
				System.debug('agrLine.Apttus__AgreementId__r.Apttus__Account__r.Parent.Parent.SAP_Customer_ID__c========>'+agrLine.Apttus__AgreementId__r.Apttus__Account__r.Parent.Parent.SAP_Customer_ID__c);
				System.debug('agrLine.Apttus__AgreementId__r.Apttus__Account__r.Parent.Parent.Parent.SAP_Customer_ID__c========>'+agrLine.Apttus__AgreementId__r.Apttus__Account__r.Parent.Parent.Parent.SAP_Customer_ID__c);
				if(!accountSet.contains(agrLine.Apttus__AgreementId__r.Apttus__Account__c) &&
					((SAPCustomerId!=NULL
					&& !exclusionAccountList.contains(SAPCustomerId)) &&
					(agrLine.Apttus__AgreementId__r.Apttus__Account__c!=null
					&& agrLine.Apttus__AgreementId__r.Apttus__Account__r.Parentid!=null
					&& agrLine.Apttus__AgreementId__r.Apttus__Account__r.Parent.Parentid!=null
					&& agrLine.Apttus__AgreementId__r.Apttus__Account__r.Parent.Parent.Parentid!=null 
					&& agrLine.Apttus__AgreementId__r.Apttus__Account__r.Parent.Parent.Parent.SAP_Customer_ID__c!=null 
					&& !exclusionAccountList.contains(agrLine.Apttus__AgreementId__r.Apttus__Account__r.Parent.Parent.Parent.SAP_Customer_ID__c)) &&
					(agrLine.Apttus__AgreementId__r.Apttus__Account__c!=null
					&& agrLine.Apttus__AgreementId__r.Apttus__Account__r.Parentid!=null
					&& agrLine.Apttus__AgreementId__r.Apttus__Account__r.Parent.Parentid!=null
					&& agrLine.Apttus__AgreementId__r.Apttus__Account__r.Parent.Parent.SAP_Customer_ID__c!=null 
					&& !exclusionAccountList.contains(agrLine.Apttus__AgreementId__r.Apttus__Account__r.Parent.Parent.SAP_Customer_ID__c)) &&
					(agrLine.Apttus__AgreementId__r.Apttus__Account__c!=null
					&& agrLine.Apttus__AgreementId__r.Apttus__Account__r.Parentid!=null
					&& agrLine.Apttus__AgreementId__r.Apttus__Account__r.Parent.SAP_Customer_ID__c!=null
					&& !exclusionAccountList.contains(agrLine.Apttus__AgreementId__r.Apttus__Account__r.Parent.SAP_Customer_ID__c)) &&
					(agrLine.Apttus__AgreementId__r.Apttus__Account__c!=null
					&& agrLine.Apttus__AgreementId__r.Apttus__Account__r.SAP_Customer_ID__c!=null
					&& !exclusionAccountList.contains(agrLine.Apttus__AgreementId__r.Apttus__Account__r.SAP_Customer_ID__c)))){
						accountSet.add(agrLine.Apttus__AgreementId__r.Apttus__Account__c);
				}
				/*if(	agrLine.Apttus__AgreementId__r.Apttus__Account__c!=null
					&& !accountSet.contains(agrLine.Apttus__AgreementId__r.Apttus__Account__c)
					&& agrLine.Apttus__AgreementId__r.Apttus__Account__r.Parentid!=null
					&& agrLine.Apttus__AgreementId__r.Apttus__Account__r.Parent.Parentid!=null
					&& agrLine.Apttus__AgreementId__r.Apttus__Account__r.Parent.Parent.SAP_Customer_ID__c!=null 
					&& !exclusionAccountList.contains(agrLine.Apttus__AgreementId__r.Apttus__Account__r.Parent.Parent.SAP_Customer_ID__c) && !exlcusionIndicator){
					accountSet.add(agrLine.Apttus__AgreementId__r.Apttus__Account__c);
					exlcusionIndicator=true;
				}
				if(!accountSet.contains(agrLine.Apttus__AgreementId__r.Apttus__Account__c)
					&& agrLine.Apttus__AgreementId__r.Apttus__Account__c!=null
					&& agrLine.Apttus__AgreementId__r.Apttus__Account__r.Parentid!=null
					&& agrLine.Apttus__AgreementId__r.Apttus__Account__r.Parent.SAP_Customer_ID__c!=null
					&& !exclusionAccountList.contains(agrLine.Apttus__AgreementId__r.Apttus__Account__r.Parent.SAP_Customer_ID__c) && !exlcusionIndicator){
					accountSet.add(agrLine.Apttus__AgreementId__r.Apttus__Account__c);
					exlcusionIndicator=true;
				}
				if(!accountSet.contains(agrLine.Apttus__AgreementId__r.Apttus__Account__c)
					&& agrLine.Apttus__AgreementId__r.Apttus__Account__c!=null
					&& agrLine.Apttus__AgreementId__r.Apttus__Account__r.SAP_Customer_ID__c!=null
					&& !exclusionAccountList.contains(agrLine.Apttus__AgreementId__r.Apttus__Account__r.SAP_Customer_ID__c) && !exlcusionIndicator){
					accountSet.add(agrLine.Apttus__AgreementId__r.Apttus__Account__c);
				}*/
			}
			if (accountSet.size() > 0) {
				APTS_NetPriceExtraction.updateNetPriceExtraction(accountSet);
			}
		} catch(DmlException ex) { throw new ApplicationException(ex); }
	}

	/*@methodName- afterUpdate
	 *@description- method is used to call logic related to the afterUpdate event
	 *@param- List<SObject> newProductsList , Map<Id, SObject> newProductsMap, List<SObject> oldProductsList, Map<Id, SObject> oldProductsMap
	 *@return- void
	 */
	public void afterUpdate(List<SObject> newRecordsList, Map<Id, SObject> newRecordsMap, List<SObject> oldRecordsList, Map<Id, SObject> oldRecordsMap) {
		try {
			Map<Id, Apttus_Config2__FrequencyConversionRate__c> oldRecMap = (Map<Id, Apttus_Config2__FrequencyConversionRate__c>) oldRecordsMap;
			Set<Id> productIdSet = new Set<Id> ();
			Set<string> exclusionAccountList = new Set<String>();
			Set<Id> fifthLevelParentIdSet = new Set<Id> ();
			Map<Id,string> fifthLevelParentSAPCustomerIdMap = new Map<Id,string>();
			For(APTS_NetPriceExtAccountExclusionTable__mdt exlcAcc : [select id,label from APTS_NetPriceExtAccountExclusionTable__mdt where APTS_isActive__c = true]){
				exclusionAccountList.add(exlcAcc.Label);
			}
			for (Apttus_Config2__FrequencyConversionRate__c newRec : (List<Apttus_Config2__FrequencyConversionRate__c>) newRecordsList) {
				if (newRec!=null && oldRecMap.get(newRec.Id) !=null &&(newRec.Apttus_Config2__FromUom__c != oldRecMap.get(newRec.Id).Apttus_Config2__FromUom__c || newRec.Apttus_Config2__ToUom__c != oldRecMap.get(newRec.Id).Apttus_Config2__ToUom__c || newRec.Apttus_Config2__ConversionFactor__c != oldRecMap.get(newRec.Id).Apttus_Config2__ConversionFactor__c)) {
					if (!productIdSet.contains(newRec.Apttus_Config2__ProductId__c))
					{
						productIdSet.add(newRec.Apttus_Config2__ProductId__c);
					}
				}
			}
			Set<Id> accountSet = new Set<Id> ();
			For (Apttus__AgreementLineItem__c agrLine :[select 
														Apttus__AgreementId__r.Apttus__Account__r.Parent.parent.Parent.Parentid 
														from Apttus__AgreementLineItem__c 
														where Apttus__ProductId__c in :productIdSet and 
														Apttus__AgreementId__r.Apttus__Status_Category__c = :APTS_NetPriceExtraction.IN_EFFECT limit 50000]){
				if(agrLine.Apttus__AgreementId__r.Apttus__Account__r.Parent.parent.Parent.Parentid!=null){
					fifthLevelParentIdSet.add(agrLine.Apttus__AgreementId__r.Apttus__Account__r.Parent.parent.Parent.Parentid);
				}
			}
			if(!fifthLevelParentIdSet.IsEmpty()){
				For(Account acc : [select id,SAP_Customer_ID__c from Account where ID in : fifthLevelParentIdSet]){
					if(fifthLevelParentSAPCustomerIdMap.get(acc.id)==null){
						fifthLevelParentSAPCustomerIdMap.put(acc.id,acc.SAP_Customer_ID__c);
					}
				}
			}
			For (Apttus__AgreementLineItem__c agrLine :[select Apttus__AgreementId__r.Apttus__Account__c,
																Apttus__AgreementId__r.Apttus__Account__r.SAP_Customer_ID__c,
																Apttus__AgreementId__r.Apttus__Account__r.parent.SAP_Customer_ID__c,
																Apttus__AgreementId__r.Apttus__Account__r.parent.parent.SAP_Customer_ID__c,
																Apttus__AgreementId__r.Apttus__Account__r.Parent.Parent.Parent.SAP_Customer_ID__c,
																Apttus__AgreementId__r.Apttus__Account__r.Parentid,
																Apttus__AgreementId__r.Apttus__Account__r.Parent.Parentid,
																Apttus__AgreementId__r.Apttus__Account__r.Parent.Parent.Parentid,
																Apttus__AgreementId__r.Apttus__Account__r.Parent.Parent.Parent.ParentId 
																from Apttus__AgreementLineItem__c 
																where Apttus__ProductId__c in :productIdSet and 
																Apttus__AgreementId__r.Apttus__Status_Category__c = :APTS_NetPriceExtraction.IN_EFFECT limit 50000])
			{
				String sapCustomerId;
				if(!fifthLevelParentSAPCustomerIdMap.isEmpty() 
					&& agrLine.Apttus__AgreementId__r.Apttus__Account__c!=null
					&& agrLine.Apttus__AgreementId__r.Apttus__Account__r.Parentid!=null
					&& agrLine.Apttus__AgreementId__r.Apttus__Account__r.Parent.Parentid!=null
					&& agrLine.Apttus__AgreementId__r.Apttus__Account__r.Parent.Parent.Parentid!=null
					&& agrLine.Apttus__AgreementId__r.Apttus__Account__r.Parent.Parent.Parent.ParentId!=null 
					&& fifthLevelParentSAPCustomerIdMap.get(agrLine.Apttus__AgreementId__r.Apttus__Account__r.Parent.Parent.Parent.ParentId)!=null){
						sapCustomerId = fifthLevelParentSAPCustomerIdMap.get(agrLine.Apttus__AgreementId__r.Apttus__Account__r.Parent.Parent.Parent.ParentId);
				}
				if (!accountSet.contains(agrLine.Apttus__AgreementId__r.Apttus__Account__c) 
					&& !exclusionAccountList.contains(agrLine.Apttus__AgreementId__r.Apttus__Account__r.SAP_Customer_ID__c) 
					&& !exclusionAccountList.contains(agrLine.Apttus__AgreementId__r.Apttus__Account__r.Parent.SAP_Customer_ID__c) 
					&& !exclusionAccountList.contains(agrLine.Apttus__AgreementId__r.Apttus__Account__r.Parent.Parent.SAP_Customer_ID__c) 
					&& !exclusionAccountList.contains(agrLine.Apttus__AgreementId__r.Apttus__Account__r.Parent.Parent.Parent.SAP_Customer_ID__c)
					&& !exclusionAccountList.contains(SAPCustomerId)){
					accountSet.add(agrLine.Apttus__AgreementId__r.Apttus__Account__c);
				}
			}
			if (accountSet.size() > 0) {
				APTS_NetPriceExtraction.updateNetPriceExtraction(accountSet);
			}
		} catch(DmlException ex) { throw new ApplicationException(ex); }
	}

	/*@methodName- afterDelete
	 *@description- method is used to call logic related to the afterDelete event
	 *@param- List<SObject> oldProductsList, Map<Id, SObject> oldProductsMap 
	 *@return- void
	 */
	public void afterDelete(List<SObject> oldRecordsList, Map<Id, SObject> oldRecordsMap) { }

	/*@methodName- afterUndelete
	 *@description- method is used to call logic related to the afterUndelete event
	 *@param- List<SObject> newProductsList, Map<Id, SObject> newProductsMap
	 *@return- void
	 */
	public void afterUndelete(List<SObject> newRecordsList, Map<Id, SObject> newRecordsMap) { }

	/*************** Business Logic Methods ***********************/


	/** Method Name : updateFreqConversionRate ---  Need to be cleaned up as the logic was moved to product batch
	 * Description : Method to update the frequency conversion rate UOM
	 **/
	public static void updateFreqConversionRate(List<Apttus_Config2__FrequencyConversionRate__c> freqConversionList) {

		Set<String> relatedProductCodes = new Set<String> ();
		List<Product2> relatedProductList = new List<Product2> ();
		Map<String, Product2> productCodeProductMap = new Map<String, Product2> ();

		for (Apttus_Config2__FrequencyConversionRate__c freqConv : freqConversionList) {
			relatedProductCodes.add(freqConv.APTS_ProductCode__c);
		}

		if (!relatedProductCodes.IsEmpty()) {
			for (Product2 prod :[Select Id, ProductCode from Product2 where ProductCode IN :relatedProductCodes limit 50000]) {
				productCodeProductMap.put(prod.ProductCode, prod);

			}
		}
		for (Apttus_Config2__FrequencyConversionRate__c freqConversion : freqConversionList) {
			if (productCodeProductMap.containsKey(freqConversion.APTS_ProductCode__c)) {
				freqConversion.Apttus_Config2__ProductId__c = productCodeProductMap.get(freqConversion.APTS_ProductCode__c).Id;

			}
			if (freqConversion.APTS_Numerator__c > 0 && freqConversion.APTS_Denominator__c > 0) {
				freqConversion.Apttus_Config2__ConversionFactor__c = (freqConversion.APTS_Numerator__c / freqConversion.APTS_Denominator__c);
			}
		}
	}
}