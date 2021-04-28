@isTest
public with sharing class SM_ResendEmailOrderConfirmationTest {
    private static testMethod void testResendEmailConfirmation() {
        test.startTest();

        Account acc = new Account();
        acc.Name = 'accName1';
        acc.BillingStreet = 'mainstreet1';
        acc.Main_House_Number__c = '121';
        acc.Main_Street_Only__c = 'streetOnly1';
        acc.BillingCity = 'mainCity1';
        acc.BillingState = 'state1';
        acc.BillingPostalCode = 'pCode1';
        acc.BillingCountry = 'country1';
        acc.Main_Country_ISO__c = 'countryISO1';
        acc.Language__c = 'SAP_SR';
        acc.Bill_Block_Reason__c = 'SAP_00';
        acc.Transactional_Block_Reason__c = 'SAP_00';
        acc.Delivery_Block_Reason__c = 'SAP_D3';
        acc.SAP_Customer_ID__c = '76509';
        acc.Phone = '+31302979111';      
        acc.Sales_Organization__c = 'SAP_0333';
        acc.Duplicate_Reason__c='Office building';
        acc.Being_Converted__c = true;
        insert acc;

        Contact con = new Contact();
        con.FirstName = 'Test First Badoom';
        con.LastName = 'Test Last Badaam';
        con.AccountId = acc.id;
        con.Phone = '+31302979222';
        con.Main_Service_Person__c = True;
        con.MobilePhone = '+31302979122';
        con.Sales_Organization__c = 'SAP_0111';
        con.Email ='sample989384@kdjf.cm';
        checkRecursive.run = true;   
        insert con;

        Apttus__APTS_Agreement__c agree = new Apttus__APTS_Agreement__c();
        agree.Apttus__Account__c = acc.Id;
        agree.APTS_Sold_To__c = acc.Id;
        agree.Name = 'Test Agreement';
        agree.RecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        
        insert agree;

        Apttus_Config2__Order__c oStandardOrderAgr = new Apttus_Config2__Order__c();
        oStandardOrderAgr.Apttus_CMConfig__AgreementId__c = agree.Id;
        oStandardOrderAgr.Apttus_Config2__PrimaryContactId__c = con.Id;
        oStandardOrderAgr.Apttus_Config2__SoldToAccountId__c = acc.Id;
        Database.insert(oStandardOrderAgr);

        List<Id> ids = new List<Id>();
        ids.add(oStandardOrderAgr.Id);

        SM_ResendEmailOrderConfirmation.resendOrderConfirmation(ids);

        Apttus_Config2__Order__c checkOrder = [Select Id, APTS_Order_Confirmation_Status__c FROM Apttus_Config2__Order__c WHERE Id = :oStandardOrderAgr.Id];

        System.assert(checkOrder.APTS_Order_Confirmation_Status__c == 'Resend Order Confirmation');

        test.stopTest();

    }
}