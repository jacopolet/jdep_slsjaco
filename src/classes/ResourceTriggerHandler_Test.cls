/**
* @author        Paul Jarred Aguiling
* @date          07.12.2018          
* @description   Test class for ResourceTriggerHandler
* @revision(s)
*/
@isTest
public class ResourceTriggerHandler_Test {
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
		testResource.RequiresClickUser__c = true;
		testResource.UserProfile__c = 'Admin';
		testResource.ActiveUser__c = true;
		testResource.EmployeeStatus__c = '3';
		testResource.Position_Description__c = Label.TS_ResourceUsrProf_Admin;
        testResource.Username__c = 'testusername@test1.com';
        testResource.NickName__c = 'testnickname@test1.com';
        testResource.Position_Description__c = Label.TS_ResourceUsrProf_Admin;
	
		insert testResource;
    }

    /**
	* @author        Paul Jarred Aguiling
	* @date          07.12.2018            
    * @description   Test class for createUserWithIntegLogs execute method
    * @revision(s)
    */
    static testMethod void testCreateUserWithIntegLogs() {
    	UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        u.UserRoleId = portalRole.Id;
        update u;

        System.runAs(u) {
			setupTestData();
			acct.OwnerId = u.Id;
			update acct;

			testResource.RequiresClickUser__c = false;
            testResource.Username__c = 'testusername@test2.com';
			update testResource;

			testResource.RequiresClickUser__c = true;
			update testResource;

            Test.startTest();
            		//verify resource
            		System.assert([SELECT Id, Sales_Organization__c, UserProfile__c FROM Resource__c WHERE Id = :testResource.Id].UserProfile__c != null);
            Test.stopTest();
        }
    }

    /**
	* @author        Paul Jarred Aguiling
	* @date          07.12.2018            
    * @description   Test class for deactivateUser execute method
    * @revision(s)
    */
    static testMethod void testDeactivateUser() {
    	UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        u.UserRoleId = portalRole.Id;
        update u;

        System.runAs(u) {
			setupTestData();
			acct.OwnerId = u.Id;
			update acct;

			testResource.RelatedUser__c = u.Id;
			update testResource;

			testResource.EmployeeStatus__c = '0';
			update testResource;

            Test.startTest();
            	//verify resource related user
            	System.assert([SELECT Id,Sales_Organization__c, RelatedUser__c FROM Resource__c WHERE Id = :testResource.Id].RelatedUser__c == null);
            Test.stopTest();
        }
    }
    
        /**
	* @author        Karen Hung
	* @date          12.13.2018            
    * @description   Test class for removeFiels method
    * @revision(s)
    */
    static testMethod void testRemoveFields() {
    	UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        u.UserRoleId = portalRole.Id;
        update u;

        System.runAs(u) {
			setupTestData();

			testResource.RelatedUser__c = u.Id;
            testResource.ActiveUser__c = true;
			update testResource;
			
            ResourceTriggerHandler.hasException = true;
            testResource.ActiveUser__c = false;
			update testResource;
            
            delete testResource;
            undelete testResource;

            Test.startTest();
            		//verify related user
            		System.assert([SELECT Id,Sales_Organization__c, RelatedUser__c FROM Resource__c WHERE Id = :testResource.Id].RelatedUser__c == null);
            Test.stopTest();
        }
    }
    
     /**
	* @author        Karen Hung
	* @date          April 8, 2021           
    * @description   Test class for permissionSetUpdate method
    * @revision(s)
    */
    static testMethod void testPermSet() {
        UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        u.CommunityNickname='testnickname@test.com';
        u.UserRoleId = portalRole.Id;
        update u;

        System.runAs(u) {
			setupTestData();
            
			testResource.RelatedUser__c = u.Id;
            testResource.ActiveUser__c = true;
            testResource.UserProfile__c = Label.TS_ResourceUsrProf_ThirdParty;
			update testResource;
            
            testResource.Create_Edit_OPG_Schedule__c = true;
            testResource.NickName__c = null;
			update testResource;
            
            testResource.Create_Edit_OPG_Schedule__c = false;
            testResource.NickName__c = 'testnickname@test2.com';
			update testResource;           
            
            Test.startTest();
            	//verify permission set assigned 
            	System.assertEquals([SELECT Id,AssigneeId FROM PermissionSetAssignment WHERE AssigneeId = :u.Id].size(),1);
            Test.stopTest();
        }
        
    }
}