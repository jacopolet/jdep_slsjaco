@isTest
private without sharing class SM_OptOutTest {
    private static testMethod void optoutContact() {

        //insert custom settings
        TriggerSettings__c ts = new TriggerSettings__c();
        ts.ConsentTrigger__c = true;
        insert ts;

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
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        Contact con1 = new Contact();
        
        Con1.FirstName = 'Jed';
        Con1.LastName = 'Samaniego';
        Con1.AccountId = acc.id;
        Con1.Phone = '+31302979111';
        Con1.Email = 'test123@gmail.com';
        Con1.Main_Commercial_Person__c = True;
        Con1.MobilePhone = '+31302979122';
        Con1.Sales_Organization__c = 'SAP_0111';
        Con1.Consent_Status_Marketing__c = 'Opt-In';
        Con1.Consent_Status_Profiling__c = 'Opt-In';
        Con1.Consent_Status_Surveys__c = 'Opt-In';
        Con1.Archiving_Flag__c = False;
        Con1.Contact_Status__c = 'Valid';
                
        insert Con1;

        Individual ind1 = new Individual();
        ind1.FirstName = Con1.FirstName;
        ind1.LastName = Con1.LastName;
        ind1.Related_To__c = Con1.Id;
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

        Contact updatecon = [Select Id, IndividualId from Contact where Id = :Con1.Id];
        updatecon.IndividualId = ind1.Id;
        update updatecon;

        List<Id> ids = new List<Id>();
        ids.add(updatecon.Id);

        SM_OptOut.optoutContact(ids);
        Contact c = [Select Id, Consent_Status_Marketing__c FROM Contact WHERE Id = :updatecon.Id];
        //Assert the name field and saved expense
        System.assert(c.Consent_Status_Marketing__c == 'Opt-Out');
    }
}