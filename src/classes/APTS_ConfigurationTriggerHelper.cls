/*************************************************************
@Name: APTS_CategoryBasedAdjustmentsHelper
@Author: Raul Orozco
@CreateDate: 04-02-2019
@Description: Helper class for APTS_ConfigurationTriggerHandler. 
@UsedBy: APTS_ConfigurationTriggerHandler
******************************************************************/
public without sharing class APTS_ConfigurationTriggerHelper {
	public static void deleteRecoverCERRecords(Set<Id> setProdConfigId){
		Id accountId;
		Id agreementId;

		//Get type of agreement and and LIs for each product configuration 
		List<Apttus_Config2__ProductConfiguration__c> lstPC =
		[
			SELECT Id,
			Apttus_CMConfig__AgreementId__r.APTS_Agreement_Request__c,
			Apttus_Config2__AccountId__c,
			Apttus_CMConfig__AgreementId__c,
			(SELECT Id FROM Apttus_Config2__LineItems__r)
			FROM Apttus_Config2__ProductConfiguration__c
			WHERE Id IN :setProdConfigId
		];

		system.debug(LoggingLevel.ERROR, 'lstPC:::::::::::' + lstPC);

		Map<Id,String> mapPCTypeAgreement = new Map<Id,String>();

		//Create set of LI ids and fill map of PC/type of agreement
		Set<Id> setLIId = new Set<Id>();

		for(Apttus_Config2__ProductConfiguration__c currentPC : lstPC){
			mapPCTypeAgreement.put(currentPC.Id,currentPC.Apttus_CMConfig__AgreementId__r.APTS_Agreement_Request__c);
			
			for(Apttus_Config2__LineItem__c currentLI : currentPC.Apttus_Config2__LineItems__r){
				setLIId.add(currentLI.Id);
			}
			
			if(accountId == null){
				accountId = currentPC.Apttus_Config2__AccountId__c;
			}

			if(agreementId == null){
				agreementId = currentPC.Apttus_CMConfig__AgreementId__c;
			}		
		}

		system.debug(LoggingLevel.ERROR, 'mapPCTypeAgreement:::::::::::' + mapPCTypeAgreement); 

		//Get pending CER records
		if(setLIId.size() > 0){
			List<APTS_Contract_Entitlement_Repository__c> lstCER = 
			[
				SELECT Id, 
				APTS_Pending_Line_Item__c,
				APTS_CER_from_Parent__c,
				APTS_Contributing_Agreement_Level__c,
				APTS_Pending_Line_Item__r.Apttus_Config2__ConfigurationId__c,
				APTS_Category_Discount_Amendment__c,
				APTS_CategoryCER__c,
				APTS_Type__c,
				APTS_Sub_Type__c,
				APTS_Sub_Category__c,
				APTS_Sub_Sub_Category__c,
				APTS_Sold_to_Party__c,
				APTS_Product__c
				FROM APTS_Contract_Entitlement_Repository__c 
				WHERE APTS_Pending_Line_Item__c in :setLIId
			];

			system.debug(LoggingLevel.ERROR, 'lstCER:::::::::::' + lstCER);

			List<APTS_Contract_Entitlement_Repository__c> lstCERDelete = new List<APTS_Contract_Entitlement_Repository__c>();
			List<APTS_Contract_Entitlement_Repository__c> lstCERRecover = new List<APTS_Contract_Entitlement_Repository__c>();
			List<APTS_Contract_Entitlement_Repository__c> lstCERRecoverAmendment = new List<APTS_Contract_Entitlement_Repository__c>();

			//Delete or recover CER record depending of validations
			if(lstCER.size() > 0)
			{
				//If not CER from parent add to deletion list
				for(APTS_Contract_Entitlement_Repository__c currentCER : lstCER){
					system.debug(LoggingLevel.ERROR, 'currentCER:::::::::::' + currentCER);
					if(!currentCER.APTS_CER_from_Parent__c){
						lstCERDelete.add(currentCER);
					}else{
						system.debug(LoggingLevel.ERROR, 'key:::::::::::' + currentCER.APTS_Pending_Line_Item__r.Apttus_Config2__ConfigurationId__c);
						system.debug(LoggingLevel.ERROR, 'contains key:::::::::::' + mapPCTypeAgreement.containsKey(currentCER.APTS_Pending_Line_Item__r.Apttus_Config2__ConfigurationId__c));
						system.debug(LoggingLevel.ERROR, 'map value:::::::::::' + mapPCTypeAgreement.get(currentCER.APTS_Pending_Line_Item__r.Apttus_Config2__ConfigurationId__c));
						//Validate if the agreement is amendment or not
						if(mapPCTypeAgreement.containsKey(currentCER.APTS_Pending_Line_Item__r.Apttus_Config2__ConfigurationId__c)){
							if(mapPCTypeAgreement.get(currentCER.APTS_Pending_Line_Item__r.Apttus_Config2__ConfigurationId__c) == 'Amendment'){
								if(currentCER.APTS_Category_Discount_Amendment__c && !currentCER.APTS_CER_from_Parent__c){
									lstCERDelete.add(currentCER);
								}else{
									lstCERRecoverAmendment.add(currentCER);
								}
							}else{
								lstCERRecover.add(currentCER);
							}
						}						
					}
				}

				system.debug(LoggingLevel.ERROR, 'lstCERDelete:::::::::::' + lstCERDelete);
				system.debug(LoggingLevel.ERROR, 'lstCERRecoverAmendment:::::::::::' + lstCERRecoverAmendment);
				system.debug(LoggingLevel.ERROR, 'lstCERRecover:::::::::::' + lstCERRecover);

				//Recover records
				if(lstCERRecover.size() > 0){
					Boolean recoveryResult = recoverCERRecordParent(lstCERRecover, accountId);
					system.debug(LoggingLevel.ERROR,'Result of records recovery>>>>>>>>>>>' + recoveryResult);
				}

				if(lstCERRecoverAmendment.size() > 0){
					Boolean recoveryResultAmendment = recoverCERRecordParentAmendment(lstCERRecoverAmendment, accountId);
					system.debug(LoggingLevel.ERROR,'Result of records recovery amendment>>>>>>>>>>>' + recoveryResultAmendment);
				}

				//Delete records
				if(lstCERDelete.size() > 0){
					delete lstCERDelete;
				}				
			}
		}	
	}

	public static Boolean recoverCERRecordParent(List<APTS_Contract_Entitlement_Repository__c> lstCER, Id accountId){
        Boolean cerRecordRecovered = false;

		//Get parent CER Record info
        Id parentAccountId = APTS_CERUtility.getCerRecordAccountForRelatedAccount(accountId,false);

		//Get list of CER object fields
		String strFields = '';

		Map <String, Schema.SObjectField> fieldMap = APTS_Contract_Entitlement_Repository__c.sObjectType.getDescribe().fields.getMap();

		for(Schema.SObjectField sfield : fieldMap.Values())
		{
			schema.describefieldresult dfield = sfield.getDescribe();
			if(dfield.isCustom() && dfield.isUpdateable()){
				strFields += dfield.getname() + ',';
			}
		}

		strFields = strFields.removeEnd(',');

		//Variables
		Set<String> setCategory = new Set<String>();
		Set<String> setsubCategory = new Set<String>();
		Set<String> setsubSubCategory = new Set<String>();
		Set<String> setType = new Set<String>();
		Set<String> setSubType = new Set<String>();
		List<APTS_Contract_Entitlement_Repository__c> lstNewCERRecord = new List<APTS_Contract_Entitlement_Repository__c>();
		List<APTS_Contract_Entitlement_Repository__c> lstDeleteCER = new List<APTS_Contract_Entitlement_Repository__c>();
		APTS_Contract_Entitlement_Repository__c newCERRecord;

		//Loop through list of CER records
		for(APTS_Contract_Entitlement_Repository__c currentCER : lstCER){
			//Check if the CER record was originally created with contributing level father, if that is the case recover original CER record
			if(currentCER.APTS_CER_from_Parent__c && !currentCER.APTS_Category_Discount_Amendment__c){
				setCategory.add(currentCER.APTS_CategoryCER__c);
				setSubCategory.add(currentCER.APTS_Sub_Category__c);
				setSubSubCategory.add(currentCER.APTS_Sub_Sub_Category__c);
				setType.add(currentCER.APTS_Type__c);
				setSubType.add(currentCER.APTS_Sub_Type__c);
			}
		}

		//Get original CER records
		String strQuery = 'SELECT ' + strFields + ' FROM APTS_Contract_Entitlement_Repository__c ' +
		'WHERE APTS_Sold_to_Party__c = :parentAccountId ' +
		'AND APTS_Type__c IN :setType ' +
		'AND APTS_Sub_Type__c IN :setSubType ' +
		'AND APTS_CategoryCER__c IN :setCategory ';

		if(setSubCategory.size() > 0){
			strQuery += ' AND APTS_Sub_Category__c IN :setSubCategory  ';
		}

		if(setSubSubCategory.size() > 0){
			strQuery += ' AND APTS_Sub_Sub_Category__c IN :setSubSubCategory  ';
		}

		List<APTS_Contract_Entitlement_Repository__c> lstCERParent = Database.query(strQuery);

		System.debug(LoggingLevel.ERROR,'List CER Parent:::::::::' + lstCERParent);

		if(lstCERParent.size() > 0){
			//Loop through CER parent records and create new records to insert
			for(APTS_Contract_Entitlement_Repository__c currentCERParent : lstCERParent){
				System.debug(LoggingLevel.ERROR,'currentCERParent:::::::::' + currentCERParent);
				//Find the corresponding CER record to avoid creation of extra CER records
				for(APTS_Contract_Entitlement_Repository__c currentCER : lstCER){
					System.debug(LoggingLevel.ERROR,'currentCER:::::::::' + currentCER);
					if(currentCERParent.APTS_Type__c == currentCER.APTS_Type__c &&
					currentCERParent.APTS_Sub_Type__c == currentCER.APTS_Sub_Type__c &&
					currentCERParent.APTS_CategoryCER__c == currentCER.APTS_CategoryCER__c &&
					currentCERParent.APTS_Sub_Category__c == currentCER.APTS_Sub_Category__c &&
					currentCERParent.APTS_Sub_Sub_Category__c == currentCER.APTS_Sub_Sub_Category__c){
						newCERRecord = currentCERParent.clone(false, false, false, false);
						newCERRecord.APTS_Sold_to_Party__c = currentCER.APTS_Sold_to_Party__c;
						newCERRecord.APTS_Is_Pending__c = true;
						
						//Set the contributing level one level up as the record was originally
						if(newCERRecord.APTS_Contributing_Agreement_Level__c == 'Child'){
							newCERRecord.APTS_Contributing_Agreement_Level__c = 'Parent';
						}else if(newCERRecord.APTS_Contributing_Agreement_Level__c == 'Parent'){
							newCERRecord.APTS_Contributing_Agreement_Level__c = 'Grandparent';
						}else if(newCERRecord.APTS_Contributing_Agreement_Level__c == 'Grandparent'){
							newCERRecord.APTS_Contributing_Agreement_Level__c = 'Buying Group';
						}

						//Add CER Parent Record
						lstNewCERRecord.add(newCERRecord);
						lstDeleteCER.add(currentCER);
					}
				}
			}

			System.debug(LoggingLevel.ERROR,'lstNewCERRecord:::::::::' + lstNewCERRecord);

			//Insert re-created records
			if(lstNewCERRecord.size() > 0){
				insert lstNewCERRecord;
				delete lstDeleteCER;

				//Set boolean value to identify that CER records were recovered
				cerRecordRecovered = true;
			}
		}

        return cerRecordRecovered;
    }

	public static Boolean recoverCERRecordParentAmendment(List<APTS_Contract_Entitlement_Repository__c> lstCER, Id accountId){
        Boolean cerRecordRecovered = false;

		Set<String> setCategory2 = new Set<String>();
		Set<String> setSubCategory2 = new Set<String>();
		Set<String> setSubSubCategory2 = new Set<String>();
		Set<String> setType2 = new Set<String>();
		Set<String> setSubType2 = new Set<String>();
		Id categoryProductId;
		Boolean scenario2 = false;
		List<APTS_Contract_Entitlement_Repository__c> lstCERScenario2 = new List<APTS_Contract_Entitlement_Repository__c>();
		List<APTS_Contract_Entitlement_Repository__c> lstDeleteCER = new List<APTS_Contract_Entitlement_Repository__c>();

		//Loop through list of CER records
		for(APTS_Contract_Entitlement_Repository__c currentCER : lstCER){
			if(categoryProductId == null){
				categoryProductId = currentCER.APTS_Product__c;
			}

			setCategory2.add(currentCER.APTS_CategoryCER__c);
			setSubCategory2.add(currentCER.APTS_Sub_Category__c);
			setSubSubCategory2.add(currentCER.APTS_Sub_Sub_Category__c);
			setType2.add(currentCER.APTS_Type__c);
			setSubType2.add(currentCER.APTS_Sub_Type__c);
			scenario2 = true;
			lstCERScenario2.add(currentCER);
		}

		if(scenario2){
			List<APTS_Contract_Entitlement_Repository__c> lstCEROriginal =
			APTS_CategoryBasedAdjustmentsHelper.getCERRecord(accountId, categoryProductId, setCategory2, setSubCategory2, 
			setSubSubCategory2, setType2, setSubType2);

			system.debug(LoggingLevel.ERROR,'lstCEROriginal>>>>>>>>>>>' + lstCEROriginal);

			for(APTS_Contract_Entitlement_Repository__c currentCEROriginal : lstCEROriginal){
				system.debug(LoggingLevel.ERROR,'currentCEROriginal>>>>>>>>>>>' + currentCEROriginal);
				//Find the corresponding CER record to avoid creation of extra CER records
				for(APTS_Contract_Entitlement_Repository__c currentCER : lstCERScenario2){
					system.debug(LoggingLevel.ERROR,'currentCER scenario2>>>>>>>>>>>' + currentCER);
					if(currentCEROriginal.APTS_Type__c == currentCER.APTS_Type__c &&
					currentCEROriginal.APTS_Sub_Type__c == currentCER.APTS_Sub_Type__c &&
					currentCEROriginal.APTS_CategoryCER__c == currentCER.APTS_CategoryCER__c &&
					currentCEROriginal.APTS_Sub_Category__c == currentCER.APTS_Sub_Category__c &&
					currentCEROriginal.APTS_Sub_Sub_Category__c == currentCER.APTS_Sub_Sub_Category__c){
						currentCEROriginal.APTS_CER_Changed_Amendment__c = false;

						//Add CER to delete
						lstDeleteCER.add(currentCER);
					}
				}
			}

			update lstCEROriginal;			
			cerRecordRecovered = true; 
		}

		if(lstDeleteCER.size() > 0){
			delete lstDeleteCER;
		}	
        
		return cerRecordRecovered;
    }
}