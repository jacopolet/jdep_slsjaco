/**
* @author        Paul Jarred Aguiling
* @date          07.12.2018          
* @description   Test class for TS_SyncRelatedUserBatch
* @revision(s)
*/
@isTest
public class TS_SyncRelatedUserBatch_Test {
    static Account acct;
    static Contact con;
    static Resource__c  testResource;

    @testSetup
    static void dataSetup() {
        //Custom settings is being shared by all test class, if another test class has already inserted the record 
        //this test class will throw "UNABLE_TO_LOCK_ROW, unable to obtain exclusive access to this record"
        try {
            TriggerSettings__c trg = TriggerSettings__c.getOrgDefaults();
            trg.ResourceTrigger__c = true;
            upsert trg;      
            system.debug('trg is:'+trg);
        } catch(Exception ex) {
            system.debug(ex);
        }

         try {
            IntegrationTriggerSettings__c trg1 = IntegrationTriggerSettings__c.getOrgDefaults();
            trg1.IntegrationLogTrigger__c = true;
            upsert trg1; 
        } catch(Exception ex) {
            system.debug(ex);
        }

        ProcessBuilderSettings__c pb = new ProcessBuilderSettings__c();
        pb.WorkOrderPBFlows__c = true;
        pb.CasePBFlows__c = true;
        insert pb;
    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          07.12.2018             
    * @description   Method responsible for creating test data
    * @revision(s)
    */
    static void setupTestData() {
        acct = new Account(Name='Account', Phone='+31302979111');
        insert acct;
        
        con = TS_TestDataFactory.createContact();  
        con.Preferred_Language__c = 'SAP_EN';
        con.AccountId = acct.Id;
        insert con;

        testResource = TS_TestDataFactory.createResourceSingle('TestRSONumber');
        testResource.EmailAddress__c = 'testRSO@JDECoffee.com';
        testResource.RelatedContact__c = con.Id;
        testResource.Nickname__c = 'TestRSONumber';
        insert testResource;
    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          07.12.2018            
    * @description   Test class for TS_SyncRelatedUserBatch
    * @revision(s)
    */
    static testMethod void testSyncRelatedUserBatch() {
        UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
        system.debug('portalRole is ' + portalRole);

        Profile profile1 = [Select Id from Profile where name = 'System Administrator'];
        User u = new User(
        UserRoleId = portalRole.Id,
        ProfileId = profile1.Id,
        Username = System.now().millisecond() + 'test2@jdecoffee.com',
        Alias = 'batman',
        Email='bruce.wayne@wayneenterprises.com',
        EmailEncodingKey='UTF-8',
        Firstname='Bruce',
        Lastname='Wayne',
        LanguageLocaleKey='en_US',
        LocaleSidKey='en_US',
        TimeZoneSidKey='America/Chicago'
        );
        Database.insert(u);
        
        System.runAs(u) {
            setupTestData();
            acct.OwnerId = u.Id;
            update acct;

            Profile p = [SELECT Id FROM Profile WHERE Name=: TS_Constants.PROFILE_PORTALUSER];//Changed by Ritesh to correct the profile name.
            User user1 = new User(
            Username = System.now().millisecond() + 'test12345@jdecoffee.com',
            ContactId = con.Id,
            ProfileId = p.Id,
            Alias = 'test123',
            Email = 'test12345@jdecoffee.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'McTesty',
            CommunityNickname = 'TestRSONumber',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            Isactive = true
            );
            Database.insert(user1);
            
            Profile p2 = [SELECT Id FROM Profile WHERE Name= 'JDE - END USER - STC MOBILE INTERNAL'];
            User user2 = new User(
            Username = System.now().millisecond() + 'test12345@jdecoffee.com',
            ProfileId = p2.Id,
            Alias = 'test1232',
            Email = 'test123452@jdecoffee.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'McTesty',
            CommunityNickname = 'TestRSONumbers',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            Isactive = true,
            EmployeeNumber = testResource.Name
            );
            Database.insert(user2);

            Test.startTest();
                Id result = Database.executeBatch(new TS_SyncRelatedUserBatch());
                System.assert(result != null);
            Test.stopTest();
        }
    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          07.12.2018            
    * @description   Test class for TS_SyncRelatedUserBatch Exception
    * @revision(s)
    */
    static testMethod void testSyncRelatedUserBatchEx() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(u) {

            setupTestData();

            Test.startTest();
                TS_SyncRelatedUserBatch.hasException = true;
                Id result = Database.executeBatch(new TS_SyncRelatedUserBatch());
                System.assert(result != null);
            Test.stopTest();
        }
    }
}