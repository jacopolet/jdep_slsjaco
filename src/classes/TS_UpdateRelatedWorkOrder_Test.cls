/**
* @author        Marvin Gatchalian
* @date          03.26.2018        
* @description   Test class for TS_UpdateRelatedWorkOrder
* @revision(s)
*/
    
@isTest
public with sharing class TS_UpdateRelatedWorkOrder_Test {
	
	static Account acct;
    static Contact con;
    static Case c;
    static WorkOrder wo;
    static PhysicalAsset__c pa;
    static User u;
    
    
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
    * @author        Marvin Gatchalian
    * @date          03.26.2018            
    * @description   Method responsible for creating test data
    * @revision(s)
    */
    static void setupTestData() {
        
        
        pa = new PhysicalAsset__c(Name='Test', 
                                  UniqueNumber__c='1234567-TestMachine', 
                                  RecordTypeId = Schema.SObjectType.PhysicalAsset__c.getRecordTypeInfosByName().get('Machine').getRecordTypeId());
        insert pa;
		
        acct = new Account(Name='Account', Phone='+31302979111');
        insert acct;
        
        con = TS_TestDataFactory.createContact();  
        con.Preferred_Language__c = 'SAP_EN';
        Insert con;
        
        c = TS_TestDataFactory.createFieldServiceCase();
        c.ContactId = con.Id;
        c.Status = Label.TS_Status_InProgress;
        c.OwnerId = userinfo.getUserId();
        insert c;
        
        wo = TS_TestDataFactory.createWorkOrder();
        wo.CaseId = c.Id;
        wo.WorkOrderType__c = Label.TS_Case_SubType_CorrectMaint;
        wo.ContactId = con.Id;
        insert wo;
        
    }
    
     static testMethod void testChangeCaseOwnerId() {
         
	    setupTestData();
		u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
         System.runAs(u) {
			 
			 Test.startTest();
				 System.debug ('Marvin >>> c.OwnerId' + c.OwnerId);
				 Case cse = [Select id, OwnerId From Case where id = :c.id];
				 cse.OwnerId = u.id;
				 update cse;
				 
	             WorkOrder wo = [Select Id, OwnerId, Case.OwnerId from WorkOrder where CaseId = :cse.id];
	             System.debug ('Marvin After Change >>> c.OwnerId' + wo.Case.OwnerId);
                 System.assertEquals(wo.Case.OwnerId, wo.OwnerId);
                 
             Test.stopTest();
         }
     }
    
    
    
}