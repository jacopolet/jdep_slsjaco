//-------------------------------------------------------------------------------------------
// Author       :   Catherine Aragon - Accenture
// Created Date :   May 12, 2020
// Usage        :   Test Class forSM_CollarWfoDistributionClass
//-------------------------------------------------------------------------------------------
@isTest
public class SM_CollarWfoDistributionClass_Test {
    private static testMethod void testDefault() {
        Id p = [SELECT Id FROM Profile WHERE Name = :SM_Constants.SystemAdmin].id;
                  
        User u = new User(alias = 'test123', email='test123@noemail.com',
                emailencodingkey='UTF-8', lastname='LastNamePartner', firstName = 'FirstNamePartner', languagelocalekey='en_US',
                localesidkey='en_US', profileid = p, country='United States',IsActive =true, Sales_Organization__c = 'SAP_0333',
                timezonesidkey='America/Los_Angeles', username='tester@notemail.com');
       
        insert u;
        
        System.runAs(u) {
            Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
            paymentTerm.Name = 'Sample';
            paymentTerm.Apttus_Config2__Sequence__c = 1;
            paymentTerm.APTS_Sales_Org__c = 'SAP_0333';
            paymentTerm.APTS_Ext_ID__c = 'asdfsadfsadfdsfasdf1';
            insert paymentTerm;
            
            Mini_Template__c mt = new Mini_Template__c();
            mt.Name = 'SAP_0333';
            mt.Mini_Sales_Organization__c ='SAP_0333';
            mt.Mini_Currency__c = 'EUR';
            mt.Mini_Terms_of_payment__c = 'asdfsadfsadfdsfasdf1';
            insert mt;
            
            MiniTemplateTax__c mtt = new MiniTemplateTax__c();
            mtt.Name = 'SAP-0033 -1';
            mtt.Sales_Organization__c = 'SAP_0333';
            insert mtt;
            
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
            
            SM_CollarWfoDistributionClass.saveCollarAndWfoPercentage(acc.Id, 40, 60);
            Account accrecord = [Select Id, Blue_Collar__c, White_Collar__c, Work_from_office__c, Work_from_home__c FROM Account WHERE Id = :acc.Id];
            System.assertEquals(accrecord.Blue_Collar__c, 40);
            System.assertEquals(accrecord.White_Collar__c, 60);
            System.assertEquals(accrecord.Work_from_home__c, 40);
            System.assertEquals(accrecord.Work_from_office__c, 60);
         
        }
    }

}