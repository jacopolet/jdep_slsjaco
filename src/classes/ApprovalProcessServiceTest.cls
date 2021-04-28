@isTest
public with sharing class ApprovalProcessServiceTest {
    static testMethod void testGetFinanceContorller() {
        Profile p = [SELECT Id FROM Profile WHERE Name =: SM_Constants.SystemAdmin]; 
        User u = new User(Alias = 'standt', Email='sample@testUser1.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@testUser1535324.com', Sales_Organization__c = 'SAP_0111', Finance_Controller_Approver__c = true);
        insert u;

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
        acc.Finance_Controller_for_Account_Validatio__c = u.Id;
        acc.Finance_Controller_2__c = u.Id;
        acc.Customer_Relations_Approval_1__c = u.Id;
        acc.Customer_Relations_Approval_2__c = u.Id;
        //acc.Customer_Relations_Approval_3__c = u.Id;
        acc.Approval_Pending_Commercial_Register_No__c = '89493';
        acc.Approval_Status__c = 'Approval Pending';
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        insert acc;

        /*List<Approval_Configuration__c> listAp = new List<Approval_Configuration__c>();
        Approval_Configuration__c ap1 = new Approval_Configuration__c();
        ap1.Approval_Role__c = 'Finance Controller';
        ap1.Approver__c = u.Id;
        ap1.Sales_Organization__c = 'SAP_0111';

        listAp.add(ap1);
        insert listAp;*/

        Id recordTypeId = ApprovalProcessService.accountRecordType();
        Map<String,Id> result = ApprovalProcessService.assignFinanceController(acc, 'Account');
        System.assert(result != Null);

        ApprovalProcessService.submitApproval(acc.Id);
    }
    
    static testMethod void testGetFinanceContorllerBnk() {
        Profile p = [SELECT Id FROM Profile WHERE Name =: SM_Constants.SystemAdmin]; 
        User u = new User(Alias = 'standt', Email='sample@testUser1.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@testUser1535324.com', Sales_Organization__c = 'SAP_0111', Finance_Controller_Approver__c = true);
        insert u;

        Bank_key__c bankKey = new Bank_key__c();
        bankKey.Conversion_ID__c = '234343434';
        insert bankKey;
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        acc.Account_Status__c = 'Valid';
        acc.Main_City__c = 'Netherlands';
        acc.Main_Postal_Code__c = '1500';
        acc.Main_State__c = 'Amsterdam';
        acc.Archiving_Flag__c = False;
        acc.Main_Country__c = 'Netherlands';
        acc.Sales_Organization__c = 'SAP_0111';
        acc.Duplicate_Reason__c = '';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+09238409384';
        insert acc;
        
        Bank_Details__c bank = new Bank_Details__c();
        bank.Bank_account__c = 'Update Bank acc';
        bank.Bank_country__c = 'SE';
        bank.Bank_key__c = bankKey.Id;
        bank.Collection_authorization__c = false;
        bank.Control_key__c = '21';
        bank.IBAN__c = 'IBAN';
        bank.Account__c = acc.Id;
        insert bank;

        Map<String,Id> result = ApprovalProcessService.assignFinanceController(acc, 'Bank_Details__c');
        System.assert(result != Null);
    }

}