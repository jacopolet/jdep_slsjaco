//-------------------------------------------------------------------------------------------//
// Author       :   Catherine Aragon - Accenture
// Created Date :   Feb 06 2020
// Usage        :   Class for LWC accountApproval
//-------------------------------------------------------------------------------------------//
public without sharing class RequestApproval {
    @AuraEnabled
    public static List<Id> fetchFinanceController(Id recordId) {
        List<Id> financeControllerId = new List<Id>();
        Account accountRec = new Account();
        accountRec = [Select Id, Finance_Controller_for_Account_Validatio__c, Sales_Organization__c, Account_Status__c, RecordType.Name
                        FROM Account 
                        WHERE Id = :recordId];
        Map<String,Id> financeController = ApprovalProcessService.assignFinanceController(accountRec, 'Account');
        
        if(financeController.size() > 0) {
            for (String finances : financeController.keySet()) {
                if (finances.contains('Finance Controller')) {
                    financeControllerId.add(financeController.get(finances));
                }
            }
        }
        return financeControllerId;
    }

    @AuraEnabled
    public static List<Id> fetchCustomerRelations(Id recordId) {
        List<Id> customerRelationsId = new List<Id>();
        Account accountRec = new Account();
        accountRec = [Select Id, Finance_Controller_for_Account_Validatio__c, Sales_Organization__c, Account_Status__c, RecordType.Name
                        FROM Account 
                        WHERE Id = :recordId];
        Map<String,Id> customerRelations = ApprovalProcessService.assignFinanceController(accountRec, 'Account');
        
        if(customerRelations.size() > 0) {
            for (String relations : customerRelations.keySet()) {
                if (relations.contains('Customer Relations')) {
                    customerRelationsId.add(customerRelations.get(relations));
                }
            }
        }
        return customerRelationsId;
    }

    @AuraEnabled
    public static List<Id> fetchFinanceControllerBnk(Id recordId) {
        List<Id> financeControllerId = new List<Id>();
        Bank_Details__c bankDetailRec = new Bank_Details__c();
        bankDetailRec = [Select Id, Finance_Controller_BD_Validation__c, Finance_Controller_BD_Validation_2__c, Sales_Organization__c
                        FROM Bank_Details__c
                        WHERE Id = :recordId];
        Map<String,Id> financeController = ApprovalProcessService.assignFinanceController(bankDetailRec, 'Bank_Details__c');
        
        if(financeController.size() > 0) {
            for (String finances : financeController.keySet()) {
                if (finances.contains('Finance Controller')) {
                    financeControllerId.add(financeController.get(finances));
                }
            }
        }
        return financeControllerId;
    }

    @AuraEnabled(cacheable=true)
    public static List<Bank_Details__c> getBankDetailList(Id accountId) {
        return [SELECT Name, Approval_Bank_Account__c, Approval_Bank_Country__c, Approval_Bank_Key__c, Approval_Collection_Authorization__c, Approval_Control_Key__c, Approval_IBAN__c, Updated_Request_Validation__c, LinkToRecord__c FROM Bank_Details__c WHERE Updated_Request_Validation__c = :'Approval Pending' AND Account__c = :accountId];
    }
}