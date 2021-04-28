/**
 * Class Name: PromoteToSAPRemote
 * @author: Alvin Lomod
 * Date: 14-Mar-2018
 * Requirement: KASM-1376
 * @description: Promote to SAP an Account, create an iLog and change RT to Promotion Requested
 *
 */
 
global without sharing class PromoteToSAPRemote{
    
    //From Account
    //Button should only be from Prospect Valid Record type or Administrative Address Valid
    webservice static string PromoteToSAP(Id accId) {
        CustomLogging.push('PromoteToSAP', 'PromoteToSAPRemote');
        String retString = 'success';
        List<Account> accList;
        try{
            accList = [SELECT Id, Address_Validation__c, Sales_Organization__c, RecordTypeId, Commercial_Register_Number__c, Main_Postal_Box_Postal_Code__c, Main_Postal_Box__c, Main_Postal_Box_City__c, VAT_Registration_Number__c, EPI_Field_Updated__c, Account_Status__c, Prospect_promotion_status__c, Promote_to_Customer_By__c, Promoted_to_Customer_at__c, IsActive__c, RecordType.Name FROM Account WHERE Id =: accId];
            //if(accList[0].Commercial_Register_Number__c == null || accList[0].VAT_Registration_Number__c == null){
            //if Sales Organization is Belgium, Sweden, Norway, or Denmark, VAT and Commercial Registration number is mandatory
            if (accList[0].Prospect_promotion_status__c != 'Submitted for promotion' && accList[0].RecordType.Name != 'Customer') {
                if((accList[0].Sales_Organization__c == 'SAP_0975' || accList[0].Sales_Organization__c == 'SAP_0976' || accList[0].Sales_Organization__c == 'SAP_0333' || accList[0].Sales_Organization__c == 'SAP_6864') && accList[0].VAT_Registration_Number__c == null && accList[0].RecordTypeId != SM_Constants.recordTypeIdAdministrativeAddressValid){
                //if Commercial Register Number and/or VAT Register Number is blank, throw an error
                	retString = 'Commercial VAT Null';
                } else if (accList[0].Account_Status__c == 'Not Valid') {
                    retString = 'Account Status Invalid';
                } else if (accList[0].Address_Validation__c == 'Request Address Validation') {
                    retString = 'Account is under address validation';
                } else if (accList[0].Main_Postal_Box__c != Null && accList[0].Main_Postal_Box_Postal_Code__c == Null) {
                    retString = 'Invalid Main Postal Box Postal Code';
                } else if (accList[0].Main_Postal_Box_Postal_Code__c != Null && accList[0].Main_Postal_Box__c == Null) {
                    retString = 'Invalid Main Postal Box';
                } else if (accList[0].Main_Postal_Box_City__c != Null && accList[0].Main_Postal_Box_Postal_Code__c == Null && accList[0].Main_Postal_Box__c == Null) {
                    retString = 'Invalid Main Postal Box Postal Code and Main Postal Box';
                } else if (accList[0].IsActive__c == false){
                    retString = 'Account is inactive';
                } else{
                    if (checkRecursive.run == true) {
                        accList[0].RecordTypeId = Label.AccountRecordTypeId_PromotionRequested;
                        accList[0].EPI_Field_Updated__c = true;
                        accList[0].Prospect_promotion_status__c = 'Submitted for promotion';
                        accList[0].Promote_to_Customer_By__c = UserInfo.getUserId();
                        accList[0].Promoted_to_Customer_at__c = datetime.now();
                        update accList;
                        
                        List<Integration_Log__c> ilogList = new List<Integration_Log__c>();
                        Integration_Log__c iLog = new Integration_Log__c();
                        iLog.Object_Id__c = accId;
                        iLog.Object__c = 'Account'; 
                        iLog.Account__c = accId;
                        ilogList.add(iLog);
                        
                        Integration_Log__c iLogAD = new Integration_Log__c();
                        iLogAD.Object_Id__c = accId;
                        iLogAD.Object__c = 'Account Digital'; 
                        iLogAD.Account__c = accId;
                        ilogList.add(iLogAD);
                        
                        if (!ilogList.isEmpty()) {
                           insert ilogList; 
                        }
                        checkRecursive.run = false;
                    }
            	}
            } else {
                retString = 'Account is Promoted';
                if (accList[0].RecordType.Name == 'Customer'){
                    retString = 'Account is already a Customer';
                }
            }
            
        }catch(Exception e){
            retString = 'ERROR ' + e; 
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
            
        }
   
        return retString;
    }
    
    // Alvin Lomod
    // Promote To SAP for Account Location
    // Requirement: TBD
    webservice static string PromoteToSAPAccountLocation(Id accLocId) {
        CustomLogging.push('PromoteToSAPAccountLocation', 'PromoteToSAPRemote');
        String retString = 'success';
        List<Apttus_Config2__AccountLocation__c> accLocList;
        try{
            accLocList = [SELECT Id, Copy_of_Parent_Account__c, Apttus_Config2__AccountId__r.SAP_Customer_ID__c , RecordTypeId, Promotion_Status__c, EPI_Field_Updated__c, Account_Location_Status__c FROM Apttus_Config2__AccountLocation__c WHERE Id =: accLocId];
            if (accLocList[0].Promotion_Status__c != 'Submitted for promotion') {
            //Only account locations that are not copy of parent are valid for promotion to sap
            if(accLocList[0].Apttus_Config2__AccountId__r.SAP_Customer_ID__c != null && !accLocList[0].Copy_of_Parent_Account__c && (accLocList[0].RecordTypeId != Label.Account_Location_Validation_Record_Type_Id || accLocList[0].RecordTypeId != Label.AccountLocationRecordTypeId_PromotionRequested) && accLocList[0].Account_Location_Status__c != 'Not Valid'){
                accLocList[0].RecordTypeId = Label.AccountLocationRecordTypeId_PromotionRequested;
                accLocList[0].EPI_Field_Updated__c = true;
                    accLocList[0].Promotion_Status__c = 'Submitted for promotion';
                update accLocList;
                
                Integration_Log__c iLog = new Integration_Log__c();
                iLog.Object_Id__c = accLocId;
                iLog.Object__c = 'Account Location'; 
                iLog.AccountLocation__c = accLocId;
                insert iLog;
            }
            else if(accLocList[0].Apttus_Config2__AccountId__r.SAP_Customer_ID__c == null){
                retString = 'parent SAP Customer ID null';
            }
            else if(accLocList[0].Account_Location_Status__c == 'Not Valid') {
                retString = 'Account Status Invalid';
            }
            else if(accLocList[0].Copy_of_Parent_Account__c || accLocList[0].RecordTypeId == Label.Account_Location_Validation_Record_Type_Id || accLocList[0].RecordTypeId == Label.AccountLocationRecordTypeId_PromotionRequested){
                retString = 'not valid';
            }
            } else {
                retString = 'Account Location is Promoted';
            }            
        }catch(Exception e){
            retString = 'ERROR ' + e; 
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
   
        return retString;
    }
    
}