//-------------------------------------------------------------------------------------------//
// Author       :   Catherine Aragon - Accenture
// Created Date :   February 28, 2017
// Usage        :   Update Request Field - This is used to updated the fields with 
//                  old values and new values
//                  Mini template - This is used to insert values coming from custom settings
//                  based on the sales organization of the user.
//
// Author       :   Divino Brinas - Accenture
// Updated Date :   March 06, 2017
// Notes        :   Pre-populated Country Field - This function is used to prepopulate the country field
//                     After the saving.
//Aditya--Renamed the field from Actual Revenue (last 12 months)(Account_Annual_Value__c) to Estimated Revenue Agreement Based
//-------------------------------------------------------------------------------------------//
public without sharing class AccountTriggerHandler implements ITriggerHandler{
    public static boolean createEpiILOG = false;
    public static Boolean isTriggerDisabled = true;
    public static Boolean isCreate;
    public static Boolean isBatchRun = false;
    private static Map<String, String> filteredAccountFieldMap = new Map<String, String>();
    private static Map<String, String> filteredAddressFieldMap = new Map<String, String>();
    private static Boolean epiUpdated = false;
    private static Boolean SAPfieldSet = false;
    private static Boolean EPIfieldSet = false;
    private static final User u = UserDAO.userInformation();
    private static final Map<String, String> AccountFieldMap = new Map<String, String>{
        'Name'=> 'Updated_Account_Name__c',
        'Second_Account_Name__c'=> 'Updated_Second_Account_Name__c',
        'Sales_Office__c'=> 'Updated_Sales_Office__c',
        'Archiving_Flag__c'=> 'Updated_Archiving_Flag__c',
        'Language__c'=> 'Updated_Language__c',
        'Bill_Block_Reason__c'=> 'Updated_Bill_Block_Reason__c',
        'Main_Postal_Box_City__c'=> 'Updated_Main_Postal_box_City__c',
        'Main_Postal_Box__c'=> 'Updated_Main_Postal_Box__c',
        'Main_Postal_Box_Postal_Code__c'=> 'Updated_Main_Postal_Box_Postal_Code__c', 
        'Main_Address_ILN_1__c'=> 'Updated_Main_Address_ILN_1__c',
        'Main_Address_ILN_2__c'=> 'Updated_Main_Address_ILN_2__c',
        'Main_Address_ILN_Digit__c'=> 'Updated_Main_Address_ILN_Digit__c',
        'Delivery_Block_Reason__c'=> 'Updated_Delivery_Block_Reason__c',
        'Segment__c'=> 'Updated_Segment__c',
        'Subsegment__c'=> 'Updated_Sub_Segment__c',
        'Mini_Dunning_procedure__c'=> 'Updated_Dunning_Procedure__c',
        'Mini_Invoicing_dates__c'=> 'Updated_Invoicing_Dates__c',
        'Invoice_List_Dates__c'=> 'Updated_Invoice_List_Dates__c',
        'Transactional_Block_Reason__c'=> 'Updated_Transactional_Block_Reason__c',
        'Third_Account_Name__c'=> 'Updated_Third_Account_Name__c',
        'Fourth_Account_Name__c'=> 'Updated_Fourth_Account_Name__c',
        'Account_Block__c'=> 'Updated_Account_Block__c',
        'VAT_Registration_Number__c'=> 'Updated_VAT_Registration_Number__c',
        'Bill_To_Payer_Account__c'=> 'Updated_Related_Bill_to_Account__c',
        'Related_Payer_Account__c'=> 'Updated_Related_Payer_Account__c',
        'House_Number_Supplement__c'=> 'Updated_House_Number_Supplement__c',
        'Region_API_Code__c'=> 'Updated_Region_Codes__c',
        'Billing_Header_Text__c'=> 'Updated_Billing_Header_Text__c',
        'Forwarding_Partner_Number__c'=> 'Updated_Forwarding_Partner_Number__c',
        'Main_Postal_Box_Supplement__c'=> 'Updated_Main_Postal_Box_Supplement__c',
        'Mini_Delivery_Priority__c'=> 'Updated_Delivery_Priority__c',
        'Mini_Shipping_Conditions__c'=> 'Updated_Shipping_Conditions__c',
        'Mini_Incoterms_Part_1__c'=> 'Updated_Incoterms_Part_1__c',
        'Mini_Incoterms_Part_2__c'=> 'Updated_Incoterms_Part_2__c',
        'Mini_Account_assigment_group__c'=> 'Updated_Account_Assignment_Group__c'
    };
    
    private static final Map<String, String> AddressFieldMap = new Map<String, String>{
        'Main_Street__c'=> 'Updated_Main_Street__c',
        'Main_House_Number__c'=> 'Updated_Main_House_Number__c',
        'Main_Street_Only__c'=> 'Updated_Main_Street_Only__c',
        'Main_City__c'=> 'Updated_Main_City__c',
        'Main_State__c'=> 'Updated_Main_State__c',
        'Main_Postal_Code__c'=> 'Updated_Main_PostalCode__c',
        'Main_Country__c'=> 'Updated_Main_Country__c',
        'Main_Country_ISO__c'=> 'Updated_Main_Country_ISO__c'
    };

    //Alvin Lomod - check if SAP related fields were changed
    Map<Id, Account> oldAcountMap = new Map<Id, Account>();

    public void beforeInsert(List<Account> newAccountList){
        isCreate = true;
        checkVatValidationRule(newAccountList, oldAcountMap);
        checkPostalBoxValidationRule(newAccountList, oldAcountMap);
        checkPOBoxValue(newAccountList, oldAcountMap);
        addDefaultValues(newAccountList);
        changeDuplicateValidationifnotORC(newAccountList, oldAcountMap);
        streetConcatenation(newAccountList, oldAcountMap);
        checkPaymentTerValidationRule(newAccountList, oldAcountMap);
        populateAvgCoffeeDosage(newAccountList, oldAcountMap);
        populateAVE(newAccountList, oldAcountMap);
        updateUltimateParentAccountNameSearch(newAccountList, oldAcountMap);
        assignSicCode(newAccountList, oldAcountMap);
        accountArchivingProcess(newAccountList, oldAcountMap);
        administrativeAddressCheck(newAccountList);
        assignTerritory(newAccountList, oldAcountMap);
        forwardingPartnerAssignDefault(newAccountList, oldAcountMap);
        forwardingPartnerAssignToOwner(newAccountList, oldAcountMap);
        invokeOTCclasForParentAccount(newAccountList, oldAcountMap);
        populateBackorFrontendcustomer(newAccountList, oldAcountMap);
        prospectNoAddressValidation(newAccountList, oldAcountMap);
        administrativeaddressNoAddressValidation(newAccountList, oldAcountMap);
        populateSicCodeandSIcDescription(newAccountList, oldAcountMap); 
        stampmachineparktimeanduser(newAccountList, oldAcountMap);
        changeRecordTypeToValid(newAccountList, oldAcountMap);
        accountValid(newAccountList, oldAcountMap);
        alignBillingAddressWithMainAddress(newAccountList, oldAcountMap);
        checkrecursive.run = false;
        
    } 
 
    public void beforeUpdate(List<Account> newAccountList, Map<Id, SObject> newItems, List<Account> oldList, Map<Id, SObject> oldSobjectMap){
        Map<Id, Account> oldAccountMap = (Map<Id, Account>) oldSobjectMap;
        if (checkrecursive.run == true) {
            checknamechangeforpartner(newAccountList, oldAccountMap);
            checkPaymentTerValidationRule(newAccountList, oldAccountMap);
            checkVatValidationRule(newAccountList, oldAccountMap);
            checkPostalBoxValidationRule(newAccountList,oldAccountMap);
            checkPOBoxValue(newAccountList, oldAcountMap);
            //financeControllerNoManagercheckPostalBoxValidationRule(newAccountList, oldAccountMap);
            changeDuplicateValidationifnotORC(newAccountList, oldAccountMap);
            //once Set Account Status to Valid  workflow is refactored place it below changeDuplicateValidationifnotORC
            changeRecordTypeToValid(newAccountList, oldAccountMap);
            updateBill2Payer(newAccountList, oldAccountMap);
            //reActivateAccount(newAccountList, oldAccountMap);
            updateUltimateParentAccountNameSearch(newAccountList, oldAccountMap);
            assignSicCode(newAccountList, oldAccountMap);
            accountValid(newAccountList, oldAccountMap);
            accountNotValid(newAccountList, oldAccountMap);
            fieldAddressValidationApproved(newAccountList, oldAccountMap);
            forwardingPartnerAssignDefault(newAccountList, oldAccountMap);
            forwardingPartnerAssignToOwner(newAccountList, oldAccountMap);
            billBlockReasonRemove(newAccountList, oldAccountMap);
            if(TriggerSettings__c.getInstance().BulkDataSwitch__c){
                changeFieldValueAccount(newAccountList, oldAccountMap);         
            }
            accountArchivingProcess(newAccountList, oldAccountMap);
            stampTransportationZoneBasedOnMainCountryISO(newAccountList, oldAccountMap);
            sapReturnAfterPromotion(newAccountList, oldAccountMap);
            sapReturnAfterIntegration(newAccountList, oldAccountMap);
            stampRelatedBilltoandPayer(newAccountList, oldAccountMap);
            assignTerritory(newAccountList, oldAccountMap);
            userAssignTerritory(newAccountList, oldAccountMap);
            streetConcatenation(newAccountList, oldAccountMap);
            alignBillingAddressWithMainAddress(newAccountList, oldAccountMap);          
            approvalRecallAndReject(newAccountList, oldAccountMap);
            approvalProcessApproved(newAccountList, oldAccountMap);
            populateAvgCoffeeDosage(newAccountList,(Map<Id, Account>) oldAccountMap);
            populateAVE(newAccountList, oldAccountMap);
            invokeOTCclasForParentAccount( newAccountList, oldAccountMap);
            stampHasChildAccount(newAccountList, oldAccountMap);
            changeMethodTermStatus(newAccountList, oldAccountMap);
            changeAccountLifeCycle(newAccountList, oldAccountMap);
            populateBackorFrontendcustomer(newAccountList, oldAccountMap);
            prospectNoAddressValidation(newAccountList, oldAccountMap);
            administrativeaddressNoAddressValidation(newAccountList, oldAccountMap);
            populateSicCodeandSIcDescription(newAccountList, oldAccountMap);
            SAPforwardingParntnerDefault(newAccountList, oldAccountMap);
            checkSubSegmentChangesonCustomer(newAccountList, oldAccountMap);
            stampmachineparktimeanduser(newAccountList, oldAccountMap);
        }
    }
 
    public void beforeDelete(List<Account> oldList, Map<Id, SObject> oldItems){
        
    }
 
    public void afterInsert(List<Account> newAccountList, Map<Id, SObject> newItems){
        isCreate = true;
        createIntegrationLogs(newAccountList, oldAcountMap); 
        insertUpdateAccountLocation(newAccountList, oldAcountMap);
        insertAccountTax(newAccountList);
        invokeOTCclasForRelatedBuyingGroup( newAccountList, oldAcountMap);
        // stampUltimateParentId(newAccountList, oldAcountMap);
        checkrecursive.run = false;
    }
 
    public void afterUpdate(List<Account> newAccountList , Map<Id, SObject> newItems, List<Account> oldList, Map<Id, SObject> oldSobjectMap){
        Map<Id, Account> oldAccountMap = (Map<Id, Account>) oldSobjectMap;
        if (checkrecursive.run == true) {
            createIntegrationLogsAfterSAP(newAccountList, oldAccountMap);
            createIntegrationLogs(newAccountList, oldAccountMap);
            insertUpdateAccountLocation(newAccountList, oldAccountMap);
            reassignToManagerApprovalRequest(newAccountList, oldAccountMap);
            invokeOTCclasForRelatedBuyingGroup (newAccountList, oldAccountMap);
            updateRelatedOpportunity(newAccountList, oldAccountMap);
            // stampUltimateParentId(newAccountList, oldAccountMap);
            checkrecursive.run = false;
        }
       
    }
 
    public void afterDelete(List<Account> oldList, Map<Id, SObject> oldItems){
        
    }
 
    public void afterUndelete(List<Account> newList, Map<Id, SObject> newItems){
        
    }
    
    public Boolean IsDisabled(){
        if (TriggerSettings__c.getInstance().AccountTrigger__c == true && !isBatchRun) {
            return false;
        } else {
            return isTriggerDisabled;
        }
    }
    
    
    private static Boolean invalidPOBox(Account acct, Map<Id, Account> oldAccountMap) {
        Account oldAcc;
        Boolean poBoxUpdate = false;
        if (acct.RecordTypeId != SM_Constants.recordTypeIdServiceProvider) {
            if(!oldAccountMap.isEmpty()) {
                oldAcc = oldAccountMap.get(acct.Id);
                if ((acct.Main_Postal_Box__c != NULL && acct.Main_Postal_Box__c != oldAcc.Main_Postal_Box__c) || 
                    (acct.Main_Postal_Box_City__c != Null && acct.Main_Postal_Box_City__c !=  oldAcc.Main_Postal_Box_City__c) || 
                    (acct.Main_Postal_Box_Postal_Code__c != Null && acct.Main_Postal_Box_Postal_Code__c != oldAcc.Main_Postal_Box_Postal_Code__c)) {
                    poBoxUpdate = true;
                }
            } else {
                if (acct.Main_Postal_Box__c != NULL || acct.Main_Postal_Box_City__c != Null || acct.Main_Postal_Box_Postal_Code__c != Null) {
                    poBoxUpdate = true;
                }
            }
        }
        
        return poBoxUpdate;
    }
    
    public static void checkPOBoxValue(List<Account> newAccountList, Map<Id, Account> oldAccountMap) {
        CustomLogging.push('checkPOBoxValue', 'AccountTriggerHandler');
        try {
            List<Account> accountFiltered = new List<Account>();
            for (Account a : newAccountList) {
                if (invalidPOBox(a, oldAccountMap)) {
                    accountFiltered.add(a);
                }
            }
            
            if (!accountFiltered.isEmpty()) {
                SM_AccountUtil.poBoxDependencies(accountFiltered);
            }
        } catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop(); 
    }
    
    private static Boolean checkPaymentTermVal(Account acct, Map<Id, Account> oldAccountMap) {
        Account oldAcc;
        Boolean ptUpdate = false;
        if (acct.RecordTypeId != SM_Constants.recordTypeIdCompetitor && acct.RecordTypeId != SM_Constants.recordTypeIdServiceProvider) {
            if(!oldAccountMap.isEmpty()) {
                oldAcc = oldAccountMap.get(acct.Id);
                if (acct.Apttus_Config2__PaymentTermId__c == NULL && acct.Apttus_Config2__PaymentTermId__c != oldAcc.Apttus_Config2__PaymentTermId__c) {
                    ptUpdate = true;
                }
            } else {
                if (acct.Apttus_Config2__PaymentTermId__c == NULL) {
                    ptUpdate = true;
                }
            }
        }
        
        return ptUpdate;
    }
    
    public static void checkPaymentTerValidationRule(List<Account> newAccountList, Map<Id, Account> oldAccountMap){
        CustomLogging.push('checkPaymentTerValidationRule', 'AccountTriggerHandler');
        try {
            List<Account> accountFiltered = new List<Account>();
            for (Account a : newAccountList) {
                if (checkPaymentTermVal(a, oldAccountMap)) {
                    accountFiltered.add(a);
                }
            }
            
            if (!accountFiltered.isEmpty()) {
                SM_AccountUtil.paymentermEmpty(accountFiltered);
            }
        } catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop(); 
    }
    
    /**
    * @author        Alvin Lomod
    * @date                   
    * @description   VAT Registration Number Validation Check Rule and Length - KASM-2401
    * @revision(s)   Catherine Aragon - 08.02.19 - Refactored
    */
    
    private static Boolean invalidVAT(Account acct, Map<Id, Account> oldAccountMap) {
        Account oldAcc;
        Boolean vatUpdate = false;
        if (acct.RecordTypeId != SM_Constants.recordTypeIdServiceProvider) {
            if(!oldAccountMap.isEmpty()) {
                oldAcc = oldAccountMap.get(acct.Id);
                if (acct.VAT_Registration_Number__c != NULL && acct.VAT_Registration_Number__c != oldAcc.VAT_Registration_Number__c) {
                    vatUpdate = true;
                }
            } else {
                if (acct.VAT_Registration_Number__c != NULL ) {
                    vatUpdate = true;
                }
            }
        }
        
        return vatUpdate;
    }
    
    public static void checkVatValidationRule(List<Account> newAccountList, Map<Id, Account> oldAccountMap){
        CustomLogging.push('checkVatValidationRule', 'AccountTriggerHandler');
        try {
            List<Account> accountFiltered = new List<Account>();
            for (Account a : newAccountList) {
                if (invalidVAT(a, oldAccountMap)) {
                    accountFiltered.add(a);
                }
            }
            
            if (!accountFiltered.isEmpty()) {
                SM_AccountUtil.vatValidationRule(accountFiltered);
            }
        } catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop(); 
    }
    
    private static Boolean invalidPostalBox(Account acct, Map<Id, Account> oldAccountMap) {
        Account oldAcc;
        Boolean pbUpdate = false;
        if (acct.RecordTypeId != SM_Constants.recordTypeIdServiceProvider) {
            if(!oldAccountMap.isEmpty()) {
                oldAcc = oldAccountMap.get(acct.Id);
                if (acct.Main_Postal_Box_Postal_Code__c != NULL && acct.Main_Postal_Box_Postal_Code__c != oldAcc.Main_Postal_Box_Postal_Code__c) {
                    pbUpdate = true;
                }
            } else {
                if (acct.Main_Postal_Box_Postal_Code__c != NULL ) {
                    pbUpdate = true;
                }
            }
        }
        
        return pbUpdate;
    }
    
    public static void checkPostalBoxValidationRule(List<Account> newAccountList, Map<Id, Account> oldAccountMap){
        CustomLogging.push('checkPostalBoxValidationRule', 'AccountTriggerHandler');
        try {
            List<Account> accountFiltered = new List<Account>();
            for (Account a : newAccountList) {
                if (invalidPostalBox(a, oldAccountMap)) {
                    accountFiltered.add(a);
                }
            }
            
            if (!accountFiltered.isEmpty()) {
                SM_AccountUtil.postalBoxPostalCodeValidationRule(accountFiltered);
            }
        } catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop(); 
    }
    
    /*private static Boolean fieldApproval(Account acct, Map<Id, Account> oldAccountMap, Map<Id, User> ufinance) {
        Account oldAcc;
        Boolean approvalFields = false;
        if(!oldAccountMap.isEmpty()) {
            oldAcc = oldAccountMap.get(acct.Id);
            if ((acct.Commercial_Register_Number__c != NULL && acct.Commercial_Register_Number__c != oldAcc.Commercial_Register_Number__c) ||
                (acct.APTS_Payment_Method__c != NULL && acct.APTS_Payment_Method__c != oldAcc.APTS_Payment_Method__c) || 
                (acct.Apttus_Config2__PaymentTermId__c != NULL && acct.Apttus_Config2__PaymentTermId__c != oldAcc.Apttus_Config2__PaymentTermId__c) ||
                (acct.Partner__c != oldAcc.Partner__c) || (acct.Mini_Customer_Pricing_Procedure__c != NULL && acct.Mini_Customer_Pricing_Procedure__c != oldAcc.Mini_Customer_Pricing_Procedure__c)) {
                if (UserInfo.getUserId() == ufinance.get(acct.Id).Id && ufinance.get(acct.Id).ManagerId == Null) {
                    approvalFields = true;
                }
            }
        } 
        
        return approvalFields;
    }
    
    public static void financeControllerNoManager(List<Account> newAccountList, Map<Id, Account> oldAccountMap) {
        CustomLogging.push('financeControllerNoManager', 'AccountTriggerHandler');
        try {
            List<Account> accountFiltered = new List<Account>();
            Map<Id, User> ufinance = UserDAO.accountFinanceController(newAccountList);
            for (Account a : newAccountList) {
                if (fieldApproval(a, oldAccountMap, ufinance)) {
                    accountFiltered.add(a);
                }
            }
            
            if (!accountFiltered.isEmpty()) {
                SM_AccountUtil.financeControllerValidation(accountFiltered);
            }
        } catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop(); 
    }*/
     
    /**
    * @author        Catherine Kia Aragon
    * @date                   
    * @description   Reassign current approval to User's Manager
    * @revision(s)   08.05.19 Refactor - Catherine Aragon
    */
    private static Boolean reassignAccount(Account acct, Map<Id, Account> oldAccountMap){
        Account oldAcc;
        Boolean accReassign = false;
        if (!oldAccountMap.isEmpty()) {
            oldAcc = oldAccountMap.get(acct.Id);
            if (acct.Reject_to_Transfer__c != oldAcc.Reject_to_Transfer__c && acct.Reject_to_Transfer__c == true) {
                accReassign = true;
            }
        } 
        return accReassign;
    }
    public static void reassignToManagerApprovalRequest(List<Account> newAccountList , Map<Id, Account> oldAccountMap) {
        CustomLogging.push('reassignToManagerApprovalRequest', 'AccountTriggerHandler');
        try {
            List<Account> accountFiltered = new List<Account>();
            for(Account a : newAccountList) {
                if (reassignAccount(a, oldAccountMap)) {
                    accountFiltered.add(a);
                }
            }
            if (!accountFiltered.isEmpty()) {
                SM_AccountUtil.updateAssignedApprover(accountFiltered);
            }
        } catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop(); 
    }
    
    /**
    * @author        Catherine Kia Aragon
    * @date                   
    * @description   Change field values after approver approved
    * @revision(s)   08.05.19 Refactor - Catherine Aragon
    */
    
    private static Boolean statusApproved(Account acct, Map<Id,Account> oldAccountMap) {
        Account oldAcc;
        Boolean statusChange = false;
        if (!oldAccountMap.isEmpty()) {
            oldAcc = oldAccountMap.get(acct.Id);
            if (acct.Approval_Status__c != oldAcc.Approval_Status__c && acct.Approval_Status__c == SM_Constants.ApprovalApproved) {
                statusChange = true;
            }
        }
        return statusChange;
    }

    public static void approvalProcessApproved(List<Account> newAccountList, Map<Id,Account> oldAccountMap) {
        CustomLogging.push('approvalProcessApproved', 'AccountTriggerHandler');
        try {
            List<Account> accountFiltered = new List<Account>();
            for (Account a : newAccountList) {
                if (statusApproved(a, oldAccountMap)) {
                    accountFiltered.add(a);
                }
            }
            
            if (!accountFiltered.isEmpty()) {
                SM_AccountUtil.approvalProcessApproved(accountFiltered);
            }
        } catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop(); 
    }
    
    /**
    * @author        Catherine Kia Aragon
    * @date                   
    * @description   Change field values after approver rejected or user recall
    * @revision(s)   12.02.19 Refactor - Catherine Aragon
    */
    private static Boolean checkApprovalStatus(Account acct, Map<Id,Account> oldAccountMap) {
        Account oldAcc;
        Boolean statusChange = false;
        if (!oldAccountMap.isEmpty()) {
            oldAcc = oldAccountMap.get(acct.Id);
            if (acct.Approval_Status__c != oldAcc.Approval_Status__c && (acct.Approval_Status__c == SM_Constants.ApprovalRecall || acct.Approval_Status__c == SM_Constants.ApprovalDeclined)) {
                statusChange = true;
            }
        }
        return statusChange;
    }
    
    public static void approvalRecallAndReject(List<Account> newAccountList, Map<Id,Account> oldAccountMap) {
        CustomLogging.push('approvalRecallAndReject', 'AccountTriggerHandler');
        try {
            List<Account> accountFiltered = new List<Account>();
            for (Account a : newAccountList) {
                if (checkApprovalStatus(a, oldAccountMap)) {
                    accountFiltered.add(a);
                }
            }
            
            if (!accountFiltered.isEmpty()) {
                SM_AccountUtil.approvalRecallAndReject(accountFiltered);
            }
        } catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop(); 
    }
    
    /**
    * @author        Catherine Kia Aragon
    * @date                   
    * @description   Update Request Field - This is used to updated the fields with old values and new values
    * @revision(s)   19.01.2018 - Alvin Lomod KASM-902
    */
    private static Boolean checkFieldUpdate(Account acct, Map<Id,Account> oldAccountMap){
        Account oldAcc = oldAccountMap.get(acct.Id);
        Boolean fieldUpdated = false;
        if ((acct.Address_Validation__c != 'Request Address Validation' || (acct.Address_Validation__c == 'Valid' && oldAcc.Address_Validation__c == 'Request Address Validation')) && 
            (acct.SAP_Customer_ID__c != Null && u.Profile.Name != SM_Constants.JDESAP && 
            (acct.RecordTypeId == SM_Constants.recordTypeIdAdministrativeAddress || acct.RecordTypeId == SM_Constants.recordTypeIdCustomer) && 
            (oldAcc.RecordTypeId != SM_Constants.recordTypeIdEndCustomerValidation && oldAcc.RecordTypeId != SM_Constants.recordTypeIdAdministrativeAddressValidation && oldAcc.RecordTypeId != SM_Constants.recordTypeIdPromotionRequested) || 
            (acct.Subsegment__c != oldAcc.Subsegment__c && acct.Segment__c != oldAcc.Segment__c && acct.of_Employees_FTE__c != oldAcc.of_Employees_FTE__c))){
                if (fieldSetEPIUpdated(acct, oldAccountMap)) {
                    fieldUpdated = true;
                    epiUpdated = true;
                }
            
                for (String fldAcct : AccountFieldMap.keySet()) {
                    if ((acct.get(fldAcct) != oldAcc.get(fldAcct) && fldAcct != 'Subsegment__c') || (acct.get(fldAcct) != Null && fldAcct != 'Subsegment__c') || (acct.get(fldAcct) != Null && oldAcc.get(fldAcct) != acct.get(fldAcct) && fldAcct == 'Subsegment__c' && oldAcc.get('Segment__c') != acct.get('Segment__c')) || (oldAcc.get(fldAcct) != Null && acct.get(fldAcct) == Null && (fldAcct == 'Delivery_Block_Reason__c' || fldAcct == 'Mini_Dunning_procedure__c' || fldAcct == 'Sales_Office__c' || fldAcct == 'Sales_Group__c' || fldAcct == 'Bill_Block_Reason__c' || fldAcct == 'Transactional_Block_Reason__c' || fldAcct == 'Mini_Invoicing_dates__c' || fldAcct == 'Invoice_List_Dates__c' || fldAcct == 'House_Number_Supplement__c' || fldAcct == 'Second_Account_Name__c' || fldAcct == 'Third_Account_Name__c' || fldAcct == 'Fourth_Account_Name__c' || fldAcct == 'Main_Postal_Box_City__c' || fldAcct == 'Main_Postal_Box__c' || fldAcct =='Main_Postal_Box_Postal_Code__c' || fldAcct == 'Bill_To_Payer_Account__c' || fldAcct =='Related_Payer_Account__c' )) )  {
                        filteredAccountFieldMap.put(fldAcct, AccountFieldMap.get(fldAcct));
                        fieldUpdated = true; 
                    }
                   
                }
                for (String fldAddress : AddressFieldMap.keySet()) {
                    if (acct.get(fldAddress) != Null) {
                        filteredAddressFieldMap.put(fldAddress, AddressFieldMap.get(fldAddress));
                        fieldUpdated = true;
                    }
                }
                
                /*for (String fldApttus : ApttusFieldMap.keySet()) {
                    if (acct.get(fldApttus) != oldAcc.get(fldApttus) ) {
                        //filteredApttusFieldMap.put(fldApttus, ApttusFieldMap.get(fldApttus));
                        fieldUpdated = true;
                    }
                }*/
        }
        return fieldUpdated;
    }
    public static void changeFieldValueAccount(List<Account> newAccountList, Map<Id,Account> oldAccountMap){
        CustomLogging.push('changeFieldValueAccount', 'AccountTriggerHandler');
        try {
            if (!oldAccountMap.isEmpty()) {
                //Fields to Check for Updates ~Account fields API Name
                Set<Account> accountToUpdate = new Set<Account>();
                for (Account a : newAccountList) {
                    if(checkFieldUpdate(a, oldAccountMap)) {
                        accountToUpdate.add(a);
                    }
                }
                //!filteredApttusFieldMap.isEmpty()
                if (!accountToUpdate.isEmpty() && (!filteredAccountFieldMap.isEmpty() || filteredAddressFieldMap.isEmpty() || epiUpdated == true )) {
                    SM_AccountUtil.changeFieldValue(accountToUpdate, oldAccountMap, filteredAccountFieldMap, filteredAddressFieldMap, epiUpdated);
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
    * @author        Catherine Kia Aragon
    * @date                   
    * @description   This is used to insert values coming from custom settings based on the sales organization of the user.
    * @revision(s)   
    */
    public static void addDefaultValues(List<Account> newAccountList){     
        CustomLogging.push('addDefaultValues', 'AccountTriggerHandler');
        try {
            SM_AccountUtil.defaultValuePerSalesOrg(newAccountList);     
        } catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }

    }
    
    //08.05.19 Refactor - Catherine Aragon
    public static void insertAccountTax(List<Account> newAccountList){
        CustomLogging.push('insertAccountTax', 'AccountTriggerHandler');
        try{
            List<Account> accountTobeRelToTax = new List<Account>();
            for(Account a : newAccountList) {
                if (UserService.recordTypeNotServiceProvider(a)) {
                    accountTobeRelToTax.add(a);
                }
            }
            if (!accountTobeRelToTax.isEmpty()) {
                SM_AccountUtil.createAccountTax(accountTobeRelToTax);
            }
        } catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop(); 
    }
    
    // Start KASM-1309 02-03-2018 Glenn Serrano SIC CODES
    // Updated DOS-366 Catherine Aragon Refactor
    private static Boolean invalidAccountCheck(Account acct, Map<Id, Account> oldAcountMap) {
        Account oldAcc;
        Boolean userUpdate = false;
        if(!oldAcountMap.isEmpty()) {
            oldAcc = oldAcountMap.get(acct.Id);
            if (acct.RecordTypeId == SM_Constants.recordTypeIdCustomer && ((acct.SIC_Name__c != NULL && acct.SIC_Name__c != oldAcc.SIC_Name__c) || (acct.of_Employees_FTE__c  != NULL && acct.of_Employees_FTE__c  != oldAcc.of_Employees_FTE__c ) || (acct.Segment__c != NULL && acct.Segment__c != oldAcc.Segment__c) || (acct.Subsegment__c != NULL && acct.Subsegment__c != oldAcc.Subsegment__c))) {
                userUpdate = true;
            }
        } else {
            if (acct.RecordTypeId == SM_Constants.recordTypeIdCustomer && (acct.SIC_Name__c != NULL || acct.Segment__c != NULL || acct.Subsegment__c != NULL)) {
                userUpdate = true;
            }
        }
        
        return userUpdate;
    }
    
    //08.05.19 Refactor - Catherine Aragon
    private static Boolean assignSic(Account acct, Map<Id, Account>oldAccountMap) {
        Account oldAcc;
        Boolean assignSicCode = false;
        if (!oldAccountMap.isEmpty()) {
            oldAcc = oldAccountMap.get(acct.Id);
            if ((acct.SIC_Name__c != null && acct.SIC_Name__c != oldAcc.SIC_Name__c) || 
                (acct.of_Employees_FTE__c != Null && acct.of_Employees_FTE__c != oldAcc.of_Employees_FTE__c) || 
                 (acct.Segment__c != Null && acct.Segment__c != oldAcc.Segment__c) ||
                 (acct.Subsegment__c != Null && acct.Subsegment__c != oldAcc.Subsegment__c)) {
                assignSicCode = true;
            }
        } else {
            if (acct.SIC_Name__c != null || (acct.of_Employees_FTE__c != Null && acct.Segment__c != Null && acct.Subsegment__c != Null)) {
                assignSicCode = true;
            }
        }
        
        return assignSicCode;
    }
    
    public static void assignSicCode(List<Account> newAccountList, Map<Id, Account>oldAccountMap) {
        CustomLogging.push('assignSicCode', 'AccountTriggerHandler');
        try{
            List<Account> accountFiltered = new List<Account>();
            for (Account a : newAccountList) {
                if (assignSic(a, oldAccountMap)){
                    accountFiltered.add(a);
                }
            }
            
            if (!accountFiltered.isEmpty()){
                SM_AccountUtil.assignJDESicCode(accountFiltered);
            }
            
        } catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        }
        CustomLogging.pop();
    }
   
    // End KASM-1309 02-03-2018 Glenn Serrano SIC CODES

    // Description: This is used to validated if the record has existing Bill2Payer // 2 records cannot be each others bill to payers
    // Scenario: Can only be triggered on mass insert of account
    // Updated: 14-07-2017 Alvin Lomod; 08.05.19 Refactor - Catherine Aragon
    private static Boolean updatePayer(Account acct, Map<Id,Account> oldAccountMap){
        Account oldAcc;
        Boolean updateBillPayer = false;
        oldAcc = oldAccountMap.get(acct.Id);
        if (acct.Bill_To_Payer_Account__c != null && acct.Bill_To_Payer_Account__c != oldAcc.Bill_To_Payer_Account__c) {
            updateBillPayer = true;
        }
        return updateBillPayer;
    }
    public static void updateBill2Payer(List<Account> newAccountList, Map<Id,Account> oldAccountMap){
        CustomLogging.push('updateBill2Payer', 'AccountTriggerHandler');
        try{
            if(!oldAccountMap.isEmpty()){       
                Map<Id, Account> bill2Map = new Map<Id, Account>();
                for(Account a: newAccountList){
                    if (UserService.recordTypeNotServiceProvider(a) && updatePayer(a, oldAccountMap)){ 
                        //Get Bill To Payer Ids
                        bill2Map.put(a.Bill_To_Payer_Account__c, a);
                    }
                }
                if(bill2Map.size() > 0){
                    List<Account> bill2Accounts = [SELECT Id, Bill_To_Payer_Account__c FROM Account WHERE Id in: bill2Map.keyset()];
                    if(bill2Accounts.size() > 0){
                        SM_AccountUtil.billToPayerValidation(Bill2Accounts, bill2Map);  
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
    * @author        Kimiko Roberto
    * @date          04.05.2017           
    * @description   Method responsible for creating Integration Logs
    * @revision(s)   11.01.2018 - Alvin Lomod KASM-604
    */
    private static Boolean fieldSetEPIUpdated(Account a, Map<Id, Account> oldRecordMap){
        Account oldAcc;
        Boolean fieldsEPIUpdated = false;
        Set<String> EPIfieldSet = new Set<String>();
        //Dynamically get the fields from the field set and then use the same for comparison in the trigger for EPI/Digital iLog
        for(Schema.FieldSetMember fields :Schema.SObjectType.Account.fieldSets.getMap().get('EPI_Account_Field_Set').getFields()){
            EPIfieldSet.add(fields.getFieldPath());
        }
        
        for(string s: EPIfieldSet){
            if (!oldRecordMap.isEmpty()){
                oldAcc = oldRecordMap.get(a.Id);
                if(a.get(s) != oldAcc.get(s)){
                    fieldsEPIUpdated = true;
                    break;
                }
            }
            
        }
        return fieldsEPIUpdated;
    }
    private static Boolean fieldSetSAPUpdated(Account a, Map<Id, Account> oldRecordMap){
        Account oldAcc;
        Boolean fieldsSAPUpdated = false;
        Set<String> SAPfieldSet = new Set<String>();
        
        //Dynamically get the fields from the field set and then use the same for comparison in the trigger for SAP iLog
        for(Schema.FieldSetMember fields :Schema.SObjectType.Account.fieldSets.getMap().get('Integration_Account_Field_Set').getFields()){
            SAPfieldSet.add(fields.getFieldPath());
        }
        for(string s: SAPfieldSet){
            if (!oldRecordMap.isEmpty()){
                oldAcc = oldRecordMap.get(a.Id);
                if(a.get(s) != oldAcc.get(s)){ 
                    fieldsSAPUpdated = true;
                    break;
                }
            }
            
        }
        return fieldsSAPUpdated;
    }
    private static Boolean createIlog(Account acct, Map<Id, Account> oldRecordMap) {
        Account oldAcc;
        Boolean ilogCreate = false;
        
        if (!oldRecordMap.isEmpty()){
            oldAcc = oldRecordMap.get(acct.id);
            if ((fieldSetSAPUpdated(acct, oldRecordMap) || fieldSetEPIUpdated(acct, oldRecordMap) || acct.SAP_Customer_ID__c != oldAcc.SAP_Customer_ID__c || 
            acct.Main_Address_Validation_Pending__c != oldAcc.Main_Address_Validation_Pending__c || acct.Creditworthiness_Flag__c != oldAcc.Creditworthiness_Flag__c ||
            acct.RecordTypeId != oldAcc.RecordTypeId || (oldAcc.Address_Validation__c == 'Request Address Validation' && acct.Address_Validation__c == 'Valid')) && oldAcc.SAP_PO_Updated__c != true){
                ilogCreate = true;
                    if (fieldSetSAPUpdated(acct, oldRecordMap)){
                        SAPfieldSet = true;
                    }
                    if (fieldSetEPIUpdated(acct, oldRecordMap)){
                        EPIfieldSet = true;
                    }
            }
        } else {
            if (acct.Main_Address_Validation_Pending__c == false && !acct.SAP_PO_Updated__c) {
                ilogCreate = true;
            }
        }
        return ilogCreate;
    }
    public static void createIntegrationLogs(List<Account> newList, Map<Id, Account> oldRecordMap) {
        CustomLogging.push('createIntegrationLogs', 'AccountTriggerHandler');
        try{ 
            if(AccountTriggerHandlerHelper.integLogFirstTime == true) {
                Set<Account> accountFiltered = new Set<Account>();
                for (Account a : newList) {
                    if (UserService.recordTypeNotServiceProvider(a) && createIlog(a, oldRecordMap)) {
                        accountFiltered.add(a);
                    }
                }
                
                if (!accountFiltered.isEmpty()) {
                    SM_AccountUtil.createIntegLogs(accountFiltered, oldRecordMap, SAPfieldSet, EPIfieldSet); 
                    checkrecursive.run = false;
                }
            }
        } catch(Exception ex){     
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
    // private static Boolean createIlogAfterSAP(Account acct, Map<Id,Account> oldAccountMap){
    //     Account oldAcc = oldAccountMap.get(acct.id);
    //     Boolean createIlog = false;
    //     if (acct.SAP_PO_Updated__c == true && acct.SAP_PO_Updated__c != oldAcc.SAP_PO_Updated__c) {
    //         createIlog = true;
    //     }
    //     return createIlog;
    // }
    public void createIntegrationLogsAfterSAP(List<Account> newAccountList, Map<Id,Account> oldAccountMap) {
        CustomLogging.push('createIntegrationLogsAfterSAP', 'AccountTriggerHandler'); 
        try{
            if (!oldAccountMap.isEmpty()){
                if(AccountTriggerHandlerHelper.integLogFirstTime == true) {
                    Set<Account> accountTobeUpdated = new Set<Account>();
                    for(Account a : newAccountList){
                        if (createEpiILOG == true && fieldSetEPIUpdated(a, oldAccountMap)) {
                            accountTobeUpdated.add(a);
                        }
                    }
                    
                    if(!accountTobeUpdated.isEmpty()) {
                        SM_AccountUtil.createIntegLogsAfterSAP(accountTobeUpdated, oldAccountMap, createEpiILOG);
                    }
                }
            }
            
        } catch(Exception ex){     
            CustomLogging.debugException(ex);
            CustomLogging.pop();      
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        CustomLogging.pop(); 
    }
    
    /**
    * @author        Alvin Lomod
    * @date          06.07.2017           
    * @description   Method responsible for reassigning an updated account in an active territory model if a rule is met
    * @revision(s)   Address should be valid to be assigned to a territory - 03.08.2017
    */ 
    
    private static Boolean assignAcctTerritory(Account acct, Map<Id,Account> oldAccountMap){
        Account oldAcc;
        Boolean accAssignTerritory = false;
        if (!oldAccountMap.isEmpty()){
            oldAcc = oldAccountMap.get(acct.id);
            if (((acct.Main_Address_Validation_Timestamp__c != null && acct.Main_Address_Validation_Timestamp__c != oldAcc.Main_Address_Validation_Timestamp__c) ||
                (acct.Account_Lifecycle__c != null && acct.Account_Lifecycle__c != oldAcc.Account_Lifecycle__c) ||
                (acct.Segment__c != null && acct.Segment__c != oldAcc.Segment__c) || 
                (acct.Main_Country__c != null && acct.Main_Country__c != oldAcc.Main_Country__c)) && 
                 acct.Main_Address_Validation_Error__c == null && acct.Exclude_from_Territory_Assignment__c == false) {
                     
                 accAssignTerritory = true;
            }
        } else {
            if (u.Profile.Name == SM_Constants.JDEDigital && acct.Account_Lifecycle__c != null && acct.Segment__c != null && acct.Main_Country__c != null && acct.Main_Postal_Code__c != null && acct.Exclude_from_Territory_Assignment__c == false){
                accAssignTerritory = true;
            }
        }
        return accAssignTerritory;
    }
    
    public static void assignTerritory(List<Account> newAccountList,  Map<Id,Account> oldAccountMap){
        CustomLogging.push('assignTerritory', 'AccountTriggerHandler');
        try {
            List <Account> accountFiltered = new List<Account>();
            Set<String> country = new Set<String>();
            for(Account a : newAccountList){
                if(assignAcctTerritory(a, oldAccountMap) && UserService.recordTypeNotServiceProvider(a)) {
                    accountFiltered.add(a);
                    country.add(a.Main_Country__c);
                }
            }
            if (!accountFiltered.isEmpty()){
                SM_AccountUtil.assignmentOfTerritory(accountFiltered, country);
            }
            
        } catch(Exception ex){     
            CustomLogging.debugException(ex);
            CustomLogging.pop();      
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        CustomLogging.pop(); 
    }
    
    /**
    * @author        Catherine Aragon
    * @date          02.02.2018           
    * @description   Method responsible for populating the Avg Coffee Dosage based on the account sales organization and brewing system.
    * @revision(s)   08.05.19 Refactor - Catherine Aragon
    */ 
    private static Boolean addCoffeeAverage(Account a, Map<Id, Account> oldAccountMap) {
        Account oldAcc;
        Boolean addAveCoffee = false;
        if (!oldAccountMap.isEmpty()){
            oldAcc = oldAccountMap.get(a.Id);
            if (a.Brewing_System__c != Null && a.Brewing_System__c != '' && a.Brewing_System__c != oldAcc.Brewing_System__c){
                addAveCoffee = true;
            }
        }else {
            if (a.Brewing_System__c != Null && a.Brewing_System__c != ''){
                addAveCoffee = true;
            }
        }
        return addAveCoffee;
    }
    public static void populateAvgCoffeeDosage(List<Account> newAccountList, Map<Id, Account> oldAccountMap) {
        CustomLogging.push('populateAvgCoffeeDosage', 'AccountTriggerHandler');
        try{
            List<Account> accountFiltered = new List<Account>();
            for (Account a : newAccountList){
                if (addCoffeeAverage(a, oldAccountMap)) {
                    accountFiltered.add(a);
                }
            }
            if (!accountFiltered.isEmpty()) {
                SM_AccountUtil.avgCoffeeDossage(accountFiltered);
            }
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        CustomLogging.pop(); 
    }
    
    /**
    * @author        Jed Samaniego
    * @date          02.02.2018           
    * @description   Method responsible for populating Acount Value Estimation from Maintenance Table
    * @revision(s)   08.05.19 Refactor - Catherine Aragon
    */
    private static Boolean addAverage(Account acct, Map<Id,Account> oldAccountMap) {
        Account oldAcc;
        Boolean addAvg = false;
        if (!oldAccountMap.isEmpty()){
            oldAcc = oldAccountMap.get(acct.Id);
            if ((acct.of_Employees_FTE__c != 0 && acct.of_Employees_FTE__c != null && acct.of_Employees_FTE__c != oldAcc.of_Employees_FTE__c) || 
                (acct.Penetration__c != 0 && acct.Penetration__c != null && acct.Penetration__c != oldAcc.Penetration__c) ||
                (acct.Tea_Drinks__c != 0 && acct.Tea_Drinks__c != null && acct.Tea_Drinks__c != oldAcc.Tea_Drinks__c) ||
                (acct.Mini_Company_Code__c != null && acct.Mini_Company_Code__c != oldAcc.Mini_Company_Code__c) || 
                (acct.Segment__c != null && acct.Segment__c != oldAcc.Segment__c) ||
                (acct.Avg_Coffee_Dosage__c != Null && acct.Avg_Coffee_Dosage__c != oldAcc.Avg_Coffee_Dosage__c) || 
                (acct.Calculation_Method__c != null && acct.Calculation_Method__c != oldAcc.Calculation_Method__c) ||
                (acct.Subsegment__c != null && acct.Subsegment__c != oldAcc.Subsegment__c) || 
                (acct.Account_Annual_Value__c != null && acct.Account_Annual_Value__c != oldAcc.Account_Annual_Value__c)){
                    
                addAvg = true;
            }
        } else {
            if ((acct.of_Employees_FTE__c != 0 && acct.of_Employees_FTE__c != null) && 
                (acct.Penetration__c != 0 && acct.Penetration__c != null) && 
                (acct.Tea_Drinks__c != 0 && acct.Tea_Drinks__c != null) &&
                acct.Mini_Company_Code__c != null && acct.Segment__c != null && 
                acct.Avg_Coffee_Dosage__c != Null && acct.Calculation_Method__c != null && 
                acct.Subsegment__c != null && acct.Account_Annual_Value__c != null) {
                    
                addAvg = true;
            }
        }
        return addAvg;
    }
    public static void populateAVE(List<Account> newAccountList, Map<Id,Account> oldAccountMap){
        try {
            
            List<Account> accountFiltered = new List<Account>();
            for (Account a : newAccountList) {
                if (addAverage(a, oldAccountMap)) {
                    accountFiltered.add(a);
                } 
            }
            
            if (!accountFiltered.isEmpty()) {
                SM_AccountUtil.populateAverage(accountFiltered);
            }
        }  catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        CustomLogging.pop(); 
    }
    
    /**
    * @author        Catherine Aragon
    * @date          10.04.2018           
    * @description   Method for invoking OTC class APTS_ManageCER
    * @revision(s)   08.05.19 Refactor - Catherine Aragon
    */
    private Boolean hasRelatedBuyingGroup(Account acct, Map<Id,Account> oldAccountMap) {
        Account oldAcc;
        Boolean hasBuyingGroup = false;
        if (!oldAccountMap.isEmpty()){
            oldAcc = oldAccountMap.get(acct.Id);
            if (acct.Purchasing_Organization__c != oldAcc.Purchasing_Organization__c || acct.ParentId != oldAcc.ParentId || acct.APTS_Ultimate_Parent_Id__c != oldAcc.APTS_Ultimate_Parent_Id__c) {
                hasBuyingGroup = true;
            }
        } else {
            if (acct.Purchasing_Organization__c != null || acct.ParentId != null || acct.APTS_Ultimate_Parent_Id__c != null) {
                hasBuyingGroup = true;
            }
        }
        return hasBuyingGroup;
    }
    public void invokeOTCclasForRelatedBuyingGroup (List<Account> newAccList, Map<Id,Account> oldAccountMap){
        CustomLogging.push('invokeOTCclasForRelatedBuyingGroup', 'AccountTriggerHandler');
        try{
            List<Apttus__APTS_Agreement__c> agreementList = new List<Apttus__APTS_Agreement__c>();
            Set<Id> accountIds = new Set<Id>();
            List<Account> accountFiltered = new List<Account>();
            for(Account a : newAccList){
                if (hasRelatedBuyingGroup(a, oldAccountMap)) {
                    accountIds.add(a.Id);
                }
            } 
            
            if (!accountIds.isEmpty()) {
                checkrecursive.run = false;
                agreementList = [Select Id, Name, Apttus__Account__c FROM Apttus__APTS_Agreement__c  WHERE Apttus__Account__c IN :accountIds];
                if(agreementList.isEmpty()) {
                    for(Id i : accountIds) {
                        Apttus__APTS_Agreement__c agreementRec = new Apttus__APTS_Agreement__c();
                        agreementRec.Apttus__Account__c = i;
                        agreementList.add(agreementRec);
                    }
                }
                APTS_ManageCER.manageCERRecords(agreementList,'Account','Update');
            }
            
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        CustomLogging.pop(); 
    }
    
    /**
    * @author        Catherine Aragon
    * @date          10.04.2018           
    * @description   Method for invoking OTC class APTS_CLMUtil
    * @revision(s)   08.05.19 Refactor - Catherine Aragon
    */
    private Boolean hasParentAccount(Account acct, Map<Id,Account> oldAccountMap) {
        Account oldAcc;
        Boolean hasParentAcc = false;
        if (!oldAccountMap.isEmpty()) {
            oldAcc = oldAccountMap.get(acct.Id);
            if (acct.ParentId != null && acct.ParentId != oldAcc.ParentId) {
                hasParentAcc = true;
            }
        } else {
            if (acct.ParentId != Null) {
                hasParentAcc = true;
            }
        }
        return hasParentAcc;
        
    }
    public void invokeOTCclasForParentAccount (List<Account> newAccList, Map<Id,Account> oldAccountMap){
        CustomLogging.push('invokeOTCclasForParentAccount', 'AccountTriggerHandler');
        try{
            Map<Id, Account> filteredOldAccountMapItems = new Map<Id, Account>();
            List<Account> accountFiltered = new List<Account>();
            for(Account a : newAccList){
                if (hasParentAccount(a, oldAccountMap)) {
                    accountFiltered.add(a);
                    filteredOldAccountMapItems.put(a.Id, oldAccountMap.get(a.Id));
                }
            }
            
            if (!accountFiltered.isEmpty() && filteredOldAccountMapItems.isEmpty()) {
                APTS_CLMUtil.setContractedProductsOnly(accountFiltered, null);
            }
            
            if (!accountFiltered.isEmpty() && !filteredOldAccountMapItems.isEmpty()) {
                APTS_CLMUtil.setContractedProductsOnly(accountFiltered, filteredOldAccountMapItems);
            }
            
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        } 
        CustomLogging.pop(); 
        
    }
    
    private static Boolean stampTranspoZone(Account a, Map<Id,Account> oldAccountMap){
        Account oldAcc = oldAccountMap.get(a.id);
        Boolean stampTransZone = false;
        if (a.Main_Country_ISO__c != Null && a.Main_Country_ISO__c != oldAcc.Main_Country_ISO__c || a.Updated_Main_Country_ISO__c != oldAcc.Updated_Main_Country_ISO__c) {
            stampTransZone = true;
        }
        
        return stampTransZone;
    }
    
    public static void stampTransportationZoneBasedOnMainCountryISO(List<Account> newAccList, Map<Id,Account> oldAccountMap) {
        CustomLogging.push('stampTransportationZoneBasedOnMainCountryISO', 'AccountTriggerHandler');
        try{
            if (!oldAccountMap.isEmpty()) {
                List<Account> accountTobeUpdated = new List<Account>();
                 for (Account a : newAccList) {
                    if (stampTranspoZone(a, oldAccountMap)){
                        accountTobeUpdated.add(a);
                    }
                }
                
                if (!accountTobeUpdated.isEmpty()) {
                    SM_AccountUtil.stampTransportationZone(accountTobeUpdated);
                }
            }
            
            
           
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        CustomLogging.pop(); 
    }
    
    private static Boolean hasChildAccount(Account acct, Map<Id,Account> oldAccountMap){
        Account oldAcc;
        Boolean hasChild = false;
        if (!oldAccountMap.isEmpty()){
            oldAcc = oldAccountMap.get(acct.Id);
            if ((acct.APTS_BizIsland_Bonsai_Account__c && acct.APTS_BizIsland_Bonsai_Account__c != oldAcc.APTS_BizIsland_Bonsai_Account__c) && acct.ParentId == Null){
                hasChild = true;
            }
        } else {
            if (acct.APTS_BizIsland_Bonsai_Account__c && acct.ParentId == Null) {
                hasChild = true;
            }
        }
        return hasChild;
    }
    public static void stampHasChildAccount (List<Account> newAccList, Map<Id,Account> oldAccountMap) {
        CustomLogging.push('stampHasChildAccount', 'AccountTriggerHandler');
        try{
            List<Account> accountFiltered = new List<Account>();
            for (Account a : newAccList) {
                if(hasChildAccount(a, oldAccountMap)){
                    accountFiltered.add(a);
                }
            }
            
            if (!accountFiltered.isEmpty()){
                SM_AccountUtil.stampHasChildAccount(accountFiltered);
            }
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        CustomLogging.pop(); 
    }
    
    //08.05.19 Refactor - Catherine Aragon
    private static Boolean insertUpdateAccountLoc(Account acct, Map<Id,Account> oldAccountMap) {
        Account oldAcc;
        Boolean addressDefaultChanged = false;
        if (!oldAccountMap.isEmpty()) {
            oldAcc = oldAccountMap.get(acct.Id);
            if (acct.First_Account_Location_created__c && (acct.RecordTypeId == SM_Constants.recordTypeIdEndCustomerValidation || acct.RecordTypeId == SM_Constants.recordTypeIdCustomer || acct.RecordTypeId == SM_Constants.recordTypeIdProspectValid || acct.RecordTypeId == SM_Constants.recordTypeIdAdministrativeAddressValid || acct.RecordTypeId == SM_Constants.recordTypeIdPromotionRequested) &&
                (acct.Account_Status__c != oldacc.Account_Status__c || acct.Main_City__c != oldacc.Main_City__c || acct.Main_Country__c != oldacc.Main_Country__c || acct.Main_Postal_Code__c != oldacc.Main_Postal_Code__c ||
                 acct.Main_State__c != oldacc.Main_State__c || acct.Main_Street__c != oldacc.Main_Street__c || acct.Archiving_Flag__c != oldacc.Archiving_Flag__c || acct.Sales_Organization__c != oldacc.Sales_Organization__c ||
                 acct.Duplicate_Reason__c != oldacc.Duplicate_Reason__c || acct.Duplicate_Validation__c != oldacc.Duplicate_Validation__c || acct.Mini_Account_Group__c != oldacc.Mini_Account_Group__c || acct.Mini_Company_Code__c != oldacc.Mini_Company_Code__c ||
                 acct.Mini_Delivery_Control__c != oldacc.Mini_Delivery_Control__c || acct.Mini_Delivery_Priority__c != oldacc.Mini_Delivery_Priority__c || acct.Distribution_Channel__c != oldacc.Distribution_Channel__c ||
                 acct.Division__c != oldacc.Division__c || acct.Mini_Incoterms_Part_1__c != oldacc.Mini_Incoterms_Part_1__c || acct.Mini_Incoterms_Part_2__c != oldacc.Mini_Incoterms_Part_2__c ||
                 acct.Language__c != oldacc.Language__c || acct.Mini_Max_part_deliveries__c != oldacc.Mini_Max_part_deliveries__c || acct.Mini_Shipping_Conditions__c != oldacc.Mini_Shipping_Conditions__c ||
                 acct.Transportation_zone__c != oldacc.Transportation_zone__c || acct.Name != oldacc.Name || acct.Second_Account_Name__c != oldacc.Second_Account_Name__c || acct.Third_Account_Name__c != oldacc.Third_Account_Name__c || acct.Fourth_Account_Name__c != oldacc.Fourth_Account_Name__c || acct.Region__c != oldacc.Region__c || acct.SAP_Customer_ID__c != oldacc.SAP_Customer_ID__c || acct.Main_Address_Validation_Timestamp__c != oldacc.Main_Address_Validation_Timestamp__c ||
                 acct.Main_Address_Validation_Pending__c != oldacc.Main_Address_Validation_Pending__c || acct.Main_Address_Validation_Code__c != oldacc.Main_Address_Validation_Code__c || acct.Main_Address_Validation_Error__c != oldacc.Main_Address_Validation_Error__c ||
                 acct.Main_Country_ISO__c != oldacc.Main_Country_ISO__c ||  acct.Main_House_Number__c != oldacc.Main_House_Number__c || acct.Main_Street_Only__c != oldacc.Main_Street_Only__c ||
                 acct.House_Number_Supplement__c != oldacc.House_Number_Supplement__c || acct.Delivery_Block_Reason__c != oldacc.Delivery_Block_Reason__c)) {
                    addressDefaultChanged = true;
                 }
            if (!acct.First_Account_Location_created__c && !acct.Archiving_Flag__c && (acct.Main_Address_Validation_Timestamp__c != Null && acct.Main_Address_Validation_Error__c == null) &&
                (acct.RecordTypeId == SM_Constants.recordTypeIdCustomer || acct.RecordTypeId == SM_Constants.recordTypeIdProspectValid || acct.RecordTypeId == SM_Constants.recordTypeIdAdministrativeAddressValid)) {
                addressDefaultChanged = true;
            }
        } else {
            if (!acct.First_Account_Location_created__c && !acct.Archiving_Flag__c && (acct.Main_Address_Validation_Timestamp__c != Null && acct.Main_Address_Validation_Error__c == null) &&
                (acct.RecordTypeId == SM_Constants.recordTypeIdCustomer || acct.RecordTypeId == SM_Constants.recordTypeIdProspectValid || acct.RecordTypeId == SM_Constants.recordTypeIdAdministrativeAddressValid)) {
                addressDefaultChanged = true;
            }
        }
        return addressDefaultChanged;
    }
    
    public static void insertUpdateAccountLocation(List<Account> newAccList, Map<Id,Account> oldAccountMap) {
        CustomLogging.push('insertUpdateAccountLocation', 'AccountTriggerHandler');
        try{
            Set<Account> accountFiltered = new Set<Account>();
            for (Account a : newAccList) {
                if (insertUpdateAccountLoc(a, oldAccountMap)) {
                    accountFiltered.add(a);
                }
            }
            if (!accountFiltered.isEmpty()) {
                SM_AccountUtil.insertUpdateAccountLocation(accountFiltered, oldAccountMap);
            }
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        CustomLogging.pop();        
    }
    /**
    * @author        Catherine Aragon
    * @date          08.05.19           
    * @description   Refactor - Catherine Aragon
    * @revision(s)   05.25.20 Added administrative address invalid to valid (workflow) - Catherine Aragon
    * 				 04.13.21 Included prospect record type to prospect valid for credit check
    */
    private static Boolean changeRT(Account acct, Map<Id, Account> oldAccountMap) {
        Account oldAcc = oldAccountMap.get(acct.Id);
        Boolean changeRecType = false;
        //oldmapchecker
        if (!oldAccountMap.isEmpty()) {
            if ((acct.RecordTypeId == SM_Constants.recordTypeIdProspectInvalid || acct.RecordTypeId == SM_Constants.recordTypeIdAdministrativeAddressInvalid) && (acct.Main_Address_Validation_Timestamp__c != Null && acct.Main_Address_Validation_Timestamp__c != oldAcc.Main_Address_Validation_Timestamp__c)) {
            	changeRecType = true;
        	}
        } else {
            if ((acct.RecordTypeId == SM_Constants.recordTypeIdProspect || acct.RecordTypeId == SM_Constants.recordTypeIdAdministrativeAddress) && (acct.Main_Address_Validation_Timestamp__c != Null)) {
            	changeRecType = true;
        	}
        }
        
        //else for new records
        return changeRecType;
        
    }
    
    public static void changeRecordTypeToValid(List<Account> newAccountList, Map<Id, Account> oldAccountMap){
        CustomLogging.push('changeRecordTypeToPropectValid', 'AccountTriggerHandler');
        try{
            List<Account> accountTobeUpdated = new List<Account>();
            for (Account a : newAccountList) {
                if (changeRT(a, oldAccountMap)){
                    accountTobeUpdated.add(a);
                }
            }
            
            if (!accountTobeUpdated.isEmpty()) {
                SM_AccountUtil.changeRecordTypeToValid(accountTobeUpdated);
            }
            
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        CustomLogging.pop(); 
    }
    
    //08.05.19 Refactor - Catherine Aragon
    private static Boolean changeAcctStatus(Account acct, Map<Id, Account> oldAccountMap) {
        Account oldAcc = oldAccountMap.get(acct.Id);
        Boolean statusChange = false;
        if ((acct.SAP_PO_Updated__c == true && acct.SAP_PO_Updated__c != oldAcc.SAP_PO_Updated__c) && (acct.Approval_Status__c == SM_Constants.ApprovalApproved && (acct.APTS_Payment_Method__c != oldAcc.APTS_Payment_Method__c || acct.Apttus_Config2__PaymentTermId__c != oldAcc.Apttus_Config2__PaymentTermId__c))){
            statusChange = true;
        }
        return statusChange;
    }
    
    public static void changeMethodTermStatus(List<Account> newAccountList, Map<Id, Account> oldAccountMap){
        CustomLogging.push('changeMethodTermStatus', 'AccountTriggerHandler');
        try{
            if (!oldAccountMap.isEmpty()) {
                List<Account> accountTobeUpdated = new List<Account>();
                for (Account a : newAccountList) {
                    if (changeAcctStatus(a, oldAccountMap)){
                        accountTobeUpdated.add(a);
                    }
                }
                
                if (!accountTobeUpdated.isEmpty()) {
                    SM_AccountUtil.changeMethodTermStatus(accountTobeUpdated);
                }
            }
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        CustomLogging.pop(); 
    }
    
    private static Boolean updateExcludeTerritory(Account acc, Map<Id, Account> oldAccountMap){
        Account oldAcc = oldAccountMap.get(acc.Id);
        Boolean territoryChanged = false;
        if (acc.Main_Address_Validation_Timestamp__c != null && acc.Main_Address_Validation_Error__c == null && acc.Exclude_from_Territory_Assignment__c == true && acc.Territory__c != oldAcc.Territory__c && UserService.recordTypeNotServiceProvider(acc)) {
           territoryChanged = true;
        }
        
        return territoryChanged;
    }
    
    public static void userAssignTerritory(List<Account> newAccountList,  Map<Id,Account> oldAccountMap){
        CustomLogging.push('userAssignTerritory', 'AccountTriggerHandler'); 
        try{
            if (!oldAccountMap.isEmpty()) {
                List<Account> accountTobeUpdated = new List<Account>();
                for(Account acc : newAccountList){
                    if (updateExcludeTerritory(acc, oldAccountMap)){
                         accountTobeUpdated.add(acc);
                    } 
                }
                
                if (!accountTobeUpdated.isEmpty()) {
                    SM_AccountUtil.userAssignTerritory(accountTobeUpdated);
                } 
            }
        } catch(Exception ex){     
            CustomLogging.debugException(ex);
            CustomLogging.pop();      
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        CustomLogging.pop(); 
    }
    
     /**
    * @author        Catherine Kia Aragon
    * @date                   
    * @description   Populate Update Address Fields after Super user validation on address
    * @revision(s)   19.01.2018 - Alvin Lomod KASM-902
    */
    private static Boolean checkFieldAddressValidation(Account acct, Map<Id,Account> oldAccountMap){
        Account oldAcc = oldAccountMap.get(acct.Id);
        Boolean addressValidation = false;
        if (acct.Address_Validation__c == 'Valid' && oldAcc.Address_Validation__c == 'Request Address Validation') {
            addressValidation = true;
        }
        return addressValidation;
    }
    
    public static void fieldAddressValidationApproved(List<Account> newAccountList, Map<Id,Account> oldAccountMap){
        CustomLogging.push('fieldAddressValidation', 'AccountTriggerHandler');
        try {
            if (!oldAccountMap.isEmpty()) {
                Set<Account> accountToUpdate = new Set<Account>();
                for (Account a : newAccountList) {
                    if(checkFieldAddressValidation(a, oldAccountMap)) {
                        accountToUpdate.add(a);
                    }
                }
                if (!accountToUpdate.isEmpty()) {
                    SM_AccountUtil.addressValidationApproved(accountToUpdate, oldAccountMap);
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
    * @author        Catherine Kia Aragon
    * @date                   
    * @description   Update Last Relevant Activity Date if account is newly created or records are updated and it was inactive.
    * @revision(s)   19.01.2018 - Alvin Lomod KASM-902
    */
    /*private static Boolean accountUpdated(Account acct, Map<Id,Account> oldAccountMap){
        Account oldAcc = oldAccountMap.get(acct.Id);
        Boolean accountEdited = false;
        if (!oldAccountMap.isEmpty()) {
            if ((acct.IsActive__c == false && oldAcc.IsActive__c == acct.IsActive__c) || (acct.Archiving_Flag__c == true && oldAcc.Archiving_Flag__c == acct.Archiving_Flag__c)) {
                accountEdited = true;
            }
        } 
        return accountEdited;
    }
    
    public static void reActivateAccount(List<Account> newAccountList, Map<Id,Account> oldAccountMap){
        CustomLogging.push('reActivateAccount', 'AccountTriggerHandler');
        try {
            if (!oldAccountMap.isEmpty()) {
                Set<Account> accountToUpdate = new Set<Account>();
                for (Account a : newAccountList) {
                    if(accountUpdated(a, oldAccountMap)) {
                        accountToUpdate.add(a);
                    }
                }
                if (!accountToUpdate.isEmpty()) {
                    SM_AccountUtil.accountReactivation(accountToUpdate);
                }
            }
        } catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        } 
        CustomLogging.pop(); 
    }*/
    
    /**
    * @author        Glenn Arman Serrano
    * @date          Jan 2 2020
    * @description   Update Account LifeCycle if account is reactivated
    */
    private static Boolean accountIsActiveFieldUpdated(Account acct, Map<Id,Account> oldAccountMap){
        Account oldAcc = oldAccountMap.get(acct.Id);
        Boolean isActiveupdated = false;
        if (!oldAccountMap.isEmpty()) {
             if (acct.IsActive__c != oldAcc.IsActive__c && (acct.RecordTypeId == SM_Constants.recordTypeIdCustomer || acct.RecordTypeId == SM_Constants.recordTypeIdEndCustomerValidation || acct.RecordTypeId == SM_Constants.recordTypeIdProspectValid ||
                                                           acct.RecordTypeId == SM_Constants.recordTypeIdAdministrativeAddress || acct.RecordTypeId == SM_Constants.recordTypeIdAdministrativeAddressValid || acct.RecordTypeId == SM_Constants.recordTypeIdAdministrativeAddressValidation)) {
                isActiveupdated = true;
            }
        } 
        return isActiveupdated;
    }
    
    public static void changeAccountLifeCycle(List<Account> newAccountList, Map<Id,Account> oldAccountMap){
        CustomLogging.push('changeAccountLifeCycle', 'AccountTriggerHandler');
        try {
            if (!oldAccountMap.isEmpty()) {
                Set<Account> accountToUpdate = new Set<Account>();
                for (Account a : newAccountList) {
                    if(accountIsActiveFieldUpdated(a, oldAccountMap)) {
                        accountToUpdate.add(a);
                    }
                }
                if (!accountToUpdate.isEmpty()) {
                    SM_AccountUtil.accountLifecyclechange(accountToUpdate);
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
    * @author        Arianne Ayusa
    * @date          Jan 3 2020
    * @description   Make updates when Archiving Flag value is set
    */    
    private static Boolean accountArchivingFlagUpdated(Account acct, Map<Id,Account> oldAccountMap){
        Account oldAcc = oldAccountMap.get(acct.Id);
        Boolean archivingFlagUpdated = false;
        if (!oldAccountMap.isEmpty()) {
            if (acct.Archiving_Flag__c != oldAcc.Archiving_Flag__c) {
                archivingFlagUpdated = true;
            }
        } 
        return archivingFlagUpdated;
    }
    
    public static void accountArchivingProcess(List<Account> newAccountList, Map<Id,Account> oldAccountMap){
        CustomLogging.push('accountArchivingProcess', 'AccountTriggerHandler');
        try {
            Set<Account> accountToUpdate = new Set<Account>();
            for (Account a : newAccountList) {
                //a.RecordTypeId == SM_Constants.recordTypeIdAdministrativeAddress || a.RecordTypeId == SM_Constants.recordTypeIdAdministrativeAddressValid || a.RecordTypeId == SM_Constants.recordTypeIdCustomer || a.RecordTypeId == SM_Constants.recordTypeIdEndCustomerValidation || a.RecordTypeId == SM_Constants.recordTypeIdAdministrativeAddressValidation || a.RecordTypeId == SM_Constants.recordTypeIdProspectInvalid || a.RecordTypeID == SM_Constants.recordTypeIdProspectValid  || a.RecordTypeId == SM_Constants.recordTypeIdPromotionRequested
                //a.RecordTypeId == SM_Constants.recordTypeIdAdministrativeAddress || a.RecordTypeId == SM_Constants.recordTypeIdAdministrativeAddressValid || a.RecordTypeId == SM_Constants.recordTypeIdCustomer || a.RecordTypeId == SM_Constants.recordTypeIdProspectInvalid || a.RecordTypeID == SM_Constants.recordTypeIdProspectValid || a.RecordTypeId == SM_Constants.recordTypeIdEndCustomerValidation || a.RecordTypeId == SM_Constants.recordTypeIdPromotionRequested || a.RecordTypeId == SM_Constants.recordTypeIdAdministrativeAddressValidation)) {
                if (!oldAccountMap.isEmpty()) {
                    if(accountArchivingFlagUpdated(a, oldAccountMap) && a.Archiving_Flag__c == true 
                       && (a.RecordTypeId == SM_Constants.recordTypeIdAdministrativeAddress || a.RecordTypeId == SM_Constants.recordTypeIdAdministrativeAddressValid || a.RecordTypeId == SM_Constants.recordTypeIdCustomer || a.RecordTypeId == SM_Constants.recordTypeIdEndCustomerValidation || a.RecordTypeId == SM_Constants.recordTypeIdAdministrativeAddressValidation  || a.RecordTypeId == SM_Constants.recordTypeIdProspectValid)) {
                           accountToUpdate.add(a);
                    } else if(accountArchivingFlagUpdated(a, oldAccountMap) && a.Archiving_Flag__c == false 
                       && (a.RecordTypeId == SM_Constants.recordTypeIdAdministrativeAddress || a.RecordTypeId == SM_Constants.recordTypeIdAdministrativeAddressValid || a.RecordTypeId == SM_Constants.recordTypeIdCustomer || a.RecordTypeId == SM_Constants.recordTypeIdEndCustomerValidation || a.RecordTypeId == SM_Constants.recordTypeIdAdministrativeAddressValidation  || a.RecordTypeId == SM_Constants.recordTypeIdProspectValid)) {
                           accountToUpdate.add(a);
                    }
                } else if (a.Archiving_Flag__c == true && (a.RecordTypeId == SM_Constants.recordTypeIdAdministrativeAddress || a.RecordTypeId == SM_Constants.recordTypeIdAdministrativeAddressValid || a.RecordTypeId == SM_Constants.recordTypeIdCustomer || a.RecordTypeId == SM_Constants.recordTypeIdEndCustomerValidation || a.RecordTypeId == SM_Constants.recordTypeIdAdministrativeAddressValidation || a.RecordTypeId == SM_Constants.recordTypeIdProspectValid)){
                    accountToUpdate.add(a);
                }
            }
            if (!accountToUpdate.isEmpty()) {
                    SM_AccountUtil.accountArchivingProcess(accountToUpdate);
            }
        } catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        } 
        CustomLogging.pop(); 
    }
    
    /*
    * @author        Arianne Ayusa
    * @date          Jan 16 2020
    * @description   Refactor of Administrative Address DMU Uncheck workflow
    */    
    public static void administrativeAddressCheck(List<Account> newAccountList){
        CustomLogging.push('administrativeAddressCheck', 'AccountTriggerHandler');
        try {
            Set<Account> accountToUpdate = new Set<Account>();
            for (Account a : newAccountList){
                if(a.RecordTypeId == SM_Constants.recordTypeIdAdministrativeAddress){
                    accountToUpdate.add(a);
                }
            }
            if (!accountToUpdate.isEmpty()) {
                    SM_AccountUtil.decisionMakingUnitUncheck(accountToUpdate);
            }
        } catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        } 
        CustomLogging.pop();
    }
    
    /*
    * @author        Glenn Serrano
    * @date          Jan 22 2020
    * @description   Refactor of Back-end Customer and Front-end Customer workflow
    */    
    private static Boolean pricingProcedurehasvalue(Account acct, Map<Id,Account> oldAccountMap){
        Account oldAcc;
        Boolean hasValue = false;
        if (!oldAccountMap.isEmpty()){
            oldAcc = oldAccountMap.get(acct.Id);
            if (acct.Mini_Customer_Pricing_Procedure__c != oldAcc.Mini_Customer_Pricing_Procedure__c){
                hasValue = true;
            }
        } else {
            if (acct.Mini_Customer_Pricing_Procedure__c != null) {
                hasValue = true;
            }
        }
        return hasValue;
    }
    
    /*
    * @author        Glenn Serrano
    * @date          Jan 22 2020
    * @description   Refactor of Back-end Customer and Front-end Customer workflow
    */    
    public static void populateBackorFrontendcustomer(List<Account> newAccountList, Map<Id,Account> oldAccountMap){
        CustomLogging.push('populateBackorFronentcustomer', 'AccountTriggerHandler');
        try {
            Set<Account> accountsforupdate = new Set<Account>(); 
            for (Account a : newAccountList){
                if (pricingProcedurehasvalue(a, oldAccountMap)){
                    accountsforupdate.add(a);
                }
            }
            
            if (!accountsforupdate.isEmpty()){
                SM_AccountUtil.populateBackorFrontendcustomer(accountsforupdate);
            }
        } catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        } 
        CustomLogging.pop();
    }
    
    /*
    * @author        Glenn Serrano
    * @date          Jan 23 2020
    * @description   Refactor of Account not Valid workflow
    */    
    public static void accountNotValid(List<Account> newAccountList, Map<Id,Account> oldAccountMap){
        CustomLogging.push('accountNotValid', 'AccountTriggerHandler');
        try {
            Set<Account> accountsforupdate = new Set<Account>(); 
            if (!oldAccountMap.isEmpty()){
                for (Account a : newAccountList){
                    Account oldaccval = oldAccountMap.get(a.Id);
                    if (a.Address_Validation__c == 'Valid' && a.RecordTypeId != SM_Constants.recordTypeIdAccountServiceProvider && (a.Main_Address_Validation_Pending__c != oldaccval.Main_Address_Validation_Pending__c || a.Main_Address_Validation_Error__c != oldaccval.Main_Address_Validation_Error__c)){
                        accountsforupdate.add(a);
                    }
                }
            }
            
            if (!accountsforupdate.isEmpty()){
                SM_AccountUtil.accountNotValid(accountsforupdate);
            }
        } catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        } 
        CustomLogging.pop();
    }
    
    /*
    * @author        Glenn Serrano
    * @date          Jan 23 2020
    * @description   Refactor of Account Valid workflow
    */    
    public static void accountValid(List<Account> newAccountList, Map<Id,Account> oldAccountMap){
        CustomLogging.push('accountValid', 'AccountTriggerHandler');
        try {
            Set<Account> accountsforupdate = new Set<Account>(); 
            for (Account a : newAccountList){
                if (!oldAccountMap.isEmpty()){
                        Account oldaccval = oldAccountMap.get(a.Id);
                        if (a.Address_Validation__c == 'Not Valid' && a.RecordTypeId != SM_Constants.recordTypeIdAccountServiceProvider && a.Main_Address_Validation_Timestamp__c != null && a.Main_Address_Validation_Error__c == null){
                            accountsforupdate.add(a);
                        }
                } else {
                    if (a.RecordTypeId != SM_Constants.recordTypeIdAccountServiceProvider && a.Main_Address_Validation_Timestamp__c != null && a.Main_Address_Validation_Error__c == null){
                            accountsforupdate.add(a);
                    }
                }
            }
            
            if (!accountsforupdate.isEmpty()){
                SM_AccountUtil.accountValid(accountsforupdate);
            }
        } catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        } 
        CustomLogging.pop();
    }

    /**
    * @author        Arianne Ayusa
    * @date          Feb 17 2020
    * @description   Refactor of Workflow that aligns Billing Address with Main Address
    */    
        
    public static void alignBillingAddressWithMainAddress(List<Account> newAccountList, Map<Id,Account> oldAccountMap){
        CustomLogging.push('alignBillingAddressWithMainAddress', 'AccountTriggerHandler');
        try {
            Set<Account> accountToUpdate = new Set<Account>();
            for (Account a : newAccountList) {
                if(a.Address_Validation__c == 'Valid'){
                    if(a.Main_Street__c != null || a.Main_Postal_Code__c != null || a.Main_City__c != null || a.Main_Country__c != null || a.Main_State__c != null || a.Main_House_Number__c != null || a.Main_Street_Only__c != null){
                        if(oldAccountMap.isEmpty()){
                            accountToUpdate.add(a);
                        } else{
                            Account oldAcc = oldAccountMap.get(a.Id);
                            if(a.Address_Validation__c != oldAcc.Address_Validation__c || a.Main_Street__c != oldAcc.Main_Street__c || a.Main_Postal_Code__c != oldAcc.Main_Postal_Code__c || a.Main_City__c != oldAcc.Main_City__c || a.Main_Country__c != oldAcc.Main_Country__c || a.Main_State__c != oldAcc.Main_State__c || a.Main_House_Number__c != oldAcc.Main_House_Number__c || a.Main_Street_Only__c != oldAcc.Main_Street_Only__c){
                                   accountToUpdate.add(a);
                               }
                        }
                    }
                }
            }
            if (!accountToUpdate.isEmpty()) {
                SM_AccountUtil.alignBillingAddressWithMainAddress(accountToUpdate);
            }
        } catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        } 
        CustomLogging.pop(); 
    }    
  
    private static Boolean SicCodeChangedorHasValue(Account acct, Map<Id,Account> oldAccountMap){
        Account oldAcc;
        Boolean SicUpdate = false;
        if (!oldAccountMap.isEmpty()){
            oldAcc = oldAccountMap.get(acct.Id);
          if (acct.Sic_Name__c != oldAcc.Sic_Name__c){
            SicUpdate = true;
          }
        } else {
          if (acct.Sic_Name__c != null) {
            SicUpdate = true;
          }
        }
        return SicUpdate;
    }
    
   /*
    * @author        Glenn Serrano
    * @date          Feb 17 2020
    * @description   Refactor of Sic Code and Sic Description workflow
    */     
    public static void populateSicCodeandSIcDescription(List<Account> newAccountList, Map<Id,Account> oldAccountMap){
        CustomLogging.push('populateSicCodeandSIcDescription', 'AccountTriggerHandler');
        try {
            Set<Account> accountsforupdate = new Set<Account>(); 
            Set<Id> jdesicmappingset = new Set<Id>();
            for (Account a : newAccountList){
                if (SicCodeChangedorHasValue(a, oldAccountMap)){
                    accountsforupdate.add(a);
                    jdesicmappingset.add(a.SIC_Name__c);
                }
            }
            
            if (!accountsforupdate.isEmpty()){
                SM_AccountUtil.populateSicCodeandSIcDescription(accountsforupdate, jdesicmappingset);
            }
        } catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        } 
        CustomLogging.pop();
    }
    
    private static Boolean adminisitrativeaddressChange(Account acct, Map<Id,Account> oldAccountMap){
        Account oldAcc;
        Boolean administrativeaddressvalidate = false;
        if (!oldAccountMap.isEmpty()){
            oldAcc = oldAccountMap.get(acct.Id);
                if (acct.RecordTypeId == SM_Constants.recordTypeIdAdministrativeAddress && acct.Main_Address_Validation_Timestamp__c != oldAcc.Main_Address_Validation_Timestamp__c && acct.Main_Address_Validation_Timestamp__c == null){
                    administrativeaddressvalidate = true;
                }
        } else {
              if (acct.RecordTypeId == SM_Constants.recordTypeIdAdministrativeAddress && acct.Main_Address_Validation_Timestamp__c == null) {
                administrativeaddressvalidate = true;
              }
        }
        return administrativeaddressvalidate;
    }
    
   /*
    * @author        Glenn Serrano
    * @date          Feb 17 2020
    * @description   Refactor of Administrative Address Account No Address Validation
    */     
    public static void administrativeaddressNoAddressValidation(List<Account> newAccountList, Map<Id,Account> oldAccountMap){
        CustomLogging.push('administrativeaddressNoAddressValidation', 'AccountTriggerHandler');
        try {
            Set<Account> accountsforupdate = new Set<Account>(); 
            for (Account a : newAccountList){
                if (adminisitrativeaddressChange(a, oldAccountMap)){
                    accountsforupdate.add(a);
                }
            }
            
            if (!accountsforupdate.isEmpty()){
                SM_AccountUtil.administrativeaddressNoAddressValidation(accountsforupdate);
            }
        } catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        } 
        CustomLogging.pop();
    }

   /*
    * @author        Catherine Aragon
    * @date          02.17.2020
    * @description   Copy Ultimate Parent Account to Ultimate Parent Account Name Search whenever ParentId has value on it was changed
    */     
    private static Boolean parentChange(Account acct, Map<Id,Account> oldAccountMap) {
        Account oldAcc;
        Boolean hasChanged = false;
        if (!oldAccountMap.isEmpty()) {
            oldAcc = oldAccountMap.get(acct.Id);
            if (acct.Ultimate_Parent_Account__c != oldAcc.Ultimate_Parent_Account__c) {
                hasChanged = true;
            }
        } else {
            if (acct.Ultimate_Parent_Account__c != Null) {
                hasChanged = true;
            }
        }
        return hasChanged;
    }
    
    public static void updateUltimateParentAccountNameSearch(List<Account> newAccList, Map<Id,Account> oldAccountMap) {
        CustomLogging.push('updateUltimateParentAccountName', 'AccountTriggerHandler');
        try{ 
            List<Account> accountToUpdate = new List<Account>();
            for (account acct : newAccList) {
                if(parentChange(acct, oldAccountMap)){
                    accountToUpdate.add(acct);
                }
            }
            
            if(!accountToUpdate.isEmpty()) {
                SM_AccountUtil.updateUtlimateParentAccountNameSearch(accountToUpdate);
            }
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        CustomLogging.pop();
    }
    
   
    /*
    * @author        Catherine Aragon
    * @date          03.13.2020
    * @description   Assign forwarding partner base on custom metadata type
    */        
    private static Boolean lspDefault(Account acct, Map<Id,Account> oldAccountMap) {
        Account oldAcc;
        Boolean isDefault = false;
        if (!oldAccountMap.isEmpty()) {
            oldAcc = oldAccountMap.get(acct.Id);
            if (acct.LSP_Forwarding_Partner__c && acct.LSP_Forwarding_Partner__c != oldAcc.LSP_Forwarding_Partner__c) {
                isDefault = true;
            }
        } else {
            if (acct.LSP_Forwarding_Partner__c) {
                isDefault = true;
            }
        }
        return isDefault;
    }
    
    public static void forwardingPartnerAssignDefault(List<Account> newAccList, Map<Id,Account> oldAccountMap) {
        CustomLogging.push('forwardingPartnerAssignDefault', 'AccountTriggerHandler');
        try{ 
            List<Account> accountToUpdate = new List<Account>();
                for (Account acct : newAccList){
                    if (lspDefault(acct, oldAccountMap)) {
                        accountToUpdate.add(acct);
                    }
                }
            
            if(!accountToUpdate.isEmpty()) {
                SM_AccountUtil.assignDefaultForwardingPartner(accountToUpdate);
            }
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        CustomLogging.pop();
    }
    
    /*
    * @author        Catherine Aragon
    * @date          03.13.2020
    * @description   Assign forwarding partner base on account owner
    */   
    private static Boolean lspNonDefault(Account acct, Map<Id,Account> oldAccountMap) {
        Account oldAcc;
        Boolean isNonDefault = false;
        if (!oldAccountMap.isEmpty()) {
            oldAcc = oldAccountMap.get(acct.Id);
            if ((!acct.LSP_Forwarding_Partner__c && acct.LSP_Forwarding_Partner__c != oldAcc.LSP_Forwarding_Partner__c) || (!acct.LSP_Forwarding_Partner__c && acct.OwnerId != oldAcc.OwnerId)) {
                isNonDefault = true;
            }
        } else {
            if (!acct.LSP_Forwarding_Partner__c) {
                isNonDefault = true;
            }
        }
        return isNonDefault;
    }
    
    public static void forwardingPartnerAssignToOwner(List<Account> newAccList, Map<Id,Account> oldAccountMap) {
        CustomLogging.push('forwardingPartnerAssignToOwner', 'AccountTriggerHandler');
        try{ 
            List<Account> accountToUpdate = new List<Account>();
            for (Account acct : newAccList){
                if (lspNonDefault(acct, oldAccountMap)) {
                    accountToUpdate.add(acct);
                }
            }
            
            if(!accountToUpdate.isEmpty()) {
                SM_AccountUtil.assignOwnerForwardingPartner(accountToUpdate);
            }
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        CustomLogging.pop();
    }

    /*
    * @author        Catherine Aragon
    * @date          03.13.2020
    * @description   Assign forwarding partner base on account owner
    */     
    
    public static void SAPforwardingParntnerDefault(List<Account> newAccList, Map<Id,Account> oldAccountMap) {
        CustomLogging.push('SAPforwardingParntnerDefault', 'AccountTriggerHandler');
        try{ 
            List<Account> accountToUpdate = new List<Account>();
            Map<String, String> defaultLSP = UserDAO.logisticPartnerInformation();
            if (!oldAccountMap.isEmpty()){
                for (Account acct : newAccList){
                    Account oldAcc = oldAccountMap.get(acct.Id);
                    if (acct.Forwarding_Partner_Number__c == defaultLSP.get(acct.Sales_Organization__c) && acct.Forwarding_Partner_Number__c != oldAcc.Forwarding_Partner_Number__c && acct.SAP_PO_Updated__c == true) {
                        accountToUpdate.add(acct);
                    }
                }
            }
            
            if(!accountToUpdate.isEmpty()) {
                SM_AccountUtil.checkForwardingPartner(accountToUpdate);
            }
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        CustomLogging.pop();
    }

    /*
    * @author        Catherine Aragon
    * @date          03.16.2020
    * @description   Concatenate the value for street with Main Street Only, Main House Number and House Number Supplement
    */   

    private static Boolean addressChanges (Account acc, Map<Id,Account> oldAccountMap) {
        Account oldAcc;
        Boolean isAddressChanges = false;
        if(!oldAccountMap.isEmpty()) {
            oldAcc = oldAccountMap.get(acc.Id);
            if((acc.Main_Street_Only__c != NULL && acc.Main_Street_Only__c != oldAcc.Main_Street_Only__c) || (acc.Main_House_Number__c != NULL && acc.Main_House_Number__c != oldAcc.Main_House_Number__c) || (acc.House_Number_Supplement__c != Null && acc.House_Number_Supplement__c != oldAcc.House_Number_Supplement__c)) {
                isAddressChanges = true;
            }
        } else {
            if(acc.Main_Street_Only__c != NULL || acc.Main_House_Number__c != NULL || acc.House_Number_Supplement__c != Null) {
                isAddressChanges = true;
            }
        }

        return isAddressChanges;
    }

    public static void streetConcatenation(List<Account> newAccList, Map<Id,Account> oldAccountMap) {
        CustomLogging.push('streetConcatenation', 'AccountTriggerHandler');
        try{ 
            List<Account> accountToUpdate = new List<Account>();
            for(Account a : newAccList) {
                if(addressChanges(a, oldAccountMap)) {
                    accountToUpdate.add(a);
                }
            }

            if(!accountToUpdate.isEmpty()) {
                SM_AccountUtil.streetValue(accountToUpdate);
            }
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        CustomLogging.pop();
    }
    
    /*
    * @author        Glenn Serrano
    * @date          03.13.2020
    * @description   removal of 4 eye principle of Duplicate process
    */ 
    
    private static Boolean duplicatereasonChange(Account acct, Map<ID, Account> oldAccountMap){
        Account oldAcc;
        Boolean hasChanged = false;
        if (!oldAccountMap.isEmpty()){
            oldAcc = oldAccountMap.get(acct.Id);
            if (acct.Duplicate_Reason__c != null && acct.Duplicate_Reason__c != oldAcc.Duplicate_Reason__c){
                hasChanged = true;
            }
        }
        else {
            if (acct.Duplicate_Reason__c != null){
                hasChanged = true;
            }
        }
        
        return hasChanged;
    }
    
    public static void changeDuplicateValidationifnotORC(List<Account> newAccList, Map<Id,Account> oldAccountMap) {
        CustomLogging.push('updateUltimateParentAccountName', 'AccountTriggerHandler');
        try{ 
            List<Account> accountToUpdate = new List<Account>();
            for (Account acct : newAccList){
                if (duplicatereasonChange(acct, oldAccountMap)){
                    accountToUpdate.add(acct);
                }
            }
                
            if(!accountToUpdate.isEmpty()) {
                SM_AccountUtil.changeDuplicateValidationifnotORC(accountToUpdate);
            }
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        CustomLogging.pop();
    }

     /*
    * @author        Catherine Aragon
    * @date          03.26.2020
    * @description   Change the RT, Account type, lifecycle, customer since date, promotion status epi field and SAP PO when return of SAP
    */ 
    public static void sapReturnAfterPromotion(List<Account> newAccList, Map<Id,Account> oldAccountMap) {
        CustomLogging.push('sapReturnAfterPromotion', 'AccountTriggerHandler');
        try{ 
            if (!oldAccountMap.isEmpty()) {
                List<Account> accountToUpdate = new List<Account>();
                for (Account acct : newAccList){
                    if (acct.SAP_PO_Updated__c == true && acct.SAP_Customer_ID__c != Null && acct.Archiving_Flag__c == false && acct.IsActive__c == true && acct.Account_Type__c == 'Prospect' && acct.Account_Lifecycle__c == 'Prospect' && acct.RecordTypeId == SM_Constants.recordTypeIdPromotionRequested){
                        accountToUpdate.add(acct);
                    }
                }
                    
                if(!accountToUpdate.isEmpty()) {
                    SM_AccountUtil.changeAfterPromotion(accountToUpdate);
                    createEpiILOG = true;
                }
            }

        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        CustomLogging.pop();
    }

    public static void sapReturnAfterIntegration(List<Account> newAccList, Map<Id,Account> oldAccountMap) {
        CustomLogging.push('sapReturnAfterIntegration', 'AccountTriggerHandler');
        try{ 
            if (!oldAccountMap.isEmpty()) {
                List<Account> accountToUpdate = new List<Account>();
                for (Account acct : newAccList){
                    if (acct.SAP_PO_Updated__c == true && acct.SAP_Customer_ID__c != Null){
                        accountToUpdate.add(acct);
                    }
                }
                    
                if(!accountToUpdate.isEmpty()) {
                    SM_AccountUtil.changeAfterIntegration(accountToUpdate);
                    createEpiILOG = true;
                }
            }

        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        CustomLogging.pop();
    }
    
    /**
    * @author        Arianne Ayusa
    * @date          April 28 2020
    * @description   Update SubSegment - INC0165917
    */    
        
    public static void checkSubSegmentChangesonCustomer(List<Account> newAccountList, Map<Id,Account> oldAccountMap){
        CustomLogging.push('checkSubSegmentChangesonCustomer', 'AccountTriggerHandler');
        try {
            for (Account a : newAccountList) {
                if(!oldAccountMap.isEmpty()){
                    Account oldAcc = oldAccountMap.get(a.Id);
                    if(a.Updated_Sub_Segment__c != null && a.SAP_PO_Updated__c == false && u.Profile.Name == SM_Constants.JDESAP){
                        a.Subsegment__c = a.Updated_Sub_Segment__c;
                        a.Updated_Sub_Segment__c = null;
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
    * @author        Glenn Serrano
    * @date          Nov 26, 2020
    * @description   DOS-2188 transfer validation rule to Apex
    */    
        
    public static void checknamechangeforpartner(List<Account> newAccountList, Map<Id,Account> oldAccountMap){
        CustomLogging.push('checknamechangeforpartner', 'AccountTriggerHandler');
        try {
            for (Account a : newAccountList) {
                if(!oldAccountMap.isEmpty()){
                    Account oldAcc = oldAccountMap.get(a.Id);
                    if(a.Name != oldacc.Name && (u.Profile.Name == 'JDE - Partner - Community User' || u.Profile.Name == 'Partner Community User')){
                       a.Name.addError('You can not change the Account name. Please request the Account owner/Channel manager to make the change via Chatter and include all details of the change');
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
    * @author        Catherine Aragon
    * @date          13.01.2021
    * @description   Whenever GTM Ingredients is updated related opportunity will be updated
    *                - opportunity that are not closed will be closed
    *                - old GTM Ingredients of account will store on partner opportunity owner on opportunity
    *                - owner of the opportunity will change to internal user based on custom metedata (Internal Assignment)
    */  
    private static void updateRelatedOpportunity(List<Account> newAccountList, Map<Id,Account> oldAccountMap){
        CustomLogging.push('updateRelatedOpportuinity', 'AccountTriggerHandler');
        try {
            List<Account> accountRec = new List<Account>();
            for (Account a : newAccountList) {
                if(!oldAccountMap.isEmpty()){
                    Account oldAcc = oldAccountMap.get(a.Id);
                    if(a.GTM_Ingredients__c != oldAcc.GTM_Ingredients__c) {
                        accountRec.add(a);
                    }
                }
            }
            if(!accountRec.isEmpty()) {
                SM_AccountUtil.updateRelOpp(accountRec, oldAccountMap);
            }
        } catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        } 
        CustomLogging.pop();
    }

    /**
    * @author        Glenn Serrano
    * @date          Jan 15, 2021
    * @description   DOS-2430 suspect machine park button
    */    
	private static Boolean machineparkvalidatechange(Account acct, Map<ID, Account> oldAccountMap){
        Account oldAcc;
        Boolean hasChanged = false;
        if (!oldAccountMap.isEmpty()){
            oldAcc = oldAccountMap.get(acct.Id);
            if (acct.Machine_Park_Validated__c == true && acct.Machine_Park_Validated__c != oldAcc.Machine_Park_Validated__c){
                hasChanged = true;
            }
        }
        else {
            if (acct.Machine_Park_Validated__c == true){
                hasChanged = true;
            }
        }
        
        return hasChanged;
    }
    
    public static void stampmachineparktimeanduser(List<Account> newAccountList, Map<Id,Account> oldAccountMap){
        CustomLogging.push('stampmachineparktimeanduser', 'AccountTriggerHandler');
        try {
            List<Account> accountToUpdate = new List<Account>();
            for (Account a : newAccountList) {
                if(machineparkvalidatechange(a, oldAccountMap)){
                    accountToUpdate.add(a);
                }
            }
            
            if (!accountToUpdate.isEmpty()){
                SM_AccountUtil.stampmachineparktimeanduser(accountToUpdate);
            }
        } catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        } 
        CustomLogging.pop(); 
    } 

    /**
    * @author        Catherine Aragon
    * @date          11-03-2021 (Format: MM/DD/YYYY)
    * @description   DOS-2654 maintain related bill-to ingredients once for related payer ingredients, related bill-to machines & services and related payer machines & services
    */    
	private static Boolean checkRelatedBillto (Account acct, Map<ID, Account> oldAccountMap){
        Account oldAcc;
        Boolean hasChanged = false;
        if (!oldAccountMap.isEmpty()){
            oldAcc = oldAccountMap.get(acct.Id);
            if (acct.Bill_To_Payer_Account__c != Null && acct.Bill_To_Payer_Account__c != oldAcc.Bill_To_Payer_Account__c){
                hasChanged = true;
            }
        }
        
        return hasChanged;
    }
    
    public static void stampRelatedBilltoandPayer (List<Account> newAccountList, Map<Id,Account> oldAccountMap){
        CustomLogging.push('stampRelatedBilltoandPayer', 'AccountTriggerHandler');
        try {
            List<Account> accountToUpdate = new List<Account>();
            for (Account a : newAccountList) {
                if(checkRelatedBillto(a, oldAccountMap)){
                    accountToUpdate.add(a);
                }
            }
            
            if (!accountToUpdate.isEmpty()){
                SM_AccountUtil.stampRelatedBilltoandPayer(accountToUpdate);
            }
        } catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        } 
        CustomLogging.pop(); 
    } 
    
    /**
    * @author        Glenn Serrano
    * @date          26-03-2021 (Format: MM/DD/YYYY)
    * @description   Bill block reason field on account not synchronizing when removing bill block reason in Salesforce
    */    
    
    private static Boolean checkAccountBlock (Account acct, Map<ID, Account> oldAccountMap){
        Account oldAcc;
        Boolean hasChanged = false;
        if (!oldAccountMap.isEmpty()){
            oldAcc = oldAccountMap.get(acct.Id);
            if (acct.Account_Block__c == false && acct.Account_Block__c != oldAcc.Account_Block__c){
                hasChanged = true;
            }
        }
        
        return hasChanged;
    }
	
    public static void billBlockReasonRemove (List<Account> newAccountList, Map<Id,Account> oldAccountMap){
        CustomLogging.push('billBlockReasonRemove', 'AccountTriggerHandler');
        try {
            List<Account> accountToUpdate = new List<Account>();       
            for (Account a : newAccountList) {
                if(checkAccountBlock(a,oldAccountMap)){
                    accountToUpdate.add(a);
                }
            }
            
            if (!accountToUpdate.isEmpty()){
                SM_AccountUtil.billBlockReasonRemove(accountToUpdate);
            }
        } catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        } 
        CustomLogging.pop(); 
    } 
    
    private static Boolean prospectaddressChange(Account acct, Map<Id,Account> oldAccountMap){
        Account oldAcc;
        Boolean prospectvalidate = false;
        if (!oldAccountMap.isEmpty()){
            oldAcc = oldAccountMap.get(acct.Id);
                if (acct.RecordTypeId == SM_Constants.recordTypeIdProspect && acct.Main_Address_Validation_Timestamp__c != oldAcc.Main_Address_Validation_Timestamp__c && acct.Main_Address_Validation_Timestamp__c == null){
                    prospectvalidate = true;
                }
        } else {
              if (acct.RecordTypeId == SM_Constants.recordTypeIdProspect && acct.Main_Address_Validation_Timestamp__c == null) {
                prospectvalidate = true;
              }
        }
        return prospectvalidate;
    }
    
   /*
    * @author        Glenn Serrano
    * @date          April 12 2021
    * @description   Refactor of Prospect Account No Address Validation
    */     
    public static void prospectNoAddressValidation(List<Account> newAccountList, Map<Id,Account> oldAccountMap){
        CustomLogging.push('prospectNoAddressValidation', 'AccountTriggerHandler');
        try {
            Set<Account> accountsforupdate = new Set<Account>(); 
            for (Account a : newAccountList){
                if (prospectaddressChange(a, oldAccountMap)){
                    accountsforupdate.add(a);
                }
            }
            
            if (!accountsforupdate.isEmpty()){
                SM_AccountUtil.prospectNoAddressValidation(accountsforupdate);
            }
        } catch(exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
        } 
        CustomLogging.pop();
    }
    
    //06.23.2020 Ultimate Parent Id Glenn Serrano
    // private static Boolean checkstampUltimateParentId(Account acct, Map<Id, Account>oldAccountMap) {
    //     Account oldAcc;
    //     Boolean stampedparentId = false;
    //     if (!oldAccountMap.isEmpty()) {
    //         oldAcc = oldAccountMap.get(acct.Id);
    //         if (acct.ParentId != oldAcc.ParentId) {
    //             stampedparentId = true;
    //         }
    //     } else {
    //         if (acct.ParentId != null) {
    //             stampedparentId = true;
    //         }
    //     }
        
    //     return stampedparentId;
    // }
    
    // public static void stampUltimateParentId(List<Account> newAccountList, Map<Id, Account>oldAccountMap) {
    //     CustomLogging.push('stampUltimateParentId', 'AccountTriggerHandler');
    //     try{
    //         List<Account> accountFiltered = new List<Account>();
    //         for (Account a : newAccountList) {
    //             if (checkstampUltimateParentId(a, oldAccountMap)){
    //                 accountFiltered.add(a);
    //             }
    //         }
            
    //         if (!accountFiltered.isEmpty()){
    //             System.debug('IM HERE MOWFOW');
    //             SM_AccountUtil.stampUltimateParentId(accountFiltered);
    //         }
            
    //     } catch(exception e){
    //         CustomLogging.debugException(e);
    //         CustomLogging.pop();      
    //         System.debug(e.getMessage() + '\n' + e.getStackTraceString());
    //     }
    //     CustomLogging.pop();
    // }
}