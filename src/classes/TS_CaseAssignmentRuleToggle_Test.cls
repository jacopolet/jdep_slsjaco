/**
* @author        Paul Aguiling
* @date          3.09.2018           
* @description   Test class for TS_CaseAssignmentRuleToggle
* @revision(s)   
*/
@isTest
private class TS_CaseAssignmentRuleToggle_Test {
	
    static Account acct;
    static Contact con;
    static Case c;

    /**
    * @author        Paul Jarred Aguiling
    * @date          03.09.2018          
    * @description   Method responsible for creating test data
    * @revision(s)
    */
    static void setupTestData() {
        acct = new Account(Name='Account', Phone='+31302979111');
        insert acct;
        
        con = TS_TestDataFactory.createContact();  
        con.Preferred_Language__c = 'SAP_EN';
        Insert con;
        
        c = TS_TestDataFactory.createFieldServiceCase();
        c.AssignToQueue__c = true;
        c.ContactId = con.Id;
        insert c;
    }


    /**
    * @author        Paul Jarred Aguiling
    * @date          03.09.2018
    * @description   Method for setting default data
    * @revision(s)
    */
    @testSetup
    static void dataSetup() {
        //Custom settings is being shared by all test class, if another test class has already inserted the record 
        //this test class will throw "UNABLE_TO_LOCK_ROW, unable to obtain exclusive access to this record"
        try {
            TriggerSettings__c trg = TriggerSettings__c.getOrgDefaults();
            trg.CaseTrigger__c = true;
            trg.WorkOrderTrigger__c = true;
            trg.WorkOrderLineItemTrigger__c = true;
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
    * @date          03.09.2018
    * @description   Test method for fireAssignmentRuleBulk
    * @revision(s)
    */
    static testmethod void testFireAssignmentRuleBulk() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(u) {
        	setupTestData();
        	Test.startTest();
        		System.assert(TS_CaseAssignmentRuleToggle.fireAssignmentRuleBulk(new List<Case>{c}) != null);
        	Test.stopTest();
        }
    }

   /**
    * @author        Paul Jarred Aguiling
    * @date          03.09.2018
    * @description   Test method for fireAssignmentRuleSingle
    * @revision(s)
    */
    static testmethod void testFireAssignmentRuleSingle() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(u) {
        	setupTestData();
        	Test.startTest();
        		System.assert(TS_CaseAssignmentRuleToggle.fireAssignmentRuleSingle(c) != null);
        	Test.stopTest();
        }
    }

   /**
    * @author        Paul Jarred Aguiling
    * @date          03.09.2018
    * @description   Test method for fireAssignmentRuleBulkUpdate
    * @revision(s)
    */
    static testmethod void testFireAssignmentRuleBulkUpdate() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(u) {
        	setupTestData();

        	Case c2 = TS_TestDataFactory.createFieldServiceCase();
	        c2.ContactId = con.Id;
	        c2.CaseQualificationDate__c = Date.today();
	        c2.CreatedOrderedManually__c = true;
	        insert c2;

        	Test.startTest();
        		TS_CaseAssignmentRuleToggle.fireAssignmentRuleBulkUpdate(new List<SObject>{c}, true, new Map<Id, SObject>{c.Id => c});
        		System.assert([SELECT Id FROM Case WHERE Id =: c.Id].Id != null);
        	Test.stopTest();
        }
    } 

   /**
    * @author        Paul Jarred Aguiling
    * @date          03.09.2018
    * @description   Test method for fireAssignmentRuleBulkUpdate
    * @revision(s)
    */
    static testmethod void testFireAssignmentRuleBulkUpdate2() {
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);

        System.runAs(u) {
        	setupTestData();

        	Case c2 = TS_TestDataFactory.createFieldServiceCase();
	        c2.ContactId = con.Id;
	        c2.CaseQualificationDate__c = Date.today();
	        c2.CreatedOrderedManually__c = true;
	        insert c2;
	        
        	Test.startTest();
        		TS_CaseAssignmentRuleToggle.fireAssignmentRuleBulkUpdate(new List<SObject>{c}, false, new Map<Id, SObject>{c.Id => c2});
        		System.assert([SELECT Id FROM Case WHERE Id =: c.Id].Id != null);
        	Test.stopTest();
        }
    } 
	
}