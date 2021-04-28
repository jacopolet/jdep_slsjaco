@isTest
private without sharing class SM_ArchiveContact_Test {
    private static testMethod void archiveContact() {
        Profile p = [SELECT Id FROM Profile WHERE Name =: SM_Constants.SystemAdmin]; 
        User u = new User(Alias = 'standt', Email='ample@testUser.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',  
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@ksdjflskje.com', Sales_Organization__c = 'SAP_0111');
        
        System.runAs(u) {
            //Create account record
            Account acc = new Account();
            acc.Name = 'Test Account';
            acc.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.Customer).getRecordTypeId();
            acc.Main_Street_Only__c = 'Test Street';
            acc.Main_Postal_Code__c = null;
            acc.Industry_Code__c = null;
            acc.Phone = '+1234567890';
            acc.CurrencyIsoCode = 'EUR';
            acc.Language__c = 'SAP_EN';
            acc.Sales_Organization__c = 'SAP_0333';
            acc.Account_Type__c = 'Customer';
            acc.Segment__c = 'SAP_A';
            acc.of_Beds__c = 10;
            acc.of_drinks__c = 10;
            acc.of_Employees_FTE__c = 10;
            acc.Exclude_from_Territory_Assignment__c = false;
            acc.of_Seats__c = 10;
            acc.Account_Lifecycle__c = 'Active Customer';
            acc.SAP_PO_Updated__c = false;
            
            insert acc;
    
            Contact con1 = new Contact();
            Con1.FirstName = 'Test First Badoom';
            Con1.LastName = 'Test Last Badaam';
            Con1.AccountId = acc.id;
            Con1.Phone = '+31302979222';
            Con1.Main_Service_Person__c = True;
            Con1.MobilePhone = '+31302979122';
            Con1.Sales_Organization__c = 'SAP_0111'; 
            insert con1;
    
            List<Id> ids = new List<Id>();
            ids.add(con1.Id);
    
            SM_ArchiveContact.archiveContact(ids);
            Contact c = [Select Id, Archiving_Flag__c FROM Contact WHERE Id = :con1.Id];
            //Assert the name field and saved expense
            System.assert(c.Archiving_Flag__c == true);
        }
    }
}