@isTest
public class ContactTriggerHandler_Test {
    //Description: This is for test setup of the test class
    static void testSetup(){
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
        //insert custom settings
        TriggerSettings__c ts = new TriggerSettings__c();
        ts.ContactTrigger__c = true;
        ts.ConsentTrigger__c = true;
        insert ts;

    }
    
    static void testSetupFalse(){
        //insert custom settings
        TriggerSettings__c ts = new TriggerSettings__c();
        ts.ContactTrigger__c = false;
        insert ts;

    }

    private static testMethod void consent(){
        testSetup();
        
        Profile p = [SELECT Id FROM Profile WHERE  Name = 'JDE-Integration-Digital']; 
        User u = new User(Alias = 'standt', Email='sample@testUser133000.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sampleasdfasdf@123123123gmail.com', Sales_Organization__c = 'SAP_0111', CurrencyIsoCode = 'EUR');
        System.runAs(u) {
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
            Con1.Email = 'testqweqwe@gmail.com';
            Con1.MobilePhone = '+31302979122';
            Con1.Sales_Organization__c = 'SAP_0111';
            checkRecursive.run = true; 
            insert con1;
            
            Individual ind = new Individual();
            ind.FirstName = con1.FirstName;
            ind.MiddleName = con1.MiddleName;
            ind.LastName = con1.LastName;
            ind.Related_To__c = con1.Id;
            insert ind;
            
            Contact updatecon = [Select Id, IndividualId, Consent_Status_Marketing__c, Consent_Status_Profiling__c, Consent_Status_Surveys__c, Email from Contact where Id = :con1.Id];
            updatecon.IndividualId = ind.Id;
            updatecon.Email = null;
            updatecon.Consent_Status_Marketing__c = 'Opt-Out';
            updatecon.Consent_Status_Profiling__c = 'Opt-Out';
            updatecon.Consent_Status_Surveys__c = 'Opt-Out';
            checkRecursive.run = true;   
            update updatecon;
            
        }
    }
    
    private static testMethod void consentpresentcptc(){
        testSetup();
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
        con.Consent_Status_Marketing__c = 'Opt-In';
        con.Consent_Status_Profiling__c = 'Opt-In';
        con.Consent_Status_Surveys__c = 'Opt-In';
        con.Consent_Version_Marketing__c = 1;
        con.Consent_Version_Profiling__c = 1;
        con.Consent_Version_Surveys__c = 1;
        insert con; 
        
        Individual ind1 = new Individual();
        ind1.FirstName = con.FirstName;
        ind1.LastName = con.LastName;
        ind1.Related_To__c = con.Id;
        insert ind1;
        
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
        
        
        insert cptcadd;
        
        Profile p = [SELECT Id FROM Profile WHERE  Name = 'JDE-Integration-Digital']; 
        User u = new User(Alias = 'standt', Email='sample@testUser313000.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sampleasdfasdf@1321123gmail.com', Sales_Organization__c = 'SAP_0111', CurrencyIsoCode = 'EUR');
        System.runAs(u) {
            
            
            Contact updatecon1 = [Select Id, IndividualId, Consent_Status_Marketing__c, Consent_Status_Profiling__c, Consent_Status_Surveys__c,
                                   Consent_Version_Marketing__c, Consent_Version_Profiling__c, Consent_Version_Surveys__c from Contact where Email = 'glenn0828serrano@gmail.com'];
            
            updatecon1.Consent_Status_Marketing__c = 'Opt-In';
            updatecon1.Consent_Status_Profiling__c = 'Opt-In';
            updatecon1.Consent_Status_Surveys__c = 'Opt-In';
            updatecon1.Consent_Version_Marketing__c = 2;
            updatecon1.Consent_Version_Profiling__c = 2;
            updatecon1.Consent_Version_Surveys__c = 2;
            checkRecursive.run = true;
            update updatecon1;
            
        }
    }
    
