/*Karen Hung 15.10.2020
*Test class for TS_SendEmail
* DOO-4969
*
*/
@isTest
public with sharing class TS_SendEmail_Test {

    static Account acct;
    static Contact con;
    static Apttus_Config2__AccountLocation__c accLoc;
    static Case cse;
    static List<CountrySetting__c> csList;
    static CountrySetting__c csetUknown;
    static CountrySetting__c csetJourneyTrigger;
    static CountrySetting__c jtStakeholder;
    static PhysicalAsset__C pa;
   
    @TestSetup
    static void dataSetup(){

        try{
            TriggerSettings__c trg = TriggerSettings__c.getOrgDefaults();
            trg.CaseTrigger__c = true;
            //trg.WorkOrderTrigger__c = true;
            //trg.WorkOrderLineItemTrigger__c = true;
            upsert trg;
            
            IntegrationTriggerSettings__c trg1 = IntegrationTriggerSettings__c.getOrgDefaults();
            trg1.IntegrationLogTrigger__c = true;
            //upsert trg1;
            
            ProcessBuilderSettings__c pb = new ProcessBuilderSettings__c();
            pb.CasePBFlows__c = true;
           // pb.WorkOrderLineItemPBFlows__c = false;
            insert pb;     
        } catch(Exception ex) {
            system.debug(ex);
        }
        
    }

    static void setupTestData(){

        //create account
        acct = new Account(Name='Account', Phone='+31302979111');
        insert acct;
        
        //create contact
        con = TS_TestDataFactory.createContact();  
        con.AccountId = acct.Id;
        con.Preferred_Language__c = 'SAP_NL';
        con.Email = 'Test@salesforce.com';
        con.Communication_Preference__c = TS_Constants.EMAIL;
        con.CaseCreationNotification__c = true;
        con.CaseClosureNotification__c = true;
        insert con;
        
        //create account location
        accLoc = TS_TestDataFactory.createAccountLocationTest('123456753', acct.Id);
        accLoc.Additional_Case_Contact__c = con.Id;
        accLoc.Second_Additional_Case_Contact__c = con.Id;
        accLoc.Apttus_Config2__AccountId__c = acct.Id;
        accLoc.StakeholderNotification__c = true;
        insert accLoc;

        //create country setting records
        String unknownContactRecType = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c','Country Unknown Contact To Account Mapping');
        String jtRecType = TS_UtilityClass.getRecordTypeIdByName('CountrySetting__c','Journey Trigger');
        
        csList = new List<CountrySetting__c>();

        csetUknown = new CountrySetting__c();
        csetUknown.Name = 'NL - Unknown';
        csetUknown.RecordTypeId = unknownContactRecType;
        csetUknown.Account__c = acct.Id;
        csetUknown.Active__c = true;
        csetUknown.Country__c = 'SAP_0111';
        csetUknown.Language__c ='SAP_NL';
        csetUknown.Origin__c = 'Regular';
        csList.add(csetUknown);

        csetJourneyTrigger = new CountrySetting__c();
        csetJourneyTrigger.Name = 'NL - Case Create - Unknown Customer';
        csetJourneyTrigger.RecordTypeId = jtRecType;
        csetJourneyTrigger.Country__c = 'SAP_0111';
        csetJourneyTrigger.Active__c = true;
        csetJourneyTrigger.Journey_Trigger_Type__c = TS_Constants.CASE_CREATE;
        csetJourneyTrigger.Journey_Trigger_SubType__c = TS_Constants.CASE_CREATION_NOTIF_UNKNOWN_CUSTOMER;
        csetJourneyTrigger.Sending_Method__c = TS_Constants.SEND_VIA_MC;
        csetJourneyTrigger.Channel__c = TS_Constants.EMAIL;
        csetJourneyTrigger.Origin__c = 'Regular';
        csList.add(csetJourneyTrigger);

        jtStakeholder = new CountrySetting__c();
        jtStakeholder.Name = 'NL - Case Create - Stakeholder';
        jtStakeholder.RecordTypeId = jtRecType;
        jtStakeholder.Country__c = 'SAP_0111';
        jtStakeholder.Channel__c = TS_Constants.EMAIL;
        jtStakeholder.Journey_Trigger_Type__c = TS_Constants.CASE_CREATE;
        jtStakeholder.Journey_Trigger_SubType__c = TS_Constants.CASE_CREATION_NOTIF_STAKEHOLDER;
        jtStakeholder.Sending_Method__c = TS_Constants.SEND_VIA_MC;
        jtStakeholder.Active__c = true;
        jtStakeholder.Origin__c = 'Regular';
        csList.add(jtStakeholder);

        insert csList; 
        
        //create physical asset
        pa = new PhysicalAsset__c();
        pa.Name='Test'; 
        pa.UniqueNumber__c='1234567-TestMachine';
        pa.ResponseTime__c = '8';
        pa.ResponseTimeS15__c = 4;
        pa.RecordTypeId = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get('Machine').getRecordTypeId();
        insert pa;

        cse = new Case();
        cse.AccountId = acct.Id;
        cse.AccountLocation__c = accLoc.Id;
        cse.Priority = Label.TS_Case_Priority_Medium;
        cse.SLADate__c=datetime.now();
        cse.SubType__c=Label.TS_Case_SubType_CorrectMaint;
        cse.Type=  TS_Constants.CASE_TYPE_FIELDSERVICE;
        cse.ContactId = con.Id;
        cse.Origin=Label.TS_Case_Origin_Email;
        cse.RecordTypeId = TS_UtilityClass.getRecordTypeIdByName(Label.TS_Obj_API_Name_Case, Label.TS_Case_RecordType_Field);
        cse.PhysicalAsset__c = pa.id;
        cse.Status = Label.TS_Status_New;
        cse.CaseSubStatus__c = Label.TS_Status_New;
        cse.SalesOrganization__c = 'SAP_0111';
        cse.Sent_Case_Create_Notification_to_Contact__c = false;
        cse.Sent_Case_Create_Notif_to_Stakeholder__c = false;
        cse.Sent_Case_Cancelation_Notif_to_Contact__c = false;
        cse.Sent_Case_Cancel_Notif_to_Stakeholder__c = false;
        cse.Sent_Case_Closure_Notif_to_Stakeholder__c = false;
        cse.Sent_Case_Closure_Notif_to_Contact__c = false;
        cse.NoCaseCreationNotification__c = false;
        cse.NoCaseClosureNotification__c = false;
        cse.NoStakeholderNotification__c = false;
        insert cse;

    }

    /*test sending email on casecreation for unknown customer using SF Platform*/
    static testMethod void testCaseUnknownCustomerviaPlatform(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
			
            setupTestData();
            
            List<CountrySetting__c> csetforUpdate = new List<CountrySetting__c>();
            csetJourneyTrigger.Sending_Method__c = TS_Constants.SEND_VIA_SF_PLATFORM;
            csetforUpdate.add(csetJourneyTrigger);
            
            jtStakeholder.Sending_Method__c = TS_Constants.SEND_VIA_SF_PLATFORM;
            csetforUpdate.add(jtStakeholder);
           
            update(csetforUpdate);
            
            csetUknown.User__c = u.Id;
            update csetUknown;
            
            cse.SuppliedEmail = 'Test@tests.com';
            cse.ContactId = null;
            cse.Contact_Created__c = false;
            cse.Type = TS_Constants.TS_CASE_RECORDTYPE_QUALIFYCASE;
            update cse;
            
            Test.startTest();
                TS_SendEmail sendEmail = new TS_SendEmail();
                sendEmail.SENDFROMCASE(new List<Case>{cse});
                System.assertEquals(true, [SELECT Id,Contact_Created__c from Case where id= :cse.Id][0].Contact_Created__c);            
            Test.stopTest();
        }
    }
    
    /*test sending email on casecreation for unknown customer*/
    static testMethod void testCaseUnknownCustomer(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {

            setupTestData();
            
            csetUknown.User__c = u.Id;
            update csetUknown;
            
            cse.SuppliedEmail = 'Test@tests.com';
            cse.ContactId = null;
            cse.Contact_Created__c = false;
            cse.Type = TS_Constants.TS_CASE_RECORDTYPE_QUALIFYCASE;
            update cse;
            
            Test.startTest();
                TS_SendEmail sendEmail = new TS_SendEmail();
                sendEmail.SENDFROMCASE(new List<Case>{cse});
                System.assertEquals(true, [SELECT Id,Sent_Case_Create_Notification_to_Contact__c from Case where id= :cse.Id][0].Sent_Case_Create_Notification_to_Contact__c);
            Test.stopTest();
        }
    }
    
    /*test sending email on casecreation for known customer*/
    static testMethod void testCaseKnownCustomer(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {

            setupTestData();
            csetJourneyTrigger.Journey_Trigger_SubType__c = TS_Constants.CASE_CREATION_NOTIF_KNOWN_CUSTOMER;
            update csetJourneyTrigger;
           
            Test.startTest();
             	TS_SendEmail sendEmail = new TS_SendEmail();
            	sendEmail.SENDFROMCASE(new List<Case>{cse});
                System.assertEquals(true, [SELECT Id,Sent_Case_Create_Notification_to_Contact__c from Case where id= :cse.Id][0].Sent_Case_Create_Notification_to_Contact__c);
            Test.stopTest();
        }
    }
    
    /*test sending email on casecreation for known customer using SF Platform*/
    static testMethod void testCaseKnownCustomerviaPlatform(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {

            setupTestData();
            
            List<CountrySetting__c> csetforUpdate = new List<CountrySetting__c>();
            csetJourneyTrigger.Sending_Method__c = TS_Constants.SEND_VIA_SF_PLATFORM;
            csetJourneyTrigger.Journey_Trigger_SubType__c = TS_Constants.CASE_CREATION_NOTIF_KNOWN_CUSTOMER;
            csetforUpdate.add(csetJourneyTrigger);
            
            jtStakeholder.Sending_Method__c = TS_Constants.SEND_VIA_SF_PLATFORM;
            csetforUpdate.add(jtStakeholder);
           
            update(csetforUpdate);
            
            Test.startTest();
            	TS_SendEmail sendEmail = new TS_SendEmail();
            	sendEmail.SENDFROMCASE(new List<Case>{cse});
                System.assertEquals(true, [SELECT Id,Sent_Case_Create_Notification_to_Contact__c from Case where id= :cse.Id][0].Sent_Case_Create_Notification_to_Contact__c);
            Test.stopTest();
        }
    }
        
    /*test sending email on case cancelation for known customer*/
    static testMethod void testCaseCancelKnownCustomer(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {

            setupTestData();
            csetJourneyTrigger.Journey_Trigger_Type__c = TS_Constants.CASE_CANCELATION;
            csetJourneyTrigger.Journey_Trigger_SubType__c = TS_Constants.CASE_CANCEL_NOTIF_KNOWN_CUSTOMER;
            update csetJourneyTrigger;
            
            jtStakeholder.Journey_Trigger_Type__c = TS_Constants.CASE_CANCELATION;
            jtStakeholder.Journey_Trigger_SubType__c = TS_Constants.CASE_CANCEL_NOTIF_STAKEHOLDER;
            update jtStakeholder;
            
            cse.Status = TS_Constants.STATUS_CANCELED;
            cse.CancelationReason__c = 'Not Needed';
            update cse;

            Test.startTest();
            	TS_SendEmail sendEmail = new TS_SendEmail();
            	sendEmail.SENDFROMCASE(new List<Case>{cse});
                System.assertEquals(true, [SELECT Id,Sent_Case_Cancelation_Notif_to_Contact__c from Case where id= :cse.Id][0].Sent_Case_Cancelation_Notif_to_Contact__c);
            Test.stopTest();
        }
    }
    
    /*test sending email on case closure for known customer*/
    static testMethod void testCaseClosureKnownCustomer(){
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {

            setupTestData();
            csetJourneyTrigger.Journey_Trigger_Type__c = TS_Constants.CASE_CLOSURE_FIXED_BY_PHONE;
            csetJourneyTrigger.Journey_Trigger_SubType__c = TS_Constants.CASE_CLOSURE_NOTIF_KNOWN_CUSTOMER;
            update csetJourneyTrigger;
            
            jtStakeholder.Journey_Trigger_Type__c = TS_Constants.CASE_CLOSURE_FIXED_BY_PHONE;
            jtStakeholder.Journey_Trigger_SubType__c = TS_Constants.CASE_CLOSURE_NOTIF_STAKEHOLDER;
            update jtStakeholder;
            
            cse.Status = TS_Constants.STATUS_CLOSED;
            cse.CompletionCode__c = '140';
            cse.External_Solution__c = 'Fixed by Phone';
            update cse;

            Test.startTest();
            	system.debug('Created Journey Trigger ' + [select id from Journey_Trigger__c]);
            	TS_SendEmail sendEmail = new TS_SendEmail();
            	sendEmail.SENDFROMCASE(new List<Case>{cse});
                System.assertEquals(true, [SELECT Id,Sent_Case_Closure_Notif_to_Contact__c from Case where id= :cse.Id][0].Sent_Case_Closure_Notif_to_Contact__c);
            Test.stopTest();
        }
    }    
}