public without sharing class SM_AccountLocationUtil {
    //Alvin Lomod - check if SAP related fields were changed
    //private static Map<Id, Boolean> SAPRelatedFieldChanged = new Map<Id, Boolean>();
	public static Integration_Log__c CreateIntegrationLogForAgreement(Id agreeId, Id accLocId){
        Integration_Log__c iLog = new Integration_Log__c();
		if(accLocId != null){
            iLog.Object_Id__c = accLocId;
            iLog.Object__c = 'Account Location';
            iLog.AccountLocation__c = accLocId;
            iLog.Integration_Status__c = INT_Constants.INITIAL;
            iLog.Agreement__c = agreeId;
        }

        return iLog;
    }
     
    public static void changeFieldValue(Set<Apttus_Config2__AccountLocation__c> accountLocs, Map<Id, Apttus_Config2__AccountLocation__c> oldAccountMap, Set<String> EPIfieldSet, Map<String, String> filteredAccountLocFieldMap,  Map<String, String> filteredSelectedAccountLocFieldMap) {
        User userRec;
        userRec = [Select Id, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
        Boolean updateRequest = false;
        Id recTypeIdAccountLocationValidation = Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get('Account Location Validation').getRecordTypeId();
        for (Apttus_Config2__AccountLocation__c accLoc : accountLocs) {
            if (userRec.Profile.Name <> 'JDE-Integration-SAP') {
                //Check if EPI fields were also updated when SAP related fields were updated
                Apttus_Config2__AccountLocation__c oldAl = (Apttus_Config2__AccountLocation__c)oldAccountMap.get(accLoc.Id);
                Set<String> changedEPIFieldSet  = new Set<String>();
                for(string s: EPIfieldSet)
                {
                    if(accLoc.get(s) != oldAl.get(s))
                    {
                        changedEPIFieldSet.add(s);//adding fields whose value changed
                    }
                }
                
                if(accLoc.Copy_of_Parent_Account__c){
                    updateRequest = updateFields(accLoc, oldAccountMap.get(accLoc.Id), filteredSelectedAccountLocFieldMap);
                }  else{
                    updateRequest = updateFields(accLoc, oldAccountMap.get(accLoc.Id), filteredAccountLocFieldMap);
                    if(accLoc.SAP_Customer_ID__c != oldAccountMap.get(accLoc.Id).SAP_Customer_ID__c){
                        accLoc.RecordTypeId = recTypeIdAccountLocationValidation;
                        accLoc.EPI_Field_Updated__c = true;
                    }
                }
                if(updateRequest){
                    if(!changedEPIFieldSet.isEmpty()){
                        accLoc.EPI_Field_Updated__c = true;
                    }
                    if (accLoc.RecordTypeId == SM_Constants.recordTypeIdAccountLocation){
                        accLoc.RecordTypeId = recTypeIdAccountLocationValidation;
                    }
                }
                
            }
            
        }
    }
    
    private static Boolean updateFields(Apttus_Config2__AccountLocation__c accloc, Apttus_Config2__AccountLocation__c oldAccLoc, Map<String, String> mapOfFields) {
        Boolean updateRequestHit = false;
        for(String fieldname : mapOfFields.keySet()) {
            if((fieldname == 'Delivery_Block_Reason__c' || fieldname == 'Picking_list_text__c' || fieldname == 'Delivery_text__c') && accLoc.get(fieldname) == null){
                accLoc.put(mapOffields.get(fieldname), 'NULL');
                accLoc.put(fieldname, oldAccLoc.get(fieldname));
            } else if (fieldname == 'Region_API_Code__c') {
                accLoc.put(mapOffields.get(fieldname),  accLoc.get(fieldname));
            } else {
                accLoc.put(mapOffields.get(fieldname),  accLoc.get(fieldname));
                accLoc.put(fieldname, oldAccLoc.get(fieldname));
            }
            updateRequestHit = true;
            //SAPRelatedFieldChanged.put(accLoc.Id,true);
        }
        
        return updateRequestHit;
    } 
    
    public static void createIntegLog(Set<Apttus_Config2__AccountLocation__c> newList, Map<Id, Apttus_Config2__AccountLocation__c> oldRecordMap, Boolean SAPfieldSet, Boolean EPIfieldSet) {
        Id recTypeIdAccountLocation = Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get('Account Location').getRecordTypeId();
        Id recTypeIdAccountLocationRO = Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get('Account Location RO').getRecordTypeId();
        Id recTypeIdAccountLocationValidation = Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get('Account Location Validation').getRecordTypeId();
        Id recTypeIdPromotionRequested = Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get('Promotion Requested').getRecordTypeId();
        Map<String, Boolean> acctLocDigital = UserDAO.digitalIntegrationInformation('Account Location');
        //Checker if an Integration Log for SAP is already created
        Boolean SAPiLogCreated = false;
        List<Integration_Log__c> integLogsToInsertList = new List<Integration_Log__c>();
        for(Apttus_Config2__AccountLocation__c a: newList)
        {
            SAPiLogCreated = false;
            if(oldRecordMap == null || oldRecordMap.isEmpty()){
                if(a.RecordTypeId == recTypeIdAccountLocation || a.RecordTypeId == recTypeIdAccountLocationRO){
                    if(a.SAP_Customer_ID__c != null && a.Address_Validation__c == 'Valid'){
                           integLogsToInsertList.add(new Integration_Log__c(Object_Id__c = a.Id, 
                                                                            Object__c = INT_Constants.ACCOUNT_LOCATION,
                                                                            Account__c = a.Apttus_Config2__AccountId__c, 
                                                                            AccountLocation__c = a.Id));
                           
                           SAPiLogCreated = true;
                    }
                    if(SAPiLogCreated == false && a.Address_Validation__c == 'Valid' && !a.SAP_PO_Updated__c && a.Batch_Import_Flag__c == false && acctLocDigital.get(a.Mini_Sales_Organization__c)){
                        integLogsToInsertList.add(new Integration_Log__c(Object_Id__c = a.Id, 
                                                                        Object__c = 'Account Location Digital',
                                                                        Integration_Status__c = INT_Constants.INITIAL,
                                                                        AccountLocation__c = a.Id));
                           
                   }
                }//end of recordtype check
            } else {
                Apttus_Config2__AccountLocation__c oldAl = oldRecordMap.get(a.Id);
                if((a.SAP_Customer_ID__c != oldAl.SAP_Customer_ID__c || a.Address_Validation__c != oldAl.Address_Validation__c || SAPfieldSet) &&  a.SAP_Customer_ID__c != null && a.Address_Validation__c == 'Valid' && (oldAL.RecordTypeId != recTypeIdAccountLocationValidation && oldAL.RecordTypeId != recTypeIdPromotionRequested)){
                       
                       integLogsToInsertList.add(new Integration_Log__c(Object_Id__c = a.Id, 
                                                                        Object__c = INT_Constants.ACCOUNT_LOCATION, 
                                                                        Account__c = a.Apttus_Config2__AccountId__c, 
                                                                        AccountLocation__c = a.Id));
                       
                       SAPiLogCreated = true;
                }
                
                //This is for Copy of Parent ALs. When the parent Account's address is change, transfer the values to default AL without creating any iLogs
                Boolean CreateEPI = true;
                // if(a.Copy_of_Parent_Account__c &&
                //   (a.Shipping_Street_Only__c != oldAL.Shipping_Street_Only__c || 
                //   a.Shipping_House_Number__c != oldAL.Shipping_House_Number__c ||
                //   a.Apttus_Config2__City__c != oldAL.Apttus_Config2__City__c ||
                //   a.Apttus_Config2__Street__c != oldAL.Apttus_Config2__Street__c ||
                //   a.Apttus_Config2__State__c != oldAL.Apttus_Config2__State__c ||
                //   a.Apttus_Config2__PostalCode__c != oldAL.Apttus_Config2__PostalCode__c ||
                //   a.Apttus_Config2__Country__c != oldAL.Apttus_Config2__Country__c ||
                //   a.Shipping_Country_ISO__c != oldAL.Shipping_Country_ISO__c)){
                
                //       CreateEPI = false;
                //       system.debug('Create EPI Skipped');
                //   }
   
                if((a.Shipping_Address_Validation_Timestamp__c != oldAL.Shipping_Address_Validation_Timestamp__c || EPIfieldSet) && a.Address_Validation__c == 'Valid' &&
                    (oldAL.RecordTypeId != recTypeIdAccountLocationValidation && oldAL.RecordTypeId != recTypeIdPromotionRequested) && SAPiLogCreated == false && CreateEPI && a.Batch_Import_Flag__c == false && acctLocDigital.get(a.Mini_Sales_Organization__c)){ 
                    integLogsToInsertList.add(new Integration_Log__c(Object_Id__c = a.Id, 
                                                                    Object__c = 'Account Location Digital',
                                                                    Integration_Status__c = INT_Constants.INITIAL,
                                                                    AccountLocation__c = a.Id));
                }
                
            }
                
        }
        if(!integLogsToInsertList.isEmpty()) {
            AccountLocationTriggerHandlerHelper.integLogFirstTime = false;
            insert integLogsToInsertList;
        }
    }
    
    public static void createIntegLogAfterSAP(Set<Apttus_Config2__AccountLocation__c> newList, Map<Id, Apttus_Config2__AccountLocation__c> oldRecordMap) {
        try {
            List<Integration_Log__c> integLogsToInsertList = new List<Integration_Log__c>();
            Id recTypeIdAccountLocationValidation = Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get('Account Location Validation').getRecordTypeId();
            Id recTypeIdAccountLocationRO = Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get('Account Location RO').getRecordTypeId();
            Id recTypeIdPromotionRequested = Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get('Promotion Requested').getRecordTypeId();
            Map<String, Boolean> acctLocDigital = UserDAO.digitalIntegrationInformation('Account Location');
            for(Apttus_Config2__AccountLocation__c a : newList){
                Apttus_Config2__AccountLocation__c oldAl = oldRecordMap.get(a.Id);
                //When SAP response, SAP PO Updated is changed to true then a workflow reverts it back to false
                if(a.Batch_Import_Flag__c == false && acctLocDigital.get(a.Mini_Sales_Organization__c)){
                       integLogsToInsertList.add(new Integration_Log__c(Object_Id__c = a.Id, 
                                                                        Object__c = 'Account Location Digital', 
                                                                        AccountLocation__c = a.Id,
                                                                        Integration_Status__c = INT_Constants.INITIAL));
                       if (a.SAP_Customer_ID__c != null && oldAl.SAP_Customer_ID__c == null && a.SAP_Customer_ID__c != oldAl.SAP_Customer_ID__c && a.RecordTypeId <> recTypeIdAccountLocationRO) {
                           integLogsToInsertList.add(new Integration_Log__c(Object_Id__c = a.Apttus_Config2__AccountId__c, 
                                                                            Object__c = INT_Constants.ACCOUNT,
                                                                            Account__c = a.Apttus_Config2__AccountId__c, 
                                                                            AccountLocation__c = a.Id));
                       }
                   }
                
            }//End of Account Loop
            
            if(integLogsToInsertList != null && !integLogsToInsertList.isEmpty()) { 
                AccountLocationTriggerHandlerHelper.integLogFirstTime = false;
                insert integLogsToInsertList;
            }
        } catch(Exception ex) {     
            CustomLogging.debugException(ex);
            CustomLogging.pop();      
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
    }
    
    public static void addressValidationApproved(Set<Apttus_Config2__AccountLocation__c> listAccountLoc, Map<Id,Apttus_Config2__AccountLocation__c> oldAccountMap){
        CustomLogging.push('addressValidationApproved', 'SM_AccountLocationUtil');
        try{
            Map <String, String> countrycode = SM_GetMetadata.getcountrycodemdtrecords();
            for (Apttus_Config2__AccountLocation__c accLoc : listAccountLoc) {
                if (!countrycode.isEmpty()){
                    accLoc.Shipping_Country_ISO__c = countrycode.get(accLoc.Apttus_Config2__Country__c);
                }
                if (accLoc.RecordTypeId == SM_Constants.recordTypeIdAccountLocation){
                    Apttus_Config2__AccountLocation__c oldAccLoc = oldAccountMap.get(accLoc.Id);
                    accLoc.Updated_Shipping_House_Number__c = accLoc.Shipping_House_Number__c;
                    accLoc.Updated_House_Number_Supplement__c = accLoc.House_Number_Supplement__c;
                    accLoc.Updated_Shipping_City__c = accLoc.Apttus_Config2__City__c;
                    accLoc.Updated_Shipping_Country__c = accLoc.Apttus_Config2__Country__c;
                    accLoc.Updated_shipping_Postal_Code__c = accLoc.Apttus_Config2__PostalCode__c;
                    accLoc.Updated_Shipping_State__c = accLoc.Apttus_Config2__State__c;
                    accLoc.Updated_Shipping_Street_Only__c = accLoc.Shipping_Street_Only__c;
                    accLoc.Updated_Shipping_Country_ISO__c = accLoc.Shipping_Country_ISO__c;
                    accLoc.Apttus_Config2__Country__c = oldAccLoc.Apttus_Config2__Country__c;
                    accLoc.Shipping_Country_ISO__c = oldAccLoc.Shipping_Country_ISO__c;
                    accLoc.RecordTypeId = SM_Constants.recordTypeIdAccountLocationValidation;
                }
            }
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
    }

    public static void changeStreetValue(Set<Apttus_Config2__AccountLocation__c> accountLoc) {
        for(Apttus_Config2__AccountLocation__c accLoc : accountLoc){
            if(accLoc.Shipping_Street_Only__c != Null) {
                accLoc.Apttus_Config2__Street__c = accLoc.Shipping_Street_Only__c;
            }
            if(accLoc.Shipping_House_Number__c != Null) {
                accLoc.Apttus_Config2__Street__c =+ accLoc.Apttus_Config2__Street__c + ' ' + accLoc.Shipping_House_Number__c;
            }
            if(accLoc.House_Number_Supplement__c != Null) {
                accLoc.Apttus_Config2__Street__c =+ accLoc.Apttus_Config2__Street__c + ' ' + accLoc.House_Number_Supplement__c;
            }
        }
    }

    public static void addDefaultValueSCTZ(Set<Apttus_Config2__AccountLocation__c> accountLoc) {
        List<Account> accountList = new List<Account>();
        Map<Id, Account> acctMap = new Map<Id, Account>();
        Set<Id> accountId = new Set<Id>();
        for(Apttus_Config2__AccountLocation__c alRec : accountLoc){
            accountId.add(alRec.Apttus_Config2__AccountId__c);
        }

        accountList = [Select Id, Mini_Shipping_Conditions__c, Transportation_zone__c FROM Account WHERE Id IN :accountId];
        for(Account acc : accountList) {
            acctMap.put(acc.Id, acc);
        }
        for (Apttus_Config2__AccountLocation__c al: accountLoc) {
            Account accountLocValue = acctMap.get(al.Apttus_Config2__AccountId__c);
            if(accountLocValue.Mini_Shipping_Conditions__c != Null) {
                al.Mini_Shipping_Conditions__c = accountLocValue.Mini_Shipping_Conditions__c;
            }
            if(accountLocValue.Transportation_zone__c != Null) {
                al.Mini_Transportation_zone__c = accountLocValue.Transportation_zone__c;
            }
        }
    }

    public static void tZoneValidation(Set<Apttus_Config2__AccountLocation__c> accountLoc){
        List<Transportation_Zone_per_Country__c> tZoneCountry = new List<Transportation_Zone_per_Country__c>();
        Map<String, String> cisoTzone = new Map<String, String>();
        Set<String> setSIso = new Set<String>();
        for(Apttus_Config2__AccountLocation__c acctLoc : accountLoc) {
            if (acctLoc.Shipping_Country_ISO__c != Null) {
                setSIso.add(acctLoc.Shipping_Country_ISO__c);
            }
        }
        tZoneCountry = [Select Country_ISO__c, Transportation_Zone__c FROM Transportation_Zone_per_Country__c WHERE Country_ISO__c IN :setSIso];
        for(Transportation_Zone_per_Country__c tZ : tZoneCountry){
            cisoTzone.put(tZ.Transportation_Zone__c, tZ.Country_ISO__c);
        }
        for(Apttus_Config2__AccountLocation__c accLoc: accountLoc) {
            if (cisoTzone.get(accLoc.Mini_Transportation_zone__c) != accLoc.Shipping_Country_ISO__c) {
                accLoc.Mini_Transportation_zone__c.addError('You cannot select this value, please choose only within your country');
            }
        }
    }
}