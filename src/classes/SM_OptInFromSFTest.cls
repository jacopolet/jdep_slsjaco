@isTest
public without sharing class SM_OptInFromSFTest {
	private static testMethod void optinContact() {

        List<DataUsePurpose> duplist = new List<DataUsePurpose>();
        DataUsePurpose dup = new DataUsePurpose();
        dup.Name = 'marketing';
        duplist.add(dup);
        
        DataUsePurpose dup1 = new DataUsePurpose();
        dup1.Name = 'survey';
        duplist.add(dup1);
        
        DataUsePurpose dup2 = new DataUsePurpose();
        dup2.Name = 'profiling';
        duplist.add(dup2);
       
        insert duplist;
        
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

        Individual ind1 = new Individual();
        ind1.FirstName = con1.FirstName;
        ind1.LastName = con1.LastName;
        ind1.Related_To__c = con1.Id;
        insert ind1;

        Contact updateContact = [Select Id, IndividualId from Contact where Id = :con1.Id];
        updateContact.IndividualId = ind1.Id;
        update updateContact;

        List<String> ids = new List<String>();
        ids.add(updateContact.Id);
        
        SM_OptInFromSF.generateOptIns generateoptinrec = new  SM_OptInFromSF.generateOptIns();
        generateoptinrec.contactid = updateContact.Id;
        List<SM_OptInFromSF.generateOptIns> goptin = new List<SM_OptInFromSF.generateOptIns>();
        goptin.add(generateoptinrec);
        
        SM_OptInFromSF.generateRecommendationforContact(goptin);
        Contact l = [Select Id, Consent_Status_Marketing__c FROM Contact WHERE Id = :updateContact.Id];
        System.assert(l.Consent_Status_Marketing__c == null);
    }
}