/**
* @author        Paul Jarred Aguiling
* @date          07.17.2018          
* @description   Test class for TS_SendUserCreateorUpdateToClick
* @revision(s)
*/
@isTest
public class TS_SendUserCreateorUpdateToClick_Test {
    static Account acct;
    static Contact con;
    static Resource__c  testResource;
    static Integration_Log__c integLog;

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
	* @date          07.17.2018           
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
        testResource.Username__c = 'testRSO@JDECoffee.com';
        testResource.Sales_Organization__c = 'SAP_0111';
		testResource.TeamNumber__c = '619';
		testResource.RequiresClickUser__c = true;
		testResource.UserProfile__c = 'Admin';
		testResource.ActiveUser__c = true;
		testResource.EmployeeStatus__c = '3';
		testResource.Position_Description__c = Label.TS_ResourceUsrProf_TSRes;
	
		insert testResource;

        integLog = new Integration_Log__c();
        integLog.Object_Id__c = testResource.Id;
        integLog.Object__c = TS_Constants.CLICK_USERCREATE;
        integLog.Integration_Status__c = INT_Constants.INITIAL;
        integLog.Triggered_Timestamp__c = Datetime.now();

        insert integLog;
    }

    /**
	* @author        Paul Jarred Aguiling
	* @date          07.17.2018           
    * @description   Test class for executeUserCreateOrUpdate execute method
    * @revision(s)
    */
    static testMethod void testExecuteUserCreateOrUpdate() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
        	setupTestData();

        	List<Integration_Log__c> currentILogList = new List<Integration_Log__c>();
        	currentILogList.add(integLog);

        	Test.startTest();
        		TS_SendUserCreateorUpdateToClick sendUser = new TS_SendUserCreateorUpdateToClick();
        		sendUser.executeUserCreateOrUpdate(currentILogList);

        		System.assert([SELECT Id FROM Resource__c WHERE Id =:integLog.Object_Id__c].Id != null);
        	Test.stopTest();
        }
    }
    
    /**
	* @author        Karen Hung
	* @date          10.03.2020           
    * @description   Test class for executeUserCreateOrUpdate execute method with exception
    * @revision(s)
    */
    static testMethod void testExecuteUserCreateOrUpdateEx() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        System.runAs(u) {
        	setupTestData();

        	List<Integration_Log__c> currentILogList = new List<Integration_Log__c>();
        	currentILogList.add(integLog);

        	Test.startTest();
        		TS_SendUserCreateorUpdateToClick sendUser = new TS_SendUserCreateorUpdateToClick();
            	sendUser.hasException = true;
        		sendUser.executeUserCreateOrUpdate(currentILogList);

        		System.assert([SELECT Id FROM Resource__c WHERE Id =:integLog.Object_Id__c].Id != null);
        	Test.stopTest();
        }
    }
}