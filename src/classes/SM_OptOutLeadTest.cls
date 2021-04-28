@isTest
private without sharing class SM_OptOutLeadTest {
    private static testMethod void optoutLead() {

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
        
        Lead lead1 = new Lead();
        
        lead1.FirstName = 'Jed';
        lead1.LastName = 'Samaniego';
        lead1.Phone = '+31302979111';
        lead1.Email = 'test123@gmail.com';
        lead1.Company = 'Kead123123123';
        lead1.Sales_Organization__c = 'SAP_0111';
        lead1.Consent_Status_Marketing__c = 'Opt-In';
        lead1.Consent_Status_Profiling__c = 'Opt-In';
        lead1.Consent_Status_Surveys__c = 'Opt-In';
                
        insert lead1;

        Individual ind1 = new Individual();
        ind1.FirstName = lead1.FirstName;
        ind1.LastName = lead1.LastName;
        ind1.Related_To__c = lead1.Id;
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

        Lead updateLead = [Select Id, IndividualId from Lead where Id = :lead1.Id];
        updateLead.IndividualId = ind1.Id;
        update updateLead;

        List<Id> ids = new List<Id>();
        ids.add(updateLead.Id);

        SM_OptOutLead.optoutLead(ids);
        Lead l = [Select Id, Consent_Status_Marketing__c FROM Lead WHERE Id = :updateLead.Id];
        //Assert the name field and saved expense
        System.assert(l.Consent_Status_Marketing__c == 'Opt-Out');
    }
}