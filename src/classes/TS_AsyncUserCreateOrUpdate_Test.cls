/**
* @author        Paul Jarred Aguiling
* @date          07.12.2018          
* @description   Test class for TS_AsyncUserCreateOrUpdate
* @revision(s)
*/
@isTest
public class TS_AsyncUserCreateOrUpdate_Test {
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
		testResource.EmployeeLastName__c = 'Skywalker';
		testResource.EmployeeFirstName__c = 'Anakin';
		testResource.CompanyCode__c = '6864';
		testResource.TeamNumber__c = '619';
        testResource.Username__c = 'testuser@salesforce.com';
        testResource.NickName__c = 'Anakin001';
		testResource.RequiresClickUser__c = true;
		testResource.UserProfile__c = Label.TS_ResourceUsrProf_ThirdParty;
		testResource.ActiveUser__c = true;
		
		insert testResource;
    }

    /**
	* @author        Paul Jarred Aguiling
	* @date          07.12.2018            
    * @description   Test class for TS_AsyncUserCreateOrUpdate execute method
    * @revision(s)
    */
    static testMethod void testExecute1() {
    	UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        u.UserRoleId = portalRole.Id;
        update u;

        System.runAs(u) {
			setupTestData();
			acct.OwnerId = u.Id;
			update acct;

			Set<Id> resList = new Set<Id>();
			resList.add(testResource.Id);

			ResourceTriggerHandler resTrig = new ResourceTriggerHandler();
	        TS_AsyncUserCreateOrUpdate userRes = new TS_AsyncUserCreateOrUpdate();
            userRes.resourceList = resList;
            userRes.map_profile = resTrig.getProfile();
            System.enqueueJob(userRes);

            Test.startTest();
            		System.assert(userRes.map_profile != null);
            Test.stopTest();
        }
    }

    /**
	* @author        Paul Jarred Aguiling
	* @date          07.12.2018            
    * @description   Test class for TS_AsyncUserCreateOrUpdate execute method
    * @revision(s)
    */
    static testMethod void testExecute2() {
    	UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        u.UserRoleId = portalRole.Id;
        update u;

        System.runAs(u) {
			setupTestData();
			acct.OwnerId = u.Id;
			update acct;

			testResource.UserProfile__c = Label.TS_ResourceUsrProf_Operator;
			update testResource;

			Set<Id> resList = new Set<Id>();
			resList.add(testResource.Id);

			ResourceTriggerHandler resTrig = new ResourceTriggerHandler();
	        TS_AsyncUserCreateOrUpdate userRes = new TS_AsyncUserCreateOrUpdate();
            userRes.resourceList = resList;
            userRes.map_profile = resTrig.getProfile();
            System.enqueueJob(userRes);

            Test.startTest();
            		System.assert(userRes.map_profile != null);
            Test.stopTest();
        }
    }

    /**
	* @author        Paul Jarred Aguiling
	* @date          07.12.2018            
    * @description   Test class for TS_AsyncUserCreateOrUpdate execute method
    * @revision(s)
    */
    static testMethod void testExecute3() {
    	UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        u.UserRoleId = portalRole.Id;
        update u;

        System.runAs(u) {
			setupTestData();
			acct.OwnerId = u.Id;
			update acct;

			testResource.UserProfile__c = Label.TS_ResourceUsrProf_Planner;
			update testResource;

			Set<Id> resList = new Set<Id>();
			resList.add(testResource.Id);

			ResourceTriggerHandler resTrig = new ResourceTriggerHandler();
	        TS_AsyncUserCreateOrUpdate userRes = new TS_AsyncUserCreateOrUpdate();
            userRes.resourceList = resList;
            userRes.map_profile = resTrig.getProfile();
            System.enqueueJob(userRes);

            Test.startTest();
            		System.assert(userRes.map_profile != null);
            Test.stopTest();
        }
    }
    /**
	* @author        Karen Hung
	* @date          01.15.19           
    * @description   Test class for TS_AsyncUserCreateOrUpdate execute method
    * @revision(s)
    */
    static testMethod void testExecute4() {
    	UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        u.UserRoleId = portalRole.Id;
        update u;

        System.runAs(u) {
			setupTestData();
			acct.OwnerId = u.Id;
			update acct;

			testResource.UserProfile__c = Label.TS_ResourceUsrProf_TSRes;
            testResource.RequiresClickUser__c = false;
			update testResource;

			Set<Id> resList = new Set<Id>();
			resList.add(testResource.Id);

			ResourceTriggerHandler resTrig = new ResourceTriggerHandler();
	        TS_AsyncUserCreateOrUpdate userRes = new TS_AsyncUserCreateOrUpdate();
            userRes.resourceList = resList;
            userRes.map_profile = resTrig.getProfile();
            System.enqueueJob(userRes);

            Test.startTest();
            		System.assert(userRes.map_profile != null);
            Test.stopTest();
        }
    }
}