    private static testMethod void consentpresentcptcoptout(){
        testSetup();
 
        Profile p = [SELECT Id FROM Profile WHERE  Name = 'JDE-Integration-Digital']; 
        User u = new User(Alias = 'standt', Email='sample@testUser313000.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sampleasdfasdf@1321123gmail.com', Sales_Organization__c = 'SAP_0111', CurrencyIsoCode = 'EUR');
        System.runAs(u) {
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
            con.Consent_Status_Marketing__c = 'Opt-In';
            con.Consent_Status_Profiling__c = 'Opt-In';
            con.Consent_Status_Surveys__c = 'Opt-In';
            con.Consent_Version_Marketing__c = 1;
            con.Consent_Version_Profiling__c = 1;
            con.Consent_Version_Surveys__c = 1;
            insert con; 
    
            Individual ind1 = new Individual();
            ind1.FirstName = con.FirstName;
            ind1.LastName = con.LastName;
            ind1.Related_To__c = con.Id;
            insert ind1;
    
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
    
    
            insert cptcadd;
            
            Contact updatecon1 = [Select Id, IndividualId, Consent_Status_Marketing__c, Consent_Status_Profiling__c, Consent_Status_Surveys__c,
                                   Consent_Version_Marketing__c, Consent_Version_Profiling__c, Consent_Version_Surveys__c from Contact where Email = 'glenn0828serrano@gmail.com'];
            
            updatecon1.Consent_Status_Marketing__c = 'Opt-Out';
            updatecon1.Consent_Status_Profiling__c = 'Opt-Out';
            updatecon1.Consent_Status_Surveys__c = 'Opt-Out';
            checkRecursive.run = true;
            update updatecon1;
            
        }
    }
    
    private static testMethod void consentpresentcptcpartial(){
        testSetup();
 
        Profile p = [SELECT Id FROM Profile WHERE  Name = 'JDE-Integration-Digital']; 
        User u = new User(Alias = 'standt', Email='sample@testUser313000.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sampleasdfasdf@1321123gmail.com', Sales_Organization__c = 'SAP_0111', CurrencyIsoCode = 'EUR');
        System.runAs(u) {
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
            con.Consent_Status_Marketing__c = 'Opt-In';
            con.Consent_Version_Marketing__c = 1;
            insert con; 
    
            Individual ind1 = new Individual();
            ind1.FirstName = con.FirstName;
            ind1.LastName = con.LastName;
            ind1.Related_To__c = con.Id;
            insert ind1;
    
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

            insert cptcadd;
            
            Contact updatecon1 = [Select Id, IndividualId, Consent_Status_Marketing__c, Consent_Status_Profiling__c, Consent_Status_Surveys__c,
                                   Consent_Version_Marketing__c, Consent_Version_Profiling__c, Consent_Version_Surveys__c from Contact where Email = 'glenn0828serrano@gmail.com'];
            
            updatecon1.Consent_Status_Marketing__c = 'Opt-In';
            updatecon1.Consent_Status_Profiling__c = 'Opt-In';
            updatecon1.Consent_Status_Surveys__c = 'Opt-In';
            updatecon1.Consent_Version_Marketing__c = 2;
            updatecon1.Consent_Version_Profiling__c = 2;
            updatecon1.Consent_Version_Surveys__c = 2;
            checkRecursive.run = true;
            update updatecon1;
            
        }
    }
    
    private static testMethod void consentpresentcptcpartial2(){
        testSetup();
 
        Profile p = [SELECT Id FROM Profile WHERE  Name = 'JDE-Integration-Digital']; 
        User u = new User(Alias = 'standt', Email='sample@testUser313000.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sampleasdfasdf@1321123gmail.com', Sales_Organization__c = 'SAP_0111', CurrencyIsoCode = 'EUR');
        System.runAs(u) {
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
            con.Consent_Status_Profiling__c = 'Opt-In';
            con.Consent_Version_Profiling__c = 1;
            insert con; 
    
            Individual ind1 = new Individual();
            ind1.FirstName = con.FirstName;
            ind1.LastName = con.LastName;
            ind1.Related_To__c = con.Id;
            insert ind1;
    
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
            cptcvaluesforinsert.DataUsePurposeId = dup1.Id;
            cptcvaluesforinsert.CaptureContactPointType = 'Email';
            cptcvaluesforinsert.Consent_Text_Version__c = '1';
            cptcvaluesforinsert.PrivacyConsentStatus = 'OptIn';
            cptcvaluesforinsert.PartyId = ind1.Id;
            cptcadd.add(cptcvaluesforinsert);

            insert cptcadd;
            
            Contact updatecon1 = [Select Id, IndividualId, Consent_Status_Marketing__c, Consent_Status_Profiling__c, Consent_Status_Surveys__c,
                                   Consent_Version_Marketing__c, Consent_Version_Profiling__c, Consent_Version_Surveys__c from Contact where Email = 'glenn0828serrano@gmail.com'];
            
            updatecon1.Consent_Status_Marketing__c = 'Opt-In';
            updatecon1.Consent_Status_Profiling__c = 'Opt-In';
            updatecon1.Consent_Status_Surveys__c = 'Opt-In';
            updatecon1.Consent_Version_Marketing__c = 2;
            updatecon1.Consent_Version_Profiling__c = 2;
            updatecon1.Consent_Version_Surveys__c = 2;
            checkRecursive.run = true;
            update updatecon1;
            
        }
    }

