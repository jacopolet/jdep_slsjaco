/**
 * This class contains unit tests for validating the behavior of LeadTriggerHandler
 * and triggers.
 */
//-------------------------------------------------------------------------------------------//
// Author       :   Alvin Lomod - Accenture
// Created Date :   November 21, 2017
// Usage        :   
// Updates      :   
//-------------------------------------------------------------------------------------------//
@isTest
private class LeadTriggerHandlerTest{
    
    private static QueuesObject insertQueue() {
        Group testGroup = new Group(Name='test group', Type='Queue');
        insert testGroup;
        
        QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = 'Lead');
            insert testQueue;
            
            return testQueue;

    }
        
    private static User createAdminUser(){
        
        Id PAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        Id RAdmin = [SELECT Id FROM UserRole WHERE Name = 'JDE Professional'].Id;
        integer i = 1;
        User systemAdmin = new User(alias = 'admin123', email='admintest123@noemail.com',
                emailencodingkey='UTF-8', lastname='LastNameAdmin', firstName = 'FirstNameAdmin', languagelocalekey='en_US',
                localesidkey='en_US', profileid = PAdmin, country='United States',IsActive =true, userroleId = RAdmin,
                Sales_Organization__c = 'SAP_0333',
                timezonesidkey='America/Los_Angeles', username='admin123test@noemail.com' + i, Elevated_Access_Reason__c = 'Defect or Incident Resolution', Elevated_Access_Reference__c = 'ASDF');
        
        insert systemAdmin;
        i++;
        return systemAdmin;
        
    }
    
    private static User createPartnerUser(){

        Id p = [SELECT Id FROM Profile WHERE Name='Partner Community User'].id;
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
        insert con;  
                  
        User PartnerUser;
        
            
        PartnerUser = new User(alias = 'test123', email='test123@noemail.com',
                emailencodingkey='UTF-8', lastname='LastNamePartner', firstName = 'FirstNamePartner', languagelocalekey='en_US',
                localesidkey='en_US', profileid = p, country='United States',IsActive =true,
                             ContactId = con.Id, Sales_Organization__c = 'SAP_0333',
                timezonesidkey='America/Los_Angeles', username='tester@notemail.com');
       
        insert PartnerUser;
    
        return PartnerUser;
    }
    
    private static User createDellBoomiUser(){

        Id p = [SELECT Id FROM Profile WHERE Name='JDE-Integration-Digital'].id;
        Id RAdmin = [SELECT Id FROM UserRole WHERE Name = 'JDE Professional'].Id;
                  
        User IntegUser = new User(alias = 'test123', email='test123@noemail.com',
                emailencodingkey='UTF-8', lastname='LastNamePartner', firstName = 'FirstNamePartner', languagelocalekey='en_US',
                localesidkey='en_US', profileid = p, country='United States',IsActive =true, Sales_Organization__c = 'SAP_0333',userroleId = RAdmin,
                timezonesidkey='America/Los_Angeles', username='tester@notemail.com');
       
        insert IntegUser;
        
        return IntegUser;
    }
    
    static testMethod void convertTaskWithOpportunity(){
        
        insert new TriggerSettings__c(LeadTrigger__c = true);
       
        List<Task> taskforinsert = new List<Task>();
        
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
        insert ld;
        
        Lead ld1 = new Lead();
        ld1.Status = 'Open';
        ld1.LastName = 'TestLead';
        ld1.FirstName = 'TestLead';
        ld1.Title = 'TestLead';
        ld1.Phone = '+1234567890';
        ld1.Segment__c = 'SAP_A';
        ld1.Touchpoint_Type__c = 'CAMPAIGN';
        ld1.Company = 'TestCompany1';
        ld1.Sales_Organization__c = 'SAP_0111';
        
        insert ld1;
        
        Task taskrec1 = new Task();
        taskrec1.Subject = 'a';
        taskrec1.Touchpoint_Type__c = 'CAMPAIGN';
        taskrec1.Task_Source__c = 'SFDC';
        taskrec1.ActivityDate = System.today();
        taskrec1.Status = 'Open';
        taskrec1.WhoId = ld.Id;
        
        Task taskrec2 = new Task();
        taskrec2.Subject = 'a';
        taskrec2.Touchpoint_Type__c = 'CAMPAIGN';
        taskrec2.Task_Source__c = 'SFDC';
        taskrec2.ActivityDate = System.today();
        taskrec2.Status = 'Open';
        taskrec2.WhoId = ld.Id;
        
        Task taskrec3 = new Task();
        taskrec3.Subject = 'a';
        taskrec3.Touchpoint_Type__c = 'CAMPAIGN';
        taskrec3.Task_Source__c = 'SFDC';
        taskrec3.ActivityDate = System.today();
        taskrec3.Status = 'Open';
        taskrec3.WhoId = ld.Id;
        
        Task taskrec4 = new Task();
        taskrec4.Subject = 'a';
        taskrec4.Touchpoint_Type__c = 'CAMPAIGN';
        taskrec4.Task_Source__c = 'SFDC';
        taskrec4.ActivityDate = System.today();
        taskrec4.Status = 'Open';
        taskrec4.WhoId = ld1.Id;
        
        Task taskrec5 = new Task();
        taskrec5.Subject = 'a';
        taskrec5.Touchpoint_Type__c = 'CAMPAIGN';
        taskrec5.Task_Source__c = 'SFDC';
        taskrec5.ActivityDate = System.today();
        taskrec5.Status = 'Open';
        taskrec5.WhoId = ld1.Id;
        
        Task taskrec6 = new Task();
        taskrec6.Subject = 'a';
        taskrec6.Touchpoint_Type__c = 'CAMPAIGN';
        taskrec6.Task_Source__c = 'SFDC';
        taskrec6.ActivityDate = System.today();
        taskrec6.Status = 'Open';
        taskrec6.WhoId = ld1.Id;
        
        taskforinsert.add(taskrec1);
        taskforinsert.add(taskrec2);
        taskforinsert.add(taskrec3);
        taskforinsert.add(taskrec4);
        taskforinsert.add(taskrec5);
        taskforinsert.add(taskrec6);
        
        insert taskforinsert;
        
        Test.startTest();
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(ld.Id);
        LeadStatus convertStatus = [Select Id, MasterLabel FROM LeadStatus WHERE isConverted = true AND MasterLabel = 'Converted with Opportunity'];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        lc.setOpportunityName('test');
        lc.setOwnerId(UserInfo.getUserId());
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        System.assert(lcr.isSuccess());
        
        Test.stopTest();
        
        List<Task> taskquery = [Select Id, Reason__c, WhoId from Task WHERE Id IN :taskforinsert];
        System.assertEquals(taskquery[0].Reason__c, 'Converted to Opportunity');  
        
    }
    
    static testMethod void convertTaskWithOpportunitywithEvent(){
        
        insert new TriggerSettings__c(LeadTrigger__c = true);
       
        List<Task> taskforinsert = new List<Task>();
        
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
        
        insert ld;
        
        Lead ld1 = new Lead();
        ld1.Status = 'Open';
        ld1.LastName = 'TestLead';
        ld1.FirstName = 'TestLead';
        ld1.Title = 'TestLead';
        ld1.Phone = '+1234567890';
        ld1.Segment__c = 'SAP_A';
        ld1.Touchpoint_Type__c = 'CAMPAIGN';
        ld1.Company = 'TestCompany1';
        ld1.Sales_Organization__c = 'SAP_0111';
        
        insert ld1;
        
        Task taskrec1 = new Task();
        taskrec1.Subject = 'a';
        taskrec1.Touchpoint_Type__c = 'CAMPAIGN';
        taskrec1.Task_Source__c = 'SFDC';
        taskrec1.ActivityDate = System.today();
        taskrec1.Status = 'Open';
        taskrec1.WhoId = ld.Id;
        
        Task taskrec2 = new Task();
        taskrec2.Subject = 'a';
        taskrec2.Touchpoint_Type__c = 'CAMPAIGN';
        taskrec2.Task_Source__c = 'SFDC';
        taskrec2.ActivityDate = System.today();
        taskrec2.Status = 'Open';
        taskrec2.WhoId = ld.Id;
        
        Task taskrec3 = new Task();
        taskrec3.Subject = 'a';
        taskrec3.Touchpoint_Type__c = 'CAMPAIGN';
        taskrec3.Task_Source__c = 'SFDC';
        taskrec3.ActivityDate = System.today();
        taskrec3.Status = 'Open';
        taskrec3.WhoId = ld.Id;
        
        Task taskrec4 = new Task();
        taskrec4.Subject = 'a';
        taskrec4.Touchpoint_Type__c = 'CAMPAIGN';
        taskrec4.Task_Source__c = 'SFDC';
        taskrec4.ActivityDate = System.today();
        taskrec4.Status = 'Open';
        taskrec4.WhoId = ld1.Id;
        
        Task taskrec5 = new Task();
        taskrec5.Subject = 'a';
        taskrec5.Touchpoint_Type__c = 'CAMPAIGN';
        taskrec5.Task_Source__c = 'SFDC';
        taskrec5.ActivityDate = System.today();
        taskrec5.Status = 'Open';
        taskrec5.WhoId = ld1.Id;
        
        Task taskrec6 = new Task();
        taskrec6.Subject = 'a';
        taskrec6.Touchpoint_Type__c = 'CAMPAIGN';
        taskrec6.Task_Source__c = 'SFDC';
        taskrec6.ActivityDate = System.today();
        taskrec6.Status = 'Open';
        taskrec6.WhoId = ld1.Id;
        
        taskforinsert.add(taskrec1);
        taskforinsert.add(taskrec2);
        taskforinsert.add(taskrec3);
        taskforinsert.add(taskrec4);
        taskforinsert.add(taskrec5);
        taskforinsert.add(taskrec6);
        
        insert taskforinsert;
        
        Test.startTest();
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(ld.Id);
        LeadStatus convertStatus = [Select Id, MasterLabel FROM LeadStatus WHERE isConverted = true AND MasterLabel = 'Converted to Opportunity with Event'];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        lc.setOpportunityName('test');
        lc.setOwnerId(UserInfo.getUserId());
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        System.assert(lcr.isSuccess());
        
        Test.stopTest();
        
        List<Task> taskquery = [Select Id, Reason__c, WhoId from Task WHERE Id IN :taskforinsert];
        System.assertEquals(taskquery[0].Reason__c, 'Converted to Event');  
        
    }
    
    static testMethod void convertTaskWithOutOpportunity(){
        
        insert new TriggerSettings__c(LeadTrigger__c = true);
       
        List<Task> taskforinsert = new List<Task>();
        
        Lead ld1 = new Lead();
        ld1.Status = 'Open';
        ld1.LastName = 'TestLead';
        ld1.FirstName = 'TestLead';
        ld1.Title = 'TestLead';
        ld1.Phone = '+1234567890';
        ld1.Segment__c = 'SAP_A';
        ld1.Touchpoint_Type__c = 'CAMPAIGN';
        ld1.Company = 'TestCompany1';
        ld1.Sales_Organization__c = 'SAP_0111';
        ld1.OwnerId = UserInfo.getUserId();
        insert ld1;
        
        Task taskrec4 = new Task();
        taskrec4.Subject = 'a';
        taskrec4.Touchpoint_Type__c = 'CAMPAIGN';
        taskrec4.Task_Source__c = 'SFDC';
        taskrec4.ActivityDate = System.today();
        taskrec4.Status = 'Open';
        taskrec4.WhoId = ld1.Id;
        
        Task taskrec5 = new Task();
        taskrec5.Subject = 'a';
        taskrec5.Touchpoint_Type__c = 'CAMPAIGN';
        taskrec5.Task_Source__c = 'SFDC';
        taskrec5.ActivityDate = System.today();
        taskrec5.Status = 'Open';
        taskrec5.WhoId = ld1.Id;
        
        Task taskrec6 = new Task();
        taskrec6.Subject = 'a';
        taskrec6.Touchpoint_Type__c = 'CAMPAIGN';
        taskrec6.Task_Source__c = 'SFDC';
        taskrec6.ActivityDate = System.today();
        taskrec6.Status = 'Open';
        taskrec6.WhoId = ld1.Id;
        
        taskforinsert.add(taskrec4);
        taskforinsert.add(taskrec5);
        taskforinsert.add(taskrec6);
        
        insert taskforinsert;
        
        Test.startTest();
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(ld1.Id);
        lc.setDoNotCreateOpportunity(true);
        lc.setOwnerId(UserInfo.getUserId());
        LeadStatus convertStatus = [Select Id, MasterLabel FROM LeadStatus WHERE isConverted = true AND MasterLabel = 'Converted without Opportunity'];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        System.assert(lcr.isSuccess());
        
        Test.stopTest();
        
        List<Task> taskquery = [Select Id, Reason__c, WhoId from Task WHERE Id IN :taskforinsert and Touchpoint_Type__c = 'CAMPAIGN'];
        System.assertEquals(taskquery[0].Reason__c, 'No Follow Up Needed');
    }
    
    static testMethod void EditDeleteUndeleteTest(){
        
        insert new TriggerSettings__c(LeadTrigger__c = true);
        insert new WorkflowSettings__c(LeadWorkflows__c = true);
        
        Lead ld = new Lead();
        ld.Status = 'Open';
        ld.LastName = 'TestLead';
        ld.FirstName = 'TestLead';
        ld.Title = 'TestLead';
        ld.Phone = '+1234567890';
        ld.LeadSource = 'Asset Ownership Change';
        ld.Company = 'TestCompany';
        ld.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get(SM_Constants.LeadRecTypePRFPartner).getRecordTypeId();
        
        insert ld;
        
        ld.Company = 'TestCompanyyyy';
        update ld;
        delete ld;
        undelete ld;
        
        List<Lead> LeadUndel = [SELECT Id, Assign__c FROM Lead WHERE LeadSource =: 'Asset Ownership Change'];
        
        system.assertEquals(LeadUndel.size(), 1);
        
    }
    
    static testMethod void ChangeOwnerToQueueDellBoomionUpdateTest(){
        
        QueuesObject testQueue = insertQueue();
        Group testGroup = new Group(Name='Hot Lead Queue Netherlands', Type='Queue');
        insert testGroup;
        
        QueuesObject testQueue1 = new QueueSObject(QueueID = testGroup.id, SObjectType = 'Lead');
        insert testQueue1;
        
        User IntegUser = createDellBoomiUser();
        system.runAs(IntegUser){
        insert new WorkflowSettings__c(LeadWorkflows__c = true);
        
        
        Lead ld = new Lead();
        ld.Status = 'Open';
        ld.LastName = 'TestLead';
        ld.FirstName = 'TestLead';
        ld.Title = 'TestLead';
        ld.Phone = '+1234567890';
        ld.LeadSource = 'Asset Ownership Change';
        ld.Company = 'TestCompany';
        ld.Email = 'glennsasd123@gmail.com';
        ld.Sales_Organization__c = 'SAP_0111';
        ld.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get(SM_Constants.LeadRecTypeStandard).getRecordTypeId();
        ld.OwnerId = testGroup.Id;
        ld.Touchpoint_Type__c = 'INBOUND CALL';
        insert ld;
        
        Task t = new Task();
        Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        t.Subject = 'ASDF';
        t.Touchpoint_Type__c = 'INBOUND CALL';
        t.Task_Source__c = 'SFDC';
        t.WhoId = ld.Id;
        t.Status = 'Open';
        t.RecordTypeId = recordTypeId;
        t.ActivityDate = System.date.today();
        
        insert t;
        
        
       
        
        ld.Company = 'TestCompanyyyy';
        Lead testLead = [Select Id, Status, Reason_Disqualified__c, Name, Sales_Organization__c FROM Lead WHERE Id = :ld.id limit 1]; 
        ld.Status = 'Disqualified';
        ld.Reason_Disqualified__c = 'Unreachable';
        ld.Consent_Text__c = 'ASDF';
        ld.Email = 'test@gmail.com';
            system.debug('rianno test');
            system.debug(testLead.Sales_Organization__c);
            String userProfileId = UserInfo.getProfileId();
            Profile profileInfo = [Select Id, Name FROM Profile WHERE Id = :userProfileId];
            system.debug(profileInfo.Name);
        update ld;
        }
        
        List<Lead> LeadUndel = [SELECT Id, Assign__c FROM Lead WHERE LeadSource =: 'Asset Ownership Change'];
        
        system.assertEquals(LeadUndel.size(), 1);
        
    }
    static testMethod void TestTriggerOff(){
        
        insert new TriggerSettings__c(LeadTrigger__c = false);
        
        LeadTriggerHandler leadhandler = new LeadTriggerHandler();
        TriggerDispatcher.Run(leadhandler);
        
        TriggerSettings__c ts = TriggerSettings__c.getInstance();
        system.assertEquals(false, ts.LeadTrigger__c);
    
    }

    static testMethod void TestOwner(){
        Profile p = [SELECT Id FROM Profile WHERE  Name =: 'JDE-Integration-Digital']; 
        User u = new User(Alias = 'standt', Email='sample@testUser1.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sample@testUser1.com', Country= 'Belgium');
        Group testGroup = new Group(Name='test group', Type='Queue');
        insert testGroup;

        System.runAs(new User(Id=UserInfo.getUserId()))
        {
            QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = 'Lead');
            insert testQueue;
        
       
        Queue_Lead_Task__c queuelead = new Queue_Lead_Task__c();
        queuelead.Name = 'SAP_0333';
        queuelead.Sales_Organization__c = 'Belgium';
        queuelead.Queue_for_Lead__c = testQueue.Id;
        
        insert queuelead;
        }
        System.runAs(u){
       
        
        Lead ld = new Lead();
        ld.Status = 'Open';
        ld.LastName = 'TestLead';
        ld.FirstName = 'TestLead';
        ld.Title = 'TestLead';
        ld.Phone = '+1234567890';
        ld.LeadSource = 'Asset Ownership Change';
        ld.Company = 'TestCompany';
        ld.Sales_Organization__c = 'SAP_0333';
        
        insert ld;
        
        }
        
    }
    
    
}