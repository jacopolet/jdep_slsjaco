@isTest
public without sharing class SM_FormAPI_Test {

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
        ts.SM_FormAPImethod__c = true;
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
        con.Email_SHA256__c = '6712A285E72F492E1B767E6A61E10BA9B6C65713D8E46087580E62E3224E3F4B';
        insert con; 
        
        Contact con1 = new Contact();
        con1.FirstName = 'FirstasdfNamePartner';
        con1.LastName = 'LastNamePartner';
        con1.AccountId = acc.Id;
        con1.Phone = '+09876254321';
        con1.Title = 'Tester';
        con1.Email = 'glenn0830serrano@gmail.com';
        insert con1; 
        
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
        
        Individual ind2 = new Individual();
        ind2.FirstName = con.FirstName;
        ind2.LastName = con.LastName;
        ind2.Related_To__c = con1.Id;
        insert ind2;
        
        Lead updatelead = [Select Id, IndividualId from Lead where Id = :ld.Id];
        updatelead.IndividualId = ind.Id;
        update updatelead;

        Contact updatecon = [Select Id, IndividualId from Contact where Id = :con.Id];
        updatecon.IndividualId = ind1.Id;
        update updatecon;
        
        Contact updatecon1 = [Select Id, IndividualId from Contact where Id = :con1.Id];
        updatecon1.IndividualId = ind2.Id;
        update updatecon1;

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
		
        ContactPointTypeConsent cptcvaluesforinsert3 = new ContactPointTypeConsent();
        cptcvaluesforinsert3.Name = 'testname';
        cptcvaluesforinsert3.CaptureSource = 'EPI';
        cptcvaluesforinsert3.Capture_URL__c = 'source.com.ph';
        cptcvaluesforinsert3.Consent_Capture_IP_Address__c = '192.168.254.254';
        cptcvaluesforinsert3.CaptureDate = System.now();
        cptcvaluesforinsert3.DataUsePurposeId = dup2.Id;
        cptcvaluesforinsert3.CaptureContactPointType = 'Email';
        cptcvaluesforinsert3.Consent_Text_Version__c = '1';
        cptcvaluesforinsert3.PrivacyConsentStatus = 'OptIn';
        cptcvaluesforinsert3.PartyId = ind2.Id;
        cptcadd.add(cptcvaluesforinsert3);
        
        insert cptcadd;
        
        PhysicalAsset__c pa2 = new PhysicalAsset__c(Name='Test2', 
                                   UniqueNumber__c='1234567-TestMachine2',
                                   SerialNumber__c = '123454',
                                   RecordTypeId = SM_Constants.recordTypeIdMachine);
        insert pa2;
	}

    private static testMethod void testPost() {
        testSetup();
        Campaign camprec = new Campaign();
        camprec.Name = 'Test me';
        
        insert camprec;
        
		String jsonstring = '{"sales_organization": "SAP_0111", "requestData": {"messageId": "randomuniqueidentifier","utmcsr": "google","utmcmd": "cpc","utmccn": "test","utmcct": "test","utmctr": "test", ' +
        '"utmgclid": "Cj0KCQjwpNr4BRDYARIsAADIx9zaXmod","utmdclid": "Cj0KCQjwpNr4BRDYARIsAADIx9zaXmod","consentSource": "EPI", "sourceUrl": "www.epi.com/somespecificform","ip": "1.1.1.1", ' +
        '"datetimevalue": "2020-06-01T01:00:00","trackingcookie": "kajhsdajkshiu"},"consent": [{"dataUsePurpose": "marketing","privacyConsentStatus": "opt-in","captureVersion": 1 ' +
        '},{"dataUsePurpose": "survey","privacyConsentStatus": "opt-in","captureVersion": 1},{"dataUsePurpose": "profiling","privacyConsentStatus": "opt-out"}],"channel": { ' +
        '"email": "glenn.a.h.serrano09123123@accenture.com"},"individual": {"lastname": "Gl09123enn","firstname": "Ser091239rano", ' +
        '"salutation": "mrs","middleName": "Her091239123ico","company": "Sern0192309123jpo","phone": "+63912312312","postalCode": "1000SJ","country": "Netherlands","city": "Amsterdam","houseNumber": "99", ' +
        '"street": "Hoofdstraat","state": "Zuid-Holland","title": "Buyer","language": "NL","subject": "Online information request","coffeemachinecode": "BaristaOne" },"details": { ' +
        '"touchpointType": "Online Quote Request MC","leadSource": "EPI" ,"campaignId": "' + camprec.Id +'"},"customFields": [{ "name": "definedonthefly1", "value": "michael" },{ "name":"differentthistime", "value": 1 },{ "name": "additionalfield", "value": true }]}';
        
        test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/formapi';
        req.httpMethod = 'POST';
        req.requestBody = blob.valueOf(jsonstring);
        RestContext.request = req;
        RestContext.response= res;
        
        SM_FormAPI.formapi();
        List<Lead> leadrec = [Select id, Consent_Status_Marketing__c, Consent_Status_Profiling__c, Consent_Status_Surveys__c from Lead where Email = 'glenn.a.h.serrano09123123@accenture.com']; 
        //language is wrong so Lead is not created
        System.assert(leadrec.size() == 0);
        test.stopTest();
    }

    private static testMethod void testPost1() {
        test.startTest();
        testSetup();
		String jsonstring = '{"sales_organization": "SAP_6712", "requestData": {"messageId": "randomuniqueidentifier","utmcsr": "google","utmcmd": "cpc","utmccn": "test","utmcct": "test","utmctr": "test", ' +
        '"utmgclid": "Cj0KCQjwpNr4BRDYARIsAADIx9zaXmod","utmdclid": "Cj0KCQjwpNr4BRDYARIsAADIx9zaXmod","consentSource": "EPI", "sourceUrl": "www.epi.com/somespecificform","ip": "1.1.1.1", ' +
        '"datetimevalue": "2020-06-01T01:00:00","trackingcookie": "kajhsdajkshiu"},"consent": [{"dataUsePurpose": "marketing","privacyConsentStatus": "opt-in","captureVersion": 1 ' +
        '},{"dataUsePurpose": "survey","privacyConsentStatus": "opt-in","captureVersion": 1},{"dataUsePurpose": "profiling","privacyConsentStatus": "opt-out"}],"channel": { ' +
        '"email": "glennserrano0829@gmail.com","emailhash": "4ee81cf8fec6b89a754a182f8df94b5139c20cea6f6c84dde3707eaca00912311"},"individual": {"lastname": "Gl09123enn","firstname": "Ser091239rano", ' +
        '"salutation": "mrs","middleName": "Her091239123ico","company": "Sern0192309123jpo","phone": "+63912312312","postalCode": "1000SJ","country": "Netherlands","city": "Amsterdam","houseNumber": "99", ' +
        '"street": "Hoofdstraat","state": "Zuid-Holland","title": "Buyer","language": "SAP_NL","subject": "Online information request","coffeemachinecode": "BaristaOne" },"details": { ' +
        '"touchpointType": "Online Quote Request MC","leadSource": "EPI" },"customFields": [{ "name": "definedonthefly1", "value": "michael" },{ "name":"differentthistime", "value": 1 },{ "name": "additionalfield", "value": true }]}';
        
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/formapi';
        req.httpMethod = 'POST';
        req.requestBody = blob.valueOf(jsonstring);
        RestContext.request = req;
        RestContext.response= res;
        
        SM_FormAPI.formapi();
        Lead leadrec = [Select id, Consent_Status_Marketing__c, Consent_Status_Profiling__c, Consent_Status_Surveys__c from Lead where Email = 'glennserrano0829@gmail.com']; 
        //Double Opt In  Market Opt in and Opt out process on consent LEAD
        System.assert(leadrec.Consent_Status_Marketing__c == 'Pending');
        System.assert(leadrec.Consent_Status_Profiling__c == 'Opt-Out');
        System.assert(leadrec.Consent_Status_Surveys__c == 'Pending');
        test.stopTest();
    }

    private static testMethod void testPost2() {
        
        testSetup();
        Campaign camprec = new Campaign();
        camprec.Name = 'Test me';
        
        insert camprec;
		String jsonstring = '{"sales_organization": "SAP_6712", "requestData": {"messageId": "randomuniqueidentifier","utmcsr": "google","utmcmd": "cpc","utmccn": "test","utmcct": "test","utmctr": "test", ' +
        '"utmgclid": "Cj0KCQjwpNr4BRDYARIsAADIx9zaXmod","utmdclid": "Cj0KCQjwpNr4BRDYARIsAADIx9zaXmod","consentSource": "EPI", "sourceUrl": "www.epi.com/somespecificform","ip": "1.1.1.1", ' +
        '"datetimevalue": "2020-06-01T01:00:00","trackingcookie": "kajhsdajkshiu"},"consent": [{"dataUsePurpose": "marketing","privacyConsentStatus": "opt-in","captureVersion": 2 ' +
        '},{"dataUsePurpose": "survey","privacyConsentStatus": "opt-in","captureVersion": 2},{"dataUsePurpose": "profiling","privacyConsentStatus": "opt-in","captureVersion": 2}],"channel": { ' +
        '"emailhash": "6712A285E72F492E1B767E6A61E10BA9B6C65713D8E46087580E62E3224E3F4B"},"individual": {"lastname": "Gl00000nn","firstname": "Ser091239rano", ' +
        '"salutation": "mrs","middleName": "Her00000ico","company": "Sern000000jpo","phone": "+63912312312","postalCode": "1000SJ","country": "Netherlands","city": "Amsterdam","houseNumber": "99", ' +
        '"street": "Hoofdstraat","state": "Zuid-Holland","title": "Buyer","language": "SAP_NL","subject": "Online information request","coffeemachinecode": "BaristaOne" },"details": { ' +
        '"touchpointType": "Online Quote Request MC","leadSource": "EPI" ,"campaignId": "' + camprec.Id +'"},"customFields": [{ "name": "definedonthefly1", "value": "michael" },{ "name":"differentthistime", "value": 1 },{ "name": "additionalfield", "value": true }]}';
        
        test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/formapi';
        req.httpMethod = 'POST';
        req.requestBody = blob.valueOf(jsonstring);
        RestContext.request = req;
        RestContext.response= res;
        
        SM_FormAPI.formapi();
        Contact contactrec = [Select id, Consent_Status_Marketing__c, Consent_Status_Profiling__c, Consent_Status_Surveys__c from Contact where Email_Sha256__c = '6712A285E72F492E1B767E6A61E10BA9B6C65713D8E46087580E62E3224E3F4B']; 
        //Double Opt In  Market Opt in all process on consent Contact
        System.assert(contactrec.Consent_Status_Marketing__c == 'Pending');
        System.assert(contactrec.Consent_Status_Profiling__c == 'Pending');
        System.assert(contactrec.Consent_Status_Surveys__c == 'Pending');
        test.stopTest();
    }

    private static testMethod void testPost3() {
        
        testSetup();
		String jsonstring = '{"sales_organization": "SAP_6712", "requestData": {"messageId": "randomuniqueidentifier","utmcsr": "google","utmcmd": "cpc","utmccn": "test","utmcct": "test","utmctr": "test", ' +
        '"utmgclid": "Cj0KCQjwpNr4BRDYARIsAADIx9zaXmod","utmdclid": "Cj0KCQjwpNr4BRDYARIsAADIx9zaXmod","consentSource": "EPI", "sourceUrl": "www.epi.com/somespecificform","ip": "1.1.1.1", ' +
        '"datetimevalue": "2020-06-01T01:00:00","trackingcookie": "kajhsdajkshiu"},"consent": [{"dataUsePurpose": "marketing","privacyConsentStatus": "opt-out" ' +
        '},{"dataUsePurpose": "survey","privacyConsentStatus": "opt-out"},{"dataUsePurpose": "profiling","privacyConsentStatus": "opt-out"}],"channel": { ' +
        '"email": "glenn0829serrano@gmail.com","emailhash": "4ee81cf8fec6b89a754a182f8df94b5139c20cea6f6c84dde3707eac12366"},"individual": {"lastname": "Gl00000nn","firstname": "Ser091239rano", ' +
        '"salutation": "mrs","middleName": "Her00000ico","company": "Sern000000jpo","phone": "+63912312312","postalCode": "1000SJ","country": "Netherlands","city": "Amsterdam","houseNumber": "99", ' +
        '"street": "Hoofdstraat","state": "Zuid-Holland","title": "Buyer","language": "SAP_NL","subject": "Online information request","coffeemachinecode": "BaristaOne" },"details": { ' +
        '"touchpointType": "Online Quote Request MC","leadSource": "EPI" },"customFields": [{ "name": "definedonthefly1", "value": "michael" },{ "name":"differentthistime", "value": 1 },{ "name": "additionalfield", "value": true }]}';
        
        test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/formapi';
        req.httpMethod = 'POST';
        req.requestBody = blob.valueOf(jsonstring);
        RestContext.request = req;
        RestContext.response= res;
        
        SM_FormAPI.formapi();
        Lead leadrec = [Select id, Email from Lead where Email = 'glenn0829serrano@gmail.com']; 
        //New Lead
        System.assert(leadrec.Email == 'glenn0829serrano@gmail.com');
        test.stopTest();
    }
    
    private static testMethod void testPost5() {
        test.startTest();
        testSetup();
		String jsonstring = '{"sales_organization": "SAP_0111", "requestData": {"messageId": "randomuniqueidentifier","utmcsr": "google","utmcmd": "cpc","utmccn": "test","utmcct": "test","utmctr": "test", ' +
        '"utmgclid": "Cj0KCQjwpNr4BRDYARIsAADIx9zaXmod","utmdclid": "Cj0KCQjwpNr4BRDYARIsAADIx9zaXmod","consentSource": "EPI", "sourceUrl": "www.epi.com/somespecificform","ip": "1.1.1.1", ' +
        '"datetimevalue": "2020-06-01T01:00:00","trackingcookie": "kajhsdajkshiu"},"consent": [{"dataUsePurpose": "marketing","privacyConsentStatus": "opt-out" ' +
        '},{"dataUsePurpose": "survey","privacyConsentStatus": "opt-out"},{"dataUsePurpose": "profiling","privacyConsentStatus": "opt-out"}],"channel": { ' +
        '"email": "glenn0828serrano@gmail.com"},"individual": {"lastname": "Gl00000nn","firstname": "Ser091239rano", ' +
        '"salutation": "mrs","middleName": "Her00000ico","company": "Sern000000jpo","phone": "+63912312312","postalCode": "1000SJ","country": "Netherlands","city": "Amsterdam","houseNumber": "99", ' +
        '"street": "Hoofdstraat","state": "Zuid-Holland","title": "Buyer","language": "SAP_NL","subject": "Online information request","coffeemachinecode": "BaristaOne" },"details": { ' +
        '"touchpointType": "Online Quote Request MC","leadSource": "EPI" },"customFields": [{ "name": "definedonthefly1", "value": "michael" },{ "name":"differentthistime", "value": 1 },{ "name": "additionalfield", "value": true }]}';
        
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/formapi';
        req.httpMethod = 'POST';
        req.requestBody = blob.valueOf(jsonstring);
        RestContext.request = req;
        RestContext.response= res;
        
        SM_FormAPI.formapi();
        Contact contactrec = [Select id, Consent_Status_Marketing__c, Consent_Status_Profiling__c, Consent_Status_Surveys__c from Contact where Email_Sha256__c = '6712A285E72F492E1B767E6A61E10BA9B6C65713D8E46087580E62E3224E3F4B']; 
        //Double Opt In  Market Opt in all process on consent Contact
        System.assert(contactrec.Consent_Status_Marketing__c == 'Opt-Out');
        System.assert(contactrec.Consent_Status_Profiling__c == 'Opt-Out');
        System.assert(contactrec.Consent_Status_Surveys__c == 'Opt-Out');
        test.stopTest();
    }
    
    private static testMethod void testPost4() {
        test.startTest();
        testSetup();
		String jsonstring = '{"sales_organization": "SAP_0111", "requestData": {"messageId": "randomuniqueidentifier","utmcsr": "google","utmcmd": "cpc","utmccn": "test","utmcct": "test","utmctr": "test", ' +
        '"utmgclid": "Cj0KCQjwpNr4BRDYARIsAADIx9zaXmod","utmdclid": "Cj0KCQjwpNr4BRDYARIsAADIx9zaXmod","consentSource": "EPI", "sourceUrl": "www.epi.com/somespecificform","ip": "1.1.1.1", ' +
        '"datetimevalue": "2020-06-01T01:00:00","trackingcookie": "kajhsdajkshiu"},"consent": [{"dataUsePurpose": "marketing","privacyConsentStatus": "opt-out" ' +
        '},{"dataUsePurpose": "survey","privacyConsentStatus": "opt-out"},{"dataUsePurpose": "profiling","privacyConsentStatus": "opt-out"}],"channel": { ' +
        '"email": "glenn0829serrano@gmail.com"},"individual": {"lastname": "Gl00000nn","firstname": "Ser091239rano", ' +
        '"salutation": "mrs","middleName": "Her00000ico","company": "Sern000000jpo","phone": "+63912312312","postalCode": "1000SJ","country": "Netherlands","city": "Amsterdam","houseNumber": "99", ' +
        '"street": "Hoofdstraat","state": "Zuid-Holland","title": "Buyer","language": "SAP_NL","subject": "Online information request","coffeemachinecode": "BaristaOne" },"details": { ' +
        '"touchpointType": "Online Quote Request MC","leadSource": "EPI" },"customFields": [{ "name": "definedonthefly1", "value": "michael" },{ "name":"differentthistime", "value": 1 },{ "name": "additionalfield", "value": true }]}';
        
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/formapi';
        req.httpMethod = 'POST';
        req.requestBody = blob.valueOf(jsonstring);
        RestContext.request = req;
        RestContext.response= res;
        
        SM_FormAPI.formapi();
        Lead leadrec = [Select id, Email from Lead where Email = 'glenn0829serrano@gmail.com']; 
        //New Lead email only
        System.assert(leadrec.Email == 'glenn0829serrano@gmail.com');
        test.stopTest();
    }
    
    private static testMethod void testPost6() {
        test.startTest();
        testSetup();
		String jsonstring = '{"sales_organization": "SAP_0111", "requestData": {"messageId": "randomuniqueidentifier","utmcsr": "google","utmcmd": "cpc","utmccn": "test","utmcct": "test","utmctr": "test", ' +
        '"utmgclid": "Cj0KCQjwpNr4BRDYARIsAADIx9zaXmod","utmdclid": "Cj0KCQjwpNr4BRDYARIsAADIx9zaXmod","consentSource": "EPI", "sourceUrl": "www.epi.com/somespecificform","ip": "1.1.1.1", ' +
        '"datetimevalue": "2020-06-01T01:00:00","trackingcookie": "kajhsdajkshiu"},"consent": [{"dataUsePurpose": "marketing","privacyConsentStatus": "opt-in","captureVersion": 2 ' +
        '},{"dataUsePurpose": "survey","privacyConsentStatus": "opt-out"},{"dataUsePurpose": "profiling","privacyConsentStatus": "opt-out"}],"channel": { ' +
        '"email": "glenn0830serrano@gmail.com"},"individual": {"lastname": "Gl00000nn","firstname": "Ser091239rano", ' +
        '"salutation": "mrs","middleName": "Her00000ico","company": "Sern000000jpo","phone": "+63912312312","postalCode": "1000SJ","country": "Netherlands","city": "Amsterdam","houseNumber": "99", ' +
        '"street": "Hoofdstraat","state": "Zuid-Holland","title": "Buyer","language": "SAP_NL","subject": "Online information request","coffeemachinecode": "BaristaOne" },"details": { ' +
        '"touchpointType": "Online Quote Request MC","leadSource": "EPI" },"customFields": [{ "name": "definedonthefly1", "value": "michael" },{ "name":"differentthistime", "value": 1 },{ "name": "additionalfield", "value": true }]}';
        
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/formapi';
        req.httpMethod = 'POST';
        req.requestBody = blob.valueOf(jsonstring);
        RestContext.request = req;
        RestContext.response= res;
        
        SM_FormAPI.formapi();
        Contact contactrec = [Select id, Consent_Status_Marketing__c, Consent_Status_Profiling__c, Consent_Status_Surveys__c, Consent_Version_Marketing__c, Consent_Version_Profiling__c,
                              Consent_Version_Surveys__c from Contact where Email = 'glenn0830serrano@gmail.com']; 
        //Single Opt In  Market Opt in all process on consent Contact update and create cptc version change
        System.assert(contactrec.Consent_Version_Marketing__c == 2);
        System.assert(contactrec.Consent_Status_Profiling__c == 'Opt-Out');
        System.assert(contactrec.Consent_Status_Surveys__c == 'Opt-Out');
        test.stopTest();
    }
    
    private static testMethod void testPost7() {
        test.startTest();
        testSetup();
		String jsonstring = '{"sales_organization": "SAP_0111", "requestData": {"messageId": "randomuniqueidentifier","utmcsr": "google","utmcmd": "cpc","utmccn": "test","utmcct": "test","utmctr": "test", ' +
        '"utmgclid": "Cj0KCQjwpNr4BRDYARIsAADIx9zaXmod","utmdclid": "Cj0KCQjwpNr4BRDYARIsAADIx9zaXmod","consentSource": "EPI", "sourceUrl": "www.epi.com/somespecificform","ip": "1.1.1.1", ' +
        '"datetimevalue": "2020-06-01T01:00:00","trackingcookie": "kajhsdajkshiu"},"consent": [{"dataUsePurpose": "marketing","privacyConsentStatus": "opt-in","captureVersion": 3 ' +
        '},{"dataUsePurpose": "survey","privacyConsentStatus": "opt-in","captureVersion": 2},{"dataUsePurpose": "profiling","privacyConsentStatus": "opt-out"}],"channel": { ' +
        '"email": "glenn0828serrano@gmail.com"},"individual": {"lastname": "Gl00000nn","firstname": "Ser091239rano", ' +
        '"salutation": "mrs","middleName": "Her00000ico","company": "Sern000000jpo","phone": "+63912312312","postalCode": "1000SJ","country": "Netherlands","city": "Amsterdam","houseNumber": "99", ' +
        '"street": "Hoofdstraat","state": "Zuid-Holland","title": "Buyer","language": "SAP_NL","subject": "Online information request","coffeemachinecode": "BaristaOne" },"details": { ' +
        '"touchpointType": "ONLINE SERVICE REQUEST","leadSource": "EPI" },"customFields": [{ "name": "definedonthefly1", "value": "michael" },{ "name":"differentthistime", "value": 1 },' + 
        '{ "name": "additionalfield", "value": true }, { "name": "machinenumber", "value": "123454" },{"name": "coffeeisrunning","value": false},{"name": "shortdescription","value": "E93"}]}';
        
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/formapi';
        req.httpMethod = 'POST';
        req.requestBody = blob.valueOf(jsonstring);
        RestContext.request = req;
        RestContext.response= res;
        
        SM_FormAPI.formapi();
        Id contactrec = [Select id from Contact where Email = 'glenn0828serrano@gmail.com'].Id; 
        //Version change and opt out
        Case caserec = [Select Id, Subject, Touchpoint_Type__c from Case where ContactId = :contactrec];
        System.assert(caserec.Touchpoint_Type__c == 'ONLINE SERVICE REQUEST');
        System.assert(caserec.Subject == 'E93');
        test.stopTest();
    }
    
    private static testMethod void testPost8() {
        testSetup();
        Campaign camprec = new Campaign();
        camprec.Name = 'Test me';
        
        insert camprec;
        
		String jsonstring = '{"sales_organization": "SAP_6712", "requestData": {"messageId": "randomuniqueidentifier","utmcsr": "google","utmcmd": "cpc","utmccn": "test","utmcct": "test","utmctr": "test", ' +
        '"utmgclid": "Cj0KCQjwpNr4BRDYARIsAADIx9zaXmod","utmdclid": "Cj0KCQjwpNr4BRDYARIsAADIx9zaXmod","consentSource": "EPI", "sourceUrl": "www.epi.com/somespecificform","ip": "1.1.1.1", ' +
        '"datetimevalue": "2020-06-01T01:00:00","trackingcookie": "kajhsdajkshiu"},"consent": [{"dataUsePurpose": "marketing","privacyConsentStatus": "opt-in","captureVersion": 1 ' +
        '},{"dataUsePurpose": "survey","privacyConsentStatus": "opt-in","captureVersion": 1},{"dataUsePurpose": "profiling","privacyConsentStatus": "opt-out"}],"channel": { ' +
        '"email": "glenn0828serrano@gmail.com"},"individual": {"lastname": "Gl09123enn","firstname": "Ser091239rano", ' +
        '"salutation": "mrs","middleName": "Her091239123ico","company": "Sern0192309123jpo","phone": "+63912312312","postalCode": "1000SJ","country": "Netherlands","city": "Amsterdam","houseNumber": "99", ' +
        '"street": "Hoofdstraat","state": "Zuid-Holland","title": "Buyer","language": "NL","subject": "Online information request","coffeemachinecode": "BaristaOne" },"details": { ' +
        '"touchpointType": "Online Quote Request MC","leadSource": "EPI" ,"campaignId": "' + camprec.Id +'"},"customFields": [{ "name": "definedonthefly1", "value": "michael" },{ "name":"differentthistime", "value": 1 },{ "name": "additionalfield", "value": true }]}';
        
        test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/formapi';
        req.httpMethod = 'POST';
        req.requestBody = blob.valueOf(jsonstring);
        RestContext.request = req;
        RestContext.response= res;
        
        SM_FormAPI.formapi();
        Contact contactrec = [Select id, Email from Contact where Email = 'glenn0828serrano@gmail.com']; 
        //No Change Error on language try catch lines
        System.assert(contactrec.Email == 'glenn0828serrano@gmail.com');
        test.stopTest();
    }
    
    private static testMethod void testPost9() {
        test.startTest();
        testSetup();
		String jsonstring = '{"sales_organization": "SAP_0111", "requestData": {"messageId": "randomuniqueidentifier","utmcsr": "google","utmcmd": "cpc","utmccn": "test","utmcct": "test","utmctr": "test", ' +
        '"utmgclid": "Cj0KCQjwpNr4BRDYARIsAADIx9zaXmod","utmdclid": "Cj0KCQjwpNr4BRDYARIsAADIx9zaXmod","consentSource": "EPI", "sourceUrl": "www.epi.com/somespecificform","ip": "1.1.1.1", ' +
        '"datetimevalue": "2020-06-01T01:00:00","trackingcookie": "kajhsdajkshiu"},"consent": [{"dataUsePurpose": "marketing","privacyConsentStatus": "opt-in","captureVersion": 1 ' +
        '},{"dataUsePurpose": "survey","privacyConsentStatus": "opt-in","captureVersion": 1},{"dataUsePurpose": "profiling","privacyConsentStatus": "opt-out"}],"channel": { ' +
        '"email": "glennserrano0829@gmail.com","emailhash": "4ee81cf8fec6b89a754a182f8df94b5139c20cea6f6c84dde3707eaca00912311"},"individual": {"lastname": "Gl09123enn","firstname": "Ser091239rano", ' +
        '"salutation": "mrs","middleName": "Her091239123ico","company": "Sern0192309123jpo","phone": "+63912312312","postalCode": "1000SJ","country": "Netherlands","city": "Amsterdam","houseNumber": "99", ' +
        '"street": "Hoofdstraat","state": "Zuid-Holland","title": "Buyer","language": "SAP_NL","subject": "Online information request","coffeemachinecode": "BaristaOne" },"details": { ' +
        '"touchpointType": "Online Quote Request MC","leadSource": "EPI" },"customFields": [{ "name": "definedonthefly1", "value": "michael" },{ "name":"differentthistime", "value": 1 },{ "name": "additionalfield", "value": true }]}';
        
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/formapi';
        req.httpMethod = 'POST';
        req.requestBody = blob.valueOf(jsonstring);
        RestContext.request = req;
        RestContext.response= res;
        
        SM_FormAPI.formapi();
        Lead leadrec = [Select id, Consent_Status_Marketing__c, Consent_Status_Profiling__c, Consent_Status_Surveys__c from Lead where Email = 'glennserrano0829@gmail.com']; 
        //Single Opt In  Market Opt in and Opt out process on consent LEAD
        System.assert(leadrec.Consent_Status_Marketing__c == 'Opt-In');
        System.assert(leadrec.Consent_Status_Profiling__c == 'Opt-Out');
        System.assert(leadrec.Consent_Status_Surveys__c == 'Opt-In');
        test.stopTest();
    }
}