    private static testMethod void testArchive() {
        testSetup();
        
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
        Con1.Archiving_Flag__c = false;
        Con1.Contact_Status__c = 'Valid';
                
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

        Contact updatecon1 = [Select Id, IndividualId, Consent_Status_Marketing__c, Consent_Status_Profiling__c, Consent_Status_Surveys__c,
        Consent_Version_Marketing__c, Consent_Version_Profiling__c, Consent_Version_Surveys__c from Contact where Email = 'test123@gmail.com'];
        updatecon1.IndividualId = ind1.Id;
        updatecon1.Consent_Status_Marketing__c = 'Opt-Out';
        updatecon1.Consent_Status_Profiling__c = 'Opt-Out';
        updatecon1.Consent_Status_Surveys__c = 'Opt-Out';
        updatecon1.Archiving_Flag__c = true;
        updatecon1.Contact_Status__c = 'Not Valid';
        checkRecursive.run = true;       
        update updatecon1;
        Try {
            Contact con2 = new Contact();
            
            Con2.FirstName = 'Test';
            Con2.LastName = 'Commercial';
            Con2.AccountId = acc.id;
            Con2.Phone = '+31302979111';
            Con2.Main_Commercial_Person__c = True;
            Con2.Sales_Organization__c = 'SAP_0111';
            checkRecursive.run = true;       
            insert con2;
        } Catch (exception e) {                    
        }
        
        //Check if Opportunity is created
        List<Contact> cont = [SELECT id FROM Contact WHERE Id =: con1.id];
                                                 
        system.assertEquals(cont.size(), 1);
        
        
    }
    
    private static testMethod void testPositive() {
        testSetup();
        
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
        Con1.Email = 'test@gmail.com';
        Con1.Main_Commercial_Person__c = True;
        Con1.MobilePhone = '+31302979122';
        Con1.Sales_Organization__c = 'SAP_0111';
        Con1.Consent_Status_Marketing__c = 'Opt-In';
        Con1.Consent_Status_Profiling__c = 'Opt-In';
        Con1.Consent_Status_Surveys__c = 'Opt-In';
                
        insert con1;

        Con1.FirstName = 'Jed Chester';
        Con1.MobilePhone = '+31302979133';
        Con1.Archiving_Flag__c = true;
        Con1.Contact_Status__c = 'Not Valid';
        checkRecursive.run = false;
        update con1;
        
        Try {
            Contact con2 = new Contact();
            
            Con2.FirstName = 'Test';
            Con2.LastName = 'Commercial';
            Con2.AccountId = acc.id;
            Con2.Phone = '+31302979111';
            Con2.Main_Commercial_Person__c = True;
            Con2.Sales_Organization__c = 'SAP_0111';
            checkRecursive.run = true;       
            insert con2;
        } Catch (exception e) {                    
        }
        
        //Check if Opportunity is created
        List<Contact> cont = [SELECT id FROM Contact WHERE Id =: con1.id];
                                                 
        system.assertEquals(cont.size(), 1);
        
        
    }
    
    private static testMethod void testValidateMainService() {
        testSetup();
        
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979333';
        insert acc;
        
        Contact con1 = new Contact();
        
        Con1.FirstName = 'Test First Badoom';
        Con1.LastName = 'Test Last Badaam';
        Con1.AccountId = acc.id;
        Con1.Phone = '+31302979222';
        Con1.Main_Service_Person__c = True;
        Con1.MobilePhone = '+31302979122';
        Con1.Sales_Organization__c = 'SAP_0111';
        checkRecursive.run = true;   
        insert con1;
        
        
        Con1.FirstName = 'Jed Chester';
        Con1.MobilePhone = '+31302979133';
        checkRecursive.run = true;
        update con1;
        
        
        Try {
            Contact con2 = new Contact();
            
            Con2.FirstName = 'Test';
            Con2.LastName = 'Commercial';
            Con2.AccountId = acc.id;
            Con2.Phone = '+31302979111';
            Con2.Main_Service_Person__c = True;
            Con2.Sales_Organization__c = 'SAP_0111';
            checkRecursive.run = true; 
            insert con2;
            
        } Catch (exception e) {                    
        }
        
        //Check if Opportunity is created
        List<Contact> cont = [SELECT id FROM Contact WHERE Id =: con1.id];
                                                 
        system.assertEquals(cont.size(), 1);
        
        
    }
    
