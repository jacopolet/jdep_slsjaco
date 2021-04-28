//-------------------------------------------------------------------------------------------//
// Author       :   Catherine Aragon - Accenture
// Created Date :   November 11 2018
// Usage        :   Utility Class for Account
//
//-------------------------------------------------------------------------------------------//
public without sharing class SM_AccountUtil {
    private static final User u = UserDAO.userInformation();
    private static Map<Id, Boolean> SAPRelatedFieldChanged = new Map<Id, Boolean>(); 
    public static List<Account> poBoxDependencies(List<Account> newAccountList) {
        CustomLogging.push('PoBoxDependencies', 'SM_AccountUtil');
        try {
            for (Account newAccount : newAccountList) {
                if (newAccount.Main_Postal_Box__c != Null && newAccount.Main_Postal_Box_Postal_Code__c == Null) {
                    newAccount.Main_Postal_Box__c.addError('Main Postal Box Postal Code is mandatory');
                } else if (newAccount.Main_Postal_Box_Postal_Code__c != Null && newAccount.Main_Postal_Box__c == Null) {
                    newAccount.Main_Postal_Box_Postal_Code__c.addError('Main Postal Box is mandatory');
                } else if (newAccount.Main_Postal_Box_City__c != Null && newAccount.Main_Postal_Box_Postal_Code__c == Null && newAccount.Main_Postal_Box__c == Null) {
                   newAccount.Main_Postal_Box_City__c.addError('Main Postal Box and Main Postal Box Postal Code is mandatory');
                }
            }
            return newAccountList;
        } catch(exception e){ CustomLogging.debugException(e); CustomLogging.pop(); System.debug(e.getMessage() + '\n' + e.getStackTraceString()); return null;
        } 
    }
    
    public static List<Account> paymentermEmpty(List<Account> newAccountList) {
        CustomLogging.push('paymentermEmpty', 'SM_AccountUtil');
        try {
            for (Account newAccount : newAccountList) {
                if (newAccount.Apttus_Config2__PaymentTermId__c == Null) {
                    newAccount.Apttus_Config2__PaymentTermId__c.addError('Payment Term is required');
                }
            }
            return newAccountList;
        } catch(exception e){ CustomLogging.debugException(e); CustomLogging.pop(); System.debug(e.getMessage() + '\n' + e.getStackTraceString()); return null;
        } 
    }
    
    public static List<Account> vatValidationRule(List<Account> newAccountList) {
        CustomLogging.push('vatValidationRule', 'SM_AccountUtil');
        try {
            Pattern vatFormat = Pattern.compile('^[a-zA-Z]{2}[0-9a-zA-Z]*$');
            Map <String, Decimal> vatRule = SM_GetMetadata.vatRule();
            Map <String, Decimal> vatLength = SM_GetMetadata.vatLength();
            for (Account newAccount : newAccountList) {
                Matcher vatMatch;
                //Length should not be greater than the needed length
                if(vatRule.get(newAccount.Main_Country_ISO__c) == 1){
                    if(newAccount.VAT_Registration_Number__c.length() <= vatLength.get(newAccount.Main_Country_ISO__c)){                           
                        vatMatch = vatFormat.matcher(newAccount.VAT_Registration_Number__c);
                        if(vatMatch.matches() == false){
                            newAccount.VAT_Registration_Number__c.addError('VAT Registration Number length should be equal or less than '+ vatLength.get(newAccount.Main_Country_ISO__c) + ' characters and starts with 2 letters');
                        }
                    }
                    else{
                        newAccount.VAT_Registration_Number__c.addError('VAT Registration Number length should be equal or less than '+ vatLength.get(newAccount.Main_Country_ISO__c) + ' characters and starts with 2 letters');
                    }
                }
                //Strict length to follow
                else if(vatRule.get(newAccount.Main_Country_ISO__c) == 3){
                    if(newAccount.VAT_Registration_Number__c.length() == vatLength.get(newAccount.Main_Country_ISO__c)){
                        vatMatch = vatFormat.matcher(newAccount.VAT_Registration_Number__c);
                        if(vatMatch.matches() == false){
                            newAccount.VAT_Registration_Number__c.addError('VAT Registration Number length should be '+ vatLength.get(newAccount.Main_Country_ISO__c) + ' characters and starts with 2 letters');
                        }
                    }
                    else{
                        newAccount.VAT_Registration_Number__c.addError('VAT Registration Number length should be '+ vatLength.get(newAccount.Main_Country_ISO__c) + ' characters and starts with 2 letters');
                    }
                    
                }
                else if(vatRule.get(newAccount.Main_Country_ISO__c) == 0){
                    if(newAccount.VAT_Registration_Number__c.length() <= vatLength.get(newAccount.Main_Country_ISO__c)){
                        vatMatch = vatFormat.matcher(newAccount.VAT_Registration_Number__c);
                        if(vatMatch.matches() == false){
                            newAccount.VAT_Registration_Number__c.addError('VAT Registration Number should starts with 2 letters');
                        }
                    }
                } 
            }
            return newAccountList;
        } catch(exception e){ CustomLogging.debugException(e); CustomLogging.pop(); System.debug(e.getMessage() + '\n' + e.getStackTraceString()); return null;
        } 
    }
    
    public static List<Account> postalBoxPostalCodeValidationRule(List<Account> newAccountList) {
        CustomLogging.push('postalBoxPostalCodeValidationRule', 'SM_AccountUtil');     
        try{
            Pattern fourFormat = Pattern.compile('^[0-9\\d+]*$');
            Pattern mtFormat = Pattern.compile('^[a-zA-Z]{3}[\\s]{1}[0-9]{4}');
            Pattern nlFormat = Pattern.compile('^[0-9]{4}[\\s]{1}[a-zA-Z]{2}');
            Pattern plFormat = Pattern.compile('^[0-9]{2}[\\-]{1}[0-9]{3}');
            Pattern ptFormat = Pattern.compile('^[0-9]{4}[\\-]{1}[0-9]{3}');
            Pattern seskczFormat = Pattern.compile('^[0-9]{3}[\\s]{1}[0-9]{2}');
            Map <String, Decimal> postalBoxRule = SM_GetMetadata.getpostalBoxRule();
            Map <String, Decimal> postalBoxLength = SM_GetMetadata.getpostalBoxLength();
            for(Account newAccount : newAccountList) {
                Matcher vatMatch; 
                //Strict length to follow
                if(postalBoxRule.get(newAccount.Main_Country_ISO__c) == 4){
                    if(newAccount.Main_Postal_Box_Postal_Code__c.length() == postalBoxLength.get(newAccount.Main_Country_ISO__c)) {
                        vatMatch = fourFormat.matcher(newAccount.Main_Postal_Box_Postal_Code__c);
                        if(vatMatch.matches() == false){
                            newAccount.Main_Postal_Box_Postal_Code__c.addError('Main Postal Box Postal Code length should be equal '+ postalBoxLength.get(newAccount.Main_Country_ISO__c) + ' numerical without gaps');
                        }
                    } else{
                        newAccount.Main_Postal_Box_Postal_Code__c.addError('Main Postal Box Postal Code length should be equal '+ postalBoxLength.get(newAccount.Main_Country_ISO__c) + ' numerical without gaps');
                    }
                }
                //Length should not be greater than  to the needed length
                else if(postalBoxRule.get(newAccount.Main_Country_ISO__c) == 5){
                    if(newAccount.Main_Postal_Box_Postal_Code__c.length() > postalBoxLength.get(newAccount.Main_Country_ISO__c)){
                        newAccount.Main_Postal_Box_Postal_Code__c.addError('Main Postal Box Postal Code length should be less than or equal '+ postalBoxLength.get(newAccount.Main_Country_ISO__c) + ' characters');
                    }
                }
                else if(postalBoxRule.get(newAccount.Main_Country_ISO__c) == 9){
                    if(newAccount.Main_Postal_Box_Postal_Code__c.length() == postalBoxLength.get(newAccount.Main_Country_ISO__c)){
                        if (newAccount.Main_Country_ISO__c == 'MT'){
                            vatMatch = mtFormat.matcher(newAccount.Main_Postal_Box_Postal_Code__c);
                            if(vatMatch.matches() == false){
                                newAccount.Main_Postal_Box_Postal_Code__c.addError('Main Postal Box Postal Code should follow the pattern "AAA NNNN". "A" means Letters and "N" is Numbers');
                            }
                        } else if (newAccount.Main_Country_ISO__c == 'NL'){
                            vatMatch = nlFormat.matcher(newAccount.Main_Postal_Box_Postal_Code__c);
                            if(vatMatch.matches() == false){
                                newAccount.Main_Postal_Box_Postal_Code__c.addError('Main Postal Box Postal Code should follow the pattern "NNNN AA". "A" means Letters and "N" is Numbers');
                            }
                        } else if (newAccount.Main_Country_ISO__c  == 'PL') {
                            vatMatch = plFormat.matcher(newAccount.Main_Postal_Box_Postal_Code__c);
                            if(vatMatch.matches() == false){
                                newAccount.Main_Postal_Box_Postal_Code__c.addError('Main Postal Box Postal Code should follow the pattern "NN-NNN". "N" means Numbers');
                            }
                        } else if (newAccount.Main_Country_ISO__c  == 'PT') {
                            vatMatch = ptFormat.matcher(newAccount.Main_Postal_Box_Postal_Code__c);
                            if(vatMatch.matches() == false){
                                newAccount.Main_Postal_Box_Postal_Code__c.addError('Main Postal Box Postal Code should follow the pattern "NNNN-NNN". "N" means Numbers');
                            }
                        } else if (newAccount.Main_Country_ISO__c  == 'SE' || newAccount.Main_Country_ISO__c  == 'SK' || newAccount.Main_Country_ISO__c  == 'CZ') {
                            vatMatch = seskczFormat.matcher(newAccount.Main_Postal_Box_Postal_Code__c);
                            if(vatMatch.matches() == false){
                                newAccount.Main_Postal_Box_Postal_Code__c.addError('Main Postal Box Postal Code should follow the pattern "NNN NN". "N" means Numbers');
                            }
                        } 
                    } else {
                        newAccount.Main_Postal_Box_Postal_Code__c.addError('Main Postal Box Postal Code length should be equal '+ postalBoxLength.get(newAccount.Main_Country_ISO__c));
                    }
                }
            }
            return newAccountList;
            
        } catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
            return null;
        }   
    }
    
    /*public static List<Account> financeControllerValidation(List<Account> newAccountList) {
        CustomLogging.push('financeControllerValidation', 'SM_AccountUtil');
        
        try{
            for (Account a : newAccountList) {
                a.addError('The Manager information on finance controller is missing, and therefore the system cant initiate an approval flow for the approval request submitted by the approver him/herself');
            }
            return newAccountList;
        } catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
            return null;
        } 
        
    }*/
    
    public static void updateAssignedApprover(List<Account> validAccountToUpdate) {
        CustomLogging.push('updateAssignedApprover', 'SM_AccountUtil');
        try{
            Map<Id, Account> validAccountMap = new Map<Id, Account>();
            Set<Id> financeIds = new Set<Id>();
            for (Account acct : validAccountToUpdate) {
                validAccountMap.put(acct.Id, acct);
                financeIds.add(acct.Finance_Controller_for_Account_Validatio__c);
            }
            List<ProcessInstanceWorkitem> ApprovalRequestList = new List<ProcessInstanceWorkitem>();
            if (validAccountMap.size() > 0 && !financeIds.isEmpty()) {
                Map<Id, Id> financeManagerMap = new Map<Id,Id>();
                for (User u : [Select Id, ManagerId FROM User WHERE Id in: financeIds]){
                    financeManagerMap.put(u.id, u.ManagerId);
                } 
                
                ApprovalRequestList = [SELECT Id, ActorId, OriginalActorId, ProcessInstanceId 
                                       FROM ProcessInstanceWorkitem piwi 
                                       WHERE piwi.ProcessInstanceId in (SELECT Id FROM ProcessInstance WHERE TargetObjectId in: validAccountMap.keySet())];
                
                if (ApprovalRequestList.size() > 0) {
                    Id financeManager;
                    for (ProcessInstanceWorkitem piwi : ApprovalRequestList) {
                        financeManager = financeManagerMap.get(piwi.ActorId);
                        if (financeManager != Null) {
                            piwi.ActorId = financeManager;                        }
                    }
                    
                    update ApprovalRequestList;
                }
            }
            
        } catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }  
    }

    public static List<Account> approvalRecallAndReject(List<Account> accts) {
        CustomLogging.push('approvalRecallAndReject', 'SM_AccountUtil');
        try{
            for(Account acct : accts) {
                Account oldAcc;
                if (acct.RecordTypeId == SM_Constants.recordTypeIdEndCustomerValidation ) {
                    acct.RecordTypeId = SM_Constants.recordTypeIdCustomer;
                } else {
                    acct.RecordTypeId = SM_Constants.recordTypeIdAdministrativeAddress; 
                }
                
                if (acct.Approval_Pending_Payment_Method__c != Null) {
                    acct.Approval_Pending_Payment_Method__c = Null;  
                } 

                if (acct.Remove_Payment_Method__c = true) {
                    acct.Remove_Payment_Method__c = false;
                }

                if (acct.Approval_Pending_Commercial_Register_No__c != Null) {
                    acct.Approval_Pending_Commercial_Register_No__c = Null;  
                } 

                if (acct.Approval_Pending_Payment_Term__c != Null) {
                    acct.Approval_Pending_Payment_Term__c = Null;  
                } 

                if (acct.Approval_Pending_Partner__c == true) {
                    acct.Approval_Pending_Partner__c = false;
                    acct.Wholesaler__c = false;
                    acct.FSD__c = false;
                    acct.Foodservice_Wholesaler__c = false;
                    acct.Office_Supplier__c = false;
                    acct.Vending__c = false;
                    acct.Cash_Carry__c = false;
                }
                
                if (acct.Approval_Pending_Customer_Pricing_Proc__c != Null) {
                    acct.Approval_Pending_Customer_Pricing_Proc__c = Null;  
                } 
            }
            
            return accts;
            
        } catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
            return null;
        } 
    }
    
    public static List<Account> approvalProcessApproved(List<Account> accts) { 
        CustomLogging.push('approvalProcessApproved', 'SM_AccountUtil');
        try{
            for(Account acct : accts) {
                if (acct.RecordTypeId == SM_Constants.recordTypeIdEndCustomerValidation || acct.RecordTypeId == SM_Constants.recordTypeIdAdministrativeAddressValidation) {
                    if (acct.Approval_Pending_Payment_Method__c == Null && acct.Approval_Pending_Payment_Term__c == Null && acct.Remove_Payment_Method__c == false) {
                        if(acct.RecordTypeId == SM_Constants.recordTypeIdEndCustomerValidation) {
                            acct.RecordTypeId = SM_Constants.recordTypeIdCustomer;
                        } else {
                            acct.RecordTypeId = SM_Constants.recordTypeIdAdministrativeAddress; 
                        }
                    }
                    if (acct.Approval_Pending_Commercial_Register_No__c != Null) {
                        acct.Commercial_Register_Number__c = acct.Approval_Pending_Commercial_Register_No__c;
                        acct.EPI_Field_Updated__c = true;
                        if (acct.Commercial_Register_Number__c != Null){
                            acct.Approval_Pending_Commercial_Register_No__c = Null;
                        }
                    }

                    if (acct.Approval_Pending_Partner__c == true) {
                        acct.Partner__c = acct.Approval_Pending_Partner__c;
                        
                    } else if (acct.Approval_Pending_Partner__c == false) {
                        acct.Partner__c = acct.Approval_Pending_Partner__c;
                        acct.Wholesaler__c = false;
                        acct.FSD__c = false;
                        acct.Foodservice_Wholesaler__c = false;
                        acct.Office_Supplier__c = false;
                        acct.Vending__c = false;
                        acct.Cash_Carry__c = false;
                    }

                    if (acct.Approval_Pending_Payment_Term__c != Null) {
                        acct.Updated_Payment_Terms__c = acct.Approval_Pending_Payment_Term__c;
                        if (acct.Updated_Payment_Terms__c != Null){
                            acct.Approval_Pending_Payment_Term__c = Null;
                        }
                    }

                    if (acct.Approval_Pending_Payment_Method__c == Null && acct.Remove_Payment_Method__c == true) {
                        acct.Updated_Payment_Method1__c = Null;
                        acct.Update_Payment_Method_Empty__c = acct.Remove_Payment_Method__c;
                        acct.Remove_Payment_Method__c = false;
                    } else {
                        acct.Updated_Payment_Method1__c = acct.Approval_Pending_Payment_Method__c;
                        if (acct.Updated_Payment_Method1__c != Null) {
                            acct.Approval_Pending_Payment_Method__c = Null;  
                        } 
                    }
                    
                    if (acct.Approval_Pending_Customer_Pricing_Proc__c != Null) {
                        acct.Updated_Customer_Pricing_Procedure__c = acct.Approval_Pending_Customer_Pricing_Proc__c;
                        if (acct.Updated_Customer_Pricing_Procedure__c != Null){
                            acct.Approval_Pending_Customer_Pricing_Proc__c = Null;
                        }
                    }
                } else {
                    if (acct.Approval_Pending_Commercial_Register_No__c != Null) {
                        acct.Commercial_Register_Number__c = acct.Approval_Pending_Commercial_Register_No__c;
                        acct.EPI_Field_Updated__c = true;
                        if (acct.Commercial_Register_Number__c != Null){
                            acct.Approval_Pending_Commercial_Register_No__c = Null;
                        }
                    }

                    if (acct.Approval_Pending_Partner__c == true) {
                        acct.Partner__c = acct.Approval_Pending_Partner__c;
                        acct.Approval_Pending_Partner__c = false;
                        
                    } else if (acct.Approval_Pending_Partner__c == false) {
                        acct.Partner__c = acct.Approval_Pending_Partner__c;
                        acct.Wholesaler__c = false;
                        acct.FSD__c = false;
                        acct.Foodservice_Wholesaler__c = false;
                        acct.Office_Supplier__c = false;
                        acct.Vending__c = false;
                        acct.Cash_Carry__c = false;
                    }

                    if (acct.Approval_Pending_Payment_Term__c != Null) {
                        acct.Apttus_Config2__PaymentTermId__c = acct.Approval_Pending_Payment_Term__c;
                        if (acct.Apttus_Config2__PaymentTermId__c != Null){
                            acct.Approval_Pending_Payment_Term__c = Null;
                        }
                    }

                    if (acct.Approval_Pending_Payment_Method__c == Null && acct.Remove_Payment_Method__c == true) {
                        acct.APTS_Payment_Method__c = Null;
                        acct.Remove_Payment_Method__c = false;
                    } else {
                        acct.APTS_Payment_Method__c = acct.Approval_Pending_Payment_Method__c;
                        if (acct.APTS_Payment_Method__c != Null) {
                            acct.Approval_Pending_Payment_Method__c = Null;  
                        } 
                    }
                    
                    if (acct.Approval_Pending_Customer_Pricing_Proc__c != Null) {
                        acct.Mini_Customer_Pricing_Procedure__c = acct.Approval_Pending_Customer_Pricing_Proc__c;
                        if (acct.Mini_Customer_Pricing_Procedure__c != Null){
                            acct.Approval_Pending_Customer_Pricing_Proc__c = Null;
                        }
                    }
                }
            }
            
            return accts;
            
        } catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
            return null;
        } 
    }
    
    public static void avgCoffeeDossage(List<Account> newAccounts) {
        CustomLogging.push('avgCoffeeDossage', 'SM_AccountUtil');
        try{
            Map<String, Brewing_System__c> mapBrewingSystem = Brewing_System__c.getAll(); 
            Map<String, String> bsApi = new Map<String, String>();
            bsApi.put('Instant', 'Instant__c');
            bsApi.put('Cafitesse', 'Cafitesse__c');
            bsApi.put('Espresso', 'Espresso__c');
            bsApi.put('Freshbrew', 'Freshbrew__c');
            bsApi.put('Promesso', 'Promesso__c');
            for (Account newAccount : newAccounts) {
                if (newAccount.Sales_Organization__c != Null) {
                    newAccount.Avg_Coffee_Dosage__c = decimal.valueof((String)mapBrewingSystem.get(newAccount.Sales_Organization__c).get(bsApi.get(newAccount.Brewing_System__c))); 
                }
            }
            
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
    }
    
    public static List<Account> defaultValuePerSalesOrg(List<Account> acctRecords) {
        CustomLogging.push('defaultValuePerSalesOrg', 'SM_AccountUtil');
        try {
            Id paymentId, paymentMId, accountIdGTMIng, accountIdGTMAssets, accountIdGTMServices, priceList, priceListPartner;
            Id recordTypeIdCustomer = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.Customer).getRecordTypeId();
            Id recordTypeIdAdministrativeAddress = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.AdministrativeAddress).getRecordTypeId();
            Id recordTypeIdProspect = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.Prospect).getRecordTypeId();
            Id recordTypeIdJDECompany = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.JDECompany).getRecordTypeId();
            Id recordTypeIdPurchasingOrg = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.PurchasingOrg).getRecordTypeId();
            Id recordTypeIdCompetitor =  Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.Competitor).getRecordTypeId();
            Id recordTypeIdProspectValid =  Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.ProspectValid).getRecordTypeId();
            String userProfileId = UserInfo.getProfileId();
            Mini_Template__c miniTemplate, minitempassign;
            User userRec;
            Set<String> paymentIdSet = new Set<String>();
            Set<String> paymentMIdSet = new Set<String>();
            Set<String> accountIdGTMIngSet = new Set<String>();
            Set<String> accountIdGTMAssetsSet = new Set<String>();
            Set<String> accountIdGTMServicesSet = new Set<String>();
            Set<String> priceListSet = new Set<String>();
            Map<String, Id> paymentIdValue = new Map<String, Id>();
            Map<String, Id> paymentMIdValue = new Map<String, Id>();
            Map<String, Id> accountIdGTMIngValue = new Map<String, Id>();
            Map<String, Id> accountIdGTMAssetsValue = new Map<String, Id>();
            Map<String, Id> accountIdGTMServicesValue = new Map<String, Id>();
            Map<String, Id> priceListValue = new Map<String, Id>();
            Map <String, Mini_Template__c> salesorgminitemplate = new Map <String, Mini_Template__c>();
            userRec = UserDAO.userInformation();
            Set<String> salesorgofrecords = new Set<String>();
            String usersalesorg;
            if (userRec.Profile.Name != 'JDE-Integration-Digital'){
                    salesorgofrecords.add(userRec.Sales_Organization__c);
                    usersalesorg = userRec.Sales_Organization__c;
            }
            else {
               for (Account a : acctRecords) {
                   if (a.Sales_Organization__c != null){
                       salesorgofrecords.add(a.Sales_Organization__c);
                   }
                } 
            }
            
            if (!salesorgofrecords.isEmpty()){
                for (String salesorg : salesorgofrecords){
                    salesorgminitemplate.put(salesOrg, Mini_Template__c.getInstance(salesOrg));
                    if (Mini_Template__c.getInstance(salesorg).Mini_Terms_of_payment__c != null){
                        paymentIdSet.add(Mini_Template__c.getInstance(salesorg).Mini_Terms_of_payment__c);
                    }
                    if (Mini_Template__c.getInstance(salesOrg).Payment_Method__c != null){
                        paymentMIdSet.add(Mini_Template__c.getInstance(salesOrg).Payment_Method__c);
                    }
                    if (Mini_Template__c.getInstance(salesOrg).GTM_Ingredients__c != null){
                        accountIdGTMIngSet.add(Mini_Template__c.getInstance(salesOrg).GTM_Ingredients__c);
                    }
                    if (Mini_Template__c.getInstance(salesOrg).GTM_Assets__c != null){
                        accountIdGTMAssetsSet.add(Mini_Template__c.getInstance(salesOrg).GTM_Assets__c);
                    }
                    if (Mini_Template__c.getInstance(salesOrg).GTM_Services__c != null){
                        accountIdGTMServicesSet.add(Mini_Template__c.getInstance(salesOrg).GTM_Services__c);
                    }
                    if (Mini_Template__c.getInstance(salesOrg).Price_List__c != null){
                        priceListSet.add(Mini_Template__c.getInstance(salesOrg).Price_List__c);
                    }
                }
                if (!paymentIdSet.isEmpty() && paymentIdSet != null) {
                    for (Apttus_Config2__PaymentTerm__c paymentIds : [Select Id, APTS_Ext_ID__c FROM Apttus_Config2__PaymentTerm__c WHERE APTS_Ext_ID__c IN: paymentIdSet]){
                        paymentIdValue.put(paymentIds.APTS_Ext_ID__c, paymentIds.Id);
                    }
                }
                if (!paymentMIdSet.isEmpty() && paymentMIdSet != null) {
                    for (APTS_Payment_Method__c paymentMIds : [Select Id, APTS_Ext_ID__c FROM APTS_Payment_Method__c WHERE APTS_Ext_ID__c IN: paymentMIdSet]){
                        paymentMIdValue.put(paymentMIds.APTS_Ext_ID__c, paymentMIds.Id);
                    }
                }
                if (!accountIdGTMIngSet.isEmpty() && accountIdGTMIngSet != null){
                    for (Account accountIdGTMIngs : [Select Id, Name FROM Account WHERE Name IN: accountIdGTMIngSet]){
                        accountIdGTMIngValue.put(accountIdGTMIngs.Name, accountIdGTMIngs.Id);
                    }
                }
                if (!accountIdGTMAssetsSet.isEmpty() && accountIdGTMAssetsSet != null){
                    for(Account accountIdGTMAssetss : [Select Id, Name FROM Account WHERE Name IN: accountIdGTMAssetsSet]){
                        accountIdGTMAssetsValue.put(accountIdGTMAssetss.Name, accountIdGTMAssetss.Id);
                    }
                }
                if (!accountIdGTMServicesSet.isEmpty() && accountIdGTMServicesSet != null){
                    for (Account accountIdGTMServicess : [Select Id, Name FROM Account WHERE Name IN: accountIdGTMServicesSet]){
                        accountIdGTMServicesValue.put(accountIdGTMServicess.Name, accountIdGTMServicess.Id);
                    } 
                }
                if (!priceListSet.isEmpty() && priceListSet != null) {
                    for (Apttus_Config2__PriceList__c priceLists : [Select Id, Name FROM Apttus_Config2__PriceList__c WHERE Name IN: priceListSet]){
                        priceListValue.put(priceLists.Name, priceLists.Id);
                    }
                }
                /*if (miniTemplate.Price_List_Partner__c != Null) {
                    priceListPartner = [Select Id FROM Apttus_Config2__PriceList__c WHERE Name = :miniTemplate.Price_List_Partner__c LIMIT 1].Id;
                }*/
                if (usersalesorg != null){
                    minitempassign =  Mini_Template__c.getInstance(usersalesorg);
                }
                
                for (Account acctRec : acctRecords) {
                    String SalesOrganization;
                    if (usersalesorg == null){
                         minitempassign = Mini_Template__c.getInstance(acctRec.Sales_Organization__c);
                    }
                       
                    if (acctRec.RecordTypeId == recordTypeIdCustomer || acctRec.RecordTypeId == recordTypeIdAdministrativeAddress || acctRec.RecordTypeId == recordTypeIdProspect || acctRec.RecordTypeId ==  recordTypeIdJDECompany || acctRec.RecordTypeId == recordTypeIdPurchasingOrg || acctRec.RecordTypeId == recordTypeIdProspectValid){
                        if (acctRec.Mini_Account_Group__c == Null) {
                            acctRec.Mini_Account_Group__c = minitempassign.Mini_Account_Group__c;
                        }
                        if (acctRec.WSONE_DATA__BillingCountryISO__c == Null) {
                            acctRec.WSONE_DATA__BillingCountryISO__c = minitempassign.Mini_Country_key__c;
                        }
                        if (acctRec.Transportation_zone__c == Null) {
                            acctRec.Transportation_zone__c = minitempassign.Mini_Transportation_zone__c;
                        }
                        if (acctRec.Mini_Company_Code__c == Null) {
                            acctRec.Mini_Company_Code__c = minitempassign.Mini_Company_Code__c;
                        }
                        if (acctRec.Mini_Reconciliation_Account__c == Null) {
                            acctRec.Mini_Reconciliation_Account__c = minitempassign.Mini_Reconciliation_Account__c;
                        }
                        if (acctRec.Mini_Payment_history_record__c == Null) {
                            acctRec.Mini_Payment_history_record__c = minitempassign.Mini_Payment_history_record__c;
                        }
                        acctRec.CurrencyIsoCode = minitempassign.Mini_Currency__c;
                        if (acctRec.Mini_Customer_Group__c == Null) {
                            acctRec.Mini_Customer_Group__c = minitempassign.Customer_Group_International_Customer__c;
                        }
                        if (acctRec.Price_Group__c == Null) {
                            acctRec.Price_Group__c = minitempassign.Mini_Price_Group__c;
                        }
                        if (acctRec.Mini_Customer_Pricing_Procedure__c == Null) {
                            acctRec.Mini_Customer_Pricing_Procedure__c = minitempassign.Mini_Customer_Pricing_Procedure__c;
                        }
                        if (acctRec.Mini_Delivery_Priority__c == Null) {
                            acctRec.Mini_Delivery_Priority__c = minitempassign.Mini_Delivery_Priority__c;
                        }
                        if (acctRec.Mini_Price_List_Type__c == Null) {
                            acctRec.Mini_Price_List_Type__c = minitempassign.Mini_Price_List_Type__c;
                        }
                        if (acctRec.Mini_Customer_Stats_Group__c == Null) {
                            acctRec.Mini_Customer_Stats_Group__c = minitempassign.Mini_Customer_Stats_Group__c;
                        }
                        if (acctRec.Mini_Shipping_Conditions__c == Null) {
                            acctRec.Mini_Shipping_Conditions__c = minitempassign.Mini_Shipping_Conditions__c;
                        }
                        if (acctRec.Mini_Incoterms_Part_1__c == Null) {
                            acctRec.Mini_Incoterms_Part_1__c = minitempassign.Mini_Incoterms_Part_1__c;
                        }
                        if (acctRec.Mini_Incoterms_Part_2__c == Null) {
                            acctRec.Mini_Incoterms_Part_2__c = minitempassign.Mini_Incoterms_Part_2__c;
                        }
                        if(!paymentIdValue.isEmpty() && acctRec.Apttus_Config2__PaymentTermId__c == null){
                            acctRec.Apttus_Config2__PaymentTermId__c = paymentIdValue.get(minitempassign.Mini_Terms_of_payment__c);
                        }
                        if (!paymentMIdValue.isEmpty() && acctRec.APTS_Payment_Method__c == null) {
                            acctRec.APTS_Payment_Method__c = paymentMIdValue.get(minitempassign.Payment_Method__c);
                        }
                        if (acctRec.Mini_Delivery_Control__c == Null) {
                            acctRec.Mini_Delivery_Control__c = minitempassign.Mini_Delivery_Control__c;
                        }
                        if (acctRec.Mini_Max_part_deliveries__c == Null) {
                            acctRec.Mini_Max_part_deliveries__c = minitempassign.Mini_Max_part_deliveries__c;
                        }
                        if (acctRec.Mini_Account_assigment_group__c == Null) {
                            acctRec.Mini_Account_assigment_group__c = minitempassign.Mini_Account_assigment_group__c;
                        }
                        if (acctRec.Sales_Organization__c == Null) {
                            acctRec.Sales_Organization__c = minitempassign.Mini_Sales_Organization__c;
                        }
                        if (acctRec.Nielsen_ID__c == Null) {
                            acctRec.Nielsen_ID__c = minitempassign.Mini_Nielsen_ID__c;
                        }
                        if (acctRec.Distribution_Channel__c == Null) {
                            acctRec.Distribution_Channel__c = minitempassign.Mini_Distribution_Channel__c;
                        }
                        if (acctRec.Division__c == Null) {
                            acctRec.Division__c = minitempassign.Mini_Division__c;
                        }
                        if (acctRec.Region__c == Null) {
                            acctRec.Region__c = minitempassign.Mini_Region__c;
                        }
                        if (acctRec.Sales_Office__c == Null) {
                            acctRec.Sales_Office__c = minitempassign.Sales_Office__c;
                        }
                        if (acctRec.Apttus_Config2__BillingPreferenceId__c == Null) {
                            acctRec.Apttus_Config2__BillingPreferenceId__c = minitempassign.Billing_Preference__c;
                        }
                        if (acctRec.Mini_Dunning_procedure__c == Null) {
                            acctRec.Mini_Dunning_procedure__c = minitempassign.Dunning_procedure__c;
                        }
                        if (acctRec.Sales_Group__c == Null) {
                            acctRec.Sales_Group__c = minitempassign.Sales_Group__c;
                        }
                        if (acctRec.Language__c == Null) {
                            acctRec.Language__c = minitempassign.Mini_Language__c;
                        }
                        if (!accountIdGTMIngValue.isEmpty() && acctRec.GTM_Ingredients__c == Null){
                            acctRec.GTM_Ingredients__c = accountIdGTMIngValue.get(minitempassign.GTM_Ingredients__c);
                        }
                        if (!accountIdGTMAssetsValue.isEmpty() && acctRec.GTM_Machine__c == Null ) {
                            acctRec.GTM_Machine__c = accountIdGTMAssetsValue.get(minitempassign.GTM_Assets__c);
                        }
                        if (!accountIdGTMServicesValue.isEmpty() && acctRec.GTM_Service__c == Null ) {
                            acctRec.GTM_Service__c = accountIdGTMServicesValue.get(minitempassign.GTM_Services__c);
                        }
                        if (!priceListValue.isEmpty() && acctRec.APTS_Price_List__c == Null) {
                            acctRec.APTS_Price_List__c = priceListValue.get(minitempassign.Price_List__c);
                        }
                        if (acctRec.Invoice_List_Dates__c == Null) {
                            acctRec.Invoice_List_Dates__c = minitempassign.Invoicing_List_dates__c;
                        }
                        if (acctRec.Mini_Invoicing_dates__c == Null) {
                            acctRec.Mini_Invoicing_dates__c = minitempassign.Invoicing_dates__c;
                        }
                    }  
                }
            }
            // if (salesOrg != Null) {
            //     miniTemplate = Mini_Template__c.getInstance(salesOrg);
            // }
            
            
            return acctRecords;
        } catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
            return null;
        }
       
    }
    
    public static List<Account> populateAverage(List<Account> acts){
        CustomLogging.push('populateAverage', 'SM_AccountUtil');
        try{
            List<Account_Value_Estimation_Size_Price__c> listAve = new List<Account_Value_Estimation_Size_Price__c>();
            Map<String,Account_Value_Estimation_Size_Price__c> mapAVESize = new map<String,Account_Value_Estimation_Size_Price__c>();
            Map<String,Account_Value_Estimation_Size_Price__c> mapAVEPrice = new map<String,Account_Value_Estimation_Size_Price__c>();
            Id recordTypeIdAVEPrice = Schema.SObjectType.Account_Value_Estimation_Size_Price__c.getRecordTypeInfosByName().get(SM_Constants.AVEPrice).getRecordTypeId();
            Id recordTypeIdAVESize = Schema.SObjectType.Account_Value_Estimation_Size_Price__c.getRecordTypeInfosByName().get(SM_Constants.AVESize).getRecordTypeId();    
            Id recordTypeIdServiceProvider = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.AccountServiceProvider).getRecordTypeId(); 
            listAVE = [Select Number_of_Drinks_per_Size_Type__c, Subsegment__c, Avg_Price_per_Drink__c, Company_Code__c, Segment__c, Size_Type_Input__c, RecordTypeId from Account_Value_Estimation_Size_Price__c];
            if (listAVE.size() > 0) {
                for (Account_Value_Estimation_Size_Price__c ave : listAVE) {
                    if(ave.RecordtypeID ==  recordTypeIdAVEPrice ) {
                        mapAVEPrice.put(ave.Company_Code__c + ave.Segment__c + ave.Subsegment__c, ave);     
                    } else if (ave.RecordtypeID ==  recordTypeIdAVESize ) {
                        mapAVESize.put(ave.Company_Code__c + ave.Segment__c + ave.Subsegment__c, ave);     
                    }
                }
            }
            for (Account act : acts) {
                if (act.RecordTypeId != recordTypeIdServiceProvider){                                        
                    if (act.Calculation_Method__c == '#FTE' ) {
                        if (act.of_Employees_FTE__c != 0 && act.of_Employees_FTE__c != null && act.Penetration__c != 0 && act.Penetration__c != null && act.Mini_Company_Code__c != null && act.Segment__c != null && act.Tea_Drinks__c != 0 && act.Tea_Drinks__c != null) {
                            if(mapAVESize.containsKey(act.Mini_Company_Code__c + act.Segment__c + act.Subsegment__c)){
                                act.of_drinks__c = act.of_Employees_FTE__c * (act.Penetration__c / 100) * mapAVESize.get(act.Mini_Company_Code__c + act.Segment__c + act.Subsegment__c).Number_of_Drinks_per_Size_Type__c;
                                act.Coffee_Drinks__c = 100 - act.Tea_Drinks__c; 
                                act.Expected_Tea_Drinks__c = (act.Tea_Drinks__c / 100) * act.of_drinks__c; 
                                act.Expected_Coffee_Drinks__c = (act.Coffee_Drinks__c / 100) * act.of_drinks__c;
                                act.Estimated_Revenue_Potential__c = mapAVEPrice.get(act.Mini_Company_Code__c + act.Segment__c + act.Subsegment__c).Avg_Price_per_Drink__c * act.of_drinks__c;
                                act.Share_of_Wallet__c = act.Account_Annual_Value__c / (act.Estimated_Revenue_Potential__c / 100);
                                act.Estimated_Coffee_Potential_in_KG_L__c = act.Expected_Coffee_Drinks__c * act.Avg_Coffee_Dosage__c / 1000;
                                
                                
                            } else if(mapAVESize.containsKey(act.Mini_Company_Code__c + act.Segment__c + 'Default')){
                                act.of_drinks__c = act.of_Employees_FTE__c * (act.Penetration__c / 100) * mapAVESize.get(act.Mini_Company_Code__c + act.Segment__c + 'Default').Number_of_Drinks_per_Size_Type__c;
                                act.Coffee_Drinks__c = 100 - act.Tea_Drinks__c; 
                                act.Expected_Tea_Drinks__c = (act.Tea_Drinks__c / 100) * act.of_drinks__c; 
                                act.Expected_Coffee_Drinks__c = (act.Coffee_Drinks__c / 100) * act.of_drinks__c;
                                act.Estimated_Revenue_Potential__c = mapAVEPrice.get(act.Mini_Company_Code__c + act.Segment__c + 'Default').Avg_Price_per_Drink__c * act.of_drinks__c;
                                act.Share_of_Wallet__c = act.Account_Annual_Value__c / (act.Estimated_Revenue_Potential__c / 100);
                                act.Estimated_Coffee_Potential_in_KG_L__c = act.Expected_Coffee_Drinks__c * act.Avg_Coffee_Dosage__c / 1000;
                                
                            } else {
                                act.of_drinks__c = 0;
                                act.Coffee_Drinks__c = 0; 
                                act.Expected_Tea_Drinks__c = 0; 
                                act.Expected_Coffee_Drinks__c = 0;
                                act.Estimated_Revenue_Potential__c = 0;
                                act.Share_of_Wallet__c = 0;
                                act.Estimated_Coffee_Potential_in_KG_L__c = 0;   
                            }
                        } else {
                            act.of_drinks__c = 0;
                            act.Coffee_Drinks__c = 0; 
                            act.Expected_Tea_Drinks__c = 0; 
                            act.Expected_Coffee_Drinks__c = 0;
                            act.Estimated_Revenue_Potential__c = 0;
                            act.Share_of_Wallet__c = 0;
                            act.Estimated_Coffee_Potential_in_KG_L__c = 0;
                        }
                    } else {
                        if (act.Estimated_Coffee_Potential_in_KG_L__c != 0 && act.Estimated_Coffee_Potential_in_KG_L__c != null && act.Penetration__c != 0 && act.Penetration__c != null && act.Mini_Company_Code__c != null && act.Segment__c != null && act.Tea_Drinks__c != 0 && act.Tea_Drinks__c != null) {
                            if(mapAVESize.containsKey(act.Mini_Company_Code__c + act.Segment__c +   act.Subsegment__c)){
                                act.Coffee_Drinks__c = 100 - act.Tea_Drinks__c; 
                                act.Expected_Coffee_Drinks__c = (act.Estimated_Coffee_Potential_in_KG_L__c * 1000) / act.Avg_Coffee_Dosage__c;
                                act.of_drinks__c = act.Expected_Coffee_Drinks__c / (act.Coffee_Drinks__c /100);
                                act.Expected_Tea_Drinks__c = act.of_drinks__c - act.Expected_Coffee_Drinks__c;
                                act.Estimated_Revenue_Potential__c = mapAVEPrice.get(act.Mini_Company_Code__c + act.Segment__c + act.Subsegment__c).Avg_Price_per_Drink__c * act.of_drinks__c;
                                act.Share_of_Wallet__c = act.Account_Annual_Value__c / (act.Estimated_Revenue_Potential__c / 100);
                                
                            } else  if(mapAVESize.containsKey(act.Mini_Company_Code__c + act.Segment__c + 'Default')){
                                act.Coffee_Drinks__c = 100 - act.Tea_Drinks__c; 
                                act.Expected_Coffee_Drinks__c = (act.Estimated_Coffee_Potential_in_KG_L__c * 1000) / act.Avg_Coffee_Dosage__c;
                                act.of_drinks__c = act.Expected_Coffee_Drinks__c / (act.Coffee_Drinks__c /100);
                                act.Expected_Tea_Drinks__c = act.of_drinks__c - act.Expected_Coffee_Drinks__c;
                                act.Estimated_Revenue_Potential__c = mapAVEPrice.get(act.Mini_Company_Code__c + act.Segment__c + 'Default').Avg_Price_per_Drink__c * act.of_drinks__c;
                                act.Share_of_Wallet__c = act.Account_Annual_Value__c / (act.Estimated_Revenue_Potential__c / 100);
                                
                            } else {
                                act.of_drinks__c = 0;
                                act.Coffee_Drinks__c = 0; 
                                act.Expected_Tea_Drinks__c = 0; 
                                act.Expected_Coffee_Drinks__c = 0;
                                act.Estimated_Revenue_Potential__c = 0;
                                act.Share_of_Wallet__c = 0;   
                            }
                        } else {
                            act.of_drinks__c = 0;
                            act.Coffee_Drinks__c = 0; 
                            act.Expected_Tea_Drinks__c = 0; 
                            act.Expected_Coffee_Drinks__c = 0;
                            act.Estimated_Revenue_Potential__c = 0;
                            act.Share_of_Wallet__c = 0;
                        }   
                    }
                }  
            }
            
            return acts;
            
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
            return null;
        }
        
    }
    
    public static void createAccountTax(List<Account> accountRecs) {
        CustomLogging.push('insertAccountTax', 'AccountTriggerHandler');
        try{
            User userRec = new User();
            userRec = [Select Sales_Organization__c, Profile.Name FROM User WHERE Id= :UserInfo.getUserId()];
            Map<Id, String> salesOrg = new Map<Id, String>();
            for (Account a : accountRecs) {
                if (userRec.Profile.Name != 'JDE-Integration-Digital'){
                    salesOrg.put(a.Id, userRec.Sales_Organization__c);
                } else {
                    salesOrg.put(a.Id, a.Sales_Organization__c);
                }
            }
            if (!salesOrg.isEmpty()) {
                List<MiniTemplateTax__c> miniTemplateTaxes = new List<MiniTemplateTax__c>();
                List<Account_Tax__c> acctaxes = new List<Account_Tax__c>();
                miniTemplateTaxes = [Select Id, Name, Sales_Organization__c, Tax_category__c, Tax_classification__c, Tax_Country__c FROM MiniTemplateTax__c WHERE Sales_Organization__c IN :salesOrg.values()];
                for(Account acct : accountRecs) {
                    for (MiniTemplateTax__c miniTemplateTax : miniTemplateTaxes) {
                        if (salesOrg.get(acct.Id) == miniTemplateTax.Sales_Organization__c) {
                            Account_Tax__c accTax = new Account_Tax__c();
                            accTax.Mini_Account__c = acct.id;
                            accTax.Mini_Tax_Category__c = miniTemplateTax.Tax_category__c;
                            accTax.Mini_Tax_Classification__c = miniTemplateTax.Tax_classification__c;
                            accTax.Mini_Tax_Country__c = miniTemplateTax.Tax_Country__c;
                            acctaxes.add(accTax);
                        }
                    }  
                }
                
                if (!acctaxes.isEmpty()) {
                   insert acctaxes; 
                }
         
            }
            
        } catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
    }

    public static List<Account> assignJDESicCode(List<Account> acctMaps) {
        CustomLogging.push('assignJDESicCode', 'SM_AccountUtil');
        try{
            List<JDE_SIC_Mapping__c> jdesic = new List<JDE_SIC_Mapping__c>();
            Set<Id> jdeId = new Set<Id>();
            for (Account jdeIdRec : acctMaps) {
                jdeId.add(jdeIdRec.SIC_Name__c);
            }
            if (!jdeId.isEmpty()) {
                jdesic = [Select Segment_2__c, Sub_Segment__c from JDE_SIC_Mapping__c where ID = :jdeId];
            }
            
            for (Account acctMap : acctMaps) {
                if (acctMap.SIC_Name__c != null){
                    for (JDE_SIC_Mapping__c jdeSicRec : jdesic) {
                        if (jdeSicRec.Segment_2__c == SM_Constants.HighSegmentBiz){
                            if (acctMap.of_Employees_FTE__c < 50){
                                acctMap.Segment__c = SM_Constants.SPKLSmallB;
                                acctMap.Subsegment__c = jdeSicRec.Sub_Segment__c;
                            }
                            else if (acctMap.of_Employees_FTE__c < 250){
                                acctMap.Segment__c = SM_Constants.SPKLMediumB;
                                acctMap.Subsegment__c  = jdeSicRec.Sub_Segment__c;
                            }
                            else if (acctMap.of_Employees_FTE__c >= 250){
                                acctMap.Segment__c = SM_Constants.SPKLLargeB;
                                acctMap.Subsegment__c  = jdeSicRec.Sub_Segment__c;
                            }
                        } else if (jdeSicRec.Segment_2__c == SM_Constants.HighSegmentHC && jdeSicRec.Sub_Segment__c == SM_Constants.SSHealthServices){
                            if (acctMap.of_Employees_FTE__c < 50){
                                acctMap.Segment__c = SM_Constants.SPKLSmallB;
                                acctMap.Subsegment__c  = SM_Constants.HighSegmentHC;
                            }
                            else if (acctMap.of_Employees_FTE__c < 250){
                                acctMap.Segment__c = SM_Constants.SPKLMediumB;
                                acctMap.Subsegment__c  = SM_Constants.HighSegmentHC;
                            }
                            else if (acctMap.of_Employees_FTE__c >= 250){
                                acctMap.Segment__c = SM_Constants.SPKLHealth;
                                acctMap.Subsegment__c  = jdeSicRec.Sub_Segment__c;
                            }
                        } else if (jdeSicRec.Segment_2__c == SM_Constants.HighSegmentHC && jdeSicRec.Sub_Segment__c == SM_Constants.SSDocDentEtc){
                            if (acctMap.of_Employees_FTE__c < 50){
                                acctMap.Segment__c = SM_Constants.SPKLSmallB;
                                acctMap.Subsegment__c  = SM_Constants.HighSegmentHC;
                            }
                            else if (acctMap.of_Employees_FTE__c < 250){
                                acctMap.Segment__c = SM_Constants.SPKLMediumB;
                                acctMap.Subsegment__c  = SM_Constants.HighSegmentHC;
                            }
                            else if (acctMap.of_Employees_FTE__c >= 250){
                                acctMap.Segment__c = SM_Constants.SPKLHealth;
                                acctMap.Subsegment__c  = jdeSicRec.Sub_Segment__c;
                            }
                        } else if (jdeSicRec.Segment_2__c == SM_Constants.HighSegmentEduc && jdeSicRec.Sub_Segment__c == SM_Constants.SSEducElemSec || jdeSicRec.Segment_2__c == SM_Constants.HighSegmentEduc && jdeSicRec.Sub_Segment__c == SM_Constants.SSEducEtcEduc){
                            if (acctMap.of_Employees_FTE__c < 50){
                                acctMap.Segment__c = SM_Constants.SPKLSmallB;
                                acctMap.Subsegment__c  = SM_Constants.SSEducEduc;
                            }
                            else if (acctMap.of_Employees_FTE__c < 250){
                                acctMap.Segment__c = SM_Constants.SPKLMediumB;
                                acctMap.Subsegment__c  = SM_Constants.SSEducEduc;
                            }
                            else if (acctMap.of_Employees_FTE__c >= 250){
                                acctMap.Segment__c = SM_Constants.SPKLEduc;
                                acctMap.Subsegment__c  = jdeSicRec.Sub_Segment__c;
                            }
                        } else{
                            if (jdeSicRec.Segment_2__c == SM_Constants.HighSegmentHC){
                                acctMap.Segment__c = SM_Constants.SPKLHealth; 
                            }
                            else if (jdeSicRec.Segment_2__c == SM_Constants.HighSegmentEduc){
                                acctMap.Segment__c = SM_Constants.SPKLEduc;
                            }
                            else if (jdeSicRec.Segment_2__c == SM_Constants.HighSegmentResBar){
                                acctMap.Segment__c = SM_Constants.SPKLResBar;
                            }
                            else if (jdeSicRec.Segment_2__c == SM_Constants.HighSegmentHotGam){
                                acctMap.Segment__c = SM_Constants.SPKLHotGam;
                            }
                            else if (jdeSicRec.Segment_2__c == SM_Constants.HighSegmentQckCof){
                                acctMap.Segment__c = SM_Constants.SPKLQckCof;
                            }
                            else if (jdeSicRec.Segment_2__c == SM_Constants.HighSegmentConRet){
                                acctMap.Segment__c = SM_Constants.SPKLConRet;
                            }
                            else if (jdeSicRec.Segment_2__c == SM_Constants.HighSegmentLeis){
                                acctMap.Segment__c = SM_Constants.SPKLLeis;
                            }
                            acctMap.Subsegment__c = jdeSicRec.Sub_Segment__c;
                        }
                    }
                    if (acctMap.Segment__c == null && acctMap.Subsegment__c == null){
                        acctMap.SIC_Name__c = acctMap.SIC_Name__c;
                    }
                    else if (acctMap.Segment__c != null && acctMap.Subsegment__c != null){
                        acctMap.SIC_Name__c = acctMap.SIC_Name__c;
                        acctMap.Segment__c = acctMap.Segment__c;
                        acctMap.Subsegment__c  = acctMap.Subsegment__c;
                    }
                    
                } else if (acctMap.Segment__c != null && acctMap.Subsegment__c != null && acctMap.SIC_Name__c == null){
                    if (acctMap.Segment__c == SM_Constants.SPKLSmallB || acctMap.Segment__c == SM_Constants.SPKLMediumB || acctMap.Segment__c == SM_Constants.SPKLLargeB){
                        if (acctMap.of_Employees_FTE__c < 50){
                            acctMap.Segment__c = SM_Constants.SPKLSmallB;
                            acctMap.Subsegment__c  = acctMap.Subsegment__c;
                        }
                        else if (acctMap.of_Employees_FTE__c < 250){
                            acctMap.Segment__c = SM_Constants.SPKLMediumB;
                            acctMap.Subsegment__c  = acctMap.Subsegment__c;
                        }
                        else if (acctMap.of_Employees_FTE__c >= 250){
                            acctMap.Segment__c = SM_Constants.SPKLLargeB;
                            acctMap.Subsegment__c = acctMap.Subsegment__c;
                        }
                    }else if (acctMap.Segment__c == SM_Constants.SPKLHealth && acctMap.Subsegment__c == SM_Constants.SSHealthServices || acctMap.Segment__c == SM_Constants.SPKLHealth && acctMap.Subsegment__c == SM_Constants.SSDocDentEtc){
                        if (acctMap.of_Employees_FTE__c < 50){
                            acctMap.Segment__c = SM_Constants.SPKLSmallB;
                            acctMap.Subsegment__c = SM_Constants.HighSegmentHC;
                        }
                        else if (acctMap.of_Employees_FTE__c < 250){
                            acctMap.Segment__c = SM_Constants.SPKLMediumB;
                            acctMap.Subsegment__c = SM_Constants.HighSegmentHC;
                        }
                        else if (acctMap.of_Employees_FTE__c >= 250){
                            acctMap.Segment__c = SM_Constants.SPKLHealth;
                            acctMap.Subsegment__c = acctMap.Subsegment__c;
                        }
                    }else if (acctMap.Segment__c == SM_Constants.SPKLEduc && acctMap.Subsegment__c == SM_Constants.SSEducElemSec || acctMap.Segment__c == SM_Constants.SPKLEduc && acctMap.Subsegment__c == SM_Constants.SSEducEtcEduc ){
                        if (acctMap.of_Employees_FTE__c < 50){
                            acctMap.Segment__c = SM_Constants.SPKLSmallB;
                            acctMap.Subsegment__c = SM_Constants.SSEducEduc;
                        }
                        else if (acctMap.of_Employees_FTE__c < 250){
                            acctMap.Segment__c = SM_Constants.SPKLMediumB;
                            acctMap.Subsegment__c = SM_Constants.SSEducEduc;
                        }
                        else if (acctMap.of_Employees_FTE__c >= 250){
                            acctMap.Segment__c = SM_Constants.SPKLEduc;
                            acctMap.Subsegment__c = acctMap.Subsegment__c;
                        }
                        else{
                            acctMap.Segment__c = acctMap.Segment__c;
                            acctMap.Subsegment__c = acctMap.Subsegment__c;
                        }
                    }
                }
            }
            
            return acctMaps;
              
        } catch(exception e){ CustomLogging.debugException(e); CustomLogging.pop();System.debug(e.getMessage() + '\n' + e.getStackTraceString());
            return null; 
        }
       
    }
    
    public static Integration_Log__c createIlog(Account newAccount, String objectString){
        Integration_Log__c ilogCreation = new Integration_Log__c();
        ilogCreation.Object_Id__c = newAccount.Id;
        ilogCreation.Object__c = objectString;
        ilogCreation.Account__c = newAccount.Id;
        ilogCreation.Integration_Status__c = INT_Constants.INITIAL;
        
        return ilogCreation;
    }
    
    public static List<Account> stampTransportationZone(List<Account> acctList){ 
        CustomLogging.push('stampTransportationZoneBasedOnMainCountryISO', 'AccountTriggerHandler');
        try {
            List<Account> accountUpdated = new List<Account>();
            for (Account a : acctList) {
                if (a.Updated_Main_Country_ISO__c == null){
                    Transportation_Zone__c tz = Transportation_Zone__c.getInstance(a.Main_Country_ISO__c);
                    if(tz != Null){
                        if (tz.Transportation_Zone__c != Null) {
                            a.Transportation_zone__c = tz.Transportation_Zone__c;
                            accountUpdated.add(a);  
                        }
                    }
                }
                else {
                    Transportation_Zone__c tz = Transportation_Zone__c.getInstance(a.Updated_Main_Country_ISO__c);
                    if(tz != Null){
                        if (tz.Transportation_Zone__c != Null) {
                            a.Transportation_zone__c = tz.Transportation_Zone__c;
                            accountUpdated.add(a);  
                        }
                    }
                }
            }
            
            return accountUpdated;
         } catch (Exception ex) {
             CustomLogging.debugException(ex);
             CustomLogging.pop();
             System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
             return null;
         }
    }
   
    public static Integration_Log__c CreateIntegrationLogForAgreementAcc(Id agreeId, Id accId){
        
        Integration_Log__c iLog = new Integration_Log__c();
        
        if(accId != null){      
            iLog.Object_Id__c = accId;
            iLog.Object__c = 'Account'; 
            iLog.Account__c = accId;
            iLog.Integration_Status__c = INT_Constants.INITIAL;
            iLog.Agreement__c = agreeId;
        }
        
        return iLog;
    }
    
    public static List<Account> billToPayerValidation (List<Account> newAccountList, Map<Id, Account> bill2Map) {
        CustomLogging.push('billToPayerValidation', 'SM_AccountUtil');
        try{
            String bill2Payer_ErrorMessage = System.Label.Bill2Payer_ErrorMessage;
            for(Account bill: newAccountList){                  
                //2 Account records cannot be each others bill to payers
                if(bill.Bill_To_Payer_Account__c != null){
                    if(bill.Bill_To_Payer_Account__c == bill2Map.get(bill.Id).Id){
                        bill2Map.get(bill.Id).Bill_To_Payer_Account__c.addError(bill2Payer_ErrorMessage);
                    }
                }
            }
        
            return newAccountList;
        } catch (Exception ex) {
             CustomLogging.debugException(ex);
             CustomLogging.pop();
             System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
             return null;
        }
    }
    
     public static void changeFieldValue(Set<Account> accountRecs, Map<Id,Account> oldAccountRecs, Map<String, String> accountFields, Map<String, String> addressFields, Boolean epiUpdated){
        CustomLogging.push('changeFieldValue', 'SM_AccountUtil');
        try{
            //Specify if value from the fields were changed
            Boolean isChange = false;
            
            Account oldAcc;
            for(Account acctMap : accountRecs){
                oldAcc = oldAccountRecs.get(acctMap.Id);
                if (!accountFields.isEmpty()) {
                    for(String fld : accountFields.keySet()){
                        if(acctMap.get(fld) != oldAcc.get(fld)){
                            //Check if VAT is changed to blank, but only applicable to Belgium, Norway, Sweden and Denmark Sales Organization
                            if(fld == 'VAT_Registration_Number__c'){
                                if(acctMap.VAT_Registration_Number__c == null && acctMap.RecordTypeId != SM_Constants.recordTypeIdAdministrativeAddress 
                                   && acctMap.RecordTypeId != SM_Constants.recordTypeIdAdministrativeAddressInvalid && acctMap.RecordTypeId != SM_Constants.recordTypeIdAdministrativeAddressValid 
                                   && acctMap.RecordTypeId != SM_Constants.recordTypeIdAdministrativeAddressValidation && (acctMap.Sales_Organization__c == 'SAP_0975' || acctMap.Sales_Organization__c == 'SAP_0976' || acctMap.Sales_Organization__c == 'SAP_0333' || acctMap.Sales_Organization__c == 'SAP_6864')){
                                    acctMap.VAT_Registration_Number__c.addError('Please fill VAT Registration Number');
                                }
                            }
                            //|| fld == 'Main_Address_ILN_1__c' || fld == 'Main_Address_ILN_2__c' || fld == 'Main_Address_ILN_Digit__c'
                            if((fld == 'Delivery_Block_Reason__c' || fld == 'Mini_Dunning_procedure__c' || fld == 'Sales_Office__c' || fld == 'Sales_Group__c' || fld == 'Bill_Block_Reason__c' || fld == 'Transactional_Block_Reason__c' || fld == 'Mini_Invoicing_dates__c' || fld == 'Invoice_List_Dates__c' || fld == 'House_Number_Supplement__c' || fld == 'Second_Account_Name__c' || fld == 'Third_Account_Name__c' || fld == 'Fourth_Account_Name__c' || fld == 'Main_Postal_Box_City__c' || fld == 'Main_Postal_Box__c' || fld =='Main_Postal_Box_Postal_Code__c' || fld == 'Billing_Header_Text__c' || fld == 'Mini_Incoterms_Part_2__c') && acctMap.get(fld) == null){
                                acctMap.put(accountFields.get(fld), 'NULL');
                                acctMap.put(fld, oldAcc.get(fld));
                                SAPRelatedFieldChanged.put(acctMap.Id, True);
                            } else if (fld == 'Account_block__c' || fld == 'Archiving_flag__c'){
                                if (acctMap.get(fld) == FALSE){
                                    acctMap.put(accountFields.get(fld), 'false');
                                } else{
                                    acctMap.put(accountFields.get(fld), 'true');
                                }
                                acctMap.put(fld, oldAcc.get(fld));
                                SAPRelatedFieldChanged.put(acctMap.Id, True);
                                
                                if (fld == 'Archiving_Flag__c'){
                                    acctMap.put('IsActive__c', oldAcc.IsActive__c);
                                    acctMap.put('Last_Relevant_Activity_Date__c', oldAcc.Last_Relevant_Activity_Date__c);
                                }
                            } else if (fld == 'Region_API_Code__c') {
                                acctMap.put(accountFields.get(fld), acctMap.get(fld));
                                SAPRelatedFieldChanged.put(acctMap.Id, True);
                            } else {
                                /*System.debug('acctMap.Segment__c: ' + acctMap.Segment__c);
                                System.debug('oldAcc.Segment__c: ' + oldAcc.Segment__c);
                                System.debug('Updated_Segment__c: ' + acctMap.Updated_Segment__c);
                                if (fld == 'Subsegment__c' && acctMap.Segment__c != oldAcc.Segment__c) {
                                    acctMap.put(accountFields.get(fld), acctMap.get(fld));
                                    acctMap.put(fld, oldAcc.get(fld)); 
                                }*/
                                //Put value on the update request field and return the prior value of the field
                                acctMap.put(accountFields.get(fld), acctMap.get(fld));
                                acctMap.put(fld, oldAcc.get(fld));
                                SAPRelatedFieldChanged.put(acctMap.Id, True);
                                
                                if (fld == 'Bill_To_Payer_Account__c' && acctMap.get(accountFields.get(fld)) == Null) {
                                    acctMap.put('Updated_Related_Bill_to_Ingr_Acct_Emp__c', true);
                                }
                                
                                if (fld == 'Related_Payer_Account__c' && acctMap.get(accountFields.get(fld)) == Null) {
                                    acctMap.put('Updated_Related_Payer_Ingr_Acct_Empty__c', true);
                                }

                                if (fld == 'Bill_To_Payer_Account__c' && acctMap.get(accountFields.get(fld)) != Null) {
                                    acctMap.put('Updated_Related_Payer_Account__c', acctMap.get(accountFields.get(fld)));
                                }
                                
                            }
                            isChange = true;
                        }
                    }
                }
                
                if (!addressFields.isEmpty()) {
                //Loop for the changes in AddressFieldMap ~ Address fields should be validated before and cannot be null before any changes
                    for(String fld : addressFields.keySet()){
                        
                        if(oldAcc.get(fld)!= null && acctMap.get(fld) != oldAcc.get(fld) && acctMap.get(addressFields.get(fld)) == null){
                            //Put value on the update request field and return the prior value of the field
                            acctMap.put(addressFields.get(fld), acctMap.get(fld));
                            acctMap.put(fld, oldAcc.get(fld));
                            SAPRelatedFieldChanged.put(acctMap.Id, True);
                            
                            isChange = true;
                            
                        }
                    
                    }
                }
                
                if(isChange){
                    
                    if(epiUpdated){
                        acctMap.EPI_Field_Updated__c = true;
                    }
                    
                    //if any changes were made change record type from "Customer" to "Customer Validation" or "Address Administrative" to "Address Administrative Validation"
                    if(acctMap.RecordTypeId == SM_Constants.recordTypeIdCustomer){
                        //change record type to end customer validation
                        acctMap.RecordTypeId = SM_Constants.recordTypeIdEndCustomerValidation;
                        acctMap.Previous_Record_Type__c = String.valueOf(SM_Constants.recordTypeIdCustomer).substring(0, 15);
                    } else if (acctMap.RecordTypeId == SM_Constants.recordTypeIdAdministrativeAddress) {
                        acctMap.RecordTypeId = SM_Constants.recordTypeIdAdministrativeAddressValidation;
                    }
                } 
            }
        } catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
    
    }
    
     /**
    * @author        Kimiko Roberto
    * @date          04.05.2017           
    * @description   Method responsible for creating Integration Logs
    * @revision(s)   11.01.2018 - Alvin Lomod KASM-604
    */
    public static void createIntegLogs(Set<Account> newList, Map<Id, Account> oldRecordMap, Boolean sapFieldUpdated, Boolean epiFieldUpdated) {
        CustomLogging.push('createIntegLogs', 'SM_AccountUtil');
        try{
            Id recordTypeIdJDECompany = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.JDECompany).getRecordTypeId();
            List<Integration_Log__c> integLogsToInsertList = new List<Integration_Log__c>();
            
            //EPI Account RecordTypes KASM-604      
            Id recordTypeIdProspect = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.Prospect).getRecordTypeId();
            Id recordTypeIdProspectValid = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.ProspectValid).getRecordTypeId(); 
            Id recordTypeIdCustomer = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.Customer).getRecordTypeId(); 
            Id recordTypeIdCustomerValidation = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.EndCustomerValidation).getRecordTypeId(); 
            Id recordTypeIdAdminAddress = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.AdministrativeAddress).getRecordTypeId();
            Id recordTypeIdAdminAddressValidation = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.EndAdministrativeAddressValidation).getRecordTypeId();
            Id recordTypeIdPromotionRequested = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.PromotionRequested).getRecordTypeId();
            Id recordTypeIdAdminAddressValid = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.AdministrativeAddressValid).getRecordTypeId();
            
            Set<Id> recordTypesSet = new Set<Id>();
            recordTypesSet.add(recordTypeIdProspect);
            recordTypesSet.add(recordTypeIdProspectValid);
            recordTypesSet.add(recordTypeIdCustomer);
            recordTypesSet.add(recordTypeIdAdminAddress);
            recordTypesSet.add(recordTypeIdAdminAddressValid);
            
            User userRec = UserDAO.userInformation(); 
            Map<String, Boolean> accountDigital = UserDAO.digitalIntegrationInformation('Account');
            //Checker if an Integration Log for SAP is already created
            Boolean SAPiLogCreated = false;
            //if(AccountTriggerHandlerHelper.integLogFirstTime == true) {
            for(Account a: newList) { 
                SAPiLogCreated = false;
                if(oldRecordMap.isEmpty()) {
                    if(a.RecordTypeId != recordTypeIdJDECompany && a.Main_Address_Validation_Timestamp__c != Null && userRec.Profile.Name != 'JDE-Integration-Digital'){
                        integLogsToInsertList.add(SM_AccountUtil.createIlog(a, INT_Constants.ACCOUNT));
                        SAPiLogCreated = true;
                    }
                } else {
                    Account oldAcc = oldRecordMap.get(a.Id);
                    Set<String> changedSAPFieldSet  = new Set<String>();
                    if (sapFieldUpdated) {
                        changedSAPFieldSet.add('SAP Field Updated');
                    }
                    
                    if(!SAPRelatedFieldChanged.isEmpty()){
                        if(SAPRelatedFieldChanged.containsKey(a.Id)){
                            if(SAPRelatedFieldChanged.get(a.Id)){
                                changedSAPFieldSet.add('SAP Changed');
                            }
                        }
                    }
                    if((a.SAP_Customer_ID__c != oldAcc.SAP_Customer_ID__c || a.Main_Address_Validation_Pending__c != oldAcc.Main_Address_Validation_Pending__c || a.Creditworthiness_Flag__c != oldAcc.Creditworthiness_Flag__c || changedSAPFieldSet.size() > 0) && a.SAP_Customer_ID__c != Null && userRec.Profile.Name != SM_Constants.JDESAP &&  (oldAcc.RecordTypeId != recordTypeIdAdminAddressValidation && oldAcc.RecordTypeId != recordTypeIdPromotionRequested)) {   
                        integLogsToInsertList.add(SM_AccountUtil.createIlog(a, INT_Constants.ACCOUNT));
                        SAPiLogCreated = true;
                    }
                    
                }
                
                //New Integration Log for EPI ~ KASM-604
                //Only create an Integration Log for EPI if the one for SAP is not created.
                if(recordTypesSet.contains(a.RecordTypeId) && !SAPiLogCreated && a.Batch_Import_Flag__c == false && accountDigital.get(a.Sales_Organization__c)){              
                    if(oldRecordMap.isEmpty()){
                        integLogsToInsertList.add(SM_AccountUtil.createIlog(a, 'Account Digital'));
                    } else {
                        Account oldAcc = (Account)oldRecordMap.get(a.Id);
                        set<String> changedEPIFieldSet  = new Set<String>(); 
                        if (epiFieldUpdated){
                            changedEPIFieldSet.add('EPI Field Updated');
                        }
                        
                        if(a.Main_Address_Validation_Pending__c == false && a.Main_Address_Validation_Timestamp__c != null && oldAcc.Archiving_Flag__c == false && (oldAcc.recordTypeId != recordTypeIdCustomerValidation && oldAcc.recordTypeId != recordTypeIdAdminAddressValidation && oldAcc.RecordTypeId != recordTypeIdPromotionRequested)){
                            //Create iLog if one of the fields was changed
                            if(changedEPIFieldSet.size() > 0){
                                integLogsToInsertList.add(SM_AccountUtil.createIlog(a, 'Account Digital'));
                            }                         
                        }
                    }
                }
            }  
            //}
            
            if(integLogsToInsertList != null && !integLogsToInsertList.isEmpty()){
                //Not needed to add accessibility checker, all profile should be able to create this record with or without access. This is for integration. Not for user interaction
                IntegrationLogTriggerHandler.isAccountIlog = true;
                AccountTriggerHandlerHelper.integLogFirstTime = false;
                insert integLogsToInsertList;
            }
            
        } catch(Exception ex){     
            CustomLogging.debugException(ex);
            CustomLogging.pop();      
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
    }
 
    
    /**
    * @author        Alvin Lomod
    * @date          29.05.2018           
    * @description   Method responsible for creating Integration Logs after SAP response for EPI
    * @revision(s)   KASM-1766
    */
    
    public static void createIntegLogsAfterSAP(Set<Account> newAccountList, Map<Id,Account> oldAccountMap, boolean createEpiILOG) {
        CustomLogging.push('createIntegLogsAfterSAP', 'SM_AccountUtil');
        try{
            List<Integration_Log__c> integLogsToInsertList = new List<Integration_Log__c>();
            List<Account> updateSubsegment = new List<Account>();
            Id recordTypeIdCustomerValidation = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.EndCustomerValidation).getRecordTypeId();
            Id recordTypeIdAdminAddressValidation = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.EndAdministrativeAddressValidation).getRecordTypeId();
            Id recordTypeIdPromotionRequested = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.PromotionRequested).getRecordTypeId();
            Id recordTypeIdProspectValid = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.ProspectValid).getRecordTypeId();
            Map<String, Boolean> accountDigital = UserDAO.digitalIntegrationInformation('Account');
            
            for(Account a : newAccountList){
                Account oldAcc = oldAccountMap.get(a.Id);
                //When SAP response, SAP PO Updated is changed to true then a workflow reverts it back to false
                //if(a.SAP_PO_Updated__c == true && oldAcc.SAP_PO_Updated__c == false && a.EPI_Field_Updated__c && (a.RecordTypeId == recordTypeIdCustomerValidation || a.RecordTypeId == recordTypeIdAdminAddressValidation || a.RecordTypeId == recordTypeIdPromotionRequested)){
                if(createEpiILOG == true && accountDigital.get(a.Sales_Organization__c) && a.Batch_Import_Flag__c == false){
                    integLogsToInsertList.add(SM_AccountUtil.createIlog(a, 'Account Digital'));
                }
                
                //Create Account Hierarchy iLog after promotion to SAP if needed
                if(a.SAP_PO_Updated__c == true && oldAcc.SAP_PO_Updated__c == false && a.SAP_Customer_Id__c != null && oldAcc.SAP_Customer_ID__c == null && oldAcc.RecordTypeId == recordTypeIdPromotionRequested && a.Parent_Valid_To__c == null && a.Parent_Valid_From__c == null && a.Parent_Change_Indicator__c == null){
                    //integLogsToInsertList.add(SM_AccountUtil.createIlog(a, 'Account Hierarchy'));
                }
                //Moving values of subsegment if it is updated 
                //if(a.SAP_PO_Updated__c == true && oldAcc.SAP_PO_Updated__c == false && (a.RecordTypeId == recordTypeIdCustomerValidation || a.RecordTypeId == recordTypeIdAdminAddressValidation) && a.Updated_Sub_Segment__c != null){ 
                //will remove this since it is already covered in checkSubSegmentChangesonCustomer method on AccountTriggerHandler
                
                //if(createEpiILOG == true && a.Updated_Sub_Segment__c != null){
                //    Account accsubsegupdate = new Account();
                //    accsubsegupdate.Id = a.Id;
                //    accsubsegupdate.Subsegment__c = a.Updated_Sub_Segment__c;
                //    if (accsubsegupdate.Subsegment__c != null){
                //        accsubsegupdate.Updated_Sub_Segment__c = null;
                //    }
                //    updateSubsegment.add(accsubsegupdate);
                //}
                
            }//End of Account Loop
            
            if (!updateSubsegment.isEmpty()){
                update updateSubsegment;
            }
            
            if(integLogsToInsertList != null && !integLogsToInsertList.isEmpty()){
                //Not needed, all profile should be able to create this record with or without access. This is for integration. Not for user interaction
                insert integLogsToInsertList;
                AccountTriggerHandlerHelper.integLogFirstTime = false;
            }
        } catch(Exception ex) {     
            CustomLogging.debugException(ex);
            CustomLogging.pop();      
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        
    }

    
    public static void assignmentOfTerritory(List<Account> accountToReassignTerritory, Set<String> country){
        CustomLogging.push('assignmentOfTerritory', 'SM_AccountUtil'); 
        try{
            
            if(!accountToReassignTerritory.isEmpty()){
                List<Territory_Rule__c> trList = [SELECT Id, Segment__c, Territory_Model__c, Postal_Code_From__c, Postal_Code_To__c, Account_Lifecycle__c, 
                                                         Assigned_Owner__c, Assigned_Territory__c,
                                                         Assigned_Territory__r.Commercial_Territory_Owner__c, Territory_Model__r.Country__c,
                                                         Assigned_Territory__r.Sales_Inside_1__c, Assigned_Territory__r.Sales_Inside_2__c,
                                                         Assigned_Territory__r.Sales_Outside_1__c, Assigned_Territory__r.Sales_Outside_2__c,
                                                         Assigned_Territory__r.Customer_Relations_1__c, Assigned_Territory__r.Customer_Relations_2__c
                                                 FROM Territory_Rule__c 
                                                 WHERE Territory_Model__r.Country__c in: country
                                                 AND Territory_Model__r.Active__c = TRUE];
                
                //to avoid moving forward if there are no territory rules queried
                if(trList.size() > 0){
                    
                    String regex = '[a-zA-Z]{1,}|\\-';
                    String postalCode;
                    Decimal postalCodeNumber;
                    
                        Set<String> SegmentValues = new Set<String>();
                
                        for(Territory_Rule__c tr : trList){
                            
                            if(tr.Segment__c != null){
                                SegmentValues = new Set<String>(tr.Segment__c.split(';'));
                            }   
                            
                            for(Account acc : accountToReassignTerritory){
                                    //Remove all letters in postal code/box and industry code
                                    postalCode = acc.Main_Postal_Code__c;
                                    
                                    if(postalCode != null){
                                        postalCodeNumber = decimal.valueOf(postalCode.replaceAll(regex, '').replaceAll( '\\s+', ''));
                                    }else{
                                        postalCodeNumber = null;
                                    }
                                    if(tr.Territory_Model__r.Country__c == acc.Main_Country__c && SegmentValues.contains(acc.Segment__c) && (acc.Account_Lifecycle__c == null || tr.Account_Lifecycle__c == acc.Account_Lifecycle__c) &&
                                    (postalCodeNumber == null || (decimal.valueof(tr.Postal_Code_From__c) <= postalCodeNumber && postalCodeNumber <= decimal.valueof(tr.Postal_Code_To__c)))){
                                            updateAccountTerritory(acc, tr);
                                           
                                    }
                            }
                            
                            SegmentValues.clear();
                            
                        }
                    
                }
            
            } 
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        } 
    } 

    public static void updateAccountTerritory(Account acc, Territory_Rule__c tr) {
        acc.Territory__c = tr.Assigned_Territory__c;
        acc.Applied_Territory_Rule__c = tr.Id;
        acc.OwnerId = tr.Assigned_Territory__r.Commercial_Territory_Owner__c;
        acc.Sales_Inside_1__c = tr.Assigned_Territory__r.Sales_Inside_1__c;
        acc.Sales_Inside_2__c = tr.Assigned_Territory__r.Sales_Inside_2__c;
        acc.Sales_Outside_1__c = tr.Assigned_Territory__r.Sales_Outside_1__c;
        acc.Sales_Outside_2__c = tr.Assigned_Territory__r.Sales_Outside_2__c;
        acc.Customer_Relations_1__c = tr.Assigned_Territory__r.Customer_Relations_1__c;
        acc.Customer_Relations_2__c = tr.Assigned_Territory__r.Customer_Relations_2__c;
    }

    
    public static List<Account> stampHasChildAccount (List<Account> listAccount) {
        CustomLogging.push('stampHasChildAccount', 'SM_AccountUtil');
        try{
            List<Account> childAccount = new List<Account>();
            Set<Id> accountBonsaiId = new Set<Id>();
            Map<Id,Account> parentChildAccountBonsai = new Map<Id,Account>();
            //filter child account
            childAccount = [Select Id, APTS_BizIsland_Bonsai_Account__c, ParentId FROM Account WHERE ParentId IN :listAccount and APTS_BizIsland_Bonsai_Account__c = true];
            for (Account a : childAccount) {
                accountBonsaiId.add(a.ParentId);
            }
            
            if (!accountBonsaiId.isEmpty()) {
                for (Account acct : listAccount) {
                    if (accountBonsaiId.contains(acct.Id)) {
                        acct.APTS_Has_Child_Accounts__c = true;
                    }
                }
            }
            
            return listAccount; 
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
            return null;
        }
    }
    
    public static void insertUpdateAccountLocation(Set<Account> listAccount,  Map<Id,Account> oldAccountMap) {
        CustomLogging.push('insertUpdateAccountLocation', 'SM_AccountUtil'); 
        try{
            List<Apttus_Config2__AccountLocation__c> acctLocList = new List<Apttus_Config2__AccountLocation__c>();
            Set<Account> accountWithAcctLoc = new Set<Account>();
            Set<Id> acctlocId = new Set<Id>();
            Id recordTypeIdALRO =  Schema.SObjectType.Apttus_Config2__AccountLocation__c.getRecordTypeInfosByName().get(SM_Constants.AccountLocationRO).getRecordTypeId();
            Id recordTypeIdCustomer =  Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.Customer).getRecordTypeId();
            Id recordTypeIdProspectValid = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.ProspectValid).getRecordTypeId();
            Id recordTypeIdAdministrativeAddressValid = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.AdministrativeAddressValid).getRecordTypeId();
            Map<String, String> customerCalendarKeyPerSalesOrg = new Map<String, String>();
            customerCalendarKeyPerSalesOrg.put('SAP_0333', 'SAP_BE');
            customerCalendarKeyPerSalesOrg.put('SAP_0975', 'SAP_DK');
            customerCalendarKeyPerSalesOrg.put('SAP_0976', 'SAP_SE');
            customerCalendarKeyPerSalesOrg.put('SAP_6864', 'SAP_NO');
            customerCalendarKeyPerSalesOrg.put('SAP_0080', 'SAP_ES');
            customerCalendarKeyPerSalesOrg.put('SAP_0111', 'SAP_NL');
            customerCalendarKeyPerSalesOrg.put('SAP_6712', 'SAP_01');
            customerCalendarKeyPerSalesOrg.put('SAP_6750', 'SAP_GB');
            User u = UserDAO.userInformation();
            List<Apttus_Config2__AccountLocation__c>acctLocLists = new List<Apttus_Config2__AccountLocation__c>();
            acctLocLists = [Select Id, Apttus_Config2__AccountId__c, Copy_of_Parent_Account__c, Archiving_Flag__c, Delivery_Block_Reason__c
                            FROM Apttus_Config2__AccountLocation__c 
                            WHERE Apttus_Config2__AccountId__c IN :listAccount];
            for (Account acct : listAccount) {
                if (!acct.First_Account_Location_created__c && u.Profile.Name != SM_Constants.JDEDigital && (acct.RecordTypeId == recordTypeIdCustomer || acct.RecordTypeId == recordTypeIdProspectValid || acct.RecordTypeId == recordTypeIdAdministrativeAddressValid)) {
                    Apttus_Config2__AccountLocation__c acctLoc = new Apttus_Config2__AccountLocation__c();
                    acctLoc.Apttus_Config2__AccountId__c = acct.Id;
                    acctLoc.Account_Location_Status__c = acct.Account_Status__c;
                    acctLoc.Apttus_Config2__City__c = acct.Main_City__c;
                    acctLoc.Apttus_Config2__Country__c = acct.Main_Country__c;
                    acctLoc.Apttus_Config2__IsDefault__c = true;
                    acctLoc.Apttus_Config2__PostalCode__c = acct.Main_Postal_Code__c;
                    acctLoc.Apttus_Config2__State__c = acct.Main_State__c;
                    acctLoc.Apttus_Config2__Street__c = acct.Main_Street__c;
                    acctLoc.Apttus_Config2__Type__c = 'Ship-To';
                    acctLoc.Archiving_Flag__c = acct.Archiving_Flag__c;
                    acctLoc.Copy_of_Parent_Account__c = true;
                    acctLoc.Customer_calendar_key__c = customerCalendarKeyPerSalesOrg.get(acct.Sales_Organization__c);
                    acctLoc.Duplicate_Reason__c = acct.Duplicate_Reason__c;
                    acctLoc.Duplicate_Validation__c = acct.Duplicate_Validation__c;
                    acctLoc.Mini_Account_Group__c = acct.Mini_Account_Group__c;
                    acctLoc.Mini_Company_Code__c = acct.Mini_Company_Code__c;
                    acctloc.Mini_Delivery_Control__c = acct.Mini_Delivery_Control__c;
                    acctLoc.Mini_Delivery_Priority__c = acct.Mini_Delivery_Priority__c;
                    acctLoc.Mini_Distribution_Channel__c = acct.Distribution_Channel__c;
                    acctLoc.Mini_Division__c = acct.Division__c;
                    acctLoc.Mini_Incoterms_Part_1__c = acct.Mini_Incoterms_Part_1__c;
                    acctLoc.Mini_Incoterms_Part_2__c = acct.Mini_Incoterms_Part_2__c;
                    acctLoc.Mini_Language__c = acct.Language__c;
                    acctLoc.Mini_Max_part_deliveries__c = acct.Mini_Max_part_deliveries__c; 
                    acctLoc.Mini_Sales_Organization__c = acct.Sales_Organization__c;
                    acctLoc.Mini_Shipping_Conditions__c = acct.Mini_Shipping_Conditions__c;
                    acctLoc.Mini_Transportation_zone__c = acct.Transportation_zone__c;
                    acctLoc.Name = acct.Name;
                    acctLoc.Second_Account_Name__c = acct.Second_Account_Name__c;
                    acctLoc.Third_Account_Name__c = acct.Third_Account_Name__c;
                    acctLoc.Fourth_Account_Name__c = acct.Fourth_Account_Name__c;
                    acctLoc.RecordTypeId = recordTypeIdALRO;
                    acctLoc.Region__c = acct.Region__c;
                    acctLoc.SAP_Customer_ID__c = acct.SAP_Customer_ID__c;
                    acctLoc.Shipping_Address_Validation_Timestamp__c = acct.Main_Address_Validation_Timestamp__c;
                    acctLoc.Shipping_Address_Validation_Pending__c = acct.Main_Address_Validation_Pending__c;
                    acctLoc.Shipping_Address_Validation_Code__c = acct.Main_Address_Validation_Code__c;
                    acctLoc.Shipping_Address_Validation_Error__c = acct.Main_Address_Validation_Error__c;
                    acctLoc.Shipping_Country_ISO__c = acct.Main_Country_ISO__c;
                    acctLoc.Shipping_House_Number__c = acct.Main_House_Number__c;
                    acctLoc.Shipping_Street_Only__c = acct.Main_Street_Only__c;
                    acctLoc.Unloading_point__c = '00';
                    acctLoc.House_Number_Supplement__c = acct.House_Number_Supplement__c;
                    acctLoc.Delivery_Block_Reason__c = acct.Delivery_Block_Reason__c;
                    acctLocList.add(acctLoc);
                    accountWithAcctLoc.add(acct);
                } else {
                    if (!acctLocLists.isEmpty()) {
                        Map<Id, Account> mapALtoAccount = new Map<Id, Account>();
                        for (Apttus_Config2__AccountLocation__c accLoc : acctLocLists) {
                            for (Account a : listAccount) {
                                if (accLoc.Apttus_Config2__AccountId__c == a.Id) {
                                    mapALtoAccount.put(accLoc.Id, a);
                                } 
                            }
                        }
                        if (!mapALtoAccount.isEmpty()) {
                            Apttus_Config2__AccountLocation__c accL;
                            for (Apttus_Config2__AccountLocation__c accLoc : acctLocLists) {
                                Account accVal = mapALtoAccount.get(accLoc.Id);
                                if (accVal.First_Account_Location_created__c) {
                                    if (u.Profile.Name != SM_Constants.JDEDigital) {
                                        if (accLoc.Copy_of_Parent_Account__c) {
                                            accL = accLoc;
                                            accL.Account_Location_Status__c = accVal.Account_Status__c;
                                            accL.Apttus_Config2__City__c = accVal.Main_City__c;
                                            accL.Apttus_Config2__Country__c = accVal.Main_Country__c;
                                            accL.Apttus_Config2__PostalCode__c = accVal.Main_Postal_Code__c;
                                            accL.Apttus_Config2__State__c = accVal.Main_State__c;
                                            accL.Apttus_Config2__Street__c = accVal.Main_Street__c;
                                            accL.Archiving_Flag__c = accVal.Archiving_Flag__c;
                                            accL.Customer_calendar_key__c = customerCalendarKeyPerSalesOrg.get(accVal.Sales_Organization__c);
                                            accL.Duplicate_Reason__c = accVal.Duplicate_Reason__c;
                                            accL.Duplicate_Validation__c = accVal.Duplicate_Validation__c;
                                            accL.Mini_Account_Group__c = accVal.Mini_Account_Group__c;
                                            accL.Mini_Company_Code__c = accVal.Mini_Company_Code__c;
                                            accL.Mini_Delivery_Control__c = accVal.Mini_Delivery_Control__c;
                                            accL.Mini_Delivery_Priority__c = accVal.Mini_Delivery_Priority__c;
                                            accL.Mini_Distribution_Channel__c = accVal.Distribution_Channel__c;
                                            accL.Mini_Division__c = accVal.Division__c;
                                            accL.Mini_Incoterms_Part_1__c = accVal.Mini_Incoterms_Part_1__c;
                                            accL.Mini_Incoterms_Part_2__c = accVal.Mini_Incoterms_Part_2__c;
                                            accL.Mini_Language__c = accVal.Language__c;
                                            accL.Mini_Max_part_deliveries__c = accVal.Mini_Max_part_deliveries__c; 
                                            accL.Mini_Sales_Organization__c = accVal.Sales_Organization__c;
                                            accL.Mini_Shipping_Conditions__c = accVal.Mini_Shipping_Conditions__c;
                                            accL.Mini_Transportation_zone__c = accVal.Transportation_zone__c;
                                            accL.Name = accVal.Name;
                                            accL.Second_Account_Name__c = accVal.Second_Account_Name__c;
                                            accL.Third_Account_Name__c = accVal.Third_Account_Name__c; 
                                            accL.Fourth_Account_Name__c = accVal.Fourth_Account_Name__c; 
                                            accL.Region__c = accVal.Region__c;
                                            accL.SAP_Customer_ID__c = accVal.SAP_Customer_ID__c;
                                            accL.Shipping_Address_Validation_Timestamp__c = accVal.Main_Address_Validation_Timestamp__c;
                                            accL.Shipping_Address_Validation_Pending__c = accVal.Main_Address_Validation_Pending__c;
                                            accL.Shipping_Address_Validation_Code__c = accVal.Main_Address_Validation_Code__c;
                                            accL.Shipping_Address_Validation_Error__c = accVal.Main_Address_Validation_Error__c;
                                            accL.Shipping_Country_ISO__c = accVal.Main_Country_ISO__c;
                                            accL.Shipping_House_Number__c = accVal.Main_House_Number__c;
                                            accL.Shipping_Street_Only__c = accVal.Main_Street_Only__c;
                                            accL.Unloading_point__c = '00';
                                            accL.House_Number_Supplement__c = accVal.House_Number_Supplement__c;
                                            accL.Delivery_Block_Reason__c = accVal.Delivery_Block_Reason__c;
                                        } else if (!accLoc.Copy_of_Parent_Account__c) {
                                            if (accVal.Archiving_Flag__c != accLoc.Archiving_Flag__c || accVal.Delivery_Block_Reason__c != accLoc.Delivery_Block_Reason__c ) {
                                                accL = accLoc;
                                                accL.Archiving_Flag__c = accVal.Archiving_Flag__c;
                                                accL.Account_Location_Status__c = accVal.Account_Status__c;
                                                accL.Delivery_Block_Reason__c = accVal.Delivery_Block_Reason__c;
                                            }
                                        }
                                    } else {
                                        accL = accLoc;
                                        accL.Mini_Company_Code__c = accVal.Mini_Company_Code__c;
                                        accL.Mini_Delivery_Control__c = accVal.Mini_Delivery_Control__c;
                                        accL.Mini_Delivery_Priority__c = accVal.Mini_Delivery_Priority__c;
                                        accL.Mini_Distribution_Channel__c = accVal.Distribution_Channel__c;
                                        accL.Mini_Division__c = accVal.Division__c;
                                        accL.Mini_Language__c = accVal.Language__c;
                                        accL.Mini_Max_part_deliveries__c = accVal.Mini_Max_part_deliveries__c;
                                        accL.Mini_Shipping_Conditions__c = accVal.Mini_Shipping_Conditions__c;
                                        accL.Mini_Transportation_zone__c = accVal.Transportation_zone__c;
                                        accL.Region__c = accVal.Region__c;
                                        accL.Account_Location_Status__c = accVal.Account_Status__c;
                                        accL.Duplicate_Reason__c = accVal.Duplicate_Reason__c;
                                        accL.Duplicate_Validation__c = accVal.Duplicate_Validation__c;
                                        accL.Delivery_Block_Reason__c = accVal.Delivery_Block_Reason__c;
                                        accL.SAP_Customer_ID__c = accVal.SAP_Customer_ID__c;
                                    } 
                                    if (!acctlocId.contains(accL.Id)){
                                        acctLocList.add(accL);
                                        acctlocId.add(accL.Id);
                                    }
                                }
                            }
                        }
                    }
                }
            }

            if (!acctLocList.isEmpty()) {
                upsert acctLocList;
            }
           
            if (!accountWithAcctLoc.isEmpty()) {
                List<Account> updateAcc = new List<Account>();
                for (Account acc : accountWithAcctLoc) {
                    Account copyAccToupdate = new Account();
                    copyAccToupdate.Id = acc.Id;
                    copyAccToupdate.First_Account_Location_created__c = true;
                    updateAcc.add(copyAccToupdate);
                }
                
                if (!updateAcc.isEmpty()) {
                    update updateAcc;
                }
            }
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        
    }
    
    public static List<Account> changeRecordTypeToValid(List<Account> listAccount) {
        CustomLogging.push('changeRecordTypeToValid', 'SM_AccountUtil');
        try{
            for (Account acc : listAccount) {
                if (acc.RecordTypeId == SM_Constants.recordTypeIdProspectInvalid || acc.RecordTypeId == SM_Constants.recordTypeIdProspect) {
                    acc.RecordTypeId = SM_Constants.recordTypeIdProspectValid;
                } 
                else {
                    acc.RecordTypeId = SM_Constants.recordTypeIdAdministrativeAddressValid;
                }
                
            }
            return listAccount;
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
            return null;
        }
    }
    
    public static List<Account> changeMethodTermStatus(List<Account> listAccount) {
        CustomLogging.push('changeMethodTermStatus', 'SM_AccountUtil');
        try{
            for (Account acc : listAccount) {
                if (acc.Approval_Status__c == 'Approval Validated') {
                    acc.Approval_Status__c = 'SAP Integration Successful';
                    acc.RecordTypeId = SM_Constants.recordTypeIdCustomer;
                }
            }
            return listAccount;
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
            return null;
        }
    }
    
    public static List<Account> userAssignTerritory(List<Account> listAccount) {
        CustomLogging.push('userAssignTerritory', 'SM_AccountUtil');
        try{
            Set<Id> territoryID = new Set<Id>();
            for (Account acc : listAccount) {
                territoryID.add(acc.Territory__c);
            }
            
            Map<Id, Territory__c> acctTerritory = new Map<Id, Territory__c>();
            List<Territory__c> territory = new List<Territory__c>();
            territory = [Select Id, Sales_Inside_1__c, Sales_Inside_2__c, Sales_Outside_1__c, Sales_Outside_2__c,
                                Customer_Relations_1__c, Customer_Relations_2__c, Commercial_Territory_Owner__c
                         FROM Territory__c
                         WHERE Id IN :territoryID];
            for (Account acc : listAccount) {
                for (Territory__c t : territory) {
                    if (acc.Territory__c == t.Id) {
                        acctTerritory.put(acc.Id, t);
                    }
                }
            }
            for (Account acc : listAccount) {
                acc.OwnerId = acctTerritory.get(acc.Id).Commercial_Territory_Owner__c;
                acc.Sales_Inside_1__c = acctTerritory.get(acc.Id).Sales_Inside_1__c;
                acc.Sales_Inside_2__c = acctTerritory.get(acc.Id).Sales_Inside_2__c;
                acc.Sales_Outside_1__c = acctTerritory.get(acc.Id).Sales_Outside_1__c;
                acc.Sales_Outside_2__c = acctTerritory.get(acc.Id).Sales_Outside_2__c;
                acc.Customer_Relations_1__c = acctTerritory.get(acc.Id).Customer_Relations_1__c;
                acc.Customer_Relations_2__c = acctTerritory.get(acc.Id).Customer_Relations_2__c;
                if (acc.Applied_Territory_Rule__c != Null) {
                    acc.Applied_Territory_Rule__c = Null;
                }
                
            }
 
            return listAccount;
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
            return null;
        }
    }
    
    public static void addressValidationApproved(Set<Account> listAccount, Map<Id,Account> oldAccountMap){
        CustomLogging.push('addressValidationApproved', 'SM_AccountUtil');
        try{
            Map <String, String> countrycode = SM_GetMetadata.getcountrycodemdtrecords();
            for (Account acct : listAccount) {
                if (!countrycode.isEmpty()){
                    acct.Main_Country_ISO__c = countrycode.get(acct.Main_Country__c);
                }
                if (acct.RecordTypeId == SM_Constants.recordTypeIdCustomer){
                    Account oldAcc = oldAccountMap.get(acct.Id);
                    acct.Updated_Main_House_Number__c = acct.Main_House_Number__c;
                    acct.Updated_House_Number_Supplement__c = acct.House_Number_Supplement__c;
                    acct.Updated_Main_City__c = acct.Main_City__c;
                    acct.Updated_Main_Country__c = acct.Main_Country__c;
                    acct.Updated_Main_PostalCode__c = acct.Main_Postal_Code__c;
                    acct.Updated_Main_State__c = acct.Main_State__c;
                    acct.Updated_Main_Street_Only__c = acct.Main_Street_Only__c;
                    acct.Updated_Main_Country_ISO__c = acct.Main_Country_ISO__c;
                    acct.Main_Country__c = oldAcc.Main_Country__c;
                    acct.Main_Country_ISO__c = oldAcc.Main_Country_ISO__c;
                    acct.RecordTypeId = SM_Constants.recordTypeIdEndCustomerValidation;
                }
                SAPRelatedFieldChanged.put(acct.Id, True);
            }
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
    }
    
    /*public static void accountReactivation(Set<Account> listAccount){
        CustomLogging.push('accountReactivation', 'SM_AccountUtil');
        try{
            for (Account acct : listAccount) {
                acct.IsActive__c = true;
                acct.Archiving_Flag__c = false;
                acct.Last_Relevant_Activity_Date__c = Date.today();
            }
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
    }*/
    
    public static void accountLifecyclechange(Set<Account> listAccount){
        CustomLogging.push('accountLifecyclechange', 'SM_AccountUtil');
        try{
            for (Account acct : listAccount) {
                if (acct.RecordTypeId == SM_Constants.recordTypeIdProspectValid || acct.RecordTypeId == SM_Constants.recordTypeIdPromotionRequested || acct.RecordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.Prospect).getRecordTypeId()){
                    if (acct.IsActive__c == true || acct.Archiving_Flag__c == false){
                        acct.Account_Lifecycle__c = 'Prospect';
                    }
                }
                else if (acct.RecordTypeId == SM_Constants.recordTypeIdCustomer || acct.RecordTypeId == SM_Constants.recordTypeIdEndCustomerValidation){
                	if (acct.IsActive__c == true){
                        if (acct.Archiving_Flag__c == false) {
                            acct.Account_Lifecycle__c = 'Active Customer';
                        }
                        acct.Active_Customer_Since__c = date.today();
                    } else{
                        if(acct.Archiving_Flag__c == false){
                            acct.Account_Lifecycle__c = 'Inactive Customer';
                            acct.Delivery_Block_Reason__c = 'SAP_Z4';
                            acct.Inactive_Customer_Since__c = date.today();
                        }
                    }
                    
                }
                else if (acct.RecordTypeId == SM_Constants.recordTypeIdAdministrativeAddress || acct.RecordTypeId == SM_Constants.recordTypeIdAdministrativeAddressValid || acct.RecordTypeId == SM_Constants.recordTypeIdAdministrativeAddressValidation){
                    if (acct.IsActive__c == true || acct.Archiving_Flag__c == false){
                        acct.Account_Lifecycle__c = 'Administrative';
                    }
                    
                }
            }
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
    }

    public static void accountArchivingProcess(Set<Account> listAccount){
        CustomLogging.push('accountArchivingProcess', 'SM_AccountUtil');
        try{
            for(Account acct : listAccount){
                if(acct.Archiving_Flag__c == true){
                	acct.Account_Lifecycle__c = 'Archived';
                    acct.Last_Relevant_Activity_Date__c = date.today();
                    acct.Account_Status__c = 'Not Valid';
                } else{
                    if (acct.Deactivation_Reason__c == Null) {
                        acct.IsActive__c = true;
                    }
                    if (acct.IsActive__c == true) {
                         if (acct.RecordTypeId == SM_Constants.recordTypeIdCustomer || acct.RecordTypeId == SM_Constants.recordTypeIdEndCustomerValidation) {
                            acct.Account_Lifecycle__c = 'Active Customer';
                        } else if (acct.RecordTypeId == SM_Constants.recordTypeIdAdministrativeAddressValidation || acct.RecordTypeId == SM_Constants.recordTypeIdAdministrativeAddress || acct.RecordTypeId == SM_Constants.recordTypeIdAdministrativeAddressValid) {
                            acct.Account_Lifecycle__c = 'Administrative';
                        }
                    } else {
                        if (acct.RecordTypeId == SM_Constants.recordTypeIdCustomer || acct.RecordTypeId == SM_Constants.recordTypeIdEndCustomerValidation) {
                            acct.Account_Lifecycle__c = 'Inactive Customer';
                        } else if (acct.RecordTypeId == SM_Constants.recordTypeIdAdministrativeAddressValidation || acct.RecordTypeId == SM_Constants.recordTypeIdAdministrativeAddress || acct.RecordTypeId == SM_Constants.recordTypeIdAdministrativeAddressValid) {
                            acct.Account_Lifecycle__c = 'Administrative';
                        }
                    }
                    acct.Account_Status__c = 'Valid';
                    acct.Last_Relevant_Activity_Date__c = date.today();
                }
            }
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
    }
    
    public static void decisionMakingUnitUncheck(Set<Account> listAccount){
        CustomLogging.push('decisionMakingUnitUncheck', 'SM_AccountUtil');
        try{
            for(Account acc : listAccount){
                acc.DMU__c = false;
                acc.Key_Account__c = false;
            }
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
    }
    
    public static void populateBackorFrontendcustomer(Set<Account> listAccount){
        CustomLogging.push('populateBackorFrontendcustomer', 'SM_AccountUtil');
        try{
            for(Account acc : listAccount){
                if (acc.Mini_Customer_Pricing_Procedure__c == 'SAP_A' || acc.Mini_Customer_Pricing_Procedure__c == 'SAP_M' || acc.Mini_Customer_Pricing_Procedure__c == 'SAP_X' || acc.Mini_Customer_Pricing_Procedure__c == 'SAP_Y'){
                    acc.Front_Back_end_customer__c = 'Back-End';
                }
                else if (acc.Mini_Customer_Pricing_Procedure__c == 'SAP_S'){
                    acc.Front_Back_end_customer__c = 'Front-End';
                }
            }
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
    }
    
    public static void accountNotValid(Set<Account> listAccount){
        CustomLogging.push('accountNotValid', 'SM_AccountUtil');
        try{
            for(Account acc : listAccount){
                if (acc.Main_Address_Validation_Pending__c == true || acc.Main_Address_Validation_Error__c != null){
                    acc.Address_Validation__c = 'Not Valid';
                }
            }
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
    }
    
    public static void accountValid(Set<Account> listAccount){
        CustomLogging.push('accountNotValid', 'SM_AccountUtil');
        try{
            for(Account acc : listAccount){
                acc.Address_Validation__c = 'Valid';
            }
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
    }
    
    public static void alignBillingAddressWithMainAddress(Set<Account> listAccount){
        CustomLogging.push('alignBillingAddressWithMainAddress', 'SM_AccountUtil');
        try{
            for(Account acc : listAccount){
                acc.BillingStreet = acc.Main_Street__c;
                acc.BillingCity = acc.Main_City__c;
                acc.BillingPostalCode = acc.Main_Postal_Code__c;
                acc.BillingCountry = acc.Main_Country__c;
                acc.BillingState = acc.Main_State__c;
                acc.WSONE_DATA__BillingHouseNumber__c = acc.Main_House_Number__c;
                acc.WSONE_DATA__BillingStreetOnly__c = acc.Main_Street_Only__c;
            }
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
    }
    
    public static void populateSicCodeandSIcDescription(Set<Account> listAccount, Set<Id> jdesicmappingset){
        CustomLogging.push('populateSicCodeandSIcDescription', 'SM_AccountUtil');
        try{
            Map<Id, JDE_SIC_Mapping__c> jdesicmap = new Map<Id, JDE_SIC_Mapping__c>();
            List <JDE_SIC_Mapping__c> jdesiclist = [Select Id, Sic_Code__c, SIC_Description__c from JDE_SIC_Mapping__c where ID IN :jdesicmappingset];
            for (JDE_SIC_Mapping__c jdesic : jdesiclist){
                jdesicmap.put(jdesic.ID, jdesic);
            }
            
            if (!jdesicmap.isEmpty()){
                for(Account acc : listAccount){
                    if (acc.Sic_Name__c != null){
                        acc.Sic = jdesicmap.get(acc.SIC_Name__c).Sic_Code__c;
    					acc.SicDesc = jdesicmap.get(acc.SIC_Name__c).SIC_Description__c;
                    }
                }
            }
                
            
            
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
    }
    
    public static void administrativeaddressNoAddressValidation(Set<Account> listAccount){
        CustomLogging.push('administrativeaddressNoAddressValidation', 'SM_AccountUtil');
        try{
            if (!listAccount.isEmpty()){
                for(Account acc : listAccount){
                    acc.RecordTypeId = SM_Constants.recordTypeIdAdministrativeAddressInvalid;
                }
            }
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
    }

    public static void updateUtlimateParentAccountNameSearch(List<Account> accountList) {
        CustomLogging.push('updateUtlimateParentAccountNameSearch', 'SM_AccountUtil');
        try {
            for (Account acct : accountList) {
                acct.Ultimate_Parent_Account_Name_Search__c = acct.Ultimate_Parent_Account__c;
            }
        } catch(exception e){ 
          CustomLogging.debugException(e); 
          CustomLogging.pop(); 
          System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        } 
    }

    public static void assignDefaultForwardingPartner(List<Account> listAccount){
        CustomLogging.push('assignDefaultForwardingPartner', 'SM_AccountUtil');
        try{
            Map<String, String> defaultLSP = UserDAO.logisticPartnerInformation();
            for(Account acc : listAccount){
                if (defaultLSP != Null){
                    acc.Forwarding_Partner_Number__c = defaultLSP.get(acc.Sales_Organization__c);
                }
            }
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
    }

    public static void assignOwnerForwardingPartner(List<Account> listAccount){
        CustomLogging.push('assignOwnerForwardingPartner', 'SM_AccountUtil');
        try{
            Set<Id> userIds = new Set<Id>();
            Map<Id, String> userForwardingMap = new Map<Id, String>();
            for (Account acct : listAccount) {
                userIds.add(acct.OwnerId);
            }
            List<User> listOfUsers = new List<User>();
            listOfUsers = [Select Id, Name, Forwarding_Partner_Number__c FROM User WHERE ID IN :userIds];
            for(User u : listOfUsers) {
                userForwardingMap.put(u.Id, u.Forwarding_Partner_Number__c);
            }

            for(Account acc : listAccount){
                if (userForwardingMap.get(acc.OwnerId) != Null) {
                    acc.Forwarding_Partner_Number__c = userForwardingMap.get(acc.OwnerId);
                } else {
                    acc.Forwarding_Partner_Number__c = null;
                }
            }
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
    }

    public static void checkForwardingPartner(List<Account> listAccount) {
        CustomLogging.push('checkForwardingPartner', 'SM_AccountUtil');
        try{
            for(Account acc : listAccount){
                acc.LSP_Forwarding_Partner__c = true;
            }
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
    }

    public static void streetValue(List<Account> listAccount) {
        CustomLogging.push('streetValue', 'SM_AccountUtil');
        try{
            for(Account acc : listAccount){
                if(acc.Main_Street_Only__c != Null) {
                    acc.Main_Street__c = acc.Main_Street_Only__c;
                }
                if(acc.Main_House_Number__c != Null) {
                    acc.Main_Street__c =+ acc.Main_Street__c + ' ' + acc.Main_House_Number__c;
                }
                if(acc.House_Number_Supplement__c != Null) {
                    acc.Main_Street__c =+ acc.Main_Street__c + ' ' + acc.House_Number_Supplement__c;
                }
            }
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
    }
    
    public static void changeDuplicateValidationifnotORC(List<Account> accountList) {
        CustomLogging.push('changeDuplicateValidationifnotORC', 'SM_AccountUtil');
        try {
            for (Account acct : accountList) {
				if (acct.Duplicate_Reason__c != 'Online Registered Customer'){
					acct.Duplicate_Validation__c = 'Duplicate Verified';
				} else {
					if (acct.Duplicate_Reason__c == 'Online Registered Customer'){
					acct.Duplicate_Validation__c = 'Duplicate Identified';
					}
				}
            }
        } catch(exception e){ 
          CustomLogging.debugException(e); 
          CustomLogging.pop(); 
          System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        } 
    }

    public static void changeAfterPromotion(List<Account> accountList) {
        CustomLogging.push('changeAfterPromotion', 'SM_AccountUtil');
        try {
            for (Account acct : accountList) {
                acct.Account_Type__c = 'Customer';
                acct.Account_Lifecycle__c = 'Active Customer';
                acct.Active_Customer_Since__c = Date.today();
                acct.Customer_Since__c = Date.today();
                acct.Prospect_promotion_status__c = 'Prospect promotion approved';
                acct.RecordTypeId = SM_Constants.recordTypeIdCustomer;
                acct.EPI_Field_Updated__c = false;
                acct.SAP_PO_Updated__c = false;
            }
        } catch(exception e){ 
          CustomLogging.debugException(e); 
          CustomLogging.pop(); 
          System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        } 
    }

    public static void changeAfterIntegration(List<Account> accountList) {
        CustomLogging.push('changeAfterIntegration', 'SM_AccountUtil');
        try {
            for (Account acct : accountList) {
                if (acct.RecordTypeId == SM_Constants.recordTypeIdEndCustomerValidation) {
                   acct.RecordTypeId = SM_Constants.recordTypeIdCustomer;
                } else if (acct.RecordTypeId == SM_Constants.recordTypeIdAdministrativeAddressValidation) {
                   acct.RecordTypeId = SM_Constants.recordTypeIdAdministrativeAddress;
                }
                acct.EPI_Field_Updated__c = false; 
                acct.SAP_PO_Updated__c = false;
            }
        } catch(exception e){ 
          CustomLogging.debugException(e); 
          CustomLogging.pop(); 
          System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        } 
    }

    public static void updateRelOpp(List<Account> accountList, Map<Id,Account> oldAccountMap) {
        CustomLogging.push('updateRelOpp', 'SM_AccountUtil');
        try {
            //get related opportunity
            List<Opportunity> oppList = new List<Opportunity>();
            List<Opportunity> updateOpp = new List<Opportunity>();
            oppList = [Select Id, OwnerId, Partner_Opportunity_Owner__c, StageName, AccountId, Sales_Organization__c 
                       FROM Opportunity 
                       WHERE AccountId IN :accountList AND RecordTypeId = :Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(SM_Constants.OppPrfPartnerRT).getRecordTypeId()
                       AND Partner_Opportunity_Owner__c = NULL];
            //get custom metadata
            Map<String, String> internalAssignedMap = SM_GetMetadata.getInternalAssigment();

            for (Opportunity opp : oppList) {
                Account oldAcc = oldAccountMap.get(opp.AccountId);
                opp.Partner_Opportunity_Owner__c = oldAcc.GTM_Ingredients__c;
                opp.StageName = 'No Bid';
                if(internalAssignedMap.get(opp.Sales_Organization__c) != NULL) {
                    opp.OwnerId = internalAssignedMap.get(opp.Sales_Organization__c);
                }
                opp.Reason_No_Bid__c = 'Switched partner';
                updateOpp.add(opp);
            }
            if(!updateOpp.isEmpty()) {
                update updateOpp;
            }
        } catch(exception e){ 
          CustomLogging.debugException(e); 
          CustomLogging.pop(); 
          System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
    }

    public static void stampmachineparktimeanduser(List<Account> accountList) {
        CustomLogging.push('stampmachineparktimeanduser', 'SM_AccountUtil');
        try {
            for (Account acct : accountList) {
               	acct.Timestamp_Machine_Park__c = System.now();
                acct.User_Machine_Park__c = u.Id;
            }
        } catch(exception e){ 
          CustomLogging.debugException(e); 
          CustomLogging.pop(); 
          System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        } 
    }

    public static void stampRelatedBilltoandPayer(List<Account> accountList) {
        CustomLogging.push('stampRelatedBilltoandPayer', 'SM_AccountUtil');
        try {
            for (Account acct : accountList) {
                acct.Related_Bill_to_Machines_Services__c = acct.Bill_To_Payer_Account__c;
                acct.Related_Payer_Account__c = acct.Bill_To_Payer_Account__c;
                acct.Related_Payer_Machines_Services__c = acct.Bill_To_Payer_Account__c;
            }
        } catch(exception e){ 
          CustomLogging.debugException(e); 
          CustomLogging.pop(); 
          System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        } 
    }

    public static void billBlockReasonRemove(List<Account> accountList) {
        CustomLogging.push('billBlockReasonRemove', 'SM_AccountUtil');
        try {
            for (Account acct : accountList) {
                acct.Bill_Block_Reason__c = null;
            }
        } catch(exception e){ 
          CustomLogging.debugException(e); 
          CustomLogging.pop(); 
          System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        } 
    }
    
    public static void prospectNoAddressValidation(Set<Account> listAccount){
        CustomLogging.push('prospectNoAddressValidation', 'SM_AccountUtil');
        try{
            if (!listAccount.isEmpty()){
                for(Account acc : listAccount){
                    acc.RecordTypeId = SM_Constants.recordTypeIdProspectInvalid;
                }
            }
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
    }
    
    // public static void stampUltimateParentId(List<Account> accountList) {
    //     CustomLogging.push('stampUltimateParentId', 'SM_AccountUtil');
    //     try {
    //         List <Account> parentId = [Select ID, ParentId, Parent.ParentId, Parent.Parent.ParentId, Parent.Parent.Parent.ParentId from Account where Id IN: accountList];
    //         List<Account> stampparentId = new List<Account>();
    //         for (Account acct : parentId) {
    //             Account accrec = new Account();
    //             accrec.Id = acct.Id;
    //             if (acct.Parent.Parent.Parent.ParentId != null) {
    //                 System.debug('IM HERE MOWFOW2');
    //                 accrec.Ultimate_Parent_Id_Stamped__c = acct.Parent.Parent.Parent.ParentId;
    //             }
    //             else if (acct.Parent.Parent.ParentId != null){
    //                 System.debug('IM HERE MOWFOW3');
    //                 accrec.Ultimate_Parent_Id_Stamped__c = acct.Parent.Parent.ParentId;
    //             }
    //             else if (acct.Parent.ParentId != null){
    //                 System.debug('IM HERE MOWFOW4');
    //                 accrec.Ultimate_Parent_Id_Stamped__c = acct.Parent.ParentId;
    //             }
    //             else if (acct.ParentId != null){
    //                 System.debug('IM HERE MOWFOW5');
    //                 accrec.Ultimate_Parent_Id_Stamped__c = acct.ParentId;
    //             }
    //             else {
    //                 System.debug('IM HERE MOWFOW6');
    //                 accrec.Ultimate_Parent_Id_Stamped__c = acct.Id;
    //             }
    //             stampparentId.add(accrec);
    //         }
    //         if (!stampparentId.isEmpty()){
    //             update stampparentId;
    //         }
    //     } catch(exception e){ 
    //       CustomLogging.debugException(e); 
    //       CustomLogging.pop(); 
    //       System.debug(e.getMessage() + '\n' + e.getStackTraceString());
    //     } 
    // }
}