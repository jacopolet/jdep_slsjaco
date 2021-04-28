//-------------------------------------------------------------------------------------------//
// Author       :   Alvin Lomod
// Created Date :   April 12, 2018
// Usage        :   
// Requirement  :  Recreated
// 
//-------------------------------------------------------------------------------------------//
public without sharing class AccountLocationTriggerHandler implements ITriggerHandler {
    
    public static Boolean isTriggerDisabled = true;
    public static Boolean isNotBatchExecution = true;
    public static Boolean isBatchExecution = false; //XEN REYES 11.11.2018
    private static Boolean SAPfieldSet = false;
    private static Boolean EPIfieldSet = false;
    private static Boolean sapReturn = false;
    Map<Id, Apttus_Config2__AccountLocation__c> oldAcountMap = new Map<Id, Apttus_Config2__AccountLocation__c>();
    private static final Map<String, String> mapOfFields = new Map<String, String> {
    'Name'=> 'Updated_Account_Location_name__c',
    'Customer_calendar_key__c'=> 'Updated_Customer_Calendar_Key__c',
    'Mini_Language__c'=> 'Updated_Language__c',
    'Pallet_type__c'=> 'Updated_Pallet_Type__c',
    'Apttus_Config2__City__c'=> 'Updated_Shipping_City__c',
    'Shipping_House_Number__c'=> 'Updated_Shipping_House_Number__c',
    'Shipping_Street_Only__c'=> 'Updated_Shipping_Street_only__c',
    'Apttus_Config2__PostalCode__c'=> 'Updated_shipping_Postal_Code__c',
    'Apttus_Config2__State__c'=> 'Updated_Shipping_State__c',
    'Apttus_Config2__Country__c'=> 'Updated_Shipping_Country__c',
    'Monday_Afternoon_From_Receiving__c'=> 'Updated_Monday_Afternoon_From__c',
    'Monday_Afternoon_To_Receiving__c'=> 'Updated_Monday_Afternoon_To__c',
    'Monday_Morning_From_Receiving__c'=> 'Updated_Monday_Morning_From__c',
    'Monday_Morning_To_Receiving__c'=> 'Updated_Monday_Morning_To__c',
    'Tuesday_Afternoon_From_Receiving__c'=> 'Updated_Tuesday_Afternoon_From__c',
    'Tuesday_Afternoon_To_Receiving__c'=> 'Updated_Tuesday_Afternoon_To__c',
    'Tuesday_Morning_From_Receiving__c'=> 'Updated_Tuesday_Morning_From__c',
    'Tuesday_Morning_To_Receiving__c'=> 'Updated_Tuesday_Morning_To__c',
    'Wednesday_Afternoon_From_Receiving__c'=> 'Updated_Wednesday_Afternoon_From__c',
    'Wednesday_Afternoon_To_Receiving__c'=> 'Updated_Wednesday_Afternoon_To__c',
    'Wednesday_Morning_From_Receiving__c'=> 'Updated_Wednesday_Morning_From__c',
    'Wednesday_Morning_To_Receiving__c'=> 'Updated_Wednesday_Morning_To__c',
    'Thursday_Afternoon_From_Receiving__c'=> 'Updated_Thursday_Afternoon_From__c',
    'Thursday_Afternoon_To_Receiving__c'=> 'Updated_Thursday_Afternoon_To__c',
    'Thursday_Morning_From_Receiving__c'=> 'Updated_Thursday_Morning_From__c',
    'Thursday_Morning_To_Receiving__c'=> 'Updated_Thursday_Morning_To__c',
    'Friday_Afternoon_From_Receiving__c'=> 'Updated_Friday_Afternoon_From__c',
    'Friday_Afternoon_To_Receiving__c'=> 'Updated_Friday_Afternoon_To__c',
    'Friday_Morning_From_Receiving__c'=> 'Updated_Friday_Morning_From__c',
    'Friday_Morning_To_Receiving__c'=> 'Updated_Friday_Morning_To__c',
    'Saturday_Afternoon_From_Receiving__c'=> 'Updated_Saturday_Afternoon_From__c',
    'Saturday_Afternoon_To_Receiving__c'=> 'Updated_Saturday_Afternoon_To__c',
    'Saturday_Morning_From_Receiving__c'=> 'Updated_Saturday_Morning_From__c',
    'Saturday_Morning_To_Receiving__c'=> 'Updated_Saturday_Morning_To__c',
    'Sunday_Afternoon_From_Receiving__c'=> 'Updated_Sunday_Afternoon_From__c',
    'Sunday_Afternoon_To_Receiving__c'=> 'Updated_Sunday_Afternoon_To__c',
    'Sunday_Morning_From_Receiving__c'=> 'Updated_Sunday_Morning_From__c',
    'Sunday_Morning_To_Receiving__c'=> 'Updated_Sunday_Morning_To__c',
    'Delivery_Block_Reason__c'=> 'Updated_Delivery_Block__c',
    'House_Number_Supplement__c'=> 'Updated_House_Number_Supplement__c',
    'Region_API_Code__c'=> 'Updated_Region_Codes__c',
    'Picking_list_text__c'=> 'Updated_Picking_List_Text__c',
    'Delivery_text__c'=> 'Updated_Delivery_Text__c',
    'Mini_Shipping_Conditions__c'=> 'Updated_Shipping_Conditions__c',
    'Mini_Transportation_zone__c'=> 'Updated_Transportation_Zone__c'
    };
    
     
    public void beforeInsert(List<SObject> newAccountMap){
        addDefaultValueSCTZ((List<Apttus_Config2__AccountLocation__c>) newAccountMap);
        setRecordTypeAddressValidation((List<Apttus_Config2__AccountLocation__c>) newAccountMap, oldAcountMap);
        shippingCountryAutoPopulate((List<Apttus_Config2__AccountLocation__c>) newAccountMap, oldAcountMap);
        concatenationStreetValue((List<Apttus_Config2__AccountLocation__c>) newAccountMap, oldAcountMap);
        populateAddressValidationInvalid((List<Apttus_Config2__AccountLocation__c>) newAccountMap, oldAcountMap);
        populateAddressValidationValid((List<Apttus_Config2__AccountLocation__c>) newAccountMap, oldAcountMap);
        populateRoutesalesSetting(newAccountMap);
        setRecordTypeCopiedToAccount((List<Apttus_Config2__AccountLocation__c>) newAccountMap);
        checkRecursive.run = false;
    } 
 
    public void beforeUpdate(List<SObject> newAccountList, Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldAccountMap){
        if (checkRecursive.run == true) {
            checkTransZone((List<Apttus_Config2__AccountLocation__c>) newAccountList, (Map<Id, Apttus_Config2__AccountLocation__c>) oldAccountMap);
            flushRSDetails((List<Apttus_Config2__AccountLocation__c>) newAccountList, (Map<Id, Apttus_Config2__AccountLocation__c>) oldAccountMap);//Francis Allen Alindogan 03/12/2020 DOO-4256
            setRecordTypeAddressValidation((List<Apttus_Config2__AccountLocation__c>) newAccountList, (Map<Id, Apttus_Config2__AccountLocation__c>) oldAccountMap);
            changeDuplicateStatus((List<Apttus_Config2__AccountLocation__c>) newAccountList, (Map<Id, Apttus_Config2__AccountLocation__c>) oldAccountMap);
            fieldAddressValidationApproved((List<Apttus_Config2__AccountLocation__c>) newAccountList, (Map<Id, Apttus_Config2__AccountLocation__c>) oldAccountMap);
            populateAddressValidationInvalid((List<Apttus_Config2__AccountLocation__c>) newAccountList, (Map<Id, Apttus_Config2__AccountLocation__c>) oldAccountMap);
            populateAddressValidationValid((List<Apttus_Config2__AccountLocation__c>) newAccountList, (Map<Id, Apttus_Config2__AccountLocation__c>) oldAccountMap);
            //setCalendarKey((List<Apttus_Config2__AccountLocation__c>) newAccountList, (Map<Id, Apttus_Config2__AccountLocation__c>) oldAccountMap);
            populateRoutesalesSetting(newAccountList);
            changeFieldValueAccountLocation((List<Apttus_Config2__AccountLocation__c>) newAccountList, (Map<Id, Apttus_Config2__AccountLocation__c>) oldAccountMap);
            concatenationStreetValue((List<Apttus_Config2__AccountLocation__c>) newAccountList, (Map<Id, Apttus_Config2__AccountLocation__c>) oldAccountMap);
            stampCustomerSinceDate((List<Apttus_Config2__AccountLocation__c>) newAccountList, (Map<Id, Apttus_Config2__AccountLocation__c>) oldAccountMap);
            setRTafterSAPReturn((List<Apttus_Config2__AccountLocation__c>) newAccountList, (Map<Id, Apttus_Config2__AccountLocation__c>) oldAccountMap);
        }
    }
 
    public void beforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems){
        
    }
 
    public void afterInsert(List<SObject> newAccountMap, Map<Id, SObject> newItems){
        insertDefaultCalendars((List<Apttus_Config2__AccountLocation__c>) newAccountMap, oldAcountMap); //XEN REYES DOO-4539 June 19, 2020
        createIntegrationLogs((List<Apttus_Config2__AccountLocation__c>) newAccountMap, oldAcountMap);
        checkRecursive.run = false;
    }
 
    public void afterUpdate(List<SObject> newAccountList , Map<Id, SObject> newItems, List<SObject> oldList, Map<Id, SObject> oldAccountMap){
        if (checkRecursive.run == true) {
            createIntegrationLogs((List<Apttus_Config2__AccountLocation__c>) newAccountList , (Map<Id, Apttus_Config2__AccountLocation__c>) oldAccountMap);
            //createIntegrationLogsAfterSAP((List<Apttus_Config2__AccountLocation__c>)newAccountList, (Map<Id, Apttus_Config2__AccountLocation__c>)oldAccountMap);
            provideThirdPartyResourceAccess((List<Apttus_Config2__AccountLocation__c>) newAccountList , (Map<Id, Apttus_Config2__AccountLocation__c>) oldAccountMap);
        }

        //KTS-1775: responsible to Initiate updates from related objects added by Paul Aguiling 7.2.2018 
        if (isNotBatchExecution) {
            //TS_UtilityClass.resendTaskIntegLog('Apttus_Config2__AccountLocation__c', 'AccountLocation__c', newAccountList, oldAccountMap);
        }
    }
 
    public void afterDelete(List<SObject> oldList, Map<Id, SObject> oldItems){
        
    }
 
    public void afterUndelete(List<SObject> newList, Map<Id, SObject> newItems){
        
    }
    
    public Boolean isDisabled(){
        if (TriggerSettings__c.getInstance().AccountLocationTrigger__c == true && !isBatchExecution) {
            return false;
        } else {
            return isTriggerDisabled;
        }
    }
    
    /**
    * @author        Kimiko Roberto
    * @date          04.05.2017           
    * @description   Method responsible for creating Integration Logs
    * @revision(s)   12.04.2018 - Alvin Lomod KASM-1575 AND KASM-1576
    */
    private static Boolean fieldSetEPIUpdated(Apttus_Config2__AccountLocation__c a, Map<Id, Apttus_Config2__AccountLocation__c> oldRecordMap){
		Apttus_Config2__AccountLocation__c oldAccL;
		Boolean fieldsEPIUpdated = false;
		Set<String> EPIfieldSet = new Set<String>();
		//Dynamically get the fields from the field set and then use the same for comparison in the trigger for EPI/Digital iLog
		for(Schema.FieldSetMember fields :Schema.SObjectType.Apttus_Config2__AccountLocation__c.fieldSets.getMap().get('EPI_Account_Location_Field_Set').getFields()){
			EPIfieldSet.add(fields.getFieldPath());
		}
		
		for(string s: EPIfieldSet){
			if (!oldRecordMap.isEmpty()){
				oldAccL = oldRecordMap.get(a.Id);
				if(a.get(s) != oldAccL.get(s)){
					fieldsEPIUpdated = true;
                    break;
				}
			}
			
        }
		return fieldsEPIUpdated;
	}
	private static Boolean fieldSetSAPUpdated(Apttus_Config2__AccountLocation__c a, Map<Id, Apttus_Config2__AccountLocation__c> oldRecordMap){
		Apttus_Config2__AccountLocation__c oldAccL;
		Boolean fieldsSAPUpdated = false;
		Set<String> SAPfieldSet = new Set<String>();
		
        //Dynamically get the fields from the field set and then use the same for comparison in the trigger for SAP iLog
		for(Schema.FieldSetMember fields :Schema.SObjectType.Apttus_Config2__AccountLocation__c.fieldSets.getMap().get('SAP_Account_Location_Field_Set').getFields()){
			SAPfieldSet.add(fields.getFieldPath());
		}
		for(string s: SAPfieldSet){
			if (!oldRecordMap.isEmpty()){
				oldAccL = oldRecordMap.get(a.Id);
				if(a.get(s) != oldAccL.get(s)){ 
                    fieldsSAPUpdated = true;
                    break;
				}
			}
			
        }
		return fieldsSAPUpdated;
	}
	private static Boolean createIlog(Apttus_Config2__AccountLocation__c accLocation, Map<Id, Apttus_Config2__AccountLocation__c> oldRecordMap) {
		Apttus_Config2__AccountLocation__c oldAccL;
		Boolean ilogCreate = false;
		if (!oldRecordMap.isEmpty()){
            oldAccL = oldRecordMap.get(accLocation.id);
			if ((fieldSetSAPUpdated(accLocation, oldRecordMap) || fieldSetEPIUpdated(accLocation, oldRecordMap)) && (accLocation.Address_Validation__c == 'Valid' || oldAccL.Address_Validation__c == 'Request Address Validation' && accLocation.Address_Validation__c == 'Valid') && !accLocation.SAP_PO_Updated__c) {
				ilogCreate = true;
                    if (fieldSetSAPUpdated(accLocation, oldRecordMap)){
                        SAPfieldSet = true;
                    }
                    if (fieldSetEPIUpdated(accLocation, oldRecordMap)){
                        EPIfieldSet = true;
                    }
			}
		} else {
			if (accLocation.Address_Validation__c == 'Valid' && !accLocation.SAP_PO_Updated__c) {
				ilogCreate = true;
			}
        }
		return ilogCreate;
	}
    private void createIntegrationLogs(List<Apttus_Config2__AccountLocation__c> newList, Map<Id, Apttus_Config2__AccountLocation__c> oldRecordMap) {
        try {
            if(AccountLocationTriggerHandlerHelper.integLogFirstTime == true) {
                CustomLogging.push('createIntegrationLogs', 'AccountLocationTriggerHandler');
                Set<Apttus_Config2__AccountLocation__c> accountLocationTobeUpdated = new Set<Apttus_Config2__AccountLocation__c>();
                for (Apttus_Config2__AccountLocation__c accLocation : newList) {
                    if(createIlog(accLocation, oldRecordMap)) {
                        accountLocationTobeUpdated.add(accLocation);
                    }
                }
                
                if (!accountLocationTobeUpdated.isEmpty()) {
                    AccountLocationTriggerHandlerHelper.integLogFirstTime = false;
                    SM_AccountLocationUtil.createIntegLog(accountLocationTobeUpdated, oldRecordMap, SAPfieldSet, EPIfieldSet);
                }
            }
        } catch(Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();      
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        CustomLogging.pop();
    }
    
    /**
    * @author        Alvin Lomod
    * @date          29.05.2018           
    * @description   Method responsible for creating Integration Logs after SAP response for EPI
    * @revision(s)   KASM-1766
    */

    /*private void createIntegrationLogsAfterSAP(List<Apttus_Config2__AccountLocation__c> newAccountList, Map<Id,Apttus_Config2__AccountLocation__c> oldAccountLocMap) {
        CustomLogging.push('createIntegrationLogsAfterSAP', 'AccountLocationTriggerHandler');
        try {
            if(AccountLocationTriggerHandlerHelper.integLogFirstTime == true){
                Set<Apttus_Config2__AccountLocation__c> accountLocs = new Set<Apttus_Config2__AccountLocation__c>();
                for (Apttus_Config2__AccountLocation__c accloc : newAccountList) {
                    Apttus_Config2__AccountLocation__c oldAccLoc = new Apttus_Config2__AccountLocation__c();
                    oldAccLoc = oldAccountLocMap.get(accloc.Id);

                        accountLocs.add(accloc);
                }
                if (!accountLocs.isEmpty()) {
                    SM_AccountLocationUtil.createIntegLogAfterSAP(accountLocs, oldAccountLocMap);
                }
            }
        } catch(Exception ex) {     
            CustomLogging.debugException(ex);
            CustomLogging.pop();      
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        
    }*/
    
     private void changeFieldValueAccountLocation(List<Apttus_Config2__AccountLocation__c> newAccountList, Map<Id, Apttus_Config2__AccountLocation__c> oldAccountMap){
        Map<String, String> filteredAccountLocFieldMap = new Map<String, String>();
        Map<String, String> filteredSelectedAccountLocFieldMap = new Map<String, String>();
        Id recTypeIdAccountLocationValidation = Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get('Account Location Validation').getRecordTypeId();
        Id recTypeIdPromotionRequested = Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get('Promotion Requested').getRecordTypeId();
        Id recTypeIdAccountLocationRO = Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get(SM_Constants.AccountLocationRO).getRecordTypeId();
        Set<Apttus_Config2__AccountLocation__c> accountLocToUpdate = new Set<Apttus_Config2__AccountLocation__c>();
        Set<String> EPIfieldSet = new Set<String>();
        Map<String,String> ALROFields = new Map<String,String>(mapOfFields);
        ALROFields.remove('Apttus_Config2__City__c');
        ALROFields.remove('Shipping_House_Number__c');
        ALROFields.remove('Shipping_Street_Only__c');
        ALROFields.remove('Apttus_Config2__PostalCode__c');
        ALROFields.remove('Apttus_Config2__State__c');
        ALROFields.remove('Apttus_Config2__Country__c');

        for (Apttus_Config2__AccountLocation__c accLoc : newAccountList) {
            Apttus_Config2__AccountLocation__c oldAccountLoc = oldAccountMap.get(accLoc.Id);
            if (accLoc.SAP_PO_Updated__c == false && accLoc.SAP_Customer_ID__c != null && (oldAccountMap.get(accLoc.Id).RecordTypeId != recTypeIdAccountLocationValidation && oldAccountMap.get(accLoc.Id).RecordTypeId != recTypeIdPromotionRequested) 
                && (accLoc.Address_Validation__c != 'Request Address Validation' || (accLoc.Address_Validation__c == 'Valid' && oldAccountLoc.Address_Validation__c == 'Request Address Validation'))) {
                for(Schema.FieldSetMember fields :Schema.SObjectType.Apttus_Config2__AccountLocation__c.fieldSets.getMap().get('EPI_Account_Location_Field_Set').getFields()){
                    EPIfieldSet.add(fields.getFieldPath());
                    accountLocToUpdate.add(accLoc);
                }
                if (accLoc.RecordTypeId != recTypeIdAccountLocationRO) {
                    for (String fldAcct : mapOfFields.keySet()) {
                        if (accLoc.get(fldAcct) != oldAccountLoc.get(fldAcct)) {
                            filteredAccountLocFieldMap.put(fldAcct, mapOfFields.get(fldAcct));
                            accountLocToUpdate.add(accLoc);
                        }
                    }
                } else {
                    for (String fldAcct : ALROFields.keySet()) {
                        if (accLoc.get(fldAcct) != oldAccountLoc.get(fldAcct)) {
                            filteredSelectedAccountLocFieldMap.put(fldAcct, ALROFields.get(fldAcct));
                            accountLocToUpdate.add(accLoc);
                        }
                    }
                }
            }
        }
        
        if(!accountLocToUpdate.isEmpty() && (!EPIfieldSet.isEmpty() || !filteredAccountLocFieldMap.isEmpty() || !filteredSelectedAccountLocFieldMap.isEmpty() )) {
            SM_AccountLocationUtil.changeFieldValue(accountLocToUpdate, oldAccountMap, EPIfieldSet, filteredAccountLocFieldMap, filteredSelectedAccountLocFieldMap);
        } 

    } 
    
      /**
    * @author        Karen Mae Hung
    * @date          11/29/2018           
    * @description   Method responsible for populating RoutesalesSettings__c field KTS-2358
    * @revision(s)
    */
    private void populateRoutesalesSetting(List<SObject> newList){
        CustomLogging.push('populateRoutesalesSetting', 'AccountLocationTriggerHandler');
        if (!SM_CheckRecursive.processedSet.contains('populateRoutesalesSetting')){
        	SM_CheckRecursive.processedSet.add('populateRoutesalesSetting');
        
            Map<String,CountrySetting__c> countryMap = new Map<String,CountrySetting__c>();
            for(CountrySetting__c country : [SELECT ID, Country__c FROM CountrySetting__c WHERE Recordtype.Name ='Route Sales Setting' AND Active__c =true]){
                countryMap.put(country.Country__c, country);
            }
            for (Apttus_Config2__AccountLocation__c accLoc: (List<Apttus_Config2__AccountLocation__c>) newList) {
    
                if(accLoc.RoutesalesInterval__c != null || accLoc.RoutesalesInterval__c !=0){
                
                    if(countryMap.containsKey(accLoc.Mini_Sales_Organization__c)){
                        accLoc.RoutesalesSettings__c = countryMap.get(accLoc.Mini_Sales_Organization__c).Id;   
                    }else{
                       accLoc.RoutesalesSettings__c = null; 
                    }
    
                }
            
            }             
        }
       

        CustomLogging.pop(); 
    }

    /**@author      Catherine Aragon
     * @date        02-04-2020
     * @description Change account and address validation status to valid
     * @revision(s)
     */

    private static Boolean changeAddressStatus(Apttus_Config2__AccountLocation__c al, Map<Id, Apttus_Config2__AccountLocation__c> oldAccountLocMap) {
        Apttus_Config2__AccountLocation__c oldAccLoc = new Apttus_Config2__AccountLocation__c();
        Boolean isChange = false;
        if(!oldAccountLocMap.isEmpty()) {
            oldAccLoc = oldAccountLocMap.get(al.Id);
            if ((al.Shipping_Address_Validation_Timestamp__c != oldAccLoc.Shipping_Address_Validation_Timestamp__c && al.Shipping_Address_Validation_Timestamp__c != Null && al.Shipping_Address_Validation_Error__c == Null && al.Address_Validation__c == 'Not Valid') || (al.Duplicate_Validation__c != oldAccLoc.Duplicate_Validation__c && al.Duplicate_Validation__c != 'Duplicate Identified') || (al.Address_Validation__c == 'Valid' && oldAccLoc.Address_Validation__c == 'Request Address Validation')) {
                isChange = true;
            }
        } else {
            if (al.Shipping_Address_Validation_Error__c == Null && al.Shipping_Address_Validation_Timestamp__c != Null && al.Address_Validation__c == 'Not Valid') {
                isChange = true;
            }
        }
        return isChange;
    }
    
    private static void populateAddressValidationValid (List<Apttus_Config2__AccountLocation__c> newAccountList, Map<Id, Apttus_Config2__AccountLocation__c> oldAccountLocMap) {
    	CustomLogging.push('populateAddressValidationValid', 'AccountLocationTriggerHandler');
        try {
            for (Apttus_Config2__AccountLocation__c al: newAccountList) {
                if(changeAddressStatus(al, oldAccountLocMap)) {
                    if (al.Address_Validation__c == 'Not Valid') {
                        al.Address_Validation__c = 'Valid';
                    }
                    if ((al.Duplicate_Validation__c == 'No Duplicate' || al.Duplicate_Validation__c == 'Duplicate Verified') && al.Account_Location_Status__c == 'Not Valid') {
                        al.Account_Location_Status__c = 'Valid';
                    }
                }
            }
        } catch(Exception ex) {     
            CustomLogging.debugException(ex);
            CustomLogging.pop();      
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        
    }
    
    private static void setRecordTypeCopiedToAccount(List<Apttus_Config2__AccountLocation__c> newAccountList){
    	CustomLogging.push('setRecordType', 'AccountLocationTriggerHandler');
        try {
            Set<Apttus_Config2__AccountLocation__c> accountToupdate = new Set<Apttus_Config2__AccountLocation__c>();
            Id recTypeIdAccountLocationValid = Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get('Account Location Valid').getRecordTypeId();
            Id recTypeIdAccountLocationRO = Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get('Account Location RO').getRecordTypeId();
            for(Apttus_Config2__AccountLocation__c al : newAccountList) {
                if (al.Copy_of_Parent_Account__c == true && al.RecordTypeId == recTypeIdAccountLocationValid) {
                	al.RecordTypeId = recTypeIdAccountLocationRO;
                }
            }
            
        } catch(Exception ex) {     
            CustomLogging.debugException(ex);
            CustomLogging.pop();      
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
    }
    

    /*
    * @author        Francis Allen Alindogan
    * @date          March 11, 2020
    * @description   Method to flush acc loc routesales details DOO-4256
    * @revision(s)   
    */
    private void flushRSDetails(List<SObject> newAccountList, Map<Id, Apttus_Config2__AccountLocation__c> oldAccountMap){
        CustomLogging.push('flushRSDetails', 'AccountLocationTriggerHandler');
        try{
            List<Id> updatedAccLoc = new List<Id>();        
            Boolean flushReady = WorkOrderLineItemTriggerHandler.isRSTaskFlushReady;//FLAG TO CHECK IF UPDATE IS FROM WORKORDERLINEITEM

                if (!newAccountList.isEmpty() && !oldAccountMap.isEmpty()){
                    for (Apttus_Config2__AccountLocation__c acctLoc : (List<Apttus_Config2__AccountLocation__c>)newAccountList) {
                        Apttus_Config2__AccountLocation__c oldAccLocs = oldAccountMap.get(acctLoc.Id);

                        if((oldAccLocs.LastRoutesalesDate__c != acctLoc.LastRoutesalesDate__c) //FOR ACCOUNT LOCATION UPDATE WITH LAST ROUTESALES CHANGE
                        || flushReady == true //FOR COM  PLETED ROUTE SALES TASK FROM WORKORDERLINEITEM
                            ){
                                //GET SCHEMA OBJECT
                                Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
                                Schema.SObjectType aclSchema = schemaMap.get('Apttus_Config2__AccountLocation__c');
                                Map<String, Schema.SObjectField> fieldMap = aclSchema.getDescribe().fields.getMap();

                                for(Schema.FieldSetMember fields :Schema.SObjectType.Apttus_Config2__AccountLocation__c.fieldSets.getMap().get(TS_Constants.ACLOC_ROUTESALES_FLUSHINGVALUES).getFields()) {                                                                
                                    String fieldName = fields.getFieldPath();
                                    Schema.DisplayType fielddataType = fieldMap.get(fieldName).getDescribe().getType();
                                    
                                    //FLUSH ACCOUNT LOCATION DETAILS
                                    if(fielddataType !=  Schema.DisplayType.Boolean){
                                        acctLoc.put(fieldName,null); //FOR DATE FIELDS
                                    }
                                    else{
                                        acctLoc.put(fieldName,false); //FOR BOOLEAN FIELDS
                                    }
                                }
                        }                          

                        //FLUSH ROUTESALES CONFIRMATION
                        if( acctLoc.RequestedRoutesalesVisit__c == true &&
                            acctLoc.RoutesalesDateOverriden__c == true &&
                            oldAccLocs.RequestedRoutesalesVisit__c != acctLoc.RequestedRoutesalesVisit__c &&
                            oldAccLocs.RoutesalesDateOverriden__c != acctLoc.RoutesalesDateOverriden__c 
                            ){
                                acctLoc.RoutesalesConfirmationDate__c = null;
                        }
                    }
                }

            //TO AVOID RECURSSION Francis Allen Alindogan March 24, 2020
            WorkOrderLineItemTriggerHandler.isRSTaskFlushReady = false;
        }
        catch(Exception ex) {     
            CustomLogging.debugException(ex);
            CustomLogging.pop();      
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
    }

    /*private static void setCalendarKey (List<Apttus_Config2__AccountLocation__c> newAccountList, Map<Id, Apttus_Config2__AccountLocation__c> oldAccountMap) {
        CustomLogging.push('setCalendarKey', 'AccountLocationTriggerHandler');
        try {
            Map<String, String> customerCalendarKeyPerSalesOrg = new Map<String, String>();
            customerCalendarKeyPerSalesOrg.put('SAP_0333', 'SAP_BE');
            customerCalendarKeyPerSalesOrg.put('SAP_0975', 'SAP_DK');
            customerCalendarKeyPerSalesOrg.put('SAP_0976', 'SAP_SE');
            customerCalendarKeyPerSalesOrg.put('SAP_6864', 'SAP_NO');
            customerCalendarKeyPerSalesOrg.put('SAP_0080', 'SAP_ES');
            customerCalendarKeyPerSalesOrg.put('SAP_0111', 'SAP_NL');
            customerCalendarKeyPerSalesOrg.put('SAP_6712', 'SAP_01');
            customerCalendarKeyPerSalesOrg.put('SAP_6750', 'SAP_GB');
            if (!oldAccountMap.isEmpty()) {
                Apttus_Config2__AccountLocation__c oldAccLoc = new Apttus_Config2__AccountLocation__c();
                for(Apttus_Config2__AccountLocation__c al : newAccountList) {
                    oldAccLoc = oldAccountMap.get(al.Id);
                    if(al.Mini_Sales_Organization__c != oldAccLoc.Mini_Sales_Organization__c && al.Mini_Sales_Organization__c != Null) {
                        al.Customer_calendar_key__c = customerCalendarKeyPerSalesOrg.get(al.Mini_Sales_Organization__c);
                    }
                }
            }

        } catch(Exception ex) {     
            CustomLogging.debugException(ex);
            CustomLogging.pop();      
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
    }*/
    
    /**
    * @author        Glenn Serrano
    * @date                   
    * @description   Populate Update Address Fields after Super user validation on address
    * @revision(s)   
    */
	private static Boolean checkFieldAddressValidation(Apttus_Config2__AccountLocation__c accLoc, Map<Id,Apttus_Config2__AccountLocation__c> oldAccountMap){
		Apttus_Config2__AccountLocation__c oldAccLoc = oldAccountMap.get(accLoc.Id);
		Boolean addressValidation = false;
        if (accLoc.Address_Validation__c == 'Valid' && oldAccLoc.Address_Validation__c == 'Request Address Validation') {
            addressValidation = true;
        }
		return addressValidation;
	}
    
    private static void fieldAddressValidationApproved(List<Apttus_Config2__AccountLocation__c> newAccountList, Map<Id,Apttus_Config2__AccountLocation__c> oldAccountMap){
        CustomLogging.push('fieldAddressValidationApproved', 'AccountLocationTriggerHandler');
        try {
            if (!oldAccountMap.isEmpty()) {
                Set<Apttus_Config2__AccountLocation__c> accLocToUpdate = new Set<Apttus_Config2__AccountLocation__c>();
                for (Apttus_Config2__AccountLocation__c a : newAccountList) {
					if(checkFieldAddressValidation(a, oldAccountMap)) {
                        accLocToUpdate.add(a);
					}
                }
                if (!accLocToUpdate.isEmpty()) {
                    SM_AccountLocationUtil.addressValidationApproved(accLocToUpdate, oldAccountMap);
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
     * @author      Catherine Aragon
     * @date        02-04-2020
     * @description Concatenation of Street value. Values of concatenation is based on shipping street only, shipping house number and shipping
     *              house number supplement 
     * @revision(s)
     */
    private static Boolean checkAddressChange(Apttus_Config2__AccountLocation__c accLoc, Map<Id,Apttus_Config2__AccountLocation__c> oldAccountLocMap) {
        Apttus_Config2__AccountLocation__c oldAccLoc = oldAccountLocMap.get(accLoc.Id);
        Boolean isAddressChanged = false;
        if ((accLoc.Shipping_Street_Only__c != Null && accLoc.Shipping_Street_Only__c != oldAccLoc.Shipping_Street_Only__c) || (accLoc.Shipping_House_Number__c != Null && accLoc.Shipping_House_Number__c != oldAccLoc.Shipping_House_Number__c) || (accLoc.House_Number_Supplement__c != Null && accLoc.House_Number_Supplement__c != oldAccLoc.House_Number_Supplement__c)) {
            isAddressChanged = true;
        } else if (accLoc.Shipping_Street_Only__c != Null || accLoc.Shipping_House_Number__c != Null || accLoc.House_Number_Supplement__c != Null) {
            isAddressChanged = true;
        }
        return isAddressChanged;
    }

    private static void concatenationStreetValue(List<Apttus_Config2__AccountLocation__c> newAccountList, Map<Id,Apttus_Config2__AccountLocation__c> oldAccountLocMap) {
        CustomLogging.push('concatenationStreetValue', 'AccountLocationTriggerHandler');
        try {
            Set<Apttus_Config2__AccountLocation__c> accLocToUpdate = new Set<Apttus_Config2__AccountLocation__c>();
            for (Apttus_Config2__AccountLocation__c a : newAccountList) {
                if(checkAddressChange(a, oldAccountLocMap)) {
                    accLocToUpdate.add(a);
                }
            }
            if (!accLocToUpdate.isEmpty()) {
                SM_AccountLocationUtil.changeStreetValue(accLocToUpdate);
            }
        } catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        } 
        CustomLogging.pop(); 
    }

     /**
     * @author      Catherine Aragon
     * @date        02-04-2020
     * @description Add customer since date when account location has been promoted to SAP
     * @revision(s)
     */
    private static void stampCustomerSinceDate(List<Apttus_Config2__AccountLocation__c> newAccountList, Map<Id,Apttus_Config2__AccountLocation__c> oldAccountLocMap){
        CustomLogging.push('customerSinceDate', 'AccountLocationTriggerHandler');
        try {
            Apttus_Config2__AccountLocation__c oldAccLoc;
            for (Apttus_Config2__AccountLocation__c a : newAccountList) {
                oldAccLoc = oldAccountLocMap.get(a.Id);
                if(a.SAP_Customer_ID__c != Null && a.SAP_Customer_ID__c != oldAccLoc.SAP_Customer_ID__c) {
                    a.Customer_Since__c = Date.today();
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
     * @author      Catherine Aragon
     * @date        02-04-2020
     * @description Add users country from shipping country field
     * @revision(s)
     */
    private static void shippingCountryAutoPopulate(List<Apttus_Config2__AccountLocation__c> newAccountList, Map<Id,Apttus_Config2__AccountLocation__c> oldAccountLocMap) {
        CustomLogging.push('shippingCountryAutoPopulate', 'AccountLocationTriggerHandler');
        try {
            Set<Apttus_Config2__AccountLocation__c> accLocToUpdate = new Set<Apttus_Config2__AccountLocation__c>();
            User u = UserDAO.userInformation();
            for (Apttus_Config2__AccountLocation__c a : newAccountList) {
                if(u.Country != Null) {
                    a.Apttus_Config2__Country__c = u.Country;
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
     * @author      Catherine Aragon
     * @date        02-04-2020
     * @description Change duplicate status to duplicate identified when reason is provided
     * @revision(s)
     */
    private static void changeDuplicateStatus(List<Apttus_Config2__AccountLocation__c> newAccountList, Map<Id,Apttus_Config2__AccountLocation__c> oldAccountLocMap) {
        CustomLogging.push('changeDuplicateStatus', 'AccountLocationTriggerHandler');
        try {
            Set<Apttus_Config2__AccountLocation__c> accLocToUpdate = new Set<Apttus_Config2__AccountLocation__c>();
            Apttus_Config2__AccountLocation__c oldAccLoc;
            for (Apttus_Config2__AccountLocation__c a : newAccountList) {
                oldAccLoc = oldAccountLocMap.get(a.Id);
                if(a.Duplicate_Reason__c != Null && a.Duplicate_Reason__c != oldAccLoc.Duplicate_Reason__c) {
                    a.Duplicate_Validation__c = 'Duplicate Identified';
                    if (a.Account_Location_Status__c  == 'Valid') {
                        a.Account_Location_Status__c = 'Not Valid';
                    }
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
     * @author      Catherine Aragon
     * @date        02-04-2020
     * @description Address Validation RT change
     * @revision(s)
     */
    private static void setRecordTypeAddressValidation(List<Apttus_Config2__AccountLocation__c> newAccountList, Map<Id,Apttus_Config2__AccountLocation__c> oldAccountLocMap) {
        CustomLogging.push('setRecordTypeAddressValidation', 'AccountLocationTriggerHandler');
        try {
            Set<Apttus_Config2__AccountLocation__c> accLocToUpdate = new Set<Apttus_Config2__AccountLocation__c>();
            Id recTypeIdAccountLocationInvalid = Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get('Account Location Invalid').getRecordTypeId();
            Id recTypeIdAccountLocationValid = Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get('Account Location Valid').getRecordTypeId();
            Apttus_Config2__AccountLocation__c oldAccLoc;
            for (Apttus_Config2__AccountLocation__c a : newAccountList) {
                if (!oldAccountLocMap.isEmpty()) {
                    oldAccLoc = oldAccountLocMap.get(a.Id);
                    if((a.RecordTypeId == recTypeIdAccountLocationInvalid && a.Shipping_Address_Validation_Timestamp__c != Null && a.Shipping_Address_Validation_Code__c != Null) || (a.RecordTypeId == recTypeIdAccountLocationInvalid && a.Shipping_Address_Validation_Timestamp__c != Null && a.Address_Validation__c == 'Valid' && oldAccLoc.Address_Validation__c == 'Request Address Validation')) {
                        a.RecordTypeId = recTypeIdAccountLocationValid;
                    }
                } else if(a.Shipping_Address_Validation_Timestamp__c == Null && a.Shipping_Address_Validation_Code__c == Null) {
                    a.RecordTypeId = recTypeIdAccountLocationInvalid;
                }
                
            }
        } catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        } 
        CustomLogging.pop(); 
    }

    /**@author      Catherine Aragon
     * @date        02-04-2020
     * @description Change account and address validation status to invalid
     * @revision(s)
     */

    private static Boolean changeAddressStatusforInvalid(Apttus_Config2__AccountLocation__c al, Map<Id, Apttus_Config2__AccountLocation__c> oldAccountLocMap) {
        Apttus_Config2__AccountLocation__c oldAccLoc = new Apttus_Config2__AccountLocation__c();
        Boolean isChange = false;
        if(!oldAccountLocMap.isEmpty()) {
            oldAccLoc = oldAccountLocMap.get(al.Id);
            if ((al.Shipping_Address_Validation_Timestamp__c != oldAccLoc.Shipping_Address_Validation_Timestamp__c && al.Shipping_Address_Validation_Timestamp__c == Null && (al.Shipping_Address_Validation_Error__c != Null || al.Shipping_Address_Validation_Pending__c == true) && al.Address_Validation__c == 'Not Valid') || (al.Duplicate_Validation__c != oldAccLoc.Duplicate_Validation__c && al.Duplicate_Validation__c == 'Duplicate Identified')) {
                isChange = true;
            }
        } else {
            if ((al.Shipping_Address_Validation_Error__c != Null || al.Shipping_Address_Validation_Pending__c == true) && al.Shipping_Address_Validation_Timestamp__c == Null) {
                isChange = true;
            }
        }
        return isChange;
    }
    
    private static void populateAddressValidationInvalid (List<Apttus_Config2__AccountLocation__c> newAccountList, Map<Id, Apttus_Config2__AccountLocation__c> oldAccountLocMap) {
    	CustomLogging.push('populateAddressValidationInvalid', 'AccountLocationTriggerHandler');
        try {
            for (Apttus_Config2__AccountLocation__c al: newAccountList) {
                if(changeAddressStatusforInvalid(al, oldAccountLocMap)) {
                    if (al.Address_Validation__c == 'Valid') {
                        al.Address_Validation__c = 'Not Valid';
                    }
                    if (al.Duplicate_Reason__c != '' || al.Duplicate_Validation__c == 'Duplicate Identified') {
                        al.Account_Location_Status__c = 'Not Valid';
                    }
                }
            }
        } catch(Exception ex) {     
            CustomLogging.debugException(ex);
            CustomLogging.pop();      
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        
    }

    /**@author      Catherine Aragon
     * @date        02-04-2020
     * @description Change RT when SAP returns
     * @revision(s)
     */
    private static void setRTafterSAPReturn(List<Apttus_Config2__AccountLocation__c> newAccountList, Map<Id, Apttus_Config2__AccountLocation__c> oldAccountLocMap) {
        CustomLogging.push('setRTafterSAPReturn', 'AccountLocationTriggerHandler');
        try {
            Id recTypeIdAccountLocationRO = Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get('Account Location RO').getRecordTypeId();
            Id recTypeIdAccountLocation = Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get('Account Location').getRecordTypeId();
            Id recTypeIdPromotionRequested = Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get('Promotion Requested').getRecordTypeId();
            Id recTypeIdAccountLocationValidation = Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get('Account Location Validation').getRecordTypeId();
            Set<Apttus_Config2__AccountLocation__c> acctLocList = new Set<Apttus_Config2__AccountLocation__c>();
            Apttus_Config2__AccountLocation__c oldAccLoc;
            for (Apttus_Config2__AccountLocation__c al: newAccountList) {
                if(!oldAccountLocMap.isEmpty()) {
                    oldAccLoc = oldAccountLocMap.get(al.Id);
                    if (al.SAP_PO_Updated__c == true && al.SAP_Customer_ID__c != Null) {
                        al.SAP_PO_Updated__c = false;
                        if (al.RecordTypeId == recTypeIdPromotionRequested || al.RecordTypeId == recTypeIdAccountLocationValidation) {
                            al.EPI_Field_Updated__c = false;
                            if (al.Copy_of_Parent_Account__c == true) {
                                al.RecordTypeId = recTypeIdAccountLocationRO;
                            } else {
                                al.RecordTypeId = recTypeIdAccountLocation;
                            }
                        }
                        
                        acctLocList.add(al);
                    }
                }
            }
            if (!acctLocList.isEmpty()) {
                SM_AccountLocationUtil.createIntegLogAfterSAP(acctLocList, oldAccountLocMap);
            }
        } catch(Exception ex) {     
            CustomLogging.debugException(ex);
            CustomLogging.pop();      
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
    }

    /**
     * @author      Abram Vixen Reyes
     * @date        June 19, 2020
     * @description Method that will insert default operating calendars when creating new account location
     * @revision(s)
     */
    private static void insertDefaultCalendars(List<Apttus_Config2__AccountLocation__c> newAccountList, Map<Id,Apttus_Config2__AccountLocation__c> oldAccountLocMap) {
        CustomLogging.push('insertDefaultCalendars', 'AccountLocationTriggerHandler');
        try {
            
            String recordTypeId = Schema.SObjectType.CountrySetting__c.getRecordTypeInfosByName().get(TS_Constants.TS_COUNTRYSETTING_RECORDTYPE_DEFAULT_CALENDAR).getRecordTypeId();
            List<CountrySetting__c> cset_List =  [SELECT Id, Country__c, StartofBusinessDay__c, EndofBusinessDay__c, MondayException__c, TuesdayException__c, WednesdayException__c, ThursdayException__c, FridayException__c, Business_Unit__c FROM CountrySetting__c WHERE RecordtypeId = :recordTypeId AND Active__c = true];

            if(!cset_List.isEmpty()){
                Map<String, List<CountrySetting__c>> countrySettingCalendarMap = new Map<String, List<CountrySetting__c>>();
                for(CountrySetting__c cset_var : cset_List){
                    if(countrySettingCalendarMap.containsKey(cset_var.Country__c)){
                        countrySettingCalendarMap.get(cset_var.Country__c).add(cset_var);
                    } else {
                        countrySettingCalendarMap.put(cset_var.Country__c, new List<CountrySetting__c>{cset_var});
                    }
                }

                List<OperatingHourAssociation__c> toInsertOHA = new List<OperatingHourAssociation__c>();
                for(Apttus_Config2__AccountLocation__c ins_var : newAccountList){
                    if(countrySettingCalendarMap.containsKey(ins_var.Mini_Sales_Organization__c)){
                        for(CountrySetting__c ins_cs_var : countrySettingCalendarMap.get(ins_var.Mini_Sales_Organization__c)){
                            OperatingHourAssociation__c newOHA_var = new OperatingHourAssociation__c();
                            newOHA_var.Active__c = true;
                            newOHA_var.Account_Location__c = ins_var.Id;
                            newOHA_var.BusinessUnit__c = ins_cs_var.Business_Unit__c;
                            newOHA_var.StartofBusinessDay__c = ins_cs_var.StartofBusinessDay__c;
                            newOHA_var.EndofBusinessDay__c = ins_cs_var.EndofBusinessDay__c;
                            newOHA_var.MondayException__c = ins_cs_var.MondayException__c;
                            newOHA_var.TuesdayException__c = ins_cs_var.TuesdayException__c;
                            newOHA_var.WednesdayException__c = ins_cs_var.WednesdayException__c;
                            newOHA_var.ThursdayException__c = ins_cs_var.ThursdayException__c;
                            newOHA_var.FridayException__c = ins_cs_var.FridayException__c;                            
                            toInsertOHA.add(newOHA_var);
                        } 
                    }
                }

                insert toInsertOHA;
            }

        } catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        } 
        CustomLogging.pop(); 
    }

    /**@author      Catherine Aragon
     * @date        04-12-2020
     * @description Add default shipping conditions and transportation zone based on related account to non-copy of parent account (non account location ro). Only works on insert of account location
     * @revision(s)
     */
    private static void addDefaultValueSCTZ (List<Apttus_Config2__AccountLocation__c> newAccountList) {
        CustomLogging.push('addDefaultValueSCTZ', 'AccountLocationTriggerHandler');
        try {
            Set<Apttus_Config2__AccountLocation__c> accLocToUpdate = new Set<Apttus_Config2__AccountLocation__c>();
            for (Apttus_Config2__AccountLocation__c al: newAccountList) {
                if (al.Copy_of_Parent_Account__c == false) {
                    accLocToUpdate.add(al);
                }
            }

            if(!accLocToUpdate.isEmpty()) {
                SM_AccountLocationUtil.addDefaultValueSCTZ(accLocToUpdate);
            }
             
        } catch(Exception ex) {     
            CustomLogging.debugException(ex);
            CustomLogging.pop();      
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        CustomLogging.pop();
        
    }

    /**@author      Catherine Aragon
     * @date        07-12-2020
     * @description Validation rule for transportation zone per country iso
     * @revision(s)
     */
    private static void checkTransZone (List<Apttus_Config2__AccountLocation__c> newAccountList, Map<Id,Apttus_Config2__AccountLocation__c> oldAccountLocMap) {
        CustomLogging.push('checkTransZone', 'AccountLocationTriggerHandler');
        try {
           
            if(!oldAccountLocMap.isEmpty()) {
                Apttus_Config2__AccountLocation__c oldAccLoc;
                Set<Apttus_Config2__AccountLocation__c> accLocToUpdate = new Set<Apttus_Config2__AccountLocation__c>();
                    
                for (Apttus_Config2__AccountLocation__c al: newAccountList) {
                    oldAccLoc = oldAccountLocMap.get(al.Id);
                    if (al.Mini_Transportation_zone__c != NULL && al.Mini_Transportation_zone__c != oldAccLoc.Mini_Transportation_zone__c) {
                        accLocToUpdate.add(al);
                    }
                }

                if(!accLocToUpdate.isEmpty()) {
                    SM_AccountLocationUtil.tZoneValidation(accLocToUpdate);
                }
            }
             
        } catch(Exception ex) {     
            CustomLogging.debugException(ex);
            CustomLogging.pop();      
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        CustomLogging.pop();
        
    }
    
     /**@author     Francis Allen Alindogan
     * @date        02-12-2021
     * @description Method for providing share access to Third Party Resource on Account & Account Location
     * @revision(s)
     */    
    public void provideThirdPartyResourceAccess(List<SObject> newList, Map<Id, SObject> oldMapItems){
        
        CustomLogging.push('provideThirdPartyResourceAccess', 'AccountLocationTriggerHandler');
        
        Map<Id,Id> map_resource_user = new Map<Id, Id>();
        List<AccountShare> accList = new List<AccountShare>();                        
        List<Resource__Share> resourceList = new List<Resource__Share>();
        Map<Id, Id> map_for_share = new Map<Id, Id>();
        Map<Id, Id> map_for_removal = new Map<Id, Id>();        
        Set<Id> idForShare = new Set<Id>();        
        
        Boolean isCommunityUser = false;
        if(UserInfo.getUserType() != 'Standard') isCommunityUser = true;
        
        for(Apttus_Config2__AccountLocation__c newAccLoc: (List<Apttus_Config2__AccountLocation__c>) newList){
            Apttus_Config2__AccountLocation__c oldAccLoc = (Apttus_Config2__AccountLocation__c) oldMapItems.get(newAccLoc.Id);
            
            //IF THIRD PARTY HAS BEEN ASSIGNED
            if (newAccLoc.Third_Party_Resource__c != oldAccLoc.Third_Party_Resource__c && newAccLoc.Third_Party_Resource__c != null && newAccLoc.Apttus_Config2__AccountId__c != null){
                    map_for_share.put(newAccLoc.Apttus_Config2__AccountId__c, newAccLoc.Third_Party_Resource__c);
                    idForShare.add(newAccLoc.Third_Party_Resource__c);                    
                }       
        
        }
                                             
        //GET ALL RELATED USERS
        if (!idForShare.isEmpty()) {            	
            for (Resource__c r: [SELECT Id, RelatedUser__c FROM Resource__c WHERE Id IN:idForShare AND RelatedUser__c != null]){
                map_resource_user.put(r.Id, r.RelatedUser__c);
            }                                
            if(!map_resource_user.isEmpty()){                                              
                //LOOP FOR SHARING
                if(!map_for_share.isEmpty()){                                                                   
                    for(Id accId : map_for_share.keySet()){
                        AccountShare accAccess = new AccountShare();
                        accAccess.AccountId = accId;
                        accAccess.UserOrGroupId = map_resource_user.get(map_for_share.get(accId));
                        accAccess.AccountAccessLevel = TS_Constants.SHARING_ACCESSLEVEL_READ;
                        accAccess.RowCause = TS_Constants.SHARING_ROWCAUSE_MANUAL;
                        accAccess.OpportunityAccessLevel = TS_Constants.SHARING_ACCESSLEVEL_NONE;
                        accList.add(accAccess);                    
                    }                    			   
                }                                           
            }
                                
            //UPDATE SHARING LIST 
            if (!accList.isEmpty()
                && (Schema.sObjectType.AccountShare.fields.AccountId.isCreateable()
                    &&  Schema.sObjectType.AccountShare.fields.UserOrGroupId.isCreateable()
                    &&  Schema.sObjectType.AccountShare.fields.AccountAccessLevel.isCreateable()
                    &&  Schema.sObjectType.AccountShare.fields.RowCause.isCreateable()
                    ||  isCommunityUser)){
                        try {
                            insert accList;
                        } catch (Exception e){                    
                            System.debug(e);
                        }
                    }        
            CustomLogging.pop();
        }
    }
	
}