    private static testMethod void EditDeleteUndeleteTest(){
        
        testSetup();
        
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
        Con1.Main_Commercial_Person__c = True;
        Con1.Sales_Organization__c = 'SAP_0111';
        checkRecursive.run = true; 
        insert con1;
        
        delete con1;
        undelete con1;
        
    }
    
    private static testMethod void TestTriggerOff(){
        
        testSetupFalse();
        
        ContactTriggerHandler conHandler = new ContactTriggerHandler();
        TriggerDispatcher.Run(conHandler);
        
        TriggerSettings__c ts = TriggerSettings__c.getInstance();
        system.assertEquals(false, ts.ContactTrigger__c);
    
    }
    
    private static testMethod void updateRecordTypeIdTest(){
		
		testSetup(); 
        
  		Account acct = new Account(Name='Account', Phone='+31302979111');
        insert acct;
        
        //create contact
        Contact con = TS_TestDataFactory.createContact();  
        con.AccountId = acct.Id;
        con.Preferred_Language__c = 'SAP_NL';
        con.Email = 'Test@salesforce.com';
        con.Communication_Preference__c = TS_Constants.EMAIL;
        con.CaseCreationNotification__c = true;
        con.CaseClosureNotification__c = true;
        con.Sales_Organization__c = 'SAP_0111';
        con.Convert_to_Standard_Contact__c = false;
        con.RecordtypeId = TS_UtilityClass.getRecordTypeIdByName(TS_Constants.OBJ_APINAME_CONTACT, SM_Constants.ContactServiceProvider);
        insert con;
        
        test.startTest();
        con.Title = 'Test Title';
        con.Convert_to_Standard_Contact__c = true;
        update con;
        
        system.assertEquals(TS_UtilityClass.getRecordTypeIdByName(TS_Constants.OBJ_APINAME_CONTACT, SM_Constants.ContactStandard), [SELECT Id,RecordtypeId FROM Contact WHERE Id= :con.Id][0].RecordTypeId);
        test.stopTest();
    }
    
    private static testMethod void noconsentyet(){
        testSetup();
        Account acc = new Account();
        acc.Name = 'accName';
        acc.Second_Account_Name__c = 'sAccName';
        //acc.Sales_Office__c = 'SAP_F020';
        acc.Phone = '+31302979111';
        insert acc;
        
        Contact con1 = new Contact();
        con1.FirstName = 'Jed';
        con1.LastName = 'Samaniego';
        con1.AccountId = acc.id;
        con1.Phone = '+31302979111';
        con1.Email = 'testupdatenocptc@gmail.com';
        con1.MobilePhone = '+31302979122';
        con1.Sales_Organization__c = 'SAP_0111';
        checkRecursive.run = true; 
        insert con1;
        
        Individual ind1 = new Individual();
        ind1.FirstName = con1.FirstName;
        ind1.LastName = con1.LastName;
        ind1.Related_To__c = con1.Id;
        insert ind1;
        Contact updatecon = [Select Id, IndividualId, Consent_Status_Marketing__c, Consent_Status_Profiling__c, Consent_Status_Surveys__c, Email from Contact where Email = 'testupdatenocptc@gmail.com'];
        updatecon.IndividualId = ind1.Id;
        update updatecon;
        
        Profile p = [SELECT Id FROM Profile WHERE  Name = 'JDE-Integration-Digital']; 
        User u = new User(Alias = 'standt', Email='sample@testUser133000.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sampleasdfasdf@123123123gmail.com', Sales_Organization__c = 'SAP_0111', CurrencyIsoCode = 'EUR');
        System.runAs(u) {

            Contact updatecon1 = [Select Id, IndividualId, Consent_Status_Marketing__c, Consent_Status_Profiling__c, Consent_Status_Surveys__c, Email, 
                                  Consent_Version_Marketing__c, Consent_Version_Profiling__c, Consent_Version_Surveys__c from Contact where Email = 'testupdatenocptc@gmail.com'];
            
            updatecon1.Consent_Status_Marketing__c = 'Opt-In';
            updatecon1.Consent_Status_Profiling__c = 'Opt-In';
            updatecon1.Consent_Status_Surveys__c = 'Opt-In';
            updatecon1.Consent_Version_Marketing__c = 1;
            updatecon1.Consent_Version_Profiling__c = 1;
            updatecon1.Consent_Version_Surveys__c = 1;
            checkRecursive.run = true;   
            test.startTest();
            update updatecon1;
            test.stopTest();
            
        }
    }
    
}