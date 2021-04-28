@isTest
public class SM_OptInClassFromSFTest {
    private static testMethod void nbaoptinonetoone() {
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

        List<ContactPointTypeConsent> cptcadd = new List<ContactPointTypeConsent>();
        ContactPointTypeConsent cptcvaluesforinsert = new ContactPointTypeConsent();
        cptcvaluesforinsert.Name = 'testname';
        cptcvaluesforinsert.CaptureSource = 'EPI';
        cptcvaluesforinsert.Capture_URL__c = 'source.com.ph';
        cptcvaluesforinsert.Consent_Capture_IP_Address__c = '192.168.254.254';
        cptcvaluesforinsert.CaptureDate = System.now();
        cptcvaluesforinsert.DataUsePurposeId = dup.Id;
        cptcvaluesforinsert.CaptureContactPointType = 'Email';
        cptcvaluesforinsert.Consent_Text_Version__c = '1';
        cptcvaluesforinsert.PrivacyConsentStatus = 'OptIn';
        cptcvaluesforinsert.PartyId = ind1.Id;
        cptcadd.add(cptcvaluesforinsert);

        ContactPointTypeConsent cptcvaluesforinsert1 = new ContactPointTypeConsent();
        cptcvaluesforinsert1.Name = 'testname';
        cptcvaluesforinsert1.CaptureSource = 'EPI';
        cptcvaluesforinsert1.Capture_URL__c = 'source.com.ph';
        cptcvaluesforinsert1.Consent_Capture_IP_Address__c = '192.168.254.254';
        cptcvaluesforinsert1.CaptureDate = System.now();
        cptcvaluesforinsert1.DataUsePurposeId = dup1.Id;
        cptcvaluesforinsert1.CaptureContactPointType = 'Email';
        cptcvaluesforinsert1.Consent_Text_Version__c = '1';
        cptcvaluesforinsert1.PrivacyConsentStatus = 'OptIn';
        cptcvaluesforinsert1.PartyId = ind1.Id;
        cptcadd.add(cptcvaluesforinsert1);

        ContactPointTypeConsent cptcvaluesforinsert2 = new ContactPointTypeConsent();
        cptcvaluesforinsert2.Name = 'testname';
        cptcvaluesforinsert2.CaptureSource = 'EPI';
        cptcvaluesforinsert2.Capture_URL__c = 'source.com.ph';
        cptcvaluesforinsert2.Consent_Capture_IP_Address__c = '192.168.254.254';
        cptcvaluesforinsert2.CaptureDate = System.now();
        cptcvaluesforinsert2.DataUsePurposeId = dup2.Id;
        cptcvaluesforinsert2.CaptureContactPointType = 'Email';
        cptcvaluesforinsert2.Consent_Text_Version__c = '1';
        cptcvaluesforinsert2.PrivacyConsentStatus = 'OptIn';
        cptcvaluesforinsert2.PartyId = ind1.Id;
        cptcadd.add(cptcvaluesforinsert2);
    
    
        insert cptcadd;

        Contact updateContact = [Select Id, IndividualId from Contact where Id = :con1.Id];
        updateContact.IndividualId = ind1.Id;
        update updateContact;

        List<Id> ids = new List<Id>();
        ids.add(updateContact.Id);

        SM_OptInClassFromSF.createContactPointTypeConsent(ids);
        Contact l = [Select Id, Consent_Status_Marketing__c FROM Contact WHERE Id = :updateContact.Id];
        //Assert Marketing Consent
        System.assert(l.Consent_Status_Marketing__c == 'Pending');
    }
    
}