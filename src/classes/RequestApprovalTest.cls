@isTest
public without sharing class RequestApprovalTest {
    static testMethod void testApprovalProcess() {
        Profile p = [SELECT Id FROM Profile WHERE Name =: SM_Constants.SystemAdmin]; 
        User u = new User(Alias = 'standt', Email='sample@testUser1.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@testUser1535324.com', Sales_Organization__c = 'SAP_0111');
        insert u;

        User u2 = new User(Alias = 'alias', Email='sample@testUser2.com', 
        EmailEncodingKey='UTF-8', LastName='aliasTest', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='aliastest@1535324.com', Sales_Organization__c = 'SAP_0111');
        insert u2;

        Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
        paymentTerm.Name = 'Sample1';
        paymentTerm.Apttus_Config2__Sequence__c = 1;
        paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
        paymentTerm.APTS_Ext_ID__c = 'asdf6';
        insert paymentTerm;

        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Archiving_Flag__c = false;
        acc.BillingStreet = 'mainstreet';
        acc.Main_House_Number__c = '123';
        acc.Main_Street_Only__c = 'streetOnly';
        acc.BillingCity = 'mainCity';
        acc.BillingState = 'state';
        acc.BillingPostalCode = 'pCode';
        acc.BillingCountry = 'country';
        acc.Main_Country_ISO__c = 'countryISO';
        acc.Language__c = 'SAP_SR';
        acc.Bill_Block_Reason__c = 'SAP_00';
        acc.Transactional_Block_Reason__c = 'SAP_00';
        acc.Delivery_Block_Reason__c = 'SAP_D3';
        acc.Apttus_Config2__PaymentTermId__c =paymentTerm.Id;
        acc.Phone = '+31302979111';
        acc.Creditworthiness_Flag__c = 'Green';
        acc.Main_Address_Validation_Pending__c = false;
        acc.Sales_Office__c = null;
        acc.Sales_Organization__c = 'SAP_0111';
        insert acc;

        /*List<Approval_Configuration__c> listAp = new List<Approval_Configuration__c>();
        Approval_Configuration__c ap1 = new Approval_Configuration__c();
        ap1.Approval_Role__c = 'Finance Controller';
        ap1.Approver__c = u.Id;
        ap1.Sales_Organization__c = 'SAP_0111';

        Approval_Configuration__c ap2 = new Approval_Configuration__c();
        ap2.Approval_Role__c = 'Customer Relations';
        ap2.Approver__c = u2.Id;
        ap2.Sales_Organization__c = 'SAP_0111';

        listAp.add(ap1);
        listAp.add(ap2);
        insert listAp;*/

        List<Id> result = RequestApproval.fetchFinanceController(acc.Id);
        List<Id> result2 = RequestApproval.fetchCustomerRelations(acc.Id);
        System.assert(result.size() > 0);
    }
    
    static testMethod void testApprovalProcessBnk() {
        Profile p = [SELECT Id FROM Profile WHERE Name =: SM_Constants.SystemAdmin]; 
        User u = new User(Alias = 'standt', Email='sample@testUser1.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@testUser1535324.com', Sales_Organization__c = 'SAP_0111');
        insert u;

        User u2 = new User(Alias = 'alias', Email='sample@testUser2.com', 
        EmailEncodingKey='UTF-8', LastName='aliasTest', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='aliastest@1535324.com', Sales_Organization__c = 'SAP_0111');
        insert u2;

        Bank_key__c bankKey = new Bank_key__c();
        bankKey.Conversion_ID__c = '234343434';
        insert bankKey;
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0111';
        acc.Phone = '+09238409384';
        insert acc;
        
        Bank_Details__c bank = new Bank_Details__c();
        bank.Bank_account__c = 'Bank acc';
        bank.Bank_country__c = 'SE';
        bank.Bank_key__c = bankKey.Id;
        bank.Collection_authorization__c = false;
        bank.Control_key__c = '21';
        bank.IBAN__c = 'IBAN';
        bank.Account__c = acc.Id;
        insert bank;

        List<Id> result = RequestApproval.fetchFinanceControllerBnk(bank.Id);
        System.assert(result.size() > 0);
    }
    
    static testMethod void testRetrieveBnk() {
        Profile p = [SELECT Id FROM Profile WHERE Name =: SM_Constants.SystemAdmin]; 
        User u = new User(Alias = 'standt', Email='sample@testUser1.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@testUser1535324.com', Sales_Organization__c = 'SAP_0111');
        insert u;

        User u2 = new User(Alias = 'alias', Email='sample@testUser2.com', 
        EmailEncodingKey='UTF-8', LastName='aliasTest', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='aliastest@1535324.com', Sales_Organization__c = 'SAP_0111');
        insert u2;

        Bank_key__c bankKey = new Bank_key__c();
        bankKey.Conversion_ID__c = '234343434';
        insert bankKey;
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Sales_Organization__c = 'SAP_0111';
        acc.Phone = '+09238409384';
        insert acc;
        
        Bank_Details__c bank = new Bank_Details__c();
        bank.Bank_account__c = 'Bank acc';
        bank.Bank_country__c = 'SE';
        bank.Bank_key__c = bankKey.Id;
        bank.Collection_authorization__c = false;
        bank.Control_key__c = '21';
        bank.IBAN__c = 'IBAN';
        bank.Account__c = acc.Id;
        bank.Updated_Request_Validation__c = 'Approval Pending';
        insert bank;

        List<Bank_Details__c> result = RequestApproval.getBankDetailList(acc.Id);
        System.assert(result.size() > 0);
    }
}