/**
* @author        Marvin Gatchalian
* @date          3.26.2018           
* @description   Test class for TS_UpdateRelatedCase_Test
* @revision(s)
*/

@isTest
public with sharing class TS_UpdateRelatedCase_Test {


static Account acct;
    static Contact con;
    static Case c;
    static WorkOrder wo;
    static Apttus_Config2__AssetLineItem__c ali;
    static Apttus_Config2__Order__c order;
    static Apttus_Config2__OrderLineItem__c oli;
    static WorkOrderLineItem woli;
    
    /**
    * @author        Marvin Gatchalian
    * @date          3.26.2018           
    * @description   Method responsible for creating custom setting records
    * @revision(s)
    */
    @testSetup
    static void dataSetup() {
        TriggerSettings__c trg = TriggerSettings__c.getOrgDefaults();
        trg.CaseTrigger__c = true;
        trg.WorkOrderLineItemTrigger__c = true;
        upsert trg;
        
        IntegrationTriggerSettings__c trg1 = IntegrationTriggerSettings__c.getOrgDefaults();
        trg1.IntegrationLogTrigger__c = true;
        upsert trg1;
        
        ProcessBuilderSettings__c pb = new ProcessBuilderSettings__c();
        pb.CasePBFlows__c = true;
        insert pb; 
        
    }
    
    /**
    * @author        Marvin Gatchalian
    * @date          3.26.2018           
    * @description   Method responsible for creating custom setting records
    * @revision(s)
    */
    static void setupTestData() {
        acct = new Account(Name='Account', Phone='+31302979111');
        //acct.Segment__c = 'SAP_A';
        //acct.High_Segment__c = 'Business';
        insert acct;
        
        con = TS_TestDataFactory.createContact();  
        con.Preferred_Language__c = 'SAP_EN';
        con.AccountId = acct.id;
        Insert con;
        
        c = TS_TestDataFactory.createFieldServiceCase();
        c.ContactId = con.Id;
        
        c.Number_of_Completed_WOLI_Tasks__c = 0;
		c.Number_of_Open_WOLI_Tasks__c = 0;
        insert c;
        
        wo = TS_TestDataFactory.createWorkOrder();
        wo.CaseId = c.Id;
        wo.WorkOrderType__c = Label.TS_Case_SubType_CorrectMaint;
        wo.ContactId = con.Id;
        
        /*
        woli = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);         
        woli.Case__c = c.Id;
        woli.WorkOrderLineItemType__c = Label.TS_Type_Task;
        woli.AssetLineItem__c = ali.Id;
        woli.OrderLineItem__c = oli.Id;
        woli.EndDate__c = DateTime.now();
        */
    }
    
    /**
    * @author        Marvin Gatchalian
    * @date          3.26.2018           
    * @description   Method responsible for creating custom setting records
    * @revision(s)
    */
    static testMethod void testInsertWoliAndUpdateCase () {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();
            Test.startTest();
                insert wo;   //It will trigger the TS_Convert to WOLI process builder to insert woli
            Test.stopTest();
            
            //Verify Results
            Case cse = [Select Number_of_Open_WOLI_Tasks__c From Case Where id = :c.id];
            System.assertEquals(0, cse.Number_of_Open_WOLI_Tasks__c);
        }
    }
    
    /**
    * @author        Marvin Gatchalian
    * @date          3.26.2018           
    * @description   Method responsible for creating custom setting records
    * @revision(s)
    */
    static testMethod void testInsertWoliStatusComplete () {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
            setupTestData();


            Test.startTest();
                insert wo;   //It will trigger the TS_Convert to WOLI process builder to insert woli
                woli = TS_TestDataFactory.createWorkOrderLineItem(wo.Id);         
                woli.Case__c = c.Id;
                woli.WorkOrderLineItemType__c = Label.TS_Type_Task;
                woli.Status = 'Completed';
            	insert woli;
            Test.stopTest();
            
            WorkOrderLineItem woliQueried = [Select id, status From WorkOrderLineItem 
            								 Where WorkOrderId = :wo.id];
            					
            woliQueried.status = 'Completed';
            update woliQueried;
           
            WorkOrderLineItem woliQueried1 = [Select id, case__c From WorkOrderLineItem 
            								  Where Status = 'Completed'];
            					
            Delete woliQueried1;
            
            //Verify Results
            Case cse1 = [Select Number_of_Open_WOLI_Tasks__c, Number_of_Completed_WOLI_Tasks__c 
            			 From Case Where id = :woliQueried1.case__c];
            System.assertEquals(0, cse1.Number_of_Open_WOLI_Tasks__c);
            System.assertEquals(0, cse1.Number_of_Completed_WOLI_Tasks__c);
            

        }
    }
    
    /**
    * @author        Marvin Gatchalian
    * @date          3.29.2018           
    * @description   Test Method for Insert Case field service TS_Routing Case Settings
    * @revision(s)
    */
    static testMethod void testInsertNewCase () {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
        	Account acct1 = new Account(Name='Account', Phone='+31302979111');
	        insert acct1;
	        
	        Contact con1 = TS_TestDataFactory.createContact();  
	        con1.Preferred_Language__c = 'SAP_EN';
	        con1.AccountId = acct1.id;
	        insert con1;
        
            Case c1 = TS_TestDataFactory.createFieldServiceCase();
	        c1.ContactId = con1.Id;
	        c1.AssignToQueue__c = false;

            Test.startTest();
                 insert c1;
            Test.stopTest();

            //Verify Results
            Case cse1 = [Select OwnerId, Run_Default_Case_Process__c , Status
            			 From Case Where id = :c1.id];
            
            system.debug('Marvin >>>' + cse1);			 
            System.assertEquals(u.id, cse1.OwnerId);
            System.assertEquals(true, cse1.Run_Default_Case_Process__c);
            System.assertEquals(TS_Constants.STATUS_OPEN, cse1.Status);

        }
    }
    
    /**
    * @author        Marvin Gatchalian
    * @date          3.29.2018           
    * @description   Test Method for Update Case field service TS_Routing Case Settings
    * @revision(s)
    */
    static testMethod void testInsertUpdateCase () {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        id aId = userInfo.getUserId();
        
	    System.runAs(u) {  
	    	Account acct1 = new Account(Name='Account', Phone='+31302979111');
        	acct1.Default_Case_Owner__c = true;
        	acct1.Customer_Relations_1__c = aId;
	        insert acct1;
	          
	        Contact con1 = TS_TestDataFactory.createContact();  
	        con1.Preferred_Language__c = 'SAP_EN';
	        con1.AccountId = acct1.id;
	        insert con1;
        
            Case c1 = TS_TestDataFactory.createFieldServiceCase();
	        c1.ContactId = con1.Id;
	        c1.Type = TS_Constants.TS_CASE_RECORDTYPE_QUALIFYCASE;
	        c1.AssignToQueue__c = true;

            Test.startTest();
                 insert c1;
                 c1.CaseQualificationDate__c = system.now();
           		 update c1;
            Test.stopTest();

            //Verify Results
            Case cse2 = [Select OwnerId, Run_Default_Case_Process__c , Status
            			 From Case Where id = :c1.id];
		 
            System.assertEquals(aId, cse2.OwnerId);
            System.assertEquals(true, cse2.Run_Default_Case_Process__c);
            System.assertEquals(TS_Constants.STATUS_OPEN, cse2.Status);

        }
    }
    
     /**
    * @author        Karen Hung 
    * @date          7.8.2019          
    * @description   Test Method for Insert Case field service TS_Routing Case Settings individual
    * @revision(s)
    */
    static testMethod void testInsertNewCaseIndividual () {       
        User u = TS_TestDataFactory.createUser(Label.TS_Default_User_Profile);
        
        System.runAs(u) {
        	Account acct1 = new Account(Name='Account', Phone='+31302979111');
	        insert acct1;
	        
	        Contact con1 = TS_TestDataFactory.createContact();  
	        con1.Preferred_Language__c = 'SAP_EN';
	        con1.AccountId = acct1.id;
	        insert con1;
        
            Case c1 = TS_TestDataFactory.createFieldServiceCase();
	        c1.ContactId = con1.Id;
	        c1.AssignToQueue__c = false;
            c1.Default_Owner_by_Country_Setting__c = 'Individual';

            Test.startTest();
                 insert c1;
            Test.stopTest();

            //Verify Results
            Case cse1 = [Select OwnerId, Run_Default_Case_Process__c , Status
            			 From Case Where id = :c1.id];
            
            system.debug('Marvin >>>' + cse1);			 
            System.assertEquals(u.id, cse1.OwnerId);
            System.assertEquals(true, cse1.Run_Default_Case_Process__c);
            System.assertEquals(TS_Constants.STATUS_OPEN, cse1.Status);

        }
    }
    
        
}