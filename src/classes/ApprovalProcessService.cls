//-------------------------------------------------------------------------------------------//
// Author       :   Catherine Aragon - Accenture
// Created Date :   Jan 23 2020
// Usage        :   Service class for Approval process
//-------------------------------------------------------------------------------------------//
public without sharing class ApprovalProcessService {
    @AuraEnabled
    public static Id accountRecordType (){
        Id accountRTId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Validation').getRecordTypeId();
        return accountRTId;
    }

    public static Map<String, Id> assignFinanceController(sObject record, String sObjectString) {
        Map<String, Id> financeController = new Map<String, Id>();
        
        if (sObjectString != null) {
            //RETRIVE ALL FIELDS FROM DEFINED SOBJECT - PARAMETER
            Map<String, Schema.SObjectField> fields_sObjMap = UserDAO.sOjectFields(sObjectString);
                    
            //INSTANTIATE BASED ON THE SOBJECT            
            SObject obj_var;
            String salesOrg;
            if(fields_sObjMap.containsKey('Sales_Organization__c') && fields_sObjMap.containsKey('Id')){
                obj_var = (SObject) (Type.forName('Schema.'+ sObjectString).newInstance());
                obj_var.put('Id', record.Id);
                //obj_var.put('Sales_Organization__c', record.get('Sales_Organization__c'));
                salesOrg = (String) record.get('Sales_Organization__c');
            }     

            System.debug('here: ' + obj_var);
            System.debug('here2: ' + salesOrg);            

            if (salesOrg != Null) {
                Id currentUser = UserInfo.getUserId();
                Account accountRec = new Account();
                Account_Tax__c accountTax = new Account_Tax__c();
                Bank_Details__c bankDetailRec = new Bank_Details__c();
                List<Approval_Configurations__mdt> approvers = new List<Approval_Configurations__mdt>();
                approvers = [Select Id, Approver__c, Sales_Organization__c, Approver_Manager__c, Approval_Role__c FROM Approval_Configurations__mdt WHERE Sales_Organization__c = :salesOrg];
                if (!approvers.isEmpty()) {
                    if (sObjectString == 'Account') {
                        accountRec = (Account) obj_var;
                        for (Approval_Configurations__mdt a : approvers) {
                            if (currentUser == a.Approver__c && a.Approver_Manager__c != Null) {
                                financeController.put(a.Approval_Role__c + ' ' + accountRec.Id + ' ' + a.Approver_Manager__c, a.Approver_Manager__c);
                            } else {
                                financeController.put(a.Approval_Role__c + ' ' + accountRec.Id + ' ' + a.Approver__c, a.Approver__c);
                            }
                        }
                        
                    } else if (sObjectString == 'Bank_Details__c') {
                        bankDetailRec = (Bank_Details__c) obj_var;
                        for (Approval_Configurations__mdt a : approvers) {
                            if (currentUser == a.Approver__c && a.Approver_Manager__c != Null) {
                                financeController.put(a.Approval_Role__c + ' ' + bankDetailRec.Id + ' ' + a.Approver_Manager__c, a.Approver_Manager__c);
                            } else {
                                financeController.put(a.Approval_Role__c + ' ' + bankDetailRec.Id + ' ' + a.Approver__c, a.Approver__c);
                            }
                        }
                    }/*else if (sObjectString == 'Account_Tax__c') {
                        accountTax = (Account_Tax__c) obj_var;
                        if (currentUser == salesOrgUser.get(accountTax.Id).Id && salesOrgUser.get(accountTax.Id).ManagerId != Null) {
                            financeController.put(accountTax.Id, salesOrgUser.get(accountTax.Sales_Organization__c).ManagerId);
                        } else {
                            financeController.put(accountTax.Id, salesOrgUser.get(accountTax.Sales_Organization__c).Id);
                        }
                   
                    }*/
                }
            }
        }
        return financeController;
    }

    @AuraEnabled
    public static Boolean submitApproval(Id recordId) {
        Boolean isSuccess = false;
        if (recordId != Null ) {
            // Create an approval request for the sObject
            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
            req1.setObjectId(recordId);

            // Submit the approval request for the sObject
            Approval.ProcessResult result = Approval.process(req1);
            unlockApproval(recordId);
            isSuccess = true;
        }
        return isSuccess;
    }

    public static void unlockApproval(Id accId){
        CustomLogging.push('unlockApproval', 'ApprovalProcessService');
        try {
            if(Approval.isLocked(accId)){
                Approval.UnlockResult urList = Approval.unlock(accId);          
            }

        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
    }
}