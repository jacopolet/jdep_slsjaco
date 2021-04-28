//-------------------------------------------------------------------------------------------//
// Author       :   Glenn Serrano - Accenture
// Created Date :   Dec 09 2020
// Usage        :   Apex Action Test Class
//
//-------------------------------------------------------------------------------------------//
@isTest
public class SM_GetPartnerValueTest {
	private static testMethod void actionflowTest() {
        Test.startTest();
    	
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
        acc.Language__c = 'SAP_SR';
        acc.Bill_Block_Reason__c = 'SAP_00';
        acc.Transactional_Block_Reason__c = 'SAP_00';
        acc.Delivery_Block_Reason__c = 'SAP_D3';
        acc.Phone = '+31302979111';
        acc.SAP_Customer_ID__c = '38162';
        acc.VAT_Registration_Number__c = '782908';
        acc.Main_Country_ISO__c = 'CZ';
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        insert acc;

      	List<Id> accreclist = new List<Id>();
        accreclist.add(acc.Id);
        List<Boolean> result = new List<Boolean>();
        result = SM_GetPartnerValue.SM_GetPartnerValueboolean(accreclist);
        Test.stopTest();
        System.assert(result != null);
    }
}