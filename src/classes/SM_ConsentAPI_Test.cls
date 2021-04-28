@isTest
public without sharing class SM_ConsentAPI_Test {

    static void testSetup() {
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

        TriggerSettings__c ts = new TriggerSettings__c();
        ts.ConsentTrigger__c = true;
        insert ts;

        Account acc = new Account() ;
        acc.Name = 'Test Partner Account';
        acc.Sales_Organization__c = 'SAP_0333';
        acc.Phone = '+0987654321';
        acc.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(SM_Constants.Customer).getRecordTypeId();
        acc.Main_Street_Only__c = 'Test Street';
        acc.Account_Type__c = 'Customer';
        insert acc; 

        Contact con = new Contact();
        con.FirstName = 'FirstNamePartner';
        con.LastName = 'LastNamePartner';
        con.AccountId = acc.Id;
        con.Phone = '+0987654321';
        con.Title = 'Tester';
        con.Email = 'glenn0828serrano@gmail.com';
        insert con; 
        
        Lead ld = new Lead();
        ld.Status = 'Open';
        ld.LastName = 'TestLead';
        ld.FirstName = 'TestLead';
        ld.Title = 'TestLead';
        ld.Phone = '+1234567890';
        ld.Touchpoint_Type__c = 'CAMPAIGN';
        ld.Segment__c = 'SAP_A';
        ld.Company = 'TestCompany';
        ld.Sales_Organization__c = 'SAP_0111';
        ld.OwnerId = UserInfo.getUserId();
        ld.Email = 'glennserrano0829@gmail.com';
        insert ld;
        
        Individual ind = new Individual();
        ind.FirstName = ld.FirstName;
        ind.MiddleName = ld.MiddleName;
        ind.LastName = ld.LastName;
        ind.Related_To__c = ld.Id;
        insert ind;

        Individual ind1 = new Individual();
        ind1.FirstName = con.FirstName;
        ind1.LastName = con.LastName;
        ind1.Related_To__c = con.Id;
        insert ind1;
        
        Lead updatelead = [Select Id, IndividualId from Lead where Id = :ld.Id];
        updatelead.IndividualId = ind.Id;
        update updatelead;

        Contact updatecon = [Select Id, IndividualId from Contact where Id = :con.Id];
        updatecon.IndividualId = ind1.Id;
        update updatecon;

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

        ContactPointTypeConsent cptcvaluesforinsert4 = new ContactPointTypeConsent();
        cptcvaluesforinsert4.Name = 'testname';
        cptcvaluesforinsert4.CaptureSource = 'EPI';
        cptcvaluesforinsert4.Capture_URL__c = 'source.com.ph';
        cptcvaluesforinsert4.Consent_Capture_IP_Address__c = '192.168.254.254';
        cptcvaluesforinsert4.CaptureDate = System.now();
        cptcvaluesforinsert4.DataUsePurposeId = dup.Id;
        cptcvaluesforinsert4.CaptureContactPointType = 'Email';
        cptcvaluesforinsert4.Consent_Text_Version__c = '1';
        cptcvaluesforinsert4.PrivacyConsentStatus = 'Seen';
        cptcvaluesforinsert4.PartyId = ind.Id;
        cptcadd.add(cptcvaluesforinsert4);

        ContactPointTypeConsent cptcvaluesforinsert5 = new ContactPointTypeConsent();
        cptcvaluesforinsert5.Name = 'testname';
        cptcvaluesforinsert5.CaptureSource = 'EPI';
        cptcvaluesforinsert5.Capture_URL__c = 'source.com.ph';
        cptcvaluesforinsert5.Consent_Capture_IP_Address__c = '192.168.254.254';
        cptcvaluesforinsert5.CaptureDate = System.now();
        cptcvaluesforinsert5.DataUsePurposeId = dup1.Id;
        cptcvaluesforinsert5.CaptureContactPointType = 'Email';
        cptcvaluesforinsert5.Consent_Text_Version__c = '1';
        cptcvaluesforinsert5.PrivacyConsentStatus = 'Seen';
        cptcvaluesforinsert5.PartyId = ind.Id;
        cptcadd.add(cptcvaluesforinsert5);

        ContactPointTypeConsent cptcvaluesforinsert6 = new ContactPointTypeConsent();
        cptcvaluesforinsert6.Name = 'testname';
        cptcvaluesforinsert6.CaptureSource = 'EPI';
        cptcvaluesforinsert6.Capture_URL__c = 'source.com.ph';
        cptcvaluesforinsert6.Consent_Capture_IP_Address__c = '192.168.254.254';
        cptcvaluesforinsert6.CaptureDate = System.now();
        cptcvaluesforinsert6.DataUsePurposeId = dup2.Id;
        cptcvaluesforinsert6.CaptureContactPointType = 'Email';
        cptcvaluesforinsert6.Consent_Text_Version__c = '2';
        cptcvaluesforinsert6.PrivacyConsentStatus = 'Seen';
        cptcvaluesforinsert6.PartyId = ind.Id;
        cptcadd.add(cptcvaluesforinsert6);

        insert cptcadd;
  }

	 private static testMethod void testPost3() {
        test.startTest();
        testSetup();
        String descval;
        List<Lead> leadval = [Select Id, IndividualId from Lead where Email = 'glennserrano0829@gmail.com'];
        Set<Id> ptid = new Set<Id>();
        for (Lead l : leadval){
            ptid.add(l.IndividualId);
        }
        List<ContactPointTypeConsent> cptcvalrecords = [Select Id from ContactPointTypeConsent where PartyId = :ptid];
        for (ContactPointTypeConsent cptcval : cptcvalrecords){
            if (descval == null){
                descval = '{"id": "' + cptcval.Id + '"},';
            }
            else {
                descval = descval + '{"id": "' + cptcval.Id + '"},';
            }
        }

        String jsonstring = '{"sales_organization": "SAP_6712", "requestData": {"messageId": "randomuniqueidentifier","utmcsr": "google","utmcmd": "cpc","utmccn": "test","utmcct": "test","utmctr": "test", ' +
        '"utmgclid": "Cj0KCQjwpNr4BRDYARIsAADIx9zaXmod","utmdclid": "Cj0KCQjwpNr4BRDYARIsAADIx9zaXmod","consentSource": "EPI", "sourceUrl": "www.epi.com/somespecificform","ip": "1.1.1.1", ' +
        '"datetimevalue": "2020-06-01T01:00:00","trackingcookie": "kajhsdajkshiu"},"action": "confirm","consent": [' + descval.removeEnd(',') + '],"channel": { ' +
        '"email": "glennserrano0829@gmail.com"}}';
        
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/consentapi';
        req.httpMethod = 'POST';
        req.requestBody = blob.valueOf(jsonstring);
        RestContext.request = req;
        RestContext.response= res;
        
        SM_ConsentAPI.consentapi();
        
        Lead leadrec = [Select id, Consent_Status_Marketing__c, Consent_Status_Profiling__c, Consent_Status_Surveys__c from Lead where Email = 'glennserrano0829@gmail.com']; 
        System.assert(leadrec.Consent_Status_Marketing__c == 'Opt-In');
        System.assert(leadrec.Consent_Status_Profiling__c == 'Opt-In');
        System.assert(leadrec.Consent_Status_Surveys__c == 'Opt-In');
         
        test.stopTest();
    }
    
    private static testMethod void testPost() {
        testSetup();
        String jsonstring = '{"sales_organization": "SAP_0111", "requestData": {"messageId": "randomuniqueidentifier","utmcsr": "google","utmcmd": "cpc","utmccn": "test","utmcct": "test","utmctr": "test", ' +
        '"utmgclid": "Cj0KCQjwpNr4BRDYARIsAADIx9zaXmod","utmdclid": "Cj0KCQjwpNr4BRDYARIsAADIx9zaXmod","consentSource": "EPI", "sourceUrl": "www.epi.com/somespecificform","ip": "1.1.1.1", ' +
        '"datetimevalue": "2020-06-01T01:00:00","trackingcookie": "kajhsdajkshiu"},"action": "update","consent": [{"dataUsePurpose": "marketing","privacyConsentStatus": "opt-in","captureVersion": 2 ' +
        '},{"dataUsePurpose": "survey","privacyConsentStatus": "opt-in","captureVersion": 2},{"dataUsePurpose": "profiling","privacyConsentStatus": "opt-out"}],"channel": { ' +
        '"email": "glennserrano0829@gmail.com","emailhash": "4ee81cf8fec6b89a754a182f8df94b5139c20cea6f6c84dde1234eaca0a09123"}}';
        
        test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/consentapi';
        req.httpMethod = 'POST';
        req.requestBody = blob.valueOf(jsonstring);
        RestContext.request = req;
        RestContext.response= res;
        
        SM_ConsentAPI.consentapi();
        Lead leadrec = [Select id, Consent_Status_Marketing__c, Consent_Status_Profiling__c, Consent_Status_Surveys__c from Lead where Email = 'glennserrano0829@gmail.com']; 
        System.assert(leadrec.Consent_Status_Marketing__c == 'Opt-In');
        System.assert(leadrec.Consent_Status_Profiling__c == null);	
        System.assert(leadrec.Consent_Status_Surveys__c == 'Opt-In');
        test.stopTest();
    }

    private static testMethod void testPost1() {
        
        testSetup();
        String jsonstring = '{"sales_organization": "SAP_6712", "requestData": {"messageId": "randomuniqueidentifier","utmcsr": "google","utmcmd": "cpc","utmccn": "test","utmcct": "test","utmctr": "test", ' +
        '"utmgclid": "Cj0KCQjwpNr4BRDYARIsAADIx9zaXmod","utmdclid": "Cj0KCQjwpNr4BRDYARIsAADIx9zaXmod","consentSource": "EPI1", "sourceUrl": "www.epi.com/somespecificform","ip": "1.1.1.1", ' +
        '"datetimevalue": "2020-06-01T01:00:00","trackingcookie": "kajhsdajkshiu"},"action": "update", "update","consent": [{"dataUsePurpose": "marketing","privacyConsentStatus": "opt-out" '+
        '},{"dataUsePurpose": "survey","privacyConsentStatus": "opt-out"},{"dataUsePurpose": "profiling","privacyConsentStatus": "opt-out"}],"channel": { ' +
        '"email": "glennserrano0829@gmail.com","emailhash": "4ee81cf8fec6b89a754a182f8df94b5139c20cea6f222de3707eaca00912311"}}';
        
        test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/consentapi';
        req.httpMethod = 'POST';
        req.requestBody = blob.valueOf(jsonstring);
        RestContext.request = req;
        RestContext.response= res;
        
        SM_ConsentAPI.consentapi();
        Lead leadrec = [Select id, Consent_Status_Marketing__c, Consent_Status_Profiling__c, Consent_Status_Surveys__c from Lead where Email = 'glennserrano0829@gmail.com']; 
        System.assert(leadrec.Consent_Status_Marketing__c == null);
        System.assert(leadrec.Consent_Status_Profiling__c == null);
        System.assert(leadrec.Consent_Status_Surveys__c == null);
        test.stopTest();
    }

    private static testMethod void testPost2() {
        testSetup();
        String jsonstring = '{"sales_organization": "SAP_6712", "requestData": {"messageId": "randomuniqueidentifier","utmcsr": "google","utmcmd": "cpc","utmccn": "test","utmcct": "test","utmctr": "test", ' +
        '"utmgclid": "Cj0KCQjwpNr4BRDYARIsAADIx9zaXmod","utmdclid": "Cj0KCQjwpNr4BRDYARIsAADIx9zaXmod","consentSource": "EPI", "sourceUrl": "www.epi.com/somespecificform","ip": "1.1.1.1", ' +
        '"datetimevalue": "2020-06-01T01:00:00","trackingcookie": "kajhsdajkshiu"},"action": "update","consent": [{"dataUsePurpose": "marketing","privacyConsentStatus": "opt-in","captureVersion": 2 ' +
        '},{"dataUsePurpose": "survey","privacyConsentStatus": "opt-out"},{"dataUsePurpose": "profiling","privacyConsentStatus": "opt-in","captureVersion": 2}],"channel": { ' +
        '"email": "glenn0828serrano@gmail.com","emailhash": "4ee81cf8fec6b89a754a182f8df94b5139c20cea6f6c84dde1234eaca0a09123"}}';
        
        test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/consentapi';
        req.httpMethod = 'POST';
        req.requestBody = blob.valueOf(jsonstring);
        RestContext.request = req;
        RestContext.response= res;
        
        SM_ConsentAPI.consentapi();
        Contact contactrec = [Select id, Consent_Status_Marketing__c, Consent_Status_Profiling__c, Consent_Status_Surveys__c from Contact where Email = 'glenn0828serrano@gmail.com']; 
        System.assert(contactrec.Consent_Status_Marketing__c == 'Pending');
        System.assert(contactrec.Consent_Status_Profiling__c == 'Pending');
        System.assert(contactrec.Consent_Status_Surveys__c == 'Opt-Out');
        test.stopTest();
    }

    private static testMethod void testPost4() {
        testSetup();
        String jsonstring = '{"sales_organization": "SAP_6712", "requestData": {"messageId": "randomuniqueidentifier","utmcsr": "google","utmcmd": "cpc","utmccn": "test","utmcct": "test","utmctr": "test", ' +
        '"utmgclid": "Cj0KCQjwpNr4BRDYARIsAADIx9zaXmod","utmdclid": "Cj0KCQjwpNr4BRDYARIsAADIx9zaXmod","consentSource": "EPI", "sourceUrl": "www.epi.com/somespecificform","ip": "1.1.1.1", ' +
        '"datetimevalue": "2020-06-01T01:00:00","trackingcookie": "kajhsdajkshiu"},"action": "update","consent": [{"dataUsePurpose": "marketing","privacyConsentStatus": "opt-in","captureVersion": 2 ' +
        '},{"dataUsePurpose": "survey","privacyConsentStatus": "opt-in","captureVersion": 2},{"dataUsePurpose": "profiling","privacyConsentStatus": "opt-out"}],"channel": { ' +
        '"email": "glennserrano0829@gmail.com"}}';
        
        test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/consentapi';
        req.httpMethod = 'POST';
        req.requestBody = blob.valueOf(jsonstring);
        RestContext.request = req;
        RestContext.response= res;
        
        SM_ConsentAPI.consentapi();
        Lead leadrec = [Select id, Consent_Status_Marketing__c, Consent_Status_Profiling__c, Consent_Status_Surveys__c from Lead where Email = 'glennserrano0829@gmail.com']; 
        System.assert(leadrec.Consent_Status_Marketing__c == 'Pending');
        System.assert(leadrec.Consent_Status_Profiling__c == null);
        System.assert(leadrec.Consent_Status_Surveys__c == 'Pending');
        test.stopTest();
    }
    private static testMethod void testPost5() {
        testSetup();
        String jsonstring = '{"sales_organization": "SAP_6712", "requestData": {"messageId": "randomuniqueidentifier","utmcsr": "google","utmcmd": "cpc","utmccn": "test","utmcct": "test","utmctr": "test", ' +
        '"utmgclid": "Cj0KCQjwpNr4BRDYARIsAADIx9zaXmod","utmdclid": "Cj0KCQjwpNr4BRDYARIsAADIx9zaXmod","consentSource": "EPI", "sourceUrl": "www.epi.com/somespecificform","ip": "1.1.1.1", ' +
        '"datetimevalue": "2020-06-01T01:00:00","trackingcookie": "kajhsdajkshiu"},"action": "update","consent": [{"dataUsePurpose": "marketing","privacyConsentStatus": "opt-in","captureVersion": 2 ' +
        '},{"dataUsePurpose": "survey","privacyConsentStatus": "opt-i1n","captureVersion": 2},{"dataUsePurpose": "profiling","privacyConsentStatus": "opt-out"}],"channel": { ' +
        '"email": "glennserrano0828@gmail.com"}}';
        
        test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/consentapi';
        req.httpMethod = 'POST';
        req.requestBody = blob.valueOf(jsonstring);
        RestContext.request = req;
        RestContext.response= res;
        
        SM_ConsentAPI.consentapi();
        List<Lead> leadrec = [Select id, Consent_Status_Marketing__c, Consent_Status_Profiling__c, Consent_Status_Surveys__c from Lead where Email = 'glennserrano0828@gmail.com']; 
        //for error lines 
        System.assert(leadrec.size() == 0);
        test.stopTest();
    }
    private static testMethod void testPost6() {
        testSetup();
        String jsonstring = '{"sales_organization": "SAP_0111", "requestData": {"messageId": "randomuniqueidentifier","utmcsr": "google","utmcmd": "cpc","utmccn": "test","utmcct": "test","utmctr": "test", ' +
        '"utmgclid": "Cj0KCQjwpNr4BRDYARIsAADIx9zaXmod","utmdclid": "Cj0KCQjwpNr4BRDYARIsAADIx9zaXmod","consentSource": "EPI", "sourceUrl": "www.epi.com/somespecificform","ip": "1.1.1.1", ' +
        '"datetimevalue": "2020-06-01T01:00:00","trackingcookie": "kajhsdajkshiu"},"action": "update","consent": [{"dataUsePurpose": "marketing","privacyConsentStatus": "opt-out" ' +
        '},{"dataUsePurpose": "survey","privacyConsentStatus": "opt-out"},{"dataUsePurpose": "profiling","privacyConsentStatus": "opt-out"}],"channel": { ' +
        '"email": "glennserrano0829@gmail.com"}}';
        
        test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/consentapi';
        req.httpMethod = 'POST';
        req.requestBody = blob.valueOf(jsonstring);
        RestContext.request = req;
        RestContext.response= res;
        
        SM_ConsentAPI.consentapi();
        Lead leadrec = [Select id, Consent_Status_Marketing__c, Consent_Status_Profiling__c, Consent_Status_Surveys__c from Lead where Email = 'glennserrano0829@gmail.com']; 
        System.assert(leadrec.Consent_Status_Marketing__c == null);
        System.assert(leadrec.Consent_Status_Profiling__c == null);
        System.assert(leadrec.Consent_Status_Surveys__c == null);
        test.stopTest();
    }
    
    private static testMethod void testPost7() {
        testSetup();
        String jsonstring = '{"sales_organization": "SAP_0111", "requestData": {"messageId": "randomuniqueidentifier","utmcsr": "google","utmcmd": "cpc","utmccn": "test","utmcct": "test","utmctr": "test", ' +
        '"utmgclid": "Cj0KCQjwpNr4BRDYARIsAADIx9zaXmod","utmdclid": "Cj0KCQjwpNr4BRDYARIsAADIx9zaXmod","consentSource": "EPI", "sourceUrl": "www.epi.com/somespecificform","ip": "1.1.1.1", ' +
        '"datetimevalue": "2020-06-01T01:00:00","trackingcookie": "kajhsdajkshiu"},"action": "update","consent": [{"dataUsePurpose": "marketing","privacyConsentStatus": "opt-out" ' +
        '},{"dataUsePurpose": "survey","privacyConsentStatus": "opt-out"},{"dataUsePurpose": "profiling","privacyConsentStatus": "opt-out"}],"channel": { ' +
        '"email": "glennserrano0828@gmail.com"}}';
        
        test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/consentapi';
        req.httpMethod = 'POST';
        req.requestBody = blob.valueOf(jsonstring);
        RestContext.request = req;
        RestContext.response= res;
        
        SM_ConsentAPI.consentapi();
        Contact contactrec = [Select id, Consent_Status_Marketing__c, Consent_Status_Profiling__c, Consent_Status_Surveys__c from Contact where Email = 'glenn0828serrano@gmail.com']; 
        System.assert(contactrec.Consent_Status_Marketing__c == null);
        System.assert(contactrec.Consent_Status_Profiling__c == null);
        System.assert(contactrec.Consent_Status_Surveys__c == null);
        test.stopTest();
    }
    
   private static testMethod void testPost8() {
        testSetup();
        String jsonstring = '{"sales_organization": "SAP_0111", "requestData": {"messageId": "randomuniqueidentifier","utmcsr": "google","utmcmd": "cpc","utmccn": "test","utmcct": "test","utmctr": "test", ' +
        '"utmgclid": "Cj0KCQjwpNr4BRDYARIsAADIx9zaXmod","utmdclid": "Cj0KCQjwpNr4BRDYARIsAADIx9zaXmod","consentSource": "EPI", "sourceUrl": "www.epi.com/somespecificform","ip": "1.1.1.1", ' +
        '"datetimevalue": "2020-06-01T01:00:00","trackingcookie": "kajhsdajkshiu"},"action": "update","consent": [{"dataUsePurpose": "marketing","privacyConsentStatus": "opt-in","captureVersion": 2 ' +
        '},{"dataUsePurpose": "survey","privacyConsentStatus": "opt-out"},{"dataUsePurpose": "profiling","privacyConsentStatus": "opt-in","captureVersion": 2}],"channel": { ' +
        '"email": "glenn0828serrano@gmail.com","emailhash": "4ee81cf8fec6b89a754a182f8df94b5139c20cea6f6c84dde1234eaca0a09123"}}';
        
        test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/consentapi';
        req.httpMethod = 'POST';
        req.requestBody = blob.valueOf(jsonstring);
        RestContext.request = req;
        RestContext.response= res;
        
        SM_ConsentAPI.consentapi();
        Contact contactrec = [Select id, Consent_Status_Marketing__c, Consent_Status_Profiling__c, Consent_Status_Surveys__c from Contact where Email = 'glenn0828serrano@gmail.com']; 
        System.assert(contactrec.Consent_Status_Marketing__c == 'Opt-In');
        System.assert(contactrec.Consent_Status_Profiling__c == 'Opt-In');
        System.assert(contactrec.Consent_Status_Surveys__c == 'Opt-Out');
        test.stopTest();
    }

}